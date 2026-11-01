extends RefCounted
class_name OrientedRect2

# Normal Rect2 is not rotated

var position: Vector2
var size: Vector2
var rotation_degrees: float
var points: PackedVector2Array

func _init(
	center_: Vector2,
	size_: Vector2,
	rotation_degrees_: float
) -> void:
	position = center_
	size = size_
	rotation_degrees = rotation_degrees_
	
	points = _get_rotated_rect_corners(
		position,
		size,
		rotation_degrees
	)

func _get_rotated_rect_corners(
	center_: Vector2,
	size_: Vector2,
	rotation_degrees_: float
) -> PackedVector2Array:
	# Rect2 with size
	var rect = Rect2(
		# this is effectively centering it
		-size_ * 0.5,
		size_
	)
	
	# Transform2D at the specified position with the rotation
	var transform_: Transform2D = Transform2D(
		deg_to_rad(rotation_degrees_),
		center_
	)

	# Proper rotation
	var corners = PackedVector2Array([
		# top left
		transform_ * rect.position,
		# top right
		transform_ * (rect.position + Vector2(size.x, 0)),
		# bottom right
		transform_ * (rect.position + size),
		# bottom left
		transform_ * (rect.position + Vector2(0, size.y))
	])

	return corners

func is_point_inside(point: Vector2) -> bool:
	return Geometry2D.is_point_in_polygon(
		point,
		points
	)

func _debug_points(
	size_: float,
	duration: float
):
	var arr = []
	for point in points:
		arr.push_back(
			Vector3(
				point.x,
				5,
				point.y
			)
		)
	var points2: PackedVector3Array = PackedVector3Array(arr)
	DebugDraw3D.draw_points(
		points2, DebugDraw3D.POINT_TYPE_SPHERE, size_, Color.RED, duration
	)
