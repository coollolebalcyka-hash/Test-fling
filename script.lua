--[[
	==================================================================
	  PanelClient  —  GUI + Aura / Fly / Fling / ESP
	==================================================================
	Куда положить:  StarterPlayer > StarterPlayerScripts
	Тип объекта:    LocalScript

	Управление:
	  G                        — свернуть/развернуть панель
	  W A S D                  — направление полёта (по камере)
	  Space / LeftShift        — вверх / вниз
==================================================================]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

--=========================  НАСТРОЙКИ  ===========================
local CONFIG = {
	AURA_TICK   = 0.5,   -- как часто просить сервер нанести урон
	AURA_RADIUS = 14,    -- ТОЛЬКО для кольца-визуала. Реальный радиус в CombatServer
	FLY_SPEED   = 70,    -- скорость полёта
	FLING_RANGE = 12,    -- локальная отсечка перед отправкой запроса
	ESP_RATE    = 0.25,  -- как часто обновлять дистанцию в ESP

	ACCENT      = Color3.fromRGB(120, 170, 255),   -- цвет включённого тоггла
	ENEMY_COLOR = Color3.fromRGB(255, 90, 90),     -- ESP: враг
	ALLY_COLOR  = Color3.fromRGB(90, 220, 130),    -- ESP: союзник по Team
}
--=================================================================

-- ждём remotes от сервера
local remotes = ReplicatedStorage:WaitForChild("CombatRemotes", 20)
if not remotes then
	warn("[PanelClient] Нет ReplicatedStorage/CombatRemotes — CombatServer не запущен")
	return
end
local AuraHit  = remotes:WaitForChild("AuraHit")
local FlingHit = remotes:WaitForChild("FlingHit")
local AskFly   = remotes:WaitForChild("AskFly")

local state = { aura = false, fly = false, fling = false, esp = false }


--==================================================================
--  1. GUI
--==================================================================
local gui = Instance.new("ScreenGui")
gui.Name            = "CombatPanel"
gui.ResetOnSpawn    = false
gui.IgnoreGuiInset  = true
gui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
gui.Parent          = player:WaitForChild("PlayerGui")

local main = Instance.new("Frame")
main.Name             = "Main"
main.Size             = UDim2.fromOffset(272, 300)
main.Position         = UDim2.new(0, 26, 0.5, -150)
main.BackgroundColor3 = Color3.fromRGB(17, 18, 23)
main.BorderSizePixel  = 0
main.ClipsDescendants = true
main.Parent           = gui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 12)
mainCorner.Parent = main

local mainStroke = Instance.new("UIStroke")
mainStroke.Color        = Color3.fromRGB(46, 48, 58)
mainStroke.Thickness    = 1
mainStroke.Transparency = 0.2
mainStroke.Parent       = main

-- ---------- шапка (за неё же и тащим) ----------
local header = Instance.new("Frame")
header.Name             = "Header"
header.Size             = UDim2.new(1, 0, 0, 44)
header.BackgroundColor3 = Color3.fromRGB(24, 26, 32)
header.BorderSizePixel  = 0
header.Parent           = main

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 12)
headerCorner.Parent = header

-- закрываем нижние скругления шапки
local headerPatch = Instance.new("Frame")
headerPatch.Size             = UDim2.new(1, 0, 0, 12)
headerPatch.Position         = UDim2.new(0, 0, 1, -12)
headerPatch.BackgroundColor3 = header.BackgroundColor3
headerPatch.BorderSizePixel  = 0
headerPatch.ZIndex           = 0
headerPatch.Parent           = header

local dot = Instance.new("Frame")
dot.Size             = UDim2.fromOffset(8, 8)
dot.Position         = UDim2.new(0, 14, 0.5, -4)
dot.BackgroundColor3 = CONFIG.ACCENT
dot.BorderSizePixel  = 0
dot.ZIndex           = 2
dot.Parent           = header
local dotCorner = Instance.new("UICorner")
dotCorner.CornerRadius = UDim.new(1, 0)
dotCorner.Parent = dot

