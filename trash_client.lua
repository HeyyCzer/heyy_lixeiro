local Tunnel = module("vrp", "lib/Tunnel")
local Proxy = module("vrp", "lib/Proxy")
heyyczer = Tunnel.getInterface("emp_lixeiro")
vRP = Proxy.getInterface("vRP")

local trabalhando = false
local IsSegurando = false

local blips = nil
local garbageBag = nil
local truck = nil

local lastDist = 1000
local lastBinBagPos = {}
local lastBinBag = nil

local blipCoords = cfg.blipCoords

RegisterCommand("cancelandoFalse", function(source, args, rawCommand)
	TriggerEvent("cancelando", false)
end)

-- ENTRAR EM SERVIÇO
Citizen.CreateThread(function()
	while true do
		if not trabalhando then
			Citizen.Wait(5)
			local ped = PlayerPedId()
			local x,y,z = table.unpack(GetEntityCoords(ped))
			local distance = GetDistanceBetweenCoords(blipCoords.x,blipCoords.y,blipCoords.z,x,y,z,true)

			if distance <= 30.0 then
				DrawMarker(21,blipCoords.x,blipCoords.y,blipCoords.z-0.6,0,0,0,0.0,0,0,0.5,0.5,0.4,255,0,0,50,0,0,0,1)
				if distance <= 1.2 then
					DrawTxtabcdefg("PRESSIONE ~r~E~w~ PARA INICIAR O SERVIÇO",4,0.5,0.93,0.50,255,255,255,180)
					if IsControlJustPressed(0,38) then
						trabalhando = true
						
						TriggerEvent("Notify", "sucesso", "Você entrou no serviço de Lixeiro. Para continuar realizar a coleta, se encaminhe para um <b>Saco de Lixo</b> próximo, estes são marcados em seu GPS com um <b>ponto amarelo</b>.")
					end
				end
			end
		else
			Citizen.Wait(5000)
		end
	end
end)
-- FINALIZAR SERVIÇO
Citizen.CreateThread(function()
	while true do
		if trabalhando then
			Citizen.Wait(20)
			if IsControlJustPressed(0,168) then
				RemoveBlip(blips)
				DeleteEntity(garbageBag)
				
				trabalhando = false
				
				IsAnimated = false
				IsSegurando = false
				
				truck = nil
				garbageBag = nil
				blips = nil
			end
		else
			Citizen.Wait(5000)
		end
	end
end)



-- TRABALHAR
Citizen.CreateThread(function()
    while true do
		if trabalhando then
			Citizen.Wait(5)
			
			if not IsAnimated and not IsSegurando then
				local ped = GetPlayerPed(-1)
				local pos = GetEntityCoords(ped)
				local proximo = false

				

				if lastDist < 1.3 then
					-- DrawTxtabcdefg("[~r~E~w~] RECOLHER LIXO", 4, 0.5, 0.93, 0.50, 255, 255, 255, 180)
					Draw3DText("[~r~E~w~] RECOLHER LIXO", lastBinBagPos.x, lastBinBagPos.y, lastBinBagPos.z)
					proximo = true
					if IsControlJustReleased(0, 38) then
						if not IsAnimated then
							IsAnimated = true

							vRP.playAnim(true,{{"pickup_object","pickup_low"}},false)

							Citizen.Wait(GetAnimDuration("pickup_object","pickup_low") * 1000 / 1.5)
							Citizen.CreateThread(function()
								local playerPed = PlayerPedId()
								local x, y, z = table.unpack(GetEntityCoords(playerPed))
								
								while garbageBag do
									SetModelAsNoLongerNeeded(garbageBag)
									SetEntityAsMissionEntity(garbageBag, false, false)
									DeleteObject(garbageBag)
									garbageBag = nil
								end
									
								while not HasAnimDictLoaded("anim@heists@narcotics@trash") do
									RequestAnimDict("anim@heists@narcotics@trash")
									Citizen.Wait(5)
								end
									
								garbageBag = CreateObject(GetHashKey("prop_cs_street_binbag_01"), 0, 0, 0, true, true, true)
								AttachEntityToEntity(garbageBag, GetPlayerPed(-1), GetPedBoneIndex(GetPlayerPed(-1), 57005), 0.4, 0, 0, 0, 270.0, 60.0, true, true, false, true, 1, true)

								-- TriggerEvent('cancelando', true)
								ClearPedTasksImmediately(playerPed)
								TaskPlayAnim(playerPed, 'anim@heists@narcotics@trash', 'walk', 1.0, -1.0,-1,49,0,0, 0,0)
									
								IsSegurando = true
								
								SetModelAsNoLongerNeeded(lastBinBag)
								SetEntityAsMissionEntity(lastBinBag, false, false)
								DeleteObject(lastBinBag)
							end)
						end
					end
						-- break
					-- end
				end


				if not proximo then
					Citizen.Wait(1500)
				end
			elseif IsAnimated and IsSegurando then
				local trunk = GetWorldPositionOfEntityBone(truck, GetEntityBoneIndexByName(truck, "platelight"))
 				local plyCoords = GetEntityCoords(GetPlayerPed(-1), false)
				local dist = Vdist(plyCoords.x, plyCoords.y, plyCoords.z, trunk.x, trunk.y, trunk.z)
				if dist <= 1.3 then
					Draw3DText("[~g~E~w~] JOGAR LIXO", trunk.x, trunk.y, trunk.z + 0.5)
					if IsControlJustReleased(0, 38) then
						jogarLixo()
					end
				end
			else
				Citizen.Wait(1000)
			end
		else
			Citizen.Wait(3000)
		end
    end
end)

