import std.conv;
import std.stdio;
import drums;

class MapGen {

    /*
      BPM value
      Map structure (one line) (e.g DDK|D|D|KKD)
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

    static double calculatePosition(int i, int bpm) {
	return ((60 / (to!double(bpm))) * to!double(i)) * 1000.0;
    }
	    
}
