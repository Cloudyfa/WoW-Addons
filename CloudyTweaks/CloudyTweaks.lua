--[[
	Cloudy Tweaks
	Copyright (c) 2016, Cloudyfa
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

		CTweaksDB['QuestLevel'] = 1
		CTweaksDB['QuestColor'] = 1
		CTweaksDB['HideTracker'] = nil
		CTweaksDB['QuestAccept'] = 1
		CTweaksDB['QuestTurnin'] = 1

		CTweaksDB['AutoSell'] = 1
		CTweaksDB['AutoRepair'] = 1
		CTweaksDB['SelfRepair'] = nil

		CTweaksDB['MinimapWheel'] = 1
		CTweaksDB['HideZoomButton'] = nil
		CTweaksDB['HideMapButton'] = 1
		CTweaksDB['DayNight'] = 1

		CTweaksDB['SkipGossip'] = 1
		CTweaksDB['DressUpButton'] = 1
		CTweaksDB['MapFade'] = 1
		CTweaksDB['ChatFade'] = nil
		CTweaksDB['ChatArrow'] = 1
		CTweaksDB['EliteFrame'] = 1
		CTweaksDB['HideGryphons'] = nil
		CTweaksDB['CamDistance'] = nil
	end
end


--- Local Functions ---
	-- Detect Friends --
	local function UnitIsInFriendList(name)
		ShowFriends()

		for i = 1, GetNumFriends() do
			local toon = GetFriendInfo(i)
			if (toon == name) then
				return true
			end
		end

		for i = 1, BNGetNumFriends() do
			local _, _, _, _, toon, _, client = BNGetFriendInfo(i)
			if (toon == name) and (client == 'WoW') then
				return true
			end
		end

		return false
	end

	-- Scan Gossip Quests --
	local function scanGossip()
		local ListQuests = {}

		for i = 1, GetNumGossipActiveQuests() do
			local quest = {}
			quest.title, quest.level = select(6 * (i - 1) + 1, GetGossipActiveQuests())

			table.insert(ListQuests, quest)
		end

		for i = 1, GetNumGossipAvailableQuests() do
			local quest = {}
			quest.title, quest.level = select(7 * (i - 1) + 1, GetGossipAvailableQuests())

			table.insert(ListQuests, quest)
		end

		return ListQuests
	end

	-- Scan Greeting Quests --
	local function scanGreeting()
		local ListQuests = {}

		for i = 1, GetNumActiveQuests() do
			local quest = {}
			quest.title = GetActiveTitle(i)
			quest.level = GetActiveLevel(i)

			table.insert(ListQuests, quest)
		end

		for i = 1, GetNumAvailableQuests() do
			local quest = {}
			quest.title = GetAvailableTitle(i)
			quest.level = GetAvailableLevel(i)

			table.insert(ListQuests, quest)
		end

		return ListQuests
	end

	-- Update Quest Title --
	local function updateQuestTitle(quest, block, title)
		local oldHeight = block:GetHeight()
		local width = block:GetWidth()
		block:SetText(title)
		block:SetWidth(width + 18)

		local newHeight = block:GetHeight()
		quest:SetHeight(quest:GetHeight() + newHeight - oldHeight)
	end

	-- Update Quest Color --
	local function updateQuestColor(id, level, freq)
		local _, tag = GetQuestTagInfo(id)
		local color = GetQuestDifficultyColor(level)

		if (tag == ITEM_QUALITY5_DESC) then
			color = {r = 1.0, g = 0.6, b = 0.1}
		elseif (freq == LE_QUEST_FREQUENCY_DAILY) then
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

	-- Tabard Buttons --
	local tabard1 = CreateFrame('Button', nil, DressUpFrame, 'UIPanelButtonTemplate')
	tabard1.Text:SetText(TABARDSLOT)
	tabard1:SetSize(80, 22)
	tabard1:SetPoint('RIGHT', DressUpFrameResetButton, 'LEFT')
	tabard1:SetScript('OnClick', function()
		DressUpModel:UndressSlot(19)
		PlaySound('gsTitleOptionOK')
	end)

	local tabard2 = CreateFrame('Button', nil, SideDressUpFrame, 'UIPanelButtonTemplate')
	tabard2.Text:SetText(TABARDSLOT)
	tabard2:SetSize(80, 22)
	tabard2:SetPoint('TOP', SideDressUpModelResetButton, 'BOTTOM')
	tabard2:SetScript('OnClick', function()
		SideDressUpModel:UndressSlot(19)
		PlaySound('gsTitleOptionOK')
	end)


--- Hook Functions ---
local function CTweaks_Hooks()
	-- QuestLog --
	hooksecurefunc('QuestLogQuests_Update', function()
		if (not CTweaksDB['QuestLevel']) then return end

		for _, button in pairs(QuestMapFrame.QuestsFrame.Contents.Titles) do
			if button and button:IsShown() then
				local title, level = GetQuestLogTitle(button.questLogIndex)
				title = '[' .. level .. '] ' .. title

				local memberOnQuest = 0
				for i = 1, GetNumSubgroupMembers() do
					if IsUnitOnQuestByQuestID(button.questID, 'party'..i) then
						memberOnQuest = memberOnQuest + 1
					end
				end
				if ( memberOnQuest > 0 ) then
					title = '[' .. memberOnQuest .. '] ' .. title
				end
				updateQuestTitle(button, button.Text, title)

				if button.Check:IsShown() then
					button.Check:SetPoint('LEFT', button.Text, button.Text:GetWrappedWidth() + 2, 0)
				end
			end
		end
	end)

	-- QuestInfo --
	hooksecurefunc('QuestInfo_Display', function(self)
		if (not CTweaksDB['QuestLevel']) then return end

		for i = 1, #self.elements, 3 do
			if (self.elements[i] == QuestInfo_ShowTitle) then
				if QuestInfoFrame.questLog then
					local index = GetQuestLogSelection()
					local title, level = GetQuestLogTitle(index)
					QuestInfoTitleHeader:SetText('[' .. level .. '] ' .. title)
				end
			end
		end
	end)

	-- QuestTracker --
	hooksecurefunc(QUEST_TRACKER_MODULE, 'SetBlockHeader', function(_, block, title, index)
		if CTweaksDB['HideTracker'] then return end
		if (not CTweaksDB['QuestLevel']) and (not CTweaksDB['QuestColor']) then return end

		local _, level, _, _, _, _ , freq = GetQuestLogTitle(index)
		if CTweaksDB['QuestLevel'] and level then
			updateQuestTitle(block, block.HeaderText, '[' .. level .. '] ' .. title)
		end

		if CTweaksDB['QuestColor'] then
			local color = updateQuestColor(index, level, freq)
			block.HeaderText:SetTextColor(color.r * 0.75, color.g * 0.75, color.b * 0.75)
		else
			local color = OBJECTIVE_TRACKER_COLOR['Header']
			block.HeaderText:SetTextColor(color.r, color.g, color.b)
		end
	end)

	-- QuestHighlight --
	local function HookQuestTracker(self)
		if CTweaksDB['QuestColor'] then
			local block = self:GetParent()
			if block and block.id then
				local index = GetQuestLogIndexByID(block.id)
				local _, level, _, _, _, _ , freq = GetQuestLogTitle(index)
				local color = updateQuestColor(block.id, level, freq)

				if block.isHighlighted then
					block.HeaderText:SetTextColor(color.r * 1.1, color.g * 1.1, color.b * 1.1)
				else
					block.HeaderText:SetTextColor(color.r * 0.75, color.g * 0.75, color.b * 0.75)
				end
			end
		end
	end
	hooksecurefunc('ObjectiveTrackerBlockHeader_OnEnter', HookQuestTracker)
	hooksecurefunc('ObjectiveTrackerBlockHeader_OnLeave', HookQuestTracker)

	-- QuestLink --
	hooksecurefunc('ChatFrame_OnHyperlinkShow', function(_, _, link)
		if CTweaksDB['QuestLevel'] then
			local level, title = strmatch(link, 'quest:%d+:(\-?%d+)|h%[(.+)%]|h|r')
			if level and title then
				if (level == '-1') then level = UnitLevel('player') end
				ItemRefTooltipTextLeft1:SetText('[' .. level .. '] ' .. title)
				ItemRefTooltip:Show()
			end
		end
	end)

	-- QuestPOI --
	local function HookQuestPOI(_, index)
		if CTweaksDB['QuestLevel'] then
			local title, level = GetQuestLogTitle(index)
			WorldMapTooltipTextLeft1:SetText('[' .. level .. '] ' .. title)
			WorldMapTooltip:Show()
		end
	end
	hooksecurefunc('WorldMapQuestPOI_SetTooltip', HookQuestPOI)
	hooksecurefunc('WorldMapQuestPOI_AppendTooltip', HookQuestPOI)

	-- GossipFrame --
	GossipFrame:HookScript('OnUpdate', function()
		if (not CTweaksDB['QuestLevel']) or (not GossipFrame:IsShown()) then return end

		local GossipQuests = scanGossip()
		for _, quest in pairs(GossipQuests) do
			if (not quest.level) or (not quest.title) then return end
			if (quest.level == -1) then quest.level = UnitLevel('player') end

			for i = 1, GossipFrame.buttonIndex do
				local button = _G['GossipTitleButton' .. i]
				if button:IsShown() and button:GetText() and strfind(button:GetText(), quest.title, 1, true) then
					button:SetText('[' .. quest.level .. '] ' .. quest.title)
					GossipResize(button)
					break
				end
			end
		end
	end)

	-- GreetingPanel --
	QuestFrameGreetingPanel:HookScript('OnUpdate', function()
		if (not CTweaksDB['QuestLevel']) or (not QuestFrameGreetingPanel:IsShown()) then return end

		local GreetingQuests = scanGreeting()
		for index, quest in pairs(GreetingQuests) do
			if (quest.level == -1) then quest.level = UnitLevel('player') end

			local button = _G['QuestTitleButton' .. index]
			button:SetText('[' .. quest.level .. '] ' .. quest.title)
			button:SetHeight(button:GetTextHeight() + 2)
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

	if CTweaksDB['HideTracker'] then
		ObjectiveTrackerFrame:Hide()
	else
		ObjectiveTrackerFrame:Show()
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

	SortQuestWatches()

	if CTweaksDB['AutoSell'] or CTweaksDB['AutoRepair'] then
		CTweaks:RegisterEvent('MERCHANT_SHOW')
	else
		CTweaks:UnregisterEvent('MERCHANT_SHOW')
	end

	if CTweaksDB['MinimapWheel'] then
		Minimap:EnableMouseWheel(true)
		Minimap:SetScript('OnMouseWheel', minimapScroll)
	else
		Minimap:EnableMouseWheel(false)
		Minimap:SetScript('OnMouseWheel', nil)
	end

	if CTweaksDB['HideZoomButton'] then
		MinimapZoomIn:Hide()
		MinimapZoomOut:Hide()
	else
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

	if CTweaksDB['SkipGossip'] then
		CTweaks:RegisterEvent('GOSSIP_SHOW')
	else
		CTweaks:UnregisterEvent('GOSSIP_SHOW')
	end

	if CTweaksDB['DressUpButton'] then
		tabard1:Show()
		tabard2:Show()
	else
		tabard1:Hide()
		tabard2:Hide()
	end

	if CTweaksDB['MapFade'] then
		SetCVar('mapFade', '1')
	else
		SetCVar('mapFade', '0')
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
	end

	if CTweaksDB['EliteFrame'] then
		PlayerFrameTexture:SetTexture('Interface\\TargetingFrame\\UI-TargetingFrame-Rare-Elite')
	else
		PlayerFrameTexture:SetTexture('Interface\\TargetingFrame\\UI-TargetingFrame')
	end

	if CTweaksDB['HideGryphons'] then
		MainMenuBarLeftEndCap:Hide()
		MainMenuBarRightEndCap:Hide()
	else
		MainMenuBarLeftEndCap:Show()
		MainMenuBarRightEndCap:Show()
	end

	if CTweaksDB['CamDistance'] then
		SetCVar('cameraDistanceMaxFactor', '2.6')
	else
		SetCVar('cameraDistanceMaxFactor', '1.9')
	end
end


--- CTweaks Loaded ---
function CTweaks_OnLoad(self)
	self:RegisterEvent('PLAYER_LOGIN')
	self:RegisterEvent('PLAYER_ENTERING_WORLD')
end


--- CTweaks Events ---
function CTweaks_OnEvent(self, event, ...)
	if (event == 'PLAYER_LOGIN') then
		CTweaksDB_Init()
		CTweaksUI_Load()

		CTweaks_Hooks()
		CTweaks_Handler()

	elseif (event == 'PLAYER_ENTERING_WORLD') then
		if CTweaksDB['CamDistance'] then
			SetCVar('cameraDistanceMaxFactor', '2.6')
		end

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
			ConfirmSummon()
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
		if HasSoulstone() then return end

		local instZone, instType = IsInInstance()
		if instZone and (instType == 'pvp') then
			RepopMe()
		end

	elseif event == 'QUEST_ACCEPT_CONFIRM' then
		if IsShiftKeyDown() then return end

		local _, numQuests = GetNumQuestLogEntries()
		if (numQuests < MAX_QUESTS) then
			ConfirmAcceptQuest()
			StaticPopup_Hide('QUEST_ACCEPT')
		end

	elseif event == 'QUEST_DETAIL' then
		if IsShiftKeyDown() then return end

		if QuestFrame.autoQuest then
			AcknowledgeAutoAcceptQuest()
		else
			AcceptQuest()
		end

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

	CTweaksUI_QuestLevel:SetChecked(CTweaksDB['QuestLevel'])
	CTweaksUI_QuestColor:SetChecked(CTweaksDB['QuestColor'])
	CTweaksUI_HideTracker:SetChecked(CTweaksDB['HideTracker'])
	CTweaksUI_QuestAccept:SetChecked(CTweaksDB['QuestAccept'])
	CTweaksUI_QuestTurnin:SetChecked(CTweaksDB['QuestTurnin'])

	CTweaksUI_AutoSell:SetChecked(CTweaksDB['AutoSell'])
	CTweaksUI_AutoRepair:SetChecked(CTweaksDB['AutoRepair'])
	CTweaksUI_SelfRepair:SetChecked(CTweaksDB['SelfRepair'])

	CTweaksUI_MinimapWheel:SetChecked(CTweaksDB['MinimapWheel'])
	CTweaksUI_HideZoomButton:SetChecked(CTweaksDB['HideZoomButton'])
	CTweaksUI_HideMapButton:SetChecked(CTweaksDB['HideMapButton'])
	CTweaksUI_DayNight:SetChecked(CTweaksDB['DayNight'])

	CTweaksUI_SkipGossip:SetChecked(CTweaksDB['SkipGossip'])
	CTweaksUI_DressUpButton:SetChecked(CTweaksDB['DressUpButton'])
	CTweaksUI_MapFade:SetChecked(CTweaksDB['MapFade'])
	CTweaksUI_ChatFade:SetChecked(CTweaksDB['ChatFade'])
	CTweaksUI_ChatArrow:SetChecked(CTweaksDB['ChatArrow'])
	CTweaksUI_EliteFrame:SetChecked(CTweaksDB['EliteFrame'])
	CTweaksUI_HideGryphons:SetChecked(CTweaksDB['HideGryphons'])
	CTweaksUI_CamDistance:SetChecked(CTweaksDB['CamDistance'])
end


--- Save Configuration ---
function CTweaksUI_Save()
	CTweaksDB['ConfirmLoot'] = CTweaksUI_ConfirmLoot:GetChecked()
	CTweaksDB['AcceptInvite'] = CTweaksUI_AcceptInvite:GetChecked()
	CTweaksDB['AcceptSummon'] = CTweaksUI_AcceptSummon:GetChecked()

	CTweaksDB['AcceptResurrect'] = CTweaksUI_AcceptResurrect:GetChecked()
	CTweaksDB['AutoRelease'] = CTweaksUI_AutoRelease:GetChecked()

	CTweaksDB['QuestLevel'] = CTweaksUI_QuestLevel:GetChecked()
	CTweaksDB['QuestColor'] = CTweaksUI_QuestColor:GetChecked()
	CTweaksDB['HideTracker'] = CTweaksUI_HideTracker:GetChecked()
	CTweaksDB['QuestAccept'] = CTweaksUI_QuestAccept:GetChecked()
	CTweaksDB['QuestTurnin'] = CTweaksUI_QuestTurnin:GetChecked()

	CTweaksDB['AutoSell'] = CTweaksUI_AutoSell:GetChecked()
	CTweaksDB['AutoRepair'] = CTweaksUI_AutoRepair:GetChecked()
	CTweaksDB['SelfRepair'] = CTweaksUI_SelfRepair:GetChecked()

	CTweaksDB['MinimapWheel'] = CTweaksUI_MinimapWheel:GetChecked()
	CTweaksDB['HideZoomButton'] = CTweaksUI_HideZoomButton:GetChecked()
	CTweaksDB['HideMapButton'] = CTweaksUI_HideMapButton:GetChecked()
	CTweaksDB['DayNight'] = CTweaksUI_DayNight:GetChecked()

	CTweaksDB['SkipGossip'] = CTweaksUI_SkipGossip:GetChecked()
	CTweaksDB['DressUpButton'] = CTweaksUI_DressUpButton:GetChecked()
	CTweaksDB['MapFade'] = CTweaksUI_MapFade:GetChecked()
	CTweaksDB['ChatFade'] = CTweaksUI_ChatFade:GetChecked()
	CTweaksDB['ChatArrow'] = CTweaksUI_ChatArrow:GetChecked()
	CTweaksDB['EliteFrame'] = CTweaksUI_EliteFrame:GetChecked()
	CTweaksDB['HideGryphons'] = CTweaksUI_HideGryphons:GetChecked()
	CTweaksDB['CamDistance'] = CTweaksUI_CamDistance:GetChecked()
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

	CTweaksUI_QuestLevelText:SetText('Show quest level')
	CTweaksUI_QuestColorText:SetText('Colorize quest tracker')
	CTweaksUI_HideTrackerText:SetText('Hide quest tracker')
	CTweaksUI_QuestAcceptText:SetText('Auto accept quest')
	CTweaksUI_QuestTurninText:SetText('Auto turn-in quest')

	CTweaksUI_AutoSellText:SetText('Auto sell junk')
	CTweaksUI_AutoRepairText:SetText('Auto repair all items')
	CTweaksUI_SelfRepairText:SetText('Use own money only')

	CTweaksUI_MinimapWheelText:SetText('Enable mouse wheel')
	CTweaksUI_HideZoomButtonText:SetText('Hide zoom buttons')
	CTweaksUI_HideMapButtonText:SetText('Hide world map button')
	CTweaksUI_DayNightText:SetText('Day/Night indicator')

	CTweaksUI_SkipGossipText:SetText('Skip useless gossip')
	CTweaksUI_DressUpButtonText:SetText('Show dress-up buttons')
	CTweaksUI_MapFadeText:SetText('Enable worldmap fading effect')
	CTweaksUI_ChatFadeText:SetText('Enable chat fading effect')
	CTweaksUI_ChatArrowText:SetText('Enable chat arrow keys')
	CTweaksUI_EliteFrameText:SetText('Player elite frame')
	CTweaksUI_HideGryphonsText:SetText('Hide gryphons')
	CTweaksUI_CamDistanceText:SetText('Increase camera distance')
end
