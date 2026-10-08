--════════════════════════════════════════════════════════════════════════════
-- NOTCH UI • FULL FIXED BUILD
-- Panel notch 100% primitive antialiased (UICorner + UIStroke).
-- Slice hanya untuk potongan sumbu-sejajar → nol gerigi, nol seam UIScale.
-- Install: LocalScript (StarterPlayerScripts / StarterGui).
-- Kontrol: drag kartu = geser widget • RightShift = show/hide (tween).
--════════════════════════════════════════════════════════════════════════════

local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UIS          = game:GetService("UserInputService")
local GuiService   = game:GetService("GuiService")

GuiService.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

--────────────────────────────────────────────────────────────────────────────
-- THEME
--────────────────────────────────────────────────────────────────────────────
local Theme = {
	Surface      = Color3.fromRGB(32, 34, 39),
	SurfaceDeep  = Color3.fromRGB(24, 25, 29),
	Accent1      = Color3.fromRGB(88, 101, 242),   -- blurple
	Accent2      = Color3.fromRGB(64, 205, 255),   -- cyan
	Text         = Color3.fromRGB(255, 255, 255),
	Sub          = Color3.fromRGB(148, 155, 166),
	Blurple      = Color3.fromRGB(88, 101, 242),
	Green        = Color3.fromRGB(87, 242, 135),
}

--────────────────────────────────────────────────────────────────────────────
-- CONSTANTS
--────────────────────────────────────────────────────────────────────────────
local STROKE   = 2
local ROW      = 2
local WIDTH    = 420
local CARD_H   = 240
local R_CARD   = 28      -- radius sudut kartu
local NOTCH_R  = 56      -- radius hole transparan notch
local BAR_H    = 64
local GAP      = 14
local OVERHANG = 12      -- ruang di atas kartu (badge overlap)
local outerH   = OVERHANG + CARD_H + GAP + BAR_H

-- Notch geometry: RC = arc outline, RF = kolom cut fill, RB = outer lip.
-- Deviasi kolom fill (RF..RF+2) jatuh DI DALAM band lip (RC..RC+LIP) → tertelan.
local S   = STROKE
local RC  = NOTCH_R + S          -- 58
local RF  = RC + S               -- 60
local LIP = 5
local RB  = RC + LIP             -- 63

--────────────────────────────────────────────────────────────────────────────
-- HELPERS
--────────────────────────────────────────────────────────────────────────────
local function New(class, props)
	local inst = Instance.new(class)
	local parent = props.Parent
	props.Parent = nil
	for k, v in pairs(props) do
		inst[k] = v
	end
	inst.Parent = parent
	return inst
end

local function Round(inst, radius)
	return New("UICorner", { CornerRadius = UDim.new(0, radius), Parent = inst })
end

local function Stroke(inst, color, thickness)
	return New("UIStroke", {
		Color = color,
		Thickness = thickness,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = inst,
	})
end

local function Grad(parent, keypoints, rotation)
	return New("UIGradient", {
		Color = ColorSequence.new(keypoints),
		Rotation = rotation or 90,
		Parent = parent,
	})
end

local function gradAt(t)
	return Theme.Accent1:Lerp(Theme.Accent2, math.clamp(t, 0, 1))
end

-- Warna gradient vertikal widget pada koordinat panel-lokal py.
local function gY(py)
	return gradAt((OVERHANG + py + S) / outerH)
end

local function Label(props)
	props.BackgroundTransparency = 1
	props.Font = props.Font or Enum.Font.Gotham
	props.TextColor3 = props.TextColor3 or Theme.Text
	return New("TextLabel", props)
end

--────────────────────────────────────────────────────────────────────────────
-- GUI ROOT
--────────────────────────────────────────────────────────────────────────────
local gui = New("ScreenGui", {
	Name = "NotchUI",
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent = Players.LocalPlayer:WaitForChild("PlayerGui"),
})

