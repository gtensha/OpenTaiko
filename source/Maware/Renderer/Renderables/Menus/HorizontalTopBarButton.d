import HorizontalTopBarMenu : HorizontalTopBarMenu;
import Button : Button;
import Solid : Solid;
import Text : Text;

import derelict.sdl2.sdl : SDL_Renderer;

class HorizontalTopBarButton : Button {

	private Solid bottomLine;

	this(SDL_Renderer* renderer,
		 Text text,
		 int value,
		 int x, int y, int w, int h,
		 ubyte r, ubyte g, ubyte b) {

		super(renderer,
			  text,
			  value,
			  x, y, 0, 0);

		this.solid = new Solid(renderer, w, h, x, y, r, g, b, 255);
		buttonText.setX(x + ((w / 2) - (text.width / 2)));
		buttonText.setY(y + (h / 2) - (text.height / 2) - 10);

		this.bottomLine = new Solid(renderer, w, h / 10, x, y + h - (h / 10),
									255, 255, 255, 255);
	}

	override public void render() {
		solid.render();
		buttonText.render();
		bottomLine.render();
	}

}
