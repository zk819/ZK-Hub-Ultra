-- ============================================
-- ZK HUB 🎯 - AIMBOT PROFISSIONAL v8.0
-- CRIADO POR ECTORSTUFFO
-- ============================================

-- Serviços
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- ========== CORES ==========
local Colors = {
    Background = Color3.fromRGB(10, 10, 10),
    Surface = Color3.fromRGB(26, 26, 26),
    Primary = Color3.fromRGB(0, 102, 255),
    Text = Color3.fromRGB(255, 255, 255),
    TextDim = Color3.fromRGB(180, 180, 200),
    Success = Color3.fromRGB(0, 255, 0),
    Danger = Color3.fromRGB(255, 0, 0),
    Warning = Color3.fromRGB(255, 255, 0),
    Inactive = Color3.fromRGB(60, 60, 70),
    HealthGreen = Color3.fromRGB(0, 255, 0),
    HealthYellow = Color3.fromRGB(255, 255, 0),
    HealthRed = Color3.fromRGB(255, 0, 0)
}

-- ========== CONFIGURAÇÕES ==========
local Config = {
    -- Aimbot Principal
    AimbotActive = true,
    AimbotSmooth = 18,
    AimbotTarget = "HEAD",
    AimbotFOV = 150,
    MaxDistance = 300,
    RageMode = false,
    AimLock = false,
    AimOnlyInFOV = true,
    
    -- Prioridade e Seleção
    Priority = "Center",
    AimOnlyVisible = true,
    IgnoreTeammates = true,
    
    -- Ativação
    ActivationMode = "Always",
    AimKey = Enum.KeyCode.E,
    AimMouseButton = Enum.UserInputType.MouseButton2,
    
    -- Previsão de Movimento
    PredictionEnabled = true,
    PredictionAmount = 15,
    
    -- Visual do Aimbot
    RainbowFOV = true,
    FOVColor = Color3.fromRGB(255, 0, 0),
    ShowFOV = true,
    ShowHitbox = false,
    ShowDistance = true,
    ShowHealth = true,
    ShowStatus = true,
    ShowDirection = false,
    ShowWeapon = true,
    
    -- ESP
    ESPActive = true,
    ESPBox = true,
    ESPBoxColor = Color3.fromRGB(255, 255, 255),
    ESPName = true,
    ESPHealthBar = false,
    ESPHealthText = true,
    ESPDistance = true,
    ESPWeapon = true,
    ESPTeamColor = true,
    ESPPercent = true,
    
    -- Extras
    Notifications = true,
    FPSCounter = true,
    FPSBooster = false,
    RemoveGreenDots = true
}

-- ========== VARIÁVEIS ==========
local FOVCircle = nil
local UI = nil
local playerGui = LocalPlayer:WaitForChild("PlayerGui")
local ESPDrawings = {}
local HitboxDrawings = {}
local CurrentTarget = nil
local FPSValue = 60
local StatusText = nil
local DirectionArrows = {}
local FPSBoosterActive = false
local OriginalSettings = {}
local WatermarkText = nil

-- ========== SUPORTE A DRAWING ==========
local DrawingSupported = pcall(Drawing.new, "Square")

-- ========== NOTIFICAÇÃO ==========
local function Notify(msg)
    if Config.Notifications then
        pcall(function()
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "ZK HUB 🎯",
                Text = msg,
                Duration = 1.5
            })
        end)
    end
end

-- ========== WATERMARK ==========
local function UpdateWatermark()
    if Config.FPSCounter then
        if not WatermarkText then
            WatermarkText = Drawing.new("Text")
            WatermarkText.Visible = true
            WatermarkText.Size = 14
            WatermarkText.Color = Colors.Primary
            WatermarkText.Outline = true
            WatermarkText.Position = Vector2.new(10, 10)
        end
        WatermarkText.Text = "ZK HUB • FPS: " .. FPSValue
    else
        if WatermarkText then
            WatermarkText.Visible = false
            WatermarkText = nil
        end
    end
end

-- ========== ATUALIZAR FOV ==========
local hue = 0
local function UpdateFOV()
    if not Config.ShowFOV or not Config.AimbotActive then
        if FOVCircle then FOVCircle:Destroy(); FOVCircle = nil end
        return
    end

    if not FOVCircle then
        FOVCircle = Instance.new("ScreenGui")
        FOVCircle.Name = "ZKFOV"
        FOVCircle.Parent = CoreGui
        FOVCircle.ResetOnSpawn = false
        FOVCircle.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        FOVCircle.DisplayOrder = 999

        local circle = Instance.new("Frame")
        circle.Name = "Circle"
        circle.BackgroundTransparency = 1
        circle.BorderSizePixel = 0
        circle.Parent = FOVCircle

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = circle

        local stroke = Instance.new("UIStroke")
        stroke.Thickness = 2
        stroke.Transparency = 0.3
        stroke.Parent = circle
    end

    local circle = FOVCircle:FindFirstChild("Circle")
    if circle then
        if Config.RainbowFOV then
            hue = (hue + 0.005) % 1
            circle.UIStroke.Color = Color3.fromHSV(hue, 1, 1)
        else
            circle.UIStroke.Color = Config.FOVColor
        end

        local size = Config.AimbotFOV * 2
        circle.Size = UDim2.new(0, size, 0, size)
        circle.Position = UDim2.new(0.5, -Config.AimbotFOV, 0.5, -Config.AimbotFOV)
    end
end
RunService.RenderStepped:Connect(UpdateFOV)

-- ========== STATUS DO AIMBOT ==========
local function UpdateStatus()
    if Config.ShowStatus then
        if not StatusText then
            StatusText = Drawing.new("Text")
            StatusText.Visible = true
            StatusText.Size = 14
            StatusText.Center = false
            StatusText.Outline = true
            StatusText.Position = Vector2.new(10, Camera.ViewportSize.Y - 30)
        end
        
        local status = "⚡ AIMBOT: "
        if Config.AimbotActive then
            if Config.RageMode then
                status = status .. "RAGE"
            else
                status = status .. "ATIVO"
            end
            
            if CurrentTarget then
                status = status .. " | 🎯 " .. (CurrentTarget.Model.Name or "Alvo")
                
                local humanoid = CurrentTarget.Model:FindFirstChild("Humanoid")
                if humanoid and humanoid.Health > 0 then
                    if Config.ShowHealth then
                        local health = math.floor(humanoid.Health)
                        local maxHealth = math.floor(humanoid.MaxHealth)
                        local percent = math.floor((health / maxHealth) * 100)
                        status = status .. string.format(" | ❤️ %d/%d (%d%%)", health, maxHealth, percent)
                    end
                end
                
                if Config.ShowDistance then
                    local dist = (Camera.CFrame.Position - CurrentTarget.Part.Position).Magnitude
                    status = status .. string.format(" | 📏 %.0fm", dist)
                end
            else
                status = status .. " | 🔍 BUSCANDO..."
            end
        else
            status = status .. "DESATIVADO"
        end
        
        StatusText.Text = status
        
        if Config.AimbotActive and CurrentTarget then
            StatusText.Color = Colors.Success
        elseif Config.AimbotActive then
            StatusText.Color = Colors.Warning
        else
            StatusText.Color = Colors.Danger
        end
    else
        if StatusText then
            StatusText.Visible = false
            StatusText = nil
        end
    end
