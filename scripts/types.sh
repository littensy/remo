# Download the roblox.d.lua file from the luau-lsp repository
curl -o scripts/roblox.d.lua https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/main/scripts/globalTypes.d.lua  

# Combine the testez.d.lua and roblox.d.lua files into one file
cat scripts/testez.d.lua scripts/roblox.d.lua > scripts/types.d.lua