local title = Instance.new("TextLabel")
title.Size                   = UDim2.new(1, -80, 1, 0)
title.Position               = UDim2.new(0, 30, 0, 0)
title.BackgroundTransparency = 1
title.Font                   = Enum.Font.GothamBold
title.Text                   = "ПАНЕЛЬ"
title.TextSize               = 13
title.TextColor3             = Color3.fromRGB(235, 238, 245)
title.TextXAlignment         = Enum.TextXAlignment.Left
title.ZIndex                 = 2
title.Parent                 = header

local minBtn = Instance.new("TextButton")
minBtn.Size                   = UDim2.fromOffset(30, 30)
minBtn.Position               = UDim2.new(1, -38, 0.5, -15)
minBtn.BackgroundColor3       = Color3.fromRGB(38, 40, 48)
minBtn.BorderSizePixel        = 0
minBtn.Font                   = Enum.Font.GothamBold
minBtn.Text                   = "–"
minBtn.TextSize               = 16
minBtn.TextColor3             = Color3.fromRGB(190, 195, 205)
minBtn.AutoButtonColor        = true
minBtn.ZIndex                 = 2
minBtn.Parent                 = header
local minCorner = Instance.new("UICorner")
minCorner.CornerRadius = UDim.new(0, 8)
minCorner.Parent = minBtn

-- ---------- тело ----------
local body = Instance.new("Frame")
body.Name                  = "Body"
body.Size                  = UDim2.new(1, 0, 1, -44)
body.Position              = UDim2.new(0, 0, 0, 44)
body.BackgroundTransparency = 1
body.Parent                = main

local bodyPad = Instance.new("UIPadding")
bodyPad.PaddingTop    = UDim.new(0, 10)
bodyPad.PaddingLeft   = UDim.new(0, 12)
bodyPad.PaddingRight  = UDim.new(0, 12)
bodyPad.Parent        = body

local bodyList = Instance.new("UIListLayout")
bodyList.Padding            = UDim.new(0, 8)
bodyList.SortOrder          = Enum.SortOrder.LayoutOrder
bodyList.HorizontalAlignment = Enum.HorizontalAlignment.Center
bodyList.Parent             = body

-- ---------- фабрика тогглов ----------
local order = 0
local function makeToggle(labelText, hintText, onChanged)
	order = order + 1

	local row = Instance.new("TextButton")
	row.Name             = labelText
	row.Size             = UDim2.new(1, 0, 0, 40)
	row.BackgroundColor3 = Color3.fromRGB(27, 29, 36)
	row.BorderSizePixel  = 0
	row.AutoButtonColor  = false
	row.Text             = ""
	row.LayoutOrder      = order
	row.Parent           = body

	local rowCorner = Instance.new("UICorner")
	rowCorner.CornerRadius = UDim.new(0, 9)
	rowCorner.Parent = row

	local name = Instance.new("TextLabel")
	name.Size                   = UDim2.new(1, -70, 0, 16)
	name.Position               = UDim2.new(0, 12, 0, 5)
	name.BackgroundTransparency = 1
	name.Font                   = Enum.Font.GothamMedium
	name.Text                   = labelText
	name.TextSize               = 13
	name.TextColor3             = Color3.fromRGB(228, 232, 240)
	name.TextXAlignment         = Enum.TextXAlignment.Left
	name.Parent                 = row

	local hint = Instance.new("TextLabel")
	hint.Size                   = UDim2.new(1, -70, 0, 12)
	hint.Position               = UDim2.new(0, 12, 0, 21)
	hint.BackgroundTransparency = 1
	hint.Font                   = Enum.Font.Gotham
	hint.Text                   = hintText
	hint.TextSize               = 10
	hint.TextColor3             = Color3.fromRGB(120, 126, 140)
	hint.TextXAlignment         = Enum.TextXAlignment.Left
	hint.Parent                 = row

	local pill = Instance.new("Frame")
	pill.Size             = UDim2.fromOffset(42, 22)
	pill.Position         = UDim2.new(1, -54, 0.5, -11)
	pill.BackgroundColor3 = Color3.fromRGB(52, 55, 65)
	pill.BorderSizePixel  = 0
	pill.Parent           = row
	local pillCorner = Instance.new("UICorner")
	pillCorner.CornerRadius = UDim.new(1, 0)
	pillCorner.Parent = pill

	local knob = Instance.new("Frame")
	knob.Size             = UDim2.fromOffset(16, 16)
	knob.Position         = UDim2.new(0, 3, 0.5, -8)
	knob.BackgroundColor3 = Color3.fromRGB(225, 228, 235)
	knob.BorderSizePixel  = 0
	knob.Parent           = pill
	local knobCorner = Instance.new("UICorner")
	knobCorner.CornerRadius = UDim.new(1, 0)
	knobCorner.Parent = knob

	local on       = false
	local locked   = false
	local tweenInf = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	local function render()
		TweenService:Create(pill, tweenInf, {
			BackgroundColor3 = on and CONFIG.ACCENT or Color3.fromRGB(52, 55, 65),
		}):Play()
		TweenService:Create(knob, tweenInf, {
			Position = on and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8),
		}):Play()
		TweenService:Create(row, tweenInf, {
			BackgroundColor3 = on and Color3.fromRGB(33, 38, 50) or Color3.fromRGB(27, 29, 36),
		}):Play()
	end

	local api = {}

	function api.set(value)
		if locked or on == value then
			return
		end
		on = value
		render()
		onChanged(on)
	end

	function api.get()
		return on
	end

	function api.lock(reason)
		locked = true
		row.BackgroundTransparency = 0.4
		name.TextColor3 = Color3.fromRGB(110, 114, 124)
		hint.Text = reason
	end

	row.MouseButton1Click:Connect(function()
		api.set(not on)
	end)

	row.MouseEnter:Connect(function()
		if not locked and not on then
			row.BackgroundColor3 = Color3.fromRGB(33, 35, 43)
		end
	end)
	row.MouseLeave:Connect(function()
		if not locked and not on then
			row.BackgroundColor3 = Color3.fromRGB(27, 29, 36)
		end
	end)

	return api
