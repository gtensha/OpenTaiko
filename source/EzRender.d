import std.stdio;
import std.conv;
import std.string;
import std.file;

import derelict.sdl2.sdl;
import derelict.sdl2.image;
import derelict.sdl2.mixer;
import derelict.sdl2.ttf;

import drums;
import map_gen;

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
    DEFAULT = "Roboto-Light.ttf",
    MENUS = "Roboto-Regular.ttf",
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
    SOUL = "soul.png",
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
    Renderable[] renderableObjects;
    Effect[] effects;
    TextBuffer debugText;

    struct TextBuffer {
	SDL_Texture* texture;
	string text;
    }

    int circleIndex;

    SDL_Texture* redDrum;
    SDL_Texture* blueDrum;
    SDL_Texture* redGrad;
    SDL_Texture* blueGrad;
    SDL_Texture* reception, good, ok, bad;
    SDL_Texture* soul;
    //SDL_Texture redLargeDrum;
    //SDL_Texture blueLargeDrum;

    Mix_Chunk* redHit, blueHit, missEffect;
    Mix_Music* track;

    TTF_Font* scoreFont, menuFont, infoFont;
    SDL_Texture*[string] textCache; // this never gets emptied, must
                                    // be implemented in the future

    int windowHeight;
    int windowWidth;
    bool hasLoaded = false;
    
    this(SDL_Renderer* renderer, SDL_Window* window) {
	this.renderer = renderer;
	this.window = window;

	string dir = ASSET_DIR.DEFAULT;

	foreach (string asset ; [ASSET_TEXTURE.RED,
				 //ASSET_TEXTURE.RED_LARGE,
				 ASSET_TEXTURE.BLUE,
				 //ASSET_TEXTURE.BLUE_LARGE,
				 ASSET_TEXTURE.GRAD_HIT_R,
				 ASSET_TEXTURE.GRAD_HIT_B,
				 ASSET_TEXTURE.HIT_GOOD,
				 ASSET_TEXTURE.HIT_OK,
				 ASSET_TEXTURE.HIT_BAD,
				 ASSET_TEXTURE.RECEPTION,
				 ASSET_TEXTURE.SOUL,
				 ASSET_SOUND.RED_HIT,
				 ASSET_SOUND.BLUE_HIT,
				 ASSET_SOUND.MISS,
				 ASSET_FONT_TYPE.DEFAULT,
				 ASSET_FONT_TYPE.MENUS]) {
	    
	    assert((dir ~ asset).isFile);
	}
	
	DerelictSDL2Image.load();
	DerelictSDL2Mixer.load();
	DerelictSDL2ttf.load();
	
	SDL_Surface* redSurface = IMG_Load(toStringz(dir ~ ASSET_TEXTURE.RED));
	SDL_Surface* blueSurface = IMG_Load(toStringz(dir ~ ASSET_TEXTURE.BLUE));
	SDL_Surface* redGradSurface = IMG_Load(toStringz(dir ~ ASSET_TEXTURE.GRAD_HIT_R));
	SDL_Surface* blueGradSurface = IMG_Load(toStringz(dir ~ ASSET_TEXTURE.GRAD_HIT_B));
	SDL_Surface* receptionSurface = IMG_Load(toStringz(dir ~ ASSET_TEXTURE.RECEPTION));
	SDL_Surface* goodSurface = IMG_Load(toStringz(dir ~ ASSET_TEXTURE.HIT_GOOD));
	SDL_Surface* okSurface = IMG_Load(toStringz(dir ~ ASSET_TEXTURE.HIT_OK));
	SDL_Surface* badSurface = IMG_Load(toStringz(dir ~ ASSET_TEXTURE.HIT_BAD));
	SDL_Surface* soulSurface = IMG_Load(toStringz(dir ~ ASSET_TEXTURE.SOUL));

	redDrum = SDL_CreateTextureFromSurface(renderer, redSurface);
	blueDrum = SDL_CreateTextureFromSurface(renderer, blueSurface);
	redGrad = SDL_CreateTextureFromSurface(renderer, redGradSurface);
	blueGrad = SDL_CreateTextureFromSurface(renderer, blueGradSurface);
	reception = SDL_CreateTextureFromSurface(renderer, receptionSurface);
	good = SDL_CreateTextureFromSurface(renderer, goodSurface);
	ok = SDL_CreateTextureFromSurface(renderer, okSurface);
	bad = SDL_CreateTextureFromSurface(renderer, badSurface);
	soul = SDL_CreateTextureFromSurface(renderer, soulSurface);

	SDL_FreeSurface(redSurface);
	SDL_FreeSurface(blueSurface);
	SDL_FreeSurface(redGradSurface);
	SDL_FreeSurface(blueGradSurface);
	SDL_FreeSurface(receptionSurface);
	SDL_FreeSurface(goodSurface);
	SDL_FreeSurface(okSurface);
	SDL_FreeSurface(badSurface);
	SDL_FreeSurface(soulSurface);

	if (Mix_OpenAudio(MIX_DEFAULT_FREQUENCY,
			  MIX_DEFAULT_FORMAT,
			  MIX_DEFAULT_CHANNELS,
			  1024) < 0) {
	    
	    throw new SDLLibLoadException("SDL_mixer failed to load");
	}
	    

	redHit = Mix_LoadWAV(toStringz(dir ~ ASSET_SOUND.RED_HIT));
	blueHit = Mix_LoadWAV(toStringz(dir ~ ASSET_SOUND.BLUE_HIT));
	missEffect = Mix_LoadWAV(toStringz(dir ~ ASSET_SOUND.MISS));

	if (TTF_Init() < 0) {
	    throw new SDLLibLoadException("SDL_ttf failed to load");
	}
	
	scoreFont = TTF_OpenFont(toStringz(dir ~ ASSET_FONT_TYPE.DEFAULT), ASSET_FONT_SIZE.SCORE);
	menuFont = TTF_OpenFont(toStringz(dir ~ ASSET_FONT_TYPE.MENUS), ASSET_FONT_SIZE.MENUS);
	infoFont = TTF_OpenFont(toStringz(dir ~ ASSET_FONT_TYPE.DEFAULT), ASSET_FONT_SIZE.INFO);

	SDL_GetWindowSize(window, &windowWidth, &windowHeight);
	effects ~= new FadeEffect(redGrad, 68,
				  0, 150, 400, 150);
	effects ~= new FadeEffect(blueGrad, 68,
				  0, 150, 400, 150);
	effects ~= new FadeEffect(good, 100,
				  80, 180, 100, 100);
	effects ~= new FadeEffect(ok, 100,
				  80, 180, 100, 100);
	effects ~= new FadeEffect(bad, 100,
				  80, 180, 100, 100);
	hasLoaded = true;
    }

    ~this() {
	if (hasLoaded) {
	    Mix_CloseAudio();
	    TTF_CloseFont(scoreFont);
	    TTF_CloseFont(menuFont);
	    TTF_CloseFont(infoFont);
	    TTF_Quit();
	}
    }
    
    // (Obsolete function)
    // Render a specific drum circle for specified frame
    bool renderCircle(Drum drum, int time) {
	int drawCoord = to!int(drum.position - time + 100);
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
    void renderAllCircles(int time) {

	/*for (int i = performance.i; i < performance.drums.length; i++) {
	    if (renderCircle(performance.drums[i], time) == false) {
		break;
	    }
	    }*/
	for (int i = circleIndex; i < renderableObjects.length; i++) {
	    if (renderableObjects[i].render(time) == false) {
		break;
	    }
	}
    }

    // Render gameplay background
    void renderBackground() {
	SDL_SetRenderDrawColor(renderer, 40, 40, 40, 255);
	SDL_RenderClear(renderer);

	// Draw overhead background
	this.fillSurfaceArea(0, 0, windowWidth, 150,
			     255, 150, 0, 255);
	// Draw play area
	this.fillSurfaceArea(0, 150, windowWidth, 150,
			     20, 20, 20, 255);
	// Draw "reception" box
	this.renderTexture(reception,
			   97, 200, 65, 65);
	
	// Draw score display
	this.renderText(rightJustify(to!string(performance.calculateScore()),
				     7, '0'), windowWidth - 290, 95);
	this.renderTexture(soul,
			   windowWidth - 85, 70, 80, 80);

    }

    // Render red or blue hit gradient
    void renderHitGradient(int color, int time) {
        effects[color].reset(time);
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

    void playMusic() {
	Mix_PauseMusic();
	Mix_RewindMusic();
	if (Mix_PlayMusic(track, 1) < 0) {
	    writeln("Failed to play music: " ~ fromStringz(Mix_GetError()));
	}
    }

    void stopMusic() {
	Mix_PauseMusic();
	Mix_RewindMusic();
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
    void renderHitResult(int type, int time) {
	if (type == 0) {
	    effects[2].reset(time);
	} else if (type == 1) {
	    effects[3].reset(time);
	} else {
	    effects[4].reset(time);
	}
	/*if (type == TAIKO_RED || type == TAIKO_BLUE) {
	    if (performance.drums[performance.i - 1].color == TAIKO_RED) {
		addAnimation(redDrum, 97, 200);
	    } else {
		addAnimation(blueDrum, 97, 200);
	    }
	  }*/
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

    void renderQuickText(string text, int x, int y) {
	if (debugText.text is null || text != debugText.text) {
	    debugText.text = text;
	    SDL_Color color = {255, 255, 255, 255};
	    SDL_Surface* textSurface = TTF_RenderText_Solid(infoFont, toStringz(text), color);
	    SDL_DestroyTexture(debugText.texture);
	    debugText.texture = SDL_CreateTextureFromSurface(renderer, textSurface);
	    SDL_FreeSurface(textSurface);
	}
	int w, h;
	SDL_QueryTexture(debugText.texture, null, null, &w, &h);
	SDL_Rect rect = {x, y, w, h};
	SDL_RenderCopy(renderer, debugText.texture, null, &rect);
    }

    // Create new menu with given titles,
    // return its index in game renderer's array
    int createNewMenu(string[] titles, string menuTitle) {
	this.menus ~= new Menu(titles, menuTitle, windowHeight, windowWidth);
	return to!int(menus.length) - 1;
    }

    void appendMenu(int index, string[] titles) {
	this.menus[index].appendContent(titles);
    }

    // Render the menu at given index
    // in game renderer's array
    void renderMenu(int index) {
	if (index < menus.length)
	    this.menus[index].render();
    }

    void setPerformance(Performance performance, Song song) {
	this.performance = performance;
	string songDir = MAP_DIR ~ song.title ~ "/" ~ song.src;
	try {
	    songDir.isFile;
	} catch (Exception e) {
	    writeln("No music was detected");
	    return;
	}
	track = Mix_LoadMUS(toStringz(songDir));
	if (track is null) {
	    writeln("Failed to load music");
	}
    }

    class Menu {

	MenuItem[] choices;
	Page[] pages;
	int w, h;
	int itemsPerPage;
	int index = 0;
	SDL_Rect textRect;
	SDL_Texture* text;

	this(string[] titles, string title, int h, int w) {
	    this.w = w - 200;
	    this.h = h - 200;

	    itemsPerPage = (this.w - 200) / 200;

	    appendContent(titles);
	    
	    SDL_Color color = {255, 255, 255, 255};
	    SDL_Surface* textSurface = TTF_RenderText_Blended(scoreFont, toStringz(title), color);
	    text = SDL_CreateTextureFromSurface(renderer, textSurface);
	    SDL_FreeSurface(textSurface);
	    int tw, th;
	    SDL_QueryTexture(text, null, null, &tw, &th);
	    textRect.x = 185;
	    textRect.y = 15;
	    textRect.w = tw;
	    textRect.h = th;
	}

	void appendContent(string[] titles) {
	    pages = null;
	    choices = null;
	    int i;
	    int pos = 200;
	    Page newPage = new Page();
	    foreach (string title ; titles) {
		MenuItem currentItem = new MenuItem(title, (pos * i++) + 200, 100, this.h, newPage);
		choices ~= currentItem;
	        newPage.pageItems ~= currentItem;
		if (i == itemsPerPage) {
		    pages ~= newPage;
		    newPage = new Page();
		    i = 0;
		}
	    }
	}

	// Select to the right or left in menu
	void selectChoice(bool direction) {
	    // Go right if true
	    if (direction == true) {
		if (index < choices.length - 1)
		    index++;
		else
		    index = 0;
	    } else {
		if (index > 0)
		    index--;
		else
		    index = choices.length - 1;
	    }
	    render();
	}

	// Return the index of the currently
	// selected button
	int choose() {
	    return index;
	}

	// Render the menu
	void render() {
	    // If we do this here we don't have to constantly
	    // update the screen when the game is inactive
	    SDL_SetRenderDrawColor(renderer, 40, 40, 40, 255);
	    SDL_RenderClear(renderer);
	    SDL_RenderCopy(renderer, text, null, &textRect);
	    choices[index].renderPage();
	}

	class Page {

	    MenuItem[] pageItems;

	    void render() {
		foreach (MenuItem item ; pageItems) {
		    item.render();
		}
	    }
	}
	
	class MenuItem {

	    static int highest;
	    Page page;
	    int itemIndex;
	    int x;
	    int y;
	    int w, h;
	    int boxHeight;
	    SDL_Texture* normal, highlighted;

	    this(string text, int x, int y, int boxHeight, Page parent) {
		this.x = x;
		this.y = y;
		this.boxHeight = boxHeight;
		this.itemIndex = choices.length;
		this.page = parent;
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

	    void renderPage() {
		this.page.render();
	    }
	    
	    void render() {
		ubyte r, gb;
		SDL_Texture* toRender;
		if (index == this.itemIndex) {
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

    void renderAllEffects(int time) {
	foreach (Effect effect ; effects) {
	    effect.renderFrame(time);
	}
    }

    void resetEffects() {
	foreach (Effect effect ; effects) {
	    effect.reset(0);
	}
    }
    
    class Effect {

	SDL_Rect rect;
	SDL_Texture* texture;
	int duration; // milliseconds
	int startTime;

	this(SDL_Texture* texture, int duration,
	     int x, int y, int w, int h) {

	    rect.x = x;
	    rect.y = y;
	    rect.w = w;
	    rect.h = h;
	    this.duration = duration;
	    this.texture = texture;
	}

	void reset(int time) {
	    startTime = time;
	}
	
	abstract void renderFrame(int time);
    }

    class FadeEffect : Effect {

	this(SDL_Texture* texture, int duration,
	     int x, int y, int w, int h) {

	    super(texture, duration, x, y, w, h);
	}
	
	override void renderFrame(int time) {
	    double x = (to!double(time - startTime) / duration) * 100;
	    if (x < 100) {
		int y = to!int((-0.0225 * (x*x)) + (1.5 * x) + 75);
		SDL_SetTextureAlphaMod(texture, to!ubyte(255 * 0.01 * y));
		SDL_RenderCopy(renderer, this.texture, null, &rect);
	    }
	}
    }

    // A basic class for use in rendering
    abstract class Renderable {

	SDL_Rect rect;
	SDL_Texture* texture;
	int position;
	
	bool render(int time) {
	    rect.x = position - time + 100;
	    SDL_RenderCopy(renderer, this.texture, null, &rect);
	    if (rect.x > windowWidth) {
		return false;
	    } else {
		return true;
	    }
	}
    }
    
    class RenderableDrum : Renderable {

	HitAnimation animation;
	int index;
	
	this(Drum drum, int index) {
	    rect.x = to!int(drum.position + 100);
	    rect.y = 200;
	    rect.w = 60;
	    rect.h = 60;
	    position = to!int(drum.position);
	    this.index = index;

	    if (drum.color() == TAIKO_RED) {
		this.texture = redDrum;
	    } else {
		this.texture = blueDrum;
	    }
	    
	    animation = new HitAnimation(texture, 250, to!int(drum.position),
					 rect.x, rect.y, rect.w, rect.h);
	}

	override bool render(int time) {
	    if (performance.i <= index) {
		rect.x = position - time + 100;
		SDL_RenderCopy(renderer, this.texture, null, &rect);
		if (rect.x > windowWidth) {
		    return false;
		} else {
		    return true;
		}
	    } else {
		animation.renderFrame(time);
		return true;
	    }
	}
    }
    
    class HitAnimation : Effect {

	bool hasStarted = false;
	
	this(SDL_Texture* texture, int duration, int startTime,
	     int x, int y, int w, int h) {

	    super(texture, 250, x, y, w - 10, h - 10);
	    this.startTime = startTime;
	}
	
	override void renderFrame(int time) {
	    if (!hasStarted) {
		startTime = time;
		hasStarted = true;
	    }
	    double x = (to!double(time - startTime) / duration) * 100;
	    if (x < 100) {
		this.rect.y = to!int((0.04625 * (x*x)) - (5.925 * x) + 200);
		this.rect.x = to!int(100 + ((windowWidth - 185) * 0.01 * x));
		SDL_RenderCopy(renderer, this.texture, null, &this.rect);
	    } else {
		circleIndex++;
	    }
	}
    }
    
    void populateRenderables() {
	renderableObjects = null;
	circleIndex = 0;
	int i = 0;
	foreach (Drum drum ; performance.drums) {
	    renderableObjects ~= new RenderableDrum(drum, i);
	    i++;
	}
    }
    
}

class SDLLibLoadException : Exception {

    this(string msg) {
	super("SDLLibLoadException: " ~ msg);
    }

    override string toString() {
	return msg;
    }

}
