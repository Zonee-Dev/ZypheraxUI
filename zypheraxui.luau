local ZypheraxUI = {}
ZypheraxUI.Version = "Enterprise 1.0.0"

-- // SERVICES \\ --
local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")

-- // THEME (Blended Lyapos & Airflow Aesthetics) \\ --
local Theme = {
    Background = Color3.fromRGB(12, 12, 15),
    Surface = Color3.fromRGB(20, 20, 25),
    Surface2 = Color3.fromRGB(28, 28, 35),
    Accent = Color3.fromRGB(0, 195, 255),
    AccentDark = Color3.fromRGB(0, 140, 200),
    Text = Color3.fromRGB(245, 245, 245),
    TextMuted = Color3.fromRGB(160, 160, 170),
    Stroke = Color3.fromRGB(45, 45, 55),
    StrokeHover = Color3.fromRGB(80, 80, 95),
    Warning = Color3.fromRGB(240, 176, 108),
    Success = Color3.fromRGB(150, 220, 170),
    Error = Color3.fromRGB(240, 120, 120),
    CornerRadius = UDim.new(0, 8),
    FontBold = Enum.Font.GothamBold,
    FontRegular = Enum.Font.Gotham,
}

-- // UTILITIES (Speed Hub Performance Style) \\ --
local Custom = {} do
    function Custom:Create(ClassName, Properties)
        local _instance = Instance.new(ClassName)
        for i, v in pairs(Properties) do
            if i ~= "Parent" then
                _instance[i] = v
            end
        end
        if Properties.Parent then
            _instance.Parent = Properties.Parent
        end
        return _instance
    end

    function Custom:ApplyStroke(UIElement, Transparency)
        return Custom:Create("UIStroke", {
            Color = Theme.Stroke,
            Thickness = 1.2,
            Transparency = Transparency or 0,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            Parent = UIElement
        })
    end

    function Custom:ApplyCorner(UIElement, Radius)
        return Custom:Create("UICorner", {
            CornerRadius = Radius or Theme.CornerRadius,
            Parent = UIElement
        })
    end

    function Custom:Tween(Instance, Info, Properties)
        local _tween = TweenService:Create(Instance, Info, Properties)
        _tween:Play()
        return _tween
    end

    function Custom:EnabledAFK()
        if not Player then return end
        Player.Idled:Connect(function()
            VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
            task.wait(1)
            VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
        end)
    end

    function Custom:MakeDraggable(TopBar, Window)
        local dragging, dragStart, startPos = false, nil, nil

        TopBar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = Window.Position

                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end)

        TopBar.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position - dragStart
                Window.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end)
    end

    function Custom:CircleClick(Button, X, Y)
        task.spawn(function()
            Button.ClipsDescendants = true
            local Circle = Custom:Create("ImageLabel", {
                Image = "rbxassetid://106471194043211",
                ImageColor3 = Theme.Accent,
                ImageTransparency = 0.8,
                BackgroundTransparency = 1,
                ZIndex = 10,
                Parent = Button
            })
            
            local NewX = X - Button.AbsolutePosition.X
            local NewY = Y - Button.AbsolutePosition.Y
            Circle.Position = UDim2.new(0, NewX, 0, NewY)

            local Size = math.max(Button.AbsoluteSize.X, Button.AbsoluteSize.Y) * 1.5
            local Time = 0.4
            
            local Tween = Custom:Tween(Circle, TweenInfo.new(Time, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, Size, 0, Size),
                Position = UDim2.new(0.5, -Size/2, 0.5, -Size/2),
                ImageTransparency = 1
            })
            
            Tween.Completed:Connect(function()
                Circle:Destroy()
            end)
        end)
    end
end
Custom:EnabledAFK()

