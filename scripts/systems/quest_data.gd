class_name QuestData
extends RefCounted

## Town NPC quest-giver definitions and dialog -- see CLAUDE.md "NPC dialog &
## quests" and "Numbered spoon set". Lives here (rather than as private consts
## on overworld_map.gd) so the Quest Log overlay
## (scripts/ui/quest_log_overlay.gd) can read quest definitions and objectives
## from both the overworld and in-level HUDs.
##
## Each quest's intro/reminder/turn_in/after dialog is a DialogTree (see
## scripts/systems/dialog_tree.gd), built via DialogTree.from_pages() --
## a linear start->n1->n2->... chain, one node per page, identical in
## substance to the old Array[String] pages. The terminal node of "intro"
## (for want_item quests) and "turn_in" carries "effects" that flip the
## quest's level_progress flag and grant/consume items -- see
## overworld_map.gd._apply_dialog_effects(). QUESTS/QUESTS_2 are `static var`
## (not `const`) because from_pages() is a function call, not a constant
## expression.

const DialogTreeScript: Script = preload("res://scripts/systems/dialog_tree.gd")

# Quest state lives in GameManager.level_progress under this pseudo-location
# id, the same get/set_level_flag pattern every level uses for its own
# progress.
const TOWN_ID: String = "town"

# Townsfolk, homed on open grass between the buildings (verified clear of
# every footprint in overworld_map.gd's LOCS). Each is a quest-giver -- see
# CLAUDE.md "NPC dialog & quests" -- whose `quest_id` indexes into QUESTS below.
const NPC_DATA: Array = [
	{"home": Vector2i(5, 10), "name": "Gus", "color": Color(0.60, 0.55, 0.48), "quest_id": "gus"},
	{"home": Vector2i(16, 5), "name": "Moira", "color": Color(0.50, 0.58, 0.55), "quest_id": "moira"},
	{"home": Vector2i(28, 11), "name": "Reggie", "color": Color(0.58, 0.50, 0.60), "quest_id": "reggie"},
	{"home": Vector2i(14, 16), "name": "Fanny", "color": Color(0.62, 0.60, 0.45), "quest_id": "fanny"},
	{"home": Vector2i(8, 13), "name": "Penny", "color": Color(0.85, 0.55, 0.65), "quest_id": "penny"},
	{"home": Vector2i(33, 15), "name": "Otis", "color": Color(0.40, 0.55, 0.70), "quest_id": "otis"},
]

# Second wave of quest-givers, added for the 12-spoon collectible set (see
# CLAUDE.md "Numbered Spoons"). Homed out in the grass padding beyond the
# original 40x19 layout (negative/large coords are valid -- overworld_map.gd's
# _anchor() just adds MAP_OFFSET, and _build_floor() paints grass across the
# whole padded GRID_COLS x GRID_ROWS grid), so these new homes can't collide
# with any building footprint or existing NPC. Wendell/Clara/Ambrose/Dottie are
# always present (fetch quests for already-placed junk items); Tobias/Agnes
# are only spawned once the matching location's secret passage has been found
# -- `requires_flag` is checked in overworld_map.gd._spawn_npcs().
const NPC_DATA_2: Array = [
	{"home": Vector2i(-5, 4), "name": "Wendell", "color": Color(0.55, 0.45, 0.40), "quest_id": "wendell"},
	{"home": Vector2i(-5, 12), "name": "Clara", "color": Color(0.45, 0.55, 0.60), "quest_id": "clara"},
	{"home": Vector2i(44, 4), "name": "Ambrose", "color": Color(0.60, 0.58, 0.42), "quest_id": "ambrose"},
	{"home": Vector2i(44, 12), "name": "Dottie", "color": Color(0.70, 0.48, 0.55), "quest_id": "dottie"},
	{
		"home": Vector2i(15, -5), "name": "Tobias", "color": Color(0.50, 0.50, 0.55), "quest_id": "tobias",
		"requires_flag": {"location": "pipe_organ_works", "flag": "secret_revealed"},
	},
	{
		"home": Vector2i(15, 23), "name": "Agnes", "color": Color(0.65, 0.62, 0.78), "quest_id": "agnes",
		"requires_flag": {"location": "old_parish_church", "flag": "secret_revealed"},
	},
]

