//  This file is part of the OpenTaiko project.
//  <https://github.com/gtensha/OpenTaiko>
//
/// Functionality for reading and writing map data, settings and localisation
/// to and from disk. Almost all features related to those tasks should go in
/// this file.
///
/// Authors: gtensha (@skyhvelv.net)
/// Copyright: 2017-2020 gtensha
/// License: GNU GPLv3 (no later versions)
//
//  You should have received a copy of the GNU General Public License
//  along with OpenTaiko. If not, see <https://www.gnu.org/licenses/>.

module opentaiko.mapgen;

import std.algorithm.comparison;
import std.algorithm.iteration;
import std.algorithm.mutation : reverse;
import std.algorithm.searching;
import std.array;
import std.ascii;
import std.conv;
import std.file;
import std.json;
import std.process : execute, ProcessException;
import std.stdio : writeln;
import std.string;
import std.typecons : tuple, Tuple;
import std.zip;

import opentaiko.bashable;
import opentaiko.difficulty;
import opentaiko.drum;
import opentaiko.gamevars;
import opentaiko.keybinds;
import opentaiko.languagehandler : Message;
import opentaiko.performance;
import opentaiko.player;
import opentaiko.score;
import opentaiko.song;
import opentaiko.timingvars;

enum {
	string MAP_DIR = "maps/",
	string LOCALE_DIR = "locale/",
	string OGG_EXTENSION = ".ogg",
	string OLD_SUFFIX = ".old",
	int WIDTH = 0,
	int HEIGHT = 1,
	int RED1 = 0,
	int RED2 = 1,
	int BLUE1 = 2,
	int BLUE2 = 3,
}

enum FFMPEG : string {
	COMMAND = "ffmpeg",
	INPUT_FLAG = "-i",
	VERSION_FLAG = "-version"
}

/// Struct for internal use holding map data and conventional Difficulty struct
struct MappedDifficulty {
	Difficulty diff;
	Song metadata;
	string map;
}

/// Exception thrown on error parsing an otfm file. This is the only exception
/// regarding OTFM parsing meant to be thrown (and caught) by outside modules
/// calling parseMapFromFile.
class OTFMException : Exception {

	this(Exception reason,
		 const size_t lineNum,
		 const size_t charIndex,
		 const string line,
		 const string fileName) {

		immutable msg = format("Error parsing otfm file \"%s\" on line %d:\n\n",
							   fileName,
							   lineNum);
		immutable pointer = line ~ "\n" ~ rightJustify("^", charIndex) ~ "\n";
		debug {
			immutable remainder = reason.toString();
		} else {
			immutable remainder = reason.msg;
		}
		this.next = reason;
		super(msg ~ pointer ~ remainder);
	}

}

/// Exception thrown on internal errors parsing an otfm file. Generally, this
/// should not be thrown for functions meant to be called outside this module.
class OTFMInternalException : Exception {

	/// Error occured parsing the character at this index in the line.
	immutable size_t charIndex;

	this(string msg, const size_t charIndex) {
		this.charIndex = charIndex;
		super(msg);
	}

}

/// Exception thrown on failure to parse a line of an otfm file.
class OTFMParseException : OTFMInternalException {

	this(string msg, const size_t charIndex, Exception next) {
		this.next = next;
		super(msg, charIndex);
	}

}

/// Class with static methods to handle OpenTaiko map and settings
/// loading/writing
class MapGen {

	/// Different ways to group hit objects (displaying separators).
	enum GroupBy : byte {
		VALUE /// Group every n objects, where n is group * zoom
	}
	
	private static ffmpegStatusChecked = false;
	private static ffmpegAvailability = false;

	/// If an error occured when loading language with id as key, then the error
	/// message is stored as the value for reading in here.
	public static string[string] languageLoadErrors;
	
