--[[
    ██████╗ ██╗      █████╗ ███████╗███╗   ███╗ █████╗
    ██╔══██╗██║     ██╔══██╗██╔════╝████╗ ████║██╔══██╗
    ██████╔╝██║     ███████║███████╗██╔████╔██║███████║
    ██╔═══╝ ██║     ██╔══██║╚════██║██║╚██╔╝██║██╔══██║
    ██║     ███████╗██║  ██║███████║██║ ╚═╝ ██║██║  ██║
    ╚═╝     ╚══════╝╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝╚═╝  ╚═╝

    PlasmaLibUI
    Version: 1.4.0

    FEATURES
    - Hacker / Sci-Fi green UI
    - Window / Tabs
    - Buttons
    - Toggles
    - Sliders
    - Dropdowns
    - Text inputs
    - Smooth animations
    - Dragging
    - Smart icon resolver
    - Optional player right-click context menu
    - Player target detection
    - Outside-click dismissal
    - Context-menu animation
    - Safe callback architecture
]]

------------------------------------------------------------------------
-- SERVICES
------------------------------------------------------------------------

local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local TextService      = game:GetService("TextService")

local LocalPlayer = Players.LocalPlayer

------------------------------------------------------------------------
-- THEME
------------------------------------------------------------------------

local Theme = {
    Background    = Color3.fromRGB(8, 12, 8),
    Surface       = Color3.fromRGB(12, 20, 12),
    SurfaceAlt    = Color3.fromRGB(18, 30, 18),

    Border        = Color3.fromRGB(0, 200, 80),
    BorderDim     = Color3.fromRGB(0, 80, 30),

    Accent        = Color3.fromRGB(0, 255, 100),
    AccentDim     = Color3.fromRGB(0, 140, 55),

    TextPrimary   = Color3.fromRGB(0, 255, 100),
    TextSecondary = Color3.fromRGB(0, 180, 70),
    TextDisabled  = Color3.fromRGB(0, 80, 30),

    Danger        = Color3.fromRGB(255, 50, 50),

    SliderFill    = Color3.fromRGB(0, 220, 90),
    SliderTrack   = Color3.fromRGB(15, 35, 15),

    ToggleOn      = Color3.fromRGB(0, 220, 90),
    ToggleOff     = Color3.fromRGB(20, 40, 20),
    ToggleKnob    = Color3.fromRGB(200, 255, 210),

    Scanline      = Color3.fromRGB(0, 255, 100),

    TabActive     = Color3.fromRGB(0, 200, 75),
    TabInactive   = Color3.fromRGB(0, 45, 18),

    TitleBar      = Color3.fromRGB(6, 16, 6),

    ContextBackground = Color3.fromRGB(7, 12, 8),
    ContextHeader     = Color3.fromRGB(5, 18, 8),
    ContextHover      = Color3.fromRGB(16, 38, 18),

    CornerRadius    = UDim.new(0, 4),
    BorderThickness = 1,

    FontMono = Enum.Font.Code,
    FontUI   = Enum.Font.GothamMedium,
    FontBold = Enum.Font.GothamBold,

    TextSizeTitle = 15,
    TextSizeBody  = 13,
    TextSizeSmall = 11,

    Tween = TweenInfo.new(
        0.16,
        Enum.EasingStyle.Quad,
        Enum.EasingDirection.Out
    ),

    TweenSlow = TweenInfo.new(
        0.32,
        Enum.EasingStyle.Quad,
        Enum.EasingDirection.Out
    ),

    ContextOpen = TweenInfo.new(
        0.14,
        Enum.EasingStyle.Quart,
        Enum.EasingDirection.Out
    ),

    ContextClose = TweenInfo.new(
        0.10,
        Enum.EasingStyle.Quad,
        Enum.EasingDirection.In
    ),
}

------------------------------------------------------------------------
-- INTERNAL HELPERS
------------------------------------------------------------------------

local function tw(object, properties, tweenInfo)
    if not object then
        return
    end

    local success, tween = pcall(function()
        return TweenService:Create(
            object,
            tweenInfo or Theme.Tween,
            properties
        )
    end)

    if success and tween then
        tween:Play()
    end
end

local function Decorate(frame, radius, strokeColor, strokeThickness)
    if not frame then
        return
    end

    local corner = Instance.new("UICorner")
    corner.CornerRadius = radius or Theme.CornerRadius
    corner.Parent = frame

    if strokeColor ~= false then
        local stroke = Instance.new("UIStroke")

        stroke.Color =
            strokeColor or Theme.BorderDim

        stroke.Thickness =
            strokeThickness or Theme.BorderThickness

        stroke.ApplyStrokeMode =
            Enum.ApplyStrokeMode.Border

        stroke.Parent = frame
    end
end

local function NewLabel(properties)
    properties = properties or {}

    local label = Instance.new("TextLabel")

    label.BackgroundTransparency = 1

    label.TextColor3 =
        properties.Color or Theme.TextPrimary

    label.Font =
        properties.Font or Theme.FontUI

    label.TextSize =
        properties.Size2 or Theme.TextSizeBody

    label.Text =
        properties.Text or ""

    label.TextXAlignment =
        properties.AlignX or Enum.TextXAlignment.Left

    label.TextYAlignment =
        Enum.TextYAlignment.Center

    label.TextTruncate =
        Enum.TextTruncate.AtEnd

    label.Size =
        properties.Size or UDim2.new(1, 0, 1, 0)

    label.Position =
        properties.Pos or UDim2.new(0, 0, 0, 0)

    label.ZIndex =
        properties.Z or 5

    label.RichText =
        properties.Rich or false

    label.Parent =
        properties.Parent

    return label
end

local function NewFrame(properties)
    properties = properties or {}

    local frame = Instance.new("Frame")

    frame.BackgroundColor3 =
        properties.Color or Theme.Surface

    frame.BackgroundTransparency =
        properties.Trans or 0

    frame.BorderSizePixel = 0

    frame.Size =
        properties.Size or UDim2.new(1, 0, 1, 0)

    frame.Position =
        properties.Pos or UDim2.new(0, 0, 0, 0)

    frame.ZIndex =
        properties.Z or 4

    frame.ClipsDescendants =
        properties.Clip or false

    frame.Name =
        properties.Name or "Frame"

    frame.Parent =
        properties.Parent

    return frame
end

------------------------------------------------------------------------
-- SMART ICON RESOLVER
------------------------------------------------------------------------

local function getIconAsset(iconInput)
    if not iconInput or iconInput == "" then
        return ""
    end

    if type(iconInput) == "number"
        or (
            type(iconInput) == "string"
            and tonumber(iconInput)
        )
    then
        return "rbxassetid://" .. tostring(iconInput)
    end

    if type(iconInput) == "string" then
        if iconInput:find("rbxasset")
            or iconInput:find("rbxthumb")
        then
            return iconInput
        end

        if iconInput:find("^https?://") then
            if not (
                writefile
                and getcustomasset
                and game.HttpGet
            ) then
                warn(
                    "[PlasmaLibUI] Executor missing file/HTTP APIs."
                )

                return ""
            end

            local safeName =
                "cache_"
                .. iconInput:gsub("[^%w]", "_"):sub(-40)
                .. ".png"

            if isfile and isfile(safeName) then
                return getcustomasset(safeName)
            end

            local success, result = pcall(function()
                local bytes = game:HttpGet(iconInput)

                writefile(
                    safeName,
                    bytes
                )

                return getcustomasset(
                    safeName
                )
            end)

            if success then
                return result
            end

            warn(
                "[PlasmaLibUI] Image download failed:",
                result
            )

            return ""
        end

        if isfile
            and getcustomasset
            and isfile(iconInput)
        then
            return getcustomasset(iconInput)
        end
    end

    return tostring(iconInput)
end

------------------------------------------------------------------------
-- GUI PARENT
------------------------------------------------------------------------

local function GuiParent()
    if gethui then
        local success, result = pcall(gethui)

        if success and result then
            return result
        end
    end

    local success, coreGui =
        pcall(function()
            return game:GetService("CoreGui")
        end)

    if success and coreGui then
        return coreGui
    end

    return LocalPlayer:WaitForChild("PlayerGui")
end

------------------------------------------------------------------------
-- SCANLINES
------------------------------------------------------------------------

