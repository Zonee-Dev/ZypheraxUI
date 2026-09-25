local ZypheraxUI = {}
ZypheraxUI.Version = "Enterprise 2.0.0"

-- // SERVICES \\ --
local Players      = game:GetService("Players")
local Player       = Players.LocalPlayer
local RunService   = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UIS          = game:GetService("UserInputService")

-- VirtualUser: safe load (blocked in most games client-side)
local VirtualUser = nil
pcall(function() VirtualUser = game:GetService("VirtualUser") end)

-- // SAFE CORE GUI RESOLVER \\ --
local function GetCore()
    if RunService:IsStudio() then return Player.PlayerGui end
    local ok, h = pcall(function() return gethui() end)
    if ok and h then return h end
    local ok2, c = pcall(function() return cloneref(game:GetService("CoreGui")) end)
    if ok2 and c then return c end
    return game:GetService("CoreGui")
end

-- // THEME (Lyapos Depth + Airflow Color System) \\ --
ZypheraxUI.Theme = {
    -- Backgrounds (Lyapos layered depth)
    Background   = Color3.fromRGB(10, 10, 13),
    Background2  = Color3.fromRGB(14, 14, 17),
    Surface      = Color3.fromRGB(18, 18, 22),
    Surface2     = Color3.fromRGB(24, 24, 30),
    Surface3     = Color3.fromRGB(32, 32, 40),

    -- Accents (Airflow-style cyan-blue)
    Accent       = Color3.fromRGB(0, 195, 255),
    AccentDark   = Color3.fromRGB(0, 120, 200),
    AccentGlow   = Color3.fromRGB(0, 140, 220),

    -- Text
    Text         = Color3.fromRGB(240, 240, 245),
    TextMuted    = Color3.fromRGB(130, 130, 145),
    TextDim      = Color3.fromRGB(80, 80, 95),

    -- Strokes (Lyapos subtle outlines)
    Stroke       = Color3.fromRGB(38, 38, 48),
    StrokeHover  = Color3.fromRGB(70, 70, 90),
    StrokeActive = Color3.fromRGB(0, 195, 255),

    -- Status
    Success      = Color3.fromRGB(120, 220, 150),
    Warning      = Color3.fromRGB(240, 176, 108),
    Error        = Color3.fromRGB(240, 100, 100),

    -- Sidebar (slightly lighter than bg)
    SidebarBg    = Color3.fromRGB(13, 13, 17),
    TabActive    = Color3.fromRGB(20, 20, 28),

    -- Misc
    CornerSm     = UDim.new(0, 4),
    CornerMd     = UDim.new(0, 6),
    CornerLg     = UDim.new(0, 8),
    Font         = Enum.Font.GothamBold,
    FontRegular  = Enum.Font.Gotham,
}
local T = ZypheraxUI.Theme  -- shorthand

-- // UTILITY CORE (Optimized) \\ --
local U = {} do
    -- Create instance with properties + parent last (optimized loop)
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

    -- Smooth tween shorthand
    function U.Tween(obj, t, props, style, dir)
        style = style or Enum.EasingStyle.Quint
        dir   = dir   or Enum.EasingDirection.Out
        local tw = TweenService:Create(obj, TweenInfo.new(t, style, dir), props)
        tw:Play()
        return tw
    end

    -- Corner shorthand
    function U.Corner(parent, radius)
        return U.New("UICorner", { CornerRadius = radius or T.CornerMd, Parent = parent })
    end

    -- Stroke shorthand
    function U.Stroke(parent, color, thickness, transparency)
        return U.New("UIStroke", {
            Color = color or T.Stroke,
            Thickness = thickness or 1,
            Transparency = transparency or 0,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            Parent = parent
        })
    end

    -- Gradient shorthand (Lyapos style)
    function U.Gradient(parent, c0, c1, rotation)
        return U.New("UIGradient", {
            Color = ColorSequence.new(c0, c1),
            Rotation = rotation or 90,
            Parent = parent
        })
    end

    -- Glow frame (Airflow style drop shadow/glow)
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

    -- Divider line (Lyapos style)
    function U.Divider(parent, offsetY)
        return U.New("Frame", {
            Size = UDim2.new(1, 0, 0, 1),
            Position = UDim2.new(0, 0, 0, offsetY or 0),
            BackgroundColor3 = T.Stroke,
            BorderSizePixel = 0,
            ZIndex = 0,
            Parent = parent
        })
    end

    -- Ripple click effect (SpeedHubX - Pool/Fast cleanup)
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

    -- Hover stroke effect (Airflow style)
    function U.HoverEffect(frame, stroke)
        local conn1 = frame.MouseEnter:Connect(function()
            U.Tween(stroke, 0.12, { Color = T.StrokeHover })
        end)
        local conn2 = frame.MouseLeave:Connect(function()
            U.Tween(stroke, 0.25, { Color = T.Stroke })
        end)
        return conn1, conn2
    end

    -- AFK protection (Lazy single instance initialization)
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

    -- Mouse pos helper
    function U.MousePos()
        local m = Player:GetMouse()
        return m.X, m.Y
    end
end

-- Enable Anti-AFK safely
ZypheraxUI:EnableAntiAFK()

-- // NOTIFICATION SYSTEM (Lyapos-style stacked, Airflow glow) \\ --
local NotifGui = nil
local NotifCount = 0

