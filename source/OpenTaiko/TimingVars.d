//  This file is part of the OpenTaiko project.
//  <https://github.com/gtensha/OpenTaiko>
//
/// Different adjustable timing values.
///
/// Authors: gtensha (@skyhvelv.net)
/// Copyright: 2019 gtensha
/// License: GNU GPLv3 (no later versions)
//
//  You should have received a copy of the GNU General Public License
//  along with OpenTaiko. If not, see <https://www.gnu.org/licenses/>.

module opentaiko.timingvars;

/// A struct that holds millisecond values related to gameplay timing.
struct TimingVars {

	/// Hits will be added (or subtracted) this many milliseconds before
	/// registering.
	int hitOffset;
	/// Hits will have to be this many milliseconds late or early in order to
	/// count as a successful hit.
	uint hitWindow;
	/// As hitWindow, but for hits that will give the highest score.
	uint goodHitWindow;
	/// The size of the window before a hit can be registered. If hit within
	/// this many milliseconds before hitWindow, the hit will be registered as
	/// a miss.
	uint preHitDeadWindow;

}
