local _, RR = ...

local Theme = {
	bg = { 0.025, 0.028, 0.055, 0.98 },
	panel = { 0.055, 0.06, 0.105, 0.96 },
	panelHover = { 0.095, 0.10, 0.17, 1 },
	input = { 0.016, 0.018, 0.038, 1 },
	border = { 0.20, 0.22, 0.34, 1 },
	accent = { 1.00, 0.58, 0.18, 1 },
	accentDark = { 0.34, 0.15, 0.045, 1 },
	text = { 0.95, 0.94, 0.90, 1 },
	muted = { 0.60, 0.62, 0.72, 1 },
	danger = { 0.82, 0.22, 0.22, 1 },
}

RR.Theme = Theme

RR.ClassColors = {
	warrior = { 0.78, 0.61, 0.43 },
	paladin = { 0.96, 0.55, 0.73 },
	hunter = { 0.67, 0.83, 0.45 },
	rogue = { 1.00, 0.96, 0.41 },
	priest = { 1.00, 1.00, 1.00 },
	deathknight = { 0.77, 0.12, 0.23 },
	shaman = { 0.00, 0.44, 0.87 },
	mage = { 0.25, 0.78, 0.92 },
	warlock = { 0.53, 0.53, 0.93 },
	monk = { 0.00, 1.00, 0.60 },
	druid = { 1.00, 0.49, 0.04 },
	demonhunter = { 0.64, 0.19, 0.79 },
	evoker = { 0.20, 0.58, 0.50 },
}

local backdrop = {
	bgFile = "Interface\\Buttons\\WHITE8X8",
	edgeFile = "Interface\\Buttons\\WHITE8X8",
	edgeSize = 1,
}

function RR:CreateThemedLabel(parent, text, font, color)
	local label = parent:CreateFontString(nil, "ARTWORK", font or "GameFontNormal")
	label:SetText(text or "")
	label:SetJustifyH("LEFT")
	local selected = color or Theme.text
	label:SetTextColor(selected[1], selected[2], selected[3], selected[4] or 1)
	return label
end

function RR:CreateThemedButton(parent, text, width, height, style)
	local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
	button:SetSize(width or 140, height or 32)
	button:SetBackdrop(backdrop)

	local base = style == "accent" and Theme.accentDark
		or style == "danger" and { 0.26, 0.055, 0.055, 1 }
		or Theme.panel
	local edge = style == "accent" and Theme.accent
		or style == "danger" and Theme.danger
		or Theme.border
	button:SetBackdropColor(base[1], base[2], base[3], base[4])
	button:SetBackdropBorderColor(edge[1], edge[2], edge[3], edge[4])

	local label = self:CreateThemedLabel(button, text, "GameFontNormal")
	label:SetPoint("CENTER")
	label:SetJustifyH("CENTER")
	button.label = label

	button:SetScript("OnEnter", function(self)
		self:SetBackdropColor(Theme.panelHover[1], Theme.panelHover[2], Theme.panelHover[3], 1)
		self:SetBackdropBorderColor(Theme.accent[1], Theme.accent[2], Theme.accent[3], 1)
	end)
	button:SetScript("OnLeave", function(self)
		if self.selected then
			self:SetBackdropColor(Theme.accentDark[1], Theme.accentDark[2], Theme.accentDark[3], 1)
			self:SetBackdropBorderColor(Theme.accent[1], Theme.accent[2], Theme.accent[3], 1)
		else
			self:SetBackdropColor(base[1], base[2], base[3], base[4])
			self:SetBackdropBorderColor(edge[1], edge[2], edge[3], edge[4])
		end
	end)
	return button
end

function RR:CreateThemedCheckbox(parent, text, small)
	local checkbox = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
	checkbox:SetSize(24, 24)
	checkbox.Text:SetText(text or "")
	checkbox.Text:SetFontObject(small and "GameFontHighlightSmall" or "GameFontHighlight")
	checkbox.Text:SetTextColor(Theme.text[1], Theme.text[2], Theme.text[3], 1)
	return checkbox
end