local uiScale = New("UiScale", { Scale = 0.94, Parent = gui })

local root = New("Frame", {
	Name = "Root",
	BackgroundTransparency = 1,
	Size = UDim2.fromScale(1, 1),
	Parent = gui,
})

local widget = New("Frame", {
	Name = "Widget",
	BackgroundTransparency = 1,
	Size = UDim2.fromOffset(WIDTH, outerH),
	Position = UDim2.new(0.5, -WIDTH / 2, 0.5, -outerH / 2),
	Parent = root,
})

--────────────────────────────────────────────────────────────────────────────
-- PANEL • SILHOUETTE SUMBU-SEJAJAR (zero aliasing by construction)
--────────────────────────────────────────────────────────────────────────────
local panel = New("Frame", {
	Name = "Panel",
	Position = UDim2.fromOffset(0, OVERHANG),
	Size = UDim2.fromOffset(WIDTH, CARD_H),
	BackgroundTransparency = 1,
	Parent = widget,
})
local cx = WIDTH / 2

local function buildSilhouette(isOutline)
	local cut = isOutline and RC or RF
	local y0  = isOutline and -S or 0
	for y = y0, CARD_H - 1, ROW do
		local inCorner = (y < R_CARD) or (y >= CARD_H - R_CARD)
		local l = inCorner and R_CARD or (isOutline and -S or 0)
		local r = inCorner and (WIDTH - R_CARD) or (isOutline and (WIDTH + S) or WIDTH)

		local spans = {}
		if y < RB then
			if l < cx - cut then table.insert(spans, { l, cx - cut }) end
			if cx + cut < r then table.insert(spans, { cx + cut, r }) end
		else
			table.insert(spans, { l, r })
		end

		local color
		if isOutline then
			color = gY(y)
		else
			color = Theme.Surface:Lerp(
				Theme.SurfaceDeep,
				math.clamp((y - RB) / (CARD_H - RB), 0, 1)
			)
		end

		for _, sp in ipairs(spans) do
			New("Frame", {
				BackgroundColor3 = color,
				Position = UDim2.fromOffset(sp[1], y),
				Size = UDim2.fromOffset(sp[2] - sp[1], ROW),
				ZIndex = isOutline and 1 or 2,
				Parent = panel,
			})
		end
	end
end
buildSilhouette(true)   -- rim gradient (z1)
buildSilhouette(false)  -- fill surface (z2)

