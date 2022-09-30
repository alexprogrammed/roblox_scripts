getgenv().config = {
  keybinds = {
    set = Enum.KeyCode.E,
    teleport = Enum.KeyCode.R,
    unset = Enum.KeyCode.Q
  },
  saveCameraAngle = true
}

loadstring(game:HttpGet("https://raw.githubusercontent.com/nilkibite/roblox_scripts/main/source/checkpoints.lua"))()
