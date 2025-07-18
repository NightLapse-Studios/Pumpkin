local Pumpkin = require(game.ReplicatedFirst.Pumpkin)
local I, P, Roact = Pumpkin, Pumpkin.P, Pumpkin.Roact

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local IsServer = RunService:IsServer()

local DebugMenuDataTransmitter
local DebugMenuCreationBroadcaster

if IsServer then
	DebugMenuDataTransmitter = Instance.new("RemoteEvent", game.ReplicatedStorage)
	DebugMenuDataTransmitter.Name = "DebugMenuDataTransmitter"
	DebugMenuCreationBroadcaster = Instance.new("RemoteEvent", game.ReplicatedStorage)
	DebugMenuCreationBroadcaster.Name = "DebugMenuCreationBroadcaster"
else
	DebugMenuDataTransmitter = game.ReplicatedStorage:WaitForChild("DebugMenuDataTransmitter")
	DebugMenuCreationBroadcaster = game.ReplicatedStorage:WaitForChild("DebugMenuCreationBroadcaster")
end

local mod = {}

local menus = {}
local plots = {}

-- List of debug values that were created on the server for when the player finally joins
local ServerOptions = { }

local ServerCallbacks = {
	RegisterSlider = {},
	RegisterButton = {},
	RegisterToggle = {},
	RegisterColor = {},
	RegisterText = {},
}

local function handleDebugMenuDataTransmitter(plr, callname, name, ...)
	ServerCallbacks[callname][name](...)
end

