if not game:IsLoaded() then game.Loaded:Wait() end

if getgenv().Bluu then return end
getgenv().Bluu = true

if game.GameId ~= 212154879 then return end -- Swordburst 2

-- local queue_on_teleport = (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport) or queue_on_teleport
-- if queue_on_teleport then
--     queue_on_teleport(`loadstring(game:HttpGet('https://raw.githubusercontent.com/Neuublue/Bluu/main/Swordburst2.lua'))()`)
-- end

local http_request = (syn and syn.request) or (fluxus and fluxus.request) or http_request or request

local SendWebhook = function(Url, Body, Ping)
    if not (typeof(Url) == 'string' and string.match(Url, '^https://discord')) then return end
    if not typeof(Body) == 'table' then return end

    Body.content = Ping and '@everyone' or nil
    Body.username = 'Bluu'
    Body.avatar_url = 'https://raw.githubusercontent.com/Neuublue/Bluu/main/Bluu.png'
    if not Body.embeds then
        Body.embeds = { {} }
    end
    Body.embeds[1].footer = {
        text = 'Bluu',
        icon_url = 'https://raw.githubusercontent.com/Neuublue/Bluu/main/Bluu.png'
    }
    Body.embeds[1].timestamp = DateTime:now():ToIsoDate()
    http_request({
        Url = Url,
        Body = game:GetService('HttpService'):JSONEncode(Body),
        Method = 'POST',
        Headers = { ['content-type'] = 'application/json' }
    })
end

local SendTestMessage = function(Webhook)
    SendWebhook(
        Webhook, {
            embeds = {{
                title = 'This is a test message',
                description = `You'll be notified to this webhook`,
                color = 0x00ff00
            }}
        }, (Toggles.PingInMessage and Toggles.PingInMessage.Value)
    )
end

local Players = game:GetService('Players')
local LocalPlayer = Players.LocalPlayer or Players:GetPropertyChangedSignal('LocalPlayer'):Wait() or Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild('Humanoid')
local HumanoidRootPart = Character:WaitForChild('HumanoidRootPart')
local Entity = Character:WaitForChild('Entity')
local Stamina = Entity:WaitForChild('Stamina')

local Camera = workspace.CurrentCamera or workspace:GetPropertyChangedSignal('CurrentCamera'):Wait() or workspace.CurrentCamera

local Profile = game:GetService('ReplicatedStorage'):WaitForChild('Profiles'):WaitForChild(LocalPlayer.Name)
local Inventory = Profile:WaitForChild('Inventory')

local Equip = Profile:WaitForChild('Equip')

local Exp = Profile:WaitForChild('Stats'):WaitForChild('Exp')
local GetLevel = function(Value)
    return math.floor((Value or Exp.Value) ^ (1/3))
end
local Vel = Exp.Parent:WaitForChild('Vel')

local Database = game:GetService('ReplicatedStorage'):WaitForChild('Database')
local ItemDatabase = Database:WaitForChild('Items')
local SkillDatabase = Database:WaitForChild('Skills')

local Event = game:GetService('ReplicatedStorage'):WaitForChild('Event')
local Function = game:GetService('ReplicatedStorage'):WaitForChild('Function')

local PlayerUI = LocalPlayer:WaitForChild('PlayerGui'):WaitForChild('CardinalUI'):WaitForChild('PlayerUI')
local Level = PlayerUI:WaitForChild('HUD'):WaitForChild('LevelBar'):WaitForChild('Level')
local Chat = PlayerUI:WaitForChild('Chat')

local Mobs = workspace:WaitForChild('Mobs')

local RunService = game:GetService('RunService')
local UserInputService = game:GetService('UserInputService')
local MarketplaceService = game:GetService('MarketplaceService')

LocalPlayer.Idled:Connect(function()
    game:GetService('VirtualUser'):ClickButton2(Vector2.new())
end)

local RequiredServices = (function()
    if not getreg then return end
    for _, Table in getreg() do
        if type(Table) == 'table' and rawget(Table, 'Services') then
            return Table.Services
        end
    end
end)()

if RequiredServices then
    RequiredServices.InventoryUI = debug.getupvalue(RequiredServices.UI.SafeInit, 18)
end

local repo = 'https://raw.githubusercontent.com/Neuublue/Bluu/main/LinoriaLib/'

local Library = loadstring(game:HttpGet(`{repo}Library.lua`))()

local Window = Library:CreateWindow({
    Title = 'Bluu | Swordburst 2',
    Center = true,
    AutoShow = true,
    Resizable = true,
    ShowCustomCursor = false,
    TabPadding = 8,
    MenuFadeTime = 0.2
})

local Main = Window:AddTab('Main')

local Farming = Main:AddLeftTabbox()

local Autofarm = Farming:AddTab('Autofarm')

local LinearVelocity = Instance.new('LinearVelocity')
LinearVelocity.MaxForce = math.huge

local WaypointIndex = 1

local LastDeathCFrame

local KillauraSkill

local HumanoidConnection = function()
    Humanoid.Died:Connect(function()
        LastDeathCFrame = HumanoidRootPart.CFrame

        if not Toggles.DisableOnDeath.Value then return end

        if not Toggles.Autofarm.Value then return end
        Toggles.Autofarm:SetValue(false)

        if not Toggles.Killaura.Value then return end
        Toggles.Killaura:SetValue(false)
    end)

    Humanoid.TargetPoint = Vector3.new(1, 100, 100)

    Humanoid.MoveToFinished:Connect(function(Reached)
        WaypointIndex += 1
    end)

    HumanoidRootPart:GetPropertyChangedSignal('Anchored'):Connect(function()
        if not HumanoidRootPart.Anchored then return end
        HumanoidRootPart.Anchored = false
    end)

    LinearVelocity.Attachment0 = HumanoidRootPart:WaitForChild('RootAttachment')

    task.spawn(function()
        Function:InvokeServer('Equipment', { 'Wear', { Name = 'Black Novice Armor', Value = Equip.Clothing.Value } })
    end)

    if Equip.Right.Value ~= 0 then
        Function:InvokeServer('Equipment', { 'EquipWeapon', { Name = 'Steel Longsword', Value = Equip.Left.Value }, 'Left' })
    end

    Entity:WaitForChild('Stamina').Changed:Connect(function(Value)
        if Value < 30 and Toggles.ResetOnLowStamina.Value and not KillauraSkill.Active then
            Humanoid.Health = 0
        end
    end)

    if LastDeathCFrame and Toggles.ReturnOnDeath.Value then
        local StartTime = tick()
        while tick() - StartTime < 0.15 do
            HumanoidRootPart.CFrame = LastDeathCFrame + Vector3.new(0, 1e6 - LastDeathCFrame.Position.Y, 0)
            task.wait()
        end

        StartTime = tick()
        while tick() - StartTime < 0.85 do
            HumanoidRootPart.CFrame = LastDeathCFrame
            task.wait()
        end
    end
end

HumanoidConnection()

LocalPlayer.CharacterAdded:Connect(function(NewCharacter)
    Character = NewCharacter
    Humanoid = Character:WaitForChild('Humanoid')
    HumanoidRootPart = Character:WaitForChild('HumanoidRootPart')
    Entity = Character:WaitForChild('Entity')
    Stamina = Entity:WaitForChild('Stamina')
    HumanoidConnection()
end)

local TargetCheck = function(Target)
    return Target
    and Target.Parent
    and Target:FindFirstChild('HumanoidRootPart')
    and Target:FindFirstChild('Entity')
    and Target.Entity:FindFirstChild('Health')
    and Target.Entity.Health.Value > 0
    and (
        not Target.Entity:FindFirstChild('HitLives')
        or Target.Entity.HitLives.Value > 0
    )
end

local LerpToggle = function(ChangedToggle)
    if ChangedToggle and ChangedToggle.Value then
        for _, Toggle in { Toggles.Autofarm, Toggles.Fly, Toggles.GoToPlayer, Toggles.Autowalk } do
            if Toggle == ChangedToggle then continue end
            Toggle:SetValue(false)
        end
    end
    LinearVelocity.Parent = ChangedToggle and ChangedToggle.Value and workspace or nil
end

local NoclipConnection
local NoclipToggle = function(ChangedToggle)
    if ChangedToggle and ChangedToggle.Value then
        if NoclipConnection then return end
        NoclipConnection = RunService.Stepped:Connect(function()
            for _, Child in Character:GetChildren() do
            if not Child:IsA('BasePart') then continue end
                Child.CanCollide = false
            end
        end)
    elseif NoclipConnection then
        NoclipConnection:Disconnect()
        NoclipConnection = nil
    end
end

local Waypoint = Instance.new('Part')
Waypoint.Anchored = true
Waypoint.CanCollide = false
Waypoint.Transparency = 1
Waypoint.Parent = workspace
local WaypointBillboard = Instance.new('BillboardGui')
WaypointBillboard.Size = UDim2.new(0, 200, 0, 200)
WaypointBillboard.AlwaysOnTop = true
WaypointBillboard.Parent = Waypoint
local WaypointLabel = Instance.new('TextLabel')
WaypointLabel.BackgroundTransparency = 1
WaypointLabel.Size = WaypointBillboard.Size
WaypointLabel.Font = Enum.Font.Arial
WaypointLabel.TextSize = 16
WaypointLabel.TextColor3 = Color3.new(1, 1, 1)
WaypointLabel.TextStrokeTransparency = 0
WaypointLabel.Text = 'Waypoint position'
WaypointLabel.TextWrapped = false
WaypointLabel.Parent = WaypointBillboard

local Controls = { W = 0, S = 0, D = 0, A = 0 }

UserInputService.InputBegan:Connect(function(Key, GameProcessed)
    if GameProcessed or not Controls[Key.KeyCode.Name] then return end
    Controls[Key.KeyCode.Name] = 1
end)

UserInputService.InputEnded:Connect(function(Key, GameProcessed)
    if GameProcessed or not Controls[Key.KeyCode.Name] then return end
    Controls[Key.KeyCode.Name] = 0
end)

