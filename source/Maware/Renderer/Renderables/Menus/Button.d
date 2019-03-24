module maware.renderable.menus.button;

import maware.renderable.menus.menu;
import maware.renderable.renderable;
import maware.renderable.menus.traversable;
import maware.renderable.text;
import maware.renderable.solid;
import maware.util.timer;

import derelict.sdl2.sdl : SDL_Color, SDL_Renderer;

class Button : Renderable {

	protected Text buttonText;
	protected string description;
	protected Solid solid;
	protected SDL_Renderer* renderer;
	protected SDL_Color color;
	protected int value;
	public void delegate() instruction;
	public Traversable subMenu;
	protected bool highlighted = false;

	// The percentage value of how transitioned the button is
	protected byte transitioned;
	protected bool transitionDirection; // true -> highlighting

	this(Text text,
		 int value,
		 Traversable subMenu,
		 void delegate() instruction,
		 int x, int y, uint w, uint h,
		 ubyte r, ubyte g, ubyte b, ubyte a) {

		this.renderer = renderer;
		this.buttonText = text;
		this.value = value;
		this.subMenu = subMenu;
		this.instruction = instruction;
		this.color.r = r;
		this.color.g = g;
		this.color.b = b;
		this.color.a = a;
		if (w > 0 && h > 0) {
			this.solid = new Solid(w, h, x, y, r, g, b, a);
		}
		if (text !is null) {
			buttonText.rect.x = x + 10;
			buttonText.rect.y = y;
		}

	}

	public void render() {
		solid.render();
		buttonText.render();
	}

	public void setX(int x) {
		int textOffset = buttonText.rect.x - solid.rect.x;
		solid.rect.x = x;
		buttonText.rect.x = x + textOffset;
	}

	public void setY(int y) {
		int textOffset = buttonText.rect.y - solid.rect.y;
		solid.rect.y = y;
		buttonText.rect.y = y + textOffset;
	}

	public int getX() {
		return solid.rect.x;
	}

	public int getY() {
		return solid.rect.y;
	}

	public Traversable getValue() {
		if (instruction !is null) {
			instruction();
		}
		return subMenu;
	}
	
	public int getId() {
		return value;
	}

	public void setDescription(string description) {
		this.description = description;
	}

	public string getDescription() {
		return description;
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
	
	public string getTitle() {
		return buttonText.getText();
	}
	
	public void setTitle(string title) {
		buttonText.updateText(title);
	}

}
