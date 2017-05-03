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

SDL_Window *window;
SDL_Renderer *renderer;

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
		buttonPressed = 0;
		break;
		
	    case SDLK_j:
		buttonPressed = 0;
		break;

	    case SDLK_d:
		buttonPressed = 1;
		break;

	    case SDLK_k:
		buttonPressed = 1;
		break;

	    default:
		break;
	    }
	    if (buttonPressed == 0 || buttonPressed == 1) {
		hitType = performance.hit(buttonPressed, frame * 16);
		if (buttonPressed == 0) {
		    gameRenderer.renderHitGradient(0);
		    gameRenderer.playSoundEffect(0);
		} else {
		    gameRenderer.renderHitGradient(1);
		    gameRenderer.playSoundEffect(1);
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

    /*writeln("Game will start in 5");
    SDL_Delay(1000);
    writeln("4");
    SDL_Delay(1000);
    writeln("3");
    SDL_Delay(1000);
    writeln("2");
    SDL_Delay(1000);
    writeln("1");
    SDL_Delay(1000);*/

    window = SDL_CreateWindow("OpenTaiko",
			      SDL_WINDOWPOS_UNDEFINED,
			      SDL_WINDOWPOS_UNDEFINED,
			      640,
			      480,
			      0);
    renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED);
    SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);
    SDL_RenderClear(renderer);
    SDL_RaiseWindow(window);

    gameRenderer = new EzRender(renderer, performance);
    
    render();
    while (/*frame * 16 < performance.drums[performance.drums.length - 1].position*/!(performance.drums[performance.drums.length - 1] is null)) {
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
