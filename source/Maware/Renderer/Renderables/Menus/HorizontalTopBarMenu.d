module maware.renderable.menus.horizontaltopbarmenu;

import maware.renderable.menus.menu;
import maware.font;
import maware.renderable.menus.button;
import maware.renderable.menus.horizontaltopbarbutton;
import maware.renderable.text;

import derelict.sdl2.sdl : SDL_Color, SDL_Renderer;

class HorizontalTopBarMenu : Menu {

	private SDL_Color fontColor;

	this(SDL_Renderer* renderer,
		 string title,
		 Font font,
		 uint buttonWidth,
		 uint buttonHeight,
		 ubyte r, ubyte g, ubyte b, ubyte a) {

		super(renderer, title, font, buttonWidth, buttonHeight, r, g, b, a);
		this.fontSize = 3 * (buttonHeight / 8);
	}

	override public Button addButton(string title, int value, Menu subMenu, void delegate() instruction) {
		buttons ~= new HorizontalTopBarButton(renderer,
							  				  new Text(renderer,
								  	   				   title,
									   	   			   buttonFont.get(fontSize),
									   	   			   true,
									   	   			   0, 0,
									   	   			   255, 255, 255, 255),
							  				   value,
							  		   		   subMenu,
							  		   		   instruction,
							  		   		   (cast(int)buttons.length) * buttonWidth, 0, buttonWidth, buttonHeight,
							  		   		   color.r, color.g, color.b, color.a);
		return buttons[buttons.length - 1];
	}

	override public Button addButton(string title, int value) {
		return addButton(title, value, null, null);
	}

}
