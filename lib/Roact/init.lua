--[[
	Packages up the internals of Roact and exposes a public API for it.
]]

local GlobalConfig = require(script.GlobalConfig)
local createReconciler = require(script.createReconciler)
local createReconcilerCompat = require(script.createReconcilerCompat)
local RobloxRenderer = require(script.RobloxRenderer)
local strict = require(script.strict)
local Binding = require(script.Binding)
local Config

local robloxReconciler = createReconciler(RobloxRenderer)
local reconcilerCompat = createReconcilerCompat(robloxReconciler)

local Roact = strict {
	Component = require(script.Component),
	createElement = require(script.createElement).createElement,
	createFragment = require(script.createFragment),
	oneChild = require(script.oneChild),
	PureComponent = require(script.PureComponent),
	None = require(script.None),
	Portal = require(script.Portal),
	createRef = require(script.createRef),
	createBinding = Binding.create,
	joinBindings = Binding.join,
	createContext = require(script.createContext),
	Type = require(script.Type),

	Change = require(script.PropMarkers.Change),
	Children = require(script.PropMarkers.Children),
	Event = require(script.PropMarkers.Event),
	Ref = require(script.PropMarkers.Ref),
	Attribute = require(script.PropMarkers.Attribute),

	elementModule = require(script.createElement),

	mount = robloxReconciler.mountVirtualTree,
	unmount = robloxReconciler.unmountVirtualTree,
	update = robloxReconciler.updateVirtualTree,

	reify = reconcilerCompat.reify,
	teardown = reconcilerCompat.teardown,
	reconcile = reconcilerCompat.reconcile,

	setGlobalConfig = GlobalConfig.set,

	__init = function(self, G)
		Config = G.Load("Config")

		G.LightLoad(script.createElement)

		if Config.Debug == true then
			self.setGlobalConfig({
				["internalTypeChecks"] = true,
				--["typeChecks"] = true,
				["elementTracing"] = true,
				["propValidation"] = true,
				["apiValidation"] = true
			})
		end
	end,

	-- APIs that may change in the future without warning
	UNSTABLE = {
	},
}

return Roact