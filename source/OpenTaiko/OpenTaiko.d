module opentaiko.game;

import maware;
import opentaiko.assets;
import opentaiko.bashable;
import opentaiko.difficulty;
import opentaiko.gamevars;
import opentaiko.keybinds;
import opentaiko.languagehandler : Message, phrase;
import opentaiko.mapgen;
import opentaiko.palette;
import opentaiko.performance;
import opentaiko.player;
import opentaiko.renderable.gameplayarea;
import opentaiko.renderable.inputbox;
import opentaiko.renderable.menus.browsablelist : BrowsableList;
import opentaiko.renderable.menus.songselectmenu;
import opentaiko.renderable.playerdisplay;
import opentaiko.renderable.textinputfield;
import opentaiko.score;
import opentaiko.song;
import opentaiko.timingvars;

import std.algorithm.comparison : equal;
import std.array : array, join, split;
import std.ascii : newline;
import std.container.dlist : DList;
import std.conv : to, ConvException;
import std.file : exists, FileException, mkdir;
import std.format : format;
import std.getopt : GetOptException, getopt;
import std.math : sin;
import std.process : environment;
import std.stdio;
import std.string : leftJustify;
import std.typecons : tuple, Tuple;

int main(string[] args) {
	string userDir = "./";
	string installDir;
	bool forceInstall;
	bool help;
	version (Posix) {
		userDir = environment.get("HOME");
		if (userDir.length > 0) {
			userDir ~= "/" ~ USER_DIRECTORY;
		}
	} version (Windows) {
		userDir = environment.get("LOCALAPPDATA");
		if (userDir.length > 0) {
			userDir ~= "\\" ~ USER_DIRECTORY;
		}
	}
	userDir = environment.get(USER_DIRECTORY_ENVVAR, userDir);
	installDir = environment.get(INSTALL_DIRECTORY_ENVVAR);
	string cmdUserDir;
	string cmdInstallDir;
	try {
		getopt(args,
			   USER_DIRECTORY_FLAG, &cmdUserDir,
			   INSTALL_DIRECTORY_FLAG, &cmdInstallDir,
			   FORCE_INSTALL_FLAG, &forceInstall,
			   HELP_FLAG, &help);
	} catch (GetOptException e) {
		writeln(e.msg ~ newline ~ getUsage(args[0]));
		return 1;
	}
	if (help) {
		writeln(getUsage(args[0]));
		return 0;
	}
	if (cmdUserDir.length > 0) {
		userDir = cmdUserDir;
	}
	if (cmdInstallDir.length > 0) {
		installDir = cmdInstallDir;
	}
	foreach (string* s ; [&userDir, &installDir]) {
		version (Windows) {
			const char trailing = '\\';
		} else {
			const char trailing = '/';
		}
		if ((*s).length > 0 && (*s)[s.length - 1] != trailing) {
			*s ~= trailing;
		}
	}
	if (!exists(userDir) || forceInstall) {
		OpenTaiko.userInstall(userDir);
	}
	Engine.initialise();
	OpenTaiko game = new OpenTaiko(installDir, userDir);
	try {
		game.run();
	} catch (Exception e) {
		Engine.notify(e.toString());
		return 1;
	}
	game.destroy();
	Engine.deInitialise();
	return 0;
}

/// Returns the usage message to return on the command line.
private string getUsage(const string binaryName) {
	const size_t padding = INSTALL_DIRECTORY_FLAG.length + 1;
	const string[] flags = [(HELP_FLAG.leftJustify(padding, ' ')
							 ~ "Display this help and quit."),
							(FORCE_INSTALL_FLAG.leftJustify(padding, ' ')
							 ~ "Force writing directory tree to user "
							 ~ "directory (useful after an update)"),
							(INSTALL_DIRECTORY_FLAG
							 ~ " Set the location of the installation "
							 ~ "directory"),
							(USER_DIRECTORY_FLAG.leftJustify(padding, ' ')
							 ~ "Set the location of the user directory")];
	enum FLAG_PREFIX = "  --";
	return format("Usage: %s [OPTIONS...]" ~ newline
				  ~ "Available flags:" ~ newline
				  ~ FLAG_PREFIX
				  ~ flags.join(newline ~ FLAG_PREFIX),
				  binaryName);
}

enum INSTALL_DIRECTORY_ENVVAR = "OPENTAIKO_INSTALLDIR"; /// Environment variable for setting installation directory.
enum USER_DIRECTORY_ENVVAR = "OPENTAIKO_USERDIR"; /// Environment variable for manually setting user directory.

enum FORCE_INSTALL_FLAG = "force-install"; /// Command line flag for forcing a user installation.
enum HELP_FLAG = "help"; /// Flag for displaying help and quitting.
enum INSTALL_DIRECTORY_FLAG = "install-directory"; /// Command line flag for setting the installation directory.
enum USER_DIRECTORY_FLAG = "user-directory"; /// Command line flag for manually setting user directory.

