local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

-- Wait for LocalPlayer
local LocalPlayer = Players.LocalPlayer
while not LocalPlayer do
    Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
    LocalPlayer = Players.LocalPlayer
end

-- ===========================
-- Config & State
-- ===========================
local Config = {
    WindowSize = UDim2.new(0, 620, 0, 420),
    SidebarWidth = 170,
    AccentColor = Color3.fromRGB(255, 170, 60),
    Visible = true,
    LookLineLength = 15,
    LookLineDistance = 1.5,
}

local State = {
    ActivePage = "Home",
    ESP = {
        Enabled = true,
        Glow = true,
        Box = true,
        Name = true,
        Health = true,
        Distance = true,
        Range = 1000,
        Color = Color3.fromRGB(255, 170, 60),
        Thickness = 2,
        TeamColor = false,
        ShowEnemies = true,
        ShowTeam = false,
        Transparency = 0.7,
        ShowLookLine = true,
        LookLineLength = 15
    },
    TrackedPlayers = {},
    TrackedCharacters = {}
}

-- ===========================
-- Helpers
-- ===========================
local function create(instanceType, props)
    local inst = Instance.new(instanceType)
    if props then
        for k, v in pairs(props) do
            if k ~= "Parent" then
                inst[k] = v
            else
                inst.Parent = v
            end
        end
    end
    return inst
end

local function setTextProps(lbl, text)
    lbl.Text = text
    lbl.Font = Enum.Font.Gotham
    lbl.TextColor3 = Color3.fromRGB(230, 230, 230)
    lbl.TextSize = 15
    lbl.BackgroundTransparency = 1
end

