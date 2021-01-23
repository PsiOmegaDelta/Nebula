/decl/client_eye/proc/Reset(var/mob/source)

/decl/client_eye/default/Reset(var/mob/source)
	if(!source.client)
		return

	source.client.perspective = EYE_PERSPECTIVE
	if(source.eyeobj) // Mainly covers AIs and the like
		source.client.eye = source.eyeobj
	else if(source.virtual_mob) // The vast majority of mobs should have a virtual eye
		source.client.eye = source.virtual_mob
	else if(!source.loc || isturf(source.loc)) // Any remaining mobs will likely be in nullspace or on a turf
		source.client.perspective = MOB_PERSPECTIVE
		source.client.eye = source // Not strictly necessary when setting MOB_PERSPECTIVE but let us be consistent
	else // But as a final fallback we recurse up locs until we encounter the atom that's in a turf
		var/atom/eye = source.loc
		while(!isturf(eye.loc))
			eye = eye.loc
		source.client.eye = eye

/mob/proc/reset_view()
