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

-- Diubah agar proporsional dengan gambar
local WIDTH, CARD_H, GAP, BAR_H = 420, 320, 10, 80
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

	-- Card Utama ---------------------------------------------------------
	Elevation(root, UDim2.fromOffset(0, 0), Vector2.new(WIDTH, CARD_H), Radius.LG)

	local card = New("Frame", {
		Name = "Card",
		Size = UDim2.fromOffset(WIDTH, CARD_H),
		BackgroundColor3 = Theme.Surface,
		BorderSizePixel = 0,
		Parent = root,
	})
	Round(card, Radius.LG)
	Stroke(card, Theme.Accent, 2) -- Border biru sesuai gambar

	-- Logo Melingkar di Tengah Atas (Overlapping) -------------------------
	local logoCircle = New("Frame", {
		Name = "LogoCircle",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0, 0), -- Di tengah atas card
		Size = UDim2.fromOffset(86, 86),
		BackgroundColor3 = Theme.Surface,
		BorderSizePixel = 0,
		ZIndex = 2,
		Parent = root,
	})
	Round(logoCircle, 43)
	Stroke(logoCircle, Color3.fromRGB(255, 255, 255), 4) -- Ring putih luar

	-- Ring biru dalam
	local innerRing = New("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.85, 0.85),
		BackgroundColor3 = Theme.Canvas, -- Warna gelap di dalam
		BorderSizePixel = 0,
		ZIndex = 3,
		Parent = logoCircle,
	})
	Round(innerRing, 36)
	Stroke(innerRing, Theme.Accent, 2) -- Ring biru dalam

	-- Gambar Logo
	New("ImageLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(45, 45),
		BackgroundTransparency = 1,
		Image = logo,
		ScaleType = Enum.ScaleType.Fit,
		ZIndex = 4,
		Parent = innerRing,
	})

	-- Area Konten Utama ---------------------------------------------------
	local content = New("Frame", {
		Position = UDim2.fromOffset(16, 50), -- Memberi ruang untuk logo di atas
		Size = UDim2.new(1, -32, 1, -66),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		ZIndex = 1,
		Parent = card,
	})

	-- Status Bar ----------------------------------------------------------
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
	Stroke(bar, Theme.Accent, 2) -- Border biru

	local avatar = New("ImageLabel", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 16, 0.5, 0),
		Size = UDim2.fromOffset(52, 52),
		BackgroundColor3 = Theme.Inset,
		BorderSizePixel = 0,
		Image = "",
		Parent = bar,
	})
	Round(avatar, 26) -- Avatar bulat
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
		Position = UDim2.fromOffset(80, 0),
		Size = UDim2.new(1, -(80 + (discord and 130 or 16)), 1, 0),
		BackgroundTransparency = 1,
		Parent = bar,
	})
	New("UIListLayout", {
		Padding = UDim.new(0, 3),
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Parent = info,
	})

	-- Teks Status sesuai gambar
	Label({
		LayoutOrder = 1,
		Size = UDim2.new(1, 0, 0, 16),
		Weight = "SemiBold",
		Text = "USER STATUS",
		TextSize = 13,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = info,
	})
	Label({
		LayoutOrder = 2,
		Size = UDim2.new(1, 0, 0, 14),
		Text = "Username : " .. (cfg.Username or LocalPlayer.Name),
		TextSize = 12,
		TextColor3 = Theme.TextSecondary,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = info,
	})
	Label({
		LayoutOrder = 3,
		Size = UDim2.new(1, 0, 0, 14),
		Text = "ID : " .. tostring(cfg.UserId or LocalPlayer.UserId),
		TextSize = 12,
		TextColor3 = Theme.TextSecondary,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = info,
	})
	Label({
		LayoutOrder = 4,
		Size = UDim2.new(1, 0, 0, 14),
		Text = "Status : " .. (cfg.Status or "No-Key Script"),
		TextSize = 12,
		TextColor3 = Theme.TextSecondary,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = info,
	})

	if discord then
		local button = New("TextButton", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -16, 0.5, 0),
			Size = UDim2.fromOffset(110, 38),
			BackgroundColor3 = Theme.Discord,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Text = "discord",
			FontFace = Typo.Medium,
			TextSize = 14,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			Parent = bar,
		})
		Round(button, 19) -- Membuat tombol pill
		local press = New("UIScale", { Parent = button })

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
	local dragZone = New("Frame", {
		Name = "DragZone",
		Size = UDim2.new(1, 0, 0, 50),
		BackgroundTransparency = 1,
		ZIndex = 1,
		Parent = card,
	})
	MakeDraggable(dragZone, root, uiScale)
	MakeDraggable(bar, root, uiScale)

	-- Launcher
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

		local tab = { Page = page, Active = false }
		table.insert(tabs, tab)

		if #tabs == 1 then
			selectTab(tab)
		end

		return BuildItems(page, accent)
	end
	window.CreateTab = window.AddTab

	return window
end

return Library
