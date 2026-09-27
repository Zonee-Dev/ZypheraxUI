local ZypheraxUI = {}
ZypheraxUI.Version = "Enterprise 3.0.0"
ZypheraxUI.Flags = {}

-- // SERVICES \\ --
local Players      = game:GetService("Players")
local Player       = Players.LocalPlayer
local RunService   = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UIS          = game:GetService("UserInputService")
local CoreGui
pcall(function()
    CoreGui = cloneref and cloneref(game:GetService("CoreGui")) or game:GetService("CoreGui")
end)

-- VirtualUser: safe load (Anti-AFK)
local VirtualUser = nil
pcall(function() VirtualUser = game:GetService("VirtualUser") end)

-- // SAFE CORE GUI RESOLVER \\ --
local function GetCore()
    if RunService:IsStudio() then return Player:WaitForChild("PlayerGui") end
    local ok, h = pcall(function() return gethui() end)
    if ok and h then return h end
    if CoreGui then return CoreGui end
    return Player:WaitForChild("PlayerGui")
end

-- // THEME (Neverlose / Lyapos Dark Depth + Airflow Color System) \\ --
ZypheraxUI.Theme = {
    -- Backgrounds (Neverlose Layered Depth)
    Background       = Color3.fromRGB(12, 12, 15),
    Background2      = Color3.fromRGB(9, 9, 11),
    Surface          = Color3.fromRGB(16, 16, 20),
    Surface2         = Color3.fromRGB(22, 22, 28),
    Surface3         = Color3.fromRGB(28, 28, 36),

    -- Accents (Cyan / Airflow / Neverlose)
    Accent           = Color3.fromRGB(0, 195, 255),
    AccentDark       = Color3.fromRGB(0, 120, 200),
    AccentGradient   = Color3.fromRGB(0, 140, 220),

    -- Text
    Text             = Color3.fromRGB(240, 240, 245),
    TextMuted        = Color3.fromRGB(140, 140, 155),
    TextDim          = Color3.fromRGB(80, 80, 95),

    -- Outlines & Strokes
    Stroke           = Color3.fromRGB(30, 30, 38),
    StrokeHover      = Color3.fromRGB(60, 60, 80),
    StrokeActive     = Color3.fromRGB(0, 195, 255),

    -- Status
    Success          = Color3.fromRGB(120, 220, 150),
    Warning          = Color3.fromRGB(240, 176, 108),
    Error            = Color3.fromRGB(240, 100, 100),

    -- Sidebar & Section Styling
    SidebarBg        = Color3.fromRGB(10, 10, 13),
    SectionHeader    = Color3.fromRGB(18, 18, 24),
    SectionBg        = Color3.fromRGB(13, 13, 17),

    -- Misc Constants
    CornerSm         = UDim.new(0, 4),
    CornerMd         = UDim.new(0, 6),
    CornerLg         = UDim.new(0, 8),
    Font             = Enum.Font.GothamBold,
    FontRegular      = Enum.Font.Gotham,
}
local T = ZypheraxUI.Theme

-- // UTILITY CORE (High-Performance Engine) \\ --
local U = {} do
    function U.New(cls, props)
        local o = Instance.new(cls)
        local parent = props.Parent
        props.Parent = nil
        for k, v in pairs(props) do
            o[k] = v
        end
        if parent then o.Parent = parent end
        return o
    end

    function U.Tween(obj, t, props, style, dir)
        style = style or Enum.EasingStyle.Quint
        dir   = dir   or Enum.EasingDirection.Out
        local tw = TweenService:Create(obj, TweenInfo.new(t, style, dir), props)
        tw:Play()
        return tw
    end

    function U.Corner(parent, radius)
        return U.New("UICorner", { CornerRadius = radius or T.CornerMd, Parent = parent })
    end

    function U.Stroke(parent, color, thickness, transparency)
        return U.New("UIStroke", {
            Color = color or T.Stroke,
            Thickness = thickness or 1,
            Transparency = transparency or 0,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            Parent = parent
        })
    end

    function U.Gradient(parent, c0, c1, rotation)
        return U.New("UIGradient", {
            Color = ColorSequence.new(c0, c1),
            Rotation = rotation or 90,
            Parent = parent
        })
    end

    function U.Glow(parent, color, transparency)
        return U.New("ImageLabel", {
            Image = "rbxassetid://6014261993",
            ImageColor3 = color or T.Accent,
            ImageTransparency = transparency or 0.82,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 50, 1, 50),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            AnchorPoint = Vector2.new(0.5, 0.5),
            ScaleType = Enum.ScaleType.Slice,
            SliceCenter = Rect.new(49, 49, 450, 450),
            ZIndex = 0,
            Parent = parent
        })
    end

    function U.Ripple(btn, x, y)
        task.spawn(function()
            if not btn or not btn.Parent then return end
            btn.ClipsDescendants = true
            local circle = U.New("Frame", {
                Size = UDim2.new(0, 0, 0, 0),
                Position = UDim2.new(0, x - btn.AbsolutePosition.X, 0, y - btn.AbsolutePosition.Y),
                BackgroundColor3 = T.Accent,
                BackgroundTransparency = 0.75,
                ZIndex = btn.ZIndex + 5,
                Parent = btn
            })
            U.Corner(circle, UDim.new(1, 0))
            local sz = math.max(btn.AbsoluteSize.X, btn.AbsoluteSize.Y) * 2
            local tw = U.Tween(circle, 0.45, {
                Size = UDim2.new(0, sz, 0, sz),
                Position = UDim2.new(0.5, -sz/2, 0.5, -sz/2),
                BackgroundTransparency = 1,
            }, Enum.EasingStyle.Quad)
            tw.Completed:Connect(function()
                circle:Destroy()
            end)
        end)
    end

    function U.Divider(parent, yOffset)
        return U.New("Frame", {
            Size = UDim2.new(1, 0, 0, 1),
            Position = UDim2.new(0, 0, 0, yOffset or 0),
            BackgroundColor3 = T.Stroke,
            BorderSizePixel = 0,
            ZIndex = 5,
            Parent = parent
        })
    end

    function U.HoverEffect(frame, stroke)
        local conn1 = frame.MouseEnter:Connect(function()
            U.Tween(stroke, 0.12, { Color = T.StrokeHover })
        end)
        local conn2 = frame.MouseLeave:Connect(function()
            U.Tween(stroke, 0.25, { Color = T.Stroke })
        end)
        return conn1, conn2
    end

    -- AFK Protection (Speed Hub X style)
    local afkInitialized = false
    function ZypheraxUI:EnableAntiAFK()
        if afkInitialized then return end
        afkInitialized = true
        task.spawn(function()
            if not Player or not VirtualUser then return end
            pcall(function()
                Player.Idled:Connect(function()
                    pcall(function()
                        VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
                        task.wait(1)
                        VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
                    end)
                end)
            end)
        end)
    end
end

-- Enable Anti-AFK safely
ZypheraxUI:EnableAntiAFK()

-- // FLOATING CIRCLE TOGGLE BUTTON \\ --
local FloatingToggleGui = nil
local FloatingButton    = nil
local FloatingContainer = nil