function ZypheraxUI:Notify(config)
    local title    = config.Title or "Notice"
    local content  = config.Content or ""
    local duration = config.Duration or 5
    local ntype    = config.Type or "Info"  -- "Info" | "Success" | "Warning" | "Error"

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
        BackgroundTransparency = 0.08,
        ClipsDescendants = true,
        Parent = NotifGui
    })
    U.Corner(holder, T.CornerMd)
    local stroke = U.Stroke(holder, accentColor, 1, 0.6)

    -- Glow subtle
    U.Glow(holder, accentColor, 0.88)

    -- Left accent bar (Lyapos style)
    U.New("Frame", {
        Size = UDim2.new(0, 3, 1, 0),
        BackgroundColor3 = accentColor,
        BorderSizePixel = 0,
        ZIndex = 2,
        Parent = holder
    })

    -- Title
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

    -- Content
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

    -- Progress bar (SpeedHubX countdown)
    local progress = U.New("Frame", {
        Size = UDim2.new(1, 0, 0, 2),
        Position = UDim2.new(0, 0, 1, -2),
        BackgroundColor3 = accentColor,
        BorderSizePixel = 0,
        ZIndex = 3,
        Parent = holder
    })

    -- Animate in
    U.Tween(holder, 0.4, { Position = UDim2.new(1, -325, 1, yOff) }, Enum.EasingStyle.Back)
    U.Tween(stroke, 0.6, { Transparency = 0 })

    -- Progress drain
    U.Tween(progress, duration, { Size = UDim2.new(0, 0, 0, 2) }, Enum.EasingStyle.Linear)

    -- Animate out + cleanup
    task.delay(duration, function()
        NotifCount = math.max(0, NotifCount - 1)
        local tw = U.Tween(holder, 0.3, { Position = UDim2.new(1, 20, 1, yOff) }, Enum.EasingStyle.Back, Enum.EasingDirection.In)
        tw.Completed:Connect(function()
            pcall(function() holder:Destroy() end)
        end)
    end)
end

