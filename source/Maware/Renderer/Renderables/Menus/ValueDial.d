//  This file is part of the OpenTaiko project.
//  <https://github.com/gtensha/OpenTaiko>
//
/// GUI element for adjusting various numeric values in the game.
///
/// Authors: gtensha (@skyhvelv.net)
/// Copyright: 2019 gtensha
/// License: GNU GPLv3 (no later versions)
//
//  You should have received a copy of the GNU General Public License
//  along with OpenTaiko. If not, see <https://www.gnu.org/licenses/>.

module maware.renderable.menus.valuedial;

import maware.font;
import maware.renderable.menus.traversable;
import maware.renderable.text;

import bindbc.sdl : SDL_Color;

import std.conv : to;

/// A class representing a renderable dial element that can be used to adjust
/// an incrementable value
class ValueDial (T) : Traversable {

	enum LEFT_INCREMENT = "-";
	enum RIGHT_INCREMENT = "+";
	enum INCREMENT_PREFIX = "±";
	enum ELEMENT_SPACING = 10;

	private const T[] incrementFactors;
	private int currentIncrementIndex;

	private T currentValue;

	private void delegate(T) updateCallback;

	private Text leftIndicator;
	private Text rightIndicator;
	private Text valueText;
	private Text incrementDisplay;
	const int height;

	/// Construct a new dial starting at initialValue, peaking at maxValue,
	/// bottoming at minValue, and being incrementable by the values listed
	/// in incrementFactors. updateCallback will be called after each selection,
	/// but is ignored if it is null.
	this(T initialValue,
		 T maxValue,
		 T minValue,
		 T[] incrementFactors,
		 void delegate(T) updateCallback,
		 int height,
		 Font dialFont,
		 SDL_Color color,
		 int x, int y) {

		this.currentValue = initialValue;
		this.height = height;
		this.updateCallback = updateCallback;
		if (incrementFactors.length < 1) {
			this.incrementFactors = [1];
		} else {
			this.incrementFactors = incrementFactors;
		}
		leftIndicator = new Text(LEFT_INCREMENT,
								 dialFont.get(height),
								 true,
								 x, y,
								 color);
		const int valueX = (leftIndicator.rect.x
							+ leftIndicator.rect.w
							+ ELEMENT_SPACING);
		valueText = new Text(to!string(initialValue),
							 dialFont.get(height),
							 true,
							 valueX, y,
							 color);
		const int rightX = (valueText.rect.x
							+ valueText.rect.w
							+ ELEMENT_SPACING);
		rightIndicator = new Text(RIGHT_INCREMENT,
								  dialFont.get(height),
								  true,
								  rightX, y,
								  color);
		incrementDisplay = new Text(INCREMENT_PREFIX,
									dialFont.get(height / 2),
									true,
									leftIndicator.rect.x, y,
									color);
		incrementDisplay.rect.y -= incrementDisplay.rect.h / 2;
		updateIncrementText();
	}

	/// Increments or decrements currentValue incrementFactor times depending on
	/// direction.
	/// Moves.LEFT - decrement.
	/// Moves.RIGHT - increment.
	/// Updates value text after each call, and calls the update callback unless
	/// it is null.
	public void move(bool direction) {
		T incrDecrValue = incrementFactors[currentIncrementIndex];
		if (direction == Moves.LEFT) {
			currentValue -= incrDecrValue;
		} else {
			currentValue += incrDecrValue;
		}
		updateValueText();
		if (updateCallback !is null) {
			updateCallback(currentValue);
		}
	}

	/// Cycles the current incrementFactor value among the ones provided during
	/// object construction. Goes from the first provided value, to the last,
	/// then repeats the process.
	public Traversable press() {
		cycleIncrementValue();
		return null;
	}

	public void render() {
		leftIndicator.render();
		valueText.render();
		incrementDisplay.render();
		rightIndicator.render();
	}

	/// Return the currently selected value.
	public T getValue() {
		return currentValue;
	}

	public int width() {
		return (rightIndicator.rect.x
				+ rightIndicator.rect.w
				- leftIndicator.rect.x);
	}

	private void cycleIncrementValue() {
		currentIncrementIndex++;
		if (currentIncrementIndex >= incrementFactors.length) {
			currentIncrementIndex = 0;
		}
		updateIncrementText();
	}

	private void updateIncrementText() {
		const string s = to!string(incrementFactors[currentIncrementIndex]);
		incrementDisplay.updateText(INCREMENT_PREFIX ~ s);
	}

	private void updateValueText() {
		valueText.updateText(to!string(currentValue));
		rightIndicator.rect.x = (valueText.rect.x
								 + valueText.rect.w
								 + ELEMENT_SPACING);
	}

}
