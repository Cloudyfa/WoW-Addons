--[[
	Cloudy TradeSkill
	Copyright (c) 2016, Cloudyfa
	All rights reserved.
]]


--- Initialization ---
local itemDisplay = 30
local numTabs = 0
local skinTabs
local searchTxt = ''
local filterMats, filterSkill
local function InitDB()
	itemDisplay = CTSkill_itemDisplay or itemDisplay
	if IsAddOnLoaded('Aurora') then
		skinTabs = 'Aurora'
	elseif IsAddOnLoaded('ElvUI') then
		skinTabs = 'ElvUI'
	end
end


--- Create Frame ---
local f = CreateFrame('Frame', 'CloudyTradeSkill')
f:RegisterEvent('PLAYER_LOGIN')
f:RegisterEvent('TRADE_SKILL_SHOW')
f:RegisterEvent('TRADE_SKILL_LIST_UPDATE')
f:RegisterEvent('TRADE_SKILL_DATA_SOURCE_CHANGED')


--- Local Functions ---
	--- Save Filters ---
	local function saveFilters()
		searchTxt = TradeSkillFrame.SearchBox:GetText()
		filterMats = C_TradeSkillUI.GetOnlyShowMakeableRecipes()
		filterSkill = C_TradeSkillUI.GetOnlyShowSkillUpRecipes()
	end

	--- Restore Filters ---
	local function restoreFilters()
		TradeSkillFrame.SearchBox:SetText('')
		TradeSkillFrame.SearchBox:SetText(searchTxt)
		C_TradeSkillUI.SetOnlyShowMakeableRecipes(filterMats)
		C_TradeSkillUI.SetOnlyShowSkillUpRecipes(filterSkill)
	end

	--- Check Current Tab ---
	local function isCurrentTab(self)
		if self.tooltip and IsCurrentSpell(self.tooltip) then
			self:SetChecked(true)
			self:RegisterForClicks(nil)
			restoreFilters()
		else
			self:SetChecked(false)
			self:RegisterForClicks('LeftButtonDown')
		end
	end

	--- Add Tab Button ---
	local function addTab(id, index, isSub)
		local name, _, icon = GetSpellInfo(id)
		if (not name) or (not icon) then return end

		local tab = _G['CTradeSkillTab' .. index] or CreateFrame('CheckButton', 'CTradeSkillTab' .. index, TradeSkillFrame, 'SpellBookSkillLineTabTemplate, SecureActionButtonTemplate')
		tab:SetPoint('TOPLEFT', TradeSkillFrame, 'TOPRIGHT', skinTabs and 1 or 0, (-44 * index) + (-40 * isSub))

		tab:SetScript('OnEvent', isCurrentTab)
		tab:RegisterEvent('CURRENT_SPELL_CAST_CHANGED')

		tab.id = id
		tab.tooltip = name
		tab:SetAttribute('type', 'spell')
		tab:SetAttribute('spell', name)
		tab:SetNormalTexture(icon)

		if skinTabs and not tab.skinned then
			local checkedTexture
			if (skinTabs == 'Aurora') then
				checkedTexture = 'Interface\\AddOns\\Aurora\\media\\CheckButtonHilight'
			elseif (skinTabs == 'ElvUI') then
				checkedTexture = tab:CreateTexture(nil, 'HIGHLIGHT')
				checkedTexture:SetColorTexture(1, 1, 1, 0.3)
				checkedTexture:SetInside()
				tab:SetHighlightTexture(nil)
			end
			tab:SetCheckedTexture(checkedTexture)
			tab:GetNormalTexture():SetTexCoord(.08, .92, .08, .92)
			tab:GetRegions():Hide()
			tab.skinned = true
		end

		isCurrentTab(tab)
		tab:Show()
	end

	--- Remove Tab Buttons ---
	local function removeTabs()
		for i = 1, numTabs do
			local tab = _G['CTradeSkillTab' .. i]
			if tab and tab:IsShown() then
				tab:UnregisterEvent('CURRENT_SPELL_CAST_CHANGED')
				tab:Hide()
			end
		end
	end

	--- Check Profession Useable ---
	local function isUseable(id)
		local name = GetSpellInfo(id)
		return IsUsableSpell(name)
	end

	--- Update Profession Tabs ---
	local function updateTabs()
		local mainTabs, subTabs = {}, {}

		local _, class = UnitClass('player')
		if class == 'DEATHKNIGHT' and isUseable(53428) then
			mainTabs[1] = 53428 --RuneForging
		elseif class == 'ROGUE' and isUseable(1804) then
			subTabs[1] = 1804 --PickLock
		end

		if GetItemCount(87216) ~= 0 then
			subTabs[#subTabs + 1] = 126462 --ThermalAnvil
		end

		local prof1, prof2, arch, fishing, cooking, firstaid = GetProfessions()
		local profs = {prof1, prof2, cooking, firstaid}
		for _, prof in pairs(profs) do
			local num, offset, _, _, _, spec = select(5, GetProfessionInfo(prof))
			if (spec and spec ~= 0) then num = 1 end
			for i = 1, num do
				if not IsPassiveSpell(offset + i, BOOKTYPE_PROFESSION) then
					local _, id = GetSpellBookItemInfo(offset + i, BOOKTYPE_PROFESSION)
					if (i == 1) then
						mainTabs[#mainTabs + 1] = id
					else
						subTabs[#subTabs + 1] = id
					end
				end
			end
		end

		local sameTabs = true
		for i = 1, #mainTabs do
			local tab = _G['CTradeSkillTab' .. i]
			if tab and not (tab.id == mainTabs[i]) then
				sameTabs = false
				break
			end
		end

		if not sameTabs or not (numTabs == #mainTabs + #subTabs) then
			removeTabs()
			numTabs = #mainTabs + #subTabs
			for i = 1, numTabs do
				addTab(mainTabs[i] or subTabs[i - #mainTabs], i, mainTabs[i] and 0 or 1)
			end
		end
	end

	--- Update Frame Size ---
	local function updateSize()
		TradeSkillFrame:SetHeight(itemDisplay * 16 + 96) --496
		TradeSkillFrame.RecipeInset:SetHeight(itemDisplay * 16 + 10) --410
		TradeSkillFrame.DetailsInset:SetHeight(itemDisplay * 16 - 10) --390
		TradeSkillFrame.DetailsFrame:SetHeight(itemDisplay * 16 - 15) --385
		TradeSkillFrame.DetailsFrame.Background:SetHeight(itemDisplay * 16 - 17) --383

		if TradeSkillFrame.RecipeList.FilterBar:IsVisible() then
			TradeSkillFrame.RecipeList:SetHeight(itemDisplay * 16 - 11) --389
		else
			TradeSkillFrame.RecipeList:SetHeight(itemDisplay * 16 + 5) --405
		end

		if #TradeSkillFrame.RecipeList.buttons < (itemDisplay + 2) then
			HybridScrollFrame_CreateButtons(TradeSkillFrame.RecipeList, 'TradeSkillRowButtonTemplate', 0, 0)
			TradeSkillFrame.RecipeList:Refresh()
		end
	end

	--- Mouse Click Events ---
	local offsetX, offsetY
	local function resizeBar_OnMouseDown(self, button)
		if (button == 'LeftButton') and not InCombatLockdown() then
			offsetX = TradeSkillFrame:GetLeft()
			offsetY = TradeSkillFrame:GetTop()

			TradeSkillFrame:SetResizable(true)
			TradeSkillFrame:SetMinResize(670, 470)
			TradeSkillFrame:SetMaxResize(670, offsetY - 40)
			TradeSkillFrame:StartSizing('BOTTOM')
		end
	end
	local function resizeBar_OnMouseUp(self, button)
		if (button == 'LeftButton') and not InCombatLockdown() then
			TradeSkillFrame:StopMovingOrSizing()
			TradeSkillFrame:SetResizable(false)
			TradeSkillFrame:ClearAllPoints()
			TradeSkillFrame:SetPoint('TOPLEFT', UIParent, 'BOTTOMLEFT', offsetX, offsetY)

			local item = (TradeSkillFrame:GetHeight() - 96) / 16
			itemDisplay = floor(item, 0.5)
			CTSkill_itemDisplay = itemDisplay
			updateSize()
		end
	end


--- Create Resize Bar ---
local resizeBar = CreateFrame('Button', nil, TradeSkillFrame)
resizeBar:SetAllPoints(TradeSkillFrameBottomBorder)
resizeBar:SetScript('OnMouseDown', resizeBar_OnMouseDown)
resizeBar:SetScript('OnMouseUp', resizeBar_OnMouseUp)
resizeBar:SetScript('OnEnter', function()
	if not InCombatLockdown() then
		SetCursor('CAST_CURSOR')
	end
end)
resizeBar:SetScript('OnLeave', function()
	if not InCombatLockdown() then
		ResetCursor()
	end
end)


--- Create Movable Bar ---
local movBar = CreateFrame('Button', nil, TradeSkillFrame)
movBar:SetAllPoints(TradeSkillFrameTopBorder)
movBar:SetScript('OnMouseDown', function(self, button)
	if (button == 'LeftButton') then
		TradeSkillFrame:SetMovable(true)
		TradeSkillFrame:StartMoving()
	end
end)
movBar:SetScript('OnMouseUp', function()
	TradeSkillFrame:StopMovingOrSizing()
	TradeSkillFrame:SetMovable(false)
end)


--- Refresh Recipe List ---
hooksecurefunc('HybridScrollFrame_Update', function(self, ...)
	if (self == TradeSkillFrame.RecipeList) then
		if self.FilterBar:IsVisible() then
			self:SetHeight(itemDisplay * 16 - 11) --389
		else
			self:SetHeight(itemDisplay * 16 + 5) --405
		end
	end
end)


--- Fix SearchBox ---
hooksecurefunc('ChatEdit_InsertLink', function(link)
	if link and TradeSkillFrame and TradeSkillFrame:IsShown() then
		local activeWindow = ChatEdit_GetActiveWindow()
		if activeWindow then return end

		local text = strmatch(link, '|h%[(.+)%]|h|r')
		if text then
			text = strmatch(text, ':%s(.+)') or text
			TradeSkillFrame.SearchBox:SetText(text:lower())
		end
	end
end)
TradeSkillFrame.SearchBox:SetWidth(205)


--- Fix StackSplit ---
hooksecurefunc('ContainerFrameItemButton_OnModifiedClick', function(self, button)
	if TradeSkillFrame and TradeSkillFrame:IsShown() then
		if (button == 'LeftButton') then
			StackSplitFrame:Hide()
		end
	end
end)


--- Fix RecipeLink ---
local getRecipe = C_TradeSkillUI.GetRecipeLink
C_TradeSkillUI.GetRecipeLink = function(link)
	if link and (link ~= '') then
		return getRecipe(link)
	end
end


--- Druid Unshapeshift ---
local function injectButtons()
	local _, class = UnitClass('player')
	if (class ~= 'DRUID') then return end

	local function injectMacro(button, text)
		local macro = CreateFrame('Button', nil, button:GetParent(), 'SecureActionButtonTemplate, MagicButtonTemplate')
		macro:SetAttribute('type', 'macro')
		macro:SetAttribute('macrotext', SLASH_CANCELFORM1)
		macro:SetPoint(button:GetPoint())
		macro:SetFrameStrata('HIGH')
		macro:SetText(text)

		if skinTabs == 'Aurora' then
			local F = unpack(Aurora)
			F.Reskin(macro)
		elseif skinTabs == 'ElvUI' then
			local E = unpack(ElvUI)
			local S = E:GetModule('Skins')
			S:HandleButton(macro, true)
		end

		macro:HookScript('OnClick', button:GetScript('OnClick'))
		button:HookScript('OnDisable', function()
			macro:SetAlpha(0)
			macro:RegisterForClicks(nil)
		end)
		button:HookScript('OnEnable', function()
			macro:SetAlpha(1)
			macro:RegisterForClicks('LeftButtonDown')
		end)
	end
	injectMacro(TradeSkillFrame.DetailsFrame.CreateButton, CREATE_PROFESSION)
	injectMacro(TradeSkillFrame.DetailsFrame.CreateAllButton, CREATE_ALL)
end


--- Handle Events ---
f:SetScript('OnEvent', function(self, event, ...)
	if (event == 'PLAYER_LOGIN') then
		InitDB()
		updateSize()
		injectButtons()
	elseif (event == 'TRADE_SKILL_SHOW') then
		restoreFilters()
	elseif (event == 'TRADE_SKILL_LIST_UPDATE') then
		saveFilters()
	elseif (event == 'TRADE_SKILL_DATA_SOURCE_CHANGED') then
		if not InCombatLockdown() then
			updateTabs()
		end
	end
end)

