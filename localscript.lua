-- LOCAL SCRIPT - AnimFlix Complete UI System (TikTok Style)
-- Coloca este script en StarterPlayer > StarterPlayerScripts

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Esperar RemoteEvents
local RemoteEvents = ReplicatedStorage:WaitForChild("AnimFlixRemotes")
local PublishAnimation = RemoteEvents:WaitForChild("PublishAnimation")
local GetAnimations = RemoteEvents:WaitForChild("GetAnimations")
local PlayAnimation = RemoteEvents:WaitForChild("PlayAnimation")
local LikeAnimation = RemoteEvents:WaitForChild("LikeAnimation")
local EditAnimation = RemoteEvents:WaitForChild("EditAnimation")

-- Variables globales del editor
local frames = {}
local currentFrame = 1
local isDrawing = false
local lastScalePoint = nil
local currentColor = Color3.fromRGB(0, 0, 0)
local currentThickness = 3
local currentTool = "pencil" -- pencil, eraser
local onionSkinEnabled = true
local animationToEdit = nil

-- Crear ScreenGui principal (FULL SCREEN SIN MÁRGENES)
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AnimFlixUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.IgnoreGuiInset = true -- ESTO ELIMINA LOS MÁRGENES
screenGui.Parent = playerGui

-- ==================== FUNCIONES AUXILIARES DE UI ====================

local function CreateTween(obj, props, time)
    local tween = TweenService:Create(obj, TweenInfo.new(time or 0.3, Enum.EasingStyle.Quad), props)
    tween:Play()
    return tween
end

local function CreateUICorner(radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 12)
    return corner
end

local function CreateButton(text, parent, callback)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 160, 0, 45)
    button.BackgroundColor3 = Color3.fromRGB(254, 44, 85) -- TikTok rosa
    button.Text = text
    button.TextColor3 = Color3.new(1, 1, 1)
    button.Font = Enum.Font.GothamBold
    button.TextSize = 16
    button.BorderSizePixel = 0
    button.Parent = parent
    
    CreateUICorner(22).Parent = button
    
    button.MouseButton1Click:Connect(function()
        CreateTween(button, {BackgroundColor3 = Color3.fromRGB(200, 35, 68)}, 0.1)
        wait(0.1)
        CreateTween(button, {BackgroundColor3 = Color3.fromRGB(254, 44, 85)}, 0.1)
        if callback then callback() end
    end)
    
    return button
end

local function CreateSearchBar(parent)
    local searchContainer = Instance.new("Frame")
    searchContainer.Size = UDim2.new(0.4, 0, 0, 50)
    searchContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    searchContainer.BorderSizePixel = 0
    
    CreateUICorner(25).Parent = searchContainer
    
    local searchIcon = Instance.new("TextLabel")
    searchIcon.Size = UDim2.new(0, 40, 0, 40)
    searchIcon.Position = UDim2.new(0, 5, 0, 5)
    searchIcon.BackgroundTransparency = 1
    searchIcon.Text = "🔍"
    searchIcon.TextSize = 20
    searchIcon.Parent = searchContainer
    
    local searchBox = Instance.new("TextBox")
    searchBox.Size = UDim2.new(1, -50, 1, -10)
    searchBox.Position = UDim2.new(0, 45, 0, 5)
    searchBox.BackgroundTransparency = 1
    searchBox.PlaceholderText = "Buscar animaciones..."
    searchBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
    searchBox.Text = ""
    searchBox.TextColor3 = Color3.new(1, 1, 1)
    searchBox.Font = Enum.Font.Gotham
    searchBox.TextSize = 16
    searchBox.TextXAlignment = Enum.TextXAlignment.Left
    searchBox.ClearTextOnFocus = false
    searchBox.Parent = searchContainer
    searchBox.ZIndex = 2
    
    searchContainer.Parent = parent
    
    return searchBox
end

-- ==================== PANTALLA PRINCIPAL (FULL SCREEN TIKTOK STYLE) ====================

local function CreateMainScreen()
    local mainFrame = screenGui:FindFirstChild("MainScreen") or Instance.new("Frame")
    mainFrame.Name = "MainScreen"
    mainFrame.Size = UDim2.new(1, 0, 1, 0) -- FULL SCREEN
    mainFrame.Position = UDim2.new(0, 0, 0, 0) -- SIN MÁRGENES
    mainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0) -- Negro TikTok
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui
    mainFrame.Visible = true
    
    -- Barra superior TikTok Style
    local topBar = Instance.new("Frame")
    topBar.Size = UDim2.new(1, 0, 0, 60)
    topBar.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
    topBar.BorderSizePixel = 0
    topBar.Parent = mainFrame
    topBar.Name = "TopBar"
    
    local topBarLayout = Instance.new("UIListLayout")
    topBarLayout.FillDirection = Enum.FillDirection.Horizontal
    topBarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    topBarLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    topBarLayout.Padding = UDim.new(0, 10)
    topBarLayout.Parent = topBar
    
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 10)
    padding.PaddingRight = UDim.new(0, 10)
    padding.Parent = topBar
    
    local logo = Instance.new("TextLabel")
    logo.Name = "Logo"
    logo.Size = UDim2.new(0, 150, 1, -10)
    logo.BackgroundTransparency = 1
    logo.Text = "🎬 AnimFlix"
    logo.TextColor3 = Color3.fromRGB(254, 44, 85)
    logo.Font = Enum.Font.GothamBold
    logo.TextSize = 24
    logo.TextXAlignment = Enum.TextXAlignment.Left
    logo.Parent = topBar
    
    local searchBar = CreateSearchBar(topBar)
    searchBar.Size = UDim2.new(0.5, 0, 0, 40)
    searchBar.LayoutOrder = 1
    
    -- Funcionalidad de búsqueda
    searchBar.FocusLost:Connect(function(enterPressed)
        if enterPressed and searchBar.Text ~= "" then
            -- Buscar animaciones
            local results = GetAnimations:InvokeServer("Search", searchBar.Text)
            
            -- Limpiar y mostrar resultados
            local scrollFrame = mainFrame:FindFirstChild("ScrollingFrame")
            if scrollFrame then
                for _, child in ipairs(scrollFrame:GetChildren()) do
                    if child:IsA("Frame") and child.Name ~= "UIListLayout" and child.Name ~= "UIPadding" then
                        child:Destroy()
                    end
                end
                
                if results and #results > 0 then
                    CreateCarousel("Resultados de búsqueda: " .. searchBar.Text, results, scrollFrame)
                else
                    local noResults = Instance.new("TextLabel")
                    noResults.Size = UDim2.new(1, 0, 0, 100)
                    noResults.BackgroundTransparency = 1
                    noResults.Text = "No se encontraron resultados para: " .. searchBar.Text
                    noResults.TextColor3 = Color3.new(1, 1, 1)
                    noResults.Font = Enum.Font.Gotham
                    noResults.TextSize = 18
                    noResults.Parent = scrollFrame
                end
            end
        end
    end)
    
    local createBtn = CreateButton("➕ CREAR", topBar)
    createBtn.Size = UDim2.new(0, 120, 0, 40)
    createBtn.LayoutOrder = 2
    createBtn.TextSize = 14
    createBtn.MouseButton1Click:Connect(function()
        mainFrame.Visible = false
        animationToEdit = nil
        CreateEditorScreen()
    end)
    
    logo.Size = UDim2.new(0, 150, 1, -10)
    
    -- ScrollFrame para contenido
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Size = UDim2.new(1, 0, 1, -60)
    scrollFrame.Position = UDim2.new(0, 0, 0, 60)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 4
    scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(254, 44, 85)
    scrollFrame.Parent = mainFrame
    
    local scrollPadding = Instance.new("UIPadding")
    scrollPadding.PaddingLeft = UDim.new(0, 10)
    scrollPadding.PaddingRight = UDim.new(0, 10)
    scrollPadding.PaddingTop = UDim.new(0, 10)
    scrollPadding.PaddingBottom = UDim.new(0, 10)
    scrollPadding.Parent = scrollFrame
    
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 20)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = scrollFrame
    
    -- Función para crear carrusel
    function CreateCarousel(categoryName, animations, parentFrame)
        local carouselFrame = Instance.new("Frame")
        carouselFrame.Size = UDim2.new(1, 0, 0, 250)
        carouselFrame.BackgroundTransparency = 1
        carouselFrame.Parent = parentFrame or scrollFrame
        
        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1, 0, 0, 30)
        title.BackgroundTransparency = 1
        title.Text = categoryName
        title.TextColor3 = Color3.new(1, 1, 1)
        title.Font = Enum.Font.GothamBold
        title.TextSize = 20
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.Parent = carouselFrame
        
        local carouselScroll = Instance.new("ScrollingFrame")
        carouselScroll.Size = UDim2.new(1, 0, 0, 210)
        carouselScroll.Position = UDim2.new(0, 0, 0, 40)
        carouselScroll.BackgroundTransparency = 1
        carouselScroll.BorderSizePixel = 0
        carouselScroll.ScrollBarThickness = 0
        carouselScroll.CanvasSize = UDim2.new(0, #animations * 150 + (#animations * 10), 0, 0)
        carouselScroll.ScrollingDirection = Enum.ScrollingDirection.X
        carouselScroll.Parent = carouselFrame
        
        local carouselLayout = Instance.new("UIListLayout")
        carouselLayout.FillDirection = Enum.FillDirection.Horizontal
        carouselLayout.Padding = UDim.new(0, 10)
        carouselLayout.Parent = carouselScroll
        
        for _, anim in ipairs(animations) do
            local card = Instance.new("TextButton")
            card.Size = UDim2.new(0, 140, 0, 200)
            card.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
            card.BorderSizePixel = 0
            card.Text = ""
            card.Parent = carouselScroll
            
            CreateUICorner(15).Parent = card
            
            local thumbnail = Instance.new("Frame")
            thumbnail.Size = UDim2.new(1, 0, 0, 120)
            thumbnail.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            thumbnail.BorderSizePixel = 0
            thumbnail.Parent = card
            
            CreateUICorner(15).Parent = thumbnail
            
            local thumbLabel = Instance.new("TextLabel")
            thumbLabel.Size = UDim2.new(1, 0, 1, 0)
            thumbLabel.BackgroundTransparency = 1
            thumbLabel.Text = "🎬"
            thumbLabel.TextSize = 40
            thumbLabel.Parent = thumbnail
            
            local titleLabel = Instance.new("TextLabel")
            titleLabel.Size = UDim2.new(1, -10, 0, 25)
            titleLabel.Position = UDim2.new(0, 5, 0, 125)
            titleLabel.BackgroundTransparency = 1
            titleLabel.Text = anim.title
            titleLabel.TextColor3 = Color3.new(1, 1, 1)
            titleLabel.Font = Enum.Font.GothamBold
            titleLabel.TextSize = 12
            titleLabel.TextTruncate = Enum.TextTruncate.AtEnd
            titleLabel.TextXAlignment = Enum.TextXAlignment.Left
            titleLabel.Parent = card
            
            local infoLabel = Instance.new("TextLabel")
            infoLabel.Size = UDim2.new(1, -10, 0, 50)
            infoLabel.Position = UDim2.new(0, 5, 0, 150)
            infoLabel.BackgroundTransparency = 1
            infoLabel.Text = "❤️ " .. anim.likes .. " 👁️ " .. anim.views
            infoLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
            infoLabel.Font = Enum.Font.Gotham
            infoLabel.TextSize = 10
            infoLabel.TextXAlignment = Enum.TextXAlignment.Left
            infoLabel.TextYAlignment = Enum.TextYAlignment.Top
            infoLabel.Parent = card
            
            card.MouseEnter:Connect(function()
                CreateTween(card, {Size = UDim2.new(0, 150, 0, 210)}, 0.2)
            end)
            
            card.MouseLeave:Connect(function()
                CreateTween(card, {Size = UDim2.new(0, 140, 0, 200)}, 0.2)
            end)
            
            card.MouseButton1Click:Connect(function()
                OpenAnimationDetails(anim)
            end)
        end
    end
    
    -- Cargar animaciones
    spawn(function()
        local categories = {"Recientes", "Terror", "Comedia", "Accion", "Drama", "Aventura"}
        
        for _, category in ipairs(categories) do
            local anims = GetAnimations:InvokeServer(category)
            if anims and #anims > 0 then
                CreateCarousel(category, anims, scrollFrame)
            end
        end
        
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 40)
    end)
    
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 40)
    end)
    
    return mainFrame