end

-- ---------- перетаскивание за шапку ----------
local dragging, dragStart, startPos = false, nil, nil

header.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
		dragging  = true
		dragStart = input.Position
		startPos  = main.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if not dragging then
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch then
		local delta = input.Position - dragStart
		main.Position = UDim2.new(
			startPos.X.Scale, startPos.X.Offset + delta.X,
			startPos.Y.Scale, startPos.Y.Offset + delta.Y
		)
	end
end)

-- ---------- свернуть / развернуть ----------
local collapsed = false
local function setCollapsed(value)
	collapsed = value
	body.Visible = not collapsed
	minBtn.Text  = collapsed and "+" or "–"
	TweenService:Create(main, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = collapsed and UDim2.fromOffset(272, 44) or UDim2.fromOffset(272, 300),
	}):Play()
end

minBtn.MouseButton1Click:Connect(function()
	setCollapsed(not collapsed)
end)


--==================================================================
--  2. АУРА — просим сервер, кольцо рисуем локально
--==================================================================
local auraRing = Instance.new("Part")
auraRing.Name         = "AuraRing"
auraRing.Shape        = Enum.PartType.Cylinder
auraRing.Size         = Vector3.new(0.4, CONFIG.AURA_RADIUS * 2, CONFIG.AURA_RADIUS * 2)
auraRing.Anchored     = true
auraRing.CanCollide   = false
auraRing.CanQuery     = false
auraRing.CanTouch     = false
auraRing.Material     = Enum.Material.Neon
auraRing.Color        = CONFIG.ACCENT
auraRing.Transparency = 0.85
auraRing.CastShadow   = false

-- Важно: кольцо создано на клиенте, значит видно только тебе.
-- Хочешь, чтобы эффект видели все — создавай его на сервере.

local function setAura(on)
	if on then
		auraRing.Parent = workspace
	else
		auraRing.Parent = nil
	end
end

task.spawn(function()
	while true do
		task.wait(CONFIG.AURA_TICK)
		if state.aura then
			AuraHit:FireServer()
		end
	end
end)


--==================================================================
--  3. FLY
--==================================================================
local flyAttachment, flyVelocity

local function stopFly()
	if flyVelocity then
		flyVelocity:Destroy()
		flyVelocity = nil
	end
	if flyAttachment then
		flyAttachment:Destroy()
		flyAttachment = nil
	end
end

