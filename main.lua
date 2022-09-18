if not game.IsLoaded then
    game.Loaded:wait();
end

local Players = game:GetService("Players");

local InsertService = game:GetService("InsertService");
local ReplicatedStorage = game:GetService("ReplicatedStorage");

local CoreGui = game:GetService("CoreGui");

local TweenService = game:GetService("TweenService");
local UserInputService = game:GetService("UserInputService");

local RunService = game:GetService("RunService");

local LocalPlayer = Players.LocalPlayer;
local OnChatted = ReplicatedStorage.DefaultChatSystemChatEvents.OnMessageDoneFiltering.OnClientEvent;

if getgenv().Running then
    warn("already loaded!")

    return;
end

local Admin = {
    Commands = {},
    Prefix = ".",
    Events = {},
    CEvents = {
        Tools = {},
        Whitelisted = {},
        Flying = false,
        InfiniteControlEvent = nil
    },
    Version = "1.0.1"
}

getgenv().Running = true;

local FlyTable = {
    ["W"] = 0,
    ["A"] = 0,
    ["S"] = 0,
    ["D"] = 0
}

local Keys = {}

-- Initializing UI
-- Not using local, because we need those values to be global

local UI = InsertService:LoadLocalAsset("rbxassetid://9625648426"):Clone();

CommandBar = UI.CommandBar;
Input = CommandBar.Input;

CommandList = UI.CommandList;
Container = CommandList.ScrollBar.Container;

CommandList.BackgroundTransparency = 1
CommandList.Visible = false

CommandList.Shadow.ImageTransparency = 1;

Container.CommandName.TextTransparency = 1
Container.CommandName.Description.TextTransparency = 1

CommandBar.BackgroundTransparency = 1

CommandBar.Shadow.ImageTransparency = 1;

Input.TextTransparency = 1
CommandBar.Position = UDim2.new(0.5, 0, 1, 35)

Container.Parent = nil;

UI.Parent = CoreGui;

local AddCommand = function(CommandName, Description, MainFunction, CommandArguments)
    for _, Command in pairs(Admin.Commands) do
        if string.lower(Command[1]) == string.lower(CommandName) then
            return nil; -- if command overrides
        end
    end
    -- ok ill try. after i eat tho in like 5 min
    if typeof(MainFunction) == "function" then
        if CommandArguments then -- make the template ui for the commandbar ig
            table.insert(Admin.Commands, {CommandName, Description, MainFunction, CommandArguments})
        else
            table.insert(Admin.Commands, {CommandName, Description, MainFunction})
        end
    else
        return nil;
    end
end

local GetIndex = function(Table, Element)
    for Index, Object in pairs(Table) do
        if Object == Element then
            return Index;
        end
    end
end

