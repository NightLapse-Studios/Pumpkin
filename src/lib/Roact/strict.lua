local Config = require(script.Parent.GlobalConfig):get()

local function strict(t, name)
	name = name or tostring(t)

	if Config.apiValidation then
		return setmetatable(t, {
			__index = function(self, key)
				local message = ("%q (%s) is not a valid member of %s"):format(
					tostring(key),
					typeof(key),
					name
				)

				warn(message, 2)
			end,

			__newindex = function(self, key, value)
				local message = ("%q (%s) is not a valid member of %s"):format(
					tostring(key),
					typeof(key),
					name
				)

				warn(message, 2)
			end,
		})
	else
		return t
	end
end

return strict