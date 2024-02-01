//  This file is part of the OpenTaiko project.
//  <https://github.com/gtensha/OpenTaiko>
//
/// Display management and handling resources related to 2D rendering.
/// Storing textures, fonts and managing different scenes. Based on SDL2.
///
/// Authors: gtensha (@skyhvelv.net)
/// Copyright: 2017-2019 gtensha
/// License: GNU GPLv3 (no later versions)
//
//  You should have received a copy of the GNU General Public License
//  along with OpenTaiko. If not, see <https://www.gnu.org/licenses/>.

module maware.renderer;

import maware.engine;
import maware.renderable.renderable;
import maware.renderable.scene;
import maware.renderable.solid;
import maware.renderable.textured;
import maware.renderable.text;
import maware.font;
import maware.util.timer;

import std.file;
import std.string : fromStringz, toStringz;
import std.conv : to;

//import loader = bindbc.loader.sharedlib;
import bindbc.sdl;
import sdl_ttf;
import sdl_image;
import bindbc.loader.sharedlib;

/// A renderer class for creating and rendering on-screen objects and scenes
/// Must be initialised before it can be used; see initialise() methods
class Renderer {
	
	private static bool sdlIsInit;

	// The parent game engine of this renderer
	private Engine parent;

	// The current renderer and window for this Renderer object
	public static SDL_Renderer* renderer;
	private SDL_Window* window;

	// Stores all the textures in the system for deployment
	private SDL_Texture*[string] textures;

	// Stores all the fonts in the system
	private Font[string] fonts;

	private Scene[] scenes; // the scenes present in the renderer
	private uint currentScene; // the index of the scene to be rendered at present

	/// Attempt loading the SDL2 libraries. Needed to successfully construct
	/// an object of this class. Throws exceptions on load failure.
	static void initialise(int videoFlags, int imgFlags) {
		SDLSupport ret = loadSDL();
		if (ret != sdlSupport) {		
			string msg;
			if (ret == SDLSupport.noLibrary) {
				msg = "This application requires the SDL library.";
			} else {
				msg = "Bad SDL version.";
			}
			throw new Exception(msg);
		}
		SDLImageSupport imgRet = loadSDLImage();
		if (imgRet != sdlImageSupport) {		
			string msg;
			if (imgRet == SDLImageSupport.noLibrary) {
				msg = "This application requires the SDL_Image library.";
			} else {
				msg = "Bad SDL version.";
			}
			throw new Exception(msg);
		}
		SDLTTFSupport ttfRet = loadSDLTTF();
		if (ttfRet != sdlTTFSupport) {		
			string msg;
			if (ttfRet == SDLTTFSupport.noLibrary) {
				msg = "This application requires the SDL_TTF library.";
			} else {
				msg = "Bad SDL version.";
			}
			throw new Exception(msg);
		}
		SDL_Init(videoFlags);
		IMG_Init(imgFlags);
		TTF_Init();
		sdlIsInit = true;
	}

	/// Call initialise() with default video subsystem flags
	static void initialise() {
		initialise(SDL_INIT_VIDEO,
				   IMG_INIT_PNG | IMG_INIT_JPG);
	}

	/// Reverses the library initialisations made by initialise().
	/// Must NOT be called before ALL resources made with the respective
	/// libraries have been freed.
	static void deInitialise() {
		TTF_Quit();
		IMG_Quit();
		SDL_Quit();
	}


	/// Create the object with the given parent
	this(Engine parent) {

		if (!sdlIsInit) {
			throw new Exception("SDL was not initialised");
		}

		if (parent is null) {
			throw new Exception("Error: Cannot have a renderer without an engine");
		} else {
			this.parent = parent;
		}

	}

	~this() {
		foreach (SDL_Texture* texture ; textures) {
			SDL_DestroyTexture(texture);
		}

		foreach (Font font ; fonts) {
			font.destroy();
		}

		SDL_DestroyRenderer(renderer);
		SDL_DestroyWindow(window);
	}

	/// Create a new window with given properties
	public void createNewWindow(int x, int y, bool vsync, string title) {

		if (title is null) {
			title = "Maware! Game Engine";
		}

		this.window = SDL_CreateWindow(toStringz(title),
									   SDL_WINDOWPOS_UNDEFINED,
									   SDL_WINDOWPOS_UNDEFINED,
									   x,
									   y,
									   cast(SDL_WindowFlags)0);

		if (this.window is null) {
			throw new Exception(to!string("Failed to create window: "
								~ fromStringz(SDL_GetError())));
		}

		if (vsync) {
			renderer = SDL_CreateRenderer(this.window,
										  -1,
										  SDL_RENDERER_ACCELERATED
										  |
										  SDL_RENDERER_PRESENTVSYNC);
		} else {
			renderer = SDL_CreateRenderer(this.window,
										  -1,
										  SDL_RENDERER_ACCELERATED);
		}

		if (renderer is null) {
			throw new Exception(to!string("Failed to create renderer: "
								~ fromStringz(SDL_GetError())));
		}

		SDL_SetRenderDrawColor(renderer, 20, 20, 20, 255);
		SDL_RenderClear(renderer);
		SDL_RenderPresent(renderer);
		SDL_RaiseWindow(window);
		SDL_SetRenderDrawBlendMode(renderer, SDL_BLENDMODE_BLEND);

	}