-- ===========================
-- Visual Creation
-- ===========================
local function createVisualForCharacter(character, player)
    if not character or character:FindFirstChild("ESPVisual") then return end

    local visu = Instance.new("Folder")
    visu.Name = "ESPVisual"
    visu.Parent = character

    -- Highlight
    local highlight = Instance.new("Highlight")
    highlight.Name = "Highlight"
    highlight.Parent = visu
    highlight.Adornee = character
    highlight.Enabled = false
    highlight.OutlineColor = State.ESP.Color
    highlight.FillColor = State.ESP.Color
    highlight.OutlineTransparency = 0
    highlight.FillTransparency = State.ESP.Transparency
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop

    -- Billboard GUI
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESPBillboard"
    billboard.Size = UDim2.new(0, 200, 0, 80)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.Enabled = false
    billboard.Parent = visu

    -- Main frame for labels
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(1, 0, 1, 0)
    mainFrame.Position = UDim2.new(0, 0, 0, 0)
    mainFrame.BackgroundTransparency = 1
    mainFrame.Parent = billboard

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.Size = UDim2.new(1, 0, 0.33, 0)
    nameLabel.Position = UDim2.new(0, 0, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 16
    nameLabel.TextColor3 = State.ESP.Color
    nameLabel.TextStrokeTransparency = 0
    nameLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    nameLabel.Text = player.Name or "Unknown"
    nameLabel.Parent = mainFrame

    local healthLabel = Instance.new("TextLabel")
    healthLabel.Name = "HealthLabel"
    healthLabel.Size = UDim2.new(1, 0, 0.33, 0)
    healthLabel.Position = UDim2.new(0, 0, 0.33, 0)
    healthLabel.BackgroundTransparency = 1
    healthLabel.Font = Enum.Font.Gotham
    healthLabel.TextSize = 14
    healthLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
    healthLabel.TextStrokeTransparency = 0
    healthLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    healthLabel.Text = "HP: ?"
    healthLabel.Parent = mainFrame

    local distanceLabel = Instance.new("TextLabel")
    distanceLabel.Name = "DistanceLabel"
    distanceLabel.Size = UDim2.new(1, 0, 0.34, 0)
    distanceLabel.Position = UDim2.new(0, 0, 0.66, 0)
    distanceLabel.BackgroundTransparency = 1
    distanceLabel.Font = Enum.Font.Gotham
    distanceLabel.TextSize = 12
    distanceLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    distanceLabel.TextStrokeTransparency = 0
    distanceLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    distanceLabel.Text = "0m"
    distanceLabel.Parent = mainFrame

    -- Look line system
    local lookLineFolder = Instance.new("Folder")
    lookLineFolder.Name = "LookLine"
    lookLineFolder.Parent = visu

    for i = 1, Config.LookLineLength do
        local part = Instance.new("Part")
        part.Name = "LookLinePart" .. i
        part.Anchored = true
        part.CanCollide = false
        part.CanTouch = false
        part.CanQuery = false
        part.Size = Vector3.new(0.15, 0.15, 0.15)
        part.Transparency = 1
        part.Color = State.ESP.Color
        part.Material = Enum.Material.Neon
        part.Shape = Enum.PartType.Ball
        part.Parent = lookLineFolder
    end

    -- Store references
    State.TrackedCharacters[character] = {
        Visuals = visu,
        Player = player,
        Highlight = highlight,
        Billboard = billboard,
        NameLabel = nameLabel,
        HealthLabel = healthLabel,
        DistanceLabel = distanceLabel,
        LookLineFolder = lookLineFolder
    }

    return visu
end

-- Clean up ESP for a player
local function cleanupESP(character)
    local data = State.TrackedCharacters[character]
    if data and data.Visuals and data.Visuals.Parent then
        data.Visuals:Destroy()
        State.TrackedCharacters[character] = nil
    end
end

-- ===========================
-- GUI Construction
-- ===========================
local screenGui = create("ScreenGui", {
    Parent = LocalPlayer:WaitForChild("PlayerGui"), 
    ResetOnSpawn = false, 
    Name = "UniversalESP"
})

local main = create("Frame", {
    Parent = screenGui,
    Size = Config.WindowSize,
    Position = UDim2.new(0.5, -Config.WindowSize.X.Offset/2, 0.4, -Config.WindowSize.Y.Offset/2),
    BackgroundColor3 = Color3.fromRGB(25, 25, 25),
    BorderSizePixel = 0,
    ClipsDescendants = true,
    Active = true
})
create("UICorner", {Parent = main, CornerRadius = UDim.new(0, 8)})
create("UIStroke", {Parent = main, Color = Config.AccentColor, Thickness = 2, Transparency = 0.0})

-- Header with close button
local header = create("Frame", {
    Parent = main, 
    Size = UDim2.new(1, 0, 0, 48), 
    BackgroundTransparency = 1,
    Active = true
})

local closeBtn = create("TextButton", {
    Parent = header,
    Size = UDim2.new(0, 24, 0, 24),
    Position = UDim2.new(1, -30, 0.5, -12),
    Text = "X",
    BackgroundColor3 = Color3.fromRGB(40, 40, 40),
    TextColor3 = Color3.fromRGB(200, 200, 200),
    Font = Enum.Font.GothamBold
})
create("UICorner", {Parent = closeBtn, CornerRadius = UDim.new(1, 0)})

closeBtn.MouseButton1Click:Connect(function()
    Config.Visible = not Config.Visible
    main.Visible = Config.Visible
end)

closeBtn.MouseEnter:Connect(function()
    TweenService:Create(closeBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(255, 50, 50)}):Play()
end)

closeBtn.MouseLeave:Connect(function()
    TweenService:Create(closeBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(40, 40, 40)}):Play()
end)

local title = create("TextLabel", {
    Parent = header, 
    Size = UDim2.new(0.6, 0, 1, 0), 
    Position = UDim2.new(0.02, 0, 0, 0)
})
title.Text = "Universal ESP"
title.Font = Enum.Font.GothamBold
title.TextColor3 = Config.AccentColor
title.TextSize = 22
title.BackgroundTransparency = 1

-- Sidebar
local sidebar = create("Frame", {
    Parent = main, 
    Position = UDim2.new(0, 0, 0, 48), 
    Size = UDim2.new(0, Config.SidebarWidth, 1, -48), 
    BackgroundColor3 = Color3.fromRGB(18, 18, 18)
})
create("UICorner", {Parent = sidebar, CornerRadius = UDim.new(0, 6)})
local sidePadding = 10

-- Content area
local content = create("Frame", {
    Parent = main, 
    Position = UDim2.new(0, Config.SidebarWidth, 0, 48), 
    Size = UDim2.new(1, -Config.SidebarWidth, 1, -48), 
    BackgroundColor3 = Color3.fromRGB(30, 30, 30)
})
create("UICorner", {Parent = content, CornerRadius = UDim.new(0, 6)})

