//  This file is part of the OpenTaiko project.
//  <https://github.com/gtensha/OpenTaiko>
//
/// A polynomial function definition. Should support just about any degree.
///
/// Authors: gtensha (@skyhvelv.net)
/// Copyright: 2017 gtensha
/// License: GNU GPLv3 (no later versions)
//
//  You should have received a copy of the GNU General Public License
//  along with OpenTaiko. If not, see <https://www.gnu.org/licenses/>.

module maware.util.math.polynomialfunction;

import maware.util.math.functionz;

import core.vararg;
import std.math : pow;
import std.conv : to;

class PolynomialFunction (T) : Function {

	T[] constants;

	this(...) {
		constants = new T[_arguments.length];
		for (int i = 0; i < _arguments.length; i++) {
			constants[i] = va_arg!(T)(_argptr);
		}
	}

	public T getY(T x) {
		T y = 0;
		for (int i = 0; i < constants.length; i++) {
			if (!(i == constants.length - 1)) {
				y += constants[i] * pow(x, constants.length - 1 - i);
			} else {
				y += constants[i];
			}
		}
		return y;
	}

}
