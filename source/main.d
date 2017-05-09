import std.stdio;
import std.process;
import std.conv;
import std.file;
import std.string;
import std.ascii;

import drums;
import map_gen;
import EzRender;

import derelict.util.exception : ShouldThrow;
import derelict.sdl2.sdl;
import derelict.sdl2.image;

// This should do something, but it doesn't
ShouldThrow myMissingSymCB(string symbolName) {
    /*if (symbolName == "something") {
        return ShouldThrow.No;
    } else {
        return ShouldThrow.Yes;
    }*/
    return ShouldThrow.No;
}

SDL_Window* window;
SDL_Renderer* renderer;

Performance performance;
EzRender gameRenderer;

int frame;

// Render a gameplay frame
void renderGameplay() {
    gameRenderer.renderBackground();
    int hitType = 3;
    SDL_Event event;
    // Find which keys are being pressed, play sounds
    // and render effects, do hit registration testing
    while (SDL_PollEvent(&event) == 1) {	
	int buttonPressed = -1;
	if (event.type == SDL_KEYDOWN) {
	    switch (event.key.keysym.sym) {
	    case SDLK_f:
		buttonPressed = TAIKO_RED;
		break;
		
	    case SDLK_j:
		buttonPressed = TAIKO_RED;
		break;

	    case SDLK_d:
		buttonPressed = TAIKO_BLUE;
		break;

	    case SDLK_k:
		buttonPressed = TAIKO_BLUE;
		break;

	    default:
		break;
	    }
	    if (buttonPressed == TAIKO_RED || buttonPressed == TAIKO_BLUE) {
		hitType = gameRenderer.performance.hit(buttonPressed, frame * 16);
		if (buttonPressed == TAIKO_RED) {
		    gameRenderer.renderHitGradient(TAIKO_RED);
		    gameRenderer.playSoundEffect(TAIKO_RED);
		} else {
		    gameRenderer.renderHitGradient(TAIKO_BLUE);
		    gameRenderer.playSoundEffect(TAIKO_BLUE);
		}
	    }
	}
    }
    
    gameRenderer.renderAllCircles(frame);

    // Skip checking if hit is way ahead of time,
    // otherwise render the proper hit animation and play sound
    if (hitType != 3 || gameRenderer.performance.checkTardiness(frame * 16)) {
	if (hitType == 0 || hitType == 1) {
	    gameRenderer.renderHitResult(hitType);
	} else {
	    gameRenderer.renderHitResult(hitType);
	    gameRenderer.playSoundEffect(3);
	}
    }
    
    SDL_RenderPresent(renderer);
    SDL_Delay(16); // aim for around 60FPS
                   // (changeable FPS values are to be implemented)
    frame++;

}

bool renderMainMenu(int menuIndex) {

    SDL_SetRenderDrawColor(renderer, 40, 40, 40, 255);
    SDL_RenderClear(renderer);
    gameRenderer.menus[menuIndex].render();
    SDL_RenderPresent(renderer);
    int choice = -1;
    while (true) {
	SDL_Event event;
	// Find which keys are being pressed, play sounds
	// and render effects, do hit registration testing
	while (SDL_PollEvent(&event) == 1) {	
	    if (event.type == SDL_KEYDOWN) {
		switch (event.key.keysym.sym) {
		case SDLK_RIGHT:
		    gameRenderer.menus[menuIndex].selectChoice(true);
		    SDL_RenderPresent(renderer);
		    break;
		    
		case SDLK_LEFT:
		    gameRenderer.menus[menuIndex].selectChoice(false);
		    SDL_RenderPresent(renderer);
		    break;
		    
		case SDLK_RETURN:
		    choice = gameRenderer.menus[menuIndex].choose();
		    break;
		    
		default:
		    break;
		}
	    }
	    if (choice > -1) {
		// Selected start
		if (choice == 0)
		    return true;
		else
		    return false;
	    }
	}
	SDL_Delay(16);
    }
}

void main(string[] args) {

    DerelictSDL2.missingSymbolCallback = &myMissingSymCB;
    
    try {
	DerelictSDL2.load();
    } catch (Exception SharedLibLoadException) {
	writeln(SharedLibLoadException.toString());
    }
    
    SDL_Init(SDL_INIT_VIDEO);

    window = SDL_CreateWindow("OpenTaiko",
			      SDL_WINDOWPOS_UNDEFINED,
			      SDL_WINDOWPOS_UNDEFINED,
			      1200,
			      600,
			      0);
    renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED);
    SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);
    SDL_RenderClear(renderer);
    SDL_RaiseWindow(window);

    gameRenderer = new EzRender(renderer, window);

    // Create and render main menu
    int mainMenuId = gameRenderer.createNewMenu(["Play", "Exit"]);
    while (renderMainMenu(mainMenuId)) {
	gameRenderer.performance = new Performance("default");
	performance = gameRenderer.performance;
	// Render the game while there are drums left unhit
	frame = 0;
	renderGameplay();
	while (!(performance.drums[performance.drums.length - 1] is null)) {
	    renderGameplay();
	}
	SDL_Delay(2000);
	writeln("Results:\n"
		~ "Good: " ~ to!string(performance.score.good)
		~ "\nOK: " ~ to!string(performance.score.ok)
		~ "\nBad/Miss: " ~ to!string(performance.score.bad)
		~ "\nScore: " ~ to!string(performance.calculateScore()));
    }
    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    SDL_Quit();
    
    writeln("Done.");
}
