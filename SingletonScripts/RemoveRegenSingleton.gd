extends Node

signal removeRegen

func regenRemoval():
	emit_signal("removeRegen")
