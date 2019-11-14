//  This file is part of the OpenTaiko project.
//  <https://github.com/gtensha/OpenTaiko>
//
/// Drum hit objects of all colours and sizes. Only objects that are strictly
/// drums should be in this module.
///
/// Authors: gtensha (@skyhvelv.net)
/// Copyright: 2017-2019 gtensha
/// License: GNU GPLv3 (no later versions)
//
//  You should have received a copy of the GNU General Public License
//  along with OpenTaiko. If not, see <https://www.gnu.org/licenses/>.

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

	protected bool wasHit;

	static SDL_Renderer* renderer;

	this(Solid[] renderables, uint position, double scroll, int keyType) {
		centerObjects(renderables, true, true);
		super(renderables, position, scroll);
		this.keyType = keyType;
	}
	
	override public int hit(int key) {
		const int lateValue = actualPosition() - timing.hitWindow;
		if (currentOffset < lateValue) {
			if (currentOffset >= lateValue - timing.preHitDeadWindow) {
				wasHit = true;
				return Success.BAD;
			}
			return Success.IGNORE;
		}
		int successType = Success.BAD;
		if (key == this.keyType) {
			if (currentOffset < actualPosition() + timing.goodHitWindow
				&& 
				currentOffset > actualPosition() - timing.goodHitWindow) {

				successType = Success.GOOD;
			} else if (currentOffset < actualPosition() + timing.hitWindow
					   && 
					   currentOffset > actualPosition() - timing.hitWindow) {

				successType = Success.OK;
			}
		}
		wasHit = true;
		return successType;
	}

	override public bool expired() {
		return true;
	}

	override public bool isFinished() {
		return wasHit;
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

	enum HIT_WINDOW = 24; /// Max interval between the two keypresses in ms

	static SDL_Texture* rimTexture;

	private int initialHitResult;
	private long firstHit = -1;

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
		if (firstHit >= 0) {
			if (currentOffset - firstHit <= HIT_WINDOW) {
				return initialHitResult | Value.LARGE;
			} else {
				return Success.SKIP | Value.LARGE;
			}
		} else {
			firstHit = currentOffset;
			initialHitResult = super.hit(keyType);
			return initialHitResult | Value.LARGE_FIRST;
		}
	}

	override bool expired() {
		return firstHit >= 0 ? currentOffset > firstHit + HIT_WINDOW : false;
	}

	override bool isFinished() {
		return wasHit && expired();
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
