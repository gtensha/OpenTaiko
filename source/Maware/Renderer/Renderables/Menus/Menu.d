import Renderable : Renderable;
import Font : Font;
import Button : Button;
import Text : Text;

import derelict.sdl2.sdl : SDL_Color, SDL_Renderer;

class Menu : Renderable {

	enum Moves : bool {
		RIGHT = true,
		LEFT = false,
		UP = false,
		DOWN = true
	};

	protected SDL_Renderer* renderer;
	protected SDL_Color color;
	protected uint buttonWidth;
	protected uint buttonHeight;
	protected uint fontSize;
	protected Font buttonFont;
	protected Button[] buttons;

	protected int activeButton = -1;

	this(SDL_Renderer* renderer,
		 string title,
		 Font font,
		 uint buttonWidth,
		 uint buttonHeight,
		 ubyte r, ubyte g, ubyte b, ubyte a) {

		color.r = r;
		color.g = g;
		color.b = b;
		color.a = a;

		this.renderer = renderer;
		this.buttonWidth = buttonWidth;
		this.buttonHeight = buttonHeight;
		this.fontSize = buttonHeight - 15;
		this.buttonFont = font;
	}

	public Button addButton(string title, int value, void delegate() instruction) {
		buttons ~= new Button(this.renderer,
							  new Text(renderer, title, buttonFont.get(fontSize), true, 0, 0, 255, 255, 255, 255),
							  value,
							  instruction,
							  (cast(int)buttons.length) * buttonWidth, 0, buttonWidth, buttonHeight,
							  color.r, color.g, color.b, color.a);

		return buttons[buttons.length - 1];
	}

	public Button addButton(string title, int value) {
		return addButton(title, value, null);
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
			activeButton < cast(int)buttons.length - 1) {

			activeButton++;
		} else if (direction == Moves.LEFT//UP
				   &&
				   activeButton > 0) {

			activeButton--;
		}
		if (activeButton >= 0) {
			buttons[activeButton].toggleHighlighted();
		}
	}

	public int press() {
		return buttons[activeButton].getValue();
	}

}
