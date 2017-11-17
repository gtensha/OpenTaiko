module maware.renderable.menus.verticalbutton;

import maware.renderable.menus.button;
import maware.renderable.solid;
import maware.renderable.text;
import maware.renderable.menus.menu;
import maware.util.math.polynomialfunction;
import maware.util.timer;
import maware.util.math.ezmath;

import std.conv : to;

import derelict.sdl2.sdl : SDL_Renderer, SDL_Rect;

class VerticalButton : Button {

	private Solid highlightLayer;
	private Text invertedText;
	private Timer timer;
	private PolynomialFunction!double buttonAnimation;
	private bool highlighting = false;
	private uint animationDuration = 800;

	this(SDL_Renderer* renderer,
		 Text text,
		 int value,
		 Menu subMenu,
		 void delegate() instruction,
		 int x, int y, uint w, uint h,
		 ubyte r, ubyte g, ubyte b, ubyte a) {

		super(renderer, text, value, subMenu, instruction, x, y, w, h, r, g, b, a);

		buttonText.setY(y + (h / 2) - (text.height / 2) - 10);

		highlightLayer = new Solid(renderer, 0, h, x, y, 255, 255, 255, 255);

		invertedText = new Text(renderer,
								buttonText.getText,
								buttonText.getFont,
								true,
								buttonText.getX,
								buttonText.getY,
								r, g, b, a);

		invertedText.setColor(r, g, b, a);

		buttonAnimation = new PolynomialFunction!double(0.01, -0.00015, 0);
		int timerIndex = Timer.addTimer();
		timer = Timer.timers[timerIndex];
	}

	override public void render() {

		int percentagePassed = timer.getPercentagePassed();
		if (percentagePassed > 100) {
			percentagePassed = 100;
		} else {
			//percentagePassed = to!int(buttonAnimation.getY(percentagePassed));
		}
		if (highlighting) {
			highlightLayer.setW(EzMath.getCoords(percentagePassed, 0, solid.width));
		} else {
			highlightLayer.setW(EzMath.getCoords(percentagePassed, solid.width, 0));
		}

		solid.render();
		buttonText.render();
		highlightLayer.render();
		SDL_Rect textPortion = Solid.getUnion(invertedText.getRect, highlightLayer.getRect);
		if (textPortion.w <= 0) {
			invertedText.render();
		} else {
			textPortion.h = 0;
			invertedText.renderPart(textPortion);
		}
	}

	override public void toggleHighlighted() {
		if (highlighting == 1) {
			highlighting = 0;
		} else {
			highlighting = 1;
		}

		timer.set(Timer.libInitPassed, Timer.libInitPassed + animationDuration);
	}

}
