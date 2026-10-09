local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local DEFAULT_LOGO = "rbxassetid://106764279090045"

--------------------------------------------------------------------------------
-- THEME & DESIGN TOKENS
--------------------------------------------------------------------------------
local Theme = {
	StrokeTop = Color3.fromRGB(96, 170, 255),
	StrokeMid = Color3.fromRGB(28, 100, 232),
	StrokeBottom = Color3.fromRGB(10, 46, 138),

	Surface = Color3.fromRGB(16, 17, 22),
	SurfaceDeep = Color3.fromRGB(9, 10, 13),
	Raised = Color3.fromRGB(23, 25, 32),
	Hover = Color3.fromRGB(31, 35, 46),
	Pressed = Color3.fromRGB(18, 20, 27),
	Inset = Color3.fromRGB(10, 11, 15),
	Track = Color3.fromRGB(40, 44, 56),

	Border = Color3.fromRGB(36, 40, 52),
	BorderStrong = Color3.fromRGB(50, 56, 72),

	Text = Color3.fromRGB(245, 247, 251),
	TextSecondary = Color3.fromRGB(188, 194, 206),
	TextTertiary = Color3.fromRGB(128, 136, 152),

	Accent = Color3.fromRGB(46, 120, 246),
	White = Color3.fromRGB(255, 255, 255),
	Discord = Color3.fromRGB(58, 128, 250),
	DiscordEdge = Color3.fromRGB(26, 78, 206),
	DiscordOutline = Color3.fromRGB(120, 172, 255),
	DiscordText = Color3.fromRGB(255, 255, 255),
	Success = Color3.fromRGB(80, 178, 128),
	Warning = Color3.fromRGB(236, 178, 70),
	Danger = Color3.fromRGB(224, 92, 92),

	SteelTop = Color3.fromRGB(222, 228, 238),
	SteelBottom = Color3.fromRGB(148, 156, 170),
	SteelInk = Color3.fromRGB(12, 20, 38),
}

--------------------------------------------------------------------------------
-- LAYOUT DIMENSIONS
--------------------------------------------------------------------------------
local WIDTH = 420
local CARD_H = 310
local GAP = 12
local BAR_H = 74
local TOTAL_H = CARD_H + GAP + BAR_H

local R_CARD = 18
local STROKE_THICKNESS = 1.5

local BADGE_D = 92
local OVERHANG = BADGE_D / 2

local AVATAR_SIZE = 52
local INFO_LABEL_W = 68
local DISCORD_W = 112
local DISCORD_H = 40

local CONTENT_PADDING = 14
local CONTENT_TOP = 42

--------------------------------------------------------------------------------
-- LIBRARY CONSTANTS & ICONS
--------------------------------------------------------------------------------
local Library = {
	Unloaded = false,
	Windows = {},
	Icons = { chevron = "", close = "", minimize = "", discord = "", check = "", crown = "", info = "", warn = "" },
}

--------------------------------------------------------------------------------
-- UTILITY FUNCTIONS
--------------------------------------------------------------------------------
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
	local ok, core = pcall(function() return CoreGui end)
	if ok and core then
		local ok2, roblox = pcall(function() return core:WaitForChild("RobloxGui") end)
		if ok2 and roblox then
			return roblox
		end
	end
	return LocalPlayer:WaitForChild("PlayerGui")
end

local function ViewportScale()
	local viewport = Workspace.CurrentCamera.ViewportSize
	return math.clamp(math.min(viewport.X / (WIDTH + 80), viewport.Y / (TOTAL_H + OVERHANG + 80)), 0.65, 1.1)
end

--------------------------------------------------------------------------------
-- GLYPH SYSTEM
--------------------------------------------------------------------------------
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
			bar(10.4 * u, 2.2 * u, 0, 0, 4.7 * u)
			bar(5.5 * u, 1.8 * u, 90, -4 * u, 0.4 * u)
			bar(7.5 * u, 1.8 * u, 90, 0, -0.6 * u)
			bar(5.5 * u, 1.8 * u, 90, 4 * u, 0.4 * u)
			bar(2.5 * u, 2.5 * u, 0, -4 * u, -2.6 * u)
			bar(2.5 * u, 2.5 * u, 0, 0, -4.6 * u)
			bar(2.5 * u, 2.5 * u, 0, 4 * u, -2.6 * u)
		elseif name == "info" then
			bar(2.4, 2.4, 0, 0, -size * 0.3)
			bar(size * 0.38, 2, 90, 0, size * 0.12)
		elseif name == "warn" then
			bar(size * 0.38, 2, 90, 0, -size * 0.12)
			bar(2.4, 2.4, 0, 0, size * 0.3)
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

