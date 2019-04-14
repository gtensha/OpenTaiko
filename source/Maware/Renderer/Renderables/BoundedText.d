module maware.renderable.boundedtext;

import maware.renderable.text;

import derelict.sdl2.sdl : SDL_Color;
import derelict.sdl2.ttf : TTF_Font;

/// Abstract class from which text that has a set bound can be derived
/// universally
abstract class BoundedText : Text {

	private int maximumWidth;

	this(string text,
		 TTF_Font* font,
		 bool pretty,
		 int maxWidth,
		 int x, int y,
		 ubyte r, ubyte g, ubyte b, ubyte a) {

		super(text, font, pretty, x, y, r, g, b, a);
		this.maximumWidth = maxWidth;
		updateWidth();
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

	/// To be called on width update
	abstract protected void updateWidth();

	override void updateText(string text) {
		super.updateText(text);
		updateWidth();
	}

	override void updateText() {
		this.updateText(currentText);
	}

	@property void maxWidth(int value) {
		maxWidth = value;
		updateWidth();
	}

	@property int maxWidth() {
		return maximumWidth;
	}

}