/// The possible inputs recognised by the game.
/// 0-127 are generic commands,
/// 128-131 + [(player amount - 1) * 4] are drum inputs for gameplay.
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
	BROWSABLELIST_DESC_TEXT_SIZE = 24,
	BROWSABLELIST_ELM_HEIGHT = 30,
	PLAYER_PICKER_LIST_WIDTH = 300,
	TEXT_SPACING = 10,
	TOP_BAR_HEIGHT = 80,
	UNDERLINE_HEIGHT = 8,
	VALUEDIAL_HEIGHT = 20
}

/// GUI Scale sizes
enum GUIScale : double {
	BROWSABLELIST_MAX_HEIGHT = 0.75, // of screen height
}

enum DEFAULT_PLAYER_ID = 0; /// Id of "Player", should be guaranteed to exist

enum SCORE_EXTENSION = ".scores";

enum USER_DIRECTORY = ".opentaiko";

enum CONFIG_FILE_PATH = "settings.json"; /// File path for settings file
enum KEYBINDS_FILE_PATH = "keybinds.json"; /// File path for the keybinds file
enum LASTPLAYER_FILE_PATH = "last.player"; /// File path storing last used player
enum PLAYER_DATA_FILE = "players.json"; /// Filename for the player data file
enum TIMINGS_FILE_PATH = "timings.json"; /// File path for timing variables file

/// The game.
class OpenTaiko {

	static struct Copyright {
		enum YEAR_START = 2017;
		enum YEAR_END = 2019;
		enum AUTHORS = ["gtensha"];
	}

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
	private static Player*[int] players;
	private Player*[] activePlayers;
	private Score[][Tuple!(Song, Difficulty)] scores;
	private Keybinds[] playerKeybinds;
	private Performance[] currentPerformances;
	private GameplayArea[] playerAreas;
	private Timer gameplayTimer;

	private string userDirectory = "./";
	private string installDirectory = "./";

	private TimingVars initialTimingVars;
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
	private bool shouldWriteSettings;
	private bool disableSettingsWrite;
	
	static this() {
		guiColors = standardPalette;
	}

	/// Initialises directory by making it if it does not exist, creating the
	/// necessary tree and writing configuration files.
	static void userInstall(const string directory) {
		if (!exists(directory)) {
			mkdir(directory);
		}
		MapGen.writeSongDatabaseTree(directory);
		const string assetDir = directory ~ ASSET_DIR;
		if (!exists(assetDir)) {
			mkdir(assetDir);	
		}
		const string customDir = assetDir ~ ASSETS_CUSTOM;
		if (!exists(customDir)) {
			mkdir(customDir);
		}
		OpenTaiko dummyGame = new OpenTaiko(null, directory);
		dummyGame.loadSettings();
		dummyGame.writeValues();
	}

	this(const string installDir, const string userDir) {
		if (installDir.length > 0) {
			installDirectory = installDir.split("\\").join("/");
		}
		if (userDir.length > 0) {
			userDirectory = userDir.split("\\").join("/");
		}
	}

	~this() {
		engine.destroy();
	}

	/// Runs the game. Loads settings and resources, and draws content on screen
	/// until a quit event code is detected, before writing any altered settings
	/// to disk before returning.
	public void run() {
		engine = new Engine("OpenTaiko");
		loadSettings();
		loadLocales();
		engine.start(options.resolution[0], 
					 options.resolution[1], 
					 options.vsync, 
					 "OpenTaiko v0.2");
		renderer = engine.gameRenderer();
		audioMixer = engine.aMixer();
		inputHandler = engine.iHandler();
		inputHandler.stopTextEditing();
		try {
			loadAssets(engine);
		} catch (Exception e) {
			Engine.notify(format(phrase(Message.Error.LOADING_ASSETS),
								 newline ~ e.toString()));
			return;
		}
		gameplayBinderIndex = inputHandler.addActionBinder();
		bindKeys(engine.iHandler);
		loadPlayers();
		createStartMenu(&startMenuIndex);
		createMainMenu(&mainMenuIndex);
		createGameplayScene();
		loadSongs();
		switchSceneToStartMenu();
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
			throw new Exception(phrase(Message.Error.NO_PLAYER_REGISTERED));
		}
		
		if (gameplayTimer is null) {
			version (SFMLMixer) {
				PreciseTimer t;
				t = new PreciseTimer(cast(long delegate())&audioMixer.getMusicPosition,
									 1_000);
				t.regardlessOffset = Bashable.timing.hitOffset;
				gameplayTimer = t;
			} else {
				gameplayTimer = new Timer();
			}
		}

