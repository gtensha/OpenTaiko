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

import derelict.sdl2.sdl : SDL_Renderer, SDL_Rect, SDL_UnionRect, SDL_Color;

class HorizontalTopBarButton : Button {

	private uint timerIndex;
	private Timer timer;
	private Solid bottomLine;
	private Text invertedText;
	private PolynomialFunction!double buttonAnimation;
	private byte highlighting = 0; // 1 = up, 0 = down
	private const int animationDuration = 800;

	this(Text text,
		 int value,
		 Traversable subMenu,
		 void delegate() instruction,
		 int x, int y, int w, int h,
		 SDL_Color buttonColor,
		 SDL_Color complementColor) {

		super(text,
			  value,
			  subMenu,
			  instruction,
			  x, y, w, h,
			  buttonColor.r, 
			  buttonColor.g, 
			  buttonColor.b, 
			  buttonColor.a);

		buttonText.rect.x = (x + ((w / 2) - (text.rect.w / 2)));
		buttonText.rect.y = (y + (h / 2) - (text.rect.h / 2) - 10);

		/*invertedText = new Text(buttonText.getText,
								buttonText.getFont,
								true,
								buttonText.rect.x,
								buttonText.rect.y,
								r, g, b, a);

		invertedText.setColor(r, g, b, a);*/
		invertedText = text;


		this.bottomLine = new Solid(w, h / 10, x, y + h - (h / 10),
									complementColor.r, 
									complementColor.g, 
									complementColor.b, 
									complementColor.a);

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
			bottomLine.rect.h = (EzMath.getCoords(percentagePassed, 
												  8, 
												  solid.rect.h));
			bottomLine.rect.y = (EzMath.getCoords(percentagePassed, 
												  solid.rect.y 
												  + solid.rect.h 
												  - (solid.rect.h / 10),
												  solid.rect.y));
		} else {
			bottomLine.rect.h = (EzMath.getCoords(percentagePassed, 
												  solid.rect.h, 
												  8));
			bottomLine.rect.y = (EzMath.getCoords(percentagePassed, 
												  solid.rect.y, 
												  solid.rect.y 
												  + solid.rect.h 
												  - (solid.rect.h / 10)));
		}

		solid.render();
		//buttonText.render();
		bottomLine.render();
		invertedText.render();

		SDL_Rect textPortion = {0,
								buttonText.rect.y + 10,
								0,
								buttonText.rect.y 
								- (bottomLine.rect.y - bottomLine.rect.h)};
		if (textPortion.h <= 0) {
			buttonText.render();
		} else {
			textPortion.w = 0;
			textPortion.y = invertedText.rect.y - textPortion.h;
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
