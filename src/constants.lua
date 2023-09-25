local RunService = game:GetService("RunService")

return {
	IS_EDIT = RunService:IsStudio() and not RunService:IsRunning(),
	IS_STUDIO = RunService:IsStudio(),
	IS_CLIENT = RunService:IsClient(),
	IS_SERVER = RunService:IsServer(),
	IS_TEST = false,
}
