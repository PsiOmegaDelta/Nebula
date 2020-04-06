var/datum/client_eye_manager/client_eye_manager = new()

/datum/client_eye_manager
	var/list/tracked_users

/datum/client_eye_manager/New()
	// By refreshing the first time only when a login occurs we don't have to init the client_eyes-list for every mob
	GLOB.logged_in_event.register_global(src, .proc/RefreshEye)

/datum/client_eye_manager/Destroy(force)
	if(force)
		for(var/tracked_user in tracked_users)
			GLOB.moved_event.unregister(tracked_user, src)
		tracked_users?.Cut()
		client_eye_manager = null
		return ..()

	return QDEL_HINT_LETMELIVE

#define SETUP_CLIENT_EYES \
if(length(user.client_eyes) && ispath(user.client_eyes[user.client_eyes.len])) { \
	var/client_eyes = list(); \
	for(var/client_eye_type in user.client_eyes) { \
		var/datum/client_eye/CV = client_eye_type; \
		if(ispath(CV)) { \
			if(initial(CV.singleton)) { \
				CV = decls_repository.get_decl(client_eye_type); \
			} else { \
				CV = new CV(); \
			} \
		} \
		CV.Add(user, FALSE); \
		client_eyes += CV; \
	} \
	user.client_eyes = client_eyes; \
}

/datum/client_eye_manager/proc/RefreshEye(mob/logged_in_user, mob/entering_user)
	var/mob/user = istype(logged_in_user) ? logged_in_user : (istype(entering_user) ? entering_user : null)

	SETUP_CLIENT_EYES
	for(var/vision in user.client_eyes)
		var/datum/client_eye/CV = vision
		var/result = CV.Update(user)
		if(!result)
			crash_with("Invalid return value from: [log_info_line(CV)]")
			LAZYREMOVE(user.client_eyes, CV)
		if(result & CLIENT_EYE_REMOVE)
			CV.Remove(user)
			LAZYREMOVE(user.client_eyes, CV)
		if(result & CLIENT_EYE_HANDLED)
			break

/datum/client_eye_manager/proc/RefreshEyes(list/mobs, client_eye)
	for(var/mob in mobs)
		var/mob/M = mob
		if(IS_FIRST_CLIENT_EYE(client_eye, M))
			RefreshEye(M)

/datum/client_eye_manager/proc/TrackUser(mob/user, client_eye)
	var/list/trackers = LAZYACCESS(tracked_users, user)
	if(!trackers)
		trackers = list()
		LAZYSET(tracked_users, user, trackers)
	trackers |= client_eye
	if(trackers.len == 1)
		GLOB.moved_event.register(user, src, .proc/RefreshEye)

/datum/client_eye_manager/proc/StopTracking(mob/user, client_eye)
	var/list/trackers = LAZYACCESS(tracked_users, user)
	if(trackers)
		trackers -= client_eye
		if(!trackers.len)
			LAZYREMOVE(tracked_users, user)
			GLOB.moved_event.unregister(user, src, .proc/RefreshEye)

/datum/client_eye_manager/proc/ViewFlags(mob/user)
	if(!user.client)
		return -1

	SETUP_CLIENT_EYES
	for(var/vision in user.client_eyes)
		var/datum/client_eye/CV = vision
		var/view_flags = CV.ViewFlags()
		if(view_flags >= 0)
			return view_flags

	return -1

#undef SETUP_CLIENT_EYES

/mob
	var/list/client_eyes = list(/datum/client_eye/default)

/mob/observer/virtual
	client_eyes = null

/mob/Destroy()
	if(length(client_eyes) && !ispath(client_eyes[client_eyes.len]))
		for(var/vision in client_eyes)
			var/datum/client_eye/CV = vision
			CV.Remove(src, FALSE)
	client_eyes?.Cut()	
	. = ..()

/mob/proc/reset_view()
	return
