extends HBoxContainer

signal stock_picked(color)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func _on_RedStockBox_button_up():
	emit_signal("stock_picked", gamestate.Stock_Color.RED)


func _on_BlueStockBox_button_up():
	emit_signal("stock_picked", gamestate.Stock_Color.BLUE)


func _on_GreenStockBox_button_up():
	emit_signal("stock_picked", gamestate.Stock_Color.GREEN)


func _on_YellowStockBox_button_up():
	emit_signal("stock_picked", gamestate.Stock_Color.YELLOW)
