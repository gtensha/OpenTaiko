module opentaiko.mapgen;

import std.conv;
import std.stdio;
import std.file;
import std.algorithm.searching;
import std.algorithm.comparison;
import std.algorithm.iteration;
import std.array;
import std.string;
import std.ascii;
import std.json;
import std.zip;

import opentaiko.drum;
import opentaiko.bashable;
import opentaiko.song;
import opentaiko.gamevars;
import opentaiko.difficulty;
import opentaiko.performance;
import opentaiko.player;
import opentaiko.keybinds;

enum {
	string MAP_DIR = "maps/",
	int WIDTH = 0,
	int HEIGHT = 1,
	int RED1 = 0,
	int RED2 = 1,
	int BLUE1 = 2,
	int BLUE2 = 3,
}

/// Struct for internal use holding map data and conventional Difficulty struct
struct MappedDifficulty {
	Difficulty diff;
	Song metadata;
	string map;
}

/// Class with static methods to handle OpenTaiko map and settings
/// loading/writing
class MapGen {

	/*
	Map structure (one line): e.g "ddk|d|d|kkd"
	or with spaces and small letters: "ddkd  d d kkdk"
	any character that isn't designated acts as empty space
	see default map.conf file for template and attribute
	specification
	*/

	/// Returns array of drum objects with desired properties
	static Bashable[] parseMapFromFile(string file) {
		int bpm = 140;
		int zoom = 4;
		double scroll = 1;
		string map = cast(string)(std.file.read(file));
		string[] lines = split(map, std.ascii.newline);
		Bashable[] drumArray;

		int i;
		int offset;
		bool processAttrs = true;
		bool processMap = false;
		foreach (string line ; lines) {

			// Ignore lines starting with '#' (comments)
			if (!line.equal("") && line[0] != '#') {

				bool foundTag = false;
				string[] formattedLine = split(line);
				// Check if should still/again check attributes
				switch (formattedLine[0]) {
					case "!attrs":
						processAttrs = true;
						processMap = false;
						foundTag = true;
						break;

					case "!endattrs":
						processAttrs = false;
						bpm = bpm * zoom;
						foundTag = true;
						break;

					case "!mapend":
						processMap = false;
						foundTag = true;
						break;

					case "!mapstart":
						processAttrs = false;
						processMap = true;
						foundTag = true;
						break;

					case "!offset":
						// This has no mercy, you MUST make sure your
						// offset is behind all circles placed so far
						offset = to!int(formattedLine[1]);
						i = 0;
						foundTag = true;
						break;

					case "!scroll":
						scroll = to!double(formattedLine[1]);
						foundTag = true;
						break;

					default:
						// Quit early if funky situation occurs
						if (processAttrs == processMap) {
							writeln("Map file error, no map was produced");
							return null;
						}
						break;
				}

				// Check for BPM or Zoom attributes
				if (!foundTag && processAttrs) {
					string[] vars = split(line);
					if (line[0] == 'B' || line[0] == 'b') {
						bpm = to!int(vars[1]);
					} else if (line[0] == 'Z' || line[0] == 'z') {
						zoom = to!int(vars[1]);
					}
				} else if (!foundTag && processMap) { // else process as map data
					drumArray ~= readMapSection(line, bpm, scroll, &i, offset);
				}
			}
		}
		return drumArray;
	}

	/// Calculate circle's position in milliseconds
	static int calculatePosition(int i, int offset, int bpm) {
		return cast(int)(((60 / (to!double(bpm))) * to!double(i)) * 1000.0) + offset;
	}

