extends Object
class_name NaturalResources

enum Ids { 
	ClayDeposit,
	StoneDeposit,
}
enum Datas {
	Name,
	Description,
	TileType,
}

const datas = {
	Ids.ClayDeposit:
	{
		Datas.Name: &"Clay deposit",
		Datas.Description: "You can build a clay pit on it to produce clay",
		Datas.TileType: MyMap.Minimap_Cell_Type.ClayDeposit,
	},
	Ids.StoneDeposit:
	{
		Datas.Name: &"Stone deposit",
		Datas.Description: "You can build a stone pit on it to produce stones",
		Datas.TileType: MyMap.Minimap_Cell_Type.StoneDeposit,
	},
}

static func get_natural_resource_name(natural_resource_id: NaturalResources.Ids) -> StringName:
	if not datas.has(natural_resource_id):
		push_warning('natural resource of id "%d" was not found ' % natural_resource_id)
		return StringName()
	return datas[natural_resource_id][Datas.Name]

static func get_natural_resource_description(
	natural_resource_id: NaturalResources.Ids
) -> StringName:
	if not datas.has(natural_resource_id):
		push_warning('natural resource of id "%d" was not found ' % natural_resource_id)
		return StringName()
	return datas[natural_resource_id][Datas.Description]

static func get_natural_resource_tile_type(
	natural_resource_id: NaturalResources.Ids
) -> MyMap.Minimap_Cell_Type:
	if not datas.has(natural_resource_id):
		push_warning('natural resource of id "%d" was not found ' % natural_resource_id)
		return -1
	return datas[natural_resource_id].get(Datas.TileType, -1)
