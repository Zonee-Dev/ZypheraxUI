local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

local DEFAULT_LOGO = "rbxassetid://106764279090045"

-- Tokens ----------------------------------------------------------------

local Theme = {
	-- Brand
	Accent = Color3.fromRGB(0, 85, 255),

	-- Surfaces (cool graphite, no pure black or white)
	Canvas = Color3.fromRGB(13, 14, 18),
	Inset = Color3.fromRGB(16, 17, 21),
	Surface = Color3.fromRGB(24, 25, 31),
	Raised = Color3.fromRGB(31, 33, 40),
	Hover = Color3.fromRGB(38, 40, 49),
	Pressed = Color3.fromRGB(27, 29, 35),
	Track = Color3.fromRGB(52, 55, 66),

	-- Lines
	Border = Color3.fromRGB(42, 45, 54),
	BorderStrong = Color3.fromRGB(58, 62, 74),

	-- Text hierarchy
	Text = Color3.fromRGB(237, 239, 243),
	TextSecondary = Color3.fromRGB(163, 168, 180),
	TextTertiary = Color3.fromRGB(125, 130, 144),

	-- Semantic
	Discord = Color3.fromRGB(88, 101, 242),
	DiscordHover = Color3.fromRGB(105, 117, 246),
	Success = Color3.fromRGB(63, 185, 125),
	Danger = Color3.fromRGB(229, 83, 83),
}

local Radius = { XS = 4, SM = 6, MD = 8, LG = 12 }

-- Created before anything shadows the global `Font`.
local FONT_FAMILY = "rbxasset://fonts/families/Inter.json"
local Typo = {
	Regular = Font.new(FONT_FAMILY, Enum.FontWeight.Regular),
	Medium = Font.new(FONT_FAMILY, Enum.FontWeight.Medium),
	SemiBold = Font.new(FONT_FAMILY, Enum.FontWeight.SemiBold),
}

local WIDTH, HEADER, CARD_H, GAP, BAR_H = 420, 72, 340, 8, 72
local TOTAL_H = CARD_H + GAP + BAR_H
local TAB_GAP = 2

local Library = {
	Unloaded = false,
	Icons = {
		chevron = "",
		close = "",
		minimize = "",
		discord = "",
	},
}

-- Helpers ---------------------------------------------------------------

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

local function Stroke(parent, color, thickness, transparency)
	return New("UIStroke", {
		Color = color,
		Thickness = thickness or 1,
		Transparency = transparency or 0,
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

-- Icon glyph: uses an uploaded asset when set, otherwise a drawn fallback
-- with a 2px stroke. Returns the holder and a paint(color, duration) function.
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

-- Input listeners exist only while a drag is active, so nothing leaks.
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

-- Very soft ambient shadow placed behind a panel (restrained elevation).
local function Elevation(parent, position, size, radius)
	local shadow = New("Frame", {
		Name = "Elevation",
		Position = UDim2.new(position.X.Scale, position.X.Offset - 3, position.Y.Scale, position.Y.Offset),
		Size = UDim2.fromOffset(size.X + 6, size.Y + 6),
		BackgroundColor3 = Theme.Canvas,
		BackgroundTransparency = 0.7,
		BorderSizePixel = 0,
		Parent = parent,
	})
	Round(shadow, radius + 3)
	return shadow
end

-- Notifications ---------------------------------------------------------

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

	-- Status marker on the leading edge
	New("Frame", {
		Size = UDim2.new(0, 3, 1, 0),
		BackgroundColor3 = accent,
		BorderSizePixel = 0,
		Parent = toast,
	})

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

-- Compatibility with the previous library's call signature.
function Library:SetNotification(cfg)
	return self:Notify({
		Title = cfg.Title or cfg[1],
		Content = cfg.Content or cfg[3] or cfg.Description or cfg[2],
		Duration = cfg.Delay or cfg[6],
	})
end

-- Tab items -------------------------------------------------------------

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
			Position = desc and UDim2.fromOffset(12, 10) or UDim2.new(0, 12, 0.5, 0),
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
				Position = UDim2.fromOffset(12, 28),
				Size = UDim2.new(1, -(12 + rightInset), 0, 14),
				Text = desc,
				TextSize = 12,
				TextColor3 = Theme.TextSecondary,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Parent = row,
			})
		end
	end

	-- Full-row hit target with consistent hover / pressed states.
	local function Hit(row)
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
			Tween(row, 0.12, { BackgroundColor3 = Theme.Raised })
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
			Position = UDim2.fromOffset(12, 10),
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
			Position = UDim2.new(1, -12, 0, 10),
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
		Round(track, Radius.XS / 2)
		local fill = New("Frame", {
			Size = UDim2.fromScale(0, 1),
			BackgroundColor3 = accent,
			BorderSizePixel = 0,
			Parent = track,
		})
		Round(fill, Radius.XS / 2)
		local knob = New("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(1, 0.5),
			Size = UDim2.fromOffset(12, 12),
			BackgroundColor3 = Color3.fromRGB(250, 250, 252),
			BorderSizePixel = 0,
			Parent = fill,
		})
		Round(knob, 6)
		Stroke(knob, Theme.Raised, 2)

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

