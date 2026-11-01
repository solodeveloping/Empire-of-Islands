@tool
extends Entity
class_name PotatoField2D_ECS

func define_components() -> Array:
	return [
		C_Building.new(Buildings.Ids.PotatoField),
		C_Name.new("Potato field"),
		C_Transform2D.new(),
		C_Health.new(100),
		C_Production.new(
			Resources.Types.Potato,
			1,
			3.0
		),
		C_CollectionBuilding.new(),
		C_CanExtendFarm.new(),
		C_RangeBox.new(
			Vector3(
				50,
				1,
				50,
			)
		),
		C_WorkerRequirement.new(
			[
				Worker_Requirement.new(
					Populations.Types.Sailor,
					1,
					1
				)
			]
		),
		C_Workers.new({
			Populations.Types.Sailor: WorkerQuantity.new(
				Populations.Types.Sailor,
				0
			)
		}),
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
