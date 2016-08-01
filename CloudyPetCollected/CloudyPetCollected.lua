--[[
	Cloudy Pet Collected
	Copyright (c) 2016, Cloudyfa
	All rights reserved.
]]


--- Pet String Calculation ---
local function GetPetString(name)
	if (not name) or (name == '') then return end
	if (not CollectionsJournal) then CollectionsJournal_LoadUI() end

	local petString, petID, speciesID
	speciesID, petID = C_PetJournal.FindPetIDByName(name)

	if speciesID and (speciesID > 0) then
		if petID then
			local level = select(3, C_PetJournal.GetPetInfoByPetID(petID))
			local quality = select(5, C_PetJournal.GetPetStats(petID))

			local color = ITEM_QUALITY_COLORS[quality - 1].hex
			petString = color .. COLLECTED .. ' (L' .. level .. ')|r'
		else
			local color = ITEM_QUALITY_COLORS[5].hex
			petString = color .. NOT_COLLECTED .. '|r'
		end
	end

	return petString
end


--- Set Pet Info ---
local function SetPetInfo(tooltip, name)
	local petString = GetPetString(name)
	if (not petString) then return end

	local petLine
	for i = 2, tooltip:NumLines() do
		local line = _G[tooltip:GetName() .. 'TextLeft' .. i]
		local text = line:GetText()

		if text then
			if (text == NOT_COLLECTED) or (text == UNIT_CAPTURABLE) or strfind(text, COLLECTED) then
				petLine = line
				break
			end
		end
	end

	if petLine then
		petLine:SetText(petString)
	else
		tooltip:AddLine(petString)
	end

	tooltip:Show()
end


--- Pet Battle Tooltip ---
hooksecurefunc('PetBattleUnitTooltip_UpdateForUnit', function(self, owner, index)
	if (owner == LE_BATTLE_PET_ENEMY) and C_PetBattles.IsWildBattle() then
		local petName = C_PetBattles.GetName(owner, index)
		local petString = GetPetString(petName)

		self.CollectedText:SetText(petString)
	end
end)


--- Pet Cage Tooltip ---
local function PetCageOnShow(self)
	local petName = self.Name and self.Name:GetText()
	local petString = GetPetString(petName)

	if petString then
		self.Owned:SetText(petString)

		if self.Delimiter then
			self:SetSize(260,164)
			self.Delimiter:ClearAllPoints()
		else
			self:SetSize(260,136)
		end

		self:Show()
	end
end
BattlePetTooltip:HookScript('OnUpdate', PetCageOnShow)
FloatingBattlePetTooltip:HookScript('OnUpdate', PetCageOnShow)


--- Pet Item Tooltip ---
local function OnTooltipSetItem(self)
	local name = self:GetItem()

	if name and (name ~= '') then
		SetPetInfo(self, name)
	end
end
GameTooltip:HookScript('OnTooltipSetItem', OnTooltipSetItem)
ItemRefTooltip:HookScript('OnTooltipSetItem', OnTooltipSetItem)


--- Pet Unit Tooltip ---
GameTooltip:HookScript('OnTooltipSetUnit', function(self)
	local _, unit = self:GetUnit()

	if unit and UnitIsWildBattlePet(unit) then
		local name = GetUnitName(unit)
		SetPetInfo(self, name)
	end
end)


--- Pet Minimap Tooltip ---
GameTooltip:HookScript('OnUpdate', function(self)
	if self:IsOwned(Minimap) then
		local line = _G[self:GetName() .. 'TextLeft1']
		local text = line:GetText()

		if (not text) or (text == '') then return end

		local lines = {text}
		if strfind(text, '\n') then
			lines = {strsplit('\n', text)}
		end

		for i = 1, #lines do
			local name = gsub(lines[i], '|T.-|t', '')

			local petString = GetPetString(name)
			if petString and (not UnitPlayerControlled(name)) then
				lines[i] = lines[i] .. '  ' .. petString
			end
		end

		text = table.concat(lines, '\n')

		line:SetText(text)
		self:Show()
	end
end)
