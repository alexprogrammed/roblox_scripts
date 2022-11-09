getgenv().config = {
  keybinds = {
    set = Enum.KeyCode.E,
    teleport = Enum.KeyCode.R,
    unset = Enum.KeyCode.Q
  },
  saveCameraAngle = true,
  saveMousePosition = true,
  checkpoint = {
    color = Color3.fromRGB(255, 255, 255),
    transparency = 0.5
  }
}

loadstring(game:HttpGet("https://raw.githubusercontent.com/alexprogrammed/roblox_scripts/dev/source/checkpoints.lua"))()
