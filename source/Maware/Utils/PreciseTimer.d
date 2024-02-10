//  This file is part of the OpenTaiko project.
//  <https://github.com/gtensha/OpenTaiko>
//
/// Stay synced with a differently timed resource (music playback, etc.)
///
/// Authors: gtensha (@skyhvelv.net)
/// Copyright: 2018-2019 gtensha
/// License: GNU GPLv3 (no later versions)
//
//  You should have received a copy of the GNU General Public License
//  along with OpenTaiko. If not, see <https://www.gnu.org/licenses/>.

module maware.util.precisetimer;

import maware.util.timer;

/// A timer that can update its offset at set intervals
class PreciseTimer : Timer {

	enum ADJUSTINTERVAL_DEFAULT = 1_000;
	
	long delegate() getSecondOpinion; /// Callback to get accurate timer value
	uint adjustInterval; /// How often to check for accuracy in ms
	long lastCheck; /// Last time (since lib init) accuracy was checked
	/// Value in milliseconds that will be added or subtracted from timer value
	long regardlessOffset;
	private long originalFrom;
	private long oldMeasure;
	private long measureDiff;
	
	/// Create a new PreciseTimer with 1 sec accuracy adjust
	this(long delegate() getPreciseTimeCallback) {
		this(getPreciseTimeCallback, ADJUSTINTERVAL_DEFAULT);
	}
	
	/// Create a new PreciseTimer with custom adjustInterval
	this(long delegate() getPreciseTimeCallback, uint adjustInterval) {
		getSecondOpinion = getPreciseTimeCallback;
		this.adjustInterval = adjustInterval;
	}
	
	/// If timer has passed faster than source, subtract difference
	void adjustAccuracy() { // TODO: make this smoother (remove jitter)
		oldMeasure = measureFrom;
		measureFrom = libInitPassed - getSecondOpinion();
		measureDiff = measureFrom - oldMeasure;
		lastCheck = libInitPassed;
	}
	
	override long getTimerPassed() {
		if (libInitPassed - lastCheck > adjustInterval) {
			if (getSecondOpinion !is null) {
				adjustAccuracy();
			}
		}
		const double correction = (((libInitPassed - lastCheck)
									/ cast(double) (lastCheck + adjustInterval))
								   * measureDiff);	  
		return (libInitPassed
				- oldMeasure
				+ cast(long) correction
				+ regardlessOffset);
	}
	
	override void set(long newTime) {
		measureFrom = newTime;
		oldMeasure = newTime;
		originalFrom = newTime;
	}
	
	override void set(long newTime, long newTimeTo) {
		set(newTime);
		measureTo = newTimeTo;
	}
	
}
