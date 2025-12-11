-- LOCAL SCRIPT - AnimFlix Simple Version (Netflix Style)
-- Coloca este script en StarterPlayer > StarterPlayerScripts

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Esperar RemoteEvents (con timeout)
local RemoteEvents = ReplicatedStorage:WaitForChild("AnimFlixRemotes", 10)
if not RemoteEvents then
    warn("[AnimFlix] No se encontraron RemoteEvents")
    return
end

local PublishAnimation = RemoteEvents:WaitForChild("PublishAnimation", 5)
local GetAnimations = RemoteEvents:WaitForChild("GetAnimations", 5)
local PlayAnimation = RemoteEvents:WaitForChild("PlayAnimation", 5)
local LikeAnimation = RemoteEvents:WaitForChild("LikeAnimation", 5)
local EditAnimation = RemoteEvents:WaitForChild("EditAnimation", 5)

-- Variables globales del editor
local frames = {}
local currentFrame = 1
local isDrawing = false
local lastScalePoint = nil
local currentColor = Color3.fromRGB(0, 0, 0)
local currentThickness = 3
local currentTool = "pencil"
local onionSkinEnabled = true
local animationToEdit = nil

-- Crear ScreenGui principal
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AnimFlixUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

-- Funciones auxiliares
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

local function CreateButton(text, parent)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 160, 0, 45)
    button.BackgroundColor3 = Color3.fromRGB(229, 9, 20)
    button.Text = text
    button.TextColor3 = Color3.new(1, 1, 1)
    button.Font = Enum.Font.GothamBold
    button.TextSize = 16
    button.BorderSizePixel = 0
    button.Parent = parent
    
    CreateUICorner(22).Parent = button
    
    return button
end

-- Pantalla principal
local function CreateMainScreen()
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainScreen"
    mainFrame.Size = UDim2.new(1, 0, 1, 0)
    mainFrame.Position = UDim2.new(0, 0, 0, 0)
    mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui
    
    -- Barra superior
    local topBar = Instance.new("Frame")
    topBar.Size = UDim2.new(1, 0, 0, 60)
    topBar.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    topBar.BorderSizePixel = 0
    topBar.Parent = mainFrame
    
    local logo = Instance.new("TextLabel")
    logo.Size = UDim2.new(0, 200, 1, 0)
    logo.Position = UDim2.new(0, 20, 0, 0)
    logo.BackgroundTransparency = 1
    logo.Text = "ANIMFLIX"
    logo.TextColor3 = Color3.fromRGB(229, 9, 20)
    logo.Font = Enum.Font.GothamBold
    logo.TextSize = 24
    logo.TextXAlignment = Enum.TextXAlignment.Left
    logo.Parent = topBar
    
    local createBtn = CreateButton("➕ CREAR", topBar)
    createBtn.Size = UDim2.new(0, 120, 0, 40)
    createBtn.Position = UDim2.new(1, -140, 0, 10)
    createBtn.TextSize = 14
    createBtn.MouseButton1Click:Connect(function()
        mainFrame.Visible = false
        CreateEditorScreen()
    end)
    
    -- Contenido
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Size = UDim2.new(1, 0, 1, -60)
    scrollFrame.Position = UDim2.new(0, 0, 0, 60)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 4
    scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(229, 9, 20)
    scrollFrame.Parent = mainFrame
    
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 20)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = scrollFrame
    
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 20)
    padding.PaddingRight = UDim.new(0, 20)
    padding.PaddingTop = UDim.new(0, 20)
    padding.Parent = scrollFrame
    
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

-- Función para crear carrusel
function CreateCarousel(categoryName, animations, parentFrame)
    local carouselFrame = Instance.new("Frame")
    carouselFrame.Size = UDim2.new(1, 0, 0, 250)
    carouselFrame.BackgroundTransparency = 1
    carouselFrame.Parent = parentFrame
    
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
        card.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        card.BorderSizePixel = 0
        card.Text = ""
        card.Parent = carouselScroll
        
        CreateUICorner(15).Parent = card
        
        local thumbnail = Instance.new("Frame")
        thumbnail.Size = UDim2.new(1, 0, 0, 120)
        thumbnail.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
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
            CreateTween(card, {Size = UDim2.new(0, 150, 0, 210)}, 0.3)
        end)
        
        card.MouseLeave:Connect(function()
            CreateTween(card, {Size = UDim2.new(0, 140, 0, 200)}, 0.3)
        end)
        
        card.MouseButton1Click:Connect(function()
            OpenAnimationDetails(anim)
        end)
    end
end

-- Editor básico
function CreateEditorScreen()
    local editorFrame = Instance.new("Frame")
    editorFrame.Name = "EditorScreen"
    editorFrame.Size = UDim2.new(1, 0, 1, 0)
    editorFrame.Position = UDim2.new(0, 0, 0, 0)
    editorFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    editorFrame.BorderSizePixel = 0
    editorFrame.Parent = screenGui
    
    local backBtn = CreateButton("← VOLVER", editorFrame)
    backBtn.Size = UDim2.new(0, 100, 0, 40)
    backBtn.Position = UDim2.new(0, 20, 0, 10)
    backBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    backBtn.TextSize = 14
    backBtn.MouseButton1Click:Connect(function()
        editorFrame:Destroy()
        CreateMainScreen()
    end)
    
    local canvas = Instance.new("Frame")
    canvas.Name = "DrawCanvas"
    canvas.Size = UDim2.new(0.7, 0, 0.7, 0)
    canvas.Position = UDim2.new(0.15, 0, 0.15, 0)
    canvas.BackgroundColor3 = Color3.new(1, 1, 1)
    canvas.BorderSizePixel = 0
    canvas.Parent = editorFrame
    
    CreateUICorner(15).Parent = canvas
    
    print("[AnimFlix] Editor creado")
end

-- Detalles de animación básico
function OpenAnimationDetails(anim)
    local detailsFrame = Instance.new("Frame")
    detailsFrame.Name = "DetailsScreen"
    detailsFrame.Size = UDim2.new(1, 0, 1, 0)
    detailsFrame.Position = UDim2.new(0, 0, 0, 0)
    detailsFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    detailsFrame.BorderSizePixel = 0
    detailsFrame.Parent = screenGui
    detailsFrame.ZIndex = 5
    
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 50, 0, 50)
    closeBtn.Position = UDim2.new(0, 10, 0, 10)
    closeBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    closeBtn.Text = "✕"
    closeBtn.TextSize = 24
    closeBtn.TextColor3 = Color3.new(1, 1, 1)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.BorderSizePixel = 0
    closeBtn.Parent = detailsFrame
    
    CreateUICorner(25).Parent = closeBtn
    
    closeBtn.MouseButton1Click:Connect(function()
        detailsFrame:Destroy()
        CreateMainScreen()
    end)
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 60)
    title.Position = UDim2.new(0, 20, 0, 80)
    title.BackgroundTransparency = 1
    title.Text = anim.title
    title.TextColor3 = Color3.new(1, 1, 1)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 32
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = detailsFrame
    
    local playBtn = CreateButton("▶ REPRODUCIR", detailsFrame)
    playBtn.Size = UDim2.new(0, 200, 0, 50)
    playBtn.Position = UDim2.new(0, 20, 0, 160)
    playBtn.MouseButton1Click:Connect(function()
        PlayAnimation:FireServer(anim.id)
        print("[AnimFlix] Reproduciendo:", anim.title)
    end)
end

-- Inicializar
CreateMainScreen()
print("[AnimFlix] Sistema básico cargado - Estilo Netflix")