module maware.inputhandler;

import derelict.sdl2.sdl;/* : SDL_PollEvent,
						   SDL_Event,
						   SDL_Keycode,
						   SDL_KeyboardEvent,
						   SDL_EventType;*/
import maware.engine;

import std.string : fromStringz;
import std.conv : to;
import std.stdio;

/// Structure to manage text editing callbacks
struct TextInputBinder {
	void delegate(string) giveText; /// Called to give a text chunk
	void delegate() eraseCharacter; /// Called to erase a character
	void delegate(bool) moveCursor; /// Called to move the cursor's position
	void delegate() commit; /// Called on enter press
	void delegate() cancel; /// Called on escape press (cancel)
	SDL_Rect* inputField; /// Set to whereever the input field is located
}

/// A class for capturing input events and handling them via delegates
class InputHandler {

	enum QUIT_EVENT_CODE = -1; /// Code for when a quit event occurs
	enum NONE_EVENT_CODE = -2; /// Code for when no event occured

	/// A simple structure that contains action codes and
	/// their designated actions as delegates
	struct ActionBinder {
		void delegate()[int] actions; /// The action bindings
		void delegate(int) anyKeyPressAction; /// Function to call in any key listen mode
	}
	
	protected TextInputBinder* inputBinder; /// The bindings to call when text editing mode is enabled
	
	private int delegate(SDL_Event) activeEventHandler; /// Current handler for events

	private Engine parent;
	private int[int] bindings;
	private ActionBinder[] actionBinders;
	private uint currentBinder;
	private bool typing;
	private bool enterPressed;

	/// Creates a new InputHandler for the given parent Engine
	this(Engine parent) {
		this.parent = parent;
		activeEventHandler = &listenKeyAction;
	}

	/// Listens for events from the keyboard and handles them
	/// Returns the code of the last handled event
	public int listenHandleEvents() {
		SDL_Event event;
		int retCode = NONE_EVENT_CODE;
		while (SDL_PollEvent(&event) == 1 && retCode != QUIT_EVENT_CODE) {
			if (event.type == SDL_QUIT) {
				retCode = QUIT_EVENT_CODE;
			} else {
				retCode = activeEventHandler(event);
			}
		}
		return retCode;
	}
	
	/// Handle keypresses according to bound actions in currently active
	/// ActionBinder
	private int listenKeyAction(SDL_Event event) {
		if (event.type == SDL_KEYDOWN && event.key.repeat == 0) {
			int* binding = (event.key.keysym.sym in bindings);
			if (binding !is null) {
				doAction(*binding);
				return *binding;
			}
		}
		return NONE_EVENT_CODE;
	}
	
	/// Listen for any keypresses, return their keycode and call the 
	/// anyKeyPressAction callback if defined
	private int listenAnyKey(SDL_Event event) {
		if (event.type == SDL_KEYDOWN) {
			void delegate(int) action = actionBinders[currentBinder].anyKeyPressAction;
			if (action !is null) {
				action(event.key.keysym.sym);
			}
			return event.key.keysym.sym;
		} else {
			return NONE_EVENT_CODE;
		}
	}
	
	/// Listen for textediting events
	private int listenTextEditing(SDL_Event event) {
		if (event.type == SDL_KEYDOWN) { // TODO: non-hardcoded editing keys
			if (event.key.keysym.sym == SDLK_BACKSPACE && !typing) {
				inputBinder.eraseCharacter();
			} else if (event.key.keysym.sym == SDLK_ESCAPE) {
				cancelTextEditing();
			} else if (event.key.keysym.sym == SDLK_RETURN && !typing) {
				if (!enterPressed) {
					enterPressed = true; // need enter twice
				} else {
					if (inputBinder.commit !is null) {
						inputBinder.commit();
					}
					stopTextEditing();
				}
			} else if ((event.key.keysym.sym == SDLK_v 
			            && 
			            SDL_GetModState() & KMOD_CTRL)
			           ||
					   (event.key.keysym.sym == SDLK_INSERT 
			            && 
			            SDL_GetModState() & KMOD_SHIFT)) {

				inputBinder.giveText(cast(string)fromStringz(cast(char*)SDL_GetClipboardText()));
			}
		} else if (event.type == SDL_TEXTINPUT) {
			inputBinder.giveText(cast(string)fromStringz(cast(char*)event.text.text));
			enterPressed = false;
			typing = false;
		} else if (event.type == SDL_TEXTEDITING) {
			typing = true;
		}
		return NONE_EVENT_CODE;
	}

