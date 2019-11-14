//  This file is part of the OpenTaiko project.
//  <https://github.com/gtensha/OpenTaiko>
//
/// GUI element for displaying position among "pages" of a vertically expanding
/// menu.
///
/// Authors: gtensha (@skyhvelv.net)
/// Copyright: 2019 gtensha
/// License: GNU GPLv3 (no later versions)
//
//  You should have received a copy of the GNU General Public License
//  along with OpenTaiko. If not, see <https://www.gnu.org/licenses/>.

module maware.renderable.menus.scrollbar;

import maware.font;
import maware.renderable.menus.verticalmenu;
import maware.renderable.renderable;
import maware.renderable.solid;
import maware.renderable.text;

import derelict.sdl2.sdl : SDL_Color;

import std.math : ceil;

/// A class representing a renderable scrollbar for visually conveying page
/// numbers, etc.
class ScrollBar : Renderable {

	enum UP_MARKER = "▲";
	enum DOWN_MARKER = "▼";
	enum SCROLLBAR_WIDTH = VerticalMenu.BUTTON_SPACING / 2;
	enum SCROLLBAR_ELM_SPACING = 5;

	private int xPos;
	private int yPos;
	private int height;

	protected Solid upMarker;
	protected Solid scrollBar;
	protected Solid downMarker;

	this(Font barMarkerFont,
		 int height,
		 int x,
		 int y,
		 SDL_Color barColor) {

		xPos = x;
		yPos = y;
		this.height = height;
		
		int barX = x;
		this.upMarker = new Text(UP_MARKER,
								 barMarkerFont.get(SCROLLBAR_WIDTH + 1),
								 true,
								 barX,
								 y,
								 barColor);
		int barY = upMarker.rect.y + upMarker.rect.h + SCROLLBAR_ELM_SPACING;
		this.scrollBar = new Solid(SCROLLBAR_WIDTH,
								   0,
								   barX,
								   barY,
								   barColor);
		this.downMarker = new Text(DOWN_MARKER,
								   barMarkerFont.get(SCROLLBAR_WIDTH + 1),
								   true,
								   barX,
								   0,
								   barColor);
		this.downMarker.rect.y = y + height - downMarker.rect.h;
	}

	/// Alternative convenience overload of update aimed at menus that don't keep
	/// page amount recorded.
	public void update(int currentPage,
					   int elementsPerPage,
					   int elementCount) {

		if (elementCount > elementsPerPage) {
			int pageAmount = cast(int)ceil((cast(double)elementCount
											/ elementsPerPage));
			update(currentPage, pageAmount);
		} else {
			scrollBar.rect.h = 0;
			scrollBar.rect.y = yPos + upMarker.rect.h + SCROLLBAR_ELM_SPACING;
		}
	}

	/// Updates the state of the scrollbar by setting the correct height and y
	/// position of the scrollBar rect according to currentPage number and
	/// pageAmount of pages.
	public void update(int currentPage, int pageAmount) {
		if (pageAmount < 2) {
			scrollBar.rect.h = 0;
			scrollBar.rect.y = yPos + upMarker.rect.h + SCROLLBAR_ELM_SPACING;
		} else {
			scrollBar.rect.h = cast(int)((1.0 / pageAmount)
										 * (height
											- upMarker.rect.h
											- downMarker.rect.h
											- 2 * SCROLLBAR_ELM_SPACING));
			scrollBar.rect.y = (yPos
								+ upMarker.rect.h
								+ SCROLLBAR_ELM_SPACING
								+ scrollBar.rect.h * (currentPage));
		}
	}

	public void render() {
		if (scrollBar.rect.h > 0) {
			upMarker.render();
			downMarker.render();
			scrollBar.render();
		}
	}

	/// Set the X coordinate of all scrollbar elements.
	public void setX(int pos) {
		upMarker.rect.x = pos;
		downMarker.rect.x = pos;
		scrollBar.rect.x = pos;
		xPos = pos;
	}

	/// Set the Y coordinate of the upper scrollbar element and move underlaying
	/// elements the same distance, relatively.
	public void setY(int pos) {
		int barDiff = scrollBar.rect.y - upMarker.rect.y;
		int downDiff = downMarker.rect.y - upMarker.rect.y;
		upMarker.rect.y = pos;
		downMarker.rect.y = pos + downDiff;
		scrollBar.rect.y = pos + barDiff;
		yPos = pos;
	}

}
