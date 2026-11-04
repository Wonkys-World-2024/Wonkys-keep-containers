function print_table(node)
    local cache, stack, output = {}, {}, {}
    local depth = 1
    local output_str = "{\n"

    while true do
        local size = 0

        for _ in pairs(node) do
            size = size + 1
        end

        local cur_index = 1

        for k, v in pairs(node) do
            if cache[node] == nil or cur_index >= cache[node] then
                if string.find(output_str, "}", #output_str) then
                    output_str = output_str .. ",\n"
                elseif not string.find(output_str, "\n", #output_str) then
                    output_str = output_str .. "\n"
                end

                table.insert(output, output_str)
                output_str = ""

                local key

                if type(k) == "number" or type(k) == "boolean" then
                    key = "[" .. tostring(k) .. "]"
                else
                    key = "['" .. tostring(k) .. "']"
                end

                if type(v) == "number" or type(v) == "boolean" then
                    output_str = output_str ..
                        string.rep("\t", depth) ..
                        key .. " = " .. tostring(v)

                elseif type(v) == "table" then
                    output_str = output_str ..
                        string.rep("\t", depth) ..
                        key .. " = {\n"

                    table.insert(stack, node)
                    table.insert(stack, v)
                    cache[node] = cur_index + 1
                    break

                else
                    output_str = output_str ..
                        string.rep("\t", depth) ..
                        key .. " = '" .. tostring(v) .. "'"
                end

                if cur_index == size then
                    output_str = output_str ..
                        "\n" .. string.rep("\t", depth - 1) .. "}"
                else
                    output_str = output_str .. ","
                end
            else
                if cur_index == size then
                    output_str = output_str ..
                        "\n" .. string.rep("\t", depth - 1) .. "}"
                end
            end

            cur_index = cur_index + 1
        end

        if size == 0 then
            output_str = output_str ..
                "\n" .. string.rep("\t", depth - 1) .. "}"
        end

        if #stack > 0 then
            node = stack[#stack]
            stack[#stack] = nil
            depth = cache[node] == nil and depth + 1 or depth - 1
        else
            break
        end
    end

    table.insert(output, output_str)
    print(table.concat(output))
end

function IndexOf(array, value)
    for i, v in ipairs(array) do
        if v == value then
            return i
        end
    end

    return nil
end

function KeyOf(tbl, value)
    for k, v in pairs(tbl) do
        if v == value then
            return k
        end
    end

    return nil
end

function RoundNum(n)
    return math.floor(n + 0.5)
end

function Round(num, dp)
    local mult = 10 ^ (dp or 0)
    return math.floor(num * mult + 0.5) / mult
end

function RandomID(length)
    local result = {}

    for i = 1, length do
        local char

        if math.random(1, 2) == 1 then
            char = string.char(math.random(97, 122))

            if math.random(1, 2) == 1 then
                char = char:upper()
            end
        else
            char = tostring(math.random(0, 9))
        end

        result[#result + 1] = char
    end

    return table.concat(result)
end

function Framework()
    local framework = tostring(Config.FrameWork or 'qbox'):lower()

    if framework == 'qb' then
        return 1
    elseif framework == 'esx' then
        return 2
    elseif framework == 'qbox' then
        return 3
    end

    return 3
end

function GetCoreObject()
    if Framework() == 3 then
        return exports.qbx_core
    elseif Framework() == 1 then
        return exports['qb-core']:GetCoreObject()
    elseif Framework() == 2 then
        return exports['es_extended']:getSharedObject()
    end
end

function TableToVector3(t)
    return vector3(
        tonumber(t.x) or 0.0,
        tonumber(t.y) or 0.0,
        tonumber(t.z) or 0.0
    )
end

function LoadModel(hash)
    if not HasModelLoaded(hash) then
        RequestModel(hash)

        while not HasModelLoaded(hash) do
            Wait(10)
        end
    end
end

function WaitForEntity(entity)
    while not DoesEntityExist(entity) do
        Wait(10)
    end
end