	/// Reads file as a map in the otfm format and returns a Bashable array
	/// from the read contents.
	static Bashable[][2] parseMapFromFile(const string file) {
		const string map = cast(string)(read(file));
		const string[] lines = map.split("\n");
		int bpm = 60;
		int zoom = 1;
		int group = 0;
		byte groupMode = GroupBy.VALUE;
		double scroll = 1;
		Bashable[] drumArray;
		Bashable[] cosmeticArray;
		int index;
		int offset;

		void setBPM(const string[] line) {
			if (line.length > 0) {
				bpm = to!int(line[0]);
			}
		}

		void setZoom(const string[] line) {
			if (line.length > 0) {
				if (index > 0) {
					index--;
					const int remainingBeats = zoom - index % zoom;
					offset = calculatePosition(index + remainingBeats,
											   offset,
											   bpm * zoom);
				}
				zoom = to!int(line[0]);
				index = 0;
			}
		}

		void reset(const string[]) {
			if (index > 0) {
				offset = calculatePosition(index - 1, offset, bpm * zoom);
				index = 0;
			}
		}

		void setScroll(const string[] line) {
			if (line.length > 0) {
				scroll = to!double(line[0]);
			}
		}

		void setGroup(const string[] line) {
			if (line.length > 0) {
				if (line[0].isNumeric()) {
					group = to!int(line[0]);
				    groupMode = GroupBy.VALUE;
				} else {
					string msg = ("Invalid value for command \"group\": "
								  ~ line[0]);
					throw new OTFMInternalException(msg, 0);
				}
			}
		}

		void setOffset(const string[] line) {
			if (line.length > 0) {
				offset = to!int(line[0]);
				index = 0;
			}
		}

		void parseHitObjects(const dstring line) {
			Tuple!(Bashable[][2], int) ret = readMapSection(line,
															bpm,
															zoom,
															scroll,
															index,
															offset,
															group);
			drumArray ~= ret[0][0];
			cosmeticArray ~= ret[0][1];
			index = ret[1];
		}

		alias delegateAA = immutable void delegate(const string[])[string];
		delegateAA handlers = ["!bpm": &setBPM,
							   "!zoom": &setZoom,
							   "!reset": &reset,
							   "!scroll": &setScroll,
							   "!group": &setGroup,
							   "!offset": &setOffset];
		foreach (size_t i, const string line ; lines) {
			const char first = line.length > 0 ? line[0] : '#';
			switch (first) {
				case '!':
					const string[] split = line.split(" ");
					immutable void delegate(const string[])* fn = (split[0]
																   in handlers);
					if (fn) {
						const string[] args = (split.length > 1
											   ? split[1 .. $] : []);
						try {
							(*fn)(args);
						} catch (ConvException e) {
							size_t charIndex = split[0].length + 2;
							if (charIndex >= line.length) {
								charIndex = 0;
							}
							throw new OTFMException(e, i, charIndex, line, file);
						} catch (OTFMInternalException e) {
							size_t charIndex = split[0].length + 2 + e.charIndex;
							if (charIndex >= line.length) {
								charIndex = 0;
							}
							throw new OTFMException(e, i, charIndex, line, file);
						}
					} else {
						immutable msg = format("Unrecognised command \"%s\"",
											   split[0]);
						OTFMInternalException e;
						e = new OTFMInternalException(msg, 0);
						throw new OTFMException(e, i, e.charIndex, line, file);
					}
					break;

				case '#':
					break;

				default:
					parseHitObjects(to!dstring(line));
					break;
			}
		}
		return [drumArray, cosmeticArray];
	}

	/// Calculate a hit object's position in milliseconds from its index
	/// relative to offset, using bpm (use the real bpm value, bpm * scroll).
	static pure int calculatePosition(const int index, const int offset, const int bpm) {
		return cast(int)((60000.0 / bpm) * index) + offset;
	}

