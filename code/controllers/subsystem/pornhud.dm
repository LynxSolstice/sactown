// A cute lil subsystem that draws pictures of peoples butts and wieners on your screen
SUBSYSTEM_DEF(pornhud)
	name = "PornHUD"
	wait = 0.5 SECONDS
	flags = SS_NO_INIT|SS_BACKGROUND

	// list of all bits
	/// format: list("Jimmy Shits" = /datum/genital_images)
	var/list/hoohaws = list()
	/// players who need a full on update of everyone's genitals
	var/list/needs_updating = list()
	/// genical datums that need to be sent to all players
	var/list/gunts_changed = list()
	var/list/currentrun = list()
	var/list/guntrun = list()
	var/image_cache_max = 512
	var/max_whitelist_search = 15
	var/debug_force_broadcast_update = TRUE
	var/debug_force_request_update = TRUE
	var/debug_clotheshud = TRUE // coming soon in 2096

/datum/controller/subsystem/pornhud/fire(resumed)
	if (!resumed)
		guntrun = gunts_changed.Copy()
		currentrun = needs_updating.Copy()
		needs_updating = list()
		gunts_changed = list()
	//cache for sanic speed (lists are references anyways)
	var/list/gunt_run = guntrun
	var/list/current_run = currentrun

	while(current_run.len)
		var/ckey = current_run[current_run.len]
		current_run.len--
		var/mob/living/carbon/human/dork = ckey2mob(ckey)
		if(!dork)
			continue
		send_everything_to_viewer(dork, debug_force_request_update)
		if (MC_TICK_CHECK)
			return

	while(gunt_run.len)
		var/datum/genital_images/GI = gunt_run[gunt_run.len]
		gunt_run.len--
		if(!GI)
			continue
		send_genitals_to_everyone(GI, debug_force_broadcast_update)
		if (MC_TICK_CHECK)
			return

/datum/controller/subsystem/pornhud/proc/catalogue_part(mob/living/dork, part, list/images = list())
	if(!isliving(dork) || !part)
		return
	var/datum/genital_images/GI = get_genital_datum(dork)
	GI.add_part(part, images)
	return TRUE

/datum/controller/subsystem/pornhud/proc/get_genital_datum(mob/living/carbon/human/dork)
	if(!ishuman(dork))
		return
	if(!dork.pornhud_key)
		generate_key(dork)
	var/datum/genital_images/GI = LAZYACCESS(hoohaws, dork.pornhud_key)
	if(!GI)
		GI = new /datum/genital_images(dork)
		hoohaws[dork.pornhud_key] = GI
	return GI

/// A player changed their view settings, so we need to give them a fresh
/// copy of everyone's genitals
/datum/controller/subsystem/pornhud/proc/request_every_genital(mob/living/dork)
	if(!dork.client)
		return
	needs_updating |= dork.ckey

/// A set of genitals changed, so we need to send everyone a fresh copy of these
/datum/controller/subsystem/pornhud/proc/request_genital_broadcast(datum/genital_images/GI)
	gunts_changed |= GI

/// flush a player's genital images, and give them a fresh copy of everyone's
/// This is the *viewer*, so it'll pull everyone's images
/// Force is happen when the *viewer* changed their settings
/datum/controller/subsystem/pornhud/proc/send_everything_to_viewer(mob/living/dork, force)
	if(!dork.client)
		return
	for(var/mobname in hoohaws)
		var/datum/genital_images/GI = hoohaws[mobname]
		GI.show_images_to(dork, force)

/// A genital thing has updated, so we need to send it to everyone
/datum/controller/subsystem/pornhud/proc/send_genitals_to_everyone(datum/genital_images/gunt, force)
	for(var/mob/seer in GLOB.player_list)
		gunt.show_images_to(seer, force)

/datum/controller/subsystem/pornhud/proc/flush_genitals(mob/living/carbon/human/flusher)
	if(!ishuman(flusher))
		return
	var/datum/genital_images/GI = get_genital_datum(flusher)
	if(!GI)
		return
	GI.flush_genitals()

/datum/controller/subsystem/pornhud/proc/flush_undies(mob/living/carbon/human/flusher)
	if(!ishuman(flusher))
		return
	var/datum/genital_images/GI = get_genital_datum(flusher)
	if(!GI)
		return
	GI.flush_genitals()

