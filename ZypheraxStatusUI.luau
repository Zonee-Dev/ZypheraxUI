--[[
	ZYPHERAX UI — reconstruction 1:1 dari mock.
	Spec terukur (mock 357px wide -> design 420px, factor 1.176):
	  card 420x282 R28 | gap 7 | bar 64 pill | logo O122 ring10 inner102 stroke2 glyph56
	  avatar 48 ring2 | discord 100x30 pill | stroke brand 2px | flat, no shadow.
	Semua metric hidup di satu tabel Metrics. Jangan hardcode angka di body.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

local DEFAULT_LOGO = "rbxassetid://106764279090045"

-- Design tokens ----------------------------------------------------------

local Theme = {
	-- Brand
	Accent = Color3.fromRGB(47, 109, 242),

	-- Surfaces (cool graphite, diambil dari sample mock)
	Canvas = Color3.fromRGB(13, 14, 18),
	Inset = Color3.fromRGB(30, 32, 38),
	Surface = Color3.fromRGB(40, 42, 48),   -- fill card & bar di mock
	Raised = Color3.fromRGB(48, 50, 58),
	Hover = Color3.fromRGB(56, 58, 67),
	Pressed = Color3.fromRGB(44, 46, 53),
	Track = Color3.fromRGB(66, 70, 80),

	-- Lines
	Border = Color3.fromRGB(58, 61, 70),
	BorderStrong = Color3.fromRGB(74, 78, 90),

	-- Text hierarchy
	Text = Color3.fromRGB(237, 239, 243),
	TextSecondary = Color3.fromRGB(176, 181, 192),
	TextTertiary = Color3.fromRGB(128, 133, 146),

	-- Status bar (mock: putih & putih terang, hierarki lewat weight)
	BarTitle = Color3.fromRGB(248, 249, 251),
	BarLine = Color3.fromRGB(222, 225, 230),

	-- Logo
	LogoRing = Color3.fromRGB(250, 250, 252),
	LogoWell = Color3.fromRGB(16, 24, 42),

	-- Semantic
	Discord = Color3.fromRGB(88, 101, 242),
	DiscordHover = Color3.fromRGB(105, 117, 246),
	Success = Color3.fromRGB(63, 185, 125),
	Danger = Color3.fromRGB(229, 83, 83),
}

local Radius = { XS = 4, SM = 6, MD = 10, LG = 28, Pill = 32 }

-- Metrics: satu-satunya sumber kebenaran untuk geometri
local Metrics = {
	Width = 420,
	CardH = 282,
	Gap = 7,
	BarH = 64,

	CardRadius = Radius.LG,
	BarRadius = Radius.Pill,

	LogoOuter = 122,
	LogoRing = 10,
	LogoStroke = 2,
	LogoGlyph = 56,

	ContentPadX = 16,
	ContentTop = 70,   -- setengah logo (61) + napas 9
	ContentBottom = 14,

	BarPad = 14,
	Avatar = 48,
	AvatarRing = 2,

	DiscordW = 100,
	DiscordH = 30,

	ChipH = 26,
	ChipRowH = 34,
}
Metrics.Inner = Metrics.LogoOuter - Metrics.LogoRing * 2
Metrics.TotalH = Metrics.CardH + Metrics.Gap + Metrics.BarH

local FONT_FAMILY = "rbxasset://fonts/families/Inter.json"
local Typo = {
	Regular = Font.new(FONT_FAMILY, Enum.FontWeight.Regular),
	Medium = Font.new(FONT_FAMILY, Enum.FontWeight.Medium),
	SemiBold = Font.new(FONT_FAMILY, Enum.FontWeight.SemiBold),
}

local Library = {
	Unloaded = false,
	Icons = { chevron = "", close = "", minimize = "", discord = "" },
}

-- Core helpers -----------------------------------------------------------

local function New(class, props)
	local inst = Instance.new(class)
	local parent = props.Parent
	props.Parent = nil
	for key, value in pairs(props) do
		inst[key] = value
	end
	inst.Parent = parent
	return inst
end

local function Round(parent, radius)
	return New("UICorner", { CornerRadius = UDim.new(0, radius), Parent = parent })
end

local function Stroke(parent, color, thickness)
	return New("UIStroke", {
		Color = color,
		Thickness = thickness or 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = parent,
	})
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
	props.BorderSizePixel = 0
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
	return LocalPlayer:WaitForChild("PlayerGui")
end

local function ViewportScale()
	local viewport = Workspace.CurrentCamera.ViewportSize
	return math.clamp(math.min(viewport.X / 520, viewport.Y / 520), 0.6, 1)
end

-- Icon glyph: asset upload bila ada, fallback digeneratif
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
		local function line(length, rotation, dx, dy)
			local part = New("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, dx, 0.5, dy),
				Size = UDim2.fromOffset(length, 2),
				Rotation = rotation,
				BackgroundColor3 = color,
				BorderSizePixel = 0,
				Parent = holder,
			})
			Round(part, 1)
			table.insert(parts, part)
		end

		if name == "chevron" then
			line(size * 0.44, 45, -size * 0.03, -size * 0.16)
			line(size * 0.44, -45, -size * 0.03, size * 0.16)
		elseif name == "close" then
			line(size * 0.75, 45, 0, 0)
			line(size * 0.75, -45, 0, 0)
		elseif name == "minimize" then
			line(size * 0.6, 0, 0, 0)
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

local function MakeDraggable(handle, target, uiScale)
	local state = { Moved = false }

	handle.InputBegan:Connect(function(input)
		if not IsPointer(input) then
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

-- Notifications ----------------------------------------------------------

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
	local toast = New("CanvasGroup", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Theme.Surface,
		BorderSizePixel = 0,
		GroupTransparency = 1,
		LayoutOrder = notifyOrder,
		Parent = NotifyHolder(),
	})
	Round(toast, Radius.MD)
	Stroke(toast, Theme.Border, 1)

	local spine = New("Frame", {
		Size = UDim2.new(0, 3, 1, -8),
		Position = UDim2.fromOffset(0, 4),
		BackgroundColor3 = accent,
		BorderSizePixel = 0,
		Parent = toast,
	})
	Round(spine, 2)

	local body = New("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Parent = toast,
	})
	New("UIPadding", {
		PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, 12),
		PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 12),
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

	local closed = false
	local function dismiss()
		if closed then
			return
		end
		closed = true
		Tween(toast, 0.2, { GroupTransparency = 1 })
		task.delay(0.25, function()
			toast:Destroy()
		end)
	end

	toast.InputBegan:Connect(function(input)
		if IsPointer(input) then
			dismiss()
		end
	end)

	Tween(toast, 0.2, { GroupTransparency = 0 })
	task.delay(duration, dismiss)
