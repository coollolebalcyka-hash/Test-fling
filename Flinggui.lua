--!strict
-- FlingClient — КЛИЕНТСКАЯ ЧАСТЬ. Куда класть: StarterGui (LocalScript)

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService  = game:GetService("UserInputService")

local MAX_POWER     = 500   -- ДОЛЖНО совпадать с сервером
local DEFAULT_POWER = 250
local HIDE_SELF     = true

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remote    = ReplicatedStorage:WaitForChild("FlingRemote")

local selectedTarget: Player? = nil
local power = DEFAULT_POWER

local gui = Instance.new("ScreenGui")
gui.Name = "FlingUI"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local main = Instance.new("Frame")
main.Size = UDim2.fromOffset(280, 360)
main.Position = UDim2.new(0, 20, 0.5, -180)
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

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 24)
title.BackgroundTransparency = 1
title.Text = "Fling"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = main

local listLabel = Instance.new("TextLabel")
listLabel.Position = UDim2.new(0, 0, 0, 30)
listLabel.Size = UDim2.new(1, 0, 0, 18)
listLabel.BackgroundTransparency = 1
listLabel.Text = "Цель:"
listLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
listLabel.Font = Enum.Font.Gotham
listLabel.TextSize = 13
listLabel.TextXAlignment = Enum.TextXAlignment.Left
listLabel.Parent = main

local list = Instance.new("ScrollingFrame")
list.Position = UDim2.new(0, 0, 0, 50)
list.Size = UDim2.new(1, 0, 0, 170)
list.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
list.BorderSizePixel = 0
list.ScrollBarThickness = 6
list.CanvasSize = UDim2.new(0, 0, 0, 0)
list.AutomaticCanvasSize = Enum.AutomaticSize.Y
list.Parent = main
do
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 6); c.Parent = list
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 4)
	layout.SortOrder = Enum.SortOrder.Name
	layout.Parent = list
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 4); pad.PaddingBottom = UDim.new(0, 4)
	pad.PaddingLeft = UDim.new(0, 4); pad.PaddingRight = UDim.new(0, 4)
	pad.Parent = list
end

local buttonsByPlayer: { [Player]: TextButton } = {}

local function refreshHighlight()
	for p, btn in pairs(buttonsByPlayer) do
		btn.BackgroundColor3 = (p == selectedTarget)
			and Color3.fromRGB(60, 110, 220)
			or Color3.fromRGB(45, 45, 52)
	end
end

local function addPlayerButton(p: Player)
	if HIDE_SELF and p == player then return end
	if buttonsByPlayer[p] then return end

	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 0, 30)
	btn.BackgroundColor3 = Color3.fromRGB(45, 45, 52)
	btn.BorderSizePixel = 0
	btn.Text = "  " .. p.DisplayName .. "  (@" .. p.Name .. ")"
	btn.TextXAlignment = Enum.TextXAlignment.Left
	btn.TextColor3 = Color3.fromRGB(240, 240, 240)
	btn.Font = Enum.Font.Gotham
	btn.TextSize = 13
	btn.TextTruncate = Enum.TextTruncate.AtEnd
	btn.Name = p.Name
	btn.Parent = list
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 4); c.Parent = btn

	btn.Activated:Connect(function()
		selectedTarget = p
		refreshHighlight()
	end)
	buttonsByPlayer[p] = btn
end

local function removePlayerButton(p: Player)
	local btn = buttonsByPlayer[p]
	if btn then btn:Destroy() end
	buttonsByPlayer[p] = nil
	if selectedTarget == p then selectedTarget = nil end
end

for _, p in ipairs(Players:GetPlayers()) do addPlayerButton(p) end
Players.PlayerAdded:Connect(addPlayerButton)
Players.PlayerRemoving:Connect(removePlayerButton)

local powerLabel = Instance.new("TextLabel")
powerLabel.Position = UDim2.new(0, 0, 0, 228)
powerLabel.Size = UDim2.new(1, 0, 0, 18)
powerLabel.BackgroundTransparency = 1
powerLabel.Text = "Мощность: " .. tostring(power)
powerLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
powerLabel.Font = Enum.Font.Gotham
powerLabel.TextSize = 13
powerLabel.TextXAlignment = Enum.TextXAlignment.Left
powerLabel.Parent = main

local track = Instance.new("Frame")
track.Position = UDim2.new(0, 0, 0, 250)
track.Size = UDim2.new(1, 0, 0, 10)
track.BackgroundColor3 = Color3.fromRGB(60, 60, 68)
track.BorderSizePixel = 0
track.Parent = main
do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1, 0); c.Parent = track end

local fill = Instance.new("Frame")
fill.Size = UDim2.new(power / MAX_POWER, 0, 1, 0)
fill.BackgroundColor3 = Color3.fromRGB(60, 110, 220)
fill.BorderSizePixel = 0
fill.Parent = track
do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1, 0); c.Parent = fill end

local handle = Instance.new("Frame")
handle.AnchorPoint = Vector2.new(0.5, 0.5)
handle.Position = UDim2.new(power / MAX_POWER, 0, 0.5, 0)
handle.Size = UDim2.fromOffset(18, 18)
handle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
handle.BorderSizePixel = 0
handle.ZIndex = 2
handle.Parent = track
do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1, 0); c.Parent = handle end

local dragging = false
local function updateFromX(x: number)
	local rel = (x - track.AbsolutePosition.X) / track.AbsoluteSize.X
	rel = math.clamp(rel, 0, 1)
	power = math.floor(rel * MAX_POWER + 0.5)
	fill.Size = UDim2.new(rel, 0, 1, 0)
	handle.Position = UDim2.new(rel, 0, 0.5, 0)
	powerLabel.Text = "Мощность: " .. tostring(power)
end

track.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		updateFromX(input.Position.X)
	end
end)
UserInputService.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch) then
		updateFromX(input.Position.X)
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
		dragging = false
	end
end)

local flingBtn = Instance.new("TextButton")
flingBtn.Position = UDim2.new(0, 0, 1, -36)
flingBtn.Size = UDim2.new(1, 0, 0, 36)
flingBtn.BackgroundColor3 = Color3.fromRGB(220, 70, 70)
flingBtn.BorderSizePixel = 0
flingBtn.Text = "FLING"
flingBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
flingBtn.Font = Enum.Font.GothamBold
flingBtn.TextSize = 16
flingBtn.Parent = main
do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = flingBtn end

local function flash(text: string)
	title.Text = text
	task.delay(1.5, function() title.Text = "Fling" end)
end

flingBtn.Activated:Connect(function()
	if not selectedTarget then flash("Fling — выбери цель!") return end
	if not selectedTarget.Parent then
		selectedTarget = nil
		refreshHighlight()
		flash("Игрок вышел")
		return
	end
	remote:FireServer(selectedTarget, power)
end)
