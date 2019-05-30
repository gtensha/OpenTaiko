module maware.renderable.menus.horizontaltopbarmenu;

import maware.renderable.menus.menu;
import maware.renderable.menus.traversable;
import maware.font;
import maware.renderable.menus.button;
import maware.renderable.menus.horizontaltopbarbutton;
import maware.renderable.text;

import derelict.sdl2.sdl : SDL_Color, SDL_Renderer;

class HorizontalTopBarMenu : Menu {

	private SDL_Color fontColor;
	private SDL_Color complementColor;

	this(string title,
		 Font font,
		 uint buttonWidth,
		 uint buttonHeight,
		 SDL_Color buttonColor,
		 SDL_Color fontColor,
		 SDL_Color complementColor) {

		super(title, font, buttonWidth, buttonHeight, 
			  buttonColor.r, buttonColor.g, buttonColor.b, buttonColor.a);
		this.fontSize = 3 * (buttonHeight / 8);
		this.complementColor = complementColor;
		this.fontColor = fontColor;
	}

	override public Button addButton(string title, int value, Traversable subMenu, void delegate() instruction) {

		buttons ~= new HorizontalTopBarButton(new Text(title,
									   	   			   buttonFont.get(fontSize),
									   	   			   true,
									   	   			   0, 0,
									   	   			   fontColor.r, 
													   fontColor.g, 
													   fontColor.b, 
													   fontColor.a),
							  				   value,
							  		   		   subMenu,
							  		   		   instruction,
							  		   		   (cast(int)buttons.length) * buttonWidth, 0, buttonWidth, buttonHeight,
							  		   		   color,
											   complementColor);

		if (activeButton < 0) {
			activeButton = 0;
			buttons[activeButton].toggleHighlighted();
		}
		return buttons[buttons.length - 1];
	}

	override public Button addButton(string title, int value) {
		return addButton(title, value, null, null);
	}

	override public uint getW() {
	    return buttonWidth * cast(uint)buttons.length;
	}

}