end

function Library:SetNotification(cfg)
	return self:Notify({
		Title = cfg.Title or cfg[1],
		Content = cfg.Content or cfg[3] or cfg.Description or cfg[2],
		Duration = cfg.Delay or cfg[6],
	})
end

-- Tab items --------------------------------------------------------------

local function BuildItems(page, accent)
	local items, order = {}, 0

	local function nextOrder()
		order += 1
		return order
	end

	local function Row(height)
		local row = New("Frame", {
			BackgroundColor3 = Theme.Raised,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, height),
			LayoutOrder = nextOrder(),
			Parent = page,
		})
		Round(row, Radius.MD)
		Stroke(row, Theme.Border, 1)
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
				TextSize = 12,
				TextColor3 = Theme.TextSecondary,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Parent = row,
			})
		end
	end

	local function Hit(row, restColor)
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
			Tween(row, 0.12, { BackgroundColor3 = restColor or Theme.Raised })
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
		Label({
			Size = UDim2.new(1, 0, 0, 20),
			LayoutOrder = nextOrder(),
			Weight = "SemiBold",
			Text = string.upper(title or ""),
			TextSize = 11,
			TextColor3 = Theme.TextTertiary,
			TextYAlignment = Enum.TextYAlignment.Bottom,
			Parent = page,
		})
		return self
	end

	function items:AddLabel(text)
		local label = Label({
			Size = UDim2.new(1, 0, 0, 0),
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
				label.Text = value
			end,
		}
	end

	function items:AddButton(cfg)
		local title = Opt(cfg, 1, "Title", "Button")
		local desc = Opt(cfg, 2, "Content", nil)
		local callback = Opt(cfg, 4, "Callback", function() end)
		if desc == "" then
			desc = nil
		end

		local row = Row(desc and 52 or 40)
		Titles(row, title, desc, 40)

		local holder, paint = Glyph(row, "chevron", Theme.TextTertiary, 16)
		holder.AnchorPoint = Vector2.new(1, 0.5)
		holder.Position = UDim2.new(1, -12, 0.5, 0)

		local hit = Hit(row)
		hit.MouseEnter:Connect(function()
			paint(Theme.TextSecondary, 0.12)
		end)
		hit.MouseLeave:Connect(function()
			paint(Theme.TextTertiary, 0.12)
		end)
		hit.Activated:Connect(function()
			task.spawn(callback)
		end)
	end

	function items:AddToggle(cfg)
		local title = Opt(cfg, 1, "Title", "Toggle")
		local desc = Opt(cfg, 2, "Content", nil)
		local default = Opt(cfg, 3, "Default", false)
		local callback = Opt(cfg, 4, "Callback", function() end)
		if desc == "" then
			desc = nil
		end

		local obj = { Value = default }
		local row = Row(desc and 52 or 40)
		Titles(row, title, desc, 60)

		local track = New("Frame", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -12, 0.5, 0),
			Size = UDim2.fromOffset(36, 20),
			BackgroundColor3 = Theme.Track,
			BorderSizePixel = 0,
			Parent = row,
		})
		Round(track, 10)
		local knob = New("Frame", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 3, 0.5, 0),
			Size = UDim2.fromOffset(14, 14),
			BackgroundColor3 = Color3.fromRGB(250, 250, 252),
			BorderSizePixel = 0,
			Parent = track,
		})
		Round(knob, 7)

		local function render(animate)
			local trackColor = obj.Value and accent or Theme.Track
			local knobPos = UDim2.new(0, obj.Value and 19 or 3, 0.5, 0)
			if animate then
				Tween(track, 0.16, { BackgroundColor3 = trackColor })
				Tween(knob, 0.16, { Position = knobPos })
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

	function items:AddSlider(cfg)
		local title = Opt(cfg, 1, "Title", "Slider")
		local increment = Opt(cfg, 3, "Increment", 1)
		local min = Opt(cfg, 4, "Min", 0)
		local max = Opt(cfg, 5, "Max", 100)
		local default = Opt(cfg, 6, "Default", min)
		local callback = Opt(cfg, 7, "Callback", function() end)

		local obj = { Value = default }
		local row = Row(52)

		Label({
			Position = UDim2.fromOffset(12, 9),
			Size = UDim2.new(1, -84, 0, 16),
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
			Size = UDim2.fromOffset(56, 16),
			Weight = "Medium",
			TextSize = 12,
			TextColor3 = Theme.TextSecondary,
			TextXAlignment = Enum.TextXAlignment.Right,
			Parent = row,
		})

		local track = New("Frame", {
			Position = UDim2.fromOffset(12, 36),
			Size = UDim2.new(1, -24, 0, 4),
			BackgroundColor3 = Theme.Track,
			BorderSizePixel = 0,
			Parent = row,
		})
		Round(track, 2)
		local fill = New("Frame", {
			Size = UDim2.fromScale(0, 1),
			BackgroundColor3 = accent,
			BorderSizePixel = 0,
			Parent = track,
		})
		Round(fill, 2)
		local knob = New("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(1, 0.5),
			Size = UDim2.fromOffset(12, 12),
			BackgroundColor3 = Color3.fromRGB(250, 250, 252),
			BorderSizePixel = 0,
			Parent = fill,
		})
		Round(knob, 6)
		Stroke(knob, Theme.Surface, 2)

		local function snap(value)
			value = math.clamp(value, min, max)
			value = min + math.floor((value - min) / increment + 0.5) * increment
			value = math.clamp(value, min, max)
			return math.floor(value * 10000 + 0.5) / 10000
		end

		local function render()
			local range = max - min
			fill.Size = UDim2.fromScale(range == 0 and 0 or (obj.Value - min) / range, 1)
			valueLabel.Text = tostring(obj.Value)
		end

		function obj:Set(value, silent)
			value = snap(value)
			local changed = value ~= obj.Value
			obj.Value = value
			render()
			if changed and not silent then
				task.spawn(callback, value)
			end
		end

		local function fromInput(position)
			local alpha = math.clamp((position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
			obj:Set(min + (max - min) * alpha)
		end

		local hit = New("TextButton", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(12, 28),
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
					page.ScrollingEnabled = true
				end
			end)
		end)

		obj.Value = snap(default)
		render()
		return obj
	end

	return items
end

-- Window -----------------------------------------------------------------

function Library:CreateWindow(cfg)
	cfg = cfg or {}
	local title = Opt(cfg, 1, "Title", "ZYPHERAX HUB")
	local logo = Opt(cfg, 5, "Logo", DEFAULT_LOGO)
	local accent = Opt(cfg, 6, "Color", Theme.Accent)
	local toggleKey = cfg.ToggleKey or Enum.KeyCode.RightShift
	local discord = cfg.Discord
	if logo == "" then
		logo = DEFAULT_LOGO
	end

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
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = parent,
	})

	local root = New("Frame", {
		Name = "Root",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(Metrics.Width, Metrics.TotalH),
		BackgroundTransparency = 1,
		Parent = gui,
	})
	local uiScale = New("UIScale", { Parent = root })

	-- Card utama: flat, stroke brand 2px, radius 28 (sesuai mock)
	local card = New("Frame", {
		Name = "Card",
		Size = UDim2.fromOffset(Metrics.Width, Metrics.CardH),
		BackgroundColor3 = Theme.Surface,
		BorderSizePixel = 0,
		Parent = root,
	})
	Round(card, Metrics.CardRadius)
	Stroke(card, accent, 2)

	-- Logo: ring putih tebal (fill), well navy, ring brand tipis, glyph
	local logoCircle = New("Frame", {
		Name = "LogoCircle",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0, 0),
		Size = UDim2.fromOffset(Metrics.LogoOuter, Metrics.LogoOuter),
		BackgroundColor3 = Theme.LogoRing,
		BorderSizePixel = 0,
		ZIndex = 2,
		Parent = root,
	})
	Round(logoCircle, Metrics.LogoOuter / 2)

	local logoWell = New("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(Metrics.Inner, Metrics.Inner),
		BackgroundColor3 = Theme.LogoWell,
		BorderSizePixel = 0,
		ZIndex = 3,
		Parent = logoCircle,
	})
	Round(logoWell, Metrics.Inner / 2)
	Stroke(logoWell, accent, Metrics.LogoStroke)

	New("ImageLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(Metrics.LogoGlyph, Metrics.LogoGlyph),
		BackgroundTransparency = 1,
		Image = logo,
		ScaleType = Enum.ScaleType.Fit,
		ZIndex = 4,
		Parent = logoWell,
	})

	-- Konten: mulai di bawah overhang logo
	local content = New("Frame", {
		Name = "Content",
		Position = UDim2.fromOffset(Metrics.ContentPadX, Metrics.ContentTop),
		Size = UDim2.new(1, -Metrics.ContentPadX * 2, 1, -(Metrics.ContentTop + Metrics.ContentBottom)),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Parent = card,
	})

	-- Tab chips: hanya muncul bila tab > 1 (mock = 1 tab = bersih)
	local chipRow = New("Frame", {
		Name = "TabChips",
		Size = UDim2.new(1, 0, 0, Metrics.ChipH),
		BackgroundTransparency = 1,
		Visible = false,
		Parent = content,
	})
	New("UIListLayout", {
		Padding = UDim.new(0, 6),
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Parent = chipRow,
	})

	local pages = New("Frame", {
		Name = "Pages",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Parent = content,
	})

	-- Status bar: pill, stroke brand, avatar + 4 baris + tombol discord
	local barY = Metrics.CardH + Metrics.Gap
	local bar = New("Frame", {
		Name = "StatusBar",
		Position = UDim2.fromOffset(0, barY),
		Size = UDim2.fromOffset(Metrics.Width, Metrics.BarH),
		BackgroundColor3 = Theme.Surface,
		BorderSizePixel = 0,
		Parent = root,
	})
	Round(bar, Metrics.BarRadius)
	Stroke(bar, accent, 2)

	local avatar = New("ImageLabel", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, Metrics.BarPad, 0.5, 0),
		Size = UDim2.fromOffset(Metrics.Avatar, Metrics.Avatar),
		BackgroundColor3 = Theme.Inset,
		BorderSizePixel = 0,
		Image = "",
		Parent = bar,
	})
	Round(avatar, Metrics.Avatar / 2)
	Stroke(avatar, Theme.LogoRing, Metrics.AvatarRing)

	task.spawn(function()
		local ok, image = pcall(
			Players.GetUserThumbnailAsync, Players,
			LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100
		)
		if ok then
			avatar.Image = image
		end
	end)

	local textX = Metrics.BarPad + Metrics.Avatar + 12
	local rightReserve = discord and (Metrics.DiscordW + Metrics.BarPad + 12) or (Metrics.BarPad + 4)

	local info = New("Frame", {
		Position = UDim2.fromOffset(textX, 0),
		Size = UDim2.new(1, -(textX + rightReserve), 1, 0),
		BackgroundTransparency = 1,
		Parent = bar,
	})
	New("UIListLayout", {
		Padding = UDim.new(0, 2),
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Parent = info,
	})

	Label({
		LayoutOrder = 1,
		Size = UDim2.new(1, 0, 0, 16),
		Weight = "SemiBold",
		Text = cfg.StatusTitle or "USER STATUS",
		TextSize = 14,
		TextColor3 = Theme.BarTitle,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = info,
	})
	Label({
		LayoutOrder = 2,
		Size = UDim2.new(1, 0, 0, 14),
		Text = "Username : " .. (cfg.Username or LocalPlayer.Name),
		TextSize = 12,
		TextColor3 = Theme.BarLine,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = info,
	})
	Label({
		LayoutOrder = 3,
		Size = UDim2.new(1, 0, 0, 14),
		Text = "ID : " .. tostring(cfg.UserId or LocalPlayer.UserId),
		TextSize = 12,
		TextColor3 = Theme.BarLine,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = info,
	})
	Label({
		LayoutOrder = 4,
		Size = UDim2.new(1, 0, 0, 14),
		Text = "Status : " .. (cfg.Status or "No-Key Script"),
		TextSize = 12,
		TextColor3 = Theme.BarLine,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = info,
	})

	if discord then
		local button = New("TextButton", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -Metrics.BarPad, 0.5, 0),
			Size = UDim2.fromOffset(Metrics.DiscordW, Metrics.DiscordH),
			BackgroundColor3 = Theme.Discord,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Text = "discord",
			FontFace = Typo.Medium,
			TextSize = 13,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			Parent = bar,
		})
		Round(button, Metrics.DiscordH / 2)
		local press = New("UIScale", { Parent = button })

		button.MouseEnter:Connect(function()
			Tween(button, 0.12, { BackgroundColor3 = Theme.DiscordHover })
		end)
		button.MouseLeave:Connect(function()
			Tween(button, 0.12, { BackgroundColor3 = Theme.Discord })
		end)
		button.MouseButton1Down:Connect(function()
			Tween(press, 0.06, { Scale = 0.96 })
		end)
		button.MouseButton1Up:Connect(function()
			Tween(press, 0.12, { Scale = 1 })
		end)
		button.Activated:Connect(function()
			if typeof(setclipboard) == "function" then
				setclipboard(discord)
				Library:Notify({ Title = "Discord", Content = "Invite link copied to clipboard.", Color = accent })
			else
				Library:Notify({ Title = "Discord", Content = discord, Color = accent })
			end
		end)
	end

	-- Drag: zona atas card + logo circle (bar sengaja tidak, agar tombol aman)
	local dragZone = New("Frame", {
		Name = "DragZone",
		Size = UDim2.new(1, 0, 0, Metrics.ContentTop),
		BackgroundTransparency = 1,
		Parent = card,
	})
	MakeDraggable(dragZone, root, uiScale)
	MakeDraggable(logoCircle, root, uiScale)

	-- Launcher (state minimize)
	local launcher = New("ImageButton", {
		Name = "Launcher",
		Position = UDim2.new(0, 20, 0.5, -24),
		Size = UDim2.fromOffset(48, 48),
		BackgroundColor3 = Theme.Inset,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Image = "",
		Visible = false,
		Parent = gui,
	})
	Round(launcher, 14)
	Stroke(launcher, Theme.BorderStrong, 1)
	New("ImageLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(28, 28),
		BackgroundTransparency = 1,
		Image = logo,
		ScaleType = Enum.ScaleType.Fit,
		Parent = launcher,
	})
	local launcherDrag = MakeDraggable(launcher, launcher)

	-- Visibility & responsive scale
	local baseScale, visible = ViewportScale(), true

	function window:SetVisible(show)
		visible = show
		launcher.Visible = not show
		root.Visible = show
		if show then
			uiScale.Scale = baseScale * 0.96
			Tween(uiScale, 0.22, { Scale = baseScale }, Enum.EasingStyle.Quint)
		end
	end

	function window:Toggle()
		window:SetVisible(not visible)
	end

	function window:Destroy()
		for _, connection in ipairs(connections) do
			connection:Disconnect()
		end
		gui:Destroy()
		Library.Unloaded = true
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

	window:SetVisible(true)

	-- Tabs -----------------------------------------------------------------
	local tabs = {}

	local function styleChip(tab, active)
		tab.Chip.BackgroundColor3 = active and accent or Theme.Raised
		tab.Chip.BackgroundTransparency = active and 0 or 1
		tab.Chip.TextColor3 = active and Color3.fromRGB(255, 255, 255) or Theme.TextSecondary
		tab.ChipStroke.Color = active and accent or Theme.Border
	end

	local function selectTab(selected)
		for _, tab in ipairs(tabs) do
			local active = tab == selected
			tab.Active = active
			tab.Page.Visible = active
			styleChip(tab, active)
		end
	end

	function window:AddTab(tabCfg)
		local name
		if type(tabCfg) == "table" then
			name = Opt(tabCfg, 1, "Name", "Tab")
		else
			name = tostring(tabCfg or "Tab")
		end

		local page = New("ScrollingFrame", {
			Name = name,
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			ScrollBarThickness = 3,
			ScrollBarImageColor3 = accent,
			ScrollBarImageTransparency = 0.35,
			Visible = false,
			Parent = pages,
		})
		New("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = page })
		New("UIPadding", { PaddingRight = UDim.new(0, 6), Parent = page })

		local chip = New("TextButton", {
			Name = name,
			Size = UDim2.fromOffset(40, Metrics.ChipH),
			BackgroundColor3 = Theme.Raised,
			BackgroundTransparency = 1,
			AutoButtonColor = false,
			Text = name,
			FontFace = Typo.Medium,
			TextSize = 12,
			TextColor3 = Theme.TextSecondary,
			Parent = chipRow,
		})
		Round(chip, Metrics.ChipH / 2)
		local chipStroke = Stroke(chip, Theme.Border, 1)
		New("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), Parent = chip })
		chip.Size = UDim2.fromOffset(math.max(chip.TextBounds.X + 24, 40), Metrics.ChipH)

		local tab = { Page = page, Chip = chip, ChipStroke = chipStroke, Active = false }
		table.insert(tabs, tab)

		chip.Activated:Connect(function()
			selectTab(tab)
		end)

		if #tabs == 2 then
			chipRow.Visible = true
			pages.Position = UDim2.fromOffset(0, Metrics.ChipRowH)
			pages.Size = UDim2.new(1, 0, 1, -Metrics.ChipRowH)
		end

		if #tabs == 1 then
			selectTab(tab)
		end

		return BuildItems(page, accent)
	end
	window.CreateTab = window.AddTab

	return window
end

return Library
