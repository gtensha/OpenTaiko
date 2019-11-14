//  This file is part of the OpenTaiko project.
//  <https://github.com/gtensha/OpenTaiko>
//
/// Stores basic info on a player.
///
/// Authors: gtensha (@skyhvelv.net)
/// Copyright: 2018 gtensha
/// License: GNU GPLv3 (no later versions)
//
//  You should have received a copy of the GNU General Public License
//  along with OpenTaiko. If not, see <https://www.gnu.org/licenses/>.

module opentaiko.player;

/// Structure representing a player profile
struct Player {
	
	string name; /// The player's nickname
	int id; /// Unique ID of the player
	int[] keybinds; /// The player's keybindings
	
}
