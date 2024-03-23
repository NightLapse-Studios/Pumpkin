--!strict
--!native
--[[
	Module by Ruuuuusty and vijet1
	TODO: more better comments

	Tweens:
			Tweens play when they are mounted, they are an extension to bindings.
			If they are unmounted, their motor stops and sequence resets.

			@param start default 0, should be a number
			@return a tween sequence for chain definitions
			I:Tween(start)

			--Motor chains. Start when the previous step is complete.
			:spring(target, frequency, dampingRatio)
			:linear(target, velocity)
			:instant(target)

			to tween non numbers it is recommended to append at the end of the chain with :map(I:ColorMap(c1, c2))

			-- other chainable functions
			@param count can be -1 for infinite
			:repeatAll(count) -- repeats the entire chain defined for count times.
			:repeatThis(count) -- repeats the last chained object for count times.
			:pause(t) -- adds a chain which pauses the tween sequence for t seconds before continuing.

			-- external
			:wipe() -- wipes the tween sequence and puts the motor back to its initial value
			:reset() -- resets the tween sequence again at the start of the chain and initial value of the motor.
			:pause() -- pauses the playing of the chain and motor.
			:resume() -- resumes playing of the chain and motor.
			:skip() -- skips to the next step in the chain, without changing the value of the motor.
			:jump() -- skips to the next step in the chain, and starts the motor at the target_value of the step being jumped.

			@examples
				-- a tween that when mounted will oscilate between 0 and 1, forever.
				local tween = I:Tween(0):spring(1, 4, 0)
				
				-- because tweens are bindings, we can map them or join them.
				I:Frame(P()
					:Size(tween:map(function(v)
						return UDim2.new(v, 0, v, 0)
					))
				)
				
				-- tweens can be controlled externally like so
				-- in this example, everytime the button is clicked, the tween will go to 0 (the start value), then go linearly to 1
				I:ImageButton(P()
					:Activated(function()
						tween:wipe():linear(1, 4)
					end)
				)
]]


local ASYNC_DEFINITIONS = true
local ASYNC_WAIT_TIME = 0.2

local Roact = require(script.lib.Roact)
local RoactRbx = require(script.lib.Roact._Index.ReactRoblox.ReactRoblox)
local ClassicSignal = require(script.lib.ClassicSignal)

local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")

local IsServer = RunService:IsServer()


type Content = string
type bool = boolean
type int = number
type float = number

type ValueAcceptor<T, R> = (T) -> R
type OneArgCtor<T, P, R> = (T | P) -> R
type TwoArgCtor<T, P, R> = (T | P, P?) -> R
type ThreeArgCtor<T, P, R> = (T | P, P?, P?) -> R
type FourArgCtor<T, P, R> = (T | P, P?, P?, P?) -> R
type InputEvent<R> = ((InputObject) -> ()) -> R
type InstanceEvent<R> = ((Instance) -> ()) -> R
type VideoFrameEvent<R> = ((Content) -> ()) -> R


type Props = { [string]: any}
type ComponentConfigFunc = (Roact.ComponentType<Props>) -> ()

