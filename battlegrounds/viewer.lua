local TLC = IMP_STATS_VIEWER_TLC
local ImperessiveStatsViewer = {}

function ImperessiveStatsViewer:Init()
	self.teamContainers = {}
	local BODY = TLC:GetNamedChild('Body')

	-- local previousControl = BODY:GetNamedChild('Rounds')
	local previousControl = nil
	for i = BATTLEGROUND_TEAM_ITERATION_BEGIN, BATTLEGROUND_TEAM_ITERATION_END do
		local previousPlayerRow
		local teamContainer = CreateControlFromVirtual('$(parent)Team', BODY, 'IMP_STATS_VIEWER_TeamTemplate', i)

		if previousControl then
			teamContainer:SetAnchor(TOPLEFT, previousControl, BOTTOMLEFT, 0, 16)
		else
			teamContainer:SetAnchor(TOPRIGHT, BODY:GetNamedChild('Headers'), BOTTOMRIGHT)
		end
		previousControl = teamContainer

		self.teamContainers[i] = {
			control = teamContainer,
			players = {},
		}
		for j = 1, 8 do
			local playerRow = CreateControlFromVirtual('$(parent)Player', teamContainer:GetNamedChild('Right'), 'IMP_STATS_VIEWER_PlayerTemplate', j)
			if previousPlayerRow then
				playerRow:SetAnchor(TOPLEFT, previousPlayerRow, BOTTOMLEFT)
			end
			previousPlayerRow = playerRow
			self.teamContainers[i].players[j] = {
				control = playerRow,
			}
		end
	end

	local function SwitchRound(roundControl, button)
		if button ~= MOUSE_BUTTON_INDEX_LEFT then return end
		self:LayoutRound(roundControl.number)
	end

	local ROUNDS = BODY:GetNamedChild('Rounds')
	for r = 1, 3 do
		local roundControl = ROUNDS:GetNamedChild('Round' .. r)
		roundControl.selected = false
		roundControl.number = r
		roundControl:SetHandler("OnMouseDown", SwitchRound)
	end

	IMP_STATS_MATCHES:SetHandler("OnEffectivelyShown", function()
		if self.match then
			TLC:SetHidden(false)
		end
	end)

	IMP_STATS_MATCHES:SetHandler("OnEffectivelyHidden", function()
		TLC:SetHidden(true)
	end)

	return self
end

function ImperessiveStatsViewer:Clear()
	for teamIndex, team in pairs(self.teamContainers) do
		for playerIndex, player in pairs(team.players) do
			player.control:SetHidden(true)
		end
		team.control:SetHidden(true)
	end
	self.match = nil
	self.roundNumber = nil
end

IMP_STATS_VIEWER = ImperessiveStatsViewer:Init()


local function LayoutPlayer(playerRow, playerData)
	local playerClass = playerData.classId
	local classIcon = playerClass and ZO_GetClassIcon(playerClass) or 'EsoUI/Art/Icons/icon_missing.dds'

	playerRow:GetNamedChild('ClassIcon'):SetTexture(classIcon)
	playerRow:GetNamedChild('PlayerName'):SetText(zo_strformat('<<1>> (<<2>>)', playerData.displayName, playerData.characterName))
	playerRow:GetNamedChild('MedalScore'):SetText(playerData.medalScore)
	playerRow:GetNamedChild('Kills'):SetText(playerData.kills)
	playerRow:GetNamedChild('Deaths'):SetText(playerData.deaths)
	playerRow:GetNamedChild('Assists'):SetText(playerData.assists)
	playerRow:GetNamedChild('DamageDone'):SetText(IMP_STATS_SHARED.FormatNumber(playerData.damageDone))
	playerRow:GetNamedChild('HealingDone'):SetText(IMP_STATS_SHARED.FormatNumber(playerData.healingDone))

	playerRow:SetHidden(false)
end

local function comparisonFunction(l, r)
	--[[
	if l.medalScore == r.medalScore then
		return l.damageDone > r.damageDone
	end

	return l.medalScore > r.medalScore
	--]]

	return l.damageDone > r.damageDone
end

local GREEN = {0, 120 / 255, 0, 100 / 255}
local RED = {150 / 255, 0, 0, 100 / 255}