--────────────────────────────────────────────────────────────────────────────
-- PANEL • CORNER PATCHES (quarter-disc fill + quarter-ring stroke, AA)
-- Clip dilebarkan +S agar band stroke tidak terpotong (fix nick sambungan).
-- UIGradient WAJIB di-parent ke UIStroke, bukan ke Frame.
--────────────────────────────────────────────────────────────────────────────
for _, c in ipairs({
	{ left = true,  top = true,  cx = R_CARD,         cy = R_CARD },
	{ left = false, top = true,  cx = WIDTH - R_CARD, cy = R_CARD },
	{ left = true,  top = false, cx = R_CARD,         cy = CARD_H - R_CARD },
	{ left = false, top = false, cx = WIDTH - R_CARD, cy = CARD_H - R_CARD },
}) do
	local orad = R_CARD + S

	-- ring rim (gradient pada stroke)
	local clipX = c.left and (c.cx - orad - 1) or c.cx
	local clipY = c.top  and (c.cy - orad - 1) or c.cy
	local outClip = New("Frame", {
		Position = UDim2.fromOffset(clipX, clipY),
		Size = UDim2.fromOffset(orad + 1, orad + 1),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		ZIndex = 1,
		Parent = panel,
	})
	local ring = New("Frame", {
		Position = UDim2.fromOffset(c.cx - orad, c.cy - orad),
		Size = UDim2.fromOffset(orad * 2, orad * 2),
		BackgroundTransparency = 1,
		ZIndex = 1,
		Parent = outClip,
	})
	Round(ring, orad)
	local ringStroke = Stroke(ring, Color3.new(1, 1, 1), S)

	local kA, kB, kp
	if c.top then
		kA, kB = gY(c.cy - orad), gY(c.cy)
		kp = {
			ColorSequenceKeypoint.new(0, kA),
			ColorSequenceKeypoint.new(0.5, kB),
			ColorSequenceKeypoint.new(1, kB),
		}
	else
		kA, kB = gY(c.cy), gY(c.cy + orad)
		kp = {
			ColorSequenceKeypoint.new(0, kA),
			ColorSequenceKeypoint.new(0.5, kA),
			ColorSequenceKeypoint.new(1, kB),
		}
	end
	Grad(ringStroke, kp, 90)   -- ✅ parent = UIStroke

	-- quarter-disc fill
	local clipX2 = c.left and (c.cx - R_CARD - 1) or c.cx
	local clipY2 = c.top  and (c.cy - R_CARD - 1) or c.cy
	local fillClip = New("Frame", {
		Position = UDim2.fromOffset(clipX2, clipY2),
		Size = UDim2.fromOffset(R_CARD + 1, R_CARD + 1),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		ZIndex = 2,
		Parent = panel,
	})
	local disc = New("Frame", {
		Position = UDim2.fromOffset(c.cx - R_CARD, c.cy - R_CARD),
		Size = UDim2.fromOffset(R_CARD * 2, R_CARD * 2),
		BackgroundColor3 = c.top and Theme.Surface or Theme.SurfaceDeep,
		ZIndex = 2,
		Parent = fillClip,
	})
	Round(disc, R_CARD)
end

--────────────────────────────────────────────────────────────────────────────
-- PANEL • NOTCH ARCS (lip surface + arc gradient, AA, menelan semua deviasi)
--────────────────────────────────────────────────────────────────────────────
local notchClip = New("Frame", {
	Position = UDim2.fromOffset(cx - RB - 2, 0),
	Size = UDim2.fromOffset((RB + 2) * 2, RB + 2),
	BackgroundTransparency = 1,
	ClipsDescendants = true,
	ZIndex = 3,
	Parent = panel,
})

local lip = New("Frame", {
	Position = UDim2.fromOffset(cx - RB, -RB),
	Size = UDim2.fromOffset(RB * 2, RB * 2),
	BackgroundTransparency = 1,
	ZIndex = 1,
	Parent = notchClip,
})
Round(lip, RB)
Stroke(lip, Theme.Surface, LIP)

local arc = New("Frame", {
	Position = UDim2.fromOffset(cx - RC, -RC),
	Size = UDim2.fromOffset(RC * 2, RC * 2),
	BackgroundTransparency = 1,
	ZIndex = 2,
	Parent = notchClip,
})
Round(arc, RC)
local arcStroke = Stroke(arc, Color3.new(1, 1, 1), S)
Grad(arcStroke, {
	ColorSequenceKeypoint.new(0,   gY(0)),
	ColorSequenceKeypoint.new(0.5, gY(0)),
	ColorSequenceKeypoint.new(1,   gY(RC)),
}, 90)   -- ✅ parent = UIStroke

--────────────────────────────────────────────────────────────────────────────
-- BAR (bawah, gap transparan sesuai kontrak mock — tanpa lens glow)
--────────────────────────────────────────────────────────────────────────────
local bar = New("Frame", {
	Name = "Bar",
	Position = UDim2.fromOffset(0, OVERHANG + CARD_H + GAP),
	Size = UDim2.fromOffset(WIDTH, BAR_H),
	BackgroundColor3 = Theme.SurfaceDeep,
	Parent = widget,
})
Round(bar, 20)
local barStroke = Stroke(bar, Color3.new(1, 1, 1), S)
Grad(barStroke, {
	ColorSequenceKeypoint.new(0, gradAt((OVERHANG + CARD_H + GAP) / outerH)),
	ColorSequenceKeypoint.new(1, gradAt(1)),
}, 0)

