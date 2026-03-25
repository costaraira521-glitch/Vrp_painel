local Tunnel = module('vrp', 'lib/Tunnel')
local Proxy = module('vrp', 'lib/Proxy')

vRP = Proxy.getInterface('vRP')
vRPclient = Tunnel.getInterface('vRP')

RegisterNetEvent('vrp_admin_panel:open')
AddEventHandler('vrp_admin_panel:open', function()
  SetNuiFocus(true, true)
  SendNUIMessage({ action = 'open' })
end)

RegisterNetEvent('vrp_admin_panel:openWL')
AddEventHandler('vrp_admin_panel:openWL', function(question)
  SetNuiFocus(true, true)
  SendNUIMessage({ action = 'openWL', question = question })
end)

RegisterNetEvent('vrp_admin_panel:wlResult')
AddEventHandler('vrp_admin_panel:wlResult', function(success, message)
  SendNUIMessage({ action = 'wlResult', success = success, message = message })
  if success then
    -- jogador foi aprovado, pode prosseguir
    SetNuiFocus(false, false)
  end
end)

RegisterNUICallback('close', function(data, cb)
  SetNuiFocus(false, false)
  cb('ok')
end)

RegisterNUICallback('cmdKick', function(data, cb)
  local targetId = tonumber(data.targetId)
  TriggerServerEvent('vrp_admin_panel:cmdKick', targetId)
  cb({ success = true })
end)

RegisterNUICallback('cmdHeal', function(data, cb)
  local targetId = tonumber(data.targetId)
  TriggerServerEvent('vrp_admin_panel:cmdHeal', targetId)
  cb({ success = true })
end)

RegisterNetEvent('vrp_admin_panel:commandResult')
AddEventHandler('vrp_admin_panel:commandResult', function(success, message)
  SendNUIMessage({ action = 'commandResult', success = success, message = message })
end)

local drawPlayerTags = false
local playerLastSet = {}

local function formatScoreText(player, setName)
  return ('%s\nSET: %s'):format(GetPlayerName(player), setName or 'desconhecido')
end

Citizen.CreateThread(function()
  while true do
    Citizen.Wait(0)
    if drawPlayerTags then
      local myPed = PlayerPedId()
      local myCoords = GetEntityCoords(myPed)
      for _, pid in ipairs(GetActivePlayers()) do
        if pid ~= PlayerId() then
          local ped = GetPlayerPed(pid)
          local coords = GetEntityCoords(ped)
          local dist = #(coords - myCoords)
          if dist < 25.0 then
            local screen, x, y = World3dToScreen2d(coords.x, coords.y + 1.1, coords.z)
            if screen then
              local txt = formatScoreText(GetPlayerServerId(pid), playerLastSet[pid] or 'default')
              SetTextScale(0.35, 0.35)
              SetTextFont(4)
              SetTextProportional(1)
              SetTextColour(255, 255, 255, 210)
              SetTextEntry('STRING')
              SetTextCentre(true)
              AddTextComponentString(txt)
              DrawText(x, y)
            end
          end
        end
      end
    else
      Citizen.Wait(200)
    end
  end
end)

RegisterNetEvent('vrp_admin_panel:setDrawTag')
AddEventHandler('vrp_admin_panel:setDrawTag', function(state)
  drawPlayerTags = state
end)

AddEventHandler('playerSpawned', function(spawn)
  TriggerServerEvent('vrp_admin_panel:checkWhitelist')
end)

RegisterCommand('adminlog', function(source, args, raw)
  TriggerClientEvent('vrp_admin_panel:open', source)
end, false)
