module maware.util.precisetimer;

import maware.util.timer;

/// A timer that can update its offset at set intervals
class PreciseTimer : Timer {

	enum ADJUSTINTERVAL_DEFAULT = 1_000;
	
	long delegate() getSecondOpinion; /// Callback to get accurate timer value
	uint adjustInterval; /// How often to check for accuracy in ms
	long lastCheck; /// Last time (since lib init) accuracy was checked
	long regardlessOffset; /// Value in milliseconds that will be added or subtracted from timer value
	private long originalFrom;
	
	/// Create a new PreciseTimer with 1 sec accuracy adjust
	this(long delegate() getPreciseTimeCallback) {
		getSecondOpinion = getPreciseTimeCallback;
		adjustInterval = ADJUSTINTERVAL_DEFAULT;
	}
	
	/// Create a new PreciseTimer with custom adjustInterval
	this(long delegate() getPreciseTimeCallback, uint adjustInterval) {
		getSecondOpinion = getPreciseTimeCallback;
		this.adjustInterval = adjustInterval;
	}
	
	/// If timer has passed faster than source, subtract difference
	void adjustAccuracy() { // TODO: make this smoother (remove jitter)
		measureFrom = libInitPassed - getSecondOpinion();
		lastCheck = libInitPassed;
	}
	
	override long getTimerPassed() {
		if (libInitPassed - lastCheck > adjustInterval) {
			if (getSecondOpinion !is null) {
				adjustAccuracy();
			}
		}
		return libInitPassed - measureFrom + regardlessOffset;
	}
	
	override void set(long newTime) {
		measureFrom = newTime;
		originalFrom = newTime;
	}
	
	override void set(long newTime, long newTimeTo) {
		set(newTime);
		measureTo = newTimeTo;
	}
	
}
