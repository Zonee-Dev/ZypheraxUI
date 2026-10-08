--[[
	Zypherax Hub - Status UI
	Layout: logo badge, content card, user status bar.
	Item API (AddButton, AddToggle, AddSlider) uses the same positional
	arguments as the old library, so existing scripts port over directly.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

local DEFAULT_LOGO = "rbxassetid://106764279090045"

local Theme = {
	Accent = Color3.fromRGB(0, 85, 255),
	Surface = Color3.fromRGB(38, 38, 45),
	Raised = Color3.fromRGB(49, 49, 58),
	Hover = Color3.fromRGB(58, 58, 69),
	Track = Color3.fromRGB(70, 70, 82),
	Badge = Color3.fromRGB(242, 242, 242),
	Text = Color3.fromRGB(245, 245, 247),
	Muted = Color3.fromRGB(160, 160, 172),
	Discord = Color3.fromRGB(88, 101, 242),
	DiscordHover = Color3.fromRGB(107, 119, 245),
	Success = Color3.fromRGB(67, 181, 129),
	Danger = Color3.fromRGB(237, 66, 69),
}

local Font = {
	Regular = Enum.Font.GothamMedium,
	Bold = Enum.Font.GothamBold,
}

local WIDTH, CARD_H, BADGE, GAP, BAR_H = 420, 330, 96, 10, 68
local TOTAL_H = BADGE / 2 + CARD_H + GAP + BAR_H

local Library = { Unloaded = false }

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
		Thickness = thickness,
		Transparency = transparency or 0,
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
	return math.clamp(math.min(viewport.X / 520, viewport.Y / 560), 0.6, 1)
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
		Position = UDim2.new(1, -20, 1, -20),
		Size = UDim2.new(0, 290, 1, -40),
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
	Round(toast, 14)
	Stroke(toast, accent, 1.5)
	New("UIPadding", {
		PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, 12),
		PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14),
		Parent = toast,
	})
	New("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder, Parent = toast })

	New("TextLabel", {
		LayoutOrder = 1,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Font = Font.Bold,
		Text = title,
		TextSize = 13,
		TextColor3 = Theme.Text,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = toast,
	})
	if content ~= "" then
		New("TextLabel", {
			LayoutOrder = 2,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Font = Font.Regular,
			Text = content,
			TextSize = 12,
			TextColor3 = Theme.Muted,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = toast,
		})
	end

	local closed = false
	local function dismiss()
		if closed then
			return
		end
		closed = true
		Tween(toast, 0.25, { GroupTransparency = 1 })
		task.delay(0.3, function()
			toast:Destroy()
		end)
	end

	toast.InputBegan:Connect(function(input)
		if IsPointer(input) then
			dismiss()
		end
	end)

	Tween(toast, 0.25, { GroupTransparency = 0 })
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
		Round(row, 10)
		return row
	end

	local function Titles(row, title, desc, rightInset)
		local width = UDim2.new(1, -(14 + rightInset), 0, 16)
		New("TextLabel", {
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0, desc and 0 or 0.5),
			Position = desc and UDim2.fromOffset(14, 9) or UDim2.new(0, 14, 0.5, 0),
			Size = width,
			Font = Font.Bold,
			Text = title,
			TextSize = 13,
			TextColor3 = Theme.Text,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = row,
		})
		if desc then
			New("TextLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(14, 27),
				Size = UDim2.new(1, -(14 + rightInset), 0, 14),
				Font = Font.Regular,
				Text = desc,
				TextSize = 11,
				TextColor3 = Theme.Muted,
				TextXAlignment = Enum.TextXAlignment.Left,
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
			Tween(row, 0.15, { BackgroundColor3 = Theme.Hover })
		end)
		hit.MouseLeave:Connect(function()
			Tween(row, 0.15, { BackgroundColor3 = Theme.Raised })
		end)
		return hit
	end

	function items:AddSection(title)
		New("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 18),
			LayoutOrder = nextOrder(),
			Font = Font.Bold,
			Text = string.upper(title or ""),
			TextSize = 11,
			TextColor3 = Theme.Muted,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = page,
		})
		return self
	end

	function items:AddLabel(text)
		local label = New("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			LayoutOrder = nextOrder(),
			Font = Font.Regular,
			Text = text or "",
			TextSize = 12,
			TextColor3 = Theme.Muted,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
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
		Titles(row, title, desc, 36)
		New("TextLabel", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -14, 0.5, 0),
			Size = UDim2.fromOffset(12, 16),
			BackgroundTransparency = 1,
			Font = Font.Bold,
			Text = ">",
			TextSize = 13,
			TextColor3 = accent,
			Parent = row,
		})

		Hit(row).Activated:Connect(function()
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
		Titles(row, title, desc, 62)

		local track = New("Frame", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -14, 0.5, 0),
			Size = UDim2.fromOffset(38, 22),
			BackgroundColor3 = Theme.Track,
			BorderSizePixel = 0,
			Parent = row,
		})
		Round(track, 11)
		local knob = New("Frame", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 3, 0.5, 0),
			Size = UDim2.fromOffset(16, 16),
			BackgroundColor3 = Theme.Text,
			BorderSizePixel = 0,
			Parent = track,
		})
		Round(knob, 8)

		local function render(animate)
			local props = { BackgroundColor3 = obj.Value and accent or Theme.Track }
			local knobProps = { Position = UDim2.new(0, obj.Value and 19 or 3, 0.5, 0) }
			if animate then
				Tween(track, 0.18, props)
				Tween(knob, 0.18, knobProps)
			else
				track.BackgroundColor3 = props.BackgroundColor3
				knob.Position = knobProps.Position
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
		local row = Row(54)

		New("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(14, 9),
			Size = UDim2.new(1, -80, 0, 16),
			Font = Font.Bold,
			Text = title,
			TextSize = 13,
			TextColor3 = Theme.Text,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = row,
		})
		local valueLabel = New("TextLabel", {
			AnchorPoint = Vector2.new(1, 0),
			BackgroundTransparency = 1,
			Position = UDim2.new(1, -14, 0, 9),
			Size = UDim2.fromOffset(56, 16),
			Font = Font.Bold,
			TextSize = 12,
			TextColor3 = accent,
			TextXAlignment = Enum.TextXAlignment.Right,
			Parent = row,
		})

		local track = New("Frame", {
			Position = UDim2.fromOffset(14, 37),
			Size = UDim2.new(1, -28, 0, 6),
			BackgroundColor3 = Theme.Track,
			BorderSizePixel = 0,
			Parent = row,
		})
		Round(track, 3)
		local fill = New("Frame", {
			Size = UDim2.fromScale(0, 1),
			BackgroundColor3 = accent,
			BorderSizePixel = 0,
			Parent = track,
		})
		Round(fill, 3)
		local knob = New("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(1, 0.5),
			Size = UDim2.fromOffset(12, 12),
			BackgroundColor3 = Theme.Text,
			BorderSizePixel = 0,
			Parent = fill,
		})
		Round(knob, 6)

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
			Position = UDim2.fromOffset(14, 28),
			Size = UDim2.new(1, -28, 0, 24),
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