end

-- ========== FPS COUNTER ==========
local function UpdateFPS()
    local start = tick()
    local frameCount = 0
    
    RunService.RenderStepped:Connect(function()
        frameCount = frameCount + 1
        local elapsed = tick() - start
        if elapsed >= 0.5 then
            FPSValue = math.floor(frameCount / elapsed + 0.5)
            start = tick()
            frameCount = 0
        end
        UpdateWatermark()
    end)
end
UpdateFPS()

-- ========== FPS BOOSTER ==========
local function ApplyFPSBooster(enable)
    if enable then
        if next(OriginalSettings) == nil then
            OriginalSettings = {
                GlobalShadows = Workspace.CurrentCamera.GlobalShadows,
                FogEnd = Lighting.FogEnd,
                DecalsEnabled = Workspace.CurrentCamera.DecalsEnabled,
                Brightness = Lighting.Brightness
            }
        end

        Workspace.CurrentCamera.GlobalShadows = false
        Lighting.FogEnd = 9e9
        Workspace.CurrentCamera.DecalsEnabled = false
        Lighting.Brightness = 2
        
        for _, v in ipairs(Lighting:GetChildren()) do
            if v:IsA("BloomEffect") or v:IsA("BlurEffect") then
                v.Enabled = false
            end
        end
        
        FPSBoosterActive = true
        Notify("FPS Booster ATIVADO")
    else
        if OriginalSettings.GlobalShadows ~= nil then
            Workspace.CurrentCamera.GlobalShadows = OriginalSettings.GlobalShadows
            Lighting.FogEnd = OriginalSettings.FogEnd
            Workspace.CurrentCamera.DecalsEnabled = OriginalSettings.DecalsEnabled
            Lighting.Brightness = OriginalSettings.Brightness
        end

        for _, v in ipairs(Lighting:GetChildren()) do
            if v:IsA("BloomEffect") or v:IsA("BlurEffect") then
                v.Enabled = true
            end
        end
        
        FPSBoosterActive = false
        Notify("FPS Booster DESATIVADO")
    end
end

-- ========== DETECTAR INIMIGOS ==========
local function IsEnemy(model)
    if not model then return false end
    if model == LocalPlayer.Character then return false end
    
    local player = Players:GetPlayerFromCharacter(model)
    if not player then return false end
    
    if not model:FindFirstChild("Humanoid") or not model:FindFirstChild("HumanoidRootPart") then return false end
    if model.Humanoid.Health <= 0 then return false end
    
    if Config.IgnoreTeammates then
        if LocalPlayer.TeamColor ~= BrickColor.new("White") and player.TeamColor ~= BrickColor.new("White") then
            if LocalPlayer.TeamColor == player.TeamColor then
                return false
            end
        end

        local myTeam = LocalPlayer.Team
        local theirTeam = player.Team
        if myTeam and theirTeam and myTeam == theirTeam then
            return false
        end
    end
    
    return true
end

local function GetEnemies()
    local enemies = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and IsEnemy(obj) then
            table.insert(enemies, {
                Model = obj,
                Root = obj.HumanoidRootPart,
                Humanoid = obj.Humanoid
            })
        end
    end
    return enemies
end

-- ========== AIMBOT ==========
local function GetBestTarget()
    if not Config.AimbotActive then return nil end
    
    if Config.ActivationMode == "Key" then
        if not UserInputService:IsKeyDown(Config.AimKey) then
            return nil
        end
    elseif Config.ActivationMode == "MouseButton" then
        if not UserInputService:IsMouseButtonPressed(Config.AimMouseButton) then
            return nil
        end
    end

    local char = LocalPlayer.Character
    if not char then return nil end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return nil end

    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local bestTarget = nil
    local bestScore = 999999
    local enemies = GetEnemies()

    for _, enemy in ipairs(enemies) do
        local targetPart
        if Config.AimbotTarget == "HEAD" then
            targetPart = enemy.Model:FindFirstChild("Head") or enemy.Root
        elseif Config.AimbotTarget == "TORSO" then
            targetPart = enemy.Model:FindFirstChild("UpperTorso") or enemy.Model:FindFirstChild("Torso") or enemy.Root
        else
            targetPart = enemy.Root
        end

        if targetPart then
            local distance = (Camera.CFrame.Position - targetPart.Position).Magnitude
            if distance > Config.MaxDistance then
                continue
            end

            local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
            if onScreen then
                if Config.AimOnlyVisible then
                    local ray = Ray.new(Camera.CFrame.Position, (targetPart.Position - Camera.CFrame.Position).Unit * distance)
                    local hit = workspace:FindPartOnRay(ray, char)
                    if hit and not hit:IsDescendantOf(enemy.Model) then
                        continue
                    end
                end

                local distFromCenter = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
                
                if Config.AimOnlyInFOV and distFromCenter > Config.AimbotFOV then
                    continue
                end
                
                local score
                if Config.Priority == "Center" then
                    score = distFromCenter
                elseif Config.Priority == "Distance" then
                    score = distance
                elseif Config.Priority == "Health" then
                    score = enemy.Humanoid.Health
                else
                    score = distance
                end
                
                if score < bestScore then
                    bestScore = score
                    bestTarget = { 
                        Part = targetPart, 
                        Position = targetPart.Position, 
                        Model = enemy.Model
                    }
                end
            end
        end
    end
    return bestTarget
end

local function AimAtTarget(target)
    if not target then return end
    
    local cameraPos = Camera.CFrame.Position
    local targetPos = target.Position
    
    if Config.PredictionEnabled then
        local humanoid = target.Model:FindFirstChild("Humanoid")
        if humanoid and humanoid.MoveDirection.Magnitude > 0 then
            local prediction = humanoid.MoveDirection * (humanoid.WalkSpeed * (Config.PredictionAmount / 100))
            targetPos = targetPos + prediction
        end
    end
    
    if Config.RageMode or Config.AimLock then
        Camera.CFrame = CFrame.lookAt(cameraPos, targetPos)
    else
        local direction = (targetPos - cameraPos).Unit
        local smooth = Config.AimbotSmooth / 100
        local currentLook = Camera.CFrame.LookVector
        local newLook = currentLook:Lerp(direction, smooth)
        Camera.CFrame = CFrame.lookAt(cameraPos, cameraPos + newLook)
    end