	/// Return a tuple with array of Bashable and index modified according to
	/// new hit objects. section is a line (without a newline) containing hit
	/// objects in the otfm format, and offset is the value of the last !offset
	/// command.
	static Tuple!(Bashable[][2], int) readMapSection(const dstring section,
													 const int bpm,
													 const int zoom,
													 const double scroll,
													 int index,
													 const int offset,
													 const int group) {
		const int realBPM = bpm * zoom;
		Bashable[] drumArray;
		Bashable[] cosmeticArray;
		int drumRollLength = 0;
		DrumRoll makeDrumRoll() {
			int startTime = calculatePosition(index - drumRollLength,
											  offset,
											  realBPM);
			int length = calculatePosition(index,
										   offset,
										   realBPM) - startTime;
			return new DrumRoll(0, 0, startTime, scroll, length);
		}
		foreach (const dchar type ; section) {
			int currentOffset = calculatePosition(index, offset, realBPM);
			if (group > 0 && index % (zoom * group) == 0) {
				cosmeticArray ~= new Separator(currentOffset, scroll);
			}
			if (type == 'O' || type == 'o') {
				drumRollLength++;
			} else {
				if (drumRollLength > 0) {
					drumArray ~= makeDrumRoll();
				}
				drumRollLength = 0;
				Bashable next;
				if (type == 'd') {
				    next = new RedDrum(0, 0, currentOffset, scroll);
				} else if (type == 'D') {
				    next = new LargeRedDrum(0, 0, currentOffset, scroll);
				} else if (type == 'k') {
					next = new BlueDrum(0, 0, currentOffset, scroll);
				} else if (type == 'K') {
					next = new LargeBlueDrum(0, 0, currentOffset, scroll);
				} else if (type == '\r') { // ignore Windows' carriage return
					continue;
				}
				if (next) {
					drumArray ~= next;
				}
			}
			index++;
		}
		if (drumRollLength > 0) {
			drumArray ~= makeDrumRoll();
		}
		Bashable[][2] arr = [drumArray, cosmeticArray];
		return tuple(arr, index);
	}

	/// Returns a JSONValue representing the Song struct song as JSON
	static JSONValue songToJSON(Song song) {
		JSONValue metaFile = JSONValue(["title": song.title,
										"artist": song.artist,
										"maintainer": song.maintainer,
										"src": song.src,
										"difficulties": null]);
										
		metaFile["difficulties"].array = null;
										
		metaFile.object["tags"] = JSONValue(song.tags);
		foreach (Difficulty diff ; song.difficulties) {
			JSONValue diffJSON;
			diffJSON = JSONValue(["name": diff.name, "difficulty": null, "mapper": diff.mapper]);
			diffJSON.object["difficulty"] = diff.difficulty;
			metaFile["difficulties"].array ~= diffJSON;
		}

		return metaFile;
	}
	
	//static Song jsonToSong(JSONValue data);
	
	/// Extracts a .osz file into the directory maps/[archive name].
	/// It merges existing data.
	/// It may register wrong filenames if the difficulties inside have
	/// different ones (different audio files, backgrounds etc).
	static void extractOSZ(string path, string userDir) {
		Song newSong;
		version (Windows) {
			path = path.split("\\").join("/");
		}
		string[] pathParts = path.split("/");
		string songTitle = pathParts[pathParts.length - 1];
		songTitle = songTitle[0 .. songTitle.length - 4];
		ZipArchive archive = new ZipArchive(read(path));
		
		const string directory = userDir ~ MAP_DIR ~ songTitle;
		if (!exists(directory)) {
			mkdir(directory);
		}
		
		bool firstMapRead = true;
		
		foreach (name, am ; archive.directory) {
			const string[] extensions = name.split(".");
			const string extension = extensions[extensions.length - 1];
			
			switch (extension) {
		
				case "osu":
					MappedDifficulty diff = fromOSU(cast(string)archive.expand(am));
					if (firstMapRead) {
						newSong = diff.metadata;
						newSong.difficulties = null;
						firstMapRead = false;
					}
					newSong.difficulties ~= diff.diff; // TODO fix duplicates registering
					std.file.write(directory ~ "/" ~ diff.diff.name ~ ".otfm",
					               diff.map);
					
					goto outside;
				
				default:
					std.file.write(directory ~ "/" ~ name, archive.expand(am));
					goto outside;
							
			}
			outside:
		}

		if (ffmpegAvailable()) {
			string[] splitAudioPath = newSong.src.split(".");
			string newAudioPath;
			if (splitAudioPath.length > 1) {
				splitAudioPath[splitAudioPath.length - 1] = OGG_EXTENSION;
				newAudioPath = splitAudioPath.join("");
			} else {
				newAudioPath = newSong.src ~ OGG_EXTENSION;
			}
			convertToOgg(directory ~ "/" ~ newSong.src, directory ~ "/" ~ newAudioPath, true);
			newSong.src = newAudioPath;
		}
		
		JSONValue metadata;
		string metaPath = directory ~ "/" ~ "meta.json";
		metadata = songToJSON(newSong);
		std.file.write(metaPath, toJSON(metadata, true));
	}

