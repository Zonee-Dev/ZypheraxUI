--════════════════════════════════════════════════════════════════════════════
-- ZYPHERAX UI LIBRARY • v4 (final fix)
-- FIX v4: New() memakai guard inst:IsA("GuiObject") sebelum set BorderSizePixel.
--         (Membaca BorderSizePixel pada ScreenGui/non-GuiObject = error runtime.)
-- FIX v3: Panel notch & sudut = primitive antialiased (slice hanya sumbu-sejajar).
--         Semua gradient stroke di-parent ke UIStroke (bukan Frame).
--         ZIndexBehavior hanya di ScreenGui. Lens glow dihapus.
-- Pemakaian: lihat execute/test script (CreateWindow → AddTab → AddXxx).
--════════════════════════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

local DEFAULT_LOGO = "rbxassetid://106764279090045"

-- Measured tokens ----------------------------------------------------------

local Theme = {
	StrokeTop = Color3.fromRGB(88, 166, 255),
	StrokeMid = Color3.fromRGB(35, 136, 255),
	StrokeBottom = Color3.fromRGB(27, 79, 216),

	Surface = Color3.fromRGB(41, 41, 46),
	SurfaceDeep = Color3.fromRGB(36, 36, 41),
	Raised = Color3.fromRGB(49, 49, 55),
	Hover = Color3.fromRGB(57, 57, 64),
	Pressed = Color3.fromRGB(44, 44, 50),
	Inset = Color3.fromRGB(34, 34, 39),
	Track = Color3.fromRGB(64, 64, 71),

	Border = Color3.fromRGB(58, 57, 65),
	BorderStrong = Color3.fromRGB(72, 71, 80),

	Text = Color3.fromRGB(250, 250, 250),
	TextSecondary = Color3.fromRGB(199, 199, 202),
	TextTertiary = Color3.fromRGB(140, 140, 145),

	Accent = Color3.fromRGB(64, 134, 214),
	White = Color3.fromRGB(245, 245, 245),
	Discord = Color3.fromRGB(87, 107, 230),
	DiscordEdge = Color3.fromRGB(80, 98, 209),
	DiscordOutline = Color3.fromRGB(48, 49, 65),
	DiscordText = Color3.fromRGB(208, 219, 242),
	Success = Color3.fromRGB(80, 178, 128),
	Danger = Color3.fromRGB(224, 92, 92),
}

-- Geometry ------------------------------------------------------------------

local WIDTH = 420
local CARD_H = 301
local GAP = 14
local BAR_H = 74
local TOTAL_H = CARD_H + GAP + BAR_H

local R_CARD = 29
local STROKE = 2
local ROW = 2

local BADGE_D = 124
local NOTCH_R = 72
local OVERHANG = BADGE_D / 2

local AVATAR = 54
local AVATAR_IMG = 38
local AVATAR_MARGIN = 10

local INFO_X = 80
local INFO_BOX = 14
local INFO_GAP = 2
local INFO_TITLE = 13
local INFO_SIZE = 12

local DISCORD_W = 110
local DISCORD_H = 38
local DISCORD_MARGIN = 12

local CONTENT_X = 16
local CONTENT_TOP = NOTCH_R + 12
local CONTENT_BOTTOM = 16

local Library = {
	Unloaded = false,
	Windows = {},
	Icons = { chevron = "", close = "", minimize = "", discord = "", check = "" },
}

-- Small utilities -----------------------------------------------------------

local function New(class, props)
	local inst = Instance.new(class)
	local parent = props.Parent
	props.Parent = nil
	for key, value in pairs(props) do
		inst[key] = value
	end
	-- BorderSizePixel HANYA valid di GuiObject. ScreenGui (LayerCollector) serta
	-- UIScale/UICorner/UIStroke/UIGradient/UIListLayout/UIPadding tidak memilikinya.
	-- Guard pakai IsA — JANGAN membaca propertinya langsung (error runtime).
	if inst:IsA("GuiObject") then
		inst.BorderSizePixel = 0
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

local FONT_FAMILY = "rbxasset://fonts/families/Inter.json"
local FALLBACK_FAMILY = "rbxasset://fonts/families/SourceSansPro.json"

local function MakeFont(weight)
	local ok, font = pcall(function()
		return Font.new(FONT_FAMILY, weight)
	end)
	if ok and font then
		return font
	end
	local ok2, backup = pcall(function()
		return Font.new(FALLBACK_FAMILY, weight)
	end)
	return ok2 and backup or Font.new(FONT_FAMILY, weight)
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

-- Drawn glyphs ---------------------------------------------------------------

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

-- Dragging --------------------------------------------------------------------

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

-- Notifications ---------------------------------------------------------------

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
	local accent = cfg.Color or Theme.Accent

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

	local stripe = New("Frame", {
		Name = "Stripe",
		Position = UDim2.fromOffset(0, 6),
		Size = UDim2.new(0, 3, 1, -12),
		BackgroundColor3 = accent,
		Parent = toast,
	})
	Round(stripe, 2)

	local body = New("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Parent = toast,
	})
	New("UIPadding", {
		PaddingTop = UDim.new(0, 11), PaddingBottom = UDim.new(0, 11),
		PaddingLeft = UDim.new(0, 15), PaddingRight = UDim.new(0, 30),
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

-- Row controls ----------------------------------------------------------------

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
		local row = Row(38)

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
			Text = tostring(default or "—"),
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

		local obj = { Value = default }

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

		local obj = {
