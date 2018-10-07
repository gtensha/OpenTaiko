module opentaiko.drumindicator;

import maware.renderable.renderable;
import maware.renderable.textured;
import maware.renderable.solid;
import maware.util.timer;

/// Class for a renderable drum "press" indicator
class DrumIndicator : Renderable {

	enum FADE_LEN = 128; /// ms to spend (partially) highlighted
	enum X_SPACING = 20; /// amount of pixels to indent from the start of conveyor

	Textured[4] indicatorHighlights;
	Timer[4] fadeTimers;
	Textured base;

	/// Create a new instance using the base textured base, and four in-order
	/// (left rim, left center, right center, right rim) Textured objects to use
	/// for highlighting it. Sets x and y coordinates to align with conveyor.
	/// All Textured objects must have the same size in pixels or they will not
	/// get aligned properly.
	this(Textured base, Textured[4] indicatorHighlights, Solid conveyor) {
		this.base = base;
		this.indicatorHighlights = indicatorHighlights;
		this.fadeTimers = [new Timer(), new Timer(), new Timer(), new Timer()];
		
		foreach (Textured t ; indicatorHighlights ~ base) {
			t.rect.x = conveyor.rect.x + X_SPACING;
			int diff = t.rect.h - conveyor.rect.h;
			t.rect.y = conveyor.rect.y - (diff / 2);
		}
	}
	
	void render() {
		base.render();
		foreach (int i, Timer t ; fadeTimers) {
			double percentage = t.getPercentagePassed();
			if (percentage < 100) {
				indicatorHighlights[i].color.a = cast(ubyte)((0xff / 100.0) * percentage);
				indicatorHighlights[i].render();
			}
		}
	}
	
	/// "Hit" a key, setting the indicator corresponding to section's timer to
	/// start now, effectively rendering a fade effect next frame.
	/// Section should be an integer in the range 0-3 or we'll crash.
	void hit(int section) {
		fadeTimers[section].set(Timer.libInitPassed, Timer.libInitPassed + FADE_LEN);
	}

}
