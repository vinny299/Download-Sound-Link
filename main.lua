loadstring([[
    function LPH_NO_VIRTUALIZE(f) return f end;
]])();

if getgenv().__warz_unload then
    pcall(getgenv().__warz_unload)
end

do
    local ok, runtime_status = pcall(function()
        local client_folder = game:GetService("Players").LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("Client")
        return require(client_folder:WaitForChild("RuntimeStatus", 10))
    end)
    if ok and type(runtime_status) == "table" and not table.isfrozen(runtime_status) then
        runtime_status.Caption = function()
            return 0
        end
        runtime_status.Matches = function()
            return false
        end
    end
    if not getgenv().__warz_runtime_status_block then
        local remote = game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("RuntimeStatus", 10)
        if remote then
            getgenv().__warz_runtime_status_block = true
            local old_namecall
            old_namecall = hookmetamethod(game, "__namecall", newcclosure(LPH_NO_VIRTUALIZE(function(self, ...)
                if self == remote and getnamecallmethod() == "FireServer" then
                    return nil
                end
                return old_namecall(self, ...)
            end)))
        end
    end
end

local repo = "https://raw.githubusercontent.com/cloudsense-pub/UELinoriaLib/main/"

local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Options = getgenv().Options
local Toggles = getgenv().Toggles

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local localplayer = Players.LocalPlayer

local config = {
    enabled = false,
    hit_parts = {Head = true},
    hit_mode = "Random",
    prediction = true,
    drop = true,
    look_spoof = true,
    max_distance = 300,
    wallcheck = true,
    teamcheck = true,
    clancheck = false,
    protect_check = true,
    whitelist = {},
    aimbot = false,
    aimbot_part = "Head",
    aimbot_smooth = 5,
    aimbot_fov = 150,
    aimbot_show_fov = true,
    aimbot_fov_color = Color3.fromRGB(255, 120, 60),
    aimbot_wallcheck = true,
    aimbot_prediction = true,
    aimbot_sticky = true,
    fov = 120,
    show_fov = true,
    fov_color = Color3.fromRGB(255, 255, 255),
    show_target = true,
    target_dot_color = Color3.fromRGB(255, 60, 60),
    target_tracer = false,
    target_tracer_color = Color3.fromRGB(255, 60, 60),
    bullet_tracer = false,
    bullet_tracer_type = "Beam",
    bullet_tracer_style = "Laser",
    bullet_tracer_color = Color3.fromRGB(133, 220, 255),
    bullet_tracer_alpha = 0,
    bullet_tracer_gradient = Color3.fromRGB(241, 133, 255),
    bullet_tracer_gradient_alpha = 0,
    bullet_tracer_outline = Color3.fromRGB(15, 15, 15),
    bullet_tracer_outline_alpha = 0,
    bullet_tracer_time = 0.8,
    no_spread = false,
    no_recoil = false,
    auto_gun = false,
    rapid_fire = false,
    rapid_fire_rate = 1.5,
    auto_shoot = false,
    auto_reload = true,
    anti_aim = false,
    aa_yaw = "Spin",
    aa_pitch = "None",
    aa_speed = 20,
    aa_jitter = 35,
    aa_static = 180,
    aa_visualize = true,
    wallbang = false,
    wallbang_radius = 4.5,

    auto_heal = false,
    heal_below = 50,
    heal_items = {BandagesDX = true},
    underground = false,
    underground_depth = 10,
    underground_prone = true,
    underground_max_under = 4,
    underground_surface = 1.5,
    auto_wall = false,
    wall_item = "Any",
    wall_cooldown = 4,
    auto_pickup = false,
    instant_pickup = false,

    esp = {
        enabled = false,
        box = true,
        name = true,
        name_mode = "Display",
        health = true,
        distance = true,
        weapon = true,
        text_size = 13,
        max_distance = 1000,
        teamcheck = false,
        color = Color3.fromRGB(255, 255, 255),
        team_color = Color3.fromRGB(80, 255, 120),
        target_color = Color3.fromRGB(255, 60, 60),
    },

    world = {
        time = false,
        time_value = 4.5,
        lighting = false,
        ambient = false,
        saturation = false,
        saturation_value = 0,
        contrast = false,
        contrast_value = 0,
        tint = false,
        tint_color = Color3.fromRGB(255, 255, 255),
        textures = false,
        texture_pack = "Minecraft",
        skybox = false,
        skybox_value = "Black Storm",
        atmosphere = false,
        atmosphere_color = Color3.fromRGB(255, 255, 255),
        atmosphere_decay = Color3.fromRGB(120, 120, 120),
        atmosphere_density = 0.35,
        atmosphere_offset = 0,
        atmosphere_haze = 1,
        atmosphere_glare = 10,
        weather = false,
        weather_type = "Rain",
        weather_color = Color3.fromRGB(255, 255, 255),
        weather_rate = 100,
        noise = false,
        noise_sound = "Night",
        noise_volume = 25,
    },
}
getgenv().WarzSilent = config

local esp = config.esp

local client = localplayer:WaitForChild("PlayerScripts"):WaitForChild("Client")
local shared = ReplicatedStorage:WaitForChild("Shared")
local remotes = ReplicatedStorage:WaitForChild("Remotes")

local hitboxes = require(shared.warz.WarzHitboxes)
local projectile = require(shared.WarzProjectile)
local solid_probe = require(shared.SolidProbe)
local game_config = require(shared.Config)
local combat_settings = require(client.input.CombatSettings)
local warz_camera = require(client.world.WarzCamera)
local fps_view = require(client.world.FpsView)
local aim_assist = require(client.world.MobileAimAssist)
local combat_input = require(client.input.CombatInput)
local barricade = require(shared.WarzBarricade)

local fire_remote = remotes:WaitForChild("FireRequest")
local pose_remote = remotes:WaitForChild("PoseSync")
local use_item_remote = remotes:WaitForChild("UseItem")
local pickup_remote = remotes:WaitForChild("PickupLoot")
local loot_hold_module = require(client.world.LootHold)

local SCALE = projectile.Scale

local enemy_set
pcall(function()
    local value = debug.getupvalue(aim_assist.UpdateHud, 1)
    if type(value) == "table" then
        enemy_set = value
    end
end)

local LCG_A, LCG_C, LCG_M = 1664525, 1013904223, 2147483647
local SEED_EPS = 0.002

local mulmod = LPH_NO_VIRTUALIZE(function(a, b)
    local hi, lo = b // 65536, b % 65536
    return ((a * hi) % LCG_M * 65536 + a * lo) % LCG_M
end)

local function powmod(base, exp)
    local result = 1
    base %= LCG_M
    while exp > 0 do
        if exp % 2 == 1 then
            result = mulmod(result, base)
        end
        base = mulmod(base, base)
        exp //= 2
    end
    return result
end

local LCG_A_INV = powmod(LCG_A, LCG_M - 2)

local fresh_spread_seed = LPH_NO_VIRTUALIZE(function()
    local window = math.floor(SEED_EPS * LCG_M)
    local half = LCG_M // 2
    for _ = 1, 4000 do
        local u2 = half + math.random(-window, window)
        local u3 = (u2 * LCG_A + LCG_C) % LCG_M
        if math.abs(u3 / LCG_M - 0.5) < SEED_EPS then
            local u1 = mulmod((u2 - LCG_C) % LCG_M, LCG_A_INV)
            if u1 >= 1 then
                return (u1 - 1 + 0.1 + math.random() * 0.8) / 2147483646
            end
        end
    end
end)

local spread_seed_ok = pcall(function()
    local rng_from_seed = require(shared.WarzSpread).RngFromSeed
    for _ = 1, 20 do
        local rng = rng_from_seed(assert(fresh_spread_seed()))
        assert(math.abs(rng() - 0.5) < SEED_EPS * 1.01 and math.abs(rng() - 0.5) < SEED_EPS * 1.01)
    end
end)

local part_groups = {
    Head = {"Bip01_Head"},
    Neck = {"Bip01_Neck", "Throat"},
    Torso = {"Bip01_Spine2", "Chest", "Bip01_Spine1", "Bip01_Spine", "Waist", "Bip01_Pelvis"},
    Arms = {"Bip01_L_UpperArm", "Bip01_L_Forearm", "Bip01_L_Hand", "Bip01_R_UpperArm", "Bip01_R_Forearm", "Bip01_R_Hand"},
    Legs = {"Bip01_L_Thigh", "Bip01_L_Calf", "Bip01_L_Foot", "Bip01_R_Thigh", "Bip01_R_Calf", "Bip01_R_Foot"},
}
local group_order = {"Head", "Neck", "Torso", "Arms", "Legs"}

local hit_part_names = {}

local function rebuild_hit_parts()
    table.clear(hit_part_names)
    for _, group in group_order do
        if config.hit_parts[group] then
            for _, name in part_groups[group] do
                table.insert(hit_part_names, name)
            end
        end
    end
end
rebuild_hit_parts()

local screen_center = LPH_NO_VIRTUALIZE(function()
    local vp = workspace.CurrentCamera.ViewportSize
    return Vector2.new(vp.X * 0.5, vp.Y * 0.5)
end)

local same_party = LPH_NO_VIRTUALIZE(function(player)
    local mine = localplayer:GetAttribute("WarzPartyId")
    return type(mine) == "string" and mine ~= "" and player:GetAttribute("WarzPartyId") == mine
end)

local same_clan = LPH_NO_VIRTUALIZE(function(player)
    local mine = localplayer:GetAttribute("ClanId")
    return type(mine) == "string" and mine ~= "" and player:GetAttribute("ClanId") == mine
end)

local not_match_enemy = LPH_NO_VIRTUALIZE(function(player)
    return enemy_set ~= nil and next(enemy_set) ~= nil and enemy_set[player.UserId] ~= true
end)

local is_teammate = LPH_NO_VIRTUALIZE(function(player)
    return same_party(player) or not_match_enemy(player) or (config.clancheck and same_clan(player))
end)

local spawn_protected = LPH_NO_VIRTUALIZE(function(player)
    return (tonumber(player:GetAttribute("WarzProtectUntil")) or 0) > workspace:GetServerTimeNow()
end)

local alive = LPH_NO_VIRTUALIZE(function(char)
    if not char or not char.Parent or not char:FindFirstChild("HumanoidRootPart") then
        return false
    end
    if char:GetAttribute("WarzDead") == true or char:GetAttribute("WarzHidden") == true then
        return false
    end
    local hum = char:FindFirstChildOfClass("Humanoid")
    return not hum or hum.Health > 0
end)

local skip_player = LPH_NO_VIRTUALIZE(function(player)
    if config.whitelist[player.Name] then
        return true
    end
    if config.teamcheck and (same_party(player) or not_match_enemy(player)) then
        return true
    end
    if config.clancheck and same_clan(player) then
        return true
    end
    return config.protect_check and spawn_protected(player)
end)

local target_chars = LPH_NO_VIRTUALIZE(function()
    local list = {}
    for _, player in Players:GetPlayers() do
        local char = player.Character
        if player ~= localplayer and alive(char) and not skip_player(player) then
            table.insert(list, char)
        end
    end
    local dummies = workspace:FindFirstChild("WarzDummies")
    if dummies then
        for _, dummy in dummies:GetChildren() do
            if dummy:IsA("Model") and alive(dummy) then
                table.insert(list, dummy)
            end
        end
    end
    return list
end)

local shape_cache = setmetatable({}, {__mode = "k"})

local get_shapes = LPH_NO_VIRTUALIZE(function(char)
    local now = os.clock()
    local cached = shape_cache[char]
    if cached and now - cached.time < 0.01 then
        return cached.map
    end
    local map = {}
    if char:GetAttribute("WarzDataHitboxes") == true then
        local ok, shapes = pcall(hitboxes.DataShapes, char)
        if ok and type(shapes) == "table" then
            for _, shape in shapes do
                if typeof(shape.cf) == "CFrame" and map[shape.name] == nil then
                    map[shape.name] = shape
                end
            end
        end
    else
        local folder = char:FindFirstChild("WarzHitboxes")
        if folder then
            for _, part in folder:GetChildren() do
                if part:IsA("BasePart") then
                    map[part.Name] = {name = part.Name, cf = part.CFrame, size = part.Size}
                end
            end
        end
    end
    shape_cache[char] = {time = now, map = map}
    return map
end)

local world_params = RaycastParams.new()
world_params.FilterType = Enum.RaycastFilterType.Exclude
world_params.IgnoreWater = true

local refresh_filter = LPH_NO_VIRTUALIZE(function()
    local list = table.clone(solid_probe.FilterList())
    local fx = workspace:FindFirstChild("WarzFx")
    if fx then
        table.insert(list, fx)
    end
    world_params.FilterDescendantsInstances = list
end)

local clear_line = LPH_NO_VIRTUALIZE(function(origin, point)
    return workspace:Raycast(origin, point - origin, world_params) == nil
end)

local SHAPE_CAST_SPAN = 40

local first_shape = LPH_NO_VIRTUALIZE(function(origin, point, char)
    local delta = point - origin
    local dist = delta.Magnitude
    if dist < 0.01 then
        return nil
    end
    local dir = delta / dist
    local start = dist > SHAPE_CAST_SPAN and point - dir * SHAPE_CAST_SPAN or origin
    local ok, hit = pcall(hitboxes.CastData, start, point + dir * 2 - start, projectile.Radius, nil, nil, function(other)
        return other == char
    end)
    return ok and hit and hit.Instance and hit.Instance.Name
end)

local shape_points = LPH_NO_VIRTUALIZE(function(origin, shape)
    local center = shape.cf.Position
    local radius = (shape.size and shape.size.Y or 0.6) * 0.5 * 0.6
    local view = CFrame.lookAt(origin, center)
    local points = {
        center,
        center + view.UpVector * radius, center + view.RightVector * radius,
        center - view.RightVector * radius, center - view.UpVector * radius,
    }
    if shape.kind == Enum.PartType.Cylinder and shape.size then
        local axis = shape.cf.RightVector * (shape.size.X * 0.35)
        table.insert(points, center + axis)
        table.insert(points, center - axis)
    end
    return points
end)

local direct_point = LPH_NO_VIRTUALIZE(function(origin, char, shape)
    for _, point in shape_points(origin, shape) do
        if clear_line(origin, point) and first_shape(origin, point, char) == shape.name then
            return point
        end
    end
end)

local spoof_sphere = LPH_NO_VIRTUALIZE(function(root)
    local velocity = root.AssemblyLinearVelocity
    local radius = config.wallbang_radius - velocity.Magnitude * 0.06
    return root.Position - velocity * 0.03, math.max(radius, 0.5)
end)

local in_solid = LPH_NO_VIRTUALIZE(function(point)
    local ok, inside = pcall(solid_probe.PointInSolid, point)
    return not ok or inside
end)

local old_barrel_buried = getgenv().__warz_old_barrel_buried or solid_probe.BarrelBuried
getgenv().__warz_old_barrel_buried = old_barrel_buried

local barrel_buried = LPH_NO_VIRTUALIZE(function(...)
    local ok, buried = pcall(old_barrel_buried, ...)
    return ok and buried == true
end)

local SPHERE_DIRS = {}
for i = 0, 47 do
    local y = 1 - (i + 0.5) / 24
    local ring = math.sqrt(1 - y * y)
    local angle = i * 2.399963
    table.insert(SPHERE_DIRS, Vector3.new(math.cos(angle) * ring, y, math.sin(angle) * ring))
end

local spoof_cache = setmetatable({}, {__mode = "k"})
local search_budget = 0

