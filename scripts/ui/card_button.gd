extends Button
class_name CardButton

signal card_selected(index: int)

var card_index: int = -1

func configure(index: int, card: Dictionary, playable: bool) -> void:
	card_index = index
	text = "%s\n[%d] %s" % [card.title, card.cost, card.description]
	disabled = not playable
	modulate = Color(1, 1, 1, 1) if playable else Color(0.7, 0.7, 0.7, 1)

func _pressed() -> void:
	emit_signal("card_selected", card_index)
