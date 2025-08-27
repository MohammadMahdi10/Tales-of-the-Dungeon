extends AnimatedSprite

var player = null
var playerTouch = false

func _ready():
	RemoveSpeedSingleton.connect("removeSpeed", self, "removalOfSpeedFloor")

func _on_Area2D_body_entered(body):
	player = body
	playerTouch = true
	SpeedSingleton.speed()
	self.queue_free()

func removalOfSpeedFloor():
	self.queue_free()
