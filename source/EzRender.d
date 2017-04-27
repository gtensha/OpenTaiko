import std.stdio;
import std.conv;

import derelict.sdl2.sdl;
import derelict.sdl2.image;
import derelict.sdl2.mixer;

import drums;

class EzRender {

    /*enum {
	TAIKO_RED_DRUM = 0;
	TAIKO_BLUE_DRUM = 1;
	TAIKO_RED_LARGE_DRUM = 2;
	TAIKO_BLUE_LARGE_DRUM = 3;
	}*/

    SDL_Renderer* renderer;
    Performance performance;

    SDL_Texture* redDrum;
    SDL_Texture* blueDrum;
    SDL_Texture* redGrad;
    SDL_Texture* blueGrad;
    //SDL_Texture redLargeDrum;
    //SDL_Texture blueLargeDrum;

    Mix_Chunk* redHit, blueHit, missEffect;
    
    this(SDL_Renderer* renderer, Performance performance) {
	this.renderer = renderer;
	this.performance = performance;

	DerelictSDL2Image.load();
	DerelictSDL2Mixer.load();

	SDL_Surface* redSurface = IMG_Load("red.png");
	SDL_Surface* blueSurface = IMG_Load("blue.png");
	SDL_Surface* redGradSurface = IMG_Load("red_grad.png");
	SDL_Surface* blueGradSurface = IMG_Load("blue_grad.png");

	redDrum = SDL_CreateTextureFromSurface(renderer, redSurface);
	blueDrum = SDL_CreateTextureFromSurface(renderer, blueSurface);
	redGrad = SDL_CreateTextureFromSurface(renderer, redGradSurface);
	blueGrad = SDL_CreateTextureFromSurface(renderer, blueGradSurface);
	

	SDL_FreeSurface(redSurface);
	SDL_FreeSurface(blueSurface);
	SDL_FreeSurface(redGradSurface);
	SDL_FreeSurface(blueGradSurface);

	Mix_OpenAudio(MIX_DEFAULT_FREQUENCY, MIX_DEFAULT_FORMAT, MIX_DEFAULT_CHANNELS, 4096);

	redHit = Mix_LoadWAV("red.wav");
	blueHit = Mix_LoadWAV("blue.wav");
	missEffect = Mix_LoadWAV("miss.wav");
    }

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

    void renderAllCircles(int frame) {

	foreach (Drum drum ; performance.drums) {
	    if (renderCircle(drum, frame) == false) {
		break;
	    }
	}

	//SDL_RenderPresent(renderer);
    }

    void renderBackground() {
	SDL_SetRenderDrawColor(renderer, 40, 40, 40, 255);
	SDL_RenderClear(renderer);
	SDL_SetRenderDrawColor(renderer, 20, 20, 20, 255);
	SDL_Rect rect = {100, 200, 65, 65};
	SDL_RenderFillRect(renderer, &rect);
    }

    void renderHitGradient(int color) {
	SDL_Rect rect = {100, 198, 480, 80};
	if (color == 0) {
	    SDL_RenderCopy(renderer, redGrad, null, &rect);
	} else {
	    SDL_RenderCopy(renderer, blueGrad, null, &rect);
	}
    }

    void playSoundEffect(int type) {
	if (type == 0) {
	    Mix_PlayChannel(0, redHit, 0);
	} else if (type == 1) {
	    Mix_PlayChannel(0, blueHit, 0);
	} else {
	    Mix_PlayChannel(0, missEffect, 0);
	}
    }
}
