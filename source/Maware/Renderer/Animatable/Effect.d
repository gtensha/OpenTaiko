//  This file is part of the OpenTaiko project.
//  <https://github.com/gtensha/OpenTaiko>
//
/// Functionality for creating effects (changing the colour of renderable
/// objects over time according to a rule.)
///
/// Authors: gtensha (@skyhvelv.net)
/// Copyright: 2018 gtensha
/// License: GNU GPLv3 (no later versions)
//
//  You should have received a copy of the GNU General Public License
//  along with OpenTaiko. If not, see <https://www.gnu.org/licenses/>.

module maware.animatable.effect;

import maware.animatable.animatable;
import maware.renderable.solid;
import maware.util.timer;

import derelict.sdl2.sdl : SDL_Color;

/// A class for modifying color values of Solid-based Renderables
class Effect : Animatable {
	
	private Solid target; /// The target of the Effect
	immutable SDL_Color origin; /// Original color for the Solid
	private Timer timer; /// Timer for timing manipulation
	private void delegate(Timer, Solid) rule; /// The manipulation function
	
	/// Create a new Animation with the given timing and rule
	this(Timer timer, Solid target, void delegate(Timer, Solid) rule) {
		this.timer = timer;
		this.target = target;
		this.origin = target.color;
		this.rule = rule;
	}
	
	/// Manipulates the Solid's color according to set rules and timing
	void animate() {
		rule(timer, target);
	}
	
	/// Resets the Solid's color property to origin
	void reset() {
		target.color = origin;
	}
	
}
