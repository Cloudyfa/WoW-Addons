--[[
	Cloudy Unit Info
	Copyright (c) 2019, Cloudyfa
	All rights reserved.
]]


--- Variables ---
local currentUNIT, currentGUID
local GearDB, SpecDB, ItemDB, SlotDB = {}, {}, {}, {}

local prefixColor = '|cffffeeaa'
local detailColor = '|cffffffff'
local lvlPattern1 = ITEM_LEVEL:gsub('%%d', '(%%d+)')
local lvlPattern2 = ITEM_LEVEL_ALT:gsub('([()])', '%%%1'):gsub('%%d', '(%%d+)')
local furySpec = GetSpecializationNameForSpecID(72)


--- Create Frame ---
local f = CreateFrame('Frame', 'CloudyUnitInfo')
f:RegisterEvent('UNIT_INVENTORY_CHANGED')


--- Set Unit Info ---
local function SetUnitInfo(gear, spec)
	if (not gear) then return end

	local _, unit = GameTooltip:GetUnit()
	if (not unit) or (UnitGUID(unit) ~= currentGUID) then return end
	if UnitLevel(unit) < 10 then
		spec = STAT_AVERAGE_ITEM_LEVEL
	elseif (not spec) then
		spec = CONTINUED
	end

	local infoLine
	for i = 2, GameTooltip:NumLines() do
		local line = _G['GameTooltipTextLeft' .. i]
		if line and line:IsShown() then
			local text = line:GetText() or ''
			if (text == CONTINUED) or strfind(text, spec .. ': ', 1, true) then
				infoLine = line
				break
			end
		end
	end

	local infoString = CONTINUED
	if (spec ~= CONTINUED) then
		infoString = prefixColor .. spec .. ': ' .. detailColor .. gear
	end

	if infoLine then
		infoLine:SetText(infoString)
	else
		GameTooltip:AddLine(infoString)
	end
	GameTooltip:Show()
end


--- PVP Item Detect ---
local function IsPVPItem(link)
	local itemStats = GetItemStats(link)

	for stat in pairs(itemStats) do
		if (stat == 'ITEM_MOD_RESILIENCE_RATING_SHORT') or (stat == 'ITEM_MOD_PVP_POWER_SHORT') then
			return true
		end
	end

	return false
end


--- Inventory Slots ---
local InvSlots = {}
for i = 1, 17 do
	if i ~= 4 then
		tinsert(InvSlots, i)
	end
end


--- Scan Item Level ---
for _, i in pairs(InvSlots) do
	local scanTip = CreateFrame('GameTooltip', 'CUnitScan' .. i, nil, 'GameTooltipTemplate')
	scanTip:SetOwner(WorldFrame, 'ANCHOR_NONE')
 	scanTip:SetScript('OnTooltipSetItem', function(self)
		local _, link = self:GetItem()
		if link then
			local name = self:GetName()
			for i = 2, self:NumLines() do
				local line = _G[name .. 'TextLeft' .. i]
				local text = line and line:GetText()
				if text then
					local level = text:match(lvlPattern1) or text:match(lvlPattern2)
					if level then
						ItemDB[link] = tonumber(level)
						break
					end
				end
			end
		end
	end)
	SlotDB[i] = scanTip
end

--- Unit Gear Info ---
local function UnitGear(unit)
	if (not unit) or (UnitGUID(unit) ~= currentGUID) then return end

	local ulvl = UnitLevel(unit)
	local class = select(2, UnitClass(unit))

	local boa, pvp = 0, 0
	local wlvl, wslot = 0, 0
	local ilvl, total, delay = nil, 0, nil

	for _, i in pairs(InvSlots) do
		local hasItem = GetInventoryItemTexture(unit, i)
		if hasItem then
			local link = GetInventoryItemLink(unit, i)
			if (not link) then
				delay = true
			else
				SlotDB[i]:SetInventoryItem(unit, i)
				local _, _, rarity, level, _, _, _, _, slot = GetItemInfo(link)
				level = ItemDB[link] or level
				if (not rarity) or (not level) then
					delay = true
				else
					if (rarity == 6) and (i == 16 or i == 17) then
						local relics = {select(4, strsplit(':', link))}
						for i = 1, 3 do
							local relicID = relics[i] ~= '' and relics[i]
							local relicLink = select(2, GetItemGem(link, i))
							if relicID and (not relicLink) then
								delay = true
								break
							end
						end
					elseif (rarity == 7) then
						boa = boa + 1
					else
						if IsPVPItem(link) then
							pvp = pvp + 1
						end
					end

					if (i == 16) then
						if (SpecDB[currentGUID] == furySpec) or (rarity == 6) then
							wlvl = level
							wslot = slot
						end
						if (slot == 'INVTYPE_2HWEAPON') or (slot == 'INVTYPE_RANGED') or ((slot == 'INVTYPE_RANGEDRIGHT') and (class == 'HUNTER')) then
							level = level * 2
						end
					end

					if (i == 17) then
						if (SpecDB[currentGUID] == furySpec) then
							if (wslot ~= 'INVTYPE_2HWEAPON') and (slot == 'INVTYPE_2HWEAPON') then
								if (level > wlvl) then
									level = level * 2 - wlvl
								end
							elseif (wslot == 'INVTYPE_2HWEAPON') then
								if (level > wlvl) then
									if (slot == 'INVTYPE_2HWEAPON') then
										level = level * 2 - wlvl * 2
									else
										level = level - wlvl
									end
								else
									level = 0
								end
							end
						elseif (rarity == 6) and wlvl then
							if level > wlvl then
								level = level * 2 - wlvl
							else
								level = wlvl
							end
						end
					end

					total = total + level
				end
			end
		end
	end

	if (not delay) then
		if (unit == 'player') and (GetAverageItemLevel() > 0) then
			ilvl = select(2, GetAverageItemLevel())
		else
			ilvl = total / 16
		end
		if (ilvl > 0) then ilvl = string.format('%.1f', ilvl) end

		if (boa > 0) then ilvl = ilvl .. '  |cffe6cc80' .. boa .. ' BOA' end
		if (pvp > 0) then ilvl = ilvl .. '  |cffa335ee' .. pvp .. ' PVP' end
	end
	return ilvl
