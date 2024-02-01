//  This file is part of the OpenTaiko project.
//  <https://github.com/gtensha/OpenTaiko>
//
/// Keeps colours consistent and changeable in the game. Defines default
/// colour values for various GUI elements.
///
/// Authors: gtensha (@skyhvelv.net)
/// Copyright: 2018 gtensha
/// License: GNU GPLv3 (no later versions)
//
//  You should have received a copy of the GNU General Public License
//  along with OpenTaiko. If not, see <https://www.gnu.org/licenses/>.

module opentaiko.palette;

import bindbc.sdl : SDL_Color;

struct ColorPalette {
	
	SDL_Color backgroundColor,
			  uiColorMain,
			  uiColorSecondary,
			  cardColor,
			  cardTextColor,
			  inactiveButtonColor,
			  activeButtonColor,
			  buttonTextColor,
			  redDrumColor,
			  blueDrumColor,
			  goodNotifyColor,
			  okNotifyColor,
			  badNotifyColor,
			  playAreaUpper,
			  playAreaConveyor,
			  playAreaLower;
	
}

immutable static ColorPalette standardPalette;

shared static this() {
	
	const SDL_Color backgroundColor = {r:0x10, g:0x20, b:0x27, a:0xff};
	const SDL_Color uiColorMain = {r:0x37, g:0x47, b:0x4f, a:0xff};
	const SDL_Color uiColorSecondary = {r:0xad, g:0x13, b:0x57, a:0xff};
	const SDL_Color cardColor = {r:0x62, g:0x72, b:0x7b, a:0xff};
	const SDL_Color cardTextColor = {r:0xff, g:0xff, b:0xff, a:0xff};
	const SDL_Color inactiveButtonColor = uiColorSecondary;//{r:0xd8, g:0x1b, b:0x60, a:0xff};
	const SDL_Color activeButtonColor = uiColorSecondary;//{r:0xff, g:0x5c, b:0x8d, a:0xff};
	const SDL_Color buttonTextColor = {r:0xfd, g:0xfd, b:0xfd, 0xff};
	const SDL_Color redDrumColor = {r:0xc5, g:0x11, b:0x62, a:0xff};
	const SDL_Color blueDrumColor = {r:0x64, g:0xdd, b:0x17, a:0xff};
	const SDL_Color goodNotifyColor = {r:0xee, g:0xff, b:0x41, a:0xff};
	const SDL_Color okNotifyColor = {r:0x84, g:0xff, b:0xff, a:0xff};
	const SDL_Color badNotifyColor = {r:0xff, g:0x17, b:0x44, a:0xff};
	
	ColorPalette newPalette;
	newPalette.backgroundColor = backgroundColor;
	newPalette.uiColorMain = uiColorMain;
	newPalette.uiColorSecondary = uiColorSecondary;
	newPalette.cardColor = cardColor;
	newPalette.cardTextColor = cardTextColor;
	newPalette.inactiveButtonColor = inactiveButtonColor;
	newPalette.activeButtonColor = activeButtonColor;
	newPalette.buttonTextColor = buttonTextColor;
	newPalette.redDrumColor = redDrumColor;
	newPalette.blueDrumColor = blueDrumColor;
	newPalette.goodNotifyColor = goodNotifyColor;
	newPalette.okNotifyColor = okNotifyColor;
	newPalette.badNotifyColor = badNotifyColor;
	newPalette.playAreaUpper = cardColor;
	newPalette.playAreaConveyor = backgroundColor;
	newPalette.playAreaLower = uiColorMain;
	
	standardPalette = newPalette;
	
}
