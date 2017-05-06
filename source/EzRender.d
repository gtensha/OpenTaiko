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

class EzRender {

    SDL_Renderer* renderer;
    SDL_Window* window;
    Performance performance;

    SDL_Texture* redDrum;
    SDL_Texture* blueDrum;
    SDL_Texture* redGrad;
    SDL_Texture* blueGrad;
    SDL_Texture* reception, good, ok, bad;
    //SDL_Texture redLargeDrum;
    //SDL_Texture blueLargeDrum;

    Mix_Chunk* redHit, blueHit, missEffect;

    TTF_Font* font;
    SDL_Texture*[string] textCache; // this never gets emptied, must
                                    // be implemented in the future

    int windowHeight;
    int windowWidth;
    
    this(SDL_Renderer* renderer, SDL_Window* window, Performance performance) {
	this.renderer = renderer;
	this.window = window;
	this.performance = performance;

	DerelictSDL2Image.load();
	DerelictSDL2Mixer.load();
	DerelictSDL2ttf.load();

	SDL_Surface* redSurface = IMG_Load("red.png");
	SDL_Surface* blueSurface = IMG_Load("blue.png");
	SDL_Surface* redGradSurface = IMG_Load("red_grad.png");
	SDL_Surface* blueGradSurface = IMG_Load("blue_grad.png");
	SDL_Surface* receptionSurface = IMG_Load("reception.png");
	SDL_Surface* goodSurface = IMG_Load("good.png");
	SDL_Surface* okSurface = IMG_Load("ok.png");
	SDL_Surface* badSurface = IMG_Load("bad.png");

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

	redHit = Mix_LoadWAV("red.wav");
	blueHit = Mix_LoadWAV("blue.wav");
	missEffect = Mix_LoadWAV("miss.wav");

	TTF_Init();
	font = TTF_OpenFont("Roboto-Light.ttf", 48);

	SDL_GetWindowSize(window, &windowWidth, &windowHeight);
    }

    ~this() {
	TTF_CloseFont(font);
	TTF_Quit();
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
	    SDL_Surface* textSurface = TTF_RenderText_Blended(font, toStringz(text), color);
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
	
}
