module maware.renderable.menus.traversable;

import maware.renderable.renderable;

enum Moves : bool {
	RIGHT = true,
	LEFT = false,
	UP = false,
	DOWN = true
};

interface Traversable : Renderable {

	public void move(bool);

	public Traversable press();

}
