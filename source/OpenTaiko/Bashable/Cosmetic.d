//  This file is part of the OpenTaiko project.
//  <https://github.com/gtensha/OpenTaiko>
//
/// Superclass for objects that are meant to be rendered as hit objects, but are
/// purely visual.
///
/// Authors: gtensha (@skyhvelv.net)
/// Copyright: 2020 gtensha
/// License: GNU GPLv3 (no later versions)
//
//  You should have received a copy of the GNU General Public License
//  along with OpenTaiko. If not, see <https://www.gnu.org/licenses/>.

module opentaiko.bashable.cosmetic;

import maware.renderable.solid;

import opentaiko.bashable.bashable;

/// Basic dummy Bashable class that does nothing when hit.
class Cosmetic : Bashable {

	immutable int width;

	this(Solid[] renderables, uint position, double scroll) {
		super(renderables, position, scroll);
		width = getObjectLength();
	}

	override int hit(int keyType) {
		return Success.SKIP | Value.NONE;
	}

	override int value() {
		return Value.NONE;
	}

	override bool expired() {
		return currentOffset > actualPosition() + width / scroll;
	}

	override bool isFinished() {
		return expired();
	}

}
