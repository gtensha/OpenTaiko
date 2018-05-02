module opentaiko.keybinds;

import derelict.sdl2.sdl : SDL_GameController;

/// Structure containing controller and keyboard bindings for a player
struct Keybinds {

	/// Structure containing keyboard keybinds (SDL_Keycodes) for a player
	struct Keyboard {
		int[4] drumKeys; /// Array of LK->LD->RD->RK drum keybinds	    
	} 
	Keyboard keyboard; /// The keyboard
    
	/// Structure containing controller keybinds for a player
	struct Controller {
		SDL_GameController* activeController; /// The active controller or null for inactive
		int[4] drumKeys; /// Array of LK->LD->RD->RK drum keybinds 
	} 
	Controller controller; /// The controller

}
