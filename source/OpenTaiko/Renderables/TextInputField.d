module opentaiko.textinputfield;

import maware.inputhandler : TextInputBinder;
import maware.renderable.renderable;
import maware.font;
import maware.renderable.text;
import maware.renderable.solid;
import opentaiko.game;
import derelict.sdl2.sdl : SDL_Rect;

import std.stdio;

/// Class representing a text input field to write into
class TextInputField : Renderable {
	
	enum CURSOR = '_';
	
	protected Font font;
	protected Text currentText;
	protected Solid fieldBackground;
	
	protected void delegate() commitCallback;
	
	protected TextInputBinder bindings;
	
	protected string previousText;
	
	/// Create a new text input field with given dimensions and font
	this(Font font,
		 void delegate() commitCallback,
		 int w, int h, int x, int y) {
			 
		this.font = font;
		this.currentText = new Text(" ",
									font.get(h),
									true,
									x, y,
									0, 0, 0, 0);
									
		this.fieldBackground = new Solid(w, h, x, y, 0, 0, 0, 0);
		this.fieldBackground.color = OpenTaiko.guiColors.uiColorMain;
		currentText.rect.y = y - (currentText.rect.h - fieldBackground.rect.h) / 2;
		
		this.currentText.color = OpenTaiko.guiColors.buttonTextColor;
									
		this.bindings.giveText = &giveText;
		this.bindings.eraseCharacter = &eraseCharacter;
		this.bindings.moveCursor = &moveCursor;
		this.bindings.inputField = &fieldBackground.rect;
		this.bindings.commit = &deactivate;
		
		this.commitCallback = commitCallback;
	}
	
	/// Give a character and handle
	void giveText(string text) {
		string oldText = currentText.getText();
		currentText.updateText(oldText[0 .. oldText.length - 1] ~ text ~ CURSOR);
	}
	
	/// Erase the last character if any exist
	void eraseCharacter() {
		string oldText = currentText.getText();
		if (oldText.length > 1) {
			currentText.updateText(oldText[0 .. oldText.length - 2] ~ CURSOR);
		}
	}
	
	/// Sets the cursor position
	void moveCursor(bool direction) {
		
	}
	
	/// Activates the input window
	void activate() {
		currentText.updateText(CURSOR ~ "");
	}
	
	void deactivate() {
		previousText = currentText.getText();
		currentText.updateText("");
		if (commitCallback !is null) {
			commitCallback();
		}
	}
	
	string getCurrentText() {
		return currentText.getText();
	}
	
	string getPreviousText() {
		return previousText;
	}
	
	TextInputBinder* getBindings() {
		return &bindings;
	}
	
	void render() {
		//fieldBackground.render();
		currentText.render();
	}
	
}