--// ============================================================
--// Modular Luau UI Library (self-contained, loadstring-ready)
--// ============================================================

local TweenService       = game:GetService("TweenService")
local UserInputService   = game:GetService("UserInputService")
local Players            = game:GetService("Players")
local CoreGuiService      = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local PlayerGui    = LocalPlayer:WaitForChild("PlayerGui")

local GUI_NAME = "Modular_UILibrary"

--// ------------------------------------------------------------
--// Cleanup: destroy any previous instance of this UI
--// ------------------------------------------------------------
local function GetGuiParent()
	local target
	local ok = pcall(function()
		target = gethui()
	end)
	if not (ok and target) then
		ok = pcall(function()
			target = CoreGuiService
		end)
	end
	if not (ok and target) then
		target = PlayerGui
	end
	return target
end

local function CleanupExisting()
	for _, container in ipairs({ CoreGuiService, PlayerGui, GetGuiParent() }) do
		local ok, existing = pcall(function()
			return container:FindFirstChild(GUI_NAME)
		end)
		if ok and existing then
			existing:Destroy()
		end
	end
end
CleanupExisting()

--// ------------------------------------------------------------
--// Constants
--// ------------------------------------------------------------
local COLORS = {
	Background    = Color3.fromRGB(255, 159, 85),
	BackgroundAlt = Color3.fromRGB(255, 169, 89),
	Stroke        = Color3.fromRGB(239, 134, 69),
	Accent        = Color3.fromRGB(98, 232, 71),
	Text          = Color3.fromRGB(255, 255, 255),
	Close         = Color3.fromRGB(72, 72, 243),
	SwitchOff     = Color3.fromRGB(90, 90, 90),
}

local TWEEN_FAST = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TWEEN_MED  = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TWEEN_DRAG = TweenInfo.new(0.05, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)

--// ------------------------------------------------------------
--// Utility helpers
--// ------------------------------------------------------------
local function Create(class, props, children)
	local inst = Instance.new(class)
	for prop, value in pairs(props or {}) do
		inst[prop] = value
	end
	for _, child in ipairs(children or {}) do
		child.Parent = inst
	end
	return inst
end

local function Tween(inst, info, props)
	local tween = TweenService:Create(inst, info, props)
	tween:Play()
	return tween
end

local function Round(inst, radius)
	Create("UICorner", { CornerRadius = radius or UDim.new(0.15, 0), Parent = inst })
end

local function Stroke(inst, color, thickness)
	Create("UIStroke", {
		Color = color or COLORS.Stroke,
		Thickness = thickness or 1.5,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = inst,
	})
end

local function Hoverify(button, baseColor, hoverColor)
	button.MouseEnter:Connect(function()
		Tween(button, TWEEN_FAST, { BackgroundColor3 = hoverColor })
	end)
	button.MouseLeave:Connect(function()
		Tween(button, TWEEN_FAST, { BackgroundColor3 = baseColor })
	end)
end

local function Draggify(handle, target)
	local dragging = false
	local dragInput, mousePos, framePos

	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			mousePos = input.Position
			framePos = target.Position

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	handle.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			local delta = input.Position - mousePos
			local newPos = UDim2.new(
				framePos.X.Scale, framePos.X.Offset + delta.X,
				framePos.Y.Scale, framePos.Y.Offset + delta.Y
			)
			Tween(target, TWEEN_DRAG, { Position = newPos })
		end
	end)
end

--// ------------------------------------------------------------
--// Library / Window / Tab metatables
--// ------------------------------------------------------------
local Library = {}
local WindowMeta = {}
WindowMeta.__index = WindowMeta
local TabMeta = {}
TabMeta.__index = TabMeta