local function handleDebugMenuCreationBroadcaster(callName, ...)
	local args = {...}
	
	if callName ~= "Plot" then
		args[#args + 1] = function(...)
			DebugMenuDataTransmitter:FireServer(callName, args[1], ...)
		end
	end
	
	mod[callName](table.unpack(args))
end

if not IsServer then
	DebugMenuCreationBroadcaster.OnClientEvent:Connect(handleDebugMenuCreationBroadcaster)
else
	DebugMenuDataTransmitter.OnServerEvent:Connect(handleDebugMenuDataTransmitter)
end

local function getMenu(menu_name, isPlot)
	menu_name = menu_name or "Default"
	
	local arr = isPlot and plots or menus
	
	if not arr[menu_name] then
		if isPlot then
			arr[menu_name] = I:Binding({})
		else
			arr[menu_name] = {}
		end
	end
	
	return arr[menu_name], menu_name
end

local MaxPointsHash = {}

-- menu_name can be "Screen" to plot directly to the screen (on a ScreenGui with IgnoreInset) instead of the plot.
-- plots are grouped by their color
function mod.Plot(opt_x, y, color: Color3, connect, opt_menu_name)
	if opt_menu_name == "Screen" then
		assert(opt_x)
	end
	
	opt_x = opt_x or tick()
	
	if IsServer then
		DebugMenuCreationBroadcaster:FireAllClients("Plot", opt_x, y, color, connect, opt_menu_name)
		return
	end
	
	local menu, name = getMenu(opt_menu_name, true)
	local points = menu:getValue()
	
	local hex = color:ToHex()
	
	points[hex] = points[hex] or {}
	
	local newPoint = {
		X = opt_x,
		Y = y,
		Connect = connect,
	}
	
	table.insert(points[hex], newPoint)
	
	if MaxPointsHash[name] and #points[hex] > MaxPointsHash[name] then
		table.remove(points[hex], 1)
	end
	
	menu.update(points)
end

function mod.SetPlotMaxPoints(menu_name, maxPoints)
	MaxPointsHash[menu_name] = maxPoints
end

function mod.RegisterSlider(name, val: number, slider_min: number, slider_max: number, step: number, opt_menu_name, callback, is_from_server: boolean?)
	if IsServer then
		ServerOptions[name] = {"RegisterSlider",  val, slider_min, slider_max, step, opt_menu_name, callback }
		ServerCallbacks.RegisterSlider[name] = callback
		DebugMenuCreationBroadcaster:FireAllClients("RegisterSlider", name, val, slider_min, slider_max, step, opt_menu_name)
		return
	elseif is_from_server then
	end
	
	local binding = I:Binding(val)
	
	table.insert(getMenu(opt_menu_name, false), {
		Type = "Slider",
		Name = name,
		Binding = binding,
		Min = slider_min,
		Max = slider_max,
		Increment = step,
		Callback = callback,
	})
	
	return binding
end

function mod.RegisterButton(name, opt_menu_name, callback, is_from_server: boolean?)
	if IsServer then
		ServerOptions[name] = {"RegisterButton", name, opt_menu_name, callback}
		ServerCallbacks.RegisterButton[name] = callback
		DebugMenuCreationBroadcaster:FireAllClients("RegisterButton", name, opt_menu_name)
		return
	elseif is_from_server then
	end
	
	table.insert(getMenu(opt_menu_name, false), {
		Type = "Button",
		Name = name,
		Callback = callback,
	})
end

function mod.RegisterToggle(name, val, opt_menu_name, callback, is_from_server: boolean?)
	if IsServer then
		ServerOptions[name] = {"RegisterToggle", name, val, opt_menu_name, callback}
		ServerCallbacks.RegisterToggle[name] = callback
		DebugMenuCreationBroadcaster:FireAllClients("RegisterToggle", name, val, opt_menu_name)
		return
	elseif is_from_server then
	end
	
	local binding = I:Binding(val)
	
	table.insert(getMenu(opt_menu_name, false), {
		Type = "Toggle",
		Binding = binding,
		Name = name,
		Callback = callback,
	})
	
	return binding
end

function mod.RegisterColor(name, val, opt_menu_name, callback, is_from_server: boolean?)
	if IsServer then
		ServerOptions[name] = {"RegisterColor", name, val, opt_menu_name, callback}
		ServerCallbacks.RegisterColor[name] = callback
		DebugMenuCreationBroadcaster:FireAllClients("RegisterColor", name, val, opt_menu_name)
		return
	elseif is_from_server then
	end
	
	local binding = I:Binding(val)
	
	table.insert(getMenu(opt_menu_name, false), {
		Type = "Color",
		Binding = binding,
		Name = name,
		Callback = callback,
	})
	
	return binding
end

function mod.RegisterText(name, val, opt_menu_name, callback, is_from_server: boolean?)
	if IsServer then
		ServerOptions[name] = {"RegisterText", name, val, opt_menu_name, callback}
		ServerCallbacks.RegisterText[name] = callback
		DebugMenuCreationBroadcaster:FireAllClients("RegisterText", name, val, opt_menu_name)
		return
	elseif is_from_server then
	end
	
	local binding = I:Binding(val)
	
	table.insert(getMenu(opt_menu_name, false), {
		Type = "Text",
		Binding = binding,
		Name = name,
		Callback = callback,
	})
	
	return binding
end

local function init(self)
	self.ColorPickingPosition = I:Binding(UDim2.new(0, 50, 0, 50))
	self.ColorPicking = I:Binding(false)
	self.ColorPickingColor = I:Binding(Color3.new())

	self.Position = I:Binding(UDim2.new(0.5, 0, 0, 50))
	self.Enabled = true

	print("Press B to toggle debug menu example")
	local UserInputService = game:GetService("UserInputService")
	UserInputService.InputBegan:Connect(function(io: InputObject)
		if io.KeyCode == Enum.KeyCode.B then
			self.Enabled = not self.Enabled
			self:setState({})
		end
	end)
end

local function render(self)
	if not self.Enabled then
		return false
	end
	
	local menuElements = {}
	local plotElements = {}
	
	local function createStrip(list, title, element)
		table.insert(list, I:Frame(P()
			:LayoutOrder(#list)
			:Size(0.94, 0, 0, 25)
			:Invisible()
		)(
			I:TextLabel(P()
				:JustifyLeft(0,0)
				:Font("Roboto")
				:Text(title)
				:ScaledTextGroup("DebugColorPickerSliderTitle")
				:TextColor3(1,1,1)
				:Size(0.45, 0, 1, 0)
				:TextXAlignment("Left")
				:TextYAlignment("Center")
				:Invisible()
			),
			
			I:Frame(P()
				:JustifyRight(0,0)
				:Size(0.45, 0, 0.8, 0)
				:Invisible()
			)(
				element
			)
		)) 
	end
	
	for menu_name, elements in menus do
		table.sort(elements, function(a, b)
			return a.Name < b.Name
		end)
		
		local strips = {}
		
		for i, props in elements do
			local ty = props.Type
			if ty == "Slider" then
				createStrip(strips, props.Name, I:DebugSlider(P()
					:Prop("Min", props.Min)
					:Prop("Max", props.Max)
					:Prop("Increment", props.Increment)
					:Prop("UseThisBinding", props.Binding)
					:Prop("Callback", props.Callback)
				))
			elseif ty == "Button" then
				createStrip(strips, props.Name, I:TextButton(P()
					:Text("")
					:Size(0.5, 0, 0.8, 0)
					:AutoButtonColor(true)
					:BackgroundColor3(0.16, 0.16, 0.16)
					:BorderSizePixel(1)
					:BorderColor3(0,0,0)
					:JustifyRight(0,0)
					:Activated(props.Callback)
				))
			elseif ty == "Toggle" then
				createStrip(strips, props.Name, I:DebugCheckbox(P()
					:Prop("UseThisBinding", props.Binding)
					:Prop("Callback", props.Callback)
				))
			elseif ty == "Color" then
				createStrip(strips, props.Name, I:TextButton(P()
					:Text("")
					:Size(0.3, 0, 0.8, 0)
					:AutoButtonColor(true)
					:JustifyRight(0,0)
					:BackgroundColor3(props.Binding)
					:BorderSizePixel(0)
					:Activated(function()
						self.ColorPicking.update(false)
						self.ColorPickingColor.update(props.Binding:getValue())
						self.ColorPicking.update(props)
					end)
				))
			elseif ty == "Text" then
				createStrip(strips, props.Name, I:DebugTextBox(P()
					:Prop("TextBinding", props.Binding)
					:Prop("Callback", props.Callback)
				))
			end
		end
		
		table.insert(menuElements, I:ScrollingFrame(P()
			:Name(menu_name)
			:Invisible()
			:ScrollingDirection(Enum.ScrollingDirection.Y)
			:AutomaticCanvasSize("Y")
			:CanvasSize(0,0,0,0)
			:ScrollBarThickness(5)
			:ClipsDescendants(true)
			:Size(0.34, 0, 1, 0)
		)(
			I:TextLabel(P()
				:LayoutOrder(-1)
				:Text(menu_name)
				:Font("Roboto")
				:ScaledTextGroup("DebugMenuNameTitles")
				:TextColor3(1, 1, 1)
				:Invisible()
				:Size(1, 0, 0, 25)
			),
			
			I:UIListLayout(P()
				:FillDirection("Vertical")
				:SortOrder("LayoutOrder")
				:VerticalAlignment("Top")
				:HorizontalAlignment("Center")
				:Padding(0, 5)
			),
			
			strips
		))
	end
	
	local function createPoint(pos, color)
		return I:Frame(P()
			:Position(pos)
			:Size(0, 3, 0, 3)
			:BackgroundColor3(color)
			:AnchorPoint(0.5, 0.5)
			:BorderSizePixel(0)
		)
	end
	
	local ScreenMenuPlot = nil
	
	for menu_name, pointsBinding in plots do
		if menu_name == "Screen" then
			ScreenMenuPlot = I:Frame(P()
				:Size(1, 0, 1, 0)
				:Invisible()
			)(
				I:DebugGraph(P()
					:Prop("Points", pointsBinding)
					:Prop("CreatePoint", createPoint)
					:Prop("IsScreen", true)
				)
			)
		else
			table.insert(plotElements, I:Frame(P()
				:Name(menu_name)
				:Invisible()
				:Size(1, 0, 0, 150)
			)(
				I:DebugGraph(P()
					:Prop("Points", pointsBinding)
					:Prop("CreatePoint", createPoint)
				)
			))
		end
	end
	
	return I:ScreenGui(P()
		:IgnoreGuiInset(true)
	)(
		I:DebugDraggableWindow(P()
			:Size(0, 500, 0, 300)
			:Prop("PositionBinding", self.Position)
			:Prop("Title", "Debug Menu")
			:Prop("CloseCallback", function()
				self.Enabled = false
				self:setState({})
			end)
			:Prop("Children", {
				I:ScrollingFrame(P()
					:Invisible()
					:ScrollingDirection(Enum.ScrollingDirection.X)
					:AutomaticCanvasSize("X")
					:CanvasSize(0,0,0,0)
					:ScrollBarThickness(5)
					:ClipsDescendants(true)
					:Size(1, 0, 0.5, 0)
				)(
					I:UIListLayout(P()
						:FillDirection("Horizontal")
						:SortOrder("Name")
						:VerticalAlignment("Top")
						:HorizontalAlignment("Left")
					),
				
					menuElements
				),
				
				I:ScrollingFrame(P()
					:Invisible()
					:ScrollingDirection(Enum.ScrollingDirection.Y)
					:AutomaticCanvasSize("Y")
					:CanvasSize(0,0,0,0)
					:ScrollBarThickness(5)
					:ClipsDescendants(true)
					:Size(1, 0, 0.5, 0)
					:Position(0, 0, 0.5, 0)
				)(
					I:UIListLayout(P()
						:FillDirection("Vertical")
						:SortOrder("Name")
						:VerticalAlignment("Top")
					),	
				
					plotElements
				),
			})
		),
		
		I:DebugDraggableWindow(P()
			:Size(0, 150, 0, 300)
			:Visible(self.ColorPicking:map(function(v)
				return v and true or false
			end))
			:Prop("PositionBinding", self.ColorPickingPosition)
			:Prop("Title", self.ColorPicking:map(function(props)
				local title = "Color Picker"
				if props then
					title ..= " | " .. props.Name
				end
				return title
			end))
			:Prop("CloseCallback", function()
				self.ColorPicking.update(false)
			end)
			:Prop("Children", {
				I:DebugColorPicker(P()
					:Color(self.ColorPickingColor)
					:Prop("Callback", function(value)
						local props = self.ColorPicking:getValue()
						if props then
							props.Binding.update(value)
							props.Callback(value)
						end
					end)
				)
			})
		),
		
		ScreenMenuPlot
	)
end



if IsServer then
	game:GetService("Players").PlayerAdded:Connect(function(plr)
		for name, params in ServerOptions do
			DebugMenuCreationBroadcaster:FireClient(plr, table.unpack(params))
		end
	end)
else
	require(script:WaitForChild("DebugSlider"))
	require(script:WaitForChild("DebugTextBox"))
	require(script:WaitForChild("DebugCheckbox"))
	require(script:WaitForChild("DebugColorPicker"))
	require(script:WaitForChild("DebugDraggableWindow"))
	require(script:WaitForChild("DebugGraph"))

	local dbg_container = Instance.new("ScreenGui", Players.LocalPlayer.PlayerGui)
	dbg_container.Name = "DebugMenu"

	I:Stateful(P()
		:Name("DebugMenu")
		:Init(init)
		:Render(render)
	)

	I:Mount(I:DebugMenu(P()), dbg_container)
end

return mod