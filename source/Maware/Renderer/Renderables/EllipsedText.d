module maware.renderable.ellipsedtext;

import maware.renderable.text;

import derelict.sdl2.sdl : SDL_Color;
import derelict.sdl2.ttf : TTF_Font;

/// A class similar to Text but with a width boundary
class EllipsedText : Text {
	
	int maxWidth;
	
	this(string text,
	     TTF_Font* font,
	     bool pretty,
	     int maxWidth,
	     int x, int y,
	     ubyte r, ubyte g, ubyte b, ubyte a) {

		super(text, font, pretty, x, y, r, g, b, a);
		this.maxWidth = maxWidth;
		updateText(text);
	}
	
	this(string text,
	     TTF_Font* font,
	     bool pretty,
	     int maxWidth,
	     int x, int y,
	     SDL_Color color) {

		this(text, font, pretty, maxWidth, x, y, color.r, color.g, color.b, color.a);
	}
	
	/// Make a new text until it is no wider than maxWidth
	override public void updateText(string text) {
		super.updateText(text);
		while (rect.w > maxWidth && text.length > 1) {
			super.updateText(text ~ "...");
			text = text[0 .. text.length - 2];
		}
	}
	
}
