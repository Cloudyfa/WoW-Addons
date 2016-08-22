--[[
	Cloudy Tooltip Mod
	Copyright (c) 2016, Cloudyfa
	All rights reserved.
]]


--- Initialization ---
local function CTipModDB_Init()
	-- Create new DB if needed --
	if (not CTipModDB) then
		CTipModDB = {}

		-- Default configuration --
		CTipModDB['MouseAnchor'] = 1

		CTipModDB['TipColor'] = 1
		CTipModDB['ClassColor'] = 1
		CTipModDB['HideHealth'] = nil
		CTipModDB['HideBorder'] = nil

		CTipModDB['TipScale'] = 1

		CTipModDB['UnitTitle'] = nil
		CTipModDB['UnitGender'] = 1
		CTipModDB['UnitStatus'] = nil
		CTipModDB['UnitRealm'] = nil
		CTipModDB['GuildRank'] = nil

		CTipModDB['TargetOfTarget'] = 1
		CTipModDB['TradeGoodsInfo'] = 1
	end
end


--- Local Functions ---
	-- Get Class Color --
	local function GetClassColor(unit)
		local name, str = UnitClass(unit)

		local color = RAID_CLASS_COLORS[str]
		color = string.format('|cff%.2x%.2x%.2x', color.r * 255, color.g * 255, color.b * 255)

		return color, name
	end

	-- Get Unit Color --
	local function GetUnitColor(unit)
		local r, g, b = GameTooltip_UnitColor(unit)
		local color = string.format('|cff%.2x%.2x%.2x', r * 255, g * 255, b * 255)

		if UnitIsDeadOrGhost(unit) or (not UnitIsConnected(unit)) then
			color = '|cff888888'
		elseif UnitIsPlayer(unit) or UnitPlayerControlled(unit) then
			if CTipModDB['TipColor'] and CTipModDB['ClassColor'] then
				if UnitIsPlayer(unit) then
					color = GetClassColor(unit)
				elseif not UnitIsPVP(unit) then
					color = '|cff0099ff'
				end
			elseif (not UnitIsPVP(unit)) or (UnitInParty(unit) and not UnitIsVisible(unit)) then
				color = '|cff0099ff'
			end
		elseif UnitIsTapDenied(unit) then
			color = '|cff77aaaa'
		end

		if C_PetBattles.IsInBattle() then
			if UnitIsBattlePetCompanion(unit) then
				color = '|cff0099ff'
			elseif UnitIsWildBattlePet(unit) then
				color = '|cffe5b200'
			end
		end

		return color
	end

	-- Get Level Color --
	local function GetLevelColor(level)
		local color = '|cffff3333'

		if (level ~= '??') then
			color = GetQuestDifficultyColor(level)
			color = string.format('|cff%.2x%.2x%.2x', color.r * 255, color.g * 255, color.b * 255)
		end

		return color
	end

	-- Color Tooltip --
	local function ColorTooltip(tooltip, color)
		local r, g, b = 0.7, 0.7, 0.7
		local border = (CTipModDB['HideBorder'] and 0) or 1

		if CTipModDB['TipColor'] then
			if color and (strlen(color) == 10) then
				r = tonumber(strsub(color, 5, 6), 16) / 255
				g = tonumber(strsub(color, 7, 8), 16) / 255
				b = tonumber(strsub(color, 9), 16) / 255
			end
		end

		tooltip:SetBackdropBorderColor(r  * 1.2, g * 1.2, b * 1.2, border)
		tooltip:SetBackdropColor(r * 0.2, g * 0.2, b * 0.2)
	end


