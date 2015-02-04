require('luvi').bundle.register("require", "modules/creationix/require.lua");
local uv = require('uv')
local require = require('require')()("bundle:main.lua")
_G.p = require('creationix/pretty-print').prettyPrint

local exitCode = 0
coroutine.wrap(function ()
  local success, err = xpcall(function ()
    require('./repl')
  end, debug.traceback)
  if not success then
    print(err)
    exitCode = -1
  end
end)()

uv.run()

return exitCode
