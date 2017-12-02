module opentaiko.bashable.drum;

import maware.renderable : Solid, Textured, Renderable;
import opentaiko.bashable.bashable;

import derelict.sdl2.sdl : SDL_Texture, SDL_Renderer;

/// A subclass of Bashable that acts as a small drum in the game
abstract class Drum : Bashable {

	enum Type : int {
		RED = 0,
		BLUE = 1
	};

	protected static SDL_Renderer* renderer;
	protected static SDL_Texture* texture;

	this(Solid renderable, uint position, double scroll) {
		super(renderable, position, scroll);
	}

	public static void setTexture(SDL_Renderer* someRenderer,
								  SDL_Texture* someTexture) {
		renderer = someRenderer;
		texture = someTexture;
	}

	override public int hit(int key, int time) {

		if (time < position - latestHit) {
			return Success.IGNORE;
		}

		int successType = Success.BAD;
		if (key == keyType) {

			if (time < position + goodHit && time > position - goodHit) {
				successType = Success.GOOD;
			} else if (time < position + latestHit && time > position - latestHit) {
				successType = Success.OK;
			}
		}

		return successType;

	}

}

abstract class NormalDrum : Drum {

	this(int yOffset, uint position, double scroll) {
		if (texture is null) {
			throw new Exception("Tried to create Drum without assigning texture");
		}
		super(new Textured(renderer,
						   texture,
						   cast(int)(position * scroll),
						   yOffset),
			  position,
			  scroll);
	}

}

class RedDrum : NormalDrum {

	immutable int keyType = Type.RED;

	this(int yOffset, uint position, double scroll) {
		super(yOffset, position, scroll);
	}

}

class BlueDrum : NormalDrum {

	immutable int keyType = Type.BLUE;

	this(int yOffset, uint position, double scroll) {
		super(yOffset, position, scroll);
	}

}
