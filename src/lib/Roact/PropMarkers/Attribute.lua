local Type = require(script.Parent.Parent.Type)

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