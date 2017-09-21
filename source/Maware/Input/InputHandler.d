import derelict.sdl2.sdl;/* : SDL_PollEvent,
						   SDL_Event,
						   SDL_Keycode,
						   SDL_KeyboardEvent,
						   SDL_EventType;*/
import Engine : Engine;

class InputHandler {

	struct ActionBinder {
		void delegate()[] actions;
		int[] bindings;
	}

	private Engine parent;
	private int[] bindings;
	private ActionBinder[] actionBinders;
	private uint currentBinder;

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
						doAction(i);
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

	public int addActionBinder() {
		ActionBinder toAdd;

		actionBinders ~= toAdd;
		return cast(int)actionBinders.length - 1;
	}

	public void bindAction(int binderID, int actionID, void delegate() action) {
		if (binderID < actionBinders.length) {
			actionBinders[binderID].actions ~= action;
			actionBinders[binderID].bindings ~= actionID;
		} else {
			throw new Exception("Error: Tried to bind to ActionBinder out of bounds");
		}
	}

	private void doAction(int action) {
		int i = 0;
		foreach (int actionID ; actionBinders[currentBinder].bindings) {
			if (actionID == action) {
				actionBinders[currentBinder].actions[i]();
				return;
			}
			i++;
		}
	}

	public void setActive(uint index) {
		if (index < actionBinders.length) {
			currentBinder = index;
		} else {
			throw new Exception("Error: Tried to set ActionBinder out of bounds");
		}
	}

}
