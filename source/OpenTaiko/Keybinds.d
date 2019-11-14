//  This file is part of the OpenTaiko project.
//  <https://github.com/gtensha/OpenTaiko>
//
/// Defining and storing keybindings and controller mapping for one or more
/// players.
///
/// Authors: gtensha (@skyhvelv.net)
/// Copyright: 2018 gtensha
/// License: GNU GPLv3 (no later versions)
//
//  You should have received a copy of the GNU General Public License
//  along with OpenTaiko. If not, see <https://www.gnu.org/licenses/>.

module opentaiko.keybinds;

import derelict.sdl2.sdl : SDL_GameController;

/// Structure containing controller and keyboard bindings for a player
struct Keybinds {

	/// Structure containing keyboard keybinds (SDL_Keycodes) for a player
	struct Keyboard {
		int[][4] drumKeys; /// Array of LK->LD->RD->RK drum keybinds	    
	} 
	Keyboard keyboard; /// The keyboard
    
	/// Structure containing controller keybinds for a player
	struct Controller {
		SDL_GameController* activeController; /// The active controller or null for inactive
		int[4] drumKeys; /// Array of LK->LD->RD->RK drum keybinds 
	} 
	Controller controller; /// The controller

}
