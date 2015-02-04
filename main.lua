require('luvi').bundle.register("require", "modules/creationix/require.lua");
local uv = require('uv')
local require = require('require')()("bundle:main.lua")
_G.p = require('creationix/pretty-print').prettyPrint

local exitCode = 0
coroutine.wrap(function ()
  local success, err = xpcall(function ()
    require('./app')
  end, debug.traceback)
  if not success then
    print(err)
    exitCode = -1
    uv.stop()
  end
end)()

uv.run()

return exitCode
