--[[
    ================================================================
    PlasmaUI - Standalone Luau UI Library
    ================================================================
    Pure Instance.new UI framework: draggable window, tab sidebar,
    buttons, toggles, sliders, cycling selectors, dropdowns, text
    inputs (with confirm/delete, for RP-name style fields), an icon
    grid with search (for shop/tools style panels), and toast
    notifications.

    RECOMMENDED USAGE: put this in a ModuleScript, e.g.
        game.ReplicatedStorage.UI.PlasmaUI

        local PlasmaUI = require(game.ReplicatedStorage.UI.PlasmaUI)

        local Window = PlasmaUI:CreateWindow({
            Title = "Plasmablake",
            SubTitle = "v1.0.0",
        })

        local Main = Window:CreateTab("Main")
        Main:CreateButton("Say Hello", function()
            print("Hello from PlasmaUI!")
        end)

        Main:CreateToggle("Camera Sway", true, function(state)
            print("Camera sway:", state)
        end)

        Main:CreateSlider("Region Sounds", 0, 100, 50, function(value)
            print("Region sounds:", value)
        end)

        Main:CreateSelector("Run Type", {"Hold", "Toggle"}, "Hold", function(opt)
            print("Run type:", opt)
        end)

        Main:CreateTextbox("RP Name", "Your RP Name here... [Max. 30]", function(text)
            print("Name confirmed:", text)
        end, {MaxLength = 30, Delete = true})

        PlasmaUI:Notify("Saved", "Your settings were updated.", 3)

    This file returns a single public API table (`Library`) and can
    also be executed directly (e.g. via loadstring) since the
    trailing `return` is valid at the top level of any Luau chunk.
    ================================================================
]]

local Library = {}
Library.__index = Library
Library._connections = {}
Library._windows = {}

----------------------------------------------------------------------
-- SERVICES
----------------------------------------------------------------------
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players          = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    LocalPlayer = Players.PlayerAdded:Wait()
end
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

----------------------------------------------------------------------
-- THEME
----------------------------------------------------------------------
local Theme = {
    Background = Color3.fromRGB(22, 22, 26),
    Panel      = Color3.fromRGB(30, 30, 35),
    Elevated   = Color3.fromRGB(38, 38, 44),
    Hover      = Color3.fromRGB(46, 46, 53),
    Stroke     = Color3.fromRGB(54, 54, 62),
    Text       = Color3.fromRGB(238, 238, 242),
    SubText    = Color3.fromRGB(150, 150, 162),
    Accent     = Color3.fromRGB(88, 142, 255),
    Success    = Color3.fromRGB(84, 199, 122),
    Danger     = Color3.fromRGB(228, 92, 92),
    Font       = Enum.Font.Gotham,
    FontMed    = Enum.Font.GothamMedium,
    FontBold   = Enum.Font.GothamBold,
}

local FAST = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local MED  = TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

----------------------------------------------------------------------
-- UTILITIES
----------------------------------------------------------------------
local function New(className, properties, children)
    local inst = Instance.new(className)
    for prop, value in pairs(properties or {}) do
        inst[prop] = value
    end
    for _, child in ipairs(children or {}) do
        child.Parent = inst
    end
    return inst
end

local function Tween(inst, props, info)
    local t = TweenService:Create(inst, info or MED, props)
    t:Play()
    return t
end

local function Corner(radius)
    return New("UICorner", {CornerRadius = UDim.new(0, radius or 6)})
end

local function Stroke(color, thickness)
    return New("UIStroke", {
        Color = color or Theme.Stroke,
        Thickness = thickness or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    })
end

local function Track(conn)
    table.insert(Library._connections, conn)
    return conn
end

local function MakeDraggable(handle, target)
    local dragging, dragStart, startPos = false, nil, nil

    Track(handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = target.Position
            local endConn
            endConn = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    endConn:Disconnect()
                end
            end)
        end
    end))

    Track(UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            target.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end))
end

----------------------------------------------------------------------
-- METATABLES
----------------------------------------------------------------------
local WindowMethods = {}
WindowMethods.__index = WindowMethods

local TabMethods = {}
TabMethods.__index = TabMethods

