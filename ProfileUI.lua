local _, RR = ...
local L = RR.L
local Theme = RR.Theme

local profileFields = {
	{ key = "raidtime", label = "RAIDTIME" },
	{ key = "progress", label = "PROGRESS" },
	{ key = "requirements", label = "REQUIREMENTS" },
	{ key = "contact", label = "CONTACT" },
	{ key = "backupcontacts", label = "BACKUP_CONTACTS" },
	{ key = "discord", label = "DISCORD" },
	{ key = "focus", label = "FOCUS" },
	{ key = "voice", label = "VOICE" },
	{ key = "website", label = "WEBSITE" },
	{ key = "about", label = "ABOUT" },
	{ key = "priority", label = "PRIORITY" },
}

local tokenList = {
	"$gname", "$glink", "$player", "$time",
	"$raidtime", "$progress", "$requirements", "$contacts", "$contact",
	"$backupcontacts", "$discord", "$focus", "$voice", "$website", "$about",
	"$priority", "$schedule", "$days",
	"$needs", "$roles", "$classes", "$activities",
}

local tokenHelpKeys = {
	["$gname"] = "TOKEN_HELP_GNAME",
	["$glink"] = "TOKEN_HELP_GLINK",
	["$player"] = "TOKEN_HELP_PLAYER",
	["$time"] = "TOKEN_HELP_TIME",
	["$raidtime"] = "TOKEN_HELP_RAIDTIME",
	["$progress"] = "TOKEN_HELP_PROGRESS",
	["$requirements"] = "TOKEN_HELP_REQUIREMENTS",
	["$contacts"] = "TOKEN_HELP_CONTACTS",
	["$contact"] = "TOKEN_HELP_CONTACT",
	["$backupcontacts"] = "TOKEN_HELP_BACKUPCONTACTS",
	["$discord"] = "TOKEN_HELP_DISCORD",
	["$focus"] = "TOKEN_HELP_FOCUS",
	["$voice"] = "TOKEN_HELP_VOICE",
	["$website"] = "TOKEN_HELP_WEBSITE",
	["$about"] = "TOKEN_HELP_ABOUT",
	["$priority"] = "TOKEN_HELP_PRIORITY",
	["$schedule"] = "TOKEN_HELP_SCHEDULE",
	["$days"] = "TOKEN_HELP_DAYS",
	["$needs"] = "TOKEN_HELP_NEEDS",
	["$roles"] = "TOKEN_HELP_ROLES",
	["$classes"] = "TOKEN_HELP_CLASSES",
	["$activities"] = "TOKEN_HELP_ACTIVITIES",
}

RR.messageTokens = tokenList
RR.tokenHelpKeys = tokenHelpKeys

local function CreateField(parent, labelText, x, y, width)
	local label = RR:CreateThemedLabel(parent, labelText, "GameFontHighlightSmall", Theme.muted)
	label:SetPoint("TOPLEFT", x, y)
	local edit = RR:CreateThemedInput(parent, width or 320, 30, false)
	edit:SetPoint("TOPLEFT", x, y - 20)
	return edit
end

local function AddPanelTitle(panel, text)
	local title = RR:CreateThemedLabel(panel, text, "GameFontNormal")
	title:SetPoint("TOPLEFT", 16, -14)
	return title
end

function RR:LoadProfileUIValues()
	if not self.profileUI or not self.db then
		return
	end

	for _, definition in ipairs(profileFields) do
		self.profileUI.fields[definition.key]:SetText(self.db.profile[definition.key] or "")
	end
	for _, key in ipairs(self.dayKeys) do
		self.profileUI.days[key]:SetChecked(self.db.schedule.days[key])
	end
	self.profileUI.startTime:SetText(self.db.schedule.startTime or "")
	self.profileUI.endTime:SetText(self.db.schedule.endTime or "")
	for _, key in ipairs(self.roleKeys) do
		self.profileUI.roles[key]:SetChecked(self.db.needs.roles[key])
	end
	for _, key in ipairs(self.classKeys) do
		self.profileUI.classes[key]:SetChecked(self.db.needs.classes[key])
		local saved = self.db.needs.specializations[key] or {}
		for specID, checkbox in pairs(self.profileUI.specializations[key] or {}) do
			checkbox:SetChecked(saved[specID] and true or false)
		end
	end
	for _, key in ipairs(self.activityKeys) do
		self.profileUI.activities[key]:SetChecked(self.db.needs.activities[key])
	end
