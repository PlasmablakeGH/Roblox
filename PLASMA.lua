--[[
    PlasmaLibUI
    Modular Roblox Luau UI Library

    This is a clean-room implementation that preserves the familiar
    PlasmaLibUI-style public API while adding an optional contextual
    player interaction system.

    Basic usage:
        local Library = loadstring(game:HttpGet(RAW_URL, true))()
        local Window = Library:CreateWindow({
            Title = "My Tool",
            IconId = "rbxassetid://7072706620",
            ToggleKey = Enum.KeyCode.RightControl,
            Scanlines = true,
            Click = true,
        })

    Click system:
        Click = true enables right-click player detection.

        Window.Click:SetCallbacks({
            OnStripTools = function(player, character)
                -- Connect this to your own AUTHORIZED server API.
            end,
            OnHighlightPlayer = function(player, character)
                -- optional; returning true/false updates the state label
            end,
            OnTeleportTo = function(player, character)
                -- optional; returning true means success
            end,
        })

        Window.Click:Open(player)
        Window.Click:Close()
        Window.Click:GetTarget()
        Window.Click:Destroy()

    Security note:
        The library deliberately does not hard-code arbitrary remote-event
        abuse. Game-owned server remotes should validate permissions server-side.
--]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local TextService = game:GetService("TextService")
local RunService = game:GetService("RunService")

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
    Warning = Color3.fromRGB(255, 190, 40),
    SliderFill = Color3.fromRGB(0, 220, 90),
    SliderTrack = Color3.fromRGB(15, 35, 15),
    ToggleOn = Color3.fromRGB(0, 220, 90),
    ToggleOff = Color3.fromRGB(20, 40, 20),
    ToggleKnob = Color3.fromRGB(200, 255, 210),
    Scanline = Color3.fromRGB(0, 255, 100),
    TabActive = Color3.fromRGB(0, 200, 75),
    TabInactive = Color3.fromRGB(0, 45, 18),
    TitleBar = Color3.fromRGB(6, 16, 6),
    CornerRadius = UDim.new(0, 0),
    BorderThickness = 1,
    FontMono = Enum.Font.Code,
    FontUI = Enum.Font.GothamMedium,
    FontBold = Enum.Font.GothamBold,
    TextSizeTitle = 15,
    TextSizeBody = 13,
    TextSizeSmall = 11,
    Tween = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    TweenFast = TweenInfo.new(0.10, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    TweenSlow = TweenInfo.new(0.30, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
}

local function safeCall(fn, ...)
    if type(fn) ~= "function" then
        return false, nil
    end
    return pcall(fn, ...)
end

local function tween(instance, properties, info)
    if not instance or not instance.Parent then
        return
    end
    local ok, tw = pcall(TweenService.Create, TweenService, instance, info or Theme.Tween, properties)
    if ok and tw then
        tw:Play()
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
    label.Size = data.Size or UDim2.fromScale(1, 1)
    label.Position = data.Pos or UDim2.fromOffset(0, 0)
    label.ZIndex = data.Z or 5
    label.Parent = data.Parent
    return label
end

local function getGuiParent()
    if typeof(gethui) == "function" then
        local ok, result = pcall(gethui)
        if ok and result then
            return result
        end
    end

    local okCore, core = pcall(function()
        return game:GetService("CoreGui")
    end)
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

    if input:find("^rbxasset") or input:find("^rbxthumb") then
        return input
    end

    if input:sub(1, 7) == "http://" or input:sub(1, 8) == "https://" then
        local haveFs = type(writefile) == "function" and type(getcustomasset) == "function" and type(game.HttpGet) == "function"
        if not haveFs then
            return ""
        end

        local safeName = "PlasmaIcon_" .. input:gsub("[^%w]", "_"):sub(-48) .. ".png"
        if type(isfile) == "function" then
            local okFile, exists = pcall(isfile, safeName)
            if okFile and exists then
                local okAsset, asset = pcall(getcustomasset, safeName)
                if okAsset then
                    return asset
                end
            end
        end

        local ok, result = pcall(function()
            local data = game:HttpGet(input)
            writefile(safeName, data)
            return getcustomasset(safeName)
        end)
        return ok and result or ""
    end

    if type(isfile) == "function" and type(getcustomasset) == "function" then
        local ok, exists = pcall(isfile, input)
        if ok and exists then
            local assetOK, asset = pcall(getcustomasset, input)
            if assetOK then
                return asset
            end
        end
    end

    return input
end

local function addScanlines(parent, count)
    count = math.clamp(count or 60, 12, 100)

    local overlay = newFrame({
        Name = "Scanlines",
        Trans = 1,
        Z = 40,
        Parent = parent,
    })

    local layout = Instance.new("UIGridLayout")
    layout.CellSize = UDim2.new(1, 0, 0, 2)
    layout.CellPadding = UDim2.new(0, 0, 0, 2)
    layout.Parent = overlay

    for _ = 1, count do
        local line = newFrame({
            Color = Theme.Scanline,
            Trans = 0.965,
            Size = UDim2.new(1, 0, 0, 2),
            Parent = overlay,
        })
    end
end

local function makeDraggable(handle, target, track)
    local active = false
    local origin = Vector2.zero
    local start = target.Position

    local function clampPosition(position)
        local camera = workspace.CurrentCamera
        local viewport = camera and camera.ViewportSize or Vector2.new(1920, 1080)
        local size = target.AbsoluteSize
        local visible = 44

        local minX = visible - size.X - viewport.X * position.X.Scale
        local maxX = viewport.X - visible - viewport.X * position.X.Scale
        local minY = 0 - viewport.Y * position.Y.Scale
        local maxY = viewport.Y - visible - viewport.Y * position.Y.Scale

        return UDim2.new(
            position.X.Scale,
            math.clamp(position.X.Offset, minX, maxX),
            position.Y.Scale,
            math.clamp(position.Y.Offset, minY, maxY)
        )
    end

    local c1 = handle.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end
        active = true
        origin = input.Position
        start = target.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                active = false
            end
        end)
    end)

    local c2 = UserInputService.InputChanged:Connect(function(input)
        if not active then
            return
        end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end

        local delta = input.Position - origin
        target.Position = clampPosition(UDim2.new(
            start.X.Scale,
            start.X.Offset + delta.X,
            start.Y.Scale,
            start.Y.Offset + delta.Y
        ))
    end)

    if track then
        track(c1)
        track(c2)
    end
