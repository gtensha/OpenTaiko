import Drum;
import MapGen;

class Performance {

	string mapTitle;
	Drum[] drums;
	Score score;
	int i;

	struct Score {
		int good;
		int ok;
		int bad;
		int currentCombo;
		int highestCombo;
	}

	this(string map) {
		mapTitle = map;
		drums = MapGen.MapGen.parseMapFromFile(map);
		drums[0].setParent(this);
		i = 0;
	}

	// Attempt to hit current drum circle
	// and return result
	int hit(int key, int time) {
		int hitResult = drums[i].hit(key, time);
		if (hitResult == 0) {
			score.good++;
			score.currentCombo++;
		} else if (hitResult == 1) {
			score.ok++;
			score.currentCombo++;
		} else if (hitResult == 3) {
			return 3;
		} else {
			score.bad++;
			score.currentCombo = 0;
		}
		if (score.currentCombo > score.highestCombo) {
			score.highestCombo = score.currentCombo;
		}
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

	// Iterate to next drum circle in the
	// game and remove the overdue one
	void nextDrum() {
		i++;
	}

	// Return the player's score in the
	// current game state
	int calculateScore() {
		int result = (score.good * 300) + (score.ok * 100);
		return result;
	}

}
