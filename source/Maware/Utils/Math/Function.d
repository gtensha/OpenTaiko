//  This file is part of the OpenTaiko project.
//  <https://github.com/gtensha/OpenTaiko>
//
/// Defining different mathematical functions and allowing them to be
/// interchangeable.
///
/// Authors: gtensha (@skyhvelv.net)
/// Copyright: 2017 gtensha
/// License: GNU GPLv3 (no later versions)
//
//  You should have received a copy of the GNU General Public License
//  along with OpenTaiko. If not, see <https://www.gnu.org/licenses/>.

module maware.util.math.functionz;

interface Function {

	public T getY(T)(T x);

}
