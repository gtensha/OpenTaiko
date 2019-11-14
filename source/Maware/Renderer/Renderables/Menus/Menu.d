//  This file is part of the OpenTaiko project.
//  <https://github.com/gtensha/OpenTaiko>
//
/// A generic vertically expanding menu with horizontal buttons.
///
/// Authors: gtensha (@skyhvelv.net)
/// Copyright: 2017-2019 gtensha
/// License: GNU GPLv3 (no later versions)
//
//  You should have received a copy of the GNU General Public License
//  along with OpenTaiko. If not, see <https://www.gnu.org/licenses/>.

module maware.renderable.menus.menu;

import maware.renderable.renderable;
import maware.renderable.menus.traversable;
import maware.font;
import maware.renderable.menus.button;
import maware.renderable.text;

import derelict.sdl2.sdl : SDL_Color, SDL_Renderer;

abstract class Menu : Traversable {

	protected SDL_Color color;
	protected uint buttonWidth;
	protected uint buttonHeight;
	protected uint fontSize;
	protected Font buttonFont;
	protected Button[] buttons;

	protected int activeButton = -1;

	this(string title,
		 Font font,
		 uint buttonWidth,
		 uint buttonHeight,
		 ubyte r, ubyte g, ubyte b, ubyte a) {

		color.r = r;
		color.g = g;
		color.b = b;
		color.a = a;

		this.buttonWidth = buttonWidth;
		this.buttonHeight = buttonHeight;
		this.fontSize = buttonHeight - 15;
		this.buttonFont = font;
	}

	public Button addButton(string title, int value, Traversable subMenu, void delegate() instruction) {

		buttons ~= new Button(new Text(title, buttonFont.get(fontSize), true, 0, 0, 255, 255, 255, 255),
							  value,
							  subMenu,
							  instruction,
							  (cast(int)buttons.length) * buttonWidth, 0, buttonWidth, buttonHeight,
							  color.r, color.g, color.b, color.a);

		if (activeButton < 0) {
			activeButton = 0;
			buttons[activeButton].toggleHighlighted();
		}
		return buttons[buttons.length - 1];
	}

	public Button addButton(string title, int value) {
		return addButton(title, value, null, null);
	}

	public void render() {
		foreach (Button button ; buttons) {
			button.render();
		}
	}

	public void move(bool direction) {
		if (activeButton >= 0) {
			buttons[activeButton].toggleHighlighted();
		}
		if (direction == Moves.RIGHT//DOWN
			&&
			activeButton <= cast(int)buttons.length - 1) {

			if (activeButton == cast(int)buttons.length - 1) {
				activeButton = 0;
			} else {
				activeButton++;
			}
		} else if (direction == Moves.LEFT//UP
				   &&
				   activeButton >= 0) {

			if (activeButton == 0) {
				activeButton = cast(int)buttons.length - 1;
			} else {
				activeButton--;
			}
		}
		if (activeButton >= 0 && buttons.length > 0) {
			buttons[activeButton].toggleHighlighted();
		}
	}

	public Traversable press() {
		return buttons[activeButton].getValue();
	}
	
	public int getActiveButtonId() {
		return buttons[activeButton].getId();
	}
	
	public string getActiveButtonTitle() {
		return buttons[activeButton].getTitle();
	}

	public uint getH() {
		return buttonHeight;
	}

	public uint getW() {
		return buttonWidth;
	}

}
