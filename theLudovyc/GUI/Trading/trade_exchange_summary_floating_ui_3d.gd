extends Node3D
class_name TradeExchangeSummaryFloatingUI3D

@onready var trade_exchange_summary_floating_ui: TradeExchangeSummaryFloatingUI = $SubViewport/TradeExchangeSummaryFloatingUi
@onready var sprite_3d: Sprite3D = $Sprite3D
@onready var sub_viewport: SubViewport = $SubViewport

func _ready() -> void:
	call_deferred("start_tween")

func start_tween():
	var tween = create_tween()
	tween.tween_property(
		self,
		"position",
		Vector3(0, 3, 0),
		#position + Vector3(0, 1, 0),
		3.0
	).from_current().as_relative()
	#tween.from_current()
	tween.tween_callback(self.queue_free)

func set_content(
	texture: Texture2D,
	text: String
):
	trade_exchange_summary_floating_ui.set_content(
		texture,
		text
	)
	sub_viewport.size = trade_exchange_summary_floating_ui.size
	