local spoof_origin = LPH_NO_VIRTUALIZE(function(muzzle, char, shape, force)
    local me = localplayer.Character
    local root = me and me:FindFirstChild("HumanoidRootPart")
    if not root then
        return nil
    end
    local center, radius = spoof_sphere(root)
    local now = os.clock()
    local cached = spoof_cache[char]
    if cached and cached.name == shape.name and now - cached.time < 0.25 then
        if cached.origin then
            local origin, point = root.Position + cached.origin, shape.cf.Position + cached.point
            if (origin - center).Magnitude <= radius and clear_line(origin, point) and (not force or not in_solid(origin)) then
                return origin, point
            end
        elseif not force or now - cached.time < 0.1 then
            return nil
        end
    end
    if not force then
        if search_budget <= 0 then
            return nil
        end
        search_budget -= 1
    end
    local candidates = {}
    local target_pos = shape.cf.Position
    local head = me:FindFirstChild("Head")
    local eye = head and head.Position or root.Position
    for _, start in {eye, eye + Vector3.yAxis, eye - Vector3.yAxis, root.Position} do
        local back = workspace:Raycast(target_pos, start - target_pos, world_params)
        if back then
            local candidate = back.Position + (target_pos - start).Unit * 0.35
            if (candidate - center).Magnitude <= radius then
                table.insert(candidates, candidate)
            end
        end
    end
    local rings = {radius, radius * 0.65, radius * 0.3}
    if radius > 6 then
        table.insert(rings, 4.5)
        table.insert(rings, 2.5)
    end
    for _, dir in SPHERE_DIRS do
        for _, ring in rings do
            table.insert(candidates, center + dir * ring)
        end
    end
    table.sort(candidates, function(a, b)
        return (a - muzzle).Magnitude < (b - muzzle).Magnitude
    end)
    local found, found_point
    for _, candidate in candidates do
        local points = shape_points(candidate, shape)
        local block = workspace:Raycast(candidate, points[1] - candidate, world_params)
        if block and (points[1] - candidate).Magnitude - block.Distance > 4 then
            continue
        end
        local valid
        for i, point in points do
            if (i == 1 and not block) or (i > 1 and clear_line(candidate, point)) then
                if valid == nil then
                    valid = not in_solid(candidate)
                end
                if not valid then
                    break
                end
                if first_shape(candidate, point, char) == shape.name then
                    found, found_point = candidate, point
                    break
                end
            end
        end
        if found then
            break
        end
    end
    spoof_cache[char] = {
        name = shape.name,
        time = now,
        origin = found and found - root.Position,
        point = found and found_point - shape.cf.Position,
    }
    return found, found_point
end)

local shot_origin = LPH_NO_VIRTUALIZE(function(muzzle, char, shape, buried)
    local point = not buried and direct_point(muzzle, char, shape)
    if point then
        return muzzle, point
    end
    if config.wallbang then
        local origin, spoofed = spoof_origin(muzzle, char, shape, true)
        if origin then
            return origin, spoofed
        end
    end
    if not buried and clear_line(muzzle, shape.cf.Position) then
        return muzzle, shape.cf.Position
    end
end)

local ballistics = LPH_NO_VIRTUALIZE(function()
    local data = combat_settings.BallisticsFor and combat_settings.BallisticsFor()
    local speed = (tonumber(data and data.Speed) or 500) * SCALE
    local gravity = -projectile.Gravity.Y * (tonumber(data and data.Mass) or 1)
    return speed, gravity, data ~= nil and data.Immediate == true
end)

local reach = LPH_NO_VIRTUALIZE(function()
    local speed, _, immediate = ballistics()
    return immediate and math.huge or speed * (projectile.Lifetime - 0.1)
end)

local solve = LPH_NO_VIRTUALIZE(function(origin, char, point)
    local speed, gravity, immediate = ballistics()
    if immediate then
        return point, point
    end
    local root = char:FindFirstChild("HumanoidRootPart")
    local velocity = root and root.AssemblyLinearVelocity or Vector3.zero
    local predicted, aim = point, point
    for _ = 1, 3 do
        local t = (aim - origin).Magnitude / speed
        if t > projectile.Lifetime - 0.05 then
            return nil
        end
        predicted = config.prediction and point + velocity * t or point
        aim = predicted
        if config.drop then
            aim += Vector3.new(0, 0.5 * gravity * t * (t + projectile.StepSeconds), 0)
        end
    end
    return aim, predicted
end)

local px_per_stud = LPH_NO_VIRTUALIZE(function(camera, depth)
    return camera.ViewportSize.Y / (2 * math.tan(math.rad(camera.FieldOfView) * 0.5) * depth)
end)

local get_target = LPH_NO_VIRTUALIZE(function(origin, buried)
    local camera = workspace.CurrentCamera
    local center = screen_center()
    local max_range = math.min(config.max_distance * SCALE, reach())
    local found = {}
    for _, char in target_chars() do
        local root = char.HumanoidRootPart
        if (root.Position - origin).Magnitude > max_range then
            continue
        end
        local root_pos = camera:WorldToViewportPoint(root.Position)
        if root_pos.Z <= 0 then
            continue
        end
        if (Vector2.new(root_pos.X, root_pos.Y) - center).Magnitude - 4 * px_per_stud(camera, root_pos.Z) > config.fov then
            continue
        end
        local shapes = get_shapes(char)
        for _, name in hit_part_names do
            local shape = shapes[name]
            if not shape then
                continue
            end
            local pos = shape.cf.Position
            local screen_pos, onscreen = camera:WorldToViewportPoint(pos)
            if not onscreen or screen_pos.Z <= 0 then
                continue
            end
            local dist = (Vector2.new(screen_pos.X, screen_pos.Y) - center).Magnitude
            if dist < config.fov then
                table.insert(found, {char = char, name = name, dist = dist, pos = pos, shape = shape})
            end
        end
    end
    table.sort(found, function(a, b)
        return a.dist < b.dist
    end)
    local spoof_tries = config.wallbang and 4 or 0
    for _, entry in found do
        if not buried and clear_line(origin, entry.pos) then
            return {char = entry.char, name = entry.name, reachable = true}
        end
        if spoof_tries > 0 then
            spoof_tries -= 1
            if spoof_origin(origin, entry.char, entry.shape, false) then
                return {char = entry.char, name = entry.name, reachable = true}
            end
        end
    end
    if not config.wallcheck and found[1] then
        return {char = found[1].char, name = found[1].name, reachable = false}
    end
end)

local random_part = LPH_NO_VIRTUALIZE(function(char, origin, buried)
    local shapes = get_shapes(char)
    local order = table.clone(hit_part_names)
    for i = #order, 2, -1 do
        local j = math.random(1, i)
        order[i], order[j] = order[j], order[i]
    end
    local fallback
    for _, name in order do
        local shape = not buried and shapes[name]
        if shape then
            local point = direct_point(origin, char, shape)
            if point then
                return name, origin, point
            end
            if not fallback and clear_line(origin, shape.cf.Position) then
                fallback = name
            end
        end
    end
    if fallback then
        return fallback, origin, shapes[fallback].cf.Position
    end
    if config.wallbang then
        local searches = 2
        for _, name in order do
            local shape = shapes[name]
            if shape then
                local spoofed, point = spoof_origin(origin, char, shape, searches > 0)
                searches -= 1
                if spoofed then
                    return name, spoofed, point
                end
            end
        end
    end
end)

local look_for = LPH_NO_VIRTUALIZE(function(camera_pos, muzzle, aim)
    local dir = (aim - muzzle).Unit
    local hit = workspace:Raycast(muzzle, dir * 5000, world_params)
    local wall = hit and hit.Position or muzzle + dir * projectile.AimDistance
    local to_wall = wall - camera_pos
    local look = to_wall.Unit
    local check = workspace:Raycast(camera_pos, to_wall.Magnitude > 5000 and look * 5000 or to_wall, world_params)
    if check and (not hit or (check.Position - wall).Magnitude > 0.5) then
        return nil
    end
    local along = (aim - camera_pos):Dot(look)
    local near, far = math.max(along - SHAPE_CAST_SPAN, 0), math.min(along + SHAPE_CAST_SPAN, to_wall.Magnitude)
    if far - near > 0.01 then
        local me = localplayer.Character
        local ok, body = pcall(hitboxes.CastData, camera_pos + look * near, look * (far - near), projectile.Radius, nil, nil, function(other)
            return other ~= me
        end)
        if ok and body and typeof(body.Position) == "Vector3" then
            local rel = body.Position - muzzle
            if (rel - dir * rel:Dot(dir)).Magnitude > 0.3 then
                return nil
            end
        end
    end
    return look
end)

local current_target
local aim_active = false
local auto_shoot_active = false
local shot_tracers = {}

local aim_shot = LPH_NO_VIRTUALIZE(function(camera_pos, muzzle, buried)
    refresh_filter()
    local target = current_target
    if not target or not alive(target.char) then
        target = get_target(muzzle, buried)
    end
    if not target then
        return
    end
    local char, origin, point = target.char, nil, nil
    if config.hit_mode == "Random" then
        origin, point = select(2, random_part(char, muzzle, buried))
    else
        local shape = get_shapes(char)[target.name]
        if shape then
            origin, point = shot_origin(muzzle, char, shape, buried)
        end
    end
    if not origin then
        return
    end
    local aim, predicted = solve(origin, char, point)
    if not aim then
        return
    end
    local look = look_for(camera_pos, origin, aim)
    local dir = (aim - origin).Unit
    if look and (origin == muzzle or clear_line(camera_pos, origin)) then
        return {look = look, dir = dir, camera = camera_pos, muzzle = origin, predicted = predicted}
    end
    return {look = dir, dir = dir, camera = origin - dir * 0.25, muzzle = origin, predicted = predicted}
end)

local last_pose
local spoof_look, spoof_time = nil, 0

local apply_look = LPH_NO_VIRTUALIZE(function(payload, look)
    local up = CFrame.lookAt(Vector3.zero, look).UpVector
    payload.lx, payload.ly, payload.lz = look.X, look.Y, look.Z
    payload.ux, payload.uy, payload.uz = up.X, up.Y, up.Z
    payload.pitch = math.asin(math.clamp(look.Y, -1, 1))
end)

local send_pose = LPH_NO_VIRTUALIZE(function(camera_pos, look)
    if not last_pose then
        return
    end
    local payload = table.clone(last_pose)
    payload.cx, payload.cy, payload.cz = camera_pos.X, camera_pos.Y, camera_pos.Z
    apply_look(payload, look)
    pose_remote.FireServer(pose_remote, payload)
end)

local AA_PITCH = math.rad(85)
local aa_angle = 0
local aa_real_until = 0
local aa_fake_yaw

local aa_active = LPH_NO_VIRTUALIZE(function()
    return config.anti_aim and os.clock() >= aa_real_until
end)

local ug_key_active = false
local ug_real_until = 0
local ug_depth_now = 0
local UG_SINK_SPEED, UG_RISE_SPEED = 30, 60

local UG_TRUST_FLOOR, UG_TRUST_RESUME = 0.6, 0.95
local ug_surface_until = 0
local ug_under_time = 0

local ug_active = LPH_NO_VIRTUALIZE(function()
    local now = os.clock()
    return ug_key_active and now >= ug_real_until and now >= ug_surface_until
end)

local ug_safety = LPH_NO_VIRTUALIZE(function(char, dt)
    local now = os.clock()
    if not ug_key_active then
        ug_under_time = 0
        return
    end
    local trust = tonumber(char:GetAttribute("WarzGroundTrust"))
    if trust and trust < UG_TRUST_FLOOR then
        ug_surface_until = math.max(ug_surface_until, now + config.underground_surface)
    elseif trust and trust < UG_TRUST_RESUME and now >= ug_surface_until and ug_depth_now <= 0 then
        ug_surface_until = now + 0.25
    end
    if ug_depth_now > 0.5 then
        ug_under_time += dt
        if ug_under_time >= config.underground_max_under then
            ug_under_time = 0
            ug_surface_until = math.max(ug_surface_until, now + config.underground_surface)
        end
    elseif ug_depth_now <= 0 then
        ug_under_time = 0
    end
end)

local aa_compute_yaw = LPH_NO_VIRTUALIZE(function(real_yaw)
    local mode = config.aa_yaw
    if mode == "Spin" then
        aa_angle = (aa_angle + config.aa_speed) % 360
        return math.rad(aa_angle)
    elseif mode == "Jitter" then
        local jitter = (os.clock() % 0.1 < 0.05) and config.aa_jitter or -config.aa_jitter
        return real_yaw + math.rad(jitter)
    elseif mode == "Static" then
        return real_yaw + math.rad(config.aa_static)
    end
    return nil
end)

local aa_pitch = LPH_NO_VIRTUALIZE(function()
    local mode = config.aa_pitch
    if mode == "Down" then
        return -AA_PITCH
    elseif mode == "Up" then
        return AA_PITCH
    elseif mode == "Zero" then
        return 0
    elseif mode == "Jitter" then
        return (os.clock() % 0.2 < 0.1) and AA_PITCH or -AA_PITCH
    end
    return nil
end)

local tracer_end = LPH_NO_VIRTUALIZE(function(camera_pos, look, muzzle)
    refresh_filter()
    local ok, aim = pcall(projectile.AimPoint, camera_pos, look.Unit, world_params)
    if not ok or typeof(aim) ~= "Vector3" then
        aim = muzzle + look.Unit * 1000
    end
    local dir = aim - muzzle
    if dir.Magnitude < 0.01 then
        return nil
    end
    local hit = workspace:Raycast(muzzle, dir.Unit * 3000, world_params)
    return hit and hit.Position or muzzle + dir.Unit * 3000
end)

local on_fire = LPH_NO_VIRTUALIZE(function(args)
    local changed = false
    local pose_sent = false
    local tracer_to
    local camera_pos, muzzle = args[4], args[5]
    if aim_active and typeof(camera_pos) == "Vector3" and typeof(muzzle) == "Vector3" then
        local stance = args[3]
        local buried = barrel_buried(muzzle, args[6], args[7], camera_pos, type(stance) == "table" and stance.inTps == true)
        local shot = aim_shot(camera_pos, muzzle, buried)
        if shot and shot.look.X == shot.look.X then
            args[1] = shot.look
            args[4] = shot.camera
            if shot.muzzle ~= muzzle then
                args[5] = shot.muzzle
                for i = 6, 7 do
                    if typeof(args[i]) == "Vector3" then
                        local moved = shot.muzzle - shot.dir * (args[i] - muzzle).Magnitude
                        args[i] = not in_solid(moved) and clear_line(moved, shot.muzzle) and moved or nil
                    end
                end
            end
            changed = true
            send_pose(shot.camera, shot.look)
            pose_sent = true
            if config.look_spoof then
                spoof_look, spoof_time = shot.look, os.clock()
            end
            tracer_to = shot.predicted
        end
    end
    if config.bullet_tracer and typeof(args[5]) == "Vector3" and typeof(args[1]) == "Vector3" and typeof(args[4]) == "Vector3" then
        local to = tracer_to or tracer_end(args[4], args[1], args[5])
        if to then
            table.insert(shot_tracers, {from = args[5], to = to, time = os.clock()})
        end
    end
    if (config.no_spread or changed) and type(args[2]) == "number" then
        local seed = spread_seed_ok and fresh_spread_seed()
        if seed then
            args[2] = seed
            changed = true
        end
    end
    if config.underground then
        ug_real_until = os.clock() + 0.5
    end
    if config.anti_aim then
        aa_real_until = os.clock() + 0.35
        if not pose_sent and typeof(args[1]) == "Vector3" and typeof(args[4]) == "Vector3" then
            send_pose(args[4], args[1])
        end
    end
    return changed and args or nil
end)

local on_pose = LPH_NO_VIRTUALIZE(function(args)
    local payload = args[1]
    if type(payload) ~= "table" then
        return
    end
    last_pose = table.clone(payload)
    if aim_active and config.look_spoof and spoof_look and os.clock() - spoof_time < 0.25 then
        apply_look(payload, spoof_look)
    elseif aa_active() and type(payload.lx) == "number" and type(payload.lz) == "number" then
        local pitch = aa_pitch()
        if aa_fake_yaw or pitch then
            local yaw = aa_fake_yaw or math.atan2(-payload.lx, -payload.lz)
            pitch = pitch or math.asin(math.clamp(tonumber(payload.ly) or 0, -1, 1))
            apply_look(payload, (CFrame.Angles(0, yaw, 0) * CFrame.Angles(pitch, 0, 0)).LookVector)
        end
    end
    if ug_active() and config.underground_prone then
        payload.stance = (payload.moveDir ~= nil and payload.moveDir ~= "Stand") and "Prone" or "ProneIdle"
    end
    if ug_depth_now > 0 and type(payload.cy) == "number" then
        payload.cy -= ug_depth_now
    end
end)

for _, key in {"__warz_hook", "__warz_hook2"} do
    if getgenv()[key] then
        getgenv()[key].handler = nil
    end
end

local hook_state = getgenv().__warz_hook3
if not hook_state then
    hook_state = {}
    getgenv().__warz_hook3 = hook_state
    local old_namecall
    old_namecall = hookmetamethod(game, "__namecall", newcclosure(LPH_NO_VIRTUALIZE(function(self, ...)
        local handler = hook_state.handler
        if handler then
            local method = getnamecallmethod()
            if method == "FireServer" then
                local ok, args = pcall(handler, self, table.pack(...))
                setnamecallmethod(method)
                if ok and args then
                    return old_namecall(self, table.unpack(args, 1, args.n))
                end
            end
        end
        return old_namecall(self, ...)
    end)))
