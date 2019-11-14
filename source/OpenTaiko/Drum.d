//  This file is part of the OpenTaiko project.
//  <https://github.com/gtensha/OpenTaiko>
//
/// Authors: gtensha (@skyhvelv.net)
/// Copyright: 2017 gtensha
/// License: GNU GPLv3 (no later versions)
//
//  You should have received a copy of the GNU General Public License
//  along with OpenTaiko. If not, see <https://www.gnu.org/licenses/>.

module opentaiko.drum;

import opentaiko.performance : Performance;

deprecated class Drum {

	int hitType;
	static Performance parent;

	public immutable double position;

	this(double time) {
		position = time;
	}

	// Set the parent (performance) of all
	// created drum objects
	static void setParent(Performance parent) {
		this.parent = parent;
	}

	// Attempt to hit this drum circle,
	// return result
	int hit(int key, int time) {
		if (time < this.position - 200.0) {
			return 3;
		}
		int successType = 2;
		if (key == this.hitType) {
			if (time < this.position + 50.0 && time > position - 50.0) {
				successType = 0;
			} else if (time < this.position + 200.0 && time > position - 200.00) {
				successType = 1;
			} else {
				successType = 2;
			}
		} else {
			successType = 2;
		}
		this.parent.nextDrum();
		return successType;
	}

	int color() {
		return -1;
	}

}

deprecated class Red : Drum {

	this(double time) {
		super(time);
		hitType = 0;
	}

	override int color() {
		return 0;
	}

}

deprecated class Blue : Drum {

	this(double time) {
		super(time);
		hitType = 1;
	}

	override int color() {
		return 1;
	}

}
