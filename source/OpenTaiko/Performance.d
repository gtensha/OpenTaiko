module opentaiko.performance;

import std.array : array;
import opentaiko.bashable;
import maware.renderable.renderable;
import maware.util.timer;
import opentaiko.mapgen : MapGen;

class Performance : Renderable {

	enum ScoreValue : int {
		GOOD = 300,
		OK = 100,
		ROLL = 50
	}

	enum ScoreMultiplier : float {
		NORMAL
	}

	private static immutable int[2] scoreValIndex = [ScoreValue.GOOD, ScoreValue.OK];

	string mapTitle;
	Bashable[] drums;
	Timer timer;
	Score score;
	int i;
	int hitResult;
	bool finished;

	struct Score {
		int good;
		int ok;
		int bad;
		int rollHits;
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

	/// Attempt to hit current drum circle and return result
	int hit(int key) {
		hit_next:
		if (i < drums.length) {
			hitResult = drums[i].hit(key);
		} else {
			finished = true;
			return Bashable.Success.IGNORE;
		}
		const int hitSuccessType = hitResult & Bashable.Success.MASK;
		const int hitValue = hitResult & Bashable.Value.MASK;
		if (hitValue == Bashable.Value.ROLL) {
			if (!drums[i].expired()) {
				score.rollHits++;
				return Bashable.Success.IGNORE;
			} else {
				i++;
				goto hit_next;
			}
		}
		switch (hitSuccessType) {
		case Bashable.Success.GOOD:
			score.good++;
			goto acceptable;

		case Bashable.Success.OK:
			score.ok++;
			goto acceptable;

		case Bashable.Success.BAD:
			score.bad++;
			score.currentCombo = 0;
			goto any_hit;

		acceptable:
			score.currentCombo++;
			goto any_hit;

		any_hit:
			i++;
			break;

		default:
			break;
		}
		if (score.currentCombo > score.highestCombo) {
			score.highestCombo = score.currentCombo;
		}
		return hitSuccessType;
	}

	/// Return true if this circle should've been hit but wasn't
	bool checkTardiness() {
		if (i >= drums.length) {
			finished = true;
			return false;
		}
		if (drums[i].value() == Bashable.Value.ROLL) {
			if (drums[i].expired()) {
				i++;
				checkTardiness();
			} else {
				return false;
			}
		}
		if (drums[i].actualPosition() + Bashable.latestHit
			<
			timer.getTimerPassed()) {

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
		int result = score.good * ScoreValue.GOOD;
		result += score.ok * ScoreValue.OK;
		result += score.rollHits * ScoreValue.ROLL;
		return result;
	}

	public void render() {
		Bashable.currentOffset = timer.getTimerPassed();
		for (int it = this.i; it < drums.length; it++) {
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
