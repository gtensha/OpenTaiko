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