/datum/controller/subsystem/pornhud/proc/update_visibility(mob/living/carbon/human/dork, part, on_off)
	if(!ishuman(dork))
		return
	var/datum/genital_images/GI = get_genital_datum(dork)
	if(!GI)
		return
	GI.update_visibility(part, on_off)

/datum/controller/subsystem/pornhud/proc/generate_key(mob/living/carbon/human/newnadhaver)
	if(!ishuman(newnadhaver))
		return
	if(newnadhaver.pornhud_key)
		return
	var/key = newnadhaver.ckey ? "[newnadhaver.ckey]-" : "stiff-"
	key += "[LAZYLEN(hoohaws) + 1]-"
	key += "[newnadhaver.real_name]-"
	key += "[world.time]-bepis"
	newnadhaver.pornhud_key = key
	return key

// scornhud
/mob/living/carbon/human
	var/pornhud_key

/// Holds all the genital images of a single human mob
/// This is the *owner*, so it'll only pull their own images
/// also defines if they're visible or not
/// get_all_images() will return a list of all images that should be visible
/// It'll not send images that the viewer has set to be hidden
/datum/genital_images
	var/datum/weakref/owner

	/// ckeys with people we've already shown our genitals to
	var/list/shown_to = list()

	var/list/breasts = list()
	var/breasts_visible

	var/list/peen = list()
	var/peen_visible

	var/list/balls = list()
	var/balls_visible

	var/list/vag = list()
	var/vag_visible

	var/list/tail = list() // nice and suggestive
	var/tail_visible

	var/list/wings = list() // dingo wings
	var/wings_visible

	var/image/undershirt
	var/shirt_visible

	var/image/underpants
	var/underpants_visible

	var/image/socks
	var/socks_visible

	/// if this is true, the player has changed their appearance since the last time we updated
	var/has_changed

	var/undies_over_genitals = TRUE

	/// massive, unwashed list of all images that were on the player at some point
	/// pruned? why? not like we'd be using that ram for anything else
	var/list/old_image_cache = list()

/datum/genital_images/New(mob/living/carbon/human/newowner)
	. = ..()
	owner = WEAKREF(newowner)

/// is this player whitelisted?
/// if so, they can see genitals even if they're hidden
/datum/genital_images/proc/is_whitelisted(mob/someone)
	if(!someone || !someone.client)
		return FALSE
	var/datum/preferences/P = extract_prefs(someone)
	var/list/whitelist = splittext(P.genital_whitelist, ",")
	var/index = 1
	for(var/entry in whitelist)
		entry = ckey(entry)
		if(findtext(ckey(someone.real_name), entry))
			return TRUE
		if(findtext(entry, ckey(someone.real_name)))
			return TRUE
		if(findtext(ckey(someone.name), entry))
			return TRUE
		if(findtext(entry, ckey(someone.name)))
			return TRUE
		if(index++ > SSpornhud.max_whitelist_search)
			return FALSE
	
// add a part to the list
/datum/genital_images/proc/add_part(part, list/images)
	if(!islist(images))
		if(isnull(images))
			images = list()
		else
			images = list(images)
	var/list/images2change
	switch(part)
		if(PHUD_BOOB)
			images2change = breasts
		if(PHUD_PENIS)
			images2change = peen
		if(PHUD_BALLS)
			images2change = balls
		if(PHUD_VAG)
			images2change = vag
		if(PHUD_TAIL)
			images2change = tail
		if(PHUD_WINGS)
			images2change = wings
		if(PHUD_SHIRT)
			images2change = undershirt
		if(PHUD_PANTS)
			images2change = underpants
		if(PHUD_SOCKS)
			images2change = socks
	if(!LAZYLEN(images ^ images2change))
		return // nothing changed
	switch(part)
		if(PHUD_BOOB)
			breasts = images
		if(PHUD_PENIS)
			peen = images
		if(PHUD_BALLS)
			balls = images
		if(PHUD_VAG)
			vag = images
		if(PHUD_TAIL)
			tail = images
		if(PHUD_WINGS)
			wings = images
		if(PHUD_SHIRT)
			undershirt = images
		if(PHUD_PANTS)
			underpants = images
		if(PHUD_SOCKS)
			socks = images
	set_changed()

