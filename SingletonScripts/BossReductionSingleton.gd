extends Node

signal bossHealth

func bossHealthReduction():
	emit_signal("bossHealth")