# Explicit, ordered list of every quest_id across NPC_DATA + NPC_DATA_2 --
# drives the "all 12 quests complete" achievement (friend_of_the_town) and the
# Quest Log overlay's quest list.
const TOWN_QUEST_IDS: Array[String] = [
	"gus", "moira", "reggie", "fanny", "penny", "otis",
	"wendell", "clara", "ambrose", "dottie", "tobias", "agnes",
]

# Each quest asks for one (already-placed, mostly pre-existing junk/lore)
# collectible and -- if `give_item` is non-empty -- hands back a reward item
# on turn-in. Dialog is paged (each entry is shown until the player presses
# ui_accept again); use "\n" for a second line. State machine per quest is
# not_started -> active -> complete, persisted via
# GameManager.get/set_level_flag(TOWN_ID, "quest_<id>", ...). The flag
# transitions and item grant/consume happen via "effects" on the terminal
# node of "intro" (not_started -> active) and "turn_in" (active -> complete)
# -- see overworld_map.gd._apply_dialog_effects().
static var QUESTS: Dictionary = {
	"gus": {
		"want_item": "bent_spoon", "give_item": "", "spoon": "numbered_spoon_01",
		"intro": DialogTreeScript.from_pages([
			"Gus: Eh? Oh, it's you two. Haven't seen strangers 'round here in ages.",
			"Gus: Say -- you didn't happen to find an old bent spoon in that organ workshop, did you?",
			"Gus: Silly thing to miss, I know. But it was Doug's -- he used it to tap pipe seams.",
			"Gus: If you spot it, bring it back. I'd consider it a favor between friends.",
		], {"set_flag": "quest_gus", "flag_value": "active"}),
		"reminder": DialogTreeScript.from_pages([
			"Gus: Still keeping an eye out for that bent spoon? Workshop floor, probably, knowing Doug.",
		]),
		"turn_in": DialogTreeScript.from_pages([
			"Gus: That's it! That's Doug's old tapping spoon, bent from years of pipe work.",
			"Gus: Thank you. He'd want someone to have it who'd remember what it was for.",
			"Gus: He used to say a pipe organ's only as good as the hands that tune it. Miss him.",
		], {"consume_item": "bent_spoon", "grant_items": ["numbered_spoon_01"], "set_flag": "quest_gus", "flag_value": "complete"}),
		"after": DialogTreeScript.from_pages([
			"Gus: Thanks again for that spoon. Keeps me thinking about the old days.",
		]),
	},
	"moira": {
		"want_item": "skeleton_key", "give_item": "", "spoon": "numbered_spoon_02",
		"intro": DialogTreeScript.from_pages([
			"Moira: Oh! Hello, dears. You look like you're headed somewhere important.",
			"Moira: If your travels take you through the Library, keep an eye out for an old skeleton key.",
			"Moira: I lent it to a friend ages ago and never got it back. Haven't seen him since, either.",
			"Moira: Funny -- it doesn't open anything anymore. But I'd like it back all the same.",
		], {"set_flag": "quest_moira", "flag_value": "active"}),
		"reminder": DialogTreeScript.from_pages([
			"Moira: Still no luck with that skeleton key? It's probably gathering dust in the stacks.",
		]),
		"turn_in": DialogTreeScript.from_pages([
			"Moira: You found it! Oh, thank you. I haven't held this in years.",
			"Moira: ...Wait. Look here, on the bow -- someone scratched a little 'D.' into the metal.",
			"Moira: That's HIS mark. The friend I lent it to. Doug always signed his things.",
			"Moira: He must have tried every lock in town with this before giving up. Typical Doug.",
			"Moira: Wherever he's gotten to, I hope he's all right. Thank you for bringing this home.",
		], {"consume_item": "skeleton_key", "grant_items": ["numbered_spoon_02"], "set_flag": "quest_moira", "flag_value": "complete"}),
		"after": DialogTreeScript.from_pages([
			"Moira: Strange, holding Doug's key again. Made me think of him all day. Thank you.",
		]),
	},
	"reggie": {
		"want_item": "arcade_token", "give_item": "", "spoon": "numbered_spoon_03",
		"intro": DialogTreeScript.from_pages([
			"Reggie: Hey hey! You two look like you can keep a secret.",
			"Reggie: Years back, me and a fella named Doug built an arcade cabinet from scratch.",
			"Reggie: Never finished it -- Doug had the only token that fit the coin slot. Custom-made!",
			"Reggie: If you ever spot a token with a logo that doesn't match ANY arcade you know... that's it.",
			"Reggie: Bring it here, would you? I think I finally know where the cabinet's hiding.",
		], {"set_flag": "quest_reggie", "flag_value": "active"}),
		"reminder": DialogTreeScript.from_pages([
			"Reggie: Keep your eyes peeled for that one-of-a-kind arcade token, yeah? You'll know it.",
		]),
		"turn_in": DialogTreeScript.from_pages([
			"Reggie: THAT'S IT! That's Doug's token! I'd know that goofy logo anywhere.",
			"Reggie: He had it cast special, said 'so nobody else can ever play MY high score.'",
			"Reggie: With this, I bet I can get that old cabinet running again. For old time's sake.",
			"Reggie: ...And maybe, just maybe, it'll tell us something about where he went. Thanks, you two.",
		], {"consume_item": "arcade_token", "grant_items": ["numbered_spoon_03"], "set_flag": "quest_reggie", "flag_value": "complete"}),
		"after": DialogTreeScript.from_pages([
			"Reggie: Still tinkering with that cabinet. One of these days, I'll get it humming again.",
		]),
	},
	"fanny": {
		"want_item": "fannys_bottle", "give_item": "", "spoon": "numbered_spoon_04",
		"intro": DialogTreeScript.from_pages([
			"Fanny: Oh, hello. You'll have to excuse me -- I've been a bit out of sorts lately.",
			"Fanny: I lost a little bottle of mine somewhere in those awful tunnels. F.B., it's marked.",
			"Fanny: Lavender scent. My favorite. I've looked everywhere I dare to go.",
			"Fanny: If you're brave enough to search down there, I'd be so grateful to have it back.",
		], {"set_flag": "quest_fanny", "flag_value": "active"}),
		"reminder": DialogTreeScript.from_pages([
			"Fanny: Still no sign of my little bottle? It's dark down there -- you may need a light.",
		]),
		"turn_in": DialogTreeScript.from_pages([
			"Fanny: You found it! Oh, thank goodness. I thought I'd lost it for good.",
			"Fanny: Doug gave me this, you know. The day before he disappeared.",
			"Fanny: He said, 'Hang onto this, Fanny -- something to remember me by, just in case.'",
			"Fanny: I didn't think much of it at the time. Now I wonder if he knew something was coming.",
			"Fanny: Thank you for finding it. It means more to me than you could know.",
		], {"consume_item": "fannys_bottle", "grant_items": ["numbered_spoon_04"], "set_flag": "quest_fanny", "flag_value": "complete"}),
		"after": DialogTreeScript.from_pages([
			"Fanny: I keep that bottle close now. Thank you again for bringing it back to me.",
		]),
	},
	"penny": {
		"want_item": "embroidered_handkerchief", "give_item": "stitched_patch", "spoon": "numbered_spoon_05",
		"intro": DialogTreeScript.from_pages([
			"Penny: Hiya! You two look like you get around. Mind doing me a favor?",
			"Penny: I was mending an old handkerchief for a customer -- an embroidered 'D,' very fancy.",
			"Penny: I dropped it somewhere in the Old Parish Church on my way to deliver it. So clumsy!",
			"Penny: The customer was a sweet old fellow named Doug. Haven't seen him to apologize, even.",
			"Penny: If you find it among the pews, I'd be ever so grateful. I'll make it worth your while!",
		], {"set_flag": "quest_penny", "flag_value": "active"}),
		"reminder": DialogTreeScript.from_pages([
			"Penny: Any luck with that handkerchief? Should be somewhere around the pews.",
		]),
		"turn_in": DialogTreeScript.from_pages([
			"Penny: You found it! Oh, thank you! I felt awful about losing Mr. Doug's handkerchief.",
			"Penny: Here -- I made this little patch for whoever found it. A gear, since Doug loved his tools.",
			"Penny: Sew it on somewhere nobody will notice. It's small, but it's something.",
			"Penny: If you do see Doug around, tell him I'm sorry -- and that I'll mend it properly this time.",
		], {"consume_item": "embroidered_handkerchief", "grant_items": ["stitched_patch", "numbered_spoon_05"], "set_flag": "quest_penny", "flag_value": "complete"}),
		"after": DialogTreeScript.from_pages([
			"Penny: Still hoping to track down Mr. Doug and finish that mending properly. Thanks again.",
		]),
	},
	"otis": {
		"want_item": "brass_compass", "give_item": "sailors_knot_bracelet", "spoon": "numbered_spoon_06",
		"intro": DialogTreeScript.from_pages([
			"Otis: Well now, fresh faces! Don't get many of those down by the docks these days.",
			"Otis: Say -- you wouldn't have spotted an old brass compass lying around the harbor, eh?",
			"Otis: Lost it in all the cargo shuffle. Hasn't pointed north right in years, but it's mine.",
			"Otis: Engraved on the back: 'To O.' -- that's me, Otis. Gift from an old friend.",
			"Otis: Find it for me and I'll tie you up a proper sailor's knot. Good luck charm, that.",
		], {"set_flag": "quest_otis", "flag_value": "active"}),
		"reminder": DialogTreeScript.from_pages([
			"Otis: Still keeping an eye out for my compass? Probably buried under cargo somewhere.",
		]),
		"turn_in": DialogTreeScript.from_pages([
			"Otis: Ha! There it is. Knew it had to be down here somewhere.",
			"Otis: 'To O., so you always find your way home.' Doug gave me this, years back.",
			"Otis: Funny thing to give a sailor whose home IS the docks. But that was Doug.",
			"Otis: Said everybody needs a way back, even if they don't know they're lost yet.",
			"Otis: Here -- a sailor's knot, like I promised. Tie it on. Might bring you luck, too.",
		], {"consume_item": "brass_compass", "grant_items": ["sailors_knot_bracelet", "numbered_spoon_06"], "set_flag": "quest_otis", "flag_value": "complete"}),
		"after": DialogTreeScript.from_pages([
			"Otis: That compass still doesn't point north. But it points home. Good enough for me.",
		]),
	},
}

