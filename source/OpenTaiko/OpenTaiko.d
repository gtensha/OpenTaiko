module opentaiko.game;

import maware;
import opentaiko.assets;
import opentaiko.renderable.menus.songselectmenu;
import opentaiko.song;
import opentaiko.difficulty;
import opentaiko.mapgen;
import opentaiko.bashable;
import opentaiko.performance;
import opentaiko.renderable.gameplayarea;
import opentaiko.palette;
import opentaiko.player;
import opentaiko.playerdisplay;
import opentaiko.textinputfield;
import opentaiko.browsablelist : BrowsableList;

import derelict.sdl2.sdl : SDL_Keycode;

import std.conv : to;
import std.algorithm.comparison : equal;
//import std.algorithm.mutation : copy;
import std.array : array;
import std.stdio;
import std.ascii : newline;
import std.container.dlist : DList;

void main(string[] args) {
	OpenTaiko game = new OpenTaiko();

	try {
		game.run();
	} catch (Throwable e) {
		Engine.notify(e.toString());
	}
}

/**
The possible inputs recognised by the game
0-127 are generic commands
128-131 + [player amount * 4] are drum inputs for gameplay
*/
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
		MODESEL = 8,

		// Drum actions
		DRUM_RIGHT_CENTER = 128,
		DRUM_RIGHT_RIM = 129,
		DRUM_LEFT_CENTER = 130,
		DRUM_LEFT_RIM = 131

}

/// Various size dimensions for GUI elements
enum GUIDimensions {
	TOP_BAR_HEIGHT = 80,
	UNDERLINE_HEIGHT = 8,
	PLAYER_PICKER_LIST_WIDTH = 300,
	BROWSABLELIST_ELM_HEIGHT = 30,
	BROWSABLELIST_DESC_TEXT_SIZE = 24,
	TEXT_SPACING = 10
}

/// GUI Scale sizes
enum GUIScale : float {
	BROWSABLELIST_MAX_HEIGHT = 0.75, // of screen height
}

enum PLAYER_DATA_FILE = "players.json"; /// Filename for the player data file

class OpenTaiko {

	private Engine engine;
	private Renderer renderer;
	private AudioMixer audioMixer;
	private InputHandler inputHandler;
	private int startMenuIndex;
	private int startMenuBinderIndex;
	private int mainMenuIndex;
	private int mainMenuBinderIndex;
	private int gameplaySceneIndex;
	private int gameplayBinderIndex = -1;
	private int menuRenderableIndex;
	private int menuRenderableLayer;
	private int originMenuRenderableIndex;
	private int originMenuRenderableLayer;
	private int extraMenuLayer;

	private DList!Traversable activeMenuStack;
	private DList!Traversable previousMenuStack;

	private Menu topBarMenu;
	private Menu playMenu;
	private Menu playersMenu;
	private Menu playerSelectMenu;
	private Menu settingsMenu;
	private SongSelectMenu songSelectMenu;
	private PlayerDisplay playerDisplay;
	private TextInputField testField;
	private BrowsableList playerSelectList;

	private Song[] songs;
	private Song activeSong;
	private Difficulty activeDifficulty;
	private string[] playerNames;
	private Player*[int] players;
	private Player*[] activePlayers;
	private Performance[] currentPerformances;
	private GameplayArea[] playerAreas;
	private Timer gameplayTimer;
	
	private string inputFieldDest;
	
	static immutable ColorPalette guiColors;

	private bool quit;
	private bool shouldWritePlayerList;
	private bool disablePlayerListWrite;
	
	static this() {
		guiColors = standardPalette;
	}

	public void run() {

		engine = new Engine("OpenTaiko");

		engine.start(1600, 900, true, "OpenTaiko v0.2");

		renderer = engine.gameRenderer();
		audioMixer = engine.aMixer();
		inputHandler = engine.iHandler();
		inputHandler.stopTextEditing();

		loadAssets(engine);
		bindKeys(engine.iHandler);
		songs = MapGen.readSongDatabase(MAP_DIR ~ "maps.json");
		loadPlayers();
		createSongSelectMenu();
		createStartMenu(&startMenuIndex);
		createMainMenu(&mainMenuIndex);
		createGameplayScene();
		//engine.gameRenderer.setScene(startMenuIndex);

		int eventCode;
		while (!quit) {
			eventCode = engine.renderFrame();
			if (eventCode == -1) {
				break;
			}
		}
		
		writeValues();

	}