-- Page manager
local pages = {}
local function newPage(name)
    local p = create("Frame", {
        Parent = content, 
        Size = UDim2.new(1, 0, 1, 0), 
        BackgroundTransparency = 1, 
        Name = name
    })
    p.Visible = false
    pages[name] = p
    return p
end

local homePage = newPage("Home")
local espPage = newPage("ESP")
local playersPage = newPage("Players")

pages["Home"].Visible = true

-- Sidebar buttons
local sidebarButtons = {}
local btnY = 8

local function makeSidebarButton(text, pageName)
    local btn = create("TextButton", {
        Parent = sidebar, 
        Size = UDim2.new(1, -sidePadding*2, 0, 34), 
        Position = UDim2.new(0, sidePadding, 0, btnY), 
        BackgroundTransparency = 1, 
        Text = text
    })
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 15
    btn.TextColor3 = Color3.fromRGB(200, 200, 200)
    btn.AutoButtonColor = false
    btnY = btnY + 40

    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {TextColor3 = Config.AccentColor}):Play()
    end)
    btn.MouseLeave:Connect(function()
        if State.ActivePage ~= pageName then
            TweenService:Create(btn, TweenInfo.new(0.15), {TextColor3 = Color3.fromRGB(200,200,200)}):Play()
        end
    end)

    btn.MouseButton1Click:Connect(function()
        for _, b in ipairs(sidebarButtons) do
            TweenService:Create(b, TweenInfo.new(0.15), {TextColor3 = Color3.fromRGB(200,200,200)}):Play()
        end
        TweenService:Create(btn, TweenInfo.new(0.15), {TextColor3 = Color3.new(1,1,1)}):Play()
        
        for name, pg in pairs(pages) do
            pg.Visible = (name == pageName)
        end
        State.ActivePage = pageName
    end)

    table.insert(sidebarButtons, btn)
    return btn
end

makeSidebarButton("Home", "Home")
makeSidebarButton("ESP", "ESP")
makeSidebarButton("Players", "Players")

sidebarButtons[1].TextColor3 = Color3.new(1,1,1)

-- Home page
local homeTitle = create("TextLabel", {
    Parent = homePage, 
    Position = UDim2.new(0, 14, 0, 6), 
    Size = UDim2.new(1, -28, 0, 28)
})
homeTitle.Font = Enum.Font.GothamBold
homeTitle.TextSize = 20
homeTitle.TextColor3 = Color3.new(1,1,1)
homeTitle.Text = "Universal ESP"
homeTitle.BackgroundTransparency = 1

local homeDesc = create("TextLabel", {
    Parent = homePage, 
    Position = UDim2.new(0, 14, 0, 36), 
    Size = UDim2.new(1, -28, 0, 50)
})
homeDesc.Font = Enum.Font.Gotham
homeDesc.TextSize = 14
homeDesc.TextColor3 = Color3.fromRGB(200,200,200)
homeDesc.Text = "Universal ESP works in any Roblox game. Configure ESP settings, track players, and customize visual elements. Use the tabs on the left to navigate between different features."
homeDesc.TextWrapped = true
homeDesc.BackgroundTransparency = 1

-- ESP Settings page helpers
local function makeLabel(parent, posY, text)
    local lbl = create("TextLabel", {
        Parent = parent, 
        Position = UDim2.new(0, 14, 0, posY), 
        Size = UDim2.new(0.5, -20, 0, 20)
    })
    setTextProps(lbl, text)
    lbl.Font = Enum.Font.GothamBold
    return lbl
end

local function makeToggle(parent, posY, labelText, initial, callback)
    makeLabel(parent, posY, labelText)
    local btn = create("TextButton", {
        Parent = parent, 
        Position = UDim2.new(0.5, 0, 0, posY-2), 
        Size = UDim2.new(0.45, -14, 0, 24), 
        Text = initial and "ON" or "OFF"
    })
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.TextColor3 = initial and Config.AccentColor or Color3.fromRGB(200,200,200)
    btn.BackgroundColor3 = Color3.fromRGB(40,40,40)
    create("UICorner", {Parent = btn, CornerRadius = UDim.new(0, 6)})
    btn.MouseButton1Click:Connect(function()
        initial = not initial
        btn.Text = initial and "ON" or "OFF"
        btn.TextColor3 = initial and Config.AccentColor or Color3.fromRGB(200,200,200)
        callback(initial)
    end)
    return btn
