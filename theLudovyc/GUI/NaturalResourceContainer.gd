extends VBoxContainer

@onready var name_label = $HBoxContainer/NameLabel
@onready var description_label: RichTextLabel = $DescriptionLabel

@onready var event_bus: EventBus

func _ready():
	event_bus = get_tree().current_scene.get_node_or_null("EventBus")

func update_infos(natural_resource: NaturalResource):
	name_label.text = NaturalResources.get_natural_resource_name(natural_resource.natural_resource_id)
	description_label.text = NaturalResources.get_natural_resource_description(natural_resource.natural_resource_id)
