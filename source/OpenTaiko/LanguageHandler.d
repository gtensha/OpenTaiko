module opentaiko.languagehandler;

import opentaiko.mapgen;

import std.ascii : toUpper;
import std.array : split, join;
import std.conv : to;
import std.stdio : writeln;
import std.string : capitalize;
import std.typecons : Tuple;

/// Returns the first word before an underscore or empty string if none in
/// index 0, and the rest of the string in 1
pure string[2] separateFirstUnderscore(string input) {
	string[2] ret;
	string[] separated = input.split("_");
	if (separated.length > 1) {
		ret[1] = separated[1 .. separated.length].join("_");
		ret[0] = separated[0];
	} else {
		ret[1] = input;
	}
	return ret;
}

/// Assumes all strings in each messages array start with the same prefix
/// and uses it in makeEnum to create enums for each
pure string makeEnums(immutable string[][] messages) {
	int accNum = 0;
	string accString;
	foreach (immutable string[] messageList ; messages) {
		if (messageList.length < 1)
			continue;
		string prefix = separateFirstUnderscore(messageList[0])[0].capitalize();
		string[] newMessageList = new string[messageList.length];
		foreach (int i, string message ; messageList) {
			newMessageList[i] = separateFirstUnderscore(message)[1];
		}
		accString ~= makeEnum(prefix, newMessageList, accNum) ~ "\n";
		accNum += newMessageList.length;
	}
	return accString ~ "enum MESSAGE_AMOUNT = " ~ to!string(accNum) ~ ";";
}

/// Returns a string of the enum named with Title, and all values as capitalised
/// versions of the strings in inputs, where their integer value is incremented
/// from and including minValue
pure string makeEnum(string title, string[] inputs, immutable int minValue) {
	string toUppercase(immutable string input) {
		char[] newName = new char[input.length];
		for (int i = 0; i < input.length; i++) {
			newName[i] = input[i].toUpper();
		}
		return cast(string)newName;
	}
	int currValue = minValue;
	string ret = "enum " ~ title ~ " : int {";
	foreach (string input ; inputs) {
		ret ~= toUppercase(input) ~ " = " ~ to!string(currValue++) ~ ",";
	}
	return ret ~ "}";
}

/// Shortening function for Message.getPhrase()
string phrase(int id) {
	return Message.getPhrase(id);
}

/// Class storing localisation options.
/// Different language localisations are stored in json files in a specified
/// directory. It is read during startup, and available languages are put
/// in an associative array. Calling getPhrase() for any defined value will
/// return the active language's definition of that phrase.
///
/// Phrase ID enums are constructed from all the different message id arrays
/// at compile time, so only adding string ID definitions will also generate
/// an associated enum value.
///
/// Enum values are made assuming the following form, derived from its string
/// equivalent:
/// Prefix.REST
/// where Prefix is the first word before an underscore, first letter
/// capitalised, the rest being lowercase. REST is the rest of the string
/// (excluding the underscore) with every letter capitalised.
static class Message {

	enum DEFAULT_LANGUAGE = "en"; /// will select this at runtime if available

	static immutable string[] title = [
		"title_game",
		"title_game_greeting"
	];
	
	static immutable string[] menus = [
		"menus_topbar_play",
		"menus_topbar_players",
		"menus_topbar_settings",
		
		"menus_play_arcademode",
		"menus_play_highscores",
		
		"menus_players_addplayer",
		"menus_players_addplayer_select",
		"menus_players_addplayer_selectname",
		"menus_players_addplayer_nameentry",
		"menus_players_addplayer_entername",
		"menus_players_removeplayer",
		"menus_players_removeplayer_choose",
		"menus_players_removeplayer_addplayerfirst",
		"menus_players_removeplayer_return",
		"menus_players_keybinds_change",
		"menus_players_keybinds_presskey",
		
		"menus_settings_importmap",
		"menus_settings_importmap_osz",
		"menus_settings_importmap_enter_path",
		"menus_settings_importmap_success",
		"menus_settings_songlist_reload",
		"menus_settings_vsync",
		"menus_settings_language",
		
		"menus_song_title",
		"menus_song_mapper",
		"menus_song_difficultylevel",
		"menus_song_highscores",
		
		"menus_welcometext"
	];
	
	static immutable string[] score = [
		"score_good",
		"score_ok",
		"score_bad",
		"score_combo"
	];
	
	static immutable string[] keys = [
		"keys_drum_rim_left",
		"keys_drum_center_left",
		"keys_drum_center_right",
		"keys_drum_rim_right"
	];
	
	static immutable string[] error = [
		"error_no_player_registered",
		"error_loading_settings",
		"error_loading_keymaps",
		"error_set_language_load",
		"error_loading_playerlist",
		"error_importing_map",
		"error_loading_difficulty",
		"error_no_maps_registered"
	];
	
	private static immutable string[][] allMessageIDArrays = [
		title,
		menus,
		score,
		keys,
		error
	];
	
	mixin(makeEnums(allMessageIDArrays));
	
	static immutable string[MESSAGE_AMOUNT] allMessageIDs = title ~ menus ~ score ~ keys ~ error;
	
	private static string[MESSAGE_AMOUNT][string] availableLanguages;
	private static string[MESSAGE_AMOUNT] activeLanguage;
	
	private static string[string] languageNames;
	
	static this() {
		Tuple!(string[string], string[MESSAGE_AMOUNT][string]) retTuple = MapGen.readLocaleDir(allMessageIDs);
		availableLanguages = retTuple[1];
		languageNames = retTuple[0];
		setLanguage(DEFAULT_LANGUAGE);
	}
	
	/// Sets the language of strings returned by getPhrase to the language
	/// defined by id by setting activeLanguage to the corresponding one in
	/// availableLanguages
	public static void setLanguage(string id) {
		string[MESSAGE_AMOUNT]* localisation = id in availableLanguages;
		if (localisation !is null) {
			activeLanguage = *localisation;
		} else {
			throw new Exception("Specified language does not exist");
		}
	}
	
	public static string[] getAvailableLanguages() {
		return availableLanguages.keys;
	}
	
	public static string getLanguageName(string id) {
		string* name = id in languageNames;
		if (name !is null) {
			return *name;
		} else {
			return id;
		}
	}
	
	/// Returns the phrase associated with the phraseID (accessed via its enum)
	public static string getPhrase(int phraseID) {
		return activeLanguage[phraseID];
	}

}