end

RunService.RenderStepped:Connect(function()
    if Config.AimbotActive then
        local target = GetBestTarget()
        CurrentTarget = target
        if target then
            AimAtTarget(target)
        else
            CurrentTarget = nil
        end
    else
        CurrentTarget = nil
    end
    
    UpdateFOV()
    UpdateStatus()
    UpdateESP()
end)

-- ========== FUNÇÃO PARA COR DA VIDA ==========
local function GetHealthColor(health, maxHealth)
    local percent = health / maxHealth
    if percent > 0.6 then
        return Colors.HealthGreen
    elseif percent > 0.3 then
        return Colors.HealthYellow
    else
        return Colors.HealthRed
    end
end

-- ========== ESP ==========
local function ClearESP()
    for _, drawing in pairs(ESPDrawings) do
        for _, d in pairs(drawing) do
            pcall(function() d:Remove() end)
        end
    end
    ESPDrawings = {}
    
    for _, d in pairs(HitboxDrawings) do
        pcall(function() d:Remove() end)
    end
    HitboxDrawings = {}
end

local function GetWeaponName(model)
    local tool = model:FindFirstChildOfClass("Tool")
    if tool then
        return tool.Name
    end
    return "?"
end

local function UpdateESP()
    if not Config.ESPActive or not DrawingSupported then
        ClearESP()
        return
    end

    local enemies = GetEnemies()
    local currentModels = {}
    for _, enemy in ipairs(enemies) do
        currentModels[enemy.Model] = true
    end

    for model, drawing in pairs(ESPDrawings) do
        if not currentModels[model] then
            for _, d in pairs(drawing) do
                pcall(function() d:Remove() end)
            end
            ESPDrawings[model] = nil
        end
    end

    for _, enemy in ipairs(enemies) do
        local model = enemy.Model
        local root = enemy.Root
        local humanoid = enemy.Humanoid
        local head = model:FindFirstChild("Head") or root

        local rootPos, rootVis = Camera:WorldToViewportPoint(root.Position)
        local headPos, headVis = Camera:WorldToViewportPoint(head.Position)

        if rootVis or headVis then
            local screenPos = Vector2.new(rootPos.X, rootPos.Y)
            local boxHeight = math.abs(rootPos.Y - headPos.Y) * 1.8
            local boxWidth = boxHeight * 0.6
            
            if not ESPDrawings[model] then
                ESPDrawings[model] = {}
            end

            local esp = ESPDrawings[model]
            
            -- CAIXA
            if Config.ESPBox then
                if not esp.Box then
                    local box = Drawing.new("Square")
                    box.Visible = false
                    box.Thickness = 1
                    box.Filled = false
                    esp.Box = box
                end
                
                local box = esp.Box
                box.Visible = true
                box.Position = Vector2.new(screenPos.X - boxWidth/2, screenPos.Y - boxHeight/2)
                box.Size = Vector2.new(boxWidth, boxHeight)
                
                if Config.ESPTeamColor then
                    local player = Players:GetPlayerFromCharacter(model)
                    if player and player.TeamColor ~= BrickColor.new("White") then
                        box.Color = player.TeamColor.Color
                    else
                        box.Color = Config.ESPBoxColor
                    end
                else
                    box.Color = Config.ESPBoxColor
                end
                
                if CurrentTarget and CurrentTarget.Model == model then
                    box.Thickness = 3
                    box.Color = Colors.Success
                else
                    box.Thickness = 1
                end
            end

            -- HITBOX
            if Config.ShowHitbox then
                if not esp.Hitbox then
                    local circle = Drawing.new("Circle")
                    circle.Visible = true
                    circle.Thickness = 2
                    circle.NumSides = 30
                    circle.Filled = false
                    circle.Radius = 12
                    esp.Hitbox = circle
                end
                esp.Hitbox.Position = screenPos
                if CurrentTarget and CurrentTarget.Model == model then
                    esp.Hitbox.Visible = true
                    esp.Hitbox.Color = Colors.Success
                else
                    esp.Hitbox.Visible = false
                end
            end

            -- NOME
            if Config.ESPName then
                if not esp.Name then
                    local nameLabel = Drawing.new("Text")
                    nameLabel.Visible = false
                    nameLabel.Color = Color3.new(1, 1, 1)
                    nameLabel.Size = 16
                    nameLabel.Center = true
                    nameLabel.Outline = true
                    esp.Name = nameLabel
                end
                
                local nameLabel = esp.Name
                nameLabel.Visible = true
                nameLabel.Text = model.Name
                nameLabel.Position = Vector2.new(screenPos.X, screenPos.Y - boxHeight/2 - 16)
            end

                      -- VIDA TEXTO
            if Config.ESPHealthText then
                if not esp.HealthText then
                    local healthLabel = Drawing.new("Text")
                    healthLabel.Visible = false
                    healthLabel.Size = 14
                    healthLabel.Center = true
                    healthLabel.Outline = true
                    esp.HealthText = healthLabel
                end
                
                local health = humanoid.Health
                local maxHealth = humanoid.MaxHealth
                local healthPercent = (health / maxHealth) * 100
                
                local healthLabel = esp.HealthText
                healthLabel.Visible = true
                
                if Config.ESPPercent then
                    healthLabel.Text = string.format("❤️ %.0f%%", healthPercent)
                else
                    healthLabel.Text = string.format("❤️ %.0f/%.0f", health, maxHealth)
                end
                
                healthLabel.Color = GetHealthColor(health, maxHealth)
                healthLabel.Position = Vector2.new(screenPos.X, screenPos.Y - boxHeight/2 - 2)
            else
                if esp.HealthText then
                    esp.HealthText.Visible = false
                end
            end

            -- DISTÂNCIA
            if Config.ESPDistance then
                if not esp.Dist then
                    local distLabel = Drawing.new("Text")
                    distLabel.Visible = false
                    distLabel.Color = Color3.new(0.8, 0.8, 0.8)
                    distLabel.Size = 14
                    distLabel.Center = true
                    distLabel.Outline = true
                    esp.Dist = distLabel
                end
                
                local distance = (Camera.CFrame.Position - root.Position).Magnitude
                local distLabel = esp.Dist
                distLabel.Visible = true
                distLabel.Text = string.format("📏 %.0fm", distance)
                distLabel.Position = Vector2.new(screenPos.X, screenPos.Y + boxHeight/2 + 2)
            else
                if esp.Dist then
                    esp.Dist.Visible = false
                end
            end
            
            -- ARMA
            if Config.ESPWeapon then
                if not esp.Weapon then
                    local weaponLabel = Drawing.new("Text")
                    weaponLabel.Visible = false
                    weaponLabel.Color = Color3.new(1, 0.8, 0)
                    weaponLabel.Size = 14
                    weaponLabel.Center = true
                    weaponLabel.Outline = true
                    esp.Weapon = weaponLabel
                end
                
                local weaponName = GetWeaponName(model)
                local weaponLabel = esp.Weapon
                weaponLabel.Visible = true
                weaponLabel.Text = "🔫 " .. weaponName
                weaponLabel.Position = Vector2.new(screenPos.X, screenPos.Y + boxHeight/2 + 18)
            else
                if esp.Weapon then
                    esp.Weapon.Visible = false
                end
            end
        else
            if ESPDrawings[model] then
                for _, d in pairs(ESPDrawings[model]) do
                    if d and d.Visible ~= nil then
                        if type(d) == "table" and d.Bg and d.Fill then
                            d.Bg.Visible = false
                            d.Fill.Visible = false
                        else
                            d.Visible = false
                        end
                    end
                end
            end
        end
    end
