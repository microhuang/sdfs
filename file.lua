-- todo: biz begin

-- biz end
ngx.header.content_type = "text/plain"


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
        ngx.say("token id not found")
        ngx.exit(200)
        --return
    end
else
        ngx.say("session id not found")
        ngx.exit(200)
        --return
end


--ngx.say(ngx.var.file_name)
local file_name=ngx.var.file_name
if file_name and string.len(file_name)>1 then
	ngx.header.content_type = "application/octet-stream; charset=utf-8"

	ngx.header.content_disposition = "attachment; filename=" .. file_name

	--ngx.header.x_accel_limit_rate = "102400"

	--ngx.header.x_accel_redirect = "/_file/" .. file_name
	--ngx.header.x_accel_redirect = "/_file/test.txt"
	ngx.header.x_accel_redirect = file_name
else
	ngx.header.content_type = "text/html; charset=utf-8"
	ngx.say('未指定文件!')
end



