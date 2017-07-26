import Engine : Engine;
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

		startMenuIndex = engine.gameRenderer().addScene("start");

		engine.gameRenderer.getScene(startMenuIndex).addLayer();

		engine.gameRenderer.getScene(startMenuIndex).addRenderable(0, engine.gameRenderer.createSolid(100, 100, 200, 200, 30, 70, 200, 255));

		for (int i = 0; i < 1000; i++) {
			engine.renderFrame();
		}

		engine.stop();
	}

}
