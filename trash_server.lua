local Tunnel = module("vrp", "lib/Tunnel")
local Proxy = module("vrp", "lib/Proxy")
vRP = Proxy.getInterface("vRP")
heyyczer = {}
Tunnel.bindInterface("emp_lixeiro", heyyczer)


function heyyczer.checkPayment()
    local source = source
    local user_id = vRP.getUserId(source)
	
	if user_id then
		vRP.giveMoney(user_id, math.random(cfg.minMoneyValue, cfg.maxMoneyValue))
	end
end