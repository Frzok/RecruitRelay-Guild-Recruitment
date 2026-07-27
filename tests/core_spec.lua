local now = 1700000000
local sentMessages = {}
local eventFrame

function GetLocale()
	return "enUS"
end

function GetServerTime()
	return now
end

function time()
	return now
end

function date(format)
	if format == "%H:%M" then
		return "20:30"
	end
	return "14.11.2023"
end

function UnitName()
	return "Tester"
end

function GetRealmName()
	return "Test Realm"
end

function UnitFactionGroup()
	return "Alliance"
end

function IsInGuild()
	return true
end

function GetGuildInfo()
	return "Test Guild"
end

function GetNumGuildMembers()
	return 120, 34
end

function InCombatLockdown()
	return false
end

function IsInInstance()
	return false
end

function UnitIsAFK()
	return false
end

function strtrim(value)
	return (value:gsub("^%s+", ""):gsub("%s+$", ""))
end

function wipe(value)
	for key in pairs(value) do
		value[key] = nil
	end
	return value
end

DEFAULT_CHAT_FRAME = {
	AddMessage = function() end,
}

local framePrototype = {}

function framePrototype:RegisterEvent() end

function framePrototype:SetScript(scriptName, callback)
	if scriptName == "OnEvent" then
		self.onEvent = callback
	end
end

function CreateFrame()
	eventFrame = setmetatable({}, { __index = framePrototype })
	return eventFrame
end

C_Timer = {
	NewTicker = function() end,
}

C_Club = {
	GetGuildClubId = function()
		return 42
	end,
}

C_GuildInfo = {
	GuildRoster = function() end,
}

local specializationsByClass = {
	[5] = {
		{ 256, "Discipline" },
		{ 257, "Holy" },
		{ 258, "Shadow" },
	},
	[6] = {
		{ 250, "Blood" },
		{ 251, "Frost" },
		{ 252, "Unholy" },
	},
	[12] = {
		{ 577, "Havoc" },
		{ 581, "Vengeance" },
		{ 1480, "Devourer" },
	},
}

C_SpecializationInfo = {
	GetNumSpecializationsForClassID = function(classID)
		return #(specializationsByClass[classID] or {})
	end,
	GetSpecializationInfo = function(index, _, _, _, _, _, classID)
		local specialization = (specializationsByClass[classID] or {})[index]
		if specialization then
			return specialization[1], specialization[2], "", 0
		end
	end,
}

C_ClubFinder = {
	GetRecruitingClubInfoFromClubID = function()
		return {
			clubFinderGUID = "ClubFinder-1-42",
			name = "Test Guild",
			recruitmentFlags = 1,
		}
	end,
	IsListingEnabledFromFlags = function()
		return true
	end,
	RequestPostingInformationFromClubId = function()
		return true
	end,
}

function GetClubFinderLink(_, clubName)
	return "|HclubFinder:test|h[Guild: " .. clubName .. "]|h"
end

local channelInfo = {
	["Trade - City"] = { localID = 2, zoneChannelID = 2 },
	["LookingForGroup"] = { localID = 4, zoneChannelID = 26 },
	Trade = { localID = 2, zoneChannelID = 2 },
	LookingForGroup = { localID = 4, zoneChannelID = 26 },
}

GENERAL = "General"
TRADE = "Trade"
LOOKING_FOR_GROUP = "LookingForGroup"

function GetChannelList()
	return 2, "Trade - City", false, 4, "LookingForGroup", false
end

C_ChatInfo = {
	GetChannelInfoFromIdentifier = function(identifier)
		return channelInfo[identifier]
	end,
	SendChatMessage = function(message, chatType, _, channelIndex)
		table.insert(sentMessages, {
			message = message,
			chatType = chatType,
			channelIndex = channelIndex,
		})
	end,
}

local addon = {}
assert(loadfile("Locale.lua"))("RecruitRelay", addon)
assert(loadfile("Core.lua"))("RecruitRelay", addon)
assert(loadfile("Theme.lua"))("RecruitRelay", addon)
assert(loadfile("ProfileUI.lua"))("RecruitRelay", addon)

addon.UpdateAllUI = function() end
addon.SetStatus = function() end

addon:InitializeDatabase()
addon:RefreshGuildFinderLink(false)

local hiddenPaletteTokens = {
	["$language"] = true,
	["$timezone"] = true,
	["$region"] = true,
	["$age"] = true,
	["$loot"] = true,
	["$starttime"] = true,
	["$endtime"] = true,
	["$date"] = true,
	["$realm"] = true,
	["$faction"] = true,
	["$online"] = true,
	["$members"] = true,
}
for _, token in ipairs(addon.messageTokens) do
	assert(not hiddenPaletteTokens[token])
	assert(addon.L[addon.tokenHelpKeys[token]])
end

local expanded = addon:ExpandMessage("$gname | $glink | $realm | $faction | $player")
assert(expanded:find("Test Guild", 1, true))
assert(expanded:find("|HclubFinder:test|h", 1, true))
assert(expanded:find("Test Realm", 1, true))
assert(expanded:find("Alliance", 1, true))
assert(expanded:find("Tester", 1, true))

addon.db.profile.progress = "6/8 Mythic"
addon.db.profile.discord = ""
addon.db.profile.contact = "Tester"
addon.db.profile.backupcontacts = "Officer"
addon.db.schedule.days.wed = true
addon.db.schedule.days.sun = true
addon.db.schedule.startTime = "20:00"
addon.db.schedule.endTime = "23:00"
addon.db.needs.roles.healer = true
addon.db.needs.roles.melee = true
addon.db.needs.roles.ranged = true
addon.db.needs.classes.priest = true
addon.db.needs.classes.deathknight = true
addon.db.needs.classes.demonhunter = true
addon.db.needs.classes.mage = true
addon.db.needs.specializations.priest = { ["256"] = true }
addon.db.needs.activities.raid = true

