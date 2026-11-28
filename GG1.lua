if not gg then
    print("❌ Lỗi: Script này phải chạy bên trong GameGuardian!")
    return
end

local KEY_LEN = 20

local function printFinish(statusText, detailText)
    print("==========================================")
    print("🏁 KẾT THÚC SCRIPT — " .. tostring(statusText or "HOÀN TẤT"))
    if detailText and detailText ~= "" then
        print(detailText)
    end
    print("🇦 🇳 🇭 🇩 🇪 🇵 🇿 🇦 🇮 — by @anhdepzai")
    print("==========================================")
end

local function getDefaultHeader(verTitle)
    return [[

-- ==========================================

-- 🇦 🇳 🇭 🇩 🇪 🇵 🇿 🇦 🇮

-- Zalo: 0334741203

-- Made by ANHDEPZAI 🇻🇳 (anh2k9VN)

-- CONTACT & SUPPORT: Telegram

-- Telegram chat: t.me/anhdepzai360

--Telegram: t.me/anhdepzai36

--Tik tok: https://www.tiktok.com/@anh_dep_zai36?_r=1&_t=ZS-9BTutYlqnhM

--Discord: https://discord.gg/sJdZuHVf
┌───────────☄◌☄───────────┐
  𝙼𝚊𝚍𝚎 𝚏𝚘𝚛: 𝙷𝚒𝚕𝚕 𝙲𝚕𝚒𝚖𝚋 𝚁𝚊𝚌𝚒𝚗𝚐 𝟸
        𝙶𝚊𝚖𝚎 𝚟𝚎𝚛𝚜𝚒𝚘𝚗: 1.76.1
      𝙴𝚗𝚌𝚛𝚢𝚙𝚝𝚒𝚘𝚗 𝚏𝚒𝚕𝚎 ]] .. verTitle .. [[

       𝙳𝚎𝚟𝚎𝚕𝚘𝚙𝚎𝚛: 𝙰𝙽𝙷𝙳𝙴𝙿𝚉𝙰𝙸
          𝙼𝚊𝚍𝚎 𝙸𝚗 𝚅𝚒𝚎𝚝𝚗𝚊𝚖
└───────────☄◌☄───────────┘

-- ==========================================
]]
end

-- ---------- Tiện ích chung ----------
local function getAutoOutputPath(inputPath, tag, multi)
    local suffix = multi and ("_" .. tag .. "_✅.lua") or "_✅.lua"
    if not inputPath or inputPath == "" then
        return "/storage/emulated/0/Download/Script_Protected_" .. tag .. ".lua"
    end
    if inputPath:sub(-4):lower() == ".lua" then
        return inputPath:sub(1, -5) .. suffix
    end
    return inputPath .. suffix
end

local function randomBytes(n)
    math.randomseed(os.time() + math.floor(os.clock() * 100000))
    for _ = 1, 7 do math.random() end
    local t = {}
    for i = 1, n do t[i] = math.random(1, 255) end
    return t
end

local function toEscaped(bytes)
    local parts = {}
    for i = 1, #bytes do
        parts[i] = string.format("\\%03d", bytes[i])
    end
    return table.concat(parts)
end

