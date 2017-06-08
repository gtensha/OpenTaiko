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
	string map = to!string(std.file.read(MAP_DIR ~ file ~ "/map.conf"));
	string[] lines = split(map, "\n");
	writeln(lines);
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

    static void convertMapFile(string source) {
	
	string file = to!string(std.file.read(source));
	string convertedMap = fromOSUFile(file);

	std.file.write(MAP_DIR ~ "imported/" ~ "map.conf", convertedMap);
	
    }
    
    static string fromOSUFile(string file) {

	string openTaikoMap;
	string[] lines = split(file, std.ascii.newline);

	bool objectSection = false;

	openTaikoMap ~= "# Map converted from .osu format\n\n";
	openTaikoMap ~= "!mapstart\n";
	
	foreach (string line ; lines) {

	    if (removechars(line, " ").equal("[HitObjects]")) {
		objectSection = true;
	    } else if (objectSection) {
		string[] properties = split(line, ',');
		if (properties.length >= 5) {
		    if (properties[3].equal("1")) {
			openTaikoMap ~= "!offset " ~ properties[2] ~ "\n";
			switch (properties[4]) {

			case "0":
			    openTaikoMap ~= "d\n";
			    break;

			case "2":
			    openTaikoMap ~= "k\n";
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
