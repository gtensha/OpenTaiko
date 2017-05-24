import map_gen;

class Performance {

    string mapTitle;
    Drum[] drums;
    Score score;
    int i;

    struct Score {
	int good;
	int ok;
	int bad;
    }

    this(string map) {
	mapTitle = map;
	drums = MapGen.parseMapFromFile(map);
	drums[0].setParent(this);
	i = 0;
    }

    // Attempt to hit current drum circle
    // and return result
    int hit(int key, int time) {
	int hitResult = drums[i].hit(key, time);
	if (hitResult == 0) {
	    score.good++;
	} else if (hitResult == 1) {
	    score.ok++;
	} else if (hitResult == 3) {
	    return hitResult;
	} else {
	    score.bad++;
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

class Drum {

    int hitType;
    static Performance parent;
    
    public immutable double position;

    this(double time) {
	position = time;
    }

    // Set the parent (performance) of all
    // created drum objects
    static void setParent(Performance parent) {
	this.parent = parent;
    }

    // Attempt to hit this drum circle,
    // return result
    int hit(int key, int time) {
	if (time < this.position - 200.0) {
	    return 3;
	}
	int successType = 2;
	if (key == this.hitType) {
	    if (time < this.position + 50.0 && time > position - 50.0) {
		successType = 0;
	    } else if (time < this.position + 200.0 && time > position - 200.00) {
		successType = 1;
	    } else {
		successType = 2;
	    }
	} else {
	    successType = 2;
	}
	this.parent.nextDrum();
	return successType;
    }

    int color() {
	return -1;
    }
    
}

class Red : Drum {

    this(double time) {
        super(time);
	hitType = 0;
    }

    override int color() {
	return 0;
    }
    
}

class Blue : Drum {

    this(double time) {
        super(time);
	hitType = 1;
    }

    override int color() {
	return 1;
    }

}
