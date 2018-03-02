module maware.renderable.menus.verticalmenu;

import maware.renderable.renderable;
import maware.renderable.menus.traversable;
import maware.font;
import maware.renderable.menus.button;
import maware.renderable.menus.verticalbutton;
import maware.renderable.text;
import maware.renderable.menus.menu;

import derelict.sdl2.sdl : SDL_Renderer, SDL_Color;

class VerticalMenu : Menu {

	protected int xOffset;
	protected int yOffset;
	
	protected SDL_Color textColor;

	this(string title,
		 Font font,
		 uint buttonWidth,
		 uint buttonHeight,
		 int xOffset,
		 int yOffset,
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
	}

	override public Button addButton(string title, int value, Traversable subMenu, void delegate() instruction) {

		buttons ~= new VerticalButton(new Text(title,
											   buttonFont.get(fontSize),
											   true,
											   xOffset,
											   0,
											   textColor.r, textColor.g, textColor.b, textColor.a),
									  value,
									  subMenu,
									  instruction,
									  xOffset,
									  yOffset + (cast(int)buttons.length * (buttonHeight + 20)),
									  buttonWidth,
									  buttonHeight,
									  color.r, color.g, color.b, color.a);

		if (activeButton < 0) {
			activeButton = 0;
			buttons[activeButton].toggleHighlighted();
		}
		return buttons[buttons.length - 1];
	}

}
