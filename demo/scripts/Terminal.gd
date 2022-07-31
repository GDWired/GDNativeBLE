# Fake terminal
# 
# There is two possibilities:
# 	- Write line: write data and put '\n'
#	- Write: write without returns '\n'
class_name Terminal
extends RichTextLabel


## Write line in the terminal
func writeln(text: String, color: Color = Color.white) -> void:
	write(text + '\n', color)


## Write in the terminal (because print is already used)
func write(text: String, color: Color = Color.white) -> void:
	# warning-ignore:return_value_discarded 
	# Always true (backwards compatibility)
	append_bbcode("[color=#" + color.to_html(false) + "]" + text + "[/color]")

