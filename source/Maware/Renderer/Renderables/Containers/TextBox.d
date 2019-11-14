//  This file is part of the OpenTaiko project.
//  <https://github.com/gtensha/OpenTaiko>
//
/// Effortless grouping of BoundedText objects.
///
/// Authors: gtensha (@skyhvelv.net)
/// Copyright: 2019 gtensha
/// License: GNU GPLv3 (no later versions)
//
//  You should have received a copy of the GNU General Public License
//  along with OpenTaiko. If not, see <https://www.gnu.org/licenses/>.

module maware.renderable.container.textbox;

import maware.renderable.renderable;
import maware.renderable.boundedtext;

/// A box with a set width and height and optional amount of columns to which
/// text can be added effortlessly as long as there is available space.
class TextBox : Renderable {

	private BoundedText[][] lines;
	private const int xPos;
	private const int yPos;
	private const int width;
	private const int height;
	private const int lineSpacing;

	this(int width, int height, int x, int y, int columns, int lineSpacing) {
		this.width = width;
		this.height = height;
		this.xPos = x;
		this.yPos = y;
		this.lineSpacing = lineSpacing;
		lines = new BoundedText[][columns];
	}

	/// Attempt to add this text line to the box. Inserts into the next column
	/// with available space. Returns true if insertion was successful (there was
	/// enough space,) else returns false.
	public bool addLine(BoundedText line) {
		foreach (size_t i, BoundedText[] column ; lines) {
			int y;
			if (column.length > 0) {
				BoundedText bottomLine = column[column.length - 1];
				y = bottomLine.rect.y + bottomLine.rect.h + lineSpacing;
			} else {
				y = yPos;
			}
			if (y + line.rect.h <= yPos + height) {
				line.rect.y = y;
				line.rect.x = cast(int)(xPos + i * (width / lines.length));
				line.setMaxWidth = cast(int)(width / lines.length);
				line.updateText();
				lines[i] ~= line;
				return true;
			}
		}
		return false;
	}

	public void render() {
		foreach (BoundedText[] column ; lines) {
			foreach (BoundedText line ; column) {
				line.render();
			}
		}
	}

}
