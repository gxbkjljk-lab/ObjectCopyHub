-- Object Copy Hub v3 (Revisión Final Limpia)
-- Compatible con Delta Executor
-- Correcciones: sintaxis limpia, sin paréntesis sobrantes, anti-duplicados, portapapeles estricto

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptagon/Kavo-UI-Library/main/source.lua"))()
local Window = Library.CreateLib("Object Copy Hub v3", "DarkTheme")

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- ====================== DATOS ======================
local InspectedObjects = {}
local CurrentIndex = 0

-- ====================== FUNCIÓN DE PORTAPAPELES ESTRICTA ======================
local function safeSetClipboard(text)
    if type(text) \~= "string" or text == "" then
        return false
    end

    if typeof(setclipboard) == "function" then
        local success = pcall(function()
            setclipboard(text)
        end)
        return success
    end

    return false
end

-- ====================== FUNCIONES ======================
local function getShapeData(part)
    if part:IsA("WedgePart") then
        return "WedgePart", "Cuña"
    elseif part:IsA("CornerWedgePart") then
        return "CornerWedgePart", "Cuña de esquina"
    elseif part:IsA("TrussPart") then
        return "TrussPart", "Truss"
    elseif part:IsA("Part") then
        if part.Shape == Enum.PartType.Ball then
            return "Part", "Bola"
        elseif part.Shape == Enum.PartType.Cylinder then
            return "Part", "Cilindro"
        end
        return "Part", "Bloque"
    end
    return part.ClassName, part.ClassName
end

local function validateMaterial(matName)
    local success, result = pcall(function()
        return Enum.Material[matName]
    end)
    return success and result or Enum.Material.Plastic
end

local function isDuplicate(newData)
    for _, existing in ipairs(InspectedObjects) do
        if existing.Name == newData.Name
            and existing.ClassName == newData.ClassName
            and existing.Size == newData.Size
            and existing.Color == newData.Color
            and existing.Position == newData.Position
            and existing.Material == newData.Material then
            return true
        end
    end
    return false
end

local function inspectObject(obj)
    if not obj or not obj:IsA("BasePart") then
        return nil
    end

    local color = obj.Color
    local rgb = string.format("%d, %d, %d", math.floor(color.R * 255), math.floor(color.G * 255), math.floor(color.B * 255))
    local size = string.format("%.3f, %.3f, %.3f", obj.Size.X, obj.Size.Y, obj.Size.Z)
    local pos = string.format("%.3f, %.3f, %.3f", obj.Position.X, obj.Position.Y, obj.Position.Z)
    local ori = string.format("%.3f, %.3f, %.3f", obj.Orientation.X, obj.Orientation.Y, obj.Orientation.Z)
    local className, shapeName = getShapeData(obj)

    local data = {
        Name = obj.Name,
        ClassName = className,
        ShapeName = shapeName,
        Color = rgb,
        Size = size,
        Position = pos,
        Orientation = ori,
        Material = obj.Material.Name,
        Transparency = obj.Transparency,
        Reflectance = obj.Reflectance,
        Anchored = obj.Anchored,
        CanCollide = obj.CanCollide,
        PartType = (obj:IsA("Part") and obj.Shape) or nil
    }

    if isDuplicate(data) then
        Library:Notify("Duplicado", "Este objeto ya está en la lista.", 3)
        return nil
    end

    table.insert(InspectedObjects, data)
    CurrentIndex = #InspectedObjects
    return data
end

local function getSelected()
    if CurrentIndex > 0 and InspectedObjects[CurrentIndex] then
        return InspectedObjects[CurrentIndex]
    end
    return nil
end

local function updateSelectionNotify()
    local obj = getSelected()
    if obj then
        Library:Notify("Seleccionado", string.format("[%d] %s (%s)", CurrentIndex, obj.Name, obj.ShapeName), 3)
    end
end

-- ====================== TAB 1: INSPECTOR ======================
local MainTab = Window:NewTab("Inspector")
local SearchSection = MainTab:NewSection("Buscar / Inspeccionar")

SearchSection:NewTextBox("Buscar por nombre (parcial)", "Ej: wall, part, floor...", function(txt)
    if txt == "" then return end
    local search = string.lower(txt)
    local found = 0

    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") and string.find(string.lower(v.Name), search) then
            if inspectObject(v) then
                found = found + 1
            end
        end
    end

    if found > 0 then
        Library:Notify("Éxito", found .. " objeto(s) nuevo(s) añadido(s).", 5)
        updateSelectionNotify()
    else
        Library:Notify("Info", "No se encontraron objetos nuevos con ese nombre.", 4)
    end
end)