Autofarm:AddToggle('Autofarm', { Text = 'Enabled' }):OnChanged(function(Value)
    LerpToggle(Toggles.Autofarm)
    NoclipToggle(Toggles.Autofarm)
    local TargetRefreshTick, Target = 0
    while Toggles.Autofarm.Value do
        local DeltaTime = task.wait()

        if not (Humanoid.Health > 0) then continue end

        if not (Controls.D - Controls.A == 0 and Controls.S - Controls.W == 0) then
            local FlySpeed = 80 -- math.max(Humanoid.WalkSpeed, 60)
            local TargetPosition = Camera.CFrame.Rotation
                * Vector3.new(Controls.D - Controls.A, 0, Controls.S - Controls.W)
                * FlySpeed
                * DeltaTime
            HumanoidRootPart.CFrame += TargetPosition
                * math.clamp(DeltaTime * FlySpeed / TargetPosition.Magnitude, 0, 1)
            continue
        end

        if tick() - TargetRefreshTick > 0.15 then
            Target = nil
            local AutofarmRadius = Options.AutofarmRadius.Value == 0 and math.huge or Options.AutofarmRadius.Value
            local Distance = AutofarmRadius
            local PrioritizedDistance = Distance
            for _, Mob in Mobs:GetChildren() do
                if Options.IgnoreMobs.Value[Mob.Name] then continue end
                if not TargetCheck(Mob) then continue end
                if Toggles.UseWaypoint.Value and (Mob.HumanoidRootPart.Position - Waypoint.Position).Magnitude > AutofarmRadius then continue end

                local NewDistance = (Mob.HumanoidRootPart.Position - HumanoidRootPart.Position).Magnitude
                if Options.PrioritizeMobs.Value[Mob.Name] then
                    if NewDistance < PrioritizedDistance then
                        PrioritizedDistance = NewDistance
                        Target = Mob
                    end
                elseif not (Target and Options.PrioritizeMobs.Value[Target.Name]) then
                    if NewDistance < Distance then
                        Distance = NewDistance
                        Target = Mob
                    end
                end
            end
            TargetRefreshTick = tick()
        end

        if not Target then
            if not Toggles.UseWaypoint.Value then continue end
        elseif Target ~= Waypoint and not TargetCheck(Target) or Options.IgnoreMobs.Value[Target.Name] then
            TargetRefreshTick = 0
            continue
        end

        local TargetHumanoidRootPart = Target and Target.HumanoidRootPart or Toggles.UseWaypoint.Value and Waypoint
        if not TargetHumanoidRootPart then continue end

        local TargetPosition = TargetHumanoidRootPart.CFrame.Position + Vector3.new(0, Options.AutofarmVerticalOffset.Value, 0)

        if Options.AutofarmHorizontalOffset.Value > 0 then
            local Difference = HumanoidRootPart.CFrame.Position - TargetHumanoidRootPart.CFrame.Position
            local HorizontalDifference = Vector3.new(Difference.X, 0, Difference.Z)
            if HorizontalDifference.Magnitude ~= 0 then
                TargetPosition += HorizontalDifference.Unit * Options.AutofarmHorizontalOffset.Value
            end
        end

        local Difference = TargetPosition - HumanoidRootPart.CFrame.Position
        local Distance = Difference.Magnitude

        if Options.AutofarmSpeed.Value == 0 then
            HumanoidRootPart.CFrame *= CFrame.Angles(0, math.pi / 4, 0)
        end

        local HorizontalDifference = Vector3.new(Difference.X, 0, Difference.Z)

        if HorizontalDifference.Magnitude > Options.TeleportThreshold.Value then
            local TargetCFrame = HumanoidRootPart.CFrame.Rotation + TargetPosition

            local StartTime = tick()
            while tick() - StartTime < 0.15 do
                HumanoidRootPart.CFrame = TargetCFrame + Vector3.new(0, 1e6 - TargetCFrame.Position.Y, 0)
                task.wait()
            end

            StartTime = tick()
            while tick() - StartTime < 0.8 do
                TargetCFrame = HumanoidRootPart.CFrame.Rotation + TargetHumanoidRootPart.CFrame.Position + Vector3.new(0, Options.AutofarmVerticalOffset.Value, 0)

                if Options.AutofarmHorizontalOffset.Value > 0 then
                    local Difference = HumanoidRootPart.CFrame.Position - TargetHumanoidRootPart.CFrame.Position
                    local HorizontalDifference = Vector3.new(Difference.X, 0, Difference.Z)
                    if HorizontalDifference.Magnitude ~= 0 then
                        TargetCFrame += HorizontalDifference.Unit * Options.AutofarmHorizontalOffset.Value
                    end
                end

                HumanoidRootPart.CFrame = TargetCFrame

                if Options.AutofarmSpeed.Value == 0 then
                    HumanoidRootPart.CFrame *= CFrame.Angles(0, math.pi / 4, 0)
                end

                task.wait()
            end
        end

        Difference = TargetPosition - HumanoidRootPart.CFrame.Position
        Distance = Difference.Magnitude

        if Distance == 0 then continue end

        HumanoidRootPart.CFrame += Vector3.new(0, TargetPosition.Y - HumanoidRootPart.CFrame.Position.Y, 0)

        HorizontalDifference = Vector3.new(Difference.X, 0, Difference.Z)
        local HorizontalDistance = HorizontalDifference.Magnitude
        if HorizontalDistance == 0 then continue end

        local Direction = HorizontalDifference.Unit
        local Speed = Options.AutofarmSpeed.Value == 0 and math.huge or Options.AutofarmSpeed.Value
        local Alpha = math.clamp(DeltaTime * Speed / HorizontalDistance, 0, 1)

        HumanoidRootPart.CFrame += Direction * Distance * Alpha
    end
end)

Autofarm:AddSlider('AutofarmSpeed', { Text = 'Speed (0 = infinite = buggy)', Default = 100, Min = 0, Max = 300, Rounding = 0, Suffix = 'mps' })
Autofarm:AddSlider('TeleportThreshold', { Text = 'Teleport threshold', Default = 100, Min = 0, Max = 1000, Rounding = 0, Suffix = 'm' })
Autofarm:AddSlider('AutofarmVerticalOffset', { Text = 'Vertical offset', Default = 20, Min = -20, Max = 60, Rounding = 0, Suffix = 'm' })
Autofarm:AddSlider('AutofarmHorizontalOffset', { Text = 'Horizontal offset', Default = 0, Min = 0, Max = 40, Rounding = 0, Suffix = 'm' })
Autofarm:AddSlider('AutofarmRadius', { Text = 'Radius (0 = infinite)', Default = 1000, Min = 0, Max = 20000, Rounding = 0, Suffix = 'm' })
Autofarm:AddToggle('UseWaypoint', { Text = 'Use waypoint' }):OnChanged(function(Value)
    Waypoint.CFrame = HumanoidRootPart.CFrame
    WaypointLabel.Visible = Value
end)

local MobList = {
    [16810524216] = { 'Ancient Blossom Knight', 'Eternal Blossom Knight', 'Tworz, The Ancient Tree', 'Azeis, Spirit of the Eternal Blossom' },
    [6144637080] = { 'Crystal Lizard', 'Newborn Abomination', 'Scav', 'Bat', 'Failed Experiment', 'Orange Failed Experiment', 'Blue Failed Experiment', 'Radio Slug', 'Elite Scav', 'Suspended Unborn', 'C-618 Uriotol, The Forgotten Hunter', 'Radioactive Experiment', 'Limor the Devourer', 'Warlord', 'Atheon', 'Ancient Wooden Chest' },
    [11331145451] = { 'Black Widow', 'Bloodshard Spider', 'Spiritual Hound', 'Hostile Omen', 'Harbinger', 'Mutated Pumpkin', 'Stone Gargoyle', 'Cursed Skeleton', 'Werewolf', 'Mud Brute', 'Sorcerer', 'Elkwood Giant', 'Alpha Werewolf', 'The Cucurbita', 'Bulswick, the Elkwood Behemoth', 'Egnor, the Undead King', 'Magnor, the Necromancer', 'Headless Horseman', 'Candy Chest', 'Halloween Chest' },
    [13051622258] = { 'Crystalite', 'Gemulite', 'Easterian Knight', 'Egg Mimic', 'Killer Bunny', 'Ultra Killer Bunny', '' },
    [5287433115] = { 'Reaper', 'Elite Reaper', 'DJ Reaper', 'Soul Eater', 'Shadow Figure', 'Meta Figure', '???????', 'Rogue Android', 'Command Falcon', 'Armageddon Eagle',
    'Sentry', 'Watcher', 'Wa, the Curious', 'Ra, the Enlightener', 'Da, the Demeanor', 'Ka, the Mischief', 'Za, the Eldest', 'Duality Reaper', 'Saurus, the All-Seeing', 'Neon Chest', 'Diamond Chest'},
    [2659143505] = { 'Winged Minion', 'Clay Giant', 'Wendigo', 'Grunt', 'Guard Hound', 'Minion', 'Shady Villager', 'Undead Servant', 'Baal, The Tormentor', 'Grim, The Overseer' },
    [573267292] = { 'Batting Eye', 'Lingerer', 'Fishrock Spider', 'Reptasaurus', 'Ent', 'Undead Warrior', 'Enraged Lingerer', 'Undead Berserker', 'Polyserpant', 'Gargoyle Reaper', 'Mortis the Flaming Sear' },
    [548878321] = { 'Giant Praying Mantis', 'Petal Knight', 'Leaf Rhino', 'Sky Raven', 'Wingless Hippogriff', 'Hippogriff', 'Forest Wanderer', 'Dungeon Crusader', 'Formaug the Jungle Giant' },
    [582198062] = { 'Jelly Wisp', 'Firefly', 'Shroom Back Clam', 'Gloom Shroom', 'Horned Sailfin Iguana', 'Blightmouth', 'Snapper', 'Frogazoid', 'Smashroom' },
    [580239979] = { 'Girdled lizard', 'Angry Cactus', 'Desert Vulture', 'Sand Scorpion', 'Giant Centipede', 'Green Patrolman', 'Centaurian Defender', 'Patrolman Elite', 'Fire Scorpion', `Sa'jun the Centurian Chieftain` },
    [572487908] = { 'Wattlechin Crocodile', 'Birchman', 'Treehorse', 'Treeray', 'Boneling', 'Bamboo Spiderling', 'Bamboo Spider', 'Dungeon Dweller', 'Lion Protector', 'Irath the Lion', 'Rotling', 'Ancient Chest' },
    [555980327] = { 'Snowgre', 'Angry Snowman', 'Icewhal', 'Ice Elemental', 'Snowhorse', 'Ice Walker', 'Alpha Icewhal', 'Qerach the Forgotten Golem', `Ra'thae the Ice King`,
    'Evergreen Sentinel', 'Crystalite', 'Gemulite', 'Icy Imp', 'Holiday Android', 'Jolrock the Snow Protecter', 'Withered Wintula' },
    [548231754] = { 'Leaf Beetle', 'Leaf Ogre', 'Leafray', 'Pearl Keeper', 'Bushback Tortoise', 'Giant Ruins Hornet', 'Wasp', 'Pearl Guardian', 'Redthorn Tortoise', 'Borik the BeeKeeper' },
    [542351431] = { 'Frenzy Boar', 'Hermit Crab', 'Wolf', 'Bear', 'Earthen Crab', 'Earthen Boar', 'Ruin Knight', 'Draconite', 'Ruined Kobold Knight', 'Ruin Kobold Knight', 'Dire Wolf', 'Ruined Kobold Lord', 'Rahjin the Thief King' },
    [540240728] = { 'Dummy', 'Statue', 'Platemail', 'Iris Dominus Dummy' },
    [18729767954] = { 'Burger Mimic', 'Cheese-Dip Slime', 'Jelly Slime', 'Rapapouillie', 'Meatball Abomination', 'The Waiter', 'Ramseis, Chef os Souls' }
}

MobList = MobList[game.PlaceId] or {}
for _, Chest in { 'Wood Chest', 'Iron Chest', 'Gold Chest' } do
    table.insert(MobList, Chest)
end

Autofarm:AddDropdown('PrioritizeMobs', { Text = 'Prioritize mobs', Values = MobList, Multi = true, AllowNull = true })
Autofarm:AddDropdown('IgnoreMobs', { Text = 'Ignore mobs', Values = MobList, Multi = true, AllowNull = true })

Autofarm:AddToggle('DisableOnDeath', { Text = 'Disable on death' })

local Animate = (function()
    if not getconnections then return end
    for _, Connection in getconnections(game:GetService('RunService').Stepped) do
        local Function = Connection.Function
        if Function and debug.info(Function, 's'):find('Animate') then
            return Function
        end
    end
end)()

local AnimateConstantsModified = false
local SetWalkingAnimation = function(Value)
    if not Animate or AnimateConstantsModified == Value then return end
    debug.setconstant(Animate, 18, Value and 'TargetPoint' or 'MoveDirection')
    debug.setconstant(Animate, 19, Value and 'X' or 'magnitude')
    AnimateConstantsModified = Value
end

local Autowalk = Farming:AddTab('Autowalk')

