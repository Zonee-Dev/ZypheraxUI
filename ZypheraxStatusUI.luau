local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

local DEFAULT_LOGO = "rbxassetid://106764279090045"

-- Measured tokens -------------------------------------------------------

local Theme = {
	-- Sapphire gradient used by every stroke in the interface (per-element,
	-- vertical): bright facet highlight -> sapphire -> deep navy.
	-- NOTE: keep this a gradient. A flat UIStroke is what makes a window look
	-- "roblox default".
	StrokeTop = Color3.fromRGB(96, 170, 255),
	StrokeMid = Color3.fromRGB(28, 100, 232),
	StrokeBottom = Color3.fromRGB(10, 46, 138),

	-- Surfaces: deep matte black with a faint cool undertone
	Surface = Color3.fromRGB(16, 17, 22),
	SurfaceDeep = Color3.fromRGB(9, 10, 13),
	Raised = Color3.fromRGB(23, 25, 32),
	Hover = Color3.fromRGB(31, 35, 46),
	Pressed = Color3.fromRGB(18, 20, 27),
	Inset = Color3.fromRGB(8, 9, 12),
	Track = Color3.fromRGB(40, 44, 56),

	-- Lines
	Border = Color3.fromRGB(36, 40, 52),
	BorderStrong = Color3.fromRGB(50, 56, 72),

	-- Text hierarchy
	Text = Color3.fromRGB(245, 247, 251),
	TextSecondary = Color3.fromRGB(188, 194, 206),
	TextTertiary = Color3.fromRGB(128, 136, 152),

	-- Brand + semantics
	Accent = Color3.fromRGB(46, 120, 246),
	White = Color3.fromRGB(245, 245, 245),     -- avatar / launcher ring
	Discord = Color3.fromRGB(58, 128, 250),
	DiscordEdge = Color3.fromRGB(26, 78, 206),
	DiscordOutline = Color3.fromRGB(120, 172, 255),
	DiscordText = Color3.fromRGB(255, 255, 255),
	Success = Color3.fromRGB(80, 178, 128),
	Warning = Color3.fromRGB(236, 178, 70),
	Danger = Color3.fromRGB(224, 92, 92),

	-- Brushed steel for the header badges
	SteelTop = Color3.fromRGB(222, 228, 238),
	SteelBottom = Color3.fromRGB(148, 156, 170),
	SteelInk = Color3.fromRGB(12, 20, 38),
}

-- Geometry, measured then rescaled by k = 1.129 --------------------------

local WIDTH = 420
local CARD_H = 301
local GAP = 16
local BAR_H = 74
local TOTAL_H = CARD_H + GAP + BAR_H

local R_CARD = 29
local STROKE = 2
local ROW = 2                       -- silhouette slice height for the notch

-- Logo disc + the transparent concave notch carved out of the panel top.
-- The notch is a true negative-space cutout: no white disc, no filler.
local BADGE_D = 124                 -- gradient-outlined logo disc diameter
local NOTCH_R = 72                  -- radius of the recessed cutout
local NOTCH_GAP = NOTCH_R - BADGE_D / 2   -- transparent breathing room (10px)
local OVERHANG = BADGE_D / 2        -- logo centre sits on the panel top edge

local AVATAR = 54
local AVATAR_IMG = 44
local AVATAR_MARGIN = 10

local INFO_X = 82
local INFO_BOX = 13                 -- line box height of the identity block
local INFO_GAP = 2                  -- breathing room between the lines
local INFO_TITLE = 13
local INFO_LABEL_W = 64            -- fixed label column so every value shares one left edge
local INFO_SIZE = 11

local DISCORD_W = 112
local DISCORD_H = 42
local DISCORD_MARGIN = 16        -- equals the vertical inset: (BAR_H - DISCORD_H) / 2

local CONTENT_X = 16
local CONTENT_TOP = NOTCH_R + 12    -- clears the recessed notch inside the card
local CONTENT_BOTTOM = 16

local Library = {
	Unloaded = false,
	Windows = {},
	Icons = { chevron = "", close = "", minimize = "", discord = "", check = "", crown = "", info = "", warn = "" },
}

-- Small utilities --------------------------------------------------------

local function New(class, props)
	local inst = Instance.new(class)
	local parent = props.Parent
	props.Parent = nil
	for key, value in pairs(props) do
		inst[key] = value
	end
	if class == "Frame" or class == "TextLabel" or class == "TextButton"
		or class == "ImageLabel" or class == "ImageButton" or class == "ScrollingFrame"
		or class == "TextBox" or class == "CanvasGroup" then
		if inst.BorderSizePixel ~= nil then
			inst.BorderSizePixel = 0
		end
	end
	inst.Parent = parent
	return inst
end

local function Round(parent, radius)
	return New("UICorner", { CornerRadius = UDim.new(0, radius), Parent = parent })
end

local function Tween(obj, duration, props, style, direction)
	local tween = TweenService:Create(
		obj,
		TweenInfo.new(duration, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out),
		props
	)
	tween:Play()
	return tween
end

-- The signature look: a 2px stroke that falls from azure to deep navy.
-- Implemented as a slightly larger gradient shell with the fill inset on top,
-- because UIStroke cannot take a gradient. If UIGradient ever fails on an
-- executor, the shell falls back to the flat top colour instead of white.
local function GradientShell(parent, name, position, size, radius, colors, zIndex)
	colors = colors or Theme
	local top = colors.top or Theme.StrokeTop
	local mid = colors.mid or Theme.StrokeMid
	local bottom = colors.bottom or Theme.StrokeBottom

	local shell = New("Frame", {
		Name = name .. "Shell",
		Position = UDim2.new(position.X.Scale, position.X.Offset - STROKE, position.Y.Scale, position.Y.Offset - STROKE),
		Size = UDim2.new(size.X.Scale, size.X.Offset + STROKE * 2, size.Y.Scale, size.Y.Offset + STROKE * 2),
		BackgroundColor3 = top,
		ZIndex = zIndex or 1,
		Parent = parent,
	})
	Round(shell, radius + STROKE)
	New("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, top),
			ColorSequenceKeypoint.new(0.5, mid),
			ColorSequenceKeypoint.new(1, bottom),
		}),
		Rotation = 90,
		Parent = shell,
	})
	return shell
end

local function Fill(parent, name, radius, color, zIndex, inset)
	inset = inset or STROKE
	local fill = New("Frame", {
		Name = name,
		Position = UDim2.fromOffset(inset, inset),
		Size = UDim2.new(1, -inset * 2, 1, -inset * 2),
		BackgroundColor3 = color or Theme.Surface,
		ZIndex = zIndex or 2,
		Parent = parent,
	})
	Round(fill, radius)
	return fill
end

-- Typography: Gotham is Roblox's built-in geometric sans. Font.fromEnum is
-- always available, unlike family JSON paths that can silently fall back to a
-- default face on some clients (which is what made the old text look off).
local FONT_BY_WEIGHT = {
	[Enum.FontWeight.Regular] = Enum.Font.Gotham,
	[Enum.FontWeight.Medium] = Enum.Font.GothamMedium,
	[Enum.FontWeight.SemiBold] = Enum.Font.GothamSemibold,
	[Enum.FontWeight.Bold] = Enum.Font.GothamBold,
}

local function MakeFont(weight)
	local ok, font = pcall(Font.fromEnum, FONT_BY_WEIGHT[weight] or Enum.Font.Gotham)
	if ok and font then
		return font
	end
	return Font.new("rbxasset://fonts/families/SourceSansPro.json", weight)
end

local Typo = {
	Regular = MakeFont(Enum.FontWeight.Regular),
	Medium = MakeFont(Enum.FontWeight.Medium),
	SemiBold = MakeFont(Enum.FontWeight.SemiBold),
	Bold = MakeFont(Enum.FontWeight.Bold),
}

local function Label(props)
	local weight = props.Weight
	props.Weight = nil
	props.FontFace = Typo[weight or "Regular"]
	if props.BackgroundTransparency == nil then
		props.BackgroundTransparency = 1
	end
	if props.TextXAlignment == nil then
		props.TextXAlignment = Enum.TextXAlignment.Left
	end
	return New("TextLabel", props)
end

local function Opt(cfg, index, key, default)
	local value = cfg[index]
	if value == nil then
		value = cfg[key]
	end
	if value == nil then
		return default
	end
	return value
end

local function IsPointer(input)
	return input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch
end

local function IsMove(input)
	return input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch
end

local function ResolveParent()
	if typeof(gethui) == "function" then
		local ok, result = pcall(gethui)
		if ok and result then
			return result
		end
	end
	local ok, core = pcall(function()
		return CoreGui
	end)
	if ok and core then
		local ok2, roblox = pcall(function()
			return core:WaitForChild("RobloxGui")
		end)
		if ok2 and roblox then
			return roblox
		end
	end
	return LocalPlayer:WaitForChild("PlayerGui")
end

local function ViewportScale()
	local viewport = Workspace.CurrentCamera.ViewportSize
	return math.clamp(math.min(viewport.X / (WIDTH + 120), viewport.Y / (TOTAL_H + OVERHANG + 120)), 0.55, 1.15)
end

-- Drawn glyphs: crisp at any size, tintable, zero assets ------------------