local GetPlayer = function(Caller, Name)
    local PlayerList = Players:GetPlayers();
    Name = string.lower(tostring(Name));

    if Name == "random" then
        return {PlayerList[math.random(1, #PlayerList)]};
    elseif Name == "all" then
        return PlayerList;
    elseif Name == "others" then
        table.remove(PlayerList, GetIndex(PlayerList, Caller));

        return PlayerList;
    elseif Name == "me" then
        return {Caller};
    end

    for _, Player in pairs(Players:GetPlayers()) do
        if string.lower(string.sub(Player.Name, 1, #Name)) == Name then
            return {Player};
        elseif string.lower(string.sub(Player.DisplayName, 1, #Name)) == Name then
            return {Player};
        end
    end
end

local CommandCheck = function(Caller, RawCommand)
    RawCommand = string.lower(RawCommand);

    local Splitted = string.split(RawCommand, " ");
    local Arguments = {};

    local CurrentCommand = Splitted[1];

    if string.sub(RawCommand, 1, 1) == Admin.Prefix then
        CurrentCommand = string.sub(CurrentCommand, 2)
    end

    for Index, Argument in pairs(Splitted) do
        if Index ~= 1 then
            table.insert(Arguments, Argument);
        end
    end

    for _, Command in pairs(Admin.Commands) do
        local Aliases = string.split(string.lower(Command[1]), "/"); -- rejoin/rj

        for _, Alias in pairs(Aliases) do
            if Alias == CurrentCommand then
                coroutine.wrap(function()
                    if Command[4] then -- Arguments
                        Command[3](Caller, unpack(Arguments));
                    else
                        Command[3]();
                    end
                end)();
            end
        end
    end
end

local ReplaceHumanoid = function()
    local OldHum = LocalPlayer.Character:WaitForChild("Humanoid", math.huge);
    local NewHum = OldHum:Clone();

    OldHum:Destroy();
    NewHum.Parent = LocalPlayer.Character;

    
    for _, Accessory in pairs(LocalPlayer.Character:GetChildren()) do
        if Accessory:IsA("Accessory") then
            sethiddenproperty(Accessory, "BackendAccoutrementState", 0);

            for _, Attachment in pairs(Accessory:GetDescendants()) do
                if Attachment:IsA("Attachment") then
                    Attachment:Destroy();
                end
            end
        end
    end

    LocalPlayer.Character["Body Colors"]:Destroy();
end

local AttachTool = function(Tool, Position, RHandGrip)
    if Position then
        local Arm = (LocalPlayer.Character:FindFirstChild("Right Arm") or
                        LocalPlayer.Character:FindFirstChild("RightHand")).CFrame *
                        CFrame.new(0, -1, 0, 1, 0, 0, 0, 0, 1, 0, -1, 0);
        Tool.Grip = Arm:ToObjectSpace(Position):Inverse();
    end
end

local GetTool = function()
    for _, Tool in pairs(LocalPlayer.Backpack:GetChildren()) do
        if Tool:FindFirstChild("Handle") then
            return Tool;
        end
    end

    return false;
end

local GetRoot = function(Character)
    return Character and Character:FindFirstChild("HumanoidRootPart") or Character:FindFirstChild("Torso") or
               Character:FindFirstChild("LowerTorso")
end

local ReplaceCharacter = function()
    local Character = LocalPlayer.Character;
    local Model = Instance.new("Model");

    LocalPlayer.Character = Model;
    LocalPlayer.Character = Character;

    Model:Destroy()
end

local ReturnMass = function(Character)
    local Mass = 0;

    for _, Object in pairs(Character:GetChildren()) do
        if Object:IsA("BasePart") then
            Mass = Mass + Object:GetMass();
        end
    end

    return Mass;
end

local ResizeLeg = function(Amount)
    local Scales = {"BodyTypeScale", "BodyProportionScale", "BodyWidthScale", "BodyHeightScale", "BodyDepthScale",
                    "HeadScale"}

    local Remove = function()
        LocalPlayer.Character.LeftFoot:WaitForChild("OriginalSize"):Destroy();

        LocalPlayer.Character.LeftLowerLeg.OriginalSize:Destroy()
        LocalPlayer.Character.LeftUpperLeg.OriginalSize:Destroy()
    end

    LocalPlayer.Character.LeftLowerLeg.LeftKneeRigAttachment.OriginalPosition:Destroy()
    LocalPlayer.Character.LeftUpperLeg.LeftKneeRigAttachment.OriginalPosition:Destroy()
    LocalPlayer.Character.LeftLowerLeg.LeftKneeRigAttachment:Destroy()
    LocalPlayer.Character.LeftUpperLeg.LeftKneeRigAttachment:Destroy()

    for Count = 1, Amount or 6 do
        Remove();

        LocalPlayer.Character.Humanoid[Scales[Count]]:Destroy()
    end
end

local KillableCheck = function(Character)
    if not Character:FindFirstChild("Humanoid") then
        print(Character.Name .. " doesn't have an humanoid.");

        return false;
    end

    local Humanoid = Character:FindFirstChild("Humanoid");

    if Humanoid:GetState() == Enum.HumanoidStateType.Dead then
        print(Character.Name .. " is dead.");

        return false;
    end

    if Humanoid.SeatPart ~= nil then
        print(Character.Name .. " is sitting.");

        return false;
    end

    if ReturnMass(LocalPlayer.Character) < ReturnMass(Character) then
        print(Character.Name .. " has more mass than you.");

        return false;
    end

    if Character.PrimaryPart.Anchored == true then
        return "Head"
    end

    return Character.PrimaryPart.Name;
end

Admin.Events.Chatted = LocalPlayer.Chatted:Connect(function(Message)
    if string.sub(Message, 1, 1) == Admin.Prefix then
        CommandCheck(LocalPlayer, Message);
    end
end)

Admin.Events.GChatted = OnChatted:Connect(function(Data)
    if table.find(Admin.CEvents.Whitelisted, Data.SpeakerUserId) ~= nil then
        if string.sub(Data.Message, 1, 1) == Admin.Prefix then
            CommandCheck(Players:GetPlayerByUserId(Data.SpeakerUserId), Data.Message);
        end
    end
end)

CommandList.ScrollBar.Positioner:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    local absoluteSize = CommandList.ScrollBar.Positioner.AbsoluteContentSize
    CommandList.ScrollBar.CanvasSize = UDim2.new(0, absoluteSize.X, 0, absoluteSize.Y + 50)
end)

Admin.Events.InputBegan = UserInputService.InputBegan:Connect(
    function(KInput, ProcessedEvent)
        if ProcessedEvent then
            return
        end

        local KeyCode = tostring(KInput.KeyCode):split(".")[3]
        Keys[KeyCode] = true

        if KInput.KeyCode == Enum.KeyCode.Semicolon and not Admin.Debounce then
            Admin.Debounce = true;

            local Tweens = {}

            table.insert(Tweens, TweenService:Create(CommandBar, TweenInfo.new(.75, Enum.EasingStyle.Quint), {
                Position = UDim2.new(0.5, 0, 1, -100)
            }))
            table.insert(Tweens, TweenService:Create(CommandBar, TweenInfo.new(.75, Enum.EasingStyle.Quint), {
                BackgroundTransparency = 0
            }))
            table.insert(Tweens, TweenService:Create(Input, TweenInfo.new(.75, Enum.EasingStyle.Quint), {
                TextTransparency = 0
            }))
            table.insert(Tweens, TweenService:Create(CommandBar.Shadow, TweenInfo.new(.75, Enum.EasingStyle.Quint), {
                ImageTransparency = 0
            }))

            for _, Tween in pairs(Tweens) do
                Tween:Play();
            end

            task.wait();

            Input:CaptureFocus();
        end
    end)

Admin.Events.InputEnded = UserInputService.InputEnded:Connect(
    function(KInput, ProcessedEvent)
        if ProcessedEvent then
            return
        end

        local KeyCode = tostring(KInput.KeyCode):split(".")[3]

        if Keys[KeyCode] then
            Keys[KeyCode] = false
        end
    end)

Admin.Events.FocusLost = Input.FocusLost:Connect(function(Enter)
    if Enter then
        local Access = Input.Text

        local Tweens = {};

        table.insert(Tweens, TweenService:Create(CommandBar, TweenInfo.new(.75, Enum.EasingStyle.Quint), {
            Position = UDim2.new(0.5, 0, 1, 35)
        }))
        table.insert(Tweens, TweenService:Create(CommandBar, TweenInfo.new(.75, Enum.EasingStyle.Quint), {
            BackgroundTransparency = 1
        }))
        table.insert(Tweens, TweenService:Create(Input, TweenInfo.new(.75, Enum.EasingStyle.Quint), {
            TextTransparency = 1
        }))
        table.insert(Tweens, TweenService:Create(CommandBar.Shadow, TweenInfo.new(.75, Enum.EasingStyle.Quint), {
            ImageTransparency = 1
        }))

        for _, Tween in pairs(Tweens) do
            Tween:Play();
        end

        Input.Text = ""

        task.wait();

        Admin.Debounce = false;

        CommandCheck(LocalPlayer, Access);
    end
end)

RunService.Heartbeat:Connect(function()
    LocalPlayer.MaximumSimulationRadius = math.pow(math.huge, math.huge) * math.huge
    pcall(function()
        sethiddenproperty(LocalPlayer, "SimulationRadius", math.pow(math.huge, math.huge) * math.huge)
    end)

    for i, v in pairs(Players:GetPlayers()) do
        if v ~= LocalPlayer then
            LocalPlayer.MaximumSimulationRadius = math.pow(math.huge, math.huge) * math.huge
            pcall(function()
                settings().Physics.AllowSleep = false;
                sethiddenproperty(LocalPlayer, "SimulationRadius", math.pow(math.huge, math.huge) * math.huge)
            end)
            LocalPlayer.ReplicationFocus = workspace
        end
    end
end)

AddCommand("commands/cmds", "shows the command list in the console", function()
    CommandList.Visible = true

    local CommandsTween = TweenService:Create(CommandList, TweenInfo.new(.25, Enum.EasingStyle.Quint), {
        BackgroundTransparency = 0
    })
    CommandsTween:Play()

    CommandsTween.Completed:Wait()

    for _, Object in ipairs(CommandList.ScrollBar:GetDescendants()) do
        if Object.Name == "Container" then
            local TextLabelTween = TweenService:Create(Object.CommandName, TweenInfo.new(.025, Enum.EasingStyle.Quint),
                {
                    TextTransparency = 0
                })
            TextLabelTween:Play()

            local DescriptionTween = TweenService:Create(Object.CommandName.Description,
                TweenInfo.new(.025, Enum.EasingStyle.Quint), {
                    TextTransparency = 0
                })
            DescriptionTween:Play()

            DescriptionTween.Completed:Wait()
        end
    end
end)

AddCommand("quit/stopadmin/q", "stops the admin", function()
    for _, Event in pairs(Admin.Events) do
        Event:Disconnect();
    end

    UI:Destroy();

    getgenv().Running = false;

    warn("quit.")
end)

AddCommand("respawn/re", "refreshes your character", function()
    ReplaceCharacter();

    wait(Players.RespawnTime - .1);

    local SavedPosition = LocalPlayer.Character.HumanoidRootPart.CFrame;

    LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState(15);

    LocalPlayer.CharacterAdded:wait();
    LocalPlayer.Character:WaitForChild("HumanoidRootPart").CFrame = SavedPosition;
end)

AddCommand("resizeleg/leg", "resizes your leg", function()
    ResizeLeg();
end)

AddCommand("getmass/gmass", "refreshes your character", function(Caller, player)
    local Target = GetPlayer(Caller, player);

    if Target ~= nil then
        for _, Player in pairs(Target) do
            print(ReturnMass(Player.Character));
        end
    else
        print(ReturnMass(LocalPlayer.Character));
    end
end, "player")

AddCommand("goto", "teleports to a player", function(Caller, player)
    local Target = GetPlayer(Caller, player);

    if Target ~= nil then
        for _, Player in pairs(Target) do
            LocalPlayer.Character.HumanoidRootPart.CFrame = GetRoot(Player.Character).CFrame;
        end
    end
end, "player")

AddCommand("walkspeed/ws", "i swear to god if you dont know what this means", function(_, speed)
    LocalPlayer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = speed;
end, "speed")

AddCommand("jumppower/jp", "i swear to god if you dont know what this means", function(_, power)
    LocalPlayer.Character:FindFirstChildOfClass("Humanoid").JumpPower = power;
end, "power")

AddCommand("view", "views a player", function(Caller, player)
    local Target = GetPlayer(Caller, player);

    if Target ~= nil then
        for _, Player in pairs(Target) do
            workspace.CurrentCamera.CameraSubject = Player.Character:FindFirstChildOfClass("Humanoid");
        end
    end
end, "player")

AddCommand("unview", "unviews a player", function()
    workspace.CurrentCamera.CameraSubject = LocalPlayer.Character:FindFirstChildOfClass("Humanoid");
end)

AddCommand("fly", "flies your character", function(_, flyspeed)
    if Admin.CEvents.Flying == false then
        Admin.CEvents.Flying = true
        local Character = LocalPlayer.Character

        Character:FindFirstChildOfClass("Humanoid"):ChangeState(8)

        local BodyVelocity = Instance.new("BodyVelocity");
        local BodyGyro = Instance.new("BodyGyro");

        BodyVelocity.Parent = Character.HumanoidRootPart;
        BodyGyro.Parent = Character.HumanoidRootPart;

        BodyGyro.P = 9e9;
        BodyGyro.MaxTorque = Vector3.new(1, 1, 1) * 9e9;
        BodyGyro.CFrame = Character.HumanoidRootPart.CFrame;

        BodyVelocity.MaxForce = Vector3.new(1, 1, 1) * 9e9;
        BodyVelocity.Velocity = Vector3.new(0, 0.1, 0);

        local Speed = 2;

        if flyspeed then
            Speed = tonumber(flyspeed)
        end

        coroutine.wrap(function()
            while Admin.CEvents.Flying do
                FlyTable["W"] = Keys["W"] and Speed or 0
                FlyTable["A"] = Keys["A"] and -Speed or 0
                FlyTable["S"] = Keys["S"] and -Speed or 0
                FlyTable["D"] = Keys["D"] and Speed or 0

                if ((FlyTable["W"] + FlyTable["S"]) ~= 0 or (FlyTable["A"] + FlyTable["D"]) ~= 0) then
                    BodyVelocity.Velocity = ((workspace.Camera.CoordinateFrame.lookVector *
                                                (FlyTable["W"] + FlyTable["S"])) + ((workspace.Camera.CoordinateFrame *
                                                CFrame.new(FlyTable["A"] + FlyTable["D"],
                                                    (FlyTable["W"] + FlyTable["S"]) * 0.2, 0).p) -
                                                workspace.Camera.CoordinateFrame.p)) * 50
                else
                    BodyVelocity.Velocity = Vector3.new(0, 0.1, 0);
                end
                BodyGyro.CFrame = workspace.Camera.CoordinateFrame;
                task.wait();
            end

            BodyVelocity:Destroy()
            BodyGyro:Destroy()
        end)()
    end
end, "speed")

AddCommand("unfly", "stops flying", function()
    Admin.CEvents.Flying = not Admin.CEvents.Flying;
end)

AddCommand("rejoin/rj", "rejoins your server", function()
    game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer);
end)

AddCommand("grabchecker", "checks if anyone is using grabtools", function()
    local Tool = GetTool();

    if Tool then
        Tool.Parent = LocalPlayer.Character;

        Tool.Parent = workspace;

        local GrabCheckerConnection = Tool.AncestryChanged:Connect(function(_, Parent)
            local Character = Parent;

            local Player = Players:GetPlayerFromCharacter(Character);

            print(Player.DisplayName .. " is grabbing tools");
        end)

        task.delay(.5, function()
            GrabCheckerConnection:Disconnect();

            if Tool.Parent == workspace then
                LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):EquipTool(Tool);
            end
        end)
    end
end)

AddCommand("sync", "syncs all playing audios", function()
    for _, Audio in pairs(workspace:GetDescendants()) do
        coroutine.wrap(function()
            if Audio:IsA("Sound") then
                Audio.TimePosition = 0;
            end
        end)();
    end
end)

AddCommand("dupe/dupetools", "dupes your tools", function(_, amount)
    Admin.CEvents.Tools = {};

    for Duped = 1, amount do
        ReplaceCharacter();

        wait(Players.RespawnTime - .1);

        local Position = LocalPlayer.Character.HumanoidRootPart.CFrame

        for _, Tool in pairs(LocalPlayer.Backpack:GetChildren()) do
            Tool.Parent = LocalPlayer.Character;
        end

        for _, Tool in pairs(LocalPlayer.Character:GetChildren()) do
            if Tool:IsA("Tool") then
                Tool.Handle.Anchored = true;
                Tool.Parent = workspace;

                table.insert(Admin.CEvents.Tools, Tool)
            end
        end

        (LocalPlayer.Character:FindFirstChild("Right Arm") or LocalPlayer.Character:FindFirstChild("RightHand")):BreakJoints()

        LocalPlayer.Character:BreakJoints();

        LocalPlayer.CharacterAdded:Wait()
        LocalPlayer.Character:WaitForChild("HumanoidRootPart").CFrame = Position

        LocalPlayer.Character:WaitForChild("Humanoid");

        for Index, Tool in pairs(Admin.CEvents.Tools) do
            pcall(function()
                LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):EquipTool(Tool);

                Tool.Handle.Anchored = false;
            end);
        end
    end

    Admin.CEvents.Tools = {};
end, "amount")

AddCommand("jail", "works for only dollhouse rp", function(Caller, player)
    if game.PlaceId == 417267366 then
        local Target = GetPlayer(Caller, player);

        if Target ~= nil then
            if #Target == 1 and KillableCheck(Target[1].Character) == false then
                warn("could not jail " .. Target[1].Name);

                return;
            end

            local BEvents = {};

            local Position = LocalPlayer.Character.HumanoidRootPart.CFrame;

            ReplaceHumanoid();

            for _, Player in pairs(Target) do
                local Check = KillableCheck(Player.Character);
                local TouchInterest;

                if Check ~= false then
                    TouchInterest = Player.Character[Check];

                    local Tool = GetTool();

                    if Tool then
                        Tool.Parent = LocalPlayer.Character

                        AttachTool(Tool,
                            CFrame.new(5616.67969, 37.0454788, -17259.5176, 0.999995291, -6.67297755e-08, 0.00300924503,
                                6.65793536e-08, 1, 5.00816135e-08, -0.00300924503, -4.98810273e-08, 0.999995291));

                            BEvents[Tool] = Tool.AncestryChanged:Connect(function(LocalTool)
                                BEvents[Tool]:Disconnect();
        
                                LocalTool.Handle:BreakJoints();
                            end)

                        firetouchinterest(Tool.Handle, TouchInterest, 0);
                    end
                else
                    warn("could not jail " .. Player.Name)
                end
            end

            LocalPlayer.CharacterAdded:wait();
            LocalPlayer.Character:WaitForChild("HumanoidRootPart").CFrame = Position;
        end
    else
        warn("not dollhouse rp")
    end
end, "player")

AddCommand("bathroom", "works for only dollhouse rp", function(Caller, player)
    if game.PlaceId == 417267366 then
        local Target = GetPlayer(Caller, player);

        if Target ~= nil then
            if #Target == 1 and KillableCheck(Target[1].Character) == false then
                warn("could not bathroom " .. Target[1].Name);

                return;
            end

            local BEvents = {};

            local Position = LocalPlayer.Character.HumanoidRootPart.CFrame;

            ReplaceHumanoid();

            for _, Player in pairs(Target) do
                local Check = KillableCheck(Player.Character);
                local TouchInterest;

                if Check ~= false then
                    TouchInterest = Player.Character[Check];

                    local Tool = GetTool();

                    if Tool then
                        Tool.Parent = LocalPlayer.Character

                        AttachTool(Tool, game:GetService("Workspace")["Bathroom Toilet"].Seat.CFrame);

                        BEvents[Tool] = Tool.AncestryChanged:Connect(function(LocalTool)
                            BEvents[Tool]:Disconnect();
    
                            LocalTool.Handle:BreakJoints();
                        end)

                        firetouchinterest(Tool.Handle, TouchInterest, 0);

                    end
                else
                    warn("could not bathroom " .. Player.Name)
                end
            end

            LocalPlayer.CharacterAdded:wait();
            LocalPlayer.Character:WaitForChild("HumanoidRootPart").CFrame = Position;
        end
    else
        warn("not dollhouse rp")
    end
end, "player")

AddCommand("kill", "kills a player", function(Caller, player)
    local Target = GetPlayer(Caller, player);

    if Target ~= nil then
        if #Target == 1 and KillableCheck(Target[1].Character) == false then
            warn("could not kill " .. Target[1].Name);

            return;
        end

        local BEvents = {};

        ReplaceHumanoid();

        local Position = LocalPlayer.Character.HumanoidRootPart.CFrame;

        for _, Player in pairs(Target) do
            local Check = KillableCheck(Player.Character);
            local TouchInterest;

            if Check ~= false then
                TouchInterest = Player.Character[Check];

                local Tool = GetTool();

                if Tool then
                    Tool.Parent = LocalPlayer.Character;

                    AttachTool(Tool, TouchInterest.CFrame);

                    BEvents[Tool] = Tool.AncestryChanged:Connect(function(LocalTool)
                        BEvents[Tool]:Disconnect();

                        LocalTool.Handle:BreakJoints();
                    end)

                    firetouchinterest(Tool.Handle, TouchInterest, 0);
                end
            else
                warn("could not kill " .. Player.Name);
            end
        end

        local R15 = LocalPlayer.Character:FindFirstChildOfClass("Humanoid").RigType == Enum.HumanoidRigType.R15;

        LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState(15);
        LocalPlayer.Character = nil;

        if not R15 then
            workspace:FindFirstChild(LocalPlayer.Name):BreakJoints();
        end

        LocalPlayer.CharacterAdded:wait();
        LocalPlayer.Character:WaitForChild("HumanoidRootPart").CFrame = Position;
    end
end, "player")

AddCommand("walkkill/wkill", "kills the player while you have less mass", function(Caller, player)
    local Target = GetPlayer(Caller, player);

    if Target ~= nil then
        if #Target == 1 and KillableCheck(Target[1].Character) == false then
            warn("could not kill " .. Target[1].Name);

            return;
        end

        ReplaceHumanoid();

        local Position = LocalPlayer.Character.HumanoidRootPart.CFrame;

        LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(0, 1e2 * 5, 1e4)

        for _, Player in pairs(Target) do
            local Check = KillableCheck(Player.Character);
            local TouchInterest;

            if Check ~= false then
                TouchInterest = Player.Character[Check];

                local Tool = GetTool();

                if Tool then
                    Tool.Parent = LocalPlayer.Character;

                    Tool.Handle.Position = TouchInterest.Position;

                    firetouchinterest(Tool.Handle, TouchInterest, 0);
                end
            else
                warn("could not wkill " .. Player.Name  );
            end
        end

        LocalPlayer.CharacterAdded:wait();
        LocalPlayer.Character:WaitForChild("HumanoidRootPart").CFrame = Position;
    end
end, "player")

AddCommand("fastkill/fkill", "fast kills a player", function(Caller, player)
    local Target = GetPlayer(Caller, player);

    if Target ~= nil then
        if #Target == 1 and KillableCheck(Target[1].Character) == false then
            warn("could not kill " .. Target[1].Name);

            return;
        end

        ReplaceCharacter()

        wait(Players.RespawnTime - .1);

        local Position = LocalPlayer.Character.HumanoidRootPart.CFrame;

        local BEvents = {};

        ReplaceHumanoid();

        for _, Player in pairs(Target) do
            local Check = KillableCheck(Player.Character);
            local TouchInterest;

            if Check ~= false then
                TouchInterest = Player.Character[Check];

                local Tool = GetTool();

                if Tool then
                    Tool.Parent = LocalPlayer.Character;

                    AttachTool(Tool, TouchInterest.CFrame);

                    BEvents[Tool] = Tool.AncestryChanged:Connect(function(LocalTool)
                        BEvents[Tool]:Disconnect();

                        LocalTool.Handle:BreakJoints();
                    end)

                    firetouchinterest(Tool.Handle, TouchInterest, 0);
                end
            else
                warn("could not kill " .. Player.Name);
            end
        end

        LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState(15);
        LocalPlayer.Character = nil;

        LocalPlayer.CharacterAdded:wait();
        LocalPlayer.Character:WaitForChild("HumanoidRootPart").CFrame = Position;
    end
end, "player")

AddCommand("masskill/mkill", "mass kills a player", function(Caller, player)
    local Target = GetPlayer(Caller, player);

    if Target ~= nil then
        if LocalPlayer.Character.Humanoid.RigType == Enum.HumanoidRigType.R6 then
            warn("not r15")

            return
        end

        local BEvents = {};

        local Position = LocalPlayer.Character.HumanoidRootPart.CFrame;

        ResizeLeg();

        ReplaceHumanoid();

        for _, Player in pairs(Target) do
            local TouchInterest = "Head";

            TouchInterest = Player.Character[TouchInterest];

            local Tool = GetTool();

            if Tool then
                Tool.Parent = LocalPlayer.Character;

                firetouchinterest(Tool.Handle, TouchInterest, 0);

                AttachTool(Tool, GetRoot(Player.Character).CFrame);

                BEvents[Tool] = Tool.AncestryChanged:Connect(function(LocalTool)
                    BEvents[Tool]:Disconnect();

                    LocalPlayer.Character:BreakJoints();
                end)
            end
        end

        LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState(15);

        LocalPlayer.CharacterAdded:wait();
        LocalPlayer.Character:WaitForChild("HumanoidRootPart").CFrame = Position;
    end
end, "player")

AddCommand("bring", "brings a player", function(Caller, player)
    local Target = GetPlayer(Caller, player);

    if Target ~= nil then
        if #Target == 1 and KillableCheck(Target[1].Character) == false then
            warn("could not bring " .. Target[1].Name);

            return;
        end

        local BEvents = {};

        local Position = LocalPlayer.Character.HumanoidRootPart.CFrame;

        ReplaceHumanoid();

        for _, Player in pairs(Target) do
            local Check = KillableCheck(Player.Character);
            local TouchInterest;

            if Check ~= false then
                TouchInterest = Player.Character[Check];

                local Tool = GetTool();

                if Tool then
                    Tool.Parent = LocalPlayer.Character

                    AttachTool(Tool, Caller.Character.HumanoidRootPart.CFrame);

                    BEvents[Tool] = Tool.AncestryChanged:Connect(function(LocalTool)
                        BEvents[Tool]:Disconnect();

                        LocalTool.Handle:BreakJoints();
                    end)

                    firetouchinterest(Tool.Handle, TouchInterest, 0);

                end
            else
                warn("could not bring " .. Player.Name)
            end
        end

        LocalPlayer.CharacterAdded:wait();
        LocalPlayer.Character:WaitForChild("HumanoidRootPart").CFrame = Position;
    end
end, "player")

AddCommand("fastbring/fbring", "fast brings a player", function(Caller, player)
    local Target = GetPlayer(Caller, player);

    if Target ~= nil then
        if #Target == 1 and KillableCheck(Target[1].Character) == false then
            warn("could not bring " .. Target[1].Name);

            return;
        end

        local BEvents = {};

        ReplaceCharacter()

        wait(Players.RespawnTime - .1);

        local Position = LocalPlayer.Character.HumanoidRootPart.CFrame;

        ReplaceHumanoid();

        for _, Player in pairs(Target) do
            local Check = KillableCheck(Player.Character);
            local TouchInterest;

            if Check ~= false then
                TouchInterest = Player.Character[Check];

                local Tool = GetTool();

                if Tool then
                    Tool.Parent = LocalPlayer.Character

                    AttachTool(Tool, Caller.Character.HumanoidRootPart.CFrame);

                    BEvents[Tool] = Tool.AncestryChanged:Connect(function(LocalTool)
                        BEvents[Tool]:Disconnect();

                        LocalTool.Handle:BreakJoints();
                    end)

                    firetouchinterest(Tool.Handle, TouchInterest, 0);

                end
            else
                warn("could not bring " .. Player.Name);
            end
        end

        LocalPlayer.CharacterAdded:wait();
        LocalPlayer.Character:WaitForChild("HumanoidRootPart").CFrame = Position;
    end
end, "player")

AddCommand("void", "voids a player", function(Caller, player)
    local Target = GetPlayer(Caller, player);

    if Target ~= nil then

        local BEvents = {};

        workspace.FallenPartsDestroyHeight = 0 / 0;

        ReplaceHumanoid();

        LocalPlayer.Character:SetPrimaryPartCFrame(CFrame.new(0, -501.5, 0));

        for _, Player in pairs(Target) do
            local Check = KillableCheck(Player.Character);
            local TouchInterest;

            if Check ~= false then
                TouchInterest = Player.Character[Check];

                local Tool = GetTool();

                if Tool then
                    Tool.Parent = LocalPlayer.Character

                    firetouchinterest(Tool.Handle, TouchInterest, 0);
                end
            else
                warn("could not void " .. Player.Name);
            end
        end

        workspace.FallenPartsDestroyHeight = -506
    end
end, "player")

AddCommand("massvoid/mvoid", "mass voids a player", function(Caller, player)
    local Target = GetPlayer(Caller, player);

    if Target ~= nil then
        if LocalPlayer.Character.Humanoid.RigType == Enum.HumanoidRigType.R6 then
            warn("not r15")

            return
        end

        local BEvents = {};

        local Position = LocalPlayer.Character.HumanoidRootPart.CFrame;

        ResizeLeg();

        workspace.FallenPartsDestroyHeight = 0 / 0;

        ReplaceHumanoid();

        LocalPlayer.Character:SetPrimaryPartCFrame(CFrame.new(0, -500, 0));

        for _, Player in pairs(Target) do
            local TouchInterest = "Head";

            TouchInterest = Player.Character[TouchInterest];

            local Tool = GetTool();

            if Tool then
                Tool.Parent = LocalPlayer.Character;

                firetouchinterest(Tool.Handle, TouchInterest, 0);
            end
        end

        workspace.FallenPartsDestroyHeight = -506

        LocalPlayer.CharacterAdded:wait();
        LocalPlayer.Character:WaitForChild("HumanoidRootPart").CFrame = Position;
    end
end, "player")

AddCommand("punish", "punishes a player", function(Caller, player)
    local Target = GetPlayer(Caller, player);

    if Target ~= nil then
        ReplaceHumanoid();

        LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(0, 9e9, 0)

        for _, Player in pairs(Target) do
            local Check = KillableCheck(Player.Character);
            local TouchInterest;

            if Check ~= false then
                TouchInterest = Player.Character[Check];

                local Tool = GetTool();

                if Tool then
                    Tool.Parent = LocalPlayer.Character;

                    firetouchinterest(Tool.Handle, TouchInterest, 0);
                end
            else
                warn("could not punish " .. Player.Name);
            end
        end
    end
end, "player")

AddCommand("attach", "attaches a player", function(Caller, player)
    local Target = GetPlayer(Caller, player);

    if Target ~= nil then
        ReplaceHumanoid();

        for _, Player in pairs(Target) do
            local Check = KillableCheck(Player.Character);
            local TouchInterest;

            if Check ~= false then
                TouchInterest = Player.Character[Check];

                local Tool = GetTool();

                if Tool then
                    Tool.Parent = LocalPlayer.Character;

                    firetouchinterest(Tool.Handle, TouchInterest, 0);
                end
            else
                warn("could not punish " .. Player.Name);
            end
        end
    end
end, "player")

AddCommand("massattach/mattach", "mass attaches a player", function(Caller, player)
    local Target = GetPlayer(Caller, player);

    if Target ~= nil then
        ResizeLeg();

        ReplaceHumanoid();

        for _, Player in pairs(Target) do
            local Check = KillableCheck(Player.Character);
            local TouchInterest;

            if Check ~= false then
                TouchInterest = Player.Character[Check];

                local Tool = GetTool();

                if Tool then
                    Tool.Parent = LocalPlayer.Character;

                    firetouchinterest(Tool.Handle, TouchInterest, 0);
                end
            else
                warn("could not punish " .. Player.Name);
            end
        end
    end
end, "player")

AddCommand("control", "controls a player for " .. tostring(Players.RespawnTime) .. " seconds", function(Caller, player)
    local Target = GetPlayer(Caller, player);

    if Target ~= nil and #Target == 1 then
        local Position = LocalPlayer.Character:WaitForChild("HumanoidRootPart").CFrame;

        ReplaceHumanoid();

        local BEvent;

        local Noclip = RunService.Stepped:Connect(function()
            for _, BPart in pairs(LocalPlayer.Character:GetChildren()) do
                if BPart:IsA("BasePart") then
                    BPart.CanCollide = false;
                end
            end
        end)

        local Velocity = game:GetService("RunService").Heartbeat:Connect(function()
            LocalPlayer.Character.HumanoidRootPart.Velocity = LocalPlayer.Character.Humanoid.MoveDirection * 20;
        end)

        for _, Player in pairs(Target) do
            local Check = KillableCheck(Player.Character);
            local TouchInterest;

            if Check ~= false then
                TouchInterest = Player.Character[Check];

                local Tool = GetTool();

                if Tool then
                    Tool.Parent = LocalPlayer.Character;

                    local VPos = Player.Character.HumanoidRootPart.Position;

                    Tool.Handle.CanCollide = false;

                    AttachTool(Tool, LocalPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(1.5, 10, 0) *
                        CFrame.Angles(0, math.rad(90), 0));

                    firetouchinterest(Tool.Handle, TouchInterest, 0);

                    BEvent = Tool.AncestryChanged:Connect(function()
                        BEvent:Disconnect();

                        LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(VPos) * CFrame.new(0, -10, 0);

                        workspace.CurrentCamera.CameraSubject = Player.Character.Humanoid;
                    end)
                end
            else
                warn("could not control " .. Player.Name);
            end
        end

        LocalPlayer.CharacterAdded:wait();
        LocalPlayer.Character:WaitForChild("HumanoidRootPart").CFrame = Position;

        Noclip:Disconnect();
        Velocity:Disconnect();
    end
end, "player")

AddCommand("infinitecontrol/icontrol", "controls a player for infinity", function(Caller, player)
    local Target = GetPlayer(Caller, player);

    if Target ~= nil and #Target == 1 then
        local Position = LocalPlayer.Character:WaitForChild("HumanoidRootPart").CFrame;

        Admin.CEvents.InfiniteControlEvent = LocalPlayer.CharacterAdded:Connect(function()
            LocalPlayer.Character:WaitForChild("HumanoidRootPart").CFrame = Position;

            wait(.25);

            ReplaceHumanoid();

            local BEvent;

            local Noclip = RunService.Stepped:Connect(function()
                for _, BPart in pairs(LocalPlayer.Character:GetChildren()) do
                    if BPart:IsA("BasePart") then
                        BPart.CanCollide = false;
                    end
                end
            end)

            local Velocity = game:GetService("RunService").Heartbeat:Connect(function()
                LocalPlayer.Character.HumanoidRootPart.Velocity = LocalPlayer.Character.Humanoid.MoveDirection * 20;
            end)

            for _, Player in pairs(Target) do
                if Player.Character:FindFirstChild("Head") then
                    local Check = KillableCheck(Player.Character);
                    local TouchInterest;

                    if Check ~= false then
                        TouchInterest = Player.Character[Check];

                        local Tool = GetTool();

                        if Tool then
                            Tool.Parent = LocalPlayer.Character;

                            local VPos = Player.Character.HumanoidRootPart.Position + Vector3.new(0, 2.5, 0);

                            Tool.Handle.CanCollide = false;

                            AttachTool(Tool, LocalPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(1.5, 10, 0) *
                                CFrame.Angles(0, math.rad(90), 0));

                            firetouchinterest(Tool.Handle, TouchInterest, 0);

                            BEvent = Tool.AncestryChanged:Connect(function()
                                BEvent:Disconnect();

                                LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(VPos) * CFrame.new(0, -10, 0);

                                workspace.CurrentCamera.CameraSubject = Player.Character.Humanoid;
                            end)
                        end
                    else
                        warn("could not control " .. Player.Name);
                    end
                end
            end

            LocalPlayer.CharacterAdded:wait();

            Noclip:Disconnect();
            Velocity:Disconnect();
        end)

        LocalPlayer.Character:WaitForChild("Humanoid");

        ReplaceHumanoid();

        local BEvent;

        local Noclip = RunService.Stepped:Connect(function()
            for _, BPart in pairs(LocalPlayer.Character:GetChildren()) do
                if BPart:IsA("BasePart") then
                    BPart.CanCollide = false;
                end
            end
        end)

        local Velocity = game:GetService("RunService").Heartbeat:Connect(function()
            LocalPlayer.Character.HumanoidRootPart.Velocity = LocalPlayer.Character.Humanoid.MoveDirection * 20;
        end)

        for _, Player in pairs(Target) do
            local Check = KillableCheck(Player.Character);
            local TouchInterest;

            if Check ~= false then
                TouchInterest = Player.Character[Check];

                local Tool = GetTool();

                if Tool then
                    Tool.Parent = LocalPlayer.Character;

                    local VPos = Player.Character.HumanoidRootPart.Position;

                    Tool.Handle.CanCollide = false;

                    AttachTool(Tool, LocalPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(1.5, 10, 0) *
                        CFrame.Angles(0, math.rad(90), 0));

                    firetouchinterest(Tool.Handle, TouchInterest, 0);

                    BEvent = Tool.AncestryChanged:Connect(function()
                        BEvent:Disconnect();

                        LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(VPos) * CFrame.new(0, -10, 0);

                        workspace.CurrentCamera.CameraSubject = Player.Character.Humanoid;
                    end)
                end
            else
                warn("could not control " .. Player.Name);
            end
        end

        LocalPlayer.CharacterAdded:Wait();

        Noclip:Disconnect();
        Velocity:Disconnect();
    end
end, "player")

AddCommand("uninfintecontrol/unicontrol/uncontrol", "stops controlling", function()
    if Admin.CEvents.InfiniteControlEvent then
        Admin.CEvents.InfiniteControlEvent:Disconnect();
    end
end)

AddCommand("skydive", "skydives a player", function(Caller, player, studs)
    local Target = GetPlayer(Caller, player);

    if Target ~= nil then
        if #Target == 1 and KillableCheck(Target[1].Character) == false then
            warn("could not skydive " .. Target[1].Name);

            return;
        end

        local BEvents = {};

        local Position = LocalPlayer.Character.HumanoidRootPart.CFrame;

        ReplaceHumanoid();

        for _, Player in pairs(Target) do
            local Check = KillableCheck(Player.Character);
            local TouchInterest;

            if Check ~= false then
                TouchInterest = Player.Character[Check];

                local Tool = GetTool();

                if Tool then
                    Tool.Parent = LocalPlayer.Character

                    AttachTool(Tool, Player.Character.HumanoidRootPart.CFrame * CFrame.new(0, studs or 800, 0));

                    BEvents[Tool] = Tool.AncestryChanged:Connect(function(LocalTool)
                        BEvents[Tool]:Disconnect();

                        LocalTool.Handle:BreakJoints();
                    end)

                    firetouchinterest(Tool.Handle, TouchInterest, 0);

                end
            else
                warn("could not skydive " .. Player.Name)
            end
        end

        LocalPlayer.CharacterAdded:wait();
        LocalPlayer.Character:WaitForChild("HumanoidRootPart").CFrame = Position;
    end
end, "player, studs")

AddCommand("sink", "sinks a player", function(Caller, player)
    local Target = GetPlayer(Caller, player);

    if Target ~= nil then
        if #Target == 1 and KillableCheck(Target[1].Character) == false then
            warn("could not sink " .. Target[1].Name);

            return;
        end

        local BEvents = {};

        local Position = LocalPlayer.Character.HumanoidRootPart.CFrame;

        local Noclip = RunService.Stepped:Connect(function()
            for _, BPart in pairs(LocalPlayer.Character:GetChildren()) do
                if BPart:IsA("BasePart") then
                    BPart.CanCollide = false;
                end
            end
        end)

        ReplaceHumanoid();

        for _, Player in pairs(Target) do
            local Check = KillableCheck(Player.Character);
            local TouchInterest;

            if Check ~= false then
                TouchInterest = Player.Character[Check];

                local Tool = GetTool();

                if Tool then
                    Tool.Parent = LocalPlayer.Character

                    AttachTool(Tool, Player.Character.HumanoidRootPart.CFrame);

                    firetouchinterest(Tool.Handle, TouchInterest, 0);

                end
            else
                warn("could not sink " .. Player.Name)
            end
        end

        task.delay(.25, function()
            for _, Event in pairs(BEvents) do
                Event:Disconnect();
                Event = nil;
            end
        end)

        wait(.15);

        local Tween = TweenService:Create(LocalPlayer.Character.HumanoidRootPart,
            TweenInfo.new(2.5, Enum.EasingStyle.Linear), {
                CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(0, -15, 0)
            });

        Tween:Play();

        LocalPlayer.CharacterAdded:wait();
        LocalPlayer.Character:WaitForChild("HumanoidRootPart").CFrame = Position;

        Noclip:Disconnect();
    end
end, "player")

AddCommand("kidnap", "kidnaps a player", function(Caller, player)
    local Target = GetPlayer(Caller, player);

    if Target ~= nil then
        if #Target == 1 and KillableCheck(Target[1].Character) == false then
            warn("could not kidnap " .. Target[1].Name);

            return;
        end

        if #Target > 1 then
            return;
        end

        local Position = LocalPlayer.Character.HumanoidRootPart.CFrame;

        local Noclip = RunService.Stepped:Connect(function()
            for _, BPart in pairs(LocalPlayer.Character:GetChildren()) do
                if BPart:IsA("BasePart") then
                    BPart.CanCollide = false;
                end
            end
        end)

        local Player = Target[1];

        ReplaceHumanoid();

        LocalPlayer.Character.HumanoidRootPart.CFrame = Player.Character.HumanoidRootPart.CFrame * CFrame.new(25, 0, -5) * CFrame.Angles(0, math.rad(90), 0);

        local Tween = TweenService:Create(LocalPlayer.Character.HumanoidRootPart, TweenInfo.new(1.5, Enum.EasingStyle.Linear), {CFrame = Player.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -5) * CFrame.Angles(0, math.rad(90), 0);})

        Tween:Play();
        Tween.Completed:wait();

        wait(.5);

        local Tool = GetTool();

        if Tool then
            Tool.Parent = LocalPlayer.Character;

            AttachTool(Tool, LocalPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(1.5, 2.5, 0) * CFrame.Angles(math.rad(-90), math.rad(0), math.rad(-90)))

            firetouchinterest(Tool.Handle, Player.Character.Head, 0);

            Tool.AncestryChanged:wait();
        end

        wait(.25);

        local Tween = TweenService:Create(LocalPlayer.Character.HumanoidRootPart, TweenInfo.new(2.25, Enum.EasingStyle.Linear), {CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -100)});

        Tween:Play();
        Tween.Completed:wait();

        LocalPlayer.Character.Humanoid:ChangeState(15);
        LocalPlayer.Character = nil;

        LocalPlayer.CharacterAdded:wait();
        LocalPlayer.Character:WaitForChild("HumanoidRootPart").CFrame = Position;

        Noclip:Disconnect();
    end
end, "player")


AddCommand("fling", "flings a player", function(Caller, player)
    local Target = GetPlayer(Caller, player);

    if Target ~= nil then
        local Position, Velocity = LocalPlayer.Character.HumanoidRootPart.CFrame,
            LocalPlayer.Character.HumanoidRootPart.Velocity;

        for _, Player in pairs(Target) do
            local PPosition = GetRoot(Player.Character).Position;

            local Running = RunService.Stepped:Connect(function(step)
                step = step - workspace.DistributedGameTime;

                GetRoot(LocalPlayer.Character).CFrame = (GetRoot(Player.Character).CFrame -
                                                            (Vector3.new(0, 1e6, 0) * step)) +
                                                            (GetRoot(Player.Character).Velocity * (step * 30));
                GetRoot(LocalPlayer.Character).Velocity = Vector3.new(0, 1e6, 0)
            end)

            local STime = tick();

            repeat
                wait();

            until (PPosition - GetRoot(Player.Character).Position).Magnitude >= 60 or tick() - STime >= 1;

            Running:Disconnect();

            GetRoot(LocalPlayer.Character).Velocity = Velocity;
            GetRoot(LocalPlayer.Character).CFrame = Position;

            wait();
        end

        local Running = RunService.Stepped:Connect(function()
            GetRoot(LocalPlayer.Character).Velocity = Velocity;
            GetRoot(LocalPlayer.Character).CFrame = Position;
        end)

        wait(2);

        GetRoot(LocalPlayer.Character).Anchored = true

        Running:Disconnect();

        GetRoot(LocalPlayer.Character).Anchored = false

        GetRoot(LocalPlayer.Character).Velocity = Velocity;
        GetRoot(LocalPlayer.Character).CFrame = Position;
    end
end, "player")

AddCommand("massfling/mfling", "mass flings a player", function(Caller, player)
    local Target = GetPlayer(Caller, player);

    if Target ~= nil then
        if LocalPlayer.Character.Humanoid.RigType == Enum.HumanoidRigType.R6 then
            warn("not r15")

            return
        end

        ResizeLeg();

        ReplaceHumanoid();

        local Position = LocalPlayer.Character.HumanoidRootPart.CFrame;

        for _, Player in pairs(Target) do
            local TouchInterest = "Head";

            TouchInterest = Player.Character[TouchInterest];

            local Tool = GetTool();

            if Tool then
                Tool.Parent = LocalPlayer.Character;

                firetouchinterest(Tool.Handle, TouchInterest, 0);
            end
        end

        local BodyVelocity = Instance.new("BodyAngularVelocity");

        BodyVelocity.MaxTorque = Vector3.new(1, 1, 1) * math.huge
        BodyVelocity.P = math.huge
        BodyVelocity.AngularVelocity = Vector3.new(1, 1, 1) * 1e5;
        BodyVelocity.Parent = GetRoot(LocalPlayer.Character);

        LocalPlayer.CharacterAdded:wait();
        LocalPlayer.Character:WaitForChild("HumanoidRootPart").CFrame = Position;
    end
end, "player")

AddCommand("teleport/tp", "teleports a player to another", function(Caller, player, player2)
    local Humanoid
    local Target = GetPlayer(Caller, player)
    local TeleportedTo = GetPlayer(Caller, player2)
    local Position = LocalPlayer.Character:WaitForChild("HumanoidRootPart").CFrame

    if Target ~= nil and TeleportedTo ~= nil then
        if #Target > 1 then
            return
        end

        ReplaceHumanoid();

        local BEvents = {};

        for _, Player in pairs(Target) do
            local Check = KillableCheck(Player.Character);
            local TouchInterest;

            if Check ~= false then
                TouchInterest = Player.Character[Check];

                local Tool = GetTool();

                if Tool then
                    Tool.Parent = LocalPlayer.Character

                    AttachTool(Tool, TeleportedTo[1].Character.HumanoidRootPart.CFrame);

                    BEvents[Tool] = Tool.AncestryChanged:Connect(function(LocalTool)
                        BEvents[Tool]:Disconnect();

                        LocalTool.Handle:BreakJoints();
                    end)

                    firetouchinterest(Tool.Handle, TouchInterest, 0);

                end
            else
                warn("could not teleport " .. Player.Name)
            end
        end

        LocalPlayer.CharacterAdded:wait();
        LocalPlayer.Character:WaitForChild("HumanoidRootPart").CFrame = Position;
    end
end, "player, player2")

AddCommand("equiptools/etools", "equips all the tools", function()
    for _, Tool in pairs(LocalPlayer.Backpack:GetChildren()) do
        Tool.Parent = LocalPlayer.Character;
    end
end)

AddCommand("handto/givetool", "gives the toold you are holding to another person", function(Caller, player)
    local Target = GetPlayer(Caller, player);

    if Target ~= nil then

        local Position = LocalPlayer.Character.HumanoidRootPart.CFrame;

        ReplaceHumanoid();

        for _, Player in pairs(Target) do
            local TouchInterest = Player.Character.Head;

            for _, Tool in pairs(LocalPlayer.Character:GetChildren()) do
                if Tool:IsA("Tool") and Tool:FindFirstChild("Handle") then
                    firetouchinterest(Tool.Handle, TouchInterest, 0);
                end
            end
        end

        LocalPlayer.Character:BreakJoints();

        LocalPlayer.CharacterAdded:wait();
        LocalPlayer.Character:WaitForChild("HumanoidRootPart").CFrame = Position;
    end
end, "player")

AddCommand("mute", "mutes a player", function(Caller, player)
    local Target = GetPlayer(Caller, player);

    if Target ~= nil and game:GetService("SoundService").RespectFilteringEnabled == false then
        for _, Player in pairs(Target) do
            for _, Object in pairs(Player.Character:GetDescendants()) do
                if Object:IsA("Sound") then
                    Object.Volume = 0;
                end
            end
        end
    end
end, "player")

AddCommand("whitelist/wl", "whitelists a player", function(Caller, player)
    local Target = GetPlayer(Caller, player);

    if Target ~= nil then
        for _, Player in pairs(Target) do
            table.insert(Admin.CEvents.Whitelisted, Player.UserId);

            ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer("/w " .. Player.Name ..
                                                                                           " You have been whitelisted to moon admin, use the prefix " ..
                                                                                           Admin.Prefix ..
                                                                                           " to get started.", "All");
        end
    end
end, "player")

table.sort(Admin.Commands, function(FirstElement, NextElement)
    return FirstElement[1]:lower() < NextElement[1]:lower()
end)

for _, Command in ipairs(Admin.Commands) do
    local clonedContainer = Container:Clone()

    if Command[4] then
        clonedContainer.CommandName.Text = Command[1] .. " { " .. Command[4] .. " }"
    else
        clonedContainer.CommandName.Text = Command[1]
    end

    clonedContainer.CommandName.Description.Text = Command[2]

    clonedContainer.Parent = CommandList.ScrollBar
end