end

local function pointInside(guiObject, position)
    if not guiObject or not guiObject.Parent then
        return false
    end

    local absolute = guiObject.AbsolutePosition
    local size = guiObject.AbsoluteSize
    return position.X >= absolute.X
        and position.X <= absolute.X + size.X
        and position.Y >= absolute.Y
        and position.Y <= absolute.Y + size.Y
end

local function getMousePosition()
    local ok, position = pcall(UserInputService.GetMouseLocation, UserInputService)
    if ok and position then
        return Vector2.new(position.X, position.Y)
    end
    return Vector2.new(0, 0)
end

local function resolveCharacterFromPart(part)
    if not part or not part.Parent then
        return nil, nil
    end

    local model = part:FindFirstAncestorOfClass("Model")
    if not model then
        return nil, nil
    end

    local player = Players:GetPlayerFromCharacter(model)
    if not player or player == LocalPlayer then
        return nil, nil
    end

    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        return nil, nil
    end

    return player, model
end

local function getCharacterRoot(character)
    if not character then
        return nil
    end
    local root = character:FindFirstChild("HumanoidRootPart")
    if root and root:IsA("BasePart") then
        return root
    end
    local primary = character.PrimaryPart
    if primary and primary:IsA("BasePart") then
        return primary
    end
    return character:FindFirstChildWhichIsA("BasePart")
end

local function safeCharacter(player)
    if not player or player == LocalPlayer then
        return nil
    end
    local character = player.Character
    if not character or not character.Parent then
        return nil
    end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then
        return nil
    end
    return character
end

local function createButton(parent, text, order, callback)
    local button = Instance.new("TextButton")
    button.Name = "Button_" .. tostring(order)
    button.LayoutOrder = order
    button.BackgroundColor3 = Theme.Surface
    button.BorderSizePixel = 0
    button.Size = UDim2.new(1, 0, 0, 31)
    button.Text = "▶  " .. tostring(text):upper()
    button.Font = Theme.FontMono
    button.TextSize = Theme.TextSizeSmall
    button.TextColor3 = Theme.Accent
    button.TextXAlignment = Enum.TextXAlignment.Left
    button.AutoButtonColor = false
    button.ZIndex = 112
    button.Parent = parent

    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 9)
    padding.Parent = button

    decorate(button, UDim.new(0, 3), Theme.BorderDim, 1)

    button.MouseEnter:Connect(function()
        tween(button, {
            BackgroundColor3 = Theme.SurfaceAlt,
            TextColor3 = Theme.TextPrimary,
        }, Theme.TweenFast)
    end)

    button.MouseLeave:Connect(function()
        tween(button, {
            BackgroundColor3 = Theme.Surface,
            TextColor3 = Theme.Accent,
        }, Theme.TweenFast)
    end)

    button.MouseButton1Down:Connect(function()
        tween(button, {
            BackgroundColor3 = Theme.AccentDim,
            TextColor3 = Theme.Background,
        }, Theme.TweenFast)
    end)

    button.MouseButton1Up:Connect(function()
        tween(button, {
            BackgroundColor3 = Theme.SurfaceAlt,
            TextColor3 = Theme.TextPrimary,
        }, Theme.TweenFast)
    end)

    button.MouseButton1Click:Connect(function()
        safeCall(callback)
    end)

    return button
end

local Library = {}
Library.__index = Library