local function IconButton(parent, position, kind)
	local button = New("TextButton", {
		AnchorPoint = Vector2.new(1, 0),
		Position = position,
		Size = UDim2.fromOffset(28, 28),
		BackgroundColor3 = kind == "close" and Theme.Danger or Theme.Raised,
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		Parent = parent,
	})
	Round(button, 8)

	local bars = {}
	local function bar(width, rotation)
		local frame = New("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(width, 2),
			Rotation = rotation,
			BackgroundColor3 = Theme.Muted,
			BorderSizePixel = 0,
			Parent = button,
		})
		Round(frame, 1)
		table.insert(bars, frame)
	end

	if kind == "close" then
		bar(13, 45)
		bar(13, -45)
	else
		bar(10, 0)
	end

	button.MouseEnter:Connect(function()
		Tween(button, 0.12, { BackgroundTransparency = 0 })
		for _, frame in ipairs(bars) do
			Tween(frame, 0.12, { BackgroundColor3 = Theme.Text })
		end
	end)
	button.MouseLeave:Connect(function()
		Tween(button, 0.12, { BackgroundTransparency = 1 })
		for _, frame in ipairs(bars) do
			Tween(frame, 0.12, { BackgroundColor3 = Theme.Muted })
		end
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

	-- Card
	local card = New("Frame", {
		Name = "Card",
		Position = UDim2.fromOffset(0, BADGE / 2),
		Size = UDim2.fromOffset(WIDTH, CARD_H),
		BackgroundColor3 = Theme.Surface,
		BorderSizePixel = 0,
		Parent = root,
	})
	Round(card, 26)
	Stroke(card, accent, 1.5)

	local dragZone = New("Frame", {
		Name = "DragZone",
		Size = UDim2.new(1, 0, 0, 96),
		BackgroundTransparency = 1,
		Parent = card,
	})

	New("TextLabel", {
		Position = UDim2.fromOffset(0, 54),
		Size = UDim2.new(1, 0, 0, 20),
		BackgroundTransparency = 1,
		Font = Font.Bold,
		Text = title,
		TextSize = 16,
		TextColor3 = Theme.Text,
		Parent = card,
	})
	New("TextLabel", {
		Position = UDim2.fromOffset(0, 74),
		Size = UDim2.new(1, 0, 0, 16),
		BackgroundTransparency = 1,
		Font = Font.Regular,
		Text = subtitle,
		TextSize = 12,
		TextColor3 = Theme.Muted,
		Parent = card,
	})

	local closeButton = IconButton(card, UDim2.new(1, -16, 0, 16), "close")
	local minimizeButton = IconButton(card, UDim2.new(1, -50, 0, 16), "minimize")

	local tabStrip = New("Frame", {
		Position = UDim2.fromOffset(16, 100),
		Size = UDim2.new(1, -32, 0, 34),
		BackgroundColor3 = Theme.Raised,
		BorderSizePixel = 0,
		Parent = card,
	})
	Round(tabStrip, 10)
	New("UIPadding", {
		PaddingTop = UDim.new(0, 3), PaddingBottom = UDim.new(0, 3),
		PaddingLeft = UDim.new(0, 3), PaddingRight = UDim.new(0, 3),
		Parent = tabStrip,
	})
	New("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = tabStrip,
	})

	local content = New("Frame", {
		Position = UDim2.fromOffset(16, 146),
		Size = UDim2.new(1, -32, 1, -162),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Parent = card,
	})

	-- Badge
	local badge = New("Frame", {
		Name = "Badge",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0),
		Size = UDim2.fromOffset(BADGE, BADGE),
		BackgroundColor3 = Theme.Badge,
		BorderSizePixel = 0,
		ZIndex = 5,
		Parent = root,
	})
	Round(badge, BADGE / 2)
	local badgeInner = New("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(BADGE - 20, BADGE - 20),
		BackgroundColor3 = Theme.Surface,
		BorderSizePixel = 0,
		Parent = badge,
	})
	Round(badgeInner, (BADGE - 20) / 2)
	Stroke(badgeInner, accent, 2)
	New("ImageLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(44, 44),
		BackgroundTransparency = 1,
		Image = logo,
		ScaleType = Enum.ScaleType.Fit,
		Parent = badgeInner,
	})

	-- Status bar
	local bar = New("Frame", {
		Name = "StatusBar",
		Position = UDim2.fromOffset(0, BADGE / 2 + CARD_H + GAP),
		Size = UDim2.fromOffset(WIDTH, BAR_H),
		BackgroundColor3 = Theme.Surface,
		BorderSizePixel = 0,
		Parent = root,
	})
	Round(bar, 22)
	Stroke(bar, accent, 1.5)

	local avatar = New("ImageLabel", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 14, 0.5, 0),
		Size = UDim2.fromOffset(46, 46),
		BackgroundColor3 = Theme.Raised,
		BorderSizePixel = 0,
		Image = "",
		Parent = bar,
	})
	Round(avatar, 23)
	Stroke(avatar, Theme.Badge, 2)

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
		Position = UDim2.fromOffset(72, 0),
		Size = UDim2.new(1, -(72 + (discord and 126 or 14)), 1, 0),
		BackgroundTransparency = 1,
		Parent = bar,
	})
	New("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Parent = info,
	})

	local function infoLine(order, bold)
		return New("TextLabel", {
			LayoutOrder = order,
			Size = UDim2.new(1, 0, 0, 14),
			BackgroundTransparency = 1,
			Font = bold and Font.Bold or Font.Regular,
			RichText = true,
			Text = "",
			TextSize = bold and 12 or 11,
			TextColor3 = bold and Theme.Text or Theme.Muted,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = info,
		})
	end

	local function pair(label, value, color)
		return string.format('%s : <font color="#%s">%s</font>', label, color:ToHex(), value)
	end

	local heading = infoLine(1, true)
	heading.Text = "USER STATUS"
	infoLine(2).Text = pair("Username", cfg.Username or LocalPlayer.Name, Theme.Text)
	infoLine(3).Text = pair("ID", tostring(cfg.UserId or LocalPlayer.UserId), Theme.Text)
	local statusLine = infoLine(4)

	function window:SetStatus(text, color)
		statusLine.Text = pair("Status", text, color or Theme.Success)
	end
	window:SetStatus(cfg.Status or "No-Key Script", cfg.StatusColor)

	if discord then
		local button = New("TextButton", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -16, 0.5, 0),
			Size = UDim2.fromOffset(98, 34),
			BackgroundColor3 = Theme.Discord,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Font = Font.Bold,
			Text = "Discord",
			TextSize = 13,
			TextColor3 = Theme.Text,
			Parent = bar,
		})
		Round(button, 17)
		local press = New("UIScale", { Parent = button })

		button.MouseEnter:Connect(function()
			Tween(button, 0.15, { BackgroundColor3 = Theme.DiscordHover })
		end)
		button.MouseLeave:Connect(function()
			Tween(button, 0.15, { BackgroundColor3 = Theme.Discord })
		end)
		button.MouseButton1Down:Connect(function()
			Tween(press, 0.08, { Scale = 0.95 })
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

	-- Dragging
	MakeDraggable(dragZone, root, uiScale)
	MakeDraggable(badge, root, uiScale)
	MakeDraggable(bar, root, uiScale)

	-- Launcher shown while minimized
	local launcher = New("ImageButton", {
		Name = "Launcher",
		Position = UDim2.new(0, 20, 0.5, -26),
		Size = UDim2.fromOffset(52, 52),
		BackgroundColor3 = Theme.Surface,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Image = "",
		Visible = false,
		Parent = gui,
	})
	Round(launcher, 26)
	Stroke(launcher, accent, 2)
	New("ImageLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(30, 30),
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
			uiScale.Scale = baseScale * 0.94
			Tween(uiScale, 0.22, { Scale = baseScale }, Enum.EasingStyle.Back)
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

	local function select(selected)
		for _, tab in ipairs(tabs) do
			local active = tab == selected
			tab.Page.Visible = active
			Tween(tab.Button, 0.15, {
				BackgroundTransparency = active and 0 or 1,
				TextColor3 = active and Theme.Text or Theme.Muted,
			})
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
		New("UIPadding", { PaddingRight = UDim.new(0, 6), Parent = page })

		local button = New("TextButton", {
			LayoutOrder = #tabs + 1,
			BackgroundColor3 = accent,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Font = Font.Bold,
			Text = name,
			TextSize = 12,
			TextColor3 = Theme.Muted,
			Parent = tabStrip,
		})
		Round(button, 8)

		local tab = { Page = page, Button = button }
		table.insert(tabs, tab)

		local count = #tabs
		for _, existing in ipairs(tabs) do
			existing.Button.Size = UDim2.new(1 / count, -(4 * (count - 1)) / count, 1, 0)
		end

		button.Activated:Connect(function()
			select(tab)
		end)
		if count == 1 then
			select(tab)
		end

		return BuildItems(page, accent)
	end
	window.CreateTab = window.AddTab

	return window
end

return Library
