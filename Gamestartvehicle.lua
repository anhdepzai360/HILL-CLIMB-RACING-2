local gameStartVehicleData = {
    items = {},
    lastScan = 0,
    formattedBlock = ""
}

local function buildGameStartVehicleBlock(items)
    local names = {}
    local rows  = {}

    for i, entry in ipairs(items) do
        table.insert(names, string.format("%q", string.format("GameStartVeh #%d (0x%X)", i, entry.address)))
        local rowStr = string.format("%d;%d;%d;%d", entry.v0 or 0, entry.v1 or 0, entry.v2 or 0, entry.v3 or 0)
        table.insert(rows, string.format("%q", rowStr))
    end

    return "GameStatusVehicles = {\n  {\n    "
        .. table.concat(names, ",\n    ")
        .. "\n  },\n  {\n    "
        .. table.concat(rows, ",\n    ")
        .. "\n  }\n}"
end

local function scanGameStartVehicle(autoCopyForPastebin)
    local prevVisible = gg.isVisible()
    gg.setVisible(false)
    gg.clearResults()

    local targetRange = (type(userSelectedRange) == "number" and userSelectedRange > 0)
        and userSelectedRange
        or gg.REGION_C_ALLOC

    gg.setRanges(targetRange)

    -- Quét dãy 8 giá trị DWORD liền tiếp (bước nhảy 29 bytes trong nhóm tìm kiếm GG)
    local searchPattern = string.rep("0;", 7) .. "0::29"
    gg.searchNumber(searchPattern, gg.TYPE_DWORD, false, gg.SIGN_EQUAL, 0, -1, 500)

    local totalFound = gg.getResultsCount()
    if totalFound == 0 then
        gg.clearResults()
        gg.setVisible(prevVisible)
        gg.toast("❌ Không tìm thấy gamestartvehicle")
        return nil
    end

    local rawResults = gg.getResults(math.min(totalFound, 200))
    gg.clearResults()

    local candidates = {}
    for _, resItem in ipairs(rawResults) do
        local addr = resItem.address
        if type(addr) == "number" and addr > 0 then
            local vals = gg.getValues({
                { address = addr,       flags = gg.TYPE_DWORD },
                { address = addr + 0x4, flags = gg.TYPE_DWORD },
                { address = addr + 0x8, flags = gg.TYPE_DWORD },
                { address = addr + 0xC, flags = gg.TYPE_DWORD },
            })

            if vals and vals[1] and vals[2] and vals[3] and vals[4] then
                local v0 = vals[1].value or 0
                local v1 = vals[2].value or 0
                local v2 = vals[3].value or 0
                local v3 = vals[4].value or 0

                -- Loại bỏ các khối toàn 0 không mang dữ liệu khởi tạo
                if (v0 ~= 0 or v1 ~= 0 or v2 ~= 0 or v3 ~= 0) then
                    table.insert(candidates, {
                        address = addr,
                        v0 = v0,
                        v1 = v1,
                        v2 = v2,
                        v3 = v3,
                    })
                end
            end
        end
    end

    gg.setVisible(prevVisible)

    if #candidates == 0 then
        gg.toast("⚠️ Có kết quả thô nhưng không lọc được ứng viên hợp lệ")
        return nil
    end

    gameStartVehicleData.items = candidates
    gameStartVehicleData.lastScan = os.time()
    gameStartVehicleData.formattedBlock = buildGameStartVehicleBlock(candidates)

    if autoCopyForPastebin then
        gg.copyText(gameStartVehicleData.formattedBlock)
        gg.toast(string.format("✅ Quét xong %d mục & đã copy cho Pastebin", #candidates))
    else
        gg.toast(string.format("✅ Quét xong %d mục gamestartvehicle", #candidates))
    end

    return candidates
end
