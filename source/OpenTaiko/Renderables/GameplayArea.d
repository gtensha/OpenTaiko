module opentaiko.renderable.gameplayarea;

import opentaiko.bashable.bashable;
import opentaiko.renderable.drumindicator;
import opentaiko.performance;
import opentaiko.renderable.hitstatus;
import opentaiko.game : OpenTaiko;
import opentaiko.renderable.playerdisplay;
import opentaiko.player;
import opentaiko.languagehandler : Message, phrase;
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
	protected DrumIndicator hitIndicator;

	//protected Text player;
	protected NameBox playerDisplay;
	protected Text score;
	protected Text combo;
	protected Renderable[] resultDisplay;
	protected bool done;

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
							  
		this.combo = new Text("000",
							  uiFont.get(30),
							  true,
							  drumConveyor.rect.x, drumConveyor.rect.y,
							  OpenTaiko.guiColors.buttonTextColor);
							  
		combo.rect.y += (drumConveyor.rect.h - combo.rect.h) / 2;
		combo.rect.x += ((reception.rect.x - drumConveyor.rect.x) - combo.rect.w) / 2;

		score.rect.x = (offsetX + maxWidth - score.rect.w - 20);
		
		this.hitResultEffect = new HitStatus([new Textured(renderer.getTexture("GoodHitKanji"),
														   0, 0),
											  new Textured(renderer.getTexture("GoodHitAlpha"),
											               0, 0),
											  new Textured(renderer.getTexture("OkHitKanji"),
														   0, 0),
											  new Textured(renderer.getTexture("OkHitAlpha"),
											               0, 0),
											  new Textured(renderer.getTexture("BadHitKanji"),
														   0, 0),
											  new Textured(renderer.getTexture("BadHitAlpha"),
											               0, 0)],
											 this.reception);
											 
		Textured[4] hi = [
			new Textured(renderer.getTexture("IndicatorLeftRim"), 0, 0),
			new Textured(renderer.getTexture("IndicatorLeftMid"), 0, 0),
			new Textured(renderer.getTexture("IndicatorRightMid"), 0, 0),
			new Textured(renderer.getTexture("IndicatorRightRim"), 0, 0)
		];
											 
		this.hitIndicator = new DrumIndicator(new Textured(renderer.getTexture("IndicatorBase"), 0, 0),
											  hi,
											  this.drumConveyor);

	}

	public void render() {

		score.updateText(rightJustify(to!string(currentPerformance.calculateScore()),
						 7,
						 '0'));
						 
		combo.updateText(to!string(currentPerformance.score.currentCombo));

		background.render();
		header.render();
		drumConveyor.render();
		indicatorArea.render();
		hitResultEffect.render();
		reception.render();
		hitIndicator.render();
		currentPerformance.render();
		score.render();
		combo.render();
		playerDisplay.render();
		
		if (done) {
			foreach (Renderable r ; resultDisplay) {
				r.render();
			}
			return;
		}

		int tardyValue = currentPerformance.checkTardiness();
		if (tardyValue == Performance.TardyValue.TARDY) {
			this.giveHitStatus(StatusType.BAD);
			missEventCallback();
		} else if (tardyValue == Performance.TardyValue.BONUS_EXPIRED) {
			int hitValue = currentPerformance.hitResult & Bashable.Success.MASK;
			this.giveHitStatus(hitValue);
		} else if (currentPerformance.finished) {
			drawResults();
		}
		
	}

	public void setPerformance(Performance performance) {

		performance.setRenderableOffset(reception.rect.x, drumConveyor.rect.y, drumConveyor.rect.h);

		currentPerformance = performance;
		
		resultDisplay = null;
		done = false;
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
	
	/// Calls DrumIndicator hitIndicator's hit method with section.
	/// section must be an integer in the range 0-3.
	public void giveDrumHit(int section) {
		hitIndicator.hit(section);
	}
	
	private void drawResults() {
		Text good = new Text(phrase(Message.Score.GOOD) ~ ": " ~ to!string(currentPerformance.hits(Bashable.Success.GOOD)),
							 score.getFont(),
							 true,
							 drumConveyor.rect.x + 10, drumConveyor.rect.y,
							 OpenTaiko.guiColors.buttonTextColor);
		good.rect.y -= good.rect.h;
		resultDisplay ~= good;
		
		Text ok = new Text(phrase(Message.Score.OK) ~ ": " ~ to!string(currentPerformance.hits(Bashable.Success.OK)),
						   score.getFont(),
						   true,
						   good.rect.x + good.rect.w + 20, drumConveyor.rect.y,
						   OpenTaiko.guiColors.buttonTextColor);
		ok.rect.y -= ok.rect.h;
		resultDisplay ~= ok;
		
		Text bad = new Text(phrase(Message.Score.BAD) ~ ": " ~ to!string(currentPerformance.score.bad),
						    score.getFont(),
						    true,
						    ok.rect.x + ok.rect.w + 20, drumConveyor.rect.y,
						    OpenTaiko.guiColors.buttonTextColor);
		bad.rect.y -= bad.rect.h;
		resultDisplay ~= bad;
		
		Text combo = new Text(phrase(Message.Score.COMBO) ~ ": " ~ to!string(currentPerformance.score.highestCombo),
						   score.getFont(),
						   true,
						   bad.rect.x + bad.rect.w + 20, drumConveyor.rect.y,
						   OpenTaiko.guiColors.buttonTextColor);
		combo.rect.y -= combo.rect.h;
		resultDisplay ~= combo;
		
		done = true;
	}

	/// Return the x coordinate of the score display text
	public int getScoreDisplayX() {
		return score.rect.x;
	}

}
