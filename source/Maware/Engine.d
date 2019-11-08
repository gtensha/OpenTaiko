module maware.engine;

import std.stdio;

import maware.renderer;
import maware.audio.mixer;
import maware.audio.sdlmixer;
import maware.audio.sfmlmixer;
import maware.inputhandler;
import maware.util.timer;
import maware.assets;
import std.conv : to;

/// A class for handling rendering and audio playback
class Engine {

	private string title;
	public static immutable string engineName = "Maware! Game Engine";

	private Renderer renderer; // the engine's renderer
	private AudioMixer audioMixer; // the engine's audio backend
	private InputHandler inputHandler;
	private Timer timer;

	private uint notifyBinderIndex;

	/// Load libraries needed for Renderer and AudioMixer
	static void initialise() {
		Renderer.initialise();
		version (SDLMixer) {
			SDLMixer.initialise();
		}
		version (SFMLMixer) {
			SFMLMixer.initialise();
		}
	}

	/// Deinitialise libraries needed by Renderer and AudioMixer
	static void deInitialise() {
		Renderer.deInitialise();
		version (SDLMixer) {
			SDLMixer.deInitialise();
		}
	}

	this(string title) {
		this.title = title;
	}

	~this() {
		renderer.destroy();
		audioMixer.destroy();
		inputHandler.destroy();
	}

	// Starts the engine
	public void start(int w, int h, bool vsync, string title) {

		timer = Timer.timers[Timer.addTimer()];

		try {
			renderer = new Renderer(this);
			version (SDLMixer) {
				audioMixer = new SDLMixer(this);
			}
			version (SFMLMixer) {
				audioMixer = new SFMLMixer(this, 256);
			}
			inputHandler = new InputHandler(this);
		} catch (Exception e) {
			notify("Error loading sub modules: " ~ e.msg);
			return;
		}

		try {
			renderer.createNewWindow(w, h, vsync, title);
		} catch (Exception e) {
			notify("Error creating window: " ~ e.msg);
		}

		notifyBinderIndex = inputHandler.addActionBinder();

	}

	// Stops the engine, deallocates resources
	public void stop() {
		audioMixer.destroy();
		audioMixer = null;
		renderer.destroy();
		renderer = null;
	}

	public int renderFrame() {
		Timer.refresh(renderer.getTicks());
		renderer.renderFrame();
		return inputHandler.listenHandleEvents();
	}

	/// Registers all texture, font and sound assets in assets, and navigates to
	/// the directory extraPath to look for the filenames. Only call this if
	/// you do not have full paths prepended in your Assets collection's values.
	public void loadAssets(Assets assets, string extraPath) {
		loadAssets(Assets.findAssets(assets, extraPath));
	}

	/// Registers all texture, font and sound assets in assets. Will register
	/// by the raw file paths contained in the values.
	public void loadAssets(Assets assets) {
		foreach (string key ; assets.textures.keys) {
			gameRenderer.registerTexture(key, assets.textures[key]);
		}
		foreach (string key ; assets.fonts.byKey()) {
			gameRenderer.registerFont(key, assets.fonts[key]);
		}
		foreach (size_t i, string path ; assets.sounds) {
			if (path !is null) {
				audioMixer.registerSFX(cast(int)i, path);
			}
		}
	}

	// Returns the engine's renderer
	public Renderer gameRenderer() {
		return renderer;
	}

	public InputHandler iHandler() {
		return inputHandler;
	}

	public AudioMixer aMixer() {
		return audioMixer;
	}

	// Sets the renderer's active scene and returns it
	public void switchScene(uint index) {
		renderer.setScene(index);
	}

	/// Write msg to stdout and give user a popup if possible
	public static void notify(string msg) {
		writeln(msg);
		Renderer.notifyPopUp(msg);
	}

	public static void notify(int msg) {
		notify(to!string(msg));
	}

	public string getTitle() {
		return title;
	}

}
