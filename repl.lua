local env = require('env')
local connect = require('creationix/coro-tcp').connect
local tlsWrap = require('creationix/coro-tls').wrap
local httpCodec = require('creationix/http-codec')
local wrapper = require('creationix/coro-wrapper')
local jsonParse = require('creationix/json').parse

local deviceID = env.get("SPARK_DEVICE_ID")
local accessToken = env.get("SPARK_ACCESS_TOKEN")

if not deviceID then
  error("SPARK_DEVICE_ID required in environment")
end
if not accessToken then
  error("SPARK_ACCESS_TOKEN require in environment")
end

local req = {
  method = "GET",
  path = "/v1/devices/" .. deviceID .. "/endpoint?access_token=" .. accessToken,
  {"Host", "api.spark.io"},
  {"User-Agent", "lit"},
  {"Accept", "*/*"},
}
local read, write = assert(connect("api.spark.io", "https"))
read, write = tlsWrap(read, write)

read = wrapper.reader(read, httpCodec.decoder())
write = wrapper.writer(write, httpCodec.encoder())


p(req)
write(req)
local res = read()
p(res)
local body = {}
for chunk in read do
  body[#body + 1] = chunk
  if #chunk == 0 then break end
end
body = table.concat(body)
p(jsonParse(body))
write()
