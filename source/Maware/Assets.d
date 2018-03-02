module maware.assets;

import std.conv : to;
import std.exception : assumeUnique;

struct Assets {

	immutable string[string] textures;

	immutable string[string] fonts;

	immutable string[] sounds;

	this(string[string] textures, string[string] fonts, string[] sounds) immutable {
		this.textures = assumeUnique(textures);
		this.fonts = assumeUnique(fonts);
		this.sounds = sounds.idup;
	}

}
