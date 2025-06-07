
local Pumpkin = require(game.ReplicatedFirst.Pumpkin)
local I, P = Pumpkin, Pumpkin.P

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Slider = {}

local meta = {__mode = "v"}
local grabbed = setmetatable({}, meta)

local function round(num, Custom)
	Custom = Custom or 1
	
	local mult = 1 / Custom
    return math.floor(num * mult + 0.5) / mult
end

local function map(value, oldMin, oldMax, newMin, newMax)
    local oldSpan = oldMax - oldMin
    local newSpan = newMax - newMin

    local valueScaled = (value - oldMin) / (oldSpan)

    return newMin + (valueScaled * newSpan)
end

local function percent(num, min, max)
	return (num - min) / (max - min)
end

local function constrainValue(v, min, max, inc)
	local n = round(v, inc)
	return math.clamp(n, min, max)
end

local function calcPos(v, min, max)
	return percent(v, min, max)
end

local function init_Slider(self)
	self.Ref = I:CreateRef()
end

local function render_Slider(self)
	local min = self.props.Min
	local max = self.props.Max
	local increment = self.props.Increment
	local binding = self.props.UseThisBinding
	local callback = self.props.Callback
	
	return I:Frame(P()
		:Size(1, 0, 1, 0)
		:Invisible()
	)(
		I:ImageButton(P()
			:Size(0.7, 0, 0.5, 0)
			:BorderSizePixel(1)
			:BorderColor3(0,0,0)
			:BackgroundColor3(self.props.BackgroundColor3 or Color3.new(0.16, 0.16, 0.16))
			:JustifyLeft(0,0)
			:Ref(self.Ref)
			:MouseButton1Down(function()
				grabbed[1] = self
			end)
		)(
			I:ImageButton(P()
				:Size(1, 0, 2, 0)
				:AspectRatioProp(0.3)
				:BorderSizePixel(0)
				:BackgroundColor3(0, 1, 0)
				:AnchorPoint(0.5, 0.5)
				:Position(binding:map(function(v)
					return UDim2.new(calcPos(v, min, max), 0, 0.5, 0)
				end))
				:MouseButton1Down(function()
					grabbed[1] = self
				end)
			),
			
			self.props.Children
		),
		
		I:Frame(P()
			:Position(1, 5, 0.5, 0)
			:AnchorPoint(1, 0.5)
			:Size(0.28, 0, 1, 0)
			:Invisible()
		)(
			I:DebugTextBox(P()
				:Prop("IsNumber", true)
				:Prop("Increment", increment)
				:Prop("Min", min)
				:Prop("Max", max)
				:Prop("TextBinding", binding)
				:Prop("DontUpdateBinding", self.props.DontUpdateBinding)
				:Prop("Callback", function(value)
					callback(value, true)
				end)
			)
		)
	)
end

I:Stateful(P()
	:Name("DebugSlider")
	:Init(init_Slider)
	:Render(render_Slider)
)

if RunService:IsClient() then
	local function do_callbacks(is_from_mouse_release)
		local self = grabbed[1]

		if self then
			local gui = self.Ref:getValue()
			if gui then
				local x = UserInputService:GetMouseLocation().X

				local minGui = gui.AbsolutePosition.X
				local maxGui = minGui + gui.AbsoluteSize.X

				local newValue = map(x, minGui, maxGui, self.props.Min, self.props.Max)

				local finalValue = constrainValue(newValue, self.props.Min, self.props.Max, self.props.Increment)
				if not self.props.DontUpdateBinding then
					self.props.UseThisBinding.update(finalValue)
				end
				self.props.Callback(finalValue, is_from_mouse_release)
			end
		end
	end

	local function HandleRelease()
		do_callbacks(true)
		table.clear(grabbed)
	end

	local function HandleMouseMove()
		do_callbacks(false)
	end

	RunService.RenderStepped:Connect(HandleMouseMove)
	UserInputService.InputEnded:Connect(function(obj)
		if obj.UserInputType == Enum.UserInputType.MouseButton1 then
			HandleRelease()
		end
	end)
end

return Slider