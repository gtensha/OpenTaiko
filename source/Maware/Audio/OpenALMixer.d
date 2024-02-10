//  This file is part of the OpenTaiko project.
//  <https://github.com/gtensha/OpenTaiko>
//
/// Audio playback using OpenAL.
///
/// Authors: gtensha (@skyhvelv.net)
/// Copyright: 2024 gtensha
/// License: GNU GPLv3 (no later versions)
//
//  You should have received a copy of the GNU General Public License
//  along with OpenTaiko. If not, see <https://www.gnu.org/licenses/>.

module maware.audio.openalmixer;

version (OpenALMixer):

import maware.engine;
import maware.audio.mixer;

import audioformats;
import bindbc.openal;
import std.array;
import std.algorithm;
import std.conv : to;

/// An AudioMixer using the OpenAL library.
/// Uses audioformats to load different sound formats.
/// It will read entire songs into memory, which takes up some space and takes
/// extra time, but it means there will be no stuttering in I/O constrained
/// environments.
class OpenALMixer : AudioMixer {

	const int sfxSourceCount = 32;
	
	private Engine parent;
	private ALCdevice* audioDevice;
	private ALCcontext* audioContext;
	private ALuint musicSource;
	private int previousSFXSourceIndex;
	private ALuint[] sfxSources;
	private ALuint musicBuffer;
	private long musicFrequency;
	private string musicName;
	private ALuint[] effectBuffers;
	private string[string] trackLocations;
	
	/// Attempt loading the Mixer library
	static void initialise() {
		ALSupport ret = loadOpenAL();
		if (ret != ALSupport.al11) {
			if (ret == ALSupport.noLibrary) {
				throw new Exception("Failed to find OpenAL library");
			} else if (ret == ALSupport.badLibrary) {
				throw new Exception("Missing symbols in OpenAL library");
			}
		}
	}

	/// Closes the audio library
	static void deInitialise() {

	}

	static string getStringForALenum(ALenum val) {
		switch (val) {
		case AL_NO_ERROR:
			return "No error";
			
		case AL_INVALID_NAME:
			return "Invalid name";

		case AL_INVALID_ENUM:
			return "Invalid enum";

		case AL_INVALID_VALUE:
			return "Invalid value";

		case AL_INVALID_OPERATION:
			return "Invalid operation";

		case AL_OUT_OF_MEMORY:
			return "Out of memory";

		default:
			return "Unknown (" ~ to!string(val) ~ ")";
		}
	}

	static void checkError(string failMessage) {
		int errorCode = alGetError();
		if (errorCode != 0) {
			throw new Exception(failMessage ~ ": " ~ getStringForALenum(errorCode));
		}
	}

	static short getSampleFromDouble(double sample) {
		int s = cast(int)(32768.5 + sample * 32767.0);
		s -= 32768;
		return cast(short) s;
	}

	static short[] getPCMFromStream(AudioStream stream) {
		const int channels = stream.getNumChannels();
		if (channels > 2) {
			throw new Exception("Too many channels in audio file (max 2)");
		}
		const int frequency = to!int(stream.getSamplerate());
		short[] readData = [];
		double[256] buffer;
		const int framesInBuffer = cast(int) buffer.length / channels;
		size_t readSize = buffer.length;
		while (readSize == buffer.length) {
			readSize = (stream.readSamplesDouble(buffer.ptr, framesInBuffer)
						* channels);
			size_t offset = readData.length;
			readData.length += readSize;
			for (int i = 0; i < readSize; i++) {
				readData[i + offset] = getSampleFromDouble(buffer[i]);
			}
		}
		return readData;
	}

	/// Returns a reference to an audio buffer containing the audio data at
    /// the given path.
	static ALuint getAudioDataFromFile(string path) {
		AudioStream stream;
		stream.openFromFile(path);
		if (stream.isError()) {
			throw new Exception("Failed reading audio data from file: "
								~ stream.errorMessage());
		}
		short[] pcmData = getPCMFromStream(stream);
		ALuint ret;
		alGetError();
		alGenBuffers(1, &ret);
		checkError("Failed to create audio buffer");
		const ALenum format = (stream.getNumChannels() > 1
							   ? AL_FORMAT_STEREO16
							   : AL_FORMAT_MONO16);
		alBufferData(ret,
					 format,
					 pcmData.ptr,
					 cast(int) (pcmData.length * 2),
					 to!int(stream.getSamplerate()));
		checkError("Failed to buffer audio data");
		return ret;
	}

