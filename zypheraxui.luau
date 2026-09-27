-- ============================================================================
-- ZYPHERAX UI LIBRARY  v4.0  (Enterprise Edition)
-- Layout  : Sidebar + Double-Column Sections
-- Bubble  : Floating circle (draggable, shows logo)
-- Shadow  : Removed ImageLabel shadow → UIStroke only
-- Corners : Strict UICorner on every frame, no orphan boxes
-- Resize  : Single ⌟ grip at bottom-right corner
-- ============================================================================

local ZypheraxUI  = {}
ZypheraxUI.Version = "Enterprise 4.0.0"
ZypheraxUI.Flags   = {}

-- ── SERVICES ────────────────────────────────────────────────────────────────
local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UIS          = game:GetService("UserInputService")
local RunService   = game:GetService("RunService")
local Player       = Players.LocalPlayer
local CoreGui
pcall(function()
    CoreGui = cloneref and cloneref(game:GetService("CoreGui")) or game:GetService("CoreGui")
end)
local VirtualUser = nil
pcall(function() VirtualUser = game:GetService("VirtualUser") end)

local function GetCore()
    if RunService:IsStudio() then return Player:WaitForChild("PlayerGui") end
    local ok, h = pcall(function() return gethui() end)
    if ok and h then return h end
    return CoreGui or Player:WaitForChild("PlayerGui")
end

-- ── THEME ────────────────────────────────────────────────────────────────────
local T = {
    -- Backgrounds (midnight blue depth)
    Bg          = Color3.fromRGB(11,  12,  20),   -- main window
    Bg2         = Color3.fromRGB( 8,   9,  15),   -- darkest
    Surface     = Color3.fromRGB(16,  18,  30),   -- card
    Surface2    = Color3.fromRGB(21,  24,  40),   -- elevated element bg
    Surface3    = Color3.fromRGB(28,  32,  52),   -- hover bg
    SidebarBg   = Color3.fromRGB( 9,  10,  17),   -- sidebar panel
    SecHeader   = Color3.fromRGB(17,  19,  32),   -- section header
    SecBg       = Color3.fromRGB(13,  15,  24),   -- section body

    -- Accent (electric cyan)
    Accent      = Color3.fromRGB(0,  200, 255),
    AccentDim   = Color3.fromRGB(0,   90, 160),
    AccentSoft  = Color3.fromRGB(60, 160, 255),

    -- Text
    Text        = Color3.fromRGB(228, 234, 248),
    TextMuted   = Color3.fromRGB(118, 130, 160),
    TextDim     = Color3.fromRGB(58,   64,  90),

    -- Stroke (border)
    Stroke      = Color3.fromRGB(26,  30,  50),
    StrokeHov   = Color3.fromRGB(55,  65, 100),

    -- Status
    Success     = Color3.fromRGB(72,  216, 130),
    Warning     = Color3.fromRGB(255, 185,  80),
    Error       = Color3.fromRGB(255,  80,  80),

    -- Corner radii
    Sm          = UDim.new(0,  6),
    Md          = UDim.new(0,  8),
    Lg          = UDim.new(0, 14),

    -- Fonts
    Bold        = Enum.Font.GothamBold,
    Reg         = Enum.Font.GothamMedium,
}
ZypheraxUI.Theme = T

-- ── UTILITY ──────────────────────────────────────────────────────────────────
local U = {}

function U.New(cls, p)
    local o = Instance.new(cls)
    local parent = p.Parent; p.Parent = nil
    for k, v in pairs(p) do o[k] = v end
    if parent then o.Parent = parent end
    return o
end

function U.Tw(obj, t, props, style, dir)
    local tw = TweenService:Create(obj,
        TweenInfo.new(t, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out),
        props)
    tw:Play(); return tw
end

function U.Corner(p, r)
    return U.New("UICorner", { CornerRadius = r or T.Md, Parent = p })
end

function U.Stroke(p, col, thick, trans)
    return U.New("UIStroke", {
        Color            = col   or T.Stroke,
        Thickness        = thick or 1,
        Transparency     = trans or 0,
        ApplyStrokeMode  = Enum.ApplyStrokeMode.Border,
        Parent           = p
    })
end

function U.Gradient(p, c0, c1, rot)
    return U.New("UIGradient", {
        Color    = ColorSequence.new(c0, c1),
        Rotation = rot or 90,
        Parent   = p
    })
end

function U.Ripple(btn, mx, my)
    task.spawn(function()
        if not btn or not btn.Parent then return end
        btn.ClipsDescendants = true
        local c = U.New("Frame", {
            Size                   = UDim2.new(0, 0, 0, 0),
            Position               = UDim2.new(0, mx - btn.AbsolutePosition.X,
                                               0, my - btn.AbsolutePosition.Y),
            BackgroundColor3       = T.Accent,
            BackgroundTransparency = 0.7,
            ZIndex                 = btn.ZIndex + 5,
            Parent                 = btn
        })
        U.Corner(c, UDim.new(1, 0))
        local sz = math.max(btn.AbsoluteSize.X, btn.AbsoluteSize.Y) * 2.2
        local tw = U.Tw(c, 0.45, {
            Size                   = UDim2.new(0, sz, 0, sz),
            Position               = UDim2.new(0.5, -sz/2, 0.5, -sz/2),
            BackgroundTransparency = 1,
        }, Enum.EasingStyle.Quad)
        tw.Completed:Connect(function() pcall(function() c:Destroy() end) end)
    end)
end

function U.Hover(base, stroke)
    local c1 = base.MouseEnter:Connect(function()
        U.Tw(base,   0.12, { BackgroundColor3 = T.Surface3 })
        if stroke then U.Tw(stroke, 0.12, { Color = T.StrokeHov }) end
    end)
    local c2 = base.MouseLeave:Connect(function()
        U.Tw(base,   0.22, { BackgroundColor3 = T.Surface2 })
        if stroke then U.Tw(stroke, 0.22, { Color = T.Stroke }) end
    end)
    return c1, c2
end

-- ── ANTI-AFK ─────────────────────────────────────────────────────────────────
local _afkDone = false
function ZypheraxUI:EnableAntiAFK()
    if _afkDone then return end; _afkDone = true
    task.spawn(function()
        if not Player or not VirtualUser then return end
        pcall(function()
            Player.Idled:Connect(function()
                pcall(function()
                    VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
                    task.wait(1)
                    VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
                end)
            end)
        end)
    end)
end
ZypheraxUI:EnableAntiAFK()

-- ── KEYBIND REGISTRY (for KeybindList) ───────────────────────────────────────
local registeredKeybinds = {}

-- ── NOTIFICATION ─────────────────────────────────────────────────────────────
local NotifGui, NotifCount = nil, 0

