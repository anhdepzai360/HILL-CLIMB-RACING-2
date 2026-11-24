local LIB_BASE = nil
local archType = 0
local currentRange = nil
local RANGE_VALUE = nil
local gameVersion = nil
local BaseGameStatus = nil
local BaseGameStatusRaw = nil
local BaseRegion = nil

local function getArchKey()
    if archType == 1 then return "arm64-v8a"
    elseif archType == 2 then return "armeabi-v7a"
    elseif archType == 3 then return "x86_64"
    elseif archType == 4 then return "x86" end
    return "Unknown"
end

local function ShowPrintMenu(reason)
    gg.setVisible(true)
    local lines = {
        "==========================================",
        "ANHDEPZAI HUB - HCR2 Script V3.4",
        "Author: anh2k9VN | ANHDEPZAI 🇻🇳",
        "Target Arch: " .. tostring(getArchKey()),
        "Game Version: " .. tostring(gameVersion or "Unknown"),
        "=========================================="
    }
    if reason and reason ~= "" then
        lines[#lines + 1] = tostring(reason)
    else
        lines[#lines + 1] = "Cảm ơn bạn đã sử dụng script!"
    end
    print(table.concat(lines, "\n"))
    os.exit()
end

-- ═══════════════════════════════════════════════════════════════
--  LOADING BAR (1% -> 100%)
-- ═══════════════════════════════════════════════════════════════
local function buildBar(pct, width)
    width = width or 15
    pct = math.max(0, math.min(100, pct))
    local filled = math.floor((pct / 100) * width + 0.5)
    if pct > 0 and filled == 0 then filled = 1 end
    if filled > width then filled = width end
    return "[" .. string.rep("█", filled) .. string.rep("░", width - filled) .. "] " .. pct .. "%"
end

local function showLoadingStep(label, pct, sleepMs)
    gg.toast(string.format("%s\n%s", label or "Loading...", buildBar(pct, 15)))
    if sleepMs and sleepMs > 0 then
        gg.sleep(sleepMs)
    end
end

local function runLoading1to100(label, totalMs)
    totalMs = totalMs or 1200
    local stepDelay = math.max(12, math.floor(totalMs / 20))
    for pct = 5, 100, 5 do
        showLoadingStep(label, pct, stepDelay)
    end
end

-- CREATIVE: two features extracted from the user's supplied source
CREATIVE = { PAGE_SIZE = 75 }
_creativeAllocHandles = nil
_creativeCachedAnchors = nil
_creativeAnyThemeCache = nil
_creativeShowHiddenCache = nil
_creativeClaimed = {}
CREATIVE_GROUP_SLOTS = { dynamic = { ptr1 = 0x48, ptr2 = 0x50, ptr3 = 0x58 }, static = { ptr1 = 0x60, ptr2 = 0x68, ptr3 = 0x70 }, props = { ptr1 = 0x78, ptr2 = 0x80, ptr3 = 0x88 } }
CREATIVE_GROUP_ORDER = { "dynamic", "static", "props" }
CREATIVE_THEME_ZERO_OFFSETS = { 0x00, 0x04, 0x08, 0x0C, 0x10, 0x14 }

-- ═══════════════════════════════════════════════════════════════
--  yj MODULE
-- ═══════════════════════════════════════════════════════════════
yj = {}

function yj.floatToDec(f)
    local page = gg.allocatePage(gg.PROT_READ | gg.PROT_WRITE, false)
    gg.setValues({{address = page, flags = gg.TYPE_FLOAT, value = f}})
    local v = gg.getValues({{address = page, flags = gg.TYPE_DWORD}})[1].value
    gg.freePage(page)
    return v
end

function yj.getString(addr)
    local bytes = {}
    for i = 0, 255 do
        local v = gg.getValues({{address = addr + i, flags = 1}})[1].value
        if v == 0 then break end
        if v < 0 then v = v + 256 end
        bytes[#bytes + 1] = string.char(v)
    end
    return table.concat(bytes)
end
function yj.stringBytes(str)
    local bytes = {}
    for i = 1, #str do bytes[i] = string.byte(str, i) end
    return bytes
end
function yj.Csearchcalculatestheoffset(value, flags)
    gg.clearResults()
    gg.setRanges(flags)
    gg.searchNumber(value, 1)
    if gg.getResultsCount() == 0 then return nil end
    return gg.getResults(1)[1].address
end
function yj.CsetValuesoffset(offset, flags, value)
    gg.setValues({{address = offset, flags = flags, value = value}})
end
function yj.Allzeropages()
    gg.clearList()
    gg.clearResults()
    gg.setRanges(gg.REGION_STACK)
    gg.searchNumber("0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0::253", 4, false, gg.SIGN_EQUAL, 0, -1, 2048)
    local r = gg.getResults(1)
    if r and #r > 0 and r[1].address then
        gg.clearResults()
        return r[1].address + 0x18
    end
    gg.toast("Không tìm thấy vùng nhớ trang 0")
    return nil
end

-- ═══════════════════════════════════════════════════════════════
--  ANTI-DETECT + SETUP
-- ═══════════════════════════════════════════════════════════════
local blockedApps = {
    "com.gushi.gtpcanary", "com.packagesniffer.frtparlak",
    "com.rhmsoft.edit", "app.greyshirts.sslcapture",
    "frtparlak.rootsniffer", "com.minhui.wifianalyzer",
    "io.neoterm", "com.foxcyber.gg", "sstool.only.com.sstool"
}
local function checkBlocked()
    gg.setVisible(false)
    for _, pkg in ipairs(blockedApps) do
        if gg.isPackageInstalled(pkg) then
            gg.alert("⛔ Detected forbidden app!\n\n📦 " .. pkg)
            os.exit()
        end
    end
end
local function checkGG()
    gg.setVisible(false)
    local ok = pcall(function() gg.require("101.1", 16142) end)
    if not ok then gg.alert("❌ Please use original Game Guardian 101.1!"); os.exit() end
end
local function checkHCR2()
    gg.setVisible(false)
    if gg.getTargetPackage() ~= "com.fingersoft.hcr2" then
        gg.alert("❗ Please select HCR2 on top of Game Guardian!")
        os.exit()
    end
end
local function getHCR2Version()
    local info = gg.getTargetInfo()
    if info and info.versionName then return tostring(info.versionName) end
    return "Unknown"
end
local function detectArch()
    local info = gg.getTargetInfo()
    local libDir = info.nativeLibraryDir:lower()
    if libDir:find("arm64") or libDir:find("aarch64") then return 1
    elseif libDir:find("armeabi") or libDir:find("v7a") then return 2
    elseif libDir:find("x86_64") then return 3
    elseif libDir:find("x86") then return 4 end
    return 0
end
local function getLib()
    local libs = gg.getRangesList("libcocos2dcpp.so")
    if #libs == 0 then
        local c = gg.choice({"⏩ Continue", "❌ Exit"}, nil, "❗ Couldn't find libcocos2dcpp.so!")
        if c ~= 1 then os.exit() end
        return false
    end
    LIB_BASE = libs[1].start
    return true
end
local function selectRange()
    gg.setVisible(false)
    local ranges = {
        { name = "C alloc", value = gg.REGION_C_ALLOC },
        { name = "C data",  value = gg.REGION_C_DATA },
        { name = "Other",   value = gg.REGION_OTHER }
    }
    local labels = {}
    for _, r in ipairs(ranges) do table.insert(labels, r.name) end
    local pick = gg.choice(labels, 0, "⏱️ Chọn vùng nhớ (khuyến nghị: C alloc)")
    if not pick then os.exit() end
    if pick ~= 1 then gg.alert("⚠️ Range này có thể không hoạt động tốt!\nVui lòng dùng C alloc.") end
    RANGE_VALUE = ranges[pick].value
    currentRange = ranges[pick].name
    gg.setRanges(RANGE_VALUE)
    gg.toast("✅ Range: " .. currentRange)
    gg.sleep(500)
end

-- ═══════════════════════════════════════════════════════════════
--  GAME STATUS FINDER
-- ═══════════════════════════════════════════════════════════════
local function findGameStatus()
    local SEARCH_REGIONS = { gg.REGION_C_ALLOC, gg.REGION_OTHER }
    for _, region in ipairs(SEARCH_REGIONS) do
        gg.clearResults()
        gg.setRanges(region)
        gg.searchNumber("h 73 74 61 72 74 75 70 5F 63 6F 75 6E 74", gg.TYPE_BYTE)
        gg.refineNumber("h 73", gg.TYPE_BYTE)
        local scan_results = gg.getResults(gg.getResultsCount())
        gg.clearResults()
        for _, d in ipairs(scan_results) do
            local ptr = gg.getValues({{ address = d.address + 0x1F, flags = gg.TYPE_QWORD }})[1]
            if ptr and ptr.value and ptr.value >= 0x10000 and ptr.value < 0x7FFFFFFFFFFF then
                local ver = gg.getValues({{ address = ptr.value + 0x10, flags = gg.TYPE_DWORD }})[1]
                local v = ver and tonumber(ver.value)
                if v == 65792 or v == 65793 or v == 16843008 or v == 16843009 then
                    local tp = gg.getValues({{ address = ptr.value + 0x80, flags = gg.TYPE_QWORD }})[1]
                    if tp and tp.value and tp.value ~= 0 then
                        local td = gg.getValues({{ address = tp.value, flags = gg.TYPE_DWORD }})[1]
                        if td and td.value and td.value ~= 0 then
                            BaseRegion = region
                            BaseGameStatusRaw = ver.address
                            BaseGameStatus = td.address
                            gg.setRanges(RANGE_VALUE)
                            return true
                        end
                    end
                end
            end
        end
    end
    gg.setRanges(RANGE_VALUE)
    return false
end

local function readStringAt(addr, maxLen)
    maxLen = maxLen or 64
    local reads = {}
    for i = 0, maxLen - 1 do reads[#reads + 1] = { address = addr + i, flags = gg.TYPE_BYTE } end
    local result = gg.getValues(reads)
    local bytes = {}
    for _, v in ipairs(result) do
        if v.value == 0 then break end
        local b = v.value < 0 and v.value + 256 or v.value
        bytes[#bytes + 1] = string.char(b)
    end
    return table.concat(bytes)
end

local PART_CAPS = {
    ["_magnet"] = 15, ["_heavyweight"] = 15, ["_glide"] = 15,
    ["_rollcage"] = 15, ["_air_control"] = 15, ["_winter_tyres"] = 15,
    ["_start_boost"] = 10, ["_jump"] = 10, ["_wheelie_boost"] = 10,
    ["_fume_boost"] = 10, ["_flip_speed_boost"] = 10,
    ["_afterburner"] = 7, ["_turbo_boost"] = 7, ["_spoiler"] = 7,
    ["_perfect_landing_boost"] = 7,
    ["_thrusters"] = 4, ["_nitro"] = 4, ["_fuel_boost"] = 4, ["_coin_boost"] = 4,
}
local function partMaxLevel(name)
    name = tostring(name or "")
    for suffix, cap in pairs(PART_CAPS) do
        if name:find(suffix .. "$") then return cap end
    end
    return 3
end
local function checkGameStatus()
    if not BaseGameStatus or BaseGameStatus == 0 then
        gg.alert("❌ Chưa scan được GameStatus!\n\n💡 Vào Garage (bấm 1 xe) rồi chạy lại script.")
        return false
    end
    return true
end

-- ═══════════════════════════════════════════════════════════════
--  VEHICLE SPEED
-- ═══════════════════════════════════════════════════════════════
local Vehiclespeedchangeoffset = nil
local Vehiclegearshiftvalue = nil
local function VehicleSpeedSet(value)
    yj.CsetValuesoffset(Vehiclespeedchangeoffset + 0x8, 16, value)
    gg.toast("✅ Đã đặt tốc độ: " .. value)
end
local function VehicleSpeedCustom()
    local inp = gg.prompt({"Nhập tốc độ [-1.3 đến -0.6]:"}, {tostring(Vehiclegearshiftvalue)}, {"number"})
    if not inp then return false end
    local v = tonumber(inp[1])
    if not v or v < -1.3 or v > -0.6 then
        gg.alert("❌ Tốc độ phải nằm trong khoảng -1.3 đến -0.6")
        return false
    end
    VehicleSpeedSet(v)
    return true
end
local function VehicleSpeedMenu()
    Vehiclespeedchangeoffset = Vehiclespeedchangeoffset or yj.Csearchcalculatestheoffset("h 11 11 91 3F 00 00 00 20", 8)
    if not Vehiclespeedchangeoffset then
        gg.alert("❌ Không tìm thấy địa chỉ bộ nhớ\n💡 Vào garage bấm 1 xe rồi thử lại.")
        return MainMenu()
    end
    gg.clearResults()
    Vehiclegearshiftvalue = gg.getValues({{address = Vehiclespeedchangeoffset + 0x8, flags = 16}})[1].value
    local items = {
        "✏️ Tự đặt tốc độ xe","🚗 Đặt tốc độ: -1.05","🚗 Đặt tốc độ: -1.00","🚗 Đặt tốc độ: -0.95",
        "🚗 Đặt tốc độ: -0.90","🚗 Đặt tốc độ: -0.85","🚗 Đặt tốc độ: -0.80","🔴 Tắt chỉnh tốc độ xe","⬅️ Quay lại"
    }
    local c = gg.choice(items, nil, "🚗 Tốc độ hiện tại: " .. tostring(Vehiclegearshiftvalue))
    if not c or c == 9 then return MainMenu() end
    if c == 1 then VehicleSpeedCustom()
    elseif c >= 2 and c <= 7 then VehicleSpeedSet(0.05 * c - 1.15)
    elseif c == 8 then VehicleSpeedSet(-1.13333332539) end
    return VehicleSpeedMenu()
end

-- ═══════════════════════════════════════════════════════════════
--  GLOBAL VISION
-- ═══════════════════════════════════════════════════════════════
local Globalvisionoffset = nil
local Globalvisionoffsetvalue = nil
local function GlobalVisionSet(value)
    yj.CsetValuesoffset(Globalvisionoffset + 0x1C, 16, value)
    yj.CsetValuesoffset(Globalvisionoffset + 0x20, 16, value)
    gg.toast("✅ Đã đặt tầm nhìn: " .. value)
end
local function GlobalVisionCustom()
    local inp = gg.prompt({"Nhập tầm nhìn:"}, {tostring(Globalvisionoffsetvalue)}, {"number"})
    if not inp then return end
    local v = tonumber(inp[1]); if not v then return end
    GlobalVisionSet(v)
end
local function GlobalVisionMenu()
    Globalvisionoffset = Globalvisionoffset or yj.Csearchcalculatestheoffset("h 0A D7 A3 3D 00 00 A0 41", 16)
    if not Globalvisionoffset then gg.alert("❌ Không tìm thấy địa chỉ bộ nhớ"); return MainMenu() end
    gg.clearResults()
    Globalvisionoffsetvalue = gg.getValues({{address = Globalvisionoffset + 0x1C, flags = 16}})[1].value
    local items = {
        "✏️ Tự đặt tầm nhìn","Tầm nhìn 20","Tầm nhìn 40","Tầm nhìn 60","Tầm nhìn 80",
        "Tầm nhìn 100","Tầm nhìn 120","Tầm nhìn 140","Tầm nhìn 160","Tầm nhìn 180",
        "Tầm nhìn 200","Tầm nhìn 220","Tầm nhìn 240","Tầm nhìn 260","Tầm nhìn 280",
        "Tầm nhìn 300","🔴 Tắt tầm nhìn toàn cục","⬅️ Quay lại"
    }
    local c = gg.choice(items, nil, "👁️ Tầm nhìn hiện tại: " .. tostring(Globalvisionoffsetvalue))
    if not c or c == 18 then return MainMenu() end
    if c == 1 then GlobalVisionCustom()
    elseif c >= 2 and c <= 16 then GlobalVisionSet(c * 20 - 20)
    elseif c == 17 then
        yj.CsetValuesoffset(Globalvisionoffset + 0x1C, 16, 20)
        yj.CsetValuesoffset(Globalvisionoffset + 0x20, 16, 50)
        gg.toast("🔴 Đã tắt tầm nhìn toàn cục")
    end
    return GlobalVisionMenu()
end

-- ═══════════════════════════════════════════════════════════════
--  UPGRADE WITHOUT SCRAP
-- ═══════════════════════════════════════════════════════════════
local noScrapState = false
local function upgradeWithoutScrap()
    local choice = gg.choice({
        "🟢 Bật Upgrade Without Scrap","🔴 Tắt Upgrade Without Scrap","⬅️ Quay lại"
    }, nil, "Trạng thái: " .. (noScrapState and "🟢 ON" or "🔴 OFF"))
    if not choice or choice == 3 then return MainMenu() end
    if choice == 1 then
        gg.clearResults(); gg.setRanges(RANGE_VALUE)
        gg.searchNumber("2139095039D;-0.6F::17", gg.TYPE_FLOAT)
        gg.refineNumber("-0.6", gg.TYPE_FLOAT)
        local res = gg.getResults(gg.getResultsCount())
        if #res == 0 then gg.alert("❌ Không tìm thấy! Vào garage trước."); return end
        gg.editAll("-999", gg.TYPE_FLOAT)
        gg.clearResults(); noScrapState = true; gg.alert("✅")
    elseif choice == 2 then
        if not noScrapState then gg.alert("❌ Chưa bật!"); return end
        gg.clearResults(); gg.setRanges(RANGE_VALUE)
        gg.searchNumber("2139095039D;-999F::17", gg.TYPE_FLOAT)
        gg.refineNumber("-999", gg.TYPE_FLOAT)
        if gg.getResultsCount() > 0 then
            gg.editAll("-0.60000002384", gg.TYPE_FLOAT)
            noScrapState = false; gg.alert("❌ Đã tắt!")
        end
    end
end

-- ═══════════════════════════════════════════════════════════════
--  FLY HACK
-- ═══════════════════════════════════════════════════════════════
local flyState = false
local function flyHack()
    local choice = gg.choice({
        "🟢 Bật Fly Hack","🔴 Tắt Fly Hack","⬅️ Quay lại"
    }, nil, "Trạng thái: " .. (flyState and "🟢 ON" or "🔴 OFF"))
    if not choice or choice == 3 then return MainMenu() end
    if choice == 1 then
        gg.clearResults(); gg.setRanges(gg.REGION_C_BSS)
        for _, v in ipairs({"-0.75", "-0.55", "-0.25", "-0.15"}) do
            gg.searchNumber(v, gg.TYPE_FLOAT); gg.getResults(2)
            gg.editAll("0.08", gg.TYPE_FLOAT); gg.clearResults()
        end
        gg.searchNumber("0.08", gg.TYPE_FLOAT)
        local res = gg.getResults(2)
        if #res > 0 then
            gg.editAll("-1.2", gg.TYPE_FLOAT); flyState = true; gg.alert("✅")
        else gg.alert("❌ Không tìm thấy!") end
        gg.setRanges(RANGE_VALUE)
    elseif choice == 2 then
        if not flyState then gg.alert("❌ Chưa bật!"); return end
        gg.clearResults(); gg.setRanges(gg.REGION_C_BSS)
        gg.searchNumber("-1.2", gg.TYPE_FLOAT)
        if gg.getResultsCount() > 0 then
            gg.editAll("0.08", gg.TYPE_FLOAT); flyState = false; gg.alert("❌ Đã tắt!")
        end
        gg.setRanges(RANGE_VALUE)
    end
end

-- ═══════════════════════════════════════════════════════════════
--  UNLOCK ANY VEHICLE
-- ═══════════════════════════════════════════════════════════════
local VEHICLES = {
    "SLED","DOUGHNUT","SNOWBOARD","HILL CLIMBER","HILL CLIMBER Mk2","SPORTS CAR","DUNE BUGGY","SUPER DIESEL","SUPERBIKE","SUPERCAR","RALLY CAR","LOWRIDER","BEAST","HOT ROD","RACING TRUCK","FORMULA","MUSCLE CAR","MONSTER TRUCK","ROTATOR","CHOPPER","TANK","CC-EV","STOCKER","HAVOC","BUS","MOONLANDER","HOVERBIKE","ROCK BOUNCER","RAIDER","BOLT","ATV","OFFROADER","SCOOTER","MOTOCROSS","TRACTOR","SNOWMOBILE","MONOWHEEL","GLIDER"
}
local function unlockVehicleByName(name)
    if not name or name == "" then return false end
    gg.clearResults(); gg.setRanges(RANGE_VALUE)
    gg.searchNumber(":" .. name, gg.TYPE_BYTE)
    local getRes = gg.getResults(gg.getResultsCount())
    if #getRes == 0 then return false end
    local tbl = {}
    for _, v in ipairs(getRes) do table.insert(tbl, {address = v.address + 0xEF, flags = gg.TYPE_DWORD}) end
    gg.clearResults(); gg.loadResults(tbl)
    gg.refineNumber("1~5", gg.TYPE_DWORD)
    local unlocked = gg.getResults(gg.getResultsCount())
    if #unlocked == 0 then return false end
    gg.editAll("1", gg.TYPE_DWORD)
    local edits = {}
    for _, v in ipairs(unlocked) do
        table.insert(edits, {address = v.address + 0x38, flags = gg.TYPE_DWORD, value = 0})
        for i = 1, 13 do
            table.insert(edits, {address = v.address + (i * 4), flags = gg.TYPE_DWORD, value = 0})
        end
    end
    gg.setValues(edits); gg.clearResults()
    return true
end
local function unlockAnyVehicle()
    local menu = {}
    for _, v in ipairs(VEHICLES) do table.insert(menu, "🚗 " .. v) end
    table.insert(menu, "⬅️ Quay lại")
    local pick = gg.multiChoice(menu, nil, "☑️ Chọn nhiều xe để mở khóa")
    if not pick then return MainMenu() end
    local count = 0
    for i, sel in pairs(pick) do
        if sel and i <= #VEHICLES then
            if unlockVehicleByName(VEHICLES[i]) then count = count + 1 end
        end
    end
    if count > 0 then gg.alert("✅ Đã mở khóa " .. count .. " xe!")
    else gg.alert("❌ Không mở khóa được xe nào!") end
end

-- ═══════════════════════════════════════════════════════════════
--  TRACKS EDITOR
-- ═══════════════════════════════════════════════════════════════
local function tracksEditor()
    local input = gg.prompt({
        "🗺️ Tên Map (VD: Countryside):","📏 Độ dài hiện tại (m):","📐 Độ dài mới (m):","✅"
    }, {"", "", "", true}, {"text", "number", "number", "checkbox"})
    if not input then return MainMenu() end
    local mapName = input[1]; local curLength = tonumber(input[2])
    local newLength = tonumber(input[3]); local doVerify = input[4]
    if not mapName or mapName == "" or not curLength or not newLength then
        gg.alert("❌ Nhập thiếu thông tin!"); return
    end
    gg.clearResults(); gg.setRanges(RANGE_VALUE)
    gg.searchNumber(":" .. mapName, gg.TYPE_BYTE)
    if gg.getResultsCount() == 0 then gg.alert("❌ Không tìm thấy map: " .. mapName); return end
    gg.refineNumber(string.byte(mapName:sub(1, 1)), gg.TYPE_BYTE)
    local results = gg.getResults(30)
    if #results == 0 then gg.alert("⚠️ Refine thất bại!"); return end
    local patched = 0
    for _, r in ipairs(results) do
        gg.clearResults(); gg.searchNumber(r.address - 1, 32)
        local ptrs = gg.getResults(100)
        for _, p in ipairs(ptrs) do
            local lengthAddr = p.address + 0x20
            local verifyAddr = p.address + 0x34
            local curVal = gg.getValues({{address = lengthAddr, flags = gg.TYPE_DWORD}})[1].value
            if curVal == curLength then
                gg.setValues({{address = lengthAddr, flags = gg.TYPE_DWORD, value = newLength}})
                if doVerify then gg.setValues({{address = verifyAddr, flags = gg.TYPE_DWORD, value = 1}}) end
                patched = patched + 1
            end
        end
    end
    if patched > 0 then gg.alert("✅ " .. patched .. " entries!")
    else gg.alert("❌ Không match!") end
end

-- ═══════════════════════════════════════════════════════════════
--  VEHICLE HACKS
-- ═══════════════════════════════════════════════════════════════
local VehicleHacks = {
    f1  = { name = "Lowrider - Super Jumpshocks", search = 'Q 00 00 A0 "A" 00 80 40 66 66 06 41', replace = 'Q 00 00 A0 "A" 00 80 "@" 00 C8 41', state = false, results = nil },
    f2  = { name = "Hot Rod - Boost Hack", search = "4620693218774745088", replace = "4620693218877722624", state = false, results = nil },
    f3  = { name = "CC-EV - Super Boost", search = 'Q 00 00 A0 "A" 00 08 "A" 00 48 41', replace = 'Q 00 00 A0 "A" 00 08 "A" 00 C8 42', state = false, results = nil },
    f4  = { name = "Glider - Infinite Propeller", search = 'Q 00 00 A0 "A" 00 C0 "?" 00 40 40', replace = 'Q 00 00 A0 "A" 00 C0 3F 28 6B EE 4E', state = false, results = nil },
    f5  = { name = "Muscle Car - Engine Hack", search = '20f;34f;44f:9', refine = '44', replace = '220', state = false, results = nil },
    f6  = { name = "Glider - Infinite Wing", search = 'Q 00 00 A0 "A" 00 A0 "@" 00 20 41', replace = 'Q 00 00 A0 "A" 00 A0 40 66 7F E2 4E', state = false, results = nil },
    f7  = { name = "Muscle Car - Super Burn-Out", search = 'Q 00 00 A0 "A" 00 60 "@" 00 D0 40', replace = 'Q 00 00 A0 "A" 00 60 "@" 00 FA 43', state = false, results = nil },
    f8  = { name = "Rally Car - Grip Hack", search = '0.8;1.2:5', refine = '1.2', replace = '999', state = false, results = nil },
    f9  = { name = "Formula - Super Grip", search = 'Q 00 00 A0 41 CD CC CC ">" 00 C0 3F', replace = 'Q 00 00 A0 41 CD CC CC ">" 00 70 41', state = false, results = nil },
    f10 = { name = "Supercar - Super Air Brake", search = 'Q 00 00 A0 "A" 00 A0 C0 00 00 A0 C1', replace = 'Q 00 00 A0 "A" 00 A0 C0 00 00 C8 C2', state = false, results = nil },
    f11 = { name = "Supercar - Reverse Air Brake", search = 'Q 00 00 A0 "A" 00 A0 C0 00 00 A0 C1', replace = 'Q 00 00 A0 "A" 00 A0 C0 00 00 8C 42', state = false, results = nil },
    f12 = { name = "Rally Car - Engine Hack", search = '10;25:5', refine = '25', replace = '999', state = false, results = nil },
    f13 = { name = "Muscle Car - Downforce + Fuel", search = '43.0;1.27999997139;2.0;0.69999998808;25.0:49', refine = '43', replace = '1000', state = false, results = nil }
}
local function toggleVehicleHack(key)
    local data = VehicleHacks[key]
    if not data then return end
    local choice = gg.choice({"🟢 BẬT","🔴 TẮT","⬅️ Quay lại"}, nil,
        "🔧 " .. data.name .. "\nTrạng thái: " .. (data.state and "🟢 ON" or "🔴 OFF"))
    if not choice or choice == 3 then return end
    local vType = gg.TYPE_FLOAT
    local s = tostring(data.search)
    if s:sub(1,2) == "Q " then vType = gg.TYPE_BYTE
    elseif s:find(";") then vType = gg.TYPE_FLOAT
    elseif not s:find("%.") then
        if #s > 10 then vType = gg.TYPE_QWORD else vType = gg.TYPE_DWORD end
    end
    if choice == 1 then
        gg.clearResults(); gg.setRanges(RANGE_VALUE)
        gg.searchNumber(data.search, vType)
        if data.refine and gg.getResultsCount() > 0 then gg.refineNumber(data.refine, vType) end
        local count = gg.getResultsCount()
        if count == 0 then gg.alert("❌ Không tìm thấy! Vào xe này trước.")
        else
            local results = gg.getResults(count)
            data.results = gg.getValues(results)
            gg.editAll(data.replace, vType)
            data.state = true; gg.clearResults()
            gg.toast("✅ Đã bật: " .. data.name)
        end
    elseif choice == 2 then
        if data.results then
            gg.setValues(data.results)
            data.state = false
            gg.toast("❌ Đã tắt: " .. data.name)
        else gg.alert("❌ Chưa bật!") end
    end
end
local function vehicleHacksMenu()
    local keys = {}
    for k in pairs(VehicleHacks) do table.insert(keys, k) end
    table.sort(keys, function(a, b) return tonumber(a:match("%d+")) < tonumber(b:match("%d+")) end)
    local labels = {}
    local n = 1
    for _, k in ipairs(keys) do
        local v = VehicleHacks[k]
        table.insert(labels, (v.state and "🟢" or "⚫") .. " " .. n .. ". " .. v.name)
        n = n + 1
    end
    table.insert(labels, "⬅️ Quay lại")
    local pick = gg.choice(labels, nil, nil)
    if not pick or pick == #labels then return MainMenu() end
    toggleVehicleHack(keys[pick])
    return vehicleHacksMenu()
end

-- ═══════════════════════════════════════════════════════════════
--  FREE CHESTS
-- ═══════════════════════════════════════════════════════════════
local freeChestsFound = false
local freeChestsOriginal = {}
local function freeChests()
    local choice = gg.choice({"🟢 Bật Free Chests","🔴 Tắt Free Chests","⬅️ Quay lại"},
        nil, "Trạng thái: " .. (freeChestsFound and "🟢 ON" or "🔴 OFF"))
    if not choice or choice == 3 then return MainMenu() end
    if choice == 1 then
        if not freeChestsFound then
            gg.clearResults(); gg.setRanges(gg.REGION_C_DATA)
            gg.searchNumber("0.1", gg.TYPE_FLOAT)
            local count = gg.getResultsCount()
            if count == 0 then gg.alert("❌ Không tìm thấy!"); gg.setRanges(RANGE_VALUE); return end
            local res = gg.getResults(count)
            freeChestsOriginal = gg.getValues(res)
            local nv = {}
            for i, v in ipairs(res) do nv[i] = {address = v.address, flags = v.flags, value = "0"} end
            gg.setValues(nv); freeChestsFound = true
            gg.setRanges(RANGE_VALUE); gg.alert("✅")
        else gg.toast("✅") end
    elseif choice == 2 then
        if freeChestsFound and #freeChestsOriginal > 0 then
            gg.setValues(freeChestsOriginal); freeChestsFound = false
            gg.setRanges(RANGE_VALUE); gg.alert("❌ Đã tắt!")
        else gg.alert("❌ Chưa bật!") end
    end
end

-- ═══════════════════════════════════════════════════════════════
--  FREE PURCHASES
-- ═══════════════════════════════════════════════════════════════
local function freePurchases()
    local c = gg.choice({"▶️ TIẾP TỤC","⬅️ Quay lại"}, nil, "⚠️ Cần kết nối Google Play!\nĐang ở Shop của game?")
    if c ~= 1 then return MainMenu() end
    gg.clearResults(); gg.setRanges(RANGE_VALUE)
    gg.searchNumber("7,234,820", gg.TYPE_DWORD)
    local results = gg.getResults(100)
    if #results == 0 then gg.alert("❌ Không tìm thấy! Vào Shop trước."); return end
    for _, v in ipairs(results) do
        gg.clearResults(); gg.searchNumber(v.address, gg.TYPE_QWORD)
        local ptrs = gg.getResults(100)
        for _, vv in ipairs(ptrs) do
            local val = gg.getValues({{address = vv.address + 0x18, flags = 4}})[1].value
            if val > 0 and val < 100 then
                local edits = {}
                for off = 0x18, 0x2C, 4 do
                    table.insert(edits, {address = vv.address + off, flags = 4, value = 0})
                end
                gg.setValues(edits)
            end
        end
    end
    gg.alert("✅")
end

-- ═══════════════════════════════════════════════════════════════
--  ADVENTURE CHEST HACK V1
-- ═══════════════════════════════════════════════════════════════
local advChestV1Found = false
local advChestV1Original = nil
local function advChestHackV1()
    local choice = gg.choice({"🟢 Bật Rising Chest Levels","🔴 Tắt Rising Chest Levels","⬅️ Quay lại"},
        nil, "Trạng thái: " .. (advChestV1Found and "🟢 ON" or "🔴 OFF"))
    if not choice or choice == 3 then return MainMenu() end
    if choice == 1 then
        if not advChestV1Found then
            gg.clearResults(); gg.setRanges(RANGE_VALUE)
            gg.searchNumber("500;500::5", gg.TYPE_DWORD)
            local count = gg.getResultsCount()
            if count == 0 then gg.alert("❌ Không tìm thấy!"); return end
            local res = gg.getResults(count)
            advChestV1Original = gg.getValues(res)
            local edits = {}
            for i, v in ipairs(res) do edits[i] = {address = v.address, flags = v.flags, value = -1} end
            gg.setValues(edits); advChestV1Found = true; gg.alert("✅")
        else gg.alert("✅ Đã bật rồi!") end
    elseif choice == 2 then
        if advChestV1Found then
            gg.setRanges(RANGE_VALUE); gg.setValues(advChestV1Original)
            advChestV1Found = false; gg.alert("❌ Đã tắt!")
        else gg.alert("❌ Chưa bật!") end
    end
end

-- ═══════════════════════════════════════════════════════════════
--  LIB OFFSETS
-- ═══════════════════════════════════════════════════════════════
local libOffsets = {
    ["arm64-v8a"] = {
        [1] = { name = "Auto Win", edits = {
            {0x11F6AE0, "55008052r"},
            {0x11F6CFC, "0990321Er"},
            {0x1D14FBC, "00008052r"},
            {0x249AEB8, "00000000r"}
        }},
        [2] = { name = "Fake Unlock", edits = {{0x16A4FD0, "20008052r"}} },
        [3] = { name = "Free Upgrades", edits = {
            {0xFA4270, "0090641Er"},
            {0xFA428C, "0090641Er"}
        }},
        [4] = { name = "Force Boss", edits = {
            {0x16988D4, "00C15FBCr"},
            {0x1527B6C, "00C15FBCr"}
        }},
        [5] = { name = "Fake VIP ", edits = {{0x16AA504, "20008052r"}} },
    },
    ["armeabi-v7a"] = {},
}

local function applyLibEdits(entry, backupTable, enable)
    if not entry or not entry.edits or #entry.edits == 0 then return false end
    if not LIB_BASE then gg.alert("❌ LIB_BASE chưa có!"); return false end
    if enable then
        for i, e in ipairs(entry.edits) do
            local off = e[1]; local strV = tostring(e[2])
            local isRel = strV:sub(-1) == "r"
            local addr = isRel and (LIB_BASE + off) or off
            local orig = gg.getValues({{address = addr, flags = gg.TYPE_DWORD}})
            if orig and orig[1] then backupTable[i] = {address = addr, value = orig[1].value} end
            if not pcall(function() gg.setValues({{address = addr, flags = gg.TYPE_DWORD, value = strV}}) end) then
                return false
            end
        end
        return true
    else
        if not backupTable or not next(backupTable) then return false end
        local restore = {}
        for _, b in pairs(backupTable) do
            restore[#restore + 1] = {address = b.address, flags = gg.TYPE_DWORD, value = b.value}
        end
        if #restore > 0 then gg.setValues(restore) end
        return true
    end
end

-- ═══════════════════════════════════════════════════════════════
--  AUTO WIN / FAKE UNLOCK / FREE UPGRADE
-- ═══════════════════════════════════════════════════════════════
local autoWinState, autoWinBackup = false, nil
local fakeUnlockState, fakeUnlockBackup = false, nil
local freeUpgradeState, freeUpgradeBackup = false, nil

local function autoWin()
    if archType == 3 or archType == 4 then gg.alert("❗ Chỉ ARM (ARMV8)!"); return end
    local archKey = getArchKey()
    if not archKey or not libOffsets[archKey] then gg.alert("❌ Không có offset cho arch!"); return end
    local entry = libOffsets[archKey][1]
    if not entry then gg.alert("❌ Entry trống!"); return end
    local choice = gg.choice({"🟢 Bật Auto Win","🔴 Tắt Auto Win","⬅️ Quay lại"}, nil,
        "🔥 " .. entry.name .. "\n📦 " .. #entry.edits .. " patches | " .. archKey ..
        "\nTrạng thái: " .. (autoWinState and "🟢 ON" or "🔴 OFF"))
    if not choice or choice == 3 then return MainMenu() end
    if choice == 1 then
        if autoWinState then gg.toast("✅"); return end
        autoWinBackup = {}
        if applyLibEdits(entry, autoWinBackup, true) then autoWinState = true; gg.toast("✅")
        else autoWinBackup = nil; gg.alert("❌") end
    elseif choice == 2 then
        if not autoWinState then gg.alert("❌ Chưa bật!"); return end
        if applyLibEdits(entry, autoWinBackup, false) then autoWinState = false; autoWinBackup = nil; gg.toast("❌ Auto Win TẮT")
        else gg.alert("❌ Tắt thất bại!") end
    end
end

local function fakeUnlock()
    if archType == 3 or archType == 4 then gg.alert("❗ Chỉ ARM!"); return end
    local archKey = getArchKey()
    if not archKey or not libOffsets[archKey] then gg.alert("❌ Không có offset!"); return end
    local entry = libOffsets[archKey][2]
    if not entry then gg.alert("❌ Entry trống!"); return end
    local choice = gg.choice({"🟢 Bật Fake Unlock","🔴 Tắt Fake Unlock","⬅️ Quay lại"}, nil,
        "🎭 " .. entry.name .. "\n📦 " .. #entry.edits .. " patches\n⚠️ KHÔNG mở khóa thật!")
    if not choice or choice == 3 then return MainMenu() end
    if choice == 1 then
        if fakeUnlockState then gg.toast("✅"); return end
        fakeUnlockBackup = {}
        if applyLibEdits(entry, fakeUnlockBackup, true) then fakeUnlockState = true; gg.toast("✅")
        else fakeUnlockBackup = nil; gg.alert("❌") end
    elseif choice == 2 then
        if not fakeUnlockState then gg.alert("❌"); return end
        if applyLibEdits(entry, fakeUnlockBackup, false) then fakeUnlockState = false; fakeUnlockBackup = nil; gg.toast("❌ TẮT")
        else gg.alert("❌ Tắt thất bại!") end
    end
end

local function freeUpgrade()
    if archType == 3 or archType == 4 then gg.alert("❗ Chỉ ARM!"); return end
    local archKey = getArchKey()
    if not archKey or not libOffsets[archKey] then gg.alert("❌ Không có offset!"); return end
    local entry = libOffsets[archKey][3]
    if not entry then gg.alert("❌ Entry trống!"); return end
    local choice = gg.choice({"🟢 Bật Free Upgrade","🔴 Tắt Free Upgrade","⬅️ Quay lại"}, nil,
        "🔧 " .. entry.name .. "\n📦 " .. #entry.edits .. " patches")
    if not choice or choice == 3 then return MainMenu() end
    if choice == 1 then
        if freeUpgradeState then gg.toast("✅ Đã bật rồi!"); return end
        freeUpgradeBackup = {}
        if applyLibEdits(entry, freeUpgradeBackup, true) then freeUpgradeState = true; gg.toast("✅ Free Upgrade BẬT")
        else freeUpgradeBackup = nil; gg.alert("❌ Bật thất bại!") end
    elseif choice == 2 then
        if not freeUpgradeState then gg.alert("❌ Chưa bật!"); return end
        if applyLibEdits(entry, freeUpgradeBackup, false) then freeUpgradeState = false; freeUpgradeBackup = nil; gg.toast("❌ TẮT")
        else gg.alert("❌ Tắt thất bại!") end
    end
end

-- ═══════════════════════════════════════════════════════════════
--  FORCE BOSS
-- ═══════════════════════════════════════════════════════════════
local forceBossState, forceBossBackup, forceBossOrigValue = false, nil, nil

local function forceBoss()
    if archType == 3 or archType == 4 then gg.alert("❗ Chỉ ARM (ARMV8)!"); return end
    local archKey = getArchKey()
    if not archKey or not libOffsets[archKey] or not libOffsets[archKey][4] then
        gg.alert("❌ Không có offset Force Boss!"); return
    end
    local entry = libOffsets[archKey][4]
    local choice = gg.choice({"🟢 Bật Force Boss","🔴 Tắt Force Boss","⬅️ Quay lại"}, nil,
        "👹 Force Boss\n📦 " .. #entry.edits .. " patches | " .. archKey ..
        "\n⚠️ 1.76.1!\nTrạng thái: " .. (forceBossState and "🟢 ON" or "🔴 OFF"))
    if not choice or choice == 3 then return MainMenu() end

    if choice == 1 then
        if forceBossState then gg.toast("✅ Đã bật rồi!"); return end
        if not checkGameStatus() then return end
        forceBossBackup = {}
        if not applyLibEdits(entry, forceBossBackup, true) then
            forceBossBackup = nil
            gg.alert("❌ Patch lib thất bại! Version không khớp?")
            return
        end
        local targetAddr = BaseGameStatus - 0x4
        local cur = gg.getValues({{address = targetAddr, flags = gg.TYPE_FLOAT}})
        if cur and cur[1] then
            forceBossOrigValue = cur[1].value
            gg.setValues({{address = targetAddr, flags = gg.TYPE_FLOAT, value = 99.9}})
        end
        forceBossState = true
        gg.toast("✅")
    elseif choice == 2 then
        if not forceBossState then gg.alert("❌ Chưa bật!"); return end
        applyLibEdits(entry, forceBossBackup, false)
        if forceBossOrigValue ~= nil and BaseGameStatus and BaseGameStatus ~= 0 then
            gg.setValues({{address = BaseGameStatus - 0x4, flags = gg.TYPE_FLOAT, value = forceBossOrigValue}})
        end
        forceBossBackup, forceBossOrigValue = nil, nil
        forceBossState = false
        gg.toast("❌ Force Boss TẮT")
    end
end

-- ═══════════════════════════════════════════════════════════════
--  DEBUG MODE
-- ═══════════════════════════════════════════════════════════════
local function debugMode()
    local choice = gg.choice({"🟢 Bật Debug Mode","🔴 Tắt Debug Mode","⬅️ Quay lại"}, nil, "💎 Play Hidden Maps")
    if not choice or choice == 3 then return MainMenu() end
    gg.clearResults(); gg.setRanges(gg.REGION_C_ALLOC | gg.REGION_C_DATA)
    gg.searchNumber("h 24 64 65 62 75 67 5F 6D 6F 64 65 5F 65 6E 61 62 6C 65 64", gg.TYPE_BYTE)
    if gg.getResultsCount() == 0 then gg.alert("❌ Không tìm thấy!"); gg.setRanges(RANGE_VALUE); return end
    local res = gg.getResults(1)
    local ptrData = gg.getValues({{address = res[1].address + 0x20, flags = gg.TYPE_QWORD}})
    if not ptrData[1] or ptrData[1].value == 0 then gg.alert("❌ Không tìm thấy pointer!"); gg.setRanges(RANGE_VALUE); return end
    local flagAddr = ptrData[1].value
    if choice == 1 then gg.setValues({{address = flagAddr, flags = gg.TYPE_BYTE, value = 1}}); gg.alert("✅")
    elseif choice == 2 then gg.setValues({{address = flagAddr, flags = gg.TYPE_BYTE, value = 0}}); gg.alert("❌ Đã tắt!") end
    gg.setRanges(RANGE_VALUE)
end

-- ═══════════════════════════════════════════════════════════════
--  VIP PASS (REAL)
-- ═══════════════════════════════════════════════════════════════
local VIPM = {}
function VIPM.readPtr(a) local v = gg.getValues({{address = a, flags = gg.TYPE_QWORD}}); return (v and v[1]) and v[1].value or 0 end
VIPM._main = nil
function VIPM.mainStatus()
    if VIPM._main then return VIPM._main end
    gg.setVisible(false); gg.clearResults(); gg.clearList()
    gg.setRanges(gg.REGION_C_ALLOC)
    gg.searchNumber("Q 1A 73 74 61 72 74 75 70 5F 63 6F 75", gg.TYPE_BYTE)
    gg.refineNumber("26", gg.TYPE_BYTE)
    local results = gg.getResults(gg.getResultsCount()); gg.clearResults()
    if not results or #results == 0 then return nil end
    for _, v in ipairs(results) do
        local p20 = VIPM.readPtr(v.address + 0x20)
        if p20 ~= 0 then
            local p80 = VIPM.readPtr(p20 + 0x80)
            if p80 ~= 0 then VIPM._main = p80; return p80 end
        end
    end
    return nil
end
local function vipPassFunc()
    local res = gg.prompt({"⭐ Nhập số ngày VIP [1-30]:"}, {30}, {"number"})
    if not res then return end
    local days = math.max(1, math.min(30, tonumber(res[1]) or 30))
    local base = VIPM.mainStatus()
    if not base then gg.toast("❌ Không tìm thấy Base Status!"); return end
    local vipPtr = VIPM.readPtr(base + 0x3A8)
    if vipPtr == 0 then gg.toast("❌ Lỗi Pointer VIP!"); return end
    local vip = vipPtr + 0x10
    local now = os.time(os.date("!*t"))
    gg.setValues({
        {address = vip, flags = gg.TYPE_DWORD, value = 130559},
        {address = vip + 0x4, flags = gg.TYPE_DWORD, value = 81},
        {address = vip + 0x8, flags = gg.TYPE_DWORD, value = now + 86400 * days},
        {address = vip + 0xC, flags = gg.TYPE_DWORD, value = 6},
        {address = vip + 0x10, flags = gg.TYPE_DWORD, value = now},
        {address = vip + 0x14, flags = gg.TYPE_DWORD, value = now},
        {address = vip + 0x18, flags = gg.TYPE_DWORD, value = now},
        {address = vip + 0x1C, flags = gg.TYPE_DWORD, value = 65793},
    })
    local p = VIPM.readPtr(base + 0x2E0)
    if p ~= 0 then
        local it = {address = p + 0x2C, flags = gg.TYPE_DWORD, value = 0, freeze = true}
        gg.setValues({it}); gg.addListItems({it})
    end
    gg.clearResults(); gg.toast("⭐ VIP " .. days .. " ngày!")
end

-- ═══════════════════════════════════════════════════════════════
--  FAKE VIP (Lib patch)
-- ═══════════════════════════════════════════════════════════════
local fakeVIPState, fakeVIPBackup = false, nil

local function FakeVIPMenu()
    if archType == 3 or archType == 4 then
        gg.alert("❗ Fake VIP chỉ hỗ trợ ARM (ARMV8)!")
        return MainMenu()
    end
    local archKey = getArchKey()
    if not archKey or not libOffsets[archKey] or not libOffsets[archKey][5] then
        gg.alert("❌ Không có offset Fake VIP cho arch này!")
        return MainMenu()
    end
    local entry = libOffsets[archKey][5]
    local c = gg.choice({
        "🟢 Bật Fake VIP",
        "🔴 Tắt Fake VIP",
        "⬅️ Quay lại"
    }, nil,
        "🎭 Fake VIP (Lib patch)\n📦 " .. #entry.edits .. " patch | " .. archKey ..
        "\n⚠️ Offset 1.76.1\nTrạng thái: " .. (fakeVIPState and "🟢 ON" or "🔴 OFF"))
    if not c or c == 3 then return MainMenu() end
    if c == 1 then
        if fakeVIPState then gg.toast("✅"); return FakeVIPMenu() end
        fakeVIPBackup = {}
        if applyLibEdits(entry, fakeVIPBackup, true) then
            fakeVIPState = true
            gg.toast("✅")
            gg.alert("✅ Đã bật Fake VIP!")
        else
            fakeVIPBackup = nil
            gg.alert("❌ Patch lib thất bại!\nVersion không khớp 1.76.1?")
        end
    elseif c == 2 then
        if not fakeVIPState then gg.alert("❌ Chưa bật!"); return FakeVIPMenu() end
        if applyLibEdits(entry, fakeVIPBackup, false) then
            fakeVIPState = false; fakeVIPBackup = nil
            gg.toast("❌ Fake VIP TẮT")
        else
            gg.alert("❌ Tắt thất bại!")
        end
    end
    return FakeVIPMenu()
end

-- ═══════════════════════════════════════════════════════════════
--  MAX VEHICLES / MASTERY / PARTS
-- ═══════════════════════════════════════════════════════════════
local function MaxVehicles()
    if not checkGameStatus() then return end
    gg.alert("⚠️ Vào garage trước rồi bấm OK")
    local vehicleListPtr = gg.getValues({{address = BaseGameStatus + 0xB8, flags = gg.TYPE_QWORD}})[1].value
    local totalVehicles = gg.getValues({{address = BaseGameStatus + 0xC0, flags = gg.TYPE_DWORD}})[1].value
    if not vehicleListPtr or vehicleListPtr == 0 or not totalVehicles or totalVehicles == 0 then
        gg.alert("❌ Không đọc được vehicle list!"); return
    end
    local reads = {}
    for i = 0, totalVehicles - 1 do reads[#reads + 1] = {address = vehicleListPtr + i * 8, flags = gg.TYPE_QWORD} end
    local vPtrs = gg.getValues(reads)
    local vehicles = {}
    for _, v in ipairs(vPtrs) do if v.value and v.value ~= 0 then vehicles[#vehicles + 1] = v.value end end
    local meta = {}
    for _, vp in ipairs(vehicles) do
        meta[#meta + 1] = {address = vp + 0x18, flags = gg.TYPE_QWORD}
        meta[#meta + 1] = {address = vp + 0x20, flags = gg.TYPE_QWORD}
    end
    local metaVals = gg.getValues(meta)
    local upReads = {}
    for k, vp in ipairs(vehicles) do
        local namePtr = metaVals[(k - 1) * 2 + 1] and metaVals[(k - 1) * 2 + 1].value
        local upgradeListPtr = metaVals[(k - 1) * 2 + 2] and metaVals[(k - 1) * 2 + 2].value
        local vehicleName = (namePtr and namePtr ~= 0) and readStringAt(namePtr + 1) or "unknown"
        local slots = vehicleName:find("lowrider") and 5 or 4
        if upgradeListPtr and upgradeListPtr ~= 0 then
            for j = 0, slots - 1 do
                upReads[#upReads + 1] = {address = upgradeListPtr + j * 8, flags = gg.TYPE_QWORD}
            end
        end
    end
    local upPtrs = gg.getValues(upReads)
    local edits = {}
    for _, p in ipairs(upPtrs) do
        if p.value and p.value ~= 0 then
            edits[#edits + 1] = {address = p.value + 0x20, flags = gg.TYPE_DWORD, value = 19}
            edits[#edits + 1] = {address = p.value + 0x24, flags = gg.TYPE_DWORD, value = 19}
        end
    end
    if #edits > 0 then gg.setValues(edits); gg.alert("✅ Đã max " .. #vehicles .. " vehicles!")
    else gg.alert("❌ Không có gì để max!") end
end

local function MaxMastery()
    if not checkGameStatus() then return end
    gg.alert("⚠️ Dùng Max Vehicles TRƯỚC!")
    local ts = os.time()
    local vehicleListPtr = gg.getValues({{address = BaseGameStatus + 0xB8, flags = gg.TYPE_QWORD}})[1].value
    local totalVehicles = gg.getValues({{address = BaseGameStatus + 0xC0, flags = gg.TYPE_DWORD}})[1].value
    if not vehicleListPtr or vehicleListPtr == 0 then gg.alert("❌ Không đọc được vehicle list!"); return end
    local reads = {}
    for i = 0, totalVehicles - 1 do reads[#reads + 1] = {address = vehicleListPtr + i * 8, flags = gg.TYPE_QWORD} end
    local vPtrs = gg.getValues(reads)
    local vehicles = {}
    for _, v in ipairs(vPtrs) do if v.value and v.value ~= 0 then vehicles[#vehicles + 1] = v.value end end
    local mReads = {}
    for _, vp in ipairs(vehicles) do mReads[#mReads + 1] = {address = vp + 0x120, flags = gg.TYPE_QWORD} end
    local mVals = gg.getValues(mReads)
    local active, caReads = {}, {}
    for k, vp in ipairs(vehicles) do
        local mPtr = mVals[k] and mVals[k].value
        if mPtr and mPtr ~= 0 then
            active[#active + 1] = {vehiclePtr = vp, masteryPtr = mPtr}
            for j = 0, 3 do caReads[#caReads + 1] = {address = mPtr + j * 8, flags = gg.TYPE_QWORD} end
        end
    end
    local caVals = gg.getValues(caReads)
    local writes = {}; local successCount = 0
    for a = 1, #active do
        local entry = active[a]; local base = (a - 1) * 4
        for j = 1, 4 do
            local p = caVals[base + j]
            if p and p.value and p.value ~= 0 then
                writes[#writes + 1] = {address = p.value + 0x18, flags = gg.TYPE_DWORD, value = 65793}
                writes[#writes + 1] = {address = p.value + 0x1C, flags = gg.TYPE_DWORD, value = ts}
            end
        end
        writes[#writes + 1] = {address = entry.vehiclePtr + 0x120, flags = gg.TYPE_QWORD, value = entry.masteryPtr}
        writes[#writes + 1] = {address = entry.vehiclePtr + 0x128, flags = gg.TYPE_DWORD, value = 4}
        writes[#writes + 1] = {address = entry.vehiclePtr + 0x12C, flags = gg.TYPE_DWORD, value = 4}
        writes[#writes + 1] = {address = entry.vehiclePtr + 0x130, flags = gg.TYPE_DWORD, value = 4}
        successCount = successCount + 1
    end
    if #writes > 0 then gg.setValues(writes); gg.alert("✅ Đã max " .. successCount .. " masteries!")
    else gg.alert("❌ Không có gì để max!") end
end

local function MaxParts()
    if not checkGameStatus() then return end
    gg.alert("⚠️ Dùng Max Vehicles TRƯỚC!")
    local vehicleListPtr = gg.getValues({{address = BaseGameStatus + 0xB8, flags = gg.TYPE_QWORD}})[1].value
    local totalVehicles = gg.getValues({{address = BaseGameStatus + 0xC0, flags = gg.TYPE_DWORD}})[1].value
    if not vehicleListPtr or vehicleListPtr == 0 then gg.alert("❌ Không đọc được vehicle list!"); return end
    local reads = {}
    for i = 0, totalVehicles - 1 do reads[#reads + 1] = {address = vehicleListPtr + i * 8, flags = gg.TYPE_QWORD} end
    local vPtrs = gg.getValues(reads)
    local vehicles = {}
    for _, v in ipairs(vPtrs) do if v.value and v.value ~= 0 then vehicles[#vehicles + 1] = v.value end end
    local meta = {}
    for _, vp in ipairs(vehicles) do
        meta[#meta + 1] = {address = vp + 0x58, flags = gg.TYPE_QWORD}
        meta[#meta + 1] = {address = vp + 0x60, flags = gg.TYPE_DWORD}
    end
    local metaVals = gg.getValues(meta)
    local upgradeList = {}
    for k, vp in ipairs(vehicles) do
        local partsListPtr = metaVals[(k - 1) * 2 + 1] and metaVals[(k - 1) * 2 + 1].value
        local totalParts = metaVals[(k - 1) * 2 + 2] and metaVals[(k - 1) * 2 + 2].value
        if partsListPtr and partsListPtr ~= 0 and totalParts and totalParts > 0 then
            local pReads = {}
            for j = 0, totalParts - 1 do pReads[#pReads + 1] = {address = partsListPtr + j * 8, flags = gg.TYPE_QWORD} end
            local partPtrs = gg.getValues(pReads)
            for _, pp in ipairs(partPtrs) do
                local partPtr = pp.value
                if partPtr and partPtr ~= 0 then
                    local namePtr = gg.getValues({{address = partPtr + 0x18, flags = gg.TYPE_QWORD}})[1].value
                    local partName = "unknown"
                    if namePtr and namePtr ~= 0 then
                        local header = gg.getValues({{address = namePtr, flags = gg.TYPE_DWORD}})[1].value
                        if header == 49 then
                            local namePtr2 = gg.getValues({{address = namePtr + 0x10, flags = gg.TYPE_QWORD}})[1].value
                            partName = namePtr2 ~= 0 and readStringAt(namePtr2) or "unknown"
                        else partName = readStringAt(namePtr + 1) end
                    end
                    local lvl = partMaxLevel(partName)
                    upgradeList[#upgradeList + 1] = {address = partPtr + 0x20, flags = gg.TYPE_DWORD, value = lvl}
                    upgradeList[#upgradeList + 1] = {address = partPtr + 0x34, flags = gg.TYPE_DWORD, value = lvl}
                end
            end
        end
    end
    if #upgradeList > 0 then
        gg.setValues(upgradeList)
        gg.alert("✅ Đã max " .. math.floor(#upgradeList / 2) .. " parts!")
    else gg.alert("❌ Không có parts để max!") end
end

-- ═══════════════════════════════════════════════════════════════
--  FUEL & COINS & UNLIMITED IN-GAME FUEL
-- ═══════════════════════════════════════════════════════════════
local FandResults, FandFound = {}, false
local function ApplyFand(val)
    if not FandFound then
        gg.clearResults(); gg.setRanges(RANGE_VALUE)
        gg.searchNumber("-1082130432~-1054867456;1~1500F;1~5;1~1500F::21", gg.TYPE_DWORD)
        gg.refineNumber("1~1500", gg.TYPE_FLOAT)
        local c = gg.getResultsCount()
        if c == 0 then gg.alert("❌ Không tìm thấy!"); return end
        FandResults = gg.getResults(c); FandFound = true
    end
    local nv = {}
    for i, r in ipairs(FandResults) do
        nv[i] = {address = r.address, flags = gg.TYPE_FLOAT, value = val}
    end
    gg.setValues(nv); gg.alert("✅ Đã áp dụng: " .. tostring(val))
end
local function SetFuelCoins()
    local presets = {
        [1]         = "⚡ Default Radius",
        [10]        = "⚡ Short Radius (10m)",
        [500]       = "⚡ Big Radius (500m)",
        [100000000] = "⚡ Remove Fuel & Coins"
    }
    local keys = {}
    for k in pairs(presets) do keys[#keys+1] = k end
    table.sort(keys)
    local labels = {}
    for _, k in ipairs(keys) do labels[#labels+1] = presets[k] end
    labels[#labels+1] = "✏️ Custom Radius"
    labels[#labels+1] = "⬅️ Quay lại"
    local choice = gg.choice(labels, nil, nil)
    if choice == nil or choice == #labels then return end
    if choice == #labels - 1 then
        local inp = gg.prompt({"Radius (m):"}, {67}, {"number"})
        if not inp then return SetFuelCoins() end
        ApplyFand(tonumber(inp[1]))
        return SetFuelCoins()
    end
    ApplyFand(keys[choice])
    return SetFuelCoins()
end

-- Tích hợp Vô hạn nhiên liệu (In-game)
function UnlimitedInGameFueladdress()
    gg.clearResults()
    gg.setRanges(RANGE_VALUE)
    gg.searchNumber("h 12 50 6C 61 79 65 72 43 61 72 00", 1)
    gg.refineNumber("18", 1)
    local results = gg.getResults(gg.getResultsCount())
    gg.clearResults()
    if #results == 0 then
        gg.alert("❗ Vui lòng vào màn chơi (in-game) trước khi bật!")
        return nil
    end
    local UnlimitedInGameFueladd = nil
    for i, pointer in ipairs(results) do
        if (pointer.address & 0xF) == 0x8 then
            UnlimitedInGameFueladd = pointer.address - 0xC0
            break
        end
    end
    if not UnlimitedInGameFueladd then
        gg.alert("❌ Không tìm thấy địa chỉ mục tiêu trong trận đấu!")
        return nil
    end
    return UnlimitedInGameFueladd
end

function UnlimitedInGameFuel()
    gg.clearList()
    gg.clearResults()
    local fuelAdd = UnlimitedInGameFueladdress()
    if not fuelAdd then
        return
    end
    local input = gg.prompt({"Nhập giá trị khóa nhiên liệu:"}, {100}, {"text"})
    if not input then
        return
    else
        local fuelAdd1 = gg.getValues({{address = fuelAdd, flags = 32}})[1].value
        local fuelAdd2 = gg.getValues({{address = fuelAdd1 + 0x10, flags = 32}})[1].value
        gg.addListItems({{
            address = fuelAdd2,
            flags = 16,
            freeze = true,
            value = input[1]
        }})
        gg.toast("✅ Đã bật vô hạn nhiên liệu: " .. input[1])
    end
end

-- ═══════════════════════════════════════════════════════════════
--  MASTERY & CUPS
-- ═══════════════════════════════════════════════════════════════
local timeCupsResults = nil
local timeCupsActive  = false
local function RemoveMasteryTime()
    local input = gg.prompt(
        {"Enter exact Vehicle Name (case-sensitive)\nExamples:\nHILL CLIMBER, SCOOTER, BUS, HILL CLIMBER Mk2, TRACTOR,\nMOTOCROSS, DUNE BUGGY, SPORTS CAR, MONSTER TRUCK, PICKUP TRUCK,\nCHOPPER, MINI TANK, LOWRIDER, SNOWMOBILE, MONOWHEEL, BEAST,\nRALLY CAR, FORMULA, MUSCLE CAR, RACING TRUCK, HOT ROD,\nELECTRIC CAR, SUPERBIKE, LAMBORGHINI, MOONLANDER, ROCK BOUNCER,\nHOVERBIKE, RAIDER, GLIDER, TRUSTY, ATV, SUPER OFFROAD, STOCK CAR"},
        {""}, {"text"})
    if not input or not input[1] or input[1] == "" then return end
    local name = input[1]
    gg.clearResults(); gg.setRanges(RANGE_VALUE)
    gg.searchNumber(":" .. name, gg.TYPE_BYTE)
    local allResults = gg.getResults(gg.getResultsCount())
    if #allResults == 0 then gg.alert("❌ No results for: " .. name .. "\nCheck exact capitalization."); return end
    local targetAddresses = {}
    for _, res in ipairs(allResults) do
        table.insert(targetAddresses, { address = res.address + 0xEF, flags = gg.TYPE_DWORD })
    end
    gg.loadResults(targetAddresses)
    gg.refineNumber("1~5", gg.TYPE_DWORD)
    local unlocked = gg.getResults(gg.getResultsCount())
    if #unlocked == 0 then gg.alert("❌ No mastery data found for this vehicle."); return end
    local patch = {}
    for _, r in ipairs(unlocked) do
        table.insert(patch, {address = r.address + 0x150, flags = gg.TYPE_DWORD, value = 1064972046})
        table.insert(patch, {address = r.address + 0x154, flags = gg.TYPE_DWORD, value = 760095363})
        table.insert(patch, {address = r.address + 0x158, flags = gg.TYPE_DWORD, value = -98777962})
        table.insert(patch, {address = r.address + 0x15C, flags = gg.TYPE_DWORD, value = 1263588797})
    end
    gg.setValues(patch); gg.clearResults()
    gg.alert("✅ Mastery time removed for: " .. name .. "\n\nTap the Mastery logo multiple times to complete!")
end
local function SetCupsCountdown()
    local input = gg.prompt({"Set Cups Countdown (seconds)\nAllowed: 0 – 10"}, {"3"}, {"number"})
    if not input then return end
    local val = tonumber(input[1])
    if not val or val < 0 or val > 10 then
        gg.alert("❌ Invalid input! Enter a number between 0 and 10.")
        return SetCupsCountdown()
    end
    if not timeCupsActive or not timeCupsResults then
        gg.clearResults(); gg.setRanges(gg.REGION_C_BSS)
        gg.searchNumber("3", gg.TYPE_FLOAT)
        local count = gg.getResultsCount()
        if count == 0 then gg.alert("❌ No results found in C_BSS."); gg.setRanges(RANGE_VALUE); return end
        timeCupsResults = gg.getResults(count); timeCupsActive  = true
    end
    local newValues = {}
    for i, res in ipairs(timeCupsResults) do
        newValues[i] = { address = res.address, flags = gg.TYPE_FLOAT, value = val }
    end
    gg.setValues(newValues); gg.setRanges(RANGE_VALUE)
    gg.alert("✅ Cups Countdown set to " .. val .. " seconds")
end
local function MasteryCupsMenu()
    while true do
        local c = gg.choice({
            "⏲️ Remove Mastery Time",
            "⏱️ Set Countdown for Cups",
            "⬅️ Quay lại",
        }, nil, "🕹️ Mastery & Cups")
        if not c or c == 3 then return MainMenu() end
        if c == 1 then RemoveMasteryTime()
        elseif c == 2 then SetCupsCountdown() end
    end
end

-- ═══════════════════════════════════════════════════════════════
--  EVENT MENU
-- ═══════════════════════════════════════════════════════════════
local function EventMenu()
    if not checkGameStatus() then return end
    local choice = gg.choice({
        "🛒 Free Purchases (Event)",
        "💎 Add Currency (Coins/Gems)",
        "⬅️ Quay lại"
    }, nil, "🎉 Làm việc trong Event tab của game")
    if not choice or choice == 3 then return end
    if choice == 1 then
        gg.clearResults(); gg.setRanges(gg.REGION_C_ALLOC)
        gg.searchNumber("60;600;150", gg.TYPE_FLOAT)
        if gg.getResultsCount() == 0 then gg.alert("❌"); return end
        gg.editAll(0, gg.TYPE_FLOAT); gg.clearResults()
        gg.alert("✅ Đã bật!\nThoát Event tab rồi vào lại.")
    elseif choice == 2 then
        local cur = gg.prompt({"Chọn (1=Coins, 2=Gems):","Số lượng:"}, {1, 50000}, {"number","number"})
        if not cur then return end
        local ctype = tonumber(cur[1]) or 1
        local amount = tonumber(cur[2]) or 50000
        local addr = BaseGameStatus + 0x4F4
        if ctype == 2 then addr = BaseGameStatus + 0x4F8 end
        gg.setValues({{address = addr, flags = gg.TYPE_DWORD, value = amount}})
        gg.alert("✅ Đã set currency " .. ctype .. " = " .. amount)
    end
end

-- ═══════════════════════════════════════════════════════════════
--  TEAM EVENT
-- ═══════════════════════════════════════════════════════════════
local TE_apiUrl = "https://api.github.com/repos/anhdepzai360/HILL-CLIMB-RACING-2/contents/Gamestartvehicle.lua"
local TE = {
    VerifyRetryCount=0x11F, VerifyMatchmakingReq=0x123, VerifyUnknown3=0x127,
    StartServerTimestamp=0x12B, StartClientTimestamp=0x12F, EndEventTimestamp=0x133,
    VerifyTeamTicketJoin=0x13F, VerifyTicketRefillBase=0x147, VerifyUnknown6=0x14B,
    VerifyRetryLimit=0x14F, VerifyRetryDisableFlag=0x153,
    VerifyTeamDurationStart=0x1FB, VerifyTeamDurationEnd=0x1FF,
    EditMatchmakingReq=0x123, EditTeamTicketJoin=0x13F, EditTicketRefill=0x147,
    EditRetryDisable=0x157, EditTeamDurationStart=0x1FB, EditTeamDurationEnd=0x1FF,
    SetVehicleLimit1=0x437, SetVehicleLimit2=0x43F, SetVehicleLimit3=0x447,
    AllowVehicleList1=0x44F, AllowVehicleList2=0x457, AllowVehicleList3=0x45F,
    AnalyzeGameMode=0x4DF,
    EventScoreCheck1=0x1B0, EventScoreCheck2=0x1C8, EventScoreCheck3=0x1E0,
}
local TE_VerifyPatterns = {
    {offset=TE.VerifyRetryCount, expected=10},{offset=TE.VerifyMatchmakingReq, expected=5},
    {offset=TE.VerifyUnknown3, expected=3},{offset=TE.VerifyTeamTicketJoin, expected=1},
    {offset=TE.VerifyTicketRefillBase, expected=14400},{offset=TE.VerifyUnknown6, expected=2},
    {offset=TE.VerifyRetryLimit, expected=50},{offset=TE.VerifyRetryDisableFlag, expected=1},
    {offset=TE.VerifyTeamDurationStart, expected=172800},{offset=TE.VerifyTeamDurationEnd, expected=172800},
}
local TE_History = {}
local TE_DurationInput = nil
local TE_VehicleCache = { base = nil, limitBase = nil, timestamp = 0 }

local function TE_readOne(addr, flags)
    if not addr or type(addr) ~= "number" then return nil end
    local v = gg.getValues({{address = addr, flags = flags}})
    return (v and v[1]) and v[1].value or nil
end
local function TE_safeAddr(addr)
    if not addr or type(addr) ~= "number" or addr == 0 then return nil end
    return addr
end
local function TE_safeRead(addr, flags)
    addr = TE_safeAddr(addr)
    if not addr then return nil end
    return TE_readOne(addr, flags)
end
local function TE_safeAdd(a, b)
    if not a or not b or type(a) ~= "number" or type(b) ~= "number" then return nil end
    return a + b
end
local function TE_verifyBase(base, editedValues)
    for _, pat in ipairs(TE_VerifyPatterns) do
        local cur = TE_readOne(base + pat.offset, gg.TYPE_DWORD)
        if cur == nil then return false end
        if cur ~= pat.expected then
            if not (editedValues and editedValues[pat.offset] ~= nil and cur == editedValues[pat.offset]) then
                return false
            end
        end
    end
    return true
end
local function TE_ensureVehicleList()
    if type(GameStatusVehicles) == "table" and type(GameStatusVehicles[1]) == "table" and type(GameStatusVehicles[2]) == "table" then
        return true
    end
    gg.toast("Đang tải danh sách xe Team Event...")
    local ok, res = pcall(function() return gg.makeRequest(TE_apiUrl) end)
    if ok and res and res.code == 200 and res.content then
        local block = res.content:match("(GameStatusVehicles%s*=%s*%b{})")
        if block then
            local fn = load(block)
            if fn and pcall(fn) and type(GameStatusVehicles) == "table" then
                gg.toast("✅ Đã tải GameStatusVehicles")
                return true
            end
        end
    end
    gg.alert("❌ Không tải được danh sách xe (GameStatusVehicles)!")
    return false
end
local function TE_getServerTime()
    local sources = {
        { url = "https://timeapi.io/api/Time/current/zone?timeZone=UTC",
          pattern = '"secondsSinceEpoch"%s*:%s*(%d+)' },
        { url = "https://worldtimeapi.org/api/timezone/Etc/UTC",
          pattern = '"unixtime"%s*:%s*(%d+)' },
        { url = "https://currentmillis.com/time/minutes-since-unix-epoch.php",
          pattern = '(%d+)', multiplier = 60 },
    }
    for _, src in ipairs(sources) do
        local ok, res = pcall(function() return gg.makeRequest(src.url) end)
        if ok and res and res.code == 200 and res.content then
            local raw = res.content:match(src.pattern)
            if raw then
                local ts = tonumber(raw)
                if ts then return ts * (src.multiplier or 1) end
            end
        end
    end
    return os.time()
end
local function TE_fmtCountdown(secs)
    secs = math.abs(math.floor(secs))
    local d = math.floor(secs / 86400)
    local h = math.floor((secs % 86400) / 3600)
    local m = math.floor((secs % 3600) / 60)
    local s = secs % 60
    if d > 0 then return string.format("%dd %02dh %02dm %02ds", d, h, m, s) end
    if h > 0 then return string.format("%02dh %02dm %02ds", h, m, s) end
    return string.format("%02dm %02ds", m, s)
end
local function TE_localFmt(ts)
    if not ts or ts == 0 then return "⚫ Not Set" end
    return os.date("%Y-%m-%d  %I:%M:%S %p", ts) .. "  (" .. os.date("%Z") .. ")"
end
local function TE_fmtStatus(ts, now, isEnd)
    if not ts or ts == 0 then return "⚫ Not Set" end
    local diff = ts - now
    if isEnd then
        if diff > 0 then return "⌛ Ends in  " .. TE_fmtCountdown(diff) end
        return "⛔ Already Ended"
    else
        if diff > 0 then return "⏳ Starts Later  →  " .. TE_fmtCountdown(diff) end
        if diff == 0 then return "🔴 Starting Now" end
        return "✅ Started  " .. TE_fmtCountdown(-diff) .. " ago"
    end
end
local function TE_promptTimestampValue(base, readOffset, now, isEnd)
    local cur = TE_readOne(base + readOffset, gg.TYPE_DWORD) or 0
    local t   = os.date("*t", cur > 0 and cur or now)
    local h12 = t.hour % 12
    if h12 == 0 then h12 = 12 end
    local isPM = os.date("*t", now).hour >= 12
    local inp = gg.prompt(
        {
            "Unix Value (0 = remove)",
            "Day [1;31]",
            "Month [1;12]",
            "Year [2020;2030]",
            "Hour [1;12]",
            "Min [1;59]",
            "Sec [1;59]",
            "☑ Check if you want PM",
        },
        {
            tostring(cur),
            tostring(t.day),
            tostring(t.month),
            tostring(t.year),
            tostring(h12),
            tostring(t.min),
            tostring(t.sec),
            isPM,
        },
        {
            "number",
            "number","number","number",
            "number","number","number",
            "checkbox",
        }
    )
    if not inp then gg.toast("Cancelled"); return nil end
    local newTs
    local rawIn = tonumber(inp[1])
    if rawIn ~= nil and rawIn ~= cur then
        newTs = math.floor(rawIn)
    else
        local d   = tonumber(inp[2])
        local mo  = tonumber(inp[3])
        local y   = tonumber(inp[4])
        local h   = tonumber(inp[5])
        local mi  = tonumber(inp[6])
        local se  = tonumber(inp[7])
        local isPM2 = inp[8] or false
        if not (d and mo and y and h and mi and se) then
            gg.toast("⚠️ Invalid input"); return nil
        end
        local h24 = h % 12
        if isPM2 then h24 = h24 + 12 end
        newTs = os.time({ year=y, month=mo, day=d, hour=h24, min=mi, sec=se })
    end
    if newTs == nil or newTs == cur then gg.toast("⚠️ No change"); return nil end
    if newTs == 0 then
        local c = gg.prompt({"⚠️ Set to 0?"}, {false}, {"checkbox"})
        if not c or not c[1] then gg.toast("Cancelled"); return nil end
    end
    if newTs > 0 then
        local diff = newTs - now
        if diff > 0 then
            if isEnd then
                gg.toast("⌛ Event will end in " .. TE_fmtCountdown(diff))
            else
                gg.toast("⏳ Will start later →  " .. TE_fmtCountdown(diff))
            end
        end
    end
    return newTs
end
local function TE_editTimestampBlock(base, offset, label, now, isEnd)
    local newTs = TE_promptTimestampValue(base, offset, now, isEnd)
    if newTs == nil then return end
    local ok = pcall(function()
        gg.setValues({{ address = base + offset, flags = gg.TYPE_DWORD, value = newTs }})
    end)
    gg.toast(ok and "✅ Set" or "❌ Write failed")
end
local function TE_editTimestampDual(base, offsets, label, now, isEnd)
    local newTs = TE_promptTimestampValue(base, offsets[1], now, isEnd)
    if newTs == nil then return end
    local batch = {}
    for _, off in ipairs(offsets) do
        table.insert(batch, { address = base + off, flags = gg.TYPE_DWORD, value = newTs })
    end
    local ok = pcall(function() gg.setValues(batch) end)
    gg.toast(ok and "✅ Set" or "❌ Write failed")
end
local function TE_showTimestampEditor(base)
    gg.toast("Fetching server time...")
    local now    = TE_getServerTime()
    local sStart = TE_readOne(base + TE.StartServerTimestamp, gg.TYPE_DWORD) or 0
    local eEnd   = TE_readOne(base + TE.EndEventTimestamp, gg.TYPE_DWORD) or 0
    local menu = gg.prompt(
        {
            "🌐Current Time Now: " .. TE_localFmt(now) .. "\n🟢 Start: " .. TE_localFmt(sStart) .. "\n" .. TE_fmtStatus(sStart, now, false),
            "🔴 End: " .. TE_localFmt(eEnd) .. "\n" .. TE_fmtStatus(eEnd, now, true),
            "⚫ Remove All 3 Timestamps",
        },
        { false, false, false },
        { "checkbox", "checkbox", "checkbox" }
    )
    if not menu then return end
    if menu[3] then
        local c = gg.prompt({ "⚠️ Remove event from game event list?\nAll 3 timestamps → 0" }, { false }, { "checkbox" })
        if c and c[1] then
            pcall(function()
                gg.setValues({
                    { address = base + TE.StartServerTimestamp, flags = gg.TYPE_DWORD, value = 0 },
                    { address = base + TE.StartClientTimestamp, flags = gg.TYPE_DWORD, value = 0 },
                    { address = base + TE.EndEventTimestamp, flags = gg.TYPE_DWORD, value = 0 },
                })
            end)
            gg.toast("⚫ Event removed from list")
        end
        return
    end
    if menu[1] then
        TE_editTimestampDual(base, { TE.StartServerTimestamp, TE.StartClientTimestamp }, "Start Time", now, false)
    end
    if menu[2] then
        TE_editTimestampBlock(base, TE.EndEventTimestamp, "End Time", now, true)
    end
end
local function TE_runJudge0(sourceCode, label)
    local function jsonEscape(str)
        return str:gsub("\\", "\\\\"):gsub("\n", "\\n"):gsub("\"", "\\\"")
    end
    local body = string.format('{"language_id":64,"source_code":"%s"}', jsonEscape(sourceCode))
    local headers = { ["Content-Type"] = "application/json", ["Accept"] = "application/json" }
    local res = gg.makeRequest("https://ce.judge0.com/submissions?wait=true", headers, body, "POST")
    if res and (res.code == 201 or res.code == 200) then
        local stdout = res.content:match('"stdout"%s*:%s*"([^"]*)"')
        stdout = stdout and stdout:gsub("\\n", "\n") or res.content
        return stdout:gsub("%z", "")
    end
    return nil, "Error or no response for " .. tostring(label)
end
local function TE_searchEvent()
    local input = gg.prompt({"Tên Event (VD: :Hooked on a Wheelin'):"}, {""}, {"text"})
    if not input or input[1] == "" then gg.toast("⚠️ Trống!"); return end
    local label = input[1]; local len = #label
    local word = label:match("^(%S+)") or label
    local firstChar = label:sub(1, 1)
    gg.clearResults(); gg.setVisible(false); gg.setRanges(RANGE_VALUE)
    gg.searchNumber(":" .. label, gg.TYPE_BYTE)
    gg.refineNumber(":" .. word, gg.TYPE_BYTE)
    gg.refineNumber(":" .. firstChar, gg.TYPE_BYTE)
    local cnt = gg.getResultsCount()
    local refineResults = gg.getResults(cnt)
    TE_History[label] = TE_History[label] or {results={}, verified={}, is_enabled=false}
    local added = 0
    if cnt == 0 then gg.toast("❌ Không tìm thấy!"); return end
    if len <= 23 then
        for _, r in ipairs(refineResults) do
            if not TE_History[label].verified[r.address] then
                if TE_verifyBase(r.address, nil) then
                    TE_History[label].verified[r.address] = true
                    TE_History[label].results[#TE_History[label].results+1] = r
                    added = added + 1
                end
            end
        end
        gg.clearResults(); gg.toast("✅ Added " .. added .. " cho: " .. label); return
    end
    for _, rr in ipairs(refineResults) do
        local stringAddress = rr.address
        gg.clearResults(); gg.setRanges(RANGE_VALUE)
        gg.searchNumber(stringAddress, gg.TYPE_QWORD)
        local pCount = gg.getResultsCount()
        if pCount > 0 then
            for _, p in ipairs(gg.getResults(pCount)) do
                local base = p.address - 0xF
                local checkAddr = p.address - 0x10
                local v = gg.getValues({{address = checkAddr, flags = gg.TYPE_DWORD}})
                if v and v[1] and v[1].value >= 0 and v[1].value <= 100 then
                    if not TE_History[label].verified[base] then
                        if TE_verifyBase(base, nil) then
                            TE_History[label].verified[base] = true
                            TE_History[label].results[#TE_History[label].results+1] = {address = base}
                            added = added + 1
                        end
                    end
                end
            end
        end
    end
    gg.toast("✅ Pointer-verified " .. added .. " cho: " .. label)
    gg.clearResults()
end
local function TE_applyEdits(base, selectedEdits, storeOriginal)
    local batch, originals = {}, {}
    for _, idx in ipairs(selectedEdits) do
        if idx == 6 then
            TE_showTimestampEditor(base)
        elseif idx == 1 then
            if storeOriginal then
                local o = TE_readOne(base + TE.EditMatchmakingReq, gg.TYPE_DWORD)
                if o then originals[#originals+1] = {address=base+TE.EditMatchmakingReq, flags=gg.TYPE_DWORD, value=o} end
            end
            batch[#batch+1] = {address=base+TE.EditMatchmakingReq, flags=gg.TYPE_DWORD, value=1}
        elseif idx == 2 then
            if storeOriginal then
                local o = TE_readOne(base + TE.EditTeamTicketJoin, gg.TYPE_DWORD)
                if o then originals[#originals+1] = {address=base+TE.EditTeamTicketJoin, flags=gg.TYPE_DWORD, value=o} end
            end
            batch[#batch+1] = {address=base+TE.EditTeamTicketJoin, flags=gg.TYPE_DWORD, value=0}
        elseif idx == 3 then
            local orig = TE_readOne(base + TE.EditTicketRefill, gg.TYPE_DWORD)
            if orig then
                gg.setValues({{address=base+TE.EditTicketRefill, flags=gg.TYPE_DWORD, value=0}})
                gg.sleep(300)
                gg.setValues({{address=base+TE.EditTicketRefill, flags=gg.TYPE_DWORD, value=orig}})
            end
        elseif idx == 4 then
            if storeOriginal then
                local o = TE_readOne(base + TE.EditRetryDisable, gg.TYPE_DWORD)
                if o then originals[#originals+1] = {address=base+TE.EditRetryDisable, flags=gg.TYPE_DWORD, value=o} end
            end
            batch[#batch+1] = {address=base+TE.EditRetryDisable, flags=gg.TYPE_DWORD, value=-1}
        elseif idx == 5 then
            if not TE_DurationInput then
                local ui = gg.prompt({"Duration (HOURS) [1;48]:"}, {"1"}, {"number"})
                if not ui then return false end
                TE_DurationInput = tonumber(ui[1]) or 1
            end
            local fv = 3600 * TE_DurationInput
            for _, off in ipairs({TE.EditTeamDurationStart, TE.EditTeamDurationEnd}) do
                if storeOriginal then
                    local o = TE_readOne(base + off, gg.TYPE_DWORD)
                    if o then originals[#originals+1] = {address=base+off, flags=gg.TYPE_DWORD, value=o} end
                end
                batch[#batch+1] = {address=base+off, flags=gg.TYPE_DWORD, value=fv}
            end
        end
    end
    if #batch > 0 then if not pcall(function() gg.setValues(batch) end) then return false end end
    return true, originals
end
local function TE_enableEvent()
    if not next(TE_History) then gg.toast("⚠️ Chưa search event!"); return end
    local labels = {}
    for label, _ in pairs(TE_History) do labels[#labels+1] = label end
    local eventPrompt = gg.prompt(labels, {}, (function()
        local t = {}; for _ = 1, #labels do t[#t+1] = "checkbox" end; return t
    end)())
    if not eventPrompt then return end
    local editNames = {
        "Matchmaking (1 player)","Team ticket unlimited","Refill Tickets [T-E]",
        "Retry Disable","Duration [Leaders]","Timestamp Editor"
    }
    local editPrompt = gg.prompt(editNames, {}, {"checkbox","checkbox","checkbox","checkbox","checkbox","checkbox"})
    if not editPrompt then return end
    local sel = {}
    for k, v in pairs(editPrompt) do if v then sel[#sel+1] = k end end
    if #sel == 0 then gg.toast("⚠️ Không chọn edits!"); return end
    local editedTable = {}
    for _, idx in ipairs(sel) do
        if idx == 1 then editedTable[TE.EditMatchmakingReq] = 1
        elseif idx == 2 then editedTable[TE.EditTeamTicketJoin] = 0
        elseif idx == 4 then editedTable[TE.EditRetryDisable] = -1
        elseif idx == 5 then
            local fv = 3600 * (TE_DurationInput or 1)
            editedTable[TE.EditTeamDurationStart] = fv
            editedTable[TE.EditTeamDurationEnd] = fv
        end
    end
    for i, isSelected in ipairs(eventPrompt) do
        if isSelected then
            local label = labels[i]; local hist = TE_History[label]; local cnt = 0
            hist.originalValues = hist.originalValues or {}
            for _, r in ipairs(hist.results) do
                local ok, origs = TE_applyEdits(r.address, sel, true)
                if ok and TE_verifyBase(r.address, editedTable) then
                    cnt = cnt + 1
                    if not hist.originalValues[r.address] then hist.originalValues[r.address] = origs end
                end
            end
            hist.is_enabled = cnt > 0
            gg.toast(string.format("✅ Enabled %d/%d cho \"%s\"", cnt, #hist.results, label))
        end
    end
    gg.clearResults(); gg.clearList()
end
local function TE_disableEvent()
    if not next(TE_History) then gg.toast("⚠️ Chưa search event!"); return end
    local labels = {}
    for label, entry in pairs(TE_History) do if entry.is_enabled then labels[#labels+1] = label end end
    if #labels == 0 then gg.toast("❌ Không có event nào bật!"); return end
    local sel = gg.prompt(labels, {}, (function()
        local t = {}; for _ = 1, #labels do t[#t+1] = "checkbox" end; return t
    end)())
    if not sel then return end
    for i, isSelected in ipairs(sel) do
        if isSelected then
            local label = labels[i]; local hist = TE_History[label]
            if hist.originalValues then
                for _, vals in pairs(hist.originalValues) do
                    if vals and #vals > 0 then pcall(function() gg.setValues(vals) end) end
                end
                hist.originalValues = nil
            else
                for _, r in ipairs(hist.results) do
                    gg.setValues({
                        {address=r.address+TE.EditMatchmakingReq, flags=gg.TYPE_DWORD, value=5},
                        {address=r.address+TE.EditTeamTicketJoin, flags=gg.TYPE_DWORD, value=1},
                        {address=r.address+TE.EditRetryDisable, flags=gg.TYPE_DWORD, value=1},
                        {address=r.address+TE.EditTeamDurationStart, flags=gg.TYPE_DWORD, value=172800},
                        {address=r.address+TE.EditTeamDurationEnd, flags=gg.TYPE_DWORD, value=172800},
                    })
                end
            end
            if hist.vehicleOriginals then
                for _, vals in pairs(hist.vehicleOriginals) do
                    if vals and #vals > 0 then pcall(function() gg.setValues(vals) end) end
                end
                hist.vehicleOriginals = nil
            end
            hist.is_enabled = false
            gg.toast("⚠️ Disabled " .. label)
        end
    end
end
local function TE_showLogs()
    if not next(TE_History) then gg.alert("⚠️ Chưa có history!"); return end
    local lines = {}
    for label, h in pairs(TE_History) do
        lines[#lines+1] = string.format("%s: %d entry [%s]", label, #h.results, h.is_enabled and "✅" or "❌")
    end
    gg.alert(table.concat(lines, "\n"))
end
local function TE_allowVehiclesInExisting()
    if not next(TE_History) then gg.toast("⚠️ Chưa search event!"); return end
    if not TE_ensureVehicleList() then return end
    local labels = {}; for label, _ in pairs(TE_History) do labels[#labels+1] = label end
    local pTypes = {}; for _ in ipairs(labels) do table.insert(pTypes, "checkbox") end
    local eventPrompt = gg.prompt(labels, {}, pTypes)
    if not eventPrompt then return end
    local vehicleNames, vehicleData = GameStatusVehicles[1], GameStatusVehicles[2]
    local vTypes = {}; for _ in ipairs(vehicleNames) do table.insert(vTypes, "checkbox") end
    local selected = gg.prompt(vehicleNames, {}, vTypes)
    if not selected then return end
    local chosen = {}
    for i, v in ipairs(selected) do
        if v then table.insert(chosen, {name = vehicleNames[i], data = vehicleData[i]}) end
    end
    if #chosen == 0 then return end
    for i, isSelected in ipairs(eventPrompt) do
        if isSelected then
            local hist = TE_History[labels[i]]
            hist.vehicleOriginals = hist.vehicleOriginals or {}
            for addr, _ in pairs(hist.verified) do
                local vStart = TE_readOne(addr + TE.AllowVehicleList1, gg.TYPE_QWORD)
                local vEnd   = TE_readOne(addr + TE.AllowVehicleList2, gg.TYPE_QWORD)
                if vStart and vEnd and vStart ~= 0 and vEnd > vStart then
                    local maxCapacity = math.floor((vEnd - vStart) / 0x18)
                    local infoMsg = string.format(
                        "Event: %s\nMax Slots: %d\nReplacing first %d vehicle(s).",
                        labels[i], maxCapacity, #chosen
                    )
                    if gg.alert(infoMsg, "OK", "CANCEL") ~= 1 then return end
                    local writeBatch, origBatch = {}, {}
                    local countToReplace = math.min(#chosen, maxCapacity)
                    for j = 1, countToReplace do
                        local offset = (j - 1) * 0x18
                        local idx = 0
                        for num in chosen[j].data:gmatch("([^;]+)") do
                            local targetAddr = vStart + offset + (idx * 4)
                            local curVal = TE_readOne(targetAddr, gg.TYPE_DWORD)
                            if curVal ~= nil then
                                table.insert(origBatch, {address = targetAddr, flags = gg.TYPE_DWORD, value = curVal})
                            end
                            table.insert(writeBatch, {
                                address = targetAddr,
                                flags = gg.TYPE_DWORD,
                                value = tonumber((num:gsub(",", ""))) or 0
                            })
                            idx = idx + 1
                        end
                    end
                    if #origBatch > 0 then table.insert(hist.vehicleOriginals, origBatch) end
                    gg.setValues(writeBatch)
                end
            end
            gg.toast("✅ Vehicle(s) replaced for: " .. labels[i])
        end
    end
end
local function TE_setVehicleLimit()
    if not next(TE_History) then gg.toast("⚠️ Chưa search event!"); return end
    local labels = {}
    for label, _ in pairs(TE_History) do labels[#labels+1] = label end
    local sel = gg.prompt(labels, {}, (function()
        local t = {}; for _ = 1, #labels do t[#t+1] = "checkbox" end; return t
    end)())
    if not sel then return end
    local inp = gg.prompt({"Limit:"}, {"1"}, {"number"})
    if not inp then return end
    local limitVal = tonumber(inp[1]) or 1
    for i, isSelected in ipairs(sel) do
        if isSelected then
            local hist = TE_History[labels[i]]
            for addr, _ in pairs(hist.verified) do
                local lStart = TE_readOne(addr + TE.SetVehicleLimit1, gg.TYPE_QWORD)
                local lEnd   = TE_readOne(addr + TE.SetVehicleLimit2, gg.TYPE_QWORD)
                if lStart and lEnd and lStart ~= 0 then
                    local count = math.floor((lEnd - lStart) / 4)
                    local batch = {}
                    for j = 0, count-1 do
                        batch[#batch+1] = {address=lStart + j*4, flags=gg.TYPE_DWORD, value=limitVal}
                    end
                    gg.setValues(batch)
                end
            end
            gg.toast("✅ Updated: " .. labels[i])
        end
    end
end
local function TE_verifyVehicleCache()
    if not TE_VehicleCache.base or not TE_VehicleCache.limitBase then return false end
    if TE_readOne(TE_VehicleCache.base, gg.TYPE_DWORD) == nil or TE_readOne(TE_VehicleCache.limitBase, gg.TYPE_DWORD) == nil then
        gg.toast("❌ Vehicle/Limit cache expired")
        TE_VehicleCache.base = nil
        TE_VehicleCache.limitBase = nil
        return false
    end
    return true
end
local function TE_searchVehicleMemory()
    gg.clearResults(); gg.setRanges(RANGE_VALUE)
    gg.searchNumber(string.rep("0;", 64) .. "::253", gg.TYPE_DWORD, false, gg.SIGN_EQUAL, 0, -1, 1000)
    if gg.getResultsCount() == 0 then gg.toast("❌ Vehicle memory not found"); return nil end
    local vehicleBase = gg.getResults(1)[1].address
    gg.clearResults(); gg.setRanges(gg.REGION_ANONYMOUS)
    gg.searchNumber(string.rep("0;", 64) .. "::253", gg.TYPE_DWORD, false, gg.SIGN_EQUAL, 0, -1, 50)
    if gg.getResultsCount() == 0 then gg.toast("❌ Limit memory not found"); return nil end
    local limitBase = gg.getResults(1)[1].address
    gg.clearResults(); gg.setRanges(RANGE_VALUE)
    TE_VehicleCache.base = vehicleBase
    TE_VehicleCache.limitBase = limitBase
    TE_VehicleCache.timestamp = os.time()
    gg.toast("✅ Vehicle memory cached")
    return { vehicleBase, limitBase }
end
local function TE_allowVehicleNewLists()
    if not next(TE_History) then gg.toast("⚠️ Search for Event first!"); return end
    if not TE_ensureVehicleList() then return end
    local labels = {}; for label, _ in pairs(TE_History) do labels[#labels+1] = label end
    local pTypes = {}; for _ in ipairs(labels) do table.insert(pTypes, "checkbox") end
    local eventPrompt = gg.prompt(labels, {}, pTypes)
    if not eventPrompt then return end
    local vehicleNames = GameStatusVehicles[1]
    local vTypes = {}; for _ in ipairs(vehicleNames) do table.insert(vTypes, "checkbox") end
    local selected = gg.prompt(vehicleNames, {}, vTypes)
    if not selected then return end
    local chosenVehicles = {}
    for i, sel in ipairs(selected) do
        if sel then table.insert(chosenVehicles, { name = vehicleNames[i], data = GameStatusVehicles[2][i] }) end
    end
    local chosenCount = #chosenVehicles
    if chosenCount == 0 then return end
    local limitInput = gg.prompt({"Enter Vehicle Limit:"}, {"20"}, {"number"})
    if not limitInput then return end
    local limitValue = tonumber(limitInput[1]) or 1
    local memoryAddrs = TE_verifyVehicleCache() and { TE_VehicleCache.base, TE_VehicleCache.limitBase } or TE_searchVehicleMemory()
    if not memoryAddrs then return end
    local vehicleBase, limitBase = memoryAddrs[1], memoryAddrs[2]
    local writeBatch = {}
    for i, v in ipairs(chosenVehicles) do
        local offset = (i - 1) * 0x18
        local idx = 0
        for num in v.data:gmatch("([^;]+)") do
            table.insert(writeBatch, {
                address = vehicleBase + offset + (idx * 4),
                flags = gg.TYPE_DWORD,
                value = tonumber((num:gsub(",", ""))) or 0
            })
            idx = idx + 1
        end
    end
    for i = 0, chosenCount - 1 do
        table.insert(writeBatch, { address = limitBase + (i * 4), flags = gg.TYPE_DWORD, value = limitValue })
    end
    local ok = pcall(function() gg.setValues(writeBatch) end)
    if not ok then
        gg.toast("❌ Write failed")
        TE_VehicleCache.base = nil
        return
    end
    local vehicleEnd = vehicleBase + (chosenCount * 0x18)
    local limitEnd = limitBase + (chosenCount * 4)
    for i, isSelected in ipairs(eventPrompt) do
        if isSelected then
            local hist = TE_History[labels[i]]
            hist.vehicleOriginals = hist.vehicleOriginals or {}
            for addr, _ in pairs(hist.verified) do
                local ptrOffsets = {
                    TE.AllowVehicleList1, TE.AllowVehicleList2, TE.AllowVehicleList3,
                    TE.SetVehicleLimit1, TE.SetVehicleLimit2, TE.SetVehicleLimit3
                }
                local origPtrs = {}
                for _, po in ipairs(ptrOffsets) do
                    local curP = TE_readOne(addr + po, gg.TYPE_QWORD)
                    if curP then table.insert(origPtrs, {address = addr + po, flags = gg.TYPE_QWORD, value = curP}) end
                end
                if #origPtrs > 0 then table.insert(hist.vehicleOriginals, origPtrs) end
                gg.setValues({
                    { address = addr + TE.AllowVehicleList1, flags = gg.TYPE_QWORD, value = vehicleBase },
                    { address = addr + TE.AllowVehicleList2, flags = gg.TYPE_QWORD, value = vehicleEnd },
                    { address = addr + TE.AllowVehicleList3, flags = gg.TYPE_QWORD, value = vehicleEnd },
                    { address = addr + TE.SetVehicleLimit1, flags = gg.TYPE_QWORD, value = limitBase },
                    { address = addr + TE.SetVehicleLimit2, flags = gg.TYPE_QWORD, value = limitEnd },
                    { address = addr + TE.SetVehicleLimit3, flags = gg.TYPE_QWORD, value = limitEnd }
                })
            end
            gg.toast("✅ New Lists Linked to: " .. labels[i])
        end
    end
    gg.clearResults()
end
local function TE_editGameModeValues(modeInfo)
    if not modeInfo or #modeInfo == 0 then gg.toast("⚠️ No mode info to edit"); return end
    local promptLabels, promptDefault, promptTypes, promptMap = {}, {}, {}, {}
    for idx, m in ipairs(modeInfo) do
        if m.mode == "Distance Mode" then
            table.insert(promptLabels, string.format("Mode %d | 🏁 Distance Value", m.jump))
            table.insert(promptDefault, tostring(m.t198)); table.insert(promptTypes, "number")
            table.insert(promptMap, {idx = idx, field = "t198"})
            table.insert(promptLabels, string.format("Mode %d | 🏆 Max Points", m.jump))
            table.insert(promptDefault, tostring(m.t1C8)); table.insert(promptTypes, "number")
            table.insert(promptMap, {idx = idx, field = "t1C8"})
        else
            table.insert(promptLabels, string.format("Mode %d | ⏱ Min Time", m.jump))
            table.insert(promptDefault, tostring(m.t198)); table.insert(promptTypes, "number")
            table.insert(promptMap, {idx = idx, field = "t198"})
            table.insert(promptLabels, string.format("Mode %d | ⏱ Max Time", m.jump))
            table.insert(promptDefault, tostring(m.t1B0)); table.insert(promptTypes, "number")
            table.insert(promptMap, {idx = idx, field = "t1B0"})
            table.insert(promptLabels, string.format("Mode %d | 🏆 Max Points", m.jump))
            table.insert(promptDefault, tostring(m.t1C8)); table.insert(promptTypes, "number")
            table.insert(promptMap, {idx = idx, field = "t1C8"})
        end
    end
    local userInput = gg.prompt(promptLabels, promptDefault, promptTypes)
    if not userInput then gg.toast("⚠️ Edit canceled"); return end
    local writeList, editedCount = {}, 0
    for pIdx, map in ipairs(promptMap) do
        local newVal = tonumber(userInput[pIdx])
        if newVal then
            local m = modeInfo[map.idx]
            local targetPtr = (map.field == "t198" and m.ptr198) or (map.field == "t1B0" and m.ptr1B0) or (map.field == "t1C8" and m.ptr1C8)
            if targetPtr then
                table.insert(writeList, { address = targetPtr, flags = gg.TYPE_FLOAT, value = newVal })
                editedCount = editedCount + 1
            end
        end
    end
    if #writeList == 0 then gg.toast("⚠️ Nothing to write"); return end
    local ok, err = pcall(function() gg.setValues(writeList) end)
    gg.toast(ok and string.format("✅ Edited %d values successfully!", editedCount) or ("❌ Write failed: " .. tostring(err)))
end
local function TE_analyzeGameMode()
    if not next(TE_History) then gg.toast("⚠️ Chưa search!"); return end
    local labels = {}
    for label, _ in pairs(TE_History) do labels[#labels+1] = label end
    local ch = gg.choice(labels, nil, "Event để phân tích:")
    if not ch then return end
    local label = labels[ch]; local hist = TE_History[label]
    if not hist or not hist.results or #hist.results == 0 then gg.toast("⚠️ No pointers"); return end
    local inp = gg.prompt({"Total Modes [1-5]:"}, {"1"}, {"number"})
    if not inp then return end
    local jumps = math.min(math.max(math.floor(tonumber(inp[1]) or 1), 1), 5)
    local jumpOffsets = {0, 0x8, 0x10, 0x18, 0x20}
    local modeInfo = {}
    for _, entry in ipairs(hist.results) do
        if type(entry) == "table" and type(entry.address) == "number" then
            local basePtrAddress = TE_safeAdd(entry.address, TE.AnalyzeGameMode)
            local basePtr = basePtrAddress and TE_safeRead(basePtrAddress, gg.TYPE_QWORD)
            if basePtr and basePtr ~= 0 then
                for i = 1, jumps do
                    local jumpPtrAddress = TE_safeAdd(basePtr, jumpOffsets[i])
                    local jumpPtr = jumpPtrAddress and TE_safeRead(jumpPtrAddress, gg.TYPE_QWORD)
                    if jumpPtr and jumpPtr ~= 0 then
                        local function readF(o)
                            local pAddr = TE_safeAdd(jumpPtr, o)
                            local p = pAddr and TE_safeRead(pAddr, gg.TYPE_QWORD)
                            if not p or p == 0 then return 0, nil end
                            return TE_safeRead(p, gg.TYPE_FLOAT) or 0, p
                        end
                        local v198, p198 = readF(TE.EventScoreCheck1)
                        local v1B0, p1B0 = readF(TE.EventScoreCheck2)
                        local v1C8, p1C8 = readF(TE.EventScoreCheck3)
                        v198, v1B0, v1C8 = tonumber(v198) or 0, tonumber(v1B0) or 0, tonumber(v1C8) or 0
                        if not (v198 == 0 and v1B0 == 0 and v1C8 == 0) then
                            modeInfo[#modeInfo+1] = {
                                jump=i, mode=(v1B0 == 0) and "Distance Mode" or "Time Attack Mode",
                                t198=v198, t1B0=v1B0, t1C8=v1C8,
                                ptr198=p198, ptr1B0=p1B0, ptr1C8=p1C8
                            }
                        end
                    end
                end
            end
        end
    end
    if #modeInfo == 0 then gg.toast("❌ Không có mode hợp lệ!"); return end
    hist.analysis = { modeInfo = modeInfo }
    local msg = "📌 Game Mode Analysis\nEvent: " .. label .. "\n\n"
    for _, m in ipairs(modeInfo) do
        msg = msg .. string.format("Mode %d (%s)\n", m.jump, m.mode)
        if m.mode == "Distance Mode" then
            msg = msg .. string.format("Distance → %.2f\nMax Points → %.2f\n\n", m.t198, m.t1C8)
        else
            msg = msg .. string.format("Min → %.2f\nMax → %.2f\nMax Points → %.2f\n\n", m.t198, m.t1B0, m.t1C8)
        end
    end
    gg.alert(msg)
    local editChoice = gg.alert("Chỉnh sửa giá trị chế độ chơi?", "✅ Edit Values", "❌ No")
    if editChoice == 1 then TE_editGameModeValues(modeInfo) end
end
local function TE_showEventScoreCalculation()
    if not next(TE_History) then gg.toast("⚠️ No history found"); return end
    local labels = {}
    for k in pairs(TE_History) do table.insert(labels, k) end
    local e = gg.choice(labels, nil, "Select Event")
    if not e then return end
    local eventName = labels[e]
    local event = TE_History[eventName]
    if not event or not event.analysis or not event.analysis.modeInfo then
        gg.toast("⚠️ Run game mode analysis first")
        TE_analyzeGameMode()
        return
    end
    local modes = event.analysis.modeInfo
    if #modes == 0 then gg.toast("⚠️ No modes detected"); return end
    local menu, promptDefaults, promptTypes = {}, {}, {}
    for i, m in ipairs(modes) do
        menu[i] = string.format("Mode %d: %s", m.jump, m.mode)
        promptDefaults[i] = false
        promptTypes[i] = "checkbox"
    end
    local mResults = gg.prompt(menu, promptDefaults, promptTypes)
    if not mResults then return end
    for mIndex, isSelected in ipairs(mResults) do
        if isSelected then
            local m = modes[mIndex]
            local msg = string.format("📌 Score Table\nEvent: %s\nMode %d (%s)\n\n", eventName, m.jump, m.mode)
            local sourceCode
            if m.mode == "Time Attack Mode" then
                msg = msg .. "Score → Time\n--------------\n"
                sourceCode = string.format([[
local sheet = {{}, {}}
sheet[1][2] = %s
sheet[2][2] = %s
local function eval(score)
  local x = (score - 1000) / 14000
  return sheet[2][2] - (sheet[2][2] - sheet[1][2]) * math.sqrt(x)
end
print('Score | Time Needed')
for score = 15000, 1000, -1000 do
  local r = eval(score)
  if score == 15000 or score == 1000 then
    print(score .. '  |  ' .. string.format('%%.0fs', r))
  else
    print(score .. '  |  ' .. string.format('%%.9fs', r))
  end
end
]], tostring(tonumber(m.t198) or 0), tostring(tonumber(m.t1B0) or 0))
            else
                msg = msg .. "Score → Distance\n-------------------\n"
                sourceCode = string.format([[
local b1, b2 = 0, %s
print("B1 =", b1)
print("B2 =", b2)
print("")
for tier = 15, 1, -1 do
  local X = 1000 + (tier - 1) * 1000
  local original = b2 - (b2 - b1) * math.sqrt((X - 1000) / 14000)
  local mirrored = b1 + b2 - original
  print(string.format("%%02d. | Score %%5d = %%.4fm", tier, X, mirrored))
end
]], tostring(tonumber(m.t198) or 0))
            end
            local stdout, err = TE_runJudge0(sourceCode, m.mode)
            if stdout then
                gg.toast(msg)
                gg.alert("OUTPUT:\n\n" .. stdout)
            else
                gg.alert("Error: " .. (err or "Unknown"))
            end
        end
    end
end
local function TeamEventMenu()
    local menu = {
        "🔍 SEARCH EVENT (BƯỚC 1)","✅ ENABLE TEAM EVENT","❌ DISABLE TEAM EVENT",
        "📝 SHOW LOGS","🥀 New Vehicle + Limit","🚗 Set Vehicle Limit",
        "🥀 Existing Allow Vehicle [Replaced]","🔬 GAME MODES INFO","🥇 SCORING SYSTEM","⬅️ Quay lại"
    }
    local choice = gg.choice(menu, nil, "🎯 TEAM EVENT")
    if choice == nil or choice == 10 then return MainMenu() end
    if choice == 1 then TE_searchEvent()
    elseif choice == 2 then TE_enableEvent()
    elseif choice == 3 then TE_disableEvent()
    elseif choice == 4 then TE_showLogs()
    elseif choice == 5 then TE_allowVehicleNewLists()
    elseif choice == 6 then TE_setVehicleLimit()
    elseif choice == 7 then TE_allowVehiclesInExisting()
    elseif choice == 8 then TE_analyzeGameMode()
    elseif choice == 9 then TE_showEventScoreCalculation() end
    return TeamEventMenu()
end

-- ═══════════════════════════════════════════════════════════════
--  PLAYER DATA (39 fields)
-- ═══════════════════════════════════════════════════════════════
local ADZ_PI = {}
local P_OFF = {
    id=0x30, name=0x38, flag=0x40, coins=0x48, neck=0x50, back=0x54,
    front=0x58, dist=0x64, gems=0x120, matches=0x1F0, wins=0x1F4,
    legend=0x200, hit=0x238, challengeID=0x240, teamID=0x2A0, guid=0x2C8,
    winLink=0x304, winGame=0x310, eventTk=0x320, evPoints=0x2C, evTk=0x48,
    evJoin=0x3B4, evScore=0x3B8, evDone=0x3BC, device=0x3C8, android=0x3D0,
    month=0x430, king=0x438, shard=0x45C, blueTk1=0x5F8, blueTk2=0x8,
    shard1=0x460, shard2=0x20, special=0x4AC, garage=0x4F4, advRank=0x52C,
    cloud=0x540, advTk1=0x5F8, advTk2=0x0, comm1=0x660, comm2=0x48,
    fleet1=0x4A0, fleet2=0x48, taskRefresh=0x5BC,
}
local function ADZ_ReadStr(p, maxLen)
    if not p or p == 0 then return "" end
    return readStringAt(p + 1, maxLen or 64)
end
local function ADZ_WriteStr(ptr, s, withLenPrefix)
    if not ptr or ptr == 0 then return end
    for i = 0, 0x14 do gg.setValues({{address = ptr + i, flags = gg.TYPE_BYTE, value = 0}}) end
    local start = withLenPrefix and 1 or 0
    if withLenPrefix then gg.setValues({{address = ptr, flags = gg.TYPE_BYTE, value = #s * 2}}) end
    for i = 1, #s do
        gg.setValues({{address = ptr + start + i - 1, flags = gg.TYPE_BYTE, value = string.byte(s, i)}})
    end
end
local function ADZ_ReadPlayer()
    if not BaseGameStatus or BaseGameStatus == 0 then return false end
    local FP = BaseGameStatus; local O = P_OFF
    local rQ = function(a) return gg.getValues({{address=a,flags=gg.TYPE_QWORD}})[1].value end
    local rD = function(a) return gg.getValues({{address=a,flags=gg.TYPE_DWORD}})[1].value end
    local rF = function(a) return gg.getValues({{address=a,flags=gg.TYPE_FLOAT}})[1].value end
    local p = {FP=FP}
    p.id    = ADZ_ReadStr(rQ(FP+O.id), 64)
    p.name  = ADZ_ReadStr(rQ(FP+O.name), 64)
    p.flag  = ADZ_ReadStr(rQ(FP+O.flag), 8)
    p.coins = rD(FP+O.coins); p.neck = rD(FP+O.neck)
    p.back  = rD(FP+O.back);  p.front = rD(FP+O.front)
    p.dist  = rF(FP+O.dist);  p.gems = rD(FP+O.gems)
    p.matches = rD(FP+O.matches); p.wins = rD(FP+O.wins)
    p.legend  = rF(FP+O.legend)*1000; p.clicks = rD(FP+O.hit)
    local cp = rQ(FP+O.challengeID); p.chal = cp~=0 and ADZ_ReadStr(rQ(cp),64) or ""
    local tp = rQ(FP+O.teamID); p.team = tp~=0 and ADZ_ReadStr(rQ(tp+0x10),64) or ""
    local gp = rQ(FP+O.guid);   p.guid = gp~=0 and ADZ_ReadStr(rQ(gp+0x10),64) or ""
    p.winLink = rD(FP+O.winLink); p.winGame = rD(FP+O.winGame)
    local ev = rQ(FP+O.eventTk)
    p.evPoints = ev~=0 and rD(ev+O.evPoints) or 0
    p.evTk     = ev~=0 and rD(ev+O.evTk) or 0
    p.evJoin = rD(FP+O.evJoin); p.evScore = rD(FP+O.evScore); p.evDone = rD(FP+O.evDone)
    p.device  = ADZ_ReadStr(rQ(FP+O.device),64)
    p.android = ADZ_ReadStr(rQ(FP+O.android),64)
    p.month   = ADZ_ReadStr(rQ(FP+O.month),64)
    p.king = rF(FP+O.king)*1000; p.shard = rD(FP+O.shard)
    local vb1 = rQ(FP+O.blueTk1); local vb2 = vb1~=0 and rQ(vb1+O.blueTk2) or 0
    p.blueTk = vb2~=0 and rD(vb2+0x20) or 0; p.blueRaw = vb2
    p.special = rD(FP+O.special); p.garage = rD(FP+O.garage); p.advRank = rF(FP+O.advRank)
    local cpp = rQ(FP+O.cloud); p.cloud = cpp~=0 and ADZ_ReadStr(rQ(cpp+0x10),64) or ""
    local at1 = rQ(FP+O.advTk1); local at2 = at1~=0 and rQ(at1+O.advTk2) or 0
    p.advTk = at2~=0 and rD(at2+0x20) or 0; p.advRaw = at2
    local cm = rQ(FP+O.comm1); p.comm = cm~=0 and rD(cm+O.comm2) or 0; p.commRaw = cm
    local fl = rQ(FP+O.fleet1); p.fleet = fl~=0 and rD(fl+O.fleet2) or 0; p.fleetRaw = fl
    p.task = rD(FP+O.taskRefresh)
    ADZ_PI = p; return true
end
local function ADZ_PlayerEdit(i)
    local p = ADZ_PI; local FP = p.FP; local O = P_OFF
    local sD = function(a,v) gg.setValues({{address=a,flags=gg.TYPE_DWORD,value=v}}) end
    local sF = function(a,v) gg.setValues({{address=a,flags=gg.TYPE_FLOAT,value=v}}) end
    local rQ = function(a) return gg.getValues({{address=a,flags=gg.TYPE_QWORD}})[1].value end
    if i==1 then local x=gg.prompt({"ID mới:"},{p.id},{"text"})
        if x and x[1]~=p.id then
            gg.clearResults(); gg.setRanges(RANGE_VALUE)
            gg.searchNumber(":"..p.id, gg.TYPE_BYTE)
            gg.getResults(10000); gg.editAll(":"..x[1], gg.TYPE_BYTE); gg.clearResults()
        end
    elseif i==2 then local x=gg.prompt({"Tên mới:"},{p.name},{"text"}); if x then ADZ_WriteStr(rQ(FP+O.name),x[1],true) end
    elseif i==3 then local x=gg.prompt({"Flag (2 chữ cái):"},{p.flag},{"text"}); if x then ADZ_WriteStr(rQ(FP+O.flag),x[1]:sub(1,2),false) end
    elseif i==4 then local x=gg.prompt({"Coins:"},{p.coins},{"number"}); if x then sD(FP+O.coins,tonumber(x[1])) end
    elseif i==5 then local x=gg.prompt({"Neck:"},{p.neck},{"number"}); if x then sD(FP+O.neck,tonumber(x[1])) end
    elseif i==6 then local x=gg.prompt({"Backflip:"},{p.back},{"number"}); if x then sD(FP+O.back,tonumber(x[1])) end
    elseif i==7 then local x=gg.prompt({"Frontflip:"},{p.front},{"number"}); if x then sD(FP+O.front,tonumber(x[1])) end
    elseif i==8 then local x=gg.prompt({"Distance:"},{string.format("%.0f",p.dist)},{"number"}); if x then sF(FP+O.dist,tonumber(x[1])) end
    elseif i==9 then local x=gg.prompt({"Gems:"},{p.gems},{"number"}); if x then sD(FP+O.gems,tonumber(x[1])) end
    elseif i==10 then local x=gg.prompt({"Matches:"},{p.matches},{"number"}); if x then sD(FP+O.matches,tonumber(x[1])) end
    elseif i==11 then local x=gg.prompt({"Wins:"},{p.wins},{"number"}); if x then sD(FP+O.wins,tonumber(x[1])) end
    elseif i==12 then local x=gg.prompt({"Legend (x1000):"},{string.format("%.0f",p.legend)},{"number"}); if x then sF(FP+O.legend,tonumber(x[1])*0.001) end
    elseif i==13 then local x=gg.prompt({"Clicks:"},{p.clicks},{"number"}); if x then sD(FP+O.hit,tonumber(x[1])) end
    elseif i==14 then gg.copyText(p.chal); gg.alert("Copied ChalID: "..p.chal)
    elseif i==15 then gg.copyText(p.team); gg.alert("Copied TeamID: "..p.team)
    elseif i==16 then gg.copyText(p.guid); gg.alert("Copied GUID: "..p.guid)
    elseif i==17 then local x=gg.prompt({"WinLink:"},{p.winLink},{"number"}); if x then sD(FP+O.winLink,tonumber(x[1])) end
    elseif i==18 then local x=gg.prompt({"WinGame:"},{p.winGame},{"number"}); if x then sD(FP+O.winGame,tonumber(x[1])) end
    elseif i==19 then local ev=rQ(FP+O.eventTk); if ev~=0 then local x=gg.prompt({"EvPoints:"},{p.evPoints},{"number"}); if x then sD(ev+O.evPoints,tonumber(x[1])) end end
    elseif i==20 then local ev=rQ(FP+O.eventTk); if ev~=0 then local x=gg.prompt({"EvTickets:"},{p.evTk},{"number"}); if x then sD(ev+O.evTk,tonumber(x[1])) end end
    elseif i==21 then local x=gg.prompt({"EvJoin:"},{p.evJoin},{"number"}); if x then sD(FP+O.evJoin,tonumber(x[1])) end
    elseif i==22 then local x=gg.prompt({"EvScore:"},{p.evScore},{"number"}); if x then sD(FP+O.evScore,tonumber(x[1])) end
    elseif i==23 then local x=gg.prompt({"EvDone:"},{p.evDone},{"number"}); if x then sD(FP+O.evDone,tonumber(x[1])) end
    elseif i==24 then gg.copyText(p.device); gg.alert("Copied Device: "..p.device)
    elseif i==25 then gg.copyText(p.android); gg.alert("Copied Android: "..p.android)
    elseif i==26 then gg.copyText(p.month); gg.alert("Copied Month: "..p.month)
    elseif i==27 then local x=gg.prompt({"King (x1000):"},{string.format("%.0f",p.king)},{"number"}); if x then sF(FP+O.king,tonumber(x[1])*0.001) end
    elseif i==28 then local x=gg.prompt({"Shard value:"},{p.shard},{"number"})
        if x then local dd=rQ(FP+O.shard1)
            if dd~=0 then gg.addListItems({
                {address=dd+O.shard2-0x4, flags=gg.TYPE_DWORD, value=520, freeze=true},
                {address=dd+O.shard2, flags=gg.TYPE_DWORD, value=tonumber(x[1]), freeze=true}}) end
        end
    elseif i==29 then local x=gg.prompt({"Blue tickets:"},{p.blueTk},{"number"}); if x and p.blueRaw~=0 then sD(p.blueRaw+0x20,tonumber(x[1])+1) end
    elseif i==30 then local x=gg.prompt({"Special tickets:"},{p.special},{"number"}); if x then sD(FP+O.special,tonumber(x[1])+1) end
    elseif i==31 then local x=gg.prompt({"Garage level:"},{p.garage},{"number"}); if x then sD(FP+O.garage,tonumber(x[1])) end
    elseif i==32 then local x=gg.prompt({"Adv rank:"},{string.format("%.2f",p.advRank)},{"number"}); if x then sF(FP+O.advRank,tonumber(x[1])) end
    elseif i==33 then gg.copyText(p.cloud); gg.alert("Copied CloudID: "..p.cloud)
    elseif i==34 then local x=gg.prompt({"Adv tokens:"},{p.advTk},{"number"}); if x and p.advRaw~=0 then sD(p.advRaw+0x20,tonumber(x[1])+1) end
    elseif i==35 then local x=gg.prompt({"Comm tickets:"},{p.comm},{"number"}); if x and p.commRaw~=0 then sD(p.commRaw+O.comm2,tonumber(x[1])) end
    elseif i==36 then local x=gg.prompt({"Fleet tickets:"},{p.fleet},{"number"}); if x and p.fleetRaw~=0 then sD(p.fleetRaw+O.fleet2,tonumber(x[1])) end
    elseif i==37 then
        local x=gg.prompt({"Fake Legend (x1000):","Fake King (x1000):"},{"9999","9999"},{"number","number"})
        if x then
            gg.clearResults(); gg.setRanges(gg.REGION_C_ALLOC)
            gg.searchNumber("-1119761152;335544322;788587520::9", gg.TYPE_DWORD)
            gg.refineNumber("-1119761152", gg.TYPE_DWORD)
            gg.getResults(100); gg.editAll("-1134575360", gg.TYPE_DWORD); gg.clearResults()
            sF(FP-0x4, tonumber(x[1])*0.001)
            if tonumber(x[2]) then sF(FP+O.king, tonumber(x[2])*0.001) end
        end
    elseif i==38 then local x=gg.prompt({"Task Refresh:"},{p.task},{"number"}); if x then sD(FP+O.taskRefresh,tonumber(x[1])) end
    end
end
function ADZ_PlayerMenu()
    if not ADZ_ReadPlayer() then
        gg.alert("❌ Chưa scan được GameStatus!\n\n💡 Vào Garage (bấm 1 xe) rồi thử lại.")
        return MainMenu()
    end
    local p = ADZ_PI
    local items = {
        "🆔 ID: "..(p.id~="" and p.id or "?"),
        "📝 Name: "..(p.name~="" and p.name or "?"),
        "🏳️ Flag: "..(p.flag~="" and p.flag or "?"),
        "💰 Coins: "..p.coins, "🔄 Neck: "..p.neck,
        "⬇️ Backflip: "..p.back, "⬆️ Frontflip: "..p.front,
        string.format("📏 Distance: %.0f", p.dist),
        "💎 Gems: "..p.gems, "🏁 Matches: "..p.matches, "🏆 Wins: "..p.wins,
        string.format("⭐ Legend: %.0f", p.legend), "👆 Clicks: "..p.clicks,
        "🎯 ChalID: "..(p.chal~="" and p.chal or "?"),
        "👥 TeamID: "..(p.team~="" and p.team or "?"),
        "🆔 GUID: "..(p.guid~="" and p.guid or "?"),
        "🔗 WinLink: "..p.winLink, "🎮 WinGame: "..p.winGame,
        "🎉 EvPoints: "..p.evPoints, "🎫 EvTickets: "..p.evTk,
        "🎯 EvJoin: "..p.evJoin, "📊 EvScore: "..p.evScore, "✅ EvDone: "..p.evDone,
        "📱 Device: "..(p.device~="" and p.device or "?"),
        "🤖 Android: "..(p.android~="" and p.android or "?"),
        "📅 Month: "..(p.month~="" and p.month or "?"),
        string.format("👑 King: %.0f", p.king), "💠 Shard: "..p.shard,
        "🎟️ BlueTicket: "..p.blueTk, "🎟️ Special: "..p.special,
        "🏠 GarageLv: "..p.garage, string.format("🏔️ AdvRank: %.2f", p.advRank),
        "☁️ CloudID: "..(p.cloud~="" and p.cloud or "?"),
        "🪙 AdvToken: "..p.advTk, "🎟️ CommTicket: "..p.comm,
        "🚗 FleetTicket: "..p.fleet, "🎭 Fake Legend + Fake King",
        "🔄 TaskRefresh: "..p.task, "🔁 Reload Data", "⬅️ Quay lại"
    }
    local c = gg.choice(items, nil, "👤 PLAYER DATA")
    if not c or c == 40 then return MainMenu() end
    if c == 39 then ADZ_ReadPlayer(); return ADZ_PlayerMenu() end
    ADZ_PlayerEdit(c); ADZ_PlayerMenu()
end

-- ═══════════════════════════════════════════════════════════════
--  SUPER PARTS CUSTOM
-- ═══════════════════════════════════════════════════════════════
local P_NAMES = {
    "Afterburner Burst","Afterburner TopSpeed","Afterburner Accel","Afterburner Max","Afterburner Fuel",
    "AirCtrl Power","AirCtrl Aero","AirCtrl Curve","AirCtrl AngVel",
    "CoinBoost TopSpeed","CoinBoost Dur","CoinBoost EffDur","CoinBoost Impulse","CoinBoost Max",
    "CoinMagnet Force","CoinMagnet Radius",
    "FlipBoost Burst","FlipBoost Dur","FlipBoost EffDur","FlipBoost Accel",
    "FuelBoost Burst","FuelBoost Dur","FuelBoost EffDur","FuelBoost Impulse","FuelBoost Accel",
    "FuelMagnet Force","FuelMagnet Radius",
    "FumeBoost Burst","FumeBoost Accel",
    "Glide Burst","Glide Dur","Glide EffDur","Glide Accel",
    "HvyW Weight","HvyW AttachHP","HvyW AccelOff","HvyW COM","HvyW PartMass","HvyW CollMass","HvyW Damage",
    "Jump Burst","Jump EffDur","Jump Impulse",
    "Magnet Radius","Magnet Force",
    "Nitro Impulse","Nitro TopSpeed","Nitro EffDur","Nitro Max",
    "PerfLanding Impulse","PerfLanding Dur",
    "PerfStart Burst","PerfStart Dur","PerfStart EffDur","PerfStart Accel",
    "Rollcage HP","Rollcage AttachHP",
    "Airbrake Downforce","Airbrake AttachHP",
    "Thrusters Burst","Thrusters Fuel","Thrusters Power",
    "Turbo TopSpeed","Turbo Impulse","Turbo EffDur","Turbo Max",
    "Wheelie Burst","Wheelie Dur","Wheelie EffDur","Wheelie Accel","Wheelie Hold",
    "Winter SnowGrip","Winter Grip","Winter Fric1","Winter Fric2"
}
local P_VALS = {
    {42.5,75},{2.5,3.5},{42.5,75},{2.5,3.5},{3,3},
    {13,20},{1,1},{0,0.25},{1.3,2},
    {8,20},{0.5,1},{0.5,1},{2,3},{7.5,10},
    {20,35},{5,15},
    {250,400},{0.5,1},{0.5,1},{250,400},
    {400,400},{0.5,1},{0.5,1},{8,8},{400,400},
    {200,200},{20,35},
    {250,450},{250,450},
    {100,200},{1.5,2.5},{1.5,2.5},{50,150},
    {81,160},{0.164,0.2},{0.039,0.075},{-0.186,-0.4},{1.214,3},{35,100},{171,350},
    {500,1000},{0.5,0.5},{0.45,0.65},
    {20,35},{5,15},
    {700,800},{0.5,1.5},{1,1.5},{700,800},
    {300,400},{0.5,1.5},
    {45,70},{2.5,2.5},{2.5,2.5},{45,70},
    {300,400},{0.5,1},
    {83,350},{0.5,1},
    {50,75},{4,10},{2.5,2.5},
    {50,75},{2,2},{2,2},{2.1,2.1},
    {50,150},{0.5,1.5},{1,1.5},{50,400},{15,100},
    {0.5,4},{0.15,1},{0.5,1.5},{0.5,1.5}
}
local _spData = nil
local function ADZ_ScanParts()
    gg.clearResults(); gg.setRanges(RANGE_VALUE)
    gg.searchNumber("h 14 46 55 45 4C 20 42 4F 4F 53 54 00", gg.TYPE_BYTE)
    gg.refineNumber("20", gg.TYPE_BYTE)
    local rs = gg.getResults(gg.getResultsCount()); local fb
    for _, v in ipairs(rs) do
        if gg.getValues({{address=v.address-0x30,flags=gg.TYPE_DWORD}})[1].value == 1702192680 then
            fb = v.address; break
        end
    end
    gg.clearResults()
    if not fb then return nil end
    local p1 = gg.getValues({{address=fb+0xB0,flags=gg.TYPE_QWORD}})[1].value
    local cdp = gg.getValues({{address=p1,flags=gg.TYPE_QWORD}})[1].value
    gg.searchNumber(cdp, gg.TYPE_QWORD)
    local all = gg.getResults(gg.getResultsCount()); gg.clearResults()
    local out = {}
    for _, r in ipairs(all) do
        if gg.getValues({{address=r.address+0x8,flags=gg.TYPE_DWORD}})[1].value ~= 1101004800 then
            out[#out+1] = {address=r.address,
                minL=gg.getValues({{address=r.address+0xC,flags=gg.TYPE_DWORD}})[1].value,
                maxL=gg.getValues({{address=r.address+0x10,flags=gg.TYPE_DWORD}})[1].value}
        end
    end
    return out
end
local function ADZ_ApplyPart(idx, val)
    _spData = _spData or ADZ_ScanParts()
    if not _spData then gg.alert("❌ Scan parts fail!"); return end
    local pair = P_VALS[idx]; if not pair then return end
    local mul = (pair[2]-pair[1])/(val-pair[1])+1.0
    local s1 = tonumber(yj.floatToDec(pair[1]) or 0)
    local s2 = tonumber(yj.floatToDec(pair[2]) or 0)
    local n = 0
    for _, d in ipairs(_spData) do
        if d.minL==s1 and d.maxL==s2 then
            gg.setValues({{address=d.address+0x8,flags=gg.TYPE_FLOAT,value=mul}})
            n = n+1
        end
    end
    gg.toast("✅ "..P_NAMES[idx].." = "..val.." ("..n..")")
end
function ADZ_SuperPartsMenu()
    local items = {}
    for i, n in ipairs(P_NAMES) do
        items[i] = string.format("%2d. %s [%s→%s]", i, n, P_VALS[i][1], P_VALS[i][2])
    end
    items[#items+1] = "♾️ Infinite Nitro (in-game)"
    items[#items+1] = "🔄 Reload parts"
    items[#items+1] = "⬅️ Quay lại"
    local c = gg.choice(items, nil, "🔩 SUPER PARTS — chọn thông số")
    if not c or c == #items then return MainMenu() end
    if c == #items - 2 then
        gg.clearResults(); gg.setRanges(RANGE_VALUE)
        gg.searchNumber("h 00 00 80 BF 00 00 80 BF CD CC CC 3D", gg.TYPE_BYTE)
        local r = gg.getResults(1)
        if #r == 0 then gg.alert("❌ Nitro not found!"); return ADZ_SuperPartsMenu() end
        local a = r[1].address
        local x = gg.prompt({"Nitro value:"},{"5"},{"number"})
        if x then
            gg.addListItems({
                {address=a+0x3C,flags=gg.TYPE_FLOAT,value=tonumber(x[1]),freeze=true},
                {address=a+0x40,flags=gg.TYPE_FLOAT,value=tonumber(x[1]),freeze=true}})
            gg.clearResults()
        end
        return ADZ_SuperPartsMenu()
    elseif c == #items - 1 then
        _spData = nil; gg.toast("🔄 Reloaded"); return ADZ_SuperPartsMenu()
    end
    local x = gg.prompt({P_NAMES[c].."\nGiá trị mới:"},{tostring(P_VALS[c][2])},{"number"})
    if x then ADZ_ApplyPart(c, tonumber(x[1])) end
    ADZ_SuperPartsMenu()
end

-- ═══════════════════════════════════════════════════════════════
--  EVENTS SHOP
-- ═══════════════════════════════════════════════════════════════
local _evShop = nil
local _resourcePool = nil
local _rewardAmount = 100

local function ADZ_FindEventShop()
    gg.clearResults(); gg.setRanges(RANGE_VALUE)
    gg.searchNumber("21600", gg.TYPE_DWORD)
    local rs = gg.getResults(100); gg.clearResults()
    if #rs == 0 then return nil end
    local now = os.time(); local reads = {}
    for _, v in ipairs(rs) do
        table.insert(reads,{address=v.address+0x10,flags=gg.TYPE_DWORD})
        table.insert(reads,{address=v.address-0x1C,flags=gg.TYPE_DWORD})
        table.insert(reads,{address=v.address-0x14,flags=gg.TYPE_DWORD})
    end
    local vals = gg.getValues(reads)
    for i = 1, #rs do
        local o = (i-1)*3
        if vals[o+1].value==-1 and vals[o+2].value<now and vals[o+3].value>now then
            local sa = rs[i].address-0x160
            local nm = ADZ_ReadStr(sa+0x19, 64)
            if nm=="" then local pp=gg.getValues({{address=sa+0x28,flags=gg.TYPE_QWORD}})[1].value
                if pp~=0 then nm = readStringAt(pp, 64) end end
            return {address=sa, name=nm~="" and nm or "Unknown"}
        end
    end
    return nil
end
local function ADZ_FreeEventItems(sa)
    local pS = gg.getValues({{address=sa+0x520,flags=gg.TYPE_QWORD}})[1].value
    local pE = gg.getValues({{address=sa+0x528,flags=gg.TYPE_QWORD}})[1].value
    if pS==0 or pE==0 or pE<=pS then return {} end
    local cnt = math.floor((pE-pS)/8)
    local reads = {}
    for i=1,cnt do reads[i] = {address=pS+(i-1)*8,flags=gg.TYPE_QWORD} end
    local ptrs = gg.getValues(reads)
    local ids, writes = {}, {}
    for i, v in ipairs(ptrs) do
        if v.value~=0 then
            local b = v.value
            writes[#writes+1] = {address=b+0x4,flags=gg.TYPE_DWORD,value=0}
            writes[#writes+1] = {address=b+0x28,flags=gg.TYPE_DWORD,value=-1}
            ids[i] = gg.getValues({{address=b+0x20,flags=gg.TYPE_QWORD}})[1].value
        end
    end
    if #writes>0 then gg.setValues(writes) end
    return ids
end
local function ADZ_InjectCharSkin(sa, itemIdx)
    local ids = ADZ_FreeEventItems(sa)
    if not ids[itemIdx] then gg.alert("❌ Item #"..itemIdx.." không tồn tại!"); return end
    local zp = yj.Allzeropages(); if not zp then return end
    gg.clearResults(); gg.setRanges(RANGE_VALUE)
    gg.searchNumber("h 0C 43 41 52 52 49 45 00", gg.TYPE_BYTE)
    gg.refineNumber("12", gg.TYPE_BYTE)
    local r = gg.getResults(gg.getResultsCount())
    if #r==0 then gg.alert("❌ CARRIE not found"); return end
    local rds = {}
    for _, v in ipairs(r) do rds[#rds+1] = {address=v.address-0x8,flags=gg.TYPE_DWORD} end
    local vs = gg.getValues(rds); local cands = {}
    for i, v in ipairs(vs) do if v.value==1 then cands[#cands+1] = r[i].address+0x70 end end
    if #cands==0 then gg.alert("❌ No CARRIE"); return end
    local prds = {}
    for _, a in ipairs(cands) do prds[#prds+1] = {address=a,flags=gg.TYPE_QWORD} end
    local pvs = gg.getValues(prds); local tgt
    for i, pv in ipairs(pvs) do
        if pv.value~=0 and readStringAt(pv.value,64)=="textures/drivers/common/carrie/carrie_torso.png" then
            tgt = cands[i]-0xB0; break
        end
    end
    if not tgt then gg.alert("❌ Skin ptr"); return end
    local sp = gg.getValues({{address=tgt,flags=gg.TYPE_QWORD}})[1].value
    gg.clearResults(); gg.setRanges(RANGE_VALUE)
    gg.searchNumber(sp, gg.TYPE_QWORD)
    local refs = gg.getResults(gg.getResultsCount()); if #refs==0 then return end
    local rr, ww = {}, {}
    for _, ref in ipairs(refs) do for off=0x8,0x1C,4 do rr[#rr+1]={address=ref.address+off,flags=gg.TYPE_DWORD} end end
    local rv = gg.getValues(rr)
    for i, v in ipairs(rv) do ww[i] = {address=zp+(i-1)*4,flags=gg.TYPE_DWORD,value=v.value} end
    gg.setValues(ww); local n = #ww/6
    gg.setValues({{address=ids[itemIdx]+0x60,flags=gg.TYPE_QWORD,value=zp},
                  {address=ids[itemIdx]+0x68,flags=gg.TYPE_QWORD,value=zp+n*24},
                  {address=ids[itemIdx]+0x70,flags=gg.TYPE_QWORD,value=zp+n*24}})
    gg.toast("✅ "..n.." char skins → item #"..itemIdx)
end
local function ADZ_InjectAnim(sa, itemIdx)
    local ids = ADZ_FreeEventItems(sa)
    if not ids[itemIdx] then gg.alert("❌ Item #"..itemIdx.." không tồn tại!"); return end
    local zp = yj.Allzeropages(); if not zp then return end
    gg.clearResults(); gg.setRanges(RANGE_VALUE)
    gg.searchNumber("h 0E 42 49 47 20 53 41 44", gg.TYPE_BYTE)
    gg.refineNumber('14', gg.TYPE_BYTE)
    local rs = gg.getResults(gg.getResultsCount()); local t
    for _, v in ipairs(rs) do
        if gg.getValues({{address=v.address-0x38,flags=gg.TYPE_DWORD}})[1].value==1734959630 then
            t = v.address-0x40; break
        end
    end
    if not t then gg.alert("❌ Anim not found"); return end
    local ap = gg.getValues({{address=t,flags=gg.TYPE_QWORD}})[1].value
    if ap==0 then return end
    gg.clearResults(); gg.searchNumber(ap, gg.TYPE_QWORD)
    local refs = gg.getResults(gg.getResultsCount())
    local rr, ww = {}, {}
    for _, ref in ipairs(refs) do for off=0x8,0x1C,4 do rr[#rr+1]={address=ref.address+off,flags=gg.TYPE_DWORD} end end
    local rv = gg.getValues(rr)
    for i, v in ipairs(rv) do ww[i] = {address=zp+(i-1)*4,flags=gg.TYPE_DWORD,value=v.value} end
    gg.setValues(ww); local n = #ww/6
    gg.setValues({{address=ids[itemIdx]+0x78,flags=gg.TYPE_QWORD,value=zp},
                  {address=ids[itemIdx]+0x80,flags=gg.TYPE_QWORD,value=zp+n*24},
                  {address=ids[itemIdx]+0x88,flags=gg.TYPE_QWORD,value=zp+n*24}})
    gg.toast("✅ "..n.." anims → item #"..itemIdx)
end
local function ADZ_InjectVehSkin(sa, itemIdx)
    local ids = ADZ_FreeEventItems(sa)
    if not ids[itemIdx] then gg.alert("❌ Item #"..itemIdx.." không tồn tại!"); return end
    local zp = yj.Allzeropages(); if not zp then return end
    gg.clearResults(); gg.setRanges(RANGE_VALUE)
    gg.searchNumber("h 1E 6A 65 65 70 5F 68 75 65 5F 76 69 6F 6C 65 74", gg.TYPE_BYTE)
    gg.refineNumber('30', gg.TYPE_BYTE)
    local rs = gg.getResults(gg.getResultsCount()); local t
    for _, v in ipairs(rs) do
        if gg.getValues({{address=v.address+0x18,flags=gg.TYPE_DWORD}})[1].value==1701145096 then
            t = v.address-0x8; break
        end
    end
    if not t then gg.alert("❌ VehSkin not found"); return end
    local sp = gg.getValues({{address=t,flags=gg.TYPE_QWORD}})[1].value
    if sp==0 then return end
    gg.clearResults(); gg.searchNumber(sp, gg.TYPE_QWORD)
    local refs = gg.getResults(gg.getResultsCount())
    local rr, ww = {}, {}
    for _, ref in ipairs(refs) do
        for _, off in ipairs({0x20,0x24,0x28,0x2C,0x30,0x34,0x8,0xC,0x10,0x14,0x18,0x1C}) do
            rr[#rr+1] = {address=ref.address+off,flags=gg.TYPE_DWORD}
        end
    end
    local rv = gg.getValues(rr)
    for i, v in ipairs(rv) do ww[i] = {address=zp+(i-1)*4,flags=gg.TYPE_DWORD,value=v.value} end
    gg.setValues(ww); local n = #ww/12
    gg.setValues({{address=ids[itemIdx]+0x90,flags=gg.TYPE_QWORD,value=zp},
                  {address=ids[itemIdx]+0x98,flags=gg.TYPE_QWORD,value=zp+n*48},
                  {address=ids[itemIdx]+0xA0,flags=gg.TYPE_QWORD,value=zp+n*48}})
    gg.toast("✅ "..n.." veh skins → item #"..itemIdx)
end
local function ADZ_InjectTireSkin(sa, itemIdx)
    local ids = ADZ_FreeEventItems(sa)
    if not ids[itemIdx] then gg.alert("❌ Item #"..itemIdx.." không tồn tại!"); return end
    local zp = yj.Allzeropages(); if not zp then return end
    gg.clearResults(); gg.setRanges(RANGE_VALUE)
    gg.searchNumber("h 0A 77 68 65 65 6C 00 00", gg.TYPE_BYTE)
    gg.refineNumber("10", gg.TYPE_BYTE)
    local w = gg.getResults(gg.getResultsCount())
    if #w==0 then gg.alert("❌ WHEEL not found"); return end
    local wbase = w[1].address; local waddrs = {}
    for k = 0, 5 do waddrs[#waddrs+1] = wbase + k*4 end
    gg.clearResults()
    gg.searchNumber("h 1E 6A 65 65 70 5F 68 75 65 5F 76 69 6F 6C 65 74", gg.TYPE_BYTE)
    gg.refineNumber('30', gg.TYPE_BYTE)
    local rs = gg.getResults(gg.getResultsCount()); local t
    for _, v in ipairs(rs) do
        if gg.getValues({{address=v.address+0x18,flags=gg.TYPE_DWORD}})[1].value==1701145096 then
            t = v.address-0x8; break
        end
    end
    if not t then return end
    local sp = gg.getValues({{address=t,flags=gg.TYPE_QWORD}})[1].value
    if sp==0 then return end
    gg.clearResults(); gg.searchNumber(sp, gg.TYPE_QWORD)
    local refs = gg.getResults(gg.getResultsCount())
    local rr, ww = {}, {}
    for _, ref in ipairs(refs) do
        for _, off in ipairs({0x20,0x24,0x28,0x2C,0x30,0x34}) do rr[#rr+1]={address=ref.address+off,flags=gg.TYPE_DWORD} end
        for _, wa in ipairs(waddrs) do rr[#rr+1]={address=wa,flags=gg.TYPE_DWORD} end
        for _, off in ipairs({0x8,0xC,0x10,0x14,0x18,0x1C}) do rr[#rr+1]={address=ref.address+off,flags=gg.TYPE_DWORD} end
    end
    local rv = gg.getValues(rr)
    for i, v in ipairs(rv) do ww[i] = {address=zp+(i-1)*4,flags=gg.TYPE_DWORD,value=v.value} end
    gg.setValues(ww); local n = #ww/18
    gg.setValues({{address=ids[itemIdx]+0xA8,flags=gg.TYPE_QWORD,value=zp},
                  {address=ids[itemIdx]+0xB0,flags=gg.TYPE_QWORD,value=zp+n*72},
                  {address=ids[itemIdx]+0xB8,flags=gg.TYPE_QWORD,value=zp+n*72}})
    gg.toast("✅ "..n.." tire skins → item #"..itemIdx)
end
local function ADZ_EventGetParts(sa, qty)
    local ids = ADZ_FreeEventItems(sa); if not ids[1] then return end
    local zp = yj.Allzeropages(); local cfg = yj.Allzeropages()
    if not zp or not cfg then return end
    for i, v in ipairs({0,1,2,3,4,999999}) do
        gg.setValues({{address=cfg+(i-1)*4,flags=gg.TYPE_DWORD,value=v}})
    end
    local wv = {}
    for _ = 1, qty do
        for _, off in ipairs({0,0,0,0,0,0,0x14,0x4,0,0,0,0,0,0,0x14,0x8,0,0,0,0,0,0,0x14,0xC,0,0,0,0,0,0,0x14,0x10}) do
            wv[#wv+1] = {address=cfg+off,flags=gg.TYPE_DWORD}
        end
    end
    local rv = gg.getValues(wv); local ww = {}
    for i, v in ipairs(rv) do ww[i] = {address=zp+(i-1)*4,flags=gg.TYPE_DWORD,value=v.value} end
    gg.setValues(ww)
    gg.setValues({{address=ids[1]+0x150,flags=gg.TYPE_QWORD,value=zp},
                  {address=ids[1]+0x158,flags=gg.TYPE_QWORD,value=zp+qty*128},
                  {address=ids[1]+0x160,flags=gg.TYPE_QWORD,value=zp+qty*128}})
    gg.toast("✅ Parts x"..qty.." → item #1")
end
local function ADZ_EventUnlockAllVehicles(sa)
    local ids = ADZ_FreeEventItems(sa); if not ids[1] then return end
    gg.clearResults(); gg.setRanges(RANGE_VALUE)
    gg.searchNumber("h AE 47 31 40 00 00 00 00 18 48 49 4C 4C 20 43 4C 49 4D 42 45", gg.TYPE_BYTE)
    local r = gg.getResults(1); if #r==0 then return end
    local base = r[1].address; gg.clearResults()
    gg.searchNumber(base-0x18, gg.TYPE_QWORD)
    local ptrs = gg.getResults(gg.getResultsCount()); local lp
    for _, p in ipairs(ptrs) do if (p.address%0x100)==0 then lp=p.address; break end end
    if not lp then return end
    local codes, off = {}, 0
    while off < 0x1000 do
        local c = gg.getValues({{address=lp+off,flags=gg.TYPE_QWORD}})[1].value
        if not c or c==0 then break end
        codes[#codes+1] = c; off = off+8
    end
    local zp = yj.Allzeropages(); if not zp then return end
    local ww, idx = {}, 0
    for _, c in ipairs(codes) do
        for k=0,5 do
            idx = idx+1
            ww[idx] = {address=zp+(idx-1)*4,flags=gg.TYPE_DWORD,value=gg.getValues({{address=c+k*4,flags=gg.TYPE_DWORD}})[1].value}
        end
    end
    gg.setValues(ww); local n = #codes
    gg.setValues({{address=ids[1]+0x48,flags=gg.TYPE_QWORD,value=zp},
                  {address=ids[1]+0x50,flags=gg.TYPE_QWORD,value=zp+n*24},
                  {address=ids[1]+0x58,flags=gg.TYPE_QWORD,value=zp+n*24},
                  {address=ids[1]+0x2C,flags=gg.TYPE_DWORD,value=19}})
    gg.toast("✅ "..n.." vehicles unlocked → item #1")
end

local function ADZ_GetResourcePool()
    gg.clearResults(); gg.setRanges(RANGE_VALUE)
    gg.searchNumber("h 0A 73 74 61 72 73 00 00", gg.TYPE_BYTE)
    gg.refineNumber("h 0A", gg.TYPE_BYTE)
    local stars = gg.getResults(gg.getResultsCount())
    local starsAdd
    for _, v in ipairs(stars) do
        local chk = gg.getValues({{address=v.address+0x18,flags=gg.TYPE_DWORD}})[1].value
        if chk == 1096045322 then starsAdd = v.address; break end
    end
    gg.clearResults()
    if not starsAdd then return nil end
    gg.searchNumber(starsAdd, gg.TYPE_DWORD)
    local ptrs = gg.getResults(gg.getResultsCount())
    local poolPtr
    for _, p in ipairs(ptrs) do
        local p1 = gg.getValues({{address=p.address+0x8,flags=gg.TYPE_QWORD}})[1].value
        if p1 ~= 0 then
            local hdr = gg.getValues({{address=p1,flags=gg.TYPE_DWORD}})[1].value
            if hdr == 1919120138 then poolPtr = p.address; break end
        end
    end
    if not poolPtr then return nil end
    local out = {}
    local off = 0
    while off < 0x200 do
        local code = gg.getValues({{address=poolPtr+off,flags=gg.TYPE_QWORD}})[1].value
        if not code or code == 0 then break end
        local name = yj.getString(code + 0x19)
        if name == "" then
            local backup = gg.getValues({{address=code+0x28,flags=gg.TYPE_QWORD}})[1].value
            if backup ~= 0 then name = yj.getString(backup) end
        end
        if name == "" then break end
        out[#out+1] = {name=name, address=code}
        off = off + 8
    end
    gg.clearResults()
    return out
end

function ADZ_ReplaceEventReward()
    _evShop = _evShop or ADZ_FindEventShop()
    if not _evShop then
        gg.alert("❌ Chưa có Event Shop!\nVào tab Event trước.")
        return
    end
    _resourcePool = _resourcePool or ADZ_GetResourcePool()
    if not _resourcePool or #_resourcePool == 0 then
        gg.alert("❌ Không tìm được resource pool!\nVào Event Shop rồi thử lại.")
        return
    end
    local ids = ADZ_FreeEventItems(_evShop.address)
    if #ids == 0 then
        gg.alert("❌ Không có item trong shop!")
        return
    end
    local resLabels = {}
    for i, r in ipairs(_resourcePool) do resLabels[i] = r.name end
    resLabels[#resLabels+1] = "⬅️ Quay lại"
    local rc = gg.choice(resLabels, nil, "🎁 Chọn loại resource để thay vào reward")
    if not rc or rc == #resLabels then return end
    local resource = _resourcePool[rc]
    local itemLabels = {}
    for i = 1, #ids do itemLabels[i] = "Item #" .. i end
    itemLabels[#itemLabels+1] = "🌟 TẤT CẢ ITEMS"
    itemLabels[#itemLabels+1] = "⬅️ Quay lại"
    local ic = gg.choice(itemLabels, nil, "🎯 Chọn item cần thay reward\n→ " .. resource.name)
    if not ic or ic == #itemLabels then return end
    local amt = gg.prompt({"Số lượng reward:"}, {tostring(_rewardAmount)}, {"number"})
    if not amt then return end
    _rewardAmount = tonumber(amt[1]) or 100
    local baseZp = yj.Allzeropages()
    if not baseZp then
        gg.alert("❌ Không tìm được zero page!")
        return
    end
    local resData = {}
    for j = 0, 5 do
        resData[j] = gg.getValues({{address=resource.address + j*4, flags=gg.TYPE_DWORD}})[1].value
    end
    local targets = {}
    if ic == #itemLabels - 1 then
        for i = 1, #ids do
            if ids[i] and ids[i] ~= 0 then targets[#targets+1] = ids[i] end
        end
    else
        if ids[ic] and ids[ic] ~= 0 then targets[1] = ids[ic] end
    end
    local writes = {}
    for idx, itemPtr in ipairs(targets) do
        local zp = baseZp + (idx - 1) * 0x20
        writes[#writes+1] = {address=zp+0x18, flags=gg.TYPE_DWORD, value=_rewardAmount}
        for j = 0, 5 do
            writes[#writes+1] = {address=zp+j*4, flags=gg.TYPE_DWORD, value=resData[j]}
        end
        writes[#writes+1] = {address=itemPtr+0x120, flags=gg.TYPE_QWORD, value=zp}
        writes[#writes+1] = {address=itemPtr+0x128, flags=gg.TYPE_QWORD, value=zp+0x20}
        writes[#writes+1] = {address=itemPtr+0x130, flags=gg.TYPE_QWORD, value=zp+0x20}
    end
    if #writes > 0 then gg.setValues(writes) end
    gg.alert(string.format(
        "✅ Đã thay reward cho %d item\n→ %s x%d\n\n💡 Thoát Event Shop rồi vào lại để thấy.",
        #targets, resource.name, _rewardAmount))
end

function ADZ_EventsShopMenu()
    _evShop = _evShop or ADZ_FindEventShop()
    if not _evShop then
        gg.alert("❌ Không tìm Event Shop!\nVào tab Event trong game rồi thử lại.")
        return MainMenu()
    end
    local items = {
        "🛒 Bật Free Event Shop Items",
        "🗑️ Xoá toàn bộ event items",
        "🎭 Inject All Character Skins  → item #2",
        "🎬 Inject All Character Anims  → item #3",
        "🚗 Inject All Vehicle Skins    → item #4",
        "🛞 Inject All Tire Skins       → item #5",
        "🔩 Get Parts xN                → item #1",
        "🚙 Unlock All Vehicles + Max   → item #1",
        "🎁 Thay Reward Event (Type+Amount)  ⭐ MỚI",
        "🔄 Reload shop data",
        "⬅️ Quay lại"
    }
    local c = gg.choice(items, nil, "🎉 EVENT SHOP: ".._evShop.name)
    if not c or c == #items then return MainMenu() end
    if c==1 then ADZ_FreeEventItems(_evShop.address); gg.alert("✅ Đã bật!")
    elseif c==2 then
        local ids = ADZ_FreeEventItems(_evShop.address)
        local w = {}
        for _, b in ipairs(ids) do
            if b and b~=0 then
                for off=0x18,0x27C,4 do w[#w+1]={address=b+off,flags=gg.TYPE_DWORD,value=0} end
            end
        end
        if #w>0 then gg.setValues(w) end
        gg.toast("✅ Đã xoá event items")
    elseif c==3 then ADZ_InjectCharSkin(_evShop.address, 2)
    elseif c==4 then ADZ_InjectAnim(_evShop.address, 3)
    elseif c==5 then ADZ_InjectVehSkin(_evShop.address, 4)
    elseif c==6 then ADZ_InjectTireSkin(_evShop.address, 5)
    elseif c==7 then
        local x = gg.prompt({"Số parts:"},{"300"},{"number"})
        if x then ADZ_EventGetParts(_evShop.address, tonumber(x[1])) end
    elseif c==8 then ADZ_EventUnlockAllVehicles(_evShop.address)
    elseif c==9 then ADZ_ReplaceEventReward()
    elseif c==10 then _evShop = nil; _resourcePool = nil; gg.toast("🔄 Reload")
    end
    ADZ_EventsShopMenu()
end

-- ═══════════════════════════════════════════════════════════════
--  DOWNFORCE
-- ═══════════════════════════════════════════════════════════════
local function ADZ_ApplyDownforce(value)
    value = tonumber(value)
    if not value or value < -100 or value > 100 then
        gg.alert("❌ Giá trị downforce phải nằm trong khoảng -100 đến 100.")
        return false
    end
    gg.clearResults()
    gg.setRanges(gg.REGION_C_ALLOC)
    gg.searchNumber("Q 00 00 00 00 00 00 C8 42 00 00 20 41 00 00 00 00", gg.TYPE_BYTE)
    if gg.getResultsCount() > 0 then
        gg.refineNumber("-56", gg.TYPE_BYTE)
    end
    local count = gg.getResultsCount()
    if count == 0 then
        gg.clearResults()
        gg.toast("❌ Không tìm thấy downforce! Vào Garage, chọn một xe rồi thử lại.")
        return false
    end
    local res = gg.getResults(count)
    local mods = {}
    for _, v in ipairs(res) do
        mods[#mods + 1] = {
            address = v.address - 0x46,
            flags = gg.TYPE_FLOAT,
            value = value
        }
    end
    local ok = pcall(gg.setValues, mods)
    gg.clearResults()
    if not ok then
        gg.alert("❌ Không thể ghi giá trị downforce. Hãy thử lại trong Garage.")
        return false
    end
    gg.toast("✅ Downforce = " .. tostring(value))
    return true
end
local function ADZ_DownforceMenu()
    local items = {
        "✏️ Tự đặt downforce",
        "-20", "-30", "-40", "-50", "-60", "-70",
        "-80", "-90", "-100", "-110", "-120",
        "♻️ Khôi phục mặc định (-10)",
        "⬅️ Quay lại"
    }
    local c = gg.choice(items, nil, "🛞 Chỉnh lực ép xuống (Downforce)")
    if not c or c == 14 then return MainMenu() end
    if c == 1 then
        local inp = gg.prompt({"Downforce [-100;100]:"}, {"-10"}, {"number"})
        if inp then ADZ_ApplyDownforce(tonumber(inp[1])) end
    elseif c >= 2 and c <= 12 then
        ADZ_ApplyDownforce(-(20 + (c - 2) * 10))
    elseif c == 13 then
        ADZ_ApplyDownforce(-10)
    end
    return ADZ_DownforceMenu()
end

-- ═══════════════════════════════════════════════════════════════
--  HIDDEN GARAGE BACKGROUND
-- ═══════════════════════════════════════════════════════════════
local function ADZ_UnlockHiddenGarageBg()
    local function patchGroup(searchPattern, refinePattern, replaceValues)
        gg.clearResults()
        gg.setRanges(gg.REGION_C_ALLOC)
        gg.searchNumber(searchPattern, gg.TYPE_DWORD)
        if gg.getResultsCount() == 0 then return 0 end
        if refinePattern then gg.refineNumber(refinePattern, gg.TYPE_DWORD) end
        local n = gg.getResultsCount()
        if n == 0 then return 0 end
        gg.getResults(math.min(n, 1000))
        local edited = gg.editAll(replaceValues, gg.TYPE_DWORD)
        gg.clearResults()
        return tonumber(edited) or n
    end
    local total = 0
    total = total + patchGroup("0;0;4;0;9::17", "0;0;4;0;9", "1;0;1;0;9")
    total = total + patchGroup(
        "0;0;4;0;17;0;1836016152",
        "0;0;4;0;17::17",
        "1;0;1;0;17"
    )
    total = total + patchGroup("0;0;4;0;33::17", "0;0;4;0;33::17", "1;0;1;0;33")
    gg.clearResults()
    if total > 0 then
        gg.toast("✅ Đã áp dụng mở khóa background gara ẩn")
    else
        gg.alert("❌ Không tìm thấy dữ liệu background.\n💡 Hãy vào Garage rồi thử lại; mẫu nhớ có thể khác theo phiên bản game.")
    end
    return MainMenu()
end

-- ═══════════════════════════════════════════════════════════════
--  ABOUT
-- ═══════════════════════════════════════════════════════════════
local function About()
    local info = [[
╔══════════════════════════════════╗
║      ꧁AɴнDᴇᴘZᴀı꧂ SCRIPT V3.4      ║
╚══════════════════════════════════╝

📌 Version: V3.4 anhdepzai
🎮 Game: Hill Climb Racing 2
⚙️ GG: 101.1

📢 Contact:
   💬 Discord  :: Andepzai
   ✈️ Telegram :: t.me/anhdepzai360
   📺 Tik Tok :: @anh_dep_zai

⚡ FEATURES (32):
   ✅ Auto Win (ARMV8)
   ✅ Fake Unlock
   ✅ Free Upgrade
   ✅ Force Boss
   ✅ Fake VIP
   ✅ Upgrade Parts Without Scrap
   ✅ Fly Hack
   ✅ Unlock Any Vehicle
   ✅ Tracks Editor
   ✅ Vehicle Hacks
   ✅ Free Chests
   ✅ Free Purchases
   ✅ Adventure Chest Hack V1
   ✅ Debug Mode
   ✅ VIP Pass (Real)
   ✅ Max Vehicles
   ✅ Max Mastery
   ✅ Max Parts
   ✅ Set Fuel & Coins
   ✅ Unlimited In-Game Fuel 
   ✅ Mastery & Cups
   ✅ Team Event Menu
   ✅ Event Menu
   ✅ Vehicle Speed
   ✅ Global Vision
   ✅ Player Data
   ✅ Super Parts Custom
   ✅ Events Shop
   ✅ Downforce
   ✅ Hidden Garage Background
   ✅ Creative (Any Theme + Hidden)
   ✅ About

⚠️ Tôi không chịu trách nhiệm
]]
    gg.alert(info, "OK")
    return MainMenu()
end

-- ═══════════════════════════════════════════════════════════════
--  CREATIVE — Any Theme Objects + Show Hidden Objects
-- ═══════════════════════════════════════════════════════════════
function cr_alignUp(addr, align) return addr % align == 0 and addr or (addr + align - (addr % align)) end
function cr_isClaimed(base, size) for cb, info in pairs(_creativeClaimed) do if base < cb + info.size and base + size > cb then return true end end return false end
function cr_isDangerousRegion(region)
    local perms = region.type or ""; if perms ~= "" and perms ~= "rw-p" then return true end
    local name, internal = region.name or "", region.internalName or ""
    return name:match("%.bss") or internal:match(":bss") or name:match("%.data") or internal:match(":data") or name:match("%[stack%]") or name:match("%[heap%]")
end
function cr_findEmpty(size)
    for _, region in ipairs(gg.getRangesList()) do
        if region.state == "O" and not cr_isDangerousRegion(region) and (region["end"] - region.start) >= size then
            local base = cr_alignUp(region.start, 8)
            if base + size <= region["end"] and not cr_isClaimed(base, size) then
                local reads = {}; for i = base, base + size - 1, 8 do reads[#reads+1] = {address=i, flags=32} end
                local allZero = true; for _, v in ipairs(gg.getValues(reads)) do if v.value ~= 0 then allZero = false; break end end
                if allZero then return base end
            end
        end
    end
    return nil
end
function cr_allocNew(size)
    local base = cr_findEmpty(size); if not base then return nil end; _creativeClaimed[base] = {size=size}
    return { base = base, size = size,
        write = function(self, values) local w = {}; for i, v in ipairs(values) do w[#w+1] = {address=self.base+(i-1)*8, flags=32, value=v} end; gg.setValues(w) end,
        free = function(self) local w = {}; for a = self.base, self.base + self.size - 1, 8 do w[#w+1] = {address=a, flags=32, value=0} end; gg.setValues(w); _creativeClaimed[self.base] = nil end
    }
end

function cr_getRawAnchors()
    gg.clearResults(); gg.setRanges(BaseRegion or gg.REGION_C_ALLOC); gg.searchNumber("h 20 66 6F 72 65 73 74 32 5F 67 66 78 2E 6A 73 6F 6E", 1); gg.refineNumber("h 20", 1)
    local results = gg.getResults(gg.getResultsCount()); gg.clearResults(); return results
end
function cr_verifyAnchorHash(v)
    local check = gg.getValues({{address=v.address+0x18, flags=4},{address=v.address+0x20, flags=4}})
    if check[1] and check[1].value and check[2] and check[2].value then return {address=v.address, flags=4} end
    return nil
end
function cr_verifyAnchorPtr(addr)
    local ptrA = gg.getValues({{address=addr-0x8, flags=32}})[1].value; if ptrA == 0 then return false end
    local checkA = gg.getValues({{address=ptrA+0x8, flags=4},{address=ptrA+0x10, flags=32}})
    local dwordAt8, ptr2 = checkA[1].value, checkA[2].value
    if dwordAt8 ~= 23 or ptr2 == 0 or not readStringAt(ptr2, 32):find("countryside_gfx_01.json", 1, true) then return false end
    local ptrB = gg.getValues({{address=addr+0x8, flags=32}})[1].value
    if ptrB == 0 or gg.getValues({{address=ptrB, flags=1}})[1].value ~= 26 or not readStringAt(ptrB+1, 8):find("city_gfx", 1, true) then return false end
    return true
end
function cr_resolveAnchors()
    if _creativeCachedAnchors and gg.getValues({{address=_creativeCachedAnchors[1]-0x8, flags=32}})[1].value ~= 0 then return _creativeCachedAnchors end
    _creativeCachedAnchors = nil; local raw = cr_getRawAnchors(); local valid = {}
    for _, v in ipairs(raw) do local ok = cr_verifyAnchorHash(v); if ok then valid[#valid+1] = ok end end
    local hits = gg.getValues(valid); gg.clearResults(); if not hits or #hits == 0 then return nil end
    local verified = {}; for _, hit in ipairs(hits) do
        gg.clearResults(); gg.searchNumber(hit.address, 32); local ptrs = gg.getResults(gg.getResultsCount()); gg.clearResults()
        for _, ptr in ipairs(ptrs) do if cr_verifyAnchorPtr(ptr.address) then verified[#verified+1] = ptr.address end end
    end
    if #verified == 0 then return nil end; _creativeCachedAnchors = verified; return verified
end

function cr_readSlotGroups(sPtr)
    local gv = gg.getValues({{address=sPtr+0x48,flags=32},{address=sPtr+0x50,flags=32},{address=sPtr+0x58,flags=32},{address=sPtr+0x60,flags=32},{address=sPtr+0x68,flags=32},{address=sPtr+0x70,flags=32},{address=sPtr+0x78,flags=32},{address=sPtr+0x80,flags=32},{address=sPtr+0x88,flags=32}})
    return { dynamic = {s=gv[1].value, e=gv[2].value, c=gv[3].value}, static = {s=gv[4].value, e=gv[5].value, c=gv[6].value}, props = {s=gv[7].value, e=gv[8].value, c=gv[9].value} }
end
function cr_collectPoolRange(gs, ge, dest)
    for a = gs, ge - 1, 0x8 do local p = gg.getValues({{address=a, flags=32}})[1].value; if p ~= 0 then dest[#dest+1] = p end end
end
function cr_isSentinel(sPtr) return gg.getValues({{address=sPtr, flags=1}})[1].value == 6 and readStringAt(sPtr+1, 3):find("all", 1, true) end
function cr_readAllPools(anchors)
    local pool = { dynamic = {}, static = {}, props = {} }; local anchorSlots = {}
    for _, anchor in ipairs(anchors) do for cur = anchor - 0x8, anchor + 0x1000, 0x8 do
        local sPtr = gg.getValues({{address=cur, flags=32}})[1].value; if sPtr == 0 or cr_isSentinel(sPtr) then break end
        local origGroups = cr_readSlotGroups(sPtr); anchorSlots[#anchorSlots+1] = {addr=cur, sPtr=sPtr, origGroups=origGroups}
        for _, grp in ipairs(CREATIVE_GROUP_ORDER) do local g = origGroups[grp]; if g.s ~= 0 and g.e > g.s then cr_collectPoolRange(g.s, g.e, pool[grp]) end end
    end end
    return pool, anchorSlots
end
function cr_chunkPool(pool)
    local pages = { dynamic = {}, static = {}, props = {} }
    for _, grp in ipairs(CREATIVE_GROUP_ORDER) do local src = pool[grp]; local i = 1; while i <= #src do local page = {}; for j = i, math.min(i+CREATIVE.PAGE_SIZE-1, #src) do page[#page+1] = src[j] end; pages[grp][#pages[grp]+1] = page; i = i + CREATIVE.PAGE_SIZE end end
    return pages
end
function cr_zeroRequiresTheme(sPtr, writes) for _, off in ipairs(CREATIVE_THEME_ZERO_OFFSETS) do writes[#writes+1] = {address=sPtr+off, flags=4, value=0} end end
function cr_writeHiddenTheme(sPtr, writes) writes[#writes+1] = {address=sPtr+0x00, flags=1, value=0x0C}; for i, b in ipairs({0x68,0x69,0x64,0x64,0x65,0x6E}) do writes[#writes+1] = {address=sPtr+i, flags=1, value=b} end end
function cr_zeroGroupSlot(sPtr, gs, writes) writes[#writes+1] = {address=sPtr+gs.ptr1, flags=32, value=0}; writes[#writes+1] = {address=sPtr+gs.ptr2, flags=32, value=0}; writes[#writes+1] = {address=sPtr+gs.ptr3, flags=32, value=0} end

function cr_anyThemeRevert()
    local cache = _creativeAnyThemeCache; if not cache then gg.toast("Nothing to revert"); return end
    local writes = {}; for _, slot in ipairs(cache.slots) do local og, sp = slot.origGroups, slot.sPtr
        writes[#writes+1] = {address=sp+0x48, flags=32, value=og.dynamic.s}; writes[#writes+1] = {address=sp+0x50, flags=32, value=og.dynamic.e}; writes[#writes+1] = {address=sp+0x58, flags=32, value=og.dynamic.c}
        writes[#writes+1] = {address=sp+0x60, flags=32, value=og.static.s}; writes[#writes+1] = {address=sp+0x68, flags=32, value=og.static.e}; writes[#writes+1] = {address=sp+0x70, flags=32, value=og.static.c}
        writes[#writes+1] = {address=sp+0x78, flags=32, value=og.props.s}; writes[#writes+1] = {address=sp+0x80, flags=32, value=og.props.e}; writes[#writes+1] = {address=sp+0x88, flags=32, value=og.props.c}
        for _, rb in ipairs(slot.origTheme) do writes[#writes+1] = rb end
    end
    gg.setValues(writes); if _creativeAllocHandles then for _, h in ipairs(_creativeAllocHandles) do h:free() end; _creativeAllocHandles = nil end
    _creativeAnyThemeCache = nil; gg.toast("Reverted " .. #cache.slots .. " slot(s)")
end
function cr_anyThemeApply()
    if archType ~= 1 or not tostring(gameVersion):find("1.76.1", 1, true) then
        gg.alert("⚠️ Any Theme Objects chỉ hỗ trợ HCR2 1.76.1 ARM64.\nThiết bị/game hiện tại: " .. tostring(gameVersion) .. " / arch=" .. tostring(archType))
        return
    end
    if _creativeAnyThemeCache then gg.toast("Already applied"); return end
    local anchors = cr_resolveAnchors(); if not anchors then return end
    local pool, anchorSlots = cr_readAllPools(anchors); if #anchorSlots == 0 then return end
    local pages = cr_chunkPool(pool); local numPages = math.min(math.max(#pages.dynamic, #pages.static, #pages.props), #anchorSlots)
    for _, slot in ipairs(anchorSlots) do local r = {}; for i = 0, 6 do r[i+1] = {address=slot.sPtr+i, flags=1} end; slot.origTheme = gg.getValues(r) or {} end
    local allocHandles = {}; local pageAllocs = {}
    for pi = 1, numPages do pageAllocs[pi] = {}; for _, grp in ipairs(CREATIVE_GROUP_ORDER) do local pg = pages[grp][pi]; if pg and #pg > 0 then local h = cr_allocNew(#pg * 8); if not h then for _, hh in ipairs(allocHandles) do hh:free() end; return end; h:write(pg); allocHandles[#allocHandles+1] = h; pageAllocs[pi][grp] = h end end end
    local allWrites = {}
    for pi = 1, numPages do local sPtr = anchorSlots[pi].sPtr
        for _, grp in ipairs(CREATIVE_GROUP_ORDER) do local gs, h, pg = CREATIVE_GROUP_SLOTS[grp], pageAllocs[pi][grp], pages[grp][pi]
            if h and pg and #pg > 0 then local endAddr = h.base + #pg * 8; allWrites[#allWrites+1] = {address=sPtr+gs.ptr1, flags=32, value=h.base}; allWrites[#allWrites+1] = {address=sPtr+gs.ptr2, flags=32, value=endAddr}; allWrites[#allWrites+1] = {address=sPtr+gs.ptr3, flags=32, value=endAddr}
            else cr_zeroGroupSlot(sPtr, gs, allWrites) end
        end
        cr_zeroRequiresTheme(sPtr, allWrites)
    end
    for si = numPages + 1, #anchorSlots do cr_writeHiddenTheme(anchorSlots[si].sPtr, allWrites) end
    gg.setValues(allWrites); _creativeAllocHandles = allocHandles; _creativeAnyThemeCache = { slots = anchorSlots }
end
function cr_anyThemeObjects(state) if state then cr_anyThemeApply() else cr_anyThemeRevert() end end

function cr_collectHiddenInPtr(ptr, dest)
    local rangeR = gg.getValues({{address=ptr+0x30, flags=32},{address=ptr+0x38, flags=32}}); local pStart, pEnd = rangeR[1].value, rangeR[2].value
    if pStart == 0 or pEnd <= pStart or (pEnd - pStart) > 0x10000 then return end
    for cur2 = pStart, pEnd - 1, 0x8 do local ptr3 = gg.getValues({{address=cur2, flags=32}})[1].value; if ptr3 ~= 0 then dest[#dest+1] = {address=ptr3+0x101, flags=1, value=0} end end
end
function cr_collectHidden(anchors)
    local targets = {}
    for _, anchor in ipairs(anchors) do for cur = anchor - 0x20, anchor + 0x1000, 0x8 do local ptr = gg.getValues({{address=cur, flags=32}})[1].value; if ptr == 0 or cr_isSentinel(ptr) then break end; cr_collectHiddenInPtr(ptr, targets) end end
    return targets
end
function cr_showHiddenObjects(state)
    if not state then
        if not _creativeShowHiddenCache then return end
        gg.setValues(_creativeShowHiddenCache)
        _creativeShowHiddenCache = nil
        gg.toast("Hidden objects restored")
        return
    end
    if archType ~= 1 or not tostring(gameVersion):find("1.76.1", 1, true) then
        gg.alert("⚠️ Show Hidden Objects chỉ hỗ trợ HCR2 1.76.1 ARM64.\nThiết bị/game hiện tại: " .. tostring(gameVersion) .. " / arch=" .. tostring(archType))
        return
    end
    local anchors = cr_resolveAnchors(); if not anchors then return end
    local targets = cr_collectHidden(anchors); if #targets == 0 then return end
    if not _creativeShowHiddenCache then
        local r = {}; for _, w in ipairs(targets) do r[#r+1] = {address=w.address, flags=w.flags} end
        _creativeShowHiddenCache = gg.getValues(r)
    end
    gg.setValues(targets)
end

local function CreativeMenu()
    local items = {
        "🎨 Any Theme Objects " .. (_creativeAnyThemeCache and "🟢 ON" or "⚫ OFF"),
        "👁️ Show Hidden Objects " .. (_creativeShowHiddenCache and "🟢 ON" or "⚫ OFF"),
        "⬅️ Quay lại"
    }
    local c = gg.choice(items, nil, "🎨 CREATIVE | ANHDEPZAI")
    if not c or c == 3 then return MainMenu() end
    if c == 1 then cr_anyThemeObjects(_creativeAnyThemeCache == nil)
    elseif c == 2 then cr_showHiddenObjects(_creativeShowHiddenCache == nil) end
    return CreativeMenu()
end


-- ═══════════════════════════════════════════════════════════════
--  SWAP MAP (tích hợp từ swap map v2.lua)
--  Dùng vùng nhớ đã chọn ở bước khởi động: C alloc / C data / Other.
-- ═══════════════════════════════════════════════════════════════
local function SwapMapMenu()
    if not RANGE_VALUE then
        gg.alert("❌ Chưa chọn vùng nhớ. Hãy khởi động lại script và chọn C alloc / C data / Other.")
        return MainMenu()
    end
    CZGZGZG = RANGE_VALUE
    gg.setRanges(CZGZGZG)
    LPP3()
    return MainMenu()
end

function LPP3()
   DRAYQ = gg.choice( {
	 "Forest",
	 "Mountain",
	 "Mine",
	 "Desert Valley",
	 "Exit"} , 0, "By ANHDEPZAI")
        if DRAYQ == nil then else
        if DRAYQ == 1 then DFK='h 6A 73 6F 6E 2F 6C 65 76 65 6C 73 2F 66 6F 72 65 73 74 5F 64 69 73 74 61 6E 63 65 2E 6A 73 6F 6E' o1() end
        if DRAYQ == 2 then DFK='h 6A 73 6F 6E 2F 6C 65 76 65 6C 73 2F 6D 6F 75 6E 74 61 69 6E 5F 64 69 73 74 61 6E 63 65 5F 30 31 2E 6A 73 6F 6E' o1() end
        if DRAYQ == 3 then DFK='h 6A 73 6F 6E 2F 6C 65 76 65 6C 73 2F 6D 69 6E 65 5F 64 69 73 74 61 6E 63 65 2E 6A 73 6F 6E' o1() end
        if DRAYQ == 4 then DFK='h 6A 73 6F 6E 2F 6C 65 76 65 6C 73 2F 72 6F 75 74 65 36 36 5F 64 69 73 74 61 6E 63 65 2E 6A 73 6F 6E' o1() end
        if DRAYQ == 5 then return end
    end
end

function o1()
   hjka = gg.choice( {
	 "3d test ",
"amused park cup",
"amused park cup 2",
"amusementpark cup 3",
"amusementpark distance",
"amusementpark glitchtest",
"amusement park distance",
"ancient arena distance 1",
"angry bill ",
"angry bill  03",
"angry bill event ",
"angry jump ",
"arena cup",
"arena cup 2",
"arena hard distance ",
"backwaterbog crocodile cup ",
"beach cup 4",
"beach cup ",
"beach distance ",
"big air cup ",
"boards ",
"boards  easy",
"boggy road ",
"bog cup ",
"bonus level ",
"cargo  2",
"cargo event ",
"city 01 ",
"city 02 ",
"city capital 01 ",
"city distance ",
"city hard distance ",
"city highway 01 ",
"city highway 02 ",
"city highway 03 ",
"city highway 04 ",
"city lights 01 ",
"clacier cup 1",
"classic event ",
"cny event ",
"collect balloons event",
"countryside ",
"countryside cup 01 ",
"countryside cup 02 ",
"countryside cup 03 ",
"countryside distance ",
"countryside sensor dev ",
"cuptown cup",
"cuptown cup 02",
"cuptown distance",
"cuptown distance  test",
"cuptown easy cup",
"darkforest distance ",
"dark forest cup ",
"dark roads ",
"desert caves ",
"desert to city ",
"downhill ",
"downhill cup ",
"downhill trials ",
"easy mine ",
"equip tuningparts event",
"floor is lava ",
"football 01 ",
"forest 01 ",
"forest 02 ",
"forest 03 ",
"forest 04 ",
"forest 05 ",
"forest ",
"forest cup logs ",
"forest distance ",
"forest hard distance ",
"formula city 2 ",
"formula city ",
"glacier cup 04",
"glacier cup 2",
"glacier distance ",
"gloomvale cup ",
"gravityland ",
"halloween 2",
"halloween event ",
"halloween event  2",
"halloween event  3",
"hallo cup ",
"hillclimb2 ",
"hillclimb mine ",
"hillclimb mountain ",
"hillclimb winter ",
"jump cargo ",
"jump original ",
"level arena bronze",
"level countryside ",
"level forest2 ",
"level tutorial",
"long city 01 ",
"long desert ",
"long glacier 01 ",
"long mine 01 ",
"long winter ",
"marshland cup ",
"mine ",
"mine  2",
"mine distance ",
"moon ",
"moon distance ",
"moon tricks ",
"mountain 01 ",
"mountain 02 ",
"mountain 06 ",
"mountain 07 ",
"mountain ",
"mountain bridges ",
"mountain cup 01 ",
"mountain distance ",
"mountain downhill 01",
"nationalpark distance",
"nationalpark distance ",
"paradisebay",
"potatofield",
"rocky road ",
"rocky road  verse3",
"roofs 01 ",
"roofs 02 ",
"rookie cup ",
"rookie forest ",
"route66 distance ",
"route66 fast ",
"route66 slow ",
"savanna cup",
"savanna distance ",
"skill ",
"speedball ",
"spring falls cup",
"spring falls cup 03",
"stormrider cup",
"testarea ",
"test ",
"test  deform",
"test cup ",
"test water ",
"thunderstorm avoid event",
"trailerpark cup",
"trailerpark distance ",
"tunnels ",
"tutorial 6",
"tutorial ",
"underwater cup 1",
"underwater cup ",
"underwater distance ",
"underwater kraken cup 1",
"underwater long cup 1",
"uphill cup ",
"water run ",
"wheelie ",
"winter cup ",
"winter cup  easy",
"winter cup  tuningparts",
"winter distance ",
"winter hard distance ",
"workshop cup ",
"workshop distance ",
"workshop factory cup ",
"bobble-head",
"double-exhaust",
"exhaust-extreme",
"exhaust-long",
"exhaust-turned",
"horn",
"mirror-green",
"rocket",
"adv_token_stack01",
"coin_stack01",
"coin_stack02",
"dual_room",
"gemcoin_stack01",
"gemcoin_stack02",
"gem_stack01",
"gem_stack02",
"single_adv_token",
"single_coin",
"single_diamond1",
"single_diamond2",
"single_diamond3",
"single_room",
"helipack",
"driver",
"driver_naked",
"driver_sitting",
"driver-hat",
"Abduction Alert",
"Thunder 6",
"Halloween",
"Pumpkin Halloween"} , 0, "By anhdepzai")
if hjka == nil then else
if hjka==1 then QQA="rube/levels/3d_test_blocks.rube" zxcz() end
if hjka==2 then QQA="rube/levels/amused_park_cup.rube" zxcz() end
if hjka==3 then QQA="rube/levels/amused_park_cup_2.rube" zxcz() end
if hjka==4 then QQA="rube/levels/amusementpark_cup_3.rube" zxcz() end
if hjka==5 then QQA="rube/levels/amusementpark_distance.rube" zxcz() end
if hjka==6 then QQA="rube/levels/amusementpark_glitchtest.rube" zxcz() end
if hjka==7 then QQA="rube/levels/amusement_park_distance.rube" zxcz() end
if hjka==8 then QQA="rube/levels/ancient_arena_distance_1.rube" zxcz() end
if hjka==9 then QQA="rube/levels/angry_bill_blocks.rube" zxcz() end
if hjka==10 then QQA="rube/levels/angry_bill_blocks_03.rube" zxcz() end
if hjka==11 then QQA="rube/levels/angry_bill_event_blocks.rube" zxcz() end
if hjka==12 then QQA="rube/levels/angry_jump_blocks.rube" zxcz() end
if hjka==13 then QQA="rube/levels/arena_cup.rube" zxcz() end
if hjka==14 then QQA="rube/levels/arena_cup_2.rube" zxcz() end
if hjka==15 then QQA="rube/levels/arena_hard_distance_blocks.rube" zxcz() end
if hjka==16 then QQA="rube/levels/backwaterbog_crocodile_cup_blocks.rube" zxcz() end
if hjka==17 then QQA="rube/levels/beach_cup_4.rube" zxcz() end
if hjka==18 then QQA="rube/levels/beach_cup_blocks.rube" zxcz() end
if hjka==19 then QQA="rube/levels/beach_distance_blocks.rube" zxcz() end
if hjka==20 then QQA="rube/levels/big_air_cup_blocks.rube" zxcz() end
if hjka==21 then QQA="rube/levels/boards_blocks.rube" zxcz() end
if hjka==22 then QQA="rube/levels/boards_blocks_easy.rube" zxcz() end
if hjka==23 then QQA="rube/levels/boggy_road_blocks.rube" zxcz() end
if hjka==24 then QQA="rube/levels/bog_cup_blocks.rube" zxcz() end
if hjka==25 then QQA="rube/levels/bonus_level_blocks.rube" zxcz() end
if hjka==26 then QQA="rube/levels/cargo_blocks_2.rube" zxcz() end
if hjka==27 then QQA="rube/levels/cargo_event_blocks.rube" zxcz() end
if hjka==28 then QQA="rube/levels/city_01_blocks.rube" zxcz() end
if hjka==29 then QQA="rube/levels/city_02_blocks.rube" zxcz() end
if hjka==30 then QQA="rube/levels/city_capital_01_blocks.rube" zxcz() end
if hjka==31 then QQA="rube/levels/city_distance_blocks.rube" zxcz() end
if hjka==32 then QQA="rube/levels/city_hard_distance_blocks.rube" zxcz() end
if hjka==33 then QQA="rube/levels/city_highway_01_blocks.rube" zxcz() end
if hjka==34 then QQA="rube/levels/city_highway_02_blocks.rube" zxcz() end
if hjka==35 then QQA="rube/levels/city_highway_03_blocks.rube" zxcz() end
if hjka==36 then QQA="rube/levels/city_highway_04_blocks.rube" zxcz() end
if hjka==37 then QQA="rube/levels/city_lights_01_blocks.rube" zxcz() end
if hjka==38 then QQA="rube/levels/clacier_cup_1.rube" zxcz() end
if hjka==39 then QQA="rube/levels/classic_event_blocks.rube" zxcz() end
if hjka==40 then QQA="rube/levels/cny_event_blocks.rube" zxcz() end
if hjka==41 then QQA="rube/levels/collect_balloons_event.rube" zxcz() end
if hjka==42 then QQA="rube/levels/countryside_blocks.rube" zxcz() end
if hjka==43 then QQA="rube/levels/countryside_cup_01_blocks.rube" zxcz() end
if hjka==44 then QQA="rube/levels/countryside_cup_02_blocks.rube" zxcz() end
if hjka==45 then QQA="rube/levels/countryside_cup_03_blocks.rube" zxcz() end
if hjka==46 then QQA="rube/levels/countryside_distance_blocks.rube" zxcz() end
if hjka==47 then QQA="rube/levels/countryside_sensor_dev_blocks.rube" zxcz() end
if hjka==48 then QQA="rube/levels/cuptown_cup.rube" zxcz() end
if hjka==49 then QQA="rube/levels/cuptown_cup_02.rube" zxcz() end
if hjka==50 then QQA="rube/levels/cuptown_distance.rube" zxcz() end
if hjka==51 then QQA="rube/levels/cuptown_distance_blocks_test.rube" zxcz() end
if hjka==52 then QQA="rube/levels/cuptown_easy_cup.rube" zxcz() end
if hjka==53 then QQA="rube/levels/darkforest_distance_blocks.rube" zxcz() end
if hjka==54 then QQA="rube/levels/dark_forest_cup_blocks.rube" zxcz() end
if hjka==55 then QQA="rube/levels/dark_roads_blocks.rube" zxcz() end
if hjka==56 then QQA="rube/levels/desert_caves_blocks.rube" zxcz() end
if hjka==57 then QQA="rube/levels/desert_to_city_blocks.rube" zxcz() end
if hjka==58 then QQA="rube/levels/downhill_blocks.rube" zxcz() end
if hjka==59 then QQA="rube/levels/downhill_cup_blocks.rube" zxcz() end
if hjka==60 then QQA="rube/levels/downhill_trials_blocks.rube" zxcz() end
if hjka==61 then QQA="rube/levels/easy_mine_blocks.rube" zxcz() end
if hjka==62 then QQA="rube/levels/equip_tuningparts_event.rube" zxcz() end
if hjka==63 then QQA="rube/levels/floor_is_lava_blocks.rube" zxcz() end
if hjka==64 then QQA="rube/levels/football_01_blocks.rube" zxcz() end
if hjka==65 then QQA="rube/levels/forest_01_blocks.rube" zxcz() end
if hjka==66 then QQA="rube/levels/forest_02_blocks.rube" zxcz() end
if hjka==67 then QQA="rube/levels/forest_03_blocks.rube" zxcz() end
if hjka==68 then QQA="rube/levels/forest_04_blocks.rube" zxcz() end
if hjka==69 then QQA="rube/levels/forest_05_blocks.rube" zxcz() end
if hjka==70 then QQA="rube/levels/forest_blocks.rube" zxcz() end
if hjka==71 then QQA="rube/levels/forest_cup_logs_blocks.rube" zxcz() end
if hjka==72 then QQA="rube/levels/forest_distance_blocks.rube" zxcz() end
if hjka==73 then QQA="rube/levels/forest_hard_distance_blocks.rube" zxcz() end
if hjka==74 then QQA="rube/levels/formula_city_2_blocks.rube" zxcz() end
if hjka==75 then QQA="rube/levels/formula_city_blocks.rube" zxcz() end
if hjka==76 then QQA="rube/levels/glacier_cup_04.rube" zxcz() end
if hjka==77 then QQA="rube/levels/glacier_cup_2.rube" zxcz() end
if hjka==78 then QQA="rube/levels/glacier_distance_blocks.rube" zxcz() end
if hjka==79 then QQA="rube/levels/gloomvale_cup_blocks.rube" zxcz() end
if hjka==80 then QQA="rube/levels/gravityland_blocks.rube" zxcz() end
if hjka==81 then QQA="rube/levels/halloween_blocks2.rube" zxcz() end
if hjka==82 then QQA="rube/levels/halloween_event_blocks.rube" zxcz() end
if hjka==83 then QQA="rube/levels/halloween_event_blocks_2.rube" zxcz() end
if hjka==84 then QQA="rube/levels/halloween_event_blocks_3.rube" zxcz() end
if hjka==85 then QQA="rube/levels/hallo_cup_blocks.rube" zxcz() end
if hjka==86 then QQA="rube/levels/hillclimb2_blocks.rube" zxcz() end
if hjka==87 then QQA="rube/levels/hillclimb_mine_blocks.rube" zxcz() end
if hjka==88 then QQA="rube/levels/hillclimb_mountain_blocks.rube" zxcz() end
if hjka==89 then QQA="rube/levels/hillclimb_winter_blocks.rube" zxcz() end
if hjka==90 then QQA="rube/levels/jump_cargo_blocks.rube" zxcz() end
if hjka==91 then QQA="rube/levels/jump_original_blocks.rube" zxcz() end
if hjka==92 then QQA="rube/levels/level_arena_bronze.rube" zxcz() end
if hjka==93 then QQA="rube/levels/level_countryside_blocks.rube" zxcz() end
if hjka==94 then QQA="rube/levels/level_forest2_blocks.rube" zxcz() end
if hjka==95 then QQA="rube/levels/level_tutorial.rube" zxcz() end
if hjka==96 then QQA="rube/levels/long_city_01_blocks.rube" zxcz() end
if hjka==97 then QQA="rube/levels/long_desert_blocks.rube" zxcz() end
if hjka==98 then QQA="rube/levels/long_glacier_01_blocks.rube" zxcz() end
if hjka==99 then QQA="rube/levels/long_mine_01_blocks.rube" zxcz() end
if hjka==100 then QQA="rube/levels/long_winter_blocks.rube" zxcz() end
if hjka==101 then QQA="rube/levels/marshland_cup_blocks.rube" zxcz() end
if hjka==102 then QQA="rube/levels/mine_blocks.rube" zxcz() end
if hjka==103 then QQA="rube/levels/mine_blocks_2.rube" zxcz() end
if hjka==104 then QQA="rube/levels/mine_distance_blocks.rube" zxcz() end
if hjka==105 then QQA="rube/levels/moon_blocks.rube" zxcz() end
if hjka==106 then QQA="rube/levels/moon_distance_blocks.rube" zxcz() end
if hjka==107 then QQA="rube/levels/moon_tricks_blocks.rube" zxcz() end
if hjka==108 then QQA="rube/levels/mountain_01_blocks.rube" zxcz() end
if hjka==109 then QQA="rube/levels/mountain_02_blocks.rube" zxcz() end
if hjka==110 then QQA="rube/levels/mountain_06_blocks.rube" zxcz() end
if hjka==111 then QQA="rube/levels/mountain_07_blocks.rube" zxcz() end
if hjka==112 then QQA="rube/levels/mountain_blocks.rube" zxcz() end
if hjka==113 then QQA="rube/levels/mountain_bridges_blocks.rube" zxcz() end
if hjka==114 then QQA="rube/levels/mountain_cup_01_blocks.rube" zxcz() end
if hjka==115 then QQA="rube/levels/mountain_distance_blocks.rube" zxcz() end
if hjka==116 then QQA="rube/levels/mountain_downhill_01.rube" zxcz() end
if hjka==117 then QQA="rube/levels/nationalpark_distance.rube" zxcz() end
if hjka==118 then QQA="rube/levels/nationalpark_distance_blocks.rube" zxcz() end
if hjka==119 then QQA="rube/levels/paradisebay.rube" zxcz() end
if hjka==120 then QQA="rube/levels/potatofield.rube" zxcz() end
if hjka==121 then QQA="rube/levels/rocky_road_blocks.rube" zxcz() end
if hjka==122 then QQA="rube/levels/rocky_road_blocks_verse3.rube" zxcz() end
if hjka==123 then QQA="rube/levels/roofs_01_blocks.rube" zxcz() end
if hjka==124 then QQA="rube/levels/roofs_02_blocks.rube" zxcz() end
if hjka==125 then QQA="rube/levels/rookie_cup_blocks.rube" zxcz() end
if hjka==126 then QQA="rube/levels/rookie_forest_blocks.rube" zxcz() end
if hjka==127 then QQA="rube/levels/route66_distance_blocks.rube" zxcz() end
if hjka==128 then QQA="rube/levels/route66_fast_blocks.rube" zxcz() end
if hjka==129 then QQA="rube/levels/route66_slow_blocks.rube" zxcz() end
if hjka==130 then QQA="rube/levels/savanna_cup.rube" zxcz() end
if hjka==131 then QQA="rube/levels/savanna_distance_blocks.rube" zxcz() end
if hjka==132 then QQA="rube/levels/skill_blocks.rube" zxcz() end
if hjka==133 then QQA="rube/levels/speedball_blocks.rube" zxcz() end
if hjka==134 then QQA="rube/levels/spring_falls_cup.rube" zxcz() end
if hjka==135 then QQA="rube/levels/spring_falls_cup_03.rube" zxcz() end
if hjka==136 then QQA="rube/levels/stormrider_cup.rube" zxcz() end
if hjka==137 then QQA="rube/levels/testarea_blocks.rube" zxcz() end
if hjka==138 then QQA="rube/levels/test_blocks.rube" zxcz() end
if hjka==139 then QQA="rube/levels/test_blocks_deform.rube" zxcz() end
if hjka==140 then QQA="rube/levels/test_cup_blocks.rube" zxcz() end
if hjka==141 then QQA="rube/levels/test_water_blocks.rube" zxcz() end
if hjka==142 then QQA="rube/levels/thunderstorm_avoid_event.rube" zxcz() end
if hjka==143 then QQA="rube/levels/trailerpark_cup.rube" zxcz() end
if hjka==144 then QQA="rube/levels/trailerpark_distance_blocks.rube" zxcz() end
if hjka==145 then QQA="rube/levels/tunnels_blocks.rube" zxcz() end
if hjka==146 then QQA="rube/levels/tutorial_6.rube" zxcz() end
if hjka==147 then QQA="rube/levels/tutorial_blocks.rube" zxcz() end
if hjka==148 then QQA="rube/levels/underwater_cup_1.rube" zxcz() end
if hjka==149 then QQA="rube/levels/underwater_cup_blocks.rube" zxcz() end
if hjka==150 then QQA="rube/levels/underwater_distance_blocks.rube" zxcz() end
if hjka==151 then QQA="rube/levels/underwater_kraken_cup_1.rube" zxcz() end
if hjka==152 then QQA="rube/levels/underwater_long_cup_1.rube" zxcz() end
if hjka==153 then QQA="rube/levels/uphill_cup_blocks.rube" zxcz() end
if hjka==154 then QQA="rube/levels/water_run_blocks.rube" zxcz() end
if hjka==155 then QQA="rube/levels/wheelie_blocks.rube" zxcz() end
if hjka==156 then QQA="rube/levels/winter_cup_blocks.rube" zxcz() end
if hjka==157 then QQA="rube/levels/winter_cup_blocks_easy.rube" zxcz() end
if hjka==158 then QQA="rube/levels/winter_cup_blocks_tuningparts.rube" zxcz() end
if hjka==159 then QQA="rube/levels/winter_distance_blocks.rube" zxcz() end
if hjka==160 then QQA="rube/levels/winter_hard_distance_blocks.rube" zxcz() end
if hjka==161 then QQA="rube/levels/workshop_cup_blocks.rube" zxcz() end
if hjka==162 then QQA="rube/levels/workshop_distance_blocks.rube" zxcz() end
if hjka==163 then QQA="rube/levels/workshop_factory_cup_blocks.rube" zxcz() end
if hjka==164 then QQA="rube/attachments/bobble-head.rube" zxcz() end
if hjka==165 then QQA="rube/attachments/double-exhaust.rube" zxcz() end
if hjka==166 then QQA="rube/attachments/exhaust-extreme.rube" zxcz() end
if hjka==167 then QQA="rube/attachments/exhaust-long.rube" zxcz() end
if hjka==168 then QQA="rube/attachments/exhaust-turned.rube" zxcz() end
if hjka==169 then QQA="rube/attachments/horn.rube" zxcz() end
if hjka==170 then QQA="rube/attachments/mirror-green.rube" zxcz() end
if hjka==171 then QQA="rube/attachments/rocket.rube" zxcz() end
if hjka==172 then QQA="rube/elements/adv_token_stack01.rube" zxcz() end
if hjka==173 then QQA="rube/elements/coin_stack01.rube" zxcz() end
if hjka==174 then QQA="rube/elements/coin_stack02.rube" zxcz() end
if hjka==175 then QQA="rube/elements/dual_room.rube" zxcz() end
if hjka==176 then QQA="rube/elements/gemcoin_stack01.rube" zxcz() end
if hjka==177 then QQA="rube/elements/gemcoin_stack02.rube" zxcz() end
if hjka==178 then QQA="rube/elements/gem_stack01.rube" zxcz() end
if hjka==179 then QQA="rube/elements/gem_stack02.rube" zxcz() end
if hjka==180 then QQA="rube/elements/single_adv_token.rube" zxcz() end
if hjka==181 then QQA="rube/elements/single_coin.rube" zxcz() end
if hjka==182 then QQA="rube/elements/single_diamond1.rube" zxcz() end
if hjka==183 then QQA="rube/elements/single_diamond2.rube" zxcz() end
if hjka==184 then QQA="rube/elements/single_diamond3.rube" zxcz() end
if hjka==185 then QQA="rube/elements/single_room.rube" zxcz() end
if hjka==186 then QQA="rube/equipment/helipack.rube" zxcz() end
if hjka==187 then QQA="rube/driver.rube" zxcz() end
if hjka==188 then QQA="rube/driver_naked.rube" zxcz() end
if hjka==189 then QQA="rube/driver_sitting.rube" zxcz() end
if hjka==190 then QQA="rube/driver-hat.rube" zxcz() end
if hjka==191 then QQA="rube/levels/ufo_team_event_blocks.rube" zxcz() end
if hjka==192 then QQA="rube/levels/thunder_event_blocks.rube" zxcz() end
if hjka==193 then QQA="rube/levels/halloween_event_blocks_3_r.rube" zxcz() end
if hjka==194 then QQA="rube/levels/angry_halloween_event.rube" zxcz() end
    end
end
function DEESA()
AAA = v[ZZCR].address
QQQQW=gg.getValues({{address = v[ZZCR].address-16, flags = gg.TYPE_DWORD}})

WSS = QQQQW[1].value
VVC=0
VVB=0

if WSS ==37 then
else
ZZCR=ZZCR+1
DEESA()
end
end
function DEES()
if ZERRDD==1 then
DEESA()
else
DEESX()
end
end
function DEESXAA()
AAA = jg[1].address + 0x1C0 +8
GTA=gg.getValues({{address = AAA, flags = gg.TYPE_DWORD}})
ZZCR=ZZCR+1
GTT = GTA[1].value
if GTT==49 then AAA = jg[1].address + 0x1C0
AAA=AAA+8
gg.clearResults() else DEESX() end
end
function DEESX()
gg.clearResults()
AAA = v[ZZCR].address
gg.searchNumber(""..AAA.."", gg.TYPE_QWORD, false, gg.SIGN_EQUAL, 0, -1)
jg=gg.getResults(1)
sl=gg.getResultCount()

if sl==1 then
DEESXAA()

else
ZZCR=ZZCR+1
DEESX()
end
end
function zxcz()
ZZCR=1
gg.clearResults()
GYYYD=string.len(QQA)
gg.setRanges(CZGZGZG)
gg.clearList()
gg.clearResults()
gg.setVisible(false)
gg.clearList()
gg.setVisible(false)
gg.searchNumber(""..DFK.."", gg.TYPE_BYTE)
gg.searchNumber(":json/", gg.TYPE_BYTE)
gg.searchNumber(":j", gg.TYPE_BYTE)
v = gg.getResults(10000)
DEESX()
gg.setVisible(false)

XCD=gg.getValues({{address = AAA+16, flags = gg.TYPE_QWORD}})
gg.setValues({{address = AAA+8,flags = gg.TYPE_DWORD,value = GYYYD}})
gg.clearList()
SDREE = XCD[1].value
gg.clearResults()
gg.startFuzzy(gg.TYPE_BYTE, SDREE, SDREE+48)
gg.getResults(GYYYD)
gg.editAll(":"..QQA.."", gg.TYPE_BYTE)
gg.setVisible(false)

gg.toast("✅")
gg.clearResults()
gg.clearList()
ZERRDD=0
end

-- ═══════════════════════════════════════════════════════════════
--  MAIN MENU V3.4 (Đã tích hợp Vô hạn nhiên liệu)
-- ═══════════════════════════════════════════════════════════════
function MainMenu()
    gg.setVisible(false)
    local menu = {
        "🔥 Auto Win (ARMV8)",
        "🎭 Fake Unlock",
        "🔧 Free Upgrade",
        "👹 Force Boss (1.76.1)",
        "🎭 Fake VIP",
        "⚡ Upgrade Parts Without Scrap",
        "🚀 Fly Hack",
        "🚗 Unlock Any Vehicle",
        "🛣️ Tracks Editor",
        "🏎️ Vehicle Hacks",
        "⚡ Free Chests",
        "💳 Free Purchases",
        "🧰 Adventure Chest Hack V1",
        "💎 Debug Mode",
        "⭐ VIP Pass (Real)",
        "🚀 Max Vehicles",
        "⭐ Max Mastery",
        "🔩 Max Parts",
        "💰 Set Fuel & Coins",
        "⛽ Vô hạn nhiên liệu (In-game)",
        "🕹️ Mastery & Cups",
        "🎯 Team Event Menu",
        "🎉 Event Menu",
        "🚗 Vehicle Speed",
        "👁️ Global Vision",
        "👤 Player Data",
        "🔩 Super Parts Custom",
        "🎉 Events Shop",
        "🛞 Downforce",
        "🖼️ Mở khóa Background gara ẩn",
        "🎨 Creative (Any Theme + Hidden)",
        "🗺️ Swap Map",
        "ℹ️ About",
        "❌ Exit"
    }
    local choice = gg.choice(menu, nil, "AɴнDᴇᴘZᴀı V3.4")
    if not choice then return end
    if choice == 1 then autoWin()
    elseif choice == 2 then fakeUnlock()
    elseif choice == 3 then freeUpgrade()
    elseif choice == 4 then forceBoss()
    elseif choice == 5 then FakeVIPMenu()
    elseif choice == 6 then upgradeWithoutScrap()
    elseif choice == 7 then flyHack()
    elseif choice == 8 then unlockAnyVehicle()
    elseif choice == 9 then tracksEditor()
    elseif choice == 10 then vehicleHacksMenu()
    elseif choice == 11 then freeChests()
    elseif choice == 12 then freePurchases()
    elseif choice == 13 then advChestHackV1()
    elseif choice == 14 then debugMode()
    elseif choice == 15 then vipPassFunc()
    elseif choice == 16 then MaxVehicles()
    elseif choice == 17 then MaxMastery()
    elseif choice == 18 then MaxParts()
    elseif choice == 19 then SetFuelCoins()
    elseif choice == 20 then UnlimitedInGameFuel()
    elseif choice == 21 then MasteryCupsMenu()
    elseif choice == 22 then TeamEventMenu()
    elseif choice == 23 then EventMenu()
    elseif choice == 24 then VehicleSpeedMenu()
    elseif choice == 25 then GlobalVisionMenu()
    elseif choice == 26 then ADZ_PlayerMenu()
    elseif choice == 27 then ADZ_SuperPartsMenu()
    elseif choice == 28 then ADZ_EventsShopMenu()
    elseif choice == 29 then ADZ_DownforceMenu()
    elseif choice == 30 then ADZ_UnlockHiddenGarageBg()
    elseif choice == 31 then CreativeMenu()
    elseif choice == 32 then SwapMapMenu()
    elseif choice == 33 then About()
    elseif choice == 34 then
        ShowPrintMenu()
    end
end

-- ═══════════════════════════════════════════════════════════════
--  KHỞI ĐỘNG
-- ═══════════════════════════════════════════════════════════════
showLoadingStep("🚀 AɴнDᴇᴘZᴀı V3.4 - Kiểm tra ứng dụng...", 10, 120)
checkBlocked()

showLoadingStep("⚙️ Kiểm tra GameGuardian 101.1...", 25, 120)
checkGG()

showLoadingStep("🎮 Kiểm tra HCR2...", 40, 120)
checkHCR2()

showLoadingStep("📚 Đọc libcocos2dcpp.so & kiến trúc...", 55, 120)
getLib()
archType = detectArch()
gameVersion = getHCR2Version()

if archType == 3 or archType == 4 then
    gg.alert("⚠️ Phát hiện Emulator!\nAuto Win / Fake Unlock / Free Upgrade / Force Boss sẽ không hoạt động.")
end

selectRange()

showLoadingStep("🧹 Dọn dẹp bộ nhớ tạm...", 70, 100)
gg.clearResults()
gg.clearList()
gg.setRanges(RANGE_VALUE)

showLoadingStep("🔍 Đang quét GameStatus...", 85, 120)
local foundStatus = findGameStatus()

showLoadingStep("✅ Hoàn tất khởi động!", 100, 300)
if not foundStatus then
    gg.toast("⚠️ Chưa tìm thấy GameStatus (vào Garage để fix)")
end

MainMenu()

while true do
    if gg.isVisible(true) then
        gg.setVisible(false)
        MainMenu()
    end
    gg.sleep(100)
end