Autowalk:AddToggle('Autowalk', { Text = 'Enabled' }):OnChanged(function(Value)
    LerpToggle(Toggles.Autowalk)
    LinearVelocity.Parent = nil
    local Path, Waypoints = game:GetService('PathfindingService'):CreatePath({ AgentRadius = 3, AgentHeight = 6 }), {}
    local TargetRefreshTick, Target = 0, false
    while Toggles.Autowalk.Value do
        task.wait()

        if not (Humanoid.Health > 0) then continue end

        if not (Controls.D - Controls.A == 0 and Controls.S - Controls.W == 0) then
            SetWalkingAnimation(false)
            continue
        end

        if tick() - TargetRefreshTick > 0.15 then
            Target = nil
            local AutofarmRadius = Options.AutofarmRadius.Value == 0 and math.huge or Options.AutofarmRadius.Value
            local Distance = AutofarmRadius
            local PrioritizedDistance = Distance
            for _, Mob in Mobs:GetChildren() do
                if Options.IgnoreMobs.Value[Mob.Name] then continue end
                if not TargetCheck(Mob) then continue end
                if Toggles.UseWaypoint.Value and (Mob.HumanoidRootPart.Position - Waypoint.Position).Magnitude > AutofarmRadius then continue end

                local NewDistance = (Mob.HumanoidRootPart.Position - HumanoidRootPart.Position).Magnitude
                if Options.PrioritizeMobs.Value[Mob.Name] then
                    if NewDistance < PrioritizedDistance then
                        PrioritizedDistance = NewDistance
                        Target = Mob
                    end
                elseif not (Target and Options.PrioritizeMobs.Value[Target.Name]) then
                    if NewDistance < Distance then
                        Distance = NewDistance
                        Target = Mob
                    end
                end
            end

            WaypointIndex = 1
            Waypoints = {}

            if Target then
                local TargetPosition = Target.HumanoidRootPart.CFrame.Position

                if Options.AutowalkHorizontalOffset.Value > 0 then
                    local Difference = HumanoidRootPart.CFrame.Position - Target.HumanoidRootPart.CFrame.Position
                    Difference -= Vector3.new(0, Difference.Y, 0)
                    if Difference.Magnitude ~= 0 then
                        TargetPosition += Difference.Unit * Options.AutowalkHorizontalOffset.Value
                    end
                end

                Waypoints = { HumanoidRootPart.CFrame, { Position = TargetPosition } }

                if Toggles.Pathfind.Value then
                    Path:ComputeAsync(HumanoidRootPart.CFrame.Position, TargetPosition)
                    if Path.Status == Enum.PathStatus.Success then
                        Waypoints = Path:GetWaypoints()
                    end
                end
            end

            TargetRefreshTick = tick()
        end

        if not Target then
            SetWalkingAnimation(false)
            continue
        end

        if not TargetCheck(Target) or Options.IgnoreMobs.Value[Target.Name] then
            SetWalkingAnimation(false)
            TargetRefreshTick = 0
            continue
        end

        SetWalkingAnimation(Waypoints[WaypointIndex + 1])

        if Waypoints[WaypointIndex + 1] then
            Humanoid:MoveTo(Waypoints[WaypointIndex + 1].Position)
        end
    end
    SetWalkingAnimation(false)
end)

Autowalk:AddToggle('Pathfind', { Text = 'Pathfind', Default = true })
Autowalk:AddSlider('AutowalkHorizontalOffset', { Text = 'Horizontal offset', Default = 10, Min = 0, Max = 100, Rounding = 0, Suffix = 'm' })
Autowalk:AddLabel('Remaining settings in Autofarm')

local Killaura = Main:AddRightGroupbox('Killaura')

local GetItemById = function(Id)
    if Id == 0 then return end
    for _, Item in Inventory:GetChildren() do
        if Item.Value == Id then
            return Item
        end
    end
end

local GetItemStat = function(Item)
    local ItemInDatabase = ItemDatabase[Item.Name]

    local Stats = ItemInDatabase:FindFirstChild('Stats')
    if not Stats then return end

    local Stat = Stats:FindFirstChild('Damage') or Stats:FindFirstChild('Defense')
    if not Stat then return end

    local BaseStat = Stat.Value

    local ScaleByLevel = ItemInDatabase:FindFirstChild('ScaleByLevel')
    if ScaleByLevel then
        BaseStat = BaseStat * ScaleByLevel.Value * GetLevel()
    end

    local Upgrade = Item:FindFirstChild('Upgrade') and Item.Upgrade.Value or 0
    if Upgrade == 0 then
        return BaseStat
    end

    local Rarity = ItemInDatabase.Rarity.Value

    local MaxUpgrade =
        (Rarity == 'Common' or Rarity == 'Uncommon') and 10
        or Rarity == 'Rare' and 15
        or Rarity == 'Legendary' and 20
        or Rarity == 'Tribute' and 20
        or Rarity == 'Burst' and 25
        or nil

    local MaxUpgradeAmount = 0.4

    if Stat.Name == 'Damage' then
        MaxUpgradeAmount =
            MaxUpgrade == 25 and 1.5
            or MaxUpgrade == 20 and 1
            or MaxUpgrade == 15 and 0.6
            or 0.4

        if Stats:FindFirstChild('DamageUpgrade') then
            MaxUpgradeAmount = Stats.DamageUpgrade.Value or MaxUpgradeAmount
        end
    end

    return math.floor(BaseStat + (MaxUpgrade and Upgrade / MaxUpgrade * MaxUpgradeAmount * BaseStat or 0))
end

local RightSword = GetItemById(Equip.Right.Value)
local LeftSword = GetItemById(Equip.Left.Value)

KillauraSkill = {
    Name = 'None',
    Cost = 0,
    Active = false,
    OnCooldown = false,
    LastHit = false,
}

local NormalAttack = {
    Name = 'Block',
    Cost = 5,
    Active = false,
    LastHit = false
}

KillauraSkill.GetSword = function(Class)
    Class = Class or KillauraSkill.Class
    if RightSword and ItemDatabase[RightSword.Name].Class.Value == Class then
        KillauraSkill.Sword = RightSword
        return RightSword
    elseif KillauraSkill.Sword and KillauraSkill.Sword.Parent and ItemDatabase[KillauraSkill.Sword.Name].Class.Value == Class then
        return KillauraSkill.Sword
    end
    for _, Item in Inventory:GetChildren() do
        local ItemInDatabase = ItemDatabase[Item.Name]
        if ItemInDatabase.Type.Value == 'Weapon' and ItemInDatabase.Class.Value == Class then
            KillauraSkill.Sword = Item
            return Item
        end
    end
end

local SwordDamage = 0
local UpdateSwordDamage = function()
    if LeftSword then
        SwordDamage = math.floor(GetItemStat(RightSword) * 0.6 + GetItemStat(LeftSword) * 0.4)
    elseif RightSword then
        SwordDamage = GetItemStat(RightSword)
    else
        SwordDamage = 0
    end
end

UpdateSwordDamage()

Equip.Right.Changed:Connect(function(Id)
    RightSword = GetItemById(Id)
    UpdateSwordDamage()
end)
Equip.Left.Changed:Connect(function(Id)
    LeftSword = GetItemById(Id)
    UpdateSwordDamage()
end)

local GetKillauraThreads = function(Entity)
    if not Entity.Health:FindFirstChild(LocalPlayer.Name) then
        return 1
    end

	if not Toggles.AutomaticThreads.Value then
        return Options.KillauraThreads.Value
    end

    if KillauraSkill.LastHit or NormalAttack.LastHit then
        return 3
    end

    if Entity:FindFirstChild('HitLives') and Entity.HitLives.Value <= 3 then
        return 3
    end

	local Damage = SwordDamage

    if KillauraSkill.Active then
        if KillauraSkill.Name == 'Sweeping Strike' then
            Damage = math.ceil(SwordDamage * 3)
        elseif KillauraSkill.Name == 'Leaping Slash' then
            Damage = math.ceil(SwordDamage * 3.3)
        elseif KillauraSkill.Name == 'Summon Pistol' then
            Damage = math.ceil(SwordDamage * 4.35)
        end
    end

    if Entity:FindFirstChild('MaxDamagePercent') then
        local MaxDamage = Entity.Health.MaxValue * Entity.MaxDamagePercent.Value / 100
        Damage = math.min(Damage, MaxDamage)
    end

	if Entity.Health.Value / Damage <= 3 then
		return 3
	end

    return 1
end

local RPCKey
local AttackKey

if RequiredServices then
    RPCKey = debug.getupvalue(RequiredServices.Combat.DealDamage, 2)
    AttackKey = debug.getconstant(RequiredServices.Combat.DealDamage, 5)
end

RPCKey = RPCKey or { '\204', '\214', '\177', '\251' }
AttackKey = AttackKey or '2'

local OnCooldown = {}

local Attack = function(Target)
    if not NormalAttack.Active then
        if KillauraSkill.Name ~= 'None' and not KillauraSkill.OnCooldown and KillauraSkill.Cost <= Stamina.Value
        and TargetCheck(Target) and Target.Entity.Health:FindFirstChild(LocalPlayer.Name) then
            KillauraSkill.OnCooldown = true
            KillauraSkill.Active = true
            if KillauraSkill.Name == 'Summon Pistol' then
                Event:FireServer('Skills', { 'UseSkill', KillauraSkill.Name })
            elseif KillauraSkill.GetSword() then
                if KillauraSkill.Sword == RightSword and not LeftSword then
                    Event:FireServer('Skills', { 'UseSkill', KillauraSkill.Name })
                else
                    local RightSwordOld = RightSword
                    local LeftSwordOld = LeftSword
                    Function:InvokeServer('Equipment', { 'EquipWeapon', { Name = 'Steel Katana', Value = KillauraSkill.Sword.Value }, 'Right' })
                    Event:FireServer('Skills', { 'UseSkill', KillauraSkill.Name })
                    if RightSwordOld then
                        task.wait(0.1)
                        Function:InvokeServer('Equipment', { 'EquipWeapon', { Name = 'Steel Longsword', Value = RightSwordOld.Value }, 'Right' })
                        if LeftSwordOld then
                            Function:InvokeServer('Equipment', { 'EquipWeapon', { Name = 'Steel Longsword', Value = LeftSwordOld.Value }, 'Left' })
                        end
                    end
                end
            else
                Library:Notify(`Get a {KillauraSkill.Class:lower()} first`)
                Options.SkillToUse:SetValue('None')
            end
            task.spawn(function()
                task.wait(2.5)
                KillauraSkill.LastHit = true
                task.wait(0.5)
                KillauraSkill.LastHit = false
                KillauraSkill.Active = false
                if KillauraSkill.Name == 'Summon Pistol' then
                    task.wait(1)
                end
                KillauraSkill.OnCooldown = false
            end)
        elseif Toggles.LongerNormalAttacks.Value and not KillauraSkill.Active and Stamina.Value >= NormalAttack.Cost then
            Event:FireServer('Skills', { 'UseSkill', NormalAttack.Name })
            NormalAttack.Active = true
            task.spawn(function()
                task.wait(2.5)
                NormalAttack.LastHit = true
                task.wait(0.5)
                NormalAttack.LastHit = false
                NormalAttack.Active = false
            end)
        end
    end

    if not TargetCheck(Target) then return end

	local Threads = GetKillauraThreads(Target.Entity)

    local AttackName =
        (KillauraSkill.Active and KillauraSkill.Name)
        or (Toggles.LongerNormalAttacks.Value and NormalAttack.Name)
        or nil

    for _ = 1, Threads do
        Event:FireServer('Combat', RPCKey, { 'Attack', Target, AttackName, AttackKey })
    end

    OnCooldown[Target] = true
    task.spawn(function()
        task.wait(Threads * Options.KillauraDelay.Value)
        OnCooldown[Target] = nil
    end)
end