end

hook_state.handler = LPH_NO_VIRTUALIZE(function(remote, args)
    if remote == fire_remote then
        return on_fire(args)
    elseif remote == pose_remote then
        on_pose(args)
    end
end)

local old_apply_recoil = getgenv().__warz_old_apply_recoil or warz_camera.ApplyRecoil
getgenv().__warz_old_apply_recoil = old_apply_recoil

warz_camera.ApplyRecoil = LPH_NO_VIRTUALIZE(function(...)
    if config.no_recoil then
        return
    end
    return old_apply_recoil(...)
end)

local spread_module = require(shared.WarzSpread)
local old_apply_spread = getgenv().__warz_old_apply_spread or spread_module.ApplySpread
getgenv().__warz_old_apply_spread = old_apply_spread

spread_module.ApplySpread = LPH_NO_VIRTUALIZE(function(look, spread, seed)
    if config.no_spread and typeof(look) == "Vector3" and look.Magnitude > 0.001 then
        return look.Unit
    end
    return old_apply_spread(look, spread, seed)
end)

if not table.isfrozen(solid_probe) then
    solid_probe.BarrelBuried = LPH_NO_VIRTUALIZE(function(...)
        if config.wallbang and aim_active and current_target and current_target.reachable then
            return false, nil
        end
        return old_barrel_buried(...)
    end)
end

local update_auto_gun = LPH_NO_VIRTUALIZE(function()
    if not config.auto_gun then
        return
    end
    local gun = combat_settings.GunFor and combat_settings.GunFor()
    if gun and gun.Kind ~= "SNP" and gun.StoreCat ~= "SNP" and combat_settings.ActiveFireMode ~= "auto" then
        combat_settings.ActiveFireMode = "auto"
    end
end)

local fire_fn
pcall(function()
    for _, fn in filtergc("function", {Name = "fire", Constants = {"KnifeFireInterval"}}) do
        if string.find(debug.info(fn, "s"), "CombatInput", 1, true) then
            fire_fn = fn
            break
        end
    end
end)

local old_interval_for = getgenv().__warz_old_interval_for or combat_settings.IntervalFor
getgenv().__warz_old_interval_for = old_interval_for

local fire_interval = LPH_NO_VIRTUALIZE(function(...)
    local interval = old_interval_for(...)
    if config.rapid_fire and type(interval) == "number" then
        interval = interval / math.max(config.rapid_fire_rate, 1)
    end
    return interval
end)

local loop_seen = os.clock()
combat_settings.IntervalFor = LPH_NO_VIRTUALIZE(function(...)
    local caller = debug.info(2, "f")
    if caller ~= fire_fn and string.find(debug.info(2, "s"), "CombatInput", 1, true) then
        loop_seen = os.clock()
    end
    return fire_interval(...)
end)

local last_weapon, last_drive = nil, 0

local drive_hold_fire = LPH_NO_VIRTUALIZE(function()
    if not fire_fn then
        return
    end
    local ok, weapon = pcall(fps_view.GetWeapon)
    weapon = ok and weapon or nil
    local now = os.clock()
    if weapon ~= last_weapon then
        last_weapon, loop_seen = weapon, now
    end
    if now - loop_seen < 1.5 or type(weapon) ~= "string" or Library.Toggled then
        return
    end
    if game_config.IsMeleeId(weapon) or game_config.IsUnarmedId(weapon) then
        return
    end
    if (combat_settings.ActiveFireMode or "auto") ~= "auto" or not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
        return
    end
    if now - last_drive < fire_interval(weapon) then
        return
    end
    last_drive = now
    pcall(fire_fn)
end)

local last_auto_shot, last_auto_reload = 0, 0

local update_auto_shoot = LPH_NO_VIRTUALIZE(function()
    if not auto_shoot_active or not fire_fn or not aim_active or Library.Toggled then
        return
    end
    local target = current_target
    if not target or not target.reachable or not alive(target.char) then
        return
    end
    local ok, weapon = pcall(fps_view.GetWeapon)
    if not ok or type(weapon) ~= "string" or game_config.IsMeleeId(weapon) or game_config.IsUnarmedId(weapon) then
        return
    end
    local gun = combat_settings.GunFor and combat_settings.GunFor(weapon)
    if not gun or gun.UsesAmmo == false then
        return
    end
    local now = os.clock()
    local clip = tonumber(localplayer:GetAttribute("CSGO_ClipAmmo"))
    if clip and clip <= 0 then
        if config.auto_reload and now - last_auto_reload > 1 and type(combat_input.RequestReload) == "function" then
            last_auto_reload = now
            pcall(combat_input.RequestReload)
        end
        return
    end
    if now - last_auto_shot < fire_interval(weapon) then
        return
    end
    last_auto_shot = now
    pcall(fire_fn)
end)

local bag_getter

local get_bag = LPH_NO_VIRTUALIZE(function()
    if not bag_getter and type(combat_input.RequestUseShield) == "function" then
        for _, value in debug.getupvalues(combat_input.RequestUseShield) do
            if type(value) == "function" then
                local ok, bag = pcall(value)
                if ok and type(bag) == "table" and type(bag.Slots) == "table" then
                    bag_getter = value
                    break
                end
            end
        end
    end
    local ok, bag = pcall(bag_getter or function() end)
    return ok and type(bag) == "table" and type(bag.Slots) == "table" and bag or nil
end)

local find_slot = LPH_NO_VIRTUALIZE(function(accept)
    local bag = get_bag()
    if not bag then
        return
    end
    for slot = 3, 6 do
        local entry = bag.Slots[slot]
        if type(entry) == "table" and type(entry.ItemId) == "string" and entry.ItemId ~= "" and (tonumber(entry.Qty) or 0) > 0 and accept(entry.ItemId) then
            return slot, entry.ItemId
        end
    end
end)

local hud_holders, hud_search = {}, -math.huge

local my_health = LPH_NO_VIRTUALIZE(function()
    if #hud_holders == 0 and os.clock() - hud_search > 5 then
        hud_search = os.clock()
        local ok, huds = pcall(filtergc, "table", {Keys = {"Render", "TookDamage", "ShowHitmarker"}})
        if ok and type(huds) == "table" then
            for _, hud in huds do
                local found, holder = pcall(debug.getupvalue, hud.Render, 1)
                if found and type(holder) == "table" then
                    table.insert(hud_holders, holder)
                end
            end
        end
    end
    for _, holder in hud_holders do
        local state = holder.hud
        if type(state) == "table" and tonumber(state.health) then
            return tonumber(state.health), state
        end
    end
    local char = localplayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health, nil
end)

local can_use_item = LPH_NO_VIRTUALIZE(function(char)
    if not alive(char) or localplayer:GetAttribute("WarzDisconnectAt") or localplayer:GetAttribute("CSGO_UiUnlock") == true then
        return false
    end
    return (tonumber(char:GetAttribute("WarzUseUntil")) or 0) <= workspace:GetServerTimeNow()
end)

local heal_choices = {}
pcall(function()
    for id, item in game_config.Shop do
        if type(id) == "string" and type(item) == "table" and game_config.IsMedicalKind(item.Kind) and item.RestoreStamina ~= true then
            table.insert(heal_choices, id)
        end
    end
end)
table.sort(heal_choices)
if #heal_choices == 0 then
    heal_choices = {"BandagesDX", "Bandages"}
end

local last_heal = 0

local heal_slots = LPH_NO_VIRTUALIZE(function()
    local bag = get_bag()
    local slots, seen = {}, {}
    if not bag then
        return slots
    end
    for slot = 3, 6 do
        local entry = bag.Slots[slot]
        local id = type(entry) == "table" and entry.ItemId
        if type(id) == "string" and config.heal_items[id] and not seen[id] and (tonumber(entry.Qty) or 0) > 0 then
            seen[id] = true
            table.insert(slots, {slot = slot, id = id})
        end
    end
    return slots
end)

local update_auto_heal = LPH_NO_VIRTUALIZE(function()
    if not config.auto_heal or os.clock() - last_heal < 1 then
        return
    end
    local char = localplayer.Character
    if not can_use_item(char) then
        return
    end
    local health, state = my_health()
    if not health or health <= 0 or health > config.heal_below then
        return
    end
    if (tonumber(localplayer:GetAttribute("WarzMedCdLeft")) or 0) > 0.05 then
        return
    end
    if state and (tonumber(state.medCooldownUntil) or 0) > workspace:GetServerTimeNow() then
        return
    end
    local slots = heal_slots()
    if #slots == 0 then
        return
    end
    last_heal = os.clock()
    for _, use in slots do
        use_item_remote:FireServer(use.slot, use.id, nil, nil, true)
    end
end)

local WALL_ITEMS = {["Riot Shield"] = "RiotShield", ["Wood Shield Bar"] = "WoodShield"}
local THREAT_RADIUS = 6

local threat
local last_wall = 0

local accept_shield = LPH_NO_VIRTUALIZE(function(id)
    local wanted = WALL_ITEMS[config.wall_item]
    if wanted then
        return id == wanted
    end
    local item = game_config.ShopItem(id)
    return item ~= nil and game_config.IsShieldKind(item.Kind)
end)

Library:GiveSignal(remotes:WaitForChild("WorldAction").OnClientEvent:Connect(LPH_NO_VIRTUALIZE(function(data)
    if not config.auto_wall or type(data) ~= "table" then
        return
    end
    local char = localplayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then
        return
    end
    if data.kind == "fire" and data.userId ~= localplayer.UserId and typeof(data.muzzle) == "Vector3" and typeof(data.dir) == "Vector3" then
        local shooter = Players:GetPlayerByUserId(data.userId)
        if shooter and is_teammate(shooter) or data.dir.Magnitude < 0.01 then
            return
        end
        local dir = data.dir.Unit
        local to_me = root.Position - data.muzzle
        local along = to_me:Dot(dir)
        if along > 0 and (to_me - dir * along).Magnitude <= THREAT_RADIUS then
            threat = {from = data.muzzle, time = os.clock()}
        end
    elseif data.kind == "playerHit" and data.victimUserId == localplayer.UserId and typeof(data.pos) == "Vector3" and typeof(data.normal) == "Vector3" then
        if not threat or os.clock() - threat.time > 0.5 then
            threat = {from = data.pos + data.normal * 30, time = os.clock()}
        end
    end
end)))

local cover_params = RaycastParams.new()
cover_params.FilterType = Enum.RaycastFilterType.Exclude
cover_params.IgnoreWater = true

local update_auto_wall = LPH_NO_VIRTUALIZE(function()
    if not config.auto_wall or not threat then
        return
    end
    local now = os.clock()
    if now - threat.time > 1 then
        threat = nil
        return
    end
    if now - last_wall < config.wall_cooldown or localplayer:GetAttribute("WarzSaveZone") == true then
        return
    end
    if (tonumber(localplayer:GetAttribute("WarzPlaceCdLeft")) or 0) > 0.05 then
        return
    end
    local char = localplayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root or not can_use_item(char) or not barricade.Standing(char) then
        return
    end
    cover_params.FilterDescendantsInstances = {char, workspace.CurrentCamera}
    local cover = workspace:Raycast(root.Position, threat.from - root.Position, cover_params)
    if cover and barricade.IsPart(cover.Instance) then
        threat = nil
        return
    end
    local slot, item = find_slot(accept_shield)
    if not slot then
        return
    end
    if config.wall_item == "Any" then
        local riot_slot = find_slot(function(id)
            return id == "RiotShield"
        end)
        if riot_slot then
            slot, item = riot_slot, "RiotShield"
        end
    end
    local yaw, flat = barricade.YawFromLook(threat.from - root.Position)
    local point = barricade.Feet(char, root) + flat * barricade.ForwardOffset(item)
    local ok, cf, place_yaw, _, valid = pcall(barricade.EvaluateAt, char, root, item, point, yaw, barricade.GROUND_DOWN_M * barricade.SCALE)
    if not ok or not cf or not valid then
        return
    end
    last_wall = now
    threat = nil
    use_item_remote:FireServer(slot, item, cf.Position, place_yaw, true)
end)

local update_auto_pickup, clear_auto_jobs, old_hold_step, old_hold_reply

do
    local PICK_RANGE, PICK_HEIGHT = 11.098, 8

    old_hold_step = getgenv().__warz_old_hold_step or loot_hold_module.Step
    getgenv().__warz_old_hold_step = old_hold_step
    old_hold_reply = getgenv().__warz_old_hold_reply or loot_hold_module.Reply
    getgenv().__warz_old_hold_reply = old_hold_reply

    local HOLD_TIME, PREP_RETRY, USE_RETRY = 1, 0.2, 0.1

    local instant_hold = LPH_NO_VIRTUALIZE(function(self)
        if self.warz_instant then
            return true
        end
        if not config.instant_pickup then
            return false
        end
        if self.warz_loot == nil then
            local ok, source = pcall(debug.info, self.send, "s")
            self.warz_loot = ok and type(source) == "string" and string.find(source, "LootPickup", 1, true) ~= nil
        end
        return self.warz_loot
    end)

    loot_hold_module.Reply = LPH_NO_VIRTUALIZE(function(self, uid, kind, ok, reason, seq)
        old_hold_reply(self, uid, kind, ok, reason, seq)
        if uid == self.uid and seq == self.sequence and instant_hold(self) then
            local now = os.clock()
            self.nextPrep = math.min(self.nextPrep or now, now)
            self.nextUse = math.min(self.nextUse or now, math.max(now, (self.started or now) + HOLD_TIME))
        end
    end)

    loot_hold_module.Step = LPH_NO_VIRTUALIZE(function(self, uid, target, holding, now)
        if not instant_hold(self) then
            return old_hold_step(self, uid, target, holding, now)
        end
        if self.uid and (self.uid ~= uid or self.target ~= target) then
            self:Reset()
        end
        if not self.uid then
            if not holding then
                return 0, false
            end
            self.sequence += 1
            self.uid, self.target, self.started = uid, target, now
            self.nextPrep, self.nextUse = now, now + HOLD_TIME
            self.committed, self.done, self.prepared, self.timedOut, self.error = true, false, false, false, nil
        end
        if holding or (self.committed and not self.done) then
            local elapsed = now - self.started
            if elapsed >= 6 and not self.done then
                self.done, self.timedOut = true, true
            end
            if not self.done then
                if not self.prepared and self.nextPrep <= now then
                    self.nextPrep = now + PREP_RETRY
                    self.send(uid, "prep", self.sequence)
                end
                if elapsed >= HOLD_TIME and self.nextUse <= now then
                    self.nextUse = now + USE_RETRY
                    self.send(uid, "use", self.sequence)
                end
            end
            return math.clamp(elapsed / HOLD_TIME, 0, 1), not self.done
        end
        self:Reset()
        return 0, false
    end)

    local MAX_PICKUPS = 1
    local auto_jobs = {}
    local auto_seq = 50000
    local loot_skip = {}

    Library:GiveSignal(pickup_remote.OnClientEvent:Connect(LPH_NO_VIRTUALIZE(function(uid, kind, ok, reason, seq)
        local job = auto_jobs[uid]
        if job then
            job.hold:Reply(uid, kind, ok, reason, seq)
        end
    end)))

    local loot_pos = LPH_NO_VIRTUALIZE(function(loot)
        if loot:IsA("Model") then
            local part = loot.PrimaryPart or loot:FindFirstChildWhichIsA("BasePart", true)
            return part and part.Position
        elseif loot:IsA("BasePart") then
            return loot.Position
        end
    end)

    local in_pick_range = LPH_NO_VIRTUALIZE(function(from, pos)
        local d = pos - from
        return Vector3.new(d.X, 0, d.Z).Magnitude <= PICK_RANGE and math.abs(d.Y) < PICK_HEIGHT
    end)

    local loot_blocked = LPH_NO_VIRTUALIZE(function()
        return localplayer:GetAttribute("CSGO_UiUnlock") == true or localplayer:GetAttribute("CSGO_Paused") == true
            or localplayer:GetAttribute("WarzTradeTarget") == true
    end)

    local loot_in_range = LPH_NO_VIRTUALIZE(function(from, now)
        local list = {}
        local folder = workspace:FindFirstChild("WarzLoot")
        if not folder then
            return list
        end
        for _, loot in folder:GetChildren() do
            local uid = loot:GetAttribute("LootUid")
            if type(uid) == "string" and uid ~= "" and not auto_jobs[uid] and loot:GetAttribute("WarzReplayFutureLoot") ~= true
                and (loot_skip[uid] or 0) <= now then
                local pos = loot_pos(loot)
                if pos and in_pick_range(from, pos) then
                    table.insert(list, {loot = loot, uid = uid, dist = (pos - from).Magnitude})
                end
            end
        end
        table.sort(list, function(a, b)
            return a.dist < b.dist
        end)
        return list
    end)

    clear_auto_jobs = LPH_NO_VIRTUALIZE(function()
        for uid, job in auto_jobs do
            job.hold:Reset()
            auto_jobs[uid] = nil
        end
    end)

    update_auto_pickup = LPH_NO_VIRTUALIZE(function()
        if not config.auto_pickup then
            if next(auto_jobs) then
                clear_auto_jobs()
            end
            return
        end
        local char = localplayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root or not alive(char) or loot_blocked() then
            clear_auto_jobs()
            return
        end
        local now = os.clock()
        local count = 0
        for uid, job in auto_jobs do
            local hold = job.hold
            local pos = job.target.Parent and loot_pos(job.target)
            if hold.done or not pos or not in_pick_range(root.Position, pos) then
                loot_skip[uid] = now + (hold.timedOut and 3 or hold.error and 2 or 1)
                hold:Reset()
                auto_jobs[uid] = nil
            else
                count += 1
            end
        end
        if count < MAX_PICKUPS then
            for _, entry in loot_in_range(root.Position, now) do
                if count >= MAX_PICKUPS then
                    break
                end
                local hold = loot_hold_module.new(function(uid, kind, seq)
                    pickup_remote:FireServer(uid, kind, seq)
                end)
                auto_seq += 2
                hold.sequence = auto_seq - 1
                hold.warz_instant = true
                auto_jobs[entry.uid] = {hold = hold, target = entry.loot}
                count += 1
            end
        end
        for uid, job in auto_jobs do
            job.hold:Step(uid, job.target, true, now)
        end
    end)
