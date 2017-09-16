import derelict.sdl2.sdl;/* : SDL_PollEvent,
						   SDL_Event,
						   SDL_Keycode,
						   SDL_KeyboardEvent,
						   SDL_EventType;*/
import Engine : Engine;

class InputHandler {

	private Engine parent;
	private int[] bindings;

	this(int eventAmount, Engine parent) {
		this.bindings = new int[eventAmount];
		this.parent = parent;
	}

	public int listenKeyboard() {
		SDL_Event event;
		while (SDL_PollEvent(&event) == 1) {
			if (event.type == SDL_KEYDOWN) {
				foreach (int i, int binding ; bindings) {
					if (binding == event.key.keysym.sym) {
						return i;
					}
				}
			} else if (event.type == SDL_QUIT) {
				return -1;
			}
		}
		return -2;
	}

	public void bind(int event, int key) {
		if (event < bindings.length && event >= 0) {
			bindings[event] = key;
		}
	}

	public void bind(int[] keys) {
		if (keys.length <= bindings.length) {
			foreach (int event, int key ; keys) {
				bindings[event] = key;
			}
		}
	}

}