SearchSection:NewButton("Inspeccionar objeto bajo el mouse", function()
    local target = Mouse.Target
    if target and target:IsA("BasePart") then
        local result = inspectObject(target)
        if result then
            Library:Notify("Inspeccionado", target.Name .. " añadido a la lista.", 4)
            updateSelectionNotify()
        end
    else
        Library:Notify("Error", "No estás apuntando a un BasePart.", 4)
    end
end)

-- ====================== TAB 2: LISTA ======================
local ListTab = Window:NewTab("Lista de Objetos")
local ListSection = ListTab:NewSection("Gestión de la lista")

ListSection:NewButton("← Anterior", function()
    if #InspectedObjects == 0 then
        Library:Notify("Error", "La lista está vacía.", 3)
        return
    end
    CurrentIndex = CurrentIndex - 1
    if CurrentIndex < 1 then
        CurrentIndex = #InspectedObjects
    end
    updateSelectionNotify()
end)

ListSection:NewButton("Siguiente →", function()
    if #InspectedObjects == 0 then
        Library:Notify("Error", "La lista está vacía.", 3)
        return
    end
    CurrentIndex = CurrentIndex + 1
    if CurrentIndex > #InspectedObjects then
        CurrentIndex = 1
    end
    updateSelectionNotify()
end)

ListSection:NewTextBox("Ir al índice", "Ej: 1, 5, 12...", function(txt)
    local idx = tonumber(txt)
    if idx and InspectedObjects[idx] then
        CurrentIndex = idx
        updateSelectionNotify()
    else
        Library:Notify("Error", "Índice no válido.", 3)
    end
end)

ListSection:NewButton("Copiar propiedades del seleccionado", function()
    local obj = getSelected()
    if not obj then
        Library:Notify("Error", "No hay ningún objeto seleccionado.", 3)
        return
    end

    local info = string.format(
        "Nombre: %s\nClase: %s (%s)\nColor: %s\nTamaño: %s\nPosición: %s\nOrientación: %s\nMaterial: %s\nTransparency: %.2f\nReflectance: %.2f\nAnchored: %s\nCanCollide: %s",
        obj.Name,
        obj.ClassName,
        obj.ShapeName,
        obj.Color,
        obj.Size,
        obj.Position,
        obj.Orientation,
        obj.Material,
        obj.Transparency,
        obj.Reflectance,
        tostring(obj.Anchored),
        tostring(obj.CanCollide)
    )

    local success = safeSetClipboard(info)

    if success then
        Library:Notify("Copiado", "Propiedades del objeto " .. CurrentIndex .. " copiadas al portapapeles.", 5)
    else
        Library:Notify("Error", "No se pudo copiar al portapapeles (setclipboard no disponible o falló).", 6)
        warn("[Object Copy Hub] Contenido:\n" .. info)
    end
end)

