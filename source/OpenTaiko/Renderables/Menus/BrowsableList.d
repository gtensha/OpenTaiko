//  This file is part of the OpenTaiko project.
//  <https://github.com/gtensha/OpenTaiko>
//
/// A compact menu for showing many different selectable options.
///
/// Authors: gtensha (@skyhvelv.net)
/// Copyright: 2018-2019 gtensha
/// License: GNU GPLv3 (no later versions)
//
//  You should have received a copy of the GNU General Public License
//  along with OpenTaiko. If not, see <https://www.gnu.org/licenses/>.

module opentaiko.renderable.menus.browsablelist;

import maware.renderable;
import maware.font;

import opentaiko.game : OpenTaiko;

import derelict.sdl2.sdl : SDL_Color;

import std.math : floor;

/// A class implementing a renderable list to present things like file
/// trees or player lists
class BrowsableList : Menu {
	
	enum PADDING = 10; /// Frame padding
	
	protected Solid frame;
	protected ScrollBar scrollBar;
	
	protected int listHeight;
	protected int x, y;
	private int buttonsPlaced;
	private int buttonsPerPage;
	
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
		this.buttonsPerPage = listHeight / itemHeight;
		const int scrollBarX = x + itemWidth + PADDING + PADDING / 2;
		const SDL_Color color = OpenTaiko.guiColors.buttonTextColor;
		this.scrollBar = new ScrollBar(font, listHeight, scrollBarX, y, color);
	}
	
	override void render() {
		frame.render();
		const int pageToRender = currentPage();
		int i = pageToRender * buttonsPerPage;
		int furthestButton = i + buttonsPerPage;
		for (;i < buttons.length && i < furthestButton;
			 i++) {

			buttons[i].render();
		}
		scrollBar.render();
	}
	
	override Button addButton(string title,
							  int value,
							  Traversable subMenu,
							  void delegate() instruction) {

		int buttonY = y + buttonsPlaced * buttonHeight + PADDING;
		if (buttonY - y + buttonHeight > listHeight) {
			buttonsPlaced = 1;
			buttonY = y + PADDING;
		} else {
			buttonsPlaced++;
		}
		buttons ~= new ListItem(title,
								buttonFont, 
								value,
								subMenu,
								instruction,
								buttonWidth, 
								buttonHeight, 
								x + PADDING,
								buttonY);

		if (buttons.length <= buttonsPerPage) {
			frame.rect.h += buttonHeight;
		} else if (buttons.length == buttonsPerPage + 1) {
			frame.rect.w += scrollBar.SCROLLBAR_WIDTH;
		}
		if (activeButton < 0) {
			activeButton = 0;
			buttons[activeButton].toggleHighlighted();
		}
		updateScrollBar();
		return buttons[buttons.length - 1];
	}

	override public void move(bool direction) {
		super.move(direction);
		updateScrollBar();
	}
	
	public int getX() {
		return x;
	}
	
	public int getY() {
		return y;
	}

	private void updateScrollBar() {
		scrollBar.update(currentPage,
						 buttonsPerPage,
						 cast(int)buttons.length);
	}

	private int currentPage() {
		return cast(int)floor(cast(double)activeButton / buttonsPerPage);
	}
	
}

/// A list item for BrowseableList
class ListItem : Button {
	
	enum HIGHLIGHT_GRAD = 20;
	enum TEXT_REL_SIZE = 0.75;
	
	protected SDL_Color highlightedColor; 
	
	this(string text, 
		 Font font,
		 int value,
		 Traversable subMenu,
		 void delegate() instruction,
		 int w, 
		 int h, 
		 int x, 
		 int y) {
		
		super(null, value, subMenu, instruction, x, y, w, h, 0, 0, 0, 0);
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
		
		buttonText = new EllipsedText(text,
									  font.get(cast(int)(h * TEXT_REL_SIZE)),
									  true,
									  w,
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
