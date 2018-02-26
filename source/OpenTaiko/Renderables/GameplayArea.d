module opentaiko.renderable.gameplayarea;

import opentaiko.performance;
import opentaiko.renderable.hitstatus;
import opentaiko.game : OpenTaiko;
import opentaiko.playerdisplay;
import opentaiko.player;
import maware.renderer;
import maware.renderable;
import maware.font;

import std.string : rightJustify;
import std.conv : to;

import derelict.sdl2.sdl : SDL_Renderer;

/// Status types for hit result effects
enum StatusType {
	GOOD = 0,
	OK = 1,
	BAD = 2
}

class GameplayArea : Renderable {

	protected Renderer renderer;
	protected Font font;
	protected int offsetX;
	protected int offsetY;
	protected int maxWidth;
	protected int maxHeight;

	protected Performance currentPerformance;
	protected Player currentPlayer;
	
	protected Solid background;
	protected Solid header;
	protected Solid indicatorArea;
	protected Solid drumConveyor;

	protected Textured reception;
	
	protected HitStatus hitResultEffect;

	//protected Text player;
	protected NameBox playerDisplay;
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
		this.font = uiFont;

		this.background = new Solid(maxWidth, maxHeight, offsetX, offsetY,
									OpenTaiko.guiColors.playAreaLower.r,
									OpenTaiko.guiColors.playAreaLower.g,
									OpenTaiko.guiColors.playAreaLower.b,
									OpenTaiko.guiColors.playAreaLower.a);

		this.header = new Solid(maxWidth, maxHeight / 3, offsetX, offsetY,
								OpenTaiko.guiColors.playAreaUpper.r,
								OpenTaiko.guiColors.playAreaUpper.g,
								OpenTaiko.guiColors.playAreaUpper.b,
								OpenTaiko.guiColors.playAreaUpper.a);

		this.indicatorArea = new Solid(126, 100, offsetX, offsetY + header.rect.h,
									   OpenTaiko.guiColors.playAreaConveyor.r,
									   OpenTaiko.guiColors.playAreaConveyor.g,
									   OpenTaiko.guiColors.playAreaConveyor.b,
									   OpenTaiko.guiColors.playAreaConveyor.a);

		this.drumConveyor = new Solid(maxWidth, 100, offsetX, offsetY + header.rect.h,
									  OpenTaiko.guiColors.playAreaConveyor.r,
									  OpenTaiko.guiColors.playAreaConveyor.g,
									  OpenTaiko.guiColors.playAreaConveyor.b,
									  OpenTaiko.guiColors.playAreaConveyor.a);

		this.reception = new Textured(renderer.getTexture("Reception"),
									  offsetX + indicatorArea.rect.w + 10, 0);

		reception.rect.y = (offsetY + header.rect.h + drumConveyor.rect.h / 2 - reception.rect.h / 2);


		this.score = new Text("0000000",
							  uiFont.get(36),
							  true,
							  0, offsetY,
							  OpenTaiko.guiColors.buttonTextColor.r,
							  OpenTaiko.guiColors.buttonTextColor.g,
							  OpenTaiko.guiColors.buttonTextColor.b,
							  OpenTaiko.guiColors.buttonTextColor.a);

		score.rect.x = (offsetX + maxWidth - score.rect.w - 20);
		
		this.hitResultEffect = new HitStatus([new Textured(renderer.getTexture("GoodHit"),
														   0, 0),
											  new Textured(renderer.getTexture("OkHit"),
														   0, 0),
											  new Textured(renderer.getTexture("BadHit"),
														   0, 0)],
											 this.reception);

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
		hitResultEffect.render();
		/*foreach (Textured drum ; drums) {
			if (drum !is null) {
				if (drum.getX > offsetX + maxWidth) {
					break;
				}
				drum.render();
			}
		}*/
		playerDisplay.render();
		
		if (currentPerformance.checkTardiness()) {
			this.giveHitStatus(StatusType.BAD);
			missEventCallback();
		}
		
	}

	public void setPerformance(Performance performance) {

		performance.setRenderableOffset(reception.rect.x, drumConveyor.rect.y, drumConveyor.rect.h);

		currentPerformance = performance;
	}
	
	public void setPlayer(Player* player, int number) {
		playerDisplay = new NameBox(player,
									number,
									font,
									drumConveyor.rect.h / 2,
									background.rect.w,
									drumConveyor.rect.h / 2,
									background.rect.x + background.rect.w,
									drumConveyor.rect.y + drumConveyor.rect.h);
	}
	
	public void giveHitStatus(int statusCode) {
		if (statusCode < 3 && statusCode > -1) {
			hitResultEffect.setEffect(statusCode);
		}
	}

}
