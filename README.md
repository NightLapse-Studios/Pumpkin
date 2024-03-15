# Pumpkin
Pumpkin is a UI library that wraps Roact in order to make improvements on features and syntax. With that said, it is highly recommended you understand developing with Roact before Pumpkin, but most people will find Pumpkin both easier and more useful.

For working examples, check out the children of src/example/DebugMenu, such as [DebugCheckBox](DebugCheckBox.lua). For many, reading [Pumpkin](Pumpkin.lua) is a doable way to learn most of the library.

### Main Attractions
1) Short Syntax/Builder Pattern
1) Improved Bindings/Tweens
1) Custom PropSet Modifiers
1) Other/Utility

### Short Syntax/Builder Pattern

```lua
-- Imports (always the same) (will be omitted from the README here on out)
local Pumpkin = require(game.ReplicatedFirst.Pumpkin)
local I, P = Pumpkin, Pumpkin.P

-- creation
I:ImageButton(P()
	:BackgroundColor3(1, 0, 0)-- You can also pass in a color3 value or a binding.
	:Activated(function()
		print("Clicked!")
	end)
):Children(
	-- more elements
)
```
What is this? Some of you may recognize this as the popular "builder pattern" in programming, and thats just what it is. We have said we want to make an `I:ImageButton()`, but we also want to give it properties. So, we constructed a table of `P`roperties via `P()`, then we defined the property `BackgroundColor3` to be red, and then we defined the event property `Activated`, so that we `print("Clicked!")` anytime the button is clicked/tapped/etc. And finally we pass that table into the creation function of the ImageButton (more on this last step below). The attraction to the builder pattern (especially over table declerations) is that the code reads left to right, top to bottom, *and* it's interpreted that way too.

UI is often thought of as a tree, and as such is coded like one. This is for good reason, the parents/children of instances are easily assigned and can be easily seen. To keep short syntax and the famous builder pattern all while visually appearing as a tree, the library takes advantage of the fact that arguments too a function must be executed before the function. So, in the above example, the properties are defined first, and then passed into the creation funciton.


### Improved Bindings/Tweens



For starters, bindings no longer *have* to be updated via their second return value:
```lua
local pulse, updPulse = I:Binding(0)

updPulse(0.5) -- Cool, but more hastle when storing bindings.

pulse.update(1) -- "Let the binding be free."
```
Next, it's easier than ever to know externally when a binding updates:
```lua
local pulse = I:Binding(0)

-- again, "Let the binding be free."
pulse:subscribe(function(newPulseValue)
	
end)
```

And finally, when joining bindings, everything goes. Mostly useful for general purpose UI components, we no longer have to check if passed in props are bindings or pure values. Let me show you:
```lua
local pulse = I:Binding(0)
local pulse2 = 0.5

I:JoinBindings({pulse, pulse2}):map(function(table)
	local pulseValue = table[1]--0
	local pulseValue2 = table[2]--0.5
end)
```

## **Anyway, Tweens.**


Any one of these three improvements may be helpful for practiced Roact developers, but now on to the *REAL* stuff... Tweens! Pumpkin Tweens are implemented as an extension to bindings and use Flippers UI Animation Library, they start playing when they are mounted. For detailed usage, read the comment at the top of [Pumpkin](Pumpkin.lua). Heres the rundown:

