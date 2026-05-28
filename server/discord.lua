Discord = {}

local API_BASE = ('https://discord.com/api/%s'):format(Config.discord.apiVersion)
local AUTH     = ('Bot %s'):format(Config.discord.token)

local function jsonHeaders()
    return {
        ['Content-Type']  = 'application/json',
        ['Authorization'] = AUTH,
        ['User-Agent']    = 'RonyToDiscordBot (FiveM, 2.0.0)',
    }
end

local function retryAfterMs(headers)
    if not headers then return 1000 end
    local raw = headers['Retry-After'] or headers['retry-after'] or headers['X-RateLimit-Reset-After']
    local seconds = tonumber(raw)
    if not seconds then return 1000 end
    return math.max(math.floor(seconds * 1000), 250)
end

function Discord.request(method, endpoint, body)
    local p = promise.new()
    local payload = (body and next(body) ~= nil) and json.encode(body) or ''
    PerformHttpRequest(API_BASE .. endpoint, function(code, data, headers)
        local parsed
        if data and #data > 0 then
            local ok, decoded = pcall(json.decode, data)
            if ok then parsed = decoded end
        end
        p:resolve({ code = code, body = parsed, headers = headers or {}, raw = data })
    end, method, payload, jsonHeaders())
    return Citizen.Await(p)
end

function Discord.getMessages(channelId, afterId, limit)
    local endpoint
    if afterId then
        endpoint = ('/channels/%s/messages?after=%s&limit=%d'):format(channelId, afterId, limit or 50)
    else
        endpoint = ('/channels/%s/messages?limit=1'):format(channelId)
    end
    return Discord.request('GET', endpoint, nil)
end

local memberCache = {}
local MEMBER_TTL = 60 * 1000

function Discord.getMember(guildId, userId)
    if not guildId or guildId == '' or guildId == '000000000000000000' then return nil end
    local now = GetGameTimer()
    local cached = memberCache[userId]
    if cached and cached.expires > now then
        return cached.member
    end
    local res = Discord.request('GET', ('/guilds/%s/members/%s'):format(guildId, userId), nil)
    if res.code == 200 and res.body then
        memberCache[userId] = { member = res.body, expires = now + MEMBER_TTL }
        return res.body
    end
    return nil
end

function Discord.invalidateMember(userId)
    memberCache[userId] = nil
end

local webhookQueue = {}
local queueRunning = false

local function runQueue()
    if queueRunning then return end
    queueRunning = true
    Citizen.CreateThread(function()
        while #webhookQueue > 0 do
            local item = table.remove(webhookQueue, 1)
            local p = promise.new()
            PerformHttpRequest(item.url, function(code, data, headers)
                p:resolve({ code = code, headers = headers or {} })
            end, 'POST', json.encode(item.payload), { ['Content-Type'] = 'application/json' })

            local res = Citizen.Await(p)
            if res.code == 429 then
                item.attempts = (item.attempts or 0) + 1
                if item.attempts <= 5 then
                    table.insert(webhookQueue, 1, item)
                    Citizen.Wait(retryAfterMs(res.headers))
                end
            elseif res.code and res.code >= 500 then
                item.attempts = (item.attempts or 0) + 1
                if item.attempts <= 3 then
                    table.insert(webhookQueue, 1, item)
                    Citizen.Wait(1500 * item.attempts)
                end
            else
                Citizen.Wait(150)
            end
        end
        queueRunning = false
    end)
end

function Discord.webhook(url, payload)
    if not url or url == '' or url == 'https://discord.com/api/webhooks/' then return end
    webhookQueue[#webhookQueue + 1] = { url = url, payload = payload }
    runQueue()
end

local function buildAuthor(author)
    if not author then return nil, nil end
    local name = ('%s (%s)'):format(author.name or 'unknown', author.id or '0')
    return name, author.avatar
end

function Discord.sendMessage(text, author)
    local name, avatar = buildAuthor(author)
    Discord.webhook(Config.discord.webhookUrl, {
        username   = name,
        avatar_url = avatar,
        content    = text,
    })
end

function Discord.sendEmbed(opts, author)
    local name, avatar = buildAuthor(author)
    local embed = {
        color       = opts.color or Config.embedColors.info,
        title       = opts.title,
        description = opts.description,
    }
    if opts.footer and opts.footer ~= '' then
        embed.footer = { text = opts.footer }
    end
    if opts.image then
        embed.image = { url = opts.image }
    end
    Discord.webhook(Config.discord.webhookUrl, {
        username   = name,
        avatar_url = avatar,
        embeds     = { embed },
    })
end

function Discord.sendScreenshot(imageUrl)
    Discord.webhook(Config.discord.screenshotUrl, {
        username   = 'Screenshot',
        avatar_url = 'https://cdn.discordapp.com/embed/avatars/5.png',
        embeds     = { {
            color = Config.embedColors.info,
            image = { url = imageUrl },
        } },
    })
end
