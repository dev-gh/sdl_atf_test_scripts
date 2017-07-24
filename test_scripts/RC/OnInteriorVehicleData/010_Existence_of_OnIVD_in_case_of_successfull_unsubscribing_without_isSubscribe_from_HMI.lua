---------------------------------------------------------------------------------------------------
-- Description
-- In case:
-- 1) RC app is subscribed to "<moduleType_value>"
-- 2) and RC app sends valid and allowed-by-policies GetInteriorVehicleData request with "subscribe:false" parameter
-- 3) and SDL received GetInteriorVehicleData response without "isSubscribed" parameter, "resultCode: SUCCESS" from HMI
-- 4) and then SDL received OnInteriorVehicleData notification
-- SDL must:
-- 1) Transfer GetInteriorVehicleData response with "isSubscribed: true", "resultCode: SUCCESS", "success:true" to the related app
-- 2) Re-send OnInteriorVehicleData notification to the app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonRC = require('test_scripts/RC/commonRC')

--[[ Local Variables ]]
local modules = { "CLIMATE", "RADIO" }

--[[ Local Functions ]]
local function unSubscriptionToModule(pModuleType, self)
  local cid = self.mobileSession:SendRPC("GetInteriorVehicleData", {
    moduleType = pModuleType,
    subscribe = false
  })

  EXPECT_HMICALL("RC.GetInteriorVehicleData", {
    appID = self.applications["Test Application"],
    moduleType = pModuleType,
    subscribe = false
  })
  :Do(function(_, data)
      self.hmiConnection:SendResponse(data.id, data.method, "SUCCESS", {
        moduleData = commonRC.getModuleControlData(pModuleType),
        -- no isSubscribed parameter
      })
    end)

  EXPECT_RESPONSE(cid, { success = true, resultCode = "SUCCESS",
    moduleData = commonRC.getModuleControlData(pModuleType),
    isSubscribed = true
  })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonRC.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonRC.start)
runner.Step("RAI, PTU", commonRC.rai_ptu)

for _, mod in pairs(modules) do
  runner.Step("Subscribe app to " .. mod, commonRC.subscribeToModule, { mod })
  runner.Step("Send notification OnInteriorVehicleData " .. mod .. ". App is subscribed", commonRC.isSubscribed, { mod })
end

runner.Title("Test")

for _, mod in pairs(modules) do
  runner.Step("Subscribe app to " .. mod, unSubscriptionToModule, { mod })
  runner.Step("Send notification OnInteriorVehicleData " .. mod .. ". App still subscribed", commonRC.isSubscribed, { mod })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", commonRC.postconditions)