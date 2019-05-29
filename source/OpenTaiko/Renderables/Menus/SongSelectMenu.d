module opentaiko.renderable.menus.songselectmenu;

import maware.renderer;
import maware.renderable;
import maware.renderable.ellipsedtext;
import maware.renderable.menus.menu : Menu;
import maware.renderable.menus.verticalmenu : VerticalMenu;
import maware.renderable.solid;
import maware.renderable.textured;
import maware.renderable.text;
import maware.font;
import opentaiko.score;
import opentaiko.song;
import opentaiko.difficulty;
import opentaiko.game : GUIDimensions, OpenTaiko;
import opentaiko.player;
import opentaiko.languagehandler : Message, phrase;

import std.algorithm.sorting : sort;
import std.conv : to;
import std.format : format;
import std.string : rightJustify;

import derelict.sdl2.sdl : SDL_Color, SDL_Renderer, SDL_Texture;
import derelict.sdl2.ttf : TTF_Font;

class SongSelectMenu : Traversable {

	protected Renderer parent;

	protected int x;
	protected int y;
	protected int maxWidth;
	protected int maxHeight;
	protected int spacing = 50;

	Font titleFont;
	Font artistFont;

	protected SongSelectMenuItem[] items;
	protected void delegate(Song song) musicPlaybackFun;
	protected void delegate() songSelectCallback;
	protected uint selectedItem;

	protected Solid[2] delims;

	this(Renderer parent,
		 void delegate(Song) musicPlaybackFun,
		 void delegate() songSelectCallback,
		 Font titleFont,
		 Font artistFont,
		 int x, int y, int maxWidth, int maxHeight) {

		this.parent = parent;
		this.x = x;
		this.y = y;
		this.maxWidth = maxWidth;
		this.maxHeight = maxHeight;
		this.titleFont = titleFont;
		this.artistFont = artistFont;
		this.selectedItem = 0;
		this.musicPlaybackFun = musicPlaybackFun;
		this.songSelectCallback = songSelectCallback;

		delims[0] = new Solid(5, maxHeight, x - 15, y,
							  127, 127, 127, 255);

		delims[1] = new Solid(5, maxHeight, x + maxWidth + 10, y,
							  127, 127, 127, 255);

	}

	public void render() {
		foreach (SongSelectMenuItem item ; items) {
			item.render();
		}
		delims[0].render();
		delims[1].render();
	}

	void addItem(Song song, Score[][Difficulty] scores, SDL_Texture* thumbnail) {

	
		items ~= new SongSelectMenuItem(parent,
										titleFont,
										artistFont,
										thumbnail,
										song,
										scores,
										songSelectCallback,
										spacing,
										cast(int)items.length,
										x, y, maxWidth, maxHeight);

		if (items.length < 2) {
			items[0].active = true;
		}
	}

	public void move(bool direction) {
		if (direction == Moves.RIGHT && selectedItem < items.length - 1) {
			items[selectedItem].active = false;
			selectedItem++;
		} else if (direction == Moves.LEFT && selectedItem > 0) {
			items[selectedItem].active = false;
			selectedItem--;
		} else {
			return;
		}
		foreach (SongSelectMenuItem item ; items) {
			item.move(!direction);
		}
		items[selectedItem].active = true;
		musicPlaybackFun(items[selectedItem].song);
	}

	public Traversable press() {
		return items[selectedItem].getMenu();
	}
	
	/// Returns the Song struct of the currently selected song
	public Song getSelectedSong() {
		return items[selectedItem].song;
	}
	
	/// Returns the Difficulty struct of the currently selected song's diff
	/// menu's Difficulty
	public Difficulty getSelectedDifficulty() {
		SongSelectMenuItem item = items[selectedItem];
		return item.song.difficulties[item.getMenu.getActiveButtonId];
	}

}

class SongSelectMenuItem : Renderable {

	protected SDL_Renderer* renderer;
	protected int spacing;
	protected int offset;
	protected string directory;
	Song song;
	protected DifficultyListMenu diffListMenu;
	
	bool active;

	protected Solid block;
	protected Textured thumbnail;
	protected Text title;
	protected Text artist;

