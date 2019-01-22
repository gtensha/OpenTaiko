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
import std.process : execute;
import std.typecons : tuple, Tuple;

import opentaiko.drum;
import opentaiko.bashable;
import opentaiko.score;
import opentaiko.song;
import opentaiko.gamevars;
import opentaiko.difficulty;
import opentaiko.performance;
import opentaiko.player;
import opentaiko.keybinds;
import opentaiko.languagehandler : Message;

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
	
	private static ffmpegStatusChecked = false;
	private static ffmpegAvailability = false;
	
	/// Returns array of drum objects with desired properties
	static Bashable[] parseMapFromFile(string file) {
		int bpm = 140;
		int zoom = 4;
		double scroll = 1;
		string map = cast(string)(std.file.read(file));
		string[] lines = split(map, "\n");
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
		bool processingDrumRoll = false;
		int drumRollLength = 0;
		Bashable[] drumArray;
		foreach (char type ; section) {
			if (type == 'O' || type == 'o') {
				drumRollLength++;
			} else {
				if (drumRollLength > 0) {
					int startTime = calculatePosition(index - drumRollLength,
													  offset,
													  bpm);
					int length = calculatePosition(index,
												   offset,
												   bpm) - startTime;
					drumArray ~= new DrumRoll(0,
											  0,
											  startTime,
											  scroll,
											  length);
				}
				drumRollLength = 0;
				if (type == 'd') {
					drumArray ~= new RedDrum(0,
											 0,
											 calculatePosition(index,
															   offset,
															   bpm),
											 scroll);
				} else if (type == 'D') {
					drumArray ~= new LargeRedDrum(0,
												  0,
												  calculatePosition(index,
																	offset,
																	bpm),
												  scroll);
				} else if (type == 'k') {
					drumArray ~= new BlueDrum(0,
											  0,
											  calculatePosition(index,
																offset,
																bpm),
											  scroll);
				} else if (type == 'K') {
					drumArray ~= new LargeBlueDrum(0,
												   0,
												   calculatePosition(index,
																	 offset,
																	 bpm),
												   scroll);
				} else if (type == '\r') { // ignore Windows' carriage return
					continue;
				}
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
		
		const string directory = MAP_DIR ~ songTitle;
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
	
	/// Returns true if the FFMPEG command can be used
	static bool ffmpegAvailable() {
		if (!ffmpegStatusChecked) {
			auto result = execute([FFMPEG.COMMAND, FFMPEG.VERSION_FLAG]);
			ffmpegAvailability = result.status == 0;
			ffmpegStatusChecked = true;
		}
		return ffmpegAvailability;
	}
	
	/// Convert the file at path infile to a .ogg file using ffmpeg, where
	/// outfile is the desired path to the converted file.
	/// Delete infile if shouldDelete is true and file was converted
	/// successfully
	static void convertToOgg(string infile, string outfile, bool shouldDelete) {
		isFile(infile);
		if (exists(outfile)) {
			rename(outfile, outfile ~ OLD_SUFFIX);
		}
		auto result = execute([FFMPEG.COMMAND, FFMPEG.INPUT_FLAG, infile, outfile]);
		if (result.status != 0) {
			rename(outfile ~ OLD_SUFFIX, outfile);
			throw new Exception("Conversion failed: " ~ result.output);
		} else {
			remove(outfile ~ OLD_SUFFIX);
		}
		if (shouldDelete) {
			remove(infile);
		}
	}

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
	
	/// Returns a GameVars struct reflecting the .json file from fileLoc
	static GameVars readConfFile(string fileLoc) {

		GameVars gameVars;
		string input = cast(string)read(fileLoc);

		JSONValue vars = parseJSON(input);

		foreach (int i, JSONValue dimension ; vars["resolution"].array) {
			gameVars.resolution[i] = to!int(dimension.integer);
		}

		if (vars["vsync"].type == JSON_TYPE.TRUE) {
			gameVars.vsync = true;
		} else {
			gameVars.vsync = false;
		}
		
		gameVars.language = vars["language"].str;

		return gameVars;
	}
	
	static void writeConfFile(GameVars options, string dest) {
		JSONValue vars = JSONValue(["resolution": options.resolution]);
		//vars.object["resolution"] = JSONValue(options.resolution);
		vars.object["vsync"] = JSONValue(options.vsync);
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
	
	static Tuple!(string[string], string[Message.MESSAGE_AMOUNT][string]) readLocaleDir(immutable string[Message.MESSAGE_AMOUNT] messageIDs) {
		string[Message.MESSAGE_AMOUNT][string] languageBindings;
		string[string] languageNameAssoc;
		foreach (DirEntry filepath ; dirEntries(LOCALE_DIR, SpanMode.shallow)) {
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
	
}
