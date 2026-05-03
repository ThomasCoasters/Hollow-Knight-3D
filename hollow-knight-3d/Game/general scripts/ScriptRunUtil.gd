class_name ScriptRunUtil

## Executes a multiline string as code.
## code_string: is the raw GDscript code you want to run.
## context: The object the code can interact with (referenced as 'ctx' in the string).
## context is an array so if you only have 1 thing you still use ctx[0]
static func execute_multiline_code(code_string: String, context: Array[Object] = [null]) -> void:
	# if the usable characters end us as nothing return
	if code_string.strip_edges() == "":
		return
	
	# create a new GDscript to run the function
	var script = GDScript.new()
	
	# add the code to the script and wrap it inside a function
	# the script extends RefCounted to make memory management easier and faster
	# also add "ctx" (context) so that you can use stuff like ctx[0].score += 10
	# indent the code inside the func because this is still GDscript
	script.source_code = ("
extends RefCounted
\n
\n
func run(ctx: Array[Object]):
\n" + code_string.indent("\t"))
	
	# reload the script to check if there is an error
	var error: int = script.reload()
	
	# if the script contains an error
	if error != OK:
		# say that there is an error and return
		push_error("the script given has an error. Please check the syntax in the inspector.")
		return
	
	# create a new instance to add the script to
	var script_instance = RefCounted.new()
	# add the script to the RefCounted instance
	script_instance.set_script(script)
	
	# Execute the function and add the context object to it
	script_instance.call(&"run", context)
