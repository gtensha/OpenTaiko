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
	public static uint libInitPassed;

	// The current ms value to calculate from
	private uint measureFrom;
	// The current ms value to calculate to
	private uint measureTo;

	// Only allow creating from static factory method
	private this() {
		this.libInitPassed = 0;
		this.measureFrom = 0;
	}

	// Refresh time and recalculate
	public static void refresh(uint currentTime) {
		libInitPassed = currentTime;
	}

	// Calculate time passed and return
	public uint getTimerPassed() {
		return libInitPassed - measureFrom;
	}

	// Returns percentage value of how much of the time has passed
	public int getPercentagePassed() {
		return to!int((to!float(getTimerPassed()) / to!float(measureTo)) * 100);
	}

	// Set new value to measure from
	public void set(uint newTime) {
		this.measureFrom = newTime;
	}

	public void set(uint newTime, uint newTimeTo) {
		this.measureFrom = newTime;
		this.measureTo = newTimeTo;
	}

}