export type PropSet = {
	props: { [string]: any },

	RoundCorners: (number?, number?) -> PropSet,
	Border: (thicknes: number, Color3) -> PropSet,
	Invisible: () -> PropSet,
	Line: (fromPos: UDim2, toPos: UDim2, thicknes: number) -> PropSet,
	AspectRatioProp: (number) -> PropSet,
	MoveBy: (xscale: number, xoffset: number, yscale: number, yoffset: number) -> PropSet,
	Center: () -> PropSet,
	JustifyLeft: (scaling: number, spacing: number) -> PropSet,
	JustifyRight: (scaling: number, spacing: number) -> PropSet,
	JustifyTop: (scaling: number, spacing: number) -> PropSet,
	JustifyBottom: (scaling: number, spacing: number) -> PropSet,
	OutsideLeft: (scaling: number, spacing: number) -> PropSet,
	OutsideRight: (scaling: number, spacing: number) -> PropSet,
	OutsideTop: (scaling: number, spacing: number) -> PropSet,
	OutsideBottom: (scaling: number, spacing: number) -> PropSet,
	Inset: (scaling: number, spacing: number) -> PropSet,
	ScaledTextGroup: (groupName: string, text: string) -> PropSet,
	Attribute: (name: string, any) -> PropSet,
	Prop: (name: string, any) -> PropSet,
	Ref: (any) -> PropSet,
	Children: (... Roact.ReactElement) -> PropSet,
	InsertChild: (Roact.ReactElement) -> PropSet,
	Change: (name: string, callback: (Instance) -> ()) -> PropSet,
	Run: ((Props, ... any) -> (), ... any) -> PropSet,
	Target: (Instance) -> PropSet,
	Init: (ComponentConfigFunc) -> PropSet,
	Render: (ComponentConfigFunc) -> PropSet,
	DidMount: (ComponentConfigFunc) -> PropSet,
	WillUnmount: (ComponentConfigFunc) -> PropSet,
	WillUpdate: (ComponentConfigFunc) -> PropSet,
	ShouldUpdate: (ComponentConfigFunc) -> PropSet,
	DidUpdate: (ComponentConfigFunc) -> PropSet,

	AutoButtonColor: ValueAcceptor<bool, PropSet>,
	Modal: ValueAcceptor<bool, PropSet>,
	Selected: ValueAcceptor<bool, PropSet>,
	Style: ValueAcceptor<Enum.Style, PropSet>,
	Name: ValueAcceptor<string, PropSet>,
	AutoLocalize: ValueAcceptor<bool, PropSet>,
	RootLocalizationTable: LocalizationTable,
	SelectionBehaviorDown: ValueAcceptor<Enum.SelectionBehavior, PropSet>,
	SelectionBehaviorLeft: ValueAcceptor<Enum.SelectionBehavior, PropSet>,
	SelectionBehaviorRight: ValueAcceptor<Enum.SelectionBehavior, PropSet>,
	SelectionBehaviorUp: ValueAcceptor<Enum.SelectionBehavior, PropSet>,
	SelectionGroup: ValueAcceptor<bool, PropSet>,
	SelectionImageObject: ValueAcceptor<GuiObject, PropSet>,
	ClipsDescendants: ValueAcceptor<bool, PropSet>,
	Draggable: ValueAcceptor<bool, PropSet>,
	Active: ValueAcceptor<bool, PropSet>,
	AnchorPoint: TwoArgCtor<Vector2, number, PropSet>,
	AutomaticSize: ValueAcceptor<Enum.AutomaticSize, PropSet>,
	BackgroundColor3: ThreeArgCtor<Color3, number, PropSet>,
	BackgroundTransparency: ValueAcceptor<float, PropSet>,
	BorderColor3: ThreeArgCtor<Color3, number, PropSet>,
	BorderMode: ValueAcceptor<Enum.BorderMode, PropSet>,
	BorderSizePixel: ValueAcceptor<int, PropSet>,
	LayoutOrder: ValueAcceptor<int, PropSet>,
	Position: FourArgCtor<UDim2, number, PropSet>,
	Rotation: ValueAcceptor<float, PropSet>,
	Size: FourArgCtor<UDim2, number, PropSet>,
	SizeConstraint: ValueAcceptor<Enum.SizeConstraint, PropSet>,
	Transparency: ValueAcceptor<float, PropSet>,
	Visible: ValueAcceptor<bool, PropSet>,
	ZIndex: ValueAcceptor<int, PropSet>,
	NextSelectionDown: ValueAcceptor<GuiObject, PropSet>,
	NextSelectionLeft: ValueAcceptor<GuiObject, PropSet>,
	NextSelectionRight: ValueAcceptor<GuiObject, PropSet>,
	NextSelectionUp: ValueAcceptor<GuiObject, PropSet>,
	Selectable: ValueAcceptor<bool, PropSet>,
	SelectionOrder: ValueAcceptor<int, PropSet>,
	Activated: InputEvent<PropSet>,
	MouseButton1Click: InputEvent<PropSet>,
	MouseButton1Down: InputEvent<PropSet>,
	MouseEnter: InputEvent<PropSet>,
	MouseLeave: InputEvent<PropSet>,
	MouseButton1Up: InputEvent<PropSet>,
	MouseButton2Click: InputEvent<PropSet>,
	MouseButton2Down: InputEvent<PropSet>,
	MouseButton2Up: InputEvent<PropSet>,
	InputBegan: InputEvent<PropSet>,
	InputEnded: InputEvent<PropSet>,
	InputChanged: InputEvent<PropSet>,
	TouchLongPress: InputEvent<PropSet>,
	TouchPan: InputEvent<PropSet>,
	TouchPinch: InputEvent<PropSet>,
	TouchRotate: InputEvent<PropSet>,
	TouchSwipe: InputEvent<PropSet>,
	TouchTap: InputEvent<PropSet>,
	GroupColor3: ThreeArgCtor<Color3, number, PropSet>,
	GroupTransparency: ValueAcceptor<float, PropSet>,
	DisplayOrder: ValueAcceptor<int, PropSet>,
	Enabled: ValueAcceptor<bool, PropSet>,
	IgnoreGuiInset: ValueAcceptor<bool, PropSet>,
	ResetOnSpawn: ValueAcceptor<bool, PropSet>,
	ZIndexBehavior: ValueAcceptor<Enum.ZIndexBehavior, PropSet>,
	Adornee: ValueAcceptor<Instance | BasePart, PropSet>,
	AlwaysOnTop: ValueAcceptor<bool, PropSet>,
	LightInfluence: ValueAcceptor<float, PropSet>,
	SizeOffset: TwoArgCtor<Vector2, number, PropSet>,
	StudsOffset: ThreeArgCtor<Vector3, number, PropSet>,
	ExtentsOffsetWorldSpace: ThreeArgCtor<Vector3, number, PropSet>,
	MaxDistance: ValueAcceptor<float, PropSet>,
	HoverImage: ValueAcceptor<Content, PropSet>,
	Image: ValueAcceptor<Content, PropSet>,
	ImageColor3: ThreeArgCtor<Color3, number, PropSet>,
	ImageRectOffset: TwoArgCtor<Vector2, number, PropSet>,
	ImageRectSize: TwoArgCtor<Vector2, number, PropSet>,
	ImageTransparency: ValueAcceptor<float, PropSet>,
	PressedImage: ValueAcceptor<Content, PropSet>,
	ResampleMode: ValueAcceptor<Enum.ResamplerMode, PropSet>,
	ScaleType: ValueAcceptor<Enum.ScaleType, PropSet>,
	SliceCenter: FourArgCtor<Rect, number, PropSet>,
	SliceScale: ValueAcceptor<float, PropSet>,
	TileSize: FourArgCtor<UDim2, number, PropSet>,
	Font: ValueAcceptor<Font, PropSet>,
	FontFace: ValueAcceptor<Font, PropSet>,
	LineHeight: ValueAcceptor<float, PropSet>,
	MaxVisibleGraphemes: ValueAcceptor<int, PropSet>,
	RichText: ValueAcceptor<bool, PropSet>,
	Text: ValueAcceptor<string, PropSet>,
	TextColor3: ThreeArgCtor<Color3, number, PropSet>,
	TextScaled: ValueAcceptor<bool, PropSet>,
	TextSize: ValueAcceptor<float, PropSet>,
	TextStrokeColor3: ThreeArgCtor<Color3, number, PropSet>,
	TextStrokeTransparency: ValueAcceptor<float, PropSet>,
	TextTransparency: ValueAcceptor<float, PropSet>,
	TextTruncate: ValueAcceptor<Enum.TextTruncate, PropSet>,
	TextWrapped: ValueAcceptor<bool, PropSet>,
	TextXAlignment: ValueAcceptor<Enum.TextXAlignment, PropSet>,
	TextYAlignment: ValueAcceptor<Enum.TextYAlignment, PropSet>,
	AutomaticCanvasSize: ValueAcceptor<Enum.AutomaticSize, PropSet>,
	BottomImage: ValueAcceptor<Content, PropSet>,
	CanvasPosition: TwoArgCtor<Vector2, number, PropSet>,
	CanvasSize: FourArgCtor<UDim2, number, PropSet>,
	ElasticBehavior: ValueAcceptor<Enum.ElasticBehavior, PropSet>,
	HorizontalScrollBarInset: ValueAcceptor<Enum.ScrollBarInset, PropSet>,
	MidImage: ValueAcceptor<Content, PropSet>,
	ScrollBarImageColor3: ThreeArgCtor<Color3, number, PropSet>,
	ScrollBarImageTransparency: ValueAcceptor<float, PropSet>,
	ScrollBarThickness: ValueAcceptor<int, PropSet>,
	ScrollingDirection: ValueAcceptor<Enum.ScrollingDirection, PropSet>,
	ScrollingEnabled: ValueAcceptor<bool, PropSet>,
	TopImage: ValueAcceptor<Content, PropSet>,
	VerticalScrollBarInset: ValueAcceptor<Enum.ScrollBarInset, PropSet>,
	VerticalScrollBarPosition: ValueAcceptor<Enum.VerticalScrollBarPosition, PropSet>,
	ClearTextOnFocus: ValueAcceptor<bool, PropSet>,
	CursorPosition: ValueAcceptor<int, PropSet>,
	MultiLine: ValueAcceptor<bool, PropSet>,
	SelectionStart: ValueAcceptor<int, PropSet>,
	ShowNativeInput: ValueAcceptor<bool, PropSet>,
	TextEditable: ValueAcceptor<bool, PropSet>,
	PlaceholderColor3: ThreeArgCtor<Color3, number, PropSet>,
	PlaceholderText: ValueAcceptor<string, PropSet>,
	FocusLost: InstanceEvent<PropSet>,
	Focused: InstanceEvent<PropSet>,
	ReturnPressedFromOnScreenKeyboard: InputEvent<PropSet>,
	Looped: ValueAcceptor<bool, PropSet>,
	Playing: ValueAcceptor<bool, PropSet>,
	TimePosition: ValueAcceptor<float, PropSet>,
	Video: ValueAcceptor<Content, PropSet>,
	Volume: ValueAcceptor<float, PropSet>,
	DidLoop: VideoFrameEvent<PropSet>,
	Ended: VideoFrameEvent<PropSet>,
	Loaded: VideoFrameEvent<PropSet>,
	Paused: VideoFrameEvent<PropSet>,
	Played: VideoFrameEvent<PropSet>,
	Ambient: ThreeArgCtor<Color3, number, PropSet>,
	LightColor: ThreeArgCtor<Color3, number, PropSet>,
	LightDirection: ThreeArgCtor<Vector3, number, PropSet>,
	CurrentCamera: ValueAcceptor<Camera, PropSet>,
	Color: ThreeArgCtor<ColorSequence | Color3, number, PropSet>,
	Offset: TwoArgCtor<Vector2, number, PropSet>,
	CornerRadius: TwoArgCtor<UDim, number, PropSet>,
	MaxTextSize: ValueAcceptor<int, PropSet>,
	MinTextSize: ValueAcceptor<int, PropSet>,
	MaxSize: TwoArgCtor<Vector2, number, PropSet>,
	MinSize: TwoArgCtor<Vector2, number, PropSet>,
	AspectRatio: ValueAcceptor<float, PropSet>,
	AspectType: ValueAcceptor<Enum.AspectType, PropSet>,
	DominantAxis: ValueAcceptor<Enum.DominantAxis, PropSet>,
	FillDirection: ValueAcceptor<Enum.FillDirection, PropSet>,
	HorizontalAlignment: ValueAcceptor<Enum.HorizontalAlignment, PropSet>,
	SortOrder: ValueAcceptor<Enum.SortOrder, PropSet>,
	VerticalAlignment: ValueAcceptor<Enum.VerticalAlignment, PropSet>,
	CellPadding: FourArgCtor<UDim2, number, PropSet>,
	CellSize: FourArgCtor<UDim2, number, PropSet>,
	FillDirectionMaxCells: ValueAcceptor<int, PropSet>,
	StartCorner: ValueAcceptor<Enum.StartCorner, PropSet>,
	Padding: TwoArgCtor<UDim, number, PropSet>,
	Animated: ValueAcceptor<bool, PropSet>,
	Circular: ValueAcceptor<bool, PropSet>,
	EasingDirection: ValueAcceptor<Enum.EasingDirection, PropSet>,
	EasingStyle: ValueAcceptor<Enum.EasingStyle, PropSet>,
	TweenTime: ValueAcceptor<float, PropSet>,
	GamepadInputEnabled: ValueAcceptor<bool, PropSet>,
	ScrollWheelInputEnabled: ValueAcceptor<bool, PropSet>,
	TouchInputEnabled: ValueAcceptor<bool, PropSet>,
	PageEnter: InstanceEvent<PropSet>,
	PageLeave: InstanceEvent<PropSet>,
	Stopped: InstanceEvent<PropSet>,
	FillEmptySpaceColumns: ValueAcceptor<bool, PropSet>,
	FillEmptySpaceRows: ValueAcceptor<bool, PropSet>,
	MajorAxis: ValueAcceptor<Enum.TableMajorAxis, PropSet>,
	PaddingBottom: TwoArgCtor<UDim, number, PropSet>,
	PaddingLeft: TwoArgCtor<UDim, number, PropSet>,
	PaddingRight: TwoArgCtor<UDim, number, PropSet>,
	PaddingTop: TwoArgCtor<UDim, number, PropSet>,
	Scale: ValueAcceptor<float, PropSet>,
	ApplyStrokeMode: ValueAcceptor<Enum.ApplyStrokeMode, PropSet>,
	LineJoinMode: ValueAcceptor<Enum.LineJoinMode, PropSet>,
	Thickness: ValueAcceptor<float, PropSet>,
}

