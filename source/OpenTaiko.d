import Engine : Engine;
import Song : Song;
import Difficulty : Difficulty;
import GameVars : GameVars;

void main(string[] args) {
	OpenTaiko game = new OpenTaiko();

	game.run();
}

class OpenTaiko {

	private Engine engine;

	public void run() {

		engine = new Engine("OpenTaiko");

		engine.start(800, 600, true, "OpenTaiko v0.2");

		engine.stop();
	}

}