end

local function makeSlider(parent, posY, labelText, min, max, initial, callback)
    makeLabel(parent, posY, labelText)
    local bar = create("Frame", {
        Parent = parent, 
        Position = UDim2.new(0.5, 0, 0, posY), 
        Size = UDim2.new(0.45, -14, 0, 18), 
        BackgroundColor3 = Color3.fromRGB(40,40,40)
    })
    create("UICorner", {Parent = bar, CornerRadius = UDim.new(0, 6)})
    local fill = create("Frame", {
        Parent = bar, 
        Size = UDim2.new((initial-min)/(max-min), 0, 1, 0), 
        BackgroundColor3 = Config.AccentColor
    })
    create("UICorner", {Parent = fill, CornerRadius = UDim.new(0, 6)})
    
    local valueLabel = create("TextLabel", {
        Parent = bar,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = tostring(math.floor(initial)),
        TextColor3 = Color3.new(1, 1, 1),
        TextSize = 12,
        Font = Enum.Font.Gotham
    })
    
    local dragging = false
    bar.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
        end
    end)
    bar.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
            local mouseX = inp.Position.X
            local absPos = bar.AbsolutePosition.X
            local rel = math.clamp((mouseX - absPos) / bar.AbsoluteSize.X, 0, 1)
            fill.Size = UDim2.new(rel, 0, 1, 0)
            local value = min + (max-min)*rel
            valueLabel.Text = tostring(math.floor(value))
            callback(value)
        end
    end)
    return bar
end

-- Layout ESP controls
do
    local y = 16
    makeLabel(espPage, y, "Main Settings:")
    y = y + 32
    makeToggle(espPage, y, "Enable ESP", State.ESP.Enabled, function(v) 
        State.ESP.Enabled = v 
    end)
    y = y + 36
    makeToggle(espPage, y, "Show Enemies", State.ESP.ShowEnemies, function(v) 
        State.ESP.ShowEnemies = v 
    end)
    y = y + 36
    makeToggle(espPage, y, "Show Team", State.ESP.ShowTeam, function(v) 
        State.ESP.ShowTeam = v 
    end)
    y = y + 36
    makeToggle(espPage, y, "Use Team Colors", State.ESP.TeamColor, function(v) 
        State.ESP.TeamColor = v 
    end)
    y = y + 48
    makeLabel(espPage, y, "Visual Elements:")
    y = y + 32
    makeToggle(espPage, y, "Glow Effect", State.ESP.Glow, function(v) 
        State.ESP.Glow = v 
    end)
    y = y + 36
    makeToggle(espPage, y, "Show Names", State.ESP.Name, function(v) 
        State.ESP.Name = v 
    end)
    y = y + 36
    makeToggle(espPage, y, "Show Health", State.ESP.Health, function(v) 
        State.ESP.Health = v 
    end)
    y = y + 36
    makeToggle(espPage, y, "Show Look Line", State.ESP.ShowLookLine, function(v) 
        State.ESP.ShowLookLine = v 
    end)
    y = y + 48
    makeSlider(espPage, y, "Max Range (studs)", 50, 2000, State.ESP.Range, function(v) 
        State.ESP.Range = math.floor(v) 
    end)
    y = y + 36
    makeSlider(espPage, y, "Transparency", 0, 1, State.ESP.Transparency, function(v) 
        State.ESP.Transparency = v 
    end)
    y = y + 36
    makeSlider(espPage, y, "Look Line Length", 5, 30, State.ESP.LookLineLength, function(v) 
        State.ESP.LookLineLength = math.floor(v)
        Config.LookLineLength = State.ESP.LookLineLength
        -- Update existing look lines by recreating them
        for character, data in pairs(State.TrackedCharacters) do
            if data.LookLineFolder then
                -- Clear existing look line parts
                for _, part in ipairs(data.LookLineFolder:GetChildren()) do
                    if part:IsA("BasePart") then
                        part:Destroy()
                    end
                end
                -- Create new look line parts with updated length
                for i = 1, Config.LookLineLength do
                    local part = Instance.new("Part")
                    part.Name = "LookLinePart" .. i
                    part.Anchored = true
                    part.CanCollide = false
                    part.CanTouch = false
                    part.CanQuery = false
                    part.Size = Vector3.new(0.15, 0.15, 0.15)
                    part.Transparency = 1
                    part.Color = State.ESP.Color
                    part.Material = Enum.Material.Neon
                    part.Shape = Enum.PartType.Ball
                    part.Parent = data.LookLineFolder
                end
            end
        end
    end)
    y = y + 48
    makeLabel(espPage, y, "ESP Color:")
    local presetColors = {
        Color3.fromRGB(255,170,60), 
        Color3.fromRGB(80,150,255), 
        Color3.fromRGB(200,80,255), 
        Color3.fromRGB(120, 240, 120),
        Color3.fromRGB(255, 80, 80),
        Color3.fromRGB(255, 255, 80)
    }
    local x = 120
    for i, c in ipairs(presetColors) do
        local sw = create("TextButton", {
            Parent = espPage, 
            Position = UDim2.new(0, x, 0, y-6), 
            Size = UDim2.new(0, 28, 0, 28), 
            BackgroundColor3 = c, 
            Text = ""
        })
        create("UICorner", {Parent = sw, CornerRadius = UDim.new(1, 0)})
        sw.MouseButton1Click:Connect(function()
            State.ESP.Color = c
            Config.AccentColor = c
        end)
        x = x + 36
    end
