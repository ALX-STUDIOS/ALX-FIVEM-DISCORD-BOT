Utils = {}

local RESET  = '^7'
local PREFIX = '^5[alx-discbot]^7 '

function Utils.log(level, msg)
    if level ~= 'error' and not Config.debug then return end
    local color = '^7'
    if level == 'ok' then color = '^2'
    elseif level == 'warn' then color = '^3'
    elseif level == 'error' then color = '^1' end
    print(PREFIX .. color .. tostring(msg) .. RESET)
end

function Utils.startsWith(str, prefix)
    if not str or not prefix then return false end
    return str:sub(1, #prefix) == prefix
end

function Utils.trim(str)
    if not str then return '' end
    return (str:gsub('^%s+', ''):gsub('%s+$', ''))
end

function Utils.split(input, sep)
    sep = sep or '%s'
    local t = {}
    for str in input:gmatch('([^' .. sep .. ']+)') do
        t[#t + 1] = str
    end
    return t
end

function Utils.tableContains(t, value)
    if not t then return false end
    for i = 1, #t do
        if t[i] == value then return true end
    end
    return false
end

function Utils.formatCoords(coords)
    if type(coords) == 'vector3' or type(coords) == 'vector4' then
        return string.format('%.2f, %.2f, %.2f', coords.x, coords.y, coords.z)
    end
    if type(coords) == 'table' then
        return string.format('%.2f, %.2f, %.2f', coords.x or 0, coords.y or 0, coords.z or 0)
    end
    return tostring(coords)
end

function Utils.toInt(value)
    if value == nil then return nil end
    local n = tonumber(value)
    if not n then return nil end
    return math.floor(n)
end

function Utils.toFloat(value)
    if value == nil then return nil end
    return tonumber(value)
end

function Utils.joinFrom(tokens, fromIndex)
    if not tokens or fromIndex > #tokens then return '' end
    return table.concat(tokens, ' ', fromIndex)
end
