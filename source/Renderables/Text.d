import Renderable : Renderable;
import Textured : Textured;
import std.algorithm.comparison : equal;
import std.string : toStringz;
import derelict.sdl2.sdl : SDL_CreateTextureFromSurface,
						   SDL_RenderCopy,
						   SDL_DestroyTexture,
						   SDL_Renderer,
						   SDL_Surface,
						   SDL_FreeSurface;
import derelict.sdl2.ttf : TTF_Font,
 						   TTF_RenderUTF8_Solid,
						   TTF_RenderUTF8_Shaded,
						   TTF_RenderUTF8_Blended;

class Text : Textured {

	private string currentText;
	private TTF_Font* font;
	private bool pretty;

	this(SDL_Renderer* renderer,
		 string text,
		 TTF_Font* font,
		 bool pretty,
		 int x, int y,
		 ubyte r, ubyte g, ubyte b, ubyte a) {

		super(renderer, null, 0, 0, x, y, r, g, b, a);

		this.font = font;
		this.pretty = pretty;
		this.currentText = "";
		this.updateText(text);
	}

	// Update the text in the texture if the new text differs from current
	public void updateText(string text) {
		if (!text.equal(currentText)) {
			SDL_Surface* tempSurface;
			if (pretty) {
				tempSurface = TTF_RenderUTF8_Blended(font, toStringz(text), color);
			} else {
				tempSurface = TTF_RenderUTF8_Solid(font, toStringz(text), color);
			}
			SDL_DestroyTexture(texture);
			texture = SDL_CreateTextureFromSurface(renderer, tempSurface);
			SDL_FreeSurface(tempSurface);
		}
	}

	// Return the text value of this Text object
	public string getText() {
		return currentText;
	}

}
