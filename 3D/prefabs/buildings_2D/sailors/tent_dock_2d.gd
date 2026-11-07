@tool
extends Entity
class_name TentDock2D_ECS

func define_components() -> Array:
	return [
		C_Building.new(Buildings.Ids.Warehouse),
		C_Name.new("Dock"),
		C_Health.new(100),
		C_IsStorage.new(),
		C_Range.new(100.0),
		C_Transform2D.new(),
		C_Dock.new(),
		C_CircularVision.new(300),
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

# TODO: would be nice if it was mutualize some way

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
