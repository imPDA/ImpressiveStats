local MATCHES   = 1
local KILLS     = 2
local DEATHS    = 3
local ASSISTS   = 4
local DAMAGE    = 5
local HEALING   = 6

local function BuildCache(forceRebuild)
    local cache
    if forceRebuild then
        cache = {players={},lastCached=0}
    else
        cache = ImpressiveStatsPlayersCache or {players={},lastCached=0}
    end
    ImpressiveStatsPlayersCache = cache

    local cachedPlayers = cache.players

    local matches = IMP_STATS_MATCHES_MANAGER.matches

    for mi = cache.lastCached + 1, #matches do
        local rounds = matches[mi]['rounds']
        for r = 1, #rounds do
            local players = rounds[r]['players']
            for p = 2, #players do
                local player = players[p]
                local displayName = player['displayName']
                local playerCache = cachedPlayers[displayName] or {{},0,0,0,0,0}
                cachedPlayers[displayName] = playerCache

                playerCache[MATCHES][#playerCache[MATCHES]+1] = mi
                playerCache[KILLS]      = playerCache[KILLS]    + player['kills']
                playerCache[DEATHS]     = playerCache[DEATHS]   + player['deaths']
                playerCache[ASSISTS]    = playerCache[ASSISTS]  + player['assists']
                playerCache[DAMAGE]     = playerCache[DAMAGE]   + player['damageDone']
                playerCache[HEALING]    = playerCache[HEALING]  + player['healingDone']
            end
        end
        cache.lastCached = mi
    end
end

-- ----------------------------------------------------------------------------

local addon = {
    control = IMP_STATS_PlayersSummary,
    listControl = IMP_STATS_PlayersSummaryBodyScrollableList,
    performanceMeter = IMP_STATS_PlayersSummaryPerformanceMeter,
    filters = {
        displayName = nil,  -- always keep in lower case!
    },
    updateStart = nil,
}

local function hex2rgb(hex)  -- TODO: define colors, make them not HEX
    local r = tonumber(hex:sub(1, 2), 16)
    local g = tonumber(hex:sub(3, 4), 16)
    local b = tonumber(hex:sub(5, 6), 16)

    return r / 255, g / 255, b / 255
end

function addon:CreateScrollListDataType()
    -- local function BuildTooltip(rowControl)
    --     local tooltip = ''
    --     local data = rowControl.dataEntry.data
    --     -- ...
    --     return tooltip
    -- end

    -- local function ShowTooltip(rowControl)
    --     ZO_Tooltips_ShowTextTooltip(rowControl, LEFT, BuildTooltip(rowControl))
    -- end

    local function ShowRMBMenu(control, button)
        if button ~= MOUSE_BUTTON_INDEX_RIGHT then return end

        local data = control.dataEntry.data

        ClearMenu()

        local categories = ImpressiveStatsPlayersSV.categories
        local players = ImpressiveStatsPlayersSV.playerCategories

        for categoryIndex, categoryData in ipairs(categories) do
            local text = ('|c%s|t13:13:/art/fx/texture/whitesquare.dds:inheritcolor|t|r %s'):format(categoryData.color, categoryData.name)
            AddCustomMenuItem(text, function()
                local playerDisplayName = data[2]
                players[playerDisplayName] = categoryIndex

                -- GetControl(control, 'Mark'):SetHidden(false)
                -- GetControl(control, 'Mark'):SetColor(hex2rgb(categoryData.color))

                self:Update()
            end)
        end

        AddCustomMenuItem('Clear category', function()
            local playerDisplayName = data[2]
            players[playerDisplayName] = nil

            -- GetControl(control, 'Mark'):SetHidden(true)

            self:Update()
        end)

        ShowMenu()
    end

    local function LayoutRow(rowControl, data, scrollList)
        local damage = data[4]
        local healing = data[5]

        -- if healing > 1000000 then
        --     GetControl(rowControl, 'Mark'):SetHidden(false)
        --     GetControl(rowControl, 'Mark'):SetColor(0, 0, 0.5)
        -- else
        --     GetControl(rowControl, 'Mark'):SetHidden(true)
        -- end

        local categoryIndex = data[6]
        if categoryIndex then
            -- GetControl(rowControl, 'Mark'):SetHidden(false)
            local categoryData = ImpressiveStatsPlayersSV.categories[categoryIndex]
            GetControl(rowControl, 'Mark'):SetColor(hex2rgb(categoryData.color))
        else
            GetControl(rowControl, 'Mark'):SetColor(0.25, 0.25, 0.25)
            -- GetControl(rowControl, 'Mark'):SetHidden(true)
        end

        -- GetControl(rowControl, 'Index'):SetText(rowControl.index)
        GetControl(rowControl, 'Index'):SetText(data[1])
        GetControl(rowControl, 'DisplayName'):SetText(data[2])
        GetControl(rowControl, 'KA'):SetText(('%.1f'):format(data[3]))

        GetControl(rowControl, 'Damage'):SetText(IMP_STATS_SHARED.FormatNumber(damage))
        if damage > 500000 then
            GetControl(rowControl, 'Damage'):SetColor(0.86, 0.3, 0)
        else
            GetControl(rowControl, 'Damage'):SetColor(1, 1, 1)
        end

        GetControl(rowControl, 'Healing'):SetText(IMP_STATS_SHARED.FormatNumber(healing))
        if healing > 500000 then
            GetControl(rowControl, 'Healing'):SetColor(0, 0.7, 0)
        else
            GetControl(rowControl, 'Healing'):SetColor(1, 1, 1)
        end

        rowControl:SetHandler('OnMouseDown', function(control, button)
            if button == MOUSE_BUTTON_INDEX_LEFT then
                ZO_ScrollList_MouseClick(scrollList, rowControl)
            else
                -- rowControl:SetHandler('OnMouseDown', ShowRMBMenu)
                ShowRMBMenu(control, button)
            end
        end)

        -- rowControl:SetHandler('OnMouseEnter', ShowTooltip)
        -- rowControl:SetHandler('OnMouseExit', ZO_Tooltips_HideTextTooltip)
    end

	local control = self.listControl
	local typeId = 1
	local templateName = 'IMP_STATS_PlayersSummaryRow'
	local height = 32
	local setupFunction = LayoutRow
	local hideCallback = nil
	local dataTypeSelectSound = nil
	local resetControlCallback = nil

	ZO_ScrollList_AddDataType(control, typeId, templateName, height, setupFunction, hideCallback, dataTypeSelectSound, resetControlCallback)

    -- local function LayoutMatchRow(previouslySelectedData, selectedData, selectingDuringRebuild)
	-- 	if not selectedData then
	-- 		IMP_STATS_VIEWER:OnDeselect()
	-- 	elseif selectedData then
	-- 		Log('Match selected')
	-- 		local match = IMP_STATS_MATCHES_MANAGER.matches[selectedData.matchIndex]
	-- 		IMP_STATS_VIEWER:LayoutMatch(match)
	-- 	end
	-- end

	-- ZO_ScrollList_EnableSelection(control, 'ZO_ThinListHighlight', LayoutMatchRow)
	-- ZO_ScrollList_SetDeselectOnReselect(control, true)
end

-- Recursive comparison function
-- @param left, right   the two items to compare
-- @param keys          table of key indices (e.g. {sortKey, tiebreaker})
-- @param ascending     true for ascending, false for descending
-- @param idx           current index in 'keys' (start at 1)
-- @return              true if left should come before right
local function compareRecursive(left, right, keys, ascending, idx)
    if idx > #keys then
        return false   -- all keys equal → keep original order (stable)
    end

    local keyIdx = keys[idx]
    local a = left.data[keyIdx]
    local b = right.data[keyIdx]

    local aIsNil = (a == nil)
    local bIsNil = (b == nil)

    -- nil handling: non‑nil always comes first (independent of direction)
    if aIsNil ~= bIsNil then
        return not aIsNil   -- true if a is non‑nil and b is nil
    end

    -- both nil or both non‑nil
    if not aIsNil then
        if a == b then
            -- tie → move to next key
            return compareRecursive(left, right, keys, ascending, idx + 1)
        else
            -- compare according to direction
            if ascending then
                return a < b
            else
                return b < a
            end
        end
    else
        -- both nil → treat as equal, go to next key
        return compareRecursive(left, right, keys, ascending, idx + 1)
    end
end

function addon:Update()
    -- if self:IsHidden() then
    --     self.dirty = true
    --     return
    -- end

    local updateStart = GetGameTimeSeconds()

    BuildCache()  -- TODO

    local control = self.listControl
    local dataList = ZO_ScrollList_GetDataList(control)

    ZO_ScrollList_Clear(control)

    local function CreateAndAddDataEntry(displayName, stats)
        local numMatches = #stats[MATCHES]  -- can it actually be 0?

        -- local deathsSafe = math.max(stats[DEATHS], 1)
        -- local kda = (stats[KILLS] + stats[ASSISTS]) / deathsSafe

        local avgKA =  (stats[KILLS] + stats[ASSISTS]) / numMatches
        local avgDmg = stats[DAMAGE] / numMatches
        local avgHeal = stats[HEALING] / numMatches

        local category = ImpressiveStatsPlayersSV.playerCategories[displayName]

        local value = {numMatches, displayName, avgKA, avgDmg, avgHeal, category}
        local entry = ZO_ScrollList_CreateDataEntry(1, value)

        dataList[#dataList+1] = entry
    end

    for playerDisplayName, playerStats in pairs(ImpressiveStatsPlayersCache.players) do
        if self:PassesFilter(playerDisplayName, playerStats) then
            CreateAndAddDataEntry(playerDisplayName, playerStats)
        end
    end

    local sortingKeyToIndex = {
        ['mark'] = 6,
        ['displayName'] = 2,
        ['numMatches'] = 1,
        ['ka'] = 3,
        ['damage'] = 4,
        ['healing'] = 5,
    }

    local sortingKeyIndex = sortingKeyToIndex[self.sortingKey]

    if not sortingKeyIndex then
        sortingKeyIndex = 6
    end
    local tiebreakerIndex = 2

    local ascending  = self.sortingDirection
    local sortingKeys = { sortingKeyIndex, tiebreakerIndex }

    table.sort(dataList, function(l, r) return compareRecursive(l, r, sortingKeys, ascending, 1) end)

    local updateDuration = GetGameTimeSeconds() - updateStart
    self.performanceMeter:SetText(('Update ~%d ms'):format(updateDuration * 1000))

    ZO_ScrollList_Commit(control)
end

function addon:PassesFilter(playerDisplayName, playerStats)
    local displayName = self.filters.displayName
    if displayName then
        if not playerDisplayName:lower():find(displayName) then
            return
        end
    end

    return true
end

function addon:HookBattlegroundPlayerRow()
    ZO_PostHook(ZO_Battleground_Scoreboard_Player_Row_Object, 'SetupOnAcquire', function(obj, panel, poolKey, data)
        local control = obj.control
        local nameLabel = obj.nameLabel

        local mark = obj.control:GetNamedChild('Mark')
        if not mark then
            mark = CreateControl('$(parent)Mark', control, CT_TEXTURE)
            mark:SetDimensions(20, 20)
            mark:SetAnchor(RIGHT, nameLabel, LEFT, -4)
            mark:SetDrawLayer(DL_TEXT)
        end

        local playerDisplayName = data.displayName
        local categoryIndex = ImpressiveStatsPlayersSV.playerCategories[playerDisplayName]

        if categoryIndex then
            local categoryData = ImpressiveStatsPlayersSV.categories[categoryIndex]
            mark:SetHidden(false)
            mark:SetColor(hex2rgb(categoryData.color))
        else
            mark:SetHidden(true)
        end
    end)
end

function addon:HookBattlegroundPlayerRowMenu()
    ZO_PreHook(BATTLEGROUND_SCOREBOARD_FRAGMENT, 'ShowKeyboardPlayerMenu', function(obj, anchorToControl)
        ClearMenu()

        local data = obj.selectedPlayerData
        if not data then return end

        if IsChatSystemAvailableForCurrentPlatform() then
            AddMenuItem(GetString(SI_SOCIAL_LIST_SEND_MESSAGE), function() StartChatInput("", CHAT_CHANNEL_WHISPER, data.displayName) end)
        end

        if not data.isLocalPlayer then
            if not IsFriend(data.displayName) then
                AddMenuItem(GetString(SI_SOCIAL_MENU_ADD_FRIEND), function() ZO_Dialogs_ShowDialog("REQUEST_FRIEND", {name = data.displayName}) end)
            end

            local function SendMailCallback()
                if not IsUnitDead("player") then
                    MAIL_SEND:ComposeMailTo(data.displayName)
                else
                    ZO_AlertEvent(EVENT_UI_ERROR, SI_CANNOT_DO_THAT_WHILE_DEAD)
                end
            end
            AddMenuItem(GetString(SI_SOCIAL_MENU_SEND_MAIL), SendMailCallback)

            AddMenuItem(GetString(SI_FRIEND_MENU_IGNORE), function() AddIgnore(data.displayName) end)
        end

        local playerDisplayName = data.displayName

        local categories = ImpressiveStatsPlayersSV.categories
        local players = ImpressiveStatsPlayersSV.playerCategories

        for categoryIndex, categoryData in ipairs(categories) do
            local text = ('|c%s|t13:13:/art/fx/texture/whitesquare.dds:inheritcolor|t|r %s'):format(categoryData.color, categoryData.name)
            AddCustomMenuItem(text, function()
                players[playerDisplayName] = categoryIndex

                GetControl(anchorToControl, 'Mark'):SetHidden(false)
                GetControl(anchorToControl, 'Mark'):SetColor(hex2rgb(categoryData.color))

                self:Update()
            end)
        end

        AddCustomMenuItem('Clear category', function()
            players[playerDisplayName] = nil

            GetControl(anchorToControl, 'Mark'):SetHidden(true)

            self:Update()
        end)

        ShowMenu(anchorToControl)

        return true
    end)
end

function addon:AddSelfToBattlegroundMatchesScene()
    local sceneName = 'IMP_STATS_MENU' .. SI_IMP_PVP_METER_BATTLEGROUNS_TAB_TITLE .. 'Scene'
    local scene = SCENE_MANAGER.scenes[sceneName]

    if not scene then return end

    local fragment = ZO_SimpleSceneFragment:New(self.control)
    scene:AddFragment(fragment)

    -- self.fragment = fragment

    fragment:RegisterCallback('StateChange', function(oldState, newState)
        if newState == ZO_STATE.SHOWING then
            self:Update()
        end
    end)
end

function addon:HookMatchesUpdate()
    -- TODO: implement event-callback system instead of this monstrosity?
    ZO_PostHook(IMP_STATS_MATCHES_UI, 'Update', function() zo_callLater(function() self:Update() end, 2000) end)
end

function addon:InitializeSearch()
    local function OnSearchTextChanged(editBox)
        local newText = string.lower(editBox:GetText())

        if newText == self.filters.displayName then return end

        self.filters.displayName = newText
        self:Update()
    end

    local searchBox = GetControl(self.control, 'HeaderPlayerSearchBox')
    searchBox:SetDefaultText('Enter player display name')
    searchBox:SetHandler('OnTextChanged',  OnSearchTextChanged)
end

function addon:SetupSortingHeaders()
    local headers = GetControl(self.control, 'BodyHeaders')

    local sortingHeaders = {
        ['mark'] = 'Mark',
        ['displayName'] = 'DisplayName',
        ['numMatches'] = 'NumMatches',
        ['ka'] = 'KA',
        ['damage'] = 'Damage',
        ['healing'] = 'Healing',
    }

    self.sortingKey = 'mark'
    self.sortingDirection = true

    local SORTING_TEXTURES = {
        -- [true] = '/esoui/art/miscellaneous/list_sortheader_icon_sortdown.dds',
        -- [false] = '/esoui/art/miscellaneous/list_sortheader_icon_sortup.dds',
        [true] = '/esoui/art/miscellaneous/list_sortdown.dds',
        [false] = '/esoui/art/miscellaneous/list_sortup.dds',
    }

    for sortingKey, headerContorolName in pairs(sortingHeaders) do
        local headerControl = headers:GetNamedChild(headerContorolName)
        headerControl:SetHandler('OnMouseDown', function(button)
            if self.sortingKey == sortingKey then
                self.sortingDirection = not self.sortingDirection
            else
                self.sortingKey = sortingKey
                self.sortingDirection = true
            end

            local sortingOrderIcon = headers:GetNamedChild('SortingOrderIcon')
            sortingOrderIcon:SetTexture(SORTING_TEXTURES[self.sortingDirection])
            sortingOrderIcon:ClearAnchors()
            if self.sortingDirection then
                sortingOrderIcon:SetAnchor(TOP, headerControl, BOTTOM, 0, -8)
            else
                sortingOrderIcon:SetAnchor(BOTTOM, headerControl, TOP, 0, 8)
            end

            if self.sortingKey == 'mark' and self.sortingDirection then
                sortingOrderIcon:SetHidden(true)
            else
                sortingOrderIcon:SetHidden(false)  -- TODO: can somehow get rid of it?
            end

            self:Update()
        end)
    end
end

function addon:Initialize()
    ImpressiveStatsPlayersSV = ImpressiveStatsPlayersSV or {
        playerCategories = {},
        categories = {
            {color='FF3333', name='Category 1'},
            {color='FF6633', name='Category 2'},
            {color='FFCC33', name='Category 3'},
            {color='CCFF33', name='Category 4'},
            {color='33FF66', name='Category 5'},
            {color='33CC33', name='Category 6'},
        }
    }

    self:CreateScrollListDataType()

    self:InitializeSearch()

    SLASH_COMMANDS['/impSTATSrebuildcache'] = function()
        BuildCache(true)
    end

    self:AddSelfToBattlegroundMatchesScene()

    self:HookBattlegroundPlayerRow()
    self:HookBattlegroundPlayerRowMenu()

    self:SetupSortingHeaders()

    -- self:HookMatchesUpdate()

    return self
end

-- TODO: SV handling, unify RMB, unify setting player category

-- TODO: remake XML with simple controls in headers and labels inside so 
-- sortind direction icon can be anchored to the cneter of label independently
-- from column actual width

-- ----------------------------------------------------------------------------

function IMP_STATS_InitializePlayersStats()
    addon:Initialize()
end
