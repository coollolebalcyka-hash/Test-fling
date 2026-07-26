--!strict
-- AuraGui — панель управления аурой (один LocalScript, без сервера).
-- Куда класть: StarterGui (LocalScript) или StarterPlayerScripts.
-- Кнопка ВКЛ/ВЫКЛ + выбор цвета. Клавиша G — быстрый вкл/выкл.

local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local auraEnabled = true
local colorMain   = Color3.fromRGB(0, 120, 255)
local KEYBIND     = Enum.KeyCode.G

local function edgeOf(c: Color3): Color3
	return c:Lerp(Color3.fromRGB(255, 255, 255), 0.5)
end

local function getRoot(): BasePart?
	local char = player.Character
	if not char then return nil end
	local root = char:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then return root end
	return nil
end

local function removeAura()
	local root = getRoot()
	if not root then return end
	local att = root:FindFirstChild("BlueAura")
	if att then att:Destroy() end
	local light = root:FindFirstChild("AuraLight")
	if light then light:Destroy() end
end

local function buildAura()
	local root = getRoot()
	if not root then return end
	removeAura()

	local att = Instance.new("Attachment")
	att.Name = "BlueAura"
	att.Parent = root

	local glow = Instance.new("ParticleEmitter")
	glow.Name = "AuraGlow"
	glow.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	glow.Color = ColorSequence.new(colorMain, edgeOf(colorMain))
	glow.LightEmission = 0.7
	glow.LightInfluence = 0
	glow.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1.8),
		NumberSequenceKeypoint.new(1, 0),
	})
	glow.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(0.7, 0.4),
		NumberSequenceKeypoint.new(1, 1),
	})
	glow.Lifetime = NumberRange.new(0.7, 1.1)
	glow.Rate = 45
	glow.Speed = NumberRange.new(1, 3)
	glow.SpreadAngle = Vector2.new(180, 180)
	glow.Rotation = NumberRange.new(0, 360)
	glow.RotSpeed = NumberRange.new(-90, 90)
	glow.Acceleration = Vector3.new(0, 5, 0)
	glow.Parent = att

	local light = Instance.new("PointLight")
	light.Name = "AuraLight"
	light.Color = colorMain
	light.Brightness = 3
	light.Range = 12
	light.Parent = root
end

local function refreshAura()
	if auraEnabled then buildAura() else removeAura() end
end

player.CharacterAdded:Connect(function()
	task.wait(0.5)
	refreshAura()
end)

-- ===== GUI =====
local gui = script:FindFirstAncestorOfClass("ScreenGui")
if not gui then
	gui = Instance.new("ScreenGui")
	gui.Name = "AuraUI"
	gui.Parent = playerGui
end
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local main = Instance.new("Frame")
main.Name = "AuraMain"
main.Size = UDim2.fromOffset(240, 210)
main.Position = UDim2.new(0, 20, 0.5, -105)
main.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true
main.Parent = gui
do
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 10); c.Parent = main
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 10); pad.PaddingBottom = UDim.new(0, 10)
	pad.PaddingLeft = UDim.new(0, 10); pad.PaddingRight = UDim.new(0, 10)
	pad.Parent = main
end

local titleLbl = Instance.new("TextLabel")
titleLbl.Size = UDim2.new(1, 0, 0, 22)
titleLbl.BackgroundTransparency = 1
titleLbl.Text = "Аура — [G]"
titleLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLbl.Font = Enum.Font.GothamBold
titleLbl.TextSize = 16
titleLbl.TextXAlignment = Enum.TextXAlignment.Left
titleLbl.Parent = main

local toggleBtn = Instance.new("TextButton")
toggleBtn.Position = UDim2.new(0, 0, 0, 30)
toggleBtn.Size = UDim2.new(1, 0, 0, 36)
toggleBtn.BorderSizePixel = 0
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextSize = 15
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.Parent = main
do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = toggleBtn end

local function updateToggleVisual()
	if auraEnabled then
		toggleBtn.Text = "Аура: ВКЛ"
		toggleBtn.BackgroundColor3 = Color3.fromRGB(60, 170, 90)
	else
		toggleBtn.Text = "Аура: ВЫКЛ"
		toggleBtn.BackgroundColor3 = Color3.fromRGB(180, 70, 70)
	end
end

local function toggleAura()
	auraEnabled = not auraEnabled
	updateToggleVisual()
	refreshAura()
end

toggleBtn.Activated:Connect(toggleAura)

local colorLbl = Instance.new("TextLabel")
colorLbl.Position = UDim2.new(0, 0, 0, 74)
colorLbl.Size = UDim2.new(1, 0, 0, 18)
colorLbl.BackgroundTransparency = 1
colorLbl.Text = "Цвет:"
colorLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
colorLbl.Font = Enum.Font.Gotham
colorLbl.TextSize = 13
colorLbl.TextXAlignment = Enum.TextXAlignment.Left
colorLbl.Parent = main

local grid = Instance.new("Frame")
grid.Position = UDim2.new(0, 0, 0, 96)
grid.Size = UDim2.new(1, 0, 0, 80)
grid.BackgroundTransparency = 1
grid.Parent = main
do
	local layout = Instance.new("UIGridLayout")
	layout.CellSize = UDim2.fromOffset(46, 30)
	layout.CellPadding = UDim2.fromOffset(6, 6)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = grid
end

local palette = {
	{ name = "Синий",      color = Color3.fromRGB(0, 120, 255) },
	{ name = "Голубой",    color = Color3.fromRGB(0, 200, 255) },
	{ name = "Бирюзовый",  color = Color3.fromRGB(0, 255, 200) },
	{ name = "Зелёный",    color = Color3.fromRGB(60, 220, 120) },
	{ name = "Фиолетовый", color = Color3.fromRGB(150, 0, 255) },
	{ name = "Розовый",    color = Color3.fromRGB(255, 90, 200) },
	{ name = "Красный",    color = Color3.fromRGB(255, 70, 70) },
	{ name = "Белый",      color = Color3.fromRGB(245, 245, 255) },
}

local selectedStroke: UIStroke? = nil

local function selectColor(swatch: TextButton, c: Color3)
	colorMain = c
	if selectedStroke then selectedStroke:Destroy() end
	local s = Instance.new("UIStroke")
	s.Thickness = 3
	s.Color = Color3.fromRGB(255, 255, 255)
	s.Parent = swatch
	selectedStroke = s
	if auraEnabled then buildAura() end
end

for i, item in ipairs(palette) do
	local sw = Instance.new("TextButton")
	sw.LayoutOrder = i
	sw.Text = ""
	sw.BackgroundColor3 = item.color
	sw.BorderSizePixel = 0
	sw.AutoButtonColor = true
	sw.Parent = grid
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 6); c.Parent = sw
	sw.Activated:Connect(function()
		selectColor(sw, item.color)
	end)
	if i == 1 then selectColor(sw, item.color) end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == KEYBIND then
		toggleAura()
	end
end)

updateToggleVisual()
if player.Character then
	task.wait(0.3)
	refreshAura()
end
