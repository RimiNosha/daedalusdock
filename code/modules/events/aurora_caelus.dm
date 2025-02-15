/datum/round_event_control/aurora_caelus
	name = "Aurora Caelus"
	typepath = /datum/round_event/aurora_caelus
	max_occurrences = 1
	weight = 1
	earliest_start = 5 MINUTES

/datum/round_event_control/aurora_caelus/canSpawnEvent(players)
	if(!CONFIG_GET(flag/starlight))
		return FALSE
	return ..()

/datum/round_event/aurora_caelus
	announceWhen = 1
	startWhen = 9
	endWhen = 50
	var/list/aurora_colors = list("#A2FF80", "#A2FF8B", "#A2FF96", "#A2FFA5", "#A2FFB6", "#A2FFC7", "#A2FFDE", "#A2FFEE")
	var/aurora_progress = 0 //this cycles from 1 to 8, slowly changing colors from gentle green to gentle blue

/datum/round_event/aurora_caelus/announce()
	priority_announce(
		"[station_name()]: A harmless cloud of ions is approaching your station, and will exhaust their energy battering the hull. Daedalus Industries has approved a short break for all employees to relax and observe this very rare event. During this time, starlight will be bright but gentle, shifting between quiet green and blue colors. Any staff who would like to view these lights for themselves may proceed to the area nearest to them with viewing ports to open space. We hope you enjoy the lights.",
		"Ananke Meteorology Division"
	)
	for(var/V in GLOB.player_list)
		var/mob/M = V
		if((M.client.prefs.toggles & SOUND_MIDI) && is_station_level(M.z))
			M.playsound_local(M, 'sound/ambience/aurora_caelus.ogg', 20, FALSE, pressure_affected = FALSE)

/datum/round_event/aurora_caelus/start()
	for(var/turf/open/space/S in world)
		var/area/A = S.loc
		if(A.area_flags & AREA_USES_STARLIGHT)
			S.set_light(l_outer_range = S.light_outer_range * 2, l_power = S.light_power * 1.3)

/datum/round_event/aurora_caelus/tick()
	if(activeFor % 5 == 0)
		aurora_progress++
		var/aurora_color = aurora_colors[aurora_progress]
		for(var/turf/open/space/S in world)
			var/area/A = S.loc
			if(A.area_flags & AREA_USES_STARLIGHT)
				S.set_light(l_color = aurora_color)

/datum/round_event/aurora_caelus/end()
	for(var/turf/open/space/S in world)
		var/area/A = S.loc
		if(A.area_flags & AREA_USES_STARLIGHT)
			fade_to_black(S)
	priority_announce(
		"The aurora caelus event is now ending. Starlight conditions will slowly return to normal. When this has concluded, please return to your workplace and continue work as normal. Have a pleasant shift, [station_name()], and thank you for watching with us.",
		"Ananke Meteorology Division"
	)

/datum/round_event/aurora_caelus/proc/fade_to_black(turf/open/space/S)
	set waitfor = FALSE
	var/new_light = initial(S.light_outer_range)
	while(S.light_outer_range > new_light)
		S.set_light(l_outer_range = S.light_outer_range * 0.75)
		sleep(30)
	S.set_light(l_outer_range = new_light, l_power = initial(S.light_power), l_color = initial(S.light_color))
