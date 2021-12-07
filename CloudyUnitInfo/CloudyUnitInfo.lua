--[[
	Cloudy Unit Info
	Copyright (c) 2020, Cloudyfa
	All rights reserved.
]]


--- Variables ---
local currentUNIT, currentGUID
local GearDB, SpecDB = {}, {}
local prefixColor = '|cffffeeaa'
local detailColor = '|cffffffff'


--- Create Frame ---
local f = CreateFrame('Frame', 'CloudyUnitInfo')
f:RegisterEvent('UPDATE_MOUSEOVER_UNIT')
f:RegisterEvent('UNIT_INVENTORY_CHANGED')


--- Set Unit Info ---
local function SetUnitInfo(gear, spec)
	if (not gear) then return end

	local _, unit = GameTooltip:GetUnit()
	if (not unit) or (UnitGUID(unit) ~= currentGUID) then return end
	if UnitLevel(unit) <= 10 then
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


--- Unit Gear Info ---
local function UnitGear(unit)
	if (not unit) or (UnitGUID(unit) ~= currentGUID) then return end

	local boa, pvp = 0, 0
	local ilvl, delay = nil, nil

	for i = 1, 17 do
		if (i ~= 4) then
			local hasItem = GetInventoryItemTexture(unit, i)
			if hasItem then
				local link = GetInventoryItemLink(unit, i)
				if (not link) then
					delay = true
				else
					local _, _, rarity = GetItemInfo(link)
					if (not rarity) then
						delay = true
					else
						if (rarity == 7) then
							boa = boa + 1
						else
							if IsPVPItem(link) then
								pvp = pvp + 1
							end
						end
					end
				end
			end
		end
	end

	if (not delay) then
		if (unit == 'player') then
			ilvl = select(2, GetAverageItemLevel())
		else
			ilvl = C_PaperDollInfo.GetInspectItemLevel(unit)
		end
		ilvl = (ilvl > 0.5) and (ilvl - 0.5) or 0

		if (ilvl > 0) then ilvl = string.format('%.0f', ilvl) end
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
	total = (total > 0.5) and (total - 0.5) or 0
	equip = (equip > 0.5) and (equip - 0.5) or 0

	if (total > 0) then total = string.format('%.0f', total) end
	if (equip > 0) then equip = string.format('%.0f', equip) end

	local ilvl = equip
	if (equip ~= total) then
		ilvl = equip .. ' / ' .. total
	end
	frame.Value:SetText(ilvl)
end)


--- Handle Events ---
f:SetScript('OnEvent', function(self, event, ...)
	if (event == 'UPDATE_MOUSEOVER_UNIT') then
		local _, unit = GameTooltip:GetUnit()
		if (not unit) or (not CanInspect(unit)) then return end

		currentUNIT, currentGUID = unit, UnitGUID(unit)
		ScanUnit(unit)
	elseif (event == 'UNIT_INVENTORY_CHANGED') then
		local unit = ...
		if (UnitGUID(unit) == currentGUID) then
			ScanUnit(unit, true)
		end
	elseif (event == 'INSPECT_READY') then
		local guid = ...
		if (guid == currentGUID) then
			GearDB[guid] = UnitGear(currentUNIT)
			SpecDB[guid] = UnitSpec(currentUNIT)

			if (not GearDB[guid]) or (not SpecDB[guid]) then
				ScanUnit(currentUNIT, true)
			else
				SetUnitInfo(GearDB[guid], SpecDB[guid])
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
