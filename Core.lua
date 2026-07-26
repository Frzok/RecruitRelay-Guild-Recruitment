local addonName, RR = ...
local L = RR.L

_G.RecruitRelay = RR

local MAX_CHAT_BYTES = 255
local MAX_MESSAGE_LINES = 2
local MIN_INTERVAL_MINUTES = 5
local MAX_INTERVAL_MINUTES = 60

local defaults = {
	enabled = true,
	message = "Guild $glink is recruiting! Whisper $player for details.",
	interval = 10,
	channels = {
		general = false,
		trade = true,
		lfg = false,
	},
	pause = {
		combat = true,
		instance = true,
		afk = true,
	},
	nextDue = 0,
	lastSent = 0,
	nextChannel = 1,
	profile = {
		raidtime = "",
		progress = "",
		requirements = "",
		contact = "",
		backupcontacts = "",
		discord = "",
		language = "",
		timezone = "",
		region = "",
		focus = "",
		voice = "",
		website = "",
		age = "",
		loot = "",
		about = "",
		priority = "",
	},
	schedule = {
		days = {
			mon = false,
			tue = false,
			wed = false,
			thu = false,
			fri = false,
			sat = false,
			sun = false,
		},
		startTime = "",
		endTime = "",
	},
	needs = {
		roles = {
			tank = false,
			healer = false,
			melee = false,
			ranged = false,
		},
		classes = {
			warrior = false,
			paladin = false,
			hunter = false,
			rogue = false,
			priest = false,
			deathknight = false,
			shaman = false,
			mage = false,
			warlock = false,
			monk = false,
			druid = false,
			demonhunter = false,
			evoker = false,
		},
		activities = {
			raid = false,
			mythicplus = false,
			pvp = false,
			social = false,
		},
	},
}

RR.dayKeys = { "mon", "tue", "wed", "thu", "fri", "sat", "sun" }
RR.roleKeys = { "tank", "healer", "melee", "ranged" }
RR.classKeys = {
	"warrior", "paladin", "hunter", "rogue", "priest", "deathknight",
	"shaman", "mage", "warlock", "monk", "druid", "demonhunter", "evoker",
}
RR.activityKeys = { "raid", "mythicplus", "pvp", "social" }

local channelDefinitions = {
	{ key = "trade", zoneChannelID = 2, label = function() return L.TRADE end },
	{ key = "lfg", zoneChannelID = 26, label = function() return L.LFG end },
	{ key = "general", zoneChannelID = 1, label = function() return L.GENERAL end },
}

RR.channelIndexes = {}
RR.guildFinderLink = nil
RR.guildFinderRequestPending = false
RR.pendingSend = nil
RR.ready = false

local function CopyDefaults(source, target)
	for key, value in pairs(source) do
		if type(value) == "table" then
			if type(target[key]) ~= "table" then
				target[key] = {}
			end
			CopyDefaults(value, target[key])
		elseif target[key] == nil then
			target[key] = value
		end
	end
end

local function EscapePattern(value)
	return value:gsub("([^%w])", "%%%1")
end

local function ReplaceToken(text, token, replacement)
	return (text:gsub(EscapePattern(token), function()
		return replacement or ""
	end))
end

local function JoinValues(values)
	return table.concat(values, ", ")
end

local function SplitLines(text)
	local lines = {}
	text = (text or ""):gsub("\r\n", "\n"):gsub("\r", "\n")

	for line in (text .. "\n"):gmatch("(.-)\n") do
		if line ~= "" or #lines > 0 then
			table.insert(lines, line)
		end
	end

	while #lines > 0 and lines[#lines] == "" do
		table.remove(lines)
	end

	return lines
end

local function FormatDuration(seconds)
	seconds = math.max(0, math.floor(seconds or 0))
	local minutes = math.floor(seconds / 60)
	local remainingSeconds = seconds % 60

	if minutes > 0 then
		return ("%d:%02d"):format(minutes, remainingSeconds)
	end

	return ("%d sec"):format(remainingSeconds)
end

function RR:Print(message)
	DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99RecruitRelay:|r " .. tostring(message))
end