-- // NOTIFICATION SYSTEM \\ --
ZypheraxUI.Notifications = {}
function ZypheraxUI:Notify(Config)
    local Title = Config.Title or "Notification"
    local Content = Config.Content or "Message..."
    local Duration = Config.Duration or 5
    
    local Core = RunService:IsStudio() and Player.PlayerGui or (gethui() or cloneref(game:GetService("CoreGui")) or game:GetService("CoreGui"))
    local ScreenGui = Core:FindFirstChild("ZypheraxNotifs")
    if not ScreenGui then
        ScreenGui = Custom:Create("ScreenGui", { Name = "ZypheraxNotifs", ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = Core })
    end

    local NotifFrame = Custom:Create("Frame", {
        Size = UDim2.new(0, 300, 0, 70),
        Position = UDim2.new(1, 20, 1, -80 - (#ScreenGui:GetChildren() * 80)),
        BackgroundColor3 = Theme.Surface,
        BackgroundTransparency = 0.1,
        Parent = ScreenGui
    })
    Custom:ApplyCorner(NotifFrame, UDim.new(0, 6))
    Custom:ApplyStroke(NotifFrame, 0)
    
    local Glow = Custom:Create("ImageLabel", {
        Image = "rbxassetid://6014261993",
        ImageColor3 = Theme.Accent,
        ImageTransparency = 0.8,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 40, 1, 40),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(49, 49, 450, 450),
        ZIndex = 0,
        Parent = NotifFrame
    })

    local TitleLbl = Custom:Create("TextLabel", {
        Text = Title,
        Font = Theme.FontBold,
        TextSize = 14,
        TextColor3 = Theme.Text,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 15, 0, 10),
        Size = UDim2.new(1, -30, 0, 20),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = NotifFrame
    })

    local ContentLbl = Custom:Create("TextLabel", {
        Text = Content,
        Font = Theme.FontRegular,
        TextSize = 13,
        TextColor3 = Theme.TextMuted,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 15, 0, 30),
        Size = UDim2.new(1, -30, 0, 30),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true,
        Parent = NotifFrame
    })
    
    local Line = Custom:Create("Frame", {
        Size = UDim2.new(0, 0, 0, 2),
        Position = UDim2.new(0, 10, 1, -2),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        Parent = NotifFrame
    })

    Custom:Tween(NotifFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Position = UDim2.new(1, -320, 1, -80 - (#ScreenGui:GetChildren() * 80)) })
    Custom:Tween(Line, TweenInfo.new(Duration, Enum.EasingStyle.Linear), { Size = UDim2.new(1, -20, 0, 2) })

    task.delay(Duration, function()
        local out = Custom:Tween(NotifFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In), { Position = UDim2.new(1, 20, NotifFrame.Position.Y.Scale, NotifFrame.Position.Y.Offset) })
        out.Completed:Connect(function() NotifFrame:Destroy() end)
    end)
end

-- // CORE WINDOW GENERATOR \\ --
function ZypheraxUI:CreateWindow(Config)
    local Title = Config.Title or "Zypherax UI"
    local Description = Config.Description or "Enterprise Edition"
    local SizeUi = Config.Size or UDim2.fromOffset(600, 400)

    local Core = RunService:IsStudio() and Player.PlayerGui or (gethui() or cloneref(game:GetService("CoreGui")) or game:GetService("CoreGui"))
    local ScreenGui = Custom:Create("ScreenGui", { Name = "ZypheraxApp", ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = Core })

    local DropShadow = Custom:Create("ImageLabel", {
        Image = "rbxassetid://6014261993",
        ImageColor3 = Color3.new(0, 0, 0),
        ImageTransparency = 0.4,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(49, 49, 450, 450),
        BackgroundTransparency = 1,
        Size = UDim2.new(0, SizeUi.X.Offset + 60, 0, SizeUi.Y.Offset + 60),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Parent = ScreenGui
    })

    local Main = Custom:Create("Frame", {
        Size = SizeUi,
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Theme.Background,
        BackgroundTransparency = 0.05,
        Parent = DropShadow
    })
    Custom:ApplyCorner(Main)
    Custom:ApplyStroke(Main, 0)

    local TopBar = Custom:Create("Frame", {
        Size = UDim2.new(1, 0, 0, 45),
        BackgroundColor3 = Theme.Surface,
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        Parent = Main
    })
    Custom:ApplyCorner(TopBar)
    
    local TopBarLine = Custom:Create("Frame", {
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = Theme.Stroke,
        BorderSizePixel = 0,
        Parent = TopBar
    })

    local TitleLbl = Custom:Create("TextLabel", {
        Text = Title,
        Font = Theme.FontBold,
        TextSize = 16,
        TextColor3 = Theme.Accent,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 15, 0, 0),
        Size = UDim2.new(0, 0, 1, 0),
        AutomaticSize = Enum.AutomaticSize.X,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = TopBar
    })

    local DescLbl = Custom:Create("TextLabel", {
        Text = " - " .. Description,
        Font = Theme.FontRegular,
        TextSize = 13,
        TextColor3 = Theme.TextMuted,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 15 + TitleLbl.TextBounds.X + 5, 0, 0),
        Size = UDim2.new(0, 0, 1, 0),
        AutomaticSize = Enum.AutomaticSize.X,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = TopBar
    })
    
    -- Dynamic update description position
    TitleLbl:GetPropertyChangedSignal("TextBounds"):Connect(function()
        DescLbl.Position = UDim2.new(0, 15 + TitleLbl.TextBounds.X + 5, 0, 0)
    end)

    local CloseBtn = Custom:Create("TextButton", {
        Text = "X",
        Font = Theme.FontBold,
        TextSize = 14,
        TextColor3 = Theme.TextMuted,
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -40, 0, 10),
        Size = UDim2.new(0, 25, 0, 25),
        Parent = TopBar
    })
    CloseBtn.MouseEnter:Connect(function() Custom:Tween(CloseBtn, TweenInfo.new(0.2), { TextColor3 = Theme.Error }) end)
    CloseBtn.MouseLeave:Connect(function() Custom:Tween(CloseBtn, TweenInfo.new(0.2), { TextColor3 = Theme.TextMuted }) end)
    CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

    Custom:MakeDraggable(TopBar, DropShadow)

    local Sidebar = Custom:Create("Frame", {
        Size = UDim2.new(0, 140, 1, -46),
        Position = UDim2.new(0, 0, 0, 46),
        BackgroundColor3 = Theme.Background,
        BackgroundTransparency = 1,
        Parent = Main
    })
    
    local SidebarLine = Custom:Create("Frame", {
        Size = UDim2.new(0, 1, 1, 0),
        Position = UDim2.new(1, 0, 0, 0),
        BackgroundColor3 = Theme.Stroke,
        BorderSizePixel = 0,
        Parent = Sidebar
    })

    local TabList = Custom:Create("ScrollingFrame", {
        Size = UDim2.new(1, 0, 1, -20),
        Position = UDim2.new(0, 0, 0, 10),
        BackgroundTransparency = 1,
        ScrollBarThickness = 0,
        Parent = Sidebar
    })
    Custom:Create("UIListLayout", { Parent = TabList, Padding = UDim.new(0, 5), HorizontalAlignment = Enum.HorizontalAlignment.Center })

    local ContentContainer = Custom:Create("Frame", {
        Size = UDim2.new(1, -141, 1, -46),
        Position = UDim2.new(0, 141, 0, 46),
        BackgroundTransparency = 1,
        Parent = Main
    })

    local WindowObj = {
        Tabs = {},
        CurrentTab = nil
    }

    function WindowObj:CreateTab(TabName)
        local TabBtn = Custom:Create("TextButton", {
            Size = UDim2.new(1, -20, 0, 32),
            BackgroundColor3 = Theme.Surface,
            BackgroundTransparency = 1,
            Text = TabName,
            Font = Theme.FontBold,
            TextSize = 13,
            TextColor3 = Theme.TextMuted,
            Parent = TabList
        })
        Custom:ApplyCorner(TabBtn, UDim.new(0, 6))

        local TabContent = Custom:Create("ScrollingFrame", {
            Size = UDim2.new(1, -20, 1, -20),
            Position = UDim2.new(0, 10, 0, 10),
            BackgroundTransparency = 1,
            ScrollBarThickness = 2,
            ScrollBarImageColor3 = Theme.Accent,
            Visible = false,
            Parent = ContentContainer
        })
        Custom:Create("UIListLayout", { Parent = TabContent, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder })
        Custom:Create("UIPadding", { Parent = TabContent, PaddingBottom = UDim.new(0, 10) })

        TabBtn.MouseButton1Click:Connect(function()
            Custom:CircleClick(TabBtn, Player:GetMouse().X, Player:GetMouse().Y)
            for _, t in pairs(WindowObj.Tabs) do
                t.Content.Visible = false
                Custom:Tween(t.Btn, TweenInfo.new(0.2), { BackgroundTransparency = 1, TextColor3 = Theme.TextMuted })
            end
            TabContent.Visible = true
            Custom:Tween(TabBtn, TweenInfo.new(0.2), { BackgroundTransparency = 0, TextColor3 = Theme.Accent })
            WindowObj.CurrentTab = TabName
        end)

        if not WindowObj.CurrentTab then
            TabContent.Visible = true
            TabBtn.BackgroundTransparency = 0
            TabBtn.TextColor3 = Theme.Accent
            WindowObj.CurrentTab = TabName
        end

        table.insert(WindowObj.Tabs, { Btn = TabBtn, Content = TabContent, Name = TabName })
        
        -- // TAB COMPONENTS \\ --
        local TabObj = {}

        function TabObj:CreateButton(Config)
            local Name = Config.Name or "Button"
            local Callback = Config.Callback or function() end

            local BtnFrame = Custom:Create("Frame", {
                Size = UDim2.new(1, -10, 0, 38),
                BackgroundColor3 = Theme.Surface,
                Parent = TabContent
            })
            Custom:ApplyCorner(BtnFrame)
            local BtnStroke = Custom:ApplyStroke(BtnFrame)

            local Btn = Custom:Create("TextButton", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = Name,
                Font = Theme.FontBold,
                TextSize = 13,
                TextColor3 = Theme.Text,
                Parent = BtnFrame
            })

            Btn.MouseEnter:Connect(function() Custom:Tween(BtnStroke, TweenInfo.new(0.2), { Color = Theme.StrokeHover }) end)
            Btn.MouseLeave:Connect(function() Custom:Tween(BtnStroke, TweenInfo.new(0.2), { Color = Theme.Stroke }) end)
            Btn.MouseButton1Click:Connect(function()
                Custom:CircleClick(Btn, Player:GetMouse().X, Player:GetMouse().Y)
                Callback()
            end)
        end

        function TabObj:CreateToggle(Config)
            local Name = Config.Name or "Toggle"
            local Default = Config.Default or false
            local Callback = Config.Callback or function() end
            local Toggled = Default

            local TglFrame = Custom:Create("Frame", {
                Size = UDim2.new(1, -10, 0, 38),
                BackgroundColor3 = Theme.Surface,
                Parent = TabContent
            })
            Custom:ApplyCorner(TglFrame)
            local TglStroke = Custom:ApplyStroke(TglFrame)

            local Lbl = Custom:Create("TextLabel", {
                Text = Name,
                Font = Theme.FontRegular,
                TextSize = 13,
                TextColor3 = Theme.Text,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 15, 0, 0),
                Size = UDim2.new(1, -60, 1, 0),
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = TglFrame
            })

            local Switch = Custom:Create("Frame", {
                Size = UDim2.new(0, 36, 0, 18),
                Position = UDim2.new(1, -50, 0.5, -9),
                BackgroundColor3 = Toggled and Theme.Accent or Theme.Surface2,
                Parent = TglFrame
            })
            Custom:ApplyCorner(Switch, UDim.new(1, 0))
            local SwitchStroke = Custom:ApplyStroke(Switch)

            local Dot = Custom:Create("Frame", {
                Size = UDim2.new(0, 14, 0, 14),
                Position = UDim2.new(0, Toggled and 20 or 2, 0.5, -7),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                Parent = Switch
            })
            Custom:ApplyCorner(Dot, UDim.new(1, 0))

            local Btn = Custom:Create("TextButton", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = "",
                Parent = TglFrame
            })

            Btn.MouseEnter:Connect(function() Custom:Tween(TglStroke, TweenInfo.new(0.2), { Color = Theme.StrokeHover }) end)
            Btn.MouseLeave:Connect(function() Custom:Tween(TglStroke, TweenInfo.new(0.2), { Color = Theme.Stroke }) end)

            local function Fire()
                Toggled = not Toggled
                Custom:Tween(Switch, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { BackgroundColor3 = Toggled and Theme.Accent or Theme.Surface2 })
                Custom:Tween(Dot, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Position = UDim2.new(0, Toggled and 20 or 2, 0.5, -7) })
                Callback(Toggled)
            end

            Btn.MouseButton1Click:Connect(function()
                Custom:CircleClick(Btn, Player:GetMouse().X, Player:GetMouse().Y)
                Fire()
            end)
            
            if Default then Callback(Default) end
        end

        function TabObj:CreateSlider(Config)
            local Name = Config.Name or "Slider"
            local Min = Config.Min or 0
            local Max = Config.Max or 100
            local Default = Config.Default or Min
            local Callback = Config.Callback or function() end

            local SldFrame = Custom:Create("Frame", {
                Size = UDim2.new(1, -10, 0, 55),
                BackgroundColor3 = Theme.Surface,
                Parent = TabContent
            })
            Custom:ApplyCorner(SldFrame)
            local SldStroke = Custom:ApplyStroke(SldFrame)

            local Lbl = Custom:Create("TextLabel", {
                Text = Name,
                Font = Theme.FontRegular,
                TextSize = 13,
                TextColor3 = Theme.Text,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 15, 0, 5),
                Size = UDim2.new(1, -30, 0, 20),
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = SldFrame
            })

            local ValLbl = Custom:Create("TextLabel", {
                Text = tostring(Default),
                Font = Theme.FontBold,
                TextSize = 13,
                TextColor3 = Theme.Accent,
                BackgroundTransparency = 1,
                Position = UDim2.new(1, -65, 0, 5),
                Size = UDim2.new(0, 50, 0, 20),
                TextXAlignment = Enum.TextXAlignment.Right,
                Parent = SldFrame
            })

            local Track = Custom:Create("Frame", {
                Size = UDim2.new(1, -30, 0, 6),
                Position = UDim2.new(0, 15, 0, 35),
                BackgroundColor3 = Theme.Surface2,
                Parent = SldFrame
            })
            Custom:ApplyCorner(Track, UDim.new(1, 0))

            local Fill = Custom:Create("Frame", {
                Size = UDim2.new((Default - Min) / (Max - Min), 0, 1, 0),
                BackgroundColor3 = Theme.Accent,
                Parent = Track
            })
            Custom:ApplyCorner(Fill, UDim.new(1, 0))
            
            local Knob = Custom:Create("Frame", {
                Size = UDim2.new(0, 12, 0, 12),
                Position = UDim2.new(1, -6, 0.5, -6),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                Parent = Fill
            })
            Custom:ApplyCorner(Knob, UDim.new(1, 0))

            local Btn = Custom:Create("TextButton", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = "",
                Parent = SldFrame
            })

            local dragging = false
            Btn.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    Custom:Tween(Knob, TweenInfo.new(0.15), { Size = UDim2.new(0, 16, 0, 16), Position = UDim2.new(1, -8, 0.5, -8) })
                end
            end)

            Btn.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                    Custom:Tween(Knob, TweenInfo.new(0.15), { Size = UDim2.new(0, 12, 0, 12), Position = UDim2.new(1, -6, 0.5, -6) })
                end
            end)

            UserInputService.InputChanged:Connect(function(input)
                if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    local mouseX = UserInputService:GetMouseLocation().X
                    local relativeX = math.clamp((mouseX - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
                    local value = math.floor(Min + ((Max - Min) * relativeX))
                    
                    ValLbl.Text = tostring(value)
                    Fill.Size = UDim2.new(relativeX, 0, 1, 0)
                    Callback(value)
                end
            end)

            Btn.MouseEnter:Connect(function() Custom:Tween(SldStroke, TweenInfo.new(0.2), { Color = Theme.StrokeHover }) end)
            Btn.MouseLeave:Connect(function() Custom:Tween(SldStroke, TweenInfo.new(0.2), { Color = Theme.Stroke }) end)
        end

        return TabObj
    end

    return WindowObj
end

return ZypheraxUI
