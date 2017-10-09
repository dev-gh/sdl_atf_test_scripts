---------------------------------------------------------------------------------------------------
-- User story: TO ADD !!!
-- Use case: TO ADD !!!
-- Item: Use Case: request is allowed but parameter of this request is NOT allowed by Policies
--
-- Requirement summary:
-- [SubscribeVehicleData] As a mobile app wants to send a request to get the details of the vehicle data
--
-- Description:
-- In case:
-- Mobile application sends valid SubscribeVehicleData to SDL and this request is
-- allowed by Policies but RPC parameter is not allowed
-- SDL must:
-- Respond DISALLOWED, success:false to mobile application and not transfer this request to HMI
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/VehicleData/commonVehicleData')
local commonTestCases = require('user_modules/shared_testcases/commonTestCases')

--[[ Local Variables ]]
local rpc = {
    name = "SubscribeVehicleData",
    params = {
    engineOilLife = true
    }
}

--[[ Local Functions ]]
local function ptu_update_func(tbl)
  local params = tbl.policy_table.functional_groupings["Emergency-1"].rpcs["SubscribeVehicleData"].parameters
  for index, value in pairs(params) do
    if ("engineOilLife" == value) then table.remove(params, index) end
  end
end

local function processRPCFailure(self)
  local mobileSession = common.getMobileSession(self, 1)
  local cid = mobileSession:SendRPC(rpc.name, rpc.params)
  EXPECT_HMICALL("VehicleInfo." .. rpc.name, rpc.params):Times(0)
  commonTestCases:DelayedExp(common.timeout)
  mobileSession:ExpectResponse(cid, { success = false, resultCode = "DISALLOWED",
    info = "'engineOilLife' disallowed by policies.",
    engineOilLife = {dataType = "VEHICLEDATA_ENGINEOILLIFE", resultCode = "DISALLOWED"} })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI with PTU", common.registerAppWithPTU, {1, ptu_update_func})
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("RPC " .. rpc.name , processRPCFailure)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