-- Window ----------------------------------------------------------------

-- Ghost icon button (28px, small radius). "close" gets a destructive hover.
local function IconButton(parent, position, kind)
	local destructive = kind == "close"
	local button = New("TextButton", {
		AnchorPoint = Vector2.new(1, 0),
		Position = position,
		Size = UDim2.fromOffset(28, 28),
		BackgroundColor3 = destructive and Theme.Danger or Theme.Hover,
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		Parent = parent,
	})
	Round(button, Radius.SM)

	local _, paint = Glyph(button, destructive and "close" or "minimize", Theme.TextSecondary, 16)

	button.MouseEnter:Connect(function()
		Tween(button, 0.12, { BackgroundTransparency = destructive and 0.85 or 0 })
		paint(destructive and Theme.Danger or Theme.Text, 0.12)
	end)
	button.MouseLeave:Connect(function()
		Tween(button, 0.12, { BackgroundTransparency = 1 })
		paint(Theme.TextSecondary, 0.12)
	end)
	return button
end

function Library:CreateWindow(cfg)
	cfg = cfg or {}
	local title = Opt(cfg, 1, "Title", "ZYPHERAX HUB")
	local subtitle = Opt(cfg, 2, "Description", "")
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
		Size = UDim2.fromOffset(WIDTH, TOTAL_H),
		BackgroundTransparency = 1,
		Parent = gui,
	})
	local uiScale = New("UIScale", { Parent = root })

	-- Card ---------------------------------------------------------------
	Elevation(root, UDim2.fromOffset(0, 0), Vector2.new(WIDTH, CARD_H), Radius.LG)

	local card = New("Frame", {
		Name = "Card",
		Size = UDim2.fromOffset(WIDTH, CARD_H),
		BackgroundColor3 = Theme.Surface,
		BorderSizePixel = 0,
		Parent = root,
	})
	Round(card, Radius.LG)
	Stroke(card, Theme.Border, 1)

	local dragZone = New("Frame", {
		Name = "DragZone",
		Size = UDim2.new(1, 0, 0, HEADER),
		BackgroundTransparency = 1,
		Parent = card,
	})

	-- Recessed logo well: inset surface, fine border, soft inner shadow.
	local well = New("Frame", {
		Name = "LogoWell",
		Position = UDim2.fromOffset(16, 12),
		Size = UDim2.fromOffset(48, 48),
		BackgroundColor3 = Theme.Inset,
		BorderSizePixel = 0,
		Parent = card,
	})
	Round(well, Radius.MD)
	Stroke(well, Theme.Border, 1)

	local innerShadow = New("Frame", {
		Size = UDim2.new(1, 0, 0, 14),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BorderSizePixel = 0,
		Parent = well,
	})
	Round(innerShadow, Radius.MD)
	New("UIGradient", {
		Rotation = 90,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.55),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Parent = innerShadow,
	})

	New("ImageLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(32, 32),
		BackgroundTransparency = 1,
		Image = logo,
		ScaleType = Enum.ScaleType.Fit,
		Parent = well,
	})

	-- Title block
	local titleBlock = New("Frame", {
		Position = UDim2.fromOffset(76, 0),
		Size = UDim2.new(1, -(76 + 16 + 28 + TAB_GAP * 2 + 28 + 12), 0, HEADER),
		BackgroundTransparency = 1,
		Parent = card,
	})
	New("UIListLayout", {
		Padding = UDim.new(0, 2),
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Parent = titleBlock,
	})
	Label({
		LayoutOrder = 1,
		Size = UDim2.new(1, 0, 0, 20),
		Weight = "SemiBold",
		Text = title,
		TextSize = 15,
		TextColor3 = Theme.Text,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = titleBlock,
	})
	Label({
		LayoutOrder = 2,
		Size = UDim2.new(1, 0, 0, 16),
		Text = subtitle,
		TextSize = 12,
		TextColor3 = Theme.TextSecondary,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Visible = subtitle ~= "",
		Parent = titleBlock,
	})

	local closeButton = IconButton(card, UDim2.new(1, -16, 0, 22), "close")
	local minimizeButton = IconButton(card, UDim2.new(1, -(16 + 28 + TAB_GAP * 2), 0, 22), "minimize")

	-- Header divider
	New("Frame", {
		Position = UDim2.fromOffset(0, HEADER),
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = Theme.Border,
		BorderSizePixel = 0,
		Parent = card,
	})

	-- Segmented tabs (inset track, raised selected segment)
	local tabStrip = New("Frame", {
		Position = UDim2.fromOffset(16, HEADER + 13),
		Size = UDim2.new(1, -32, 0, 32),
		BackgroundColor3 = Theme.Inset,
		BorderSizePixel = 0,
		Parent = card,
	})
	Round(tabStrip, Radius.MD)
	Stroke(tabStrip, Theme.Border, 1)
	New("UIPadding", {
		PaddingTop = UDim.new(0, 2), PaddingBottom = UDim.new(0, 2),
		PaddingLeft = UDim.new(0, 2), PaddingRight = UDim.new(0, 2),
		Parent = tabStrip,
	})
	New("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, TAB_GAP),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = tabStrip,
	})

	local content = New("Frame", {
		Position = UDim2.fromOffset(16, HEADER + 57),
		Size = UDim2.new(1, -32, 1, -(HEADER + 57 + 12)),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Parent = card,
	})

	-- Status bar ---------------------------------------------------------
	local barY = CARD_H + GAP
	Elevation(root, UDim2.fromOffset(0, barY), Vector2.new(WIDTH, BAR_H), Radius.LG)

	local bar = New("Frame", {
		Name = "StatusBar",
		Position = UDim2.fromOffset(0, barY),
		Size = UDim2.fromOffset(WIDTH, BAR_H),
		BackgroundColor3 = Theme.Surface,
		BorderSizePixel = 0,
		Parent = root,
	})
	Round(bar, Radius.LG)
	Stroke(bar, Theme.Border, 1)

	local avatar = New("ImageLabel", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 16, 0.5, 0),
		Size = UDim2.fromOffset(40, 40),
		BackgroundColor3 = Theme.Inset,
		BorderSizePixel = 0,
		Image = "",
		Parent = bar,
	})
	Round(avatar, Radius.MD)
	Stroke(avatar, Theme.Border, 1)

	task.spawn(function()
		local ok, image = pcall(
			Players.GetUserThumbnailAsync, Players,
			LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100
		)
		if ok then
			avatar.Image = image
		end
	end)

	local info = New("Frame", {
		Position = UDim2.fromOffset(68, 0),
		Size = UDim2.new(1, -(68 + (discord and 124 or 16)), 1, 0),
		BackgroundTransparency = 1,
		Parent = bar,
	})
	New("UIListLayout", {
		Padding = UDim.new(0, 1),
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Parent = info,
	})

	Label({
		LayoutOrder = 1,
		Size = UDim2.new(1, 0, 0, 16),
		Weight = "SemiBold",
		Text = cfg.Username or LocalPlayer.Name,
		TextSize = 13,
		TextColor3 = Theme.Text,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = info,
	})
	Label({
		LayoutOrder = 2,
		Size = UDim2.new(1, 0, 0, 14),
		RichText = true,
		Text = string.format(
			'<font color="#%s">ID</font>  %s',
			Theme.TextTertiary:ToHex(),
			tostring(cfg.UserId or LocalPlayer.UserId)
		),
		TextSize = 12,
		TextColor3 = Theme.TextSecondary,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = info,
	})

	local statusRow = New("Frame", {
		LayoutOrder = 3,
		Size = UDim2.new(1, 0, 0, 14),
		BackgroundTransparency = 1,
		Parent = info,
	})
	local statusDot = New("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.fromOffset(6, 6),
		BackgroundColor3 = Theme.Success,
		BorderSizePixel = 0,
		Parent = statusRow,
	})
	Round(statusDot, 3)
	local statusLabel = Label({
		Position = UDim2.fromOffset(12, 0),
		Size = UDim2.new(1, -12, 1, 0),
		Weight = "Medium",
		TextSize = 12,
		TextColor3 = Theme.TextSecondary,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = statusRow,
	})

	function window:SetStatus(text, color)
		statusLabel.Text = text
		statusDot.BackgroundColor3 = color or Theme.Success
	end
	window:SetStatus(cfg.Status or "No-Key Script", cfg.StatusColor)

	if discord then
		local button = New("TextButton", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -16, 0.5, 0),
			Size = UDim2.fromOffset(96, 32),
			BackgroundColor3 = Theme.Discord,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Text = "",
			Parent = bar,
		})
		Round(button, Radius.SM)
		local press = New("UIScale", { Parent = button })

		local inner = New("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Parent = button,
		})
		New("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 6),
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = inner,
		})

		local discordIcon = Library.Icons.discord
		if discordIcon and discordIcon ~= "" then
			New("ImageLabel", {
				LayoutOrder = 1,
				Size = UDim2.fromOffset(16, 16),
				BackgroundTransparency = 1,
				Image = discordIcon,
				ImageColor3 = Color3.fromRGB(255, 255, 255),
				ScaleType = Enum.ScaleType.Fit,
				Parent = inner,
			})
		end
		Label({
			LayoutOrder = 2,
			Size = UDim2.fromOffset(0, 16),
			AutomaticSize = Enum.AutomaticSize.X,
			Weight = "SemiBold",
			Text = "Discord",
			TextSize = 12,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			Parent = inner,
		})

		button.MouseEnter:Connect(function()
			Tween(button, 0.12, { BackgroundColor3 = Theme.DiscordHover })
		end)
		button.MouseLeave:Connect(function()
			Tween(button, 0.12, { BackgroundColor3 = Theme.Discord })
		end)
		button.MouseButton1Down:Connect(function()
			Tween(press, 0.06, { Scale = 0.97 })
		end)
		button.MouseButton1Up:Connect(function()
			Tween(press, 0.1, { Scale = 1 })
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

	-- Dragging
	MakeDraggable(dragZone, root, uiScale)
	MakeDraggable(bar, root, uiScale)

	-- Launcher shown while minimized
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
	Round(launcher, Radius.LG)
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

	-- Visibility and scaling
	local baseScale, visible = ViewportScale(), true

	function window:SetVisible(show)
		visible = show
		launcher.Visible = not show
		root.Visible = show
		if show then
			uiScale.Scale = baseScale * 0.96
			Tween(uiScale, 0.2, { Scale = baseScale }, Enum.EasingStyle.Quint)
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

	minimizeButton.Activated:Connect(function()
		window:SetVisible(false)
	end)
	closeButton.Activated:Connect(function()
		window:Destroy()
	end)
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

	-- Tabs
	local tabs = {}

	local function selectTab(selected)
		for _, tab in ipairs(tabs) do
			local active = tab == selected
			tab.Active = active
			tab.Page.Visible = active
			Tween(tab.Button, 0.15, {
				BackgroundTransparency = active and 0 or 1,
				TextColor3 = active and Theme.Text or Theme.TextSecondary,
			})
			Tween(tab.Stroke, 0.15, { Transparency = active and 0 or 1 })
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
			ScrollBarThickness = 2,
			ScrollBarImageColor3 = accent,
			Visible = false,
			Parent = content,
		})
		New("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = page })
		New("UIPadding", { PaddingRight = UDim.new(0, 8), Parent = page })

		local button = New("TextButton", {
			LayoutOrder = #tabs + 1,
			BackgroundColor3 = Theme.Raised,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			FontFace = Typo.Medium,
			Text = name,
			TextSize = 12,
			TextColor3 = Theme.TextSecondary,
			Parent = tabStrip,
		})
		Round(button, Radius.SM)
		local buttonStroke = Stroke(button, Theme.BorderStrong, 1, 1)

		local tab = { Page = page, Button = button, Stroke = buttonStroke, Active = false }
		table.insert(tabs, tab)

		local count = #tabs
		for _, existing in ipairs(tabs) do
			existing.Button.Size = UDim2.new(1 / count, -(TAB_GAP * (count - 1)) / count, 1, 0)
		end

		button.MouseEnter:Connect(function()
			if not tab.Active then
				Tween(button, 0.12, { TextColor3 = Theme.Text })
			end
		end)
		button.MouseLeave:Connect(function()
			if not tab.Active then
				Tween(button, 0.12, { TextColor3 = Theme.TextSecondary })
			end
		end)
		button.Activated:Connect(function()
			selectTab(tab)
		end)
		if count == 1 then
			selectTab(tab)
		end

		return BuildItems(page, accent)
	end
	window.CreateTab = window.AddTab

	return window
end

return Library
