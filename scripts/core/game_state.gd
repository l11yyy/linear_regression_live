extends Node
class_name GameState

signal battle_state_changed(state: Dictionary)
signal battle_log_added(entry: String)
signal battle_won
signal battle_lost

const STARTING_DECK := [
	{"id": "strike", "title": "Strike", "description": "Deal 6 damage.", "cost": 1, "damage": 6, "block": 0, "card_type": "attack"},
	{"id": "strike", "title": "Strike", "description": "Deal 6 damage.", "cost": 1, "damage": 6, "block": 0, "card_type": "attack"},
	{"id": "strike", "title": "Strike", "description": "Deal 6 damage.", "cost": 1, "damage": 6, "block": 0, "card_type": "attack"},
	{"id": "defend", "title": "Defend", "description": "Gain 5 block.", "cost": 1, "damage": 0, "block": 5, "card_type": "skill"},
	{"id": "defend", "title": "Defend", "description": "Gain 5 block.", "cost": 1, "damage": 0, "block": 5, "card_type": "skill"},
	{"id": "bash", "title": "Bash", "description": "Deal 8 damage.", "cost": 2, "damage": 8, "block": 0, "card_type": "attack"}
]

const PLAYER_TEMPLATE := {
	"name": "Ironclad Clone",
	"max_hp": 80,
	"hp": 80,
	"block": 0,
	"energy": 3,
	"max_energy": 3
}

const ENEMY_TEMPLATE := {
	"name": "Training Dummy",
	"max_hp": 45,
	"hp": 45,
	"block": 0,
	"intent_cycle": [
		{"label": "Bonk", "damage": 6, "block": 0},
		{"label": "Guard", "damage": 0, "block": 5},
		{"label": "Heavy Swing", "damage": 10, "block": 0}
	],
	"intent_index": 0
}

var player: Dictionary = {}
var enemy: Dictionary = {}
var draw_pile: Array[Dictionary] = []
var discard_pile: Array[Dictionary] = []
var hand: Array[Dictionary] = []
var turn: int = 1
var log_entries: Array[String] = []

func _ready() -> void:
	reset_battle()

func reset_battle() -> void:
	player = PLAYER_TEMPLATE.duplicate(true)
	enemy = ENEMY_TEMPLATE.duplicate(true)
	draw_pile = []
	discard_pile = []
	hand = []
	turn = 1
	log_entries = []
	for card in STARTING_DECK:
		draw_pile.append(card.duplicate(true))
	draw_pile.shuffle()
	_add_log("A new training battle begins.")
	_start_turn(true)

func get_state() -> Dictionary:
	return {
		"turn": turn,
		"player": player.duplicate(true),
		"enemy": enemy.duplicate(true),
		"hand": hand.duplicate(true),
		"draw_size": draw_pile.size(),
		"discard_size": discard_pile.size(),
		"intent": _current_intent().duplicate(true),
		"log": log_entries.duplicate()
	}

func play_card(card_index: int) -> void:
	if card_index < 0 or card_index >= hand.size():
		return
	var card := hand[card_index]
	if card.cost > player.energy:
		_add_log("Not enough energy for %s." % card.title)
		_emit_state()
		return
	player.energy -= card.cost
	if card.damage > 0:
		_apply_damage_to_enemy(card.damage)
	if card.block > 0:
		player.block += card.block
	_add_log("Player used %s." % card.title)
	discard_pile.append(card)
	hand.remove_at(card_index)
	_check_battle_end()
	_emit_state()

func end_turn() -> void:
	player.block = 0
	var intent := _current_intent()
	if intent.block > 0:
		enemy.block += intent.block
		_add_log("Enemy gains %d block." % intent.block)
	if intent.damage > 0:
		_apply_damage_to_player(intent.damage)
		_add_log("Enemy uses %s for %d damage." % [intent.label, intent.damage])
	_check_battle_end()
	if enemy.hp > 0 and player.hp > 0:
		enemy.intent_index = (enemy.intent_index + 1) % enemy.intent_cycle.size()
		turn += 1
		_start_turn(false)
	_emit_state()

func _start_turn(is_first_turn: bool) -> void:
	player.energy = player.max_energy
	player.block = 0
	if not is_first_turn:
		_add_log("Turn %d begins." % turn)
	_draw_cards(5)
	_emit_state()

func _draw_cards(count: int) -> void:
	for _i in range(count):
		if draw_pile.is_empty():
			if discard_pile.is_empty():
				return
			draw_pile = discard_pile.duplicate(true)
			discard_pile.clear()
			draw_pile.shuffle()
		if draw_pile.is_empty():
			return
		hand.append(draw_pile.pop_back())

func _apply_damage_to_enemy(amount: int) -> void:
	var mitigated := max(amount - enemy.block, 0)
	enemy.block = max(enemy.block - amount, 0)
	enemy.hp = max(enemy.hp - mitigated, 0)
	_add_log("Enemy takes %d damage." % mitigated)

func _apply_damage_to_player(amount: int) -> void:
	var mitigated := max(amount - player.block, 0)
	player.block = max(player.block - amount, 0)
	player.hp = max(player.hp - mitigated, 0)

func _current_intent() -> Dictionary:
	return enemy.intent_cycle[enemy.intent_index]

func _check_battle_end() -> void:
	if enemy.hp <= 0:
		_add_log("Enemy defeated. Prototype victory.")
		emit_signal("battle_won")
	elif player.hp <= 0:
		_add_log("Player defeated. Prototype run ends.")
		emit_signal("battle_lost")

func _add_log(entry: String) -> void:
	log_entries.append(entry)
	emit_signal("battle_log_added", entry)

func _emit_state() -> void:
	emit_signal("battle_state_changed", get_state())
