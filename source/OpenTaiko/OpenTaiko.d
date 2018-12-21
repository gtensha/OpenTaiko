module opentaiko.game;

import maware;
import opentaiko.assets;
import opentaiko.renderable.menus.songselectmenu;
import opentaiko.song;
import opentaiko.difficulty;
import opentaiko.mapgen;
import opentaiko.bashable;
import opentaiko.performance;
import opentaiko.gamevars;
import opentaiko.renderable.gameplayarea;
import opentaiko.palette;
import opentaiko.player;
import opentaiko.playerdisplay;
import opentaiko.textinputfield;
import opentaiko.browsablelist : BrowsableList;
import opentaiko.keybinds;
import opentaiko.renderable.inputbox;

import derelict.sdl2.sdl : SDL_Keycode;

import std.conv : to;
import std.algorithm.comparison : equal;
//import std.algorithm.mutation : copy;
import std.array : array, join;
import std.stdio;
import std.file : exists;
import std.ascii : newline;
import std.container.dlist : DList;
import std.math : sin;

void main(string[] args) {

	Engine.initialise();

	OpenTaiko game = new OpenTaiko();

	try {
		game.run();
	} catch (Throwable e) {
		Engine.notify(e.toString());
		return;
	}

	game.destroy();

	Engine.deInitialise();
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
	DRUM_LEFT_RIM = 128,
	DRUM_LEFT_CENTER = 129,
	DRUM_RIGHT_CENTER = 130,
	DRUM_RIGHT_RIM = 131
}

/// How much the next player's drum action codes are offset from the previous'
enum DRUM_ACTION_OFFSET = 4;

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
enum GUIScale : double {
	BROWSABLELIST_MAX_HEIGHT = 0.75, // of screen height
}

