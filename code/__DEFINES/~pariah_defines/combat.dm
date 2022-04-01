/mob/living/carbon/proc/KnockToFloor(silent = TRUE, ignore_canknockdown = FALSE, knockdown_amt = 1)
	if(!silent && body_position != LYING_DOWN)
		to_chat(src, "<span class='warning'>You are knocked to the floor!</span>")
	Knockdown(knockdown_amt, ignore_canknockdown)

/mob/living/proc/StaminaKnockdown(stamina_damage, disarm, brief_stun, hardstun, ignore_canknockdown = FALSE, paralyze_amount, knockdown_amt = 1)
	if(!stamina_damage)
		return
	return Paralyze((paralyze_amount ? paralyze_amount : stamina_damage))

/mob/living/carbon/StaminaKnockdown(stamina_damage, disarm, brief_stun, hardstun, ignore_canknockdown = FALSE, paralyze_amount, knockdown_amt = 1)
	if(!stamina_damage)
		return
	if(!ignore_canknockdown && !(status_flags & CANKNOCKDOWN))
		return FALSE
	if(istype(buckled, /obj/vehicle/ridden))
		buckled.unbuckle_mob(src)
	KnockToFloor(TRUE, ignore_canknockdown, knockdown_amt)
	adjustStaminaLoss(stamina_damage)
	if(disarm)
		drop_all_held_items()
	if(brief_stun)
		//Stun doesnt send a proper signal to stand up, so paralyze for now
		Paralyze(0.25 SECONDS)
	if(hardstun)
		Paralyze((paralyze_amount ? paralyze_amount : stamina_damage))

#define HEADSMASH_BLOCK_ARMOR 20

