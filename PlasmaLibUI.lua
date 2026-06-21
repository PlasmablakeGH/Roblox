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
    Version      :  1.1.0  (tab switching fixed)

    USAGE:
        local Library = loadstring(game:HttpGet(RAW_URL, true))()
        local Window  = Library:CreateWindow({ Title = "My Tool", IconId = "rbxassetid://7072706620" })
        local Tab     = Window:CreateTab("Main")
        Tab:CreateButton({ Label = "Click", Callback = function() print("!") end })
        Tab:CreateToggle({ Label = "ESP",   Default = false, Callback = function(v) print(v) end })
        Tab:CreateSlider({ Label = "Speed", Min = 16, Max = 250, Default = 16, Callback = function(v) print(v) end })
        Tab:CreateDropdown({ Label = "Team", Options = {"Red","Blue"}, Callback = function(v) print(v) end })
        Tab:CreateLabel("PlasmaLibUI v1.1")
--]]

------------------------------------------------------------------------
-- Services
------------------------------------------------------------------------
local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

------------------------------------------------------------------------
-- Theme  (edit here to reskin everything)
------------------------------------------------------------------------
local Theme = {
    Background   = Color3.fromRGB(8,   12,  8),
    Surface      = Color3.fromRGB(12,  20,  12),
    SurfaceAlt   = Color3.fromRGB(18,  30,  18),
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
}

