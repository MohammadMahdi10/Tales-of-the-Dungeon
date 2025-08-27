extends Node

signal coinIncrement

func emitCoinIncrement():
	emit_signal("coinIncrement")

