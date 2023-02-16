extends Control

onready var chart: LineChart = $LineChart
export var x : Array
export var y : Array
export var title : String
export var x_label : String
export var y_label : String
export var x_scale : float
export var y_scale : float

func _ready():
	# Let's customize the chart properties, which specify how the chart
	# should look, plus some additional elements like labels, the scale, etc...
	var cp: ChartProperties = ChartProperties.new()
	cp.grid = false
	cp.title = title
	cp.x_label = x_label
	cp.x_scale = x_scale
	cp.y_label = y_label
	cp.y_scale = y_scale
	cp.points = false
	cp.line_width = 1.0
	cp.point_radius = 1.5
	cp.use_splines = true
	cp.interactive = true # false by default, it allows the chart to create a tooltip to show point values
	# and interecept clicks on the plot
	
	
	# Plot our data
	chart.plot(x, y, cp)



# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
