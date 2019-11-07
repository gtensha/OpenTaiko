module maware.font;

import derelict.sdl2.ttf : TTF_CloseFont, TTF_Font, TTF_GetError, TTF_OpenFont;
import std.string : fromStringz, toStringz;

class FontLoadException : Exception {
	this(string msg) {
		super(msg);
	}
}

/// A class representing a font face that can be retrieved as various sizes.
/// Holds the path to the font file and reads this every time a new size is
/// requested. If a size has already been loaded previously, the reference is
/// stored so retrieving only needs to happen once per size.
class Font {

	private string name;
	private string src;

	private TTF_Font*[int] sizes;

	/// Construct a new Font object with given name and file at src.
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

	/// Returns the font struct pointer if size exists, else makes new size and
	/// returns.
	public TTF_Font* get(int size) {
		if (size > 0) {
			TTF_Font** someSize = size in sizes;
			if (someSize is null) {
				TTF_Font* newSize = TTF_OpenFont(toStringz(src), size);
				if (!newSize) {
					const string err = cast(string)fromStringz(TTF_GetError());
					throw new FontLoadException(name ~ ": " ~ err);
				}
				sizes[size] = newSize;
				return newSize;
			} else {
				return *someSize;
			}
		} else {
			throw new FontLoadException("Invalid font size");
		}
	}

}
