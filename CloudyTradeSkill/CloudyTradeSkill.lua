--[[
	Cloudy TradeSkill
	Copyright (c) 2020, Cloudyfa
	All rights reserved.
]]


--- Initialization ---
local numTabs, craftTabs = 0, nil
local skinUI, loadedUI, delay
local function InitDB()
	-- Create new DB if needed --
	if (not CTradeSkillDB) then
		CTradeSkillDB = {}
		CTradeSkillDB['Unlock'] = false
		CTradeSkillDB['Level'] = true
		CTradeSkillDB['Tooltip'] = true
	end
	CTradeSkillDB['Size'] = 22
	if not CTradeSkillDB['Tabs'] then CTradeSkillDB['Tabs'] = {} end
	if not CTradeSkillDB['Bookmarks'] then CTradeSkillDB['Bookmarks'] = {} end

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
f:RegisterEvent('ADDON_LOADED')
f:RegisterEvent('SPELLS_CHANGED')
f:RegisterEvent('PLAYER_REGEN_ENABLED')


--- Local Functions ---
	--- Profession Data ---
	local CTS_ProfsData = {
		-- profName: profID, subSpell
		['Herbalism'] = {182},
		['Alchemy'] = {171},
		['Skinning'] = {393},
		['Leatherworking'] = {165},
		['Smelting'] = {186},
		['Blacksmithing'] = {164},
		['Engineering'] = {202},
		['Tailoring'] = {197},
		['Enchanting'] = {333, 'Disenchant'},
		-- ['Fishing'] = {356},
		['Cooking'] = {185, 'Basic Campfire'},
		['First Aid'] = {129},
	}

	--- Get Player Professions ---
	local function CTS_GetProfessions()
		local section, profs = 0, {}
		for i = 1, GetNumSkillLines() do
			local name, hdr = GetSkillLineInfo(i)
			if hdr then
				section = section + 1
			else
				if (section == 2) or (section == 3) then
					tinsert(profs, name)
				end
			end
		end
		return profs
	end

	--- Check Current Tab ---
	local function isCurrentTab(self)
		--- Auto Hide Tab ---
		local frame = self:GetParent()
		if (frame == CraftFrame) and not UnitAffectingCombat('player') then
			if IsCurrentSpell('Enchanting') then
				self:Show()
			else
				self:Hide()
				return
			end
		end

		--- Check Tab State ---
		if self.tooltip and IsCurrentSpell(self.tooltip) then
			if IsCurrentSpell('Enchanting') then
				if (self.tooltip == 'Enchanting') then
					CTradeSkillDB['Panel'] = self.tooltip
					self:SetChecked(true)
					self:RegisterForClicks(nil)
				elseif (self.isSub == 0) then
					self:SetChecked(false)
					self:RegisterForClicks('AnyDown')
				end
			else
				if TradeSkillFrame:IsShown() and (self.isSub == 0) then
					CTradeSkillDB['Panel'] = self.tooltip
				end
				self:SetChecked(true)
				self:RegisterForClicks(nil)
			end
		else
			self:SetChecked(false)
			self:RegisterForClicks('AnyDown')
		end
	end

	--- Add Tab Button ---
	local function addTab(name, index, isSub, frame)
		local icon = select(3, GetSpellInfo(name))
		if (not name) or (not icon) then return end

		local tab = _G['CTSTab-' .. frame:GetName() .. '_' .. index] or CreateFrame('CheckButton', 'CTSTab-' .. frame:GetName() .. '_' .. index, frame, 'SpellBookSkillLineTabTemplate, SecureActionButtonTemplate')
		tab:SetScript('OnEvent', isCurrentTab)
		tab:RegisterEvent('CURRENT_SPELL_CAST_CHANGED')

		tab.isSub = isSub
		tab.tooltip = name
		tab:SetNormalTexture(icon)
		tab:SetAttribute('type', 'spell')
		tab:SetAttribute('spell', name)
		isCurrentTab(tab)

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
	end

	--- Remove Tab Buttons ---
	local function removeTabs()
		for _, frame in pairs({TradeSkillFrame, CraftFrame}) do
			for i = 1, numTabs do
				local tab = _G['CTSTab-' .. frame:GetName() .. '_' .. i]
				if tab and tab:IsShown() then
					tab:UnregisterEvent('CURRENT_SPELL_CAST_CHANGED')
					tab:Hide()
				end
			end
		end
	end

	--- Sort Tabs ---
	local function sortTabs()
		for _, frame in pairs({TradeSkillFrame, CraftFrame}) do
			local index = 1
			for i = 1, numTabs do
				local tab = _G['CTSTab-' .. frame:GetName() .. '_' .. i]
				if tab then
					if CTradeSkillDB['Tabs'][tab.tooltip] then
						tab:SetPoint('TOPLEFT', frame, 'TOPRIGHT', skinUI and -33 or -34, (-50 * index) + (-50 * tab.isSub))
						if (frame == CraftFrame) and (GetCraftDisplaySkillLine() ~= 'Enchanting') then
							tab:Hide()
						else
							tab:Show()
						end
						index = index + 1
					else
						tab:Hide()
					end
				end
			end
		end
	end

	--- Update Profession Tabs ---
	local function updateTabs(init)
		local mainTabs, subTabs = {}, {}

		local _, class = UnitClass('player')
		if (class == 'ROGUE') then
			local spell = GetSpellInfo(1804) --PickLock
			if IsUsableSpell(spell) then
				tinsert(subTabs, spell)
			end
		end

		local profs = CTS_GetProfessions()
		for _, prof in pairs(profs) do
			if (prof == 'Mining') then prof = 'Smelting' end
			local profInfo = CTS_ProfsData[prof]
			if profInfo then
				local profID, subSpell = profInfo[1], profInfo[2]
				tinsert(mainTabs, prof)
				if subSpell then
					tinsert(subTabs, subSpell)
				end

				if init and not CTradeSkillDB['Panel'] then
					CTradeSkillDB['Panel'] = prof
				end
			end
		end

		local sameTabs = true
		for i = 1, #mainTabs + #subTabs do
			local name = mainTabs[i] or subTabs[i - #mainTabs]
			if not CTradeSkillDB['Tabs'][name] then
				CTradeSkillDB['Tabs'][name] = true
				sameTabs = false
			end
		end

		if not sameTabs or (numTabs ~= #mainTabs + #subTabs) or (CraftFrame and not craftTabs) then
			removeTabs()
			numTabs = #mainTabs + #subTabs
			for i = 1, numTabs do
				local name = mainTabs[i] or subTabs[i - #mainTabs]
				addTab(name, i, mainTabs[i] and 0 or 1, TradeSkillFrame)
				if CraftFrame then
					addTab(name, i, mainTabs[i] and 0 or 1, CraftFrame)
					craftTabs = true
				end
			end
			sortTabs()
		end
	end

	--- Update Frame Size ---
	local function updateSize(frame)
		_G[frame .. 'Frame']:SetWidth(714)
		_G[frame .. 'Frame']:SetHeight(skinUI and 512 or 487)

		_G[frame .. 'DetailScrollFrame']:ClearAllPoints()
		_G[frame .. 'DetailScrollFrame']:SetPoint('TOPLEFT', _G[frame .. 'Frame'], 'TOPLEFT', 362, -92)
		_G[frame .. 'DetailScrollFrame']:SetSize(296, 332)
		_G[frame .. 'DetailScrollFrameTop']:SetAlpha(0)
		_G[frame .. 'DetailScrollFrameBottom']:SetAlpha(0)

		_G[frame .. 'ListScrollFrame']:ClearAllPoints()
		if (frame == 'Craft') then
			_G[frame .. 'ListScrollFrame']:SetPoint('TOPLEFT', _G[frame .. 'Frame'], 'TOPLEFT', 23.8, -74.3)
			_G[frame .. 'ListScrollFrame']:SetSize(296, 357)
		else
			_G[frame .. 'ListScrollFrame']:SetPoint('TOPLEFT', _G[frame .. 'Frame'], 'TOPLEFT', 23.8, -99)
			_G[frame .. 'ListScrollFrame']:SetSize(296, 332)
		end
		if not skinUI then
			local scrollFix = _G[frame .. 'ListScrollFrame']:CreateTexture(nil, 'BACKGROUND')
			scrollFix:SetPoint('TOPRIGHT', _G[frame .. 'ListScrollFrame'], 'TOPRIGHT', 29, -110)
			scrollFix:SetTexture('Interface\\ClassTrainerFrame\\UI-ClassTrainer-ScrollBar')
			scrollFix:SetTexCoord(.0, .5, .2, .9)
			scrollFix:SetSize(32, 0)
		end

		local regions = {_G[frame .. 'Frame']:GetRegions()}
		regions[2]:SetTexture('Interface\\QuestFrame\\UI-QuestLogDualPane-Left')
		regions[2]:SetSize(512, 512)

		regions[3]:ClearAllPoints()
		regions[3]:SetPoint('TOPLEFT', regions[2], 'TOPRIGHT')
		regions[3]:SetTexture('Interface\\QuestFrame\\UI-QuestLogDualPane-Right')
		regions[3]:SetSize(256, 512)

		if not skinUI then
			regions[4]:Hide()
			regions[5]:Hide()
		end
		regions[9]:Hide()
		regions[10]:Hide()

		if not skinUI then
			--- Recipe Background ---
			local RecipeInset = _G[frame .. 'Frame']:CreateTexture(nil, 'ARTWORK')
			RecipeInset:SetPoint('TOPLEFT', _G[frame .. 'Frame'], 'TOPLEFT', 16.4, -72)
			RecipeInset:SetTexture('Interface\\RaidFrame\\UI-RaidFrame-GroupBg')
			RecipeInset:SetSize(326.5, 360.8)

			--- Detail Background ---
			local DetailsInset = _G[frame .. 'Frame']:CreateTexture(nil, 'ARTWORK')
			DetailsInset:SetPoint('TOPLEFT', _G[frame .. 'Frame'], 'TOPLEFT', 349, -73)
			DetailsInset:SetAtlas('tradeskill-background-recipe')
			DetailsInset:SetSize(324, 339)
		end

		-- Expand Tab ---
		_G[frame .. 'ExpandTabLeft']:Hide()

		--- Filter Dropdown ---
		if (frame ~= 'Craft') then
			TradeSkillInvSlotDropDown:ClearAllPoints()
			TradeSkillInvSlotDropDown:SetPoint('TOPLEFT', TradeSkillFrame, 'TOPLEFT', 190, -70)
			TradeSkillSubClassDropDown:ClearAllPoints()
			TradeSkillSubClassDropDown:SetPoint('TOPRIGHT', TradeSkillInvSlotDropDown, 'TOPLEFT', 29, 0)
		end

		--- Craft Buttons ---
		_G[frame .. 'CancelButton']:ClearAllPoints()
		_G[frame .. 'CancelButton']:SetPoint('BOTTOMRIGHT', _G[frame .. 'Frame'], 'BOTTOMRIGHT', -40, skinUI and 79 or 54)
		_G[frame .. 'CreateButton']:ClearAllPoints()
		_G[frame .. 'CreateButton']:SetPoint('RIGHT', _G[frame .. 'CancelButton'], 'LEFT', -1, 0)

		--- Recipe Buttons ---
		local skillButton
		if (frame == 'Craft') then
			skillButton = 'Craft'
			CRAFTS_DISPLAYED = CTradeSkillDB['Size']
		else
			skillButton = 'TradeSkillSkill'
			TRADE_SKILLS_DISPLAYED = CTradeSkillDB['Size']
		end

		for i = 1, CTradeSkillDB['Size'] do
			local button = _G[skillButton .. i] or CreateFrame('Button', skillButton .. i, _G[frame .. 'Frame'], skillButton .. 'ButtonTemplate')
			if (i > 1) then
				button:ClearAllPoints()
				button:SetPoint('TOPLEFT', _G[skillButton .. (i - 1)], 'BOTTOMLEFT', 0, 1)
			end
			if skinUI and not button.skinned then
				button._minus = button:CreateTexture(nil, 'OVERLAY')
				button._plus = button:CreateTexture(nil, 'OVERLAY')
				button.skinned = true
			end
		end
	end

	--- Get Recipe Index ---
	local function getRecipeIndex(name, frame)
		if (frame == CraftFrame) then
			for index = 1, GetNumCrafts() do
				local recipe = GetCraftInfo(index)
				if (recipe == name) then
					return index
				end
			end
		else
			for index = 1, GetNumTradeSkills() do
				local recipe = GetTradeSkillInfo(index)
				if (recipe == name) then
					return index
				end
			end
		end
	end

	--- Set Bookmark Icon ---
	local function bookmarkIcon(button, texture)
		button:SetNormalTexture(texture)
		button:SetPushedTexture(texture)

		local pushed = button:GetPushedTexture()
		pushed:ClearAllPoints()
		pushed:SetPoint('TOPLEFT', 1, -1)
		pushed:SetPoint('BOTTOMRIGHT', -1, 1)
		pushed:SetVertexColor(0.75, 0.75, 0.75)
	end

	--- Update Bookmarks ---
	local function updateBookmarks(frame)
		local prof
		if (frame == CraftFrame) then
			prof = GetCraftDisplaySkillLine()
		else
			prof = GetTradeSkillLine()
		end
		if not prof or (prof == 'UNKNOWN') then
			for i = 0, 10 do
				local button = _G['CTSBookmark-' .. frame:GetName() .. '_' .. i]
				if button and button:IsShown() then
					button:Hide()
				end
			end
			if _G['CTSOption-CraftFrame'] then
				_G['CTSOption-CraftFrame']:Hide()
			end
			return
		else
			local button = _G['CTSBookmark-' .. frame:GetName() .. '_0']
			if button and not button:IsShown() then
				button:Show()
			end
			if _G['CTSOption-CraftFrame'] then
				_G['CTSOption-CraftFrame']:Show()
			end
		end

		if not CTradeSkillDB['Bookmarks'][prof] then
			CTradeSkillDB['Bookmarks'][prof] = {}
		end

		local saved = CTradeSkillDB['Bookmarks'][prof]
		for i = 1, 10 do
			local button = _G['CTSBookmark-' .. frame:GetName() .. '_' .. i]
			if saved[i] then
				local index = getRecipeIndex(saved[i], frame)
				if index then
					local icon
					if (frame == CraftFrame) then
						icon = GetCraftIcon(index)
					else
						icon = GetTradeSkillIcon(index)
					end
					bookmarkIcon(button, icon or 'Interface\\Icons\\INV_Misc_QuestionMark')
					button:Show()
				end
			else
				button:Hide()
			end
		end

		local recipe
		if (frame == CraftFrame) then
			local index = GetCraftSelectionIndex()
			recipe = GetCraftInfo(index)
		else
			local index = GetTradeSkillSelectionIndex()
			recipe = GetTradeSkillInfo(index)
		end

		local selected = tContains(saved, recipe)
		local main = _G['CTSBookmark-' .. frame:GetName() .. '_0']
		if not recipe or (#saved > 9 and not selected) then
			main:Disable()
			main.State:Hide()
		else
			main:Enable()
			main.State:Show()
			if selected then
				main.State:SetTexture('Interface\\PetBattles\\DeadPetIcon')
			else
				main.State:SetTexture('Interface\\PaperDollInfoFrame\\Character-Plus')
			end
		end
	end

	--- Add Bookmark ---
	local function addBookmark(index, frame)
		local button = _G['CTSBookmark-' .. frame:GetName() .. '_' .. index] or CreateFrame('Button', 'CTSBookmark-' .. frame:GetName() .. '_' .. index, frame)
		button:SetHighlightTexture('Interface\\Buttons\\ButtonHilight-Square', 'ADD')
		button:RegisterForClicks('LeftButtonDown', 'RightButtonDown')
		button:SetPoint('TOPRIGHT', frame, 'TOPRIGHT', -65 - (index * 25), -42)
		button:SetSize(24, 24)
		button:SetID(index)

		if (index == 0) then
			bookmarkIcon(button, 'Interface\\Icons\\INV_Misc_Book_09')
			button.State = button:CreateTexture(nil, 'OVERLAY')
			button.State:SetSize(12, 12)
			button.State:SetPoint('BOTTOMRIGHT', -3, 3)
		else
			button:Hide()
		end

		button:SetScript('OnClick', function(self, mouse)
			local frame = self:GetParent()
			local prof
			if (frame == CraftFrame) then
				prof = GetCraftDisplaySkillLine()
				if (prof ~= 'Enchanting') then return end
			else
				prof = GetTradeSkillLine()
			end
			if not prof then return end

			local recipe
			if (frame == CraftFrame) then
				local index = GetCraftSelectionIndex()
				recipe = GetCraftInfo(index)
			else
				local index = GetTradeSkillSelectionIndex()
				recipe = GetTradeSkillInfo(index)
			end

			local saved = CTradeSkillDB['Bookmarks'][prof]
			if (self:GetID() == 0) then
				if tContains(saved, recipe) then
					for i = #saved, 1, -1 do
						if (saved[i] == recipe) then
							tremove(saved, i)
						end
					end
				else
					if (#saved < 10) then
						tinsert(saved, recipe)
					end
				end
				updateBookmarks(frame)
			else
				if (mouse == 'LeftButton') then
					local index = getRecipeIndex(saved[self:GetID()], frame)
					if index then
						if (frame == CraftFrame) then
							CraftListScrollFrameScrollBar:SetValue((index - 1) * 16)
							CraftFrame_SetSelection(index)
							CraftFrame_Update()
						else
							TradeSkillListScrollFrameScrollBar:SetValue((index - 1) * 16)
							TradeSkillFrame_SetSelection(index)
							TradeSkillFrame_Update()
						end
					end
				elseif (mouse == 'RightButton') then
					tremove(saved, self:GetID())
					updateBookmarks(frame)
				end
			end
		end)

		button:SetScript('OnEnter', function(self)
			local frame = self:GetParent()
			local prof
			if (frame == CraftFrame) then
				prof = GetCraftDisplaySkillLine()
				if (prof ~= 'Enchanting') then return end
			else
				prof = GetTradeSkillLine()
			end
			if not prof then return end

			local saved = CTradeSkillDB['Bookmarks'][prof]
			GameTooltip:SetOwner(self, 'ANCHOR_LEFT')
			if (self:GetID() > 0) then
				local index = getRecipeIndex(saved[self:GetID()], frame)
				if index then
					if (frame == CraftFrame) then
						GameTooltip:SetCraftSpell(index)
					else
						GameTooltip:SetTradeSkillItem(index)
					end
				end
			else
				local recipe
				if (frame == CraftFrame) then
					local index = GetCraftSelectionIndex()
					recipe = GetCraftInfo(index)
				else
					local index = GetTradeSkillSelectionIndex()
					recipe = GetTradeSkillInfo(index)
				end

				local selected = tContains(saved, recipe)
				GameTooltip:AddLine(selected and REMOVE or ADD, 1, 1, 1)
			end
			GameTooltip:Show()
		end)
		button:SetScript('OnLeave', function()
			GameTooltip:Hide()
		end)
	end

	--- Create Bookmarks ---
	local function createBookmarks(frame)
		for i = 0, 10 do
			addBookmark(i, frame)
		end

		local function hookFrame()
			updateBookmarks(frame)
		end
		hooksecurefunc(frame:GetName() .. '_Update', hookFrame)
	end

	--- Update Frame Position ---
	local function updatePosition()
		for _, frame in pairs({TradeSkillFrame, CraftFrame}) do
			if CTradeSkillDB['Unlock'] then
				UIPanelWindows[frame:GetName()].area = nil
				frame:ClearAllPoints()
				if CTradeSkillDB['OffsetX'] and CTradeSkillDB['OffsetY'] then
					frame:SetPoint('TOPLEFT', UIParent, 'BOTTOMLEFT', CTradeSkillDB['OffsetX'], CTradeSkillDB['OffsetY'])
				else
					frame:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', GetUIPanel('left') and 623 or 16, -116)
				end
			else
				UpdateUIPanelPositions(frame)
			end
		end
	end


--- Create Movable Bar ---
local createMoveBar = function(frame)
	local movBar = CreateFrame('Button', nil, frame)
	movBar:SetPoint('TOPRIGHT', frame, -37, -15)
	movBar:SetSize(610, 20)
	movBar:SetScript('OnMouseDown', function(_, button)
		if (button == 'LeftButton') then
			if CTradeSkillDB['Unlock'] then
				frame:SetMovable(true)
				frame:StartMoving()
			end
		elseif (button == 'RightButton') then
			if not UnitAffectingCombat('player') then
				CTradeSkillDB['OffsetX'] = nil
				CTradeSkillDB['OffsetY'] = nil
				updatePosition()
			end
		end
	end)
	movBar:SetScript('OnMouseUp', function(_, button)
		if (button == 'LeftButton') then
			frame:StopMovingOrSizing()
			frame:SetMovable(false)

			CTradeSkillDB['OffsetX'] = frame:GetLeft()
			CTradeSkillDB['OffsetY'] = frame:GetTop()
		end
	end)
end


--- Refresh TSRecipes ---
local function refreshRecipes(frame)
	local function hookFrame()
		if not frame and frame:IsShown() then return end

		local skillButton, scrollFrame, getSkillInfo
		if (frame == TradeSkillFrame) then
			skillButton = 'TradeSkillSkill'
			scrollFrame = TradeSkillListScrollFrame
			getSkillInfo = GetTradeSkillInfo
		elseif (frame == CraftFrame) then
			skillButton = 'Craft'
			scrollFrame = CraftListScrollFrame
			getSkillInfo = GetCraftInfo
		end

		for i = 1, CTradeSkillDB['Size'] do
			local button = _G[skillButton .. i]
			if button then
				--- Button Tooltip ---
				if not button.CTSTip then
					button:HookScript('OnEnter', function(self)
						if CTradeSkillDB['Tooltip'] then
							local frame = self:GetParent()
							if (frame == CraftFrame) then
								local prof = GetCraftDisplaySkillLine()
								if (prof ~= 'Enchanting') then return end
							end

							local offset = FauxScrollFrame_GetOffset(scrollFrame)
							local index = i + offset
							GameTooltip:SetOwner(self, 'ANCHOR_LEFT')
							if (frame == CraftFrame) then
								GameTooltip:SetCraftSpell(index)
							else
								GameTooltip:SetTradeSkillItem(index)
							end
						end
					end)
					button:HookScript('OnLeave', function()
						if CTradeSkillDB['Tooltip'] then
							GameTooltip:Hide()
						end
					end)
					button.CTSTip = true
				end

				--- Required Level ---
				if CTradeSkillDB['Level'] then
					if not button.CTSLevel then
						button.CTSLevel = button:CreateFontString(nil, 'ARTWORK', 'GameFontNormalSmall')
						button.CTSLevel:SetPoint('RIGHT', button, 'LEFT', 20, 2)
					end

					if (frame == CraftFrame) and (GetCraftDisplaySkillLine() ~= 'Enchanting') then
						button.CTSLevel:SetText('')
					else
						local offset = FauxScrollFrame_GetOffset(scrollFrame)
						local index = i + offset
						local recipe, hdr, quality, _, _, _, level = getSkillInfo(index)
						if recipe and level then
							if (level > 1) then
								button.CTSLevel:SetText(level)
								button.CTSLevel:SetTextColor(GetItemQualityColor(1))
							end
							button:SetText('      ' .. recipe)
						elseif recipe and (hdr ~= 'header') then
							local link = GetTradeSkillItemLink(index)
							if link then
								quality, _, level = select(3, GetItemInfo(link))
								if quality and level and level > 1 then
									button.CTSLevel:SetText(level)
									button.CTSLevel:SetTextColor(GetItemQualityColor(quality))
								else
									button.CTSLevel:SetText('')
								end
							end
						else
							button.CTSLevel:SetText('')
						end
					end
				else
					if button.CTSLevel then
						button.CTSLevel:SetText('')
					end
				end
			end
		end
	end
	hooksecurefunc(frame:GetName() .. '_Update', hookFrame)
end


--- Druid Unshapeshift ---
local function injectDruidButtons()
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
	injectMacro(TradeSkillCreateButton, CREATE_PROFESSION)
	injectMacro(TradeSkillCreateAllButton, CREATE_ALL)
end


--- Warning Dialog ---
StaticPopupDialogs['CTRADESKILL_WARNING'] = {
	text = UNLOCK_FRAME .. ' ' .. REQUIRES_RELOAD:lower() .. '!\n',
	button1 = ACCEPT,
	button2 = CANCEL,
	OnAccept = function()
		CTradeSkillDB['Unlock'] = not CTradeSkillDB['Unlock']
		ReloadUI()
	end,
	OnShow = function()
		_G['CTSOption-TradeSkillFrame']:Disable()
		if _G['CTSOption-CraftFrame'] then
			_G['CTSOption-CraftFrame']:Disable()
		end
	end,
	OnHide = function()
		_G['CTSOption-TradeSkillFrame']:Enable()
		if _G['CTSOption-CraftFrame'] then
			_G['CTSOption-CraftFrame']:Enable()
		end
	end,
	timeout = 0,
	exclusive = 1,
	preferredIndex = 3,
}


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

		info.text = UNLOCK_FRAME
		info.func = function()
			StaticPopup_Show('CTRADESKILL_WARNING')
		end
		info.checked = CTradeSkillDB['Unlock']
		UIDropDownMenu_AddButton(info, level)

		info.text = STAT_AVERAGE_ITEM_LEVEL
		info.func = function()
			CTradeSkillDB['Level'] = not CTradeSkillDB['Level']
			if CraftFrame then
				CraftFrame_Update()
			end
			TradeSkillFrame_Update()
		end
		info.keepShownOnClick = true
		info.checked = CTradeSkillDB['Level']
		UIDropDownMenu_AddButton(info, level)

		info.text = DISPLAY .. ' ' .. INFO
		info.func = function()
			CTradeSkillDB['Tooltip'] = not CTradeSkillDB['Tooltip']
		end
		info.keepShownOnClick = true
		info.checked = CTradeSkillDB['Tooltip']
		UIDropDownMenu_AddButton(info, level)

		info.func = nil
		info.checked = 	nil
		info.notCheckable = true
		info.hasArrow = true

		info.text = PRIMARY
		info.value = 1
		info.disabled = UnitAffectingCombat('player')
		UIDropDownMenu_AddButton(info, level)

		info.text = SECONDARY
		info.value = 2
		info.disabled = UnitAffectingCombat('player')
		UIDropDownMenu_AddButton(info, level)
	elseif level == 2 then
		info.isNotRadio = true
		info.keepShownOnClick = true
		if UIDROPDOWNMENU_MENU_VALUE == 1 then
			for i = 1, numTabs do
				local tab = _G['CTSTab-TradeSkillFrame_' .. i]
				if tab and (tab.isSub == 0) then
					info.text = tab.tooltip
					info.func = function()
						CTradeSkillDB['Tabs'][tab.tooltip] = not CTradeSkillDB['Tabs'][tab.tooltip]
						sortTabs()
					end
					info.checked = CTradeSkillDB['Tabs'][tab.tooltip]
					UIDropDownMenu_AddButton(info, level)
				end
			end
		elseif UIDROPDOWNMENU_MENU_VALUE == 2 then
			for i = 1, numTabs do
				local tab = _G['CTSTab-TradeSkillFrame_' .. i]
				if tab and (tab.isSub == 1) then
					info.text = tab.tooltip
					info.func = function()
						CTradeSkillDB['Tabs'][tab.tooltip] = not CTradeSkillDB['Tabs'][tab.tooltip]
						sortTabs()
					end
					info.checked = CTradeSkillDB['Tabs'][tab.tooltip]
					UIDropDownMenu_AddButton(info, level)
				end
			end
		end
	end
end


--- Create Option Menu ---
local function createOptions(frame)
	if not _G['CTSDropdown'] then
		local menu = CreateFrame('Frame', 'CTSDropdown', frame, 'UIDropDownMenuTemplate')
		UIDropDownMenu_Initialize(CTSDropdown, CTSDropdown_Init, 'MENU')
	end

	--- Option Button ---
	local button = CreateFrame('Button', 'CTSOption-' .. frame:GetName(), frame, 'UIPanelButtonTemplate')
	button:SetScript('OnClick', function(self) ToggleDropDownMenu(1, nil, CTSDropdown, self, 2, -6) end)
	button:SetPoint('RIGHT', _G[frame:GetName() .. 'CloseButton'], 'LEFT', 3.5, 0.4)
	button:SetFrameStrata('HIGH')
	button:SetText('CTS')
	button:SetSize(38, 22)

	if (skinUI == 'Aurora') then
		loadedUI.Reskin(button)
	elseif (skinUI == 'ElvUI') then
		button:StripTextures(true)
		button:CreateBackdrop('Default', true)
		button.backdrop:SetAllPoints()
	end
end


--- Force ESC Close ---
hooksecurefunc('ToggleGameMenu', function()
	if CTradeSkillDB['Unlock'] and TradeSkillFrame:IsShown() then
		CloseTradeSkill()
		HideUIPanel(GameMenuFrame)
	end
end)


--- Handle Events ---
f:SetScript('OnEvent', function(self, event, arg1)
	if (event == 'PLAYER_LOGIN') then
		InitDB()
		updatePosition()
		updateTabs(true)
		updateSize('TradeSkill')
		createMoveBar(TradeSkillFrame)
		createBookmarks(TradeSkillFrame)
		createOptions(TradeSkillFrame)
		refreshRecipes(TradeSkillFrame)
		injectDruidButtons()
	elseif (event == 'ADDON_LOADED') then
		if (arg1 == 'Blizzard_CraftUI') then
			if UnitAffectingCombat('player') then
				delay = true
			else
				updateTabs()
			end
			updateSize('Craft')
			createMoveBar(CraftFrame)
			createBookmarks(CraftFrame)
			createOptions(CraftFrame)
			refreshRecipes(CraftFrame)

			f:UnregisterEvent('ADDON_LOADED')
		end
	elseif (event == 'SPELLS_CHANGED') then
		if UnitAffectingCombat('player') then
			delay = true
		else
			updateTabs()
		end
	elseif (event == 'PLAYER_REGEN_ENABLED') then
		if delay then
			updateTabs()
			delay = false
		end
	end
end)
