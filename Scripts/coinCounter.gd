extends Node

signal enemyCoinIncrement

func emitEnemyCoin():
	emit_signal("enemyCoinIncrement")
