import Renderable : Renderable;
import Font : Font;
import Button : Button;
import Text : Text;

import derelict.sdl2.sdl : SDL_Renderer;

class Menu : Renderable {

	private SDL_Renderer* renderer;
	private uint buttonWidth;
	private uint buttonHeight;
	private uint fontSize;
	private Font buttonFont;
	private Button[] buttons;

	this(SDL_Renderer* renderer,
		 string title,
		 Font font,
		 uint buttonWidth,
		 uint buttonHeight) {

		this.renderer = renderer;
		this.buttonWidth = buttonWidth;
		this.buttonHeight = buttonHeight;
		this.fontSize = buttonHeight;
		this.buttonFont = font;
	}

	public Button addButton(string title, int value) {
		buttons ~= new Button(this.renderer,
							  new Text(renderer, title, buttonFont.get(fontSize), true, 0, 0, 255, 255, 255, 255),
							  value,
							  cast(int)buttons.length * buttonWidth, 0, buttonWidth, buttonHeight);
		return buttons[buttons.length - 1];
	}

	public void render() {
		foreach (Button button ; buttons) {
			button.render();
		}
	}

}
