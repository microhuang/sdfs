ngx.header.content_type = "text/plain"


function getToken()
--local fff = ngx.re.match('abcd.tar.gz','(\\w+)(.*)')
--ngx.say(fff[2])
    math.randomseed(tostring(os.time()):reverse():sub(1, 6))
    --ngx.say(ngx.md5(math.random()));
    return ngx.md5(math.random())
end


local sessiondb = ngx.shared.sessiondb
if not sessiondb then
    ngx.say("please init sessiondb in http: lua_shared_dict sessiondb XXXm;")
    return
end

-- paramers
--local sid = ngx.var.cookie_JSESSIONID
local token = getToken()
local file_type = "jpeg"
local file_size = "10M"
-- owner user everyone
local file_mod = "0777"
local file_timeout = 3600
local timestamp = os.time()
local t = {}
t = {token=token,file_type=file_type,file_size=file_size,timestamp=timestamp}

local cjson = require 'cjson';
--local success, err, forcible = sessiondb:set(token,cjson.encode(t))
-- 86400s
local ok,err = sessiondb:safe_set(token,cjson.encode(t),86400)
if ok then
    ngx.say('{"sdfs_token":"'..token..'", "code":200, "message":"success!"}')
else
    ngx.say(err)
end



