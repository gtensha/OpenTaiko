module maware.renderer;

import maware.engine;
import maware.renderable.renderable;
import maware.renderable.scene;
import maware.renderable.solid;
import maware.renderable.textured;
import maware.renderable.text;
import maware.renderable.dialogbox;
import maware.font;
import maware.util.timer;

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

// A renderer class for creating and rendering on-screen objects and scenes
class Renderer {

	// The parent game engine of this renderer
	private Engine parent;

	// The current renderer and window for this Renderer object
	private SDL_Renderer* renderer;
	private SDL_Window* window;

	// Stores all the textures in the system for deployment
	private SDL_Texture*[string] textures;

	// Stores all the fonts in the system
	private Font[string] fonts;

	private Scene[] scenes; // the scenes present in the renderer
	private uint currentScene; // the index of the scene to be rendered at present

	private DialogBox messageBox;
	private Font defaultFont;


	// Create the object with the given parent and initiate video
	this(Engine parent) {

		if (parent is null) {
			throw new Exception("Error: Cannot have a renderer without an engine");
		} else {
			this.parent = parent;
		}

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

		if (IMG_Init(IMG_INIT_PNG | IMG_INIT_JPG) < 0) {
			throw new Exception(to!string("Failed to initialise SDL_image: "
										  ~ fromStringz(IMG_GetError())));
		}

		if (TTF_Init() < 0) {
			throw new Exception(to!string("Failed to initialise SDL_ttf: "
										  ~ fromStringz(TTF_GetError())));
		}


	}

	~this() {
		foreach (SDL_Texture* texture ; textures) {
			SDL_DestroyTexture(texture);
		}

		SDL_DestroyRenderer(renderer);
		SDL_DestroyWindow(window);
		TTF_Quit();
		IMG_Quit();
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
		SDL_RenderPresent(this.renderer);
		SDL_RaiseWindow(this.window);
		SDL_SetRenderDrawBlendMode(this.renderer, SDL_BLENDMODE_BLEND);

	}

	public void renderFrame() {
		SDL_SetRenderDrawColor(renderer, 20, 20, 20, 255);
		SDL_RenderClear(renderer);
		scenes[currentScene].render();
		SDL_RenderPresent(renderer);
	}

	public DialogBox notifyPopUp(string msg) {
		if (messageBox !is null) {
			messageBox.popUp(msg);
		}
		return messageBox;
	}

	public void setDefaultFont(string type) {
		defaultFont = getFont(type);
		messageBox = new DialogBox("Generic error",
								   "OK",
								   defaultFont,
								   null,
								   this);
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
		if (tempTexture is null) {
			throw new Exception(to!string(fromStringz(SDL_GetError())));
		}
		SDL_FreeSurface(surface);
		textures[key] = tempTexture;
	}

	public SDL_Texture* getTexture(string key) {
		SDL_Texture** someTexture = (key in textures);
		if (someTexture !is null) {
			return *someTexture;
		} else {
			return null;
		}
	}

	// Register a new Font object into the system
	public void registerFont(string key, string src) {
		fonts[key] = new Font(key, src);
	}

	// Returns Font object if exists, else returns null
	public Font getFont(string key) {
		if ((key in fonts) !is null) {
			return fonts[key];
		} else {
			return null;
		}
	}

	public uint addScene(string name) {
		scenes ~= new Scene(name);
		return to!uint(scenes.length - 1);
	}

	public uint addScene(Scene scene) {
		scenes ~= scene;
		return to!uint(scenes.length - 1);
	}

	// Sets the renderer's active scene, returns it or null upon failure
	public Scene setScene(uint index) {
		if (index > scenes.length - 1) {
			return null;
		} else {
			currentScene = index;
			return scenes[currentScene];
		}
	}

	// Returns the scene at the specified index
	public Scene getScene(uint index) {
		if (index > scenes.length - 1) {
			return null;
		} else {
			return scenes[index];
		}
	}

	// Gets the currently rendered scene
	public Scene getCurrentScene() {
		if (scenes.length > 0) {
			return scenes[currentScene];
		} else {
			return null;
		}
	}

	public uint getCurrentSceneIndex() {
		return currentScene;
	}

	// Return the amount of milliseconds since library init
	public static uint getTicks() {
		return SDL_GetTicks();
	}

	// Return the window's current width in pixels
	public int windowWidth() {
		int w;
		SDL_GetWindowSize(window, &w, null);
		return w;
	}

	// Return the window's current height in pixels
	public int windowHeight() {
		int h;
		SDL_GetWindowSize(window, null, &h);
		return h;
	}

	public SDL_Renderer* sdlRenderer() {
		return renderer;
	}

	public Solid createSolid(int w, int h, int x, int y,
							 ubyte r, ubyte g, ubyte b, ubyte a) {

		return new Solid(renderer, w, h, x, y, r, g, b, a);
	}

	public Textured createTextured(string texture,
								   int w, int h, int x, int y) {

		if ((texture in textures) is null) {
			return null;
		} else {
			return new Textured(renderer, textures[texture], w, h, x, y);
		}
	}

	public Textured createTextured(string texture,
								   int x, int y) {

		if ((texture in textures) is null) {
			return null;
		} else {
			return new Textured(renderer, textures[texture], x, y);
		}
	}

	public Text createText(string text,
						   string font,
						   uint size,
						   bool pretty,
						   int x, int y,
						   ubyte r, ubyte g, ubyte b, ubyte a) {

		TTF_Font* fontFace = getFont(font).get(size);
		if (fontFace is null) {
			parent.notify("There was an error opening the font "
						  ~ font
						  ~ " with size "
						  ~ to!string(size));

			return null;
		}

		Text newText = new Text(this.renderer,
								text,
								fontFace,
								pretty,
								x, y,
								r, g, b, a);
		return newText;
	}

}