local function AddScanlines(parent, count)
    count = count or 60

    local overlay = Instance.new("Frame")

    overlay.BackgroundTransparency = 1
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.ZIndex = 60
    overlay.BorderSizePixel = 0
    overlay.Name = "Scanlines"
    overlay.Parent = parent

    local grid = Instance.new("UIGridLayout")

    grid.CellSize =
        UDim2.new(1, 0, 0, 2)

    grid.CellPadding =
        UDim2.new(0, 0, 0, 2)

    grid.Parent = overlay

    for _ = 1, count do
        local line = Instance.new("Frame")

        line.BackgroundColor3 =
            Theme.Scanline

        line.BackgroundTransparency = 0.965
        line.BorderSizePixel = 0
        line.Parent = overlay
    end
end

------------------------------------------------------------------------
-- DRAG SYSTEM
------------------------------------------------------------------------

local function MakeDraggable(handle, target, track)
    local active = false
    local origin = Vector2.zero
    local startPosition = UDim2.new()

    local function clampPosition(position)
        local camera =
            workspace.CurrentCamera

        local viewport =
            camera
            and camera.ViewportSize
            or Vector2.new(1920, 1080)

        local size =
            target.AbsoluteSize

        local minimumVisible = 44

        local scaleX =
            position.X.Scale

        local scaleY =
            position.Y.Scale

        local minOffsetX =
            minimumVisible
            - size.X
            - viewport.X * scaleX

        local maxOffsetX =
            viewport.X
            - minimumVisible
            - viewport.X * scaleX

        local minOffsetY =
            0
            - viewport.Y * scaleY

        local maxOffsetY =
            viewport.Y
            - minimumVisible
            - viewport.Y * scaleY

        local x =
            math.clamp(
                position.X.Offset,
                minOffsetX,
                maxOffsetX
            )

        local y =
            math.clamp(
                position.Y.Offset,
                minOffsetY,
                maxOffsetY
            )

        return UDim2.new(
            scaleX,
            x,
            scaleY,
            y
        )
    end

    local began =
        handle.InputBegan:Connect(function(input)
            if input.UserInputType
                ~= Enum.UserInputType.MouseButton1
                and input.UserInputType
                    ~= Enum.UserInputType.Touch
            then
                return
            end

            active = true
            origin = input.Position
            startPosition = target.Position

            input.Changed:Connect(function()
                if input.UserInputState
                    == Enum.UserInputState.End
                then
                    active = false
                end
            end)
        end)

    local changed =
        UserInputService.InputChanged:Connect(function(input)
            if not active then
                return
            end

            if input.UserInputType
                ~= Enum.UserInputType.MouseMovement
                and input.UserInputType
                    ~= Enum.UserInputType.Touch
            then
                return
            end

            local delta =
                input.Position - origin

            local newPosition =
                UDim2.new(
                    startPosition.X.Scale,
                    startPosition.X.Offset + delta.X,

                    startPosition.Y.Scale,
                    startPosition.Y.Offset + delta.Y
                )

            target.Position =
                clampPosition(newPosition)
        end)

    if track then
        track(began)
        track(changed)
    end
end

------------------------------------------------------------------------
-- LIBRARY
------------------------------------------------------------------------

local Library = {}
Library.__index = Library

------------------------------------------------------------------------
-- WINDOW
------------------------------------------------------------------------