end

-- ==================== PANTALLA DE DETALLES ====================

function OpenAnimationDetails(anim)
    local mainScreen = screenGui:FindFirstChild("MainScreen")
    if mainScreen then mainScreen.Visible = false end
    
    local detailsFrame = Instance.new("Frame")
    detailsFrame.Name = "DetailsScreen"
    detailsFrame.Size = UDim2.new(1, 0, 1, 0)
    detailsFrame.Position = UDim2.new(0, 0, 0, 0)
    detailsFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    detailsFrame.BorderSizePixel = 0
    detailsFrame.Parent = screenGui
    detailsFrame.ZIndex = 5
    
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 50, 0, 50)
    closeBtn.Position = UDim2.new(0, 10, 0, 10)
    closeBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    closeBtn.Text = "✕"
    closeBtn.TextSize = 24
    closeBtn.TextColor3 = Color3.new(1, 1, 1)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.BorderSizePixel = 0
    closeBtn.Parent = detailsFrame
    
    CreateUICorner(25).Parent = closeBtn
    
    closeBtn.MouseButton1Click:Connect(function()
        detailsFrame:Destroy()
        if mainScreen then mainScreen.Visible = true end
    end)
    
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Size = UDim2.new(1, 0, 1, -70)
    scrollFrame.Position = UDim2.new(0, 0, 0, 70)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 4
    scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(254, 44, 85)
    scrollFrame.Parent = detailsFrame
    
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 10)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.Parent = scrollFrame
    
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 20)
    padding.PaddingRight = UDim.new(0, 20)
    padding.PaddingTop = UDim.new(0, 20)
    padding.PaddingBottom = UDim.new(0, 20)
    padding.Parent = scrollFrame
    
    local infoContainer = Instance.new("Frame")
    infoContainer.Size = UDim2.new(1, 0, 0, 400)
    infoContainer.BackgroundTransparency = 1
    infoContainer.Parent = scrollFrame
    
    local infoLayout = Instance.new("UIListLayout")
    infoLayout.Padding = UDim.new(0, 5)
    infoLayout.SortOrder = Enum.SortOrder.LayoutOrder
    infoLayout.Parent = infoContainer
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 60)
    title.BackgroundTransparency = 1
    title.Text = anim.title
    title.TextColor3 = Color3.new(1, 1, 1)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 42
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.TextWrapped = true
    title.Parent = infoContainer
    
    local metadata = Instance.new("TextLabel")
    metadata.Size = UDim2.new(1, 0, 0, 25)
    metadata.BackgroundTransparency = 1
    metadata.Text = anim.type .. " • " .. anim.category .. " • " .. anim.duration .. " frames"
    metadata.TextColor3 = Color3.fromRGB(150, 150, 150)
    metadata.Font = Enum.Font.Gotham
    metadata.TextSize = 16
    metadata.TextXAlignment = Enum.TextXAlignment.Left
    metadata.Parent = infoContainer
    
    local creator = Instance.new("TextLabel")
    creator.Size = UDim2.new(1, 0, 0, 25)
    creator.BackgroundTransparency = 1
    creator.Text = "Por: " .. anim.creator
    creator.TextColor3 = Color3.fromRGB(200, 200, 200)
    creator.Font = Enum.Font.GothamBold
    creator.TextSize = 14
    creator.TextXAlignment = Enum.TextXAlignment.Left
    creator.Parent = infoContainer
    
    local spacer = Instance.new("Frame")
    spacer.Size = UDim2.new(1, 0, 0, 10)
    spacer.BackgroundTransparency = 1
    spacer.Parent = infoContainer
    
    local desc = Instance.new("TextLabel")
    desc.Size = UDim2.new(1, 0, 0, 80)
    desc.BackgroundTransparency = 1
    desc.Text = anim.description
    desc.TextColor3 = Color3.fromRGB(220, 220, 220)
    desc.Font = Enum.Font.Gotham
    desc.TextSize = 14
    desc.TextXAlignment = Enum.TextXAlignment.Left
    desc.TextYAlignment = Enum.TextYAlignment.Top
    desc.TextWrapped = true
    desc.Parent = infoContainer
    
    local stats = Instance.new("TextLabel")
    stats.Size = UDim2.new(1, 0, 0, 25)
    stats.BackgroundTransparency = 1
    stats.Text = "❤️ " .. anim.likes .. "    👁️ " .. anim.views
    stats.TextColor3 = Color3.fromRGB(180, 180, 180)
    stats.Font = Enum.Font.Gotham
    stats.TextSize = 14
    stats.TextXAlignment = Enum.TextXAlignment.Left
    stats.Parent = infoContainer
    
    local buttonsContainer = Instance.new("Frame")
    buttonsContainer.Size = UDim2.new(1, 0, 0, 50)
    buttonsContainer.BackgroundTransparency = 1
    buttonsContainer.Parent = infoContainer
    
    local buttonLayout = Instance.new("UIListLayout")
    buttonLayout.FillDirection = Enum.FillDirection.Horizontal
    buttonLayout.Padding = UDim.new(0, 10)
    buttonLayout.Parent = buttonsContainer
    
    local playBtn = CreateButton("▶ REPRODUCIR", buttonsContainer)
    playBtn.Size = UDim2.new(0.33, -7, 0, 50)
    playBtn.TextSize = 14
    playBtn.MouseButton1Click:Connect(function()
        PlayAnimation:FireServer(anim.id)
        PlayAnimationScreen(anim, detailsFrame)
    end)
    
    local likeBtn = CreateButton("❤️ ME GUSTA", buttonsContainer)
    likeBtn.Size = UDim2.new(0.33, -7, 0, 50)
    likeBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    likeBtn.MouseButton1Click:Connect(function()
        LikeAnimation:FireServer(anim.id)
        likeBtn.Text = "✓ TE GUSTA"
        likeBtn.BackgroundColor3 = Color3.fromRGB(254, 44, 85)
    end)
    
    -- Botón EDITAR (solo si eres el creador)
    if anim.creatorId == player.UserId then
        local editBtn = CreateButton("✏️ EDITAR", buttonsContainer)
        editBtn.Size = UDim2.new(0.33, -7, 0, 50)
        editBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
        editBtn.MouseButton1Click:Connect(function()
            detailsFrame:Destroy()
            animationToEdit = anim
            CreateEditorScreen()
        end)
    end
    
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 80)
    end)
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 80)
    
    dialogLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        dialog.CanvasSize = UDim2.new(0, 0, 0, dialogLayout.AbsoluteContentSize.Y + 60)
    end)
    dialog.CanvasSize = UDim2.new(0, 0, 0, dialogLayout.AbsoluteContentSize.Y + 60)