----------------------------------------------------------------------
-- LIBRARY: CREATE WINDOW
----------------------------------------------------------------------
function Library:CreateWindow(config)
    config = config or {}
    local title      = config.Title or "UI Library"
    local subtitle   = config.SubTitle or ""
    local size       = config.Size or UDim2.fromOffset(580, 400)
    local toggleKey  = config.ToggleKey or Enum.KeyCode.RightControl

    local ScreenGui = New("ScreenGui", {
        Name = "PlasmaUI",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 100,
    })

    local parented = pcall(function()
        ScreenGui.Parent = PlayerGui
    end)
    if not parented then
        warn("[PlasmaUI] Failed to parent ScreenGui to PlayerGui.")
    end

    local Main = New("Frame", {
        Name = "Main",
        Size = size,
        Position = UDim2.new(0.5, -size.X.Offset / 2, 0.5, -size.Y.Offset / 2),
        BackgroundColor3 = Theme.Background,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = ScreenGui,
    }, {Corner(10), Stroke(Theme.Stroke, 1)})

    -- Title bar
    local TitleBar = New("Frame", {
        Name = "TitleBar",
        Size = UDim2.new(1, 0, 0, 42),
        BackgroundColor3 = Theme.Panel,
        BorderSizePixel = 0,
        Parent = Main,
    }, {Corner(10)})

    New("Frame", { -- flattens the bottom corners of the title bar
        BackgroundColor3 = Theme.Panel,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 10),
        Position = UDim2.new(0, 0, 1, -10),
        Parent = TitleBar,
    })

    New("TextLabel", {
        Name = "Title",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 16, 0, 4),
        Size = UDim2.new(1, -100, 0, 20),
        Font = Theme.FontBold,
        Text = title,
        TextColor3 = Theme.Text,
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = TitleBar,
    })

    New("TextLabel", {
        Name = "SubTitle",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 16, 0, 22),
        Size = UDim2.new(1, -100, 0, 16),
        Font = Theme.Font,
        Text = subtitle,
        TextColor3 = Theme.SubText,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = TitleBar,
    })

    local CloseBtn = New("TextButton", {
        Name = "Close",
        Size = UDim2.new(0, 28, 0, 28),
        Position = UDim2.new(1, -36, 0, 7),
        BackgroundColor3 = Theme.Elevated,
        Text = "",
        Parent = TitleBar,
    }, {Corner(6)})
    New("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Font = Theme.FontBold,
        Text = "x",
        TextColor3 = Theme.SubText,
        TextSize = 15,
        Parent = CloseBtn,
    })

    local MinBtn = New("TextButton", {
        Name = "Minimize",
        Size = UDim2.new(0, 28, 0, 28),
        Position = UDim2.new(1, -68, 0, 7),
        BackgroundColor3 = Theme.Elevated,
        Text = "",
        Parent = TitleBar,
    }, {Corner(6)})
    New("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Font = Theme.FontBold,
        Text = "-",
        TextColor3 = Theme.SubText,
        TextSize = 18,
        Parent = MinBtn,
    })

    for _, btn in ipairs({CloseBtn, MinBtn}) do
        Track(btn.MouseEnter:Connect(function()
            Tween(btn, {BackgroundColor3 = Theme.Hover}, FAST)
        end))
        Track(btn.MouseLeave:Connect(function()
            Tween(btn, {BackgroundColor3 = Theme.Elevated}, FAST)
        end))
    end

    -- Body: sidebar + pages
    local Body = New("Frame", {
        Name = "Body",
        Size = UDim2.new(1, 0, 1, -42),
        Position = UDim2.new(0, 0, 0, 42),
        BackgroundTransparency = 1,
        Parent = Main,
    })

    local Sidebar = New("Frame", {
        Name = "Sidebar",
        Size = UDim2.new(0, 140, 1, -12),
        Position = UDim2.new(0, 6, 0, 6),
        BackgroundColor3 = Theme.Panel,
        BorderSizePixel = 0,
        Parent = Body,
    }, {Corner(8)})

    New("UIPadding", {
        PaddingTop = UDim.new(0, 8),
        PaddingLeft = UDim.new(0, 6),
        PaddingRight = UDim.new(0, 6),
    }).Parent = Sidebar

    New("UIListLayout", {
        Padding = UDim.new(0, 4),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }).Parent = Sidebar

    local Pages = New("Frame", {
        Name = "Pages",
        Size = UDim2.new(1, -158, 1, -12),
        Position = UDim2.new(0, 152, 0, 6),
        BackgroundTransparency = 1,
        Parent = Body,
    })

    MakeDraggable(TitleBar, Main)

    -- Minimize behaviour
    local minimized = false
    local expandedSize = size
    Track(MinBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            Body.Visible = false
            Tween(Main, {Size = UDim2.new(0, size.X.Offset, 0, 42)}, MED)
        else
            Tween(Main, {Size = expandedSize}, MED)
            task.delay(0.05, function()
                if not minimized then
                    Body.Visible = true
                end
            end)
        end
    end))

    Track(CloseBtn.MouseButton1Click:Connect(function()
        ScreenGui.Enabled = false
    end))

    Track(UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == toggleKey then
            ScreenGui.Enabled = not ScreenGui.Enabled
        end
    end))

    local Window = setmetatable({}, WindowMethods)
    Window.ScreenGui = ScreenGui
    Window.Main = Main
    Window.Sidebar = Sidebar
    Window.Pages = Pages
    Window.Tabs = {}
    Window._tabOrder = 0
    Window.ActiveTab = nil

    table.insert(Library._windows, Window)
    Library.ScreenGui = ScreenGui -- convenience reference to the latest window

    return Window
