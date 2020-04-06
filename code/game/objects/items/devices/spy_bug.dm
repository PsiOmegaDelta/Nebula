/obj/item/spy_bug
	name = "bug"
	desc = ""	// Nothing to see here
	icon = 'icons/obj/items/shield/e_shield.dmi'
	icon_state = "eshield0"
	item_state = "nothing"
	layer = BELOW_TABLE_LAYER

	obj_flags = OBJ_FLAG_CONDUCTIBLE
	force = 5.0
	w_class = ITEM_SIZE_TINY
	slot_flags = SLOT_EARS
	throwforce = 5.0
	throw_range = 15
	throw_speed = 3

	origin_tech = "{'programming':1,'engineering':1,'esoteric':3}"
	virtual_mob = /mob/observer/virtual/hear
	var/obj/item/radio/spy/radio
	var/obj/machinery/camera/spy/camera

/obj/item/spy_bug/Initialize()
	. = ..()
	radio = new(src)
	camera = new(src)

/obj/item/spy_bug/Destroy()
	QDEL_NULL(radio)
	QDEL_NULL(camera)
	return ..()

/obj/item/spy_bug/examine(mob/user, distance)
	. = ..()
	if(distance <= 0)
		to_chat(user, "It's a tiny camera, microphone, and transmission device in a happy union.")
		to_chat(user, "Needs to be both configured and brought in contact with monitor device to be fully functional.")

/obj/item/spy_bug/attack_self(mob/user)
	radio.attack_self(user)

/obj/item/spy_bug/attackby(obj/W, mob/living/user)
	if(istype(W, /obj/item/spy_monitor))
		var/obj/item/spy_monitor/SM = W
		SM.pair(src, user)
	else
		..()

/obj/item/spy_bug/hear_talk(mob/M, var/msg, verb, decl/language/speaking)
	radio.hear_talk(M, msg, speaking)


/obj/item/spy_monitor
	name = "\improper PDA"
	desc = "A portable microcomputer by Thinktronic Systems, LTD. Functionality determined by a preprogrammed ROM cartridge."
	icon = 'icons/obj/modular_computers/pda/pda.dmi'
	icon_state = ICON_STATE_WORLD
	color = COLOR_GRAY80

	w_class = ITEM_SIZE_SMALL

	origin_tech = "{'programming':1,'engineering':1,'esoteric':3}"

	var/obj/item/radio/spy/radio
	var/obj/machinery/camera/spy/selected_camera
	var/list/obj/machinery/camera/spy/cameras
	var/datum/client_eye/remote/camera/remote_view

/obj/item/spy_monitor/Initialize()
	. = ..()
	radio = new(src)

/obj/item/spy_monitor/Destroy()
	QDEL_NULL(radio)
	for(var/camera in camera)
		remove_camera(camera)
	QDEL_NULL(remote_view)
	return ..()

/obj/item/spy_monitor/examine(mob/user, distance)
	. = ..()
	if(distance <= 1)
		to_chat(user, "The time '12:00' is blinking in the corner of the screen and \the [src] looks very cheaply made.")

/obj/item/spy_monitor/attack_self(mob/user)
	radio.attack_self(user)
	view_cameras(user)

/obj/item/spy_monitor/attackby(obj/W, mob/living/user)
	if(istype(W, /obj/item/spy_bug))
		pair(W, user)
	else
		return ..()

/obj/item/spy_monitor/proc/pair(var/obj/item/spy_bug/SB, var/mob/living/user)
	if(SB.camera in cameras)
		to_chat(user, "<span class='notice'>\The [SB] has been unpaired from \the [src].</span>")
		remove_camera(SB.camera)
	else
		to_chat(user, "<span class='notice'>\The [SB] has been paired with \the [src].</span>")
		LAZYADD(cameras, SB.camera)
		GLOB.destroyed_event.register(SB.camera, src, .proc/remove_camera)

/obj/item/spy_monitor/proc/remove_camera(camera)
	LAZYREMOVE(cameras, camera)
	GLOB.destroyed_event.unregister(camera, src, .proc/remove_camera)
	if(selected_camera == camera)
		selected_camera = get_working_camera()
		if(selected_camera)
			remote_view.ChangeTarget(selected_camera)
		else
			QDEL_NULL(remote_view)

/obj/item/spy_monitor/proc/get_working_camera()
	for(var/camera in cameras)
		var/obj/machinery/camera/C = camera
		if(C.can_use())
			return C

/obj/item/spy_monitor/proc/view_cameras(mob/user)
	if(!can_use_cam(user))
		return

	selected_camera = get_working_camera()
	remote_view = remote_view || new(src, selected_camera)
	remote_view.Add(user)
	do
		remote_view.ChangeTarget(selected_camera)
		var/obj/machinery/camera/camera_choice = input("Select camera bug to view.", "Select camera", selected_camera) as null|anything in cameras
		if(camera_choice)
			if(!QDELETED(camera_choice) && camera_choice.can_use())
				selected_camera = camera_choice
			else
				to_chat(user, SPAN_WARNING("The selected camera isn't currently operational"))
		else
			selected_camera = null
	while(selected_camera && remote_view.IsAdded(user))
	QDEL_NULL(remote_view)

/obj/item/spy_monitor/proc/can_use_cam(mob/user)
	if(remote_view && remote_view.HasUsers())
		to_chat(user, SPAN_WARNING("\The [src] is already in use!"))
		return FALSE

	if(!LAZYLEN(cameras))
		to_chat(user, SPAN_WARNING("No paired cameras detected!"))
		to_chat(user, SPAN_WARNING("Bring a bug in contact with this device to pair the camera."))
		return FALSE

	if(!get_working_camera())
		to_chat(user, SPAN_WARNING("None of the connected cameras are currently operational!"))
		return FALSE

	return TRUE

/obj/item/spy_monitor/hear_talk(mob/M, var/msg, verb, decl/language/speaking)
	return radio.hear_talk(M, msg, speaking)


/obj/machinery/camera/spy
	// These cheap toys are accessible from the mercenary camera console as well
	network = list(NETWORK_MERCENARY)

/obj/machinery/camera/spy/Initialize()
	. = ..()
	name = "DV-136ZB #[random_id(/obj/machinery/camera/spy, 1000,9999)]"
	c_tag = name

/obj/item/radio/spy
	listening = 0
	frequency = 1473
	broadcasting = 0
	canhear_range = 1
	name = "spy device"
	icon_state = "syn_cypherkey"
