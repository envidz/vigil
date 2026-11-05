# Vigil

Script menu with ESP, aimbot, silent aim, visuals and movement.

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/envidz/vigil/main/vigil.lua"))()
```

If nothing happens, use this version instead. It prints the real reason in the console (F9):

```lua
local ok, src = pcall(game.HttpGet, game, "https://raw.githubusercontent.com/envidz/vigil/main/vigil.lua")
if not ok then return warn("Vigil: download failed: " .. tostring(src)) end
local fn, err = loadstring(src)
if not fn then return warn("Vigil: executor could not compile it (re-attach the executor): " .. tostring(err)) end
fn()
```

An error like `CoreGui.12345.67890:1: attempt to call a nil value` means the executor's `loadstring` returned nothing, which on Xeno happens when it has lost its attach to Roblox (its log shows `Client not found`). Rejoin the game, wait until Xeno says it is attached, then execute again.

Right Shift shows or hides the menu (rebindable in Settings). Running it again replaces the running copy.

Edit `src/vigil.lua`, then run `node build.mjs` to regenerate `vigil.lua`. The published copy has comments and indentation stripped. Keep the main chunk under 200 top-level locals (wrap sections in `do ... end`): Xeno compiles without optimisation and refuses anything over that limit. Check with `luau-compile --binary -O0 vigil.lua`.