	this(Renderer renderer,
		 Font titleFont,
		 Font artistFont,
		 SDL_Texture* thumbnail,
		 Song song,
		 Score[][Difficulty] scores,
		 void delegate() songSelectCallback,
		 int spacing,
		 int offset,
		 int x, int y, int w, int h) {

		this.spacing = spacing;
		this.offset = offset;
		this.directory = directory;
		
		this.song = song;
		
		static const int edge = 10;
		const int maxWidth = w - edge * 2;

		block = new Solid(w, h, x, y, OpenTaiko.guiColors.cardColor);
		this.thumbnail = new Textured(thumbnail, w - edge * 2, w - edge * 2, x + edge, y + edge);
		this.title = new EllipsedText(song.title, 
									  titleFont.get(20), 
									  true,
									  maxWidth,
									  x + edge, 
									  y + this.thumbnail.rect.h + edge, 
									  OpenTaiko.guiColors.cardTextColor);
							  
		this.artist = new EllipsedText(song.artist,
									   artistFont.get(18), 
									   true,
									   maxWidth,
									   x + edge, 
									   y + this.title.rect.h + this.thumbnail.rect.h + edge,
									   OpenTaiko.guiColors.cardTextColor);

		for (int i = 0; i < offset; i++) {
			move(Moves.RIGHT);
		}
		
		diffListMenu = new DifficultyListMenu(renderer,
											  titleFont,
											  artistFont,
											  song,
											  scores,
											  this,
											  songSelectCallback,
											  renderer.windowHeight - block.rect.y);

	}

	public void render() {
		if (active) {
			diffListMenu.render();
		} else {
			renderCard();
		}
	}

	public void renderCard() {
		block.render();
		thumbnail.render();
		title.render();
		artist.render();
	}
	
	public DifficultyListMenu getMenu() {
		return diffListMenu;
	}

	void move(bool direction) {
		int toMove;
		if (direction == Moves.RIGHT) {
			toMove = block.rect.w + spacing;
			block.rect.x = (block.rect.x + toMove);
			thumbnail.rect.x = (thumbnail.rect.x + toMove);
			title.rect.x = (title.rect.x + toMove);
			artist.rect.x = (artist.rect.x + toMove);
		} else {
			toMove = block.rect.w + spacing;
			block.rect.x = (block.rect.x - toMove);
			thumbnail.rect.x = (thumbnail.rect.x - toMove);
			title.rect.x = (title.rect.x - toMove);
			artist.rect.x = (artist.rect.x - toMove);
		}
	}

}

class DifficultyListMenu : Traversable {
	
	enum BORDER_SPACING = 10; /// pixels between squares
	enum TEXT_SPACING = 10;
	enum DIFF_LIST_BUTTON_HEIGHT = 50;
	enum TEXTBOX_COLUMN_COUNT = 2;
	
	protected Song song;
	protected SongSelectMenuItem parentItem;
	
	protected Menu difficultyList;
	protected Solid menuPadding;
	protected Solid difficultyInfoPadding;

	protected TextBox[] difficultyInfoBox;
	protected Text[] difficultyTitle;
	protected Text mapperText;
	protected Text[] mapperInfo;
	protected Text difficultyText;
	protected Text[] difficultyLevel;
	protected Text highScoreText;
	protected Text[][] highScoreDisplay;
	
	protected int activeDiffIndex;
	
