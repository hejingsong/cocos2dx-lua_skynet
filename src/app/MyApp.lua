
require("app.LoginTest")
local MyApp = class("MyApp", cc.load("mvc").AppBase)

function MyApp:onCreate()
    math.randomseed(os.time())

    local s = crypt.hashkey("Hello World.")
    printInfo("ret: %s", s)
end

return MyApp