end
-- ========== HITBOX ==========
local function UpdateHitbox()
    if not Config.ShowHitbox or not DrawingSupported then
        for _, d in pairs(HitboxDrawings) do
            pcall(function() d:Remove() end)
        end
        HitboxDrawings = {}
        return
    end

    for model, circle in pairs(HitboxDrawings) do
        local humanoid = model and model:FindFirstChild("Humanoid")
        if not humanoid or humanoid.Health <= 0 then
            pcall(function() circle:Remove() end)
            HitboxDrawings[model] = nil
        end
    end

    if CurrentTarget and CurrentTarget.Part then
        local model = CurrentTarget.Model
        local part = CurrentTarget.Part
        local humanoid = model and model:FindFirstChild("Humanoid")
        
        if humanoid and humanoid.Health > 0 then
            local pos, vis = Camera:WorldToViewportPoint(part.Position)
            if vis then
                if not HitboxDrawings[model] then
                    local circle = Drawing.new("Circle")
                    circle.Visible = true
                    circle.Thickness = 2
                    circle.NumSides = 30
                    circle.Filled = false
                    circle.Radius = 12
                    HitboxDrawings[model] = circle
                end

                local circle = HitboxDrawings[model]
                circle.Position = Vector2.new(pos.X, pos.Y)
                
                local healthPercent = humanoid.Health / humanoid.MaxHealth
                if healthPercent > 0.6 then
                    circle.Color = Colors.HealthGreen
                elseif healthPercent > 0.3 then
                    circle.Color = Colors.HealthYellow
                else
                    circle.Color = Colors.HealthRed
                end
                
                circle.Visible = true
            else
                if HitboxDrawings[model] then
                    HitboxDrawings[model].Visible = false
                end
            end
        else
            if HitboxDrawings[model] then
                HitboxDrawings[model].Visible = false
            end
        end
    end
end

-- ========== DIREÇÃO DO ALVO ==========
local function UpdateDirection()
    if Config.ShowDirection and CurrentTarget and CurrentTarget.Part then
        local model = CurrentTarget.Model
        local humanoid = model:FindFirstChild("Humanoid")
        local root = model:FindFirstChild("HumanoidRootPart")
        
        if humanoid and root and humanoid.MoveDirection.Magnitude > 0 then
            local screenPos, onScreen = Camera:WorldToViewportPoint(root.Position)
            if onScreen then
                if not DirectionArrows[model] then
                    local arrow = Drawing.new("Triangle")
                    arrow.Visible = false
                    arrow.Color = Colors.Primary
                    arrow.Thickness = 2
                    arrow.Filled = false
                    DirectionArrows[model] = arrow
                end
                
                local dir = humanoid.MoveDirection * 3
                local arrow = DirectionArrows[model]
                arrow.Visible = true
                arrow.PointA = Vector2.new(screenPos.X + dir.X, screenPos.Y + dir.Z - 20)
                arrow.PointB = Vector2.new(screenPos.X - 5, screenPos.Y - 15)
                arrow.PointC = Vector2.new(screenPos.X + 5, screenPos.Y - 15)
            else
                if DirectionArrows[model] then
                    DirectionArrows[model].Visible = false
                end
            end
        else
            if DirectionArrows[model] then
                DirectionArrows[model].Visible = false
            end
        end
    else
        for _, arrow in pairs(DirectionArrows) do
            if arrow then
                arrow.Visible = false
            end
        end
    end
end

-- ========== LOOP PRINCIPAL ==========
RunService.RenderStepped:Connect(function()
    -- Aimbot
    if Config.AimbotActive then
        local target = GetBestTarget()
        CurrentTarget = target
        if target then
            AimAtTarget(target)
        else
            CurrentTarget = nil
        end
    else
        CurrentTarget = nil
    end
    
    -- Funções visuais
    UpdateFOV()
    if Config.ShowHitbox then
        UpdateHitbox()
    end
    if Config.ShowDirection then
        UpdateDirection()
    end
    UpdateStatus()
    UpdateESP()
end)