	/// Initiates gameplay for the selected Song and Difficulty.
	/// The next frames rendered will be those of the gameplay
	void gameplay(Song song, Difficulty diff) {

		if (activePlayers.length < 1) { // in the future, we can autoplay map instead
			throw new Exception("No players registered");
		}
		
		if (gameplayTimer is null) {
			gameplayTimer = Timer.timers[Timer.addTimer()];
		}

		currentPerformances = null;
		for (int i = 0; i < playerAreas.length; i++) {
			Bashable[] map = MapGen.parseMapFromFile(song.title ~ "/" ~ diff.name ~ ".otfm");
			currentPerformances ~= new Performance(song.title, map, gameplayTimer, 0, 0);
			playerAreas[i].setPerformance(currentPerformances[i]);
			//playerAreas[i].setPlayer(players[i], i);
		}
		Text songTitle = new Text(song.artist ~ " - " ~ song.title,
								  renderer.getFont("Noto-Light").get(30),
								  true,
								  GUIDimensions.TEXT_SPACING, 0,
								  guiColors.buttonTextColor);
		
		renderer.getScene(gameplaySceneIndex).clearLayer(1);
		renderer.getScene(gameplaySceneIndex).addRenderable(1, songTitle);
		renderer.setScene(gameplaySceneIndex);
		inputHandler.setActive(gameplayBinderIndex);
		playSong(song);
		Timer.refresh(renderer.getTicks());
		gameplayTimer.set(Timer.libInitPassed);

	}
	
	/// Writes player data, settings and scores to disk
	void writeValues() {
		if (shouldWritePlayerList && !disablePlayerListWrite) {
			shouldWritePlayerList = false;
			MapGen.writePlayerList(players, activePlayers, PLAYER_DATA_FILE);
		}
	}

	void loadAssets(Engine e) {

		e.loadAssets(openTaikoAssets(), ASSET_DIR.DEFAULT);

		renderer.colorTexture("DrumCoreRed", 
							  guiColors.redDrumColor.r, 
							  guiColors.redDrumColor.g,
							  guiColors.redDrumColor.b);
							  
		renderer.colorTexture("DrumCoreBlue", 
							  guiColors.blueDrumColor.r, 
							  guiColors.blueDrumColor.g, 
							  guiColors.blueDrumColor.b);

		BlueDrum.texture = renderer.getTexture("DrumCoreBlue");
		Drum.renderer = renderer.renderer;
		RedDrum.texture = renderer.getTexture("DrumCoreRed");
		NormalDrum.rimTexture = renderer.getTexture("DrumBorder");

	}
	
	void loadPlayers() {
		try {
			players = MapGen.readPlayerList(PLAYER_DATA_FILE);
		} catch (Exception e) {
			Engine.notify("Error loading player list: " 
						  ~ e.msg
						  ~ newline
						  ~ "Player list write has been disabled. "
						  ~ "Please correct the file's formatting.");
			disablePlayerListWrite = true;
		}
		if (players is null) {
			Player* player = new Player("Player", 0, null);
			players[player.id] = player;
		}
		activePlayers ~= players[0]; // temporarily do this
		/*Player* player = new Player();
		player.name = "gtensha";
		player.id = 0;
		player.keybinds = null;
		players ~= player;
		player = new Player();
		player.name = "栄子";
		player.id = 1;
		players ~= player;*/
	}

