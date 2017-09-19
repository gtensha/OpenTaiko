import Menu : Menu;
import Font : Font;
import Button : Button;
import HorizontalTopBarButton : HorizontalTopBarButton;
import Text : Text;

import derelict.sdl2.sdl : SDL_Color, SDL_Renderer;

class HorizontalTopBarMenu : Menu {

	private SDL_Color color;
	private SDL_Color fontColor;

	this(SDL_Renderer* renderer,
		 string title,
		 Font font,
		 uint buttonWidth,
		 uint buttonHeight,
		 ubyte r, ubyte g, ubyte b, ubyte a) {

		super(renderer, title, font, buttonWidth, buttonHeight);
		this.fontSize = 3 * (buttonHeight / 8);
		color.r = r;
		color.g = g;
		color.b = b;
		color.a = a;
	}

	override public Button addButton(string title, int value) {
		buttons ~= new HorizontalTopBarButton(renderer,
							  new Text(renderer,
								  	   title,
									   buttonFont.get(fontSize),
									   true,
									   0, 0,
									   255, 255, 255, 255),
							  value,
							  (cast(int)buttons.length) * buttonWidth, 0, buttonWidth, buttonHeight,
							  color.r, color.g, color.b);
		return buttons[buttons.length - 1];
	}

}
