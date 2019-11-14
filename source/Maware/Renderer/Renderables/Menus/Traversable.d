//  This file is part of the OpenTaiko project.
//  <https://github.com/gtensha/OpenTaiko>
//
/// This module contains the Traversable interface. The idea is that all menu
/// objects will implement this interface, so that they can be both treated as
/// renderable objects and be navigated in the same way, for a seamless menu
/// ecosystem. This module should contain all the standards related to menus.
///
/// Authors: gtensha (@skyhvelv.net)
/// Copyright: 2017 gtensha
/// License: GNU GPLv3 (no later versions)
//
//  You should have received a copy of the GNU General Public License
//  along with OpenTaiko. If not, see <https://www.gnu.org/licenses/>.

module maware.renderable.menus.traversable;

import maware.renderable.renderable;

enum Moves : bool {
	RIGHT = true,
	LEFT = false,
	UP = false,
	DOWN = true
};

interface Traversable : Renderable {

	public void move(bool);

	public Traversable press();

}
