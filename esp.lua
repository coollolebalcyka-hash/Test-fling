-- ESP скрипт для Roblox — ТОЛЬКО ДЛЯ ТЕСТИРОВАНИЯ СОБСТВЕННОЙ ИГРЫ
-- Демонстрирует, как клиент может получить информацию об игроках
-- через рендеринг Drawing объектов

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Функция для создания ESP для одного игрока
local function createESP(player)
    if player == LocalPlayer then return end
    
    -- Создаём объекты Drawing для линии и текста
    local line = Drawing.new("Line")
    local text = Drawing.new("Text")
    
    line.Thickness = 2
    line.Color = Color3.fromRGB(0, 255, 0)
    line.Transparency = 0.7
    
    text.Size = 16
    text.Center = true
    text.Outline = true
    text.OutlineColor = Color3.fromRGB(0, 0, 0)
    text.Color = Color3.fromRGB(255, 255, 255)
    text.Text = player.Name
    
    -- Храним объекты в игроке для последующей очистки
    player:SetAttribute("ESP_Line", line)
    player:SetAttribute("ESP_Text", text)
end

-- Создаём ESP для всех существующих игроков
for _, player in ipairs(Players:GetPlayers()) do
    createESP(player)
end

-- Обрабатываем новых игроков
Players.PlayerAdded:Connect(function(player)
    createESP(player)
end)

-- Основной цикл рендеринга — обновление позиций каждый кадр
RunService.RenderStepped:Connect(function()
    -- Очищаем все линии ESP перед перерисовкой (чтобы избежать дублирования)
    for _, drawing in pairs(Drawing.GetDrawings or {}) do
        if drawing:IsA("Line") then
            drawing.Visible = false
        end
    end
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        
        local line = player:GetAttribute("ESP_Line")
        local text = player:GetAttribute("ESP_Text")
        if not line or not text then continue end
        
        local character = player.Character
        if not character or not character:FindFirstChild("HumanoidRootPart") then
            line.Visible = false
            text.Visible = false
            continue
        end
        
        local rootPart = character.HumanoidRootPart
        local head = character:FindFirstChild("Head")
        local torso = character:FindFirstChild("HumanoidRootPart") or head
        
        -- Проецируем 3D позиции на 2D экран
        local rootPos, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
        local headPos = head and Camera:WorldToViewportPoint(head.Position) or rootPos
        
        if onScreen then
            -- Рисуем линию от корня до головы (бокс)
            local boxWidth = math.floor(2000 / rootPos.Z)
            local boxHeight = headPos and (headPos.Y - rootPos.Y) * 2 or boxWidth
            
            -- Линия от низа до верха (скелетная линия)
            line.From = Vector2.new(rootPos.X, rootPos.Y + boxHeight/2)
            line.To = Vector2.new(rootPos.X, rootPos.Y - boxHeight/2)
            line.Visible = true
            
            -- Текст с именем над головой
            text.Position = Vector2.new(
                headPos and headPos.X or rootPos.X,
                (headPos and headPos.Y or rootPos.Y) - 20
            )
            text.Visible = true
        else
            line.Visible = false
            text.Visible = false
        end
    end
end)

-- Очистка при удалении игрока
Players.PlayerRemoving:Connect(function(player)
    local line = player:GetAttribute("ESP_Line")
    local text = player:GetAttribute("ESP_Text")
    if line then line:Remove() end
    if text then text:Remove() end
end)
