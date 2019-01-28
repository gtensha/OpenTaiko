module opentaiko.assets;

import maware.assets;

enum ASSET_DIR = "assets/"; /// Folder path for asset directory
enum ASSETS_BGM = "bgm/"; /// Subfolder for background music
enum ASSETS_BGM_TITLE = "title.ogg"; /// Filename for title music loop
enum ASSETS_BGM_MENU = "menu.ogg"; /// Filename for menu music loop
enum ASSETS_DEFAULT = "default/"; /// Default asset folder

static Assets openTaikoAssets() {
	return immutable Assets(
		["DrumBorder"	     : "drum_default_border.png",
		 "DrumCoreRed"	     : "drum_default_core.png",
		 "DrumCoreBlue"	     : "drum_default_core.png",
		 "LargeDrumBorder"   : "drum_large_border.png",
		 "LargeDrumCore"     : "drum_large_core.png",
		 "LargeDrumCoreRed"  : "drum_large_core.png",
		 "LargeDrumCoreBlue" : "drum_large_core.png",
		 "DrumRollStartBorder":"drumroll_start_border.png",
		 "DrumRollStartCore" : "drumroll_start_core.png",
		 "DrumRollBodyBorder": "drumroll_body_border.png",
		 "DrumRollBodyCore"  : "drumroll_body_core.png",
		 "DrumRollEndBorder" : "drumroll_end_border.png",
		 "DrumRollEndCore"   : "drumroll_end_core.png",
		 "Reception"	     : "reception.png",
		 "GoodHitKanji"      : "good_kanji_notify.png",
		 "GoodHitAlpha"      : "good_alpha_notify.png",
		 "OkHitKanji"        : "ok_kanji_notify.png",
		 "OkHitAlpha"        : "ok_alpha_notify.png",
		 "BadHitKanji"       : "bad_kanji_notify.png",
		 "BadHitAlpha"       : "bad_alpha_notify.png",
		 "IndicatorBase"     : "drum_indicator_base.png",
		 "IndicatorLeftRim"  : "drum_indicator_left_rim.png",
		 "IndicatorLeftMid"  : "drum_indicator_left_center.png",
		 "IndicatorRightMid" : "drum_indicator_right_center.png",
		 "IndicatorRightRim" : "drum_indicator_right_rim.png",
		 "Soul" 		     : "soul.png",
		 "Default-Thumb"     : "song-default.png"],

		["Noto-Bold"	     : "NotoSansCJK-Bold.ttc",
		 "Noto-Regular"	     : "NotoSansCJK-Regular.ttc",
		 "Noto-Light"	     : "NotoSansCJK-Light.ttc"],

		["red.wav", //0
		 "blue.wav", //1
		 "miss.wav"]); //2
}
