local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local visuals = {}


local function updateLeaderstats()
	for character, data in pairs(visuals) do
		if data.isDummy then continue end

		local leaderstats = data.player:FindFirstChild("leaderstats")
		if not leaderstats then continue end

		local killsStat = leaderstats:FindFirstChild("Kills")
		if not killsStat then continue end

		local kills = killsStat.Value
		local color

		if kills <= 7500 then
			local ratio = math.clamp(kills / 7500,0,1)
			local hue = 0.33 * (1 - ratio)
			color = Color3.fromHSV(hue,1,1)
		else
			local extra = kills - 7500
			local darkness = math.clamp(extra / 7500,0,1)
			local brightness = 1 - (darkness * 0.7)
			color = Color3.fromHSV(0,1,brightness)
		end

		data.stats.Text = "Kills: "..kills
		data.stats.TextColor3 = color
	end
end

local function cleanupModel(model)
	local data = visuals[model]
	if not data then return end

	if data.gui then data.gui:Destroy() end
	if data.highlight then data.highlight:Destroy() end

	visuals[model] = nil
end

local function createVisual(player, character, humanoid)
	if visuals[character] then return end

	local head = character:WaitForChild("Head", 5)
	if not head then return end

	local gui = Instance.new("BillboardGui")
	gui.Name = "re"
	gui.Adornee = head
	gui.Size = UDim2.fromScale(4, 2.4)
	gui.StudsOffset = Vector3.new(0, 3, 0)
	gui.AlwaysOnTop = true
	gui.Parent = character

	local container = Instance.new("Frame")
	container.Size = UDim2.fromScale(1, 1)
	container.BackgroundTransparency = 1
	container.Parent = gui

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.fromScale(1, 0.3)
	nameLabel.BackgroundTransparency = 1
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.SourceSansBold
	nameLabel.TextStrokeTransparency = 0
	nameLabel.Text = player.Name
	nameLabel.TextColor3 = Color3.new(1,1,1)
	nameLabel.Parent = container

	local statsLabel = Instance.new("TextLabel")
	statsLabel.Size = UDim2.fromScale(1, 0.3)
	statsLabel.Position = UDim2.fromScale(0, 0.3)
	statsLabel.BackgroundTransparency = 1
	statsLabel.TextScaled = true
	statsLabel.Font = Enum.Font.SourceSansBold
	statsLabel.TextStrokeTransparency = 0
	statsLabel.Parent = container

	local hpLabel = Instance.new("TextLabel")
	hpLabel.Size = UDim2.fromScale(1, 0.4)
	hpLabel.Position = UDim2.fromScale(0, 0.6)
	hpLabel.BackgroundTransparency = 1
	hpLabel.TextScaled = true
	hpLabel.Font = Enum.Font.SourceSansBold
	hpLabel.TextStrokeTransparency = 0
	hpLabel.Parent = container

	local highlight = Instance.new("Highlight")
	highlight.Adornee = character
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.FillTransparency = 0.85
	highlight.OutlineTransparency = 0.7
	highlight.Parent = character

	visuals[character] = {
		gui = gui,
		hp = hpLabel,
		stats = statsLabel,
		humanoid = humanoid,
		player = player,
		highlight = highlight,
		isDummy = false,

		lastHp = humanoid.Health,
		damageLabel = nil
	}
end

local function trackPlayer(player)
	local function onCharacter(character)
		local humanoid = character:WaitForChild("Humanoid", 5)
		if humanoid then
			createVisual(player, character, humanoid)
			updateLeaderstats()
		end
	end

	if player.Character then
		onCharacter(player.Character)
	end

	player.CharacterAdded:Connect(onCharacter)
end

for _, player in ipairs(Players:GetPlayers()) do
	trackPlayer(player)
end

Players.PlayerAdded:Connect(trackPlayer)

Players.PlayerRemoving:Connect(function(player)
	for character, data in pairs(visuals) do
		if data.player == player then
			cleanupModel(character)
		end
	end
end)

RunService.RenderStepped:Connect(function()
	for character, data in pairs(visuals) do

		if not data.humanoid or not data.humanoid.Parent then
			cleanupModel(character)
			continue
		end

		local hp = math.floor(data.humanoid.Health)
		local maxHp = math.floor(data.humanoid.MaxHealth)

		data.hp.Text = hp.." / "..maxHp.." HP"

		local ratio = hp / math.max(maxHp,1)
		data.hp.TextColor3 = Color3.fromRGB(
			255 * (1-ratio),
			255 * ratio,
			0
		)

--huyna peredelivaem
		local lastHp = data.lastHp or hp

		if hp < lastHp then
			local damage = math.floor(lastHp - hp)

			if data.damageLabel then
				data.damageLabel:Destroy()
			end

			local dmg = Instance.new("TextLabel")
			dmg.Size = UDim2.new(1,0,0.3,0)
			dmg.Position = UDim2.new(0,0,-0.3,0)
			dmg.BackgroundTransparency = 1
			dmg.TextScaled = true
			dmg.Font = Enum.Font.SourceSansBold
			dmg.TextStrokeTransparency = 0
			dmg.TextColor3 = Color3.fromRGB(255,50,50)
			dmg.Text = "-"..damage
			dmg.Parent = data.gui

			data.damageLabel = dmg

			task.spawn(function()
				for i = 1,20 do
					if not dmg then return end
					dmg.TextTransparency = i/20
					dmg.TextStrokeTransparency = i/20
					dmg.Position = dmg.Position - UDim2.new(0,0,0.01,0)
					task.wait(0.03)
				end
				if dmg then dmg:Destroy() end
			end)
		end

		data.lastHp = hp

		local teamColor = data.player.TeamColor
		if teamColor then
			data.highlight.FillColor = teamColor.Color
			data.highlight.OutlineColor = teamColor.Color
		end
	end
end)

task.spawn(function()
	while true do
		task.wait(10)
		updateLeaderstats()
	end
end)