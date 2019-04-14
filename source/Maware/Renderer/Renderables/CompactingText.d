module maware.renderable.compactingtext;

import maware.renderable.text;

import derelict.sdl2.sdl : SDL_QueryTexture, SDL_Color;
import derelict.sdl2.ttf : TTF_Font;

/// Simple variant of Text that accepts an extra parameter; max length. If the
/// length of the text exceeds the max length, then it will be rendered
/// "compacted." It is ugly, but makes things possible to read at smaller
/// resolutions and therefore shouldn't be used for text that normally exceeds
/// its supposed bounds.
class CompactingText : Text {

	int maxWidth;

	this(string text,
		 TTF_Font* font,
		 bool pretty,
		 int maxWidth,
		 int x, int y,
		 ubyte r, ubyte g, ubyte b, ubyte a) {

		super(text, font, pretty, x, y, r, g, b, a);
		this.maxWidth = maxWidth;
		compact();
	}

	this(string text,
		 TTF_Font* font,
		 bool pretty,
		 int maxWidth,
		 int x, int y,
		 SDL_Color color) {

		const SDL_Color c = color;
		this(text, font, pretty, maxWidth, x, y, c.r, c.g, c.b, c.a);
	}

	/// Checks the length of the text texture, and sets the rect width to
	/// maxWidth if it is longer than maxWidth, else sets it to normal width.
	private void compact() {
		int w;
		SDL_QueryTexture(texture, null, null, &w, null);
		if (w > maxWidth) {
			rect.w = maxWidth;
		} else {
			rect.w = w;
		}
	}

	override void updateText(string text) {
		super.updateText(text);
		compact();
	}

	override void updateText() {
		this.updateText(currentText);
	}

	// TODO: renderPart()
	
}
