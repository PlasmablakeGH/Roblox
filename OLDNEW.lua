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
    Version      :  1.3.0  (Added Smart Asset/Icon Resolver)

    USAGE:
        local Library = loadstring(game:HttpGet(RAW_URL, true))()
        
        -- IconId accepts:
        -- 1. Roblox ID: 7072706620 or "7072706620"
        -- 2. Local PC File: "my_icon.png" (placed inside executor workspace)
        -- 3. Web URL: "https://raw.githubusercontent.com/.../icon.png"
        
        local Window  = Library:CreateWindow({
            Title     = "My Tool",
            IconId    = "my_icon.png",               -- Local file or Asset ID
            ToggleKey = Enum.KeyCode.RightControl, -- optional
            Scanlines = true,                      -- optional, default true
        })
--]]

------------------------------------------------------------------------
-- Services
------------------------------------------------------------------------
local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local TextService      = game:GetService("TextService")

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
local function getIconAsset(iconInput)
    if not iconInput or iconInput == "" then return "" end

    -- 1. Numeric Roblox ID (e.g., 7072706620 or "7072706620")
    if type(iconInput) == "number" or (type(iconInput) == "string" and tonumber(iconInput)) then
        return "rbxassetid://" .. tostring(iconInput)
    end

    if type(iconInput) == "string" then
        -- 2. Standard Roblox asset string formats
        if iconInput:find("rbxasset") or iconInput:find("rbxthumb") then
            return iconInput
        end

        -- 3. Web URL (e.g., raw GitHub / Imgur)
        if iconInput:find("http://") or iconInput:find("https://") then
            if not (writefile and getcustomasset and game.HttpGet) then
                warn("[PlasmaLibUI] Executor missing APIs to fetch web images.")
                return ""
            end

            local safeName = "cache_" .. iconInput:gsub("[^%w]", "_"):sub(-40) .. ".png"
            if isfile and isfile(safeName) then
                return getcustomasset(safeName)
            end

            local success, result = pcall(function()
                local bytes = game:HttpGet(iconInput)
                writefile(safeName, bytes)
                return getcustomasset(safeName)
            end)

            if success then
                return result
            else
                warn("[PlasmaLibUI] Failed to download image from URL:", result)
                return ""
            end
        end

        -- 4. Local file inside executor workspace folder
        if isfile and isfile(iconInput) and getcustomasset then
            return getcustomasset(iconInput)
        end
    end

    return tostring(iconInput)
end

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

