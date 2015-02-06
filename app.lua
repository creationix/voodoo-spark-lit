local env = require('env')
local uv = require('uv')
local connect = require('coro-tcp').connect

local getAddress = require('./get-address')
local makeApi = require('./api')

local deviceID = env.get("SPARK_DEVICE_ID")
local accessToken = env.get("SPARK_TOKEN")
if not deviceID then
  error("SPARK_DEVICE_ID required in environment")
end
if not accessToken then
  error("SPARK_TOKEN require in environment")
end

local ip, port = getAddress(deviceID, accessToken)
p({ip=ip,port=port})

local api = makeApi(connect(ip, port))

p(api)

api.pinMode(6, "OUTPUT")
api.pinMode(7, "OUTPUT")
api.pinMode(2, "INPUT")
api.pinMode(4, "INPUT")
-- api.setSampleInterval(1000)
-- api.alwaysSendBit(2, "DIGITAL")

local on = false
local timer = uv.new_timer()
timer:start(500, 500, function ()
  local success, err = xpcall(function ()
    coroutine.wrap(function ()
      on = not on
      if on then
        api.digitalWrite(7, 1)
        api.digitalWrite(6, 0)
      else
        api.digitalWrite(7, 0)
        api.digitalWrite(6, 1)
      end
      p("read 2", api.digitalRead(2))
    end)()
  end, debug.traceback)
  if not success then error(err) end
end)

