extends Node2D

var dragging: bool 
var v2_mouse: Vector2i 
var show_chat = false
enum COMMAND {GIFT, SEASON_WINTER,SEASON_SUMMER,SEASON_NORMAL,HELP}
var command_dict = {"gift": COMMAND.GIFT,
					"season-winter":COMMAND.SEASON_WINTER,
					"season-summer":COMMAND.SEASON_SUMMER,
					"season-normal":COMMAND.SEASON_NORMAL,
					"help": COMMAND.HELP}

@onready var control: Control = $Control
@onready var pet: CharacterBody2D = $Pet
@onready var polygon_2d_2: Polygon2D = $Polygon2D
@onready var polygon_2d_3: Polygon2D = $Polygon2D2
@onready var rich_text_label: RichTextLabel = $Control/PanelContainer/VBoxContainer/RichTextLabel
@onready var line_edit: LineEdit = $Control/PanelContainer/VBoxContainer/LineEdit
@onready var ai: Node = $ai


func _ready() -> void:
	control.scale = Vector2.ZERO
	line_edit.text_submitted.connect(on_submitted)
	ai.request_finished.connect(on_request_finished)
	
func _physics_process(_delta) -> void:
	
	if control and show_chat:
		DisplayServer.window_set_mouse_passthrough(polygon_2d_3.polygon)
		
	else:
		DisplayServer.window_set_mouse_passthrough(polygon_2d_2.polygon)
		

func _input(event):
	# 窗口拖拽逻辑
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				dragging = true
				v2_mouse = get_global_mouse_position()
			else:
				dragging = false

	if event is InputEventMouseMotion and dragging:
		DisplayServer.window_set_position(DisplayServer.mouse_get_position() - v2_mouse)

	# 右键点击宠物显示对话框
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			show_chat = !show_chat
			pet.stop = !pet.stop
			
			var tween = create_tween()
			if show_chat:
				tween.tween_property(control, "scale", Vector2.ONE, 0.5)
				await tween.finished
				show_text("你没事干吗(输入#+空格+help显示特殊指令帮助)",1)
			else:
				tween.tween_property(control, "scale", Vector2.ZERO, 0.5)
				await tween.finished

func show_text(text:String, time:float):
	rich_text_label.text = text
	var tw = create_tween()
	tw.tween_property(rich_text_label,"visible_ratio",1,time).from(0)

func check_command(text):
	match command_dict[text]:
		COMMAND.GIFT:
			show_text("谢谢,你怎么知道我最喜欢这个",0.5)
			await get_tree().create_timer(0.5).timeout
		COMMAND.SEASON_WINTER:
			show_text("降温了,要注意给农场的动物们保温",0.5)
			$Pet.season='winter_'
			await get_tree().create_timer(0.5).timeout
		COMMAND.SEASON_SUMMER:
			show_text("你的农场有种辣椒吗*吞口水",0.5)
			$Pet.season='summer_'
			await get_tree().create_timer(0.5).timeout
		COMMAND.SEASON_NORMAL:
			$Pet.season='_'
			await get_tree().create_timer(0.5).timeout
		COMMAND.HELP:
			show_text("# gift: 送礼\n# season-winter: 冬季服饰\n# season-summer: 夏季服饰\n# season-normal: 春秋服饰",0.5)


func on_submitted(new_text:String):
	if new_text.begins_with("#"):
		var command_array = new_text.split(" ")
		if 	command_dict.has(command_array[1]):
			check_command(command_array[1])
	else:
		ai.call_aliyun(new_text)

func on_request_finished(output:String):
	show_text(output,1)
