local _, RR = ...
local L = RR.L
local Theme = RR.Theme

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

local function AddPanelTitle(panel, text)
	local title = RR:CreateThemedLabel(panel, text, "GameFontNormal")
	title:SetPoint("TOPLEFT", 16, -14)
	return title
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
		self.ui.validation:SetTextColor(Theme.accent[1], Theme.accent[2], Theme.accent[3], 1)
		self.ui.validation:SetText(L.TEST_PREVIEW)
	else
		self.ui.validation:SetTextColor(1, 0.3, 0.3, 1)
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
	self.ui.queueNotice:SetText(
		self:IsMessageQueueAvailable() and L.MESSAGE_QUEUE_ACTIVE or L.HARDWARE_NOTICE
	)
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

	if self.pendingSend and self.pendingSend.queued then
		self.readyButton:Hide()
		self.disableAnnouncementsButton:Show()
	elseif self.pendingSend then
		local sentCount = self.pendingSend.total - #self.pendingSend.lines
		local nextLine = math.min(self.pendingSend.total, sentCount + 1)
		self.readyButton.label:SetText(L.SEND_LINE:format(nextLine, self.pendingSend.total))
		self.readyButton:Show()
		self.disableAnnouncementsButton:Show()
	elseif self.ready then
		self.readyButton.label:SetText(L.CLICK_TO_SEND)
		self.readyButton:Show()
		self.disableAnnouncementsButton:Show()
	else
		self.readyButton:Hide()
		self.disableAnnouncementsButton:Hide()
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

function RR:OpenDialogFromMain(dialog)
	if not dialog then
		return
	end

	dialog.returnToMain = self.ui and self.ui.frame:IsShown() or false
	if dialog.returnToMain then
		self.ui.frame:Hide()
	end
	dialog:Show()
end

function RR:RestoreMainAfterDialog(dialog)
	if not dialog or not dialog.returnToMain or not self.ui then
		return
	end

	dialog.returnToMain = false
	self.preserveMainDraftOnShow = true
	self.ui.frame:Show()
end

function RR:CreateReadyButton()
	local button = self:CreateThemedButton(UIParent, L.CLICK_TO_SEND, 240, 38, "accent")
	button:SetPoint("TOP", UIParent, "TOP", -85, -145)
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
		GameTooltip:AddLine(L.READY, Theme.accent[1], Theme.accent[2], Theme.accent[3])
		GameTooltip:AddLine(L.CLICK_TO_SEND, 1, 1, 1, true)
		GameTooltip:Show()
	end)
	button:SetScript("OnLeave", GameTooltip_Hide)
	button:Hide()
	self.readyButton = button

	local disableButton = self:CreateThemedButton(UIParent, L.DISABLE_ANNOUNCEMENTS, 190, 38, "danger")
	disableButton:SetPoint("LEFT", button, "RIGHT", 10, 0)
	disableButton:SetFrameStrata("DIALOG")
	disableButton:SetClampedToScreen(true)
	disableButton:SetScript("OnClick", function()
		RR:SetAnnouncementsEnabled(false)
	end)
	disableButton:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
		GameTooltip:AddLine(L.DISABLE_ANNOUNCEMENTS, 1, 0.35, 0.35)
		GameTooltip:AddLine(L.DISABLE_ANNOUNCEMENTS_HELP, 1, 1, 1, true)
		GameTooltip:Show()
	end)
	disableButton:SetScript("OnLeave", GameTooltip_Hide)
	disableButton:Hide()
	self.disableAnnouncementsButton = disableButton
end

