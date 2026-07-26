local _, RR = ...
local L = RR.L

local profileFields = {
	{ key = "raidtime", label = "RAIDTIME" },
	{ key = "progress", label = "PROGRESS" },
	{ key = "requirements", label = "REQUIREMENTS" },
	{ key = "contact", label = "CONTACT" },
	{ key = "backupcontacts", label = "BACKUP_CONTACTS" },
	{ key = "discord", label = "DISCORD" },
	{ key = "language", label = "LANGUAGE" },
	{ key = "timezone", label = "TIMEZONE" },
	{ key = "region", label = "REGION" },
	{ key = "focus", label = "FOCUS" },
	{ key = "voice", label = "VOICE" },
	{ key = "website", label = "WEBSITE" },
	{ key = "age", label = "AGE" },
	{ key = "loot", label = "LOOT" },
	{ key = "about", label = "ABOUT" },
	{ key = "priority", label = "PRIORITY" },
}

local tokenList = {
	"$gname", "$glink", "$realm", "$faction", "$player",
	"$online", "$members", "$time", "$date",
	"$raidtime", "$progress", "$requirements", "$contacts", "$contact",
	"$backupcontacts", "$discord", "$language", "$timezone", "$region",
	"$focus", "$voice", "$website", "$age", "$loot", "$about",
	"$priority", "$schedule", "$days", "$starttime", "$endtime",
	"$needs", "$roles", "$classes", "$activities",
}

local function CreateLabel(parent, text, font)
	local label = parent:CreateFontString(nil, "ARTWORK", font or "GameFontNormal")
	label:SetText(text)
	label:SetJustifyH("LEFT")
	return label
end

local function CreateButton(parent, text, width)
	local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
	button:SetSize(width or 120, 24)
	button:SetText(text)
	return button
end

local function CreateCheckbox(parent, text)
	local checkbox = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
	checkbox.Text:SetText(text)
	checkbox.Text:SetFontObject("GameFontHighlightSmall")
	return checkbox
end

local function CreateEditField(parent, labelText, x, y, width)
	local label = CreateLabel(parent, labelText, "GameFontHighlightSmall")
	label:SetPoint("TOPLEFT", x, y)

	local edit = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
	edit:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 4, -3)
	edit:SetSize(width or 320, 24)
	edit:SetAutoFocus(false)
	edit:SetScript("OnEscapePressed", function(self)
		self:ClearFocus()
	end)
	return edit
end

local function CreateSectionTitle(parent, text, y)
	local label = CreateLabel(parent, text, "GameFontNormalLarge")
	label:SetPoint("TOPLEFT", 8, y)
	return label
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
	end
	for _, key in ipairs(self.activityKeys) do
		self.db.needs.activities[key] = self.profileUI.activities[key]:GetChecked() and true or false
	end

	self:SetStatus(L.PROFILE_SAVED)
	self:RefreshPreview()
end

function RR:ShowProfileWindow()
	if not self.profileUI then
		self:CreateProfileWindow()
	end
	self:LoadProfileUIValues()
	self.profileUI.frame:Show()
end

