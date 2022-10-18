# roblox_scripts
This is where I post Roblox scripts that I've made.<br>
# about
I made this so I could use scripts without having to put the source code inside the executor. These scripts should work with SynapseX and maybe Script-Ware. **Due to many exploits becoming a subscription service and Roblox obtaining Byfron, updates here will be rare.**
# script
Inside this folder is the loadstring and config for scripts. These use `loadstring` with `game:HttpGet` along with a customizable config. These will auto-update, look in the source folder for the source code.
```lua
-- Config Example
getgenv().config = {
  A = true,
  B = false,
  C = 1
}

-- Loadstring Example
loadstring(game:HttpGet("https://raw.githubusercontent.com/alexprogrammed/roblox_scripts/main/source/example.lua"))()
```
# source
Inside this folder is the source code of scripts, recommended to use the scripts from the script folder. These will not auto-update.
