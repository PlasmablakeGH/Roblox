--[[
    ███╗   ██╗███████╗██╗  ██╗██╗   ██╗███████╗    ██╗   ██╗██╗
    ████╗  ██║██╔════╝╚██╗██╔╝██║   ██║██╔════╝    ██║   ██║██║
    ██╔██╗ ██║█████╗   ╚███╔╝ ██║   ██║███████╗    ██║   ██║██║
    ██║╚██╗██║██╔══╝   ██╔██╗ ██║   ██║╚════██║    ██║   ██║██║
    ██║ ╚████║███████╗██╔╝ ██╗╚██████╔╝███████║    ╚██████╔╝██║
    ╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝     ╚═════╝ ╚═╝

    NexusUI  –  Modular Roblox Luau UI Library
    Theme    :  Hacker / Sci-Fi  (green-on-black)
    Author   :  Generated for educational purposes
    Version  :  1.0.0

    USAGE (loader script):
        local Library = loadstring(game:HttpGet(
            "https://raw.githubusercontent.com/<user>/<repo>/main/NexusUI.lua"
        ))()

        local Window = Library:CreateWindow({
            Title   = "My Tool",
            IconId  = "rbxassetid://7072706620",   -- change to any asset id
        })

        local Tab = Window:CreateTab("Main")
        Tab:CreateButton({ Label = "Click Me", Callback = function() print("clicked") end })
        Tab:CreateToggle({ Label = "God Mode", Default = false, Callback = function(v) print(v) end })
        Tab:CreateSlider({ Label = "Speed",  Min = 0, Max = 100, Default = 16, Callback = function(v) print(v) end })
        Tab:CreateDropdown({ Label = "Team", Options = {"Red","Blue","Green"}, Callback = function(v) print(v) end })
        Tab:CreateLabel("Build v1.0 – NexusUI")
--]]

-- ─────────────────────────────────────────────────────────────────────────────
-- Services
-- ─────────────────────────────────────────────────────────────────────────────
local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local RunService       = game:GetService("RunService")

local LocalPlayer      = Players.LocalPlayer

