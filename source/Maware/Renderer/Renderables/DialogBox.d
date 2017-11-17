module maware.renderable.dialogbox;

import maware.renderer;
import maware.renderable.renderable;
import maware.renderable.text;
import maware.renderable.solid;
import maware.renderable.textured;
import maware.renderable.menus.button, maware.renderable.menus.verticalbutton;
import maware.renderable.scene;
import maware.font;

class DialogBox : Renderable {

	private Text message;
	private Solid box;
	private Solid background;
	private Button[] buttons;
	private Scene backgroundScene;
	private uint backgroundSceneIndex;
	private uint sceneIndex;
	private void delegate() closeEvent;
	private Renderer parent;

	this(string msg,
		 string buttonText,
		 Font font,
		 void delegate() callback,
		 Renderer parent) {

		this.backgroundScene = parent.getCurrentScene();
		this.backgroundSceneIndex = parent.getCurrentSceneIndex();
		this.parent = parent;

		this.sceneIndex = parent.addScene(msg);
		parent.getScene(sceneIndex).addLayer();
		parent.getScene(sceneIndex).addRenderable(0, backgroundScene);
		parent.getScene(sceneIndex).addLayer();
		parent.getScene(sceneIndex).addRenderable(1, this);

		this.background = new Solid(parent.sdlRenderer,
									parent.windowWidth,
									parent.windowHeight,
									0, 0,
									40, 40, 40, 128);

		this.box = new Solid(parent.sdlRenderer,
							 parent.windowWidth / 2,
							 parent.windowHeight / 3,
							 parent.windowWidth / 4,
							 parent.windowHeight / 6,
							 224, 224, 224, 255);

		this.message = new Text(parent.sdlRenderer,
								msg,
								font.get(32),
								true,
								box.getX + 20, box.getY + 20,
								40, 40, 40, 255);

		Text onButton = new Text(parent.sdlRenderer,
								 buttonText,
							 	 font.get(22),
							 	 true,
							 	 0, 0,
							 	 255, 255, 255, 255);

		buttons ~= new VerticalButton(parent.sdlRenderer,
									  onButton,
									  0,
									  null,
									  callback,
									  box.getX + ((box.getX + box.width - box.getX) / 4),
									  box.getY + box.height - 80,
									  onButton.width + 40, onButton.height + 20,
									  221, 44, 0, 255);

	}

	public void render() {
		backgroundScene.render();
		background.render();
		box.render();
		message.render();
		foreach(Button button ; buttons) {
			if (button !is null) {
				button.render();
			}
		}
	}

	public void popUp(string msg) {
		message.updateText(msg);
		parent.getScene(sceneIndex).setObjectAt(parent.getCurrentScene(), 0, 0);
		backgroundSceneIndex = parent.getCurrentSceneIndex();
		backgroundScene = parent.getCurrentScene();
		parent.setScene(sceneIndex);
	}

	public void close() {
		parent.setScene(backgroundSceneIndex);
	}

}