	static int textSize = 20;
	
	
	this(Renderer renderer,
		 Font boldFont,
		 Font textFont,
		 Song song,
		 Score[][Difficulty] scores,
		 SongSelectMenuItem parentItem,
		 void delegate() songSelectCallback,
		 int lowerSectionReserved) {
		
		this.song = song;
		this.parentItem = parentItem;
		
		const int paddingWidth = (renderer.windowWidth / 2) - BORDER_SPACING;
		int paddingHeight = renderer.windowHeight 
		                    - lowerSectionReserved 
							- GUIDimensions.TOP_BAR_HEIGHT 
							- (BORDER_SPACING * 2);
		
		difficultyInfoPadding = new Solid(paddingWidth,
										  paddingHeight,
										  BORDER_SPACING,
										  GUIDimensions.TOP_BAR_HEIGHT + BORDER_SPACING,
										  OpenTaiko.guiColors.cardColor);
										  
		menuPadding = new Solid(paddingWidth - BORDER_SPACING,
								paddingHeight,
								paddingWidth + (BORDER_SPACING * 2),
								GUIDimensions.TOP_BAR_HEIGHT + BORDER_SPACING,
								OpenTaiko.guiColors.cardColor);
		
		difficultyList = new VerticalMenu("Difficulty select",
		                                  boldFont,
										  menuPadding.rect.w - BORDER_SPACING * 2,
										  DIFF_LIST_BUTTON_HEIGHT,
										  menuPadding.rect.x + BORDER_SPACING,
										  menuPadding.rect.y + BORDER_SPACING,
										  menuPadding.rect.h - BORDER_SPACING,
										  OpenTaiko.guiColors.activeButtonColor,
										  OpenTaiko.guiColors.buttonTextColor);
		
		difficultyInfoBox = new TextBox[song.difficulties.length];
		
		foreach (int i, Difficulty diff ; song.difficulties) {
			wchar[10] starparts = ['☆', '☆', '☆', '☆', '☆', '☆', '☆', '☆', '☆', '☆'];
			for (int ii = 0; ii < diff.difficulty && ii < 10; ii++) {
				starparts[ii] = '★';
			}
			const string stars = to!string(starparts);
			const int boxWidth = difficultyInfoPadding.rect.w - BORDER_SPACING * 2;
			const int textWidth = boxWidth / TEXTBOX_COLUMN_COUNT;
			difficultyList.addButton(diff.name ~ " " ~ stars, i, null, songSelectCallback);
			TextBox box = new TextBox(boxWidth,
									  difficultyInfoPadding.rect.h - BORDER_SPACING * 2,
									  difficultyInfoPadding.rect.x + BORDER_SPACING,
									  difficultyInfoPadding.rect.y + BORDER_SPACING,
									  TEXTBOX_COLUMN_COUNT,
									  0);
			box.addLine(new EllipsedText(diff.name,
										 boldFont.get(textSize + (textSize * 2) / 2),
										 true,
										 0,
										 0,
										 0,
										 OpenTaiko.guiColors.cardTextColor));
			box.addLine(new CompactingText(diff.mapper,
										   textFont.get(textSize),
										   true,
										   0,
										   0,
										   0,
										   OpenTaiko.guiColors.cardTextColor));
			box.addLine(new CompactingText(stars ~ " (" ~ to!string(diff.difficulty) ~ ")",
										   textFont.get(textSize),
										   true,
										   0,
										   0,
										   0,
										   OpenTaiko.guiColors.cardTextColor));
			Score[]* scoreArrPtr = diff in scores;
			Score[] scoreArr = scoreArrPtr !is null ? *scoreArrPtr : null;
			int scoreRank = 1;
			foreach (Score score ; scoreArr.sort!("a > b")) {
				Player* p = OpenTaiko.getPlayerById(score.playerId);
				string playerName;
				if (p is null) {
					playerName = "UnknownPlayer#%d".format(score.playerId);
				} else {
					playerName = p.name;
				}
				string playerTimeText = format("#%d %s %s",
											   scoreRank,
											   playerName,
											   score.time.toSimpleString());
				string scoreText = format("%s (%sx) %d/%d/%d",
										  to!string(score.score).rightJustify(7, '0'),
										  to!string(score.maxCombo).rightJustify(4, '0'),
										  score.good,
										  score.ok,
										  score.bad);
				CompactingText upperCandidate;
				upperCandidate = new CompactingText(playerTimeText,
													boldFont.get(textSize),
													true,
													0,
													0,
													0,
													OpenTaiko.guiColors.cardTextColor);
				CompactingText candidate;
				candidate = new CompactingText(scoreText,
											   textFont.get(textSize),
											   true,
											   0,
											   0,
											   0,
											   OpenTaiko.guiColors.cardTextColor);
				scoreRank++;
				if (!box.addLine(upperCandidate) || !box.addLine(candidate)) {
					break;
				}
			}
			if (scoreRank < 2) {
				box.addLine(new CompactingText(phrase(Message.Menus.SONG_NO_SCORES),
											   textFont.get(textSize),
											   true,
											   0,
											   0,
											   0,
											   OpenTaiko.guiColors.cardTextColor));
			}
			difficultyInfoBox[i] = box;
		}
	}
	
	void move(bool direction) {
		difficultyList.move(direction);
		activeDiffIndex = difficultyList.getActiveButtonId();
	}
	
	Traversable press() {
		return difficultyList.press();
	}
	
	void render() {
		parentItem.renderCard();
		difficultyInfoPadding.render();
		menuPadding.render();
		difficultyList.render();
		difficultyInfoBox[activeDiffIndex].render();
	}
	
	int getActiveButtonId() {
		return activeDiffIndex;
	}
	
}
