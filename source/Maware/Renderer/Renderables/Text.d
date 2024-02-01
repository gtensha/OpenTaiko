//  This file is part of the OpenTaiko project.
//  <https://github.com/gtensha/OpenTaiko>
//
/// Rendering and manipulating text with different fonts and sizes.
///
/// Authors: gtensha (@skyhvelv.net)
/// Copyright: 2017-2019 gtensha
/// License: GNU GPLv3 (no later versions)
//
//  You should have received a copy of the GNU General Public License
//  along with OpenTaiko. If not, see <https://www.gnu.org/licenses/>.

module maware.renderable.text;

import maware.renderable.renderable;
import maware.renderable.textured;

import std.algorithm.comparison : equal;
import std.string : toStringz;
import bindbc.sdl : SDL_CreateTextureFromSurface,
					SDL_RenderCopy,
					SDL_DestroyTexture,
					SDL_Renderer,
					SDL_Surface,
					SDL_FreeSurface,
					SDL_QueryTexture,
					SDL_Color;
import sdl_ttf : TTF_Font,
 				 TTF_RenderUTF8_Solid,
				 TTF_RenderUTF8_Shaded,
				 TTF_RenderUTF8_Blended;

class Text : Textured {

	protected string currentText;
	private TTF_Font* font;
	protected bool pretty;

	this(string text,
		 TTF_Font* font,
		 bool pretty,
		 int x, int y,
		 ubyte r, ubyte g, ubyte b, ubyte a) {

		super(null, 0, 0, x, y, r, g, b, a);

		this.font = font;
		this.pretty = pretty;
		this.updateText(text);
	}
	
	this(string text,
		 TTF_Font* font,
		 bool pretty,
		 int x, int y,
		 SDL_Color color) {
		
		this(text, font, pretty, x, y, color.r, color.g, color.b, color.a);
	}

	~this() {
		if (texture !is null) {
			SDL_DestroyTexture(texture);
		}
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
			SDL_DestroyTexture(this.texture);
			this.texture = SDL_CreateTextureFromSurface(renderer, tempSurface);
			int w, h;
			SDL_QueryTexture(this.texture, null, null, &w, &h);
			this.rect.w = w;
			this.rect.h = h;
			SDL_FreeSurface(tempSurface);
			currentText = text;
		}
	}

	public void updateText() {
		this.updateText(currentText);
	}

	// Return the text value of this Text object
	public string getText() {
		return currentText;
	}

	public TTF_Font* getFont() {
		return font;
	}

}
