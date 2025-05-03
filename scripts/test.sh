rojo build test.project.json -o test.rbxl

run-in-roblox --place test.rbxl --script scripts/spec.server.luau

rm test.rbxl
