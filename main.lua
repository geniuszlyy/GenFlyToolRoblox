-- ГЛОБАЛЬНЫЕ ПЕРЕМЕННЫЕ
local flightPower = 30 -- Мощность полета
local maxFlightPower = 100 -- Максимальная мощность полета
local minFlightPower = 10 -- Минимальная мощность полета
local speedIncrement = 5 -- Прирост скорости при увеличении
local flyingTool = nil

local bodyPosition = Instance.new("BodyPosition")
local bodyGyro = Instance.new("BodyGyro")

local isFlying = false
local particleEmitter = nil -- Эмиттер частиц

local localPlayer = game.Players.LocalPlayer
local characterModel = localPlayer.Character or localPlayer.CharacterAdded:wait()
local torso = characterModel:FindFirstChild("UpperTorso") or characterModel:FindFirstChild("Torso")

local playerMouse = localPlayer:GetMouse()
local flightGui = nil -- GUI для отображения состояния полета

-- ФУНКЦИЯ ИНИЦИАЛИЗАЦИИ ИНСТРУМЕНТА И ИНТЕРФЕЙСА
local function initializeTool()
    -- Создание инструмента "FlyTool" и размещение его в рюкзаке игрока
    flyingTool = Instance.new("Tool")
    flyingTool.Name = "FlyTool"
    flyingTool.RequiresHandle = false
    flyingTool.Parent = localPlayer.Backpack

    bodyGyro.maxTorque = Vector3.new(math.huge, math.huge, math.huge)
    bodyPosition.maxForce = Vector3.new(math.huge, math.huge, math.huge)

    script.Parent = flyingTool

    -- Создание GUI для отображения состояния полета
    flightGui = Instance.new("ScreenGui", localPlayer:WaitForChild("PlayerGui"))
    local statusLabel = Instance.new("TextLabel", flightGui)
    statusLabel.Size = UDim2.new(0, 200, 0, 50)
    statusLabel.Position = UDim2.new(0.5, -100, 0, 50)
    statusLabel.Text = "Flight Power: " .. flightPower
    statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    statusLabel.BackgroundTransparency = 1
    statusLabel.TextScaled = true

    -- Обновление текста с мощностью полета
    local function updateFlightPower()
        statusLabel.Text = "Flight Power: " .. flightPower
    end

    -- События изменения мощности полета с использованием стрелок
    playerMouse.KeyDown:Connect(function(key)
        if key == Enum.KeyCode.Up then
            flightPower = math.min(flightPower + speedIncrement, maxFlightPower)
            updateFlightPower()
        elseif key == Enum.KeyCode.Down then
            flightPower = math.max(flightPower - speedIncrement, minFlightPower)
            updateFlightPower()
        elseif key == Enum.KeyCode.F then
            if isFlying then
                onToolDeactivated()
            else
                onToolActivated()
            end
        end
    end)
end

initializeTool()

-- ФУНКЦИИ УПРАВЛЕНИЯ ПОЛЕТОМ
-- Обработчик активации инструмента
function onToolActivated()
    if not torso then
        warn("Торс не найден, полет невозможен.")
        return
    end

    -- Настройка компонентов для полета
    bodyPosition.Parent = torso
    bodyPosition.Position = torso.Position + Vector3.new(0, 10, 0)
    bodyGyro.Parent = torso

    characterModel.Humanoid.PlatformStand = true

    -- Создание эффекта частиц
    particleEmitter = Instance.new("ParticleEmitter", torso)
    particleEmitter.Texture = "rbxassetid://243098098" -- ID текстуры частицы
    particleEmitter.Rate = 100
    particleEmitter.Lifetime = NumberRange.new(1, 2)
    particleEmitter.Speed = NumberRange.new(5, 10)
    particleEmitter.VelocitySpread = 180

    for _, motor in ipairs(torso:GetChildren()) do
        if motor:IsA("Motor") then
            motor.MaxVelocity = 0
            motor.CurrentAngle = -1
            if motor.Name == "Left Hip" then
                motor.CurrentAngle = 1
            end
        end
    end

    isFlying = true
    while isFlying do
        local mousePos = playerMouse.Hit.p
        bodyGyro.CFrame = CFrame.new(torso.Position, mousePos) * CFrame.fromEulerAnglesXYZ(-math.pi / 2, 0, 0)
        bodyPosition.Position = torso.Position + (mousePos - torso.Position).unit * flightPower
        wait(0.1) -- Уменьшение частоты обновления для улучшения производительности
    end
end

-- Обработчик деактивации инструмента
function onToolDeactivated()
    if not torso then
        warn("Торс не найден, невозможно остановить полет.")
        return
    end

    bodyGyro.Parent = nil
    bodyPosition.Parent = nil
    isFlying = false

    if particleEmitter then
        particleEmitter:Destroy()
        particleEmitter = nil
    end

    characterModel.Humanoid.PlatformStand = false

    for _, motor in ipairs(torso:GetChildren()) do
        if motor:IsA("Motor") then
            motor.MaxVelocity = 1
        end
    end
end

flyingTool.Unequipped:Connect(function() isFlying = false end)
flyingTool.Activated:Connect(onToolActivated)
flyingTool.Deactivated:Connect(onToolDeactivated)