	/// Bind the key with the given SDL_Keycode to the given event number
	public void bind(int event, int key) {
		bindings[key] = event;
		bindings = bindings.rehash();
	}

	/// Bind multiple keys simultaneously
	public void bind(int[] keys) {
		foreach (int event, int key ; keys) {
			bindings[key] = event;
		}
		bindings = bindings.rehash();
	}

	/// Adds an ActionBinder to the system and returns its index
	public int addActionBinder() {
		ActionBinder toAdd;
		actionBinders ~= toAdd;
		return cast(int)actionBinders.length - 1;
	}
	
	/// Binds an action delegate to be used when listening for any keypress
	/// to the ActionBinder with binderID
	public void setAnyKeyAction(int binderID, void delegate(int) action) {
		actionBinders[binderID].anyKeyPressAction = action;
	}

	/// Binds an action delegate with the action number actionID, to binder
	/// with index binderID
	public void bindAction(int binderID, int actionID, void delegate() action) {
		actionBinders[binderID].actions[actionID] = action;
		actionBinders[binderID].actions = actionBinders[binderID].actions.rehash();
	}

	/// Runs the delegate assigned to the code action in the currently active
	/// binder
	private void doAction(int action) {
		void delegate()* binding;
		binding = (action in actionBinders[currentBinder].actions);
		if (binding !is null) {
			void delegate() instruction = *binding;
			instruction();
		}
	}
	
	/// Returns an array of key codes associated with actionCode
	public int[] findAssociatedKeys(int actionCode) {
		int[] keyCodes;
		foreach (int code ; bindings.keys) {
			int boundKey = bindings[code];
			if (boundKey == actionCode) {
				keyCodes ~= code;
			}
		}
		return keyCodes;
	}
	
	/// Returns the keyCode as a string
	static string getKeyName(int keyCode) {
		return to!string(fromStringz(SDL_GetKeyName(keyCode)));
	}

	/// Sets the active ActionBinder with given index or throws Exception
	/// on failure
	public void setActive(uint index) {
		if (index < actionBinders.length) {
			currentBinder = index;
		} else {
			throw new Exception("Error: Tried to set ActionBinder out of bounds");
		}
	}
	
	/// Sets the active TextInputBinder to feed text when text editing is enabled
	public void setInputBinder(TextInputBinder* binder) {
		this.inputBinder = binder;
	}
	
	/// Enables listening for any keypress
	public void enableAnyKeyListen() {
		activeEventHandler = &listenAnyKey;
	}
	
	public void enableBoundActionListen() {
		activeEventHandler = &listenKeyAction;
	}
	
	/// Enables text input for the currently set inputBinder
	public void enableTextEditing() {
		if (inputBinder is null) {
			throw new Exception("No InputBinder registered");
		}
		SDL_StartTextInput();
		SDL_SetTextInputRect(inputBinder.inputField);
		activeEventHandler = &listenTextEditing;
	}
	
	/// Calls the cancel delegate and stops editing
	private void cancelTextEditing() {
		if (inputBinder.cancel !is null) {
			inputBinder.cancel();		
		}
		stopTextEditing();
	}	
	
	/// Stops registering text input
	public void stopTextEditing() {
		SDL_StopTextInput();
		activeEventHandler = &listenKeyAction;
	}

}