-- ─────────────────────────────────────────────────────────────────────────────
-- Theme  (single source of truth – change colours here)
-- ─────────────────────────────────────────────────────────────────────────────
local Theme = {
    -- Core palette
    Background      = Color3.fromRGB(8,   12,  8),    -- near-black green tint
    Surface         = Color3.fromRGB(12,  20,  12),   -- slightly lighter panel
    SurfaceAlt      = Color3.fromRGB(16,  26,  16),   -- element background
    Border          = Color3.fromRGB(0,   200, 80),   -- vivid green border
    BorderDim       = Color3.fromRGB(0,   80,  30),   -- muted border / divider
    Accent          = Color3.fromRGB(0,   255, 100),  -- primary accent (bright green)
    AccentDim       = Color3.fromRGB(0,   140, 55),   -- secondary accent
    TextPrimary     = Color3.fromRGB(0,   255, 100),  -- main readable text
    TextSecondary   = Color3.fromRGB(0,   180, 70),   -- subtitles / labels
    TextDisabled    = Color3.fromRGB(0,   80,  30),
    Danger          = Color3.fromRGB(255, 50,  50),
    SliderFill      = Color3.fromRGB(0,   220, 90),
    SliderTrack     = Color3.fromRGB(15,  35,  15),
    ToggleOn        = Color3.fromRGB(0,   220, 90),
    ToggleOff       = Color3.fromRGB(20,  40,  20),
    ToggleKnob      = Color3.fromRGB(200, 255, 210),
    Scanline        = Color3.fromRGB(0,   255, 100),  -- decorative scanlines
    TabActive       = Color3.fromRGB(0,   200, 75),
    TabInactive     = Color3.fromRGB(0,   50,  20),
    TitleBar        = Color3.fromRGB(6,   16,  6),
    Shadow          = Color3.fromRGB(0,   0,   0),

    -- Sizing
    CornerRadius    = UDim.new(0, 4),
    BorderThickness = 1,
    FontMono        = Enum.Font.Code,
    FontUI          = Enum.Font.GothamMedium,
    FontTitle       = Enum.Font.GothamBold,
    TextSizeTitle   = 15,
    TextSizeBody    = 13,
    TextSizeLabel   = 12,

    -- Tweening
    TweenInfo       = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    TweenInfoSlow   = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Helpers
-- ─────────────────────────────────────────────────────────────────────────────

--- Quick tween wrapper
local function Tween(instance, props, info)
    TweenService:Create(instance, info or Theme.TweenInfo, props):Play()
end

--- Apply UICorner + UIStroke to a frame in one call
local function Decorate(frame, radius, strokeColor, strokeThickness)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = radius or Theme.CornerRadius
    corner.Parent = frame

    if strokeColor ~= false then
        local stroke = Instance.new("UIStroke")
        stroke.Color     = strokeColor or Theme.BorderDim
        stroke.Thickness = strokeThickness or Theme.BorderThickness
        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        stroke.Parent = frame
    end
    return frame
end

--- Create a TextLabel with sane defaults
local function MakeLabel(props)
    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency = 1
    lbl.TextColor3             = props.Color      or Theme.TextPrimary
    lbl.Font                   = props.Font       or Theme.FontUI
    lbl.TextSize               = props.TextSize   or Theme.TextSizeBody
    lbl.Text                   = props.Text       or ""
    lbl.TextXAlignment         = props.AlignX     or Enum.TextXAlignment.Left
    lbl.TextYAlignment         = props.AlignY     or Enum.TextYAlignment.Center
    lbl.TextTruncate           = Enum.TextTruncate.AtEnd
    lbl.Size                   = props.Size       or UDim2.new(1, 0, 1, 0)
    lbl.Position               = props.Position   or UDim2.new(0, 0, 0, 0)
    lbl.ZIndex                 = props.ZIndex     or 1
    lbl.Parent                 = props.Parent
    return lbl
end

--- Create a basic Frame with sane defaults
local function MakeFrame(props)
    local f = Instance.new("Frame")
    f.BackgroundColor3 = props.Color        or Theme.Surface
    f.BackgroundTransparency = props.Transparency or 0
    f.BorderSizePixel  = 0
    f.Size             = props.Size         or UDim2.new(1, 0, 1, 0)
    f.Position         = props.Position     or UDim2.new(0, 0, 0, 0)
    f.ZIndex           = props.ZIndex       or 1
    f.ClipsDescendants = props.Clip         or false
    f.Name             = props.Name         or "Frame"
    f.Parent           = props.Parent
    return f
end

--- Scanline texture overlay (purely decorative, very subtle)
local function AddScanlines(parent)
    local over = Instance.new("Frame")
    over.Name                  = "Scanlines"
    over.BackgroundTransparency= 1
    over.Size                  = UDim2.new(1, 0, 1, 0)
    over.ZIndex                = parent.ZIndex + 50
    over.BorderSizePixel       = 0
    over.Parent                = parent

    -- We draw ~every-other-pixel horizontal lines via a UIGridLayout trick
    -- (lightweight: no RunService, purely static)
    local lines = Instance.new("UIGridLayout")
    lines.CellSize    = UDim2.new(1, 0, 0, 2)
    lines.CellPadding = UDim2.new(0, 0, 0, 2)
    lines.Parent      = over

    for _ = 1, 60 do
        local line = Instance.new("Frame")
        line.BackgroundColor3        = Theme.Scanline
        line.BackgroundTransparency  = 0.97
        line.BorderSizePixel         = 0
        line.Parent                  = over
    end
    return over
end

-- ─────────────────────────────────────────────────────────────────────────────
-- GUI Root  (secure parenting)
-- ─────────────────────────────────────────────────────────────────────────────
local function GetGuiParent()
    -- gethui() is present in most modern executors and bypasses CoreGui protection
    if gethui then
        return gethui()
    end
    -- Fallback 1: protected CoreGui (works in some environments)
    local ok, coreGui = pcall(function() return game:GetService("CoreGui") end)
    if ok and coreGui then
        return coreGui
    end
    -- Fallback 2: PlayerGui (always available)
    return LocalPlayer:WaitForChild("PlayerGui")
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Dragging  (UIS-only, no RunService)
-- ─────────────────────────────────────────────────────────────────────────────
local function MakeDraggable(handle, target)
    local dragging    = false
    local dragStart   = Vector2.new()
    local startPos    = UDim2.new()

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            dragStart = input.Position
            startPos  = target.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (
            input.UserInputType == Enum.UserInputType.MouseMovement or
            input.UserInputType == Enum.UserInputType.Touch
        ) then
            local delta = input.Position - dragStart
            target.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Library Table  (the public API)
-- ─────────────────────────────────────────────────────────────────────────────
local Library = {}
Library.__index = Library

-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║  Library:CreateWindow(options)                                          ║
-- ║                                                                         ║
-- ║  options = {                                                            ║
-- ║    Title   : string          -- Window title text                       ║
-- ║    IconId  : string          -- rbxassetid:// string for top-left icon  ║
-- ║    Width   : number          -- default 480                             ║
-- ║    Height  : number          -- default 360                             ║
-- ║  }                                                                      ║
-- ╚══════════════════════════════════════════════════════════════════════════╝
function Library:CreateWindow(options)
    options = options or {}
    local title  = options.Title  or "NexusUI"
    local iconId = options.IconId or "rbxassetid://7072706620"
    local W      = options.Width  or 480
    local H      = options.Height or 360

    -- ── ScreenGui ────────────────────────────────────────────────────────
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name                  = "NexusUI_" .. title:gsub("%s", "")
    screenGui.ResetOnSpawn          = false
    screenGui.ZIndexBehavior        = Enum.ZIndexBehavior.Sibling
    screenGui.IgnoreGuiInset        = true
    screenGui.DisplayOrder          = 999
    screenGui.Parent                = GetGuiParent()

    -- ── Main Window Frame ─────────────────────────────────────────────────
    local winFrame = MakeFrame({
        Name     = "Window",
        Color    = Theme.Background,
        Size     = UDim2.new(0, W, 0, H),
        Position = UDim2.new(0.5, -W/2, 0.5, -H/2),
        Clip     = true,
        Parent   = screenGui,
    })
    Decorate(winFrame, UDim.new(0, 6), Theme.Border, 1)
    AddScanlines(winFrame)

    -- Glowing accent line at very top
    local topLine = MakeFrame({
        Name   = "TopAccent",
        Color  = Theme.Accent,
        Size   = UDim2.new(1, 0, 0, 2),
        ZIndex = 5,
        Parent = winFrame,
    })

    -- ── Title Bar ─────────────────────────────────────────────────────────
    local titleBar = MakeFrame({
        Name   = "TitleBar",
        Color  = Theme.TitleBar,
        Size   = UDim2.new(1, 0, 0, 38),
        Position= UDim2.new(0, 0, 0, 2),   -- below accent line
        ZIndex = 4,
        Parent = winFrame,
    })

    -- Icon (left side)
    local icon = Instance.new("ImageLabel")
    icon.Name                   = "Icon"
    icon.BackgroundTransparency = 1
    icon.Size                   = UDim2.new(0, 24, 0, 24)
    icon.Position               = UDim2.new(0, 8, 0.5, -12)
    icon.Image                  = iconId
    icon.ImageColor3            = Theme.Accent
    icon.ZIndex                 = 5
    icon.Parent                 = titleBar

    -- Title text
    local titleLabel = MakeLabel({
        Text     = ("[ %s ]"):format(title:upper()),
        Color    = Theme.Accent,
        Font     = Theme.FontMono,
        TextSize = Theme.TextSizeTitle,
        Size     = UDim2.new(1, -90, 1, 0),
        Position = UDim2.new(0, 40, 0, 0),
        ZIndex   = 5,
        Parent   = titleBar,
    })

    -- "SYS" badge top-right
    local sysBadge = MakeLabel({
        Text     = "SYS::ACTIVE",
        Color    = Theme.AccentDim,
        Font     = Theme.FontMono,
        TextSize = 10,
        AlignX   = Enum.TextXAlignment.Right,
        Size     = UDim2.new(0, 80, 1, 0),
        Position = UDim2.new(1, -88, 0, 0),
        ZIndex   = 5,
        Parent   = titleBar,
    })

    -- Close button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name                  = "CloseBtn"
    closeBtn.BackgroundColor3      = Color3.fromRGB(30, 10, 10)
    closeBtn.Size                  = UDim2.new(0, 28, 0, 20)
    closeBtn.Position              = UDim2.new(1, -34, 0.5, -10)
    closeBtn.Text                  = "✕"
    closeBtn.Font                  = Theme.FontTitle
    closeBtn.TextSize              = 13
    closeBtn.TextColor3            = Theme.Danger
    closeBtn.BorderSizePixel       = 0
    closeBtn.ZIndex                = 6
    closeBtn.AutoButtonColor       = false
    closeBtn.Parent                = titleBar
    Decorate(closeBtn, UDim.new(0, 3), Theme.Danger, 1)

    closeBtn.MouseButton1Click:Connect(function()
        Tween(winFrame, {Size = UDim2.new(0, W, 0, 0)}, Theme.TweenInfoSlow)
        task.delay(0.4, function() screenGui:Destroy() end)
    end)
    closeBtn.MouseEnter:Connect(function()
        Tween(closeBtn, {BackgroundColor3 = Theme.Danger})
        Tween(closeBtn, {TextColor3 = Color3.new(1,1,1)})
    end)
    closeBtn.MouseLeave:Connect(function()
        Tween(closeBtn, {BackgroundColor3 = Color3.fromRGB(30,10,10)})
        Tween(closeBtn, {TextColor3 = Theme.Danger})
    end)

    -- Make window draggable via title bar
    MakeDraggable(titleBar, winFrame)

    -- Bottom status bar
    local statusBar = MakeFrame({
        Name     = "StatusBar",
        Color    = Theme.TitleBar,
        Size     = UDim2.new(1, 0, 0, 18),
        Position = UDim2.new(0, 0, 1, -18),
        ZIndex   = 4,
        Parent   = winFrame,
    })
    MakeLabel({
        Text     = "◈ NEXUSUI  //  SECURE CHANNEL  //  ENCRYPTED",
        Color    = Theme.BorderDim,
        Font     = Theme.FontMono,
        TextSize = 10,
        AlignX   = Enum.TextXAlignment.Center,
        ZIndex   = 5,
        Parent   = statusBar,
    })

    -- ── Tab Bar (horizontal strip) ────────────────────────────────────────
    local tabBar = MakeFrame({
        Name     = "TabBar",
        Color    = Theme.TitleBar,
        Size     = UDim2.new(1, 0, 0, 30),
        Position = UDim2.new(0, 0, 0, 40),
        ZIndex   = 4,
        Parent   = winFrame,
    })
    local tabBarLayout = Instance.new("UIListLayout")
    tabBarLayout.FillDirection  = Enum.FillDirection.Horizontal
    tabBarLayout.SortOrder      = Enum.SortOrder.LayoutOrder
    tabBarLayout.Padding        = UDim.new(0, 2)
    tabBarLayout.Parent         = tabBar

    -- Divider under tab bar
    MakeFrame({
        Color    = Theme.BorderDim,
        Size     = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 1, 0),
        ZIndex   = 5,
        Parent   = tabBar,
    })

    -- ── Content Area ──────────────────────────────────────────────────────
    local contentArea = MakeFrame({
        Name     = "ContentArea",
        Color    = Theme.Background,
        Size     = UDim2.new(1, 0, 1, -(40 + 30 + 18 + 2)),
        Position = UDim2.new(0, 0, 0, 40 + 30 + 2),
        ZIndex   = 3,
        Parent   = winFrame,
    })

    -- ── Window Object ─────────────────────────────────────────────────────
    local Window      = {}
    local tabs        = {}   -- { tabBtn, tabPage }
    local activeTab   = nil

    local function SetActiveTab(index)
        for i, data in ipairs(tabs) do
            if i == index then
                Tween(data.btn, {BackgroundColor3 = Theme.TabActive,  TextColor3 = Theme.Background})
                data.page.Visible = true
            else
                Tween(data.btn, {BackgroundColor3 = Theme.TabInactive, TextColor3 = Theme.TextSecondary})
                data.page.Visible = false
            end
        end
        activeTab = index
    end

    -- ── Expose icon setter ────────────────────────────────────────────────
    function Window:SetIcon(newId)
        icon.Image = newId
    end

    -- ╔════════════════════════════════════════════════════════════════════╗
    -- ║  Window:CreateTab(name)                                           ║
    -- ╚════════════════════════════════════════════════════════════════════╝
    function Window:CreateTab(name)
        name = name or "Tab"

        -- Tab button
        local btn = Instance.new("TextButton")
        btn.Name                = "Tab_" .. name
        btn.BackgroundColor3    = Theme.TabInactive
        btn.Size                = UDim2.new(0, 90, 1, -4)
        btn.Position            = UDim2.new(0, 0, 0, 2)
        btn.Text                = name:upper()
        btn.Font                = Theme.FontMono
        btn.TextSize            = 11
        btn.TextColor3          = Theme.TextSecondary
        btn.BorderSizePixel     = 0
        btn.AutoButtonColor     = false
        btn.LayoutOrder         = #tabs + 1
        btn.ZIndex              = 5
        btn.Parent              = tabBar
        Decorate(btn, UDim.new(0, 3), false)

        -- Tab content page (scrollable)
        local page = Instance.new("ScrollingFrame")
        page.Name                    = "Page_" .. name
        page.BackgroundTransparency  = 1
        page.Size                    = UDim2.new(1, 0, 1, 0)
        page.Position                = UDim2.new(0, 0, 0, 0)
        page.BorderSizePixel         = 0
        page.ScrollBarThickness      = 3
        page.ScrollBarImageColor3    = Theme.AccentDim
        page.CanvasSize              = UDim2.new(0, 0, 0, 0)
        page.AutomaticCanvasSize     = Enum.AutomaticSize.Y
        page.ZIndex                  = 4
        page.Visible                 = false
        page.Parent                  = contentArea

        local listLayout = Instance.new("UIListLayout")
        listLayout.SortOrder        = Enum.SortOrder.LayoutOrder
        listLayout.Padding          = UDim.new(0, 6)
        listLayout.Parent           = page

        local pagePadding = Instance.new("UIPadding")
        pagePadding.PaddingTop    = UDim.new(0, 8)
        pagePadding.PaddingLeft   = UDim.new(0, 10)
        pagePadding.PaddingRight  = UDim.new(0, 10)
        pagePadding.PaddingBottom = UDim.new(0, 8)
        pagePadding.Parent        = page

        local tabIndex = #tabs + 1
        tabs[tabIndex] = { btn = btn, page = page }

        btn.MouseButton1Click:Connect(function()
            SetActiveTab(tabIndex)
        end)
        btn.MouseEnter:Connect(function()
            if activeTab ~= tabIndex then
                Tween(btn, {BackgroundColor3 = Theme.AccentDim})
            end
        end)
        btn.MouseLeave:Connect(function()
            if activeTab ~= tabIndex then
                Tween(btn, {BackgroundColor3 = Theme.TabInactive})
            end
        end)

        -- Auto-activate first tab
        if tabIndex == 1 then SetActiveTab(1) end

        -- ── Element factory (shared layout order counter) ─────────────────
        local elementOrder = 0
        local function NextOrder()
            elementOrder = elementOrder + 1
            return elementOrder
        end

        -- ── Element container helper ──────────────────────────────────────
        local function MakeElementFrame(height)
            local ef = MakeFrame({
                Color    = Theme.SurfaceAlt,
                Size     = UDim2.new(1, 0, 0, height or 38),
                ZIndex   = 5,
                Name     = "Element",
                Parent   = page,
            })
            ef.LayoutOrder = NextOrder()
            Decorate(ef, UDim.new(0, 4), Theme.BorderDim, 1)
            local pad = Instance.new("UIPadding")
            pad.PaddingLeft   = UDim.new(0, 10)
            pad.PaddingRight  = UDim.new(0, 10)
            pad.Parent        = ef
            return ef
        end

        -- ── Tab API object ────────────────────────────────────────────────
        local Tab = {}

        -- ┌──────────────────────────────────────────────────────────────┐
        -- │  Tab:CreateLabel(text)                                       │
        -- └──────────────────────────────────────────────────────────────┘
        function Tab:CreateLabel(text)
            local ef = MakeElementFrame(28)
            ef.BackgroundColor3 = Theme.Surface

            -- Prefix decoration
            MakeLabel({
                Text     = "//",
                Color    = Theme.AccentDim,
                Font     = Theme.FontMono,
                TextSize = Theme.TextSizeLabel,
                Size     = UDim2.new(0, 20, 1, 0),
                ZIndex   = 6,
                Parent   = ef,
            })
            MakeLabel({
                Text     = text or "Label",
                Color    = Theme.TextSecondary,
                Font     = Theme.FontMono,
                TextSize = Theme.TextSizeLabel,
                Size     = UDim2.new(1, -22, 1, 0),
                Position = UDim2.new(0, 22, 0, 0),
                ZIndex   = 6,
                Parent   = ef,
            })
            return ef
        end

        -- ┌──────────────────────────────────────────────────────────────┐
        -- │  Tab:CreateButton(options)                                   │
        -- │   options = { Label, Callback }                              │
        -- └──────────────────────────────────────────────────────────────┘
        function Tab:CreateButton(options)
            options = options or {}
            local label    = options.Label    or "Button"
            local callback = options.Callback or function() end

            local ef  = MakeElementFrame(36)
            local btn = Instance.new("TextButton")
            btn.Name              = "Button"
            btn.BackgroundColor3  = Theme.Surface
            btn.Size              = UDim2.new(1, 0, 1, 0)
            btn.Text              = ("▶  %s"):format(label:upper())
            btn.Font              = Theme.FontMono
            btn.TextSize          = Theme.TextSizeBody
            btn.TextColor3        = Theme.Accent
            btn.BorderSizePixel   = 0
            btn.AutoButtonColor   = false
            btn.ZIndex            = 6
            btn.Parent            = ef
            Decorate(btn, UDim.new(0, 4), Theme.Border, 1)

            -- Hover / click feedback
            btn.MouseEnter:Connect(function()
                Tween(btn, {BackgroundColor3 = Theme.SurfaceAlt, TextColor3 = Theme.TextPrimary})
            end)
            btn.MouseLeave:Connect(function()
                Tween(btn, {BackgroundColor3 = Theme.Surface, TextColor3 = Theme.Accent})
            end)
            btn.MouseButton1Down:Connect(function()
                Tween(btn, {BackgroundColor3 = Theme.AccentDim})
            end)
            btn.MouseButton1Up:Connect(function()
                Tween(btn, {BackgroundColor3 = Theme.SurfaceAlt})
            end)
            btn.MouseButton1Click:Connect(function()
                pcall(callback)
            end)

            return btn
        end

        -- ┌──────────────────────────────────────────────────────────────┐
        -- │  Tab:CreateToggle(options)                                   │
        -- │   options = { Label, Default, Callback }                     │
        -- └──────────────────────────────────────────────────────────────┘
        function Tab:CreateToggle(options)
            options  = options  or {}
            local label    = options.Label    or "Toggle"
            local state    = options.Default  or false
            local callback = options.Callback or function() end

            local ef = MakeElementFrame(38)

            MakeLabel({
                Text     = label,
                Color    = Theme.TextPrimary,
                Font     = Theme.FontUI,
                TextSize = Theme.TextSizeBody,
                Size     = UDim2.new(1, -56, 1, 0),
                ZIndex   = 6,
                Parent   = ef,
            })

            -- Track
            local track = MakeFrame({
                Color    = state and Theme.ToggleOn or Theme.ToggleOff,
                Size     = UDim2.new(0, 44, 0, 22),
                Position = UDim2.new(1, -44, 0.5, -11),
                ZIndex   = 7,
                Parent   = ef,
            })
            Decorate(track, UDim.new(0, 11), Theme.Border, 1)

            -- Knob
            local knob = MakeFrame({
                Color    = Theme.ToggleKnob,
                Size     = UDim2.new(0, 16, 0, 16),
                Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8),
                ZIndex   = 8,
                Parent   = track,
            })
            Decorate(knob, UDim.new(0, 8), false)

            -- Hit area
            local hitBox = Instance.new("TextButton")
            hitBox.BackgroundTransparency = 1
            hitBox.Size                   = UDim2.new(1, 0, 1, 0)
            hitBox.Text                   = ""
            hitBox.ZIndex                 = 9
            hitBox.Parent                 = ef

            local toggle = {}
            function toggle:Set(val)
                state = val
                Tween(track, {BackgroundColor3 = state and Theme.ToggleOn or Theme.ToggleOff})
                Tween(knob,  {Position = state
                    and UDim2.new(1, -19, 0.5, -8)
                    or  UDim2.new(0, 3,  0.5, -8)})
                pcall(callback, state)
            end
            function toggle:Get() return state end

            hitBox.MouseButton1Click:Connect(function()
                toggle:Set(not state)
            end)
            hitBox.MouseEnter:Connect(function()
                Tween(ef, {BackgroundColor3 = Theme.Surface})
            end)
            hitBox.MouseLeave:Connect(function()
                Tween(ef, {BackgroundColor3 = Theme.SurfaceAlt})
            end)

            return toggle
        end

        -- ┌──────────────────────────────────────────────────────────────┐
        -- │  Tab:CreateSlider(options)                                   │
        -- │   options = { Label, Min, Max, Default, Step, Callback }     │
        -- └──────────────────────────────────────────────────────────────┘
        function Tab:CreateSlider(options)
            options  = options  or {}
            local label    = options.Label    or "Slider"
            local min      = options.Min      or 0
            local max      = options.Max      or 100
            local step     = options.Step     or 1
            local value    = math.clamp(options.Default or min, min, max)
            local callback = options.Callback or function() end

            local ef = MakeElementFrame(54)

            -- Label row
            local labelRow = MakeFrame({
                Color    = Color3.new(0,0,0),
                Transparency = 1,
                Size     = UDim2.new(1, 0, 0, 22),
                ZIndex   = 6,
                Parent   = ef,
            })
            MakeLabel({
                Text     = label,
                Color    = Theme.TextPrimary,
                Font     = Theme.FontUI,
                TextSize = Theme.TextSizeBody,
                Size     = UDim2.new(0.7, 0, 1, 0),
                ZIndex   = 7,
                Parent   = labelRow,
            })
            local valLabel = MakeLabel({
                Text     = tostring(value),
                Color    = Theme.Accent,
                Font     = Theme.FontMono,
                TextSize = Theme.TextSizeBody,
                AlignX   = Enum.TextXAlignment.Right,
                Size     = UDim2.new(0.3, 0, 1, 0),
                Position = UDim2.new(0.7, 0, 0, 0),
                ZIndex   = 7,
                Parent   = labelRow,
            })

            -- Track row
            local trackRow = MakeFrame({
                Color       = Color3.new(0,0,0),
                Transparency= 1,
                Size        = UDim2.new(1, 0, 0, 20),
                Position    = UDim2.new(0, 0, 0, 26),
                ZIndex      = 6,
                Parent      = ef,
            })

            local track = MakeFrame({
                Color    = Theme.SliderTrack,
                Size     = UDim2.new(1, 0, 0, 8),
                Position = UDim2.new(0, 0, 0.5, -4),
                ZIndex   = 7,
                Parent   = trackRow,
            })
            Decorate(track, UDim.new(0, 4), Theme.BorderDim, 1)

            local fill = MakeFrame({
                Color    = Theme.SliderFill,
                Size     = UDim2.new((value - min) / (max - min), 0, 1, 0),
                ZIndex   = 8,
                Parent   = track,
            })
            Decorate(fill, UDim.new(0, 4), false)

            -- Knob
            local knob = MakeFrame({
                Color    = Theme.Accent,
                Size     = UDim2.new(0, 14, 0, 14),
                Position = UDim2.new((value - min) / (max - min), -7, 0.5, -7),
                ZIndex   = 9,
                Parent   = track,
            })
            Decorate(knob, UDim.new(0, 7), Theme.Background, 1)

            -- Input handling (UIS only)
            local dragging = false

            local function UpdateFromPos(absX)
                local trackAbsPos  = track.AbsolutePosition.X
                local trackAbsSize = track.AbsoluteSize.X
                local pct  = math.clamp((absX - trackAbsPos) / trackAbsSize, 0, 1)
                -- Snap to step
                local raw  = min + (max - min) * pct
                local snapped = math.floor((raw - min) / step + 0.5) * step + min
                value = math.clamp(snapped, min, max)
                local newPct = (value - min) / (max - min)
                Tween(fill,  {Size     = UDim2.new(newPct, 0, 1, 0)})
                Tween(knob,  {Position = UDim2.new(newPct, -7, 0.5, -7)})
                valLabel.Text = tostring(math.floor(value * 100 + 0.5) / 100)
                pcall(callback, value)
            end

            track.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    UpdateFromPos(input.Position.X)
                end
            end)

            UserInputService.InputChanged:Connect(function(input)
                if dragging and (
                    input.UserInputType == Enum.UserInputType.MouseMovement or
                    input.UserInputType == Enum.UserInputType.Touch
                ) then
                    UpdateFromPos(input.Position.X)
                end
            end)

            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                end
            end)

            local slider = {}
            function slider:Set(v)
                value = math.clamp(v, min, max)
                local pct = (value - min) / (max - min)
                Tween(fill,  {Size     = UDim2.new(pct, 0, 1, 0)})
                Tween(knob,  {Position = UDim2.new(pct, -7, 0.5, -7)})
                valLabel.Text = tostring(value)
                pcall(callback, value)
            end
            function slider:Get() return value end

            return slider
        end

        -- ┌──────────────────────────────────────────────────────────────┐
        -- │  Tab:CreateDropdown(options)                                 │
        -- │   options = { Label, Options, Default, Callback }            │
        -- └──────────────────────────────────────────────────────────────┘
        function Tab:CreateDropdown(options)
            options  = options  or {}
            local label    = options.Label    or "Dropdown"
            local choices  = options.Options  or {}
            local callback = options.Callback or function() end
            local selected = options.Default  or choices[1] or "None"
            local open     = false

            -- Collapsed frame
            local ef = MakeElementFrame(38)
            ef.ClipsDescendants = false   -- allows dropdown to overflow

            MakeLabel({
                Text     = label,
                Color    = Theme.TextPrimary,
                Font     = Theme.FontUI,
                TextSize = Theme.TextSizeBody,
                Size     = UDim2.new(0.45, 0, 1, 0),
                ZIndex   = 6,
                Parent   = ef,
            })

            -- Current value button
            local dropBtn = Instance.new("TextButton")
            dropBtn.Name              = "DropBtn"
            dropBtn.BackgroundColor3  = Theme.Surface
            dropBtn.Size              = UDim2.new(0.52, 0, 0, 26)
            dropBtn.Position          = UDim2.new(0.46, 0, 0.5, -13)
            dropBtn.Text              = ("  %s  ▾"):format(selected)
            dropBtn.Font              = Theme.FontMono
            dropBtn.TextSize          = Theme.TextSizeLabel
            dropBtn.TextColor3        = Theme.Accent
            dropBtn.BorderSizePixel   = 0
            dropBtn.AutoButtonColor   = false
            dropBtn.ZIndex            = 7
            dropBtn.ClipsDescendants  = false
            dropBtn.Parent            = ef
            Decorate(dropBtn, UDim.new(0, 4), Theme.Border, 1)

            -- Dropdown list (initially hidden)
            local listFrame = MakeFrame({
                Color    = Theme.TitleBar,
                Size     = UDim2.new(1, 0, 0, #choices * 28),
                Position = UDim2.new(0, 0, 1, 4),
                ZIndex   = 20,
                Clip     = true,
                Parent   = dropBtn,
            })
            listFrame.Visible = false
            Decorate(listFrame, UDim.new(0, 4), Theme.Border, 1)

            local listLayout = Instance.new("UIListLayout")
            listLayout.SortOrder = Enum.SortOrder.LayoutOrder
            listLayout.Parent    = listFrame

            for i, choice in ipairs(choices) do
                local item = Instance.new("TextButton")
                item.BackgroundColor3 = Theme.TitleBar
                item.Size             = UDim2.new(1, 0, 0, 28)
                item.Text             = ("  %s"):format(choice)
                item.Font             = Theme.FontMono
                item.TextSize         = Theme.TextSizeLabel
                item.TextColor3       = Theme.TextSecondary
                item.TextXAlignment   = Enum.TextXAlignment.Left
                item.BorderSizePixel  = 0
                item.AutoButtonColor  = false
                item.LayoutOrder      = i
                item.ZIndex           = 21
                item.Parent           = listFrame

                item.MouseEnter:Connect(function()
                    Tween(item, {BackgroundColor3 = Theme.SurfaceAlt, TextColor3 = Theme.Accent})
                end)
                item.MouseLeave:Connect(function()
                    Tween(item, {BackgroundColor3 = Theme.TitleBar, TextColor3 = Theme.TextSecondary})
                end)
                item.MouseButton1Click:Connect(function()
                    selected = choice
                    dropBtn.Text = ("  %s  ▾"):format(selected)
                    open = false
                    listFrame.Visible = false
                    pcall(callback, selected)
                end)
            end

            -- Toggle open/close
            dropBtn.MouseButton1Click:Connect(function()
                open = not open
                listFrame.Visible = open
                Tween(dropBtn, {
                    BackgroundColor3 = open and Theme.SurfaceAlt or Theme.Surface
                })
            end)
            dropBtn.MouseEnter:Connect(function()
                if not open then Tween(dropBtn, {BackgroundColor3 = Theme.SurfaceAlt}) end
            end)
            dropBtn.MouseLeave:Connect(function()
                if not open then Tween(dropBtn, {BackgroundColor3 = Theme.Surface}) end
            end)

            -- Close if click outside
            UserInputService.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 and open then
                    -- Small delay so the item click can fire first
                    task.defer(function()
                        open = false
                        listFrame.Visible = false
                        Tween(dropBtn, {BackgroundColor3 = Theme.Surface})
                    end)
                end
            end)

            local dd = {}
            function dd:Set(choice)
                selected = choice
                dropBtn.Text = ("  %s  ▾"):format(selected)
                pcall(callback, selected)
            end
            function dd:Get() return selected end

            return dd
        end

        -- ┌──────────────────────────────────────────────────────────────┐
        -- │  Tab:CreateSection(name)   (visual separator)                │
        -- └──────────────────────────────────────────────────────────────┘
        function Tab:CreateSection(name)
            local ef = MakeElementFrame(24)
            ef.BackgroundTransparency = 1

            -- Left line
            MakeFrame({
                Color    = Theme.BorderDim,
                Size     = UDim2.new(0.06, 0, 0, 1),
                Position = UDim2.new(0, 0, 0.5, 0),
                ZIndex   = 6,
                Parent   = ef,
            })
            MakeLabel({
                Text     = ("── %s ──"):format((name or "Section"):upper()),
                Color    = Theme.AccentDim,
                Font     = Theme.FontMono,
                TextSize = 10,
                AlignX   = Enum.TextXAlignment.Center,
                ZIndex   = 6,
                Parent   = ef,
            })
        end

        -- ┌──────────────────────────────────────────────────────────────┐
        -- │  Tab:CreateTextInput(options)                                │
        -- │   options = { Label, Placeholder, Callback }                 │
        -- └──────────────────────────────────────────────────────────────┘
        function Tab:CreateTextInput(options)
            options  = options  or {}
            local label       = options.Label       or "Input"
            local placeholder = options.Placeholder or "type here..."
            local callback    = options.Callback    or function() end

            local ef = MakeElementFrame(38)

            MakeLabel({
                Text     = label,
                Color    = Theme.TextPrimary,
                Font     = Theme.FontUI,
                TextSize = Theme.TextSizeBody,
                Size     = UDim2.new(0.38, 0, 1, 0),
                ZIndex   = 6,
                Parent   = ef,
            })

            local box = Instance.new("TextBox")
            box.BackgroundColor3      = Theme.Surface
            box.Size                  = UDim2.new(0.58, 0, 0, 26)
            box.Position              = UDim2.new(0.40, 0, 0.5, -13)
            box.Text                  = ""
            box.PlaceholderText       = placeholder
            box.PlaceholderColor3     = Theme.TextDisabled
            box.Font                  = Theme.FontMono
            box.TextSize              = Theme.TextSizeLabel
            box.TextColor3            = Theme.Accent
            box.BorderSizePixel       = 0
            box.ZIndex                = 7
            box.ClearTextOnFocus      = false
            box.Parent                = ef
            Decorate(box, UDim.new(0, 4), Theme.Border, 1)

            local pad = Instance.new("UIPadding")
            pad.PaddingLeft = UDim.new(0, 6)
            pad.Parent = box

            box.FocusLost:Connect(function(enter)
                pcall(callback, box.Text, enter)
            end)
            box.Focused:Connect(function()
                Tween(box, {BackgroundColor3 = Theme.SurfaceAlt})
            end)
            box.FocusLost:Connect(function()
                Tween(box, {BackgroundColor3 = Theme.Surface})
            end)

            local inp = {}
            function inp:Get() return box.Text end
            function inp:Set(v) box.Text = tostring(v) end

            return inp
        end

        return Tab
    end   -- Window:CreateTab

    -- Auto-open animation
    winFrame.Size = UDim2.new(0, W, 0, 0)
    Tween(winFrame, {Size = UDim2.new(0, W, 0, H)}, Theme.TweenInfoSlow)

    return Window
end   -- Library:CreateWindow

-- ─────────────────────────────────────────────────────────────────────────────
-- Expose a theme-override helper so users can re-skin at runtime
-- ─────────────────────────────────────────────────────────────────────────────
function Library:SetTheme(overrides)
    for k, v in pairs(overrides) do
        if Theme[k] ~= nil then
            Theme[k] = v
        end
    end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Return the library so loadstring() callers can capture it:
--   local Lib = loadstring(game:HttpGet(URL))()
-- ─────────────────────────────────────────────────────────────────────────────
return Library
