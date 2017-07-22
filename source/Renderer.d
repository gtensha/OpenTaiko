import Engine;
import Renderable;

import std.file;
import std.string : fromStringz, toStringz;
import std.conv : to;

import derelict.sdl2.sdl;
import derelict.sdl2.image;
import derelict.sdl2.ttf;
import derelict.util.exception : ShouldThrow;

ShouldThrow myMissingSymCB(string symbolName) {
    return ShouldThrow.No;
}

class Renderer {

	// The parent game engine of this renderer
	private Engine parent;

	// The current renderer and window for this Renderer object
	private SDL_Renderer* renderer;
	private SDL_Window* window;

	// Stores all the textures in the system for deployment
	private SDL_Texture*[string] textures;

	// The renderables for the renderer to render each render() call.
	// Uses a layered principle, objects in the lower layers will render first
	// and at the bottom of the screen
	private Renderable[][] renderables;

	// Create the object with the given parent and initiate video
	this(Engine parent) {

		this.parent = parent;

		DerelictSDL2.missingSymbolCallback = &myMissingSymCB;

		try {
			DerelictSDL2.load();
			DerelictSDL2Image.load();
			DerelictSDL2ttf.load();
		} catch (Exception e) {
			throw e;
		}

		if (SDL_Init(SDL_INIT_VIDEO) < 0) {
			throw new Exception(to!string("Failed to initialise SDL: "
								~ fromStringz(SDL_GetError())));
		}

	}

	~this() {
		foreach (SDL_Texture* texture ; textures) {
			SDL_DestroyTexture(texture);
		}
		SDL_DestroyRenderer(renderer);
		SDL_DestroyWindow(window);
		SDL_Quit();
	}

	// Create a new window with given properties, used for startup or changing
	// settings
	public void createNewWindow(int x, int y, bool vsync, string title) {

		if (title is null) {
			title = "Maware! Game Engine";
		}

		this.window = SDL_CreateWindow(toStringz(title),
									   SDL_WINDOWPOS_UNDEFINED,
									   SDL_WINDOWPOS_UNDEFINED,
									   x,
									   y,
									   0);

		if (this.window is null) {
			throw new Exception(to!string("Failed to create window: "
								~ fromStringz(SDL_GetError())));
		}

		if (vsync) {
			this.renderer = SDL_CreateRenderer(this.window,
											   -1,
											   SDL_RENDERER_ACCELERATED
											   |
											   SDL_RENDERER_PRESENTVSYNC);
		} else {
			this.renderer = SDL_CreateRenderer(this.window,
											   -1,
											   SDL_RENDERER_ACCELERATED);
		}

		if (this.renderer is null) {
			throw new Exception(to!string("Failed to create renderer: "
								~ fromStringz(SDL_GetError())));
		}

		SDL_SetRenderDrawColor(this.renderer, 20, 20, 20, 255);
		SDL_RenderClear(this.renderer);
		SDL_RaiseWindow(this.window);
		SDL_Delay(3000);
	}

	public void renderFrame() {
		SDL_SetRenderDrawColor(renderer, 20, 20, 20, 255);
		SDL_RenderClear(renderer);
		foreach (Renderable[] renderableObjects ; this.renderables) {
			foreach (Renderable renderable ; renderableObjects) {
				renderable.render();
			}
		}
		SDL_RenderPresent(renderer);
	}

	// Register a new texture into the system with the given key from
	// a path to a supported image file
	public void registerTexture(string key, string src) {
		SDL_Surface* tempSurface = IMG_Load(toStringz(src));
		if (tempSurface is null) {
			throw new Exception(to!string(fromStringz(SDL_GetError())));
		}
		registerTexture(key, tempSurface);
	}

	// Register a new texture into the system with the given key
	// from an already created surface
	public void registerTexture(string key, SDL_Surface* surface) {
		SDL_Texture* tempTexture = SDL_CreateTextureFromSurface(this.renderer,
																surface);
		SDL_FreeSurface(surface);
	}

}
