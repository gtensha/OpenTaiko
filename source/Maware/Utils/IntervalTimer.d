module maware.util.intervaltimer;

import maware.util.timer;

import std.stdio;

/// Timer variant that gives percentage or raw values as an interval
/// getTimerPassed and getPercentagePassed go up to measureTo and go down to
/// 0 again when reached
class IntervalTimer : Timer {
	
	uint interval; /// Stores the interval length for quick access (cannot be changed directly)
	
	override public uint getTimerPassed() {
		const uint passed = libInitPassed - measureFrom;
		const uint excess = passed / interval;
		return passed - interval * excess;
	}
	
	override public double getPercentagePassed() {
		return ((getTimerPassed() / cast(double)interval) * 100.0);
	}
	
	/// Sets the timer's interval to the given length
	public void setInterval(uint intervalLen) {
		measureFrom = libInitPassed;
		measureTo = measureFrom + intervalLen;
		interval = intervalLen;
	}
	
}