-- ========== FUNÇÕES UI ==========
local function createToggle(parent, y, text, var, default)
    Config[var] = default

    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, -20, 0, 35)
    frame.Position = UDim2.new(0, 10, 0, y)
    frame.BackgroundTransparency = 1

    local lbl = Instance.new("TextLabel", frame)
    lbl.Text = text
    lbl.Size = UDim2.new(0.7, 0, 1, 0)
    lbl.Position = UDim2.new(0, 0, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = Colors.Text
    lbl.TextSize = 14
    lbl.Font = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(0, 60, 0, 22)
    btn.Position = UDim2.new(1, -70, 0.5, -11)
    btn.TextColor3 = Colors.Text
    btn.TextSize = 14
    btn.Font = Enum.Font.GothamBold
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false

    local btnCorner = Instance.new("UICorner", btn)
    btnCorner.CornerRadius = UDim.new(0, 5)

    local function updateToggleVisual()
        btn.BackgroundColor3 = Config[var] and Colors.Success or Colors.Inactive
        btn.Text = Config[var] and "ON" or "OFF"
    end

    updateToggleVisual()

    btn.MouseButton1Click:Connect(function()
        Config[var] = not Config[var]
        updateToggleVisual()
        Notify(text .. " " .. (Config[var] and "ON" or "OFF"))

        if var == "FPSBooster" then
            ApplyFPSBooster(Config[var])
        end
    end)

    return 35
end

local function createSlider(parent, y, text, var, min, max, default, suffix)
    Config[var] = default

    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, -20, 0, 50)
    frame.Position = UDim2.new(0, 10, 0, y)
    frame.BackgroundTransparency = 1

    local lbl = Instance.new("TextLabel", frame)
    lbl.Text = text
    lbl.Size = UDim2.new(0.5, 0, 0, 20)
    lbl.Position = UDim2.new(0, 0, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = Colors.Text
    lbl.TextSize = 14
    lbl.Font = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local valLbl = Instance.new("TextLabel", frame)
    valLbl.Size = UDim2.new(0.5, -10, 0, 20)
    valLbl.Position = UDim2.new(0.5, 0, 0, 0)
    valLbl.BackgroundTransparency = 1
    valLbl.Text = tostring(default) .. (suffix or "")
    valLbl.TextColor3 = Colors.Primary
    valLbl.TextSize = 14
    valLbl.Font = Enum.Font.GothamBold
    valLbl.TextXAlignment = Enum.TextXAlignment.Right

    local bg = Instance.new("Frame", frame)
    bg.Size = UDim2.new(1, 0, 0, 8)
    bg.Position = UDim2.new(0, 0, 0, 25)
    bg.BackgroundColor3 = Colors.Inactive
    bg.BorderSizePixel = 0

    local bgCorner = Instance.new("UICorner", bg)
    bgCorner.CornerRadius = UDim.new(0, 4)

    local fill = Instance.new("Frame", bg)
    fill.Size = UDim2.new((default-min)/(max-min), 0, 1, 0)
    fill.BackgroundColor3 = Colors.Primary
    fill.BorderSizePixel = 0

    local fillCorner = Instance.new("UICorner", fill)
    fillCorner.CornerRadius = UDim.new(0, 4)

    local sliderBtn = Instance.new("TextButton", bg)
    sliderBtn.Size = UDim2.new(1, 0, 1, 0)
    sliderBtn.BackgroundTransparency = 1
    sliderBtn.Text = ""

    local dragging = false
    local function update(input)
        local pos = input.Position
        local absPos = bg.AbsolutePosition
        local absSize = bg.AbsoluteSize.X
        local rel = math.clamp(pos.X - absPos.X, 0, absSize)
        local percent = rel / absSize
        local value = math.floor(min + (max - min) * percent)
        Config[var] = value
        valLbl.Text = tostring(value) .. (suffix or "")
        fill.Size = UDim2.new(percent, 0, 1, 0)
    end

    sliderBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            update(input)
        end
    end)
    sliderBtn.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            update(input)
        end
    end)
    sliderBtn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    return 55
end

