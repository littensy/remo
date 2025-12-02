curl -o scripts/roblox.d.luau https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/main/scripts/globalTypes.d.luau

rojo sourcemap test.project.json -o sourcemap.json

luau-lsp analyze --defs=scripts/testez.d.luau --defs=scripts/roblox.d.luau --sourcemap=sourcemap.json --base-luaurc=.luaurc --ignore="**/_Index/**" src

selene src

stylua --check src

rm scripts/roblox.d.luau
