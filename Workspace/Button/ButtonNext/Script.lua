local Players = game:GetService("Players")

local prompt = script.Parent:WaitForChild("ProximityPrompt")
local spawnLocation = workspace:WaitForChild("SpawnLocation")

local difficulty = "Normal" -- GANTI sesuai folder

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

	local levelFolder = workspace:FindFirstChild(difficulty)
	if not levelFolder then return end

	local startLevel = levelFolder:FindFirstChild("StartLevel"..difficulty)
	if not startLevel then return end

	-- teleport ke startlevel + Z 10
	hrp.CFrame = CFrame.new(startLevel.Position + Vector3.new(0, 0, 10))

	-- reset agar killer spawn ulang pas diinjak
	player:SetAttribute("ActiveLevel", difficulty)
	player:SetAttribute("HasCheckpoint", false)
	player:SetAttribute("CheckpointPos", nil)
end)
