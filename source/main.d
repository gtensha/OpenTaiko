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

// Keep going even if something is missing
ShouldThrow myMissingSymCB(string symbolName) {
    return ShouldThrow.No;
}

SDL_Window* window;
SDL_Renderer* renderer;

Performance performance;
EzRender gameRenderer;

GameVars vars;
Song[] songs;
Song currentSong;
Difficulty currentDiff;
int songSelectionMenu;
int diffSelectionMenu;

int frame;
int gameplayTime;
int seconds;
int fps;
int prevFrames;
int targetFPS = -1;
int frameSleepTime;
bool quit = false;

// Render a gameplay frame
void renderGameplay() {
    gameRenderer.renderBackground();
    int currentTime = SDL_GetTicks() - gameplayTime;
    if (currentTime - (seconds * 1000) > 0) {
	fps = frame - prevFrames;
	prevFrames = frame;
	seconds++;
    }
    gameRenderer.renderText(&gameRenderer.debugText, "FPS: " ~ to!string(fps), gameRenderer.infoFont, false, 0, 0);
    int hitType = 3;
    SDL_Event event;
    // Find which keys are being pressed, play sounds
    // and render effects, do hit registration testing
    int buttonPressed = -1;
    while (SDL_PollEvent(&event) == 1) {
	if (event.type == SDL_KEYDOWN) {
	    if (event.key.keysym.sym == vars.p1[RED1] || event.key.keysym.sym == vars.p1[RED2]) {
		buttonPressed = TAIKO_RED;
	    } else if (event.key.keysym.sym == vars.p1[BLUE1] || event.key.keysym.sym == vars.p1[BLUE2]) {
		buttonPressed = TAIKO_BLUE;
	    } else if (event.key.keysym.sym == SDLK_ESCAPE) {
		quit = true;
	    }
	} else if (event.type == SDL_QUIT) {
	    quit = true;
	}

    }

    if (buttonPressed == TAIKO_RED || buttonPressed == TAIKO_BLUE) {
	hitType = gameRenderer.performance.hit(buttonPressed, currentTime);
	if (buttonPressed == TAIKO_RED) {
	    gameRenderer.renderHitGradient(TAIKO_RED, currentTime);
	    gameRenderer.playSoundEffect(TAIKO_RED);
	} else {
	    gameRenderer.renderHitGradient(TAIKO_BLUE, currentTime);
	    gameRenderer.playSoundEffect(TAIKO_BLUE);
	}
    }

    gameRenderer.renderAllCircles(currentTime);

    // Skip checking if hit is way ahead of time,
    // otherwise render the proper hit animation and play sound
    if (hitType != 3 || gameRenderer.performance.checkTardiness(currentTime)) {
	if (hitType == 0 || hitType == 1) {
	    gameRenderer.renderHitResult(hitType, currentTime);
	} else {
	    gameRenderer.renderHitResult(hitType, currentTime);
	    gameRenderer.renderableObjects[performance.i - 1].success = false;
	    gameRenderer.playSoundEffect(3);
	}
    }

    gameRenderer.renderAllEffects(currentTime);

    SDL_RenderPresent(renderer);

    // This works nowhere near as good as I want it to, the image
    // is very choppy. Best to just play without a limiter for now...
    /*
    if (frameSleepTime > 0) {
	int frameEndTime = SDL_GetTicks() - gameplayTime;
	int toSleep = frameEndTime - currentTime;
	if (toSleep < frameSleepTime) {
	    SDL_Delay(frameSleepTime - toSleep);
	}
    }
    */
    frame++;

}

// Render the song selection menu
int renderSongSelection(int menuIndex) {

    gameRenderer.menus[menuIndex].render();
    SDL_RenderPresent(renderer);
    int choice = -1;
    quit = false;
    while (!quit) {
	SDL_Event event;
	// Detect menu navigation and render new
	// menu state
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
		    return gameRenderer.menus[menuIndex].choose();

		case SDLK_ESCAPE:
		    quit = true;
		    break;

		default:
		    break;
		}
	    } else if (event.type == SDL_QUIT) {
		quit = true;
	    }
	}
	SDL_Delay(16); // poll approx. 60 times/second
    }
    return -1;
}