--------------------------------------------------------------------------------
-- DRAGGABLE SYSTEM
--------------------------------------------------------------------------------
local function MakeDraggable(handle, target, uiScale)
	local state = { Moved = false }

	handle.InputBegan:Connect(function(input)
		if not IsPointer(input) then return end
		if UserInputService:GetFocusedTextBox() then return end

		local origin, startPos = input.Position, target.Position
		state.Moved = false

		local move, ended
		move = UserInputService.InputChanged:Connect(function(changed)
			if not IsMove(changed) then return end
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

--------------------------------------------------------------------------------
-- NOTIFICATIONS
--------------------------------------------------------------------------------
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
		kind = "info"
	end

	notifyOrder += 1

	local shell = New("Frame", {
		Name = "Toast",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Theme.Surface,
		LayoutOrder = notifyOrder,
		Parent = NotifyHolder(),
	})
	Round(shell, 10)

	local stroke = New("UIStroke", {
		Color = accent,
		Thickness = 1,
		Transparency = 0.4,
		Parent = shell,
	})

	local body = New("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Parent = shell,
	})
	New("UIPadding", {
		PaddingTop = UDim.new(0, 11), PaddingBottom = UDim.new(0, 11),
		PaddingLeft = UDim.new(0, 44), PaddingRight = UDim.new(0, 30),
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
		Position = UDim2.fromOffset(12, 10),
		Size = UDim2.fromOffset(22, 22),
		BackgroundColor3 = accent,
		BackgroundTransparency = 0.85,
		Parent = shell,
	})
	Round(iconBadge, 11)
	Glyph(iconBadge, kindIcon[kind], accent, 12)

	local closer, closePaint = Glyph(shell, "close", Theme.TextTertiary, 12)
	closer.AnchorPoint = Vector2.new(1, 0)
	closer.Position = UDim2.new(1, -10, 0, 10)

	local closed = false
	local function dismiss()
		if closed then return end
		closed = true
		Tween(shell, 0.2, { BackgroundTransparency = 1 })
		Tween(stroke, 0.2, { Transparency = 1 })
		task.delay(0.22, function() shell:Destroy() end)
	end

	closer.InputBegan:Connect(function(input)
		if IsPointer(input) then dismiss() end
	end)
	closer.MouseEnter:Connect(function() closePaint(Theme.Text, 0.1) end)
	closer.MouseLeave:Connect(function() closePaint(Theme.TextTertiary, 0.1) end)

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

--------------------------------------------------------------------------------
-- ROW CONTROLS
--------------------------------------------------------------------------------
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
			ClipsDescendants = false, -- PERBAIKAN: False agar Dropdown/Colorpicker melayang mulus
			Parent = page,
		})
		Round(row, 8)
		New("UIStroke", {
			Color = Theme.Border,
			Thickness = 1,
			Transparency = 0.5,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Parent = row,
		})
		return row
	end

	local function Titles(row, title, desc, rightInset)
		Label({
			AnchorPoint = Vector2.new(0, desc and 0 or 0.5),
			Position = desc and UDim2.fromOffset(12, 8) or UDim2.new(0, 12, 0.5, 0),
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
				Position = UDim2.fromOffset(12, 26),
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
			BackgroundTransparency = 0.5,
			Parent = wrap,
		})
		heading:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
			local width = heading.AbsoluteSize.X + 10
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
		return { Set = function(_, value) label.Text = tostring(value) end }
	end

	function items:AddButton(cfg, legacy)
		if type(cfg) == "string" then cfg = { Title = cfg, Callback = legacy } end
		cfg = cfg or {}
		local title = Opt(cfg, 1, "Title", "Button")
		local desc = Opt(cfg, 2, "Content", nil)
		local callback = Opt(cfg, 4, "Callback", function() end)

		local row = Row(desc and 48 or 36)
		Titles(row, title, desc, 36)

		local holder, paint = Glyph(row, "chevron", Theme.TextTertiary, 14)
		holder.AnchorPoint = Vector2.new(1, 0.5)
		holder.Position = UDim2.new(1, -12, 0.5, 0)

		local hit = Hit(row)
		hit.MouseEnter:Connect(function() paint(Theme.TextSecondary, 0.12) end)
		hit.MouseLeave:Connect(function() paint(Theme.TextTertiary, 0.12) end)
		hit.Activated:Connect(function() task.spawn(callback) end)
		return { Fire = function() task.spawn(callback) end }
	end

	function items:AddToggle(cfg, legacy)
		if type(cfg) == "string" then cfg = { Title = cfg, Callback = legacy } end
		cfg = cfg or {}
		local title = Opt(cfg, 1, "Title", "Toggle")
		local desc = Opt(cfg, 2, "Content", nil)
		local default = Opt(cfg, 3, "Default", false)
		local callback = Opt(cfg, 4, "Callback", function() end)

		local obj = { Value = default and true or false }
		local row = Row(desc and 48 or 36)
		Titles(row, title, desc, 54)

		local track = New("Frame", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -12, 0.5, 0),
			Size = UDim2.fromOffset(36, 18),
			BackgroundColor3 = Theme.Track,
			Parent = row,
		})
		Round(track, 9)
		local knob = New("Frame", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 2, 0.5, 0),
			Size = UDim2.fromOffset(14, 14),
			BackgroundColor3 = Theme.White,
			Parent = track,
		})
		Round(knob, 7)

		local function render(animate)
			local trackColor = obj.Value and accents.fill or Theme.Track
			local knobPos = UDim2.new(0, obj.Value and 20 or 2, 0.5, 0)
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
			if not silent then task.spawn(callback, obj.Value) end
			return obj.Value
		end

		Hit(row).Activated:Connect(function() obj:Set(not obj.Value) end)
		render(false)
		if default then task.spawn(callback, true) end
		return obj
	end

	function items:AddSlider(cfg, legacy)
		if type(cfg) == "string" then cfg = { Title = cfg, Callback = legacy } end
		cfg = cfg or {}
		local title = Opt(cfg, 1, "Title", "Slider")
		local increment = Opt(cfg, 3, "Increment", 1)
		local min = Opt(cfg, 4, "Min", 0)
		local max = Opt(cfg, 5, "Max", 100)
		local default = Opt(cfg, 6, "Default", min)
		local suffix = cfg.Suffix or ""
		local callback = Opt(cfg, 7, "Callback", function() end)

		local obj = { Value = default }
		local row = Row(48)

		Label({
			Position = UDim2.fromOffset(12, 8),
			Size = UDim2.new(1, -80, 0, 16),
			Weight = "Medium",
			Text = title,
			TextSize = 13,
			TextColor3 = Theme.Text,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = row,
		})
		local valueLabel = Label({
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -12, 0, 8),
			Size = UDim2.fromOffset(60, 16),
			Weight = "Medium",
			TextSize = 12,
			TextColor3 = accents.top,
			TextXAlignment = Enum.TextXAlignment.Right,
			Parent = row,
		})

		local track = New("Frame", {
			Position = UDim2.fromOffset(12, 32),
			Size = UDim2.new(1, -24, 0, 4),
			BackgroundColor3 = Theme.Track,
			Parent = row,
		})
		Round(track, 2)
		local fill = New("Frame", {
			Size = UDim2.fromScale(0, 1),
			BackgroundColor3 = accents.top,
			Parent = track,
		})
		Round(fill, 2)

		local knob = New("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(1, 0.5),
			Size = UDim2.fromOffset(12, 12),
			BackgroundColor3 = Theme.White,
			Parent = fill,
		})
		Round(knob, 6)

		local function format(val)
			local text = (increment % 1 == 0) and tostring(math.floor(val + 0.5)) or tostring(math.floor(val * 100 + 0.5) / 100)
			return text .. suffix
		end

		local function snap(val)
			val = math.clamp(val, min, max)
			val = min + math.floor((val - min) / increment + 0.5) * increment
			return math.clamp(val, min, max)
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
			if changed and not silent then task.spawn(callback, value) end
			return value
		end

		local function fromInput(pos)
			local alpha = math.clamp((pos.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
			obj:Set(min + (max - min) * alpha)
		end

		local hit = New("TextButton", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(12, 24),
			Size = UDim2.new(1, -24, 0, 20),
			Text = "",
			AutoButtonColor = false,
			Parent = row,
		})
		hit.InputBegan:Connect(function(input)
			if not IsPointer(input) then return end
			fromInput(input.Position)
			page.ScrollingEnabled = false
			local move, ended
			move = UserInputService.InputChanged:Connect(function(changed)
				if IsMove(changed) then fromInput(changed.Position) end
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

	function items:AddDropdown(cfg, legacy)
		if type(cfg) == "string" then cfg = { Title = cfg, Callback = legacy } end
		cfg = cfg or {}
		local title = Opt(cfg, 1, "Title", "Dropdown")
		local options = cfg.Options or cfg.List or {}
		local default = cfg.Default
		local callback = cfg.Callback or function() end

		local open = false
		local row = Row(36)

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
			Position = UDim2.new(1, -32, 0.5, 0),
			Size = UDim2.new(0.5, -36, 0, 16),
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

		-- PERBAIKAN: Dropdown List Melayang di atas (Topmost ZIndex)
		local list = New("Frame", {
			Position = UDim2.new(0, 0, 1, 4),
			Size = UDim2.new(1, 0, 0, 0),
			BackgroundColor3 = Theme.Inset,
			ClipsDescendants = true,
			Visible = false,
			ZIndex = 50,
			Parent = row,
		})
		Round(list, 8)
		New("UIStroke", { Color = Theme.Border, Thickness = 1, Parent = list })

		local scroll = New("ScrollingFrame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			ScrollBarThickness = 2,
			ScrollBarImageColor3 = accents.top,
			CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ZIndex = 51,
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
			row.ZIndex = state and 40 or 1
			list.Visible = true
			local count = math.min(#options, 5)
			local target = state and (count * 28 + 8) or 0
			Tween(arrow, 0.16, { Rotation = state and 180 or 0 })
			arrowPaint(state and accents.top or Theme.TextTertiary, 0.12)
			Tween(list, 0.18, { Size = UDim2.new(1, 0, 0, target) }, Enum.EasingStyle.Quint)
			if not state then
				task.delay(0.18, function()
					if not open then
						list.Visible = false
						row.ZIndex = 1
					end
				end)
			end
		end

		local function rebuild()
			for _, child in ipairs(scroll:GetChildren()) do
				if child:IsA("TextButton") then child:Destroy() end
			end
			for index, option in ipairs(options) do
				local selected = option == obj.Value
				local entry = New("TextButton", {
					Size = UDim2.new(1, 0, 0, 26),
					LayoutOrder = index,
					BackgroundColor3 = selected and Theme.Hover or Theme.Inset,
					Text = "",
					AutoButtonColor = false,
					ZIndex = 52,
					Parent = scroll,
				})
				Round(entry, 6)
				Label({
					Position = UDim2.fromOffset(8, 0),
					Size = UDim2.new(1, -28, 1, 0),
					Text = tostring(option),
					TextSize = 12,
					TextColor3 = selected and Theme.Text or Theme.TextSecondary,
					TextYAlignment = Enum.TextYAlignment.Center,
					TextTruncate = Enum.TextTruncate.AtEnd,
					ZIndex = 53,
					Parent = entry,
				})
				if selected then
					local mark = Glyph(entry, "check", accents.top, 12)
					mark.AnchorPoint = Vector2.new(1, 0.5)
					mark.Position = UDim2.new(1, -8, 0.5, 0)
				end
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
			if not silent then task.spawn(callback, value) end
			return value
		end

		function obj:Refresh(newOptions)
			options = newOptions or options
			rebuild()
		end

		Hit(row).Activated:Connect(function() setOpen(not open) end)
		rebuild()
		return obj
	end

	function items:AddKeybind(cfg, legacy)
		if type(cfg) == "string" then cfg = { Title = cfg, Callback = legacy } end
		cfg = cfg or {}
		local title = Opt(cfg, 1, "Title", "Keybind")
		local defaultKey = cfg.Default or cfg.Key
		local callback = cfg.Callback or function() end

		local obj = { Key = defaultKey }
		local row = Row(36)
		Titles(row, title, nil, 90)

		local listening = false
		local pill = New("TextButton", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -12, 0.5, 0),
			Size = UDim2.fromOffset(70, 22),
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
			if not key or key == Enum.KeyCode.Unknown then return "None" end
			return string.gsub(key.Name, "^KeyCode", "")
		end

		local function render()
			keyLabel.Text = listening and "..." or nameOf(obj.Key)
		end

		local connection
		function obj:Set(key, silent)
			obj.Key = key
			render()
			if not silent then task.spawn(callback, key) end
		end

		pill.Activated:Connect(function()
			listening = not listening
			render()
			pillStroke.Color = listening and accents.top or Theme.Border
			if listening then
				connection = UserInputService.InputBegan:Connect(function(input, processed)
					if processed then return end
					if input.UserInputType == Enum.UserInputType.Keyboard then
						if input.KeyCode == Enum.KeyCode.Backspace then
							obj:Set(Enum.KeyCode.Unknown)
						elseif input.KeyCode ~= Enum.KeyCode.Unknown then
							obj:Set(input.KeyCode)
						end
						listening = false
						render()
						pillStroke.Color = Theme.Border
						if connection then connection:Disconnect() connection = nil end
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
		if type(cfg) == "string" then cfg = { Title = cfg, Callback = legacy } end
		cfg = cfg or {}
		local title = Opt(cfg, 1, "Title", "Textbox")
		local placeholder = cfg.Placeholder or "Type..."
		local default = cfg.Default or ""
		local callback = cfg.Callback or function() end

		local obj = { Value = default }
		local row = Row(36)
		Titles(row, title, nil, 150)

		-- PERBAIKAN: TextTruncate dan ClipsDescendants dipasang agar teks tidak meluber keluar box
		local boxWrap = New("Frame", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -12, 0.5, 0),
			Size = UDim2.fromOffset(140, 24),
			BackgroundColor3 = Theme.Inset,
			ClipsDescendants = true,
			Parent = row,
		})
		Round(boxWrap, 6)
		local boxStroke = New("UIStroke", { Color = Theme.Border, Thickness = 1, Parent = boxWrap })

		local box = New("TextBox", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			TextColor3 = Theme.Text,
			PlaceholderText = placeholder,
			PlaceholderColor3 = Theme.TextTertiary,
			FontFace = Typo.Regular,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			ClearTextOnFocus = false,
			Text = default,
			Parent = boxWrap,
		})
		New("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), Parent = boxWrap })

		box.Focused:Connect(function() boxStroke.Color = accents.top end)
		box.FocusLost:Connect(function()
			boxStroke.Color = Theme.Border
			obj.Value = box.Text
			task.spawn(callback, box.Text)
		end)

		function obj:Set(text, silent)
			box.Text = tostring(text)
			obj.Value = box.Text
			if not silent then task.spawn(callback, obj.Value) end
		end
		return obj
	end

	function items:AddColorpicker(cfg, legacy)
		if type(cfg) == "string" then cfg = { Title = cfg, Callback = legacy } end
		cfg = cfg or {}
		local title = Opt(cfg, 1, "Title", "Color")
		local default = cfg.Default or cfg.Color or accents.top
		local callback = cfg.Callback or function() end

		local obj = { Value = default }
		local row = Row(36)
		Titles(row, title, nil, 44)

		local swatch = New("TextButton", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -12, 0.5, 0),
			Size = UDim2.fromOffset(24, 24),
			BackgroundColor3 = default,
			Text = "",
			AutoButtonColor = false,
			Parent = row,
		})
		Round(swatch, 6)
		New("UIStroke", { Color = Theme.BorderStrong, Thickness = 1, Parent = swatch })

		-- PERBAIKAN: Panel ColorPicker Melayang Paling Atas (ZIndex 100)
		local panelOpen = false
		local panel = New("Frame", {
			Position = UDim2.new(1, -180, 1, 6),
			Size = UDim2.fromOffset(176, 146),
			BackgroundColor3 = Theme.Inset,
			ClipsDescendants = true,
			Visible = false,
			ZIndex = 100,
			Parent = row,
		})
		Round(panel, 8)
		New("UIStroke", { Color = Theme.Border, Thickness = 1, Parent = panel })

		local sv = New("TextButton", {
			Position = UDim2.fromOffset(8, 8),
			Size = UDim2.fromOffset(120, 100),
			BackgroundColor3 = default,
			Text = "",
			AutoButtonColor = false,
			ZIndex = 101,
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
			ZIndex = 102,
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
			Size = UDim2.fromOffset(8, 8),
			BackgroundColor3 = Color3.new(1, 1, 1),
			ZIndex = 103,
			Parent = sv,
		})
		Round(svKnob, 4)

		local hue = New("TextButton", {
			Position = UDim2.fromOffset(136, 8),
			Size = UDim2.fromOffset(12, 100),
			BackgroundColor3 = Color3.new(1, 1, 1),
			Text = "",
			AutoButtonColor = false,
			ZIndex = 101,
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
			Size = UDim2.fromOffset(14, 4),
			BackgroundColor3 = Color3.new(1, 1, 1),
			ZIndex = 102,
			Parent = hue,
		})
		Round(hueKnob, 2)

		local hexLabel = Label({
			Position = UDim2.fromOffset(8, 116),
			Size = UDim2.fromOffset(120, 20),
			Weight = "Medium",
			TextSize = 11,
			TextColor3 = Theme.TextSecondary,
			TextXAlignment = Enum.TextXAlignment.Center,
			ZIndex = 101,
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
			if not silent then task.spawn(callback, color) end
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
				if not IsPointer(input) then return end
				handler(input)
				page.ScrollingEnabled = false
				local move, ended
				move = UserInputService.InputChanged:Connect(function(changed)
					if IsMove(changed) then handler(changed) end
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
			row.ZIndex = state and 100 or 1 -- Naikkan ZIndex row secara dramatis
			panel.Visible = state
		end

		swatch.Activated:Connect(function() setPanelOpen(not panelOpen) end)
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
		New("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = wrap })

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
		return wrap
	end

	return items
end

--------------------------------------------------------------------------------
-- MAIN WINDOW CREATION
--------------------------------------------------------------------------------
function Library:CreateWindow(cfg)
	cfg = cfg or {}
	local logo = Opt(cfg, 5, "Logo", DEFAULT_LOGO)
	local toggleKey = cfg.ToggleKey or Enum.KeyCode.RightShift
	local discord = cfg.Discord
	if logo == "" then logo = DEFAULT_LOGO end

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
	if previous then previous:Destroy() end

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

	----------------------------------------------------------------------------
	-- MAIN CARD (UNIBODY CLEAN LOOK)
	----------------------------------------------------------------------------
	local panel = New("Frame", {
		Name = "Panel",
		Position = UDim2.fromOffset(0, OVERHANG),
		Size = UDim2.fromOffset(WIDTH, CARD_H),
		BackgroundColor3 = Theme.Surface,
		Parent = root,
	})
	Round(panel, R_CARD)

	local panelStroke = New("UIStroke", {
		Thickness = STROKE_THICKNESS,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = panel,
	})
	New("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, accents.top),
			ColorSequenceKeypoint.new(0.5, accents.mid),
			ColorSequenceKeypoint.new(1, accents.bottom),
		}),
		Rotation = 90,
		Parent = panelStroke,
	})

	local dragFrame = New("Frame", {
		Name = "DragHandle",
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundTransparency = 1,
		ZIndex = 10,
		Parent = panel,
	})

	----------------------------------------------------------------------------
	-- BRUSHED STEEL HEADER BADGES
	----------------------------------------------------------------------------
	local BADGE_W, BADGE_H, BADGE_Y, BADGE_EDGE = 114, 22, 12, 14

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

		local row = New("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			ZIndex = 6,
			Parent = plate,
		})
		New("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 4),
			Parent = row,
		})
		if withCrown then
			Glyph(row, "crown", Theme.SteelInk, 11)
		end
		Label({
			Size = UDim2.new(0, 0, 1, 0),
			AutomaticSize = Enum.AutomaticSize.X,
			Weight = "SemiBold",
			Text = text,
			TextSize = 9,
			TextColor3 = Theme.SteelInk,
			Parent = row,
		})
		return plate
	end

	if cfg.ShowBadges ~= false then
		SteelBadge("LeftBadge", BADGE_EDGE, cfg.LeftBadge or "Z-EXECUTOR HUB", false)
		SteelBadge("RightBadge", WIDTH - BADGE_EDGE - BADGE_W, cfg.RightBadge or "PREMIUM EDITION", true)
	end

	----------------------------------------------------------------------------
	-- LOGO MEDALLION DISC
	----------------------------------------------------------------------------
	local badgeShell = New("Frame", {
		Name = "LogoMedallion",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0, OVERHANG),
		Size = UDim2.fromOffset(BADGE_D, BADGE_D),
		BackgroundColor3 = Theme.Surface,
		ZIndex = 8,
		Parent = root,
	})
	Round(badgeShell, BADGE_D / 2)

	local badgeStroke = New("UIStroke", {
		Thickness = 2,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = badgeShell,
	})
	New("UIGradient", {
		Color = ColorSequence.new(accents.top, accents.bottom),
		Rotation = 90,
		Parent = badgeStroke,
	})

	-- HALO PULSING
	local halo = New("Frame", {
		Name = "Halo",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0, OVERHANG),
		Size = UDim2.fromOffset(BADGE_D + 6, BADGE_D + 6),
		BackgroundTransparency = 1,
		ZIndex = 7,
		Parent = root,
	})
	Round(halo, (BADGE_D + 6) / 2)
	local haloStroke = New("UIStroke", {
		Color = accents.top,
		Thickness = 1.5,
		Transparency = 0.3,
		Parent = halo,
	})
	local haloTween = TweenService:Create(
		haloStroke,
		TweenInfo.new(1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{ Transparency = 0.85, Thickness = 3.5 }
	)
	haloTween:Play()

	local logoImg = New("ImageLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.85, 0.85),
		BackgroundTransparency = 1,
		Image = logo,
		ScaleType = Enum.ScaleType.Fit,
		ZIndex = 9,
		Parent = badgeShell,
	})

	----------------------------------------------------------------------------
	-- CONTENT AREA
	----------------------------------------------------------------------------
	local content = New("Frame", {
		Name = "Content",
		Position = UDim2.fromOffset(CONTENT_PADDING, CONTENT_TOP),
		Size = UDim2.new(1, -CONTENT_PADDING * 2, 1, -(CONTENT_TOP + 12)),
		BackgroundTransparency = 1,
		ClipsDescendants = false,
		ZIndex = 4,
		Parent = panel,
	})

	----------------------------------------------------------------------------
	-- BOTTOM USER STATUS BAR
	----------------------------------------------------------------------------
	local barY = OVERHANG + CARD_H + GAP
	local bar = New("Frame", {
		Name = "StatusBar",
		Position = UDim2.fromOffset(0, barY),
		Size = UDim2.fromOffset(WIDTH, BAR_H),
		BackgroundColor3 = Theme.Surface,
		ZIndex = 2,
		Parent = root,
	})
	Round(bar, BAR_H / 2)
	local barStroke = New("UIStroke", {
		Thickness = STROKE_THICKNESS,
		Parent = bar,
	})
	New("UIGradient", {
		Color = ColorSequence.new(accents.top, accents.bottom),
		Rotation = 90,
		Parent = barStroke,
	})

	-- PERBAIKAN: Profile Circle dengan Masking Sempurna
	local avatarShell = New("Frame", {
		Name = "AvatarDisc",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 12, 0.5, 0),
		Size = UDim2.fromOffset(AVATAR_SIZE, AVATAR_SIZE),
		BackgroundColor3 = Theme.SurfaceDeep,
		ClipsDescendants = true, -- PERBAIKAN: gambar tidak bocor keluar
		ZIndex = 3,
		Parent = bar,
	})
	Round(avatarShell, AVATAR_SIZE / 2)
	New("UIStroke", { Color = accents.top, Thickness = 1.5, Parent = avatarShell })

	local avatar = New("ImageLabel", {
		Name = "Head",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1), -- PERBAIKAN: Scale Penuh
		BackgroundTransparency = 1,
		Image = "",
		ScaleType = Enum.ScaleType.Crop, -- PERBAIKAN: Crop lingkaran rapi
		ZIndex = 4,
		Parent = avatarShell,
	})

	task.spawn(function()
		local ok, image = pcall(function()
			return Players:GetUserThumbnailAsync(
				LocalPlayer.UserId,
				Enum.ThumbnailType.HeadShot,
				Enum.ThumbnailSize.Size420x420
			)
		end)
		if ok and image then avatar.Image = image end
	end)

	local info = New("Frame", {
		Name = "InfoBlock",
		Position = UDim2.fromOffset(74, 0),
		Size = UDim2.new(1, -(74 + (discord and (DISCORD_W + 20) or 16)), 1, 0),
		BackgroundTransparency = 1,
		ZIndex = 3,
		Parent = bar,
	})
	New("UIListLayout", {
		Padding = UDim.new(0, 2),
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Parent = info,
	})

	local statusTitle = Label({
		LayoutOrder = 1,
		Size = UDim2.new(1, 0, 0, 14),
		Weight = "Bold",
		Text = "USER STATUS",
		TextSize = 12,
		TextColor3 = Theme.Text,
		Parent = info,
	})

	local function InfoRow(order, name, value)
		local row = New("Frame", {
			LayoutOrder = order,
			Size = UDim2.new(1, 0, 0, 13),
			BackgroundTransparency = 1,
			Parent = info,
		})
		Label({
			Size = UDim2.new(0, INFO_LABEL_W, 1, 0),
			Weight = "Medium",
			Text = name .. ":",
			TextSize = 11,
			TextColor3 = Theme.TextTertiary,
			Parent = row,
		})
		return Label({
			Position = UDim2.fromOffset(INFO_LABEL_W, 0),
			Size = UDim2.new(1, -INFO_LABEL_W, 1, 0),
			Text = tostring(value),
			TextSize = 11,
			TextColor3 = Theme.Text,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = row,
		})
	end

	local statusName = InfoRow(2, "Username", cfg.Username or LocalPlayer.Name)
	local statusId = InfoRow(3, "ID", cfg.UserId or LocalPlayer.UserId)
	local statusLine = InfoRow(4, "Status", cfg.Status or "No-Key Script")

	if discord then
		local button = New("TextButton", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -12, 0.5, 0),
			Size = UDim2.fromOffset(DISCORD_W, DISCORD_H),
			BackgroundColor3 = Theme.Discord,
			Text = "",
			AutoButtonColor = false,
			ZIndex = 3,
			Parent = bar,
		})
		Round(button, DISCORD_H / 2)
		New("UIStroke", { Color = Theme.DiscordOutline, Thickness = 1, Parent = button })

		Label({
			Size = UDim2.fromScale(1, 1),
			Weight = "SemiBold",
			Text = "Discord",
			TextSize = 12,
			TextColor3 = Theme.DiscordText,
			TextXAlignment = Enum.TextXAlignment.Center,
			ZIndex = 4,
			Parent = button,
		})

		button.Activated:Connect(function()
			if typeof(setclipboard) == "function" then
				pcall(setclipboard, discord)
				Library:Notify({ Title = "Discord", Content = "Invite link copied to clipboard.", Color = accents.fill })
			end
		end)
	end

	----------------------------------------------------------------------------
	-- DRAGGING & VISIBILITY CONTROLS
	----------------------------------------------------------------------------
	MakeDraggable(dragFrame, root, uiScale)
	MakeDraggable(bar, root, uiScale)
	MakeDraggable(badgeShell, root, uiScale)

	local launcher = New("ImageButton", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 16, 0.5, 0),
		Size = UDim2.fromOffset(50, 50),
		BackgroundColor3 = Theme.Surface,
		Visible = false,
		Parent = gui,
	})
	Round(launcher, 25)
	New("UIStroke", { Color = accents.top, Thickness = 1.5, Parent = launcher })

	New("ImageLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.8, 0.8),
		BackgroundTransparency = 1,
		Image = logo,
		ScaleType = Enum.ScaleType.Fit,
		Parent = launcher,
	})

	local baseScale, visible = ViewportScale(), false

	function window:SetVisible(show)
		visible = show
		launcher.Visible = not show
		root.Visible = show
		if show then
			uiScale.Scale = baseScale * 0.95
			Tween(uiScale, 0.2, { Scale = baseScale })
		end
	end

	function window:Toggle() window:SetVisible(not visible) end

	function window:Destroy()
		pcall(function() haloTween:Cancel() end)
		for _, conn in ipairs(connections) do conn:Disconnect() end
		gui:Destroy()
		Library.Unloaded = true
	end

	function window:SetStatus(statusCfg)
		statusCfg = statusCfg or {}
		if statusCfg.Username then statusName.Text = tostring(statusCfg.Username) end
		if statusCfg.UserId then statusId.Text = tostring(statusCfg.UserId) end
		if statusCfg.Status then statusLine.Text = tostring(statusCfg.Status) end
		if statusCfg.Title then statusTitle.Text = tostring(statusCfg.Title) end
	end

	launcher.Activated:Connect(function() window:SetVisible(true) end)

	table.insert(connections, UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == toggleKey then window:Toggle() end
	end))

	----------------------------------------------------------------------------
	-- TABS SYSTEM
	----------------------------------------------------------------------------
	local tabs = {}
	local selectedTab
	local tabStrip, tabThumb, tabButtons, pagesHolder

	local function selectTab(selected, animate)
		selectedTab = selected
		for _, tab in ipairs(tabs) do
			local active = tab == selected
			tab.Active = active
			tab.Page.Visible = active
			if active then tab.Page.CanvasPosition = Vector2.new(0, 0) end
			if tab.ButtonLabel then
				Tween(tab.ButtonLabel, 0.15, { TextColor3 = active and Theme.Text or Theme.TextTertiary })
			end
		end

		if tabThumb and selectedTab and selectedTab.Button then
			local goalPos = selectedTab.Button.Position
			local goalSize = selectedTab.Button.Size
			tabThumb.Visible = true
			if animate then
				Tween(tabThumb, 0.2, { Position = goalPos, Size = goalSize })
			else
				tabThumb.Position = goalPos
				tabThumb.Size = goalSize
			end
		end
	end

	local function buildTabStrip()
		tabStrip = New("Frame", {
			Name = "TabStrip",
			Size = UDim2.new(1, 0, 0, 28),
			BackgroundColor3 = Theme.Inset,
			LayoutOrder = 0,
			Parent = content,
		})
		Round(tabStrip, 6)
		New("UIStroke", { Color = Theme.Border, Thickness = 1, Parent = tabStrip })

		tabThumb = New("Frame", {
			Name = "Thumb",
			BackgroundColor3 = Theme.Raised,
			Visible = false,
			ZIndex = 2,
			Parent = tabStrip,
		})
		Round(tabThumb, 5)
		New("UIStroke", { Color = accents.top, Thickness = 1, Transparency = 0.5, Parent = tabThumb })

		tabButtons = New("Frame", {
			Name = "Buttons",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			ClipsDescendants = true, -- PERBAIKAN: Mencegah overflow tab
			ZIndex = 3,
			Parent = tabStrip,
		})
		New("UIListLayout", {
			Padding = UDim.new(0, 4),
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = tabButtons,
		})

		pagesHolder = New("Frame", {
			Name = "Pages",
			Position = UDim2.fromOffset(0, 34),
			Size = UDim2.new(1, 0, 1, -34),
			BackgroundTransparency = 1,
			LayoutOrder = 1,
			Parent = content,
		})
	end

	local function makeTabButton(tab)
		local width = math.max(64, math.floor(string.len(tab.Name) * 7.2 + 24))
		local button = New("TextButton", {
			Size = UDim2.new(0, width, 1, -4),
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
			TextColor3 = tab.Active and Theme.Text or Theme.TextTertiary,
			TextXAlignment = Enum.TextXAlignment.Center,
			Parent = button,
		})
		tab.Button = button
		tab.ButtonLabel = buttonLabel

		button.Activated:Connect(function() selectTab(tab, true) end)
	end

	function window:AddTab(tabCfg)
		local name, default
		if type(tabCfg) == "table" then
			name = Opt(tabCfg, 1, "Name", "Tab")
			default = tabCfg.Default
		else
			name = tostring(tabCfg or "Tab")
		end

		if not tabStrip and #tabs >= 1 then
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
			ClipsDescendants = false, -- PERBAIKAN: False agar Dropdown/Colorpicker melayang mulus
			Visible = false,
			Parent = holder,
		})
		New("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = page })
		New("UIPadding", { PaddingRight = UDim.new(0, 4), Parent = page })

		local tab = { Page = page, Active = false, Name = name, Order = #tabs + 1 }
		table.insert(tabs, tab)

		if tabStrip then makeTabButton(tab) end
		if #tabs == 1 or default then selectTab(tab, false) end

		return BuildItems(page, accents)
	end
	window.CreateTab = window.AddTab

	window:SetVisible(true)
	table.insert(Library.Windows, window)
	window.Gui = gui
	return window
end

function Library:Unload()
	for _, win in ipairs(Library.Windows) do pcall(function() win:Destroy() end) end
	table.clear(Library.Windows)
	if notifyGui then notifyGui:Destroy() notifyGui = nil end
	Library.Unloaded = true
end

return Library