	/// Reads the string data as a .osu file, parses it and returns a
	/// MappedDifficulty struct with song, difficulty and map data from the
	/// file.
	static MappedDifficulty fromOSU(const string data) {

		string openTaikoMap;
		openTaikoMap ~= "# Map converted from .osu format" ~ "\n\n";
		const dstring[] lines = split(to!dstring(data), "\r\n");

		Song song;
		Difficulty diff;

		void delegate(const dstring)[string] sectionParsers;
		void delegate(const dstring) activeParser;

		const void delegate(dstring)[string] attributeCallbacks = [
			// [General]
			"AudioFilename": (dstring s){
				song.src = to!string(s);
			},
			// [Metadata]
			"Title": (dstring s){
				song.title = to!string(s);
			},
			"Artist": (dstring s){
				song.artist = to!string(s);
			},
			"Creator": (dstring s){
				song.maintainer = to!string(s);
				diff.mapper = to!string(s);
			},
			"Version": (dstring s){
				diff.name = to!string(s);
			},
			"Tags": (dstring s){
				song.tags = to!string(s).split(" ");
			},
			// [Difficulty]
			"OverallDifficulty": (dstring s){
				if (s.isNumeric()) {
					diff.difficulty = cast(int)(to!double(s));
				}
			}
		];

		struct KVPair {
			dstring key;
			dstring value;
		}

		struct TimingSection {
			int startTime;
			int bpm;
			int group;
			Tuple!(int, double)[] scrollChanges;
		}

		TimingSection[] timingSections;
		Tuple!(int, int, char)[] hitObjects; // time, length, type

		/// Returns the key and value from line, split using delim. Only splits
		/// on the first occurence of delim.
		KVPair keyValueSplitter(const dstring line, const string delim) {
			const dstring[] split = line.split(delim);
			KVPair ret;
			ret.key = split[0];
			if (split.length >= 2) {
			    ret.value = split[1 .. $].join(delim);
			}
			return ret;
		}

		void applyAttribute(const KVPair pair,
							const void delegate(dstring)[string] cb) {

			const void delegate(dstring)* fn = to!string(pair.key) in cb;
			if (fn) {
				(*fn)(pair.value);
			}
		}

		// [General]
		void generalParser(const dstring line) {
			applyAttribute(keyValueSplitter(line, ": "), attributeCallbacks);
		}

		// [Editor]
		void editorParser(const dstring line) {}

		// [Metadata]
		void metadataParser(const dstring line) {
			applyAttribute(keyValueSplitter(line, ":"), attributeCallbacks);
		}

		// [Difficulty]
		void difficultyParser(const dstring line) {
			applyAttribute(keyValueSplitter(line, ":"), attributeCallbacks);
		}

		// [Events]
		void eventsParser(const dstring line) {}

		// [TimingPoints]
		void timingPointsParser(const dstring line) {
			if (line.length < 1) {
				return;
			}
			const dstring[] split = line.split(",");
			if (split.length > 0 && split.length != 8) {
				// TODO: Proper error handling
				throw new Exception("Malformed .osu file: TimingPoints");
			}
			const int time = cast(int)(to!real(split[0]));
			const double beatLength = to!double(split[1]);
			const int meter = cast(int)(to!real(split[2]));
			if (beatLength > 0) {
				TimingSection newSection;
				const int bpm = cast(int)((1 / beatLength) * 60000.0);
				newSection.startTime = time;
				newSection.bpm = bpm;
				newSection.group = meter;
				timingSections ~= newSection;
			} else if (timingSections.length > 0) {
				const double scroll = beatLength / -100;
				timingSections[$ - 1].scrollChanges ~= tuple(time + 0,
															 scroll + 0);
			}
		}

		// [Colours]
		void coloursParser(const dstring line) {}

		// [HitObjects]
		void hitObjectsParser(const dstring line) {
			if (line.length < 1) {
				return;
			}
			const dstring[] split = line.split(",");
			if (split.length < 6) {
				// TODO: Proper error handling
				throw new Exception("Malformed .osu file: HitObjects");
			}
			const int time = to!int(split[2]);
			const byte type = to!byte(split[3]);
			if (type & 0b0001) { // regular drum
				const byte soundType = to!ubyte(split[4]);
				char variant;
				if ((soundType & 0b0010) || (soundType & 0b1000)) { // kat
					variant = 'k';
				} else { // don
					variant = 'd';
				}
				if (soundType & 0b0100) { // enlarge
					variant -= 'a' - 'A';
				}
				hitObjects ~= tuple(time + 0, 0, cast(char)variant);
			} else if (type & 0b0010) { // slider
				// TODO: implement sliders
			} else if (type & 0b1000) { // spinner (converts to slider)
				const char variant = 'O';
				const int duration = to!int(split[5]) - time;
				hitObjects ~= tuple(time + 0, duration + 0, cast(char)variant);
			}
		}

		sectionParsers = ["[General]": &generalParser,
						  "[Editor]": &editorParser,
						  "[Metadata]": &metadataParser,
						  "[Difficulty]": &difficultyParser,
						  "[Events]": &eventsParser,
						  "[TimingPoints]": &timingPointsParser,
						  "[Colours]": &coloursParser,
						  "[HitObjects]": &hitObjectsParser];

		foreach (const dstring line ; lines) {
			if (line.length < 1) {
				continue;
			}
			void delegate(const dstring)* fn = (to!string(line)
												in sectionParsers);
			if (fn) {
				activeParser = *fn;
			} else if (activeParser) {
				activeParser(line);
			}
		}

		int hitObjectIndex;
		for (int i = 0; i < timingSections.length; i++) {
			TimingSection section = timingSections[i];
			openTaikoMap ~= format("!bpm %d\n", section.bpm);
			int scrollChangeIndex;
			int nextSectionStart;
			if (i + 1 < timingSections.length) {
				nextSectionStart = timingSections[i + 1].startTime;
			} else {
				nextSectionStart = int.max;
			}
			while (hitObjectIndex < hitObjects.length
				   && hitObjects[hitObjectIndex][0] < nextSectionStart) {

				Tuple!(int, int, char) object = hitObjects[hitObjectIndex];
				Tuple!(int, double) scrollChange;
				if (scrollChangeIndex < section.scrollChanges.length) {
					scrollChange = section.scrollChanges[scrollChangeIndex];
				} else {
					scrollChange = tuple(int.max, 1.0);
				}
				if (scrollChange[0] <= object[0]) {
					openTaikoMap ~= format("!scroll %f\n", scrollChange[1]);
					scrollChangeIndex++;
				}
				if (object[2] == 'O') { // TODO: proper drum roll length
					static immutable int zoom = 16;
					openTaikoMap ~= format("!zoom %d\n", zoom);
					openTaikoMap ~= format("!offset %d\n", object[0]);
					int accumulatedTime = object[0];
					int objectsAdded;
					while (accumulatedTime < object[0] + object[1]) {
						openTaikoMap ~= 'o';
						accumulatedTime = calculatePosition(objectsAdded,
															object[0],
															section.bpm * zoom);
						objectsAdded++;
					}
					openTaikoMap ~= '\n';
				} else {
					openTaikoMap ~= format("!offset %d\n", object[0]);
					openTaikoMap ~= object[2] ~ "\n";
				}
				hitObjectIndex++;
			}
		}

		MappedDifficulty ret;
		ret.map = openTaikoMap;
		ret.diff = diff;
		ret.metadata = song;
		return ret;
	}

