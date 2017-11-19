module maware.inputhandler;

import derelict.sdl2.sdl;/* : SDL_PollEvent,
						   SDL_Event,
						   SDL_Keycode,
						   SDL_KeyboardEvent,
						   SDL_EventType;*/
import maware.engine;

class InputHandler {

	struct ActionBinder {
		void delegate()[int] actions;
	}

	private Engine parent;
	private int[int] bindings;
	private ActionBinder[] actionBinders;
	private uint currentBinder;

	this(Engine parent) {
		this.parent = parent;
	}

	public int listenKeyboard() {
		SDL_Event event;
		while (SDL_PollEvent(&event) == 1) {
			if (event.type == SDL_KEYDOWN && event.key.repeat == 0) {
				int* binding = (event.key.keysym.sym in bindings);
				if (binding !is null) {
					doAction(*binding);
					return *binding;
				}

			} else if (event.type == SDL_QUIT) {
				return -1;
			}
		}
		return -2;
	}

	public void bind(int event, int key) {
		bindings[key] = event;
		bindings = bindings.rehash();
	}

	public void bind(int[] keys) {
		foreach (int event, int key ; keys) {
			bindings[key] = event;
		}
		bindings = bindings.rehash();
	}

	public int addActionBinder() {
		ActionBinder toAdd;
		actionBinders ~= toAdd;
		return cast(int)actionBinders.length - 1;
	}

	public void bindAction(int binderID, int actionID, void delegate() action) {
			actionBinders[binderID].actions[actionID] = action;
			actionBinders[binderID].actions = actionBinders[binderID].actions.rehash();
	}

	private void doAction(int action) {
		void delegate()* binding;
		binding = (action in actionBinders[currentBinder].actions);
		if (binding !is null) {
			void delegate() instruction = *binding;
			instruction();
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
