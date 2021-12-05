--[[
	Cloudy Tweaks
	Copyright (c) 2020, Cloudyfa
	All rights reserved.
]]


--- Initialization ---
local function CTweaksDB_Init()
	-- Create new DB if needed --
	if (not CTweaksDB) then
		CTweaksDB = {}

		-- Default configuration --
		CTweaksDB['ConfirmLoot'] = 1
		CTweaksDB['AcceptInvite'] = 1
		CTweaksDB['AcceptSummon'] = nil

		CTweaksDB['AcceptResurrect'] = 1
		CTweaksDB['AutoRelease'] = nil

		CTweaksDB['AutoSell'] = 1
		CTweaksDB['AutoRepair'] = 1
		CTweaksDB['SelfRepair'] = nil
		CTweaksDB['SkipGossip'] = nil

		CTweaksDB['ChatFade'] = nil
		CTweaksDB['ChatArrow'] = 1
		CTweaksDB['ChatScroll'] = 1

		CTweaksDB['MinimapScroll'] = 1
		CTweaksDB['HideMapButton'] = 1
		CTweaksDB['DayNight'] = 1

		CTweaksDB['QuestLevel'] = 1
		CTweaksDB['QuestColor'] = 1
		CTweaksDB['QuestAccept'] = nil
		CTweaksDB['QuestTurnin'] = 1

		CTweaksDB['MapFade'] = nil
		CTweaksDB['MapCoords'] = 1
		CTweaksDB['EliteFrame'] = 1
		CTweaksDB['HideGryphons'] = nil
		CTweaksDB['CamDistance'] = nil
		CTweaksDB['RemoveGlow'] = 1
	end

	-- Check if features are useable --
	if not GetCVar('cameraDistanceMaxZoomFactor') then
		CTweaksUI_CamDistance:Disable()
		CTweaksUI_CamDistance:SetAlpha(0.5)
	end
end


--- Local Functions ---
	-- Detect Friends --
	local function UnitIsInFriendList(name)
		C_FriendList.ShowFriends()

		for i = 1, C_FriendList.GetNumOnlineFriends() do
			local toon = C_FriendList.GetFriendInfoByIndex(i).name
			if toon and (toon == name) then
				return true
			end
		end
		for i = 1, BNGetNumFriends() do
			for j = 1, C_BattleNet.GetFriendNumGameAccounts(i) do
				local friendGameAccount = C_BattleNet.GetFriendGameAccountInfo(i, j)
				local toon = friendGameAccount.characterName
				local client = friendGameAccount.clientProgram
				if (toon == name) and (client == 'WoW') then
					return true
				end
			end
		end

		return false
	end

	-- Update Quest Title --
	local function updateQuestTitle(button, title, tracker)
		local header = tracker and button.HeaderText or button.Text
		local oldHeight = header:GetHeight()
		header:SetText(title)
		if tracker then
			if not button.lineWidth then
				header:SetWidth(255)
			end
		else
			header:SetWidth(200)
		end
		local newHeight = header:GetHeight()
		button:SetHeight(button:GetHeight() + newHeight - oldHeight)
	end

	-- Update Quest Color --
	local function updateQuestColor(id, freq)
		local tag = C_QuestLog.GetQuestTagInfo(id)
		local color = GetDifficultyColor(C_PlayerInfo.GetContentDifficultyQuestForPlayer(id))

		if tag and (tag.tagName == ITEM_QUALITY5_DESC) then
			color = {r = 1.0, g = 0.6, b = 0.1}
		elseif (freq == Enum.QuestFrequency.Daily) then
			color = {r = 0.1, g = 0.6, b = 1.0}
		end
		return color
	end

	-- Minimap Mouse Scroll --
	local function minimapScroll(_, delta)
		if (delta > 0) then
			Minimap_ZoomIn()
		else
			Minimap_ZoomOut()
		end
	end

	-- Update Map Coords --
	local function updateCoords(self)
		if (not WorldMapFrame:IsVisible()) then return end

		local cPos = NOT_APPLICABLE
		local cX, cY = WorldMapFrame:GetNormalizedCursorPosition()
		if cX and cY then
			if not (cX <= 0 or cX >= 1 or cY <= 0 or cY >= 1) then
				cPos = format('%.1f, %.1f', cX * 100, cY * 100)
			end
		end
		self.cursor:SetText(gsub(HARDWARE_CURSOR, HARDWARE, '') .. ': ' .. cPos)

		local pPos, pX, pY = NOT_APPLICABLE, 0, 0
		local mapID = WorldMapFrame:GetMapID() or 0
		local pMap = C_Map.GetPlayerMapPosition(mapID, 'player')
		if pMap then
			pX, pY = pMap:GetXY()
			if not (pX == 0 and pY == 0) then
				pPos = format('%.1f, %.1f', pX * 100, pY * 100)
			end
		end
		self.player:SetText(' ' .. PLAYER .. ' : ' .. pPos)
	end

	-- Map Coords Frame --
	local mCoords = CreateFrame('Frame', nil, WorldMapFrame.ScrollContainer)
	mCoords:SetPoint('BOTTOMLEFT', WorldMapFrame.ScrollContainer)
	mCoords:SetSize(136, 36)

	mCoords.bg = mCoords:CreateTexture()
	mCoords.bg:SetAllPoints(mCoords)
	mCoords.bg:SetColorTexture(0, 0, 0, 0.35)

	mCoords.cursor = mCoords:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
	mCoords.cursor:SetPoint('TOPLEFT', 10, -4)
	mCoords.cursor:SetJustifyH('LEFT')

	mCoords.player = mCoords:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
	mCoords.player:SetPoint('BOTTOMLEFT', 10, 4)
	mCoords.player:SetJustifyH('LEFT')


