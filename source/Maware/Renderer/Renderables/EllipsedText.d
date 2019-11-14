//  This file is part of the OpenTaiko project.
//  <https://github.com/gtensha/OpenTaiko>
//
/// Text that renders ellipsed when it exceeds its width limit.
///
/// Authors: gtensha (@skyhvelv.net)
/// Copyright: 2018-2019 gtensha
/// License: GNU GPLv3 (no later versions)
//
//  You should have received a copy of the GNU General Public License
//  along with OpenTaiko. If not, see <https://www.gnu.org/licenses/>.

module maware.renderable.ellipsedtext;

import maware.renderable.boundedtext;

import derelict.sdl2.sdl : SDL_Color;
import derelict.sdl2.ttf : TTF_Font;

import std.algorithm.comparison : equal;

/// A class similar to Text but with a width boundary
class EllipsedText : BoundedText {

	private bool shrinking;
	private string originalText;
	
	this(string text,
	     TTF_Font* font,
	     bool pretty,
	     int maxWidth,
	     int x, int y,
	     ubyte r, ubyte g, ubyte b, ubyte a) {

		originalText = text;
		super(text, font, pretty, maxWidth, x, y, r, g, b, a);
		this.updateText();
	}
	
	this(string text,
	     TTF_Font* font,
	     bool pretty,
	     int maxWidth,
	     int x, int y,
	     SDL_Color color) {

		this(text, font, pretty, maxWidth, x, y, color.r, color.g, color.b, color.a);
	}

	/// Make a new text until it is no wider than maxWidth
	override protected void updateWidth() {
		if (shrinking) {
			return;
		}
		string text = originalText;
		shrinking = true;
		while (rect.w > getMaxWidth() && text.length > 1) {
			text = text[0 .. text.length - 2];
			super.updateText(text ~ "...");
		}
		shrinking = false;
	}

	override public void updateText(string text) {
		originalText = text;
		super.updateText(text);
	}

	override public void updateText() {
		updateText(originalText);
	}

}
