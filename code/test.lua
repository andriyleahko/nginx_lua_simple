-- hello block and exit
-- ngx.say("Hello LUA")
--ngx.exit(ngx.HTTP_OK)
--end hello block

--block of functions
----------------------------------------------------------------------------
function serialize (mixed_value)
	-- body
	local val, key, okey,
		  ktype, vals, count, _type;

		  ktype = ''; vals = ''; count = 0;

	-- https://gist.github.com/978154
	_round = function(num) return math.floor(num + .5) end

	_utf8Size = function (str)
		local size, i, l, code, val;
		size = 0; i = 0;
		l = string.len(str); code = '';

		for i = 1, l, 1 do
			code = str:byte(i)
	        if code < 0x0080 then
	            val = 1
	        elseif code < 0x0800 then
	            val = 2
	        else
	            val = 3
			end
			size = size + val
		end

		return size
	end


	_type = type(mixed_value)

	if _type == 'function' then
		val = ''

	elseif _type == 'boolean' then
		val = 'b:' .. (mixed_value and '1' or '0')

	elseif _type == 'number' then
		val = (_round(mixed_value) == mixed_value and 'i' or 'd') .. ':' .. tostring(mixed_value)

	elseif _type == 'string' then
		val = 's:' .. _utf8Size(mixed_value) .. ':"' .. mixed_value .. '"'

	elseif _type == 'table' then
		val = 'a'

		for k,v in pairs(mixed_value) do
			ktype = type(v)
			if ktype ~= 'function' then

				vals = vals .. serialize(k) .. serialize(v)
				count = count + 1
			end
		end
		val = val .. ':' .. count .. ':{' .. vals .. '}'
	else
		--- if the object has a property which contains a null value, the string cannot be unserialized by PHP
		val = 'N'
	end

	if _type ~= 'table' then
		val = val ..';'
	end

	return val
end

local function unserialize (data)

	local function utf8Overhead (chr)
		local code = chr:byte()
		if (code < 0x0080) then
			return 0
		end

		if (code < 0x0800) then
			return 1
		end

		return 2
	end

	local function error (type, msg, filename, line)
		print ("[Error(" .. type .. ", " ..  message ..")]")
	end

	local function read_until (data, offset, stopchr)
		local buf, chr, len;

	    buf = {}; chr = data:sub(offset, offset);
		len = string.len(data);
	    while (chr ~= stopchr) do
	        if (offset > len) then
	           error('Error', 'Invalid')
		    end
	        table.insert(buf, chr)
			offset = offset + 1

	        chr = data:sub(offset, offset)
		end

	    return {table.getn(buf), table.concat(buf,'')};
	end

	local function read_chrs(data, offset, length)
		local i, buf;
		buf = {};
	    for i = 0, length - 1, 1 do
	        chr = data:sub(offset + i, offset + i);
	        table.insert(buf, chr);

	        length = length - utf8Overhead(chr);
		end
	    return {table.getn(buf), table.concat(buf,'')};
	end


	local function _unserialize(data, offset)
		local dtype, dataoffset, keyandchrs, keys,
			  readdata, readData, ccount, stringlength,
			  i, key, kprops, kchrs, vprops, vchrs, value,
              chrs, typeconvert;
		chrs = 0;
		typeconvert = function(x) return x end;

		if offset == nil then
			offset = 1 -- lua offsets starts at 1
		end

		dtype = string.lower(data:sub(offset, offset))
		-- print ("dtype " .. dtype .. " offset " ..offset)

		dataoffset = offset + 2
		if (dtype == 'i') or (dtype == 'd') then
			typeconvert = function(x)
				return tonumber(x)
			end

			readData = read_until(data, dataoffset, ';');
            chrs     = tonumber(readData[1]);
            readdata = readData[2];
            dataoffset = dataoffset + chrs + 1;

		elseif dtype == 'b' then
			typeconvert = function(x)
				return tonumber(x) ~= 0
			end

			readData = read_until(data, dataoffset, ';');
            chrs 	 = tonumber(readData[1]);
            readdata = readData[2];
            dataoffset = dataoffset + chrs + 1;
		elseif dtype == 'n' then
			readData = nil

		elseif dtype == 's' then
			ccount = read_until(data, dataoffset, ':');

			chrs         = tonumber(ccount[1]);
            stringlength = tonumber(ccount[2]);
            dataoffset = dataoffset + chrs + 2;

            readData = read_chrs(data, dataoffset, stringlength);
            chrs     = readData[1];
            readdata = readData[2];
            dataoffset = dataoffset + chrs + 2;

            if ((chrs ~= stringlength) and (chrs ~= string.length(readdata.length))) then
                error('SyntaxError', 'String length mismatch');
			end

		elseif dtype == 'a' then
			readdata = {}

			keyandchrs = read_until(data, dataoffset, ':');
            chrs = tonumber(keyandchrs[1]);
            keys = tonumber(keyandchrs[2]);

			dataoffset = dataoffset + chrs + 2

			for i = 0, keys - 1, 1 do
				kprops = _unserialize(data, dataoffset);

				kchrs  = tonumber(kprops[2]);
				key    = kprops[3];
				dataoffset = dataoffset + kchrs

				vprops = _unserialize(data, dataoffset)
                vchrs  = tonumber(vprops[2]);
                value  = vprops[3];
				dataoffset = dataoffset + vchrs;

                readdata[key] = value;
			end

			dataoffset = dataoffset + 1
		else
			error('SyntaxError', 'Unknown / Unhandled data type(s): ' + dtype);
		end

		return {dtype, dataoffset - offset, typeconvert(readdata)};
	end

	return _unserialize((data .. ''), 1)[3];