--- Hook Functions ---
local function CTipMod_Hooks()
	-- Tooltip Anchor --
	hooksecurefunc('GameTooltip_SetDefaultAnchor', function(self, parent)
		if (not CTipModDB['MouseAnchor']) then return end

		local frame = GetMouseFocus()
		if (frame == WorldFrame) then
			self:SetOwner(parent, 'ANCHOR_CURSOR')
		end
	end)

	-- Tooltip Color --
	GameTooltip:HookScript('OnUpdate', function(self)
		local _, unit = self:GetUnit()
		local color = unit and GetUnitColor(unit)

		if (not color) then
			local _, link = self:GetItem()
			color = link and strmatch(link, '(|c%x+)')
		end

		ColorTooltip(self, color)
	end)

	-- Hyperlink Tooltip Color --
	hooksecurefunc('ChatFrame_OnHyperlinkShow', function(_, link, text)
		local linkType = link and strmatch(link, '(%w+)')

		if (linkType ~= 'player') and (linkType ~= 'channel') and (linkType ~= 'trade') then
			local color = text and strmatch(text, '(|c%x+)')
			ColorTooltip(ItemRefTooltip, color)
		end
	end)

	-- Comparison Tooltip Color --
	hooksecurefunc('GameTooltip_ShowCompareItem', function(self)
		if self and self.shoppingTooltips then
			for _, tooltip in pairs(self.shoppingTooltips) do
				local _, link = tooltip:GetItem()
				local color = link and strmatch(link, '(|c%x+)')

				ColorTooltip(tooltip, color)
			end
		end
	end)

	-- Modify Item Tooltip --
	local function OnTooltipSetItem(self)
		if (not CTipModDB['TradeGoodsInfo']) then return end

		local _, link = self:GetItem()
		if (not link) then return end

		local id = strmatch(link, 'item:(%d+)')
		if (not id) then return end

		local itemType, subType = select(6, GetItemInfo(id))

		if (itemType == 'Trade Goods') or (itemType == 'Artisanat') or (itemType == 'Handwerkswaren') or (itemType == 'Mercadorias') or (itemType == 'Objeto comerciable') or (itemType == 'Beni commerciali') or (itemType == 'Хозяйственные товары') or (itemType == '직업용품') or (itemType == '商品') then
			self:AddLine(itemType .. ': |cffaaff77' .. (subType or UNKNOWN))
		end
	end
	GameTooltip:HookScript('OnTooltipSetItem', OnTooltipSetItem)
	ItemRefTooltip:HookScript('OnTooltipSetItem', OnTooltipSetItem)

	-- Modify Unit Tooltip --
	local function OnTooltipSetUnit(self)
		local _, unit = self:GetUnit()
		if (not unit) then return end

		--	Analyzing --
		local nameLine, guildLine, detailLine, lootLine

		for i = 1, self:NumLines() do
			line = _G[self:GetName() .. 'TextLeft' .. i]
			text = line:GetText()

			if text then
				if (i == 1) then
					nameLine = line
				elseif strfind(text, UNIT_LEVEL_TEMPLATE) or strfind(text, UNIT_LETHAL_LEVEL_TEMPLATE) then
					if (i > 2) then
						guildLine = _G[self:GetName() .. 'TextLeft' .. (i - 1)]
					end
					detailLine = line
				elseif strfind(text, LOOT .. ':') then
					lootLine = line
				end
			end
		end

		-- Get Color --
		local defaultColor = '|cffffeeaa'
		local unitColor = GetUnitColor(unit)

		-- Name Mod --
		if nameLine then
			local unitName, unitRealm = UnitName(unit)
			local unitRelation = UnitRealmRelationship(unit)

			if CTipModDB['UnitTitle'] and UnitPVPName(unit) then
				unitName = UnitPVPName(unit)
			end

			if CTipModDB['UnitStatus'] then
				if UnitIsAFK(unit) then
					unitName = '<' .. AFK .. '>' .. unitName
				elseif UnitIsDND(unit) then
					unitName = '<' .. DND .. '>' .. unitName
				end
			end

			if unitRealm and (unitRealm ~= '') then
				if CTipModDB['UnitRealm'] then
					nameLine:SetText(unitColor .. unitName .. ' (' .. unitRealm .. ')')
				else
					if (unitRelation == LE_REALM_RELATION_VIRTUAL) then
						nameLine:SetText(unitColor .. unitName .. INTERACTIVE_SERVER_LABEL)
					else
						nameLine:SetText(unitColor .. unitName .. FOREIGN_SERVER_LABEL)
					end
				end
			else
				nameLine:SetText(unitColor .. unitName)
			end
		end

		-- Guild Mod --
		if guildLine then
			if UnitIsPlayer(unit) then
				local guildName, guildRank = GetGuildInfo(unit)
				if not guildName then return end

				if CTipModDB['GuildRank'] and guildRank then
					guildLine:SetText(unitColor .. '<' .. guildName .. '> |cff888888' .. guildRank)
				else
					guildLine:SetText(unitColor .. '<' .. guildName .. '>')
				end
			else
				local text = gsub(guildLine:GetText(), '-.+\'s', '\'s')
				guildLine:SetText(unitColor .. '<' .. text .. '>')
			end
		end

		-- Detail Mod --
		if detailLine then
			-- Unit Level --
			local unitLevel, levelColor

			if UnitIsWildBattlePet(unit) or UnitIsBattlePetCompanion(unit) then
				unitLevel = UnitBattlePetLevel(unit)
			else
				unitLevel = UnitLevel(unit)
			end

			if (unitLevel == -1) then unitLevel = '??' end

			if UnitCanAttack(unit, 'player') then
				levelColor = GetLevelColor(unitLevel)
			else
				levelColor = defaultColor
			end

			unitLevel = levelColor .. 'L' .. unitLevel

			-- Unit Detail --
			local unitDetail

			if UnitIsPlayer(unit) then
				local unitRace = UnitRace(unit)
				local classColor, className = GetClassColor(unit)

				if CTipModDB['TipColor'] and CTipModDB['ClassColor'] then
					className = ''
				end

				if CTipModDB['UnitGender'] then
					local unitGender = {'', MALE, FEMALE}
					unitDetail = defaultColor .. unitGender[UnitSex(unit)] .. ' ' .. unitRace .. ' ' .. classColor .. className
				else
					unitDetail = defaultColor .. unitRace .. ' ' .. classColor .. className
				end
			else
				local creatureClass, creatureType

				if UnitIsWildBattlePet(unit) or UnitIsBattlePetCompanion(unit) then
					creatureType = UnitBattlePetType(unit)
					creatureType = PET_TYPE_SUFFIX[creatureType]

					creatureClass = ' (' .. PET .. ')'
				else
					creatureType = UnitCreatureType(unit)
					if (not creatureType) or (creatureType == 'Not specified') then
						creatureType = ''
					end

					creatureClass = UnitClassification(unit)
					if creatureClass then
						if (creatureClass == 'elite') or (creatureClass == 'rareelite') then
							unitLevel = unitLevel .. '+'
						end

						if (creatureClass == 'rare') or (creatureClass == 'rareelite') then
							creatureClass = ' |cffff66ff(' .. ITEM_QUALITY3_DESC ..')'
						elseif (creatureClass == 'worldboss') then
							creatureClass = ' |cffff0000(' .. BOSS ..')'
						else
							creatureClass = ''
						end
					end
				end

				unitDetail = defaultColor .. creatureType .. creatureClass
			end

			detailLine:SetText(unitLevel .. ' ' .. unitDetail)
		end

		-- Loot Mod --
		if lootLine then
			local ownerName = strmatch(lootLine:GetText(), '%s([^%-]+)')
			if (not ownerName) or (ownerName == '') then return end

			local ownerColor = '|cffffffff'
			if (UnitName('player') == ownerName) then
				ownerColor = GetClassColor('player')
			else
				local groupType = 'party'
				if UnitInRaid('player') then
					groupType = 'raid'
				end

				for i = 1, GetNumGroupMembers() - 1 do
					local owner = groupType .. i
					if (UnitName(owner) == ownerName) then
						ownerColor = GetClassColor(owner)
						break
					end
				end
			end

			lootLine:SetText(defaultColor .. LOOT .. ': ' .. ownerColor .. ownerName)
		end

		-- Target of Target --
		local targetUnit = unit .. 'target'
		if CTipModDB['TargetOfTarget'] and UnitExists(targetUnit) then
			local targetName, targetColor

			if UnitIsUnit(targetUnit, 'player') then
				if UnitCanAttack(unit, 'player') then
					targetColor = '|cffcc4c38'
				else
					targetColor = '|cff009919'
				end

				targetName = '<' .. string.upper(YOU) .. '>'
			else
				if UnitIsPlayer(targetUnit) then
					targetColor = GetClassColor(targetUnit)
				else
					local r, g, b = GameTooltip_UnitColor(targetUnit)
					targetColor = string.format('|cff%.2x%.2x%.2x', r * 255, g * 255, b * 255)
				end

				targetName = UnitName(targetUnit)
			end

			self:AddLine(defaultColor .. TARGET .. ': ' .. targetColor .. targetName)
		end

		self:Show()
	end
	GameTooltip:HookScript('OnTooltipSetUnit', OnTooltipSetUnit)
