extends Node

################################################################################
# This project works with EPS32: the C++ BLE library is not fully implemented	#
# so there is a lot of missing things like: unscuscribe impossible in macOS		#
# discover services and characteristics not implemented						#
################################################################################

# Reference to child nodes
onready var _terminal: RichTextLabel = $Terminal

onready var _esp32: NativeBLE = $ESP32

onready var _connect: Button = $Controls/Connect

onready var _service: LineEdit = $Controls/Connection/Service
onready var _characteristic: LineEdit = $Controls/Connection/Characteristic

onready var _notify: Button = $Controls/Interactions/Notify
onready var _read: Button = $Controls/Interactions/Read
onready var _send: Button = $Controls/Interactions/Send
onready var _data: LineEdit = $Controls/Interactions/Data

## Write new line in the terminal
func _writeln_in_terminal(text: String) -> void:
	_terminal.bbcode_text = _terminal.bbcode_text + '\n' + text

## Disconnect later (after timeout)
func _disconnect_later(timeout: float) -> void:
	var t = Timer.new()
	t.set_wait_time(timeout)
	t.set_one_shot(true)
	self.add_child(t)
	t.start()
	yield(t, "timeout")
	_esp32.disconnect()

## Disconnect at the end
func _exit_tree() -> void:
	_esp32.dispose()
	if _esp32.is_connected():
		_esp32.disconnect()

## On connect button pressed
func _on_Connect_pressed() -> void:
	if _esp32.is_connected():
		_esp32.disconnect()
	else:
		_esp32.connect()

## On notify button pressed
func _on_Notify_toggled(button_pressed: bool) -> void:
	if button_pressed:
		_esp32.notify(_service.text, _characteristic.text)
		_read.disabled = true
		_send.disabled = true
		_service.editable = false
		_characteristic.editable = false
	else:
		_esp32.unsubscribe(_service.text, _characteristic.text) #Not implemented...
		_writeln_in_terminal("[color=#FF0000]Unsubscribe not implemented[/color]")
		_read.disabled = false
		_send.disabled = false
		_service.editable = true
		_characteristic.editable = true
		_disconnect_later(0.1)

## On read button pressed
func _on_Read_pressed() -> void:
	_esp32.read(_service.text, _characteristic.text)

## On send button pressed
func _on_Send_pressed() -> void:
	_esp32.write_request(_service.text, _characteristic.text, _data.text)

## On device connected
func _on_ESP32_device_connected(__: Object) -> void:
	_writeln_in_terminal("[color=#00FF00]Connected![/color]")
	_connect.text = "Disconnect"
	_notify.disabled = false
	_read.disabled = false
	_send.disabled = false

## On device disconnected
func _on_ESP32_device_disconnected(__: Object, message: String) -> void:
	_writeln_in_terminal("[color=#FF0000]Disconnected: " + message + "[/color]")
	_connect.text = "Connect"
	_notify.disabled = true
	_read.disabled = true
	_send.disabled = true

## Notify callback
func _on_ESP32_notified(__: Object, ___: String, ____: String, data: String) -> void:
	_writeln_in_terminal("[color=#FF00FF]Notify[/color]: " + data)

## Read callback
func _on_ESP32_data_received(__: Object, ___: String, ____: String, data: String) -> void:
	_writeln_in_terminal("[color=#FF00FF]Read[/color]: " + data)
