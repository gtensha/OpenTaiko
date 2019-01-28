module opentaiko.song;

import opentaiko.difficulty;

struct Song {

    string title;
    string artist;
    string maintainer;
    string[] tags;

    string src;
	string directory;

    Difficulty[] difficulties;

}
