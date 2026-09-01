local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local TextService = game:GetService("TextService")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")

local LocalPlayer = Players.LocalPlayer

local Theme = {
    Background = Color3.fromRGB(7, 10, 8),
    Surface = Color3.fromRGB(11, 17, 12),
    SurfaceAlt = Color3.fromRGB(16, 25, 17),
    SurfaceBright = Color3.fromRGB(22, 34, 23),
    Border = Color3.fromRGB(0, 220, 90),
    BorderDim = Color3.fromRGB(0, 84, 32),
    Accent = Color3.fromRGB(0, 255, 105),
    AccentDim = Color3.fromRGB(0, 155, 62),
    TextPrimary = Color3.fromRGB(219, 255, 228),
    TextSecondary = Color3.fromRGB(0, 205, 82),
    TextMuted = Color3.fromRGB(78, 125, 88),
    TextDisabled = Color3.fromRGB(39, 70, 46),
    Danger = Color3.fromRGB(255, 74, 74),
    Warning = Color3.fromRGB(255, 190, 50),
    Info = Color3.fromRGB(75, 170, 255),
    Success = Color3.fromRGB(80, 255, 145),
    SliderTrack = Color3.fromRGB(16, 36, 19),
    SliderFill = Color3.fromRGB(0, 225, 92),
    ToggleOn = Color3.fromRGB(0, 220, 88),
    ToggleOff = Color3.fromRGB(19, 40, 22),
    ToggleKnob = Color3.fromRGB(220, 255, 226),
    TabActive = Color3.fromRGB(0, 200, 75),
    TabInactive = Color3.fromRGB(0, 42, 17),
    TitleBar = Color3.fromRGB(6, 13, 7),
    Tooltip = Color3.fromRGB(8, 14, 9),
    Console = Color3.fromRGB(5, 8, 6),
    CornerRadius = UDim.new(0, 5),
    BorderThickness = 1,
    FontMono = Enum.Font.Code,
    FontUI = Enum.Font.GothamMedium,
    FontBold = Enum.Font.GothamBold,
    TextSizeTitle = 15,
    TextSizeBody = 13,
    TextSizeSmall = 11,
    Tween = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    TweenFast = TweenInfo.new(0.09, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    TweenSlow = TweenInfo.new(0.26, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
}

local Library = {Version = "3.0.0", Theme = Theme}
Library.__index = Library

local function safeCall(fn, ...)
    if type(fn) ~= "function" then
        return false, nil
    end
    return pcall(fn, ...)
end

local function tween(instance, properties, info)
    if not instance or not instance.Parent then
        return nil
    end
    local ok, tw = pcall(TweenService.Create, TweenService, instance, info or Theme.Tween, properties)
    if ok and tw then
        tw:Play()
        return tw
    end
    return nil
end

local function addConnection(list, connection)
    if connection then
        table.insert(list, connection)
    end
    return connection
end

local function disconnectAll(list)
    for i = #list, 1, -1 do
        local connection = list[i]
        if connection then
            pcall(connection.Disconnect, connection)
        end
        list[i] = nil
    end
end

local function decorate(object, radius, strokeColor, thickness)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = radius or Theme.CornerRadius
    corner.Parent = object
    if strokeColor ~= false then
        local stroke = Instance.new("UIStroke")
        stroke.Color = strokeColor or Theme.BorderDim
        stroke.Thickness = thickness or Theme.BorderThickness
        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        stroke.Parent = object
    end
    return corner
end

local function addPadding(parent, left, right, top, bottom)
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, left or 0)
    padding.PaddingRight = UDim.new(0, right or left or 0)
    padding.PaddingTop = UDim.new(0, top or 0)
    padding.PaddingBottom = UDim.new(0, bottom or top or 0)
    padding.Parent = parent
    return padding
end

local function newFrame(data)
    local frame = Instance.new("Frame")
    frame.Name = data.Name or "Frame"
    frame.BackgroundColor3 = data.Color or Theme.Surface
    frame.BackgroundTransparency = data.Trans or 0
    frame.BorderSizePixel = 0
    frame.Size = data.Size or UDim2.fromScale(1, 1)
    frame.Position = data.Pos or UDim2.fromOffset(0, 0)
    frame.ZIndex = data.Z or 1
    frame.Visible = data.Visible ~= false
    frame.ClipsDescendants = data.Clip == true
    frame.Parent = data.Parent
    return frame
end

local function newLabel(data)
    local label = Instance.new("TextLabel")
    label.Name = data.Name or "Label"
    label.BackgroundTransparency = 1
    label.Text = data.Text or ""
    label.TextColor3 = data.Color or Theme.TextPrimary
    label.Font = data.Font or Theme.FontUI
    label.TextSize = data.Size2 or Theme.TextSizeBody
    label.TextXAlignment = data.AlignX or Enum.TextXAlignment.Left
    label.TextYAlignment = data.AlignY or Enum.TextYAlignment.Center
    label.TextTruncate = data.Truncate or Enum.TextTruncate.AtEnd
    label.RichText = data.Rich == true
    label.TextWrapped = data.Wrap == true
    label.Size = data.Size or UDim2.fromScale(1, 1)
    label.Position = data.Pos or UDim2.fromOffset(0, 0)
    label.ZIndex = data.Z or 5
    label.Parent = data.Parent
    return label
end

local function getGuiParent()
    local gethuiFn = rawget(_G, "gethui")
    if type(gethuiFn) ~= "function" then
        gethuiFn = nil
    end
    if type(gethuiFn) == "function" then
        local ok, gui = pcall(gethuiFn)
        if ok and gui then
            return gui
        end
    end
    local okCore, core = pcall(game.GetService, game, "CoreGui")
    if okCore and core then
        return core
    end
    return LocalPlayer:WaitForChild("PlayerGui")
end

local function getIconAsset(input)
    if input == nil or input == "" then
        return ""
    end
    if type(input) == "number" then
        return "rbxassetid://" .. tostring(input)
    end
    if type(input) ~= "string" then
        return tostring(input)
    end
    if tonumber(input) then
        return "rbxassetid://" .. input
    end
    return input
end

local function clampViewportPosition(target, position)
    local camera = workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize or Vector2.new(1920, 1080)
    local size = target.AbsoluteSize
    local margin = 8
    local x = math.clamp(position.X, margin, math.max(margin, viewport.X - size.X - margin))
    local y = math.clamp(position.Y, margin, math.max(margin, viewport.Y - size.Y - margin))
    return Vector2.new(x, y)
end

local function createRipple(parent, position, color)
    local dot = Instance.new("Frame")
    dot.AnchorPoint = Vector2.new(0.5, 0.5)
    dot.Position = UDim2.fromOffset(position.X, position.Y)
    dot.Size = UDim2.fromOffset(0, 0)
    dot.BackgroundColor3 = color or Theme.Accent
    dot.BackgroundTransparency = 0.35
    dot.BorderSizePixel = 0
    dot.ZIndex = 300
    dot.Parent = parent
    decorate(dot, UDim.new(1, 0), false)
    tween(dot, {Size = UDim2.fromOffset(160, 160), BackgroundTransparency = 1}, Theme.TweenSlow)
    task.delay(0.27, function()
        if dot.Parent then
            dot:Destroy()
        end
    end)
end

local function makeDraggable(handle, target, track, onChanged)
    local dragging = false
    local origin = Vector2.zero
    local start = target.Position
    addConnection(track, handle.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end
        dragging = true
        origin = input.Position
        start = target.Position
        addConnection(track, input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end))
    end))
    addConnection(track, UserInputService.InputChanged:Connect(function(input)
        if not dragging then
            return
        end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end
        local delta = input.Position - origin
        local candidate = UDim2.new(start.X.Scale, start.X.Offset + delta.X, start.Y.Scale, start.Y.Offset + delta.Y)
        target.Position = candidate
        if onChanged then
            safeCall(onChanged, target.Position)
        end
    end))
end

local function getMousePosition()
    local ok, position = pcall(UserInputService.GetMouseLocation, UserInputService)
    if ok and position then
        return Vector2.new(position.X, position.Y)
    end
    return Vector2.zero
end

local function formatNumber(value, decimals)
    decimals = decimals == nil and 2 or decimals
    local rounded = math.floor(value * 10 ^ decimals + 0.5) / 10 ^ decimals
    if decimals <= 0 then
        return tostring(math.floor(rounded + 0.5))
    end
    local text = string.format("%0." .. decimals .. "f", rounded)
    text = text:gsub("(%..-)0+$", "%1"):gsub("%.$", "")
    return text
end