local function EnsureFloatingButton(onToggleWindow)
    if FloatingContainer and FloatingContainer.Parent then return FloatingButton end

    FloatingToggleGui = U.New("ScreenGui", {
        Name            = "ZypheraxFloatingToggle",
        ZIndexBehavior  = Enum.ZIndexBehavior.Sibling,
        DisplayOrder    = 9999,
        ResetOnSpawn    = false,
        Parent          = GetCore()
    })

    -- Glow wrapper (larger, behind button — not clipped so glow shows)
    local glowFrame = U.New("Frame", {
        Name                  = "GlowWrapper",
        Size                  = UDim2.new(0, 76, 0, 76),
        Position              = UDim2.new(0.05, -12, 0.15, -12),
        BackgroundTransparency = 1,
        Visible               = false,
        ZIndex                = 8,
        Parent                = FloatingToggleGui
    })
    local glowImg = U.New("ImageLabel", {
        Image                 = "rbxassetid://6014261993",
        ImageColor3           = T.Accent,
        ImageTransparency     = 0.72,
        BackgroundTransparency = 1,
        Size                  = UDim2.new(1, 0, 1, 0),
        ScaleType             = Enum.ScaleType.Slice,
        SliceCenter           = Rect.new(49, 49, 450, 450),
        ZIndex                = 8,
        Parent                = glowFrame
    })

    -- Actual clickable button (clips itself so inner elements stay inside circle)
    FloatingButton = U.New("ImageButton", {
        Name                  = "FloatingCircleBtn",
        Size                  = UDim2.new(0, 52, 0, 52),
        Position              = UDim2.new(0.05, 0, 0.15, 0),
        BackgroundColor3      = T.Background2,
        BackgroundTransparency = 0.08,
        Image                 = "",
        Visible               = false,
        ZIndex                = 10,
        ClipsDescendants      = true,
        Parent                = FloatingToggleGui
    })
    U.Corner(FloatingButton, UDim.new(1, 0))
    U.Stroke(FloatingButton, T.Accent, 1.5, 0)

    -- Icon inside button
    U.New("TextLabel", {
        Text                  = "Z",
        Font                  = T.Font,
        TextSize              = 20,
        TextColor3            = T.Accent,
        BackgroundTransparency = 1,
        Size                  = UDim2.new(1, 0, 1, 0),
        ZIndex                = 11,
        Parent                = FloatingButton
    })

    -- Sync glow position whenever button moves
    local function syncGlow()
        glowFrame.Position = UDim2.new(
            FloatingButton.Position.X.Scale,
            FloatingButton.Position.X.Offset - 12,
            FloatingButton.Position.Y.Scale,
            FloatingButton.Position.Y.Offset - 12
        )
    end
    syncGlow()

    -- Draggable
    local dragging, dragStart, startPos = false, nil, nil
    FloatingButton.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or
           inp.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            dragStart = inp.Position
            startPos  = FloatingButton.Position
            local c
            c = inp.Changed:Connect(function()
                if inp.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    if c then c:Disconnect() end
                end
            end)
        end
    end)
    FloatingButton.InputChanged:Connect(function(inp)
        if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or
                         inp.UserInputType == Enum.UserInputType.Touch) then
            local d = inp.Position - dragStart
            FloatingButton.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + d.X,
                startPos.Y.Scale, startPos.Y.Offset + d.Y
            )
            syncGlow()
        end
    end)

    -- Click to restore
    local hasMoved = false
    local downPos  = Vector2.zero
    FloatingButton.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            downPos  = Vector2.new(inp.Position.X, inp.Position.Y)
            hasMoved = false
        end
    end)
    FloatingButton.InputChanged:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseMovement then
            if (Vector2.new(inp.Position.X, inp.Position.Y) - downPos).Magnitude > 4 then
                hasMoved = true
            end
        end
    end)
    FloatingButton.MouseButton1Up:Connect(function()
        if not hasMoved then
            U.Ripple(FloatingButton, Player:GetMouse().X, Player:GetMouse().Y)
            onToggleWindow(true)
        end
    end)

    FloatingContainer = glowFrame  -- track for existence check
    return FloatingButton
end

-- // NOTIFICATION SYSTEM (Lyapos / Airflow Stacked) \\ --
local NotifGui = nil
local NotifCount = 0

function ZypheraxUI:Notify(config)
    local title    = config.Title or config.Name or "Notice"
    local content  = config.Content or config.Description or ""
    local duration = config.Duration or 5
    local ntype    = config.Type or "Info"

    local typeColors = {
        Info    = T.Accent,
        Success = T.Success,
        Warning = T.Warning,
        Error   = T.Error,
    }
    local accentColor = typeColors[ntype] or T.Accent

    if not NotifGui or not NotifGui.Parent then
        NotifGui = U.New("ScreenGui", {
            Name = "ZypheraxNotifs",
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
            DisplayOrder = 9999,
            ResetOnSpawn = false,
            Parent = GetCore()
        })
    end

    NotifCount = NotifCount + 1
    local yOff = -(70 + (NotifCount - 1) * 78)

    local holder = U.New("Frame", {
        Size = UDim2.new(0, 310, 0, 70),
        Position = UDim2.new(1, 20, 1, yOff),
        BackgroundColor3 = T.Surface,
        BackgroundTransparency = 0.2,
        ClipsDescendants = true,
        Parent = NotifGui
    })
    U.Corner(holder, T.CornerMd)
    local stroke = U.Stroke(holder, accentColor, 1, 0.6)
    U.Glow(holder, accentColor, 0.88)

    U.New("Frame", {
        Size = UDim2.new(0, 3, 1, 0),
        BackgroundColor3 = accentColor,
        BorderSizePixel = 0,
        ZIndex = 2,
        Parent = holder
    })

    U.New("TextLabel", {
        Text = title,
        Font = T.Font,
        TextSize = 14,
        TextColor3 = T.Text,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 14, 0, 8),
        Size = UDim2.new(1, -20, 0, 18),
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 2,
        Parent = holder
    })

    U.New("TextLabel", {
        Text = content,
        Font = T.FontRegular,
        TextSize = 12,
        TextColor3 = T.TextMuted,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 14, 0, 28),
        Size = UDim2.new(1, -24, 0, 32),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true,
        ZIndex = 2,
        Parent = holder
    })

    local progress = U.New("Frame", {
        Size = UDim2.new(1, 0, 0, 2),
        Position = UDim2.new(0, 0, 1, -2),
        BackgroundColor3 = accentColor,
        BorderSizePixel = 0,
        ZIndex = 3,
        Parent = holder
    })

    U.Tween(holder, 0.4, { Position = UDim2.new(1, -325, 1, yOff) }, Enum.EasingStyle.Back)
    U.Tween(stroke, 0.6, { Transparency = 0 })
    U.Tween(progress, duration, { Size = UDim2.new(0, 0, 0, 2) }, Enum.EasingStyle.Linear)

    task.delay(duration, function()
        NotifCount = math.max(0, NotifCount - 1)
        local tw = U.Tween(holder, 0.3, { Position = UDim2.new(1, 20, 1, yOff) }, Enum.EasingStyle.Back, Enum.EasingDirection.In)
        tw.Completed:Connect(function()
            pcall(function() holder:Destroy() end)
        end)
    end)
end
ZypheraxUI.Notification = ZypheraxUI.Notify

-- // WATERMARK SYSTEM (Neverlose Floating Pill) \\ --
local WatermarkGui = nil
local WatermarkLabel = nil

function ZypheraxUI:Watermark(textOrList)
    if not WatermarkGui or not WatermarkGui.Parent then
        WatermarkGui = U.New("ScreenGui", {
            Name = "ZypheraxWatermark",
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
            DisplayOrder = 9998,
            ResetOnSpawn = false,
            Parent = GetCore()
        })
        local holder = U.New("Frame", {
            Position = UDim2.new(0, 20, 0, 20),
            BackgroundColor3 = T.Background2,
            BackgroundTransparency = 0.15,
            AutomaticSize = Enum.AutomaticSize.XY,
            Parent = WatermarkGui
        })
        U.Corner(holder, T.CornerSm)
        U.Stroke(holder, T.Accent, 1, 0.4)

        local line = U.New("Frame", {
            Size = UDim2.new(0, 3, 1, 0),
            BackgroundColor3 = T.Accent,
            BorderSizePixel = 0,
            Parent = holder
        })

        WatermarkLabel = U.New("TextLabel", {
            Font = T.Font,
            TextSize = 12,
            TextColor3 = T.Text,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 10, 0, 0),
            Size = UDim2.new(0, 0, 0, 24),
            AutomaticSize = Enum.AutomaticSize.X,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = holder
        })
        U.New("UIPadding", { PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 10), Parent = WatermarkLabel })
    end

    if type(textOrList) == "table" then
        WatermarkLabel.Text = table.concat(textOrList, "  |  ")
    else
        WatermarkLabel.Text = tostring(textOrList)
    end
end

-- // KEYBIND LIST SYSTEM (Neverlose Floating Window) \\ --
function ZypheraxUI:KeybindList(title)
    local kbGui = U.New("ScreenGui", {
        Name = "ZypheraxKeybindList",
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 9997,
        ResetOnSpawn = false,
        Parent = GetCore()
    })

    local frame = U.New("Frame", {
        Size = UDim2.new(0, 180, 0, 130),
        Position = UDim2.new(0, 20, 0.4, 0),
        BackgroundColor3 = T.Background,
        BackgroundTransparency = 0.2,
        Visible = false, -- Hidden by default
        Parent = kbGui
    })
    U.Corner(frame, T.CornerSm)
    U.Stroke(frame, T.Stroke, 1, 0)

    local header = U.New("Frame", {
        Size = UDim2.new(1, 0, 0, 26),
        BackgroundColor3 = T.Surface,
        BackgroundTransparency = 0.2,
        Parent = frame
    })
    U.Corner(header, T.CornerSm)
    U.New("TextLabel", {
        Text = title or "Keybinds",
        Font = T.Font,
        TextSize = 12,
        TextColor3 = T.Text,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 0),
        Size = UDim2.new(1, -20, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = header
    })

    return frame
end

