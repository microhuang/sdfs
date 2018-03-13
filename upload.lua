package.path = '/var/opt/dfs/lua-resty-upload/lib/resty/?.lua;'
local upload = require "upload"


ngx.header.content_type = "text/plain"


--local fff = ngx.re.match('abcd.tar.gz','(\\w+)(.*)')
--ngx.say(fff[2])

--math.randomseed(tostring(os.time()):reverse():sub(1, 6))
--ngx.say(ngx.md5(math.random()));

-- check token
local token = ngx.req.get_uri_args()["token"]
local session = ngx.var.cookie_JSESSIONID
if token and string.len(token)>1 then
    local sessiondb = ngx.shared.sessiondb
    local t = sessiondb:get(token)
    if not t then
        ngx.say("token id not found")
        return
    end
else
        ngx.say("session id not found")
        return
end

-- paramers
local cross_domain = ngx.var.cross_domain
local file_path = ngx.var.file_path

--if not cross_domain then
--    ngx.say("cross domain")
--    return
--end

if not file_path then
    file_path = "/tmp/"
end

-- cross domain
-- xxx.yyy.zzz
ngx.header.Access_Control_Allow_Origin = cross_domain
-- true
ngx.header.Access_Control_Allow_Credentials = "true"

local chunk_size = 4096
local form = upload:new(chunk_size)
if not form then
    ngx.say("nothing uploaded")
    return
end
local file
local filelen=0
form:set_timeout(0) -- 1 sec
local filename = file_path

function file_exists(path)
  local file = io.open(path, "rb")
  if file then file:close() end
  return file ~= nil
end

function get_filename(res)
    local filename = ngx.re.match(res,'(.+)filename="(.+)"(.*)')
    if filename then
        --return filename[2]
        --ngx.say(filename[2])
        math.randomseed(tostring(os.time()):reverse():sub(1, 6))
        --ngx.say(ngx.md5(math.random()));
        local ext = ngx.re.match(filename[2],'(\\w+)(.*)')
        if ext and ext[2] then
            return ngx.md5(math.random()) .. ext[2]
        end
        return ngx.md5(math.random())
    end
end


local osfilepath = file_path
local i=0
while true do
    local typ, res, err = form:read()
    if not typ then
        ngx.say("failed to read: ", err)
        return
    end
    if typ == "header" then
        if res[1] ~= "Content-Type" then
            filename = get_filename(res[2])
            if filename then
                i=i+1
                filepath = osfilepath  .. filename
                if file_exists(filepath) then
                	ngx.say('{"code":500, "message":"系统错误，请稍后再试!"}')
                	return
                else
                	file = io.open(filepath,"wb+")
                	if not file then
                    ngx.say("failed to open file ")
                    return
                	end
                end
            else
            end
        end
    elseif typ == "body" then
        if file then
            filelen= filelen + tonumber(string.len(res))    
            file:write(res)
        else
        end
    elseif typ == "part_end" then
        if file then
            file:close()
            file = nil
            --ngx.say("file upload success: " .. filepath)
            ngx.say('{"code":200, "message":"file upload success", "data": "' .. filename .. '"}')
        end
    elseif typ == "eof" then
        break
    else
    end
end
if i==0 then
    ngx.say("please upload at least one file!")
    return
end



