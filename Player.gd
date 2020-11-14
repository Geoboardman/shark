extends Control

var highlight = load("res://PlayerHighlight.tres")
var player_name = "player name"
var money = 0
# Stock counts in id:number.
var stocks = {
	gamestate.Stock_Color.YELLOW: 0,
	gamestate.Stock_Color.RED: 0,
	gamestate.Stock_Color.BLUE: 0,
	gamestate.Stock_Color.GREEN: 0,
}

# Called when the node enters the scene tree for the first time.
func _ready():
	$VCont/Name.text = player_name
	set_money(0)
	$VCont/Stock/RedStock.text = str(stocks[gamestate.Stock_Color.RED])
	$VCont/Stock/BlueStock.text = str(stocks[gamestate.Stock_Color.BLUE])
	$VCont/Stock/GreenStock.text = str(stocks[gamestate.Stock_Color.GREEN])
	$VCont/Stock/YellowStock.text = str(stocks[gamestate.Stock_Color.YELLOW])

func set_current_player(enable):
	if enable:
		set("custom_styles/panel", highlight)
	else:
		set("custom_styles/panel", null)

func set_money(money_delta):
	money += money_delta
	$VCont/Money.text = "$" + str(money)
	if money < 0:
		$VCont/Money.set("custom_colors/font_color", Color(1,0,0))
	else:
		$VCont/Money.set("custom_colors/font_color", Color(1,1,1))


func set_stock(stock_color, stock_delta):
	stocks[stock_color] += stock_delta
	$VCont/Stock/RedStock.text = str(stocks[gamestate.Stock_Color.RED])
	$VCont/Stock/BlueStock.text = str(stocks[gamestate.Stock_Color.BLUE])
	$VCont/Stock/GreenStock.text = str(stocks[gamestate.Stock_Color.GREEN])
	$VCont/Stock/YellowStock.text = str(stocks[gamestate.Stock_Color.YELLOW])	

remotesync func buy_stock(stock_color, stock_price, amount):
	print("player buy stock")
	var cost = amount * stock_price * -1 * gamestate.SINGLE_STOCK_VAL
	set_money(cost)
	set_stock(stock_color, amount)
	
remotesync func sell_stock(stock_color, stock_price, amount):
	print("player sell stock")
	var cost = amount * stock_price * -1 * gamestate.SINGLE_STOCK_VAL
	set_money(cost)
	set_stock(stock_color, amount)

remotesync func update_money(delta):
	set_money(delta)

master func stock_value_change(stock_delta, stock_color):
	if stocks[stock_color] > 0:
		print("we have stock: " + str(stocks[stock_color]))
		var money_delta = stocks[stock_color] * stock_delta * gamestate.SINGLE_STOCK_VAL
		print("money delta: " + str(money_delta))
		rpc("update_money", money_delta)