end


--- CTipMod Handler ---
local function CTipMod_Handler()
	if CTipModDB['HideHealth'] then
		GameTooltipStatusBar:SetStatusBarTexture('')
	else
		GameTooltipStatusBar:SetStatusBarTexture('Interface\\TargetingFrame\\UI-TargetingFrame-BarFill')
	end

	GameTooltip:SetScale(CTipModDB['TipScale'])
	ItemRefTooltip:SetScale(CTipModDB['TipScale'])
end


--- CTipMod Loaded ---
function CTipMod_OnLoad(self)
	self:RegisterEvent('PLAYER_LOGIN')
end


--- CTipMod Events ---
function CTipMod_OnEvent(self, event, ...)
	if (event == 'PLAYER_LOGIN') then
		CTipModDB_Init()
		CTipModUI_Load()

		CTipMod_Hooks()
		CTipMod_Handler()
	end
end


--- Load Configuration ---
function CTipModUI_Load()
	CTipModUI_MouseAnchor:SetChecked(CTipModDB['MouseAnchor'])

	CTipModUI_TipColor:SetChecked(CTipModDB['TipColor'])
	CTipModUI_ClassColor:SetChecked(CTipModDB['ClassColor'])
	CTipModUI_HideHealth:SetChecked(CTipModDB['HideHealth'])
	CTipModUI_HideBorder:SetChecked(CTipModDB['HideBorder'])

	CTipModUI_TipScale:SetValue(CTipModDB['TipScale'] or 1)

	CTipModUI_UnitTitle:SetChecked(CTipModDB['UnitTitle'])
	CTipModUI_UnitGender:SetChecked(CTipModDB['UnitGender'])
	CTipModUI_UnitStatus:SetChecked(CTipModDB['UnitStatus'])
	CTipModUI_UnitRealm:SetChecked(CTipModDB['UnitRealm'])
	CTipModUI_GuildRank:SetChecked(CTipModDB['GuildRank'])

	CTipModUI_TargetOfTarget:SetChecked(CTipModDB['TargetOfTarget'])
	CTipModUI_TradeGoodsInfo:SetChecked(CTipModDB['TradeGoodsInfo'])
