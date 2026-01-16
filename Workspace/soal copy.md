ini susunan folder dan script dari project saya roblox studio

buatkan agar button dan proximity prompt ini berfungsi dengan syarat

player jika menekan BUtton next, player akan teleport ke StartLevel dan posisi z akan +10
lalu jika player menekan button exit maka player akan teleport ke spawnlocation
dan killer akan destroy atau stop ketika player klik exit
dan juga next lalu muncul baru lagi ketika player menginjak atau terkena StartLevel

buatkan step by step dan pastikkan full code

Workspace
    - easy (folder)
        - 1 (model)
            - RightAnswer (model)
                - Handler (script)
                - Main
            - WrongAnswer (model)
                - Handler (script)
                - Main
            - WrongAnswer (model)
                - Handler (script)
                - Main
            - wall (union)
  
        - 2 (model)
        - 3 (model)
        - 4 (model)
        - StartLevelEasy (part)
    - Normal (folder)
        - sama seperti easy
        - StartLevelNormal (Part)
    - Hard (Folder)
        - sama seperti easy
        - StartLevelNormal (part)
    - SpawnLocation
    - ButtonEasy
        - ButtonExit
            - Button
                - ProximityPrompt
        - ButtonNext
            - Button
                - ProximityPrompt
    - ButtonNormal
        - Sama seperti Easy
    - ButtonHard
        - Sama Seperti easy

ReplicatedStorage
    - KillerVisibility (remoteevent)

ServerScriptService
    - KillerServer (script)
    - RespawnCheckpoint (script)
  
ServerStorage
    - KillerPart (part)
  
StarterPlayer
    - StarterPlayerScripts
        - KillerClient (localscript)
  
Scriptnya:

RightAnswer (handler): 
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

ServerScriptService
KillerServer:
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Referensi objek dasar dan jalur komunikasi client-server
local killerTemplate = ServerStorage:WaitForChild("KillerPart")
local visibilityRemote = ReplicatedStorage:WaitForChild("KillerVisibility")

-- Parameter sistem: Jarak mundur KillerPart saat pemain respawn agar memberikan ruang gerak
local BACK_OFFSET_DISTANCE = 30 

-- Definisi parameter setiap tingkat kesulitan
local LEVEL_CONFIG = {
	Easy = {
		partName = "StartLevelEasy",
		startPos = Vector3.new(-100.002, 17.788, 2318.568),
		endPos   = Vector3.new(-100.004, 14.046, -362.679),
		speed = 8
	},
	Normal = {
		partName = "StartLevelNormal",
		startPos = Vector3.new(-0.002, 17.788, 2318.568),
		endPos   = Vector3.new(-0.002, 14.848, 715.392),
		speed = 8
	},
	Hard = {
		partName = "StartLevelHard",
		startPos = Vector3.new(99.998, 17.788, 2318.568),
		endPos   = Vector3.new(99.998, 14.848, 1246.577),
		speed = 10
	}
}

-- Cache untuk melacak instance killer yang aktif per pemain
local activeKillers = {}

-- Fungsi utama untuk membuat dan menggerakkan instance KillerPart
local function spawnKiller(player, config)
	if activeKillers[player] then return end

	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return end

	-- Inisialisasi properti fisik objek pengejar
	local killerPart = killerTemplate:Clone()
	killerPart.Anchored = true
	killerPart.CanCollide = true
	killerPart.Parent = workspace
	killerPart:SetAttribute("Owner", player.UserId)

	-- Menentukan vektor arah pergerakan berdasarkan posisi start dan end
	local direction = (config.endPos - config.startPos).Unit

	-- Logika posisi spawn: Menggunakan koordinat terakhir jika pemain memiliki checkpoint
	if player:GetAttribute("HasCheckpoint") and player:GetAttribute("KillerPos") then
		killerPart.Position = player:GetAttribute("KillerPos")
	else
		killerPart.Position = config.startPos
	end

	activeKillers[player] = killerPart
	visibilityRemote:FireAllClients(killerPart, player.UserId)

	local isAlive = true

	-- Sinkronisasi pergerakan menggunakan Heartbeat agar tetap konsisten terhadap delta time
	local moveConnection
	moveConnection = RunService.Heartbeat:Connect(function(deltaTime)
		if isAlive then
			killerPart.Position += direction * config.speed * deltaTime
		end
	end)

	-- Prosedur pembersihan saat pemain tereliminasi
	humanoid.Died:Connect(function()
		if not isAlive then return end
		isAlive = false

		-- Menyimpan referensi posisi untuk mekanisme 'Resume' setelah respawn
		if player:GetAttribute("HasCheckpoint") then
			player:SetAttribute(
				"KillerPos",
				killerPart.Position - (direction * BACK_OFFSET_DISTANCE)
			)
		end

		killerPart:Destroy()
		activeKillers[player] = nil
		moveConnection:Disconnect()
	end)

	-- Validasi kontak fisik antara KillerPart dan karakter pemain
	killerPart.Touched:Connect(function(hit)
		if hit:IsDescendantOf(character) then
			humanoid.Health = 0
		end
	end)
