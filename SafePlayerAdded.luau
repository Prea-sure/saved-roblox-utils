local Players = game:GetService("Players")


local function SafePlayerAdded(playerAddedCallback: (Player) -> nil)
	for _, player in pairs(Players:GetPlayers()) do
		task.spawn(playerAddedCallback, player)
	end
	return Players.PlayerAdded:Connect(playerAddedCallback)
end
return SafePlayerAdded

