local Children = require(script.Parent.PropMarkers.Children)
local ElementKind = require(script.Parent.ElementKind)
local Logging = require(script.Parent.Logging)
local Type = require(script.Parent.Type)
local Attribute = require(script.Parent.PropMarkers.Attribute)
local Ref = require(script.Parent.PropMarkers.Ref)

local config = require(script.Parent.GlobalConfig).get()

local multipleChildrenMessage = [[
The prop `Roact.Children` was defined but was overriden by the third parameter to createElement!
This can happen when a component passes props through to a child element but also uses the `children` argument:

	Roact.createElement("Frame", passedProps, {
		child = ...
	})

Instead, consider using a utility function to merge tables of children together:

	local children = mergeTables(passedProps[Roact.Children], {
		child = ...
	})

	local fullProps = mergeTables(passedProps, {
		[Roact.Children] = children
	})

	Roact.createElement("Frame", fullProps)]]

local mod = { }

local mt_ElementUtils = { __index = mod }

local Game
local UI

local function __clone(self)
	local t = { }
	
	
	for i,v in self do
		
	end
	
	for i,v in self do
		if typeof(v) == "table" and not (v[Type] == Type.Binding) then
 			t[i] = __clone(v)
		else
			t[i] = v
		end
	end
	
	
	
	return t
end

--Direct mutation to props is sometimes done by other functions, this is not a restricted API entry point
function mod:Override(prop, value)
	self.props[prop] = value
	return self
end

function mod:Overrides(props)
	for prop, value in props do
		self.props[prop] = value
	end
	return self
end

function mod:Clone()
	local props = __clone(self.props)
	
	local clone = {
		props = props,
		
		[Type] = Type.Element,
		[ElementKind] = self[ElementKind],
		component = self.component,
	}
	
	setmetatable(clone, mt_ElementUtils)
	
	return clone
end

function mod:__init(G)
	Game = G
	UI = G.Load("UI")
end

--[[
	Creates a new element representing the given component.

	Elements are lightweight representations of what a component instance should
	look like.

	Children is a shorthand for specifying `Roact.Children` as a key inside
	props. If specified, the passed `props` table is mutated!
]]
function mod.createElement(component, props, children)
	assert(component ~= nil, "`component` is required")

	if config.typeChecks then
		assert(typeof(props) == "table" or props == nil, "`props` must be a table or nil")
		assert(typeof(children) == "table" or children == nil, "`children` must be a table or nil")
	end

	if props == nil then
		props = {}
	end

	if children ~= nil then
		if props[Children] ~= nil then
			Logging.warnOnce(multipleChildrenMessage)
		end

		props[Children] = children
	end

	local elementKind = ElementKind.fromComponent(component)

	local element = {
		[Type] = Type.Element,
		[ElementKind] = elementKind,
		component = component,
		props = props,
	}

	if config.elementTracing then
		-- We trim out the leading newline since there's no way to specify the
		-- trace level without also specifying a message.
		element.source = debug.traceback("", 2):sub(2)
	end

	setmetatable(element, mt_ElementUtils)

	return element
end

return mod