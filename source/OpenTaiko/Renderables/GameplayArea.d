module opentaiko.renderable.gameplayarea;

import opentaiko.performance;
import maware.renderer;
import maware.renderable;
import maware.font;

import std.string : rightJustify;
import std.conv : to;

import derelict.sdl2.sdl : SDL_Renderer;

class GameplayArea : Renderable {

	protected Renderer renderer;
	protected int offsetX;
	protected int offsetY;
	protected int maxWidth;
	protected int maxHeight;

	protected Performance currentPerformance;

	protected Solid background;
	protected Solid header;
	protected Solid indicatorArea;
	protected Solid drumConveyor;

	protected Textured reception;

	protected Text player;
	protected Text score;

	protected Textured[] drums;
	
	protected void delegate() missEventCallback;

	this(Renderer renderer,
		 int offsetX,
		 int offsetY,
		 int maxWidth,
		 int maxHeight,
		 Font uiFont,
		 void delegate() missEventCallback) {

		this.renderer = renderer;
		this.offsetX = offsetX;
		this.offsetY = offsetY;
		this.maxWidth = maxWidth;
		this.maxHeight = maxHeight;
		this.missEventCallback = missEventCallback;

		this.background = new Solid(maxWidth, maxHeight, offsetX, offsetY,
									40, 40, 40, 255);

		this.header = new Solid(maxWidth, maxHeight / 3, offsetX, offsetY,
								240, 240, 240, 255);

		this.indicatorArea = new Solid(126, 100, offsetX, offsetY + header.rect.h,
									   40, 40, 40, 0);

		this.drumConveyor = new Solid(maxWidth, 100, offsetX, offsetY + header.rect.h,
									  20, 20, 20, 255);

		this.reception = new Textured(renderer.getTexture("Reception"),
									  offsetX + indicatorArea.rect.w + 10, 0);

		reception.rect.y = (offsetY + header.rect.h + drumConveyor.rect.h / 2 - reception.rect.h / 2);


		this.score = new Text("0000000",
							  uiFont.get(32),
							  true,
							  0, offsetY,
							  40, 40, 40, 255);

		score.rect.x = (offsetX + maxWidth - score.rect.w - 20);

	}

	public void render() {

		score.updateText(rightJustify(to!string(currentPerformance.calculateScore()),
						 7,
						 '0'));

		background.render();
		header.render();
		drumConveyor.render();
		indicatorArea.render();
		reception.render();
		currentPerformance.render();
		//player.render();
		score.render();
		/*foreach (Textured drum ; drums) {
			if (drum !is null) {
				if (drum.getX > offsetX + maxWidth) {
					break;
				}
				drum.render();
			}
		}*/
		
		if (currentPerformance.checkTardiness()) {
			missEventCallback();
		}
		
	}

	public void setPerformance(Performance performance) {

		performance.setRenderableOffset(reception.rect.x, drumConveyor.rect.y, drumConveyor.rect.h);

		currentPerformance = performance;
	}

}
