package.path = '/var/opt/dfs/lua-resty-upload/lib/?.lua;' .. package.path

package.path = '/var/opt/dfs/lua-resty-fastdfs/lib/?.lua;' .. package.path

function _dump_res(res)
    for i in pairs(res) do
        ngx.say(string.format("%s:%s",i, res[i]))
    end
    ngx.say("")
end

function fdfs_storage(ip)
	local tracker = require('resty.fastdfs.tracker')
	local storage = require('resty.fastdfs.storage')
	local tk, err = tracker:new()
	if not tk then
	    ngx.say('get tracker error:' .. err)
	    ngx.exit(200)
	end
	tk:set_timeout(3000)
	local ok, err = tk:connect({host=ip,port=22122})
	if not ok then
	    ngx.say('connect error:' .. err)
	    ngx.exit(200)
	end
	local res, err = tk:query_storage_store()
	if not res then
	    ngx.say("query storage error:" .. err)
	    ngx.exit(200)
	end
	local st = storage:new()
	st:set_timeout(3000)
	local ok, err = st:connect(res)
	if not ok then
	    ngx.say("connect storage error:" .. err)
	    ngx.exit(200)
	end
	return st
end

function file_exists(path)
  local file = io.open(path, "rb")
  if file then file:close() end
  return file ~= nil
end

function get_filename(res)
    local filename = ngx.re.match(res,'(.+)filename="(.+)"(.*)')
    if filename then
        --return filename[2]
        math.randomseed(tostring(os.time()):reverse():sub(1, 6))
        --ngx.say(ngx.md5(math.random()));
local sdfs_path = ngx.re.match(filename[2],'/?(.*)/')
if sdfs_path and sdfs_path[1] then
--ngx.say(sdfs_path[1])
    sdfs_path = sdfs_path[1]
else
    sdfs_path = ''
end
        local ext = ngx.re.match(filename[2],'/?((\\w+)/?)*(\\w*)(\\..*)')
        if ext and ext[4] then
--ngx.say(ext[1])
--ngx.say(ext[2])
--ngx.say(ext[3])
--ngx.say(ext[4])
            return ngx.md5(math.random()), ext[4], sdfs_path
        end
        return ngx.md5(math.random()), '', sdfs_path
    end
end


ngx.header.content_type = "text/plain"

-- config
local tk_ip = '127.0.0.1'
local ext = ''


--local fff = ngx.re.match('abcd.tar.gz','(\\w+)(.*)')
--ngx.say(fff[2])

--math.randomseed(tostring(os.time()):reverse():sub(1, 6))
--ngx.say(ngx.md5(math.random()));

-- check token
local token = ngx.req.get_uri_args()["token"]
local session = ngx.var.cookie_JSESSIONID
if token and string.len(token)>1 then
    local sessiondb = ngx.shared.sessiondb
    if not sessiondb then
        ngx.say("please init sessiondb in http: lua_shared_dict sessiondb XXXm;")
        return
    end
    local t = sessiondb:get(token)
    if not t then
        --ngx.say("token id not found")
        --return
    end
else
    --ngx.say("session id not found")
    --return
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


local upload = require "resty.upload"

local chunk_size = 4096
local form = upload:new(chunk_size)
if not form then
    ngx.say("nothing uploaded")
    return
end
form:set_timeout(0) -- 1 sec

local file
local filelen=0
local filename = file_path

local osfilepath = file_path

local files = {}
local i=0

-- 
local sdfs_path = ''
local sres = nil
local serr = nil

while true do
    local typ, res, err = form:read()
    if not typ then
        ngx.say("failed to read: ", err)
        return
    end
    if typ == "header" then
        if res[1] ~= "Content-Type" then
            filename,ext,sdfs_path = get_filename(res[2])
            if filename then
                i=i+1
                if not(sdfs_path=='' or sdfs_path==nil) then --自定义路径目前只能本地存储
			  --ngx.say(osfilepath  .. sdfs_path .. '/' .. filename .. ext)
                    filepath = osfilepath  .. sdfs_path .. '/' .. filename .. ext
                	  --filepath = filepath .. ext
		        --filepath = osfilepath  .. filename
		        if file_exists(filepath) then
		        	ngx.say('{"code":500, "message":"系统错误，请稍后再试!"}')
		        	return
		        else
		        	file = io.open(filepath,"wb+")
		        	files[i] = filepath
		        	if not file then
		               ngx.say("failed to open file ")
		               return
		        	end
		        end
                else --dfs存储
		        sres = nil
		        serr = nil
                end
            else
		    -- 没有文件名？
		    --ngx.say('{"code":500, "message":"系统错误，请稍后再试!"}')
		    sres = 1
		    serr = 1
            end
        end
    elseif typ == "body" then
        if file then
            filelen= filelen + tonumber(string.len(res))    
            file:write(res)
        else
		if sres==1 then
		else
			  local st = fdfs_storage(tk_ip)
			if (not not ext) and (string.sub(ext,1,1)==".") then
			    ext = string.sub(ext,2)
			    ext = string.sub(ext,-6)
			    ext = string.gsub(ext,"^[%s.]*(.-)[%s.]*$","%1")
			end
			  if sres==nil then
			      sres, serr = st:upload_appender_by_buff(res,ext)
			      files[i] = sres.file_name
				--local metadata = {origin_name="abcd.txt"}
				--local aa,bb=st:set_metadata(sres.group_name,sres.file_name,metadata,"O");
			else
			      local ok, err = st:append_by_buff(sres.group_name,sres.file_name,res)
			end
			  --ngx.say("upload success:" .. sres.file_name)
		end
        end
    elseif typ == "part_end" then
        if file then
            file:close()
            file = nil
            --ngx.say("file upload success: " .. filepath)
            ngx.say('{"code":200, "message":"file upload success", "data": "' .. filename .. '", "file":{"originalname":"' .. filepath .. '","size":123,"path":"' .. filename .. '"}}')
        else
		sres = nil
		serr = nil
        end
    elseif typ == "eof" then
        sres = nil
        serr = nil
        break
    else
    end
end

if i==0 then
    ngx.say("please upload at least one file!")
    return
end

local cjson = require 'cjson';
ngx.say('{"code":200, "message":"file upload success", "files":' .. cjson.encode(files) .. '}')




