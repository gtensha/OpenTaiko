module maware.renderable.scene;

import maware.renderable.renderable;

import std.conv : to;

/// A renderable class that holds other renderables to act as a "scene" in the game.
/// Some of the methods in this class will throw a RangeError if bad indices
/// are supplied.
class Scene : Renderable {

	private string name;

	/* The renderables for the renderer to render each render() call.
	   Uses a layered principle, objects in the lower layers will render first
	   and at the bottom of the screen
	*/
	private Renderable[][] renderables;

	/// Create a new Scene with the given name
	this(string name) {
		this.name = name;
	}

	/// Render all the renderables in this scene
	public void render() {
		foreach (Renderable[] renderableObjects ; renderables) {
			foreach (Renderable renderable ; renderableObjects) {
				if (renderable !is null) {
					renderable.render();
				}
			}
		}
	}

	/// Adds a layer of renderables and returns its index
	public int addLayer() {
		renderables ~= null;
		return cast(uint)renderables.length - 1;
	}

	/// Clears the layer at the given index of renderables
	public void clearLayer(uint layer) {
		renderables[layer] = null;
	}

	/// Registers a renderable to the specified layer and returns its index
	public int addRenderable(uint layer, Renderable renderable) {
			renderables[layer] ~= renderable;
			return cast(uint)renderables[layer].length - 1;
	}

	/// Remove a renderable from the scene and return it if found
	public Renderable removeRenderable(int layer, int index) {
		Renderable tempRenderable = renderables[layer][index];
		renderables[layer][index] = null;
		return tempRenderable;
	}

	/// Returns the object contained at the specified position
	public Renderable objectAt(int layer, int index) {
		return renderables[layer][index];
	}

	/// Returns the object contained at the specified position and replaces
	/// it with the object from arguments
	public Renderable setObjectAt(Renderable renderable, int layer, int index) {
		Renderable toReplace = renderables[layer][index];
		renderables[layer][index] = renderable;
		return toReplace;
	}

	/// Returns the name of this scene
	public string getName() {
		return name;
	}
}