local function Glyph(parent, name, color, size)
	local holder = New("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(size, size),
		BackgroundTransparency = 1,
		Parent = parent,
	})

	local parts, isImage = {}, false
	local asset = Library.Icons[name]

	if asset and asset ~= "" then
		isImage = true
		table.insert(parts, New("ImageLabel", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Image = asset,
			ImageColor3 = color,
			ScaleType = Enum.ScaleType.Fit,
			Parent = holder,
		}))
	else
		local function bar(length, thickness, rotation, dx, dy)
			local part = New("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, dx, 0.5, dy),
				Size = UDim2.fromOffset(length, thickness),
				Rotation = rotation,
				BackgroundColor3 = color,
				Parent = holder,
			})
			Round(part, thickness / 2)
			table.insert(parts, part)
		end

		if name == "chevron" then
			bar(size * 0.42, 2, 45, -size * 0.04, -size * 0.15)
			bar(size * 0.42, 2, -45, -size * 0.04, size * 0.15)
		elseif name == "chevronDown" then
			bar(size * 0.42, 2, 45, -size * 0.15, -size * 0.04)
			bar(size * 0.42, 2, -45, size * 0.15, -size * 0.04)
		elseif name == "close" then
			bar(size * 0.72, 2, 45, 0, 0)
			bar(size * 0.72, 2, -45, 0, 0)
		elseif name == "minimize" then
			bar(size * 0.6, 2, 0, 0, 0)
		elseif name == "check" then
			bar(size * 0.34, 2, 45, -size * 0.16, size * 0.06)
			bar(size * 0.58, 2, -45, size * 0.1, -size * 0.06)
		elseif name == "crown" then
			local u = size / 12
			bar(10.4 * u, 2.4 * u, 0, 0, 4.7 * u)             -- base
			bar(6 * u, 2 * u, 90, -4 * u, 0.4 * u)            -- left prong
			bar(8 * u, 2 * u, 90, 0, -0.6 * u)                -- centre prong
			bar(6 * u, 2 * u, 90, 4 * u, 0.4 * u)             -- right prong
			bar(2.8 * u, 2.8 * u, 0, -4 * u, -2.6 * u)        -- jewels
			bar(2.8 * u, 2.8 * u, 0, 0, -4.6 * u)
			bar(2.8 * u, 2.8 * u, 0, 4 * u, -2.6 * u)
		elseif name == "info" then
			bar(2.6, 2.6, 0, 0, -size * 0.3)
			bar(size * 0.4, 2, 90, 0, size * 0.12)
		elseif name == "warn" then
			bar(size * 0.4, 2, 90, 0, -size * 0.12)
			bar(2.6, 2.6, 0, 0, size * 0.3)
		end
	end

	local function paint(newColor, duration)
		local prop = isImage and "ImageColor3" or "BackgroundColor3"
		for _, part in ipairs(parts) do
			if duration and duration > 0 then
				Tween(part, duration, { [prop] = newColor })
			else
				part[prop] = newColor
			end
		end
	end

	return holder, paint
end

-- Dragging ----------------------------------------------------------------

local function MakeDraggable(handle, target, uiScale)
	local state = { Moved = false }

	handle.InputBegan:Connect(function(input)
		if not IsPointer(input) then
			return
		end
		if UserInputService:GetFocusedTextBox() then
			return
		end

		local origin, startPos = input.Position, target.Position
		state.Moved = false

		local move, ended
		move = UserInputService.InputChanged:Connect(function(changed)
			if not IsMove(changed) then
				return
			end
			local delta = changed.Position - origin
			if delta.Magnitude > 4 then
				state.Moved = true
			end
			local s = uiScale and uiScale.Scale or 1
			target.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + delta.X / s,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y / s
			)
		end)
		ended = input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				move:Disconnect()
				ended:Disconnect()
			end
		end)
	end)

	return state
end

-- Notifications -----------------------------------------------------------

local notifyGui, notifyOrder = nil, 0

local function NotifyHolder()
	if notifyGui and notifyGui.Parent then
		return notifyGui.Holder
	end

	notifyGui = New("ScreenGui", {
		Name = "ZypheraxNotify",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 200,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = ResolveParent(),
	})

	local holder = New("Frame", {
		Name = "Holder",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -16, 1, -16),
		Size = UDim2.new(0, 300, 1, -32),
		BackgroundTransparency = 1,
		Parent = notifyGui,
	})
	New("UIListLayout", {
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		Parent = holder,
	})
	return holder
end

