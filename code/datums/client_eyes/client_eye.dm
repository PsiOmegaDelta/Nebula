/datum/client_eye
	var/singleton = FALSE
	VAR_PRIVATE/list/users
	VAR_PRIVATE/list/tracked_users
	VAR_PRIVATE/process_while_used = FALSE

/datum/client_eye/Destroy()
	RemoveAllUsers()
	return ..()

/datum/client_eye/Process()
	SHOULD_NOT_OVERRIDE(TRUE)
	RefreshEyes()

/datum/client_eye/proc/Update(mob/user)
	return CLIENT_EYE_REMOVE

/datum/client_eye/proc/Add(mob/user, refresh_vision = TRUE)
	SHOULD_NOT_OVERRIDE(TRUE)
	if(LAZYISIN(users, user))
		return
	if(!CanAdd(user))
		return

	LAZYINSERT(users, user, 1)
	LAZYINSERT(user.client_eyes, src, 1)
	if(process_while_used && LAZYLEN(users) == 1)
		START_PROCESSING(SSprocessing, src)
	
	if(refresh_vision)
		client_eye_manager.RefreshEye(user)

/datum/client_eye/proc/Remove(mob/user, refresh_vision = TRUE)
	SHOULD_NOT_OVERRIDE(TRUE)
	if(!LAZYISIN(users, user))
		return

	var/was_first_eye = IS_FIRST_CLIENT_EYE(src, user)
	LAZYREMOVE(users, user)
	LAZYREMOVE(user.client_eyes, src)

	if(LAZYISIN(tracked_users, user))
		LAZYREMOVE(tracked_users, user)
		client_eye_manager.StopTracking(user, src)

	if(process_while_used && !LAZYLEN(users))
		STOP_PROCESSING(SSprocessing, src)

	if(refresh_vision && was_first_eye)
		client_eye_manager.RefreshEye(user)

/datum/client_eye/proc/CanAdd(mob/user)
	PROTECTED_PROC(TRUE)
	return !QDELETED(target)

/datum/client_eye/proc/RefreshEyes()
	PROTECTED_PROC(TRUE)
	SHOULD_NOT_OVERRIDE(TRUE)
	client_eye_manager.RefreshEyes(users, src)

/datum/client_eye/proc/TrackUser(mob/user)
	PROTECTED_PROC(TRUE)
	SHOULD_NOT_OVERRIDE(TRUE)

	if(!LAZYISIN(tracked_users, user))
		LAZYADD(tracked_users, user)
		client_eye_manager.TrackUser(user, src)

/datum/client_eye/proc/RemoveAllUsers()
	PROTECTED_PROC(TRUE)
	SHOULD_NOT_OVERRIDE(TRUE)
	for(var/user in users)
		Remove(user)

/datum/client_eye/proc/IsAdded(mob/user)
	return LAZYISIN(users, user)

/datum/client_eye/proc/HasUsers()
	return !!LAZYLEN(users)

/datum/client_eye/proc/GetUsers()
	. = list()
	for(var/user in users)
		. += user

/datum/client_eye/proc/ViewFlags()
	return -1
