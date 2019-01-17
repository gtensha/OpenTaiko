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

	enum TardyValue : int {
		TIMELY, /// Object has not exceeded hit window
		TARDY, /// Object has expired (exceeded hit window)
		BONUS_EXPIRED /// Object was hit in time, but cannot be hit again
	}
	
	enum ScoreMultiplier : float {
		NORMAL = 1.0,
		LARGE = 1.5
	}

	enum VAL_AMOUNT = 2;
	enum SCORE_AMOUNT = 2;
	enum GOOD_INDEX = 0;
	enum OK_INDEX = 1;
	enum NORMAL_INDEX = 0;
	enum LARGE_INDEX = 1;
	
	private static immutable int[2] scoreValIndex = [ScoreValue.GOOD, ScoreValue.OK];

	unittest {
		assert(((Bashable.Value.NORMAL >> 8) - 1) == NORMAL_INDEX);
		assert(((Bashable.Value.LARGE >> 8) - 1) == LARGE_INDEX);
		assert(Bashable.Success.GOOD == GOOD_INDEX);
		assert(Bashable.Success.OK == OK_INDEX);
		assert([Bashable.Value.NORMAL, Bashable.Value.LARGE].length == VAL_AMOUNT);
		assert([Bashable.Success.GOOD, Bashable.Success.OK].length == SCORE_AMOUNT);
	}

	string mapTitle;
	Bashable[] drums;
	Timer timer;
	Score score;
	int i;
	int hitResult;
	int pendingResult; /// Result from a partially hit object (like big drum)
	bool finished;
	
	struct Score {
		int[SCORE_AMOUNT][VAL_AMOUNT] hits;
		//int good;
		//int ok;
		int bad;
		int rollHits;
		int currentCombo;
		int highestCombo;
	}

	this(string title, Bashable[] hitObjects, Timer timer, int xOffset, int yOffset) {

		mapTitle = title;
		drums = array(hitObjects);
		this.timer = timer;

		foreach (Bashable bashable ; drums) {
			bashable.adjustX(xOffset);
			bashable.adjustY(yOffset);
		}

	}

	/// Attempt to hit current drum circle and return Success value.
	/// Possible success values are defined in the Bashable.Success enum.
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
		} else if (hitValue == Bashable.Value.LARGE_FIRST) {
			pendingResult = hitSuccessType;
			return Bashable.Success.IGNORE;
		}
		const int valueIndex = (hitValue >> 8) - 1;
		const int typeIndex = hitSuccessType;
		if (hitSuccessType == Bashable.Success.GOOD
			||
			hitSuccessType == Bashable.Success.OK) {

			score.hits[valueIndex][typeIndex]++;
			score.currentCombo++;
			i++;
		} else if (hitSuccessType == Bashable.Success.BAD) {
			score.bad++;
			score.currentCombo = 0;
			i++;
		}
		if (score.currentCombo > score.highestCombo) {
			score.highestCombo = score.currentCombo;
		}
		return hitSuccessType;
	}

	/// Return the level of timeliness of the current hit object, that is,
	/// whether it has been hit in time and/or is within the timing window.
	/// Timeliness levels are defined in the TardyValues enum.
	/// Calling this when an object is tardy will advance to the next hit object.
	int checkTardiness() { // TODO: Optimise this for low framerates
		if (i >= drums.length) {
			finished = true;
			return TardyValue.TIMELY;
		}
		Bashable currentDrum = drums[i];
		if (currentDrum.value() == Bashable.Value.ROLL) {
			if (currentDrum.expired()) {
				i++;
				return checkTardiness();
			} else {
				return TardyValue.TIMELY;
			}
		} else if (currentDrum.value() == Bashable.Value.LARGE) {
			if ((hitResult & Bashable.Value.MASK) == Bashable.Value.LARGE_FIRST
				&&
				currentDrum.expired()) {

				i++;
				hitResult &= Bashable.Success.MASK | (Bashable.Value.MASK
													  &
													  Bashable.Value.NONE);
				return TardyValue.BONUS_EXPIRED;
			}
		}
		if (tardy(currentDrum)) {
			return TardyValue.TARDY;
		} else {
			return TardyValue.TIMELY;
		}
	}

	private bool tardy(Bashable obj) {
		if (obj.actualPosition() + Bashable.latestHit
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

	/// Manually iterate to next drum circle in the game
	void nextDrum() {
		i++;
	}

	/// Return the player's score in the current game state
	int calculateScore() {
		int result;
		foreach (size_t i, float scoreMult ; [ScoreMultiplier.NORMAL,
											  ScoreMultiplier.LARGE]) {
			result += cast(int)(score.hits[i][GOOD_INDEX]
								* ScoreValue.GOOD
								* scoreMult);
			result += cast(int)(score.hits[i][OK_INDEX]
								* ScoreValue.OK
								* scoreMult);
		}
		result += score.rollHits * ScoreValue.ROLL;
		return result;
	}

	int hits(int type) {
		int count;
		foreach(int[] scoreCounts ; score.hits) {
			count += scoreCounts[type];
		}
		return count;
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
