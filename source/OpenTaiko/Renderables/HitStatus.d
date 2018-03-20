module opentaiko.renderable.hitstatus;

import maware.renderable.renderable;
import maware.renderable.solid;
import maware.util.timer;

/// A class for displaying hit status graphics
class HitStatus : Renderable {
	
	enum FADE_LEN = 128; /// Effect fade length in ms
	
	private Timer effectTimer;
	private Solid[] hitStatusEffects;
	private int activeEffect;
	
	/// Create a new instance with these displayable textures,
	/// aligning them with the Solid reference
	this(Solid[] effects, Solid reference) {
		this.hitStatusEffects = effects;
		foreach (Solid effect ; hitStatusEffects) {
			effect.rect.y = reference.rect.y 
							- (effect.rect.h - reference.rect.h) / 2;
							
			effect.rect.x = reference.rect.x
							- (effect.rect.w - reference.rect.w) / 2;
		}
		effectTimer = Timer.timers[Timer.addTimer()];
	}
	
	void render() {
		const int percentage = cast(int)effectTimer.getPercentagePassed();
		if (percentage < 100) {
			hitStatusEffects[activeEffect].color.a = cast(ubyte)((0xff / 100) * percentage);
			hitStatusEffects[activeEffect].render();
		}
	}
	
	/// Sets the specified effect as active and resets timer
	void setEffect(int effectIndex) {
		activeEffect = effectIndex;
		effectTimer.set(Timer.libInitPassed, Timer.libInitPassed + FADE_LEN);
	}
	
}
