local lastMessageId = nil
local botRunning = false

local function buildAvatar(author)
    if author.avatar then
        return ('https://cdn.discordapp.com/avatars/%s/%s.png?size=1024'):format(author.id, author.avatar)
    end
    local discriminator = tonumber(author.discriminator) or 0
    local index = discriminator > 0 and (discriminator % 5) or ((tonumber(author.id) or 0) % 6)
    return ('https://cdn.discordapp.com/embed/avatars/%d.png'):format(index)
end

local function buildContext(msg)
    return {
        raw    = msg.content,
        author = {
            id     = msg.author.id,
            name   = msg.author.username,
            avatar = buildAvatar(msg.author),
        },
    }
end

local function rolesAllowedFor(commandName)
    return Config.commandRoles[commandName] or Config.allowedRoles
end

local function userMayExecute(ctx, commandName)
    local roleList = rolesAllowedFor(commandName)
    if not roleList or #roleList == 0 then return true end
    if not Config.discord.guildId or Config.discord.guildId == '' or Config.discord.guildId == '000000000000000000' then
        Utils.log('error', 'allowedRoles is set but Config.discord.guildId is not configured — role checks will deny everyone.')
        return false
    end
    local member = Discord.getMember(Config.discord.guildId, ctx.author.id)
    if not member or not member.roles then
        Utils.log('warn', ('Could not fetch member %s from guild (missing GUILD_MEMBERS intent or bot not in guild?).'):format(ctx.author.id))
        return false
    end
    for i = 1, #member.roles do
        if Utils.tableContains(roleList, member.roles[i]) then return true end
    end
    return false
end

local function dispatch(msg)
    if msg.author.bot then return end
    local content = msg.content
    if not content or not Utils.startsWith(content, Config.discord.prefix) then return end

    local stripped = content:sub(#Config.discord.prefix + 1)
    local tokens   = Utils.split(stripped)
    local name     = tokens[1] and tokens[1]:lower() or nil
    if not name then return end

    if not Config.commands[name] then return end
    if not Commands.exists(name) then return end

    local ctx = buildContext(msg)
    Utils.log('info', ('Command from %s (%s): %s'):format(ctx.author.name, ctx.author.id, name))

    if not userMayExecute(ctx, name) then
        Utils.log('warn', ('Denied: %s lacks an allowed role for "%s".'):format(ctx.author.name, name))
        Discord.sendMessage('> ``🚫`` You are not allowed to use this command.', ctx.author)
        return
    end

    local args = {}
    for i = 2, #tokens do args[i - 1] = tokens[i] end

    local okStatus, errMsg = pcall(Commands.handlerFor(name), ctx, args)
    if not okStatus then
        Discord.sendMessage(('> ``💥`` Internal error executing ``%s``: ``%s``'):format(name, tostring(errMsg)), ctx.author)
    end
end

local function httpHint(code, body)
    if code == 0 then
        return 'No HTTP response — server has no outbound internet or Discord is unreachable.'
    elseif code == 401 then
        return 'Unauthorized — the bot token is wrong or malformed (it must be the Bot token, not the application/client secret).'
    elseif code == 403 then
        return 'Forbidden — the bot is not in the guild, cannot see the channel, or lacks View Channel / Read Message History.'
    elseif code == 404 then
        return 'Not found — the channel ID is wrong, or the bot is not in that guild.'
    elseif code == 429 then
        return 'Rate limited.'
    elseif body and body.message then
        return tostring(body.message)
    end
    return 'Unexpected response.'
end

local function fetchInitial()
    local res = Discord.getMessages(Config.discord.channelId, nil, 1)
    if res.code == 200 and res.body and res.body[1] then
        lastMessageId = res.body[1].id
    elseif res.code == 200 then
        Utils.log('warn', 'Channel is empty; will pick up the next message posted.')
    else
        Utils.log('error', ('Initial fetch failed (%s). %s'):format(tostring(res.code), httpHint(res.code, res.body)))
    end
end

Citizen.CreateThread(function()
    Citizen.Wait(2500)
    if Config.discord.token == 'XxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXx'
       or Config.discord.channelId == '000000000000000000' then
        Utils.log('error', 'Bot disabled: set Config.discord.token and Config.discord.channelId in shared/config.lua.')
        return
    end

    local waited = 0
    while not Bridge.ready() do
        Citizen.Wait(500)
        waited = waited + 500
        if waited == (Config.framework.esxLoadTimeout or 30000) then
            Utils.log('error', 'ESX never resolved. Is es_extended started and listed before this resource?')
        end
    end

    local info = Bridge.info()
    Utils.log('ok', ('Ready. inventory=%s skin=%s'):format(tostring(info.inventory), tostring(info.skin)))

    fetchInitial()
    if lastMessageId then
        Utils.log('info', ('Listening on channel %s (last message %s).'):format(Config.discord.channelId, lastMessageId))
    end
    botRunning = true

    while botRunning do
        Citizen.Wait(Config.discord.pollInterval)
        local res = Discord.getMessages(Config.discord.channelId, lastMessageId, 50)

        if res.code == 200 and type(res.body) == 'table' then
            -- Discord returns newest-first; iterate in chronological order
            for i = #res.body, 1, -1 do
                local msg = res.body[i]
                if msg and msg.id then
                    dispatch(msg)
                    lastMessageId = msg.id
                end
            end
        elseif res.code == 429 then
            local raw = res.headers['Retry-After'] or res.headers['retry-after']
            local wait = (tonumber(raw) or 60) * 1000
            Utils.log('warn', ('Rate limited. Backing off %dms.'):format(math.max(wait, 10000)))
            Citizen.Wait(math.max(wait, 10000))
        else
            Utils.log('error', ('Discord API returned %s. %s'):format(
                tostring(res.code),
                httpHint(res.code, res.body)
            ))
            Citizen.Wait(10000)
        end
    end
end)

RegisterNetEvent('alx-discbot:ScreenshotSV')
AddEventHandler('alx-discbot:ScreenshotSV', function(imageUrl)
    if type(imageUrl) ~= 'string' or imageUrl == '' then return end
    Discord.sendScreenshot(imageUrl)
end)
