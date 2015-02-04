require('luvi').bundle.register("require", "modules/creationix/require.lua");
local uv = require('uv')
local require = require('require')()("bundle:main.lua")
_G.p = require('creationix/pretty-print').prettyPrint
p("TODO: Implement voodoospark protocol and link to readline repl.")


--  curl https://api.spark.io/v1/devices/{DEVICE-ID}/endpoint?access_token={ACCESS-TOKEN}
-- {
--   "cmd": "VarReturn",
--   "name": "endpoint",
--   "result": "192.168.1.10:48879",
--   "coreInfo": {
--     "last_app": "",
--     "last_heard": "2014-05-08T02:51:48.826Z",
--     "connected": true,
--     "deviceID": "{DEVICE-ID}"
--   }
-- }

-- http://voodoospark.me/#api

uv.run()
