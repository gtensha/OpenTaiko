module maware.util.precisetimer;

import maware.util.timer;

/// A timer that can update its offset at set intervals
class PreciseTimer : Timer {
	
	int delegate() getSecondOpinion; /// Callback to get accurate timer value
	int adjustInterval; /// How often to check for accuracy in ms
	int lastCheck; /// Last time (since lib init) accuracy was checked
	private int originalFrom;
	
	/// Create a new PreciseTimer with 1 sec accuracy adjust
	this(int delegate() getPreciseTimeCallback) {
		getSecondOpinion = getPreciseTimeCallback;
		adjustInterval = 1_000;
	}
	
	/// Create a new PreciseTimer with custom adjustInterval
	this(int delegate() getPreciseTimeCallback, int adjustInterval) {
		getSecondOpinion = getPreciseTimeCallback;
		this.adjustInterval = adjustInterval;
	}
	
	/// If timer has passed faster than source, subtract difference
	void adjustAccuracy() { // TODO: make this smoother (remove jitter)
		measureFrom = libInitPassed - getSecondOpinion();
		lastCheck = libInitPassed;
	}
	
	override uint getTimerPassed() {
		if (getSecondOpinion !is null && 
			libInitPassed - lastCheck > adjustInterval) {

			adjustAccuracy();
		}
		return libInitPassed - measureFrom;
	}
	
	override void set(uint newTime) {
		measureFrom = newTime;
		originalFrom = newTime;
	}
	
	override void set(uint newTime, uint newTimeTo) {
		set(newTime);
		measureTo = newTimeTo;
	}
	
}
