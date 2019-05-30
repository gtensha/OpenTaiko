module opentaiko.renderable.playerdisplay;

import maware.renderable.ellipsedtext;
import maware.renderable.renderable;
import maware.renderable.solid;
import maware.font;
import maware.renderable.text;

import opentaiko.player;
import opentaiko.game : OpenTaiko, GUIDimensions;

import std.conv : to;
import std.format : format;

/// Class for displaying current players
class PlayerDisplay : Renderable {
	
	enum NAME_SPACING = 10;
	enum FONT_SIZE = 18;
	enum PLAYERNAME_MAX_WIDTH = 200;
	
	protected Player*[] players;
	protected int prevPlayerCount;
	protected Font font;
	protected Solid underline;
	protected NameBox[] names;
	protected Text additionalPlayers;
	
	protected int maxWidth;
	protected int startX;
	protected int height;
	
	/// Create a new PlayerDisplay with the given font and dimensions
	this(Player*[] players,
		 Font font,
		 int maxWidth, int height,
		 int startX, int y) {
			 
		this.font = font;
		this.height = height;
		this.startX = startX;
		this.maxWidth = maxWidth;
		this.underline = new Solid(0, GUIDimensions.UNDERLINE_HEIGHT,
								   startX, y + GUIDimensions.TOP_BAR_HEIGHT - GUIDimensions.UNDERLINE_HEIGHT,
								   OpenTaiko.guiColors.uiColorSecondary.r,
								   OpenTaiko.guiColors.uiColorSecondary.g,
								   OpenTaiko.guiColors.uiColorSecondary.b,
								   OpenTaiko.guiColors.uiColorSecondary.a);
								   
		this.updatePlayers(players);
	}
	
	void render() {
		underline.render();
		foreach (NameBox name ; names) {
			name.render();
		}
		if (additionalPlayers !is null) {
			additionalPlayers.render();
		}
	}
	
	/// Updates the list with new player data
	public void updatePlayers(Player*[] updated) {
		players = updated;
		names = null;
		underline.rect.w = 0;
		underline.rect.x = startX;
		const int nameWidth = PLAYERNAME_MAX_WIDTH > maxWidth ? maxWidth : PLAYERNAME_MAX_WIDTH;
		int i;
		for (i = 0; i < players.length; i++) {
			NameBox n = new NameBox(players[i],
									i,
									font,
									FONT_SIZE,
									nameWidth,
									height,
									names.length > 0 ? names[names.length - 1].getX : startX, 0);
			if (i == 0 || startX - n.getX <= maxWidth) {
				names ~= n;
				const int newWidth = n.width + NAME_SPACING;
				underline.rect.w += newWidth;
				underline.rect.x -= newWidth;
			}
		}
		if (names.length > 0 && i > names.length) {
			string text = "+%d".format(i - names.length);
			int fontSize = cast(int)(FONT_SIZE * 0.8);
			NameBox b = names[names.length - 1];
			int xVal = b.getX();
			int yVal = b.getY() - fontSize;
			additionalPlayers = new Text(text,
										 font.get(fontSize),
										 true,
										 xVal, yVal,
										 OpenTaiko.guiColors.buttonTextColor);
		} else {
			additionalPlayers = null;
		}
	}
	
}


/// A renderable class that renders a name and player number
class NameBox : Renderable {
	
	protected Player* player;
	protected Font font;
	
	protected Text playerName;
	
	this(Player* player,
		 int number,
		 Font font,
		 int fontSize,
		 int maxWidth, int h, int x, int y) {

		const string t = "[P" ~ to!string(number + 1) ~ "] " ~ player.name;
		playerName = new EllipsedText(t,
									  font.get(fontSize),
									  true,
									  maxWidth,
									  0, y,
									  OpenTaiko.guiColors.buttonTextColor);
								   
		this.playerName.rect.x = x - this.playerName.rect.w - PlayerDisplay.NAME_SPACING;
		this.playerName.rect.y = y + (h - this.playerName.rect.h) / 2;
	}
	
	void render() {
		playerName.render();
	}
	
	int getX() {
		return playerName.rect.x;
	}

	int getY() {
		return playerName.rect.y;
	}
	
	int width() {
		return playerName.rect.w;
	}

	int height() {
		return playerName.rect.h;
	}
	
}
