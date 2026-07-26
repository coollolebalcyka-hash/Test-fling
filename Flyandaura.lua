--!strict
-- AuraLocal — синяя аура только для тебя. Куда класть: StarterPlayerScripts (LocalScript)

local Players = game:GetService("Players")
local player  = Players.LocalPlayer

local COLOR_MAIN = Color3.fromRGB(0, 120, 255)
local COLOR_EDGE = Color3.fromRGB(150, 210, 255)

local function makeAura(char: Model)
	local root = char:WaitForChild("HumanoidRootPart", 10)
	if not root or not root:IsA("BasePart") then return end
	if root:FindFirstChild("BlueAura") then return end

	local att = Instance.new("Attachment")
	att.Name = "BlueAura"
	att.Parent = root

	local glow = Instance.new("ParticleEmitter")
	glow.Name = "AuraGlow"
	glow.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	glow.Color = ColorSequence.new(COLOR_MAIN, COLOR_EDGE)
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
	light.Color = COLOR_MAIN
	light.Brightness = 3
	light.Range = 12
	light.Parent = root
end

player.CharacterAdded:Connect(makeAura)
if player.Character then makeAura(player.Character) end
