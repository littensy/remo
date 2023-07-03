--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local include = script:FindFirstAncestor("rbxts_include")
	or ReplicatedStorage:FindFirstChild("rbxts_include")
	or script.Parent.Parent

if include and include:FindFirstChild("Promise") then
	return require(include.Promise)
else
	error(`Could not find Promise from {script:GetFullName()}`)
end
