import Button : Button;
import Solid : Solid;
import Text : Text;
import PolynomialFunction : PolynomialFunction;
import Timer : Timer;
import EzMath : EzMath;

import std.conv : to;

import derelict.sdl2.sdl : SDL_Renderer;

class VerticalButton : Button {

	private Solid highlightLayer;
	private Timer timer;
	private PolynomialFunction!double buttonAnimation;
	private bool highlighting = false;
	private uint animationDuration = 800;

	this(SDL_Renderer* renderer,
		 Text text,
		 int value,
		 void delegate() instruction,
		 int x, int y, uint w, uint h,
		 ubyte r, ubyte g, ubyte b, ubyte a) {

		super(renderer, text, value, instruction, x, y, w, h, r ,g, b, a);

		buttonText.setY(y + (h / 2) - (text.height / 2) - 10);

		highlightLayer = new Solid(renderer, 0, h, x, y, 255, 255, 255, 255);

		buttonAnimation = new PolynomialFunction!double(-0.0002, 0.0307, -0.037, 0);
		int timerIndex = Timer.addTimer();
		timer = Timer.timers[timerIndex];
	}

	override public void render() {

		int percentagePassed = timer.getPercentagePassed();
		if (percentagePassed > 100) {
			percentagePassed = 100;
		}
		if (highlighting) {
			highlightLayer.setW(EzMath.getCoords(to!int(buttonAnimation.getY(percentagePassed)), 0, solid.width));
		} else {
			highlightLayer.setW(EzMath.getCoords(to!int(buttonAnimation.getY(percentagePassed)), solid.width, 0));
		}

		solid.render();
		highlightLayer.render();
		buttonText.render();
	}

	override public void toggleHighlighted() {
		if (highlighting == 1) {
			highlighting = 0;
			buttonText.setColor(255, 255, 255, -1);
			buttonText.updateText();
		} else {
			highlighting = 1;
			buttonText.setColor(color.r, color.g, color.b, -1);
			buttonText.updateText();
		}

		timer.set(Timer.libInitPassed, Timer.libInitPassed + animationDuration);
	}

}
