//  This file is part of the OpenTaiko project.
//  <https://github.com/gtensha/OpenTaiko>
//
/// This module contains the interface for AudioMixer.
///
/// Authors: gtensha (@skyhvelv.net)
/// Copyright: 2017-2018 gtensha
/// License: GNU GPLv3 (no later versions)
//
//  You should have received a copy of the GNU General Public License
//  along with OpenTaiko. If not, see <https://www.gnu.org/licenses/>.

module maware.audio.mixer;

/// An interface for a class implementing an AudioMixer; handling sound effect
/// and music playback.
interface AudioMixer {

	/// Attempt loading the Mixer library
	static void initialise();

	/// Closes the audio library
	static void deInitialise();

	/// Register a sound effect into the system
	public void registerSFX(int id, string src);

	/// Register a music track into the system
	public void registerMusic(string title, string src);

	public bool isRegistered(string track);

	/// Gets the position (in ms) of any playing or paused music, < 1 if not
	/// playing
	public int getMusicPosition();

	/// Plays the already registered music track with the given title, looping
	/// loop times (or loop < 1, infinite loop)
	public void playTrack(string title, int loop);

	public void playTrackLooped(string);

	/// Pauses any currently playing music
	public void pauseMusic();

	/// Stops any currently playing or paused music (rewinds it, unqueues it)
	public void stopMusic();

	/// Resume playback of any paused music
	public void resumeMusic();

	/// Plays the sound effect with the registered ID
	public void playSFX(int id);

}
