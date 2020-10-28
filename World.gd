extends Control

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func trade_stock(stock_color, amount):
	print("trade_stock " + str(stock_color) + "" + str(amount))
	var p_id = get_tree().get_network_unique_id()
	if get_tree().is_network_server():
		verify_trade(1, stock_color, amount)
	else:
		rpc_id(1, "verify_trade", p_id, stock_color, amount)

remote func verify_trade(p_id, stock_color, amount):
	print("verify trade " + str(p_id) + str(stock_color) + str(amount))
