--!strict
-- FlingServer — СЕРВЕРНАЯ ЧАСТЬ
-- Куда класть: ServerScriptService (обычный Script)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ========================= НАСТРОЙКИ =========================
local MAX_POWER    = 500    -- потолок мощности (в клиенте должно совпадать)
local MIN_POWER    = 0
local COOLDOWN     = 1.0    -- секунд между флингами
local ALLOW_SELF   = false  -- можно ли флингать самого себя
local UPWARD_BIAS  = 0.5    -- добавка вверх: 0 = вбок, 1 = сильно вверх
local SPIN         = 30     -- закрутка, 0 = без вращения
local IMPULSE_TIME = 0.2    -- сколько секунд действует толчок

local USE_ALLOWLIST = false -- true = флингать могут только из списка ниже
local ALLOWLIST = {
	-- [123456789] = true,   -- по UserId
	-- ["Roblox"]  = true,   -- по нику
}
-- ============================================================

local remote = ReplicatedStorage:FindFirstChild("FlingRemote")
if not remote then
	remote = Instance.new("RemoteEvent")
	remote.Name = "FlingRemote"
	remote.Parent = ReplicatedStorage
end

local lastUse: { [Player]: number } = {}

local function isAllowed(player: Player): boolean
	if not USE_ALLOWLIST then return true end
	return ALLOWLIST[player.UserId] == true or ALLOWLIST[player.Name] == true
end

local function getRoot(player: Player): BasePart?
	local char = player.Character
	if not char then return nil end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then return nil end
	local root = char:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then return root end
	return nil
end

local function applyFling(root: BasePart, direction: Vector3, power: number)
	local velocity = direction * power + Vector3.new(0, power * UPWARD_BIAS, 0)

	local attachment = Instance.new("Attachment")
	attachment.Name = "FlingAttachment"
	attachment.Parent = root

	local lv = Instance.new("LinearVelocity")
	lv.Attachment0 = attachment
	lv.RelativeTo = Enum.ActuatorRelativeTo.World
	lv.ForceLimitMode = Enum.ForceLimitMode.Magnitude
	lv.MaxForce = math.huge
	lv.VectorVelocity = velocity
	lv.Parent = root

	local av: AngularVelocity? = nil
	if SPIN > 0 then
		av = Instance.new("AngularVelocity")
		av.Attachment0 = attachment
		av.RelativeTo = Enum.ActuatorRelativeTo.World
		av.MaxTorque = math.huge
		av.AngularVelocity = Vector3.new(
			math.random(-SPIN, SPIN),
			math.random(-SPIN, SPIN),
			math.random(-SPIN, SPIN)
		)
		av.Parent = root
	end

	task.delay(IMPULSE_TIME, function()
		if av then av:Destroy() end
		lv:Destroy()
		attachment:Destroy()
	end)
end

remote.OnServerEvent:Connect(function(sender: Player, target: any, power: any)
	if typeof(target) ~= "Instance" or not target:IsA("Player") then return end
	if typeof(power) ~= "number" or power ~= power then return end
	if not isAllowed(sender) then return end
	if target == sender and not ALLOW_SELF then return end

	local now = os.clock()
	local last = lastUse[sender]
	if last and (now - last) < COOLDOWN then return end

	power = math.clamp(power, MIN_POWER, MAX_POWER)
	if power <= 0 then return end

	local targetRoot = getRoot(target)
	if not targetRoot then return end

	local senderRoot = getRoot(sender)
	local dir: Vector3
	if senderRoot then
		local flat = targetRoot.Position - senderRoot.Position
		flat = Vector3.new(flat.X, 0, flat.Z)
		if flat.Magnitude < 0.1 then
			flat = Vector3.new(math.random(-10, 10), 0, math.random(-10, 10))
		end
		dir = flat.Unit
	else
		dir = Vector3.new(math.random(-10, 10), 0, math.random(-10, 10)).Unit
	end

	lastUse[sender] = now
	applyFling(targetRoot, dir, power)
end)

Players.PlayerRemoving:Connect(function(p)
	lastUse[p] = nil
end)