```lua
-- define a tween at 0 (default start value)
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

So essentially, Pumpkin Tweens are bindings with a sequence of animation steps. As you can see, despite the complex nature of this tween, the syntax remains relatively short. The animation sequence can be defined or changed at *anytime* too. You can read more about other functions related to tweens at the top of [Pumpkin](Pumpkin.lua). You can also find more examples there.



### Custom PropSet Modifiers


Because the table of properties relating to a ui element is defined via the builder pattern, take a look at this neat capability:
```lua
I:Frame(P()
	:Center()
)
```

Simple. How often do you need a ui element at AnchorPoint `Vector2.new(0.5, 0.5)` and Position `UDim2.fromScale(0.5, 0.5)`? All the time. You can find the definition of the `:Center()` modifier in [Pumpkin](Pumpkin.lua). But *if* we were to implement it ourselves... well we could put it right into [Pumpkin](Pumpkin.lua) no problem. Or, we could do this:
```lua
I:RegisterModifier("Center", function(props)
	props:AnchorPoint(0.5, 0.5)
	props:Position(0.5, 0, 0.5, 0)
end)
```
Not too crazy, but pretty nice. There's much more pre-defined custom modifiers in [Pumpkin](Pumpkin.lua). Some of which include 
`:RoundCorners(scale, pixels)`
`:Border(thick, color)`
`:Invisible()`
`:AspectRatioProp(ratio)`
`:MoveBy(xs, xo, ys, yo)`
`:Inset(scaling, spacing)`


### Other/Utility/Notes

* [DebugMenu](DebugMenu.lua) for a fully fledged client and server debug menu with sliders (with expression parser), color pickers, plotting, checkboxes, and textboxes.
* You can define Attributes to the propset like so `:Attribute("AttributeName", value/binding)`.
* The Roact Type table has been exposed, though rarely necessary, it would be used like this: `local isBinding = pulse[Roact.Type] == Roact.Type.Binding`.
* Stateful creation is like so:
	```lua
	I:Stateful(P()
		:Name("MyStateful")
		:Init(function(self)
		end)
		:Render(function(self)
		end)
		-- etc
	)
	
	-- creation
	I:MyStateful()
	```
* Trying to use custom propset/elements/statefuls before their creation will result in a timeout yield that waits for the creation.
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
* Custom Props for Custom Elements and Statefuls: `propSet:Prop(name, value)`
* More ports exist in [Pumpkin](Pumpkin.lua), such as Refs, Portals, and Change Events.
* There exists `I:IsPositionInObject`, `I:IsScrollBarAtEnd`.
* `PropSet:ScaledTextGroup` is the better TextScaled that works with multiple TextLabels instead of just one.
* `PropSet:Line(fromPos, toPos, thickness)` is an advanced custom modifier that *just works*, positions being interpreted in the same relativity as the  `Position` property of the UI element.
* Due to the functional nature of the syntax, how you write can be very different from anyone else, yet it always ends up readable. Lets look at 2 examples.

	* Example 1, `propSet:Run()` exists to maintain the tree structure of the code by offering in-tree custom modifiers that may be too niche to deserve a full on RegisteredModifier. The classic example is conditionals, without :Run, you may constantly be scrolling up and down leaving the tree to perform logic and then coming back.
		```lua
		-- rather simple, and would be better to store a variable
		local function createFrame(disabled: boolean)
			local transparecy = disabled and 0.7 or 0-- works and is better, but, for sake of example:
			
			return I:Frame(P()
				:Center()
				:Size(1, 0, 1, 0)
				:Run(function(propSet)
					if disabled then
						propSet:BackgroundTransparency(0.7)
					else
						propSet:BackgroundTransparency(0)
					end
				end)
				:BackgroundColor3(0,0,0)
			)
		end
		
		-- OR
		
		local function assignTransparency(propSet, disabled)
			if disabled then
				propSet:BackgroundTransparency(0.7)
			else
				propSet:BackgroundTransparency(0)
			end
		end
		
		local function createFrame(disabled: boolean)
			return I:Frame(P()
				:Center()
				:Size(1, 0, 1, 0)
				:Run(assignTransparency, disabled)
				:BackgroundColor3(0,0,0)
			)
		end
		
		-- OR even, no :Run and no Tree structure:
		
		local function createFrame(disabled: boolean)
			local propSet = P()
			propSet:Center()
			propSet:Size(1, 0, 1, 0)
			
			if disabled then
				propSet:BackgroundTransparency(0.7)
			else
				propSet:BackgroundTransparency(0)
			end
			
			propSet:BackgroundColor3(0,0,0)
			
			return I:Frame(propSet)
		end
		```
	* Example 2: Children.
		```lua
		I:Frame(P()
			
		):Children(
			--etc
		)
		
		-- OR
		
		I:Frame(P()
			:Children(
				--etc
			)
		)
		```