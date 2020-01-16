//  This file is part of the OpenTaiko project.
//  <https://github.com/gtensha/OpenTaiko>
//
/// Timing things that occur in intervals.
///
/// Authors: gtensha (@skyhvelv.net)
/// Copyright: 2018-2020 gtensha
/// License: GNU GPLv3 (no later versions)
//
//  You should have received a copy of the GNU General Public License
//  along with OpenTaiko. If not, see <https://www.gnu.org/licenses/>.

module maware.util.intervaltimer;

import maware.util.timer;

import std.stdio;

/// Timer variant that gives percentage or raw values as an interval.
/// getTimerPassed and getPercentagePassed go up to measureTo and go down to
/// 0 again when reached.
class IntervalTimer : Timer {

	long interval; /// Stores the interval length for quick access (cannot be changed directly)
	
	override public long getTimerPassed() {
		const long passed = libInitPassed - measureFrom;
		const long excess = passed / interval;
		return passed - interval * excess;
	}

	override public double getPercentagePassed() {
		return ((getTimerPassed() / cast(double)interval) * 100.0);
	}

	/// Sets the timer's interval to the given length
	public void setInterval(long intervalLen) {
		measureFrom = libInitPassed;
		measureTo = measureFrom + intervalLen;
		interval = intervalLen;
	}

}
