@tool
extends TabWidget
class_name ShipMenuTabWidget

# FIXME: comment
##onready var faction_indicator := $WidgetDetail/Body/ShipMenu/MarginContainer/FactionIndicator
#@onready var faction_indicator := find_child("FactionIndicator")
#
#func _ready() -> void:
	#if Engine.is_editor_hint():
		#return
#
	#faction_indicator.texture = Global.FACTIONS[Global.faction].emblem
