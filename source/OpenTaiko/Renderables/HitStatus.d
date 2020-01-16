//  This file is part of the OpenTaiko project.
//  <https://github.com/gtensha/OpenTaiko>
//
/// Gives visual feedback to the player about their drum hits and how well
/// things are going.
///
/// Authors: gtensha (@skyhvelv.net)
/// Copyright: 2018, 2020 gtensha
/// License: GNU GPLv3 (no later versions)
//
//  You should have received a copy of the GNU General Public License
//  along with OpenTaiko. If not, see <https://www.gnu.org/licenses/>.

module opentaiko.renderable.hitstatus;

import maware.renderable.renderable;
import maware.renderable.solid;
import maware.util.timer;

/// A class for displaying hit status graphics
class HitStatus : Renderable {
	
	enum FADE_LEN = 320; /// Effect fade length in ms
	
	private Timer effectTimer;
	private Solid[6] hitStatusEffects;
	private int[6] idleY;
	private int[6] expandedY;
	private int[6] expandedHeight;
	private int activeEffect;
	
	/// Create a new instance with these displayable textures,
	/// aligning them with the Solid reference
	this(Solid[6] effects, Solid reference) {
		this.hitStatusEffects = effects;
		foreach (int i, Solid effect ; hitStatusEffects) {
			if (i % 2 == 0) { // top item
				effect.rect.y = reference.rect.y + reference.rect.h / 2;
				expandedY[i] = effect.rect.y - effect.rect.h;
			} else { // bottom item
				effect.rect.y = reference.rect.y + reference.rect.h / 2;
				expandedY[i] = effect.rect.y;
			}
			effect.rect.x = reference.rect.x - (effect.rect.w - reference.rect.w) / 2;
			idleY[i] = effect.rect.y;
			expandedHeight[i] = effect.rect.h;
		}
		effectTimer = new Timer();
	}
	
	void render() {
		double getEffectPercentage(double x) {
			if (x <= 24.4949) {
				return (x * x) / 6;
			} else if (x < 80) {
				return 100;
			} else {
				return (-0.3 * x * x) + 48 * x - 1820;
			}
		}
		const double percentage = effectTimer.getPercentagePassed();
		if (percentage < 100) {
			const int i = activeEffect;
			double x = percentage;
			int h = cast(int)((getEffectPercentage(percentage) / 100.0) * expandedHeight[i]);
			hitStatusEffects[i].rect.h = h;
			hitStatusEffects[i].rect.y = idleY[i] - h;
			h = cast(int)((getEffectPercentage(percentage) / 100.0) * expandedHeight[i + 1]);
			hitStatusEffects[i + 1].rect.h = h;
			hitStatusEffects[i].render();
			hitStatusEffects[i + 1].render();
		}
	}
	
	/// Sets the specified effect as active and resets timer
	void setEffect(int effectIndex) {
		if (effectIndex == 0) {
			activeEffect = 0;
		} else {
			activeEffect = effectIndex * 2;
		}
		effectTimer.set(Timer.libInitPassed, Timer.libInitPassed + FADE_LEN);
	}
	
}
