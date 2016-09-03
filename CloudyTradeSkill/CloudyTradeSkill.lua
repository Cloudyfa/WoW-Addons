--[[
	Cloudy TradeSkill
	Copyright (c) 2016, Cloudyfa
	All rights reserved.
]]


--- Initialization ---
local numTabs = 0
local searchTxt = ''
local filterMats, filterSkill
local skinUI, loadedUI
local function InitDB()
	-- Create new DB if needed --
	if (not CTradeSkillDB) then
		CTradeSkillDB = {}
		CTradeSkillDB['Size'] = 30
		CTradeSkillDB['Fade'] = true
		CTradeSkillDB['Unlock'] = false
	end
	if not CTradeSkillDB['Tabs'] then CTradeSkillDB['Tabs'] = {} end

	-- Load UI addons --
	if IsAddOnLoaded('Aurora') then
		skinUI = 'Aurora'
		loadedUI = unpack(Aurora)
	elseif IsAddOnLoaded('ElvUI') then
		skinUI = 'ElvUI'
		loadedUI = unpack(ElvUI):GetModule('Skins')
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
			self:RegisterForClicks('AnyDown')
		end
	end

	--- Add Tab Button ---
	local function addTab(id, index, isSub)
		local name, _, icon = GetSpellInfo(id)
		if (not name) or (not icon) then return end

		local tab = _G['CTradeSkillTab' .. index] or CreateFrame('CheckButton', 'CTradeSkillTab' .. index, TradeSkillFrame, 'SpellBookSkillLineTabTemplate, SecureActionButtonTemplate')
		tab:SetScript('OnEvent', isCurrentTab)
		tab:RegisterEvent('CURRENT_SPELL_CAST_CHANGED')

		tab.id = id
		tab.isSub = isSub
		tab.tooltip = name
		tab:SetNormalTexture(icon)

		if (id == 67556) then
			tab:SetAttribute('type', 'toy')
			tab:SetAttribute('toy', name)
		elseif (id == 126462) then
			tab:SetAttribute('type', 'item')
			tab:SetAttribute('item', name)
		else
			tab:SetAttribute('type', 'spell')
			tab:SetAttribute('spell', name)
		end

		if skinUI and not tab.skinned then
			local checkedTexture
			if (skinUI == 'Aurora') then
				checkedTexture = 'Interface\\AddOns\\Aurora\\media\\CheckButtonHilight'
			elseif (skinUI == 'ElvUI') then
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

	--- Sort Tabs ---
	local function sortTabs()
		local index = 1
		for i = 1, numTabs do
			local tab = _G['CTradeSkillTab' .. i]
			if tab then
				if CTradeSkillDB['Tabs'][tab.id] == true then
					tab:SetPoint('TOPLEFT', TradeSkillFrame, 'TOPRIGHT', skinUI and 1 or 0, (-44 * index) + (-40 * tab.isSub))
					tab:Show()
					index = index + 1
				else
					tab:Hide()
				end
			end
		end
	end

	--- Check Fading State ---
	local function fadeState()
		if GetUnitSpeed('player') == 0 then
			TradeSkillFrame:SetAlpha(1.0)
		else
			if CTradeSkillDB['Fade'] == true then
				TradeSkillFrame:SetAlpha(0.4)
			else
				TradeSkillFrame:SetAlpha(1.0)
			end
		end

		if CTradeSkillDB['Fade'] == true then
			f:RegisterEvent('PLAYER_STARTED_MOVING')
			f:RegisterEvent('PLAYER_STOPPED_MOVING')
		else
			f:UnregisterEvent('PLAYER_STARTED_MOVING')
			f:UnregisterEvent('PLAYER_STOPPED_MOVING')
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
			tinsert(mainTabs, 53428) --RuneForging
		elseif class == 'ROGUE' and isUseable(1804) then
			tinsert(subTabs, 1804) --PickLock
		end

		if GetItemCount(134020) ~= 0 then
			tinsert(subTabs, 67556) --CheftHat
		end
		if GetItemCount(87216) ~= 0 then
			tinsert(subTabs, 126462) --ThermalAnvil
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
						tinsert(mainTabs, id)
					else
						tinsert(subTabs, id)
					end
				end
			end
		end

		local sameTabs = true
		for i = 1, #mainTabs + #subTabs do
			local id = mainTabs[i] or subTabs[i - #mainTabs]
			if CTradeSkillDB['Tabs'][id] == nil then
				CTradeSkillDB['Tabs'][id] = true
				sameTabs = false
				break
			end
		end

		if not sameTabs or (numTabs ~= #mainTabs + #subTabs) then
			removeTabs()
			numTabs = #mainTabs + #subTabs

			for i = 1, numTabs do
				local id = mainTabs[i] or subTabs[i - #mainTabs]
				addTab(id, i, mainTabs[i] and 0 or 1)
			end
			sortTabs()
		end
	end

	--- Update Frame Size ---
	local function updateSize(forced)
		TradeSkillFrame:SetHeight(CTradeSkillDB['Size'] * 16 + 96) --496
		TradeSkillFrame.RecipeInset:SetHeight(CTradeSkillDB['Size'] * 16 + 10) --410
		TradeSkillFrame.DetailsInset:SetHeight(CTradeSkillDB['Size'] * 16 - 10) --390
		TradeSkillFrame.DetailsFrame:SetHeight(CTradeSkillDB['Size'] * 16 - 15) --385
		TradeSkillFrame.DetailsFrame.Background:SetHeight(CTradeSkillDB['Size'] * 16 - 17) --383

		if TradeSkillFrame.RecipeList.FilterBar:IsVisible() then
			TradeSkillFrame.RecipeList:SetHeight(CTradeSkillDB['Size'] * 16 - 11) --389
		else
			TradeSkillFrame.RecipeList:SetHeight(CTradeSkillDB['Size'] * 16 + 5) --405
		end

		if forced and #TradeSkillFrame.RecipeList.buttons < floor(CTradeSkillDB['Size'], 0.5) + 2 then
			HybridScrollFrame_CreateButtons(TradeSkillFrame.RecipeList, 'TradeSkillRowButtonTemplate', 0, 0)
			TradeSkillFrame.RecipeList:Refresh()
		end
	end

	--- Update Frame Position ---
	local function updatePosition()
		if CTradeSkillDB['Unlock'] then
			UIPanelWindows['TradeSkillFrame'].area = nil
			TradeSkillFrame:ClearAllPoints()
			if CTradeSkillDB['OffsetX'] and CTradeSkillDB['OffsetY'] then
				TradeSkillFrame:SetPoint('TOPLEFT', UIParent, 'BOTTOMLEFT', CTradeSkillDB['OffsetX'], CTradeSkillDB['OffsetY'])
			else
				TradeSkillFrame:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', GetUIPanel('left') and 623 or 16, -116)
			end
		else
			UpdateUIPanelPositions(TradeSkillFrame)
		end
	end


--- Create Resize Bar ---
local resizeBar = CreateFrame('Button', nil, TradeSkillFrame)
resizeBar:SetAllPoints(TradeSkillFrameBottomBorder)
resizeBar:SetScript('OnMouseDown', function(_, button)
	if (button == 'LeftButton') and not InCombatLockdown() then
		TradeSkillFrame:SetResizable(true)
		TradeSkillFrame:SetMinResize(670, 470)
		TradeSkillFrame:SetMaxResize(670, TradeSkillFrame:GetTop() - 40)
		TradeSkillFrame:StartSizing('BOTTOM')
	end
end)
resizeBar:SetScript('OnMouseUp', function(_, button)
	if (button == 'LeftButton') and not InCombatLockdown() then
		TradeSkillFrame:StopMovingOrSizing()
		TradeSkillFrame:SetResizable(false)
		updateSize(true)
	end
end)
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
movBar:SetScript('OnMouseDown', function(_, button)
	if (button == 'LeftButton') then
		TradeSkillFrame:SetMovable(true)
		TradeSkillFrame:StartMoving()
	elseif (button == 'RightButton') then
		if not InCombatLockdown() then
			CTradeSkillDB['OffsetX'] = nil
			CTradeSkillDB['OffsetY'] = nil
			updatePosition()
		end
	end
end)
movBar:SetScript('OnMouseUp', function(_, button)
	if (button == 'LeftButton') then
		TradeSkillFrame:StopMovingOrSizing()
		TradeSkillFrame:SetMovable(false)

		CTradeSkillDB['OffsetX'] = TradeSkillFrame:GetLeft()
		CTradeSkillDB['OffsetY'] = TradeSkillFrame:GetTop()
	end
end)


--- Force ESC Close ---
hooksecurefunc('ToggleGameMenu', function()
	if CTradeSkillDB['Unlock'] and TradeSkillFrame:IsShown() then
		C_TradeSkillUI.CloseTradeSkill()
		HideUIPanel(GameMenuFrame)
	end
end)


--- Refresh TSFrame ---
TradeSkillFrame:HookScript('OnSizeChanged', function()
	if not InCombatLockdown() then
		CTradeSkillDB['Size'] = (TradeSkillFrame:GetHeight() - 96) / 16
		updateSize()
	end
end)


--- Refresh RecipeList ---
hooksecurefunc('HybridScrollFrame_Update', function(self, ...)
	if (self == TradeSkillFrame.RecipeList) then
		if self.FilterBar:IsVisible() then
			self:SetHeight(CTradeSkillDB['Size'] * 16 - 11) --389
		else
			self:SetHeight(CTradeSkillDB['Size'] * 16 + 5) --405
		end
	end
end)


--- Fix SearchBox ---
TradeSkillFrame.RankFrame:SetWidth(500)
TradeSkillFrame.SearchBox:SetWidth(240)
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
		local macro = CreateFrame('Button', nil, button:GetParent(), 'MagicButtonTemplate, SecureActionButtonTemplate')
		macro:SetAttribute('type', 'macro')
		macro:SetAttribute('macrotext', SLASH_CANCELFORM1)
		macro:SetPoint(button:GetPoint())
		macro:SetFrameStrata('HIGH')
		macro:SetText(text)

		if (skinUI == 'Aurora') then
			loadedUI.Reskin(macro)
		elseif (skinUI == 'ElvUI') then
			loadedUI:HandleButton(macro, true)
		end

		macro:HookScript('OnClick', button:GetScript('OnClick'))
		button:HookScript('OnDisable', function()
			button:SetAlpha(1)
			macro:SetAlpha(0)
			macro:RegisterForClicks(nil)
		end)
		button:HookScript('OnEnable', function()
			button:SetAlpha(0)
			macro:SetAlpha(1)
			macro:RegisterForClicks('LeftButtonDown')
		end)
	end
	injectMacro(TradeSkillFrame.DetailsFrame.CreateButton, CREATE_PROFESSION)
	injectMacro(TradeSkillFrame.DetailsFrame.CreateAllButton, CREATE_ALL)
end


--- Create Option Menu ---
local function createOptions()
	--- Dropdown Menu ---
	local function CTSDropdown_Init(self, level)
		local info = UIDropDownMenu_CreateInfo()
		if level == 1 then
			info.text = f:GetName()
			info.isTitle = true
			info.notCheckable = true
			UIDropDownMenu_AddButton(info, level)

			info.isTitle = false
			info.disabled = false
			info.isNotRadio = true
			info.notCheckable = false
			info.keepShownOnClick = true

			info.text = 'UI ' .. ACTION_SPELL_AURA_REMOVED_BUFF
			info.func = function()
				CTradeSkillDB['Fade'] = not CTradeSkillDB['Fade']
				fadeState()
			end
			info.checked = CTradeSkillDB['Fade']
			UIDropDownMenu_AddButton(info, level)

			info.text = UNLOCK_FRAME
			info.func = function()
				CTradeSkillDB['Unlock'] = not CTradeSkillDB['Unlock']
				ReloadUI()
			end
			info.checked = CTradeSkillDB['Unlock']
			UIDropDownMenu_AddButton(info, level)

			info.func = nil
			info.checked = 	nil
			info.notCheckable = true
			info.hasArrow = true

			info.text = PRIMARY;
			info.value = 1;
			info.disabled = InCombatLockdown()
			UIDropDownMenu_AddButton(info, level);

			info.text = SECONDARY;
			info.value = 2;
			info.disabled = InCombatLockdown()
			UIDropDownMenu_AddButton(info, level);
		elseif level == 2 then
			info.isNotRadio = true
			info.keepShownOnClick = true
			if UIDROPDOWNMENU_MENU_VALUE == 1 then
				for i = 1, numTabs do
					local tab = _G['CTradeSkillTab' .. i]
					if tab and (tab.isSub == 0) then
						info.text = tab.tooltip
						info.func = function()
							CTradeSkillDB['Tabs'][tab.id] = not CTradeSkillDB['Tabs'][tab.id]
							sortTabs()
						end
						info.checked = CTradeSkillDB['Tabs'][tab.id]
						UIDropDownMenu_AddButton(info, level)
					end
				end
			elseif UIDROPDOWNMENU_MENU_VALUE == 2 then
				for i = 1, numTabs do
					local tab = _G['CTradeSkillTab' .. i]
					if tab and (tab.isSub == 1) then
						info.text = tab.tooltip
						info.func = function()
							CTradeSkillDB['Tabs'][tab.id] = not CTradeSkillDB['Tabs'][tab.id]
							sortTabs()
						end
						info.checked = CTradeSkillDB['Tabs'][tab.id]
						UIDropDownMenu_AddButton(info, level)
					end
				end
			end
		end
	end
	local menu = CreateFrame('Frame', 'CTSDropdown', nil, 'UIDropDownMenuTemplate')
	UIDropDownMenu_Initialize(CTSDropdown, CTSDropdown_Init, 'MENU')

	--- Option Button ---
	local button = CreateFrame('Button', 'CTSOption', TradeSkillFrame.FilterButton, 'UIMenuButtonStretchTemplate')
	button:SetScript('OnClick', function(self) ToggleDropDownMenu(1, nil, CTSDropdown, self, 2, -6) end)
	button:SetPoint('RIGHT', TradeSkillFrame.FilterButton, 'LEFT', -8, 0)
	button:SetText(GAMEOPTIONS_MENU)
	button:SetSize(80, 22)
	button.Icon = button:CreateTexture(nil, 'ARTWORK')
	button.Icon:SetPoint('RIGHT')
	button.Icon:Hide()

	if (skinUI == 'Aurora') then
		loadedUI.ReskinFilterButton(button)
	elseif (skinUI == 'ElvUI') then
		button:StripTextures(true)
		button:CreateBackdrop('Default', true)
		button.backdrop:SetAllPoints()
	end
end


--- Handle Events ---
f:SetScript('OnEvent', function(self, event, ...)
	if (event == 'PLAYER_LOGIN') then
		InitDB()
		updateSize(true)
		updatePosition()
		createOptions()
		injectButtons()
		fadeState()
	elseif (event == 'PLAYER_STARTED_MOVING') then
		TradeSkillFrame:SetAlpha(0.4)
	elseif (event == 'PLAYER_STOPPED_MOVING') then
		TradeSkillFrame:SetAlpha(1.0)
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

