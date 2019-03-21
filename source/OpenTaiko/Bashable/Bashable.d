module opentaiko.bashable.bashable;

import maware.renderable.renderable;
import maware.renderable.solid;

/// A class that can be rendered and hit in a timing window
abstract class Bashable : Renderable {

	/// How many milliseconds for the timing window
	static const int latestHit = 200;
	static const int goodHit = 50; /// ditto

	/// Success codes for the hitting of an object
	enum Success : ubyte {
		GOOD = 0x00,
		OK = 0x01,
		BAD = 0x02,
		IGNORE = 0x03,
		AWAIT = 0x04,
		SKIP = 0x05,
		MASK = 0xff
	}
	
	/// Values for the hitting of an object
	enum Value : ushort {
		NORMAL = 0x0100,
		LARGE = 0x0200,
		ROLL = 0x0300,
		NONE = 0x0400,
		LARGE_FIRST = 0x0500,
		MASK = 0xff00
	}

	public static int currentOffset; /// The current time offset in ms

	immutable uint position; /// Object position in milliseconds
	immutable double scroll; /// How fast the object will advance (multiplier)

	public Solid[] renderables; /// The renderable(s) (texture, e.l.)

	this(Solid[] renderables, uint position, double scroll) {
		this.renderables ~= renderables;
		this.position = cast(int)(position * scroll);
		this.scroll = scroll;
	}

	public void render() {
		foreach (Solid renderable ; renderables) {
			renderable.renderOffset(0 - cast(int)(currentOffset * scroll), 0);
		}
	}

	public void adjustX(int xOffset) {
		foreach (Solid renderable ; renderables) {
			if (renderable !is null) {
				renderable.rect.x = (renderable.rect.x + xOffset);
			}
		}
	}

	public void adjustY(int yOffset) {
		foreach (Solid renderable ; renderables) {
			if (renderable !is null) {
				renderable.rect.y = (renderable.rect.y + yOffset);
			}
		}
	}

	/// Attempt to hit this object and return success code
	public abstract int hit(int key);
	
	/// Return true if this object has been hit before but cannot be hit again
	public abstract bool expired();

	/// Return the value of this object, from which we can infer type
	public int value();

	/// Return this object's actual (relative) position on the timeline
	public int actualPosition() {
		return cast(int)(position / scroll);
	}

	/// Return this object's current position on the timeline
	public int currentPosition() {
		return cast(int)(position - currentOffset * scroll);
	}

	/// Return true if this object was hit and should no longer be rendered
	public abstract bool isFinished();

	public int getObjectMaxHeight() {
		int max = 0;
		foreach (Solid renderable ; renderables) {
			if (renderable.rect.h > max) {
				max = renderable.rect.h;
			}
		}
		return max;
	}

	/// Returns the (visible) length of this object
	public int getObjectLength() {
		if (renderables.length < 1) {
			return 0;
		}
		int minX = renderables[0].rect.x;
		foreach (Solid renderable ; renderables) {
			if (renderable.rect.x < minX) {
				minX = renderable.rect.x;
			}
		}
		int max;
		foreach (Solid s ; renderables) {
			int actualWidth = s.rect.x - minX + s.rect.w;
			if (actualWidth > max) {
				max = actualWidth;
			}
		}
		return max;
	}

	/// Align all Solid objects in objects by changing their relative coordinates
	/// so that they are centered inside the largest.
	/// Centers on both X and Y axis if centerX is true, else only Y.
	static void centerObjects(Solid[] objects, bool centerX, bool centerY) {
		if (objects.length < 2) {
			return;
		}
		Solid largestY = objects[0];
		Solid largestX = objects[0];
		foreach (Solid obj ; objects[1 .. objects.length]) {
			if (centerY && obj.rect.h > largestY.rect.h) {
				largestY = obj;
			}
			if (centerX && obj.rect.w > largestX.rect.w) {
				largestX = obj;
			}
		}
		foreach (Solid obj ; objects) {
			if (centerY && obj != largestY) {
				obj.rect.y = largestY.rect.y;
				obj.rect.y += (largestY.rect.h - obj.rect.h) / 2;
			}
			if (centerX && obj != largestX) {
				obj.rect.x = largestX.rect.x;
				obj.rect.x += (largestX.rect.w - obj.rect.w) / 2;
			}
		}
	}

}
