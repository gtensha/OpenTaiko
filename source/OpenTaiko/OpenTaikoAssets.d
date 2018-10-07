module opentaiko.assets;

import maware.assets;

enum ASSET_DIR = "assets/"; /// Folder path for asset directory
enum ASSETS_BGM = "bgm/"; /// Subfolder for background music
enum ASSETS_BGM_TITLE = "title.ogg"; /// Filename for title music loop
enum ASSETS_BGM_MENU = "menu.ogg"; /// Filename for menu music loop
enum ASSETS_DEFAULT = "default/"; /// Default asset folder

static Assets openTaikoAssets() {
	return immutable Assets(["RedDrum" 		 : "red.png",
							 "BlueDrum"		 : "blue.png",
							 "DrumBorder"	 : "drum_default_border.png",
							 "DrumCoreRed"	 : "drum_default_core.png",
							 "DrumCoreBlue"	 : "drum_default_core.png",
							 "Reception"	 : "reception.png",
							 "GoodHit" 		 : "good.png",
							 "OkHit" 		 : "ok.png",
							 "BadHit" 		 : "bad.png",
							 "GoodHitKanji"  : "good_kanji_notify.png",
							 "GoodHitAlpha"  : "good_alpha_notify.png",
							 "OkHitKanji"    : "ok_kanji_notify.png",
							 "OkHitAlpha"    : "ok_alpha_notify.png",
							 "BadHitKanji"   : "bad_kanji_notify.png",
							 "BadHitAlpha"   : "bad_alpha_notify.png",
							 "BlueGrad" 	 : "blue_grad.png",
							 "RedGrad" 		 : "red_grad.png",
							 "Soul" 		 : "soul.png",
							 "Default-Thumb" : "song-default.png"],

							["Roboto-Light"  : "Roboto-Light.ttf",
							 "Roboto-Regular": "Roboto-Regular.ttf",
							 "Noto-Bold"	 : "NotoSansCJK-Bold.ttc",
							 "Noto-Regular"	 : "NotoSansCJK-Regular.ttc",
							 "Noto-Light"	 : "NotoSansCJK-Light.ttc"],

							["red.wav", //0
							 "blue.wav", //1
							 "miss.wav"]); //2
}