--// ==============================================================
--// Library:CreateWindow
--// ==============================================================
function Library:CreateWindow(title)
	title = title or "Window"

	if self._gui then
		self._gui:Destroy()
		self._gui = nil
	end

	local ScreenGui = Create("ScreenGui", {
		Name = GUI_NAME,
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	})
	ScreenGui.Parent = GetGuiParent()
	self._gui = ScreenGui

	local Main = Create("Frame", {
		Name = "Main",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.45, 0.5),
		BackgroundColor3 = COLORS.Background,
		BorderSizePixel = 0,
		Parent = ScreenGui,
	})
	Round(Main, UDim.new(0.03, 0))
	Stroke(Main, COLORS.Stroke, 2)

	local TitleBar = Create("Frame", {
		Name = "TitleBar",
		Size = UDim2.new(1, 0, 0, 36),
		BackgroundColor3 = COLORS.BackgroundAlt,
		BorderSizePixel = 0,
		Parent = Main,
	})
	Round(TitleBar, UDim.new(0.3, 0))
	Stroke(TitleBar, COLORS.Stroke, 2)

	Create("TextLabel", {
		Text = title,
		Font = Enum.Font.GothamBold,
		TextSize = 18,
		TextColor3 = COLORS.Text,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -80, 1, 0),
		Position = UDim2.new(0, 12, 0, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = TitleBar,
	})

	local CloseButton = Create("TextButton", {
		Text = "X",
		Font = Enum.Font.GothamBold,
		TextSize = 16,
		TextColor3 = Color3.fromRGB(44, 44, 199),
		BackgroundColor3 = COLORS.Close,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		Size = UDim2.fromOffset(24, 24),
		AutoButtonColor = false,
		Parent = TitleBar,
	})
	Round(CloseButton, UDim.new(0.25, 0))
	Hoverify(CloseButton, COLORS.Close, Color3.fromRGB(255, 90, 90))

	local MinimizeButton = Create("TextButton", {
		Text = "_",
		Font = Enum.Font.GothamBold,
		TextSize = 16,
		TextColor3 = Color3.fromRGB(44, 44, 199),
		BackgroundColor3 = COLORS.Close,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -38, 0.5, 0),
		Size = UDim2.fromOffset(24, 24),
		AutoButtonColor = false,
		Parent = TitleBar,
	})
	Round(MinimizeButton, UDim.new(0.25, 0))
	Hoverify(MinimizeButton, COLORS.Close, Color3.fromRGB(120, 120, 255))

	Draggify(TitleBar, Main)

	local Sidebar = Create("Frame", {
		Name = "Sidebar",
		Size = UDim2.new(0.28, 0, 1, -44),
		Position = UDim2.new(0, 6, 0, 40),
		BackgroundColor3 = COLORS.BackgroundAlt,
		BorderSizePixel = 0,
		Parent = Main,
	})
	Round(Sidebar, UDim.new(0.05, 0))
	Stroke(Sidebar, COLORS.Stroke, 2)

	local SidebarList = Create("ScrollingFrame", {
		Size = UDim2.fromScale(0.92, 0.95),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Parent = Sidebar,
	})
	Create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 6),
		Parent = SidebarList,
	})

	local Content = Create("Frame", {
		Name = "Content",
		Size = UDim2.new(0.72, -6, 1, -48),
		Position = UDim2.new(0.28, 8, 0, 40),
		BackgroundColor3 = COLORS.BackgroundAlt,
		BorderSizePixel = 0,
		Parent = Main,
	})
	Round(Content, UDim.new(0.03, 0))
	Stroke(Content, COLORS.Stroke, 2)

	local Window = setmetatable({
		_screenGui = ScreenGui,
		_main = Main,
		_sidebar = SidebarList,
		_content = Content,
		_tabs = {},
		_activeTab = nil,
		_minimized = false,
		_fullSize = Main.Size,
	}, WindowMeta)

	CloseButton.MouseButton1Click:Connect(function()
		Library:Destroy()
	end)

	MinimizeButton.MouseButton1Click:Connect(function()
		Window._minimized = not Window._minimized
		if Window._minimized then
			Content.Visible = false
			Sidebar.Visible = false
			Tween(Main, TWEEN_MED, {
				Size = UDim2.new(Window._fullSize.X.Scale, Window._fullSize.X.Offset, 0, 40),
			})
		else
			Tween(Main, TWEEN_MED, { Size = Window._fullSize })
			task.delay(0.2, function()
				Content.Visible = true
				Sidebar.Visible = true
			end)
		end
	end)

	return Window
