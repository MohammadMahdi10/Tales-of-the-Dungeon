extends Sprite

var player = null
var player_enter = false

func _ready():
	RemoveLadderSingleton.connect("removeLadder", self, "removalOfLadderFloor")

func _on_Area2D_body_entered(body):
	player = body
	player_enter = true
	LadderSingleton.ladderTransmit()
	self.queue_free()

func removalOfLadderFloor():
	self.queue_free()
	
