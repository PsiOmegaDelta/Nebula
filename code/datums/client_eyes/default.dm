/datum/client_eye/default
	singleton = TRUE

/datum/client_eye/default/Destroy(forced)
	if(forced)
		return ..()
	return QDEL_HINT_LETMELIVE

/datum/client_eye/default/Update(mob/user)
	. = CLIENT_EYE_HANDLED
	if(!user.client)
		return

	var/atom/target
	var/perspective = EYE_PERSPECTIVE
	if(user.eyeobj) // Mainly covers AIs and the like
		target = user.eyeobj
	else if(user.virtual_mob) // The vast majority of mobs should have a virtual eye
		target = user.virtual_mob
	else
		TrackUser(user)
		if(!user.loc || isturf(user.loc)) // Any remaining mobs will likely be in nullspace or on a turf
			target = user // Not strictly necessary when setting MOB_PERSPECTIVE but let us be consistent
			perspective = MOB_PERSPECTIVE
		else // But as a final fallback we recurse up locs until we encounter the atom that's in a turf
			target = user.loc
			while(!isturf(target.loc))
				target = target.loc

	user.client.eye = target
	user.client.perspective = perspective
