import Menu : Menu;
import Renderable : Renderable;
import Text : Text;
import Solid : Solid;
import Timer : Timer;
import derelict.sdl2.sdl : SDL_Color, SDL_Renderer;

class Button : Renderable {

	protected Text buttonText;
	protected Solid solid;
	protected SDL_Renderer* renderer;
	protected SDL_Color color;
	protected int value;
	protected bool highlighted = false;

	// The percentage value of how transitioned the button is
	protected byte transitioned;
	protected bool transitionDirection; // true -> highlighting

	this(SDL_Renderer* renderer,
		 Text text,
		 int value,
		 int x, int y, uint w, uint h,
		 ubyte r, ubyte g, ubyte b, ubyte a) {

		this.renderer = renderer;
		this.buttonText = text;
		this.value = value;
		this.color.r = r;
		this.color.g = g;
		this.color.b = b;
		this.color.a = a;
		if (w > 0 && h > 0) {
			this.solid = new Solid(renderer, w, h, x, y, r, g, b, a);
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

	public void toggleHighlighted() {
		if (highlighted) {
			highlighted = false;
			solid.setColor(color.r, color.g, color.b, -1);
		} else {
			highlighted = true;
			solid.setColor(255, 255, 255, -1);
		}
	}

}
