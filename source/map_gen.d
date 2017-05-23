import std.conv;
import std.stdio;
import std.file;
import std.algorithm.searching;
import std.algorithm.comparison;
import std.array;
import std.string;
import std.ascii;
import drums;

enum {
    string MAP_DIR = "maps/",
};

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
	int zoom = 1;
	string map = to!string(std.file.read(MAP_DIR ~ file ~ "/map.conf"));
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
	    
}