end

----------------------------------------------------------------------
-- WINDOW: CREATE TAB
----------------------------------------------------------------------
function WindowMethods:CreateTab(name)
    self._tabOrder += 1
    local order = self._tabOrder

    local TabButton = New("TextButton", {
        Name = "Tab_" .. name,
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundColor3 = Theme.Elevated,
        BackgroundTransparency = 1,
        Text = "",
        LayoutOrder = order,
        Parent = self.Sidebar,
    }, {Corner(6)})

    local Indicator = New("Frame", {
        Size = UDim2.new(0, 3, 0, 16),
        Position = UDim2.new(0, 0, 0.5, -8),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        Visible = false,
        Parent = TabButton,
    }, {Corner(2)})

    New("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 14, 0, 0),
        Size = UDim2.new(1, -20, 1, 0),
        Font = Theme.FontMed,
        Text = name,
        TextColor3 = Theme.SubText,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = TabButton,
    })

    local Page = New("ScrollingFrame", {
        Name = "Page_" .. name,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Theme.Accent,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false,
        Parent = self.Pages,
    })

    New("UIListLayout", {
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }).Parent = Page

    New("UIPadding", {
        PaddingTop = UDim.new(0, 4),
        PaddingBottom = UDim.new(0, 4),
        PaddingRight = UDim.new(0, 6),
    }).Parent = Page

    local Tab = setmetatable({}, TabMethods)
    Tab.Button = TabButton
    Tab.Indicator = Indicator
    Tab.Container = Page
    Tab._order = 0
    Tab._window = self

    table.insert(self.Tabs, Tab)

    local function select()
        for _, t in ipairs(self.Tabs) do
            t.Container.Visible = false
            t.Indicator.Visible = false
            Tween(t.Button, {BackgroundTransparency = 1}, FAST)
            local lbl = t.Button:FindFirstChildOfClass("TextLabel")
            if lbl then Tween(lbl, {TextColor3 = Theme.SubText}, FAST) end
        end
        Page.Visible = true
        Indicator.Visible = true
        Tween(TabButton, {BackgroundTransparency = 0}, FAST)
        local lbl = TabButton:FindFirstChildOfClass("TextLabel")
        if lbl then Tween(lbl, {TextColor3 = Theme.Text}, FAST) end
        self.ActiveTab = Tab
    end

    Track(TabButton.MouseButton1Click:Connect(select))

    if order == 1 then
        select()
    end

    return Tab
end

----------------------------------------------------------------------
-- TAB: SHARED HELPERS
----------------------------------------------------------------------
function TabMethods:_nextOrder()
    self._order += 1
    return self._order
end

----------------------------------------------------------------------
-- TAB: BUTTON
----------------------------------------------------------------------
function TabMethods:CreateButton(text, callback)
    callback = callback or function() end
    local order = self:_nextOrder()

    local ButtonFrame = New("TextButton", {
        Name = "Button",
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = Theme.Panel,
        AutoButtonColor = false,
        Text = "",
        LayoutOrder = order,
        Parent = self.Container,
    }, {Corner(6), Stroke()})

    New("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 14, 0, 0),
        Size = UDim2.new(1, -20, 1, 0),
        Font = Theme.FontMed,
        Text = text,
        TextColor3 = Theme.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = ButtonFrame,
    })

    Track(ButtonFrame.MouseEnter:Connect(function()
        Tween(ButtonFrame, {BackgroundColor3 = Theme.Hover}, FAST)
    end))
    Track(ButtonFrame.MouseLeave:Connect(function()
        Tween(ButtonFrame, {BackgroundColor3 = Theme.Panel}, FAST)
    end))
    Track(ButtonFrame.MouseButton1Click:Connect(function()
        Tween(ButtonFrame, {BackgroundColor3 = Theme.Accent}, FAST)
        task.delay(0.1, function()
            Tween(ButtonFrame, {BackgroundColor3 = Theme.Panel}, FAST)
        end)
        local ok, err = pcall(callback)
        if not ok then warn("[PlasmaUI] Button callback error: " .. tostring(err)) end
    end))

    return ButtonFrame
