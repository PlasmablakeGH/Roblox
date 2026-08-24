-- PlasmaLibUI v2.0.0
-- Drop-in Roblox Luau UI library with windows, tabs, components, themes,
-- notifications, keybinds, color picker, multi-dropdown, search, configs,
-- lifecycle cleanup, responsive sizing, keyboard navigation and effects.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local TextService = game:GetService("TextService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

local Theme = {
    Background = Color3.fromRGB(7, 10, 8),
    Surface = Color3.fromRGB(11, 17, 12),
    SurfaceAlt = Color3.fromRGB(17, 27, 18),
    SurfaceBright = Color3.fromRGB(23, 36, 24),
    Border = Color3.fromRGB(0, 220, 85),
    BorderDim = Color3.fromRGB(0, 90, 36),
    Accent = Color3.fromRGB(0, 255, 105),
    AccentDim = Color3.fromRGB(0, 155, 62),
    TextPrimary = Color3.fromRGB(205, 255, 215),
    TextSecondary = Color3.fromRGB(90, 190, 112),
    TextMuted = Color3.fromRGB(55, 105, 66),
    TextDisabled = Color3.fromRGB(45, 70, 48),
    Danger = Color3.fromRGB(255, 65, 65),
    Warning = Color3.fromRGB(255, 190, 65),
    Info = Color3.fromRGB(85, 175, 255),
    Success = Color3.fromRGB(0, 255, 105),
    SliderFill = Color3.fromRGB(0, 235, 95),
    SliderTrack = Color3.fromRGB(13, 31, 16),
    ToggleOn = Color3.fromRGB(0, 205, 80),
    ToggleOff = Color3.fromRGB(20, 40, 22),
    ToggleKnob = Color3.fromRGB(225, 255, 230),
    Scanline = Color3.fromRGB(0, 255, 100),
    TabActive = Color3.fromRGB(0, 205, 78),
    TabInactive = Color3.fromRGB(0, 43, 18),
    TitleBar = Color3.fromRGB(5, 13, 6),
    Shadow = Color3.fromRGB(0, 0, 0),
    Overlay = Color3.fromRGB(0, 0, 0),
    CornerRadius = UDim.new(0, 5),
    BorderThickness = 1,
    FontMono = Enum.Font.Code,
    FontUI = Enum.Font.GothamMedium,
    FontBold = Enum.Font.GothamBold,
    TextSizeTitle = 15,
    TextSizeBody = 13,
    TextSizeSmall = 11,
    AnimationScale = 1,
    Tween = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    TweenFast = TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    TweenSlow = TweenInfo.new(0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
}

local Presets = {
    Plasma = {
        Accent = Color3.fromRGB(0, 255, 105), Border = Color3.fromRGB(0, 220, 85),
        Background = Color3.fromRGB(7, 10, 8), Surface = Color3.fromRGB(11, 17, 12),
        SurfaceAlt = Color3.fromRGB(17, 27, 18), SurfaceBright = Color3.fromRGB(23, 36, 24),
        TextPrimary = Color3.fromRGB(205, 255, 215), TextSecondary = Color3.fromRGB(90, 190, 112),
        TabActive = Color3.fromRGB(0, 205, 78), TabInactive = Color3.fromRGB(0, 43, 18), TitleBar = Color3.fromRGB(5, 13, 6),
    },
    Matrix = {
        Accent = Color3.fromRGB(80, 255, 80), Border = Color3.fromRGB(55, 200, 55),
        Background = Color3.fromRGB(1, 5, 1), Surface = Color3.fromRGB(4, 12, 4),
        SurfaceAlt = Color3.fromRGB(8, 20, 8), SurfaceBright = Color3.fromRGB(12, 30, 12),
        TextPrimary = Color3.fromRGB(180, 255, 180), TextSecondary = Color3.fromRGB(80, 180, 80),
        TabActive = Color3.fromRGB(50, 180, 50), TabInactive = Color3.fromRGB(10, 40, 10), TitleBar = Color3.fromRGB(1, 8, 1),
    },
    Cyberpunk = {
        Accent = Color3.fromRGB(255, 55, 220), Border = Color3.fromRGB(0, 220, 255),
        Background = Color3.fromRGB(9, 7, 14), Surface = Color3.fromRGB(15, 11, 23),
        SurfaceAlt = Color3.fromRGB(24, 16, 34), SurfaceBright = Color3.fromRGB(32, 20, 46),
        TextPrimary = Color3.fromRGB(245, 225, 255), TextSecondary = Color3.fromRGB(185, 115, 220),
        TabActive = Color3.fromRGB(255, 55, 220), TabInactive = Color3.fromRGB(65, 15, 58), TitleBar = Color3.fromRGB(10, 6, 16),
    },
    Amber = {
        Accent = Color3.fromRGB(255, 190, 55), Border = Color3.fromRGB(235, 160, 30),
        Background = Color3.fromRGB(12, 10, 5), Surface = Color3.fromRGB(20, 16, 8),
        SurfaceAlt = Color3.fromRGB(31, 24, 12), SurfaceBright = Color3.fromRGB(45, 34, 15),
        TextPrimary = Color3.fromRGB(255, 235, 180), TextSecondary = Color3.fromRGB(210, 165, 75),
        TabActive = Color3.fromRGB(235, 165, 30), TabInactive = Color3.fromRGB(58, 39, 8), TitleBar = Color3.fromRGB(12, 9, 4),
    },
    Minimal = {
        Accent = Color3.fromRGB(230, 230, 230), Border = Color3.fromRGB(90, 90, 90),
        Background = Color3.fromRGB(17, 17, 17), Surface = Color3.fromRGB(23, 23, 23),
        SurfaceAlt = Color3.fromRGB(31, 31, 31), SurfaceBright = Color3.fromRGB(42, 42, 42),
        TextPrimary = Color3.fromRGB(245, 245, 245), TextSecondary = Color3.fromRGB(175, 175, 175),
        TabActive = Color3.fromRGB(210, 210, 210), TabInactive = Color3.fromRGB(45, 45, 45), TitleBar = Color3.fromRGB(13, 13, 13),
    },
    Frost = {
        Accent = Color3.fromRGB(95, 210, 255), Border = Color3.fromRGB(75, 175, 225),
        Background = Color3.fromRGB(5, 11, 15), Surface = Color3.fromRGB(10, 20, 27),
        SurfaceAlt = Color3.fromRGB(15, 29, 39), SurfaceBright = Color3.fromRGB(23, 42, 55),
        TextPrimary = Color3.fromRGB(220, 245, 255), TextSecondary = Color3.fromRGB(120, 190, 220),
        TabActive = Color3.fromRGB(75, 175, 225), TabInactive = Color3.fromRGB(18, 48, 65), TitleBar = Color3.fromRGB(4, 10, 14),
    },
}

local Library = {}
Library.__index = Library
Library.Theme = Theme
Library.Presets = Presets
Library.Windows = {}
Library.Debug = false
Library.ReducedMotion = false
Library.Configs = {}
Library._windowSerial = 0
Library._themeListeners = {}
Library._notifications = {}
Library._themes = {}

local function now()
    return os.clock()
end

local function safeCallback(fn, ...)
    if typeof(fn) ~= "function" then return true end
    local args = table.pack(...)
    local ok, err = xpcall(function()
        fn(table.unpack(args, 1, args.n))
    end, debug.traceback)
    if not ok and Library.Debug then
        warn("[PlasmaLibUI] Callback error:\n" .. tostring(err))
    end
    return ok, err
end

local function copyTable(t)
    local out = {}
    for k, v in pairs(t or {}) do
        if type(v) == "table" then out[k] = copyTable(v) else out[k] = v end
    end
    return out
end

local function mergeTables(base, overlay)
    local out = copyTable(base)
    for k, v in pairs(overlay or {}) do out[k] = v end
    return out
end

local Maid = {}
Maid.__index = Maid
function Maid.new()
    return setmetatable({Tasks = {}, Destroyed = false}, Maid)
end
function Maid:Give(taskItem)
    if self.Destroyed then
        if typeof(taskItem) == "RBXScriptConnection" then taskItem:Disconnect()
        elseif typeof(taskItem) == "Instance" then taskItem:Destroy()
        elseif type(taskItem) == "function" then pcall(taskItem)
        elseif type(taskItem) == "table" and taskItem.Destroy then pcall(taskItem.Destroy, taskItem) end
        return taskItem
    end
    table.insert(self.Tasks, taskItem)
    return taskItem
end
function Maid:GiveFunction(fn) return self:Give(fn) end
function Maid:Cleanup()
    for i = #self.Tasks, 1, -1 do
        local item = self.Tasks[i]
        local kind = typeof(item)
        if kind == "RBXScriptConnection" then pcall(function() item:Disconnect() end)
        elseif kind == "Instance" then pcall(function() item:Destroy() end)
        elseif type(item) == "function" then pcall(item)
        elseif type(item) == "table" then
            if item.Destroy then pcall(item.Destroy, item) elseif item.Disconnect then pcall(item.Disconnect, item) end
        end
        self.Tasks[i] = nil
    end
end
function Maid:Destroy()
    if self.Destroyed then return end
    self.Destroyed = true
    self:Cleanup()
end

local TweenManager = {}
TweenManager.__index = TweenManager
function TweenManager.new(maid)
    return setmetatable({Maid = maid, Active = setmetatable({}, {__mode = "k"})}, TweenManager)
end
function TweenManager:Play(obj, props, info, key)
    if not obj or obj.Parent == nil then return nil end
    if Library.ReducedMotion then
        for k, v in pairs(props) do pcall(function() obj[k] = v end) end
        return nil
    end
    info = info or Theme.Tween
    local bucket = self.Active[obj]
    if not bucket then bucket = {}; self.Active[obj] = bucket end
    key = key or "__default"
    if bucket[key] then pcall(function() bucket[key]:Cancel() end) end
    local tween = TweenService:Create(obj, info, props)
    bucket[key] = tween
    tween.Completed:Connect(function()
        if bucket[key] == tween then bucket[key] = nil end
    end)
    self.Maid:Give(tween.Completed:Connect(function() end))
    tween:Play()
    return tween
end
function TweenManager:Cancel(obj, key)
    local bucket = self.Active[obj]
    if not bucket then return end
    if key then
        if bucket[key] then pcall(function() bucket[key]:Cancel() end); bucket[key] = nil end
    else
        for k, tween in pairs(bucket) do pcall(function() tween:Cancel() end); bucket[k] = nil end
    end
end

local function getGuiParent(explicit)
    if explicit then return explicit end
    if typeof(gethui) == "function" then
        local ok, result = pcall(gethui)
        if ok and result then return result end
    end
    local ok, core = pcall(function() return game:GetService("CoreGui") end)
    if ok and core then return core end
    return LocalPlayer:WaitForChild("PlayerGui")
end

local function decorate(obj, radius, strokeColor, strokeThickness)
    local corner = obj:FindFirstChildOfClass("UICorner") or Instance.new("UICorner")
    corner.CornerRadius = radius or Theme.CornerRadius
    corner.Parent = obj
    if strokeColor ~= false then
        local stroke = obj:FindFirstChildOfClass("UIStroke") or Instance.new("UIStroke")
        stroke.Color = strokeColor or Theme.BorderDim
        stroke.Thickness = strokeThickness or Theme.BorderThickness
        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        stroke.Transparency = 0
        stroke.Parent = obj
    end
end

local function label(parent, text, props)
    props = props or {}
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Text = tostring(text or "")
    l.TextColor3 = props.Color or Theme.TextPrimary
    l.Font = props.Font or Theme.FontUI
    l.TextSize = props.TextSize or Theme.TextSizeBody
    l.TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left
    l.TextYAlignment = props.TextYAlignment or Enum.TextYAlignment.Center
    l.TextTruncate = props.Wrap and Enum.TextTruncate.None or Enum.TextTruncate.AtEnd
    l.TextWrapped = props.Wrap or false
    l.RichText = props.RichText or false
    l.Size = props.Size or UDim2.fromScale(1, 1)
    l.Position = props.Position or UDim2.fromOffset(0, 0)
    l.AnchorPoint = props.AnchorPoint or Vector2.zero
    l.ZIndex = props.ZIndex or 5
    l.LayoutOrder = props.LayoutOrder or 0
    l.Parent = parent
    return l
end

local function frame(parent, props)
    props = props or {}
    local f = Instance.new("Frame")
    f.BackgroundColor3 = props.Color or Theme.Surface
    f.BackgroundTransparency = props.Transparency or 0
    f.BorderSizePixel = 0
    f.Size = props.Size or UDim2.fromScale(1, 1)
    f.Position = props.Position or UDim2.fromOffset(0, 0)
    f.AnchorPoint = props.AnchorPoint or Vector2.zero
    f.ZIndex = props.ZIndex or 4
    f.Name = props.Name or "Frame"
    f.ClipsDescendants = props.ClipsDescendants or false
    f.Visible = props.Visible ~= false
    f.LayoutOrder = props.LayoutOrder or 0
    f.Parent = parent
    return f
end

local function button(parent, props)
    props = props or {}
    local b = Instance.new("TextButton")
    b.AutoButtonColor = false
    b.BackgroundColor3 = props.Color or Theme.Surface
    b.BorderSizePixel = 0
    b.Text = props.Text or ""
    b.TextColor3 = props.TextColor or Theme.Accent
    b.Font = props.Font or Theme.FontMono
    b.TextSize = props.TextSize or Theme.TextSizeBody
    b.Size = props.Size or UDim2.fromScale(1, 1)
    b.Position = props.Position or UDim2.fromOffset(0, 0)
    b.AnchorPoint = props.AnchorPoint or Vector2.zero
    b.ZIndex = props.ZIndex or 7
    b.TextWrapped = props.TextWrapped or false
    b.ClipsDescendants = props.ClipsDescendants or false
    b.Name = props.Name or "Button"
    b.Parent = parent
    decorate(b, props.CornerRadius or UDim.new(0, 4), props.Stroke == false and false or (props.Stroke or Theme.BorderDim), props.StrokeThickness or 1)
    return b
end

local function addScanlines(parent, height)
    local overlay = frame(parent, {Color = Theme.Scanline, Transparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 55, Name = "Scanlines", ClipsDescendants = true})
    local count = math.clamp(math.floor(height / 5), 16, 70)
    for i = 1, count do
        local line = frame(overlay, {
            Color = Theme.Scanline,
            Transparency = 0.975,
            Size = UDim2.new(1, 0, 0, 1),
            Position = UDim2.new(0, 0, (i - 1) / count, 0),
            ZIndex = 56,
            Name = "Line" .. i,
        })
    end
    return overlay
end

local function makeShadow(parent)
    local shadow = frame(parent, {
        Color = Theme.Shadow,
        Transparency = 0.45,
        Size = UDim2.new(1, 18, 1, 18),
        Position = UDim2.fromOffset(9, 9),
        ZIndex = 0,
        Name = "Shadow",
    })
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 7)
    corner.Parent = shadow
    return shadow
end

local Signal = {}
Signal.__index = Signal
function Signal.new()
    return setmetatable({Listeners = {}, Destroyed = false}, Signal)
end
function Signal:Connect(fn)
    if self.Destroyed or type(fn) ~= "function" then return {Disconnect = function() end} end
    local conn = {Connected = true}
    function conn:Disconnect()
        if not self.Connected then return end
        self.Connected = false
        for i, listener in ipairs(self._owner.Listeners) do
            if listener == self._fn then table.remove(self._owner.Listeners, i); break end
        end
    end
    conn._owner = self
    conn._fn = fn
    table.insert(self.Listeners, fn)
    return conn
end
function Signal:Fire(...)
    if self.Destroyed then return end
    for _, fn in ipairs(table.clone(self.Listeners)) do safeCallback(fn, ...) end
end
function Signal:Destroy()
    self.Destroyed = true
    table.clear(self.Listeners)
end

function Library:_trackTheme(fn)
    table.insert(self._themeListeners, fn)
end
function Library:_notifyTheme()
    for _, fn in ipairs(table.clone(self._themeListeners)) do safeCallback(fn, Theme) end
end
function Library:GetTheme()
    return copyTable(Theme)
end
function Library:RegisterTheme(name, values)
    self._themes[name] = mergeTables(Presets.Plasma, values or {})
    return self._themes[name]
end
function Library:ApplyTheme(nameOrTable)
    local values = type(nameOrTable) == "string" and (self._themes[nameOrTable] or Presets[nameOrTable]) or nameOrTable
    if not values then return false end
    for k, v in pairs(values) do if Theme[k] ~= nil then Theme[k] = v end end
    self:_notifyTheme()
    return true
end
function Library:SetTheme(overrides)
    return self:ApplyTheme(overrides)
end

for name, values in pairs(Presets) do Library:RegisterTheme(name, values) end

function Library:_nextWindowId(title)
    self._windowSerial += 1
    local slug = tostring(title or "Window"):gsub("%W", "")
    return (slug ~= "" and slug or "Window") .. "_" .. self._windowSerial
end

function Library:_notifyOptions(opts)
    local duration = math.max(0.5, tonumber(opts.Duration or 3) or 3)
    local holder = self._notificationHolder
    if not holder then return end
    local row = frame(holder, {Color = Theme.Surface, Size = UDim2.new(1, 0, 0, 70), ZIndex = 200})
    decorate(row, UDim.new(0, 6), Theme.BorderDim, 1)
    local accent = frame(row, {Color = opts.Color or Theme.Accent, Size = UDim2.new(0, 3, 1, 0), ZIndex = 202})
    label(row, opts.Title or "NOTIFICATION", {Color = opts.Color or Theme.Accent, Font = Theme.FontMono, TextSize = 12, Size = UDim2.new(1, -20, 0, 20), Position = UDim2.fromOffset(12, 7), ZIndex = 203})
    label(row, opts.Description or opts.Text or "", {Color = Theme.TextPrimary, Font = Theme.FontUI, TextSize = 11, Size = UDim2.new(1, -20, 0, 38), Position = UDim2.fromOffset(12, 27), Wrap = true, ZIndex = 203})
    row.BackgroundTransparency = 1
    local targetPosition = UDim2.fromOffset(0, 0)
    TweenService:Create(row, Theme.Tween, {BackgroundTransparency = 0}):Play()
    task.delay(duration, function()
        if row.Parent then
            local out = TweenService:Create(row, Theme.Tween, {BackgroundTransparency = 1})
            out:Play()
            out.Completed:Connect(function() if row.Parent then row:Destroy() end end)
        end
    end)
    return row
end

function Library:Notify(opts)
    opts = type(opts) == "table" and opts or {Description = tostring(opts)}
    local kind = opts.Type or "Info"
    opts.Color = opts.Color or ({
        Info = Theme.Info, Success = Theme.Success, Warning = Theme.Warning, Error = Theme.Danger, Debug = Theme.TextSecondary,
    })[kind] or Theme.Accent
    return self:_notifyOptions(opts)
end

function Library:_ensureNotificationHolder(parent)
    if self._notificationHolder and self._notificationHolder.Parent then return end
    self._notificationHolder = Instance.new("Frame")
    self._notificationHolder.BackgroundTransparency = 1
    self._notificationHolder.AnchorPoint = Vector2.new(1, 1)
    self._notificationHolder.Position = UDim2.new(1, -18, 1, -18)
    self._notificationHolder.Size = UDim2.fromOffset(320, 0)
    self._notificationHolder.AutomaticSize = Enum.AutomaticSize.Y
    self._notificationHolder.ZIndex = 190
    self._notificationHolder.Parent = parent
    local layout = Instance.new("UIListLayout")
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    layout.Padding = UDim.new(0, 6)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = self._notificationHolder
end

function Library:GetWindow(name)
    return self.Windows[name]
end
function Library:DestroyAll()
    for _, win in pairs(table.clone(self.Windows)) do pcall(function() win:Destroy() end) end
    table.clear(self.Windows)
end
function Library:SetReducedMotion(enabled)
    self.ReducedMotion = enabled == true
end

function Library:CreateWindow(opts)
    opts = opts or {}
    local title = tostring(opts.Title or "PlasmaLibUI")
    local width = tonumber(opts.Width) or 520
    local height = tonumber(opts.Height) or 410
    local minWidth = tonumber(opts.MinWidth) or 320
    local maxWidth = tonumber(opts.MaxWidth) or 900
    local minHeight = tonumber(opts.MinHeight) or 260
    local maxHeight = tonumber(opts.MaxHeight) or 800
    local toggleKey = opts.ToggleKey
    local parent = getGuiParent(opts.Parent)
    local id = self:_nextWindowId(title)

    width = math.clamp(width, minWidth, maxWidth)
    height = math.clamp(height, minHeight, maxHeight)

    local maid = Maid.new()
    local tween = TweenManager.new(maid)
    local windowSignals = {
        VisibilityChanged = Signal.new(),
        TabChanged = Signal.new(),
        Destroyed = Signal.new(),
        StateChanged = Signal.new(),
    }
    maid:Give(windowSignals.VisibilityChanged)
    maid:Give(windowSignals.TabChanged)
    maid:Give(windowSignals.Destroyed)
    maid:Give(windowSignals.StateChanged)

    local sg = Instance.new("ScreenGui")
    sg.Name = "PlasmaLibUI_" .. id
    sg.ResetOnSpawn = false
    sg.IgnoreGuiInset = true
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.DisplayOrder = tonumber(opts.DisplayOrder) or 999
    sg.Parent = parent
    maid:Give(sg)

    self:_ensureNotificationHolder(sg)

    local holder = frame(sg, {Color = Theme.Overlay, Transparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 0, Name = "WindowRoot"})
    local shadow = makeShadow(holder)
    local win = frame(holder, {
        Name = "Window",
        Color = Theme.Background,
        Size = UDim2.fromOffset(width, 0),
        Position = UDim2.new(0.5, -width / 2, 0.5, -height / 2),
        ZIndex = 2,
        ClipsDescendants = true,
    })
    decorate(win, UDim.new(0, 6), Theme.Border, Theme.BorderThickness)
    if opts.Scanlines ~= false then addScanlines(win, height) end
    frame(win, {Color = Theme.Accent, Size = UDim2.new(1, 0, 0, 2), ZIndex = 70, Name = "AccentLine"})

    local window = {
        Id = id,
        Name = title,
        Gui = sg,
        Root = holder,
        Frame = win,
        Maid = maid,
        Tween = tween,
        Signals = windowSignals,
        Components = {},
        Tabs = {},
        State = {
            Visible = true,
            Minimized = false,
            Destroyed = false,
        },
        Width = width,
        Height = height,
        MinWidth = minWidth,
        MaxWidth = maxWidth,
        MinHeight = minHeight,
        MaxHeight = maxHeight,
    }
    window.__index = window
    self.Windows[id] = window
    if opts.SingletonName then
        if self.Windows[opts.SingletonName] and self.Windows[opts.SingletonName] ~= window then
            pcall(function() self.Windows[opts.SingletonName]:Destroy() end)
        end
        self.Windows[opts.SingletonName] = window
        window.SingletonName = opts.SingletonName
    end

    local titleBar = frame(win, {Color = Theme.TitleBar, Size = UDim2.new(1, 0, 0, 40), Position = UDim2.fromOffset(0, 2), ZIndex = 60, Name = "TitleBar"})
    local titleIcon = Instance.new("ImageLabel")
    titleIcon.BackgroundTransparency = 1
    titleIcon.Image = opts.IconId or "rbxassetid://7072706620"
    titleIcon.ImageColor3 = Theme.Accent
    titleIcon.Size = UDim2.fromOffset(23, 23)
    titleIcon.Position = UDim2.fromOffset(9, 8)
    titleIcon.ZIndex = 65
    titleIcon.Parent = titleBar
    local titleText = label(titleBar, "[ " .. title:upper() .. " ]", {
        Color = Theme.Accent, Font = Theme.FontMono, TextSize = Theme.TextSizeTitle,
        Size = UDim2.new(1, -118, 1, 0), Position = UDim2.fromOffset(40, 0), ZIndex = 65,
    })
    local statusDot = frame(titleBar, {Color = Theme.Success, Size = UDim2.fromOffset(6, 6), Position = UDim2.new(1, -108, 0.5, -3), ZIndex = 66})
    decorate(statusDot, UDim.new(1, 0), false)

    local minimize = button(titleBar, {Text = "_", Color = Theme.Surface, TextColor = Theme.Accent, Size = UDim2.fromOffset(28, 21), Position = UDim2.new(1, -68, 0.5, -10), ZIndex = 68, Stroke = Theme.BorderDim, Name = "Minimize"})
    local close = button(titleBar, {Text = "×", Color = Color3.fromRGB(35, 9, 9), TextColor = Theme.Danger, Size = UDim2.fromOffset(28, 21), Position = UDim2.new(1, -36, 0.5, -10), ZIndex = 68, Stroke = Theme.Danger, Name = "Close"})
    local dragStrip = button(titleBar, {Text = "", Color = Theme.TitleBar, Size = UDim2.new(1, -115, 1, 0), Position = UDim2.fromOffset(0, 0), ZIndex = 64, Stroke = false, Name = "DragStrip"})
    dragStrip.Text = ""
    dragStrip.BackgroundTransparency = 1

    local tabBar = Instance.new("ScrollingFrame")
    tabBar.Name = "TabBar"
    tabBar.BackgroundColor3 = Theme.TitleBar
    tabBar.BorderSizePixel = 0
    tabBar.Size = UDim2.new(1, 0, 0, 32)
    tabBar.Position = UDim2.fromOffset(0, 42)
    tabBar.ScrollBarThickness = 2
    tabBar.ScrollBarImageColor3 = Theme.AccentDim
    tabBar.ScrollingDirection = Enum.ScrollingDirection.X
    tabBar.AutomaticCanvasSize = Enum.AutomaticSize.X
    tabBar.CanvasSize = UDim2.new()
    tabBar.ZIndex = 60
    tabBar.Parent = win
    local tabList = Instance.new("UIListLayout")
    tabList.FillDirection = Enum.FillDirection.Horizontal
    tabList.Padding = UDim.new(0, 3)
    tabList.SortOrder = Enum.SortOrder.LayoutOrder
    tabList.Parent = tabBar
    local tabPad = Instance.new("UIPadding")
    tabPad.PaddingLeft = UDim.new(0, 5)
    tabPad.PaddingRight = UDim.new(0, 5)
    tabPad.PaddingTop = UDim.new(0, 3)
    tabPad.Parent = tabBar

    local contentTop = 74
    local statusHeight = 20
    local content = frame(win, {Color = Theme.Background, Size = UDim2.new(1, 0, 1, -(contentTop + statusHeight)), Position = UDim2.fromOffset(0, contentTop), ZIndex = 4, Name = "ContentArea"})
    local status = frame(win, {Color = Theme.TitleBar, Size = UDim2.new(1, 0, 0, statusHeight), Position = UDim2.new(0, 0, 1, -statusHeight), ZIndex = 60, Name = "StatusBar"})
    local statusLabel = label(status, "◈ PLASMALIB // ONLINE", {Color = Theme.BorderDim, Font = Theme.FontMono, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 65})

    window.TitleBar = titleBar
    window.TabBar = tabBar
    window.Content = content
    window.StatusBar = status
    window.TitleLabel = titleText
    window.Icon = titleIcon
    window.StatusLabel = statusLabel

    local dragging = false
    local dragStart = Vector2.zero
    local startPos = win.Position
    local function clampWindow(pos)
        local camera = workspace.CurrentCamera
        local viewport = camera and camera.ViewportSize or Vector2.new(1920, 1080)
        local size = win.AbsoluteSize
        local visible = 42
        local x = math.clamp(pos.X.Offset, visible - size.X - viewport.X * pos.X.Scale, viewport.X - visible - viewport.X * pos.X.Scale)
        local y = math.clamp(pos.Y.Offset, visible - size.Y - viewport.Y * pos.Y.Scale, viewport.Y - visible - viewport.Y * pos.Y.Scale)
        return UDim2.new(pos.X.Scale, x, pos.Y.Scale, y)
    end
    maid:Give(dragStrip.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
        dragging = true
        dragStart = input.Position
        startPos = win.Position
        maid:Give(input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end))
    end))
    maid:Give(UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
        local delta = input.Position - dragStart
        win.Position = clampWindow(UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y))
    end))

    function window:Center()
        win.Position = UDim2.new(0.5, -win.AbsoluteSize.X / 2, 0.5, -win.AbsoluteSize.Y / 2)
    end
    function window:SetIcon(idValue) titleIcon.Image = tostring(idValue or "") end
    function window:SetTitle(textValue)
        title = tostring(textValue or "PlasmaLibUI")
        window.Name = title
        titleText.Text = "[ " .. title:upper() .. " ]"
    end
    function window:IsDestroyed() return self.State.Destroyed end
    function window:IsVisible() return self.State.Visible end
    function window:SetVisible(visible)
        if self.State.Destroyed then return end
        visible = visible == true
        self.State.Visible = visible
        holder.Visible = visible
        windowSignals.VisibilityChanged:Fire(visible)
    end
    function window:Show() self:SetVisible(true) end
    function window:Hide() self:SetVisible(false) end
    function window:Minimize()
        if self.State.Minimized or self.State.Destroyed then return end
        self.State.Minimized = true
        tabBar.Visible, content.Visible, status.Visible = false, false, false
        tween:Play(win, {Size = UDim2.fromOffset(width, 42)}, Theme.TweenSlow, "windowSize")
        windowSignals.StateChanged:Fire("Minimized", true)
    end
    function window:Restore()
        if not self.State.Minimized or self.State.Destroyed then return end
        self.State.Minimized = false
        tween:Play(win, {Size = UDim2.fromOffset(width, height)}, Theme.TweenSlow, "windowSize")
        task.delay(Library.ReducedMotion and 0 or 0.2, function()
            if not self.State.Minimized and not self.State.Destroyed then tabBar.Visible, content.Visible, status.Visible = true, true, true end
        end)
        windowSignals.StateChanged:Fire("Minimized", false)
    end
    function window:Snap(side)
        local camera = workspace.CurrentCamera
        local vp = camera and camera.ViewportSize or Vector2.new(1920, 1080)
        if side == "Left" then win.Position = UDim2.fromOffset(8, math.max(8, vp.Y / 2 - win.AbsoluteSize.Y / 2))
        elseif side == "Right" then win.Position = UDim2.new(1, -win.AbsoluteSize.X - 8, 0.5, -win.AbsoluteSize.Y / 2)
        elseif side == "Top" then win.Position = UDim2.new(0.5, -win.AbsoluteSize.X / 2, 0, 8)
        elseif side == "Bottom" then win.Position = UDim2.new(0.5, -win.AbsoluteSize.X / 2, 1, -win.AbsoluteSize.Y - 8) end
    end
    function window:Destroy()
        if self.State.Destroyed then return end
        self.State.Destroyed = true
        self.State.Visible = false
        self.Signals.Destroyed:Fire(self)
        if self.SingletonName and self.Windows and self.Windows[self.SingletonName] == self then self.Windows[self.SingletonName] = nil end
        self.Windows[id] = nil
        for _, component in pairs(self.Components) do pcall(function() component:Destroy() end) end
        maid:Destroy()
    end

    maid:Give(minimize.MouseEnter:Connect(function() tween:Play(minimize, {BackgroundColor3 = Theme.SurfaceBright}, Theme.TweenFast, "hover") end))
    maid:Give(minimize.MouseLeave:Connect(function() tween:Play(minimize, {BackgroundColor3 = Theme.Surface}, Theme.TweenFast, "hover") end))
    maid:Give(minimize.MouseButton1Click:Connect(function() if window.State.Minimized then window:Restore() else window:Minimize() end end))
    maid:Give(close.MouseEnter:Connect(function() tween:Play(close, {BackgroundColor3 = Theme.Danger, TextColor3 = Color3.new(1, 1, 1)}, Theme.TweenFast, "hover") end))
    maid:Give(close.MouseLeave:Connect(function() tween:Play(close, {BackgroundColor3 = Color3.fromRGB(35, 9, 9), TextColor3 = Theme.Danger}, Theme.TweenFast, "hover") end))
    maid:Give(close.MouseButton1Click:Connect(function() window:Destroy() end))
    maid:Give(dragStrip.MouseButton1DoubleClick:Connect(function() if window.State.Minimized then window:Restore() else window:Minimize() end end))

    if toggleKey then
        maid:Give(UserInputService.InputBegan:Connect(function(input, processed)
            if processed or window.State.Destroyed then return end
            if input.KeyCode == toggleKey then window:SetVisible(not window.State.Visible) end
        end))
    end

    local activeTab = 0
    local searchText = ""
    window.SearchText = ""

    local function setActiveTab(index)
        if window.State.Destroyed then return end
        if not window.Tabs[index] then return end
        activeTab = index
        for i, entry in ipairs(window.Tabs) do
            local active = i == index
            entry.Page.Visible = active
            tween:Play(entry.Button, {
                BackgroundColor3 = active and Theme.TabActive or Theme.TabInactive,
                TextColor3 = active and Theme.Background or Theme.TextSecondary,
            }, Theme.Tween, "tabStyle")
        end
        tabBar.CanvasPosition = Vector2.new(math.max(0, window.Tabs[index].Button.AbsolutePosition.X - tabBar.AbsolutePosition.X - 18), 0)
        window.Signals.TabChanged:Fire(window.Tabs[index], index)
    end
    window.SetActiveTab = setActiveTab

    local function registerComponent(component)
        if component and component.Id then
            window.Components[component.Id] = component
        end
        return component
    end

    local function componentId(kind)
        window._componentSerial = (window._componentSerial or 0) + 1
        return kind .. "_" .. window._componentSerial
    end

    local searchButton = button(titleBar, {Text = "/", Color = Theme.Surface, TextColor = Theme.TextSecondary, Size = UDim2.fromOffset(24, 21), Position = UDim2.new(1, -100, 0.5, -10), ZIndex = 68, Stroke = Theme.BorderDim, Name = "SearchButton"})
    local searchBox
    local searchPanel
    local function buildSearch()
        if searchPanel then searchPanel:Destroy(); searchPanel = nil; searchBox = nil end
        if searchText == "" then return end
        local currentTab = window.Tabs[activeTab]
        if not currentTab then return end
        for _, component in pairs(currentTab.Components) do
            local hay = (component.SearchText or component.Label or component.Name or ""):lower()
            local visible = hay:find(searchText:lower(), 1, true) ~= nil
            if component.Root then component.Root.Visible = visible end
        end
    end
    maid:Give(searchButton.MouseButton1Click:Connect(function()
        if searchPanel then searchPanel:Destroy(); searchPanel = nil; searchBox = nil; return end
        searchPanel = frame(win, {Color = Theme.TitleBar, Size = UDim2.new(0, 260, 0, 34), Position = UDim2.new(1, -270, 0, 41), ZIndex = 120, Name = "SearchPanel"})
        decorate(searchPanel, UDim.new(0, 5), Theme.Border, 1)
        searchBox = Instance.new("TextBox")
        searchBox.BackgroundTransparency = 1
        searchBox.ClearTextOnFocus = false
        searchBox.Text = searchText
        searchBox.PlaceholderText = "search components..."
        searchBox.PlaceholderColor3 = Theme.TextMuted
        searchBox.TextColor3 = Theme.Accent
        searchBox.Font = Theme.FontMono
        searchBox.TextSize = 12
        searchBox.TextXAlignment = Enum.TextXAlignment.Left
        searchBox.Size = UDim2.new(1, -16, 1, 0)
        searchBox.Position = UDim2.fromOffset(8, 0)
        searchBox.ZIndex = 122
        searchBox.Parent = searchPanel
        maid:Give(searchBox:GetPropertyChangedSignal("Text"):Connect(function()
            searchText = searchBox.Text
            window.SearchText = searchText
            buildSearch()
        end))
        searchBox:CaptureFocus()
    end))

    local function commonComponent(root, kind, userLabel)
        local component = {
            Id = componentId(kind),
            Type = kind,
            Root = root,
            Label = tostring(userLabel or kind),
            SearchText = tostring(userLabel or kind),
            State = {Destroyed = false, Disabled = false, Visible = true},
            Signals = {Changed = Signal.new()},
            Maid = Maid.new(),
        }
        component.Name = component.Label
        function component:IsDestroyed() return self.State.Destroyed end
        function component:SetVisible(v) self.State.Visible = v == true; root.Visible = self.State.Visible end
        function component:SetDisabled(v)
            self.State.Disabled = v == true
            root.BackgroundTransparency = self.State.Disabled and 0.45 or 0
        end
        function component:Destroy()
            if self.State.Destroyed then return end
            self.State.Destroyed = true
            self.Signals.Changed:Destroy()
            self.Maid:Destroy()
            if entry and entry.Components then entry.Components[self.Id] = nil end
            if root.Parent then root:Destroy() end
        end
        window._themeMaid = window._themeMaid or Maid.new()
        table.insert(window.Components, component)
        for _, sig in pairs(component.Signals) do component.Maid:Give(sig) end
        return component
    end

    function window:CreateTab(name)
        name = tostring(name or "Tab")
        local textSize = TextService:GetTextSize(name:upper(), Theme.TextSizeSmall, Theme.FontMono, Vector2.new(1000, 20))
        local tabButton = button(tabBar, {Text = name:upper(), Color = Theme.TabInactive, TextColor = Theme.TextSecondary, Font = Theme.FontMono, TextSize = Theme.TextSizeSmall, Size = UDim2.fromOffset(math.clamp(textSize.X + 28, 70, 190), 26), ZIndex = 65, Stroke = false, Name = "Tab_" .. name})
        local page = Instance.new("ScrollingFrame")
        page.BackgroundTransparency = 1
        page.BorderSizePixel = 0
        page.Size = UDim2.fromScale(1, 1)
        page.ScrollBarThickness = 3
        page.ScrollBarImageColor3 = Theme.AccentDim
        page.AutomaticCanvasSize = Enum.AutomaticSize.Y
        page.CanvasSize = UDim2.new()
        page.Visible = false
        page.ZIndex = 5
        page.Name = "Page_" .. name
        page.Parent = content
        local list = Instance.new("UIListLayout")
        list.SortOrder = Enum.SortOrder.LayoutOrder
        list.Padding = UDim.new(0, 7)
        list.Parent = page
        local pad = Instance.new("UIPadding")
        pad.PaddingTop = UDim.new(0, 8); pad.PaddingBottom = UDim.new(0, 10); pad.PaddingLeft = UDim.new(0, 10); pad.PaddingRight = UDim.new(0, 10)
        pad.Parent = page

        local entry = {Name = name, Button = tabButton, Page = page, Components = {}, Order = #window.Tabs + 1, _order = 0}
        table.insert(window.Tabs, entry)
        local tab = {}
        tab.Name = name
        tab.Page = page
        tab.Components = entry.Components
        tab.Signals = {Selected = Signal.new()}
        maid:Give(tab.Signals.Selected)

        local function nextOrder() entry._order += 1; return entry._order end
        local function elem(h)
            local root = frame(page, {Color = Theme.SurfaceAlt, Size = UDim2.new(1, 0, 0, h), ZIndex = 8, Name = "Element", LayoutOrder = nextOrder()})
            decorate(root, UDim.new(0, 5), Theme.BorderDim, 1)
            local padding = Instance.new("UIPadding")
            padding.PaddingLeft = UDim.new(0, 10); padding.PaddingRight = UDim.new(0, 10)
            padding.Parent = root
            return root
        end

        function tab:GetComponent(idValue) return entry.Components[idValue] end
        function tab:Find(labelValue)
            local result
            for _, comp in pairs(entry.Components) do if comp.Label == labelValue then result = comp; break end end
            return result
        end
        function tab:CreateLabel(text)
            local root = elem(29)
            root.BackgroundColor3 = Theme.Surface
            local component = commonComponent(root, "Label", text)
            label(root, "// " .. tostring(text or ""), {Color = Theme.TextSecondary, Font = Theme.FontMono, TextSize = Theme.TextSizeSmall, ZIndex = 10})
            entry.Components[component.Id] = component
            return component
        end
        function tab:CreateSection(text)
            local root = elem(26); root.BackgroundTransparency = 1
            local component = commonComponent(root, "Section", text)
            label(root, "── " .. tostring(text or "SECTION"):upper() .. " ──", {Color = Theme.AccentDim, Font = Theme.FontMono, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 10})
            entry.Components[component.Id] = component
            return component
        end
        function tab:CreateParagraph(opts2)
            opts2 = type(opts2) == "table" and opts2 or {Text = tostring(opts2 or "")}
            local root = elem(58)
            local component = commonComponent(root, "Paragraph", opts2.Title or "Paragraph")
            local titleLabel = label(root, opts2.Title or "INFO", {Color = Theme.Accent, Font = Theme.FontMono, TextSize = 11, Size = UDim2.new(1, 0, 0, 18), ZIndex = 10})
            local body = label(root, opts2.Text or "", {Color = Theme.TextSecondary, Font = Theme.FontUI, TextSize = 11, Size = UDim2.new(1, 0, 1, -21), Position = UDim2.fromOffset(0, 20), Wrap = true, ZIndex = 10})
            function component:SetText(v) body.Text = tostring(v or "") end
            function component:SetTitle(v) titleLabel.Text = tostring(v or "") end
            entry.Components[component.Id] = component
            return component
        end
        function tab:CreateDivider()
            local root = frame(page, {Color = Theme.BorderDim, Size = UDim2.new(1, 0, 0, 1), ZIndex = 8, LayoutOrder = nextOrder()})
            return root
        end
        function tab:CreateSpacer(size)
            return frame(page, {Color = Theme.Background, Transparency = 1, Size = UDim2.new(1, 0, 0, tonumber(size) or 8), ZIndex = 5, LayoutOrder = nextOrder()})
        end
        function tab:CreateButton(opts2)
            opts2 = opts2 or {}
            local root = elem(40)
            local text = tostring(opts2.Label or "Button")
            local b = button(root, {Text = "▶  " .. text:upper(), Color = Theme.Surface, TextColor = Theme.Accent, Font = Theme.FontMono, TextSize = Theme.TextSizeBody, ZIndex = 11, Stroke = Theme.Border})
            local component = commonComponent(root, "Button", text)
            component.Button = b
            component.Activated = Signal.new()
            component.Maid:Give(component.Activated)
            component.Callback = opts2.Callback or function() end
            function component:SetText(v) self.Label = tostring(v or ""); self.SearchText = self.Label; b.Text = "▶  " .. self.Label:upper() end
            function component:SetDisabled(v) self.State.Disabled = v == true; b.Active = not self.State.Disabled; b.TextTransparency = self.State.Disabled and 0.55 or 0 end
            component.Maid:Give(b.MouseEnter:Connect(function() if not component.State.Disabled then tween:Play(b, {BackgroundColor3 = Theme.SurfaceBright, TextColor3 = Theme.TextPrimary}, Theme.TweenFast, "hover") end end))
            component.Maid:Give(b.MouseLeave:Connect(function() tween:Play(b, {BackgroundColor3 = Theme.Surface, TextColor3 = Theme.Accent}, Theme.TweenFast, "hover") end))
            component.Maid:Give(b.MouseButton1Down:Connect(function() if not component.State.Disabled then tween:Play(b, {BackgroundColor3 = Theme.AccentDim}, Theme.TweenFast, "press") end end))
            component.Maid:Give(b.MouseButton1Up:Connect(function() tween:Play(b, {BackgroundColor3 = Theme.SurfaceBright}, Theme.TweenFast, "press") end))
            component.Maid:Give(b.Activated:Connect(function() if component.State.Disabled then return end; component.Activated:Fire(); safeCallback(component.Callback, b) end))
            entry.Components[component.Id] = component
            return component
        end
        function tab:CreateToggle(opts2)
            opts2 = opts2 or {}
            local root = elem(45)
            local component = commonComponent(root, "Toggle", opts2.Label or "Toggle")
            local state = opts2.Default == true
            local text = label(root, opts2.Label or "Toggle", {Color = Theme.TextPrimary, Font = Theme.FontUI, TextSize = Theme.TextSizeBody, Size = UDim2.new(1, -66, 1, 0), ZIndex = 10})
            local track = frame(root, {Color = state and Theme.ToggleOn or Theme.ToggleOff, Size = UDim2.fromOffset(48, 24), Position = UDim2.new(1, -48, 0.5, -12), ZIndex = 11})
            decorate(track, UDim.new(1, 0), Theme.Border, 1)
            local knob = frame(track, {Color = Theme.ToggleKnob, Size = UDim2.fromOffset(18, 18), Position = state and UDim2.new(1, -21, 0.5, -9) or UDim2.fromOffset(3, 3), ZIndex = 12})
            decorate(knob, UDim.new(1, 0), false)
            local hit = Instance.new("TextButton")
            hit.BackgroundTransparency = 1; hit.Text = ""; hit.Size = UDim2.fromScale(1, 1); hit.ZIndex = 13; hit.Parent = root
            component.Track = track; component.Knob = knob; component.StateValue = state; component.Callback = opts2.Callback or function() end
            function component:Set(value, fire)
                value = value == true
                state = value; self.StateValue = value
                tween:Play(track, {BackgroundColor3 = value and Theme.ToggleOn or Theme.ToggleOff}, Theme.Tween, "toggleColor")
                tween:Play(knob, {Position = value and UDim2.new(1, -21, 0.5, -9) or UDim2.fromOffset(3, 3)}, Theme.Tween, "toggleKnob")
                if fire ~= false then safeCallback(self.Callback, value); self.Signals.Changed:Fire(value) end
            end
            function component:Get() return state end
            function component:SetText(v) self.Label = tostring(v or ""); self.SearchText = self.Label; text.Text = self.Label end
            component.Maid:Give(hit.Activated:Connect(function() if not component.State.Disabled then component:Set(not state) end end))
            component.Maid:Give(hit.MouseEnter:Connect(function() tween:Play(root, {BackgroundColor3 = Theme.SurfaceBright}, Theme.TweenFast, "hover") end))
            component.Maid:Give(hit.MouseLeave:Connect(function() tween:Play(root, {BackgroundColor3 = Theme.SurfaceAlt}, Theme.TweenFast, "hover") end))
            entry.Components[component.Id] = component
            return component
        end
        function tab:CreateCheckbox(opts2)
            opts2 = opts2 or {}
            local toggle = tab:CreateToggle(opts2)
            toggle.Type = "Checkbox"
            toggle.Checkbox = true
            return toggle
        end
        function tab:CreateSlider(opts2)
            opts2 = opts2 or {}
            local minValue = tonumber(opts2.Min) or 0
            local maxValue = tonumber(opts2.Max) or 100
            local stepValue = math.abs(tonumber(opts2.Step) or 1)
            if maxValue < minValue then minValue, maxValue = maxValue, minValue end
            if maxValue == minValue then maxValue = minValue + 1 end
            local value = math.clamp(tonumber(opts2.Default) or minValue, minValue, maxValue)
            local root = elem(66)
            local component = commonComponent(root, "Slider", opts2.Label or "Slider")
            local top = frame(root, {Color = Theme.SurfaceAlt, Transparency = 1, Size = UDim2.new(1, 0, 0, 22), ZIndex = 9})
            local text = label(top, opts2.Label or "Slider", {Color = Theme.TextPrimary, Font = Theme.FontUI, TextSize = Theme.TextSizeBody, Size = UDim2.new(0.7, 0, 1, 0), ZIndex = 10})
            local valueText = label(top, tostring(value), {Color = Theme.Accent, Font = Theme.FontMono, TextSize = Theme.TextSizeBody, TextXAlignment = Enum.TextXAlignment.Right, Size = UDim2.new(0.3, 0, 1, 0), Position = UDim2.new(0.7, 0, 0, 0), ZIndex = 10})
            local track = frame(root, {Color = Theme.SliderTrack, Size = UDim2.new(1, 0, 0, 8), Position = UDim2.new(0, 0, 0, 40), ZIndex = 10})
            decorate(track, UDim.new(1, 0), Theme.BorderDim, 1)
            local fill = frame(track, {Color = Theme.SliderFill, Size = UDim2.new(0, 0, 1, 0), ZIndex = 11})
            decorate(fill, UDim.new(1, 0), false)
            local knob = frame(track, {Color = Theme.Accent, Size = UDim2.fromOffset(16, 16), ZIndex = 12})
            decorate(knob, UDim.new(1, 0), Theme.Background, 1)
            local draggingSlider = false
            local decimals = tonumber(opts2.Decimals)
            local suffix = tostring(opts2.Suffix or "")
            local prefix = tostring(opts2.Prefix or "")
            local function roundValue(v)
                local stepped = math.floor(((v - minValue) / stepValue) + 0.5) * stepValue + minValue
                stepped = math.clamp(stepped, minValue, maxValue)
                if decimals ~= nil then local p = 10 ^ decimals; stepped = math.floor(stepped * p + 0.5) / p end
                return stepped
            end
            local function formatValue(v)
                return prefix .. tostring(v) .. suffix
            end
            local function render(v, fire)
                value = roundValue(v)
                local percent = (value - minValue) / (maxValue - minValue)
                tween:Play(fill, {Size = UDim2.new(percent, 0, 1, 0)}, Theme.TweenFast, "fill")
                tween:Play(knob, {Position = UDim2.new(percent, -8, 0.5, -8)}, Theme.TweenFast, "knob")
                valueText.Text = formatValue(value)
                if fire ~= false then safeCallback(component.Callback, value); component.Signals.Changed:Fire(value) end
            end
            component.Callback = opts2.Callback or function() end
            component.Min, component.Max, component.Step = minValue, maxValue, stepValue
            function component:Set(v, fire) render(tonumber(v) or minValue, fire) end
            function component:Get() return value end
            function component:GetPercent() return (value - minValue) / (maxValue - minValue) end
            function component:SetPercent(p, fire) render(minValue + (maxValue - minValue) * math.clamp(tonumber(p) or 0, 0, 1), fire) end
            function component:SetText(v) self.Label = tostring(v or ""); self.SearchText = self.Label; text.Text = self.Label end
            local function recalc(x)
                if track.AbsoluteSize.X <= 0 then return end
                local pct = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
                render(minValue + (maxValue - minValue) * pct)
            end
            component.Maid:Give(track.InputBegan:Connect(function(input)
                if component.State.Disabled then return end
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then draggingSlider = true; recalc(input.Position.X) end
            end))
            component.Maid:Give(UserInputService.InputChanged:Connect(function(input)
                if draggingSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then recalc(input.Position.X) end
            end))
            component.Maid:Give(UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then draggingSlider = false end
            end))
            component.Maid:Give(track.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton2 then render(minValue); end
            end))
            render(value, false)
            entry.Components[component.Id] = component
            return component
        end
        function tab:CreateDropdown(opts2)
            opts2 = opts2 or {}
            local choices = table.clone(opts2.Options or {})
            local selected = opts2.Default
            if selected == nil then selected = choices[1] end
            local root = elem(45)
            root.ClipsDescendants = false
            local component = commonComponent(root, "Dropdown", opts2.Label or "Dropdown")
            component.Options = choices
            component.Callback = opts2.Callback or function() end
            component.Multi = opts2.Multi == true or opts2.MultiSelect == true
            if component.Multi then selected = type(opts2.Default) == "table" and table.clone(opts2.Default) or {} end
            label(root, opts2.Label or "Dropdown", {Color = Theme.TextPrimary, Font = Theme.FontUI, TextSize = Theme.TextSizeBody, Size = UDim2.new(0.38, 0, 1, 0), ZIndex = 10})
            local selectedText = button(root, {Text = "", Color = Theme.Surface, TextColor = Theme.Accent, Size = UDim2.new(0.59, 0, 0, 29), Position = UDim2.new(0.4, 0, 0.5, -14.5), ZIndex = 21, Stroke = Theme.Border})
            local popup = frame(root, {Color = Theme.TitleBar, Size = UDim2.new(0.59, 0, 0, 0), Position = UDim2.new(0.4, 0, 1, 5), ZIndex = 100, ClipsDescendants = true, Name = "DropdownPopup"})
            decorate(popup, UDim.new(0, 5), Theme.Border, 1)
            local scroll = Instance.new("ScrollingFrame")
            scroll.BackgroundTransparency = 1; scroll.BorderSizePixel = 0; scroll.Size = UDim2.fromScale(1, 1)
            scroll.ScrollBarThickness = 3; scroll.ScrollBarImageColor3 = Theme.AccentDim; scroll.ZIndex = 101; scroll.Parent = popup
            local list = Instance.new("UIListLayout"); list.SortOrder = Enum.SortOrder.LayoutOrder; list.Parent = scroll
            popup.Visible = false
            local open = false
            local outsideConnection
            local searchBar
            local maxDisplayed = tonumber(opts2.MaxVisible) or 6
            local itemHeight = tonumber(opts2.ItemHeight) or 28
            local selectedMap = {}
            if component.Multi then for _, v in ipairs(selected) do selectedMap[tostring(v)] = true end end
            local function displayText()
                if component.Multi then
                    local vals = {}
                    for _, option in ipairs(choices) do if selectedMap[tostring(option)] then table.insert(vals, tostring(option)) end end
                    if #vals == 0 then return "  select...  ▾" end
                    return "  " .. table.concat(vals, ", ") .. "  ▾"
                end
                return "  " .. tostring(selected == nil and "select..." or selected) .. "  ▾"
            end
            local function closeDropdown()
                if not open then return end
                open = false
                popup.Visible = false
                if outsideConnection then outsideConnection:Disconnect(); outsideConnection = nil end
            end
            local function makeItem(option, i)
                local item = button(scroll, {Text = "  " .. tostring(option), Color = Theme.TitleBar, TextColor = Theme.TextSecondary, Font = Theme.FontMono, TextSize = Theme.TextSizeSmall, Size = UDim2.new(1, 0, 0, itemHeight), ZIndex = 102, Stroke = false})
                item.LayoutOrder = i
                item.TextXAlignment = Enum.TextXAlignment.Left
                if component.Multi and selectedMap[tostring(option)] then item.TextColor3 = Theme.Accent end
                item.MouseEnter:Connect(function() if not component.State.Disabled then tween:Play(item, {BackgroundColor3 = Theme.Surface, TextColor3 = Theme.TextPrimary}, Theme.TweenFast, "hover") end end)
                item.MouseLeave:Connect(function() tween:Play(item, {BackgroundColor3 = Theme.TitleBar, TextColor3 = component.Multi and selectedMap[tostring(option)] and Theme.Accent or Theme.TextSecondary}, Theme.TweenFast, "hover") end)
                item.Activated:Connect(function()
                    if component.State.Disabled then return end
                    if component.Multi then
                        selectedMap[tostring(option)] = not selectedMap[tostring(option)]
                        local out = {}
                        for _, valueOption in ipairs(choices) do if selectedMap[tostring(valueOption)] then table.insert(out, valueOption) end end
                        selected = out; selectedText.Text = displayText(); safeCallback(component.Callback, table.clone(out)); component.Signals.Changed:Fire(table.clone(out))
                        item.TextColor3 = selectedMap[tostring(option)] and Theme.Accent or Theme.TextSecondary
                    else
                        selected = option; selectedText.Text = displayText(); safeCallback(component.Callback, selected); component.Signals.Changed:Fire(selected); closeDropdown()
                    end
                end)
                return item
            end
            local function rebuild()
                for _, child in ipairs(scroll:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
                for i, option in ipairs(choices) do makeItem(option, i) end
                scroll.CanvasSize = UDim2.fromOffset(0, #choices * itemHeight + (searchBar and 32 or 0))
            end
            local function openDropdown()
                if component.State.Disabled then return end
                open = true; popup.Visible = true
                local shown = math.min(#choices, maxDisplayed)
                popup.Size = UDim2.new(0.59, 0, 0, math.max(1, shown) * itemHeight)
                outsideConnection = UserInputService.InputBegan:Connect(function(input)
                    if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
                    local p = input.Position
                    local a, s = popup.AbsolutePosition, popup.AbsoluteSize
                    local b, bs = selectedText.AbsolutePosition, selectedText.AbsoluteSize
                    local insidePopup = p.X >= a.X and p.X <= a.X + s.X and p.Y >= a.Y and p.Y <= a.Y + s.Y
                    local insideButton = p.X >= b.X and p.X <= b.X + bs.X and p.Y >= b.Y and p.Y <= b.Y + bs.Y
                    if not insidePopup and not insideButton then closeDropdown() end
                end)
            end
            selectedText.Text = displayText()
            selectedText.Activated:Connect(function() if open then closeDropdown() else openDropdown() end end)
            component.Maid:Give(selectedText.MouseEnter:Connect(function() tween:Play(selectedText, {BackgroundColor3 = Theme.SurfaceBright}, Theme.TweenFast, "hover") end))
            component.Maid:Give(selectedText.MouseLeave:Connect(function() tween:Play(selectedText, {BackgroundColor3 = Theme.Surface}, Theme.TweenFast, "hover") end))
            component.Maid:Give(function() if outsideConnection then outsideConnection:Disconnect() end end)
            function component:Get() return component.Multi and table.clone(selected) or selected end
            function component:Set(v, fire)
                if component.Multi then
                    selected = type(v) == "table" and table.clone(v) or {}
                    table.clear(selectedMap); for _, option in ipairs(selected) do selectedMap[tostring(option)] = true end
                else selected = v end
                selectedText.Text = displayText()
                if fire ~= false then safeCallback(component.Callback, component:Get()); component.Signals.Changed:Fire(component:Get()) end
            end
            function component:Refresh(newChoices)
                choices = table.clone(newChoices or {})
                component.Options = choices
                rebuild()
                selectedText.Text = displayText()
            end
            function component:Add(option) table.insert(choices, option); rebuild() end
            function component:Remove(option)
                for i, valueOption in ipairs(choices) do if valueOption == option then table.remove(choices, i); break end end
                rebuild()
            end
            rebuild()
            entry.Components[component.Id] = component
            return component
        end
        function tab:CreateMultiDropdown(opts2) opts2 = opts2 or {}; opts2.Multi = true; return tab:CreateDropdown(opts2) end
        function tab:CreateTextInput(opts2)
            opts2 = opts2 or {}
            local root = elem(45)
            local component = commonComponent(root, "TextInput", opts2.Label or "Input")
            component.Callback = opts2.Callback or function() end
            local text = label(root, opts2.Label or "Input", {Color = Theme.TextPrimary, Font = Theme.FontUI, TextSize = Theme.TextSizeBody, Size = UDim2.new(0.37, 0, 1, 0), ZIndex = 10})
            local box = Instance.new("TextBox")
            box.BackgroundColor3 = Theme.Surface; box.BorderSizePixel = 0; box.ClearTextOnFocus = false
            box.Text = tostring(opts2.Default or ""); box.PlaceholderText = tostring(opts2.Placeholder or "type here...")
            box.PlaceholderColor3 = Theme.TextMuted; box.TextColor3 = Theme.Accent; box.Font = Theme.FontMono; box.TextSize = 11
            box.Size = UDim2.new(0.59, 0, 0, 29); box.Position = UDim2.new(0.4, 0, 0.5, -14.5); box.ZIndex = 11; box.Parent = root
            decorate(box, UDim.new(0, 4), Theme.Border, 1)
            local pad = Instance.new("UIPadding"); pad.PaddingLeft = UDim.new(0, 7); pad.PaddingRight = UDim.new(0, 7); pad.Parent = box
            component.Box = box; component.Value = box.Text
            component.MaxLength = tonumber(opts2.MaxLength)
            component.Validator = opts2.Validator
            function component:Get() return box.Text end
            function component:Set(v, fire) box.Text = tostring(v or ""); if fire ~= false then safeCallback(component.Callback, box.Text, false); component.Signals.Changed:Fire(box.Text) end end
            function component:Focus() box:CaptureFocus() end
            function component:Clear() self:Set("") end
            component.Maid:Give(box:GetPropertyChangedSignal("Text"):Connect(function()
                if component.MaxLength and #box.Text > component.MaxLength then box.Text = string.sub(box.Text, 1, component.MaxLength) end
                component.Value = box.Text
                if opts2.OnChanged then safeCallback(opts2.OnChanged, box.Text) end
            end))
            component.Maid:Give(box.Focused:Connect(function() tween:Play(box, {BackgroundColor3 = Theme.SurfaceBright}, Theme.TweenFast, "focus") end))
            component.Maid:Give(box.FocusLost:Connect(function(enter)
                tween:Play(box, {BackgroundColor3 = Theme.Surface}, Theme.TweenFast, "focus")
                if component.Validator then
                    local ok, message = component.Validator(box.Text)
                    if ok == false then
                        box.TextColor3 = Theme.Danger
                        Library:Notify({Title = component.Label, Description = tostring(message or "Invalid value"), Type = "Error", Duration = 2})
                    else box.TextColor3 = Theme.Accent end
                end
                safeCallback(component.Callback, box.Text, enter); component.Signals.Changed:Fire(box.Text)
            end))
            entry.Components[component.Id] = component
            return component
        end
        function tab:CreateNumberInput(opts2)
            opts2 = opts2 or {}
            opts2.Default = tonumber(opts2.Default) or tonumber(opts2.Min) or 0
            opts2.Validator = opts2.Validator or function(text)
                local n = tonumber(text); if not n then return false, "Enter a valid number." end
                if opts2.Min and n < opts2.Min then return false, "Value is below minimum." end
                if opts2.Max and n > opts2.Max then return false, "Value is above maximum." end
                return true
            end
            return tab:CreateTextInput(opts2)
        end
        function tab:CreateKeybind(opts2)
            opts2 = opts2 or {}
            local root = elem(45)
            local component = commonComponent(root, "Keybind", opts2.Label or "Keybind")
            component.Callback = opts2.Callback or function() end
            local current = opts2.Default
            local listening = false
            label(root, opts2.Label or "Keybind", {Color = Theme.TextPrimary, Font = Theme.FontUI, TextSize = Theme.TextSizeBody, Size = UDim2.new(0.48, 0, 1, 0), ZIndex = 10})
            local bindButton = button(root, {Text = current and current.Name or "NONE", Color = Theme.Surface, TextColor = Theme.Accent, Size = UDim2.new(0.45, 0, 0, 29), Position = UDim2.new(0.53, 0, 0.5, -14.5), ZIndex = 11, Stroke = Theme.Border})
            component.Button = bindButton
            function component:Get() return current end
            function component:Set(key) current = key; bindButton.Text = key and (key.Name or tostring(key)) or "NONE" end
            function component:Clear() self:Set(nil) end
            component.Maid:Give(bindButton.Activated:Connect(function() listening = true; bindButton.Text = "PRESS KEY..." end))
            component.Maid:Give(UserInputService.InputBegan:Connect(function(input, processed)
                if listening then
                    if input.UserInputType == Enum.UserInputType.Keyboard or input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 or input.UserInputType == Enum.UserInputType.MouseButton3 then
                        listening = false
                        if input.KeyCode ~= Enum.KeyCode.Unknown then component:Set(input.KeyCode) elseif input.UserInputType ~= Enum.UserInputType.Keyboard then component:Set(input.UserInputType) end
                    end
                    return
                end
                if processed then return end
                if current and ((typeof(current) == "EnumItem" and current.EnumType == Enum.KeyCode and input.KeyCode == current) or (typeof(current) == "EnumItem" and current.EnumType == Enum.UserInputType and input.UserInputType == current)) then safeCallback(component.Callback, current); component.Signals.Changed:Fire(current) end
            end))
            entry.Components[component.Id] = component
            return component
        end
        function tab:CreateColorPicker(opts2)
            opts2 = opts2 or {}
            local root = elem(45)
            local component = commonComponent(root, "ColorPicker", opts2.Label or "Color")
            component.Callback = opts2.Callback or function() end
            local currentColor = opts2.Default or Color3.new(1, 1, 1)
            label(root, opts2.Label or "Color", {Color = Theme.TextPrimary, Font = Theme.FontUI, TextSize = Theme.TextSizeBody, Size = UDim2.new(0.55, 0, 1, 0), ZIndex = 10})
            local swatch = button(root, {Text = "", Color = currentColor, Size = UDim2.fromOffset(48, 29), Position = UDim2.new(1, -48, 0.5, -14.5), ZIndex = 11, Stroke = Theme.Border})
            component.Button = swatch
            local picker
            local function closePicker() if picker then picker:Destroy(); picker = nil end end
            local function buildPicker()
                closePicker()
                picker = frame(root.Parent.Parent, {Color = Theme.TitleBar, Size = UDim2.fromOffset(230, 150), Position = UDim2.new(0.5, -115, 0.5, -75), ZIndex = 180})
                decorate(picker, UDim.new(0, 6), Theme.Border, 1)
                local r = Instance.new("TextBox")
                local g = Instance.new("TextBox")
                local b = Instance.new("TextBox")
                local inputs = {{r, "R", currentColor.R}, {g, "G", currentColor.G}, {b, "B", currentColor.B}}
                label(picker, "COLOR PICKER", {Color = Theme.Accent, Font = Theme.FontMono, TextSize = 12, Size = UDim2.new(1, -12, 0, 25), Position = UDim2.fromOffset(8, 4), ZIndex = 184})
                for i, info in ipairs(inputs) do
                    local box = info[1]
                    box.BackgroundColor3 = Theme.Surface; box.BorderSizePixel = 0; box.TextColor3 = Theme.Accent; box.Font = Theme.FontMono; box.TextSize = 12; box.Text = string.format("%.2f", info[3]); box.PlaceholderText = info[2]; box.Size = UDim2.new(1, -20, 0, 27); box.Position = UDim2.fromOffset(10, 30 + (i - 1) * 32); box.ZIndex = 185; box.Parent = picker; decorate(box, UDim.new(0, 4), Theme.BorderDim, 1)
                end
                local apply = button(picker, {Text = "APPLY", Color = Theme.SurfaceAlt, TextColor = Theme.Accent, Size = UDim2.new(1, -20, 0, 27), Position = UDim2.new(0, 10, 1, -35), ZIndex = 185, Stroke = Theme.Border})
                apply.Activated:Connect(function()
                    local rr = math.clamp(tonumber(r.Text) or currentColor.R, 0, 1)
                    local gg = math.clamp(tonumber(g.Text) or currentColor.G, 0, 1)
                    local bb = math.clamp(tonumber(b.Text) or currentColor.B, 0, 1)
                    currentColor = Color3.new(rr, gg, bb); swatch.BackgroundColor3 = currentColor; safeCallback(component.Callback, currentColor); component.Signals.Changed:Fire(currentColor); closePicker()
                end)
            end
            swatch.Activated:Connect(buildPicker)
            function component:Get() return currentColor end
            function component:Set(c, fire) if typeof(c) ~= "Color3" then return end; currentColor = c; swatch.BackgroundColor3 = c; if fire ~= false then safeCallback(component.Callback, c); component.Signals.Changed:Fire(c) end end
            local baseDestroy = component.Destroy
            function component:Destroy()
                closePicker()
                baseDestroy(self)
            end
            entry.Components[component.Id] = component
            return component
        end
        function tab:CreateProgressBar(opts2)
            opts2 = opts2 or {}
            local minValue = tonumber(opts2.Min) or 0
            local maxValue = tonumber(opts2.Max) or 100
            local current = math.clamp(tonumber(opts2.Default) or minValue, minValue, maxValue)
            local root = elem(48)
            local component = commonComponent(root, "ProgressBar", opts2.Label or "Progress")
            local text = label(root, opts2.Label or "Progress", {Color = Theme.TextPrimary, Font = Theme.FontUI, TextSize = 12, Size = UDim2.new(0.7, 0, 0, 20), ZIndex = 10})
            local valueLabel = label(root, "", {Color = Theme.Accent, Font = Theme.FontMono, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Right, Size = UDim2.new(0.3, 0, 0, 20), Position = UDim2.new(0.7, 0, 0, 0), ZIndex = 10})
            local track = frame(root, {Color = Theme.SliderTrack, Size = UDim2.new(1, 0, 0, 8), Position = UDim2.new(0, 0, 0, 28), ZIndex = 10})
            decorate(track, UDim.new(1, 0), Theme.BorderDim, 1)
            local fill = frame(track, {Color = opts2.Color or Theme.Accent, Size = UDim2.new(0, 0, 1, 0), ZIndex = 11}); decorate(fill, UDim.new(1, 0), false)
            local function render(v) current = math.clamp(v, minValue, maxValue); local p = (current - minValue) / (maxValue - minValue); tween:Play(fill, {Size = UDim2.new(p, 0, 1, 0)}, Theme.Tween, "progress"); valueLabel.Text = string.format("%d%%", math.floor(p * 100 + 0.5)) end
            function component:Set(v) render(tonumber(v) or minValue) end
            function component:Get() return current end
            render(current)
            entry.Components[component.Id] = component
            return component
        end
        function tab:CreateImage(opts2)
            opts2 = opts2 or {}
            local root = elem(110)
            local component = commonComponent(root, "Image", opts2.Label or "Image")
            local image = Instance.new("ImageLabel")
            image.BackgroundTransparency = 1; image.Image = tostring(opts2.Image or opts2.ImageId or ""); image.ImageColor3 = opts2.ImageColor3 or Color3.new(1, 1, 1)
            image.ScaleType = opts2.ScaleType or Enum.ScaleType.Fit; image.Size = UDim2.new(1, 0, 1, 0); image.ZIndex = 10; image.Parent = root
            component.Image = image
            function component:SetImage(idValue) image.Image = tostring(idValue or "") end
            entry.Components[component.Id] = component
            return component
        end

        tab.CreateInput = tab.CreateTextInput
        tab.CreateNumber = tab.CreateNumberInput
        tab.CreateKeyBind = tab.CreateKeybind
        tab.CreateColourPicker = tab.CreateColorPicker

        maid:Give(tabButton.Activated:Connect(function() setActiveTab(entry.Order); tab.Signals.Selected:Fire(tab) end))
        maid:Give(tabButton.MouseEnter:Connect(function() if activeTab ~= entry.Order then tween:Play(tabButton, {BackgroundColor3 = Theme.SurfaceBright}, Theme.TweenFast, "hover") end end))
        maid:Give(tabButton.MouseLeave:Connect(function() if activeTab ~= entry.Order then tween:Play(tabButton, {BackgroundColor3 = Theme.TabInactive}, Theme.TweenFast, "hover") end end))

        if #window.Tabs == 1 then setActiveTab(1) end
        return tab
    end

    function window:ForEachComponent(fn)
        for _, tabEntry in ipairs(self.Tabs) do for _, component in pairs(tabEntry.Components) do safeCallback(fn, component, tabEntry) end end
    end
    function window:SetTheme(overrides) return Library:SetTheme(overrides) end
    function window:SaveConfig(name) return Library:SaveConfig(name, self) end
    function window:LoadConfig(name) return Library:LoadConfig(name, self) end

    local function applyTheme()
        if window.State.Destroyed then return end
        win.BackgroundColor3 = Theme.Background
        titleBar.BackgroundColor3 = Theme.TitleBar
        status.BackgroundColor3 = Theme.TitleBar
        statusLabel.TextColor3 = Theme.BorderDim
        titleText.TextColor3 = Theme.Accent
        titleIcon.ImageColor3 = Theme.Accent
        statusDot.BackgroundColor3 = Theme.Success
        tabBar.BackgroundColor3 = Theme.TitleBar
    end
    self:_trackTheme(applyTheme)
    maid:Give(function()
        for i, fn in ipairs(self._themeListeners) do if fn == applyTheme then table.remove(self._themeListeners, i); break end end
    end)

    window:Center()
    local openSize = UDim2.fromOffset(width, height)
    if Library.ReducedMotion then win.Size = openSize else tween:Play(win, {Size = openSize}, Theme.TweenSlow, "open") end

    return window
end

function Library:_serializeComponent(component)
    local data = {Type = component.Type, Label = component.Label, Id = component.Id}
    if component.Type == "Toggle" or component.Type == "Checkbox" then data.Value = component:Get()
    elseif component.Type == "Slider" then data.Value = component:Get()
    elseif component.Type == "Dropdown" then data.Value = component:Get()
    elseif component.Type == "TextInput" or component.Type == "NumberInput" then data.Value = component:Get()
    elseif component.Type == "ColorPicker" then local c = component:Get(); data.Value = {R = c.R, G = c.G, B = c.B}
    elseif component.Type == "Keybind" then local k = component:Get(); data.Value = k and k.Name or nil end
    return data
end

function Library:ExportConfig(window)
    local result = {Version = "2.0", Window = window and window.Name or "", Tabs = {}}
    if not window then return result end
    for _, tab in ipairs(window.Tabs) do
        local tabData = {Name = tab.Name, Components = {}}
        for _, component in pairs(tab.Components) do table.insert(tabData.Components, self:_serializeComponent(component)) end
        table.insert(result.Tabs, tabData)
    end
    return result
end
function Library:SaveConfig(name, window)
    name = tostring(name or "Default")
    local data = self:ExportConfig(window)
    self.Configs[name] = data
    return data
end
function Library:LoadConfig(name, window)
    name = tostring(name or "Default")
    local data = self.Configs[name]
    if not data or not window then return false end
    for _, tabData in ipairs(data.Tabs or {}) do
        for _, saved in ipairs(tabData.Components or {}) do
            local component
            for _, tab in ipairs(window.Tabs) do for _, candidate in pairs(tab.Components) do if candidate.Id == saved.Id or candidate.Label == saved.Label then component = candidate; break end end end
            if component and saved.Value ~= nil then
                if component.Type == "ColorPicker" and type(saved.Value) == "table" then component:Set(Color3.new(saved.Value.R or 1, saved.Value.G or 1, saved.Value.B or 1), false)
                elseif component.Set then component:Set(saved.Value, false) end
            end
        end
    end
    return true
end
function Library:EncodeConfig(window)
    return HttpService:JSONEncode(self:ExportConfig(window))
end
function Library:DecodeConfig(json)
    local ok, result = pcall(function() return HttpService:JSONDecode(json) end)
    return ok and result or nil
end
function Library:SetDebug(enabled) self.Debug = enabled == true end
function Library:Destroy()
    self:DestroyAll()
    if self._notificationHolder and self._notificationHolder.Parent then self._notificationHolder:Destroy() end
    table.clear(self._themeListeners)
end

return Library
