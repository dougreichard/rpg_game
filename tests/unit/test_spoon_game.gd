extends GutTest

# "Gimme Dat Spoon" rules engine (scripts/systems/spoon_game.gd) -- a UI-agnostic
# RefCounted, same scene-free shape as test_unlock_chain.gd. Locks in the
# "Endgame: The Pile" rules from locations/gimme_data_spoon.md, which are
# intricate and easy to silently break on a future tweak: Anchor shield
# (immunity, then expiry-elimination), the Magnet/Spinner/Switch/Reverse/
# Anchorless power effects, the two-player pile-discard phase, and the
# pile-vs-survivor tiebreak.

const SpoonGameScript = preload("res://scripts/systems/spoon_game.gd")

const NAMES: Array = ["P0", "P1", "P2", "P3", "P4", "P5"]
const COLORS: Array = [Color.RED, Color.GREEN, Color.BLUE, Color.YELLOW, Color.PURPLE, Color.CYAN]


func _new_game():
	var game = SpoonGameScript.new()
	game.start(NAMES.duplicate(), COLORS.duplicate())
	return game


func test_deal_gives_each_player_two_spoons_with_one_of_each_power() -> void:
	var game = _new_game()
	assert_eq(game.players.size(), 6, "should deal to all 6 players")
	var total: int = 0
	var counts: Dictionary = {}
	for p in game.players:
		assert_eq(p["hand"].size(), 2, "each player should start with 2 spoons")
		total += p["hand"].size()
		for spoon in p["hand"]:
			counts[spoon] = counts.get(spoon, 0) + 1
	assert_eq(total, 12, "12 spoons total (6 power + 6 standard)")
	assert_eq(counts.get("standard", 0), 6, "6 standard spoons")
	for power_type in SpoonGameScript.POWER_TYPES:
		assert_eq(counts.get(power_type, 0), 1, "exactly one %s spoon" % power_type)


func test_next_alive_skips_eliminated_players() -> void:
	var game = _new_game()
	game.players[1]["alive"] = false
	game.players[2]["alive"] = false
	game.direction = 1
	assert_eq(game._next_alive(0, 1), 3, "should skip eliminated players 1 and 2")
	game.direction = -1
	assert_eq(game._next_alive(0, 1), 5, "should wrap and skip backwards too")


func test_resolve_turn_passes_spoon_to_recipient() -> void:
	var game = _new_game()
	for p in game.players:
		p["hand"] = ["standard", "standard"]
	game.active_idx = 0
	game._pending_recipient_idx = 1
	watch_signals(game)
	game.resolve_turn("standard", false)
	assert_eq(game.players[0]["hand"].size(), 1, "passer should have one fewer spoon")
	assert_eq(game.players[1]["hand"].size(), 3, "recipient should gain the passed spoon")
	assert_signal_emitted(game, "spoon_passed")


func test_anchor_activation_shields_from_elimination_on_empty_hand() -> void:
	var game = _new_game()
	for p in game.players:
		p["hand"] = ["standard"]
	game.players[0]["hand"] = ["anchor"]
	game.active_idx = 0
	game._pending_recipient_idx = 1
	watch_signals(game)
	game.resolve_turn("anchor", true)
	assert_true(game.players[0]["hand"].is_empty(), "anchor spoon should be passed away")
	assert_true(game.players[0]["alive"], "shield should prevent elimination on empty hand")
	assert_true(game.players[0]["shielded"], "player should be marked shielded")
	assert_signal_emitted_with_parameters(game, "power_activated", [0, "anchor"])


func test_anchor_shield_expires_and_eliminates_if_still_empty_at_next_turn() -> void:
	var game = _new_game()
	for p in game.players:
		p["hand"] = ["standard", "standard"]
	game.players[1]["hand"] = []
	game.players[1]["shielded"] = true
	watch_signals(game)
	game._advance_turn(0, 1, false)
	assert_false(game.players[1]["alive"], "shield expiry with an empty hand should eliminate")
	assert_signal_emitted_with_parameters(game, "player_eliminated", [1])
	assert_eq(game.active_idx, 2, "turn should skip the just-eliminated player")


