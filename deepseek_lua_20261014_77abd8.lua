-- ============================================
-- AUTO WALK RECORDER + DRIVE LOADER
-- by EGX AI untuk Tuan Rilx
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
local recordInterval = 0.05  -- 20 FPS
local recordTimer = 0

-- ============================================
-- GUI
-- ============================================
local gui = Instance.new("ScreenGui")
gui.Name = "AutoWalkRecorder"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

-- Frame utama
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 280, 0, 320)
frame.Position = UDim2.new(0, 20, 0.5, -160)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)

-- Title
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 35)
title.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
title.Text = "🎮 Auto Walk Recorder"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 15
title.Parent = frame
Instance.new("UICorner", title).CornerRadius = UDim.new(0, 12)

-- ============================================
-- FUNGSI BIKIN TOMBOL
-- ============================================
local function makeButton(text, yPos, color, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.9, 0, 0, 38)
    btn.Position = UDim2.new(0.05, 0, 0, yPos)
    btn.BackgroundColor3 = color
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.Parent = frame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

-- Tombol RECORD
local recordBtn = makeButton("● RECORD", 45, Color3.fromRGB(200, 50, 50), function()
    if isRecording then
        -- STOP RECORDING
        isRecording = false
        recordBtn.Text = "● RECORD"
        recordBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        status.Text = "Saved: " .. #recordedPath .. " frames"
        status.TextColor3 = Color3.fromRGB(100, 255, 100)
    else
        -- START RECORDING
        recordedPath = {}
        isRecording = true
        recordTimer = 0
        recordBtn.Text = "■ STOP"
        recordBtn.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
        status.Text = "● Recording..."
        status.TextColor3 = Color3.fromRGB(255, 100, 100)
    end
end)

