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
