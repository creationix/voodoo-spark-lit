local env = require('env')
local getAddress = require('./get-address')
local connect = require('creationix/coro-tcp').connect

local deviceID = env.get("SPARK_DEVICE_ID")
local accessToken = env.get("SPARK_ACCESS_TOKEN")
if not deviceID then
  error("SPARK_DEVICE_ID required in environment")
end
if not accessToken then
  error("SPARK_ACCESS_TOKEN require in environment")
end

local read, write, handle = connect(getAddress(deviceID, accessToken))
p{read=read,write=write,handle=handle}



