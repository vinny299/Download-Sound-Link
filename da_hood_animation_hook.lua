-- Da Hood animation hook (client-side)
-- 1) ใส่ ANIM_ID  2) รันใน executor  3) ดู log ใน console (F9)
-- หมายเหตุ: animation ต้องเป็นของเรา/เจ้าของเกมเท่านั้น ไม่งั้น Roblox โหลดไม่ได้ (Length จะเป็น 0)

local ANIM_ID = "rbxassetid://0"
local SPEED, LOOPED = 1, true

if getgenv().DH_ANIM_CLEANUP then pcall(getgenv().DH_ANIM_CLEANUP) end

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local LogService = game:GetService("LogService")
local lp = Players.LocalPlayer

local mine, conns, alive = setmetatable({}, {__mode = "k"}), {}, true
local animator, track

-- กันเกมสั่ง Stop/Destroy/ปรับ weight ของ track เรา
local old
old = hookmetamethod(game, "__namecall", function(self, ...)
    local m = getnamecallmethod()
    if alive and not checkcaller() and mine[self] then
        if m == "Stop" or m == "Destroy" or m == "AdjustWeight" then
            warn("[HOOK] blocked", m, "on our track")
            return nil
        end
    end
    return old(self, ...)
end)

-- error ของ engine เกี่ยวกับ animation
conns[#conns + 1] = LogService.MessageOut:Connect(function(msg)
    if msg:lower():find("animation") then warn("[ENGINE]", msg) end
end)

local function load(char)
    local hum = char:WaitForChild("Humanoid", 10)
    if not hum then return end
    animator = hum:FindFirstChildOfClass("Animator") or hum:WaitForChild("Animator", 5)
    if not animator then warn("[ANIM] ไม่เจอ Animator") return end

    local a = Instance.new("Animation")
    a.AnimationId = ANIM_ID
    local ok, tr = pcall(function() return animator:LoadAnimation(a) end)
    if not ok or not tr then warn("[ANIM] LoadAnimation fail:", tr) return end

    local t0 = os.clock()
    while tr.Length == 0 and os.clock() - t0 < 3 do task.wait() end
    if tr.Length == 0 then
        warn("[ANIM] โหลดไม่สำเร็จ (Length=0) -> ID นี้ไม่ใช่ของเรา/เจ้าของเกม หรือ ID ผิด")
    end

    mine[tr] = true
    tr.Priority, tr.Looped = Enum.AnimationPriority.Action4, LOOPED
    tr:Play()
    tr:AdjustSpeed(SPEED)
    track = tr
end

-- เฝ้า: track หยุด / Animator ถูกลบหรือแทนที่ -> เล่นใหม่
conns[#conns + 1] = RunService.Heartbeat:Connect(function()
    local char = lp.Character
    if not (alive and char) then return end
    if animator and not animator:IsDescendantOf(char) then
        track, animator = nil, nil
        task.spawn(load, char)
    elseif track and not track.IsPlaying then
        track:Play()
        track:AdjustSpeed(SPEED)
    end
end)

conns[#conns + 1] = lp.CharacterAdded:Connect(function(c) track, animator = nil, nil task.spawn(load, c) end)
if lp.Character then task.spawn(load, lp.Character) end

getgenv().DH_ANIM_CLEANUP = function()
    alive = false
    for _, c in ipairs(conns) do c:Disconnect() end
    if track then mine[track] = nil pcall(function() track:Stop() end) end
end
