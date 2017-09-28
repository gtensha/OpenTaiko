module maware.font;

import derelict.sdl2.ttf : TTF_Font, TTF_OpenFont, TTF_CloseFont;
import std.string : toStringz;

class Font {

	private string name;
	private string src;

	private TTF_Font*[512] sizes;

	this(string name, string src) {
		this.name = name;
		this.src = src;
	}

	~this() {
		foreach (TTF_Font* font ; sizes) {
			if (font !is null) {
				TTF_CloseFont(font);
			}
		}
	}

	// Returns the font struct if size exists, else makes new size and returns
	public TTF_Font* get(uint size) {
		if (size <= sizes.length) {
			if (sizes[size] is null) {
				sizes[size] = TTF_OpenFont(toStringz(src), size);
			}
			return sizes[size];
		} else {
			throw new Exception("Error: Font size out of bounds");
		}
	}

}