function RR:CreateProfileWindow()
	local frame = CreateFrame("Frame", "RecruitRelayProfileFrame", UIParent, "BackdropTemplate")
	frame:SetSize(780, 720)
	frame:SetPoint("CENTER")
	frame:SetFrameStrata("DIALOG")
	frame:SetClampedToScreen(true)
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
	frame:SetBackdrop({
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		tile = true,
		tileSize = 24,
		edgeSize = 24,
		insets = { left = 8, right = 8, top = 8, bottom = 8 },
	})

	local title = CreateLabel(frame, L.GUILD_PROFILE, "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", 24, -22)

	local description = CreateLabel(frame, L.PROFILE_DESCRIPTION, "GameFontHighlightSmall")
	description:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -5)

	local close = CreateButton(frame, "×", 28)
	close:SetPoint("TOPRIGHT", -18, -16)
	close:SetScript("OnClick", function()
		frame:Hide()
	end)

	local scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
	scroll:SetPoint("TOPLEFT", 22, -68)
	scroll:SetPoint("BOTTOMRIGHT", -42, 62)

	local content = CreateFrame("Frame", nil, scroll)
	content:SetSize(710, 940)
	scroll:SetScrollChild(content)

	local fields = {}
	for index, definition in ipairs(profileFields) do
		local column = (index - 1) % 2
		local row = math.floor((index - 1) / 2)
		fields[definition.key] = CreateEditField(
			content,
			L[definition.label],
			8 + column * 350,
			-8 - row * 54,
			325
		)
	end

	local usePlayer = CreateButton(content, L.USE_PLAYER, 170)
	fields.contact:SetWidth(145)
	usePlayer:SetPoint("LEFT", fields.contact, "RIGHT", 8, 0)
	usePlayer:SetScript("OnClick", function()
		fields.contact:SetText(UnitName("player") or "")
	end)

	CreateSectionTitle(content, L.SCHEDULE, -450)

	local days = {}
	for index, key in ipairs(self.dayKeys) do
		local checkbox = CreateCheckbox(content, L["DAY_" .. key:upper()])
		checkbox:SetPoint("TOPLEFT", 4 + (index - 1) * 94, -480)
		days[key] = checkbox
	end

	local startTime = CreateEditField(content, L.START_TIME, 8, -522, 145)
	local endTime = CreateEditField(content, L.END_TIME, 190, -522, 145)

	CreateSectionTitle(content, L.RECRUITMENT_NEEDS, -590)

	local rolesLabel = CreateLabel(content, L.ROLES, "GameFontNormal")
	rolesLabel:SetPoint("TOPLEFT", 8, -622)
	local roles = {}
	for index, key in ipairs(self.roleKeys) do
		local checkbox = CreateCheckbox(content, L["ROLE_" .. key:upper()])
		checkbox:SetPoint("TOPLEFT", 4 + (index - 1) * 170, -646)
		roles[key] = checkbox
	end

	local classesLabel = CreateLabel(content, L.CLASSES, "GameFontNormal")
	classesLabel:SetPoint("TOPLEFT", 8, -686)
	local classes = {}
	for index, key in ipairs(self.classKeys) do
		local column = (index - 1) % 4
		local row = math.floor((index - 1) / 4)
		local checkbox = CreateCheckbox(content, L["CLASS_" .. key:upper()])
		checkbox:SetPoint("TOPLEFT", 4 + column * 170, -710 - row * 28)
		classes[key] = checkbox
	end

	local activitiesLabel = CreateLabel(content, L.ACTIVITIES, "GameFontNormal")
	activitiesLabel:SetPoint("TOPLEFT", 8, -830)
	local activities = {}
	for index, key in ipairs(self.activityKeys) do
		local checkbox = CreateCheckbox(content, L["ACTIVITY_" .. key:upper()])
		checkbox:SetPoint("TOPLEFT", 4 + (index - 1) * 170, -854)
		activities[key] = checkbox
	end

	local save = CreateButton(frame, L.SAVE, 120)
	save:SetPoint("BOTTOMLEFT", 24, 22)
	save:SetScript("OnClick", function()
		RR:SaveProfileUIValues()
	end)

	local saveClose = CreateButton(frame, L.SAVE_CLOSE, 150)
	saveClose:SetPoint("BOTTOMRIGHT", -24, 22)
	saveClose:SetScript("OnClick", function()
		RR:SaveProfileUIValues()
		frame:Hide()
	end)

	frame:SetScript("OnShow", function()
		RR:LoadProfileUIValues()
	end)
	frame:Hide()
	table.insert(UISpecialFrames, frame:GetName())

	self.profileUI = {
		frame = frame,
		fields = fields,
		days = days,
		startTime = startTime,
		endTime = endTime,
		roles = roles,
		classes = classes,
		activities = activities,
	}
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
	if self.tokenFrame:IsShown() then
		self.tokenFrame:Hide()
	else
		self.tokenFrame:Show()
	end
end

function RR:CreateTokenPalette()
	local frame = CreateFrame("Frame", "RecruitRelayTokenFrame", UIParent, "BackdropTemplate")
	frame:SetSize(630, 385)
	frame:SetPoint("CENTER")
	frame:SetFrameStrata("DIALOG")
	frame:SetClampedToScreen(true)
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
	frame:SetBackdrop({
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		tile = true,
		tileSize = 24,
		edgeSize = 24,
		insets = { left = 8, right = 8, top = 8, bottom = 8 },
	})

	local title = CreateLabel(frame, L.TOKENS, "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", 24, -22)
	local description = CreateLabel(frame, L.TOKEN_DESCRIPTION, "GameFontHighlightSmall")
	description:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -5)

	for index, token in ipairs(tokenList) do
		local column = (index - 1) % 4
		local row = math.floor((index - 1) / 4)
		local button = CreateButton(frame, token, 140)
		button:SetPoint("TOPLEFT", 24 + column * 148, -72 - row * 28)
		button:SetScript("OnClick", function()
			RR:InsertMessageToken(token)
		end)
	end

	local optionalHelp = CreateLabel(frame, L.OPTIONAL_HELP, "GameFontHighlightSmall")
	optionalHelp:SetPoint("BOTTOMLEFT", 24, 22)
	optionalHelp:SetPoint("RIGHT", frame, "RIGHT", -55, 0)
	optionalHelp:SetTextColor(1, 0.82, 0)

	local close = CreateButton(frame, "×", 28)
	close:SetPoint("TOPRIGHT", -18, -16)
	close:SetScript("OnClick", function()
		frame:Hide()
	end)

	frame:Hide()
	table.insert(UISpecialFrames, frame:GetName())
	self.tokenFrame = frame
end
