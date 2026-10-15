-- autoreplay.lua
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local hrp = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")

-- Paste isi soreya-v1.json di sini
local JSON_DATA = [[
PASTE_ISI_JSON_DISINI
]]

local data = HttpService:JSONDecode(JSON_DATA)

-- Matikan kontrol player
humanoid.WalkSpeed = 0
humanoid.AutoRotate = false

task.wait(2)
print("[ZmZ] Replay mulai. Frames:", #data)

local startTime = tick()
for i, frame in ipairs(data) do
    local t = frame.time
    local elapsed = tick() - startTime
    if elapsed < t then
        task.wait(t - elapsed)
    end

    local p = frame.position
    local r = frame.rotation or 0

    hrp.CFrame = CFrame.new(p.x, p.y, p.z) * CFrame.Angles(0, r, 0)

    if frame.velocity then
        hrp.AssemblyLinearVelocity = Vector3.new(
            frame.velocity.x,
            frame.velocity.y,
            frame.velocity.z
        )
    end

    if frame.walkSpeed then
        humanoid.WalkSpeed = frame.walkSpeed
    end

    if frame.jumping then
        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    elseif frame.state == 5 then
        humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
    elseif frame.state == 7 then
        humanoid:ChangeState(Enum.HumanoidStateType.Landed)
    elseif frame.state == 8 then
        humanoid:ChangeState(Enum.HumanoidStateType.Running)
    end
end

print("[ZmZ] Replay selesai.")