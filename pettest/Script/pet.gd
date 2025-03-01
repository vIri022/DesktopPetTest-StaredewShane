extends CharacterBody2D

@export var move_speed: float = 120 
@export var drag_speed: float = 0.18 

var target_window_pos: Vector2 = Vector2.ZERO
var is_dragging: bool = false
var drag_offset: Vector2
var is_moving: bool = false
var move_timer: Timer
var stop = false
var season:String = '_'

@onready var idle_timer = Timer.new()

func _ready():
	# 初始化节点属性
	$Body.play(season+"idle")
	
	# 设置计时器系统
	move_timer = Timer.new()
	move_timer.wait_time = randf_range(3, 6)
	move_timer.autostart = true
	move_timer.timeout.connect(_on_move_timeout)
	add_child(move_timer)
	
	idle_timer.wait_time = 0.5
	idle_timer.timeout.connect(_on_idle_timeout)
	add_child(idle_timer)

func _process(delta: float):
	if is_dragging:
		_handle_dragging(delta)
	elif is_moving:
		_handle_auto_move(delta)
	else:
		if $Body.animation != season+"idle":
			$Body.play(season+"idle")

func _handle_dragging(delta: float):
	# 获取当前屏幕信息
	var screen_index = DisplayServer.window_get_current_screen()
	var screen_size = Vector2(DisplayServer.screen_get_size(screen_index))
	var screen_pos = Vector2(DisplayServer.screen_get_position(screen_index))
	
	# 计算目标位置
	var mouse_pos = Vector2(DisplayServer.mouse_get_position())
	var target_pos = mouse_pos - drag_offset
	
	# 应用边界限制
	target_pos = Vector2(
		clamp(target_pos.x, screen_pos.x, screen_pos.x + screen_size.x ),
		clamp(target_pos.y, screen_pos.y, screen_pos.y + screen_size.y )
	)
	
	# 平滑插值移动
	var current_pos = Vector2(DisplayServer.window_get_position())
	var new_pos = current_pos.lerp(target_pos, drag_speed * delta * 60)
	DisplayServer.window_set_position(Vector2i(new_pos))
	
	if $Body.animation != season+"jump":
		$Body.play(season+"jump")

func _handle_auto_move(delta: float):
	if stop:
		$Body.play(season+"idle")
		return
	
	var current_pos = Vector2(DisplayServer.window_get_position())
	var direction = target_window_pos - current_pos
	
	if direction.length() < 5:
		is_moving = false
		$Body.play(season+"idle")
		return
	# 动态速度调整
	var speed_factor = clamp(direction.length() / 300.0, 0.6, 1.2)
	_update_animation(direction.normalized())
	
	# 平滑移动
	var new_pos = current_pos.move_toward(target_window_pos, max(move_speed * delta * speed_factor,1.0 ))
	DisplayServer.window_set_position(Vector2i(new_pos.round()))

func _input(event: InputEvent):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			# 转换坐标系
			var window_pos = Vector2(DisplayServer.window_get_position())
			var mouse_global = Vector2(event.global_position) + window_pos
			var collider_global = Vector2($CollisionShape2D.global_position) + window_pos
			
			if _is_click_in_shape(mouse_global, collider_global):
				is_dragging = true
				is_moving = false
				move_timer.stop()
				drag_offset = mouse_global - window_pos
				$Body.play(season+"jump")
		else:
			if is_dragging:
				is_dragging = false
				$Body.play(season+"idle")
				idle_timer.start()
				move_timer.start()

func _on_move_timeout():
	if !is_dragging and !stop:
		target_window_pos = _generate_valid_position()
		is_moving = true
		move_timer.wait_time = randf_range(2, 6)

func _on_idle_timeout():
	idle_timer.stop()
	if !is_moving and !is_dragging:
		$Body.play(season+"idle")

# 辅助方法
func _generate_valid_position() -> Vector2:
	var screen_index = DisplayServer.window_get_current_screen()
	var screen_size = Vector2(DisplayServer.screen_get_size(screen_index))
	var screen_pos = Vector2(DisplayServer.screen_get_position(screen_index))
	var window_size = DisplayServer.window_get_size()
	
	return Vector2(
		randf_range(screen_pos.x , screen_pos.x + screen_size.x - window_size.x ),
		randf_range(screen_pos.y , screen_pos.y + screen_size.y - window_size.y)
	)

func _is_click_in_shape(mouse_pos: Vector2, shape_pos: Vector2) -> bool:
	var rect_shape = $CollisionShape2D.shape as RectangleShape2D
	if rect_shape:
		var extents = rect_shape.size * $CollisionShape2D.scale / 2
		var area_rect = Rect2(
			shape_pos - extents,
			extents * 2
		)
		return area_rect.has_point(mouse_pos)
	return false

func _update_animation(direction: Vector2):
	var anim_suffix = "down"
	if abs(direction.x) > abs(direction.y):
		anim_suffix = "right" if direction.x > 0 else "left"
	else:
		anim_suffix = "down" if direction.y > 0 else "up"
	$Body.play(season+"walk_" + anim_suffix)
