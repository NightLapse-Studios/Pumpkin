--[[
	Accepts a binding or value to assign to the host instance's attributes at the key
	Updating the binding will update the attribute's value
]]

local Type = require(script.Parent.Parent["Type.roblox"])

local Attribute = {}

local AttributeMetatable = {
	__tostring = function(self)
		return ("RoactHostAttribute(%s)"):format(self.name)
	end,
}

setmetatable(Attribute, {
	__index = function(self, name)
		local AttributeListener = {
			[Type] = Type.Attribute,
			name = name,
		}

		setmetatable(AttributeListener, AttributeMetatable)
		Attribute[name] = AttributeListener

		return AttributeListener
	end,
})

return Attribute