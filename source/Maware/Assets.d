module maware.assets;

import std.algorithm.comparison : equal;
import std.array : join, split;
import std.conv : to;
import std.exception : assumeUnique;
import std.file : DirEntry, dirEntries, SpanMode;
import std.typecons : Tuple, tuple;

/// A struct describing an asset collection. Contains two immutable associative
/// arrays holding a name-path pair for loading textures with fixed names but
/// variable paths, and one array of strings describing the path to sound files
/// which will be identified by their index.
immutable struct Assets {

	immutable string[string] textures;
	immutable string[string] fonts;
	immutable string[] sounds;

	/// Construct a new immutable Assets collection. dirPath will be added to
	/// the path field of all entries in textures, fonts and sounds, and so they
	/// are modified in place.
	this(string[string] textures,
		 string[string] fonts,
		 string[] sounds,
		 string dirPath) immutable {

		foreach (string[string] aaCollection ; [textures, fonts]) {
			foreach (string key ; aaCollection.keys) {
				aaCollection[key] = dirPath ~ aaCollection[key];
			}
		}
		this.textures = assumeUnique(textures);
		this.fonts = assumeUnique(fonts);
		foreach (size_t i, string path ; sounds) {
			sounds[i] = dirPath ~ path;
		}
		this.sounds = sounds.idup;
	}

	/// Returns the file name in s, excluding the path.
	static string filePart(string s) {
		if (s.length > 0) {
			return s.split("\\").join("/").split("/")[$ - 1];
		} else {
			return "";
		}
	}

	/// Returns a new Assets collection where layers is applied in just that;
	/// layers. The Assets collection at index 0 is added first, and then any
	/// collections is put on top, so a new collection that is guaranteed to be
	/// complete can be returned.
	static immutable(Assets) combineAssetCollections(immutable Assets[] layers) {
		string[string] combinedTextures;
		string[string] combinedFonts;
		string[] combinedSounds;
		foreach (immutable Assets layer ; layers) {
			foreach (string key ; layer.textures.keys) {
				combinedTextures[key] = layer.textures[key];
			}
			foreach (string key ; layer.fonts.keys) {
				combinedFonts[key] = layer.fonts[key];
			}
			foreach (size_t i, string path ; layer.sounds) {
				if (combinedSounds.length < i + 1) {
					combinedSounds ~= "";
				}
				if (filePart(path).length > 0) {
					combinedSounds[i] = path;
				}
			}
		}
		return immutable Assets(combinedTextures, combinedFonts, combinedSounds, "");
	}

	/// Returns an Assets collection containing all the assets found in
	/// searchDir, using present files in reference to see which to look for.
	/// The returned value will have full paths in its values inferred from
	/// searchDir.
	/// The values in reference must not contain paths; only filenames, else
	/// this function will not work.
	static immutable(Assets) findAssets(immutable Assets reference, string searchDir) {
		string[] fileNames;
		foreach (DirEntry entry ; dirEntries(searchDir, SpanMode.shallow)) {
			fileNames ~= filePart(entry.name);
		}
		string[string] textures;
		string[string] fonts;
		string[] sounds = new string[reference.sounds.length];
		foreach (kv ; reference.textures.byKeyValue()) {
			foreach (string file ; fileNames) {
				if (kv.value.equal(file)) {
					textures[kv.key] = kv.value;
				}
			}
		}
		foreach (kv ; reference.fonts.byKeyValue()) {
			foreach (string file ; fileNames) {
				if (kv.value.equal(file)) {
					fonts[kv.key] = kv.value;
				}
			}
		}
		foreach (size_t i, string file ; reference.sounds) {
			foreach (string entry ; fileNames) {
				if (file.equal(entry)) {
					sounds[i] = file;
				}
			}
		}
		return immutable Assets(textures, fonts, sounds, searchDir);
	}

	/// Returns the keys of any entries which are present in reference, but
	/// missing in toLoad.
	static string[] findMissing(immutable Assets reference,
								immutable Assets toLoad) {

		string[] ret;
		foreach (immutable string[string][2] aaCollection ; [[reference.textures,
															  toLoad.textures],
															 [reference.fonts,
															  toLoad.fonts]]) {
			string[string] refFiles;
			string[string] compareFiles;
			foreach (kv ; aaCollection[0].byKeyValue()) {
				refFiles[kv.key] = filePart(kv.value);
			}
			foreach (kv ; aaCollection[1].byKeyValue()) {
				compareFiles[kv.key] = filePart(kv.value);
			}
			foreach (string key ; refFiles.keys) {
				if (key !in compareFiles) {
					ret ~= key ~ ": " ~ refFiles[key];
				}
			}
		}
		foreach (size_t i, string file ; reference.sounds) {
			if (i < toLoad.sounds.length) {
				if (!equal(filePart(file), filePart(toLoad.sounds[i]))) {
					ret ~= file;
				}
			} else {
				ret ~= reference.sounds[i .. $];
				break;
			}
		}
		return ret;
	}

}