		currentPerformances = null;
		for (int i = 0; i < playerAreas.length; i++) {
			Bashable[] map = MapGen.parseMapFromFile(song.directory
													 ~ "/"
													 ~ diff.name
													 ~ ".otfm");
			currentPerformances ~= new Performance(song.title, map, gameplayTimer, 0, 0, renderer.windowWidth);
			playerAreas[i].setPerformance(currentPerformances[i]);
		}
		int titleMaxWidth = (playerAreas[0].getScoreDisplayX()
							 - GUIDimensions.TEXT_SPACING);
		Text songTitle = new EllipsedText(song.artist ~ " - " ~ song.title,
										  renderer.getFont("Noto-Light").get(30),
										  true,
										  titleMaxWidth,
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
			MapGen.writePlayerList(players,
								   activePlayers,
								   userDirectory ~ PLAYER_DATA_FILE);
		}
		if (shouldWriteKeybindsList && !disableKeybindsListWrite) {
			shouldWriteKeybindsList = false;
			MapGen.writeKeybindsFile(playerKeybinds,
									 userDirectory ~ KEYBINDS_FILE_PATH);
		}
		if (shouldWriteSettings && !disableSettingsWrite) {
			shouldWriteSettings = false;
			MapGen.writeConfFile(options, userDirectory ~ CONFIG_FILE_PATH);
		}
		if (activePlayers.length > 0) {
			MapGen.writePlayerId(activePlayers[0].id,
								 userDirectory ~ LASTPLAYER_FILE_PATH);
		}
		if (initialTimingVars != Bashable.timing) {
			MapGen.writeTimings(Bashable.timing,
								userDirectory ~ TIMINGS_FILE_PATH);
		}
	}

	/// Loads all the assets required by the game into e.
	void loadAssets(Engine e) {
		immutable Assets getDefaultAssetsOrThrow() {
			try {
				return Assets.findAssets(openTaikoAssets(),
										 getDefaultAssetDir());
			} catch (Exception exception) {
				Engine.notify(format(phrase(Message.Error.MISSING_DEFAULT_ASSET_DIR),
									 newline ~ exception.msg));
				throw exception;
			}
		}
		immutable Assets defaultAssets = getDefaultAssetsOrThrow();
		immutable Assets getCustomMergedAssetsOrThrow() {
			immutable Assets customAssets = Assets.findAssets(openTaikoAssets(),
															  getCustomAssetDir());
			immutable Assets mergedAssets = Assets.combineAssetCollections([defaultAssets,
																			customAssets]);
			const string[] missing = Assets.findMissing(openTaikoAssets(),
														mergedAssets);
			if (missing.length > 0) {
				const errorMsg = format(phrase(Message.Error.MISSING_ASSETS),
										newline ~ missing.join(newline));
				throw new Exception(errorMsg);
			}
			return mergedAssets;
		}
		try {
			immutable Assets mergedAssets = getCustomMergedAssetsOrThrow();
			e.loadAssets(mergedAssets);
		} catch (Exception exception) {
			Engine.notify(format(phrase(Message.Error.MISSING_CUSTOM_ASSET_DIR),
								 newline ~ exception.toString()));
			e.loadAssets(defaultAssets);
		}
		// Drum
		renderer.colorTexture("DrumCoreRed",
							  guiColors.redDrumColor.r,
							  guiColors.redDrumColor.g,
							  guiColors.redDrumColor.b);
		renderer.colorTexture("LargeDrumCoreRed",
							  guiColors.redDrumColor.r,
							  guiColors.redDrumColor.g,
							  guiColors.redDrumColor.b);
		renderer.colorTexture("DrumCoreBlue",
							  guiColors.blueDrumColor.r,
							  guiColors.blueDrumColor.g,
							  guiColors.blueDrumColor.b);
		renderer.colorTexture("LargeDrumCoreBlue",
							  guiColors.blueDrumColor.r,
							  guiColors.blueDrumColor.g,
							  guiColors.blueDrumColor.b);
		Drum.renderer = renderer.renderer;
		DrumRoll.centerColor = guiColors.redDrumColor;
		DrumRoll.rimColor = guiColors.blueDrumColor;
		DrumRoll.noColor = guiColors.cardColor;
		BlueDrum.texture = renderer.getTexture("DrumCoreBlue");
		LargeBlueDrum.texture = renderer.getTexture("LargeDrumCoreBlue");
		RedDrum.texture = renderer.getTexture("DrumCoreRed");
		LargeRedDrum.texture = renderer.getTexture("LargeDrumCoreRed");
		NormalDrum.rimTexture = renderer.getTexture("DrumBorder");
		LargeDrum.rimTexture = renderer.getTexture("LargeDrumBorder");
		// DrumRoll
		DrumRoll.startTextureBorder = renderer.getTexture("DrumRollStartBorder");
		DrumRoll.startTextureCore = renderer.getTexture("DrumRollStartCore");
		DrumRoll.bodyTextureBorder = renderer.getTexture("DrumRollBodyBorder");
		DrumRoll.bodyTextureCore = renderer.getTexture("DrumRollBodyCore");
		DrumRoll.endTextureBorder = renderer.getTexture("DrumRollEndBorder");
		DrumRoll.endTextureCore = renderer.getTexture("DrumRollEndCore");
		// Hit indication effect
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
		// Drumming indicator
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
		foreach (string path ; [(getCustomAssetDir()
								 ~ ASSETS_BGM ~ ASSETS_BGM_TITLE),
		                        (getDefaultAssetDir()
								 ~ ASSETS_BGM ~ ASSETS_BGM_TITLE)]) {
			if (exists(path)) {
				audioMixer.registerMusic("title-loop", path);
				titleMusicEnabled = true;
			}
		}
		foreach (string path ; [(getCustomAssetDir()
								 ~ ASSETS_BGM ~ ASSETS_BGM_MENU),
		                        (getDefaultAssetDir()
								 ~ ASSETS_BGM ~ ASSETS_BGM_MENU)]) {
			if (exists(path)) {
				audioMixer.registerMusic("menu-loop", path);
				menuMusicEnabled = true;
			}
		}
	}

	/// Calls loadLocales() in Message with the current installDirectory, making
	/// localised messages available.
	void loadLocales() {
		Message.loadLocales(installDirectory);
		try {
			Message.setLanguage(options.language);
		} catch (Exception e) {
			Engine.notify(format(phrase(Message.Error.SET_LANGUAGE_LOAD),
								 options.language,
								 e.msg));
		}
	}
	
	/// Loads options from settings.json into the options GameVars struct
	void loadSettings() {
		static int[][4] fallbackKeys = [[100], [102], [106], [107]]; // dfjk
		options.resolution = [1280, 1024];
		options.vsync = true;
		options.assets = ASSETS_CUSTOM;
		options.language = Message.DEFAULT_LANGUAGE;
		if (exists(userDirectory ~ CONFIG_FILE_PATH)) {
			try {
				options = MapGen.readConfFile(userDirectory ~ CONFIG_FILE_PATH,
											  options);
			} catch (Exception e) {
				Engine.notify(format(phrase(Message.Error.LOADING_SETTINGS),
									 CONFIG_FILE_PATH ~ newline ~ e.msg ~ newline));
				disableSettingsWrite = true;
			}
		} else {
			shouldWriteSettings = true;
		}
		Keybinds bindings;
		bindings.keyboard.drumKeys = fallbackKeys;
		if (exists(userDirectory ~ KEYBINDS_FILE_PATH)) {
			try {
				playerKeybinds = MapGen.readKeybindsFile(userDirectory
														 ~ KEYBINDS_FILE_PATH);
			} catch (Exception e) {
				Engine.notify(format(phrase(Message.Error.LOADING_KEYMAPS),
									 e.msg ~ newline,
									 "d f j k"));
				playerKeybinds ~= bindings;
				disableKeybindsListWrite = true;
			}
		} else {
			playerKeybinds ~= bindings;
			shouldWriteKeybindsList = true;
		}
		if (exists(userDirectory ~ TIMINGS_FILE_PATH)) {
			try {
				initialTimingVars = MapGen.readTimings(userDirectory
													   ~ TIMINGS_FILE_PATH);
				Bashable.timing = initialTimingVars;
			} catch (Exception e) {
				Engine.notify(format(phrase(Message.Error.LOADING_TIMINGS),
									 e.toString));
			}
		} else {
			MapGen.writeTimings(Bashable.timing,
								userDirectory ~ TIMINGS_FILE_PATH);
		}
	}

	/// Read players.json and load them into the game, as well as setting the
	/// last active player from last.player as active.
	void loadPlayers() {
		try {
			players = MapGen.readPlayerList(userDirectory ~ PLAYER_DATA_FILE);
		} catch (Exception e) {
			Engine.notify(format(phrase(Message.Error.LOADING_PLAYERLIST)
			                     ~ e.msg ~ newline));
			disablePlayerListWrite = true;
		}
		if (players is null || DEFAULT_PLAYER_ID !in players) {
			Player* player = new Player("Player", DEFAULT_PLAYER_ID, null);
			players[player.id] = player;
		}
		int recentPlayerId;
		try {
			recentPlayerId = MapGen.getPlayerId(userDirectory
												~ LASTPLAYER_FILE_PATH);
		} catch (FileException e) {
			recentPlayerId = DEFAULT_PLAYER_ID;
		} catch (ConvException e) {
			throw e; // Maybe we should handle this scenario? It's too unlikely
		}
		Player** recentPlayer = recentPlayerId in players;
		if (recentPlayer !is null) {
			activePlayers ~= *recentPlayer;
		} else {
			activePlayers ~= players[DEFAULT_PLAYER_ID];
		}
	}

	/// Creates the Start Menu (press any key greeter screen), adds it to the
	/// Renderer and copies the index of its Scene into menuIndex.
	void createStartMenu(int* menuIndex) {
		Renderer r = engine.gameRenderer;
		*menuIndex = r.addScene("Start", 1);
		Scene startScene = r.getScene(*menuIndex);
		startScene.backgroundColor = guiColors.backgroundColor;

		Text titleHeader = new Text(phrase(Message.Title.GAME),
									r.getFont("Noto-Regular").get(36),
									true,
					 				0, 100,
					 				guiColors.buttonTextColor.r, 
									guiColors.buttonTextColor.g, 
									guiColors.buttonTextColor.b, 
									guiColors.buttonTextColor.a);

		titleHeader.rect.x = (getCenterPos(r.windowWidth, titleHeader.rect.w));
		startScene.addRenderable(0, titleHeader);

		Text copyright = new Text(format("© %d–%d  %s",
										 Copyright.YEAR_START,
										 Copyright.YEAR_END,
										 Copyright.AUTHORS.join(", ")),
								  r.getFont("Noto-Light").get(18),
								  true,
								  0, 0,
								  guiColors.buttonTextColor);
		startScene.addRenderable(0, copyright);

		Solid lineCenter = new Solid(r.windowWidth, 80, 0, 0,
									 guiColors.uiColorSecondary.r, 
									 guiColors.uiColorSecondary.g, 
									 guiColors.uiColorSecondary.b, 
									 guiColors.uiColorSecondary.a);

		lineCenter.rect.y = (getCenterPos(r.windowHeight, lineCenter.rect.h));
		startScene.addRenderable(0, lineCenter);

		titleHeader.rect.y = (lineCenter.rect.y / 2) - (titleHeader.rect.h / 2);
		copyright.rect.x = (getCenterPos(r.windowWidth, copyright.rect.w));
		copyright.rect.y = (r.windowHeight
							- (lineCenter.rect.y + lineCenter.rect.h) / 2);

		Text centerInfo = new Text(phrase(Message.Title.GAME_GREETING),
								   r.getFont("Noto-Light").get(24),
								   true,
								   0, 0,
								   guiColors.buttonTextColor);

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
		
		startScene.addAnimatable(new Animation(infoTimer,
											   centerInfo,
											   infoRule));

		centerInfo.rect.x = (getCenterPos(r.windowWidth, centerInfo.rect.w));
		centerInfo.rect.y = (getCenterPos(r.windowHeight, centerInfo.rect.h));
		startScene.addRenderable(0, centerInfo);
		
		startMenuBinderIndex = engine.iHandler.addActionBinder();
		engine.iHandler.setActive(startMenuBinderIndex);
		engine.iHandler.bindAction(startMenuBinderIndex, Action.SELECT, &switchSceneToMainMenu);
		engine.iHandler.bindAction(startMenuBinderIndex, Action.PAUSE, &quitGame);
		engine.iHandler.setAnyKeyAction(startMenuBinderIndex, (int code){if (code == '\033') {quit = true;} else {switchSceneToMainMenu();}});
	}

	/// Populates the main menu and adds itself as a scene to the Renderer, then
	/// copying the index of the menu into menuIndex.
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
		newMenu.addButton(phrase(Message.Menus.TOPBAR_PLAY), 0, null, &switchToPlayMenu);
		newMenu.addButton(phrase(Message.Menus.TOPBAR_PLAYERS), 1, null, &switchToPlayersMenu);
		newMenu.addButton(phrase(Message.Menus.TOPBAR_SETTINGS), 2, null, &switchToSettingsMenu);								

		playMenu = makeStandardMenu("Play");

		menuRenderableIndex = s.addRenderable(0, playMenu);
		originMenuRenderableIndex = menuRenderableIndex;

		playerSelectMenu = makeStandardMenu("Player select");

		playersMenu = makeStandardMenu("Players");

		const void delegate() songSelectPreCheck = (){
			if (songSelectMenu is null) {
				Engine.notify(phrase(Message.Error.NO_MAPS_REGISTERED));
			} else {
				audioMixer.pauseMusic();
			}
		};
		
		playButton = playMenu.addButton(phrase(Message.Menus.PLAY_ARCADEMODE), 0, null, songSelectPreCheck);
		playMenu.addButton(phrase(Message.Menus.PLAY_HIGHSCORES), 1, null, null);
		const void delegate() playerKeybindPreCheck = (){
			if (activePlayers.length < 1) {
				Engine.notify(phrase(Message.Menus.PLAYERS_REMOVEPLAYER_ADDPLAYERFIRST));
			} else {
				popupPlayerKeybindSelection();
			}
		};
		
		playersMenu.addButton(phrase(Message.Menus.PLAYERS_ADDPLAYER), 0, null, &popupPlayerSelection);
		playersMenu.addButton(phrase(Message.Menus.PLAYERS_REMOVEPLAYER), 1, null, &popupPlayerRemoveSelection);
		playersMenu.addButton(phrase(Message.Menus.PLAYERS_KEYBINDS_CHANGE), 2, null, playerKeybindPreCheck);
		Button keybindWipeButton = playersMenu.addButton(phrase(Message.Menus.PLAYERS_KEYBINDS_CLEAR), 3, null, null);
		
		void delegate() makeWipeCallback(int playerNum) {
			return (){clearBindings(playerNum);};
		}
		
		const void delegate() makeKeybindWipeMenu = (){
			Menu wipeMenu = makeStandardMenu("Keybind wipe");
			foreach (int i, Keybinds binds ; playerKeybinds) {
				const string t = phrase(Message.Terminology.PLAYER) ~ " ";
				wipeMenu.addButton(t ~ to!string(i + 1), i, wipeMenu, makeWipeCallback(i));
			}
			keybindWipeButton.subMenu = wipeMenu;
		};
		keybindWipeButton.instruction = makeKeybindWipeMenu;

		settingsMenu = makeStandardMenu("Settings");
		VerticalMenu importMenu = makeStandardMenu("Import...");
		VerticalMenu languageMenu = makeStandardMenu("Language select");
		VerticalMenu timingMenu = makeStandardMenu("Adjust timing");
		
		void delegate() makeLangChangeCallback(string id) {
			return (){changeLanguage(id);};
		}
		
		foreach (int i, string languageOption ; Message.getAvailableLanguages()) {
			languageMenu.addButton(Message.getLanguageName(languageOption), 
			                       i,
			                       languageMenu,
			                       makeLangChangeCallback(languageOption));
		}

		const int c = 4;
		string[c] timingLabels = [phrase(Message.Menus.TIMINGVARS_SET_OFFSET),
								  phrase(Message.Menus.TIMINGVARS_SET_WINDOW),
								  phrase(Message.Menus.TIMINGVARS_SET_GOODWINDOW),
								  phrase(Message.Menus.TIMINGVARS_SET_DEADWINDOW)];
		int[c] initVals = [Bashable.timing.hitOffset,
						   Bashable.timing.hitWindow,
						   Bashable.timing.goodHitWindow,
						   Bashable.timing.preHitDeadWindow];
		void delegate(int)[c] timingCallbacks = [(int v){Bashable.timing.hitOffset = v;},
												 (int v){Bashable.timing.hitWindow = v;},
												 (int v){Bashable.timing.goodHitWindow = v;},
												 (int v){Bashable.timing.preHitDeadWindow = v;}];
		for (int i = 0; i < timingLabels.length; i++) {
			ValueDial!int v = new ValueDial!int(initVals[i],
												int.max,
												int.min,
												[1, 10, 100],
												timingCallbacks[i],
												GUIDimensions.VALUEDIAL_HEIGHT,
												renderer.getFont("Noto-Light"),
												guiColors.buttonTextColor,
												GUIDimensions.TEXT_SPACING,
												(GUIDimensions.TOP_BAR_HEIGHT
												 + GUIDimensions.TEXT_SPACING));
			timingMenu.addButton(timingLabels[i], i, v, null);
		}

		settingsMenu.addButton(phrase(Message.Menus.SETTINGS_IMPORTMAP), 0, importMenu, null);
		settingsMenu.addButton(phrase(Message.Menus.SETTINGS_SONGLIST_RELOAD), 1, null, &loadSongs);
		Button vsyncButton = settingsMenu.addButton(makeVsyncButtonTitle(options.vsync), 2, null, null);
		vsyncButton.instruction = (){toggleVsync(vsyncButton);};
		settingsMenu.addButton(phrase(Message.Menus.SETTINGS_LANGUAGE), 3, languageMenu, null);
		settingsMenu.addButton(phrase(Message.Menus.SETTINGS_TIMINGVARS), 4, timingMenu, null);

		void delegate(int) importCallback = (int mode) {
			try {
				MapGen.extractOSZ(inputFieldDest, userDirectory);
				loadSongs();
			} catch (Exception e) {
				Engine.notify(format(phrase(Message.Error.IMPORTING_MAP), e.toString()));
				return;
			} finally {
				hideTextInputField();
			}
			Engine.notify(phrase(Message.Menus.SETTINGS_IMPORTMAP_SUCCESS));
		};
		
		InputBox pathField;
		pathField = new InputBox(phrase(Message.Menus.SETTINGS_IMPORTMAP_ENTER_PATH),
								 r.getFont("Noto-Light"),
								 {
									inputHandler.stopTextEditing(); 
									importCallback(0);
								 },
								 &hideTextInputField,
								 &inputFieldDest,
								 r.windowWidth - 20, 80,
								 10, r.windowHeight / 2);
								
		importMenu.addButton(phrase(Message.Menus.SETTINGS_IMPORTMAP_OSZ), 0, null, {popupTextInputField(pathField);});
		
		playerDisplay = new PlayerDisplay(activePlayers,
										  r.getFont("Noto-Light"),
										  renderer.windowWidth - topBarMenu.getW,
										  GUIDimensions.TOP_BAR_HEIGHT,
										  r.windowWidth, 0);
										  
		// TODO: easier menu creation...
		
		s.addRenderable(1, playerDisplay);
		
		Text greeting = new Text(phrase(Message.Menus.WELCOMETEXT),
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
			const long passed = timer.getTimerPassed();
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
	
	/// Create and register playerNum's hit delegates
	void bindPlayerKeys(int playerNum, InputHandler i) {
		void delegate() makeHitClosure(int player, int variant, int side) {
			return {hitDrum(player, variant, side);};
		}
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
		
		inputHandler.bindAction(gameplayBinderIndex,
								Action.PAUSE,
								(){postGameWriteScores(); switchSceneToMainMenu();});
		
		for (int playerNum; playerNum < playerKeybinds.length; playerNum++) {
			bindPlayerKeys(playerNum, i);
		}
	}
	
	/// Load songs and update song select menu
	void loadSongs() {
		songs = MapGen.readSongDatabase(userDirectory);
		scores = getScores(songs);
		songSelectMenu = createSongSelectMenu();
		playButton.subMenu = songSelectMenu;
	}

	/// Create a song select menu from the available Songs, find and load
	/// thumnails and return a reference to the menu.
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
		if (songs.length < 1) {
			return null;
		}
		foreach (Song song ; songs) {
			string artPath = MapGen.findImage(song.directory);
			if (artPath !is null) {		
				try {
					renderer.registerTexture("Thumb_" ~ song.title,
											 artPath);
    
					newMenu.addItem(song,
									getSongSpecificScoreList(scores, song),
									renderer.getTexture("Thumb_" ~ song.title));
					continue;
				} catch (Exception e) {}			
			}
			newMenu.addItem(song,
							getSongSpecificScoreList(scores, song),
							renderer.getTexture("Default-Thumb"));			
		}
		return newMenu;
	}

	/// Returns an associative array of arrays of Score structs for each
	/// combination of Song and Difficulty (as the key). Scans the maps/
	/// directory.
	static Score[][Tuple!(Song, Difficulty)] getScores(Song[] songList) {
		Score[][Tuple!(Song, Difficulty)] scores;
		foreach (Song song ; songList) {
			foreach (Difficulty diff ; song.difficulties) {
				const string filePath = (song.directory
										 ~ "/"
										 ~ diff.name
										 ~ SCORE_EXTENSION);
				try {
					scores[tuple(song, diff)] = MapGen.readScores(filePath);
				} catch (Exception e) {
					Engine.notify(format(phrase(Message.Error.LOADING_SCORES),
										 song.title,
										 e.msg));
				}
			}
		}
		return scores;
	}

	/// Returns an associative array of Score structs, filtering list by song.
	static Score[][Difficulty] getSongSpecificScoreList(Score[][Tuple!(Song, Difficulty)] list, Song song) {
		Score[][Difficulty] scoreList;
		foreach (Difficulty diff ; song.difficulties) {
			Score[]* arr = tuple(song, diff) in list;
			if (arr !is null) {
				scoreList[diff] = *arr;
			}
		}
		return scoreList;
	}

	/// Write scores from the previously active game session to disk.
	void postGameWriteScores() {
		string scoreFilePath = (activeSong.directory
								~ "/"
								~ activeDifficulty.name
								~ SCORE_EXTENSION);
		foreach (size_t i, Performance p ; currentPerformances) {
			if (p.finished) {
				Score s = p.getScore(activePlayers[i].id);
				MapGen.writeScore(s, scoreFilePath);
			}
		}
	}

	/// Create a play area for every registered player and add them to
	/// playerAreas, and set the gameplayScene with these playerAreas.
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

	/// Method to create a BrowsableList with standard dimensions and
	/// properties.
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
	
	/// Makes a selection list and puts it in the active menu stack.
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
	
	/// Returns a standard VerticalMenu suitable for the main menu.
	VerticalMenu makeStandardMenu(string title) {
		int maxHeight = (renderer.windowHeight
						 - GUIDimensions.TOP_BAR_HEIGHT
						 - 20);
		return new VerticalMenu(title,
		                        renderer.getFont("Noto-Light"),
		                        renderer.windowWidth / 3,
		                        60,
		                        10,
		                        GUIDimensions.TOP_BAR_HEIGHT + 20,
								maxHeight,
		                        guiColors.activeButtonColor,
		                        guiColors.buttonTextColor);
	}

	/// Sets the language to use in game to id, and enables saving this setting
	/// on quit. id must be a valid language ID defined and loaded in Message.
	void changeLanguage(string id) {
		options.language = id;
		Message.setLanguage(id);
		shouldWriteSettings = true;
	}

	/// Make a button title for the vsync settings button.
	string makeVsyncButtonTitle(bool value) {
		return format(phrase(Message.Menus.SETTINGS_VSYNC), getLocalisedOnOff(value));
	}
	
	string getLocalisedOnOff(bool value) {
		return value ? phrase(Message.Values.ON) : phrase(Message.Values.OFF);
	}
	
	/// Clears the bindings of player number playerNum.
	/// Removes the bindings in playerKeybinds, and unbinds all bound actions
	/// in inputHandler.
	void clearBindings(int playerNum) {
		for (int i = 0; i < 4; i++) {
			playerKeybinds[playerNum].keyboard.drumKeys[i] = null;
		}
		const int baseActionCode = Action.DRUM_LEFT_RIM + DRUM_ACTION_OFFSET * playerNum;
		for (int actionCode = baseActionCode;
		     actionCode < baseActionCode + 4;
		     actionCode++) {

			foreach (int code ; inputHandler.findAssociatedKeys(actionCode)) {
				inputHandler.unbind(code);
			}
		}
	}

	/// Returns a Player struct pointer if a player with id exists, else returns
	/// null.
	static Player* getPlayerById(int id) {
		Player** p = id in players;
		if (p !is null) {
			return *p;
		} else {
			return null;
		}
	}

	static int getCenterPos(int maxWidth, int width) {
		return (maxWidth - width) / 2;
	}

	/// Return the absolute path to the active custom asset directory.
	string getCustomAssetDir() {
		return userDirectory ~ ASSET_DIR ~ options.assets;
	}

	/// Return the absolute path to the default asset directory.
	string getDefaultAssetDir() {
		return installDirectory ~ ASSET_DIR ~ ASSETS_DEFAULT;
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
		if (subMenu == activeMenuStack.front()) {
			activeMenuStack.removeFront();
		} else if (subMenu !is null) {
			activeMenuStack.insertFront(subMenu);
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
		Menu list = makeStandardMenu("Player select");
		activeMenuStack.insertFront(list);
		updateMainMenu();
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
				bindPlayerKeys(playerNum, inputHandler);
				shouldWriteKeybindsList = true;
			}
			lastUsed.setTitle(oldTitle);
			inputHandler.enableBoundActionListen();
		};
		inputHandler.setAnyKeyAction(mainMenuBinderIndex, selectKey);
		foreach (int i, Player* player ; activePlayers) {
			Menu keySelect = makeStandardMenu("Key select");
			if (playerKeybinds.length <= i) {
				Keybinds b;
				playerKeybinds ~= b;
			}
			foreach (int j, string title ; [phrase(Message.Keys.DRUM_RIM_LEFT),
			                                phrase(Message.Keys.DRUM_CENTER_LEFT),
			                                phrase(Message.Keys.DRUM_CENTER_RIGHT),
			                                phrase(Message.Keys.DRUM_RIM_RIGHT)]) {
				int actionCode = Action.DRUM_LEFT_RIM + j + i * DRUM_ACTION_OFFSET;
				int[] boundCodes = playerKeybinds[i].keyboard.drumKeys[j];
				string[] keyNames = new string[boundCodes.length];
				foreach (int ii, int val ; boundCodes) {
					keyNames[ii] = InputHandler.getKeyName(val);
				}
				string extra;
				if (keyNames.length > 0) {
					extra = " [" ~ keyNames.join(", ") ~ "]";
				} else {
					extra = " " ~ phrase(Message.Menus.PLAYERS_KEYBINDS_UNBOUND);
				}
				void delegate() makeKeyCallback(Button button, string altTitle, int keyNumber) {
					return (){
						oldTitle = button.getTitle();
						lastUsed = button;
						button.setTitle(format(phrase(Message.Menus.PLAYERS_KEYBINDS_PRESSKEY), altTitle));
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
		const string message = Message.Menus.PLAYERS_REMOVEPLAYER_CHOOSE.phrase;
		bool proceed = activePlayers.length > 0;
		makeSelectionList(proceed ? message : phrase(Message.Menus.PLAYERS_REMOVEPLAYER_ADDPLAYERFIRST));
		BrowsableList list = cast(BrowsableList)activeMenuStack.front();
		playerSelectList = list;
		if (!proceed) {
			list.addButton(phrase(Message.Menus.PLAYERS_REMOVEPLAYER_RETURN), 0, null, &navigateMenuBack);
			return;
		}
		foreach (int i, Player* player ; activePlayers) {
			list.addButton(player.name, i, null, &removeActiveName);
		}
	}
	
	void popupPlayerSelection() {
		makeSelectionList(phrase(Message.Menus.PLAYERS_ADDPLAYER_SELECT));
		BrowsableList list = cast(BrowsableList)activeMenuStack.front();
		playerSelectList = list;
		list.addButton(phrase(Message.Menus.PLAYERS_ADDPLAYER_NAMEENTRY), -1, null, &doNameEntry);
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
		popupTextInputField(new InputBox(phrase(Message.Menus.PLAYERS_ADDPLAYER_ENTERNAME),
										 renderer.getFont("Noto-Light"),
										 &addPlayer,
										 &hideTextInputField,
										 &inputFieldDest,
										 renderer.windowWidth - 2 * GUIDimensions.TEXT_SPACING,
										 80,
										 GUIDimensions.TEXT_SPACING,
										 renderer.windowHeight / 2));
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
			Engine.notify(format(phrase(Message.Error.LOADING_DIFFICULTY), newline ~ e.toString()));
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
		string songPath = song.directory ~ "/" ~ song.src;
		if (song.src.length < 1) {
			return;
		}
		if (!audioMixer.isRegistered(song.title)) {
			if (!exists(songPath)) {
				return;
			}
			try {
				audioMixer.registerMusic(song.title, 
										 songPath);
			} catch (Exception e) {
				Engine.notify(e.msg);
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
	
	void toggleVsync(Button toAlter) {
		options.vsync = !options.vsync;
		shouldWriteSettings = true;
		const string newLabel = makeVsyncButtonTitle(options.vsync);
		toAlter.setTitle(newLabel);
	}

}
