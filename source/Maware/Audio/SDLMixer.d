module maware.audio.sdlmixer;

import maware.engine;
import maware.audio.mixer;

import std.string : fromStringz, toStringz;
import std.conv : to;

import derelict.sdl2.sdl : SDL_GetError;
import derelict.sdl2.mixer;

/// A class for playing music and SFX using SDL_Mixer.
/// Must be initialised before using; see initialise()
class SDLMixer : AudioMixer {

	private static bool isInit;

	/// The parent game engine of this AudioMixer
	private Engine parent;

	/// AAs of all registered sound effects and music
	Mix_Chunk*[256] sfx;
	Mix_Music*[string] music; /// ditto

	/// Attempt loading the SDL_Mixer library. Needed to successfully construct
	/// an object of this class. Throws exceptions on load failure.
	static void initialise(int frequency, ushort format, int channels) {

		try {
			DerelictSDL2Mixer.load();
		} catch (Exception e) {
			throw new Exception("Failed to load SDL_Mixer: " ~ e.msg);
		}

		if (Mix_OpenAudio(frequency,
						  format,
						  channels,
						  1024) < 0) {

			throw new Exception(to!string("Failed to load SDL_Mixer: "
										  ~ fromStringz(Mix_GetError())));
		}

		Mix_AllocateChannels(sfx.length);

		isInit = true;

	}

	/// Call initialise with default frequency, format and channel count
	static void initialise() {
		initialise(MIX_DEFAULT_FREQUENCY,
				   MIX_DEFAULT_FORMAT,
				   MIX_DEFAULT_CHANNELS);
	}

	/// Closes the audio library. Do this only after all resources made by
	/// this class have been freed!
	static void deInitialise() {
		Mix_CloseAudio();
	}

	/// Create a new AudioMixer with given parent Engine
	this(Engine parent) {

		if (!isInit) {
			throw new Exception("Library was not initialised");
		}

		if (parent is null) {
			throw new Exception("Parent cannot be null");
		} else {
			this.parent = parent;
		}

	}

	~this() {
		foreach (Mix_Chunk* effect ; sfx) {
			if (effect !is null)
				Mix_FreeChunk(effect);
		}

		foreach (Mix_Music* track ; music) {
			Mix_FreeMusic(track);
		}

		Mix_CloseAudio();
	}

	/// Register a sound effect into the system
	public void registerSFX(int id, string src) {

		Mix_Chunk* temp = Mix_LoadWAV(toStringz(src));
		if (temp is null) {
			throw new Exception(to!string(fromStringz(Mix_GetError())));
		}
		sfx[id] = temp;
	}

	/// Register a music track into the system
	public void registerMusic(string title, string src) {

		Mix_Music* temp = Mix_LoadMUS(toStringz(src));
		if (temp is null) {
			throw new Exception(to!string(fromStringz(Mix_GetError())));
		}
		music[title] = temp;
	}

	public bool isRegistered(string track) {
		return ((track in music) !is null) ? true : false;
	}

	/// Not implemented
	public int getMusicPosition() {
		return -1;
	}

	/// Plays the already registered music track with the given title
	public void playTrack(string title, int loop) {
		//Mix_PauseMusic();
		if (Mix_PlayMusic(music[title], loop) < 0) {
			parent.notify(to!string("Failed to play track \"" ~ title ~ "\": "
						  			~ fromStringz(Mix_GetError())));
		}
		resumeMusic();
	}

	/// Plays a track, looped
	public void playTrackLooped(string title) {
		if (Mix_PlayMusic(music[title], -1) < 0) {
			parent.notify(to!string("Failed to play track \"" ~ title ~ "\": "
						  			~ fromStringz(Mix_GetError())));
		}
		resumeMusic();
	}

	/// Pauses any currently playing music
	public void pauseMusic() {
		Mix_PauseMusic();
	}

	public void stopMusic() {
		Mix_PauseMusic();
		Mix_RewindMusic();
	}

	/// Resume playback of any paused music
	public void resumeMusic() {
		Mix_ResumeMusic();
	}

	/// Plays the sound effect with the registered ID
	public void playSFX(int id) {
		Mix_PlayChannel(id, sfx[id], 0);
	}

}
