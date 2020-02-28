
--Speed setup
turnVelocity=300
midVelocity=450
chargingspeed=200

--RFID
clear = "FFFF"
PERMISSION_GRANT = 1

--Laser number
turnOffAll = 0
--turnOnAll = 32768+16384+8
--turnOffAll = 0
turnOnAll = 1

--Dir degree
leftwarddegree = 90
rightwarddegree = -90
invertdegree = 180
ninvertdegree = -180

--Air Dir
forward = 0
rightward = 1 
backward = 2
leftward = 3
none = 0
aivDir = forward

--Dirs
--含义：1→2 车辆需要前进，故为forward
directions = {
--[[
	["2,1"] = backward,
	["5,6"] = backward,
	["4,5"] = backward,
	["3,4"] = backward,

	["1,2"] = forward,
	["6,5"] = forward,
	["5,4"] = forward,
	["4,3"] = forward,

	["1,6"] = leftward,
	["2,3"] = leftward,

	["6,1"] = rightward,
	["3,2"] = rightward,
--]]

["2,1"] = backward,
["4,3"] = backward,
["5,4"] = backward,
["6,5"] = backward,
["8,7"] = backward,
["12,11"] = backward,
["11,10"] = backward,
["10,9"] = backward,
["14,13"] = backward,
["18,17"] = backward,
["17,16"] = backward,
["16,15"] = backward,
["13,8"] = backward,
["15,12"] = backward,

["1,2"] = forward,
["3,4"] = forward,
["4,5"] = forward,
["5,6"] = forward,
["7,8"] = forward,
["9,10"] = forward,
["10,11"] = forward,
["11,12"] = forward,
["13,14"] = forward,
["15,16"] = forward,
["16,17"] = forward,
["17,18"] = forward,
["8,13"] = forward,
["12,15"] = forward,


["3,1"] = rightward,
["6,2"] = rightward,
["9,7"] = rightward,
["12,8"] = rightward,
["15,13"] = rightward,
["18,14"] = rightward,
["8,5"] = rightward,



["1,3"] = leftward,
["2,6"] = leftward,
["7,9"] = leftward,
["8,12"] = leftward,
["13,15"] = leftward,
["14,18"] = leftward,
["5,8"] = leftward,

}

-- RFIDs
RFIDs = {
--[4]  = "0101",[5]  = "0201",[6]  = "3002",
--[14] = "3003",[15] = "3004",[16] = "3005",
--[1]  = "3001",[2]  = "0432",[3]  = "3013",[4] = "0201",
--[5]  = "0401",[6]  = "3012",
[1]  = "3105",[2]  = "3100",[3]  = "3104",[4] = "3103",[5] = "3102",
[6]  = "3101",[7]  = "3107",[8]  = "3117",[9] = "3119",[10] = "3111",
[11]  = "3118",[12]  = "3002",[13]  = "3001",[14] = "0432",[15] = "3012",
[16]  = "0401",[17]  = "0201",[18]  = "3013",
}

-- Charge message setup
MsgType4Charging = 1
MsgType4Signal = 2

--3rd party messages
chargeReqMsgId = 2
chargeFinishMsgId = 3

-- signal msgid
signalMsgIdTaskFinished = 161	--  ;任务完成
signalMsgIdArrialPort = 163      --	;工位到达
signalMsgIdReportIdlePoint = 170

MsgId4AllowCharging = 241

MsgId4AllowDrawing = 242
MsgId4AllowDrawingExit = 243
MsgId4AllowSafeGateDrawing = 244

MsgId4AllowDelivery = 245
MsgId4AllowDeliveryExit = 246
MsgId4AllowSafeGateDelivery = 247

--
SignalDeviceSN = 1



--Function 1
--获取点位方位
function getDirection(point1,point2)
	local s = tostring(point1..","..point2)
	return directions[s]
end


--Function 2
--旋转操作1
function turnWithDegree(degree)
--[[	双轮差速转向
	aiv.EnablePermeameter(false)
	aiv.SetTurnThetaCommand(degree,turnVelocity)
	aiv.EnablePermeameter(true)
--]]	
	steer_wheel.ChangeDirection(degree)
	logger.Info("function turnWithDegree -- steer.ChangeDirection is OK")
