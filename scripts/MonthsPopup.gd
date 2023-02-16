extends MenuButton

var checked_items : Array = ["01", "02", "03", "04", "05", "06", "07", "08", "09", "10", "11", "12"]

func _ready():
	self.get_popup().hide_on_checkable_item_selection = false
	self.get_popup().hide_on_item_selection = false
	self.get_popup().hide_on_state_item_selection = false
	self.get_popup().connect("id_pressed", self, "_on_item_pressed")

func _on_item_pressed(index) -> void:
	self.get_popup().toggle_item_checked(index)
	var toggled_month : String = String(index + 1).pad_zeros(2)
	if checked_items.has(toggled_month):
		checked_items.erase(toggled_month)
	else:
		checked_items.append(toggled_month)
