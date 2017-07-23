import std.conv : to;

// Simple timer class for sharing timing data across objects
class Timer {

	public static Timer[] timers;

	// Creates a timer object and adds it to the static list
	public static int addTimer() {
		timers ~= new Timer();
		return to!int(timers.length - 1);
	}

	// The raw time in ms
	public uint libInitPassed;

	// The current ms value to calculate from
	private uint measureFrom;
	// The pre-calculated ms value
	public uint timerPassed;

	// Only allow creating from static factory method
	private this() {
		this.libInitPassed = 0;
		this.measureFrom = 0;
	}

	// Refresh time and recalculate
	public void refresh(uint currentTime) {
		libInitPassed = currentTime;
		timerPassed = libInitPassed - measureFrom;
	}

	// Set new value to measure from
	public void set(uint newTime) {
		this.measureFrom = newTime;
	}

}