end
--旋转操作2
function turn(pathDirection)
	logger.Info("function turn --aivDir is "..tostring(aivDir)..", and pathDirection is "..tostring(pathDirection))
	--[[	双轮差速转向2
	if(pathDirection==nil) then
		return
	end
	-- Note:现场测试，转弯的地方是否都空间足够。否则，还是要关闭激光。
	--turnOffLaserAll()

	--airDir是AGV当前的车头方向 默认aivDir == forward == 0
	local diff=pathDirection-aivDir
	logger.Info("function turn -- AIV's currentDir is "..tostring(airDir).." and nextDir is "..tostring(pathDirection))
	--此处的算法是 1-0 2-1 3-2 0-3
	if (diff==1 or diff==-3) then
		turnWithDegree(rightwarddegree)
		aivDir=pathDirection
	logger.Info("function turn -- AIV's turning over, currentDir is"..tostring(airDir)))
	elseif (diff==-1 or diff==3) then
		turnWithDegree(leftwarddegree)
		aivDir=pathDirection
	logger.Info("function turn -- AIV's turning over, currentDir is"..tostring(airDir)))
	end
	--]]

	--	舵轮转向
	if(pathDirection == nil) then
		return
	elseif((aivDir == backward or aivDir == forward ) and (pathDirection == leftward or pathDirection == rightward))then
		turnWithDegree(90)
		aivDir=leftward
		logger.Info("function turn -- AIV turnWithDegree 90, and aivDir is leftward")
	elseif((aivDir == leftward or aivDir == rightward ) and (pathDirection == backward or pathDirection == forward))then
		turnWithDegree(0)
		aivDir = forward
		logger.Info("function turn -- AIV turnWithDegree 0, and aivDir is forward")
	else
		logger.Info("function turn -- AIV's airDir is same as currentDir")
	end

end

--Function 3
--顶升操作
function operateScroll(op_type)
	logger.Info("function operateScroll @ optype is  "..tostring(op_type))
	ScrollCount = 0
	local operation = -1
	local res = 0

	--操作步骤：5（下降）--1(顶升工位)--3（下降）--....--4（顶升）--2(下降工位)--x
	--if (op_type == 2 or op_type==3 or op_type == 5) then
	if (op_type == 2 or op_type == 5) then
	  operation = 2
	--elseif (op_type == 1 or op_type==4 ) then
	elseif (op_type == 1) then
	  operation = 1
	elseif(op_type == -1) then
		logger.Info("function operateScroll @ op_type is -1, do nothing ")
	else
		logger.Info("function operateScroll @ optype wrong is "..tostring(op_type))
	end
	
	if(operation > 0) then 
		res=aiv.Scroll(operation)
		while(res==-1 and ScrollCount~=3)do
			if(operation==1)then
				logger.Error("function operateScroll @ Scroll up failed")
			elseif(operation==2)then
				logger.Error("function operateScroll @ Scroll down failed")
			else
				logger.Error("function operateScroll @ Scroll failed, operation is "..tostring(operation))
			end
			
			aiv.WaitTimeout(1000)
			logger.Info("function operateScroll @ operate----------res restart----------: "..tostring(res))
			
			ScrollCount = ScrollCount + 1
			logger.Info("function operateScroll @ failed Scrollcount= "..tostring(ScrollCount))
		end
	end
	
	logger.Info("function operateScroll @ op result="..tostring(res))
	
  aiv.WaitTimeout(2000)
end

--Function 4
--？？当前点ID？操作和方向吗？
function stop(pointId,operation,direction1,direction2)
	logger.Info("Stop: "..tostring(PointId).." operation:"..tostring(operation).."  direction1:"..tostring(direction1).."  direction2:"..tostring(direction2))
	if(pointId==nil) then
		return
	end
	
	--如果不执行顶升操作，也不进行转弯
	local stopOnPoint=(operation~=-1 or direction~=direction2)
	
	if(not stopOnPoint) then	
		RFID.SetStopControlRFID(clear)
	end	
		
	RFID.WaitRFID(RFIDs[pointId], stopOnPoint, false)
