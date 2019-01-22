module opentaiko.score;

import std.array : split;
import std.conv : to;
import std.datetime.date : DateTime;
import std.format : format;

/// Exception meant to be thrown by Score in the static fromString() method
class ScoreParseException : Exception {
	this(string msg) {
		super(msg);
	}
}

/// A class representing a "score" value, being any score achieved by some player
/// during gameplay. It is made to be conveniently read from and written to file.
/// The string format is a string composed of 6 integers and one ISO date string.
/// They are separated by a space. See internal Index enum for indices regarding
/// the different values.
class Score {

	/// Score values for different hit objects
	enum Value : int {
		GOOD = 300,
		OK = 100,
		ROLL = 50
	}

	/// Score multiplier values for different hit objects
	enum Multiplier : real {
		NORMAL = 1.0,
		LARGE = 1.5
	}

	enum STRING_SECTION_COUNT = 7; /// Amount of values in string
	enum VALUE_SEPARATOR = " "; /// Separator used to separate values in string

	/// Indices when converted to string
	enum Index : int {
		PLAYERID = 0,
		SCORE = 1,
		GOOD = 2,
		OK = 3,
		BAD = 4,
		COMBO = 5,
		TIME = 6
	}

	immutable int playerId; /// Player ID for score
	immutable int score; /// Score value computed at completion
	immutable int good; /// Amount of good hits
	immutable int ok; /// Amount of ok hits
	immutable int bad; /// Amount of bad (miss) hits
	immutable int maxCombo; /// Highest combo achieved
	immutable DateTime time; /// Time of completion

	this(int playerId,
		 int score,
		 int good,
		 int ok,
		 int bad,
		 int maxCombo,
		 DateTime time) {

		this.playerId = playerId;
		this.score = score;
		this.good = good;
		this.ok = ok;
		this.bad = bad;
		this.maxCombo = maxCombo;
		this.time = time;
	}

	/// Returns a string representation of this Score object, suitable for
	/// writing to a file. Uses the same format read by fromString()
	public override string toString() {
		return "%d %d %d %d %d %d %s".format(playerId,
											 score,
											 good,
											 ok,
											 bad,
											 maxCombo,
											 time.toISOExtString());
	}

	/// Reads a formatted string from fmt and returns a new Score object with the
	/// corresponding values. Throws a ScoreParseException if any error occurs.
	static Score fromString(string fmt) {
		string[] split = fmt.split(VALUE_SEPARATOR);
		if (split.length != STRING_SECTION_COUNT) {
			throw new ScoreParseException("Section count mismatch: "
										  ~ to!string(split.length)
										  ~ "/"
										  ~ to!string(STRING_SECTION_COUNT + 0));
		}
		try {
			int id = to!int(split[Index.PLAYERID]);
			int score = to!int(split[Index.SCORE]);
			int good = to!int(split[Index.GOOD]);
			int ok = to!int(split[Index.OK]);
			int bad = to!int(split[Index.BAD]);
			int maxCombo = to!int(split[Index.COMBO]);
			DateTime time = DateTime.fromISOExtString(split[Index.TIME]);
			return new Score(id, score, good, ok, bad, maxCombo, time);
		} catch (Exception e) {
			throw new ScoreParseException("Bad string format: " ~ e.msg);
		}
	}

	bool opEquals(Score other) {
		return this.score == other.score;
	}

	alias opEquals = Object.opEquals;

	int opCmp(Score other) {
		return this.score - other.score;
	}

	alias opCmp = Object.opCmp;

}
