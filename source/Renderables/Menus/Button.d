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

	}

	public void render() {

	}

	public int getValue() {
		return value;
	}

}
