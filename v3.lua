-- ============================================
-- AUTO WALK RECORDER v2 - WITH STOP PLAYBACK
-- ============================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

-- DATA
local recordedPath = {}
local isRecording = false
local isPlaying = false
local recordInterval = 0.03
local recordTimer = 0

-- ============================================
-- GUI
-- ============================================
local gui = Instance.new("ScreenGui")
gui.Name = "AutoWalkRecorder"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 220, 0, 290)
frame.Position = UDim2.new(0, 20, 0.5, -145)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

-- Title
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
title.Text = "🎮 Auto Walk Recorder"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 13
title.Parent = frame
Instance.new("UICorner", title).CornerRadius = UDim.new(0, 10)

-- ============================================
-- FUNGSI BIKIN TOMBOL
-- ============================================
local function makeButton(text, yPos, color, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.9, 0, 0, 36)
    btn.Position = UDim2.new(0.05, 0, 0, yPos)
    btn.BackgroundColor3 = color
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.Parent = frame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

-- Tombol RECORD
local recordBtn = makeButton("● RECORD", 38, Color3.fromRGB(200, 50, 50), function()
    if isRecording then
        isRecording = false
        recordBtn.Text = "● RECORD"
        recordBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        status.Text = "Saved: " .. #recordedPath .. " frames"
        status.TextColor3 = Color3.fromRGB(100, 255, 100)
    else
        recordedPath = {}
        isRecording = true
        recordTimer = 0
        recordBtn.Text = "■ STOP REC"
        recordBtn.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
        status.Text = "● Recording..."
        status.TextColor3 = Color3.fromRGB(255, 100, 100)
    end
end)

-- Tombol PLAYBACK
local playBtn = makeButton("▶ PLAYBACK", 80, Color3.fromRGB(100, 200, 100), function()
    if isRecording or isPlaying then return end
    if #recordedPath == 0 then
        status.Text = "❌ No data!"
        return
    end
    
    isPlaying = true
    playBtn.Text = "▶ PLAYING..."
    playBtn.BackgroundColor3 = Color3.fromRGB(150, 255, 150)
    status.Text = "▶ Playing..."
    
    task.spawn(function()
        local char = player.Character
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChild("Humanoid")
        if not root or not hum then return end
        
        hum.AutoRotate = true
        
        for i = 1, #recordedPath do
            if not isPlaying then break end
            if not root.Parent then break end
            
            local targetCF = recordedPath[i]
            root.CFrame = CFrame.new(targetCF.Position, targetCF.Position + targetCF.LookVector)
            
            if i < #recordedPath then
                local nextPos = recordedPath[i + 1].Position
                local dir = (nextPos - targetCF.Position)
                if dir.Magnitude > 0.5 then
                    hum:Move(dir.Unit, false)
                end
            end
            
            task.wait(recordInterval)
        end
        
        if hum and hum.Parent then
            hum:Move(Vector3.new(0, 0, 0), false)
        end
        
        isPlaying = false
        playBtn.Text = "▶ PLAYBACK"
        playBtn.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
        status.Text = "✅ Done!"
    end)
end)
-- Tombol STOP PLAYBACK
local stopBtn = makeButton("■ STOP PLAYBACK", 122, Color3.fromRGB(200, 100, 50), function()
    if not isPlaying then
        status.Text = "❌ Gak lagi playback"
        status.TextColor3 = Color3.fromRGB(255, 200, 100)
        return
    end
    
    isPlaying = false
    
    -- Stop karakter
    local char = player.Character
    if char then
        local hum = char:FindFirstChild("Humanoid")
        if hum then
            hum:Move(Vector3.new(0, 0, 0), false)
        end
    end
    
    playBtn.Text = "▶ PLAYBACK"
    playBtn.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
    status.Text = "🛑 Stopped"
    status.TextColor3 = Color3.fromRGB(255, 150, 100)
end)

-- Tombol COPY JSON
local copyBtn = makeButton("📋 COPY JSON", 164, Color3.fromRGB(50, 150, 200), function()
    if #recordedPath == 0 then
        status.Text = "❌ No data!"
        status.TextColor3 = Color3.fromRGB(255, 100, 100)
        return
    end
    
    local data = {}
    for _, cf in ipairs(recordedPath) do
        local rx, ry, rz = cf:ToEulerAnglesXYZ()
        table.insert(data, {
            p = {
                math.floor(cf.X * 100) / 100,
                math.floor(cf.Y * 100) / 100,
                math.floor(cf.Z * 100) / 100
            },
            r = {
                math.floor(rx * 1000) / 1000,
                math.floor(ry * 1000) / 1000,
                math.floor(rz * 1000) / 1000
            }
        })
    end
    
    local json = HttpService:JSONEncode(data)
    
    if setclipboard then
        setclipboard(json)
        status.Text = "✅ Copied! " .. #json .. " bytes"
        status.TextColor3 = Color3.fromRGB(100, 255, 100)
    else
        status.Text = "❌ No clipboard"
        status.TextColor3 = Color3.fromRGB(255, 100, 100)
        print(json)
    end
end)

-- Tombol CLEAR
local clearBtn = makeButton("🗑 CLEAR", 206, Color3.fromRGB(80, 80, 80), function()
    recordedPath = {}
    status.Text = "🗑 Cleared"
    status.TextColor3 = Color3.fromRGB(200, 200, 200)
end)

-- Status bar
local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, 0, 0, 20)
status.Position = UDim2.new(0, 0, 1, -22)
status.BackgroundTransparency = 1
status.Text = "Ready"
status.TextColor3 = Color3.fromRGB(200, 200, 200)
status.Font = Enum.Font.Gotham
status.TextSize = 11
status.Parent = frame

-- ============================================
-- LOOP RECORD
-- ============================================
RunService.Heartbeat:Connect(function(dt)
    if not isRecording then return end
    if not rootPart or not rootPart.Parent then return end
    
    recordTimer += dt
    if recordTimer >= recordInterval then
        recordTimer = 0
        table.insert(recordedPath, rootPart.CFrame)
        status.Text = "● Rec: " .. #recordedPath .. " frames"
    end
end)

-- ============================================
-- RESPAWN
-- ============================================
player.CharacterAdded:Connect(function(newChar)
    isRecording = false
    isPlaying = false
    character = newChar
    humanoid = newChar:WaitForChild("Humanoid")
    rootPart = newChar:WaitForChild("HumanoidRootPart")
    recordBtn.Text = "● RECORD"
    recordBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    playBtn.Text = "▶ PLAYBACK"
    playBtn.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
    status.Text = "Respawned"
    status.TextColor3 = Color3.fromRGB(200, 200, 200)
end)

print("[AutoWalk v2] Ready with STOP PLAYBACK!")