end

local new_drawing = LPH_NO_VIRTUALIZE(function(class, props)
    local drawing = Drawing.new(class)
    for key, value in props do
        drawing[key] = value
    end
    return drawing
end)

local circle = new_drawing("Circle", {Thickness = 1, NumSides = 64, Filled = false, Transparency = 1, Visible = false})
local dot = new_drawing("Circle", {Thickness = 1, NumSides = 16, Radius = 5, Filled = true, Transparency = 1, Visible = false})
local target_line = new_drawing("Line", {Thickness = 1, Transparency = 1, Visible = false})
local TRACER_BEAMS = {
    Laser = {
        FaceCamera = true, TextureSpeed = 1.5, Width0 = 0.25, Width1 = 0.25, TextureLength = 2,
        LightEmission = 3, Brightness = 2.5, Texture = "rbxassetid://12781800668",
    },
    Light = {
        FaceCamera = true, TextureSpeed = 2, Width0 = 0.25, Width1 = 0.25, LightInfluence = 1, LightEmission = 3,
        Segments = 1, Texture = "http://www.roblox.com/asset/?id=2382169232", TextureLength = 15, TextureMode = Enum.TextureMode.Wrap,
    },
    Flow = {
        FaceCamera = true, TextureSpeed = 2.5, Width0 = 0.2, Width1 = 0.2, LightEmission = 3, Brightness = 5,
        Texture = "rbxassetid://12788927812",
    },
}

local remove_tracer = LPH_NO_VIRTUALIZE(function(tracer)
    for _, object in tracer.objects or {} do
        if typeof(object) == "Instance" then
            object:Destroy()
        else
            object:Remove()
        end
    end
    tracer.objects = nil
end)

local spawn_tracer = LPH_NO_VIRTUALIZE(function(tracer)
    tracer.kind = config.bullet_tracer_type
    tracer.life = math.max(config.bullet_tracer_time, 0.1)
    tracer.fade = tracer.kind == "Beam" and 0.2 or 0.3
    if tracer.kind == "Beam" then
        local terrain = workspace.Terrain
        local beam = Instance.new("Beam")
        tracer.objects = {beam}
        for key, value in TRACER_BEAMS[config.bullet_tracer_style] or TRACER_BEAMS.Laser do
            beam[key] = value
        end
        tracer.alpha0, tracer.alpha1 = config.bullet_tracer_alpha, config.bullet_tracer_gradient_alpha
        beam.Color = ColorSequence.new(config.bullet_tracer_color, config.bullet_tracer_gradient)
        beam.Transparency = NumberSequence.new(tracer.alpha0, tracer.alpha1)
        local start, finish = Instance.new("Attachment"), Instance.new("Attachment")
        table.insert(tracer.objects, start)
        table.insert(tracer.objects, finish)
        start.Parent, finish.Parent = terrain, terrain
        start.WorldPosition, finish.WorldPosition = tracer.from, tracer.to
        beam.Attachment0, beam.Attachment1 = start, finish
        beam.Parent = terrain
        tracer.beam = beam
    else
        tracer.opacity = 1 - config.bullet_tracer_alpha
        tracer.outline_opacity = 1 - config.bullet_tracer_outline_alpha
        tracer.outline = new_drawing("Line", {Thickness = 3, Color = config.bullet_tracer_outline, Transparency = tracer.outline_opacity, Visible = false})
        tracer.line = new_drawing("Line", {Thickness = 1, Color = config.bullet_tracer_color, Transparency = tracer.opacity, Visible = false})
        tracer.objects = {tracer.line, tracer.outline}
    end
end)

local draw_tracer_line = LPH_NO_VIRTUALIZE(function(tracer, camera, fade)
    local line, outline = tracer.line, tracer.outline
    local a, a_on = camera:WorldToViewportPoint(tracer.from)
    local b, b_on = camera:WorldToViewportPoint(tracer.to)
    if not a_on and not b_on then
        line.Visible, outline.Visible = false, false
        return
    end
    local size = camera.ViewportSize
    local from = a.Z < 0 and Vector2.new(math.clamp(size.X - a.X, 0, size.X), math.clamp(size.Y - a.Y, 0, size.Y)) or Vector2.new(a.X, a.Y)
    local to = b.Z < 0 and Vector2.new(math.clamp(size.X - b.X, 0, size.X), math.clamp(size.Y - b.Y, 0, size.Y)) or Vector2.new(b.X, b.Y)
    from = from:Lerp(to, fade)
    local offset = (from - to).Magnitude > 0.01 and (from - to).Unit or Vector2.zero
    line.From, line.To = from, to
    outline.From, outline.To = from + offset, to - offset
    line.Transparency = tracer.opacity * (1 - fade)
    outline.Transparency = tracer.outline_opacity * (1 - fade)
    line.Visible, outline.Visible = true, true
end)

local update_bullet_tracers = LPH_NO_VIRTUALIZE(function(camera)
    local now = os.clock()
    while #shot_tracers > 48 do
        remove_tracer(table.remove(shot_tracers, 1))
    end
    for i = #shot_tracers, 1, -1 do
        local tracer = shot_tracers[i]
        if not tracer.kind and not pcall(spawn_tracer, tracer) then
            tracer.kind, tracer.life, tracer.fade = "Failed", -1, 0
        end
        local age = now - tracer.time
        if age > tracer.life + tracer.fade then
            remove_tracer(tracer)
            table.remove(shot_tracers, i)
        else
            local t = math.clamp((age - tracer.life) / tracer.fade, 0, 1)
            local fade = 1 - (1 - t) * (1 - t)
            if tracer.kind == "Beam" then
                if fade > 0 then
                    tracer.beam.Transparency = NumberSequence.new(tracer.alpha0 + (1 - tracer.alpha0) * fade, tracer.alpha1 + (1 - tracer.alpha1) * fade)
                end
            else
                draw_tracer_line(tracer, camera, fade)
            end
        end
    end
end)

local esp_objects = {}

local get_esp = LPH_NO_VIRTUALIZE(function(player)
    local objects = esp_objects[player]
    if objects then
        return objects
    end
    objects = {
        box_outline = new_drawing("Square", {Thickness = 3, Filled = false, Color = Color3.new(0, 0, 0), Transparency = 1, Visible = false}),
        box = new_drawing("Square", {Thickness = 1, Filled = false, Transparency = 1, Visible = false}),
        hp_outline = new_drawing("Square", {Thickness = 1, Filled = true, Color = Color3.new(0, 0, 0), Transparency = 1, Visible = false}),
        hp_bar = new_drawing("Square", {Thickness = 1, Filled = true, Transparency = 1, Visible = false}),
        name = new_drawing("Text", {Center = true, Outline = true, Font = 2, Transparency = 1, Visible = false}),
        info = new_drawing("Text", {Center = true, Outline = true, Font = 2, Transparency = 1, Visible = false}),
    }
    esp_objects[player] = objects
    return objects
end)

local hide_esp = LPH_NO_VIRTUALIZE(function(objects)
    for _, drawing in objects do
        drawing.Visible = false
    end
end)

local function remove_esp(player)
    local objects = esp_objects[player]
    if not objects then
        return
    end
    for _, drawing in objects do
        drawing:Remove()
    end
    esp_objects[player] = nil
end

local BOX_TOP, BOX_FEET, BOX_RATIO = 1.9, 1.3, 0.4

local get_box = LPH_NO_VIRTUALIZE(function(char, camera)
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then
        return
    end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local pos = root.Position
    local top = camera:WorldToViewportPoint(pos + Vector3.new(0, BOX_TOP, 0))
    local bottom = camera:WorldToViewportPoint(pos - Vector3.new(0, (hum and hum.HipHeight or 2.2) + BOX_FEET, 0))
    if top.Z <= 0 or bottom.Z <= 0 then
        return
    end
    local h = math.max(bottom.Y - top.Y, 6)
    local w = math.max(h * BOX_RATIO, 3)
    local center_x = (top.X + bottom.X) * 0.5
    return math.floor(center_x - w * 0.5), math.floor(top.Y), math.floor(w), math.floor(h)
end)

local display_name = LPH_NO_VIRTUALIZE(function(player)
    if esp.name_mode == "Username" or string.find(player.DisplayName, "[\128-\255]") then
        return player.Name
    elseif esp.name_mode == "Both" and player.DisplayName ~= player.Name then
        return player.DisplayName .. " (@" .. player.Name .. ")"
    end
    return player.DisplayName
end)

local weapon_names = {}

local weapon_name = LPH_NO_VIRTUALIZE(function(id)
    if type(id) ~= "string" or id == "" then
        return nil
    end
    local name = weapon_names[id]
    if name == nil then
        local ok, item = pcall(game_config.ShopItem, id)
        name = ok and type(item) == "table" and type(item.Name) == "string" and item.Name or id
        if string.find(name, "[\128-\255]") then
            name = id
        end
        weapon_names[id] = name
    end
    return name
end)

local HP_LOW, HP_MID, HP_HIGH = Color3.fromRGB(255, 40, 40), Color3.fromRGB(255, 200, 40), Color3.fromRGB(40, 255, 80)

local health_color = LPH_NO_VIRTUALIZE(function(ratio)
    if ratio < 0.5 then
        return HP_LOW:Lerp(HP_MID, ratio / 0.5)
    end
    return HP_MID:Lerp(HP_HIGH, (ratio - 0.5) / 0.5)
end)

local update_esp = LPH_NO_VIRTUALIZE(function(player, camera, my_root, target_char)
    local objects = get_esp(player)
    local char = player.Character
    if not esp.enabled or not alive(char) then
        hide_esp(objects)
        return
    end

    local teammate = is_teammate(player)
    if teammate and esp.teamcheck then
        hide_esp(objects)
        return
    end

    local root = char.HumanoidRootPart
    local distance = my_root and (root.Position - my_root.Position).Magnitude / SCALE or 0
    if distance > esp.max_distance then
        hide_esp(objects)
        return
    end

    local x, y, w, h = get_box(char, camera)
    if not x then
        hide_esp(objects)
        return
    end

    local color = esp.color
    if char == target_char then
        color = esp.target_color
    elseif teammate then
        color = esp.team_color
    end

    objects.box_outline.Visible = esp.box
    objects.box.Visible = esp.box
    if esp.box then
        objects.box_outline.Position = Vector2.new(x, y)
        objects.box_outline.Size = Vector2.new(w, h)
        objects.box.Position = Vector2.new(x, y)
        objects.box.Size = Vector2.new(w, h)
        objects.box.Color = color
    end

    local hum = char:FindFirstChildOfClass("Humanoid")
    local show_health = esp.health and hum ~= nil
    objects.hp_outline.Visible = show_health
    objects.hp_bar.Visible = show_health
    if show_health then
        local ratio = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
        local bar = math.floor(h * ratio)
        objects.hp_outline.Position = Vector2.new(x - 6, y - 1)
        objects.hp_outline.Size = Vector2.new(4, h + 2)
        objects.hp_bar.Position = Vector2.new(x - 5, y + h - bar)
        objects.hp_bar.Size = Vector2.new(2, bar)
        objects.hp_bar.Color = health_color(ratio)
    end

    objects.name.Visible = esp.name
    if esp.name then
        objects.name.Text = display_name(player)
        objects.name.Size = esp.text_size
        objects.name.Position = Vector2.new(x + w * 0.5, y - esp.text_size - 3)
        objects.name.Color = color
    end

    local info = {}
    if esp.distance then
        table.insert(info, "[" .. math.floor(distance) .. "m]")
    end
    if esp.weapon then
        local weapon = weapon_name(char:GetAttribute("WarzCatalogId"))
        if weapon then
            table.insert(info, weapon)
        end
    end
    objects.info.Visible = #info > 0
    if #info > 0 then
        objects.info.Text = table.concat(info, " ")
        objects.info.Size = esp.text_size
        objects.info.Position = Vector2.new(x + w * 0.5, y + h + 2)
        objects.info.Color = color
    end
end)

Library:GiveSignal(Players.PlayerRemoving:Connect(remove_esp))

local aa_saved
local AA_RESTORE_STEP = "warz_anti_aim_restore"

local aa_restore = LPH_NO_VIRTUALIZE(function()
    local saved = aa_saved
    aa_saved = nil
    if saved and saved.root.Parent then
        saved.root.CFrame = CFrame.new(saved.root.Position + (saved.offset or Vector3.zero)) * saved.rotation
    end
end)

Library:GiveSignal(RunService.Heartbeat:Connect(LPH_NO_VIRTUALIZE(function(dt)
    aa_fake_yaw = nil
    local char = localplayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root or not alive(char) then
        ug_depth_now = 0
        return
    end
    local yaw
    if aa_active() then
        local _, real_yaw = root.CFrame:ToOrientation()
        yaw = aa_compute_yaw(real_yaw)
    end
    ug_safety(char, dt)
    local target_depth = ug_active() and math.max(config.underground_depth, 5) or 0
    if ug_depth_now < target_depth then
        ug_depth_now = math.min(ug_depth_now + UG_SINK_SPEED * dt, target_depth)
    elseif ug_depth_now > target_depth then
        ug_depth_now = math.max(ug_depth_now - UG_RISE_SPEED * dt, target_depth)
    end
    local depth = ug_depth_now
    if not yaw and depth <= 0 then
        return
    end
    aa_fake_yaw = yaw
    local offset = Vector3.new(0, depth, 0)
    aa_saved = {root = root, rotation = root.CFrame.Rotation, offset = offset}
    root.CFrame = CFrame.new(root.Position - offset) * (yaw and CFrame.Angles(0, yaw, 0) or root.CFrame.Rotation)
end)))

pcall(RunService.UnbindFromRenderStep, RunService, AA_RESTORE_STEP)
RunService:BindToRenderStep(AA_RESTORE_STEP, Enum.RenderPriority.First.Value, LPH_NO_VIRTUALIZE(function()
    aa_restore()
    if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
        if config.anti_aim then
            aa_real_until = math.max(aa_real_until, os.clock() + 0.35)
        end
        if config.underground then
            ug_real_until = math.max(ug_real_until, os.clock() + 0.5)
        end
    end
end))

local AA_VISUAL_STEP = "warz_anti_aim_visual"
pcall(RunService.UnbindFromRenderStep, RunService, AA_VISUAL_STEP)
RunService:BindToRenderStep(AA_VISUAL_STEP, Enum.RenderPriority.Camera.Value + 1, LPH_NO_VIRTUALIZE(function()
    if not (config.aa_visualize and aa_fake_yaw and aa_active()) then
        return
    end
    local char = localplayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then
        return
    end
    aa_saved = aa_saved or {root = root, rotation = root.CFrame.Rotation}
    root.CFrame = CFrame.new(root.Position) * CFrame.Angles(0, aa_fake_yaw, 0)
end))

Library:GiveSignal(RunService.Stepped:Connect(aa_restore))

