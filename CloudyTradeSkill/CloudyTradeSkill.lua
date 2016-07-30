--[[
	Cloudy Trade Skill
	Copyright (c) 2016, Cloudyfa
	All rights reserved.
]]


--- Variables ---
local skillDisplay = 30


--- Create Frame ---
local f = CreateFrame('Frame', 'CloudyTradeSkill')
f:RegisterEvent('TRADE_SKILL_LIST_UPDATE')

f:SetScript('OnEvent', function(self, event, ...)
	if (event == 'TRADE_SKILL_LIST_UPDATE') then
		if TradeSkillFrame and TradeSkillFrame.RecipeList then
			if TradeSkillFrame.RecipeList.buttons and #TradeSkillFrame.RecipeList.buttons ~= (skillDisplay + 2) then
				HybridScrollFrame_CreateButtons(TradeSkillFrame.RecipeList, 'TradeSkillRowButtonTemplate', 0, 0)
			end
		end
	end
end)


-- Fix SearchBox
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


-- Fix RecipeLink
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
			self:SetHeight(skillDisplay * 16 - 11) --389
		else
			self:SetHeight(skillDisplay * 16 + 5) --405
		end
	end
end)
TradeSkillFrame:SetHeight(skillDisplay * 16 + 96) --496
TradeSkillFrame.RecipeInset:SetHeight(skillDisplay * 16 + 10) --410
TradeSkillFrame.DetailsInset:SetHeight(skillDisplay * 16 - 10) --390
TradeSkillFrame.DetailsFrame:SetHeight(skillDisplay * 16 - 15) --385
TradeSkillFrame.DetailsFrame.Background:SetHeight(skillDisplay * 16 - 17) --383

