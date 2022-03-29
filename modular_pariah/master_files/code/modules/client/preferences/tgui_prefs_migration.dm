/datum/preferences/proc/migrate_skyrat(savefile/S)
	if(features["flavor_text"])
		write_preference(GLOB.preference_entries[/datum/preference/text/flavor_text], features["flavor_text"])

	var/ooc_prefs
	READ_FILE(S["ooc_prefs"], ooc_prefs)
	if(ooc_prefs)
		write_preference(GLOB.preference_entries[/datum/preference/text/ooc_notes], ooc_prefs)