function ImperessiveStatsViewer:LayoutRound(roundNumber)
	local match = self.match

	if not (match and match.rounds and match.rounds[roundNumber] and match.rounds[roundNumber].result ~= BATTLEGROUND_ROUND_RESULT_INVALID) then return end
	if roundNumber == self.roundNumber then return end

	local BODY = TLC:GetNamedChild('Body')
	local ROUNDS = BODY:GetNamedChild('Rounds')

	if self.roundNumber then
		local previousSelectedRoundControl = ROUNDS:GetNamedChild('Round' .. self.roundNumber)
		previousSelectedRoundControl:SetColor(GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_NORMAL))
		previousSelectedRoundControl.selected = false
	end

	local selectedRoundControl = ROUNDS:GetNamedChild('Round' .. roundNumber)
	selectedRoundControl:SetColor(GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_SELECTED))
	selectedRoundControl.selected = true

	self.roundNumber = roundNumber

	local round = match.rounds[roundNumber]

	local teams = {
		[1] = {},
		[2] = {},
		[3] = {},
	}
	local players = round.players
	for playerIndex = 1, #players do
		local teamIndex = players[playerIndex].battlegroundTeam

		table.insert(teams[teamIndex], players[playerIndex])
	end

	local maxScore = -1
	local teamWithMaxScore = 0
	for teamIndex, teamScore in pairs(round.scores) do
		if teamScore > maxScore then
			maxScore = teamScore
			teamWithMaxScore = teamIndex
		end
	end

	local numTeams = 0
	for teamIndex = 1, 3 do
		local teamData = teams[teamIndex]
		if #teamData > 1 then
			local teamContainer = self.teamContainers[teamIndex].control

			teamContainer:SetHidden(false)
			local color = teamWithMaxScore == teamIndex and GREEN or RED
			teamContainer:GetNamedChild('BG'):SetColor(unpack(color))

			local left = teamContainer:GetNamedChild('Left')
			left:GetNamedChild('Score'):SetText(round.scores[teamIndex])
			left:GetNamedChild('TeamIcon'):SetTexture(ZO_GetBattlegroundTeamIcon(teamIndex))
			-- left:GetNamedChild('TeamIcon'):SetColor()

			table.sort(teamData, comparisonFunction)

			for playerIndex = 1, 8 do
				local playerData = teamData[playerIndex]
				local control = self.teamContainers[teamIndex].players[playerIndex].control
				if playerData then
					LayoutPlayer(control, playerData)
				else
					control:SetHidden(true)
				end
			end
			numTeams = teamIndex
		end
	end

	ROUNDS:SetAnchor(TOPLEFT, self.teamContainers[numTeams].control, BOTTOMLEFT, 0, 12)
end

function ImperessiveStatsViewer:LayoutMatch(match)
	self:Clear()

	self.match = match

	self:LayoutRound(1)

	local ROUNDS = TLC:GetNamedChild('Body'):GetNamedChild('Rounds')
	if #self.match.rounds > 1 then
		for r = 1, 3 do
			local roundData = match.rounds[r]
			local roundControl = ROUNDS:GetNamedChild('Round' .. r)
			if roundData and roundData.result ~= BATTLEGROUND_ROUND_RESULT_INVALID then
				roundControl:SetHidden(false)
				if r == IMP_STATS_VIEWER.roundNumber then
					roundControl.selected = true
					roundControl:SetColor(GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_SELECTED))
				else
					roundControl.selected = false
					roundControl:SetColor(GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_NORMAL))
				end
			else
				roundControl:SetHidden(true)
			end
		end
		ROUNDS:SetHidden(false)
	else
		ROUNDS:SetHidden(true)
	end

	if match.entryTimestamp then
		local formattedTime = os.date('%d.%m.%Y %H:%M', match.entryTimestamp)
		local localPlayer = match.rounds[1].players[1]
		local formattedPlayer = zo_strformat('<<1>> (<<2>>)', localPlayer.displayName, localPlayer.characterName)
		TLC:GetNamedChild('HeaderLabel'):SetText(
			('%s, %s, %s'):format(formattedTime, GetZoneNameById(match.zoneId), formattedPlayer)
		)
	end

	TLC:SetHidden(false)
end

function ImperessiveStatsViewer:OnDeselect()
	TLC:SetHidden(true)
	self:Clear()
end
