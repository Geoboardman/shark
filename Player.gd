extends Control


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
	$Name.text = player_name
	$Money.text = str(money)
	$Stock/RedStock.text = str(stocks[gamestate.Stock_Color.RED])
	$Stock/BlueStock.text = str(stocks[gamestate.Stock_Color.BLUE])
	$Stock/GreenStock.text = str(stocks[gamestate.Stock_Color.GREEN])
	$Stock/YellowStock.text = str(stocks[gamestate.Stock_Color.YELLOW])

func set_money(money_delta):
	money += money_delta
	$Money.text = str(money)

func set_stock(stock_color, stock_delta):
	stocks[stock_color] += stock_delta
	$Stock/RedStock.text = str(stocks[gamestate.Stock_Color.RED])
	$Stock/BlueStock.text = str(stocks[gamestate.Stock_Color.BLUE])
	$Stock/GreenStock.text = str(stocks[gamestate.Stock_Color.GREEN])
	$Stock/YellowStock.text = str(stocks[gamestate.Stock_Color.YELLOW])	