-- avatar
local avatarRing = New("Frame", {
	Position = UDim2.fromOffset(14, BAR_H / 2 - 21),
	Size = UDim2.fromOffset(42, 42),
	BackgroundTransparency = 1,
	Parent = bar,
})
Round(avatarRing, 21)
local avStroke = Stroke(avatarRing, Color3.new(1, 1, 1), S)
Grad(avStroke, {
	ColorSequenceKeypoint.new(0, Theme.Accent2),
	ColorSequenceKeypoint.new(1, Theme.Accent1),
}, 135)

local avatarCore = New("Frame", {
	Position = UDim2.fromOffset(3, 3),
	Size = UDim2.fromOffset(36, 36),
	BackgroundColor3 = Theme.Surface,
	Parent = avatarRing,
})
Round(avatarCore, 18)

Label({
	Text = "🦊",
	TextSize = 18,
	Size = UDim2.fromScale(1, 1),
	Position = UDim2.fromOffset(0, 0),
	TextXAlignment = Enum.TextXAlignment.Center,
	TextYAlignment = Enum.TextYAlignment.Center,
	Parent = avatarCore,
})

-- name + status
Label({
	Text = "bergerigi",
	Font = Enum.Font.GothamBold,
	TextSize = 16,
	Position = UDim2.fromOffset(66, 12),
	Size = UDim2.fromOffset(180, 18),
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = bar,
})
Label({
	Text = '#0001   <font color="rgb(87,242,135)">● online</font>',
	RichText = true,
	TextSize = 12,
	TextColor3 = Theme.Sub,
	Position = UDim2.fromOffset(66, 32),
	Size = UDim2.fromOffset(180, 16),
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = bar,
})

-- discord pill
local pill = New("Frame", {
	Position = UDim2.fromOffset(WIDTH - 110, BAR_H / 2 - 16),
	Size = UDim2.fromOffset(96, 32),
	BackgroundColor3 = Theme.Blurple,
	Parent = bar,
})
Round(pill, 16)
Label({
	Text = "DISCORD",
	Font = Enum.Font.GothamBold,
	TextSize = 11,
	Size = UDim2.fromScale(1, 1),
	TextXAlignment = Enum.TextXAlignment.Center,
	TextYAlignment = Enum.TextYAlignment.Center,
	Parent = pill,
})

--────────────────────────────────────────────────────────────────────────────
-- BADGE (di tengah notch, negative space transparan di sekelilingnya)
--────────────────────────────────────────────────────────────────────────────
local badgeRing = New("Frame", {
	Name = "Badge",
	Position = UDim2.fromOffset(cx - 44, OVERHANG - 44),
	Size = UDim2.fromOffset(88, 88),
	BackgroundTransparency = 1,
	Parent = widget,
})
Round(badgeRing, 44)
local badgeStroke = Stroke(badgeRing, Color3.new(1, 1, 1), 3)
Grad(badgeStroke, {
	ColorSequenceKeypoint.new(0, Theme.Accent2),
	ColorSequenceKeypoint.new(1, Theme.Accent1),
}, 135)

local badgeCore = New("Frame", {
	Position = UDim2.fromOffset(4, 4),
	Size = UDim2.fromOffset(80, 80),
	BackgroundColor3 = Theme.SurfaceDeep,
	Parent = badgeRing,
})
Round(badgeCore, 40)

Label({
	Text = "✦",
	Font = Enum.Font.GothamBold,
	TextSize = 32,
	Size = UDim2.fromScale(1, 1),
	TextXAlignment = Enum.TextXAlignment.Center,
	TextYAlignment = Enum.TextYAlignment.Center,
	Parent = badgeCore,
})

