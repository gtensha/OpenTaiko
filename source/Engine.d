import std.stdio;

import Renderer : Renderer;
import AudioMixer : AudioMixer;
import Timer : Timer;

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
	}

	// Load a bunch of textures into the renderer from an AA
	public void loadTextures(string[string] src) {
		foreach (string str ; src.keys) {
			try {
				renderer.registerTexture(str, src[str]);
			} catch (Exception e) {
				notify("Failed to load texture: " ~ e.msg);
			}
		}
	}

	// Load a single texture from file into the renderer
	public void loadTexture(string key, string src) {
		try {
			renderer.registerTexture(key, src);
		} catch (Exception e) {
			notify("Failed to load texture: " ~ e.msg);
		}
	}

	// This should be able to render a message on screen in the future as well
	// as writing to console
	public void notify(string msg) {
		writeln(msg);
	}

}
