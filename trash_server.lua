local Tunnel = module("vrp", "lib/Tunnel")
local Proxy = module("vrp", "lib/Proxy")
vRP = Proxy.getInterface("vRP")
heyyczer = {}
Tunnel.bindInterface("emp_lixeiro", heyyczer)


function heyyczer.checkPayment()
    local source = source
    local user_id = vRP.getUserId(source)
	if user_id then
		local money = math.random(cfg.minMoneyValue, cfg.maxMoneyValue)
		
		vRP.giveMoney(user_id, money)
		TriggerClientEvent("Notify", source, "sucesso", "Você recebeu <b>$" .. money .. " dólares</b> pelo saco de lixo.")
	end
end