export type PumpkinAPI = {
	P: () -> PropSet,
	Stateful: (PumpkinAPI, PropSet) -> Roact.ComponentType<Props>,
	RegisterModifier: (PumpkinAPI, name: string, (PropSet) -> (PropSet)) -> (),
	NewElement: (PumpkinAPI, name: string, Roact.Element<string> | (PropSet) -> Roact.Element<string>) -> (),
	Element: (PumpkinAPI, name: string, PropSet) -> Roact.Element<string>,
	Binding: (PumpkinAPI, any) -> Roact.Binding<any>,
	JoinBindings: (PumpkinAPI, { Roact.Binding<any> }) -> Roact.Binding<any>,
	CreateRef: (PumpkinAPI) -> Roact.Ref<any>,
	Mount: (PumpkinAPI, Roact.ReactNodeList, parent: Instance) -> RoactRbx.RootType,
	Tween: (PumpkinAPI, number?) -> Roact.Binding<number>,
	Portal: (PumpkinAPI, children: { Roact.Element<string> }, container: Instance, PropSet, opt_key: string?) -> Roact.Element<unknown>,
	IsPositionInObject: (PumpkinAPI, Vector2, GuiBase2d) -> boolean,
	IsScrollBarAtEnd: (PumpkinAPI, Instance, padding: number?) -> boolean,

	GuiButton: (PumpkinAPI, PropSet) -> Roact.Element<"GuiButton">,
	GuiBase2d: (PumpkinAPI, PropSet) -> Roact.Element<"GuiBase2d">,
	GuiObject: (PumpkinAPI, PropSet) -> Roact.Element<"GuiObject">,
	CanvasGroup: (PumpkinAPI, PropSet) -> Roact.Element<"CanvasGroup">,
	Frame: (PumpkinAPI, PropSet) -> Roact.Element<"Frame">,
	ScreenGui: (PumpkinAPI, PropSet) -> Roact.Element<"ScreenGui">,
	BillboardGui: (PumpkinAPI, PropSet) -> Roact.Element<"BillboardGui">,
	ImageButton: (PumpkinAPI, PropSet) -> Roact.Element<"ImageButton">,
	TextButton: (PumpkinAPI, PropSet) -> Roact.Element<"TextButton">,
	ImageLabel: (PumpkinAPI, PropSet) -> Roact.Element<"ImageLabel">,
	TextLabel: (PumpkinAPI, PropSet) -> Roact.Element<"TextLabel">,
	ScrollingFrame: (PumpkinAPI, PropSet) -> Roact.Element<"ScrollingFrame">,
	TextBox: (PumpkinAPI, PropSet) -> Roact.Element<"TextBox">,
	VideoFrame: (PumpkinAPI, PropSet) -> Roact.Element<"VideoFrame">,
	ViewportFrame: (PumpkinAPI, PropSet) -> Roact.Element<"ViewportFrame">,
	UIGradient: (PumpkinAPI, PropSet) -> Roact.Element<"UIGradient">,
	UICorner: (PumpkinAPI, PropSet) -> Roact.Element<"UICorner">,
	UITextSizeConstraint: (PumpkinAPI, PropSet) -> Roact.Element<"UITextSizeConstraint">,
	UISizeConstraint: (PumpkinAPI, PropSet) -> Roact.Element<"UISizeConstraint">,
	UIAspectRatioConstraint: (PumpkinAPI, PropSet) -> Roact.Element<"UIAspectRatioConstraint">,
	UIGridStyleLayout: (PumpkinAPI, PropSet) -> Roact.Element<"UIGridStyleLayout">,
	UIGridLayout: (PumpkinAPI, PropSet) -> Roact.Element<"UIGridLayout">,
	UIListLayout: (PumpkinAPI, PropSet) -> Roact.Element<"UIListLayout">,
	UIPageLayout: (PumpkinAPI, PropSet) -> Roact.Element<"UIPageLayout">,
	UITableLayout: (PumpkinAPI, PropSet) -> Roact.Element<"UITableLayout">,
	UIPadding: (PumpkinAPI, PropSet) -> Roact.Element<"UIPadding">,
	UIScale: (PumpkinAPI, PropSet) -> Roact.Element<"UIScale">,
	UIStroke: (PumpkinAPI, PropSet) -> Roact.Element<"UIStroke">,

	Roact: typeof(Roact),
	RoactRbx: typeof(RoactRbx)
}

