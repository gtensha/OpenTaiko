import Engine : Engine;
import Renderer : Renderer;
import Scene : Scene;
import Renderable : Renderable;
import Solid, Text, Textured;
import Song : Song;
import Difficulty : Difficulty;
import GameVars : GameVars;

import std.conv : to;

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

		loadAssets(engine.gameRenderer);
		createStartMenu(&startMenuIndex);

		for (int i = 0; i < 1000; i++) {
			engine.renderFrame();
		}

		engine.stop();
	}

	void loadAssets(Renderer r) {

		r.registerFont("Roboto", "assets/default/Roboto-Light.ttf");

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
					 					"Roboto",
					 					24,
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
									   "Roboto",
									   20,
									   true,
									   0, 0,
									   240, 240, 240, 255);

		centerInfo.setX(getCenterPos(r.windowWidth, centerInfo.width));
		centerInfo.setY(getCenterPos(r.windowHeight, centerInfo.height));
		r.getScene(*menuIndex).addRenderable(1, centerInfo);

	}

	static int getCenterPos(int maxWidth, int width) {
		return (maxWidth - width) / 2;
	}

}
