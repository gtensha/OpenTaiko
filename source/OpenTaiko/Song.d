//  This file is part of the OpenTaiko project.
//  <https://github.com/gtensha/OpenTaiko>
//
/// Song metadata.
///
/// Authors: gtensha (@skyhvelv.net)
/// Copyright: 2017-2018 gtensha
/// License: GNU GPLv3 (no later versions)
//
//  You should have received a copy of the GNU General Public License
//  along with OpenTaiko. If not, see <https://www.gnu.org/licenses/>.

module opentaiko.song;

import opentaiko.difficulty;

struct Song {

    string title;
    string artist;
    string maintainer;
    string[] tags;

    string src;
	string directory;

    Difficulty[] difficulties;

}