function RR:InitializeDatabase()
	RecruitRelayDB = RecruitRelayDB or {}
	CopyDefaults(defaults, RecruitRelayDB)
	self.db = RecruitRelayDB
	self.db.interval = math.max(
		MIN_INTERVAL_MINUTES,
		math.min(MAX_INTERVAL_MINUTES, tonumber(self.db.interval) or defaults.interval)
	)
end

function RR:GetNow()
	if GetServerTime then
		return GetServerTime()
	end
	return time()
end

function RR:ResetTimer(silent)
	self.pendingSend = nil
	self.ready = false
	self.db.nextDue = self:GetNow() + (self.db.interval * 60)
	self:UpdateAllUI()

	if not silent then
		self:Print(L.TIMER_RESET)
	end
end

function RR:GetGuildName()
	if not IsInGuild() then
		return L.NO_GUILD
	end
	return GetGuildInfo("player") or L.NO_GUILD
end

function RR:RequestGuildRoster()
	if IsInGuild() and C_GuildInfo and C_GuildInfo.GuildRoster then
		C_GuildInfo.GuildRoster()
	end
end

function RR:GetGuildCounts()
	if not IsInGuild() or not GetNumGuildMembers then
		return 0, 0
	end

	local total, online = GetNumGuildMembers()
	return tonumber(total) or 0, tonumber(online) or 0
end

function RR:GetSelectedLabels(source, keys, prefix)
	local selected = {}
	for _, key in ipairs(keys) do
		if source and source[key] then
			table.insert(selected, L[prefix .. key:upper()] or key)
		end
	end
	return selected
end

function RR:GetScheduleParts()
	local schedule = self.db.schedule
	local days = self:GetSelectedLabels(schedule.days, self.dayKeys, "DAY_")
	local dayText = JoinValues(days)
	local startTime = strtrim(schedule.startTime or "")
	local endTime = strtrim(schedule.endTime or "")
	local timeText = ""

	if startTime ~= "" and endTime ~= "" then
		timeText = startTime .. "–" .. endTime
	elseif startTime ~= "" then
		timeText = startTime
	elseif endTime ~= "" then
		timeText = endTime
	end

	local parts = {}
	if dayText ~= "" then
		table.insert(parts, dayText)
	end
	if timeText ~= "" then
		table.insert(parts, timeText)
	end
	if #parts > 0 and strtrim(self.db.profile.timezone or "") ~= "" then
		table.insert(parts, self.db.profile.timezone)
	end

	return JoinValues(parts), dayText, startTime, endTime
end

function RR:GetTokenValues()
	local profile = self.db.profile
	local totalMembers, onlineMembers = self:GetGuildCounts()
	local schedule, days, startTime, endTime = self:GetScheduleParts()
	local roles = JoinValues(self:GetSelectedLabels(self.db.needs.roles, self.roleKeys, "ROLE_"))
	local classes = JoinValues(self:GetSelectedLabels(self.db.needs.classes, self.classKeys, "CLASS_"))
	local activities = JoinValues(
		self:GetSelectedLabels(self.db.needs.activities, self.activityKeys, "ACTIVITY_")
	)
	local needParts = {}
	if roles ~= "" then
		table.insert(needParts, roles)
	end
	if classes ~= "" then
		table.insert(needParts, classes)
	end
	local needs = JoinValues(needParts)
	local contacts = strtrim(profile.contact or "")
	if strtrim(profile.backupcontacts or "") ~= "" then
		if contacts ~= "" then
			contacts = contacts .. ", " .. profile.backupcontacts
		else
			contacts = profile.backupcontacts
		end
	end

	local localTime = date and date("%H:%M") or ""
	local localDate = date and date("%d.%m.%Y") or ""

	return {
		["$backupcontacts"] = profile.backupcontacts,
		["$requirements"] = profile.requirements,
		["$activities"] = activities,
		["$starttime"] = startTime,
		["$endtime"] = endTime,
		["$raidtime"] = strtrim(profile.raidtime or "") ~= "" and profile.raidtime or schedule,
		["$progress"] = profile.progress,
		["$contacts"] = contacts,
		["$contact"] = profile.contact,
		["$schedule"] = schedule,
		["$timezone"] = profile.timezone,
		["$language"] = profile.language,
		["$priority"] = profile.priority,
		["$discord"] = profile.discord,
		["$website"] = profile.website,
		["$faction"] = UnitFactionGroup("player") or "",
		["$classes"] = classes,
		["$members"] = tostring(totalMembers),
		["$online"] = tostring(onlineMembers),
		["$region"] = profile.region,
		["$focus"] = profile.focus,
		["$voice"] = profile.voice,
		["$about"] = profile.about,
		["$player"] = UnitName("player") or "",
		["$realm"] = GetRealmName() or "",
		["$roles"] = roles,
		["$needs"] = needs,
		["$need"] = needs,
		["$days"] = days,
		["$loot"] = profile.loot,
		["$age"] = profile.age,
		["$time"] = localTime,
		["$date"] = localDate,
		["$glink"] = self.guildFinderLink or self:GetGuildName(),
		["$gname"] = self:GetGuildName(),
	}
