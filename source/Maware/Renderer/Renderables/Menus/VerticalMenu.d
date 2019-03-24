module maware.renderable.menus.verticalmenu;

import maware.renderable.renderable;
import maware.renderable.solid;
import maware.renderable.menus.traversable;
import maware.font;
import maware.renderable.menus.button;
import maware.renderable.menus.verticalbutton;
import maware.renderable.text;
import maware.renderable.menus.menu;

import derelict.sdl2.sdl : SDL_Renderer, SDL_Color;

class VerticalMenu : Menu {

	enum UP_MARKER = "▲";
	enum DOWN_MARKER = "▼";
	enum BUTTON_SPACING = 20;

	protected int xOffset;
	protected int yOffset;
	protected const int buttonsPerPage;
	protected const int maxHeight;

	protected SDL_Color textColor;

	protected Solid scrollBar;

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
		buttons ~= new VerticalButton(new Text(title,
											   buttonFont.get(fontSize),
											   true,
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
		return buttons[buttons.length - 1];
	}

	override public void render() {
		foreach (Button button ; buttons) {
			if (button.getY < yOffset) {
				continue;
			} else if (button.getY + buttonHeight + BUTTON_SPACING / 2
					   >
					   yOffset + maxHeight) {
				break;
			} else {
				button.render();
			}
		}
	}

	override public void move(bool direction) {
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
		} else if (buttonY + buttonHeight > yOffset + maxHeight) {
			moveAmount = 0 - (buttonY - yOffset);
		} else if (buttonY < yOffset) {
			moveAmount = yOffset - buttons[activeButton
										   - buttonsPerPage].getY; // danger zone
		} else {
			return;
		}
		foreach (Button b ; buttons) {
			b.setY(b.getY + moveAmount);
		}
	}

}