-- ---------- Cấu hình riêng từng kiểu Lua từ 5 file gốc ----------
local LUA_PROFILES = {
    ["5.1"] = {
        label = "Lua 5.1",
        tag = "51",
        verTitle = "𝚕𝚞𝚊",
        headerText = getDefaultHeader("𝚕𝚞𝚊"),
        compileSource = function(src)
            local loadFn = loadstring or load
            return loadFn(src)
        end,
        compileLoader = function(code)
            local loadFn = loadstring or load
            return loadFn(code)
        end,
        bxor = function(a, b)
            if bit32 and bit32.bxor then return bit32.bxor(a, b) end
            if bit and bit.bxor then return bit.bxor(a, b) end
            local r = 0
            for i = 0, 7 do
                local p = 2 ^ i
                if ((a / p) % 2 >= 1) ~= ((b / p) % 2 >= 1) then r = r + p end
            end
            return r
        end,
        body = [[
local _x=function(a,b)
if bit32 and bit32.bxor then return bit32.bxor(a,b) end
if bit and bit.bxor then return bit.bxor(a,b) end
local r=0
for i=0,7 do local p=2^i
if ((a/p)%2>=1)~=((b/p)%2>=1) then r=r+p end end
return r end
local _n,_o,_h=#_K,{},0
for i=1,#_B do
local _kb=_K:byte(((i-1)%_n)+1)
local _ks=_K:byte(((i+_S-1)%_n)+1)
local k=_x(_x(_kb,(i*23+_S*3)%256),_ks)
local c=_x(_B:byte(i),k)
_o[i]=string.char(c)
_h=(_h*137+c)%2147483647
end
if _h~=_C then error("Script bi loi hoac bi sua doi") end
local _f,_e=(loadstring or load)(table.concat(_o))
if not _f then error(tostring(_e)) end
return _f(...)
]],
        doneMsg = function(outputPath, size)
            return "✅ MÃ HÓA THÀNH CÔNG!\n\n📁 " .. outputPath
                .. "\n📦 Kích thước: " .. size .. " byte"
                .. "\n✔️"
                .. "\n\n—꧁ by @anhdepzai ꧂—"
        end
    },

    ["5.2"] = {
        label = "Lua 5.2",
        tag = "52",
        verTitle = "𝚕𝚞𝚊 𝟻.𝟸",
        headerText = getDefaultHeader("𝚕𝚞𝚊 𝟻.𝟸"),
        compileSource = function(src)
            local load52 = load
            return load52(src, "=(load)", "t", _ENV)
        end,
        compileLoader = function(code)
            local load52 = load
            return load52(code, "=(loader)", "t", _ENV)
        end,
        bxor = function(a, b)
            if bit32 and bit32.bxor then
                return bit32.bxor(a, b)
            end
            local r = 0
            for i = 0, 7 do
                local p = 2 ^ i
                if ((a / p) % 2 >= 1) ~= ((b / p) % 2 >= 1) then r = r + p end
            end
            return r
        end,
        body = [[
local _x = (bit32 and bit32.bxor) or function(a,b)
local r=0
for i=0,7 do local p=2^i
if ((a/p)%2>=1)~=((b/p)%2>=1) then r=r+p end end
return r end
local _n,_o,_h=#_K,{},0
for i=1,#_B do
local _kb=_K:byte(((i-1)%_n)+1)
local _ks=_K:byte(((i+_S-1)%_n)+1)
local k=_x(_x(_kb,(i*23+_S*3)%256),_ks)
local c=_x(_B:byte(i),k)
_o[i]=string.char(c)
_h=(_h*137+c)%2147483647
end
if _h~=_C then error("Script bi loi hoac bi sua doi") end
local _f,_e=load(table.concat(_o),"=(load)","bt",_ENV)
if not _f then error(tostring(_e)) end
return _f(...)
]],
        doneMsg = function(outputPath, size)
            return "✅ MÃ HÓA LUA 5.2 THÀNH CÔNG!\n\n📁 " .. outputPath
                .. "\n📦 Kích thước: " .. size .. " byte"
                .. "\n✔️"
                .. "\n\n—꧁ by @anhdepzai ꧂—"
        end
    },

    ["5.3"] = {
        label = "Lua 5.3",
        tag = "53",
        verTitle = "𝚕𝚞𝚊 𝟻.𝟹",
        headerText = getDefaultHeader("𝚕𝚞𝚊 𝟻.𝟹"),
        compileSource = function(src)
            local load53 = load
            return load53(src, "=(load)", "t", _ENV)
        end,
        compileLoader = function(code)
            local load53 = load
            return load53(code, "=(loader)", "t", _ENV)
        end,
        bxor = (function()
            local load53 = load
            local fn = load53 and load53("return function(a, b) return (a ~ b) & 0xFF end")
            if fn then
                return fn()
            elseif bit32 and bit32.bxor then
                return function(a, b) return bit32.bxor(a, b) % 256 end
            else
                return function(a, b)
                    local r = 0
                    for i = 0, 7 do
                        local p = 2 ^ i
                        if ((a / p) % 2 >= 1) ~= ((b / p) % 2 >= 1) then r = r + p end
                    end
                    return r
                end
            end
        end)(),
        body = [[
local _x = (function()
    local f = load("return function(a,b) return (a~b)&0xFF end")
    if f then return f() end
    if bit32 and bit32.bxor then return function(a,b) return bit32.bxor(a,b)%256 end end
    return function(a,b)
        local r=0
        for i=0,7 do local p=2^i
        if ((a/p)%2>=1)~=((b/p)%2>=1) then r=r+p end end
        return r
    end
end)()
local _n,_o,_h=#_K,{},0
for i=1,#_B do
local _kb=_K:byte(((i-1)%_n)+1)
local _ks=_K:byte(((i+_S-1)%_n)+1)
local k=_x(_x(_kb,(i*23+_S*3)%256),_ks)
local c=_x(_B:byte(i),k)
_o[i]=string.char(c)
_h=(_h*137+c)%2147483647
end
if _h~=_C then error("Script bi loi hoac bi sua doi") end
local _f,_e=load(table.concat(_o),"=(load)","bt",_ENV)
if not _f then error(tostring(_e)) end
return _f(...)
]],
        doneMsg = function(outputPath, size)
            return "✅ MÃ HÓA LUA 5.3 THÀNH CÔNG!\n\n📁 " .. outputPath
                .. "\n📦 Kích thước: " .. size .. " byte"
                .. "\n✔️"
                .. "\n\n—꧁ by @anhdepzai ꧂—"
        end
    },

    ["5.4"] = {
        label = "Lua 5.4",
        tag = "54",
        verTitle = "𝚕𝚞𝚊 𝟻.𝟺",
        headerText = getDefaultHeader("𝚕𝚞𝚊 𝟻.𝟺"),
        compileSource = function(src)
            local load54 = load
            return load54(src, "=(load)", "t", _ENV)
        end,
        compileLoader = function(code)
            local load54 = load
            return load54(code, "=(loader)", "t", _ENV)
        end,
        bxor = (function()
            local load54 = load
            local fn = load54 and load54("return function(a, b) return (a ~ b) & 0xFF end")
            if fn then
                return fn()
            elseif bit32 and bit32.bxor then
                return function(a, b) return bit32.bxor(a, b) % 256 end
            else
                return function(a, b)
                    local r = 0
                    for i = 0, 7 do
                        local p = 2 ^ i
                        if ((a / p) % 2 >= 1) ~= ((b / p) % 2 >= 1) then r = r + p end
                    end
                    return r
                end
            end
        end)(),
        body = [[
local _x = (function()
    local f = load("return function(a,b) return (a~b)&0xFF end")
    if f then return f() end
    if bit32 and bit32.bxor then return function(a,b) return bit32.bxor(a,b)%256 end end
    return function(a,b)
        local r=0
        for i=0,7 do local p=2^i
        if ((a/p)%2>=1)~=((b/p)%2>=1) then r=r+p end end
        return r
    end
end)()
local _n,_o,_h=#_K,{},0
for i=1,#_B do
local _kb=_K:byte(((i-1)%_n)+1)
local _ks=_K:byte(((i+_S-1)%_n)+1)
local k=_x(_x(_kb,(i*23+_S*3)%256),_ks)
local c=_x(_B:byte(i),k)
_o[i]=string.char(c)
_h=(_h*137+c)%2147483647
end
if _h~=_C then error("Script bi loi hoac bi sua doi") end
local _f,_e=load(table.concat(_o),"=(load)","bt",_ENV)
if not _f then error(tostring(_e)) end
return _f(...)
]],
        doneMsg = function(outputPath, size)
            return "✅ MÃ HÓA LUA 5.4 THÀNH CÔNG!\n\n📁 " .. outputPath
                .. "\n📦 Kích thước: " .. size .. " byte"
                .. "\n✔️"
                .. "\n\n—꧁ by @anhdepzai ꧂—"
        end
    },

    ["5.5"] = {
        label = "Lua 5.5",
        tag = "55",
        verTitle = "𝚕𝚞𝚊 𝟻.𝟻",
        headerText = getDefaultHeader("𝚕𝚞𝚊 𝟻.𝟻"),
        compileSource = function(src)
            local load55 = load
            return load55(src, "=(load)", "t", _ENV)
        end,
        compileLoader = function(code)
            local load55 = load
            return load55(code, "=(loader)", "t", _ENV)
        end,
        bxor = (function()
            local load55 = load
            local fn = load55 and load55("return function(a, b) return (a ~ b) & 0xFF end")
            if fn then
                return fn()
            elseif bit32 and bit32.bxor then
                return function(a, b) return bit32.bxor(a, b) % 256 end
            else
                return function(a, b)
                    local r = 0
                    for i = 0, 7 do
                        local p = 2 ^ i
                        if ((a / p) % 2 >= 1) ~= ((b / p) % 2 >= 1) then r = r + p end
                    end
                    return r
                end
            end
        end)(),
        body = [[
local _x = (function()
    local f = load("return function(a,b) return (a~b)&0xFF end")
    if f then return f() end
    if bit32 and bit32.bxor then return function(a,b) return bit32.bxor(a,b)%256 end end
    return function(a,b)
        local r=0
        for i=0,7 do local p=2^i
        if ((a/p)%2>=1)~=((b/p)%2>=1) then r=r+p end end
        return r
    end
end)()
local _n,_o,_h=#_K,{},0
for i=1,#_B do
local _kb=_K:byte(((i-1)%_n)+1)
local _ks=_K:byte(((i+_S-1)%_n)+1)
local k=_x(_x(_kb,(i*23+_S*3)%256),_ks)
local c=_x(_B:byte(i),k)
_o[i]=string.char(c)
_h=(_h*137+c)%2147483647
end
if _h~=_C then error("Script bi loi hoac bi sua doi") end
local _f,_e=load(table.concat(_o),"=(load)","bt",_ENV)
if not _f then error(tostring(_e)) end
return _f(...)
]],
        doneMsg = function(outputPath, size)
            return "✅ MÃ HÓA LUA 5.5 THÀNH CÔNG!\n\n📁 " .. outputPath
                .. "\n📦 Kích thước: " .. size .. " byte"
                .. "\n✔️"
                .. "\n\n—꧁ by @anhdepzai ꧂—"
        end
    }
}

