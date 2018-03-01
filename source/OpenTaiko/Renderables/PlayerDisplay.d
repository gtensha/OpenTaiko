module opentaiko.playerdisplay;

import maware.renderable.renderable;
import maware.renderable.solid;
import maware.font;
import maware.renderable.text;

import opentaiko.player;
import opentaiko.game : OpenTaiko, GUIDimensions;

import std.conv : to;

/// Class for displaying current players
class PlayerDisplay : Renderable {
	
	enum NAME_SPACING = 10;
	
	protected Player*[] players;
	protected int prevPlayerCount;
	protected Font font;
	protected Solid underline;
	protected NameBox[] names;
	
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
		foreach(NameBox name ; names) {
			name.render();
		}
	}
	
	/// Updates the list with new player data
	public void updatePlayers(Player*[] updated) {
		players = updated;
		names = null;
		underline.rect.w = 0;
		underline.rect.x = startX;
		for (int i = 0; i < players.length; i++) {
			names ~= new NameBox(players[i],
								 i,
								 font,
								 18,
								 200,
								 height,
								 (i > 0) ? names[i - 1].getX : startX, 0);
								 
			const int newWidth = names[i].width + NAME_SPACING;
			underline.rect.w += newWidth;
			underline.rect.x -= newWidth;
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
		
		this.playerName = new Text("[P" ~ to!string(number + 1) ~ "] " ~ player.name,
								   font.get(fontSize),
								   true,
								   0, y,
								   OpenTaiko.guiColors.buttonTextColor.r,
								   OpenTaiko.guiColors.buttonTextColor.g,
								   OpenTaiko.guiColors.buttonTextColor.b,
								   OpenTaiko.guiColors.buttonTextColor.a);
								   
		this.playerName.rect.x = x - this.playerName.rect.w - PlayerDisplay.NAME_SPACING;
		this.playerName.rect.y = y + (h - this.playerName.rect.h) / 2;
	}
	
	void render() {
		playerName.render();
	}
	
	int getX() {
		return playerName.rect.x;
	}
	
	int width() {
		return playerName.rect.w;
	}
	
}