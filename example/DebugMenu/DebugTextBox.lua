
--[[
	Use this to request Text Input that is not Chat like. If input text did not pass verification, it is reset to the last valid text.

	Init-- the initial value of the TextBox.

	IsNumber -- will only pass if the input passed the ExpressionParser.
	Increment -- Increments to round the number to. (1, 0.1, 5, etc.)

	-- verifies charcount for strings, rounds the value for numbers.
	Min
	Max

	-- should error if it did not pass the check, otherwise can optionally return a new value to use. Called after preset verifications (min, max)
	Verify

	-- called when the input after the FocusLost Event has passed all the checks.
	Callback
]]

local TextBox = {}

function TextBox:__ui(G, I, P, Roact)
	local ExpressionParser = G.Load("ExpressionParser")
	local Math = G.Load("Math")
	
	local function init(self)
		self.LastText = self.props.TextBinding
	end
	
	local function render(self)
		local props = self.props
		
		local oldLost = props[Roact.Event.FocusLost]
		local ref = props[Roact.Ref]
	
		return I:TextBox(P()
			:BorderSizePixel(1)
			:BorderColor3(0,0,0)
			:MultiLine(false)
			:TextScaled(false)
			:Font("Roboto")
			:Ref(ref)
			:Text(self.LastText:map(function(v)
				if props.Increment then
					return Math.Round(v, props.Increment)
				end
				return v
			end))
			:Size(1, 0, 1, 0)
			:TextTruncate(Enum.TextTruncate.None)
			:ClearTextOnFocus(false)
			:TextWrapped(false)
			:TextEditable(true)
			:TextColor3(1,1,1)
			:BackgroundColor3(0.16,0.16,0.16)
			
			:FocusLost(function(rbx, enterPressed)
				if props.IsNumber then
					-- Expression Parser
					local suc, num = pcall(ExpressionParser.Evaluate, rbx.Text)
	
					if suc and num then
	
						-- Rounding
						if props.Increment then
							num = Math.Round(num, props.Increment)
						end
	
						-- Clamping
						num = math.clamp(num, props.Min or -math.huge, props.Max or math.huge)
	
						-- Custom Verification
						local verify = props.Verify
						local passedCustom = true
						if verify then
							local suc2, new = pcall(verify, num)
							if suc2 then
								if new then
									num = new
								end
							else
								passedCustom = false
							end
						end
	
						-- Callbacks
						if passedCustom then
							if not self.props.DontUpdateBinding then
								self.LastText.update(num)
							end
							props.Callback(num)
	
							if oldLost then
								oldLost(rbx, enterPressed)
							end
	
							return
						end
					end
				else
					local text = rbx.Text
	
					-- Verify Char count
					if (not props.Min) or #text >= props.Min then
						if (not props.Max) or #text <= props.Max then
	
							-- Custom Verification
							local verify = props.Verify
							local passedCustom = true
	
							if verify then
								local suc, new = pcall(verify, text)
								if suc then
									if new then
										text = new
									end
								else
									passedCustom = false
								end
							end
	
							-- callbacks
							if passedCustom then
								if not self.props.DontUpdateBinding then
									self.LastText.update(text)
								end
								props.Callback(text)
	
								if oldLost then
									oldLost(rbx, enterPressed)
								end
	
								return
							end
						end
					end
				end
	
				-- reset text if not returned
				if not self.props.DontUpdateBinding then
					self.LastText.update(self.LastText:getValue())
				end
	
				if oldLost then
					oldLost(rbx, enterPressed)
				end
			end)
		)
	end
	
	I:Stateful(P()
		:Name("DebugTextBox")
		:Init(init)
		:Render(render)
	)
end

return TextBox