local Players = game:GetService("Players")

local prompt = script.Parent:WaitForChild("ProximityPrompt")
local spawnLocation = workspace:WaitForChild("SpawnLocation")

local function destroyKiller(player)
	for _, obj in ipairs(workspace:GetChildren()) do
		if obj:IsA("Part") and obj:GetAttribute("Owner") == player.UserId then
			obj:Destroy()
		end
	end
	player:SetAttribute("KillerPos", nil)
end

prompt.Triggered:Connect(function(player)
	local character = player.Character
	if not character then return end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	destroyKiller(player)

	-- reset total
	player:SetAttribute("ActiveLevel", nil)
	player:SetAttribute("HasCheckpoint", false)
	player:SetAttribute("CheckpointPos", nil)

	hrp.CFrame = spawnLocation.CFrame + Vector3.new(0, 3, 0)
end)