end



function strtotime(timeToConvert)
    -- Assuming a date pattern like: yyyy-mm-dd hh:mm:ss
    local pattern = "(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)"
    local runyear, runmonth, runday, runhour, runminute, runseconds = timeToConvert:match(pattern)
    return os.time({year = runyear, month = runmonth, day = runday, hour = runhour, min = runminute, sec = runseconds})
end

-- Escape any single quote with another (ANSI SQL-style):
function escapesinglequotes(s)
  return (string.gsub(s, "%'", "''"))
end
-- addslashesansi

-- Backslash-escape special characters:
function addslashes(s)
  -- Double quote, single quote, and backslash (per the PHP
  -- manual):
  s = string.gsub(s, "(['\"\\])", "\\%1")
  -- The null character gets turned into a pair of printing
  -- characters by PHP addslashes.  Let's do the same:
  return (string.gsub(s, "%z", "\\0"))
end
-- addslashes

local function formatSiteName(url, on_off_subdomain)
    if (string.find(url, "http") ~= nil or string.find(url, "https") ~= nil) then
        namePart = explode('://', url)
        nameWithoutHttp = namePart[2]
    else
        nameWithoutHttp = url
    end
    namePart = explode('.', nameWithoutHttp)
    if (on_off_subdomain == 1) then
        if (string.find(nameWithoutHttp, "www") == nil) then
          return namePart[2]
        else
            return namePart[3]
        end
    else
        if (string.find(nameWithoutHttp, "www") == nil) then
          return namePart[1]
        else
            return namePart[2]
        end
    end
end


