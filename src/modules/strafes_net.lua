local http_request = require('./http.lua')
local API = {}
local API_KEY = require('./apikey.lua')
local API_HEADER = { {'Content-Type','application/json'}, { 'api-key', API_KEY } }
local STRAFESNET_API_URL = 'https://api.strafes.net/v1/'
local ROVER_API_URL = 'https://verify.eryn.io/api/'
local ROBLOX_API_URL = 'https://users.roblox.com/v1/'
local ROBLOX_API_URL2 = 'https://api.roblox.com/'
local ROBLOX_THUMBNAIL_URL = 'https://thumbnails.roblox.com/v1/'


local RANK_CONSTANT_A, RANK_CONSTANT_B, RANK_CONSTANT_C, RANK_CONSTANT_D, RANK_CONSTANT_E = 0.215, 0.595, 0.215, 0.215, 0.71

local t=tostring
local r=function(n,nd) return tonumber(string.format('%.' .. (nd or 0) .. 'f', n)) end

local GAMES={BHOP=1,SURF=2,[1]='bhop',[2]='surf'}
local STATES={[0]='Default',[1]='Whitelisted',[2]='Blacklisted',[3]='Pending'}
local RANKS={'New (1)','Newb (2)','Bad (3)','Okay (4)','Not Bad (5)','Decent (6)','Getting There (7)','Advanced (8)','Good (9)','Great (10)','Superb (11)','Amazing (12)','Sick (13)','Master (14)','Insane (15)','Majestic (16)','Baby Jesus (17)','Jesus (18)','Half God (19)','God (20)'}
local STYLES_LIST={'Autohop','Scroll','Sideways','Half-Sideways','W-Only','A-Only','Backwards'}
local STYLES={AUTOHOP=1,SCROLL=2,SIDEWAYS=3,HALFSIDEWAYS=4,WONLY=5,AONLY=6,BACKWARDS=7}