	this(Engine parent, int effectCount) {
		if (parent !is null) {
			this.parent = parent;
		} else {
			throw new Exception("Parent was null on OpenALMixer construction");
		}
		alGetError();
		audioDevice = alcOpenDevice(null);
		int errorCode = alGetError();
		if (audioDevice is null) {
			throw new Exception("Failed to open audio device with OpenAL: "
								~ to!string(errorCode));
		}
		audioContext = alcCreateContext(audioDevice, null);
		errorCode = alGetError();
		if (audioContext is null) {
			throw new Exception("Failed to open audo context on device: "
								~ to!string(errorCode));
		}
		if (!alcMakeContextCurrent(audioContext)) {
			errorCode = alGetError();
			throw new Exception("Failed to make context: "
								~ to!string(errorCode));
		}
		alGenSources(1, &musicSource);
		errorCode = alGetError();
		if (errorCode != 0) {
			throw new Exception("Failed to generate music source: "
								~ to!string(errorCode));
		}
		sfxSources = new ALuint[sfxSourceCount];
		alGenSources(sfxSourceCount, sfxSources.ptr);
		errorCode = alGetError();
		if (errorCode != 0) {
			throw new Exception("Failed to generate sfx sources: "
								~ to!string(errorCode));
		}
		effectBuffers = new ALuint[effectCount];
		trackLocations = new string[string];
	}

	~this() {
		// ALuint[] loadedEffects = effectBuffers.filter!(id => id > 0).array();
		// alSourceUnqueueBuffers(
		// if (musicBuffer != 0) {
		// 	alDeleteBuffers(1, &musicBuffer);
		// }
		alDeleteSources(1, &musicSource);
		alDeleteSources(sfxSourceCount, sfxSources.ptr);
		alcMakeContextCurrent(null);
		alcDestroyContext(audioContext);
		alcCloseDevice(audioDevice);
	}

	/// Register a sound effect into the system
	public void registerSFX(int id, string src) {
		if (effectBuffers[id] != 0) {
			alGetError();
			alDeleteBuffers(1, &effectBuffers[id]);
			checkError("Failed to delete existing audio buffer");
		}
		effectBuffers[id] = getAudioDataFromFile(src);
	}

	/// Register a music track into the system
	public void registerMusic(string title, string src) {
		trackLocations[title] = src;
	}

	public bool isRegistered(string track) {
	    return (track in trackLocations) !is null;
	}

	/// Gets the position (in ms) of any playing or paused music, < 1 if not
	/// playing
	public int getMusicPosition() {
		if (musicBuffer == 0) {
			return 0;
		} else {
			int sampleOffset;
			alGetSourcei(musicSource, AL_SAMPLE_OFFSET, &sampleOffset);
			checkError("Failed to get music sample offset");
			long sampleOffsetLong = sampleOffset * 1_000L;
			long result = sampleOffsetLong / musicFrequency;
			return cast(int) result;
		}
	}

	/// Plays the already registered music track with the given title, looping
	/// loop times (or loop < 1, infinite loop)
	public void playTrack(string title, int loop) {
		if (musicName == title) {
			alSourceRewind(musicSource);
			checkError("Failed to rewind music");
		} else {
			stopMusic();
			musicBuffer = getAudioDataFromFile(trackLocations[title]);
			alSourcei(musicSource, AL_BUFFER, musicBuffer);
			checkError("Failed to set buffer for music source");
			int sampleRate;
			alGetBufferi(musicBuffer, AL_FREQUENCY, &sampleRate);
			checkError("Failed to get music sample rate");
			musicFrequency = sampleRate;
			musicName = title;
		}
		alSourcePlay(musicSource);
		checkError("Failed to play music source");
	}

	public void playTrackLooped(string title) {
		playTrack(title, true);
	}

	/// Pauses any currently playing music
	public void pauseMusic() {
		if (musicBuffer != 0) {
			alSourcePause(musicSource);
			checkError("Failed to pause music");
		}
	}

	/// Stops any currently playing or paused music (rewinds it, unqueues it)
	public void stopMusic() {
		if (musicBuffer != 0) {
			alSourceStop(musicSource);
			checkError("Failed to stop music source");
			alSourcei(musicSource, AL_BUFFER, 0);
			checkError("Failed to remove music from source");
			alDeleteBuffers(1, &musicBuffer);
			checkError("Failed to delete music buffer");
			musicBuffer = 0;
			musicName = null;
		}
	}

	/// Resume playback of any paused music
	public void resumeMusic() {
		if (musicBuffer != 0) {
			alSourcePlay(musicSource);
			checkError("Failed to play music source");
		}
	}

	private int getSFXSourceId() {
		int ret = previousSFXSourceIndex;
		++previousSFXSourceIndex;
		if (previousSFXSourceIndex >= sfxSources.length) {
			previousSFXSourceIndex = 0;
		}
		return ret;
	}

	/// Plays the sound effect with the registered ID
	public void playSFX(int id) {
		int sourceIndex = getSFXSourceId();
		ALuint source = sfxSources[sourceIndex];
		alSourcei(source, AL_BUFFER, effectBuffers[id]);
		checkError("Failed to set audio buffer source");
		alSourcePlay(source);
		checkError("Failed to play source");
	}
	
}
