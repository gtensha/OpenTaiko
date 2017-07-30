import Assets : Assets;

enum ASSET_DIR : string {
	DEFAULT = "assets/default/",
};

static Assets openTaikoAssets() {
	return immutable Assets(["RedDrum" 		 : "red.png",
							 "BlueDrum"		 : "blue.png",
							 "Reception"	 : "reception.png",
							 "GoodHit" 		 : "good.png",
							 "OkHit" 		 : "ok.png",
							 "BadHit" 		 : "bad.png",
							 "BlueGrad" 	 : "blue_grad.png",
							 "RedGrad" 		 : "red_grad.png",
							 "Soul" 		 : "soul.png"],

							["Roboto-Light"  : "Roboto-Light.ttf",
							 "Roboto-Regular": "Roboto-Regular.ttf"],

							["red.wav", //0
							 "blue.wav", //1
							 "miss.wav"]); //2
}
