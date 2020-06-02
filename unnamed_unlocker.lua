local _, gbl = ...
local NeP = _G.NeP
gbl.Wownet = {}
local f = gbl.Wownet
local g = gbl.gapis

-- WoW 8.1.5.29981
local Offsets = {
    ['BoundingRadius'] = 0x15DC,
    ['CombatReach'] = 0x15E0, -- BoundingRadius + 4
    ['CastingTarget'] = 0x1910,
    ['SpecID'] = 0x1AE4,
    ['SummonedBy'] = 0x1510,
    ['CreatedBy'] = 0x1520, -- SummonedBy + 10
    ['Target'] = 0x1550,
    ['Rotation'] = 0x160
}

local apis = {
    'UnitInRange', 'UnitPlayerControlled', 'UnitIsVisible', 'GetUnitSpeed',
    'UnitExists', 'UnitClass', 'UnitIsTappedByPlayer', 'UnitThreatSituation',
    'UnitCanAttack', 'GetUnitSpeed', 'UnitCreatureType', 'UnitIsDeadOrGhost',
    'UnitDetailedThreatSituation', 'UnitGUID', 'UnitIsUnit', 'UnitHealthMax',
    'UnitAffectingCombat', 'UnitReaction', 'UnitIsPlayer', 'UnitIsDead',
    'UnitInParty', 'UnitInRaid', 'UnitHealth', 'UnitCastingInfo',
    'UnitChannelInfo', 'UnitName', 'UnitBuff', 'UnitDebuff', 'UnitInPhase',
    'UnitIsFriend', 'IsSpellInRange', 'UnitClassification', 'UnitAura',
    'UnitGroupRolesAssigned', -- untested
    'SetPortraitTexture', 'UnitXPMax', 'UnitXP', 'UnitUsingVehicle', 'UnitStat',
    'UnitSex', 'UnitSelectionColor', 'UnitResistance', 'UnitReaction',
    'UnitRangedDamage', 'UnitRangedAttackPower', 'UnitRangedAttack', 'UnitRace',
    'UnitPowerType', 'UnitPowerMax', 'UnitPower', 'UnitPVPName',
    'UnitPlayerOrPetInRaid', 'UnitPlayerOrPetInParty', 'UnitManaMax',
    'UnitMana', 'UnitLevel', 'UnitIsTrivial', 'UnitIsTapped',
    'UnitIsSameServer', 'UnitIsPossessed', 'UnitIsPVPSanctuary',
    'UnitIsPVPFreeForAll', 'UnitIsPVP', 'UnitIsGhost', 'UnitIsFeignDeath',
    'UnitIsEnemy', 'UnitIsDND', 'UnitIsCorpse', 'UnitIsConnected',
    'UnitIsCharmed', 'UnitIsAFK', 'UnitIsInMyGuild', 'UnitInBattleground',
    'GetPlayerInfoByGUID', 'UnitDefense', 'UnitDamage', 'UnitCreatureType',
    'UnitCreatureFamily', 'UnitClass', 'UnitCanCooperate', 'UnitCanAttack',
    'UnitCanAssist', 'UnitAttackSpeed', 'UnitAttackPower',
    'UnitAttackBothHands', 'UnitArmor', 'InviteUnit', 'GetUnitSpeed',
    'GetUnitPitch', 'GetUnitName', 'FollowUnit', 'CheckInteractDistance',
    'InitiateTrade', 'UnitOnTaxi', 'AssistUnit', 'SpellTargetUnit',
    'SpellCanTargetUnit', 'CombatTextSetActiveUnit', 'SummonFriend',
    'CanSummonFriend', 'GrantLevel', 'CanGrantLevel', 'SetRaidTarget',
    'GetReadyCheckStatus', 'GetRaidTargetIndex', 'GetPartyAssignment',
    'DemoteAssistant', 'PromoteToAssistant', 'IsUnitOnQuest', 'DropItemOnUnit',
    'GetDefaultLanguage', 'GetCritChanceFromAgility',
    'GetSpellCritChanceFromIntellect'
}

local original_apis = {}
local loaded_once = false;
local UnitExists = _G.UnitExists;

local function hookGuids()
    for _, api in pairs(apis) do
        -- save original
        if not original_apis[api] then original_apis[api] = _G[api] end
        -- intercept guids
        g[api] = function(...)
            local mouseover;
            local focus;
            local args = {...}
            for k, v in pairs(args) do
                if v and not UnitExists(v) and g.IsGuid(v) then
                    if not mouseover then
                        args[k] = g.SetMouseOver(v)
                        mouseover = true
                    elseif not focus then
                        args[k] = g.SetFocusTarget(v)
                        focus = true
                    end
                end
            end
            return original_apis[api](unpack(args))
        end
    end
end

function f.Load()
    if loaded_once then return end
    loaded_once = true;
    hookGuids()
end

function f.Cast(spell, target)
    g.CallSecureFunction('CastSpellByName', spell,
                         g.IsGuid(target) and g.SetMouseOver(target) or target)
end

