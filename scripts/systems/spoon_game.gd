extends RefCounted

## Core turn-based rules engine for the "Gimme Dat Spoon" minigame.
## UI-agnostic -- the level script drives turns and listens to signals.

signal die_rolled(roll: int)
signal spoon_passed(from_idx: int, to_idx: int, spoon_type: String)
signal spoon_discarded(player_idx: int, spoon_type: String)
signal power_activated(player_idx: int, spoon_type: String)
signal direction_changed(direction: int)
signal player_eliminated(idx: int)
signal turn_changed(active_idx: int)
signal game_over(winner_idx: int)

const POWER_TYPES: Array[String] = ["anchor", "magnet", "spinner", "switch", "reverse", "anchorless"]
const PLAYER_COUNT: int = 6

var players: Array = []
var direction: int = 1
var active_idx: int = 0
var discarded_count: int = 0

var _pending_roll: int = 0
var _pending_recipient_idx: int = -1


func start(player_names: Array, colors: Array) -> void:
	players.clear()
	direction = 1
	discarded_count = 0
	for i in range(PLAYER_COUNT):
		players.append({
			"name": player_names[i],
			"color": colors[i],
			"hand": [],
			"alive": true,
			"shielded": false,
		})
	var pool: Array[String] = POWER_TYPES.duplicate()
	for i in range(6):
		pool.append("standard")
	pool.shuffle()
	var p_idx: int = 0
	for spoon in pool:
		players[p_idx]["hand"].append(spoon)
		p_idx = (p_idx + 1) % PLAYER_COUNT
	active_idx = randi() % PLAYER_COUNT


func alive_count() -> int:
	var n: int = 0
	for p in players:
		if p["alive"]:
			n += 1
	return n


func _next_alive(from_idx: int, steps: int) -> int:
	var idx: int = from_idx
	var taken: int = 0
	while taken < steps:
		idx = (idx + direction) % PLAYER_COUNT
		if idx < 0:
			idx += PLAYER_COUNT
		if players[idx]["alive"]:
			taken += 1
	return idx


## Rolls the die and computes who would receive the passed spoon.
## Does not mutate any hands -- call resolve_turn() to commit the turn.
## When only two players remain, rolling a 6 instead sends the active
## player's chosen spoon to "the pile" -- call resolve_discard() for these
## turns instead of resolve_turn().
func begin_turn() -> Dictionary:
	var roll: int = randi_range(1, 6)
	die_rolled.emit(roll)
	_pending_roll = roll
	if alive_count() == 2 and roll == 6:
		_pending_recipient_idx = -1
		return {"roll": roll, "recipient_idx": -1, "discard": true}
	var recipient_idx: int = _next_alive(active_idx, roll)
	_pending_recipient_idx = recipient_idx
	return {"roll": roll, "recipient_idx": recipient_idx, "discard": false}


## AI: prefer passing a standard spoon, keeping power spoons in hand.
func ai_choose_spoon(idx: int) -> String:
	var hand: Array = players[idx]["hand"]
	for spoon in hand:
		if spoon == "standard":
			return "standard"
	return hand[0]


## AI: decide whether to activate a power spoon being passed this turn.
func ai_choose_activate(idx: int, spoon_type: String) -> bool:
	var remaining: int = players[idx]["hand"].size() - 1
	match spoon_type:
		"magnet":
			return randf() < 0.9
		"spinner":
			return randf() < 0.6
		"reverse":
			return randf() < 0.4
		"anchorless":
			return remaining > 0
		"anchor":
			if remaining == 0:
				return true
			return randf() < 0.2
		"switch":
			return randf() < 0.5
		_:
			return false


## AI: when forced to discard (see begin_turn()), prefer dumping a Standard
## Spoon, keeping power spoons in hand for future turns.
func ai_choose_discard(idx: int) -> String:
	var hand: Array = players[idx]["hand"]
	for spoon in hand:
		if spoon == "standard":
			return "standard"
	return hand[0]


## Convenience for an AI-controlled seat: rolls, picks a spoon and activation
## choice via the AI heuristics, and resolves the turn in one call.
func take_ai_turn() -> void:
	var turn: Dictionary = begin_turn()
	if turn["discard"]:
		resolve_discard(ai_choose_discard(active_idx))
		return
	var spoon_type: String = ai_choose_spoon(active_idx)
	var activate: bool = false
	if spoon_type in POWER_TYPES:
		activate = ai_choose_activate(active_idx, spoon_type)
	resolve_turn(spoon_type, activate)


