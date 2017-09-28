module maware.renderable.menus.verticalmenu;

import maware.renderable.renderable;
import maware.font;
import maware.renderable.menus.button;
import maware.renderable.menus.verticalbutton;
import maware.renderable.text;
import maware.renderable.menus.menu;

import derelict.sdl2.sdl : SDL_Renderer;

class VerticalMenu : Menu {

	protected int xOffset;
	protected int yOffset;

	this(SDL_Renderer* renderer,
		 string title,
		 Font font,
		 uint buttonWidth,
		 uint buttonHeight,
		 int xOffset,
		 int yOffset,
		 ubyte r, ubyte g, ubyte b, ubyte a) {

		super(renderer,
			  title,
			  font,
			  buttonWidth,
			  buttonHeight,
			  r, g, b, a);

		this.xOffset = xOffset;
		this.yOffset = yOffset;
		this.fontSize = 4 * (buttonHeight / 10);
	}

	override public Button addButton(string title, int value, Menu subMenu, void delegate() instruction) {

		buttons ~= new VerticalButton(renderer,
							  		  new Text(renderer,
								  	   		   title,
									   		   buttonFont.get(fontSize),
									   		   true,
									   		   xOffset,
									   		   0,
									   		   255, 255, 255, 255),
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
