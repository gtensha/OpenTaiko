module opentaiko.browsablelist;

import maware.renderable;
import maware.font;

import opentaiko.game : OpenTaiko;

import derelict.sdl2.sdl : SDL_Color;

/// A class implementing a renderable list to present things like file
/// trees or player lists
class BrowsableList : Menu {
	
	enum PADDING = 10; /// Frame padding
	
	protected Solid frame;
	
	protected int listHeight;
	protected int x, y;
	
	this(Font font,
		 int itemWidth,
		 int itemHeight,
		 int listHeight,
		 int x, int y) {
		
		super("", font, itemWidth, itemHeight, 0, 0, 0, 0);
		this.buttonFont = font;
		this.listHeight = listHeight;
		this.x = x;
		this.y = y;
		this.frame = new Solid(itemWidth + 2 * PADDING,
							   2 * PADDING,
							   x, y,
							   0, 0, 0, 0);
							   
		this.frame.color = OpenTaiko.guiColors.uiColorMain;
		
	}
	
	override void render() {
		frame.render();
		super.render();
	}
	
	override Button addButton(string title,
							  int value,
							  Traversable subMenu,
							  void delegate() instruction) {
		
		buttons ~= new ListItem(title,
								buttonFont, 
								subMenu,
								instruction,
								buttonWidth, 
								buttonHeight, 
								x + PADDING,
								y + cast(int)buttons.length * buttonHeight + PADDING);
								
		frame.rect.h += buttonHeight;
								
		return buttons[buttons.length - 1];
	}
	
}

/// A list item for BrowseableList
class ListItem : Button {
	
	enum HIGHLIGHT_GRAD = 20;
	enum TEXT_REL_SIZE = 0.75;
	
	protected SDL_Color highlightedColor; 
	
	this(string text, 
		 Font font,
		 Traversable subMenu,
		 void delegate() instruction,
		 int w, 
		 int h, 
		 int x, 
		 int y) {
		
		super(null, -1, subMenu, instruction, x, y, w, h, 0, 0, 0, 0);
		solid.color = OpenTaiko.guiColors.uiColorMain;
		this.color = solid.color;
		
		int r = color.r + HIGHLIGHT_GRAD;
		int g = color.g + HIGHLIGHT_GRAD;
		int b = color.b + HIGHLIGHT_GRAD;
		
		highlightedColor.r = r > 0xff ? 0xff : cast(ubyte)r;
		highlightedColor.g = g > 0xff ? 0xff : cast(ubyte)g;
		highlightedColor.b = b > 0xff ? 0xff : cast(ubyte)b;
		highlightedColor.a = color.a;
		
		const SDL_Color c = OpenTaiko.guiColors.buttonTextColor;
		
		buttonText = new Text(text,
							  font.get(cast(int)(h * TEXT_REL_SIZE)),
							  true,
							  x, y,
							  c.r, c.g, c.b, c.a);
							  
		buttonText.rect.y = y + (solid.rect.h - buttonText.rect.h) / 2;
	}
	
	override void toggleHighlighted() {
		if (highlighted) {
			highlighted = false;
			solid.color = color;
		} else {
			highlighted = true;
			solid.color = highlightedColor;
		}
	}
	
}