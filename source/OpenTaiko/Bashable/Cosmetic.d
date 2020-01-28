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
		foreach (Solid r ; renderables) {
			r.rect.x = cast(int)(r.rect.x * scroll);
		}
	}

	override int hit(int keyType) {
		return Success.SKIP | Value.NONE;
	}

	override int value() {
		return Value.NONE;
	}

	override bool expired() {
		return (currentPosition + width / scroll) < 0;
	}

	override bool isFinished() {
		return expired();
	}

}