-- // MAIN WINDOW BUILDER (Neverlose Double-Column Layout + Speed Hub Circle Minimize) \\ --
function ZypheraxUI:CreateWindow(config)
    config = config or {}
    local title   = config.Title or config.Name or "Zypherax UI"
    local sub     = config.Description or config.SubName or "Enterprise Edition"
    local size    = config.Size or UDim2.fromOffset(660, 480)
    local keybind = config.Keybind or Enum.KeyCode.RightControl
    local logo    = config.Logo

    local core = GetCore()
    local connections = {}

    local function trackConnection(conn)
        table.insert(connections, conn)
        return conn
    end

    -- Root ScreenGui
    local gui = U.New("ScreenGui", {
        Name = "ZypheraxApp_" .. title,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 100,
        ResetOnSpawn = false,
        Parent = core
    })

    -- Drop shadow
    local shadow = U.New("ImageLabel", {
        Image = "rbxassetid://6014261993",
        ImageColor3 = Color3.new(0, 0, 0),
        ImageTransparency = 0.45,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, size.X.Offset + 70, 0, size.Y.Offset + 70),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(49, 49, 450, 450),
        ZIndex = 0,
        Parent = gui
    })

    -- Main window frame
    local main = U.New("Frame", {
        Size = size,
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = T.Background,
        BackgroundTransparency = 0.15,
        ClipsDescendants = true,
        ZIndex = 1,
        Parent = shadow
    })
    U.Corner(main, T.CornerLg)
    U.Stroke(main, T.Stroke, 1.2, 0)

    -- Top Glow (subtle cyan at top edge)
    U.Glow(main, T.Accent, 0.92)

    -- // OVERLAY CONTROL BUTTONS (top-right corner of window) \\ --
    local ctrlContainer = U.New("Frame", {
        Size                   = UDim2.new(0, 68, 0, 30),
        Position               = UDim2.new(1, -76, 0, 10),
        BackgroundTransparency = 1,
        ZIndex                 = 20,
        Parent                 = main
    })
    U.New("UIListLayout", {
        FillDirection        = Enum.FillDirection.Horizontal,
        HorizontalAlignment  = Enum.HorizontalAlignment.Right,
        VerticalAlignment    = Enum.VerticalAlignment.Center,
        Padding              = UDim.new(0, 4),
        Parent               = ctrlContainer
    })

    local function makeCtrlBtn(symbol, hoverColor)
        local wrap = U.New("Frame", {
            Size                   = UDim2.new(0, 26, 0, 26),
            BackgroundColor3       = T.Surface3,
            BackgroundTransparency = 0.5,
            ZIndex                 = 20,
            Parent                 = ctrlContainer
        })
        U.Corner(wrap, T.CornerSm)
        local wStroke = U.Stroke(wrap, T.Stroke, 1, 0.3)
        local lbl = U.New("TextLabel", {
            Text                   = symbol,
            Font                   = T.Font,
            TextSize               = 12,
            TextColor3             = T.TextDim,
            BackgroundTransparency = 1,
            Size                   = UDim2.new(1, 0, 1, 0),
            ZIndex                 = 21,
            Parent                 = wrap
        })
        local btn = U.New("TextButton", {
            Size                   = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Text                   = "",
            AutoButtonColor        = false,
            ZIndex                 = 22,
            Parent                 = wrap
        })
        trackConnection(btn.MouseEnter:Connect(function()
            U.Tween(wrap,    0.12, { BackgroundColor3 = hoverColor, BackgroundTransparency = 0.05 })
            U.Tween(wStroke, 0.12, { Color = hoverColor, Transparency = 0 })
            U.Tween(lbl,     0.12, { TextColor3 = Color3.new(1,1,1) })
        end))
        trackConnection(btn.MouseLeave:Connect(function()
            U.Tween(wrap,    0.2, { BackgroundColor3 = T.Surface3, BackgroundTransparency = 0.5 })
            U.Tween(wStroke, 0.2, { Color = T.Stroke, Transparency = 0.3 })
            U.Tween(lbl,     0.2, { TextColor3 = T.TextDim })
        end))
        return btn
    end

    local closeBtn = makeCtrlBtn("✕", T.Error)
    local minBtn   = makeCtrlBtn("−", T.Warning)

    -- Window Object
    local Win = { Tabs = {}, Pages = {}, _currentTab = nil }

    function Win:Destroy()
        for _, c in ipairs(connections) do
            if c and c.Connected then pcall(function() c:Disconnect() end) end
        end
        table.clear(connections)
        if gui then pcall(function() gui:Destroy() end) end
        if FloatingToggleGui then pcall(function() FloatingToggleGui:Destroy() end) end
    end

    -- Toggle Window Visibility & Floating Bubble
    local floatBtn = EnsureFloatingButton(function()
        Win:ToggleVisibility(true)
    end)

    function Win:ToggleVisibility(visible)
        if visible == nil then visible = not gui.Enabled end
        if visible then
            gui.Enabled = true
            floatBtn.Visible = false
            if FloatingContainer then FloatingContainer.Visible = false end
            main.Size = UDim2.new(0, size.X.Offset * 0.92, 0, size.Y.Offset * 0.92)
            main.BackgroundTransparency = 1
            U.Tween(main, 0.32, { Size = size, BackgroundTransparency = 0.08 }, Enum.EasingStyle.Quint)
        else
            U.Tween(main, 0.22, {
                Size = UDim2.new(0, size.X.Offset * 0.92, 0, size.Y.Offset * 0.92),
                BackgroundTransparency = 1
            }, Enum.EasingStyle.Quint).Completed:Connect(function()
                gui.Enabled = false
                floatBtn.Visible = true
                if FloatingContainer then FloatingContainer.Visible = true end
            end)
        end
    end

    trackConnection(closeBtn.MouseButton1Click:Connect(function()
        U.Ripple(closeBtn, Player:GetMouse().X, Player:GetMouse().Y)
        Win:Destroy()
    end))
    trackConnection(minBtn.MouseButton1Click:Connect(function()
        U.Ripple(minBtn, Player:GetMouse().X, Player:GetMouse().Y)
        Win:ToggleVisibility(false)
    end))

    -- Keybind Listener
    local registeredKeybinds = {}
    trackConnection(UIS.InputBegan:Connect(function(inp, gp)
        if gp then return end
        if inp.KeyCode == keybind then
            Win:ToggleVisibility()
        else
            for _, kb in ipairs(registeredKeybinds) do
                if inp.KeyCode == kb.key then kb.callback(kb.key) end
            end
        end
    end))

    -- // SIDEBAR (Full height, left column — matches reference image) \\ --
    local SIDEBAR_W = 240
    local sidebar = U.New("Frame", {
        Size             = UDim2.new(0, SIDEBAR_W, 1, 0),
        Position         = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = T.SidebarBg,
        BorderSizePixel  = 0,
        ClipsDescendants = true,
        ZIndex           = 2,
        Parent           = main
    })
    U.Corner(sidebar, T.CornerLg)
    -- Right border separator
    U.New("Frame", {
        Size             = UDim2.new(0, 1, 1, 0),
        Position         = UDim2.new(1, 0, 0, 0),
        BackgroundColor3 = T.Stroke,
        BorderSizePixel  = 0,
        ZIndex           = 3,
        Parent           = sidebar
    })
    -- Fill bottom-left corner to be square (covers the rounded corners on the right side)
    U.New("Frame", {
        Size             = UDim2.new(0, T.CornerLg.Offset, 1, 0),
        Position         = UDim2.new(1, -T.CornerLg.Offset, 0, 0),
        BackgroundColor3 = T.SidebarBg,
        BorderSizePixel  = 0,
        ZIndex           = 2,
        Parent           = sidebar
    })

    -- // SIDEBAR HEADER (Logo + Title + drag area) \\ --
    local sidebarHeader = U.New("Frame", {
        Size             = UDim2.new(1, 0, 0, 72),
        BackgroundTransparency = 1,
        ZIndex           = 4,
        Parent           = sidebar
    })

    -- Logo box (white square placeholder)
    local logoBox = U.New("Frame", {
        Size             = UDim2.new(0, 44, 0, 44),
        Position         = UDim2.new(0, 14, 0.5, -22),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        ZIndex           = 5,
        Parent           = sidebarHeader
    })
    U.Corner(logoBox, UDim.new(0, 6))
    -- Logo image (loads if config.Logo provided, otherwise shows "Z")
    local logoImg = U.New("ImageLabel", {
        Size                   = UDim2.new(1, -6, 1, -6),
        Position               = UDim2.new(0, 3, 0, 3),
        BackgroundTransparency = 1,
        Image                  = logo or "",
        ZIndex                 = 6,
        Parent                 = logoBox
    })
    if not logo or logo == "" then
        logoImg.Visible = false
        U.New("TextLabel", {
            Text                   = "Z",
            Font                   = T.Font,
            TextSize               = 22,
            TextColor3             = T.Accent,
            BackgroundTransparency = 1,
            Size                   = UDim2.new(1, 0, 1, 0),
            ZIndex                 = 6,
            Parent                 = logoBox
        })
    end

    -- Title text (blue/bold, like in reference)
    U.New("TextLabel", {
        Text                   = string.upper(title),
        Font                   = T.Font,
        TextSize               = 15,
        TextColor3             = T.Accent,
        BackgroundTransparency = 1,
        Position               = UDim2.new(0, 66, 0, 16),
        Size                   = UDim2.new(1, -80, 0, 18),
        TextXAlignment         = Enum.TextXAlignment.Left,
        ZIndex                 = 5,
        Parent                 = sidebarHeader
    })
    U.New("TextLabel", {
        Text                   = sub,
        Font                   = T.FontRegular,
        TextSize               = 10,
        TextColor3             = T.TextMuted,
        BackgroundTransparency = 1,
        Position               = UDim2.new(0, 66, 0, 36),
        Size                   = UDim2.new(1, -80, 0, 14),
        TextXAlignment         = Enum.TextXAlignment.Left,
        ZIndex                 = 5,
        Parent                 = sidebarHeader
    })

    -- Blue underline divider below header (matching reference image)
    local headerDivider = U.New("Frame", {
        Size             = UDim2.new(1, -20, 0, 1.5),
        Position         = UDim2.new(0, 10, 1, -1),
        BackgroundColor3 = T.Accent,
        BorderSizePixel  = 0,
        ZIndex           = 5,
        Parent           = sidebarHeader
    })
    U.New("UIGradient", {
        Color    = ColorSequence.new(T.Accent, Color3.fromRGB(0,0,0)),
        Rotation = 0,
        Parent   = headerDivider
    })

    -- Draggable (drag on sidebar header)
    local dragging, dragStart, startPos = false, nil, nil
    trackConnection(sidebarHeader.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or
           inp.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            dragStart = inp.Position
            startPos  = shadow.Position
            local c
            c = inp.Changed:Connect(function()
                if inp.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    if c then c:Disconnect() end
                end
            end)
        end
    end))
    trackConnection(sidebarHeader.InputChanged:Connect(function(inp)
        if dragging and (
            inp.UserInputType == Enum.UserInputType.MouseMovement or
            inp.UserInputType == Enum.UserInputType.Touch
        ) then
            local d = inp.Position - dragStart
            shadow.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + d.X,
                startPos.Y.Scale, startPos.Y.Offset + d.Y
            )
        end
    end))

    -- // SIDEBAR TAB LIST (scrollable, pill-style) \\ --
    local tabList = U.New("ScrollingFrame", {
        Size                   = UDim2.new(1, 0, 1, -72 - 80),  -- leave room for header + footer
        Position               = UDim2.new(0, 0, 0, 72),
        BackgroundTransparency = 1,
        ScrollBarThickness     = 0,
        AutomaticCanvasSize    = Enum.AutomaticSize.Y,
        CanvasSize             = UDim2.new(0, 0, 0, 0),
        ZIndex                 = 3,
        Parent                 = sidebar
    })
    U.New("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding   = UDim.new(0, 3),
        Parent    = tabList
    })
    U.New("UIPadding", {
        PaddingLeft   = UDim.new(0, 10),
        PaddingRight  = UDim.new(0, 10),
        PaddingTop    = UDim.new(0, 8),
        Parent        = tabList
    })

    -- // SIDEBAR PLAYER FOOTER CARD \\ --
    local footer = U.New("Frame", {
        Size             = UDim2.new(1, 0, 0, 72),
        Position         = UDim2.new(0, 0, 1, -72),
        BackgroundColor3 = T.Surface,
        BackgroundTransparency = 0.3,
        BorderSizePixel  = 0,
        ZIndex           = 4,
        Parent           = sidebar
    })
    -- Top border of footer
    U.New("Frame", {
        Size             = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = T.Stroke,
        BorderSizePixel  = 0,
        ZIndex           = 5,
        Parent           = footer
    })

    -- Avatar circle
    local avatarFrame = U.New("Frame", {
        Size             = UDim2.new(0, 44, 0, 44),
        Position         = UDim2.new(0, 12, 0.5, -22),
        BackgroundColor3 = T.Surface3,
        ZIndex           = 5,
        Parent           = footer
    })
    U.Corner(avatarFrame, UDim.new(1, 0))
    U.Stroke(avatarFrame, T.Accent, 1.5, 0.3)

    local avatarImg = U.New("ImageLabel", {
        Size                   = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Image                  = "",
        ScaleType              = Enum.ScaleType.Crop,
        ZIndex                 = 6,
        Parent                 = avatarFrame
    })
    U.Corner(avatarImg, UDim.new(1, 0))

    -- Load avatar async
    task.spawn(function()
        local ok, url = pcall(function()
            return Players:GetUserThumbnailAsync(
                Player.UserId,
                Enum.ThumbnailType.AvatarBust,
                Enum.ThumbnailSize.Size100x100
            )
        end)
        if ok and url then avatarImg.Image = url end
    end)

    -- Online status dot
    local statusDot = U.New("Frame", {
        Size             = UDim2.new(0, 10, 0, 10),
        Position         = UDim2.new(1, -2, 1, -2),
        AnchorPoint      = Vector2.new(1, 1),
        BackgroundColor3 = T.Success,
        ZIndex           = 7,
        Parent           = avatarFrame
    })
    U.Corner(statusDot, UDim.new(1, 0))
    U.Stroke(statusDot, T.SidebarBg, 1.5, 0)

    -- Username
    U.New("TextLabel", {
        Text                   = Player.DisplayName,
        Font                   = T.Font,
        TextSize               = 13,
        TextColor3             = T.Text,
        BackgroundTransparency = 1,
        Position               = UDim2.new(0, 64, 0, 14),
        Size                   = UDim2.new(1, -80, 0, 16),
        TextXAlignment         = Enum.TextXAlignment.Left,
        TextTruncate           = Enum.TextTruncate.AtEnd,
        ZIndex                 = 5,
        Parent                 = footer
    })

    -- @username muted
    U.New("TextLabel", {
        Text                   = "@" .. Player.Name,
        Font                   = T.FontRegular,
        TextSize               = 10,
        TextColor3             = T.TextMuted,
        BackgroundTransparency = 1,
        Position               = UDim2.new(0, 64, 0, 32),
        Size                   = UDim2.new(1, -80, 0, 13),
        TextXAlignment         = Enum.TextXAlignment.Left,
        TextTruncate           = Enum.TextTruncate.AtEnd,
        ZIndex                 = 5,
        Parent                 = footer
    })

    -- Status badge ("Online" pill)
    local statusBadge = U.New("Frame", {
        Size             = UDim2.new(0, 52, 0, 16),
        Position         = UDim2.new(0, 64, 0, 48),
        BackgroundColor3 = T.Success,
        BackgroundTransparency = 0.6,
        ZIndex           = 5,
        Parent           = footer
    })
    U.Corner(statusBadge, UDim.new(1, 0))
    U.New("TextLabel", {
        Text                   = "●  Online",
        Font                   = T.Font,
        TextSize               = 9,
        TextColor3             = T.Success,
        BackgroundTransparency = 1,
        Size                   = UDim2.new(1, 0, 1, 0),
        ZIndex                 = 6,
        Parent                 = statusBadge
    })


    -- // CONTENT CONTAINER (Double Column, right of sidebar) \\ --
    local contentArea = U.New("Frame", {
        Size             = UDim2.new(1, -(SIDEBAR_W + 1), 1, -8),
        Position         = UDim2.new(0, SIDEBAR_W + 1, 0, 4),
        BackgroundTransparency = 1,
        ZIndex           = 2,
        Parent           = main
    })

    -- // RESIZE HANDLE (bottom-right corner drag) \\ --
    local resizeHandle = U.New("Frame", {
        Size     = UDim2.new(0, 18, 0, 18),
        Position = UDim2.new(1, -18, 1, -18),
        BackgroundColor3 = T.Stroke,
        BackgroundTransparency = 0.4,
        BorderSizePixel = 0,
        ZIndex = 20,
        Parent = main
    })
    U.Corner(resizeHandle, UDim.new(0, 3))
    -- Diagonal lines icon
    U.New("TextLabel", {
        Text = "⌟", Font = T.Font, TextSize = 14,
        TextColor3 = T.TextDim, BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0), ZIndex = 21,
        Parent = resizeHandle
    })
    local resizeBtn = U.New("TextButton", {
        Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
        Text = "", AutoButtonColor = false, ZIndex = 22, Parent = resizeHandle
    })

    local MIN_W, MIN_H = 460, 340
    local resizeDragging, resizeStart, resizeOrigSize = false, nil, nil
    trackConnection(resizeBtn.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            resizeDragging = true
            resizeStart    = Vector2.new(inp.Position.X, inp.Position.Y)
            resizeOrigSize = Vector2.new(main.AbsoluteSize.X, main.AbsoluteSize.Y)
            local c
            c = inp.Changed:Connect(function()
                if inp.UserInputState == Enum.UserInputState.End then
                    resizeDragging = false
                    if c then c:Disconnect() end
                end
            end)
        end
    end))
    trackConnection(UIS.InputChanged:Connect(function(inp)
        if resizeDragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
            local delta    = Vector2.new(inp.Position.X, inp.Position.Y) - resizeStart
            local newW     = math.max(MIN_W, resizeOrigSize.X + delta.X)
            local newH     = math.max(MIN_H, resizeOrigSize.Y + delta.Y)
            local newSize  = UDim2.fromOffset(newW, newH)
            main.Size      = newSize
            shadow.Size    = UDim2.new(0, newW + 70, 0, newH + 70)
            size           = newSize
        end
    end))
    trackConnection(resizeBtn.MouseEnter:Connect(function()
        U.Tween(resizeHandle, 0.12, { BackgroundColor3 = T.Accent, BackgroundTransparency = 0.2 })
    end))
    trackConnection(resizeBtn.MouseLeave:Connect(function()
        U.Tween(resizeHandle, 0.2, { BackgroundColor3 = T.Stroke, BackgroundTransparency = 0.4 })
    end))

    -- // CREATE TAB / PAGE (Neverlose Double Column Grid Layout) \\ --
    function Win:CreateTab(nameOrCfg, icon)
        local tabName = type(nameOrCfg) == "table" and (nameOrCfg.Name or nameOrCfg.Title) or nameOrCfg
        local tabIcon = type(nameOrCfg) == "table" and (nameOrCfg.Icon or nameOrCfg.Logo) or icon

        local tabBtn = U.New("Frame", {
            Size                   = UDim2.new(1, 0, 0, 40),
            BackgroundColor3       = T.Surface2,
            BackgroundTransparency = 1,
            ZIndex                 = 4,
            Parent                 = tabList
        })
        U.Corner(tabBtn, UDim.new(0, 8))

        -- Left accent bar (pill shape, shown when active)
        local activeBar = U.New("Frame", {
            Size             = UDim2.new(0, 3, 0, 22),
            Position         = UDim2.new(0, 0, 0.5, -11),
            BackgroundColor3 = T.Accent,
            BackgroundTransparency = 1,
            ZIndex           = 5,
            Parent           = tabBtn
        })
        U.Corner(activeBar, UDim.new(1, 0))

        -- Icon (image or default circle dot)
        local iconEl
        local iconOffset = 14
        if tabIcon and tabIcon ~= "" then
            iconEl = U.New("ImageLabel", {
                Image                  = string.find(tabIcon, "rbxassetid") and tabIcon or ("rbxassetid://" .. tabIcon),
                Size                   = UDim2.new(0, 18, 0, 18),
                Position               = UDim2.new(0, 12, 0.5, -9),
                BackgroundColor3       = T.Surface3,
                BackgroundTransparency = 0.3,
                ImageColor3            = T.TextMuted,
                ZIndex                 = 5,
                Parent                 = tabBtn
            })
            U.Corner(iconEl, UDim.new(0, 4))
            iconOffset = 38
        else
            iconEl = U.New("Frame", {
                Size             = UDim2.new(0, 6, 0, 6),
                Position         = UDim2.new(0, 16, 0.5, -3),
                BackgroundColor3 = T.TextDim,
                ZIndex           = 5,
                Parent           = tabBtn
            })
            U.Corner(iconEl, UDim.new(1, 0))
        end

        local tabLbl = U.New("TextLabel", {
            Text                   = tabName,
            Font                   = T.FontRegular,
            TextSize               = 13,
            TextColor3             = T.TextMuted,
            BackgroundTransparency = 1,
            Position               = UDim2.new(0, iconOffset, 0, 0),
            Size                   = UDim2.new(1, -iconOffset - 10, 1, 0),
            TextXAlignment         = Enum.TextXAlignment.Left,
            ZIndex                 = 5,
            Parent                 = tabBtn
        })

        -- Invisible clickable overlay
        local tabBtnStroke = U.Stroke(tabBtn, T.Stroke, 1, 1)  -- hidden by default
        local clickable = U.New("TextButton", {
            Size                   = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Text                   = "",
            AutoButtonColor        = false,
            ZIndex                 = 6,
            Parent                 = tabBtn
        })

        -- Double Column Container (Side 1 = Left Column, Side 2 = Right Column)
        local pageFrame = U.New("Frame", {
            Size = UDim2.new(1, -16, 1, -16),
            Position = UDim2.new(0, 8, 0, 8),
            BackgroundTransparency = 1,
            Visible = false,
            ZIndex = 3,
            Parent = contentArea
        })

        local function makeColumn(posX, widthScale)
            local col = U.New("ScrollingFrame", {
                Size = UDim2.new(widthScale, -4, 1, 0),
                Position = UDim2.new(posX, 0, 0, 0),
                BackgroundTransparency = 1,
                ScrollBarThickness = 2,
                ScrollBarImageColor3 = T.Accent,
                ScrollBarImageTransparency = 0.6,
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                CanvasSize = UDim2.new(0, 0, 0, 0),
                ZIndex = 3,
                Parent = pageFrame
            })
            U.New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8), Parent = col })
            U.New("UIPadding", { PaddingBottom = UDim.new(0, 12), Parent = col })
            return col
        end

        local leftCol  = makeColumn(0, 0.5)
        local rightCol = makeColumn(0.5, 0.5)

        local function activate()
            for _, t in ipairs(Win.Tabs) do
                t.page.Visible = false
                -- Deactivate: remove pill bg, fade label, hide bar and icon tint
                U.Tween(t.btn,    0.18, { BackgroundTransparency = 1 })
                U.Tween(t.stroke, 0.18, { Transparency = 1 })
                U.Tween(t.lbl,    0.18, { TextColor3 = T.TextMuted, Font = T.FontRegular })
                U.Tween(t.bar,    0.18, { BackgroundTransparency = 1 })
                if t.iconEl and t.iconEl:IsA("ImageLabel") then
                    U.Tween(t.iconEl, 0.18, { ImageColor3 = T.TextMuted, BackgroundTransparency = 0.3 })
                elseif t.iconEl and t.iconEl:IsA("Frame") then
                    U.Tween(t.iconEl, 0.18, { BackgroundColor3 = T.TextDim })
                end
            end
            pageFrame.Visible = true
            -- Activate: pill bg cyan-tint, accent label, show left bar
            U.Tween(tabBtn,       0.2, { BackgroundColor3 = T.AccentDark, BackgroundTransparency = 0.7 })
            U.Tween(tabBtnStroke, 0.2, { Transparency = 0.5, Color = T.AccentDark })
            U.Tween(tabLbl,       0.2, { TextColor3 = T.Accent, Font = T.Font })
            U.Tween(activeBar,    0.2, { BackgroundTransparency = 0 })
            if iconEl and iconEl:IsA("ImageLabel") then
                U.Tween(iconEl, 0.2, { ImageColor3 = T.Accent, BackgroundTransparency = 0.1 })
            elseif iconEl and iconEl:IsA("Frame") then
                U.Tween(iconEl, 0.2, { BackgroundColor3 = T.Accent })
            end
            Win._currentTab = tabName
        end

        trackConnection(clickable.MouseButton1Click:Connect(function()
            U.Ripple(tabBtn, Player:GetMouse().X, Player:GetMouse().Y)
            activate()
        end))
        trackConnection(clickable.MouseEnter:Connect(function()
            if Win._currentTab ~= tabName then
                U.Tween(tabBtn,       0.12, { BackgroundColor3 = T.Surface3, BackgroundTransparency = 0.5 })
                U.Tween(tabLbl,       0.12, { TextColor3 = T.Text })
            end
        end))
        trackConnection(clickable.MouseLeave:Connect(function()
            if Win._currentTab ~= tabName then
                U.Tween(tabBtn,       0.2, { BackgroundTransparency = 1 })
                U.Tween(tabLbl,       0.2, { TextColor3 = T.TextMuted })
            end
        end))

        if #Win.Tabs == 0 then activate() end

        local entry = {
            btn    = tabBtn,
            stroke = tabBtnStroke,
            lbl    = tabLbl,
            bar    = activeBar,
            iconEl = iconEl,
            page   = pageFrame,
            name   = tabName
        }
        table.insert(Win.Tabs, entry)

        -- // TAB / PAGE COMPONENT API (Neverlose Sections) \\ --
        local Tab = {}

        function Tab:CreateSection(secCfg)
            local secName = type(secCfg) == "table" and (secCfg.Name or secCfg.Title) or secCfg
            local side    = type(secCfg) == "table" and (secCfg.Side or 1) or 1
            local targetCol = (side == 2) and rightCol or leftCol

            local sectionBox = U.New("Frame", {
                Size = UDim2.new(1, 0, 0, 0),
                BackgroundColor3 = T.SectionBg,
                AutomaticSize = Enum.AutomaticSize.Y,
                ZIndex = 4,
                Parent = targetCol
            })
            U.Corner(sectionBox, T.CornerMd)
            U.Stroke(sectionBox, T.Stroke, 1, 0)

            -- Section Header with Top Accent Gradient (Neverlose style)
            local secHeader = U.New("Frame", {
                Size = UDim2.new(1, 0, 0, 26),
                BackgroundColor3 = T.SectionHeader,
                ZIndex = 5,
                Parent = sectionBox
            })
            U.Corner(secHeader, T.CornerMd)
            U.New("Frame", { Size = UDim2.new(1, 0, 0.4, 0), Position = UDim2.new(0, 0, 0.6, 0), BackgroundColor3 = T.SectionHeader, BorderSizePixel = 0, ZIndex = 4, Parent = secHeader })
            
            -- Top accent line
            local topLine = U.New("Frame", {
                Size = UDim2.new(1, 0, 0, 1.5),
                Position = UDim2.new(0, 0, 0, 0),
                BackgroundColor3 = T.Accent,
                BorderSizePixel = 0,
                ZIndex = 6,
                Parent = secHeader
            })
            U.Gradient(topLine, T.Accent, Color3.fromRGB(0,0,0), 0)

            U.New("TextLabel", {
                Text = string.upper(secName),
                Font = T.Font,
                TextSize = 11,
                TextColor3 = T.TextMuted,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 10, 0, 0),
                Size = UDim2.new(1, -20, 1, 0),
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 6,
                Parent = secHeader
            })

            -- Elements Container inside Section
            local secContainer = U.New("Frame", {
                Size = UDim2.new(1, -12, 0, 0),
                Position = UDim2.new(0, 6, 0, 30),
                BackgroundTransparency = 1,
                AutomaticSize = Enum.AutomaticSize.Y,
                ZIndex = 5,
                Parent = sectionBox
            })
            U.New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 5), Parent = secContainer })
            U.New("UIPadding", { PaddingBottom = UDim.new(0, 8), Parent = secContainer })

            local Section = {}

            local function makeBase(height, isButton)
                local cls = isButton and "TextButton" or "Frame"
                local base = U.New(cls, {
                    Size = UDim2.new(1, 0, 0, height),
                    BackgroundColor3 = T.Surface2,
                    BorderSizePixel = 0,
                    ZIndex = 5,
                    Parent = secContainer
                })
                if isButton then
                    base.Text = ""
                    base.AutoButtonColor = false
                end
                U.Corner(base, T.CornerSm)
                local stroke = U.Stroke(base, T.Stroke, 1, 0)
                return base, stroke
            end

            -- TOGGLE
            function Section:CreateToggle(cfg)
                local nm      = cfg.Name or "Toggle"
                local flag    = cfg.Flag
                local default = cfg.Default == true
                local cb      = cfg.Callback or function() end
                local toggled = default

                if flag then ZypheraxUI.Flags[flag] = toggled end

                local base, stroke = makeBase(36)
                local h1, h2 = U.HoverEffect(base, stroke)
                trackConnection(h1); trackConnection(h2)

                U.New("TextLabel", {
                    Text = nm,
                    Font = T.FontRegular,
                    TextSize = 12,
                    TextColor3 = T.Text,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 10, 0, 0),
                    Size = UDim2.new(1, -55, 1, 0),
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 6,
                    Parent = base
                })

                local track = U.New("Frame", {
                    Size = UDim2.new(0, 34, 0, 18),
                    Position = UDim2.new(1, -42, 0.5, -9),
                    BackgroundColor3 = toggled and T.Accent or T.Surface3,
                    ZIndex = 6,
                    Parent = base
                })
                U.Corner(track, UDim.new(1, 0))

                local knob = U.New("Frame", {
                    Size = UDim2.new(0, 12, 0, 12),
                    Position = UDim2.new(0, toggled and 19 or 3, 0.5, -6),
                    BackgroundColor3 = T.Text,
                    ZIndex = 7,
                    Parent = track
                })
                U.Corner(knob, UDim.new(1, 0))

                local clickable = U.New("TextButton", { Size = UDim2.new(1,0,1,0), BackgroundTransparency=1, Text="", ZIndex=8, Parent=base })

                local function fire(silent)
                    toggled = not toggled
                    if flag then ZypheraxUI.Flags[flag] = toggled end
                    U.Tween(track, 0.2, { BackgroundColor3 = toggled and T.Accent or T.Surface3 })
                    U.Tween(knob, 0.25, { Position = UDim2.new(0, toggled and 19 or 3, 0.5, -6) }, Enum.EasingStyle.Back)
                    if not silent then cb(toggled) end
                end

                trackConnection(clickable.MouseButton1Click:Connect(function()
                    U.Ripple(clickable, Player:GetMouse().X, Player:GetMouse().Y)
                    fire()
                end))

                if default then cb(true) end
                return { Set = function(_, v) if v ~= toggled then fire(true) end end, Get = function() return toggled end }
            end
            Section.Toggle = Section.CreateToggle

            -- SLIDER
            function Section:CreateSlider(cfg)
                local nm      = cfg.Name or "Slider"
                local flag    = cfg.Flag
                local mn      = cfg.Min or 0
                local mx      = cfg.Max or 100
                local default = math.clamp(cfg.Default or mn, mn, mx)
                local suffix  = cfg.Suffix or ""
                local cb      = cfg.Callback or function() end
                local value   = default

                if flag then ZypheraxUI.Flags[flag] = value end

                local base, stroke = makeBase(48)
                local h1, h2 = U.HoverEffect(base, stroke)
                trackConnection(h1); trackConnection(h2)

                U.New("TextLabel", {
                    Text = nm,
                    Font = T.FontRegular,
                    TextSize = 12,
                    TextColor3 = T.Text,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 10, 0, 4),
                    Size = UDim2.new(1, -70, 0, 18),
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 6,
                    Parent = base
                })

                local valLbl = U.New("TextLabel", {
                    Text = tostring(default) .. suffix,
                    Font = T.Font,
                    TextSize = 11,
                    TextColor3 = T.Accent,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(1, -55, 0, 4),
                    Size = UDim2.new(0, 45, 0, 18),
                    TextXAlignment = Enum.TextXAlignment.Right,
                    ZIndex = 6,
                    Parent = base
                })

                local track = U.New("Frame", {
                    Size = UDim2.new(1, -20, 0, 4),
                    Position = UDim2.new(0, 10, 0, 32),
                    BackgroundColor3 = T.Surface3,
                    ZIndex = 6,
                    Parent = base
                })
                U.Corner(track, UDim.new(1, 0))

                local fillRatio = (default - mn) / math.max(mx - mn, 1)
                local fill = U.New("Frame", {
                    Size = UDim2.new(fillRatio, 0, 1, 0),
                    BackgroundColor3 = T.Accent,
                    ZIndex = 7,
                    Parent = track
                })
                U.Corner(fill, UDim.new(1, 0))

                local knob = U.New("Frame", {
                    Size = UDim2.new(0, 12, 0, 12),
                    Position = UDim2.new(1, -6, 0.5, -6),
                    BackgroundColor3 = T.Text,
                    ZIndex = 8,
                    Parent = fill
                })
                U.Corner(knob, UDim.new(1, 0))

                local hitbox = U.New("TextButton", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "", ZIndex = 9, Parent = base })
                local dragging = false
                local dragConn = nil

                local function updateSlider(mx_pos)
                    local rel = math.clamp((mx_pos - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
                    value = math.floor(mn + (mx - mn) * rel)
                    if flag then ZypheraxUI.Flags[flag] = value end
                    valLbl.Text = tostring(value) .. suffix
                    fill.Size = UDim2.new(rel, 0, 1, 0)
                    cb(value)
                end

                trackConnection(hitbox.InputBegan:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
                        dragging = true
                        updateSlider(UIS:GetMouseLocation().X)
                        if dragConn then dragConn:Disconnect() end
                        dragConn = UIS.InputChanged:Connect(function(mInp)
                            if dragging and (mInp.UserInputType == Enum.UserInputType.MouseMovement or mInp.UserInputType == Enum.UserInputType.Touch) then
                                updateSlider(UIS:GetMouseLocation().X)
                            end
                        end)
                    end
                end))

                trackConnection(hitbox.InputEnded:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
                        dragging = false
                        if dragConn then dragConn:Disconnect(); dragConn = nil end
                    end
                end))

                return { Set = function(_, v) value = math.clamp(v, mn, mx) local r = (value-mn)/math.max(mx-mn,1) fill.Size = UDim2.new(r,0,1,0) valLbl.Text=tostring(value)..suffix end, Get = function() return value end }
            end
            Section.Slider = Section.CreateSlider

            -- DROPDOWN
            function Section:CreateDropdown(cfg)
                local nm    = cfg.Name or "Dropdown"
                local flag  = cfg.Flag
                local items = cfg.Items or {}
                local multi = cfg.Multi == true
                local cb    = cfg.Callback or function() end
                local selected = multi and (type(cfg.Default) == "table" and cfg.Default or {}) or (cfg.Default or nil)
                local open = false

                if flag then ZypheraxUI.Flags[flag] = selected end

                local base, stroke = makeBase(34)
                base.ClipsDescendants = true

                local clickable = U.New("TextButton", { Size = UDim2.new(1,0,0,34), BackgroundTransparency = 1, Text = "", ZIndex = 6, Parent = base })

                local lbl = U.New("TextLabel", {
                    Text = nm .. " : " .. (multi and (#selected > 0 and table.concat(selected, ", ") or "None") or (selected or "None")),
                    Font = T.FontRegular,
                    TextSize = 12,
                    TextColor3 = T.Text,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 10, 0, 0),
                    Size = UDim2.new(1, -30, 0, 34),
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 6,
                    Parent = base
                })

                local chevron = U.New("TextLabel", {
                    Text = "›", Font = T.Font, TextSize = 16, TextColor3 = T.TextMuted, BackgroundTransparency = 1,
                    Position = UDim2.new(1, -22, 0, 0), Size = UDim2.new(0, 16, 0, 34), Rotation = 90, ZIndex = 6, Parent = base
                })

                local itemList = U.New("Frame", { Size = UDim2.new(1, -16, 0, 0), Position = UDim2.new(0, 8, 0, 36), BackgroundTransparency = 1, ZIndex = 6, Parent = base })
                U.New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 3), Parent = itemList })

                local rowObjects = {}

                local function updateRows()
                    for _, r in ipairs(rowObjects) do
                        local isOn = multi and table.find(selected, r.item) or selected == r.item
                        r.row.BackgroundTransparency = isOn and 0.3 or 0.7
                        r.txt.TextColor3 = isOn and T.Accent or T.TextMuted
                    end
                end

                local function buildItems()
                    if #rowObjects > 0 then updateRows(); return #items * 29 end
                    local totalH = 0
                    for _, item in ipairs(items) do
                        local isOn = multi and table.find(selected, item) or selected == item
                        local row = U.New("TextButton", {
                            Size = UDim2.new(1, 0, 0, 26), BackgroundColor3 = T.Surface3, BackgroundTransparency = isOn and 0.3 or 0.7,
                            Text = "", AutoButtonColor = false, ZIndex = 7, Parent = itemList
                        })
                        U.Corner(row, T.CornerSm)
                        local txt = U.New("TextLabel", {
                            Text = tostring(item), Font = T.FontRegular, TextSize = 11, TextColor3 = isOn and T.Accent or T.TextMuted,
                            BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0, 0), Size = UDim2.new(1, -15, 1, 0),
                            TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 8, Parent = row
                        })
                        table.insert(rowObjects, { item = item, row = row, txt = txt })

                        trackConnection(row.MouseButton1Click:Connect(function()
                            if multi then
                                local idx = table.find(selected, item)
                                if idx then table.remove(selected, idx) else table.insert(selected, item) end
                            else
                                selected = item
                                open = false
                                U.Tween(base, 0.25, { Size = UDim2.new(1, 0, 0, 34) })
                                U.Tween(chevron, 0.2, { Rotation = 90 })
                            end
                            if flag then ZypheraxUI.Flags[flag] = selected end
                            lbl.Text = nm .. " : " .. (multi and (#selected > 0 and table.concat(selected, ", ") or "None") or (selected or "None"))
                            cb(selected)
                            updateRows()
                        end))
                        totalH = totalH + 29
                    end
                    itemList.Size = UDim2.new(1, -16, 0, totalH)
                    return totalH
                end

                trackConnection(clickable.MouseButton1Click:Connect(function()
                    open = not open
                    local totalH = buildItems()
                    if open then
                        U.Tween(base, 0.3, { Size = UDim2.new(1, 0, 0, 40 + totalH) }, Enum.EasingStyle.Quint)
                        U.Tween(chevron, 0.25, { Rotation = 270 })
                    else
                        U.Tween(base, 0.3, { Size = UDim2.new(1, 0, 0, 34) }, Enum.EasingStyle.Quint)
                        U.Tween(chevron, 0.25, { Rotation = 90 })
                    end
                end))

                local h1, h2 = U.HoverEffect(base, stroke)
                trackConnection(h1); trackConnection(h2)
            end
            Section.Dropdown = Section.CreateDropdown

            -- COLORPICKER (Full HSV Panel)
            function Section:CreateColorPicker(cfg)
                local nm      = cfg.Name or "Color"
                local flag    = cfg.Flag
                local default = cfg.Default or Color3.fromRGB(0, 195, 255)
                local cb      = cfg.Callback or function() end

                local h, s, v = Color3.toHSV(default)
                local currentColor = default
                if flag then ZypheraxUI.Flags[flag] = currentColor end

                -- Row (collapsed)
                local base, stroke = makeBase(34)
                local h1, h2 = U.HoverEffect(base, stroke)
                trackConnection(h1); trackConnection(h2)

                U.New("TextLabel", {
                    Text = nm, Font = T.FontRegular, TextSize = 12, TextColor3 = T.Text,
                    BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0, 0),
                    Size = UDim2.new(1, -60, 1, 0), TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 6, Parent = base
                })

                local swatch = U.New("Frame", {
                    Size = UDim2.new(0, 28, 0, 16), Position = UDim2.new(1, -38, 0.5, -8),
                    BackgroundColor3 = currentColor, ZIndex = 6, Parent = base
                })
                U.Corner(swatch, T.CornerSm)
                U.Stroke(swatch, T.Stroke, 1, 0)

                -- Expand toggle
                local panelOpen = false
                local panel = nil

                local function buildHSVPanel()
                    panel = U.New("Frame", {
                        Size = UDim2.new(1, 0, 0, 120),
                        BackgroundColor3 = T.Surface,
                        BorderSizePixel = 0,
                        ZIndex = 6,
                        Parent = secContainer,
                        ClipsDescendants = true
                    })
                    U.Corner(panel, T.CornerSm)
                    U.Stroke(panel, T.Stroke, 1, 0)
                    U.New("UIPadding", { PaddingLeft = UDim.new(0,8), PaddingRight = UDim.new(0,8), PaddingTop = UDim.new(0,8), PaddingBottom = UDim.new(0,8), Parent = panel })

                    -- SV field (Saturation × Value 2D square)
                    local svField = U.New("ImageButton", {
                        Size = UDim2.new(0, 80, 0, 80),
                        Position = UDim2.new(0, 0, 0, 0),
                        BackgroundColor3 = Color3.fromHSV(h, 1, 1),
                        AutoButtonColor = false,
                        ZIndex = 7,
                        Parent = panel
                    })
                    U.Corner(svField, T.CornerSm)
                    -- White to transparent gradient (saturation)
                    U.New("UIGradient", {
                        Color = ColorSequence.new(Color3.new(1,1,1), Color3.new(1,1,1)),
                        Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)}),
                        Rotation = 0,
                        Parent = svField
                    })
                    -- Transparent to black gradient (value)
                    local valGrad = U.New("Frame", {
                        Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1,
                        ZIndex = 8, Parent = svField, ClipsDescendants = true
                    })
                    U.Corner(valGrad, T.CornerSm)
                    U.New("UIGradient", {
                        Color = ColorSequence.new(Color3.new(0,0,0), Color3.new(0,0,0)),
                        Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0)}),
                        Rotation = 270,
                        Parent = valGrad
                    })

                    -- SV cursor
                    local svCursor = U.New("Frame", {
                        Size = UDim2.new(0, 10, 0, 10),
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        Position = UDim2.new(s, 0, 1 - v, 0),
                        BackgroundColor3 = Color3.new(1,1,1),
                        BorderSizePixel = 0,
                        ZIndex = 10,
                        Parent = svField
                    })
                    U.Corner(svCursor, UDim.new(1, 0))
                    U.Stroke(svCursor, Color3.new(0,0,0), 1.5, 0)

                    -- Hue bar
                    local hueBar = U.New("ImageLabel", {
                        Size = UDim2.new(0, 14, 0, 80),
                        Position = UDim2.new(0, 88, 0, 0),
                        Image = "rbxassetid://2880333002", -- rainbow hue bar
                        BackgroundTransparency = 1,
                        ZIndex = 7,
                        Parent = panel
                    })
                    U.Corner(hueBar, T.CornerSm)
                    U.Stroke(hueBar, T.Stroke, 1, 0)
                    local hueBtn = U.New("TextButton", {
                        Size = UDim2.new(1,0,1,0), BackgroundTransparency=1, Text="", ZIndex=8, Parent=hueBar
                    })

                    -- Hue cursor
                    local hueCursor = U.New("Frame", {
                        Size = UDim2.new(1, 4, 0, 4),
                        Position = UDim2.new(0, -2, h, -2),
                        BackgroundColor3 = Color3.new(1,1,1),
                        BorderSizePixel = 0,
                        ZIndex = 9,
                        Parent = hueBar
                    })
                    U.Corner(hueCursor, UDim.new(0, 2))

                    -- HEX input
                    local function toHex(c)
                        return string.format("#%02X%02X%02X",
                            math.round(c.R*255), math.round(c.G*255), math.round(c.B*255))
                    end

                    local hexBox = U.New("TextBox", {
                        Size = UDim2.new(0, 80, 0, 22),
                        Position = UDim2.new(0, 0, 0, 88),
                        BackgroundColor3 = T.Surface3, Text = toHex(currentColor),
                        Font = T.Font, TextSize = 11, TextColor3 = T.Accent,
                        PlaceholderText = "#RRGGBB", ClearTextOnFocus = false,
                        TextXAlignment = Enum.TextXAlignment.Center,
                        ZIndex = 7, Parent = panel
                    })
                    U.Corner(hexBox, T.CornerSm)
                    U.Stroke(hexBox, T.Stroke, 1, 0)

                    -- Update function
                    local function applyColor()
                        currentColor = Color3.fromHSV(h, s, v)
                        swatch.BackgroundColor3 = currentColor
                        svField.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
                        svCursor.Position = UDim2.new(s, 0, 1 - v, 0)
                        hueCursor.Position = UDim2.new(0, -2, h, -2)
                        hexBox.Text = toHex(currentColor)
                        if flag then ZypheraxUI.Flags[flag] = currentColor end
                        cb(currentColor)
                    end

                    -- SV drag
                    local svDrag = false
                    svField.InputBegan:Connect(function(inp)
                        if inp.UserInputType == Enum.UserInputType.MouseButton1 then svDrag = true end
                    end)
                    local svConn
                    svField.InputBegan:Connect(function(inp)
                        if inp.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
                        svDrag = true
                        if svConn then svConn:Disconnect() end
                        svConn = UIS.InputChanged:Connect(function(m)
                            if not svDrag then return end
                            if m.UserInputType ~= Enum.UserInputType.MouseMovement then return end
                            local rel = svField.AbsolutePosition
                            local sz  = svField.AbsoluteSize
                            s = math.clamp((m.Position.X - rel.X) / sz.X, 0, 1)
                            v = 1 - math.clamp((m.Position.Y - rel.Y) / sz.Y, 0, 1)
                            applyColor()
                        end)
                    end)
                    UIS.InputEnded:Connect(function(inp)
                        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                            svDrag = false
                            if svConn then svConn:Disconnect(); svConn = nil end
                        end
                    end)

                    -- Hue drag
                    local hueDrag = false
                    local hueConn
                    hueBtn.InputBegan:Connect(function(inp)
                        if inp.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
                        hueDrag = true
                        if hueConn then hueConn:Disconnect() end
                        hueConn = UIS.InputChanged:Connect(function(m)
                            if not hueDrag then return end
                            if m.UserInputType ~= Enum.UserInputType.MouseMovement then return end
                            local rel = hueBar.AbsolutePosition
                            local sz  = hueBar.AbsoluteSize
                            h = math.clamp((m.Position.Y - rel.Y) / sz.Y, 0, 1)
                            applyColor()
                        end)
                    end)
                    UIS.InputEnded:Connect(function(inp)
                        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                            hueDrag = false
                            if hueConn then hueConn:Disconnect(); hueConn = nil end
                        end
                    end)

                    -- Hex input
                    hexBox.FocusLost:Connect(function()
                        local raw = hexBox.Text:gsub("#", "")
                        if #raw == 6 then
                            local r = tonumber(raw:sub(1,2),16)
                            local g = tonumber(raw:sub(3,4),16)
                            local b = tonumber(raw:sub(5,6),16)
                            if r and g and b then
                                h, s, v = Color3.toHSV(Color3.fromRGB(r,g,b))
                                applyColor()
                            end
                        end
                    end)
                end

                -- Toggle panel open/close
                local toggleBtn = U.New("TextButton", {
                    Size = UDim2.new(1,0,1,0), BackgroundTransparency=1, Text="", ZIndex=8, Parent=base
                })
                trackConnection(toggleBtn.MouseButton1Click:Connect(function()
                    panelOpen = not panelOpen
                    if panelOpen then
                        if not panel or not panel.Parent then buildHSVPanel() end
                        U.Tween(base, 0.2, { Size = UDim2.new(1, 0, 0, 34) })
                    else
                        if panel and panel.Parent then
                            pcall(function() panel:Destroy() end)
                            panel = nil
                        end
                    end
                end))
            end
            Section.Colorpicker = Section.CreateColorPicker

            -- KEYBIND
            function Section:CreateKeybind(cfg)
                local nm      = cfg.Name or "Keybind"
                local flag    = cfg.Flag
                local default = cfg.Default or Enum.KeyCode.Delete
                local cb      = cfg.Callback or function() end
                local current = default
                local binding = false

                if flag then ZypheraxUI.Flags[flag] = current end

                local base, stroke = makeBase(34)
                local h1, h2 = U.HoverEffect(base, stroke)
                trackConnection(h1); trackConnection(h2)

                U.New("TextLabel", {
                    Text = nm, Font = T.FontRegular, TextSize = 12, TextColor3 = T.Text, BackgroundTransparency = 1,
                    Position = UDim2.new(0, 10, 0, 0), Size = UDim2.new(1, -85, 1, 0), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6, Parent = base
                })

                local badge = U.New("Frame", {
                    Size = UDim2.new(0, 65, 0, 20), Position = UDim2.new(1, -72, 0.5, -10), BackgroundColor3 = T.Surface3, ZIndex = 6, Parent = base
                })
                U.Corner(badge, T.CornerSm)
                local bStroke = U.Stroke(badge, T.Stroke, 1, 0)

                local bLbl = U.New("TextLabel", {
                    Text = current.Name, Font = T.Font, TextSize = 10, TextColor3 = T.Accent, BackgroundTransparency = 1, Size = UDim2.new(1,0,1,0), ZIndex = 7, Parent = badge
                })

                local btn = U.New("TextButton", { Size = UDim2.new(1,0,1,0), BackgroundTransparency=1, Text="", ZIndex=8, Parent=base })
                local bindConn = nil

                local kbEntry = { key = current, callback = function(k) cb(k) end }
                table.insert(registeredKeybinds, kbEntry)

                trackConnection(btn.MouseButton1Click:Connect(function()
                    binding = true
                    bLbl.Text = "..."
                    U.Tween(bStroke, 0.15, { Color = T.Accent })

                    if bindConn then bindConn:Disconnect() end
                    bindConn = UIS.InputBegan:Connect(function(inp, gp)
                        if gp then return end
                        if inp.UserInputType == Enum.UserInputType.Keyboard then
                            binding = false
                            current = inp.KeyCode
                            kbEntry.key = current
                            if flag then ZypheraxUI.Flags[flag] = current end
                            bLbl.Text = current.Name
                            U.Tween(bStroke, 0.2, { Color = T.Stroke })
                            if bindConn then bindConn:Disconnect(); bindConn = nil end
                        end
                    end)
                end))
            end
            Section.Keybind = Section.CreateKeybind

            -- INPUT
            function Section:CreateInput(cfg)
                local nm      = cfg.Name or "Input"
                local flag    = cfg.Flag
                local ph      = cfg.Placeholder or "Type..."
                local default = cfg.Default or ""
                local cb      = cfg.Callback or function() end

                if flag then ZypheraxUI.Flags[flag] = default end

                local base, stroke = makeBase(34)
                local h1, h2 = U.HoverEffect(base, stroke)
                trackConnection(h1); trackConnection(h2)

                U.New("TextLabel", {
                    Text = nm, Font = T.FontRegular, TextSize = 12, TextColor3 = T.Text, BackgroundTransparency = 1,
                    Position = UDim2.new(0, 10, 0, 0), Size = UDim2.new(0.4, 0, 1, 0), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6, Parent = base
                })

                local inputBox = U.New("TextBox", {
                    Text = default, PlaceholderText = ph, Font = T.FontRegular, TextSize = 11, TextColor3 = T.Text, PlaceholderColor3 = T.TextDim,
                    BackgroundColor3 = T.Surface3, Position = UDim2.new(0.42, 0, 0.5, -10), Size = UDim2.new(0.55, 0, 0, 20), ClearTextOnFocus = false,
                    TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6, Parent = base
                })
                U.Corner(inputBox, T.CornerSm)
                U.Stroke(inputBox, T.Stroke, 1, 0)
                U.New("UIPadding", { PaddingLeft = UDim.new(0, 6), Parent = inputBox })

                trackConnection(inputBox.FocusLost:Connect(function(enter)
                    if flag then ZypheraxUI.Flags[flag] = inputBox.Text end
                    cb(inputBox.Text, enter)
                end))

                return { Set = function(_, v) inputBox.Text = tostring(v) end, Get = function() return inputBox.Text end }
            end
            Section.Input = Section.CreateInput

            -- BUTTON
            function Section:CreateButton(cfg)
                local nm    = cfg.Name or "Button"
                local cb    = cfg.Callback or function() end
                local style = cfg.Style

                local base, stroke = makeBase(32, true)
                if style == "Primary" then
                    base.BackgroundColor3 = T.AccentDark
                    base.BackgroundTransparency = 0.3
                    stroke.Color = T.Accent
                else
                    local c1, c2 = U.HoverEffect(base, stroke)
                    trackConnection(c1); trackConnection(c2)
                end

                U.New("TextLabel", {
                    Text = nm, Font = T.Font, TextSize = 12, TextColor3 = style == "Primary" and T.Accent or T.Text, BackgroundTransparency = 1,
                    Size = UDim2.new(1, -20, 1, 0), Position = UDim2.new(0, 10, 0, 0), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6, Parent = base
                })

                trackConnection(base.MouseButton1Click:Connect(function()
                    U.Ripple(base, Player:GetMouse().X, Player:GetMouse().Y)
                    cb()
                end))
            end
            Section.Button = Section.CreateButton

            -- LABEL
            function Section:CreateLabel(text)
                local lbl = U.New("TextLabel", {
                    Text = text, Font = T.FontRegular, TextSize = 11, TextColor3 = T.TextMuted, BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 18), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 5, Parent = secContainer
                })
                local LblObj = {}
                function LblObj:Colorpicker(cfg) return Section:CreateColorPicker(cfg) end
                function LblObj:Keybind(cfg) return Section:CreateKeybind(cfg) end
                return LblObj
            end
            Section.Label = Section.CreateLabel

            return Section
        end
        Tab.Section = Tab.CreateSection

        return Tab
    end
    Win.Page = Win.CreateTab
    Win.Category = Win.CreateTab

    -- Neverlose Theme API Compatibility
    function Win:ChangeTheme(themeKey, colorVal)
        if T[themeKey] ~= nil then
            T[themeKey] = colorVal
        end
    end

    function Win:Init()
        -- Compatibility finish method
        return Win
    end

    return Win
end

return ZypheraxUI