end

function RR:SaveProfileUIValues()
	if not self.profileUI or not self.db then
		return
	end

	for _, definition in ipairs(profileFields) do
		self.db.profile[definition.key] = self.profileUI.fields[definition.key]:GetText() or ""
	end
	for _, key in ipairs(self.dayKeys) do
		self.db.schedule.days[key] = self.profileUI.days[key]:GetChecked() and true or false
	end
	self.db.schedule.startTime = self.profileUI.startTime:GetText() or ""
	self.db.schedule.endTime = self.profileUI.endTime:GetText() or ""
	for _, key in ipairs(self.roleKeys) do
		self.db.needs.roles[key] = self.profileUI.roles[key]:GetChecked() and true or false
	end
	for _, key in ipairs(self.classKeys) do
		self.db.needs.classes[key] = self.profileUI.classes[key]:GetChecked() and true or false
		self.db.needs.specializations[key] = self.db.needs.specializations[key] or {}
		for specID, checkbox in pairs(self.profileUI.specializations[key] or {}) do
			self.db.needs.specializations[key][specID] = checkbox:GetChecked() and true or false
		end
	end
	for _, key in ipairs(self.activityKeys) do
		self.db.needs.activities[key] = self.profileUI.activities[key]:GetChecked() and true or false
	end

	self:SetStatus(L.PROFILE_SAVED)
	self:RefreshPreview()
end

function RR:SetProfileTab(tabName)
	if not self.profileUI then
		return
	end
	local profileSelected = tabName == "profile"
	local recruitmentSelected = tabName == "recruitment"
	local classesSelected = tabName == "classes"
	self.profileUI.profilePage:SetShown(profileSelected)
	self.profileUI.recruitmentPage:SetShown(recruitmentSelected)
	self.profileUI.classesPage:SetShown(classesSelected)
	self:SetTabSelected(self.profileUI.profileTab, profileSelected)
	self:SetTabSelected(self.profileUI.recruitmentTab, recruitmentSelected)
	self:SetTabSelected(self.profileUI.classesTab, classesSelected)
	self.profileUI.activeTab = tabName
end

function RR:ShowProfileWindow()
	if not self.profileUI then
		self:CreateProfileWindow()
	end
	self:LoadProfileUIValues()
	self:OpenDialogFromMain(self.profileUI.frame)
end

