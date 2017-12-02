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

	immutable int keyType = 0;

	immutable uint position; /// Object position in milliseconds
	immutable double scroll; /// How fast the object will advance (multiplier)

	protected Solid renderable; /// The renderable (texture, e.l.)

	this(Solid renderable, uint position, double scroll) {
		this.renderable = renderable;
		this.position = position;
		this.scroll = scroll;
	}

	public void render() {
		renderable.render();
	}

	/// Attempt to hit this object and return success code
	public abstract int hit(int key, int time);

}
