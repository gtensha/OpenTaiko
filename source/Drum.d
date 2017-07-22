import Performance;

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
