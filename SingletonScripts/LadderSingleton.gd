extends Node

signal ladderEnter

func ladderTransmit():
	emit_signal("ladderEnter")