end

-- Players page
do
    local title = create("TextLabel", {
        Parent = playersPage, 
        Position = UDim2.new(0, 12, 0, 8), 
        Size = UDim2.new(1, -24, 0, 26)
    })
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.TextColor3 = Color3.new(1,1,1)
    title.Text = "Player Management"
    title.BackgroundTransparency = 1

    local scroll = create("ScrollingFrame", {
        Parent = playersPage, 
        Position = UDim2.new(0, 12, 0, 44), 
        Size = UDim2.new(1, -24, 1, -56), 
        CanvasSize = UDim2.new(0,0,0,0), 
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 6
    })
    local uiList = create("UIListLayout", {Parent = scroll, Padding = UDim.new(0,6)})
    uiList.SortOrder = Enum.SortOrder.LayoutOrder
    
    local function refreshPlayersList()
        for _, child in ipairs(scroll:GetChildren()) do
            if child:IsA("Frame") then child:Destroy() end
        end
        local y = 0
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                local entry = create("Frame", {
                    Parent = scroll, 
                    Size = UDim2.new(1, 0, 0, 36), 
                    BackgroundColor3 = Color3.fromRGB(40,40,40)
                })
                create("UICorner", {Parent = entry, CornerRadius = UDim.new(0,6)})
                entry.LayoutOrder = y
                
                local name = create("TextLabel", {
                    Parent = entry, 
                    Position = UDim2.new(0,8,0,0), 
                    Size = UDim2.new(0.6, -12, 1, 0)
                })
                setTextProps(name, player.Name)
                name.Font = Enum.Font.Gotham
                name.TextSize = 14
                
                local toggle = create("TextButton", {
                    Parent = entry, 
                    Size = UDim2.new(0.28, -12, 0, 26), 
                    Position = UDim2.new(1, -12 - (0.28*entry.AbsoluteSize.X), 0, 5)
                })
                toggle.AnchorPoint = Vector2.new(1,0)
                toggle.Font = Enum.Font.GothamBold
                toggle.TextSize = 13
                toggle.BackgroundColor3 = Color3.fromRGB(60,60,60)
                create("UICorner", {Parent = toggle, CornerRadius = UDim.new(0,6)})
                
                local enabled = State.TrackedPlayers[player] ~= false
                toggle.Text = enabled and "ENABLED" or "DISABLED"
                toggle.TextColor3 = enabled and Config.AccentColor or Color3.fromRGB(200,200,200)
                
                toggle.MouseButton1Click:Connect(function()
                    enabled = not enabled
                    State.TrackedPlayers[player] = enabled
                    toggle.Text = enabled and "ENABLED" or "DISABLED"
                    toggle.TextColor3 = enabled and Config.AccentColor or Color3.fromRGB(200,200,200)
                    
                    if enabled and player.Character then
                        createVisualForCharacter(player.Character, player)
                    elseif not enabled and player.Character then
                        cleanupESP(player.Character)
                    end
                end)
                
                y = y + 1
            end
        end
        scroll.CanvasSize = UDim2.new(0, 0, 0, y * 42)
    end

    refreshPlayersList()
    Players.PlayerAdded:Connect(refreshPlayersList)
    Players.PlayerRemoving:Connect(refreshPlayersList)
