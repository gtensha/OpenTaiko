module maware.renderable.menus.verticalmenu;

import maware.renderable.renderable;
import maware.renderable.solid;
import maware.renderable.menus.traversable;
import maware.font;
import maware.renderable.menus.button;
import maware.renderable.menus.verticalbutton;
import maware.renderable.text;
import maware.renderable.menus.menu;

import derelict.sdl2.sdl : SDL_Renderer, SDL_Color;

import std.math : ceil;

class VerticalMenu : Menu {

	enum UP_MARKER = "▲";
	enum DOWN_MARKER = "▼";
	enum BUTTON_SPACING = 20;
	enum SCROLLBAR_WIDTH = BUTTON_SPACING / 2;
	enum SCROLLBAR_ELM_SPACING = 5;

	protected int xOffset;
	protected int yOffset;
	protected const int buttonsPerPage;
	protected const int maxHeight;
	protected int currentPage;

	protected SDL_Color textColor;

	protected Solid upMarker;
	protected Solid scrollBar;
	protected Solid downMarker;

	this(string title,
		 Font font,
		 uint buttonWidth,
		 uint buttonHeight,
		 int xOffset,
		 int yOffset,
		 int maxHeight,
		 SDL_Color buttonColor,
		 SDL_Color textColor) {

		super(title,
			  font,
			  buttonWidth,
			  buttonHeight,
			  buttonColor.r, buttonColor.g, buttonColor.b, buttonColor.a);

		int barX = xOffset + buttonWidth + BUTTON_SPACING / 2;
		this.upMarker = new Text(UP_MARKER,
								 buttonFont.get(SCROLLBAR_WIDTH + 1),
								 true,
								 barX,
								 yOffset,
								 textColor);
		int barY = upMarker.rect.y + upMarker.rect.h + SCROLLBAR_ELM_SPACING;
		this.scrollBar = new Solid(SCROLLBAR_WIDTH,
								   0,
								   barX,
								   barY,
								   textColor);
		this.downMarker = new Text(DOWN_MARKER,
								   buttonFont.get(SCROLLBAR_WIDTH + 1),
								   true,
								   barX,
								   0,
								   textColor);
		this.downMarker.rect.y = yOffset + maxHeight - downMarker.rect.h;
		this.textColor = textColor;
		this.xOffset = xOffset;
		this.yOffset = yOffset;
		this.fontSize = 4 * (buttonHeight / 10);
		this.maxHeight = maxHeight;
		this.buttonsPerPage = cast(int)(maxHeight
										/ (buttonHeight + BUTTON_SPACING));
	}

	override public Button addButton(string title,
									 int value,
									 Traversable subMenu,
									 void delegate() instruction) {

		size_t btY = yOffset + buttons.length * (buttonHeight + BUTTON_SPACING);
		buttons ~= new VerticalButton(new Text(title,
											   buttonFont.get(fontSize),
											   true,
											   xOffset,
											   0,
											   textColor.r,
											   textColor.g,
											   textColor.b,
											   textColor.a),
									  value,
									  subMenu,
									  instruction,
									  xOffset,
									  cast(int)btY,
									  buttonWidth,
									  buttonHeight,
									  color.r, color.g, color.b, color.a);
		if (activeButton < 0) {
			activeButton = 0;
			buttons[activeButton].toggleHighlighted();
		}
		updateScrollBar();
		return buttons[buttons.length - 1];
	}

	private void updateScrollBar() {
		if (buttons.length > buttonsPerPage) {
			int pageAmount = cast(int)ceil((cast(double)buttons.length
											/ buttonsPerPage));
			scrollBar.rect.h = cast(int)((1.0 / pageAmount)
										 * (maxHeight
											- upMarker.rect.h
											- downMarker.rect.h
											- 2 * SCROLLBAR_ELM_SPACING));
			scrollBar.rect.y = (yOffset
								+ upMarker.rect.h
								+ SCROLLBAR_ELM_SPACING
								+ scrollBar.rect.h * (currentPage));
		} else {
			scrollBar.rect.h = 0;
		}
	}

	override public void render() {
		if (scrollBar.rect.h > 0) {
			upMarker.render();
			downMarker.render();
			scrollBar.render();
		}
		foreach (Button button ; buttons) {
			if (button.getY < yOffset) {
				continue;
			} else if (button.getY + buttonHeight + BUTTON_SPACING
					   >
					   yOffset + maxHeight) {
				break;
			} else {
				button.render();
			}
		}
	}

	override public void move(bool direction) {
		if (buttons.length < 1) {
			return;
		}
		int previousIndex = activeButton;
		super.move(direction);
		Button active = buttons[activeButton];
		int buttonY = active.getY;
		int moveAmount;
		if (previousIndex == 0 && activeButton > 1) { // move from top to bottom
			int indexToReach = activeButton;
		    super.move(Moves.RIGHT);
			while (activeButton < indexToReach) {
				move(Moves.RIGHT);
			}
			return;
		} else if (buttonY + buttonHeight + BUTTON_SPACING > yOffset + maxHeight) {
			moveAmount = 0 - (buttonY - yOffset);
			if (activeButton == 0) {
				currentPage = 0;
			} else {
				currentPage++;
			}
			updateScrollBar();
		} else if (buttonY < yOffset) {
			moveAmount = yOffset - buttons[activeButton // danger
										   - buttonsPerPage + 1].getY; // zone
			currentPage--;
			updateScrollBar();
		} else {
			return;
		}
		foreach (Button b ; buttons) {
			b.setY(b.getY + moveAmount);
		}
	}

}
