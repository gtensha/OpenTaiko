import Solid : Solid;
import derelict.sdl2.sdl : SDL_Texture,
						   SDL_QueryTexture,
						   SDL_RenderCopy,
						   SDL_Renderer;

class Textured : Solid {

	protected SDL_Texture* texture;

	this(SDL_Renderer* renderer,
		 SDL_Texture* texture,
		 int w, int h, int x, int y,
		 ubyte r, ubyte g, ubyte b, ubyte a) {

		super(renderer, w, h, x, y, r, g, b, a);
		this.texture = texture;
	}

	this(SDL_Renderer* renderer,
		 SDL_Texture* texture,
		 int w, int h, int x, int y) {

		super(renderer, w, h, x, y, 0, 0, 0, 255);
		this.texture = texture;
	}

	this(SDL_Renderer* renderer,
		 SDL_Texture* texture,
		 int x, int y) {

		int w, h;
		SDL_QueryTexture(texture, null, null, &w, &h);
		super(renderer, w, h, x, y, 0, 0, 0, 255);
		this.texture = texture;
	}

	override public void render() {
		SDL_RenderCopy(renderer, texture, null, &rect);
	}

}
