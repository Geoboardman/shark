extends TextureButton


var x = 0
var y = 0

var quadrant = 0
signal on_tile_clicked()
# Called when the node enters the scene tree for the first time.
func _ready():
	pass
	
func init(quad):
	quadrant = quad
	if quadrant > 0:
		$Label.text = str(quadrant)
	else:
		$Label.text = ""	


func _on_Tile_button_up():
	emit_signal("on_tile_clicked")
