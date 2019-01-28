module maware.audio.sfmlmixer;

version (SFMLMixer) {

import maware.engine;
import maware.audio.mixer;

import derelict.sfml2.audio;

import std.string : toStringz;

/// An AudioMixer using the SFML2 library
class SFMLMixer : AudioMixer {

	private Engine parent;

	private sfMusic*[string] tracks; /// Music tracks
	private sfSound*[] effects; /// Sound effects

	private sfMusic* currentlyPlaying; /// Song currently playing (or paused)

	/// Link the libcsfml libraries dynamically
	static void initialise() {
		DerelictSFML2Audio.load();
	}

	/// Not implemented
	static void deInitialise() {

	}

	/// Create a new mixer with given parent and max amount of sound effects
	this(Engine parent, int effectCount) {
		if (parent !is null) {
			this.parent = parent; 
		} else {
			throw new Exception("Parent was null");
		}
		
		effects = new sfSound*[effectCount];
	}

	~this() {
		foreach (sfMusic* track ; tracks) {
			sfMusic_destroy(track);
		}

		foreach (sfSound* effect ; effects) {
			if (effect !is null) {
				destroyEffect(effect);
			}
		}
	}
	
	private static void destroyEffect(sfSound* effect) {
		sfSoundBuffer_destroy(cast(sfSoundBuffer*)sfSound_getBuffer(effect));
		sfSound_destroy(effect);
	}

	// TODO: mp3 support

	/// Registers sound effect from path src to id
	void registerSFX(int id, string src) {
		sfSoundBuffer* newEffect = sfSoundBuffer_createFromFile(toStringz(src));
		sfSound* newSound = sfSound_create();
		sfSound_setBuffer(newSound, newEffect);
		if (newEffect !is null) {
			if (effects[id] !is null) {
				destroyEffect(effects[id]);
			}
			effects[id] = newSound;
		} else {
			throw new Exception("Failed to load " ~ src);
		}
	}

	/// Registers the track using title, from the path src into the system
	void registerMusic(string title, string src) {
		sfMusic* newTrack = sfMusic_createFromFile(toStringz(src));
		if (newTrack !is null) {
			if (isRegistered(title)) {
				sfMusic_destroy(tracks[title]);
			}
			tracks[title] = newTrack;
		} else {
			// TODO: proper error handling, display reason
			throw new Exception("Failed loading track " ~ title ~ " from " ~ src);
		}
	}

	/// Returns true if a track with this title has been registered 
	/// (and can be played)
	bool isRegistered(string track) {
		return (track in tracks) !is null;
	}

	/// Returns music playback position in milliseconds
	int getMusicPosition() {
		return cast(int)sfMusic_getPlayingOffset(currentlyPlaying).microseconds / 1000;
		//return sfTime_asMilliseconds(position);
	}

	/// Plays the track with title (if registered) and sets it as active.
	/// Loops it if loop < 1 (plays it once if this is not the case)
	void playTrack(string title, int loop) {
		sfMusic** toPlay = title in tracks;
		if (toPlay !is null) {
			currentlyPlaying = *toPlay;
			if (loop < 1) {
				sfMusic_setLoop(currentlyPlaying, true);
			} else {
				sfMusic_setLoop(currentlyPlaying, false);
			}
			sfMusic_play(*toPlay);
		} else {
			throw new Exception("Unregistered track");
		}
	}

	/// Calls playTrack with loop = 0
	deprecated void playTrackLooped(string title) {
		playTrack(title, 0);
	}

	/// Pause music playback
	void pauseMusic() {
		sfMusic_pause(currentlyPlaying);
	}

	/// Stop music playback (reset playing position)
	void stopMusic() {
		if (currentlyPlaying !is null) {
			sfMusic_stop(currentlyPlaying);
		}
	}

	/// Resume playing last played or paused track
	void resumeMusic() {
		sfMusic_play(currentlyPlaying);
	}

	/// Play the sound effect with the given id
	void playSFX(int id) {
		sfSound_play(effects[id]);
	}

}

}
