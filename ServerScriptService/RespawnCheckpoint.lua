local Players = game:GetService("Players")

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(char)
		local hrp = char:WaitForChild("HumanoidRootPart")
		task.wait(0.1) -- Jeda biar teleport engine selesai

		local hasCheckpoint = player:GetAttribute("HasCheckpoint")
		local pos = player:GetAttribute("CheckpointPos")

		-- HANYA TELEPORT JIKA PUNYA CHECKPOINT AKTIF
		if hasCheckpoint and pos then
			hrp.CFrame = CFrame.new(pos)
		end
	end)
end)