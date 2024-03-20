# Pumpkin
Pumpkin is a UI library that wraps Roact and Flipper to achieve better expressiveness and ease of writing components. It is highly recommended you understand developing with Roact before Pumpkin since it is built on Roact.

For working examples, check out the children of [src/example/DebugMenu](src/example/DebugMenu/init.lua), such as [DebugCheckBox](src/example/DebugMenu/DebugCheckBox.lua), and most functionality is implemented in a single file: [Pumpkin](src/Pumpkin/init.lua)

### Main Attractions
* Short Syntax/Builder Pattern
* Improved Bindings
* Flipper is available through bindings directly
* Custom PropSet Modifiers
* Props receive datatype arguments instead of the datatype directly
* Other/Utility

## Installation
Place the `src/Pumpkin` folder in your project and require it. The source code is the release.

### Short Syntax/Builder Pattern

```lua
-- Imports (always the same) (will be omitted from the README here on out)
local Pumpkin = require(game.ReplicatedFirst.Pumpkin)
local I, P = Pumpkin, Pumpkin.P

-- Roact 17 and Roact legacy modules are available, just in case
local Roact, RoactRbx = Pumpkin.Roact, Pumpkin.RoactRbx

-- creation
I:ImageButton(P()
	-- No need to type `Color3.new(...),`
	-- You can also pass in a color3 or binding.
	:BackgroundColor3(1, 0, 0)
	:Activated(function()
		print("Clicked!")
	end)
):Children(
	-- more elements
)

-- Equivalent to:
Roact.createElement("ImageButton", {
	BackgroundColor3 = Color3.new(1, 0, 0),
	[Roact.Event.Activated] = function()
		print("Clicked!")
	end,
}, {
	-- more elements
})
```


### Improved Bindings/Tweens

For starters, bindings no longer *have* to be updated via their second return value:
```lua
local pulse, updPulse = I:Binding(0)

-- Equivalent:
updPulse(0.5)
pulse.update(0.5)
```
Next, it's easier than ever to know externally when a binding updates:
```lua
-- Note, self is not passed in.
local disconnect_func = pulse.subscribe(function(newPulseValue)
	
end)
```

And finally, when joining bindings, everything goes. Mostly useful for general purpose UI components, we no longer have to check if passed in props are bindings or pure values:
```lua
local pulse = I:Binding(0)
local pulse2 = 0.5

I:JoinBindings({pulse, pulse2}):map(function(table)
	local pulseValue = table[1]		--0
	local pulseValue2 = table[2]	--0.5
end)
```


## Tweens

Pumpkin Tweens are implemented as an extension to bindings and use Flippers UI Animation Library, they start playing when they are attached to an instance, and reset to the beginning when unattached. A tween with no sequences will start playing once sequences have been added to it, which is what you should do if you don't want your tween to play until you tell it to. For detailed usage, read the comment at the top of [Pumpkin](src/Pumpkin/init.lua). Here's the rundown:

```lua
-- define a tween with value 0 (default start value)
-- spring to 1 with speed of 2 and damping of 1.3, go back to 0, wait half a second, repeat this forever
local pulse = I:Tween():spring(1, 2, 1.3):instant(0):pause(0.5):repeatAll(-1)

I:ImageButton(P()
	:BackgroundColor3(pulse:map(function(v)-- the tween is a binding with extra functionality.
		return Color3.new(v, 0, 0)
	end))
	:Activated(function()
		pulse:wipe()-- when the buttons is clicked, clear the animation steps and reset to start value (0)
	end)
)
```

So essentially, Pumpkin Tweens are bindings with a sequence of animation steps. As you can see, despite the complex nature of this tween, the syntax remains relatively short. The animation sequence can be defined or changed at *any time* too. You can read more about other functions related to tweens at the top of [Pumpkin](src/Pumpkin/init.lua). You can also find more examples there.


## Custom PropSet Modifiers