end

----------------------------------------------------------------------
-- TAB: TOGGLE
----------------------------------------------------------------------
function TabMethods:CreateToggle(text, default, callback)
    callback = callback or function() end
    local state = default and true or false
    local order = self:_nextOrder()

    local Frame = New("Frame", {
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = Theme.Panel,
        LayoutOrder = order,
        Parent = self.Container,
    }, {Corner(6), Stroke()})

    New("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 14, 0, 0),
        Size = UDim2.new(1, -70, 1, 0),
        Font = Theme.FontMed,
        Text = text,
        TextColor3 = Theme.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Frame,
    })

    local Switch = New("Frame", {
        Size = UDim2.new(0, 38, 0, 20),
        Position = UDim2.new(1, -50, 0.5, -10),
        BackgroundColor3 = state and Theme.Accent or Theme.Elevated,
        Parent = Frame,
    }, {Corner(10)})

    local onPos = UDim2.new(1, -18, 0.5, -8)
    local offPos = UDim2.new(0, 2, 0.5, -8)

    local Knob = New("Frame", {
        Size = UDim2.new(0, 16, 0, 16),
        Position = state and onPos or offPos,
        BackgroundColor3 = Color3.new(1, 1, 1),
        Parent = Switch,
    }, {Corner(8)})

    local ClickCatcher = New("TextButton", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        Parent = Frame,
    })

    local function setState(newState, fire)
        state = newState
        Tween(Switch, {BackgroundColor3 = state and Theme.Accent or Theme.Elevated}, FAST)
        Tween(Knob, {Position = state and onPos or offPos}, FAST)
        if fire then
            local ok, err = pcall(callback, state)
            if not ok then warn("[PlasmaUI] Toggle callback error: " .. tostring(err)) end
        end
    end

    Track(ClickCatcher.MouseButton1Click:Connect(function()
        setState(not state, true)
    end))

    local ToggleObj = {}
    function ToggleObj:Set(newState) setState(newState and true or false, true) end
    function ToggleObj:Get() return state end
    return ToggleObj
end

----------------------------------------------------------------------
-- TAB: SLIDER
----------------------------------------------------------------------
function TabMethods:CreateSlider(text, min, max, default, callback)
    callback = callback or function() end
    min, max = min or 0, max or 100
    local value = math.clamp(default or min, min, max)
    local order = self:_nextOrder()

    local Frame = New("Frame", {
        Size = UDim2.new(1, 0, 0, 46),
        BackgroundColor3 = Theme.Panel,
        LayoutOrder = order,
        Parent = self.Container,
    }, {Corner(6), Stroke()})

    New("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 14, 0, 6),
        Size = UDim2.new(1, -80, 0, 16),
        Font = Theme.FontMed,
        Text = text,
        TextColor3 = Theme.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Frame,
    })

    local ValueLabel = New("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -66, 0, 6),
        Size = UDim2.new(0, 52, 0, 16),
        Font = Theme.FontMed,
        Text = tostring(value),
        TextColor3 = Theme.SubText,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = Frame,
    })

    local SliderTrack = New("Frame", {
        Size = UDim2.new(1, -28, 0, 6),
        Position = UDim2.new(0, 14, 1, -16),
        BackgroundColor3 = Theme.Elevated,
        Parent = Frame,
    }, {Corner(3)})

    local startAlpha = (value - min) / (max - min)

    local Fill = New("Frame", {
        Size = UDim2.new(startAlpha, 0, 1, 0),
        BackgroundColor3 = Theme.Accent,
        Parent = SliderTrack,
    }, {Corner(3)})

    local Knob = New("Frame", {
        Size = UDim2.new(0, 12, 0, 12),
        Position = UDim2.new(startAlpha, -6, 0.5, -6),
        BackgroundColor3 = Color3.new(1, 1, 1),
        ZIndex = 2,
        Parent = SliderTrack,
    }, {Corner(6)})

    local dragging = false

    local function setFromX(x)
        local abs = SliderTrack.AbsolutePosition.X
        local size = SliderTrack.AbsoluteSize.X
        local alpha = size > 0 and math.clamp((x - abs) / size, 0, 1) or 0
        local newValue = math.floor(min + (max - min) * alpha + 0.5)
        Tween(Fill, {Size = UDim2.new(alpha, 0, 1, 0)}, FAST)
        Tween(Knob, {Position = UDim2.new(alpha, -6, 0.5, -6)}, FAST)
        if newValue ~= value then
            value = newValue
            ValueLabel.Text = tostring(value)
            local ok, err = pcall(callback, value)
            if not ok then warn("[PlasmaUI] Slider callback error: " .. tostring(err)) end
        end
    end

    Track(SliderTrack.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            setFromX(input.Position.X)
        end
    end))
    Track(UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            setFromX(input.Position.X)
        end
    end))
    Track(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end))

    local SliderObj = {}
    function SliderObj:Set(v)
        v = math.clamp(v, min, max)
        local alpha = (v - min) / (max - min)
        value = v
        ValueLabel.Text = tostring(v)
        Tween(Fill, {Size = UDim2.new(alpha, 0, 1, 0)}, FAST)
        Tween(Knob, {Position = UDim2.new(alpha, -6, 0.5, -6)}, FAST)
    end
    function SliderObj:Get() return value end
    return SliderObj
