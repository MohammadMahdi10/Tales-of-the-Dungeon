extends AnimatedSprite

var player = null
var playerTouch = false

func _ready():
	$".".play("CoinAnimation")
	RemoveCoinSingleton.connect("removeCoin", self, "removalOfCoinFloor")
	
func _on_Area2D_body_entered(body):
	player = body
	playerTouch = true
	CoinSingleton.emitCoinIncrement()
	self.queue_free()

func removalOfCoinFloor():
	self.queue_free()
