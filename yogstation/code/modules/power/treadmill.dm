/obj/machinery/power/treadmill
	name = "treadmill"
	desc = "Fifteen Million Merits"
	icon = 'icons/obj/vehicles.dmi'
	icon_state = "bicycle"
	density = TRUE
	anchored =  TRUE
	use_power = NO_POWER_USE
	can_buckle = 1
	buckle_lying = 0

	var/operating
	var/generating
	var/power_exponent = 1000
	var/simple_power = 15
	var/no_mind_power = 25
	var/slave_power = 50
	var/lifeweb

/obj/machinery/power/treadmill/examine(mob/user)
	. = ..()
	. +="<span class='notice'>It is generating [generating]kw of power.</span>"

/obj/machinery/power/treadmill/emag_act(mob/user)
	if(obj_flags & EMAGGED)
		return
	obj_flags |= EMAGGED
	lifeweb = 1
	to_chat(user, "<span class='warning'>You disabled safeties</span>")

/obj/machinery/power/treadmill/wrench_act(mob/living/user, obj/item/I)
	if(!anchored && !isinspace())
		playsound(src.loc, 'sound/items/deconstruct.ogg', 50, 1)
		if(do_after(user, 20, target = src))
			connect_to_network()
			to_chat(user, "<span class='notice'>You secure [src] to the floor.</span>")
			anchored  = TRUE
			playsound(src.loc, 'sound/items/deconstruct.ogg', 50, 1)
	else if(anchored)
		if(operating)
			to_chat(user, "<span class='warning'>You can't detach [src] from the floor while its moving!</span>")
			return TRUE
		playsound(src.loc, 'sound/items/deconstruct.ogg', 50, 1)
		if(do_after(user, 20, target = src))
			disconnect_from_network()
			to_chat(user, "<span class='notice'>You unsecure [src] from the floor.</span>")
			anchored = FALSE
			playsound(src.loc, 'sound/items/deconstruct.ogg', 50, 1)
	return TRUE

/obj/machinery/power/treadmill/crowbar_act(mob/living/user, obj/item/I)
	if(lifeweb)
		to_chat(user, "<span class='notice'>You forcefully yank the emergency brake.</span>")
	return TRUE

/obj/machinery/power/treadmill/attack_paw(mob/user)
	return attack_hand(user)

/obj/machinery/power/treadmill/attack_hand(mob/user)
	if(lifeweb)
		to_chat(user, "<span class='danger'>It's spinning too fast! You might hurt yourself if you try to get them off!</span>")
		return
	unbuckle_mob()

/obj/machinery/power/treadmill/process()
	if(!operating)
		return
	if(operating)
		if(lifeweb)
			check_buckled()
			life_drain()
			to_chat(world, "DEBUG :  emaggedworking")
			add_avail((operating * power_exponent) * 1.5)
			generating = (operating * 1.5)
			return
		check_buckled()
		to_chat(world, "DEBUG :  working")
		add_avail(operating * power_exponent)
		generating = (operating)

/obj/machinery/power/treadmill/update_icon()
	if(operating)
		to_chat(world, "DEBUG : icon on")
	else
		to_chat(world, "DEBUG : icon off")

//BUCKLE HOOKS

/obj/machinery/power/treadmill/unbuckle_mob(mob/living/buckled_mob,force = 0)
	playsound(src,'sound/mecha/mechmove01.ogg', 50, TRUE)
	if(istype(buckled_mob))
		buckled_mob.pixel_x = 0
		buckled_mob.pixel_y = 0
	. = ..()
	to_chat(world, "DEBUG : unbuckled")
	operating = 0
	generating = 0
	update_icon()

/obj/machinery/power/treadmill/user_buckle_mob(mob/living/M, mob/living/carbon/user)
	if(user.incapacitated() || !istype(user))
		return
	for(var/atom/movable/A in get_turf(src))
		if(A.density && (A != src && A != M))
			return
	M.forceMove(get_turf(src))
	..()
	playsound(src,'sound/mecha/mechmove01.ogg', 50, TRUE)
	to_chat(world, "DEBUG : buckled")
	check_buckled()

/obj/machinery/power/treadmill/proc/check_buckled(mob/living)
	for(var/mob/living/BM in buckled_mobs)
		if(!isliving(BM))
			to_chat(world, "DEBUG : he ded")
			return
		if(istype(BM,/mob/living/carbon/monkey) || istype(BM, /mob/living/simple_animal))
			operating = simple_power
			update_icon()
			to_chat(world, "DEBUG : i see monkey")
		if(istype(BM,/mob/living/carbon/human))
			if(!BM.mind)
				operating = no_mind_power
				to_chat(world, "DEBUG : braindead")
			operating = slave_power
			update_icon()
			to_chat(world, "DEBUG : i see you")

/obj/machinery/power/treadmill/proc/life_drain(mob/living)
	for(var/mob/living/BM in buckled_mobs)
		BM.adjustBruteLoss(5)