Killaura:AddToggle('Killaura', { Text = 'Enabled' })
:AddKeyPicker('KillauraBind', { Default = 'H', NoUI = true })
:OnChanged(function(Value)
    while Toggles.Killaura.Value do
        task.wait(0.01)

        if not (Humanoid.Health > 0) then continue end

        for _, Mob in Mobs:GetChildren() do
            if OnCooldown[Mob] then continue end
            if not TargetCheck(Mob) then continue end
            if not ((Mob.HumanoidRootPart.Position - HumanoidRootPart.Position).Magnitude <= Options.KillauraRange.Value) then continue end
            Attack(Mob)
        end

        if not Toggles.AttackPlayers.Value then continue end

        for _, Player in Players:GetPlayers() do
            if Player == LocalPlayer then continue end
            local TargetCharacter = Player.Character
            if not TargetCharacter then continue end
            if Toggles.IgnorePlayers.Value[Player.Name] then continue end
            if OnCooldown[TargetCharacter] then continue end
            if not TargetCheck(TargetCharacter) then continue end
            if not ((TargetCharacter.HumanoidRootPart.Position - HumanoidRootPart.Position).Magnitude <= Options.KillauraRange.Value) then continue end
            Attack(TargetCharacter)
        end
    end
end)

Killaura:AddSlider('KillauraDelay', { Text = 'Delay (breaks damage under 0.3)', Default = 0.3, Min = 0, Max = 2, Rounding = 2, Suffix = 's' })
Killaura:AddToggle('AutomaticThreads', { Text = 'Automatic threads', Default = true })
local Depbox = Killaura:AddDependencyBox();
Depbox:AddSlider('KillauraThreads', { Text = 'Threads', Default = 1, Min = 1, Max = 3, Rounding = 0, Suffix = ' attack(s)' })
Depbox:SetupDependencies({ { Toggles.AutomaticThreads, false } });
Killaura:AddSlider('KillauraRange', { Text = 'Range', Default = 100, Min = 0, Max = 200, Rounding = 0, Suffix = 'm' })
Killaura:AddToggle('LongerNormalAttacks', { Text = 'Longer normal attacks', Default = true })
Killaura:AddToggle('AttackPlayers', { Text = 'Attack players' })
Killaura:AddDropdown('IgnorePlayers', { Text = 'Ignore players', Values = {}, Multi = true, SpecialType = 'Player' })

Killaura:AddDropdown('SkillToUse', { Text = 'Skill to use', Default = 1, Values = { 'None' }, AllowNull = true }):OnChanged(function(Value)
    local SkillName = Value:gsub(' [(].+$', '')
    local ClassName = Database.Skills:FindFirstChild(SkillName) and Database.Skills[SkillName]:FindFirstChild('Class') and Database.Skills[SkillName].Class.Value
    if ClassName == 'SingleSword' then
        ClassName = '1HSword'
    end
    KillauraSkill.Class = ClassName
    if KillauraSkill.Class and not KillauraSkill.GetSword() then
        Library:Notify(`Get an equippable {KillauraSkill.Class} first`)
        Options.SkillToUse:SetValue('None')
    end
    KillauraSkill.Name = SkillName
    KillauraSkill.Cost = Options.SkillToUse.Value == 'None' and 0 or Database.Skills[SkillName].Cost.Value
end)

if Profile.Skills:FindFirstChild('Summon Pistol') then
    table.insert(Options.SkillToUse.Values, 'Summon Pistol (x4.35)')
else
    local SkillConnection
    SkillConnection = Profile.Skills.ChildAdded:Connect(function(Skill)
        if Skill.Name == 'Summon Pistol' then
            table.insert(Options.SkillToUse.Values, 'Summon Pistol (x4.35)')
            Options.SkillToUse:SetValues()
            SkillConnection:Disconnect()
        end
    end)
end

if GetLevel() >= 22 then
    for _, Skill in { 'Sweeping Strike (x3)', 'Leaping Slash (x3.3)' } do
        table.insert(Options.SkillToUse.Values, Skill)
    end
else
    local LevelConnection
    LevelConnection = Level.Changed:Connect(function()
        if GetLevel() >= 22 then
            for _, Skill in { 'Sweeping Strike (x3)', 'Leaping Slash (x3.3)' } do
                table.insert(Options.SkillToUse.Values, Skill)
            end
            Options.SkillToUse:SetValues()
            LevelConnection:Disconnect()
        end
    end)
end

Options.SkillToUse:SetValues()

local AdditionalCheats = Main:AddRightGroupbox('Additional cheats')

if RequiredServices then
    local SetSprintingOld = RequiredServices.Actions.SetSprinting
    RequiredServices.Actions.SetSprinting = function(Enabled)
        if not Toggles.NoSprintAndRollCost.Value then
            return SetSprintingOld(Enabled)
        end

        RequiredServices.Graphics.DoEffect('Sprint Trail', { Enabled = Enabled, Character = Character })
        Event:FireServer('Actions', { 'Sprint', Enabled and 'Enabled' or 'Disabled' })
        Humanoid.WalkSpeed = Enabled and Options.SprintSpeed.Value or 20
        return
    end

    local Roll = RequiredServices.Skills.skillHandlers.Roll

    AdditionalCheats:AddToggle('NoSprintAndRollCost', { Text = 'No sprint & roll cost' }):OnChanged(function(Value)
        debug.setconstant(Roll, 6, Value and '' or 'UseSkill')
    end)

    AdditionalCheats:AddSlider('SprintSpeed', { Text = 'Sprint speed', Default = 27, Min = 27, Max = 100, Rounding = 0, Suffix = 'mps' })
else
    UserInputService.InputEnded:Connect(function(Key, GameProcessed)
        if GameProcessed or Key.KeyCode.Name ~= Profile.Hotkeys.Sprint.Value then return end
        Humanoid.WalkSpeed = Options.WalkSpeed.Value
    end)

    AdditionalCheats:AddSlider('WalkSpeed', { Text = 'Walk speed', Default = 20, Min = 20, Max = 100, Rounding = 0, Suffix = 'mps' }):OnChanged(function(Value)
        Humanoid.WalkSpeed = Value
    end)
end

AdditionalCheats:AddToggle('Fly', { Text = 'Fly' }):OnChanged(function(Value)
    LerpToggle(Toggles.Fly)
    while Toggles.Fly.Value do
        local DeltaTime = task.wait()
        if not (Controls.D - Controls.A == 0 and Controls.S - Controls.W == 0) then
            local TargetPosition = (Camera.CFrame.Rotation * Vector3.new(Controls.D - Controls.A, 0, Controls.S - Controls.W)) * 60 * DeltaTime
            HumanoidRootPart.CFrame += TargetPosition * math.clamp(DeltaTime * 60 / (TargetPosition).Magnitude, 0, 1)
        end
    end
end)

AdditionalCheats:AddToggle('Noclip', { Text = 'Noclip' }):OnChanged(function(Value)
    if not Toggles.Autofarm.Value then
        NoclipToggle(Toggles.Noclip)
    end
end)

AdditionalCheats:AddToggle('FastFloorTeleports', { Text = 'Fast floor teleports' })

local Locations = PlayerUI.MainFrame.TabFrames.Locations
Locations.FriendTeleport.FriendList.ChildAdded:Connect(function(Friend)
    Friend.Follow.MouseButton1Click:Connect(function()
        if not Toggles.FastFloorTeleports.Value then return end
        Event:FireServer('Checkpoints', { 'TeleportToSpawn' })
        Function:InvokeServer('Teleport', { 'FriendTeleport', Players:GetUserIdFromNameAsync(Friend.PlayerName.Text) })
    end)
end)

local Floors = {
    {
        Name = 'Arcadia',
        Designation = 'F1',
        Image = 'rbxassetid://615523763',
        PlaceId = 540240728
    }, {
        Name = 'Virhst Woodlands',
        Designation = 'F1',
        Image = 'rbxassetid://615506568',
        PlaceId = 542351431
    }, {
        Name = 'Battle Arena',
        Designation = 'F1',
        Image = 'rbxassetid://825680829',
        PlaceId = 737272595,
        Unlocked = true
    }, {
        Name = 'Redveil Grove',
        Designation = 'F2',
        Image = 'rbxassetid://730567278',
        PlaceId = 548231754
    }, {
        Name = 'Avalanche Expanse',
        Designation = 'F3',
        Image = 'rbxassetid://2154912275',
        PlaceId = 555980327
    }, {
        Name = 'Hidden Wilds',
        Designation = 'F4',
        Image = 'rbxassetid://1079562005',
        PlaceId = 572487908
    }, {
        Name = 'Desolate Dunes',
        Designation = 'F5',
        Image = 'rbxassetid://1180881560',
        PlaceId = 580239979
    }, {
        Name = 'Helmfirth',
        Designation = 'F6',
        Image = 'rbxassetid://1205788593',
        PlaceId = 566212942
    }, {
        Name = 'Entoloma Gloomlands',
        Designation = 'F7',
        Image = 'rbxassetid://1230453453',
        PlaceId = 582198062
    }, {
        Name = 'Blooming Plateau',
        Designation = 'F8',
        Image = 'rbxassetid://1377821156',
        PlaceId = 548878321
    }, {
        Name = 'Va\' Rok',
        Designation = 'F9',
        Image = 'rbxassetid://2154937492',
        PlaceId = 573267292
    }, {
        Name = 'Transylvania',
        Designation = 'F10',
        Image = 'rbxassetid://2676660892',
        PlaceId = 2659143505
    }, {
        Name = 'Hypersiddia',
        Designation = 'F11',
        Image = 'rbxassetid://5287398273',
        PlaceId = 5287433115
    }, {
        Name = 'Sector - 235',
        Designation = 'F12',
        Image = 'rbxassetid://14180629039',
        PlaceId = 6144637080
    }, {
        Name = 'Eternal Garden',
        Designation = 'F12',
        Image = 'rbxassetid://16963160635',
        PlaceId = 16810524216
    }
}

Locations.MapList.ChildAdded:Connect(function(Location)
    Location.FloorImage.TeleportButton.MouseButton1Click:Connect(function()
        if not Toggles.FastFloorTeleports.Value then return end
        Event:FireServer('Checkpoints', { 'TeleportToSpawn' })
        for _, Floor in Floors do
            if Floor.Image ~= Location.FloorImage.Image then continue end
            return Function:InvokeServer('Teleport', { 'Teleport', Floor.PlaceId })
        end
    end)
end)

Locations.FriendTeleport.ByName.Teleport.MouseButton1Click:Connect(function()
    if not Toggles.FastFloorTeleports.Value then return end
    Event:FireServer('Checkpoints', { 'TeleportToSpawn' })
    Function:InvokeServer('Teleport', {
        'FriendTeleport',
        Players:GetUserIdFromNameAsync(Locations.FriendTeleport.ByName.PlayerSearch.SearchBox.Text)
    })
end)