function RR:CreateThemedInput(parent, width, height, multiline)
	local edit = CreateFrame("EditBox", nil, parent, "BackdropTemplate")
	edit:SetSize(width or 260, height or 30)
	edit:SetBackdrop(backdrop)
	edit:SetBackdropColor(Theme.input[1], Theme.input[2], Theme.input[3], 1)
	edit:SetBackdropBorderColor(Theme.border[1], Theme.border[2], Theme.border[3], 1)
	edit:SetFontObject(multiline and "ChatFontNormal" or "GameFontHighlight")
	edit:SetTextInsets(10, 10, 5, 5)
	edit:SetAutoFocus(false)
	edit:SetMultiLine(multiline and true or false)
	edit:SetScript("OnEscapePressed", function(self)
		self:ClearFocus()
	end)
	edit:SetScript("OnEditFocusGained", function(self)
		self:SetBackdropBorderColor(Theme.accent[1], Theme.accent[2], Theme.accent[3], 1)
	end)
	edit:SetScript("OnEditFocusLost", function(self)
		self:SetBackdropBorderColor(Theme.border[1], Theme.border[2], Theme.border[3], 1)
	end)
	return edit
end

function RR:CreateThemedPanel(parent)
	local panel = CreateFrame("Frame", nil, parent, "BackdropTemplate")
	panel:SetBackdrop(backdrop)
	panel:SetBackdropColor(Theme.panel[1], Theme.panel[2], Theme.panel[3], Theme.panel[4])
	panel:SetBackdropBorderColor(Theme.border[1], Theme.border[2], Theme.border[3], 1)
	return panel
end

function RR:CreateThemedWindow(name, width, height, titleText, subtitleText)
	local frame = CreateFrame("Frame", name, UIParent, "BackdropTemplate")
	frame:SetSize(width, height)
	frame:SetPoint("CENTER")
	frame:SetFrameStrata("DIALOG")
	frame:SetClampedToScreen(true)
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
	frame:SetBackdrop(backdrop)
	frame:SetBackdropColor(Theme.bg[1], Theme.bg[2], Theme.bg[3], Theme.bg[4])
	frame:SetBackdropBorderColor(Theme.border[1], Theme.border[2], Theme.border[3], 1)

	local header = frame:CreateTexture(nil, "BACKGROUND")
	header:SetColorTexture(0.045, 0.038, 0.082, 1)
	header:SetPoint("TOPLEFT", 1, -1)
	header:SetPoint("TOPRIGHT", -1, -1)
	header:SetHeight(82)

	local accent = frame:CreateTexture(nil, "ARTWORK")
	accent:SetColorTexture(Theme.accent[1], Theme.accent[2], Theme.accent[3], 0.8)
	accent:SetPoint("TOPLEFT", 1, -82)
	accent:SetPoint("TOPRIGHT", -1, -82)
	accent:SetHeight(2)

	local title = self:CreateThemedLabel(frame, titleText, "GameFontNormalHuge")
	title:SetPoint("TOPLEFT", 26, -20)
	local subtitle = self:CreateThemedLabel(frame, subtitleText, "GameFontHighlightSmall", Theme.muted)
	subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -7)

	local close = self:CreateThemedButton(frame, "×", 36, 34)
	close:SetPoint("TOPRIGHT", -18, -18)
	close.label:SetFontObject("GameFontNormalLarge")
	close:SetScript("OnClick", function()
		frame:Hide()
	end)

	frame.title = title
	frame.subtitle = subtitle
	frame.closeButton = close
	return frame
end

function RR:SetTabSelected(button, selected)
	if not button then
		return
	end
	button.selected = selected
	if selected then
		button:SetBackdropColor(Theme.accentDark[1], Theme.accentDark[2], Theme.accentDark[3], 1)
		button:SetBackdropBorderColor(Theme.accent[1], Theme.accent[2], Theme.accent[3], 1)
		button.label:SetTextColor(Theme.text[1], Theme.text[2], Theme.text[3], 1)
	else
		button:SetBackdropColor(Theme.panel[1], Theme.panel[2], Theme.panel[3], 1)
		button:SetBackdropBorderColor(Theme.border[1], Theme.border[2], Theme.border[3], 1)
		button.label:SetTextColor(Theme.muted[1], Theme.muted[2], Theme.muted[3], 1)
	end
end