function ZypheraxUI:Notify(cfg)
    local title   = cfg.Title or cfg.Name or "Notice"
    local content = cfg.Content or cfg.Description or ""
    local dur     = cfg.Duration or 5
    local ntype   = cfg.Type or "Info"

    local colors  = { Info = T.Accent, Success = T.Success, Warning = T.Warning, Error = T.Error }
    local accent  = colors[ntype] or T.Accent

    if not NotifGui or not NotifGui.Parent then
        NotifGui = U.New("ScreenGui", {
            Name = "ZypheraxNotifs", ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
            DisplayOrder = 9999, ResetOnSpawn = false, Parent = GetCore()
        })
    end

    NotifCount = NotifCount + 1
    local yOff = -(76 + (NotifCount - 1) * 84)

    local card = U.New("Frame", {
        Size                   = UDim2.new(0, 316, 0, 72),
        Position               = UDim2.new(1, 20, 1, yOff),
        BackgroundColor3       = T.Surface,
        BackgroundTransparency = 0.08,
        ClipsDescendants       = true,
        Parent                 = NotifGui
    })
    U.Corner(card, T.Md)
    local st = U.Stroke(card, accent, 1, 0.5)

    -- Accent left bar
    U.New("Frame", {
        Size = UDim2.new(0, 3, 1, 0), BackgroundColor3 = accent,
        BorderSizePixel = 0, ZIndex = 2, Parent = card
    })

    U.New("TextLabel", {
        Text = title, Font = T.Bold, TextSize = 14, TextColor3 = T.Text,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 14, 0, 8), Size = UDim2.new(1, -20, 0, 18),
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 2, Parent = card
    })
    U.New("TextLabel", {
        Text = content, Font = T.Reg, TextSize = 11, TextColor3 = T.TextMuted,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 14, 0, 28), Size = UDim2.new(1, -24, 0, 30),
        TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true,
        TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 2, Parent = card
    })

    -- Timer bar
    local bar = U.New("Frame", {
        Size = UDim2.new(1, 0, 0, 2), Position = UDim2.new(0, 0, 1, -2),
        BackgroundColor3 = accent, BorderSizePixel = 0, ZIndex = 3, Parent = card
    })

    U.Tw(card, 0.4, { Position = UDim2.new(1, -330, 1, yOff) }, Enum.EasingStyle.Back)
    U.Tw(st,   0.5, { Transparency = 0 })
    U.Tw(bar,  dur, { Size = UDim2.new(0, 0, 0, 2) }, Enum.EasingStyle.Linear)

    task.delay(dur, function()
        NotifCount = math.max(0, NotifCount - 1)
        local tw = U.Tw(card, 0.3, { Position = UDim2.new(1, 20, 1, yOff) },
            Enum.EasingStyle.Back, Enum.EasingDirection.In)
        tw.Completed:Connect(function() pcall(function() card:Destroy() end) end)
    end)
end
ZypheraxUI.Notification = ZypheraxUI.Notify

-- ── WATERMARK ────────────────────────────────────────────────────────────────
local _wmGui, _wmLbl = nil, nil
function ZypheraxUI:Watermark(text)
    if not _wmGui or not _wmGui.Parent then
        _wmGui = U.New("ScreenGui", {
            Name = "ZypheraxWM", ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
            DisplayOrder = 9998, ResetOnSpawn = false, Parent = GetCore()
        })
        local hold = U.New("Frame", {
            Position = UDim2.new(0, 20, 0, 20), BackgroundColor3 = T.Bg2,
            BackgroundTransparency = 0.1, AutomaticSize = Enum.AutomaticSize.XY,
            Parent = _wmGui
        })
        U.Corner(hold, T.Sm)
        U.Stroke(hold, T.Accent, 1, 0.4)
        U.New("Frame", { Size = UDim2.new(0, 3, 1, 0), BackgroundColor3 = T.Accent,
            BorderSizePixel = 0, Parent = hold })
        _wmLbl = U.New("TextLabel", {
            Font = T.Bold, TextSize = 12, TextColor3 = T.Text,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 10, 0, 0), Size = UDim2.new(0, 0, 0, 24),
            AutomaticSize = Enum.AutomaticSize.X, TextXAlignment = Enum.TextXAlignment.Left,
            Parent = hold
        })
        U.New("UIPadding", { PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 10), Parent = _wmLbl })
    end
    _wmLbl.Text = type(text) == "table" and table.concat(text, "  |  ") or tostring(text)
end

-- ── KEYBIND LIST ─────────────────────────────────────────────────────────────
function ZypheraxUI:KeybindList(title)
    local gui = U.New("ScreenGui", {
        Name = "ZypheraxKBList", ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 9997, ResetOnSpawn = false, Parent = GetCore()
    })
    local frame = U.New("Frame", {
        Size = UDim2.new(0, 190, 0, 30), Position = UDim2.new(0, 20, 0.4, 0),
        BackgroundColor3 = T.Bg, BackgroundTransparency = 0.08, Visible = false,
        AutomaticSize = Enum.AutomaticSize.Y, Parent = gui
    })
    U.Corner(frame, T.Sm)
    U.Stroke(frame, T.Stroke, 1, 0)

    local hdr = U.New("Frame", {
        Size = UDim2.new(1, 0, 0, 28), BackgroundColor3 = T.Surface,
        BackgroundTransparency = 0.1, Parent = frame
    })
    U.Corner(hdr, T.Sm)
    U.New("TextLabel", {
        Text = title or "Keybinds", Font = T.Bold, TextSize = 11,
        TextColor3 = T.TextMuted, BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 0), Size = UDim2.new(1, -16, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Left, Parent = hdr
    })

    local list = U.New("Frame", {
        Size = UDim2.new(1, -16, 0, 0), Position = UDim2.new(0, 8, 0, 34),
        BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.Y,
        Parent = frame
    })
    U.New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4), Parent = list })
    U.New("UIPadding", { PaddingBottom = UDim.new(0, 8), Parent = list })

    -- Populate with registered keybinds after a frame
    task.spawn(function()
        task.wait()
        for _, kb in ipairs(registeredKeybinds) do
            local row = U.New("Frame", {
                Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, Parent = list
            })
            U.New("TextLabel", {
                Text = kb.name or "?", Font = T.Reg, TextSize = 10, TextColor3 = T.TextMuted,
                BackgroundTransparency = 1, Size = UDim2.new(0.6, 0, 1, 0),
                TextXAlignment = Enum.TextXAlignment.Left, Parent = row
            })
            U.New("TextLabel", {
                Text = kb.key and kb.key.Name or "—", Font = T.Bold, TextSize = 10,
                TextColor3 = T.Accent, BackgroundTransparency = 1,
                Size = UDim2.new(0.4, 0, 1, 0), Position = UDim2.new(0.6, 0, 0, 0),
                TextXAlignment = Enum.TextXAlignment.Right, Parent = row
            })
        end
    end)

    return frame
end

-- ── FLOATING BUBBLE ──────────────────────────────────────────────────────────
local _fbGui, _fbBtn, _fbTrack = nil, nil, nil

local function ensureBubble(onShow)
    if _fbTrack and _fbTrack.Parent then return _fbBtn end

    _fbGui = U.New("ScreenGui", {
        Name = "ZypheraxBubble", ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 9999, ResetOnSpawn = false, Parent = GetCore()
    })

    -- Main circle button
    _fbBtn = U.New("ImageButton", {
        Size = UDim2.new(0, 54, 0, 54), Position = UDim2.new(0.04, 0, 0.14, 0),
        BackgroundColor3 = T.Bg2, BackgroundTransparency = 0.06,
        Image = "", Visible = false, ZIndex = 10, ClipsDescendants = true,
        Parent = _fbGui
    })
    U.Corner(_fbBtn, UDim.new(1, 0))
    U.Stroke(_fbBtn, T.Accent, 1.5, 0)

    local bLogo = U.New("ImageLabel", {
        Name = "FloatingLogo", Size = UDim2.new(1, -14, 1, -14),
        Position = UDim2.new(0, 7, 0, 7), BackgroundTransparency = 1,
        Image = "", ScaleType = Enum.ScaleType.Fit, ZIndex = 11, Parent = _fbBtn
    })
    local bText = U.New("TextLabel", {
        Name = "FloatingText", Text = "Z", Font = T.Bold, TextSize = 26,
        TextColor3 = T.Accent, BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0), ZIndex = 10, Parent = _fbBtn
    })

    -- Drag logic
    local dragging, dStart, dPos = false, nil, nil
    _fbBtn.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true; dStart = inp.Position; dPos = _fbBtn.Position
            local c; c = inp.Changed:Connect(function()
                if inp.UserInputState == Enum.UserInputState.End then
                    dragging = false; if c then c:Disconnect() end
                end
            end)
        end
    end)
    _fbBtn.InputChanged:Connect(function(inp)
        if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
            local d = inp.Position - dStart
            _fbBtn.Position = UDim2.new(dPos.X.Scale, dPos.X.Offset + d.X,
                                         dPos.Y.Scale, dPos.Y.Offset + d.Y)
        end
    end)

    -- Click to restore (only if not dragged)
    local hasMoved, downP = false, Vector2.zero
    _fbBtn.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            downP = Vector2.new(inp.Position.X, inp.Position.Y); hasMoved = false
        end
    end)
    _fbBtn.InputChanged:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseMovement then
            if (Vector2.new(inp.Position.X, inp.Position.Y) - downP).Magnitude > 5 then hasMoved = true end
        end
    end)
    _fbBtn.MouseButton1Up:Connect(function()
        if not hasMoved then
            U.Ripple(_fbBtn, Player:GetMouse().X, Player:GetMouse().Y)
            onShow()
        end
    end)

    _fbTrack = _fbBtn
    return _fbBtn, bLogo, bText
