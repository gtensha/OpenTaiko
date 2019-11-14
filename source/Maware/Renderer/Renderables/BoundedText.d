//  This file is part of the OpenTaiko project.
//  <https://github.com/gtensha/OpenTaiko>
//
/// Functionality for creating subclasses of Text that have a length (in pixels)
/// limit.
///
/// Authors: gtensha (@skyhvelv.net)
/// Copyright: 2019 gtensha
/// License: GNU GPLv3 (no later versions)
//
//  You should have received a copy of the GNU General Public License
//  along with OpenTaiko. If not, see <https://www.gnu.org/licenses/>.

module maware.renderable.boundedtext;

import maware.renderable.text;

import derelict.sdl2.sdl : SDL_Color;
import derelict.sdl2.ttf : TTF_Font;

/// Abstract class from which text that has a set bound can be derived
/// universally
abstract class BoundedText : Text {

	private int maxWidth;

	this(string text,
		 TTF_Font* font,
		 bool pretty,
		 int maxWidth,
		 int x, int y,
		 ubyte r, ubyte g, ubyte b, ubyte a) {

		super(text, font, pretty, x, y, r, g, b, a);
	    setMaxWidth(maxWidth);
	}

	this(string text,
		 TTF_Font* font,
		 bool pretty,
		 int maxWidth,
		 int x, int y,
		 SDL_Color color) {

		const SDL_Color c = color;
		this(text, font, pretty, maxWidth, x, y, c.r, c.g, c.b, c.a);
	}

	/// To be called on width update
	abstract protected void updateWidth();

	override void updateText(string text) {
		super.updateText(text);
		updateWidth();
	}

	override void updateText() {
		this.updateText(currentText);
	}

	void setMaxWidth(int value) {
		maxWidth = value;
		updateWidth();
	}

	int getMaxWidth() {
		return maxWidth;
	}

}