end


--- Save Configuration ---
function CTipModUI_Save()
	CTipModDB['MouseAnchor'] = CTipModUI_MouseAnchor:GetChecked()

	CTipModDB['TipColor'] = CTipModUI_TipColor:GetChecked()
	CTipModDB['ClassColor'] = CTipModUI_ClassColor:GetChecked()
	CTipModDB['HideHealth'] = CTipModUI_HideHealth:GetChecked()
	CTipModDB['HideBorder'] = CTipModUI_HideBorder:GetChecked()

	CTipModDB['TipScale'] = CTipModUI_TipScale:GetValue() or 1

	CTipModDB['UnitTitle'] = CTipModUI_UnitTitle:GetChecked()
	CTipModDB['UnitGender'] = CTipModUI_UnitGender:GetChecked()
	CTipModDB['UnitStatus'] = CTipModUI_UnitStatus:GetChecked()
	CTipModDB['UnitRealm'] = CTipModUI_UnitRealm:GetChecked()
	CTipModDB['GuildRank'] = CTipModUI_GuildRank:GetChecked()

	CTipModDB['TargetOfTarget'] = CTipModUI_TargetOfTarget:GetChecked()
	CTipModDB['TradeGoodsInfo'] = CTipModUI_TradeGoodsInfo:GetChecked()
end


--- ConfigUI Loaded ---
function CTipModUI_OnLoad(self)
	-- Register Option Panel --
	self.name, self.title, self.note = GetAddOnInfo('CloudyTooltipMod')
	self.cancel = function()
		CTipModUI_Load()
	end
	self.okay = function()
		CTipModUI_Save()
		CTipMod_Handler()
	end
	InterfaceOptions_AddCategory(self)

	-- Set ConfigUI Text --
	CTipModUITitle:SetText(self.title)
	CTipModUISubText:SetText(self.note)

	CTipModUI_MouseAnchorText:SetText('Anchor to Mouse')

	CTipModUI_TipColorText:SetText('Colorize Tooltip')
	CTipModUI_ClassColorText:SetText('Class color priority')
	CTipModUI_HideHealthText:SetText('Hide Health Bar')
	CTipModUI_HideBorderText:SetText('Hide Tooltip Border')

	CTipModUI_UnitTitleText:SetText('Player Title')
	CTipModUI_UnitGenderText:SetText('Player Gender')
	CTipModUI_UnitStatusText:SetText('Player Status')
	CTipModUI_UnitRealmText:SetText('Player Realm')
	CTipModUI_GuildRankText:SetText('Guild Rank')

	CTipModUI_TargetOfTargetText:SetText('Target of Target')
	CTipModUI_TradeGoodsInfoText:SetText('Trade Goods info')
end