local function createDropdown(parent, y, text, var, options, default)
    Config[var] = default

    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, -20, 0, 35)
    frame.Position = UDim2.new(0, 10, 0, y)
    frame.BackgroundTransparency = 1

    local lbl = Instance.new("TextLabel", frame)
    lbl.Text = text
    lbl.Size = UDim2.new(0.5, 0, 1, 0)
    lbl.Position = UDim2.new(0, 0, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = Colors.Text
    lbl.TextSize = 14
    lbl.Font = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(0, 80, 0, 25)
    btn.Position = UDim2.new(1, -90, 0.5, -12.5)
    btn.BackgroundColor3 = Colors.Inactive
    btn.Text = default
    btn.TextColor3 = Colors.Text
    btn.TextSize = 14
    btn.Font = Enum.Font.GothamBold
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false

    local btnCorner = Instance.new("UICorner", btn)
    btnCorner.CornerRadius = UDim.new(0, 5)

    local currentIndex = 1
    for i, opt in ipairs(options) do
        if opt == default then
            currentIndex = i
            break
        end
    end

    btn.MouseButton1Click:Connect(function()
        currentIndex = currentIndex % #options + 1
        Config[var] = options[currentIndex]
        btn.Text = options[currentIndex]
        Notify(text .. ": " .. options[currentIndex])
    end)

    return 40
end

local function createKeybind(parent, y, text, var, default)
    Config[var] = default

    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, -20, 0, 40)
    frame.Position = UDim2.new(0, 10, 0, y)
    frame.BackgroundTransparency = 1

    local lbl = Instance.new("TextLabel", frame)
    lbl.Text = text
    lbl.Size = UDim2.new(0.5, 0, 1, 0)
    lbl.Position = UDim2.new(0, 0, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = Colors.Text
    lbl.TextSize = 14
    lbl.Font = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(0, 80, 0, 25)
    btn.Position = UDim2.new(1, -90, 0.5, -12.5)
    btn.BackgroundColor3 = Colors.Inactive
    btn.Text = default.Name
    btn.TextColor3 = Colors.Text
    btn.TextSize = 14
    btn.Font = Enum.Font.GothamBold
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false

    local btnCorner = Instance.new("UICorner", btn)
    btnCorner.CornerRadius = UDim.new(0, 5)

    local listening = false

    btn.MouseButton1Click:Connect(function()
        listening = true
        btn.Text = "..."
        btn.BackgroundColor3 = Colors.Warning
    end)

    UserInputService.InputBegan:Connect(function(input)
        if listening then
            if input.UserInputType == Enum.UserInputType.Keyboard then
                Config[var] = input.KeyCode
                btn.Text = input.KeyCode.Name
                btn.BackgroundColor3 = Colors.Inactive
                listening = false
                Notify(text .. ": " .. input.KeyCode.Name)
            elseif input.UserInputType == Enum.UserInputType.MouseButton1 or 
                   input.UserInputType == Enum.UserInputType.MouseButton2 then
                Config[var] = input.UserInputType
                btn.Text = input.UserInputType.Name
                btn.BackgroundColor3 = Colors.Inactive
                listening = false
                Notify(text .. ": " .. input.UserInputType.Name)
            end
        end
    end)

    return 45
end
-- ========== REMOVER PONTOS VERDES ==========
local function RemoveGreenDots()
    if not Config.RemoveGreenDots then return end
    
    pcall(function()
        for _, v in ipairs(Workspace:GetDescendants()) do
            if v:IsA("BillboardGui") then
                v.Enabled = false
                v:Destroy()
            end
            
            if v:IsA("BasePart") then
                if v.BrickColor == BrickColor.new("Lime green") or 
                   v.BrickColor == BrickColor.new("Bright green") then
                    v.Transparency = 1
                end
            end
            
            local name = v.Name:lower()
            if name:find("point") or name:find("marker") or name:find("dot") or name:find("aim") then
                if v:IsA("BasePart") then
                    v.Transparency = 1
                elseif v:IsA("Model") then
                    v:Destroy()
                end
            end
        end
    end)
end

spawn(function()
    while wait(0.5) do
        RemoveGreenDots()
    end
end)

-- ========== INTERFACE PRINCIPAL ==========
local function CreateUI()
    pcall(function()
        local old = playerGui:FindFirstChild("ZkHub")
        if old then old:Destroy() end
    end)

    RunService.Heartbeat:Wait()

    UI = Instance.new("ScreenGui")
    UI.Name = "ZkHub"
    UI.Parent = playerGui
    UI.ResetOnSpawn = false
    UI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    UI.DisplayOrder = 1000

    -- FRAME PRINCIPAL
    local mainFrame = Instance.new("Frame", UI)
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 450, 0, 650)
    mainFrame.Position = UDim2.new(0.5, -225, 0.5, -325)
    mainFrame.BackgroundColor3 = Colors.Background
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Visible = false

    local frameCorner = Instance.new("UICorner", mainFrame)
    frameCorner.CornerRadius = UDim.new(0, 15)

    -- CABEÇALHO
    local header = Instance.new("Frame", mainFrame)
    header.Size = UDim2.new(1, 0, 0, 60)
    header.BackgroundColor3 = Colors.Surface

    local headerCorner = Instance.new("UICorner", header)
    headerCorner.CornerRadius = UDim.new(0, 15)

    local title = Instance.new("TextLabel", header)
    title.Size = UDim2.new(1, -50, 0.6, 0)
    title.Position = UDim2.new(0, 15, 0, 5)
    title.BackgroundTransparency = 1
    title.Text = "🎯 ZK HUB"
    title.TextColor3 = Colors.Text
    title.TextSize = 26
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left

    local version = Instance.new("TextLabel", header)
    version.Size = UDim2.new(1, -50, 0.4, 0)
    version.Position = UDim2.new(0, 15, 0, 35)
    version.BackgroundTransparency = 1
    version.Text = "AIMBOT PROFISSIONAL v8.0"
    version.TextColor3 = Colors.Primary
    version.TextSize = 14
    version.Font = Enum.Font.Gotham
    version.TextXAlignment = Enum.TextXAlignment.Left

    local closeBtn = Instance.new("TextButton", header)
    closeBtn.Size = UDim2.new(0, 40, 0, 40)
    closeBtn.Position = UDim2.new(1, -50, 0.5, -20)
    closeBtn.BackgroundColor3 = Colors.Danger
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Colors.Text
    closeBtn.TextSize = 22
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.BorderSizePixel = 0

    local closeCorner = Instance.new("UICorner", closeBtn)
    closeCorner.CornerRadius = UDim.new(1, 0)

    closeBtn.MouseButton1Click:Connect(function()
        UI:Destroy()
        ClearESP()
        if FPSBoosterActive then
            ApplyFPSBooster(false)
        end
    end)

    -- ÁREA DE CONTEÚDO (SCROLL)
    local contentFrame = Instance.new("ScrollingFrame", mainFrame)
    contentFrame.Size = UDim2.new(1, -20, 1, -80)
    contentFrame.Position = UDim2.new(0, 10, 0, 70)
    contentFrame.BackgroundTransparency = 1
    contentFrame.ScrollBarThickness = 4
    contentFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y

    -- ===== CONSTRUÇÃO DO CONTEÚDO =====
    local y = 0

    -- INFO / FPS
    local infoLabel = Instance.new("TextLabel", contentFrame)
    infoLabel.Size = UDim2.new(1, -20, 0, 25)
    infoLabel.Position = UDim2.new(0, 10, 0, y)
    infoLabel.BackgroundTransparency = 1
    infoLabel.Text = "📊 FPS: " .. FPSValue .. " | 🎯 ZK HUB"
    infoLabel.TextColor3 = Colors.TextDim
    infoLabel.TextSize = 14
    infoLabel.Font = Enum.Font.Gotham
    infoLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    spawn(function()
        while UI and UI.Parent do
            infoLabel.Text = "📊 FPS: " .. FPSValue .. " | 🎯 ZK HUB"
            wait(0.5)
        end
    end)
    
    y = y + 35

    -- ===== AIMBOT PRINCIPAL =====
    local mainTitle = Instance.new("TextLabel", contentFrame)
    mainTitle.Size = UDim2.new(1, -20, 0, 40)
    mainTitle.Position = UDim2.new(0, 10, 0, y)
    mainTitle.BackgroundTransparency = 1
    mainTitle.Text = "🎯 AIMBOT PRINCIPAL"
    mainTitle.TextColor3 = Colors.Text
    mainTitle.TextSize = 24
    mainTitle.Font = Enum.Font.GothamBold
    mainTitle.TextXAlignment = Enum.TextXAlignment.Left
    y = y + 45

    y = y + createToggle(contentFrame, y, "Ativar Aim Assist", "AimbotActive", true)
    y = y + 5
    y = y + createToggle(contentFrame, y, "⚡ Rage Mode (sem suavidade)", "RageMode", false)
    y = y + 5
    y = y + createToggle(contentFrame, y, "🔒 Aim Lock (trava fixa)", "AimLock", false)
    y = y + 5
    
    if not Config.RageMode then
        y = y + createSlider(contentFrame, y, "Suavidade da Mira", "AimbotSmooth", 0, 100, 18, "%")
        y = y + 5
    end

    -- ===== SELEÇÃO DE ALVO =====
    local targetTitle = Instance.new("TextLabel", contentFrame)
    targetTitle.Size = UDim2.new(1, -20, 0, 30)
    targetTitle.Position = UDim2.new(0, 10, 0, y)
    targetTitle.BackgroundTransparency = 1
    targetTitle.Text = "👤 SELEÇÃO DE ALVO"
    targetTitle.TextColor3 = Colors.TextDim
    targetTitle.TextSize = 18
    targetTitle.Font = Enum.Font.GothamBold
    targetTitle.TextXAlignment = Enum.TextXAlignment.Left
    y = y + 35

    local partFrame = Instance.new("Frame", contentFrame)
    partFrame.Size = UDim2.new(1, -20, 0, 45)
    partFrame.Position = UDim2.new(0, 10, 0, y)
    partFrame.BackgroundTransparency = 1

    local headBtn = Instance.new("TextButton", partFrame)
    headBtn.Size = UDim2.new(0, 90, 0, 40)
    headBtn.Position = UDim2.new(0, 0, 0.5, -20)
    headBtn.BackgroundColor3 = Config.AimbotTarget == "HEAD" and Colors.Primary or Colors.Inactive
    headBtn.Text = "HEAD"
    headBtn.TextColor3 = Colors.Text
    headBtn.TextSize = 16
    headBtn.Font = Enum.Font.GothamBold
    headBtn.BorderSizePixel = 0

    local torsoBtn = Instance.new("TextButton", partFrame)
    torsoBtn.Size = UDim2.new(0, 90, 0, 40)
    torsoBtn.Position = UDim2.new(0.5, -45, 0.5, -20)
    torsoBtn.BackgroundColor3 = Config.AimbotTarget == "TORSO" and Colors.Primary or Colors.Inactive
    torsoBtn.Text = "TORSO"
    torsoBtn.TextColor3 = Colors.Text
    torsoBtn.TextSize = 16
    torsoBtn.Font = Enum.Font.GothamBold
    torsoBtn.BorderSizePixel = 0

    local rootBtn = Instance.new("TextButton", partFrame)
    rootBtn.Size = UDim2.new(0, 90, 0, 40)
    rootBtn.Position = UDim2.new(1, -90, 0.5, -20)
    rootBtn.BackgroundColor3 = Config.AimbotTarget == "ROOT" and Colors.Primary or Colors.Inactive
    rootBtn.Text = "ROOT"
    rootBtn.TextColor3 = Colors.Text
    rootBtn.TextSize = 16
    rootBtn.Font = Enum.Font.GothamBold
    rootBtn.BorderSizePixel = 0

    local cornerH = Instance.new("UICorner", headBtn); cornerH.CornerRadius = UDim.new(0, 8)
    local cornerT = Instance.new("UICorner", torsoBtn); cornerT.CornerRadius = UDim.new(0, 8)
    local cornerR = Instance.new("UICorner", rootBtn); cornerR.CornerRadius = UDim.new(0, 8)

    local function updateTargetButtons(selected)
        Config.AimbotTarget = selected
        headBtn.BackgroundColor3 = selected == "HEAD" and Colors.Primary or Colors.Inactive
        torsoBtn.BackgroundColor3 = selected == "TORSO" and Colors.Primary or Colors.Inactive
        rootBtn.BackgroundColor3 = selected == "ROOT" and Colors.Primary or Colors.Inactive
        Notify("Alvo: " .. selected)
    end

    headBtn.MouseButton1Click:Connect(function() updateTargetButtons("HEAD") end)
    torsoBtn.MouseButton1Click:Connect(function() updateTargetButtons("TORSO") end)
    rootBtn.MouseButton1Click:Connect(function() updateTargetButtons("ROOT") end)

    y = y + 55

    y = y + createDropdown(contentFrame, y, "Prioridade do Alvo", "Priority", {"Center", "Distance", "Health", "Closest"}, "Center")
    y = y + 5
    y = y + createToggle(contentFrame, y, "🚫 Ignorar times aliados", "IgnoreTeammates", true)
    y = y + 5

    -- ===== LIMITES =====
    local limitsTitle = Instance.new("TextLabel", contentFrame)
    limitsTitle.Size = UDim2.new(1, -20, 0, 30)
    limitsTitle.Position = UDim2.new(0, 10, 0, y)
    limitsTitle.BackgroundTransparency = 1
    limitsTitle.Text = "📏 LIMITES"
    limitsTitle.TextColor3 = Colors.TextDim
    limitsTitle.TextSize = 18
    limitsTitle.Font = Enum.Font.GothamBold
    limitsTitle.TextXAlignment = Enum.TextXAlignment.Left
    y = y + 35

    y = y + createSlider(contentFrame, y, "Campo de Visão (FOV)", "AimbotFOV", 50, 500, 150, "px")
    y = y + 5
    y = y + createSlider(contentFrame, y, "Distância Máxima", "MaxDistance", 50, 1000, 300, "m")
    y = y + 5
    y = y + createToggle(contentFrame, y, "🔍 Só mirar se visível", "AimOnlyVisible", true)
    y = y + 5
    y = y + createToggle(contentFrame, y, "📌 Só mirar dentro do FOV", "AimOnlyInFOV", true)
    y = y + 5

    -- ===== ATIVAÇÃO =====
    local activationTitle = Instance.new("TextLabel", contentFrame)
    activationTitle.Size = UDim2.new(1, -20, 0, 30)
    activationTitle.Position = UDim2.new(0, 10, 0, y)
    activationTitle.BackgroundTransparency = 1
    activationTitle.Text = "🔫 ATIVAÇÃO"
    activationTitle.TextColor3 = Colors.TextDim
    activationTitle.TextSize = 18
    activationTitle.Font = Enum.Font.GothamBold
    activationTitle.TextXAlignment = Enum.TextXAlignment.Left
    y = y + 35

    y = y + createDropdown(contentFrame, y, "Modo de Ativação", "ActivationMode", {"Always", "Key", "MouseButton"}, "Always")
    y = y + 5

    if Config.ActivationMode == "Key" then
        y = y + createKeybind(contentFrame, y, "Tecla de Ativação", "AimKey", Enum.KeyCode.E)
        y = y + 5
    end

    if Config.ActivationMode == "MouseButton" then
        y = y + createDropdown(contentFrame, y, "Botão do Mouse", "AimMouseButton", {"MouseButton2", "MouseButton1"}, "MouseButton2")
        y = y + 5
    end

    -- ===== PREVISÃO =====
    local predictionTitle = Instance.new("TextLabel", contentFrame)
    predictionTitle.Size = UDim2.new(1, -20, 0, 30)
    predictionTitle.Position = UDim2.new(0, 10, 0, y)
    predictionTitle.BackgroundTransparency = 1
    predictionTitle.Text = "📈 PREVISÃO DE MOVIMENTO"
    predictionTitle.TextColor3 = Colors.TextDim
    predictionTitle.TextSize = 18
    predictionTitle.Font = Enum.Font.GothamBold
    predictionTitle.TextXAlignment = Enum.TextXAlignment.Left
    y = y + 35

    y = y + createToggle(contentFrame, y, "Ativar previsão", "PredictionEnabled", true)
    y = y + 5

    if Config.PredictionEnabled then
        y = y + createSlider(contentFrame, y, "Intensidade da Previsão", "PredictionAmount", 0, 100, 15, "%")
        y = y + 5
    end

    -- ===== VISUAL =====
    local visualTitle = Instance.new("TextLabel", contentFrame)
    visualTitle.Size = UDim2.new(1, -20, 0, 40)
    visualTitle.Position = UDim2.new(0, 10, 0, y)
    visualTitle.BackgroundTransparency = 1
    visualTitle.Text = "🎨 VISUAL"
    visualTitle.TextColor3 = Colors.Text
    visualTitle.TextSize = 24
    visualTitle.Font = Enum.Font.GothamBold
    visualTitle.TextXAlignment = Enum.TextXAlignment.Left
    y = y + 45

    y = y + createToggle(contentFrame, y, "Mostrar Círculo FOV", "ShowFOV", true)
    y = y + 5

    if Config.ShowFOV then
        y = y + createToggle(contentFrame, y, "🌈 FOV Arco-Íris", "RainbowFOV", true)
        y = y + 5
    end
    
    y = y + createToggle(contentFrame, y, "⚪ Mostrar Hitbox", "ShowHitbox", false)
    y = y + 5
    y = y + createToggle(contentFrame, y, "📏 Mostrar Distância", "ShowDistance", true)
    y = y + 5
    y = y + createToggle(contentFrame, y, "❤️ Mostrar Vida", "ShowHealth", true)
    y = y + 5
    y = y + createToggle(contentFrame, y, "📊 Mostrar Status na Tela", "ShowStatus", true)
    y = y + 5
    y = y + createToggle(contentFrame, y, "🧭 Mostrar Direção do Alvo", "ShowDirection", false)
    y = y + 5
    y = y + createToggle(contentFrame, y, "🔫 Mostrar Arma", "ShowWeapon", true)
    y = y + 5

    -- ===== ESP =====
    local espTitle = Instance.new("TextLabel", contentFrame)
    espTitle.Size = UDim2.new(1, -20, 0, 40)
    espTitle.Position = UDim2.new(0, 10, 0, y)
    espTitle.BackgroundTransparency = 1
    espTitle.Text = "👁️ ESP"
    espTitle.TextColor3 = Colors.Text
    espTitle.TextSize = 24
    espTitle.Font = Enum.Font.GothamBold
    espTitle.TextXAlignment = Enum.TextXAlignment.Left
    y = y + 45

    if not DrawingSupported then
        local warning = Instance.new("TextLabel", contentFrame)
        warning.Size = UDim2.new(1, -20, 0, 30)
        warning.Position = UDim2.new(0, 10, 0, y)
        warning.BackgroundTransparency = 1
        warning.Text = "⚠️ Seu executor não suporta ESP (Drawing)"
        warning.TextColor3 = Colors.Danger
        warning.TextSize = 14
        warning.Font = Enum.Font.Gotham
        warning.TextXAlignment = Enum.TextXAlignment.Left
        y = y + 35
    end

    y = y + createToggle(contentFrame, y, "Ativar ESP", "ESPActive", true)
    y = y + 5

    if Config.ESPActive then
        y = y + createToggle(contentFrame, y, "Mostrar Caixa", "ESPBox", true)
        y = y + 5
        y = y + createToggle(contentFrame, y, "Mostrar Nome", "ESPName", true)
        y = y + 5
        y = y + createToggle(contentFrame, y, "Mostrar Barra de Vida", "ESPHealthBar", false)
        y = y + 5
        y = y + createToggle(contentFrame, y, "Mostrar Vida (Texto)", "ESPHealthText", true)
        y = y + 5
        
        if Config.ESPHealthText then
            y = y + createToggle(contentFrame, y, "Mostrar Porcentagem", "ESPPercent", true)
            y = y + 5
        end
        
        y = y + createToggle(contentFrame, y, "Mostrar Distância", "ESPDistance", true)
        y = y + 5
        y = y + createToggle(contentFrame, y, "Mostrar Arma", "ESPWeapon", true)
        y = y + 5
        y = y + createToggle(contentFrame, y, "Usar Cor do Time", "ESPTeamColor", true)
        y = y + 5
    end

    -- ===== EXTRAS =====
    local extrasTitle = Instance.new("TextLabel", contentFrame)
    extrasTitle.Size = UDim2.new(1, -20, 0, 40)
    extrasTitle.Position = UDim2.new(0, 10, 0, y)
    extrasTitle.BackgroundTransparency = 1
    extrasTitle.Text = "⚙️ EXTRAS"
    extrasTitle.TextColor3 = Colors.Text
    extrasTitle.TextSize = 24
    extrasTitle.Font = Enum.Font.GothamBold
    extrasTitle.TextXAlignment = Enum.TextXAlignment.Left
    y = y + 45

    y = y + createToggle(contentFrame, y, "Mostrar FPS no Menu", "FPSCounter", true)
    y = y + 5
    y = y + createToggle(contentFrame, y, "FPS Booster", "FPSBooster", false)
    y = y + 5
    y = y + createToggle(contentFrame, y, "Remover Pontos Verdes", "RemoveGreenDots", true)
    y = y + 5
    y = y + createToggle(contentFrame, y, "Notificações", "Notifications", true)
    y = y + 5

    -- CRÉDITO
    local credit = Instance.new("TextLabel", contentFrame)
    credit.Size = UDim2.new(1, -20, 0, 40)
    credit.Position = UDim2.new(0, 10, 0, y)
    credit.BackgroundTransparency = 1
    credit.Text = "✨ ZK HUB OFICIAL ✨"
    credit.TextColor3 = Colors.Primary
    credit.TextSize = 16
    credit.Font = Enum.Font.GothamBold
    credit.TextXAlignment = Enum.TextXAlignment.Center
    y = y + 45

    -- BARRA COMPACTA
    local topBar = Instance.new("Frame", UI)
    topBar.Size = UDim2.new(0, 300, 0, 50)
    topBar.Position = UDim2.new(0.5, -150, 0.3, 0)
    topBar.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
    topBar.BorderSizePixel = 0
    topBar.Active = true
    topBar.Draggable = true

    local topBarCorner = Instance.new("UICorner", topBar)
    topBarCorner.CornerRadius = UDim.new(0, 14)

    local topBarStroke = Instance.new("UIStroke", topBar)
    topBarStroke.Color = Color3.fromRGB(220, 220, 220)
    topBarStroke.Thickness = 1

    local topBarTitle = Instance.new("TextLabel", topBar)
    topBarTitle.Size = UDim2.new(0.6, 0, 1, 0)
    topBarTitle.Position = UDim2.new(0, 15, 0, 0)
    topBarTitle.BackgroundTransparency = 1
    topBarTitle.Text = "ZK HUB"
    topBarTitle.TextColor3 = Color3.fromRGB(40, 40, 40)
    topBarTitle.TextSize = 20
    topBarTitle.Font = Enum.Font.GothamBold
    topBarTitle.TextXAlignment = Enum.TextXAlignment.Left

    local topBarOpenBtn = Instance.new("TextButton", topBar)
    topBarOpenBtn.Size = UDim2.new(0, 35, 0, 35)
    topBarOpenBtn.Position = UDim2.new(1, -80, 0.5, -17.5)
    topBarOpenBtn.BackgroundTransparency = 1
    topBarOpenBtn.Text = "+"
    topBarOpenBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
    topBarOpenBtn.TextSize = 26
    topBarOpenBtn.Font = Enum.Font.GothamBold

    local topBarCloseBtn = Instance.new("TextButton", topBar)
    topBarCloseBtn.Size = UDim2.new(0, 35, 0, 35)
    topBarCloseBtn.Position = UDim2.new(1, -40, 0.5, -17.5)
    topBarCloseBtn.BackgroundTransparency = 1
    topBarCloseBtn.Text = "×"
    topBarCloseBtn.TextColor3 = Color3.fromRGB(120, 120, 120)
    topBarCloseBtn.TextSize = 26
    topBarCloseBtn.Font = Enum.Font.GothamBold

    topBarOpenBtn.MouseButton1Click:Connect(function()
        mainFrame.Visible = not mainFrame.Visible
    end)

    topBarCloseBtn.MouseButton1Click:Connect(function()
        UI:Destroy()
        ClearESP()
        if FPSBoosterActive then
            ApplyFPSBooster(false)
        end
    end)
end

-- ========== INICIAR ==========
CreateUI()
Notify("ZK HUB v8.0 • AIMBOT PROFISSIONAL")