--- Hook Functions ---
local function CTweaks_Hooks()
	-- QuestLog --
	hooksecurefunc('QuestLogQuests_Update', function()
		if (not CTweaksDB['QuestLevel']) then return end

		for _, button in pairs{QuestMapFrame.QuestsFrame.Contents:GetChildren()} do
			if button and button.Check then
				local info = C_QuestLog.GetInfo(button.questLogIndex)
				if info and info.questID then
					local id, title, level = info.questID, info.title, info.level
					title = '[' .. level .. '] ' .. title

					local memberOnQuest = QuestUtils_GetNumPartyMembersOnQuest(id)
					if (memberOnQuest > 0) then
						title = '[' .. memberOnQuest .. '] ' .. title
					end
					updateQuestTitle(button, title)

					if QuestUtils_IsQuestWatched(id) then
						button.Check:SetPoint('LEFT', button.Text, button.Text:GetWrappedWidth() + 2, 0)
						button.Check:Show()
					else
						button.Check:Hide()
					end
				end
			end
		end
	end)

	-- QuestButton --
	hooksecurefunc('QuestMapLogTitleButton_OnEnter', function(button)
		if CTweaksDB['QuestLevel'] then
			local info = C_QuestLog.GetInfo(button.questLogIndex)
			if info and info.questID then
				local title, level = info.title, info.level
				GameTooltipTextLeft1:SetText('[' .. level .. '] ' .. title)
				GameTooltip:Show()
			end
		end
	end)

	-- QuestInfo --
	hooksecurefunc('QuestInfo_Display', function(template, frame)
		if (not CTweaksDB['QuestLevel']) then return end

		local questFrame = frame:GetParent():GetParent()
		local id = template.questLog and questFrame.questID or GetQuestID()
		local index = C_QuestLog.GetLogIndexForQuestID(id)
		if index then
			local info = C_QuestLog.GetInfo(index)
			if info and info.questID then
				local title, level = info.title, info.level
				QuestInfoTitleHeader:SetText('[' .. level .. '] ' .. title)
			end
		end
	end)

	-- QuestTracker --
	local function hookQuestTracker(self, block, title, index)
		if (not CTweaksDB['QuestLevel']) and (not CTweaksDB['QuestColor']) then return end

		local info = C_QuestLog.GetInfo(index)
		if info and info.questID then
			if CTweaksDB['QuestLevel'] then
				local title, level = info.title, info.level
				title = '[' .. level .. '] ' .. title
				updateQuestTitle(block, title, true)
			end
			if CTweaksDB['QuestColor'] then
				local id, freq = info.questID, info.frequency
				local color = updateQuestColor(id, freq)
				block.HeaderText:SetTextColor(color.r * 0.75, color.g * 0.75, color.b * 0.75)
			else
				local color = OBJECTIVE_TRACKER_COLOR['Header']
				block.HeaderText:SetTextColor(color.r, color.g, color.b)
			end
		end
	end
	hooksecurefunc(QUEST_TRACKER_MODULE, 'SetBlockHeader', hookQuestTracker)
	hooksecurefunc(CAMPAIGN_QUEST_TRACKER_MODULE, 'SetBlockHeader', hookQuestTracker)

	-- QuestHighlight --
	local function hookQuestHeader(self)
		if not CTweaksDB['QuestColor'] then return end

		local block = self:GetParent()
		if block and block.id then
			local index = C_QuestLog.GetLogIndexForQuestID(block.id)
			if index then
				local info = C_QuestLog.GetInfo(index)
				if info and info.questID then
					local freq = info.frequency
					local color = updateQuestColor(block.id, freq)
					if block.isHighlighted then
						block.HeaderText:SetTextColor(color.r * 1.1, color.g * 1.1, color.b * 1.1)
					else
						block.HeaderText:SetTextColor(color.r * 0.75, color.g * 0.75, color.b * 0.75)
					end
				end
			end
		end
	end
	hooksecurefunc('ObjectiveTrackerBlockHeader_OnEnter', hookQuestHeader)
	hooksecurefunc('ObjectiveTrackerBlockHeader_OnLeave', hookQuestHeader)

	-- QuestLink --
	hooksecurefunc('ChatFrame_OnHyperlinkShow', function(_, text, link)
		if CTweaksDB['QuestLevel'] then
			local level = strmatch(text, 'quest:%d+:(\-?%d+)')
			local title = strmatch(link, '%[(.+)%]')
			if level and title then
				if (level == '-1') or (tonumber(level) > 60) then
					level = UnitLevel('player')
				end
				ItemRefTooltipTextLeft1:SetText('[' .. level .. '] ' .. title)
				ItemRefTooltip:Show()
			end
		end
	end)

	-- GreetingPanel --
	QuestFrameGreetingPanel:HookScript('OnShow', function(self)
		if (not self:IsVisible()) or (not CTweaksDB['QuestLevel']) then return end

		for button in self.titleButtonPool:EnumerateActive() do
			local id = button:GetID()
			local title, level
			if button.isActive == 1 then
				title = GetActiveTitle(id)
				level = GetActiveLevel(id)
			else
				title = GetAvailableTitle(id)
				level = GetAvailableLevel(id)
			end

			if title and level then
				button:SetText('[' .. level .. '] ' .. title)
				button:SetHeight(button:GetTextHeight() + 2)
			end
		end
	end)

	-- ProgressPanel --
	QuestFrameProgressPanel:HookScript('OnShow', function(self)
		if (not self:IsVisible()) or (not CTweaksDB['QuestLevel']) then return end

		local id = GetQuestID()
		local index = C_QuestLog.GetLogIndexForQuestID(id)
		if index then
			local info = C_QuestLog.GetInfo(index)
			if info and info.questID then
				local title, level = info.title, info.level
				QuestProgressTitleText:SetText('[' .. level .. '] ' .. title)
			end
		end
	end)