function RR:RegisterSettingsLauncher()
	if not Settings or not Settings.RegisterCanvasLayoutCategory then
		return
	end

	local panel = CreateFrame("Frame")
	panel.name = "RecruitRelay"
	local title = self:CreateThemedLabel(panel, L.ADDON_NAME, "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", 16, -16)
	local description = self:CreateThemedLabel(panel, L.DESCRIPTION, "GameFontHighlight", Theme.muted)
	description:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -12)
	description:SetPoint("RIGHT", panel, "RIGHT", -24, 0)
	local openButton = self:CreateThemedButton(panel, L.SETTINGS_BUTTON, 190, 34, "accent")
	openButton:SetPoint("TOPLEFT", description, "BOTTOMLEFT", 0, -20)
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

	local frame = self:CreateThemedWindow(
		"RecruitRelayMainFrame",
		940,
		700,
		L.SHORT_NAME,
		L.DESCRIPTION
	)

	local navBar = self:CreateThemedPanel(frame)
	navBar:SetPoint("TOPLEFT", 22, -96)
	navBar:SetSize(896, 44)

	local announcementsNav = self:CreateThemedButton(navBar, L.ANNOUNCEMENTS, 176, 32, "accent")
	announcementsNav:SetPoint("TOPLEFT", 6, -6)
	local profileNav = self:CreateThemedButton(navBar, L.GUILD_PROFILE, 176, 32)
	profileNav:SetPoint("LEFT", announcementsNav, "RIGHT", 8, 0)
	profileNav:SetScript("OnClick", function()
		RR:ShowProfileWindow()
	end)
	local tokensNav = self:CreateThemedButton(navBar, L.TOKENS, 130, 32)
	tokensNav:SetPoint("LEFT", profileNav, "RIGHT", 8, 0)
	tokensNav:SetScript("OnClick", function()
		RR:ToggleTokenPalette()
	end)

	local limitation = self:CreateThemedLabel(navBar, L.HARDWARE_NOTICE, "GameFontHighlightSmall", Theme.muted)
	limitation:SetPoint("LEFT", tokensNav, "RIGHT", 18, 0)
	limitation:SetPoint("RIGHT", navBar, "RIGHT", -12, 0)
	limitation:SetJustifyH("RIGHT")

	local pageTitle = self:CreateThemedLabel(frame, L.ANNOUNCEMENTS, "GameFontNormalLarge")
	pageTitle:SetPoint("TOPLEFT", 28, -158)
	local pageHint = self:CreateThemedLabel(frame, L.ANNOUNCEMENTS_DESCRIPTION, "GameFontHighlightSmall", Theme.muted)
	pageHint:SetPoint("TOPLEFT", pageTitle, "BOTTOMLEFT", 0, -6)

	local enabled = self:CreateThemedCheckbox(frame, L.ENABLED)
	enabled:SetPoint("TOPLEFT", 716, -158)

	local messageLabel = self:CreateThemedLabel(frame, L.MESSAGE, "GameFontNormal")
	messageLabel:SetPoint("TOPLEFT", 28, -208)
	local messageHelp = self:CreateThemedLabel(frame, L.MESSAGE_HELP, "GameFontHighlightSmall", Theme.muted)
	messageHelp:SetPoint("TOPLEFT", messageLabel, "BOTTOMLEFT", 0, -5)

	local messageEdit = self:CreateThemedInput(frame, 884, 90, true)
	messageEdit:SetPoint("TOPLEFT", 28, -247)
	messageEdit:SetMaxLetters(510)
	messageEdit:SetScript("OnTextChanged", function()
		RR:RefreshPreview()
	end)

	local channelsPanel = self:CreateThemedPanel(frame)
	channelsPanel:SetPoint("TOPLEFT", 28, -351)
	channelsPanel:SetSize(430, 92)
	AddPanelTitle(channelsPanel, L.CHANNELS)
	local trade = self:CreateThemedCheckbox(channelsPanel, L.TRADE, true)
	trade:SetPoint("TOPLEFT", 12, -46)
	local lfg = self:CreateThemedCheckbox(channelsPanel, L.LFG, true)
	lfg:SetPoint("TOPLEFT", 138, -46)
	local general = self:CreateThemedCheckbox(channelsPanel, L.GENERAL, true)
	general:SetPoint("TOPLEFT", 304, -46)

	local intervalPanel = self:CreateThemedPanel(frame)
	intervalPanel:SetPoint("TOPLEFT", 472, -351)
	intervalPanel:SetSize(440, 92)
	AddPanelTitle(intervalPanel, L.INTERVAL)
	local interval = CreateFrame("Slider", "RecruitRelayIntervalSlider", intervalPanel, "OptionsSliderTemplate")
	interval:SetPoint("TOPLEFT", 18, -55)
	interval:SetSize(300, 18)
	interval:SetMinMaxValues(5, 60)
	interval:SetValueStep(1)
	interval:SetObeyStepOnDrag(true)
	_G[interval:GetName() .. "Low"]:SetText("5")
	_G[interval:GetName() .. "High"]:SetText("60")
	_G[interval:GetName() .. "Text"]:SetText("")
	local intervalValue = self:CreateThemedLabel(intervalPanel, "", "GameFontHighlight")
	intervalValue:SetPoint("LEFT", interval, "RIGHT", 16, 0)
	interval:SetScript("OnValueChanged", function(_, value)
		intervalValue:SetText(L.MINUTES:format(math.floor(value + 0.5)))
	end)

	local safetyPanel = self:CreateThemedPanel(frame)
	safetyPanel:SetPoint("TOPLEFT", 28, -457)
	safetyPanel:SetSize(430, 122)
	AddPanelTitle(safetyPanel, L.SAFETY)
	local pauseCombat = self:CreateThemedCheckbox(safetyPanel, L.PAUSE_COMBAT, true)
	pauseCombat:SetPoint("TOPLEFT", 12, -42)
	local pauseInstance = self:CreateThemedCheckbox(safetyPanel, L.PAUSE_INSTANCE, true)
	pauseInstance:SetPoint("TOPLEFT", 12, -72)
	local pauseAFK = self:CreateThemedCheckbox(safetyPanel, L.PAUSE_AFK, true)
	pauseAFK:SetPoint("TOPLEFT", 12, -102)

	local previewPanel = self:CreateThemedPanel(frame)
	previewPanel:SetPoint("TOPLEFT", 472, -457)
	previewPanel:SetSize(440, 122)
	AddPanelTitle(previewPanel, L.PREVIEW)
	local preview = self:CreateThemedLabel(previewPanel, "", "ChatFontNormal")
	preview:SetPoint("TOPLEFT", 16, -42)
	preview:SetPoint("RIGHT", -16, 0)
	preview:SetHeight(58)
	preview:SetJustifyV("TOP")
	local byteCount = self:CreateThemedLabel(previewPanel, "", "GameFontHighlightSmall", Theme.muted)
	byteCount:SetPoint("BOTTOMLEFT", 16, 12)

	local validation = self:CreateThemedLabel(frame, "", "GameFontHighlightSmall", Theme.muted)
	validation:SetPoint("TOPLEFT", 472, -588)
	validation:SetPoint("RIGHT", frame, "RIGHT", -28, 0)

	local statusPanel = self:CreateThemedPanel(frame)
	statusPanel:SetPoint("BOTTOMLEFT", 28, 62)
	statusPanel:SetSize(884, 36)
	local status = self:CreateThemedLabel(statusPanel, "", "GameFontHighlight")
	status:SetPoint("LEFT", 16, 0)
	status:SetPoint("RIGHT", -16, 0)
	status:SetTextColor(Theme.accent[1], Theme.accent[2], Theme.accent[3], 1)

	local footerLine = frame:CreateTexture(nil, "ARTWORK")
	footerLine:SetColorTexture(Theme.border[1], Theme.border[2], Theme.border[3], 0.8)
	footerLine:SetPoint("BOTTOMLEFT", 1, 59)
	footerLine:SetPoint("BOTTOMRIGHT", -1, 59)
	footerLine:SetHeight(1)

	local save = self:CreateThemedButton(frame, L.SAVE, 118, 34, "accent")
	save:SetPoint("BOTTOMLEFT", 28, 14)
	save:SetScript("OnClick", function()
		RR:SaveUIValues()
	end)
	local reset = self:CreateThemedButton(frame, L.RESET_TIMER, 142, 34)
	reset:SetPoint("LEFT", save, "RIGHT", 10, 0)
	reset:SetScript("OnClick", function()
		if RR:SaveUIValues() then
			RR:ResetTimer(false)
		end
	end)
	local sendNow = self:CreateThemedButton(frame, L.SEND_NOW, 142, 34)
	sendNow:SetPoint("LEFT", reset, "RIGHT", 10, 0)
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
	local closeBottom = self:CreateThemedButton(frame, L.CLOSE, 110, 34)
	closeBottom:SetPoint("BOTTOMRIGHT", -28, 14)
	closeBottom:SetScript("OnClick", function()
		frame:Hide()
	end)

	frame:SetScript("OnShow", function()
		if RR.preserveMainDraftOnShow then
			RR.preserveMainDraftOnShow = false
			RR:RefreshPreview()
			RR:SetStatus(RR:GetStatusText())
		else
			RR:LoadUIValues()
		end
	end)
	frame:SetScript("OnHide", function()
		if RR.tokenFrame then
			RR.tokenFrame:Hide()
		end
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
		queueNotice = limitation,
	}

	self:CreateReadyButton()
	self:RegisterSettingsLauncher()
	self:LoadUIValues()
end
