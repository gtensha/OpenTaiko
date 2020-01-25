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

import opentaiko.bashable.cosmetic;

/// A vertical line.
class Separator : Cosmetic {

	enum LINE_HEIGHT = 90;
	enum LINE_WIDTH = 3;

	this(uint position, double scroll) {
		Solid line = new Solid(LINE_WIDTH, LINE_HEIGHT, position, 0, 0xff, 0xff, 0xff, 0xff);
		super([line], position, scroll);
	}

}
