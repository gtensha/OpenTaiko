module opentaiko.renderable.gameplayarea;

import opentaiko.performance;
import maware.renderer;
import maware.renderable;
import maware.font;

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

	this(Renderer renderer,
		 int offsetX,
		 int offsetY,
		 int maxWidth,
		 int maxHeight,
		 Font uiFont) {

		this.renderer = renderer;
		this.offsetX = offsetX;
		this.offsetY = offsetY;
		this.maxWidth = maxWidth;
		this.maxHeight = maxHeight;

		this.background = new Solid(renderer.sdlRenderer,
									maxWidth, maxHeight, offsetX, offsetY,
									40, 40, 40, 255);

		this.header = new Solid(renderer.sdlRenderer,
								maxWidth, maxHeight / 3, offsetX, offsetY,
								240, 240, 240, 255);

		this.indicatorArea = new Solid(renderer.sdlRenderer,
									   126, 100, offsetX, offsetY + header.height,
									   40, 40, 40, 0);

		this.drumConveyor = new Solid(renderer.sdlRenderer,
									  maxWidth, 100, offsetX, offsetY + header.height,
									  20, 20, 20, 255);

		this.reception = new Textured(renderer.sdlRenderer,
									  renderer.getTexture("Reception"),
									  offsetX + indicatorArea.width + 10, 0);

		reception.setY(offsetY + header.height + drumConveyor.height / 2 - reception.height / 2);


		this.score = new Text(renderer.sdlRenderer,
							  "0000000",
							  uiFont.get(32),
							  true,
							  0, offsetY,
							  40, 40, 40, 255);

		score.setX(offsetX + maxWidth - score.width - 20);

	}

	public void render() {

		background.render();
		header.render();
		drumConveyor.render();
		indicatorArea.render();
		reception.render();
		//player.render();
		score.render();
		foreach (Textured drum ; drums) {
			if (drum !is null) {
				if (drum.getX > offsetX + maxWidth) {
					break;
				}
				drum.render();
			}
		}

	}

}