end


--- CTweaks Handler ---
local function CTweaks_Handler()
	if CTweaksDB['ConfirmLoot'] then
		CTweaks:RegisterEvent('CONFIRM_LOOT_ROLL')
		CTweaks:RegisterEvent('CONFIRM_DISENCHANT_ROLL')
	else
		CTweaks:UnregisterEvent('CONFIRM_LOOT_ROLL')
		CTweaks:UnregisterEvent('CONFIRM_DISENCHANT_ROLL')
	end

	if CTweaksDB['AcceptInvite'] then
		CTweaks:RegisterEvent('PARTY_INVITE_REQUEST')
	else
		CTweaks:UnregisterEvent('PARTY_INVITE_REQUEST')
	end

	if CTweaksDB['AcceptSummon'] then
		CTweaks:RegisterEvent('CONFIRM_SUMMON')
	else
		CTweaks:UnregisterEvent('CONFIRM_SUMMON')
	end

	if CTweaksDB['AcceptResurrect'] then
		CTweaks:RegisterEvent('RESURRECT_REQUEST')
	else
		CTweaks:UnregisterEvent('RESURRECT_REQUEST')
	end

	if CTweaksDB['AutoRelease'] then
		CTweaks:RegisterEvent('PLAYER_DEAD')
	else
		CTweaks:UnregisterEvent('PLAYER_DEAD')
	end

	if CTweaksDB['AutoSell'] or CTweaksDB['AutoRepair'] then
		CTweaks:RegisterEvent('MERCHANT_SHOW')
	else
		CTweaks:UnregisterEvent('MERCHANT_SHOW')
	end

	if CTweaksDB['SkipGossip'] then
		CTweaks:RegisterEvent('GOSSIP_SHOW')
	else
		CTweaks:UnregisterEvent('GOSSIP_SHOW')
	end

	for i = 1, NUM_CHAT_WINDOWS do
		if CTweaksDB['ChatFade'] then
			_G['ChatFrame' .. i]:SetFading(true)
		else
			_G['ChatFrame' .. i]:SetFading(false)
		end

		if CTweaksDB['ChatArrow'] then
			_G['ChatFrame' .. i .. 'EditBox']:SetAltArrowKeyMode(false)
		else
			_G['ChatFrame' .. i .. 'EditBox']:SetAltArrowKeyMode(true)
		end

		if CTweaksDB['ChatScroll'] then
			_G['ChatFrame' .. i]:EnableMouseWheel(true)
			_G['ChatFrame' .. i]:SetScript('OnMouseWheel', FloatingChatFrame_OnMouseScroll)
		else
			_G['ChatFrame' .. i]:EnableMouseWheel(false)
			_G['ChatFrame' .. i]:SetScript('OnMouseWheel', nil)
		end
	end

	if CTweaksDB['MinimapScroll'] then
		Minimap:EnableMouseWheel(true)
		Minimap:SetScript('OnMouseWheel', minimapScroll)

		MinimapZoomIn:Hide()
		MinimapZoomOut:Hide()
	else
		Minimap:EnableMouseWheel(false)
		Minimap:SetScript('OnMouseWheel', nil)

		MinimapZoomIn:Show()
		MinimapZoomOut:Show()
	end

	if CTweaksDB['HideMapButton'] then
		MiniMapWorldMapButton:Hide()
		MinimapZoneTextButton:SetPoint('CENTER', 14, 83)
	else
		MiniMapWorldMapButton:Show()
		MinimapZoneTextButton:SetPoint('CENTER', 7, 83)
	end

	if CTweaksDB['DayNight'] then
		GameTimeTexture:Show()
	else
		GameTimeTexture:Hide()
	end

	if CTweaksDB['QuestAccept'] then
		CTweaks:RegisterEvent('QUEST_ACCEPT_CONFIRM')
		CTweaks:RegisterEvent('QUEST_DETAIL')
	else
		CTweaks:UnregisterEvent('QUEST_ACCEPT_CONFIRM')
		CTweaks:UnregisterEvent('QUEST_DETAIL')
	end

	if CTweaksDB['QuestTurnin'] then
		CTweaks:RegisterEvent('QUEST_PROGRESS')
		CTweaks:RegisterEvent('QUEST_COMPLETE')
	else
		CTweaks:UnregisterEvent('QUEST_PROGRESS')
		CTweaks:UnregisterEvent('QUEST_COMPLETE')
	end

	C_QuestLog.SortQuestWatches()

	if CTweaksDB['MapFade'] then
		SetCVar('mapFade', '1')
	else
		SetCVar('mapFade', '0')
	end

	if CTweaksDB['MapCoords'] then
		mCoords:SetScript('OnUpdate', updateCoords)
		mCoords:Show()
	else
		mCoords:SetScript('OnUpdate', nil)
		mCoords:Hide()
	end

	if CTweaksDB['EliteFrame'] then
		PlayerFrameTexture:SetTexture('Interface\\TargetingFrame\\UI-TargetingFrame-Rare-Elite')
	else
		PlayerFrameTexture:SetTexture('Interface\\TargetingFrame\\UI-TargetingFrame')
	end

	if CTweaksDB['HideGryphons'] then
		MainMenuBarArtFrame.LeftEndCap:Hide()
		MainMenuBarArtFrame.RightEndCap:Hide()
	else
		MainMenuBarArtFrame.LeftEndCap:Show()
		MainMenuBarArtFrame.RightEndCap:Show()
	end

	if CTweaksUI_CamDistance:IsEnabled() then
		if CTweaksDB['CamDistance'] then
			SetCVar('cameraDistanceMaxZoomFactor', '2.6')
		else
			SetCVar('cameraDistanceMaxZoomFactor', '1.9')
		end
	end

	if CTweaksDB['RemoveGlow'] then
		SetCVar('ffxGlow', '0')
	else
		SetCVar('ffxGlow', '1')
	end
