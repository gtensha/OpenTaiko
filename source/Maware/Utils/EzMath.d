import std.conv : to;

class EzMath {

	public static int getCoords(int percentage, int from, int til) {
		return to!int(from + ((to!float(til - from) / 100) * percentage));
	}

}