end

----------------------------------------------------------------------
-- TAB: SELECTOR (cycling "< value >" control, e.g. Run Type / Nametags)
----------------------------------------------------------------------
function TabMethods:CreateSelector(text, options, default, callback)
    callback = callback or function() end
    options = options or {}
    assert(#options > 0, "CreateSelector requires at least one option")
    local order = self:_nextOrder()

    local index = 1
    for i, opt in ipairs(options) do
        if opt == default then index = i break end
    end

    local Frame = New("Frame", {
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = Theme.Panel,
        LayoutOrder = order,
        Parent = self.Container,
    }, {Corner(6), Stroke()})

    New("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 14, 0, 0),
        Size = UDim2.new(0.45, 0, 1, 0),
        Font = Theme.FontMed,
        Text = text,
        TextColor3 = Theme.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Frame,
    })

    local LeftBtn = New("TextButton", {
        Size = UDim2.new(0, 22, 0, 22),
        Position = UDim2.new(1, -132, 0.5, -11),
        BackgroundColor3 = Theme.Elevated,
        Text = "<",
        Font = Theme.FontBold,
        TextColor3 = Theme.SubText,
        TextSize = 14,
        Parent = Frame,
    }, {Corner(5)})

    local ValueLabel = New("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -104, 0, 0),
        Size = UDim2.new(0, 70, 1, 0),
        Font = Theme.FontMed,
        Text = tostring(options[index]),
        TextColor3 = Theme.Accent,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Center,
        Parent = Frame,
    })

    local RightBtn = New("TextButton", {
        Size = UDim2.new(0, 22, 0, 22),
        Position = UDim2.new(1, -30, 0.5, -11),
        BackgroundColor3 = Theme.Elevated,
        Text = ">",
        Font = Theme.FontBold,
        TextColor3 = Theme.SubText,
        TextSize = 14,
        Parent = Frame,
    }, {Corner(5)})

    local function set(newIndex, fire)
        index = ((newIndex - 1) % #options) + 1
        ValueLabel.Text = tostring(options[index])
        if fire then
            local ok, err = pcall(callback, options[index], index)
            if not ok then warn("[PlasmaUI] Selector callback error: " .. tostring(err)) end
        end
    end

    Track(LeftBtn.MouseButton1Click:Connect(function() set(index - 1, true) end))
    Track(RightBtn.MouseButton1Click:Connect(function() set(index + 1, true) end))

    local SelectorObj = {}
    function SelectorObj:Set(optionValue)
        for i, opt in ipairs(options) do
            if opt == optionValue then set(i, true) return end
        end
    end
    function SelectorObj:Get() return options[index] end
    return SelectorObj
end

----------------------------------------------------------------------
-- TAB: DROPDOWN (expanding list)
----------------------------------------------------------------------
function TabMethods:CreateDropdown(text, options, callback)
    callback = callback or function() end
    options = options or {}
    local order = self:_nextOrder()
    local open = false
    local selected = options[1]

    local Frame = New("Frame", {
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = Theme.Panel,
        LayoutOrder = order,
        ClipsDescendants = true,
        Parent = self.Container,
    }, {Corner(6), Stroke()})

    local Header = New("TextButton", {
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundTransparency = 1,
        Text = "",
        Parent = Frame,
    })

    New("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 14, 0, 0),
        Size = UDim2.new(0.5, 0, 0, 36),
        Font = Theme.FontMed,
        Text = text,
        TextColor3 = Theme.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Header,
    })

    local SelectedLabel = New("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -140, 0, 0),
        Size = UDim2.new(0, 100, 0, 36),
        Font = Theme.FontMed,
        Text = tostring(selected or "Select..."),
        TextColor3 = Theme.Accent,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = Header,
    })

    local Arrow = New("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -30, 0, 0),
        Size = UDim2.new(0, 20, 0, 36),
        Font = Theme.FontBold,
        Text = "v",
        TextColor3 = Theme.SubText,
        TextSize = 12,
        Parent = Header,
    })

    local List = New("Frame", {
        Position = UDim2.new(0, 0, 0, 36),
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundTransparency = 1,
        Parent = Frame,
    })

    New("UIListLayout", {
        Padding = UDim.new(0, 2),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }).Parent = List

    New("UIPadding", {
        PaddingTop = UDim.new(0, 4),
        PaddingBottom = UDim.new(0, 6),
        PaddingLeft = UDim.new(0, 6),
        PaddingRight = UDim.new(0, 6),
    }).Parent = List

    for i, opt in ipairs(options) do
        local OptButton = New("TextButton", {
            Size = UDim2.new(1, 0, 0, 28),
            BackgroundColor3 = Theme.Elevated,
            Text = "",
            LayoutOrder = i,
            Parent = List,
        }, {Corner(5)})

        New("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 10, 0, 0),
            Size = UDim2.new(1, -20, 1, 0),
            Font = Theme.Font,
            Text = tostring(opt),
            TextColor3 = Theme.Text,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = OptButton,
        })

        Track(OptButton.MouseEnter:Connect(function()
            Tween(OptButton, {BackgroundColor3 = Theme.Hover}, FAST)
        end))
        Track(OptButton.MouseLeave:Connect(function()
            Tween(OptButton, {BackgroundColor3 = Theme.Elevated}, FAST)
        end))
        Track(OptButton.MouseButton1Click:Connect(function()
            selected = opt
            SelectedLabel.Text = tostring(opt)
            open = false
            Tween(Frame, {Size = UDim2.new(1, 0, 0, 36)}, MED)
            Tween(Arrow, {Rotation = 0}, MED)
            local ok, err = pcall(callback, opt)
            if not ok then warn("[PlasmaUI] Dropdown callback error: " .. tostring(err)) end
        end))
    end

    local listHeight = #options * 30 + 10

    Track(Header.MouseButton1Click:Connect(function()
        open = not open
        if open then
            Tween(Frame, {Size = UDim2.new(1, 0, 0, 36 + listHeight)}, MED)
            Tween(Arrow, {Rotation = 180}, MED)
        else
            Tween(Frame, {Size = UDim2.new(1, 0, 0, 36)}, MED)
            Tween(Arrow, {Rotation = 0}, MED)
        end
    end))

    local DropdownObj = {}
    function DropdownObj:Get() return selected end
    return DropdownObj