## Commits the pending turn: passes spoon_type from the active player to the
## recipient computed by begin_turn(), resolving any activated power.
func resolve_turn(spoon_type: String, activate: bool) -> void:
	var passer_idx: int = active_idx
	var recipient_idx: int = _pending_recipient_idx
	var hand: Array = players[passer_idx]["hand"]
	hand.erase(spoon_type)

	var is_power: bool = activate and spoon_type in POWER_TYPES
	var switch_seized: bool = false

	if is_power and spoon_type == "anchorless":
		discarded_count += 1
		power_activated.emit(passer_idx, spoon_type)
		spoon_passed.emit(passer_idx, recipient_idx, "anchorless_exiled")
	else:
		var delivered_type: String = "standard" if is_power else spoon_type
		players[recipient_idx]["hand"].append(delivered_type)
		spoon_passed.emit(passer_idx, recipient_idx, spoon_type)
		if is_power:
			power_activated.emit(passer_idx, spoon_type)
			match spoon_type:
				"anchor":
					players[passer_idx]["shielded"] = true
				"magnet":
					_take_random_spoon(recipient_idx, passer_idx)
				"spinner":
					_spin_pass(recipient_idx)
				"switch":
					switch_seized = true
				"reverse":
					direction *= -1
					direction_changed.emit(direction)

	if hand.is_empty() and not players[passer_idx]["shielded"]:
		_eliminate(passer_idx)

	if players[recipient_idx]["alive"] and players[recipient_idx]["hand"].is_empty() and not players[recipient_idx]["shielded"]:
		_eliminate(recipient_idx)

	if _check_game_over():
		return

	_advance_turn(passer_idx, recipient_idx, switch_seized)


## Commits a pending discard turn (see begin_turn()): the active player's
## chosen spoon goes to "the middle" instead of being passed -- no power
## resolves, regardless of the spoon type.
func resolve_discard(spoon_type: String) -> void:
	var passer_idx: int = active_idx
	var hand: Array = players[passer_idx]["hand"]
	hand.erase(spoon_type)
	discarded_count += 1
	spoon_discarded.emit(passer_idx, spoon_type)

	if hand.is_empty() and not players[passer_idx]["shielded"]:
		_eliminate(passer_idx)

	if _check_game_over():
		return

	_advance_turn(passer_idx, passer_idx, false)


func _take_random_spoon(from_idx: int, to_idx: int) -> void:
	var from_hand: Array = players[from_idx]["hand"]
	if from_hand.is_empty():
		return
	var i: int = randi() % from_hand.size()
	var spoon: String = from_hand[i]
	from_hand.remove_at(i)
	players[to_idx]["hand"].append(spoon)


## The recipient of an activated Spinner Spoon must immediately re-pass it
## to a new random target (excluding themselves).
func _spin_pass(recipient_idx: int) -> void:
	var hand: Array = players[recipient_idx]["hand"]
	hand.erase("standard")
	var targets: Array[int] = []
	for i in range(PLAYER_COUNT):
		if i != recipient_idx and players[i]["alive"]:
			targets.append(i)
	if targets.is_empty():
		hand.append("standard")
		return
	var target_idx: int = targets[randi() % targets.size()]
	players[target_idx]["hand"].append("standard")
	spoon_passed.emit(recipient_idx, target_idx, "spinner_redirect")


func _eliminate(idx: int) -> void:
	players[idx]["alive"] = false
	players[idx]["shielded"] = false
	player_eliminated.emit(idx)


## Game ends once at most one player remains. winner_idx == -1 means
## "the middle wins" -- either no player is left standing, or the survivor's
## shield expired and emptied their hand too, or the middle's pile is at
## least as large as the survivor's remaining hand.
func _check_game_over() -> bool:
	if alive_count() > 1:
		return false

	var winner_idx: int = -1
	for i in range(PLAYER_COUNT):
		if players[i]["alive"]:
			winner_idx = i
			break

	if winner_idx != -1 and players[winner_idx]["shielded"]:
		players[winner_idx]["shielded"] = false
		if players[winner_idx]["hand"].is_empty():
			_eliminate(winner_idx)
			winner_idx = -1

	if winner_idx != -1 and discarded_count >= players[winner_idx]["hand"].size():
		winner_idx = -1

	game_over.emit(winner_idx)
	return true


func _advance_turn(passer_idx: int, recipient_idx: int, switch_seized: bool) -> void:
	var next_idx: int
	if switch_seized:
		next_idx = recipient_idx
	else:
		next_idx = _next_alive(passer_idx, 1)

	# Resolve Anchor-shield expiry for the player whose turn is starting.
	while players[next_idx]["shielded"]:
		players[next_idx]["shielded"] = false
		if players[next_idx]["hand"].is_empty():
			_eliminate(next_idx)
			if _check_game_over():
				return
			next_idx = _next_alive(next_idx, 1)
		else:
			break

	active_idx = next_idx
	turn_changed.emit(active_idx)
