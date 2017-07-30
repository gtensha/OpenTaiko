import Engine : Engine;
import Renderer : Renderer;
import Scene : Scene;
import Renderable : Renderable;
import Solid, Text, Textured;
import Song : Song;
import Difficulty : Difficulty;
import GameVars : GameVars;
import OpenTaikoAssets : openTaikoAssets, ASSET_DIR;

import std.conv : to;
import std.stdio;

void main(string[] args) {
	OpenTaiko game = new OpenTaiko();

	game.run();
}

class OpenTaiko {

	private Engine engine;
	private uint startMenuIndex;

	public void run() {

		engine = new Engine("OpenTaiko");

		engine.start(800, 600, true, "OpenTaiko v0.2");

		loadAssets(engine);
		createStartMenu(&startMenuIndex);

		for (int i = 0; i < 1000; i++) {
			engine.renderFrame();
		}

		engine.stop();
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
					 					"Roboto-Light",
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
									   "Roboto-Light",
									   24,
									   true,
									   0, 0,
									   240, 240, 240, 255);

		centerInfo.setX(getCenterPos(r.windowWidth, centerInfo.width));
		centerInfo.setY(getCenterPos(r.windowHeight, centerInfo.height));
		r.getScene(*menuIndex).addRenderable(1, centerInfo);
		r.getScene(*menuIndex).addRenderable(1, r.createTextured("Soul", 0, 0));

	}

	static int getCenterPos(int maxWidth, int width) {
		return (maxWidth - width) / 2;
	}

}