end

-- ==================== REPRODUCTOR DE ANIMACIÓN ====================

function PlayAnimationScreen(anim, parentFrame)
    local playerFrame = Instance.new("Frame")
    playerFrame.Size = UDim2.new(1, 0, 1, 0)
    playerFrame.Position = UDim2.new(0, 0, 0, 0)
    playerFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    playerFrame.BorderSizePixel = 0
    playerFrame.Parent = screenGui
    playerFrame.ZIndex = 10
    
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -20, 1, -100)
    container.Position = UDim2.new(0, 10, 0, 50)
    container.BackgroundTransparency = 1
    container.Parent = playerFrame
    
    local animTitle = Instance.new("TextLabel")
    animTitle.Size = UDim2.new(1, 0, 0, 30)
    animTitle.Position = UDim2.new(0, 0, 0, -40)
    animTitle.BackgroundTransparency = 1
    animTitle.Text = anim.title
    animTitle.TextColor3 = Color3.new(1, 1, 1)
    animTitle.Font = Enum.Font.GothamBold
    animTitle.TextSize = 24
    animTitle.TextXAlignment = Enum.TextXAlignment.Center
    animTitle.Parent = container
    
    local canvas = Instance.new("Frame")
    canvas.Name = "PlayCanvas"
    canvas.Size = UDim2.new(1, 0, 1, 0)
    canvas.BackgroundColor3 = Color3.new(1, 1, 1)
    canvas.BorderSizePixel = 0
    canvas.Parent = container
    
    CreateUICorner(15).Parent = canvas
    
    local aspectRatio = Instance.new("UIAspectRatioConstraint")
    aspectRatio.AspectRatio = 1.33
    aspectRatio.AspectType = Enum.AspectType.ScaleWithParentSize
    aspectRatio.Parent = canvas
    
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 50, 0, 50)
    closeBtn.Position = UDim2.new(1, -60, 0, 10)
    closeBtn.AnchorPoint = Vector2.new(1, 0)
    closeBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    closeBtn.Text = "✕"
    closeBtn.TextSize = 24
    closeBtn.TextColor3 = Color3.new(1, 1, 1)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.BorderSizePixel = 0
    closeBtn.ZIndex = 11
    closeBtn.Parent = playerFrame
    
    CreateUICorner(25).Parent = closeBtn
    
    closeBtn.MouseButton1Click:Connect(function()
        playerFrame:Destroy()
    end)
    
    local currentFrameIndex = 1
    local isPlaying = true
    local fps = 12
    local accumulatedTime = 0
    
    local function DrawFrame(frameData)
        for _, child in ipairs(canvas:GetChildren()) do
            if child:IsA("Frame") and child.Name == "DrawingPoint" then
                child:Destroy()
            end
        end
        
        if frameData and frameData.strokes then
            for _, stroke in ipairs(frameData.strokes) do
                for _, point in ipairs(stroke.points) do
                    local dot = Instance.new("Frame")
                    dot.Name = "DrawingPoint"
                    dot.Position = UDim2.new(point.scaleX, 0, point.scaleY, 0)
                    dot.Size = UDim2.new(0, point.thickness or 3, 0, point.thickness or 3)
                    dot.BackgroundColor3 = point.color or Color3.new(0, 0, 0)
                    dot.BorderSizePixel = 0
                    dot.Parent = canvas
                    
                    local corner = Instance.new("UICorner")
                    corner.CornerRadius = UDim.new(1, 0)
                    corner.Parent = dot
                end
            end
        end
    end
    
    local controlsFrame = Instance.new("Frame")
    controlsFrame.Size = UDim2.new(1, 0, 0, 60)
    controlsFrame.Position = UDim2.new(0.5, 0, 1, -70)
    controlsFrame.AnchorPoint = Vector2.new(0.5, 0)
    controlsFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    controlsFrame.BorderSizePixel = 0
    controlsFrame.Parent = playerFrame
    
    CreateUICorner(10).Parent = controlsFrame
    
    local controlsLayout = Instance.new("UIListLayout")
    controlsLayout.FillDirection = Enum.FillDirection.Horizontal
    controlsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    controlsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    controlsLayout.Padding = UDim.new(0, 15)
    controlsLayout.Parent = controlsFrame
    
    local playPauseBtn = Instance.new("TextButton")
    playPauseBtn.Size = UDim2.new(0, 50, 0, 50)
    playPauseBtn.BackgroundColor3 = Color3.fromRGB(254, 44, 85)
    playPauseBtn.Text = "⏸"
    playPauseBtn.TextSize = 24
    playPauseBtn.TextColor3 = Color3.new(1, 1, 1)
    playPauseBtn.Font = Enum.Font.GothamBold
    playPauseBtn.BorderSizePixel = 0
    playPauseBtn.Parent = controlsFrame
    
    CreateUICorner(25).Parent = playPauseBtn
    
    local frameCounter = Instance.new("TextLabel")
    frameCounter.Size = UDim2.new(0, 150, 0, 50)
    frameCounter.BackgroundTransparency = 1
    frameCounter.Text = "1 / " .. #anim.frames
    frameCounter.TextColor3 = Color3.new(1, 1, 1)
    frameCounter.Font = Enum.Font.GothamBold
    frameCounter.TextSize = 18
    frameCounter.Parent = controlsFrame
    
    playPauseBtn.MouseButton1Click:Connect(function()
        isPlaying = not isPlaying
        playPauseBtn.Text = isPlaying and "⏸" or "▶"
    end)
    
    local connection
    connection = RunService.Heartbeat:Connect(function(dt)
        if isPlaying and #anim.frames > 0 then
            accumulatedTime = accumulatedTime + dt
            local frameDuration = 1/fps
            
            if accumulatedTime >= frameDuration then
                DrawFrame(anim.frames[currentFrameIndex])
                frameCounter.Text = currentFrameIndex .. " / " .. #anim.frames
                
                currentFrameIndex = currentFrameIndex + 1
                if currentFrameIndex > #anim.frames then
                    currentFrameIndex = 1
                end
                accumulatedTime = 0
            end
        end
    end)
    
    playerFrame.AncestryChanged:Connect(function()
        if not playerFrame.Parent then
            connection:Disconnect()
        end
    end)
    
    DrawFrame(anim.frames[1])
end

-- ==================== EDITOR DE ANIMACIÓN (CON HERRAMIENTAS PROFESIONALES) ====================

