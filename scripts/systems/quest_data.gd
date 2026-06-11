class_name QuestData
extends RefCounted

## Town NPC quest-giver definitions and dialog -- see CLAUDE.md "NPC dialog &
## quests" and "Numbered spoon set". Lives here (rather than as private consts
## on overworld_map.gd) so the Quest Log overlay
## (scripts/ui/quest_log_overlay.gd) can read quest definitions and objectives
## from both the overworld and in-level HUDs.

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
# GameManager.get/set_level_flag(TOWN_ID, "quest_<id>", ...).
const QUESTS: Dictionary = {
	"gus": {
		"want_item": "bent_spoon", "give_item": "", "spoon": "numbered_spoon_01",
		"intro": [
			"Gus: Eh? Oh, it's you two.\nHaven't seen strangers 'round\nhere in ages.",
			"Gus: Say -- you didn't happen\nto find an old bent spoon in\nthat organ workshop, did you?",
			"Gus: Silly thing to miss, I\nknow. But it was Doug's -- he\nused it to tap pipe seams.",
			"Gus: If you spot it, bring it\nback. I'd consider it a favor\nbetween friends.",
		],
		"reminder": [
			"Gus: Still keeping an eye out\nfor that bent spoon? Workshop\nfloor, probably, knowing Doug.",
		],
		"turn_in": [
			"Gus: That's it! That's Doug's\nold tapping spoon, bent from\nyears of pipe work.",
			"Gus: Thank you. He'd want\nsomeone to have it who'd\nremember what it was for.",
			"Gus: He used to say a pipe\norgan's only as good as the\nhands that tune it. Miss him.",
		],
		"after": [
			"Gus: Thanks again for that\nspoon. Keeps me thinking\nabout the old days.",
		],
	},
	"moira": {
		"want_item": "skeleton_key", "give_item": "", "spoon": "numbered_spoon_02",
		"intro": [
			"Moira: Oh! Hello, dears. You\nlook like you're headed\nsomewhere important.",
			"Moira: If your travels take you\nthrough the Library, keep an\neye out for an old skeleton key.",
			"Moira: I lent it to a friend ages\nago and never got it back.\nHaven't seen him since, either.",
			"Moira: Funny -- it doesn't open\nanything anymore. But I'd\nlike it back all the same.",
		],
		"reminder": [
			"Moira: Still no luck with that\nskeleton key? It's probably\ngathering dust in the stacks.",
		],
		"turn_in": [
			"Moira: You found it! Oh, thank\nyou. I haven't held this in\nyears.",
			"Moira: ...Wait. Look here, on\nthe bow -- someone scratched a\nlittle 'D.' into the metal.",
			"Moira: That's HIS mark. The\nfriend I lent it to. Doug\nalways signed his things.",
			"Moira: He must have tried every\nlock in town with this before\ngiving up. Typical Doug.",
			"Moira: Wherever he's gotten to,\nI hope he's all right. Thank\nyou for bringing this home.",
		],
		"after": [
			"Moira: Strange, holding Doug's\nkey again. Made me think of\nhim all day. Thank you.",
		],
	},
	"reggie": {
		"want_item": "arcade_token", "give_item": "", "spoon": "numbered_spoon_03",
		"intro": [
			"Reggie: Hey hey! You two look\nlike you can keep a secret.",
			"Reggie: Years back, me and a\nfella named Doug built an\narcade cabinet from scratch.",
			"Reggie: Never finished it -- Doug\nhad the only token that fit\nthe coin slot. Custom-made!",
			"Reggie: If you ever spot a token\nwith a logo that doesn't match\nANY arcade you know... that's it.",
			"Reggie: Bring it here, would you?\nI think I finally know where\nthe cabinet's hiding.",
		],
		"reminder": [
			"Reggie: Keep your eyes peeled\nfor that one-of-a-kind arcade\ntoken, yeah? You'll know it.",
		],
		"turn_in": [
			"Reggie: THAT'S IT! That's Doug's\ntoken! I'd know that goofy\nlogo anywhere.",
			"Reggie: He had it cast special,\nsaid 'so nobody else can ever\nplay MY high score.'",
			"Reggie: With this, I bet I can\nget that old cabinet running\nagain. For old time's sake.",
			"Reggie: ...And maybe, just maybe,\nit'll tell us something about\nwhere he went. Thanks, you two.",
		],
		"after": [
			"Reggie: Still tinkering with that\ncabinet. One of these days,\nI'll get it humming again.",
		],
	},
	"fanny": {
		"want_item": "fannys_bottle", "give_item": "", "spoon": "numbered_spoon_04",
		"intro": [
			"Fanny: Oh, hello. You'll have to\nexcuse me -- I've been a bit\nout of sorts lately.",
			"Fanny: I lost a little bottle of\nmine somewhere in those awful\ntunnels. F.B., it's marked.",
			"Fanny: Lavender scent. My\nfavorite. I've looked\neverywhere I dare to go.",
			"Fanny: If you're brave enough to\nsearch down there, I'd be so\ngrateful to have it back.",
		],
		"reminder": [
			"Fanny: Still no sign of my\nlittle bottle? It's dark down\nthere -- you may need a light.",
		],
		"turn_in": [
			"Fanny: You found it! Oh, thank\ngoodness. I thought I'd lost\nit for good.",
			"Fanny: Doug gave me this, you\nknow. The day before he\ndisappeared.",
			"Fanny: He said, 'Hang onto this,\nFanny -- something to remember\nme by, just in case.'",
			"Fanny: I didn't think much of it\nat the time. Now I wonder if\nhe knew something was coming.",
			"Fanny: Thank you for finding it.\nIt means more to me than you\ncould know.",
		],
		"after": [
			"Fanny: I keep that bottle close\nnow. Thank you again for\nbringing it back to me.",
		],
	},
	"penny": {
		"want_item": "embroidered_handkerchief", "give_item": "stitched_patch", "spoon": "numbered_spoon_05",
		"intro": [
			"Penny: Hiya! You two look like\nyou get around. Mind doing me\na favor?",
			"Penny: I was mending an old\nhandkerchief for a customer --\nan embroidered 'D,' very fancy.",
			"Penny: I dropped it somewhere in\nthe Old Parish Church on my way\nto deliver it. So clumsy!",
			"Penny: The customer was a sweet\nold fellow named Doug. Haven't\nseen him to apologize, even.",
			"Penny: If you find it among the\npews, I'd be ever so grateful.\nI'll make it worth your while!",
		],
		"reminder": [
			"Penny: Any luck with that\nhandkerchief? Should be\nsomewhere around the pews.",
		],
		"turn_in": [
			"Penny: You found it! Oh, thank\nyou! I felt awful about losing\nMr. Doug's handkerchief.",
			"Penny: Here -- I made this little\npatch for whoever found it. A\ngear, since Doug loved his tools.",
			"Penny: Sew it on somewhere\nnobody will notice. It's small,\nbut it's something.",
			"Penny: If you do see Doug around,\ntell him I'm sorry -- and that\nI'll mend it properly this time.",
		],
		"after": [
			"Penny: Still hoping to track down\nMr. Doug and finish that\nmending properly. Thanks again.",
		],
	},
	"otis": {
		"want_item": "brass_compass", "give_item": "sailors_knot_bracelet", "spoon": "numbered_spoon_06",
		"intro": [
			"Otis: Well now, fresh faces!\nDon't get many of those down\nby the docks these days.",
			"Otis: Say -- you wouldn't have\nspotted an old brass compass\nlying around the harbor, eh?",
			"Otis: Lost it in all the cargo\nshuffle. Hasn't pointed north\nright in years, but it's mine.",
			"Otis: Engraved on the back: 'To\nO.' -- that's me, Otis. Gift\nfrom an old friend.",
			"Otis: Find it for me and I'll tie\nyou up a proper sailor's knot.\nGood luck charm, that.",
		],
		"reminder": [
			"Otis: Still keeping an eye out\nfor my compass? Probably buried\nunder cargo somewhere.",
		],
		"turn_in": [
			"Otis: Ha! There it is. Knew it\nhad to be down here\nsomewhere.",
			"Otis: 'To O., so you always find\nyour way home.' Doug gave me\nthis, years back.",
			"Otis: Funny thing to give a\nsailor whose home IS the docks.\nBut that was Doug.",
			"Otis: Said everybody needs a way\nback, even if they don't know\nthey're lost yet.",
			"Otis: Here -- a sailor's knot,\nlike I promised. Tie it on.\nMight bring you luck, too.",
		],
		"after": [
			"Otis: That compass still doesn't\npoint north. But it points\nhome. Good enough for me.",
		],
	},
}