# Second wave of quests, for the new NPC_DATA_2 quest-givers -- see CLAUDE.md
# "Numbered Spoons". Wendell/Clara/Ambrose/Dottie are ordinary fetch quests
# (want_item -> spoon, no flavor give_item). Tobias/Agnes have no want_item:
# they were "freed" by the player finding a secret passage elsewhere, so the
# very first conversation both completes the quest and hands over their spoon
# -- their "intro" terminal node carries the grant/flag effects directly, and
# "reminder"/"turn_in" are empty trees (unreachable, since the quest flag goes
# straight from not_started to complete). Every quest here (and every quest
# above, via the "spoon" key) grants exactly one of the 12 numbered_spoon_NN
# items.
static var QUESTS_2: Dictionary = {
	"wendell": {
		"want_item": "ticket_stub_torn", "give_item": "", "spoon": "numbered_spoon_07",
		"intro": DialogTreeScript.from_pages([
			"Wendell: ...Oh. Visitors. Don't get many of those out here.",
			"Wendell: I collect ticket stubs -- odd hobby, I know. Lost one somewhere near the Carnival.",
			"Wendell: Torn clean in half. If you spot it, I'd love to add it back to the collection.",
		], {"set_flag": "quest_wendell", "flag_value": "active"}),
		"reminder": DialogTreeScript.from_pages([
			"Wendell: Still no torn ticket stub? It'd have blown around near the Carnival, probably.",
		]),
		"turn_in": DialogTreeScript.from_pages([
			"Wendell: That's the one! Thank you. Every stub tells a little story.",
			"Wendell: Here, take this -- found it years ago, no idea what it goes to. Number 7, see?",
			"Wendell: I had eleven others like it once, scattered all over town. Funny, isn't it?",
			"Wendell: Always wondered what kind of game needs that many identical spoons.",
		], {"consume_item": "ticket_stub_torn", "grant_items": ["numbered_spoon_07"], "set_flag": "quest_wendell", "flag_value": "complete"}),
		"after": DialogTreeScript.from_pages([
			"Wendell: Thanks again for that stub. Let me know if you ever find the rest of that set.",
		]),
	},
	"clara": {
		"want_item": "tangled_headphone_cable", "give_item": "", "spoon": "numbered_spoon_08",
		"intro": DialogTreeScript.from_pages([
			"Clara: Hey! You two get around, right? I'm missing a cable for my crystal radio project.",
			"Clara: Tangled mess of a thing, last I saw it near the Recording Studio.",
			"Clara: Probably looks like junk to most people. To me it's a spare part. Keep an eye out?",
		], {"set_flag": "quest_clara", "flag_value": "active"}),
		"reminder": DialogTreeScript.from_pages([
			"Clara: Still no cable? It's probably tangled up with something else by now.",
		]),
		"turn_in": DialogTreeScript.from_pages([
			"Clara: You found it! Perfect, thanks. This'll patch right into the radio.",
			"Clara: Oh -- this was tangled up with it. A spoon? Number 8, stamped right there.",
			"Clara: No idea why anyone would tape a spoon to a headphone cable. Yours now, I guess.",
		], {"consume_item": "tangled_headphone_cable", "grant_items": ["numbered_spoon_08"], "set_flag": "quest_clara", "flag_value": "complete"}),
		"after": DialogTreeScript.from_pages([
			"Clara: Radio's coming along nicely, thanks to you. Still picking up mostly static, but!",
		]),
	},
	"ambrose": {
		"want_item": "faded_treasure_map", "give_item": "", "spoon": "numbered_spoon_09",
		"intro": DialogTreeScript.from_pages([
			"Ambrose: Ah, travelers! I'm an amateur cartographer. Maps fascinate me, even bad ones.",
			"Ambrose: I heard tell of a faded treasure map down at the Harbor & Docks. Useless, but--",
			"Ambrose: --I'd love to study it anyway. The X's never line up with anything, but still!",
		], {"set_flag": "quest_ambrose", "flag_value": "active"}),
		"reminder": DialogTreeScript.from_pages([
			"Ambrose: Any luck with that treasure map? Probably stuffed in a crate down at the docks.",
		]),
		"turn_in": DialogTreeScript.from_pages([
			"Ambrose: Wonderful! Let's see... yes, these landmarks match NOTHING. Fascinating.",
			"Ambrose: Hold on -- something was folded inside it. A spoon, numbered '9'.",
			"Ambrose: Maybe X marked this spot after all. Here, it's yours -- I'm keeping the map.",
		], {"consume_item": "faded_treasure_map", "grant_items": ["numbered_spoon_09"], "set_flag": "quest_ambrose", "flag_value": "complete"}),
		"after": DialogTreeScript.from_pages([
			"Ambrose: Still cross-referencing that map against, well, reality. Slow going.",
		]),
	},
	"dottie": {
		"want_item": "rabbits_foot_keychain", "give_item": "", "spoon": "numbered_spoon_10",
		"intro": DialogTreeScript.from_pages([
			"Dottie: Ooh, hello! I collect lucky charms. Doesn't matter if they actually work.",
			"Dottie: I heard there's a rabbit's foot keychain out wherever the team made their big jump.",
			"Dottie: 'The Drop,' they call it? Sounds thrilling. If you find it, it'd complete my shelf.",
		], {"set_flag": "quest_dottie", "flag_value": "active"}),
		"reminder": DialogTreeScript.from_pages([
			"Dottie: Still no rabbit's foot? It can't have gone far -- there's nowhere TO go, really.",
		]),
		"turn_in": DialogTreeScript.from_pages([
			"Dottie: You found it! My shelf is complete. Well -- ENOUGH. There's always more to find.",
			"Dottie: Funny, this was tucked underneath it. Spoon, marked '10'. Double digits!",
			"Dottie: Here, take it. Whatever game these belong to, it's a big one. Lucky you, I suppose.",
		], {"consume_item": "rabbits_foot_keychain", "grant_items": ["numbered_spoon_10"], "set_flag": "quest_dottie", "flag_value": "complete"}),
		"after": DialogTreeScript.from_pages([
			"Dottie: Still feeling lucky from that rabbit's foot. Or maybe that's just my outlook. Thanks!",
		]),
	},
	"tobias": {
		"want_item": "", "give_item": "", "spoon": "numbered_spoon_11",
		"intro": DialogTreeScript.from_pages([
			"Tobias: ...Whoa. Daylight. Hadn't seen that in a while.",
			"Tobias: I got turned around in that parts closet behind the organ workshop. Thanks for finding the way through.",
			"Tobias: Here -- found this rolling around in there with me. Spoon, marked '11'. Yours.",
			"Tobias: Don't ask me what it's for. I was just glad for the company, honestly.",
		], {"grant_items": ["numbered_spoon_11"], "set_flag": "quest_tobias", "flag_value": "complete"}),
		"reminder": {},
		"turn_in": {},
		"after": DialogTreeScript.from_pages([
			"Tobias: Good to be back out and about. Thanks again for letting some light in.",
		]),
	},
	"agnes": {
		"want_item": "", "give_item": "", "spoon": "numbered_spoon_12",
		"intro": DialogTreeScript.from_pages([
			"Agnes: Oh! Someone found the loft. I've been up there practicing for, oh, ages.",
			"Agnes: Lovely organ, that one. A bit dusty. Anyway -- you startled this right out of my pocket.",
			"Agnes: A spoon. Number '12', if you squint. A full dozen, all numbered, none useful for soup.",
			"Agnes: Definitely a game piece -- but for which game, I couldn't tell you. Keep it!",
		], {"grant_items": ["numbered_spoon_12"], "set_flag": "quest_agnes", "flag_value": "complete"}),
		"reminder": {},
		"turn_in": {},
		"after": DialogTreeScript.from_pages([
			"Agnes: Back to practicing, I think. Thanks for the company -- and the daylight.",
		]),
	},
}

# Returns the QUESTS/QUESTS_2 entry for `quest_id`, or {} if unknown.
static func get_quest(quest_id: String) -> Dictionary:
	return QUESTS.get(quest_id, QUESTS_2.get(quest_id, {}))

# Returns the {name, color, quest_id, ...} entry from NPC_DATA/NPC_DATA_2 for
# `quest_id`, or {} if unknown.
static func get_npc(quest_id: String) -> Dictionary:
	for data: Dictionary in NPC_DATA + NPC_DATA_2:
		if data["quest_id"] == quest_id:
			return data
	return {}