// Render the main menu
bool renderMainMenu(int menuIndex) {

    int choice = -1;
    quit = false;
    while (choice != 0) {
	SDL_Event event;
	// Detect menu navigation and render new
	// menu state
	gameRenderer.menus[menuIndex].render();
	SDL_RenderPresent(renderer);
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

		case SDLK_ESCAPE:
		    return false;

		default:
		    break;
		}
	    } else if (event.type == SDL_QUIT) {
		choice = 3;
	    }
	    if (choice > -1) {
		if (choice == 0) {
		    string[] songTitles;
		    foreach (Song song ; songs) {
			songTitles ~= song.title;
		    }
		    gameRenderer.appendMenu(songSelectionMenu,
					    songTitles);
		    int mapChoice = renderSongSelection(songSelectionMenu);
		    if (mapChoice >= 0) {
			currentSong = songs[mapChoice];

			string[] diffTitles;
			foreach (Difficulty diff ; songs[mapChoice].difficulties) {
			    diffTitles ~= diff.name;
			}
			gameRenderer.appendMenu(diffSelectionMenu,
						diffTitles);
			int diffChoice = renderSongSelection(diffSelectionMenu);
			if (diffChoice >= 0) {
			    currentDiff = songs[mapChoice].difficulties[diffChoice];
			    return true;
			}
		    }
		    choice = -1;
		} else if (choice == 1) {
		    write("Enter the path to a valid .osu file: ");
		    try {
			MapGen.convertMapFile(removechars(stdin.readln(), std.ascii.newline));
		    } catch (Throwable t) {
			writeln("Error: The requested file could not be read\n\n"
				~ t.msg);
		    }
		    choice = -1;
		} else {
		    return false;
		}
	    }
	}
	SDL_Delay(16); // poll approx. 60 times/second
    }
    return true;
}

// Load and run the game
void main(string[] args) {

    try {
	vars = MapGen.readConfFile("settings.json");
	if (vars.resolution[0] < 0 || vars.resolution[1] < 0) {
	    vars.resolution = [1200, 600];
	}
    } catch (Exception e) {
	vars.p1 = [106, 102, 107, 100];
	vars.p2 = [0, 0, 0, 0];
	vars.resolution = [1200, 600];
	vars.vsync = false;

	writeln(e.msg);
	writeln("Error reading config file, using default settings.");
    }

    int rendererFlags;
    if (vars.vsync == true) {
	rendererFlags = SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC;
    } else {
	rendererFlags = SDL_RENDERER_ACCELERATED;
    }

    DerelictSDL2.missingSymbolCallback = &myMissingSymCB;

    try {
	DerelictSDL2.load();
    } catch (Exception e) {
	writeln(e.toString());
	return;
    }

    if (SDL_Init(SDL_INIT_VIDEO) < 0) {
	writeln("Failed to initialise SDL: ", fromStringz(SDL_GetError()));
	return;
    }

    window = SDL_CreateWindow("OpenTaiko",
			      SDL_WINDOWPOS_UNDEFINED,
			      SDL_WINDOWPOS_UNDEFINED,
			      vars.resolution[WIDTH],
			      vars.resolution[HEIGHT],
			      0);
    if (window is null) {
	writeln("Failed to create window: ", fromStringz(SDL_GetError()));
	return;
    }

    renderer = SDL_CreateRenderer(window, -1, rendererFlags);
    if (renderer is null) {
	writeln("Failed to create renderer: ", fromStringz(SDL_GetError()));
	return;
    }

    SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);
    SDL_RenderClear(renderer);
    SDL_RaiseWindow(window);

    bool canPlay = true;
    try {
	gameRenderer = new EzRender(renderer, window);
    } catch (Exception e) {
	writeln(e.toString());
	writeln("\nGame load FAILED");
	canPlay = false;
    }

    if (targetFPS > 0) {
	frameSleepTime = 1000 / targetFPS;
    }

    if (canPlay) {
	// Create and render main menu
	int mainMenuId = gameRenderer.createNewMenu(["Play", "Convert", "Exit"], "Main menu");
	try {
	    songs = MapGen.readSongDatabase(MAP_DIR ~ "maps.json");
	} catch (Exception e) {
	    writeln("Error in map database file, please verify that the contained data is correct before playing:\n"
		    ~ e.msg);
	    return;
	}
	songSelectionMenu = gameRenderer.createNewMenu(["null"], "Song selection");
	diffSelectionMenu = gameRenderer.createNewMenu(["null"], "Select difficulty");
	while (renderMainMenu(mainMenuId)) {
	    gameRenderer.setPerformance(new Performance(currentSong.title
							~ "/"
							~ currentDiff.name
							~ ".otfm"),
					currentSong);
	    performance = gameRenderer.performance;
	    if (performance.drums is null) {
		writeln("Error loading map, no drum objects produced");
	    } else {
		// Render the game while there are drums left unhit
		frame = 0;
		seconds = 0;
		gameRenderer.populateRenderables();
		gameRenderer.playMusic();
		gameplayTime = SDL_GetTicks();
		renderGameplay();
		while (!quit && performance.i < performance.drums.length) {
		    renderGameplay();
		}
		gameRenderer.resetEffects();
		//gameRenderer.stopMusic();
		if (!quit) {
		    SDL_Delay(2000);
		    writeln("Results:\n"
			    ~ "Good: " ~ to!string(performance.score.good)
			    ~ "\nOK: " ~ to!string(performance.score.ok)
			    ~ "\nBad/Miss: " ~ to!string(performance.score.bad)
			    ~ "\nMax combo: " ~ to!string(performance.score.highestCombo)
			    ~ "\nScore: " ~ to!string(performance.calculateScore()));
		}
	    }
	}
    }

    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    SDL_Quit();

    writeln("Done.");
}