end

--Function 5
--移动操作1
function moveAndStop(nextPointId,operation,direction1,direction2)
	logger.Info("function @ moveAndStop: "..tostring(nextPointId).." operation:"..tostring(operation).."  direction1:"..tostring(direction1).."  direction2:"..tostring(direction2))
	if(nextPointId==nil) then 
		return 
	end

	local stopOnPoint=false;
	if (nil == direction2) then
		stopOnPoint = true
	else 
		stopOnPoint = (operation~=-1 or direction1~=direction2)
	end 

	logger.Info("function @ moveAndStop: stopOnPoint = "..tostring(stopOnPoint))
	if(stopOnPoint) then	
		RFID.SetStopControlRFID(RFIDs[nextPointId])
	else
		RFID.SetStopControlRFID(clear)
	end	
	
	aiv.MoveWithSpeedByPermeameter(midVelocity, direction1==aivDir)
	
	RFID.WaitRFID(RFIDs[nextPointId], stopOnPoint, false)
end

--Function 6
--激光操作
function setSecurityLaserMode(modeNumber)
    laser.SetSecureLaserMode(modeNumber)
		laserMode=laser.GetSecureLaserMode()
end

function turnOffLaserAll()
	setSecurityLaserMode(turnOffAll)
end

function turnOnLaserAll()
	setSecurityLaserMode(turnOnAll)
end

--Function 7
-- 充电
function BeginCharge(nChargingPlatform)
	if (ChargingState) then
		logger.Info("Function BeginCharge'States is true , System is Charging...")
		return
	end

	aiv_charge.ChargeReady()
	aiv.WaitTimeout(3000)
	
	--chargingMsgType = 1;  // 充电命令类型值
	--chargeReqMsgId = 2;	// 请求充电桩伸出充电头的消息ID
	--chargeFinishMsgId = 3;	// 请求充电桩收回充电头的消息ID
	--string signal.GetSignalName(int signalType, int nSignalId, int nSN)
	local chargereq_signalName = signal.GetSignalName(MsgType4Charging, chargeReqMsgId, nChargingPlatform)
	if (chargereq_signalName == nil) then
		logger.Info("Function BeginCharge's chargereq_signalName is ERROR"..tostring(chargereq_signalName))
		return -11
	end

	logger.Info("Function BeginCharge  Now send signal: "..tostring(chargereq_signalName))
	nResult = signal.SetSignal(chargereq_signalName);
	logger.Info("Function BeginCharge SetSignal's nResult is : "..tostring(nResult))	
	
	ChargingState = true

	return nResult
end

function FinishCharge(nChargingPlatform)
	if (not ChargingState) then
		logger.Info("Function FinshCharge'States is false , System is on Charging...")
		return;
	end

	aiv_charge.ChargeFinished();
	aiv.WaitTimeout(3000)

	--chargingMsgType = 1;  // 充电命令类型值
	--chargeReqMsgId = 2;	// 请求充电桩伸出充电头的消息ID
	--chargeFinishMsgId = 3;	// 请求充电桩收回充电头的消息ID
	--string signal.GetSignalName(int signalType, int nSignalId, int nSN);
	local chargeFinish_signalName = signal.GetSignalName(MsgType4Charging, chargeFinishMsgId, nChargingPlatform);
	if (chargeFinish_signalName == nil) then
		logger.Info("Function FinshCharge's chargereq_signalName is ERROR"..tostring(chargereq_signalName))
		return -11
	end

	logger.Info("Function FinishCharge Now send signal: "..tostring(chargereq_signalName))
	nResult = signal.SetSignal(chargeFinish_signalName);
	logger.Info("Function FinishCharge SetSignal's nResult is : "..tostring(nResult))

	aiv.WaitTimeout(4000)
	ChargingState = false;
	return nResult
end

--------------------------------------------------------------------------------------------------------------------

logger.Info(" ----------------- Start Program ---------------" )

-- Initialization
currentPoint=-100
aiv.EnablePermeameter(true)
--nChargingPlatform = 11  -- aiv_battery.GetChargingDeviceID(7);
ChargingState = false		-- 充电状态，初始 未充电 
turnOffLaserAll()

