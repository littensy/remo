local RunService = game:GetService("RunService")

local IS_TEST = false
local IS_EDIT = RunService:IsStudio() and not RunService:IsRunning()
local IS_CLIENT = RunService:IsClient()
local IS_SERVER = RunService:IsServer()

return {
	IS_TEST = IS_TEST,
	IS_EDIT = IS_EDIT,
	IS_CLIENT = IS_CLIENT,
	IS_SERVER = IS_SERVER,
}
