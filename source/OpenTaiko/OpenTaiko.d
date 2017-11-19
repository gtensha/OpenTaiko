module opentaiko.game;

import maware;
import opentaiko.assets;
import opentaiko.renderable.menus.songselectmenu;
import opentaiko.song;
import opentaiko.mapgen;
import opentaiko.renderable.gameplayarea;

import derelict.sdl2.sdl : SDL_Keycode;

import std.conv : to;
import std.stdio;
import std.container.dlist : DList;

void main(string[] args) {
	OpenTaiko game = new OpenTaiko();

	game.run();
}

enum Action : int {
		// Arrow keys
		UP = 0,
		DOWN = 1,
		LEFT = 2,
		RIGHT = 3,
		// Selectors
		SELECT = 4,
		BACK = 5,
		PAUSE = 6,
		QUIT = 7,
		MODESEL = 8

}

class OpenTaiko {

	private Engine engine;
	private Renderer renderer;
	private AudioMixer audioMixer;
	private InputHandler inputHandler;
	private uint startMenuIndex;
	private uint startMenuBinderIndex;
	private uint mainMenuIndex;
	private uint mainMenuBinderIndex;
	private uint gameplaySceneIndex;
	private uint gameplayBinderIndex;

	private DList!Traversable activeMenuStack;

	private Menu topBarMenu;
	private Menu playMenu;
	private Menu playerSelectMenu;
	private Menu settingsMenu;
	private SongSelectMenu songSelectMenu;

	private Song[] songs;
	private string[] playerNames;

	private bool quit = false;

