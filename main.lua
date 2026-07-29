--[[
	==================================================================
	  CombatServer  —  СЕРВЕРНАЯ ЧАСТЬ (обязательна)
	==================================================================
	Куда положить:  ServerScriptService
	Тип объекта:    Script   (обычный, НЕ LocalScript)

	RemoteEvent'ы создаются этим скриптом автоматически.
==================================================================]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--=========================  НАСТРОЙКИ  ===========================
local CONFIG = {
	-- АУРА (урон по всем вокруг себя)
	AURA_RADIUS      = 14,     -- радиус в стадах
	AURA_DAMAGE      = 8,      -- урон за один тик
	AURA_COOLDOWN    = 0.5,    -- минимум секунд между тиками
	AURA_MAX_TARGETS = 6,      -- максимум целей за один тик

	-- FLING (отталкивание при касании)
	FLING_RANGE      = 12,     -- макс. дистанция, на которой сервер верит в касание
	FLING_POWER      = 85,     -- сила толчка в сторону
	FLING_UP         = 55,     -- подброс вверх
	FLING_COOLDOWN   = 1.2,    -- секунд между толчками

	-- FLY
	FLY_EVERYONE     = true,   -- true = fly у всех. false = только тем, кто в ADMINS
	ADMINS           = {},     -- сюда UserId, например: { 1234567, 7654321 }

	-- ОБЩЕЕ
	FRIENDLY_FIRE    = false,  -- false = не бить игроков из своей Team
	NPC_FOLDER       = "NPCs", -- папка в Workspace с NPC. Нет папки — игнорируется
}
--=================================================================


--------------------------------------------------------------------
-- 1. Создаём RemoteEvent'ы (если их ещё нет)
--------------------------------------------------------------------
local remotes = ReplicatedStorage:FindFirstChild("CombatRemotes")
if not remotes then
	remotes = Instance.new("Folder")
	remotes.Name = "CombatRemotes"
	remotes.Parent = ReplicatedStorage
end

local function makeRemote(className, name)
	local found = remotes:FindFirstChild(name)
	if not found then
		found = Instance.new(className)
		found.Name = name
		found.Parent = remotes
	end
	return found
end

local AuraHit  = makeRemote("RemoteEvent",    "AuraHit")   -- клиент -> сервер
local FlingHit = makeRemote("RemoteEvent",    "FlingHit")  -- клиент -> сервер
local AskFly   = makeRemote("RemoteFunction", "AskFly")    -- клиент спрашивает права


--------------------------------------------------------------------
-- 2. Вспомогательное
--------------------------------------------------------------------
local auraCooldown  = {}   -- [Player] = время последнего тика
local flingCooldown = {}   -- [Player] = время последнего толчка

-- Возвращает character, humanoid, root — только если персонаж жив
local function getAlive(player)
	local char = player.Character
	if not char then
		return nil
	end
	local hum  = char:FindFirstChildOfClass("Humanoid")
	local root = char:FindFirstChild("HumanoidRootPart")
	if not hum or not root or hum.Health <= 0 then
		return nil
	end
	return char, hum, root
end

-- Можно ли атакующему бить жертву
local function canHit(attacker, victim)
	if attacker == victim then
		return false
	end
	if not CONFIG.FRIENDLY_FIRE and attacker.Team and victim.Team and attacker.Team == victim.Team then
		return false
	end
	return true
end

-- Простая защита от спама событием
local function passCooldown(store, player, seconds)
	local now  = os.clock()
	local last = store[player] or 0
	if now - last < seconds then
		return false
	end
	store[player] = now
	return true
end


--------------------------------------------------------------------
-- 3. АУРА — урон по всем в радиусе
--    Клиент присылает только факт "использую".
--    Цели и дистанцию сервер считает сам.
--------------------------------------------------------------------
AuraHit.OnServerEvent:Connect(function(player)
	if not passCooldown(auraCooldown, player, CONFIG.AURA_COOLDOWN) then
		return
	end

	local _, _, root = getAlive(player)
	if not root then
		return
	end

	local origin = root.Position
	local hits   = 0

	-- по игрокам
	for _, other in ipairs(Players:GetPlayers()) do
		if hits < CONFIG.AURA_MAX_TARGETS and canHit(player, other) then
			local _, oHum, oRoot = getAlive(other)
			if oRoot and (oRoot.Position - origin).Magnitude <= CONFIG.AURA_RADIUS then
				oHum:TakeDamage(CONFIG.AURA_DAMAGE)
				hits = hits + 1
			end
		end
	end

	-- по NPC из папки Workspace.NPCs (если она есть)
	local npcFolder = workspace:FindFirstChild(CONFIG.NPC_FOLDER)
	if npcFolder then
		for _, model in ipairs(npcFolder:GetChildren()) do
			if hits >= CONFIG.AURA_MAX_TARGETS then
				break
			end
			local hum  = model:FindFirstChildOfClass("Humanoid")
			local part = model.PrimaryPart or model:FindFirstChild("HumanoidRootPart")
			if hum and part and hum.Health > 0 then
				if (part.Position - origin).Magnitude <= CONFIG.AURA_RADIUS then
					hum:TakeDamage(CONFIG.AURA_DAMAGE)
					hits = hits + 1
				end
			end
		end
	end
end)


--------------------------------------------------------------------
-- 4. FLING — отталкивание того, кого коснулись
--------------------------------------------------------------------
FlingHit.OnServerEvent:Connect(function(player, target)
	-- жёсткая проверка аргумента: клиент может прислать что угодно
	if typeof(target) ~= "Instance" or not target:IsA("Player") then
		return
	end
	if not canHit(player, target) then
		return
	end
	if not passCooldown(flingCooldown, player, CONFIG.FLING_COOLDOWN) then
		return
	end

	local _, _, myRoot = getAlive(player)
	local _, tHum, tRoot = getAlive(target)
	if not myRoot or not tRoot then
		return
	end

	-- сервер не верит клиенту на слово: было ли касание вообще возможно
	local offset = tRoot.Position - myRoot.Position
	if offset.Magnitude > CONFIG.FLING_RANGE then
		return
	end

	-- направление "от меня к жертве" по горизонтали
	local flat = Vector3.new(offset.X, 0, offset.Z)
	local dir  = (flat.Magnitude > 0.1) and flat.Unit or myRoot.CFrame.LookVector
	local push = (dir * CONFIG.FLING_POWER) + Vector3.new(0, CONFIG.FLING_UP, 0)

	-- Персонажем жертвы физически владеет её клиент, поэтому на время
	-- толчка забираем владение серверу — иначе импульс не применится.
	pcall(function()
		tRoot:SetNetworkOwner(nil)
	end)

	tHum:ChangeState(Enum.HumanoidStateType.Freefall)
	tRoot:ApplyImpulse(push * tRoot.AssemblyMass)

	task.delay(0.7, function()
		if tRoot.Parent then
			pcall(function()
				tRoot:SetNetworkOwnershipAuto()
			end)
		end
	end)
end)


--------------------------------------------------------------------
-- 5. FLY — выдача прав
--    Честно: движение своего персонажа в Roblox всегда на стороне
--    клиента, поэтому это проверка "для своих", а не античит.
--------------------------------------------------------------------
AskFly.OnServerInvoke = function(player)
	if CONFIG.FLY_EVERYONE then
		return true
	end
	for _, id in ipairs(CONFIG.ADMINS) do
		if player.UserId == id then
			return true
		end
	end
	return false
end


--------------------------------------------------------------------
-- 6. Уборка за ушедшими игроками
--------------------------------------------------------------------
Players.PlayerRemoving:Connect(function(player)
	auraCooldown[player]  = nil
	flingCooldown[player] = nil
end)

print("[CombatServer] запущен. Remotes: ReplicatedStorage/CombatRemotes")
