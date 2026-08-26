local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local TextService = game:GetService("TextService")

local LocalPlayer = Players.LocalPlayer

local Theme = {
	Background = Color3.fromRGB(8, 12, 8),
	Surface = Color3.fromRGB(12, 20, 12),
	SurfaceAlt = Color3.fromRGB(18, 30, 18),
	Border = Color3.fromRGB(0, 200, 80),
	BorderDim = Color3.fromRGB(0, 80, 30),
	Accent = Color3.fromRGB(0, 255, 100),
	AccentDim = Color3.fromRGB(0, 140, 55),
	TextPrimary = Color3.fromRGB(0, 255, 100),
	TextSecondary = Color3.fromRGB(0, 180, 70),
	TextDisabled = Color3.fromRGB(0, 80, 30),
	Danger = Color3.fromRGB(255, 50, 50),
	SliderFill = Color3.fromRGB(0, 220, 90),
	SliderTrack = Color3.fromRGB(15, 35, 15),
	ToggleOn = Color3.fromRGB(0, 220, 90),
	ToggleOff = Color3.fromRGB(20, 40, 20),
	ToggleKnob = Color3.fromRGB(200, 255, 210),
	Scanline = Color3.fromRGB(0, 255, 100),
	TabActive = Color3.fromRGB(0, 200, 75),
	TabInactive = Color3.fromRGB(0, 45, 18),
	TitleBar = Color3.fromRGB(6, 16, 6),
	CornerRadius = UDim.new(0, 4),
	BorderThickness = 1,
	FontMono = Enum.Font.Code,
	FontUI = Enum.Font.GothamMedium,
	FontBold = Enum.Font.GothamBold,
	TextSizeTitle = 15,
	TextSizeBody = 13,
	TextSizeSmall = 11,
	Tween = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	TweenSlow = TweenInfo.new(0.32, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
}

local function getIconAsset(iconInput)
	if not iconInput or iconInput == "" then
		return ""
	end

	if type(iconInput) == "number" or (type(iconInput) == "string" and tonumber(iconInput)) then
		return "rbxassetid://" .. tostring(iconInput)
	end

	if type(iconInput) ~= "string" then
		return tostring(iconInput)
	end

	if iconInput:find("rbxasset") or iconInput:find("rbxthumb") then
		return iconInput
	end

	if iconInput:find("http://") or iconInput:find("https://") then
		if not (writefile and getcustomasset and game.HttpGet) then
			return ""
		end

		local safeName = "plasma_cache_" .. iconInput:gsub("[^%w]", "_"):sub(-40) .. ".png"

		if isfile and isfile(safeName) then
			local ok, result = pcall(getcustomasset, safeName)
			if ok then
				return result
			end
		end

		local ok, result = pcall(function()
			local bytes = game:HttpGet(iconInput)
			writefile(safeName, bytes)
			return getcustomasset(safeName)
		end)

		return ok and result or ""
	end

	if isfile and isfile(iconInput) and getcustomasset then
		local ok, result = pcall(getcustomasset, iconInput)
		if ok then
			return result
		end
	end

	return tostring(iconInput)
end

local function tw(object, properties, info)
	local ok, tween = pcall(function()
		return TweenService:Create(object, info or Theme.Tween, properties)
	end)

	if ok and tween then
		tween:Play()
	end

	return tween
end

local function Decorate(object, radius, strokeColor, strokeThickness)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = radius or Theme.CornerRadius
	corner.Parent = object

	if strokeColor ~= false then
		local stroke = Instance.new("UIStroke")
		stroke.Color = strokeColor or Theme.BorderDim
		stroke.Thickness = strokeThickness or Theme.BorderThickness
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		stroke.Parent = object
	end
end

local function NewLabel(data)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.TextColor3 = data.Color or Theme.TextPrimary
	label.Font = data.Font or Theme.FontUI
	label.TextSize = data.Size2 or Theme.TextSizeBody
	label.Text = data.Text or ""
	label.TextXAlignment = data.AlignX or Enum.TextXAlignment.Left
	label.TextYAlignment = data.AlignY or Enum.TextYAlignment.Center
	label.TextTruncate = data.Truncate or Enum.TextTruncate.AtEnd
	label.Size = data.Size or UDim2.new(1, 0, 1, 0)
	label.Position = data.Pos or UDim2.new()
	label.ZIndex = data.Z or 5
	label.RichText = data.Rich or false
	label.Parent = data.Parent
	return label
end

local function NewFrame(data)
	local frame = Instance.new("Frame")
	frame.BackgroundColor3 = data.Color or Theme.Surface
	frame.BackgroundTransparency = data.Trans or 0
	frame.BorderSizePixel = 0
	frame.Size = data.Size or UDim2.new(1, 0, 1, 0)
	frame.Position = data.Pos or UDim2.new()
	frame.ZIndex = data.Z or 4
	frame.ClipsDescendants = data.Clip or false
	frame.Name = data.Name or "Frame"
	frame.Parent = data.Parent
	return frame
end

local function AddScanlines(parent, count)
	local overlay = Instance.new("Frame")
	overlay.BackgroundTransparency = 1
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.ZIndex = 60
	overlay.BorderSizePixel = 0
	overlay.Name = "Scanlines"
	overlay.Parent = parent

	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.new(1, 0, 0, 2)
	grid.CellPadding = UDim2.new(0, 0, 0, 2)
	grid.Parent = overlay

	for _ = 1, count do
		local line = Instance.new("Frame")
		line.BackgroundColor3 = Theme.Scanline
		line.BackgroundTransparency = 0.965
		line.BorderSizePixel = 0
		line.Parent = overlay
	end
end

local function GuiParent()
	if gethui then
		local ok, result = pcall(gethui)
		if ok and result then
			return result
		end
	end

	local ok, coreGui = pcall(function()
		return game:GetService("CoreGui")
	end)

	if ok and coreGui then
		return coreGui
	end

	return LocalPlayer:WaitForChild("PlayerGui")
end

local function MakeDraggable(handle, target, track)
	local active = false
	local origin = Vector2.zero
	local startPosition = target.Position

	local function clampPosition(position)
		local camera = workspace.CurrentCamera
		local viewport = camera and camera.ViewportSize or Vector2.new(1920, 1080)
		local size = target.AbsoluteSize
		local minimumVisible = 44

		local minimumX = minimumVisible - size.X - viewport.X * position.X.Scale
		local maximumX = viewport.X - minimumVisible - viewport.X * position.X.Scale
		local minimumY = -viewport.Y * position.Y.Scale
		local maximumY = viewport.Y - minimumVisible - viewport.Y * position.Y.Scale

		return UDim2.new(
			position.X.Scale,
			math.clamp(position.X.Offset, minimumX, maximumX),
			position.Y.Scale,
			math.clamp(position.Y.Offset, minimumY, maximumY)
		)
	end

	local inputBegan = handle.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end

		active = true
		origin = input.Position
		startPosition = target.Position

		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				active = false
			end
		end)
	end)

	local inputChanged = UserInputService.InputChanged:Connect(function(input)
		if not active then
			return
		end

		if input.UserInputType ~= Enum.UserInputType.MouseMovement
			and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end

		local delta = input.Position - origin

		target.Position = clampPosition(UDim2.new(
			startPosition.X.Scale,
			startPosition.X.Offset + delta.X,
			startPosition.Y.Scale,
			startPosition.Y.Offset + delta.Y
		))
	end)

	if track then
		track(inputBegan)
		track(inputChanged)
	end