	public void run() {

		engine = new Engine("OpenTaiko");

		engine.start(1600, 900, true, "OpenTaiko v0.2");

		renderer = engine.gameRenderer();
		audioMixer = engine.aMixer();
		inputHandler = engine.iHandler();

		loadAssets(engine);
		bindKeys(engine.iHandler);
		songs = MapGen.readSongDatabase(MAP_DIR ~ "maps.json");
		createSongSelectMenu();
		createStartMenu(&startMenuIndex);
		createMainMenu(&mainMenuIndex);
		createGameplayScene();
		//engine.gameRenderer.setScene(startMenuIndex);
		engine.gameRenderer.setDefaultFont("Noto-Light");

		int eventCode;
		while (!quit) {
			eventCode = engine.renderFrame();
			if (eventCode == -1) {
				break;
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
		startMenuBinderIndex = engine.iHandler.addActionBinder();
		engine.iHandler.setActive(startMenuBinderIndex);
		engine.iHandler.bindAction(startMenuBinderIndex, Action.SELECT, &switchSceneToMainMenu);
		engine.iHandler.bindAction(startMenuBinderIndex, Action.PAUSE, &quitGame);

	}

	void createMainMenu(uint* menuIndex) {
		Renderer r = engine.gameRenderer;
		*menuIndex = r.addScene("Main Menu");
		r.getScene(*menuIndex).addLayer();
		r.getScene(*menuIndex).addRenderable(0, r.createSolid(r.windowWidth, r.windowHeight, 0, 0, 224, 224, 224, 255));
		r.getScene(*menuIndex).addLayer();
		HorizontalTopBarMenu newMenu = new HorizontalTopBarMenu(r.sdlRenderer,
																"Banan",
																r.getFont("Noto-Light"),
																160,
																80,
																221, 44, 0, 255);

		r.getScene(*menuIndex).addRenderable(1, new Solid(r.sdlRenderer,
														  r.windowWidth,
														  80,
														  0, 0,
														  221, 44, 0, 255));
		r.getScene(*menuIndex).addRenderable(1, newMenu);
		topBarMenu = newMenu;
		newMenu.addButton("Play", 0, null, &switchToPlayMenu);
		newMenu.addButton("Settings", 1, null, &switchToSettingsMenu);

		playMenu = new VerticalMenu(r.sdlRenderer,
												 "Play",
												 r.getFont("Noto-Light"),
												 r.windowWidth / 3,
												 60,
												 10,
												 newMenu.getH + 20,
												 221, 44, 0, 255);

		r.getScene(*menuIndex).addRenderable(1, playMenu);

		playerSelectMenu = new VerticalMenu(r.sdlRenderer,
											"Player select",
											r.getFont("Noto-Light"),
											r.windowWidth / 3,
											60,
											10,
											newMenu.getH + 20,
											221, 44, 0, 255);

		playerSelectMenu.addButton("Single play", 0, songSelectMenu, null);
		playerSelectMenu.addButton("Multi play", 1, null, null);
		playerSelectMenu.addButton("Back", 2, null, &navigateMenuBack);

		playMenu.addButton("Arcade mode", 0, playerSelectMenu, null);
		playMenu.addButton("High scores", 1, null, null);
		playMenu.addButton("Test Gameplay Scene", 2, null, &switchSceneToGameplayScene);
		//playMenu.addButton("TestPopup", 2, null, &notifyMe);

		settingsMenu = new VerticalMenu(r.sdlRenderer,
										"Play",
										r.getFont("Noto-Light"),
										r.windowWidth / 3,
										60,
										10,
										newMenu.getH + 20,
										221, 44, 0, 255);



		settingsMenu.addButton("Name entry", 0, null, null);
		settingsMenu.addButton("Vsync", 1, null, null);

		mainMenuBinderIndex = engine.iHandler.addActionBinder();
		engine.iHandler.bindAction(mainMenuBinderIndex, Action.PAUSE, &navigateMenuBack);
		engine.iHandler.bindAction(mainMenuBinderIndex, Action.SELECT, &pressMenuButton);
		engine.iHandler.bindAction(mainMenuBinderIndex, Action.RIGHT, &moveRightMenu);
		engine.iHandler.bindAction(mainMenuBinderIndex, Action.DOWN, &moveRightMenu);
		engine.iHandler.bindAction(mainMenuBinderIndex, Action.LEFT, &moveLeftMenu);
		engine.iHandler.bindAction(mainMenuBinderIndex, Action.UP, &moveLeftMenu);
		engine.iHandler.bindAction(mainMenuBinderIndex, Action.MODESEL, &navigateTopBarRight);

	}

	void bindKeys(InputHandler i) {
		i.bind(Action.RIGHT, 	1073741903);
		i.bind(Action.LEFT, 	1073741904);
		i.bind(Action.DOWN, 	1073741905);
		i.bind(Action.UP, 		1073741906);
		i.bind(Action.SELECT, 	'\r');
		i.bind(Action.BACK, 	'\b');
		i.bind(Action.MODESEL,	'\t');
		i.bind(Action.PAUSE,	'\033');
	}

	void createSongSelectMenu() {
		int w = 250;
		int h = 325;
		int x = (renderer.windowWidth / 2) - (w / 2);
		int y = renderer.windowHeight - (h + 50);
		songSelectMenu = new SongSelectMenu(renderer,
											renderer.getFont("Noto-Bold").get(20),
											renderer.getFont("Noto-Light").get(18),
											x, y, w, h);
		foreach (Song song ; songs) {
			try {
				renderer.registerTexture("Thumb_" ~ song.title,
										 MAP_DIR ~ song.title ~ "/thumb.png");

				songSelectMenu.addItem(song, renderer.getTexture("Thumb_" ~ song.title));
			} catch (Exception e) {
				songSelectMenu.addItem(song, renderer.getTexture("Default-Thumb"));
			}
		}
	}

	void createGameplayScene() {

		GameplayArea playerOne = new GameplayArea(renderer,
												  0, 0, renderer.windowWidth, renderer.windowHeight / 2,
												  renderer.getFont("Noto-Regular"));

		GameplayArea playerTwo = new GameplayArea(renderer,
												  0, renderer.windowHeight / 2, renderer.windowWidth, renderer.windowHeight / 2,
												  renderer.getFont("Noto-Regular"));

		Scene gameplayScene = new Scene("Gameplay");
		gameplayScene.addLayer();
		gameplayScene.addRenderable(0, playerOne);
		gameplayScene.addRenderable(0, playerTwo);

		gameplaySceneIndex = renderer.addScene(gameplayScene);
		gameplayBinderIndex = inputHandler.addActionBinder();
		inputHandler.bindAction(gameplayBinderIndex, Action.PAUSE, &switchSceneToMainMenu);

	}

	static int getCenterPos(int maxWidth, int width) {
		return (maxWidth - width) / 2;
	}

	void switchSceneToMainMenu() {
		engine.gameRenderer.setScene(mainMenuIndex);
		engine.iHandler.setActive(mainMenuBinderIndex);
		engine.aMixer.playSFX(0);
		activeMenuStack.insertFront(cast(Menu)engine.gameRenderer.getScene(mainMenuIndex).objectAt(1, 2));
	}

	void switchSceneToStartMenu() {
		engine.gameRenderer.setScene(startMenuIndex);
		engine.iHandler.setActive(startMenuBinderIndex);
	}

	void switchSceneToGameplayScene() {
		renderer.setScene(gameplaySceneIndex);
		inputHandler.setActive(gameplayBinderIndex);
	}

	void quitGame() {
		quit = true;
	}

	void moveRightMenu() {
		activeMenuStack.front().move(Moves.RIGHT);
	}

	void moveLeftMenu() {
		activeMenuStack.front().move(Moves.LEFT);
	}

	void navigateMenuBack() {
		activeMenuStack.removeFront();
		if (activeMenuStack.empty) {
			switchSceneToStartMenu();
		} else {
			updateMainMenu();
		}
	}

	void navigateTopBarRight() {
		topBarMenu.move(Moves.RIGHT);
		topBarMenu.press();
	}

	void navigateTopBarLeft() {
		topBarMenu.move(Moves.LEFT);
		topBarMenu.press();
	}

	void pressMenuButton() {
		Traversable subMenu = activeMenuStack.front().press();
		if (subMenu !is null) {
			activeMenuStack.insertFront(subMenu);
		} else if (subMenu == activeMenuStack.front()) {
			activeMenuStack.removeFront();
		} else {
			return;
		}
		updateMainMenu();
	}

	void switchToPlayMenu() {
		activeMenuStack.clear();
		activeMenuStack.insertFront(playMenu);
		updateMainMenu();
	}

	void switchToSettingsMenu() {
		activeMenuStack.clear();
		activeMenuStack.insertFront(settingsMenu);
		updateMainMenu();
	}

	void updateMainMenu() {
		engine.gameRenderer.getScene(mainMenuIndex).setObjectAt(activeMenuStack.front(), 1, 2);
	}

	void notifyMe() {
		engine.notify(" ");
	}

}