function Library:CreateWindow(options)
    options = options or {}

    local TITLE =
        tostring(options.Title or "PlasmaLibUI")

    local ICON =
        getIconAsset(
            options.IconId
            or "rbxassetid://7072706620"
        )

    local WIDTH =
        tonumber(options.Width) or 500

    local HEIGHT =
        tonumber(options.Height) or 380

    local SCANLINES =
        options.Scanlines ~= false

    local TOGGLE_KEY =
        options.ToggleKey

    local ScreenGui = Instance.new("ScreenGui")

    ScreenGui.Name =
        "PlasmaLibUI_"
        .. TITLE:gsub("%s", "")

    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior =
        Enum.ZIndexBehavior.Sibling

    ScreenGui.IgnoreGuiInset = true
    ScreenGui.DisplayOrder = 999
    ScreenGui.Parent = GuiParent()

    --------------------------------------------------------------------
    -- WINDOW FRAME
    --------------------------------------------------------------------

    local WindowFrame = NewFrame({
        Name = "Window",

        Color = Theme.Background,

        Size =
            UDim2.new(
                0,
                WIDTH,
                0,
                0
            ),

        Pos =
            UDim2.new(
                0.5,
                -WIDTH / 2,
                0.5,
                -HEIGHT / 2
            ),

        Clip = true,
        Z = 2,

        Parent = ScreenGui,
    })

    Decorate(
        WindowFrame,
        UDim.new(0, 0),
        Theme.Border,
        1
    )

    if SCANLINES then
        AddScanlines(
            WindowFrame,
            math.clamp(
                math.floor(HEIGHT / 4),
                20,
                80
            )
        )
    end

    NewFrame({
        Color = Theme.Accent,
        Size = UDim2.new(1, 0, 0, 2),
        Z = 6,
        Parent = WindowFrame,
    })

    --------------------------------------------------------------------
    -- CONNECTION MANAGEMENT
    --------------------------------------------------------------------

    local Connections = {}

    local function track(connection)
        if connection then
            table.insert(
                Connections,
                connection
            )
        end

        return connection
    end

    local ContextMenus = {}

    --------------------------------------------------------------------
    -- WINDOW OBJECT
    --------------------------------------------------------------------

    local Window = {}

    --------------------------------------------------------------------
    -- TITLE BAR
    --------------------------------------------------------------------

    local TitleBar = NewFrame({
        Name = "TitleBar",
        Color = Theme.TitleBar,

        Size =
            UDim2.new(
                1,
                0,
                0,
                38
            ),

        Pos =
            UDim2.new(
                0,
                0,
                0,
                2
            ),

        Z = 5,
        Parent = WindowFrame,
    })

    --------------------------------------------------------------------
    -- ICON
    --------------------------------------------------------------------

    local Icon = Instance.new("ImageLabel")

    Icon.BackgroundTransparency = 1

    Icon.Size =
        UDim2.new(
            0,
            22,
            0,
            22
        )

    Icon.Position =
        UDim2.new(
            0,
            8,
            0.5,
            -11
        )

    Icon.Image = ICON
    Icon.ImageColor3 = Theme.Accent
    Icon.ZIndex = 7
    Icon.Parent = TitleBar

    --------------------------------------------------------------------
    -- TITLE
    --------------------------------------------------------------------

    NewLabel({
        Text =
            ("[ %s ]"):format(
                TITLE:upper()
            ),

        Color = Theme.Accent,
        Font = Theme.FontMono,
        Size2 = Theme.TextSizeTitle,

        Size =
            UDim2.new(
                1,
                -104,
                1,
                0
            ),

        Pos =
            UDim2.new(
                0,
                38,
                0,
                0
            ),

        Z = 7,
        Parent = TitleBar,
    })

    --------------------------------------------------------------------
    -- CLOSE
    --------------------------------------------------------------------

    local CloseButton = Instance.new("TextButton")

    CloseButton.BackgroundColor3 =
        Color3.fromRGB(28, 8, 8)

    CloseButton.Size =
        UDim2.new(
            0,
            28,
            0,
            20
        )

    CloseButton.Position =
        UDim2.new(
            1,
            -34,
            0.5,
            -10
        )

    CloseButton.Text = "X"
    CloseButton.Font = Theme.FontBold
    CloseButton.TextSize = 13
    CloseButton.TextColor3 = Theme.Danger

    CloseButton.BorderSizePixel = 0
    CloseButton.AutoButtonColor = false
    CloseButton.ZIndex = 8
    CloseButton.Parent = TitleBar

    Decorate(
        CloseButton,
        UDim.new(0, 3),
        Theme.Danger,
        1
    )

    track(
        CloseButton.MouseEnter:Connect(function()
            tw(
                CloseButton,
                {
                    BackgroundColor3 =
                        Theme.Danger,

                    TextColor3 =
                        Color3.new(1, 1, 1),
                }
            )
        end)
    )

    track(
        CloseButton.MouseLeave:Connect(function()
            tw(
                CloseButton,
                {
                    BackgroundColor3 =
                        Color3.fromRGB(
                            28,
                            8,
                            8
                        ),

                    TextColor3 =
                        Theme.Danger,
                }
            )
        end)
    )

    track(
        CloseButton.MouseButton1Click:Connect(function()
            tw(
                WindowFrame,
                {
                    Size =
                        UDim2.new(
                            0,
                            WIDTH,
                            0,
                            0
                        ),
                },
                Theme.TweenSlow
            )

            task.delay(0.38, function()
                if Window.Destroy then
                    Window:Destroy()
                end
            end)
        end)
    )

    --------------------------------------------------------------------
    -- MINIMIZE
    --------------------------------------------------------------------

    local MinimizeButton = Instance.new("TextButton")

    MinimizeButton.BackgroundColor3 =
        Theme.Surface

    MinimizeButton.Size =
        UDim2.new(
            0,
            28,
            0,
            20
        )

    MinimizeButton.Position =
        UDim2.new(
            1,
            -66,
            0.5,
            -10
        )

    MinimizeButton.Text = "_"
    MinimizeButton.Font = Theme.FontBold
    MinimizeButton.TextSize = 15
    MinimizeButton.TextColor3 = Theme.Accent

    MinimizeButton.BorderSizePixel = 0
    MinimizeButton.AutoButtonColor = false
    MinimizeButton.ZIndex = 8
    MinimizeButton.Parent = TitleBar

    Decorate(
        MinimizeButton,
        UDim.new(0, 3),
        Theme.Border,
        1
    )

    track(
        MinimizeButton.MouseEnter:Connect(function()
            tw(
                MinimizeButton,
                {
                    BackgroundColor3 =
                        Theme.SurfaceAlt
                }
            )
        end)
    )

    track(
        MinimizeButton.MouseLeave:Connect(function()
            tw(
                MinimizeButton,
                {
                    BackgroundColor3 =
                        Theme.Surface
                }
            )
        end)
    )

    MakeDraggable(
        TitleBar,
        WindowFrame,
        track
    )

    --------------------------------------------------------------------
    -- TAB BAR
    --------------------------------------------------------------------

    local TabBar = Instance.new("ScrollingFrame")

    TabBar.Name = "TabBar"

    TabBar.BackgroundColor3 =
        Theme.TitleBar

    TabBar.BorderSizePixel = 0

    TabBar.Size =
        UDim2.new(
            1,
            0,
            0,
            30
        )

    TabBar.Position =
        UDim2.new(
            0,
            0,
            0,
            40
        )

    TabBar.ZIndex = 5

    TabBar.ScrollingDirection =
        Enum.ScrollingDirection.X

    TabBar.ScrollBarThickness = 2

    TabBar.ScrollBarImageColor3 =
        Theme.AccentDim

    TabBar.CanvasSize =
        UDim2.new(0, 0, 0, 0)

    TabBar.AutomaticCanvasSize =
        Enum.AutomaticSize.X

    TabBar.Parent = WindowFrame

    local TabBarLayout = Instance.new("UIListLayout")

    TabBarLayout.FillDirection =
        Enum.FillDirection.Horizontal

    TabBarLayout.SortOrder =
        Enum.SortOrder.LayoutOrder

    TabBarLayout.Padding =
        UDim.new(0, 2)

    TabBarLayout.Parent = TabBar

    local TabPadding = Instance.new("UIPadding")

    TabPadding.PaddingLeft =
        UDim.new(0, 4)

    TabPadding.Parent = TabBar

    --------------------------------------------------------------------
    -- CONTENT
    --------------------------------------------------------------------

    local CONTENT_TOP = 71
    local STATUSBAR_HEIGHT = 18

    local ContentArea = NewFrame({
        Name = "ContentArea",

        Color = Theme.Background,

        Size =
            UDim2.new(
                1,
                0,
                1,
                -(CONTENT_TOP + STATUSBAR_HEIGHT)
            ),

        Pos =
            UDim2.new(
                0,
                0,
                0,
                CONTENT_TOP
            ),

        Z = 3,

        Parent = WindowFrame,
    })

    --------------------------------------------------------------------
    -- STATUS BAR
    --------------------------------------------------------------------

    local StatusBar = NewFrame({
        Name = "StatusBar",
        Color = Theme.TitleBar,

        Size =
            UDim2.new(
                1,
                0,
                0,
                STATUSBAR_HEIGHT
            ),

        Pos =
            UDim2.new(
                0,
                0,
                1,
                -STATUSBAR_HEIGHT
            ),

        Z = 5,

        Parent = WindowFrame,
    })

    NewLabel({
        Text =
            "◈ SYSTEM ONLINE // PLASMA // READY",

        Color = Theme.BorderDim,
        Font = Theme.FontMono,
        Size2 = 10,

        AlignX =
            Enum.TextXAlignment.Center,

        Z = 6,
        Parent = StatusBar,
    })

    --------------------------------------------------------------------
    -- MINIMIZE STATE
    --------------------------------------------------------------------

    local minimized = false

    track(
        MinimizeButton.MouseButton1Click:Connect(function()
            minimized = not minimized

            if minimized then
                TabBar.Visible = false
                ContentArea.Visible = false
                StatusBar.Visible = false

                tw(
                    WindowFrame,
                    {
                        Size =
                            UDim2.new(
                                0,
                                WIDTH,
                                0,
                                40
                            ),
                    },
                    Theme.TweenSlow
                )
            else
                tw(
                    WindowFrame,
                    {
                        Size =
                            UDim2.new(
                                0,
                                WIDTH,
                                0,
                                HEIGHT
                            ),
                    },
                    Theme.TweenSlow
                )

                task.delay(
                    0.32,
                    function()
                        if minimized then
                            return
                        end

                        TabBar.Visible = true
                        ContentArea.Visible = true
                        StatusBar.Visible = true
                    end
                )
            end
        end)
    )

    --------------------------------------------------------------------
    -- TAB MANAGEMENT
    --------------------------------------------------------------------

    local Tabs = {}
    local ActiveTab = 0
    local ActiveDropdownCloser = nil

    local function SetActiveTab(index)
        if ActiveTab == index then
            return
        end

        ActiveTab = index

        for i, entry in ipairs(Tabs) do
            if i == index then
                tw(
                    entry.Button,
                    {
                        BackgroundColor3 =
                            Theme.TabActive,

                        TextColor3 =
                            Theme.Background,
                    }
                )

                entry.Page.Visible = true
            else
                tw(
                    entry.Button,
                    {
                        BackgroundColor3 =
                            Theme.TabInactive,

                        TextColor3 =
                            Theme.TextSecondary,
                    }
                )

                entry.Page.Visible = false
            end
        end
    end

    --------------------------------------------------------------------
    -- WINDOW API
    --------------------------------------------------------------------

    function Window:SetIcon(id)
        Icon.Image = getIconAsset(id)
    end

    function Window:GetGui()
        return ScreenGui
    end

    function Window:GetFrame()
        return WindowFrame
    end

    function Window:IsMinimized()
        return minimized
    end

    function Window:SetMinimized(state)
        state = state == true

        if minimized == state then
            return
        end

        MinimizeButton:Activate()
    end

    function Window:Destroy()
        for _, contextMenu in ipairs(ContextMenus) do
            pcall(function()
                contextMenu:Destroy()
            end)
        end

        table.clear(ContextMenus)

        for _, connection in ipairs(Connections) do
            pcall(function()
                connection:Disconnect()
            end)
        end

        table.clear(Connections)

        pcall(function()
            ScreenGui:Destroy()
        end)
    end

    --------------------------------------------------------------------
    -- WINDOW TOGGLE KEY
    --------------------------------------------------------------------

    if TOGGLE_KEY then
        track(
            UserInputService.InputBegan:Connect(
                function(input, processed)
                    if processed then
                        return
                    end

                    if input.KeyCode == TOGGLE_KEY then
                        WindowFrame.Visible =
                            not WindowFrame.Visible
                    end
                end
            )
        )
    end

    --------------------------------------------------------------------
    -- PLAYER CONTEXT MENU
    --------------------------------------------------------------------

    function Window:CreatePlayerContextMenu(options)
        options = options or {}

        local enabled =
            options.Enabled ~= false

        local width =
            tonumber(options.Width) or 205

        local titleHeight = 34
        local buttonHeight = 31
        local buttonGap = 4
        local padding = 6

        local destroyed = false
        local opened = false

        local targetPlayer = nil
        local targetCharacter = nil

        local contextConnections = {}
        local menu = nil
        local menuScale = nil
        local actionContainer = nil
        local targetLabel = nil
        local closeToken = 0

        local function contextTrack(connection)
            if connection then
                table.insert(
                    contextConnections,
                    connection
                )
            end

            return connection
        end

        local Context = {}

        ----------------------------------------------------------------
        -- TARGET DETECTION
        ----------------------------------------------------------------

        local function findCharacterFromInstance(instance)
            if not instance then
                return nil
            end

            local cursor = instance

            while cursor do
                if cursor:IsA("Model") then
                    local player =
                        Players:GetPlayerFromCharacter(
                            cursor
                        )

                    if player then
                        return player, cursor
                    end
                end

                cursor = cursor.Parent
            end

            return nil
        end

        ----------------------------------------------------------------
        -- POSITION
        ----------------------------------------------------------------

        local function clampMenuPosition(x, y)
            local camera =
                workspace.CurrentCamera

            local viewport =
                camera
                and camera.ViewportSize
                or Vector2.new(1920, 1080)

            local size =
                menu.AbsoluteSize

            local margin = 5

            local finalX =
                math.clamp(
                    x,
                    margin,
                    math.max(
                        margin,
                        viewport.X
                            - size.X
                            - margin
                    )
                )

            local finalY =
                math.clamp(
                    y,
                    margin,
                    math.max(
                        margin,
                        viewport.Y
                            - size.Y
                            - margin
                    )
                )

            return finalX, finalY
        end

        ----------------------------------------------------------------
        -- INSIDE CHECK
        ----------------------------------------------------------------

        local function isInside(
            guiObject,
            position
        )
            if not guiObject
                or not guiObject.Visible
            then
                return false
            end

            local absolutePosition =
                guiObject.AbsolutePosition

            local absoluteSize =
                guiObject.AbsoluteSize

            return
                position.X >= absolutePosition.X
                and position.X
                    <= absolutePosition.X
                        + absoluteSize.X

                and position.Y >= absolutePosition.Y
                and position.Y
                    <= absolutePosition.Y
                        + absoluteSize.Y
        end

        ----------------------------------------------------------------
        -- CLOSE
        ----------------------------------------------------------------

        local function close(animated)
            if not menu then
                return
            end

            if not opened then
                targetPlayer = nil
                targetCharacter = nil
                return
            end

            opened = false
            closeToken += 1

            local token = closeToken

            if animated then
                tw(
                    menuScale,
                    {
                        Scale = 0.92
                    },
                    Theme.ContextClose
                )

                tw(
                    menu,
                    {
                        BackgroundTransparency = 1
                    },
                    Theme.ContextClose
                )

                task.delay(
                    0.11,
                    function()
                        if token ~= closeToken then
                            return
                        end

                        if menu then
                            menu.Visible = false
                        end
                    end
                )
            else
                menu.Visible = false
            end

            targetPlayer = nil
            targetCharacter = nil
        end

        ----------------------------------------------------------------
        -- ACTION CALLBACK
        ----------------------------------------------------------------

        local function executeAction(action)
            if destroyed then
                return
            end

            if not targetPlayer
                or not targetCharacter
            then
                close(true)
                return
            end

            local player =
                targetPlayer

            local character =
                targetCharacter

            local callback =
                action.Callback

            close(true)

            if type(callback) ~= "function" then
                return
            end

            task.spawn(function()
                local success, errorMessage =
                    pcall(
                        callback,
                        player,
                        character
                    )

                if not success then
                    warn(
                        "[PlasmaLibUI] Player context action failed:",
                        tostring(action.Id),
                        errorMessage
                    )
                end
            end)
        end

        ----------------------------------------------------------------
        -- ACTION BUTTON
        ----------------------------------------------------------------

        local function createActionButton(
            action,
            index
        )
            local button =
                Instance.new("TextButton")

            button.Name =
                "ContextAction_"
                .. tostring(
                    action.Id or index
                )

            button.Size =
                UDim2.new(
                    1,
                    0,
                    0,
                    buttonHeight
                )

            button.BackgroundColor3 =
                action.BackgroundColor
                or Theme.Surface

            button.BorderSizePixel = 0

            button.AutoButtonColor = false

            button.Text =
                action.Text
                or tostring(
                    action.Id or "ACTION"
                )

            button.Font =
                action.Font
                or Theme.FontMono

            button.TextSize =
                action.TextSize
                or Theme.TextSizeSmall

            button.TextColor3 =
                action.TextColor
                or Theme.TextPrimary

            button.TextXAlignment =
                Enum.TextXAlignment.Left

            button.TextTruncate =
                Enum.TextTruncate.AtEnd

            button.ZIndex = 1010
            button.LayoutOrder = index

            button.Parent =
                actionContainer

            local paddingObject =
                Instance.new("UIPadding")

            paddingObject.PaddingLeft =
                UDim.new(0, 8)

            paddingObject.Parent = button

            Decorate(
                button,
                UDim.new(0, 4),
                action.BorderColor
                    or Theme.BorderDim,
                1
            )

            contextTrack(
                button.MouseEnter:Connect(
                    function()
                        tw(
                            button,
                            {
                                BackgroundColor3 =
                                    action.HoverColor
                                    or Theme.ContextHover,

                                TextColor3 =
                                    action.HoverTextColor
                                    or Theme.Accent,
                            }
                        )
                    end
                )
            )

            contextTrack(
                button.MouseLeave:Connect(
                    function()
                        tw(
                            button,
                            {
                                BackgroundColor3 =
                                    action.BackgroundColor
                                    or Theme.Surface,

                                TextColor3 =
                                    action.TextColor
                                    or Theme.TextPrimary,
                            }
                        )
                    end
                )
            )

            contextTrack(
                button.MouseButton1Down:Connect(
                    function()
                        tw(
                            button,
                            {
                                BackgroundColor3 =
                                    action.PressColor
                                    or Theme.AccentDim
                            },
                            TweenInfo.new(
                                0.06,
                                Enum.EasingStyle.Quad,
                                Enum.EasingDirection.Out
                            )
                        )
                    end
                )
            )

            contextTrack(
                button.MouseButton1Up:Connect(
                    function()
                        tw(
                            button,
                            {
                                BackgroundColor3 =
                                    action.HoverColor
                                    or Theme.ContextHover
                            }
                        )
                    end
                )
            )

            contextTrack(
                button.MouseButton1Click:Connect(
                    function()
                        executeAction(action)
                    end
                )
            )

            return button
        end

        ----------------------------------------------------------------
        -- BUILD
        ----------------------------------------------------------------

        local function build()
            if menu then
                return
            end

            local parent =
                options.Parent
                or ScreenGui

            menu =
                Instance.new("Frame")

            menu.Name =
                "PlayerContextMenu"

            menu.Size =
                UDim2.new(
                    0,
                    width,
                    0,
                    0
                )

            menu.BackgroundColor3 =
                options.BackgroundColor
                or Theme.ContextBackground

            menu.BackgroundTransparency = 1

            menu.BorderSizePixel = 0

            menu.Visible = false

            menu.ZIndex = 1000

            menu.Parent = parent

            Decorate(
                menu,
                UDim.new(0, 6),
                options.BorderColor
                    or Theme.Border,
                1
            )

            menuScale =
                Instance.new("UIScale")

            menuScale.Scale = 0.92

            menuScale.Parent = menu

            ------------------------------------------------------------
            -- HEADER
            ------------------------------------------------------------

            local header =
                Instance.new("Frame")

            header.Name = "Header"

            header.BackgroundColor3 =
                Theme.ContextHeader

            header.BorderSizePixel = 0

            header.Size =
                UDim2.new(
                    1,
                    -2,
                    0,
                    titleHeight
                )

            header.Position =
                UDim2.new(
                    0,
                    1,
                    0,
                    1
                )

            header.ZIndex = 1005

            header.Parent = menu

            local headerCorner =
                Instance.new("UICorner")

            headerCorner.CornerRadius =
                UDim.new(0, 5)

            headerCorner.Parent = header

            targetLabel =
                NewLabel({
                    Text = "◈ NO TARGET",

                    Color =
                        Theme.Accent,

                    Font =
                        Theme.FontMono,

                    Size2 =
                        Theme.TextSizeSmall,

                    Size =
                        UDim2.new(
                            1,
                            -16,
                            1,
                            0
                        ),

                    Pos =
                        UDim2.new(
                            0,
                            8,
                            0,
                            0
                        ),

                    Z = 1007,

                    Parent = header,
                })

            ------------------------------------------------------------
            -- DIVIDER
            ------------------------------------------------------------

            local divider =
                Instance.new("Frame")

            divider.BackgroundColor3 =
                Theme.BorderDim

            divider.BorderSizePixel = 0

            divider.Size =
                UDim2.new(
                    1,
                    -12,
                    0,
                    1
                )

            divider.Position =
                UDim2.new(
                    0,
                    6,
                    0,
                    titleHeight
                )

            divider.ZIndex = 1006

            divider.Parent = menu

            ------------------------------------------------------------
            -- ACTION CONTAINER
            ------------------------------------------------------------

            actionContainer =
                Instance.new("Frame")

            actionContainer.Name =
                "Actions"

            actionContainer.BackgroundTransparency = 1

            actionContainer.Size =
                UDim2.new(
                    1,
                    -padding * 2,
                    1,
                    -(titleHeight + padding * 2)
                )

            actionContainer.Position =
                UDim2.new(
                    0,
                    padding,
                    0,
                    titleHeight + padding
                )

            actionContainer.ZIndex = 1005

            actionContainer.Parent = menu

            local list =
                Instance.new("UIListLayout")

            list.SortOrder =
                Enum.SortOrder.LayoutOrder

            list.Padding =
                UDim.new(
                    0,
                    buttonGap
                )

            list.Parent =
                actionContainer

            ------------------------------------------------------------
            -- ACTIONS
            ------------------------------------------------------------

            local actions =
                options.Actions
                or {}

            local totalHeight =
                titleHeight
                + padding * 2

            for index, action in ipairs(actions) do
                createActionButton(
                    action,
                    index
                )

                totalHeight +=
                    buttonHeight

                if index < #actions then
                    totalHeight +=
                        buttonGap
                end
            end

            totalHeight +=
                padding

            menu.Size =
                UDim2.new(
                    0,
                    width,
                    0,
                    totalHeight
                )
        end

        build()

        ----------------------------------------------------------------
        -- SHOW
        ----------------------------------------------------------------

        local function show(
            player,
            character,
            mousePosition
        )
            if destroyed
                or not enabled
            then
                return
            end

            if player == LocalPlayer then
                return
            end

            if not character
                or not character.Parent
            then
                return
            end

            if not menu then
                build()
            end

            targetPlayer = player
            targetCharacter = character

            opened = true
            closeToken += 1

            if targetLabel then
                targetLabel.Text =
                    "◈ "
                    .. string.upper(
                        player.DisplayName
                    )
                    .. "  @"
                    .. player.Name
            end

            local x =
                mousePosition.X

            local y =
                mousePosition.Y

            task.defer(function()
                if not menu
                    or destroyed
                then
                    return
                end

                x, y =
                    clampMenuPosition(
                        x,
                        y
                    )

                menu.Position =
                    UDim2.fromOffset(
                        x,
                        y
                    )

                menu.Visible = true

                menu.BackgroundTransparency = 1
                menuScale.Scale = 0.92

                tw(
                    menu,
                    {
                        BackgroundTransparency = 0
                    },
                    Theme.ContextOpen
                )

                tw(
                    menuScale,
                    {
                        Scale = 1
                    },
                    Theme.ContextOpen
                )
            end)
        end

        ----------------------------------------------------------------
        -- RIGHT CLICK TARGETING
        ----------------------------------------------------------------

        if enabled then
            contextTrack(
                UserInputService.InputBegan:Connect(
                    function(input, processed)
                        if destroyed
                            or not enabled
                        then
                            return
                        end

                        if input.UserInputType
                            ~= Enum.UserInputType.MouseButton2
                        then
                            return
                        end

                        local mouse =
                            LocalPlayer:GetMouse()

                        local hit =
                            mouse.Target

                        local player,
                            character =
                            findCharacterFromInstance(
                                hit
                            )

                        if not player
                            or not character
                        then
                            close(true)
                            return
                        end

                        if player == LocalPlayer then
                            close(true)
                            return
                        end

                        local position =
                            UserInputService:GetMouseLocation()

                        show(
                            player,
                            character,
                            position
                        )
                    end
                )
            )
        end

        ----------------------------------------------------------------
        -- OUTSIDE CLICK
        ----------------------------------------------------------------

        contextTrack(
            UserInputService.InputBegan:Connect(
                function(input)
                    if destroyed
                        or not menu
                        or not menu.Visible
                    then
                        return
                    end

                    if input.UserInputType
                        ~= Enum.UserInputType.MouseButton1
                        and input.UserInputType
                            ~= Enum.UserInputType.Touch
                    then
                        return
                    end

                    local position =
                        UserInputService:GetMouseLocation()

                    if not isInside(
                        menu,
                        position
                    ) then
                        close(true)
                    end
                end
            )
        )

        ----------------------------------------------------------------
        -- ESCAPE
        ----------------------------------------------------------------

        contextTrack(
            UserInputService.InputBegan:Connect(
                function(input)
                    if input.KeyCode
                        == Enum.KeyCode.Escape
                    then
                        close(true)
                    end
                end
            )
        )

        ----------------------------------------------------------------
        -- PUBLIC CONTEXT API
        ----------------------------------------------------------------

        function Context:SetEnabled(state)
            enabled = state == true

            if not enabled then
                close(false)
            end
        end

        function Context:IsEnabled()
            return enabled
        end

        function Context:GetTarget()
            return targetPlayer,
                targetCharacter
        end

        function Context:IsOpen()
            return opened
        end

        function Context:OpenFor(
            player,
            character,
            position
        )
            if not player then
                return
            end

            if player == LocalPlayer then
                return
            end

            character =
                character
                or player.Character

            if not character then
                return
            end

            position =
                position
                or UserInputService:GetMouseLocation()

            show(
                player,
                character,
                position
            )
        end

        function Context:Close()
            close(true)
        end

        function Context:Destroy()
            if destroyed then
                return
            end

            destroyed = true
            enabled = false

            close(false)

            for _, connection
                in ipairs(contextConnections)
            do
                pcall(function()
                    connection:Disconnect()
                end)
            end

            table.clear(
                contextConnections
            )

            if menu then
                pcall(function()
                    menu:Destroy()
                end)

                menu = nil
            end

            targetPlayer = nil
            targetCharacter = nil
        end

        table.insert(
            ContextMenus,
            Context
        )

        return Context
    end

    --------------------------------------------------------------------
    -- CREATE TAB
    --------------------------------------------------------------------

    function Window:CreateTab(name)
        name =
            tostring(
                name or "Tab"
            )

        local textSize =
            TextService:GetTextSize(
                name:upper(),
                Theme.TextSizeSmall,
                Theme.FontMono,
                Vector2.new(
                    1000,
                    20
                )
            )

        local buttonWidth =
            math.clamp(
                textSize.X + 24,
                64,
                160
            )

        local tabButton =
            Instance.new("TextButton")

        tabButton.Name =
            "TabBtn_" .. name

        tabButton.BackgroundColor3 =
            Theme.TabInactive

        tabButton.Size =
            UDim2.new(
                0,
                buttonWidth,
                1,
                -6
            )

        tabButton.Text =
            name:upper()

        tabButton.Font =
            Theme.FontMono

        tabButton.TextSize =
            Theme.TextSizeSmall

        tabButton.TextColor3 =
            Theme.TextSecondary

        tabButton.BorderSizePixel = 0
        tabButton.AutoButtonColor = false

        tabButton.LayoutOrder =
            #Tabs + 1

        tabButton.ZIndex = 7
        tabButton.Parent = TabBar

        Decorate(
            tabButton,
            UDim.new(0, 3),
            false
        )

        ---------------------------------------------------------------
        -- PAGE
        ---------------------------------------------------------------

        local page =
            Instance.new("ScrollingFrame")

        page.Name =
            "Page_" .. name

        page.BackgroundTransparency = 1
        page.BorderSizePixel = 0

        page.Size =
            UDim2.new(
                1,
                0,
                1,
                0
            )

        page.Position =
            UDim2.new(
                0,
                0,
                0,
                0
            )

        page.ScrollBarThickness = 3

        page.ScrollBarImageColor3 =
            Theme.AccentDim

        page.CanvasSize =
            UDim2.new(
                0,
                0,
                0,
                0
            )

        page.AutomaticCanvasSize =
            Enum.AutomaticSize.Y

        page.ZIndex = 4
        page.Visible = false

        page.Parent =
            ContentArea

        local listLayout =
            Instance.new("UIListLayout")

        listLayout.SortOrder =
            Enum.SortOrder.LayoutOrder

        listLayout.Padding =
            UDim.new(0, 6)

        listLayout.Parent = page

        local pagePadding =
            Instance.new("UIPadding")

        pagePadding.PaddingTop =
            UDim.new(0, 8)

        pagePadding.PaddingLeft =
            UDim.new(0, 10)

        pagePadding.PaddingRight =
            UDim.new(0, 10)

        pagePadding.PaddingBottom =
            UDim.new(0, 8)

        pagePadding.Parent = page

        local index =
            #Tabs + 1

        Tabs[index] = {
            Button = tabButton,
            Page = page,
        }

        if index == 1 then
            SetActiveTab(1)
        end

        track(
            tabButton.MouseButton1Click:Connect(function()
                SetActiveTab(index)
            end)
        )

        track(
            tabButton.MouseEnter:Connect(function()
                if ActiveTab ~= index then
                    tw(
                        tabButton,
                        {
                            BackgroundColor3 =
                                Theme.SurfaceAlt
                        }
                    )
                end
            end)
        )

        track(
            tabButton.MouseLeave:Connect(function()
                if ActiveTab ~= index then
                    tw(
                        tabButton,
                        {
                            BackgroundColor3 =
                                Theme.TabInactive
                        }
                    )
                end
            end)
        )

        local elementOrder = 0

        local function NextOrder()
            elementOrder += 1
            return elementOrder
        end

        ---------------------------------------------------------------
        -- ELEMENT CONTAINER
        ---------------------------------------------------------------

        local function ElementFrame(height)
            local frame =
                NewFrame({
                    Color =
                        Theme.SurfaceAlt,

                    Size =
                        UDim2.new(
                            1,
                            0,
                            0,
                            height or 38
                        ),

                    Z = 5,
                    Name = "Element",
                    Parent = page,
                })

            frame.LayoutOrder =
                NextOrder()

            Decorate(
                frame,
                UDim.new(0, 4),
                Theme.BorderDim,
                1
            )

            local padding =
                Instance.new("UIPadding")

            padding.PaddingLeft =
                UDim.new(0, 10)

            padding.PaddingRight =
                UDim.new(0, 10)

            padding.Parent = frame

            return frame
        end

        local Tab = {}

        ----------------------------------------------------------------
        -- LABEL
        ----------------------------------------------------------------

        function Tab:CreateLabel(text)
            local frame =
                ElementFrame(26)

            frame.BackgroundColor3 =
                Theme.Surface

            NewLabel({
                Text =
                    "// "
                    .. tostring(
                        text or ""
                    ),

                Color =
                    Theme.TextSecondary,

                Font =
                    Theme.FontMono,

                Size2 =
                    Theme.TextSizeSmall,

                Z = 6,

                Parent = frame,
            })
        end

        ----------------------------------------------------------------
        -- SECTION
        ----------------------------------------------------------------

        function Tab:CreateSection(text)
            local frame =
                ElementFrame(22)

            frame.BackgroundTransparency = 1

            NewLabel({
                Text =
                    ("── %s ──"):format(
                        tostring(
                            text or "Section"
                        ):upper()
                    ),

                Color =
                    Theme.AccentDim,

                Font =
                    Theme.FontMono,

                Size2 = 10,

                AlignX =
                    Enum.TextXAlignment.Center,

                Z = 6,

                Parent = frame,
            })
        end

        ----------------------------------------------------------------
        -- BUTTON
        ----------------------------------------------------------------

        function Tab:CreateButton(options)
            options = options or {}

            local label =
                options.Label
                or "Button"

            local callback =
                options.Callback
                or function() end

            local frame =
                ElementFrame(36)

            local button =
                Instance.new("TextButton")

            button.BackgroundColor3 =
                Theme.Surface

            button.Size =
                UDim2.new(
                    1,
                    0,
                    1,
                    0
                )

            button.Text =
                ("▶  %s"):format(
                    label:upper()
                )

            button.Font =
                Theme.FontMono

            button.TextSize =
                Theme.TextSizeBody

            button.TextColor3 =
                Theme.Accent

            button.BorderSizePixel = 0
            button.AutoButtonColor = false

            button.ZIndex = 6
            button.Parent = frame

            Decorate(
                button,
                UDim.new(0, 4),
                Theme.Border,
                1
            )

            track(
                button.MouseEnter:Connect(function()
                    tw(
                        button,
                        {
                            BackgroundColor3 =
                                Theme.SurfaceAlt,

                            TextColor3 =
                                Theme.TextPrimary,
                        }
                    )
                end)
            )

            track(
                button.MouseLeave:Connect(function()
                    tw(
                        button,
                        {
                            BackgroundColor3 =
                                Theme.Surface,

                            TextColor3 =
                                Theme.Accent,
                        }
                    )
                end)
            )

            track(
                button.MouseButton1Down:Connect(function()
                    tw(
                        button,
                        {
                            BackgroundColor3 =
                                Theme.AccentDim
                        }
                    )
                end)
            )

            track(
                button.MouseButton1Up:Connect(function()
                    tw(
                        button,
                        {
                            BackgroundColor3 =
                                Theme.SurfaceAlt
                        }
                    )
                end)
            )

            track(
                button.MouseButton1Click:Connect(function()
                    pcall(callback)
                end)
            )

            return button
        end

        ----------------------------------------------------------------
        -- TOGGLE
        ----------------------------------------------------------------

        function Tab:CreateToggle(options)
            options = options or {}

            local label =
                options.Label
                or "Toggle"

            local state =
                options.Default == true

            local callback =
                options.Callback
                or function() end

            local frame =
                ElementFrame(38)

            NewLabel({
                Text = label,

                Color =
                    Theme.TextPrimary,

                Font =
                    Theme.FontUI,

                Size2 =
                    Theme.TextSizeBody,

                Size =
                    UDim2.new(
                        1,
                        -56,
                        1,
                        0
                    ),

                Z = 6,

                Parent = frame,
            })

            local trackFrame =
                NewFrame({
                    Color =
                        state
                        and Theme.ToggleOn
                        or Theme.ToggleOff,

                    Size =
                        UDim2.new(
                            0,
                            44,
                            0,
                            22
                        ),

                    Pos =
                        UDim2.new(
                            1,
                            -44,
                            0.5,
                            -11
                        ),

                    Z = 7,

                    Parent = frame,
                })

            Decorate(
                trackFrame,
                UDim.new(0, 11),
                Theme.Border,
                1
            )

            local knob =
                NewFrame({
                    Color =
                        Theme.ToggleKnob,

                    Size =
                        UDim2.new(
                            0,
                            16,
                            0,
                            16
                        ),

                    Pos =
                        state
                        and UDim2.new(
                            1,
                            -19,
                            0.5,
                            -8
                        )
                        or UDim2.new(
                            0,
                            3,
                            0.5,
                            -8
                        ),

                    Z = 8,

                    Parent = trackFrame,
                })

            Decorate(
                knob,
                UDim.new(0, 8),
                false
            )

            local hit =
                Instance.new("TextButton")

            hit.BackgroundTransparency = 1

            hit.Size =
                UDim2.new(
                    1,
                    0,
                    1,
                    0
                )

            hit.Text = ""
            hit.ZIndex = 9
            hit.Parent = frame

            local Toggle = {}

            function Toggle:Set(value)
                state = value == true

                tw(
                    trackFrame,
                    {
                        BackgroundColor3 =
                            state
                            and Theme.ToggleOn
                            or Theme.ToggleOff,
                    }
                )

                tw(
                    knob,
                    {
                        Position =
                            state
                            and UDim2.new(
                                1,
                                -19,
                                0.5,
                                -8
                            )
                            or UDim2.new(
                                0,
                                3,
                                0.5,
                                -8
                            ),
                    }
                )

                pcall(
                    callback,
                    state
                )
            end

            function Toggle:Get()
                return state
            end

            track(
                hit.MouseButton1Click:Connect(function()
                    Toggle:Set(
                        not state
                    )
                end)
            )

            track(
                hit.MouseEnter:Connect(function()
                    tw(
                        frame,
                        {
                            BackgroundColor3 =
                                Theme.Surface
                        }
                    )
                end)
            )

            track(
                hit.MouseLeave:Connect(function()
                    tw(
                        frame,
                        {
                            BackgroundColor3 =
                                Theme.SurfaceAlt
                        }
                    )
                end)
            )

            return Toggle
        end

        ----------------------------------------------------------------
        -- SLIDER
        ----------------------------------------------------------------

        function Tab:CreateSlider(options)
            options = options or {}

            local label =
                options.Label
                or "Slider"

            local minimum =
                tonumber(
                    options.Min
                ) or 0

            local maximum =
                tonumber(
                    options.Max
                ) or 100

            local step =
                tonumber(
                    options.Step
                ) or 1

            if maximum <= minimum then
                maximum = minimum + 1
            end

            local value =
                math.clamp(
                    tonumber(
                        options.Default
                    ) or minimum,

                    minimum,
                    maximum
                )

            local callback =
                options.Callback
                or function() end

            local frame =
                ElementFrame(54)

            local topRow =
                NewFrame({
                    Trans = 1,

                    Size =
                        UDim2.new(
                            1,
                            0,
                            0,
                            22
                        ),

                    Z = 6,

                    Parent = frame,
                })

            NewLabel({
                Text = label,

                Color =
                    Theme.TextPrimary,

                Font =
                    Theme.FontUI,

                Size2 =
                    Theme.TextSizeBody,

                Size =
                    UDim2.new(
                        0.7,
                        0,
                        1,
                        0
                    ),

                Z = 7,

                Parent = topRow,
            })

            local valueLabel =
                NewLabel({
                    Text =
                        tostring(
                            value
                        ),

                    Color =
                        Theme.Accent,

                    Font =
                        Theme.FontMono,

                    Size2 =
                        Theme.TextSizeBody,

                    AlignX =
                        Enum.TextXAlignment.Right,

                    Size =
                        UDim2.new(
                            0.3,
                            0,
                            1,
                            0
                        ),

                    Pos =
                        UDim2.new(
                            0.7,
                            0,
                            0,
                            0
                        ),

                    Z = 7,

                    Parent = topRow,
                })

            local bottomRow =
                NewFrame({
                    Trans = 1,

                    Size =
                        UDim2.new(
                            1,
                            0,
                            0,
                            20
                        ),

                    Pos =
                        UDim2.new(
                            0,
                            0,
                            0,
                            26
                        ),

                    Z = 6,

                    Parent = frame,
                })

            local sliderTrack =
                NewFrame({
                    Color =
                        Theme.SliderTrack,

                    Size =
                        UDim2.new(
                            1,
                            0,
                            0,
                            8
                        ),

                    Pos =
                        UDim2.new(
                            0,
                            0,
                            0.5,
                            -4
                        ),

                    Z = 7,

                    Parent = bottomRow,
                })

            Decorate(
                sliderTrack,
                UDim.new(0, 4),
                Theme.BorderDim,
                1
            )

            local percentage =
                (value - minimum)
                / (maximum - minimum)

            local fill =
                NewFrame({
                    Color =
                        Theme.SliderFill,

                    Size =
                        UDim2.new(
                            percentage,
                            0,
                            1,
                            0
                        ),

                    Z = 8,

                    Parent = sliderTrack,
                })

            Decorate(
                fill,
                UDim.new(0, 4),
                false
            )

            local knob =
                NewFrame({
                    Color =
                        Theme.Accent,

                    Size =
                        UDim2.new(
                            0,
                            14,
                            0,
                            14
                        ),

                    Pos =
                        UDim2.new(
                            percentage,
                            -7,
                            0.5,
                            -7
                        ),

                    Z = 9,

                    Parent = sliderTrack,
                })

            Decorate(
                knob,
                UDim.new(0, 7),
                Theme.Background,
                1
            )

            local dragging = false

            local function recalculate(x)
                local size =
                    sliderTrack.AbsoluteSize.X

                if size <= 0 then
                    return
                end

                local percent =
                    math.clamp(
                        (
                            x
                            - sliderTrack.AbsolutePosition.X
                        )
                        / size,

                        0,
                        1
                    )

                local raw =
                    minimum
                    + (
                        maximum
                        - minimum
                    )
                    * percent

                local stepped =
                    math.floor(
                        (
                            raw - minimum
                        )
                        / step
                        + 0.5
                    )
                    * step
                    + minimum

                value =
                    math.clamp(
                        stepped,
                        minimum,
                        maximum
                    )

                local newPercent =
                    (
                        value
                        - minimum
                    )
                    / (
                        maximum
                        - minimum
                    )

                tw(
                    fill,
                    {
                        Size =
                            UDim2.new(
                                newPercent,
                                0,
                                1,
                                0
                            ),
                    }
                )

                tw(
                    knob,
                    {
                        Position =
                            UDim2.new(
                                newPercent,
                                -7,
                                0.5,
                                -7
                            ),
                    }
                )

                valueLabel.Text =
                    tostring(value)

                pcall(
                    callback,
                    value
                )
            end

            track(
                sliderTrack.InputBegan:Connect(function(input)
                    if input.UserInputType
                        == Enum.UserInputType.MouseButton1
                        or input.UserInputType
                            == Enum.UserInputType.Touch
                    then
                        dragging = true
                        recalculate(
                            input.Position.X
                        )
                    end
                end)
            )

            track(
                UserInputService.InputChanged:Connect(
                    function(input)
                        if not dragging then
                            return
                        end

                        if input.UserInputType
                            == Enum.UserInputType.MouseMovement
                            or input.UserInputType
                                == Enum.UserInputType.Touch
                        then
                            recalculate(
                                input.Position.X
                            )
                        end
                    end
                )
            )

            track(
                UserInputService.InputEnded:Connect(
                    function(input)
                        if input.UserInputType
                            == Enum.UserInputType.MouseButton1
                            or input.UserInputType
                                == Enum.UserInputType.Touch
                        then
                            dragging = false
                        end
                    end
                )
            )

            local Slider = {}

            function Slider:Set(number)
                value =
                    math.clamp(
                        tonumber(number)
                            or minimum,

                        minimum,
                        maximum
                    )

                local percent =
                    (
                        value
                        - minimum
                    )
                    / (
                        maximum
                        - minimum
                    )

                tw(
                    fill,
                    {
                        Size =
                            UDim2.new(
                                percent,
                                0,
                                1,
                                0
                            ),
                    }
                )

                tw(
                    knob,
                    {
                        Position =
                            UDim2.new(
                                percent,
                                -7,
                                0.5,
                                -7
                            ),
                    }
                )

                valueLabel.Text =
                    tostring(value)

                pcall(
                    callback,
                    value
                )
            end

            function Slider:Get()
                return value
            end

            return Slider
        end

        ----------------------------------------------------------------
        -- DROPDOWN
        ----------------------------------------------------------------

        function Tab:CreateDropdown(options)
            options = options or {}

            local label =
                options.Label
                or "Dropdown"

            local choices =
                options.Options
                or {}

            local callback =
                options.Callback
                or function() end

            local selected =
                options.Default
                or choices[1]
                or "None"

            local open = false
            local outsideConnection = nil

            local frame =
                ElementFrame(38)

            frame.ClipsDescendants = false

            NewLabel({
                Text = label,

                Color =
                    Theme.TextPrimary,

                Font =
                    Theme.FontUI,

                Size2 =
                    Theme.TextSizeBody,

                Size =
                    UDim2.new(
                        0.44,
                        0,
                        1,
                        0
                    ),

                Z = 6,

                Parent = frame,
            })

            local dropdownButton =
                Instance.new("TextButton")

            dropdownButton.BackgroundColor3 =
                Theme.Surface

            dropdownButton.Size =
                UDim2.new(
                    0.53,
                    0,
                    0,
                    26
                )

            dropdownButton.Position =
                UDim2.new(
                    0.46,
                    0,
                    0.5,
                    -13
                )

            dropdownButton.Text =
                ("  %s  ▾"):format(
                    tostring(selected)
                )

            dropdownButton.Font =
                Theme.FontMono

            dropdownButton.TextSize =
                Theme.TextSizeSmall

            dropdownButton.TextColor3 =
                Theme.Accent

            dropdownButton.BorderSizePixel = 0
            dropdownButton.AutoButtonColor = false

            dropdownButton.ZIndex = 7
            dropdownButton.ClipsDescendants = false

            dropdownButton.Parent =
                frame

            Decorate(
                dropdownButton,
                UDim.new(0, 4),
                Theme.Border,
                1
            )

            local maxDisplayed = 6
            local itemHeight = 28

            local listFrame =
                NewFrame({
                    Color =
                        Theme.TitleBar,

                    Size =
                        UDim2.new(
                            1,
                            0,
                            0,
                            0
                        ),

                    Pos =
                        UDim2.new(
                            0,
                            0,
                            1,
                            4
                        ),

                    Z = 22,

                    Clip = true,

                    Parent =
                        dropdownButton,
                })

            listFrame.Visible = false

            Decorate(
                listFrame,
                UDim.new(0, 4),
                Theme.Border,
                1
            )

            local itemContainer =
                Instance.new("ScrollingFrame")

            itemContainer.BackgroundTransparency = 1

            itemContainer.Size =
                UDim2.new(
                    1,
                    0,
                    1,
                    0
                )

            itemContainer.ScrollBarThickness = 3

            itemContainer.ScrollBarImageColor3 =
                Theme.AccentDim

            itemContainer.BorderSizePixel = 0

            itemContainer.ZIndex = 23

            itemContainer.Parent =
                listFrame

            local itemLayout =
                Instance.new("UIListLayout")

            itemLayout.SortOrder =
                Enum.SortOrder.LayoutOrder

            itemLayout.Parent =
                itemContainer

            local Dropdown = {}

            local function CloseDropdown()
                if not open then
                    return
                end

                open = false
                frame.ZIndex = 5

                tw(
                    listFrame,
                    {
                        Size =
                            UDim2.new(
                                1,
                                0,
                                0,
                                0
                            ),
                    }
                )

                task.delay(
                    0.16,
                    function()
                        if not open then
                            listFrame.Visible = false
                        end
                    end
                )

                if outsideConnection then
                    outsideConnection:Disconnect()
                    outsideConnection = nil
                end

                if ActiveDropdownCloser
                    == CloseDropdown
                then
                    ActiveDropdownCloser = nil
                end
            end

            local function OpenDropdown()
                if ActiveDropdownCloser
                    and ActiveDropdownCloser
                        ~= CloseDropdown
                then
                    ActiveDropdownCloser()
                end

                open = true
                frame.ZIndex = 50

                listFrame.Visible = true

                local visibleCount =
                    math.min(
                        #choices,
                        maxDisplayed
                    )

                local targetHeight =
                    visibleCount
                    * itemHeight

                itemContainer.CanvasSize =
                    UDim2.new(
                        0,
                        0,
                        0,
                        #choices
                            * itemHeight
                    )

                tw(
                    listFrame,
                    {
                        Size =
                            UDim2.new(
                                1,
                                0,
                                0,
                                targetHeight
                            ),
                    }
                )

                outsideConnection =
                    UserInputService.InputBegan:Connect(
                        function(input)
                            if input.UserInputType
                                ~= Enum.UserInputType.MouseButton1
                                and input.UserInputType
                                    ~= Enum.UserInputType.Touch
                            then
                                return
                            end

                            local position =
                                input.Position

                            local listPosition =
                                listFrame.AbsolutePosition

                            local listSize =
                                listFrame.AbsoluteSize

                            local buttonPosition =
                                dropdownButton.AbsolutePosition

                            local buttonSize =
                                dropdownButton.AbsoluteSize

                            local insideList =
                                position.X
                                    >= listPosition.X
                                and position.X
                                    <= listPosition.X
                                        + listSize.X
                                and position.Y
                                    >= listPosition.Y
                                and position.Y
                                    <= listPosition.Y
                                        + listSize.Y

                            local insideButton =
                                position.X
                                    >= buttonPosition.X
                                and position.X
                                    <= buttonPosition.X
                                        + buttonSize.X
                                and position.Y
                                    >= buttonPosition.Y
                                and position.Y
                                    <= buttonPosition.Y
                                        + buttonSize.Y

                            if not insideList
                                and not insideButton
                            then
                                CloseDropdown()
                            end
                        end
                    )

                ActiveDropdownCloser =
                    CloseDropdown
            end

            local function BuildChoices()
                for _, child
                    in ipairs(
                        itemContainer:GetChildren()
                    )
                do
                    if child:IsA("TextButton") then
                        child:Destroy()
                    end
                end

                for index, choice
                    in ipairs(choices)
                do
                    local choiceButton =
                        Instance.new("TextButton")

                    choiceButton.BackgroundColor3 =
                        Theme.TitleBar

                    choiceButton.Size =
                        UDim2.new(
                            1,
                            0,
                            0,
                            itemHeight
                        )

                    choiceButton.Text =
                        "  "
                        .. tostring(choice)

                    choiceButton.Font =
                        Theme.FontMono

                    choiceButton.TextSize =
                        Theme.TextSizeSmall

                    choiceButton.TextColor3 =
                        Theme.TextSecondary

                    choiceButton.TextXAlignment =
                        Enum.TextXAlignment.Left

                    choiceButton.BorderSizePixel = 0
                    choiceButton.AutoButtonColor = false

                    choiceButton.LayoutOrder =
                        index

                    choiceButton.ZIndex = 24

                    choiceButton.Parent =
                        itemContainer

                    track(
                        choiceButton.MouseEnter:Connect(function()
                            tw(
                                choiceButton,
                                {
                                    BackgroundColor3 =
                                        Theme.Surface,

                                    TextColor3 =
                                        Theme.TextPrimary,
                                }
                            )
                        end)
                    )

                    track(
                        choiceButton.MouseLeave:Connect(function()
                            tw(
                                choiceButton,
                                {
                                    BackgroundColor3 =
                                        Theme.TitleBar,

                                    TextColor3 =
                                        Theme.TextSecondary,
                                }
                            )
                        end)
                    )

                    track(
                        choiceButton.MouseButton1Click:Connect(function()
                            selected = choice

                            dropdownButton.Text =
                                ("  %s  ▾"):format(
                                    tostring(
                                        selected
                                    )
                                )

                            pcall(
                                callback,
                                selected
                            )

                            CloseDropdown()
                        end)
                    )
                end
            end

            BuildChoices()

            track(
                dropdownButton.MouseEnter:Connect(function()
                    tw(
                        dropdownButton,
                        {
                            BackgroundColor3 =
                                Theme.SurfaceAlt
                        }
                    )
                end)
            )

            track(
                dropdownButton.MouseLeave:Connect(function()
                    tw(
                        dropdownButton,
                        {
                            BackgroundColor3 =
                                Theme.Surface
                        }
                    )
                end)
            )

            track(
                dropdownButton.MouseButton1Click:Connect(function()
                    if open then
                        CloseDropdown()
                    else
                        OpenDropdown()
                    end
                end)
            )

            function Dropdown:Set(value)
                selected = value

                dropdownButton.Text =
                    ("  %s  ▾"):format(
                        tostring(
                            selected
                        )
                    )

                pcall(
                    callback,
                    selected
                )
            end

            function Dropdown:Get()
                return selected
            end

            function Dropdown:Refresh(newChoices)
                choices =
                    newChoices
                    or {}

                if open then
                    CloseDropdown()
                end

                BuildChoices()
            end

            function Dropdown:SetOptions(newChoices)
                self:Refresh(
                    newChoices
                )
            end

            return Dropdown
        end

        ----------------------------------------------------------------
        -- TEXT INPUT
        ----------------------------------------------------------------

        function Tab:CreateTextInput(options)
            options = options or {}

            local label =
                options.Label
                or "Input"

            local placeholder =
                options.Placeholder
                or "type here..."

            local callback =
                options.Callback
                or function() end

            local frame =
                ElementFrame(38)

            NewLabel({
                Text = label,

                Color =
                    Theme.TextPrimary,

                Font =
                    Theme.FontUI,

                Size2 =
                    Theme.TextSizeBody,

                Size =
                    UDim2.new(
                        0.38,
                        0,
                        1,
                        0
                    ),

                Z = 6,

                Parent = frame,
            })

            local box =
                Instance.new("TextBox")

            box.BackgroundColor3 =
                Theme.Surface

            box.Size =
                UDim2.new(
                    0.58,
                    0,
                    0,
                    26
                )

            box.Position =
                UDim2.new(
                    0.40,
                    0,
                    0.5,
                    -13
                )

            box.Text = ""

            box.PlaceholderText =
                placeholder

            box.PlaceholderColor3 =
                Theme.TextDisabled

            box.Font =
                Theme.FontMono

            box.TextSize =
                Theme.TextSizeSmall

            box.TextColor3 =
                Theme.Accent

            box.BorderSizePixel = 0
            box.ZIndex = 7

            box.ClearTextOnFocus = false

            box.Parent = frame

            Decorate(
                box,
                UDim.new(0, 4),
                Theme.Border,
                1
            )

            local padding =
                Instance.new("UIPadding")

            padding.PaddingLeft =
                UDim.new(0, 6)

            padding.PaddingRight =
                UDim.new(0, 6)

            padding.Parent = box

            track(
                box.Focused:Connect(function()
                    tw(
                        box,
                        {
                            BackgroundColor3 =
                                Theme.SurfaceAlt
                        }
                    )
                end)
            )

            track(
                box.FocusLost:Connect(function(enterPressed)
                    tw(
                        box,
                        {
                            BackgroundColor3 =
                                Theme.Surface
                        }
                    )

                    pcall(
                        callback,
                        box.Text,
                        enterPressed
                    )
                end)
            )

            local Input = {}

            function Input:Get()
                return box.Text
            end

            function Input:Set(value)
                box.Text =
                    tostring(
                        value or ""
                    )
            end

            function Input:Clear()
                box.Text = ""
            end

            function Input:Focus()
                box:CaptureFocus()
            end

            return Input
        end

        ----------------------------------------------------------------
        -- RETURN TAB
        ----------------------------------------------------------------

        return Tab
    end

    --------------------------------------------------------------------
    -- INITIAL WINDOW ANIMATION
    --------------------------------------------------------------------

    tw(
        WindowFrame,
        {
            Size =
                UDim2.new(
                    0,
                    WIDTH,
                    0,
                    HEIGHT
                ),
        },
        Theme.TweenSlow
    )

    return Window
end

------------------------------------------------------------------------
-- GLOBAL THEME API
------------------------------------------------------------------------

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

------------------------------------------------------------------------
-- RETURN
------------------------------------------------------------------------

return Library