local function startFly()
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then
		return false
	end
	stopFly()

	flyAttachment = Instance.new("Attachment")
	flyAttachment.Name   = "FlyAttachment"
	flyAttachment.Parent = root

	flyVelocity = Instance.new("LinearVelocity")
	flyVelocity.Attachment0    = flyAttachment
	flyVelocity.MaxForce       = math.huge
	flyVelocity.RelativeTo     = Enum.ActuatorRelativeTo.World
	flyVelocity.VectorVelocity = Vector3.new(0, 0, 0)
	flyVelocity.Parent         = root
	return true
end

local function setFly(on)
	if on then
		if not startFly() then
			return
		end
	else
		stopFly()
	end
end

local function keyDown(code)
	return UserInputService:IsKeyDown(code)
end

RunService.RenderStepped:Connect(function()
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")

	-- кольцо ауры держим на персонаже (Cylinder лежит на боку — поворачиваем)
	if state.aura and root and auraRing.Parent then
		auraRing.CFrame = CFrame.new(root.Position - Vector3.new(0, 2.6, 0)) * CFrame.Angles(0, 0, math.rad(90))
	end

	-- полёт
	if not state.fly or not root then
		return
	end
	if not flyVelocity or not flyVelocity.Parent then
		return
	end

	local hum = char:FindFirstChildOfClass("Humanoid")
	local dir = Vector3.new(0, 0, 0)
	local cf  = camera.CFrame

	if keyDown(Enum.KeyCode.W) then dir = dir + cf.LookVector end
	if keyDown(Enum.KeyCode.S) then dir = dir - cf.LookVector end
	if keyDown(Enum.KeyCode.A) then dir = dir - cf.RightVector end
	if keyDown(Enum.KeyCode.D) then dir = dir + cf.RightVector end
	if keyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
	if keyDown(Enum.KeyCode.LeftShift) then dir = dir - Vector3.new(0, 1, 0) end

	if dir.Magnitude > 0 then
		dir = dir.Unit
		if hum then
			hum:ChangeState(Enum.HumanoidStateType.Freefall)
		end
	end
	-- нулевой вектор = зависание на месте (MaxForce гасит гравитацию)
	flyVelocity.VectorVelocity = dir * CONFIG.FLY_SPEED
end)


--==================================================================
--  4. FLING — ловим касание своего персонажа
--==================================================================
local lastFlingSent = 0

local function playerFromHit(hit)
	local model = hit:FindFirstAncestorOfClass("Model")
	if not model then
		return nil
	end
	return Players:GetPlayerFromCharacter(model)
end

local function hookPart(part)
	if not part:IsA("BasePart") then
		return
	end
	part.Touched:Connect(function(hit)
		if not state.fling then
			return
		end
		local other = playerFromHit(hit)
		if not other or other == player then
			return
		end
		if os.clock() - lastFlingSent < 0.4 then
			return
		end

		-- локальная отсечка, чтобы не спамить сервер зря
		local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		local oRoot  = other.Character and other.Character:FindFirstChild("HumanoidRootPart")
		if not myRoot or not oRoot then
			return
		end
		if (oRoot.Position - myRoot.Position).Magnitude > CONFIG.FLING_RANGE then
			return
		end

		lastFlingSent = os.clock()
		FlingHit:FireServer(other)
	end)
end


--==================================================================
--  5. ESP — подсветка игроков
--    В Roblox персонажи всех игроков и так реплицированы клиенту,
--    так что это визуализация, а не доступ к скрытым данным.
--==================================================================
local espData = {}   -- [Player] = { highlight = ..., billboard = ..., label = ... }

local function removeEsp(target)
	local data = espData[target]
	if not data then
		return
	end
	if data.highlight then data.highlight:Destroy() end
	if data.billboard then data.billboard:Destroy() end
	espData[target] = nil
end