	void createStartMenu(int* menuIndex) {
		Renderer r = engine.gameRenderer;
		*menuIndex = r.addScene("Start", 1);
		
		r.getScene(*menuIndex).backgroundColor = guiColors.backgroundColor;

		Text titleHeader = new Text("OpenTaiko",
									r.getFont("Noto-Regular").get(36),
									true,
					 				0, 100,
					 				guiColors.buttonTextColor.r, 
									guiColors.buttonTextColor.g, 
									guiColors.buttonTextColor.b, 
									guiColors.buttonTextColor.a);

		titleHeader.rect.x = (getCenterPos(r.windowWidth, titleHeader.rect.w));
		r.getScene(*menuIndex).addRenderable(0, titleHeader);

		Solid lineCenter = new Solid(r.windowWidth, 80, 0, 0,
									 guiColors.uiColorSecondary.r, 
									 guiColors.uiColorSecondary.g, 
									 guiColors.uiColorSecondary.b, 
									 guiColors.uiColorSecondary.a);

		lineCenter.rect.y = (getCenterPos(r.windowHeight, lineCenter.rect.h));
		r.getScene(*menuIndex).addRenderable(0, lineCenter);

		Text centerInfo = new Text("Press any key",
								   r.getFont("Noto-Light").get(24),
								   true,
								   0, 0,
								   240, 240, 240, 255);

		centerInfo.rect.x = (getCenterPos(r.windowWidth, centerInfo.rect.w));
		centerInfo.rect.y = (getCenterPos(r.windowHeight, centerInfo.rect.h));
		r.getScene(*menuIndex).addRenderable(0, centerInfo);
		r.getScene(*menuIndex).addRenderable(0, new Textured(r.getTexture("Soul"), 0, 0));
		r.getScene(*menuIndex).addRenderable(0, new Textured(r.getTexture("NormalDrum"), 100, 100));
		startMenuBinderIndex = engine.iHandler.addActionBinder();
		engine.iHandler.setActive(startMenuBinderIndex);
		engine.iHandler.bindAction(startMenuBinderIndex, Action.SELECT, &switchSceneToMainMenu);
		engine.iHandler.bindAction(startMenuBinderIndex, Action.PAUSE, &quitGame);

	}