	abstract string fromTJAFile(string file);
	
	/// Returns true if the FFMPEG command can be used
	static bool ffmpegAvailable() {
		if (!ffmpegStatusChecked) {
			ffmpegStatusChecked = true;
			try {
				auto result = execute([FFMPEG.COMMAND, FFMPEG.VERSION_FLAG]);
				ffmpegAvailability = result.status == 0;
			} catch (ProcessException e) {
				writeln("Warning: FFMPEG execute failed: " ~ e.msg);
				return false;
			}
		}
		return ffmpegAvailability;
	}
	
	/// Convert the file at path infile to a .ogg file using ffmpeg, where
	/// outfile is the desired path to the converted file.
	/// Delete infile if shouldDelete is true and file was converted
	/// successfully
	static void convertToOgg(string infile, string outfile, bool shouldDelete) {
		isFile(infile);
		bool fileExisted;
		if (exists(outfile)) {
			rename(outfile, outfile ~ OLD_SUFFIX);
			fileExisted = true;
		}
		auto result = execute([FFMPEG.COMMAND, FFMPEG.INPUT_FLAG, infile, outfile]);
		if (result.status != 0) {
			rename(outfile ~ OLD_SUFFIX, outfile);
			throw new Exception("Conversion failed: " ~ result.output);
		} else if (fileExisted) {
			remove(outfile ~ OLD_SUFFIX);
		}
		if (shouldDelete) {
			remove(infile);
		}
	}

