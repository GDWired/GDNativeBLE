# 
# 
# This project works with EPS32: the C++ BLE library is not fully implemented
# so there is a lot of missing things like: unscuscribe impossible in macOS
# discover services and characteristics not implemented

extends Node

# Reference to child nodes
onready var _terminal: RichTextLabel = $Terminal

onready var _esp32: NativeBLE = $ESP32

onready var _device_index: SpinBox = $Controls/ConnectScan/DeviceIndex
onready var _connect: Button = $Controls/ConnectScan/Connect
onready var _scan: Button = $Controls/ConnectScan/Scan

onready var _service: LineEdit = $Controls/Connection/Service
onready var _characteristic: LineEdit = $Controls/Connection/Characteristic

onready var _notify: Button = $Controls/Interactions/Notify
onready var _read: Button = $Controls/Interactions/Read
onready var _send: Button = $Controls/Interactions/Send
onready var _data: LineEdit = $Controls/Interactions/Data

# Private
var _scan_thread: Thread = null # One million dollars error


## Write new line in the terminal
func _writeln_in_terminal(text: String) -> void:
	_terminal.bbcode_text = _terminal.bbcode_text + '\n' + text


## Disconnect at the end
func _exit_tree() -> void:
	_esp32.dispose()
	if _esp32.is_connected():
		_esp32.disconnect()
	if _scan_thread != null:
		_scan_thread.wait_to_finish()


## On connect button pressed
func _on_Connect_pressed() -> void:	
	if _esp32.is_connected():
		_esp32.disconnect()
	else:
		# If the spinbox value is 0 use the default address
		_esp32.connect(int(_device_index.value))


## On scan button pressed
func _on_Scan_pressed() -> void:
	if _scan_thread == null or !_scan_thread.is_alive():
		if _scan_thread != null:
			_scan_thread.wait_to_finish()
		_scan_thread = Thread.new()
		var error := _scan_thread.start(_esp32, "scan_timeout", 5000)
		if error != OK:
			_writeln_in_terminal("[color=#FF0000]Something wrong happen: " + str(error) + "[/color]")
	else:
		_writeln_in_terminal("[color=#FF0000]Scan already started[/color]")


## On notify button pressed
func _on_Notify_toggled(button_pressed: bool) -> void:
	if button_pressed:
		_esp32.notify(_service.text, _characteristic.text)
		_read.disabled = true
		_send.disabled = true
		_service.editable = false
		_characteristic.editable = false
	else:
		_writeln_in_terminal("[color=#FF0000]Unsubscribe not implemented[/color]")
		_read.disabled = false
		_send.disabled = false
		_service.editable = true
		_characteristic.editable = true
		_esp32.disconnect()


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


## Scan start callback
func _on_ESP32_scan_started(__: Object) -> void:
	_writeln_in_terminal("[color=#FF00FF]Scan started for 5sec ...[/color]")


## Scan stop callback
func _on_ESP32_scan_stopped(__: Object) -> void:
	_writeln_in_terminal("[color=#FF00FF]...scan finished[/color]")


## Scan device found callback
func _on_ESP32_device_found(__: Object, name: String, address: String, discovered_count: int) -> void:
	_writeln_in_terminal("[color=#FF00FF]Found[/color]: " + str(discovered_count) + " " + name + " ([color=#00FF00]" + address + "[/color])")