------------------------------------------------------------------------
-- Internal helpers
------------------------------------------------------------------------
local function tw(obj, props, info)
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
    l.RichText     = p.Rich     or falseSYS
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

    -- ── ScreenGui ────────────────────────────────────────────────────
    local sg = Instance.new("ScreenGui")
    sg.Name             = "PlasmaLibUI_" .. TITLE:gsub("%s","")
    sg.ResetOnSpawn     = false
    sg.ZIndexBehavior   = Enum.ZIndexBehavior.Sibling
    sg.IgnoreGuiInset   = true
    sg.DisplayOrder     = 999
    sg.Parent           = GuiParent()

    -- ── Window frame ─────────────────────────────────────────────────
    local win = NewFrame({
        Name   = "Window",
        Color  = Theme.Background,
        Size   = UDim2.new(0, W, 0, 0),     -- starts at 0, animated open
        Pos    = UDim2.new(0.5,-W/2, 0.5,-H/2),
        Clip   = true,
        Z      = 2,
        Parent = sg,
    })
    Decorate(win, UDim.new(0,0), Theme.Border, 1)
    AddScanlines(win)

    -- Top accent stripe
    NewFrame({ Color=Theme.Accent, Size=UDim2.new(1,0,0,2), Z=6, Parent=win })

    -- ── Title bar ────────────────────────────────────────────────────
    local titleBar = NewFrame({
        Name   = "TitleBar",
        Color  = Theme.TitleBar,
        Size   = UDim2.new(1,0,0,38),
        Pos    = UDim2.new(0,0,0,2),
        Z      = 5,
        Parent = win,
    })

    -- Icon
    local iconImg = Instance.new("ImageLabel")
    iconImg.BackgroundTransparency = 1
    iconImg.Size      = UDim2.new(0,22,0,22)
    iconImg.Position  = UDim2.new(0,8,0.5,-11)
    iconImg.Image     = ICON
    iconImg.ImageColor3 = Color3.fromRGB(0, 255, 100)
    iconImg.ZIndex    = 7
    iconImg.Parent    = titleBar

    -- Title text
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

 

    -- Close button
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

    -- ── Tab button bar ───────────────────────────────────────────────
    -- Sits directly below the title bar (y = 40)
    local tabBar = NewFrame({
        Name   = "TabBar",
        Color  = Theme.TitleBar,
        Size   = UDim2.new(1,0,0,30),
        Pos    = UDim2.new(0,0,0,40),
        Z      = 5,
        Parent = win,
    })
    -- Horizontal list layout for tab buttons
    local tabBarList = Instance.new("UIListLayout")
    tabBarList.FillDirection = Enum.FillDirection.Horizontal
    tabBarList.HorizontalAlignment = Enum.HorizontalAlignment.Center
    tabBarList.SortOrder     = Enum.SortOrder.LayoutOrder
    tabBarList.Padding       = UDim.new(0, 2)
    tabBarList.Parent        = tabBar

    -- Left padding so buttons don't touch the edge
    local tabBarPad = Instance.new("UIPadding")
    tabBarPad.PaddingLeft = UDim.new(0, 4)
    tabBarPad.Parent      = tabBar

 

    -- ── Content area ─────────────────────────────────────────────────
    -- Starts at y=71  (titleBar 38 + accent 2 + tabBar 30 + divider 1)
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

    -- ── Status bar ───────────────────────────────────────────────────
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

    ------------------------------------------------------------------
    -- Tab registry  (shared across all tabs in this window)
    -- Each entry: { btn = TextButton, page = ScrollingFrame }
    ------------------------------------------------------------------
    local tabs       = {}   -- array, filled as CreateTab is called
    local activeIdx  = 0    -- which tab is currently shown

    -- This function always walks the live `tabs` array — no stale captures
    local function SetActiveTab(idx)
        if activeIdx == idx then return end
        activeIdx = idx
        for i, entry in ipairs(tabs) do
            if i == idx then
                -- Active style
                tw(entry.btn, {
                    BackgroundColor3 = Theme.TabActive,
                    TextColor3       = Theme.Background,
                })
                entry.page.Visible = true
            else
                -- Inactive style
                tw(entry.btn, {
                    BackgroundColor3 = Theme.TabInactive,
                    TextColor3       = Theme.TextSecondary,
                })
                entry.page.Visible = false
            end
        end
    end

    ------------------------------------------------------------------
    -- Window public API
    ------------------------------------------------------------------
    local Window = {}

    function Window:SetIcon(id)
        iconImg.Image = id
    end

    ----------------------------------------------------------------
    -- Window:CreateTab(name)
    ----------------------------------------------------------------
    function Window:CreateTab(name)
        name = tostring(name or "Tab")

        ---- Tab button ------------------------------------------------
        local btn = Instance.new("TextButton")
        btn.Name             = "TabBtn_" .. name
        btn.BackgroundColor3 = Theme.TabInactive
        btn.Size             = UDim2.new(0, 86, 1, -6)       -- width fixed, height fills bar minus padding
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

        ---- Scrollable page -------------------------------------------
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
        page.Visible                = false          -- hidden until activated
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

        ---- Register the tab BEFORE connecting the button click -------
        local myIndex = #tabs + 1
        tabs[myIndex] = { btn = btn, page = page }

        -- If this is the very first tab, activate it immediately
        if myIndex == 1 then
            SetActiveTab(1)
        end

        ---- Button interactions ---------------------------------------
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

        ---- Element helpers (scoped to this tab's page) ---------------
        local elementOrder = 0
        local function NextOrder()
            elementOrder = elementOrder + 1
            return elementOrder
        end

        local function ElemFrame(h)
            local ef = NewFrame({
                Color  = Theme.SurfaceAlt,
                Size   = UDim2.new(1,0,0, h or 38),
                Z      = 5,
                Name   = "Element",
                Parent = page,
            })
            ef.LayoutOrder = NextOrder()
            Decorate(ef, UDim.new(0,4), Theme.BorderDim, 1)
            local pad = Instance.new("UIPadding")
            pad.PaddingLeft  = UDim.new(0,10)
            pad.PaddingRight = UDim.new(0,10)
            pad.Parent       = ef
            return ef
        end

        ---- Tab object ------------------------------------------------
        local Tab = {}

        ------------------------------------------------------------------
        -- Tab:CreateLabel
        ------------------------------------------------------------------
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

        ------------------------------------------------------------------
        -- Tab:CreateSection
        ------------------------------------------------------------------
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

        ------------------------------------------------------------------
        -- Tab:CreateButton
        ------------------------------------------------------------------
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

        ------------------------------------------------------------------
        -- Tab:CreateToggle
        ------------------------------------------------------------------
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

        ------------------------------------------------------------------
        -- Tab:CreateSlider
        ------------------------------------------------------------------
        function Tab:CreateSlider(opts)
            opts = opts or {}
            local lbl  = opts.Label    or "Slider"
            local min  = opts.Min      or 0
            local max  = opts.Max      or 100
            local step = opts.Step     or 1
            local val  = math.clamp(opts.Default or min, min, max)
            local cb   = opts.Callback or function() end

            local ef = ElemFrame(54)

            -- top row: name + current value
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

            -- bottom row: track
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
                if inp.UserInputType == Enum.UserInputType.MouseMovement
                or inp.UserInputType == Enum.UserInputType.Touch then
                    Recalc(inp.Position.X)
                end
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
        -- Tab:CreateDropdown (Overhauled & Layer-Fixed)
        ------------------------------------------------------------------
      ------------------------------------------------------------------
        -- Tab:CreateDropdown (Overhauled, Layer-Fixed & Dynamic)
        ------------------------------------------------------------------
        ------------------------------------------------------------------
        -- Tab:CreateDropdown (Overhauled, Layer-Fixed & Dynamic)
        ------------------------------------------------------------------
        function Tab:CreateDropdown(opts)
            opts = opts or {}
            local lbl      = opts.Label    or "Dropdown"
            local choices  = opts.Options  or {}
            local cb       = opts.Callback or function() end
            local selected = opts.Default  or choices[1] or "None"
            local open     = false

            local ef = ElemFrame(38)
            ef.ClipsDescendants = false -- Keep false so selection box can overflow safely

            NewLabel({
                Text   = lbl,
                Color  = Theme.TextPrimary,
                Font   = Theme.FontUI,
                Size2  = Theme.TextSizeBody,
                Size   = UDim2.new(0.44, 0, 1, 0),
                Z      = 6,
                Parent = ef,
            })

            local dropBtn = Instance.new("TextButton")
            dropBtn.BackgroundColor3 = Theme.Surface
            dropBtn.Size             = UDim2.new(0.53, 0, 0, 26)
            dropBtn.Position         = UDim2.new(0.46, 0, 0.5, -13)
            dropBtn.Text             = ("  %s  ▾"):format(selected)
            dropBtn.Font             = Theme.FontMono
            dropBtn.TextSize         = Theme.TextSizeSmall
            dropBtn.TextColor3       = Theme.Accent
            dropBtn.BorderSizePixel  = 0
            dropBtn.AutoButtonColor  = false
            dropBtn.ZIndex           = 7
            dropBtn.ClipsDescendants = false
            dropBtn.Parent           = ef
            Decorate(dropBtn, UDim.new(0, 4), Theme.Border, 1)

            -- Constants for dropdown sizing
            local maxDisplayed = 6
            local itemHeight = 28

            -- Base dropdown pane container
            local listFrame = NewFrame({
                Color  = Theme.TitleBar,
                Size   = UDim2.new(1, 0, 0, 0),
                Pos    = UDim2.new(0, 0, 1, 4),
                Z      = 22,
                Clip   = true,
                Parent = dropBtn,
            })
            listFrame.Visible = false
            Decorate(listFrame, UDim.new(0, 4), Theme.Border, 1)

            -- Unified ScrollingFrame (auto-handles both small and large lists)
            local itemContainer = Instance.new("ScrollingFrame")
            itemContainer.BackgroundTransparency = 1
            itemContainer.Size                   = UDim2.new(1, 0, 1, 0)
            itemContainer.ScrollBarThickness     = 3
            itemContainer.ScrollBarImageColor3   = Theme.AccentDim
            itemContainer.BorderSizePixel        = 0
            itemContainer.ZIndex                 = 23
            itemContainer.Parent                 = listFrame

            local ll = Instance.new("UIListLayout")
            ll.SortOrder = Enum.SortOrder.LayoutOrder
            ll.Parent    = itemContainer

            -- Animation Helpers
            local function Close()
                open = false
                ef.ZIndex = 5 -- FIX: Revert the row's ZIndex back to normal
                tw(listFrame, {Size = UDim2.new(1, 0, 0, 0)})
                -- Wait for tween to finish before hiding to prevent visual snapping
                task.delay(0.16, function() 
                    if not open then listFrame.Visible = false end 
                end)
            end

            local function Open()
                open = true
                ef.ZIndex = 50 -- FIX: Blast the row's ZIndex to 50 so it renders over everything else
                listFrame.Visible = true
                
                local count = #choices
                local visibleCount = math.min(count, maxDisplayed)
                local targetHeight = visibleCount * itemHeight
                
                itemContainer.CanvasSize = UDim2.new(0, 0, 0, count * itemHeight)
                tw(listFrame, {Size = UDim2.new(1, 0, 0, targetHeight)})
            end

            dropBtn.MouseButton1Click:Connect(function()
                if open then Close() else Open() end
            end)

            -- Choice Generator
            local function BuildChoices()
                -- Clear existing
                for _, child in ipairs(itemContainer:GetChildren()) do
                    if child:IsA("TextButton") then child:Destroy() end
                end

                for i, choice in ipairs(choices) do
                    local cBtn = Instance.new("TextButton")
                    cBtn.BackgroundColor3 = Theme.TitleBar
                    cBtn.Size             = UDim2.new(1, 0, 0, itemHeight)
                    cBtn.Text             = "  " .. tostring(choice)
                    cBtn.Font             = Theme.FontMono
                    cBtn.TextSize         = Theme.TextSizeSmall
                    cBtn.TextColor3       = Theme.TextSecondary
                    cBtn.TextXAlignment   = Enum.TextXAlignment.Left
                    cBtn.BorderSizePixel  = 0
                    cBtn.AutoButtonColor  = false
                    cBtn.LayoutOrder      = i
                    cBtn.ZIndex           = 24
                    cBtn.Parent           = itemContainer

                    cBtn.MouseEnter:Connect(function()
                        tw(cBtn, {BackgroundColor3 = Theme.Surface, TextColor3 = Theme.TextPrimary})
                    end)
                    cBtn.MouseLeave:Connect(function()
                        tw(cBtn, {BackgroundColor3 = Theme.TitleBar, TextColor3 = Theme.TextSecondary})
                    end)
                    cBtn.MouseButton1Click:Connect(function()
                        selected = choice
                        dropBtn.Text = ("  %s  ▾"):format(tostring(selected))
                        pcall(cb, selected)
                        Close()
                    end)
                end
            end

            BuildChoices()

            local Dropdown = {}
            function Dropdown:Set(val)
                selected = val
                dropBtn.Text = ("  %s  ▾"):format(tostring(selected))
                pcall(cb, selected)
            end
            function Dropdown:Refresh(newChoices)
                choices = newChoices or {}
                BuildChoices()
            end

            return Dropdown
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

        return Tab
    end  -- CreateTab

    -- Animate open
    tw(win, {Size = UDim2.new(0,W,0,H)}, Theme.TweenSlow)

    return Window
end  -- CreateWindow

------------------------------------------------------------------------
-- Library:SetTheme  (runtime palette override)
------------------------------------------------------------------------
function Library:SetTheme(overrides)
    for k,v in pairs(overrides) do
        if Theme[k] ~= nil then Theme[k] = v end
    end
end

------------------------------------------------------------------------
-- Return so loadstring callers can capture it:
--   local Lib = loadstring(game:HttpGet(URL, true))()
------------------------------------------------------------------------
return Library