local function AddScanlines(parent, count)
    count = count or 60
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
    for _ = 1, count do
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
-- Drag
------------------------------------------------------------------------
local function MakeDraggable(handle, target, track)
    local active, origin, startPos = false, Vector2.zero, UDim2.new()

    local function clampPos(newPos)
        local camera = workspace.CurrentCamera
        local vp = camera and camera.ViewportSize or Vector2.new(1920, 1080)
        local size = target.AbsoluteSize
        local minVisible = 44
        local scaleX, scaleY = newPos.X.Scale, newPos.Y.Scale
        local minOffX = minVisible - size.X - vp.X * scaleX
        local maxOffX = vp.X - minVisible - vp.X * scaleX
        local minOffY = 0 - vp.Y * scaleY
        local maxOffY = vp.Y - minVisible - vp.Y * scaleY
        local x = math.clamp(newPos.X.Offset, minOffX, maxOffX)
        local y = math.clamp(newPos.Y.Offset, minOffY, maxOffY)
        return UDim2.new(scaleX, x, scaleY, y)
    end

    local c1 = handle.InputBegan:Connect(function(inp)
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
    local c2 = UserInputService.InputChanged:Connect(function(inp)
        if not active then return end
        if inp.UserInputType ~= Enum.UserInputType.MouseMovement
        and inp.UserInputType ~= Enum.UserInputType.Touch then return end
        local d = inp.Position - origin
        local newPos = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + d.X,
            startPos.Y.Scale, startPos.Y.Offset + d.Y
        )
        target.Position = clampPos(newPos)
    end)

    if track then track(c1); track(c2) end
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
    local TITLE     = opts.Title     or "PlasmaLibUI"
    local ICON      = getIconAsset(opts.IconId or "rbxassetid://7072706620")
    local W         = opts.Width     or 500
    local H         = opts.Height    or 380
    local SCANLINES = opts.Scanlines ~= false
    local TOGGLEKEY = opts.ToggleKey

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
        Size   = UDim2.new(0, W, 0, 0),
        Pos    = UDim2.new(0.5,-W/2, 0.5,-H/2),
        Clip   = true,
        Z      = 2,
        Parent = sg,
    })
    Decorate(win, UDim.new(0,0), Theme.Border, 1)
    if SCANLINES then
        AddScanlines(win, math.clamp(math.floor(H / 4), 20, 80))
    end

    NewFrame({ Color=Theme.Accent, Size=UDim2.new(1,0,0,2), Z=6, Parent=win })

    local connections = {}
    local function track(c)
        table.insert(connections, c)
        return c
    end

    local Window = {}

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
    iconImg.ImageColor3 = Theme.Accent
    iconImg.ZIndex    = 7
    iconImg.Parent    = titleBar

    -- Title text
    NewLabel({
        Text   = ("[ %s ]"):format(TITLE:upper()),
        Color  = Theme.Accent,
        Font   = Theme.FontMono,
        Size2  = Theme.TextSizeTitle,
        Size   = UDim2.new(1,-104,1,0),
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
        task.delay(0.38, function() Window:Destroy() end)
    end)

    -- Minimize button
    local minimizeBtn = Instance.new("TextButton")
    minimizeBtn.BackgroundColor3 = Theme.Surface
    minimizeBtn.Size       = UDim2.new(0,28,0,20)
    minimizeBtn.Position   = UDim2.new(1,-66,0.5,-10)
    minimizeBtn.Text       = "_"
    minimizeBtn.Font       = Theme.FontBold
    minimizeBtn.TextSize   = 15
    minimizeBtn.TextColor3 = Theme.Accent
    minimizeBtn.BorderSizePixel = 0
    minimizeBtn.AutoButtonColor = false
    minimizeBtn.ZIndex = 8
    minimizeBtn.Parent = titleBar
    Decorate(minimizeBtn, UDim.new(0,3), Theme.Border, 1)
    minimizeBtn.MouseEnter:Connect(function()
        tw(minimizeBtn,{BackgroundColor3=Theme.SurfaceAlt})
    end)
    minimizeBtn.MouseLeave:Connect(function()
        tw(minimizeBtn,{BackgroundColor3=Theme.Surface})
    end)

    MakeDraggable(titleBar, win, track)

    -- ── Tab button bar ───────────────────────────────────────────────
    local tabBar = Instance.new("ScrollingFrame")
    tabBar.Name                 = "TabBar"
    tabBar.BackgroundColor3     = Theme.TitleBar
    tabBar.BorderSizePixel      = 0
    tabBar.Size                 = UDim2.new(1,0,0,30)
    tabBar.Position             = UDim2.new(0,0,0,40)
    tabBar.ZIndex               = 5
    tabBar.ScrollingDirection   = Enum.ScrollingDirection.X
    tabBar.ScrollBarThickness   = 2
    tabBar.ScrollBarImageColor3 = Theme.AccentDim
    tabBar.CanvasSize           = UDim2.new(0,0,0,0)
    tabBar.AutomaticCanvasSize  = Enum.AutomaticSize.X
    tabBar.Parent               = win

    local tabBarList = Instance.new("UIListLayout")
    tabBarList.FillDirection = Enum.FillDirection.Horizontal
    tabBarList.SortOrder     = Enum.SortOrder.LayoutOrder
    tabBarList.Padding       = UDim.new(0, 2)
    tabBarList.Parent        = tabBar

    local tabBarPad = Instance.new("UIPadding")
    tabBarPad.PaddingLeft = UDim.new(0, 4)
    tabBarPad.Parent      = tabBar

    -- ── Content area ─────────────────────────────────────────────────
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

    local minimized = false
    minimizeBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            tabBar.Visible       = false
            contentArea.Visible  = false
            statusBar.Visible    = false
            tw(win, {Size = UDim2.new(0,W,0,40)}, Theme.TweenSlow)
        else
            tw(win, {Size = UDim2.new(0,W,0,H)}, Theme.TweenSlow)
            task.delay(0.32, function()
                if minimized then return end
                tabBar.Visible      = true
                contentArea.Visible = true
                statusBar.Visible   = true
            end)
        end
    end)

    local tabs       = {}
    local activeIdx  = 0
    local activeDropdownCloser = nil

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

    ------------------------------------------------------------------
    -- Window public API
    ------------------------------------------------------------------
    function Window:SetIcon(id)
        iconImg.Image = getIconAsset(id)
    end

    function Window:Destroy()
        for _, c in ipairs(connections) do
            pcall(function() c:Disconnect() end)
        end
        table.clear(connections)
        sg:Destroy()
    end

    if TOGGLEKEY then
        track(UserInputService.InputBegan:Connect(function(inp, processed)
            if processed then return end
            if inp.KeyCode == TOGGLEKEY then
                win.Visible = not win.Visible
            end
        end))
    end

    ----------------------------------------------------------------
    -- Window:CreateTab(name)
    ----------------------------------------------------------------
    function Window:CreateTab(name)
        name = tostring(name or "Tab")

        local textSize = TextService:GetTextSize(
            name:upper(), Theme.TextSizeSmall, Theme.FontMono, Vector2.new(1000, 20)
        )
        local btnWidth = math.clamp(textSize.X + 24, 64, 160)

        local btn = Instance.new("TextButton")
        btn.Name             = "TabBtn_" .. name
        btn.BackgroundColor3 = Theme.TabInactive
        btn.Size             = UDim2.new(0, btnWidth, 1, -6)
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

            local track2 = NewFrame({
                Color  = state and Theme.ToggleOn or Theme.ToggleOff,
                Size   = UDim2.new(0,44,0,22),
                Pos    = UDim2.new(1,-44,0.5,-11),
                Z      = 7,
                Parent = ef,
            })
            Decorate(track2, UDim.new(0,11), Theme.Border, 1)

            local knob = NewFrame({
                Color  = Theme.ToggleKnob,
                Size   = UDim2.new(0,16,0,16),
                Pos    = state and UDim2.new(1,-19,0.5,-8) or UDim2.new(0,3,0.5,-8),
                Z      = 8,
                Parent = track2,
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
                tw(track2, {BackgroundColor3 = state and Theme.ToggleOn or Theme.ToggleOff})
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
            local strack = NewFrame({
                Color  = Theme.SliderTrack,
                Size   = UDim2.new(1,0,0,8),
                Pos    = UDim2.new(0,0,0.5,-4),
                Z      = 7,
                Parent = botRow,
            })
            Decorate(strack, UDim.new(0,4), Theme.BorderDim, 1)

            local fill = NewFrame({
                Color  = Theme.SliderFill,
                Size   = UDim2.new((val-min)/(max-min), 0, 1, 0),
                Z      = 8,
                Parent = strack,
            })
            Decorate(fill, UDim.new(0,4), false)

            local knob = NewFrame({
                Color  = Theme.Accent,
                Size   = UDim2.new(0,14,0,14),
                Pos    = UDim2.new((val-min)/(max-min),-7,0.5,-7),
                Z      = 9,
                Parent = strack,
            })
            Decorate(knob, UDim.new(0,7), Theme.Background, 1)

            local dragging = false

            local function Recalc(absX)
                local pct    = math.clamp((absX - strack.AbsolutePosition.X) / strack.AbsoluteSize.X, 0, 1)
                local raw    = min + (max - min) * pct
                val          = math.clamp(math.floor((raw - min) / step + 0.5) * step + min, min, max)
                local newPct = (val - min) / (max - min)
                tw(fill,  {Size     = UDim2.new(newPct,0,1,0)})
                tw(knob,  {Position = UDim2.new(newPct,-7,0.5,-7)})
                valLbl.Text = tostring(val)
                pcall(cb, val)
            end

            track(strack.InputBegan:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1
                or inp.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    Recalc(inp.Position.X)
                end
            end))
            track(UserInputService.InputChanged:Connect(function(inp)
                if not dragging then return end
                if inp.UserInputType == Enum.UserInputType.MouseMovement
                or inp.UserInputType == Enum.UserInputType.Touch then
                    Recalc(inp.Position.X)
                end
            end))
            track(UserInputService.InputEnded:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1
                or inp.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                end
            end))

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

        function Tab:CreateDropdown(opts)
            opts = opts or {}
            local lbl      = opts.Label    or "Dropdown"
            local choices  = opts.Options  or {}
            local cb       = opts.Callback or function() end
            local selected = opts.Default  or choices[1] or "None"
            local open     = false
            local outsideConn = nil

            local ef = ElemFrame(38)
            ef.ClipsDescendants = false

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

            local maxDisplayed = 6
            local itemHeight = 28

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

            local Close, Open

            Close = function()
                if not open then return end
                open = false
                ef.ZIndex = 5
                tw(listFrame, {Size = UDim2.new(1, 0, 0, 0)})
                task.delay(0.16, function()
                    if not open then listFrame.Visible = false end
                end)
                if outsideConn then
                    outsideConn:Disconnect()
                    outsideConn = nil
                end
                if activeDropdownCloser == Close then
                    activeDropdownCloser = nil
                end
            end

            Open = function()
                if activeDropdownCloser and activeDropdownCloser ~= Close then
                    activeDropdownCloser()
                end
                open = true
                ef.ZIndex = 50
                listFrame.Visible = true

                local count = #choices
                local visibleCount = math.min(count, maxDisplayed)
                local targetHeight = visibleCount * itemHeight

                itemContainer.CanvasSize = UDim2.new(0, 0, 0, count * itemHeight)
                tw(listFrame, {Size = UDim2.new(1, 0, 0, targetHeight)})

                outsideConn = track(UserInputService.InputBegan:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1
                    or inp.UserInputType == Enum.UserInputType.Touch then
                        local pos = inp.Position
                        local a, s   = listFrame.AbsolutePosition, listFrame.AbsoluteSize
                        local ba, bs = dropBtn.AbsolutePosition, dropBtn.AbsoluteSize
                        local insideList = pos.X >= a.X and pos.X <= a.X + s.X and pos.Y >= a.Y and pos.Y <= a.Y + s.Y
                        local insideBtn  = pos.X >= ba.X and pos.X <= ba.X + bs.X and pos.Y >= ba.Y and pos.Y <= ba.Y + bs.Y
                        if not insideList and not insideBtn then
                            Close()
                        end
                    end
                end))
                activeDropdownCloser = Close
            end

            dropBtn.MouseButton1Click:Connect(function()
                if open then Close() else Open() end
            end)

            local function BuildChoices()
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
