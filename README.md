# alx-discbot

> **Discord admin bot for FiveM (ESX)** — run server admin commands straight from a Discord channel.

`alx-discbot` watches a Discord channel and turns prefixed messages (`!heal 1`, `!revive 2`, `!announce ...`) into in-game admin actions. Results are posted back to Discord through webhooks, with per-user avatars and clean embeds. It targets the **ESX** framework and adapts automatically to common forks and add-ons (`ox_inventory`, `illenium-appearance`, `esx_skin`).



## Features

- **30+ admin commands** covering player state, vehicles, economy, jobs, inventory, and moderation.
- **Role-based access control** — restrict commands to specific Discord role IDs, globally or per command.
- **Framework adapters** — auto-detects `ox_inventory` vs legacy ESX inventory, and `illenium-appearance` vs `esx_skin`. Works with both modern (export) and legacy (event) ESX.
- **Resilient Discord layer** — webhook queue with automatic retry, rate-limit (HTTP 429) back-off, and member caching.
- **Helpful diagnostics** — clear console hints when the token, channel, intents, or permissions are misconfigured.
- **Optional screenshots** — capture a player's screen via [`screenshot-basic`](https://github.com/citizenfx/screenshot-basic).

---

## Requirements

| Dependency | Required | Notes |
|---|---|---|
| [`es_extended`](https://github.com/esx-framework/esx_core) | ✅ | ESX framework (modern or legacy). |
| [`oxmysql`](https://github.com/overextended/oxmysql) | ✅ | Used by the `user` and `getinventory` commands. |
| [`ox_inventory`](https://github.com/overextended/ox_inventory) | optional | Auto-detected; otherwise legacy ESX inventory is used. |
| [`illenium-appearance`](https://github.com/iLLeniumStudios/illenium-appearance) / `esx_skin` | optional | For the `openskin` command. |
| [`screenshot-basic`](https://github.com/citizenfx/screenshot-basic) | optional | For the `screenshot` command. |

You also need a **Discord application/bot** and a channel the bot can read.

---

## Installation

1. Download or clone this repository into your server's `resources` folder:
   ```bash
   cd resources
   git clone https://github.com/<your-username>/alx-discbot.git
   ```
2. Make sure dependencies start **before** this resource. In `server.cfg`:
   ```cfg
   ensure es_extended
   ensure oxmysql
   ensure alx-discbot
   ```
3. Configure `shared/config.lua` (see [Configuration](#configuration)).
4. Restart the server, or run `ensure alx-discbot` from the console.

---

## Discord setup

1. Go to the [Discord Developer Portal](https://discord.com/developers/applications) → **New Application**.
2. Open **Bot** → **Reset Token** and copy the **bot token** (this is the value for `Config.discord.token`, *not* the client/application secret).
3. Under **Privileged Gateway Intents**, enable:
   - **MESSAGE CONTENT INTENT** — required so the bot can read command text.
   - **SERVER MEMBERS INTENT** — required for role-based permission checks.
4. Invite the bot to your guild with at least these permissions: **View Channel**, **Read Message History**.
5. Enable **Developer Mode** in Discord (User Settings → Advanced), then right-click to **Copy ID** for your guild, the command channel, etc.
6. Create **two webhooks** (Channel → Edit → Integrations → Webhooks):
   - one for command responses → `Config.discord.webhookUrl`
   - one for screenshots → `Config.discord.screenshotUrl`

---

## Commands

Default prefix is `!`. `<id>` is the in-game **server ID** of the target player.

### Player state
| Command | Description |
|---|---|
| `!heal <id>` | Restore the player to full health. |
| `!sethealth <id> <value>` | Set the player's health. |
| `!armour <id>` | Give full armour. |
| `!setarmour <id> <value>` | Set the player's armour. |
| `!revive <id>` | Revive the player. |
| `!kill <id>` | Kill the player. |
| `!setcoords <id> <x> <y> <z>` | Teleport to coordinates. |
| `!freeze <id>` / `!unfreeze <id>` | Freeze / unfreeze the player. |
| `!tpway <id>` | Teleport the player to their map waypoint. |
| `!visible <id>` / `!invisible <id>` | Toggle the player's visibility. |

### Vehicles
| Command | Description |
|---|---|
| `!spawnveh <id> [model]` | Spawn a vehicle (prompts in-game if no model given). |
| `!fixveh <id>` | Repair the player's current vehicle. |
| `!delveh <id>` | Delete the player's current vehicle. |

### Economy, jobs & inventory
| Command | Description |
|---|---|
| `!setjob <id> <job> <grade>` | Set the player's job and grade. |
| `!addmoney <id> <amount>` | Add cash to the wallet. |
| `!addbank <id> <amount>` | Add money to the bank. |
| `!giveitem <id> <item> <count>` | Give an inventory item. |
| `!giveweapon <id> <weapon> <ammo>` | Give a weapon with ammo. |
| `!openskin <id>` | Open the player's appearance/skin menu. |

### Read-only queries
| Command | Description |
|---|---|
| `!getcoords <id>` | Show the player's coordinates. |
| `!getgroup <id>` | Show the player's permission group. |
| `!getname <id>` | Show the player's character name. |
| `!getjob <id>` | Show the player's job and grade. |
| `!getinventory <id>` | Show the player's inventory. |
| `!user <id>` | Full profile: identifier, name, money/bank/black, group, job, DOB, etc. |

### Moderation & utility
| Command | Description |
|---|---|
| `!kick <id> <reason>` | Kick the player. |
| `!notify <id> <message>` | Send an on-screen notification to a player. |
| `!announce <message>` | Broadcast a message to all players. |
| `!screenshot <id>` | Capture the player's screen (needs `screenshot-basic`). |
| `!plist` | List online players (ID, name, job, ping). |
| `!help` | Show all available commands. |

---

## How it works

The bot uses Discord's **REST API** (not the gateway/websocket). On a fixed interval (`pollInterval`, default 5 s) it fetches new messages in the configured channel, parses any that begin with the prefix, checks the author's roles, and dispatches to the matching command handler. Each handler triggers the appropriate client/server events in-game and posts the result back through the response webhook. The webhook sender is a queue with automatic retry and 429 rate-limit back-off, so bursts of commands won't get dropped.

---

## Permissions & roles

Access is gated by Discord role IDs:

- A command is allowed if the author has **any** role listed in `Config.commandRoles[command]`, or — when that entry is absent — any role in `Config.allowedRoles`.
- If a role list is configured but `Config.discord.guildId` is missing, **everyone is denied** (fail-safe) and a warning is logged.
- Role lookups require the **SERVER MEMBERS INTENT**; without it, members can't be fetched and commands are denied.
- Members are cached for ~60 seconds to reduce API calls.

Leaving `Config.allowedRoles` empty allows any non-bot user posting in the channel — only do this in a tightly locked-down channel.

---

## Troubleshooting

The console prints targeted hints based on the Discord HTTP status:

| Symptom | Likely cause |
|---|---|
| `Unauthorized (401)` | Wrong/malformed token — make sure it's the **Bot** token, not the client secret. |
| `Forbidden (403)` | Bot isn't in the guild, can't see the channel, or lacks **View Channel / Read Message History**. |
| `Not found (404)` | Wrong channel ID, or the bot isn't in that guild. |
| `No HTTP response (0)` | The server has no outbound internet, or Discord is unreachable. |
| `Rate limited (429)` | Too many requests — the bot backs off automatically. |
| `role checks will deny everyone` | `allowedRoles` is set but `guildId` is empty — fill in `Config.discord.guildId`. |
| `ESX never resolved` | `es_extended` isn't started, or isn't listed before this resource in `server.cfg`. |
| Commands ignored entirely | **MESSAGE CONTENT INTENT** is disabled, or the message doesn't start with the prefix. |

Set `Config.debug = true` for verbose logs while diagnosing.

---

## Credits & license

- **Author:** ALX STUDIOS
- **Version:** 2.1.0
- **Framework:** ESX · **Game:** GTA V (FiveM)

> Discord and the Discord logo are trademarks of Discord Inc. This project is an independent integration and is not affiliated with or endorsed by Discord.





















# alx-discbot

> **Bot de administración de Discord para FiveM (ESX)** — ejecuta comandos de administración del servidor directamente desde un canal de Discord.

`alx-discbot` vigila un canal de Discord y convierte los mensajes con prefijo (`!heal 1`, `!revive 2`, `!announce ...`) en acciones de administración dentro del juego. Los resultados se publican de vuelta en Discord mediante webhooks, con avatares por usuario y *embeds* limpios. Está diseñado para el framework **ESX** y se adapta automáticamente a los *forks* y complementos más habituales (`ox_inventory`, `illenium-appearance`, `esx_skin`).


## Características

- **Más de 30 comandos de administración** para estado del jugador, vehículos, economía, trabajos, inventario y moderación.
- **Control de acceso por roles** — restringe los comandos a IDs de roles de Discord concretos, de forma global o por comando.
- **Adaptadores de framework** — detecta automáticamente `ox_inventory` frente al inventario ESX clásico, y `illenium-appearance` frente a `esx_skin`. Funciona con ESX moderno (export) y antiguo (event).
- **Capa de Discord resistente** — cola de webhooks con reintentos automáticos, espera ante límites de tasa (HTTP 429) y caché de miembros.
- **Diagnósticos útiles** — mensajes de consola claros cuando el token, el canal, los *intents* o los permisos están mal configurados.
- **Capturas de pantalla opcionales** — captura la pantalla de un jugador mediante [`screenshot-basic`](https://github.com/citizenfx/screenshot-basic).

---

## Requisitos

| Dependencia | Obligatoria | Notas |
|---|---|---|
| [`es_extended`](https://github.com/esx-framework/esx_core) | ✅ | Framework ESX (moderno o antiguo). |
| [`oxmysql`](https://github.com/overextended/oxmysql) | ✅ | Lo usan los comandos `user` y `getinventory`. |
| [`ox_inventory`](https://github.com/overextended/ox_inventory) | opcional | Se detecta automáticamente; si no, se usa el inventario ESX clásico. |
| [`illenium-appearance`](https://github.com/iLLeniumStudios/illenium-appearance) / `esx_skin` | opcional | Para el comando `openskin`. |
| [`screenshot-basic`](https://github.com/citizenfx/screenshot-basic) | opcional | Para el comando `screenshot`. |

También necesitas una **aplicación/bot de Discord** y un canal que el bot pueda leer.

---

## Instalación

1. Descarga o clona este repositorio en la carpeta `resources` de tu servidor:
   ```bash
   cd resources
   git clone https://github.com/<tu-usuario>/alx-discbot.git
   ```
2. Asegúrate de que las dependencias arranquen **antes** que este recurso. En `server.cfg`:
   ```cfg
   ensure es_extended
   ensure oxmysql
   ensure alx-discbot
   ```
3. Configura `shared/config.lua` (consulta [Configuración](#configuración)).
4. Reinicia el servidor o ejecuta `ensure alx-discbot` desde la consola.

---

## Configuración de Discord

1. Entra en el [Portal de Desarrolladores de Discord](https://discord.com/developers/applications) → **New Application**.
2. Abre **Bot** → **Reset Token** y copia el **token del bot** (este es el valor de `Config.discord.token`, *no* el secreto de cliente/aplicación).
3. En **Privileged Gateway Intents**, activa:
   - **MESSAGE CONTENT INTENT** — necesario para que el bot pueda leer el texto de los comandos.
   - **SERVER MEMBERS INTENT** — necesario para las comprobaciones de permisos por rol.
4. Invita al bot a tu servidor con, al menos, estos permisos: **Ver canal** y **Leer historial de mensajes**.
5. Activa el **Modo desarrollador** en Discord (Ajustes de usuario → Avanzado) y haz clic derecho para **Copiar ID** de tu servidor, del canal de comandos, etc.
6. Crea **dos webhooks** (Canal → Editar → Integraciones → Webhooks):
   - uno para las respuestas de los comandos → `Config.discord.webhookUrl`
   - uno para las capturas de pantalla → `Config.discord.screenshotUrl`

---

## Configuración

Todos los ajustes están en `shared/config.lua`. Campos principales:

```lua
Config.discord = {
    token         = 'TU_TOKEN_DEL_BOT',      -- Token del bot (Bot, no el secreto de cliente)
    guildId       = 'TU_ID_DE_SERVIDOR',     -- Necesario para las comprobaciones de roles
    channelId     = 'TU_ID_DE_CANAL',        -- Canal que el bot escucha
    webhookUrl    = 'https://discord.com/api/webhooks/...',  -- Respuestas de comandos
    screenshotUrl = 'https://discord.com/api/webhooks/...',  -- Capturas de pantalla
    prefix        = '!',                      -- Prefijo de los comandos
    pollInterval  = 5000,                     -- Frecuencia de sondeo a Discord (ms)
}
```

Otras secciones útiles:

- **`Config.allowedRoles`** — IDs de roles de Discord autorizados a usar comandos por defecto. Déjalo vacío para permitir a cualquier usuario (que no sea bot) del canal (**no recomendado**).
- **`Config.commandRoles`** — sobrescrituras de roles por comando (p. ej. limitar `kick` a un rol concreto). Si no está, se usa `allowedRoles`.
- **`Config.commands`** — activa o desactiva comandos de forma individual.
- **`Config.framework`** — fija o detecta automáticamente los sistemas de `inventory` y `skin`; sobrescribe nombres de métodos de ESX para *forks* poco comunes; define columnas de la base de datos para la lectura del inventario clásico.
- **`Config.triggers`** — nombres de eventos para revivir / notificar / anunciar, para que coincidan con los recursos de tu servidor.
- **`Config.embedColors`** — colores de los *embeds* de éxito / información / error.
- **`Config.debug`** — registro detallado en consola (los errores siempre se muestran).

> ⚠️ **Nunca subas tu token real ni tus URLs de webhook.** Los valores que vienen en `config.lua` son marcadores de posición.

---

## Comandos

El prefijo por defecto es `!`. `<id>` es el **ID de servidor** del jugador objetivo dentro del juego.

### Estado del jugador
| Comando | Descripción |
|---|---|
| `!heal <id>` | Restaura la vida del jugador al máximo. |
| `!sethealth <id> <valor>` | Establece la vida del jugador. |
| `!armour <id>` | Da chaleco/armadura al máximo. |
| `!setarmour <id> <valor>` | Establece la armadura del jugador. |
| `!revive <id>` | Revive al jugador. |
| `!kill <id>` | Mata al jugador. |
| `!setcoords <id> <x> <y> <z>` | Teletransporta a unas coordenadas. |
| `!freeze <id>` / `!unfreeze <id>` | Congela / descongela al jugador. |
| `!tpway <id>` | Teletransporta al jugador a su punto de mapa (waypoint). |
| `!visible <id>` / `!invisible <id>` | Alterna la visibilidad del jugador. |

### Vehículos
| Comando | Descripción |
|---|---|
| `!spawnveh <id> [modelo]` | Genera un vehículo (pide el modelo en el juego si no se indica). |
| `!fixveh <id>` | Repara el vehículo actual del jugador. |
| `!delveh <id>` | Elimina el vehículo actual del jugador. |

### Economía, trabajos e inventario
| Comando | Descripción |
|---|---|
| `!setjob <id> <trabajo> <grado>` | Establece el trabajo y el grado del jugador. |
| `!addmoney <id> <cantidad>` | Añade dinero en efectivo a la cartera. |
| `!addbank <id> <cantidad>` | Añade dinero al banco. |
| `!giveitem <id> <objeto> <cantidad>` | Da un objeto del inventario. |
| `!giveweapon <id> <arma> <munición>` | Da un arma con munición. |
| `!openskin <id>` | Abre el menú de apariencia/skin del jugador. |

### Consultas de solo lectura
| Comando | Descripción |
|---|---|
| `!getcoords <id>` | Muestra las coordenadas del jugador. |
| `!getgroup <id>` | Muestra el grupo de permisos del jugador. |
| `!getname <id>` | Muestra el nombre del personaje. |
| `!getjob <id>` | Muestra el trabajo y el grado del jugador. |
| `!getinventory <id>` | Muestra el inventario del jugador. |
| `!user <id>` | Perfil completo: identificador, nombre, dinero/banco/negro, grupo, trabajo, fecha de nacimiento, etc. |

### Moderación y utilidades
| Comando | Descripción |
|---|---|
| `!kick <id> <motivo>` | Expulsa al jugador. |
| `!notify <id> <mensaje>` | Envía una notificación en pantalla a un jugador. |
| `!announce <mensaje>` | Difunde un mensaje a todos los jugadores. |
| `!screenshot <id>` | Captura la pantalla del jugador (requiere `screenshot-basic`). |
| `!plist` | Lista los jugadores conectados (ID, nombre, trabajo, ping). |
| `!help` | Muestra todos los comandos disponibles. |

---

## Cómo funciona

El bot usa la **API REST** de Discord (no la *gateway*/websocket). En un intervalo fijo (`pollInterval`, 5 s por defecto) consulta los mensajes nuevos del canal configurado, analiza los que empiezan por el prefijo, comprueba los roles del autor y los envía al manejador de comando correspondiente. Cada manejador dispara los eventos cliente/servidor adecuados en el juego y publica el resultado a través del webhook de respuestas. El emisor de webhooks es una cola con reintentos automáticos y espera ante el límite de tasa 429, de modo que las ráfagas de comandos no se pierden.

---

## Permisos y roles

El acceso se controla mediante IDs de roles de Discord:

- Un comando se permite si el autor tiene **cualquiera** de los roles indicados en `Config.commandRoles[comando]` o —cuando esa entrada no existe— cualquier rol de `Config.allowedRoles`.
- Si hay una lista de roles configurada pero falta `Config.discord.guildId`, **se deniega a todos** (modo seguro) y se registra una advertencia.
- Las búsquedas de roles requieren el **SERVER MEMBERS INTENT**; sin él, no se pueden obtener los miembros y los comandos se deniegan.
- Los miembros se almacenan en caché durante ~60 segundos para reducir las llamadas a la API.

Dejar `Config.allowedRoles` vacío permite a cualquier usuario (que no sea bot) que escriba en el canal — hazlo solo en un canal totalmente restringido.

---

## Solución de problemas

La consola muestra pistas concretas según el estado HTTP de Discord:

| Síntoma | Causa probable |
|---|---|
| `Unauthorized (401)` | Token incorrecto o mal formado — asegúrate de que es el token del **Bot**, no el secreto de cliente. |
| `Forbidden (403)` | El bot no está en el servidor, no ve el canal o le faltan **Ver canal / Leer historial de mensajes**. |
| `Not found (404)` | ID de canal incorrecto, o el bot no está en ese servidor. |
| `No HTTP response (0)` | El servidor no tiene salida a internet o Discord no es accesible. |
| `Rate limited (429)` | Demasiadas peticiones — el bot espera automáticamente. |
| `role checks will deny everyone` | `allowedRoles` está configurado pero `guildId` está vacío — rellena `Config.discord.guildId`. |
| `ESX never resolved` | `es_extended` no está iniciado, o no aparece antes que este recurso en `server.cfg`. |
| Los comandos se ignoran por completo | El **MESSAGE CONTENT INTENT** está desactivado, o el mensaje no empieza con el prefijo. |

Pon `Config.debug = true` para tener registros detallados mientras diagnosticas.

---

## Créditos y licencia

- **Autor:** ALX STUDIOS
- **Versión:** 2.1.0
- **Framework:** ESX · **Juego:** GTA V (FiveM)
