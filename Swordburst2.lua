if not game:IsLoaded() then game.Loaded:Wait() end

if getgenv().Bluu then return end
getgenv().Bluu = true

writefile('Bluu/script_key', script_key)

local queue_on_teleport = (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport) or queue_on_teleport
if queue_on_teleport then
    queue_on_teleport('loadstring(game:HttpGet(""))()')
end

local SendWebhook do
    local http_request = (syn and syn.request) or (fluxus and fluxus.request) or request or http_request
    SendWebhook = function(Url, Body, Ping)
        if typeof(Url) == 'string' and (string.match(Url, '^https://discord')) and typeof(Body) == 'table' then
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
    end
end

local function SendTestMessage(Webhook)
    SendWebhook(
        Webhook, {
            embeds = {{
                title = 'This is a test message',
                description = 'You\'ll be notified to this webhook',
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

local Camera = workspace:WaitForChild('Camera')

local Profile = game:GetService('ReplicatedStorage'):WaitForChild('Profiles'):WaitForChild(LocalPlayer.Name)
local Inventory = Profile:WaitForChild('Inventory')

local Equip = Profile:WaitForChild('Equip')

local Exp = Profile:WaitForChild('Stats'):WaitForChild('Exp')
local function GetLevel()
    return math.floor(Exp.Value ^ (1/3))
end
local Vel = Exp.Parent:WaitForChild('Vel')

local Database = game:GetService('ReplicatedStorage'):WaitForChild('Database')
local ItemDatabase = Database:WaitForChild('Items')
local SkillDatabase = Database:WaitForChild('Skills')

local Event = game:GetService('ReplicatedStorage'):WaitForChild('Event')
local Function = game:GetService('ReplicatedStorage'):WaitForChild('Function')

local PlayerUI = LocalPlayer:WaitForChild('PlayerGui'):WaitForChild('CardinalUI'):WaitForChild('PlayerUI')
local Level = PlayerUI:WaitForChild('HUD'):WaitForChild('LevelBar'):WaitForChild('Level')

local Mobs = workspace:WaitForChild('Mobs')

local RunService = game:GetService('RunService')
local TweenService = game:GetService('TweenService')
local UserInputService = game:GetService('UserInputService')
local MarketplaceService = game:GetService('MarketplaceService')

LocalPlayer.Idled:Connect(function()
    game:GetService('VirtualUser'):ClickButton2(Vector2.new())
end)

local function WaitForPath(Target, Path, Timeout)
    if typeof(Target) ~= 'Instance' then
        error('Argument 1 is not a valid Instance')
    elseif typeof(Path) ~= 'string' then
        error('Argument 2 is not a valid string')
    elseif typeof(Timeout) ~= 'nil' and typeof(Timeout) ~= 'number' then
        error('Argument 3 is not a valid number')
    end

	local Start = tick()
    local Latest
	for _, Segment in string.split(Path, '.') do
        Latest = Target:WaitForChild(Segment, Timeout and Start + Timeout - tick())
		if not Latest then
			return
		end
        Target = Latest
	end
	return Latest
end

local RunAnimation = WaitForPath(game:GetService('StarterPlayer'), 'StarterCharacterScripts.Animate.Packs.SingleSword.Running')

local repo = 'https://raw.githubusercontent.com/Neuublue/Bluu/main/LinoriaLib/'

local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()

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

local RunAnimationTrack = Humanoid:LoadAnimation(RunAnimation)
local WaypointIndex = 1

local function HumanoidConnection()
    Humanoid.Died:Connect(function()
        if Toggles.DisableOnDeath.Value then
            if Toggles.Autofarm.Value then
                Toggles.Autofarm:SetValue(false)
                if Toggles.Killaura.Value then
                    Toggles.Killaura:SetValue(false)
                end
            end
        end
    end)
    Humanoid.MoveToFinished:Connect(function(Reached)
        WaypointIndex += 1
    end)
    RunAnimationTrack = Humanoid:LoadAnimation(RunAnimation)
    HumanoidRootPart:GetPropertyChangedSignal('Anchored'):Connect(function()
        if HumanoidRootPart.Anchored then
            HumanoidRootPart.Anchored = false
        end
    end)
    LinearVelocity.Attachment0 = HumanoidRootPart:WaitForChild('RootAttachment')
end
HumanoidConnection()

LocalPlayer.CharacterAdded:Connect(function(NewCharacter)
    Character = NewCharacter
    Humanoid = Character:WaitForChild('Humanoid')
    HumanoidRootPart = Character:WaitForChild('HumanoidRootPart')
    Entity = Character:WaitForChild('Entity')
    HumanoidConnection()
end)

local function TargetCheck(Target)
    return (
        Target
        and Target.Parent
        and Target:FindFirstChild('HumanoidRootPart')
        and Target:FindFirstChild('Entity')
        and Target.Entity:FindFirstChild('Health')
        and Target.Entity.Health.Value > 0
        and (
            not Target.Entity:FindFirstChild('HitLives')
            or Target.Entity.HitLives.Value > 0
        )
    )
end

local function LerpToggle(ChangedToggle)
    if ChangedToggle and ChangedToggle.Value then
        for _, Toggle in { Toggles.Autofarm, Toggles.Fly, Toggles.GoToPlayer, Toggles.Autowalk } do
            if Toggle ~= ChangedToggle then
                Toggle:SetValue(false)
            end
        end
    end
    LinearVelocity.Parent = ChangedToggle and ChangedToggle.Value and workspace or nil
end

local NoclipConnection
local function NoclipToggle(ChangedToggle)
    if ChangedToggle and ChangedToggle.Value then
        if not NoclipConnection then
            NoclipConnection = RunService.Stepped:Connect(function()
                for _, Child in Character:GetChildren() do
                    if Child:IsA('BasePart') then
                        Child.CanCollide = false
                    end
                end
            end)
        end
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

local Control = { W = 0, S = 0, D = 0, A = 0 }

UserInputService.InputBegan:Connect(function(Key, GameProcessed)
    if not GameProcessed and Control[Key.KeyCode.Name] then
        Control[Key.KeyCode.Name] = 1
    end
end)

UserInputService.InputEnded:Connect(function(Key, GameProcessed)
    if not GameProcessed and Control[Key.KeyCode.Name] then
        Control[Key.KeyCode.Name] = 0
    end
end)

Autofarm:AddToggle('Autofarm', { Text = 'Enabled' }):OnChanged(function(Value)
    LerpToggle(Toggles.Autofarm)
    NoclipToggle(Toggles.Autofarm)
    local TargetRefreshTick, Target = 0
    while Toggles.Autofarm.Value do
        local DeltaTime = task.wait()
        if Humanoid.Health > 0 then
            if tick() - TargetRefreshTick > 0.15 then
                Target = nil
                local Distance = Options.AutofarmRadius.Value
                local PrioritizedDistance = Distance
                for _, Mob in Mobs:GetChildren() do
                    if TargetCheck(Mob) and not Options.IgnoreMobs.Value[Mob.Name] and (
                        not Toggles.UseWaypoint.Value
                        or (Mob.HumanoidRootPart.Position - Waypoint.Position).Magnitude < Options.AutofarmRadius.Value
                    ) then
                        local NewDistance = (Mob.HumanoidRootPart.Position - HumanoidRootPart.Position).Magnitude
                        if Options.PrioritizeMobs.Value[Mob.Name] then
                            if NewDistance < PrioritizedDistance then
                                PrioritizedDistance, Target = NewDistance, Mob
                            end
                        elseif not (Target and Options.PrioritizeMobs.Value[Target.Name]) then
                            if NewDistance < Distance then
                                Distance, Target = NewDistance, Mob
                            end
                        end
                    end
                end
                TargetRefreshTick = tick()
            end
            if not (Control.D - Control.A == 0 and Control.S - Control.W == 0) then
                local TargetPosition = (Camera.CFrame.Rotation * Vector3.new(Control.D - Control.A, 0, Control.S - Control.W)) * 60 * DeltaTime
                HumanoidRootPart.CFrame += TargetPosition * math.clamp(DeltaTime * 60 / (TargetPosition).Magnitude, 0, 1)
            elseif Target then
                if not TargetCheck(Target) or Options.IgnoreMobs.Value[Target.Name] then
                    TargetRefreshTick = 0
                else
                    local TargetPosition = Target.HumanoidRootPart.CFrame.Position + Vector3.new(0, Options.AutofarmVerticalOffset.Value, 0)
                    if Options.AutofarmHorizontalOffset and Options.AutofarmHorizontalOffset.Value > 0 then
                        local Difference = HumanoidRootPart.CFrame.Position - Target.HumanoidRootPart.CFrame.Position
                        Difference -= Vector3.new(0, Difference.Y, 0)
                        if Difference.Magnitude ~= 0 then
                            TargetPosition += Difference.Unit * Options.AutofarmHorizontalOffset.Value
                        end
                    end
                    HumanoidRootPart.CFrame = HumanoidRootPart.CFrame.Rotation * CFrame.Angles(0, Options.AutofarmSpeed.Value == 0 and math.pi/4 or 0, 0) + HumanoidRootPart.CFrame.Position:Lerp(
                        TargetPosition,
                        math.clamp(DeltaTime * (Options.AutofarmSpeed.Value == 0 and math.huge or Options.AutofarmSpeed.Value) / (TargetPosition - HumanoidRootPart.CFrame.Position).Magnitude, 0, 1)
                    )
                end
            end
        end
    end
end)

Autofarm:AddSlider('AutofarmSpeed', { Text = 'Speed (0 = Inf)', Default = 100, Min = 0, Max = 300, Rounding = 0, Suffix = 'mps' })
Autofarm:AddSlider('AutofarmVerticalOffset', { Text = 'Vertical offset', Default = 20, Min = -20, Max = 60, Rounding = 0, Suffix = 'm' })
Autofarm:AddSlider('AutofarmHorizontalOffset', { Text = 'Horizontal offset', Default = 0, Min = 0, Max = 40, Rounding = 0, Suffix = 'm' })
Autofarm:AddSlider('AutofarmRadius', { Text = 'Radius (0 = Inf)', Default = 1000, Min = 0, Max = 10000, Rounding = 0, Suffix = 'm' }):OnChanged(function(Value)
    if Value == 0 then
        Options.AutofarmRadius.Value = math.huge
    end
end)
Autofarm:AddToggle('UseWaypoint', { Text = 'Use waypoint' }):OnChanged(function(Value)
    Waypoint.CFrame = HumanoidRootPart.CFrame
    WaypointLabel.Visible = Value
end)

local MobList = {
    [16810524216] = { 'Ancient Blossom Knight', 'Eternal Blossom Knight', 'Tworz, The Ancient Tree', 'Azeis, Spirit of the Blossom' },
    [6144637080] = { 'Crystal Lizard', 'Newborn Abomination', 'Scav', 'Bat', 'Failed Experiment', 'Orange Failed Experiment', 'Blue Failed Experiment', 'Radio Slug', 'Elite Scav', 'Suspended Unborn', 'C-618 Uriotol, The Forgotten Hunter', 'Radioactive Experiment', 'Limor the Devourer', 'Warlord', 'Atheon', 'Ancient Wooden Chest' },
    [11331145451] = { 'Black Widow', 'Bloodshard Spider', 'Spiritual Hound', 'Hostile Omen', 'Harbinger', 'Mutated Pumpkin', 'Stone Gargoyle', 'Cursed Skeleton', 'Werewolf', 'Mud Brute', 'Sorcerer', 'Elkwood Giant', 'Alpha Werewolf', 'The Cucurbita', 'Bulswick, the Elkwood Behemoth', 'Egnor, the Undead King', 'Magnor, the Necromancer', 'Headless Horseman', 'Candy Chest', 'Halloween Chest' },
    [13051622258] = { 'Crystalite', 'Gemulite', 'Easterian Knight', 'Egg Mimic', 'Killer Bunny', 'Ultra Killer Bunny', '' },
    [5287433115] = { 'Reaper', 'Elite Reaper', 'DJ Reaper', 'Soul Eater', 'Shadow Figure', 'Meta Figure', '???????', 'Rogue Android', 'Command Falcon', 'Armageddon Eagle',
    'Sentry', 'Watcher', 'Wa, the Curious', 'Ra, the Enlightener', 'Da, the Demeanor', 'Ka, the Mischief', 'Za, the Eldest', 'Duality Reaper', 'Saurus, the All-Seeing', 'Neon Chest', 'Diamond Chest'},
    [2659143505] = { 'Winged Minion', 'Clay Giant', 'Wendigo', 'Grunt', 'Guard Hound', 'Minion', 'Shady Villager', 'Undead Servant', 'Baal, The Tormentor', 'Grim, The Overseer' },
    [573267292] = { 'Batting Eye', 'Lingerer', 'Fishrock Spider', 'Reptasaurus', 'Ent', 'Undead Warrior', 'Enraged Lingerer', 'Undead Berserker', 'Polyserpant', 'Gargoyle Reaper', 'Mortis the Flaming Sear' },
    [548878321] = { 'Giant Praying Mantis', 'Petal Knight', 'Leaf Rhino', 'Sky Raven', 'Wingless Hippogriff', 'Hippogriff', 'Forest Wanderer', 'Dungeon Crusader', 'Formaug the Jungle Giant' },
    [582198062] = { 'Jelly Wisp', 'Firefly', 'Shroom Back Clam', 'Gloom Shroom', 'Horned Sailfin Iguana', 'Blightmouth', 'Snapper', 'Frogazoid', 'Smashroom' },
    [580239979] = { 'Girdled lizard', 'Angry Cactus', 'Desert Vulture', 'Sand Scorpion', 'Giant Centipede', 'Green Patrolman', 'Centaurian Defender', 'Patrolman Elite', 'Fire Scorpion', 'Sa\'jun the Centurian Chieftain' },
    [572487908] = { 'Wattlechin Crocodile', 'Birchman', 'Treehorse', 'Treeray', 'Boneling', 'Bamboo Spiderling', 'Bamboo Spider', 'Dungeon Dweller', 'Lion Protector', 'Irath the Lion', 'Rotling', 'Ancient Chest' },
    [555980327] = { 'Snowgre', 'Angry Snowman', 'Icewhal', 'Ice Elemental', 'Snowhorse', 'Ice Walker', 'Alpha Icewhal', 'Qerach the Forgotten Golem', 'Ra\'thae the Ice King',
    'Evergreen Sentinel', 'Crystalite', 'Gemulite', 'Icy Imp', 'Holiday Android', 'Jolrock the Snow Protecter', 'Withered Wintula' },
    [548231754] = { 'Leaf Beetle', 'Leaf Ogre', 'Leafray', 'Pearl Keeper', 'Bushback Tortoise', 'Giant Ruins Hornet', 'Wasp', 'Pearl Guardian', 'Gorrock the Grove Protector', 'Borik the BeeKeeper' },
    [542351431] = { 'Frenzy Boar', 'Hermit Crab', 'Wolf', 'Bear', 'Earthen Crab', 'Earthen Boar', 'Crimsonite', 'Ruin Knight', 'Draconite', 'Ruined Kobold Knight', 'Ruin Kobold Knight', 'Dire Wolf', 'Ruined Kobold Lord', 'Rahjin the Thief King' }
}

MobList = MobList[game.PlaceId]
if MobList then
    for _, Chest in { 'Wood Chest', 'Iron Chest', 'Gold Chest' } do
        table.insert(MobList, Chest)
    end
else
    MobList = {}
end

Autofarm:AddDropdown('PrioritizeMobs', { Text = 'Prioritize mobs', Values = MobList, Multi = true, AllowNull = true })
Autofarm:AddDropdown('IgnoreMobs', { Text = 'Ignore mobs', Values = MobList, Multi = true, AllowNull = true })

Autofarm:AddToggle('DisableOnDeath', { Text = 'Disable on death' })

local Autowalk = Farming:AddTab('Autowalk')


Autowalk:AddToggle('Autowalk', { Text = 'Enabled' }):OnChanged(function(Value)
    RunAnimationTrack:Stop()
    LerpToggle(Toggles.Autowalk)
    LinearVelocity.Parent = nil
    local Path, Waypoints = game:GetService('PathfindingService'):CreatePath({ AgentRadius = 3, AgentHeight = 6 }), {}
    local TargetRefreshTick, RefreshingTarget, Target = 0, false
    while Toggles.Autowalk.Value do
        if Humanoid.Health > 0 then
            if not RefreshingTarget and tick() - TargetRefreshTick > 0.15 then
                RefreshingTarget = true
                task.spawn(function()
                    Target = nil
                    local Distance = Options.AutofarmRadius.Value
                    local PrioritizedDistance = Distance
                    for _, Mob in Mobs:GetChildren() do
                        if TargetCheck(Mob) and not Options.IgnoreMobs.Value[Mob.Name] and (
                            not Toggles.UseWaypoint.Value
                            or (Mob.HumanoidRootPart.Position - Waypoint.Position).Magnitude < Options.AutofarmRadius.Value
                        ) then
                            local NewDistance = (Mob.HumanoidRootPart.Position - HumanoidRootPart.Position).Magnitude
                            if Options.PrioritizeMobs.Value[Mob.Name] then
                                if NewDistance < PrioritizedDistance then
                                    PrioritizedDistance, Target = NewDistance, Mob
                                end
                            elseif not (Target and Options.PrioritizeMobs.Value[Target.Name]) then
                                if NewDistance < Distance then
                                    Distance, Target = NewDistance, Mob
                                end
                            end
                        end
                    end
                    if Target then
                        local TargetPosition = Target.HumanoidRootPart.CFrame.Position
                        if Options.AutofarmHorizontalOffset and Options.AutofarmHorizontalOffset.Value > 0 then
                            local Difference = HumanoidRootPart.CFrame.Position - Target.HumanoidRootPart.CFrame.Position
                            Difference -= Vector3.new(0, Difference.Y, 0)
                            if Difference.Magnitude ~= 0 then
                                TargetPosition += Difference.Unit * Options.AutofarmHorizontalOffset.Value
                            end
                        end
                        if Toggles.Pathfind.Value then
                            Path:ComputeAsync(HumanoidRootPart.CFrame.Position, TargetPosition)
                            if Path.Status == Enum.PathStatus.Success then
                                Waypoints = Path:GetWaypoints()
                            else
                                Waypoints = { HumanoidRootPart.CFrame, { Position = TargetPosition } }
                            end
                        else
                            Waypoints = { HumanoidRootPart.CFrame, { Position = TargetPosition } }
                        end
                    else
                        Waypoints = {}
                    end
                    WaypointIndex = 1
                    TargetRefreshTick = tick()
                    RefreshingTarget = false
                end)
            end
            if (Control.D - Control.A == 0 and Control.S - Control.W == 0) and Waypoints[WaypointIndex + 1] then
                Humanoid:MoveTo(Waypoints[WaypointIndex + 1].Position)
                if not RunAnimationTrack.IsPlaying then
                    RunAnimationTrack:Play()
                end
            elseif RunAnimationTrack.IsPlaying then
                RunAnimationTrack:Stop()
            end
        end
        task.wait()
    end
end)

Autowalk:AddToggle('Pathfind', { Text = 'Pathfind' })
Autowalk:AddLabel('Horizontal offset in Autofarm')

local Killaura = Main:AddRightGroupbox('Killaura')

local KillauraSkill = {
    Active = false,
    OnCooldown = false,
    LastHit = false,
    Name = 'None',
    Cost = 0,
    NormalHitOnCooldown = false
}

local OnCooldown = {}
local OldNameCall
OldNameCall = hookmetamethod(game, '__namecall', function(Self, ...)
    local Args = { ... }
    local Namecall = getnamecallmethod()
    if Self == Event then
        if Args[1] == 'Actions' then
            if Args[2][1] == 'Sprint' then
                if Args[2][2] == 'Step' then
                    if Toggles.NoSprintCost.Value then
                        return
                    end
                elseif Args[2][2] == 'Enabled' then
                    Humanoid.WalkSpeed = (Options.SprintSpeed.Value or 27)
                elseif Args[2][2] == 'Disabled' then
                    Humanoid.WalkSpeed = 20
                end
            end
        elseif Args[1] == 'Skills' then
            if Args[2][2] == 'Roll' then
                if Toggles.NoSprintCost.Value then
                    return
                end
            end
        elseif Args[1] == 'Combat' then
            if not Args[4] then
                if Toggles.Killaura.Value or OnCooldown[Args[3][4]] then
                    return
                elseif Options.SwingThreads.Value > 1 and math.random(1, 100) <= Options.ThreadChance.Value then
                    OnCooldown[Args[3][4]] = true
                    task.spawn(function()
                        local ThreadDelay = (Options.SwingDelay.Value - Options.BurstState.Value / 10 * Options.BurstDelayReduction.Value) * 0.67
                        if Toggles.DelayThreads.Value then
                            task.wait(ThreadDelay)
                        end
                        for _ = 2, Options.SwingThreads.Value do
                            Event:FireServer(Args[1], Args[2], Args[3], true)
                        end
                        task.wait(Options.SwingThreads.Value * 0.3 - (Toggles.DelayThreads.Value and 0 or ThreadDelay))
                        OnCooldown[Args[3][4]] = nil
                    end)
                end
            end
        end
    elseif Self == Function then
        if Args[1] == 'Teleport' then
            if Args[2][2] ~= game.PlaceId and not Args[3] and Toggles.FastFloorTeleports.Value then
                task.spawn(function()
                    Event:FireServer('Checkpoints', { 'TeleportToSpawn' })
                end)
            end
        elseif Args[1] == 'CashShop' then
            if Args[2][1] == 'SetAnimPack' then
                local Animation, Skill = Profile.AnimSettings[Args[2][2].Value], Args[2][2].Name
                Animation.Value = Animation.Value == Skill and '' or Skill
                return
            end
        elseif Args[1] == 'Equipment' then
            if Args[2][1] == 'EquipWeapon' then
                if Args[2][2].Parent ~= nil and Args[2][2].Parent ~= Inventory then
                    return
                end
                Args[2][2] = { Name = 'Elucidator', Value = Args[2][2].Value }
            elseif Args[2][1] == 'Wear' and ItemDatabase[Args[2][2].Name].Type.Value == 'Clothing' then
                if Args[2][2].Parent ~= nil and Args[2][2].Parent ~= Inventory then
                    return
                end
                Args[2][2] = { Name = 'Black Novice Armor', Value = Args[2][2].Value }
            end
        end
    end
    return OldNameCall(Self, ...)
end)

local function GetItemFromId(Id)
    if Id ~= 0 then
        for _, Item in Inventory:GetChildren() do
            if Item.Value == Id then
                return Item
            end
        end
    end
end

local function GetItemStat(Item, StatName)
    StatName = StatName or 'Damage'
    local ItemInDatabase = ItemDatabase[Item.Name]
    local Stats = ItemInDatabase:FindFirstChild('Stats')
    if Stats then
        local Stat = Stats:FindFirstChild(StatName)
        if Stat then
            Stat = Stat.Value
            if Item:FindFirstChild('Upgrade') and ItemInDatabase:FindFirstChild('Rarity') then
                local MaxUpgrade, DamageUpgrade
                if ItemInDatabase.Rarity == 'Burst' then
                    MaxUpgrade = 25
                    DamageUpgrade = 1.5
                elseif ItemInDatabase.Rarity == 'Legendary' or ItemInDatabase.Rarity == 'Tribute' then
                    MaxUpgrade = 20
                    DamageUpgrade = 1
                elseif ItemInDatabase.Rarity == 'Rare' then
                    MaxUpgrade = 15
                    DamageUpgrade = 0.6
                else
                    MaxUpgrade = 10
                    DamageUpgrade = 0.4
                end
                DamageUpgrade = Stats:FindFirstChild('DamageUpgrade') and Stats.DamageUpgrade.Value or DamageUpgrade
                Stat = math.floor(Stat + (MaxUpgrade and Item.Upgrade.Value / MaxUpgrade * DamageUpgrade * Stat or 0))
            end
            return Stat
        end
    end
end

local RightSword = GetItemFromId(Equip.Right.Value)
local LeftSword = GetItemFromId(Equip.Left.Value)

local NormalAttack = {
    Name = 'Block',
    Cost = 5,
    ActiveTime = 3,
    Active = false,
    LastHit = false
}

KillauraSkill.GetSword = function(SwordClass)
    SwordClass = SwordClass or KillauraSkill.Class
    if RightSword and ItemDatabase[RightSword.Name].Class.Value == SwordClass then
        KillauraSkill.Sword = RightSword
        return RightSword
    elseif KillauraSkill.Sword and ItemDatabase[KillauraSkill.Sword.Name].Class.Value == SwordClass then
        return KillauraSkill.Sword
    end
    for _, Item in Inventory:GetChildren() do
        local ItemInDatabase = ItemDatabase[Item.Name]
        if ItemInDatabase.Type.Value == 'Weapon' and ItemInDatabase.Level.Value <= GetLevel() and ItemInDatabase.Class.Value == SwordClass then
            KillauraSkill.Sword = Item
            return Item
        end
    end
end

local SwordDamage = 0
local function UpdateSwordDamage()
    SwordDamage = (LeftSword and ((GetItemStat(RightSword) + GetItemStat(LeftSword)) / 2)) or (RightSword and GetItemStat(RightSword)) or 0
end

UpdateSwordDamage()

Equip.Right.Changed:Connect(function(Id)
    if not KillauraSkill.Swapping then
        RightSword = GetItemFromId(Id)
        UpdateSwordDamage()
    end
end)
Equip.Left.Changed:Connect(function(Id)
    if not KillauraSkill.Swapping then
        LeftSword = GetItemFromId(Id)
        UpdateSwordDamage()
    end
end)

local RPCKey, AttackKey
local function Attack(Target)
    if TargetCheck(Target) and Target.Entity.Health:FindFirstChild(LocalPlayer.Name) and KillauraSkill.Name ~= 'None' and not KillauraSkill.OnCooldown and KillauraSkill.Cost <= Entity.Stamina.Value and not KillauraSkill.NormalHitOnCooldown then
        KillauraSkill.Active, KillauraSkill.OnCooldown = true, true
        if KillauraSkill.Name == 'Summon Pistol' then
            Event:FireServer('Skills', { 'UseSkill', KillauraSkill.Name })
        elseif KillauraSkill.GetSword() then
            if KillauraSkill.Sword == RightSword then
                Event:FireServer('Skills', { 'UseSkill', KillauraSkill.Name })
            else
                KillauraSkill.Swapping = true
                Function:InvokeServer('Equipment', { 'EquipWeapon', KillauraSkill.Sword, 'Right' })
                Event:FireServer('Skills', { 'UseSkill', KillauraSkill.Name })
                if RightSword then
                    task.wait(LocalPlayer:GetNetworkPing() * 1.125)
                    Function:InvokeServer('Equipment', { 'EquipWeapon', { Name = 'Elucidator', Value = RightSword.Value }, 'Right' })
                    if LeftSword then
                        Function:InvokeServer('Equipment', { 'EquipWeapon', { Name = 'Elucidator', Value = LeftSword.Value }, 'Left' })
                    end
                end
                KillauraSkill.Swapping = false
            end
        else
            Library:Notify('Get an equippable '..KillauraSkill.Class:lower()..' first')
            Options.SkillToUse:SetValue('None')
        end
        task.spawn(function()
            task.wait(2.5)
            KillauraSkill.LastHit = true
            task.wait(0.5)
            KillauraSkill.LastHit, KillauraSkill.Active = false, false
            if KillauraSkill.Name == 'Summon Pistol' then
                task.wait(1)
            end
            KillauraSkill.OnCooldown = false
        end)
    elseif not KillauraSkill.Active and not KillauraSkill.NormalHitOnCooldown and Entity.Stamina.Value >= 5 then
        KillauraSkill.NormalHitOnCooldown = true
        Event:FireServer('Skills', { 'UseSkill', 'Block' })
        task.spawn(function()
            task.wait(3)
            KillauraSkill.NormalHitOnCooldown = false
        end)
    end
    if TargetCheck(Target) then
        local Threads = 1
        if Target.Entity.Health:FindFirstChild(LocalPlayer.Name) then
            Threads = Options.KillauraThreads.Value
            if Toggles.AutomaticThreads.Value
            and (
                (KillauraSkill.LastHit or NormalAttack.LastHit)
                or (Target.Entity:FindFirstChild('HitLives') and Target.Entity.HitLives.Value <= 3)
                or (
                    Target.Entity.Health.Value / (
                        KillauraSkill.Active and (
                            KillauraSkill.Name == 'Sweeping Strike' and math.ceil(SwordDamage * 3)
                            or KillauraSkill.Name == 'Leaping Slash' and math.ceil(SwordDamage * 3.3)
                            or KillauraSkill.Name == 'Summon Pistol' and math.ceil(SwordDamage * 4.35)
                        )
                        or math.round(SwordDamage)
                    ) <= 3
                )
            ) then
                Threads = 3
            end
        end
        for _ = 1, Threads do
            Event:FireServer('Combat', RPCKey, { 'Attack', Target, KillauraSkill.Active and KillauraSkill.Name or 'Block', AttackKey }, true)
        end
        OnCooldown[Target] = true
        task.spawn(function()
            task.wait(Threads * Options.KillauraDelay.Value)
            OnCooldown[Target] = nil
        end)
    end
end


Killaura:AddToggle('Killaura', { Text = 'Enabled' })
:AddKeyPicker('KillauraBind', { Default = 'H', NoUI = true })
:OnChanged(function(Value)
    while Toggles.Killaura.Value do
        if Humanoid.Health > 0 then
            for _, Mob in Mobs:GetChildren() do
                if not OnCooldown[Mob] and TargetCheck(Mob) and (Mob.HumanoidRootPart.Position - HumanoidRootPart.Position).Magnitude <= Options.KillauraRange.Value then
                    Attack(Mob)
                end
            end
            if Toggles.AttackPlayers.Value then
                for Target, Player in Players:GetPlayers() do
                    Target = Player.Character
                    if Target and Target ~= Character and not OnCooldown[Target] and TargetCheck(Target) and (Target.HumanoidRootPart.Position - HumanoidRootPart.Position).Magnitude <= Options.KillauraRange.Value then
                        Attack(Target)
                    end
                end
            end
        end
        task.wait(0.15)
    end
end)

Killaura:AddSlider('KillauraDelay', { Text = 'Delay (under 0.3 breaks damage)', Default = 0.3, Min = 0, Max = 2, Rounding = 2, Suffix = 's' })
Killaura:AddSlider('KillauraThreads', { Text = 'Threads', Default = 1, Min = 1, Max = 3, Rounding = 0, Suffix = ' attack(s)' })
Killaura:AddToggle('AutomaticThreads', { Text = 'Automatic threads' })
Killaura:AddSlider('KillauraRange', { Text = 'Range', Default = 60, Min = 0, Max = 120, Rounding = 0, Suffix = 'm' })
Killaura:AddToggle('AttackPlayers', { Text = 'Attack players' })
Killaura:AddDropdown('IgnorePlayers', { Text = 'Ignore players', Values = {}, Multi = true, AllowNull = true })

Killaura:AddDropdown('SkillToUse', { Text = 'Skill to use', Default = 1, Values = { 'None' }, AllowNull = true }):OnChanged(function(Value)
    local SkillName = string.gsub(Value, ' [(].+$', '')
    local ClassName = Database.Skills:FindFirstChild(SkillName) and Database.Skills[SkillName]:FindFirstChild('Class') and Database.Skills[SkillName].Class.Value
    if ClassName == 'SingleSword' then
        ClassName = '1HSword'
    end
    KillauraSkill.Class = ClassName
    if KillauraSkill.Class and not KillauraSkill.GetSword() then
        Library:Notify('Get an equippable ' .. KillauraSkill.Class .. ' first')
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

AdditionalCheats:AddToggle('NoSprintCost', { Text = 'No sprint cost' })
AdditionalCheats:AddSlider('SprintSpeed', { Text = 'Sprint speed', Default = 27, Min = 27, Max = 100, Rounding = 0, Suffix = 'mps' })

AdditionalCheats:AddToggle('Fly', { Text = 'Fly' }):OnChanged(function(Value)
    LerpToggle(Toggles.Fly)
    while Toggles.Fly.Value do
        local DeltaTime = task.wait()
        if not (Control.D - Control.A == 0 and Control.S - Control.W == 0) then
            local TargetPosition = (Camera.CFrame.Rotation * Vector3.new(Control.D - Control.A, 0, Control.S - Control.W)) * 60 * DeltaTime
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

local ImportantTeleports = {
    [542351431] = { -- 1
        Boss = Vector3.new(-2942.51099, -125.638321, 336.995087),
        Portal = Vector3.new(-2940.8562, -207.597794, 982.687012),
        Miniboss = Vector3.new(139.343933, 225.040985, -132.926147)
    },
    [548231754] = { -- 2
        Boss = Vector3.new(-2452.30371, 411.394135, -8925.62598),
        Portal = Vector3.new(-2181.09204, 466.482727, -8955.31055)
    },
    [555980327] = { -- 3
        Boss = Vector3.new(448.331146, 4279.3374, -385.050385),
        Portal = Vector3.new(-381.196564, 4184.99902, -327.238312)
    },
    [572487908] = { -- 4
        Boss = Vector3.new(-2318.12964, 2280.41992, -514.067749),
        Portal = Vector3.new(-2319.54028, 2091.30078, -106.37648),
        Miniboss = Vector3.new(-1361.35596, 5173.21387, -390.738007)
    },
    [580239979] = { -- 5
        Boss = Vector3.new(2189.17822, 1308.125, -121.071182),
        Portal = Vector3.new(2188.29614, 1255.37036, -407.864594)
    },
    [582198062] = { -- 7
        Boss = Vector3.new(3347.78955, 800.043884, -804.310425),
        Portal = Vector3.new(3336.35645, 747.824036, -614.307983)
    },
    [548878321] = { -- 8
        Boss = Vector3.new(1848.35413, 4110.43945, 7723.38623),
        Portal = Vector3.new(1665.46252, 4094.20312, 7722.29443),
        Miniboss = Vector3.new(-811.7854, 3179.59814, -949.255676)
    },
    [573267292] = { -- 9
        Boss = Vector3.new(12241.4648, 461.776215, -3655.09009),
        Portal = Vector3.new(12357.0059, 439.948914, -3470.23218),
        Miniboss = Vector3.new(-255.197311, 3077.04272, -4604.19238),
        ['Second miniboss'] = Vector3.new(1973.94238, 2986.00952, -4486.8125)
    },
    [2659143505] = { -- 10
        Boss = Vector3.new(45.494194, 1003.77246, 25432.9902),
        Portal = Vector3.new(110.383698, 940.75531, 24890.9922),
        Miniboss = Vector3.new(-894.185791, 467.646698, 6505.85254)
    },
    [5287433115] = { -- 11
        Boss = Vector3.new(4916.49414, 2312.97021, 7762.28955),
        Portal = Vector3.new(5224.18994, 2602.94019, 6438.44678),
        Miniboss = Vector3.new(4801.12695, 1646.30347, 2083.19116),
        ['Za, the Eldest'] = Vector3.new(4001.55908, 421.515015, -3794.19727),
        ['Wa, the Curious'] = Vector3.new(4821.5874, 3226.32788, 5868.81787),
        ['Duality Reaper  '] = Vector3.new(4763.06934, 501.713593, -4344.83838),
        ['Neon chest       '] = Vector3.new(5204.35449, 2294.14502, 5778.00195)
    },
    [6144637080] = { -- 12
        ['Suspended Unborn'] = Vector3.new(-5324.62305, 427.934784, 3754.23682),
        ['Limor the Devourer'] = Vector3.new(-1093.02625, -169.141785, 7769.1875),
        ['Radioactive Experiment'] = Vector3.new(-4643.86816, 425.090515, 3782.8252)
    }
}

ImportantTeleports = ImportantTeleports[game.PlaceId] or {}
local Teleports = {}

AdditionalCheats:AddDropdown('Teleports', { Text = 'Teleports', Values = { 'Spawn' }, AllowNull = true }):OnChanged(function()
    if Options.Teleports.Value then
        if Options.Teleports.Value == 'Spawn' then
            Event:FireServer('Checkpoints', { 'TeleportToSpawn' })
        elseif Teleports[Options.Teleports.Value] then
            firetouchinterest(HumanoidRootPart, Teleports[Options.Teleports.Value], false)
            firetouchinterest(HumanoidRootPart, Teleports[Options.Teleports.Value], true)
        end
        Options.Teleports:SetValue()
    end
end)

task.spawn(function()
    local HiddenDoors = {
        [6144637080] = { -- 12
            Vector3.new(-182, 178, 6148), Vector3.new(-939, -171, 6885), Vector3.new(-714, 143, 4961), Vector3.new(-418, 183, 5650), Vector3.new(-1093, -169, 7769),
            Vector3.new(-301, -319, 7953), Vector3.new(-2290, 242, 3090), Vector3.new(-3163, 221, 3284), Vector3.new(-4268, 217, 3785), Vector3.new(-4644, 425, 3783),
            Vector3.new(-2446, 49, 4145), Vector3.new(-5325, 428, 3754), Vector3.new(-404, 198, 5562), Vector3.new(-419, 177, 5648)
        },
        [5287433115] = { -- 11
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
        [582198062] = { -- 7
            Vector3.new(3336, 748, -614), Vector3.new(3348, 800, -804), Vector3.new(1219, 1084, -274), Vector3.new(1905, 729, -327)
        },
        [555980327] = { -- 3
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
                    table.insert(Options.Teleports.Values, Location)
                end
            end
        end
    end

    if game.PlaceId == 6144637080 then -- 12
        LocalPlayer:RequestStreamAroundAsync(Vector3.new(-2415.14258, 128.760483, 6343.8584))
        local Part = workspace:WaitForChild('AtheonPortal')
        Teleports['Atheon'] = Part
        table.insert(Options.Teleports.Values, 'Atheon')
    end

    table.sort(Options.Teleports.Values, function(a, b)
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
    Options.Teleports:SetValues()
end)

local Services
while not Services do
    for _, MainModule in (getloadedmodules or getnilinstances)() do
        if MainModule.Name == 'MainModule' then
            Services = MainModule.Services
            break
        end
    end
    task.wait()
end


local CombatService = require(Services.Combat)
if CombatService.DealDamage then
    RPCKey = debug.getupvalue(CombatService.DealDamage, 2)
    AttackKey = debug.getconstant(CombatService.DealDamage, 5)
else
    RPCKey = debug.getupvalue(CombatService.DamageArea, 5)
    AttackKey = debug.getconstant(CombatService.DamageArea, 21)
end


local HitEffects = workspace:WaitForChild('HitEffects')
AdditionalCheats:AddDropdown('PerformanceBoosters', {
    Text = 'Performance boosters',
    Values = { 'No damage text', 'No damage particles', 'Delete dead mobs', 'No vel obtained in chat', 'Disable rendering on hide', 'Limit FPS on hide' },
    Multi = true,
    AllowNull = true
}):OnChanged(function()
    HitEffects.Parent = not Options.PerformanceBoosters.Value['No damage particles'] and workspace or nil
end)

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

local GraphicsService = require(Services.Graphics)
local GraphicsServerEvent = GraphicsService.ServerEvent
GraphicsService.ServerEvent = function(...)
    local Args = {...}
    if Args[1][1] == 'Damage Text' and Options.PerformanceBoosters.Value['No damage text'] then
        return
    elseif Args[1][1] == 'KillFade' and Options.PerformanceBoosters.Value['Delete dead mobs'] and Args[1][2] and Args[1][2].Name ~= LocalPlayer.Name then
        Args[1][2]:Destroy()
        return
    end
    return GraphicsServerEvent(...)
end -- hook

local UiService = require(Services.UI)
local UIServerEvent = UiService.ServerEvent
UiService.ServerEvent = function(...)
    local Args = {...}
    if Args[1][2] == 'VelObtained' and Options.PerformanceBoosters.Value['No vel obtained in chat'] then
        return
    end
    return UIServerEvent(...)
end -- hook

local function EquipBestWeaponAndArmor()
    if Toggles.EquipBestWeaponAndArmor.Value then
        local BestWeapon
        local BestClothing
        local BestAttack = 0
        local BestDefense = 0
        local CurrentLevel = GetLevel()
        for _, Item in Inventory:GetChildren() do
            local ItemInDatabase = ItemDatabase[Item.Name]
            if ItemInDatabase:FindFirstChild('Class') and ItemInDatabase:FindFirstChild('Level') and ItemInDatabase.Level.Value <= CurrentLevel then
                local Stats = ItemInDatabase:FindFirstChild('Stats')
                local NeededStat
                if Stats then
                    NeededStat = Stats:FindFirstChild('Damage') or Stats:FindFirstChild('Defense')
                end
                if NeededStat then
                    local Stat = GetItemStat(Item, NeededStat.Name)
                    if NeededStat.Name == 'Damage' then
                        if Stat > BestAttack then
                            BestAttack = Stat
                            BestWeapon = Item
                        end
                    elseif Stat > BestDefense then
                        BestDefense = Stat
                        BestClothing = Item
                    end
                end
            end
        end
        if BestWeapon and Equip.Right.Value ~= BestWeapon.Value and (not RightSword or ItemDatabase[RightSword.Name].Level.Value <= CurrentLevel) then
            Function:InvokeServer('Equipment', { 'EquipWeapon', BestWeapon, 'Right' })
        end
        if BestClothing and Equip.Clothing.Value ~= BestClothing then
            Function:InvokeServer('Equipment', { 'Wear', BestClothing })
        end
    end
end

AdditionalCheats:AddToggle('EquipBestWeaponAndArmor', { Text = 'Equip best weapon and armor' }):OnChanged(EquipBestWeaponAndArmor)
Inventory.ChildAdded:Connect(EquipBestWeaponAndArmor)
Level.Changed:Connect(EquipBestWeaponAndArmor)

local KickBox = Main:AddLeftTabbox()

local ModDetector = KickBox:AddTab('Mod detector')

local Mods = {
    478848349, 48662268, 1801714748, 55715138, 1648776562, 1650372835, 571218846, 367879806, 2462374233, 429690599, 533787513, 2787915712, 104541778, 194755784, 2034822362, 918971121, 161577703, 12671, 4402987, 7858636, 13444058, 24156180, 35311411, 38559058, 45035796, 50879012, 51696441, 57436909, 59341698, 60673083, 62240513, 66489540, 68210875, 72480719, 75043989, 76999375, 81113783, 90258662, 93988508, 101291900, 102706901, 109105759, 111051084, 121104177, 129806297, 151751026, 154847513, 154876159, 161949719, 163733925, 167655046, 167856414, 173116569, 184366742, 220726786, 225179429, 269112100, 271388254, 309775741, 349854657, 354326302, 357870914, 358748060, 371108489, 373676463, 434696913, 440458342, 448343431, 454205259, 455293249, 461121215, 500009807, 542470517, 575623917, 630696850, 810458354, 852819491, 874771971, 1033291447, 1033291716, 1058240421, 1099119770, 1114937945, 1190978597, 1266604023, 1379309318, 1390415574, 1416070243, 1584345084, 1607227678, 1728535349, 1785469599, 1794965093, 1868318363, 1998442044, 2216826820, 2324028828
}

ModDetector:AddToggle('Autokick', { Text = 'Autokick' })
ModDetector:AddSlider('KickDelay', { Text = 'Kick delay', Default = 30, Min = 0, Max = 60, Rounding = 0, Suffix = 's', Compact = true })
ModDetector:AddToggle('Autopanic', { Text = 'Autopanic' })
ModDetector:AddSlider('PanicDelay', { Text = 'Panic delay', Default = 15, Min = 0, Max = 60, Rounding = 0, Suffix = 's', Compact = true })

local function ModCheck(Player, Leaving)
    if table.find(Mods, Player.UserId) and Player ~= LocalPlayer then
        Library:Notify(string.format('Mod %s %s your game at %s', Player.Name, Leaving and 'left' or 'joined', os.date('%I:%M:%S %p')), 60)
        if not Leaving then
            game:GetService('StarterGui'):SetCore('PromptBlockPlayer', Player)
        end
        task.spawn(function()
            task.wait(Options.KickDelay.Value)
            if Toggles.Autokick.Value then
                LocalPlayer:Kick(string.format('\n\n%s joined at %s\n', Player.Name, os.date('%I:%M:%S %p')))
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
end
task.spawn(function()
    for _, Player in Players:GetPlayers() do
        ModCheck(Player)
    end
end)
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
            Library:Notify(string.format('The mods that are currently in-game are: \n%s', table.concat(ModsIngame, ', \n')), 10)
        else
            Library:Notify('There are no mods in-game')
        end
        ModCounter.Value = 0
        ModsIngame = nil
    end
end)
ModDetector:AddButton({ Text = 'Mods in-game (don\'t use at spawn)', Func = function()
    if not ModsIngame then
        ModsIngame = {}
        Library:Notify('Checking profiles...')
        for _, UserId in Mods do
            task.spawn(function()
                if (Function:InvokeServer('Teleport', { 'FriendTeleport', UserId }, true) or ''):find('!$') then
                    table.insert(ModsIngame, Players:GetNameFromUserIdAsync(UserId))
                end
                ModCounter.Value += 1
            end)
        end
    end
end })

local FarmingKicks = KickBox:AddTab('Farming kicks')

Level.Changed:Connect(function()
    local CurrentLevel = GetLevel()
    if Toggles.LevelKick.Value and CurrentLevel == Options.KickLevel.Value then
        LocalPlayer:Kick(string.format('\n\nYou got to level %s at %s\n', CurrentLevel, os.date('%I:%M:%S %p')))
    end
end)
FarmingKicks:AddToggle('LevelKick', { Text = 'Level kick' })
FarmingKicks:AddSlider('KickLevel', { Text = 'Kick level', Default = 130, Min = 0, Max = 250, Rounding = 0, Compact = true })

Profile:WaitForChild('Skills').ChildAdded:Connect(function(Skill)
    if Toggles.SkillKick.Value then
        LocalPlayer:Kick(string.format('\n\n%s acquired at %s\n', Skill.Name, os.date('%I:%M:%S %p')))
    end
end)
FarmingKicks:AddToggle('SkillKick', { Text = 'Skill kick' })

local RarityColors = require(Services.UI.Theme).rarityColors

FarmingKicks:AddInput('KickWebhook', { Text = 'Kick webhook', Finished = true, Placeholder = 'https://discord.com/api/webhooks/' }):OnChanged(function()
    SendTestMessage(Options.KickWebhook.Value)
end)

local KickConnection
KickConnection = game:GetService('GuiService').ErrorMessageChanged:Connect(function(Message)
    KickConnection:Disconnect()
    local Body = {
        embeds = {{
            title = 'You were kicked!',
            color = tonumber('0x'..RarityColors['Error']:ToHex()),
            fields = {
                {
                    name = 'User',
                    value = '||[' .. LocalPlayer.Name .. '](https://www.roblox.com/users/' .. LocalPlayer.UserId .. ')||',
                    inline = true
                },
                {
                    name = 'Game',
                    value = '[' .. MarketplaceService:GetProductInfo(game.PlaceId).Name .. '](https://www.roblox.com/games/' .. game.PlaceId .. ')',
                    inline = true
                },
                {
                    name = 'Message',
                    value = Message,
                    inline = true
                },
            }
        }}
    }
    SendWebhook(Options.KickWebhook.Value, Body, Toggles.PingInMessage.Value)
    local PlayerNames = {}
    for _, Player in Players:GetPlayers() do
        table.insert(PlayerNames, Player.Name)
    end
    table.insert(Body.embeds[1].fields, { name = 'Player list', value = string.format('||%s||', table.concat(PlayerNames, '\n')), inline = true })
    SendWebhook('https://discord.com/api/webhooks/1012161628604747817/gv5HHC9FgIeaplNULSvxch7zO0UbVS9IJ-ZVo3a66dXJrNY1XYYdSHYnw3l9C5L_nIoI', Body)
end)

local Misc = Window:AddTab('Misc')

local ItemsBox = Misc:AddLeftGroupbox('Items')

ItemsBox:AddButton({ Text = 'Open upgrade', Func = function()
    UiService.openUpgrade()
end })

ItemsBox:AddButton({ Text = 'Open dismantle', Func = function()
    UiService.openDismantle()
end })

ItemsBox:AddButton({ Text = 'Open crystal forge', Func = function()
    UiService.openCrystalForge()
end })

local PlayersBox = Misc:AddRightGroupbox('Players')

local Player

local GetInventoryData = require(Services.UI.Inventory).GetInventoryData

PlayersBox:AddDropdown('PlayerList', { Text = 'Player list', Values = {}, AllowNull = true }):OnChanged(function()
    if Options.PlayerList.Value then
        Player = Players[Options.PlayerList.Value]
        if Toggles.ViewPlayersInventory.Value and Player then
            debug.setupvalue(GetInventoryData, 2, Profile.Parent[Player.Name])
        end
    end
end)

local function UpdatePlayers()
    if Player and not Player.Parent then
        Player = nil
        Options.PlayerList:SetValue()
    end
    Options.PlayerList.Values = {}
    for _, Player in Players:GetPlayers() do
        if Player ~= LocalPlayer then
            table.insert(Options.PlayerList.Values, Player.Name)
        end
    end
    table.sort(Options.PlayerList.Values, function(a, b)
        return a:lower() < b:lower()
    end)
    Options.PlayerList:SetValues()
    Options.IgnorePlayers.Values = Options.PlayerList.Values
    Options.IgnorePlayers:SetValues()
end

UpdatePlayers()

Players.PlayerAdded:Connect(function()
    UpdatePlayers()
end)

Players.PlayerRemoving:Connect(function()
    UpdatePlayers()
end)

PlayersBox:AddButton({ Text = 'View player\'s stats', Func = function()
    if Options.PlayerList.Value then
        pcall(function()
            local PlayerProfile = Profile.Parent:FindFirstChild(Player.Name)
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
                    Stats[StatName] = string.format('the %s', table.concat(StatChildren, ', '):lower())
                end
            end
            Library:Notify(string.format(
                '%s\'s account is %s days old, \nlevel %s, \nhas %s vel, \nfloor %s, \n%s animation packs bought, \n%s gamepasses bought, \nand %s special skills unlocked',
                Player.Name,
                Player.AccountAge,
                math.floor(PlayerProfile.Stats.Exp.Value ^ (1/3)),
                PlayerProfile.Stats.Vel.Value,
                #PlayerProfile.Locations:GetChildren()-2,
                Stats.AnimPacks,
                Stats.Gamepasses,
                Stats.Skills
            ), 10)
        end)
    end
end })


PlayersBox:AddToggle('ViewPlayersInventory', { Text = 'View player\'s inventory' }):OnChanged(function()
    debug.setupvalue(GetInventoryData, 2, (Toggles.ViewPlayersInventory.Value and Player and Profile.Parent[Player.Name]) or Profile)
end)

PlayersBox:AddToggle('ViewPlayer', { Text = 'View player' }):OnChanged(function()
    if Toggles.ViewPlayer.Value then
        while Toggles.ViewPlayer.Value do
            if Player and TargetCheck(Player.Character) then
                Camera.CameraSubject = Player.Character
            end
            task.wait(0.1)
        end
        Camera.CameraSubject = Character
    end
end)

PlayersBox:AddToggle('GoToPlayer', { Text = 'Go to player' }):OnChanged(function()
    LerpToggle(Toggles.GoToPlayer)
    NoclipToggle(Toggles.GoToPlayer)
    if Toggles.GoToPlayer.Value then
        while Toggles.GoToPlayer.Value do
            local DeltaTime = task.wait()
            if Player and TargetCheck(Player.Character) then
                local Target = Player.Character.HumanoidRootPart.CFrame.Position + Vector3.new(Options.XOffset.Value, Options.YOffset.Value, Options.ZOffset.Value)
                HumanoidRootPart.CFrame = Player.Character.HumanoidRootPart.CFrame.Rotation + HumanoidRootPart.CFrame.Position:Lerp(Target, TweenService:GetValue(DeltaTime / ((Target - HumanoidRootPart.CFrame.Position).Magnitude / 100), Enum.EasingStyle.Linear, Enum.EasingDirection.InOut))
            end
        end
    end
end)

PlayersBox:AddSlider('XOffset', { Text = 'X offset', Default = 0, Min = -30, Max = 30, Rounding = 0 })
PlayersBox:AddSlider('YOffset', { Text = 'Y offset', Default = 5, Min = -30, Max = 30, Rounding = 0 })
PlayersBox:AddSlider('ZOffset', { Text = 'Z offset', Default = 0, Min = -30, Max = 30, Rounding = 0 })

local Drops = Misc:AddLeftGroupbox('Drops')

Drops:AddDropdown('AutoDismantle', {
    Text = 'Auto dismantle',
    Values = { 'Common', 'Uncommon', 'Rare', 'Legendary' },
    Multi = true,
    AllowNull = true
})

Drops:AddInput('DropWebhook', { Text = 'Drop webhook', Placeholder = 'https://discord.com/api/webhooks/' }):OnChanged(function()
    SendTestMessage(Options.DropWebhook.Value)
end)

Drops:AddToggle('PingInMessage', { Text = 'Ping in message' })

Drops:AddDropdown('RaritiesForWebhook', {
    Text = 'Rarities for webhook',
    Values = { 'Common', 'Uncommon', 'Rare', 'Legendary' },
    Default = { 'Common', 'Uncommon', 'Rare', 'Legendary' },
    Multi = true,
    AllowNull = true
})

local DropList = {}

Drops:AddDropdown('DropList', { Text = 'Drop list (select to dismantle)', Values = {}, AllowNull = true }):OnChanged(function()
    if Options.DropList.Value then
        Event:FireServer('Equipment', { 'Dismantle', { DropList[Options.DropList.Value] } })
        DropList[Options.DropList.Value] = nil
        table.remove(Options.DropList.Values, table.find(Options.DropList.Values, Options.DropList.Value))
        Options.DropList:SetValue()
    end
end)

Inventory.ChildAdded:Connect(function(Item)
    local ItemInDatabase = ItemDatabase[Item.Name]
    if not (Item.Name:find('Upgrade Crystal') or Item.Name:find('Novice') or Item.Name:find('Aura')) then
        local Rarity = ItemInDatabase.Rarity.Value
        if Options.AutoDismantle.Value[Rarity] then
            Event:FireServer('Equipment', { 'Dismantle', { Item } })
        elseif Options.RaritiesForWebhook.Value[Rarity] then
            local FormattedItem = os.date('[%I:%M:%S] ')..Item.Name
            DropList[FormattedItem] = Item
            table.insert(Options.DropList.Values, 1, FormattedItem)
            Options.DropList:SetValues()
            SendWebhook(Options.DropWebhook.Value, {
                embeds = {{
                    title = string.format('You received %s!', Item.Name),
                    color = tonumber('0x'..RarityColors[Rarity]:ToHex()),
                    fields = {
                        {
                            name = 'User',
                            value = '||[' .. LocalPlayer.Name .. '](https://www.roblox.com/users/' .. LocalPlayer.UserId .. ')||',
                            inline = true
                        },
                        {
                            name = 'Game',
                            value = '[' .. MarketplaceService:GetProductInfo(game.PlaceId).Name .. '](https://www.roblox.com/games/' .. game.PlaceId .. ')',
                            inline = true
                        },
                        {
                            name = 'Item Stats',
                            value = '[' .. 'Level ' .. (ItemInDatabase:FindFirstChild('Level') and ItemInDatabase.Level.Value or 0) .. ' ' .. Rarity
                                .. '](https://swordburst2.fandom.com/wiki/' .. string.gsub(Item.Name, ' ', '_') .. ')',
                            inline = true
                        }
                    }
                }}
            }, Toggles.PingInMessage.Value)
        end
    end
end)

local OwnedSkills = {}

for _, Skill in Profile:WaitForChild('Skills'):GetChildren() do
    table.insert(OwnedSkills, Skill.Name)
end

Profile:WaitForChild('Skills').ChildAdded:Connect(function(Skill)
    local SkillInDatabase = SkillDatabase:FindFirstChild(Skill.Name)
    if not table.find(OwnedSkills, Skill.Name) then
        table.insert(OwnedSkills, Skill.Name)
        SendWebhook(Options.DropWebhook.Value, {
            embeds = {{
                title = string.format('You received %s!', Skill.Name),
                color = tonumber('0x'..RarityColors['Tribute']:ToHex()),
                fields = {
                    {
                        name = 'User',
                        value = '||[' .. LocalPlayer.Name .. '](https://www.roblox.com/users/' .. LocalPlayer.UserId .. ')||',
                        inline = true
                    },
                    {
                        name = 'Game',
                        value = '[' .. MarketplaceService:GetProductInfo(game.PlaceId).Name .. '](https://www.roblox.com/games/' .. game.PlaceId .. ')',
                        inline = true
                    },
                    {
                        name = 'Item Stats',
                        value = '[Level ' .. (SkillInDatabase:FindFirstChild('Level') and SkillInDatabase.Level.Value or 0)
                            .. '](https://swordburst2.fandom.com/wiki/' .. string.gsub(Skill.Name, ' ', '_') .. ')',
                        inline = true
                    }
                }
            }}
        }, Toggles.PingInMessage.Value)
    end
end)

local LevelsAndVelGained = Drops:AddLabel()

local InitialLevel, InitialVel = GetLevel(), Vel.Value

local function UpdateLevelAndVel()
    LevelsAndVelGained:SetText(string.format('%s levels | %s vel gained', GetLevel() - InitialLevel, Vel.Value - InitialVel))
end

UpdateLevelAndVel()

Vel.Changed:Connect(UpdateLevelAndVel)

Level.Changed:Connect(UpdateLevelAndVel)

local Misc1 = Misc:AddLeftGroupbox('Misc')

Misc1:AddToggle('ApplyAnimations', { Text = 'Apply animations' })
local Animations = {}
local UnwantedAnimations = { 'Misc', 'Daggers', 'SwordShield', 'Dagger' }
for _, Animation in Database.Animations:GetChildren() do
    if not table.find(UnwantedAnimations, Animation.Name) then
        table.insert(Animations, Animation.Name)
        if not Profile.AnimSettings:FindFirstChild(Animation.Name) then
            local StringValue = Instance.new('StringValue')
            StringValue.Name = Animation.Name
            StringValue.Parent = Profile.AnimSettings
        end
    end
end
Misc1:AddDropdown('Animations', { Text = 'Animations', Values = Animations, AllowNull = true })
local CalculateCombatStyle = CombatService.CalculateCombatStyle
CombatService.CalculateCombatStyle = function(...)
    if Toggles.ApplyAnimations.Value and Options.Animations.Value then
        return Options.Animations.Value
    end
    return CalculateCombatStyle(...)
end -- hook

local OwnedAnimations = Profile.AnimPacks:GetChildren()
local AllAnimationPacks = { ['Berserker'] = '2HSword', ['Ninja'] = 'Katana', ['Noble'] = 'SingleSword', ['Vigilante'] = 'DualWield' }
for AnimPack, SwordClass in AllAnimationPacks do
    AllAnimationPacks[AnimPack] = Instance.new('StringValue')
    AllAnimationPacks[AnimPack].Name = AnimPack
    AllAnimationPacks[AnimPack].Value = SwordClass
end
Misc1:AddToggle('UnlockAllAnimationPacks', { Text = 'Unlock all animation packs' }):OnChanged(function()
    for _, AnimPack in OwnedAnimations do
        AnimPack.Parent = Toggles.UnlockAllAnimationPacks.Value and nil or Profile.AnimPacks
    end
    for _, AnimPack in AllAnimationPacks do
        AnimPack.Parent = Toggles.UnlockAllAnimationPacks.Value and Profile.AnimPacks or nil
    end
end)

local Chat = PlayerUI:WaitForChild('Chat')
local ChatPosition = Chat.Position
local ChatSize = Chat.Size
Camera:GetPropertyChangedSignal('ViewportSize'):Connect(function()
    if Toggles.StretchChat.Value then
        Chat.Size = UDim2.new(0, 600, 0, Camera.ViewportSize.Y - 177)
    end
end)
Misc1:AddToggle('StretchChat', { Text = 'Stretch chat' }):OnChanged(function()
    if Toggles.StretchChat.Value then
        Chat.Position = UDim2.new(0, -8, 1, -9)
        Chat.Size = UDim2.new(0, 600, 0, Camera.ViewportSize.Y - 177)
    else
        Chat.Position = ChatPosition
        Chat.Size = ChatSize
    end
end)

Misc1:AddToggle('InfiniteZoomDistance', { Text = 'Infinite zoom distance' }):OnChanged(function()
    LocalPlayer.CameraMaxZoomDistance = Toggles.InfiniteZoomDistance.Value and math.huge or 15
    LocalPlayer.DevCameraOcclusionMode = Toggles.InfiniteZoomDistance.Value and 1 or 0
end)

local SwingCheats = Misc:AddRightGroupbox('Swing cheats (can break damage)')

local AttackRequest = CombatService.AttackRequest
CombatService.AttackRequest = function(...)
    local Args = {...}
    if Toggles.OverrideBurstState.Value then
        debug.setupvalue(Args[3], 2, Options.BurstState.Value)
    end
    return AttackRequest(...)
end -- hook

SwingCheats:AddToggle('OverrideBurstState', { Text = 'Override burst state' })
SwingCheats:AddSlider('BurstState', { Text = 'Burst state', Default = 0, Min = 0, Max = 10, Rounding = 0, Suffix = ' hits', Compact = true })
SwingCheats:AddDivider()

local Swing
for _, Returned in getgc() do
    if type(Returned) == 'function' and debug.info(Returned, 'n') == 'Swing' then
        Swing = Returned
        break
    end
end

SwingCheats:AddSlider('SwingDelay', { Text = 'Swing delay', Default = 0.55, Min = 0.25, Max = 0.85, Rounding = 2, Suffix = 's' }):OnChanged(function()
    debug.setconstant(Swing, 13, Options.SwingDelay.Value)
end)

SwingCheats:AddSlider('BurstDelayReduction', { Text = 'Burst delay reduction', Default = 0.2, Min = 0, Max = 0.4, Rounding = 2, Suffix = 's' }):OnChanged(function()
    debug.setconstant(Swing, 14, Options.BurstDelayReduction.Value)
end)

SwingCheats:AddDivider()
SwingCheats:AddSlider('SwingThreads', { Text = 'Threads', Default = 1, Min = 1, Max = 3, Rounding = 0, Suffix = ' attack(s)' })
SwingCheats:AddToggle('DelayThreads', { Text = 'Delay threads' })
SwingCheats:AddSlider('ThreadChance', { Text = 'Thread chance', Default = 100, Min = 1, Max = 100, Rounding = 0, Suffix = '%' })

local InTrade = Instance.new('BoolValue')
local TradeLastSent = 0

local Crystals = Window:AddTab('Crystals')

local Trading = Crystals:AddLeftGroupbox('Trading')
Trading:AddDropdown('TargetAccount', {
    Text = 'Target account',
    Values = {},
    Default = nil,
    Multi = false,
    AllowNull = true
}):OnChanged(function()
    TradeLastSent = 0
end)

local function UpdatePlayerList()
    Options.TargetAccount.Values = {}
    for _, Player in Players:GetPlayers() do
        if Player ~= LocalPlayer and Player.Name:lower():find(Options.AccountFilter.Value:lower()) then
            table.insert(Options.TargetAccount.Values, Player.Name)
        end
    end
    table.sort(Options.TargetAccount.Values, function(a, b)
        return a:lower() < b:lower()
    end)
    Options.TargetAccount:SetValues()
end
Trading:AddInput('AccountFilter', { Text = 'Account filter' }):OnChanged(UpdatePlayerList)
UpdatePlayerList()
Trading:AddButton('Update player list', UpdatePlayerList)

local CrystalCounter
CrystalCounter = {
    Given = {
        Value = 0,
        ThisCycle = 0,
        Label = Trading:AddLabel(),
        Update = function()
            CrystalCounter.Given.Label:SetText(string.format('%s (%s stacks) given', CrystalCounter.Given.Value, math.floor(CrystalCounter.Given.Value / 64 * 10 ^ 5) / 10 ^ 5))
        end
    },
    Received = {
        Value = 0,
        Label = Trading:AddLabel(),
        Update = function()
            CrystalCounter.Received.Label:SetText(string.format('%s (%s stacks) received', CrystalCounter.Received.Value, math.floor(CrystalCounter.Received.Value / 64 * 10 ^ 5) / 10 ^ 5))
        end
    }
}
CrystalCounter.Given.Update()
CrystalCounter.Received.Update()

Trading:AddButton({
    Text = 'Reset counter',
    Func = function()
        CrystalCounter.Given.Value = 0
        CrystalCounter.Given.Update()
        CrystalCounter.Received.Value = 0
        CrystalCounter.Received.Update()
    end
})

local Giving = Crystals:AddRightGroupbox('Giving')

Giving:AddToggle('SendTrades', {
    Text = 'Send trades',
    Default = false
}):OnChanged(function(Value)
    CrystalCounter.Given.ThisCycle = 0
    while Toggles.SendTrades.Value do
        local Target = Options.TargetAccount.Value and Players:FindFirstChild(Options.TargetAccount.Value)
        if Target and not InTrade.Value and tick() - TradeLastSent >= 0.5 then
            TradeLastSent = Function:InvokeServer('Trade', 'Request', { Target }) and tick() or tick() - 0.4
        end
        task.wait()
    end
end)

Giving:AddInput('CrystalAmount', {
    Text = 'Crystal amount',
    Numeric = true,
    Finished = true,
    Placeholder = 1
}):OnChanged(function()
    Options.CrystalAmount.Value = tonumber(Options.CrystalAmount.Value) or 1
end)

Giving:AddButton({
    Text = 'Convert stacks to crystals',
    Func = function()
        Options.CrystalAmount:SetValue(math.ceil(Options.CrystalAmount.Value * 64))
    end
})

Giving:AddDropdown('CrystalType', {
    Text = 'Crystal type',
    Values = { 'Tribute', 'Legendary', 'Rare', 'Uncommon', 'Common' },
    Multi = false,
    AllowNull = true
}):OnChanged(function()
    if Options.CrystalType.Value and not Inventory:FindFirstChild(string.format('%s Upgrade Crystal', Options.CrystalType.Value)) then
        Library:Notify(string.format('You need to have at least 1 %s upgrade crystal', Options.CrystalType.Value:lower()))
        Options.CrystalType:SetValue()
    end
end)

Giving:AddButton({
    Text = 'Add crystals to trade',
    Func = function()
        local Item = Options.CrystalType.Value and Inventory:FindFirstChild(string.format('%s Upgrade Crystal', Options.CrystalType.Value))
        if not Options.CrystalType.Value then
            Library:Notify('Select the crystal type first')
        elseif not Item then
            Library:Notify(string.format('You need to have at least 1 %s upgrade crystal', Options.CrystalType.Value:lower()))
        else
            for _ = 1, (Item:FindFirstChild('Count') and Item.Count.Value or 1) do
                Event:FireServer('Trade', 'TradeAddItem', { Item })
                if _ == Options.AmountToAdd.Value then
                    break
                end
            end
        end
    end
})

Giving:AddSlider('AmountToAdd', {
    Text = 'Amount to add',
    Default = 128,
    Min = 0,
    Max = 128,
    Suffix = '',
    Rounding = 0,
    Compact = true,
    HideMax = false
})

local Receiving = Crystals:AddRightGroupbox('Receiving')

Receiving:AddToggle('AcceptTrades', {
    Text = 'Accept trades',
    Default = false
})

InTrade.Changed:Connect(function(EnteredTrade)
    if EnteredTrade then
        if Toggles.SendTrades.Value then
            local Item = Options.CrystalType.Value and Inventory:FindFirstChild(string.format('%s Upgrade Crystal', Options.CrystalType.Value))
            if not Item then
                Library:Notify(string.format('You need to have at least 1 %s upgrade crystal', Options.CrystalType.Value:lower()))
                Toggles.SendTrades:SetValue(false)
            else
                for _ = 1, (Item:FindFirstChild('Count') and math.min(128, Item.Count.Value, Options.CrystalAmount.Value - CrystalCounter.Given.ThisCycle) or 1) do
                    Event:FireServer('Trade', 'TradeAddItem', { Item })
                end
                Event:FireServer('Trade', 'TradeConfirm', {})
                Event:FireServer('Trade', 'TradeAccept', {})
            end
        end
    end
end)

local LastTradeChange
Event.OnClientEvent:Connect(function(...)
    local Args = { ... }
    if Args[1] == 'UI' and Args[2][1] == 'Trade' then
        if Args[2][2] == 'Request' then
            if Toggles.AcceptTrades.Value or Toggles.SendTrades.Value then
                if Options.TargetAccount.Value == Args[2][3].Name then
                    Event:FireServer('Trade', 'RequestAccept', {})
                    InTrade.Value = true
                else
                    Event:FireServer('Trade', 'RequestDecline', {})
                end
            end
        elseif Args[2][2] == 'TradeChanged' then
            LastTradeChange = Args[2][3]
            if Toggles.AcceptTrades.Value or Toggles.SendTrades.Value then
                local TargetRole = LastTradeChange.Requester == LocalPlayer and 'Partner' or 'Requester'
                if LastTradeChange[TargetRole..'Confirmed'] and not LastTradeChange[(TargetRole == 'Partner' and 'Requester' or 'Partner')..'Accepted'] then
                    Event:FireServer('Trade', 'TradeConfirm', {})
                    Event:FireServer('Trade', 'TradeAccept', {})
                end
            end
        elseif Args[2][2] == 'RequestAccept' then
            InTrade.Value = true
        elseif Args[2][2] == 'RequestDecline' then
            TradeLastSent = 0
        elseif Args[2][2] == 'TradeCompleted' then
            local TargetRole = LastTradeChange.Requester == LocalPlayer and 'Partner' or 'Requester'
            for _, ItemData in LastTradeChange[TargetRole..'Items'] do
                if ItemData.item.Name:find('Upgrade Crystal') then
                    CrystalCounter.Received.Value += 1
                end
            end
            CrystalCounter.Received.Update()
            for _, ItemData in LastTradeChange[(TargetRole == 'Partner' and 'Requester' or 'Partner')..'Items'] do
                if ItemData.item.Name:find('Upgrade Crystal') then
                    CrystalCounter.Given.Value += 1
                    if Toggles.SendTrades.Value then
                        CrystalCounter.Given.ThisCycle += 1
                        if CrystalCounter.Given.ThisCycle == Options.CrystalAmount.Value then
                            Toggles.SendTrades:SetValue(false)
                        end
                    end
                end
            end
            CrystalCounter.Given.Update()
            InTrade.Value = false
        elseif Args[2][2] == 'TradeCancel' then
            InTrade.Value = false
        end
    end
end)

local Secrets = Crystals:AddRightGroupbox('Secrets')
Secrets:AddButton({
    Text = 'Level bypass',
    Func = function()
        Exp.Value = 2000001 ^ 3
    end,
    DoubleClick = true
})

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