-- ServerScriptService > LeaderboardManager
local Players = game:GetService("Players")

Players.PlayerAdded:Connect(function(player)
    local leaderstats = Instance.new("Folder")
    leaderstats.Name = "leaderstats"
    leaderstats.Parent = player

    local difficulty = Instance.new("StringValue")
    difficulty.Name = "Difficulty"
    difficulty.Value = "Lobby"
    difficulty.Parent = leaderstats

    local points = Instance.new("IntValue")
    points.Name = "Points"
    points.Value = 0
    points.Parent = leaderstats

    -- Folder Tracker untuk mencegah double points
    local tracker = Instance.new("Folder")
    tracker.Name = "StageTracker"
    tracker.Parent = player
    
    for _, diff in pairs({"Easy", "Normal", "Hard"}) do
        local val = Instance.new("IntValue")
        val.Name = diff
        val.Value = 0
        val.Parent = tracker
    end
end)