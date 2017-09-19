import Engine : Engine;
import Renderer : Renderer;
import Scene : Scene;
import Renderable : Renderable;
import Solid, Text, Textured;
import Song : Song;
import Difficulty : Difficulty;
import GameVars : GameVars;
import OpenTaikoAssets : openTaikoAssets, ASSET_DIR;
import Menu : Menu;
import HorizontalTopBarMenu : HorizontalTopBarMenu;

//import derelict.sdl2.sdl : SDL_Keycode;

import std.conv : to;
import std.stdio;

void main(string[] args) {
	OpenTaiko game = new OpenTaiko();

	game.run();
}

class OpenTaiko {

	private Engine engine;
	private uint startMenuIndex;
	private uint mainMenuIndex;

	public void run() {

		engine = new Engine("OpenTaiko");

		engine.start(800, 600, true, "OpenTaiko v0.2");

		loadAssets(engine);
		createStartMenu(&startMenuIndex);
		createMainMenu(&mainMenuIndex);

		engine.iHandler.bind(0, '\r');
		engine.iHandler.bind(1, 'p');

		int eventCode;
		while (true) {
			eventCode = engine.renderFrame();
			switch (eventCode) {
				case 0:
					engine.gameRenderer.fadeIntoScene(mainMenuIndex, 3000, &engine.renderFrame);
					break;

				case 1:
					engine.gameRenderer.fadeIntoScene(startMenuIndex, 3000, &engine.renderFrame);
					break;

				default:
					break;

				case -1:
					engine.stop();
					return;
			}

		}


	}

	void loadAssets(Engine e) {

		e.loadAssets(openTaikoAssets(), ASSET_DIR.DEFAULT);

	}

	void createStartMenu(uint* menuIndex) {
		Renderer r = engine.gameRenderer;
		*menuIndex = r.addScene("Start");
		r.getScene(*menuIndex).addLayer;
		r.getScene(*menuIndex)
		 .addRenderable(0,
				  		r.createSolid(r.windowWidth,
									  r.windowHeight,
									  0, 0,
									  240, 240, 240, 255));

		r.getScene(*menuIndex).addLayer;

		Text titleHeader = r.createText("OpenTaiko",
					 					"Noto-Light",
					 					36,
					 					true,
					 					0, 100,
					 					40, 40, 40, 255);

		titleHeader.setX(getCenterPos(r.windowWidth, titleHeader.width));
		r.getScene(*menuIndex).addRenderable(1, titleHeader);

		Solid lineCenter = r.createSolid(r.windowWidth, 80, 0, 0,
										 40, 40, 40, 255);

		lineCenter.setY(getCenterPos(r.windowHeight, lineCenter.height));
		r.getScene(*menuIndex).addRenderable(1, lineCenter);

		Text centerInfo = r.createText("Press any key",
									   "Noto-Light",
									   24,
									   true,
									   0, 0,
									   240, 240, 240, 255);

		centerInfo.setX(getCenterPos(r.windowWidth, centerInfo.width));
		centerInfo.setY(getCenterPos(r.windowHeight, centerInfo.height));
		r.getScene(*menuIndex).addRenderable(1, centerInfo);
		r.getScene(*menuIndex).addRenderable(1, r.createTextured("Soul", 0, 0));

	}

	void createMainMenu(uint* menuIndex) {
		Renderer r = engine.gameRenderer;
		*menuIndex = r.addScene("Main Menu");
		r.getScene(*menuIndex).addLayer();
		r.getScene(*menuIndex).addRenderable(0, r.createSolid(50, 50, 0, 0, 156, 89, 238, 255));
		r.getScene(*menuIndex).addLayer();
		HorizontalTopBarMenu newMenu = new HorizontalTopBarMenu(r.sdlRenderer,
								"Banan",
								r.getFont("Noto-Light"),
								200,
								80,
								216, 27, 96, 255);

		r.getScene(*menuIndex).addRenderable(1, new Solid(r.sdlRenderer,
														  r.windowWidth,
														  80,
														  0, 0,
														  216, 27, 96, 255));
		r.getScene(*menuIndex).addRenderable(1, newMenu);
		newMenu.addButton("Play", 0);
		newMenu.addButton("Settings", 1);
		newMenu.addButton("怪しい列", 2);
		newMenu.addButton("Exit", -1);

	}

	static int getCenterPos(int maxWidth, int width) {
		return (maxWidth - width) / 2;
	}

}
