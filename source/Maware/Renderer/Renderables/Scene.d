module maware.renderable.scene;

import maware.renderable.renderable;

import std.conv : to;

// A renderable class that holds other renderables to act as a "scene" in the game
class Scene : Renderable {

	private string name; // the scene's name

	// The renderables for the renderer to render each render() call.
	// Uses a layered principle, objects in the lower layers will render first
	// and at the bottom of the screen
	private Renderable[][] renderables;

	this(string name) {
		this.name = name;
	}

	// Render all the renderables in this scene
	public void render() {
		foreach (Renderable[] renderableObjects ; this.renderables) {
			foreach (Renderable renderable ; renderableObjects) {
				if (renderable !is null) {
					renderable.render();
				}
			}
		}
	}

	// Adds a layer of renderables and returns its index
	public int addLayer() {
		renderables ~= null;
		return to!int(renderables.length - 1);
	}

	public void clearLayer(uint layer) {
		if (layer < renderables.length) {
			renderables[layer] = null;
		} else {
			throw new Exception("Tried to clear non-existent layer (out of bounds)");
		}
	}

	// Registers a renderable to the specified layer and returns index
	public int addRenderable(int layer, Renderable renderable) {
		if (renderables.length - 1 < layer) {
			return -1;
		} else {
			renderables[layer] ~= renderable;
			return to!int(renderables[layer].length - 1);
		}
	}

	// Remove a renderable from the scene and return it if found,
	// else returns null
	public Renderable removeRenderable(int layer, int index) {
		if (layer < renderables.length && index < renderables[layer].length) {
			Renderable tempRenderable = renderables[layer][index];
			renderables[layer][index] = null;
			return tempRenderable;
		} else {
			return null;
		}
	}

	// Returns the object contained at the specified position, or null if
	// empty/unspecified space
	public Renderable objectAt(int layer, int index) {
		if (renderables.length > layer) {
			if (renderables[layer].length > index) {
				return renderables[layer][index];
			} else {
				return null;
			}
		} else {
			return null;
		}
	}

	// Returns the object contained at the specified position and replaces
	// it with the object from arguments, returns null if invalid index
	public Renderable setObjectAt(Renderable renderable, int layer, int index) {
		if (renderables.length > layer) {
			if (renderables[layer].length > index) {
				Renderable toReplace = renderables[layer][index];
				renderables[layer][index] = renderable;
				return toReplace;
			} else {
				return null;
			}
		} else {
			return null;
		}
	}
}