	/// Return array of Bashable from a map in string form from section with
	/// given attributes
	static Bashable[] readMapSection(string section,
									 int bpm,
									 double scroll,
									 int* i,
									 int offset) {
		int index = *i;
		Bashable[] drumArray;
		foreach (char type ; section) {
			if (type == 'D' || type == 'd') {
				drumArray ~= new RedDrum(0,
										 0,
										 calculatePosition(index, offset, bpm),
										 scroll);
			} else if (type == 'K' || type == 'k') {
				drumArray ~= new BlueDrum(0,
										  0,
										  calculatePosition(index, offset, bpm),
										  scroll);
			}
			index++;
		}
		*i = index;
		return drumArray;
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
	static void extractOSZ(string path) {
		Song newSong;
		if (path.length < 5 || equal(path[path.length - 3 .. path.length],
		                             ".osz")) {
			throw new Exception("Bad file extension");
		}
		string[] pathParts = path.split("/");
		string songTitle = pathParts[pathParts.length - 1];
		songTitle = songTitle[0 .. songTitle.length - 4];
		ZipArchive archive = new ZipArchive(read(path));
		
		const string directory = "maps/" ~ songTitle;
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
		
		//newSong.title = songTitle;

		JSONValue metadata;
		string metaPath = directory ~ "/" ~ "meta.json";
		metadata = songToJSON(newSong);		
		writeln(newSong.difficulties.length);
		std.file.write(metaPath, toJSON(metadata, true));
		
	}

	/// Reads the string data as a .osu file, parses it and returns a
	/// MappedDifficulty struct with song, difficulty and map data from the file
	static MappedDifficulty fromOSU(string data) {

		string openTaikoMap;
		string[] lines = split(data, "\r\n");

		//writeln(lines);
		Song song;
		Difficulty diff;

		bool objectSection = false;
		bool generalSection = false;
		bool metaSection = false;

		openTaikoMap ~= "# Map converted from .osu format" ~ "\n\n";
		openTaikoMap ~= "!mapstart" ~ "\n";

		foreach (string line ; lines) {

			if (line.canFind("[HitObjects]")) {
				objectSection = true;
				generalSection = false;
				metaSection = false;
			} else if (line.canFind("[General]")) {
				generalSection = true;
				objectSection = false;
				metaSection = false;
			} else if (line.canFind("[Metadata]")) {
				metaSection = true;
				objectSection = false;
				generalSection = false;

			} else if (generalSection) {
				if (canFind(line, "AudioFilename:")) {
					song.src = findSplitAfter(line, "AudioFilename: ")[1];
				}				

			} else if (metaSection) {
				string[] identifier = split(line, ":");
				if (identifier.length > 1) {
					switch (identifier[0]) {
						case "Title":
							song.title = findSplitAfter(line, "Title:")[1];
							break;

						case "Artist":
							song.artist = findSplitAfter(line, "Artist:")[1];
							break;

						case "Creator":
							song.maintainer = findSplitAfter(line, "Creator:")[1];
							break;
							
						case "Tags":
							song.tags = findSplitAfter(line, "Tags:")[1].split();
							break;

						case "Version":
							diff.name = findSplitAfter(line, "Version:")[1];
							diff.difficulty = 0;
							song.difficulties ~= diff;
							break;

						default:
							break;
					}					
				}					
			} else if (objectSection) {
				string[] properties = split(line, ',');
				if (properties.length >= 5) {
					if (properties[3].equal("1")) {
						openTaikoMap ~= "!offset " ~ properties[2] ~ "\n";
						switch (properties[4]) {

							case "0":
								openTaikoMap ~= "d" ~ "\n";
								break;

							case "2":
								openTaikoMap ~= "k" ~ "\n";
								break;

							case "8":
								goto case "2";

							case "6":
								goto case "2";

							default:
								break;
						}
					}
				}
			}
		}

		openTaikoMap ~= "!mapend";

		diff.mapper = song.maintainer;
		MappedDifficulty ret;
		ret.map = openTaikoMap;
		ret.diff = diff;
		ret.metadata = song;
		return ret;

	}

	abstract string fromTJAFile(string file);

	/// Reads the maps/ directory and returns an array of Song structs
	static Song[] readSongDatabase() {
		Song[] songs;

		foreach (string dir ; dirEntries(MAP_DIR, SpanMode.shallow)) {
			try {
				JSONValue map = parseJSON(cast(string)(std.file.read(dir
																     ~ "/meta.json")));

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
			} catch (Exception e) {
				writeln(e.msg);
			}
		}
		return songs;
	}
	
	/// Returns the path to an image file if it was found in directory, or null
	/// if none could be found. Include '/' in directory name string
	static string findImage(string directory) { // TODO: make this efficient
	
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
	
	/// Returns a GameVars struct reflecting the .json file from fileLoc
	static GameVars readConfFile(string fileLoc) {

		GameVars gameVars;
		string input = to!string(std.file.read(fileLoc));

		JSONValue vars = parseJSON(input);

		if (!(vars["defaultKeys"].array.length == 4
			  &&
			  vars["resolution"].array.length == 2
			  &&
			  (vars["vsync"].type == JSON_TYPE.TRUE || vars["vsync"].type == JSON_TYPE.FALSE))) {

			throw new Exception("Incorrect parameters in config file");
		}

		int i;
		foreach (JSONValue key ; vars["defaultKeys"].array) {
			gameVars.defaultKeys[i] = to!int(key.integer);
			i++;
		} i = 0;

		foreach (JSONValue dimension ; vars["resolution"].array) {
			gameVars.resolution[i] = to!int(dimension.integer);
			i++;
		} i = 0;

		if (vars["vsync"].type == JSON_TYPE.TRUE) {
			gameVars.vsync = true;
		} else {
			gameVars.vsync = false;
		}

		return gameVars;
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
	
}