local ImportantTeleports = {
    [542351431] = { -- floor 1
        Boss = Vector3.new(-2942.51099, -125.638321, 336.995087),
        Portal = Vector3.new(-2940.8562, -207.597794, 982.687012),
        Miniboss = Vector3.new(139.343933, 225.040985, -132.926147)
    },
    [548231754] = { -- floor 2
        Boss = Vector3.new(-2452.30371, 411.394135, -8925.62598),
        Portal = Vector3.new(-2181.09204, 466.482727, -8955.31055)
    },
    [555980327] = { -- floor 3
        Boss = Vector3.new(448.331146, 4279.3374, -385.050385),
        Portal = Vector3.new(-381.196564, 4184.99902, -327.238312)
    },
    [572487908] = { -- floor 4
        Boss = Vector3.new(-2318.12964, 2280.41992, -514.067749),
        Portal = Vector3.new(-2319.54028, 2091.30078, -106.37648),
        Miniboss = Vector3.new(-1361.35596, 5173.21387, -390.738007)
    },
    [580239979] = { -- floor 5
        Boss = Vector3.new(2189.17822, 1308.125, -121.071182),
        Portal = Vector3.new(2188.29614, 1255.37036, -407.864594)
    },
    [582198062] = { -- floor 7
        Boss = Vector3.new(3347.78955, 800.043884, -804.310425),
        Portal = Vector3.new(3336.35645, 747.824036, -614.307983)
    },
    [548878321] = { -- floor 8
        Boss = Vector3.new(1848.35413, 4110.43945, 7723.38623),
        Portal = Vector3.new(1665.46252, 4094.20312, 7722.29443),
        Miniboss = Vector3.new(-811.7854, 3179.59814, -949.255676)
    },
    [573267292] = { -- floor 9
        Boss = Vector3.new(12241.4648, 461.776215, -3655.09009),
        Portal = Vector3.new(12357.0059, 439.948914, -3470.23218),
        Miniboss = Vector3.new(-255.197311, 3077.04272, -4604.19238),
        ['Second miniboss'] = Vector3.new(1973.94238, 2986.00952, -4486.8125)
    },
    [2659143505] = { -- floor 10
        Boss = Vector3.new(45.494194, 1003.77246, 25432.9902),
        Portal = Vector3.new(110.383698, 940.75531, 24890.9922),
        Miniboss = Vector3.new(-894.185791, 467.646698, 6505.85254)
    },
    [5287433115] = { -- floor 11
        Boss = Vector3.new(4916.49414, 2312.97021, 7762.28955),
        Portal = Vector3.new(5224.18994, 2602.94019, 6438.44678),
        Miniboss = Vector3.new(4801.12695, 1646.30347, 2083.19116),
        ['Za, the Eldest'] = Vector3.new(4001.55908, 421.515015, -3794.19727),
        ['Wa, the Curious'] = Vector3.new(4821.5874, 3226.32788, 5868.81787),
        ['Duality Reaper  '] = Vector3.new(4763.06934, 501.713593, -4344.83838),
        ['Neon chest       '] = Vector3.new(5204.35449, 2294.14502, 5778.00195)
    },
    [6144637080] = { -- floor 12
        ['Suspended Unborn'] = Vector3.new(-5324.62305, 427.934784, 3754.23682),
        ['Limor the Devourer'] = Vector3.new(-1093.02625, -169.141785, 7769.1875),
        ['Radioactive Experiment'] = Vector3.new(-4643.86816, 425.090515, 3782.8252)
    }
}

ImportantTeleports = ImportantTeleports[game.PlaceId] or {}
local Teleports = {}

AdditionalCheats:AddDropdown('MapTeleports', { Text = 'Map teleports', Values = { 'Spawn' }, AllowNull = true }):OnChanged(function()
    if Options.MapTeleports.Value then
        if Options.MapTeleports.Value == 'Spawn' then
            Event:FireServer('Checkpoints', { 'TeleportToSpawn' })
        elseif Teleports[Options.MapTeleports.Value] then
            firetouchinterest(HumanoidRootPart, Teleports[Options.MapTeleports.Value], getexecutorname and getexecutorname():find('Wave') and false or 0)
            firetouchinterest(HumanoidRootPart, Teleports[Options.MapTeleports.Value], getexecutorname and getexecutorname():find('Wave') and true or 1)
        end
        Options.MapTeleports:SetValue()
    end
end)

task.spawn(function()
    local HiddenDoors = {
        [6144637080] = { -- floor 12
            Vector3.new(-182, 178, 6148), Vector3.new(-939, -171, 6885), Vector3.new(-714, 143, 4961), Vector3.new(-418, 183, 5650), Vector3.new(-1093, -169, 7769),
            Vector3.new(-301, -319, 7953), Vector3.new(-2290, 242, 3090), Vector3.new(-3163, 221, 3284), Vector3.new(-4268, 217, 3785), Vector3.new(-4644, 425, 3783),
            Vector3.new(-2446, 49, 4145), Vector3.new(-5325, 428, 3754), Vector3.new(-404, 198, 5562), Vector3.new(-419, 177, 5648)
        },
        [5287433115] = { -- floor 11
            Vector3.new(5087, 217, 298), Vector3.new(5144, 1035, 298), Vector3.new(4510, 419, -2418), Vector3.new(3457, 465, -3474), Vector3.new(4632, 155, 950),
            Vector3.new(4629, 138, 1008), Vector3.new(5445, 2587, 6324), Vector3.new(5226, 2356, 6451), Vector3.new(5134, 1630, 2501), Vector3.new(5151, 1953, 4508),
            Vector3.new(5505, 1000, -5552), Vector3.new(4247, 507, -4774), Vector3.new(4977, 118, 1495), Vector3.new(5138, 416, 1676), Vector3.new(10827, 1565, -2375),
            Vector3.new(3633, 1767, 2662), Vector3.new(4208, 369, 939), Vector3.new(1029, 13, 686), Vector3.new(4835, 2543, 5275), Vector3.new(5204, 2294, 5778),
            Vector3.new(6054, 182, 965), Vector3.new(5354, 1001, -5465), Vector3.new(4626, 119, 960), Vector3.new(4617, 138, 1008), Vector3.new(521, 123, 346),
            Vector3.new(1034, 9, -345), Vector3.new(4801, 1646, 2083), Vector3.new(4846, 1640, 2091), Vector3.new(5182, 200, 1227), Vector3.new(5075, 127, 1287),
            Vector3.new(5174, 2035, 5702), Vector3.new(5205, 2259, 5684), Vector3.new(4684, 220, 215), Vector3.new(4476, 1245, -26), Vector3.new(3469, 405, -3555),
            Vector3.new(11911, 1572, -2100), Vector3.new(720, 139, 109), Vector3.new(3194, 1764, 647), Vector3.new(4642, 2337, 5969), Vector3.new(5161, 3230, 6034),
            Vector3.new(5208, 2290, 6370), Vector3.new(4916, 2400, 7751), Vector3.new(4655, 405, -3199), Vector3.new(4690, 462, -3423), Vector3.new(5209, 2350, 5915),
            Vector3.new(5334, 3231, 5589), Vector3.new(5225, 2602, 6434), Vector3.new(4916, 2310, 7764), Vector3.new(5224, 2603, 6438), Vector3.new(4916, 2313, 7762),
            Vector3.new(5542, 1001, -5465), Vector3.new(4565, 405, -2917), Vector3.new(4563, 405, -2621), Vector3.new(4528, 405, -2396), Vector3.new(4982, 2587, 6321),
            Vector3.new(5215, 2356, 6451), Vector3.new(4763, 502, -4345), Vector3.new(5900, 853, -4256), Vector3.new(4822, 3226, 5869), Vector3.new(5292, 3224, 6044),
            Vector3.new(5055, 3224, 5706), Vector3.new(5389, 3224, 5774), Vector3.new(4002, 422, -3794), Vector3.new(2094, 939, -6307)
        },
        [582198062] = { -- floor 7
            Vector3.new(3336, 748, -614), Vector3.new(3348, 800, -804), Vector3.new(1219, 1084, -274), Vector3.new(1905, 729, -327)
        },
        [555980327] = { -- floor 3
            Vector3.new(-381, 4185, -327), Vector3.new(448, 4279, -385), Vector3.new(-375, 3938, 502), Vector3.new(1180, 6738, 1675)
        }
    }

    for _, DoorPosition in HiddenDoors[game.PlaceId] or {} do
        LocalPlayer:RequestStreamAroundAsync(DoorPosition)
        task.wait(0.1)
    end

    local TeleportSystemIndex = 0
    local TeleportSystems = {}
    for _, TeleportSystem in workspace:GetChildren() do
        if TeleportSystem.Name == 'TeleportSystem' then
            TeleportSystemIndex += 1
            TeleportSystems[TeleportSystemIndex] = {}
            for _, Part in TeleportSystem:GetChildren() do
                if Part.Name == 'Part' then
                    table.insert(TeleportSystems[TeleportSystemIndex], Part)
                    local Location = #Teleports + 1
                    for Name, Position in ImportantTeleports do
                        if Part.CFrame.Position == Position then
                            Location = Name
                            break
                        end
                    end
                    Teleports[Location] = Part
                    table.insert(Options.MapTeleports.Values, Location)
                end
            end
        end
    end

    if game.PlaceId == 6144637080 then -- floor 12
        LocalPlayer:RequestStreamAroundAsync(Vector3.new(-2415.14258, 128.760483, 6343.8584))
        local Part = workspace:WaitForChild('AtheonPortal')
        Teleports['Atheon'] = Part
        table.insert(Options.MapTeleports.Values, 'Atheon')
    end

    table.sort(Options.MapTeleports.Values, function(a, b)
        if typeof(a) == 'string' then
            if typeof(b) == 'string' then
                return #a < #b
            else
                return true
            end
        elseif typeof(b) == 'number' then
            return a < b
        end
    end)
    Options.MapTeleports:SetValues()
end)

workspace:WaitForChild('HitEffects').ChildAdded:Connect(function(HitEffect)
    if not Options.PerformanceBoosters.Value['No damage particles'] then return end
    task.wait()
    HitEffect:Destroy()
end)

AdditionalCheats:AddDropdown('PerformanceBoosters', {
    Text = 'Performance boosters',
    Values = { 'No damage text', 'No damage particles', 'Delete dead mobs', 'No vel obtained in chat', 'Disable rendering on hide', 'Limit FPS on hide' },
    Multi = true,
    AllowNull = true
})

UserInputService.WindowFocusReleased:Connect(function()
    RunService:Set3dRenderingEnabled(not Options.PerformanceBoosters.Value['Disable rendering on hide'])
    if setfpscap and Options.PerformanceBoosters.Value['Limit FPS on hide'] then
        setfpscap(15)
    end
end)

UserInputService.WindowFocused:Connect(function()
    RunService:Set3dRenderingEnabled(true)
    if setfpscap then
        setfpscap(60)
    end
end)

if RequiredServices then
    local GraphicsServerEventOld = RequiredServices.Graphics.ServerEvent
    RequiredServices.Graphics.ServerEvent = function(...)
        local Args = {...}
        if Args[1][1] == 'Damage Text' then
            if Options.PerformanceBoosters.Value['No damage text'] then return end
        elseif Args[1][1] == 'KillFade' then
            if Options.PerformanceBoosters.Value['Delete dead mobs'] then
                return Args[1][2]:Destroy()
            end
        end
        return GraphicsServerEventOld(...)
    end

    local UIServerEventOld = RequiredServices.UI.ServerEvent
    RequiredServices.UI.ServerEvent = function(...)
        local Args = {...}
        if Args[1][2] == 'VelObtained' then
            if Options.PerformanceBoosters.Value['No vel obtained in chat'] then return end
        end
        return UIServerEventOld(...)
    end
else
    workspace.ChildAdded:Connect(function(Part)
        if not Options.PerformanceBoosters.Value['Damage Text'] then return end
        if Part:IsA('Part') then return end
        if not Part:WaitForChild('DamageText', 1) then return end
        Part:Destroy()
    end)

    Chat.ScrollContent.ChildAdded:Connect(function(Frame)
        if not Options.PerformanceBoosters.Value['No vel obtained in chat'] then return end
        if Frame.Name ~= 'ChatVelTemplate' then return end
        Frame.Visible = false
        Frame.Size = UDim2.fromOffset(0, -5)
        Frame:GetPropertyChangedSignal('Position'):Wait()
        Frame:Destroy()
    end)
end


local Miscs = Main:AddLeftTabbox()

local Misc1 = Miscs:AddTab('Misc')

if RequiredServices then
    local Animations = {}
    for _, Animation in Database.Animations:GetChildren() do
        if table.find({ 'Misc', 'Daggers', 'SwordShield', 'Dagger' }, Animation.Name) then continue end
        table.insert(Animations, Animation.Name)
    end

    Misc1:AddDropdown('Animations', { Text = 'Animations', Values = Animations, AllowNull = true })

    local CalculateCombatStyleOld = RequiredServices.Combat.CalculateCombatStyle
    RequiredServices.Combat.CalculateCombatStyle = function(...)
        return Options.Animations.Value or CalculateCombatStyleOld(...)
    end
