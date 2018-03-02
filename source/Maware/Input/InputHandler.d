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
	SDL_Rect* inputField; /// Set to whereever the input field is located
}

/// A class for capturing input events and handling them via delegates
class InputHandler {

	/// A simple structure that contains action codes and
	/// their designated actions as delegates
	struct ActionBinder {
		void delegate()[int] actions; /// The action bindings
	}
	
	protected TextInputBinder* inputBinder; /// The bindings to call when text editing mode is enabled

	private Engine parent;
	private int[int] bindings;
	private ActionBinder[] actionBinders;
	private uint currentBinder;
	private bool isTextEditing;
	private bool typing;
	private bool enterPressed;

	/// Creates a new InputHandler for the given parent Engine
	this(Engine parent) {
		this.parent = parent;
	}

	/// Listen for events from the keyboard and handle them
	public int listenKeyboard() {
		SDL_Event event;
		while (SDL_PollEvent(&event) == 1) {
			// for some reason, using a switch here makes the game unresponsive
			// if you switch to a different window, so if/else will have to do
			if (event.type == SDL_KEYDOWN && event.key.repeat == 0) {
				if (!isTextEditing) {
					int* binding = (event.key.keysym.sym in bindings);
					if (binding !is null) {
						doAction(*binding);
						return *binding;
					}
				} else {
					if (event.key.keysym.sym == SDLK_BACKSPACE && !typing) {
						inputBinder.eraseCharacter();
					} else if (event.key.keysym.sym == SDLK_ESCAPE) {
						stopTextEditing();
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
				}
			} else if (event.type == SDL_QUIT) {
				return -1;
			} else if (event.type == SDL_TEXTINPUT) {
				inputBinder.giveText(cast(string)fromStringz(cast(char*)event.text.text));
				enterPressed = false;
				typing = false;
			} else if (event.type == SDL_TEXTEDITING) {
				//writeln(typing);
				typing = true;
			}
	
		}
		return -2;
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
	
	/// Enables text input for the currently set inputBinder
	public void enableTextEditing() {
		if (inputBinder is null) {
			throw new Exception("No InputBinder registered");
		}
		SDL_StartTextInput();
		SDL_SetTextInputRect(inputBinder.inputField);
		isTextEditing = true;
	}
	
	/// Stops registering text input
	public void stopTextEditing() {
		SDL_StopTextInput();
		isTextEditing = false;
	}

}