local profileExpanded = addon:ExpandMessage(
	"$online/$members | $progress | $schedule | $needs | $activities | $contacts | $time $date"
)
assert(profileExpanded:find("34/120", 1, true))
assert(profileExpanded:find("6/8 Mythic", 1, true))
assert(profileExpanded:find("Wed, Sun, 20:00–23:00", 1, true))
assert(profileExpanded:find("Heal, MDPS, RDPS", 1, true))
assert(profileExpanded:find("Priest (Discipline), DK, Mage, DH", 1, true))
assert(profileExpanded:find("Raids", 1, true))
assert(profileExpanded:find("Tester, Officer", 1, true))
assert(profileExpanded:find("20:30 14.11.2023", 1, true))

local optionalExpanded = addon:ExpandMessage("[[Discord: $discord · ]]Guild: $gname")
assert(optionalExpanded == "Guild: Test Guild")

local valid, lines = addon:ValidateMessage("Line one\nLine two")
assert(valid)
assert(#lines == 2)

local tooManyLines, lineError = addon:ValidateMessage("One\nTwo\nThree")
assert(not tooManyLines)
assert(lineError == addon.L.STATUS_TOO_MANY_LINES)

local tooLong, lengthError = addon:ValidateMessage(string.rep("a", 256))
assert(not tooLong)
assert(lengthError:find("255", 1, true))

addon.db.message = "Recruiting: $glink"
addon.db.channels.trade = true
addon.db.channels.lfg = true
addon:RefreshChannels()

assert(addon.channelIndexes[2] == 2)
assert(addon.channelIndexes[26] == 4)

local prepared, prepareError = addon:PrepareSend(true)
assert(prepared, prepareError)
assert(addon.pendingSend.channel.index == 2)

addon:SendNextLine()
assert(#sentMessages == 1)
assert(sentMessages[1].chatType == "CHANNEL")
assert(sentMessages[1].channelIndex == 2)
assert(sentMessages[1].message:find("|HclubFinder:test|h", 1, true))
assert(addon.pendingSend == nil)
assert(addon.db.lastSent == now)
assert(addon.db.nextDue == now + addon.db.interval * 60)

addon.db.message = "First\nSecond"
assert(addon:PrepareSend(true))
addon:SendNextLine()
assert(addon.pendingSend ~= nil)
assert(#addon.pendingSend.lines == 1)
addon:SendNextLine()
assert(addon.pendingSend == nil)
assert(#sentMessages == 3)

addon.db.enabled = true
addon.db.nextDue = now
assert(addon:PrepareSend(false))
assert(addon.pendingSend ~= nil)
addon:SetAnnouncementsEnabled(false, true)
assert(addon.db.enabled == false)
assert(addon.db.nextDue == 0)
assert(addon.pendingSend == nil)
assert(addon.ready == false)

addon:SetAnnouncementsEnabled(true, true)
assert(addon.db.enabled == true)
assert(addon.db.nextDue == now + addon.db.interval * 60)

local queuedActions = {}
MessageQueue = {
	Enqueue = function(action)
		table.insert(queuedActions, action)
		return #queuedActions
	end,
}

addon.db.message = "Automatic queue"
addon.db.channels.trade = true
addon.db.channels.lfg = false
addon.db.enabled = true
addon.db.nextDue = now
addon.pendingSend = nil
addon:Tick()

assert(#queuedActions == 1)
assert(addon.pendingSend ~= nil)
assert(addon.pendingSend.queued == true)
assert(#sentMessages == 3)

queuedActions[1]()
assert(#sentMessages == 4)
assert(sentMessages[4].message == "Automatic queue")
assert(addon.pendingSend == nil)
assert(addon.db.lastSent == now)

queuedActions = {}
addon.db.message = "Cancelled queue"
addon.db.nextDue = now
addon:Tick()
assert(#queuedActions == 1)
addon:SetAnnouncementsEnabled(false, true)
queuedActions[1]()
assert(#sentMessages == 4)

GetLocale = function()
	return "ruRU"
end
RecruitRelayDB = nil
local ruAddon = {}
assert(loadfile("Locale.lua"))("RecruitRelay", ruAddon)
assert(loadfile("Core.lua"))("RecruitRelay", ruAddon)
assert(loadfile("Theme.lua"))("RecruitRelay", ruAddon)
assert(loadfile("ProfileUI.lua"))("RecruitRelay", ruAddon)
ruAddon.UpdateAllUI = function() end
ruAddon:InitializeDatabase()

for _, token in ipairs(ruAddon.messageTokens) do
	assert(ruAddon.L[ruAddon.tokenHelpKeys[token]])
end

ruAddon.db.needs.roles.healer = true
ruAddon.db.needs.roles.melee = true
ruAddon.db.needs.roles.ranged = true
for _, key in ipairs(ruAddon.classKeys) do
	ruAddon.db.needs.classes[key] = true
end

local russianNeeds = ruAddon:ExpandMessage("$roles | $classes")
assert(russianNeeds:find("Хил, МДД, РДД", 1, true))
assert(russianNeeds:find("Вар, Пал, Хант, Рога, Прист, ДК", 1, true))
assert(russianNeeds:find("Шам, Маг, Лок, Монк, Дру, ДХ, Дракон", 1, true))

print("RecruitRelay core tests: OK")
