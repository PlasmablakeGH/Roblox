--[[
    ██████╗ ██╗      █████╗ ███████╗███╗   ███╗ █████╗ 
    ██╔══██╗██║     ██╔══██╗██╔════╝████╗ ████║██╔══██╗
    ██████╔╝██║     ███████║███████╗██╔████╔██║███████║
    ██╔═══╝ ██║     ██╔══██║╚════██║██║╚██╔╝██║██╔══██║
    ██║     ███████╗██║  ██║███████║██║ ╚═╝ ██║██║  ██║
    ╚═╝     ╚══════╝╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝╚═╝  ╚═╝

    PlasmaLibUI  –  Modular Roblox Luau UI Library
    Theme        :  Hacker / Sci-Fi  (green-on-black)
    Version      :  2.0.0

    CHANGELOG v2.0:
      BUG FIXES
        • Dropdown z-layering: list now portals to ScreenGui root — never
          clipped by ScrollingFrame or sibling elements
        • `falseSYS` typo in NewLabel corrected to `false`
        • Slider drag state isolated per-instance (was already ok but now
          explicitly documented via named upvalue pattern)
        • Close tween now collapses to actual zero height, not stale H
        • Empty-option Dropdown no longer errors on Refresh
        • UIListLayout LayoutOrder gaps on rapid tab creation fixed

      NEW ELEMENTS
        • Tab:CreateParagraph(opts)   – multi-line description block
        • Tab:CreateKeybind(opts)     – press a key to rebind; returns :Get()/:Set()
        • Tab:CreateColorPicker(opts) – HSV wheel + hex box; returns :Get()/:Set()
        • Tab:CreateDivider(label?)   – thin separator with optional centred text
        • Tab:CreateSearchBox(opts)   – filter list that fires callback on change

      NEW WINDOW API
        • Window:Notify(opts)         – toast notification (title, body, duration, type)
        • Window:SetTab(name)         – programmatically switch to a tab by name
        • Window:SetStatus(text)      – update status-bar text at runtime
        • Window:Minimize() / :Restore()

      QUALITY-OF-LIFE
        • Scanlines rewritten: single canvas with gradient, no 80-frame spam
        • Title bar shows live clock (HH:MM:SS)
        • Notification stack (up to 5 simultaneous toasts, auto-dismiss)
        • Theme accent stripe now pulses subtly on open
        • All tweens respect a global `Library.AnimationsEnabled` flag

    USAGE:
        local Library = loadstring(game:HttpGet(RAW_URL, true))()
        local Window  = Library:CreateWindow({ Title = "My Tool" })
        local Tab     = Window:CreateTab("Main")
        Tab:CreateButton({ Label = "Fire", Callback = function() end })
        Tab:CreateToggle({ Label = "ESP", Default = false, Callback = function(v) end })
        Tab:CreateSlider({ Label = "Speed", Min = 16, Max = 250, Default = 16, Callback = function(v) end })
        Tab:CreateDropdown({ Label = "Team", Options = {"Red","Blue"}, Callback = function(v) end })
        Tab:CreateKeybind({ Label = "Trigger", Default = Enum.KeyCode.E, Callback = function(k) end })
        Tab:CreateColorPicker({ Label = "Color", Default = Color3.fromRGB(0,255,100), Callback = function(c) end })
        Window:Notify({ Title = "Ready", Body = "Tool loaded.", Duration = 4 })
--]]

------------------------------------------------------------------------
-- Services
------------------------------------------------------------------------
local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local RunService       = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

------------------------------------------------------------------------
-- Library root
------------------------------------------------------------------------
local Library = {}
Library.__index = Library
Library.AnimationsEnabled = true   -- set false to skip all tweens

------------------------------------------------------------------------
-- Theme
------------------------------------------------------------------------
local Theme = {
    Background    = Color3.fromRGB(7,   11,  7),
    Surface       = Color3.fromRGB(11,  18,  11),
    SurfaceAlt    = Color3.fromRGB(16,  28,  16),
    SurfaceHover  = Color3.fromRGB(22,  38,  22),
    Border        = Color3.fromRGB(0,   200, 80),
    BorderDim     = Color3.fromRGB(0,   70,  28),
    Accent        = Color3.fromRGB(0,   255, 100),
    AccentDim     = Color3.fromRGB(0,   130, 52),
    AccentGlow    = Color3.fromRGB(0,   255, 120),
    TextPrimary   = Color3.fromRGB(0,   255, 100),
    TextSecondary = Color3.fromRGB(0,   170, 65),
    TextMuted     = Color3.fromRGB(0,   90,  35),
    TextDisabled  = Color3.fromRGB(0,   60,  24),
    Danger        = Color3.fromRGB(255, 55,  55),
    DangerDim     = Color3.fromRGB(80,  12,  12),
    Warning       = Color3.fromRGB(255, 185, 0),
    Success       = Color3.fromRGB(0,   255, 100),
    Info          = Color3.fromRGB(0,   180, 255),
    SliderFill    = Color3.fromRGB(0,   220, 90),
    SliderTrack   = Color3.fromRGB(14,  32,  14),
    ToggleOn      = Color3.fromRGB(0,   210, 85),
    ToggleOff     = Color3.fromRGB(18,  38,  18),
    ToggleKnob    = Color3.fromRGB(200, 255, 210),
    TabActive     = Color3.fromRGB(0,   195, 75),
    TabInactive   = Color3.fromRGB(0,   40,  16),
    TitleBar      = Color3.fromRGB(5,   14,  5),
    Scanline      = Color3.fromRGB(0,   255, 100),

    CornerRadius    = UDim.new(0, 5),
    BorderThickness = 1,
    FontMono        = Enum.Font.Code,
    FontUI          = Enum.Font.GothamMedium,
    FontBold        = Enum.Font.GothamBold,
    TextSizeTitle   = 15,
    TextSizeBody    = 13,
    TextSizeSmall   = 11,

    Tween     = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    TweenMed  = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    TweenSlow = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    TweenBounce = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
}

------------------------------------------------------------------------
-- Runtime theme override
------------------------------------------------------------------------
function Library:SetTheme(overrides)
    for k, v in pairs(overrides) do
        if Theme[k] ~= nil then Theme[k] = v end
    end
end

------------------------------------------------------------------------
-- Internal helpers
------------------------------------------------------------------------
local function tw(obj, props, info)
    if not Library.AnimationsEnabled then
        for k, v in pairs(props) do
            pcall(function() obj[k] = v end)
        end
        return
    end
    TweenService:Create(obj, info or Theme.Tween, props):Play()
end

local function Decorate(f, radius, strokeCol, strokeThick)
    local c  = Instance.new("UICorner")
    c.CornerRadius = radius or Theme.CornerRadius
    c.Parent = f
    if strokeCol ~= false then
        local s = Instance.new("UIStroke")
        s.Color           = strokeCol or Theme.BorderDim
        s.Thickness       = strokeThick or Theme.BorderThickness
        s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        s.Parent          = f
    end
