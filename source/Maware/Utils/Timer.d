//  This file is part of the OpenTaiko project.
//  <https://github.com/gtensha/OpenTaiko>
//
/// Effortlessly manage timing of different gameplay and GUI elements.
///
/// Authors: gtensha (@skyhvelv.net)
/// Copyright: 2017-2019 gtensha
/// License: GNU GPLv3 (no later versions)
//
//  You should have received a copy of the GNU General Public License
//  along with OpenTaiko. If not, see <https://www.gnu.org/licenses/>.

module maware.util.timer;

import std.conv : to;

/// Simple timer class for sharing timing data across objects
class Timer {

	public static Timer[] timers;

	/// Creates a timer object and adds it to the static list
	public static int addTimer() {
		timers ~= new Timer();
		return to!int(timers.length - 1);
	}

	/// The raw time in ms
	public shared static long libInitPassed;

	/// The current ms value to calculate from
	protected long measureFrom;
	/// The current ms value to calculate to. It is used by getPercentagePassed
	protected long measureTo;

	/// Refresh time and recalculate
	public static void refresh(long currentTime) {
		libInitPassed = currentTime;
	}

	/// Calculate time passed and return
	public long getTimerPassed() {
		return libInitPassed - measureFrom;
	}
	
	/// Returns percentage value of how much of the time has passed. If you do
	/// not set newTimeTo with set(), this will always return 100.
	public double getPercentagePassed() {
		if (libInitPassed >= measureTo) {
			return 100;
		} else if (libInitPassed <= measureFrom) {
			return 0;
		} else {
			return ((libInitPassed - measureFrom) * 100.0) / (measureTo - libInitPassed);
		}
	}

	/// Set new value to measure from
	public void set(long newTime) {
		this.measureFrom = newTime;
	}

	/// Set new value to measure from, and to
	public void set(long newTime, long newTimeTo) {
		this.measureFrom = newTime;
		this.measureTo = newTimeTo;
	}

}