end

function Library:Destroy()
	if self._gui then
		self._gui:Destroy()
		self._gui = nil
	end
	CleanupExisting()
end

--// ==============================================================
--// WindowMeta:CreateTab
--// ==============================================================
function WindowMeta:CreateTab(name)
	name = name or "Tab"

	local TabButton = Create("TextButton", {
		Text = name,
		Font = Enum.Font.GothamSemibold,
		TextSize = 14,
		TextColor3 = COLORS.Text,
		BackgroundColor3 = COLORS.Background,
		Size = UDim2.new(1, 0, 0, 30),
		AutoButtonColor = false,
		Parent = self._sidebar,
	})
	Round(TabButton, UDim.new(0.2, 0))
	Stroke(TabButton, COLORS.Stroke, 1.5)
	Hoverify(TabButton, COLORS.Background, COLORS.BackgroundAlt)

	local Page = Create("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Visible = false,
		Parent = self._content,
	})
	Create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 8),
		Parent = Page,
	})
	Create("UIPadding", {
		PaddingTop = UDim.new(0, 10),
		PaddingLeft = UDim.new(0, 10),
		PaddingRight = UDim.new(0, 10),
		PaddingBottom = UDim.new(0, 10),
		Parent = Page,
	})

	local Tab = setmetatable({
		_window = self,
		_button = TabButton,
		_page = Page,
	}, TabMeta)

	TabButton.MouseButton1Click:Connect(function()
		self:_selectTab(Tab)
	end)

	table.insert(self._tabs, Tab)
	if not self._activeTab then
		self:_selectTab(Tab)
	end

	return Tab
end

function WindowMeta:_selectTab(tab)
	for _, t in ipairs(self._tabs) do
		t._page.Visible = (t == tab)
		Tween(t._button, TWEEN_FAST, {
			BackgroundColor3 = (t == tab) and COLORS.Accent or COLORS.Background,
		})
	end
	self._activeTab = tab
end

--// ==============================================================
--// TabMeta: components
--// ==============================================================
function TabMeta:CreateLabel(text)
	local Label = Create("TextLabel", {
		Text = text or "",
		Font = Enum.Font.GothamSemibold,
		TextSize = 14,
		TextColor3 = COLORS.Text,
		BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		Size = UDim2.new(1, 0, 0, 24),
		Parent = self._page,
	})
	return {
		Set = function(_, newText) Label.Text = newText end,
	}
end

function TabMeta:CreateButton(text, callback)
	callback = callback or function() end

	local Button = Create("TextButton", {
		Text = text or "Button",
		Font = Enum.Font.GothamSemibold,
		TextSize = 14,
		TextColor3 = COLORS.Text,
		BackgroundColor3 = COLORS.Background,
		Size = UDim2.new(1, 0, 0, 34),
		AutoButtonColor = false,
		Parent = self._page,
	})
	Round(Button, UDim.new(0.15, 0))
	Stroke(Button, COLORS.Stroke, 1.5)
	Hoverify(Button, COLORS.Background, COLORS.BackgroundAlt)

	Button.MouseButton1Down:Connect(function()
		Tween(Button, TWEEN_FAST, { Size = UDim2.new(1, -6, 0, 32) })
	end)
	Button.MouseButton1Up:Connect(function()
		Tween(Button, TWEEN_FAST, { Size = UDim2.new(1, 0, 0, 34) })
	end)
	Button.MouseButton1Click:Connect(function()
		callback()
	end)

	return Button
end

