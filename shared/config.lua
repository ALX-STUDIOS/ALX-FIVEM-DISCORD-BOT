Config = {}

Config.debug = true

Config.discord = {
    token         = 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX',
    guildId       = 'XXXXXXXXXXXXXXXXXXXX',
    channelId     = 'XXXXXXXXXXXXXXXXXXXX',
    webhookUrl    = 'https://discord.com/api/webhooks/150950XXXXXXXXXb18B2g-XXXXXXXXXXXXXXrp22Q',
    screenshotUrl = 'https://discord.com/api/webhooks/150XXXXXXXXXXXXX18B2g-IPXXXXXXXXrp22Q',
    prefix        = '!',
    pollInterval  = 5000,
    apiVersion    = 'v10',
    httpTimeout   = 10000,
}

-- Discord role IDs allowed to execute commands by default.
-- Leave empty to allow any non-bot user in the channel (NOT recommended).
Config.allowedRoles = {
    'XXXXXXXX',
}

-- Per-command role overrides. Falls back to Config.allowedRoles when absent.
Config.commandRoles = {
    -- kick = { '000000000000000000' },
    -- setjob = { '000000000000000000' },
}

Config.triggers = {
    revive = 'esx_ambulancejob:revive',
    notify = 'esx:showNotification',
    announce = {
        useChat         = true,
        chatTrigger     = 'chat:addMessage',
        chatColor       = { 0, 150, 20 },
        chatMultiline   = true,
        fallbackTrigger = 'esx:showNotification',
    },
}


Config.framework = {
    -- 'auto' | 'esx' | 'ox_inventory'
    inventory = 'auto',

    -- 'auto' | 'esx_skin' | 'illenium' | 'custom'
    skin = 'auto',

    -- Only used when skin = 'custom'. Triggered client-side with no args.
    customSkinTrigger = nil,

    -- DB columns read by the `getinventory` command when using legacy ESX
    -- inventory. Ignored when ox_inventory is active.
    esxInventoryColumn = 'inventory',
    esxLoadoutColumn   = 'loadout',

    -- How long to wait for ESX before giving up at startup (ms).
    esxLoadTimeout = 30000,

    -- Player method name overrides for exotic ESX forks. Leave commented to
    -- use the auto-detected defaults. Each value can be a string or a list of
    -- candidate names (first callable one wins).
    methods = {
        -- identifier = 'getIdentifier',
        -- name       = 'getName',
        -- group      = 'getGroup',
        -- job        = 'getJob',
        -- coords     = 'getCoords',
        -- account    = 'getAccount',
        -- money      = 'getMoney',
        -- setJob     = 'setJob',
        -- addMoney   = 'addMoney',
        -- addAccount = { 'addAccountMoney', 'addAccount' },
        -- kick       = { 'kick', 'drop' },
    },
}

Config.commands = {
    heal         = true,
    sethealth    = true,
    armour       = true,
    setarmour    = true,
    revive       = true,
    kill         = true,
    setcoords    = true,
    freeze       = true,
    unfreeze     = true,
    tpway        = true,
    visible      = true,
    invisible    = true,
    spawnveh     = true,
    fixveh       = true,
    delveh       = true,
    setjob       = true,
    addmoney     = true,
    addbank      = true,
    giveitem     = true,
    openskin     = true,
    giveweapon   = true,
    getcoords    = true,
    getgroup     = true,
    getname      = true,
    getjob       = true,
    getinventory = true,
    user         = true,
    kick         = true,
    notify       = true,
    announce     = true,
    screenshot   = true,
    plist        = true,
    help         = true,
}

Config.embedColors = {
    success = 4437377,
    info    = 3447003,
    error   = 15158332,
}