# Second wave of quests, for the new NPC_DATA_2 quest-givers -- see CLAUDE.md
# "Numbered Spoons". Wendell/Clara/Ambrose/Dottie are ordinary fetch quests
# (want_item -> spoon, no flavor give_item). Tobias/Agnes have no want_item:
# they were "freed" by the player finding a secret passage elsewhere, so the
# very first conversation both completes the quest and hands over their spoon
# -- see overworld_map.gd._talk_to_npc()'s want_item == "" branch. Every quest
# here (and every quest above, via the "spoon" key added to QUESTS) grants
# exactly one of the 12 numbered_spoon_NN items.
const QUESTS_2: Dictionary = {
	"wendell": {
		"want_item": "ticket_stub_torn", "give_item": "", "spoon": "numbered_spoon_07",
		"intro": [
			"Wendell: ...Oh. Visitors. Don't\nget many of those out here.",
			"Wendell: I collect ticket stubs --\nodd hobby, I know. Lost one\nsomewhere near the Carnival.",
			"Wendell: Torn clean in half. If you\nspot it, I'd love to add it\nback to the collection.",
		],
		"reminder": [
			"Wendell: Still no torn ticket\nstub? It'd have blown around\nnear the Carnival, probably.",
		],
		"turn_in": [
			"Wendell: That's the one! Thank\nyou. Every stub tells a\nlittle story.",
			"Wendell: Here, take this -- found\nit years ago, no idea what it\ngoes to. Number 7, see?",
			"Wendell: I had eleven others like\nit once, scattered all over\ntown. Funny, isn't it?",
			"Wendell: Always wondered what kind\nof game needs that many\nidentical spoons.",
		],
		"after": [
			"Wendell: Thanks again for that\nstub. Let me know if you ever\nfind the rest of that set.",
		],
	},
	"clara": {
		"want_item": "tangled_headphone_cable", "give_item": "", "spoon": "numbered_spoon_08",
		"intro": [
			"Clara: Hey! You two get around,\nright? I'm missing a cable for\nmy crystal radio project.",
			"Clara: Tangled mess of a thing,\nlast I saw it near the\nRecording Studio.",
			"Clara: Probably looks like junk to\nmost people. To me it's a\nspare part. Keep an eye out?",
		],
		"reminder": [
			"Clara: Still no cable? It's\nprobably tangled up with\nsomething else by now.",
		],
		"turn_in": [
			"Clara: You found it! Perfect,\nthanks. This'll patch right\ninto the radio.",
			"Clara: Oh -- this was tangled up\nwith it. A spoon? Number 8,\nstamped right there.",
			"Clara: No idea why anyone would\ntape a spoon to a headphone\ncable. Yours now, I guess.",
		],
		"after": [
			"Clara: Radio's coming along\nnicely, thanks to you. Still\npicking up mostly static, but!",
		],
	},
	"ambrose": {
		"want_item": "faded_treasure_map", "give_item": "", "spoon": "numbered_spoon_09",
		"intro": [
			"Ambrose: Ah, travelers! I'm an\namateur cartographer. Maps\nfascinate me, even bad ones.",
			"Ambrose: I heard tell of a faded\ntreasure map down at the\nHarbor & Docks. Useless, but--",
			"Ambrose: --I'd love to study it\nanyway. The X's never line up\nwith anything, but still!",
		],
		"reminder": [
			"Ambrose: Any luck with that\ntreasure map? Probably stuffed\nin a crate down at the docks.",
		],
		"turn_in": [
			"Ambrose: Wonderful! Let's see...\nyes, these landmarks match\nNOTHING. Fascinating.",
			"Ambrose: Hold on -- something was\nfolded inside it. A spoon,\nnumbered '9'.",
			"Ambrose: Maybe X marked this spot\nafter all. Here, it's yours --\nI'm keeping the map.",
		],
		"after": [
			"Ambrose: Still cross-referencing\nthat map against, well,\nreality. Slow going.",
		],
	},
	"dottie": {
		"want_item": "rabbits_foot_keychain", "give_item": "", "spoon": "numbered_spoon_10",
		"intro": [
			"Dottie: Ooh, hello! I collect\nlucky charms. Doesn't matter\nif they actually work.",
			"Dottie: I heard there's a rabbit's\nfoot keychain out wherever\nthe team made their big jump.",
			"Dottie: 'The Drop,' they call it?\nSounds thrilling. If you find\nit, it'd complete my shelf.",
		],
		"reminder": [
			"Dottie: Still no rabbit's foot?\nIt can't have gone far --\nthere's nowhere TO go, really.",
		],
		"turn_in": [
			"Dottie: You found it! My shelf is\ncomplete. Well -- ENOUGH.\nThere's always more to find.",
			"Dottie: Funny, this was tucked\nunderneath it. Spoon, marked\n'10'. Double digits!",
			"Dottie: Here, take it. Whatever\ngame these belong to, it's a\nbig one. Lucky you, I suppose.",
		],
		"after": [
			"Dottie: Still feeling lucky from\nthat rabbit's foot. Or maybe\nthat's just my outlook. Thanks!",
		],
	},
	"tobias": {
		"want_item": "", "give_item": "", "spoon": "numbered_spoon_11", "reminder": [], "turn_in": [],
		"intro": [
			"Tobias: ...Whoa. Daylight. Hadn't\nseen that in a while.",
			"Tobias: I got turned around in\nthat parts closet behind the\norgan workshop. Thanks for\nfinding the way through.",
			"Tobias: Here -- found this rolling\naround in there with me.\nSpoon, marked '11'. Yours.",
			"Tobias: Don't ask me what it's for.\nI was just glad for the\ncompany, honestly.",
		],
		"after": [
			"Tobias: Good to be back out and\nabout. Thanks again for\nletting some light in.",
		],
	},
	"agnes": {
		"want_item": "", "give_item": "", "spoon": "numbered_spoon_12", "reminder": [], "turn_in": [],
		"intro": [
			"Agnes: Oh! Someone found the\nloft. I've been up there\npracticing for, oh, ages.",
			"Agnes: Lovely organ, that one. A\nbit dusty. Anyway -- you\nstartled this right out of\nmy pocket.",
			"Agnes: A spoon. Number '12', if\nyou squint. A full dozen, all\nnumbered, none useful for soup.",
			"Agnes: Definitely a game piece --\nbut for which game, I\ncouldn't tell you. Keep it!",
		],
		"after": [
			"Agnes: Back to practicing, I\nthink. Thanks for the\ncompany -- and the daylight.",
		],
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
