extends TextureButton
var middle_color = load("res://Art/red.png")

var x = 0
var y = 0
var quadrant = 0
var color = null

signal on_tile_clicked(x, y)
# Called when the node enters the scene tree for the first time.
func _ready():
	pass
	
func init(quad):
	quadrant = quad
	if quadrant <= 4:
		$Label.text = str(quadrant)
	else:
		set("Textures/Normal", middle_color)
		$Label.text = ""	


func _on_Tile_button_up():
	emit_signal("on_tile_clicked", x, y)


func set_color(c):
	print("setting color: " + (str(c)))
	color = c
	$ColorRect.show()
	$Label.hide()
	if color == gamestate.Stock_Color.RED:
		$ColorRect.color = Color(255,0,0)
	elif color == gamestate.Stock_Color.GREEN:
		$ColorRect.color = Color(0,255,0)
	elif color == gamestate.Stock_Color.BLUE:
		$ColorRect.color = Color(0,0,255)
	elif color == gamestate.Stock_Color.YELLOW:
		$ColorRect.color = Color(255,255,0)			
