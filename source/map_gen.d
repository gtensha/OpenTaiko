import std.conv;
import std.stdio;
import drums;

class MapGen {

    /*
      Map structure (one line): e.g "ddk|d|d|kkd"
      or with spaces and small letters: "ddkd  d d kkdk"
      any character that isn't designated acts as empty space
     */

    // Returns array of drum objects with desired properties
    static Drum[] parseMapFromFile(string file, int bpm) {
	int i = 0;
	Drum[] drumArray;
        foreach (char type ; file) {
	    if (type == 'D' || type == 'd') {
		drumArray ~= new Red(calculatePosition(i, bpm));
	    } else if (type == 'K' || type == 'k') {
		drumArray ~= new Blue(calculatePosition(i, bpm));
	    }
	    i++;
	}
	return drumArray;
    }

    // Calculate circle's position in milliseconds
    static double calculatePosition(int i, int bpm) {
	return ((60 / (to!double(bpm))) * to!double(i)) * 1000.0;
    }
	    
}