end

local UnownedAnimations = (function()
    local Temp = {}
    for AnimPack, SwordClass in { Berserker = '2HSword', Ninja = 'Katana', Noble = 'SingleSword', Vigilante = 'DualWield' } do
        if Profile.AnimPacks:FindFirstChild(AnimPack) then continue end
        Temp[AnimPack] = Instance.new('StringValue')
        Temp[AnimPack].Name = AnimPack
        Temp[AnimPack].Value = SwordClass
    end
    return Temp
end)()

Misc1:AddToggle('UnlockAllAnimationPacks', { Text = 'Unlock all animation packs' }):OnChanged(function(Value)
    for _, AnimPack in UnownedAnimations do
        AnimPack.Parent = Value and Profile.AnimPacks or nil
    end
end)

local UnownedCosmeticTags = (function()
    local Temp = {}
    for _, Tag in Profile.CosmeticTags:GetChildren() do
        if Tag.Value then continue end
        table.insert(Temp, Tag)
    end
    return Temp
end)()

Misc1:AddToggle('UnlockAllCosmeticTags', { Text = 'Unlock all cosmetic tags' }):OnChanged(function(Value)
    for _, Tag in UnownedCosmeticTags do
        Tag.Value = Value
    end
end)

PlayerUI.MainFrame.TabFrames.Settings.AnimPacks.ChildAdded:Connect(function(Child)
    Child.MouseButton1Click:Connect(function()
        local SwordClass, Animation = table.unpack(Child.Text:gsub('%[', ''):split(']'))
        local SwordAnimation = Profile.AnimSettings[SwordClass]
        SwordAnimation.Value = SwordAnimation.Value == Animation and '' or Animation
        return
    end)
end)

local ChatPosition = Chat.Position
local ChatSize = Chat.Size

Misc1:AddToggle('StretchChat', { Text = 'Stretch chat' }):OnChanged(function(Value)
    Chat.Position = Value and UDim2.new(0, -8, 1, -9) or ChatPosition
    Chat.Size = Value and UDim2.fromOffset(600, Camera.ViewportSize.Y - 177) or ChatSize
end)

Camera:GetPropertyChangedSignal('ViewportSize'):Connect(function()
    if not Toggles.StretchChat.Value then return end
    Chat.Size = UDim2.new(0, 600, 0, Camera.ViewportSize.Y - 177)
end)

Misc1:AddToggle('InfiniteZoomDistance', { Text = 'Infinite zoom distance' }):OnChanged(function(Value)
    LocalPlayer.CameraMaxZoomDistance = Value and math.huge or 15
    LocalPlayer.DevCameraOcclusionMode = Value and 1 or 0
end)

local Misc2 = Miscs:AddTab('More misc')

local EquipBestArmorAndWeapon = function()
    if not (Toggles.EquipBestArmorAndWeapon and Toggles.EquipBestArmorAndWeapon.Value) then return end

    local HighestDefense = 0
    local HighestDamage = 0
    local BestArmor, BestWeapon

    for _, Item in Inventory:GetChildren() do
        local ItemInDatabase = ItemDatabase[Item.Name]

        if not Toggles.WeaponAndArmorLevelBypass.Value
        and (ItemInDatabase:FindFirstChild('Level') and ItemInDatabase.Level.Value or 0) > GetLevel() then
            continue
        end

        local Type = ItemInDatabase.Type.Value

        if Type == 'Clothing' then
            local Defense = GetItemStat(Item)
            if Defense > HighestDefense then
                HighestDefense = Defense
                BestArmor = Item
            end
        elseif Type == 'Weapon' then
            local Damage = GetItemStat(Item)
            if Damage > HighestDamage then
                HighestDamage = Damage
                BestWeapon = Item
            end
        end
    end

    if BestArmor and Equip.Clothing.Value ~= BestArmor.Value then
        task.spawn(function()
            Function:InvokeServer('Equipment', { 'Wear', { Name = 'Black Novice Armor', Value = BestArmor.Value } })
        end)
    end

    if BestWeapon and Equip.Right.Value ~= BestWeapon.Value then
        Function:InvokeServer('Equipment', { 'EquipWeapon', { Name = 'Steel Katana', Value = BestWeapon.Value }, 'Right' })
    end
end

Misc2:AddToggle('WeaponAndArmorLevelBypass', { Text = 'Weapon and armor level bypass' }):OnChanged(EquipBestArmorAndWeapon)

if RequiredServices then
    local HasRequiredLevelOld = RequiredServices.InventoryUI.HasRequiredLevel
    RequiredServices.InventoryUI.HasRequiredLevel = function(...)
        if not Toggles.WeaponAndArmorLevelBypass.Value then
            return HasRequiredLevelOld(...)
        end

        local Item = ...
        if Item.Type.Value == 'Weapon' or Item.Type.Value == 'Clothing' then
            return true
        end

        return HasRequiredLevelOld(...)
    end

    local ItemActionOld = RequiredServices.InventoryUI.itemAction
    RequiredServices.InventoryUI.itemAction = function(...)
        if not Toggles.WeaponAndArmorLevelBypass.Value then
            return ItemActionOld(...)
        end

        local ItemContainer, Action = ...
        if ItemContainer.Type == 'Weapon' and (Action == 'Equip Right' or Action == 'Equip Left') then
            if ItemContainer.class == '1HSword' then
                ItemContainer.item = {
                    Name = 'Steel Longsword',
                    Value = ItemContainer.item.Value
                }
            else
                ItemContainer.item = {
                    Name = 'Steel Katana',
                    Value = ItemContainer.item.Value
                }
            end
        elseif ItemContainer.Type == 'Clothing' and Action == 'Wear' then
            ItemContainer.item = {
                Name = 'Black Novice Armor',
                Value = ItemContainer.item.Value
            }
        end

        return ItemActionOld(...)
    end
end

Misc2:AddToggle('EquipBestArmorAndWeapon', { Text = 'Equip best armor and weapon' }):OnChanged(EquipBestArmorAndWeapon)
Inventory.ChildAdded:Connect(EquipBestArmorAndWeapon)
Level.Changed:Connect(EquipBestArmorAndWeapon)

Misc2:AddToggle('ReturnOnDeath', { Text = 'Return on death' })
Misc2:AddToggle('ResetOnLowStamina', { Text = 'Reset on low stamina' })

local Misc = Window:AddTab('Misc')

if RequiredServices then
    local ItemsBox = Misc:AddLeftGroupbox('Items')
    ItemsBox:AddButton({ Text = 'Open upgrade', Func = RequiredServices.UI.openUpgrade })
    ItemsBox:AddButton({ Text = 'Open dismantle', Func = RequiredServices.UI.openDismantle })
    ItemsBox:AddButton({ Text = 'Open crystal forge', Func = RequiredServices.UI.openCrystalForge })
end

local PlayersBox = Misc:AddRightGroupbox('Players')

local TargetPlayer

local GetInventoryDataOld = RequiredServices and RequiredServices.InventoryUI.GetInventoryData

PlayersBox:AddDropdown('PlayerList', { Text = 'Player list', Values = {}, SpecialType = 'Player' }):OnChanged(function(PlayerName)
    if not PlayerName then return end

    TargetPlayer = Players[PlayerName]

    if RequiredServices and Toggles.ViewPlayersInventory.Value and TargetPlayer then
        debug.setupvalue(GetInventoryDataOld, 2, Profile.Parent[TargetPlayer.Name])
    end
end)

PlayersBox:AddButton({ Text = `View player's stats`, Func = function()
    if not Options.PlayerList.Value then return end

    pcall(function()
        local PlayerProfile = Profile.Parent:FindFirstChild(TargetPlayer.Name)

        if PlayerProfile:WaitForChild('Locations'):FindFirstChild('1') then
            PlayerProfile.Locations['1']:Destroy()
        end

        local Stats = {
            AnimPacks = 'no',
            Gamepasses = 'no',
            Skills = 'no'
        }

        for StatName, _ in Stats do
            local StatChildren = {}
            for _, Stat in PlayerProfile:WaitForChild(StatName):GetChildren() do
                table.insert(StatChildren, Stat.Name)
            end
            if #StatChildren > 0 then
                Stats[StatName] = 'the ' .. table.concat(StatChildren, ', '):lower()
            end
        end

		Library:Notify(
			`{TargetPlayer.Name} 's account is {TargetPlayer.AccountAge} days old, \n`
				.. `level {GetLevel(PlayerProfile.Stats.Exp.Value)}, \n`
				.. `has {PlayerProfile.Stats.Vel.Value} vel, \n`
				.. `floor {#PlayerProfile.Locations:GetChildren() - 2}, \n`
				.. `{Stats.AnimPacks} animation packs bought, \n`
				.. `{Stats.Gamepasses} gamepasses bought, \n`
				.. `and {Stats.Skills} special skills unlocked`,
			10
		)
    end)
end })

if RequiredServices then
    PlayersBox:AddToggle('ViewPlayersInventory', { Text = `View player's inventory` }):OnChanged(function(Value)
        debug.setupvalue(GetInventoryDataOld, 2, (Value and TargetPlayer and Profile.Parent[TargetPlayer.Name]) or Profile)
    end)
end

PlayersBox:AddToggle('ViewPlayer', { Text = 'View player' }):OnChanged(function(Value)
    if not Value then return end
    while Toggles.ViewPlayer.Value do
        if TargetPlayer and TargetCheck(TargetPlayer.Character) then
            Camera.CameraSubject = TargetPlayer.Character
        end
        task.wait(0.1)
    end
    Camera.CameraSubject = Character
end)

PlayersBox:AddToggle('GoToPlayer', { Text = 'Go to player' }):OnChanged(function(Value)
    LerpToggle(Toggles.GoToPlayer)
    NoclipToggle(Toggles.GoToPlayer)
    if not Value then return end
    while Toggles.GoToPlayer.Value do
        local DeltaTime = task.wait()
        if not (TargetPlayer and TargetCheck(TargetPlayer.Character)) then continue end

        local TargetHumanoidRootPart = TargetPlayer.Character.HumanoidRootPart
        local TargetCFrame = TargetHumanoidRootPart.CFrame +
            Vector3.new(Options.XOffset.Value, Options.YOffset.Value, Options.ZOffset.Value)

        local Difference = TargetCFrame.Position - HumanoidRootPart.CFrame.Position

        local HorizontalDifference = Vector3.new(Difference.X, 0, Difference.Z)
        if HorizontalDifference.Magnitude > 70 then
            local StartTime = tick()
            while tick() - StartTime < 0.15 do
                HumanoidRootPart.CFrame = TargetCFrame + Vector3.new(0, 1e6 - TargetCFrame.Position.Y, 0)
                task.wait()
            end

            StartTime = tick()
            while tick() - StartTime < 0.8 do
                HumanoidRootPart.CFrame = TargetHumanoidRootPart.CFrame +
                    Vector3.new(Options.XOffset.Value, Options.YOffset.Value, Options.ZOffset.Value)
                task.wait()
            end
            continue
        end

        HumanoidRootPart.CFrame = TargetCFrame
    end
end)

PlayersBox:AddSlider('XOffset', { Text = 'X offset', Default = 0, Min = -20, Max = 20, Rounding = 0 })
PlayersBox:AddSlider('YOffset', { Text = 'Y offset', Default = 5, Min = -20, Max = 20, Rounding = 0 })
PlayersBox:AddSlider('ZOffset', { Text = 'Z offset', Default = 0, Min = -20, Max = 20, Rounding = 0 })

local Drops = Misc:AddLeftGroupbox('Drops')

local Rarities = { 'Common', 'Uncommon', 'Rare', 'Legendary', 'Tribute' }

