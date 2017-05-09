import std.stdio;
import std.conv;
import std.string;

import derelict.sdl2.sdl;
import derelict.sdl2.image;
import derelict.sdl2.mixer;
import derelict.sdl2.ttf;

import drums;

enum {
    TAIKO_RED = 0,
    TAIKO_BLUE = 1,
    TAIKO_RED_LARGE = 2,
    TAIKO_BLUE_LARGE = 3,
};

enum ASSET_DIR : string {
    DEFAULT = "assets/default/",
};

enum ASSET_FONT_TYPE : string {
    DEFAULT = "Roboto-light.ttf",
    MENUS = "Roboto-regular.ttf",
};

enum ASSET_FONT_SIZE : int {
    SCORE = 48,
    MENUS = 32,
    INFO = 24,
};

enum ASSET_TEXTURE : string {
    RED = "red.png",
    RED_LARGE = "redLarge.png",
    BLUE = "blue.png",
    BLUE_LARGE = "blueLarge.png",
    GRAD_HIT_R = "red_grad.png",
    GRAD_HIT_B = "blue_grad.png",
    HIT_GOOD = "good.png",
    HIT_OK = "ok.png",
    HIT_BAD = "bad.png",
    RECEPTION = "reception.png",
};

enum ASSET_SOUND : string {
    RED_HIT = "red.wav",
    BLUE_HIT = "blue.wav",
    MISS = "miss.wav",
};

class EzRender {

    SDL_Renderer* renderer;
    SDL_Window* window;
    Performance performance;
    Menu[] menus;

    SDL_Texture* redDrum;
    SDL_Texture* blueDrum;
    SDL_Texture* redGrad;
    SDL_Texture* blueGrad;
    SDL_Texture* reception, good, ok, bad;
    //SDL_Texture redLargeDrum;
    //SDL_Texture blueLargeDrum;

    Mix_Chunk* redHit, blueHit, missEffect;

    TTF_Font* scoreFont, menuFont;
    SDL_Texture*[string] textCache; // this never gets emptied, must
                                    // be implemented in the future

    int windowHeight;
    int windowWidth;
    
    this(SDL_Renderer* renderer, SDL_Window* window) {
	this.renderer = renderer;
	this.window = window;
	this.performance = performance;

	DerelictSDL2Image.load();
	DerelictSDL2Mixer.load();
	DerelictSDL2ttf.load();

	SDL_Surface* redSurface = IMG_Load(toStringz(ASSET_DIR.DEFAULT ~ ASSET_TEXTURE.RED));
	SDL_Surface* blueSurface = IMG_Load(toStringz(ASSET_DIR.DEFAULT ~ ASSET_TEXTURE.BLUE));
	SDL_Surface* redGradSurface = IMG_Load(toStringz(ASSET_DIR.DEFAULT ~ ASSET_TEXTURE.GRAD_HIT_R));
	SDL_Surface* blueGradSurface = IMG_Load(toStringz(ASSET_DIR.DEFAULT ~ ASSET_TEXTURE.GRAD_HIT_B));
	SDL_Surface* receptionSurface = IMG_Load(toStringz(ASSET_DIR.DEFAULT ~ ASSET_TEXTURE.RECEPTION));
	SDL_Surface* goodSurface = IMG_Load(toStringz(ASSET_DIR.DEFAULT ~ ASSET_TEXTURE.HIT_GOOD));
	SDL_Surface* okSurface = IMG_Load(toStringz(ASSET_DIR.DEFAULT ~ ASSET_TEXTURE.HIT_OK));
	SDL_Surface* badSurface = IMG_Load(toStringz(ASSET_DIR.DEFAULT ~ ASSET_TEXTURE.HIT_BAD));

	redDrum = SDL_CreateTextureFromSurface(renderer, redSurface);
	blueDrum = SDL_CreateTextureFromSurface(renderer, blueSurface);
	redGrad = SDL_CreateTextureFromSurface(renderer, redGradSurface);
	blueGrad = SDL_CreateTextureFromSurface(renderer, blueGradSurface);
	reception = SDL_CreateTextureFromSurface(renderer, receptionSurface);
	good = SDL_CreateTextureFromSurface(renderer, goodSurface);
	ok = SDL_CreateTextureFromSurface(renderer, okSurface);
	bad = SDL_CreateTextureFromSurface(renderer, badSurface);
	

	SDL_FreeSurface(redSurface);
	SDL_FreeSurface(blueSurface);
	SDL_FreeSurface(redGradSurface);
	SDL_FreeSurface(blueGradSurface);
	SDL_FreeSurface(receptionSurface);
	SDL_FreeSurface(goodSurface);
	SDL_FreeSurface(okSurface);
	SDL_FreeSurface(badSurface);

	Mix_OpenAudio(MIX_DEFAULT_FREQUENCY, MIX_DEFAULT_FORMAT, MIX_DEFAULT_CHANNELS, 1024);

	redHit = Mix_LoadWAV(toStringz(ASSET_DIR.DEFAULT ~ ASSET_SOUND.RED_HIT));
	blueHit = Mix_LoadWAV(toStringz(ASSET_DIR.DEFAULT ~ ASSET_SOUND.BLUE_HIT));
	missEffect = Mix_LoadWAV(toStringz(ASSET_DIR.DEFAULT ~ ASSET_SOUND.MISS));

	TTF_Init();
	scoreFont = TTF_OpenFont(toStringz(ASSET_DIR.DEFAULT ~ ASSET_FONT_TYPE.DEFAULT), ASSET_FONT_SIZE.SCORE);
	menuFont = TTF_OpenFont(toStringz(ASSET_DIR.DEFAULT ~ ASSET_FONT_TYPE.MENUS), ASSET_FONT_SIZE.MENUS);

	SDL_GetWindowSize(window, &windowWidth, &windowHeight);
    }