	/// Render a frame for the current scene
	public void renderFrame() {
		Scene s = scenes[currentScene];
		const SDL_Color c = s.backgroundColor;
		SDL_SetRenderDrawColor(renderer, c.r, c.g, c.b, c.a);
		SDL_RenderClear(renderer);
		s.render();
		SDL_RenderPresent(renderer);
	}

	/// Show an OS specific popup box on screen
	public static void notifyPopUp(string msg) {
		if (sdlIsInit) {
			SDL_ShowSimpleMessageBox(SDL_MESSAGEBOX_WARNING,
									 toStringz(Engine.engineName),
									 toStringz(msg),
									 null);
		}
	}

	/// Register a new texture into the renderer with the given key from
	/// a path to a supported image file
	public void registerTexture(string key, string src) {
		SDL_Surface* tempSurface = IMG_Load(toStringz(src));
		if (tempSurface is null) {
			throw new Exception(cast(string)(src
											 ~ ": "
											 ~ fromStringz(SDL_GetError())));
		}
		registerTexture(key, tempSurface);
		SDL_FreeSurface(tempSurface);
	}

	/// Register a new texture into the system with the given key
	/// from a pre created surface
	public void registerTexture(string key, SDL_Surface* surface) {
		SDL_Texture* tempTexture = SDL_CreateTextureFromSurface(this.renderer,
																surface);
		if (tempTexture is null) {
			throw new Exception(cast(string)(key
											 ~ ": "
											 ~ fromStringz(SDL_GetError())));
		}
		SDL_Texture** possibleTexture = key in textures;
		if (possibleTexture !is null) {
			SDL_DestroyTexture(*possibleTexture);
		}
		textures[key] = tempTexture;
	}

	/// Gets the SDL_Texture* assigned to this key, if it exists
	public SDL_Texture* getTexture(string key) {
		SDL_Texture** someTexture = (key in textures);
		if (someTexture !is null) {
			return *someTexture;
		} else {
			return null;
		}
	}

	/// Colors an already registered texture with the given rgb values
	public void colorTexture(string key, ubyte r, ubyte g, ubyte b) {
		SDL_Texture* texture = getTexture(key);
		if (texture is null) {
			throw new Exception("Error coloring texture: No texture with this key exists");
		}
		if (SDL_SetTextureColorMod(texture, r, g, b) < 0) {
			parent.notify(to!string("Failed to color texture: " ~ fromStringz(SDL_GetError())));
		}
	}

	/// Register a new Font object from src path on disk disk into the renderer
	public void registerFont(string key, string src) {
		fonts[key] = new Font(key, src);
	}

	/// Returns Font object if exists, else returns null
	public Font getFont(string key) {
		if ((key in fonts) !is null) {
			return fonts[key];
		} else {
			return null;
		}
	}

	/// Create a scene with the given name and layer count for the renderer
	public uint addScene(string name, int layerCount) {
		scenes ~= new Scene(name, layerCount);
		return cast(uint)scenes.length - 1;
	}

	/// Add the given Scene to the renderer
	public uint addScene(Scene scene) {
		scenes ~= scene;
		return cast(uint)scenes.length - 1;
	}

	/// Sets the renderer's active scene and returns it
	public Scene setScene(int index) {
		currentScene = index;
		return scenes[currentScene];
	}

	/// Returns the scene at the specified index
	public Scene getScene(int index) {
		return scenes[index];
	}

	/// Gets the currently rendered scene or null if there are none
	public Scene getCurrentScene() {
		if (scenes.length > 0) {
			return scenes[currentScene];
		} else {
			return null;
		}
	}

	/// Returns the index of the currently rendered scene
	public int getCurrentSceneIndex() {
		return currentScene;
	}

	/// Return the amount of milliseconds since library init
	public static uint getTicks() {
		return SDL_GetTicks();
	}

	/// Return the window's current width in pixels
	public int windowWidth() {
		int w;
		SDL_GetWindowSize(window, &w, null);
		return w;
	}

	/// Return the window's current height in pixels
	public int windowHeight() {
		int h;
		SDL_GetWindowSize(window, null, &h);
		return h;
	}

}
