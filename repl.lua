local env = require('env')
local connect = require('creationix/coro-tcp').connect
local tlsWrap = require('creationix/coro-tls').wrap
local httpCodec = require('creationix/http-codec')
local wrapper = require('creationix/coro-wrapper')

local deviceID = env.get("SPARK_DEVICE_ID")
local accessToken = env.get("SPARK_ACCESS_TOKEN")

if not deviceID then
  error("SPARK_DEVICE_ID required in environment")
end
if not accessToken then
  error("SPARK_ACCESS_TOKEN require in environment")
end

local read, write = assert(connect("api.spark.io", "https"))
read, write = tlsWrap(read, write)

read = wrapper.reader(read, httpCodec.decoder())
write = wrapper.writer(write, httpCodec.encoder())


local req = {
  method = "GET",
  path = "/v1/devices/" .. deviceID .. "/endpoint?access_token=" .. accessToken
}
write(req)
local res = read()

p(req)
p(res)