end

----------------------------------------------------------------------
-- TAB: TEXTBOX (with optional Confirm / Delete, e.g. RP Name + Bio)
----------------------------------------------------------------------
function TabMethods:CreateTextbox(text, placeholder, callback, options)
    callback = callback or function() end
    options = options or {}
    local order = self:_nextOrder()
    local maxLength = options.MaxLength
    local showConfirm = options.Confirm ~= false -- default true
    local showDelete = options.Delete == true

    local Frame = New("Frame", {
        Size = UDim2.new(1, 0, 0, 66),
        BackgroundColor3 = Theme.Panel,
        LayoutOrder = order,
        Parent = self.Container,
    }, {Corner(6), Stroke()})

    New("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 14, 0, 6),
        Size = UDim2.new(1, -28, 0, 16),
        Font = Theme.FontMed,
        Text = text,
        TextColor3 = Theme.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Frame,
    })

    local ConfirmW, DeleteW, Gap, Margin = 62, 56, 6, 14
    local rightUsed = 0
    if showDelete then rightUsed += DeleteW + Gap end
    if showConfirm then rightUsed += ConfirmW + Gap end

    local Box = New("TextBox", {
        Position = UDim2.new(0, 14, 0, 26),
        Size = UDim2.new(1, -(Margin + rightUsed + 14), 0, 26),
        BackgroundColor3 = Theme.Elevated,
        Text = "",
        PlaceholderText = placeholder or "",
        PlaceholderColor3 = Theme.SubText,
        Font = Theme.Font,
        TextColor3 = Theme.Text,
        TextSize = 13,
        ClearTextOnFocus = false,
        Parent = Frame,
    }, {Corner(5), New("UIPadding", {PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8)})})

    if maxLength then
        Track(Box:GetPropertyChangedSignal("Text"):Connect(function()
            if #Box.Text > maxLength then
                Box.Text = string.sub(Box.Text, 1, maxLength)
            end
        end))
    end

    local function fire()
        local ok, err = pcall(callback, Box.Text)
        if not ok then warn("[PlasmaUI] Textbox callback error: " .. tostring(err)) end
    end

    local cursor = Margin

    if showDelete then
        local DeleteBtn = New("TextButton", {
            Position = UDim2.new(1, -(cursor + DeleteW), 0, 26),
            Size = UDim2.new(0, DeleteW, 0, 26),
            BackgroundColor3 = Theme.Danger,
            Text = "Del",
            Font = Theme.FontMed,
            TextColor3 = Color3.new(1, 1, 1),
            TextSize = 12,
            Parent = Frame,
        }, {Corner(5)})
        Track(DeleteBtn.MouseButton1Click:Connect(function()
            Box.Text = ""
            local fn = options.OnDelete or callback
            local ok, err = pcall(fn, "")
            if not ok then warn("[PlasmaUI] Textbox delete callback error: " .. tostring(err)) end
        end))
        cursor += DeleteW + Gap
    end

    if showConfirm then
        local ConfirmBtn = New("TextButton", {
            Position = UDim2.new(1, -(cursor + ConfirmW), 0, 26),
            Size = UDim2.new(0, ConfirmW, 0, 26),
            BackgroundColor3 = Theme.Success,
            Text = "Confirm",
            Font = Theme.FontMed,
            TextColor3 = Color3.new(1, 1, 1),
            TextSize = 12,
            Parent = Frame,
        }, {Corner(5)})
        Track(ConfirmBtn.MouseButton1Click:Connect(fire))
    end

    Track(Box.FocusLost:Connect(function(enterPressed)
        if enterPressed and not showConfirm then
            fire()
        end
    end))

    local TextboxObj = {}
    function TextboxObj:Get() return Box.Text end
    function TextboxObj:Set(v) Box.Text = v end
    return TextboxObj
