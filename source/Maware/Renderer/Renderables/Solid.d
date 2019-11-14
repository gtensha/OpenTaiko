//  This file is part of the OpenTaiko project.
//  <https://github.com/gtensha/OpenTaiko>
//
/// A square with position, height and width plus colour. The most basic
/// renderable object, and should implement features that can be shared with
/// subclasses. This is the base for the Textured object.
///
/// Authors: gtensha (@skyhvelv.net)
/// Copyright: 2017-2018 gtensha
/// License: GNU GPLv3 (no later versions)
//
//  You should have received a copy of the GNU General Public License
//  along with OpenTaiko. If not, see <https://www.gnu.org/licenses/>.

module maware.renderable.solid;

import maware.renderable.renderable;
import maware.renderer;

import std.conv : to;

import derelict.sdl2.sdl : SDL_Rect,
						   SDL_Color,
						   SDL_Renderer,
						   SDL_SetRenderDrawColor,
						   SDL_RenderFillRect;

class Solid : Renderable {

	public SDL_Rect rect;
	public SDL_Color color;
	protected SDL_Renderer* renderer;

	this(int w, int h, int x, int y,
		 ubyte r, ubyte g, ubyte b, ubyte a) {

		rect.w = w;
		rect.h = h;
		rect.x = x;
		rect.y = y;

		color.r = r;
		color.g = g;
		color.b = b;
		color.a = a;

		renderer = Renderer.renderer;
	}
	
	this(int w, int h, int x, int y,
		 SDL_Color color) {
		
		this(w, h, x, y, color.r, color.g, color.b, color.a);
	}

	public void render() {
		SDL_SetRenderDrawColor(renderer,
							   color.r,
							   color.g,
							   color.b,
							   color.a);

		SDL_RenderFillRect(renderer, &rect);
	}

	public void renderOffset(int x, int y) {
		SDL_SetRenderDrawColor(renderer,
							   color.r,
							   color.g,
							   color.b,
							   color.a);

		SDL_Rect realRect = rect;
		SDL_Rect tempRect = {rect.x + x, rect.y + y, rect.w, rect.h};
		rect = tempRect;
		render();
		rect = realRect;
	}

	// Set the color of the solid, int < 0 for unchanged
	public void setColor(int r, int g, int b, int a) {
		if (r >= 0) {
			this.color.r = to!ubyte(r);
		}
		if (g >= 0) {
			this.color.g = to!ubyte(g);
		}
		if (b >= 0) {
			this.color.b = to!ubyte(b);
		}
		if (a >= 0) {
			this.color.a = to!ubyte(a);
		}
	}

	public static SDL_Rect getUnion(SDL_Rect* a, SDL_Rect* b) {
		SDL_Rect result = {0, 0, (a.x + a.w) - (b.x + b.w), (a.y + a.h) - (b.y + b.h)};
		return result;
	}

}
