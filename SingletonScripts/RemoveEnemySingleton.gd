extends Node

signal removeEnemy

func enemyRemoval():
	emit_signal("removeEnemy")
