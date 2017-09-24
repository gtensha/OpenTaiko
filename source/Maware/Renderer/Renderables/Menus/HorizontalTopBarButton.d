import HorizontalTopBarMenu : HorizontalTopBarMenu;
import Button : Button;
import Solid : Solid;
import Text : Text;
import PolynomialFunction : PolynomialFunction;
import Timer : Timer;
import EzMath : EzMath;

import std.conv : to;

import derelict.sdl2.sdl : SDL_Renderer;

class HorizontalTopBarButton : Button {

	private uint timerIndex;
	private Timer timer;
	private Solid bottomLine;
	private PolynomialFunction!double buttonAnimation;
	private byte highlighting = 0; // 1 = up, 0 = down
	private const int animationDuration = 800;

	this(SDL_Renderer* renderer,
		 Text text,
		 int value,
		 void delegate() instruction,
		 int x, int y, int w, int h,
		 ubyte r, ubyte g, ubyte b, ubyte a) {

		super(renderer,
			  text,
			  value,
			  instruction,
			  x, y, w, h,
			  r, g, b, a);

		buttonText.setX(x + ((w / 2) - (text.width / 2)));
		buttonText.setY(y + (h / 2) - (text.height / 2) - 10);

		this.bottomLine = new Solid(renderer, w, h / 10, x, y + h - (h / 10),
									255, 255, 255, 255);

		buttonAnimation = new PolynomialFunction!double(-0.0002, 0.0307, -0.037, 0);
		timerIndex = Timer.addTimer();
		timer = Timer.timers[timerIndex];
	}

	override public void render() {

		int percentagePassed = timer.getPercentagePassed();
		if (percentagePassed > 100) {
			percentagePassed = 100;
		}
		if (highlighting == 1) {
			bottomLine.setH(EzMath.getCoords(to!int(buttonAnimation.getY(percentagePassed)), 9, solid.height));
			bottomLine.setY(EzMath.getCoords(to!int(buttonAnimation.getY(percentagePassed)), solid.getY + solid.height - (solid.height / 10), solid.getY));
		} else {
			bottomLine.setH(EzMath.getCoords(to!int(buttonAnimation.getY(percentagePassed)), solid.height, 9));
			bottomLine.setY(EzMath.getCoords(to!int(buttonAnimation.getY(percentagePassed)), solid.getY, solid.getY + solid.height - (solid.height / 10)));
		}

		solid.render();
		bottomLine.render();
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