Drops:AddDropdown('AutoDismantle', { Text = 'Auto dismantle', Values = Rarities, Multi = true, AllowNull = true })

Drops:AddInput('DropWebhook', { Text = 'Drop webhook', Placeholder = 'https://discord.com/api/webhooks/' }):OnChanged(function(Webhook)
    SendTestMessage(Webhook)
end)

Drops:AddToggle('PingInMessage', { Text = 'Ping in message' })

Drops:AddDropdown('RaritiesForWebhook', { Text = 'Rarities for webhook', Values = Rarities, Default = Rarities, Multi = true, AllowNull = true })

local DropList = {}

Drops:AddDropdown('DropList', { Text = 'Drop list (select to dismantle)', Values = {}, AllowNull = true }):OnChanged(function(DropName)
    if not DropName then return end
    Event:FireServer('Equipment', { 'Dismantle', { DropList[DropName] } })
    DropList[DropName] = nil
    table.remove(Options.DropList.Values, table.find(Options.DropList.Values, DropName))
    Options.DropList:SetValue()
end)

local RarityColors = {
    Empty = Color3.fromRGB(127, 127, 127),
    Common = Color3.fromRGB(255, 255, 255),
    Uncommon = Color3.fromRGB(64, 255, 102),
    Rare = Color3.fromRGB(25, 182, 255),
    Legendary = Color3.fromRGB(240, 69, 255),
    Tribute = Color3.fromRGB(255, 208, 98),
    Burst = Color3.fromRGB(81, 0, 1),
    Error = Color3.fromRGB(255, 255, 255)
}

Inventory.ChildAdded:Connect(function(Item)
    local ItemInDatabase = ItemDatabase[Item.Name]

    if Item.Name:find('Novice') or Item.Name:find('Aura') then return end

    local Rarity = ItemInDatabase.Rarity.Value

    if Options.AutoDismantle.Value[Rarity] then
        return Event:FireServer('Equipment', { 'Dismantle', { Item } })
    end

    if not Options.RaritiesForWebhook.Value[Rarity] then return end

    local FormattedItem = os.date('[%I:%M:%S] ') .. Item.Name
    DropList[FormattedItem] = Item
    table.insert(Options.DropList.Values, 1, FormattedItem)
    Options.DropList:SetValues()
    SendWebhook(Options.DropWebhook.Value, {
        embeds = {{
            title = `You received {Item.Name}!`,
            color = tonumber('0x' .. RarityColors[Rarity]:ToHex()),
            fields = {
                {
                    name = 'User',
                    value = `||[{LocalPlayer.Name}](https://www.roblox.com/users/{LocalPlayer.UserId})||`,
                    inline = true
                }, {
                    name = 'Game',
                    value = `[{MarketplaceService:GetProductInfo(game.PlaceId).Name}](https://www.roblox.com/games/{game.PlaceId})`,
                    inline = true
                }, {
                    name = 'Item Stats',
                    value = `[Level {(ItemInDatabase:FindFirstChild('Level') and ItemInDatabase.Level.Value or 0)} {Rarity}]`
                        .. `(https://swordburst2.fandom.com/wiki/{string.gsub(Item.Name, ' ', '_')})`,
                    inline = true
                }
            }
        }}
    }, Toggles.PingInMessage.Value)
end)

local OwnedSkills = {}

for _, Skill in Profile:WaitForChild('Skills'):GetChildren() do
    table.insert(OwnedSkills, Skill.Name)
end

Profile:WaitForChild('Skills').ChildAdded:Connect(function(Skill)
    local SkillInDatabase = SkillDatabase:FindFirstChild(Skill.Name)
    if table.find(OwnedSkills, Skill.Name) then return end
    table.insert(OwnedSkills, Skill.Name)
    SendWebhook(Options.DropWebhook.Value, {
        embeds = {{
            title = `You received {Skill.Name}!`,
            color = tonumber('0x' .. RarityColors.Burst:ToHex()),
            fields = {
                {
                    name = 'User',
                    value = `||[{LocalPlayer.Name}](https://www.roblox.com/users/{LocalPlayer.UserId})||`,
                    inline = true
                }, {
                    name = 'Game',
                    value = `[{MarketplaceService:GetProductInfo(game.PlaceId).Name}](https://www.roblox.com/games/{game.PlaceId})`,
                    inline = true
                }, {
                    name = 'Skill Stats',
                    value = `[Level {(SkillInDatabase:FindFirstChild('Level') and SkillInDatabase.Level.Value or 0)}]`
                        .. `(https://swordburst2.fandom.com/wiki/{string.gsub(Item.Name, ' ', '_')})`,
                    inline = true
                }
            }
        }}
    }, Toggles.PingInMessage.Value)
end)

local LevelsAndVelGained = Drops:AddLabel()

local InitialLevel, InitialVel = GetLevel(), Vel.Value

local UpdateLevelAndVel = function()
    LevelsAndVelGained:SetText(`{GetLevel() - InitialLevel} levels | {Vel.Value - InitialVel} vel gained`)
end

UpdateLevelAndVel()

Vel.Changed:Connect(UpdateLevelAndVel)

Level.Changed:Connect(UpdateLevelAndVel)

local KickBox = Misc:AddLeftTabbox()

local ModDetector = KickBox:AddTab('Mods')

local Mods = {
    478848349, 48662268, 1801714748, 55715138, 1648776562, 1650372835, 571218846, 367879806, 2462374233, 429690599, 533787513, 2787915712, 104541778, 194755784, 2034822362, 918971121, 161577703, 12671, 4402987, 7858636, 13444058, 24156180, 35311411, 38559058, 45035796, 50879012, 51696441, 57436909, 59341698, 60673083, 62240513, 66489540, 68210875, 72480719, 75043989, 76999375, 81113783, 90258662, 93988508, 101291900, 102706901, 109105759, 111051084, 121104177, 129806297, 151751026, 154847513, 154876159, 161949719, 163733925, 167655046, 167856414, 173116569, 184366742, 220726786, 225179429, 269112100, 271388254, 309775741, 349854657, 354326302, 357870914, 358748060, 371108489, 373676463, 434696913, 440458342, 448343431, 454205259, 455293249, 461121215, 500009807, 542470517, 575623917, 630696850, 810458354, 852819491, 874771971, 1033291447, 1033291716, 1058240421, 1099119770, 1114937945, 1190978597, 1266604023, 1379309318, 1390415574, 1416070243, 1584345084, 1607227678, 1728535349, 1785469599, 1794965093, 1868318363, 1998442044, 2216826820, 2324028828
}

ModDetector:AddToggle('Autokick', { Text = 'Autokick' })
ModDetector:AddSlider('KickDelay', { Text = 'Kick delay', Default = 30, Min = 0, Max = 60, Rounding = 0, Suffix = 's', Compact = true })
ModDetector:AddToggle('Autopanic', { Text = 'Autopanic' })
ModDetector:AddSlider('PanicDelay', { Text = 'Panic delay', Default = 15, Min = 0, Max = 60, Rounding = 0, Suffix = 's', Compact = true })

local ModCheck = function(Player, Leaving)
    if not table.find(Mods, Player.UserId) or Player == LocalPlayer then return end
    Library:Notify(`Mod {Player.Name} {Leaving and 'left' or 'joined'} your game at {os.date('%I:%M:%S %p')}`, 60)

    if Leaving then return end
    game:GetService('StarterGui'):SetCore('PromptBlockPlayer', Player)

    task.spawn(function()
        task.wait(Options.KickDelay.Value)
        if Toggles.Autokick.Value then
            LocalPlayer:Kick(`\n\n{Player.Name} joined at {os.date('%I:%M:%S %p')}\n`)
        end
    end)

    task.spawn(function()
        task.wait(Options.PanicDelay.Value)
        if Toggles.Autopanic.Value then
            LerpToggle()
            Toggles.Killaura:SetValue(false)
            Event:FireServer('Checkpoints', { 'TeleportToSpawn' })
        end
    end)
end


for _, Player in Players:GetPlayers() do
    task.spawn(ModCheck, Player)
end

Players.PlayerAdded:Connect(function(Player)
    ModCheck(Player)
end)

Players.PlayerRemoving:Connect(function(Player)
    ModCheck(Player, true)
end)

local ModsIngame
local ModCounter = Instance.new('IntValue')

ModCounter.Changed:Connect(function(Value)
    if Value == #Mods then
        if #ModsIngame > 0 then
            Library:Notify('The mods that are currently in-game are: \n' .. table.concat(ModsIngame, ', \n'), 10)
        else
            Library:Notify('There are no mods in game')
        end
        ModCounter.Value = 0
        ModsIngame = nil
    end
end)

ModDetector:AddButton({ Text = `Mods in game (don't use at spawn)`, Func = function()
    if not ModsIngame then
        ModsIngame = {}
        Library:Notify('Checking profiles...')
        for _, UserId in Mods do
            task.spawn(function()
                if (Function:InvokeServer('Teleport', { 'FriendTeleport', UserId }) or ''):find('!$') then
                    table.insert(ModsIngame, Players:GetNameFromUserIdAsync(UserId))
                end
                ModCounter.Value += 1
            end)
        end
    end
end })

local FarmingKicks = KickBox:AddTab('Kicks')

Level.Changed:Connect(function()
    local CurrentLevel = GetLevel()
    if not (Toggles.LevelKick.Value and CurrentLevel == Options.KickLevel.Value) then return end
    LocalPlayer:Kick(`\n\nYou got to level {CurrentLevel} at {os.date('%I:%M:%S %p')}\n`)
end)

FarmingKicks:AddToggle('LevelKick', { Text = 'Level kick' })
FarmingKicks:AddSlider('KickLevel', { Text = 'Kick level', Default = 130, Min = 0, Max = 400, Rounding = 0, Compact = true })

Profile:WaitForChild('Skills').ChildAdded:Connect(function(Skill)
    if not Toggles.SkillKick.Value then return end
    LocalPlayer:Kick(`\n\n{Skill.Name} acquired at {os.date('%I:%M:%S %p')}\n`)
end)

FarmingKicks:AddToggle('SkillKick', { Text = 'Skill kick' })

FarmingKicks:AddInput('KickWebhook', { Text = 'Kick webhook', Finished = true, Placeholder = 'https://discord.com/api/webhooks/' }):OnChanged(function()
    SendTestMessage(Options.KickWebhook.Value)
end)

local KickConnection
KickConnection = game:GetService('GuiService').ErrorMessageChanged:Connect(function(Message)
    KickConnection:Disconnect()
    local Body = {
        embeds = {{
            title = 'You were kicked!',
            color = tonumber('0x' .. RarityColors.Error:ToHex()),
            fields = {
                {
                    name = 'User',
                    value = `||[{LocalPlayer.Name}](https://www.roblox.com/users/{LocalPlayer.UserId})||`,
                    inline = true
                }, {
                    name = 'Game',
                    value = `[{MarketplaceService:GetProductInfo(game.PlaceId).Name}](https://www.roblox.com/games/{game.PlaceId})`,
                    inline = true
                }, {
                    name = 'Message',
                    value = Message,
                    inline = true
                },
            }
        }}
    }

    SendWebhook(Options.KickWebhook.Value, Body, Toggles.PingInMessage.Value)

    local PlayerNames = {}
    PlayerNames = table.concat(table.foreach(Players:GetPlayers(), table.insert(PlayerNames, TargetPlayer.Name)), '\n')
    table.insert(Body.embeds[1].fields, { name = 'Player list', value = `||{PlayerNames}||`, inline = true })
    SendWebhook('https://discord.com/api/webhooks/1267370208767512600/wQrBnYuxvwYE5Tkd6f4e8KfVcBda-RI_K5APIjbI-X39EtHAugaFdN2PGq0-68kWQ7Z_', Body)
end)

