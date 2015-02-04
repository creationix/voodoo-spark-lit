local env = require('env')
local getAddress = require('./get-address')
local connect = require('creationix/coro-tcp').connect
local wrapper = require('creationix/coro-wrapper')
local uv = require('uv')
local bit = require('bit')

local function decode(chunk)
  if #chunk < 2 then return end
  local first = string.byte(chunk, 1)
  -- Return: 4 bytes which have 0x03 as the first byte, the pin as the second, lsb as third and msb as fourth.
  if first == 3 or first == 4 then
    if #chunk < 4 then return end
    return {
      command = first == 3 and "digitalRead" or "analogRead",
      pin = string.byte(chunk, 2),
      value = bit.bor(string.byte(chunk, 3), bit.lshift(string.byte(chunk, 4), 7)),
    }, string.sub(chunk, 5)
  elseif first == 5 then
    if #chunk < 4 then return end
    return {
      command = "bit",
      pin = string.byte(chunk, 2),
      value = bit.bor(string.byte(chunk, 3), bit.lshift(string.byte(chunk, 4), 7)),
    }, string.sub(chunk, 5)
  end
  error("Unknown byte prefix: " .. first)
end

local pinModes = {
  INPUT = "\0",
  OUTPUT = "\1",
  INPUT_PULLUP = "\2",
  INPUT_PULLDOWN = "\3",
  SERVO = "\4",
}

local alwaysModes = {
  DIGITAL = "\1",
  ANALOG = "\2",
}


local function makeApi(read, write)
  read = wrapper.reader(read, decode)
  local queue = {}
  coroutine.wrap(function ()
    for event in read do
      for i = 1, #queue do
        local item = queue[i]
        if item.command == event.command and
           item.pin == event.pin then
          table.remove(queue, i)
          coroutine.resume(item.co, event.value)
          break
        end
      end
    end
  end)()
  return {
    pinMode = function (pin, mode)
      write("\0" .. string.char(pin) .. (pinModes[mode] or error("Illegal mode: " .. mode)))
    end,
    digitalWrite = function (pin, value)
      write("\1" .. string.char(pin) .. string.char(value))
    end,
    analogWrite = function (pin, value)
      write("\2" .. string.char(pin) .. string.char(value))
    end,
    digitalRead = function (pin)
      write("\3" .. string.char(pin))
      queue[#queue + 1] = {
        command = "digitalRead",
        pin = pin,
        co = coroutine.running()
      }
      return coroutine.yield()
    end,
    analogRead = function (pin)
      write("\4" .. string.char(pin))
      queue[#queue + 1] = {
        command = "analogRead",
        pin = pin,
        co = coroutine.running()
      }
      return coroutine.yield()
    end,
    alwaysSendBit = function (pin, mode)
      write("\5" .. string.char(pin) .. (alwaysModes[mode] or error("Illegal mode: " .. mode)))
    end,
    setSampleInterval = function (interval)
      write("\6" .. string.char(bit.band(interval, 0x7f))
                 .. string.char(bit.band(bit.rshift(interval, 7), 0x75)))
    end,
  }
end


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

