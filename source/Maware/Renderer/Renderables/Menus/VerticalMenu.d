//  This file is part of the OpenTaiko project.
//  <https://github.com/gtensha/OpenTaiko>
//
/// Ready to use vertical menu for generic game menus.
///
/// Authors: gtensha (@skyhvelv.net)
/// Copyright: 2017-2019 gtensha
/// License: GNU GPLv3 (no later versions)
//
//  You should have received a copy of the GNU General Public License
//  along with OpenTaiko. If not, see <https://www.gnu.org/licenses/>.

module maware.renderable.menus.verticalmenu;

import maware.renderable.renderable;
import maware.renderable.compactingtext;
import maware.renderable.solid;
import maware.renderable.menus.traversable;
import maware.font;
import maware.renderable.menus.button;
import maware.renderable.menus.verticalbutton;
import maware.renderable.text;
import maware.renderable.menus.menu;
import maware.renderable.menus.scrollbar;

import bindbc.sdl : SDL_Renderer, SDL_Color;

import std.math : ceil;

class VerticalMenu : Menu {

	enum BUTTON_SPACING = 20;

	protected int xOffset;
	protected int yOffset;
	protected const int buttonsPerPage;
	protected const int maxHeight;
	protected int currentPage;

	protected SDL_Color textColor;

	protected ScrollBar scrollBar;

	this(string title,
		 Font font,
		 uint buttonWidth,
		 uint buttonHeight,
		 int xOffset,
		 int yOffset,
		 int maxHeight,
		 SDL_Color buttonColor,
		 SDL_Color textColor) {

		super(title,
			  font,
			  buttonWidth,
			  buttonHeight,
			  buttonColor.r, buttonColor.g, buttonColor.b, buttonColor.a);

		int barX = xOffset + buttonWidth + BUTTON_SPACING / 2;
		int barY = yOffset;
		this.scrollBar = new ScrollBar(font,
									   maxHeight,
									   barX,
									   barY,
									   textColor);
		this.textColor = textColor;
		this.xOffset = xOffset;
		this.yOffset = yOffset;
		this.fontSize = 4 * (buttonHeight / 10);
		this.maxHeight = maxHeight;
		this.buttonsPerPage = cast(int)(maxHeight
										/ (buttonHeight + BUTTON_SPACING));
	}

	override public Button addButton(string title,
									 int value,
									 Traversable subMenu,
									 void delegate() instruction) {

		size_t btY = yOffset + buttons.length * (buttonHeight + BUTTON_SPACING);
		buttons ~= new VerticalButton(new CompactingText(title,
														 buttonFont.get(fontSize),
														 true,
														 buttonWidth - BUTTON_SPACING,
														 xOffset,
														 0,
														 textColor.r,
														 textColor.g,
														 textColor.b,
														 textColor.a),
									  value,
									  subMenu,
									  instruction,
									  xOffset,
									  cast(int)btY,
									  buttonWidth,
									  buttonHeight,
									  color.r, color.g, color.b, color.a);
		if (activeButton < 0) {
			activeButton = 0;
			buttons[activeButton].toggleHighlighted();
		}
		updateScrollBar();
		return buttons[buttons.length - 1];
	}

	private void updateScrollBar() {
	    scrollBar.update(currentPage,
						 buttonsPerPage,
						 cast(int)buttons.length);
	}

	override public void render() {
	    scrollBar.render();
		foreach (Button button ; buttons) {
			if (button.getY < yOffset) {
				continue;
			} else if (button.getY + buttonHeight + BUTTON_SPACING
					   >
					   yOffset + maxHeight) {
				break;
			} else {
				button.render();
			}
		}
	}

	override public void move(bool direction) {
		if (buttons.length < 1) {
			return;
		}
		int previousIndex = activeButton;
		super.move(direction);
		Button active = buttons[activeButton];
		int buttonY = active.getY;
		int moveAmount;
		if (previousIndex == 0 && activeButton > 1) { // move from top to bottom
			int indexToReach = activeButton;
		    super.move(Moves.RIGHT);
			while (activeButton < indexToReach) {
				move(Moves.RIGHT);
			}
			return;
		} else if (buttonY + buttonHeight + BUTTON_SPACING
				   > yOffset + maxHeight) {

			moveAmount = 0 - (buttonY - yOffset);
			if (activeButton == 0) {
				currentPage = 0;
			} else {
				currentPage++;
			}
			updateScrollBar();
		} else if (buttonY < yOffset) {
			if (activeButton == 0) {
				moveAmount = 0 - (buttonY - yOffset);
				currentPage = 0;
			} else {
				moveAmount = yOffset - buttons[activeButton // danger
											   - buttonsPerPage + 1].getY;// zone
				currentPage--;
			}
			updateScrollBar();
		} else {
			return;
		}
		foreach (Button b ; buttons) {
			b.setY(b.getY + moveAmount);
		}
	}

}