local mod = {
	Roact = Roact,
	RoactRbx = RoactRbx
}

mod = (mod :: any) :: PumpkinAPI

local PropSet = { }

local mt_PropSet = { __index = PropSet }

if ASYNC_DEFINITIONS then
	--[[
		The idea is to "break" intermodule dependencies by waiting for unfound indices (which are always functions)
		We substitute the missing function with one which waits for the expected function
		Recommended for use in ergonomic frameworks
		See README for elaboration
			
		In roblox, task.wait() causes a 1 frame delay that is multiplied by the depth of your dependency tree.
		In practice, the waiting period is 1 frame if you write appropriate code (get your definitions out of the way
			early and use your dependencies late, or otherwise use a framework that can prevent dependencies from
			blocking definitions i.e. Knit)
	]]
	setmetatable(mod, {
		__index = function(t, index)
			return function(...)
				local total = 0
				repeat total += task.wait() until (rawget(t, index) or total > ASYNC_WAIT_TIME)
				
				if not rawget(t, index) then
					error(index .. " is not registered")
				end
				
				return rawget(t, index)(...)
			end
		end
	})

	setmetatable(PropSet, {
		__index = function(t, index)
			return function(...)
				local total = 0
				repeat total += task.wait() until (rawget(t, index) or total > ASYNC_WAIT_TIME)
				
				if not rawget(t, index) then
					error(index .. " is not registered")
				end
				
				return rawget(t, index)(...)
			end
		end
	})
end

function mod.P(): PropSet
	local set = {
		props = { }
	}

	setmetatable(set, mt_PropSet)
	return (set :: any) :: PropSet
end

local P = mod.P

function PropSet:RoundCorners(scale, pixels)
	self:Children(
		mod:UICorner(P()
			:CornerRadius(scale or 0, pixels or 4)
		)
	)

	return self
end

function PropSet:Border(thick, color)
	self:Children(
		mod:UIStroke(P()
			:ApplyStrokeMode(Enum.ApplyStrokeMode.Border)
			:Color(color or Color3.new(0, 0, 0))
			:Thickness(thick or 2)
		)
	)

	return self
end

function PropSet:Invisible()
	self:BackgroundTransparency(1)
	self:BorderSizePixel(0)
	return self
end

function PropSet:Line(fromPos: UDim2, toPos: UDim2, thick)
	local size, updSize = Roact.createBinding(UDim2.new(0,0,0,0))
	local rotation, updRotation = Roact.createBinding(0)
	local position, updPosition = Roact.createBinding(UDim2.new(0,0,0,0))

	local function updateBindings(rbx)
		if not (rbx and rbx.Parent) then
			return
		end

		local absoluteSize = rbx.Parent.AbsoluteSize

		local x1 = fromPos.X.Scale * absoluteSize.X + fromPos.X.Offset
		local y1 = fromPos.Y.Scale * absoluteSize.Y + fromPos.Y.Offset
		local x2 = toPos.X.Scale * absoluteSize.X + toPos.X.Offset
		local y2 = toPos.Y.Scale * absoluteSize.Y + toPos.Y.Offset
		local dx = x2 - x1
		local dy = y2 - y1

		local distance = math.sqrt(dx * dx + dy * dy)
		updSize(UDim2.new(0, distance, 0, thick))

		updPosition(UDim2.new(0, (x1 + x2)/2, 0, (y1 + y2)/2))

		updRotation(math.deg(math.atan2(y2 - y1, x2 - x1)))
	end

	local old = self.props[Roact.Change.AbsoluteSize]
	self.props[Roact.Change.AbsoluteSize] = function(rbx: Instance)
		if old then
			old(rbx)
		end
		updateBindings(rbx)
	end

	local old2 = self.props[Roact.Change.AbsolutePosition]
	self.props[Roact.Change.AbsolutePosition] = function(rbx: Instance)
		if old2 then
			old2(rbx)
		end
		updateBindings(rbx)
	end

	local old3 = self.props[Roact.Change.Parent]
	self.props[Roact.Change.Parent] = function(rbx: Instance)
		if old3 then
			old3(rbx)
		end

		updateBindings(rbx)
	end

	self.props["ref"] = function(rbx: Instance)
		updateBindings(rbx)
	end

	self:AnchorPoint(0.5, 0.5)
	self:Size(size)
	self:Rotation(rotation)
	self:Position(position)

	return self
end

function PropSet:AspectRatioProp(ratio)
	-- Aspect Ratio is X/Y, so the larger the ratio, the larger Width.
	self:Children(
		mod:UIAspectRatioConstraint(P()
			:AspectRatio(ratio)
		)
	)

	return self
end