end

function RR:ExpandOptionalBlocks(text, values)
	return (text:gsub("%[%[(.-)%]%]", function(block)
		for token in block:gmatch("%$[%a]+") do
			if values[token] ~= nil and strtrim(tostring(values[token] or "")) == "" then
				return ""
			end
		end
		return block
	end))
end

function RR:RefreshGuildFinderLink(requestIfMissing)
	self.guildFinderLink = nil

	if not IsInGuild() or not C_Club or not C_Club.GetGuildClubId or not C_ClubFinder then
		return
	end

	local clubId = C_Club.GetGuildClubId()
	if not clubId then
		return
	end

	local clubInfo
	if C_ClubFinder.GetRecruitingClubInfoFromClubID then
		clubInfo = C_ClubFinder.GetRecruitingClubInfoFromClubID(clubId)
	end

	if clubInfo
		and clubInfo.clubFinderGUID
		and clubInfo.name
		and (not C_ClubFinder.IsListingEnabledFromFlags
			or C_ClubFinder.IsListingEnabledFromFlags(clubInfo.recruitmentFlags)) then
		if GetClubFinderLink then
			self.guildFinderLink = GetClubFinderLink(clubInfo.clubFinderGUID, clubInfo.name)
		else
			local linkText = CLUB_FINDER_LINK_GUILD
				and CLUB_FINDER_LINK_GUILD:format(clubInfo.name)
				or ("[Guild: %s]"):format(clubInfo.name)
			self.guildFinderLink = ("|cffffd100|HclubFinder:%s|h%s|h|r"):format(
				tostring(clubInfo.clubFinderGUID),
				linkText
			)
		end

		self.guildFinderRequestPending = false
		return
	end

	if clubInfo then
		self.guildFinderRequestPending = false
		return
	end

	if requestIfMissing
		and not self.guildFinderRequestPending
		and C_ClubFinder.RequestPostingInformationFromClubId then
		self.guildFinderRequestPending =
			C_ClubFinder.RequestPostingInformationFromClubId(clubId) ~= false
	end
end

function RR:ExpandMessage(text)
	local values = self:GetTokenValues()
	local tokens = {}
	for token in pairs(values) do
		table.insert(tokens, token)
	end
	table.sort(tokens, function(left, right)
		return #left > #right
	end)

	text = self:ExpandOptionalBlocks(text or "", values)
	for _, token in ipairs(tokens) do
		text = ReplaceToken(text, token, tostring(values[token] or ""))
	end
	return text
end