	void createMainMenu(int* menuIndex) {
		Renderer r = engine.gameRenderer;
		*menuIndex = r.addScene("Main Menu", 3);
		Scene s = r.getScene(*menuIndex);
		extraMenuLayer = 2;
		
		s.backgroundColor = guiColors.backgroundColor;
		HorizontalTopBarMenu newMenu = new HorizontalTopBarMenu("Banan",
																r.getFont("Noto-Light"),
																160,
																GUIDimensions.TOP_BAR_HEIGHT,
																guiColors.uiColorMain,
																guiColors.buttonTextColor,
																guiColors.uiColorSecondary);

		s.addRenderable(0, new Solid(r.windowWidth,
									 GUIDimensions.TOP_BAR_HEIGHT,
									 0, 0,
									 guiColors.uiColorMain.r,
									 guiColors.uiColorMain.g, 
									 guiColors.uiColorMain.b,
									 guiColors.uiColorMain.a));
		menuRenderableLayer = 0;
		originMenuRenderableLayer = menuRenderableLayer;
		s.addRenderable(0, newMenu);
		topBarMenu = newMenu;
		newMenu.addButton("Play", 0, null, &switchToPlayMenu);
		newMenu.addButton("Players", 1, null, &switchToPlayersMenu);
		newMenu.addButton("Settings", 2, null, &switchToSettingsMenu);								

		playMenu = new VerticalMenu("Play",
									r.getFont("Noto-Light"),
									r.windowWidth / 3,
									60,
									10,
									newMenu.getH + 20,
									guiColors.activeButtonColor,
									guiColors.buttonTextColor);

		menuRenderableIndex = s.addRenderable(0, playMenu);
		originMenuRenderableIndex = menuRenderableIndex;

		playerSelectMenu = new VerticalMenu("Player select",
											r.getFont("Noto-Light"),
											r.windowWidth / 3,
											60,
											10,
											newMenu.getH + 20,
											guiColors.activeButtonColor,
											guiColors.buttonTextColor);
											
		playersMenu = new VerticalMenu("Players",
									   r.getFont("Noto-Light"),
									   r.windowWidth / 3,
									   60,
									   10,
									   GUIDimensions.TOP_BAR_HEIGHT + 20,
									   guiColors.activeButtonColor,
									   guiColors.buttonTextColor);

		BrowsableList testList = new BrowsableList(r.getFont("Noto-Light"),
												   300, 30, 200, 100, 100);
													 
		testList.addButton("List option 1", 0, null, null);
		testList.addButton("List option 2", 1, null, null);
		testList.addButton("List option 3", 2, null, null);
		testList.addButton("List option 4", 3, null, null);
		testList.addButton("List option 5", 4, null, null);
									   
		playerSelectMenu.addButton("Single play", 0, songSelectMenu, null);
		playerSelectMenu.addButton("Multi play", 1, null, null);
		playerSelectMenu.addButton("Back", 2, null, &navigateMenuBack);

		playMenu.addButton("Arcade mode", 0, playerSelectMenu, null);
		playMenu.addButton("High scores", 1, null, null);
		playMenu.addButton("Test text input", 3, null, &testEditing);
		playMenu.addButton("Test BrowseableList", 4, testList, null);
		
		playersMenu.addButton("Add player", 0, null, &popupPlayerSelection);
		playersMenu.addButton("Remove player", 1, null, &popupPlayerRemoveSelection);
		
		testField = new TextInputField(r.getFont("Noto-Bold"),
									   null,
									   null,
									   400, 30,
									   0, r.windowHeight - 60);
												 
		s.addRenderable(0, testField);



		engine.iHandler.setInputBinder(testField.getBindings());
		//playMenu.addButton("TestPopup", 2, null, &notifyMe);

		settingsMenu = new VerticalMenu("Play",
										r.getFont("Noto-Light"),
										r.windowWidth / 3,
										60,
										10,
										newMenu.getH + 20,
										guiColors.activeButtonColor,
										guiColors.buttonTextColor);



		settingsMenu.addButton("Name entry", 0, null, null);
		settingsMenu.addButton("Vsync", 1, null, null);
		
		playerDisplay = new PlayerDisplay(activePlayers,
										  r.getFont("Noto-Light"),
										  (r.windowWidth / 3 * 2),
										  GUIDimensions.TOP_BAR_HEIGHT,
										  r.windowWidth, 0);
										  
		
		s.addRenderable(1, playerDisplay);

		mainMenuBinderIndex = engine.iHandler.addActionBinder();
		inputHandler.bindAction(mainMenuBinderIndex, Action.PAUSE, &navigateMenuBack);
		inputHandler.bindAction(mainMenuBinderIndex, Action.SELECT, &pressMenuButton);
		inputHandler.bindAction(mainMenuBinderIndex, Action.RIGHT, &moveRightMenu);
		inputHandler.bindAction(mainMenuBinderIndex, Action.DOWN, &moveRightMenu);
		inputHandler.bindAction(mainMenuBinderIndex, Action.LEFT, &moveLeftMenu);
		inputHandler.bindAction(mainMenuBinderIndex, Action.UP, &moveLeftMenu);
		inputHandler.bindAction(mainMenuBinderIndex, Action.MODESEL, &navigateTopBarRight);

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

		i.bind(Action.DRUM_RIGHT_CENTER, 'j');
		i.bind(Action.DRUM_RIGHT_RIM,	 'k');
		i.bind(Action.DRUM_LEFT_CENTER,	 'f');
		i.bind(Action.DRUM_LEFT_RIM,	 'd');
	}

