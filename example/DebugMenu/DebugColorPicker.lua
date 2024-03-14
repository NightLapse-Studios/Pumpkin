local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ColorPicker = {}

local ColorWheel = "rbxassetid://7151805781"
local CircleRing = "rbxassetid://7151851820"

local Math

local grabbed = nil

local function constrainValue(v, min, max, inc)
	local n = Math.Round(v, inc)
	return math.clamp(n, min, max)
end

function ColorPicker:__ui(G, I, P, Roact)
	Math = G.Load("Math")
	local Vectors = G.Load("Vectors")
	
	local function init(self)
		self.WheelRef = I:CreateRef()
		self.LastNon0Hue = self.props.Color:getValue():ToHSV()
		self.UpdateColor = function(color)
			self.props.Color.update(color)
			self.props.Callback(color)
		end
		
		self.ColorComponents = self.props.Color:map(function(v: Color3)
			-- n is for normalized
			
			local nh, ns, nv = v:ToHSV()
			
			if nh ~= 0 then
				self.LastNon0Hue = nh
			end
			
			local nr, ng, nb = v.R, v.G, v.B
			
			local hex = v:ToHex()
			
			return {nh, ns, nv,  nr, ng, nb,  hex}
		end)
	end
	
	local function render(self)
		local color = self.props.Color
		local updateColor = self.UpdateColor
		local colorComponents = self.ColorComponents
		
		local List = {}
		
		local function createStrip(title, element)
			table.insert(List, I:Frame(P()
				:LayoutOrder(#List)
				:Size(1, 0, 0.12, 0)
				:Invisible()
			):Children(
				I:TextLabel(P()
					:JustifyLeft(0,0)
					:Font("Roboto")
					:Text(title)
					:ScaledTextSize("DebugColorPickerSliderTitle")
					:TextColor3(1,1,1)
					:Size(0.1, 0, 1, 0)
					:TextXAlignment("Center")
					:TextYAlignment("Center")
					:Invisible()
				),
				
				I:Frame(P()
					:JustifyRight(0,0)
					:Size(0.85, 0, 1, 0)
					:Invisible()
				):Children(
					element
				)
			)) 
		end
		
		local function createSlider(title, componentIndex, callback)
			createStrip(title, I:DebugSlider(P()
				:Prop("Min", 0)
				:Prop("Max", 1)
				:Prop("Increment", 0.001)
				:Prop("UseThisBinding", colorComponents:map(function(comps)
					return comps[componentIndex]
				end))
				:Prop("DontUpdateBinding", true)
				:Prop("Callback", callback)
				
				:BackgroundColor3(1, 1, 1)
				
				:Prop("Children", {
					I:UIGradient(P()
						:Color(colorComponents:map(function(comps)
							local C1, C2
							
							if componentIndex == 1 then
								local seq = {}
								local n = 19-- 20 keypoint limit
								for i = 0, n do
									table.insert(seq, ColorSequenceKeypoint.new(i/n, Color3.fromHSV(i/n, comps[2], comps[3])))
								end
								return ColorSequence.new(seq)
							elseif componentIndex == 2 then
								C1 = Color3.fromHSV(comps[1], 0, comps[3])
								C2 = Color3.fromHSV(comps[1], 1, comps[3])
							elseif componentIndex == 3 then
								C1 = Color3.fromHSV(comps[1], comps[2], 0)
								C2 = Color3.fromHSV(comps[1], comps[2], 1)
							elseif componentIndex == 4 then
								C1 = Color3.new(0, comps[5], comps[6])
								C2 = Color3.new(1, comps[5], comps[6])
							elseif componentIndex == 5 then
								C1 = Color3.new(comps[4], 0, comps[6])
								C2 = Color3.new(comps[4], 1, comps[6])
							elseif componentIndex == 6 then
								C1 = Color3.new(comps[4], comps[5], 0)
								C2 = Color3.new(comps[4], comps[5], 1)
							end
							
							return ColorSequence.new(C1, C2)
						end))
					)
				})
			))
		end
		
		createSlider("H", 1, function(updatedValue)
			local nh, ns, nv,  nr, ng, nb,  hex = table.unpack(colorComponents:getValue())
			local newColor = Color3.fromHSV(updatedValue, ns, nv)
			self.LastNon0Hue = updatedValue
			updateColor(newColor)
		end)
		
		createSlider("S", 2, function(updatedValue)
			local nh, ns, nv,  nr, ng, nb,  hex = table.unpack(colorComponents:getValue())
			updateColor(Color3.fromHSV(self.LastNon0Hue, updatedValue, nv))
		end)
		
		createSlider("V", 3, function(updatedValue)
			local nh, ns, nv,  nr, ng, nb,  hex = table.unpack(colorComponents:getValue())
			updateColor(Color3.fromHSV(self.LastNon0Hue, ns, updatedValue))
		end)
		
		createSlider("R", 4, function(updatedValue)
			local nh, ns, nv,  nr, ng, nb,  hex = table.unpack(colorComponents:getValue())
			local newColor = Color3.new(updatedValue, ng, nb)
			self.LastNon0Hue = newColor:ToHSV()
			updateColor(newColor)
		end)
		
		createSlider("G", 5, function(updatedValue)
			local nh, ns, nv,  nr, ng, nb,  hex = table.unpack(colorComponents:getValue())
			local newColor = Color3.new(nr, updatedValue, nb)
			self.LastNon0Hue = newColor:ToHSV()
			updateColor(newColor)
		end)
		
		createSlider("B", 6, function(updatedValue)
			local nh, ns, nv,  nr, ng, nb,  hex = table.unpack(colorComponents:getValue())
			local newColor = Color3.new(nr, ng, updatedValue)
			self.LastNon0Hue = newColor:ToHSV()
			updateColor(newColor)
		end)
		
		createStrip("HEX", I:DebugTextBox(P()
			:Prop("TextBinding", colorComponents:map(function(comps)
				return comps[#comps]
			end))
			:Prop("Min", 6)
			:Prop("Max", 6)
			:Prop("DontUpdateBinding", true)
			:Prop("Verify", function(value)
				local suc, err = pcall(function()
					Color3.fromHex(value)
				end)
				
				return suc
			end)
			:Prop("Callback", function(value)
				local newColor = Color3.fromHex(value)
				updateColor(newColor)
			end)
		))
		
		return I:Frame(P()
			:Size(1, 0, 1, 0)
			:Invisible()
			:AspectRatioProp(0.5)
		):Children(
			I:ImageButton(P()
				:AutoButtonColor(false)
				:AspectRatioProp(1)
				:Size(0.9, 0, 1, 0)
				:JustifyTop(0.03, 0)
				:Image(ColorWheel)
				:Invisible()
				:Ref(self.WheelRef)
				
				:ImageColor3(colorComponents:map(function(comps)
					return Color3.new(comps[3], comps[3], comps[3])
				end))
				
				:MouseButton1Down(function()
					grabbed = self
				end)
			):Children(
				I:ImageButton(P()
					:AutoButtonColor(false)
					:Size(0, 20, 0, 20)
					:Image(CircleRing)
					:Invisible()
					
					:AnchorPoint(0.5, 0.5)
					:Position(colorComponents:map(function(comps)
						local x, y = Vectors.XYOnCircle(0,0, comps[2]/2, math.pi/2 - self.LastNon0Hue * math.pi * 2)

						return UDim2.new(0.5 + x, 0, 0.5 - y, 0)
					end))
					
					:MouseButton1Down(function()
						grabbed = self
					end)
				)
			),
			
			I:Frame(P()
				:Position(0, 0, 0.5, 0)
				:Size(0.9, 0, 0.45, 0)
				:Invisible()
			):Children(
				I:UIListLayout(P()
					:Padding(0.04, 0)
					:FillDirection("Vertical")
					:HorizontalAlignment("Center")
					:SortOrder("LayoutOrder")
					:VerticalAlignment("Top")
				),
				
				I:Fragment(List)
			)
		)
	end
	
	I:Stateful(P()
		:Name("DebugColorPicker")
		:Init(init)
		:Render(render)
	)
	
	RunService.RenderStepped:Connect(function()
		if grabbed then
			if not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
				grabbed = nil
			else
				local wheel = grabbed.WheelRef:getValue()
				if not wheel then
					grabbed = nil
				else
					local center = wheel.AbsolutePosition + wheel.AbsoluteSize/2
					local mousePosition = UserInputService:GetMouseLocation() - GuiService:GetGuiInset()
					
					local delta = center - mousePosition
					
					local s = math.min(delta.Magnitude / wheel.AbsoluteSize.X * 2, 1)
					local angle = math.atan2(-delta.X, delta.Y)
					local h = angle % (math.pi * 2) / (math.pi * 2)

					local _, _, v = grabbed.props.Color:getValue():ToHSV()
					
					h, s, v = constrainValue(h, 0, 1, 0.001), constrainValue(s, 0, 1, 0.001), constrainValue(v, 0, 1, 0.001)
					
					local color = Color3.fromHSV(h, s, v)
					
					grabbed.UpdateColor(color)
				end
			end
		end
	end)
end

return ColorPicker