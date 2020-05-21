local _, gbl = ...
gbl.Apep = gbl.MergeTable(gbl.FireHack, {})
local NeP = _G.NeP
local f = gbl.Apep
local g = gbl.gapis
local max_distance = NeP.Interface:Fetch('NerdPack_Settings', 'OM_Dis', 100)

function f.Load() end

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
        return gbl.Generic.CastGround(spell, target)
    end
    if not NeP.DSL:Get('exists')(target) then return end
    -- Need to know if the spell comes from a Item for use UseItemByName or CastSpellByName
	local IsItem = NeP._G.GetItemSpell(spell)
	local func = IsItem and gbl.Generic.UseItem or gbl.Generic.Cast
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

function f.OM_Maker()
	for i=1, g.GetObjectCount(max_distance) do
		local Obj = g.GetObjectWithIndex(i)
		NeP.OM:Add(Obj)
	end
end

gbl:AddUnlocker('Apep', {
	test = function() return _G.Apep end,
	init = f.Load,
	prio = 8,
	functions = f,
})