	/// Reads the maps/ directory and returns an array of Song structs, where
	/// userDir is the path to the directory where the maps/ directory is
	/// contained.
	static Song[] readSongDatabase(const string userDir) {
		Song[] songs;
		foreach (string dir ; dirEntries(userDir ~ MAP_DIR, SpanMode.shallow)) {
			const string jsonFile = dir ~ "/meta.json";
			if (isDir(dir) && exists(jsonFile) && isFile(jsonFile)) {
				try {
					JSONValue map = parseJSON(cast(string)(read(jsonFile)));
					Song song = {
						map["title"].str,
						map["artist"].str,
						map["maintainer"].str,
						null,
						map["src"].str,
						dir,
						null
					};
					foreach (JSONValue tag ; map["tags"].array) {
						song.tags ~= tag.str;
					}
					foreach (JSONValue difficulty ; map["difficulties"].array) {
						Difficulty diff = {
							difficulty["name"].str,
							to!int(difficulty["difficulty"].integer),
							difficulty["mapper"].str
						};
						song.difficulties ~= diff;
					}
					songs ~= song;
				} catch (JSONException e) {
					writeln(dir ~ " load error, malformed meta.json: " ~ e.msg);
				}
			}
		}
		return songs;
	}

	/// Takes baseDir as the base user directory (with a trailing slash) and
	/// creates the normal directory structure for the maps/ directory.
	static void writeSongDatabaseTree(string baseDir) {
		if (exists(baseDir) && isDir(baseDir)) {
			const string p = (baseDir ~ MAP_DIR).split("\\").join("/");
			if (!exists(p)) {
				mkdir(p);
			}
		} else {
			throw new FileException(baseDir ~ " does not exist.");
		}
	}
	
	/// Returns the path to an image file if it was found in directory, or null
	/// if none could be found. Include '/' in directory name string
	static string findImage(string directory) { // TODO: make this efficient
	
		version(Windows) {
			directory = directory.split("/").join("\\");
		}

		static immutable supportedExts = ["jpg", "jpeg", "png", "gif"];
		static immutable priorityFiles = ["thumb.png", "thumb.jpg", "bg.jpg"];
		
		foreach (string file ; priorityFiles) {
			if (exists(directory ~ file)) {
				return file;
			}					
		}		
	
		foreach (string file ; dirEntries(directory, SpanMode.shallow)) {
			string[] exts = file.split(".");
			if (exts.length > 1) {
				string fileExt = exts[exts.length - 1];
				foreach (string ext ; supportedExts) {
				    if (ext.equal(fileExt)) {
					    return file;
				    }				
				}				
			}
		}

		return null;
	}	
	
	/// Returns a GameVars struct reflecting the .json file from fileLoc. If an
	/// entry does not exist in the file, then the corresponding value from
	/// defaultVals is loaded.
	static GameVars readConfFile(string fileLoc, GameVars defaultVals) {
		GameVars gameVars = defaultVals;
		string input = cast(string)read(fileLoc);
		JSONValue vars = parseJSON(input);
		const(JSONValue)* p = "resolution" in vars;
		if (p) {
			foreach (int i, JSONValue dimension ; (*p).array) {
				gameVars.resolution[i] = to!int(dimension.integer);
			}
		}
		p = "vsync" in vars;
		if (p) {
			gameVars.vsync = (*p).type == JSON_TYPE.TRUE;
		}
		p = "assets" in vars;
		if (p) {
			gameVars.assets = (*p).str;
		}
		if (gameVars.assets.length > 0 && gameVars.assets[$ - 1] != '/') {
			if (gameVars.assets[$ - 1] == '\\') {
				gameVars.assets = gameVars.assets[0 .. $ - 1] ~ "/";
			} else {
				gameVars.assets ~= "/";
			}
		}
		p = "language" in vars;
		if (p) {
			gameVars.language = (*p).str;
		}
		return gameVars;
	}
	
