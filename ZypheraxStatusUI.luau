--════════════════════════════════════════════════════════════════════════════
-- TEST / EXECUTE SCRIPT — butuh FILE 1 (library).
-- Opsi A (hosted):  local Library = loadstring(game:HttpGet("URL_LIBRARY_ANDA"))()
-- Opsi B (1 file):  paste isi FILE 1 di atas script ini, lalu ganti baris di
--                   bawah dengan:  local Library = <tabel yang di-return>
--                   (paling mudah: wrap FILE 1 dalam function ... end)
--════════════════════════════════════════════════════════════════════════════

local Library = loadstring(game:HttpGet("URL_LIBRARY_ANDA"))()

local win = Library:CreateWindow({
	Title = "ZYPHERAX HUB",
	Logo = "rbxassetid://106764279090045",
	Discord = "https://discord.gg/xxxxxx",
	Status = "No-Key Script",
	ToggleKey = Enum.KeyCode.RightShift,
	-- Color = Color3.fromRGB(167, 139, 250),  -- opsional: tint accent
})

local main = win:AddTab("Main")
main:AddSection("Combat")
main:AddToggle({ Title = "Auto Farm", Content = "loop nearest mob", Default = true, Callback = function(v) end })
main:AddSlider({ Title = "Attack Range", Min = 10, Max = 200, Default = 60, Increment = 5, Suffix = "m", Callback = function(v) end })
main:AddButton({ Title = "Teleport to Hub", Callback = function()
	Library:Notify({ Title = "Teleport", Content = "Moved to hub spot.", Duration = 3 })
end })
main:AddDropdown({ Title = "Farm Mode", Options = { "Safe", "Risky", "YOLO" }, Default = "Safe", Callback = function(o) end })

local misc = win:AddTab("Misc")
misc:AddTextbox({ Title = "Username Target", Placeholder = "input...", Callback = function(t) end })
misc:AddKeybind({ Title = "Toggle Fly", Default = Enum.KeyCode.F, Callback = function(k) end })
misc:AddColorpicker({ Title = "Tracer Color", Default = Color3.fromRGB(88, 166, 255), Callback = function(c) end })
misc:AddParagraph({ Title = "Build v3", Content = "Notch antialiased, gradient stroke fixed, console bersih." })

local visual = win:AddTab("Visuals")
visual:AddLabel("ESP box")
visual:AddToggle({ Title = "Chams", Default = false, Callback = function(v) end })

task.wait(1)
Library:Notify({ Title = "Loaded", Content = "Library v3 siap. RightShift = toggle.", Duration = 4 })