local function in_array(tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end

    return false
end

local function decodeURI(s)
	if(s) then
		s = string.gsub(s, '%%(%x%x)',
		function (hex) return string.char(tonumber(hex,16)) end )
	end
	return s
end

local function encodeURI(str)
	if (str) then
		str = string.gsub (str, "\n", "\r\n")
		str = string.gsub (str, "([^%w ])",
    		function (c)
    		    if(c=='.') then
    		        return '.'
    		    elseif(c=='-') then
    		        return '-'
    		    elseif(c=='_') then
    		        return '_'
    		    else
    		        return string.format ("%%%02X", string.byte(c))
    		    end
    	    end
	    )
		str = string.gsub (str, " ", "+")
	end
	return str
end


function explode(div,str)
  if (div=='') then return false end
  local pos,arr = 0,{}
  -- for each divider found
  for st,sp in function() return string.find(str,div,pos,true) end do
    table.insert(arr,string.sub(str,pos,st-1)) -- Attach chars left of current divider
    pos = sp + 1 -- Jump past current divider
  end
  table.insert(arr,string.sub(str,pos)) -- Attach chars right of last divider
  return arr
end
----------------------------------------------------------------------------

-------------------------------------------
-- cjson module
local cjson = require "cjson"
-- end cjson module
-------------------------------------------

local urlOb = require "url"


-- connect to mysql module
local mysql = require "mysql"
local db, err = mysql:new()
-- end connect to mysql module



-- connect to database in mysql
local ok, err, errcode, sqlstate = db:connect{
    host = "127.0.0.1",
    database = "plusers",
    user = "plusers",
    password = "j7K8XkJDQxTAEZ2C",
}
-- end connect to database in mysql

-- check to connect
if not ok then
    ngx.say("failed to connect: ", err, ": ", errcode, " ", sqlstate)
    return
end
-- end check to connect

-- parse get param
local args = ngx.req.get_uri_args()
-- end parse get param
local params = args['params']

if(params == nil) then
    ngx.say("Params missing")
    return
end

local params = cjson.decode(params)

local ip = ngx.var.remote_addr

---
--global blocked ips
---
res, err, errcode, sqlstate = db:query("SELECT `sett_name`, `value` FROM `global_settings` WHERE `sett_name` = 'clicks_blocked_remote_addresses' LIMIT 1")
local bloked_ips = res[1]['value']
local ips = explode('|',bloked_ips);

if (in_array(ips, ip)) then
    ngx.say("Your ip blocked")
    return
end

if (params['user_hash'] == nil or params['suid'] == nil or params['site_url'] == nil or params['position']['y'] == nil or params['position']['totalY'] == nil or params['page_url'] == nil or params['ip_visitor'] == nil) then
    ngx.say("Required params missing")
    return
end

local md5 = require "md5"
--ngx.say(md5.sumhexa("aaa"))

if (md5.sumhexa(md5.sumhexa(params['suid'] .. 'click')) ~= params['user_hash']) then
     ngx.say("Wrong hash code")
     return
end


local id = tonumber(params['suid'])
if (id == nil) then
    return
end

-- get user from database
user, err, errcode, sqlstate = db:query("SELECT `id`, `name` FROM `users` WHERE `id` = ".. addslashes(id) .." LIMIT 1")

-- check if user exist
if (user[1] == nil or user[1]['id'] == nil) then
    ngx.say("User not found")
    return
end

site, err, errcode, sqlstate = db:query("SELECT * FROM `sites_click_map` WHERE `user_id` =".. addslashes(user[1]['id']) .." LIMIT 1")

-- check if site params exist
if (site[1] == nil or site[1]['id'] == nil) then
    ngx.say("Not find site params")
    return
end

-- check if enabled
if (site[1]['enabled'] == 0 ) then
    ngx.say("Site is disabled")
    return
end

-- check for limit save--
if (site[1]['on_off_save'] == 0 ) then
    ngx.say("Limit reached")
    return
end

-- check site name
if ( (formatSiteName(site[1]['url'],0) ~= formatSiteName(params['site_url'],site[1]['on_off_subdomain'])) and (formatSiteName(site[1]['url'],0) ~= formatSiteName(params['site_url'],0)) ) then
    local status, err, errcode, sqlstate = db:query("UPDATE `sites_click_map` SET `code_status` = 2 WHERE `user_id` = " .. addslashes(user[1]['id']))
    ngx.say('Wrong host')
    return
end


if (site[1]['blocked_remote_addresses'] ~= nil and site[1]['blocked_remote_addresses'] ~= ngx.null) then
    ips = explode('|', site[1]['blocked_remote_addresses'])
    if (ips ~= nil and in_array(ips, ip)) then
        ngx.say("Your ip blocked")
        return
    end
end



-- set status code for init click
if (site[1]['code_status'] ~= 1) then
    local status, err, errcode, sqlstate = db:query("UPDATE `sites_click_map` SET `code_status` = 1 WHERE `user_id` = " .. addslashes(user[1]['id']) )
end


tags, err, errcode, sqlstate = db:query("SELECT * FROM `tags`")
tags_all = {}
for k, t in pairs(tags) do
    tags_all[t['name']] = t['id'];
end

if (tags_all[params['tag_name'][1]] ~= nil) then
    el_on_click = tags_all[params['tag_name'][1]]
else
    local tag, err, errcode, sqlstate = db:query("insert tags(name) values('".. addslashes(params['tag_name'][1]) .."');")
    el_on_click =  tag.insert_id
end

tags_all = nil
tag = nil
site = nil

local superUserData, err, errcode, sqlstate = db:query("SELECT * FROM `superusers_data` WHERE `user_id` = ".. addslashes(user[1]['id']) .." LIMIT 1")

if (superUserData[1]['db_host'] == nil) then
    ngx.say("No connect")
    return
end




-- connect to database in mysql
local ok, err, errcode, sqlstate = db:connect{
    host = "127.0.0.1",
    database = superUserData[1]['db_name'],
    user = superUserData[1]['db_username'],
    password = superUserData[1]['db_password'],
}
-- end connect to database in mysql

-- check to connect
if not ok then
    ngx.say("failed to connect: ", err, ": ", errcode, " ", sqlstate)
    return
end
-- end check to connect


local click, err, errcode, sqlstate = db:query("insert clicks(y, totalY, tag_name, page_url, ip_visitor, updated_at, created_at, device, node_number, el_on_click, traffic_source, class) values('".. addslashes(params['position']['y']) .."','".. addslashes(params['position']['totalY']) .."', '".. serialize(params['tag_name']) .."', '".. encodeURI(decodeURI(decodeURI(params['page_url']))) .."', '".. addslashes(params['ip_visitor']) .."', '".. os.date("%Y-%m-%d %X", os.time()) .."', '".. os.date("%Y-%m-%d %X", os.time()) .."', '".. addslashes(params['device']) .."', '".. serialize(params['node_number']) .."', '".. el_on_click .."', '".. addslashes(params['traffic_source']) .."', '".. addslashes(params['class_name']) .."');")

if not click then
    ngx.say("failed to connect: ", err, ": ", errcode, " ", sqlstate)
    return
end

ngx.say('ok')
