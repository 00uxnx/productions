local UH = loadstring(game:HttpGet("https://raw.githubusercontent.com/YourUser/YourRepo/main/UH.lua"))()

local Window = UH.Window

local PlayerCat = Window:AddCategory("Player", true)
local PlayerSub = Window:AddSubmenu(PlayerCat, "Stats")

UH:AddToggle(PlayerSub, "godmode", "God Mode", false, function(val)
    print("Godmode:", val)
end)

UH:AddSlider(PlayerSub, "speed", "Walk Speed", 16, 200, 16, function(val)
    LocalPlayer.Character.Humanoid.WalkSpeed = val
end)

UH:AddDropdown(PlayerSub, "skin", "Skin Changer", {"Default", "Cop", "Fireman"}, "Default", function(opt)
    print("Skin set to:", opt)
end)

local VehicleCat = Window:AddCategory("Vehicle", false)
UH:AddButton(VehicleCat, "Spawn Car", function()
    print("Car spawned!")
end)

local InfoPanel = Window:AddInfoPanel("Personal Information")
Window:AddInfoItem(InfoPanel, "Health:", "200")
Window:AddInfoItem(InfoPanel, "Armor:", "100")
Window:AddInfoItem(InfoPanel, "Cash:", "$1,000,000")

Window:SelectPage("Player")