function RR:CreateProfileWindow()
	local frame = self:CreateThemedWindow(
		"RecruitRelayProfileFrame",
		980,
		700,
		L.GUILD_PROFILE,
		L.PROFILE_DESCRIPTION
	)

	local tabBar = self:CreateThemedPanel(frame)
	tabBar:SetPoint("TOPLEFT", 22, -96)
	tabBar:SetSize(936, 44)
	local profileTab = self:CreateThemedButton(tabBar, L.PROFILE_TAB, 210, 32)
	profileTab:SetPoint("TOPLEFT", 6, -6)
	local recruitmentTab = self:CreateThemedButton(tabBar, L.RECRUITMENT_TAB, 230, 32)
	recruitmentTab:SetPoint("LEFT", profileTab, "RIGHT", 8, 0)
	local classesTab = self:CreateThemedButton(tabBar, L.CLASSES_TAB, 250, 32)
	classesTab:SetPoint("LEFT", recruitmentTab, "RIGHT", 8, 0)

	local profilePage = CreateFrame("Frame", nil, frame)
	profilePage:SetPoint("TOPLEFT", 22, -154)
	profilePage:SetSize(936, 468)
	local recruitmentPage = CreateFrame("Frame", nil, frame)
	recruitmentPage:SetPoint("TOPLEFT", 22, -154)
	recruitmentPage:SetSize(936, 468)
	local classesPage = CreateFrame("Frame", nil, frame)
	classesPage:SetPoint("TOPLEFT", 22, -154)
	classesPage:SetSize(936, 468)

	local fieldsPanel = self:CreateThemedPanel(profilePage)
	fieldsPanel:SetAllPoints()
	AddPanelTitle(fieldsPanel, L.GUILD_DETAILS)

	local fields = {}
	for index, definition in ipairs(profileFields) do
		local column = (index - 1) % 2
		local row = math.floor((index - 1) / 2)
		fields[definition.key] = CreateField(
			fieldsPanel,
			L[definition.label],
			18 + column * 455,
			-48 - row * 72,
			438
		)
	end

	local usePlayer = self:CreateThemedButton(fieldsPanel, L.USE_PLAYER, 145, 28)
	fields.contact:SetWidth(182)
	usePlayer:SetPoint("LEFT", fields.contact, "RIGHT", 10, 0)
	usePlayer:SetScript("OnClick", function()
		fields.contact:SetText(UnitName("player") or "")
	end)

	local schedulePanel = self:CreateThemedPanel(recruitmentPage)
	schedulePanel:SetPoint("TOPLEFT", 0, 0)
	schedulePanel:SetSize(936, 112)
	AddPanelTitle(schedulePanel, L.SCHEDULE)
	local days = {}
	for index, key in ipairs(self.dayKeys) do
		local checkbox = self:CreateThemedCheckbox(schedulePanel, L["DAY_" .. key:upper()], true)
		checkbox:SetPoint("TOPLEFT", 12 + (index - 1) * 108, -43)
		days[key] = checkbox
	end
	local startLabel = self:CreateThemedLabel(schedulePanel, L.START_TIME, "GameFontHighlightSmall", Theme.muted)
	startLabel:SetPoint("TOPLEFT", 16, -79)
	local startTime = self:CreateThemedInput(schedulePanel, 118, 27, false)
	startTime:SetPoint("LEFT", startLabel, "RIGHT", 10, 0)
	local endLabel = self:CreateThemedLabel(schedulePanel, L.END_TIME, "GameFontHighlightSmall", Theme.muted)
	endLabel:SetPoint("LEFT", startTime, "RIGHT", 24, 0)
	local endTime = self:CreateThemedInput(schedulePanel, 118, 27, false)
	endTime:SetPoint("LEFT", endLabel, "RIGHT", 10, 0)

	local rolesPanel = self:CreateThemedPanel(recruitmentPage)
	rolesPanel:SetPoint("TOPLEFT", 0, -126)
	rolesPanel:SetSize(456, 96)
	AddPanelTitle(rolesPanel, L.ROLES)
	local roles = {}
	for index, key in ipairs(self.roleKeys) do
		local checkbox = self:CreateThemedCheckbox(rolesPanel, L["ROLE_" .. key:upper()], true)
		local column = (index - 1) % 2
		local row = math.floor((index - 1) / 2)
		checkbox:SetPoint("TOPLEFT", 12 + column * 220, -42 - row * 28)
		roles[key] = checkbox
	end

	local activitiesPanel = self:CreateThemedPanel(recruitmentPage)
	activitiesPanel:SetPoint("TOPRIGHT", 0, -126)
	activitiesPanel:SetSize(466, 96)
	AddPanelTitle(activitiesPanel, L.ACTIVITIES)
	local activities = {}
	for index, key in ipairs(self.activityKeys) do
		local checkbox = self:CreateThemedCheckbox(activitiesPanel, L["ACTIVITY_" .. key:upper()], true)
		local column = (index - 1) % 2
		local row = math.floor((index - 1) / 2)
		checkbox:SetPoint("TOPLEFT", 12 + column * 226, -42 - row * 28)
		activities[key] = checkbox
	end

	local classesLinkPanel = self:CreateThemedPanel(recruitmentPage)
	classesLinkPanel:SetPoint("TOPLEFT", 0, -236)
	classesLinkPanel:SetSize(936, 112)
	AddPanelTitle(classesLinkPanel, L.CLASSES)
	local classHint = self:CreateThemedLabel(
		classesLinkPanel,
		L.SPECIALIZATIONS_HINT,
		"GameFontHighlightSmall",
		Theme.muted
	)
	classHint:SetPoint("TOPLEFT", 16, -44)
	local openClasses = self:CreateThemedButton(classesLinkPanel, L.OPEN_CLASSES_SPECS, 280, 34, "accent")
	openClasses:SetPoint("TOPRIGHT", -16, -38)
	openClasses:SetScript("OnClick", function()
		RR:SetProfileTab("classes")
	end)

	local classesPanel = self:CreateThemedPanel(classesPage)
	classesPanel:SetAllPoints()
	AddPanelTitle(classesPanel, L.CLASSES_TAB)
	local classesHint = self:CreateThemedLabel(
		classesPanel,
		L.SPECIALIZATIONS_HINT,
		"GameFontHighlightSmall",
		Theme.muted
	)
	classesHint:SetPoint("TOPRIGHT", -16, -15)
	local classes = {}
	local specializations = {}
	for index, key in ipairs(self.classKeys) do
		local classKey = key
		local column = (index - 1) % 3
		local row = math.floor((index - 1) / 3)
		local cell = self:CreateThemedPanel(classesPanel)
		cell:SetSize(294, 76)
		cell:SetPoint("TOPLEFT", 16 + column * 304, -48 - row * 82)
		cell:SetBackdropBorderColor(Theme.border[1], Theme.border[2], Theme.border[3], 0.55)

		local color = self.ClassColors[classKey] or Theme.text
		local label = self:CreateThemedLabel(cell, L["CLASS_" .. classKey:upper()], "GameFontHighlightSmall")
		label:SetPoint("TOPLEFT", 12, -10)
		label:SetWidth(244)
		label:SetWordWrap(false)
		label:SetTextColor(color[1], color[2], color[3], 1)

		local checkbox = CreateFrame("CheckButton", nil, cell, "UICheckButtonTemplate")
		checkbox:SetSize(24, 24)
		checkbox:SetPoint("TOPRIGHT", -8, -4)
		classes[classKey] = checkbox
		specializations[classKey] = {}

		local classSpecs = self:GetClassSpecializations(classKey)
		for specIndex, specialization in ipairs(classSpecs) do
			local specCheckbox = self:CreateThemedCheckbox(
				cell,
				specialization.name,
				true
			)
			local specColumn = (specIndex - 1) % 2
			local specRow = math.floor((specIndex - 1) / 2)
			specCheckbox:SetPoint("TOPLEFT", 8 + specColumn * 143, -34 - specRow * 24)
			specCheckbox.Text:SetWidth(108)
			specCheckbox.Text:SetWordWrap(false)
			specCheckbox.Text:SetJustifyH("LEFT")
			specCheckbox:SetScript("OnClick", function(self)
				if self:GetChecked() then
					checkbox:SetChecked(true)
				end
			end)
			specializations[classKey][specialization.id] = specCheckbox
		end

		checkbox:SetScript("OnClick", function(self)
			if not self:GetChecked() then
				for _, specCheckbox in pairs(specializations[classKey]) do
					specCheckbox:SetChecked(false)
				end
			end
		end)
	end

	profileTab:SetScript("OnClick", function()
		RR:SetProfileTab("profile")
	end)
	recruitmentTab:SetScript("OnClick", function()
		RR:SetProfileTab("recruitment")
	end)
	classesTab:SetScript("OnClick", function()
		RR:SetProfileTab("classes")
	end)

	local footerLine = frame:CreateTexture(nil, "ARTWORK")
	footerLine:SetColorTexture(Theme.border[1], Theme.border[2], Theme.border[3], 0.8)
	footerLine:SetPoint("BOTTOMLEFT", 1, 59)
	footerLine:SetPoint("BOTTOMRIGHT", -1, 59)
	footerLine:SetHeight(1)
	local save = self:CreateThemedButton(frame, L.SAVE, 124, 34, "accent")
	save:SetPoint("BOTTOMLEFT", 22, 14)
	save:SetScript("OnClick", function()
		RR:SaveProfileUIValues()
	end)
	local saveClose = self:CreateThemedButton(frame, L.SAVE_CLOSE, 160, 34)
	saveClose:SetPoint("BOTTOMRIGHT", -26, 14)
	saveClose:SetScript("OnClick", function()
		RR:SaveProfileUIValues()
		frame:Hide()
	end)

	frame:SetScript("OnShow", function()
		RR:LoadProfileUIValues()
	end)
	frame:SetScript("OnHide", function(self)
		RR:RestoreMainAfterDialog(self)
	end)
	frame:Hide()
	table.insert(UISpecialFrames, frame:GetName())

	self.profileUI = {
		frame = frame,
		profilePage = profilePage,
		recruitmentPage = recruitmentPage,
		classesPage = classesPage,
		profileTab = profileTab,
		recruitmentTab = recruitmentTab,
		classesTab = classesTab,
		fields = fields,
		days = days,
		startTime = startTime,
		endTime = endTime,
		roles = roles,
		classes = classes,
		specializations = specializations,
		activities = activities,
	}
	self:SetProfileTab("profile")
