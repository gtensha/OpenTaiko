//  This file is part of the OpenTaiko project.
//  <https://github.com/gtensha/OpenTaiko>
//
/// Hit object that rewards mashing during the set time period.
///
/// Authors: gtensha (@skyhvelv.net)
/// Copyright: 2019 gtensha
/// License: GNU GPLv3 (no later versions)
//
//  You should have received a copy of the GNU General Public License
//  along with OpenTaiko. If not, see <https://www.gnu.org/licenses/>.

module opentaiko.bashable.drumroll;

import opentaiko.bashable.bashable;

import maware.animatable.animatable;
import maware.animatable.animation;
import maware.animatable.effect;
import maware.renderable.coloringtextured;
import maware.renderable.solid;
import maware.renderable.textured;
import maware.util.timer;

import bindbc.sdl : SDL_Texture, SDL_Color;

import std.math : PI, sin;

class DrumRoll : Bashable {

	enum EFFECT_LEN = 512; /// Length of the hit effect in milliseconds
	enum PART_COUNT = 6; /// Amount of actual Textured objects
	enum COLOUR_PART_COUNT = 3; /// Amount of Textured objects to be coloured
	enum ANIM_VAR_COUNT = 2; /// Animation variation amount
	enum EFFCT_VAR_COUNT = 2; /// Effect variation amount
	enum LEFT_ANIMATION = 0; /// Index of left animation group
	enum RIGHT_ANIMATION = 1; /// Index of right animation group
	enum CENTER_EFFECT = 0; /// Index of center effect group
	enum RIM_EFFECT = 1; /// Index of rim effect group

	static SDL_Texture* startTextureBorder; /// Texture for the first part
	static SDL_Texture* startTextureCore; /// ditto
	static SDL_Texture* bodyTextureBorder; /// Texture for the long part
	static SDL_Texture* bodyTextureCore; /// ditto
	static SDL_Texture* endTextureBorder; /// Texture for the end part
	static SDL_Texture* endTextureCore; /// ditto

	static SDL_Color centerColor;
	static SDL_Color rimColor;
	static SDL_Color noColor;

	private Animatable[PART_COUNT][ANIM_VAR_COUNT] animations;
	private Animatable[COLOUR_PART_COUNT][EFFCT_VAR_COUNT] effects;
	private Timer animationTimer;
	private byte activeEffectIndex;
	private byte activeAnimationIndex;

	private int originY;

	private int length;

	this(int xOffset, int yOffset, int position, double scroll, int length) {
		Solid[PART_COUNT] rendables;
		Textured startB = new Textured(startTextureBorder,
									   xOffset + cast(int)(position * scroll),
									   yOffset);
		Textured startC = new ColoringTextured(startTextureCore,
											   startB.rect.x,
											   startB.rect.y);
		centerObjects([startB, startC], true, true);
		Textured bodyB = new Textured(bodyTextureBorder,
									  startB.rect.x + (startB.rect.w / 2),
									  startB.rect.y);
		Textured bodyC = new ColoringTextured(bodyTextureCore,
											  bodyB.rect.x,
											  bodyB.rect.y);
		centerObjects([bodyB, bodyC], false, true);
		Textured endB = new Textured(endTextureBorder, 0, 0);
		Textured endC = new ColoringTextured(endTextureCore, 0, 0);
		bodyB.rect.w = length - (startB.rect.w / 2) - endB.rect.w;
		bodyC.rect.w = bodyB.rect.w;
		endB.rect.x = bodyB.rect.x + bodyB.rect.w;
		endB.rect.y = bodyB.rect.y;
		centerObjects([endB, endC], true, true);
		foreach (size_t i, Solid s ; [endC,
									  endB,
									  bodyC,
									  bodyB,
									  startC,
									  startB]) {
			rendables[cast(int) i] = s;
		}
		centerObjects(rendables, false, true);
		super(rendables, position, scroll);
		this.length = length;
		this.originY = startB.rect.y;
		this.animationTimer = new Timer();
		
		void delegate(Timer, Solid) centerEffect = makeEffect(noColor,
															  centerColor);
		void delegate(Timer, Solid) rimEffect = makeEffect(noColor,
														   centerColor);
		foreach (size_t typeInd, void delegate(Timer, Solid) e ; [centerEffect,
																  rimEffect]) {
			foreach (size_t i, Solid s ; [startC, bodyC, endC]) {
				effects[typeInd][i] = new Effect(animationTimer, s, e);
			}
		}

		void delegate(Timer, Solid) leftAnimation;
		leftAnimation = makeAnimation(LEFT_ANIMATION);
		void delegate(Timer, Solid) rightAnimation;
		leftAnimation = makeAnimation(RIGHT_ANIMATION);
		foreach (size_t typeInd, void delegate(Timer, Solid) e ; [leftAnimation,
																  rightAnimation]) {
			foreach (size_t i, Solid s ; [startB,
										  startC,
										  bodyB,
										  bodyC,
										  endB,
										  endC]) {
				animations[typeInd][i] = new Animation(animationTimer, s, e);
			}
		}
	}

