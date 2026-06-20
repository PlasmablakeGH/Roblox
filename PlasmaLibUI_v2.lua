--[[
    ██████╗ ██╗      █████╗ ███████╗███╗   ███╗ █████╗ 
    ██╔══██╗██║     ██╔══██╗██╔════╝████╗ ████║██╔══██╗
    ██████╔╝██║     ███████║███████╗██╔████╔██║███████║
    ██╔═══╝ ██║     ██╔══██║╚════██║██║╚██╔╝██║██╔══██║
    ██║     ███████╗██║  ██║███████║██║ ╚═╝ ██║██║  ██║
    ╚═╝     ╚══════╝╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝╚═╝  ╚═╝
    ██╗     ██╗██████╗     ██╗   ██╗██╗
    ██║     ██║██╔══██╗    ██║   ██║██║
    ██║     ██║██████╔╝    ██║   ██║██║
    ██║     ██║██╔══██╗    ██║   ██║██║
    ███████╗██║██████╔╝    ╚██████╔╝██║
    ╚══════╝╚═╝╚═════╝      ╚═════╝ ╚═╝

    PlasmaLibUI  –  Modular Roblox Luau UI Library
    Theme        :  Hacker / Sci-Fi  (green-on-black)
    Version      :  2.0.0  (COMPLETE OVERHAUL)

    NEW FEATURES:
    • Fixed Dropdown z-index & click handling (renders ON TOP of everything)
    • CreateDropdownButton   – Dropdown + Execute Button combo
    • CreateInputButton      – TextBox + Execute Button combo
    • CreateKeybind          – Key capture element
    • CreateColorPicker      – RGB color selector
    • CreateMultiDropdown    – Multi-select dropdown
    • CreateProgressBar      – Animated progress indicator
    • Better animations, cleaner code, robust layering

    USAGE:
        local Library = loadstring(game:HttpGet(RAW_URL, true))()
        local Window  = Library:CreateWindow({ Title = "My Tool", IconId = "rbxassetid://7072706620" })
        local Tab     = Window:CreateTab("Main")

        Tab:CreateButton({ Label = "Click", Callback = function() print("!") end })
        Tab:CreateToggle({ Label = "ESP", Default = false, Callback = function(v) print(v) end })
        Tab:CreateSlider({ Label = "Speed", Min = 16, Max = 250, Default = 16, Callback = function(v) print(v) end })

        -- FIXED: Dropdown now properly layers on top
        Tab:CreateDropdown({ Label = "Team", Options = {"Red","Blue","Green","Yellow"}, Callback = function(v) print(v) end })

        -- NEW: Combined elements
        Tab:CreateDropdownButton({ 
            Label = "Teleport", 
            Options = {"Spawn","Base","Shop"}, 
            ButtonLabel = "GO",
            Callback = function(selected) print("Teleport to", selected) end 
        })

        Tab:CreateInputButton({
            Label = "Command",
            Placeholder = "enter cmd...",
            ButtonLabel = "RUN",
            Callback = function(text, enterPressed) print("Command:", text) end
        })

        Tab:CreateKeybind({ Label = "Fly Key", Default = Enum.KeyCode.F, Callback = function(key) print("Bound to", key.Name) end })
        Tab:CreateColorPicker({ Label = "ESP Color", Default = Color3.fromRGB(0,255,100), Callback = function(c) print(c) end })
        Tab:CreateMultiDropdown({ Label = "Tags", Options = {"Admin","VIP","Mod","User"}, Callback = function(selectedTable) print(selectedTable) end })
        Tab:CreateProgressBar({ Label = "Health", Value = 75 })
--]]

------------------------------------------------------------------------
-- Services
------------------------------------------------------------------------
local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local RunService       = game:GetService("RunService")
local HttpService      = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