end

-- Draggable logic
do
    local dragging = false
    local dragStart, startPos
    
    local function update(input)
        local delta = input.Position - dragStart
        main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
    
    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = main.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    header.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement and dragging then
            update(input)
        end
    end)
end

-- Opening animation
main.Position = UDim2.new(0.5, -Config.WindowSize.X.Offset/2, 1.2, 0)
main.BackgroundTransparency = 1
TweenService:Create(main, TweenInfo.new(0.55, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
    Position = UDim2.new(0.5, -Config.WindowSize.X.Offset/2, 0.4, -Config.WindowSize.Y.Offset/2),
    BackgroundTransparency = 0
}):Play()

-- ===========================
-- ESP Logic
-- ===========================
local function updateLookLine(character, lookLineFolder)
    if not character or not lookLineFolder or not State.ESP.ShowLookLine then
        for _, part in ipairs(lookLineFolder:GetChildren()) do
            if part:IsA("BasePart") then
                part.Transparency = 1
            end
        end
        return
    end

    local head = character:FindFirstChild("Head")
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not head or not humanoid then 
        -- Hide all parts if no head or humanoid
        for _, part in ipairs(lookLineFolder:GetChildren()) do
            if part:IsA("BasePart") then
                part.Transparency = 1
            end
        end
        return 
    end

    local lookVector
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    
    -- Determine look direction based on movement state
    if humanoid.MoveDirection.Magnitude > 0.1 then
        -- Player is moving, use movement direction
        lookVector = humanoid.MoveDirection.Unit
    elseif rootPart then
        -- Player is stationary, use where they're looking
        lookVector = rootPart.CFrame.LookVector
    else
        -- Fallback to head look direction
        lookVector = head.CFrame.LookVector
    end

    -- Create the look line with diminishing opacity
    for i, part in ipairs(lookLineFolder:GetChildren()) do
        if part:IsA("BasePart") and part.Name:match("LookLinePart") then
            local partIndex = tonumber(part.Name:match("LookLinePart(%d+)"))
            if partIndex then
                local distance = partIndex * Config.LookLineDistance
                local position = head.Position + (lookVector * distance)
                
                part.Position = position
                part.Color = State.ESP.Color
                
                -- Calculate transparency based on distance (closer = more opaque)
                local transparencyFactor = (partIndex - 1) / (State.ESP.LookLineLength - 1)
                part.Transparency = 0.3 + (transparencyFactor * 0.7) -- Range from 0.3 to 1.0
                
                -- Make parts smaller as they get further away
                local sizeFactor = 1 - (transparencyFactor * 0.5) -- Range from 1.0 to 0.5
                part.Size = Vector3.new(0.15 * sizeFactor, 0.15 * sizeFactor, 0.15 * sizeFactor)
            end
        end
    end
end