end


--- Unit Specialization ---
local function UnitSpec(unit)
	if (not unit) or (UnitGUID(unit) ~= currentGUID) then return end

	local specName
	if (unit == 'player') then
		local specIndex = GetSpecialization()
		if specIndex then
			specName = select(2, GetSpecializationInfo(specIndex))
		end
	else
		local specID = GetInspectSpecialization(unit)
		if specID and (specID > 0) then
			specName = GetSpecializationNameForSpecID(specID)
		end
	end

	return specName
end


--- Scan Current Unit ---
local function ScanUnit(unit, forced)
	local cachedGear, cachedSpec

	if UnitIsUnit(unit, 'player') then
		cachedSpec = UnitSpec('player')
		cachedGear = UnitGear('player')

		SetUnitInfo(cachedGear or CONTINUED, cachedSpec)
	else
		if (not unit) or (UnitGUID(unit) ~= currentGUID) then return end

		cachedSpec = SpecDB[currentGUID]
		cachedGear = GearDB[currentGUID]

		if cachedGear or forced then
			SetUnitInfo(cachedGear, cachedSpec)
		end

		if not (IsShiftKeyDown() or forced) then
			if cachedGear and cachedSpec then return end
			if UnitAffectingCombat('player') then return end
		end

		if (not UnitIsVisible(unit)) then return end
		if UnitIsDeadOrGhost('player') or UnitOnTaxi('player') then return end
		if InspectFrame and InspectFrame:IsShown() then return end

		SetUnitInfo(CONTINUED, cachedSpec)

		local lastRequest = GetTime() - (f.lastUpdate or 0)
		if (lastRequest >= 1.5) then
			f.nextUpdate = 0
		else
			f.nextUpdate = 1.5 - lastRequest
		end
		f:Show()
	end
end


--- Character Info Sheet ---
MIN_PLAYER_LEVEL_FOR_ITEM_LEVEL_DISPLAY = 1
hooksecurefunc('PaperDollFrame_SetItemLevel', function(frame, unit)
	if (unit ~= 'player') then return end

	local total, equip = GetAverageItemLevel()
	if (total > 0) then total = string.format('%.1f', total) end
	if (equip > 0) then equip = string.format('%.1f', equip) end

	local ilvl = equip
	if (equip ~= total) then
		ilvl = equip .. ' / ' .. total
	end
	frame.Value:SetText(ilvl)
end)


--- Handle Events ---
f:SetScript('OnEvent', function(self, event, ...)
	if (event == 'UNIT_INVENTORY_CHANGED') then
		local unit = ...
		if (UnitGUID(unit) == currentGUID) then
			ScanUnit(unit, true)
		end
	elseif (event == 'INSPECT_READY') then
		local guid = ...
		if (guid == currentGUID) then
			local spec = UnitSpec(currentUNIT)
			SpecDB[guid] = spec

			local gear = UnitGear(currentUNIT)
			GearDB[guid] = gear

			if (not gear) or (not spec) then
				ScanUnit(currentUNIT, true)
			else
				SetUnitInfo(gear, spec)
			end
		end
		self:UnregisterEvent('INSPECT_READY')
	end
end)

f:SetScript('OnUpdate', function(self, elapsed)
	self.nextUpdate = (self.nextUpdate or 0) - elapsed
	if (self.nextUpdate > 0) then return end

	self:Hide()
	ClearInspectPlayer()

	if currentUNIT and (UnitGUID(currentUNIT) == currentGUID) then
		self.lastUpdate = GetTime()
		self:RegisterEvent('INSPECT_READY')
		NotifyInspect(currentUNIT)
	end
end)

GameTooltip:HookScript('OnTooltipSetUnit', function(self)
	local _, unit = self:GetUnit()
	if (not unit) or (not CanInspect(unit)) then return end

	currentUNIT, currentGUID = unit, UnitGUID(unit)
	ScanUnit(unit)
end)
