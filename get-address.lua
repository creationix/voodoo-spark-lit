local connect = require('coro-tcp').connect
local tlsWrap = require('coro-tls').wrap
local httpCodec = require('http-codec')
local wrapper = require('coro-wrapper')
local fs = require('coro-fs')
local jsonParse = require('json').parse

return function (deviceId, accessToken)
  assert(deviceId and accessToken)

  local json = fs.readFile("address." .. deviceId)
  if not json then

    local req = {
      method = "GET",
      path = "/v1/devices/" .. deviceId .. "/endpoint?access_token=" .. accessToken,
      {"Host", "api.spark.io"},
      {"User-Agent", "lit"},
      {"Accept", "*/*"},
    }
    local read, write = assert(connect("api.spark.io", "https"))
    read, write = tlsWrap(read, write)

    read = wrapper.reader(read, httpCodec.decoder())
    write = wrapper.writer(write, httpCodec.encoder())

    write(req)
    p(req)
    local res = read()
    p(res)
    assert(res.code == 200)
    local body = {}
    for chunk in read do
      p(chunk)
      body[#body + 1] = chunk
      if #chunk == 0 then break end
    end
    json = table.concat(body)
    fs.writeFile("address." .. deviceId, json)
  end
  json = jsonParse(json)
  p(json)
  local ip, port = string.match(json.result, "^([^:]+):(.*)$")
  port = tonumber(port)
  return ip, port
end