end


--- CTweaks Loaded ---
function CTweaks_OnLoad(self)
	self:RegisterEvent('PLAYER_LOGIN')
end


--- CTweaks Events ---
function CTweaks_OnEvent(self, event, ...)
	if (event == 'PLAYER_LOGIN') then
		CTweaksDB_Init()
		CTweaksUI_Load()

		CTweaks_Hooks()
		CTweaks_Handler()

	elseif (event == 'CONFIRM_LOOT_ROLL') or (event == 'CONFIRM_DISENCHANT_ROLL') then
		local id, roll = ...
		ConfirmLootRoll(id, roll)
		StaticPopup_Hide('CONFIRM_LOOT_ROLL')

	elseif (event == 'PARTY_INVITE_REQUEST') then
		for index in pairs(LFG_CATEGORY_NAMES) do
			if GetLFGMode(index) then return end
		end

		local sender = ...
		if UnitIsInMyGuild(sender) or UnitIsInFriendList(sender) then
			AcceptGroup()
			for i = 1, STATICPOPUP_NUMDIALOGS do
				local dialog = _G['StaticPopup' .. i]
				if (dialog.which == 'PARTY_INVITE') then
					dialog.inviteAccepted = 1
					StaticPopup_Hide('PARTY_INVITE')
					break
				elseif (dialog.which == 'PARTY_INVITE_XREALM') then
					dialog.inviteAccepted = 1
					StaticPopup_Hide('PARTY_INVITE_XREALM')
					break
				end
			end
		end

	elseif (event == 'CONFIRM_SUMMON') then
		if (not UnitAffectingCombat('player')) then
			C_SummonInfo.ConfirmSummon()
			StaticPopup_Hide('CONFIRM_SUMMON')
		end

	elseif (event == 'RESURRECT_REQUEST') then
		if (GetCorpseRecoveryDelay() > 0) then return end

		local sender = ...
		if (not UnitAffectingCombat(sender)) then
			AcceptResurrect()
			StaticPopup_Hide('RESURRECT_NO_TIMER')
			DoEmote('thank', sender)
		end

	elseif (event == 'PLAYER_DEAD') then
		if C_DeathInfo.GetSelfResurrectOptions() and (#C_DeathInfo.GetSelfResurrectOptions() > 0) then return end

		local instZone, instType = IsInInstance()
		if instZone and (instType == 'pvp') then
			RepopMe()
		end

	elseif event == 'QUEST_ACCEPT_CONFIRM' then
		if IsShiftKeyDown() then return end

		local _, numQuests = C_QuestLog.GetNumQuestLogEntries()
		if (numQuests < MAX_QUESTS) then
			ConfirmAcceptQuest()
			StaticPopup_Hide('QUEST_ACCEPT')
		end

	elseif event == 'QUEST_DETAIL' then
		if IsShiftKeyDown() then return end

		AcceptQuest()
		HideUIPanel(QuestFrame)

	elseif (event == 'QUEST_PROGRESS') then
		if IsShiftKeyDown() then return end

		if IsQuestCompletable() then
			CompleteQuest()
		end

	elseif (event == 'QUEST_COMPLETE') then
		if IsShiftKeyDown() then return end

		local numChoices = GetNumQuestChoices()
		if (numChoices <= 1) then
			GetQuestReward(numChoices)
		end

	elseif (event == 'MERCHANT_SHOW') then
		if IsShiftKeyDown() then return end

		if CTweaksDB['AutoSell'] then
			local total = 0
			for bag = 0, 4 do
				for slot = 1, GetContainerNumSlots(bag) do
					local item = GetContainerItemID(bag, slot)
					if item then
						local _, _, rarity, _, _, _, _, _, _, _, price = GetItemInfo(item)
						if (rarity == 0) and (price > 0) then
							local _, quantity = GetContainerItemInfo(bag, slot)
							total = total + (price * quantity)
							UseContainerItem(bag, slot)
						end
					end
				end
			end

			if (total > 0) then
				print(ITEM_SOLD_COLON .. ' ' .. GetCoinTextureString(total))
			end
		end

		if CTweaksDB['AutoRepair'] then
			local cost, needed = GetRepairAllCost()
			if needed and (cost > 0) then
				local repaired, source

				if (not CTweaksDB['SelfRepair']) and CanGuildBankRepair() then
					local limit = GetGuildBankWithdrawMoney()
					if (limit == -1) or (limit >= cost) then
						local remain = GetGuildBankMoney()
						if (remain == 0) then
							RepairAllItems(1)
							RepairAllItems()
							repaired = 1
						elseif (remain >= cost) then
							RepairAllItems(1)
							repaired = 1
							source = ' (' .. GUILD .. ')'
						end
					end
				end

				if (not repaired) then
					local funds = GetMoney()
					if (funds >= cost) then
						RepairAllItems()
						repaired = 1
					end
				end

				if repaired then
					print(REPAIR_ITEMS .. ' ' .. COSTS_LABEL .. ' ' .. GetCoinTextureString(cost) .. (source or ''))
				else
					print(ERR_NOT_ENOUGH_MONEY .. ' ' .. REQUIRES_LABEL .. ' ' .. GetCoinTextureString(cost))
				end
			end
		end

	elseif (event == 'GOSSIP_SHOW') then
		if IsShiftKeyDown() then return end

		if (GetNumGossipActiveQuests() == 0) and (GetNumGossipAvailableQuests() == 0) then
			if (GetNumGossipOptions() == 1) then
				SelectGossipOption(1)
			end
		end
	end
end


--- Load Configuration ---
function CTweaksUI_Load()
	CTweaksUI_ConfirmLoot:SetChecked(CTweaksDB['ConfirmLoot'])
	CTweaksUI_AcceptInvite:SetChecked(CTweaksDB['AcceptInvite'])
	CTweaksUI_AcceptSummon:SetChecked(CTweaksDB['AcceptSummon'])

	CTweaksUI_AcceptResurrect:SetChecked(CTweaksDB['AcceptResurrect'])
	CTweaksUI_AutoRelease:SetChecked(CTweaksDB['AutoRelease'])

	CTweaksUI_AutoSell:SetChecked(CTweaksDB['AutoSell'])
	CTweaksUI_AutoRepair:SetChecked(CTweaksDB['AutoRepair'])
	CTweaksUI_SelfRepair:SetChecked(CTweaksDB['SelfRepair'])
	CTweaksUI_SkipGossip:SetChecked(CTweaksDB['SkipGossip'])

	CTweaksUI_ChatFade:SetChecked(CTweaksDB['ChatFade'])
	CTweaksUI_ChatArrow:SetChecked(CTweaksDB['ChatArrow'])
	CTweaksUI_ChatScroll:SetChecked(CTweaksDB['ChatScroll'])

	CTweaksUI_MinimapScroll:SetChecked(CTweaksDB['MinimapScroll'])
	CTweaksUI_HideMapButton:SetChecked(CTweaksDB['HideMapButton'])
	CTweaksUI_DayNight:SetChecked(CTweaksDB['DayNight'])

	CTweaksUI_QuestLevel:SetChecked(CTweaksDB['QuestLevel'])
	CTweaksUI_QuestColor:SetChecked(CTweaksDB['QuestColor'])
	CTweaksUI_QuestAccept:SetChecked(CTweaksDB['QuestAccept'])
	CTweaksUI_QuestTurnin:SetChecked(CTweaksDB['QuestTurnin'])

	CTweaksUI_MapFade:SetChecked(CTweaksDB['MapFade'])
	CTweaksUI_MapCoords:SetChecked(CTweaksDB['MapCoords'])
	CTweaksUI_EliteFrame:SetChecked(CTweaksDB['EliteFrame'])
	CTweaksUI_HideGryphons:SetChecked(CTweaksDB['HideGryphons'])
	CTweaksUI_CamDistance:SetChecked(CTweaksDB['CamDistance'])
	CTweaksUI_RemoveGlow:SetChecked(CTweaksDB['RemoveGlow'])
end


--- Save Configuration ---
function CTweaksUI_Save()
	CTweaksDB['ConfirmLoot'] = CTweaksUI_ConfirmLoot:GetChecked()
	CTweaksDB['AcceptInvite'] = CTweaksUI_AcceptInvite:GetChecked()
	CTweaksDB['AcceptSummon'] = CTweaksUI_AcceptSummon:GetChecked()

	CTweaksDB['AcceptResurrect'] = CTweaksUI_AcceptResurrect:GetChecked()
	CTweaksDB['AutoRelease'] = CTweaksUI_AutoRelease:GetChecked()

	CTweaksDB['AutoSell'] = CTweaksUI_AutoSell:GetChecked()
	CTweaksDB['AutoRepair'] = CTweaksUI_AutoRepair:GetChecked()
	CTweaksDB['SelfRepair'] = CTweaksUI_SelfRepair:GetChecked()
	CTweaksDB['SkipGossip'] = CTweaksUI_SkipGossip:GetChecked()

	CTweaksDB['ChatFade'] = CTweaksUI_ChatFade:GetChecked()
	CTweaksDB['ChatArrow'] = CTweaksUI_ChatArrow:GetChecked()
	CTweaksDB['ChatScroll'] = CTweaksUI_ChatScroll:GetChecked()

	CTweaksDB['MinimapScroll'] = CTweaksUI_MinimapScroll:GetChecked()
	CTweaksDB['HideMapButton'] = CTweaksUI_HideMapButton:GetChecked()
	CTweaksDB['DayNight'] = CTweaksUI_DayNight:GetChecked()

	CTweaksDB['QuestLevel'] = CTweaksUI_QuestLevel:GetChecked()
	CTweaksDB['QuestColor'] = CTweaksUI_QuestColor:GetChecked()
	CTweaksDB['QuestAccept'] = CTweaksUI_QuestAccept:GetChecked()
	CTweaksDB['QuestTurnin'] = CTweaksUI_QuestTurnin:GetChecked()

	CTweaksDB['MapFade'] = CTweaksUI_MapFade:GetChecked()
	CTweaksDB['MapCoords'] = CTweaksUI_MapCoords:GetChecked()
	CTweaksDB['EliteFrame'] = CTweaksUI_EliteFrame:GetChecked()
	CTweaksDB['HideGryphons'] = CTweaksUI_HideGryphons:GetChecked()
	CTweaksDB['CamDistance'] = CTweaksUI_CamDistance:GetChecked()
	CTweaksDB['RemoveGlow'] = CTweaksUI_RemoveGlow:GetChecked()
end


--- ConfigUI Loaded ---
function CTweaksUI_OnLoad(self)
	-- Register Option Panel --
	self.name, self.title, self.note = GetAddOnInfo('CloudyTweaks')
	self.cancel = function()
		CTweaksUI_Load()
	end
	self.okay = function()
		CTweaksUI_Save()
		CTweaks_Handler()
	end
	InterfaceOptions_AddCategory(self)

	-- Set ConfigUI Text --
	CTweaksUITitle:SetText(self.title)
	CTweaksUISubText:SetText(self.note)

	CTweaksUI_ConfirmLootText:SetText('Auto confirm loot roll')
	CTweaksUI_AcceptInviteText:SetText('Auto accept party invitation')
	CTweaksUI_AcceptSummonText:SetText('Auto accept offered summon')

	CTweaksUI_AcceptResurrectText:SetText('Auto accept resurrection')
	CTweaksUI_AutoReleaseText:SetText('Auto release in BGs')

	CTweaksUI_AutoSellText:SetText('Auto sell junk')
	CTweaksUI_AutoRepairText:SetText('Auto repair all items')
	CTweaksUI_SelfRepairText:SetText('Use own money only')
	CTweaksUI_SkipGossipText:SetText('Skip useless gossip')

	CTweaksUI_ChatFadeText:SetText('Enable chat fading')
	CTweaksUI_ChatArrowText:SetText('Enable chat arrow keys')
	CTweaksUI_ChatScrollText:SetText('Enable chat scroll')

	CTweaksUI_MinimapScrollText:SetText('Enable minimap scroll')
	CTweaksUI_HideMapButtonText:SetText('Hide worldmap button')
	CTweaksUI_DayNightText:SetText('Day/Night indicator')

	CTweaksUI_QuestLevelText:SetText('Show quest level')
	CTweaksUI_QuestColorText:SetText('Colorize quest tracker')
	CTweaksUI_QuestAcceptText:SetText('Auto accept quest')
	CTweaksUI_QuestTurninText:SetText('Auto turn-in quest')

	CTweaksUI_MapFadeText:SetText('Enable map fading')
	CTweaksUI_MapCoordsText:SetText('Show map coords')
	CTweaksUI_EliteFrameText:SetText('Player elite frame')
	CTweaksUI_HideGryphonsText:SetText('Hide gryphons')
	CTweaksUI_CamDistanceText:SetText('Increase camera distance')
	CTweaksUI_RemoveGlowText:SetText('Remove glowing effect')
end