function Library:CreateWindow(options)
    options = options or {}
    local title = tostring(options.Title or "PlasmaLibUI")
    local width = math.clamp(tonumber(options.Width) or 620, 320, 1100)
    local height = math.clamp(tonumber(options.Height) or 430, 240, 900)
    local toggleKey = options.ToggleKey
    local scanlines = options.Scanlines == true
    local resizable = options.Resizable ~= false
    local centered = options.Center ~= false
    local themeBefore = {}
    for key, value in pairs(Theme) do
        themeBefore[key] = value
    end
    for key, value in pairs(options.Theme or {}) do
        if Theme[key] ~= nil then
            Theme[key] = value
        end
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = "PlasmaLibUI_" .. title:gsub("[^%w]", "")
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.DisplayOrder = tonumber(options.DisplayOrder) or 999
    gui.Parent = getGuiParent()

    local root = newFrame({
        Name = "Window",
        Color = Theme.Background,
        Size = UDim2.fromOffset(width, 0),
        Pos = centered and UDim2.new(0.5, -width / 2, 0.5, -height / 2) or UDim2.fromOffset(24, 24),
        Clip = true,
        Z = 10,
        Parent = gui,
    })
    decorate(root, UDim.new(0, 6), Theme.Border, 1)

    local rootStroke = root:FindFirstChildOfClass("UIStroke")
    if rootStroke then
        rootStroke.Transparency = 0.12
    end

    local destroyed = false
    local minimized = false
    local maximized = false
    local tabs = {}
    local currentTab = nil
    local connections = {}
    local windowElements = {}
    local activePopupCloser
    local previousSize = UDim2.fromOffset(width, height)
    local previousPosition = root.Position

    local function track(c)
        return addConnection(connections, c)
    end

    local function registerElement(element)
        table.insert(windowElements, element)
        return element
    end

    local function setRootSize(newWidth, newHeight)
        width = math.clamp(tonumber(newWidth) or width, 320, 1200)
        height = math.clamp(tonumber(newHeight) or height, 240, 900)
        previousSize = UDim2.fromOffset(width, height)
        tween(root, {Size = previousSize}, Theme.TweenSlow)
    end

    local titleBar = newFrame({
        Name = "TitleBar",
        Color = Theme.TitleBar,
        Size = UDim2.new(1, 0, 0, 40),
        Pos = UDim2.fromOffset(0, 2),
        Z = 20,
        Parent = root,
    })

    local topAccent = newFrame({
        Name = "TopAccent",
        Color = Theme.Accent,
        Size = UDim2.new(1, 0, 0, 2),
        Z = 25,
        Parent = root,
    })

    if scanlines then
        local overlay = newFrame({Name = "Scanlines", Trans = 1, Z = 100, Parent = root})
        local grid = Instance.new("UIGridLayout")
        grid.CellSize = UDim2.new(1, 0, 0, 2)
        grid.CellPadding = UDim2.new(0, 0, 0, 2)
        grid.Parent = overlay
        for _ = 1, math.clamp(math.floor(height / 4), 20, 120) do
            newFrame({Color = Theme.Accent, Trans = 0.975, Size = UDim2.new(1, 0, 0, 2), Parent = overlay})
        end
    end

    local icon = Instance.new("ImageLabel")
    icon.Name = "Icon"
    icon.BackgroundTransparency = 1
    icon.Size = UDim2.fromOffset(22, 22)
    icon.Position = UDim2.fromOffset(9, 9)
    icon.Image = getIconAsset(options.IconId or "")
    icon.ImageColor3 = Theme.Accent
    icon.ZIndex = 24
    icon.Parent = titleBar

    local titleLabel = newLabel({
        Name = "Title",
        Text = "[ " .. title:upper() .. " ]",
        Color = Theme.Accent,
        Font = Theme.FontMono,
        Size2 = Theme.TextSizeTitle,
        Size = UDim2.new(1, -210, 1, 0),
        Pos = UDim2.fromOffset(39, 0),
        Z = 24,
        Parent = titleBar,
    })

    local versionLabel = newLabel({
        Name = "Version",
        Text = "v" .. Library.Version,
        Color = Theme.TextMuted,
        Font = Theme.FontMono,
        Size2 = 9,
        AlignX = Enum.TextXAlignment.Right,
        Size = UDim2.fromOffset(74, 40),
        Pos = UDim2.new(1, -214, 0, 0),
        Z = 24,
        Parent = titleBar,
    })

    local function makeTitleButton(name, text, x, color)
        local button = Instance.new("TextButton")
        button.Name = name
        button.BackgroundColor3 = Theme.Surface
        button.Size = UDim2.fromOffset(28, 22)
        button.Position = UDim2.new(1, x, 0.5, -11)
        button.Text = text
        button.Font = Theme.FontBold
        button.TextSize = 13
        button.TextColor3 = color or Theme.Accent
        button.BorderSizePixel = 0
        button.AutoButtonColor = false
        button.ZIndex = 26
        button.Parent = titleBar
        decorate(button, UDim.new(0, 4), color or Theme.Border, 1)
        track(button.MouseEnter:Connect(function()
            tween(button, {BackgroundColor3 = Theme.SurfaceBright})
        end))
        track(button.MouseLeave:Connect(function()
            tween(button, {BackgroundColor3 = Theme.Surface})
        end))
        return button
    end

    local minimizeButton = makeTitleButton("Minimize", "_", -98)
    local maximizeButton = makeTitleButton("Maximize", "□", -66)
    local closeButton = makeTitleButton("Close", "×", -34, Theme.Danger)

    local tabBar = Instance.new("ScrollingFrame")
    tabBar.Name = "TabBar"
    tabBar.BackgroundColor3 = Theme.TitleBar
    tabBar.BorderSizePixel = 0
    tabBar.Size = UDim2.new(1, 0, 0, 32)
    tabBar.Position = UDim2.fromOffset(0, 42)
    tabBar.ZIndex = 20
    tabBar.ScrollingDirection = Enum.ScrollingDirection.X
    tabBar.ScrollBarThickness = 2
    tabBar.ScrollBarImageColor3 = Theme.AccentDim
    tabBar.CanvasSize = UDim2.new()
    tabBar.AutomaticCanvasSize = Enum.AutomaticSize.X
    tabBar.Parent = root

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Padding = UDim.new(0, 3)
    tabLayout.Parent = tabBar
    addPadding(tabBar, 5, 5, 4, 4)

    local toolbar = newFrame({
        Name = "Toolbar",
        Color = Theme.TitleBar,
        Size = UDim2.new(1, 0, 0, 28),
        Pos = UDim2.fromOffset(0, 74),
        Z = 18,
        Parent = root,
    })

    local toolbarStatus = newLabel({
        Name = "ToolbarStatus",
        Text = "READY",
        Color = Theme.TextMuted,
        Font = Theme.FontMono,
        Size2 = 9,
        Size = UDim2.new(1, -120, 1, 0),
        Pos = UDim2.fromOffset(8, 0),
        Z = 22,
        Parent = toolbar,
    })

    local commandHint = newLabel({
        Name = "Hint",
        Text = "F1 HELP",
        Color = Theme.TextMuted,
        Font = Theme.FontMono,
        Size2 = 9,
        AlignX = Enum.TextXAlignment.Right,
        Size = UDim2.fromOffset(88, 28),
        Pos = UDim2.new(1, -96, 0, 0),
        Z = 22,
        Parent = toolbar,
    })

    local content = newFrame({
        Name = "ContentArea",
        Color = Theme.Background,
        Size = UDim2.new(1, 0, 1, -124),
        Pos = UDim2.fromOffset(0, 102),
        Z = 12,
        Parent = root,
    })

    local statusBar = newFrame({
        Name = "StatusBar",
        Color = Theme.TitleBar,
        Size = UDim2.new(1, 0, 0, 22),
        Pos = UDim2.new(0, 0, 1, -22),
        Z = 20,
        Parent = root,
    })

    local statusText = newLabel({
        Name = "Status",
        Text = "◈ PLASMA // ONLINE",
        Color = Theme.TextSecondary,
        Font = Theme.FontMono,
        Size2 = 9,
        Size = UDim2.new(0.72, 0, 1, 0),
        Pos = UDim2.fromOffset(8, 0),
        Z = 22,
        Parent = statusBar,
    })

    local fpsLabel = newLabel({
        Name = "FPS",
        Text = "FPS --",
        Color = Theme.TextMuted,
        Font = Theme.FontMono,
        Size2 = 9,
        AlignX = Enum.TextXAlignment.Right,
        Size = UDim2.new(0.28, -8, 1, 0),
        Pos = UDim2.new(0.72, 0, 0, 0),
        Z = 22,
        Parent = statusBar,
    })

    local resizeHandle
    if resizable then
        resizeHandle = newFrame({
            Name = "ResizeHandle",
            Color = Theme.AccentDim,
            Trans = 0.25,
            Size = UDim2.fromOffset(10, 10),
            Pos = UDim2.new(1, -10, 1, -10),
            Z = 60,
            Parent = root,
        })
        decorate(resizeHandle, UDim.new(0, 2), false)
        local resizing = false
        local resizeOrigin = Vector2.zero
        local sizeOrigin = Vector2.zero
        track(resizeHandle.InputBegan:Connect(function(input)
            if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
                return
            end
            resizing = true
            resizeOrigin = input.Position
            sizeOrigin = root.AbsoluteSize
        end))
        track(UserInputService.InputChanged:Connect(function(input)
            if not resizing or input.UserInputType ~= Enum.UserInputType.MouseMovement then
                return
            end
            local delta = input.Position - resizeOrigin
            setRootSize(sizeOrigin.X + delta.X, sizeOrigin.Y + delta.Y)
        end))
        track(UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                resizing = false
            end
        end))
    end

    local Window = {}

    function Window:SetTitle(value)
        title = tostring(value)
        titleLabel.Text = "[ " .. title:upper() .. " ]"
        return self
    end

    function Window:SetIcon(value)
        icon.Image = getIconAsset(value)
        return self
    end

    function Window:SetStatus(value, color)
        statusText.Text = tostring(value)
        if color then
            statusText.TextColor3 = color
        end
        return self
    end

    function Window:SetToolbarStatus(value, color)
        toolbarStatus.Text = tostring(value)
        toolbarStatus.TextColor3 = color or Theme.TextMuted
        return self
    end

    function Window:GetGui()
        return gui
    end

    function Window:GetRoot()
        return root
    end

    function Window:IsVisible()
        return root.Visible
    end

    function Window:IsMinimized()
        return minimized
    end

    function Window:SetVisible(value)
        root.Visible = value == true
        return self
    end

    function Window:Show()
        root.Visible = true
        return self
    end

    function Window:Hide()
        root.Visible = false
        return self
    end

    function Window:Toggle()
        root.Visible = not root.Visible
        if not root.Visible and activePopupCloser then
            activePopupCloser()
        end
        return self
    end

    function Window:SetSize(w, h)
        setRootSize(w, h)
        return self
    end

    function Window:GetSize()
        return root.AbsoluteSize
    end

    function Window:SetPosition(x, y)
        local point = clampViewportPosition(root, Vector2.new(tonumber(x) or 0, tonumber(y) or 0))
        root.Position = UDim2.fromOffset(point.X, point.Y)
        return self
    end

    function Window:Center()
        local camera = workspace.CurrentCamera
        local viewport = camera and camera.ViewportSize or Vector2.new(1920, 1080)
        local size = root.AbsoluteSize
        root.Position = UDim2.fromOffset((viewport.X - size.X) / 2, (viewport.Y - size.Y) / 2)
        return self
    end

    function Window:Minimize()
        if minimized then
            return self
        end
        minimized = true
        maximized = false
        previousSize = UDim2.fromOffset(root.AbsoluteSize.X, root.AbsoluteSize.Y)
        tabBar.Visible = false
        toolbar.Visible = false
        content.Visible = false
        statusBar.Visible = false
        tween(root, {Size = UDim2.fromOffset(root.AbsoluteSize.X, 44)}, Theme.TweenSlow)
        return self
    end

    function Window:Restore()
        if not minimized then
            return self
        end
        minimized = false
        tabBar.Visible = true
        toolbar.Visible = true
        content.Visible = true
        statusBar.Visible = true
        tween(root, {Size = previousSize}, Theme.TweenSlow)
        return self
    end

    function Window:Maximize()
        if maximized then
            return self
        end
        maximized = true
        minimized = false
        previousSize = UDim2.fromOffset(root.AbsoluteSize.X, root.AbsoluteSize.Y)
        previousPosition = root.Position
        local camera = workspace.CurrentCamera
        local viewport = camera and camera.ViewportSize or Vector2.new(1920, 1080)
        root.Position = UDim2.fromOffset(8, 8)
        tween(root, {Position = UDim2.fromOffset(8, 8), Size = UDim2.fromOffset(viewport.X - 16, viewport.Y - 16)}, Theme.TweenSlow)
        return self
    end

    function Window:Unmaximize()
        if not maximized then
            return self
        end
        maximized = false
        tween(root, {Position = previousPosition, Size = previousSize}, Theme.TweenSlow)
        return self
    end

    function Window:CreateTab(name, settings)
        settings = settings or {}
        name = tostring(name or settings.Name or "Tab")
        local index = #tabs + 1
        local measured = TextService:GetTextSize(name:upper(), 10, Theme.FontMono, Vector2.new(1000, 24))
        local button = Instance.new("TextButton")
        button.Name = "Tab_" .. name:gsub("%W", "_")
        button.Size = UDim2.fromOffset(math.clamp(measured.X + 28, 72, 180), 24)
        button.BackgroundColor3 = Theme.TabInactive
        button.BorderSizePixel = 0
        button.Text = (settings.Prefix and tostring(settings.Prefix) .. "  " or "") .. name:upper()
        button.Font = Theme.FontMono
        button.TextSize = 10
        button.TextColor3 = Theme.TextSecondary
        button.AutoButtonColor = false
        button.LayoutOrder = index
        button.ZIndex = 24
        button.Parent = tabBar
        decorate(button, UDim.new(0, 4), false)

        local page = Instance.new("ScrollingFrame")
        page.Name = "Page_" .. name:gsub("%W", "_")
        page.BackgroundTransparency = 1
        page.BorderSizePixel = 0
        page.Size = UDim2.fromScale(1, 1)
        page.ScrollBarThickness = 3
        page.ScrollBarImageColor3 = Theme.AccentDim
        page.CanvasSize = UDim2.new()
        page.AutomaticCanvasSize = Enum.AutomaticSize.Y
        page.Visible = false
        page.ZIndex = 13
        page.Parent = content

        local list = Instance.new("UIListLayout")
        list.SortOrder = Enum.SortOrder.LayoutOrder
        list.Padding = UDim.new(0, 6)
        list.Parent = page
        addPadding(page, 10, 10, 8, 8)

        local tabConnections = {}
        local elementOrder = 0
        local tabDestroyed = false

        local tabRecord = {Name = name, Button = button, Page = page, Connections = tabConnections}
        tabs[index] = tabRecord

        local function nextOrder()
            elementOrder += 1
            return elementOrder
        end

        local function elementFrame(height, background)
            local frame = newFrame({
                Name = "Element",
                Color = background or Theme.SurfaceAlt,
                Size = UDim2.new(1, 0, 0, height or 38),
                Z = 16,
                Parent = page,
            })
            frame.LayoutOrder = nextOrder()
            decorate(frame, UDim.new(0, 5), Theme.BorderDim, 1)
            return frame
        end

        local function makeElementApi(frame, cleanup)
            local api = {}
            function api:GetObject()
                return frame
            end
            function api:SetVisible(value)
                frame.Visible = value == true
                return self
            end
            function api:IsVisible()
                return frame.Visible
            end
            function api:Destroy()
                if cleanup then
                    cleanup()
                end
                if frame.Parent then
                    frame:Destroy()
                end
            end
            return api
        end

        local Tab = {}
        Tab.Name = name
        Tab.Page = page

        function Tab:GetPage()
            return page
        end

        function Tab:IsActive()
            return currentTab == index
        end

        function Tab:Select()
            if currentTab == index then
                return self
            end
            currentTab = index
            for i, tab in ipairs(tabs) do
                local active = i == index
                tab.Page.Visible = active
                tween(tab.Button, {
                    BackgroundColor3 = active and Theme.TabActive or Theme.TabInactive,
                    TextColor3 = active and Theme.Background or Theme.TextSecondary,
                })
            end
            Window:SetToolbarStatus("TAB // " .. name:upper(), Theme.TextSecondary)
            return self
        end

        function Tab:ScrollToTop()
            page.CanvasPosition = Vector2.zero
            return self
        end

        function Tab:ScrollToBottom()
            page.CanvasPosition = Vector2.new(0, math.max(0, page.AbsoluteCanvasSize.Y - page.AbsoluteSize.Y))
            return self
        end

        function Tab:CreateLabel(text, settings)
            settings = settings or {}
            local frame = elementFrame(settings.Height or 30, settings.Background or Theme.Surface)
            addPadding(frame, 10, 10, 0, 0)
            newLabel({
                Text = tostring(text or ""),
                Color = settings.Color or Theme.TextSecondary,
                Font = settings.Font or Theme.FontMono,
                Size2 = settings.TextSize or 11,
                AlignX = settings.AlignX or Enum.TextXAlignment.Left,
                Wrap = settings.Wrap == true,
                Z = 17,
                Parent = frame,
            })
            return registerElement(makeElementApi(frame))
        end

        function Tab:CreateParagraph(settings)
            settings = settings or {}
            local titleText = tostring(settings.Title or settings.Label or "Info")
            local bodyText = tostring(settings.Content or settings.Description or "")
            local frame = elementFrame(settings.Height or 72, settings.Background or Theme.Surface)
            addPadding(frame, 10, 10, 8, 8)
            newLabel({Text = titleText, Color = settings.TitleColor or Theme.Accent, Font = Theme.FontBold, Size2 = 12, Size = UDim2.new(1, 0, 0, 20), Z = 17, Parent = frame})
            newLabel({Text = bodyText, Color = settings.ContentColor or Theme.TextMuted, Font = settings.Font or Theme.FontUI, Size2 = settings.TextSize or 11, Size = UDim2.new(1, 0, 1, -20), Pos = UDim2.fromOffset(0, 20), Wrap = true, Z = 17, Parent = frame})
            return registerElement(makeElementApi(frame))
        end

        function Tab:CreateSection(text, settings)
            settings = settings or {}
            local frame = elementFrame(settings.Height or 23, Theme.Background)
            frame.BackgroundTransparency = 1
            local line = newFrame({Color = Theme.BorderDim, Size = UDim2.new(1, 0, 0, 1), Pos = UDim2.new(0, 0, 0.5, 0), Z = 16, Parent = frame})
            local label = newLabel({Text = "  " .. tostring(text or "SECTION"):upper() .. "  ", Color = settings.Color or Theme.AccentDim, Font = Theme.FontMono, Size2 = 10, AlignX = Enum.TextXAlignment.Center, Size = UDim2.fromOffset(math.max(90, TextService:GetTextSize(tostring(text or "SECTION"):upper(), 10, Theme.FontMono, Vector2.new(1000, 20)).X + 32), 23), Pos = UDim2.new(0.5, -75, 0, 0), Z = 17, Parent = frame})
            label.BackgroundColor3 = Theme.Background
            label.BackgroundTransparency = 0
            return registerElement(makeElementApi(frame))
        end

        function Tab:CreateDivider(settings)
            settings = settings or {}
            local frame = elementFrame(settings.Height or 10, Theme.Background)
            frame.BackgroundTransparency = 1
            newFrame({Color = settings.Color or Theme.BorderDim, Size = UDim2.new(1, 0, 0, 1), Pos = UDim2.new(0, 0, 0.5, 0), Z = 17, Parent = frame})
            return registerElement(makeElementApi(frame))
        end

        function Tab:CreateButton(settings)
            settings = settings or {}
            local label = tostring(settings.Label or settings.Name or "Button")
            local callback = settings.Callback or function() end
            local frame = elementFrame(settings.Height or 38)
            local button2 = Instance.new("TextButton")
            button2.Name = "Button"
            button2.BackgroundColor3 = settings.Color or Theme.Surface
            button2.Size = UDim2.new(1, 0, 1, 0)
            button2.Text = tostring(settings.Prefix or "▶") .. "  " .. label:upper()
            button2.Font = settings.Font or Theme.FontMono
            button2.TextSize = settings.TextSize or Theme.TextSizeBody
            button2.TextColor3 = settings.TextColor or Theme.Accent
            button2.BorderSizePixel = 0
            button2.AutoButtonColor = false
            button2.ZIndex = 18
            button2.Parent = frame
            decorate(button2, UDim.new(0, 4), settings.BorderColor or Theme.Border, 1)

            local localConnections = {}
            addConnection(localConnections, button2.MouseEnter:Connect(function()
                tween(button2, {BackgroundColor3 = Theme.SurfaceBright, TextColor3 = Theme.TextPrimary})
            end))
            addConnection(localConnections, button2.MouseLeave:Connect(function()
                tween(button2, {BackgroundColor3 = settings.Color or Theme.Surface, TextColor3 = settings.TextColor or Theme.Accent})
            end))
            addConnection(localConnections, button2.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    local abs = button2.AbsolutePosition
                    createRipple(button2, input.Position - abs, Theme.Accent)
                    tween(button2, {BackgroundColor3 = Theme.AccentDim, TextColor3 = Theme.Background}, Theme.TweenFast)
                end
            end))
            addConnection(localConnections, button2.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    tween(button2, {BackgroundColor3 = settings.Color or Theme.Surface, TextColor3 = settings.TextColor or Theme.Accent}, Theme.TweenFast)
                end
            end))
            addConnection(localConnections, button2.Activated:Connect(function()
                safeCall(callback)
            end))

            local Button = makeElementApi(frame, function()
                disconnectAll(localConnections)
            end)
            function Button:SetText(value)
                label = tostring(value)
                button2.Text = tostring(settings.Prefix or "▶") .. "  " .. label:upper()
                return self
            end
            function Button:GetText()
                return label
            end
            function Button:SetEnabled(enabled)
                button2.Active = enabled ~= false
                button2.AutoButtonColor = false
                button2.TextTransparency = enabled == false and 0.45 or 0
                frame.BackgroundTransparency = enabled == false and 0.15 or 0
                return self
            end
            function Button:Fire()
                safeCall(callback)
                return self
            end
            return registerElement(Button)
        end

        function Tab:CreateToggle(settings)
            settings = settings or {}
            local label = tostring(settings.Label or "Toggle")
            local state = settings.Default == true
            local callback = settings.Callback or function() end
            local frame = elementFrame(settings.Height or 40)
            addPadding(frame, 10, 10, 0, 0)
            local text = newLabel({Text = label, Color = Theme.TextPrimary, Font = Theme.FontUI, Size2 = settings.TextSize or Theme.TextSizeBody, Size = UDim2.new(0.72, 0, 1, 0), Z = 17, Parent = frame})
            if settings.Description then
                text.Size = UDim2.new(0.72, 0, 0, 20)
                text.Position = UDim2.fromOffset(0, 1)
                newLabel({Text = tostring(settings.Description), Color = Theme.TextMuted, Font = Theme.FontUI, Size2 = 9, Size = UDim2.new(0.72, 0, 0, 15), Pos = UDim2.fromOffset(0, 20), Z = 17, Parent = frame})
            end

            local trackFrame = newFrame({Color = state and Theme.ToggleOn or Theme.ToggleOff, Size = UDim2.fromOffset(42, 20), Pos = UDim2.new(1, -42, 0.5, -10), Z = 18, Parent = frame})
            decorate(trackFrame, UDim.new(0, 10), Theme.BorderDim, 1)
            local knob = newFrame({Color = Theme.ToggleKnob, Size = UDim2.fromOffset(14, 14), Pos = state and UDim2.new(1, -17, 0.5, -7) or UDim2.fromOffset(3, 3), Z = 19, Parent = trackFrame})
            decorate(knob, UDim.new(0, 7), false)
            local hit = Instance.new("TextButton")
            hit.BackgroundTransparency = 1
            hit.Size = UDim2.new(1, 0, 1, 0)
            hit.Text = ""
            hit.ZIndex = 20
            hit.Parent = frame

            local Toggle = {}
            local function render(silent)
                tween(trackFrame, {BackgroundColor3 = state and Theme.ToggleOn or Theme.ToggleOff})
                tween(knob, {Position = state and UDim2.new(1, -17, 0.5, -7) or UDim2.fromOffset(3, 3)})
                if not silent then
                    safeCall(callback, state)
                end
            end
            function Toggle:Set(value, silent)
                state = value == true
                render(silent)
                return self
            end
            function Toggle:Get()
                return state
            end
            function Toggle:Toggle()
                return self:Set(not state)
            end
            function Toggle:SetEnabled(enabled)
                hit.Active = enabled ~= false
                frame.BackgroundTransparency = enabled == false and 0.14 or 0
                text.TextTransparency = enabled == false and 0.5 or 0
                return self
            end
            function Toggle:GetObject()
                return frame
            end
            function Toggle:Destroy()
                if frame.Parent then
                    frame:Destroy()
                end
            end
            addConnection(tabConnections, hit.Activated:Connect(function()
                Toggle:Toggle()
            end))
            addConnection(tabConnections, hit.MouseEnter:Connect(function()
                tween(frame, {BackgroundColor3 = Theme.Surface})
            end))
            addConnection(tabConnections, hit.MouseLeave:Connect(function()
                tween(frame, {BackgroundColor3 = Theme.SurfaceAlt})
            end))
            return registerElement(Toggle)
        end

        function Tab:CreateSlider(settings)
            settings = settings or {}
            local label = tostring(settings.Label or "Slider")
            local min = tonumber(settings.Min) or 0
            local max = tonumber(settings.Max) or 100
            local step = math.abs(tonumber(settings.Step) or 1)
            if max <= min then
                max = min + 1
            end
            local decimals = tonumber(settings.Decimals)
            local value = math.clamp(tonumber(settings.Default) or min, min, max)
            local callback = settings.Callback or function() end
            local frame = elementFrame(settings.Height or 58)
            addPadding(frame, 10, 10, 5, 6)
            newLabel({Text = label, Color = Theme.TextPrimary, Font = Theme.FontUI, Size2 = 12, Size = UDim2.new(0.68, 0, 0, 19), Z = 17, Parent = frame})
            local valueLabel = newLabel({Text = settings.Format and tostring(settings.Format(value)) or formatNumber(value, decimals), Color = Theme.Accent, Font = Theme.FontMono, Size2 = 11, AlignX = Enum.TextXAlignment.Right, Size = UDim2.new(0.32, 0, 0, 19), Pos = UDim2.new(0.68, 0, 0, 0), Z = 17, Parent = frame})
            local sliderTrack = newFrame({Color = Theme.SliderTrack, Size = UDim2.new(1, 0, 0, 8), Pos = UDim2.fromOffset(0, 31), Z = 17, Parent = frame})
            decorate(sliderTrack, UDim.new(0, 4), Theme.BorderDim, 1)
            local pct = (value - min) / (max - min)
            local fill = newFrame({Color = Theme.SliderFill, Size = UDim2.new(pct, 0, 1, 0), Z = 18, Parent = sliderTrack})
            decorate(fill, UDim.new(0, 4), false)
            local knob = newFrame({Color = Theme.Accent, Size = UDim2.fromOffset(16, 16), Pos = UDim2.new(pct, -8, 0.5, -8), Z = 19, Parent = sliderTrack})
            decorate(knob, UDim.new(0, 8), Theme.Background, 1)
            local dragging = false

            local function snap(raw)
                return math.clamp(min + math.floor((raw - min) / step + 0.5) * step, min, max)
            end
            local function render(silent)
                local p = (value - min) / (max - min)
                tween(fill, {Size = UDim2.new(p, 0, 1, 0)}, Theme.TweenFast)
                tween(knob, {Position = UDim2.new(p, -8, 0.5, -8)}, Theme.TweenFast)
                valueLabel.Text = settings.Format and tostring(settings.Format(value)) or formatNumber(value, decimals)
                if not silent then
                    safeCall(callback, value)
                end
            end
            local function recalc(x, silent)
                local pct2 = math.clamp((x - sliderTrack.AbsolutePosition.X) / math.max(1, sliderTrack.AbsoluteSize.X), 0, 1)
                value = snap(min + (max - min) * pct2)
                render(silent)
            end
            addConnection(tabConnections, sliderTrack.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    recalc(input.Position.X)
                end
            end))
            addConnection(tabConnections, UserInputService.InputChanged:Connect(function(input)
                if not dragging then
                    return
                end
                if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                    recalc(input.Position.X)
                end
            end))
            addConnection(tabConnections, UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                end
            end))

            local Slider = {}
            function Slider:Set(newValue, silent)
                value = snap(tonumber(newValue) or min)
                render(silent)
                return self
            end
            function Slider:Get()
                return value
            end
            function Slider:SetRange(newMin, newMax, silent)
                min = tonumber(newMin) or min
                max = tonumber(newMax) or max
                if max <= min then
                    max = min + 1
                end
                value = math.clamp(value, min, max)
                render(silent)
                return self
            end
            function Slider:GetRange()
                return min, max
            end
            function Slider:SetStep(newStep)
                step = math.abs(tonumber(newStep) or step)
                if step == 0 then
                    step = 1
                end
                return self
            end
            function Slider:Increment(amount)
                amount = tonumber(amount) or step
                return self:Set(value + amount)
            end
            function Slider:Decrement(amount)
                amount = tonumber(amount) or step
                return self:Set(value - amount)
            end
            function Slider:GetObject()
                return frame
            end
            function Slider:Destroy()
                if frame.Parent then
                    frame:Destroy()
                end
            end
            return registerElement(Slider)
        end

        function Tab:CreateDropdown(settings)
            settings = settings or {}
            local label = tostring(settings.Label or "Dropdown")
            local choices = table.clone(settings.Options or {})
            local selected = settings.Default or choices[1] or "None"
            local callback = settings.Callback or function() end
            local open = false
            local popup = Instance.new("Frame")
            local outsideConnection
            local frame = elementFrame(settings.Height or 40)
            frame.ClipsDescendants = false
            addPadding(frame, 10, 10, 0, 0)
            newLabel({Text = label, Color = Theme.TextPrimary, Font = Theme.FontUI, Size2 = 12, Size = UDim2.new(0.42, 0, 1, 0), Z = 17, Parent = frame})

            local button3 = Instance.new("TextButton")
            button3.Name = "Dropdown"
            button3.BackgroundColor3 = Theme.Surface
            button3.Size = UDim2.new(0.54, 0, 0, 28)
            button3.Position = UDim2.new(0.44, 0, 0.5, -14)
            button3.Text = "  " .. tostring(selected) .. "  ▼"
            button3.Font = Theme.FontMono
            button3.TextSize = 10
            button3.TextColor3 = Theme.Accent
            button3.BorderSizePixel = 0
            button3.AutoButtonColor = false
            button3.TextXAlignment = Enum.TextXAlignment.Left
            button3.ZIndex = 18
            button3.Parent = frame
            decorate(button3, UDim.new(0, 4), Theme.Border, 1)

            popup.Name = "DropdownPopup"
            popup.BackgroundColor3 = Theme.TitleBar
            popup.Size = UDim2.new(1, 0, 0, 0)
            popup.Position = UDim2.fromOffset(0, 30)
            popup.BorderSizePixel = 0
            popup.Visible = false
            popup.ZIndex = 80
            popup.Parent = button3
            decorate(popup, UDim.new(0, 4), Theme.Border, 1)

            local container = Instance.new("ScrollingFrame")
            container.BackgroundTransparency = 1
            container.BorderSizePixel = 0
            container.Size = UDim2.fromScale(1, 1)
            container.ScrollBarThickness = 3
            container.ScrollBarImageColor3 = Theme.AccentDim
            container.ZIndex = 81
            container.Parent = popup
            local list = Instance.new("UIListLayout")
            list.SortOrder = Enum.SortOrder.LayoutOrder
            list.Parent = container

            local function closeDropdown()
                if not open then
                    return
                end
                open = false
                if activePopupCloser == closeDropdown then
                    activePopupCloser = nil
                end
                if outsideConnection then
                    outsideConnection:Disconnect()
                    outsideConnection = nil
                end
                tween(popup, {Size = UDim2.new(1, 0, 0, 0)})
                task.delay(0.12, function()
                    if not open and popup.Parent then
                        popup.Visible = false
                    end
                end)
            end

            local function rebuildChoices()
                for _, child in ipairs(container:GetChildren()) do
                    if child:IsA("TextButton") then
                        child:Destroy()
                    end
                end
                for i, choice in ipairs(choices) do
                    local entry = Instance.new("TextButton")
                    entry.BackgroundColor3 = Theme.TitleBar
                    entry.BorderSizePixel = 0
                    entry.Size = UDim2.new(1, 0, 0, 28)
                    entry.LayoutOrder = i
                    entry.Text = "  " .. tostring(choice)
                    entry.TextXAlignment = Enum.TextXAlignment.Left
                    entry.Font = Theme.FontMono
                    entry.TextSize = 10
                    entry.TextColor3 = tostring(choice) == tostring(selected) and Theme.TextPrimary or Theme.TextSecondary
                    entry.AutoButtonColor = false
                    entry.ZIndex = 82
                    entry.Parent = container
                    entry.Activated:Connect(function()
                        selected = choice
                        button3.Text = "  " .. tostring(selected) .. "  ▼"
                        safeCall(callback, selected)
                        closeDropdown()
                    end)
                end
            end

            local function openDropdown()
                if activePopupCloser and activePopupCloser ~= closeDropdown then
                    activePopupCloser()
                end
                activePopupCloser = closeDropdown
                open = true
                popup.Visible = true
                local visibleCount = math.min(#choices, math.max(1, settings.MaxVisible or 7))
                local targetHeight = visibleCount * 28
                container.CanvasSize = UDim2.new(0, 0, 0, #choices * 28)
                tween(popup, {Size = UDim2.new(1, 0, 0, targetHeight)}, Theme.TweenFast)
                outsideConnection = UserInputService.InputBegan:Connect(function(input)
                    if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
                        return
                    end
                    if not pointInside(button3, input.Position) and not pointInside(popup, input.Position) then
                        closeDropdown()
                    end
                end)
            end

            addConnection(tabConnections, button3.Activated:Connect(function()
                if open then
                    closeDropdown()
                else
                    openDropdown()
                end
            end))
            rebuildChoices()

            local Dropdown = makeElementApi(frame, function()
                closeDropdown()
            end)
            function Dropdown:Set(value, silent)
                selected = value
                button3.Text = "  " .. tostring(selected) .. "  ▼"
                if not silent then
                    safeCall(callback, selected)
                end
                return self
            end
            function Dropdown:Get()
                return selected
            end
            function Dropdown:Refresh(newChoices)
                choices = table.clone(newChoices or {})
                if not table.find(choices, selected) then
                    selected = choices[1] or "None"
                end
                button3.Text = "  " .. tostring(selected) .. "  ▼"
                rebuildChoices()
                return self
            end
            function Dropdown:GetOptions()
                return table.clone(choices)
            end
            function Dropdown:Open()
                openDropdown()
                return self
            end
            function Dropdown:Close()
                closeDropdown()
                return self
            end
            return registerElement(Dropdown)
        end

        function Tab:CreateMultiDropdown(settings)
            settings = settings or {}
            local optionsList = table.clone(settings.Options or {})
            local selected = {}
            for _, item in ipairs(settings.Default or {}) do
                selected[item] = true
            end
            local callback = settings.Callback or function() end
            local frame = elementFrame(settings.Height or 40)
            frame.ClipsDescendants = false
            addPadding(frame, 10, 10, 0, 0)
            newLabel({Text = tostring(settings.Label or "Multi Select"), Color = Theme.TextPrimary, Font = Theme.FontUI, Size2 = 12, Size = UDim2.new(0.42, 0, 1, 0), Z = 17, Parent = frame})
            local button = Instance.new("TextButton")
            button.BackgroundColor3 = Theme.Surface
            button.Size = UDim2.new(0.54, 0, 0, 28)
            button.Position = UDim2.new(0.44, 0, 0.5, -14)
            button.Text = "  SELECT  ▼"
            button.TextXAlignment = Enum.TextXAlignment.Left
            button.Font = Theme.FontMono
            button.TextSize = 10
            button.TextColor3 = Theme.Accent
            button.BorderSizePixel = 0
            button.AutoButtonColor = false
            button.ZIndex = 18
            button.Parent = frame
            decorate(button, UDim.new(0, 4), Theme.Border, 1)
            local popup = Instance.new("Frame")
            popup.BackgroundColor3 = Theme.TitleBar
            popup.Size = UDim2.new(1, 0, 0, 0)
            popup.Position = UDim2.fromOffset(0, 30)
            popup.Visible = false
            popup.BorderSizePixel = 0
            popup.ZIndex = 80
            popup.Parent = button
            decorate(popup, UDim.new(0, 4), Theme.Border, 1)
            local scroll = Instance.new("ScrollingFrame")
            scroll.BackgroundTransparency = 1
            scroll.BorderSizePixel = 0
            scroll.Size = UDim2.fromScale(1, 1)
            scroll.ScrollBarThickness = 3
            scroll.ScrollBarImageColor3 = Theme.AccentDim
            scroll.Parent = popup
            local list = Instance.new("UIListLayout")
            list.Parent = scroll
            list.SortOrder = Enum.SortOrder.LayoutOrder
            local opened = false
            local outsideConnection
            local function summary()
                local count = 0
                for _, enabled in pairs(selected) do
                    if enabled then count += 1 end
                end
                return count == 0 and "  SELECT  ▼" or "  " .. tostring(count) .. " SELECTED  ▼"
            end
            local function close()
                if not opened then return end
                opened = false
                if activePopupCloser then activePopupCloser = nil end
                if outsideConnection then outsideConnection:Disconnect(); outsideConnection = nil end
                tween(popup, {Size = UDim2.new(1, 0, 0, 0)})
                task.delay(0.12, function() if popup.Parent and not opened then popup.Visible = false end end)
            end
            local function rebuild()
                for _, child in ipairs(scroll:GetChildren()) do
                    if child:IsA("TextButton") then child:Destroy() end
                end
                for i, option in ipairs(optionsList) do
                    local entry = Instance.new("TextButton")
                    entry.BackgroundColor3 = Theme.TitleBar
                    entry.BorderSizePixel = 0
                    entry.Size = UDim2.new(1, 0, 0, 28)
                    entry.LayoutOrder = i
                    entry.TextXAlignment = Enum.TextXAlignment.Left
                    entry.Font = Theme.FontMono
                    entry.TextSize = 10
                    entry.AutoButtonColor = false
                    entry.TextColor3 = selected[option] and Theme.TextPrimary or Theme.TextSecondary
                    entry.Text = (selected[option] and "  ☑  " or "  ☐  ") .. tostring(option)
                    entry.ZIndex = 82
                    entry.Parent = scroll
                    entry.Activated:Connect(function()
                        selected[option] = not selected[option]
                        entry.TextColor3 = selected[option] and Theme.TextPrimary or Theme.TextSecondary
                        entry.Text = (selected[option] and "  ☑  " or "  ☐  ") .. tostring(option)
                        button.Text = summary()
                        local values = {}
                        for _, item in ipairs(optionsList) do
                            if selected[item] then table.insert(values, item) end
                        end
                        safeCall(callback, values)
                    end)
                end
            end
            local function open()
                if activePopupCloser and activePopupCloser ~= close then activePopupCloser() end
                activePopupCloser = close
                opened = true
                popup.Visible = true
                scroll.CanvasSize = UDim2.new(0, 0, 0, #optionsList * 28)
                tween(popup, {Size = UDim2.new(1, 0, 0, math.min(#optionsList, settings.MaxVisible or 7) * 28)}, Theme.TweenFast)
                outsideConnection = UserInputService.InputBegan:Connect(function(input)
                    if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
                    if not pointInside(button, input.Position) and not pointInside(popup, input.Position) then close() end
                end)
            end
            addConnection(tabConnections, button.Activated:Connect(function() if opened then close() else open() end end))
            rebuild()
            local Multi = makeElementApi(frame, close)
            function Multi:Set(values, silent)
                table.clear(selected)
                for _, value in ipairs(values or {}) do selected[value] = true end
                button.Text = summary()
                rebuild()
                if not silent then safeCall(callback, self:Get()) end
                return self
            end
            function Multi:Get()
                local result = {}
                for _, item in ipairs(optionsList) do
                    if selected[item] then table.insert(result, item) end
                end
                return result
            end
            function Multi:Refresh(newOptions)
                optionsList = table.clone(newOptions or {})
                rebuild()
                button.Text = summary()
                return self
            end
            return registerElement(Multi)
        end

        function Tab:CreateTextInput(settings)
            settings = settings or {}
            local label = tostring(settings.Label or "Input")
            local value = tostring(settings.Default or "")
            local placeholder = tostring(settings.Placeholder or "type here...")
            local callback = settings.Callback or function() end
            local frame = elementFrame(settings.Height or 40)
            addPadding(frame, 10, 10, 0, 0)
            newLabel({Text = label, Color = Theme.TextPrimary, Font = Theme.FontUI, Size2 = 12, Size = UDim2.new(0.34, 0, 1, 0), Z = 17, Parent = frame})
            local box = Instance.new("TextBox")
            box.BackgroundColor3 = Theme.Surface
            box.Size = UDim2.new(0.64, 0, 0, 28)
            box.Position = UDim2.new(0.36, 0, 0.5, -14)
            box.Text = value
            box.PlaceholderText = placeholder
            box.PlaceholderColor3 = Theme.TextDisabled
            box.Font = settings.Font or Theme.FontMono
            box.TextSize = settings.TextSize or 10
            box.TextColor3 = Theme.Accent
            box.TextXAlignment = Enum.TextXAlignment.Left
            box.ClearTextOnFocus = settings.ClearTextOnFocus == true
            box.BorderSizePixel = 0
            box.ZIndex = 18
            box.Parent = frame
            decorate(box, UDim.new(0, 4), Theme.Border, 1)
            addPadding(box, 7, 7, 0, 0)
            local Input = makeElementApi(frame)
            function Input:Get()
                return box.Text
            end
            function Input:Set(newValue, silent)
                value = tostring(newValue)
                box.Text = value
                if not silent then safeCall(callback, value, false) end
                return self
            end
            function Input:Focus()
                box:CaptureFocus()
                return self
            end
            function Input:ReleaseFocus(submit)
                box:ReleaseFocus()
                if submit then safeCall(callback, box.Text, true) end
                return self
            end
            function Input:SelectAll()
                box.CursorPosition = 1
                box.SelectionStart = #box.Text + 1
                return self
            end
            addConnection(tabConnections, box.Focused:Connect(function()
                tween(box, {BackgroundColor3 = Theme.SurfaceAlt, TextColor3 = Theme.TextPrimary})
            end))
            addConnection(tabConnections, box.FocusLost:Connect(function(enter)
                tween(box, {BackgroundColor3 = Theme.Surface, TextColor3 = Theme.Accent})
                safeCall(callback, box.Text, enter)
            end))
            return registerElement(Input)
        end

        function Tab:CreateKeybind(settings)
            settings = settings or {}
            local label = tostring(settings.Label or "Keybind")
            local current = settings.Default or settings.Key or Enum.KeyCode.Unknown
            local callback = settings.Callback or function() end
            local changed = settings.Changed
            local listening = false
            local frame = elementFrame(settings.Height or 40)
            addPadding(frame, 10, 10, 0, 0)
            newLabel({Text = label, Color = Theme.TextPrimary, Font = Theme.FontUI, Size2 = 12, Size = UDim2.new(0.52, 0, 1, 0), Z = 17, Parent = frame})
            local button = Instance.new("TextButton")
            button.BackgroundColor3 = Theme.Surface
            button.Size = UDim2.new(0.44, 0, 0, 28)
            button.Position = UDim2.new(0.56, 0, 0.5, -14)
            button.Text = "  " .. tostring(current.Name or current) .. "  "
            button.Font = Theme.FontMono
            button.TextSize = 10
            button.TextColor3 = Theme.Accent
            button.BorderSizePixel = 0
            button.AutoButtonColor = false
            button.ZIndex = 18
            button.Parent = frame
            decorate(button, UDim.new(0, 4), Theme.Border, 1)
            local Keybind = makeElementApi(frame)
            function Keybind:Get()
                return current
            end
            function Keybind:Set(key, silent)
                current = key
                button.Text = "  " .. tostring(current.Name or current) .. "  "
                if not silent then safeCall(changed, current) end
                return self
            end
            function Keybind:Clear()
                return self:Set(Enum.KeyCode.Unknown)
            end
            function Keybind:Capture()
                listening = true
                button.Text = "  PRESS KEY...  "
                return self
            end
            addConnection(tabConnections, button.Activated:Connect(function()
                Keybind:Capture()
            end))
            addConnection(tabConnections, UserInputService.InputBegan:Connect(function(input, processed)
                if listening then
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then return end
                    listening = false
                    current = input.KeyCode ~= Enum.KeyCode.Unknown and input.KeyCode or input.UserInputType
                    button.Text = "  " .. tostring(current.Name or current) .. "  "
                    safeCall(changed, current)
                    return
                end
                if processed then return end
                local matched = false
                if typeof(current) == "EnumItem" then
                    if current.EnumType == Enum.KeyCode then matched = input.KeyCode == current end
                    if current.EnumType == Enum.UserInputType then matched = input.UserInputType == current end
                end
                if matched then safeCall(callback, current) end
            end))
            return registerElement(Keybind)
        end

        function Tab:CreateColorPicker(settings)
            settings = settings or {}
            local label = tostring(settings.Label or "Color")
            local color = settings.Default or settings.Color or Theme.Accent
            local callback = settings.Callback or function() end
            local frame = elementFrame(settings.Height or 40)
            addPadding(frame, 10, 10, 0, 0)
            newLabel({Text = label, Color = Theme.TextPrimary, Font = Theme.FontUI, Size2 = 12, Size = UDim2.new(0.56, 0, 1, 0), Z = 17, Parent = frame})
            local preview = Instance.new("TextButton")
            preview.BackgroundColor3 = color
            preview.Size = UDim2.fromOffset(72, 28)
            preview.Position = UDim2.new(1, -72, 0.5, -14)
            preview.Text = ""
            preview.BorderSizePixel = 0
            preview.AutoButtonColor = false
            preview.ZIndex = 18
            preview.Parent = frame
            decorate(preview, UDim.new(0, 4), Theme.Border, 1)
            local popup = newFrame({Color = Theme.TitleBar, Size = UDim2.fromOffset(220, 0), Pos = UDim2.new(0, -148, 1, 3), Clip = true, Z = 90, Visible = false, Parent = preview})
            decorate(popup, UDim.new(0, 5), Theme.Border, 1)
            local hue = Instance.new("TextBox")
            hue.BackgroundColor3 = Theme.Surface
            hue.Size = UDim2.new(1, -16, 0, 28)
            hue.Position = UDim2.fromOffset(8, 8)
            hue.PlaceholderText = "R,G,B (0-255)"
            hue.PlaceholderColor3 = Theme.TextDisabled
            hue.Text = string.format("%d,%d,%d", color.R * 255, color.G * 255, color.B * 255)
            hue.Font = Theme.FontMono
            hue.TextSize = 10
            hue.TextColor3 = Theme.TextPrimary
            hue.BorderSizePixel = 0
            hue.ZIndex = 92
            hue.Parent = popup
            decorate(hue, UDim.new(0, 4), Theme.BorderDim, 1)
            addPadding(hue, 6, 6, 0, 0)
            local apply = Instance.new("TextButton")
            apply.BackgroundColor3 = Theme.Surface
            apply.Size = UDim2.new(1, -16, 0, 30)
            apply.Position = UDim2.fromOffset(8, 44)
            apply.Text = "APPLY"
            apply.Font = Theme.FontMono
            apply.TextSize = 10
            apply.TextColor3 = Theme.Accent
            apply.BorderSizePixel = 0
            apply.AutoButtonColor = false
            apply.ZIndex = 92
            apply.Parent = popup
            decorate(apply, UDim.new(0, 4), Theme.BorderDim, 1)
            local open = false
            local ColorPicker = makeElementApi(frame)
            local function setColor(newColor, silent)
                color = newColor
                preview.BackgroundColor3 = color
                hue.Text = string.format("%d,%d,%d", color.R * 255, color.G * 255, color.B * 255)
                if not silent then safeCall(callback, color) end
            end
            function ColorPicker:Get() return color end
            function ColorPicker:Set(newColor, silent)
                if typeof(newColor) == "Color3" then setColor(newColor, silent) end
                return self
            end
            function ColorPicker:Open()
                if activePopupCloser then activePopupCloser() end
                activePopupCloser = function() self:Close() end
                open = true
                popup.Visible = true
                tween(popup, {Size = UDim2.fromOffset(220, 82)}, Theme.TweenFast)
                return self
            end
            function ColorPicker:Close()
                if not open then return self end
                open = false
                if activePopupCloser then activePopupCloser = nil end
                tween(popup, {Size = UDim2.fromOffset(220, 0)}, Theme.TweenFast)
                task.delay(0.12, function() if popup.Parent and not open then popup.Visible = false end end)
                return self
            end
            addConnection(tabConnections, preview.Activated:Connect(function() if open then ColorPicker:Close() else ColorPicker:Open() end end))
            addConnection(tabConnections, apply.Activated:Connect(function()
                local numbers = {}
                for token in string.gmatch(hue.Text, "[^,]+") do table.insert(numbers, tonumber(token)) end
                if #numbers == 3 then
                    setColor(Color3.fromRGB(math.clamp(numbers[1] or 0, 0, 255), math.clamp(numbers[2] or 0, 0, 255), math.clamp(numbers[3] or 0, 0, 255)))
                end
                ColorPicker:Close()
            end))
            return registerElement(ColorPicker)
        end

        function Tab:CreateProgressBar(settings)
            settings = settings or {}
            local value = math.clamp(tonumber(settings.Default) or 0, 0, 1)
            local label = tostring(settings.Label or "Progress")
            local frame = elementFrame(settings.Height or 46)
            addPadding(frame, 10, 10, 5, 5)
            newLabel({Text = label, Color = Theme.TextPrimary, Font = Theme.FontUI, Size2 = 11, Size = UDim2.new(0.72, 0, 0, 18), Z = 17, Parent = frame})
            local percent = newLabel({Text = formatNumber(value * 100, 0) .. "%", Color = Theme.Accent, Font = Theme.FontMono, Size2 = 10, AlignX = Enum.TextXAlignment.Right, Size = UDim2.new(0.28, 0, 0, 18), Pos = UDim2.new(0.72, 0, 0, 0), Z = 17, Parent = frame})
            local trackFrame = newFrame({Color = Theme.SliderTrack, Size = UDim2.new(1, 0, 0, 8), Pos = UDim2.fromOffset(0, 27), Z = 17, Parent = frame})
            decorate(trackFrame, UDim.new(0, 4), Theme.BorderDim, 1)
            local fill = newFrame({Color = settings.Color or Theme.Accent, Size = UDim2.new(value, 0, 1, 0), Z = 18, Parent = trackFrame})
            decorate(fill, UDim.new(0, 4), false)
            local Progress = makeElementApi(frame)
            function Progress:Set(newValue)
                value = math.clamp(tonumber(newValue) or 0, 0, 1)
                percent.Text = formatNumber(value * 100, 0) .. "%"
                tween(fill, {Size = UDim2.new(value, 0, 1, 0)})
                return self
            end
            function Progress:Get() return value end
            return registerElement(Progress)
        end

        function Tab:CreateSearchBox(settings)
            settings = settings or {}
            local callback = settings.Callback or function() end
            local frame = elementFrame(settings.Height or 40)
            local box = Instance.new("TextBox")
            box.BackgroundColor3 = Theme.Surface
            box.Size = UDim2.new(1, 0, 1, 0)
            box.Text = ""
            box.PlaceholderText = settings.Placeholder or "search..."
            box.PlaceholderColor3 = Theme.TextDisabled
            box.Font = Theme.FontMono
            box.TextSize = 10
            box.TextColor3 = Theme.TextPrimary
            box.BorderSizePixel = 0
            box.ClearTextOnFocus = false
            box.ZIndex = 18
            box.Parent = frame
            decorate(box, UDim.new(0, 4), Theme.BorderDim, 1)
            addPadding(box, 9, 9, 0, 0)
            local Search = makeElementApi(frame)
            function Search:Get() return box.Text end
            function Search:Set(value, silent)
                box.Text = tostring(value)
                if not silent then safeCall(callback, box.Text) end
                return self
            end
            function Search:Focus() box:CaptureFocus(); return self end
            addConnection(tabConnections, box:GetPropertyChangedSignal("Text"):Connect(function() safeCall(callback, box.Text) end))
            return registerElement(Search)
        end

        function Tab:CreateConsole(settings)
            settings = settings or {}
            local maxLines = math.max(10, tonumber(settings.MaxLines) or 250)
            local frame = elementFrame(settings.Height or 180, Theme.Console)
            frame.ClipsDescendants = true
            local scroll = Instance.new("ScrollingFrame")
            scroll.BackgroundTransparency = 1
            scroll.BorderSizePixel = 0
            scroll.Size = UDim2.fromScale(1, 1)
            scroll.ScrollBarThickness = 3
            scroll.ScrollBarImageColor3 = Theme.AccentDim
            scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
            scroll.ZIndex = 17
            scroll.Parent = frame
            addPadding(scroll, 8, 8, 7, 7)
            local list = Instance.new("UIListLayout")
            list.SortOrder = Enum.SortOrder.LayoutOrder
            list.Padding = UDim.new(0, 2)
            list.Parent = scroll
            local Console = makeElementApi(frame)
            local entries = {}
            local function push(level, text)
                local label = Instance.new("TextLabel")
                label.BackgroundTransparency = 1
                label.Size = UDim2.new(1, 0, 0, 16)
                label.AutomaticSize = Enum.AutomaticSize.Y
                label.TextWrapped = true
                label.TextXAlignment = Enum.TextXAlignment.Left
                label.TextYAlignment = Enum.TextYAlignment.Top
                label.Font = Theme.FontMono
                label.TextSize = 9
                label.Text = os.date("[%H:%M:%S]") .. " [" .. level:upper() .. "] " .. tostring(text)
                label.TextColor3 = level == "error" and Theme.Danger or level == "warn" and Theme.Warning or level == "info" and Theme.TextSecondary or Theme.TextMuted
                label.LayoutOrder = #entries + 1
                label.ZIndex = 18
                label.Parent = scroll
                table.insert(entries, label)
                while #entries > maxLines do
                    local old = table.remove(entries, 1)
                    if old and old.Parent then old:Destroy() end
                end
                task.defer(function()
                    scroll.CanvasPosition = Vector2.new(0, math.max(0, scroll.AbsoluteCanvasSize.Y))
                end)
            end
            function Console:Log(text) push("log", text); return self end
            function Console:Info(text) push("info", text); return self end
            function Console:Warn(text) push("warn", text); return self end
            function Console:Error(text) push("error", text); return self end
            function Console:Clear()
                for _, entry in ipairs(entries) do if entry.Parent then entry:Destroy() end end
                table.clear(entries)
                return self
            end
            return registerElement(Console)
        end

        function Tab:CreatePlayerSelector(settings)
            settings = settings or {}
            local selected = settings.Default
            local callback = settings.Callback or function() end
            local refreshRate = tonumber(settings.RefreshRate) or 1
            local frame = elementFrame(settings.Height or 40)
            frame.ClipsDescendants = false
            addPadding(frame, 10, 10, 0, 0)
            newLabel({Text = tostring(settings.Label or "Player"), Color = Theme.TextPrimary, Font = Theme.FontUI, Size2 = 12, Size = UDim2.new(0.32, 0, 1, 0), Z = 17, Parent = frame})
            local button = Instance.new("TextButton")
            button.BackgroundColor3 = Theme.Surface
            button.Size = UDim2.new(0.64, 0, 0, 28)
            button.Position = UDim2.new(0.36, 0, 0.5, -14)
            button.Text = "  " .. (selected and selected.Name or "LOCAL") .. "  ▼"
            button.Font = Theme.FontMono
            button.TextSize = 10
            button.TextColor3 = Theme.Accent
            button.TextXAlignment = Enum.TextXAlignment.Left
            button.BorderSizePixel = 0
            button.AutoButtonColor = false
            button.ZIndex = 18
            button.Parent = frame
            decorate(button, UDim.new(0, 4), Theme.Border, 1)
            local selector = Tab:CreateDropdown({Label = settings.Label or "Player", Options = Players:GetPlayers(), Default = selected, Callback = callback})
            local originalFrame = selector:GetObject()
            frame:Destroy()
            task.spawn(function()
                while not destroyed and not tabDestroyed and selector:GetObject().Parent do
                    local options2 = Players:GetPlayers()
                    selector:Refresh(options2)
                    if selected and selected.Parent then selector:Set(selected, true) end
                    task.wait(refreshRate)
                end
            end)
            return selector
        end

        function Tab:Destroy()
            if tabDestroyed then return end
            tabDestroyed = true
            if activePopupCloser then activePopupCloser() end
            disconnectAll(tabConnections)
            if button.Parent then button:Destroy() end
            if page.Parent then page:Destroy() end
        end

        addConnection(tabConnections, button.Activated:Connect(function()
            Tab:Select()
        end))
        addConnection(tabConnections, button.MouseEnter:Connect(function()
            if currentTab ~= index then tween(button, {BackgroundColor3 = Theme.SurfaceBright}) end
        end))
        addConnection(tabConnections, button.MouseLeave:Connect(function()
            if currentTab ~= index then tween(button, {BackgroundColor3 = Theme.TabInactive}) end
        end))

        if not currentTab or settings.Select == true then
            Tab:Select()
        end
        return Tab
    end

    function Window:FindTab(name)
        name = tostring(name)
        for _, tab in ipairs(tabs) do
            if tab.Name == name then
                return tab
            end
        end
        return nil
    end

    function Window:SelectTab(nameOrIndex)
        local tab
        if type(nameOrIndex) == "number" then
            tab = tabs[nameOrIndex]
        else
            tab = self:FindTab(nameOrIndex)
        end
        if tab and tab.Page then
            local i = table.find(tabs, tab)
            for index, entry in ipairs(tabs) do
                local active = index == i
                entry.Page.Visible = active
                tween(entry.Button, {BackgroundColor3 = active and Theme.TabActive or Theme.TabInactive, TextColor3 = active and Theme.Background or Theme.TextSecondary})
            end
            currentTab = i
            self:SetToolbarStatus("TAB // " .. tostring(tab.Name):upper(), Theme.TextSecondary)
            return tab
        end
        return nil
    end

    local notifications = {}
    local notificationContainer = newFrame({Name = "Notifications", Color = Theme.Background, Trans = 1, Size = UDim2.fromOffset(340, 0), Pos = UDim2.new(1, -350, 1, -300), Z = 400, Parent = gui})
    local notificationLayout = Instance.new("UIListLayout")
    notificationLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    notificationLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    notificationLayout.Padding = UDim.new(0, 6)
    notificationLayout.Parent = notificationContainer

    local function notify(settings)
        settings = type(settings) == "table" and settings or {Title = "Notice", Content = tostring(settings)}
        local titleText = tostring(settings.Title or "Notice")
        local contentText = tostring(settings.Content or "")
        local duration = math.max(0.6, tonumber(settings.Duration) or 3.2)
        local accent = settings.Color or Theme.Accent
        local card = newFrame({Color = Theme.TitleBar, Size = UDim2.fromOffset(326, 0), Clip = true, Z = 410, Parent = notificationContainer})
        decorate(card, UDim.new(0, 5), accent, 1)
        local stripe = newFrame({Color = accent, Size = UDim2.fromOffset(3, 1), Parent = card, Z = 415})
        local titleNode = newLabel({Text = titleText:upper(), Color = accent, Font = Theme.FontMono, Size2 = 11, Size = UDim2.new(1, -20, 0, 18), Pos = UDim2.fromOffset(12, 7), Z = 415, Parent = card})
        local bodyNode = newLabel({Text = contentText, Color = Theme.TextPrimary, Font = Theme.FontUI, Size2 = 10, Size = UDim2.new(1, -24, 0, 34), Pos = UDim2.fromOffset(12, 27), Wrap = true, Z = 415, Parent = card})
        local targetHeight = math.clamp(45 + TextService:GetTextSize(contentText, 10, Theme.FontUI, Vector2.new(294, 100)).Y, 54, 108)
        bodyNode.Size = UDim2.new(1, -24, 0, targetHeight - 32)
        table.insert(notifications, card)
        tween(card, {Size = UDim2.fromOffset(326, targetHeight)}, Theme.TweenSlow)
        task.delay(duration, function()
            if not card.Parent then return end
            tween(card, {Size = UDim2.fromOffset(326, 0), BackgroundTransparency = 1}, Theme.TweenFast)
            task.delay(0.12, function()
                for i, item in ipairs(notifications) do
                    if item == card then table.remove(notifications, i); break end
                end
                if card.Parent then card:Destroy() end
            end)
        end)
        return card
    end

    function Window:Notify(settings)
        return notify(settings)
    end
    Window.Notification = Window.Notify

    local modalOverlay = newFrame({Name = "ModalOverlay", Color = Theme.Background, Trans = 0.28, Size = UDim2.fromScale(1, 1), Z = 500, Visible = false, Parent = gui})
    local modal = newFrame({Name = "Modal", Color = Theme.TitleBar, Size = UDim2.fromOffset(360, 0), Pos = UDim2.new(0.5, -180, 0.5, 0), Clip = true, Z = 510, Parent = modalOverlay})
    decorate(modal, UDim.new(0, 6), Theme.Border, 1)
    local modalTitle = newLabel({Text = "CONFIRM", Color = Theme.Accent, Font = Theme.FontMono, Size2 = 13, Size = UDim2.new(1, -24, 0, 22), Pos = UDim2.fromOffset(12, 8), Z = 515, Parent = modal})
    local modalBody = newLabel({Text = "", Color = Theme.TextPrimary, Font = Theme.FontUI, Size2 = 11, Size = UDim2.new(1, -24, 0, 50), Pos = UDim2.fromOffset(12, 31), Wrap = true, Z = 515, Parent = modal})
    local modalActions = newFrame({Name = "Actions", Color = Theme.TitleBar, Size = UDim2.new(1, -24, 0, 34), Pos = UDim2.fromOffset(12, 92), Z = 515, Parent = modal})
    local modalConfirm = Instance.new("TextButton")
    modalConfirm.BackgroundColor3 = Theme.AccentDim
    modalConfirm.Size = UDim2.new(0.48, -3, 1, 0)
    modalConfirm.Text = "CONFIRM"
    modalConfirm.Font = Theme.FontMono
    modalConfirm.TextSize = 10
    modalConfirm.TextColor3 = Theme.Background
    modalConfirm.BorderSizePixel = 0
    modalConfirm.ZIndex = 520
    modalConfirm.Parent = modalActions
    decorate(modalConfirm, UDim.new(0, 4), Theme.Accent, 1)
    local modalCancel = Instance.new("TextButton")
    modalCancel.BackgroundColor3 = Theme.Surface
    modalCancel.Size = UDim2.new(0.48, -3, 1, 0)
    modalCancel.Position = UDim2.new(0.52, 0, 0, 0)
    modalCancel.Text = "CANCEL"
    modalCancel.Font = Theme.FontMono
    modalCancel.TextSize = 10
    modalCancel.TextColor3 = Theme.TextSecondary
    modalCancel.BorderSizePixel = 0
    modalCancel.ZIndex = 520
    modalCancel.Parent = modalActions
    decorate(modalCancel, UDim.new(0, 4), Theme.BorderDim, 1)
    local modalOpen = false
    local modalCallback

    local function closeModal(result)
        if not modalOpen then return end
        modalOpen = false
        modalOverlay.Visible = false
        tween(modal, {Size = UDim2.fromOffset(360, 0)})
        local callback = modalCallback
        modalCallback = nil
        if callback then safeCall(callback, result) end
    end

    function Window:Confirm(settings)
        settings = settings or {}
        modalTitle.Text = tostring(settings.Title or "CONFIRM"):upper()
        modalBody.Text = tostring(settings.Content or "Are you sure?")
        modalConfirm.Text = tostring(settings.ConfirmText or "CONFIRM"):upper()
        modalCancel.Text = tostring(settings.CancelText or "CANCEL"):upper()
        modalCallback = settings.Callback
        modalOpen = true
        modalOverlay.Visible = true
        tween(modal, {Size = UDim2.fromOffset(360, 136)}, Theme.TweenSlow)
        return self
    end

    track(modalConfirm.Activated:Connect(function() closeModal(true) end))
    track(modalCancel.Activated:Connect(function() closeModal(false) end))

    function Window:OpenModal(titleText, bodyText, onResult)
        return self:Confirm({Title = titleText, Content = bodyText, Callback = onResult})
    end

    function Window:SetTheme(overrides)
        for key, value in pairs(overrides or {}) do
            if Theme[key] ~= nil then Theme[key] = value end
        end
        return self
    end

    function Window:GetTheme()
        local copy = {}
        for key, value in pairs(Theme) do copy[key] = value end
        return copy
    end

    function Window:ResetTheme()
        for key, value in pairs(themeBefore) do Theme[key] = value end
        return self
    end

    function Window:GetTabs()
        local result = {}
        for i, tab in ipairs(tabs) do result[i] = tab.Name end
        return result
    end

    function Window:UpdateFPS(text)
        fpsLabel.Text = tostring(text)
        return self
    end

    local fpsAccumulator = 0
    local fpsFrames = 0
    track(RunService.RenderStepped:Connect(function(delta)
        if destroyed then return end
        fpsAccumulator += delta
        fpsFrames += 1
        if fpsAccumulator >= 0.5 then
            local fps = fpsFrames / fpsAccumulator
            fpsLabel.Text = "FPS " .. formatNumber(fps, 0)
            fpsAccumulator = 0
            fpsFrames = 0
        end
    end))

    makeDraggable(titleBar, root, connections, function(position)
        previousPosition = position
    end)

    track(minimizeButton.Activated:Connect(function()
        if minimized then Window:Restore() else Window:Minimize() end
    end))
    track(maximizeButton.Activated:Connect(function()
        if maximized then Window:Unmaximize() else Window:Maximize() end
    end))
    track(closeButton.Activated:Connect(function()
        Window:Destroy()
    end))

    track(UserInputService.InputBegan:Connect(function(input, processed)
        if destroyed or processed then return end
        if toggleKey and input.KeyCode == toggleKey then
            Window:Toggle()
        end
    end))

    function Window:Destroy()
        if destroyed then return end
        destroyed = true
        disconnectAll(connections)
        if activePopupCloser then activePopupCloser() end
        if modalOpen then closeModal(false) end
        for _, tab in ipairs(tabs) do
            if tab.Page then tab.Page:Destroy() end
            if tab.Button then tab.Button:Destroy() end
        end
        if gui then
            tween(root, {Size = UDim2.fromOffset(root.AbsoluteSize.X, 0), BackgroundTransparency = 1}, Theme.TweenSlow)
            task.delay(0.28, function()
                if gui then pcall(gui.Destroy, gui) end
            end)
        end
    end

    local function buildDebugTab()
        if options.DebugTab == false then return end
        local tab = Window:CreateTab(options.DebugTabName or "Debug", {Prefix = "◆", Select = not options.StartTab})
        tab:CreateSection("Runtime")
        local console = tab:CreateConsole({Height = 180, MaxLines = 300})
        console:Info("PlasmaLibUI " .. Library.Version .. " initialized")
        local statsLabel = tab:CreateLabel("Collecting runtime diagnostics...", {Height = 24})
        tab:CreateButton({Label = "Refresh Diagnostics", Callback = function()
            local playerCount = #Players:GetPlayers()
            local ping = "--"
            pcall(function()
                local network = Stats.Network.ServerStatsItem["Data Ping"]
                ping = tostring(math.floor(network:GetValue())) .. " ms"
            end)
            statsLabel:GetObject():FindFirstChildWhichIsA("TextLabel").Text = string.format("Players: %d   Ping: %s   Place: %s", playerCount, ping, tostring(game.PlaceId))
            console:Info("Diagnostics refreshed")
        end})
        tab:CreateButton({Label = "Center Window", Callback = function() Window:Center() end})
        tab:CreateButton({Label = "Clear Console", Callback = function() console:Clear() end})
    end

    buildDebugTab()

    if options.StartTab then
        Window:SelectTab(options.StartTab)
    end

    if options.Visible == false then
        root.Visible = false
    else
        root.Visible = true
        tween(root, {Size = UDim2.fromOffset(width, height)}, Theme.TweenSlow)
    end

    return Window
end

function Library:SetTheme(overrides)
    for key, value in pairs(overrides or {}) do
        if Theme[key] ~= nil then Theme[key] = value end
    end
    return self
end

function Library:GetTheme()
    local copy = {}
    for key, value in pairs(Theme) do copy[key] = value end
    return copy
end

function Library:CreateNotification(settings)
    settings = settings or {}
    local gui = Instance.new("ScreenGui")
    gui.Name = "PlasmaLibUI_NotificationHost"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 1000
    gui.Parent = getGuiParent()
    local card = newFrame({Color = Theme.TitleBar, Size = UDim2.fromOffset(320, 62), Pos = UDim2.new(1, -332, 1, -74), Z = 20, Parent = gui})
    decorate(card, UDim.new(0, 5), settings.Color or Theme.Accent, 1)
    newLabel({Text = tostring(settings.Title or "NOTICE"):upper(), Color = settings.Color or Theme.Accent, Font = Theme.FontMono, Size2 = 11, Size = UDim2.new(1, -20, 0, 20), Pos = UDim2.fromOffset(10, 7), Parent = card, Z = 22})
    newLabel({Text = tostring(settings.Content or ""), Color = Theme.TextPrimary, Font = Theme.FontUI, Size2 = 10, Size = UDim2.new(1, -20, 0, 28), Pos = UDim2.fromOffset(10, 29), Wrap = true, Parent = card, Z = 22})
    task.delay(math.max(0.5, tonumber(settings.Duration) or 3), function()
        if gui.Parent then gui:Destroy() end
    end)
    return gui
end

function Library:GetVersion()
    return Library.Version
end

return Library
