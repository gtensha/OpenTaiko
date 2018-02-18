module opentaiko.bashable.bashable;

import maware.renderable.renderable;
import maware.renderable.solid;

/// A class that can be rendered and hit in a timing window
abstract class Bashable : Renderable {

	/// How many milliseconds for the timing window
	static const int latestHit = 200;
	static const int goodHit = 50; /// ditto

	/// Success codes for the hitting of an object
	enum Success : int {
		GOOD = 0,
		OK = 1,
		BAD = 2,
		IGNORE = 3
	};

	public static int currentOffset; /// The current time offset in ms

	immutable uint position; /// Object position in milliseconds
	immutable double scroll; /// How fast the object will advance (multiplier)

	public Solid[] renderables; /// The renderable(s) (texture, e.l.)

	this(Solid[] renderables, uint position, double scroll) {
		this.renderables ~= renderables;
		this.position = position;
		this.scroll = 1;
	}

	public void render() {
		foreach (Solid renderable ; renderables) {
			renderable.renderOffset(0 - currentOffset/*cast(int)(currentOffset * scroll)*/, 0);
		}
		//renderable.render();
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

	/// Return this object's actual (relative) position on the timeline
	public int actualPosition() {
		return cast(int)(position / scroll);
	}

	/// Return this object's current position on the timeline
	public int currentPosition() {
		return cast(int)(position - currentOffset * scroll);
	}

	public int getObjectMaxHeight() {
		int max = 0;
		foreach (Solid renderable ; renderables) {
			if (renderable.rect.h > max) {
				max = renderable.rect.h;
			}
		}
		return max;
	}

}
