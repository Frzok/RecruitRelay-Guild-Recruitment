local _, RR = ...
local L = RR.L

local function CreateLabel(parent, text, size)
	local label = parent:CreateFontString(nil, "ARTWORK", size or "GameFontNormal")
	label:SetText(text)
	label:SetJustifyH("LEFT")
	return label
end

local function CreateCheckbox(parent, text)
	local checkbox = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
	checkbox.Text:SetText(text)
	checkbox.Text:SetFontObject("GameFontHighlight")
	return checkbox
end

local function CreateButton(parent, text, width)
	local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
	button:SetSize(width or 120, 24)
	button:SetText(text)
	return button
end

local function GetDraftLines(text)
	local lines = {}
	text = (text or ""):gsub("\r\n", "\n"):gsub("\r", "\n")
	for line in (text .. "\n"):gmatch("(.-)\n") do
		table.insert(lines, line)
	end
	while #lines > 0 and lines[#lines] == "" do
		table.remove(lines)
	end
	return lines
end

function RR:SetStatus(message)
	self.transientStatus = message
	if self.ui and self.ui.status then
		self.ui.status:SetText(message or self:GetStatusText())
	end
end

function RR:RefreshPreview()
	if not self.ui or not self.ui.messageEdit then
		return
	end

	local message = self.ui.messageEdit:GetText() or ""
	local expanded = self:ExpandMessage(message)
	local lines = GetDraftLines(expanded)
	local byteDetails = {}

	for index, line in ipairs(lines) do
		table.insert(byteDetails, ("%d: %d/255"):format(index, #line))
	end

	self.ui.preview:SetText(expanded ~= "" and expanded or " ")
	self.ui.byteCount:SetText(table.concat(byteDetails, "   "))

	local valid, errorMessage = self:ValidateMessage(message)
	if valid then
		self.ui.validation:SetTextColor(0.3, 1, 0.5)
		self.ui.validation:SetText(L.TEST_PREVIEW)
	else
		self.ui.validation:SetTextColor(1, 0.35, 0.35)
		self.ui.validation:SetText(errorMessage)
	end
end

function RR:LoadUIValues()
	if not self.ui or not self.db then
		return
	end

	self.ui.enabled:SetChecked(self.db.enabled)
	self.ui.messageEdit:SetText(self.db.message or "")
	self.ui.general:SetChecked(self.db.channels.general)
	self.ui.trade:SetChecked(self.db.channels.trade)
	self.ui.lfg:SetChecked(self.db.channels.lfg)
	self.ui.pauseCombat:SetChecked(self.db.pause.combat)
	self.ui.pauseInstance:SetChecked(self.db.pause.instance)
	self.ui.pauseAFK:SetChecked(self.db.pause.afk)
	self.ui.interval:SetValue(self.db.interval)
	self.ui.intervalValue:SetText(L.MINUTES:format(self.db.interval))
	self:RefreshPreview()
	self:SetStatus(self:GetStatusText())
end

function RR:SaveUIValues()
	local message = self.ui.messageEdit:GetText() or ""
	local valid, errorMessage = self:ValidateMessage(message)
	if not valid then
		self:SetStatus(errorMessage)
		return false
	end

	local anyChannel = self.ui.general:GetChecked()
		or self.ui.trade:GetChecked()
		or self.ui.lfg:GetChecked()
	if not anyChannel then
		self:SetStatus(L.STATUS_NO_CHANNEL)
		return false
	end

	self.db.enabled = self.ui.enabled:GetChecked() and true or false
	self.db.message = message
	self.db.channels.general = self.ui.general:GetChecked() and true or false
	self.db.channels.trade = self.ui.trade:GetChecked() and true or false
	self.db.channels.lfg = self.ui.lfg:GetChecked() and true or false
	self.db.pause.combat = self.ui.pauseCombat:GetChecked() and true or false
	self.db.pause.instance = self.ui.pauseInstance:GetChecked() and true or false
	self.db.pause.afk = self.ui.pauseAFK:GetChecked() and true or false
	self.db.interval = math.floor(self.ui.interval:GetValue() + 0.5)
	self:ResetTimer(true)
	self:SetStatus(L.STATUS_SAVED)
	return true
end

function RR:UpdateReadyButton()
	if not self.readyButton or not self.db then
		return
	end

	if self.pendingSend then
		local sentCount = self.pendingSend.total - #self.pendingSend.lines
		local nextLine = math.min(self.pendingSend.total, sentCount + 1)
		self.readyButton:SetText(L.SEND_LINE:format(nextLine, self.pendingSend.total))
		self.readyButton:Show()
	elseif self.ready then
		self.readyButton:SetText(L.CLICK_TO_SEND)
		self.readyButton:Show()
	else
		self.readyButton:Hide()
	end
end

function RR:UpdateAllUI()
	if not self.db then
		return
	end

	self:UpdateReadyButton()

	if self.ui and self.ui.frame:IsShown() then
		self.ui.status:SetText(self.transientStatus or self:GetStatusText())
		self:RefreshPreview()
	end
end

function RR:ShowMainWindow()
	if not self.ui then
		return
	end
	self.transientStatus = nil
	self:LoadUIValues()
	self.ui.frame:Show()
end

function RR:ToggleMainWindow()
	if self.ui.frame:IsShown() then
		self.ui.frame:Hide()
	else
		self:ShowMainWindow()
	end
end

function RR:CreateReadyButton()
	local button = CreateFrame("Button", "RecruitRelayReadyButton", UIParent, "UIPanelButtonTemplate")
	button:SetSize(230, 34)
	button:SetPoint("TOP", UIParent, "TOP", 0, -150)
	button:SetFrameStrata("DIALOG")
	button:SetClampedToScreen(true)
	button:SetMovable(true)
	button:RegisterForDrag("LeftButton")
	button:SetScript("OnDragStart", button.StartMoving)
	button:SetScript("OnDragStop", button.StopMovingOrSizing)
	button:SetScript("OnClick", function()
		RR:SendNextLine()
	end)
	button:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
		GameTooltip:AddLine(L.READY, 1, 0.82, 0)
		GameTooltip:AddLine(L.CLICK_TO_SEND, 1, 1, 1, true)
		GameTooltip:Show()
	end)
	button:SetScript("OnLeave", GameTooltip_Hide)
	button:Hide()
	self.readyButton = button
end

function RR:RegisterSettingsLauncher()
	if not Settings or not Settings.RegisterCanvasLayoutCategory then
		return
	end

	local panel = CreateFrame("Frame")
	panel.name = "RecruitRelay"

	local title = CreateLabel(panel, L.ADDON_NAME, "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", 16, -16)

	local description = CreateLabel(panel, L.DESCRIPTION, "GameFontHighlight")
	description:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -12)
	description:SetPoint("RIGHT", panel, "RIGHT", -24, 0)
	description:SetJustifyH("LEFT")

	local hint = CreateLabel(panel, L.SETTINGS_HINT, "GameFontHighlightSmall")
	hint:SetPoint("TOPLEFT", description, "BOTTOMLEFT", 0, -12)

	local openButton = CreateButton(panel, L.SETTINGS_BUTTON, 180)
	openButton:SetPoint("TOPLEFT", hint, "BOTTOMLEFT", 0, -18)
	openButton:SetScript("OnClick", function()
		RR:ShowMainWindow()
	end)

	local category = Settings.RegisterCanvasLayoutCategory(panel, "RecruitRelay")
	Settings.RegisterAddOnCategory(category)
	self.settingsCategoryID = category:GetID()