function PropSet:MoveBy(xs, xo, ys, yo)
	local pos = self.props.Position or UDim2.new()
	pos += UDim2.new(xs, xo, ys, yo)
	self:Position(pos)
	return self
end

function PropSet:Center()
	self:AnchorPoint(0.5, 0.5)
	self:Position(0.5, 0, 0.5, 0)
	return self
end

function PropSet:JustifyLeft(scaling, spacing)
	self:AnchorPoint(0, 0.5)

	local old_pos = self.props.Position
	if old_pos then
		self:Position(scaling, spacing, old_pos.Y.Scale, old_pos.Y.Offset)
	else
		self:Position(scaling, spacing, 0.5, 0)
	end

	return self
end
function PropSet:JustifyRight(scaling, spacing)
	self:AnchorPoint(1, 0.5)

	local old_pos = self.props.Position
	if old_pos then
		self:Position(1 - scaling, -spacing, old_pos.Y.Scale, old_pos.Y.Offset)
	else
		self:Position(1 - scaling, -spacing, 0.5, 0)
	end

	return self
end
function PropSet:JustifyTop(scaling, spacing)
	self:AnchorPoint(0.5, 0)

	local old_pos = self.props.Position
	if old_pos then
		self:Position(old_pos.X.Scale, old_pos.X.Offset, scaling, spacing)
	else
		self:Position(0.5, 0, scaling, spacing)
	end

	return self
end
function PropSet:JustifyBottom(scaling, spacing)
	self:AnchorPoint(0.5, 1)

	local old_pos = self.props.Position
	if old_pos then
		self:Position(old_pos.X.Scale, old_pos.X.Offset, 1 - scaling, -spacing)
	else
		self:Position(0.5, 0, 1 - scaling, -spacing)
	end

	return self
end

function PropSet:OutsideLeft(scaling, spacing)
	self:AnchorPoint(1, 0.5)

	local old_pos = self.props.Position
	if old_pos then
		self:Position(-scaling, -spacing, old_pos.Y.Scale, old_pos.Y.Offset)
	else
		self:Position(-scaling, -spacing, 0.5, 0)
	end

	return self
end
function PropSet:OutsideRight(scaling, spacing)
	self:AnchorPoint(0, 0.5)

	local old_pos = self.props.Position
	if old_pos then
		self:Position(1 + scaling, spacing, old_pos.Y.Scale, old_pos.Y.Offset)
	else
		self:Position(1 + scaling, spacing, 0.5, 0)
	end

	return self
end
function PropSet:OutsideTop(scaling, spacing)
	self:AnchorPoint(0.5, 1)

	local old_pos = self.props.Position
	if old_pos then
		self:Position(old_pos.X.Scale, old_pos.X.Offset, -scaling, -spacing)
	else
		self:Position(0.5, 0, -scaling, -spacing)
	end

	return self
end
function PropSet:OutsideBottom(scaling, spacing)
	self:AnchorPoint(0.5, 0)

	local old_pos = self.props.Position
	if old_pos then
		self:Position(old_pos.X.Scale, old_pos.X.Offset, 1 + scaling, spacing)
	else
		self:Position(0.5, 0, 1 + scaling, spacing)
	end

	return self
end

function PropSet:Inset(scaling, spacing)
	self:Size(1 - scaling, -spacing, 1 - scaling, -spacing)
	return self
end


--[[
	TextScaled Groups.
]]
local scaledTextGroups = {}

local function getMaxSize(rbx: TextLabel, constantText)
	local sizeX, sizeY = rbx.AbsoluteSize.X, rbx.AbsoluteSize.Y
	local isAutoSizeX = rbx.AutomaticSize == Enum.AutomaticSize.X or rbx.AutomaticSize == Enum.AutomaticSize.XY
	local isAutoSizeY = rbx.AutomaticSize == Enum.AutomaticSize.Y or rbx.AutomaticSize == Enum.AutomaticSize.XY
	
	if isAutoSizeX then
		sizeX = 99999
	end
	
	if isAutoSizeY then
		sizeY = 99999
	end
	
	local text = constantText or rbx.Text
	text = " " .. text .. " "
	
	local font = rbx.Font

	local maxSize = 100
	local minSize = 11
	
	local absMinSize = minSize
	
	local container = Vector2.new(sizeX, 99999)-- dont use SizeY here so that textWrapped works automatically
	
	while minSize <= maxSize do
		local midSize = math.floor((minSize + maxSize) / 2)
		local textSize = TextService:GetTextSize(text, midSize, font, container)

		local tooLarge = textSize.Y > sizeY or textSize.X > sizeX

		if tooLarge then
			maxSize = midSize - 1
		else
			minSize = midSize + 1
		end
	end
	
	if absMinSize == maxSize then
		return maxSize
	else
		return maxSize - 1
	end
end

function PropSet:ScaledTextGroup(groupName, constantText)
	if type(constantText) == "number" then
		constantText = string.rep(" ", constantText)
	end
	
	local group = scaledTextGroups[groupName]
	if not group then
		local binding = mod:Binding(0)
		
		scaledTextGroups[groupName] = {
			Binding = binding,
			Refs = {},
			
			ConstantText = constantText,
		}
		
		group = scaledTextGroups[groupName]
	end
	
	local ref = mod:CreateRef()
	self:Ref(ref)
	
	table.insert(group.Refs, ref)
	
	self:TextSize(group.Binding)
	
	return self
end

if not IsServer then
	RunService.Stepped:Connect(function()
		for name, group in pairs(scaledTextGroups) do
			local refs = group.Refs
			
			local min = 100
			
			local did = false
			
			for i = #refs, 1, -1 do
				local ref = refs[i]
				local rbx = ref:getValue()
				
				if not rbx then
					continue
				end
				
				did = true
				
				local max = getMaxSize(rbx, group.ConstantText)
				if max < min then
					min = max
				end
			end
			
			if not did then
				min = 7-- the first frame that the text is rendered will be this size
			end
			
			group.Binding.update(min)
		end
	end)
end

function PropSet:Attribute(name, value)
	self.props[Roact.Attribute[name]] = value
	return self
end

function PropSet:Prop(name, value)
	self.props[name] = value
	return self
end

function PropSet:Ref(value)
	self.props["ref"] = value
	return self
end


function PropSet:Children(...)
	local existing_children = self.props["children"]
	local new_children = { ... }

	if not existing_children then
		self.props["children"] = new_children
	else
		for i,v in new_children do
			table.insert(existing_children, v)
		end
		self.props["children"] = existing_children
	end

	return self
end

function PropSet:InsertChild(child)
	self.props["children"] = self.props["children"] or { }
	table.insert(self, child)
	return self
end

function PropSet:Change(name: string, callback: (GuiObject) -> ())
	self.props[Roact.Change[name]] = callback
	return self
