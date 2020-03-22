--[[
	Cloudy Tooltip Mod
	Copyright (c) 2020, Cloudyfa
	All rights reserved.
]]


--- Initialization ---
local function CTipModDB_Init()
	-- Create new DB if needed --
	if (not CTipModDB) then
		CTipModDB = {}

		-- Default configuration --
		CTipModDB['MouseAnchor'] = 1
		CTipModDB['MousePos'] = 3
		CTipModDB['OverlayAnchor'] = nil

		CTipModDB['TipColor'] = 1
		CTipModDB['ClassColor'] = 1
		CTipModDB['HideHealth'] = nil
		CTipModDB['HideBorder'] = nil
		CTipModDB['HidePVP'] = nil

		CTipModDB['TipScale'] = 1

		CTipModDB['UnitTitle'] = nil
		CTipModDB['UnitGender'] = 1
		CTipModDB['UnitStatus'] = nil
		CTipModDB['UnitRealm'] = 1
		CTipModDB['RealmLabel'] = 1
		CTipModDB['GuildRank'] = nil

		CTipModDB['TargetOfTarget'] = 1
		CTipModDB['VendorPrice'] = 1
		CTipModDB['FactionIcon'] = nil
		CTipModDB['LinkIcon'] = 1
	end
	if (not CTipModPOS) then CTipModPOS = {} end

	-- DropDownMenu Init --
	UIDropDownMenu_Initialize(CTipModUI_MousePos, CTipPos_Init)
	UIDropDownMenu_SetSelectedValue(CTipModUI_MousePos, CTipModDB['MousePos'] or 3)

	-- Change tooltip style --
	CTipBackdrop = GameTooltip:GetBackdrop()
	CTipBackdrop.insets = {left = 2, right = 2, top = 2, bottom = 2}
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

		tooltip:SetBackdrop(CTipBackdrop)
		tooltip:SetBackdropColor(r * 0.2, g * 0.2, b * 0.2)
		tooltip:SetBackdropBorderColor(r  * 1.2, g * 1.2, b * 1.2)
	end

	-- Get Anchor Position --
	local function getPosition(self)
		local point, _, relative, xOffset, yOffset = self:GetPoint()
		if (point == 'LEFT') or (point == 'RIGHT') then
			if (yOffset > 0) then
				point = 'TOP' .. point
				yOffset = yOffset + 35
			else
				point = 'BOTTOM' .. point
				yOffset = yOffset - 35
			end
		elseif (point == 'TOP') or (point == 'BOTTOM') then
			if (xOffset < 0) then
				point = point .. 'LEFT'
				xOffset = xOffset - 85
			else
				point = point .. 'RIGHT'
				xOffset = xOffset + 85
			end
		elseif (point == 'CENTER') then
			if (yOffset > 0) and (xOffset < 0) then
				point = 'TOPLEFT'
				xOffset = xOffset - 85
				yOffset = yOffset + 35
			elseif (yOffset > 0) and (xOffset >= 0) then
				point = 'TOPRIGHT'
				xOffset = xOffset + 85
				yOffset = yOffset + 35
			elseif (yOffset <= 0) and (xOffset < 0) then
				point = 'BOTTOMLEFT'
				xOffset = xOffset - 85
				yOffset = yOffset - 35
			elseif (yOffset <= 0) and (xOffset >= 0) then
				point = 'BOTTOMRIGHT'
				xOffset = xOffset + 85
				yOffset = yOffset - 35
			end
		end
		return point, relative, xOffset, yOffset
	end

	-- Tooltip Anchor Frame --
	local TipAnchor = CreateFrame('Frame', 'CTipAnchor', UIParent)
	TipAnchor:SetFrameStrata('TOOLTIP')
	TipAnchor:SetClampedToScreen(true)
	TipAnchor:SetMovable(true)
	TipAnchor:SetSize(170, 70)
	TipAnchor:Hide()

	TipAnchor.bg = TipAnchor:CreateTexture()
	TipAnchor.bg:SetAllPoints(true)
	TipAnchor.bg:SetColorTexture(0.2, 0.4, 0.6, 0.5)

	TipAnchor.text = TipAnchor:CreateFontString(nil, 'ARTWORK', 'GameFontHighlightLarge')
	TipAnchor.text:SetPoint('CENTER')
	TipAnchor.text:SetText('CTipMod')

	if CTipModPOS and (#CTipModPOS ~= 0) then
		TipAnchor:SetPoint(CTipModPOS[1], UIParent, CTipModPOS[2], CTipModPOS[3], CTipModPOS[4])
	else
		TipAnchor:SetPoint('BOTTOMRIGHT', 0, 8)
	end

	TipAnchor:SetScript('OnMouseDown', function(self)
		self:StartMoving()
	end)
	TipAnchor:SetScript('OnMouseUp', function(self)
		self:StopMovingOrSizing()
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
				if (CTipModDB['MousePos'] == 2) then
					self:SetOwner(parent, 'ANCHOR_CURSOR_LEFT')
				elseif (CTipModDB['MousePos'] == 3) then
					self:SetOwner(parent, 'ANCHOR_CURSOR_RIGHT')
				else
					self:SetOwner(parent, 'ANCHOR_CURSOR')
				end
			end
		elseif CTipModDB['OverlayAnchor'] then
			self:ClearAllPoints()
			if CTipModPOS and (#CTipModPOS ~= 0) then
				self:SetPoint(CTipModPOS[1], UIParent, CTipModPOS[2], CTipModPOS[3], CTipModPOS[4])
			else
				self:SetPoint('BOTTOMRIGHT', 0, 8)
			end
		end
	end)

	-- Tooltip Color --
	local function OnTooltipShow(self)
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
	end
	GameTooltip:HookScript('OnShow', OnTooltipShow)
	GameTooltip:HookScript('OnUpdate', OnTooltipShow)

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
				local _, link = tooltip:GetItem()
				local color = link and strmatch(link, '(|c%x+)')
				ColorTooltip(tooltip, color)
				tooltip:SetScale(CTipModDB['TipScale'])
			end
		end
	end)

	-- Modify Item Tooltip --
	local function OnTooltipSetItem(self)
		if (not CTipModDB['VendorPrice']) then return end

		local _, link = self:GetItem()
		if (not link) then return end

		local price = select(11, GetItemInfo(link))
		if (not self.shownMoneyFrames) and price and (price > 0) then
			local container = GetMouseFocus()
			local quantity = container and container.count and tonumber(container.count) or 1
			SetTooltipMoney(self, price * quantity, 'STATIC', SELL_PRICE .. ':')
		end
	end
	GameTooltip:HookScript('OnTooltipSetItem', OnTooltipSetItem)
	ItemRefTooltip:HookScript('OnTooltipSetItem', OnTooltipSetItem)

	-- Modify Unit Tooltip --
	local function OnTooltipSetUnit(self)
		local _, unit = self:GetUnit()
		if (not unit) then return end

		-- Analyzing --
		local nameLine, guildLine, detailLine, lootLine, hasGuild

		if UnitIsPlayer(unit) and GetGuildInfo(unit) then
			hasGuild = true
			self:AddLine(GUILD)
		end

		for i = 1, self:NumLines() do
			local line = _G[self:GetName() .. 'TextLeft' .. i]
			local text = line:GetText()

			if text then
				if (i == 1) then
					nameLine = line
				elseif strfind(text, UNIT_LEVEL_TEMPLATE) or strfind(text, UNIT_LETHAL_LEVEL_TEMPLATE) then
					if hasGuild then
						guildLine = line
						detailLine = _G[self:GetName() .. 'TextLeft' .. self:NumLines()]
					else
						if (i > 2) then
							guildLine = _G[self:GetName() .. 'TextLeft' .. (i - 1)]
						end
						detailLine = line
					end
				elseif strfind(text, LOOT .. ':') then
					lootLine = line
				elseif strfind(text, TARGET .. ':') then
					line:Hide()
				elseif (text == PVP) then
					line:Hide()
				elseif (text == FACTION_ALLIANCE) or (text == FACTION_HORDE) then
					if CTipModDB['FactionIcon'] then
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
			local unitLevel, levelColor = UnitLevel(unit), defaultColor

			if (unitLevel == -1) then unitLevel = '??' end
			if UnitCanAttack(unit, 'player') then
				levelColor = GetLevelColor(unitLevel)
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
		local faction = UnitFactionGroup(unit)
		if CTipModDB['FactionIcon'] and faction then
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
				self.icon:SetAlpha(0.55)
			else
				nameLine:SetWidth(nameLine:GetWidth() + 7)
				self.icon:SetPoint('TOPRIGHT', 10, 7)
				self.icon:SetAlpha(0.75)
			end
			self.icon:Show()
		end

		-- Cleanup Tooltip --
		for i = 1, self:NumLines() do
			local line = _G['GameTooltipTextLeft' .. i]
			local text = _G['GameTooltipTextRight' .. i]
			if line and not line:IsShown() then
				line:SetText(nil)
				text:SetText(nil)
				for j = i + 1, self:NumLines() do
					local nline = _G['GameTooltipTextLeft' .. j]
					local ntext = _G['GameTooltipTextRight' .. j]
					if nline and nline:IsShown() then
						local textL = nline:GetText()
						local textR = ntext:GetText()
						if textL then
							line:SetText(textL)
							line:Show()
							nline:SetText(nil)
							nline:Hide()
							if textR then
								text:SetText(textR)
								text:Show()
								ntext:SetText(nil)
								ntext:Hide()
							end
							break
						end
					end
				end
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
		if CTipEdgeSize > 13 then
			CTipBackdrop.edgeSize = 13
		else
			CTipBackdrop.edgeSize = CTipEdgeSize
		end
	end

	GameTooltip:SetScale(CTipModDB['TipScale'])
	ItemRefTooltip:SetScale(CTipModDB['TipScale'])
end


--- CTipPos Init ---
function CTipPos_Init()
	local selectedValue = UIDropDownMenu_GetSelectedValue(CTipModUI_MousePos)
	local info = UIDropDownMenu_CreateInfo()
	local items = {'Center', 'Left', 'Right'}

	for i, opt in pairs(items) do
		info.text, info.value = opt, i
		info.checked = (selectedValue == i)
		info.func = function()
			CTipModDB['MousePos'] = i
			UIDropDownMenu_SetSelectedValue(CTipModUI_MousePos, i)
		end
		UIDropDownMenu_AddButton(info)
	end
end


--- Load Configuration ---
local function CTipModUI_Load()
	CTipModUI_MouseAnchor:SetChecked(CTipModDB['MouseAnchor'])
	CTipModUI_OverlayAnchor:SetChecked(CTipModDB['OverlayAnchor'])

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
	CTipModUI_VendorPrice:SetChecked(CTipModDB['VendorPrice'])
	CTipModUI_FactionIcon:SetChecked(CTipModDB['FactionIcon'])
	CTipModUI_LinkIcon:SetChecked(CTipModDB['LinkIcon'])
end


--- Save Configuration ---
local function CTipModUI_Save()
	CTipModDB['MouseAnchor'] = CTipModUI_MouseAnchor:GetChecked()
	CTipModDB['OverlayAnchor'] = CTipModUI_OverlayAnchor:GetChecked()

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
	CTipModDB['VendorPrice'] = CTipModUI_VendorPrice:GetChecked()
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
	self:RegisterEvent('PLAYER_LOGIN')

	-- Set ConfigUI Text --
	CTipModUITitle:SetText(self.title)
	CTipModUISubText:SetText(self.note)

	CTipModUI_MouseAnchorText:SetText('Anchor to Mouse')
	CTipModUI_OverlayAnchorText:SetText('Anchor to Overlay')

	CTipModUI_TipColorText:SetText('Colorize tooltip')
	CTipModUI_ClassColorText:SetText('Class color priority')
	CTipModUI_HideHealthText:SetText('Hide health bar')
	CTipModUI_HideBorderText:SetText('Hide tooltip border')
	CTipModUI_HidePVPText:SetText('Hide in combat')

	CTipModUI_UnitTitleText:SetText('Player title')
	CTipModUI_UnitGenderText:SetText('Player gender')
	CTipModUI_UnitStatusText:SetText('Player status')
	CTipModUI_UnitRealmText:SetText('Player realm')
	CTipModUI_RealmLabelText:SetText('Use realm label')
	CTipModUI_GuildRankText:SetText('Guild rank')

	CTipModUI_TargetOfTargetText:SetText('Target of Target')
	CTipModUI_VendorPriceText:SetText('Vendor price')
	CTipModUI_FactionIconText:SetText('Faction icon')
	CTipModUI_LinkIconText:SetText('Link icon')
end


--- CTipMod Events ---
function CTipModUI_OnEvent(self, event, ...)
	if (event == 'PLAYER_LOGIN') then
		CTipModDB_Init()
		CTipModUI_Load()
		CTipMod_Hooks()
		CTipMod_Handler()

		self:UnregisterEvent(event)
	end
end
