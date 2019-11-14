//  This file is part of the OpenTaiko project.
//  <https://github.com/gtensha/OpenTaiko>
//
/// Functionality for creating animations (manipulating the size and position
/// of renderable objects over time according to a rule.)
///
/// Authors: gtensha (@skyhvelv.net)
/// Copyright: 2018 gtensha
/// License: GNU GPLv3 (no later versions)
//
//  You should have received a copy of the GNU General Public License
//  along with OpenTaiko. If not, see <https://www.gnu.org/licenses/>.

module maware.animatable.animation;

import maware.renderable.solid;
import maware.animatable.animatable;
import maware.util.timer;

import derelict.sdl2.sdl : SDL_Rect;

/// A class for manipulating the position and/or size of Solid-based renderables
class Animation : Animatable {
	
	private Solid target; /// The target of the Animation
	immutable SDL_Rect origin; /// Original position for the Solid
	private Timer timer; /// Timer for timing manipulation
	private void delegate(Timer, Solid) rule; /// The manipulation function
	
	/// Create a new Animation with the given timing and rule
	this(Timer timer, Solid target, void delegate(Timer, Solid) rule) {
		this.timer = timer;
		this.target = target;
		this.origin = target.rect;
		this.rule = rule;
	}
	
	/// Manipulates the Solid's rect according to set rules and timing
	void animate() {
		rule(timer, target);
	}
	
	/// Resets the Solid's rect property to origin
	void reset() {
		target.rect = origin;
	}
	
}
