//  This file is part of the OpenTaiko project.
//  <https://github.com/gtensha/OpenTaiko>
//
/// Makes rendering hit objects more efficient by only rendering objects based
/// on their time of approach.
///
/// Authors: gtensha (@skyhvelv.net)
/// Copyright: 2019 gtensha
/// License: GNU GPLv3 (no later versions)
//
//  You should have received a copy of the GNU General Public License
//  along with OpenTaiko. If not, see <https://www.gnu.org/licenses/>.

module opentaiko.renderable.renderqueue;

import maware.renderable.renderable;
import maware.util.timer;

import opentaiko.bashable.bashable;

import std.algorithm.sorting : sort;

/// Assumes every time scroll value is changed that a new group of objects
/// follow. Sorts objects by time of appearance, and renders them optimally.
class RenderQueue : Renderable {

	/// Holds hit objects in a group and renders them efficiently.
	class ObjectGroup {

	    private Bashable[] hitObjects;
		private int hitObjectIndex;
		const int firstAppearance; /// Time first object becomes visible
		const int lastAppearance; /// Latest time an object is visible

		this(Bashable[] hitObjects, double scroll, int maxOffset) {
			this.hitObjects = hitObjects;
			int first = int.max;
			int last = 0;
			foreach (Bashable object ; hitObjects) {
				int basePosition = object.actualPosition();
				int firstPosition = basePosition + cast(int)(maxOffset / scroll);
				if (firstPosition < first) {
					first = firstPosition;
				}
				int longestPosition = (basePosition
									   + cast(int)(object.getObjectLength()
												   / scroll));
				if (longestPosition > last) {
					last = longestPosition;
				}
			}
			firstAppearance = first;
			lastAppearance = last;
		}

		/// Renders all hitObjects from time, excluding those outside the play
		/// area (> time + largestOffset)
		void render(int largestOffset) {
			foreach (Bashable hitObject ; hitObjects[hitObjectIndex
													 ..
													 hitObjects.length]) {
				if (hitObject.currentPosition > largestOffset) {
					break;
				} else if (hitObject.isFinished) {
					hitObjectIndex++;
				} else {
					hitObject.render();
				}
			}
		}

	}

	private ObjectGroup[] objectGroups;
	private Timer gameplayTimer;
	private int objectGroupIndex;
	private const int maxOffset;

	this(Bashable[] hitObjects, Timer gameplayTimer, int maxOffset) {
		this.gameplayTimer = gameplayTimer;
		this.maxOffset = maxOffset;
		Bashable[] acc;
		double scroll = hitObjects.length > 0 ? hitObjects[0].scroll : 0.0;
		void addObjects() {
			ObjectGroup newGroup = new ObjectGroup(acc, scroll, maxOffset);
			objectGroups ~= newGroup;
		}
		foreach (Bashable b ; hitObjects) {
			if (b.scroll != scroll) {
				addObjects();
				scroll = b.scroll;
				acc = null;
			}
			acc ~= b;
		}
		if (acc.length > 0) {
			addObjects();
		}
		objectGroups.sort!("a.firstAppearance < b.firstAppearance");
	}

	void render() {
		if (objectGroupIndex >= objectGroups.length) {
			return;
		}
		const long currentOffset = gameplayTimer.getTimerPassed();
		if (objectGroups[objectGroupIndex].lastAppearance < currentOffset) {
			objectGroupIndex++;
		}
		foreach (ObjectGroup g ; objectGroups[objectGroupIndex
											  ..
											  objectGroups.length]) {
			g.render(maxOffset);
		}
	}

}
