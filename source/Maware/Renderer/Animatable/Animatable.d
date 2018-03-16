module maware.animatable.animatable;

/// Interface for making animations and effects
interface Animatable {
	
	/// Should be callable in a frame to alter a Renderable's properties
	public void animate();
	
	/// Should reset a state to its origin
	public void reset();
	
}