local aa_forcing_move = false

local aa_move_dir = LPH_NO_VIRTUALIZE(function(world_dir, yaw)
    local rel = CFrame.Angles(0, yaw, 0):VectorToObjectSpace(world_dir)
    local forward, right = -rel.Z, rel.X
    local f, b, r, l = forward > 0.38, forward < -0.38, right > 0.38, right < -0.38
    if f and r then
        return "StrRight"
    elseif f and l then
        return "StrLeft"
    elseif f then
        return "Str"
    elseif b and r then
        return "BackRight"
    elseif b and l then
        return "BackLeft"
    elseif b then
        return "Back"
    elseif r then
        return "Right"
    elseif l then
        return "Left"
    end
    return "Stand"
end)

local update_aa_move_dir = LPH_NO_VIRTUALIZE(function()
    local char = localplayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if aa_fake_yaw and aa_active() and hum then
        local move = hum.MoveDirection * Vector3.new(1, 0, 1)
        localplayer:SetAttribute("CSGO_ForceMoveDir", move.Magnitude > 0.1 and aa_move_dir(move.Unit, aa_fake_yaw) or "Stand")
        aa_forcing_move = true
    elseif aa_forcing_move then
        localplayer:SetAttribute("CSGO_ForceMoveDir", nil)
        aa_forcing_move = false
    end
end)

local old_get_pitch = getgenv().__warz_old_get_pitch or warz_camera.GetPitch
getgenv().__warz_old_get_pitch = old_get_pitch

warz_camera.GetPitch = LPH_NO_VIRTUALIZE(function(...)
    if config.aa_visualize and aa_active() and localplayer:GetAttribute("CSGO_Tps") == true then
        local pitch = aa_pitch()
        if pitch then
            return math.clamp(pitch, -1.4, 1.4)
        end
    end
    return old_get_pitch(...)
end)

local key_active = LPH_NO_VIRTUALIZE(function(enabled, key)
    local mode = key and key.Mode or "Toggle"
    if key and mode == "Toggle" and key.Toggled ~= enabled then
        key.Toggled = enabled
        key:Update()
    end
    return enabled and (mode ~= "Hold" or key:GetState())
end)

local AIMBOT_STEP = "warz_aimbot"
local aim_circle = new_drawing("Circle", {Thickness = 1, NumSides = 64, Filled = false, Transparency = 1, Visible = false})

do
    local AIM_PARTS = {Head = "Bip01_Head", Neck = "Bip01_Neck", Torso = "Bip01_Spine2"}
    local locked_char

    local aim_point = LPH_NO_VIRTUALIZE(function(char, cam_pos)
        local shape = get_shapes(char)[AIM_PARTS[config.aimbot_part] or "Bip01_Head"]
        if shape and (shape.cf.Position - cam_pos).Magnitude <= config.max_distance * SCALE then
            return shape.cf.Position
        end
    end)

    local lock_valid = LPH_NO_VIRTUALIZE(function(char)
        if not alive(char) then
            return false
        end
        local player = Players:GetPlayerFromCharacter(char)
        return not player or not skip_player(player)
    end)

    local find_aim_target = LPH_NO_VIRTUALIZE(function(camera)
        local center = screen_center()
        local cam_pos = camera.CFrame.Position
        local best, best_dist
        for _, char in target_chars() do
            local pos = aim_point(char, cam_pos)
            if pos then
                local screen, on_screen = camera:WorldToViewportPoint(pos)
                if on_screen and screen.Z > 0 then
                    local dist = (Vector2.new(screen.X, screen.Y) - center).Magnitude
                    if dist <= config.aimbot_fov and (not best_dist or dist < best_dist)
                        and (not config.aimbot_wallcheck or clear_line(cam_pos, pos)) then
                        best, best_dist = {char = char, pos = pos}, dist
                    end
                end
            end
        end
        return best
    end)

    pcall(RunService.UnbindFromRenderStep, RunService, AIMBOT_STEP)
    RunService:BindToRenderStep(AIMBOT_STEP, Enum.RenderPriority.Camera.Value - 1, LPH_NO_VIRTUALIZE(function(dt)
        local camera = workspace.CurrentCamera
        aim_circle.Visible = config.aimbot_show_fov
        if aim_circle.Visible then
            aim_circle.Radius = config.aimbot_fov
            aim_circle.Color = config.aimbot_fov_color
            aim_circle.Position = screen_center()
        end
        local key = Options.AimbotKey
        if not key or not key_active(config.aimbot, key) then
            locked_char = nil
            return
        end
        if Library.Toggled then
            return
        end
        if localplayer:GetAttribute("CSGO_UiUnlock") == true or localplayer:GetAttribute("CSGO_Paused") == true then
            return
        end
        local ok_orbit, orbiting = pcall(warz_camera.IsOrbiting)
        local ok_killcam, killcam = pcall(warz_camera.IsKillcam)
        if (ok_orbit and orbiting) or (ok_killcam and killcam) then
            return
        end
        local my_char = localplayer.Character
        if not my_char or not my_char:FindFirstChild("HumanoidRootPart") then
            return
        end
        refresh_filter()
        local cam_pos = camera.CFrame.Position
        local target
        if config.aimbot_sticky and locked_char then
            local pos = lock_valid(locked_char) and aim_point(locked_char, cam_pos)
            if pos then
                target = {char = locked_char, pos = pos}
            else
                locked_char = nil
            end
        end
        if not target then
            target = find_aim_target(camera)
            if not target then
                return
            end
            locked_char = config.aimbot_sticky and target.char or nil
        end
        if config.aimbot_wallcheck and not clear_line(cam_pos, target.pos) then
            return
        end
        local dir
        if config.aimbot_prediction then
            local ok_muzzle, muzzle = pcall(fps_view.MuzzlePosition)
            if ok_muzzle and typeof(muzzle) == "Vector3" then
                local aim = solve(muzzle, target.char, target.pos)
                if aim then
                    dir = look_for(cam_pos, muzzle, aim) or (aim - cam_pos).Unit
                end
            end
        end
        dir = dir or (target.pos - cam_pos).Unit
        if dir.X ~= dir.X then
            return
        end
        local want_yaw = math.atan2(-dir.X, -dir.Z)
        local want_pitch = math.clamp(math.asin(math.clamp(dir.Y, -1, 1)), -1.2217, 1.2217)
        local yaw, pitch = warz_camera.GetYaw(), old_get_pitch()
        local diff = (want_yaw - yaw + math.pi) % (2 * math.pi) - math.pi
        local alpha = config.aimbot_smooth <= 1 and 1 or 1 - (1 - 1 / config.aimbot_smooth) ^ (math.min(dt, 0.1) * 60)
        pcall(debug.setupvalue, warz_camera.GetYaw, 1, yaw + diff * alpha)
        pcall(debug.setupvalue, old_get_pitch, 1, pitch + (want_pitch - pitch) * alpha)
    end))
end

Library:GiveSignal(RunService.RenderStepped:Connect(LPH_NO_VIRTUALIZE(function()
    local camera = workspace.CurrentCamera
    circle.Visible = config.enabled and config.show_fov
    circle.Radius = config.fov
    circle.Color = config.fov_color
    circle.Position = screen_center()

    search_budget = 1
    aim_active = key_active(config.enabled, Options.SilentAimKey)
    auto_shoot_active = key_active(config.auto_shoot, Options.AutoShootKey)
    ug_key_active = key_active(config.underground, Options.UndergroundKey)

    update_auto_gun()
    drive_hold_fire()
    update_auto_heal()
    update_auto_wall()
    update_auto_pickup()
    update_aa_move_dir()

    local my_char = localplayer.Character
    local my_root = my_char and my_char:FindFirstChild("HumanoidRootPart")
    local target, target_pos
    if config.enabled and my_root then
        refresh_filter()
        local ok, points = pcall(fps_view.BarrelPoints)
        points = ok and type(points) == "table" and points or {}
        local muzzle = typeof(points[1]) == "Vector3" and points[1] or nil
        if not muzzle then
            local ok_muzzle, position = pcall(fps_view.MuzzlePosition)
            muzzle = ok_muzzle and typeof(position) == "Vector3" and position or nil
        end
        local ok_root, gun_root = pcall(fps_view.GunRoot)
        local buried = muzzle ~= nil and barrel_buried(muzzle, points[2], ok_root and gun_root or nil, camera.CFrame.Position, localplayer:GetAttribute("CSGO_Tps") == true)
        target = get_target(muzzle or my_root.Position, buried)
        local shape = target and get_shapes(target.char)[target.name]
        target_pos = shape and shape.cf.Position
        if not target_pos then
            target = nil
        end
    end
    current_target = target
    update_auto_shoot()

    if target and aim_active and config.look_spoof and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
        spoof_look, spoof_time = (target_pos - camera.CFrame.Position).Unit, os.clock()
    end

    if target then
        local pos = camera:WorldToViewportPoint(target_pos)
        local screen_pos = Vector2.new(pos.X, pos.Y)
        dot.Position = screen_pos
        dot.Color = config.target_dot_color
        target_line.From = screen_center()
        target_line.To = screen_pos
        target_line.Color = config.target_tracer_color
    end
    dot.Visible = target ~= nil and config.show_target
    target_line.Visible = target ~= nil and config.target_tracer

    update_bullet_tracers(camera)

    local target_char = target and target.char
    for _, player in Players:GetPlayers() do
        if player ~= localplayer then
            update_esp(player, camera, my_root, target_char)
        end
    end
end)))