	void createSongSelectMenu() {
		int w = 250;
		int h = 325;
		int x = (renderer.windowWidth / 2) - (w / 2);
		int y = renderer.windowHeight - (h + 50);
		songSelectMenu = new SongSelectMenu(renderer,
											&playSong,
											&playSelectedSong,
											renderer.getFont("Noto-Bold"),
											renderer.getFont("Noto-Light"),
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

		if (activePlayers.length < 1) {
			return;
		}
	
		if (playerAreas !is null) {
			playerAreas = null;
		}

		const int w = renderer.windowWidth;
		const int h = renderer.windowHeight / cast(int)activePlayers.length;
		Font font = renderer.getFont("Noto-Regular");
		// TODO: implement vertical split
		for (int i = 0; i < activePlayers.length; i++) {
			const int x = 0;
			const int y = i * (renderer.windowHeight / cast(int)activePlayers.length);
			GameplayArea area = new GameplayArea(renderer,
												 x, y, w, h,
												 font,
												 &playBadSound);
			area.setPlayer(activePlayers[i], i);
			playerAreas ~= area;
		}

		Scene gameplayScene = renderer.getScene(gameplaySceneIndex);
		if (gameplayScene is null || !gameplayScene.name.equal("Gameplay")) {
			gameplayScene = new Scene("Gameplay", 2);
			foreach (GameplayArea gameplayArea ; playerAreas) {
				gameplayScene.addRenderable(0, gameplayArea);
			}

			gameplaySceneIndex = renderer.addScene(gameplayScene);
		} else {
			gameplayScene.clearLayer(0);
			foreach (GameplayArea gameplayArea ; playerAreas) {
				gameplayScene.addRenderable(0, gameplayArea);
			}
		}

		if (gameplayBinderIndex < 1) {
			gameplayBinderIndex = inputHandler.addActionBinder();
			inputHandler.bindAction(gameplayBinderIndex, Action.PAUSE, &switchSceneToMainMenu);
			inputHandler.bindAction(gameplayBinderIndex, Action.DRUM_RIGHT_CENTER, &hitCenterDrum);
			inputHandler.bindAction(gameplayBinderIndex, Action.DRUM_LEFT_CENTER, &hitCenterDrum);
			inputHandler.bindAction(gameplayBinderIndex, Action.DRUM_RIGHT_RIM, &hitRimDrum);
			inputHandler.bindAction(gameplayBinderIndex, Action.DRUM_LEFT_RIM, &hitRimDrum);
		}

	}
	
	/// Makes a selection list and puts it in the active menu stack
	void makeSelectionList(string desc) {
		int w = GUIDimensions.PLAYER_PICKER_LIST_WIDTH;
		int h = cast(int)(GUIScale.BROWSABLELIST_MAX_HEIGHT * renderer.windowHeight);
		int x = (renderer.windowWidth - w) / 2;
		int y = (renderer.windowHeight - h) / 2;
		BrowsableList playerList;
		playerList = new BrowsableList(renderer.getFont("Noto-Light"),
									   w,
									   GUIDimensions.BROWSABLELIST_ELM_HEIGHT,
									   h,
									   x, y);
									   
		previousMenuStack.clear();
		previousMenuStack = activeMenuStack.dup();
		activeMenuStack.clear();
		activeMenuStack.insertFront(playerList);
		
		menuRenderableLayer = originMenuRenderableLayer;
		
		
		Solid shade = new Solid(renderer.windowWidth,
								renderer.windowHeight,
								0, 0,
								guiColors.backgroundColor);

		shade.color.a -= cast(int)(shade.color.a / 2);
		
		Text description;
		description = new Text(desc,
							   renderer.getFont("Noto-Light").get(GUIDimensions.BROWSABLELIST_DESC_TEXT_SIZE),
							   true,
							   playerList.getX, 0,
							   guiColors.buttonTextColor);
							   
		description.rect.y = playerList.getY - description.rect.h;
		
		Scene s = renderer.getScene(mainMenuIndex);
		s.clearLayer(extraMenuLayer);
		s.showLayer(extraMenuLayer);
		s.addRenderable(extraMenuLayer, shade);
		s.addRenderable(extraMenuLayer, description);
		menuRenderableIndex = s.addRenderable(extraMenuLayer, playerList);
		
	}

	static int getCenterPos(int maxWidth, int width) {
		return (maxWidth - width) / 2;
	}
	
	/* --- Various callback functions go under here --- */

	void switchSceneToMainMenu() {
		engine.gameRenderer.setScene(mainMenuIndex);
		engine.iHandler.setActive(mainMenuBinderIndex);
		engine.aMixer.playSFX(0);
		switchToPlayMenu();
	}

	void switchSceneToStartMenu() {
		engine.gameRenderer.setScene(startMenuIndex);
		engine.iHandler.setActive(startMenuBinderIndex);
	}

	void switchSceneToGameplayScene() {
		renderer.setScene(gameplaySceneIndex);
		inputHandler.setActive(gameplayBinderIndex);
		gameplay(activeSong, activeDifficulty);
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
			if (!previousMenuStack.empty) {
				activeMenuStack = previousMenuStack.dup();
				previousMenuStack.clear();
				menuRenderableLayer = originMenuRenderableLayer;
				menuRenderableIndex = originMenuRenderableIndex;
				renderer.getScene(mainMenuIndex).hideLayer(extraMenuLayer);
				updateMainMenu();
			} else {
				switchSceneToStartMenu();
			}
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
	
	void switchToPlayersMenu() {
		activeMenuStack.clear();
		activeMenuStack.insertFront(playersMenu);
		updateMainMenu();
	}
	
	void popupPlayerRemoveSelection() {
		const string message = "Select player to remove";
		bool proceed = true;
		if (activePlayers.length < 1) {
			proceed = false;
		}
		makeSelectionList(proceed ? message : "Add a player first!");
		BrowsableList list = cast(BrowsableList)activeMenuStack.front();
		playerSelectList = list;
		if (!proceed) {
			list.addButton("[Return]", 0, null, &navigateMenuBack);
			return;
		}
		foreach (int i, Player* player ; activePlayers) {
			list.addButton(player.name, i, null, &removeActiveName);
		}
	}
	
	void popupPlayerSelection() {
		makeSelectionList("Select a player...");
		BrowsableList list = cast(BrowsableList)activeMenuStack.front();
		playerSelectList = list;
		list.addButton("[Name entry]", -1, null, &doNameEntry);
		foreach (Player* player ; players) {
			list.addButton(player.name, player.id, null, &selectActiveName);
		}
	}
	
	void removeActiveName() {
		const int i = playerSelectList.getActiveButtonId();
		activePlayers = activePlayers[0 .. i] 
						~ activePlayers[i + 1 .. activePlayers.length];
		playerDisplay.updatePlayers(activePlayers);
		playerSelectMenu = null;
		createGameplayScene();
		navigateMenuBack();
	}
	
	void selectActiveName() {
		activePlayers ~= players[playerSelectList.getActiveButtonId()];
		playerDisplay.updatePlayers(activePlayers);
		playerSelectMenu = null;
		createGameplayScene();
		navigateMenuBack();
	}
	
	void doNameEntry() {
		TextInputField f = new TextInputField(renderer.getFont("Noto-Light"),
											  &addPlayer,
											  &inputFieldDest,
											  400, 30, 0, 0);

		renderer.getScene(mainMenuIndex).addRenderable(extraMenuLayer, f);
		inputHandler.setInputBinder(f.getBindings());
		f.activate();
		inputHandler.enableTextEditing();
	}
	
	void addPlayer() {
		string player = inputFieldDest.dup;
		if (player !is null && player.length > 0) {
			for (int i = 0; i <= 0x7f_ff_ff_ff; i++) {
				if (i !in players) {
					players[i] = new Player(player, i, null);
					activePlayers ~= players[i];
					break;
				}
			}
			playerDisplay.updatePlayers(activePlayers);
			shouldWritePlayerList = true;
			writeValues();
		}
		inputHandler.stopTextEditing();
		navigateMenuBack();
	}
	
	void playSelectedSong() {
		activeSong = songSelectMenu.getSelectedSong();
		activeDifficulty = songSelectMenu.getSelectedDifficulty();
		try {
			gameplay(activeSong, activeDifficulty);
		} catch (Exception e) {
			Engine.notify("Difficulty load failed: " ~ newline ~ e.msg);
		}
	}

	void updateMainMenu() {
		engine.gameRenderer.getScene(mainMenuIndex).setObjectAt(activeMenuStack.front(), 
																menuRenderableLayer, 
																menuRenderableIndex);
	}

	void hitCenterDrum() {
		hitDrum(Drum.Type.RED);
	}

	void hitRimDrum() {
		hitDrum(Drum.Type.BLUE);
	}
	
	void hitDrum(int key) {
		audioMixer.playSFX(key);
		int hitResult = currentPerformances[0].hit(key);
		if (hitResult == Bashable.Success.BAD) {
			playBadSound();
		}
		playerAreas[0].giveHitStatus(hitResult);
	}
	
	void playBadSound() {
		audioMixer.playSFX(2);
	}
	
	void playSong(Song song) {
		audioMixer.pauseMusic();
		if (song.title !in audioMixer.music) {
			try {
				audioMixer.registerMusic(song.title, 
										 MAP_DIR ~ song.title ~ "/" ~ song.src);
			} catch (Exception e) {
				//Engine.notify(e.msg);
				return;
			}
		}
		audioMixer.playTrack(song.title);
		audioMixer.resumeMusic();
	}
	
	void testEditing() {
		testField.activate();
		inputHandler.enableTextEditing();
	}

}