local function addEsp(target)
	if target == player or espData[target] then
		return
	end
	local char = target.Character
	local head = char and char:FindFirstChild("Head")
	if not char or not head then
		return
	end

	local isAlly = (player.Team ~= nil and target.Team == player.Team)
	local color  = isAlly and CONFIG.ALLY_COLOR or CONFIG.ENEMY_COLOR

	local highlight = Instance.new("Highlight")
	highlight.Name              = "ESP_Highlight"
	highlight.Adornee           = char
	highlight.FillColor         = color
	highlight.FillTransparency  = 0.65
	highlight.OutlineColor      = color
	highlight.OutlineTransparency = 0
	highlight.DepthMode         = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Parent            = char

	local billboard = Instance.new("BillboardGui")
	billboard.Name          = "ESP_Tag"
	billboard.Adornee       = head
	billboard.Size          = UDim2.fromOffset(190, 30)
	billboard.StudsOffset   = Vector3.new(0, 2.4, 0)
	billboard.AlwaysOnTop   = true
	billboard.MaxDistance   = 900
	billboard.Parent        = char

	local label = Instance.new("TextLabel")
	label.Size                   = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font                   = Enum.Font.GothamBold
	label.TextSize               = 13
	label.TextColor3             = color
	label.TextStrokeTransparency = 0.4
	label.Text                   = target.DisplayName
	label.Parent                 = billboard

	espData[target] = { highlight = highlight, billboard = billboard, label = label }
end

local function clearEsp()
	for target in pairs(espData) do
		removeEsp(target)
	end
end

local function setEsp(on)
	if on then
		for _, other in ipairs(Players:GetPlayers()) do
			addEsp(other)
		end
	else
		clearEsp()
	end
end

-- обновляем дистанцию и подхватываем респавны
task.spawn(function()
	while true do
		task.wait(CONFIG.ESP_RATE)
		if state.esp then
			local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			for _, other in ipairs(Players:GetPlayers()) do
				if other ~= player then
					local data = espData[other]
					local char = other.Character
					local ok   = char and char:FindFirstChild("Head") and char:FindFirstChildOfClass("Humanoid")

					if ok and not data then
						addEsp(other)               -- заспавнился
					elseif data and not ok then
						removeEsp(other)            -- умер / персонаж исчез
					elseif data and myRoot then
						local oRoot = char:FindFirstChild("HumanoidRootPart")
						local hum   = char:FindFirstChildOfClass("Humanoid")
						if oRoot and hum then
							local dist = math.floor((oRoot.Position - myRoot.Position).Magnitude)
							data.label.Text = string.format(
								"%s  ·  %dm  ·  %d hp",
								other.DisplayName, dist, math.floor(hum.Health)
							)
						end
					end
				end
			end
		end
	end
end)

Players.PlayerRemoving:Connect(removeEsp)


--==================================================================
--  6. Собираем тогглы
--==================================================================
makeToggle("Аура", "урон по всем вокруг", function(on)
	state.aura = on
	setAura(on)
end)

local flyToggle = makeToggle("Fly", "W A S D · Space · Shift", function(on)
	state.fly = on
	setFly(on)
end)

makeToggle("Fling", "отталкивать при касании", function(on)
	state.fling = on
end)

makeToggle("ESP", "подсветка игроков", function(on)
	state.esp = on
	setEsp(on)
end)

-- подсказка снизу
local hintBox = Instance.new("TextLabel")
hintBox.Size                   = UDim2.new(1, 0, 0, 34)
hintBox.BackgroundTransparency = 1
hintBox.Font                   = Enum.Font.Gotham
hintBox.Text                   = "G — свернуть панель\nурон и толчок считает сервер"
hintBox.TextSize               = 10
hintBox.TextColor3             = Color3.fromRGB(105, 110, 124)
hintBox.TextWrapped            = true
hintBox.LayoutOrder            = 99
hintBox.Parent                 = body


--==================================================================
--  7. Права на Fly + хоткеи + респавн
--==================================================================
task.spawn(function()
	local ok, allowed = pcall(function()
		return AskFly:InvokeServer()
	end)
	if not ok or not allowed then
		flyToggle.set(false)
		flyToggle.lock("нет прав — см. CONFIG.ADMINS на сервере")
	end
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.KeyCode == Enum.KeyCode.G then
		setCollapsed(not collapsed)
	end
end)

local function onCharacter(char)
	-- заново вешаем Touched и перезапускаем полёт после респавна
	for _, part in ipairs(char:GetDescendants()) do
		hookPart(part)
	end
	char.DescendantAdded:Connect(hookPart)

	if state.fly then
		task.wait(0.2)
		startFly()
	end
	if state.esp then
		clearEsp()
		setEsp(true)
	end
end

if player.Character then
	onCharacter(player.Character)
end
player.CharacterAdded:Connect(onCharacter)

print("[PanelClient] панель загружена")
