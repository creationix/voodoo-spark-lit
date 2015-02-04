local env = require('env')
local getAddress = require('./get-address')
local connect = require('creationix/coro-tcp').connect
local uv = require('uv')

local deviceID = env.get("SPARK_DEVICE_ID")
local accessToken = env.get("SPARK_ACCESS_TOKEN")
if not deviceID then
  error("SPARK_DEVICE_ID required in environment")
end
if not accessToken then
  error("SPARK_ACCESS_TOKEN require in environment")
end

local ip, port = getAddress(deviceID, accessToken)
p({ip=ip,port=port})

local read, write, handle = connect(ip, port)
p{read=read,write=write,handle=handle}

-- pinMode(6, OUTPUT);
write("\0\6\1")
-- pinMode(7, OUTPUT);
write("\0\2\1")
-- pinMode(2, INPUT);
write("\0\2\0")
-- pinMode(4, INPUT);
write("\0\4\0")


local on = false
local timer = uv.new_timer()
timer:start(500, 500, function ()
  on = not on
  if on then
    write("\1\7\1\1\6\0")
  else
    write("\1\7\0\1\6\1")
  end
end)