setmetatable(STYLES,{__index=function(self,i)
    if type(i)=='number' then return STYLES_LIST[i] or 'Unknown' end
    if i=='a' then i='auto'elseif i=='hsw'then i='half'elseif i=='s'then i='scroll'elseif i=='sw'then i='side'elseif i=='bw'then i='back'end
    for ix,v in pairs(self) do
        if string.sub(ix:lower(),1,#i):find(i:lower()) then
            return self[ix]
        end
    end
end})
setmetatable(GAMES,{__index=function(self,i)
    for ix,v in pairs(self) do
        if tostring(ix):lower()==i:lower() then
            return self[ix]
        end
    end
end})

API.GAMES=GAMES
API.STYLES=STYLES
API.STYLES_LIST=STYLES_LIST
API.STATES=STATES

API.ROBLOX_LOCATION_TYPES={
    [0]='Mobile Website',
    [1]='Mobile In-Game',
    [2]='Website',
    [3]='Roblox Studio',
    [4]='In-Game',
    [5]='XboxApp',
    [6]='TeamCreate'
}

API.ROBLOX_THUMBNAIL_SIZES={
    [48]='48x48',
    [50]='50x50',
    [60]='60x60',
    [75]='75x75',
    [100]='100x100',
    [110]='110x110',
    [150]='150x150',
    [180]='180x180',
    [352]='352x352',
    [420]='420x420',
    [720]='720x720'
}
API.ROBLOX_THUMBNAIL_TYPES = {
    AVATAR='avatar',
    BUST='avatar-bust',
    HEADSHOT='avatar-headshot'
}

-- insyri make this BTW
-- use as local err, res = parseToURLArgs(), thanks golang for this idea
function parseToURLArgs(tb) local function Err(err) return err, nil end local function Ok(res) return nil, res end if not tb then return Err('got nothing') end if type(tb) ~= 'table' then return Err('expected table, got '..type(tb)) end local str = '?' local index = 1 for key, value in pairs(tb) do if index == 1 then str = str..key..'='..t(value) else str = str..'&'..key..'='..t(value) end index = index + 1 end return Ok(str) end
-- fiveman made these (converted to lua from python)
function format_helper(a,b)a=tostring(a)while#a<b do a='0'..a end;return a end
function formatTime(a)if a>86400000 then return'>1 day'end;local c=format_helper(a%1000,3)local d=format_helper(math.floor(a/1000)%60,2)local e=format_helper(math.floor(a/(1000*60))%60,2)local f=format_helper(math.floor(a/(1000*60*60))%24,2)if f=='00'then return e..':'..d..'.'..c else return f..':'..e..':'..d end end


-- [[ STRAFESNET API ]] --

-- Get rank string from rank point
function API.FormatRank(n) return RANKS[1+math.floor(n*19)] end
-- Get skill percentage from skill point
function API.FormatSkill(n) return r(n*100,3)..'%' end
function API.FormatTime(n) return formatTime(n) end

-- Time from id.
function API:GetTime(ID)
    if not ID then return 'empty id' end
    local response,headers = http_request('GET', STRAFESNET_API_URL..'time/'..ID, API_HEADER)
    return response,headers
end
-- Time rank from id.
function API:GetTimeRank(TIME_ID)
    if not TIME_ID then return 'empty id' end
    local response,headers = http_request('GET', STRAFESNET_API_URL..'time/'..TIME_ID..'/rank', API_HEADER)
    return response,headers
end
-- 10 recent world records.
function API:GetRecentWrs(STYLE_ID, GAME_ID, WHITELIST_FILTER)
    if not STYLE_ID or not GAME_ID then return 'empty id' end
    local err, res = parseToURLArgs({style=STYLE_ID, game=GAME_ID, whitelist=WHITELIST_FILTER})
    if err then return err end
    local response,headers = http_request('GET', STRAFESNET_API_URL..'time/recent/wr'..res, API_HEADER)
    return response,headers
end
-- Time by map id. Sorted in ascending order.
function API:GetMapTimes(MAP_ID, STYLE_ID, PAGE)
    if not MAP_ID then return 'empty id' end
    local err, res = parseToURLArgs({style=STYLE_ID, page=PAGE})
    if err then return err end
    local response,headers = http_request('GET', STRAFESNET_API_URL..'time/map/'..MAP_ID..res, API_HEADER)
    return response,headers
end
-- Get WR of map.
function API:GetMapWr(MAP_ID, STYLE_ID)
    if not MAP_ID or not STYLE_ID then return 'empty id' end
    local err, res = parseToURLArgs({style=STYLE_ID})
    if err then return err end
    local response,headers = http_request('GET', STRAFESNET_API_URL..'time/map/'..MAP_ID..'/wr'..res, API_HEADER)
    return response,headers
end
-- Time by user id.
function API:GetUserTimes(USER_ID, MAP_ID, STYLE_ID, GAME_ID, PAGE)
    if not USER_ID then return 'empty id' end
    local err, res = parseToURLArgs({map=MAP_ID, style=STYLE_ID, game=GAME_ID, page=PAGE})
    if err then return err end
    local response,headers = http_request('GET', STRAFESNET_API_URL..'time/user/'..USER_ID..res , API_HEADER)
    return response,headers
end
-- World records by user id.
function API:GetUserWrs(USER_ID,GAME_ID,STYLE_ID)
    if not USER_ID or not GAME_ID or not STYLE_ID then return 'empty id' end
    local err, res = parseToURLArgs({game=GAME_ID, style=STYLE_ID})
    if err then return err end
    local response,headers = http_request('GET', STRAFESNET_API_URL..'time/user/'..USER_ID..'/wr'..res, API_HEADER)
    return response,headers
end
-- User from id.
function API:GetUser(USER_ID)
    if not USER_ID then return 'empty id' end
    local response,headers = http_request('GET', STRAFESNET_API_URL..'user/'..USER_ID, API_HEADER)
    return response,headers
end
-- Top ranked players, paged at 50 per page.
function API:GetRanks(STYLE_ID,GAME_ID,PAGE)
    if not STYLE_ID or not GAME_ID then return 'empty id' end
    local err, res = parseToURLArgs({style=STYLE_ID, game=GAME_ID, page=PAGE})
    if err then return err end
    local response,headers = http_request('GET', STRAFESNET_API_URL..'rank'..res, API_HEADER)
    return response,headers
end
-- Get rank of user by their id.
function API:GetRank(USER_ID,GAME_ID,STYLE_ID)
    if not USER_ID or not STYLE_ID or not GAME_ID then return 'empty id' end
    local err, res = parseToURLArgs({style=STYLE_ID, game=GAME_ID})
    if err then return err end
    local response,headers = http_request('GET', STRAFESNET_API_URL..'rank/'..USER_ID..res, API_HEADER)
    return response,headers
end
-- Get list of maps.
function API:GetMaps(GAME_ID,PAGE)
    if not GAME_ID then return 'empty id' end
    local err, res = parseToURLArgs({game=GAME_ID, page=PAGE})
    if err then return err end
    local response,headers = http_request('GET', STRAFESNET_API_URL..'map'..res, API_HEADER)
    return response,headers
end
-- Get map by ID.
function API:GetMap(MAP_ID)
    if not MAP_ID then return 'empty id' end
    local response,headers = http_request('GET', STRAFESNET_API_URL..'map/'..MAP_ID, API_HEADER)
    return response,headers
end

-- [[ CUSTOM ]] --

function API:GetMapCompletionCount(MAP_ID,STYLE_ID)
    if not MAP_ID or not STYLE_ID then return 'empty id' end
    local _,headers = self:GetMapTimes(MAP_ID,STYLE_ID)
    local pages = headers['Pagination-Count']
    local res,h = self:GetMapTimes(MAP_ID,STYLE_ID,pages)
    if not res then
        table.foreach(h,print)
    end
    return ((pages-1)*200)+#res
end
--cool doggo, aidan and me
function API.CalculatePoint(rank,count) --??wtf
    return RANK_CONSTANT_A*(math.exp(RANK_CONSTANT_B)-1)/(1-math.exp(math.max(-700, -RANK_CONSTANT_C*count)))*math.exp(math.max(-700, -RANK_CONSTANT_D*rank))+(1-RANK_CONSTANT_E)*(1+2*(count-rank))/(count*count)
end

function API.Pad(str,n)
    n = n or 20
    str = tostring(str)
    return str..string.rep(' ',n-#str)
end

function API.CalculateDifference(v1,v2)
    return math.abs(v1-v2)
end

function API.CalculateDifferencePercent(v1,v2)
    return math.abs((1-(v1/v2))*100)..'%'
end
function API:GetUserFromAny(user,message)
    local str = user:match('^["\'](.+)[\'"]$')
    local num = user:match('^(%d+)$')
    if str then
        local roblox_user=self:GetRobloxInfoFromUsername(str)
        if not roblox_user.id then return 'User not found' end
        return roblox_user
    elseif num then
        local roblox_user = self:GetRobloxInfoFromUserId(user)
        if not roblox_user.id then return 'Invalid user id' end
        return roblox_user
    elseif user=='me' then
        local me=message.author
        local roblox_user=self:GetRobloxInfoFromDiscordId(me.id)
        if not roblox_user.id then return 'You are not registered with the RoverAPI' end
        return roblox_user
    elseif user:match('<@%d+>') then
        local user_id=user:match('<@(%d+)>')
        local member=message.guild:getMember(user_id)
        local roblox_user=self:GetRobloxInfoFromDiscordId(member.id)
        if not roblox_user.id then return 'User is not registered with the RoverAPI' end
        return roblox_user
    else
        local roblox_user=self:GetRobloxInfoFromUsername(user)
        if not roblox_user.id then return 'User not found' end
        return roblox_user
    end
    return 'Something went wrong (this should generally not happen)'
end


-- [[ ROBLOX / ROVER AND OTHER APIs ]] --

function API:GetRobloxInfoFromUserId(USER_ID)
    if not USER_ID then return 'empty id' end
    local response,headers = http_request('GET', ROBLOX_API_URL..'users/'..USER_ID, API_HEADER)
    return response,headers
end

function API:GetRobloxInfoFromUsername(USERNAME)
    if not USERNAME then return 'empty id' end
    local err, res = parseToURLArgs({username=USERNAME})
    if err then return err end
    local response,headers = http_request('GET', ROBLOX_API_URL2..'users/get-by-username'..res, API_HEADER)
    if not response.Id then return 'no user found' end
    local response2 = http_request('GET', ROBLOX_API_URL..'users/'..response.Id, API_HEADER)
    return response2
end

function API:GetRobloxInfoFromDiscordId(DISCORD_ID)
    if not DISCORD_ID then return 'empty id' end
    local response,headers = http_request('GET', ROVER_API_URL..'user/'..DISCORD_ID, API_HEADER)
    if not response.robloxId and response.error then return response,headers.error end
    local response2 = http_request('GET', ROBLOX_API_URL..'users/'..response.robloxId, API_HEADER)
    return response2
end

function API:GetUserOnlineStatus(USER_ID) -- https://api.roblox.com/users/1455906620/onlinestatus
    if not USER_ID then return 'empty id' end
    local response,headers = http_request('GET', ROBLOX_API_URL2..'users/'..USER_ID..'/onlinestatus', API_HEADER)
    return response,headers
end

function API:GetUserThumbnail(USER_ID,TYPE,SIZE) -- https://thumbnails.roblox.com/v1/users/avatar?userIds=1455906620&size=180x180&format=Png&isCircular=false
    if not USER_ID then return 'empty id' end
    local _TYPE = self.ROBLOX_THUMBNAIL_TYPES[TYPE] or 'avatar'
    local _SIZE = self.ROBLOX_THUMBNAIL_SIZES[SIZE] or '180x180'
    local err, res = parseToURLArgs({userIds=USER_ID,size=_SIZE,format='Png',isCircular=false})
    if err then return err end
    local response,headers = http_request('GET', ROBLOX_THUMBNAIL_URL..'users/'.._TYPE..res, API_HEADER)
    return response,headers
end

return API