local function setup_world(world)
    local Lighting = game:GetService("Lighting")
    local MaterialService = game:GetService("MaterialService")
    local SoundService = game:GetService("SoundService")

    local WORLD_STEP = "warz_world"
    local WHITE = Color3.new(1, 1, 1)
    local TEXTURE_WHITE = Color3.fromRGB(254, 253, 255)
    local WEATHER_SIZE, WEATHER_OFFSET = Vector3.new(40, 40, 85), Vector3.new(0, 20, 0)
    local LIGHTING_PROPS = {"ClockTime", "Technology", "Ambient", "OutdoorAmbient"}
    local SKY_FACES = {"SkyboxBk", "SkyboxDn", "SkyboxFt", "SkyboxLf", "SkyboxRt", "SkyboxUp"}
    local SKIP_FOLDERS = {WarzLoot = true, WarzFx = true, WarzDummies = true}

    local SKYBOX_NAMES = {"Black Storm", "Blue Space", "Realistic", "Stormy", "Pink"}
    local SKYBOXES = {
        ["Black Storm"] = {
            SkyboxBk = "rbxassetid://15502511288", SkyboxDn = "rbxassetid://15502508460", SkyboxFt = "rbxassetid://15502510289",
            SkyboxLf = "rbxassetid://15502507918", SkyboxRt = "rbxassetid://15502509398", SkyboxUp = "rbxassetid://15502511911",
        },
        ["Blue Space"] = {
            SkyboxBk = "rbxassetid://15536110634", SkyboxDn = "rbxassetid://15536112543", SkyboxFt = "rbxassetid://15536116141",
            SkyboxLf = "rbxassetid://15536114370", SkyboxRt = "rbxassetid://15536118762", SkyboxUp = "rbxassetid://15536117282",
        },
        Realistic = {
            SkyboxBk = "rbxassetid://653719502", SkyboxDn = "rbxassetid://653718790", SkyboxFt = "rbxassetid://653719067",
            SkyboxLf = "rbxassetid://653719190", SkyboxRt = "rbxassetid://653718931", SkyboxUp = "rbxassetid://653719321",
        },
        Stormy = {
            SkyboxBk = "http://www.roblox.com/asset/?id=18703245834", SkyboxDn = "http://www.roblox.com/asset/?id=18703243349",
            SkyboxFt = "http://www.roblox.com/asset/?id=18703240532", SkyboxLf = "http://www.roblox.com/asset/?id=18703237556",
            SkyboxRt = "http://www.roblox.com/asset/?id=18703235430", SkyboxUp = "http://www.roblox.com/asset/?id=18703232671",
        },
        Pink = {
            SkyboxBk = "rbxassetid://12216109205", SkyboxDn = "rbxassetid://12216109875", SkyboxFt = "rbxassetid://12216109489",
            SkyboxLf = "rbxassetid://12216110170", SkyboxRt = "rbxassetid://12216110471", SkyboxUp = "rbxassetid://12216108877",
        },
    }

    local SOUND_NAMES = {"Windy Winter", "Thunderstorm", "Light Rain", "Night", "Day"}
    local SOUNDS = {
        ["Windy Winter"] = "rbxassetid://6046340391",
        Thunderstorm = "rbxassetid://4305545740",
        ["Light Rain"] = "rbxassetid://18862087062",
        Night = "rbxassetid://179507208",
        Day = "rbxassetid://6189453706",
    }

    local WEATHER_NAMES = {"Light Rain", "Rain", "Snow"}
    local WEATHERS = {
        ["Light Rain"] = {
            LockedToPart = true, Rate = 500, Brightness = 2, LightEmission = 0.5, LightInfluence = 0.3,
            Texture = "rbxasset://textures/particles/sparkles_main.dds",
            Speed = NumberRange.new(30, 50), Lifetime = NumberRange.new(9, 9),
            EmissionDirection = Enum.NormalId.Bottom, Orientation = Enum.ParticleOrientation.FacingCameraWorldUp,
            Size = NumberSequence.new(0.2), Squash = NumberSequence.new(3),
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.435, 0), NumberSequenceKeypoint.new(1, 1),
            }),
        },
        Rain = {
            LockedToPart = true, Rate = 600, LightEmission = 0.05, LightInfluence = 0.9,
            Texture = "rbxassetid://1822883048",
            Speed = NumberRange.new(60, 60), Lifetime = NumberRange.new(0.8, 0.8),
            EmissionDirection = Enum.NormalId.Bottom, Orientation = Enum.ParticleOrientation.FacingCameraWorldUp,
            Size = NumberSequence.new(10),
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.25, 0.784),
                NumberSequenceKeypoint.new(0.75, 0.784), NumberSequenceKeypoint.new(1, 1),
            }),
        },
        Snow = {
            Rate = 1000, LightEmission = 0.5,
            Texture = "http://www.roblox.com/asset/?id=99851851",
            Speed = NumberRange.new(30, 30), SpreadAngle = Vector2.new(50, 50),
            EmissionDirection = Enum.NormalId.Bottom,
            Size = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.331), NumberSequenceKeypoint.new(0.551, 0.402), NumberSequenceKeypoint.new(1, 0.331),
            }),
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.7375), NumberSequenceKeypoint.new(0.973, 0.76875), NumberSequenceKeypoint.new(1, 1),
            }),
        },
    }

    local TEXTURE_PACK_NAMES = {"Minecraft"}
    local TEXTURE_PACKS = {
        Minecraft = {
            Slate = "http://www.roblox.com/asset/?id=8676746437",
            Grass = "http://www.roblox.com/asset/?id=9267183930",
            Sand = "http://www.roblox.com/asset/?id=12624140843",
            Wood = "http://www.roblox.com/asset/?id=3258599312",
            Brick = "http://www.roblox.com/asset/?id=10777285622",
            Concrete = "http://www.roblox.com/asset/?id=15622710576",
            CorrodedMetal = "rbxassetid://78612695839404",
            Metal = "http://www.roblox.com/asset/?id=121650613091353",
            WoodPlanks = "http://www.roblox.com/asset/?id=8676581022",
        },
    }

    local technologies, technology_names = {}, {}
    for _, item in Enum.Technology:GetEnumItems() do
        technologies[item.Name] = item
        table.insert(technology_names, item.Name)
    end

    local set_prop = function(instance, prop, value)
        instance[prop] = value
    end

    local get_prop = function(instance, prop)
        return instance[prop]
    end

    local same = LPH_NO_VIRTUALIZE(function(a, b)
        if type(a) == "number" and type(b) == "number" then
            return math.abs(a - b) < 1e-5
        end
        return a == b
    end)

    local write = LPH_NO_VIRTUALIZE(function(instance, prop, value)
        if not pcall(set_prop, instance, prop, value) and sethiddenproperty then
            pcall(sethiddenproperty, instance, prop, value)
        end
    end)

    local set_if = LPH_NO_VIRTUALIZE(function(instance, prop, value)
        if not same(instance[prop], value) then
            instance[prop] = value
        end
    end)

    -- per instance/prop: game = value the game wants, want = our value, applied = what the instance held after our write
    local lit = {}
    local overrides = setmetatable({[Lighting] = lit}, {__mode = "k"})

    local force = LPH_NO_VIRTUALIZE(function(instance, prop, value)
        local props = overrides[instance]
        if not props then
            props = {}
            overrides[instance] = props
        end
        local current = instance[prop]
        local entry = props[prop]
        if not entry then
            entry = {game = current}
            props[prop] = entry
        elseif not same(current, entry.applied) then
            entry.game = current
        elseif same(value, entry.want) then
            return
        end
        if not same(current, value) then
            write(instance, prop, value)
            current = instance[prop]
        end
        entry.want, entry.applied = value, current
    end)

    local release = LPH_NO_VIRTUALIZE(function(instance, prop)
        local props = overrides[instance]
        local entry = props and props[prop]
        if not entry then
            return
        end
        props[prop] = nil
        local ok, current = pcall(get_prop, instance, prop)
        if ok and same(current, entry.applied) then
            write(instance, prop, entry.game)
        end
    end)

    local toggle_prop = LPH_NO_VIRTUALIZE(function(instance, prop, enabled, value)
        if enabled and value ~= nil then
            force(instance, prop, value)
        else
            release(instance, prop)
        end
    end)

    local release_class = LPH_NO_VIRTUALIZE(function(class)
        for instance, props in overrides do
            if instance ~= Lighting and instance.ClassName == class then
                for prop in props do
                    release(instance, prop)
                end
                overrides[instance] = nil
            end
        end
    end)

    local owned, state = {}, {}

    local drop = function(key)
        local instance = owned[key]
        if instance then
            owned[key] = nil
            pcall(instance.Destroy, instance)
        end
    end

    local clock_text = function(clock)
        local seconds = math.floor((clock % 24) * 3600 + 0.5)
        return string.format("%02d:%02d:%02d", seconds // 3600 % 24, seconds // 60 % 60, seconds % 60)
    end

    local clock_value = function(text)
        local h, m, s = string.match(text, "^%s*(%-?%d+):(%d+):?(%d*)")
        if h then
            return (tonumber(h) + tonumber(m) / 60 + (tonumber(s) or 0) / 3600) % 24
        end
    end

    -- game scripts read/write the values they expect while ours stay applied; only Lighting gets this metatable
    local lighting_mt = getgenv().__warz_lighting_mt
    if not lighting_mt and getrawmetatable then
        local ok, mt = pcall(getrawmetatable, Lighting)
        if ok and type(mt) == "table" then
            lighting_mt = mt
            getgenv().__warz_lighting_mt = mt
        end
    end

    local spoofed = false
    if lighting_mt and setrawmetatable and checkcaller and newcclosure then
        local old_index, old_newindex = lighting_mt.__index, lighting_mt.__newindex
        local fake = {}
        for key, value in lighting_mt do
            fake[key] = value
        end
        fake.__index = newcclosure(LPH_NO_VIRTUALIZE(function(self, key)
            if not checkcaller() then
                local entry = lit[key]
                if entry then
                    return entry.game
                elseif key == "TimeOfDay" and lit.ClockTime then
                    return clock_text(lit.ClockTime.game)
                end
            end
            return old_index(self, key)
        end))
        fake.__newindex = newcclosure(LPH_NO_VIRTUALIZE(function(self, key, value)
            if not checkcaller() then
                local entry = lit[key]
                if entry and typeof(value) == typeof(entry.game) then
                    entry.game = value
                    return
                elseif key == "TimeOfDay" and lit.ClockTime and type(value) == "string" then
                    local clock = clock_value(value)
                    if clock then
                        lit.ClockTime.game = clock
                        return
                    end
                end
            end
            return old_newindex(self, key, value)
        end))
        spoofed = pcall(setrawmetatable, Lighting, fake)
    end

    local update_lighting = LPH_NO_VIRTUALIZE(function()
        toggle_prop(Lighting, "ClockTime", world.time, world.time_value)
        toggle_prop(Lighting, "Technology", world.lighting, technologies[world.lighting_mode])
        toggle_prop(Lighting, "Ambient", world.ambient, world.ambient_color)
        toggle_prop(Lighting, "OutdoorAmbient", world.ambient, world.outdoor_color)
    end)

    local update_color = LPH_NO_VIRTUALIZE(function()
        if not (world.saturation or world.contrast or world.tint) then
            drop("color")
            return
        end
        local effect = owned.color
        if not effect or effect.Parent ~= Lighting then
            drop("color")
            effect = Instance.new("ColorCorrectionEffect")
            effect.Name = "\0"
            effect.Parent = Lighting
            owned.color = effect
        end
        set_if(effect, "Saturation", world.saturation and world.saturation_value or 0)
        set_if(effect, "Contrast", world.contrast and world.contrast_value or 0)
        set_if(effect, "TintColor", world.tint and world.tint_color or WHITE)
    end)

    local force_atmosphere = LPH_NO_VIRTUALIZE(function(atmosphere)
        force(atmosphere, "Color", world.atmosphere_color)
        force(atmosphere, "Decay", world.atmosphere_decay)
        force(atmosphere, "Density", world.atmosphere_density)
        force(atmosphere, "Offset", world.atmosphere_offset)
        force(atmosphere, "Haze", world.atmosphere_haze)
        force(atmosphere, "Glare", world.atmosphere_glare)
    end)

    local update_sky = LPH_NO_VIRTUALIZE(function()
        local faces = world.skybox and SKYBOXES[world.skybox_value]
        local atmosphere_on = world.atmosphere
        if not faces and state.sky then
            state.sky = false
            release_class("Sky")
            drop("sky")
        end
        if not atmosphere_on and state.atmosphere then
            state.atmosphere = false
            release_class("Atmosphere")
            drop("atmosphere")
        end
        if not faces and not atmosphere_on then
            return
        end
        local has_sky, has_atmosphere = false, false
        for _, child in Lighting:GetChildren() do
            local class = child.ClassName
            if faces and class == "Sky" then
                has_sky = true
                for _, face in SKY_FACES do
                    force(child, face, faces[face])
                end
            elseif atmosphere_on and class == "Atmosphere" then
                has_atmosphere = true
                force_atmosphere(child)
            end
        end
        if faces then
            state.sky = true
            if not has_sky then
                drop("sky")
                local sky = Instance.new("Sky")
                sky.Name = "\0"
                for _, face in SKY_FACES do
                    sky[face] = faces[face]
                end
                sky.Parent = Lighting
                owned.sky = sky
            end
        end
        if atmosphere_on then
            state.atmosphere = true
            if not has_atmosphere then
                drop("atmosphere")
                local atmosphere = Instance.new("Atmosphere")
                atmosphere.Name = "\0"
                atmosphere.Parent = Lighting
                owned.atmosphere = atmosphere
                force_atmosphere(atmosphere)
            end
        end
    end)

    local update_weather = LPH_NO_VIRTUALIZE(function()
        local data = world.weather and WEATHERS[world.weather_type]
        local camera = workspace.CurrentCamera
        if not data or not camera then
            drop("weather")
            return
        end
        local part = owned.weather
        if not part or not part:IsDescendantOf(workspace) then
            drop("weather")
            part = Instance.new("Part")
            part.Name = "\0"
            part.Size = WEATHER_SIZE
            part.Transparency = 1
            part.Anchored = true
            part.CanCollide = false
            part.CanTouch = false
            part.CanQuery = false
            part.CastShadow = false
            part.Parent = camera
            owned.weather = part
            state.weather_type = nil
        end
        if state.weather_type ~= world.weather_type then
            if state.emitter then
                pcall(state.emitter.Destroy, state.emitter)
            end
            local emitter = Instance.new("ParticleEmitter")
            for key, value in data do
                pcall(set_prop, emitter, key, value)
            end
            emitter.Parent = part
            state.emitter, state.weather_type = emitter, world.weather_type
            state.weather_color, state.weather_rate = nil, nil
        end
        local emitter = state.emitter
        if state.weather_color ~= world.weather_color then
            state.weather_color = world.weather_color
            emitter.Color = ColorSequence.new(world.weather_color)
        end
        local rate = data.Rate * world.weather_rate / 100
        if state.weather_rate ~= rate then
            state.weather_rate = rate
            emitter.Rate = rate
        end
        part.CFrame = CFrame.new(camera.CFrame.Position + WEATHER_OFFSET)
    end)

    local sound_parent = function()
        local ok, hui = pcall(gethui)
        if ok and typeof(hui) == "Instance" and hui:IsDescendantOf(game) then
            return hui
        end
        return SoundService
    end

    local update_noise = LPH_NO_VIRTUALIZE(function()
        local id = world.noise and SOUNDS[world.noise_sound]
        if not id then
            drop("sound")
            return
        end
        local sound = owned.sound
        if not sound or not sound:IsDescendantOf(game) then
            drop("sound")
            sound = Instance.new("Sound")
            sound.Name = "\0"
            sound.Looped = true
            sound.Parent = sound_parent()
            owned.sound = sound
            state.sound_id, state.sound_volume = nil, nil
        end
        local volume = world.noise_volume / 65
        if state.sound_volume ~= volume then
            state.sound_volume = volume
            sound.Volume = volume
        end
        if state.sound_id ~= id then
            state.sound_id = id
            sound:Stop()
            sound.SoundId = id
            sound:Play()
        elseif not sound.Playing then
            sound:Play()
        end
    end)

    local textures = {pack = nil, variants = {}, colors = setmetatable({}, {__mode = "k"}), connection = nil}

    local texture_blocked = LPH_NO_VIRTUALIZE(function(node)
        if node:IsA("Camera") then
            return true
        elseif node:IsA("Model") then
            return node:FindFirstChildOfClass("Humanoid") ~= nil or Players:GetPlayerFromCharacter(node) ~= nil
        end
        return node.Parent == workspace and SKIP_FOLDERS[node.Name] == true
    end)

    -- skips characters, loot, fx and the camera so only the map gets recolored
    local texture_allowed = LPH_NO_VIRTUALIZE(function(part, memo)
        local path = memo and {}
        local node, allowed = part.Parent, nil
        while allowed == nil do
            if node == workspace then
                allowed = true
            elseif node == nil then
                allowed = false
            elseif memo and memo[node] ~= nil then
                allowed = memo[node]
            elseif texture_blocked(node) then
                allowed = false
                if memo then
                    memo[node] = false
                end
            else
                if path then
                    table.insert(path, node)
                end
                node = node.Parent
            end
        end
        if path then
            for _, visited in path do
                memo[visited] = allowed
            end
        end
        return allowed
    end)

    local texture_part = LPH_NO_VIRTUALIZE(function(part, memo)
        local pack = textures.pack
        if pack and part:IsA("BasePart") and not part:IsA("Terrain") and pack[part.Material.Name] ~= nil
            and part.Transparency < 0.8 and textures.colors[part] == nil and texture_allowed(part, memo) then
            textures.colors[part] = part.Color
            part.Color = TEXTURE_WHITE
        end
    end)

    local set_texture_pack = function(pack)
        if textures.connection then
            textures.connection:Disconnect()
            textures.connection = nil
        end
        for _, variant in textures.variants do
            pcall(variant.Destroy, variant)
        end
        table.clear(textures.variants)
        for part, color in textures.colors do
            if part.Color == TEXTURE_WHITE then
                part.Color = color
            end
        end
        table.clear(textures.colors)
        local service_props = overrides[MaterialService]
        if service_props then
            for prop in service_props do
                release(MaterialService, prop)
            end
        end
        textures.pack = pack
        if not pack then
            return
        end
        for name, id in pack do
            local ok, material = pcall(get_prop, Enum.Material, name)
            if ok and material then
                local variant = Instance.new("MaterialVariant")
                variant.Name = name
                write(variant, "BaseMaterial", material)
                write(variant, "StudsPerTile", 5)
                for _, map in {"ColorMap", "NormalMap", "MetalnessMap", "RoughnessMap"} do
                    write(variant, map, id)
                end
                variant.Parent = MaterialService
                table.insert(textures.variants, variant)
                pcall(force, MaterialService, name .. "Name", name)
            end
        end
        local memo = {}
        for _, part in workspace:GetDescendants() do
            texture_part(part, memo)
        end
        textures.connection = workspace.DescendantAdded:Connect(texture_part)
    end

    local update_textures = function()
        local pack = world.textures and TEXTURE_PACKS[world.texture_pack] or nil
        if pack ~= textures.pack then
            set_texture_pack(pack)
        end
    end

    local updates = {update_lighting, update_color, update_sky, update_weather, update_noise, update_textures}

    pcall(RunService.UnbindFromRenderStep, RunService, WORLD_STEP)
    RunService:BindToRenderStep(WORLD_STEP, Enum.RenderPriority.Last.Value, LPH_NO_VIRTUALIZE(function()
        for _, update in updates do
            pcall(update)
        end
    end))

    local ok_tech, technology = pcall(function()
        return Lighting.Technology.Name
    end)

    return {
        technologies = technology_names,
        technology = ok_tech and technologies[technology] and technology or technology_names[1],
        ambient = Lighting.Ambient,
        outdoor = Lighting.OutdoorAmbient,
        skyboxes = SKYBOX_NAMES,
        sounds = SOUND_NAMES,
        weathers = WEATHER_NAMES,
        packs = TEXTURE_PACK_NAMES,
        unload = function()
            pcall(RunService.UnbindFromRenderStep, RunService, WORLD_STEP)
            pcall(set_texture_pack, nil)
            for _, prop in LIGHTING_PROPS do
                pcall(release, Lighting, prop)
            end
            pcall(release_class, "Sky")
            pcall(release_class, "Atmosphere")
            for key in owned do
                drop(key)
            end
            if spoofed then
                pcall(setrawmetatable, Lighting, lighting_mt)
            end
        end,
    }
end

local world_fx = setup_world(config.world)

local function build_menu()
    local Window = Library:CreateWindow({
        Title = '<font color="#ffffff">WarZ PvP</font>',
        Center = true,
        AutoShow = true,
        Resizable = true,
        ShowCustomCursor = true,
        UnlockMouseWhileOpen = true,
        NotifySide = "Left",
        TabPadding = 8,
        MenuFadeTime = 0.2,
    })

    for instance, data in Library.RegistryMap do
        if typeof(instance) == "Instance" and instance:IsA("TextLabel") and instance.AnchorPoint == Vector2.new(1, 0)
            and instance.Parent and instance.Parent.Name == "Inner" and data.Properties.TextColor3 == "AccentColor" then
            local red = Color3.fromRGB(255, 0, 0)
            for _, entry in Library.Registry do
                if entry.Instance == instance and entry.Properties.TextColor3 ~= nil then
                    entry.Properties.TextColor3 = function()
                        return red
                    end
                end
            end
            instance.TextColor3 = red
            break
        end
    end

    local Tabs = {
        Main = Window:AddTab("Main"),
        Visuals = Window:AddTab("Visuals"),
        Misc = Window:AddTab("Misc"),
        ["UI Settings"] = Window:AddTab("UI Settings"),
    }

    local CombatBox = Tabs.Main:AddLeftTabbox()
    local SilentGroup = CombatBox:AddTab("Silent Aim")
    local AimbotGroup = CombatBox:AddTab("Aimbot")

    SilentGroup:AddToggle("SilentAimEnabled", {
        Text = "Silent Aim",
        Default = false,
    }):AddKeyPicker("SilentAimKey", {
        Default = "X",
        Mode = "Toggle",
        Modes = {"Toggle", "Hold", "Always"},
        Text = "Silent Aim",
    })

    SilentGroup:AddDropdown("SilentAimHitParts", {
        Text = "Hit Part (Multi)",
        Values = {"Head", "Neck", "Torso", "Arms", "Legs"},
        Default = 1,
        Multi = true,
    })

    SilentGroup:AddDropdown("SilentAimHitMode", {
        Text = "Hit Part Mode",
        Values = {"Random", "Closest"},
        Default = 1,
    })

    SilentGroup:AddDivider()

    SilentGroup:AddToggle("SilentAimPrediction", {
        Text = "Prediction",
        Default = true,
    })
    SilentGroup:AddToggle("SilentAimDrop", {
        Text = "Bullet Drop",
        Default = true,
    })
    SilentGroup:AddToggle("SilentAimLookSpoof", {
        Text = "Look Spoof",
        Default = true,
    })
    SilentGroup:AddSlider("SilentAimMaxDistance", {
        Text = "Max Distance",
        Default = 300,
        Min = 25,
        Max = 4000,
        Rounding = 0,
        Suffix = "m",
    })

    SilentGroup:AddDivider()

    SilentGroup:AddToggle("AutoShoot", {
        Text = "Auto Shoot",
        Default = false,
    }):AddKeyPicker("AutoShootKey", {
        Default = "None",
        Mode = "Toggle",
        Modes = {"Toggle", "Hold", "Always"},
        Text = "Auto Shoot",
    })
    SilentGroup:AddToggle("AutoReload", {
        Text = "Auto Reload",
        Default = true,
    })

    AimbotGroup:AddToggle("Aimbot", {
        Text = "Aimbot",
        Default = false,
    }):AddKeyPicker("AimbotKey", {
        Default = "MB2",
        Mode = "Hold",
        Modes = {"Toggle", "Hold", "Always"},
        Text = "Aimbot",
    })
    AimbotGroup:AddToggle("AimbotSticky", {
        Text = "Sticky Aim",
        Default = true,
    })
    AimbotGroup:AddDropdown("AimbotPart", {
        Text = "Aim Part",
        Values = {"Head", "Neck", "Torso"},
        Default = 1,
    })
    AimbotGroup:AddSlider("AimbotSmooth", {
        Text = "Smoothness",
        Default = 5,
        Min = 1,
        Max = 20,
        Rounding = 1,
    })
    AimbotGroup:AddToggle("AimbotPrediction", {
        Text = "Prediction",
        Default = true,
    })
    AimbotGroup:AddToggle("AimbotWallCheck", {
        Text = "Wall Check",
        Default = true,
    })
    AimbotGroup:AddToggle("AimbotShowFOV", {
        Text = "Show FOV",
        Default = true,
    }):AddColorPicker("AimbotFOVColor", {
        Default = Color3.fromRGB(255, 120, 60),
        Title = "Aimbot FOV Color",
    })
    AimbotGroup:AddSlider("AimbotFOV", {
        Text = "FOV Radius",
        Default = 150,
        Min = 10,
        Max = 800,
        Rounding = 0,
        Suffix = "px",
    })

    local GunGroup = Tabs.Main:AddLeftGroupbox("Gun Mods")

    GunGroup:AddToggle("NoSpread", {
        Text = "No Spread",
        Default = false,
    })
    GunGroup:AddToggle("NoRecoil", {
        Text = "No Recoil",
        Default = false,
    })
    GunGroup:AddToggle("AutoGun", {
        Text = "Automatic Gun",
        Default = false,
    })
    GunGroup:AddToggle("RapidFire", {
        Text = "Rapid Fire",
        Default = false,
    })
    local RapidDepbox = GunGroup:AddDependencyBox()
    RapidDepbox:AddSlider("RapidFireRate", {
        Text = "Fire Rate",
        Default = 1.5,
        Min = 1,
        Max = 5,
        Rounding = 1,
        Suffix = "x",
    })
    RapidDepbox:SetupDependencies({
        {Toggles.RapidFire, true},
    })

    GunGroup:AddDivider()

    GunGroup:AddToggle("Wallbang", {
        Text = "Wallbang",
        Default = false,
    })
    GunGroup:AddSlider("MagicRadius", {
        Text = "Wallbang Distance",
        Default = 4.5,
        Min = 1,
        Max = 200,
        Rounding = 1,
        Suffix = " studs",
    })

    local ChecksGroup = Tabs.Main:AddRightGroupbox("Checks")

    ChecksGroup:AddToggle("SilentAimWallCheck", {
        Text = "Wall Check",
        Default = true,
    })
    ChecksGroup:AddToggle("SilentAimTeamCheck", {
        Text = "Team Check",
        Default = true,
    })
    ChecksGroup:AddToggle("SilentAimClanCheck", {
        Text = "Clan Check",
        Default = false,
    })
    ChecksGroup:AddToggle("SilentAimProtectCheck", {
        Text = "Spawn Protect Check",
        Default = true,
    })
    ChecksGroup:AddInput("WhitelistSearch", {
        Text = "Search Player",
        Default = "",
        Placeholder = "Name / Display Name",
        Numeric = false,
        Finished = false,
    })
    ChecksGroup:AddDropdown("SilentAimWhitelist", {
        Text = "Whitelist",
        Values = {},
        Multi = true,
        AllowNull = true,
    })

    local FovGroup = Tabs.Main:AddRightGroupbox("FOV & Tracer")

    FovGroup:AddToggle("ShowFOV", {
        Text = "Show FOV",
        Default = true,
    }):AddColorPicker("FOVColor", {
        Default = Color3.fromRGB(255, 255, 255),
        Title = "FOV Color",
    })

    FovGroup:AddSlider("FOVRadius", {
        Text = "FOV Radius",
        Default = 120,
        Min = 10,
        Max = 800,
        Rounding = 0,
        Suffix = "px",
    })

    FovGroup:AddToggle("ShowTarget", {
        Text = "Show Target",
        Default = true,
    }):AddColorPicker("TargetDotColor", {
        Default = Color3.fromRGB(255, 60, 60),
        Title = "Target Color",
    })

    FovGroup:AddDivider()

    FovGroup:AddToggle("TargetTracer", {
        Text = "Target Tracer",
        Default = false,
    }):AddColorPicker("TargetTracerColor", {
        Default = Color3.fromRGB(255, 60, 60),
        Title = "Target Tracer Color",
    })

    FovGroup:AddToggle("BulletTracer", {
        Text = "Bullet Tracer",
        Default = false,
    }):AddColorPicker("BulletTracerColor", {
        Default = Color3.fromRGB(133, 220, 255),
        Title = "Bullet Tracer Color",
        Transparency = 0,
    })

    local BulletTracerDepbox = FovGroup:AddDependencyBox()
    BulletTracerDepbox:AddDropdown("BulletTracerType", {
        Text = "Tracer Type",
        Values = {"Beam", "Line"},
        Default = 1,
    })
    local tracer_is_beam = {Type = "Toggle", Value = true}
    local TracerBeamDepbox = BulletTracerDepbox:AddDependencyBox()
    TracerBeamDepbox:AddDropdown("BulletTracerStyle", {
        Text = "Tracer Style",
        Values = {"Laser", "Light", "Flow"},
        Default = 1,
    })
    TracerBeamDepbox:AddLabel("Gradient Color"):AddColorPicker("BulletTracerGradient", {
        Default = Color3.fromRGB(241, 133, 255),
        Title = "Gradient Color",
        Transparency = 0,
    })
    TracerBeamDepbox:SetupDependencies({
        {tracer_is_beam, true},
    })
    local TracerLineDepbox = BulletTracerDepbox:AddDependencyBox()
    TracerLineDepbox:AddLabel("Outline Color"):AddColorPicker("BulletTracerOutline", {
        Default = Color3.fromRGB(15, 15, 15),
        Title = "Outline Color",
        Transparency = 0,
    })
    TracerLineDepbox:SetupDependencies({
        {tracer_is_beam, false},
    })
    BulletTracerDepbox:AddSlider("BulletTracerTime", {
        Text = "Tracer Time",
        Default = 0.8,
        Min = 0.1,
        Max = 1.5,
        Rounding = 1,
        Suffix = "s",
    })
    BulletTracerDepbox:SetupDependencies({
        {Toggles.BulletTracer, true},
    })
    for _, flag in {"BulletTracerColor", "BulletTracerGradient", "BulletTracerOutline"} do
        Options[flag].HasTransparency = true
    end

    local EspGroup = Tabs.Visuals:AddLeftGroupbox("ESP")

    EspGroup:AddToggle("ESPEnabled", {
        Text = "ESP",
        Default = false,
    })

    EspGroup:AddToggle("ESPBox", {Text = "Box", Default = true})
    EspGroup:AddToggle("ESPName", {Text = "Name", Default = true})
    EspGroup:AddDropdown("ESPNameMode", {
        Text = "Name Type",
        Values = {"Display", "Username", "Both"},
        Default = 1,
    })
    EspGroup:AddToggle("ESPHealth", {Text = "Health Bar", Default = true})
    EspGroup:AddToggle("ESPDistance", {Text = "Distance", Default = true})
    EspGroup:AddToggle("ESPWeapon", {Text = "Weapon", Default = true})
    EspGroup:AddDivider()
    EspGroup:AddToggle("ESPTeamCheck", {
        Text = "Hide Team",
        Default = false,
    })
    EspGroup:AddSlider("ESPMaxDistance", {
        Text = "Max Distance",
        Default = 1000,
        Min = 50,
        Max = 4000,
        Rounding = 0,
        Suffix = "m",
    })

    local EspColorGroup = Tabs.Visuals:AddRightGroupbox("ESP Colors")

    EspColorGroup:AddLabel("Enemy"):AddColorPicker("ESPColor", {
        Default = Color3.fromRGB(255, 255, 255),
        Title = "Enemy Color",
    })
    EspColorGroup:AddLabel("Team"):AddColorPicker("ESPTeamColor", {
        Default = Color3.fromRGB(80, 255, 120),
        Title = "Team Color",
    })
    EspColorGroup:AddLabel("Silent Aim Target"):AddColorPicker("ESPTargetColor", {
        Default = Color3.fromRGB(255, 60, 60),
        Title = "Target Color",
    })
    EspColorGroup:AddSlider("ESPTextSize", {
        Text = "Text Size",
        Default = 13,
        Min = 10,
        Max = 20,
        Rounding = 0,
    })

    local WorldGroup = Tabs.Visuals:AddLeftGroupbox("World")

    WorldGroup:AddToggle("WorldTime", {Text = "World Time", Default = false})
    local WorldTimeDepbox = WorldGroup:AddDependencyBox()
    WorldTimeDepbox:AddSlider("WorldTimeValue", {
        Text = "Time",
        Default = 4.5,
        Min = 0,
        Max = 24,
        Rounding = 1,
        Suffix = "h",
    })
    WorldTimeDepbox:SetupDependencies({
        {Toggles.WorldTime, true},
    })

    WorldGroup:AddToggle("WorldLighting", {Text = "Lighting Mode", Default = false})
    local WorldLightingDepbox = WorldGroup:AddDependencyBox()
    WorldLightingDepbox:AddDropdown("WorldLightingMode", {
        Text = "Technology",
        Values = world_fx.technologies,
        Default = world_fx.technology,
    })
    WorldLightingDepbox:SetupDependencies({
        {Toggles.WorldLighting, true},
    })

    WorldGroup:AddToggle("WorldAmbient", {Text = "Ambient", Default = false})
    local WorldAmbientDepbox = WorldGroup:AddDependencyBox()
    WorldAmbientDepbox:AddLabel("Ambient Color"):AddColorPicker("WorldAmbientColor", {
        Default = world_fx.ambient,
        Title = "Ambient Color",
    })
    WorldAmbientDepbox:AddLabel("Outdoor Color"):AddColorPicker("WorldOutdoorColor", {
        Default = world_fx.outdoor,
        Title = "Outdoor Ambient Color",
    })
    WorldAmbientDepbox:SetupDependencies({
        {Toggles.WorldAmbient, true},
    })

    WorldGroup:AddToggle("WorldSaturation", {Text = "Saturation", Default = false})
    local WorldSaturationDepbox = WorldGroup:AddDependencyBox()
    WorldSaturationDepbox:AddSlider("WorldSaturationValue", {
        Text = "Amount",
        Default = 0,
        Min = -1,
        Max = 1,
        Rounding = 2,
    })
    WorldSaturationDepbox:SetupDependencies({
        {Toggles.WorldSaturation, true},
    })

    WorldGroup:AddToggle("WorldContrast", {Text = "Contrast", Default = false})
    local WorldContrastDepbox = WorldGroup:AddDependencyBox()
    WorldContrastDepbox:AddSlider("WorldContrastValue", {
        Text = "Amount",
        Default = 0,
        Min = -1,
        Max = 1,
        Rounding = 2,
    })
    WorldContrastDepbox:SetupDependencies({
        {Toggles.WorldContrast, true},
    })

    WorldGroup:AddToggle("WorldTint", {
        Text = "Tint",
        Default = false,
    }):AddColorPicker("WorldTintColor", {
        Default = Color3.fromRGB(255, 255, 255),
        Title = "Tint Color",
    })

    WorldGroup:AddToggle("WorldTextures", {Text = "Textures", Default = false})
    local WorldTexturesDepbox = WorldGroup:AddDependencyBox()
    WorldTexturesDepbox:AddDropdown("WorldTexturePack", {
        Text = "Pack",
        Values = world_fx.packs,
        Default = 1,
    })
    WorldTexturesDepbox:SetupDependencies({
        {Toggles.WorldTextures, true},
    })

    local SkyGroup = Tabs.Visuals:AddRightGroupbox("Sky")

    SkyGroup:AddToggle("WorldSkybox", {Text = "Skybox", Default = false})
    local SkyboxDepbox = SkyGroup:AddDependencyBox()
    SkyboxDepbox:AddDropdown("WorldSkyboxValue", {
        Text = "Sky",
        Values = world_fx.skyboxes,
        Default = "Black Storm",
    })
    SkyboxDepbox:SetupDependencies({
        {Toggles.WorldSkybox, true},
    })

    SkyGroup:AddDivider()

    SkyGroup:AddToggle("WorldAtmosphere", {Text = "Atmosphere", Default = false})
    local AtmosphereDepbox = SkyGroup:AddDependencyBox()
    AtmosphereDepbox:AddLabel("Color"):AddColorPicker("WorldAtmosphereColor", {
        Default = Color3.fromRGB(255, 255, 255),
        Title = "Atmosphere Color",
    })
    AtmosphereDepbox:AddLabel("Decay"):AddColorPicker("WorldAtmosphereDecay", {
        Default = Color3.fromRGB(120, 120, 120),
        Title = "Atmosphere Decay",
    })
    AtmosphereDepbox:AddSlider("WorldAtmosphereDensity", {
        Text = "Density",
        Default = 0.35,
        Min = 0,
        Max = 1,
        Rounding = 3,
    })
    AtmosphereDepbox:AddSlider("WorldAtmosphereOffset", {
        Text = "Offset",
        Default = 0,
        Min = 0,
        Max = 1,
        Rounding = 3,
    })
    AtmosphereDepbox:AddSlider("WorldAtmosphereHaze", {
        Text = "Haze",
        Default = 1,
        Min = 0,
        Max = 10,
        Rounding = 2,
    })
    AtmosphereDepbox:AddSlider("WorldAtmosphereGlare", {
        Text = "Glare",
        Default = 10,
        Min = 0,
        Max = 10,
        Rounding = 2,
    })
    AtmosphereDepbox:SetupDependencies({
        {Toggles.WorldAtmosphere, true},
    })

    local WeatherGroup = Tabs.Visuals:AddRightGroupbox("Weather")

    WeatherGroup:AddToggle("WorldWeather", {
        Text = "Weather",
        Default = false,
    }):AddColorPicker("WorldWeatherColor", {
        Default = Color3.fromRGB(255, 255, 255),
        Title = "Weather Color",
    })
    local WeatherDepbox = WeatherGroup:AddDependencyBox()
    WeatherDepbox:AddDropdown("WorldWeatherType", {
        Text = "Type",
        Values = world_fx.weathers,
        Default = "Rain",
    })
    WeatherDepbox:AddSlider("WorldWeatherRate", {
        Text = "Rate",
        Default = 100,
        Min = 1,
        Max = 100,
        Rounding = 0,
        Suffix = "%",
    })
    WeatherDepbox:SetupDependencies({
        {Toggles.WorldWeather, true},
    })

    WeatherGroup:AddDivider()

    WeatherGroup:AddToggle("WorldNoise", {Text = "Background Noise", Default = false})
    local NoiseDepbox = WeatherGroup:AddDependencyBox()
    NoiseDepbox:AddDropdown("WorldNoiseSound", {
        Text = "Sound",
        Values = world_fx.sounds,
        Default = "Night",
    })
    NoiseDepbox:AddSlider("WorldNoiseVolume", {
        Text = "Volume",
        Default = 25,
        Min = 0,
        Max = 100,
        Rounding = 0,
        Suffix = "%",
    })
    NoiseDepbox:SetupDependencies({
        {Toggles.WorldNoise, true},
    })

    local HealGroup = Tabs.Misc:AddLeftGroupbox("Auto Heal")

    HealGroup:AddToggle("AutoHeal", {
        Text = "Auto Heal",
        Default = false,
    })
    HealGroup:AddDropdown("HealItems", {
        Text = "Heal Items (Multi)",
        Values = heal_choices,
        Default = table.find(heal_choices, "BandagesDX") and {"BandagesDX"} or 1,
        Multi = true,
    })
    HealGroup:AddSlider("HealBelow", {
        Text = "Heal Below",
        Default = 50,
        Min = 5,
        Max = 99,
        Rounding = 0,
        Suffix = " HP",
    })

    local LootGroup = Tabs.Misc:AddLeftGroupbox("Loot")

    LootGroup:AddToggle("AutoPickup", {
        Text = "Auto Pickup",
        Default = false,
    })
    LootGroup:AddToggle("InstantPickup", {
        Text = "Instant Pickup",
        Default = false,
    })

    local UndergroundGroup = Tabs.Misc:AddLeftGroupbox("Underground")

    UndergroundGroup:AddToggle("Underground", {
        Text = "Underground (RISK KICK)",
        Default = false,
    }):AddKeyPicker("UndergroundKey", {
        Default = "None",
        Mode = "Toggle",
        Modes = {"Toggle", "Hold", "Always"},
        Text = "Underground",
    })
    UndergroundGroup:AddSlider("UndergroundDepth", {
        Text = "Depth",
        Default = 10,
        Min = 5,
        Max = 50,
        Rounding = 0,
        Suffix = " studs",
    })
    UndergroundGroup:AddToggle("UndergroundProne", {
        Text = "Lie Down",
        Default = true,
    })
    UndergroundGroup:AddSlider("UndergroundMaxUnder", {
        Text = "Max Under",
        Default = 4,
        Min = 1,
        Max = 30,
        Rounding = 1,
        Suffix = "s",
    })
    UndergroundGroup:AddSlider("UndergroundSurface", {
        Text = "Surface Time",
        Default = 1.5,
        Min = 0.5,
        Max = 5,
        Rounding = 1,
        Suffix = "s",
    })

    local WallGroup = Tabs.Misc:AddRightGroupbox("Auto Wall")

    WallGroup:AddToggle("AutoWall", {
        Text = "Auto Wall",
        Default = false,
    })
    WallGroup:AddDropdown("AutoWallItem", {
        Text = "Shield",
        Values = {"Any", "Riot Shield", "Wood Shield Bar"},
        Default = 1,
    })
    WallGroup:AddSlider("AutoWallCooldown", {
        Text = "Cooldown",
        Default = 4,
        Min = 1,
        Max = 15,
        Rounding = 0,
        Suffix = "s",
    })

    local AntiAimGroup = Tabs.Misc:AddRightGroupbox("Anti Aim")

    AntiAimGroup:AddToggle("AntiAim", {
        Text = "Anti Aim",
        Default = false,
    }):AddKeyPicker("AntiAimKey", {
        Default = "None",
        SyncToggleState = true,
        Mode = "Toggle",
        Text = "Anti Aim",
    })
    AntiAimGroup:AddToggle("AntiAimVisualize", {
        Text = "Show On Self",
        Default = true,
    })
    AntiAimGroup:AddDropdown("AntiAimYaw", {
        Text = "Yaw",
        Values = {"Spin", "Jitter", "Static", "None"},
        Default = 1,
    })
    AntiAimGroup:AddDropdown("AntiAimPitch", {
        Text = "Pitch",
        Values = {"None", "Down", "Up", "Zero", "Jitter"},
        Default = 1,
    })
    AntiAimGroup:AddSlider("AntiAimSpeed", {
        Text = "Spin Speed",
        Default = 20,
        Min = 1,
        Max = 60,
        Rounding = 0,
        Suffix = "°",
    })
    AntiAimGroup:AddSlider("AntiAimJitter", {
        Text = "Jitter Angle",
        Default = 35,
        Min = 1,
        Max = 180,
        Rounding = 0,
        Suffix = "°",
    })
    AntiAimGroup:AddSlider("AntiAimStatic", {
        Text = "Static Yaw",
        Default = 180,
        Min = 0,
        Max = 360,
        Rounding = 0,
        Suffix = "°",
    })

    local function bind(flag, apply)
        local object = Toggles[flag] or Options[flag]
        object:OnChanged(function()
            apply(object.Value)
        end)
    end

    bind("SilentAimEnabled", function(value) config.enabled = value end)
    Options.SilentAimKey:OnClick(function(toggled)
        if Options.SilentAimKey.Mode == "Toggle" then
            Toggles.SilentAimEnabled:SetValue(toggled)
        end
    end)
    bind("SilentAimHitParts", function(value)
        config.hit_parts = value
        rebuild_hit_parts()
    end)
    bind("SilentAimHitMode", function(value) config.hit_mode = value end)
    bind("SilentAimPrediction", function(value) config.prediction = value end)
    bind("SilentAimDrop", function(value) config.drop = value end)
    bind("SilentAimLookSpoof", function(value) config.look_spoof = value end)
    bind("SilentAimMaxDistance", function(value) config.max_distance = value end)
    bind("SilentAimWallCheck", function(value) config.wallcheck = value end)
    bind("SilentAimTeamCheck", function(value) config.teamcheck = value end)
    bind("SilentAimClanCheck", function(value) config.clancheck = value end)
    bind("SilentAimProtectCheck", function(value) config.protect_check = value end)
    local function refresh_whitelist()
        local dropdown = Options.SilentAimWhitelist
        local search = string.lower(Options.WhitelistSearch.Value or "")
        local names = {}
        for _, player in Players:GetPlayers() do
            if player ~= localplayer then
                local name = player.Name
                if config.whitelist[name] then
                    dropdown.Value[name] = true
                end
                if dropdown.Value[name] or search == "" or string.find(string.lower(name), search, 1, true)
                    or string.find(string.lower(player.DisplayName), search, 1, true) then
                    table.insert(names, name)
                end
            end
        end
        table.sort(names, function(a, b)
            local picked_a, picked_b = dropdown.Value[a] == true, dropdown.Value[b] == true
            if picked_a ~= picked_b then
                return picked_a
            end
            return string.lower(a) < string.lower(b)
        end)
        dropdown:SetValues(names)
    end
    bind("SilentAimWhitelist", function(value)
        for _, player in Players:GetPlayers() do
            config.whitelist[player.Name] = value[player.Name] == true or nil
        end
    end)
    Options.WhitelistSearch:OnChanged(refresh_whitelist)
    for _, signal in {Players.PlayerAdded, Players.PlayerRemoving} do
        Library:GiveSignal(signal:Connect(function()
            task.delay(0.1, refresh_whitelist)
        end))
    end
    bind("ShowFOV", function(value) config.show_fov = value end)
    bind("FOVColor", function(value) config.fov_color = value end)
    bind("FOVRadius", function(value) config.fov = value end)
    bind("ShowTarget", function(value) config.show_target = value end)
    bind("TargetDotColor", function(value) config.target_dot_color = value end)
    bind("TargetTracer", function(value) config.target_tracer = value end)
    bind("TargetTracerColor", function(value) config.target_tracer_color = value end)
    bind("BulletTracer", function(value) config.bullet_tracer = value end)
    bind("BulletTracerColor", function(value)
        config.bullet_tracer_color = value
        config.bullet_tracer_alpha = Options.BulletTracerColor.Transparency
    end)
    bind("BulletTracerType", function(value)
        config.bullet_tracer_type = value
        tracer_is_beam.Value = value == "Beam"
        Library:UpdateDependencyBoxes()
    end)
    bind("BulletTracerStyle", function(value) config.bullet_tracer_style = value end)
    bind("BulletTracerGradient", function(value)
        config.bullet_tracer_gradient = value
        config.bullet_tracer_gradient_alpha = Options.BulletTracerGradient.Transparency
    end)
    bind("BulletTracerOutline", function(value)
        config.bullet_tracer_outline = value
        config.bullet_tracer_outline_alpha = Options.BulletTracerOutline.Transparency
    end)
    bind("BulletTracerTime", function(value) config.bullet_tracer_time = value end)
    bind("Aimbot", function(value) config.aimbot = value end)
    Options.AimbotKey:OnClick(function(toggled)
        if Options.AimbotKey.Mode == "Toggle" then
            Toggles.Aimbot:SetValue(toggled)
        end
    end)
    bind("AimbotSticky", function(value) config.aimbot_sticky = value end)
    bind("AimbotPart", function(value) config.aimbot_part = value end)
    bind("AimbotSmooth", function(value) config.aimbot_smooth = value end)
    bind("AimbotPrediction", function(value) config.aimbot_prediction = value end)
    bind("AimbotWallCheck", function(value) config.aimbot_wallcheck = value end)
    bind("AimbotShowFOV", function(value) config.aimbot_show_fov = value end)
    bind("AimbotFOVColor", function(value) config.aimbot_fov_color = value end)
    bind("AimbotFOV", function(value) config.aimbot_fov = value end)
    bind("NoSpread", function(value) config.no_spread = value end)
    bind("NoRecoil", function(value) config.no_recoil = value end)
    bind("AutoGun", function(value) config.auto_gun = value end)
    bind("AutoShoot", function(value) config.auto_shoot = value end)
    Options.AutoShootKey:OnClick(function(toggled)
        if Options.AutoShootKey.Mode == "Toggle" then
            Toggles.AutoShoot:SetValue(toggled)
        end
    end)
    bind("AutoReload", function(value) config.auto_reload = value end)
    bind("RapidFire", function(value) config.rapid_fire = value end)
    bind("RapidFireRate", function(value) config.rapid_fire_rate = value end)
    bind("MagicRadius", function(value) config.wallbang_radius = value end)
    bind("Wallbang", function(value) config.wallbang = value end)
    bind("AutoHeal", function(value) config.auto_heal = value end)
    bind("HealBelow", function(value) config.heal_below = value end)
    bind("HealItems", function(value) config.heal_items = value end)
    bind("Underground", function(value) config.underground = value end)
    bind("UndergroundDepth", function(value) config.underground_depth = value end)
    bind("UndergroundProne", function(value) config.underground_prone = value end)
    bind("UndergroundMaxUnder", function(value) config.underground_max_under = value end)
    bind("UndergroundSurface", function(value) config.underground_surface = value end)
    Options.UndergroundKey:OnClick(function(toggled)
        if Options.UndergroundKey.Mode == "Toggle" then
            Toggles.Underground:SetValue(toggled)
        end
    end)
    bind("AutoWall", function(value) config.auto_wall = value end)
    bind("AutoWallItem", function(value) config.wall_item = value end)
    bind("AutoWallCooldown", function(value) config.wall_cooldown = value end)
    bind("AntiAim", function(value)
        config.anti_aim = value
        if not value then
            aa_angle = 0
        end
    end)
    bind("AntiAimVisualize", function(value) config.aa_visualize = value end)
    bind("AntiAimYaw", function(value) config.aa_yaw = value end)
    bind("AntiAimPitch", function(value) config.aa_pitch = value end)
    bind("AntiAimSpeed", function(value) config.aa_speed = value end)
    bind("AntiAimJitter", function(value) config.aa_jitter = value end)
    bind("AntiAimStatic", function(value) config.aa_static = value end)
    bind("AutoPickup", function(value) config.auto_pickup = value end)
    bind("InstantPickup", function(value) config.instant_pickup = value end)

    bind("ESPEnabled", function(value) esp.enabled = value end)
    bind("ESPBox", function(value) esp.box = value end)
    bind("ESPName", function(value) esp.name = value end)
    bind("ESPNameMode", function(value) esp.name_mode = value end)
    bind("ESPHealth", function(value) esp.health = value end)
    bind("ESPDistance", function(value) esp.distance = value end)
    bind("ESPWeapon", function(value) esp.weapon = value end)
    bind("ESPTeamCheck", function(value) esp.teamcheck = value end)
    bind("ESPMaxDistance", function(value) esp.max_distance = value end)
    bind("ESPColor", function(value) esp.color = value end)
    bind("ESPTeamColor", function(value) esp.team_color = value end)
    bind("ESPTargetColor", function(value) esp.target_color = value end)
    bind("ESPTextSize", function(value) esp.text_size = value end)

    local world = config.world
    bind("WorldTime", function(value) world.time = value end)
    bind("WorldTimeValue", function(value) world.time_value = value end)
    bind("WorldLighting", function(value) world.lighting = value end)
    bind("WorldLightingMode", function(value) world.lighting_mode = value end)
    bind("WorldAmbient", function(value) world.ambient = value end)
    bind("WorldAmbientColor", function(value) world.ambient_color = value end)
    bind("WorldOutdoorColor", function(value) world.outdoor_color = value end)
    bind("WorldSaturation", function(value) world.saturation = value end)
    bind("WorldSaturationValue", function(value) world.saturation_value = value end)
    bind("WorldContrast", function(value) world.contrast = value end)
    bind("WorldContrastValue", function(value) world.contrast_value = value end)
    bind("WorldTint", function(value) world.tint = value end)
    bind("WorldTintColor", function(value) world.tint_color = value end)
    bind("WorldTextures", function(value) world.textures = value end)
    bind("WorldTexturePack", function(value) world.texture_pack = value end)
    bind("WorldSkybox", function(value) world.skybox = value end)
    bind("WorldSkyboxValue", function(value) world.skybox_value = value end)
    bind("WorldAtmosphere", function(value) world.atmosphere = value end)
    bind("WorldAtmosphereColor", function(value) world.atmosphere_color = value end)
    bind("WorldAtmosphereDecay", function(value) world.atmosphere_decay = value end)
    bind("WorldAtmosphereDensity", function(value) world.atmosphere_density = value end)
    bind("WorldAtmosphereOffset", function(value) world.atmosphere_offset = value end)
    bind("WorldAtmosphereHaze", function(value) world.atmosphere_haze = value end)
    bind("WorldAtmosphereGlare", function(value) world.atmosphere_glare = value end)
    bind("WorldWeather", function(value) world.weather = value end)
    bind("WorldWeatherColor", function(value) world.weather_color = value end)
    bind("WorldWeatherType", function(value) world.weather_type = value end)
    bind("WorldWeatherRate", function(value) world.weather_rate = value end)
    bind("WorldNoise", function(value) world.noise = value end)
    bind("WorldNoiseSound", function(value) world.noise_sound = value end)
    bind("WorldNoiseVolume", function(value) world.noise_volume = value end)

    local MenuGroup = Tabs["UI Settings"]:AddLeftGroupbox("Menu")

    MenuGroup:AddToggle("KeybindMenuOpen", {Default = Library.KeybindFrame.Visible, Text = "Open Keybind Menu", Callback = function(value) Library.KeybindFrame.Visible = value end})
    MenuGroup:AddDivider()
    MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", {Default = "RightShift", NoUI = true, Text = "Menu keybind"})
    MenuGroup:AddButton("Unload", function() Library:Unload() end)

    for _, option in Options do
        if type(option) == "table" and option.Type == "KeyPicker" then
            local previous = option.ChangedCallback
            option.ChangedCallback = function(...)
                if option.Value == "Escape" then
                    option:SetValue({"None", option.Mode})
                end
                if previous then
                    return previous(...)
                end
            end
        end
    end

    Library.ToggleKeybind = Options.MenuKeybind

    Library:OnUnload(function()
        hook_state.handler = nil
        warz_camera.ApplyRecoil = old_apply_recoil
        spread_module.ApplySpread = old_apply_spread
        if not table.isfrozen(solid_probe) then
            solid_probe.BarrelBuried = old_barrel_buried
        end
        loot_hold_module.Step = old_hold_step
        loot_hold_module.Reply = old_hold_reply
        clear_auto_jobs()
        pcall(RunService.UnbindFromRenderStep, RunService, AA_RESTORE_STEP)
        pcall(RunService.UnbindFromRenderStep, RunService, AA_VISUAL_STEP)
        pcall(RunService.UnbindFromRenderStep, RunService, AIMBOT_STEP)
        aim_circle:Remove()
        aa_restore()
        warz_camera.GetPitch = old_get_pitch
        if aa_forcing_move then
            localplayer:SetAttribute("CSGO_ForceMoveDir", nil)
        end
        combat_settings.IntervalFor = old_interval_for
        circle:Remove()
        dot:Remove()
        target_line:Remove()
        for _, tracer in shot_tracers do
            remove_tracer(tracer)
        end
        table.clear(shot_tracers)
        for player in esp_objects do
            remove_esp(player)
        end
        world_fx.unload()
        getgenv().__warz_unload = nil
        Library.Unloaded = true
    end)

    getgenv().__warz_unload = function()
        Library:Unload()
    end

    ThemeManager:SetLibrary(Library)
    SaveManager:SetLibrary(Library)
    SaveManager:IgnoreThemeSettings()
    SaveManager:SetIgnoreIndexes({"WhitelistSearch"})
    ThemeManager:SetFolder("WarZ PvP")
    SaveManager:SetFolder("WarZ PvP/main")
    SaveManager:BuildConfigSection(Tabs["UI Settings"])
    ThemeManager:ApplyToTab(Tabs["UI Settings"])
    SaveManager:LoadAutoloadConfig()
end

build_menu()
