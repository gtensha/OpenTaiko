module opentaiko.renderable.menus.songselectmenu;

import maware.renderer;
import maware.renderable;
import maware.renderable.menus.menu : Menu;
import maware.renderable.solid;
import maware.renderable.textured;
import maware.renderable.text;
import opentaiko.song;

import derelict.sdl2.sdl : SDL_Color, SDL_Renderer, SDL_Texture;
import derelict.sdl2.ttf : TTF_Font;

class SongSelectMenu : Traversable {

	protected Renderer parent;

	protected int x;
	protected int y;
	protected int maxWidth;
	protected int maxHeight;
	protected int spacing = 50;

	TTF_Font* titleFont;
	TTF_Font* artistFont;

	protected SongSelectMenuItem[] items;
	protected uint selectedItem;

	protected Solid[2] delims;

	this(Renderer parent,
		 TTF_Font* titleFont,
		 TTF_Font* artistFont,
		 int x, int y, int maxWidth, int maxHeight) {

		this.parent = parent;
		this.x = x;
		this.y = y;
		this.maxWidth = maxWidth;
		this.maxHeight = maxHeight;
		this.titleFont = titleFont;
		this.artistFont = artistFont;
		this.selectedItem = 0;

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

	void addItem(Song song, SDL_Texture* thumbnail) {

		items ~= new SongSelectMenuItem(titleFont,
										artistFont,
										thumbnail,
										song.title,
										song.artist,
										spacing,
										cast(int)items.length,
										x, y, maxWidth, maxHeight);

	}

	public void move(bool direction) {
		if (direction == Moves.RIGHT && selectedItem < items.length - 1) {
			selectedItem++;
		} else if (direction == Moves.LEFT && selectedItem > 0) {
			selectedItem--;
		} else {
			return;
		}
		foreach (SongSelectMenuItem item ; items) {
			item.move(!direction);
		}
	}

	public Menu press() {
		return null;
	}

}

class SongSelectMenuItem : Renderable {

	protected SDL_Renderer* renderer;
	protected int spacing;
	protected int offset;
	protected string directory;
	protected Song song;

	protected Solid block;
	protected Textured thumbnail;
	protected Text title;
	protected Text artist;

	this(TTF_Font* titleFont,
		 TTF_Font* artistFont,
		 SDL_Texture* thumbnail,
		 string title,
		 string artist,
		 int spacing,
		 int offset,
		 int x, int y, int w, int h) {

		this.spacing = spacing;
		this.offset = offset;
		this.directory = directory;

		block = new Solid(w, h, x, y, 250, 250, 250, 255);
		this.thumbnail = new Textured(thumbnail, w - 20, w - 20, x + 10, y + 10);
		this.title = new Text(title, 
							  titleFont, 
							  true, 
							  x + 10, 
							  y + this.thumbnail.rect.h + 10, 
							  30, 30, 30, 255);
							  
		this.artist = new Text(artist,
							   artistFont, 
							   true, 
							   x + 10, 
							   y + this.title.rect.h + this.thumbnail.rect.h + 10,
							   50, 50, 50, 255);

		for (int i = 0; i < offset; i++) {
			move(Moves.RIGHT);
		}

	}

	public void render() {
		block.render();
		thumbnail.render();
		title.render();
		artist.render();
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
