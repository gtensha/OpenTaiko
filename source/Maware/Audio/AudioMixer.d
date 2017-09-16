import Engine : Engine;

import std.string : fromStringz, toStringz;
import std.conv : to;

import derelict.sdl2.sdl : SDL_GetError;
import derelict.sdl2.mixer;

class AudioMixer {

	// The parent game engine of this AudioMixer
	private Engine parent;

	// AAs of all registered sound effects and music
	Mix_Chunk*[256] sfx;
	Mix_Music*[string] music;

	this(Engine parent) {
		this.parent = parent;

		try {
			DerelictSDL2Mixer.load();
		} catch (Exception e) {
			throw new Exception("Failed to load SDL_Mixer: " ~ e.msg);
		}

		if (Mix_OpenAudio(MIX_DEFAULT_FREQUENCY,
						  MIX_DEFAULT_FORMAT,
						  MIX_DEFAULT_CHANNELS,
						  1024) < 0) {

			throw new Exception(to!string("Failed to load SDL_Mixer: "
										  ~ fromStringz(Mix_GetError())));
		}

		Mix_AllocateChannels(sfx.length);
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

	// Register a sound effect into the system
	public void registerSFX(int id, string src) {

		Mix_Chunk* temp = Mix_LoadWAV(toStringz(src));
		if (temp is null) {
			throw new Exception(to!string(fromStringz(Mix_GetError())));
		}
		sfx[id] = temp;
	}

	// Register a music track into the system
	public void registerMusic(string title, string src) {

		Mix_Music* temp = Mix_LoadMUS(toStringz(src));
		if (temp is null) {
			throw new Exception(to!string(fromStringz(Mix_GetError())));
		}
		music[title] = temp;
	}

	// Plays the already registered music track with the given title
	public void playTrack(string title) {
		Mix_PauseMusic();
		if (Mix_PlayMusic(music[title], 1) < 0) {
			parent.notify(to!string("Failed to play track \"" ~ title ~ "\": "
						  			~ fromStringz(Mix_GetError())));
		}
	}

	// Pauses any currently playing music
	public void pauseMusic() {
		Mix_PauseMusic();
	}

	// Resume playback of any paused music
	public void resumeMusic() {
		Mix_ResumeMusic();
	}

	// Plays the sound effect with the registered ID
	public void playSFX(int id) {
		Mix_PlayChannel(id, sfx[id], 0);
	}

}
