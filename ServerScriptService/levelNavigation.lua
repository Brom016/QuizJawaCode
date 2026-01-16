local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

-- Ambil Kabel Penghubung
local spawnEvent = ServerStorage:WaitForChild("SpawnKillerEvent")

-- Config Logic Perpindahan
local NavigationConfig = {
    -- [Nama Folder Button] = {Tujuan Level, Nama Part Start}
    ["ButtonEasy"]   = {nextLevel = "Normal", startPartName = "StartLevelNormal"},
    ["ButtonNormal"] = {nextLevel = "Hard",   startPartName = "StartLevelHard"},
    ["ButtonHard"]   = {nextLevel = "Easy",   startPartName = "StartLevelEasy"} -- Loop balik ke Easy
}

-- Fungsi Reset Total (Untuk Button Exit)
local function executeExit(player)
    local ls = player:FindFirstChild("leaderstats")
    local tracker = player:FindFirstChild("StageTracker")

    -- Reset Leaderstats
    if ls then
        ls.Points.Value = 0
        ls.Difficulty.Value = "Lobby"
    end
    -- Reset Tracker Soal
    if tracker then
        for _, v in pairs(tracker:GetChildren()) do v.Value = 0 end
    end
    -- Reset Attributes
    player:SetAttribute("HasCheckpoint", false)
    player:SetAttribute("CheckpointPos", nil)
    player:SetAttribute("KillerPos", nil)
    player:SetAttribute("ActiveLevel", nil)

    -- Matikan Player untuk balik ke Spawn
    if player.Character then
        player.Character:BreakJoints()
    end
end

-- Fungsi Pindah Level (Untuk Button Next)
local function executeNext(player, config)
    local targetLevel = config.nextLevel
    local targetPartName = config.startPartName
    
    -- Cari folder level tujuan
    local targetFolder = workspace:FindFirstChild(targetLevel)
    if not targetFolder then warn("Folder Level tidak ketemu: "..targetLevel) return end
    
    local startPart = targetFolder:FindFirstChild(targetPartName)
    
    if startPart and player.Character then
        -- 1. Reset Checkpoint Lama
        player:SetAttribute("HasCheckpoint", false)
        player:SetAttribute("CheckpointPos", nil)
        player:SetAttribute("KillerPos", nil)
        
        -- 2. Teleportasi
        player.Character:MoveTo(startPart.Position + Vector3.new(0, 5, 0))
        
        -- 3. KIRIM SINYAL KE KILLER SERVER (Solusi Masalah Kamu)
        spawnEvent:Fire(player, targetLevel)
    end
end

-- SETUP OTOMATIS UNTUK SEMUA TOMBOL
-- Kita loop folder ButtonEasy, ButtonNormal, ButtonHard
for folderName, config in pairs(NavigationConfig) do
    local folderGroup = workspace:FindFirstChild(folderName)
    
    if folderGroup then
        -- 1. Setup Button NEXT
        local btnNext = folderGroup:FindFirstChild("ButtonNext")
        if btnNext then
            local prompt = btnNext:FindFirstChild("Button") and btnNext.Button:FindFirstChild("ProximityPrompt")
            if prompt then
                prompt.Triggered:Connect(function(player)
                    executeNext(player, config)
                end)
            end
        end

        -- 2. Setup Button EXIT
        local btnExit = folderGroup:FindFirstChild("ButtonExit")
        if btnExit then
            local prompt = btnExit:FindFirstChild("Button") and btnExit.Button:FindFirstChild("ProximityPrompt")
            if prompt then
                prompt.Triggered:Connect(function(player)
                    executeExit(player)
                end)
            end
        end
    else
        warn("Folder Button tidak ditemukan di Workspace: " .. folderName)
    end
end