Constructing props through the builder pattern lets us put names on our ways of setting props:
```lua
I:Frame(P()
	 -- Center the UI within its parent
	:Center()
	-- Position it 5 pixels away from the left side of its parent, (overwriting the :Center() call above)
	:JustifyLeft(0, 5)
	:Invisible()
	-- Propset modifiers can do a lot more than modify props
	-- This example involves inserting children into the props as well, a UIAspectRatioConstraint
	:AspectRatioProp(1/3)
)
```

All PropSet modifiers can be found in [Pumpkin](src/Pumpkin/init.lua) under the `PropSet` table. But we can also define custom modifiers elsewhere, to be used in the same way
```lua
I:RegisterModifier("Center", function(props)
	props:AnchorPoint(0.5, 0.5)
	props:Position(0.5, 0, 0.5, 0)
end)
```


## Misc

* [DebugMenu](src/example/DebugMenu/init.lua) for a fully fledged client and server debug menu with sliders, color pickers, plotting, checkboxes, and textboxes.
* You can define Instance Attributes to the PropSet like so `:Attribute("AttributeName", value/binding)`.
* The Roact Type table has been exposed, though rarely necessary, it would be used like this: `local isBinding = pulse["$$typeof"] == Roact.Type.Binding`.
* Roact elements fall back to pumpkin prop sets:
	```lua
	-- We are adding childrent directly to a roact element's props
	I:Frame(P()
		
	):Children(
		--etc
	)

	-- OR: We add them to the PropSet via the same function, and they are moved to the element when the PropSet is processed
	I:Frame(P()
		:Children(
			--etc
		)
	)

	-- Works as if it was made through pumpkin
	Roact.createElement("Frame"):JustifyLeft(0, 1)
	```
* Roact.component.extend() has been abstracted slightly:
	```lua
	I:Stateful(P()
		:Name("MyStateful")
		:Init(function(self)
		end)
		:Render(function(self)
		end)
		-- etc
	)
	
	-- Once a stateful component is created, it can be instanced by name
	I:MyStateful()
	```
* Custom Elements can be created and used like so:
	```lua
	I:NewElement("MyElement", I:Frame(P()
		--etc
	))
	
	--OR
	
	I:NewElement("MyElement", function(props)
	
	end)
	
	-- creation
	I:Element("MyElement", P()
		--etc
	)
	```
* Trying to use custom PropSet/elements/statefuls before their creation will result in a timeout yield that waits for the creation (plays nicely with frameworks that have execution models, but results in a *delayed* error in unyieldable code).
* Custom Props for function elements and stateful components: `propSet:Prop(name, value)`
* More wrappers exist in [Pumpkin](src/Pumpkin/init.lua), such as Refs, Portals, and Change Events.
* There exists `I:IsPositionInObject`, `I:IsScrollBarAtEnd`.
* `PropSet:ScaledTextGroup` is the better TextScaled that works with multiple TextLabels instead of just one.
* `PropSet:Line(fromPos: UDim2, toPos: UDim2, thickness: number)` is an advanced custom modifier that *just works* with positions relative the  `Position` property of the UI element.
* `propSet:Run()` exists to maintain the tree structure of the code by offering in-tree custom modifiers that may be too niche to deserve a full on RegisteredModifier. The classic example is conditionals, without :Run, you may constantly be scrolling up and down leaving the tree to perform logic and then coming back.
	```lua
	-- Conditionally set props without bindings
	local function createFrame(disabled: boolean)
		local props = P():Center()
		
		if disabled then
			props:BackgroundTransparency(0.7)
			props:BackgroundColor3(--[[Some disabled color]])
		else
			props:BackgroundTransparency(0)
			props:BackgroundColor3(--[[Some enabled color]])
		end

		return I:Frame(props)
	end

	-- Now do it without destructuring the tree
	local function createFrame(disabled: boolean)
		return I:Frame(P()
			:Center()
			:Run(function(props)
				if disabled then
					props:BackgroundTransparency(0.7)
					props:BackgroundColor3(--[[Some disabled color]])
				else
					props:BackgroundTransparency(0)
					props:BackgroundColor3(--[[Some enabled color]])
				end
			end)
		)
	end
	```