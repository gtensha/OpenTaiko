//  This file is part of the OpenTaiko project.
//  <https://github.com/gtensha/OpenTaiko>
//
/// Game scene management. The Scene is a way to group renderable
/// objects together without creating a new class. It is used in Renderer as
/// the means to switch contexts on screen, as different scenes can be made and
/// swapped with minimal boilerplate.
///
/// Authors: gtensha (@skyhvelv.net)
/// Copyright: 2017-2018 gtensha
/// License: GNU GPLv3 (no later versions)
//
//  You should have received a copy of the GNU General Public License
//  along with OpenTaiko. If not, see <https://www.gnu.org/licenses/>.

module maware.renderable.scene;

import maware.renderable.renderable;
import maware.animatable.animatable;

import bindbc.sdl : SDL_Color;

/// A renderable class that holds other renderables to act as a "scene" in the game.
/// Some of the methods in this class will throw a RangeError if bad indices
/// are supplied.
class Scene : Renderable {

	immutable string name; /// The scene's name

	/* The renderables for the renderer to render each render() call.
	   Uses a layered principle, objects in the lower layers will render first
	   and at the bottom of the screen
	*/
	private Renderable[][] renderables;
	private Renderable[][] hiddenLayers; // temporary storage for hidden layers
	
	private Animatable[] animatables; // array of Animatables to process in render()
	
	SDL_Color backgroundColor; /// The background color to render with

	/// Create a new Scene with the given name and amount of layers
	this(string name, int layerCount) {
		this.name = name;
		this.renderables = new Renderable[][layerCount];
		this.hiddenLayers = new Renderable[][layerCount];
	}

	/// Render all the renderables in this scene
	public void render() {
		foreach (Animatable animatable ; animatables) {
			animatable.animate();
		}
		foreach (Renderable[] renderableObjects ; renderables) {
			foreach (Renderable renderable ; renderableObjects) {
				if (renderable !is null) {
					renderable.render();
				}
			}
		}
	}

	/// Clears the layer at the given index of renderables
	public void clearLayer(int layer) {
		renderables[layer] = null;
		hiddenLayers[layer] = null;
	}
	
	/// "Hides" a layer, so that it is not rendered
	public void hideLayer(int layer) {
		if (hiddenLayers[layer] is null) {
			hiddenLayers[layer] = renderables[layer];
			renderables[layer] = null;
		}
	}
	
	/// "Shows" a layer, so that it is shown yet again
	public void showLayer(int layer) {
		if (hiddenLayers[layer] !is null) {
			renderables[layer] = hiddenLayers[layer];
			hiddenLayers[layer] = null;
		}
	}
	
	/// "Toggles" a layer by hiding if shown, and showing if hidden
	public void toggleLayer(int layer) {
		if (hiddenLayers[layer] is null) {
			hideLayer(layer);
		} else {
			showLayer(layer);
		}
	}

	/// Registers a renderable to the specified layer and returns its index
	public int addRenderable(int layer, Renderable renderable) {
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
	
	/// Adds an Animatable to run during render times and return its index
	public int addAnimatable(Animatable animatable) {
		animatables ~= animatable;
		return cast(int)animatables.length - 1;
	}
	
	/// Removes the Animatable at index from the Scene and returns it
	public Animatable removeAnimatable(int index) {
		Animatable animatable = animatables[index];
		animatables = animatables[0 .. index] 
					  ~ animatables[index + 1 .. animatables.length];
		return animatable;
	}

}