end

-- FIX: was `false` written as `falseSYS` — corrected
local function NewLabel(p)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.TextColor3    = p.Color  or Theme.TextPrimary
    l.Font          = p.Font   or Theme.FontUI
    l.TextSize      = p.Size2  or Theme.TextSizeBody
    l.Text          = p.Text   or ""
    l.TextXAlignment = p.AlignX or Enum.TextXAlignment.Left
    l.TextYAlignment = Enum.TextYAlignment.Center
    l.TextTruncate  = Enum.TextTruncate.AtEnd
    l.Size          = p.Size   or UDim2.new(1,0,1,0)
    l.Position      = p.Pos    or UDim2.new(0,0,0,0)
    l.ZIndex        = p.Z      or 5
    l.RichText      = p.Rich   or false   -- BUG FIX: was `falseSYS`
    l.Parent        = p.Parent
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

-- Lightweight scanline overlay using a single gradient frame instead of 80 children
local function AddScanlines(parent)
    local over = Instance.new("Frame")
    over.BackgroundTransparency = 1
    over.Size          = UDim2.new(1,0,1,0)
    over.ZIndex        = 60
    over.BorderSizePixel = 0
    over.Name          = "Scanlines"
    over.Parent        = parent

    -- Two repeating stripe frames using UIGradient with transparency trick
    -- Much cheaper: 2 frames total vs 80
    local stripe = Instance.new("Frame")
    stripe.BackgroundColor3       = Theme.Scanline
    stripe.BackgroundTransparency = 0.94
    stripe.BorderSizePixel        = 0
    stripe.Size                   = UDim2.new(1,0,1,0)
    stripe.ZIndex                 = 61
    stripe.Parent                 = over

    local grad = Instance.new("UIGradient")
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0,   Color3.new(0,0,0)),
        ColorSequenceKeypoint.new(0.49, Color3.new(0,0,0)),
        ColorSequenceKeypoint.new(0.50, Color3.new(1,1,1)),
        ColorSequenceKeypoint.new(1,   Color3.new(1,1,1)),
    })
    grad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0,    1),
        NumberSequenceKeypoint.new(0.49, 1),
        NumberSequenceKeypoint.new(0.50, 0),
        NumberSequenceKeypoint.new(1,    0),
    })
    grad.Rotation = 90
    grad.Parent   = stripe
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
-- Draggable (UIS-only, no RunService)
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
-- Notification stack manager (module-level, shared across windows)
------------------------------------------------------------------------
local NotifyStack    = {}
local NOTIFY_W       = 280
local NOTIFY_H_BASE  = 60
local NOTIFY_PAD     = 8
local NOTIFY_MAX     = 5

local function PushNotify(sg, opts)
    opts = opts or {}
    local title    = opts.Title    or "Notice"
    local body     = opts.Body     or ""
    local duration = opts.Duration or 4
    local ntype    = opts.Type     or "info"   -- "info" | "success" | "warning" | "danger"

    local accentCol = ({
        info    = Theme.Info,
        success = Theme.Success,
        warning = Theme.Warning,
        danger  = Theme.Danger,
    })[ntype] or Theme.Info

    -- Prune dismissed entries
    for i = #NotifyStack, 1, -1 do
        if not NotifyStack[i].active then
            table.remove(NotifyStack, i)
        end
    end
    if #NotifyStack >= NOTIFY_MAX then
        -- Dismiss oldest
        local oldest = NotifyStack[1]
        oldest.dismiss()
    end

    local H = NOTIFY_H_BASE + (body ~= "" and 18 or 0)

    local nFrame = NewFrame({
        Color  = Theme.TitleBar,
        Size   = UDim2.new(0, NOTIFY_W, 0, H),
        Pos    = UDim2.new(1, NOTIFY_W + 10, 1, -80),   -- off-screen right
        Z      = 200,
        Clip   = false,
        Name   = "Notification",
        Parent = sg,
    })
    Decorate(nFrame, UDim.new(0,6), accentCol, 1)

    -- Left accent bar
    local accentBar = NewFrame({
        Color  = accentCol,
        Size   = UDim2.new(0, 3, 1, 0),
        Z      = 201,
        Parent = nFrame,
    })
    Instance.new("UICorner").Parent = accentBar

    -- Icon
    local iconMap = { info="ℹ", success="✓", warning="⚠", danger="✕" }
    local iconLbl = NewLabel({
        Text   = iconMap[ntype] or "ℹ",
        Color  = accentCol,
        Font   = Theme.FontBold,
        Size2  = 16,
        Size   = UDim2.new(0,28,0,H),
        Pos    = UDim2.new(0,6,0,0),
        AlignX = Enum.TextXAlignment.Center,
        Z      = 202,
        Parent = nFrame,
    })

    -- Title
    NewLabel({
        Text   = title,
        Color  = Theme.TextPrimary,
        Font   = Theme.FontBold,
        Size2  = 13,
        Size   = UDim2.new(1,-42,0,22),
        Pos    = UDim2.new(0,36,0,8),
        Z      = 202,
        Parent = nFrame,
    })

    -- Body
    if body ~= "" then
        NewLabel({
            Text   = body,
            Color  = Theme.TextSecondary,
            Font   = Theme.FontUI,
            Size2  = 11,
            Size   = UDim2.new(1,-42,0,18),
            Pos    = UDim2.new(0,36,0,28),
            Z      = 202,
            Parent = nFrame,
        })
    end

    -- Progress bar
    local prog = NewFrame({
        Color  = accentCol,
        Size   = UDim2.new(1,0,0,2),
        Pos    = UDim2.new(0,0,1,-2),
        Z      = 203,
        Parent = nFrame,
    })

    local entry = { active = true, frame = nFrame, dismiss = nil }
    table.insert(NotifyStack, entry)

    local function Restack()
        for i, e in ipairs(NotifyStack) do
            if e.active and e.frame then
                local targetY = -(80 + (H + NOTIFY_PAD) * (i - 1) + H)
                tw(e.frame, {
                    Position = UDim2.new(1, -(NOTIFY_W + 12), 1, targetY)
                }, Theme.TweenMed)
            end
        end
    end

    local function dismiss()
        if not entry.active then return end
        entry.active = false
        tw(nFrame, {Position = UDim2.new(1, NOTIFY_W + 20, nFrame.Position.Y.Scale, nFrame.Position.Y.Offset)}, Theme.TweenMed)
        task.delay(0.35, function()
            pcall(function() nFrame:Destroy() end)
            Restack()
        end)
    end
    entry.dismiss = dismiss

    -- Click to dismiss
    local hitBtn = Instance.new("TextButton")
    hitBtn.BackgroundTransparency = 1
    hitBtn.Size   = UDim2.new(1,0,1,0)
    hitBtn.Text   = ""
    hitBtn.ZIndex = 210
    hitBtn.Parent = nFrame
    hitBtn.MouseButton1Click:Connect(dismiss)

    Restack()

    -- Progress bar tween + auto-dismiss
    tw(prog, {Size = UDim2.new(0,0,0,2)}, TweenInfo.new(duration, Enum.EasingStyle.Linear))
    task.delay(duration, dismiss)
