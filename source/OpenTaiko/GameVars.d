//  This file is part of the OpenTaiko project.
//  <https://github.com/gtensha/OpenTaiko>
//
/// Basic configuration values for the game. Language, display options, custom
/// assets to load, and so on.
///
/// Authors: gtensha (@skyhvelv.net)
/// Copyright: 2017-2019 gtensha
/// License: GNU GPLv3 (no later versions)
//
//  You should have received a copy of the GNU General Public License
//  along with OpenTaiko. If not, see <https://www.gnu.org/licenses/>.

module opentaiko.gamevars;

/// Structure for basic game config options
struct GameVars {

    /// Fallback keyboard mapping.
    int[4] defaultKeys;

    /// Display options.
    int[2] resolution; // w * h
    // int maxFPS
    bool vsync; /// ditto

	string assets; /// Directory in assets/ to get custom assets from.
	string language; /// Active language to load.

}
