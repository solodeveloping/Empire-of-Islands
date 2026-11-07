@tool
extends Entity
class_name MainSquare2D_ECS

func define_components() -> Array:
	return [
		C_Building.new(Buildings.Ids.MainSquare),
		C_MainSquare.new(),
		C_Health.new(100),
		C_Range.new(25.0),
		C_Transform2D.new(),
		C_Name.new("Main square"),
		C_CircularVision.new(250),
	]

func on_ready():
	ECSBuilding2DUtils.setup_trans_and_vision(
		self
	)

var visual_node: Node
func set_visual_node(node: Node):
	visual_node = node

func get_visual_node() -> Node:
	return visual_node

func _on_vision_area_area_entered(
	area: Area2D
):
	#print("_on_vision_area_area_entered %s %s" % [
		#self.get_path(),
		#area.get_path(),
	#])
	if area == self or area.get_parent() == self:
		return
	
	if !area.get_parent().has_method("handle_area_entered"):
		return
	
	if area.get_parent().get_meta(StaticFactions.BELONGS_TO_LOCAL_PLAYER_META, false):
		return
	
	area.get_parent().handle_area_entered(self)

func _on_vision_area_area_exited(
	area: Area2D
):
	#print("_on_vision_area_area_exited %s %s" % [
		#self.get_path(),
		#area.get_path(),
	#])
	if area == self or area.get_parent() == self:
		return
	
	if !area.get_parent().has_method("handle_area_exited"):
		return
	
	if area.get_parent().get_meta(StaticFactions.BELONGS_TO_LOCAL_PLAYER_META, false):
		return
	
	area.get_parent().handle_area_exited(self)