end

function RR:InsertMessageToken(token)
	if not self.ui or not self.ui.messageEdit then
		return
	end
	self.ui.messageEdit:Insert(token)
	self.ui.messageEdit:SetFocus()
end

function RR:ToggleTokenPalette()
	if not self.tokenFrame then
		self:CreateTokenPalette()
	end
	if not self.tokenFrame then
		return
	end
	if self.tokenFrame:IsShown() then
		self.tokenFrame:Hide()
	else
		self.tokenFrame:Show()
	end
end

function RR:CreateTokenPalette()
	if not self.ui or not self.ui.frame or not self.ui.messageEdit then
		return
	end

	local frame = self:CreateThemedPanel(self.ui.frame)
	frame:SetSize(884, 246)
	frame:SetPoint("TOPLEFT", self.ui.messageEdit, "BOTTOMLEFT", 0, -8)
	frame:SetFrameLevel(self.ui.frame:GetFrameLevel() + 30)
	frame:EnableMouse(true)

	local title = self:CreateThemedLabel(frame, L.TOKENS, "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", 14, -12)
	local hint = self:CreateThemedLabel(frame, L.TOKEN_DESCRIPTION, "GameFontHighlightSmall", Theme.muted)
	hint:SetPoint("LEFT", title, "RIGHT", 14, 0)
	local close = self:CreateThemedButton(frame, "×", 30, 28)
	close:SetPoint("TOPRIGHT", -8, -7)
	close:SetScript("OnClick", function()
		frame:Hide()
	end)

	for index, token in ipairs(tokenList) do
		local column = (index - 1) % 5
		local row = math.floor((index - 1) / 5)
		local button = self:CreateThemedButton(frame, token, 162, 30)
		button:SetPoint("TOPLEFT", 14 + column * 172, -44 - row * 34)
		button:SetScript("OnClick", function()
			RR:InsertMessageToken(token)
		end)
		button:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetText(token, Theme.accent[1], Theme.accent[2], Theme.accent[3])
			GameTooltip:AddLine(L[tokenHelpKeys[token]] or "", 0.88, 0.9, 0.96, true)
			GameTooltip:Show()
		end)
		button:SetScript("OnLeave", function()
			GameTooltip:Hide()
		end)
	end

	local optionalHelp = self:CreateThemedLabel(frame, L.OPTIONAL_HELP, "GameFontHighlightSmall", Theme.muted)
	optionalHelp:SetPoint("BOTTOMLEFT", 14, 10)
	optionalHelp:SetPoint("RIGHT", frame, "RIGHT", -14, 0)

	frame:SetScript("OnHide", function()
		GameTooltip:Hide()
	end)
	frame:Hide()
	self.tokenFrame = frame
end
