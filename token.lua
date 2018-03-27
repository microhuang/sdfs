ngx.header.content_type = "text/plain"


function getToken()
--local fff = ngx.re.match('abcd.tar.gz','(\\w+)(.*)')
--ngx.say(fff[2])
    math.randomseed(tostring(os.time()):reverse():sub(1, 6))
    --ngx.say(ngx.md5(math.random()));
    return ngx.md5(math.random())
end

-- FastDFS1234567890 http.conf
function getFDFSToken(remote_filename,ts,secret_key)
	--local ts = os.time()
	--local secret_key = "FastDFS1234567890"
	return ngx.md5(remote_filename .. secret_key .. ts)
end


local sessiondb = ngx.shared.sessiondb
if not sessiondb then
    ngx.say("please init sessiondb in http: lua_shared_dict sessiondb XXXm;")
    return
end

local fdfs_file = ''
local sid = ''
local token = getToken()
local file_type = "jpeg"
local file_size = "10M"
-- owner user everyone
local file_mod = "0777"
-- 86400s
local file_timeout = 86400
local timestamp = os.time()

-- paramers
if ngx.req.get_uri_args()["fdfs_file"] then
    fdfs_file = ngx.req.get_uri_args()["fdfs_file"]
end
if ngx.req.get_uri_args()["sid"] then
    sid = ngx.req.get_uri_args()["sid"]
end
if ngx.req.get_uri_args()["file_timeout"] then
    file_timeout = ngx.req.get_uri_args()["file_timeout"]
end

local t = {}
t = {sid=sid,file_type=file_type,file_size=file_size,file_timeout=file_timeout,timestamp=timestamp}

local fdfs_token = ''
if fdfs_file~='' then
    fdfs_token = getFDFSToken(fdfs_file,timestamp,"FastDFS1234567890")
end

local cjson = require 'cjson';
--local success, err, forcible = sessiondb:set(token,cjson.encode(t))
local ok,err = sessiondb:safe_set(token,cjson.encode(t),file_timeout)
if ok then
    ngx.say('{"token":"'..token..'", "fdfs_token":"'..fdfs_token..'", "code":200, "message":"success!", "data":'..cjson.encode(t)..'}')
else
    ngx.say(err)
end