--────────────────────────────────────────────────────────────────────────────
-- CONTENT KARTU
--────────────────────────────────────────────────────────────────────────────
local content = New("Frame", {
	Name = "Content",
	Position = UDim2.fromOffset(24, OVERHANG + 30),
	Size = UDim2.fromOffset(WIDTH - 48, CARD_H - 60),
	BackgroundTransparency = 1,
	Parent = widget,
})

Label({
	Text = "PREMIUM LOUNGE",
	Font = Enum.Font.GothamBold,
	TextSize = 20,
	Position = UDim2.fromOffset(0, 0),
	Size = UDim2.fromOffset(WIDTH - 48, 24),
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = content,
})
Label({
	Text = "Notch mulus • primitive antialiased • nol gerigi",
	TextSize = 12,
	TextColor3 = Theme.Sub,
	Position = UDim2.fromOffset(0, 28),
	Size = UDim2.fromOffset(WIDTH - 48, 16),
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = content,
})

local divider = New("Frame", {
	Position = UDim2.fromOffset(0, 58),
	Size = UDim2.fromOffset(WIDTH - 48, 2),
	BackgroundColor3 = Color3.new(1, 1, 1),
	Parent = content,
})
Grad(divider, {
	ColorSequenceKeypoint.new(0, Theme.Accent1),
	ColorSequenceKeypoint.new(1, Theme.Accent2),
}, 0)

local rows = {
	{ label = "Anggota", value = "12.480", dot = Theme.Accent1 },
	{ label = "Online",  value = "3.214",  dot = Theme.Green },
}
for i, r in ipairs(rows) do
	local y = 76 + (i - 1) * 28
	local dot = New("Frame", {
		Position = UDim2.fromOffset(0, y + 4),
		Size = UDim2.fromOffset(8, 8),
		BackgroundColor3 = r.dot,
		Parent = content,
	})
	Round(dot, 4)
	Label({
		Text = r.label,
		TextSize = 13,
		Position = UDim2.fromOffset(16, y),
		Size = UDim2.fromOffset(160, 16),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = content,
	})
	Label({
		Text = r.value,
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		Position = UDim2.fromOffset(WIDTH - 48 - 90, y),
		Size = UDim2.fromOffset(90, 16),
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = content,
	})
end

--────────────────────────────────────────────────────────────────────────────
-- DRAG (pegang area kartu untuk geser seluruh widget)
--────────────────────────────────────────────────────────────────────────────
local dragFrame = New("Frame", {
	Name = "Drag",
	Position = UDim2.fromOffset(0, OVERHANG),
	Size = UDim2.fromOffset(WIDTH, CARD_H),
	BackgroundTransparency = 1,
	Parent = widget,
})

local dragging, dragStart, startPos
dragFrame.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
		dragging  = true
		dragStart = input.Position
		startPos  = widget.Position
	end
end)
UIS.InputChanged:Connect(function(input)
	if dragging
		and (input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = input.Position - dragStart
		widget.Position = UDim2.new(
			startPos.X.Scale, startPos.X.Offset + delta.X,
			startPos.Y.Scale, startPos.Y.Offset + delta.Y
		)
	end
end)
UIS.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
		dragging = false
	end
end)

--────────────────────────────────────────────────────────────────────────────
-- ENTRANCE + TOGGLE (RightShift)
--────────────────────────────────────────────────────────────────────────────
TweenService:Create(
	uiScale,
	TweenInfo.new(0.7, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
	{ Scale = 1 }
):Play()

local shown = true
UIS.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode ~= Enum.KeyCode.RightShift then return end

	if shown then
		shown = false
		local t = TweenService:Create(
			uiScale,
			TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.In),
			{ Scale = 0.9 }
		)
		t:Play()
		t.Completed:Wait()
		gui.Enabled = false
	else
		shown = true
		gui.Enabled = true
		uiScale.Scale = 0.94
		TweenService:Create(
			uiScale,
			TweenInfo.new(0.6, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
			{ Scale = 1 }
		):Play()
	end
end)
