import std.stdio;
import Renderer;
import AudioMixer;

class Engine {

	private string title;

	private Renderer renderer;
	private AudioMixer audioMixer;

	this(string title) {
		this.title = title;
	}

	// Starts the engine
	public void start(int w, int h, bool vsync, string title) {

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

	public void quit() {
		audioMixer.destroy();
		audioMixer = null;
		renderer.destroy();
		renderer = null;
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

	// This should be able to render a message on screen in the future as well
	// as writing to console
	private void notify(string msg) {
		writeln(msg);
	}

}
