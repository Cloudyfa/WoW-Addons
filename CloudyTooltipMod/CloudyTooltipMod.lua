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
		CTipModDB['OffsetAnchor'] = nil

		CTipModDB['TipColor'] = nil
		CTipModDB['ClassColor'] = 1
		CTipModDB['HideHealth'] = nil
		CTipModDB['HideBorder'] = 1
		CTipModDB['HidePVP'] = nil

		CTipModDB['TipScale'] = 1

		CTipModDB['UnitTitle'] = nil
		CTipModDB['UnitGender'] = 1
		CTipModDB['UnitStatus'] = nil
		CTipModDB['UnitRealm'] = nil
		CTipModDB['RealmLabel'] = 1
		CTipModDB['GuildRank'] = nil

		CTipModDB['TargetOfTarget'] = 1
		CTipModDB['TradeGoodsInfo'] = 1
		CTipModDB['FactionIcon'] = 1
		CTipModDB['LinkIcon'] = 1
	end
	if (not CTipModPOS) then CTipModPOS = {} end

	-- Change tooltip style --
	CTipBackdrop = GameTooltip:GetBackdrop()
	CTipBackdrop.insets = {left = 2, right = 2, top = 2, bottom = 2}
	CTipBackdrop.edgeFile = 'Interface\\Tooltips\\UI-Tooltip-Border'
	CTipEdgeSize = CTipBackdrop.edgeSize
	GameTooltipStatusBar:SetHeight(5)
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
			if CTipModDB['ClassColor'] then
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
		local r, g, b = 0.65, 0.65, 0.65
		if CTipModDB['TipColor'] then
			if color and (strlen(color) == 10) then
				r = tonumber(strsub(color, 5, 6), 16) / 255
				g = tonumber(strsub(color, 7, 8), 16) / 255
				b = tonumber(strsub(color, 9), 16) / 255
			end
		end

		tooltip:SetBackdropBorderColor(r  * 1.2, g * 1.2, b * 1.2)
		tooltip:SetBackdropColor(r * 0.2, g * 0.2, b * 0.2)
	end

	-- Get Anchor Position --
	local function getPosition(self)
		local point, _, relative, xOffset, yOffset = self:GetPoint()
		local anchor = point
		if point == 'LEFT' then
			anchor = yOffset > 0 and 'TOPLEFT' or 'BOTTOMLEFT'
		elseif point == 'RIGHT' then
			anchor = yOffset > 0 and 'TOPRIGHT' or 'BOTTOMRIGHT'
		elseif point == 'TOP' then
			anchor = xOffset < 0 and 'TOPLEFT' or 'TOPRIGHT'
		elseif point == 'BOTTOM' then
			anchor = xOffset < 0 and 'BOTTOMLEFT' or 'BOTTOMRIGHT'
		elseif point == 'CENTER' then
			if yOffset > 0 then
				anchor = xOffset < 0 and 'TOPLEFT' or 'TOPRIGHT'
			else
				anchor = xOffset < 0 and 'BOTTOMLEFT' or 'BOTTOMRIGHT'
			end
		end
		return point, relative, xOffset, yOffset, anchor
	end

	-- Set Anchor Position --
	local function setPosition(self)
		if CTipModPOS and (#CTipModPOS ~= 0) then
			self:SetPoint(CTipModPOS[1], UIParent, CTipModPOS[2], CTipModPOS[3], CTipModPOS[4])
		else
			self:SetPoint('BOTTOMRIGHT')
		end
	end

	-- Tooltip Anchor Frame --
	local TipAnchor = CreateFrame('Frame', 'CTipAnchor', UIParent)
	TipAnchor:SetFrameStrata('TOOLTIP')
	TipAnchor:SetClampedToScreen(true)
	TipAnchor:SetSize(170, 70)
	TipAnchor:EnableMouse(0)
	TipAnchor:Hide()

	TipAnchor.bg = TipAnchor:CreateTexture()
	TipAnchor.bg:SetAllPoints(TipAnchor)
	TipAnchor.bg:SetColorTexture(0.2, 0.4, 0.6, 0.5)

	TipAnchor.text = TipAnchor:CreateFontString(nil, 'ARTWORK', 'GameFontHighlightLarge')
	TipAnchor.text:SetPoint('CENTER')
	TipAnchor.text:SetText('CTipMod')

	TipAnchor:SetScript('OnMouseDown', function(self)
		self:SetMovable(true)
		self:StartMoving()
	end)
	TipAnchor:SetScript('OnMouseUp', function(self)
		self:StopMovingOrSizing()
		self:SetMovable(false)
		CTipModPOS = {getPosition(self)}
	end)


--- Hook Functions ---
local function CTipMod_Hooks()
	-- Tooltip Anchor --
	hooksecurefunc('GameTooltip_SetDefaultAnchor', function(self, parent)
		if CTipModDB['HidePVP'] and UnitAffectingCombat('player') then
			return self:Hide()
		end

		if CTipModDB['MouseAnchor'] then
			if (GetMouseFocus() == WorldFrame) then
				self:SetOwner(parent, 'ANCHOR_CURSOR')
			end
		elseif CTipModDB['OffsetAnchor'] then
			self:ClearAllPoints()
			if CTipModPOS and (#CTipModPOS ~= 0) then
				if strfind(CTipModPOS[5], 'BOTTOM', 1, true) then
					self:SetPoint(CTipModPOS[5], TipAnchor, CTipModPOS[5], 0, 8)
				else
					self:SetPoint(CTipModPOS[5], TipAnchor, CTipModPOS[5])
				end
			else
				self:SetPoint('BOTTOMRIGHT', 0, 8)
			end
		end
	end)

	-- Tooltip Color --
	GameTooltip:HookScript('OnUpdate', function(self)
		local color = nil
		local name, unit = self:GetUnit()
		if (not name) and (not unit) then
			if self:GetSpell() then
				color = '|cff71d5ff'
			else
				local _, link = self:GetItem()
				color = link and strmatch(link, '(|c%x+)')
			end
			ColorTooltip(self, color)
		else
			color = unit and GetUnitColor(unit)
			if color then
				ColorTooltip(self, color)
			end
		end
	end)

	-- Hyperlink Tooltip Color --
	hooksecurefunc('SetItemRef', function(str, link)
		local color = link and strmatch(link, '(|c%x+)')
		ColorTooltip(ItemRefTooltip, color)

		if CTipModDB['LinkIcon'] and _G['CTMIcon'] then
			local icon = nil
			local source, id = strmatch(str, '(%w+):(%d+)')
			if (source == 'item') then
				icon = GetItemIcon(id)
			elseif (source == 'spell') then
				icon = GetSpellTexture(id)
			elseif (source == 'achievement') then
				icon = select(10,GetAchievementInfo(id))
			end

			if icon then
				_G['CTMIcon'].texture:SetTexture(icon)
				_G['CTMIcon']:Show()
			else
				_G['CTMIcon'].texture:SetTexture(nil)
				_G['CTMIcon']:Hide()
			end
		end
	end)

	-- Comparison Tooltip Color --
	hooksecurefunc('GameTooltip_ShowCompareItem', function(self)
		if self and self.shoppingTooltips then
			for _, tooltip in pairs(self.shoppingTooltips) do
				tooltip:SetBackdrop(CTipBackdrop)
				tooltip:SetScale(CTipModDB['TipScale'])

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

		local itemType, subType = select(2, GetItemInfoInstant(id))
		if strfind(TRADESKILLS, itemType, 1, true) then
			self:AddLine(BAG_FILTER_TRADE_GOODS .. ': |cffaaff77' .. (subType or UNKNOWN))
		end
	end
	GameTooltip:HookScript('OnTooltipSetItem', OnTooltipSetItem)
	ItemRefTooltip:HookScript('OnTooltipSetItem', OnTooltipSetItem)

	-- Modify Unit Tooltip --
	local function OnTooltipSetUnit(self)
		local _, unit = self:GetUnit()
		if (not unit) then return end

		-- Analyzing --
		local nameLine, guildLine, detailLine, lootLine, faction

		for i = 1, self:NumLines() do
			local line = _G[self:GetName() .. 'TextLeft' .. i]
			local text = line:GetText()

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
				elseif strfind(text, TARGET .. ':') then
					line:Hide()
				elseif (text == PVP) then
					line:Hide()
				elseif (text == FACTION_ALLIANCE) or (text == FACTION_HORDE) then
					if CTipModDB['FactionIcon'] then
						faction = text
						line:Hide()
					end
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

			if CTipModDB['UnitRealm'] and unitRealm and (unitRealm ~= '') then
				if CTipModDB['RealmLabel'] then
					if (unitRelation == LE_REALM_RELATION_VIRTUAL) then
						nameLine:SetText(unitColor .. unitName .. INTERACTIVE_SERVER_LABEL)
					else
						nameLine:SetText(unitColor .. unitName .. FOREIGN_SERVER_LABEL)
					end
				else
					nameLine:SetText(unitColor .. unitName .. ' (' .. unitRealm .. ')')
				end
			else
				nameLine:SetText(unitColor .. unitName)
			end
		end

		-- Guild Mod --
		if guildLine then
			local guildString
			if UnitIsPlayer(unit) then
				local guildName, guildRank = GetGuildInfo(unit)
				if guildName then
					if CTipModDB['GuildRank'] and guildRank then
						guildString = '<' .. guildName .. '> |cff888888' .. guildRank
					else
						guildString = '<' .. guildName .. '>'
					end
				else
					guildString = '<' .. gsub(guildLine:GetText(), '-.+', '') .. '>'
				end
			else
				guildString = '<' .. gsub(guildLine:GetText(), '-.+\'s', '\'s') .. '>'
			end
			guildLine:SetText(unitColor .. guildString)
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

				if CTipModDB['ClassColor'] then
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
			if ownerName and (ownerName ~= '') then
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

		-- Faction Icon --
		if faction then
			if not self.icon then
				self.icon = self:CreateTexture(nil, 'ARTWORK')
				self.icon:SetSize(32, 32)
			end
			if (faction == FACTION_ALLIANCE) then
				self.icon:SetTexture('Interface\\Timer\\Alliance-Logo')
			elseif (faction == FACTION_HORDE) then
				self.icon:SetTexture('Interface\\Timer\\Horde-Logo')
			end

			if CTipModDB['HideBorder'] then
				nameLine:SetWidth(nameLine:GetWidth() + 15)
				self.icon:SetPoint('TOPRIGHT', 3, -1)
				self.icon:SetAlpha(0.65)
			else
				nameLine:SetWidth(nameLine:GetWidth() + 7)
				self.icon:SetPoint('TOPRIGHT', 10, 7)
				self.icon:SetAlpha(0.95)
			end
			self.icon:Show()
		end

		-- Cleanup Tooltip --
		for i = 1, self:NumLines() do
			local line = _G[self:GetName() .. 'TextLeft' .. i]
			local text = _G[self:GetName() .. 'TextRight' .. i]
			local nextline = _G[self:GetName() .. 'TextLeft' .. i + 1]

			if nextline and line and not line:IsShown() then
				if text then text:Hide() end
				nextline:SetPoint(line:GetPoint())
			end
		end
	end
	GameTooltip:HookScript('OnTooltipSetUnit', OnTooltipSetUnit)

	-- Clear Texture --
	GameTooltip:HookScript('OnTooltipCleared', function(self)
		if self.icon then
			self.icon:SetTexture(nil)
			self.icon:Hide()
		end
	end)
end


--- CTipMod Handler ---
local function CTipMod_Handler()
	if CTipModDB['LinkIcon'] then
		if not _G['CTMIcon'] then
			local icon = CreateFrame('Frame', 'CTMIcon', ItemRefTooltip)
			icon:SetPoint('TOPRIGHT', ItemRefTooltip, 'TOPLEFT', 0, -2)
			icon:SetSize(36,36)
			icon.texture = icon:CreateTexture(nil, 'BACKGROUND')
			icon.texture:SetAllPoints(icon)
			icon.texture:SetTexCoord(.08, .92, .08, .92)
		end
	else
		if _G['CTMIcon'] then
			_G['CTMIcon'].texture:SetTexture(nil)
			_G['CTMIcon']:Hide()
		end
	end

	if CTipModDB['HideHealth'] then
		GameTooltipStatusBar:SetStatusBarTexture('')
	else
		GameTooltipStatusBar:SetStatusBarTexture('Interface\\TargetingFrame\\UI-TargetingFrame-BarFill')
	end

	if CTipModDB['HideBorder'] then
		CTipBackdrop.edgeSize = 0.01
	else
		if CTipEdgeSize > 12 then
			CTipBackdrop.edgeSize = 12
		else
			CTipBackdrop.edgeSize = CTipEdgeSize
		end
	end
	GameTooltip:SetBackdrop(CTipBackdrop)
	ItemRefTooltip:SetBackdrop(CTipBackdrop)

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

		setPosition(TipAnchor)
	end
end


--- Load Configuration ---
function CTipModUI_Load()
	CTipModUI_MouseAnchor:SetChecked(CTipModDB['MouseAnchor'])
	CTipModUI_OffsetAnchor:SetChecked(CTipModDB['OffsetAnchor'])

	CTipModUI_TipColor:SetChecked(CTipModDB['TipColor'])
	CTipModUI_ClassColor:SetChecked(CTipModDB['ClassColor'])
	CTipModUI_HideHealth:SetChecked(CTipModDB['HideHealth'])
	CTipModUI_HideBorder:SetChecked(CTipModDB['HideBorder'])
	CTipModUI_HidePVP:SetChecked(CTipModDB['HidePVP'])

	CTipModUI_TipScale:SetValue(CTipModDB['TipScale'] or 1)

	CTipModUI_UnitTitle:SetChecked(CTipModDB['UnitTitle'])
	CTipModUI_UnitGender:SetChecked(CTipModDB['UnitGender'])
	CTipModUI_UnitStatus:SetChecked(CTipModDB['UnitStatus'])
	CTipModUI_UnitRealm:SetChecked(CTipModDB['UnitRealm'])
	CTipModUI_RealmLabel:SetChecked(CTipModDB['RealmLabel'])
	CTipModUI_GuildRank:SetChecked(CTipModDB['GuildRank'])

	CTipModUI_TargetOfTarget:SetChecked(CTipModDB['TargetOfTarget'])
	CTipModUI_TradeGoodsInfo:SetChecked(CTipModDB['TradeGoodsInfo'])
	CTipModUI_FactionIcon:SetChecked(CTipModDB['FactionIcon'])
	CTipModUI_LinkIcon:SetChecked(CTipModDB['LinkIcon'])
end


--- Save Configuration ---
function CTipModUI_Save()
	CTipModDB['MouseAnchor'] = CTipModUI_MouseAnchor:GetChecked()
	CTipModDB['OffsetAnchor'] = CTipModUI_OffsetAnchor:GetChecked()

	CTipModDB['TipColor'] = CTipModUI_TipColor:GetChecked()
	CTipModDB['ClassColor'] = CTipModUI_ClassColor:GetChecked()
	CTipModDB['HideHealth'] = CTipModUI_HideHealth:GetChecked()
	CTipModDB['HideBorder'] = CTipModUI_HideBorder:GetChecked()
	CTipModDB['HidePVP'] = CTipModUI_HidePVP:GetChecked()

	CTipModDB['TipScale'] = CTipModUI_TipScale:GetValue() or 1

	CTipModDB['UnitTitle'] = CTipModUI_UnitTitle:GetChecked()
	CTipModDB['UnitGender'] = CTipModUI_UnitGender:GetChecked()
	CTipModDB['UnitStatus'] = CTipModUI_UnitStatus:GetChecked()
	CTipModDB['UnitRealm'] = CTipModUI_UnitRealm:GetChecked()
	CTipModDB['RealmLabel'] = CTipModUI_RealmLabel:GetChecked()
	CTipModDB['GuildRank'] = CTipModUI_GuildRank:GetChecked()

	CTipModDB['TargetOfTarget'] = CTipModUI_TargetOfTarget:GetChecked()
	CTipModDB['TradeGoodsInfo'] = CTipModUI_TradeGoodsInfo:GetChecked()
	CTipModDB['FactionIcon'] = CTipModUI_FactionIcon:GetChecked()
	CTipModDB['LinkIcon'] = CTipModUI_LinkIcon:GetChecked()
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
	CTipModUI_OffsetAnchorText:SetText('Anchor to Offsets')

	CTipModUI_TipColorText:SetText('Colorize Tooltip')
	CTipModUI_ClassColorText:SetText('Class color priority')
	CTipModUI_HideHealthText:SetText('Hide Health Bar')
	CTipModUI_HideBorderText:SetText('Hide Tooltip Border')
	CTipModUI_HidePVPText:SetText('Hide in Combat')

	CTipModUI_UnitTitleText:SetText('Player Title')
	CTipModUI_UnitGenderText:SetText('Player Gender')
	CTipModUI_UnitStatusText:SetText('Player Status')
	CTipModUI_UnitRealmText:SetText('Player Realm')
	CTipModUI_RealmLabelText:SetText('Use realm label')
	CTipModUI_GuildRankText:SetText('Guild Rank')

	CTipModUI_TargetOfTargetText:SetText('Target of Target')
	CTipModUI_TradeGoodsInfoText:SetText('Trade Goods info')
	CTipModUI_FactionIconText:SetText('Faction Icon')
	CTipModUI_LinkIconText:SetText('Link Icon')
end