local function updateVisual(character)
    if not character then return end
    local data = State.TrackedCharacters[character]
    if not data then return end
    
    local player = data.Player
    if not player then return end
    
    -- Player-specific toggle check
    local playerEnabled = State.TrackedPlayers[player]
    if playerEnabled == false then
        data.Highlight.Enabled = false
        data.Billboard.Enabled = false
        -- Hide look line
        if data.LookLineFolder then
            for _, part in ipairs(data.LookLineFolder:GetChildren()) do
                if part:IsA("BasePart") then
                    part.Transparency = 1
                end
            end
        end
        return
    end

    -- Global ESP toggle check
    if not State.ESP.Enabled then
        data.Highlight.Enabled = false
        data.Billboard.Enabled = false
        -- Hide look line
        if data.LookLineFolder then
            for _, part in ipairs(data.LookLineFolder:GetChildren()) do
                if part:IsA("BasePart") then
                    part.Transparency = 1
                end
            end
        end
        return
    end

    -- Team checks
    local isEnemy = true
    if player.Team and LocalPlayer.Team then
        isEnemy = player.Team ~= LocalPlayer.Team
    end
    
    local shouldShow = (isEnemy and State.ESP.ShowEnemies) or (not isEnemy and State.ESP.ShowTeam)
    if not shouldShow then
        data.Highlight.Enabled = false
        data.Billboard.Enabled = false
        -- Hide look line
        if data.LookLineFolder then
            for _, part in ipairs(data.LookLineFolder:GetChildren()) do
                if part:IsA("BasePart") then
                    part.Transparency = 1
                end
            end
        end
        return
    end

    -- Find primary part
    local primaryPart = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Head")
    if not primaryPart then return end

    -- Distance check
    local lpChar = LocalPlayer.Character
    local lpRoot = lpChar and (lpChar:FindFirstChild("HumanoidRootPart") or lpChar:FindFirstChild("Head"))
    local distance = 0
    local distOk = true
    
    if lpRoot then
        distance = (primaryPart.Position - lpRoot.Position).Magnitude
        distOk = distance <= State.ESP.Range
    end

    if not distOk then
        data.Highlight.Enabled = false
        data.Billboard.Enabled = false
        -- Hide look line
        if data.LookLineFolder then
            for _, part in ipairs(data.LookLineFolder:GetChildren()) do
                if part:IsA("BasePart") then
                    part.Transparency = 1
                end
            end
        end
        return
    end

    -- Get current color
    local currentColor = State.ESP.Color
    if State.ESP.TeamColor and player.Team and player.Team.TeamColor then
        currentColor = player.Team.TeamColor.Color
    end

    -- Update highlight
    data.Highlight.Enabled = State.ESP.Glow
    data.Highlight.OutlineColor = currentColor
    data.Highlight.FillColor = currentColor
    data.Highlight.FillTransparency = State.ESP.Transparency
    data.Highlight.Adornee = character

    -- Update billboard
    data.Billboard.Enabled = State.ESP.Name or State.ESP.Health or State.ESP.Distance
    data.Billboard.Adornee = primaryPart

    -- Update labels
    data.NameLabel.Visible = State.ESP.Name
    data.NameLabel.TextColor3 = currentColor
    data.NameLabel.Text = player.Name or "Unknown"

    -- Update health
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        data.HealthLabel.Visible = State.ESP.Health
        local healthPercent = humanoid.Health / humanoid.MaxHealth
        local healthColor = Color3.new(1 - healthPercent, healthPercent, 0)
        data.HealthLabel.TextColor3 = healthColor
        data.HealthLabel.Text = "HP: " .. math.floor(humanoid.Health) .. "/" .. math.floor(humanoid.MaxHealth)
    else
        data.HealthLabel.Visible = false
    end

    -- Update distance
    data.DistanceLabel.Visible = State.ESP.Distance
    data.DistanceLabel.Text = math.floor(distance) .. "m"
    
    -- Update look line
    if data.LookLineFolder then
        updateLookLine(character, data.LookLineFolder)
    end
end

-- Character handling
local function onCharacterAdded(character, player)
    if player == LocalPlayer then return end
    
    -- Wait for the character to fully load
    local humanoid = character:WaitForChild("Humanoid", 5)
    if not humanoid then return end
    
    -- Small delay to ensure character is fully loaded
    wait(0.1)
    
    createVisualForCharacter(character, player)
    State.TrackedPlayers[player] = State.TrackedPlayers[player] or true
end

local function onCharacterRemoving(character)
    cleanupESP(character)
end

-- Initialize for existing players
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        State.TrackedPlayers[player] = true
        
        if player.Character then
            coroutine.wrap(onCharacterAdded)(player.Character, player)
        end
        
        player.CharacterAdded:Connect(function(char)
            onCharacterAdded(char, player)
        end)
        
        player.CharacterRemoving:Connect(onCharacterRemoving)
    end
end

-- Handle new players
Players.PlayerAdded:Connect(function(player)
    if player == LocalPlayer then return end
    
    State.TrackedPlayers[player] = true
    
    player.CharacterAdded:Connect(function(char)
        onCharacterAdded(char, player)
    end)
    
    player.CharacterRemoving:Connect(onCharacterRemoving)
    
    if player.Character then
        coroutine.wrap(onCharacterAdded)(player.Character, player)
    end
end)

-- Handle players leaving
Players.PlayerRemoving:Connect(function(player)
    State.TrackedPlayers[player] = nil
    if player.Character then
        cleanupESP(player.Character)
    end
end)