while (true) do

	logger.Info("\r\nfor while ---- currentPoint: " ..tostring(currentPoint).."  next point:" .. tostring(nextPoint))
	
	-- AGV处于休息点
	-- AGV处于暂停点、操作点
	-- AGV处于正常运行点

	if (currentPoint == -100) then
		
		turnWithDegree(0)
		aivDir = forward
		task.GetNextWorkPoint(currentPoint)
		nextPoint = taskresult.ResultOnNextPoint()
		task.GetNextTaskPointPermissionUntillGrant(nextPoint)
		--RFIDs[currentPoint] = RFID.GetCurrentRFID()
		currentPoint = nextPoint

	elseif (currentPoint == nextPoint)  and (currentPoint == 3) then
		logger.Info("current point is 3,and nextPoint is 3, now charging at 5#")
		--BeginCharge(5)
		aiv.WaitTimeout(4000)
		task.GetNextWorkPoint()
		nextPoint = taskresult.ResultOnNextPoint()

	elseif (currentPoint == nextPoint)  and (currentPoint == 9) then
		logger.Info("current point is 9,and nextPoint is 9, now charging at 2#")
		--BeginCharge(2)
		aiv.WaitTimeout(4000)
		task.GetNextWorkPoint()
		nextPoint = taskresult.ResultOnNextPoint()

	elseif (currentPoint == nextPoint)  and (currentPoint == 15) then
		logger.Info("current point is 15, and nextPoint is 15, now charging at 4#")
		--BeginCharge(4)
		aiv.WaitTimeout(4000)
		task.GetNextWorkPoint()
		nextPoint = taskresult.ResultOnNextPoint()

	elseif (currentPoint == nextPoint) and (currentPoint ~= 3) and (currentPoint ~= 9) and (currentPoint ~= 15) then
		task.GetNextWorkPoint()
		nextPoint = taskresult.ResultOnNextPoint()
		aiv.WaitTimeout(3000)

	elseif (currentPoint > 0) and (nextPoint < 19) and (currentPoint ~= nextPoint) then

		if (currentPoint == 3) and (ChargingState == true) then
			logger.Info("current point is 3, and nextPoint is not 3, now finish charging at 5#")
			--FinishCharge(5)
			--aiv.WaitTimeout(4000)
		elseif (currentPoint == 9) and (ChargingState == true) then
			logger.Info("current point is 9, and nextPoint is not 9, now finish charging at 2#")
			--FinishCharge(2)
			--aiv.WaitTimeout(4000)
		elseif (currentPoint == 15) and (ChargingState == true) then
			logger.Info("current point is 15, and nextPoint is not 15, now finish charging at 4#")
			--FinishCharge(4)
			--aiv.WaitTimeout(4000)
		else
			logger.Info("No Charging...")
		end

		task.GetNextWorkPoint()
		nextPoint = taskresult.ResultOnNextPoint()

		currentDirection = getDirection(currentPoint,nextPoint)

		opType = task.GetOperationTypeAtPoint(currentPoint)
		
		permission_currentpoint = task.GetNextTaskPointPermission(currentPoint)
		
		logger.Info("Info: currentPoint: "..tostring(currentPoint))
		logger.Info("Info: nextPoint: "..tostring(nextPoint))
		logger.Info("Info: air's currentdir: "..tostring(aivDir))
		logger.Info("Info: currentDirection: "..tostring(currentDirection))
		logger.Info("Info: op @ currentPoint is : "..tostring(currentPoint).." And opType is "..tostring(opType))
		logger.Info("Info: permission @ currentPoint permission is:"..tostring(permission_currentpoint))

		--等待3rd信号
		logger.Info("Running: watting signal @ watting 3rd signal")
		if (permission_nextpoint ~= PERMISSION_GRANT) then
			logger.Info("Running: permission_nextpoint is not 1 ,stop AGV for nextPoint: "..tostring(nextPoint))
			--aiv.MoveWithSpeedByPermeameter(0, true)
			--？？此处的stop()是没有传参的，是有问题的。不进行停止的。
			aiv.Stop()
			task.GetNextTaskPointPermissionUntillGrant(nextPoint)
		else
			logger.Info("Running: permission_nextpoint is 1 , AGV Go to nextPoint"..tostring(nextPoint))
		end

		--执行操作
		logger.Info("Running: oping @ currentPoint----: "..tostring(opType).."   @ "..tostring(currentPoint))
		operateScroll(opType)

		if(nextPoint > 0) then
			logger.Info("State: nextPoint is > 0 ")	

			--转弯
			logger.Info("Running: air's currentdir: "..tostring(aivDir))
			logger.Info("Running: turning @ currentPoint----: "..tostring(currentDirection).."   @ "..tostring(currentPoint))
			turn(currentDirection)

			--移动
			task.GetNextWorkPoint(nextPoint)
			nextNextPoint=taskresult.ResultOnNextPoint()	

			nextDirection = getDirection(nextPoint,nextNextPoint)

			opNextPoint = task.GetOperationTypeAtPoint(nextPoint)
			permission_nextpoint = task.GetNextTaskPointPermission(nextPoint)

			logger.Info("Info: currentPoint: "..tostring(currentPoint))
			logger.Info("Info: nextPoint: "..tostring(nextPoint))
			logger.Info("Info: nextNextPoint: "..tostring(nextNextPoint))
			logger.Info("Info: currentDirection: "..tostring(currentDirection))
			logger.Info("Info: nextDirection: "..tostring(nextDirection))
			logger.Info("Info: op @ NextPoint----: "..tostring(opNextPoint).."   @ "..tostring(nextPoint))
			logger.Info("Info: permission @ nextPoint----:"..tostring(permission_nextpoint))
			
			if(opNextPoint ~= -1)then
				--turnOffLaserAll()
				logger.Info("Info: op @ NextPoint's op is "..tostring(opNextPoint)..", turnOffLaserAll and number is "..tostring(turnOffAll))
			else
				--turnOnLaserAll()
				logger.Info("Info: op @ NextPoint's op is "..tostring(opNextPoint)..", turnOnLaserAll and number is "..tostring(turnOnAll))
			end


			--task.GetNextTaskPointPermissionUntillGrant(nextPoint)
			moveAndStop(nextPoint,opNextPoint,currentDirection,nextDirection)
			logger.Info("Running: arrived target-point！！ -- currentPoint: "..tostring(currentPoint) .. ",and nextPoint: "..tostring(nextPoint).. "  and OP: "..tostring(opNextPoint))
			
			--报告当前点
			task.LeaveCurrentLocation(currentPoint)
			logger.Info("Running: report task.LeaveCurrentLocation(currentPoint): " ..tostring(currentPoint))		
			task.ReportCurrentLocation(nextPoint)
			logger.Info("Running: report task.ReportCurrentLocation(nextPoint): " ..tostring(nextPoint))
			
			--点位替换
			currentPoint, nextPoint = nextPoint, nextNextPoint
			logger.Info("Running: report Update Points currentPoint -- " ..tostring(currentPoint)..",and nextPoint --"..tostring(nextPoint))

		elseif(nextPoint == -1) then
			logger.Info("State: nextPoint is -1 ")	
			logger.Info("Running: report taskStatus -- " ..tostring("1")..",and "..tostring("5"))
			task.ReportTaskStatus(1, 5)
			logger.Info("Running: report taskStatus --1,5 is OK ")
			task.GetNextWorkPoint()
			nextPoint = taskresult.ResultOnNextPoint()
			logger.Info("Running: report taskStatus --Get nextPoint is "..tostring(nextPoint))
		elseif(nextPoint == -2) then
			logger.Info("State: nextPoint is -2 ")
		elseif(nextPoint == -3) then
			logger.Info("State: nextPoint is -3 ")
		elseif(nextPoint == -4) then
			logger.Info("State: nextPoint is -4 ")
		elseif(nextPoint == -20) then
			logger.Info("State: nextPoint is -20 ")				
		else
			logger.Info("State: nextPoint is Wrong State "..tostring(nextPoint))
		end

	else
		logger.Info("Something is Wrong...")
	end
	
	logger.Info("\r\n End OK")
		
end