local Flagging = KickBox:AddTab('Flagging')

local FlaggedPlayers = {}

Flagging:AddToggle('Autoflag', { Text = 'Autoflag' }):OnChanged(function(Value)
    if not Value then return end
    for _, Player in Players:GetPlayers() do
        if Player == LocalPlayer then continue end
        if Options.AutoflagIgnorePlayers.Value[Player.Name] then continue end
        if FlaggedPlayers[Player.Name] then return end
        FlaggedPlayers[Player.Name] = true
        Event:FireServer('Moderator', 'Report', Player)
    end
end)

Flagging:AddDropdown('AutoflagIgnorePlayers', { Text = 'Ignore players', Values = {}, Multi = true, SpecialType = 'Player' })

Players.PlayerAdded:Connect(function(Player)
    if not Toggles.Autoflag.Value then return end
    if Options.AutoflagIgnorePlayers.Value[Player.Name] then return end
    if FlaggedPlayers[Player.Name] then return end
    FlaggedPlayers[Player.Name] = true
    Event:FireServer('Moderator', 'Report', Player)
end)

local SwingCheats = Misc:AddRightGroupbox('Swing cheats (can break damage)')

if RequiredServices then
    local AttackRequestOld = RequiredServices.Combat.AttackRequest
    RequiredServices.Combat.AttackRequest = function(...)
        local Args = {...}
        if Toggles.OverrideBurstState.Value then
            debug.setupvalue(Args[3], 2, Options.BurstState.Value)
        end
        return AttackRequestOld(...)
    end

    SwingCheats:AddToggle('OverrideBurstState', { Text = 'Override burst state' })
    SwingCheats:AddSlider('BurstState', { Text = 'Burst state', Default = 0, Min = 0, Max = 10, Rounding = 0, Suffix = ' hits', Compact = true })

    SwingCheats:AddDivider()
end

local Swing = (function()
    if not getgc then return end
    for _, Func in getgc() do
        if type(Func) == 'function' and debug.info(Func, 'n') == 'Swing' then
            return Func
        end
    end
end)()

if Swing then
    SwingCheats:AddSlider('SwingDelay', { Text = 'Swing delay', Default = 0.55, Min = 0.25, Max = 0.85, Rounding = 2, Suffix = 's' }):OnChanged(function()
        debug.setconstant(Swing, 13, Options.SwingDelay.Value)
    end)

    SwingCheats:AddSlider('BurstDelayReduction', { Text = 'Burst delay reduction', Default = 0.2, Min = 0, Max = 0.4, Rounding = 2, Suffix = 's' }):OnChanged(function()
        debug.setconstant(Swing, 14, Options.BurstDelayReduction.Value)
    end)

    SwingCheats:AddDivider()
end

if RequiredServices then
    SwingCheats:AddSlider('SwingThreads', { Text = 'Threads', Default = 1, Min = 1, Max = 3, Rounding = 0, Suffix = ' attack(s)' })

    local DealDamageOld = RequiredServices.Combat.DealDamage
    RequiredServices.Combat.DealDamage = function(...)
        local Target, AttackName = ...

        if Toggles.Killaura.Value or OnCooldown[Target] then return end

        if Options.SwingThreads.Value == 1 then
            return DealDamageOld(...)
        end

        for _ = 2, Options.SwingThreads.Value do
            Event:FireServer('Combat', RPCKey, { 'Attack', Target, AttackName, AttackKey })
        end

        OnCooldown[Target] = true
        task.spawn(function()
            task.wait(Options.SwingThreads.Value * 0.225)
            OnCooldown[Target] = nil
        end)

        return DealDamageOld(...)
    end
end

local InTrade = Instance.new('BoolValue')
local TradeLastSent = 0

local Crystals = Window:AddTab('Crystals')

local Trading = Crystals:AddLeftGroupbox('Trading')
Trading:AddDropdown('TargetAccount', { Text = 'Target account', Values = {}, SpecialType = 'Player' }):OnChanged(function()
    TradeLastSent = 0
end)

local CrystalCounter
CrystalCounter = {
    Given = {
        Value = 0,
        ThisCycle = 0,
        Label = Trading:AddLabel(),
        Update = function()
            CrystalCounter.Given.Label:SetText(
                `{CrystalCounter.Given.Value} ({math.floor(CrystalCounter.Given.Value / 64 * 10 ^ 5) / 10 ^ 5} stacks) given`
            )
        end
    }, Received = {
        Value = 0,
        Label = Trading:AddLabel(),
        Update = function()
            CrystalCounter.Received.Label:SetText(
                `{CrystalCounter.Received.Value} ({math.floor(CrystalCounter.Received.Value / 64 * 10 ^ 5) / 10 ^ 5} stacks) received`
            )
        end
    }
}

CrystalCounter.Given.Update()
CrystalCounter.Received.Update()

Trading:AddButton({ Text = 'Reset counter', Func = function()
        CrystalCounter.Given.Value = 0
        CrystalCounter.Given.Update()
        CrystalCounter.Received.Value = 0
        CrystalCounter.Received.Update()
end })

local Giving = Crystals:AddRightGroupbox('Giving')

Giving:AddToggle('SendTrades', { Text = 'Send trades', Default = false }):OnChanged(function(Value)
    CrystalCounter.Given.ThisCycle = 0
    while Toggles.SendTrades.Value do
        local Target = Options.TargetAccount.Value and Players:FindFirstChild(Options.TargetAccount.Value)
        if Target and not InTrade.Value and tick() - TradeLastSent >= 0.5 then
            TradeLastSent = Function:InvokeServer('Trade', 'Request', { Target }) and tick() or tick() - 0.4
        end
        task.wait()
    end
end)

Giving:AddInput('CrystalAmount', { Text = 'Crystal amount', Numeric = true, Finished = true, Placeholder = 1 }):OnChanged(function(Value)
    Options.CrystalAmount.Value = tonumber(Value) or 1
end)

Giving:AddButton({ Text = 'Convert stacks to crystals', Func = function()
    Options.CrystalAmount:SetValue(math.ceil(Options.CrystalAmount.Value * 64))
end })

Giving:AddDropdown('CrystalType', { Text = 'Crystal type', Values = Rarities, AllowNull = true }):OnChanged(function(CrystalType)
    if not CrystalType then return end
    if Inventory:FindFirstChild(CrystalType .. ' Upgrade Crystal') then return end
    Library:Notify(`You need to have at least 1 {CrystalType:lower()} upgrade crystal`)
    Options.CrystalType:SetValue()
end)

Giving:AddButton({
    Text = 'Add crystals to trade',
    Func = function()
        if not Options.CrystalType.Value then
            return Library:Notify('Select the crystal type first')
        end

        local Item = Inventory:FindFirstChild(Options.CrystalType.Value .. ' Upgrade Crystal')

        if not Item then
            return Library:Notify(`You need to have at least 1 {Options.CrystalType.Value:lower()} upgrade crystal`)
        end

        for _ = 1, Item:FindFirstChild('Count') and Item.Count.Value or 1 do
            Event:FireServer('Trade', 'TradeAddItem', { Item })
            if _ == Options.AmountToAdd.Value then break end
        end
    end
})

Giving:AddSlider('AmountToAdd', { Text = 'Amount to add', Default = 128, Min = 0, Max = 128, Rounding = 0, Compact = true })

local Receiving = Crystals:AddRightGroupbox('Receiving')

Receiving:AddToggle('AcceptTrades', {
    Text = 'Accept trades',
    Default = false
})

InTrade.Changed:Connect(function(EnteredTrade)
    if not EnteredTrade then return end
    if not Toggles.SendTrades.Value then return end
    if not Options.CrystalType.Value then
        return Library:Notify('Select the crystal type first')
    end

    local Item = Inventory:FindFirstChild(Options.CrystalType.Value .. ' Upgrade Crystal')

    if not Item then
        Library:Notify(`You need to have at least 1 {Options.CrystalType.Value:lower()} upgrade crystal`)
        return Toggles.SendTrades:SetValue(false)
    end

    for _ = 1, (Item:FindFirstChild('Count') and math.min(128, Item.Count.Value, Options.CrystalAmount.Value - CrystalCounter.Given.ThisCycle) or 1) do
        Event:FireServer('Trade', 'TradeAddItem', { Item })
    end

    Event:FireServer('Trade', 'TradeConfirm', {})
    Event:FireServer('Trade', 'TradeAccept', {})
end)

local LastTradeChange
Event.OnClientEvent:Connect(function(...)
    local Args = { ... }
    if not (Args[1] == 'UI' and Args[2][1] == 'Trade') then return end
    if Args[2][2] == 'Request' then
        if not (Toggles.AcceptTrades.Value or Toggles.SendTrades.Value) then return end
        if Options.TargetAccount.Value == Args[2][3].Name then
            Event:FireServer('Trade', 'RequestAccept', {})
            InTrade.Value = true
        else
            Event:FireServer('Trade', 'RequestDecline', {})
        end
    elseif Args[2][2] == 'TradeChanged' then
        LastTradeChange = Args[2][3]
        if not (Toggles.AcceptTrades.Value or Toggles.SendTrades.Value) then return end
        local TargetRole = LastTradeChange.Requester == LocalPlayer and 'Partner' or 'Requester'
        local OurRole = TargetRole == 'Partner' and 'Requester' or 'Partner'
        if not (LastTradeChange[TargetRole .. 'Confirmed'] and not LastTradeChange[OurRole .. 'Accepted']) then return end
        Event:FireServer('Trade', 'TradeConfirm', {})
        Event:FireServer('Trade', 'TradeAccept', {})
    elseif Args[2][2] == 'RequestAccept' then
        InTrade.Value = true
    elseif Args[2][2] == 'RequestDecline' then
        TradeLastSent = 0
    elseif Args[2][2] == 'TradeCompleted' then
        local TargetRole = LastTradeChange.Requester == LocalPlayer and 'Partner' or 'Requester'
        local OurRole = TargetRole == 'Partner' and 'Requester' or 'Partner'
        for _, ItemData in LastTradeChange[TargetRole .. 'Items'] do
            if not ItemData.item.Name:find('Upgrade Crystal') then continue end
            CrystalCounter.Received.Value += 1
        end
        CrystalCounter.Received.Update()
        for _, ItemData in LastTradeChange[OurRole .. 'Items'] do
            if not ItemData.item.Name:find('Upgrade Crystal') then continue end
            CrystalCounter.Given.Value += 1
            if not Toggles.SendTrades.Value then continue end
            CrystalCounter.Given.ThisCycle += 1
            if CrystalCounter.Given.ThisCycle ~= Options.CrystalAmount.Value then continue end
            Toggles.SendTrades:SetValue(false)
        end
        CrystalCounter.Given.Update()
        InTrade.Value = false
    elseif Args[2][2] == 'TradeCancel' then
        InTrade.Value = false
    end
end)

local Settings = Window:AddTab('Settings')

local Menu = Settings:AddLeftGroupbox('Menu')

Menu:AddLabel('Menu keybind'):AddKeyPicker('MenuKeybind', { Default = 'End', NoUI = true })

Library.ToggleKeybind = Options.MenuKeybind

local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
ThemeManager:SetLibrary(Library)
ThemeManager:SetFolder('Bluu/Swordburst 2')
ThemeManager:ApplyToTab(Settings)

local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()
SaveManager:SetLibrary(Library)
SaveManager:SetFolder('Bluu/Swordburst 2')
SaveManager:IgnoreThemeSettings()
SaveManager:BuildConfigSection(Settings)
SaveManager:LoadAutoloadConfig()

local Credits = Settings:AddRightGroupbox('Credits')

Credits:AddLabel('de_Neuublue - Script')
Credits:AddLabel('Inori - UI library')
Credits:AddLabel('wally - UI addons')