enum PLAYER_DATA_FILE = "players.json"; /// Filename for the player data file
enum CONFIG_FILE_PATH = "settings.json"; /// File path for settings file
enum KEYBINDS_FILE_PATH = "keybinds.json"; /// File path for the keybinds file

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
	private int testSceneIndex;
	private int originMenuRenderableIndex;
	private int originMenuRenderableLayer;
	private int extraMenuLayer;
	private int inputFieldIndex;

	private DList!Traversable activeMenuStack;
	private DList!Traversable previousMenuStack;

	private Menu topBarMenu;
	private Menu playMenu;
	private Menu playersMenu;
	private Menu playerSelectMenu;
	private Menu settingsMenu;
	private SongSelectMenu songSelectMenu;
	private PlayerDisplay playerDisplay;
	private InputBox testField;
	private BrowsableList playerSelectList;
	private Button playButton;
	private void delegate() previousMenuInstruction;

	private Song[] songs;
	private Song activeSong;
	private Difficulty activeDifficulty;
	private string[] playerNames;
	private Player*[int] players;
	private Player*[] activePlayers;
	private Keybinds[] playerKeybinds;
	private Performance[] currentPerformances;
	private GameplayArea[] playerAreas;
	private Timer gameplayTimer;
	private string assetDir = ASSET_DIR ~ ASSETS_DEFAULT;
	
	private GameVars options;
	private bool titleMusicEnabled;
	private bool menuMusicEnabled;
	
	private string inputFieldDest;
	
	static immutable ColorPalette guiColors;

	private bool quit;
	private bool shouldWritePlayerList;
	private bool disablePlayerListWrite;
	private bool shouldWriteKeybindsList;
	private bool disableKeybindsListWrite;
	
	static this() {
		guiColors = standardPalette;
	}

	~this() {
		engine.destroy();
	}

	public void run() {

		engine = new Engine("OpenTaiko");
		
		loadSettings();

		engine.start(options.resolution[0], 
					 options.resolution[1], 
					 options.vsync, 
					 "OpenTaiko v0.2");

		renderer = engine.gameRenderer();
		audioMixer = engine.aMixer();
		inputHandler = engine.iHandler();
		inputHandler.stopTextEditing();

		loadAssets(engine);
		gameplayBinderIndex = inputHandler.addActionBinder();
		bindKeys(engine.iHandler);
		loadPlayers();
		createStartMenu(&startMenuIndex);
		createMainMenu(&mainMenuIndex);
		createGameplayScene();
		loadSongs();
		switchSceneToStartMenu();
		//engine.gameRenderer.setScene(startMenuIndex);

		int eventCode;
		while (!quit) {
			eventCode = engine.renderFrame();
			if (eventCode == InputHandler.QUIT_EVENT_CODE) {
				quit = true;
			}
		}
		
		writeValues();

	}

	/// Initiates gameplay for the selected Song and Difficulty.
	/// The next frames rendered will be those of the gameplay
	void gameplay(Song song, Difficulty diff) {

		if (activePlayers.length < 1) { // TODO: in the future, we can autoplay map instead
			throw new Exception("No players registered");
		}
		
		if (gameplayTimer is null) {
			version (SFMLMixer) {
				gameplayTimer = new PreciseTimer(&audioMixer.getMusicPosition, 1_000);
			} else {
				gameplayTimer = new Timer();
			}
		}

		currentPerformances = null;
		for (int i = 0; i < playerAreas.length; i++) {
			Bashable[] map = MapGen.parseMapFromFile(song.directory ~ "/" ~ diff.name ~ ".otfm");
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
		if (shouldWriteKeybindsList && !disableKeybindsListWrite) {
			shouldWriteKeybindsList = false;
			MapGen.writeKeybindsFile(playerKeybinds, KEYBINDS_FILE_PATH);
		}
	}

	void loadAssets(Engine e) {

		e.loadAssets(openTaikoAssets(), assetDir);

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
		
		renderer.colorTexture("GoodHitKanji",
		                      guiColors.goodNotifyColor.r,
							  guiColors.goodNotifyColor.g,
							  guiColors.goodNotifyColor.b);
							  
		renderer.colorTexture("GoodHitAlpha",
		                      guiColors.goodNotifyColor.r,
							  guiColors.goodNotifyColor.g,
		                      guiColors.goodNotifyColor.b);
							  
		renderer.colorTexture("OkHitKanji",
		                      guiColors.okNotifyColor.r,
							  guiColors.okNotifyColor.g,
		                      guiColors.okNotifyColor.b);
		
		renderer.colorTexture("OkHitAlpha",
							  guiColors.okNotifyColor.r,
							  guiColors.okNotifyColor.g,
		                      guiColors.okNotifyColor.b);
							  
		renderer.colorTexture("BadHitKanji",
							  guiColors.badNotifyColor.r,
							  guiColors.badNotifyColor.g,
							  guiColors.badNotifyColor.b);
							  
		renderer.colorTexture("BadHitAlpha",
							  guiColors.badNotifyColor.r,
							  guiColors.badNotifyColor.g,
		                      guiColors.badNotifyColor.b);
							  
		renderer.colorTexture("IndicatorLeftMid", 
							guiColors.redDrumColor.r, 
							guiColors.redDrumColor.g,
							guiColors.redDrumColor.b);

		renderer.colorTexture("IndicatorLeftRim", 
		                      guiColors.blueDrumColor.r, 
							  guiColors.blueDrumColor.g, 
		                      guiColors.blueDrumColor.b);
							  
		renderer.colorTexture("IndicatorRightMid", 
		                      guiColors.redDrumColor.r, 
							  guiColors.redDrumColor.g,
		                      guiColors.redDrumColor.b);
							  
		renderer.colorTexture("IndicatorRightRim", 
		                      guiColors.blueDrumColor.r, 
		                      guiColors.blueDrumColor.g, 
		                      guiColors.blueDrumColor.b);

		foreach (string path ; [assetDir ~ ASSETS_BGM ~ ASSETS_BGM_TITLE, 
		                        ASSET_DIR ~ ASSETS_DEFAULT ~ ASSETS_BGM ~ ASSETS_BGM_TITLE]) {
			if (exists(path)) {
				audioMixer.registerMusic("title-loop", path);
				titleMusicEnabled = true;
			}
		}
		foreach (string path ; [assetDir ~ ASSETS_BGM ~ ASSETS_BGM_MENU, 
		                        ASSET_DIR ~ ASSETS_DEFAULT ~ ASSETS_BGM ~ ASSETS_BGM_MENU]) {
			if (exists(path)) {
				audioMixer.registerMusic("menu-loop", path);
				menuMusicEnabled = true;
			}
		}
	}
	
	/// Loads options from settings.json into the options GameVars struct
	void loadSettings() {
		static int[][4] fallbackKeys = [[100], [102], [106], [107]]; // dfjk
		try {
			options = MapGen.readConfFile(CONFIG_FILE_PATH);
		} catch (Exception e) {
			Engine.notify("Failed to load settings from " ~ CONFIG_FILE_PATH
						  ~ newline ~ e.msg
						  ~ newline ~ "Using fallback settings");
						  
			//options.defaultKeys = fallbackKeys;
			options.resolution = [1280, 1024];
			options.vsync = true;
		}
		
		try {
			playerKeybinds = MapGen.readKeybindsFile(KEYBINDS_FILE_PATH);
		} catch (Exception e) {
			Engine.notify("Failed to load key mappings from " ~ KEYBINDS_FILE_PATH
						  ~ newline ~ e.msg
						  ~ newline ~ "Using fallback keys (d f j k)");
			Keybinds bindings;
			bindings.keyboard.drumKeys = fallbackKeys;
			playerKeybinds ~= bindings;
			disableKeybindsListWrite = true;
		}
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

		IntervalTimer infoTimer = new IntervalTimer();
		infoTimer.setInterval(1000);
		immutable int w = centerInfo.rect.w;
		immutable int h = centerInfo.rect.h;
		void delegate(Timer, Solid) infoRule = (Timer timer, Solid solid){
			const double percentage = timer.getPercentagePassed();
			if (percentage >= 75) {
				solid.rect.w = 0;
				solid.rect.h = 0;
			} else {
				solid.rect.w = w;
				solid.rect.h = h;
			}
		};
		
		r.getScene(*menuIndex).addAnimatable(new Animation(infoTimer,
														   centerInfo,
														   infoRule));
								   
		centerInfo.rect.x = (getCenterPos(r.windowWidth, centerInfo.rect.w));
		centerInfo.rect.y = (getCenterPos(r.windowHeight, centerInfo.rect.h));
		r.getScene(*menuIndex).addRenderable(0, centerInfo);
		
		Textured soul = new Textured(r.getTexture("Soul"), 0, 0);
		IntervalTimer soulTimer = new IntervalTimer();
		soulTimer.setInterval(1000);
		void delegate(Timer, Solid) soulRule = (Timer timer, Solid solid){
			const double percentage = timer.getPercentagePassed();
			solid.rect.y = cast(int)(20 + (100 * sin(0.03142 * percentage)));
		};
		r.getScene(*menuIndex).addAnimatable(new Animation(soulTimer,
														   soul,
														   soulRule));
		
		r.getScene(*menuIndex).addRenderable(0, soul);
		
		startMenuBinderIndex = engine.iHandler.addActionBinder();
		engine.iHandler.setActive(startMenuBinderIndex);
		engine.iHandler.bindAction(startMenuBinderIndex, Action.SELECT, &switchSceneToMainMenu);
		engine.iHandler.bindAction(startMenuBinderIndex, Action.PAUSE, &quitGame);
		engine.iHandler.setAnyKeyAction(startMenuBinderIndex, (int code){if (code == '\033') {quit = true;} else {switchSceneToMainMenu();}});

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
		previousMenuInstruction = &switchToPlayMenu;
		newMenu.addButton("Play", 0, null, &switchToPlayMenu);
		newMenu.addButton("Players", 1, null, &switchToPlayersMenu);
		newMenu.addButton("Settings", 2, null, &switchToSettingsMenu);								

		playMenu = makeStandardMenu("Play");

		menuRenderableIndex = s.addRenderable(0, playMenu);
		originMenuRenderableIndex = menuRenderableIndex;

		playerSelectMenu = makeStandardMenu("Player select");

		playersMenu = makeStandardMenu("Players");

		BrowsableList testList = new BrowsableList(r.getFont("Noto-Light"),
												   300, 30, 200, 100, 100);
		
		testField = new InputBox("TestBox",
								 r.getFont("Noto-Bold"),
								 {
									inputHandler.stopTextEditing(); 
									renderer.getScene(mainMenuIndex).clearLayer(extraMenuLayer);
								 },
								 &hideTextInputField,
								 null,
								 r.windowWidth - 20, 80,
								 10, r.windowHeight / 2);
													 
		testList.addButton("List option 1", 0, null, null);
		testList.addButton("List option 2", 1, null, null);
		testList.addButton("List option 3", 2, null, null);
		testList.addButton("List option 4", 3, null, null);
		testList.addButton("List option 5", 4, null, null);

		playButton = playMenu.addButton("Arcade mode", 0, null, &audioMixer.pauseMusic);
		playMenu.addButton("High scores", 1, null, null);
		playMenu.addButton("Test text input", 3, null, {popupTextInputField(testField);});
		playMenu.addButton("Test BrowseableList", 4, testList, null);
		
		playersMenu.addButton("Add player", 0, null, &popupPlayerSelection);
		playersMenu.addButton("Remove player", 1, null, &popupPlayerRemoveSelection);
		playersMenu.addButton("Change keybinds", 2, null, &popupPlayerKeybindSelection);
												 
		//s.addRenderable(0, testField);

		//engine.iHandler.setInputBinder(testField.inputField.getBindings());
		//playMenu.addButton("TestPopup", 2, null, &notifyMe);

		settingsMenu = makeStandardMenu("Settings");
		VerticalMenu importMenu = makeStandardMenu("Import...");

		settingsMenu.addButton("Import map", 0, importMenu, null);
		settingsMenu.addButton("Reload song list", 1, null, &loadSongs);
		settingsMenu.addButton("Vsync", 2, null, null);

		void delegate(int) importCallback = (int mode) {
			try {
				MapGen.extractOSZ(inputFieldDest);
				loadSongs();
			} catch (Exception e) {
				Engine.notify("Failed to import map: " ~ e.toString());
				return;
			}
			Engine.notify("Map successfully imported.");
		};
		
		InputBox pathField;
		pathField = new InputBox("Enter path to file (or CTRL+V/SHIFT+INSERT)",
								 r.getFont("Noto-Light"),
								 {
									inputHandler.stopTextEditing(); 
									importCallback(0);
								 },
								 &hideTextInputField,
								 &inputFieldDest,
								 r.windowWidth - 20, 80,
								 10, r.windowHeight / 2);
								
		importMenu.addButton("Import from .osz", 0, null, {popupTextInputField(pathField);});
		
		playerDisplay = new PlayerDisplay(activePlayers,
										  r.getFont("Noto-Light"),
										  (r.windowWidth / 3 * 2),
										  GUIDimensions.TOP_BAR_HEIGHT,
										  r.windowWidth, 0);
										  
		// TODO: easier menu creation...
		
		s.addRenderable(1, playerDisplay);
		
		Text greeting = new Text("Welcome to OpenTaiko!",
								 renderer.getFont("Noto-Light").get(24),
								 true,
								 0, 0,
								 guiColors.buttonTextColor);
		
		greeting.rect.y = renderer.windowHeight - greeting.rect.h - 1;
		greeting.rect.x = renderer.windowWidth;
		
		Timer dummyTimer = new Timer();
		immutable int initX = renderer.windowWidth;
		immutable int minX = 0 - greeting.rect.w;
		void delegate(Timer, Solid) greetingRule = (Timer timer, Solid solid){
			const int passed = timer.getTimerPassed();
			if (passed < 12) {
				return;
			}

			solid.rect.x -= passed / 12;
			if (solid.rect.x < minX) {
				solid.rect.x = initX;
			}
			timer.set(Timer.libInitPassed);
		};
		
		s.addRenderable(1, greeting);
		s.addAnimatable(new Animation(dummyTimer,
									  greeting,
									  greetingRule));

		mainMenuBinderIndex = engine.iHandler.addActionBinder();
		inputHandler.bindAction(mainMenuBinderIndex, Action.PAUSE, &navigateMenuBack);
		inputHandler.bindAction(mainMenuBinderIndex, Action.SELECT, &pressMenuButton);
		inputHandler.bindAction(mainMenuBinderIndex, Action.RIGHT, &moveRightMenu);
		inputHandler.bindAction(mainMenuBinderIndex, Action.DOWN, &moveRightMenu);
		inputHandler.bindAction(mainMenuBinderIndex, Action.LEFT, &moveLeftMenu);
		inputHandler.bindAction(mainMenuBinderIndex, Action.UP, &moveLeftMenu);
		inputHandler.bindAction(mainMenuBinderIndex, Action.MODESEL, &navigateTopBarRight);

	}

	/// Bind input actions and player keybindings from the playerKeybinds array
	void bindKeys(InputHandler i) {
		// TODO: rebindable action keys
		i.bind(Action.RIGHT, 	1073741903);
		i.bind(Action.LEFT, 	1073741904);
		i.bind(Action.DOWN, 	1073741905);
		i.bind(Action.UP, 		1073741906);
		i.bind(Action.SELECT, 	'\r');
		i.bind(Action.BACK, 	'\b');
		i.bind(Action.MODESEL,	'\t');
		i.bind(Action.PAUSE,	'\033');
		
		void delegate() makeHitClosure(int player, int variant, int side) {
			return {hitDrum(player, variant, side);};
		}
		
		inputHandler.bindAction(gameplayBinderIndex, Action.PAUSE, &switchSceneToMainMenu);
		
		for (int playerNum; playerNum < playerKeybinds.length; playerNum++) {
			const int offset = playerNum * DRUM_ACTION_OFFSET;
			int[] actionCodes = [Action.DRUM_LEFT_RIM,
			                     Action.DRUM_LEFT_CENTER,
								 Action.DRUM_RIGHT_CENTER,
								 Action.DRUM_RIGHT_RIM];
			foreach (int drumNum, int actionCode ; actionCodes) {
				foreach (int keyCode ; playerKeybinds[playerNum].keyboard.drumKeys[drumNum]) {
					i.bind(actionCode + offset, keyCode);
				}
			}
			void delegate() hitRimLeft = makeHitClosure(playerNum, Drum.Type.BLUE, Drum.Side.LEFT);
			void delegate() hitCenterLeft = makeHitClosure(playerNum, Drum.Type.RED, Drum.Side.LEFT);
			void delegate() hitCenterRight = makeHitClosure(playerNum, Drum.Type.RED, Drum.Side.RIGHT);
			void delegate() hitRimRight = makeHitClosure(playerNum, Drum.Type.BLUE, Drum.Side.RIGHT);
			i.bindAction(gameplayBinderIndex, Action.DRUM_RIGHT_CENTER + offset, hitCenterRight);
			i.bindAction(gameplayBinderIndex, Action.DRUM_LEFT_CENTER + offset, hitCenterLeft);
			i.bindAction(gameplayBinderIndex, Action.DRUM_RIGHT_RIM + offset, hitRimRight);
			i.bindAction(gameplayBinderIndex, Action.DRUM_LEFT_RIM + offset, hitRimLeft);
		}
	}
	
	/// Load songs and update song select menu
	void loadSongs() {
		songs = MapGen.readSongDatabase();
		songSelectMenu = createSongSelectMenu();
		playButton.subMenu = songSelectMenu;
	}

	SongSelectMenu createSongSelectMenu() {
		int w = 250;
		int h = 325;
		int x = (renderer.windowWidth / 2) - (w / 2);
		int y = renderer.windowHeight - (h + 50);
		SongSelectMenu newMenu;
		newMenu = new SongSelectMenu(renderer,
									 &playSong,
									 &playSelectedSong,
									 renderer.getFont("Noto-Bold"),
									 renderer.getFont("Noto-Light"),
									 x, y, w, h);
		foreach (Song song ; songs) {
			string artPath = MapGen.findImage(song.directory);
			if (artPath !is null) {		
				try {
					renderer.registerTexture("Thumb_" ~ song.title,
											 artPath);
    
					newMenu.addItem(song, renderer.getTexture("Thumb_" ~ song.title));
					continue;
				} catch (Exception e) {}			
			}
			newMenu.addItem(song, renderer.getTexture("Default-Thumb"));			
		}
		return newMenu;
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

	}
	
	BrowsableList createList() {
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

		return playerList;
	}
	
	/// Makes a selection list and puts it in the active menu stack
	void makeSelectionList(string description) {
		Text makeText(string desc, BrowsableList playerList) {
			Text descriptionText;
			descriptionText = new Text(desc,
								       renderer.getFont("Noto-Light").get(GUIDimensions.BROWSABLELIST_DESC_TEXT_SIZE),
								       true,
								       playerList.getX, 0,
								       guiColors.buttonTextColor);
								   
			descriptionText.rect.y = playerList.getY - descriptionText.rect.h;
			return descriptionText;
		}
		
		BrowsableList playerList = createList();
		Text descriptionText = makeText(description, playerList);
		
		Solid shade = new Solid(renderer.windowWidth,
								renderer.windowHeight,
								0, 0,
								guiColors.backgroundColor);
		
		shade.color.a -= cast(int)(shade.color.a / 2);
		
		Scene s = renderer.getScene(mainMenuIndex);
		s.clearLayer(extraMenuLayer);
		s.showLayer(extraMenuLayer);
		s.addRenderable(extraMenuLayer, shade);
		s.addRenderable(extraMenuLayer, descriptionText);
		menuRenderableIndex = s.addRenderable(extraMenuLayer, playerList);
		
	}
	
	/// Returns a standard VerticalMenu suitable for the main menu
	VerticalMenu makeStandardMenu(string title) {
		return new VerticalMenu(title,
		                        renderer.getFont("Noto-Light"),
		                        renderer.windowWidth / 3,
		                        60,
		                        10,
		                        GUIDimensions.TOP_BAR_HEIGHT + 20,
		                        guiColors.activeButtonColor,
		                        guiColors.buttonTextColor);
	}

	static int getCenterPos(int maxWidth, int width) {
		return (maxWidth - width) / 2;
	}
	
	/* --- Various callback functions go under here --- */

	void switchSceneToMainMenu() {
		engine.gameRenderer.setScene(mainMenuIndex);
		engine.iHandler.setActive(mainMenuBinderIndex);
		engine.iHandler.enableBoundActionListen();
		engine.aMixer.playSFX(0);
		if (menuMusicEnabled) {
			audioMixer.stopMusic();
			audioMixer.playTrackLooped("menu-loop");
		}
		previousMenuInstruction();
	}

	void switchSceneToStartMenu() {
		engine.gameRenderer.setScene(startMenuIndex);
		engine.iHandler.setActive(startMenuBinderIndex);
		engine.iHandler.enableAnyKeyListen();
		if (titleMusicEnabled) {
			audioMixer.stopMusic();
			audioMixer.playTrackLooped("title-loop");
		}
	}

	void switchSceneToGameplayScene() {
		renderer.setScene(gameplaySceneIndex);
		inputHandler.setActive(gameplayBinderIndex);
		gameplay(activeSong, activeDifficulty);
	}
	
	void switchSceneToTestScene() {
		engine.gameRenderer.setScene(testSceneIndex);
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
		previousMenuInstruction = &switchToPlayMenu;
		activeMenuStack.clear();
		activeMenuStack.insertFront(playMenu);
		updateMainMenu();
	}

	void switchToSettingsMenu() {
		previousMenuInstruction = &switchToSettingsMenu;
		activeMenuStack.clear();
		activeMenuStack.insertFront(settingsMenu);
		updateMainMenu();
	}
	
	void switchToPlayersMenu() {
		previousMenuInstruction = &switchToPlayersMenu;
		activeMenuStack.clear();
		activeMenuStack.insertFront(playersMenu);
		updateMainMenu();
	}
	
	void popupPlayerKeybindSelection() {
		//makeSelectionList("Select a player to change keybinds");
		Menu list = makeStandardMenu("Player select");
		activeMenuStack.insertFront(list);
		updateMainMenu();
		//Text keyDescription = makeSelectionList.makeText("Select key", keySelect);
		int playerNum = 0;
		int keyNum = 0;
		void delegate() selectPlayer = (){
			playerNum = list.getActiveButtonId();
		};
		string oldTitle;
		Button lastUsed;
		void delegate(int) selectKey = (int keyCode){
			if (keyCode != '\033') {
				playerKeybinds[playerNum].keyboard.drumKeys[keyNum] ~= keyCode;
				inputHandler.bind(Action.DRUM_LEFT_RIM + keyNum + playerNum * DRUM_ACTION_OFFSET, keyCode);
				shouldWriteKeybindsList = true;
			}
			lastUsed.setTitle(oldTitle);
			inputHandler.enableBoundActionListen();
		};
		inputHandler.setAnyKeyAction(mainMenuBinderIndex, selectKey);
		foreach (int i, Player* player ; activePlayers) {
			Menu keySelect = makeStandardMenu("Key select");
			foreach (int j, string title ; ["Left Rim", "Left Center", "Right Center", "Right Rim"]) {
				int actionCode = Action.DRUM_LEFT_RIM + j + i * DRUM_ACTION_OFFSET;
				int[] boundCodes = playerKeybinds[i].keyboard.drumKeys[j];
				string[] keyNames = new string[boundCodes.length];
				foreach (int ii, int val ; boundCodes) {
					keyNames[ii] = InputHandler.getKeyName(val);
				}
				string extra = keyNames.length > 0 ? " [" ~ keyNames.join(", ") ~ "]" : "";
				void delegate() makeKeyCallback(Button button, string altTitle, int keyNumber) {
					return (){
						oldTitle = button.getTitle();
						lastUsed = button;
						button.setTitle("Press a key for \"" ~ altTitle ~ "\" (ESC cancels)...");
						keyNum = keyNumber;
						inputHandler.enableAnyKeyListen();
					};
				}
				Button button = keySelect.addButton(title ~ extra, j, null, null);
				button.instruction = makeKeyCallback(button, title, j);
			}
			list.addButton("[P" ~ to!string(i + 1) ~ "] " ~ player.name, i, keySelect, selectPlayer);
		}
	}

	void popupPlayerRemoveSelection() {
		const string message = "Select player to remove";
		bool proceed = activePlayers.length > 0;
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
		popupTextInputField(new InputBox("Enter player name",
										 renderer.getFont("Noto-Light"),
										 &addPlayer,
										 &hideTextInputField,
										 &inputFieldDest,
										 renderer.windowWidth - 2 * GUIDimensions.TEXT_SPACING,
										 80,
										 GUIDimensions.TEXT_SPACING,
										 renderer.windowHeight / 2));
		/*TextInputField f = new TextInputField(renderer.getFont("Noto-Light"),
											  &addPlayer,
											  &inputFieldDest,
											  400, 30, 0, 0);

		renderer.getScene(mainMenuIndex).addRenderable(extraMenuLayer, f);
		inputHandler.setInputBinder(f.getBindings());
		f.activate();
		inputHandler.enableTextEditing();*/
	}
	
	/// Show the box on screen and activate it
	void popupTextInputField(InputBox box) {
		inputFieldIndex = renderer.getScene(mainMenuIndex).addRenderable(extraMenuLayer, box);
		inputHandler.setInputBinder(box.inputField.getBindings());
		box.inputField.activate();
		inputHandler.enableTextEditing();
	}
	
	/// Hide the displayed text box. inputFieldIndex must be set before call!
	void hideTextInputField() {
		renderer.getScene(mainMenuIndex).removeRenderable(extraMenuLayer, 
														  inputFieldIndex);
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
		hideTextInputField();
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
		hitDrum(0, Drum.Type.RED, Drum.Side.LEFT);
	}

	void hitRimDrum() {
		hitDrum(0, Drum.Type.BLUE, Drum.Side.LEFT);
	}
	
	void hitDrum(int playerNum, int key, int side) {
		audioMixer.playSFX(key);
		if (playerNum > currentPerformances.length - 1) {
			return;		
		}		
		Performance current = currentPerformances[playerNum];
		int hitResult;
		if (!current.finished) {
			hitResult = current.hit(key);
		} else {
			hitResult = Bashable.Success.IGNORE;
		}
			
		if (hitResult == Bashable.Success.BAD) {
			playBadSound();
		}
		playerAreas[playerNum].giveHitStatus(hitResult);
		int hitKey;
		if (side == Drum.Side.LEFT) {
			hitKey = key == 0 ? 1 : 0;
		} else {
			hitKey = key + 2;
		}
		playerAreas[playerNum].giveDrumHit(hitKey);
	}
	
	void playBadSound() {
		audioMixer.playSFX(2);
	}
	
	void playSong(Song song) {
		audioMixer.stopMusic();
		if (!audioMixer.isRegistered(song.title)) {
			try {
				audioMixer.registerMusic(song.title, 
										 song.directory ~ "/" ~ song.src);
			} catch (Exception e) {
				//Engine.notify(e.msg);
				return;
			}
		}
		audioMixer.playTrack(song.title, 1);
		audioMixer.resumeMusic();
	}
	
	void testEditing() {
		testField.inputField.activate();
		inputHandler.enableTextEditing();
	}

}