function CreateEditorScreen()
    if animationToEdit then
        frames = animationToEdit.frames
        currentFrame = 1
    else
        frames = {}
        currentFrame = 1
    end
    
    local editorFrame = screenGui:FindFirstChild("EditorScreen") or Instance.new("Frame")
    editorFrame.Name = "EditorScreen"
    editorFrame.Size = UDim2.new(1, 0, 1, 0)
    editorFrame.Position = UDim2.new(0, 0, 0, 0)
    editorFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
    editorFrame.BorderSizePixel = 0
    editorFrame.Parent = screenGui
    editorFrame.Visible = true
    
    local topBar = Instance.new("Frame")
    topBar.Size = UDim2.new(1, 0, 0, 60)
    topBar.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
    topBar.BorderSizePixel = 0
    topBar.Parent = editorFrame
    
    local topBarLayout = Instance.new("UIListLayout")
    topBarLayout.FillDirection = Enum.FillDirection.Horizontal
    topBarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    topBarLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    topBarLayout.Padding = UDim.new(0, 10)
    topBarLayout.Parent = topBar
    
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 10)
    padding.PaddingRight = UDim.new(0, 10)
    padding.Parent = topBar
    
    local editorTitle = Instance.new("TextLabel")
    editorTitle.Size = UDim2.new(0.5, 0, 1, 0)
    editorTitle.BackgroundTransparency = 1
    editorTitle.Text = animationToEdit and "✏️ EDITAR ANIMACIÓN" or "✏️ CREAR ANIMACIÓN"
    editorTitle.TextColor3 = Color3.fromRGB(254, 44, 85)
    editorTitle.Font = Enum.Font.GothamBold
    editorTitle.TextSize = 20
    editorTitle.TextXAlignment = Enum.TextXAlignment.Left
    editorTitle.Parent = topBar
    editorTitle.LayoutOrder = 0
    
    local backBtn = CreateButton("← VOLVER", topBar)
    backBtn.Size = UDim2.new(0, 100, 0, 40)
    backBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    backBtn.TextSize = 14
    backBtn.LayoutOrder = 1
    backBtn.MouseButton1Click:Connect(function()
        editorFrame:Destroy()
        CreateMainScreen().Visible = true
    end)
    
    local publishBtn = CreateButton(animationToEdit and "💾 GUARDAR" or "📤 PUBLICAR", topBar)
    publishBtn.Size = UDim2.new(0, 140, 0, 40)
    publishBtn.TextSize = 14
    publishBtn.LayoutOrder = 2
    publishBtn.MouseButton1Click:Connect(function()
        if #frames > 0 then
            OpenPublishDialog(editorFrame)
        else
            local notification = Instance.new("TextLabel")
            notification.Size = UDim2.new(0, 300, 0, 60)
            notification.Position = UDim2.new(0.5, -150, 0, 100)
            notification.BackgroundColor3 = Color3.fromRGB(254, 44, 85)
            notification.Text = "⚠️ Necesitas al menos 1 frame"
            notification.TextColor3 = Color3.new(1, 1, 1)
            notification.Font = Enum.Font.GothamBold
            notification.TextSize = 16
            notification.BorderSizePixel = 0
            notification.ZIndex = 10
            notification.Parent = editorFrame
            
            CreateUICorner(10).Parent = notification
            
            wait(2)
            notification:Destroy()
        end
    end)
    
    local editorContainer = Instance.new("Frame")
    editorContainer.Size = UDim2.new(1, 0, 1, -60)
    editorContainer.Position = UDim2.new(0, 0, 0, 60)
    editorContainer.BackgroundTransparency = 1
    editorContainer.Parent = editorFrame
    
    local editorContentLayout = Instance.new("UIListLayout")
    editorContentLayout.FillDirection = Enum.FillDirection.Horizontal
    editorContentLayout.Parent = editorContainer
    
    -- Panel de herramientas
    local toolPanel = Instance.new("Frame")
    toolPanel.Size = UDim2.new(0, 150, 1, 0)
    toolPanel.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    toolPanel.BorderSizePixel = 0
    toolPanel.Parent = editorContainer
    
    local toolPadding = Instance.new("UIPadding")
    toolPadding.PaddingTop = UDim.new(0, 10)
    toolPadding.PaddingBottom = UDim.new(0, 10)
    toolPadding.PaddingLeft = UDim.new(0, 10)
    toolPadding.PaddingRight = UDim.new(0, 10)
    toolPadding.Parent = toolPanel
    
    local toolListLayout = Instance.new("UIListLayout")
    toolListLayout.Padding = UDim.new(0, 10)
    toolListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    toolListLayout.Parent = toolPanel
    
    local toolTitle = Instance.new("TextLabel")
    toolTitle.Size = UDim2.new(1, 0, 0, 25)
    toolTitle.BackgroundTransparency = 1
    toolTitle.Text = "🎨 HERRAMIENTAS"
    toolTitle.TextColor3 = Color3.fromRGB(254, 44, 85)
    toolTitle.Font = Enum.Font.GothamBold
    toolTitle.TextSize = 12
    toolTitle.Parent = toolPanel
    
    -- Botones de herramientas
    local toolsContainer = Instance.new("Frame")
    toolsContainer.Size = UDim2.new(1, 0, 0, 80)
    toolsContainer.BackgroundTransparency = 1
    toolsContainer.Parent = toolPanel
    
    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.CellSize = UDim2.new(0, 60, 0, 60)
    gridLayout.CellPadding = UDim2.new(0, 5, 0, 5)
    gridLayout.Parent = toolsContainer
    
    local tools = {
    {name = "pencil", icon = "✏️", text = "Lápiz"},
    {name = "eraser", icon = "🧹", text = "Borrador"}
    }
    
    local toolButtons = {}
    
    for i, tool in ipairs(tools) do
        local toolBtn = Instance.new("TextButton")
        toolBtn.Size = UDim2.new(0, 60, 0, 60)
        toolBtn.BackgroundColor3 = tool.name == currentTool and Color3.fromRGB(254, 44, 85) or Color3.fromRGB(40, 40, 40)
        toolBtn.Text = tool.icon
        toolBtn.TextSize = 28
        toolBtn.BorderSizePixel = 0
        toolBtn.Parent = toolsContainer
        
        CreateUICorner(10).Parent = toolBtn
        
        table.insert(toolButtons, {btn = toolBtn, toolName = tool.name})
        
        toolBtn.MouseButton1Click:Connect(function()
            currentTool = tool.name
            for _, tb in ipairs(toolButtons) do
                tb.btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            end
            toolBtn.BackgroundColor3 = Color3.fromRGB(254, 44, 85)
        end)
    end
    
    -- Grosor
    local thicknessLabel = Instance.new("TextLabel")
    thicknessLabel.Size = UDim2.new(1, 0, 0, 20)
    thicknessLabel.BackgroundTransparency = 1
    thicknessLabel.Text = "Grosor: 3px"
    thicknessLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    thicknessLabel.Font = Enum.Font.Gotham
    thicknessLabel.TextSize = 10
    thicknessLabel.TextXAlignment = Enum.TextXAlignment.Left
    thicknessLabel.Parent = toolPanel
    
    local sliderContainer = Instance.new("Frame")
    sliderContainer.Size = UDim2.new(1, 0, 0, 20)
    sliderContainer.BackgroundTransparency = 1
    sliderContainer.Parent = toolPanel
    
    local thicknessSlider = Instance.new("Frame")
    thicknessSlider.Size = UDim2.new(1, -20, 0, 6)
    thicknessSlider.Position = UDim2.new(0, 10, 0, 7)
    thicknessSlider.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    thicknessSlider.BorderSizePixel = 0
    thicknessSlider.Parent = sliderContainer
    
    CreateUICorner(3).Parent = thicknessSlider
    
    local sliderButton = Instance.new("TextButton")
    sliderButton.Size = UDim2.new(0, 20, 0, 20)
    sliderButton.Position = UDim2.new(0, -10, 0.5, -10)
    sliderButton.BackgroundColor3 = Color3.fromRGB(254, 44, 85)
    sliderButton.Text = ""
    sliderButton.BorderSizePixel = 0
    sliderButton.Parent = thicknessSlider
    
    CreateUICorner(10).Parent = sliderButton
    
    local dragging = false
    local function updateThickness(inputPos)
        local relativeX = math.clamp(inputPos.X - thicknessSlider.AbsolutePosition.X, 0, thicknessSlider.AbsoluteSize.X)
        local percent = relativeX / thicknessSlider.AbsoluteSize.X
        sliderButton.Position = UDim2.new(percent, -10, 0.5, -10)
        currentThickness = math.floor(3 + percent * 17)
        thicknessLabel.Text = "Grosor: " .. currentThickness .. "px"
    end
    
    sliderButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            updateThickness(input.Position)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateThickness(input.Position)
        end
    end)
    
    -- Paleta de colores
    local colorLabel = Instance.new("TextLabel")
    colorLabel.Size = UDim2.new(1, 0, 0, 20)
    colorLabel.BackgroundTransparency = 1
    colorLabel.Text = "Colores:"
    colorLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    colorLabel.Font = Enum.Font.Gotham
    colorLabel.TextSize = 10
    colorLabel.TextXAlignment = Enum.TextXAlignment.Left
    colorLabel.Parent = toolPanel
    
    local colorsContainer = Instance.new("Frame")
    colorsContainer.Size = UDim2.new(1, 0, 0, 80)
    colorsContainer.BackgroundTransparency = 1
    colorsContainer.Parent = toolPanel
    
    local colorGridLayout = Instance.new("UIGridLayout")
    colorGridLayout.CellSize = UDim2.new(0, 30, 0, 30)
    colorGridLayout.CellPadding = UDim2.new(0, 5, 0, 5)
    colorGridLayout.FillDirection = Enum.FillDirection.Horizontal
    colorGridLayout.Parent = colorsContainer
    
    local colors = {
    Color3.fromRGB(0, 0, 0),
    Color3.fromRGB(255, 255, 255),
    Color3.fromRGB(254, 44, 85),
    Color3.fromRGB(33, 150, 243),
    Color3.fromRGB(76, 175, 80),
    Color3.fromRGB(255, 235, 59),
    Color3.fromRGB(255, 152, 0),
    Color3.fromRGB(156, 39, 176)
    }
    
    local colorButtons = {}
    
    for i, color in ipairs(colors) do
        local colorBtn = Instance.new("TextButton")
        colorBtn.Size = UDim2.new(0, 30, 0, 30)
        colorBtn.BackgroundColor3 = color
        colorBtn.Text = ""
        colorBtn.BorderSizePixel = 2
        colorBtn.BorderColor3 = Color3.fromRGB(100, 100, 100)
        colorBtn.Parent = colorsContainer
        
        CreateUICorner(15).Parent = colorBtn
        table.insert(colorButtons, colorBtn)
        
        colorBtn.MouseButton1Click:Connect(function()
            currentColor = color
            for _, btn in ipairs(colorButtons) do
                btn.BorderSizePixel = 2
                btn.BorderColor3 = Color3.fromRGB(100, 100, 100)
            end
            colorBtn.BorderSizePixel = 3
            colorBtn.BorderColor3 = Color3.fromRGB(254, 44, 85)
        end)
    end
    
    colorButtons[1].BorderSizePixel = 3
    colorButtons[1].BorderColor3 = Color3.fromRGB(254, 44, 85)
    
    -- Onion Skin Toggle
    local onionSkinBtn = Instance.new("TextButton")
    onionSkinBtn.Size = UDim2.new(1, 0, 0, 35)
    onionSkinBtn.BackgroundColor3 = onionSkinEnabled and Color3.fromRGB(76, 175, 80) or Color3.fromRGB(60, 60, 60)
    onionSkinBtn.Text = onionSkinEnabled and "🧅 Cebolla: ON" or "🧅 Cebolla: OFF"
    onionSkinBtn.TextColor3 = Color3.new(1, 1, 1)
    onionSkinBtn.Font = Enum.Font.GothamBold
    onionSkinBtn.TextSize = 11
    onionSkinBtn.BorderSizePixel = 0
    onionSkinBtn.Parent = toolPanel
    
    CreateUICorner(8).Parent = onionSkinBtn
    
    onionSkinBtn.MouseButton1Click:Connect(function()
        onionSkinEnabled = not onionSkinEnabled
        onionSkinBtn.BackgroundColor3 = onionSkinEnabled and Color3.fromRGB(76, 175, 80) or Color3.fromRGB(60, 60, 60)
        onionSkinBtn.Text = onionSkinEnabled and "🧅 Cebolla: ON" or "🧅 Cebolla: OFF"
        RefreshCanvas()
    end)
    
    local clearBtn = CreateButton("🗑️ LIMPIAR", toolPanel)
    clearBtn.Size = UDim2.new(1, 0, 0, 35)
    clearBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    clearBtn.TextSize = 12
    clearBtn.MouseButton1Click:Connect(function()
        if frames[currentFrame] then
            frames[currentFrame].strokes = {}
            RefreshCanvas()
        end
    end)
    
    -- Canvas y Timeline
    local canvasTimelineContainer = Instance.new("Frame")
    canvasTimelineContainer.Size = UDim2.new(1, -150, 1, 0)
    canvasTimelineContainer.BackgroundTransparency = 1
    canvasTimelineContainer.Parent = editorContainer
    
    local canvasTimelineLayout = Instance.new("UIListLayout")
    canvasTimelineLayout.FillDirection = Enum.FillDirection.Vertical
    canvasTimelineLayout.Parent = canvasTimelineContainer
    
    local canvasContainer = Instance.new("Frame")
    canvasContainer.Size = UDim2.new(1, 0, 1, -120)
    canvasContainer.BackgroundTransparency = 1
    canvasContainer.Parent = canvasTimelineContainer
    
    local canvas = Instance.new("Frame")
    canvas.Name = "DrawCanvas"
    canvas.Size = UDim2.new(1, -20, 1, -20)
    canvas.Position = UDim2.new(0.5, 0, 0.5, 0)
    canvas.AnchorPoint = Vector2.new(0.5, 0.5)
    canvas.BackgroundColor3 = Color3.new(1, 1, 1)
    canvas.BorderSizePixel = 0
    canvas.Parent = canvasContainer
    
    CreateUICorner(15).Parent = canvas
    
    local aspectRatio = Instance.new("UIAspectRatioConstraint")
    aspectRatio.AspectRatio = 1.33
    aspectRatio.AspectType = Enum.AspectType.ScaleWithParentSize
    aspectRatio.Parent = canvas
    
    local drawingFrame = Instance.new("Frame")
    drawingFrame.Size = UDim2.new(1, 0, 1, 0)
    drawingFrame.BackgroundTransparency = 1
    drawingFrame.Parent = canvas
    
    local currentStroke = nil
    
    function RefreshCanvas()
        for _, child in ipairs(drawingFrame:GetChildren()) do
            if child:IsA("Frame") then
                child:Destroy()
            end
        end
        
        -- Onion Skin (frame anterior con transparencia)
        if onionSkinEnabled and currentFrame > 1 and frames[currentFrame - 1] then
            local prevFrame = frames[currentFrame - 1]
            if prevFrame.strokes then
                for _, stroke in ipairs(prevFrame.strokes) do
                    for _, point in ipairs(stroke.points) do
                        local dot = Instance.new("Frame")
                        dot.Position = UDim2.new(point.scaleX, 0, point.scaleY, 0)
                        dot.Size = UDim2.new(0, point.thickness, 0, point.thickness)
                        dot.BackgroundColor3 = point.color
                        dot.BackgroundTransparency = 0.7 -- Semi-transparente
                        dot.BorderSizePixel = 0
                        dot.Parent = drawingFrame
                        
                        local corner = Instance.new("UICorner")
                        corner.CornerRadius = UDim.new(1, 0)
                        corner.Parent = dot
                    end
                end
            end
        end
        
        -- Frame actual
        if frames[currentFrame] and frames[currentFrame].strokes then
            for _, stroke in ipairs(frames[currentFrame].strokes) do
                for _, point in ipairs(stroke.points) do
                    local dot = Instance.new("Frame")
                    dot.Position = UDim2.new(point.scaleX, 0, point.scaleY, 0)
                    dot.Size = UDim2.new(0, point.thickness, 0, point.thickness)
                    dot.BackgroundColor3 = point.color
                    dot.BorderSizePixel = 0
                    dot.Parent = drawingFrame
                    
                    local corner = Instance.new("UICorner")
                    corner.CornerRadius = UDim.new(1, 0)
                    corner.Parent = dot
                end
            end
        end
    end
    
    local function inputToScale(inputPos)
        local absSize = canvas.AbsoluteSize
        local relativePos = Vector2.new(
        inputPos.X - canvas.AbsolutePosition.X,
        inputPos.Y - canvas.AbsolutePosition.Y
        )
        return Vector2.new(
        relativePos.X / absSize.X,
        relativePos.Y / absSize.Y
        )
    end
    
    canvas.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
            input.UserInputType == Enum.UserInputType.Touch then
            isDrawing = true
            
            if not frames[currentFrame] then
                frames[currentFrame] = {strokes = {}}
            end
            
            if currentTool == "pencil" then
                currentStroke = {points = {}, color = currentColor, thickness = currentThickness}
                table.insert(frames[currentFrame].strokes, currentStroke)
                
                local currentScale = inputToScale(input.Position)
                lastScalePoint = currentScale
                
                table.insert(currentStroke.points, {
                scaleX = currentScale.X,
                scaleY = currentScale.Y,
                color = currentColor,
                thickness = currentThickness
                })
                
                RefreshCanvas()
            elseif currentTool == "eraser" then
                -- Borrador: elimina puntos cercanos
                local currentScale = inputToScale(input.Position)
                if frames[currentFrame].strokes then
                    for strokeIndex, stroke in ipairs(frames[currentFrame].strokes) do
                        local newPoints = {}
                        for _, point in ipairs(stroke.points) do
                            local distance = math.sqrt((point.scaleX - currentScale.X)^2 + (point.scaleY - currentScale.Y)^2)
                            if distance > 0.02 then -- Radio de borrado
                                table.insert(newPoints, point)
                            end
                        end
                        stroke.points = newPoints
                    end
                end
                RefreshCanvas()
            end
        end
    end)
    
    canvas.InputChanged:Connect(function(input)
        if isDrawing and
            (input.UserInputType == Enum.UserInputType.MouseMovement or
            input.UserInputType == Enum.UserInputType.Touch) then
            
            local newScale = inputToScale(input.Position)
            
            if currentTool == "pencil" and currentStroke and lastScalePoint then
                local numSteps = 5
                for i = 1, numSteps do
                    local t = i / numSteps
                    local interpScale = lastScalePoint:Lerp(newScale, t)
                    
                    table.insert(currentStroke.points, {
                    scaleX = interpScale.X,
                    scaleY = interpScale.Y,
                    color = currentColor,
                    thickness = currentThickness
                    })
                end
                lastScalePoint = newScale
                RefreshCanvas()
            elseif currentTool == "eraser" then
                if frames[currentFrame].strokes then
                    for strokeIndex, stroke in ipairs(frames[currentFrame].strokes) do
                        local newPoints = {}
                        for _, point in ipairs(stroke.points) do
                            local distance = math.sqrt((point.scaleX - newScale.X)^2 + (point.scaleY - newScale.Y)^2)
                            if distance > 0.02 then
                                table.insert(newPoints, point)
                            end
                        end
                        stroke.points = newPoints
                    end
                end
                RefreshCanvas()
            end
        end
    end)
    
    canvas.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
            input.UserInputType == Enum.UserInputType.Touch then
            isDrawing = false
            currentStroke = nil
            lastScalePoint = nil
        end
    end)
    
    -- Timeline
    local timelinePanel = Instance.new("Frame")
    timelinePanel.Size = UDim2.new(1, 0, 0, 120)
    timelinePanel.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    timelinePanel.BorderSizePixel = 0
    timelinePanel.Parent = canvasTimelineContainer
    
    CreateUICorner(10).Parent = timelinePanel
    
    local paddingTimeline = Instance.new("UIPadding")
    paddingTimeline.PaddingLeft = UDim.new(0, 10)
    paddingTimeline.PaddingRight = UDim.new(0, 10)
    paddingTimeline.Parent = timelinePanel
    
    local timelineTitle = Instance.new("TextLabel")
    timelineTitle.Size = UDim2.new(1, 0, 0, 30)
    timelineTitle.Position = UDim2.new(0, 0, 0, 5)
    timelineTitle.BackgroundTransparency = 1
    timelineTitle.Text = "🎞️ FRAMES"
    timelineTitle.TextColor3 = Color3.fromRGB(254, 44, 85)
    timelineTitle.Font = Enum.Font.GothamBold
    timelineTitle.TextSize = 14
    timelineTitle.TextXAlignment = Enum.TextXAlignment.Left
    timelineTitle.Parent = timelinePanel
    
    local framesScroll = Instance.new("ScrollingFrame")
    framesScroll.Size = UDim2.new(1, -90, 0, 70)
    framesScroll.Position = UDim2.new(0, 5, 0, 40)
    framesScroll.BackgroundTransparency = 1
    framesScroll.BorderSizePixel = 0
    framesScroll.ScrollBarThickness = 4
    framesScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    framesScroll.ScrollingDirection = Enum.ScrollingDirection.X
    framesScroll.Parent = timelinePanel
    
    local framesLayout = Instance.new("UIListLayout")
    framesLayout.FillDirection = Enum.FillDirection.Horizontal
    framesLayout.Padding = UDim.new(0, 10)
    framesLayout.Parent = framesScroll
    
    local function UpdateTimeline()
        for _, child in ipairs(framesScroll:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end
        
        for i = 1, math.max(#frames, 1) do
            local frameBtn = Instance.new("TextButton")
            frameBtn.Size = UDim2.new(0, 60, 0, 60)
            frameBtn.BackgroundColor3 = i == currentFrame and Color3.fromRGB(254, 44, 85) or Color3.fromRGB(40, 40, 40)
            frameBtn.Text = tostring(i)
            frameBtn.TextColor3 = Color3.new(1, 1, 1)
            frameBtn.Font = Enum.Font.GothamBold
            frameBtn.TextSize = 18
            frameBtn.BorderSizePixel = 0
            frameBtn.Parent = framesScroll
            
            CreateUICorner(8).Parent = frameBtn
            
            frameBtn.MouseButton1Click:Connect(function()
                currentFrame = i
                RefreshCanvas()
                UpdateTimeline()
            end)
        end
        
        framesScroll.CanvasSize = UDim2.new(0, framesLayout.AbsoluteContentSize.X + 10, 0, 0)
    end
    
    local addFrameBtn = CreateButton("➕", timelinePanel)
    addFrameBtn.Size = UDim2.new(0, 60, 0, 60)
    addFrameBtn.Position = UDim2.new(1, -70, 0, 40)
    addFrameBtn.AnchorPoint = Vector2.new(1, 0)
    addFrameBtn.TextSize = 24
    addFrameBtn.MouseButton1Click:Connect(function()
        table.insert(frames, {strokes = {}})
        currentFrame = #frames
        RefreshCanvas()
        UpdateTimeline()
    end)
    
    if #frames == 0 then
        frames[1] = {strokes = {}}
    end
    UpdateTimeline()
    RefreshCanvas()
    
end

-- ==================== DIÁLOGO DE PUBLICACIÓN ====================

function OpenPublishDialog(editorFrame)
    local dialogBg = Instance.new("Frame")
    dialogBg.Size = UDim2.new(1, 0, 1, 0)
    dialogBg.Position = UDim2.new(0, 0, 0, 0)
    dialogBg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    dialogBg.BorderSizePixel = 0
    dialogBg.ZIndex = 5
    dialogBg.Parent = screenGui
    
    local dialog = Instance.new("ScrollingFrame")
    dialog.Size = UDim2.new(1, 0, 1, 0)
    dialog.Position = UDim2.new(0, 0, 0, 0)
    dialog.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
    dialog.BorderSizePixel = 0
    dialog.ZIndex = 6
    dialog.ScrollBarThickness = 4
    dialog.ScrollBarImageColor3 = Color3.fromRGB(254, 44, 85)
    dialog.Parent = dialogBg
    
    local dialogLayout = Instance.new("UIListLayout")
    dialogLayout.Padding = UDim.new(0, 10)
    dialogLayout.SortOrder = Enum.SortOrder.LayoutOrder
    dialogLayout.Parent = dialog
    
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 20)
    padding.PaddingRight = UDim.new(0, 20)
    padding.PaddingTop = UDim.new(0, 20)
    padding.PaddingBottom = UDim.new(0, 20)
    padding.Parent = dialog
    
    CreateUICorner(15).Parent = dialog
    
    local dialogTitle = Instance.new("TextLabel")
    dialogTitle.Size = UDim2.new(1, 0, 0, 40)
    dialogTitle.BackgroundTransparency = 1
    dialogTitle.Text = animationToEdit and "💾 GUARDAR CAMBIOS" or "📤 PUBLICAR ANIMACIÓN"
    dialogTitle.TextColor3 = Color3.fromRGB(254, 44, 85)
    dialogTitle.Font = Enum.Font.GothamBold
    dialogTitle.TextSize = 24
    dialogTitle.Parent = dialog
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, 0, 0, 20)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "Título:"
    titleLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    titleLabel.Font = Enum.Font.Gotham
    titleLabel.TextSize = 14
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = dialog
    
    local titleBox = Instance.new("TextBox")
    titleBox.Size = UDim2.new(1, 0, 0, 40)
    titleBox.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    titleBox.Text = animationToEdit and animationToEdit.title or ""
    titleBox.PlaceholderText = "Mi increíble animación"
    titleBox.TextColor3 = Color3.new(1, 1, 1)
    titleBox.PlaceholderColor3 = Color3.fromRGB(100, 100, 100)
    titleBox.Font = Enum.Font.Gotham
    titleBox.TextSize = 16
    titleBox.BorderSizePixel = 0
    titleBox.Parent = dialog
    
    CreateUICorner(8).Parent = titleBox
    
    local descLabel = Instance.new("TextLabel")
    descLabel.Size = UDim2.new(1, 0, 0, 20)
    descLabel.BackgroundTransparency = 1
    descLabel.Text = "Descripción:"
    descLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    descLabel.Font = Enum.Font.Gotham
    descLabel.TextSize = 14
    descLabel.TextXAlignment = Enum.TextXAlignment.Left
    descLabel.Parent = dialog
    
    local descBox = Instance.new("TextBox")
    descBox.Size = UDim2.new(1, 0, 0, 80)
    descBox.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    descBox.Text = animationToEdit and animationToEdit.description or ""
    descBox.PlaceholderText = "Describe tu animación..."
    descBox.TextColor3 = Color3.new(1, 1, 1)
    descBox.PlaceholderColor3 = Color3.fromRGB(100, 100, 100)
    descBox.Font = Enum.Font.Gotham
    descBox.TextSize = 14
    descBox.BorderSizePixel = 0
    descBox.TextWrapped = true
    descBox.MultiLine = true
    descBox.TextYAlignment = Enum.TextYAlignment.Top
    descBox.Parent = dialog
    
    CreateUICorner(8).Parent = descBox
    
    local catLabel = Instance.new("TextLabel")
    catLabel.Size = UDim2.new(1, 0, 0, 20)
    catLabel.BackgroundTransparency = 1
    catLabel.Text = "Categoría:"
    catLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    catLabel.Font = Enum.Font.Gotham
    catLabel.TextSize = 14
    catLabel.TextXAlignment = Enum.TextXAlignment.Left
    catLabel.Parent = dialog
    
    local catContainer = Instance.new("Frame")
    catContainer.Size = UDim2.new(1, 0, 0, 40)
    catContainer.BackgroundTransparency = 1
    catContainer.Parent = dialog
    
    local catLayout = Instance.new("UIListLayout")
    catLayout.FillDirection = Enum.FillDirection.Horizontal
    catLayout.Padding = UDim.new(0, 5)
    catLayout.Parent = catContainer
    
    local selectedCategory = animationToEdit and animationToEdit.category or "Accion"
    local categories = {"Terror", "Comedia", "Accion", "Drama", "Aventura"}
    
    for i, cat in ipairs(categories) do
        local catBtn = Instance.new("TextButton")
        catBtn.Size = UDim2.new(0, 80, 1, 0)
        catBtn.BackgroundColor3 = cat == selectedCategory and Color3.fromRGB(254, 44, 85) or Color3.fromRGB(60, 60, 60)
        catBtn.Text = cat
        catBtn.TextColor3 = Color3.new(1, 1, 1)
        catBtn.Font = Enum.Font.GothamBold
        catBtn.TextSize = 12
        catBtn.BorderSizePixel = 0
        catBtn.Parent = catContainer
        
        CreateUICorner(6).Parent = catBtn
        
        catBtn.MouseButton1Click:Connect(function()
            selectedCategory = cat
            for _, btn in ipairs(catContainer:GetChildren()) do
                if btn:IsA("TextButton") then
                    btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
                end
            end
            catBtn.BackgroundColor3 = Color3.fromRGB(254, 44, 85)
        end)
    end
    
    local typeLabel = Instance.new("TextLabel")
    typeLabel.Size = UDim2.new(1, 0, 0, 20)
    typeLabel.BackgroundTransparency = 1
    typeLabel.Text = "Tipo:"
    typeLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    typeLabel.Font = Enum.Font.Gotham
    typeLabel.TextSize = 14
    typeLabel.TextXAlignment = Enum.TextXAlignment.Left
    typeLabel.Parent = dialog
    
    local typeContainer = Instance.new("Frame")
    typeContainer.Size = UDim2.new(1, 0, 0, 40)
    typeContainer.BackgroundTransparency = 1
    typeContainer.Parent = dialog
    
    local typeLayout = Instance.new("UIListLayout")
    typeLayout.FillDirection = Enum.FillDirection.Horizontal
    typeLayout.Padding = UDim.new(0, 10)
    typeLayout.Parent = typeContainer
    
    local selectedType = animationToEdit and animationToEdit.type or "Pelicula"
    local types = {"Pelicula", "Serie"}
    
    for i, typ in ipairs(types) do
        local typeBtn = Instance.new("TextButton")
        typeBtn.Size = UDim2.new(0.5, -5, 1, 0)
        typeBtn.BackgroundColor3 = typ == selectedType and Color3.fromRGB(254, 44, 85) or Color3.fromRGB(60, 60, 60)
        typeBtn.Text = typ == "Pelicula" and "🎬 PELÍCULA" or "📺 SERIE"
        typeBtn.TextColor3 = Color3.new(1, 1, 1)
        typeBtn.Font = Enum.Font.GothamBold
        typeBtn.TextSize = 14
        typeBtn.BorderSizePixel = 0
        typeBtn.Parent = typeContainer
        
        CreateUICorner(8).Parent = typeBtn
        
        typeBtn.MouseButton1Click:Connect(function()
            selectedType = typ
            for _, btn in ipairs(typeContainer:GetChildren()) do
                if btn:IsA("TextButton") then
                    btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
                end
            end
            typeBtn.BackgroundColor3 = Color3.fromRGB(254, 44, 85)
        end)
    end
    
    -- Editor de Thumbnail
    local thumbnailLabel = Instance.new("TextLabel")
    thumbnailLabel.Size = UDim2.new(1, 0, 0, 20)
    thumbnailLabel.BackgroundTransparency = 1
    thumbnailLabel.Text = "Imagen de portada (Thumbnail):"
    thumbnailLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    thumbnailLabel.Font = Enum.Font.Gotham
    thumbnailLabel.TextSize = 14
    thumbnailLabel.TextXAlignment = Enum.TextXAlignment.Left
    thumbnailLabel.Parent = dialog
    
    local thumbnailContainer = Instance.new("Frame")
    thumbnailContainer.Size = UDim2.new(1, 0, 0, 150)
    thumbnailContainer.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    thumbnailContainer.BorderSizePixel = 0
    thumbnailContainer.Parent = dialog
    
    CreateUICorner(10).Parent = thumbnailContainer
    
    local selectedThumbnailIndex = 1
    
    local thumbnailScroll = Instance.new("ScrollingFrame")
    thumbnailScroll.Size = UDim2.new(1, -10, 1, -10)
    thumbnailScroll.Position = UDim2.new(0, 5, 0, 5)
    thumbnailScroll.BackgroundTransparency = 1
    thumbnailScroll.BorderSizePixel = 0
    thumbnailScroll.ScrollBarThickness = 4
    thumbnailScroll.ScrollBarImageColor3 = Color3.fromRGB(254, 44, 85)
    thumbnailScroll.ScrollingDirection = Enum.ScrollingDirection.X
    thumbnailScroll.Parent = thumbnailContainer
    
    local thumbLayout = Instance.new("UIListLayout")
    thumbLayout.FillDirection = Enum.FillDirection.Horizontal
    thumbLayout.Padding = UDim.new(0, 10)
    thumbLayout.Parent = thumbnailScroll
    
    for i, frameData in ipairs(frames) do
        local thumbBtn = Instance.new("TextButton")
        thumbBtn.Size = UDim2.new(0, 120, 0, 130)
        thumbBtn.BackgroundColor3 = i == selectedThumbnailIndex and Color3.fromRGB(254, 44, 85) or Color3.fromRGB(60, 60, 60)
        thumbBtn.BorderSizePixel = 0
        thumbBtn.Text = ""
        thumbBtn.Parent = thumbnailScroll
        
        CreateUICorner(8).Parent = thumbBtn
        
        local thumbCanvas = Instance.new("Frame")
        thumbCanvas.Size = UDim2.new(1, -10, 1, -30)
        thumbCanvas.Position = UDim2.new(0, 5, 0, 5)
        thumbCanvas.BackgroundColor3 = Color3.new(1, 1, 1)
        thumbCanvas.BorderSizePixel = 0
        thumbCanvas.Parent = thumbBtn
        
        CreateUICorner(6).Parent = thumbCanvas
        
        -- Dibujar preview del frame
        if frameData.strokes then
            for _, stroke in ipairs(frameData.strokes) do
                for _, point in ipairs(stroke.points) do
                    local dot = Instance.new("Frame")
                    dot.Position = UDim2.new(point.scaleX, 0, point.scaleY, 0)
                    dot.Size = UDim2.new(0, point.thickness or 3, 0, point.thickness or 3)
                    dot.BackgroundColor3 = point.color or Color3.new(0, 0, 0)
                    dot.BorderSizePixel = 0
                    dot.Parent = thumbCanvas
                    
                    local corner = Instance.new("UICorner")
                    corner.CornerRadius = UDim.new(1, 0)
                    corner.Parent = dot
                end
            end
        end
        
        local thumbLabel = Instance.new("TextLabel")
        thumbLabel.Size = UDim2.new(1, 0, 0, 20)
        thumbLabel.Position = UDim2.new(0, 0, 1, -20)
        thumbLabel.BackgroundTransparency = 1
        thumbLabel.Text = "Frame " .. i
        thumbLabel.TextColor3 = Color3.new(1, 1, 1)
        thumbLabel.Font = Enum.Font.GothamBold
        thumbLabel.TextSize = 10
        thumbLabel.Parent = thumbBtn
        
        thumbBtn.MouseButton1Click:Connect(function()
            selectedThumbnailIndex = i
            for _, btn in ipairs(thumbnailScroll:GetChildren()) do
                if btn:IsA("TextButton") then
                    btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
                end
            end
            thumbBtn.BackgroundColor3 = Color3.fromRGB(254, 44, 85)
        end)
    end
    
    thumbnailScroll.CanvasSize = UDim2.new(0, thumbLayout.AbsoluteContentSize.X + 10, 0, 0)
    
    local spacer = Instance.new("Frame")
    spacer.Size = UDim2.new(1, 0, 0, 20)
    spacer.BackgroundTransparency = 1
    spacer.Parent = dialog
    
    local actionContainer = Instance.new("Frame")
    actionContainer.Size = UDim2.new(1, 0, 0, 50)
    actionContainer.BackgroundTransparency = 1
    actionContainer.Parent = dialog
    
    local actionLayout = Instance.new("UIListLayout")
    actionLayout.FillDirection = Enum.FillDirection.Horizontal
    actionLayout.Padding = UDim.new(0, 10)
    actionLayout.Parent = actionContainer
    
    local cancelBtn = CreateButton("CANCELAR", actionContainer)
    cancelBtn.Size = UDim2.new(0.5, -5, 1, 0)
    cancelBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    cancelBtn.MouseButton1Click:Connect(function()
        dialogBg:Destroy()
    end)
    
    local publishBtnFinal = CreateButton(animationToEdit and "GUARDAR" or "PUBLICAR", actionContainer)
    publishBtnFinal.Size = UDim2.new(0.5, -5, 1, 0)
    publishBtnFinal.MouseButton1Click:Connect(function()
        local title = titleBox.Text
        local description = descBox.Text
        
        if title == "" or title == nil then
            titleBox.PlaceholderText = "⚠️ El título es obligatorio"
            titleBox.PlaceholderColor3 = Color3.fromRGB(254, 44, 85)
            return
        end
        
        -- Mostrar pantalla de carga PANTALLA COMPLETA
        local loadingScreen = Instance.new("Frame")
        loadingScreen.Size = UDim2.new(1, 0, 1, 0)
        loadingScreen.Position = UDim2.new(0, 0, 0, 0)
        loadingScreen.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        loadingScreen.BorderSizePixel = 0
        loadingScreen.ZIndex = 100
        loadingScreen.Parent = screenGui
        
        local loadingText = Instance.new("TextLabel")
        loadingText.Size = UDim2.new(1, 0, 0, 50)
        loadingText.Position = UDim2.new(0, 0, 0.5, -80)
        loadingText.BackgroundTransparency = 1
        loadingText.Text = animationToEdit and "💾 Guardando cambios..." or "📤 Publicando animación..."
        loadingText.TextColor3 = Color3.new(1, 1, 1)
        loadingText.Font = Enum.Font.GothamBold
        loadingText.TextSize = 24
        loadingText.ZIndex = 101
        loadingText.Parent = loadingScreen
        
        local loadingBarBg = Instance.new("Frame")
        loadingBarBg.Size = UDim2.new(0.6, 0, 0, 8)
        loadingBarBg.Position = UDim2.new(0.2, 0, 0.5, 0)
        loadingBarBg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        loadingBarBg.BorderSizePixel = 0
        loadingBarBg.ZIndex = 101
        loadingBarBg.Parent = loadingScreen
        
        CreateUICorner(4).Parent = loadingBarBg
        
        local loadingBar = Instance.new("Frame")
        loadingBar.Size = UDim2.new(0, 0, 1, 0)
        loadingBar.BackgroundColor3 = Color3.fromRGB(254, 44, 85)
        loadingBar.BorderSizePixel = 0
        loadingBar.ZIndex = 102
        loadingBar.Parent = loadingBarBg
        
        CreateUICorner(4).Parent = loadingBar
        
        -- Animación de carga
        spawn(function()
            for i = 1, 100, 2 do
                loadingBar.Size = UDim2.new(i/100, 0, 1, 0)
                wait(0.02)
            end
        end)
        
        local animationData = {
        title = title,
        description = description ~= "" and description or "Sin descripción",
        category = selectedCategory,
        type = selectedType,
        frames = frames,
        thumbnail = frames[selectedThumbnailIndex] or frames[1]
        }
        
        if animationToEdit then
            animationData.id = animationToEdit.id
            EditAnimation:FireServer(animationData)
        else
            PublishAnimation:FireServer(animationData)
        end
        
        wait(2)
        loadingScreen:Destroy()
        dialogBg:Destroy()
        
        local successNotif = Instance.new("Frame")
        successNotif.Size = UDim2.new(1, 0, 0, 100)
        successNotif.Position = UDim2.new(0, 0, 0.5, -50)
        successNotif.BackgroundColor3 = Color3.fromRGB(76, 175, 80)
        successNotif.BorderSizePixel = 0
        successNotif.ZIndex = 10
        successNotif.Parent = screenGui
        
        local successText = Instance.new("TextLabel")
        successText.Size = UDim2.new(1, 0, 1, 0)
        successText.BackgroundTransparency = 1
        successText.Text = animationToEdit and "✓ ¡Animación actualizada!" or "✓ ¡Animación publicada con éxito!"
        successText.TextColor3 = Color3.new(1, 1, 1)
        successText.Font = Enum.Font.GothamBold
        successText.TextSize = 18
        successText.TextWrapped = true
        successText.ZIndex = 11
        successText.Parent = successNotif
        
        wait(3)
        successNotif:Destroy()
        editorFrame:Destroy()
        CreateMainScreen()
    end)
    