end

function PropSet:Run(func, ...)
	func(self, ...)
	return self
end

function PropSet:Target(instance)
	self.props.target = instance
	return self
end


-- Stateful functionality
function mod:Stateful(prop_set: PropSet)
	local props = prop_set.props
	
	local component = Roact.Component:extend(props.Name)
	component.init = props.init
	component.render = props.render
	component.componentDidMount = props.didMount
	component.componentWillUnmount = props.willUnmount
	component.componentWillUpdate = props.willUpdate
	component.shouldComponentUpdate = props.shouldUpdate
	component.componentDidUpdate = props.didUpdate
	
	mod[props.Name] = function(_self, this_prop_set: table)
		local this_props = this_prop_set.props
		local element = Roact.createElement(component, this_props)
		
		return element
	end
	
	return component
end

function PropSet:Init(func)
	self.props.init = func
	return self
end

function PropSet:Render(func)
	self.props.render = func
	return self
end

function PropSet:DidMount(func)
	self.props.didMount = func
	return self
end

function PropSet:WillUnmount(func)
	self.props.willUnmount = func
	return self
end

function PropSet:WillUpdate(func)
	self.props.willUpdate = func
	return self
end

function PropSet:ShouldUpdate(func)
	self.props.shouldUpdate = func
	return self
end

function PropSet:DidUpdate(func)
	self.props.didUpdate = func
	return self
end

--A small system which allows us to register external functions which modify the props of the element being built
function mod:RegisterModifier(name: string, func)
	assert(PropSet[name] == nil)
	
	PropSet[name] = function(self, ...)
		func(self, ...)
		return self
	end
end


local StandardElements = {}
local StandardElementsAwaiting = {}

function mod:NewElement(name, element_prototype)
	assert(StandardElements[name] == nil)
	
	StandardElements[name] = element_prototype
	
	if StandardElementsAwaiting[name] then
		for _, callback in StandardElementsAwaiting[name] do
			callback()
		end
		
		StandardElementsAwaiting[name] = nil
	end
end

function mod:Element(name, prop_set)
	if not StandardElements[name] then
		local signal = ClassicSignal.new()
		
		StandardElementsAwaiting[name] = StandardElementsAwaiting[name] or {}
		
		table.insert(StandardElementsAwaiting, function()
			signal:Fire()
		end)
		
		if signal.FireCount == 0 then
			signal:Wait(1)
		end
	end
	
	local element_prototype = StandardElements[name]

	-- 1) function elements have to read the props passed in
	-- 2) elements that are just trees will be deep-cloned and then have their highest most props automatically merged with this prop_set
	local element
	if typeof(element_prototype) == "function" then
		element = element_prototype(prop_set.props)
	else
		element = element_prototype:Clone()
		element:Overrides(prop_set.props)
	end

	return element
end

function mod:Binding(default)
	return Roact.createBinding(default)
end

function mod:JoinBindings(bindings)
	return Roact.joinBindings(bindings)
end

function mod:CreateRef()
	return Roact.createRef()
end

function mod:Mount(tree: Roact.ReactNodeList, parent: Instance)
	if parent:IsA("PlayerGui") then
		warn("createRoot will clear all children of the root instance, yet entire PlayerGui is the root")
	end

	local root = RoactRbx.createRoot(parent)
	root:render(tree)

	return root
end

function mod:Tween(start: number?)
	start = start or 0

	local binding = Roact.createBinding(start)
	return binding:makeTweenable()
end

-- Portal functionality
-- TODO: Test this with react 17 update
function mod:Portal(children: { Roact.Element<string> }, container: Instance, prop_set, opt_key: string?)
	local props = prop_set.props
	local element = RoactRbx.createPortal(children, container, props)
	
	return element
end

function mod:IsPositionInObject(position: Vector2, object: GuiBase2d)
	local topLeft = object.AbsolutePosition
	local bottomRight = topLeft + object.AbsoluteSize
	
	return position.X < bottomRight.X and position.X > topLeft.X and position.Y < bottomRight.Y and position.Y > topLeft.Y
end

function mod:IsScrollBarAtEnd(barRBX, damp)
	damp = damp or 1

	local maxYPosition = barRBX.AbsoluteCanvasSize.Y - barRBX.AbsoluteSize.Y
	local currentYPosition = barRBX.CanvasPosition.Y

	if currentYPosition + damp >= maxYPosition then-- add one to damp
		return true
	end
	
	return false
end

local ReactElement = require(script.lib.Roact._Index.React.React.ReactElement)
ReactElement.__set_pumpkin_mt({__index = PropSet})



-- Setup the I:<InstanceName> behavior
-- and the constructors for their props


-- differentiate between color3 and colorSequence
local function decodeColors(...): ColorSequence | Color3
	local args = {...}
	
	if type(args[1]) == "number" then
		if #args == 3 then
			return Color3.new(...)
		else
			local seq = {}
			
			for i = 1, #args, 2 do
				table.insert(seq, ColorSequenceKeypoint.new(args[i], args[i + 1]))
			end
			
			return ColorSequence.new(seq)
		end
	else
		-- Color3 was passed in
		return ...
	end
end

-- differentiate between float and float sequence
local function decodeNumbers(...): NumberSequence | number
	local args = {...}
	
	if #args == 1 then
		return ...
	else
		local seq = {}
		
		for i = 1, #args, 3 do
			table.insert(seq, NumberSequenceKeypoint.new(args[i], args[i + 1], args[i + 3]))
		end
		
		return NumberSequence.new(seq)
	end
end

-- differentiate between UDim2 and UDim
local function decodeUDims(...): UDim | UDim2
	local args = {...}
	
	if #args == 4 then
		return UDim2.new(...)
	elseif #args == 2 then
		return UDim.new(...)
	else
		return ...
	end
end

local function decodeEnum(enum): (string | EnumItem) -> EnumItem
	return function(arg: string | EnumItem): EnumItem
		if type(arg) == "userdata" then
			-- Enum passed directly
			return arg
		else
			-- string passed
			return enum[arg]
		end
	end
end