Citizen.CreateThread(function()
	while true do
		if trabalhando then
			Citizen.Wait(2500)

			local abc = {}
			local distance = -1
			for _, model in ipairs(cfg.binbagsModels) do
				local pos = GetEntityCoords(GetPlayerPed(-1))
				local binBag = GetClosestObjectOfType(pos.x, pos.y, pos.z, 100.0, model, false, false, false)
				local binBagPos = GetEntityCoords(binBag)
				local plyCoords = GetEntityCoords(GetPlayerPed(-1), false)
				local dist = Vdist(plyCoords.x, plyCoords.y, plyCoords.z, binBagPos.x, binBagPos.y, binBagPos.z)
				if dist < distance or distance == -1 then
					abc = binBagPos
					distance = dist
					-- print(dist .. " | " .. distance)
				end
			end
			
			CriandoBlip(abc.x, abc.y, abc.z)
			
			Citizen.Wait(2500)

			local truckTemp = GetPlayersLastVehicle()
			local isLegalVehicle = false
					
			for _, vehicleModel in ipairs(cfg.garbageTruckModels) do
				-- print(vehicleModel)
				-- print(GetHashKey(vehicleModel))
				if GetEntityModel(truckTemp) == GetHashKey(vehicleModel) then
					isLegalVehicle = true
					-- print("LegalVehicle")
				end
			end
			
			if isLegalVehicle then
				truck = truckTemp
			end
			-- print(truck)
			-- print(truckTemp)
		else
			Citizen.Wait(5000)
		end
	end
end)

Citizen.CreateThread(function()
	while true do
		if trabalhando then
			local counter = 0
			for _, model in ipairs(cfg.binbagsModels) do
				local pos = GetEntityCoords(GetPlayerPed(-1))
				local binBag = GetClosestObjectOfType(pos.x, pos.y, pos.z, 10.0, model, false, false, false)
				local binBagPos = GetEntityCoords(binBag)
				local dist = GetDistanceBetweenCoords(pos.x, pos.y, pos.z, binBagPos.x, binBagPos.y, binBagPos.z, true)
			
				if dist <= lastDist then
					lastDist = dist
					lastBinBagPos = binBagPos
					lastBinBag = binBag
				else
					counter = counter + 1
				end
			end
			
			if counter >= #cfg.binbagsModels then
				lastDist = 10
			end
			
			Citizen.Wait(1500)
		else
			lastDist = 1000
			Citizen.Wait(3000)
		end
	end
end)

function jogarLixo()
	IsAnimated = false
	IsSegurando = false

	-- TriggerEvent('cancelando', false)

	while not HasAnimDictLoaded("anim@heists@narcotics@trash") do
		RequestAnimDict("anim@heists@narcotics@trash")
		Citizen.Wait(5)
	end

	SetVehicleDoorOpen(truck, 5, false, false)


	ClearPedTasksImmediately(GetPlayerPed(-1))
	TaskPlayAnim(PlayerPedId(-1), 'anim@heists@narcotics@trash', 'throw_b', 1.0, -1.0,-1,2,0,0, 0,0)
 	Citizen.Wait(800)
	
	DeleteEntity(garbageBag)
	heyyczer.checkPayment()
	
	Citizen.Wait(100)
	ClearPedTasksImmediately(GetPlayerPed(-1))
	
	SetVehicleDoorShut(truck, 5, false, false)
end



function CriandoBlip(x, y, z)
	if blips and DoesBlipExist(blips) then
		RemoveBlip(blips)
	end
	
	blips = AddBlipForCoord(x, y, z)
	SetBlipSprite(blips, 1)
	SetBlipColour(blips, 5)
	SetBlipScale(blips, 0.4)
	SetBlipAsShortRange(blips, false)
	SetBlipRoute(blips, true)
	BeginTextCommandSetBlipName("STRING")
	AddTextComponentString("Coleta de Lixo")
	EndTextCommandSetBlipName(blips)
end
function DrawTxtabcdefg(text, font, x, y, scale, r, g, b, a)
    SetTextFont(font)
    SetTextScale(scale, scale)
    SetTextColour(r, g, b, a)
    SetTextOutline()
    SetTextCentre(1)
    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText(x, y)
end
function Draw3DText(text, x,y,z)
	local onScreen,_x,_y = World3dToScreen2d(x,y,z)
	SetTextFont(4)
	SetTextScale(0.35,0.35)
	SetTextColour(255,255,255,150)
	SetTextEntry("STRING")
	SetTextCentre(1)
	AddTextComponentString(text)
	DrawText(_x,_y)
	local factor = (string.len(text))/370
	DrawRect(_x,_y+0.0125,0.01+factor,0.03,0,0,0,80)
end