function TabMeta:CreateToggle(text, default, callback)
	default = default or false
	callback = callback or function() end

	local Holder = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundColor3 = COLORS.Background,
		Parent = self._page,
	})
	Round(Holder, UDim.new(0.15, 0))
	Stroke(Holder, COLORS.Stroke, 1.5)

	Create("TextLabel", {
		Text = text or "Toggle",
		Font = Enum.Font.GothamSemibold,
		TextSize = 14,
		TextColor3 = COLORS.Text,
		BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, -60, 1, 0),
		Position = UDim2.new(0, 10, 0, 0),
		Parent = Holder,
	})

	local Switch = Create("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(40, 20),
		BackgroundColor3 = default and COLORS.Accent or COLORS.SwitchOff,
		Parent = Holder,
	})
	Round(Switch, UDim.new(0.5, 0))

	local Knob = Create("Frame", {
		Size = UDim2.fromOffset(16, 16),
		Position = default and UDim2.new(1, -18, 0.5, 0) or UDim2.new(0, 2, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		Parent = Switch,
	})
	Round(Knob, UDim.new(0.5, 0))

	local ClickArea = Create("TextButton", {
		Text = "",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Parent = Holder,
	})

	local state = default

	local function setState(newState, fire)
		state = newState
		Tween(Switch, TWEEN_FAST, { BackgroundColor3 = state and COLORS.Accent or COLORS.SwitchOff })
		Tween(Knob, TWEEN_FAST, { Position = state and UDim2.new(1, -18, 0.5, 0) or UDim2.new(0, 2, 0.5, 0) })
		if fire then callback(state) end
	end

	ClickArea.MouseButton1Click:Connect(function()
		setState(not state, true)
	end)

	return {
		Set = function(_, value) setState(value, true) end,
		Get = function() return state end,
	}
end

function TabMeta:CreateSlider(text, min, max, default, callback)
	min = min or 0
	max = max or 100
	default = math.clamp(default or min, min, max)
	callback = callback or function() end

	local Holder = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 46),
		BackgroundColor3 = COLORS.Background,
		Parent = self._page,
	})
	Round(Holder, UDim.new(0.1, 0))
	Stroke(Holder, COLORS.Stroke, 1.5)

	Create("TextLabel", {
		Text = text or "Slider",
		Font = Enum.Font.GothamSemibold,
		TextSize = 13,
		TextColor3 = COLORS.Text,
		BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, -60, 0, 18),
		Position = UDim2.new(0, 10, 0, 4),
		Parent = Holder,
	})

	local ValueLabel = Create("TextLabel", {
		Text = tostring(default),
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		TextColor3 = COLORS.Text,
		BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Right,
		Size = UDim2.new(0, 50, 0, 18),
		Position = UDim2.new(1, -55, 0, 4),
		Parent = Holder,
	})

	local Track = Create("Frame", {
		Size = UDim2.new(1, -20, 0, 6),
		Position = UDim2.new(0, 10, 1, -14),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.5,
		Parent = Holder,
	})
	Round(Track, UDim.new(1, 0))

	local alpha0 = (default - min) / (max - min)
	local Fill = Create("Frame", {
		Size = UDim2.new(alpha0, 0, 1, 0),
		BackgroundColor3 = COLORS.Accent,
		Parent = Track,
	})
	Round(Fill, UDim.new(1, 0))

	local Dragger = Create("TextButton", {
		Text = "",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(alpha0, 0, 0.5, 0),
		Size = UDim2.fromOffset(14, 14),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		AutoButtonColor = false,
		Parent = Track,
	})
	Round(Dragger, UDim.new(0.5, 0))
	Stroke(Dragger, COLORS.Stroke, 1.5)

	local value = default
	local dragging = false

	local function updateFromX(inputX)
		local trackPos, trackSize = Track.AbsolutePosition.X, Track.AbsoluteSize.X
		local a = math.clamp((inputX - trackPos) / trackSize, 0, 1)
		value = math.floor(min + (max - min) * a + 0.5)
		a = (value - min) / (max - min)
		Fill.Size = UDim2.new(a, 0, 1, 0)
		Dragger.Position = UDim2.new(a, 0, 0.5, 0)
		ValueLabel.Text = tostring(value)
		callback(value)
	end

	Dragger.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then
			updateFromX(input.Position.X)
		end
	end)
	Track.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			updateFromX(input.Position.X)
		end
	end)

	return {
		Set = function(_, newValue)
			newValue = math.clamp(newValue, min, max)
			local a = (newValue - min) / (max - min)
			value = newValue
			Fill.Size = UDim2.new(a, 0, 1, 0)
			Dragger.Position = UDim2.new(a, 0, 0.5, 0)
			ValueLabel.Text = tostring(newValue)
		end,
		Get = function() return value end,
	}