end

----------------------------------------------------------------------
-- TAB: LABEL / SECTION HEADER
----------------------------------------------------------------------
function TabMethods:CreateLabel(text)
    local order = self:_nextOrder()
    return New("TextLabel", {
        Size = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
        Font = Theme.Font,
        Text = text,
        TextColor3 = Theme.SubText,
        TextSize = 12,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = order,
        Parent = self.Container,
    })
end

function TabMethods:CreateSection(text)
    local order = self:_nextOrder()
    local Frame = New("Frame", {
        Size = UDim2.new(1, 0, 0, 24),
        BackgroundTransparency = 1,
        LayoutOrder = order,
        Parent = self.Container,
    })
    New("TextLabel", {
        Size = UDim2.new(1, 0, 0, 16),
        Position = UDim2.new(0, 0, 0, 6),
        BackgroundTransparency = 1,
        Font = Theme.FontBold,
        Text = string.upper(text),
        TextColor3 = Theme.Accent,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Frame,
    })
    return Frame
end

----------------------------------------------------------------------
-- TAB: ITEM GRID (icon grid + search, e.g. Shop / Tools panels)
----------------------------------------------------------------------
function TabMethods:CreateItemGrid(items, callback, options)
    callback = callback or function() end
    items = items or {}
    options = options or {}
    local order = self:_nextOrder()
    local columns = options.Columns or 4
    local cellSize = options.CellSize or 72

    local rows = math.max(1, math.ceil(#items / columns))
    local gridHeight = rows * (cellSize + 8) + 8
    local totalHeight = 40 + gridHeight

    local Frame = New("Frame", {
        Size = UDim2.new(1, 0, 0, totalHeight),
        BackgroundColor3 = Theme.Panel,
        LayoutOrder = order,
        Parent = self.Container,
    }, {Corner(6), Stroke()})

    local SearchBox = New("TextBox", {
        Position = UDim2.new(0, 8, 0, 6),
        Size = UDim2.new(1, -16, 0, 28),
        BackgroundColor3 = Theme.Elevated,
        Text = "",
        PlaceholderText = "Search...",
        PlaceholderColor3 = Theme.SubText,
        Font = Theme.Font,
        TextColor3 = Theme.Text,
        TextSize = 13,
        Parent = Frame,
    }, {Corner(5), New("UIPadding", {PaddingLeft = UDim.new(0, 8)})})

    local GridHolder = New("Frame", {
        Position = UDim2.new(0, 8, 0, 40),
        Size = UDim2.new(1, -16, 0, gridHeight),
        BackgroundTransparency = 1,
        Parent = Frame,
    })

    New("UIGridLayout", {
        CellSize = UDim2.new(0, cellSize, 0, cellSize),
        CellPadding = UDim2.new(0, 8, 0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }).Parent = GridHolder

    local cells = {}
    for i, item in ipairs(items) do
        local name = item.Name or tostring(item)
        local image = item.Image
        local price = item.Price

        local Cell = New("TextButton", {
            Size = UDim2.new(0, cellSize, 0, cellSize),
            BackgroundColor3 = Theme.Elevated,
            Text = "",
            LayoutOrder = i,
            Parent = GridHolder,
        }, {Corner(6)})

        if price then
            New("TextLabel", {
                Size = UDim2.new(1, -8, 0, 14),
                Position = UDim2.new(0, 4, 0, 2),
                BackgroundTransparency = 1,
                Font = Theme.FontBold,
                Text = tostring(price),
                TextColor3 = Theme.Success,
                TextSize = 10,
                TextXAlignment = Enum.TextXAlignment.Right,
                ZIndex = 2,
                Parent = Cell,
            })
        end

        if image then
            New("ImageLabel", {
                Size = UDim2.new(1, -16, 1, -30),
                Position = UDim2.new(0, 8, 0, 6),
                BackgroundTransparency = 1,
                Image = image,
                Parent = Cell,
            })
        end

        New("TextLabel", {
            Size = UDim2.new(1, -8, 0, 16),
            Position = UDim2.new(0, 4, 1, -18),
            BackgroundTransparency = 1,
            Font = Theme.Font,
            Text = name,
            TextColor3 = Theme.SubText,
            TextSize = 10,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Center,
            Parent = Cell,
        })

        Track(Cell.MouseEnter:Connect(function()
            Tween(Cell, {BackgroundColor3 = Theme.Hover}, FAST)
        end))
        Track(Cell.MouseLeave:Connect(function()
            Tween(Cell, {BackgroundColor3 = Theme.Elevated}, FAST)
        end))
        Track(Cell.MouseButton1Click:Connect(function()
            local ok, err = pcall(callback, item)
            if not ok then warn("[PlasmaUI] Grid callback error: " .. tostring(err)) end
        end))

        cells[i] = {Instance = Cell, Name = string.lower(name)}
    end

    Track(SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
        local query = string.lower(SearchBox.Text)
        for _, cell in ipairs(cells) do
            cell.Instance.Visible = (query == "" or string.find(cell.Name, query, 1, true) ~= nil)
        end
    end))

    return Frame
end

----------------------------------------------------------------------
-- LIBRARY: NOTIFICATIONS
----------------------------------------------------------------------
function Library:Notify(title, text, duration)
    duration = duration or 3
    local ScreenGui = self.ScreenGui
    if not ScreenGui then return end

    local holder = ScreenGui:FindFirstChild("NotifyHolder")
    if not holder then
        holder = New("Frame", {
            Name = "NotifyHolder",
            AnchorPoint = Vector2.new(1, 1),
            Position = UDim2.new(1, -16, 1, -16),
            Size = UDim2.new(0, 260, 1, -32),
            BackgroundTransparency = 1,
            Parent = ScreenGui,
        })
        New("UIListLayout", {
            Padding = UDim.new(0, 8),
            VerticalAlignment = Enum.VerticalAlignment.Bottom,
            SortOrder = Enum.SortOrder.LayoutOrder,
        }).Parent = holder
    end

    local Toast = New("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = Theme.Panel,
        BackgroundTransparency = 1,
        Parent = holder,
    }, {Corner(8), Stroke()})

    New("UIPadding", {
        PaddingTop = UDim.new(0, 10),
        PaddingBottom = UDim.new(0, 10),
        PaddingLeft = UDim.new(0, 12),
        PaddingRight = UDim.new(0, 12),
    }).Parent = Toast

    New("UIListLayout", {
        Padding = UDim.new(0, 2),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }).Parent = Toast

    New("TextLabel", {
        Size = UDim2.new(1, 0, 0, 16),
        BackgroundTransparency = 1,
        Font = Theme.FontBold,
        Text = title,
        TextColor3 = Theme.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        Parent = Toast,
    })

    New("TextLabel", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Font = Theme.Font,
        Text = text,
        TextColor3 = Theme.SubText,
        TextSize = 12,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Toast,
    })

    Tween(Toast, {BackgroundTransparency = 0}, MED)
    task.delay(duration, function()
        if Toast and Toast.Parent then
            Tween(Toast, {BackgroundTransparency = 1}, MED)
            task.wait(0.25)
            Toast:Destroy()
        end
    end)
end

----------------------------------------------------------------------
-- LIBRARY: DESTROY / CLEANUP
----------------------------------------------------------------------
function Library:Destroy()
    for _, conn in ipairs(self._connections) do
        if typeof(conn) == "RBXScriptConnection" and conn.Connected then
            conn:Disconnect()
        end
    end
    table.clear(self._connections)

    for _, window in ipairs(self._windows) do
        if window.ScreenGui then
            window.ScreenGui:Destroy()
        end
    end
    table.clear(self._windows)

    self.ScreenGui = nil
end

return Library
