local Graph = {}

function Graph:__ui(G, I, P, Roact)
	I:Stateful(P()
		:Name("DebugGraph")
		:Init(function(self)
			self.props.Points:subscribe(function(hexHash)
				self:setState({})
			end)
		end)
		:Render(function(self)
			local createPoint = self.props.CreatePoint
			local hexHash = self.props.Points:getValue()
			
			local renderPoints = {}
			local renderLines = {}
			
			if self.props.IsScreen then
				for hex, points in hexHash do
					local color = Color3.fromHex(hex)
					
					local lastPos
					
					for i = 1, #points do
						local point = points[i]
						
						local pos = UDim2.fromOffset(point.X, point.Y)
						table.insert(renderPoints, createPoint(pos, color))
						
						if point.Connect then
							local previousPoint = points[i - 1]
							
							if previousPoint and previousPoint.Connect then
								
								table.insert(renderLines, I:Frame(P()
									:BackgroundColor3(color)
									:BorderSizePixel(0)
									:Line(pos, lastPos, 1)
								))
							end
						end
						
						lastPos = pos
					end
				end
				
				return I:Fragment({I:Fragment(renderPoints), I:Fragment(renderLines)})
			end
			
			local minY, maxY = math.huge, -math.huge
			local minX, maxX = math.huge, -math.huge
			
			for hex, points in hexHash do
				for i, point in points do
					minY, maxY = math.min(point.Y, minY), math.max(point.Y, maxY)
					minX, maxX = math.min(point.X, minX), math.max(point.X, maxX)
				end
			end
			
			if minY == math.huge then
				-- there are no points
				return false
			end
			
			local rangeY = maxY - minY
			local rangeX = maxX - minX
			
			if rangeY == 0 then
				rangeY = 1
			end
			
			if rangeX == 0 then
				rangeX = 1
			end
			
			for hex, points in hexHash do
				local color = Color3.fromHex(hex)
				
				local lastPos
				for i = 1, #points do
					local point = points[i]
					
					local xScale = (point.X - minX) / rangeX
					local yScale = (point.Y - minY) / rangeY
					
					local pos = UDim2.fromScale(xScale, yScale)
					table.insert(renderPoints, createPoint(pos, color))
					
					if point.Connect then
						local previousPoint = points[i - 1]
						
						if previousPoint and previousPoint.Connect then
							
							table.insert(renderLines, I:Frame(P()
								:BackgroundColor3(color)
								:BorderSizePixel(0)
								:Line(pos, lastPos, 1)
							))
						end
					end
					
					lastPos = pos
				end
			end
			
			return I:Fragment({
				I:Fragment(renderLines),
				I:Fragment(renderPoints),
				
				-- y axis top bound
				I:TextLabel(P()
					:Position(0, 0, 0, 0)
					:AnchorPoint(1, 0)
					:Text(maxY)
					:TextSize(14)
					:Font("Roboto")
					:TextColor3(1,1,1)
					:Invisible()
					:TextXAlignment(Enum.TextXAlignment.Right)
					:TextYAlignment(Enum.TextYAlignment.Center)
					:Size(0, 1, 0, 20)
					:ClipsDescendants(false)
				),
				
				-- y axis center bound
				I:TextLabel(P()
					:Position(0, 0, 0.5, 0)
					:AnchorPoint(1, 0.5)
					:Text("(" .. rangeY .. ")")
					:TextSize(14)
					:Font("Roboto")
					:TextColor3(1,1,1)
					:Invisible()
					:TextXAlignment(Enum.TextXAlignment.Right)
					:TextYAlignment(Enum.TextYAlignment.Center)
					:Size(0, 1, 0, 20)
					:ClipsDescendants(false)
				),
				
				-- y axis lower bound
				I:TextLabel(P()
					:Position(0, 0, 1, 0)
					:AnchorPoint(1, 1)
					:Text(minY)
					:TextSize(14)
					:Font("Roboto")
					:TextColor3(1,1,1)
					:Invisible()
					:TextXAlignment(Enum.TextXAlignment.Right)
					:TextYAlignment(Enum.TextYAlignment.Center)
					:Size(0, 1, 0, 20)
					:ClipsDescendants(false)
				),
				
				-- x axis top bound
				I:TextLabel(P()
					:Position(1, 0, 1, 0)
					:AnchorPoint(1, 0)
					:Text(maxX)
					:TextSize(14)
					:Font("Roboto")
					:TextColor3(1,1,1)
					:Invisible()
					:TextXAlignment(Enum.TextXAlignment.Center)
					:TextYAlignment(Enum.TextYAlignment.Center)
					:Size(0, 1, 0, 20)
					:ClipsDescendants(false)
				),
				
				-- x axis center bound
				I:TextLabel(P()
					:Position(0.5, 0, 1, 0)
					:AnchorPoint(0.5, 0)
					:Text(rangeX)
					:TextSize(14)
					:Font("Roboto")
					:TextColor3(1,1,1)
					:Invisible()
					:TextXAlignment(Enum.TextXAlignment.Center)
					:TextYAlignment(Enum.TextYAlignment.Center)
					:Size(0, 1, 0, 20)
					:ClipsDescendants(false)
				),
				
				-- x axis lower bound
				I:TextLabel(P()
					:Position(0, 0, 1, 0)
					:AnchorPoint(0, 0)
					:Text(minX)
					:TextSize(14)
					:Font("Roboto")
					:TextColor3(1,1,1)
					:Invisible()
					:TextXAlignment(Enum.TextXAlignment.Center)
					:TextYAlignment(Enum.TextYAlignment.Center)
					:Size(0, 1, 0, 20)
					:ClipsDescendants(false)
				),
			})
		end)
	)
end


return Graph