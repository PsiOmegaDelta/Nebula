/datum/client_eye/remote
	VAR_PRIVATE/datum/host
	VAR_PRIVATE/atom/target
	VAR_PRIVATE/topic_state
	VAR_PRIVATE/flags
	
	VAR_PROTECTED/expected_target_type = /atom

/datum/client_eye/remote/New(datum/host, atom/target, flags = REMOTE_EYE_NONE, datum/topic_state/topic_state = null)
	topic_state = topic_state || host.DefaultTopicState()
	if(!istype(host))
		CRASH("Invalid host. Expected a /datum, host is: [log_info_line(host)]")
	if(target && !istype(target, expected_target_type))
		CRASH("Invalid target. Expected \a [expected_target_type], target is: [log_info_line(target)]")
	if(!istype(topic_state))
		CRASH("Invalid topic state. Expected a /datum/topic_state, topic_state is: [log_info_line(topic_state)]")

	src.host = host
	src.target = target
	src.topic_state = topic_state
	src.flags = flags

	// We don't handle deletions by default because in many cases the owner of the remote view is assumed to already have such a registration anyway
	if(target && (flags & REMOTE_EYE_HANDLE_TARGET_DELETION))
		GLOB.destroyed_event.register(target, src, .proc/ClearTarget)

/datum/client_eye/remote/Destroy()
	if(target && (flags & REMOTE_EYE_HANDLE_TARGET_DELETION))
		GLOB.destroyed_event.unregister(target, src, .proc/ClearTarget)
	return ..()

/datum/client_eye/remote/Update(mob/user)
	SHOULD_NOT_OVERRIDE(TRUE)
	if(!user.client)
		return CLIENT_EYE_REMOVE

	if(!CanInteractWith(user, host, topic_state))
		return CLIENT_EYE_REMOVE

	if(!target || !CanUseTarget(user, target))
		return CLIENT_EYE_NO_ACTION

	return SetClientEye(user, target)

/datum/client_eye/remote/proc/ChangeTarget(atom/new_target)
	SHOULD_NOT_OVERRIDE(TRUE)
	if(target == new_target)
		return

	if(new_target && !istype(new_target, expected_target_type))
		CRASH("Invalid target. Expected \a [expected_target_type], target is: [log_info_line(target)]")

	if(target && (flags & REMOTE_EYE_HANDLE_TARGET_DELETION))
		GLOB.destroyed_event.unregister(target, src, .proc/ClearTarget)

	if(new_target)
		target = new_target
		if(target && (flags & REMOTE_EYE_HANDLE_TARGET_DELETION))
			GLOB.destroyed_event.register(new_target, src, .proc/ClearTarget)
		RefreshEyes()
	else
		ClearTarget()

/datum/client_eye/remote/proc/CanUseTarget(mob/user, atom/target)
	PROTECTED_PROC(TRUE)
	return !QDELETED(target)

/datum/client_eye/remote/proc/SetClientEye(mob/user, atom/target)
	PROTECTED_PROC(TRUE)
	return user.SetRemoteEyeTarget(target)

/datum/client_eye/remote/proc/ClearTarget()
	PRIVATE_PROC(TRUE)
	SHOULD_NOT_OVERRIDE(TRUE)

	if(target && (flags & REMOTE_EYE_HANDLE_TARGET_DELETION))
		GLOB.destroyed_event.unregister(target, src, .proc/ClearTarget)

	target = null
	RefreshEyes()

/datum/client_eye/proc/ViewFlags()
	return target ? target.replacing_visual_flags() : ..()

/mob/proc/SetRemoteEyeTarget(atom/target)
	client.eye = target.virtual_mob || target
	client.perspective = EYE_PERSPECTIVE

	update_sight()
	return CLIENT_EYE_HANDLED

/mob/living/silicon/ai/SetRemoteEyeTarget(atom/target)
	if(!is_in_chassis())
		eyeobj.setLoc(target)
	return CLIENT_EYE_HANDLED|CLIENT_EYE_REMOVE

/***********
* Subtypes *
***********/
/datum/client_eye/remote/camera
	process_while_used = TRUE
	expected_target_type = /obj/machinery/camera

/datum/client_eye/remote/camera/CanUseTarget(mob/user, obj/machinery/camera/C)
	return ..() && C.can_use()