local TypeBindings = {
	Vector2 = Vector2.new,
	Vector3 = Vector3.new,
	Rect = Rect.new,
	
	-- Some classes have the same property names as other classes, but different types.
	-- we have to treat them as if they are the same type, and interpret the paramaters to differentiate bettwen types.
	ColorSequence = decodeColors,
	Color3 = decodeColors,
	
	float = decodeNumbers,
	NumberSequence = decodeNumbers,
	
	UDim = decodeUDims,
	UDim2 = decodeUDims,
	
	-- just for clarity, servers no interpretation purpose in the code.
	bool = "primitive",
	int = "primitive",
	string = "primitive",
	Content = "primitive",
	
	GuiObject = "reference",
	Instance = "reference",
	LocalizationTable = "reference",
	
	-- Roact.Event
	Event = "Event",
	
	-- overwritten below to functions that support strings
	[Enum.SelectionBehavior] = decodeEnum(Enum.SelectionBehavior),
	[Enum.BorderMode] = decodeEnum(Enum.BorderMode),
	[Enum.SizeConstraint] = decodeEnum(Enum.SizeConstraint),
	[Enum.FrameStyle] = decodeEnum(Enum.FrameStyle),
	[Enum.ResamplerMode] = decodeEnum(Enum.ResamplerMode),
	[Enum.ScaleType] = decodeEnum(Enum.ScaleType),
	[Enum.AutomaticSize] = decodeEnum(Enum.AutomaticSize),
	[Enum.ElasticBehavior] = decodeEnum(Enum.ElasticBehavior),
	[Enum.ScrollingDirection] = decodeEnum(Enum.ScrollingDirection),
	[Enum.ScrollBarInset] = decodeEnum(Enum.ScrollBarInset),
	[Enum.VerticalScrollBarPosition] = decodeEnum(Enum.VerticalScrollBarPosition),
	[Enum.TextTruncate] = decodeEnum(Enum.TextTruncate),
	[Enum.TextXAlignment] = decodeEnum(Enum.TextXAlignment),
	[Enum.TextYAlignment] = decodeEnum(Enum.TextYAlignment),
	[Enum.AspectType] = decodeEnum(Enum.AspectType),
	[Enum.DominantAxis] = decodeEnum(Enum.DominantAxis),
	[Enum.FillDirection] = decodeEnum(Enum.FillDirection),
	[Enum.HorizontalAlignment] = decodeEnum(Enum.HorizontalAlignment),
	[Enum.SortOrder] = decodeEnum(Enum.SortOrder),
	[Enum.VerticalAlignment] = decodeEnum(Enum.VerticalAlignment),
	[Enum.StartCorner] = decodeEnum(Enum.StartCorner),
	[Enum.EasingDirection] = decodeEnum(Enum.EasingDirection),
	[Enum.EasingStyle] = decodeEnum(Enum.EasingStyle),
	[Enum.TableMajorAxis] = decodeEnum(Enum.TableMajorAxis),
	[Enum.ApplyStrokeMode] = decodeEnum(Enum.ApplyStrokeMode),
	[Enum.LineJoinMode] = decodeEnum(Enum.LineJoinMode),
	[Enum.ZIndexBehavior] = decodeEnum(Enum.ZIndexBehavior),
}

