extends Node2D
class_name TradeExchangeSummaryFloatingUI2D

@onready var trade_exchange_summary_floating_ui: TradeExchangeSummaryFloatingUI = $TradeExchangeSummaryFloatingUi

func _ready() -> void:
	print("TradeExchangeSummaryFloatingUI2D:_ready")
	call_deferred("start_tween")

func start_tween():
	print("start_tween")
	var tween = create_tween()
	tween.tween_property(
		self,
		"position",
		Vector2(0, -75),
		#position + Vector3(0, 1, 0),
		2.0
	).from_current().as_relative()
	# Info: Can't really use parallel here I think
	#tween.parallel().tween_property(
		#self,
		#"scale",
		#Vector2(-0.3, -0.3),
		#2.0
	#).from_current().as_relative().set_ease(Tween.EASE_IN)
	var tween2 = create_tween()
	tween2.tween_property(
		self,
		"scale",
		Vector2(-0.5, -0.5),
		0.5
	).from_current().as_relative().set_delay(1.5)#.set_ease(Tween.EASE_IN)
	tween.tween_callback(self.queue_free)

func set_content(
	texture: Texture2D,
	text: String
):
	trade_exchange_summary_floating_ui.set_content(
		texture,
		text
	)
	