-- // MAIN WINDOW BUILDER \\ --
function ZypheraxUI:CreateWindow(config)
    local title   = config.Title or "Zypherax"
    local sub     = config.Description or "Enterprise Edition"
    local size    = config.Size or UDim2.fromOffset(640, 430)
    local keybind = config.Keybind or Enum.KeyCode.RightControl

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

    -- Drop shadow (Airflow style)
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
        BackgroundTransparency = 0,
        ClipsDescendants = true,
        ZIndex = 1,
        Parent = shadow
    })
    U.Corner(main, T.CornerLg)
    local mainStroke = U.Stroke(main, T.Stroke, 1.2, 0)

    -- Subtle top glow (Airflow)
    local topGlow = U.New("ImageLabel", {
        Image = "rbxassetid://6014261993",
        ImageColor3 = T.Accent,
        ImageTransparency = 0.88,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 120),
        Position = UDim2.new(0, 0, 0, -30),
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(49, 49, 450, 450),
        ZIndex = 0,
        Parent = main
    })

    -- // TOPBAR \\ --
    local topbar = U.New("Frame", {
        Size = UDim2.new(1, 0, 0, 46),
        BackgroundColor3 = T.Surface,
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        ZIndex = 3,
        Parent = main
    })
    U.Corner(topbar, T.CornerLg)

    -- Fix rounded corners only on top
    U.New("Frame", {
        Size = UDim2.new(1, 0, 0.5, 0),
        Position = UDim2.new(0, 0, 0.5, 0),
        BackgroundColor3 = T.Surface,
        BorderSizePixel = 0,
        ZIndex = 2,
        Parent = topbar
    })

    -- Topbar bottom divider (Lyapos style)
    U.New("Frame", {
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = T.Stroke,
        BorderSizePixel = 0,
        ZIndex = 4,
        Parent = topbar
    })

    -- Accent dot indicator (Lyapos style)
    local accentDot = U.New("Frame", {
        Size = UDim2.new(0, 6, 0, 6),
        Position = UDim2.new(0, 16, 0.5, -3),
        BackgroundColor3 = T.Accent,
        BorderSizePixel = 0,
        ZIndex = 5,
        Parent = topbar
    })
    U.Corner(accentDot, UDim.new(1, 0))

    -- Title
    local titleLbl = U.New("TextLabel", {
        Text = title,
        Font = T.Font,
        TextSize = 16,
        TextColor3 = T.Text,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 30, 0, 0),
        Size = UDim2.new(0, 0, 1, 0),
        AutomaticSize = Enum.AutomaticSize.X,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 5,
        Parent = topbar
    })

    -- Separator dot
    local sepDot = U.New("TextLabel", {
        Text = "·",
        Font = T.FontRegular,
        TextSize = 16,
        TextColor3 = T.TextDim,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 34, 0, 0),
        AutomaticSize = Enum.AutomaticSize.X,
        Size = UDim2.new(0, 0, 1, 0),
        ZIndex = 5,
        Parent = topbar
    })

    -- Subtitle
    local subLbl = U.New("TextLabel", {
        Text = sub,
        Font = T.FontRegular,
        TextSize = 13,
        TextColor3 = T.TextMuted,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 40, 0, 0),
        AutomaticSize = Enum.AutomaticSize.X,
        Size = UDim2.new(0, 0, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 5,
        Parent = topbar
    })

    -- Adjust subtitle position when title size renders
    trackConnection(titleLbl:GetPropertyChangedSignal("TextBounds"):Connect(function()
        sepDot.Position = UDim2.new(0, 34 + titleLbl.TextBounds.X + 2, 0, 0)
        subLbl.Position = UDim2.new(0, 42 + titleLbl.TextBounds.X + 12, 0, 0)
    end))

    -- Control buttons (Lyapos style: X and -)
    local function makeCtrlBtn(text, posX, hoverColor)
        local btn = U.New("TextButton", {
            Text = text,
            Font = T.Font,
            TextSize = 14,
            TextColor3 = T.TextMuted,
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 22, 0, 22),
            Position = UDim2.new(1, posX, 0.5, -11),
            AutoButtonColor = false,
            ZIndex = 6,
            Parent = topbar
        })
        trackConnection(btn.MouseEnter:Connect(function() U.Tween(btn, 0.15, { TextColor3 = hoverColor }) end))
        trackConnection(btn.MouseLeave:Connect(function() U.Tween(btn, 0.2, { TextColor3 = T.TextMuted }) end))
        return btn
    end

    local closeBtn = makeCtrlBtn("✕", -14, T.Error)
    local minBtn   = makeCtrlBtn("−", -40, T.Warning)

    -- Draggable (SpeedHubX style)
    local dragging, dragStart, startPos = false, nil, nil
    trackConnection(topbar.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = inp.Position
            startPos = shadow.Position
            local c
            c = inp.Changed:Connect(function()
                if inp.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    if c then c:Disconnect() end
                end
            end)
        end
    end))
    trackConnection(topbar.InputChanged:Connect(function(inp)
        if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
            local d = inp.Position - dragStart
            shadow.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end))

    -- Window Object to return
    local Win = { Tabs = {}, _currentTab = nil }

    -- Destroy Window & Cleanup all connections
    function Win:Destroy()
        for _, c in ipairs(connections) do
            if c and c.Connected then pcall(function() c:Disconnect() end) end
        end
        table.clear(connections)
        if gui then pcall(function() gui:Destroy() end) end
    end

    -- Close button
    trackConnection(closeBtn.MouseButton1Click:Connect(function()
        U.Ripple(closeBtn, Player:GetMouse().X, Player:GetMouse().Y)
        U.Tween(main, 0.25, { BackgroundTransparency = 1 })
        U.Tween(shadow, 0.25, { ImageTransparency = 1 })
        task.delay(0.28, function() Win:Destroy() end)
    end))

    -- Minimize button
    local isOpen = true
    trackConnection(minBtn.MouseButton1Click:Connect(function()
        U.Ripple(minBtn, Player:GetMouse().X, Player:GetMouse().Y)
        isOpen = not isOpen
        if isOpen then
            main.ClipsDescendants = false
            U.Tween(main, 0.35, { Size = size }, Enum.EasingStyle.Quint)
        else
            U.Tween(main, 0.35, { Size = UDim2.new(0, size.X.Offset, 0, 46) }, Enum.EasingStyle.Quint)
        end
    end))

    -- Keybind toggle visibility
    local registeredKeybinds = {}
    trackConnection(UIS.InputBegan:Connect(function(inp, gp)
        if gp then return end
        if inp.KeyCode == keybind then
            gui.Enabled = not gui.Enabled
        else
            for _, kb in ipairs(registeredKeybinds) do
                if inp.KeyCode == kb.key then
                    kb.callback(kb.key)
                end
            end
        end
    end))

    -- // SIDEBAR (Lyapos style) \\ --
    local SIDEBAR_W = 150
    local sidebar = U.New("Frame", {
        Size = UDim2.new(0, SIDEBAR_W, 1, -47),
        Position = UDim2.new(0, SIDEBAR_W == 150 and 0 or 0, 0, 47),
        BackgroundColor3 = T.SidebarBg,
        BorderSizePixel = 0,
        ZIndex = 2,
        Parent = main
    })

    -- Sidebar right border
    U.New("Frame", {
        Size = UDim2.new(0, 1, 1, 0),
        Position = UDim2.new(1, 0, 0, 0),
        BackgroundColor3 = T.Stroke,
        BorderSizePixel = 0,
        ZIndex = 3,
        Parent = sidebar
    })

    -- Tab list scroll
    local tabList = U.New("ScrollingFrame", {
        Size = UDim2.new(1, 0, 1, -16),
        Position = UDim2.new(0, 0, 0, 10),
        BackgroundTransparency = 1,
        ScrollBarThickness = 0,
        ClipsDescendants = true,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ZIndex = 3,
        Parent = sidebar
    })
    U.New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 3), Parent = tabList })
    U.New("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), Parent = tabList })

    -- Version label at sidebar bottom (Lyapos style)
    U.New("TextLabel", {
        Text = "v" .. ZypheraxUI.Version,
        Font = T.FontRegular,
        TextSize = 11,
        TextColor3 = T.TextDim,
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 10, 1, -8),
        Size = UDim2.new(1, -20, 0, 14),
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 3,
        Parent = sidebar
    })

    -- // CONTENT AREA \\ --
    local contentArea = U.New("Frame", {
        Size = UDim2.new(1, -(SIDEBAR_W + 1), 1, -47),
        Position = UDim2.new(0, SIDEBAR_W + 1, 0, 47),
        BackgroundTransparency = 1,
        ZIndex = 2,
        Parent = main
    })

    -- // CREATE TAB \\ --
    function Win:CreateTab(name, icon)
        -- Tab button in sidebar
        local tabBtn = U.New("TextButton", {
            Size = UDim2.new(1, 0, 0, 34),
            BackgroundColor3 = T.Surface2,
            BackgroundTransparency = 1,
            Text = "",
            AutoButtonColor = false,
            ZIndex = 4,
            Parent = tabList
        })
        U.Corner(tabBtn, T.CornerSm)
        local tabBtnStroke = U.Stroke(tabBtn, T.Stroke, 1, 1)

        -- Active indicator bar (Lyapos style)
        local activeBar = U.New("Frame", {
            Size = UDim2.new(0, 2, 0, 18),
            Position = UDim2.new(0, 0, 0.5, -9),
            BackgroundColor3 = T.Accent,
            BorderSizePixel = 0,
            BackgroundTransparency = 1,
            ZIndex = 5,
            Parent = tabBtn
        })
        U.Corner(activeBar, UDim.new(1, 0))

        -- Tab icon (optional)
        local iconOffset = 10
        if icon and icon ~= "" then
            U.New("ImageLabel", {
                Image = icon,
                Size = UDim2.new(0, 14, 0, 14),
                Position = UDim2.new(0, 10, 0.5, -7),
                BackgroundTransparency = 1,
                ImageColor3 = T.TextMuted,
                ZIndex = 5,
                Parent = tabBtn
            })
            iconOffset = 30
        end

        -- Tab name label
        local tabLbl = U.New("TextLabel", {
            Text = name,
            Font = T.Font,
            TextSize = 13,
            TextColor3 = T.TextMuted,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, iconOffset, 0, 0),
            Size = UDim2.new(1, -iconOffset - 6, 1, 0),
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 5,
            Parent = tabBtn
        })

        -- Content scroll frame for this tab (Native AutomaticCanvasSize for max speed)
        local tabContent = U.New("ScrollingFrame", {
            Size = UDim2.new(1, -20, 1, -16),
            Position = UDim2.new(0, 10, 0, 10),
            BackgroundTransparency = 1,
            ScrollBarThickness = 2,
            ScrollBarImageColor3 = T.Accent,
            ScrollBarImageTransparency = 0.5,
            Visible = false,
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            ZIndex = 3,
            Parent = contentArea
        })
        U.New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6), Parent = tabContent })
        U.New("UIPadding", { PaddingBottom = UDim.new(0, 12), Parent = tabContent })

        -- Activate tab
        local function activate()
            for _, t in ipairs(Win.Tabs) do
                t.content.Visible = false
                U.Tween(t.btn, 0.2, { BackgroundTransparency = 1 })
                U.Tween(t.stroke, 0.2, { Transparency = 1 })
                U.Tween(t.lbl, 0.2, { TextColor3 = T.TextMuted })
                U.Tween(t.bar, 0.2, { BackgroundTransparency = 1 })
            end
            tabContent.Visible = true
            U.Tween(tabBtn, 0.2, { BackgroundTransparency = 0 })
            U.Tween(tabBtnStroke, 0.2, { Transparency = 0.6, Color = T.Stroke })
            U.Tween(tabLbl, 0.2, { TextColor3 = T.Accent })
            U.Tween(activeBar, 0.2, { BackgroundTransparency = 0 })
            Win._currentTab = name
        end

        trackConnection(tabBtn.MouseButton1Click:Connect(function()
            U.Ripple(tabBtn, Player:GetMouse().X, Player:GetMouse().Y)
            activate()
        end))

        trackConnection(tabBtn.MouseEnter:Connect(function()
            if Win._currentTab ~= name then
                U.Tween(tabBtnStroke, 0.12, { Color = T.StrokeHover, Transparency = 0 })
                U.Tween(tabLbl, 0.15, { TextColor3 = T.Text })
            end
        end))
        trackConnection(tabBtn.MouseLeave:Connect(function()
            if Win._currentTab ~= name then
                U.Tween(tabBtnStroke, 0.2, { Color = T.Stroke, Transparency = 1 })
                U.Tween(tabLbl, 0.2, { TextColor3 = T.TextMuted })
            end
        end))

        -- Auto-select first tab
        if #Win.Tabs == 0 then activate() end

        local entry = { btn = tabBtn, stroke = tabBtnStroke, lbl = tabLbl, bar = activeBar, content = tabContent, name = name }
        table.insert(Win.Tabs, entry)

        -- // TAB COMPONENT API \\ --
        local Tab = {}

        -- Internal helper: build element base frame
        local function makeBase(height, isButton)
            local cls = isButton and "TextButton" or "Frame"
            local base = U.New(cls, {
                Size = UDim2.new(1, -2, 0, height),
                BackgroundColor3 = T.Surface2,
                BackgroundTransparency = 0,
                BorderSizePixel = 0,
                ZIndex = 4,
                Parent = tabContent
            })
            if isButton then
                base.Text = ""
                base.AutoButtonColor = false
            end
            U.Corner(base, T.CornerSm)
            local stroke = U.Stroke(base, T.Stroke, 1, 0)
            return base, stroke
        end

        -- SECTION (Lyapos style with gradient line)
        function Tab:CreateSection(name)
            local sec = U.New("Frame", {
                Size = UDim2.new(1, -2, 0, 28),
                BackgroundTransparency = 1,
                ZIndex = 4,
                Parent = tabContent
            })
            U.New("TextLabel", {
                Text = string.upper(name),
                Font = T.Font,
                TextSize = 11,
                TextColor3 = T.TextMuted,
                BackgroundTransparency = 1,
                Size = UDim2.new(0, 0, 0, 14),
                Position = UDim2.new(0, 2, 0.5, -7),
                AutomaticSize = Enum.AutomaticSize.X,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 5,
                Parent = sec
            })

            -- Gradient line (Lyapos)
            local line = U.New("Frame", {
                Size = UDim2.new(1, -10, 0, 1),
                Position = UDim2.new(0, 5, 1, -2),
                BackgroundColor3 = T.Stroke,
                BorderSizePixel = 0,
                ZIndex = 4,
                Parent = sec
            })
            U.New("UIGradient", {
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, T.Accent),
                    ColorSequenceKeypoint.new(0.4, T.Stroke),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(0,0,0))
                }),
                Transparency = NumberSequence.new(0, 1),
                Parent = line
            })
        end

        -- BUTTON (Airflow ripple + Lyapos styling)
        function Tab:CreateButton(cfg)
            local nm = cfg.Name or "Button"
            local cb = cfg.Callback or function() end
            local style = cfg.Style  -- "Primary" for accent fill

            local base, stroke = makeBase(36, true)
            if style == "Primary" then
                base.BackgroundColor3 = T.AccentDark
                base.BackgroundTransparency = 0.3
                stroke.Color = T.Accent
                stroke.Transparency = 0.4
                trackConnection(base.MouseEnter:Connect(function() U.Tween(base, 0.12, { BackgroundTransparency = 0.1 }) end))
                trackConnection(base.MouseLeave:Connect(function() U.Tween(base, 0.2, { BackgroundTransparency = 0.3 }) end))
            else
                local c1, c2 = U.HoverEffect(base, stroke)
                trackConnection(c1); trackConnection(c2)
            end

            U.New("TextLabel", {
                Text = nm,
                Font = T.Font,
                TextSize = 13,
                TextColor3 = style == "Primary" and T.Accent or T.Text,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -40, 1, 0),
                Position = UDim2.new(0, 14, 0, 0),
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 5,
                Parent = base
            })

            -- Chevron arrow
            U.New("TextLabel", {
                Text = "›",
                Font = T.Font,
                TextSize = 18,
                TextColor3 = T.TextMuted,
                BackgroundTransparency = 1,
                Size = UDim2.new(0, 20, 1, 0),
                Position = UDim2.new(1, -24, 0, 0),
                ZIndex = 5,
                Parent = base
            })

            trackConnection(base.MouseButton1Click:Connect(function()
                U.Ripple(base, Player:GetMouse().X, Player:GetMouse().Y)
                cb()
            end))
        end

        -- TOGGLE (Airflow smooth switch + Lyapos surface)
        function Tab:CreateToggle(cfg)
            local nm      = cfg.Name or "Toggle"
            local default = cfg.Default == true
            local cb      = cfg.Callback or function() end
            local toggled = default

            local base, stroke = makeBase(38)
            local h1, h2 = U.HoverEffect(base, stroke)
            trackConnection(h1); trackConnection(h2)

            U.New("TextLabel", {
                Text = nm,
                Font = T.FontRegular,
                TextSize = 13,
                TextColor3 = T.Text,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 14, 0, 0),
                Size = UDim2.new(1, -60, 1, 0),
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 5,
                Parent = base
            })

            -- Switch track
            local track = U.New("Frame", {
                Size = UDim2.new(0, 38, 0, 20),
                Position = UDim2.new(1, -50, 0.5, -10),
                BackgroundColor3 = toggled and T.Accent or T.Surface3,
                ZIndex = 5,
                Parent = base
            })
            U.Corner(track, UDim.new(1, 0))
            U.Stroke(track, T.Stroke, 1, toggled and 1 or 0)

            -- Glow behind track when ON
            local trackGlow = U.Glow(track, T.Accent, toggled and 0.7 or 1)

            -- Knob
            local knob = U.New("Frame", {
                Size = UDim2.new(0, 14, 0, 14),
                Position = UDim2.new(0, toggled and 22 or 2, 0.5, -7),
                BackgroundColor3 = T.Text,
                ZIndex = 6,
                Parent = track
            })
            U.Corner(knob, UDim.new(1, 0))

            local clickable = U.New("TextButton", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = "",
                ZIndex = 7,
                Parent = base
            })

            local function fire(silent)
                toggled = not toggled
                U.Tween(track, 0.25, { BackgroundColor3 = toggled and T.Accent or T.Surface3 }, Enum.EasingStyle.Quint)
                U.Tween(trackGlow, 0.25, { ImageTransparency = toggled and 0.72 or 1 })
                U.Tween(knob, 0.3, { Position = UDim2.new(0, toggled and 22 or 2, 0.5, -7) }, Enum.EasingStyle.Back)
                if not silent then cb(toggled) end
            end

            trackConnection(clickable.MouseButton1Click:Connect(function()
                U.Ripple(clickable, Player:GetMouse().X, Player:GetMouse().Y)
                fire()
            end))

            if default then cb(true) end

            return { Set = function(_, v) if v ~= toggled then fire(true) cb(toggled) end end, Get = function() return toggled end }
        end

        -- SLIDER (On-demand event connections during drag)
        function Tab:CreateSlider(cfg)
            local nm      = cfg.Name or "Slider"
            local mn      = cfg.Min or 0
            local mx      = cfg.Max or 100
            local default = math.clamp(cfg.Default or mn, mn, mx)
            local suffix  = cfg.Suffix or ""
            local cb      = cfg.Callback or function() end
            local value   = default

            local base, stroke = makeBase(54)
            local h1, h2 = U.HoverEffect(base, stroke)
            trackConnection(h1); trackConnection(h2)

            U.New("TextLabel", {
                Text = nm,
                Font = T.FontRegular,
                TextSize = 13,
                TextColor3 = T.Text,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 14, 0, 6),
                Size = UDim2.new(1, -90, 0, 18),
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 5,
                Parent = base
            })

            -- Value readout box (Airflow style)
            local readout = U.New("Frame", {
                Size = UDim2.new(0, 54, 0, 22),
                Position = UDim2.new(1, -64, 0, 6),
                BackgroundColor3 = T.Surface3,
                ZIndex = 5,
                Parent = base
            })
            U.Corner(readout, T.CornerSm)
            U.Stroke(readout, T.Stroke, 1, 0)

            local valLbl = U.New("TextLabel", {
                Text = tostring(default) .. suffix,
                Font = T.Font,
                TextSize = 12,
                TextColor3 = T.Accent,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 1, 0),
                ZIndex = 6,
                Parent = readout
            })

            -- Track
            local track = U.New("Frame", {
                Size = UDim2.new(1, -28, 0, 5),
                Position = UDim2.new(0, 14, 0, 38),
                BackgroundColor3 = T.Surface3,
                ZIndex = 5,
                Parent = base
            })
            U.Corner(track, UDim.new(1, 0))

            -- Fill
            local fillRatio = (default - mn) / math.max(mx - mn, 1)
            local fill = U.New("Frame", {
                Size = UDim2.new(fillRatio, 0, 1, 0),
                BackgroundColor3 = T.Accent,
                ZIndex = 6,
                Parent = track
            })
            U.Corner(fill, UDim.new(1, 0))

            -- Knob
            local knob = U.New("Frame", {
                Size = UDim2.new(0, 14, 0, 14),
                Position = UDim2.new(1, -7, 0.5, -7),
                BackgroundColor3 = T.Text,
                ZIndex = 7,
                Parent = fill
            })
            U.Corner(knob, UDim.new(1, 0))
            U.Glow(fill, T.Accent, 0.78)

            -- Invisible input area
            local hitbox = U.New("TextButton", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = "",
                ZIndex = 8,
                Parent = base
            })

            local dragging = false
            local dragConnection = nil

            local function updateSlider(mx_pos)
                local rel = math.clamp((mx_pos - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
                value = math.floor(mn + (mx - mn) * rel)
                valLbl.Text = tostring(value) .. suffix
                fill.Size = UDim2.new(rel, 0, 1, 0)
                cb(value)
            end

            trackConnection(hitbox.InputBegan:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    U.Tween(knob, 0.1, { Size = UDim2.new(0, 17, 0, 17), Position = UDim2.new(1, -8, 0.5, -8) })
                    updateSlider(UIS:GetMouseLocation().X)

                    if dragConnection then dragConnection:Disconnect() end
                    dragConnection = UIS.InputChanged:Connect(function(moveInp)
                        if dragging and (moveInp.UserInputType == Enum.UserInputType.MouseMovement or moveInp.UserInputType == Enum.UserInputType.Touch) then
                            updateSlider(UIS:GetMouseLocation().X)
                        end
                    end)
                end
            end))

            trackConnection(hitbox.InputEnded:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                    if dragConnection then
                        dragConnection:Disconnect()
                        dragConnection = nil
                    end
                    U.Tween(knob, 0.15, { Size = UDim2.new(0, 14, 0, 14), Position = UDim2.new(1, -7, 0.5, -7) })
                end
            end))

            return { Set = function(_, v) value = math.clamp(v, mn, mx) local r = (value-mn)/math.max(mx-mn,1) fill.Size = UDim2.new(r,0,1,0) valLbl.Text=tostring(value)..suffix end, Get = function() return value end }
        end

        -- DROPDOWN (Recycled / In-Place UI Update for maximum performance)
        function Tab:CreateDropdown(cfg)
            local nm    = cfg.Name or "Dropdown"
            local items = cfg.Items or {}
            local multi = cfg.Multi == true
            local cb    = cfg.Callback or function() end
            local selected = multi and {} or nil
            local open = false

            local base, stroke = makeBase(36)
            base.ClipsDescendants = true

            local clickable = U.New("TextButton", {
                Size = UDim2.new(1, 0, 0, 36),
                BackgroundTransparency = 1,
                Text = "",
                ZIndex = 5,
                Parent = base
            })

            local lbl = U.New("TextLabel", {
                Text = nm .. "  :  None",
                Font = T.FontRegular,
                TextSize = 13,
                TextColor3 = T.Text,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 14, 0, 0),
                Size = UDim2.new(1, -36, 0, 36),
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 5,
                Parent = base
            })

            -- Chevron icon
            local chevron = U.New("TextLabel", {
                Text = "›",
                Font = T.Font,
                TextSize = 18,
                TextColor3 = T.TextMuted,
                BackgroundTransparency = 1,
                Position = UDim2.new(1, -26, 0, 0),
                Size = UDim2.new(0, 20, 0, 36),
                Rotation = 90,
                ZIndex = 5,
                Parent = base
            })

            -- Items container
            local itemList = U.New("Frame", {
                Size = UDim2.new(1, -20, 0, 0),
                Position = UDim2.new(0, 10, 0, 40),
                BackgroundTransparency = 1,
                ZIndex = 5,
                Parent = base
            })
            U.New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 3), Parent = itemList })

            local function getDisplay()
                if multi then
                    return #selected > 0 and table.concat(selected, ", ") or "None"
                else
                    return selected or "None"
                end
            end

            local rowObjects = {}

            local function updateRowStates()
                for _, rData in ipairs(rowObjects) do
                    local item = rData.item
                    local isOn = multi and table.find(selected, item) or selected == item
                    rData.row.BackgroundTransparency = isOn and 0.3 or 0.7
                    rData.check.BackgroundTransparency = isOn and 0 or 1
                    rData.txt.TextColor3 = isOn and T.Accent or T.TextMuted
                end
            end

            local function buildItems()
                if #rowObjects > 0 then
                    updateRowStates()
                    return #items * 31
                end

                local totalH = 0
                for _, item in ipairs(items) do
                    local isOn = multi and table.find(selected, item) or selected == item
                    local row = U.New("TextButton", {
                        Size = UDim2.new(1, 0, 0, 28),
                        BackgroundColor3 = T.Surface3,
                        BackgroundTransparency = isOn and 0.3 or 0.7,
                        Text = "",
                        AutoButtonColor = false,
                        ZIndex = 6,
                        Parent = itemList
                    })
                    U.Corner(row, T.CornerSm)

                    local check = U.New("Frame", {
                        Size = UDim2.new(0, 4, 0, 14),
                        Position = UDim2.new(0, 4, 0.5, -7),
                        BackgroundColor3 = T.Accent,
                        BackgroundTransparency = isOn and 0 or 1,
                        ZIndex = 7,
                        Parent = row
                    })
                    U.Corner(check, UDim.new(1, 0))

                    local txt = U.New("TextLabel", {
                        Text = tostring(item),
                        Font = T.FontRegular,
                        TextSize = 12,
                        TextColor3 = isOn and T.Accent or T.TextMuted,
                        BackgroundTransparency = 1,
                        Position = UDim2.new(0, 14, 0, 0),
                        Size = UDim2.new(1, -20, 1, 0),
                        TextXAlignment = Enum.TextXAlignment.Left,
                        ZIndex = 7,
                        Parent = row
                    })

                    table.insert(rowObjects, { item = item, row = row, check = check, txt = txt })

                    trackConnection(row.MouseEnter:Connect(function() U.Tween(row, 0.15, { BackgroundTransparency = 0.4 }) end))
                    trackConnection(row.MouseLeave:Connect(function()
                        local curOn = multi and table.find(selected, item) or selected == item
                        U.Tween(row, 0.2, { BackgroundTransparency = curOn and 0.3 or 0.7 })
                    end))

                    trackConnection(row.MouseButton1Click:Connect(function()
                        if multi then
                            local idx = table.find(selected, item)
                            if idx then table.remove(selected, idx) else table.insert(selected, item) end
                        else
                            selected = item
                            open = false
                            U.Tween(base, 0.25, { Size = UDim2.new(1, -2, 0, 36) }, Enum.EasingStyle.Quint)
                            U.Tween(chevron, 0.2, { Rotation = 90 })
                        end
                        lbl.Text = nm .. "  :  " .. getDisplay()
                        cb(multi and selected or selected)
                        updateRowStates()
                    end))

                    totalH = totalH + 31
                end
                itemList.Size = UDim2.new(1, -20, 0, totalH)
                return totalH
            end

            trackConnection(clickable.MouseButton1Click:Connect(function()
                open = not open
                local totalH = buildItems()
                if open then
                    U.Tween(base, 0.3, { Size = UDim2.new(1, -2, 0, 44 + totalH) }, Enum.EasingStyle.Quint)
                    U.Tween(chevron, 0.25, { Rotation = 270 })
                else
                    U.Tween(base, 0.3, { Size = UDim2.new(1, -2, 0, 36) }, Enum.EasingStyle.Quint)
                    U.Tween(chevron, 0.25, { Rotation = 90 })
                end
            end))

            local h1, h2 = U.HoverEffect(base, stroke)
            trackConnection(h1); trackConnection(h2)
        end

        -- LABEL
        function Tab:CreateLabel(text)
            local lbl = U.New("TextLabel", {
                Text = text,
                Font = T.FontRegular,
                TextSize = 12,
                TextColor3 = T.TextMuted,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -2, 0, 18),
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 4,
                Parent = tabContent
            })
            U.New("UIPadding", { PaddingLeft = UDim.new(0, 4), Parent = lbl })
            local LblObj = {}
            function LblObj:CreateColorPicker(cfg)
                Tab:CreateColorPicker(cfg)
            end
            return LblObj
        end

        -- COLORPICKER
        function Tab:CreateColorPicker(cfg)
            local nm = cfg.Name or "Color"
            local default = cfg.Default or Color3.fromRGB(255, 255, 255)
            local cb = cfg.Callback or function() end

            local base, stroke = makeBase(38)
            local h1, h2 = U.HoverEffect(base, stroke)
            trackConnection(h1); trackConnection(h2)

            U.New("TextLabel", {
                Text = nm,
                Font = T.FontRegular,
                TextSize = 13,
                TextColor3 = T.Text,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 14, 0, 0),
                Size = UDim2.new(1, -70, 1, 0),
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 5,
                Parent = base
            })

            local swatch = U.New("Frame", {
                Size = UDim2.new(0, 38, 0, 22),
                Position = UDim2.new(1, -50, 0.5, -11),
                BackgroundColor3 = default,
                ZIndex = 5,
                Parent = base
            })
            U.Corner(swatch, T.CornerSm)
            U.Stroke(swatch, T.Stroke, 1, 0)

            U.New("TextLabel", {
                Text = "#" .. default:ToHex():upper(),
                Font = T.FontRegular,
                TextSize = 11,
                TextColor3 = T.TextMuted,
                BackgroundTransparency = 1,
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(0.5, 0, 0.5, 0),
                Size = UDim2.new(1, 0, 1, 0),
                ZIndex = 6,
                Parent = swatch
            })

            local btn = U.New("TextButton", { Size = UDim2.new(1,0,1,0), BackgroundTransparency=1, Text="", ZIndex=7, Parent=base })
            trackConnection(btn.MouseButton1Click:Connect(function()
                U.Ripple(btn, Player:GetMouse().X, Player:GetMouse().Y)
                cb(swatch.BackgroundColor3)
            end))
        end

        -- KEYBIND (On-Demand Listening)
        function Tab:CreateKeybind(cfg)
            local nm = cfg.Name or "Keybind"
            local default = cfg.Default or Enum.KeyCode.Delete
            local cb = cfg.Callback or function() end
            local current = default
            local binding = false

            local base, stroke = makeBase(38)
            local h1, h2 = U.HoverEffect(base, stroke)
            trackConnection(h1); trackConnection(h2)

            U.New("TextLabel", {
                Text = nm,
                Font = T.FontRegular,
                TextSize = 13,
                TextColor3 = T.Text,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 14, 0, 0),
                Size = UDim2.new(1, -100, 1, 0),
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 5,
                Parent = base
            })

            local badge = U.New("Frame", {
                Size = UDim2.new(0, 74, 0, 24),
                Position = UDim2.new(1, -84, 0.5, -12),
                BackgroundColor3 = T.Surface3,
                ZIndex = 5,
                Parent = base
            })
            U.Corner(badge, T.CornerSm)
            local badgeStroke = U.Stroke(badge, T.Stroke, 1, 0)

            local badgeLbl = U.New("TextLabel", {
                Text = current.Name,
                Font = T.Font,
                TextSize = 11,
                TextColor3 = T.Accent,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 1, 0),
                ZIndex = 6,
                Parent = badge
            })

            local btn = U.New("TextButton", { Size = UDim2.new(1,0,1,0), BackgroundTransparency=1, Text="", ZIndex=7, Parent=base })
            local bindConn = nil

            trackConnection(btn.MouseButton1Click:Connect(function()
                binding = true
                badgeLbl.Text = "..."
                U.Tween(badgeStroke, 0.15, { Color = T.Accent, Transparency = 0 })

                if bindConn then bindConn:Disconnect() end
                bindConn = UIS.InputBegan:Connect(function(inp, gp)
                    if gp then return end
                    if inp.UserInputType == Enum.UserInputType.Keyboard then
                        binding = false
                        current = inp.KeyCode
                        badgeLbl.Text = current.Name
                        U.Tween(badgeStroke, 0.2, { Color = T.Stroke, Transparency = 0 })
                        if bindConn then
                            bindConn:Disconnect()
                            bindConn = nil
                        end
                    end
                end)
            end))

            table.insert(registeredKeybinds, {
                key = current,
                callback = function(k) cb(k) end
            })
        end

        -- INPUT (Text Box)
        function Tab:CreateInput(cfg)
            local nm = cfg.Name or "Input"
            local ph = cfg.Placeholder or "Type here..."
            local default = cfg.Default or ""
            local cb = cfg.Callback or function() end

            local base, stroke = makeBase(38)
            local h1, h2 = U.HoverEffect(base, stroke)
            trackConnection(h1); trackConnection(h2)

            U.New("TextLabel", {
                Text = nm,
                Font = T.FontRegular,
                TextSize = 13,
                TextColor3 = T.Text,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 14, 0, 0),
                Size = UDim2.new(0.4, 0, 1, 0),
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 5,
                Parent = base
            })

            local inputBox = U.New("TextBox", {
                Text = default,
                PlaceholderText = ph,
                Font = T.FontRegular,
                TextSize = 12,
                TextColor3 = T.Text,
                PlaceholderColor3 = T.TextDim,
                BackgroundColor3 = T.Surface3,
                Position = UDim2.new(0.42, 0, 0.5, -11),
                Size = UDim2.new(0.55, 0, 0, 22),
                ClearTextOnFocus = false,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 5,
                Parent = base
            })
            U.Corner(inputBox, T.CornerSm)
            U.Stroke(inputBox, T.Stroke, 1, 0)
            U.New("UIPadding", { PaddingLeft = UDim.new(0, 8), Parent = inputBox })

            trackConnection(inputBox.Focused:Connect(function() U.Tween(inputBox, 0.15, { BackgroundColor3 = T.Surface }) end))
            trackConnection(inputBox.FocusLost:Connect(function(enter)
                U.Tween(inputBox, 0.15, { BackgroundColor3 = T.Surface3 })
                cb(inputBox.Text, enter)
            end))

            return { Set = function(_, v) inputBox.Text = tostring(v) end, Get = function() return inputBox.Text end }
        end

        return Tab
    end  -- end CreateTab

    -- Keybind hint label
    U.New("TextLabel", {
        Text = "Keybind: " .. keybind.Name .. "  |  Zypherax Enterprise v2",
        Font = T.FontRegular,
        TextSize = 11,
        TextColor3 = T.TextDim,
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.new(0.5, 0, 1, -1),
        Size = UDim2.new(1, -10, 0, 14),
        ZIndex = 3,
        Parent = main
    })

    return Win
end  -- end CreateWindow

return ZypheraxUI
