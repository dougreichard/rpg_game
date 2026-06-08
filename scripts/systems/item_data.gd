class_name ItemData
extends Resource

## A collectible — gates a puzzle, buffs a character, or (for junk/lore items)
## just looks like it should and doesn't. See CLAUDE.md "Collectibles & Inventory".

@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var icon_color: Color = Color.WHITE
## "" = any character can hold/use it; a name like "Quinn" binds it to them
## (e.g. each character's own Grand Marquee ticket).
@export var owner_character: String = ""
## True for the comedic red-herring items that look load-bearing but gate nothing.
@export var is_junk: bool = false
