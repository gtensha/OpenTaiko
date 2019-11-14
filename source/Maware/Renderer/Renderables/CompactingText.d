//  This file is part of the OpenTaiko project.
//  <https://github.com/gtensha/OpenTaiko>
//
/// Text that renders compacted (and ugly) when it exceeds its width limit.
///
/// Authors: gtensha (@skyhvelv.net)
/// Copyright: 2019 gtensha
/// License: GNU GPLv3 (no later versions)
//
//  You should have received a copy of the GNU General Public License
//  along with OpenTaiko. If not, see <https://www.gnu.org/licenses/>.

module maware.renderable.compactingtext;

import maware.renderable.boundedtext;

import derelict.sdl2.sdl : SDL_QueryTexture, SDL_Color;
import derelict.sdl2.ttf : TTF_Font;

/// Simple variant of Text that accepts an extra parameter; max length. If the
/// length of the text exceeds the max length, then it will be rendered
/// "compacted." It is ugly, but makes things possible to read at smaller
/// resolutions and therefore shouldn't be used for text that normally exceeds
/// its supposed bounds.
class CompactingText : BoundedText {

	this(string text,
		 TTF_Font* font,
		 bool pretty,
		 int maxWidth,
		 int x, int y,
		 ubyte r, ubyte g, ubyte b, ubyte a) {

		super(text, font, pretty, maxWidth, x, y, r, g, b, a);
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

	/// Checks the length of the text texture, and sets the rect width to
	/// maxWidth if it is longer than maxWidth, else sets it to normal width.
	override protected void updateWidth() {
		int w;
		SDL_QueryTexture(texture, null, null, &w, null);
		if (w > getMaxWidth()) {
			rect.w = getMaxWidth();
		} else {
			rect.w = w;
		}
	}

	// TODO: renderPart()

}
