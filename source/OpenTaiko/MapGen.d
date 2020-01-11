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

/// Class with static methods to handle OpenTaiko map and settings
/// loading/writing
class MapGen {

	/// Different ways to group hit objects (displaying separators).
	enum GroupBy : byte {
		VALUE, /// Group every n objects, dictated by index.
		ZOOM /// As VALUE, where n is always equal to zoom.
	}
	
	private static ffmpegStatusChecked = false;
	private static ffmpegAvailability = false;

	/// If an error occured when loading language with id as key, then the error
	/// message is stored as the value for reading in here.
	public static string[string] languageLoadErrors;
	
	/// Reads file as a map in the otfm format and returns a Bashable array
	/// from the read contents.
	static Bashable[] parseMapFromFile(const string file) {
		const string map = cast(string)(read(file));
		const string[] lines = map.split("\n");
		int bpm = 60;
		int zoom = 1;
		int group = 0;
		byte groupMode = GroupBy.VALUE;
		double scroll = 1;
		Bashable[] drumArray;
		int[] separatorTimes;
		int index;
		int offset;

		void setBPM(const string[] line) {
			if (line.length > 0) {
				bpm = to!int(line[0]);
			}
		}

		void setZoom(const string[] line) {
			if (line.length > 0) {
				zoom = to!int(line[0]);
				if (groupMode == GroupBy.ZOOM) {
					group = zoom;
				}
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
				} else if (line[0].equal("zoom")) {
					group = zoom;
					groupMode = GroupBy.ZOOM;
				} else {
					throw new Exception("Invalid value for command \"group\": "
										~ line[0]);
				}
			}
		}

		void setOffset(const string[] line) {
			if (line.length > 0) {
				offset = to!int(line[0]);
				index = 0;
			}
		}

		void parseHitObjects(const string line) {
			Tuple!(Bashable[], int, int[]) ret = readMapSection(line,
																bpm * zoom,
																scroll,
																index,
																offset,
																group,
																separatorTimes);
			drumArray ~= ret[0];
			index = ret[1];
			separatorTimes = ret[2];
		}

		alias delegateAA = immutable void delegate(const string[])[string];
		delegateAA handlers = ["!bpm": &setBPM,
							   "!zoom": &setZoom,
							   "!scroll": &setScroll,
							   "!group": &setGroup,
							   "!offset": &setOffset];
		foreach (const string line ; lines) {
			const char first = line.length > 0 ? line[0] : '#';
			switch (first) {
				case '!':
					const string[] split = line.split(" ");
					immutable void delegate(const string[])* fn = (split[0]
																   in handlers);
					if (fn) {
						const string[] args = (split.length > 1
											   ? split[1 .. $] : []);
						(*fn)(args);
					}
					break;

				case '#':
					break;

				default:
					parseHitObjects(line);
					break;
			}
		}
		return drumArray;
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
	static Tuple!(Bashable[], int, int[]) readMapSection(const string section,
														 const int bpm,
														 const double scroll,
														 int index,
														 const int offset,
														 const int group,
														 int[] separatorTimes) {
		Bashable[] drumArray;
		int drumRollLength = 0;
		DrumRoll makeDrumRoll() {
			int startTime = calculatePosition(index - drumRollLength,
											  offset,
											  bpm);
			int length = calculatePosition(index,
										   offset,
										   bpm) - startTime;
			return new DrumRoll(0, 0, startTime, scroll, length);
		}
		Bashable insertSeparators(Bashable root, int[] separatorTimes) {
			Bashable next = root;
			foreach (int t ; separatorTimes.reverse()) {
				next = new Separator(t, root.scroll, root);
			}
			return next;
		}
		foreach (const char type ; section) {
			int currentOffset = calculatePosition(index, offset, bpm);
			if (group > 0 && index % group == 0) {
				separatorTimes ~= currentOffset;
			}
			if (type == 'O' || type == 'o') {
				drumRollLength++;
			} else {
				if (drumRollLength > 0) {
					DrumRoll d = makeDrumRoll();
					drumArray ~= insertSeparators(d, separatorTimes);
					separatorTimes = [];
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
				    if (separatorTimes.length > 0) {
						drumArray ~= insertSeparators(next, separatorTimes);
						separatorTimes = [];
					} else {
						drumArray ~= next;
					}
				}
			}
			index++;
		}
		if (drumRollLength > 0) {
			drumArray ~= insertSeparators(makeDrumRoll(), separatorTimes);
			separatorTimes = [];
		}
		return tuple(drumArray, index, separatorTimes);
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
		if (path.length < 5 || equal(path[path.length - 3 .. path.length],
		                             ".osz")) {
			throw new Exception("Bad file extension");
		}
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