-- Tombol COPY JSON
local copyBtn = makeButton("📋 COPY JSON", 90, Color3.fromRGB(50, 150, 200), function()
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

-- Tombol PLAYBACK
local playBtn = makeButton("▶ PLAYBACK (LOCAL)", 135, Color3.fromRGB(100, 200, 100), function()
    if isRecording or isPlaying then return end
    if #recordedPath == 0 then
        status.Text = "❌ No data!"
        status.TextColor3 = Color3.fromRGB(255, 100, 100)
        return
    end
    
    isPlaying = true
    status.Text = "▶ Playing..."
    status.TextColor3 = Color3.fromRGB(100, 200, 255)
    
    task.spawn(function()
        local RunService = game:GetService("RunService")
        local char = player.Character
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return end
        
        for i = 1, #recordedPath - 1 do
            if not isPlaying or not root.Parent then break end
            
            local currentCF = recordedPath[i]
            local nextCF = recordedPath[i + 1]
            local startTime = tick()
            
            while tick() - startTime < recordInterval do
                if not isPlaying or not root.Parent then break end
                local alpha = math.min((tick() - startTime) / recordInterval, 1)
                root.CFrame = currentCF:Lerp(nextCF, alpha)
                RunService.RenderStepped:Wait()
            end
        end
        
        if root.Parent and #recordedPath > 0 then
            root.CFrame = recordedPath[#recordedPath]
        end
        
        isPlaying = false
        status.Text = "Done! (no loop)"
        status.TextColor3 = Color3.fromRGB(100, 255, 100)
    end)
end)

-- ============================================
-- INPUT LINK DRIVE
-- ============================================
local linkLabel = Instance.new("TextLabel")
linkLabel.Size = UDim2.new(0.9, 0, 0, 20)
linkLabel.Position = UDim2.new(0.05, 0, 0, 180)
linkLabel.BackgroundTransparency = 1
linkLabel.Text = "🔗 Link Google Drive JSON:"
linkLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
linkLabel.Font = Enum.Font.Gotham
linkLabel.TextSize = 12
linkLabel.TextXAlignment = Enum.TextXAlignment.Left
linkLabel.Parent = frame

local linkBox = Instance.new("TextBox")
linkBox.Size = UDim2.new(0.9, 0, 0, 32)
linkBox.Position = UDim2.new(0.05, 0, 0, 202)
linkBox.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
linkBox.TextColor3 = Color3.fromRGB(255, 255, 255)
linkBox.PlaceholderText = "Paste link Drive di sini..."
linkBox.PlaceholderColor3 = Color3.fromRGB(120, 120, 130)
linkBox.Font = Enum.Font.Gotham
linkBox.TextSize = 12
linkBox.Text = ""
linkBox.ClearTextOnFocus = false
linkBox.Parent = frame
Instance.new("UICorner", linkBox).CornerRadius = UDim.new(0, 6)

-- Tombol LOAD DARI DRIVE
local loadBtn = makeButton("⬇ LOAD FROM DRIVE", 242, Color3.fromRGB(200, 130, 50), function()
    local link = linkBox.Text
    if link == "" or link == nil then
        status.Text = "❌ Link kosong!"
        status.TextColor3 = Color3.fromRGB(255, 100, 100)
        return
    end
    
    status.Text = "⏳ Loading..."
    status.TextColor3 = Color3.fromRGB(255, 200, 100)
    
    task.spawn(function()
        local success, err = pcall(function()
            -- Konversi link view ke direct download
            local fileId = link:match("/d/([%w%-_]+)")
            if not fileId then
                fileId = link:match("id=([%w%-_]+)")
            end
            
            if not fileId then
                error("Link Drive gak valid!")
            end
            
            local directLink = "https://drive.google.com/uc?export=download&id=" .. fileId
            
            -- Download JSON
            local json = game:HttpGet(directLink)
            local data = HttpService:JSONDecode(json)
            
            if type(data) ~= "table" then
                error("Format JSON salah!")
            end
            
            -- Konversi balik ke CFrame
            recordedPath = {}
            for _, item in ipairs(data) do
                local pos = item.p or item.pos
                local rot = item.r or item.rot
                
                if pos and rot then
                    local cf = CFrame.new(pos[1], pos[2], pos[3]) 
                        * CFrame.Angles(rot[1], rot[2], rot[3])
                    table.insert(recordedPath, cf)
                end
            end
            
            status.Text = "✅ Loaded! " .. #recordedPath .. " frames"
            status.TextColor3 = Color3.fromRGB(100, 255, 100)
        end)
        
        if not success then
            status.Text = "❌ " .. tostring(err)
            status.TextColor3 = Color3.fromRGB(255, 100, 100)
        end
    end)
end)

-- ============================================
-- TOMBOL PLAYBACK DARI DRIVE
-- ============================================
local playDriveBtn = makeButton("▶ PLAY FROM DRIVE", 285, Color3.fromRGB(130, 80, 200), function()
    -- Auto load lalu play
    local link = linkBox.Text
    if link == "" then
        status.Text = "❌ Paste link dulu!"
        status.TextColor3 = Color3.fromRGB(255, 100, 100)
        return
    end
    
    status.Text = "⏳ Loading & Playing..."
    status.TextColor3 = Color3.fromRGB(200, 150, 255)
    
    task.spawn(function()
        local success, err = pcall(function()
            local fileId = link:match("/d/([%w%-_]+)") or link:match("id=([%w%-_]+)")
            if not fileId then error("Link Drive gak valid!") end
            
            local directLink = "https://drive.google.com/uc?export=download&id=" .. fileId
            local json = game:HttpGet(directLink)
            local data = HttpService:JSONDecode(json)
            
            recordedPath = {}
            for _, item in ipairs(data) do
                local pos = item.p or item.pos
                local rot = item.r or item.rot
                if pos and rot then
                    table.insert(recordedPath, 
                        CFrame.new(pos[1], pos[2], pos[3]) * CFrame.Angles(rot[1], rot[2], rot[3]))
                end
            end
            
            status.Text = "▶ Playing " .. #recordedPath .. " frames..."
            
            -- Playback
            local char = player.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if not root then error("Karakter gak ada!") end
            
            isPlaying = true
            for i = 1, #recordedPath - 1 do
                if not isPlaying or not root.Parent then break end
                
                local currentCF = recordedPath[i]
                local nextCF = recordedPath[i + 1]
                local startTime = tick()
                
                while tick() - startTime < recordInterval do
                    if not isPlaying or not root.Parent then break end
                    local alpha = math.min((tick() - startTime) / recordInterval, 1)
                    root.CFrame = currentCF:Lerp(nextCF, alpha)
                    RunService.RenderStepped:Wait()
                end
            end
            
            if root.Parent and #recordedPath > 0 then
                root.CFrame = recordedPath[#recordedPath]
            end
            
            isPlaying = false
            status.Text = "✅ Done!"
            status.TextColor3 = Color3.fromRGB(100, 255, 100)
        end)
        
        if not success then
            status.Text = "❌ " .. tostring(err)
            status.TextColor3 = Color3.fromRGB(255, 100, 100)
            isPlaying = false
        end
    end)
end)

-- Tombol CLEAR
local clearBtn = makeButton("🗑 CLEAR", 330, Color3.fromRGB(80, 80, 80), function()
    recordedPath = {}
    status.Text = "🗑 Cleared"
    status.TextColor3 = Color3.fromRGB(200, 200, 200)
end)

-- ============================================
-- STATUS BAR
-- ============================================
local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, 0, 0, 22)
status.Position = UDim2.new(0, 0, 1, -25)
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
-- RESPAWN HANDLER
-- ============================================
player.CharacterAdded:Connect(function(newChar)
    isRecording = false
    isPlaying = false
    character = newChar
    humanoid = newChar:WaitForChild("Humanoid")
    rootPart = newChar:WaitForChild("HumanoidRootPart")
    recordBtn.Text = "● RECORD"
    recordBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    status.Text = "Respawned"
    status.TextColor3 = Color3.fromRGB(200, 200, 200)
end)

print("[AutoWalk+Drive] Ready! by EGX AI")