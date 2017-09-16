import Renderable : Renderable;
import std.conv : to;
import derelict.sdl2.sdl : SDL_Rect,
						   SDL_Color,
						   SDL_Renderer,
						   SDL_SetRenderDrawColor,
						   SDL_RenderFillRect;

class Solid : Renderable {

	protected SDL_Rect rect;
	protected SDL_Color color;
	protected SDL_Renderer* renderer;

	this(SDL_Renderer* renderer,
		 int w, int h, int x, int y,
		 ubyte r, ubyte g, ubyte b, ubyte a) {

		rect.w = w;
		rect.h = h;
		rect.x = x;
		rect.y = y;

		color.r = r;
		color.g = g;
		color.b = b;
		color.a = a;

		this.renderer = renderer;
	}

	public void render() {
		SDL_SetRenderDrawColor(renderer,
							   color.r,
							   color.g,
							   color.b,
							   color.a);

		SDL_RenderFillRect(renderer, &rect);
	}

	public int width() {
		return rect.w;
	}

	public int height() {
		return rect.h;
	}

	public void setX(uint x) {
		rect.x = x;
	}

	public void setY(uint y) {
		rect.y = y;
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

}