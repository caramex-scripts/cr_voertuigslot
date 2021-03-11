ESX               = nil

local Keys = {
	["ESC"] = 322, ["F1"] = 288, ["F2"] = 289, ["F3"] = 170, ["F5"] = 166, ["F6"] = 167, ["F7"] = 168, ["F8"] = 169, ["F9"] = 56, ["F10"] = 57,
	["~"] = 243, ["1"] = 157, ["2"] = 158, ["3"] = 160, ["4"] = 164, ["5"] = 165, ["6"] = 159, ["7"] = 161, ["8"] = 162, ["9"] = 163, ["-"] = 84, ["="] = 83, ["BACKSPACE"] = 177,
	["TAB"] = 37, ["Q"] = 44, ["W"] = 32, ["E"] = 38, ["R"] = 45, ["T"] = 245, ["Y"] = 246, ["U"] = 303, ["P"] = 199, ["["] = 39, ["]"] = 40, ["ENTER"] = 18,
	["CAPS"] = 137, ["A"] = 34, ["S"] = 8, ["D"] = 9, ["F"] = 23, ["G"] = 47, ["H"] = 74, ["K"] = 311, ["L"] = 182,
	["LEFTSHIFT"] = 21, ["Z"] = 20, ["X"] = 73, ["C"] = 26, ["V"] = 0, ["B"] = 29, ["N"] = 249, ["M"] = 244, [","] = 82, ["."] = 81,
	["LEFTCTRL"] = 36, ["LEFTALT"] = 19, ["SPACE"] = 22, ["RIGHTCTRL"] = 70,
	["HOME"] = 213, ["PAGEUP"] = 10, ["PAGEDOWN"] = 11, ["DELETE"] = 178,
	["LEFT"] = 174, ["RIGHT"] = 175, ["TOP"] = 27, ["DOWN"] = 173,
	["NENTER"] = 201, ["N4"] = 108, ["N5"] = 60, ["N6"] = 107, ["N+"] = 96, ["N-"] = 97, ["N7"] = 117, ["N8"] = 61, ["N9"] = 118
}

local isRunningWorkaround = false

Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
	end
end)

function DrawText3Ds(x,y,z, text)
    local onScreen,_x,_y=World3dToScreen2d(x,y,z)
    local px,py,pz=table.unpack(GetGameplayCamCoords())
    
    SetTextScale(0.27, 0.27)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(_x,_y)
end

function DrawText3Ds2(x,y,z, text)
    local onScreen,_x,_y=World3dToScreen2d(x,y,z)
    local px,py,pz=table.unpack(GetGameplayCamCoords())
    
    SetTextScale(0.27, 0.27)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(_x,_y)
end

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)

		local ped = PlayerPedId()
		local pedCoords = GetEntityCoords(ped)
		local vehicle = GetClosestVehicle(pedCoords, 3.0, false, 70)
		local vehCoords = GetEntityCoords(vehicle)
		local plate = GetVehicleNumberPlateText(vehicle)
		local distance = GetDistanceBetweenCoords(pedCoords, vehCoords, true)
		local lockStatus = GetVehicleDoorLockStatus(vehicle)

		if distance < 2.5 and lockStatus == 2 and IsPedInAnyVehicle(ped, false) == false then
			DrawText3Ds(vehCoords.x, vehCoords.y, vehCoords.z + 1.35, "[~r~Vergrendeld~w~] Kenteken: " .. plate)
		elseif distance < 2.5 and lockStatus == 1 and IsPedInAnyVehicle(ped, false) == false then
			DrawText3Ds(vehCoords.x, vehCoords.y, vehCoords.z + 1.35, "[~g~Ontgrendeld~w~] Kenteken: " .. plate)
		end
	end
end)

function StartWorkaroundTask()
	if isRunningWorkaround then
		return
	end

	local timer = 0
	local playerPed = PlayerPedId()
	isRunningWorkaround = true

	while timer < 100 do
		Citizen.Wait(2000)
		timer = timer + 1

		local vehicle = GetVehiclePedIsTryingToEnter(playerPed)
		local vcoords = GetEntityCoords(vehicle)

		if DoesEntityExist(vehicle) then
			local lockStatus = GetVehicleDoorLockStatus(vehicle)

			if lockStatus == 2 then
				ClearPedTasks(playerPed)
			end
		end
	end

	isRunningWorkaround = false
end

function loadAnimDict( dict )
    while ( not HasAnimDictLoaded( dict ) ) do
        RequestAnimDict( dict )
        Citizen.Wait( 1500 )
    end
end

function ToggleVehicleLock()
	local playerPed = PlayerPedId()
	local coords = GetEntityCoords(playerPed)
	local vehicle

	Citizen.CreateThread(function()
		StartWorkaroundTask()
	end)

	if IsPedInAnyVehicle(playerPed, false) then
		vehicle = GetVehiclePedIsIn(playerPed, false)
	else
		vehicle = GetClosestVehicle(coords, 8.0, 0, 70)
	end

	if not DoesEntityExist(vehicle) then
		return
	end

	ESX.TriggerServerCallback('esx_vehiclelock:requestPlayerCars', function(isOwnedVehicle)

		if isOwnedVehicle then
			local lockStatus = GetVehicleDoorLockStatus(vehicle)
			local playerPed = PlayerPedId()
	        local ad = "anim@mp_player_intmenu@key_fob@"

			if lockStatus == 1 then -- unlocked
				SetVehicleDoorsLocked(vehicle, 2)
				PlayVehicleDoorCloseSound(vehicle, 1)

				TriggerEvent('chat:addMessage', { args = { _U('message_titleu'), _U('message_locked') } })

				if not IsPedInAnyVehicle(playerPed, false) then
		            loadAnimDict( ad )
		            TaskPlayAnim(playerPed, ad, 'fob_click', 8.0, 1.0, -1, 47, 0, 0, 0, 0 )
				end
				TriggerServerEvent('InteractSound_SV:PlayWithinDistance', 0.5, 'lock', 0.1)
	            Citizen.Wait(600)
	            ClearPedTasks(playerPed)
			elseif lockStatus == 2 then -- locked
				SetVehicleDoorsLocked(vehicle, 1)
				PlayVehicleDoorOpenSound(vehicle, 0)

				TriggerEvent('chat:addMessage', { args = { _U('message_titlel'), _U('message_unlocked') } })
				if not IsPedInAnyVehicle(playerPed, false) then
		            loadAnimDict( ad )
		            TaskPlayAnim(playerPed, ad, 'fob_click', 8.0, 1.0, -1, 47, 0, 0, 0, 0 )
				end
				TriggerServerEvent('InteractSound_SV:PlayWithinDistance', 0.5, 'lock', 0.1)
	            Citizen.Wait(600)
	            ClearPedTasks(playerPed)
			end
		end

	end, ESX.Math.Trim(GetVehicleNumberPlateText(vehicle)))
end

RegisterNetEvent("s1:togglelock")
AddEventHandler("s1:togglelock", function()
	ToggleVehicleLock()
end)

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(10)

		if IsControlJustReleased(0, Keys['L']) and IsInputDisabled(0) then
			ToggleVehicleLock()
			Citizen.Wait(1000)
		elseif IsControlJustReleased(0, 173) and not IsInputDisabled(0) then
			ToggleVehicleLock()
			Citizen.Wait(300)
		end
	end
end)