function Library:Notify(cfg)
	cfg = cfg or {}
	local title = Opt(cfg, 1, "Title", "Notice")
	local content = Opt(cfg, 2, "Content", "")
	local duration = Opt(cfg, 3, "Duration", 4)
	local kind = cfg.Type and string.lower(tostring(cfg.Type)) or nil
	local kindColors = {
		success = Theme.Success,
		warning = Theme.Warning,
		error = Theme.Danger,
		info = Theme.Accent,
	}
	local kindIcon = { success = "check", warning = "warn", error = "close", info = "info" }
	local accent = cfg.Color or (kind and kindColors[kind]) or Theme.Accent
	if not kind or not kindIcon[kind] then
		-- No explicit Type: infer it from the colour so existing calls get a matching icon.
		kind = "info"
		for name, color in pairs(kindColors) do
			local distance = math.abs(accent.R - color.R) + math.abs(accent.G - color.G) + math.abs(accent.B - color.B)
			if name ~= "info" and distance < 0.2 then
				kind = name
			end
		end
	end

	notifyOrder += 1

	local shell = New("Frame", {
		Name = "Toast",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Color3.new(1, 1, 1),
		LayoutOrder = notifyOrder,
		Parent = NotifyHolder(),
	})
	New("UIGradient", {
		Color = ColorSequence.new(Theme.StrokeTop, Theme.StrokeBottom),
		Rotation = 90,
		Parent = shell,
	})
	Round(shell, 10)

	local toast = New("CanvasGroup", {
		Position = UDim2.fromOffset(2, 2),
		Size = UDim2.new(1, -4, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Theme.Surface,
		GroupTransparency = 1,
		Parent = shell,
	})
	Round(toast, 8)

	New("Frame", {
		Name = "Stripe",
		Position = UDim2.fromOffset(0, 6),
		Size = UDim2.new(0, 3, 1, -12),
		BackgroundColor3 = accent,
		Parent = toast,
	})
	Round(toast.Stripe, 2)

	local body = New("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Parent = toast,
	})
	New("UIPadding", {
		PaddingTop = UDim.new(0, 11), PaddingBottom = UDim.new(0, 11),
		PaddingLeft = UDim.new(0, 46), PaddingRight = UDim.new(0, 30),
		Parent = body,
	})
	New("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder, Parent = body })

	Label({
		LayoutOrder = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Weight = "SemiBold",
		Text = title,
		TextSize = 13,
		TextColor3 = Theme.Text,
		TextWrapped = true,
		Parent = body,
	})
	if content ~= "" then
		Label({
			LayoutOrder = 2,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Text = content,
			TextSize = 12,
			TextColor3 = Theme.TextSecondary,
			TextWrapped = true,
			Parent = body,
		})
	end

	local iconBadge = New("Frame", {
		Name = "Icon",
		Position = UDim2.fromOffset(16, 10),
		Size = UDim2.fromOffset(22, 22),
		BackgroundColor3 = accent,
		BackgroundTransparency = 0.82,
		Parent = toast,
	})
	Round(iconBadge, 11)
	New("UIStroke", {
		Color = accent,
		Thickness = 1,
		Transparency = 0.55,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = iconBadge,
	})
	Glyph(iconBadge, kindIcon[kind], accent, 12)

	local closer, closePaint = Glyph(toast, "close", Theme.TextTertiary, 12)
	closer.AnchorPoint = Vector2.new(1, 0)
	closer.Position = UDim2.new(1, -10, 0, 10)

	local closed = false
	local function dismiss()
		if closed then
			return
		end
		closed = true
		local height = shell.AbsoluteSize.Y
		shell.AutomaticSize = Enum.AutomaticSize.None
		shell.Size = UDim2.new(1, 0, 0, height)
		Tween(toast, 0.18, { GroupTransparency = 1 })
		Tween(shell, 0.2, { Size = UDim2.new(1, 0, 0, 0) }, Enum.EasingStyle.Quint)
		task.delay(0.24, function()
			shell:Destroy()
		end)
	end

	closer.InputBegan:Connect(function(input)
		if IsPointer(input) then
			dismiss()
		end
	end)
	closer.MouseEnter:Connect(function() closePaint(Theme.Text, 0.1) end)
	closer.MouseLeave:Connect(function() closePaint(Theme.TextTertiary, 0.1) end)

	Tween(toast, 0.22, { GroupTransparency = 0 }, Enum.EasingStyle.Quint)
	if duration and duration > 0 then
		task.delay(duration, dismiss)
	end
	return { Dismiss = dismiss }
end

function Library:SetNotification(cfg)
	cfg = cfg or {}
	return self:Notify({
		Title = cfg.Title or cfg[1],
		Content = cfg.Content or cfg.Description or cfg[2],
		Duration = cfg.Duration or cfg.Delay or cfg[3],
		Color = cfg.Color,
	})
end

-- Row controls ------------------------------------------------------------

local function BuildItems(page, accents)
	local items, order = {}, 0

	local function nextOrder()
		order += 1
		return order
	end

	local function Row(height)
		local row = New("Frame", {
			BackgroundColor3 = Theme.Raised,
			Size = UDim2.new(1, 0, 0, height),
			LayoutOrder = nextOrder(),
			Parent = page,
		})
		Round(row, 8)
		New("UIStroke", {
			Color = Theme.Border,
			Thickness = 1,
			Transparency = 0.4,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Parent = row,
		})
		return row
	end

	local function Titles(row, title, desc, rightInset)
		Label({
			AnchorPoint = Vector2.new(0, desc and 0 or 0.5),
			Position = desc and UDim2.fromOffset(12, 9) or UDim2.new(0, 12, 0.5, 0),
			Size = UDim2.new(1, -(12 + rightInset), 0, 16),
			Weight = "Medium",
			Text = title,
			TextSize = 13,
			TextColor3 = Theme.Text,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = row,
		})
		if desc then
			Label({
				Position = UDim2.fromOffset(12, 27),
				Size = UDim2.new(1, -(12 + rightInset), 0, 14),
				Text = desc,
				TextSize = 11,
				TextColor3 = Theme.TextTertiary,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Parent = row,
			})
		end
	end

	local function Hit(row, leaveColor)
		local hit = New("TextButton", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Text = "",
			AutoButtonColor = false,
			Parent = row,
		})
		hit.MouseEnter:Connect(function()
			Tween(row, 0.12, { BackgroundColor3 = Theme.Hover })
		end)
		hit.MouseLeave:Connect(function()
			Tween(row, 0.12, { BackgroundColor3 = leaveColor or Theme.Raised })
		end)
		hit.MouseButton1Down:Connect(function()
			Tween(row, 0.06, { BackgroundColor3 = Theme.Pressed })
		end)
		hit.MouseButton1Up:Connect(function()
			Tween(row, 0.1, { BackgroundColor3 = Theme.Hover })
		end)
		return hit
	end

	function items:AddSection(title)
		local wrap = New("Frame", {
			Size = UDim2.new(1, 0, 0, 22),
			LayoutOrder = nextOrder(),
			BackgroundTransparency = 1,
			Parent = page,
		})
		local heading = Label({
			Position = UDim2.fromOffset(2, 0),
			Size = UDim2.new(0, 0, 1, 0),
			AutomaticSize = Enum.AutomaticSize.X,
			Weight = "SemiBold",
			Text = string.upper(title or ""),
			TextSize = 10,
			TextColor3 = Theme.TextTertiary,
			TextYAlignment = Enum.TextYAlignment.Center,
			Parent = wrap,
		})
		local divider = New("Frame", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 14, 0.5, 0),
			Size = UDim2.new(1, -14, 0, 1),
			BackgroundColor3 = Theme.Border,
			BackgroundTransparency = 0.45,
			Parent = wrap,
		})
		heading:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
			local width = heading.AbsoluteSize.X + 12
			divider.Position = UDim2.new(0, width, 0.5, 0)
			divider.Size = UDim2.new(1, -width, 0, 1)
		end)
		return self
	end

	function items:AddLabel(text)
		local label = Label({
			Size = UDim2.new(1, -4, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			LayoutOrder = nextOrder(),
			Text = text or "",
			TextSize = 12,
			TextColor3 = Theme.TextSecondary,
			TextWrapped = true,
			Parent = page,
		})
		return {
			Set = function(_, value)
				label.Text = tostring(value)
			end,
		}
	end

	function items:AddButton(cfg, legacy)
		if type(cfg) == "string" then
			cfg = { Title = cfg, Callback = legacy }
		end
		cfg = cfg or {}
		local title = Opt(cfg, 1, "Title", "Button")
		local desc = Opt(cfg, 2, "Content", nil)
		local callback = Opt(cfg, 4, "Callback", function() end)
		if desc == "" then
			desc = nil
		end

		local row = Row(desc and 50 or 38)
		Titles(row, title, desc, 40)

		local holder, paint = Glyph(row, "chevron", Theme.TextTertiary, 15)
		holder.AnchorPoint = Vector2.new(1, 0.5)
		holder.Position = UDim2.new(1, -12, 0.5, 0)

		local hit = Hit(row)
		hit.MouseEnter:Connect(function() paint(Theme.TextSecondary, 0.12) end)
		hit.MouseLeave:Connect(function() paint(Theme.TextTertiary, 0.12) end)
		hit.Activated:Connect(function()
			task.spawn(callback)
		end)
		return { Fire = function() task.spawn(callback) end }
	end

	function items:AddToggle(cfg, legacy)
		if type(cfg) == "string" then
			cfg = { Title = cfg, Callback = legacy }
		end
		cfg = cfg or {}
		local title = Opt(cfg, 1, "Title", "Toggle")
		local desc = Opt(cfg, 2, "Content", nil)
		local default = Opt(cfg, 3, "Default", false)
		local callback = Opt(cfg, 4, "Callback", function() end)
		if desc == "" then
			desc = nil
		end

		local obj = { Value = default and true or false }
		local row = Row(desc and 50 or 38)
		Titles(row, title, desc, 60)

		local track = New("Frame", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -12, 0.5, 0),
			Size = UDim2.fromOffset(36, 20),
			BackgroundColor3 = Theme.Track,
			Parent = row,
		})
		Round(track, 10)
		local knob = New("Frame", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 3, 0.5, 0),
			Size = UDim2.fromOffset(14, 14),
			BackgroundColor3 = Theme.White,
			Parent = track,
		})
		Round(knob, 7)

		local function render(animate)
			local trackColor = obj.Value and accents.fill or Theme.Track
			local knobPos = UDim2.new(0, obj.Value and 19 or 3, 0.5, 0)
			if animate then
				Tween(track, 0.16, { BackgroundColor3 = trackColor })
				Tween(knob, 0.18, { Position = knobPos }, Enum.EasingStyle.Quint)
			else
				track.BackgroundColor3 = trackColor
				knob.Position = knobPos
			end
		end

		function obj:Set(value, silent)
			obj.Value = value and true or false
			render(true)
			if not silent then
				task.spawn(callback, obj.Value)
			end
			return obj.Value
		end

		Hit(row).Activated:Connect(function()
			obj:Set(not obj.Value)
		end)

		render(false)
		if default then
			task.spawn(callback, true)
		end
		return obj
	end

	function items:AddSlider(cfg, legacy)
		if type(cfg) == "string" then
			cfg = { Title = cfg, Callback = legacy }
		end
		cfg = cfg or {}
		local title = Opt(cfg, 1, "Title", "Slider")
		local increment = Opt(cfg, 3, "Increment", 1)
		local min = Opt(cfg, 4, "Min", 0)
		local max = Opt(cfg, 5, "Max", 100)
		local default = Opt(cfg, 6, "Default", min)
		local suffix = cfg.Suffix or ""
		local callback = Opt(cfg, 7, "Callback", function() end)

		local obj = { Value = default }
		local row = Row(50)

		Label({
			Position = UDim2.fromOffset(12, 9),
			Size = UDim2.new(1, -90, 0, 16),
			Weight = "Medium",
			Text = title,
			TextSize = 13,
			TextColor3 = Theme.Text,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = row,
		})
		local valueLabel = Label({
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -12, 0, 9),
			Size = UDim2.fromOffset(64, 16),
			Weight = "Medium",
			TextSize = 12,
			TextColor3 = accents.top,
			TextXAlignment = Enum.TextXAlignment.Right,
			Parent = row,
		})

		local track = New("Frame", {
			Position = UDim2.fromOffset(12, 34),
			Size = UDim2.new(1, -24, 0, 4),
			BackgroundColor3 = Theme.Track,
			Parent = row,
		})
		Round(track, 2)
		local fill = New("Frame", {
			Size = UDim2.fromScale(0, 1),
			BackgroundColor3 = Color3.new(1, 1, 1),
			Parent = track,
		})
		Round(fill, 2)
		New("UIGradient", {
			Color = ColorSequence.new(accents.top, accents.bottom),
			Rotation = 0,
			Parent = fill,
		})
		local knob = New("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(1, 0.5),
			Size = UDim2.fromOffset(12, 12),
			BackgroundColor3 = Theme.White,
			Parent = fill,
		})
		Round(knob, 6)
		New("UIStroke", { Color = Theme.Surface, Thickness = 2, Parent = knob })

		local function format(value)
			local text = (increment % 1 == 0) and tostring(math.floor(value + 0.5)) or tostring(math.floor(value * 100 + 0.5) / 100)
			return text .. suffix
		end

		local function snap(value)
			value = math.clamp(value, min, max)
			value = min + math.floor((value - min) / increment + 0.5) * increment
			value = math.clamp(value, min, max)
			return math.floor(value * 10000 + 0.5) / 10000
		end

		local function render()
			local range = max - min
			fill.Size = UDim2.fromScale(range == 0 and 0 or (obj.Value - min) / range, 1)
			valueLabel.Text = format(obj.Value)
		end

		function obj:Set(value, silent)
			value = snap(value)
			local changed = value ~= obj.Value
			obj.Value = value
			render()
			if changed and not silent then
				task.spawn(callback, value)
			end
			return value
		end

		local function fromInput(position)
			local alpha = math.clamp((position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
			obj:Set(min + (max - min) * alpha)
		end

		local hit = New("TextButton", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(12, 26),
			Size = UDim2.new(1, -24, 0, 20),
			Text = "",
			AutoButtonColor = false,
			Parent = row,
		})
		hit.InputBegan:Connect(function(input)
			if not IsPointer(input) then
				return
			end
			fromInput(input.Position)
			Tween(knob, 0.1, { Size = UDim2.fromOffset(14, 14) })
			page.ScrollingEnabled = false

			local move, ended
			move = UserInputService.InputChanged:Connect(function(changed)
				if IsMove(changed) then
					fromInput(changed.Position)
				end
			end)
			ended = input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					move:Disconnect()
					ended:Disconnect()
					Tween(knob, 0.14, { Size = UDim2.fromOffset(12, 12) })
					page.ScrollingEnabled = true
				end
			end)
		end)

		obj.Value = snap(default)
		render()
		return obj
	end

	function items:AddDropdown(cfg, legacy)
		if type(cfg) == "string" then
			cfg = { Title = cfg, Callback = legacy }
		end
		cfg = cfg or {}
		local title = Opt(cfg, 1, "Title", "Dropdown")
		local options = cfg.Options or cfg.List or {}
		local default = cfg.Default
		local callback = cfg.Callback or function() end

		local open = false
		local current = default
		local rowHeight = 38
		local row = Row(rowHeight)

		Label({
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 12, 0.5, 0),
			Size = UDim2.new(0.5, -12, 0, 16),
			Weight = "Medium",
			Text = title,
			TextSize = 13,
			TextColor3 = Theme.Text,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = row,
		})
		local chosen = Label({
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -34, 0.5, 0),
			Size = UDim2.new(0.5, -40, 0, 16),
			Text = tostring(current or "—"),
			TextSize = 12,
			TextColor3 = Theme.TextSecondary,
			TextXAlignment = Enum.TextXAlignment.Right,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = row,
		})
		local arrow, arrowPaint = Glyph(row, "chevronDown", Theme.TextTertiary, 14)
		arrow.AnchorPoint = Vector2.new(1, 0.5)
		arrow.Position = UDim2.new(1, -12, 0.5, 0)

		local list = New("Frame", {
			Position = UDim2.new(0, 4, 1, 2),
			Size = UDim2.new(1, -8, 0, 0),
			BackgroundColor3 = Theme.Inset,
			ClipsDescendants = true,
			Visible = false,
			LayoutOrder = nextOrder(),
			Parent = page,
		})
		Round(list, 8)
		New("UIStroke", { Color = Theme.Border, Thickness = 1, Transparency = 0.3, Parent = list })
		local scroll = New("ScrollingFrame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			ScrollBarThickness = 2,
			ScrollBarImageColor3 = accents.top,
			CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			Parent = list,
		})
		New("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder, Parent = scroll })
		New("UIPadding", {
			PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4),
			PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4),
			Parent = scroll,
		})

		local obj = { Value = current }

		local function setOpen(state)
			open = state
			list.Visible = true
			local count = math.min(#options, 6)
			local target = state and (count * 28 + 10) or 0
			Tween(arrow, 0.18, { Rotation = state and 180 or 0 })
			arrowPaint(state and accents.top or Theme.TextTertiary, 0.15)
			Tween(list, 0.18, { Size = UDim2.new(1, -8, 0, target) }, Enum.EasingStyle.Quint)
			if not state then
				task.delay(0.18, function()
					if not open then
						list.Visible = false
					end
				end)
			end
		end

		local function rebuild()
			for _, child in ipairs(scroll:GetChildren()) do
				if child:IsA("TextButton") then
					child:Destroy()
				end
			end
			for index, option in ipairs(options) do
				local selected = option == obj.Value
				local entry = New("TextButton", {
					Size = UDim2.new(1, 0, 0, 26),
					LayoutOrder = index,
					BackgroundColor3 = selected and Theme.Hover or Theme.Inset,
					Text = "",
					AutoButtonColor = false,
					Parent = scroll,
				})
				Round(entry, 6)
				Label({
					Position = UDim2.fromOffset(10, 0),
					Size = UDim2.new(1, -30, 1, 0),
					Text = tostring(option),
					TextSize = 12,
					TextColor3 = selected and Theme.Text or Theme.TextSecondary,
					TextYAlignment = Enum.TextYAlignment.Center,
					TextTruncate = Enum.TextTruncate.AtEnd,
					Parent = entry,
				})
				if selected then
					local mark = Glyph(entry, "check", accents.top, 12)
					mark.AnchorPoint = Vector2.new(1, 0.5)
					mark.Position = UDim2.new(1, -8, 0.5, 0)
				end
				entry.MouseEnter:Connect(function()
					if option ~= obj.Value then
						entry.BackgroundColor3 = Theme.Raised
					end
				end)
				entry.MouseLeave:Connect(function()
					entry.BackgroundColor3 = (option == obj.Value) and Theme.Hover or Theme.Inset
				end)
				entry.Activated:Connect(function()
					obj:Set(option)
					setOpen(false)
				end)
			end
		end

		function obj:Set(value, silent)
			obj.Value = value
			current = value
			chosen.Text = tostring(value or "—")
			rebuild()
			if not silent then
				task.spawn(callback, value)
			end
			return value
		end

		function obj:Refresh(newOptions)
			options = newOptions or options
			rebuild()
		end

		Hit(row).Activated:Connect(function()
			setOpen(not open)
		end)

		rebuild()
		if default ~= nil then
			chosen.Text = tostring(default)
		end
		return obj
	end

	function items:AddKeybind(cfg, legacy)
		if type(cfg) == "string" then
			cfg = { Title = cfg, Callback = legacy }
		end
		cfg = cfg or {}
		local title = Opt(cfg, 1, "Title", "Keybind")
		local defaultKey = cfg.Default or cfg.Key
		local callback = cfg.Callback or function() end
		local onChanged = cfg.OnChanged or function() end

		local obj = { Key = defaultKey }
		local row = Row(38)
		Titles(row, title, nil, 96)

		local listening = false
		local pill = New("TextButton", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -12, 0.5, 0),
			Size = UDim2.fromOffset(72, 22),
			BackgroundColor3 = Theme.Inset,
			Text = "",
			AutoButtonColor = false,
			Parent = row,
		})
		Round(pill, 6)
		local pillStroke = New("UIStroke", { Color = Theme.Border, Thickness = 1, Parent = pill })
		local keyLabel = Label({
			Size = UDim2.fromScale(1, 1),
			Weight = "Medium",
			TextSize = 11,
			TextColor3 = Theme.TextSecondary,
			TextXAlignment = Enum.TextXAlignment.Center,
			Parent = pill,
		})

		local function nameOf(key)
			if not key or key == Enum.KeyCode.Unknown then
				return "None"
			end
			return string.gsub(key.Name, "^KeyCode", "")
		end
		local function render()
			keyLabel.Text = listening and "..." or nameOf(obj.Key or Enum.KeyCode.Unknown)
		end

		local connection
		function obj:Set(key, silent)
			obj.Key = key
			render()
			if not silent then
				task.spawn(onChanged, key)
			end
		end

		pill.Activated:Connect(function()
			listening = not listening
			render()
			pillStroke.Color = listening and accents.top or Theme.Border
			if listening then
				connection = UserInputService.InputBegan:Connect(function(input, processed)
					if processed then
						return
					end
					if input.UserInputType == Enum.UserInputType.Keyboard then
						if input.KeyCode == Enum.KeyCode.Backspace then
							obj:Set(Enum.KeyCode.Unknown)
						elseif input.KeyCode ~= Enum.KeyCode.Unknown then
							obj:Set(input.KeyCode)
							task.spawn(callback, input.KeyCode)
						end
						listening = false
						render()
						pillStroke.Color = Theme.Border
						if connection then
							connection:Disconnect()
							connection = nil
						end
					end
				end)
			elseif connection then
				connection:Disconnect()
				connection = nil
			end
		end)

		render()
		return obj
	end

	function items:AddTextbox(cfg, legacy)
		if type(cfg) == "string" then
			cfg = { Title = cfg, Callback = legacy }
		end
		cfg = cfg or {}
		local title = Opt(cfg, 1, "Title", "Textbox")
		local placeholder = cfg.Placeholder or ""
		local default = cfg.Default or ""
		local callback = cfg.Callback or function() end

		local obj = { Value = default }
		local row = Row(38)
		Titles(row, title, nil, 150)

		local box = New("TextBox", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -12, 0.5, 0),
			Size = UDim2.fromOffset(140, 24),
			BackgroundColor3 = Theme.Inset,
			TextColor3 = Theme.Text,
			PlaceholderText = placeholder,
			PlaceholderColor3 = Theme.TextTertiary,
			FontFace = Typo.Regular,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			ClearTextOnFocus = false,
			Text = default,
			Parent = row,
		})
		Round(box, 6)
		local boxStroke = New("UIStroke", { Color = Theme.Border, Thickness = 1, Parent = box })
		New("UIPadding", { PaddingLeft = UDim.new(0, 9), PaddingRight = UDim.new(0, 9), Parent = box })

		box.Focused:Connect(function()
			boxStroke.Color = accents.top
		end)
		box.FocusLost:Connect(function()
			boxStroke.Color = Theme.Border
			obj.Value = box.Text
			task.spawn(callback, box.Text)
		end)

		function obj:Set(text, silent)
			box.Text = tostring(text)
			obj.Value = box.Text
			if not silent then
				task.spawn(callback, obj.Value)
			end
		end
		return obj
	end

	function items:AddColorpicker(cfg, legacy)
		if type(cfg) == "string" then
			cfg = { Title = cfg, Callback = legacy }
		end
		cfg = cfg or {}
		local title = Opt(cfg, 1, "Title", "Color")
		local default = cfg.Default or cfg.Color or accents.top
		local callback = cfg.Callback or function() end

		local obj = { Value = default }
		local row = Row(38)
		Titles(row, title, nil, 44)

		local swatch = New("TextButton", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -12, 0.5, 0),
			Size = UDim2.fromOffset(26, 26),
			BackgroundColor3 = default,
			Text = "",
			AutoButtonColor = false,
			Parent = row,
		})
		Round(swatch, 7)
		New("UIStroke", { Color = Theme.BorderStrong, Thickness = 1, Parent = swatch })

		local panelOpen = false
		local panel = New("Frame", {
			Position = UDim2.new(1, -186, 1, 4),
			Size = UDim2.fromOffset(178, 0),
			BackgroundColor3 = Theme.Inset,
			ClipsDescendants = true,
			Visible = false,
			ZIndex = 8,
			Parent = row,
		})
		Round(panel, 8)
		New("UIStroke", { Color = Theme.Border, Thickness = 1, Parent = panel })

		local sv = New("TextButton", {
			Position = UDim2.fromOffset(10, 10),
			Size = UDim2.fromOffset(118, 100),
			BackgroundColor3 = default,
			Text = "",
			AutoButtonColor = false,
			ZIndex = 9,
			Parent = panel,
		})
		Round(sv, 6)
		local svGradient = New("UIGradient", {
			Color = ColorSequence.new(Color3.new(1, 1, 1), default),
			Parent = sv,
		})
		local svDark = New("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Color3.new(0, 0, 0),
			BackgroundTransparency = 1,
			ZIndex = 10,
			Parent = sv,
		})
		New("UIGradient", {
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(1, 0),
			}),
			Rotation = 90,
			Parent = svDark,
		})
		local svKnob = New("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(1, 0),
			Size = UDim2.fromOffset(10, 10),
			BackgroundColor3 = Color3.new(1, 1, 1),
			ZIndex = 11,
			Parent = sv,
		})
		Round(svKnob, 5)
		New("UIStroke", { Color = Color3.new(0, 0, 0), Transparency = 0.35, Thickness = 1, Parent = svKnob })

		local hue = New("TextButton", {
			Position = UDim2.fromOffset(136, 10),
			Size = UDim2.fromOffset(12, 100),
			BackgroundColor3 = Color3.new(1, 1, 1),
			Text = "",
			AutoButtonColor = false,
			ZIndex = 9,
			Parent = panel,
		})
		Round(hue, 6)
		New("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
				ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
				ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
				ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
				ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
				ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
			}),
			Rotation = 90,
			Parent = hue,
		})
		local hueKnob = New("Frame", {
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromScale(0.5, 0),
			Size = UDim2.fromOffset(16, 4),
			BackgroundColor3 = Color3.new(1, 1, 1),
			ZIndex = 10,
			Parent = hue,
		})
		Round(hueKnob, 2)

		local hexLabel = Label({
			Position = UDim2.fromOffset(10, 118),
			Size = UDim2.fromOffset(118, 18),
			Weight = "Medium",
			TextSize = 11,
			TextColor3 = Theme.TextSecondary,
			TextXAlignment = Enum.TextXAlignment.Center,
			ZIndex = 9,
			Parent = panel,
		})

		local hsv = { h = 0.58, s = 1, v = 0.9 }
		hsv.h, hsv.s, hsv.v = default:ToHSV()

		local function toHex(color)
			return string.format("#%02X%02X%02X", color.R * 255, color.G * 255, color.B * 255)
		end

		local function apply(silent)
			local color = Color3.fromHSV(hsv.h, hsv.s, hsv.v)
			local hueColor = Color3.fromHSV(hsv.h, 1, 1)
			obj.Value = color
			swatch.BackgroundColor3 = color
			sv.BackgroundColor3 = hueColor
			svGradient.Color = ColorSequence.new(Color3.new(1, 1, 1), hueColor)
			hexLabel.Text = toHex(color)
			if not silent then
				task.spawn(callback, color)
			end
		end

		local function dragSV(input)
			local x = math.clamp((input.Position.X - sv.AbsolutePosition.X) / sv.AbsoluteSize.X, 0, 1)
			local y = math.clamp((input.Position.Y - sv.AbsolutePosition.Y) / sv.AbsoluteSize.Y, 0, 1)
			hsv.s, hsv.v = x, 1 - y
			svKnob.Position = UDim2.fromScale(x, y)
			apply()
		end

		local function dragHue(input)
			local y = math.clamp((input.Position.Y - hue.AbsolutePosition.Y) / hue.AbsoluteSize.Y, 0, 1)
			hsv.h = 1 - y
			hueKnob.Position = UDim2.fromScale(0.5, y)
			apply()
		end

		local function bindDrag(button, handler)
			button.InputBegan:Connect(function(input)
				if not IsPointer(input) then
					return
				end
				handler(input)
				page.ScrollingEnabled = false
				local move, ended
				move = UserInputService.InputChanged:Connect(function(changed)
					if IsMove(changed) then
						handler(changed)
					end
				end)
				ended = input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then
						move:Disconnect()
						ended:Disconnect()
						page.ScrollingEnabled = true
					end
				end)
			end)
		end
		bindDrag(sv, dragSV)
		bindDrag(hue, dragHue)

		local function setPanelOpen(state)
			panelOpen = state
			row.ZIndex = state and 3 or 1
			panel.Visible = true
			Tween(panel, 0.16, { Size = UDim2.fromOffset(178, state and 148 or 0) }, Enum.EasingStyle.Quint)
			if not state then
				task.delay(0.16, function()
					if not panelOpen then
						panel.Visible = false
						row.ZIndex = 1
					end
				end)
			end
		end

		swatch.Activated:Connect(function()
			setPanelOpen(not panelOpen)
		end)

		svKnob.Position = UDim2.fromScale(hsv.s, 1 - hsv.v)
		hueKnob.Position = UDim2.fromScale(0.5, 1 - hsv.h)
		apply(true)
		return obj
	end

	function items:AddParagraph(cfg)
		cfg = cfg or {}
		local title = Opt(cfg, 1, "Title", "")
		local content = Opt(cfg, 2, "Content", "")

		local wrap = New("Frame", {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundColor3 = Theme.Inset,
			LayoutOrder = nextOrder(),
			Parent = page,
		})
		Round(wrap, 8)
		New("UIPadding", {
			PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10),
			PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12),
			Parent = wrap,
		})
		local layout = New("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = wrap })
		if title and title ~= "" then
			Label({
				LayoutOrder = 1,
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				Weight = "SemiBold",
				Text = title,
				TextSize = 12,
				TextColor3 = Theme.Text,
				TextWrapped = true,
				Parent = wrap,
			})
		end
		Label({
			LayoutOrder = 2,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Text = content,
			TextSize = 12,
			TextColor3 = Theme.TextSecondary,
			TextWrapped = true,
			Parent = wrap,
		})
		layout.Padding = UDim.new(0, 4)
		return wrap
	end

	return items
end

-- Window -------------------------------------------------------------------

function Library:CreateWindow(cfg)
	cfg = cfg or {}
	local logo = Opt(cfg, 5, "Logo", DEFAULT_LOGO)
	local toggleKey = cfg.ToggleKey or Enum.KeyCode.RightShift
	local discord = cfg.Discord
	if logo == "" then
		logo = DEFAULT_LOGO
	end

	-- Per-window accent: the measured brand gradient, or a tinted variant.
	local accents = { top = Theme.StrokeTop, mid = Theme.StrokeMid, bottom = Theme.StrokeBottom }
	if cfg.Color and typeof(cfg.Color) == "Color3" then
		local deep = Color3.fromRGB(8, 20, 48)
		accents.top = cfg.Color
		accents.mid = cfg.Color:Lerp(deep, 0.35)
		accents.bottom = cfg.Color:Lerp(deep, 0.62)
	end
	accents.fill = accents.top:Lerp(accents.bottom, 0.35)

	local window, connections = {}, {}

	local parent = ResolveParent()
	local previous = parent:FindFirstChild("ZypheraxHub")
	if previous then
		previous:Destroy()
	end

	local gui = New("ScreenGui", {
		Name = "ZypheraxHub",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 100,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = parent,
	})

	local root = New("Frame", {
		Name = "Root",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(WIDTH, TOTAL_H + OVERHANG),
		BackgroundTransparency = 1,
		Parent = gui,
	})
	local uiScale = New("UIScale", { Parent = root })

	-- Main panel with a true transparent notch ----------------------------
	-- The panel is sliced into 2px horizontal rows. Every row pair skirts the
	-- notch circle, so the top edge genuinely curves AROUND the logo and the
	-- cutout stays negative space (the 3D scene shows through). The gradient
	-- outline is a second silhouette, 2px larger, drawn underneath; the fill
	-- silhouette on top leaves a perfect 2px band that follows every curve,
	-- including the recessed arc. No white disc, no filler, no seam.

	local function cornerInset(d, r)
		if d >= r then
			return 0
		end
		return r - math.sqrt(r * r - (r - d) * (r - d))
	end

	local function gradAt(t)
		t = math.clamp(t, 0, 1)
		if t < 0.5 then
			return accents.top:Lerp(accents.mid, t * 2)
		end
		return accents.mid:Lerp(accents.bottom, (t - 0.5) * 2)
	end

	local panel = New("Frame", {
		Name = "Panel",
		Position = UDim2.fromOffset(0, OVERHANG),
		Size = UDim2.fromOffset(WIDTH, CARD_H),
		BackgroundTransparency = 1,
		Parent = root,
	})

	local cx = WIDTH / 2
	local outerH = CARD_H + STROKE * 2
	local R = NOTCH_R
	local EXT = 2 -- hidden overlap so no hairline seams appear at fractional UI scales

	-- Geometry rebuilt from solid pieces only (no 2px row slicing):
	--   * rounded corner blocks (UICorner = real antialiased arcs)
	--   * plain rectangles between them
	--   * the notch: a thick ring clipped to the notch columns. The ring paints
	--     only the area OUTSIDE the notch circle, so the inside stays transparent.
	-- The outline is the same silhouette grown by STROKE, drawn underneath.

	local function fillAt(y)
		return Theme.Surface:Lerp(Theme.SurfaceDeep, math.clamp(y / CARD_H, 0, 1))
	end

	local function outlineAt(y)
		return gradAt((y + STROKE) / outerH)
	end

	local function seq(top, bottom, colorAt, kink)
		local keys = { ColorSequenceKeypoint.new(0, colorAt(top)) }
		if kink and kink > top and kink < bottom then
			keys[#keys + 1] = ColorSequenceKeypoint.new((kink - top) / (bottom - top), colorAt(kink))
		end
		keys[#keys + 1] = ColorSequenceKeypoint.new(1, colorAt(bottom))
		return ColorSequence.new(keys)
	end

	local function block(name, x, y, w, h, z, colorAt, kink, radius)
		local piece = New("Frame", {
			Name = name,
			Position = UDim2.fromOffset(x, y),
			Size = UDim2.fromOffset(w, h),
			BackgroundColor3 = Color3.new(1, 1, 1),
			ZIndex = z,
			Parent = panel,
		})
		New("UIGradient", { Color = seq(y, y + h, colorAt, kink), Rotation = 90, Parent = piece })
		if radius then
			Round(piece, radius)
		end
		return piece
	end

	-- band [r0, r0 + thick) around the point (cx, 0), clipped to rows y0..y1
	-- of the notch columns
	local function notchBand(name, y0, y1, r0, thick, color, z)
		local clip = New("Frame", {
			Name = name .. "Clip",
			Position = UDim2.fromOffset(cx - R - EXT, y0),
			Size = UDim2.fromOffset(R * 2 + EXT * 2, y1 - y0),
			BackgroundTransparency = 1,
			ClipsDescendants = true,
			ZIndex = z,
			Parent = panel,
		})
		local ring = New("Frame", {
			Name = name,
			Position = UDim2.fromOffset(R + EXT - r0, -y0 - r0),
			Size = UDim2.fromOffset(r0 * 2, r0 * 2),
			BackgroundTransparency = 1,
			ZIndex = z,
			Parent = clip,
		})
		Round(ring, r0)
		New("UIStroke", {
			Color = color,
			Thickness = thick,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Parent = ring,
		})
	end

	local kinkY = CARD_H / 2
	local oR = R_CARD + STROKE

	-- outline silhouette (z = 1)
	block("OutLeftRound", -STROKE, -STROKE, oR * 2, outerH, 1, outlineAt, kinkY, oR)
	block("OutRightRound", WIDTH + STROKE - oR * 2, -STROKE, oR * 2, outerH, 1, outlineAt, kinkY, oR)
	block("OutLeft", R_CARD, -STROKE, cx - R - R_CARD, outerH, 1, outlineAt, kinkY)
	block("OutRight", cx + R, -STROKE, WIDTH - R_CARD - (cx + R), outerH, 1, outlineAt, kinkY)
	block("OutMid", cx - R - EXT, R, R * 2 + EXT * 2, CARD_H + STROKE - R, 1, outlineAt, kinkY)

	-- notch outline: ring band starting at NOTCH_R - STROKE, in three tone steps
	local holeR = R - STROKE
	notchBand("NotchOutA", -STROKE, 23, holeR, 80, outlineAt(10), 1)
	notchBand("NotchOutB", 22, 48, holeR, 80, outlineAt(35), 1)
	notchBand("NotchOutC", 47, R + 1, holeR, 80, outlineAt(60), 1)

	-- fill silhouette (z = 2)
	block("FillLeftRound", 0, 0, R_CARD * 2, CARD_H, 2, fillAt, nil, R_CARD)
	block("FillRightRound", WIDTH - R_CARD * 2, 0, R_CARD * 2, CARD_H, 2, fillAt, nil, R_CARD)
	block("FillLeft", R_CARD, 0, cx - R - R_CARD, CARD_H, 2, fillAt)
	block("FillRight", cx + R, 0, WIDTH - R_CARD - (cx + R), CARD_H, 2, fillAt)
	block("FillMid", cx - R - EXT, R, R * 2 + EXT * 2, CARD_H - R, 2, fillAt)

	-- notch fill: surface colour OUTSIDE the circle only; the circle stays transparent
	notchBand("NotchFill", 0, R + 1, R, 80, fillAt(R / 3), 2)

	-- invisible drag surface over the panel (content sits above it)
	local dragFrame = New("Frame", {
		Name = "Drag",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ZIndex = 3,
		Parent = panel,
	})

	-- Header badges: brushed-steel plates flanking the logo notch -----------------

	local BADGE_W, BADGE_H, BADGE_Y, BADGE_EDGE = 116, 24, 15, 14

	local function SteelBadge(name, x, text, withCrown)
		local plate = New("Frame", {
			Name = name,
			Position = UDim2.fromOffset(x, BADGE_Y),
			Size = UDim2.fromOffset(BADGE_W, BADGE_H),
			BackgroundColor3 = Color3.new(1, 1, 1),
			ZIndex = 5,
			Parent = panel,
		})
		Round(plate, 5)
		New("UIGradient", {
			Color = ColorSequence.new(Theme.SteelTop, Theme.SteelBottom),
			Rotation = 90,
			Parent = plate,
		})

		-- Polished edge: bright top lip falling to a dark lower edge.
		local edge = New("UIStroke", {
			Color = Color3.new(1, 1, 1),
			Thickness = 1,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Parent = plate,
		})
		New("UIGradient", {
			Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(82, 90, 108)),
			Rotation = 90,
			Parent = edge,
		})

		-- Brushed grain: fine horizontal streaks at uneven spacing, inset so
		-- they never poke past the rounded corners.
		local grain = { 3, 6, 9, 11, 14, 17, 20, 22 }
		for i, y in ipairs(grain) do
			local light = i % 2 == 0
			New("Frame", {
				Position = UDim2.fromOffset(5, y),
				Size = UDim2.new(1, -10, 0, 1),
				BackgroundColor3 = light and Color3.new(1, 1, 1) or Color3.new(0, 0, 0),
				BackgroundTransparency = light and 0.7 or 0.93,
				ZIndex = 6,
				Parent = plate,
			})
		end

		local row = New("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			ZIndex = 7,
			Parent = plate,
		})
		New("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 5),
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = row,
		})
		if withCrown then
			local crown = Glyph(row, "crown", Theme.SteelInk, 12)
			crown.LayoutOrder = 1
		end
		Label({
			LayoutOrder = 2,
			Size = UDim2.new(0, 0, 1, 0),
			AutomaticSize = Enum.AutomaticSize.X,
			Weight = "SemiBold",
			Text = text,
			TextSize = 9,
			TextColor3 = Theme.SteelInk,
			TextXAlignment = Enum.TextXAlignment.Center,
			ZIndex = 8,
			Parent = row,
		})
		return plate
	end

	if cfg.ShowBadges ~= false then
		SteelBadge("HubBadge", BADGE_EDGE, cfg.LeftBadge or "Z-EXECUTOR HUB", false)
		SteelBadge("EditionBadge", WIDTH - BADGE_EDGE - BADGE_W, cfg.RightBadge or "PREMIUM EDITION", true)
	end

	-- Content area ----------------------------------------------------------

	local content = New("Frame", {
		Name = "Content",
		Position = UDim2.fromOffset(CONTENT_X, CONTENT_TOP),
		Size = UDim2.new(1, -CONTENT_X * 2, 1, -(CONTENT_TOP + CONTENT_BOTTOM)),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		ZIndex = 4,
		Parent = panel,
	})

	-- Logo disc, centred exactly on the panel's top edge -------------------
	-- Gradient-outlined charcoal disc. The recessed panel edge keeps a
	-- consistent transparent gap (NOTCH_GAP) around it.

	local badgeShell = New("Frame", {
		Name = "Badge",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0, OVERHANG),
		Size = UDim2.fromOffset(BADGE_D, BADGE_D),
		BackgroundColor3 = accents.top,
		ZIndex = 6,
		Parent = root,
	})
	Round(badgeShell, BADGE_D / 2)
	New("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, accents.top),
			ColorSequenceKeypoint.new(0.5, accents.mid),
			ColorSequenceKeypoint.new(1, accents.bottom),
		}),
		Rotation = 90,
		Parent = badgeShell,
	})

	local badgeCore = New("Frame", {
		Name = "Core",
		Position = UDim2.fromOffset(STROKE, STROKE),
		Size = UDim2.new(1, -STROKE * 2, 1, -STROKE * 2),
		BackgroundColor3 = Theme.Surface,
		ZIndex = 7,
		Parent = badgeShell,
	})
	Round(badgeCore, BADGE_D / 2 - STROKE)

	-- Logo image. Default fills the whole core: the uploaded asset ships with
	-- its own navy disc, and filling the core hides the disc seam so the badge
	-- reads as one curved medallion. Pass cfg.LogoSize (px) if your logo is a
	-- transparent glyph instead.
	local logoSize = cfg.LogoSize or 0
	New("ImageLabel", {
		Name = "Logo",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = logoSize > 0 and UDim2.fromOffset(logoSize, logoSize) or UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Image = logo,
		ScaleType = Enum.ScaleType.Fit,
		ZIndex = 8,
		Parent = badgeCore,
	})

	-- Pulsing sapphire halo, just outside the medallion and inside the notch gap
	local HALO_D = BADGE_D + 6
	local halo = New("Frame", {
		Name = "Halo",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0, OVERHANG),
		Size = UDim2.fromOffset(HALO_D, HALO_D),
		BackgroundTransparency = 1,
		ZIndex = 5,
		Parent = root,
	})
	Round(halo, HALO_D / 2)
	local haloStroke = New("UIStroke", {
		Color = accents.top,
		Thickness = 1.5,
		Transparency = 0.25,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = halo,
	})
	local haloTween = TweenService:Create(
		haloStroke,
		TweenInfo.new(1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{ Transparency = 0.85, Thickness = 3.5 }
	)
	haloTween:Play()

	-- Status bar -------------------------------------------------------------

	local barY = OVERHANG + CARD_H + GAP
	GradientShell(root, "Bar", UDim2.fromOffset(0, barY), UDim2.fromOffset(WIDTH, BAR_H), BAR_H / 2, accents, 1)
	local bar = Fill(root.BarShell, "Bar", BAR_H / 2, Color3.new(1, 1, 1), 2)
	New("UIGradient", { Color = ColorSequence.new(Theme.Surface, Theme.SurfaceDeep), Rotation = 90, Parent = bar })

	-- Avatar medallion: gradient stroke → white ring → headshot
	local avatarShell = New("Frame", {
		Name = "Avatar",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, AVATAR_MARGIN, 0.5, 0),
		Size = UDim2.fromOffset(AVATAR, AVATAR),
		BackgroundColor3 = Color3.new(1, 1, 1),
		ZIndex = 3,
		Parent = bar,
	})
	Round(avatarShell, AVATAR / 2)
	New("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, accents.top),
			ColorSequenceKeypoint.new(0.5, accents.mid),
			ColorSequenceKeypoint.new(1, accents.bottom),
		}),
		Rotation = 90,
		Parent = avatarShell,
	})
	local avatarRing = New("Frame", {
		Name = "Ring",
		Position = UDim2.fromOffset(STROKE, STROKE),
		Size = UDim2.new(1, -STROKE * 2, 1, -STROKE * 2),
		BackgroundColor3 = Theme.White,
		ClipsDescendants = true,
		ZIndex = 4,
		Parent = avatarShell,
	})
	Round(avatarRing, (AVATAR - STROKE * 2) / 2)
	local avatar = New("ImageLabel", {
		Name = "Head",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(AVATAR_IMG, AVATAR_IMG),
		BackgroundTransparency = 1,
		Image = "",
		ScaleType = Enum.ScaleType.Fit,
		ZIndex = 5,
		Parent = avatarRing,
	})

	task.spawn(function()
		local ok, image = pcall(function()
			return Players:GetUserThumbnailAsync(
				LocalPlayer.UserId,
				Enum.ThumbnailType.HeadShot,
				Enum.ThumbnailSize.Size420x420
			)
		end)
		if ok and image then
			avatar.Image = image
		end
	end)

	-- Identity block: heading, then label / value rows on one shared grid
	local info = New("Frame", {
		Name = "Info",
		Position = UDim2.fromOffset(INFO_X, 0),
		Size = UDim2.new(1, -(INFO_X + (discord and (DISCORD_W + DISCORD_MARGIN + 12) or CONTENT_X)), 1, 0),
		BackgroundTransparency = 1,
		ZIndex = 3,
		Parent = bar,
	})
	New("UIListLayout", {
		Padding = UDim.new(0, INFO_GAP),
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Parent = info,
	})

	local statusTitle = Label({
		LayoutOrder = 1,
		Size = UDim2.new(1, 0, 0, INFO_BOX + 1),
		Weight = "Bold",
		Text = "USER STATUS",
		TextSize = INFO_TITLE,
		TextColor3 = Theme.Text,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = info,
	})
	New("Frame", {
		Name = "Spacer",
		LayoutOrder = 2,
		Size = UDim2.new(1, 0, 0, 2),
		BackgroundTransparency = 1,
		Parent = info,
	})

	local function InfoRow(order, name, value)
		local row = New("Frame", {
			Name = name,
			LayoutOrder = order,
			Size = UDim2.new(1, 0, 0, INFO_BOX),
			BackgroundTransparency = 1,
			Parent = info,
		})
		Label({
			Size = UDim2.new(0, INFO_LABEL_W, 1, 0),
			Weight = "Medium",
			Text = name .. ":",
			TextSize = INFO_SIZE,
			TextColor3 = Theme.TextTertiary,
			Parent = row,
		})
		return Label({
			Position = UDim2.fromOffset(INFO_LABEL_W, 0),
			Size = UDim2.new(1, -INFO_LABEL_W, 1, 0),
			Text = tostring(value),
			TextSize = INFO_SIZE,
			TextColor3 = Theme.Text,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = row,
		})
	end

	local statusName = InfoRow(3, "Username", cfg.Username or LocalPlayer.Name)
	local statusId = InfoRow(4, "ID", cfg.UserId or LocalPlayer.UserId)
	local statusLine = InfoRow(5, "Status", cfg.Status or "No-Key Script")

	-- Discord pill ------------------------------------------------------------
	-- The gradient lives on a child frame, never on the TextButton itself: a
	-- UIGradient on a text object also tints the text, which is what turned the
	-- white label sapphire-on-sapphire. Drop an asset id into Library.Icons.discord
	-- to get the white logo mark beside the label.

	if discord then
		local button = New("TextButton", {
			Name = "Discord",
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -DISCORD_MARGIN, 0.5, 0),
			Size = UDim2.fromOffset(DISCORD_W, DISCORD_H),
			BackgroundTransparency = 1,
			AutoButtonColor = false,
			Text = "",
			ZIndex = 3,
			Parent = bar,
		})
		local pill = New("Frame", {
			Name = "Pill",
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Color3.fromRGB(240, 240, 240),
			ZIndex = 3,
			Parent = button,
		})
		Round(pill, DISCORD_H / 2)
		New("UIGradient", {
			Color = ColorSequence.new(Theme.Discord, Theme.DiscordEdge),
			Rotation = 90,
			Parent = pill,
		})
		New("UIStroke", {
			Color = Theme.DiscordOutline,
			Thickness = 1,
			Transparency = 0.45,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Parent = pill,
		})
		local gloss = New("Frame", {
			Name = "Gloss",
			Position = UDim2.fromOffset(8, 3),
			Size = UDim2.new(1, -16, 0.45, -3),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BackgroundTransparency = 0.88,
			ZIndex = 4,
			Parent = pill,
		})
		Round(gloss, 8)

		local iconAsset = Library.Icons.discord
		local hasIcon = iconAsset ~= nil and iconAsset ~= ""
		if hasIcon then
			New("ImageLabel", {
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 16, 0.5, 0),
				Size = UDim2.fromOffset(18, 18),
				BackgroundTransparency = 1,
				Image = iconAsset,
				ImageColor3 = Color3.new(1, 1, 1),
				ScaleType = Enum.ScaleType.Fit,
				ZIndex = 5,
				Parent = button,
			})
		end
		Label({
			Position = UDim2.fromOffset(hasIcon and 34 or 0, 0),
			Size = UDim2.new(1, hasIcon and -42 or 0, 1, 0),
			Weight = "SemiBold",
			Text = "Discord",
			TextSize = 13,
			TextColor3 = Theme.DiscordText,
			TextXAlignment = Enum.TextXAlignment.Center,
			ZIndex = 5,
			Parent = button,
		})

		button.MouseEnter:Connect(function()
			Tween(pill, 0.12, { BackgroundColor3 = Color3.new(1, 1, 1) })
		end)
		button.MouseLeave:Connect(function()
			Tween(pill, 0.12, { BackgroundColor3 = Color3.fromRGB(240, 240, 240) })
		end)
		button.MouseButton1Down:Connect(function()
			Tween(button, 0.06, { Size = UDim2.fromOffset(DISCORD_W - 3, DISCORD_H - 3) })
		end)
		button.MouseButton1Up:Connect(function()
			Tween(button, 0.12, { Size = UDim2.fromOffset(DISCORD_W, DISCORD_H) }, Enum.EasingStyle.Quint)
		end)
		button.Activated:Connect(function()
			if typeof(setclipboard) == "function" then
				pcall(setclipboard, discord)
				Library:Notify({ Title = "Discord", Content = "Invite link copied to clipboard.", Color = accents.fill })
			else
				Library:Notify({ Title = "Discord", Content = discord, Color = accents.fill })
			end
			if typeof(request) == "function" and cfg.OpenDiscord then
				pcall(request, { Url = discord, Method = "GET" })
			end
		end)
	end

	-- Dragging -----------------------------------------------------------------

	MakeDraggable(dragFrame, root, uiScale)
	MakeDraggable(bar, root, uiScale)
	MakeDraggable(badgeShell, root, uiScale)

	-- Launcher ------------------------------------------------------------------

	local launcher = New("ImageButton", {
		Name = "Launcher",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 18, 0.5, 0),
		Size = UDim2.fromOffset(56, 56),
		BackgroundColor3 = Theme.White,
		AutoButtonColor = false,
		Image = "",
		Visible = false,
		Parent = gui,
	})
	Round(launcher, 28)
	local launcherRing = New("Frame", {
		Position = UDim2.fromOffset(4, 4),
		Size = UDim2.new(1, -8, 1, -8),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = launcher,
	})
	Round(launcherRing, 24)
	New("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, accents.top),
			ColorSequenceKeypoint.new(0.5, accents.mid),
			ColorSequenceKeypoint.new(1, accents.bottom),
		}),
		Rotation = 90,
		Parent = launcherRing,
	})
	local launcherCore = New("Frame", {
		Position = UDim2.fromOffset(2, 2),
		Size = UDim2.new(1, -4, 1, -4),
		BackgroundColor3 = Theme.Surface,
		Parent = launcherRing,
	})
	Round(launcherCore, 22)
	New("ImageLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Image = logo,
		ScaleType = Enum.ScaleType.Fit,
		Parent = launcherCore,
	})
	local launcherScale = New("UIScale", { Parent = launcher })
	local launcherDrag = MakeDraggable(launcher, launcher)

	launcher.MouseEnter:Connect(function()
		Tween(launcherScale, 0.14, { Scale = 1.06 }, Enum.EasingStyle.Quint)
	end)
	launcher.MouseLeave:Connect(function()
		Tween(launcherScale, 0.14, { Scale = 1 }, Enum.EasingStyle.Quint)
	end)

	-- Visibility and scaling -------------------------------------------------------

	local baseScale, visible = ViewportScale(), false

	function window:SetVisible(show)
		if visible == show then
			return
		end
		visible = show
		launcher.Visible = not show
		root.Visible = show
		if show then
			uiScale.Scale = baseScale * 0.94
			Tween(uiScale, 0.24, { Scale = baseScale }, Enum.EasingStyle.Quint)
		end
	end

	function window:Toggle()
		window:SetVisible(not visible)
	end

	function window:Destroy()
		pcall(function()
			haloTween:Cancel()
		end)
		for _, connection in ipairs(connections) do
			connection:Disconnect()
		end
		gui:Destroy()
		Library.Unloaded = true
	end

	function window:SetStatus(statusCfg)
		statusCfg = statusCfg or {}
		if statusCfg.Username then
			statusName.Text = tostring(statusCfg.Username)
		end
		if statusCfg.UserId then
			statusId.Text = tostring(statusCfg.UserId)
		end
		if statusCfg.Status then
			statusLine.Text = tostring(statusCfg.Status)
		end
		if statusCfg.Title then
			statusTitle.Text = tostring(statusCfg.Title)
		end
	end

	launcher.Activated:Connect(function()
		if not launcherDrag.Moved then
			window:SetVisible(true)
		end
	end)

	table.insert(connections, Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
		baseScale = ViewportScale()
		if visible then
			uiScale.Scale = baseScale
		end
	end))
	table.insert(connections, UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == toggleKey then
			window:Toggle()
		end
	end))

	-- Tabs ------------------------------------------------------------------------

	local tabs = {}
	local selectedTab
	local tabStrip, tabThumb, tabButtons, pagesHolder

	local STRIP_W = WIDTH - CONTENT_X * 2
	local STRIP_PAD, STRIP_GAP = 3, 3

	-- The thumb is placed from the known button widths, not from AbsolutePosition:
	-- absolute values are screen pixels (they drift under UIScale) and are stale
	-- until the layout has run, which left the highlight on the wrong tab.
	local function layoutThumb(animate)
		if not (tabThumb and selectedTab and selectedTab.Width) then
			return
		end
		local total, offset = 0, nil
		for _, tab in ipairs(tabs) do
			if tab.Width then
				if tab == selectedTab then
					offset = total
				end
				total += tab.Width + STRIP_GAP
			end
		end
		total -= STRIP_GAP
		if not offset then
			return
		end
		local x = STRIP_PAD + ((STRIP_W - STRIP_PAD * 2) - total) / 2 + offset
		local goalPosition = UDim2.fromOffset(x, 3)
		local goalSize = UDim2.new(0, selectedTab.Width, 1, -6)
		tabThumb.Visible = true
		if animate then
			Tween(tabThumb, 0.22, { Position = goalPosition, Size = goalSize }, Enum.EasingStyle.Quint)
		else
			tabThumb.Position = goalPosition
			tabThumb.Size = goalSize
		end
	end

	local function selectTab(selected, animate)
		selectedTab = selected
		for _, tab in ipairs(tabs) do
			local active = tab == selected
			tab.Active = active
			tab.Page.Visible = active
			if active then
				tab.Page.CanvasPosition = Vector2.new(0, 0)
			end
			if tab.ButtonLabel then
				Tween(tab.ButtonLabel, 0.15, {
					TextColor3 = active and Color3.new(1, 1, 1) or Theme.TextTertiary,
				})
			end
		end
		layoutThumb(animate)
	end

	local function buildTabStrip()
		tabStrip = New("Frame", {
			Name = "TabStrip",
			Size = UDim2.new(1, 0, 0, 30),
			BackgroundColor3 = Theme.Inset,
			LayoutOrder = 0,
			Parent = content,
		})
		Round(tabStrip, 8)
		New("UIStroke", {
			Color = Theme.Border,
			Thickness = 1,
			Transparency = 0.2,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Parent = tabStrip,
		})
		tabThumb = New("Frame", {
			Name = "Thumb",
			Position = UDim2.fromOffset(STRIP_PAD, 3),
			Size = UDim2.new(0, 0, 1, -6),
			BackgroundColor3 = Color3.new(1, 1, 1),
			Visible = false,
			ZIndex = 2,
			Parent = tabStrip,
		})
		Round(tabThumb, 6)
		-- Deep enough sapphire that the white label keeps >4:1 contrast.
		New("UIGradient", {
			Color = ColorSequence.new(
				accents.mid:Lerp(accents.top, 0.25),
				accents.bottom:Lerp(accents.mid, 0.4)
			),
			Rotation = 0,
			Parent = tabThumb,
		})
		New("UIStroke", {
			Color = accents.top,
			Thickness = 1,
			Transparency = 0.5,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Parent = tabThumb,
		})
		-- Buttons live in their own holder so the layout never touches the thumb
		-- (a UIListLayout on the strip itself would also position the thumb).
		tabButtons = New("Frame", {
			Name = "Buttons",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			ZIndex = 3,
			Parent = tabStrip,
		})
		New("UIListLayout", {
			Padding = UDim.new(0, STRIP_GAP),
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = tabButtons,
		})
		New("UIPadding", {
			PaddingLeft = UDim.new(0, STRIP_PAD), PaddingRight = UDim.new(0, STRIP_PAD),
			Parent = tabButtons,
		})

		pagesHolder = New("Frame", {
			Name = "Pages",
			Position = UDim2.fromOffset(0, 38),
			Size = UDim2.new(1, 0, 1, -38),
			BackgroundTransparency = 1,
			LayoutOrder = 1,
			Parent = content,
		})
	end

	local function makeTabButton(tab)
		tab.Width = math.max(62, math.floor(string.len(tab.Name) * 7.4 + 26))
		local button = New("TextButton", {
			Size = UDim2.new(0, tab.Width, 1, -6),
			LayoutOrder = tab.Order,
			BackgroundTransparency = 1,
			Text = "",
			AutoButtonColor = false,
			ZIndex = 3,
			Parent = tabButtons,
		})
		local buttonLabel = Label({
			Size = UDim2.fromScale(1, 1),
			Weight = "SemiBold",
			Text = tab.Name,
			TextSize = 12,
			TextColor3 = tab.Active and Color3.new(1, 1, 1) or Theme.TextTertiary,
			TextXAlignment = Enum.TextXAlignment.Center,
			Parent = button,
		})
		tab.Button = button
		tab.ButtonLabel = buttonLabel
		button.MouseEnter:Connect(function()
			if not tab.Active then
				Tween(buttonLabel, 0.1, { TextColor3 = Theme.TextSecondary })
			end
		end)
		button.MouseLeave:Connect(function()
			if not tab.Active then
				Tween(buttonLabel, 0.1, { TextColor3 = Theme.TextTertiary })
			end
		end)
		button.Activated:Connect(function()
			selectTab(tab, true)
		end)
	end

	-- The first tab is selected by default; pass Default = true on another tab to override.
	function window:AddTab(tabCfg)
		local name, default
		if type(tabCfg) == "table" then
			name = Opt(tabCfg, 1, "Name", "Tab")
			default = tabCfg.Default
		else
			name = tostring(tabCfg or "Tab")
		end

		if not tabStrip and #tabs >= 1 then
			-- A second tab appears: promote the existing page under a tab strip
			-- and give the first tab its button too.
			buildTabStrip()
			for _, existing in ipairs(tabs) do
				existing.Page.Parent = pagesHolder
				makeTabButton(existing)
			end
		end
		local holder = tabStrip and pagesHolder or content

		local page = New("ScrollingFrame", {
			Name = name,
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			ScrollBarThickness = 2,
			ScrollBarImageColor3 = accents.top,
			ElasticBehavior = Enum.ElasticBehavior.Never,
			Visible = false,
			Parent = holder,
		})
		New("UIListLayout", { Padding = UDim.new(0, 7), SortOrder = Enum.SortOrder.LayoutOrder, Parent = page })
		New("UIPadding", { PaddingRight = UDim.new(0, 6), Parent = page })

		local tab = { Page = page, Active = false, Name = name, Order = #tabs + 1 }
		table.insert(tabs, tab)

		if tabStrip then
			makeTabButton(tab)
		end

		if #tabs == 1 or default then
			selectTab(tab, false)
		else
			layoutThumb(false) -- the strip is centred, so adding a tab shifts the selected one
		end

		return BuildItems(page, accents)
	end
	window.CreateTab = window.AddTab

	window:SetVisible(true)
	table.insert(Library.Windows, window)
	window.Gui = gui
	return window
end

function Library:Unload()
	for _, window in ipairs(Library.Windows) do
		pcall(function()
			window:Destroy()
		end)
	end
	table.clear(Library.Windows)
	if notifyGui then
		notifyGui:Destroy()
		notifyGui = nil
	end
	Library.Unloaded = true
end

return Library
