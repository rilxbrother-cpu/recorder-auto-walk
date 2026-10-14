-- ============================================
-- AUTO WALK RECORDER v3 - CAMERA FREE
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
local recordInterval = 0.1
local recordTimer = 0

-- ============================================
-- GUI
-- ============================================
local gui = Instance.new("ScreenGui")
gui.Name = "AutoWalkRecorder"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 200, 0, 180)
frame.Position = UDim2.new(0, 20, 0.5, -90)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
frame.BorderSizePixel = 0
frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

local recordBtn = Instance.new("TextButton")
recordBtn.Size = UDim2.new(0.9, 0, 0, 38)
recordBtn.Position = UDim2.new(0.05, 0, 0, 10)
recordBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
recordBtn.Text = "● RECORD"
recordBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
recordBtn.Font = Enum.Font.GothamBold
recordBtn.TextSize = 14
recordBtn.Parent = frame
Instance.new("UICorner", recordBtn).CornerRadius = UDim.new(0, 6)

local copyBtn = Instance.new("TextButton")
copyBtn.Size = UDim2.new(0.9, 0, 0, 38)
copyBtn.Position = UDim2.new(0.05, 0, 0, 55)
copyBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 200)
copyBtn.Text = "📋 COPY JSON"
copyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
copyBtn.Font = Enum.Font.GothamBold
copyBtn.TextSize = 14
copyBtn.Parent = frame
Instance.new("UICorner", copyBtn).CornerRadius = UDim.new(0, 6)

local playBtn = Instance.new("TextButton")
playBtn.Size = UDim2.new(0.9, 0, 0, 38)
playBtn.Position = UDim2.new(0.05, 0, 0, 100)
playBtn.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
playBtn.Text = "▶ PLAYBACK"
playBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
playBtn.Font = Enum.Font.GothamBold
playBtn.TextSize = 14
playBtn.Parent = frame
Instance.new("UICorner", playBtn).CornerRadius = UDim.new(0, 6)

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, 0, 0, 25)
status.Position = UDim2.new(0, 0, 1, -25)
status.BackgroundTransparency = 1
status.Text = "Ready"
status.TextColor3 = Color3.fromRGB(200, 200, 200)
status.Font = Enum.Font.Gotham
status.TextSize = 11
status.Parent = frame

-- ============================================
-- RECORD
-- ============================================
local function startRecording()
    recordedPath = {}
    isRecording = true
    recordTimer = 0
    status.Text = "● Recording..."
    status.TextColor3 = Color3.fromRGB(255, 100, 100)
end

local function stopRecording()
    isRecording = false
    status.Text = "Saved: " .. #recordedPath .. " frames"
    status.TextColor3 = Color3.fromRGB(100, 255, 100)
end

-- ============================================
-- COPY JSON
-- ============================================
local function copyJSON()
    if #recordedPath == 0 then
        status.Text = "No data!"
        return
    end
    
    local data = {}
    for _, cf in ipairs(recordedPath) do
        local rx, ry, rz = cf:ToEulerAnglesXYZ()
        table.insert(data, {
            p = {math.floor(cf.X*100)/100, math.floor(cf.Y*100)/100, math.floor(cf.Z*100)/100},
            r = {math.floor(rx*1000)/1000, math.floor(ry*1000)/1000, math.floor(rz*1000)/1000}
        })
    end
    
    local json = HttpService:JSONEncode(data)
    
    if setclipboard then
        setclipboard(json)
        status.Text = "✅ Copied! " .. #json .. " bytes"
        status.TextColor3 = Color3.fromRGB(100, 255, 100)
    else
        status.Text = "❌ No clipboard"
        print(json)
    end
end

-- ============================================
-- PLAYBACK (MOVE + JALAN ANIMASI)
-- ============================================
local function playback()
    if isRecording or isPlaying then return end
    if #recordedPath == 0 then
        status.Text = "No data!"
        return
    end
    
    isPlaying = true
    status.Text = "▶ Playing..."
    status.TextColor3 = Color3.fromRGB(100, 200, 255)
    
    task.spawn(function()
        for i, cf in ipairs(recordedPath) do
            if not humanoid.Parent or not isPlaying then break end
            
            -- Kalo karakter jauh dari target, pake MoveTo
            local distance = (rootPart.Position - cf.Position).Magnitude
            
            if distance > 3 then
                humanoid:MoveTo(cf.Position)
                
                -- Tunggu sampe nyampe atau timeout
                local waited = 0
                while (rootPart.Position - cf.Position).Magnitude > 2 and waited < 30 do
                    task.wait(0.05)
                    waited += 1
                    if not isPlaying then break end
                end
            else
                -- Kalo deket, langsung set CFrame biar presisi
                rootPart.CFrame = CFrame.new(cf.Position) * CFrame.Angles(cf:ToEulerAnglesXYZ())
                task.wait(recordInterval)
            end
        end
        
        humanoid:MoveTo(rootPart.Position) -- Stop
        isPlaying = false
        status.Text = "Done!"
        status.TextColor3 = Color3.fromRGB(100, 255, 100)
    end)
end

-- ============================================
-- EVENT
-- ============================================
recordBtn.MouseButton1Click:Connect(function()
    if isRecording then stopRecording() else startRecording() end
end)

copyBtn.MouseButton1Click:Connect(copyJSON)
playBtn.MouseButton1Click:Connect(playback)

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
        status.Text = "● Rec: " .. #recordedPath
    end
end)

-- ============================================
-- RESPAWN HANDLER
-- ============================================
player.CharacterAdded:Connect(function(newChar)
    isRecording = false
    isPlaying = false
    character = newChar
    humanoid = newChar:WaitForChild("Humanoid")
    rootPart = newChar:WaitForChild("HumanoidRootPart")
    status.Text = "Respawned"
    status.TextColor3 = Color3.fromRGB(200, 200, 200)
end)

print("[AutoWalk v3] Camera-Free Ready!")