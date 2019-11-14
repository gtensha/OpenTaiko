//  This file is part of the OpenTaiko project.
//  <https://github.com/gtensha/OpenTaiko>
//
/// The primary method of putting textures on the screen, as well as being the
/// superclass for Text. Functionality that can be shared by other derived
/// classes should be implemented here.
//
/// Authors: gtensha (@skyhvelv.net)
/// Copyright: 2017-2018 gtensha
/// License: GNU GPLv3 (no later versions)
//
//  You should have received a copy of the GNU General Public License
//  along with OpenTaiko. If not, see <https://www.gnu.org/licenses/>.

module maware.renderable.textured;

import maware.renderable.solid;

import derelict.sdl2.sdl : SDL_Texture,
						   SDL_Rect,
						   SDL_QueryTexture,
						   SDL_RenderCopy,
						   SDL_Renderer;

class Textured : Solid {

	protected SDL_Texture* texture;

	this(SDL_Texture* texture,
		 int w, int h, int x, int y,
		 ubyte r, ubyte g, ubyte b, ubyte a) {

		super(w, h, x, y, r, g, b, a);
		this.texture = texture;
	}

	this(SDL_Texture* texture,
		 int w, int h, int x, int y) {

		super(w, h, x, y, 0, 0, 0, 255);
		this.texture = texture;
	}

	this(SDL_Texture* texture,
		 int x, int y) {

		int w, h;
		SDL_QueryTexture(texture, null, null, &w, &h);
		super(w, h, x, y, 0, 0, 0, 255);
		this.texture = texture;
	}

	override public void render() {
		SDL_RenderCopy(renderer, texture, null, &rect);
	}

	public void renderPart(SDL_Rect cover) {
		SDL_Rect newPart = {rect.x, rect.y, rect.w - cover.w, rect.h - cover.h};
		cover.w = rect.w - cover.w;
		cover.h = rect.h - cover.h;
		SDL_RenderCopy(renderer, texture, &cover, &newPart);
	}

}
