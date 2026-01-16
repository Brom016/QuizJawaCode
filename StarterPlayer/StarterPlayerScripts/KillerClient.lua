local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local remote = ReplicatedStorage:WaitForChild("KillerVisibility")

remote.OnClientEvent:Connect(function(part, ownerId)
	if ownerId ~= player.UserId then
		part.LocalTransparencyModifier = 1
		part.CanCollide = false
	end
end)
