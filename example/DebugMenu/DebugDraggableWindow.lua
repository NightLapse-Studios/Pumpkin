local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local DraggableWindow = {}

local grab = nil

function DraggableWindow:__ui(G, I, P, Roact)
	I:Stateful(P()
		:Name("DebugDraggableWindow")
		:Init(function(self)
			
		end)
		:Render(function(self)
			return I:Frame(P()
				:Size(self.props.Size)
				:BorderSizePixel(1)
				:BorderColor3(0,0,0)
				:BackgroundColor3(0.08, 0.08, 0.08)
				:Position(self.props.PositionBinding)
				:Visible(self.props.Visible)
			):Children(
				I:TextButton(P()
					:Size(1, 0, 0, 25)
					:Text(self.props.Title)
					:Font("Roboto")
					:AnchorPoint(0, 1)
					:Position(0,0,0,-1)
					:BackgroundColor3(0,0,0)
					:BorderSizePixel(1)
					:BorderColor3(0,0,0)
					:TextColor3(1,1,1)
					:TextXAlignment("Left")
					:TextYAlignment("Center")
					
					:MouseButton1Down(function(rbx)
						local mouseLocation = UserInputService:GetMouseLocation()
						local grabOffset = rbx.AbsolutePosition - mouseLocation
						
						grab = {
							Binding = self.props.PositionBinding,
							Offset = grabOffset,
						}
					end)
				):Children(
					I:ImageButton(P()
						:JustifyRight(0, 5)
						:BackgroundColor3(1,0,0)
						:Size(0, 15, 0, 15)
						:BorderSizePixel(1)
						:BorderColor3(0,0,0)
						
						:Activated(function()
							self.props.CloseCallback()
						end)
					),
					
					I:UIPadding(P()
						:PaddingLeft(0, 5)
					)
				),
				
				I:Frame(P()
					:Size(1, 0, 1, 0)
					:Invisible()
				):Children(
					I:Fragment(self.props.Children)
				)
			)
		end)
	)
	
	RunService.RenderStepped:Connect(function()
		if grab then
			if not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
				grab = nil
			else
				local pos = UserInputService:GetMouseLocation() + grab.Offset + GuiService:GetGuiInset()
				grab.Binding.update(UDim2.new(0, pos.X, 0, pos.Y + 26))-- +26 is the height of the top grab bar + 1
			end
		end
	end)
end


return DraggableWindow