/datum/genital_images/proc/update_visibility(part, on_off)
	switch(part)
		if(PHUD_BOOB)
			if(breasts_visible == on_off)
				return
			breasts_visible = on_off
		if(PHUD_PENIS)
			if(peen_visible == on_off)
				return
			peen_visible = on_off
		if(PHUD_BALLS)
			if(balls_visible == on_off)
				return
			balls_visible = on_off
		if(PHUD_VAG)
			if(vag_visible == on_off)
				return
			vag_visible = on_off
		if(PHUD_TAIL)
			if(tail_visible == on_off)
				return
			tail_visible = on_off
		if(PHUD_WINGS)
			if(wings_visible == on_off)
				return
			wings_visible = on_off
		if(PHUD_SHIRT)
			if(shirt_visible == on_off)
				return
			shirt_visible = on_off
		if(PHUD_PANTS)
			if(underpants_visible == on_off)
				return
			underpants_visible = on_off
		if(PHUD_SOCKS)
			if(socks_visible == on_off)
				return
			socks_visible = on_off
	set_changed()

/datum/genital_images/proc/cache_images(list/imgs = list())
	for(var/imgl in imgs)
		old_image_cache |= imgs[imgl]
	if(LAZYLEN(old_image_cache) >= SSpornhud.image_cache_max)
		var/num_to_remove = LAZYLEN(old_image_cache) - SSpornhud.image_cache_max
		if(num_to_remove > 1)
			old_image_cache.Cut(1, num_to_remove)

/datum/genital_images/proc/show_images_to(mob/seer, force)
	if(!seer || !seer.client)
		return // they cant see us!
	if(shown_to[seer.ckey] && !force)
		return // no need to update
	shown_to[seer.ckey] = TRUE
	remove_images(seer)
	var/list/imgs = get_all_images(seer.client.prefs)
	add_images(seer, imgs)

/datum/genital_images/proc/remove_images(mob/seer)
	if(!seer)
		return
	seer.client.images -= old_image_cache

/datum/genital_images/proc/add_images(mob/seer, list/imgs = list())
	if(!seer)
		return
	for(var/imglayer in imgs)
		seer.client.images += imgs[imglayer]

/datum/genital_images/proc/get_all_images(datum/preferences/P)
	if(!P)
		return
	var/list/all_images = list()
	var/mob/living/carbon/human/myowner = GET_WEAKREF(owner)
	if(!ishuman(myowner))
		return
	var/list/image_order = myowner.dna.decode_cockstring(FALSE)
	var/preflag = is_whitelisted(P.parent.mob) ? NONE : P.features["genital_hide"]
	for(var/entry in image_order)
		switch(entry)
			if(CS_BOOB)
				if(breasts_visible && !CHECK_BITFIELD(preflag, HIDE_BOOBS))
					all_images += breasts
			if(CS_PENIS)
				if(peen_visible && !CHECK_BITFIELD(preflag, HIDE_PENIS))
					all_images += peen
			if(CS_BALLS)
				if(balls_visible && !CHECK_BITFIELD(preflag, HIDE_BALLS))
					all_images += balls
			if(CS_VAG)
				if(vag_visible && !CHECK_BITFIELD(preflag, HIDE_VAG))
					all_images += vag
	if(tail && tail_visible)
		all_images += tail
	var/list/imgsformatted = list()
	for(var/image/I in all_images)
		var/image/flat = imgsformatted["[I.layer]"]
		if(!flat)
			flat = image('icons/mob/hud.dmi', myowner, "")
			flat.appearance_flags = RESET_COLOR|RESET_TRANSFORM
			imgsformatted["[I.layer]"] = flat
		flat.overlays += I
	cache_images(imgsformatted)
	return imgsformatted

/datum/genital_images/proc/flush_genitals()
	var/changed = LAZYLEN(breasts) || LAZYLEN(peen) || LAZYLEN(balls) || LAZYLEN(vag)
	breasts = list()
	peen = list()
	balls = list()
	vag = list()
	if(changed)
		set_changed()
	return TRUE

/datum/genital_images/proc/flush_undies()
	cache_images(get_all_images())
	undershirt = null
	underpants = null
	socks = null
	return TRUE

/datum/genital_images/proc/set_changed()
	shown_to.Cut()
	SSpornhud.request_genital_broadcast(src)
