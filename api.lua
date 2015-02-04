local wrapper = require('creationix/coro-wrapper')
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


return function (read, write)
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
