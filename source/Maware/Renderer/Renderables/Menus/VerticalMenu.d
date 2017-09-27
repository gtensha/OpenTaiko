import Renderable : Renderable;
import Font : Font;
import Button : Button;
import VerticalButton : VerticalButton;
import Text : Text;
import Menu : Menu;

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

		return buttons[buttons.length - 1];
	}

}
