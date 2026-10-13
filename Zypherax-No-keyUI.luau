-- ==========================================
-- SERVICES & VARIABLES
-- ==========================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer
local FishingSystem = ReplicatedStorage:WaitForChild("FishingSystem")
local FishingModules = FishingSystem:WaitForChild("FishingModules")

local MinigameSystem = require(FishingModules:WaitForChild("MinigameSystem"))
local FishGiver = FishingSystem:WaitForChild("FishGiver")

local isRunning = false
local cycleThread = nil

-- ==========================================
-- CORE FUNCTIONS
-- ==========================================
local function getEquippedRod()
    local char = LocalPlayer.Character
    if not char then return nil end
    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") and CollectionService:HasTag(tool, "Rod") then
            return tool
        end
    end
    return nil
end

-- Fungsi untuk mengklik tombol Auto bawaan game
local function clickAutoButton()
    local PlayerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not PlayerGui then return false end
    local FishingGui = PlayerGui:FindFirstChild("FishingGui")
    if not FishingGui then return false end
    local AutoButton = FishingGui:FindFirstChild("AutoButton")
    if not AutoButton then return false end

    -- Cek teks tombol, jika masih OFF maka diklik
    local textLabel = AutoButton:FindFirstChild("Text")
    if textLabel and textLabel.Text == "Auto: OFF" then
        local pos = AutoButton.AbsolutePosition
        local size = AutoButton.AbsoluteSize
        local x = pos.X + (size.X / 2)
        local y = pos.Y + (size.Y / 2)
        
        -- Simulasi klik mouse (Work di semua executor)
        VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 1)
        VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 1)
        return true
    end
    return false
end

-- ==========================================
-- AUTO CYCLE LOGIC (YANG SUDAH DIPERBAIKI)
-- ==========================================
local function startCycle()
    isRunning = true
    
    -- 1. Nyalakan Auto-Fish bawaan game di awal
    clickAutoButton()
    task.wait(1) 

    cycleThread = task.spawn(function()
        while isRunning do
            local rod = getEquippedRod()
            
            -- Jika rod hilang (karena proses reset), equip ulang
            if not rod then
                local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
                if humanoid then
                    for _, tool in ipairs(LocalPlayer.Backpack:GetChildren()) do
                        if tool:IsA("Tool") and CollectionService:HasTag(tool, "Rod") then
                            humanoid:EquipTool(tool)
                            rod = tool
                            break
                        end
                    end
                end
                task.wait(1.5) -- Tunggu animasi equip
            else
                -- 2. Tunggu sampai Minigame muncul
                if MinigameSystem:IsActive() then
                    -- Ambil posisi kail asli
                    local sinker = workspace:FindFirstChild("FishingHook")
                    local hookPos = sinker and sinker.Position or Vector3.new(-6719.759765625, 2229.21337890625, 22375.83203125)
                    
                    -- 3. INSTANT CATCH (Klaim ikan)
                    FishGiver:FireServer({
                        hookPosition = hookPos,
                        powerPercent = 1
                    })
                    
                    -- ️ PERBAIKAN UTAMA: TUNGGU 1.5 DETIK! ️
                    -- Ini memberi waktu server untuk memproses FishGiver dan memasukkan ikan ke inventory.
                    -- Jika di-unequip kecepetan, server akan membatalkan catch.
                    task.wait(1.5) 

                    -- 4. RESET STATE (Unequip -> Equip)
                    -- Sekarang aman untuk mereset state client agar tidak stuck di minigame
                    local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
                    if humanoid then
                        humanoid:UnequipTools() 
                        task.wait(0.8) -- Tunggu sampai benar-benar unequip
                        
                        humanoid:EquipTool(rod) 
                        task.wait(1.0) -- Tunggu animasi equip selesai
                        
                        -- 5. NYALAKAN AUTO LAGI
                        -- Karena unequip mematikan auto-fish, kita nyalakan ulang
                        clickAutoButton()
                        task.wait(1.0) -- Tunggu game mempersiapkan lemparan berikutnya
                    end
                else
                    task.wait(0.2) -- Polling cepat menunggu ikan makan
                end
            end
        end
    end)
end

local function stopCycle()
    isRunning = false
    if cycleThread then
        cycleThread = nil
    end
end

-- ==========================================
-- SIMPLE GUI
-- ==========================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SafeAutoFish"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 240, 0, 140)
MainFrame.Position = UDim2.new(0.5, -120, 0.5, -70)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)
local Stroke = Instance.new("UIStroke", MainFrame)
Stroke.Color = Color3.fromRGB(0, 255, 150)
Stroke.Thickness = 1.5

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 35)
Title.BackgroundTransparency = 1
Title.Text = "⚡ Safe Auto Instant Fish"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 16
Title.Parent = MainFrame

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0.85, 0, 0, 45)
ToggleBtn.Position = UDim2.new(0.075, 0, 0.35, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 150, 80)
ToggleBtn.Text = "Start Auto-Cycle"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamSemibold
ToggleBtn.TextSize = 15
ToggleBtn.BorderSizePixel = 0
ToggleBtn.Parent = MainFrame
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 8)

local InfoLabel = Instance.new("TextLabel")
InfoLabel.Size = UDim2.new(0.9, 0, 0, 30)
InfoLabel.Position = UDim2.new(0.05, 0, 0.75, 0)
InfoLabel.BackgroundTransparency = 1
InfoLabel.Text = "Delay 1.5s agar ikan masuk server"
InfoLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
InfoLabel.Font = Enum.Font.Gotham
InfoLabel.TextSize = 11
InfoLabel.Parent = MainFrame

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, 0, 0, 20)
StatusLabel.Position = UDim2.new(0, 0, 0.92, 0)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Status: Idle"
StatusLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextSize = 12
StatusLabel.Parent = MainFrame

-- ==========================================
-- GUI EVENTS & DRAGGING
-- ==========================================
ToggleBtn.MouseButton1Click:Connect(function()
    if not isRunning then
        startCycle()
        ToggleBtn.Text = "Stop Auto-Cycle"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
        StatusLabel.Text = "Status: Running (Safe Delay)"
        StatusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
    else
        stopCycle()
        ToggleBtn.Text = "Start Auto-Cycle"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 150, 80)
        StatusLabel.Text = "Status: Stopped"
        StatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
    end
end)

-- Draggable Logic
local dragging, dragInput, dragStart, startPos
Title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
Title.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