-- Main update loop with error handling
local updateConnection
updateConnection = RunService.Heartbeat:Connect(function()
    local success, error = pcall(function()
        for character, data in pairs(State.TrackedCharacters) do
            if character.Parent then
                updateVisual(character)
            else
                cleanupESP(character)
            end
        end
    end)
    
    if not success then
        warn("ESP Update Error: " .. tostring(error))
    end
end)

-- Keyboard shortcuts
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.Insert then
        Config.Visible = not Config.Visible
        main.Visible = Config.Visible
    elseif input.KeyCode == Enum.KeyCode.F1 then
        State.ESP.Enabled = not State.ESP.Enabled
        print("ESP " .. (State.ESP.Enabled and "Enabled" or "Disabled"))
    elseif input.KeyCode == Enum.KeyCode.F2 then
        State.ESP.ShowEnemies = not State.ESP.ShowEnemies
        print("Show Enemies: " .. tostring(State.ESP.ShowEnemies))
    elseif input.KeyCode == Enum.KeyCode.F3 then
        State.ESP.ShowTeam = not State.ESP.ShowTeam
        print("Show Team: " .. tostring(State.ESP.ShowTeam))
    elseif input.KeyCode == Enum.KeyCode.F4 then
        State.ESP.Glow = not State.ESP.Glow
        print("Glow Effect: " .. tostring(State.ESP.Glow))
    elseif input.KeyCode == Enum.KeyCode.F5 then
        State.ESP.ShowLookLine = not State.ESP.ShowLookLine
        print("Look Line: " .. tostring(State.ESP.ShowLookLine))
    end
end)

-- Cleanup on script end
game:GetService("Players").PlayerRemoving:Connect(function(player)
    if player == LocalPlayer then
        if updateConnection then
            updateConnection:Disconnect()
        end
        for character, _ in pairs(State.TrackedCharacters) do
            cleanupESP(character)
        end
    end
end)

-- Auto-reconnect if LocalPlayer changes
Players:GetPropertyChangedSignal("LocalPlayer"):Connect(function()
    LocalPlayer = Players.LocalPlayer
    if not LocalPlayer then return end
    
    -- Re-parent the GUI
    if screenGui then
        screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
end)

-- Create notification
local function createNotification(title, message)
    local notif = create("Frame", {
        Parent = screenGui,
        Size = UDim2.new(0, 300, 0, 80),
        Position = UDim2.new(1, -320, 0, 20),
        BackgroundColor3 = Color3.fromRGB(25, 25, 25),
        BorderSizePixel = 0
    })
    create("UICorner", {Parent = notif, CornerRadius = UDim.new(0, 8)})
    create("UIStroke", {Parent = notif, Color = Config.AccentColor, Thickness = 2})
    
    local titleLabel = create("TextLabel", {
        Parent = notif,
        Size = UDim2.new(1, -16, 0, 25),
        Position = UDim2.new(0, 8, 0, 8),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = Config.AccentColor,
        TextSize = 16,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    local messageLabel = create("TextLabel", {
        Parent = notif,
        Size = UDim2.new(1, -16, 0, 40),
        Position = UDim2.new(0, 8, 0, 30),
        BackgroundTransparency = 1,
        Text = message,
        TextColor3 = Color3.fromRGB(200, 200, 200),
        TextSize = 14,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true
    })
    
    -- Slide in animation
    notif.Position = UDim2.new(1, 20, 0, 20)
    TweenService:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(1, -320, 0, 20)
    }):Play()
    
    -- Auto remove after 5 seconds
    wait(5)
    TweenService:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
        Position = UDim2.new(1, 20, 0, 20)
    }):Play()
    
    wait(0.3)
    notif:Destroy()
end

-- Show startup notification
coroutine.wrap(function()
    wait(1)
    createNotification("ESP Loaded", "Universal ESP is ready! Use INSERT to toggle GUI or F1-F4 for quick controls.")
end)()

print("Universal ESP Loaded Successfully!")
print("Controls:")
print("INSERT - Toggle GUI")
print("F1 - Toggle ESP")
print("F2 - Toggle Show Enemies")
print("F3 - Toggle Show Team")
print("F4 - Toggle Glow Effect")
print("F5 - Toggle Look Line")