extends AnimatedSprite

var player = null
var playerTouch = false

func _ready():
	RemoveStrengthSingleton.connect("removeStrength", self, "removalOfStrengthFloor")

func _on_Area2D_body_entered(body):
	player = body
	playerTouch = true
	StrengthSingleton.strength()
	self.queue_free()

func removalOfStrengthFloor():
	self.queue_free()
