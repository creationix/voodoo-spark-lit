require('luvi').bundle.register("require", "modules/creationix/require.lua");
local uv = require('uv')
local require = require('require')()("bundle:main.lua")
_G.p = require('creationix/pretty-print').prettyPrint
p("TODO: Implement voodoospark protocol and link to readline repl.")
uv.run()