ListSection:NewButton("Exportar TODO (código completo)", function()
    if #InspectedObjects == 0 then
        Library:Notify("Error", "La lista está vacía.", 3)
        return
    end

    local lines = {
        "-- Object Copy Hub v3 - Exportación",
        "-- Pegar este código en un Script",
        ""
    }

    for i, obj in ipairs(InspectedObjects) do
        table.insert(lines, string.format("local p%d = Instance.new(\"%s\")", i, obj.ClassName))
        table.insert(lines, string.format("p%d.Name = \"%s\"", i, obj.Name:gsub("\"", "\\\"")))
        table.insert(lines, string.format("p%d.Size = Vector3.new(%s)", i, obj.Size))
        table.insert(lines, string.format("p%d.Color = Color3.fromRGB(%s)", i, obj.Color))
        table.insert(lines, string.format("p%d.Material = Enum.Material.%s", i, obj.Material))
        table.insert(lines, string.format("p%d.Transparency = %.3f", i, obj.Transparency))
        table.insert(lines, string.format("p%d.Reflectance = %.3f", i, obj.Reflectance))
        table.insert(lines, string.format("p%d.Anchored = %s", i, tostring(obj.Anchored)))
        table.insert(lines, string.format("p%d.CanCollide = %s", i, tostring(obj.CanCollide)))
        table.insert(lines, string.format("p%d.Position = Vector3.new(%s)", i, obj.Position))
        table.insert(lines, string.format("p%d.Orientation = Vector3.new(%s)", i, obj.Orientation))

        if obj.PartType then
            local shapeName = tostring(obj.PartType):match("Enum%.PartType%.(%w+)")
            if shapeName then
                table.insert(lines, string.format("p%d.Shape = Enum.PartType.%s", i, shapeName))
            end
        end

        table.insert(lines, string.format("p%d.Parent = workspace", i))
        table.insert(lines, "")
    end

    local exportStr = table.concat(lines, "\n")
    local success = safeSetClipboard(exportStr)

    if success then
        Library:Notify("Exportado", #InspectedObjects .. " objetos exportados al portapapeles.", 5)
    else
        Library:Notify("Error", "No se pudo copiar al portapapeles. El código se imprimió en la consola.", 6)
        warn("[Object Copy Hub] Código exportado:\n" .. exportStr)
    end
end)

ListSection:NewButton("Limpiar lista completa", function()
    InspectedObjects = {}
    CurrentIndex = 0
    Library:Notify("Lista limpia", "Se eliminaron todos los objetos.", 3)
end)

-- ====================== TAB 3: RECREAR ======================
local RecreateTab = Window:NewTab("Recrear")
local RecSection = RecreateTab:NewSection("Crear objeto localmente")

RecSection:NewButton("Crear objeto seleccionado (cerca mío)", function()
    local data = getSelected()
    if not data then
        Library:Notify("Error", "Selecciona un objeto primero.", 3)
        return
    end

    local character = LocalPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then
        Library:Notify("Error", "No se encontró el personaje. Reaparece.", 4)
        return
    end

    local p = Instance.new(data.ClassName)
    p.Name = data.Name

    local colors = {}
    for val in string.gmatch(data.Color, "([^,]+)") do
        table.insert(colors, tonumber(val))
    end
    p.Color = Color3.fromRGB(colors[1] or 255, colors[2] or 255, colors[3] or 255)

    local sizes = {}
    for val in string.gmatch(data.Size, "([^,]+)") do
        table.insert(sizes, tonumber(val))
    end
    p.Size = Vector3.new(sizes[1] or 1, sizes[2] or 1, sizes[3] or 1)

    p.Material = validateMaterial(data.Material)
    p.Transparency = data.Transparency or 0
    p.Reflectance = data.Reflectance or 0
    p.Anchored = true
    p.CanCollide = data.CanCollide

    if p:IsA("Part") and data.PartType then
        p.Shape = data.PartType
    end

    p.Parent = workspace
    p.Position = root.Position + Vector3.new(0, 6, 0)

    Library:Notify("Creado", data.Name .. " recreado encima tuyo.", 4)
end)

RecSection:NewButton("Crear en posición ORIGINAL", function()
    local data = getSelected()
    if not data then
        Library:Notify("Error", "Selecciona un objeto primero.", 3)
        return
    end

    local p = Instance.new(data.ClassName)
    p.Name = data.Name

    local colors = {}
    for val in string.gmatch(data.Color, "([^,]+)") do
        table.insert(colors, tonumber(val))
    end
    p.Color = Color3.fromRGB(colors[1] or 255, colors[2] or 255, colors[3] or 255)

    local sizes = {}
    for val in string.gmatch(data.Size, "([^,]+)") do
        table.insert(sizes, tonumber(val))
    end
    p.Size = Vector3.new(sizes[1] or 1, sizes[2] or 1, sizes[3] or 1)

    local pos = {}
    for val in string.gmatch(data.Position, "([^,]+)") do
        table.insert(pos, tonumber(val))
    end
    p.Position = Vector3.new(pos[1] or 0, pos[2] or 0, pos[3] or 0)

    local ori = {}
    for val in string.gmatch(data.Orientation, "([^,]+)") do
        table.insert(ori, tonumber(val))
    end
    p.Orientation = Vector3.new(ori[1] or 0, ori[2] or 0, ori[3] or 0)

    p.Material = validateMaterial(data.Material)
    p.Transparency = data.Transparency or 0
    p.Reflectance = data.Reflectance or 0
    p.Anchored = data.Anchored
    p.CanCollide = data.CanCollide

    if p:IsA("Part") and data.PartType then
        p.Shape = data.PartType
    end

    p.Parent = workspace
    Library:Notify("Creado", data.Name .. " creado en su posición original.", 4)
end)

-- Notificación de carga
Library:Notify("Cargado", "Object Copy Hub v3 listo", 5)
