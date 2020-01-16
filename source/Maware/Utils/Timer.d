//  This file is part of the OpenTaiko project.
//  <https://github.com/gtensha/OpenTaiko>
//
/// Effortlessly manage timing of different gameplay and GUI elements.
///
/// Authors: gtensha (@skyhvelv.net)
/// Copyright: 2017-2020 gtensha
/// License: GNU GPLv3 (no later versions)
//
//  You should have received a copy of the GNU General Public License
//  along with OpenTaiko. If not, see <https://www.gnu.org/licenses/>.

module maware.util.timer;

import std.conv : to;

/// Simple timer class for sharing timing data across objects. The time is
/// stored as milliseconds, and is not intended for precise measurement of time.
class Timer {

	/// The raw time in milliseconds. This value must be incremented regularly
	/// (every frame, for instance) and must never be decremented, as such an
	/// operation will result in undefined behavior. As the value is 64-bit,
	/// it is assumed that the program never will run long enough for it to ever
	/// wrap.
	public shared static long libInitPassed;

	/// The time in milliseconds this timer was set to measure from. It is set
	/// relative to libInitPassed, so that (libInitPassed - measureFrom) gives
	/// the amount of milliseconds passed.
	protected long measureFrom;
	/// When this value is set greater than measureFrom, getPercentagePassed
	/// is able to calculate how many percent of the time interval between
	/// measureFrom and measureTo has passed.
	protected long measureTo;

	/// Sets libInitPassed to currentTime. currentTime must be greater than the
	/// previous value in libInitPassed, lest undefined behavior be encountered.
	public static void refresh(const long currentTime) {
		libInitPassed = currentTime;
	}

	/// Return the time passed in milliseconds since the timer was set. If the
	/// time previously set hasn't been reached yet, the value will be negative,
	/// how many milliseconds remain until the target time has been reached.
	public long getTimerPassed() {
		return libInitPassed - measureFrom;
	}
	
	/// Returns percentage value of how much of the time has passed. Implies
	/// measureTo being set.
	public double getPercentagePassed() {
		if (libInitPassed >= measureTo) {
			return 100;
		} else if (libInitPassed <= measureFrom) {
			return 0;
		} else {
			return ((libInitPassed - measureFrom) * 100.0) / (measureTo - libInitPassed);
		}
	}

	/// Sets the timer to measure from newTime, a value in milliseconds. After
	/// this getTimerPassed() can be called to get the amount of milliseconds
	/// passed since newTime.
	public void set(const long newTime) {
		this.measureFrom = newTime;
	}

	/// Sets the timer to measure from newTime, a value in milliseconds. Also,
	/// sets the time to measure to, making it possible to call
	/// getPercentagePassed. newTimeTo must be greater than newTime.
	public void set(const long newTime, const long newTimeTo) {
		this.measureFrom = newTime;
		this.measureTo = newTimeTo;
	}

}
