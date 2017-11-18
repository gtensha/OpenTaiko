module maware.renderable.menus.horizontaltopbarbutton;

import maware.renderable.menus.horizontaltopbarmenu;
import maware.renderable.menus.button;
import maware.renderable.menus.traversable;
import maware.renderable.solid;
import maware.renderable.text;
import maware.renderable.menus.menu;
import maware.util.math.polynomialfunction;
import maware.util.timer;
import maware.util.math.ezmath;

import std.conv : to;

import derelict.sdl2.sdl : SDL_Renderer, SDL_Rect, SDL_UnionRect;

class HorizontalTopBarButton : Button {

	private uint timerIndex;
	private Timer timer;
	private Solid bottomLine;
	private Text invertedText;
	private PolynomialFunction!double buttonAnimation;
	private byte highlighting = 0; // 1 = up, 0 = down
	private const int animationDuration = 800;

	this(SDL_Renderer* renderer,
		 Text text,
		 int value,
		 Traversable subMenu,
		 void delegate() instruction,
		 int x, int y, int w, int h,
		 ubyte r, ubyte g, ubyte b, ubyte a) {

		super(renderer,
			  text,
			  value,
			  subMenu,
			  instruction,
			  x, y, w, h,
			  r, g, b, a);

		buttonText.setX(x + ((w / 2) - (text.width / 2)));
		buttonText.setY(y + (h / 2) - (text.height / 2) - 10);

		invertedText = new Text(renderer,
								buttonText.getText,
								buttonText.getFont,
								true,
								buttonText.getX,
								buttonText.getY,
								r, g, b, a);

		invertedText.setColor(r, g, b, a);


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
		} else {
			//percentagePassed = to!int(buttonAnimation.getY(percentagePassed));
		}
		if (highlighting == 1) {
			bottomLine.setH(EzMath.getCoords(percentagePassed, 8, solid.height));
			bottomLine.setY(EzMath.getCoords(percentagePassed, solid.getY + solid.height - (solid.height / 10), solid.getY));
		} else {
			bottomLine.setH(EzMath.getCoords(percentagePassed, solid.height, 8));
			bottomLine.setY(EzMath.getCoords(percentagePassed, solid.getY, solid.getY + solid.height - (solid.height / 10)));
		}

		solid.render();
		//buttonText.render();
		bottomLine.render();
		invertedText.render();

		SDL_Rect textPortion = {0,
								buttonText.getY + 10,
								0,
								buttonText.getY - (bottomLine.getY - bottomLine.height)};
		if (textPortion.h <= 0) {
			buttonText.render();
		} else {
			textPortion.w = 0;
			textPortion.y = invertedText.getY - textPortion.h;
			//textPortion.y = invertedText.getY + invertedText.height;

			buttonText.renderPart(textPortion);
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