function Library:CreateWindow(options)
    options = options or {}

    local title = tostring(options.Title or "PlasmaLibUI")
    local icon = getIconAsset(options.IconId or "rbxassetid://7072706620")
    local width = math.clamp(tonumber(options.Width) or 500, 300, 900)
    local height = math.clamp(tonumber(options.Height) or 380, 220, 800)
    local scanlines = options.Scanlines ~= false
    local toggleKey = options.ToggleKey
    local clickEnabled = options.Click == true

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "PlasmaLibUI_" .. title:gsub("[^%w]", "")
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.DisplayOrder = tonumber(options.DisplayOrder) or 999
    screenGui.Parent = getGuiParent()

    local root = newFrame({
        Name = "Window",
        Color = Theme.Background,
        Size = UDim2.fromOffset(width, 0),
        Pos = UDim2.new(0.5, -width / 2, 0.5, -height / 2),
        Clip = true,
        Z = 2,
        Parent = screenGui,
    })
    decorate(root, UDim.new(0, 0), Theme.Border, 1)

    if scanlines then
        addScanlines(root, math.floor(height / 4))
    end

    newFrame({
        Name = "TopAccent",
        Color = Theme.Accent,
        Size = UDim2.new(1, 0, 0, 2),
        Z = 50,
        Parent = root,
    })

    local connections = {}
    local destroyed = false
    local function track(connection)
        if connection then
            table.insert(connections, connection)
        end
        return connection
    end

    local Window = {}

    ---------------------------------------------------------------------
    -- Title bar
    ---------------------------------------------------------------------
    local titleBar = newFrame({
        Name = "TitleBar",
        Color = Theme.TitleBar,
        Size = UDim2.new(1, 0, 0, 38),
        Pos = UDim2.fromOffset(0, 2),
        Z = 5,
        Parent = root,
    })

    local iconImage = Instance.new("ImageLabel")
    iconImage.Name = "Icon"
    iconImage.BackgroundTransparency = 1
    iconImage.Size = UDim2.fromOffset(22, 22)
    iconImage.Position = UDim2.new(0, 8, 0.5, -11)
    iconImage.Image = icon
    iconImage.ImageColor3 = Theme.Accent
    iconImage.ZIndex = 8
    iconImage.Parent = titleBar

    newLabel({
        Name = "Title",
        Text = "[ " .. title:upper() .. " ]",
        Color = Theme.Accent,
        Font = Theme.FontMono,
        Size2 = Theme.TextSizeTitle,
        Size = UDim2.new(1, -105, 1, 0),
        Pos = UDim2.fromOffset(38, 0),
        Z = 8,
        Parent = titleBar,
    })

    local minimize = Instance.new("TextButton")
    minimize.Name = "Minimize"
    minimize.BackgroundColor3 = Theme.Surface
    minimize.Size = UDim2.fromOffset(28, 20)
    minimize.Position = UDim2.new(1, -66, 0.5, -10)
    minimize.Text = "_"
    minimize.Font = Theme.FontBold
    minimize.TextSize = 15
    minimize.TextColor3 = Theme.Accent
    minimize.BorderSizePixel = 0
    minimize.AutoButtonColor = false
    minimize.ZIndex = 9
    minimize.Parent = titleBar
    decorate(minimize, UDim.new(0, 3), Theme.Border, 1)

    local close = Instance.new("TextButton")
    close.Name = "Close"
    close.BackgroundColor3 = Color3.fromRGB(28, 8, 8)
    close.Size = UDim2.fromOffset(28, 20)
    close.Position = UDim2.new(1, -34, 0.5, -10)
    close.Text = "X"
    close.Font = Theme.FontBold
    close.TextSize = 13
    close.TextColor3 = Theme.Danger
    close.BorderSizePixel = 0
    close.AutoButtonColor = false
    close.ZIndex = 9
    close.Parent = titleBar
    decorate(close, UDim.new(0, 3), Theme.Danger, 1)

    track(minimize.MouseEnter:Connect(function()
        tween(minimize, {BackgroundColor3 = Theme.SurfaceAlt})
    end))
    track(minimize.MouseLeave:Connect(function()
        tween(minimize, {BackgroundColor3 = Theme.Surface})
    end))
    track(close.MouseEnter:Connect(function()
        tween(close, {BackgroundColor3 = Theme.Danger, TextColor3 = Color3.new(1, 1, 1)})
    end))
    track(close.MouseLeave:Connect(function()
        tween(close, {BackgroundColor3 = Color3.fromRGB(28, 8, 8), TextColor3 = Theme.Danger})
    end))

    makeDraggable(titleBar, root, track)

    ---------------------------------------------------------------------
    -- Tabs / content
    ---------------------------------------------------------------------
    local tabBar = Instance.new("ScrollingFrame")
    tabBar.Name = "TabBar"
    tabBar.BackgroundColor3 = Theme.TitleBar
    tabBar.BorderSizePixel = 0
    tabBar.Size = UDim2.new(1, 0, 0, 30)
    tabBar.Position = UDim2.fromOffset(0, 40)
    tabBar.ZIndex = 6
    tabBar.ScrollingDirection = Enum.ScrollingDirection.X
    tabBar.ScrollBarThickness = 2
    tabBar.ScrollBarImageColor3 = Theme.AccentDim
    tabBar.CanvasSize = UDim2.new()
    tabBar.AutomaticCanvasSize = Enum.AutomaticSize.X
    tabBar.Parent = root

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Padding = UDim.new(0, 2)
    tabLayout.Parent = tabBar

    local tabPadding = Instance.new("UIPadding")
    tabPadding.PaddingLeft = UDim.new(0, 4)
    tabPadding.Parent = tabBar

    local contentTop = 71
    local statusHeight = 18

    local content = newFrame({
        Name = "ContentArea",
        Color = Theme.Background,
        Size = UDim2.new(1, 0, 1, -(contentTop + statusHeight)),
        Pos = UDim2.fromOffset(0, contentTop),
        Z = 3,
        Parent = root,
    })

    local status = newFrame({
        Name = "StatusBar",
        Color = Theme.TitleBar,
        Size = UDim2.new(1, 0, 0, statusHeight),
        Pos = UDim2.new(0, 0, 1, -statusHeight),
        Z = 6,
        Parent = root,
    })

    local statusText = newLabel({
        Text = "◈ PLASMA // ONLINE",
        Color = Theme.BorderDim,
        Font = Theme.FontMono,
        Size2 = 10,
        AlignX = Enum.TextXAlignment.Center,
        Z = 7,
        Parent = status,
    })

    local minimized = false
    local tabs = {}
    local activeTab = 0
    local activeDropdownCloser

    local function setActiveTab(index)
        if activeTab == index then
            return
        end
        activeTab = index
        for i, entry in ipairs(tabs) do
            local active = i == index
            entry.page.Visible = active
            tween(entry.button, {
                BackgroundColor3 = active and Theme.TabActive or Theme.TabInactive,
                TextColor3 = active and Theme.Background or Theme.TextSecondary,
            })
        end
    end

    function Window:SetIcon(id)
        iconImage.Image = getIconAsset(id)
    end

    function Window:SetStatus(text)
        statusText.Text = tostring(text)
    end

    function Window:GetGui()
        return screenGui
    end

    function Window:IsMinimized()
        return minimized
    end

    function Window:Toggle()
        if minimized then
            minimized = false
            tabBar.Visible = true
            content.Visible = true
            status.Visible = true
            tween(root, {Size = UDim2.fromOffset(width, height)}, Theme.TweenSlow)
        else
            minimized = true
            tabBar.Visible = false
            content.Visible = false
            status.Visible = false
            tween(root, {Size = UDim2.fromOffset(width, 40)}, Theme.TweenSlow)
        end
    end

    track(minimize.MouseButton1Click:Connect(function()
        Window:Toggle()
    end))

    ---------------------------------------------------------------------
    -- Contextual player interaction system
    ---------------------------------------------------------------------
    local ClickSystem

    if clickEnabled then
        ClickSystem = {}

        local playerMenu = newFrame({
            Name = "PlayerContextMenu",
            Color = Theme.TitleBar,
            Size = UDim2.fromOffset(228, 0),
            Pos = UDim2.fromOffset(0, 0),
            Clip = true,
            Z = 100,
            Parent = screenGui,
        })
        playerMenu.Visible = false
        decorate(playerMenu, UDim.new(0, 5), Theme.Border, 1)

        local menuAccent = newFrame({
            Name = "Accent",
            Color = Theme.Accent,
            Size = UDim2.new(1, 0, 0, 2),
            Z = 110,
            Parent = playerMenu,
        })

        local avatar = Instance.new("ImageLabel")
        avatar.Name = "Avatar"
        avatar.BackgroundColor3 = Theme.Surface
        avatar.Size = UDim2.fromOffset(40, 40)
        avatar.Position = UDim2.fromOffset(9, 10)
        avatar.BorderSizePixel = 0
        avatar.ZIndex = 111
        avatar.Parent = playerMenu
        decorate(avatar, UDim.new(0, 4), Theme.BorderDim, 1)

        local nameLabel = newLabel({
            Name = "Name",
            Text = "[ PLAYER ]",
            Color = Theme.TextPrimary,
            Font = Theme.FontBold,
            Size2 = 13,
            Size = UDim2.new(1, -62, 0, 19),
            Pos = UDim2.fromOffset(59, 9),
            Z = 112,
            Parent = playerMenu,
        })

        local usernameLabel = newLabel({
            Name = "Username",
            Text = "@unknown",
            Color = Theme.TextSecondary,
            Font = Theme.FontMono,
            Size2 = 10,
            Size = UDim2.new(1, -62, 0, 16),
            Pos = UDim2.fromOffset(59, 29),
            Z = 112,
            Parent = playerMenu,
        })

        local stateLabel = newLabel({
            Name = "State",
            Text = "● READY",
            Color = Theme.Accent,
            Font = Theme.FontMono,
            Size2 = 9,
            AlignX = Enum.TextXAlignment.Right,
            Size = UDim2.fromOffset(68, 16),
            Pos = UDim2.new(1, -77, 0, 46),
            Z = 112,
            Parent = playerMenu,
        })

        local separator = newFrame({
            Color = Theme.BorderDim,
            Size = UDim2.new(1, -18, 0, 1),
            Pos = UDim2.fromOffset(9, 57),
            Z = 112,
            Parent = playerMenu,
        })

        local actions = newFrame({
            Name = "Actions",
            Trans = 1,
            Size = UDim2.new(1, -18, 0, 0),
            Pos = UDim2.fromOffset(9, 64),
            Z = 112,
            Parent = playerMenu,
        })

        local actionLayout = Instance.new("UIListLayout")
        actionLayout.Padding = UDim.new(0, 5)
        actionLayout.SortOrder = Enum.SortOrder.LayoutOrder
        actionLayout.Parent = actions

        local menuHint = newLabel({
            Name = "Hint",
            Text = "RMB target  //  LMB outside to close",
            Color = Theme.TextDisabled,
            Font = Theme.FontMono,
            Size2 = 8,
            AlignX = Enum.TextXAlignment.Center,
            Size = UDim2.new(1, -16, 0, 14),
            Pos = UDim2.new(0, 8, 1, -18),
            Z = 112,
            Parent = playerMenu,
        })

        local selectedPlayer
        local selectedCharacter
        local highlighted = setmetatable({}, {__mode = "k"})
        local clickConnections = {}
        local menuOpen = false
        local menuToken = 0
        local callbacks = {
            OnStripTools = options.OnStripTools,
            OnHighlightPlayer = options.OnHighlightPlayer,
            OnTeleportTo = options.OnTeleportTo,
        }

        local DEFAULT_HEIGHT = 205
        local ACTION_HEIGHT = 31
        local function actionMenuHeight(count)
            return 82 + count * ACTION_HEIGHT + math.max(0, count - 1) * 5
        end

        local function trackClick(connection)
            if connection then
                table.insert(clickConnections, connection)
            end
            return connection
        end

        local function setState(text, color)
            stateLabel.Text = tostring(text)
            stateLabel.TextColor3 = color or Theme.Accent
        end

        local function clearActionButtons()
            for _, child in ipairs(actions:GetChildren()) do
                if child:IsA("GuiButton") then
                    child:Destroy()
                end
            end
        end

        local function getHighlight(player, character)
            local object = highlighted[player]
            if object and object.Parent then
                return object
            end

            local existing = character and character:FindFirstChild("PlasmaLibUI_Highlight")
            if existing and existing:IsA("Highlight") then
                highlighted[player] = existing
                return existing
            end

            return nil
        end

        local function toggleLocalHighlight(player, character)
            if not player or not character then
                return false
            end

            local existing = getHighlight(player, character)
            if existing then
                pcall(existing.Destroy, existing)
                highlighted[player] = nil
                return false
            end

            local highlight = Instance.new("Highlight")
            highlight.Name = "PlasmaLibUI_Highlight"
            highlight.Adornee = character
            highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            highlight.FillColor = Theme.Accent
            highlight.FillTransparency = 0.82
            highlight.OutlineColor = Theme.Accent
            highlight.OutlineTransparency = 0
            highlight.Parent = character
            highlighted[player] = highlight
            return true
        end

        local function defaultHighlight(player, character)
            return toggleLocalHighlight(player, character)
        end

        local function defaultTeleport(player, character)
            local localCharacter = LocalPlayer.Character
            local localRoot = getCharacterRoot(localCharacter)
            local targetRoot = getCharacterRoot(character)

            if not localRoot or not targetRoot then
                return false
            end

            return pcall(function()
                localRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 3)
            end)
        end

        local function runAction(name, callback)
            if not selectedPlayer or not selectedCharacter then
                return
            end

            local player = selectedPlayer
            local character = selectedCharacter

            ClickSystem:Close()

            local ok, result = safeCall(callback, player, character)
            if not ok then
                warn("[PlasmaLibUI] " .. tostring(name) .. " failed:", result)
            end
        end

        local function makePlayerAction(label, order, callback)
            return createButton(actions, label, order, function()
                runAction(label, callback)
            end)
        end

        local function rebuildActions()
            clearActionButtons()

            makePlayerAction("Strip Tools", 1, callbacks.OnStripTools or function()
                warn("[PlasmaLibUI] Strip Tools has no authorized callback configured.")
            end)

            makePlayerAction("Highlight Player", 2, callbacks.OnHighlightPlayer or defaultHighlight)
            makePlayerAction("Teleport To", 3, callbacks.OnTeleportTo or defaultTeleport)

            local total = 3
            local height = actionMenuHeight(total)
            actions.Size = UDim2.new(1, -18, 0, total * ACTION_HEIGHT + (total - 1) * 5)
            return height
        end

        local function clampMenu(x, y, w, h)
            local camera = workspace.CurrentCamera
            local viewport = camera and camera.ViewportSize or Vector2.new(1920, 1080)
            local margin = 6

            local finalX = x
            local finalY = y
            if finalX + w > viewport.X - margin then
                finalX = x - w
            end
            if finalY + h > viewport.Y - margin then
                finalY = viewport.Y - h - margin
            end

            return math.clamp(finalX, margin, math.max(margin, viewport.X - w - margin)),
                math.clamp(finalY, margin, math.max(margin, viewport.Y - h - margin))
        end

        local function refreshTargetVisuals(player, character)
            nameLabel.Text = "[ " .. tostring((player.DisplayName ~= "" and player.DisplayName or player.Name):upper()) .. " ]"
            usernameLabel.Text = "@" .. player.Name

            local ok, content = pcall(function()
                return Players:GetUserThumbnailAsync(
                    player.UserId,
                    Enum.ThumbnailType.HeadShot,
                    Enum.ThumbnailSize.Size100x100
                )
            end)
            if ok then
                avatar.Image = content
            else
                avatar.Image = ""
            end

            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health > 0 then
                setState("● READY", Theme.Accent)
            else
                setState("● OFFLINE", Theme.Danger)
            end
        end

        function ClickSystem:SetCallbacks(newCallbacks)
            newCallbacks = newCallbacks or {}
            if newCallbacks.OnStripTools ~= nil then
                callbacks.OnStripTools = newCallbacks.OnStripTools
            end
            if newCallbacks.OnHighlightPlayer ~= nil then
                callbacks.OnHighlightPlayer = newCallbacks.OnHighlightPlayer
            end
            if newCallbacks.OnTeleportTo ~= nil then
                callbacks.OnTeleportTo = newCallbacks.OnTeleportTo
            end
            return self
        end

        function ClickSystem:GetTarget()
            return selectedPlayer, selectedCharacter
        end

        function ClickSystem:IsOpen()
            return menuOpen
        end

        function ClickSystem:Close()
            if not menuOpen then
                return
            end

            menuOpen = false
            menuToken += 1
            local token = menuToken

            local targetSize = UDim2.fromOffset(228, 0)
            tween(playerMenu, {
                Size = targetSize,
                BackgroundTransparency = 0.15,
            }, Theme.TweenFast)

            task.delay(0.11, function()
                if destroyed or menuOpen or token ~= menuToken then
                    return
                end
                playerMenu.Visible = false
            end)
        end

        function ClickSystem:Open(player, character, position)
            if not player or player == LocalPlayer then
                return false
            end

            character = character or safeCharacter(player)
            if not character then
                return false
            end

            selectedPlayer = player
            selectedCharacter = character
            refreshTargetVisuals(player, character)

            local menuHeight = rebuildActions()
            local point = position or getMousePosition()
            local x, y = clampMenu(point.X, point.Y, 228, menuHeight)

            menuToken += 1
            menuOpen = true
            playerMenu.Visible = true
            playerMenu.Position = UDim2.fromOffset(x, y)
            playerMenu.Size = UDim2.fromOffset(228, 0)
            playerMenu.BackgroundTransparency = 0.22

            tween(playerMenu, {
                Size = UDim2.fromOffset(228, menuHeight),
                BackgroundTransparency = 0,
            }, Theme.TweenSlow)

            return true
        end

        function ClickSystem:Highlight(player, character)
            player = player or selectedPlayer
            character = character or selectedCharacter or (player and safeCharacter(player))
            if not player or not character then
                return false
            end
            return safeCall(callbacks.OnHighlightPlayer or defaultHighlight, player, character)
        end

        function ClickSystem:Teleport(player, character)
            player = player or selectedPlayer
            character = character or selectedCharacter or (player and safeCharacter(player))
            if not player or not character then
                return false
            end
            return safeCall(callbacks.OnTeleportTo or defaultTeleport, player, character)
        end

        function ClickSystem:Destroy()
            self:Close()
            for player, highlight in pairs(highlighted) do
                if highlight then
                    pcall(highlight.Destroy, highlight)
                end
                highlighted[player] = nil
            end
            for _, connection in ipairs(clickConnections) do
                pcall(connection.Disconnect, connection)
            end
            table.clear(clickConnections)
            pcall(playerMenu.Destroy, playerMenu)
        end

        -- One input listener is used instead of creating a new connection every time.
        trackClick(UserInputService.InputBegan:Connect(function(input, processed)
            if destroyed then
                return
            end

            if input.UserInputType == Enum.UserInputType.MouseButton2 then
                if pointInside(playerMenu, input.Position) then
                    return
                end

                local mouse = LocalPlayer:GetMouse()
                local player, character = resolveCharacterFromPart(mouse.Target)
                if player and character then
                    ClickSystem:Open(player, character, input.Position)
                else
                    ClickSystem:Close()
                end
                return
            end

            if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2)
                and menuOpen
                and not pointInside(playerMenu, input.Position) then
                ClickSystem:Close()
            end
        end))

        trackClick(UserInputService.InputChanged:Connect(function(input)
            if not menuOpen then
                return
            end
            if input.UserInputType == Enum.UserInputType.MouseMovement then
                -- Keep the menu visually attached to the viewport, but do not move it after opening.
                -- This branch intentionally stays lightweight for executor environments.
            end
        end))

        trackClick(Players.PlayerRemoving:Connect(function(player)
            local highlight = highlighted[player]
            if highlight then
                pcall(highlight.Destroy, highlight)
            end
            highlighted[player] = nil

            if selectedPlayer == player then
                selectedPlayer = nil
                selectedCharacter = nil
                ClickSystem:Close()
            end
        end))

        trackClick(RunService.RenderStepped:Connect(function()
            if not menuOpen then
                return
            end

            if not selectedPlayer or not selectedCharacter or not selectedCharacter.Parent then
                ClickSystem:Close()
                return
            end

            if selectedPlayer.Character ~= selectedCharacter then
                selectedCharacter = safeCharacter(selectedPlayer)
                if not selectedCharacter then
                    ClickSystem:Close()
                end
            end
        end))

        Window.Click = ClickSystem
    else
        Window.Click = nil
    end

    ---------------------------------------------------------------------
    -- Toggle key
    ---------------------------------------------------------------------
    if toggleKey then
        track(UserInputService.InputBegan:Connect(function(input, processed)
            if processed or destroyed then
                return
            end
            if input.KeyCode == toggleKey then
                root.Visible = not root.Visible
                if not root.Visible and Window.Click then
                    Window.Click:Close()
                end
            end
        end))
    end

    ---------------------------------------------------------------------
    -- Window destroy
    ---------------------------------------------------------------------
    function Window:Destroy()
        if destroyed then
            return
        end
        destroyed = true

        if Window.Click then
            pcall(Window.Click.Destroy, Window.Click)
        end

        for _, connection in ipairs(connections) do
            pcall(connection.Disconnect, connection)
        end
        table.clear(connections)

        pcall(function()
            tween(root, {Size = UDim2.fromOffset(width, 0)}, Theme.TweenSlow)
            task.delay(0.30, function()
                if screenGui then
                    pcall(screenGui.Destroy, screenGui)
                end
            end)
        end)
    end

    ---------------------------------------------------------------------
    -- CreateTab
    ---------------------------------------------------------------------
    function Window:CreateTab(name)
        name = tostring(name or "Tab")

        local measured = TextService:GetTextSize(
            name:upper(),
            Theme.TextSizeSmall,
            Theme.FontMono,
            Vector2.new(1000, 20)
        )
        local buttonWidth = math.clamp(measured.X + 24, 64, 160)

        local button = Instance.new("TextButton")
        button.Name = "TabBtn_" .. name:gsub("%W", "_")
        button.BackgroundColor3 = Theme.TabInactive
        button.Size = UDim2.new(0, buttonWidth, 1, -6)
        button.Text = name:upper()
        button.Font = Theme.FontMono
        button.TextSize = Theme.TextSizeSmall
        button.TextColor3 = Theme.TextSecondary
        button.BorderSizePixel = 0
        button.AutoButtonColor = false
        button.LayoutOrder = #tabs + 1
        button.ZIndex = 8
        button.Parent = tabBar
        decorate(button, UDim.new(0, 3), false)

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
        page.ZIndex = 4
        page.Parent = content

        local list = Instance.new("UIListLayout")
        list.SortOrder = Enum.SortOrder.LayoutOrder
        list.Padding = UDim.new(0, 6)
        list.Parent = page

        local pagePadding = Instance.new("UIPadding")
        pagePadding.PaddingTop = UDim.new(0, 8)
        pagePadding.PaddingLeft = UDim.new(0, 10)
        pagePadding.PaddingRight = UDim.new(0, 10)
        pagePadding.PaddingBottom = UDim.new(0, 8)
        pagePadding.Parent = page

        local index = #tabs + 1
        tabs[index] = {button = button, page = page}

        button.MouseButton1Click:Connect(function()
            setActiveTab(index)
        end)
        button.MouseEnter:Connect(function()
            if activeTab ~= index then
                tween(button, {BackgroundColor3 = Theme.SurfaceAlt})
            end
        end)
        button.MouseLeave:Connect(function()
            if activeTab ~= index then
                tween(button, {BackgroundColor3 = Theme.TabInactive})
            end
        end)

        local elementOrder = 0
        local function nextOrder()
            elementOrder += 1
            return elementOrder
        end

        local function elementFrame(height)
            local frame = newFrame({
                Name = "Element",
                Color = Theme.SurfaceAlt,
                Size = UDim2.new(1, 0, 0, height or 38),
                Z = 5,
                Parent = page,
            })
            frame.LayoutOrder = nextOrder()
            decorate(frame, UDim.new(0, 4), Theme.BorderDim, 1)

            local pad = Instance.new("UIPadding")
            pad.PaddingLeft = UDim.new(0, 10)
            pad.PaddingRight = UDim.new(0, 10)
            pad.Parent = frame
            return frame
        end

        local Tab = {}

        function Tab:CreateLabel(text)
            local frame = elementFrame(26)
            frame.BackgroundColor3 = Theme.Surface
            newLabel({
                Text = "// " .. tostring(text or ""),
                Color = Theme.TextSecondary,
                Font = Theme.FontMono,
                Size2 = Theme.TextSizeSmall,
                Z = 6,
                Parent = frame,
            })
        end

        function Tab:CreateSection(text)
            local frame = elementFrame(22)
            frame.BackgroundTransparency = 1
            newLabel({
                Text = "── " .. tostring(text or "Section"):upper() .. " ──",
                Color = Theme.AccentDim,
                Font = Theme.FontMono,
                Size2 = 10,
                AlignX = Enum.TextXAlignment.Center,
                Z = 6,
                Parent = frame,
            })
        end

        function Tab:CreateButton(settings)
            settings = settings or {}
            local label = tostring(settings.Label or "Button")
            local callback = settings.Callback or function() end
            local frame = elementFrame(36)

            local button2 = Instance.new("TextButton")
            button2.BackgroundColor3 = Theme.Surface
            button2.Size = UDim2.fromScale(1, 1)
            button2.Text = "▶  " .. label:upper()
            button2.Font = Theme.FontMono
            button2.TextSize = Theme.TextSizeBody
            button2.TextColor3 = Theme.Accent
            button2.BorderSizePixel = 0
            button2.AutoButtonColor = false
            button2.ZIndex = 6
            button2.Parent = frame
            decorate(button2, UDim.new(0, 4), Theme.Border, 1)

            button2.MouseEnter:Connect(function()
                tween(button2, {BackgroundColor3 = Theme.SurfaceAlt, TextColor3 = Theme.TextPrimary})
            end)
            button2.MouseLeave:Connect(function()
                tween(button2, {BackgroundColor3 = Theme.Surface, TextColor3 = Theme.Accent})
            end)
            button2.MouseButton1Down:Connect(function()
                tween(button2, {BackgroundColor3 = Theme.AccentDim, TextColor3 = Theme.Background}, Theme.TweenFast)
            end)
            button2.MouseButton1Up:Connect(function()
                tween(button2, {BackgroundColor3 = Theme.SurfaceAlt, TextColor3 = Theme.TextPrimary}, Theme.TweenFast)
            end)
            button2.MouseButton1Click:Connect(function()
                safeCall(callback)
            end)
            return button2
        end

        function Tab:CreateToggle(settings)
            settings = settings or {}
            local label = tostring(settings.Label or "Toggle")
            local state = settings.Default == true
            local callback = settings.Callback or function() end
            local frame = elementFrame(38)

            newLabel({
                Text = label,
                Color = Theme.TextPrimary,
                Font = Theme.FontUI,
                Size2 = Theme.TextSizeBody,
                Size = UDim2.new(0.68, 0, 1, 0),
                Z = 6,
                Parent = frame,
            })

            local trackFrame = newFrame({
                Name = "Toggle",
                Color = state and Theme.ToggleOn or Theme.ToggleOff,
                Size = UDim2.fromOffset(36, 18),
                Pos = UDim2.new(1, -36, 0.5, -9),
                Z = 7,
                Parent = frame,
            })
            decorate(trackFrame, UDim.new(0, 9), Theme.BorderDim, 1)

            local knob = newFrame({
                Color = Theme.ToggleKnob,
                Size = UDim2.fromOffset(12, 12),
                Pos = state and UDim2.new(1, -15, 0.5, -6) or UDim2.fromOffset(3, 3),
                Z = 8,
                Parent = trackFrame,
            })
            decorate(knob, UDim.new(0, 6), false)

            local hit = Instance.new("TextButton")
            hit.BackgroundTransparency = 1
            hit.Size = UDim2.new(1, 0, 1, 0)
            hit.Text = ""
            hit.ZIndex = 9
            hit.Parent = frame

            local Toggle = {}
            function Toggle:Set(value, silent)
                state = value == true
                tween(trackFrame, {BackgroundColor3 = state and Theme.ToggleOn or Theme.ToggleOff})
                tween(knob, {
                    Position = state and UDim2.new(1, -15, 0.5, -6) or UDim2.fromOffset(3, 3)
                })
                if not silent then
                    safeCall(callback, state)
                end
            end
            function Toggle:Get()
                return state
            end

            hit.MouseButton1Click:Connect(function()
                Toggle:Set(not state)
            end)
            hit.MouseEnter:Connect(function()
                tween(frame, {BackgroundColor3 = Theme.Surface})
            end)
            hit.MouseLeave:Connect(function()
                tween(frame, {BackgroundColor3 = Theme.SurfaceAlt})
            end)

            return Toggle
        end

        function Tab:CreateSlider(settings)
            settings = settings or {}
            local label = tostring(settings.Label or "Slider")
            local min = tonumber(settings.Min) or 0
            local max = tonumber(settings.Max) or 100
            local step = tonumber(settings.Step) or 1
            if max <= min then
                max = min + 1
            end
            local value = math.clamp(tonumber(settings.Default) or min, min, max)
            local callback = settings.Callback or function() end
            local frame = elementFrame(54)

            local top = newFrame({Trans = 1, Size = UDim2.new(1, 0, 0, 22), Z = 6, Parent = frame})
            newLabel({Text = label, Color = Theme.TextPrimary, Font = Theme.FontUI, Size2 = Theme.TextSizeBody, Size = UDim2.new(0.65, 0, 1, 0), Z = 7, Parent = top})
            local valueLabel = newLabel({Text = tostring(value), Color = Theme.Accent, Font = Theme.FontMono, Size2 = Theme.TextSizeBody, AlignX = Enum.TextXAlignment.Right, Size = UDim2.new(0.35, 0, 1, 0), Pos = UDim2.new(0.65, 0, 0, 0), Z = 7, Parent = top})

            local bottom = newFrame({Trans = 1, Size = UDim2.new(1, 0, 0, 20), Pos = UDim2.fromOffset(0, 26), Z = 6, Parent = frame})
            local sliderTrack = newFrame({Color = Theme.SliderTrack, Size = UDim2.new(1, 0, 0, 8), Pos = UDim2.new(0, 0, 0.5, -4), Z = 7, Parent = bottom})
            decorate(sliderTrack, UDim.new(0, 4), Theme.BorderDim, 1)

            local percent = (value - min) / (max - min)
            local fill = newFrame({Color = Theme.SliderFill, Size = UDim2.new(percent, 0, 1, 0), Z = 8, Parent = sliderTrack})
            decorate(fill, UDim.new(0, 4), false)
            local knob = newFrame({Color = Theme.Accent, Size = UDim2.fromOffset(14, 14), Pos = UDim2.new(percent, -7, 0.5, -7), Z = 9, Parent = sliderTrack})
            decorate(knob, UDim.new(0, 7), Theme.Background, 1)

            local dragging = false
            local function recalc(x, silent)
                local pct = math.clamp((x - sliderTrack.AbsolutePosition.X) / math.max(1, sliderTrack.AbsoluteSize.X), 0, 1)
                local raw = min + (max - min) * pct
                value = math.clamp(math.floor((raw - min) / step + 0.5) * step + min, min, max)
                local p = (value - min) / (max - min)
                tween(fill, {Size = UDim2.new(p, 0, 1, 0)}, Theme.TweenFast)
                tween(knob, {Position = UDim2.new(p, -7, 0.5, -7)}, Theme.TweenFast)
                valueLabel.Text = tostring(value)
                if not silent then
                    safeCall(callback, value)
                end
            end

            track(sliderTrack.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    recalc(input.Position.X)
                end
            end))
            track(UserInputService.InputChanged:Connect(function(input)
                if not dragging then
                    return
                end
                if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                    recalc(input.Position.X)
                end
            end))
            track(UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                end
            end))

            local Slider = {}
            function Slider:Set(newValue, silent)
                value = math.clamp(tonumber(newValue) or min, min, max)
                local p = (value - min) / (max - min)
                tween(fill, {Size = UDim2.new(p, 0, 1, 0)})
                tween(knob, {Position = UDim2.new(p, -7, 0.5, -7)})
                valueLabel.Text = tostring(value)
                if not silent then
                    safeCall(callback, value)
                end
            end
            function Slider:Get()
                return value
            end
            return Slider
        end

        function Tab:CreateDropdown(settings)
            settings = settings or {}
            local label = tostring(settings.Label or "Dropdown")
            local choices = settings.Options or {}
            local selected = settings.Default or choices[1] or "None"
            local callback = settings.Callback or function() end
            local open = false
            local outsideConnection

            local frame = elementFrame(38)
            frame.ClipsDescendants = false

            newLabel({Text = label, Color = Theme.TextPrimary, Font = Theme.FontUI, Size2 = Theme.TextSizeBody, Size = UDim2.new(0.44, 0, 1, 0), Z = 6, Parent = frame})

            local button3 = Instance.new("TextButton")
            button3.BackgroundColor3 = Theme.Surface
            button3.Size = UDim2.new(0.53, 0, 0, 26)
            button3.Position = UDim2.new(0.46, 0, 0.5, -13)
            button3.Text = "  " .. tostring(selected) .. "  ▾"
            button3.Font = Theme.FontMono
            button3.TextSize = Theme.TextSizeSmall
            button3.TextColor3 = Theme.Accent
            button3.BorderSizePixel = 0
            button3.AutoButtonColor = false
            button3.ZIndex = 7
            button3.ClipsDescendants = false
            button3.Parent = frame
            decorate(button3, UDim.new(0, 4), Theme.Border, 1)

            local listFrame = newFrame({Color = Theme.TitleBar, Size = UDim2.new(1, 0, 0, 0), Pos = UDim2.fromOffset(0, 30), Z = 30, Clip = true, Parent = button3})
            listFrame.Visible = false
            decorate(listFrame, UDim.new(0, 4), Theme.Border, 1)

            local container = Instance.new("ScrollingFrame")
            container.BackgroundTransparency = 1
            container.BorderSizePixel = 0
            container.Size = UDim2.fromScale(1, 1)
            container.ScrollBarThickness = 3
            container.ScrollBarImageColor3 = Theme.AccentDim
            container.ZIndex = 31
            container.Parent = listFrame

            local list = Instance.new("UIListLayout")
            list.SortOrder = Enum.SortOrder.LayoutOrder
            list.Parent = container

            local function closeDropdown()
                if not open then
                    return
                end
                open = false
                frame.ZIndex = 5
                tween(listFrame, {Size = UDim2.new(1, 0, 0, 0)})
                task.delay(0.12, function()
                    if not open then
                        listFrame.Visible = false
                    end
                end)
                if outsideConnection then
                    outsideConnection:Disconnect()
                    outsideConnection = nil
                end
                if activeDropdownCloser == closeDropdown then
                    activeDropdownCloser = nil
                end
            end

            local function openDropdown()
                if activeDropdownCloser and activeDropdownCloser ~= closeDropdown then
                    activeDropdownCloser()
                end
                activeDropdownCloser = closeDropdown
                open = true
                frame.ZIndex = 50
                listFrame.Visible = true

                local count = #choices
                local visibleCount = math.min(count, 6)
                local itemHeight = 28
                local targetHeight = visibleCount * itemHeight
                container.CanvasSize = UDim2.new(0, 0, 0, count * itemHeight)
                tween(listFrame, {Size = UDim2.new(1, 0, 0, targetHeight)})

                outsideConnection = UserInputService.InputBegan:Connect(function(input)
                    if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
                        return
                    end
                    if not pointInside(button3, input.Position) and not pointInside(listFrame, input.Position) then
                        closeDropdown()
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
                    local choiceButton = Instance.new("TextButton")
                    choiceButton.BackgroundColor3 = Theme.TitleBar
                    choiceButton.BorderSizePixel = 0
                    choiceButton.Size = UDim2.new(1, 0, 0, 28)
                    choiceButton.LayoutOrder = i
                    choiceButton.Text = "  " .. tostring(choice)
                    choiceButton.TextColor3 = Theme.TextSecondary
                    choiceButton.TextXAlignment = Enum.TextXAlignment.Left
                    choiceButton.Font = Theme.FontMono
                    choiceButton.TextSize = Theme.TextSizeSmall
                    choiceButton.AutoButtonColor = false
                    choiceButton.ZIndex = 32
                    choiceButton.Parent = container

                    choiceButton.MouseEnter:Connect(function()
                        tween(choiceButton, {BackgroundColor3 = Theme.Surface, TextColor3 = Theme.TextPrimary})
                    end)
                    choiceButton.MouseLeave:Connect(function()
                        tween(choiceButton, {BackgroundColor3 = Theme.TitleBar, TextColor3 = Theme.TextSecondary})
                    end)
                    choiceButton.MouseButton1Click:Connect(function()
                        selected = choice
                        button3.Text = "  " .. tostring(selected) .. "  ▾"
                        safeCall(callback, selected)
                        closeDropdown()
                    end)
                end
            end

            button3.MouseButton1Click:Connect(function()
                if open then
                    closeDropdown()
                else
                    openDropdown()
                end
            end)
            rebuildChoices()

            local Dropdown = {}
            function Dropdown:Set(value, silent)
                selected = value
                button3.Text = "  " .. tostring(selected) .. "  ▾"
                if not silent then
                    safeCall(callback, selected)
                end
            end
            function Dropdown:Get()
                return selected
            end
            function Dropdown:Refresh(newChoices)
                choices = newChoices or {}
                rebuildChoices()
            end
            function Dropdown:Close()
                closeDropdown()
            end
            return Dropdown
        end

        function Tab:CreateTextInput(settings)
            settings = settings or {}
            local label = tostring(settings.Label or "Input")
            local placeholder = tostring(settings.Placeholder or "type here...")
            local callback = settings.Callback or function() end
            local frame = elementFrame(38)

            newLabel({Text = label, Color = Theme.TextPrimary, Font = Theme.FontUI, Size2 = Theme.TextSizeBody, Size = UDim2.new(0.38, 0, 1, 0), Z = 6, Parent = frame})

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
            box.ClearTextOnFocus = false
            box.ZIndex = 7
            box.Parent = frame
            decorate(box, UDim.new(0, 4), Theme.Border, 1)

            local padding = Instance.new("UIPadding")
            padding.PaddingLeft = UDim.new(0, 6)
            padding.PaddingRight = UDim.new(0, 6)
            padding.Parent = box

            box.Focused:Connect(function()
                tween(box, {BackgroundColor3 = Theme.SurfaceAlt})
            end)
            box.FocusLost:Connect(function(enter)
                tween(box, {BackgroundColor3 = Theme.Surface})
                safeCall(callback, box.Text, enter)
            end)

            local Input = {}
            function Input:Get()
                return box.Text
            end
            function Input:Set(value)
                box.Text = tostring(value)
            end
            function Input:Focus()
                box:CaptureFocus()
            end
            function Input:ReleaseFocus()
                box:ReleaseFocus()
            end
            return Input
        end

        if #tabs == 0 then
            -- nothing
        end

        setActiveTab(index)
        return Tab
    end

    tween(root, {Size = UDim2.fromOffset(width, height)}, Theme.TweenSlow)
    return Window
end

function Library:SetTheme(overrides)
    if type(overrides) ~= "table" then
        return self
    end
    for key, value in pairs(overrides) do
        if Theme[key] ~= nil then
            Theme[key] = value
        end
    end
    return self
end

function Library:GetTheme()
    local copy = {}
    for key, value in pairs(Theme) do
        copy[key] = value
    end
    return copy
end

return Library
