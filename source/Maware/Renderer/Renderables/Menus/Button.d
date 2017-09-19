import Menu : Menu;
import Renderable : Renderable;
import Text : Text;
import Solid : Solid;
import derelict.sdl2.sdl : SDL_Rect, SDL_Renderer;

class Button : Renderable {

	private Text buttonText;
	private Solid solid;
	private SDL_Renderer* renderer;
	private int value;

	this(SDL_Renderer* renderer,
		 Text text,
		 int value,
		 int x, int y, uint w, uint h) {

		this.renderer = renderer;
		this.buttonText = text;
		this.value = value;
		this.solid = new Solid(renderer, x, y, w, h, 255, 255, 255, 255);

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