	override int hit(int keyType) {
		if (currentOffset >= actualPosition()) {
			animationTimer.set(Timer.libInitPassed,
							   Timer.libInitPassed + EFFECT_LEN);
			activeEffectIndex = cast(byte)keyType;
			//activeAnimationIndex = keyType;
			// TODO: Rewrite keyType handling to make side distinguishable
			return Success.AWAIT | Value.ROLL;
		} else {
			return Success.IGNORE | Value.ROLL;
		}
	}

	override bool expired() {
		return currentOffset > actualPosition() + length / scroll;
	}

	override bool isFinished() {
		return expired();
	}

	override void render() {
		foreach (Animatable a ; animations[activeAnimationIndex]) {
			//a.animate(); // animations broken, do not use now
		}
		foreach (Animatable a ; effects[activeEffectIndex]) {
			a.animate(); // effects also broken, but not as badly
		}
		super.render();
	}

	override void adjustY(int yOffset) {
		super.adjustY(yOffset);
		originY += yOffset;
	}

	override int value() {
		return Value.ROLL;
	}

	private void delegate(Timer, Solid) makeAnimation(int type) {
		int delegate(int, int) getNewY;
		if (type == LEFT_ANIMATION) {
			getNewY = (int x, int y){
				return x - y;
			};
		} else {
			getNewY = (int x, int y){
				return x + y;
			};
		}
		return (Timer t, Solid s){
			double x = t.getPercentagePassed();
			s.rect.y = getNewY(originY, cast(int)(10 * sin(0.01 * PI * x)));
		};
	}

	private void delegate(Timer, Solid) makeEffect(SDL_Color base,
												   SDL_Color target) {
		int delegate(double) makeDelegate(int from, int to) {
			int diff;
			int raiseValue;
			if (from == to) {
				return (double){return from;};
			} else if (from > to) {
				diff = (from - to) * -1;
				raiseValue = from;
			} else {
				diff = (to - from);
				raiseValue = from;
			}
			return (double x){
				return cast(int)(diff * sin(0.01 * PI * x) + raiseValue);
			};
		}
		int delegate(double) redDelegate = makeDelegate(base.r, target.r);
		int delegate(double) greenDelegate = makeDelegate(base.g, target.g);
		int delegate(double) blueDelegate = makeDelegate(base.b, target.b);
		int delegate(double) alphaDelegate = makeDelegate(base.a, target.a);
		return (Timer t, Solid s){
			double x = t.getPercentagePassed();
			s.color.r = cast(ubyte)redDelegate(x);
			s.color.g = cast(ubyte)greenDelegate(x);
			s.color.b = cast(ubyte)blueDelegate(x);
			s.color.a = cast(ubyte)alphaDelegate(x);
		};
	}

}
