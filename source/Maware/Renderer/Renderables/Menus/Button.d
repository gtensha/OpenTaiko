import Menu : Menu;
import Renderable : Renderable;
import Text : Text;
import Solid : Solid;
import derelict.sdl2.sdl : SDL_Rect, SDL_Renderer;

class Button : Renderable {

	protected Text buttonText;
	protected Solid solid;
	protected SDL_Renderer* renderer;
	protected int value;

	this(SDL_Renderer* renderer,
		 Text text,
		 int value,
		 int x, int y, uint w, uint h) {

		this.renderer = renderer;
		this.buttonText = text;
		this.value = value;
		if (w > 0 && h > 0) {
			this.solid = new Solid(renderer, w, h, x, y, 125, 125, 125, 255);
		}
		if (text !is null) {
			buttonText.setX(x + 10);
			buttonText.setY(y);
		}

	}

	public void render() {
		solid.render();
		buttonText.render();
	}

	public void setX(int x) {
		solid.setX(x);
	}

	public void setY(int y) {
		solid.setY(y);
	}

	public int getValue() {
		return value;
	}

}
