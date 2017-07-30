import std.stdio;

import Renderer : Renderer;
import AudioMixer : AudioMixer;
import Timer : Timer;
import Assets : Assets;

// A class for handling rendering and audio playback
class Engine {

	private string title;

	private Renderer renderer; // the engine's renderer
	private AudioMixer audioMixer; // the engine's audio backend
	private Timer timer;

	this(string title) {
		this.title = title;
	}

	// Starts the engine
	public void start(int w, int h, bool vsync, string title) {

		timer = Timer.timers[Timer.addTimer()];

		try {
			renderer = new Renderer(this);
			audioMixer = new AudioMixer(this);
		} catch (Exception e) {
			notify("Error loading sub modules: " ~ e.msg);
			return;
		}

		try {
			renderer.createNewWindow(w, h, vsync, title);
		} catch (Exception e) {
			notify("Error creating window: " ~ e.msg);
		}

	}

	// Stops the engine, deallocates resources
	public void stop() {
		audioMixer.destroy();
		audioMixer = null;
		renderer.destroy();
		renderer = null;
	}

	public void renderFrame() {
		timer.refresh(renderer.getTicks());
		renderer.renderFrame();
	}

	public void loadAssets(Assets assets, string extraPath) {
		foreach (string key ; assets.textures.byKey()) {
			if ((key in assets.textures) !is null) {
				gameRenderer.registerTexture(key, extraPath ~ assets.textures[key]);
			}
		}

		foreach (string key ; assets.fonts.byKey()) {
			if ((key in assets.fonts) !is null) {
				gameRenderer.registerFont(key, extraPath ~ assets.fonts[key]);
			}
		}

		int i = 0;
		foreach (string path ; assets.sounds) {
			if (path !is null) {
				audioMixer.registerSFX(i, extraPath ~ path);
			}
			i++;
		}
	}

	// Returns the engine's renderer
	public Renderer gameRenderer() {
		return renderer;
	}

	// Sets the renderer's active scene and returns it
	public void switchScene(uint index) {
		renderer.setScene(index);
	}

	// This should be able to render a message on screen in the future as well
	// as writing to console
	public void notify(string msg) {
		writeln(msg);
	}

}
