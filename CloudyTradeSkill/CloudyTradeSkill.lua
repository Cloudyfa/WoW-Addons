--[[
	Cloudy Trade Skill
	Copyright (c) 2016, Cloudyfa
	All rights reserved.
]]


--- Variables ---
local itemDisplay = 30
local enableTabs = true


--- Create Frame ---
local f = CreateFrame('Frame', 'CloudyTradeSkill')
f:RegisterEvent('TRADE_SKILL_LIST_UPDATE')


--- Local Functions ---
	--- Check Current Tab ---
	local function isCurrentTab(self)
		if InCombatLockdown() then return end

		if self.spell and IsCurrentSpell(self.spell) then
			self:SetChecked(true)
			self:Disable()
		else
			self:SetChecked(false)
			self:Enable()
		end
	end

	--- Add Tab Button ---
	local function addTab(id, index, isSub)
		local name, _, icon = GetSpellInfo(id)
		if (not name) or (not icon) then return end

		local tab = _G['CTradeSkillTab' .. index] or CreateFrame('CheckButton', 'CTradeSkillTab' .. index, TradeSkillFrame, 'SpellBookSkillLineTabTemplate,SecureActionButtonTemplate')
		tab.spell = name
		tab.spellID = id
		tab.tooltip = name

		tab:SetScript('OnEvent', isCurrentTab)
		tab:RegisterEvent('CURRENT_SPELL_CAST_CHANGED')

		tab:SetAttribute('type', 'spell')
		tab:SetAttribute('spell', name)
		tab:SetNormalTexture(icon)
		tab:SetPoint('TOPLEFT', TradeSkillFrame, 'TOPRIGHT', 1, -44 * index + (-32 * isSub))
		tab:Show()

		isCurrentTab(tab)
	end

	--- Remove Tab Buttons ---
	local function removeTabs()
		for i = 1, 10 do
			local tab = _G['CTradeSkillTab' .. i]
			if tab and tab:IsShown() then
				tab:Hide()
			end
		end
	end

	--- Update Profession Tabs ---
	local function updateTabs()
		local mainTabs, subTabs = {}, {}

		local _, class = UnitClass('player')
		if class == 'DEATHKNIGHT' then
			mainTabs[1] = 53428 --RuneForging
		elseif class == 'ROGUE' then
			mainTabs[1] = 1804 --PickLock
		end

		local prof1, prof2, arch, fishing, cooking, firstaid = GetProfessions()
		local profs = {prof1, prof2, cooking, firstaid}
		for _, prof in pairs(profs) do
			local _, _, _, _, num, offset = GetProfessionInfo(prof)
			for i = 1, num do
				local _, id = GetSpellBookItemInfo(offset + i, BOOKTYPE_PROFESSION)
				if (i == 1) then
					mainTabs[#mainTabs + 1] = id
				else
					subTabs[#subTabs + 1] = id
				end
			end
		end

		for i = 1, #mainTabs do
			addTab(mainTabs[i], i, 0)
		end
		for i = 1, #subTabs do
			addTab(subTabs[i], #mainTabs + i, 1)
		end
	end


--- Fix SearchBox ---
hooksecurefunc('ChatEdit_InsertLink', function(link)
	if link and TradeSkillFrame and TradeSkillFrame:IsShown() then
		local text = strmatch(link, '|h%[(.+)%]|h|r')
		if text then
			text = strmatch(text, ':%s(.+)') or text
			TradeSkillFrame.SearchBox:SetText(text:lower())
		end
	end
end)
TradeSkillFrame.SearchBox:SetWidth(205)


--- Fix RecipeLink ---
local getRecipe = C_TradeSkillUI.GetRecipeLink
C_TradeSkillUI.GetRecipeLink = function(link)
	if link and (link ~= '') then
		return getRecipe(link)
	end
end


--- Modify Default Frame ---
hooksecurefunc('HybridScrollFrame_Update', function(self, ...)
	if (self == TradeSkillFrame.RecipeList) then
		if self.FilterBar:IsVisible() then
			self:SetHeight(itemDisplay * 16 - 11) --389
		else
			self:SetHeight(itemDisplay * 16 + 5) --405
		end
	end
end)
TradeSkillFrame:SetHeight(itemDisplay * 16 + 96) --496
TradeSkillFrame.RecipeInset:SetHeight(itemDisplay * 16 + 10) --410
TradeSkillFrame.DetailsInset:SetHeight(itemDisplay * 16 - 10) --390
TradeSkillFrame.DetailsFrame:SetHeight(itemDisplay * 16 - 15) --385
TradeSkillFrame.DetailsFrame.Background:SetHeight(itemDisplay * 16 - 17) --383


--- Handle Events ---
f:SetScript('OnEvent', function(self, event, ...)
	if (event == 'TRADE_SKILL_LIST_UPDATE') then
		if TradeSkillFrame and TradeSkillFrame.RecipeList then
			if TradeSkillFrame.RecipeList.buttons and #TradeSkillFrame.RecipeList.buttons ~= (itemDisplay + 2) then
				HybridScrollFrame_CreateButtons(TradeSkillFrame.RecipeList, 'TradeSkillRowButtonTemplate', 0, 0)
			end
			if enableTabs and not InCombatLockdown() then
				removeTabs()
				updateTabs()
			end
		end
	end
end)