end

function RR:CreateUI()
	if self.ui then
		return
	end

	local frame = CreateFrame("Frame", "RecruitRelayMainFrame", UIParent, "BackdropTemplate")
	frame:SetSize(660, 650)
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

	local title = CreateLabel(frame, L.ADDON_NAME, "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", 24, -22)

	local description = CreateLabel(frame, L.DESCRIPTION, "GameFontHighlightSmall")
	description:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
	description:SetPoint("RIGHT", frame, "RIGHT", -30, 0)

	local close = CreateButton(frame, "×", 28)
	close:SetPoint("TOPRIGHT", -18, -16)
	close:SetScript("OnClick", function()
		frame:Hide()
	end)

	local enabled = CreateCheckbox(frame, L.ENABLED)
	enabled:SetPoint("TOPLEFT", description, "BOTTOMLEFT", -4, -16)

	local profileButton = CreateButton(frame, L.GUILD_PROFILE, 155)
	profileButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -190, -77)
	profileButton:SetScript("OnClick", function()
		RR:ShowProfileWindow()
	end)

	local tokensButton = CreateButton(frame, L.TOKENS, 110)
	tokensButton:SetPoint("LEFT", profileButton, "RIGHT", 8, 0)
	tokensButton:SetScript("OnClick", function()
		RR:ToggleTokenPalette()
	end)

	local messageLabel = CreateLabel(frame, L.MESSAGE, "GameFontNormal")
	messageLabel:SetPoint("TOPLEFT", enabled, "BOTTOMLEFT", 4, -18)

	local messageHelp = CreateLabel(frame, L.MESSAGE_HELP, "GameFontHighlightSmall")
	messageHelp:SetPoint("TOPLEFT", messageLabel, "BOTTOMLEFT", 0, -4)

	local messageBorder = CreateFrame("Frame", nil, frame, "BackdropTemplate")
	messageBorder:SetPoint("TOPLEFT", messageHelp, "BOTTOMLEFT", 0, -8)
	messageBorder:SetSize(600, 92)
	messageBorder:SetBackdrop({
		bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true,
		tileSize = 16,
		edgeSize = 12,
		insets = { left = 3, right = 3, top = 3, bottom = 3 },
	})
	messageBorder:SetBackdropColor(0.03, 0.03, 0.03, 0.9)

	local messageScroll = CreateFrame("ScrollFrame", nil, messageBorder, "UIPanelScrollFrameTemplate")
	messageScroll:SetPoint("TOPLEFT", 8, -8)
	messageScroll:SetPoint("BOTTOMRIGHT", -28, 8)

	local messageEdit = CreateFrame("EditBox", nil, messageScroll)
	messageEdit:SetMultiLine(true)
	messageEdit:SetAutoFocus(false)
	messageEdit:SetFontObject("ChatFontNormal")
	messageEdit:SetWidth(555)
	messageEdit:SetHeight(74)
	messageEdit:SetTextInsets(2, 2, 2, 2)
	messageEdit:SetScript("OnEscapePressed", function(self)
		self:ClearFocus()
	end)
	messageEdit:SetScript("OnTextChanged", function()
		RR:RefreshPreview()
	end)
	messageScroll:SetScrollChild(messageEdit)

	local channelsLabel = CreateLabel(frame, L.CHANNELS, "GameFontNormal")
	channelsLabel:SetPoint("TOPLEFT", messageBorder, "BOTTOMLEFT", 0, -18)

	local trade = CreateCheckbox(frame, L.TRADE)
	trade:SetPoint("TOPLEFT", channelsLabel, "BOTTOMLEFT", -4, -6)
	local lfg = CreateCheckbox(frame, L.LFG)
	lfg:SetPoint("LEFT", trade, "RIGHT", 145, 0)
	local general = CreateCheckbox(frame, L.GENERAL)
	general:SetPoint("LEFT", lfg, "RIGHT", 175, 0)

	local intervalLabel = CreateLabel(frame, L.INTERVAL, "GameFontNormal")
	intervalLabel:SetPoint("TOPLEFT", trade, "BOTTOMLEFT", 4, -20)

	local interval = CreateFrame("Slider", "RecruitRelayIntervalSlider", frame, "OptionsSliderTemplate")
	interval:SetPoint("TOPLEFT", intervalLabel, "BOTTOMLEFT", 4, -16)
	interval:SetSize(280, 18)
	interval:SetMinMaxValues(5, 60)
	interval:SetValueStep(1)
	interval:SetObeyStepOnDrag(true)
	_G[interval:GetName() .. "Low"]:SetText("5")
	_G[interval:GetName() .. "High"]:SetText("60")
	_G[interval:GetName() .. "Text"]:SetText("")

	local intervalValue = CreateLabel(frame, "", "GameFontHighlight")
	intervalValue:SetPoint("LEFT", interval, "RIGHT", 18, 0)
	interval:SetScript("OnValueChanged", function(_, value)
		intervalValue:SetText(L.MINUTES:format(math.floor(value + 0.5)))
	end)

	local safetyLabel = CreateLabel(frame, L.SAFETY, "GameFontNormal")
	safetyLabel:SetPoint("TOPLEFT", interval, "BOTTOMLEFT", -4, -24)

	local pauseCombat = CreateCheckbox(frame, L.PAUSE_COMBAT)
	pauseCombat:SetPoint("TOPLEFT", safetyLabel, "BOTTOMLEFT", -4, -6)
	local pauseInstance = CreateCheckbox(frame, L.PAUSE_INSTANCE)
	pauseInstance:SetPoint("TOPLEFT", pauseCombat, "BOTTOMLEFT", 0, -2)
	local pauseAFK = CreateCheckbox(frame, L.PAUSE_AFK)
	pauseAFK:SetPoint("TOPLEFT", pauseInstance, "BOTTOMLEFT", 0, -2)

	local previewLabel = CreateLabel(frame, L.PREVIEW, "GameFontNormal")
	previewLabel:SetPoint("TOPLEFT", pauseAFK, "BOTTOMLEFT", 4, -18)

	local previewBorder = CreateFrame("Frame", nil, frame, "BackdropTemplate")
	previewBorder:SetPoint("TOPLEFT", previewLabel, "BOTTOMLEFT", 0, -8)
	previewBorder:SetSize(600, 88)
	previewBorder:SetBackdrop({
		bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true,
		tileSize = 16,
		edgeSize = 12,
		insets = { left = 3, right = 3, top = 3, bottom = 3 },
	})
	previewBorder:SetBackdropColor(0.02, 0.02, 0.02, 0.85)

	local preview = CreateLabel(previewBorder, "", "ChatFontNormal")
	preview:SetPoint("TOPLEFT", 10, -10)
	preview:SetPoint("RIGHT", previewBorder, "RIGHT", -10, 0)
	preview:SetJustifyH("LEFT")
	preview:SetJustifyV("TOP")

	local byteCount = CreateLabel(frame, "", "GameFontHighlightSmall")
	byteCount:SetPoint("TOPLEFT", previewBorder, "BOTTOMLEFT", 0, -4)

	local validation = CreateLabel(frame, "", "GameFontHighlightSmall")
	validation:SetPoint("TOPLEFT", byteCount, "BOTTOMLEFT", 0, -4)
	validation:SetPoint("RIGHT", frame, "RIGHT", -30, 0)

	local status = CreateLabel(frame, "", "GameFontHighlight")
	status:SetPoint("BOTTOMLEFT", 26, 54)
	status:SetPoint("RIGHT", frame, "RIGHT", -26, 0)
	status:SetTextColor(1, 0.82, 0)

	local save = CreateButton(frame, L.SAVE, 110)
	save:SetPoint("BOTTOMLEFT", 24, 20)
	save:SetScript("OnClick", function()
		RR:SaveUIValues()
	end)

	local reset = CreateButton(frame, L.RESET_TIMER, 130)
	reset:SetPoint("LEFT", save, "RIGHT", 8, 0)
	reset:SetScript("OnClick", function()
		if RR:SaveUIValues() then
			RR:ResetTimer(false)
		end
	end)

	local sendNow = CreateButton(frame, L.SEND_NOW, 135)
	sendNow:SetPoint("LEFT", reset, "RIGHT", 8, 0)
	sendNow:SetScript("OnClick", function()
		if RR:SaveUIValues() then
			local prepared, errorMessage = RR:PrepareSend(true)
			if not prepared then
				RR:SetStatus(errorMessage)
			else
				RR:SendNextLine()
			end
		end
	end)

	local closeBottom = CreateButton(frame, L.CLOSE, 90)
	closeBottom:SetPoint("BOTTOMRIGHT", -24, 20)
	closeBottom:SetScript("OnClick", function()
		frame:Hide()
	end)

	frame:SetScript("OnShow", function()
		RR:LoadUIValues()
	end)
	frame:Hide()

	table.insert(UISpecialFrames, frame:GetName())

	self.ui = {
		frame = frame,
		enabled = enabled,
		messageEdit = messageEdit,
		general = general,
		trade = trade,
		lfg = lfg,
		interval = interval,
		intervalValue = intervalValue,
		pauseCombat = pauseCombat,
		pauseInstance = pauseInstance,
		pauseAFK = pauseAFK,
		preview = preview,
		byteCount = byteCount,
		validation = validation,
		status = status,
	}

	self:CreateReadyButton()
	self:RegisterSettingsLauncher()
	self:LoadUIValues()
end