end

function TabMeta:CreateDropdown(text, options, callback)
	options = options or {}
	callback = callback or function() end

	local Holder = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundColor3 = COLORS.Background,
		ClipsDescendants = false,
		ZIndex = 2,
		Parent = self._page,
	})
	Round(Holder, UDim.new(0.15, 0))
	Stroke(Holder, COLORS.Stroke, 1.5)

	Create("TextLabel", {
		Text = text or "Dropdown",
		Font = Enum.Font.GothamSemibold,
		TextSize = 14,
		TextColor3 = COLORS.Text,
		BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(0.5, 0, 1, 0),
		Position = UDim2.new(0, 10, 0, 0),
		Parent = Holder,
	})

	local Selected = options[1]

	local SelectButton = Create("TextButton", {
		Text = tostring(Selected or "Select"),
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		TextColor3 = COLORS.Text,
		BackgroundColor3 = COLORS.BackgroundAlt,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		Size = UDim2.new(0.42, 0, 0, 24),
		AutoButtonColor = false,
		ZIndex = 3,
		Parent = Holder,
	})
	Round(SelectButton, UDim.new(0.2, 0))
	Stroke(SelectButton, COLORS.Stroke, 1.5)

	local ListFrame = Create("ScrollingFrame", {
		Size = UDim2.new(0.42, 0, 0, math.clamp(#options, 1, 4) * 26),
		Position = UDim2.new(1, -8, 1, 4),
		AnchorPoint = Vector2.new(1, 0),
		BackgroundColor3 = COLORS.BackgroundAlt,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		Visible = false,
		ZIndex = 5,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Parent = Holder,
	})
	Round(ListFrame, UDim.new(0.1, 0))
	Stroke(ListFrame, COLORS.Stroke, 1.5)
	Create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = ListFrame,
	})

	for _, option in ipairs(options) do
		local OptionButton = Create("TextButton", {
			Text = tostring(option),
			Font = Enum.Font.Gotham,
			TextSize = 13,
			TextColor3 = COLORS.Text,
			BackgroundColor3 = COLORS.BackgroundAlt,
			Size = UDim2.new(1, 0, 0, 26),
			AutoButtonColor = false,
			ZIndex = 5,
			Parent = ListFrame,
		})
		Hoverify(OptionButton, COLORS.BackgroundAlt, COLORS.Background)

		OptionButton.MouseButton1Click:Connect(function()
			Selected = option
			SelectButton.Text = tostring(option)
			ListFrame.Visible = false
			callback(option)
		end)
	end

	SelectButton.MouseButton1Click:Connect(function()
		ListFrame.Visible = not ListFrame.Visible
	end)

	return {
		Set = function(_, option)
			Selected = option
			SelectButton.Text = tostring(option)
		end,
		Get = function() return Selected end,
	}
end

--// ==============================================================
--// Example usage (documentation only)
--// ==============================================================
--[[
local Library = loadstring(game:HttpGet("RAW_GITHUB_URL"))()

local Window = Library:CreateWindow("Settings")

local Gameplay = Window:CreateTab("Gameplay")
Gameplay:CreateToggle("Blur", true, function(state) end)
Gameplay:CreateToggle("Color correction", false, function(state) end)
Gameplay:CreateSlider("Latency", 0, 200, 50, function(value) end)
Gameplay:CreateDropdown("Game quality", {"Low", "Normal", "High"}, function(option) end)
Gameplay:CreateButton("Reset Settings", function() end)

local Sounds = Window:CreateTab("Sounds")
Sounds:CreateToggle("Bell sound", true, function(state) end)
Sounds:CreateSlider("UI sounds", 0, 100, 75, function(value) end)
]]

return Library