    ~this() {
	TTF_CloseFont(scoreFont);
	TTF_CloseFont(menuFont);
	TTF_Quit();
    }

    void setPerformance(Performance performance) {
	this.performance = performance;
    }

    // Render a specific drum circle for specified frame
    bool renderCircle(Drum drum, int frame) {
	int drawCoord = to!int(drum.position - (frame * 16) + 100);
	SDL_Rect rect = {drawCoord, 200, 60, 60};
	if (drum.color() == 0) {
	    SDL_RenderCopy(renderer, redDrum, null, &rect);
	} else {
	    SDL_RenderCopy(renderer, blueDrum, null, &rect);
	}
	if (drawCoord > 1300) {
	    return false;
	} else {
	    return true;
	}
    }

    // Render all the drum circles in the game for specified frame
    void renderAllCircles(int frame) {

	foreach (Drum drum ; performance.drums) {
	    if (!(drum is null)) {
		if (renderCircle(drum, frame) == false) {
		    break;
		}
	    }
	}
    }

    // Render gameplay background
    void renderBackground() {
	SDL_SetRenderDrawColor(renderer, 40, 40, 40, 255);
	SDL_RenderClear(renderer);

	// Draw overhead background
	this.fillSurfaceArea(0, 0, 1200, 150,
			     255, 150, 0, 255);
	// Draw play area
	this.fillSurfaceArea(0, 150, 1200, 150,
			     20, 20, 20, 255);
	// Draw "reception" box
	this.renderTexture(reception,
			   97, 200, 65, 65);

	// Draw score display
	this.renderText(to!string(performance.calculateScore()), windowWidth - 200, 95);
    }

    // Render red or blue hit gradient
    void renderHitGradient(int color) {
	SDL_Rect rect = {0, 150, 400, 150};
	if (color == TAIKO_RED) {
	    SDL_RenderCopy(renderer, redGrad, null, &rect);
	} else {
	    SDL_RenderCopy(renderer, blueGrad, null, &rect);
	}
    }

    // Play desired sound effect
    void playSoundEffect(int type) {
	if (type == TAIKO_RED) {
	    Mix_PlayChannel(0, redHit, 0);
	} else if (type == TAIKO_BLUE) {
	    Mix_PlayChannel(1, blueHit, 0);
	} else {
	    Mix_PlayChannel(2, missEffect, 0);
	}
    }

    // Fill a defined quadratic area with a specified colour
    void fillSurfaceArea(int x, int y, int w, int h, 
			 ubyte r, ubyte g, ubyte b, ubyte a) {
	
	SDL_Rect rect = {x, y, w, h};
	SDL_SetRenderDrawColor(renderer, r, g, b, a);
	SDL_RenderFillRect(renderer, &rect);
    }

    // Render a texture already loaded in the game
    void renderTexture(SDL_Texture* texture, int x, int y, int w, int h) {
	SDL_Rect rect = {x, y, w, h};
	SDL_RenderCopy(renderer, texture, null, &rect);
    }

