extends Object
class_name MyMap

enum Minimap_Cell_Type{Deep, Shallow, Sand, Ground, Tree, Building, StoneDeposit}

enum Datas {
	Name,
	SourceId,
	AtlasCoords,
}

const datas = {
	MyMap.Minimap_Cell_Type.Deep: {
		Datas.Name: "Deep",
		Datas.SourceId: 1,
		# FIXME : IDK how to set the type
		Datas.AtlasCoords: [
			Vector2i(0, 0),
			Vector2i(0, 2),
			Vector2i(0, 4),
			Vector2i(0, 6),
			Vector2i(0, 8),
			Vector2i(1, 0),
			Vector2i(1, 2),# reference one
			Vector2i(1, 4),
			Vector2i(2, 0),
			Vector2i(2, 2),
			Vector2i(2, 4),
			Vector2i(2, 6),
			Vector2i(2, 8),
		],
	},
	MyMap.Minimap_Cell_Type.Shallow: {
		Datas.Name: "Shallow",
		Datas.SourceId: 1,
		Datas.AtlasCoords: [
			Vector2i(3, 0),
			Vector2i(3, 2),
			Vector2i(3, 4),
			Vector2i(3, 6),
			Vector2i(3, 8),
			Vector2i(4, 0),
			Vector2i(4, 2),# reference one
			Vector2i(4, 4),
			Vector2i(5, 0),
			Vector2i(5, 2),
			Vector2i(5, 4),
			Vector2i(5, 6),
			Vector2i(5, 8),
		],
	},
	MyMap.Minimap_Cell_Type.Sand: {
		Datas.Name: "Sand",
		Datas.SourceId: 1,
		Datas.AtlasCoords: [
			Vector2i(6, 0),
			Vector2i(6, 2),
			Vector2i(6, 4),
			Vector2i(6, 6),
			Vector2i(6, 8),
			Vector2i(7, 0),
			Vector2i(7, 2),# reference one
			Vector2i(7, 4),
			Vector2i(8, 0),
			Vector2i(8, 2),
			Vector2i(8, 4),
			Vector2i(8, 6),
			Vector2i(8, 8),
		],
	},
	MyMap.Minimap_Cell_Type.Ground: {
		Datas.Name: "Ground",
		Datas.SourceId: 1,
		Datas.AtlasCoords: [
			Vector2i(7, 6)# reference one
		],
	},
	MyMap.Minimap_Cell_Type.Tree: {
		Datas.Name: "Tree",
		Datas.SourceId: 1,
		Datas.AtlasCoords: [Vector2i(0, 1)],
	},
	MyMap.Minimap_Cell_Type.Building: {
		Datas.Name: "Building",
		Datas.SourceId: -1,
		Datas.AtlasCoords: [],
	},
	MyMap.Minimap_Cell_Type.StoneDeposit: {
		Datas.Name: "Stone Deposit",
		Datas.SourceId: -1,
		Datas.AtlasCoords: [],
	},
}

static func get_cell_type_name(cell_type: MyMap.Minimap_Cell_Type) -> String:
	if not datas.has(cell_type):
		push_error("cell_type " + str(cell_type) + " not found")
		return "Unknown"

	return datas[cell_type].get(Datas.Name)

static func get_source_id(cell_type: MyMap.Minimap_Cell_Type) -> int:
	if not datas.has(cell_type):
		push_error("cell_type " + str(cell_type) + " not found")
		return -1

	return datas[cell_type].get(Datas.SourceId)

# FIXME : assign Array[Vector2i] here if possible
static func get_atlas_coords(cell_type: MyMap.Minimap_Cell_Type) -> Array:
	if not datas.has(cell_type):
		push_error("cell_type " + str(cell_type) + " not found")
		return []

	return datas[cell_type].get(Datas.AtlasCoords)
