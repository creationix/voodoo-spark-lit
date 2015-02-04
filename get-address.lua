local connect = require('creationix/coro-tcp').connect
local tlsWrap = require('creationix/coro-tls').wrap
local httpCodec = require('creationix/http-codec')
local wrapper = require('creationix/coro-wrapper')
local jsonParse = require('creationix/json').parse

return function (deviceId, accessToken)
  assert(deviceId and accessToken)
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
  body = assert(jsonParse(table.concat(body)))
  p(body)
  local ip, port = string.match(body.result, "^([^:]+):(.*)$")
  port = tonumber(port)
  return ip, port
end