function f.CastGround(spell, target)
    if not spell then return end
    -- fallback to generic if we can cast it using macros
    if gbl.validGround[target] then
        return gbl.Generic.CastGround(spell, target)
    end
    g.CallSecureFunction('CastSpellByName', spell)
    g.ClickPosition(g.GetUnitPosition(target or 'player'))
end

function f.Macro(text) g.CallSecureFunction('RunMacroText', text) end

function f.UseItem(name, target)
    g.CallSecureFunction('UseItemByName', name, target)
end

function f.UseInvItem(name) g.CallSecureFunction('UseInventoryItem', name) end

function f.TargetUnit(target)
    g.CallSecureFunction('TargetUnit', g.SetMouseOver(target))
end

function f.SpellStopCasting() g.CallSecureFunction('SpellStopCasting') end

function f.Distance(a, b)

    if not a or not b then return 999 end

    local ax, ay, az = g.GetUnitPosition(a) -- 'Attacker'
    local bx, by, bz = g.GetUnitPosition(b) -- 'Defender'
    if ax == nil or bx == nil then return math.huge end

    return math.sqrt((bx - ax) * (bx - ax) + (by - ay) * (by - ay) + (bz - az) *
                         (bz - az))
end

function f.Infront(a, b)

    if not g.UnitIsVisible(a) or not g.UnitIsVisible(b) then return false end

    local degrees = 90
    local angle1 = g.UnitFacing(a)
    local angle2 = g.UnitFacing(b)
    local calculatedAngle = 999

    local Y1, X1, Z1 = g.GetUnitPosition(a)
    local Y2, X2, Z2 = g.GetUnitPosition(b)
    if Y1 and X1 and Z1 and angle1 and Y2 and X2 and Z2 and angle2 then
        local deltaY = Y2 - Y1
        local deltaX = X2 - X1
        angle1 = math.deg(math.abs(angle1 - math.pi * 2))
        if deltaX > 0 then
            angle2 = math.deg(math.atan(deltaY / deltaX) + (math.pi / 2) +
                                  math.pi)
        elseif deltaX < 0 then
            angle2 = math.deg(math.atan(deltaY / deltaX) + (math.pi / 2))
        end
        if angle2 - angle1 > 180 then
            calculatedAngle = math.abs(angle2 - angle1 - 360)
        elseif angle1 - angle2 > 180 then
            calculatedAngle = math.abs(angle1 - angle2 - 360)
        else
            calculatedAngle = math.abs(angle2 - angle1)
        end
    end

    return calculatedAngle <= degrees
end

function f.LineOfSight(a, b)

    if not a or not b then return false end

    -- Make Sure the Unit Exists
    local aGUID = not g.IsGuid(a) and g.UnitGUID(a) or a
    local bGUID = not g.IsGuid(b) and g.UnitGUID(b) or b

    if aGUID == bGUID then return true end

    -- skip if its a boss
    local aID = tonumber(aGUID:match("-(%d+)-%x+$"), 10)
    local bID = tonumber(bGUID:match("-(%d+)-%x+$"), 10)
    if NeP.BossID:Eval(aID) or NeP.BossID:Eval(bID) then return true end

    -- contiunue
    local ax, ay, az = g.GetUnitPosition(a)
    local bx, by, bz = g.GetUnitPosition(b)

    if ax and ay and az and bx and by and bz then
        return (g.TraceLine(ax, ay, az, bx, by, bz, 0x100010) == 1)
    end
    return false
end

local ObjectTypes = {
    Object = 0,
    Item = 1,
    Container = 2,
    AzeriteEmpoweredItem = 3,
    AzeriteItem = 4,
    Unit = 5,
    Player = 6,
    ActivePlayer = 7,
    GameObject = 8,
    DynamicObject = 9,
    Corpse = 10,
    AreaTrigger = 11,
    SceneObject = 12,
    Conversation = 13
}

local function ObjectIsType(obj, i) return g.ObjectType(obj) == ObjectTypes[i] end

function f.ObjectExists() return true end

function f.OM_Maker()
    for i = 1, g.GetObjectCount() do
        local Obj = g.GetObjectWithIndex(i)
        if Obj and g.IsGuid(Obj) then
            NeP.OM:Add(Obj, ObjectIsType(Obj, ObjectTypes.GameObject))
        end
    end
end

f.ObjectCreator = function(Obj)
    return g.ObjectField((Obj), Offsets.SummonedBy, 15) or
               g.ObjectField((Obj), Offsets.CreatedBy, 15) or 0
end

f.ObjectGUID = function(Obj) return g.IsGuid(Obj) and Obj or g.UnitGUID(Obj) end

f.ObjectExists = function(Obj)
    return g.UnitExists(Obj) or g.GetObjectWithGUID(Obj)
end

f.UnitName = function(Obj) return g.ObjectName(Obj) end

f.TargetUnit = function(Obj)
    if g.IsGuid(Obj) then
        g.CallSecureFunction('TargetUnit', g.SetMouseOver(Obj))
        return
    end
    g.CallSecureFunction('TargetUnit', Obj)
end

gbl:AddUnlocker('WowNet', {
    test = function() return _G.CallSecureFunction ~= nil end,
    init = f.Load,
    prio = 9,
    functions = f
})