------------------------------------------------------------------------
-- Theme  (edit here to reskin everything)
------------------------------------------------------------------------
local Theme = {
    Background   = Color3.fromRGB(8,   12,  8),
    Surface      = Color3.fromRGB(12,  20,  12),
    SurfaceAlt   = Color3.fromRGB(18,  30,  18),
    SurfaceHover = Color3.fromRGB(25,  45,  25),
    Border       = Color3.fromRGB(0,   200, 80),
    BorderDim    = Color3.fromRGB(0,   80,  30),
    Accent       = Color3.fromRGB(0,   255, 100),
    AccentDim    = Color3.fromRGB(0,   140, 55),
    TextPrimary  = Color3.fromRGB(0,   255, 100),
    TextSecondary= Color3.fromRGB(0,   180, 70),
    TextDisabled = Color3.fromRGB(0,   80,  30),
    Danger       = Color3.fromRGB(255, 50,  50),
    SliderFill   = Color3.fromRGB(0,   220, 90),
    SliderTrack  = Color3.fromRGB(15,  35,  15),
    ToggleOn     = Color3.fromRGB(0,   220, 90),
    ToggleOff    = Color3.fromRGB(20,  40,  20),
    ToggleKnob   = Color3.fromRGB(200, 255, 210),
    Scanline     = Color3.fromRGB(0,   255, 100),
    TabActive    = Color3.fromRGB(0,   200, 75),
    TabInactive  = Color3.fromRGB(0,   45,  18),
    TitleBar     = Color3.fromRGB(6,   16,  6),
    DropdownOverlay = Color3.fromRGB(10, 20, 10),

    CornerRadius    = UDim.new(0, 4),
    BorderThickness = 1,
    FontMono        = Enum.Font.Code,
    FontUI          = Enum.Font.GothamMedium,
    FontBold        = Enum.Font.GothamBold,
    TextSizeTitle   = 15,
    TextSizeBody    = 13,
    TextSizeSmall   = 11,

    Tween     = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    TweenSlow = TweenInfo.new(0.32, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    TweenFast = TweenInfo.new(0.10, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
}

------------------------------------------------------------------------
-- Internal helpers
------------------------------------------------------------------------
local function tw(obj, props, info)
    if not obj or not obj.Parent then return end
    TweenService:Create(obj, info or Theme.Tween, props):Play()
end

local function Decorate(f, radius, strokeCol, strokeThick)
    local c = Instance.new("UICorner")
    c.CornerRadius = radius or Theme.CornerRadius
    c.Parent = f
    if strokeCol ~= false then
        local s = Instance.new("UIStroke")
        s.Color            = strokeCol or Theme.BorderDim
        s.Thickness        = strokeThick or Theme.BorderThickness
        s.ApplyStrokeMode  = Enum.ApplyStrokeMode.Border
        s.Parent           = f
    end
end

local function NewLabel(p)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.TextColor3   = p.Color    or Theme.TextPrimary
    l.Font         = p.Font     or Theme.FontUI
    l.TextSize     = p.Size2    or Theme.TextSizeBody
    l.Text         = p.Text     or ""
    l.TextXAlignment = p.AlignX or Enum.TextXAlignment.Left
    l.TextYAlignment = Enum.TextYAlignment.Center
    l.TextTruncate = Enum.TextTruncate.AtEnd
    l.Size         = p.Size     or UDim2.new(1,0,1,0)
    l.Position     = p.Pos      or UDim2.new(0,0,0,0)
    l.ZIndex       = p.Z        or 5
    l.RichText     = p.Rich     or false
    l.Parent       = p.Parent
    return l
end

local function NewFrame(p)
    local f = Instance.new("Frame")
    f.BackgroundColor3       = p.Color or Theme.Surface
    f.BackgroundTransparency = p.Trans or 0
    f.BorderSizePixel        = 0
    f.Size                   = p.Size  or UDim2.new(1,0,1,0)
    f.Position               = p.Pos   or UDim2.new(0,0,0,0)
    f.ZIndex                 = p.Z     or 4
    f.ClipsDescendants       = p.Clip  or false
    f.Name                   = p.Name  or "Frame"
    f.Parent                 = p.Parent
    return f
end

local function AddScanlines(parent)
    local over = Instance.new("Frame")
    over.BackgroundTransparency = 1
    over.Size          = UDim2.new(1,0,1,0)
    over.ZIndex        = 60
    over.BorderSizePixel = 0
    over.Name          = "Scanlines"
    over.Parent        = parent
    local grid = Instance.new("UIGridLayout")
    grid.CellSize    = UDim2.new(1,0,0,2)
    grid.CellPadding = UDim2.new(0,0,0,2)
    grid.Parent      = over
    for _ = 1, 80 do
        local ln = Instance.new("Frame")
        ln.BackgroundColor3       = Theme.Scanline
        ln.BackgroundTransparency = 0.965
        ln.BorderSizePixel        = 0
        ln.Parent = over
    end
end

------------------------------------------------------------------------
-- Secure GUI parent
------------------------------------------------------------------------
local function GuiParent()
    if gethui then return gethui() end
    local ok, cg = pcall(function() return game:GetService("CoreGui") end)
    if ok and cg then return cg end
    return LocalPlayer:WaitForChild("PlayerGui")
end

------------------------------------------------------------------------
-- Drag  (pure UIS, zero RunService)
------------------------------------------------------------------------
local function MakeDraggable(handle, target)
    local active, origin, startPos = false, Vector2.zero, UDim2.new()
    handle.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            active   = true
            origin   = inp.Position
            startPos = target.Position
            inp.Changed:Connect(function()
                if inp.UserInputState == Enum.UserInputState.End then
                    active = false
                end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if not active then return end
        if inp.UserInputType ~= Enum.UserInputType.MouseMovement
        and inp.UserInputType ~= Enum.UserInputType.Touch then return end
        local d = inp.Position - origin
        target.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + d.X,
            startPos.Y.Scale, startPos.Y.Offset + d.Y
        )
    end)
end

------------------------------------------------------------------------
-- GLOBAL DROPDOWN MANAGER (fixes z-index layering)
------------------------------------------------------------------------
local GlobalDropdowns = {}
local DropdownScreenGui = nil

local function GetDropdownContainer()
    if DropdownScreenGui and DropdownScreenGui.Parent then return DropdownScreenGui end
    DropdownScreenGui = Instance.new("ScreenGui")
    DropdownScreenGui.Name = "PlasmaLibUI_DropdownLayer"
    DropdownScreenGui.ResetOnSpawn = false
    DropdownScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    DropdownScreenGui.DisplayOrder = 100000
    DropdownScreenGui.IgnoreGuiInset = true
    DropdownScreenGui.Parent = GuiParent()
    return DropdownScreenGui
end

local function CloseAllDropdowns(exceptListFrame)
    for _, entry in ipairs(GlobalDropdowns) do
        if entry.listFrame ~= exceptListFrame and entry.isOpen then
            entry.isOpen = false
            entry.listFrame.Visible = false
            if entry.button then
                tw(entry.button, {BackgroundColor3 = Theme.Surface})
            end
        end
    end
end

UserInputService.InputBegan:Connect(function(inp, gameProcessed)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
        local mousePos = UserInputService:GetMouseLocation()
        local anyClickedInside = false
        for _, entry in ipairs(GlobalDropdowns) do
            if entry.isOpen and entry.listFrame.Visible then
                local absPos = entry.listFrame.AbsolutePosition
                local absSize = entry.listFrame.AbsoluteSize
                if mousePos.X >= absPos.X and mousePos.X <= absPos.X + absSize.X
                   and mousePos.Y >= absPos.Y and mousePos.Y <= absPos.Y + absSize.Y then
                    anyClickedInside = true
                    break
                end
            end
        end
        if not anyClickedInside then
            CloseAllDropdowns(nil)
        end
    end
end)

------------------------------------------------------------------------
-- Library
------------------------------------------------------------------------
local Library = {}
Library.__index = Library

------------------------------------------------------------------------
-- Library:CreateWindow
------------------------------------------------------------------------
function Library:CreateWindow(opts)
    opts = opts or {}
    local TITLE  = opts.Title  or "PlasmaLibUI"
    local ICON   = opts.IconId or "rbxassetid://7072706620"
    local W      = opts.Width  or 500
    local H      = opts.Height or 380

    local sg = Instance.new("ScreenGui")
    sg.Name             = "PlasmaLibUI_" .. TITLE:gsub("%s","")
    sg.ResetOnSpawn     = false
    sg.ZIndexBehavior   = Enum.ZIndexBehavior.Global
    sg.IgnoreGuiInset   = true
    sg.DisplayOrder     = 999
    sg.Parent           = GuiParent()

    local win = NewFrame({
        Name   = "Window",
        Color  = Theme.Background,
        Size   = UDim2.new(0, W, 0, 0),
        Pos    = UDim2.new(0.5,-W/2, 0.5,-H/2),
        Clip   = true,
        Z      = 2,
        Parent = sg,
    })
    Decorate(win, UDim.new(0,6), Theme.Border, 1)
    AddScanlines(win)

    NewFrame({ Color=Theme.Accent, Size=UDim2.new(1,0,0,2), Z=6, Parent=win })

    local titleBar = NewFrame({
        Name   = "TitleBar",
        Color  = Theme.TitleBar,
        Size   = UDim2.new(1,0,0,38),
        Pos    = UDim2.new(0,0,0,2),
        Z      = 5,
        Parent = win,
    })

    local iconImg = Instance.new("ImageLabel")
    iconImg.BackgroundTransparency = 1
    iconImg.Size      = UDim2.new(0,22,0,22)
    iconImg.Position  = UDim2.new(0,8,0.5,-11)
    iconImg.Image     = ICON
    iconImg.ImageColor3 = Color3.fromRGB(0, 255, 100)
    iconImg.ZIndex    = 7
    iconImg.Parent    = titleBar

    NewLabel({
        Text   = ("[ %s ]"):format(TITLE:upper()),
        Color  = Theme.Accent,
        Font   = Theme.FontMono,
        Size2  = Theme.TextSizeTitle,
        Size   = UDim2.new(1,-100,1,0),
        Pos    = UDim2.new(0,38,0,0),
        Z      = 7,
        Parent = titleBar,
    })

    NewLabel({
        Text   = "Plasmablake",
        Color  = Theme.AccentDim,
        Font   = Theme.FontMono,
        Size2  = 10,
        AlignX = Enum.TextXAlignment.Right,
        Size   = UDim2.new(0,82,1,0),
        Pos    = UDim2.new(1,-116,0,0),
        Z      = 7,
        Parent = titleBar,
    })

    local closeBtn = Instance.new("TextButton")
    closeBtn.BackgroundColor3 = Color3.fromRGB(28,8,8)
    closeBtn.Size       = UDim2.new(0,28,0,20)
    closeBtn.Position   = UDim2.new(1,-34,0.5,-10)
    closeBtn.Text       = "X"
    closeBtn.Font       = Theme.FontBold
    closeBtn.TextSize   = 13
    closeBtn.TextColor3 = Theme.Danger
    closeBtn.BorderSizePixel = 0
    closeBtn.AutoButtonColor = false
    closeBtn.ZIndex = 8
    closeBtn.Parent = titleBar
    Decorate(closeBtn, UDim.new(0,3), Theme.Danger, 1)
    closeBtn.MouseEnter:Connect(function()
        tw(closeBtn,{BackgroundColor3=Theme.Danger, TextColor3=Color3.new(1,1,1)})
    end)
    closeBtn.MouseLeave:Connect(function()
        tw(closeBtn,{BackgroundColor3=Color3.fromRGB(28,8,8), TextColor3=Theme.Danger})
    end)
    closeBtn.MouseButton1Click:Connect(function()
        tw(win,{Size=UDim2.new(0,W,0,0)}, Theme.TweenSlow)
        task.delay(0.38, function() sg:Destroy() end)
    end)

    MakeDraggable(titleBar, win)

    local tabBar = NewFrame({
        Name   = "TabBar",
        Color  = Theme.TitleBar,
        Size   = UDim2.new(1,0,0,30),
        Pos    = UDim2.new(0,0,0,40),
        Z      = 5,
        Parent = win,
    })
    local tabBarList = Instance.new("UIListLayout")
    tabBarList.FillDirection = Enum.FillDirection.Horizontal
    tabBarList.HorizontalAlignment = Enum.HorizontalAlignment.Center
    tabBarList.SortOrder     = Enum.SortOrder.LayoutOrder
    tabBarList.Padding       = UDim.new(0, 2)
    tabBarList.Parent        = tabBar

    local tabBarPad = Instance.new("UIPadding")
    tabBarPad.PaddingLeft = UDim.new(0, 4)
    tabBarPad.Parent      = tabBar

    local CONTENT_TOP = 71
    local STATUSBAR_H = 18
    local contentArea = NewFrame({
        Name   = "ContentArea",
        Color  = Theme.Background,
        Size   = UDim2.new(1,0,1,-(CONTENT_TOP + STATUSBAR_H)),
        Pos    = UDim2.new(0,0,0,CONTENT_TOP),
        Z      = 3,
        Parent = win,
    })

    local statusBar = NewFrame({
        Name   = "StatusBar",
        Color  = Theme.TitleBar,
        Size   = UDim2.new(1,0,0,STATUSBAR_H),
        Pos    = UDim2.new(0,0,1,-STATUSBAR_H),
        Z      = 5,
        Parent = win,
    })
    NewLabel({
        Text   = "◈ ENCRYPTED // ENCRYPTED // ENCRYPTED",
        Color  = Theme.BorderDim,
        Font   = Theme.FontMono,
        Size2  = 10,
        AlignX = Enum.TextXAlignment.Center,
        Z      = 6,
        Parent = statusBar,
    })

    local tabs       = {}
    local activeIdx  = 0

    local function SetActiveTab(idx)
        if activeIdx == idx then return end
        activeIdx = idx
        for i, entry in ipairs(tabs) do
            if i == idx then
                tw(entry.btn, {
                    BackgroundColor3 = Theme.TabActive,
                    TextColor3       = Theme.Background,
                })
                entry.page.Visible = true
            else
                tw(entry.btn, {
                    BackgroundColor3 = Theme.TabInactive,
                    TextColor3       = Theme.TextSecondary,
                })
                entry.page.Visible = false
            end
        end
    end

    local Window = {}

    function Window:SetIcon(id)
        iconImg.Image = id
    end

    function Window:CreateTab(name)
        name = tostring(name or "Tab")

        local btn = Instance.new("TextButton")
        btn.Name             = "TabBtn_" .. name
        btn.BackgroundColor3 = Theme.TabInactive
        btn.Size             = UDim2.new(0, 86, 1, -6)
        btn.Text             = name:upper()
        btn.Font             = Theme.FontMono
        btn.TextSize         = Theme.TextSizeSmall
        btn.TextColor3       = Theme.TextSecondary
        btn.BorderSizePixel  = 0
        btn.AutoButtonColor  = false
        btn.LayoutOrder      = #tabs + 1
        btn.ZIndex           = 7
        btn.Parent           = tabBar
        Decorate(btn, UDim.new(0,3), false)

        local page = Instance.new("ScrollingFrame")
        page.Name                   = "Page_" .. name
        page.BackgroundTransparency = 1
        page.BorderSizePixel        = 0
        page.Size                   = UDim2.new(1,0,1,0)
        page.Position               = UDim2.new(0,0,0,0)
        page.ScrollBarThickness     = 3
        page.ScrollBarImageColor3   = Theme.AccentDim
        page.CanvasSize             = UDim2.new(0,0,0,0)
        page.AutomaticCanvasSize    = Enum.AutomaticSize.Y
        page.ZIndex                 = 4
        page.Visible                = false
        page.Parent                 = contentArea

        local listLayout = Instance.new("UIListLayout")
        listLayout.SortOrder        = Enum.SortOrder.LayoutOrder
        listLayout.Padding          = UDim.new(0, 6)
        listLayout.Parent           = page

        local pagePad = Instance.new("UIPadding")
        pagePad.PaddingTop    = UDim.new(0, 8)
        pagePad.PaddingLeft   = UDim.new(0, 10)
        pagePad.PaddingRight  = UDim.new(0, 10)
        pagePad.PaddingBottom = UDim.new(0, 8)
        pagePad.Parent        = page

        local myIndex = #tabs + 1
        tabs[myIndex] = { btn = btn, page = page }

        if myIndex == 1 then
            SetActiveTab(1)
        end

        btn.MouseButton1Click:Connect(function()
            SetActiveTab(myIndex)
        end)
        btn.MouseEnter:Connect(function()
            if activeIdx ~= myIndex then
                tw(btn, {BackgroundColor3 = Theme.SurfaceAlt})
            end
        end)
        btn.MouseLeave:Connect(function()
            if activeIdx ~= myIndex then
                tw(btn, {BackgroundColor3 = Theme.TabInactive})
            end
        end)

        local elementOrder = 0
        local function NextOrder()
            elementOrder = elementOrder + 1
            return elementOrder
        end

        local function ElemFrame(h, customParent)
            local ef = NewFrame({
                Color  = Theme.SurfaceAlt,
                Size   = UDim2.new(1,0,0, h or 38),
                Z      = 5,
                Name   = "Element",
                Parent = customParent or page,
            })
            ef.LayoutOrder = NextOrder()
            Decorate(ef, UDim.new(0,4), Theme.BorderDim, 1)
            local pad = Instance.new("UIPadding")
            pad.PaddingLeft  = UDim.new(0,10)
            pad.PaddingRight = UDim.new(0,10)
            pad.Parent       = ef
            return ef
        end

        local Tab = {}

        function Tab:CreateLabel(text)
            local ef = ElemFrame(26)
            ef.BackgroundColor3 = Theme.Surface
            NewLabel({
                Text   = "// " .. (text or ""),
                Color  = Theme.TextSecondary,
                Font   = Theme.FontMono,
                Size2  = Theme.TextSizeSmall,
                Z      = 6,
                Parent = ef,
            })
        end

        function Tab:CreateSection(text)
            local ef = ElemFrame(22)
            ef.BackgroundTransparency = 1
            NewLabel({
                Text   = ("── %s ──"):format((text or "Section"):upper()),
                Color  = Theme.AccentDim,
                Font   = Theme.FontMono,
                Size2  = 10,
                AlignX = Enum.TextXAlignment.Center,
                Z      = 6,
                Parent = ef,
            })
        end

        function Tab:CreateButton(opts)
            opts = opts or {}
            local lbl = opts.Label    or "Button"
            local cb  = opts.Callback or function() end

            local ef  = ElemFrame(36)
            local btn2 = Instance.new("TextButton")
            btn2.BackgroundColor3 = Theme.Surface
            btn2.Size             = UDim2.new(1,0,1,0)
            btn2.Text             = ("▶  %s"):format(lbl:upper())
            btn2.Font             = Theme.FontMono
            btn2.TextSize         = Theme.TextSizeBody
            btn2.TextColor3       = Theme.Accent
            btn2.BorderSizePixel  = 0
            btn2.AutoButtonColor  = false
            btn2.ZIndex           = 6
            btn2.Parent           = ef
            Decorate(btn2, UDim.new(0,4), Theme.Border, 1)

            btn2.MouseEnter:Connect(function()
                tw(btn2,{BackgroundColor3=Theme.SurfaceAlt, TextColor3=Theme.TextPrimary})
            end)
            btn2.MouseLeave:Connect(function()
                tw(btn2,{BackgroundColor3=Theme.Surface, TextColor3=Theme.Accent})
            end)
            btn2.MouseButton1Down:Connect(function()
                tw(btn2,{BackgroundColor3=Theme.AccentDim})
            end)
            btn2.MouseButton1Up:Connect(function()
                tw(btn2,{BackgroundColor3=Theme.SurfaceAlt})
            end)
            btn2.MouseButton1Click:Connect(function() pcall(cb) end)

            return btn2
        end

        function Tab:CreateToggle(opts)
            opts = opts or {}
            local lbl   = opts.Label    or "Toggle"
            local state = opts.Default  or false
            local cb    = opts.Callback or function() end

            local ef = ElemFrame(38)

            NewLabel({
                Text   = lbl,
                Color  = Theme.TextPrimary,
                Font   = Theme.FontUI,
                Size2  = Theme.TextSizeBody,
                Size   = UDim2.new(1,-56,1,0),
                Z      = 6,
                Parent = ef,
            })

            local track = NewFrame({
                Color  = state and Theme.ToggleOn or Theme.ToggleOff,
                Size   = UDim2.new(0,44,0,22),
                Pos    = UDim2.new(1,-44,0.5,-11),
                Z      = 7,
                Parent = ef,
            })
            Decorate(track, UDim.new(0,11), Theme.Border, 1)

            local knob = NewFrame({
                Color  = Theme.ToggleKnob,
                Size   = UDim2.new(0,16,0,16),
                Pos    = state and UDim2.new(1,-19,0.5,-8) or UDim2.new(0,3,0.5,-8),
                Z      = 8,
                Parent = track,
            })
            Decorate(knob, UDim.new(0,8), false)

            local hit = Instance.new("TextButton")
            hit.BackgroundTransparency = 1
            hit.Size   = UDim2.new(1,0,1,0)
            hit.Text   = ""
            hit.ZIndex = 9
            hit.Parent = ef

            local Toggle = {}
            function Toggle:Set(v)
                state = v
                tw(track, {BackgroundColor3 = state and Theme.ToggleOn or Theme.ToggleOff})
                tw(knob,  {Position = state
                    and UDim2.new(1,-19,0.5,-8)
                    or  UDim2.new(0,3,0.5,-8)})
                pcall(cb, state)
            end
            function Toggle:Get() return state end

            hit.MouseButton1Click:Connect(function() Toggle:Set(not state) end)
            hit.MouseEnter:Connect(function() tw(ef,{BackgroundColor3=Theme.Surface}) end)
            hit.MouseLeave:Connect(function() tw(ef,{BackgroundColor3=Theme.SurfaceAlt}) end)

            return Toggle
        end

        function Tab:CreateSlider(opts)
            opts = opts or {}
            local lbl  = opts.Label    or "Slider"
            local min  = opts.Min      or 0
            local max  = opts.Max      or 100
            local step = opts.Step     or 1
            local val  = math.clamp(opts.Default or min, min, max)
            local cb   = opts.Callback or function() end

            local ef = ElemFrame(54)

            local topRow = NewFrame({Trans=1, Size=UDim2.new(1,0,0,22), Z=6, Parent=ef})
            NewLabel({
                Text   = lbl,
                Color  = Theme.TextPrimary,
                Font   = Theme.FontUI,
                Size2  = Theme.TextSizeBody,
                Size   = UDim2.new(0.7,0,1,0),
                Z      = 7,
                Parent = topRow,
            })
            local valLbl = NewLabel({
                Text   = tostring(val),
                Color  = Theme.Accent,
                Font   = Theme.FontMono,
                Size2  = Theme.TextSizeBody,
                AlignX = Enum.TextXAlignment.Right,
                Size   = UDim2.new(0.3,0,1,0),
                Pos    = UDim2.new(0.7,0,0,0),
                Z      = 7,
                Parent = topRow,
            })

            local botRow = NewFrame({Trans=1, Size=UDim2.new(1,0,0,20), Pos=UDim2.new(0,0,0,26), Z=6, Parent=ef})
            local track  = NewFrame({
                Color  = Theme.SliderTrack,
                Size   = UDim2.new(1,0,0,8),
                Pos    = UDim2.new(0,0,0.5,-4),
                Z      = 7,
                Parent = botRow,
            })
            Decorate(track, UDim.new(0,4), Theme.BorderDim, 1)

            local fill = NewFrame({
                Color  = Theme.SliderFill,
                Size   = UDim2.new((val-min)/(max-min), 0, 1, 0),
                Z      = 8,
                Parent = track,
            })
            Decorate(fill, UDim.new(0,4), false)

            local knob = NewFrame({
                Color  = Theme.Accent,
                Size   = UDim2.new(0,14,0,14),
                Pos    = UDim2.new((val-min)/(max-min),-7,0.5,-7),
                Z      = 9,
                Parent = track,
            })
            Decorate(knob, UDim.new(0,7), Theme.Background, 1)

            local dragging = false

            local function Recalc(absX)
                local pct    = math.clamp((absX - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
                local raw    = min + (max - min) * pct
                val          = math.clamp(math.floor((raw - min) / step + 0.5) * step + min, min, max)
                local newPct = (val - min) / (max - min)
                tw(fill,  {Size     = UDim2.new(newPct,0,1,0)})
                tw(knob,  {Position = UDim2.new(newPct,-7,0.5,-7)})
                valLbl.Text = tostring(val)
                pcall(cb, val)
            end

            track.InputBegan:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1
                or inp.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    Recalc(inp.Position.X)
                end
            end)
            UserInputService.InputChanged:Connect(function(inp)
                if not dragging then return end
                if inp.UserInputType ~= Enum.UserInputType.MouseMovement
                and inp.UserInputType ~= Enum.UserInputType.Touch then return end
                Recalc(inp.Position.X)
            end)
            UserInputService.InputEnded:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1
                or inp.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                end
            end)

            local Slider = {}
            function Slider:Set(v)
                val = math.clamp(v, min, max)
                local p = (val-min)/(max-min)
                tw(fill,  {Size     = UDim2.new(p,0,1,0)})
                tw(knob,  {Position = UDim2.new(p,-7,0.5,-7)})
                valLbl.Text = tostring(val)
                pcall(cb, val)
            end
            function Slider:Get() return val end

            return Slider
        end

        ------------------------------------------------------------------
        -- FIXED: Tab:CreateDropdown (renders on top via global layer)
        ------------------------------------------------------------------
        function Tab:CreateDropdown(opts)
            opts = opts or {}
            local lbl      = opts.Label    or "Dropdown"
            local choices  = opts.Options  or {}
            local cb       = opts.Callback or function() end
            local selected = opts.Default  or choices[1] or "None"
            local open     = false

            local ef = ElemFrame(38)
            ef.ClipsDescendants = false

            NewLabel({
                Text   = lbl,
                Color  = Theme.TextPrimary,
                Font   = Theme.FontUI,
                Size2  = Theme.TextSizeBody,
                Size   = UDim2.new(0.44,0,1,0),
                Z      = 6,
                Parent = ef,
            })

            local dropBtn = Instance.new("TextButton")
            dropBtn.BackgroundColor3 = Theme.Surface
            dropBtn.Size             = UDim2.new(0.53,0,0,26)
            dropBtn.Position         = UDim2.new(0.46,0,0.5,-13)
            dropBtn.Text             = ("  %s  ▾"):format(selected)
            dropBtn.Font             = Theme.FontMono
            dropBtn.TextSize         = Theme.TextSizeSmall
            dropBtn.TextColor3       = Theme.Accent
            dropBtn.BorderSizePixel  = 0
            dropBtn.AutoButtonColor  = false
            dropBtn.ZIndex           = 7
            dropBtn.ClipsDescendants = false
            dropBtn.Parent           = ef
            Decorate(dropBtn, UDim.new(0,4), Theme.Border, 1)

            -- GLOBAL LAYER: Parented to separate ScreenGui with DisplayOrder 100000
            local listH = math.min(#choices, 6) * 28
            local listFrame = NewFrame({
                Color  = Theme.DropdownOverlay,
                Size   = UDim2.new(0, 100, 0, listH),
                Pos    = UDim2.new(0, 0, 0, 0),
                Z      = 1000,
                Clip   = true,
                Parent = GetDropdownContainer(),
            })
            listFrame.Visible = false
            listFrame.Name = "DropdownList_" .. lbl
            Decorate(listFrame, UDim.new(0,4), Theme.Border, 1)

            -- Drop shadow
            local shadow = Instance.new("ImageLabel")
            shadow.BackgroundTransparency = 1
            shadow.Image = "rbxassetid://5554236805"
            shadow.ImageColor3 = Color3.new(0,0,0)
            shadow.ImageTransparency = 0.6
            shadow.ScaleType = Enum.ScaleType.Slice
            shadow.SliceCenter = Rect.new(23,23,277,277)
            shadow.Size = UDim2.new(1,20,1,20)
            shadow.Position = UDim2.new(0,-10,0,-10)
            shadow.ZIndex = 999
            shadow.Parent = listFrame

            local ll = Instance.new("UIListLayout")
            ll.SortOrder = Enum.SortOrder.LayoutOrder
            ll.Parent    = listFrame

            local itemParent = listFrame
            if #choices > 6 then
                local sf = Instance.new("ScrollingFrame")
                sf.BackgroundTransparency = 1
                sf.Size = UDim2.new(1,0,1,0)
                sf.CanvasSize = UDim2.new(0,0,0,#choices*28)
                sf.ScrollBarThickness = 3
                sf.ScrollBarImageColor3 = Theme.AccentDim
                sf.BorderSizePixel = 0
                sf.ZIndex = 1001
                sf.Parent = listFrame
                ll.Parent = sf
                itemParent = sf
            end

            for i, choice in ipairs(choices) do
                local item = Instance.new("TextButton")
                item.BackgroundColor3 = Theme.DropdownOverlay
                item.Size = UDim2.new(1,0,0,28)
                item.Text = ("  %s"):format(choice)
                item.Font = Theme.FontMono
                item.TextSize = Theme.TextSizeSmall
                item.TextColor3 = Theme.TextSecondary
                item.TextXAlignment = Enum.TextXAlignment.Left
                item.BorderSizePixel = 0
                item.AutoButtonColor = false
                item.LayoutOrder = i
                item.ZIndex = 1002
                item.Parent = itemParent

                item.MouseEnter:Connect(function()
                    tw(item,{BackgroundColor3=Theme.SurfaceAlt,TextColor3=Theme.Accent})
                end)
                item.MouseLeave:Connect(function()
                    tw(item,{BackgroundColor3=Theme.DropdownOverlay,TextColor3=Theme.TextSecondary})
                end)
                item.MouseButton1Click:Connect(function()
                    selected = choice
                    dropBtn.Text = ("  %s  ▾"):format(selected)
                    open = false
                    listFrame.Visible = false
                    pcall(cb, selected)
                end)
            end

            local ddEntry = {
                listFrame = listFrame,
                button = dropBtn,
                isOpen = false,
            }
            table.insert(GlobalDropdowns, ddEntry)

            local function UpdateListPosition()
                local absPos = dropBtn.AbsolutePosition
                local absSize = dropBtn.AbsoluteSize
                listFrame.Position = UDim2.new(0, absPos.X, 0, absPos.Y + absSize.Y + 4)
                listFrame.Size = UDim2.new(0, absSize.X, 0, listH)
            end

            dropBtn.MouseButton1Click:Connect(function()
                UpdateListPosition()
                open = not open
                ddEntry.isOpen = open
                listFrame.Visible = open
                CloseAllDropdowns(listFrame)
                tw(dropBtn,{BackgroundColor3 = open and Theme.SurfaceAlt or Theme.Surface})
            end)
            dropBtn.MouseEnter:Connect(function()
                if not open then tw(dropBtn,{BackgroundColor3=Theme.SurfaceAlt}) end
            end)
            dropBtn.MouseLeave:Connect(function()
                if not open then tw(dropBtn,{BackgroundColor3=Theme.Surface}) end
            end)

            local conn = RunService.RenderStepped:Connect(function()
                if open then UpdateListPosition() end
            end)

            local DD = {}
            function DD:Set(v)
                selected = v
                dropBtn.Text = ("  %s  ▾"):format(v)
                pcall(cb, v)
            end
            function DD:Get() return selected end
            function DD:Destroy()
                conn:Disconnect()
                for i, entry in ipairs(GlobalDropdowns) do
                    if entry == ddEntry then
                        table.remove(GlobalDropdowns, i)
                        break
                    end
                end
                listFrame:Destroy()
            end
            return DD
        end

        ------------------------------------------------------------------
        -- Tab:CreateTextInput
        ------------------------------------------------------------------
        function Tab:CreateTextInput(opts)
            opts = opts or {}
            local lbl  = opts.Label       or "Input"
            local ph   = opts.Placeholder or "type here..."
            local cb   = opts.Callback    or function() end

            local ef = ElemFrame(38)

            NewLabel({
                Text   = lbl,
                Color  = Theme.TextPrimary,
                Font   = Theme.FontUI,
                Size2  = Theme.TextSizeBody,
                Size   = UDim2.new(0.38,0,1,0),
                Z      = 6,
                Parent = ef,
            })

            local box = Instance.new("TextBox")
            box.BackgroundColor3  = Theme.Surface
            box.Size              = UDim2.new(0.58,0,0,26)
            box.Position          = UDim2.new(0.40,0,0.5,-13)
            box.Text              = ""
            box.PlaceholderText   = ph
            box.PlaceholderColor3 = Theme.TextDisabled
            box.Font              = Theme.FontMono
            box.TextSize          = Theme.TextSizeSmall
            box.TextColor3        = Theme.Accent
            box.BorderSizePixel   = 0
            box.ZIndex            = 7
            box.ClearTextOnFocus  = false
            box.Parent            = ef
            Decorate(box, UDim.new(0,4), Theme.Border, 1)

            local p = Instance.new("UIPadding")
            p.PaddingLeft = UDim.new(0,6)
            p.Parent = box

            box.Focused:Connect(function()   tw(box,{BackgroundColor3=Theme.SurfaceAlt}) end)
            box.FocusLost:Connect(function(enter)
                tw(box,{BackgroundColor3=Theme.Surface})
                pcall(cb, box.Text, enter)
            end)

            local Inp = {}
            function Inp:Get() return box.Text end
            function Inp:Set(v) box.Text = tostring(v) end
            return Inp
        end

        ------------------------------------------------------------------
        -- NEW: Tab:CreateDropdownButton  (Dropdown + Execute Button)
        ------------------------------------------------------------------
        function Tab:CreateDropdownButton(opts)
            opts = opts or {}
            local lbl         = opts.Label       or "Action"
            local choices     = opts.Options     or {}
            local btnLabel    = opts.ButtonLabel or "EXECUTE"
            local cb          = opts.Callback    or function() end
            local selected    = opts.Default    or choices[1] or "None"

            local ef = ElemFrame(38)
            ef.ClipsDescendants = false

            NewLabel({
                Text   = lbl,
                Color  = Theme.TextPrimary,
                Font   = Theme.FontUI,
                Size2  = Theme.TextSizeBody,
                Size   = UDim2.new(0.30,0,1,0),
                Z      = 6,
                Parent = ef,
            })

            local dropBtn = Instance.new("TextButton")
            dropBtn.BackgroundColor3 = Theme.Surface
            dropBtn.Size             = UDim2.new(0.35,0,0,26)
            dropBtn.Position         = UDim2.new(0.31,0,0.5,-13)
            dropBtn.Text             = ("  %s  ▾"):format(selected)
            dropBtn.Font             = Theme.FontMono
            dropBtn.TextSize         = Theme.TextSizeSmall
            dropBtn.TextColor3       = Theme.Accent
            dropBtn.BorderSizePixel  = 0
            dropBtn.AutoButtonColor  = false
            dropBtn.ZIndex           = 7
            dropBtn.ClipsDescendants = false
            dropBtn.Parent           = ef
            Decorate(dropBtn, UDim.new(0,4), Theme.Border, 1)

            local execBtn = Instance.new("TextButton")
            execBtn.BackgroundColor3 = Theme.AccentDim
            execBtn.Size             = UDim2.new(0.30,0,0,26)
            execBtn.Position         = UDim2.new(0.68,0,0.5,-13)
            execBtn.Text             = btnLabel:upper()
            execBtn.Font             = Theme.FontMono
            execBtn.TextSize         = Theme.TextSizeSmall
            execBtn.TextColor3       = Theme.Background
            execBtn.BorderSizePixel  = 0
            execBtn.AutoButtonColor  = false
            execBtn.ZIndex           = 7
            execBtn.Parent           = ef
            Decorate(execBtn, UDim.new(0,4), Theme.Border, 1)

            -- GLOBAL LAYER dropdown list
            local listH = math.min(#choices, 6) * 28
            local listFrame = NewFrame({
                Color  = Theme.DropdownOverlay,
                Size   = UDim2.new(0, 100, 0, listH),
                Pos    = UDim2.new(0, 0, 0, 0),
                Z      = 1000,
                Clip   = true,
                Parent = GetDropdownContainer(),
            })
            listFrame.Visible = false
            Decorate(listFrame, UDim.new(0,4), Theme.Border, 1)

            local shadow = Instance.new("ImageLabel")
            shadow.BackgroundTransparency = 1
            shadow.Image = "rbxassetid://5554236805"
            shadow.ImageColor3 = Color3.new(0,0,0)
            shadow.ImageTransparency = 0.6
            shadow.ScaleType = Enum.ScaleType.Slice
            shadow.SliceCenter = Rect.new(23,23,277,277)
            shadow.Size = UDim2.new(1,20,1,20)
            shadow.Position = UDim2.new(0,-10,0,-10)
            shadow.ZIndex = 999
            shadow.Parent = listFrame

            local ll = Instance.new("UIListLayout")
            ll.SortOrder = Enum.SortOrder.LayoutOrder
            ll.Parent = listFrame

            local itemParent = listFrame
            if #choices > 6 then
                local sf = Instance.new("ScrollingFrame")
                sf.BackgroundTransparency = 1
                sf.Size = UDim2.new(1,0,1,0)
                sf.CanvasSize = UDim2.new(0,0,0,#choices*28)
                sf.ScrollBarThickness = 3
                sf.ScrollBarImageColor3 = Theme.AccentDim
                sf.BorderSizePixel = 0
                sf.ZIndex = 1001
                sf.Parent = listFrame
                ll.Parent = sf
                itemParent = sf
            end

            for i, choice in ipairs(choices) do
                local item = Instance.new("TextButton")
                item.BackgroundColor3 = Theme.DropdownOverlay
                item.Size = UDim2.new(1,0,0,28)
                item.Text = ("  %s"):format(choice)
                item.Font = Theme.FontMono
                item.TextSize = Theme.TextSizeSmall
                item.TextColor3 = Theme.TextSecondary
                item.TextXAlignment = Enum.TextXAlignment.Left
                item.BorderSizePixel = 0
                item.AutoButtonColor = false
                item.LayoutOrder = i
                item.ZIndex = 1002
                item.Parent = itemParent
                item.MouseEnter:Connect(function()
                    tw(item,{BackgroundColor3=Theme.SurfaceAlt,TextColor3=Theme.Accent})
                end)
                item.MouseLeave:Connect(function()
                    tw(item,{BackgroundColor3=Theme.DropdownOverlay,TextColor3=Theme.TextSecondary})
                end)
                item.MouseButton1Click:Connect(function()
                    selected = choice
                    dropBtn.Text = ("  %s  ▾"):format(selected)
                    open = false
                    listFrame.Visible = false
                end)
            end

            local ddEntry = { listFrame = listFrame, button = dropBtn, isOpen = false }
            table.insert(GlobalDropdowns, ddEntry)

            local open = false
            local function UpdateListPos()
                local absPos = dropBtn.AbsolutePosition
                local absSize = dropBtn.AbsoluteSize
                listFrame.Position = UDim2.new(0, absPos.X, 0, absPos.Y + absSize.Y + 4)
                listFrame.Size = UDim2.new(0, absSize.X, 0, listH)
            end

            dropBtn.MouseButton1Click:Connect(function()
                UpdateListPos()
                open = not open
                ddEntry.isOpen = open
                listFrame.Visible = open
                CloseAllDropdowns(listFrame)
                tw(dropBtn,{BackgroundColor3 = open and Theme.SurfaceAlt or Theme.Surface})
            end)

            local posConn = RunService.RenderStepped:Connect(function()
                if open then UpdateListPos() end
            end)

            execBtn.MouseEnter:Connect(function()
                tw(execBtn,{BackgroundColor3=Theme.Accent, TextColor3=Theme.Background})
            end)
            execBtn.MouseLeave:Connect(function()
                tw(execBtn,{BackgroundColor3=Theme.AccentDim, TextColor3=Theme.Background})
            end)
            execBtn.MouseButton1Down:Connect(function()
                tw(execBtn,{BackgroundColor3=Theme.SurfaceAlt, TextColor3=Theme.Accent})
            end)
            execBtn.MouseButton1Up:Connect(function()
                tw(execBtn,{BackgroundColor3=Theme.Accent, TextColor3=Theme.Background})
            end)
            execBtn.MouseButton1Click:Connect(function()
                pcall(cb, selected)
            end)

            local Combo = {}
            function Combo:SetSelection(v) selected = v; dropBtn.Text = ("  %s  ▾"):format(v) end
            function Combo:GetSelection() return selected end
            function Combo:SetButtonText(v) execBtn.Text = v:upper() end
            function Combo:Destroy()
                posConn:Disconnect()
                for i, entry in ipairs(GlobalDropdowns) do
                    if entry == ddEntry then table.remove(GlobalDropdowns, i); break end
                end
                listFrame:Destroy()
            end
            return Combo
        end

        ------------------------------------------------------------------
        -- NEW: Tab:CreateInputButton  (TextInput + Execute Button)
        ------------------------------------------------------------------
        function Tab:CreateInputButton(opts)
            opts = opts or {}
            local lbl        = opts.Label       or "Command"
            local ph         = opts.Placeholder or "enter..."
            local btnLabel   = opts.ButtonLabel or "RUN"
            local cb         = opts.Callback    or function() end
            local clearOnRun = opts.ClearOnRun  ~= false

            local ef = ElemFrame(38)

            NewLabel({
                Text   = lbl,
                Color  = Theme.TextPrimary,
                Font   = Theme.FontUI,
                Size2  = Theme.TextSizeBody,
                Size   = UDim2.new(0.28,0,1,0),
                Z      = 6,
                Parent = ef,
            })

            local box = Instance.new("TextBox")
            box.BackgroundColor3  = Theme.Surface
            box.Size              = UDim2.new(0.42,0,0,26)
            box.Position          = UDim2.new(0.29,0,0.5,-13)
            box.Text              = ""
            box.PlaceholderText   = ph
            box.PlaceholderColor3 = Theme.TextDisabled
            box.Font              = Theme.FontMono
            box.TextSize          = Theme.TextSizeSmall
            box.TextColor3        = Theme.Accent
            box.BorderSizePixel   = 0
            box.ZIndex            = 7
            box.ClearTextOnFocus  = false
            box.Parent            = ef
            Decorate(box, UDim.new(0,4), Theme.Border, 1)

            local p = Instance.new("UIPadding")
            p.PaddingLeft = UDim.new(0,6)
            p.Parent = box

            local execBtn = Instance.new("TextButton")
            execBtn.BackgroundColor3 = Theme.AccentDim
            execBtn.Size             = UDim2.new(0.26,0,0,26)
            execBtn.Position         = UDim2.new(0.73,0,0.5,-13)
            execBtn.Text             = btnLabel:upper()
            execBtn.Font             = Theme.FontMono
            execBtn.TextSize         = Theme.TextSizeSmall
            execBtn.TextColor3       = Theme.Background
            execBtn.BorderSizePixel  = 0
            execBtn.AutoButtonColor  = false
            execBtn.ZIndex           = 7
            execBtn.Parent           = ef
            Decorate(execBtn, UDim.new(0,4), Theme.Border, 1)

            local function Execute()
                local txt = box.Text
                pcall(cb, txt, true)
                if clearOnRun then box.Text = "" end
            end

            box.Focused:Connect(function() tw(box,{BackgroundColor3=Theme.SurfaceAlt}) end)
            box.FocusLost:Connect(function(enter)
                tw(box,{BackgroundColor3=Theme.Surface})
                if enter then Execute() end
                pcall(cb, box.Text, enter)
            end)

            execBtn.MouseEnter:Connect(function()
                tw(execBtn,{BackgroundColor3=Theme.Accent, TextColor3=Theme.Background})
            end)
            execBtn.MouseLeave:Connect(function()
                tw(execBtn,{BackgroundColor3=Theme.AccentDim, TextColor3=Theme.Background})
            end)
            execBtn.MouseButton1Down:Connect(function()
                tw(execBtn,{BackgroundColor3=Theme.SurfaceAlt, TextColor3=Theme.Accent})
            end)
            execBtn.MouseButton1Up:Connect(function()
                tw(execBtn,{BackgroundColor3=Theme.Accent, TextColor3=Theme.Background})
            end)
            execBtn.MouseButton1Click:Connect(Execute)

            local InpBtn = {}
            function InpBtn:Get() return box.Text end
            function InpBtn:Set(v) box.Text = tostring(v) end
            function InpBtn:SetButtonText(v) execBtn.Text = v:upper() end
            function InpBtn:Execute() Execute() end
            return InpBtn
        end

        ------------------------------------------------------------------
        -- NEW: Tab:CreateKeybind
        ------------------------------------------------------------------
        function Tab:CreateKeybind(opts)
            opts = opts or {}
            local lbl      = opts.Label    or "Keybind"
            local default  = opts.Default  or Enum.KeyCode.Unknown
            local cb       = opts.Callback or function() end
            local currentKey = default
            local listening = false

            local ef = ElemFrame(38)

            NewLabel({
                Text   = lbl,
                Color  = Theme.TextPrimary,
                Font   = Theme.FontUI,
                Size2  = Theme.TextSizeBody,
                Size   = UDim2.new(1,-80,1,0),
                Z      = 6,
                Parent = ef,
            })

            local keyBtn = Instance.new("TextButton")
            keyBtn.BackgroundColor3 = Theme.Surface
            keyBtn.Size             = UDim2.new(0,70,0,26)
            keyBtn.Position         = UDim2.new(1,-70,0.5,-13)
            keyBtn.Text             = currentKey.Name ~= "Unknown" and currentKey.Name or "[NONE]"
            keyBtn.Font             = Theme.FontMono
            keyBtn.TextSize         = Theme.TextSizeSmall
            keyBtn.TextColor3       = Theme.Accent
            keyBtn.BorderSizePixel  = 0
            keyBtn.AutoButtonColor  = false
            keyBtn.ZIndex           = 7
            keyBtn.Parent           = ef
            Decorate(keyBtn, UDim.new(0,4), Theme.Border, 1)

            local function SetKey(key)
                currentKey = key
                keyBtn.Text = key.Name ~= "Unknown" and key.Name or "[NONE]"
                tw(keyBtn, {BackgroundColor3=Theme.Surface, TextColor3=Theme.Accent})
                pcall(cb, currentKey)
            end

            keyBtn.MouseButton1Click:Connect(function()
                if listening then return end
                listening = true
                keyBtn.Text = "[PRESS KEY]"
                tw(keyBtn, {BackgroundColor3=Theme.SurfaceHover, TextColor3=Theme.TextPrimary})
            end)

            local inputConn = UserInputService.InputBegan:Connect(function(inp, gameProcessed)
                if not listening then return end
                if inp.UserInputType == Enum.UserInputType.Keyboard then
                    listening = false
                    SetKey(inp.KeyCode)
                elseif inp.UserInputType == Enum.UserInputType.MouseButton1
                    or inp.UserInputType == Enum.UserInputType.MouseButton2 then
                    listening = false
                    SetKey(Enum.KeyCode.Unknown)
                end
            end)

            keyBtn.MouseEnter:Connect(function()
                if not listening then tw(keyBtn,{BackgroundColor3=Theme.SurfaceAlt}) end
            end)
            keyBtn.MouseLeave:Connect(function()
                if not listening then tw(keyBtn,{BackgroundColor3=Theme.Surface}) end
            end)

            local KB = {}
            function KB:Set(key) SetKey(key) end
            function KB:Get() return currentKey end
            function KB:Destroy() inputConn:Disconnect() end
            return KB
        end

        ------------------------------------------------------------------
        -- NEW: Tab:CreateColorPicker
        ------------------------------------------------------------------
        function Tab:CreateColorPicker(opts)
            opts = opts or {}
            local lbl     = opts.Label    or "Color"
            local default = opts.Default  or Color3.fromRGB(0,255,100)
            local cb      = opts.Callback or function() end
            local current = default
            local open    = false

            local ef = ElemFrame(38)
            ef.ClipsDescendants = false

            NewLabel({
                Text   = lbl,
                Color  = Theme.TextPrimary,
                Font   = Theme.FontUI,
                Size2  = Theme.TextSizeBody,
                Size   = UDim2.new(1,-56,1,0),
                Z      = 6,
                Parent = ef,
            })

            local preview = NewFrame({
                Color  = current,
                Size   = UDim2.new(0,40,0,22),
                Pos    = UDim2.new(1,-40,0.5,-11),
                Z      = 7,
                Parent = ef,
            })
            Decorate(preview, UDim.new(0,4), Theme.Border, 1)

            local hit = Instance.new("TextButton")
            hit.BackgroundTransparency = 1
            hit.Size = UDim2.new(1,0,1,0)
            hit.Text = ""
            hit.ZIndex = 8
            hit.Parent = ef

            local pickerFrame = NewFrame({
                Color  = Theme.DropdownOverlay,
                Size   = UDim2.new(0, 200, 0, 140),
                Pos    = UDim2.new(0,0,0,0),
                Z      = 1000,
                Clip   = false,
                Parent = GetDropdownContainer(),
            })
            pickerFrame.Visible = false
            Decorate(pickerFrame, UDim.new(0,6), Theme.Border, 1)

            local shadow = Instance.new("ImageLabel")
            shadow.BackgroundTransparency = 1
            shadow.Image = "rbxassetid://5554236805"
            shadow.ImageColor3 = Color3.new(0,0,0)
            shadow.ImageTransparency = 0.6
            shadow.ScaleType = Enum.ScaleType.Slice
            shadow.SliceCenter = Rect.new(23,23,277,277)
            shadow.Size = UDim2.new(1,20,1,20)
            shadow.Position = UDim2.new(0,-10,0,-10)
            shadow.ZIndex = 999
            shadow.Parent = pickerFrame

            local hueLabel = NewLabel({
                Text="HUE", Color=Theme.TextSecondary, Font=Theme.FontMono, Size2=9,
                Size=UDim2.new(1,0,0,14), Z=1001, Parent=pickerFrame
            })
            local hueTrack = NewFrame({
                Color=Color3.fromRGB(30,30,30), Size=UDim2.new(1,-16,0,10), Pos=UDim2.new(0,8,0,16), Z=1001, Parent=pickerFrame
            })
            Decorate(hueTrack, UDim.new(0,3), Theme.BorderDim, 1)
            local hueFill = NewFrame({Color=Theme.Accent, Size=UDim2.new(0.5,0,1,0), Z=1002, Parent=hueTrack})
            Decorate(hueFill, UDim.new(0,3), false)

            local satLabel = NewLabel({
                Text="SAT", Color=Theme.TextSecondary, Font=Theme.FontMono, Size2=9,
                Size=UDim2.new(1,0,0,14), Pos=UDim2.new(0,0,0,32), Z=1001, Parent=pickerFrame
            })
            local satTrack = NewFrame({
                Color=Color3.fromRGB(30,30,30), Size=UDim2.new(1,-16,0,10), Pos=UDim2.new(0,8,0,48), Z=1001, Parent=pickerFrame
            })
            Decorate(satTrack, UDim.new(0,3), Theme.BorderDim, 1)
            local satFill = NewFrame({Color=Theme.Accent, Size=UDim2.new(0.8,0,1,0), Z=1002, Parent=satTrack})
            Decorate(satFill, UDim.new(0,3), false)

            local valLabel = NewLabel({
                Text="VAL", Color=Theme.TextSecondary, Font=Theme.FontMono, Size2=9,
                Size=UDim2.new(1,0,0,14), Pos=UDim2.new(0,0,0,64), Z=1001, Parent=pickerFrame
            })
            local valTrack = NewFrame({
                Color=Color3.fromRGB(30,30,30), Size=UDim2.new(1,-16,0,10), Pos=UDim2.new(0,8,0,80), Z=1001, Parent=pickerFrame
            })
            Decorate(valTrack, UDim.new(0,3), Theme.BorderDim, 1)
            local valFill = NewFrame({Color=Theme.Accent, Size=UDim2.new(0.6,0,1,0), Z=1002, Parent=valTrack})
            Decorate(valFill, UDim.new(0,3), false)

            local pickerPreview = NewFrame({
                Color=current, Size=UDim2.new(0.4,0,0,24), Pos=UDim2.new(0.05,0,0,100), Z=1001, Parent=pickerFrame
            })
            Decorate(pickerPreview, UDim.new(0,4), Theme.Border, 1)

            local okBtn = Instance.new("TextButton")
            okBtn.BackgroundColor3 = Theme.AccentDim
            okBtn.Size = UDim2.new(0.4,0,0,24)
            okBtn.Position = UDim2.new(0.55,0,0,100)
            okBtn.Text = "OK"
            okBtn.Font = Theme.FontMono
            okBtn.TextSize = 11
            okBtn.TextColor3 = Theme.Background
            okBtn.BorderSizePixel = 0
            okBtn.AutoButtonColor = false
            okBtn.ZIndex = 1001
            okBtn.Parent = pickerFrame
            Decorate(okBtn, UDim.new(0,4), Theme.Border, 1)

            local h, s, v = Color3.toHSV(current)

            local function UpdateFromHSV()
                current = Color3.fromHSV(h, s, v)
                preview.BackgroundColor3 = current
                pickerPreview.BackgroundColor3 = current
                hueFill.Size = UDim2.new(h,0,1,0)
                satFill.Size = UDim2.new(s,0,1,0)
                valFill.Size = UDim2.new(v,0,1,0)
                pcall(cb, current)
            end

            local function MakeSliderInteractive(track, fill, updateFunc)
                local dragging = false
                track.InputBegan:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = true
                        local pct = math.clamp((inp.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
                        updateFunc(pct)
                    end
                end)
                UserInputService.InputChanged:Connect(function(inp)
                    if not dragging then return end
                    if inp.UserInputType == Enum.UserInputType.MouseMovement then
                        local pct = math.clamp((inp.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
                        updateFunc(pct)
                    end
                end)
                UserInputService.InputEnded:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = false
                    end
                end)
            end

            MakeSliderInteractive(hueTrack, hueFill, function(pct) h = pct; UpdateFromHSV() end)
            MakeSliderInteractive(satTrack, satFill, function(pct) s = pct; UpdateFromHSV() end)
            MakeSliderInteractive(valTrack, valFill, function(pct) v = pct; UpdateFromHSV() end)

            local function UpdatePickerPos()
                local absPos = preview.AbsolutePosition
                local absSize = preview.AbsoluteSize
                pickerFrame.Position = UDim2.new(0, absPos.X - 160, 0, absPos.Y + absSize.Y + 4)
            end

            hit.MouseButton1Click:Connect(function()
                UpdatePickerPos()
                open = not open
                pickerFrame.Visible = open
                CloseAllDropdowns(nil)
            end)

            okBtn.MouseButton1Click:Connect(function()
                open = false
                pickerFrame.Visible = false
            end)

            okBtn.MouseEnter:Connect(function() tw(okBtn,{BackgroundColor3=Theme.Accent}) end)
            okBtn.MouseLeave:Connect(function() tw(okBtn,{BackgroundColor3=Theme.AccentDim}) end)

            local posConn = RunService.RenderStepped:Connect(function()
                if open then UpdatePickerPos() end
            end)

            local CP = {}
            function CP:Set(color)
                current = color
                h, s, v = Color3.toHSV(current)
                preview.BackgroundColor3 = current
                pickerPreview.BackgroundColor3 = current
                hueFill.Size = UDim2.new(h,0,1,0)
                satFill.Size = UDim2.new(s,0,1,0)
                valFill.Size = UDim2.new(v,0,1,0)
                pcall(cb, current)
            end
            function CP:Get() return current end
            function CP:Destroy()
                posConn:Disconnect()
                pickerFrame:Destroy()
            end
            return CP
        end

        ------------------------------------------------------------------
        -- NEW: Tab:CreateMultiDropdown  (Multi-select dropdown)
        ------------------------------------------------------------------
        function Tab:CreateMultiDropdown(opts)
            opts = opts or {}
            local lbl       = opts.Label    or "Multi Select"
            local choices   = opts.Options  or {}
            local cb        = opts.Callback or function() end
            local selected  = {}
            if opts.Default then
                for _, v in ipairs(opts.Default) do selected[v] = true end
            end
            local open = false

            local ef = ElemFrame(38)
            ef.ClipsDescendants = false

            NewLabel({
                Text   = lbl,
                Color  = Theme.TextPrimary,
                Font   = Theme.FontUI,
                Size2  = Theme.TextSizeBody,
                Size   = UDim2.new(0.44,0,1,0),
                Z      = 6,
                Parent = ef,
            })

            local function GetDisplayText()
                local count = 0
                for _ in pairs(selected) do count = count + 1 end
                if count == 0 then return "  NONE  ▾" end
                if count == 1 then
                    for k in pairs(selected) do return ("  %s  ▾"):format(k) end
                end
                return ("  %d SELECTED  ▾"):format(count)
            end

            local dropBtn = Instance.new("TextButton")
            dropBtn.BackgroundColor3 = Theme.Surface
            dropBtn.Size             = UDim2.new(0.53,0,0,26)
            dropBtn.Position         = UDim2.new(0.46,0,0.5,-13)
            dropBtn.Text             = GetDisplayText()
            dropBtn.Font             = Theme.FontMono
            dropBtn.TextSize         = Theme.TextSizeSmall
            dropBtn.TextColor3       = Theme.Accent
            dropBtn.BorderSizePixel  = 0
            dropBtn.AutoButtonColor  = false
            dropBtn.ZIndex           = 7
            dropBtn.ClipsDescendants = false
            dropBtn.Parent           = ef
            Decorate(dropBtn, UDim.new(0,4), Theme.Border, 1)

            local listH = math.min(#choices, 6) * 28
            local listFrame = NewFrame({
                Color  = Theme.DropdownOverlay,
                Size   = UDim2.new(0, 100, 0, listH),
                Pos    = UDim2.new(0, 0, 0, 0),
                Z      = 1000,
                Clip   = true,
                Parent = GetDropdownContainer(),
            })
            listFrame.Visible = false
            Decorate(listFrame, UDim.new(0,4), Theme.Border, 1)

            local shadow = Instance.new("ImageLabel")
            shadow.BackgroundTransparency = 1
            shadow.Image = "rbxassetid://5554236805"
            shadow.ImageColor3 = Color3.new(0,0,0)
            shadow.ImageTransparency = 0.6
            shadow.ScaleType = Enum.ScaleType.Slice
            shadow.SliceCenter = Rect.new(23,23,277,277)
            shadow.Size = UDim2.new(1,20,1,20)
            shadow.Position = UDim2.new(0,-10,0,-10)
            shadow.ZIndex = 999
            shadow.Parent = listFrame

            local ll = Instance.new("UIListLayout")
            ll.SortOrder = Enum.SortOrder.LayoutOrder
            ll.Parent = listFrame

            local itemParent = listFrame
            if #choices > 6 then
                local sf = Instance.new("ScrollingFrame")
                sf.BackgroundTransparency = 1
                sf.Size = UDim2.new(1,0,1,0)
                sf.CanvasSize = UDim2.new(0,0,0,#choices*28)
                sf.ScrollBarThickness = 3
                sf.ScrollBarImageColor3 = Theme.AccentDim
                sf.BorderSizePixel = 0
                sf.ZIndex = 1001
                sf.Parent = listFrame
                ll.Parent = sf
                itemParent = sf
            end

            local itemButtons = {}
            for i, choice in ipairs(choices) do
                local item = Instance.new("TextButton")
                item.BackgroundColor3 = Theme.DropdownOverlay
                item.Size = UDim2.new(1,0,0,28)
                item.Text = ("  %s"):format(choice)
                item.Font = Theme.FontMono
                item.TextSize = Theme.TextSizeSmall
                item.TextColor3 = selected[choice] and Theme.Accent or Theme.TextSecondary
                item.TextXAlignment = Enum.TextXAlignment.Left
                item.BorderSizePixel = 0
                item.AutoButtonColor = false
                item.LayoutOrder = i
                item.ZIndex = 1002
                item.Parent = itemParent

                local check = Instance.new("TextLabel")
                check.BackgroundTransparency = 1
                check.Size = UDim2.new(0,20,1,0)
                check.Position = UDim2.new(1,-20,0,0)
                check.Text = selected[choice] and "✓" or ""
                check.Font = Theme.FontBold
                check.TextSize = 12
                check.TextColor3 = Theme.Accent
                check.ZIndex = 1003
                check.Parent = item

                item.MouseEnter:Connect(function()
                    tw(item,{BackgroundColor3=Theme.SurfaceAlt})
                end)
                item.MouseLeave:Connect(function()
                    tw(item,{BackgroundColor3=Theme.DropdownOverlay})
                end)
                item.MouseButton1Click:Connect(function()
                    selected[choice] = not selected[choice]
                    if not selected[choice] then selected[choice] = nil end
                    item.TextColor3 = selected[choice] and Theme.Accent or Theme.TextSecondary
                    check.Text = selected[choice] and "✓" or ""
                    dropBtn.Text = GetDisplayText()

                    local result = {}
                    for k in pairs(selected) do table.insert(result, k) end
                    pcall(cb, result)
                end)

                itemButtons[choice] = item
            end

            local ddEntry = { listFrame = listFrame, button = dropBtn, isOpen = false }
            table.insert(GlobalDropdowns, ddEntry)

            local function UpdateListPos()
                local absPos = dropBtn.AbsolutePosition
                local absSize = dropBtn.AbsoluteSize
                listFrame.Position = UDim2.new(0, absPos.X, 0, absPos.Y + absSize.Y + 4)
                listFrame.Size = UDim2.new(0, absSize.X, 0, listH)
            end

            dropBtn.MouseButton1Click:Connect(function()
                UpdateListPos()
                open = not open
                ddEntry.isOpen = open
                listFrame.Visible = open
                CloseAllDropdowns(listFrame)
                tw(dropBtn,{BackgroundColor3 = open and Theme.SurfaceAlt or Theme.Surface})
            end)
            dropBtn.MouseEnter:Connect(function()
                if not open then tw(dropBtn,{BackgroundColor3=Theme.SurfaceAlt}) end
            end)
            dropBtn.MouseLeave:Connect(function()
                if not open then tw(dropBtn,{BackgroundColor3=Theme.Surface}) end
            end)

            local posConn = RunService.RenderStepped:Connect(function()
                if open then UpdateListPos() end
            end)

            local MD = {}
            function MD:Set(vals)
                selected = {}
                for _, v in ipairs(vals) do selected[v] = true end
                dropBtn.Text = GetDisplayText()
                for choice, btn in pairs(itemButtons) do
                    btn.TextColor3 = selected[choice] and Theme.Accent or Theme.TextSecondary
                    for _, child in ipairs(btn:GetChildren()) do
                        if child:IsA("TextLabel") then child.Text = selected[choice] and "✓" or "" end
                    end
                end
                local result = {}
                for k in pairs(selected) do table.insert(result, k) end
                pcall(cb, result)
            end
            function MD:Get()
                local result = {}
                for k in pairs(selected) do table.insert(result, k) end
                return result
            end
            function MD:Destroy()
                posConn:Disconnect()
                for i, entry in ipairs(GlobalDropdowns) do
                    if entry == ddEntry then table.remove(GlobalDropdowns, i); break end
                end
                listFrame:Destroy()
            end
            return MD
        end

        ------------------------------------------------------------------
        -- NEW: Tab:CreateProgressBar
        ------------------------------------------------------------------
        function Tab:CreateProgressBar(opts)
            opts = opts or {}
            local lbl   = opts.Label or "Progress"
            local val   = math.clamp(opts.Value or 0, 0, 100)
            local showPct = opts.ShowPercent ~= false

            local ef = ElemFrame(40)

            NewLabel({
                Text   = lbl,
                Color  = Theme.TextPrimary,
                Font   = Theme.FontUI,
                Size2  = Theme.TextSizeBody,
                Size   = UDim2.new(1,0,0,18),
                Z      = 6,
                Parent = ef,
            })

            local track = NewFrame({
                Color  = Theme.SliderTrack,
                Size   = UDim2.new(1,0,0,10),
                Pos    = UDim2.new(0,0,0,22),
                Z      = 6,
                Parent = ef,
            })
            Decorate(track, UDim.new(0,3), Theme.BorderDim, 1)

            local fill = NewFrame({
                Color  = Theme.Accent,
                Size   = UDim2.new(val/100, 0, 1, 0),
                Z      = 7,
                Parent = track,
            })
            Decorate(fill, UDim.new(0,3), false)

            local pctLbl = nil
            if showPct then
                pctLbl = NewLabel({
                    Text   = tostring(math.floor(val)) .. "%",
                    Color  = Theme.TextSecondary,
                    Font   = Theme.FontMono,
                    Size2  = 9,
                    AlignX = Enum.TextXAlignment.Right,
                    Size   = UDim2.new(1,0,0,18),
                    Z      = 6,
                    Parent = ef,
                })
            end

            local PB = {}
            function PB:Set(v)
                val = math.clamp(v, 0, 100)
                tw(fill, {Size = UDim2.new(val/100, 0, 1, 0)})
                if pctLbl then pctLbl.Text = tostring(math.floor(val)) .. "%" end
            end
            function PB:Get() return val end
            return PB
        end

        return Tab
    end

    tw(win, {Size = UDim2.new(0,W,0,H)}, Theme.TweenSlow)
    return Window
end

function Library:SetTheme(overrides)
    for k,v in pairs(overrides) do
        if Theme[k] ~= nil then Theme[k] = v end
    end
end

return Library