end

-- Mekanisme otomatisasi untuk memunculkan kembali killer setelah pemain respawn
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		task.wait(0.2) 

		-- Validasi progres: Hanya memproses pemain yang sudah memasuki area permainan
		if not player:GetAttribute("HasCheckpoint") then return end

		local activeLevel = player:GetAttribute("ActiveLevel")
		local config = LEVEL_CONFIG[activeLevel]

		if config then
			spawnKiller(player, config)
		end
	end)
end)

-- Inisialisasi deteksi pada pad awal untuk setiap tingkat kesulitan
for levelName, config in pairs(LEVEL_CONFIG) do
	local levelFolder = workspace:WaitForChild(levelName)
	local startPad = levelFolder:WaitForChild(config.partName)

	startPad.Touched:Connect(function(hit)
		local character = hit.Parent
		local player = Players:GetPlayerFromCharacter(character)
		if not player then return end

		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if not humanoid or humanoid.Health <= 0 then return end

		-- Registrasi level aktif dan inisialisasi pengejaran pertama kali
		player:SetAttribute("ActiveLevel", levelName)
		spawnKiller(player, config)

		-- Pembaruan informasi visual pada leaderboard pemain
		local leaderstats = player:FindFirstChild("leaderstats")
		if leaderstats then
			local difficultyStat = leaderstats:FindFirstChild("Difficulty")
			if difficultyStat then
				-- Formatting penamaan tingkat kesulitan menjadi format TitleCase
				local formattedName = levelName:sub(1,1):upper() .. levelName:sub(2)
				difficultyStat.Value = formattedName
			end
		end
	end)
end

RespawnCheckpoint
local Players = game:GetService("Players")

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(char)
		local hrp = char:WaitForChild("HumanoidRootPart")
		local checkpoint = player:GetAttribute("CheckpointPos")

		if checkpoint then
			task.wait()
			hrp.CFrame = CFrame.new(checkpoint)
		end
	end)
end)

LeaderboardManager
local Players = game:GetService("Players")

-- Daftar kategori kesulitan yang tersedia dalam game
local DIFFICULTY_CATEGORIES = {"Easy", "Normal", "Hard"}

Players.PlayerAdded:Connect(function(player)

	-- 1. Inisialisasi Leaderstats (Ditampilkan pada Menu Tab/Player List)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	-- Kolom Status Kesulitan: Menampilkan tingkat kesulitan yang sedang dikerjakan
	local difficulty = Instance.new("StringValue")
	difficulty.Name = "Difficulty"
	difficulty.Value = "Lobby"
	difficulty.Parent = leaderstats

	-- Kolom Poin: Menampilkan total skor kumulatif pemain
	local points = Instance.new("IntValue")
	points.Name = "Points"
	points.Value = 0
	points.Parent = leaderstats

	-- 2. Inisialisasi StageTracker (Data Internal/Hidden)
	-- Digunakan untuk validasi progres agar pemain tidak mendapatkan poin berulang dari stage yang sama
	local stageTracker = Instance.new("Folder")
	stageTracker.Name = "StageTracker"
	stageTracker.Parent = player

	-- Membuat tracker nilai untuk setiap kategori kesulitan
	for _, categoryName in ipairs(DIFFICULTY_CATEGORIES) do
		local tracker = Instance.new("IntValue")
		tracker.Name = categoryName
		tracker.Value = 0 -- Default progres dimulai dari nol
		tracker.Parent = stageTracker
	end
end)

StarterPlayer/StarterPlayerScript
KillerClient:
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