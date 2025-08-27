extends AnimatedSprite

var player = null
var playerTouch = false

func _ready():
	RemoveRegenSingleton.connect("removeRegen", self, "removalOfRegenFloor")

func _on_Area2D_body_entered(body):
	player = body
	playerTouch = true
	RegenerationSingleton.regeneration()
	self.queue_free()

func removalOfRegenFloor():
	self.queue_free()