end

-- ==================== SISTEMA DE NOTIFICACIONES ====================

PublishAnimation.OnClientEvent:Connect(function(action, data)
    if action == "NewAnimation" then
        local notif = Instance.new("Frame")
        notif.Size = UDim2.new(0, 350, 0, 80)
        notif.Position = UDim2.new(1, -370, 0, 20)
        notif.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        notif.BorderSizePixel = 0
        notif.ZIndex = 100
        notif.Parent = screenGui
        
        CreateUICorner(12).Parent = notif
        
        local notifIcon = Instance.new("TextLabel")
        notifIcon.Size = UDim2.new(0, 60, 0, 60)
        notifIcon.Position = UDim2.new(0, 10, 0, 10)
        notifIcon.BackgroundColor3 = Color3.fromRGB(254, 44, 85)
        notifIcon.Text = "🎬"
        notifIcon.TextSize = 32
        notifIcon.BorderSizePixel = 0
        notifIcon.ZIndex = 101
        notifIcon.Parent = notif
        
        CreateUICorner(10).Parent = notifIcon
        
        local notifText = Instance.new("TextLabel")
        notifText.Size = UDim2.new(1, -80, 1, -20)
        notifText.Position = UDim2.new(0, 75, 0, 10)
        notifText.BackgroundTransparency = 1
        notifText.Text = "Nueva animación\n" .. data.title
        notifText.TextColor3 = Color3.new(1, 1, 1)
        notifText.Font = Enum.Font.GothamBold
        notifText.TextSize = 14
        notifText.TextXAlignment = Enum.TextXAlignment.Left
        notifText.TextYAlignment = Enum.TextYAlignment.Center
        notifText.ZIndex = 101
        notifText.Parent = notif
        
        notif.Position = UDim2.new(1, 20, 0, 20)
        CreateTween(notif, {Position = UDim2.new(1, -370, 0, 20)}, 0.5)
        
        wait(4)
        
        CreateTween(notif, {Position = UDim2.new(1, 20, 0, 20)}, 0.5)
        wait(0.5)
        notif:Destroy()
    end
    
end)