local function stepMask(bxorFn, keyBytes, i, salt)
    local n = #keyBytes
    local kBase = keyBytes[((i - 1) % n) + 1]
    local kShift = keyBytes[((i + salt - 1) % n) + 1]
    local modMix = (i * 23 + salt * 3) % 256
    return bxorFn(bxorFn(kBase, modMix), kShift)
end

local function decryptBytes(bxorFn, keyBytes, encBytes, salt)
    local out, h = {}, 0
    for i = 1, #encBytes do
        local k = stepMask(bxorFn, keyBytes, i, salt)
        local c = bxorFn(encBytes[i], k)
        out[i] = c
        h = (h * 137 + c) % 2147483647
    end
    return out, h
end

-- ---------- Mã hóa chính theo kiểu Lua ----------
local function encryptWithProfile(sourceCode, outputPath, profile)
    if sourceCode:sub(1, 3) == "\239\187\191" then
        sourceCode = sourceCode:sub(4)
    end

    local func, syntaxErr = profile.compileSource(sourceCode)
    if not func then
        gg.alert("❌ Code gốc bị lỗi cú pháp " .. profile.label .. ":\n\n" .. tostring(syntaxErr))
        return false
    end

    local ok, raw = pcall(string.dump, func, true)
    if not ok or not raw then ok, raw = pcall(string.dump, func) end
    if not ok or not raw then
        gg.alert("❌ Không thể biên dịch sang Bytecode " .. profile.label .. "!")
        return false
    end

    local key = randomBytes(KEY_LEN)
    local salt = math.random(1, 255)
    local rawBytes, enc, hash = {}, {}, 0
    for i = 1, #raw do
        local b = raw:byte(i)
        rawBytes[i] = b
        local k = stepMask(profile.bxor, key, i, salt)
        enc[i] = profile.bxor(b, k)
        hash = (hash * 137 + b) % 2147483647
    end

    local back, backHash = decryptBytes(profile.bxor, key, enc, salt)
    if backHash ~= hash or #back ~= #rawBytes then
        gg.alert("❌ Tự kiểm thử thất bại!")
        return false
    end

    local headerConst = string.format("local _INFO = %q\n", profile.headerText)
    local vars = "local _K,_B,_S,_C=\"" .. toEscaped(key) .. "\",\""
        .. toEscaped(enc) .. "\"," .. salt .. "," .. hash .. "\n"

    local loaderCode = headerConst .. vars .. profile.body
    local loaderFunc, lerr = profile.compileLoader(loaderCode)
    if not loaderFunc then
        gg.alert("❌ Loader bị lỗi:\n" .. tostring(lerr))
        return false
    end

    local content = loaderCode
    local dok, dres = pcall(string.dump, loaderFunc, true)
    if not dok or not dres then dok, dres = pcall(string.dump, loaderFunc) end
    if dok and dres then content = dres end

    local out, err = io.open(outputPath, "wb")
    if not out then
        gg.alert("❌ Lỗi tạo file:\n" .. tostring(err))
        return false
    end
    out:write(content)
    out:close()

    gg.alert(profile.doneMsg(outputPath, #content))
    return true
end

local function main()
    if gg.isVisible() then gg.setVisible(false) end

    local p = gg.prompt({
        "Chọn File",
        "Lua 5.1",
        "Lua 5.2",
        "Lua 5.3",
        "Lua 5.4",
        "Lua 5.5"
    }, {
        "/storage/emulated/0/by @anhdepzai.lua",
        false,
        false,
        false,
        false,
        false
    }, {
        "file",
        "checkbox",
        "checkbox",
        "checkbox",
        "checkbox",
        "checkbox"
    })

    if not p or not p[1] or p[1] == "" then
        printFinish("ĐÃ HỦY", "Người dùng đã hủy hoặc chưa chọn file.")
        return
    end

    local selected = {}
    if p[2] then table.insert(selected, "5.1") end
    if p[3] then table.insert(selected, "5.2") end
    if p[4] then table.insert(selected, "5.3") end
    if p[5] then table.insert(selected, "5.4") end
    if p[6] then table.insert(selected, "5.5") end

    if #selected == 0 then
        gg.alert("⚠️ Vui lòng tick ít nhất 1 kiểu Lua!")
        printFinish("DỪNG LẠI", "Chưa chọn kiểu Lua nào để mã hóa.")
        return
    end

    local f, err = io.open(p[1], "rb")
    if not f then
        gg.alert("❌ Không mở được file gốc: " .. tostring(err))
        printFinish("LỖI MỞ FILE", "File gốc: " .. tostring(p[1]) .. " | Lỗi: " .. tostring(err))
        return
    end
    local src = f:read("*a")
    f:close()

    local multi = (#selected > 1)
    local successList = {}
    local failList = {}

    for _, verKey in ipairs(selected) do
        local prof = LUA_PROFILES[verKey]
        local outPath = getAutoOutputPath(p[1], prof.tag, multi)
        local ok = encryptWithProfile(src, outPath, prof)
        if ok then
            table.insert(successList, prof.label .. " -> " .. outPath)
            print("✅ Đã xuất [" .. prof.label .. "]: " .. outPath)
        else
            table.insert(failList, prof.label)
            print("❌ Thất bại [" .. prof.label .. "]")
        end
    end

    local summary = "Tổng chọn: " .. #selected .. " | Thành công: " .. #successList .. " | Lỗi: " .. #failList
    if #successList > 0 then
        summary = summary .. "\nFile đã tạo:\n - " .. table.concat(successList, "\n - ")
    end
    printFinish(#successList > 0 and "MÃ HÓA XONG" or "KHÔNG THÀNH CÔNG", summary)
end

main()
