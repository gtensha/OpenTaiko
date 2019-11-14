//  This file is part of the OpenTaiko project.
//  <https://github.com/gtensha/OpenTaiko>
//
/// Mathematical functions that don't belong anywhere in particular.
///
/// Authors: gtensha (@skyhvelv.net)
/// Copyright: 2017-2018 gtensha
/// License: GNU GPLv3 (no later versions)
//
//  You should have received a copy of the GNU General Public License
//  along with OpenTaiko. If not, see <https://www.gnu.org/licenses/>.

module maware.util.math.ezmath;

import std.conv : to;

class EzMath {

	public static int getCoords(int percentage, int from, int til) {
		return cast(int)(from + (((til - from) / 100.0) * percentage));
	}
	
	public static int getCoords(double percentage, int from, int til) {
		return cast(int)(from + (((til - from) / 100.0) * percentage));
	}

}
