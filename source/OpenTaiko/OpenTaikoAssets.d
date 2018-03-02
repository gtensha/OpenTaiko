module opentaiko.assets;

import maware.assets;

enum ASSET_DIR : string {
	DEFAULT = "assets/default/",
};

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
