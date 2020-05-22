local _, gbl = ...
gbl.Apep = gbl.MergeTable(gbl.FireHack, {})
local NeP = _G.NeP
local f = gbl.Apep
local g = gbl.gapis
local max_distance = NeP.Interface:Fetch('NerdPack_Settings', 'OM_Dis', 100)
local OM_Memory = NeP.OM:Get("Memory")

local SecureApis = {
	"RunMacroText", "CastSpellByName", "UseItemByName", "UseInventoryItem", "TargetUnit", "SpellStopCasting",
	"GetNumVoiceSessions", "PickupContainerItem", "SetOverrideBindingClick", "ClearOverrideBindings",
	"InteractUnit", "CastSpellByID", "MoveAndSteerStart", "MoveAndSteerStop", "RemoveTalent",
	"LearnTalents", "AssistUnit", "AttackTarget", "CameraOrSelectOrMoveStart", "CameraOrSelectOrMoveStop",
	"CancelItemTempEnchantment", "CancelLogout", "CancelShapeshiftForm", "CastPetAction", "CastShapeshiftForm",
	"CastSpell", "ClearTarget", "DescendStop", "DestroyTotem", "FocusUnit", "ForceQuit", "ForceLogout",
	"Logout", "JumpOrAscendStart", "MoveBackwardStart", "MoveBackwardStop", "MoveForwardStart",
	"MoveForwardStop", "PetAssistMode", "PetAttack", "PetDefensiveAssistMode", "PetDefensiveMode", "PetFollow",
	"PetPassiveMode", "PetWait", "Quit", "RegisterForSave", "ReplaceEnchant", "ReplaceTradeEnchant", "RunMacro",
	"SetMoveEnabled", "SetTurnEnabled", "SitStandOrDescendStart", "SpellStopTargeting", "SpellTargetUnit",
	"StrafeLeftStart", "StrafeLeftStop", "StrafeRightStart", "StrafeRightStop", "Stuck", "SwapRaidSubgroup",
	"TargetLastEnemy", "TargetLastTarget", "TargetNearestEnemy", "TargetNearestFriend", "ToggleAutoRun",
	"ToggleRun", "TurnLeftStart", "TurnLeftStop", "TurnOrActionStart", "TurnOrActionStop", "TurnRightStart",
	"TurnRightStop", "UseAction", "UseContainerItem", "UseToy", "UseToyByName"
}

local function om()
	local count  = g.GetObjectCount(max_distance)
	for i = 1, count do
		local Obj, _, Guid = g.GetObjectWithIndex(i)
		if not OM_Memory[Guid] then
			NeP.OM:Add(Obj)
		end
	end
end

function f.Load()
	local apep = Apep.funcs
	for _, api in pairs(SecureApis) do
		f[api] = apep[api]
	end

	f.Macro = f.RunMacroText
	f.Cast = f.CastSpellByName
	f.UseItem = f.UseItemByName
	f.UseInvItem = f.UseInventoryItem
	f.TargetUnit = f.TargetUnit
	f.SpellStopCasting = f.SpellStopCasting

	NeP.Protected.nPlates = nil
	NeP.Timer.Add('nep_apep_om', om, 1)
end

function f.Distance(a, b)
	if not NeP.DSL:Get('exists')(a)
	or not NeP.DSL:Get('exists')(b) then
		return 999
	end
	return g.GetDistanceBetweenObjects(a, b) or 0
end

function f.ObjectGUID(obj) return _G.UnitGUID(obj) or g.ObjectGUID(obj) end

function f.UnitName(obj) return _G.UnitName(obj) or g.ObjectName(obj) end

function f.Infront(a, b)
	if not NeP.DSL:Get('exists')(a)
	or not NeP.DSL:Get('exists')(b) then
		return false
	end
	return g.ObjectIsFacing(a, b)
end

function f.CastGround(spell, target)
	-- fallback to generic if we can cast it using macros
	if gbl.validGround[target] then
		return f.Macro("/cast [@"..target.."]"..spell)
	end
	if not NeP.DSL:Get('exists')(target) then return end
	-- Need to know if the spell comes from a Item for use UseItemByName or CastSpellByName
	local IsItem = NeP._G.GetItemSpell(spell)
	local func = IsItem and f.UseItem(spell) or f.Cast(spell)
	local oX, oY, oZ = NeP._G.ObjectPosition(target)
	local rX, rY = math.random(), math.random()
	if oX then
		oX = oX + rX;
        oY = oY + rY
		local i = -100
		func(spell)
		local mouselookup = NeP._G.IsMouseButtonDown(2)
		if mouselookup then NeP._G.MouselookStop() end
		while NeP._G.SpellIsTargeting() and i <= 100 do
			g.ClickPosition(oX, oY, oZ)
			i = i + 1
			oZ = i
		end
		if mouselookup then NeP._G.MouselookStart() end
		if i >= 100 and NeP._G.SpellIsTargeting() then
			NeP._G.SpellStopTargeting()
		end
	end
end

function f.ObjectExists(Obj)
	return Obj and _G.UnitExists(Obj) or g.ObjectExists(Obj)
end

function f.UnitCombatRange(a, b)
	if b=='player' then return 0 end
	if not NeP.DSL:Get('exists')(a) or not NeP.DSL:Get('exists')(b) then
		return 999
	end
	local reachA = g.UnitCombatReach(a) or 1.5
	local reachB = g.UnitCombatReach(b) or 1.5
	local distance = NeP.DSL:Get('distance')(a, nil, b) or 0
	return distance - (reachA + reachB)
end

function f.LineOfSight(a, b)
	if not NeP.DSL:Get('exists')(a) or not NeP.DSL:Get('exists')(b) then
		return false
	end
	-- skip if its a boss
	if NeP.BossID:Eval(a) or NeP.BossID:Eval(b) then return true end
	local ax, ay, az = g.ObjectPosition(a)
	if not ax then return false end
	local bx, by, bz = g.ObjectPosition(b)
	return bx and not g.TraceLine(ax, ay, az + 2.25, bx, by, bz + 2.25, g.bit.bor(0x10, 0x100))
end

function f.OM_Maker() end

gbl:AddUnlocker('Apep', {
	test = function() return _G.Apep end,
	init = f.Load,
	prio = 8,
	functions = f,
})
