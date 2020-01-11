//  This file is part of the OpenTaiko project.
//  <https://github.com/gtensha/OpenTaiko>
//
/// Purely visual object that separates stanzas.
///
/// Authors: gtensha (@skyhvelv.net)
/// Copyright: 2019-2020 gtensha
/// License: GNU GPLv3 (no later versions)
//
//  You should have received a copy of the GNU General Public License
//  along with OpenTaiko. If not, see <https://www.gnu.org/licenses/>.

module opentaiko.bashable.separator;

import maware.renderable.solid;

import opentaiko.bashable.bashable;

class Separator : Bashable {

	enum LINE_HEIGHT = 140;
	enum LINE_WIDTH = 3;
	
	private Bashable succeedingObject; /// Really hit that object instead of this.

	this(uint position, double scroll, Bashable succeeding) {
		succeedingObject = succeeding;
	    Solid line = new Solid(LINE_WIDTH, LINE_HEIGHT, position, 0, 0xff, 0xff, 0xff, 0xff);
		super([line], position, scroll);
	}

	override public void render() {
		super.render();
		succeedingObject.render();
	}

	override public void adjustX(int xOffset) {
		super.adjustX(xOffset);
		succeedingObject.adjustX(xOffset);
	}

	override public void adjustY(int yOffset) {
		super.adjustY(yOffset);
		succeedingObject.adjustY(yOffset);
	}

	override public int hit(int key) {
		return succeedingObject.hit(key);
	}

	override public bool expired() {
		return succeedingObject.expired();
	}

	override public int value() {
		return succeedingObject.value();
	}

	override public int actualPosition() {
		return succeedingObject.actualPosition();
	}

	override public int currentPosition() {
		return succeedingObject.currentPosition();
	}

	override public bool isFinished() {
		return succeedingObject.isFinished();
	}

	override public int getObjectMaxHeight() {
		return succeedingObject.getObjectMaxHeight();
	}

	override public int getObjectLength() {
		return succeedingObject.getObjectLength();
	}

}
