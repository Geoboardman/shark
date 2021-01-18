extends Control

var highlight = load("res://PlayerHighlight.tres")
var player_name = "player name"
var money = 0
var final_score = 0
# Stock counts in id:number.
var stocks = {
	gamestate.Stock_Color.YELLOW: 0,
	gamestate.Stock_Color.RED: 0,
	gamestate.Stock_Color.BLUE: 0,
	gamestate.Stock_Color.GREEN: 0,
}

signal add_event_text()

# Called when the node enters the scene tree for the first time.
func _ready():
	$HBox/VCont/Name.text = player_name
	set_money(0)
	$HBox/VCont/Stock/RedStock.text = str(stocks[gamestate.Stock_Color.RED])
	$HBox/VCont/Stock/BlueStock.text = str(stocks[gamestate.Stock_Color.BLUE])
	$HBox/VCont/Stock/GreenStock.text = str(stocks[gamestate.Stock_Color.GREEN])
	$HBox/VCont/Stock/YellowStock.text = str(stocks[gamestate.Stock_Color.YELLOW])

func set_current_player(enable):
	if enable:
		set("custom_styles/panel", highlight)
	else:
		set("custom_styles/panel", null)

func set_money(money_delta):
	money += money_delta
	$HBox/VCont/Money.text = "$" + str(money)
	if money < 0:
		$HBox/VCont/Money.set("custom_colors/font_color", Color(1,0,0))
	else:
		$HBox/VCont/Money.set("custom_colors/font_color", Color(1,1,1))


func set_stock(stock_color, stock_delta):
	stocks[stock_color] += stock_delta
	$HBox/VCont/Stock/RedStock.text = str(stocks[gamestate.Stock_Color.RED])
	$HBox/VCont/Stock/BlueStock.text = str(stocks[gamestate.Stock_Color.BLUE])
	$HBox/VCont/Stock/GreenStock.text = str(stocks[gamestate.Stock_Color.GREEN])
	$HBox/VCont/Stock/YellowStock.text = str(stocks[gamestate.Stock_Color.YELLOW])	

remotesync func buy_stock(stock_color, stock_price, amount):
	print("player buy stock")
	var cost = amount * stock_price * -1
	set_money(cost)
	set_stock(stock_color, amount)
	
remotesync func sell_stock(stock_color, stock_price, amount):
	print("player sell stock")
	var cost = amount * stock_price * -1
	set_money(cost)
	set_stock(stock_color, amount)

remotesync func update_money(delta):
	set_money(delta)

master func remove_player():
	rpc("eliminated")

remotesync func eliminated():
	$HBox/VCont/Money.hide()
	$HBox/VCont/Label.hide()
	$HBox/VCont/Stock.hide()
	$HBox/VCont/Eliminated.show()

master func stock_value_change(stock_delta, stock_color):
	if stocks[stock_color] > 0:
		print("i have those stocks")
		var money_delta = stocks[stock_color] * stock_delta * gamestate.SINGLE_STOCK_VAL
		rpc("update_money", money_delta)
		if money_delta > 0:
			emit_signal("add_event_text", player_name + " earned $" + str(money_delta) + " for owning" + str(gamestate.Stock_Color.keys()[stock_color]) + " stock")
		else:
			emit_signal("add_event_text", player_name + " lost $" + str(money_delta) + " on " + str(gamestate.Stock_Color.keys()[stock_color]) + " stock")

remotesync func set_final_score(score):
	final_score = score
	$HBox/FinalScore.show()
	$HBox/FinalScore.text = "Final Score: $" + str(score);
