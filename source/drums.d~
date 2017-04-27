import map_gen;

class Performance {

    Drum[] drums;
    Score score;
    private int i;

    struct Score {
	int good;
	int ok;
	int bad;
    }

    this(string map, int bpm) {
	drums = MapGen.parseMapFromFile(map, bpm);
	drums[0].setParent(this);
	i = 0;
    }

    int hit(int key, int time) {
	int hitResult = drums[i].hit(key, time);
	if (hitResult == 0) {
	    score.good++;
	} else if (hitResult == 1) {
	    score.ok++;
	} else {
	    score.bad++;
	}
	return hitResult;
    }

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

    void nextDrum() {
	i++;
    }

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

    static void setParent(Performance parent) {
	this.parent = parent;
    }
    
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
