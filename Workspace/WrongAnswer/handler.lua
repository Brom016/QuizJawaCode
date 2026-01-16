local Players = game:GetService("Players")

script.Parent.Main.Touched:Connect(function(hit)
	local char = hit.Parent
	local player = Players:GetPlayerFromCharacter(char)
	if not player then return end

	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.Health = 0
	end
end)
