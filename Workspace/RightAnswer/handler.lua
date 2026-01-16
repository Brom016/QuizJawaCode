local Players = game:GetService("Players")

-- Referensi Objek
local handlerScript = script
local answerModel = handlerScript.Parent
local questionModel = answerModel.Parent -- Mewakili angka stage (e.g., "1", "2")
local difficultyFolder = questionModel.Parent -- Mewakili kategori (e.g., "Easy", "Hard")
local mainPart = answerModel:WaitForChild("Main")

-- Konfigurasi Sistem
local SPAWN_OFFSET = Vector3.new(0, 0, -20)
local POINT_INCREMENT = 1 -- Poin yang diberikan per stage baru

-- Ekstraksi dan Validasi ID Stage
local stageID = tonumber(questionModel.Name)
if not stageID then
	warn(string.format("[Error] Nama model '%s' bukan angka valid. Pastikan penamaan sesuai urutan stage.", questionModel.Name))
end

-- Listener Event Sentuhan (Touched)
mainPart.Touched:Connect(function(hit)
	local character = hit.Parent
	local player = Players:GetPlayerFromCharacter(character)

	-- Validasi entitas pemain dan status kesehatan
	if not player then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local rootPart = character:FindFirstChild("HumanoidRootPart")

	if not humanoid or not rootPart or humanoid.Health <= 0 then 
		return 
	end

	-- 1. Pembaruan Data Checkpoint
	-- Menyimpan koordinat spawn baru menggunakan Attributes
	player:SetAttribute("CheckpointPos", mainPart.Position + SPAWN_OFFSET)
	player:SetAttribute("HasCheckpoint", true)

	-- 2. Pembaruan Progres Leaderboard
	local leaderstats = player:FindFirstChild("leaderstats")
	local stageTracker = player:FindFirstChild("StageTracker")

	if leaderstats and stageTracker and stageID then
		-- Normalisasi nama kategori kesulitan (Case-Sensitive Handling)
		local difficultyName = difficultyFolder.Name
		if difficultyName:lower() == "easy" then difficultyName = "Easy" end

		local currentDifficultyRecord = stageTracker:FindFirstChild(difficultyName)
		local totalPoints = leaderstats:FindFirstChild("Points")
		local difficultyDisplay = leaderstats:FindFirstChild("Difficulty")

		-- Validasi Progres: Hanya memberikan poin jika pemain mencapai stage baru
		if currentDifficultyRecord and totalPoints then
			if stageID > currentDifficultyRecord.Value then
				-- Update record stage tertinggi di kategori terkait
				currentDifficultyRecord.Value = stageID

				-- Penambahan poin kumulatif
				totalPoints.Value += POINT_INCREMENT

				-- Update tampilan status kesulitan pada leaderboard
				if difficultyDisplay then
					difficultyDisplay.Value = difficultyName
				end
			end
		end
	end
end)