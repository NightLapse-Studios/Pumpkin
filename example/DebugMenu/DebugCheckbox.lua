local Checkbox = {}

function Checkbox:__ui(G, I, P, Roact)
	I:Stateful(P()
		:Name("DebugCheckbox")
		:Render(function(self)
			local binding = self.props.UseThisBinding
			local callback = self.props.Callback
			
			return I:Frame(P()
				:Size(1, 0, 1, 0)
				:Invisible()
			):Children(
				I:TextButton(P()
					:Size(1, 0, 1, 0)
					:Center()
					:BackgroundColor3(binding:map(function(v)
						return v and Color3.new(0,1,0) or Color3.new(0.16, 0.16, 0.16)
					end))
					:BorderSizePixel(0)
					:Text(" ON ")
					:TextTransparency(binding:map(function(v)
						return v and 0 or 1
					end))
					:TextScaled(true)
					:TextColor3(0,0,0)
					:Font(Enum.Font.Roboto)
					:Activated(function()
						binding.update(not binding:getValue())
						callback(binding:getValue())
					end)
				):Children(
					I:Frame(P()
						:Invisible()
						:Size(1, 2, 1, 2)
						:Center()
						:Border(1, Color3.new(0, 1, 0))
					)
				)
			)
		end)
	)
end


return Checkbox