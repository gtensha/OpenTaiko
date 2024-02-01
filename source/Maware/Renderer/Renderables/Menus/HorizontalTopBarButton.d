//  This file is part of the OpenTaiko project.
//  <https://github.com/gtensha/OpenTaiko>
//
/// Button object for the HorizontalTopBarMenu.
///
/// Authors: gtensha (@skyhvelv.net)
/// Copyright: 2017-2018 gtensha
/// License: GNU GPLv3 (no later versions)
//
//  You should have received a copy of the GNU General Public License
//  along with OpenTaiko. If not, see <https://www.gnu.org/licenses/>.

module maware.renderable.menus.horizontaltopbarbutton;

import maware.renderable.menus.horizontaltopbarmenu;
import maware.renderable.menus.button;
import maware.renderable.menus.traversable;
import maware.renderable.solid;
import maware.renderable.text;
import maware.renderable.menus.menu;
import maware.util.math.polynomialfunction;
import maware.util.timer;
import maware.util.math.ezmath;

import std.conv : to;
import std.math : sin, cos, PI;

import bindbc.sdl : SDL_Renderer, SDL_Rect, SDL_UnionRect, SDL_Color;

class HorizontalTopBarButton : Button {

	private uint timerIndex;
	private Timer timer;
	private Solid bottomLine;
	private Text invertedText;
	private byte highlighting = 0; // 1 = up, 0 = down
	private const int animationDuration = 1400;

	this(Text text,
		 int value,
		 Traversable subMenu,
		 void delegate() instruction,
		 int x, int y, int w, int h,
		 SDL_Color buttonColor,
		 SDL_Color complementColor) {

		super(text,
			  value,
			  subMenu,
			  instruction,
			  x, y, w, h,
			  buttonColor.r, 
			  buttonColor.g, 
			  buttonColor.b, 
			  buttonColor.a);

		buttonText.rect.x = (x + ((w / 2) - (text.rect.w / 2)));
		buttonText.rect.y = (y + (h / 2) - (text.rect.h / 2) - 10);

		this.bottomLine = new Solid(w, h / 10, x, y + h - (h / 10),
									complementColor.r, 
									complementColor.g, 
									complementColor.b, 
									complementColor.a);

		timerIndex = Timer.addTimer();
		timer = Timer.timers[timerIndex];
	}

	override public void render() {

		double x = timer.getPercentagePassed();
		double percentagePassed;
		if (x <= 100) {
			if (x <= 60) {
				percentagePassed = 100 * sin(x / (120 / PI) - PI / 2) + 100;
			} else {
				percentagePassed = 10 * cos(x / (40 / PI) - PI) + 100;
			}
		} else {
			percentagePassed = 100;
		}

		if (highlighting == 1) {
			bottomLine.rect.h = (EzMath.getCoords(percentagePassed, 
												  8, 
												  solid.rect.h));
			bottomLine.rect.y = (EzMath.getCoords(percentagePassed, 
												  solid.rect.y 
												  + solid.rect.h 
												  - (solid.rect.h / 10),
												  solid.rect.y));
		} else {
			bottomLine.rect.h = (EzMath.getCoords(percentagePassed, 
												  solid.rect.h, 
												  8));
			bottomLine.rect.y = (EzMath.getCoords(percentagePassed, 
												  solid.rect.y, 
												  solid.rect.y 
												  + solid.rect.h 
												  - (solid.rect.h / 10)));
		}

		solid.render();
		bottomLine.render();
		buttonText.render();
		//invertedText.render();

		/*SDL_Rect textPortion = {0,
								buttonText.rect.y + 10,
								0,
								buttonText.rect.y 
								- (bottomLine.rect.y - bottomLine.rect.h)};
		if (textPortion.h <= 0) {
			buttonText.render();
		} else {
			textPortion.w = 0;
			textPortion.y = invertedText.rect.y - textPortion.h;
			//textPortion.y = invertedText.getY + invertedText.height;

			buttonText.renderPart(textPortion);
		}*/
	}

	override public void toggleHighlighted() {
		if (highlighting == 1) {
			highlighting = 0;
		} else {
			highlighting = 1;
		}

		timer.set(Timer.libInitPassed, Timer.libInitPassed + animationDuration);
	}

}
