//  This file is part of the OpenTaiko project.
//  <https://github.com/gtensha/OpenTaiko>
//
/// This module contains the Renderable interface. All objects which can be
/// rendered on screen, should implement this interface. It is used in Scene
/// among other places to render objects independent of properties and type.
///
/// Authors: gtensha (@skyhvelv.net)
/// Copyright: 2017 gtensha
/// License: GNU GPLv3 (no later versions)
//
//  You should have received a copy of the GNU General Public License
//  along with OpenTaiko. If not, see <https://www.gnu.org/licenses/>.

module maware.renderable.renderable;

interface Renderable {

	public void render();

}
