module opentaiko.renderable.inputbox;

import opentaiko.renderable.textinputfield;
import opentaiko.game;

import maware.renderable.renderable;
import maware.renderable.solid;
import maware.renderable.text;
import maware.font;

/// Renderable text input field with title text and background box
class InputBox : Renderable {
	
	Solid box;
	Solid inputArea;
	Text title;
	TextInputField inputField;
	
	this(string titleString,
		 Font font,
		 void delegate() commitCallback,
		 void delegate() cancelCallback,
		 string* destination,
		 int w, int h, int x, int y) {
		
		this.box = new Solid(w, h, x, y, OpenTaiko.guiColors.uiColorMain);
		this.title = new Text(titleString,
		                      font.get(h / 4),
							  true,
							  x + GUIDimensions.TEXT_SPACING,
							  y + GUIDimensions.TEXT_SPACING,
							  OpenTaiko.guiColors.buttonTextColor);
		
		this.inputArea = new Solid(w - (2 * GUIDimensions.TEXT_SPACING),
		                           h / 2 - 2 * GUIDimensions.TEXT_SPACING,
								   x + GUIDimensions.TEXT_SPACING,
								   y + GUIDimensions.TEXT_SPACING + h / 2,
								   OpenTaiko.guiColors.backgroundColor);
		
		this.inputField = new TextInputField(font,
		                                     commitCallback,
											 cancelCallback,
											 destination,
		                                     inputArea.rect.w,
											 inputArea.rect.h,
											 inputArea.rect.x,
											 inputArea.rect.y);
		
	}
	
	void render() {
		box.render();
		title.render();
		inputArea.render();
		inputField.render();
	}	
	
}