//TODO: Add a grab state check on the do_mobs
/datum/species/proc/try_grab_maneuver(mob/living/carbon/human/user, mob/living/carbon/human/target, modifiers)
	var/obj/item/bodypart/affecting = target.get_bodypart(ran_zone(user.zone_selected))
	if(!affecting)
		return FALSE
	. = FALSE
	if(HAS_TRAIT(user, TRAIT_PACIFISM)) //They're mostly violent acts
		return
	if(user.combat_mode)
		switch(user.zone_selected)
			if(BODY_ZONE_HEAD)
				//Head slam
				if(target.body_position == LYING_DOWN)
					. = TRUE
					var/time_doing = 4 SECONDS
					if(target.stat != CONSCIOUS)
						time_doing = 2 SECONDS
						target.visible_message("<span class='danger'>[user.name] holds [target.name]'s tight and slams it down!</span>", ignored_mobs=user)
						to_chat(user, "<span class='danger'>You grasp [target.name]'s head and slam it down!</span>")
					else
						target.visible_message("<span class='danger'>[user.name] holds [target.name]'s head and tries to overpower [target.p_them()]!</span>", \
							"<span class='userdanger'>You struggle as [user.name] holds your head and tries to overpower you!</span>", ignored_mobs=user)
						to_chat(user, "<span class='danger'>You grasp [target.name]'s head and try to overpower [target.p_them()]...</span>")
					user.changeNext_move(time_doing)
					if(do_mob(user, target, time_doing))
						var/armor_block = target.run_armor_check(affecting, MELEE)
						var/head_knock = FALSE
						if(armor_block < HEADSMASH_BLOCK_ARMOR)
							head_knock = TRUE

						target.visible_message("<span class='danger'>[user.name] violently slams [target.name]'s head into the floor!</span>", \
							"<span class='userdanger'>[user.name] slams your head against the floor[head_knock ? ", knocking you out cold" : ""]!</span>", ignored_mobs=user)
						to_chat(user, "<span class='danger'>You slam [target.name] head against the floor[head_knock ? ", knocking him out cold" : ""]!</span>")

						//Check to see if our head is protected by atleast 20 melee armor
						if(head_knock)
							if(target.stat == CONSCIOUS)
								target.Unconscious(400)
							target.adjustOrganLoss(ORGAN_SLOT_BRAIN, 15)

						target.apply_damage(15, BRUTE, affecting, armor_block)
						playsound(target, 'sound/effects/hit_kick.ogg', 70)
						log_combat(user, target, "headsmashes", "against the floor (trying to knock unconscious)")

		//Chances are, no matter what you do on disarm you're gonna break your grip by accident because of shoving, let make a good use of disarm intent for maneuvers then
		if(modifiers && modifiers["right"])
			switch(user.zone_selected)
				if(BODY_ZONE_HEAD)
					//Chokehold
					. = TRUE
					user.changeNext_move(1.5 SECONDS)
					target.visible_message("<span class='danger'>[user.name] wraps his arm around [target.name]'s neck and chokes him!</span>", \
							"<span class='userdanger'>[user.name] wraps his arm around your neck and chokes you!</span>", ignored_mobs=user)
					to_chat(user, "<span class='danger'>You lock [target.name]'s neck with your arm and begin to choke [target.p_them()]...</span>")
					if(do_mob(user, target, 1.5 SECONDS))
						var/in_progress = TRUE
						log_combat(user, target, "chokeholds", "(trying to knock unconscious)")
						while(in_progress)
							user.changeNext_move(1 SECONDS)
							if(!do_mob(user, target, 1 SECONDS))
								in_progress = FALSE
								break
							to_chat(target, "<span class='warning'>[user] is choking you!</span>")
							target.losebreath = max(3, target.losebreath)
							target.adjustOxyLoss(2)
							if(target.oxyloss > 50)
								target.Unconscious(400)
				if(BODY_ZONE_CHEST)
					//Suplex!
					. = TRUE
					user.changeNext_move(3 SECONDS)
					target.visible_message("<span class='danger'>[user.name] holds [target.name] tight and starts lifting him up!</span>", \
							"<span class='userdanger'>[user.name] holds you tight and lifts you up!</span>", ignored_mobs=user)
					to_chat(user, "<span class='danger'>You hold [target.name] tight and lift him up...</span>")
					if(do_mob(user, target, 3 SECONDS))
						var/move_dir = get_dir(target, user)
						var/moved_turf = get_turf(target)
						for(var/i in 1 to 2)
							var/turf/next_turf = get_step(moved_turf, move_dir)
							if(IS_OPAQUE_TURF(next_turf))
								break
							moved_turf = next_turf
						target.visible_message("<span class='danger'>[user.name] suplexes [target.name] down to the ground!</span>", \
							"<span class='userdanger'>[user.name] suplexes you!</span>", ignored_mobs=user)
						to_chat(user, "<span class='danger'>You suplex [target.name]!</span>")
						user.StaminaKnockdown(30, TRUE, TRUE)
						user.SpinAnimation(7,1)
						target.SpinAnimation(7,1)
						target.throw_at(moved_turf, 1, 1)
						target.StaminaKnockdown(80)
						target.Paralyze(2 SECONDS)
						log_combat(user, target, "suplexes", "down on the ground (knocking down both)")
				else
					var/datum/wound/blunt/blute_wound = affecting.get_wound_type(/datum/wound/blunt)
					if(blute_wound && blute_wound.severity >= WOUND_SEVERITY_MODERATE)
						//At this point we'll be doing the medical action that's not a grab manevour
						return
					//Dislocation
					. = TRUE
					user.changeNext_move(4 SECONDS)
					target.visible_message("<span class='danger'>[user.name] twists [target.name]'s [affecting.name] violently!</span>", \
							"<span class='userdanger'>[user.name] twists your [affecting.name] violently!</span>", ignored_mobs=user)
					to_chat(user, "<span class='danger'>You start twisting [target.name]'s [affecting.name] violently!</span>")
					if(do_mob(user, target, 4 SECONDS))
						target.visible_message("<span class='danger'>[user.name] dislocates [target.name]'s [affecting.name]!</span>", \
							"<span class='userdanger'>[user.name] dislocates your [affecting.name]!</span>", ignored_mobs=user)
						to_chat(user, "<span class='danger'>You dislocate [target.name]'s [affecting.name]!</span>")
						affecting.force_wound_upwards(/datum/wound/blunt/moderate)
						log_combat(user, target, "dislocates", "the [affecting.name]")

	if(.)
		user.changeNext_move(CLICK_CD_MELEE)
	return

#undef HEADSMASH_BLOCK_ARMOR
