Commands = {}

local handlers = {}

local function reply(ctx, text)
    Discord.sendMessage(text, ctx.author)
end

local function replyEmbed(ctx, opts)
    Discord.sendEmbed(opts, ctx.author)
end

local function err(ctx, message)
    reply(ctx, '> ``❌`` ' .. message)
end

local function buildSuccess(action, lines)
    local parts = { '> ``✔️`` ' .. action }
    for i = 1, #lines do
        parts[#parts + 1] = ' > ' .. lines[i]
    end
    return table.concat(parts, ' \n')
end

local function ok(ctx, action, lines)
    reply(ctx, buildSuccess(action, lines or {}))
end

local function resolvePlayer(ctx, idArg)
    if idArg == nil or idArg == '' then
        err(ctx, 'Missing player ID.')
        return nil
    end
    local src = tonumber(idArg)
    if not src then
        err(ctx, ('Invalid player ID: ``%s``.'):format(tostring(idArg)))
        return nil
    end
    if not GetPlayerName(src) then
        err(ctx, ('Player (ID: %s) is not online.'):format(idArg))
        return nil
    end
    local xPlayer = Bridge.getESX().GetPlayerFromId(src)
    if not xPlayer then
        err(ctx, ('Player (ID: %s) is not an ESX player.'):format(idArg))
        return nil
    end
    if not xPlayer.source then xPlayer.source = src end
    return xPlayer, src
end

local function requireArg(ctx, value, name)
    if value == nil or value == '' then
        err(ctx, ('Missing argument: ``%s``.'):format(name))
        return false
    end
    return true
end

local function requireNumber(ctx, value, name)
    if not requireArg(ctx, value, name) then return nil end
    local n = tonumber(value)
    if not n then
        err(ctx, ('Argument ``%s`` must be a number, got ``%s``.'):format(name, tostring(value)))
        return nil
    end
    return n
end

local function playerHeader(arg, xPlayer)
    return ('``🧍`` ID: %s ``(%s)``'):format(arg, Bridge.player.identifier(xPlayer))
end

local function notifyTarget(src, ctx, msg)
    TriggerClientEvent(Config.triggers.notify, src, ('%s %s'):format(ctx.author.name, msg))
end

local function register(name, handler)
    handlers[name] = handler
end


register('heal', function(ctx, args)
    local xPlayer, src = resolvePlayer(ctx, args[1])
    if not xPlayer then return end
    TriggerClientEvent('alx-discbot:Heal', src, 200)
    notifyTarget(src, ctx, 'healed you.')
    ok(ctx, 'heal', { playerHeader(args[1], xPlayer) })
end)

register('sethealth', function(ctx, args)
    local xPlayer, src = resolvePlayer(ctx, args[1])
    if not xPlayer then return end
    local hp = requireNumber(ctx, args[2], 'health')
    if not hp then return end
    TriggerClientEvent('alx-discbot:Heal', src, math.floor(hp + 100))
    notifyTarget(src, ctx, 'set your health.')
    ok(ctx, 'sethealth', {
        playerHeader(args[1], xPlayer),
        ('``❤️`` Health: %d'):format(math.floor(hp)),
    })
end)

register('armour', function(ctx, args)
    local xPlayer, src = resolvePlayer(ctx, args[1])
    if not xPlayer then return end
    TriggerClientEvent('alx-discbot:Armour', src, 100)
    notifyTarget(src, ctx, 'armoured you.')
    ok(ctx, 'armour', { playerHeader(args[1], xPlayer) })
end)

register('setarmour', function(ctx, args)
    local xPlayer, src = resolvePlayer(ctx, args[1])
    if not xPlayer then return end
    local value = requireNumber(ctx, args[2], 'armour')
    if not value then return end
    TriggerClientEvent('alx-discbot:Armour', src, math.floor(value))
    notifyTarget(src, ctx, 'set your armour.')
    ok(ctx, 'setarmour', {
        playerHeader(args[1], xPlayer),
        ('``🛡️`` Armour: %d'):format(math.floor(value)),
    })
end)

register('revive', function(ctx, args)
    local xPlayer, src = resolvePlayer(ctx, args[1])
    if not xPlayer then return end
    TriggerClientEvent(Config.triggers.revive, src)
    notifyTarget(src, ctx, 'revived you.')
    ok(ctx, 'revive', { playerHeader(args[1], xPlayer) })
end)

register('kill', function(ctx, args)
    local xPlayer, src = resolvePlayer(ctx, args[1])
    if not xPlayer then return end
    TriggerClientEvent('alx-discbot:Kill', src)
    notifyTarget(src, ctx, 'killed you.')
    ok(ctx, 'kill', { playerHeader(args[1], xPlayer) })
end)

register('setcoords', function(ctx, args)
    local xPlayer, src = resolvePlayer(ctx, args[1])
    if not xPlayer then return end
    local x = requireNumber(ctx, args[2], 'x')
    local y = requireNumber(ctx, args[3], 'y')
    local z = requireNumber(ctx, args[4], 'z')
    if not (x and y and z) then return end
    TriggerClientEvent('alx-discbot:setcoords', src, x, y, z)
    notifyTarget(src, ctx, 'set your coords.')
    ok(ctx, 'setcoords', {
        playerHeader(args[1], xPlayer),
        ('``🗺️`` %s'):format(Utils.formatCoords(vector3(x, y, z))),
    })
end)

register('freeze', function(ctx, args)
    local xPlayer, src = resolvePlayer(ctx, args[1])
    if not xPlayer then return end
    TriggerClientEvent('alx-discbot:Freeze', src)
    notifyTarget(src, ctx, 'froze you.')
    ok(ctx, 'freeze', { playerHeader(args[1], xPlayer) })
end)

register('unfreeze', function(ctx, args)
    local xPlayer, src = resolvePlayer(ctx, args[1])
    if not xPlayer then return end
    TriggerClientEvent('alx-discbot:UnFreeze', src)
    notifyTarget(src, ctx, 'unfroze you.')
    ok(ctx, 'unfreeze', { playerHeader(args[1], xPlayer) })
end)

register('tpway', function(ctx, args)
    local xPlayer, src = resolvePlayer(ctx, args[1])
    if not xPlayer then return end
    TriggerClientEvent('alx-discbot:tpway', src)
    notifyTarget(src, ctx, 'teleported you to your waypoint.')
    ok(ctx, 'tpway', { playerHeader(args[1], xPlayer) })
end)

register('visible', function(ctx, args)
    local xPlayer, src = resolvePlayer(ctx, args[1])
    if not xPlayer then return end
    TriggerClientEvent('alx-discbot:visible', src)
    notifyTarget(src, ctx, 'made you visible.')
    ok(ctx, 'visible', { playerHeader(args[1], xPlayer) })
end)

register('invisible', function(ctx, args)
    local xPlayer, src = resolvePlayer(ctx, args[1])
    if not xPlayer then return end
    TriggerClientEvent('alx-discbot:invisible', src)
    notifyTarget(src, ctx, 'made you invisible.')
    ok(ctx, 'invisible', { playerHeader(args[1], xPlayer) })
end)


register('spawnveh', function(ctx, args)
    local xPlayer, src = resolvePlayer(ctx, args[1])
    if not xPlayer then return end
    local model = args[2]
    TriggerClientEvent('alx-discbot:spawnveh', src, model)
    notifyTarget(src, ctx, 'spawned a vehicle for you.')
    local lines = { playerHeader(args[1], xPlayer) }
    if model then lines[#lines + 1] = ('``🚗`` Model: ``%s``'):format(model) end
    ok(ctx, 'spawnveh', lines)
end)

register('fixveh', function(ctx, args)
    local xPlayer, src = resolvePlayer(ctx, args[1])
    if not xPlayer then return end
    TriggerClientEvent('alx-discbot:fixveh', src)
    notifyTarget(src, ctx, 'fixed your vehicle.')
    ok(ctx, 'fixveh', { playerHeader(args[1], xPlayer) })
end)

register('delveh', function(ctx, args)
    local xPlayer, src = resolvePlayer(ctx, args[1])
    if not xPlayer then return end
    TriggerClientEvent('alx-discbot:delveh', src)
    notifyTarget(src, ctx, 'deleted your vehicle.')
    ok(ctx, 'delveh', { playerHeader(args[1], xPlayer) })
end)

register('setjob', function(ctx, args)
    local xPlayer, _ = resolvePlayer(ctx, args[1])
    if not xPlayer then return end
    if not requireArg(ctx, args[2], 'job') then return end
    local grade = requireNumber(ctx, args[3], 'grade')
    if not grade then return end
    Bridge.player.setJob(xPlayer, args[2], math.floor(grade))
    notifyTarget(xPlayer.source, ctx, 'changed your job.')
    ok(ctx, 'setjob', {
        playerHeader(args[1], xPlayer),
        ('``👷`` Job: ``%s``'):format(args[2]),
        ('``🛠`` Grade: ``%d``'):format(math.floor(grade)),
    })
end)

register('addmoney', function(ctx, args)
    local xPlayer = resolvePlayer(ctx, args[1])
    if not xPlayer then return end
    local amount = requireNumber(ctx, args[2], 'amount')
    if not amount then return end
    Bridge.player.addMoney(xPlayer, math.floor(amount))
    notifyTarget(xPlayer.source, ctx, 'added money to your wallet.')
    ok(ctx, 'addmoney', {
        playerHeader(args[1], xPlayer),
        ('``💵`` Wallet: +%d'):format(math.floor(amount)),
    })
end)

register('addbank', function(ctx, args)
    local xPlayer = resolvePlayer(ctx, args[1])
    if not xPlayer then return end
    local amount = requireNumber(ctx, args[2], 'amount')
    if not amount then return end
    Bridge.player.addAccountMoney(xPlayer, 'bank', math.floor(amount))
    notifyTarget(xPlayer.source, ctx, 'added money to your bank.')
    ok(ctx, 'addbank', {
        playerHeader(args[1], xPlayer),
        ('``🏦`` Bank: +%d'):format(math.floor(amount)),
    })
end)

register('giveitem', function(ctx, args)
    local xPlayer = resolvePlayer(ctx, args[1])
    if not xPlayer then return end
    if not requireArg(ctx, args[2], 'item') then return end
    local count = requireNumber(ctx, args[3], 'count')
    if not count then return end
    if not Bridge.giveItem(xPlayer, args[2], math.floor(count)) then
        err(ctx, ('Could not give item ``%s`` (inventory full?).'):format(args[2]))
        return
    end
    notifyTarget(xPlayer.source, ctx, 'gave you an item.')
    ok(ctx, 'giveitem', {
        playerHeader(args[1], xPlayer),
        ('``📦`` Item: ``%s``'):format(args[2]),
        ('``🔢`` Count: %d'):format(math.floor(count)),
    })
end)

register('openskin', function(ctx, args)
    local xPlayer = resolvePlayer(ctx, args[1])
    if not xPlayer then return end
    Bridge.openSkin(xPlayer.source)
    notifyTarget(xPlayer.source, ctx, 'opened your skin menu.')
    ok(ctx, 'openskin', { playerHeader(args[1], xPlayer) })
end)

register('giveweapon', function(ctx, args)
    local xPlayer = resolvePlayer(ctx, args[1])
    if not xPlayer then return end
    if not requireArg(ctx, args[2], 'weapon') then return end
    local ammo = requireNumber(ctx, args[3], 'ammo')
    if not ammo then return end
    if not Bridge.giveWeapon(xPlayer, args[2], math.floor(ammo)) then
        err(ctx, ('Could not give weapon ``%s``.'):format(args[2]))
        return
    end
    notifyTarget(xPlayer.source, ctx, 'gave you a weapon.')
    ok(ctx, 'giveweapon', {
        playerHeader(args[1], xPlayer),
        ('``🔫`` Weapon: ``%s``'):format(args[2]),
        ('``🔢`` Ammo: %d'):format(math.floor(ammo)),
    })
end)

register('getcoords', function(ctx, args)
    local xPlayer = resolvePlayer(ctx, args[1])
    if not xPlayer then return end
    ok(ctx, 'getcoords', {
        playerHeader(args[1], xPlayer),
        ('``🗺️`` Coords: ``%s``'):format(Utils.formatCoords(Bridge.player.coords(xPlayer))),
    })
end)

register('getgroup', function(ctx, args)
    local xPlayer = resolvePlayer(ctx, args[1])
    if not xPlayer then return end
    ok(ctx, 'getgroup', {
        playerHeader(args[1], xPlayer),
        ('``🎓`` Group: ``%s``'):format(Bridge.player.group(xPlayer)),
    })
end)

register('getname', function(ctx, args)
    local xPlayer = resolvePlayer(ctx, args[1])
    if not xPlayer then return end
    ok(ctx, 'getname', {
        playerHeader(args[1], xPlayer),
        ('``📋`` Name: ``%s``'):format(Bridge.player.name(xPlayer)),
    })
end)

register('getjob', function(ctx, args)
    local xPlayer = resolvePlayer(ctx, args[1])
    if not xPlayer then return end
    local job = Bridge.player.job(xPlayer)
    ok(ctx, 'getjob', {
        playerHeader(args[1], xPlayer),
        ('``📋`` Job: ``%s``'):format(job.name),
        ('``📊`` Grade: ``%s`` (``%s``)'):format(job.grade_label, job.grade),
    })
end)

register('getinventory', function(ctx, args)
    local xPlayer = resolvePlayer(ctx, args[1])
    if not xPlayer then return end
    local identifier = Bridge.player.identifier(xPlayer)
    Bridge.fetchInventory(xPlayer, function(data)
        local description = ('``%s``\n\n**Inventory**\n``%s``'):format(identifier, tostring(data.inventory or 'empty'))
        local footer = data.loadout and ('Loadout: %s'):format(tostring(data.loadout)) or nil
        replyEmbed(ctx, {
            color       = Config.embedColors.info,
            title       = ('Inventory — ID %s'):format(args[1]),
            description = description,
            footer      = footer,
        })
    end)
end)

register('user', function(ctx, args)
    local xPlayer = resolvePlayer(ctx, args[1])
    if not xPlayer then return end
    local identifier = Bridge.player.identifier(xPlayer)
    MySQL.query(
        'SELECT firstname, lastname, dateofbirth, sex, height FROM users WHERE identifier = ?',
        { identifier },
        function(rows)
            local row = rows and rows[1] or {}
            local money       = Bridge.player.accountMoney(xPlayer, 'money')
            local bank        = Bridge.player.accountMoney(xPlayer, 'bank')
            local blackMoney  = Bridge.player.accountMoney(xPlayer, 'black_money')
            local job         = Bridge.player.job(xPlayer)

            local lines = {
                ('Identifier: ``%s``'):format(identifier),
                ('Firstname: ``%s``'):format(tostring(row.firstname or '-')),
                ('Lastname: ``%s``'):format(tostring(row.lastname or '-')),
                ('Money: ``%s`` | Bank: ``%s`` | Black: ``%s``'):format(money, bank, blackMoney),
                ('Group: ``%s``'):format(Bridge.player.group(xPlayer)),
                ('Job: ``%s`` (``%s`` — %s)'):format(job.name, job.grade, job.grade_label),
                ('DOB: ``%s`` | Sex: ``%s`` | Height: ``%s``'):format(
                    tostring(row.dateofbirth or '-'),
                    tostring(row.sex or '-'),
                    tostring(row.height or '-')
                ),
            }

            replyEmbed(ctx, {
                color       = Config.embedColors.info,
                title       = ('User info — ID %s'):format(args[1]),
                description = table.concat(lines, '\n'),
            })
        end
    )
end)

register('kick', function(ctx, args)
    local xPlayer = resolvePlayer(ctx, args[1])
    if not xPlayer then return end
    local reason = Utils.joinFrom(args, 2)
    if reason == '' then reason = 'No reason provided.' end
    Bridge.player.kick(xPlayer, ('%s kicked you for: %s'):format(ctx.author.name, reason))
    ok(ctx, 'kick', {
        playerHeader(args[1], xPlayer),
        ('``🔨`` Reason: ``%s``'):format(reason),
    })
end)

register('notify', function(ctx, args)
    local xPlayer = resolvePlayer(ctx, args[1])
    if not xPlayer then return end
    local message = Utils.joinFrom(args, 2)
    if not requireArg(ctx, message ~= '' and message or nil, 'message') then return end
    TriggerClientEvent(Config.triggers.notify, xPlayer.source, ('%s notified you: %s'):format(ctx.author.name, message))
    ok(ctx, 'notify', {
        playerHeader(args[1], xPlayer),
        ('``🔔`` Msg: ``%s``'):format(message),
    })
end)

register('announce', function(ctx, args)
    local message = Utils.joinFrom(args, 1)
    if not requireArg(ctx, message ~= '' and message or nil, 'message') then return end
    local fullMsg = ('%s announced: %s'):format(ctx.author.name, message)
    if Config.triggers.announce.useChat then
        TriggerClientEvent(Config.triggers.announce.chatTrigger, -1, {
            color     = Config.triggers.announce.chatColor,
            multiline = Config.triggers.announce.chatMultiline,
            args      = { fullMsg },
        })
    else
        TriggerClientEvent(Config.triggers.announce.fallbackTrigger, -1, fullMsg)
    end
    ok(ctx, 'announce', { ('``📢`` Msg: ``%s``'):format(message) })
end)

register('screenshot', function(ctx, args)
    local xPlayer = resolvePlayer(ctx, args[1])
    if not xPlayer then return end
    TriggerClientEvent('alx-discbot:screenshotCL', xPlayer.source, Config.discord.screenshotUrl)
    ok(ctx, 'screenshot', { playerHeader(args[1], xPlayer) })
end)

register('plist', function(ctx, _)
    local ESX = Bridge.getESX()
    local xPlayers = ESX.GetPlayers()
    if #xPlayers == 0 then
        replyEmbed(ctx, {
            color       = Config.embedColors.info,
            title       = 'Player List',
            description = 'No players online.',
        })
        return
    end

    local lines = {}
    for i = 1, #xPlayers do
        local src = xPlayers[i]
        local xPlayer = ESX.GetPlayerFromId(src)
        if xPlayer then
            if not xPlayer.source then xPlayer.source = src end
            local job = Bridge.player.job(xPlayer)
            lines[#lines + 1] = ('`(ID: %s)` %s | %s | %s (%s) | Ping: %d'):format(
                src,
                GetPlayerName(src) or '?',
                Bridge.player.name(xPlayer) or '?',
                job.name, job.grade,
                GetPlayerPing(src)
            )
        end
    end

    local chunks, current, currentLen = {}, {}, 0
    for i = 1, #lines do
        local line = lines[i]
        if currentLen + #line + 1 > 3800 and #current > 0 then
            chunks[#chunks + 1] = table.concat(current, '\n')
            current, currentLen = {}, 0
        end
        current[#current + 1] = line
        currentLen = currentLen + #line + 1
    end
    if #current > 0 then
        chunks[#chunks + 1] = table.concat(current, '\n')
    end

    for i = 1, #chunks do
        replyEmbed(ctx, {
            color       = Config.embedColors.info,
            title       = ('Player List (%d) — %d/%d'):format(#xPlayers, i, #chunks),
            description = chunks[i],
        })
    end
end)

register('help', function(ctx, _)
    local prefix = Config.discord.prefix
    local rows = {
        ('``%sheal <id>``'):format(prefix),
        ('``%ssethealth <id> <value>``'):format(prefix),
        ('``%sarmour <id>``'):format(prefix),
        ('``%ssetarmour <id> <value>``'):format(prefix),
        ('``%srevive <id>``'):format(prefix),
        ('``%skill <id>``'):format(prefix),
        ('``%ssetcoords <id> <x> <y> <z>``'):format(prefix),
        ('``%sfreeze <id> | %sunfreeze <id>``'):format(prefix, prefix),
        ('``%stpway <id>``'):format(prefix),
        ('``%svisible <id> | %sinvisible <id>``'):format(prefix, prefix),
        ('``%sspawnveh <id> [model]`` ``%sfixveh <id>`` ``%sdelveh <id>``'):format(prefix, prefix, prefix),
        ('``%ssetjob <id> <job> <grade>``'):format(prefix),
        ('``%saddmoney <id> <amount>`` ``%saddbank <id> <amount>``'):format(prefix, prefix),
        ('``%sgiveitem <id> <item> <count>``'):format(prefix),
        ('``%sopenskin <id>``'):format(prefix),
        ('``%sgiveweapon <id> <weapon> <ammo>``'):format(prefix),
        ('``%sgetcoords <id>`` ``%sgetgroup <id>`` ``%sgetname <id>`` ``%sgetjob <id>``'):format(prefix, prefix, prefix, prefix),
        ('``%sgetinventory <id>`` ``%suser <id>``'):format(prefix, prefix),
        ('``%skick <id> <reason>``'):format(prefix),
        ('``%snotify <id> <msg>``'):format(prefix),
        ('``%sannounce <msg>``'):format(prefix),
        ('``%sscreenshot <id>``'):format(prefix),
        ('``%splist``'):format(prefix),
    }
    replyEmbed(ctx, {
        color       = Config.embedColors.info,
        title       = 'Commands',
        description = table.concat(rows, '\n'),
    })
end)

function Commands.handlerFor(name)
    return handlers[name]
end

function Commands.exists(name)
    return handlers[name] ~= nil
end
