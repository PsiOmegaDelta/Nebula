var/list/all_virtual_listeners = list()

/mob/observer/virtual
	icon = 'icons/mob/virtual.dmi'
	invisibility = INVISIBILITY_SYSTEM
	see_in_dark = SEE_IN_DARK_DEFAULT
	see_invisible = SEE_INVISIBLE_LIVING
	sight = SEE_SELF

	virtual_mob = null
	no_z_overlay = TRUE

	var/atom/host      // A virtual mob can only be owned by one host
	var/list/observers //  but can have multiple observers connected to it

	var/host_type = /atom
	var/abilities = VIRTUAL_ABILITY_HEAR|VIRTUAL_ABILITY_SEE

	var/static/list/overlay_icons

/mob/observer/virtual/hear
	abilities = VIRTUAL_ABILITY_HEAR

/mob/observer/virtual/see
	abilities = VIRTUAL_ABILITY_SEE

/mob/observer/virtual/Initialize(mapload, var/atom/movable/host)
	. = ..()
	if(!istype(host, host_type))
		crash_with("Received an unexpected host type. Expected [host_type], was [log_info_line(host)].")
		return INITIALIZE_HINT_QDEL
	src.host = host
	if(istype(host))
		GLOB.moved_event.register(host, src, /atom/movable/proc/move_to_turf_or_null)

	all_virtual_listeners += src

	update_icon()
	STOP_PROCESSING(SSmobs, src)

/mob/observer/virtual/Destroy()
	if(ismovable(host))
		GLOB.moved_event.unregister(host, src, /atom/movable/proc/move_to_turf_or_null)
	GLOB.moved_event.unregister(host, src, /atom/movable/proc/move_to_turf_or_null)
	all_virtual_listeners -= src
	host = null
	observers?.Cut()
	return ..()

/mob/observer/virtual/Life()
	return PROCESS_KILL

/mob/observer/virtual/on_update_icon()
	if(!overlay_icons)
		overlay_icons = list()
		for(var/i_state in icon_states(icon))
			overlay_icons[i_state] = image(icon = icon, icon_state = i_state)
	overlays.Cut()

	if(abilities & VIRTUAL_ABILITY_HEAR)
		overlays += overlay_icons["hear"]
	if(abilities & VIRTUAL_ABILITY_SEE)
		overlays += overlay_icons["see"]

/***********************
* Virtual Mob Creation *
***********************/
/atom
	var/mob/observer/virtual/virtual_mob // An atom can only own one virtual mob
	var/list/observed_virtual_mobs       //  but can observe multiple virtual mobs

/atom/movable/Initialize()
	. = ..()
	if(ispath(virtual_mob))
		virtual_mob = new virtual_mob(get_turf(src), src)
