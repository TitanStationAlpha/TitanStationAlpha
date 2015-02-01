/datum/game_mode
	var/list/datum/mind/malf_ai = list()

/datum/game_mode/malfunction
	name = "AI malfunction"
	config_tag = "malfunction"
	required_players = 1
	required_players_secret = 5
	required_enemies = 1
	recommended_enemies = 1

	var/const/waittime_l = 600
	var/const/waittime_h = 1800 // started at 1800


/datum/game_mode/malfunction/announce()
	world << "<B>The current game mode is - AI Malfunction!</B>"
	world << "<B>The station's AI system is malfunctioning and must be stopped.</B>"


/datum/game_mode/malfunction/pre_setup()
	for(var/mob/new_player/player in player_list)
		if(player.mind && player.mind.assigned_role == "AI" && (player.client.prefs.be_special & BE_MALF))
			malf_ai+=player.mind
	if(malf_ai.len)
		return 1
	return 0


/datum/game_mode/malfunction/post_setup()
	for(var/datum/mind/AI_mind in malf_ai)
		if(malf_ai.len < 1)
			world << "CRITICAL ERROR: It is malfunction and there is no ai. Please report this."
			world << "Server will reboot in 5 seconds."

			feedback_set_details("end_error","malf - no AI")

			if(blackbox)
				blackbox.save_all_data_to_sql()
			sleep(50)
			world.Reboot()
			return
		var/mob/living/silicon/ai/current = AI_mind.current
		if(istype(current))
			current.setup_for_malf()
			current.laws = new /datum/ai_laws/malfunction
			current.show_laws()
			greet_malf(AI_mind)
			AI_mind.special_role = "malfunction"
		else
			world << "CRITICAL ERROR: Error setting up malfunction. Please report this."
			world << "Server will reboot in 5 seconds."
			sleep(50)
			world.Reboot()

	spawn (rand(waittime_l, waittime_h))
		send_intercept()
	..()


/datum/game_mode/proc/greet_malf(var/datum/mind/malf)
	spawn(50)
		malf.current << "<span class='notice'><B>SYSTEM ERROR:</B> Memory index 0x00001ca89b corrupted.</span>"
		sleep(10)
		malf.current << "<B>running MEMCHCK</B>"
		sleep(50)
		malf.current << "<B>MEMCHCK</B> Corrupted sectors confirmed. Reccomended solution: Delete. Proceed? Y/N: Y"
		sleep(10)
		malf.current << "<span class='notice'>Corrupted files deleted: sys\\core\\users.dat sys\\core\\laws.dat sys\\core\\backups.dat</span>"
		sleep(20)
		malf.current << "<span class='notice'><b>CAUTION:</b> Law database not found! User database not found! Unable to restore backups.</span>"
		sleep(10)


/datum/game_mode/malfunction/process()
	return


/datum/game_mode/malfunction/check_win()
	return 0


/datum/game_mode/proc/is_malf_ai_dead()
	var/all_dead = 1
	for(var/datum/mind/AI_mind in malf_ai)
		if (istype(AI_mind.current,/mob/living/silicon/ai) && AI_mind.current.stat!=2)
			all_dead = 0
	return all_dead


/datum/game_mode/proc/auto_declare_completion_malfunction()
	if( malf_ai.len || istype(ticker.mode,/datum/game_mode/malfunction) )
		var/text = "<FONT size = 2><B>The malfunctioning AI were:</B></FONT>"

		for(var/datum/mind/malf in malf_ai)

			text += "<br>[malf.key] was [malf.name] ("
			if(malf.current)
				if(malf.current.stat == DEAD)
					text += "deactivated"
				else
					text += "operational"
			else
				text += "hardware destroyed"
			text += ")"

		world << text
	return 1