	static void writeConfFile(GameVars options, string dest) {
		JSONValue vars = JSONValue(["resolution": options.resolution]);
		//vars.object["resolution"] = JSONValue(options.resolution);
		vars.object["vsync"] = JSONValue(options.vsync);
		vars.object["assets"] = JSONValue(options.assets);
		vars.object["language"] = JSONValue(options.language);
		std.file.write(dest, toJSON(vars, true));
	}
	
	/// Reads the JSON file from given path and returns an AA of pointers to
	/// Player structs
	static Player*[int] readPlayerList(string fileLoc) {
		
		Player*[int] players;
		try {
			isFile(fileLoc);
		} catch (FileException e) {
			return null;
		}
		
		string input = cast(string)std.file.read(fileLoc);
		
		JSONValue vars = parseJSON(input);
		
		foreach (JSONValue player ; vars["players"].array) {
			string name;
			int id;
			int[] keybinds;
			
			name = player["name"].str;
			id = cast(int)player["id"].integer;
			foreach (JSONValue binding ; player["keybinds"].array) {
				keybinds ~= cast(int)binding.integer;
			}
			if (id in players) {
				throw new Exception("Player id mismatch in players.json: "
									~ name ~ " conflicts with " ~ players[id].name
									~ " with id " ~ to!string(id));
			}
			players[id] = new Player(name, id, keybinds);
		}
		
		return players;
		
	}
	
	/// Writes the Player array to JSON format in the given file
	static void writePlayerList(Player*[int] players, Player*[] activePlayers, string dest) {
		if (players !is null) {
			JSONValue[] vars;
			
			foreach (Player* player ; players) {
				JSONValue data;
				data["name"] = JSONValue(player.name);
				data["id"] = JSONValue(player.id);
				data["keybinds"] = JSONValue(player.keybinds);
				vars ~= data;
			}
			JSONValue lastOne = ["players": vars];
			lastOne.object["lastActive"] = JSONValue(activePlayers is null ? -1 : activePlayers[0].id);
			std.file.write(dest, toJSON(lastOne, true));
		}
		
	}
	
	/// Read key bindings from fileLoc and return array of Keybinds[] values
	static Keybinds[] readKeybindsFile(string fileLoc) {

		Keybinds[] playerBinds;
		isFile(fileLoc);
		
		JSONValue vars = parseJSON(cast(string)read(fileLoc));
		
		foreach (JSONValue binds ; vars["bindings"].array) {
			Keybinds bindings;
			const(JSONValue)* keyboard = "keyboard" in binds;
			if (keyboard !is null) {
				JSONValue keyboardz = *keyboard;
				foreach (int i, JSONValue key ; keyboardz.array) {
					int[] keyBindings;
					foreach (JSONValue keycode ; key.array) {
						keyBindings ~= cast(int)keycode.integer;
					}
					bindings.keyboard.drumKeys[i] = keyBindings;
				}
			}
			
			const(JSONValue)* controller = "controller" in binds;
			if (controller !is null) {
				JSONValue controllerz = *controller;
				foreach (int i, JSONValue button ; controllerz.array) {
					bindings.controller.drumKeys[i] = cast(int)button.integer;
				}
			}
			playerBinds ~= bindings;
		}
		
		return playerBinds;		
		
	}
	
	/// Writes keybinds to fileLoc as a JSON struct
	static void writeKeybindsFile(Keybinds[] keybinds, string fileLoc) {
		JSONValue[] vars;
		foreach (Keybinds binds ; keybinds) {
			JSONValue[] arrayElms;
			foreach (int[] keyCodes ; binds.keyboard.drumKeys) {
				arrayElms ~= JSONValue(keyCodes);
			}
			vars ~= JSONValue(["keyboard": JSONValue(arrayElms)]);
		}
		JSONValue finalDoc = JSONValue(["bindings": vars]);
		std.file.write(fileLoc, toJSON(finalDoc, true));
	}