end

local function GetPlayerFromInstance(instance)
	if not instance then
		return nil
	end

	local current = instance

	while current and current ~= workspace do
		if current:IsA("Model") then
			local player = Players:GetPlayerFromCharacter(current)

			if player and player ~= LocalPlayer then
				return player
			end
		end

		current = current.Parent
	end

	return nil
end

local function PointInside(object, position)
	if not object or not object.Visible then
		return false
	end

	local absolutePosition = object.AbsolutePosition
	local absoluteSize = object.AbsoluteSize

	return position.X >= absolutePosition.X
		and position.X <= absolutePosition.X + absoluteSize.X
		and position.Y >= absolutePosition.Y
		and position.Y <= absolutePosition.Y + absoluteSize.Y
end

local Library = {}
Library.__index = Library

function Library:CreateWindow(options)
	options = options or {}

	local title = options.Title or "PlasmaLibUI"
	local icon = getIconAsset(options.IconId or "7072706620")
	local width = options.Width or 500
	local height = options.Height or 380
	local scanlines = options.Scanlines ~= false
	local toggleKey = options.ToggleKey
	local playerContextEnabled = options.PlayerContextMenu == true
	local playerContextDefaults = options.PlayerContextActions

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "PlasmaLibUI_" .. title:gsub("%s", "")
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.IgnoreGuiInset = true
	screenGui.DisplayOrder = 999
	screenGui.Parent = GuiParent()

	local windowFrame = NewFrame({
		Name = "Window",
		Color = Theme.Background,
		Size = UDim2.new(0, width, 0, 0),
		Pos = UDim2.new(0.5, -width / 2, 0.5, -height / 2),
		Clip = true,
		Z = 2,
		Parent = screenGui,
	})

	Decorate(windowFrame, UDim.new(0, 0), Theme.Border, 1)

	if scanlines then
		AddScanlines(windowFrame, math.clamp(math.floor(height / 4), 20, 80))
	end

	NewFrame({
		Color = Theme.Accent,
		Size = UDim2.new(1, 0, 0, 2),
		Z = 6,
		Parent = windowFrame,
	})

	local connections = {}

	local function track(connection)
		table.insert(connections, connection)
		return connection
	end

	local Window = {
		ScreenGui = screenGui,
		Frame = windowFrame,
	}

	local titleBar = NewFrame({
		Name = "TitleBar",
		Color = Theme.TitleBar,
		Size = UDim2.new(1, 0, 0, 38),
		Pos = UDim2.new(0, 0, 0, 2),
		Z = 5,
		Parent = windowFrame,
	})

	local iconImage = Instance.new("ImageLabel")
	iconImage.BackgroundTransparency = 1
	iconImage.Size = UDim2.new(0, 22, 0, 22)
	iconImage.Position = UDim2.new(0, 8, 0.5, -11)
	iconImage.Image = icon
	iconImage.ImageColor3 = Theme.Accent
	iconImage.ZIndex = 7
	iconImage.Parent = titleBar

	NewLabel({
		Text = ("[ %s ]"):format(title:upper()),
		Color = Theme.Accent,
		Font = Theme.FontMono,
		Size2 = Theme.TextSizeTitle,
		Size = UDim2.new(1, -104, 1, 0),
		Pos = UDim2.new(0, 38, 0, 0),
		Z = 7,
		Parent = titleBar,
	})

	local closeButton = Instance.new("TextButton")
	closeButton.BackgroundColor3 = Color3.fromRGB(28, 8, 8)
	closeButton.Size = UDim2.new(0, 28, 0, 20)
	closeButton.Position = UDim2.new(1, -34, 0.5, -10)
	closeButton.Text = "X"
	closeButton.Font = Theme.FontBold
	closeButton.TextSize = 13
	closeButton.TextColor3 = Theme.Danger
	closeButton.BorderSizePixel = 0
	closeButton.AutoButtonColor = false
	closeButton.ZIndex = 8
	closeButton.Parent = titleBar

	Decorate(closeButton, UDim.new(0, 3), Theme.Danger, 1)

	track(closeButton.MouseEnter:Connect(function()
		tw(closeButton, {
			BackgroundColor3 = Theme.Danger,
			TextColor3 = Color3.new(1, 1, 1)
		})
	end))

	track(closeButton.MouseLeave:Connect(function()
		tw(closeButton, {
			BackgroundColor3 = Color3.fromRGB(28, 8, 8),
			TextColor3 = Theme.Danger
		})
	end))

	track(closeButton.MouseButton1Click:Connect(function()
		Window:Destroy()
	end))

	local minimizeButton = Instance.new("TextButton")
	minimizeButton.BackgroundColor3 = Theme.Surface
	minimizeButton.Size = UDim2.new(0, 28, 0, 20)
	minimizeButton.Position = UDim2.new(1, -66, 0.5, -10)
	minimizeButton.Text = "_"
	minimizeButton.Font = Theme.FontBold
	minimizeButton.TextSize = 15
	minimizeButton.TextColor3 = Theme.Accent
	minimizeButton.BorderSizePixel = 0
	minimizeButton.AutoButtonColor = false
	minimizeButton.ZIndex = 8
	minimizeButton.Parent = titleBar

	Decorate(minimizeButton, UDim.new(0, 3), Theme.Border, 1)

	track(minimizeButton.MouseEnter:Connect(function()
		tw(minimizeButton, {
			BackgroundColor3 = Theme.SurfaceAlt
		})
	end))

	track(minimizeButton.MouseLeave:Connect(function()
		tw(minimizeButton, {
			BackgroundColor3 = Theme.Surface
		})
	end))

	MakeDraggable(titleBar, windowFrame, track)

	local tabBar = Instance.new("ScrollingFrame")
	tabBar.Name = "TabBar"
	tabBar.BackgroundColor3 = Theme.TitleBar
	tabBar.BorderSizePixel = 0
	tabBar.Size = UDim2.new(1, 0, 0, 30)
	tabBar.Position = UDim2.new(0, 0, 0, 40)
	tabBar.ZIndex = 5
	tabBar.ScrollingDirection = Enum.ScrollingDirection.X
	tabBar.ScrollBarThickness = 2
	tabBar.ScrollBarImageColor3 = Theme.AccentDim
	tabBar.CanvasSize = UDim2.new()
	tabBar.AutomaticCanvasSize = Enum.AutomaticSize.X
	tabBar.Parent = windowFrame

	local tabBarLayout = Instance.new("UIListLayout")
	tabBarLayout.FillDirection = Enum.FillDirection.Horizontal
	tabBarLayout.SortOrder = Enum.SortOrder.LayoutOrder
	tabBarLayout.Padding = UDim.new(0, 2)
	tabBarLayout.Parent = tabBar

	local tabBarPadding = Instance.new("UIPadding")
	tabBarPadding.PaddingLeft = UDim.new(0, 4)
	tabBarPadding.Parent = tabBar

	local contentTop = 71
	local statusHeight = 18

	local contentArea = NewFrame({
		Name = "ContentArea",
		Color = Theme.Background,
		Size = UDim2.new(1, 0, 1, -(contentTop + statusHeight)),
		Pos = UDim2.new(0, 0, 0, contentTop),
		Z = 3,
		Parent = windowFrame,
	})

	local statusBar = NewFrame({
		Name = "StatusBar",
		Color = Theme.TitleBar,
		Size = UDim2.new(1, 0, 0, statusHeight),
		Pos = UDim2.new(0, 0, 1, -statusHeight),
		Z = 5,
		Parent = windowFrame,
	})

	NewLabel({
		Text = "◈ PLASMA // READY",
		Color = Theme.BorderDim,
		Font = Theme.FontMono,
		Size2 = 10,
		AlignX = Enum.TextXAlignment.Center,
		Z = 6,
		Parent = statusBar,
	})

	local minimized = false

	track(minimizeButton.MouseButton1Click:Connect(function()
		minimized = not minimized

		if minimized then
			tabBar.Visible = false
			contentArea.Visible = false
			statusBar.Visible = false
			tw(windowFrame, {
				Size = UDim2.new(0, width, 0, 40)
			}, Theme.TweenSlow)
		else
			tabBar.Visible = true
			contentArea.Visible = true
			statusBar.Visible = true
			tw(windowFrame, {
				Size = UDim2.new(0, width, 0, height)
			}, Theme.TweenSlow)
		end
	end))

	if toggleKey then
		track(UserInputService.InputBegan:Connect(function(input, processed)
			if processed then
				return
			end

			if input.KeyCode == toggleKey then
				windowFrame.Visible = not windowFrame.Visible
			end
		end))
	end

	local tabs = {}
	local activeTab = nil

	function Window:CreateTab(name)
		name = tostring(name or "Tab")

		local tabButton = Instance.new("TextButton")
		tabButton.BackgroundColor3 = Theme.TabInactive
		tabButton.Size = UDim2.new(0, math.max(70, TextService:GetTextSize(name, Theme.TextSizeSmall, Theme.FontMono, Vector2.new(300, 20)).X + 20), 1, 0)
		tabButton.Text = "[ " .. name:upper() .. " ]"
		tabButton.Font = Theme.FontMono
		tabButton.TextSize = Theme.TextSizeSmall
		tabButton.TextColor3 = Theme.TextSecondary
		tabButton.BorderSizePixel = 0
		tabButton.AutoButtonColor = false
		tabButton.ZIndex = 7
		tabButton.Parent = tabBar

		Decorate(tabButton, UDim.new(0, 3), Theme.BorderDim, 1)

		local scrolling = Instance.new("ScrollingFrame")
		scrolling.Name = name .. "_Content"
		scrolling.BackgroundTransparency = 1
		scrolling.BorderSizePixel = 0
		scrolling.Size = UDim2.new(1, -8, 1, -8)
		scrolling.Position = UDim2.new(0, 4, 0, 4)
		scrolling.ScrollBarThickness = 3
		scrolling.ScrollBarImageColor3 = Theme.AccentDim
		scrolling.CanvasSize = UDim2.new()
		scrolling.AutomaticCanvasSize = Enum.AutomaticSize.Y
		scrolling.Visible = false
		scrolling.ZIndex = 4
		scrolling.Parent = contentArea

		local layout = Instance.new("UIListLayout")
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Padding = UDim.new(0, 4)
		layout.Parent = scrolling

		local padding = Instance.new("UIPadding")
		padding.PaddingTop = UDim.new(0, 2)
		padding.PaddingBottom = UDim.new(0, 8)
		padding.PaddingLeft = UDim.new(0, 2)
		padding.PaddingRight = UDim.new(0, 2)
		padding.Parent = scrolling

		local Tab = {
			Name = name,
			Container = scrolling,
			Window = Window
		}

		function Tab:Select()
			for _, entry in ipairs(tabs) do
				entry.Container.Visible = false
				tw(entry.Button, {
					BackgroundColor3 = Theme.TabInactive,
					TextColor3 = Theme.TextSecondary
				})
			end

			scrolling.Visible = true
			tw(tabButton, {
				BackgroundColor3 = Theme.TabActive,
				TextColor3 = Theme.TextPrimary
			})

			activeTab = Tab
		end

		function Tab:CreateSection(text)
			local section = NewFrame({
				Color = Theme.Surface,
				Size = UDim2.new(1, 0, 0, 24),
				Z = 5,
				Parent = scrolling
			})

			Decorate(section, UDim.new(0, 3), Theme.BorderDim, 1)

			NewLabel({
				Text = "[ " .. tostring(text):upper() .. " ]",
				Color = Theme.Accent,
				Font = Theme.FontMono,
				Size2 = Theme.TextSizeSmall,
				Pos = UDim2.new(0, 8, 0, 0),
				Size = UDim2.new(1, -16, 1, 0),
				Z = 6,
				Parent = section
			})

			return section
		end

		local function createElement(height)
			local frame = NewFrame({
				Color = Theme.TitleBar,
				Size = UDim2.new(1, 0, 0, height),
				Z = 5,
				Parent = scrolling
			})

			Decorate(frame, UDim.new(0, 3), Theme.BorderDim, 1)
			return frame
		end

		function Tab:CreateLabel(text)
			local element = createElement(32)

			NewLabel({
				Text = tostring(text),
				Color = Theme.TextSecondary,
				Font = Theme.FontMono,
				Size2 = Theme.TextSizeSmall,
				Pos = UDim2.new(0, 8, 0, 0),
				Size = UDim2.new(1, -16, 1, 0),
				Z = 6,
				Parent = element
			})

			return element
		end

		function Tab:CreateButton(options)
			options = options or {}

			local label = options.Label or "Button"
			local callback = options.Callback or function() end

			local button = Instance.new("TextButton")
			button.BackgroundColor3 = Theme.Surface
			button.Size = UDim2.new(1, 0, 0, 32)
			button.Text = "[ " .. tostring(label):upper() .. " ]"
			button.Font = Theme.FontMono
			button.TextSize = Theme.TextSizeSmall
			button.TextColor3 = Theme.Accent
			button.BorderSizePixel = 0
			button.AutoButtonColor = false
			button.ZIndex = 6
			button.Parent = scrolling

			Decorate(button, UDim.new(0, 3), Theme.BorderDim, 1)

			track(button.MouseEnter:Connect(function()
				tw(button, {
					BackgroundColor3 = Theme.SurfaceAlt,
					TextColor3 = Theme.TextPrimary
				})
			end))

			track(button.MouseLeave:Connect(function()
				tw(button, {
					BackgroundColor3 = Theme.Surface,
					TextColor3 = Theme.Accent
				})
			end))

			track(button.MouseButton1Click:Connect(function()
				pcall(callback)
			end))

			return button
		end

		function Tab:CreateToggle(options)
			options = options or {}

			local label = options.Label or "Toggle"
			local value = options.Default == true
			local callback = options.Callback or function() end

			local element = createElement(38)

			NewLabel({
				Text = label,
				Color = Theme.TextPrimary,
				Font = Theme.FontUI,
				Size2 = Theme.TextSizeBody,
				Size = UDim2.new(0.68, 0, 1, 0),
				Z = 6,
				Parent = element
			})

			local switch = Instance.new("TextButton")
			switch.BackgroundColor3 = value and Theme.ToggleOn or Theme.ToggleOff
			switch.Size = UDim2.new(0, 46, 0, 20)
			switch.Position = UDim2.new(1, -54, 0.5, -10)
			switch.Text = ""
			switch.BorderSizePixel = 0
			switch.AutoButtonColor = false
			switch.ZIndex = 7
			switch.Parent = element

			Decorate(switch, UDim.new(0, 10), Theme.BorderDim, 1)

			local knob = NewFrame({
				Color = Theme.ToggleKnob,
				Size = UDim2.new(0, 14, 0, 14),
				Pos = value and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7),
				Z = 8,
				Parent = switch
			})

			Decorate(knob, UDim.new(0, 7), false)

			local Toggle = {}

			local function apply(newValue, fire)
				value = newValue == true

				tw(switch, {
					BackgroundColor3 = value and Theme.ToggleOn or Theme.ToggleOff
				})

				tw(knob, {
					Position = value
						and UDim2.new(1, -17, 0.5, -7)
						or UDim2.new(0, 3, 0.5, -7)
				})

				if fire then
					pcall(callback, value)
				end
			end

			track(switch.MouseButton1Click:Connect(function()
				apply(not value, true)
			end))

			function Toggle:Set(newValue)
				apply(newValue, true)
			end

			function Toggle:Get()
				return value
			end

			return Toggle
		end

		function Tab:CreateSlider(options)
			options = options or {}

			local label = options.Label or "Slider"
			local minimum = options.Min or 0
			local maximum = options.Max or 100
			local step = options.Step or 1
			local value = math.clamp(options.Default or minimum, minimum, maximum)
			local callback = options.Callback or function() end

			local element = createElement(48)

			NewLabel({
				Text = label,
				Color = Theme.TextPrimary,
				Font = Theme.FontUI,
				Size2 = Theme.TextSizeBody,
				Size = UDim2.new(0.48, 0, 0, 22),
				Pos = UDim2.new(0, 8, 0, 1),
				Z = 6,
				Parent = element
			})

			local valueLabel = NewLabel({
				Text = tostring(value),
				Color = Theme.Accent,
				Font = Theme.FontMono,
				Size2 = Theme.TextSizeSmall,
				AlignX = Enum.TextXAlignment.Right,
				Size = UDim2.new(0.25, 0, 0, 22),
				Pos = UDim2.new(0.67, 0, 0, 1),
				Z = 6,
				Parent = element
			})

			local trackFrame = NewFrame({
				Color = Theme.SliderTrack,
				Size = UDim2.new(0.94, 0, 0, 8),
				Pos = UDim2.new(0.03, 0, 1, -14),
				Z = 7,
				Parent = element
			})

			Decorate(trackFrame, UDim.new(0, 4), Theme.BorderDim, 1)

			local fill = NewFrame({
				Color = Theme.SliderFill,
				Size = UDim2.new((value - minimum) / (maximum - minimum), 0, 1, 0),
				Z = 8,
				Parent = trackFrame
			})

			Decorate(fill, UDim.new(0, 4), false)

			local knob = NewFrame({
				Color = Theme.Accent,
				Size = UDim2.new(0, 14, 0, 14),
				Pos = UDim2.new((value - minimum) / (maximum - minimum), -7, 0.5, -7),
				Z = 9,
				Parent = trackFrame
			})

			Decorate(knob, UDim.new(0, 7), Theme.Background, 1)

			local dragging = false

			local function updateFromX(x, fire)
				local percentage = math.clamp(
					(x - trackFrame.AbsolutePosition.X) / trackFrame.AbsoluteSize.X,
					0,
					1
				)

				local raw = minimum + (maximum - minimum) * percentage
				value = math.clamp(
					math.floor((raw - minimum) / step + 0.5) * step + minimum,
					minimum,
					maximum
				)

				local normalized = (value - minimum) / (maximum - minimum)

				tw(fill, {
					Size = UDim2.new(normalized, 0, 1, 0)
				})

				tw(knob, {
					Position = UDim2.new(normalized, -7, 0.5, -7)
				})

				valueLabel.Text = tostring(value)

				if fire then
					pcall(callback, value)
				end
			end

			track(trackFrame.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1
					or input.UserInputType == Enum.UserInputType.Touch then
					dragging = true
					updateFromX(input.Position.X, true)
				end
			end))

			track(UserInputService.InputChanged:Connect(function(input)
				if not dragging then
					return
				end

				if input.UserInputType == Enum.UserInputType.MouseMovement
					or input.UserInputType == Enum.UserInputType.Touch then
					updateFromX(input.Position.X, true)
				end
			end))

			track(UserInputService.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1
					or input.UserInputType == Enum.UserInputType.Touch then
					dragging = false
				end
			end))

			local Slider = {}

			function Slider:Set(newValue)
				updateFromX(
					trackFrame.AbsolutePosition.X
						+ math.clamp((newValue - minimum) / (maximum - minimum), 0, 1) * trackFrame.AbsoluteSize.X,
					true
				)
			end

			function Slider:Get()
				return value
			end

			return Slider
		end

		function Tab:CreateDropdown(options)
			options = options or {}

			local label = options.Label or "Dropdown"
			local choices = options.Options or {}
			local selected = options.Default or choices[1] or "None"
			local callback = options.Callback or function() end
			local open = false
			local outsideConnection

			local element = createElement(38)
			element.ClipsDescendants = false

			NewLabel({
				Text = label,
				Color = Theme.TextPrimary,
				Font = Theme.FontUI,
				Size2 = Theme.TextSizeBody,
				Size = UDim2.new(0.44, 0, 1, 0),
				Z = 6,
				Parent = element
			})

			local dropdownButton = Instance.new("TextButton")
			dropdownButton.BackgroundColor3 = Theme.Surface
			dropdownButton.Size = UDim2.new(0.53, 0, 0, 26)
			dropdownButton.Position = UDim2.new(0.46, 0, 0.5, -13)
			dropdownButton.Text = ("  %s  ▾"):format(tostring(selected))
			dropdownButton.Font = Theme.FontMono
			dropdownButton.TextSize = Theme.TextSizeSmall
			dropdownButton.TextColor3 = Theme.Accent
			dropdownButton.BorderSizePixel = 0
			dropdownButton.AutoButtonColor = false
			dropdownButton.ZIndex = 7
			dropdownButton.ClipsDescendants = false
			dropdownButton.Parent = element

			Decorate(dropdownButton, UDim.new(0, 4), Theme.Border, 1)

			local listFrame = NewFrame({
				Color = Theme.TitleBar,
				Size = UDim2.new(1, 0, 0, 0),
				Pos = UDim2.new(0, 0, 1, 4),
				Z = 22,
				Clip = true,
				Parent = dropdownButton
			})

			listFrame.Visible = false
			Decorate(listFrame, UDim.new(0, 4), Theme.Border, 1)

			local list = Instance.new("ScrollingFrame")
			list.BackgroundTransparency = 1
			list.Size = UDim2.new(1, 0, 1, 0)
			list.ScrollBarThickness = 3
			list.ScrollBarImageColor3 = Theme.AccentDim
			list.BorderSizePixel = 0
			list.ZIndex = 23
			list.Parent = listFrame

			local listLayout = Instance.new("UIListLayout")
			listLayout.SortOrder = Enum.SortOrder.LayoutOrder
			listLayout.Parent = list

			local function close()
				if not open then
					return
				end

				open = false
				element.ZIndex = 5

				tw(listFrame, {
					Size = UDim2.new(1, 0, 0, 0)
				})

				task.delay(0.16, function()
					if not open then
						listFrame.Visible = false
					end
				end)

				if outsideConnection then
					outsideConnection:Disconnect()
					outsideConnection = nil
				end
			end

			local function rebuild()
				for _, child in ipairs(list:GetChildren()) do
					if child:IsA("TextButton") then
						child:Destroy()
					end
				end

				for index, choice in ipairs(choices) do
					local button = Instance.new("TextButton")
					button.BackgroundColor3 = Theme.TitleBar
					button.Size = UDim2.new(1, 0, 0, 28)
					button.Text = "  " .. tostring(choice)
					button.Font = Theme.FontMono
					button.TextSize = Theme.TextSizeSmall
					button.TextColor3 = Theme.TextSecondary
					button.TextXAlignment = Enum.TextXAlignment.Left
					button.BorderSizePixel = 0
					button.AutoButtonColor = false
					button.LayoutOrder = index
					button.ZIndex = 24
					button.Parent = list

					track(button.MouseEnter:Connect(function()
						tw(button, {
							BackgroundColor3 = Theme.Surface,
							TextColor3 = Theme.TextPrimary
						})
					end))

					track(button.MouseLeave:Connect(function()
						tw(button, {
							BackgroundColor3 = Theme.TitleBar,
							TextColor3 = Theme.TextSecondary
						})
					end))

					track(button.MouseButton1Click:Connect(function()
						selected = choice
						dropdownButton.Text = ("  %s  ▾"):format(tostring(selected))
						pcall(callback, selected)
						close()
					end))
				end
			end

			local function openDropdown()
				open = true
				element.ZIndex = 50
				listFrame.Visible = true

				local visibleCount = math.min(#choices, 6)
				local targetHeight = visibleCount * 28

				list.CanvasSize = UDim2.new(0, 0, 0, #choices * 28)

				tw(listFrame, {
					Size = UDim2.new(1, 0, 0, targetHeight)
				})

				outsideConnection = UserInputService.InputBegan:Connect(function(input)
					if input.UserInputType ~= Enum.UserInputType.MouseButton1
						and input.UserInputType ~= Enum.UserInputType.Touch then
						return
					end

					local position = input.Position

					if not PointInside(listFrame, position)
						and not PointInside(dropdownButton, position) then
						close()
					end
				end)
			end

			rebuild()

			track(dropdownButton.MouseButton1Click:Connect(function()
				if open then
					close()
				else
					openDropdown()
				end
			end))

			local Dropdown = {}

			function Dropdown:Set(value)
				selected = value
				dropdownButton.Text = ("  %s  ▾"):format(tostring(selected))
				pcall(callback, selected)
			end

			function Dropdown:Get()
				return selected
			end

			function Dropdown:Refresh(newChoices)
				choices = newChoices or {}
				rebuild()
			end

			function Dropdown:SetOptions(newChoices)
				choices = newChoices or {}
				rebuild()
			end

			return Dropdown
		end

		function Tab:CreateTextInput(options)
			options = options or {}

			local label = options.Label or "Input"
			local placeholder = options.Placeholder or "type here..."
			local callback = options.Callback or function() end

			local element = createElement(38)

			NewLabel({
				Text = label,
				Color = Theme.TextPrimary,
				Font = Theme.FontUI,
				Size2 = Theme.TextSizeBody,
				Size = UDim2.new(0.38, 0, 1, 0),
				Z = 6,
				Parent = element
			})

			local box = Instance.new("TextBox")
			box.BackgroundColor3 = Theme.Surface
			box.Size = UDim2.new(0.58, 0, 0, 26)
			box.Position = UDim2.new(0.40, 0, 0.5, -13)
			box.Text = ""
			box.PlaceholderText = placeholder
			box.PlaceholderColor3 = Theme.TextDisabled
			box.Font = Theme.FontMono
			box.TextSize = Theme.TextSizeSmall
			box.TextColor3 = Theme.Accent
			box.BorderSizePixel = 0
			box.ZIndex = 7
			box.ClearTextOnFocus = false
			box.Parent = element

			Decorate(box, UDim.new(0, 4), Theme.Border, 1)

			local padding = Instance.new("UIPadding")
			padding.PaddingLeft = UDim.new(0, 6)
			padding.Parent = box

			track(box.Focused:Connect(function()
				tw(box, {
					BackgroundColor3 = Theme.SurfaceAlt
				})
			end))

			track(box.FocusLost:Connect(function(enterPressed)
				tw(box, {
					BackgroundColor3 = Theme.Surface
				})

				pcall(callback, box.Text, enterPressed)
			end))

			local Input = {}

			function Input:Get()
				return box.Text
			end

			function Input:Set(value)
				box.Text = tostring(value)
			end

			return Input
		end

		table.insert(tabs, {
			Button = tabButton,
			Container = scrolling,
			Object = Tab
		})

		track(tabButton.MouseButton1Click:Connect(function()
			Tab:Select()
		end))

		if not activeTab then
			Tab:Select()
		end

		return Tab
	end

	local PlayerContext = {
		Enabled = playerContextEnabled,
		Target = nil,
		Actions = {},
		Open = false,
		Frame = nil
	}

	Window.PlayerContext = PlayerContext

	local contextFrame
	local contextActions
	local contextHeader
	local contextPlayerLabel
	local contextOutsideConnection
	local contextScreenConnection

	local function destroyContextButtons()
		if not contextActions then
			return
		end

		for _, child in ipairs(contextActions:GetChildren()) do
			if child:IsA("TextButton") then
				child:Destroy()
			end
		end
	end

	local function closePlayerContext(immediate)
		if not contextFrame or not PlayerContext.Open then
			return
		end

		PlayerContext.Open = false

		if contextOutsideConnection then
			contextOutsideConnection:Disconnect()
			contextOutsideConnection = nil
		end

		if contextScreenConnection then
			contextScreenConnection:Disconnect()
			contextScreenConnection = nil
		end

		if immediate then
			contextFrame.Visible = false
			contextFrame.Size = UDim2.new(0, 210, 0, 0)
			return
		end

		tw(contextFrame, {
			Size = UDim2.new(0, 210, 0, 0)
		})

		task.delay(0.18, function()
			if not PlayerContext.Open and contextFrame then
				contextFrame.Visible = false
			end
		end)
	end

	local function buildPlayerContext()
		destroyContextButtons()

		local count = 0

		for _, action in ipairs(PlayerContext.Actions) do
			if type(action) == "table"
				and type(action.Label) == "string"
				and type(action.Callback) == "function" then

				count += 1

				local button = Instance.new("TextButton")
				button.Name = "ContextAction_" .. count
				button.BackgroundColor3 = Theme.Surface
				button.Size = UDim2.new(1, 0, 0, 31)
				button.Text = "[ " .. action.Label:upper() .. " ]"
				button.Font = Theme.FontMono
				button.TextSize = Theme.TextSizeSmall
				button.TextColor3 = Theme.Accent
				button.TextXAlignment = Enum.TextXAlignment.Left
				button.BorderSizePixel = 0
				button.AutoButtonColor = false
				button.LayoutOrder = count
				button.ZIndex = 106
				button.Parent = contextActions

				Decorate(button, UDim.new(0, 3), Theme.BorderDim, 1)

				local padding = Instance.new("UIPadding")
				padding.PaddingLeft = UDim.new(0, 8)
				padding.Parent = button

				track(button.MouseEnter:Connect(function()
					tw(button, {
						BackgroundColor3 = Theme.SurfaceAlt,
						TextColor3 = Theme.TextPrimary
					})
				end))

				track(button.MouseLeave:Connect(function()
					tw(button, {
						BackgroundColor3 = Theme.Surface,
						TextColor3 = Theme.Accent
					})
				end))

				track(button.MouseButton1Click:Connect(function()
					local target = PlayerContext.Target

					if not target then
						closePlayerContext()
						return
					end

					pcall(action.Callback, target)
					closePlayerContext()
				end))
			end
		end

		return count
	end

	local function openPlayerContext(player, position)
		if not PlayerContext.Enabled or not contextFrame then
			return
		end

		if not player or player == LocalPlayer then
			return
		end

		if not player.Parent then
			return
		end

		local camera = workspace.CurrentCamera
		local viewport = camera and camera.ViewportSize or Vector2.new(1920, 1080)

		PlayerContext.Target = player
		PlayerContext.Open = true

		contextPlayerLabel.Text = "[ " .. player.Name:upper() .. " ]"

		local actionCount = buildPlayerContext()

		local height = 40 + math.max(actionCount * 34 + 6, 38)

		local x = math.clamp(position.X + 6, 4, viewport.X - 214)
		local y = math.clamp(position.Y + 6, 4, viewport.Y - height - 4)

		contextFrame.Position = UDim2.fromOffset(x, y)
		contextFrame.Size = UDim2.new(0, 210, 0, 0)
		contextFrame.Visible = true

		tw(contextFrame, {
			Size = UDim2.new(0, 210, 0, height)
		})

		contextOutsideConnection = UserInputService.InputBegan:Connect(function(input)
			if input.UserInputType ~= Enum.UserInputType.MouseButton1
				and input.UserInputType ~= Enum.UserInputType.MouseButton2
				and input.UserInputType ~= Enum.UserInputType.Touch then
				return
			end

			if not PointInside(contextFrame, input.Position) then
				closePlayerContext()
			end
		end)

		contextScreenConnection = UserInputService.InputChanged:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement then
				if not PlayerContext.Open then
					return
				end

				local currentCamera = workspace.CurrentCamera
				local currentViewport = currentCamera and currentCamera.ViewportSize or Vector2.new(1920, 1080)
				local currentSize = contextFrame.AbsoluteSize

				local nx = math.clamp(input.Position.X + 6, 4, currentViewport.X - currentSize.X - 4)
				local ny = math.clamp(input.Position.Y + 6, 4, currentViewport.Y - currentSize.Y - 4)

				if math.abs(nx - contextFrame.Position.X.Offset) > 60
					or math.abs(ny - contextFrame.Position.Y.Offset) > 60 then
					closePlayerContext()
				end
			end
		end)
	end

	function PlayerContext:AddAction(options)
		assert(type(options) == "table", "PlayerContext:AddAction expects a table")
		assert(type(options.Label) == "string", "PlayerContext:AddAction requires Label")
		assert(type(options.Callback) == "function", "PlayerContext:AddAction requires Callback")

		local action = {
			Label = options.Label,
			Callback = options.Callback
		}

		table.insert(PlayerContext.Actions, action)

		if PlayerContext.Open then
			local currentTarget = PlayerContext.Target
			local currentPosition = contextFrame.AbsolutePosition

			closePlayerContext(true)

			task.defer(function()
				if currentTarget and currentTarget.Parent then
					openPlayerContext(currentTarget, currentPosition)
				end
			end)
		end

		return action
	end

	function PlayerContext:RemoveAction(label)
		for index = #self.Actions, 1, -1 do
			if self.Actions[index].Label == label then
				table.remove(self.Actions, index)
			end
		end
	end

	function PlayerContext:ClearActions()
		table.clear(self.Actions)
		destroyContextButtons()
	end

	function PlayerContext:SetEnabled(state)
		self.Enabled = state == true

		if not self.Enabled then
			closePlayerContext(true)
		end
	end

	function PlayerContext:GetTarget()
		return self.Target
	end

	function PlayerContext:Close()
		closePlayerContext()
	end

	if playerContextEnabled then
		contextFrame = NewFrame({
			Name = "PlayerContextMenu",
			Color = Theme.TitleBar,
			Size = UDim2.new(0, 210, 0, 0),
			Pos = UDim2.new(0, 0, 0, 0),
			Z = 100,
			Clip = true,
			Parent = screenGui
		})

		contextFrame.Visible = false
		Decorate(contextFrame, UDim.new(0, 4), Theme.Border, 1)

		NewFrame({
			Color = Theme.Accent,
			Size = UDim2.new(1, 0, 0, 2),
			Z = 110,
			Parent = contextFrame
		})

		local playerHeader = NewFrame({
			Name = "Header",
			Color = Theme.Surface,
			Size = UDim2.new(1, 0, 0, 36),
			Pos = UDim2.new(0, 0, 0, 2),
			Z = 105,
			Parent = contextFrame
		})

		Decorate(playerHeader, UDim.new(0, 3), Theme.BorderDim, 1)

		contextPlayerLabel = NewLabel({
			Text = "[ PLAYER ]",
			Color = Theme.Accent,
			Font = Theme.FontMono,
			Size2 = Theme.TextSizeSmall,
			Pos = UDim2.new(0, 8, 0, 0),
			Size = UDim2.new(1, -16, 1, 0),
			Z = 106,
			Parent = playerHeader
		})

		contextActions = Instance.new("Frame")
		contextActions.Name = "Actions"
		contextActions.BackgroundTransparency = 1
		contextActions.Size = UDim2.new(1, -8, 1, -42)
		contextActions.Position = UDim2.new(0, 4, 0, 40)
		contextActions.BorderSizePixel = 0
		contextActions.ZIndex = 106
		contextActions.Parent = contextFrame

		local contextLayout = Instance.new("UIListLayout")
		contextLayout.SortOrder = Enum.SortOrder.LayoutOrder
		contextLayout.Padding = UDim.new(0, 3)
		contextLayout.Parent = contextActions

		if type(playerContextDefaults) == "table" then
			for _, action in ipairs(playerContextDefaults) do
				if type(action) == "table" then
					if type(action.Label) == "string" and type(action.Callback) == "function" then
						PlayerContext:AddAction(action)
					end
				end
			end
		end

		track(UserInputService.InputBegan:Connect(function(input, processed)
			if processed or not PlayerContext.Enabled then
				return
			end

			if input.UserInputType ~= Enum.UserInputType.MouseButton2 then
				return
			end

			local mousePosition = input.Position
			local camera = workspace.CurrentCamera

			if not camera then
				return
			end

			local unitRay = camera:ViewportPointToRay(mousePosition.X, mousePosition.Y)

			local raycastParams = RaycastParams.new()
			raycastParams.FilterType = Enum.RaycastFilterType.Exclude

			local ignored = {}

			if LocalPlayer.Character then
				table.insert(ignored, LocalPlayer.Character)
			end

			raycastParams.FilterDescendantsInstances = ignored

			local result = workspace:Raycast(
				unitRay.Origin,
				unitRay.Direction * 2000,
				raycastParams
			)

			if not result or not result.Instance then
				closePlayerContext()
				return
			end

			local player = GetPlayerFromInstance(result.Instance)

			if not player or player == LocalPlayer then
				closePlayerContext()
				return
			end

			openPlayerContext(player, mousePosition)
		end))
	end

	function Window:SetPlayerContextEnabled(state)
		PlayerContext:SetEnabled(state)
	end

	function Window:GetPlayerContext()
		return PlayerContext
	end

	function Window:Destroy()
		closePlayerContext(true)

		for _, connection in ipairs(connections) do
			pcall(function()
				connection:Disconnect()
			end)
		end

		table.clear(connections)

		if screenGui then
			screenGui:Destroy()
		end
	end

	tw(windowFrame, {
		Size = UDim2.new(0, width, 0, height)
	}, Theme.TweenSlow)

	return Window
end

function Library:SetTheme(overrides)
	if type(overrides) ~= "table" then
		return
	end

	for key, value in pairs(overrides) do
		if Theme[key] ~= nil then
			Theme[key] = value
		end
	end
end

function Library:GetTheme()
	return Theme
end

return Library