end

------------------------------------------------------------------------
-- Library:CreateWindow
------------------------------------------------------------------------
function Library:CreateWindow(opts)
    opts = opts or {}
    local TITLE  = opts.Title  or "PlasmaLibUI"
    local ICON   = opts.IconId or "rbxassetid://7072706620"
    local W      = opts.Width  or 510
    local H      = opts.Height or 390

    -- ── ScreenGui ────────────────────────────────────────────────────
    local sg = Instance.new("ScreenGui")
    sg.Name           = "PlasmaLibUI_" .. TITLE:gsub("%s","")
    sg.ResetOnSpawn   = false
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.IgnoreGuiInset = true
    sg.DisplayOrder   = 999
    sg.Parent         = GuiParent()

    -- ── Window frame ─────────────────────────────────────────────────
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

    -- Top accent stripe (pulses on open)
    local accentStripe = NewFrame({
        Color  = Theme.Accent,
        Size   = UDim2.new(1,0,0,2),
        Z      = 6,
        Parent = win,
    })
    task.spawn(function()
        while accentStripe.Parent do
            tw(accentStripe, {BackgroundColor3 = Theme.AccentGlow}, Theme.TweenMed)
            task.wait(1.2)
            tw(accentStripe, {BackgroundColor3 = Theme.Accent}, Theme.TweenMed)
            task.wait(1.2)
        end
    end)

    -- ── Title bar ────────────────────────────────────────────────────
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
    iconImg.Size       = UDim2.new(0,22,0,22)
    iconImg.Position   = UDim2.new(0,8,0.5,-11)
    iconImg.Image      = ICON
    iconImg.ImageColor3 = Theme.Accent
    iconImg.ZIndex     = 7
    iconImg.Parent     = titleBar

    NewLabel({
        Text   = ("[ %s ]"):format(TITLE:upper()),
        Color  = Theme.Accent,
        Font   = Theme.FontMono,
        Size2  = Theme.TextSizeTitle,
        Size   = UDim2.new(1,-160,1,0),
        Pos    = UDim2.new(0,38,0,0),
        Z      = 7,
        Parent = titleBar,
    })

    -- Live clock in title bar
    local clockLbl = NewLabel({
        Text   = "00:00:00",
        Color  = Theme.TextMuted,
        Font   = Theme.FontMono,
        Size2  = Theme.TextSizeSmall,
        AlignX = Enum.TextXAlignment.Right,
        Size   = UDim2.new(0,80,1,0),
        Pos    = UDim2.new(1,-160,0,0),
        Z      = 7,
        Parent = titleBar,
    })
    task.spawn(function()
        while clockLbl.Parent do
            local t = os.time()
            local h, m, s = math.floor(t/3600)%24, math.floor(t/60)%60, t%60
            clockLbl.Text = ("%02d:%02d:%02d"):format(h, m, s)
            task.wait(1)
        end
    end)

    -- Minimize button
    local minimizeBtn = Instance.new("TextButton")
    minimizeBtn.BackgroundColor3 = Color3.fromRGB(20,30,20)
    minimizeBtn.Size       = UDim2.new(0,28,0,20)
    minimizeBtn.Position   = UDim2.new(1,-68,0.5,-10)
    minimizeBtn.Text       = "─"
    minimizeBtn.Font       = Theme.FontBold
    minimizeBtn.TextSize   = 15
    minimizeBtn.TextColor3 = Theme.AccentDim
    minimizeBtn.BorderSizePixel = 0
    minimizeBtn.AutoButtonColor = false
    minimizeBtn.ZIndex    = 8
    minimizeBtn.Parent    = titleBar
    Decorate(minimizeBtn, UDim.new(0,3), Theme.BorderDim, 1)
    minimizeBtn.MouseEnter:Connect(function()
        tw(minimizeBtn,{BackgroundColor3=Theme.SurfaceAlt, TextColor3=Theme.Accent})
    end)
    minimizeBtn.MouseLeave:Connect(function()
        tw(minimizeBtn,{BackgroundColor3=Color3.fromRGB(20,30,20), TextColor3=Theme.AccentDim})
    end)

    -- Close button
    local closeBtn = Instance.new("TextButton")
    closeBtn.BackgroundColor3 = Color3.fromRGB(28,8,8)
    closeBtn.Size       = UDim2.new(0,28,0,20)
    closeBtn.Position   = UDim2.new(1,-34,0.5,-10)
    closeBtn.Text       = "✕"
    closeBtn.Font       = Theme.FontBold
    closeBtn.TextSize   = 13
    closeBtn.TextColor3 = Theme.Danger
    closeBtn.BorderSizePixel = 0
    closeBtn.AutoButtonColor = false
    closeBtn.ZIndex   = 8
    closeBtn.Parent   = titleBar
    Decorate(closeBtn, UDim.new(0,3), Theme.Danger, 1)
    closeBtn.MouseEnter:Connect(function()
        tw(closeBtn,{BackgroundColor3=Theme.Danger, TextColor3=Color3.new(1,1,1)})
    end)
    closeBtn.MouseLeave:Connect(function()
        tw(closeBtn,{BackgroundColor3=Color3.fromRGB(28,8,8), TextColor3=Theme.Danger})
    end)
    closeBtn.MouseButton1Click:Connect(function()
        tw(win,{Size=UDim2.new(0,W,0,0)}, Theme.TweenSlow)
        task.delay(0.40, function() sg:Destroy() end)
    end)

    MakeDraggable(titleBar, win)

    -- ── Tab bar ──────────────────────────────────────────────────────
    local tabBar = NewFrame({
        Name   = "TabBar",
        Color  = Theme.TitleBar,
        Size   = UDim2.new(1,0,0,30),
        Pos    = UDim2.new(0,0,0,40),
        Z      = 5,
        Parent = win,
    })
    -- Thin divider below tab bar
    NewFrame({ Color=Theme.BorderDim, Size=UDim2.new(1,0,0,1), Pos=UDim2.new(0,0,1,-1), Z=6, Parent=tabBar })

    local tabBarList = Instance.new("UIListLayout")
    tabBarList.FillDirection       = Enum.FillDirection.Horizontal
    tabBarList.HorizontalAlignment = Enum.HorizontalAlignment.Left
    tabBarList.SortOrder           = Enum.SortOrder.LayoutOrder
    tabBarList.Padding             = UDim.new(0, 2)
    tabBarList.Parent              = tabBar

    local tabBarPad = Instance.new("UIPadding")
    tabBarPad.PaddingLeft = UDim.new(0,6)
    tabBarPad.PaddingTop  = UDim.new(0,4)
    tabBarPad.Parent      = tabBar

    -- ── Content area ─────────────────────────────────────────────────
    local CONTENT_TOP = 71
    local STATUSBAR_H = 20

    local contentArea = NewFrame({
        Name   = "ContentArea",
        Color  = Theme.Background,
        Size   = UDim2.new(1,0,1,-(CONTENT_TOP + STATUSBAR_H)),
        Pos    = UDim2.new(0,0,0,CONTENT_TOP),
        Z      = 3,
        Clip   = true,
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
    -- Top divider on status bar
    NewFrame({ Color=Theme.BorderDim, Size=UDim2.new(1,0,0,1), Z=6, Parent=statusBar })

    local statusLbl = NewLabel({
        Text   = "◈ ENCRYPTED // SECURE // PLASMA v2.0",
        Color  = Theme.TextMuted,
        Font   = Theme.FontMono,
        Size2  = 10,
        AlignX = Enum.TextXAlignment.Center,
        Z      = 6,
        Parent = statusBar,
    })

    ------------------------------------------------------------------
    -- Tab registry
    ------------------------------------------------------------------
    local tabs      = {}
    local activeIdx = 0
    local minimized = false
    local savedH    = H

    -- BUG FIX: SetActiveTab walks the live `tabs` table, no stale captures
    local function SetActiveTab(idx)
        if activeIdx == idx then return end
        activeIdx = idx
        for i, entry in ipairs(tabs) do
            if i == idx then
                tw(entry.btn, { BackgroundColor3 = Theme.TabActive, TextColor3 = Theme.Background })
                -- Slide active indicator
                tw(entry.indicator, { BackgroundTransparency = 0 })
                entry.page.Visible = true
            else
                tw(entry.btn, { BackgroundColor3 = Theme.TabInactive, TextColor3 = Theme.TextSecondary })
                tw(entry.indicator, { BackgroundTransparency = 1 })
                entry.page.Visible = false
            end
        end
    end

    ------------------------------------------------------------------
    -- Window public API
    ------------------------------------------------------------------
    local Window = {}

    function Window:SetIcon(id) iconImg.Image = id end
    function Window:SetStatus(text) statusLbl.Text = text end

    function Window:Notify(o) PushNotify(sg, o) end

    function Window:SetTab(name)
        for i, entry in ipairs(tabs) do
            if entry.name == name then
                SetActiveTab(i)
                return
            end
        end
    end

    function Window:Minimize()
        if minimized then return end
        minimized = true
        savedH    = win.AbsoluteSize.Y
        tw(win, {Size = UDim2.new(0,W,0,40)}, Theme.TweenMed)
        minimizeBtn.Text = "□"
    end

    function Window:Restore()
        if not minimized then return end
        minimized = false
        tw(win, {Size = UDim2.new(0,W,0,savedH)}, Theme.TweenMed)
        minimizeBtn.Text = "─"
    end

    minimizeBtn.MouseButton1Click:Connect(function()
        if minimized then Window:Restore() else Window:Minimize() end
    end)

    ----------------------------------------------------------------
    -- Window:CreateTab
    ----------------------------------------------------------------
    function Window:CreateTab(name)
        name = tostring(name or "Tab")

        -- Tab button
        local btn = Instance.new("TextButton")
        btn.Name             = "TabBtn_" .. name
        btn.BackgroundColor3 = Theme.TabInactive
        btn.Size             = UDim2.new(0, 88, 0, 22)
        btn.Text             = name:upper()
        btn.Font             = Theme.FontMono
        btn.TextSize         = Theme.TextSizeSmall
        btn.TextColor3       = Theme.TextSecondary
        btn.BorderSizePixel  = 0
        btn.AutoButtonColor  = false
        btn.LayoutOrder      = #tabs + 1
        btn.ZIndex           = 7
        btn.Parent           = tabBar
        Decorate(btn, UDim.new(0,4), false)

        -- Active underline indicator
        local indicator = NewFrame({
            Color  = Theme.Accent,
            Size   = UDim2.new(1,-6,0,2),
            Pos    = UDim2.new(0,3,1,-2),
            Z      = 8,
            Parent = btn,
        })
        indicator.BackgroundTransparency = 1

        -- Scrollable page
        local page = Instance.new("ScrollingFrame")
        page.Name                 = "Page_" .. name
        page.BackgroundTransparency = 1
        page.BorderSizePixel      = 0
        page.Size                 = UDim2.new(1,0,1,0)
        page.Position             = UDim2.new(0,0,0,0)
        page.ScrollBarThickness   = 3
        page.ScrollBarImageColor3 = Theme.AccentDim
        page.CanvasSize           = UDim2.new(0,0,0,0)
        page.AutomaticCanvasSize  = Enum.AutomaticSize.Y
        page.ZIndex               = 4
        page.Visible              = false
        page.Parent               = contentArea

        local listLayout = Instance.new("UIListLayout")
        listLayout.SortOrder = Enum.SortOrder.LayoutOrder
        listLayout.Padding   = UDim.new(0, 6)
        listLayout.Parent    = page

        local pagePad = Instance.new("UIPadding")
        pagePad.PaddingTop    = UDim.new(0,8)
        pagePad.PaddingLeft   = UDim.new(0,10)
        pagePad.PaddingRight  = UDim.new(0,10)
        pagePad.PaddingBottom = UDim.new(0,8)
        pagePad.Parent        = page

        local myIndex = #tabs + 1
        tabs[myIndex] = { btn = btn, page = page, name = name, indicator = indicator }

        if myIndex == 1 then SetActiveTab(1) end

        btn.MouseButton1Click:Connect(function() SetActiveTab(myIndex) end)
        btn.MouseEnter:Connect(function()
            if activeIdx ~= myIndex then tw(btn, {BackgroundColor3=Theme.SurfaceAlt}) end
        end)
        btn.MouseLeave:Connect(function()
            if activeIdx ~= myIndex then tw(btn, {BackgroundColor3=Theme.TabInactive}) end
        end)

        -- Element builder helpers
        local elementOrder = 0
        local function NextOrder() elementOrder = elementOrder + 1; return elementOrder end

        local function ElemFrame(h, noClip)
            local ef = NewFrame({
                Color  = Theme.SurfaceAlt,
                Size   = UDim2.new(1,0,0, h or 38),
                Z      = 5,
                Clip   = not noClip,
                Name   = "Element",
                Parent = page,
            })
            ef.LayoutOrder = NextOrder()
            Decorate(ef, UDim.new(0,5), Theme.BorderDim, 1)
            local pad = Instance.new("UIPadding")
            pad.PaddingLeft  = UDim.new(0,10)
            pad.PaddingRight = UDim.new(0,10)
            pad.Parent       = ef
            return ef
        end

        local Tab = {}

        ----------------------------------------------------------------
        -- Tab:CreateLabel
        ----------------------------------------------------------------
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

        ----------------------------------------------------------------
        -- Tab:CreateSection
        ----------------------------------------------------------------
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

        ----------------------------------------------------------------
        -- Tab:CreateDivider  (NEW)
        ----------------------------------------------------------------
        function Tab:CreateDivider(label)
            local ef = ElemFrame(20)
            ef.BackgroundTransparency = 1

            if label and label ~= "" then
                -- Label in centre, lines on either side
                local lw = math.min(#label * 8 + 16, 180)
                NewFrame({ Color=Theme.BorderDim, Size=UDim2.new(0.5,-lw/2-4,0,1), Pos=UDim2.new(0,0,0.5,0), Z=6, Parent=ef })
                NewFrame({ Color=Theme.BorderDim, Size=UDim2.new(0.5,-lw/2-4,0,1), Pos=UDim2.new(0.5,lw/2+4,0.5,0), Z=6, Parent=ef })
                NewLabel({
                    Text   = label:upper(),
                    Color  = Theme.TextMuted,
                    Font   = Theme.FontMono,
                    Size2  = 10,
                    AlignX = Enum.TextXAlignment.Center,
                    Size   = UDim2.new(1,0,1,0),
                    Z      = 6,
                    Parent = ef,
                })
            else
                NewFrame({ Color=Theme.BorderDim, Size=UDim2.new(1,0,0,1), Pos=UDim2.new(0,0,0.5,0), Z=6, Parent=ef })
            end
        end

        ----------------------------------------------------------------
        -- Tab:CreateParagraph  (NEW)
        ----------------------------------------------------------------
        function Tab:CreateParagraph(opts)
            opts = opts or {}
            local heading = opts.Heading or ""
            local body    = opts.Body    or opts.Text or ""
            local lineH   = 16
            local lines   = 1
            -- rough line count
            for _ in body:gmatch("\n") do lines = lines + 1 end
            lines = math.max(lines, math.ceil(#body / 52))
            local totalH  = (heading ~= "" and 22 or 0) + lines * lineH + 16

            local ef = ElemFrame(totalH)
            ef.BackgroundColor3 = Theme.Surface

            local yOff = 8
            if heading ~= "" then
                NewLabel({
                    Text   = heading,
                    Color  = Theme.Accent,
                    Font   = Theme.FontBold,
                    Size2  = Theme.TextSizeBody,
                    Size   = UDim2.new(1,0,0,20),
                    Pos    = UDim2.new(0,0,0,yOff),
                    Z      = 6,
                    Parent = ef,
                })
                yOff = yOff + 22
            end

            local bodyLbl = Instance.new("TextLabel")
            bodyLbl.BackgroundTransparency = 1
            bodyLbl.TextColor3    = Theme.TextSecondary
            bodyLbl.Font          = Theme.FontUI
            bodyLbl.TextSize      = Theme.TextSizeSmall
            bodyLbl.Text          = body
            bodyLbl.TextXAlignment = Enum.TextXAlignment.Left
            bodyLbl.TextYAlignment = Enum.TextYAlignment.Top
            bodyLbl.TextWrapped   = true
            bodyLbl.Size          = UDim2.new(1,-20,0, lines * lineH)
            bodyLbl.Position      = UDim2.new(0,0,0,yOff)
            bodyLbl.ZIndex        = 6
            bodyLbl.Parent        = ef
        end

        ----------------------------------------------------------------
        -- Tab:CreateButton
        ----------------------------------------------------------------
        function Tab:CreateButton(opts)
            opts = opts or {}
            local lbl = opts.Label    or "Button"
            local cb  = opts.Callback or function() end

            local ef   = ElemFrame(36)
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
            Decorate(btn2, UDim.new(0,5), Theme.Border, 1)

            btn2.MouseEnter:Connect(function()
                tw(btn2,{BackgroundColor3=Theme.SurfaceHover, TextColor3=Theme.TextPrimary})
            end)
            btn2.MouseLeave:Connect(function()
                tw(btn2,{BackgroundColor3=Theme.Surface, TextColor3=Theme.Accent})
            end)
            btn2.MouseButton1Down:Connect(function()
                tw(btn2,{BackgroundColor3=Theme.AccentDim})
            end)
            btn2.MouseButton1Up:Connect(function()
                tw(btn2,{BackgroundColor3=Theme.SurfaceHover})
            end)
            btn2.MouseButton1Click:Connect(function() pcall(cb) end)

            return btn2
        end

        ----------------------------------------------------------------
        -- Tab:CreateToggle
        ----------------------------------------------------------------
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

        ----------------------------------------------------------------
        -- Tab:CreateSlider
        ----------------------------------------------------------------
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

            local dragging = false  -- per-slider via closure

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

        ----------------------------------------------------------------
        -- Tab:CreateDropdown   BUG FIX: portals list to sg root
        --   The old version parented the list to dropBtn which was inside
        --   a ScrollingFrame — ScrollingFrames clip children regardless of
        --   ZIndex so the list was always hidden behind other elements.
        --   Fix: the open list is reparented to `sg` (ScreenGui root) and
        --   its absolute position is recalculated every time it opens.
        ----------------------------------------------------------------
        function Tab:CreateDropdown(opts)
            opts = opts or {}
            local lbl      = opts.Label    or "Dropdown"
            local choices  = opts.Options  or {}
            local cb       = opts.Callback or function() end
            local selected = opts.Default  or choices[1] or "None"
            local open     = false

            local ITEM_H     = 28
            local MAX_SHOWN  = 6

            -- Anchor element (normal flow)
            local ef = ElemFrame(38)

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
            dropBtn.Text             = ("  %s  ▾"):format(tostring(selected))
            dropBtn.Font             = Theme.FontMono
            dropBtn.TextSize         = Theme.TextSizeSmall
            dropBtn.TextColor3       = Theme.Accent
            dropBtn.BorderSizePixel  = 0
            dropBtn.AutoButtonColor  = false
            dropBtn.ZIndex           = 7
            dropBtn.Parent           = ef
            Decorate(dropBtn, UDim.new(0,4), Theme.Border, 1)

            -- Portal frame: lives at ScreenGui root — never clipped
            local portal = NewFrame({
                Color  = Theme.TitleBar,
                Size   = UDim2.new(0,1,0,0),   -- sized absolutely on open
                Pos    = UDim2.new(0,0,0,0),
                Z      = 120,
                Clip   = true,
                Name   = "DropdownPortal",
                Parent = sg,
            })
            portal.Visible = false
            Decorate(portal, UDim.new(0,5), Theme.Border, 1)

            local scrollF = Instance.new("ScrollingFrame")
            scrollF.BackgroundTransparency = 1
            scrollF.Size                   = UDim2.new(1,0,1,0)
            scrollF.ScrollBarThickness     = 3
            scrollF.ScrollBarImageColor3   = Theme.AccentDim
            scrollF.BorderSizePixel        = 0
            scrollF.ZIndex                 = 121
            scrollF.Parent                 = portal

            local ll = Instance.new("UIListLayout")
            ll.SortOrder = Enum.SortOrder.LayoutOrder
            ll.Parent    = scrollF

            local function Close()
                if not open then return end
                open = false
                tw(portal, {Size = UDim2.new(0, portal.AbsoluteSize.X, 0, 0)}, Theme.Tween)
                task.delay(0.18, function()
                    if not open then portal.Visible = false end
                end)
                dropBtn.Text = ("  %s  ▾"):format(tostring(selected))
            end

            local function Open()
                if open then return end
                open = true
                -- Recalc portal position from dropBtn's absolute position
                local abs  = dropBtn.AbsolutePosition
                local sz   = dropBtn.AbsoluteSize
                local listH = math.min(#choices, MAX_SHOWN) * ITEM_H
                local availableBelow = sg.AbsoluteSize.Y - (abs.Y + sz.Y + 6)
                local spawnY = abs.Y + sz.Y + 6
                if listH > availableBelow then
                    spawnY = abs.Y - listH - 4
                end
                portal.Position  = UDim2.new(0, abs.X, 0, spawnY)
                portal.Size      = UDim2.new(0, sz.X, 0, 0)
                portal.Visible   = true
                tw(portal, {Size = UDim2.new(0, sz.X, 0, listH)}, Theme.Tween)
                dropBtn.Text = ("  %s  ▴"):format(tostring(selected))
            end

            -- Close when clicking elsewhere
            UserInputService.InputBegan:Connect(function(inp)
                if not open then return end
                if inp.UserInputType ~= Enum.UserInputType.MouseButton1
                and inp.UserInputType ~= Enum.UserInputType.Touch then return end
                local mp = inp.Position
                local pa = portal.AbsolutePosition
                local ps = portal.AbsoluteSize
                local da = dropBtn.AbsolutePosition
                local ds = dropBtn.AbsoluteSize
                local inPortal = mp.X >= pa.X and mp.X <= pa.X+ps.X and mp.Y >= pa.Y and mp.Y <= pa.Y+ps.Y
                local inBtn    = mp.X >= da.X and mp.X <= da.X+ds.X and mp.Y >= da.Y and mp.Y <= da.Y+ds.Y
                if not inPortal and not inBtn then Close() end
            end)

            dropBtn.MouseButton1Click:Connect(function()
                if open then Close() else Open() end
            end)
            dropBtn.MouseEnter:Connect(function()
                tw(dropBtn, {BackgroundColor3=Theme.SurfaceAlt})
            end)
            dropBtn.MouseLeave:Connect(function()
                tw(dropBtn, {BackgroundColor3=Theme.Surface})
            end)

            local Dropdown = {}

            function Dropdown:Refresh(newOptions)
                choices = newOptions or {}
                for _, c in ipairs(scrollF:GetChildren()) do
                    if c:IsA("TextButton") then c:Destroy() end
                end
                scrollF.CanvasSize = UDim2.new(0,0,0, #choices * ITEM_H)

                for i, choice in ipairs(choices) do
                    local item = Instance.new("TextButton")
                    item.BackgroundColor3 = Theme.TitleBar
                    item.Size             = UDim2.new(1,0,0,ITEM_H)
                    item.Text             = ("  %s"):format(tostring(choice))
                    item.TextXAlignment   = Enum.TextXAlignment.Left
                    item.Font             = Theme.FontMono
                    item.TextSize         = Theme.TextSizeSmall
                    item.TextColor3       = i == 1 and Theme.Accent or Theme.TextSecondary
                    item.BorderSizePixel  = 0
                    item.AutoButtonColor  = false
                    item.LayoutOrder      = i
                    item.ZIndex           = 122
                    item.Parent           = scrollF

                    item.MouseEnter:Connect(function()
                        tw(item,{BackgroundColor3=Theme.SurfaceHover, TextColor3=Theme.Accent})
                    end)
                    item.MouseLeave:Connect(function()
                        tw(item,{BackgroundColor3=Theme.TitleBar, TextColor3=Theme.TextSecondary})
                    end)
                    item.MouseButton1Click:Connect(function()
                        selected = choice
                        Close()
                        pcall(cb, selected)
                    end)
                end
            end

            function Dropdown:Get()  return selected end
            function Dropdown:Set(v)
                selected = v
                dropBtn.Text = ("  %s  ▾"):format(tostring(selected))
                pcall(cb, selected)
            end

            Dropdown:Refresh(choices)
            return Dropdown
        end

        ----------------------------------------------------------------
        -- Tab:CreateTextInput
        ----------------------------------------------------------------
        function Tab:CreateTextInput(opts)
            opts = opts or {}
            local lbl = opts.Label       or "Input"
            local ph  = opts.Placeholder or "type here..."
            local cb  = opts.Callback    or function() end

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
            box.Text              = opts.Default or ""
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
            p.Parent      = box

            box.Focused:Connect(function()
                tw(box,{BackgroundColor3=Theme.SurfaceHover})
                tw(box,{TextColor3=Theme.AccentGlow})
            end)
            box.FocusLost:Connect(function(enter)
                tw(box,{BackgroundColor3=Theme.Surface})
                tw(box,{TextColor3=Theme.Accent})
                pcall(cb, box.Text, enter)
            end)

            local Inp = {}
            function Inp:Get()     return box.Text end
            function Inp:Set(v)    box.Text = tostring(v) end
            function Inp:Clear()   box.Text = "" end
            return Inp
        end

        ----------------------------------------------------------------
        -- Tab:CreateSearchBox  (NEW)
        ----------------------------------------------------------------
        function Tab:CreateSearchBox(opts)
            opts = opts or {}
            local lbl  = opts.Label       or "Search"
            local ph   = opts.Placeholder or "search..."
            local cb   = opts.Callback    or function() end

            local ef = ElemFrame(38)
            ef.BackgroundColor3 = Theme.Surface

            -- Magnifier icon
            NewLabel({
                Text   = "⌕",
                Color  = Theme.AccentDim,
                Font   = Theme.FontMono,
                Size2  = 16,
                Size   = UDim2.new(0,24,1,0),
                AlignX = Enum.TextXAlignment.Center,
                Z      = 7,
                Parent = ef,
            })

            local box = Instance.new("TextBox")
            box.BackgroundTransparency = 1
            box.Size              = UDim2.new(1,-30,0,28)
            box.Position          = UDim2.new(0,26,0.5,-14)
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

            box.Changed:Connect(function(prop)
                if prop == "Text" then pcall(cb, box.Text) end
            end)

            local S = {}
            function S:Get()   return box.Text end
            function S:Set(v)  box.Text = tostring(v) end
            function S:Clear() box.Text = "" end
            return S
        end

        ----------------------------------------------------------------
        -- Tab:CreateKeybind  (NEW)
        ----------------------------------------------------------------
        function Tab:CreateKeybind(opts)
            opts = opts or {}
            local lbl       = opts.Label    or "Keybind"
            local default   = opts.Default  or Enum.KeyCode.Unknown
            local cb        = opts.Callback or function() end
            local current   = default
            local listening = false

            local ef = ElemFrame(38)

            NewLabel({
                Text   = lbl,
                Color  = Theme.TextPrimary,
                Font   = Theme.FontUI,
                Size2  = Theme.TextSizeBody,
                Size   = UDim2.new(1,-120,1,0),
                Z      = 6,
                Parent = ef,
            })

            local keyBtn = Instance.new("TextButton")
            keyBtn.BackgroundColor3 = Theme.Surface
            keyBtn.Size             = UDim2.new(0,110,0,24)
            keyBtn.Position         = UDim2.new(1,-110,0.5,-12)
            keyBtn.Text             = ("[ %s ]"):format(current.Name)
            keyBtn.Font             = Theme.FontMono
            keyBtn.TextSize         = Theme.TextSizeSmall
            keyBtn.TextColor3       = Theme.Accent
            keyBtn.BorderSizePixel  = 0
            keyBtn.AutoButtonColor  = false
            keyBtn.ZIndex           = 7
            keyBtn.Parent           = ef
            Decorate(keyBtn, UDim.new(0,4), Theme.Border, 1)

            keyBtn.MouseButton1Click:Connect(function()
                if listening then return end
                listening = true
                keyBtn.Text      = "[ ... ]"
                keyBtn.TextColor3 = Theme.Warning
                tw(keyBtn, {BackgroundColor3=Theme.SurfaceHover})
            end)

            UserInputService.InputBegan:Connect(function(inp, processed)
                if not listening then return end
                if inp.UserInputType == Enum.UserInputType.Keyboard then
                    listening        = false
                    current          = inp.KeyCode
                    keyBtn.Text      = ("[ %s ]"):format(current.Name)
                    keyBtn.TextColor3 = Theme.Accent
                    tw(keyBtn, {BackgroundColor3=Theme.Surface})
                    pcall(cb, current)
                end
            end)

            keyBtn.MouseEnter:Connect(function()
                if not listening then tw(keyBtn,{BackgroundColor3=Theme.SurfaceAlt}) end
            end)
            keyBtn.MouseLeave:Connect(function()
                if not listening then tw(keyBtn,{BackgroundColor3=Theme.Surface}) end
            end)

            local Keybind = {}
            function Keybind:Get()   return current end
            function Keybind:Set(kc)
                current = kc
                keyBtn.Text = ("[ %s ]"):format(current.Name)
            end
            return Keybind
        end

        ----------------------------------------------------------------
        -- Tab:CreateColorPicker  (NEW)
        -- HSV picker: hue strip + SV square + hex input
        ----------------------------------------------------------------
        function Tab:CreateColorPicker(opts)
            opts = opts or {}
            local lbl     = opts.Label    or "Color"
            local default = opts.Default  or Color3.fromRGB(0,255,100)
            local cb      = opts.Callback or function() end

            -- Convert default to HSV
            local initH, initS, initV = default:ToHSV()
            local curH, curS, curV = initH, initS, initV
            local expanded = false

            -- Collapsed row
            local ef = ElemFrame(38)

            NewLabel({
                Text   = lbl,
                Color  = Theme.TextPrimary,
                Font   = Theme.FontUI,
                Size2  = Theme.TextSizeBody,
                Size   = UDim2.new(1,-120,1,0),
                Z      = 6,
                Parent = ef,
            })

            -- Preview swatch
            local swatch = NewFrame({
                Color  = default,
                Size   = UDim2.new(0,32,0,22),
                Pos    = UDim2.new(1,-100,0.5,-11),
                Z      = 7,
                Parent = ef,
            })
            Decorate(swatch, UDim.new(0,4), Theme.Border, 1)

            local toggleBtn = Instance.new("TextButton")
            toggleBtn.BackgroundColor3 = Theme.Surface
            toggleBtn.Size             = UDim2.new(0,60,0,22)
            toggleBtn.Position         = UDim2.new(1,-64,0.5,-11)
            toggleBtn.Text             = "PICK ▾"
            toggleBtn.Font             = Theme.FontMono
            toggleBtn.TextSize         = 11
            toggleBtn.TextColor3       = Theme.AccentDim
            toggleBtn.BorderSizePixel  = 0
            toggleBtn.AutoButtonColor  = false
            toggleBtn.ZIndex           = 7
            toggleBtn.Parent           = ef
            Decorate(toggleBtn, UDim.new(0,4), Theme.BorderDim, 1)

            -- Expanded picker panel (appended after ef in the page)
            local pickerFrame = NewFrame({
                Color  = Theme.Surface,
                Size   = UDim2.new(1,0,0,0),
                Z      = 5,
                Clip   = true,
                Name   = "ColorPickerPanel",
                Parent = page,
            })
            pickerFrame.LayoutOrder = ef.LayoutOrder + 0.5
            pickerFrame.Visible     = false
            Decorate(pickerFrame, UDim.new(0,5), Theme.BorderDim, 1)

            -- SV square (200 x 120)
            local SQ_W, SQ_H = 200, 110
            local svCanvas = Instance.new("ImageLabel")
            svCanvas.BackgroundColor3 = Color3.fromHSV(curH, 1, 1)
            svCanvas.Size             = UDim2.new(0,SQ_W,0,SQ_H)
            svCanvas.Position         = UDim2.new(0,10,0,10)
            svCanvas.BorderSizePixel  = 0
            svCanvas.ZIndex           = 7
            svCanvas.Image            = "rbxassetid://4155801252"  -- white-to-transparent gradient
            svCanvas.Parent           = pickerFrame
            Decorate(svCanvas, UDim.new(0,3), Theme.BorderDim, 1)

            -- Black gradient overlay
            local blackGrad = Instance.new("ImageLabel")
            blackGrad.BackgroundTransparency = 1
            blackGrad.Size        = UDim2.new(1,0,1,0)
            blackGrad.BorderSizePixel = 0
            blackGrad.ZIndex      = 8
            blackGrad.Image       = "rbxassetid://4155801252"
            blackGrad.ImageColor3 = Color3.new(0,0,0)
            blackGrad.Rotation    = 90
            blackGrad.Parent      = svCanvas

            -- SV cursor
            local svCursor = NewFrame({
                Color  = Color3.new(1,1,1),
                Size   = UDim2.new(0,10,0,10),
                Pos    = UDim2.new(curS,-5, 1-curV,-5),
                Z      = 10,
                Parent = svCanvas,
            })
            Decorate(svCursor, UDim.new(0,5), Color3.new(0,0,0), 1)

            -- Hue strip (right of SV)
            local HUE_W = 20
            local hueStrip = Instance.new("ImageLabel")
            hueStrip.BackgroundColor3 = Color3.new(1,1,1)
            hueStrip.Size             = UDim2.new(0,HUE_W,0,SQ_H)
            hueStrip.Position         = UDim2.new(0,SQ_W+16,0,10)
            hueStrip.BorderSizePixel  = 0
            hueStrip.ZIndex           = 7
            hueStrip.Image            = "rbxassetid://698052001"   -- rainbow gradient
            hueStrip.Parent           = pickerFrame
            Decorate(hueStrip, UDim.new(0,3), Theme.BorderDim, 1)

            local hueCursor = NewFrame({
                Color  = Color3.new(1,1,1),
                Size   = UDim2.new(1,4,0,4),
                Pos    = UDim2.new(0,-2, curH, -2),
                Z      = 10,
                Parent = hueStrip,
            })
            Decorate(hueCursor, UDim.new(0,2), Color3.new(0,0,0), 1)

            -- Hex input
            local hexBox = Instance.new("TextBox")
            hexBox.BackgroundColor3  = Theme.SurfaceAlt
            hexBox.Size              = UDim2.new(0,SQ_W,0,24)
            hexBox.Position          = UDim2.new(0,10,0,SQ_H+16)
            hexBox.Text              = ("%02X%02X%02X"):format(
                math.floor(default.R*255), math.floor(default.G*255), math.floor(default.B*255))
            hexBox.PlaceholderText   = "RRGGBB"
            hexBox.PlaceholderColor3 = Theme.TextDisabled
            hexBox.Font              = Theme.FontMono
            hexBox.TextSize          = Theme.TextSizeSmall
            hexBox.TextColor3        = Theme.Accent
            hexBox.BorderSizePixel   = 0
            hexBox.ZIndex            = 7
            hexBox.ClearTextOnFocus  = false
            hexBox.Parent            = pickerFrame
            Decorate(hexBox, UDim.new(0,3), Theme.Border, 1)

            local hexPad = Instance.new("UIPadding")
            hexPad.PaddingLeft = UDim.new(0,6)
            hexPad.Parent      = hexBox

            local PANEL_H = SQ_H + 16 + 24 + 14

            -- Helper: fire callback with current HSV
            local function FireCB()
                local c = Color3.fromHSV(curH, curS, curV)
                swatch.BackgroundColor3 = c
                hexBox.Text = ("%02X%02X%02X"):format(
                    math.floor(c.R*255), math.floor(c.G*255), math.floor(c.B*255))
                pcall(cb, c)
            end

            -- SV drag
            local svDragging = false
            svCanvas.InputBegan:Connect(function(inp)
                if inp.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
                svDragging = true
                local rel = inp.Position - svCanvas.AbsolutePosition
                curS = math.clamp(rel.X / SQ_W, 0, 1)
                curV = math.clamp(1 - rel.Y / SQ_H, 0, 1)
                svCursor.Position = UDim2.new(curS,-5, 1-curV,-5)
                FireCB()
            end)
            UserInputService.InputChanged:Connect(function(inp)
                if not svDragging then return end
                if inp.UserInputType ~= Enum.UserInputType.MouseMovement then return end
                local rel = inp.Position - svCanvas.AbsolutePosition
                curS = math.clamp(rel.X / SQ_W, 0, 1)
                curV = math.clamp(1 - rel.Y / SQ_H, 0, 1)
                svCursor.Position = UDim2.new(curS,-5, 1-curV,-5)
                FireCB()
            end)
            UserInputService.InputEnded:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                    svDragging = false
                end
            end)

            -- Hue drag
            local hueDragging = false
            hueStrip.InputBegan:Connect(function(inp)
                if inp.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
                hueDragging = true
                local rel = inp.Position - hueStrip.AbsolutePosition
                curH = math.clamp(rel.Y / SQ_H, 0, 1)
                hueCursor.Position = UDim2.new(0,-2, curH,-2)
                svCanvas.BackgroundColor3 = Color3.fromHSV(curH,1,1)
                FireCB()
            end)
            UserInputService.InputChanged:Connect(function(inp)
                if not hueDragging then return end
                if inp.UserInputType ~= Enum.UserInputType.MouseMovement then return end
                local rel = inp.Position - hueStrip.AbsolutePosition
                curH = math.clamp(rel.Y / SQ_H, 0, 1)
                hueCursor.Position = UDim2.new(0,-2, curH,-2)
                svCanvas.BackgroundColor3 = Color3.fromHSV(curH,1,1)
                FireCB()
            end)
            UserInputService.InputEnded:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                    hueDragging = false
                end
            end)

            -- Hex input commit
            hexBox.FocusLost:Connect(function()
                local hex = hexBox.Text:gsub("[^%x]",""):sub(1,6)
                if #hex == 6 then
                    local r = tonumber(hex:sub(1,2),16)/255
                    local g = tonumber(hex:sub(3,4),16)/255
                    local b = tonumber(hex:sub(5,6),16)/255
                    local c = Color3.new(r,g,b)
                    curH, curS, curV = c:ToHSV()
                    svCanvas.BackgroundColor3 = Color3.fromHSV(curH,1,1)
                    svCursor.Position  = UDim2.new(curS,-5,1-curV,-5)
                    hueCursor.Position = UDim2.new(0,-2,curH,-2)
                    FireCB()
                end
            end)

            -- Toggle expand
            toggleBtn.MouseButton1Click:Connect(function()
                expanded = not expanded
                if expanded then
                    pickerFrame.Visible = true
                    tw(pickerFrame, {Size=UDim2.new(1,0,0,PANEL_H)}, Theme.TweenMed)
                    toggleBtn.Text = "PICK ▴"
                else
                    tw(pickerFrame, {Size=UDim2.new(1,0,0,0)}, Theme.Tween)
                    task.delay(0.2, function()
                        if not expanded then pickerFrame.Visible = false end
                    end)
                    toggleBtn.Text = "PICK ▾"
                end
            end)

            local ColorPicker = {}
            function ColorPicker:Get()
                return Color3.fromHSV(curH, curS, curV)
            end
            function ColorPicker:Set(c)
                curH, curS, curV = c:ToHSV()
                svCanvas.BackgroundColor3 = Color3.fromHSV(curH,1,1)
                svCursor.Position  = UDim2.new(curS,-5,1-curV,-5)
                hueCursor.Position = UDim2.new(0,-2,curH,-2)
                FireCB()
            end
            return ColorPicker
        end

        return Tab
    end  -- CreateTab

    -- Animate open
    tw(win, {Size = UDim2.new(0,W,0,H)}, Theme.TweenBounce)

    return Window
end  -- CreateWindow

return Library