func test_magnet_activation_conserves_total_spoon_count() -> void:
	var game = _new_game()
	for p in game.players:
		p["hand"] = ["standard", "standard"]
	game.players[0]["hand"] = ["magnet", "standard"]
	game.active_idx = 0
	game._pending_recipient_idx = 1
	watch_signals(game)
	game.resolve_turn("magnet", true)
	assert_false(game.players[0]["hand"].has("magnet"), "magnet spoon should be consumed")
	assert_eq(game.players[0]["hand"].size(), 2, "passer should steal back a spoon to stay even")
	assert_eq(game.players[1]["hand"].size(), 2, "recipient should end up even too")
	assert_signal_emitted_with_parameters(game, "power_activated", [0, "magnet"])


func test_spinner_activation_redirects_to_another_player() -> void:
	var game = _new_game()
	for p in game.players:
		p["hand"] = ["standard", "standard"]
	game.players[0]["hand"] = ["spinner", "standard"]
	game.active_idx = 0
	game._pending_recipient_idx = 1
	watch_signals(game)
	game.resolve_turn("spinner", true)
	assert_eq(game.players[1]["hand"].size(), 2, "recipient shouldn't keep the spinner's standard spoon")
	assert_signal_emitted(game, "spoon_passed")
	var params: Array = get_signal_parameters(game, "spoon_passed", 1)
	assert_eq(params[2], "spinner_redirect", "second pass should be the spinner redirect")
	assert_ne(params[1], 1, "redirect target should not be the original recipient")


func test_switch_activation_seizes_turn_order() -> void:
	var game = _new_game()
	for p in game.players:
		p["hand"] = ["standard", "standard"]
	game.players[0]["hand"] = ["switch", "standard"]
	game.active_idx = 0
	game._pending_recipient_idx = 3
	game.resolve_turn("switch", true)
	assert_eq(game.active_idx, 3, "recipient should seize the turn immediately")


func test_reverse_activation_flips_direction() -> void:
	var game = _new_game()
	for p in game.players:
		p["hand"] = ["standard", "standard"]
	game.players[0]["hand"] = ["reverse", "standard"]
	game.active_idx = 0
	game._pending_recipient_idx = 1
	assert_eq(game.direction, 1, "should start clockwise")
	watch_signals(game)
	game.resolve_turn("reverse", true)
	assert_eq(game.direction, -1, "activating reverse should flip direction")
	assert_signal_emitted_with_parameters(game, "direction_changed", [-1])


func test_anchorless_activation_exiles_spoon_without_passing() -> void:
	var game = _new_game()
	for p in game.players:
		p["hand"] = ["standard", "standard"]
	game.players[0]["hand"] = ["anchorless", "standard"]
	game.active_idx = 0
	game._pending_recipient_idx = 1
	watch_signals(game)
	game.resolve_turn("anchorless", true)
	assert_eq(game.discarded_count, 1, "exiled spoon should count toward the pile")
	assert_eq(game.players[1]["hand"].size(), 2, "recipient should not receive anything")
	assert_signal_emitted_with_parameters(game, "spoon_passed", [0, 1, "anchorless_exiled"])


func test_two_player_discard_advances_turn_without_passing() -> void:
	var game = _new_game()
	for i in range(2, 6):
		game.players[i]["alive"] = false
	game.players[0]["hand"] = ["standard", "standard"]
	game.players[1]["hand"] = ["standard"]
	game.active_idx = 0
	watch_signals(game)
	game.resolve_discard("standard")
	assert_eq(game.players[0]["hand"].size(), 1, "discarded spoon should leave the hand")
	assert_eq(game.discarded_count, 1, "discard should add to the pile")
	assert_eq(game.active_idx, 1, "turn should pass to the other player")
	assert_signal_emitted_with_parameters(game, "spoon_discarded", [0, "standard"])


func test_pile_wins_when_pile_size_at_least_survivors_hand() -> void:
	var game = _new_game()
	for i in range(2, 6):
		game._eliminate(i)
	game.players[0]["hand"] = ["standard", "standard"]
	game.players[1]["hand"] = []
	game.discarded_count = 2
	watch_signals(game)
	game._eliminate(1)
	var over: bool = game._check_game_over()
	assert_true(over, "game should be over with one player remaining")
	assert_signal_emitted_with_parameters(game, "game_over", [-1])


func test_survivor_wins_when_pile_smaller_than_their_hand() -> void:
	var game = _new_game()
	for i in range(2, 6):
		game._eliminate(i)
	game.players[0]["hand"] = ["standard", "standard"]
	game.players[1]["hand"] = []
	game.discarded_count = 1
	watch_signals(game)
	game._eliminate(1)
	var over: bool = game._check_game_over()
	assert_true(over, "game should be over with one player remaining")
	assert_signal_emitted_with_parameters(game, "game_over", [0])
