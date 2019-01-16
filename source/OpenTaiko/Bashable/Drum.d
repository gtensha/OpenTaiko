module opentaiko.bashable.drum;

import maware.renderable : Solid, Textured, Renderable;
import opentaiko.bashable.bashable;

import derelict.sdl2.sdl : SDL_Texture, SDL_Renderer;

/// A subclass of Bashable that acts as a small drum in the game
abstract class Drum : Bashable {

	enum Type : int {
		RED = 0,
		BLUE = 1
	}
	
	enum Side : int {
		LEFT = 0,
		RIGHT = 1
	}
	
	immutable int keyType;

	static SDL_Renderer* renderer;

	this(Solid[] renderables, uint position, double scroll, int keyType) {
		centerObjects(renderables, true, true);
		super(renderables, position, scroll);
		this.keyType = keyType;
	}
	
	override public int hit(int key) {
	
		if (currentOffset < actualPosition() - latestHit) {
			return Success.IGNORE;
		}

		int successType = Success.BAD;
		if (key == this.keyType) {

			if (currentOffset < actualPosition() + goodHit 
				&& 
				currentOffset > actualPosition() - goodHit) {

				successType = Success.GOOD;
			} else if (currentOffset < actualPosition() + latestHit 
					   && 
					   currentOffset > actualPosition() - latestHit) {

				successType = Success.OK;
			}
		}

		return successType;

	}

	override public bool expired() {
		return true;
	}

}

abstract class NormalDrum : Drum {

	static SDL_Texture* rimTexture;

	this(SDL_Texture* texture,
		 int xOffset, int yOffset, uint position, double scroll, int keyType) {

		if (texture is null || rimTexture is null) {
			throw new Exception("Tried to create Drum without assigning texture");
		} else if (renderer is null) {
			throw new Exception("Tried to create Drum without assigning renderer");
		}
		Solid[2] renderables;
		renderables[0] = new Textured(texture,
									  xOffset + cast(int)(position * scroll),
									  yOffset);

		renderables[1] = new Textured(rimTexture,
									  renderables[0].rect.x,
									  renderables[0].rect.y);

		super(renderables, position, scroll, keyType);
	}

	override int hit(int keyType) {
		return super.hit(keyType) | Value.NORMAL;
	}

	override int value() {
		return Value.NORMAL;
	}

}

class RedDrum : NormalDrum {

	static SDL_Texture* texture;

	this(int xOffset, int yOffset, uint position, double scroll) {
		super(texture, xOffset, yOffset, position, scroll, Type.RED);
	}

}

class BlueDrum : NormalDrum {

	static SDL_Texture* texture;

	this(int xOffset, int yOffset, uint position, double scroll) {
		super(texture, xOffset, yOffset, position, scroll, Type.BLUE);
	}

}

abstract class LargeDrum : Drum {

	static SDL_Texture* rimTexture;

	this(SDL_Texture* texture,
		 int xOffset, int yOffset, uint position, double scroll, int keyType) {

		if (texture is null || rimTexture is null) {
			throw new Exception("Tried to create LargeDrum without assigning texture");
		} else if (renderer is null) {
			throw new Exception("Tried to create LargeDrum without assigning renderer");
		}

		Solid[2] renderables;
		renderables[0] = new Textured(texture,
									  xOffset + cast(int)(position * scroll),
									  yOffset);

		renderables[1] = new Textured(rimTexture,
									  renderables[0].rect.x,
									  renderables[0].rect.y);

		super(renderables, position, scroll, keyType);
	}

	override int hit(int keyType) {
		return super.hit(keyType) | Value.LARGE;
	}

	override int value() {
		return Value.LARGE;
	}

}

class LargeRedDrum : LargeDrum {

	static SDL_Texture* texture;

	this(int xOffset, int yOffset, uint position, double scroll) {
		super(texture, xOffset, yOffset, position, scroll, Type.RED);
	}

}

class LargeBlueDrum : LargeDrum {

	static SDL_Texture* texture;

	this(int xOffset, int yOffset, uint position, double scroll) {
		super(texture, xOffset, yOffset, position, scroll, Type.BLUE);
	}

}
