-- CONFIGURATION
local targetUsernames = getgenv().targets -- {"user1", "user2"}

local modelId = 110321462359232 --104515922403348 
local heightOffset = 3
local idleAnimationId = 101907348895136
local runAnimationId = 100466662502744
local landingAnimationId = 91194170893496
local landingSoundId = 82613796053949
local impactSoundId = 74149238738530
local ambienceSoundIds = {105438678078526, 92139743699536, 82618476532926}
local landingCooldown = 10
local toolGripOffset = CFrame.new(0, -0.4, 0) * CFrame.Angles(math.rad(180), math.rad(0), math.rad(90))

-- Clean up any previous run (all targets)
if _G.morphCleanupAll then
    pcall(_G.morphCleanupAll)
end

game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "Credits",
    Text = "Made by Homelessman2 and Lolcat_hitz.",
    Duration = 5
})

task.wait(0.5)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local localPlayer = Players.LocalPlayer

local activeMorphs = {} -- [username] = cleanupFunction

---------------------------------------------------------------------
-- Creates one morph for one player. Returns a cleanup function.
---------------------------------------------------------------------
local function createMorph(targetUsername)
    local targetPlayer = Players:FindFirstChild(targetUsername)
    if not targetPlayer then
        warn("Target player ('" .. targetUsername .. "') not found in server!")
        return nil
    end

    local isLocalUserTarget = (localPlayer == targetPlayer)
    local isThirdPerson = false

    if isLocalUserTarget then
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Speed Bypass",
            Text = "Use mspaint's or vynixus speed bypass and set speed to 45",
            Duration = 10
        })
    end

    local objects = game:GetObjects("rbxassetid://" .. modelId)
    local morph = objects[1]
    if not morph then return nil end

    local originalCharacter = targetPlayer.Character or targetPlayer.CharacterAdded:Wait()
    local originalRootPart = originalCharacter:WaitForChild("HumanoidRootPart")
    local originalHumanoid = originalCharacter:FindFirstChildWhichIsA("Humanoid")
    local originalHeadPart = originalCharacter:FindFirstChild("Head")
    if not originalRootPart or not originalHumanoid then
        morph:Destroy()
        return nil
    end

    local originalWalkSpeed = originalHumanoid.WalkSpeed
    local originalJumpPower = originalHumanoid.JumpPower
    local originalJumpHeight = originalHumanoid.JumpHeight
    local lastLandingTime = 0

    local morphHumanoid = morph:FindFirstChildWhichIsA("Humanoid")
    if morphHumanoid then morphHumanoid:Destroy() end

    for _, part in ipairs(morph:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Anchored = false
            part.CanCollide = false
        end
    end

    local morphRootPart = morph:FindFirstChild("HumanoidRootPart", true) or morph:FindFirstChild("RootPart", true)
    if not morphRootPart then
        morphRootPart = Instance.new("Part")
        morphRootPart.Name = "HumanoidRootPart"
        morphRootPart.Size = Vector3.new(2, 1, 1)
        morphRootPart.Anchored = false
        morphRootPart.CanCollide = false
        morphRootPart.Parent = morph
    end
    morph.PrimaryPart = morphRootPart

    local morphHeadPart = morph:FindFirstChild("Head", true)
    if not morphHeadPart then
        morphHeadPart = Instance.new("Part")
        morphHeadPart.Name = "Head"
        morphHeadPart.Size = Vector3.new(1, 1, 1)
        morphHeadPart.Anchored = false
        morphHeadPart.CanCollide = false
        morphHeadPart.Parent = morph
    end

    morph.Name = "Morph_" .. targetUsername
    morph.Parent = workspace

    for _, part in ipairs(originalCharacter:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Transparency = 1
            part.CanCollide = false
        elseif part:IsA("Accessory") then
            local handle = part:FindFirstChild("Handle")
            if handle then handle.Transparency = 1 end
        end
    end

    local rootWeld = Instance.new("Weld")
    rootWeld.Part0 = originalRootPart
    rootWeld.Part1 = morphRootPart
    rootWeld.C0 = CFrame.new(0, heightOffset, 0)
    rootWeld.Parent = originalRootPart

    local headWeld = Instance.new("Weld")
    headWeld.Part0 = originalHeadPart or originalRootPart
    headWeld.Part1 = morphHeadPart
    local headWeldOffset = morphHeadPart.Position - (originalHeadPart and originalHeadPart.Position or originalRootPart.Position)
    headWeld.C0 = CFrame.new(headWeldOffset)
    headWeld.Parent = headWeld.Part0

    local camera = workspace.CurrentCamera
    if isLocalUserTarget and camera then
        camera.CameraType = Enum.CameraType.Scriptable
    end

    local enforceLoop = RunService.RenderStepped:Connect(function()
        if rootWeld and rootWeld.Parent then
            rootWeld.C0 = CFrame.new(0, heightOffset, 0)
        end

        if isLocalUserTarget and camera and morphHeadPart and morphHeadPart:IsDescendantOf(workspace) then
            local lookVector = camera.CFrame.LookVector
            local upVector = camera.CFrame.UpVector
            local headPos = morphHeadPart.Position

            if isThirdPerson then
                local camPos = headPos - (lookVector * 12) + Vector3.new(0, 2, 0)
                camera.CFrame = CFrame.lookAt(camPos, headPos, upVector)
            else
                local offset = Vector3.new(0, 0.2, -0.5)
                local targetPosition = morphHeadPart.CFrame:PointToWorldSpace(offset)
                camera.CFrame = CFrame.lookAt(targetPosition, targetPosition + lookVector, upVector)
            end
        end

        local morphRightHand = morph:FindFirstChild("RightHand", true)
        if originalCharacter and morphRightHand then
            for _, tool in ipairs(originalCharacter:GetChildren()) do
                if tool:IsA("Tool") then
                    local handle = tool:FindFirstChild("Handle")
                    if handle then
                        for _, gripName in ipairs({"RightGrip", "LeftGrip"}) do
                            local grip = handle:FindFirstChild(gripName)
                            if grip then
                                if grip:IsA("Motor6D") then
                                    grip.Enabled = false
                                else
                                    grip:Destroy()
                                end
                            end
                        end

                        local morphWeld = handle:FindFirstChild("MorphWeld")
                        if not morphWeld then
                            morphWeld = Instance.new("Weld")
                            morphWeld.Name = "MorphWeld"
                            morphWeld.Part0 = morphRightHand
                            morphWeld.Part1 = handle
                            morphWeld.C0 = toolGripOffset
                            morphWeld.Parent = handle
                        elseif morphWeld.Part0 ~= morphRightHand then
                            morphWeld.Part0 = morphRightHand
                        end
                    end
                end
            end
        end
    end)

    local animationController = morph:FindFirstChildWhichIsA("AnimationController") or morph:FindFirstChild("AnimationController", true)
    if not animationController then
        animationController = Instance.new("AnimationController", morph)
    end
    local animator = morph:FindFirstChildWhichIsA("Animator", true)
    if not animator then
        animator = Instance.new("Animator", animationController)
    end

    local function createAnimation(animationId)
        local animation = Instance.new("Animation")
        animation.AnimationId = "rbxassetid://" .. animationId
        return animation
    end

    local function playAnimation(animationObject, looped)
        local track = animator:LoadAnimation(animationObject)
        if track then
            track.Looped = looped or false
            track:Play()
        end
        return track
    end

    local function createSound(soundId)
        local sound = Instance.new("Sound")
        sound.SoundId = "rbxassetid://" .. soundId
        return sound
    end

    local function playSound(soundObject)
        if not soundObject then return end
        soundObject.Parent = morph
        soundObject:Play()
    end

    local idleAnimation = createAnimation(idleAnimationId)
    local runAnimation = createAnimation(runAnimationId)
    local landingAnimation = createAnimation(landingAnimationId)

    local landingSound = createSound(landingSoundId)
    local impactSound = createSound(impactSoundId)

    local ambienceSounds = {}
    for i, id in ipairs(ambienceSoundIds) do
        local sound = createSound(id)
        sound.Looped = true
        ambienceSounds[i] = sound
    end

    local footstepsSound = nil
    for _, child in ipairs(morph:GetDescendants()) do
        if child:IsA("Sound") and child.Name == "Footsteps" then
            footstepsSound = child
            break
        end
    end

    local currentAmbience = nil
    local movementEnabled = false
    local runTrack, idleTrack, landingTrack = nil, nil, nil
    local lastMoveState = nil

    local function restoreMovement()
        if isLocalUserTarget then
            originalHumanoid.WalkSpeed = originalWalkSpeed
            originalHumanoid.JumpPower = originalJumpPower
            if originalHumanoid.JumpHeight then
                originalHumanoid.JumpHeight = originalJumpHeight
            end
        end
    end

    local function replayLanding()
        if tick() - lastLandingTime < landingCooldown then return end
        lastLandingTime = tick()

        if landingTrack then landingTrack:Stop() end
        landingTrack = playAnimation(landingAnimation, false)
        playSound(landingSound)
        playSound(impactSound)
        movementEnabled = false

        if isLocalUserTarget then
            originalHumanoid.WalkSpeed = 0
            originalHumanoid.JumpPower = 0
            if originalHumanoid.JumpHeight then
                originalHumanoid.JumpHeight = 0
            end
        end

        if landingTrack then
            landingTrack.Stopped:Connect(function()
                restoreMovement()
                movementEnabled = true
                if not runTrack or not runTrack.IsPlaying then
                    idleTrack = playAnimation(idleAnimation, true)
                end
            end)
        else
            restoreMovement()
            movementEnabled = true
        end
    end

    local inputConnection
    if isLocalUserTarget then
        local keySoundMap = {}
        local ambienceKeys = {Enum.KeyCode.Z, Enum.KeyCode.L, Enum.KeyCode.P}
        for i, key in ipairs(ambienceKeys) do
            if ambienceSounds[i] then keySoundMap[key] = ambienceSounds[i] end
        end

        inputConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then return end
            if input.UserInputType == Enum.UserInputType.Keyboard then
                local key = input.KeyCode
                local sound = keySoundMap[key]
                if sound then
                    if currentAmbience == sound then
                        sound:Stop()
                        currentAmbience = nil
                    else
                        if currentAmbience then currentAmbience:Stop() end
                        playSound(sound)
                        currentAmbience = sound
                    end
                    return
                end
                if key == Enum.KeyCode.B then
                    replayLanding()
                elseif key == Enum.KeyCode.L then
                    isThirdPerson = not isThirdPerson
                end
            end
        end)
    end

    replayLanding()

    local movementLoop = RunService.RenderStepped:Connect(function()
        if not movementEnabled then return end
        local moveDirection = originalHumanoid.MoveDirection
        if not moveDirection then return end
        local moving = moveDirection.Magnitude > 0.1

        if moving then
            if lastMoveState ~= "run" then
                if idleTrack then idleTrack:Stop() end
                runTrack = playAnimation(runAnimation, true)
                lastMoveState = "run"
            end
            if footstepsSound and not footstepsSound.IsPlaying then
                footstepsSound:Play()
            end
        else
            if lastMoveState ~= "idle" then
                if runTrack then runTrack:Stop() end
                idleTrack = playAnimation(idleAnimation, true)
                lastMoveState = "idle"
            end
            if footstepsSound and footstepsSound.IsPlaying then
                footstepsSound:Stop()
            end
        end
    end)

    return function()
        if inputConnection then inputConnection:Disconnect() end
        if enforceLoop then enforceLoop:Disconnect() end
        if movementLoop then movementLoop:Disconnect() end
        if currentAmbience then currentAmbience:Stop() end
        if landingTrack then landingTrack:Stop() end
        if runTrack then runTrack:Stop() end
        if idleTrack then idleTrack:Stop() end
        if footstepsSound then footstepsSound:Stop() end

        if isLocalUserTarget then
            if camera then camera.CameraType = Enum.CameraType.Custom end
            restoreMovement()
        end

        if rootWeld then rootWeld:Destroy() end
        if headWeld then headWeld:Destroy() end

        if originalCharacter then
            for _, part in ipairs(originalCharacter:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.Transparency = (part.Name == "HumanoidRootPart") and 1 or 0
                    part.CanCollide = true
                elseif part:IsA("Accessory") then
                    local handle = part:FindFirstChild("Handle")
                    if handle then handle.Transparency = 0 end
                end
            end
        end

        if morph then morph:Destroy() end
    end
end

for _, username in ipairs(targetUsernames) do
    task.spawn(function()
        if activeMorphs[username] then
            pcall(activeMorphs[username])
        end
        activeMorphs[username] = createMorph(username)
    end)
end

-- Remove everything
_G.morphCleanupAll = function()
    for username, cleanup in pairs(activeMorphs) do
        if cleanup then pcall(cleanup) end
        activeMorphs[username] = nil
    end
    _G.morphCleanupAll = nil
end

_G.morphAdd = function(username)
    task.spawn(function()
        if activeMorphs[username] then pcall(activeMorphs[username]) end
        activeMorphs[username] = createMorph(username)
    end)
end

_G.morphRemove = function(username)
    if activeMorphs[username] then
        pcall(activeMorphs[username])
        activeMorphs[username] = nil
    end
end
