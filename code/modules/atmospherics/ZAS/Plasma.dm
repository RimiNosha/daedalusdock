GLOBAL_DATUM_INIT(contamination_overlay, /image, image('modular_pariah/master_files/icons/effects/contamination.dmi'))

/datum/pl_control
	var/plasma_dmg = 3
	var/plasma_dmg_name = "Plasma Damage Amount"
	var/plasma_dmg_desc = "Self Descriptive"

	var/plasmaguard_only = FALSE
	var/plamaguard_only_name = "\"PlasmaGuard Only\""
	var/plasmaguard_only_desc = "If this is on, only biosuits and spacesuits protect against contamination and ill effects."

	var/genetic_corruption = 0
	var/genetic_corruption_name = "Genetic Corruption Chance"
	var/genetic_corruption_desc = "Chance of genetic corruption, X in 1,000."

	var/eye_burns = 1
	var/eye_burns_name = "Eye Burns"
	var/eye_burns_desc = "Phoron burns the eyes of anyone not wearing eye protection. Change is X * exposed_volume"

	var/phoron_hallucination = 0
	var/phoron_hallucination_name = "Phoron Hallucination"
	var/phoron_hallucination_desc = "Does being in phoron cause you to hallucinate?"


/atom/proc/expose_plasma()
	return

///Handles all the bad things phoron can do.
/mob/living/carbon/human/expose_plasma(exposed_amount)
	//Anything else requires them to not be dead.
	if(stat >= 2)
		return

	//Burn eyes if exposed.
	if(rand(1, 100) < zas_settings.plc.eye_burns * exposed_amount)
		if(!is_eyes_covered())
			var/obj/item/organ/internal/eyes/E = getorganslot(ORGAN_SLOT_EYES)
			if(E && !(E.status == ORGAN_ROBOTIC))
				if(prob(20))
					to_chat(src, span_warning("Your eyes burn!"))
				E.applyOrganDamage(2.5)
				eye_blurry = min(eye_blurry+3,50)
				if (prob(max(0, E.damage - 15) + 1) && !eye_blind)
					to_chat(src, span_danger("You are blinded!"))
					blind_eyes(20)

	//Genetic Corruption
	if(zas_settings.plc.genetic_corruption)
		if(rand(1, 1000) < zas_settings.plc.genetic_corruption * exposed_amount)
			easy_random_mutate(NEGATIVE)
			to_chat(src, "<span class='danger'>High levels of toxins cause you to spontaneously mutate!</span>")

/mob/living/carbon/human/proc/pl_head_protected()
	//Checks if the head is adequately sealed.
	if(head)
		if(zas_settings.plc.plasmaguard_only)
			if(head.obj_flags & PLASMAGUARD)
				return TRUE
		else if(is_eyes_covered())
			return TRUE
	return FALSE

/mob/living/carbon/human/proc/pl_suit_protected()
	//Checks if the suit is adequately sealed.
	var/coverage = NONE
	for(var/obj/item/protection in list(wear_suit, gloves, shoes))
		if(!protection)
			continue
		if(istype(protection, /obj/item/clothing))
			var/obj/item/clothing/clothing_item = protection
			if(zas_settings.plc.plasmaguard_only && !((clothing_item.clothing_flags & THICKMATERIAL) || (clothing_item.clothing_flags & GAS_FILTERING) || (clothing_item.obj_flags & PLASMAGUARD)))
				return FALSE

		else if(zas_settings.plc.plasmaguard_only && !(protection.obj_flags & PLASMAGUARD))
			return FALSE

		coverage |= protection.body_parts_covered

	if(zas_settings.plc.plasmaguard_only)
		return TRUE

	return (~(coverage) & (CHEST|LEGS|FEET|ARMS|HANDS) == 0)