end

-- ── MAIN WINDOW BUILDER ───────────────────────────────────────────────────────
function ZypheraxUI:CreateWindow(cfg)
    cfg = cfg or {}
    local title   = cfg.Title or cfg.Name or "Zypherax UI"
    local sub     = cfg.Description or cfg.SubName or "Enterprise Edition"
    local size    = cfg.Size or UDim2.fromOffset(660, 480)
    local keybind = cfg.Keybind or Enum.KeyCode.RightControl
    local logo    = cfg.Logo

    local core        = GetCore()
    local connections = {}
    local function track(c) table.insert(connections, c) end

    -- Root ScreenGui
    local gui = U.New("ScreenGui", {
        Name = "ZypheraxUI_Main", ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 100, ResetOnSpawn = false, Parent = core
    })

    -- ── Main window frame (NO ImageLabel shadow — UIStroke only) ─────────────
    local main = U.New("Frame", {
        Size = size, Position = UDim2.new(0.5, 0, 0.5, 0), AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = T.Bg, BackgroundTransparency = 0.04,
        ClipsDescendants = false, ZIndex = 1, Parent = gui
    })
    U.Corner(main, T.Lg)
    -- Premium outer glow stroke (replaces shadow)
    U.Stroke(main, T.Stroke, 1.5, 0)

    -- Subtle top-edge accent line (1px, not a box)
    local topGlow = U.New("Frame", {
        Size = UDim2.new(1, -28, 0, 1), Position = UDim2.new(0, 14, 0, 0),
        BackgroundColor3 = T.Accent, BackgroundTransparency = 0.4,
        BorderSizePixel = 0, ZIndex = 3, Parent = main
    })
    U.Corner(topGlow, UDim.new(1, 0))

    -- Inner clip frame (prevents rounded corners clipping content to a box)
    local inner = U.New("Frame", {
        Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
        ClipsDescendants = true, ZIndex = 1, Parent = main
    })
    U.Corner(inner, T.Lg)

    -- ── DRAG (via header) ─────────────────────────────────────────────────────
    local function makeDraggable(handle)
        local drag, dStart, dPos = false, nil, nil
        track(handle.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                drag = true; dStart = inp.Position; dPos = main.Position
                local c; c = inp.Changed:Connect(function()
                    if inp.UserInputState == Enum.UserInputState.End then
                        drag = false; if c then c:Disconnect() end
                    end
                end)
            end
        end))
        track(UIS.InputChanged:Connect(function(inp)
            if drag and inp.UserInputType == Enum.UserInputType.MouseMovement then
                local d = inp.Position - dStart
                main.Position = UDim2.new(dPos.X.Scale, dPos.X.Offset + d.X,
                                          dPos.Y.Scale, dPos.Y.Offset + d.Y)
            end
        end))
    end

    -- ── LAYOUT: Sidebar (left 140px) + Content (rest) ────────────────────────
    local sidebar = U.New("Frame", {
        Size = UDim2.new(0, 140, 1, 0), BackgroundColor3 = T.SidebarBg,
        BorderSizePixel = 0, ZIndex = 2, Parent = inner
    })
    -- Right edge separator
    U.New("Frame", {
        Size = UDim2.new(0, 1, 1, 0), Position = UDim2.new(1, 0, 0, 0),
        BackgroundColor3 = T.Stroke, BorderSizePixel = 0, ZIndex = 3, Parent = sidebar
    })

    -- ── Sidebar Header ─────────────────────────────────────────────────────
    local sideHdr = U.New("Frame", {
        Size = UDim2.new(1, 0, 0, 72), BackgroundColor3 = T.Bg2,
        BorderSizePixel = 0, ZIndex = 3, Parent = sidebar
    })
    U.New("Frame", { -- bottom divider
        Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -1),
        BackgroundColor3 = T.Stroke, BorderSizePixel = 0, ZIndex = 4, Parent = sideHdr
    })
    makeDraggable(sideHdr)

    -- Logo box (transparent, image or "Z" fallback)
    local logoBox = U.New("Frame", {
        Size = UDim2.new(0, 40, 0, 40), Position = UDim2.new(0, 12, 0.5, -20),
        BackgroundTransparency = 1, ZIndex = 4, Parent = sideHdr
    })
    U.Corner(logoBox, T.Sm)

    local logoImg = U.New("ImageLabel", {
        Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
        Image = logo or "", ScaleType = Enum.ScaleType.Fit, ZIndex = 5, Parent = logoBox
    })
    local logoFallback = U.New("TextLabel", {
        Text = "Z", Font = T.Bold, TextSize = 26, TextColor3 = T.Accent,
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), ZIndex = 5,
        Parent = logoBox, Visible = (not logo or logo == "")
    })
    logoImg.Visible = (logo and logo ~= "")

    -- Title & subtitle
    U.New("TextLabel", {
        Text = string.upper(title), Font = T.Bold, TextSize = 13, TextColor3 = T.Accent,
        BackgroundTransparency = 1, Position = UDim2.new(0, 58, 0, 14),
        Size = UDim2.new(1, -62, 0, 18), TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 4, Parent = sideHdr, TextTruncate = Enum.TextTruncate.AtEnd
    })
    U.New("TextLabel", {
        Text = sub, Font = T.Reg, TextSize = 10, TextColor3 = T.TextMuted,
        BackgroundTransparency = 1, Position = UDim2.new(0, 58, 0, 34),
        Size = UDim2.new(1, -62, 0, 14), TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 4, Parent = sideHdr, TextTruncate = Enum.TextTruncate.AtEnd
    })

    -- ── Control buttons [−] [✕]  (minimize left, close right) ────────────────
    local ctrlRow = U.New("Frame", {
        Size = UDim2.new(1, -8, 0, 22), Position = UDim2.new(0, 4, 1, -30),
        BackgroundTransparency = 1, ZIndex = 5, Parent = sideHdr
    })
    U.New("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 4), Parent = ctrlRow
    })

    local function makeCtrl(sym, col)
        local wrap = U.New("Frame", {
            Size = UDim2.new(0, 24, 0, 24), BackgroundColor3 = T.Surface2,
            BackgroundTransparency = 0.4, ZIndex = 6, Parent = ctrlRow
        })
        U.Corner(wrap, T.Sm)
        local ws = U.Stroke(wrap, T.Stroke, 1, 0.4)
        local lbl = U.New("TextLabel", {
            Text = sym, Font = T.Bold, TextSize = 14, TextColor3 = T.TextDim,
            BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), ZIndex = 7, Parent = wrap
        })
        local btn = U.New("TextButton", {
            Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
            Text = "", AutoButtonColor = false, ZIndex = 8, Parent = wrap
        })
        track(btn.MouseEnter:Connect(function()
            U.Tw(wrap, 0.12, { BackgroundColor3 = col, BackgroundTransparency = 0.1 })
            U.Tw(ws,   0.12, { Color = col, Transparency = 0 })
            U.Tw(lbl,  0.12, { TextColor3 = T.Text })
        end))
        track(btn.MouseLeave:Connect(function()
            U.Tw(wrap, 0.2, { BackgroundColor3 = T.Surface2, BackgroundTransparency = 0.4 })
            U.Tw(ws,   0.2, { Color = T.Stroke, Transparency = 0.4 })
            U.Tw(lbl,  0.2, { TextColor3 = T.TextDim })
        end))
        return btn
    end

    local minBtn   = makeCtrl("−", T.Warning)
    local closeBtn = makeCtrl("✕", T.Error)

    -- ── Tab list (below header in sidebar) ────────────────────────────────────
    local tabScroll = U.New("ScrollingFrame", {
        Size = UDim2.new(1, 0, 1, -72), Position = UDim2.new(0, 0, 0, 72),
        BackgroundTransparency = 1, ScrollBarThickness = 2,
        ScrollBarImageColor3 = T.Accent, ScrollBarImageTransparency = 0.5,
        AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(0,0,0,0),
        ZIndex = 3, Parent = sidebar
    })
    U.New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2), Parent = tabScroll })
    U.New("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingLeft = UDim.new(0, 6),
        PaddingRight = UDim.new(0, 6), PaddingBottom = UDim.new(0, 8), Parent = tabScroll })

    -- ── Sidebar Footer (Profile) ───────────────────────────────────────────
    local avatar = Player and Player.UserId and
        ("https://www.roblox.com/headshot-thumbnail/image?userId="..Player.UserId.."&width=48&height=48&format=png")
        or ""
    local footerH = 56
    local footer = U.New("Frame", {
        Size = UDim2.new(1, 0, 0, footerH), Position = UDim2.new(0, 0, 1, -footerH),
        BackgroundColor3 = T.Bg2, BorderSizePixel = 0, ZIndex = 3, Parent = sidebar
    })
    U.New("Frame", { -- top border
        Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = T.Stroke,
        BorderSizePixel = 0, ZIndex = 4, Parent = footer
    })
    local pfpImg = U.New("ImageLabel", {
        Image = avatar, Size = UDim2.new(0, 32, 0, 32),
        Position = UDim2.new(0, 10, 0.5, -16), BackgroundColor3 = T.Surface2,
        BackgroundTransparency = 0, ZIndex = 4, Parent = footer
    })
    U.Corner(pfpImg, UDim.new(1, 0))
    U.New("TextLabel", {
        Text = Player and Player.Name or "Player", Font = T.Bold, TextSize = 11,
        TextColor3 = T.Text, BackgroundTransparency = 1,
        Position = UDim2.new(0, 50, 0.5, -12), Size = UDim2.new(1, -56, 0, 14),
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 4, Parent = footer
    })
    U.New("TextLabel", {
        Text = "Free User", Font = T.Reg, TextSize = 9,
        TextColor3 = T.TextMuted, BackgroundTransparency = 1,
        Position = UDim2.new(0, 50, 0.5, 2), Size = UDim2.new(1, -56, 0, 12),
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 4, Parent = footer
    })

    -- ── Content Area ─────────────────────────────────────────────────────────
    local contentArea = U.New("Frame", {
        Size = UDim2.new(1, -140, 1, 0), Position = UDim2.new(0, 140, 0, 0),
        BackgroundColor3 = T.Bg, BackgroundTransparency = 0.02,
        ClipsDescendants = true, ZIndex = 2, Parent = inner
    })

    -- ── Resize Handle — single ⌟ at bottom-right of main ────────────────────
    local resizeH = U.New("Frame", {
        Size = UDim2.new(0, 22, 0, 22), Position = UDim2.new(1, -22, 1, -22),
        BackgroundTransparency = 1, ZIndex = 20, Parent = main
    })
    local chevronLbl = U.New("TextLabel", {
        Text = "⌟", Font = T.Bold, TextSize = 18, TextColor3 = T.TextDim,
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), ZIndex = 21, Parent = resizeH
    })
    local resizeBtn = U.New("TextButton", {
        Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "",
        AutoButtonColor = false, ZIndex = 22, Parent = resizeH
    })
    local MIN_W, MIN_H = 440, 340
    local rDrag, rStart, rOrig = false, nil, nil
    track(resizeBtn.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            rDrag = true; rStart = Vector2.new(inp.Position.X, inp.Position.Y)
            rOrig  = Vector2.new(main.AbsoluteSize.X, main.AbsoluteSize.Y)
            local c; c = inp.Changed:Connect(function()
                if inp.UserInputState == Enum.UserInputState.End then
                    rDrag = false; if c then c:Disconnect() end
                end
            end)
        end
    end))
    track(UIS.InputChanged:Connect(function(inp)
        if rDrag and inp.UserInputType == Enum.UserInputType.MouseMovement then
            local d  = Vector2.new(inp.Position.X, inp.Position.Y) - rStart
            local nw = math.max(MIN_W, rOrig.X + d.X)
            local nh = math.max(MIN_H, rOrig.Y + d.Y)
            main.Size = UDim2.fromOffset(nw, nh)
        end
    end))
    track(resizeBtn.MouseEnter:Connect(function()  U.Tw(chevronLbl, 0.12, { TextColor3 = T.Accent }) end))
    track(resizeBtn.MouseLeave:Connect(function()  U.Tw(chevronLbl, 0.20, { TextColor3 = T.TextDim }) end))

    -- ── Window Object ─────────────────────────────────────────────────────────
    local Win = { Tabs = {}, _current = nil }

    -- ── Toggle Visibility ──────────────────────────────────────────────────
    function Win:ToggleVisibility(v)
        if v == nil then v = not gui.Enabled end
        gui.Enabled = v
        if _fbBtn then _fbBtn.Visible = not v end
        if v then
            main.BackgroundTransparency = 1
            U.Tw(main, 0.22, { BackgroundTransparency = 0.04 })
        end
    end

    -- Close & Minimize
    track(closeBtn.MouseButton1Click:Connect(function()
        gui.Enabled = false
        for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
        gui:Destroy()
    end))
    track(minBtn.MouseButton1Click:Connect(function()
        Win:ToggleVisibility(false)
    end))

    -- Keybind toggle
    track(UIS.InputBegan:Connect(function(inp, gp)
        if gp then return end
        if inp.KeyCode == keybind then Win:ToggleVisibility() end
    end))

    -- Bubble setup
    local fb, fbLogo, fbText = ensureBubble(function() Win:ToggleVisibility(true) end)
    if fb then
        if logo and logo ~= "" then
            if fbLogo then fbLogo.Image = logo; fbLogo.Visible = true end
            if fbText then fbText.Visible = false end
        else
            if fbLogo then fbLogo.Visible = false end
            if fbText then fbText.Visible = true end
        end
    end

    -- ── CreateTab ───────────────────────────────────────────────────────────
    function Win:CreateTab(nameOrCfg, icon)
        local tabName = type(nameOrCfg) == "table" and (nameOrCfg.Name or nameOrCfg.Title) or nameOrCfg
        local tabIcon = type(nameOrCfg) == "table" and (nameOrCfg.Icon or nameOrCfg.Logo) or icon

        -- Tab button in sidebar
        local tabBtn = U.New("Frame", {
            Size = UDim2.new(1, 0, 0, 38), BackgroundColor3 = T.Surface,
            BackgroundTransparency = 1, ZIndex = 4, Parent = tabScroll
        })
        U.Corner(tabBtn, T.Md)

        -- Left accent pill
        local pill = U.New("Frame", {
            Size = UDim2.new(0, 3, 0, 20), Position = UDim2.new(0, 0, 0.5, -10),
            BackgroundColor3 = T.Accent, BackgroundTransparency = 1,
            ZIndex = 5, Parent = tabBtn
        })
        U.Corner(pill, UDim.new(1, 0))

        -- Icon
        local iconEl, iconXOff = nil, 12
        if tabIcon and tabIcon ~= "" then
            iconEl = U.New("ImageLabel", {
                Image = tabIcon:find("rbxassetid") and tabIcon or ("rbxassetid://"..tabIcon),
                Size = UDim2.new(0, 16, 0, 16), Position = UDim2.new(0, 12, 0.5, -8),
                BackgroundTransparency = 1, ImageColor3 = T.TextMuted, ZIndex = 5, Parent = tabBtn
            })
            iconXOff = 34
        else
            iconEl = U.New("Frame", {
                Size = UDim2.new(0, 5, 0, 5), Position = UDim2.new(0, 14, 0.5, -2.5),
                BackgroundColor3 = T.TextDim, ZIndex = 5, Parent = tabBtn
            })
            U.Corner(iconEl, UDim.new(1, 0))
            iconXOff = 28
        end

        local tabLbl = U.New("TextLabel", {
            Text = tabName, Font = T.Reg, TextSize = 12, TextColor3 = T.TextMuted,
            BackgroundTransparency = 1, Position = UDim2.new(0, iconXOff, 0, 0),
            Size = UDim2.new(1, -iconXOff - 8, 1, 0), TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 5, Parent = tabBtn, TextTruncate = Enum.TextTruncate.AtEnd
        })

        local tabStroke = U.Stroke(tabBtn, T.Stroke, 1, 1)

        local clickable = U.New("TextButton", {
            Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "",
            AutoButtonColor = false, ZIndex = 6, Parent = tabBtn
        })

        -- Page frame (double column)
        local page = U.New("Frame", {
            Size = UDim2.new(1, -16, 1, -16), Position = UDim2.new(0, 8, 0, 8),
            BackgroundTransparency = 1, Visible = false, ZIndex = 3, Parent = contentArea
        })

        local function makeCol(posX, wScale)
            local col = U.New("ScrollingFrame", {
                Size = UDim2.new(wScale, -4, 1, 0), Position = UDim2.new(posX, posX > 0 and 4 or 0, 0, 0),
                BackgroundTransparency = 1, ScrollBarThickness = 2,
                ScrollBarImageColor3 = T.Accent, ScrollBarImageTransparency = 0.5,
                AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(0,0,0,0),
                ZIndex = 3, Parent = page
            })
            U.New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8), Parent = col })
            U.New("UIPadding", { PaddingBottom = UDim.new(0, 12), Parent = col })
            return col
        end

        local leftCol  = makeCol(0,   0.5)
        local rightCol = makeCol(0.5, 0.5)

        -- Activate tab
        local function activate()
            for _, tab in ipairs(Win.Tabs) do
                tab.page.Visible = false
                U.Tw(tab.btn,  0.18, { BackgroundTransparency = 1 })
                U.Tw(tab.pill, 0.18, { BackgroundTransparency = 1 })
                U.Tw(tab.lbl,  0.18, { TextColor3 = T.TextMuted, Font = T.Reg })
                if tab.iconEl then
                    if tab.iconEl:IsA("ImageLabel") then
                        U.Tw(tab.iconEl, 0.18, { ImageColor3 = T.TextMuted })
                    else
                        U.Tw(tab.iconEl, 0.18, { BackgroundColor3 = T.TextDim })
                    end
                end
            end
            page.Visible = true
            U.Tw(tabBtn,    0.2, { BackgroundColor3 = T.AccentDim, BackgroundTransparency = 0.75 })
            U.Tw(tabStroke, 0.2, { Transparency = 0.6, Color = T.AccentDim })
            U.Tw(pill,      0.2, { BackgroundTransparency = 0 })
            U.Tw(tabLbl,    0.2, { TextColor3 = T.Accent, Font = T.Bold })
            if iconEl then
                if iconEl:IsA("ImageLabel") then
                    U.Tw(iconEl, 0.2, { ImageColor3 = T.Accent })
                else
                    U.Tw(iconEl, 0.2, { BackgroundColor3 = T.Accent })
                end
            end
            Win._current = tabName
        end

        track(clickable.MouseButton1Click:Connect(function()
            U.Ripple(tabBtn, Player:GetMouse().X, Player:GetMouse().Y)
            activate()
        end))
        track(clickable.MouseEnter:Connect(function()
            if Win._current ~= tabName then
                U.Tw(tabBtn, 0.12, { BackgroundColor3 = T.Surface2, BackgroundTransparency = 0.6 })
                U.Tw(tabLbl, 0.12, { TextColor3 = T.Text })
            end
        end))
        track(clickable.MouseLeave:Connect(function()
            if Win._current ~= tabName then
                U.Tw(tabBtn, 0.2, { BackgroundTransparency = 1 })
                U.Tw(tabLbl, 0.2, { TextColor3 = T.TextMuted })
            end
        end))

        if #Win.Tabs == 0 then activate() end

        table.insert(Win.Tabs, { btn = tabBtn, pill = pill, lbl = tabLbl,
            iconEl = iconEl, stroke = tabStroke, page = page, name = tabName })

        -- ── Tab API ─────────────────────────────────────────────────────────
        local Tab = {}

        function Tab:CreateSection(secCfg)
            local secName   = type(secCfg) == "table" and (secCfg.Name or secCfg.Title) or tostring(secCfg)
            local side      = type(secCfg) == "table" and (secCfg.Side or 1) or 1
            local targetCol = side == 2 and rightCol or leftCol

            local secBox = U.New("Frame", {
                Size = UDim2.new(1, 0, 0, 0), BackgroundColor3 = T.SecBg,
                AutomaticSize = Enum.AutomaticSize.Y, ZIndex = 4, Parent = targetCol
            })
            U.Corner(secBox, T.Md)
            U.Stroke(secBox, T.Stroke, 1, 0)

            -- Section header
            local secHdr = U.New("Frame", {
                Size = UDim2.new(1, 0, 0, 28), BackgroundColor3 = T.SecHeader,
                ZIndex = 5, Parent = secBox
            })
            U.Corner(secHdr, T.Md)
            -- Fill bottom half to square off the rounded header bottom
            U.New("Frame", {
                Size = UDim2.new(1, 0, 0.5, 0), Position = UDim2.new(0, 0, 0.5, 0),
                BackgroundColor3 = T.SecHeader, BorderSizePixel = 0, ZIndex = 4, Parent = secHdr
            })
            -- Accent top line (1px, then fades via gradient)
            local accentLine = U.New("Frame", {
                Size = UDim2.new(0.6, 0, 0, 1), Position = UDim2.new(0, 0, 0, 0),
                BackgroundColor3 = T.Accent, BorderSizePixel = 0, ZIndex = 6, Parent = secHdr
            })
            U.Gradient(accentLine, T.Accent, Color3.fromRGB(0,0,0), 0)
            U.New("TextLabel", {
                Text = string.upper(secName), Font = T.Bold, TextSize = 10,
                TextColor3 = T.TextMuted, BackgroundTransparency = 1,
                Position = UDim2.new(0, 10, 0, 0), Size = UDim2.new(1, -16, 1, 0),
                TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6, Parent = secHdr
            })

            -- Elements container
            local secCtr = U.New("Frame", {
                Size = UDim2.new(1, -12, 0, 0), Position = UDim2.new(0, 6, 0, 32),
                BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.Y,
                ZIndex = 5, Parent = secBox
            })
            U.New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4), Parent = secCtr })
            U.New("UIPadding", { PaddingBottom = UDim.new(0, 8), Parent = secCtr })

            local Sec = {}

            -- makeBase helper
            local function mkBase(h, isBtn)
                local cls = isBtn and "TextButton" or "Frame"
                local b   = U.New(cls, {
                    Size = UDim2.new(1, 0, 0, h), BackgroundColor3 = T.Surface2,
                    BorderSizePixel = 0, ZIndex = 5, Parent = secCtr
                })
                if isBtn then b.Text = ""; b.AutoButtonColor = false end
                U.Corner(b, T.Sm)
                local s = U.Stroke(b, T.Stroke, 1, 0)
                return b, s
            end

            -- ── TOGGLE ────────────────────────────────────────────────────────
            function Sec:CreateToggle(c)
                local nm  = c.Name or "Toggle"
                local flag = c.Flag
                local def  = c.Default == true
                local cb   = c.Callback or function() end
                local tog  = def
                if flag then ZypheraxUI.Flags[flag] = tog end

                local b, s = mkBase(36)
                local h1, h2 = U.Hover(b, s); track(h1); track(h2)

                U.New("TextLabel", {
                    Text = nm, Font = T.Reg, TextSize = 12, TextColor3 = T.Text,
                    BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0, 0),
                    Size = UDim2.new(1, -56, 1, 0), TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 6, Parent = b
                })

                local track_ = U.New("Frame", {
                    Size = UDim2.new(0, 32, 0, 17), Position = UDim2.new(1, -40, 0.5, -8.5),
                    BackgroundColor3 = tog and T.Accent or T.Surface3, ZIndex = 6, Parent = b
                })
                U.Corner(track_, UDim.new(1, 0))
                local knob = U.New("Frame", {
                    Size = UDim2.new(0, 11, 0, 11),
                    Position = UDim2.new(0, tog and 18 or 3, 0.5, -5.5),
                    BackgroundColor3 = T.Text, ZIndex = 7, Parent = track_
                })
                U.Corner(knob, UDim.new(1, 0))

                local clk = U.New("TextButton", {
                    Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1,
                    Text = "", ZIndex = 8, Parent = b
                })
                local function fire(silent)
                    tog = not tog
                    if flag then ZypheraxUI.Flags[flag] = tog end
                    U.Tw(track_, 0.2, { BackgroundColor3 = tog and T.Accent or T.Surface3 })
                    U.Tw(knob,   0.25, { Position = UDim2.new(0, tog and 18 or 3, 0.5, -5.5) }, Enum.EasingStyle.Back)
                    if not silent then cb(tog) end
                end
                track(clk.MouseButton1Click:Connect(function()
                    U.Ripple(b, Player:GetMouse().X, Player:GetMouse().Y); fire()
                end))
                if def then task.spawn(function() task.wait() cb(true) end) end
                return { Set = function(_, v) if v ~= tog then fire(true) end end,
                         Get = function() return tog end }
            end
            Sec.Toggle = Sec.CreateToggle

            -- ── SLIDER ────────────────────────────────────────────────────────
            function Sec:CreateSlider(c)
                local nm  = c.Name or "Slider"
                local flag = c.Flag
                local mn  = c.Min or 0; local mx = c.Max or 100
                local def = math.clamp(c.Default or mn, mn, mx)
                local suf = c.Suffix or ""
                local cb  = c.Callback or function() end
                local val = def
                if flag then ZypheraxUI.Flags[flag] = val end

                local b, s = mkBase(48)
                local h1, h2 = U.Hover(b, s); track(h1); track(h2)

                U.New("TextLabel", {
                    Text = nm, Font = T.Reg, TextSize = 12, TextColor3 = T.Text,
                    BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0, 5),
                    Size = UDim2.new(1, -70, 0, 17), TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 6, Parent = b
                })
                local vLbl = U.New("TextLabel", {
                    Text = tostring(def)..suf, Font = T.Bold, TextSize = 11,
                    TextColor3 = T.Accent, BackgroundTransparency = 1,
                    Position = UDim2.new(1, -58, 0, 5), Size = UDim2.new(0, 50, 0, 17),
                    TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 6, Parent = b
                })

                local trk = U.New("Frame", {
                    Size = UDim2.new(1, -20, 0, 4), Position = UDim2.new(0, 10, 0, 33),
                    BackgroundColor3 = T.Surface3, ZIndex = 6, Parent = b
                })
                U.Corner(trk, UDim.new(1, 0))
                local fill = U.New("Frame", {
                    Size = UDim2.new((def-mn)/math.max(mx-mn,1), 0, 1, 0),
                    BackgroundColor3 = T.Accent, ZIndex = 7, Parent = trk
                })
                U.Corner(fill, UDim.new(1, 0))
                local knob = U.New("Frame", {
                    Size = UDim2.new(0, 12, 0, 12), Position = UDim2.new(1, -6, 0.5, -6),
                    BackgroundColor3 = T.Text, ZIndex = 8, Parent = fill
                })
                U.Corner(knob, UDim.new(1, 0))

                local hbx = U.New("TextButton", {
                    Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1,
                    Text = "", ZIndex = 9, Parent = b
                })
                local dragging, dragConn = false, nil
                local function update(mx_pos)
                    local rel = math.clamp((mx_pos - trk.AbsolutePosition.X) / trk.AbsoluteSize.X, 0, 1)
                    val = math.floor(mn + (mx - mn) * rel)
                    if flag then ZypheraxUI.Flags[flag] = val end
                    vLbl.Text = tostring(val)..suf
                    fill.Size = UDim2.new(rel, 0, 1, 0)
                    cb(val)
                end
                track(hbx.InputBegan:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = true; update(UIS:GetMouseLocation().X)
                        if dragConn then dragConn:Disconnect() end
                        dragConn = UIS.InputChanged:Connect(function(m)
                            if dragging and m.UserInputType == Enum.UserInputType.MouseMovement then
                                update(UIS:GetMouseLocation().X)
                            end
                        end)
                    end
                end))
                track(hbx.InputEnded:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = false
                        if dragConn then dragConn:Disconnect(); dragConn = nil end
                    end
                end))
                return { Set = function(_, v)
                    val = math.clamp(v, mn, mx)
                    fill.Size = UDim2.new((val-mn)/math.max(mx-mn,1), 0, 1, 0)
                    vLbl.Text = tostring(val)..suf
                end, Get = function() return val end }
            end
            Sec.Slider = Sec.CreateSlider

            -- ── DROPDOWN ──────────────────────────────────────────────────────
            function Sec:CreateDropdown(c)
                local nm    = c.Name or "Dropdown"
                local flag  = c.Flag
                local items = c.Items or {}
                local multi = c.Multi == true
                local cb    = c.Callback or function() end
                local sel   = multi and (type(c.Default) == "table" and c.Default or {}) or (c.Default)
                local open  = false
                if flag then ZypheraxUI.Flags[flag] = sel end

                local b, s = mkBase(34)
                b.ClipsDescendants = true

                local clk = U.New("TextButton", {
                    Size = UDim2.new(1,0,0,34), BackgroundTransparency = 1,
                    Text = "", ZIndex = 7, Parent = b
                })
                local lbl = U.New("TextLabel", {
                    Text = nm.." : "..(multi and (#sel > 0 and table.concat(sel,", ") or "None") or (sel or "None")),
                    Font = T.Reg, TextSize = 12, TextColor3 = T.Text, BackgroundTransparency = 1,
                    Position = UDim2.new(0, 10, 0, 0), Size = UDim2.new(1, -32, 0, 34),
                    TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6, Parent = b,
                    TextTruncate = Enum.TextTruncate.AtEnd
                })
                local chev = U.New("TextLabel", {
                    Text = "›", Font = T.Bold, TextSize = 16, TextColor3 = T.TextMuted,
                    BackgroundTransparency = 1, Position = UDim2.new(1, -24, 0, 0),
                    Size = UDim2.new(0, 18, 0, 34), Rotation = 90, ZIndex = 6, Parent = b
                })

                local iList = U.New("Frame", {
                    Size = UDim2.new(1, -14, 0, 0), Position = UDim2.new(0, 7, 0, 37),
                    BackgroundTransparency = 1, ZIndex = 6, Parent = b
                })
                U.New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 3), Parent = iList })

                local rows = {}
                local function updateRows()
                    for _, r in ipairs(rows) do
                        local on = multi and table.find(sel, r.item) or sel == r.item
                        r.row.BackgroundTransparency = on and 0.3 or 0.7
                        r.txt.TextColor3 = on and T.Accent or T.TextMuted
                    end
                end
                local function buildItems()
                    if #rows > 0 then updateRows(); return #items * 30 end
                    local tot = 0
                    for _, item in ipairs(items) do
                        local on = multi and table.find(sel, item) or sel == item
                        local row = U.New("TextButton", {
                            Size = UDim2.new(1, 0, 0, 27), BackgroundColor3 = T.Surface3,
                            BackgroundTransparency = on and 0.3 or 0.7, Text = "",
                            AutoButtonColor = false, ZIndex = 7, Parent = iList
                        })
                        U.Corner(row, T.Sm)
                        local txt = U.New("TextLabel", {
                            Text = tostring(item), Font = T.Reg, TextSize = 11,
                            TextColor3 = on and T.Accent or T.TextMuted, BackgroundTransparency = 1,
                            Position = UDim2.new(0, 10, 0, 0), Size = UDim2.new(1, -16, 1, 0),
                            TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 8, Parent = row
                        })
                        table.insert(rows, { item = item, row = row, txt = txt })
                        track(row.MouseButton1Click:Connect(function()
                            if multi then
                                local idx = table.find(sel, item)
                                if idx then table.remove(sel, idx) else table.insert(sel, item) end
                            else
                                sel = item; open = false
                                U.Tw(b, 0.25, { Size = UDim2.new(1, 0, 0, 34) })
                                U.Tw(chev, 0.2, { Rotation = 90 })
                            end
                            if flag then ZypheraxUI.Flags[flag] = sel end
                            lbl.Text = nm.." : "..(multi and (#sel > 0 and table.concat(sel,", ") or "None") or (sel or "None"))
                            cb(sel); updateRows()
                        end))
                        tot = tot + 30
                    end
                    iList.Size = UDim2.new(1, -14, 0, tot); return tot
                end
                track(clk.MouseButton1Click:Connect(function()
                    open = not open
                    local tot = buildItems()
                    if open then
                        U.Tw(b, 0.28, { Size = UDim2.new(1, 0, 0, 42 + tot) }, Enum.EasingStyle.Quint)
                        U.Tw(chev, 0.22, { Rotation = 270 })
                    else
                        U.Tw(b, 0.28, { Size = UDim2.new(1, 0, 0, 34) }, Enum.EasingStyle.Quint)
                        U.Tw(chev, 0.22, { Rotation = 90 })
                    end
                end))
                local h1, h2 = U.Hover(b, s); track(h1); track(h2)
            end
            Sec.Dropdown = Sec.CreateDropdown

            -- ── COLOR PICKER ──────────────────────────────────────────────────
            function Sec:CreateColorPicker(c)
                local nm  = c.Name or "Color"
                local flag = c.Flag
                local def = c.Default or Color3.fromRGB(0, 200, 255)
                local cb  = c.Callback or function() end

                local h, s, v = Color3.toHSV(def)
                local cur = def
                if flag then ZypheraxUI.Flags[flag] = cur end

                local b, bs = mkBase(34)
                local h1, h2 = U.Hover(b, bs); track(h1); track(h2)

                U.New("TextLabel", {
                    Text = nm, Font = T.Reg, TextSize = 12, TextColor3 = T.Text,
                    BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0, 0),
                    Size = UDim2.new(1, -60, 1, 0), TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 6, Parent = b
                })
                local swatch = U.New("Frame", {
                    Size = UDim2.new(0, 28, 0, 16), Position = UDim2.new(1, -38, 0.5, -8),
                    BackgroundColor3 = cur, ZIndex = 6, Parent = b
                })
                U.Corner(swatch, T.Sm)
                U.Stroke(swatch, T.Stroke, 1, 0)

                local panelOpen = false
                local panel = nil

                local function buildPanel()
                    panel = U.New("Frame", {
                        Size = UDim2.new(1, -12, 0, 118), Position = UDim2.new(0, 6, 0, 38),
                        BackgroundColor3 = T.Bg2, BackgroundTransparency = 0.1,
                        ZIndex = 7, Parent = b
                    })
                    U.Corner(panel, T.Sm)
                    U.Stroke(panel, T.Stroke, 1, 0)

                    -- SV field
                    local svF = U.New("Frame", {
                        Size = UDim2.new(1, -24, 0, 88), Position = UDim2.new(0, 6, 0, 6),
                        BackgroundColor3 = Color3.fromHSV(h, 1, 1), ZIndex = 8, Parent = panel
                    })
                    U.Corner(svF, T.Sm)
                    -- White gradient (left→white)
                    U.Gradient(svF, Color3.fromRGB(255,255,255), Color3.fromRGB(255,255,255), 0)
                    -- Black gradient (bottom→black)
                    local svGrad2 = U.New("Frame", {
                        Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
                        ZIndex = 9, Parent = svF
                    })
                    U.Corner(svGrad2, T.Sm)
                    U.Gradient(svGrad2, Color3.fromRGB(0,0,0), Color3.fromRGB(0,0,0), 90)

                    local svCur = U.New("Frame", {
                        Size = UDim2.new(0, 8, 0, 8),
                        Position = UDim2.new(s, -4, 1-v, -4),
                        BackgroundColor3 = T.Text, ZIndex = 10, Parent = svF
                    })
                    U.Corner(svCur, UDim.new(1, 0))
                    U.Stroke(svCur, T.Bg, 1.5, 0)

                    local svBtn = U.New("TextButton", {
                        Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, Text = "",
                        ZIndex = 11, Parent = svF
                    })

                    -- Hue bar (right side)
                    local hueBar = U.New("Frame", {
                        Size = UDim2.new(0, 12, 0, 88), Position = UDim2.new(1, -18, 0, 6),
                        ZIndex = 8, Parent = panel
                    })
                    U.Corner(hueBar, T.Sm)
                    U.Gradient(hueBar, ColorSequence.new({
                        ColorSequenceKeypoint.new(0,   Color3.fromHSV(0,   1, 1)),
                        ColorSequenceKeypoint.new(0.17, Color3.fromHSV(0.17,1, 1)),
                        ColorSequenceKeypoint.new(0.33, Color3.fromHSV(0.33,1, 1)),
                        ColorSequenceKeypoint.new(0.5,  Color3.fromHSV(0.5, 1, 1)),
                        ColorSequenceKeypoint.new(0.67, Color3.fromHSV(0.67,1, 1)),
                        ColorSequenceKeypoint.new(0.83, Color3.fromHSV(0.83,1, 1)),
                        ColorSequenceKeypoint.new(1,    Color3.fromHSV(1,   1, 1)),
                    }))
                    local hueCur = U.New("Frame", {
                        Size = UDim2.new(1, 4, 0, 3), Position = UDim2.new(0, -2, h, -1.5),
                        BackgroundColor3 = T.Text, ZIndex = 9, Parent = hueBar
                    })
                    U.Corner(hueCur, UDim.new(1, 0))
                    local hueBtn = U.New("TextButton", {
                        Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, Text = "",
                        ZIndex = 10, Parent = hueBar
                    })

                    -- Hex input
                    local function toHex(col)
                        return string.format("#%02X%02X%02X",
                            math.round(col.R*255), math.round(col.G*255), math.round(col.B*255))
                    end
                    local hexBox = U.New("TextBox", {
                        Size = UDim2.new(0, 76, 0, 20), Position = UDim2.new(0, 6, 0, 98),
                        BackgroundColor3 = T.Surface3, Text = toHex(cur),
                        Font = T.Bold, TextSize = 11, TextColor3 = T.Accent,
                        PlaceholderText = "#RRGGBB", ClearTextOnFocus = false,
                        TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 8, Parent = panel
                    })
                    U.Corner(hexBox, T.Sm)
                    U.Stroke(hexBox, T.Stroke, 1, 0)

                    local function apply()
                        cur = Color3.fromHSV(h, s, v)
                        swatch.BackgroundColor3 = cur
                        svF.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
                        svCur.Position = UDim2.new(s, -4, 1-v, -4)
                        hueCur.Position = UDim2.new(0, -2, h, -1.5)
                        hexBox.Text = toHex(cur)
                        if flag then ZypheraxUI.Flags[flag] = cur end
                        cb(cur)
                    end

                    -- SV drag
                    local svDrag, svConn = false, nil
                    svBtn.InputBegan:Connect(function(inp)
                        if inp.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
                        svDrag = true
                        if svConn then svConn:Disconnect() end
                        svConn = UIS.InputChanged:Connect(function(m)
                            if not svDrag or m.UserInputType ~= Enum.UserInputType.MouseMovement then return end
                            local rel = svF.AbsolutePosition; local sz = svF.AbsoluteSize
                            s = math.clamp((m.Position.X - rel.X) / sz.X, 0, 1)
                            v = 1 - math.clamp((m.Position.Y - rel.Y) / sz.Y, 0, 1)
                            apply()
                        end)
                    end)
                    UIS.InputEnded:Connect(function(inp)
                        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                            svDrag = false; if svConn then svConn:Disconnect(); svConn = nil end
                        end
                    end)

                    -- Hue drag
                    local hueDrag, hueConn = false, nil
                    hueBtn.InputBegan:Connect(function(inp)
                        if inp.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
                        hueDrag = true
                        if hueConn then hueConn:Disconnect() end
                        hueConn = UIS.InputChanged:Connect(function(m)
                            if not hueDrag or m.UserInputType ~= Enum.UserInputType.MouseMovement then return end
                            local rel = hueBar.AbsolutePosition; local sz = hueBar.AbsoluteSize
                            h = math.clamp((m.Position.Y - rel.Y) / sz.Y, 0, 1)
                            apply()
                        end)
                    end)
                    UIS.InputEnded:Connect(function(inp)
                        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                            hueDrag = false; if hueConn then hueConn:Disconnect(); hueConn = nil end
                        end
                    end)

                    hexBox.FocusLost:Connect(function()
                        local raw = hexBox.Text:gsub("#", "")
                        if #raw == 6 then
                            local r = tonumber(raw:sub(1,2), 16)
                            local g = tonumber(raw:sub(3,4), 16)
                            local bl = tonumber(raw:sub(5,6), 16)
                            if r and g and bl then
                                h, s, v = Color3.toHSV(Color3.fromRGB(r, g, bl)); apply()
                            end
                        end
                    end)
                end

                -- Toggle panel
                local tog = U.New("TextButton", {
                    Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1,
                    Text = "", ZIndex = 8, Parent = b
                })
                track(tog.MouseButton1Click:Connect(function()
                    panelOpen = not panelOpen
                    if panelOpen then
                        if not panel or not panel.Parent then buildPanel() end
                        U.Tw(b, 0.2, { Size = UDim2.new(1, 0, 0, 164) })
                    else
                        U.Tw(b, 0.2, { Size = UDim2.new(1, 0, 0, 34) })
                        if panel then pcall(function() panel:Destroy() end); panel = nil end
                    end
                end))
            end
            Sec.Colorpicker = Sec.CreateColorPicker

            -- ── KEYBIND ───────────────────────────────────────────────────────
            function Sec:CreateKeybind(c)
                local nm  = c.Name or "Keybind"
                local flag = c.Flag
                local def = c.Default or Enum.KeyCode.Delete
                local cb  = c.Callback or function() end
                local cur = def; local binding = false
                if flag then ZypheraxUI.Flags[flag] = cur end

                local b, s = mkBase(34)
                local h1, h2 = U.Hover(b, s); track(h1); track(h2)

                U.New("TextLabel", {
                    Text = nm, Font = T.Reg, TextSize = 12, TextColor3 = T.Text,
                    BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0, 0),
                    Size = UDim2.new(1, -88, 1, 0), TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 6, Parent = b
                })

                local badge = U.New("Frame", {
                    Size = UDim2.new(0, 68, 0, 20), Position = UDim2.new(1, -76, 0.5, -10),
                    BackgroundColor3 = T.Surface3, ZIndex = 6, Parent = b
                })
                U.Corner(badge, T.Sm)
                local bStroke = U.Stroke(badge, T.Stroke, 1, 0)
                local bLbl = U.New("TextLabel", {
                    Text = cur.Name, Font = T.Bold, TextSize = 10, TextColor3 = T.Accent,
                    BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), ZIndex = 7, Parent = badge
                })

                local kbEntry = { name = nm, key = cur, callback = cb }
                table.insert(registeredKeybinds, kbEntry)

                local btn = U.New("TextButton", {
                    Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, Text = "",
                    ZIndex = 8, Parent = b
                })
                local bindConn = nil
                track(btn.MouseButton1Click:Connect(function()
                    binding = true; bLbl.Text = "..."
                    U.Tw(bStroke, 0.15, { Color = T.Accent })
                    if bindConn then bindConn:Disconnect() end
                    bindConn = UIS.InputBegan:Connect(function(inp, gp)
                        if gp then return end
                        if inp.UserInputType == Enum.UserInputType.Keyboard then
                            binding = false; cur = inp.KeyCode; kbEntry.key = cur
                            if flag then ZypheraxUI.Flags[flag] = cur end
                            bLbl.Text = cur.Name
                            U.Tw(bStroke, 0.2, { Color = T.Stroke })
                            if bindConn then bindConn:Disconnect(); bindConn = nil end
                            cb(cur)
                        end
                    end)
                end))
            end
            Sec.Keybind = Sec.CreateKeybind

            -- ── INPUT ─────────────────────────────────────────────────────────
            function Sec:CreateInput(c)
                local nm  = c.Name or "Input"
                local flag = c.Flag
                local ph  = c.Placeholder or "Type..."
                local def = c.Default or ""
                local cb  = c.Callback or function() end
                if flag then ZypheraxUI.Flags[flag] = def end

                local b, s = mkBase(34)
                local h1, h2 = U.Hover(b, s); track(h1); track(h2)

                U.New("TextLabel", {
                    Text = nm, Font = T.Reg, TextSize = 12, TextColor3 = T.Text,
                    BackgroundTransparency = 1, Position = UDim2.new(0, 10, 0, 0),
                    Size = UDim2.new(0.4, 0, 1, 0), TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 6, Parent = b
                })
                local iBox = U.New("TextBox", {
                    Text = def, PlaceholderText = ph, Font = T.Reg, TextSize = 11,
                    TextColor3 = T.Text, PlaceholderColor3 = T.TextDim,
                    BackgroundColor3 = T.Surface3, ClearTextOnFocus = false,
                    Position = UDim2.new(0.42, 0, 0.5, -11), Size = UDim2.new(0.55, 0, 0, 22),
                    TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6, Parent = b
                })
                U.Corner(iBox, T.Sm)
                U.Stroke(iBox, T.Stroke, 1, 0)
                U.New("UIPadding", { PaddingLeft = UDim.new(0, 6), Parent = iBox })
                track(iBox.FocusLost:Connect(function(enter)
                    if flag then ZypheraxUI.Flags[flag] = iBox.Text end
                    cb(iBox.Text, enter)
                end))
                return { Set = function(_, val) iBox.Text = tostring(val) end, Get = function() return iBox.Text end }
            end
            Sec.Input = Sec.CreateInput

            -- ── BUTTON ────────────────────────────────────────────────────────
            function Sec:CreateButton(c)
                local nm   = c.Name or "Button"
                local cb   = c.Callback or function() end
                local style = c.Style

                local b, s = mkBase(32, true)
                if style == "Primary" then
                    b.BackgroundColor3 = T.AccentDim
                    b.BackgroundTransparency = 0.3
                    s.Color = T.Accent; s.Transparency = 0.3
                else
                    local h1, h2 = U.Hover(b, s); track(h1); track(h2)
                end

                U.New("TextLabel", {
                    Text = nm, Font = T.Bold, TextSize = 12,
                    TextColor3 = style == "Primary" and T.Accent or T.Text,
                    BackgroundTransparency = 1, Size = UDim2.new(1, -20, 1, 0),
                    Position = UDim2.new(0, 10, 0, 0), TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 6, Parent = b
                })
                track(b.MouseButton1Click:Connect(function()
                    U.Ripple(b, Player:GetMouse().X, Player:GetMouse().Y); cb()
                end))
            end
            Sec.Button = Sec.CreateButton

            -- ── LABEL ─────────────────────────────────────────────────────────
            function Sec:CreateLabel(text)
                U.New("TextLabel", {
                    Text = tostring(text), Font = T.Reg, TextSize = 11,
                    TextColor3 = T.TextMuted, BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 18), TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 5, Parent = secCtr
                })
            end
            Sec.Label = Sec.CreateLabel

            return Sec
        end
        Tab.Section = Tab.CreateSection

        return Tab
    end
    Win.Page = Win.CreateTab
    Win.Category = Win.CreateTab

    function Win:ChangeTheme(key, val)
        if T[key] ~= nil then T[key] = val end
    end

    function Win:Init() return Win end

    return Win
end

return ZypheraxUI