LikeAnimation.OnClientEvent:Connect(function(status, likes)
    local notif = Instance.new("Frame")
    notif.Size = UDim2.new(0.7, 0, 0, 60)
    notif.Position = UDim2.new(0.5, 0, 0, 100)
    notif.AnchorPoint = Vector2.new(0.5, 0)
    notif.BorderSizePixel = 0
    notif.ZIndex = 100
    notif.Parent = screenGui
    
    if status == "Success" then
        notif.BackgroundColor3 = Color3.fromRGB(254, 44, 85)
        local text = Instance.new("TextLabel")
        text.Size = UDim2.new(1, 0, 1, 0)
        text.BackgroundTransparency = 1
        text.Text = "❤️ ¡Te gusta esta animación!"
        text.TextColor3 = Color3.new(1, 1, 1)
        text.Font = Enum.Font.GothamBold
        text.TextSize = 16
        text.ZIndex = 101
        text.Parent = notif
    else
        notif.BackgroundColor3 = Color3.fromRGB(255, 152, 0)
        local text = Instance.new("TextLabel")
        text.Size = UDim2.new(1, 0, 1, 0)
        text.BackgroundTransparency = 1
        text.Text = "Ya diste like a esta animación"
        text.TextColor3 = Color3.new(1, 1, 1)
        text.Font = Enum.Font.GothamBold
        text.TextSize = 14
        text.ZIndex = 101
        text.Parent = notif
    end
    
    CreateUICorner(10).Parent = notif
    
    wait(2)
    notif:Destroy()
    
end)

-- ==================== INICIALIZACIÓN ====================

CreateMainScreen()

print("[AnimFlix] Sistema de UI cargado - Estilo TikTok")

