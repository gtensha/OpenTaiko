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

			throw new Exception(to!string("Failed to load SDL_Mixer: " ~ fromStringz(SDL_GetError())));
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

	public void registerSFX(int id, string src) {

		if (sfx[id] is null) {
			Mix_Chunk* temp = Mix_LoadWAV(toStringz(src));
			if (temp is null) {
				throw new Exception(to!string(fromStringz(SDL_GetError())));
			}
			sfx[id] = temp;
		} else {
			throw new Exception("Error: already registered");
		}
	}

}