function RR:ValidateMessage(message)
	local rawLines = SplitLines(message)
	if #rawLines == 0 then
		return false, L.STATUS_NO_MESSAGE
	end

	if #rawLines > MAX_MESSAGE_LINES then
		return false, L.STATUS_TOO_MANY_LINES
	end

	local expandedLines = {}
	for index, rawLine in ipairs(rawLines) do
		local expandedLine = self:ExpandMessage(rawLine)
		if #expandedLine > MAX_CHAT_BYTES then
			return false, L.STATUS_TOO_LONG:format(index, #expandedLine)
		end
		table.insert(expandedLines, expandedLine)
	end

	return true, expandedLines
end

function RR:RefreshChannels()
	wipe(self.channelIndexes)

	if GetChannelList and C_ChatInfo and C_ChatInfo.GetChannelInfoFromIdentifier then
		local channelData = { GetChannelList() }
		for index = 1, #channelData, 3 do
			local localID = channelData[index]
			local channelName = channelData[index + 1]
			if localID and channelName then
				local info = C_ChatInfo.GetChannelInfoFromIdentifier(channelName)
				if info and info.zoneChannelID then
					self.channelIndexes[info.zoneChannelID] = info.localID or localID
				end
			end
		end

		local identifiers = {
			[1] = _G.GENERAL,
			[2] = _G.TRADE,
			[26] = _G.LOOKING_FOR_GROUP,
		}
		for zoneChannelID, identifier in pairs(identifiers) do
			if identifier and not self.channelIndexes[zoneChannelID] then
				local info = C_ChatInfo.GetChannelInfoFromIdentifier(identifier)
				if info and info.localID then
					self.channelIndexes[zoneChannelID] = info.localID
				end
			end
		end
	end
end

function RR:UpdateChannelFromEvent(action, zoneChannelID, channelIndex)
	if not zoneChannelID then
		return
	end

	if action == "YOU_JOINED" or action == "YOU_CHANGED" then
		self.channelIndexes[zoneChannelID] = channelIndex
	elseif action == "YOU_LEFT" or action == "SUSPENDED" then
		self.channelIndexes[zoneChannelID] = nil
	end

	self:UpdateAllUI()
end

function RR:GetAvailableChannels()
	local available = {}
	for _, definition in ipairs(channelDefinitions) do
		if self.db.channels[definition.key] then
			local channelIndex = self.channelIndexes[definition.zoneChannelID]
			if channelIndex then
				table.insert(available, {
					key = definition.key,
					index = channelIndex,
					name = definition.label(),
				})
			end
		end
	end
	return available
end

function RR:SelectChannel()
	local available = self:GetAvailableChannels()
	if #available == 0 then
		return nil
	end

	local selectedIndex = math.max(1, math.min(#available, self.db.nextChannel or 1))
	local selected = available[selectedIndex]
	self.db.nextChannel = selectedIndex % #available + 1
	return selected
end

function RR:GetPauseReason()
	if self.db.pause.combat and InCombatLockdown() then
		return L.STATUS_COMBAT
	end

	if self.db.pause.instance then
		local inInstance = IsInInstance()
		if inInstance then
			return L.STATUS_INSTANCE
		end
	end

	if self.db.pause.afk and UnitIsAFK("player") then
		return L.STATUS_AFK
	end

	return nil
end

function RR:PrepareSend(isManual)
	self:RefreshChannels()
	self:RefreshGuildFinderLink(true)

	local valid, result = self:ValidateMessage(self.db.message)
	if not valid then
		return false, result
	end

	local channel = self:SelectChannel()
	if not channel then
		return false, L.STATUS_CHANNEL_UNAVAILABLE
	end

	self.pendingSend = {
		lines = result,
		total = #result,
		channel = channel,
		manual = isManual,
	}
	self.ready = true
	self:UpdateAllUI()
	return true
end

function RR:SendNextLine()
	if not self.pendingSend then
		local prepared, errorMessage = self:PrepareSend(true)
		if not prepared then
			self:Print(errorMessage)
			self:SetStatus(errorMessage)
			return
		end
	end

	local pending = self.pendingSend
	local line = table.remove(pending.lines, 1)
	if not line then
		self:CompleteSend()
		return
	end

	C_ChatInfo.SendChatMessage(line, "CHANNEL", nil, pending.channel.index)

	if #pending.lines == 0 then
		self:CompleteSend()
	else
		self.ready = true
		self:UpdateAllUI()
	end
end

function RR:CompleteSend()
	local channelName = self.pendingSend and self.pendingSend.channel.name or L.CHANNEL_UNKNOWN
	self.pendingSend = nil
	self.ready = false
	self.db.lastSent = self:GetNow()
	self.db.nextDue = self.db.lastSent + (self.db.interval * 60)
	self:Print(L.STATUS_SENT:format(channelName))
	self:UpdateAllUI()
end

function RR:Tick()
	if not self.db or not self.db.enabled then
		self.ready = false
		self:UpdateAllUI()
		return
	end

	if not self.db.nextDue or self.db.nextDue <= 0 then
		self:ResetTimer(true)
		return
	end

	if self:GetNow() < self.db.nextDue then
		self:UpdateAllUI()
		return
	end

	local pauseReason = self:GetPauseReason()
	if pauseReason then
		self.ready = false
		self:SetStatus(pauseReason)
		self:UpdateReadyButton()
		return
	end

	if not self.pendingSend then
		local prepared, errorMessage = self:PrepareSend(false)
		if not prepared then
			self.ready = false
			self:SetStatus(errorMessage)
			self:UpdateReadyButton()
			return
		end
	end

	self.ready = true
	self:UpdateAllUI()
end

function RR:GetStatusText()
	if not self.db.enabled then
		return L.STATUS_DISABLED
	end

	local pauseReason = self:GetPauseReason()
	if pauseReason and self:GetNow() >= (self.db.nextDue or 0) then
		return pauseReason
	end

	if self.pendingSend or self.ready then
		return L.STATUS_READY
	end

	return L.STATUS_WAITING:format(FormatDuration((self.db.nextDue or 0) - self:GetNow()))
end

function RR:HandleSlashCommand(input)
	input = strtrim((input or ""):lower())

	if input == "" then
		self:ToggleMainWindow()
	elseif input == "send" then
		local prepared, errorMessage = self:PrepareSend(true)
		if not prepared then
			self:Print(errorMessage)
		end
	elseif input == "reset" then
		self:ResetTimer(false)
	elseif input == "status" then
		self:Print(self:GetStatusText())
	else
		self:Print(L.SLASH_HELP)
	end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("CHAT_MSG_CHANNEL_NOTICE")
eventFrame:RegisterEvent("CHAT_MSG_CHANNEL")
eventFrame:RegisterEvent("CLUB_FINDER_RECRUITMENT_POST_RETURNED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterEvent("PLAYER_FLAGS_CHANGED")
eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
eventFrame:RegisterEvent("GUILD_ROSTER_UPDATE")
eventFrame:RegisterEvent("PLAYER_GUILD_UPDATE")

eventFrame:SetScript("OnEvent", function(_, event, ...)
	if event == "ADDON_LOADED" then
		local loadedAddon = ...
		if loadedAddon == addonName then
			RR:InitializeDatabase()
			RR:CreateUI()
		end
	elseif event == "PLAYER_LOGIN" then
		RR:RefreshChannels()
		RR:RefreshGuildFinderLink(true)
		RR:RequestGuildRoster()
		RR:ResetTimer(true)

		SLASH_RECRUITRELAY1 = "/rr"
		SLASH_RECRUITRELAY2 = "/recruitrelay"
		SlashCmdList.RECRUITRELAY = function(input)
			RR:HandleSlashCommand(input)
		end

		C_Timer.NewTicker(1, function()
			RR:Tick()
		end)
	elseif event == "CHAT_MSG_CHANNEL_NOTICE" then
		local action, _, _, _, _, _, zoneChannelID, channelIndex = ...
		RR:UpdateChannelFromEvent(action, zoneChannelID, channelIndex)
	elseif event == "CHAT_MSG_CHANNEL" then
		local _, _, _, _, _, _, zoneChannelID, channelIndex = ...
		if zoneChannelID and channelIndex then
			RR.channelIndexes[zoneChannelID] = channelIndex
		end
	elseif event == "CLUB_FINDER_RECRUITMENT_POST_RETURNED" then
		RR.guildFinderRequestPending = false
		RR:RefreshGuildFinderLink(false)
		RR:UpdateAllUI()
	elseif event == "PLAYER_GUILD_UPDATE" then
		RR:RefreshGuildFinderLink(true)
		RR:RequestGuildRoster()
		RR:UpdateAllUI()
	elseif event == "GUILD_ROSTER_UPDATE" then
		RR:UpdateAllUI()
	else
		RR:RefreshChannels()
		RR:Tick()
	end
end)