	/// Reads the timings file at fileLoc as JSON and returns its equivalent
	/// TimingVars struct.
	static TimingVars readTimings(string fileLoc) {
		TimingVars timingVars;
		string input = cast(string)read(fileLoc);
		JSONValue vars = parseJSON(input);
		timingVars.hitOffset = cast(int)vars["hitOffset"].integer;
		timingVars.hitWindow = cast(uint)vars["hitWindow"].integer;
		timingVars.goodHitWindow = cast(uint)vars["goodHitWindow"].integer;
		timingVars.preHitDeadWindow = cast(uint)vars["preHitDeadWindow"].integer;
		return timingVars;
	}

	/// Writes the TimingVars struct to the file at fileLoc as JSON.
	static void writeTimings(TimingVars timingVars, string fileLoc) {
		JSONValue root = JSONValue(["hitOffset": timingVars.hitOffset,
									"hitWindow": timingVars.hitWindow,
									"goodHitWindow": timingVars.goodHitWindow,
									"preHitDeadWindow": timingVars.preHitDeadWindow]);
		write(fileLoc, toJSON(root, true));
	}
	
	static Tuple!(string, string[Message.MESSAGE_AMOUNT]) readLocaleFile(string[Message.MESSAGE_AMOUNT] messageList, string path) {
		string[Message.MESSAGE_AMOUNT] ret;
		JSONValue root = parseJSON(cast(string)read(path));
		string languageName = root["language"].str;
		JSONValue messages = root["message"];
		foreach (int i, string message ; messageList) {
			const(JSONValue*) match = message in messages;
			if (match !is null) {
				JSONValue deref = *match;
				ret[i] = deref.str;
			}
		}
		return tuple(languageName, ret);
	}
	
	static Tuple!(string[string], string[Message.MESSAGE_AMOUNT][string]) readLocaleDir(immutable string userDir, immutable string[Message.MESSAGE_AMOUNT] messageIDs) {
		string[Message.MESSAGE_AMOUNT][string] languageBindings;
		string[string] languageNameAssoc;
		foreach (DirEntry filepath ; dirEntries(userDir ~ LOCALE_DIR, SpanMode.shallow)) {
			string[] splitPath = filepath.name.split("/");
			const string filename = splitPath[splitPath.length - 1];
			string[] splitName = filename.split(".");
			if (splitName.length > 1 
			    && 
			    filepath.isFile() 
			    && 
			    splitName[splitName.length - 1].equal("json")) {

				string languageAbbrev = splitName[0 .. splitName.length - 1].join();
				try {
					auto returned = readLocaleFile(messageIDs, filepath.name);
					languageBindings[languageAbbrev] = returned[1];
					languageNameAssoc[languageAbbrev] = returned[0];
				} catch (JSONException e) {
					writeln("Warning: Language "
					        ~ filename
					        ~ " failed to load: "
					        ~ e.toString());
					languageLoadErrors[languageAbbrev] = e.toString();
					continue;
				}
			}
		}
		return tuple(languageNameAssoc, languageBindings);
	}

	/// Reads scores line by line from file and returns them as an array
	/// ordered by read sequence
	static Score[] readScores(string file) {
		if (!exists(file)) {
			return null;
		}
		string[] lines = split(cast(string)read(file), "\n");
		Score[] scores;
		foreach (string line ; lines) {
			if (line.length > 0) {
				scores ~= Score.fromString(line);
			}
		}
		return scores;
	}

	/// Appends string representation of score to the file at fileDest
	static void writeScore(Score score, string fileDest) {
		append(fileDest, score.toString() ~ "\n");
	}

	/// Returns an int stored as a string in file at path file
	static int getPlayerId(string file) {
		return to!int(cast(char[])read(file));
	}

	/// Write id to file fileDest as a string
	static void writePlayerId(int id, string fileDest) {
		write(fileDest, to!string(id));
	}
	
}
