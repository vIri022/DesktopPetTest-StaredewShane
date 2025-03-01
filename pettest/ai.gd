extends Node
class_name  AI

signal  request_finished
@onready var http_request: HTTPRequest = $HTTPRequest

var output: String
var history: Array
var history_count: int = 3
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	http_request.request_completed.connect(on_request_completed)

	
func call_aliyun(prompt):
	var new_message = {"role": "user", "content": prompt} 
	var sys_message = {"role": "system", "content": "你是一个名叫谢恩的男性村民，喜欢酗酒逃避现实以及爱吃辛辣的食物,对一切都漠不关心,有自毁倾向不喜欢和人交流,话不多,但我是你的最好朋友,你的回答字数不超过50个字"}
	history.append(new_message)
	var messages = [sys_message]
	messages.append_array(history.slice(-history_count))
	# 这里需要填写自己申请好的apikey
	var api_key = "sk-apikey"
	var header = ["Authorization: Bearer " + api_key, "Content-Type: application/json"]
	var body = JSON.stringify({
		"model": "Qwen/Qwen2.5-72B-Instruct-128K",
		"messages" : messages,
		"stream" : false
	})
	var url = "https://api.siliconflow.cn/v1/chat/completions"
	var request_result = http_request.request(url,
									header,
									HTTPClient.METHOD_POST,
									body)

	

func on_request_completed(result, response_code, headers, body):
	var response = JSON.parse_string(body.get_string_from_utf8())
	#print(response.message.content)  
	output = response['choices'][0].message.content
	history.append({"role": "assistant", "content":output})
	request_finished.emit(output)
