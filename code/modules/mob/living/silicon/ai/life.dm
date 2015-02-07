/mob/living/silicon/ai/Life()
	if (src.stat == 2)
		return
	else //I'm not removing that shitton of tabs, unneeded as they are. -- Urist
		//Being dead doesn't mean your temperature never changes
		var/turf/T = get_turf(src)

		if (src.stat!=0)
			src.cameraFollow = null
			src.reset_view(null)
			src.unset_machine()

		src.updatehealth()

		if (!hardware_integrity() || !backup_capacitor())
			death()
			return

		if(!psupply)
			create_powersupply()

		if (src.machine)
			if (!( src.machine.check_eye(src) ))
				src.reset_view(null)

		// Handle power damage (oxy)
		if(aiRestorePowerRoutine != 0 && !APU_power)
			// Los� power
			adjustOxyLoss(1)
		else
			// Gain Power
			aiRestorePowerRoutine = 0
			adjustOxyLoss(-1)

		malf_process()

		if(APU_power && (hardware_integrity() < 50))
			src << "<span class='notice'><b>APU GENERATOR FAILURE! (System Damaged)</b></span>"
			stop_apu(1)

		// Handle EMP-stun
		handle_stunned()

		var/blind = 0
		var/area/loc = null
		if (istype(T, /turf))
			loc = T.loc
			if (istype(loc, /area))
				if ((!loc.master.power_equip && !istype(src.loc,/obj/item)) && !APU_power)
					blind = 1

		if (!blind)
			src.sight |= SEE_TURFS
			src.sight |= SEE_MOBS
			src.sight |= SEE_OBJS
			src.see_in_dark = 8
			src.see_invisible = SEE_INVISIBLE_LIVING

			if (src:aiRestorePowerRoutine==2)
				src << "Alert cancelled. Power has been restored without our assistance."
				src:aiRestorePowerRoutine = 0
				src.blind.layer = 0
				return
			else if (src:aiRestorePowerRoutine==3)
				src << "Alert cancelled. Power has been restored."
				src:aiRestorePowerRoutine = 0
				src.blind.layer = 0
				return
			else if (APU_power)
				src:aiRestorePowerRoutine = 0
				src.blind.layer = 0
				return
		else

			src.blind.screen_loc = "1,1 to 15,15"
			if (src.blind.layer!=18)
				src.blind.layer = 18
			src.sight = src.sight&~SEE_TURFS
			src.sight = src.sight&~SEE_MOBS
			src.sight = src.sight&~SEE_OBJS
			src.see_in_dark = 0
			src.see_invisible = SEE_INVISIBLE_LIVING



			if (((!loc.master.power_equip) || istype(T, /turf/space)) && !istype(src.loc,/obj/item) && !APU_power)
				if (src:aiRestorePowerRoutine==0)
					src:aiRestorePowerRoutine = 1

					src << "You've lost power!"
					spawn(20)
						src << "Backup battery online. Scanners, camera, and radio interface offline. Beginning fault-detection."
						sleep(50)
						if (loc.master.power_equip)
							if (!istype(T, /turf/space))
								src << "Alert cancelled. Power has been restored without our assistance."
								src:aiRestorePowerRoutine = 0
								src.blind.layer = 0
								return
						src << "Fault confirmed: missing external power. Shutting down main control system to save power."
						sleep(20)
						src << "Emergency control system online. Verifying connection to power network."
						sleep(50)
						if (istype(T, /turf/space))
							src << "Unable to verify! No power connection detected!"
							src:aiRestorePowerRoutine = 2
							return
						src << "Connection verified. Searching for APC in power network."
						sleep(50)
						var/obj/machinery/power/apc/theAPC = null
						var/PRP //like ERP with the code, at least this stuff is no more 4x sametext
						for (PRP=1, PRP<=4, PRP++)
							var/area/AIarea = get_area(src)
							for(var/area/A in AIarea.master.related)
								for (var/obj/machinery/power/apc/APC in A)
									if (!(APC.stat & BROKEN))
										theAPC = APC
										break
							if (!theAPC)
								switch(PRP)
									if (1) src << "Unable to locate APC!"
									else src << "Lost connection with the APC!"
								src:aiRestorePowerRoutine = 2
								return
							if (loc.master.power_equip)
								if (!istype(T, /turf/space))
									src << "Alert cancelled. Power has been restored without our assistance."
									src:aiRestorePowerRoutine = 0
									src.blind.layer = 0 //This, too, is a fix to issue 603
									return
							switch(PRP)
								if (1) src << "APC located. Optimizing route to APC to avoid needless power waste."
								if (2) src << "Best route identified. Hacking offline APC power port."
								if (3) src << "Power port upload access confirmed. Loading control program into APC power port software."
								if (4)
									src << "Transfer complete. Forcing APC to execute program."
									sleep(50)
									src << "Receiving control information from APC."
									sleep(2)
									//bring up APC dialog
									apc_override = 1
									theAPC.attack_ai(src)
									apc_override = 0
									src:aiRestorePowerRoutine = 3
									src << "Here are your current laws:"
									src.show_laws()
							sleep(50)
							theAPC = null

	regular_hud_updates()
	switch(src.sensor_mode)
		if (SEC_HUD)
			process_sec_hud(src,0,src.eyeobj)
		if (MED_HUD)
			process_med_hud(src,0,src.eyeobj)

/mob/living/silicon/ai/updatehealth()
	if(status_flags & GODMODE)
		health = 100
		stat = CONSCIOUS
		setOxyLoss(0)
	else
		health = 100 - getToxLoss() - getFireLoss() - getBruteLoss()

/mob/living/silicon/ai/rejuvenate()
	..()
	add_ai_verbs(src)