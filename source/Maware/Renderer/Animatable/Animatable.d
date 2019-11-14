//  This file is part of the OpenTaiko project.
//  <https://github.com/gtensha/OpenTaiko>
//
/// Base functionality for creating animations and effects.
///
/// Authors: gtensha (@skyhvelv.net)
/// Copyright: 2018 gtensha
/// License: GNU GPLv3 (no later versions)
//
//  You should have received a copy of the GNU General Public License
//  along with OpenTaiko. If not, see <https://www.gnu.org/licenses/>.

module maware.animatable.animatable;

/// Interface for making animations and effects
interface Animatable {
	
	/// Should be callable in a frame to alter a Renderable's properties
	public void animate();
	
	/// Should reset a state to its origin
	public void reset();
	
}
