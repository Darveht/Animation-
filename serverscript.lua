-- SERVER SCRIPT - AnimFlix System
-- Coloca este script en ServerScriptService
 
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
 
-- DataStores
local AnimationsStore = DataStoreService:GetDataStore("AnimFlixAnimations_v1")
local UserDataStore = DataStoreService:GetDataStore("AnimFlixUsers_v1")
 
-- RemoteEvents y RemoteFunctions
local RemoteEvents = ReplicatedStorage:FindFirstChild("AnimFlixRemotes") or Instance.new("Folder")
RemoteEvents.Name = "AnimFlixRemotes"
RemoteEvents.Parent = ReplicatedStorage
 
local PublishAnimation = RemoteEvents:FindFirstChild("PublishAnimation") or Instance.new("RemoteEvent")
PublishAnimation.Name = "PublishAnimation"
PublishAnimation.Parent = RemoteEvents
 
local GetAnimations = RemoteEvents:FindFirstChild("GetAnimations") or Instance.new("RemoteFunction")
GetAnimations.Name = "GetAnimations"
GetAnimations.Parent = RemoteEvents
 
local PlayAnimation = RemoteEvents:FindFirstChild("PlayAnimation") or Instance.new("RemoteEvent")
PlayAnimation.Name = "PlayAnimation"
PlayAnimation.Parent = RemoteEvents
 
local LikeAnimation = RemoteEvents:FindFirstChild("LikeAnimation") or Instance.new("RemoteEvent")
LikeAnimation.Name = "LikeAnimation"
LikeAnimation.Parent = RemoteEvents
 
local GetUserAnimations = RemoteEvents:FindFirstChild("GetUserAnimations") or Instance.new("RemoteFunction")
GetUserAnimations.Name = "GetUserAnimations"
GetUserAnimations.Parent = RemoteEvents
 
local EditAnimation = RemoteEvents:FindFirstChild("EditAnimation") or Instance.new("RemoteEvent")
EditAnimation.Name = "EditAnimation"
EditAnimation.Parent = RemoteEvents
 
-- Sistema de almacenamiento global
local GlobalAnimations = {}
local AnimationsByCategory = {
Terror = {},
Comedia = {},
Accion = {},
Drama = {},
Aventura = {},
Recientes = {}
}
 
