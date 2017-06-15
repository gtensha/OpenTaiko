import std.conv;
import std.stdio;
import std.file;
import std.algorithm.searching;
import std.algorithm.comparison;
import std.array;
import std.string;
import std.ascii;
import std.json;
import drums;

enum {
    string MAP_DIR = "maps/",
    int WIDTH = 0,
    int HEIGHT = 1,
    int RED1 = 0,
    int RED2 = 1,
    int BLUE1 = 2,
    int BLUE2 = 3,
};

struct GameVars {

    // Keyboard mapping
    int[4] p1;
    int[4] p2;

    // Display options
    int[2] resolution;
    // int maxFPS
    bool vsync;

}

struct Song {

    string title;
    string artist;
    string maintainer;
    string[] tags;

    string src;

    Difficulty[] difficulties;

}

struct Difficulty {

    string name;
    int difficulty;
    string mapper;

}

class MapGen {

    /*
      Map structure (one line): e.g "ddk|d|d|kkd"
      or with spaces and small letters: "ddkd  d d kkdk"
      any character that isn't designated acts as empty space
      see default map.conf file for template and attribute
      specification
     */

    // Returns array of drum objects with desired properties
    static Drum[] parseMapFromFile(string file) {
	int bpm = 140;
	int zoom = 4;
	string map = to!string(std.file.read(MAP_DIR ~ file));
	string[] lines = split(map, std.ascii.newline);
	Drum[] drumArray;

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
		    drumArray ~= readMapSection(line, bpm, &i, offset);
		}
	    }
	}
	return drumArray;
    }

    // Calculate circle's position in milliseconds
    static double calculatePosition(int i, int offset, int bpm) {
	return (((60 / (to!double(bpm))) * to!double(i)) * 1000.0) + offset;
    }

    static Drum[] readMapSection(string section, int bpm, int* i, int offset) {
	int index = *i;
	Drum[] drumArray;
        foreach (char type ; section) {
	    if (type == 'D' || type == 'd') {
		drumArray ~= new Red(calculatePosition(index, offset, bpm));
	    } else if (type == 'K' || type == 'k') {
		drumArray ~= new Blue(calculatePosition(index, offset, bpm));
	    }
	    index++;
	}
	*i = index;
	return drumArray;
    }

    static string songToJSON(Song song) {
	JSONValue metaFile = JSONValue(["title": song.title,
					"artist": song.artist,
					"maintainer": song.maintainer,
					"src": song.src]);

	metaFile.object["tags"] = JSONValue(song.tags);
	//metaFile.object["tags"] = JSONValue(["converted", "osu"]);
	metaFile.object["difficulties"] = JSONValue([["name": song.difficulties[0].name,
						      "mapper": song.difficulties[0].mapper]]);

	metaFile["difficulties"].array[0].object["difficulty"] = song.difficulties[0].difficulty;

	return toJSON(metaFile, true);
    }

    static void convertMapFile(string source) {

	string file = to!string(std.file.read(source));
	string[] paths = split(source, "/");
	string path;
	for (int i = 0; i > paths.length - 1; i++) {
	    path ~= paths[i] ~ "/";
	}

	Song newSong;
	string convertedMap = fromOSUFile(file, &newSong);
	string metaFile;
	try {
	    isFile(MAP_DIR ~ newSong.title ~ "/meta.json");
	    JSONValue meta = parseJSON(to!string(std.file.read(MAP_DIR
							       ~ newSong.title
							       ~ "/meta.json")));

	    JSONValue newDiff = JSONValue(["name": newSong.difficulties[0].name,
					   "mapper": newSong.difficulties[0].mapper]);

	    newDiff.object["difficulty"] = JSONValue(newSong.difficulties[0].difficulty);
	    meta["difficulties"].array ~= newDiff;
	    metaFile = toJSON(meta, true);
	} catch (Exception e) {
	    metaFile = songToJSON(newSong);
	}



	try {
	    isDir(MAP_DIR ~ newSong.title);
	} catch (Exception e) {
	    mkdir(MAP_DIR ~ newSong.title);
	}

	JSONValue mapTree = parseJSON(to!string(std.file.read(MAP_DIR ~ "maps.json")));
	bool hasIt = false;
	foreach (JSONValue title ; mapTree["dirs"].array) {
	    if (title.str.equal(newSong.title)) {
		hasIt = true;
	    }
	}
	if (!hasIt) {
	    mapTree["dirs"].array ~= JSONValue(newSong.title);
	    std.file.write(MAP_DIR ~ "maps.json", toJSON(mapTree, true));
	}

	std.file.write(MAP_DIR ~ newSong.title ~ "/" ~ newSong.difficulties[0].name ~ ".otfm", convertedMap);
	std.file.write(MAP_DIR ~ newSong.title ~ "/meta.json", metaFile);

    }

    static string fromOSUFile(string file, Song* newSong) {

	string openTaikoMap;
	string[] lines = split(file, std.ascii.newline);

	Song song = *newSong;

	bool objectSection = false;
	bool generalSection = false;
	bool metaSection = false;

	openTaikoMap ~= "# Map converted from .osu format" ~ std.ascii.newline ~ std.ascii.newline;
	openTaikoMap ~= "!mapstart" ~ std.ascii.newline;

	foreach (string line ; lines) {

	    if (removechars(line, " ").equal("[HitObjects]")) {
		objectSection = true;
		generalSection = false;
		metaSection = false;
	    } else if (removechars(line, " ").equal("[General]")) {
		generalSection = true;
		objectSection = false;
		metaSection = false;
	    } else if (removechars(line, " ").equal("[Metadata]")) {
		metaSection = true;
		objectSection = false;
		generalSection = false;

	    } else if (generalSection) {
		string[] unformatted = line.split();
		if (unformatted !is null && unformatted.length > 0) {
		    string formatted;
		    if (unformatted[0].equal("AudioFilename:")) {
			/*for (int i = 0; i > unformatted.length; i++) {
			    if (i == 0) {
			    } else if (i == unformatted.length - 1) {
				formatted ~= unformatted[i];
			    } else {
				formatted ~= unformatted[i] ~ " ";
			    }
			    }*/

			song.src = unformatted[1];
		    }
		}

	    } else if (metaSection) {
		string[] unformatted = split(line, ":");
		if (unformatted !is null && unformatted.length > 0) {
		    switch (unformatted[0]) {
		    case "Title":
			song.title = unformatted[1];
			break;

		    case "Artist":
			song.artist = unformatted[1];
			break;

		    case "Creator":
			song.maintainer = unformatted[1];
			break;

		    case "Version":
			Difficulty diff = {unformatted[1], 0, null};
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
			openTaikoMap ~= "!offset " ~ properties[2] ~ std.ascii.newline;
			switch (properties[4]) {

			case "0":
			    openTaikoMap ~= "d" ~ std.ascii.newline;
			    break;

			case "2":
			    openTaikoMap ~= "k" ~ std.ascii.newline;
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

	song.difficulties[0].mapper = song.maintainer;
	*newSong = song;
	return openTaikoMap;

    }

    abstract string fromTJAFile(string file);

    static Song[] readSongDatabase(string file) {
	Song[] songs;
	string unprocessed = to!string(std.file.read(file));
	JSONValue maps = parseJSON(unprocessed);

	foreach (JSONValue dir ; maps["dirs"].array) {

	    JSONValue map = parseJSON(to!string(std.file.read(MAP_DIR
							      ~ dir.str
							      ~ "/meta.json")));

	    Song song = {
		map["title"].str,
		map["artist"].str,
		map["maintainer"].str,
		null,
		map["src"].str,
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
	}
	return songs;
    }

    static GameVars readConfFile(string fileLoc) {

	GameVars gameVars;
	string input = to!string(std.file.read(fileLoc));

	JSONValue vars = parseJSON(input);

	if (!(vars["p1"].array.length == 4
	      &&
	      vars["p2"].array.length == 4
	      &&
	      vars["resolution"].array.length == 2
	      &&
	      (vars["vsync"].type == JSON_TYPE.TRUE || vars["vsync"].type == JSON_TYPE.FALSE))) {

	    throw new Exception("Incorrect parameters in config file");
	}

	int i;
	foreach (JSONValue key ; vars["p1"].array) {
	    gameVars.p1[i] = to!int(key.integer);
	    i++;
	} i = 0;

	foreach (JSONValue key ; vars["p2"].array) {
	    gameVars.p2[i] = to!int(key.integer);
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
}
