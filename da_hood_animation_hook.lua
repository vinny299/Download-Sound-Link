-- Da Hood animation hook (compact). Set ANIM_ID, run, read console (F9).
-- Animation must be owned by you or the game, else Length stays 0.
local ANIM_ID = "rbxassetid://0"
local lp = game:GetService("Players").LocalPlayer
if getgenv().DH_STOP then pcall(getgenv().DH_STOP) end
local on, mine, track, cur = true, setmetatable({}, {__mode = "k"}), nil, nil

local old
old = hookmetamethod(game, "__namecall", function(self, ...)
    local m = getnamecallmethod()
    if on and mine[self] and not checkcaller() and (m == "Stop" or m == "Destroy" or m == "AdjustWeight") then
        return nil
    end
    return old(self, ...)
end)

local function load()
    local hum = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
    local an = hum and hum:FindFirstChildOfClass("Animator")
    if not an then return end
    local a = Instance.new("Animation")
    a.AnimationId = ANIM_ID
    local ok, tr = pcall(function() return an:LoadAnimation(a) end)
    if not ok then warn("[ANIM] LoadAnimation failed:", tr) return end
    mine[tr] = true
    tr.Priority = Enum.AnimationPriority.Action4
    tr.Looped = true
    tr:Play()
    track, cur = tr, an
    task.delay(3, function() if tr.Length == 0 then warn("[ANIM] Length=0: bad or not-owned ID") end end)
end

task.spawn(function()
    while on do
        local hum = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
        local an = hum and hum:FindFirstChildOfClass("Animator")
        if an and (not track or cur ~= an) then
            load()
        elseif track and not track.IsPlaying then
            track:Play()
        end
        task.wait(0.2)
    end
end)

getgenv().DH_STOP = function() on = false if track then mine[track] = nil pcall(function() track:Stop() end) end end
