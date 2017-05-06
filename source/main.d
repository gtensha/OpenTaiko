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

ShouldThrow myMissingSymCB( string symbolName ) {
    /*if( symbolName == "SDL_QueueAudio" )
    {
        return ShouldThrow.No;
    }
    else
    {
        return ShouldThrow.Yes;
    }*/
    return ShouldThrow.No;
}

SDL_Window* window;
SDL_Renderer* renderer;

Performance performance;
EzRender gameRenderer;

int frame;

void render() {
    gameRenderer.renderBackground();
    int hitType = 3;
    SDL_Event event;
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
		hitType = performance.hit(buttonPressed, frame * 16);
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

    if (hitType != 3 || performance.checkTardiness(frame * 16)) {
	if (hitType == 0 || hitType == 1) {
	    gameRenderer.renderHitResult(hitType);
	} else {
	    gameRenderer.renderHitResult(hitType);
	    gameRenderer.playSoundEffect(3);
	}
	//SDL_Rect rect = {0, 150, 30, 30};
	//SDL_RenderFillRect(renderer, &rect);
    }
    
    SDL_RenderPresent(renderer);
    SDL_Delay(16); // aim for around 60FPS
                   // (changeable FPS values are to be implemented)
    frame++;

}

void main(string[] args) {

    DerelictSDL2.missingSymbolCallback = &myMissingSymCB;
    
    try {
	DerelictSDL2.load();
    } catch (Exception SharedLibLoadException) {
	writeln(SharedLibLoadException.toString());
    }
    
    SDL_Init(SDL_INIT_VIDEO);

    write("Enter desired BPM value (and press ENTER): ");
    int bpm;
    try {
	bpm = to!int(removechars(stdin.readln(), std.ascii.newline));
    } catch (Exception ConvException) {
	writeln("You dip, that's not a number, I've set the BPM to 1337 for you instead so good luck playing the game now");
	bpm = 1337;
    }
    string mapString = to!string(std.file.read("map.conf"));
    performance = new Performance(mapString, bpm);

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

    gameRenderer = new EzRender(renderer, window, performance);
    
    render();
    while (!(performance.drums[performance.drums.length - 1] is null)) {
	render();
    }
    SDL_Delay(2000);
    writeln("Results:\n"
	    ~ "Good: " ~ to!string(performance.score.good)
	    ~ "\nOK: " ~ to!string(performance.score.ok)
	    ~ "\nBad/Miss: " ~ to!string(performance.score.bad)
	    ~ "\nScore: " ~ to!string(performance.calculateScore()));

    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);

    writeln("Done.");

    SDL_Quit();
}