    // Render hit result (good, bad, miss)
    void renderHitResult(int type) {
	SDL_Rect rect = {80, 180, 100, 100};
	if (type == 0) {
	    SDL_RenderCopy(renderer, good, null, &rect);
	} else if (type == 1) {
	    SDL_RenderCopy(renderer, ok, null, &rect);
	} else {
	    SDL_RenderCopy(renderer, bad, null, &rect);
	}
    }

    // Render some text with the default font and colour
    void renderText(string text, int x, int y) {
	SDL_Texture* cachedText;
	if ((text in textCache) is null) {
	    SDL_SetRenderDrawColor(renderer, 255, 255, 255, 255);
	    SDL_Color color = {255, 255, 255, 255};
	    SDL_Surface* textSurface = TTF_RenderText_Blended(scoreFont, toStringz(text), color);
	    cachedText = SDL_CreateTextureFromSurface(renderer, textSurface);
	    textCache[text] = cachedText;
	    SDL_FreeSurface(textSurface);
	} else {
	    cachedText = textCache.get(text, null);
	}
	int w, h;
	SDL_QueryTexture(cachedText, null, null, &w, &h);
	SDL_Rect rect = {x, y, w, h};
	SDL_RenderCopy(renderer, cachedText, null, &rect);
    }

    int createNewMenu(string[] titles) {
	this.menus ~= new Menu(titles, windowHeight, windowWidth);
	return menus.length - 1;
    }

    void renderMenu(int index) {
	if (index < menus.length)
	    this.menus[index].render();
    }

    class Menu {

	MenuItem[] choices;
	int w, h;
	int index = 0;

	this(string[] titles, int h, int w) {
	    this.w = w - 200;
	    this.h = h - 200;

	    int pos = 200;//this.w / titles.length;
	    int i = 0;
	    foreach (string title ; titles) {
		choices ~= new MenuItem(title, (pos * i++) + 200, 100, this.h);
	    }
	}

	void selectChoice(bool direction) {
	    // Go right if true
	    if (direction == true) {
		if (index < choices.length)
		    index++;
	    } else {
		if (index > 0)
		    index--;
	    }
	    render();
	}

	int choose() {
	    return index;
	}

	void render() {
	    int i = 0;
	    foreach (MenuItem item ; choices) {
		if (i == index)
		    item.render(true);
		else
		    item.render(false);
		i++;
	    }
	}
	
	class MenuItem {

	    static int highest;
	    int x;
	    int y;
	    int w, h;
	    int boxHeight;
	    SDL_Texture* normal, highlighted;

	    this(string text, int x, int y, int boxHeight) {
		this.x = x;
		this.y = y;
		this.boxHeight = boxHeight;
		string newText;
	        foreach (char character ; text) {
		    newText ~= character ~ "\n";
		}
		
		SDL_SetRenderDrawColor(renderer, 255, 255, 255, 255);
		SDL_Color color = {255, 255, 255, 255};
		SDL_Surface* normalSurface = TTF_RenderText_Blended_Wrapped(menuFont,
									  toStringz(newText),
									  color,
									  ASSET_FONT_SIZE.MENUS);
		SDL_Color color2 = {240, 40, 40, 255};
		SDL_Surface* highlightedSurface = TTF_RenderText_Blended_Wrapped(menuFont,
										 toStringz(newText),
										 color2,
										 ASSET_FONT_SIZE.MENUS);
		normal = SDL_CreateTextureFromSurface(renderer, normalSurface);
		highlighted = SDL_CreateTextureFromSurface(renderer, highlightedSurface);
		SDL_FreeSurface(normalSurface);
		SDL_FreeSurface(highlightedSurface);
		SDL_QueryTexture(normal, null, null, &w, &h);
		if (h > highest) {
		    highest = h;
		}
	    }
	    
	    void render(bool isHighlighted) {
		ubyte r, gb;
		SDL_Texture* toRender;
		if (isHighlighted) {
		    r = 255;
		    gb = 255;
		    toRender = highlighted;
		} else {
		    r = 240;
		    gb = 40;
		    toRender = normal;
		}
		fillSurfaceArea(x - 10, y - 10, ASSET_FONT_SIZE.MENUS + 10, boxHeight + 10,
				r, gb, gb, 255);
		renderTexture(toRender, x, y, w, h);
	    }
	    
	}
    }
	
}