-- Función para cargar todas las animaciones al inicio
local function LoadAllAnimations()
    local success, result = pcall(function()
        return AnimationsStore:GetAsync("GlobalAnimationsList") or {}
    end)
    
    if success and result then
        GlobalAnimations = result
        
        -- Organizar por categorías
        for category, _ in pairs(AnimationsByCategory) do
            AnimationsByCategory[category] = {}
        end
        
        -- Llenar categorías
        for _, anim in ipairs(GlobalAnimations) do
            if anim.category and AnimationsByCategory[anim.category] then
                table.insert(AnimationsByCategory[anim.category], anim)
            end
        end
        
        -- Ordenar recientes
        table.sort(GlobalAnimations, function(a, b)
            return (a.timestamp or 0) > (b.timestamp or 0)
        end)
        
        -- Top 20 recientes
        AnimationsByCategory.Recientes = {}
        for i = 1, math.min(20, #GlobalAnimations) do
            table.insert(AnimationsByCategory.Recientes, GlobalAnimations[i])
        end
        
        print("[AnimFlix] Cargadas " .. #GlobalAnimations .. " animaciones")
    end
end
 
-- Función para guardar animaciones
local function SaveGlobalAnimations()
    spawn(function()
        local success, err = pcall(function()
            AnimationsStore:SetAsync("GlobalAnimationsList", GlobalAnimations)
        end)
        if not success then
            warn("[AnimFlix] Error guardando animaciones globales: " .. tostring(err))
        end
    end)
end
 
-- Publicar animación
PublishAnimation.OnServerEvent:Connect(function(player, animationData)
    if not animationData then return end
    
    if not animationData.title or not animationData.frames or #animationData.frames == 0 then
        return
    end
    
    local animId = player.UserId .. "_" .. os.time() .. "_" .. math.random(1000, 9999)
    
    local newAnimation = {
    id = animId,
    title = animationData.title or "Sin título",
    description = animationData.description or "Sin descripción",
    creator = player.Name,
    creatorId = player.UserId,
    category = animationData.category or "Accion",
    type = animationData.type or "Pelicula",
    frames = animationData.frames,
    thumbnail = animationData.thumbnail or animationData.frames[1],
    duration = #animationData.frames,
    timestamp = os.time(),
    likes = 0,
    views = 0,
    likedBy = {}
    }
    
    table.insert(GlobalAnimations, 1, newAnimation)
    
    if AnimationsByCategory[newAnimation.category] then
        table.insert(AnimationsByCategory[newAnimation.category], 1, newAnimation)
    end
    
    table.insert(AnimationsByCategory.Recientes, 1, newAnimation)
    if #AnimationsByCategory.Recientes > 20 then
        table.remove(AnimationsByCategory.Recientes, #AnimationsByCategory.Recientes)
    end
    
    -- GUARDAR INMEDIATAMENTE EN DATASTORE (PERSISTENCIA GLOBAL)
    local success, err = pcall(function()
        AnimationsStore:SetAsync("GlobalAnimationsList", GlobalAnimations)
    end)
    
    if success then
        print("[AnimFlix] ✓ " .. player.Name .. " publicó: " .. newAnimation.title .. " (GUARDADO EN DATASTORE)")
    else
        warn("[AnimFlix] ✗ Error guardando animación en DataStore: " .. tostring(err))
    end
    
    -- Guardar en datos de usuario
    spawn(function()
        local success, userData = pcall(function()
            return UserDataStore:GetAsync("User_" .. player.UserId) or {animations = {}}
        end)
        
        if success then
            table.insert(userData.animations, animId)
            pcall(function()
                UserDataStore:SetAsync("User_" .. player.UserId, userData)
            end)
        end
    end)
    
    -- NOTIFICAR A TODOS LOS JUGADORES EN TODOS LOS SERVIDORES
    for _, p in ipairs(Players:GetPlayers()) do
        PublishAnimation:FireClient(p, "NewAnimation", newAnimation)
    end
    
end)
 
-- Editar animación
EditAnimation.OnServerEvent:Connect(function(player, animationData)
    if not animationData or not animationData.id then return end
    
    -- Buscar la animación
    for i, anim in ipairs(GlobalAnimations) do
        if anim.id == animationData.id and anim.creatorId == player.UserId then
            -- Actualizar datos
            anim.title = animationData.title or anim.title
            anim.description = animationData.description or anim.description
            anim.category = animationData.category or anim.category
            anim.type = animationData.type or anim.type
            anim.frames = animationData.frames or anim.frames
            anim.thumbnail = animationData.thumbnail or (animationData.frames and animationData.frames[1]) or anim.thumbnail
            anim.duration = animationData.frames and #animationData.frames or anim.duration
            anim.timestamp = os.time()
            
            -- Reorganizar categorías
            for category, _ in pairs(AnimationsByCategory) do
                AnimationsByCategory[category] = {}
            end
            
            for _, a in ipairs(GlobalAnimations) do
                if a.category and AnimationsByCategory[a.category] then
                    table.insert(AnimationsByCategory[a.category], a)
                end
            end
            
            -- GUARDAR INMEDIATAMENTE EN DATASTORE
            local success, err = pcall(function()
                AnimationsStore:SetAsync("GlobalAnimationsList", GlobalAnimations)
            end)
            
            if success then
                print("[AnimFlix] ✓ " .. player.Name .. " editó: " .. anim.title .. " (GUARDADO EN DATASTORE)")
            else
                warn("[AnimFlix] ✗ Error guardando edición en DataStore: " .. tostring(err))
            end
            break
        end
    end
end)
 
-- Obtener animaciones
GetAnimations.OnServerInvoke = function(player, filter, searchQuery)
    filter = filter or "Recientes"
    
    if filter == "Search" and searchQuery then
        -- Búsqueda por título
        local results = {}
        local lowerQuery = string.lower(searchQuery)
        
        for _, anim in ipairs(GlobalAnimations) do
            if string.find(string.lower(anim.title), lowerQuery) or 
                string.find(string.lower(anim.description or ""), lowerQuery) then
                table.insert(results, anim)
            end
        end
        
        return results
    elseif filter == "All" then
        return GlobalAnimations
    elseif AnimationsByCategory[filter] then
        return AnimationsByCategory[filter]
    else
        return AnimationsByCategory.Recientes
    end
end
 
-- Obtener animaciones de un usuario
GetUserAnimations.OnServerInvoke = function(player, userId)
    local userAnims = {}
    for _, anim in ipairs(GlobalAnimations) do
        if anim.creatorId == userId then
            table.insert(userAnims, anim)
        end
    end
    return userAnims
end
 
-- Dar like a una animación
LikeAnimation.OnServerEvent:Connect(function(player, animId)
    local foundAnim = nil
    for i, anim in ipairs(GlobalAnimations) do
        if anim.id == animId then
            foundAnim = anim
            break
        end
    end
    
    if foundAnim then
        local alreadyLiked = false
        for _, userId in ipairs(foundAnim.likedBy) do
            if userId == player.UserId then
                alreadyLiked = true
                break
            end
        end
        
        if not alreadyLiked then
            table.insert(foundAnim.likedBy, player.UserId)
            foundAnim.likes = foundAnim.likes + 1
            
            -- GUARDAR INMEDIATAMENTE
            pcall(function()
                AnimationsStore:SetAsync("GlobalAnimationsList", GlobalAnimations)
            end)
            
            LikeAnimation:FireClient(player, "Success", foundAnim.likes)
        else
            LikeAnimation:FireClient(player, "AlreadyLiked")
        end
    end
end)
 
-- Registrar visualización
PlayAnimation.OnServerEvent:Connect(function(player, animId)
    for i, anim in ipairs(GlobalAnimations) do
        if anim.id == animId then
            anim.views = anim.views + 1
            -- GUARDAR INMEDIATAMENTE
            spawn(function()
                pcall(function()
                    AnimationsStore:SetAsync("GlobalAnimationsList", GlobalAnimations)
                end)
            end)
            break
        end
    end
end)
 
-- Cargar animaciones al iniciar
LoadAllAnimations()
 
-- Autoguardado cada 5 minutos
spawn(function()
    while wait(300) do
        SaveGlobalAnimations()
    end
end)
 
print("[AnimFlix] Sistema de servidor iniciado correctamente")
