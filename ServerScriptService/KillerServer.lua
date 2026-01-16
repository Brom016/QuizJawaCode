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
	if activeKillers[player] then
		activeKillers[player]:Destroy()
		activeKillers[player] = nil
	end


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