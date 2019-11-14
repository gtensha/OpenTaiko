//  This file is part of the OpenTaiko project.
//  <https://github.com/gtensha/OpenTaiko>
//
/// Ready to use vertical button for generic menus.
///
/// Authors: gtensha (@skyhvelv.net)
/// Copyright: 2017-2019 gtensha
/// License: GNU GPLv3 (no later versions)
//
//  You should have received a copy of the GNU General Public License
//  along with OpenTaiko. If not, see <https://www.gnu.org/licenses/>.

module maware.renderable.menus.verticalbutton;

import maware.renderable.compactingtext;
import maware.renderable.menus.button;
import maware.renderable.menus.traversable;
import maware.renderable.solid;
import maware.renderable.text;
import maware.renderable.menus.menu;
import maware.util.timer;
import maware.util.math.ezmath;

import std.conv : to;

import derelict.sdl2.sdl : SDL_Renderer, SDL_Rect;

class VerticalButton : Button {

	private Solid highlightLayer;
	private Text invertedText;
	private Timer timer;
	private bool highlighting = false;
	private uint animationDuration = 1000;

	this(Text text,
		 int value,
		 Traversable subMenu,
		 void delegate() instruction,
		 int x, int y, uint w, uint h,
		 ubyte r, ubyte g, ubyte b, ubyte a) {

		super(text, value, subMenu, instruction, x, y, w, h, r, g, b, a);

		buttonText.rect.y = (this.solid.rect.h - text.rect.h) / 2 + y;

		highlightLayer = new Solid(0, h, x, y, 
								   text.color.r, 
								   text.color.g, 
								   text.color.b, 
								   text.color.a);

		CompactingText t = cast(CompactingText)text;
		invertedText = new CompactingText(buttonText.getText,
										  buttonText.getFont,
										  true,
										  t.getMaxWidth,
										  buttonText.rect.x,
										  buttonText.rect.y,
										  r, g, b, a);

		invertedText.setColor(r, g, b, a);

		int timerIndex = Timer.addTimer();
		timer = Timer.timers[timerIndex];
	}

	override public void render() {

		double x = timer.getPercentagePassed();
		if (x < 1) {
			x = 1;
		}
		double percentagePassed = (101 - (1 / (0.01 * x)));

		if (percentagePassed > 100) {
			percentagePassed = 100;
		}
		if (highlighting) {
			highlightLayer.rect.w = cast(int)(EzMath.getCoords(percentagePassed, 0, solid.rect.w));
		} else {
			highlightLayer.rect.w = cast(int)(EzMath.getCoords(percentagePassed, solid.rect.w, 0));
		}

		solid.render();
		buttonText.render();
		highlightLayer.render();
		SDL_Rect textPortion = Solid.getUnion(&invertedText.rect, &highlightLayer.rect);
		if (textPortion.w <= 0) {
			invertedText.render();
		} else {
			textPortion.h = 0;
			invertedText.renderPart(textPortion);
		}
	}

	override public void toggleHighlighted() {
		if (highlighting == 1) {
			highlighting = 0;
		} else {
			highlighting = 1;
		}

		timer.set(Timer.libInitPassed, Timer.libInitPassed + animationDuration);
	}
	
	override void setTitle(string title) {
		super.setTitle(title);
		invertedText.updateText(title);
	}

	override public void setX(int x) {
		super.setX(x);
		highlightLayer.rect.x = x;
		invertedText.rect.x = buttonText.rect.x;
	}

	override public void setY(int y) {
		super.setY(y);
		highlightLayer.rect.y = y;
		invertedText.rect.y = buttonText.rect.y;
	}

}