local Classes = {
	GuiButton = {
		AutoButtonColor = "bool",
		Modal = "bool",
		Selected = "bool",
		Style = "Enum"
	},
	GuiBase2d = {
		Name = "string",
		AutoLocalize = "bool",
		RootLocalizationTable = "LocalizationTable",
		SelectionBehaviorDown = Enum.SelectionBehavior,
		SelectionBehaviorLeft = Enum.SelectionBehavior,
		SelectionBehaviorRight = Enum.SelectionBehavior,
		SelectionBehaviorUp = Enum.SelectionBehavior,
		SelectionGroup = "bool"
	},
	GuiObject = {
		SelectionImageObject = "GuiObject",
		ClipsDescendants = "bool",
		Draggable = "bool",
		Active = "bool",
		AnchorPoint = "Vector2",
		AutomaticSize = Enum.AutomaticSize,
		BackgroundColor3 = "Color3",
		BackgroundTransparency = "float",
		BorderColor3 = "Color3",
		BorderMode = Enum.BorderMode,
		BorderSizePixel = "int",
		LayoutOrder = "int",
		Position = "UDim2",
		Rotation = "float",
		Size = "UDim2",
		SizeConstraint = Enum.SizeConstraint,
		Transparency = "float",
		Visible = "bool",
		ZIndex = "int",
		NextSelectionDown = "GuiObject",
		NextSelectionLeft = "GuiObject",
		NextSelectionRight = "GuiObject",
		NextSelectionUp = "GuiObject",
		Selectable = "bool",
		SelectionOrder = "int",
		Activated = "Event",
		MouseButton1Click = "Event",
		MouseButton1Down = "Event",
		MouseEnter = "Event",
		MouseLeave = "Event",
		MouseButton1Up = "Event",
		MouseButton2Click = "Event",
		MouseButton2Down = "Event",
		MouseButton2Up = "Event",
		InputBegan = "Event",
		InputEnded = "Event",
		InputChanged = "Event",
		TouchLongPress = "Event",
		TouchPan = "Event",
		TouchPinch = "Event",
		TouchRotate = "Event",
		TouchSwipe = "Event",
		TouchTap = "Event",
	},
	CanvasGroup = {
		GroupColor3 = "Color3",
		GroupTransparency = "float"
	},
	Frame = {
		Name = "string"
	},
	ScreenGui = {
		DisplayOrder = "int",
		Enabled = "bool",
		IgnoreGuiInset = "bool",
		ResetOnSpawn = "bool",
		ZIndexBehavior = Enum.ZIndexBehavior,
	},
	BillboardGui = {
		Adornee = "Instance",
		AlwaysOnTop = "bool",
		LightInfluence = "float",
		Size = "UDim2",
		SizeOffset = "Vector2",
		StudsOffset = "Vector3",
		ExtentsOffsetWorldSpace = "Vector3",
		MaxDistance = "float",
	},
	ImageButton = {
		HoverImage = "Content",
		Image = "Content",
		ImageColor3 = "Color3",
		ImageRectOffset = "Vector2",
		ImageRectSize = "Vector2",
		ImageTransparency = "float",
		PressedImage = "Content",
		ResampleMode = Enum.ResamplerMode,
		ScaleType = Enum.ScaleType,
		SliceCenter = "Rect",
		SliceScale = "float",
		TileSize = "UDim2"
	},
	TextButton = {
		Font = "Font",
		FontFace = "Font",
		LineHeight = "float",
		MaxVisibleGraphemes = "int",
		RichText = "bool",
		Text = "string",
		TextColor3 = "Color3",
		TextScaled = "bool",
		TextSize = "float",
		TextStrokeColor3 = "Color3",
		TextStrokeTransparency = "float",
		TextTransparency = "float",
		TextTruncate = Enum.TextTruncate,
		TextWrapped = "bool",
		TextXAlignment = Enum.TextXAlignment,
		TextYAlignment = Enum.TextYAlignment
	},
	ImageLabel = {
		Image = "Content",
		ImageColor3 = "Color3",
		ImageRectOffset = "Vector2",
		ImageRectSize = "Vector2",
		ImageTransparency = "float",
		ResampleMode = Enum.ResamplerMode,
		ScaleType = Enum.ScaleType,
		SliceCenter = "Rect",
		SliceScale = "float",
		TileSize = "UDim2"
	},
	TextLabel = {
		Font = "Font",
		FontFace = "Font",
		LineHeight = "float",
		MaxVisibleGraphemes = "int",
		RichText = "bool",
		Text = "string",
		TextColor3 = "Color3",
		TextScaled = "bool",
		TextSize = "float",
		TextStrokeColor3 = "Color3",
		TextStrokeTransparency = "float",
		TextTransparency = "float",
		TextTruncate = Enum.TextTruncate,
		TextWrapped = "bool",
		TextXAlignment = Enum.TextXAlignment,
		TextYAlignment = Enum.TextYAlignment
	},
	ScrollingFrame = {
		AutomaticCanvasSize = Enum.AutomaticSize,
		BottomImage = "Content",
		CanvasPosition = "Vector2",
		CanvasSize = "UDim2",
		ElasticBehavior = Enum.ElasticBehavior,
		HorizontalScrollBarInset = Enum.ScrollBarInset,
		MidImage = "Content",
		ScrollBarImageColor3 = "Color3",
		ScrollBarImageTransparency = "float",
		ScrollBarThickness = "int",
		ScrollingDirection = Enum.ScrollingDirection,
		ScrollingEnabled = "bool",
		TopImage = "Content",
		VerticalScrollBarInset = Enum.ScrollBarInset,
		VerticalScrollBarPosition = Enum.VerticalScrollBarPosition
	},
	TextBox = {
		ClearTextOnFocus = "bool",
		CursorPosition = "int",
		MultiLine = "bool",
		SelectionStart = "int",
		ShowNativeInput = "bool",
		TextEditable = "bool",
		Font = "Font",
		FontFace = "Font",
		LineHeight = "float",
		MaxVisibleGraphemes = "int",
		PlaceholderColor3 = "Color3",
		PlaceholderText = "string",
		RichText = "bool",
		Text = "string",
		TextColor3 = "Color3",
		TextScaled = "bool",
		TextSize = "float",
		TextStrokeColor3 = "Color3",
		TextStrokeTransparency = "float",
		TextTransparency = "float",
		TextTruncate = Enum.TextTruncate,
		TextWrapped = "bool",
		TextXAlignment = Enum.TextXAlignment,
		TextYAlignment = Enum.TextYAlignment,
		FocusLost = "Event",
		Focused = "Event",
		ReturnPressedFromOnScreenKeyboard = "Event"
	},
	VideoFrame = {
		Looped = "bool",
		Playing = "bool",
		TimePosition = "float",
		Video = "Content",
		Volume = "float",
		DidLoop = "Event",
		Ended = "Event",
		Loaded = "Event",
		Paused = "Event",
		Played = "Event"
	},
	ViewportFrame = {
		Ambient = "Color3",
		LightColor = "Color3",
		LightDirection = "Vector3",
		CurrentCamera = "Camera",
		ImageColor3 = "Color3",
		ImageTransparency = "float"
	},

	UIGradient = {
		Color = "ColorSequence",
		Enabled = "bool",
		Offset = "Vector2",
		Rotation = "float",
		Transparency = "NumberSequence"
	},
	UICorner = {
		CornerRadius = "UDim",
	},
	UITextSizeConstraint = {
		MaxTextSize = "int",
		MinTextSize = "int",
	},
	UISizeConstraint = {
		MaxSize = "Vector2",
		MinSize = "Vector2",
	},
	UIAspectRatioConstraint = {
		AspectRatio = "float",
		AspectType = Enum.AspectType,
		DominantAxis = Enum.DominantAxis,
	},
	UIGridStyleLayout = {
		FillDirection = Enum.FillDirection,
		HorizontalAlignment = Enum.HorizontalAlignment,
		SortOrder = Enum.SortOrder,
		VerticalAlignment = Enum.VerticalAlignment,
	},
	UIGridLayout = {
		CellPadding = "UDim2",
		CellSize = "UDim2",
		FillDirectionMaxCells = "int",
		StartCorner = Enum.StartCorner,
	},
	UIListLayout = {
		Padding = "UDim"
	},
	UIPageLayout = {
		Animated = "bool",
		Circular = "bool",
		EasingDirection = Enum.EasingDirection,
		EasingStyle = Enum.EasingStyle,
		Padding = "UDim",
		TweenTime = "float",
		GamepadInputEnabled = "bool",
		ScrollWheelInputEnabled = "bool",
		TouchInputEnabled = "bool",
		PageEnter = "Event",
		PageLeave = "Event",
		Stopped = "Event"
	},
	UITableLayout = {
		FillEmptySpaceColumns = "bool",
		FillEmptySpaceRows = "bool",
		Padding = "UDim2",
		MajorAxis = Enum.TableMajorAxis
	},
	UIPadding = {
		PaddingBottom = "UDim",
		PaddingLeft = "UDim",
		PaddingRight = "UDim",
		PaddingTop = "UDim"
	},
	UIScale = {
		Scale = "float"
	},
	UIStroke = {
		ApplyStrokeMode = Enum.ApplyStrokeMode,
		Color = "Color3",
		LineJoinMode = Enum.LineJoinMode,
		Thickness = "float",
		Transparency = "float",
		Enabled = "bool"
	},
}

local RoactSymbols = Roact.Symbols

-- create :[propName]() functions
-- put in a function for type utility
local function build_prop_funcs(prop_target, mod_target)
	for class, properties in pairs(Classes) do
		for prop_name: string, _type in properties do
			local ctor = TypeBindings[_type]

			if typeof(rawget(prop_target, prop_name)) == "function" then
				continue
			end

			if type(ctor) == "function" then
				prop_target[prop_name] = function(_self, binding, ...)
					if typeof(binding) == "table" and binding["$$typeof"] == RoactSymbols.REACT_BINDING_TYPE then
						_self.props[prop_name] = binding
					else
						local value = ctor(binding, ...)
						_self.props[prop_name] = value
					end
					
					return _self
				end
			elseif ctor == "Event" then
				local event_key = Roact.Event[prop_name]
				prop_target[prop_name] = function(_self, value)
					_self.props[event_key] = value
					return _self
				end
			elseif ctor == "Change" then
				local event_key = Roact.Change[prop_name]
				prop_target[prop_name] = function(_self, value)
					_self.props[event_key] = value
					return _self
				end
			else
				prop_target[prop_name] = function(_self, value)
					_self.props[prop_name] = value
					return _self
				end
			end
		end

		mod_target[class] = function(_self, prop_set: table)
			local props = prop_set.props
			local element = Roact.createElement(class, props)
			
			return element
		end
	end

	return prop_target
end

build_prop_funcs(PropSet, mod)

return (mod :: any) :: PumpkinAPI