module opentaiko.performance;

import std.array : array;
import opentaiko.bashable;
import maware.renderable.renderable;
import maware.util.timer;
import opentaiko.mapgen : MapGen;

class Performance : Renderable {

	string mapTitle;
	Bashable[] drums;
	Timer timer;
	Score score;
	int i;

	struct Score {
		int good;
		int ok;
		int bad;
		int currentCombo;
		int highestCombo;
	}

	this(string title, Bashable[] hitObjects, Timer timer, int xOffset, int yOffset) {

		mapTitle = title;
		drums = array(hitObjects);
		this.timer = timer;
		score.good = 0;

		foreach (Bashable bashable ; drums) {
			bashable.adjustX(xOffset);
			bashable.adjustY(yOffset);
		}

		i = 0;
	}

	import std.stdio;
	/// Attempt to hit current drum circle and return result
	int hit(int key, int time) {
		const int hitResult = drums[i].hit(key, time);
		if (hitResult == Bashable.Success.GOOD) {
			score.good++;
			score.currentCombo++;
		} else if (hitResult == Bashable.Success.OK) {
			score.ok++;
			score.currentCombo++;
		} else if (hitResult == Bashable.Success.IGNORE) {
			return Bashable.Success.IGNORE;
		} else {
			score.bad++;
			score.currentCombo = 0;
		}
		if (score.currentCombo > score.highestCombo) {
			score.highestCombo = score.currentCombo;
		}
		writeln(hitResult);
		i++;
		return hitResult;
	}

	// Return true if this circle should've
	// been hit but wasn't
	bool checkTardiness(int time) {
		if (i >= drums.length - 1) {
			return false;
		}
		if (drums[i].position + 200 < time) {
			i++;

			score.bad++;
			score.currentCombo = 0;
			return true;
		} else {
			return false;
		}
	}

	// Iterate to next drum circle in the game
	void nextDrum() {
		i++;
	}

	// Return the player's score in the current game state
	int calculateScore() {
		int result = (score.good * 300) + (score.ok * 100);
		return result;
	}

	public void render() {
		Bashable.currentOffset = timer.getTimerPassed();
		for (int it = this.i; it < drums.length/* && drums[it].currentPosition  time*/; it++) {
			drums[it].render();
		}
	}

	public void setRenderableOffset(int xOffset, int yOffset, int maxHeight) {
		foreach (Bashable bashable ; drums) {
			bashable.adjustX(xOffset);
			bashable.adjustY(yOffset + (maxHeight - bashable.getObjectMaxHeight) / 2);
		}
	}

}
