--[[
================================================================================
    MA3 PDF Exporter V2
    Export fixture patch data and statistics from grandMA3 to PDF
    
    GitHub: https://github.com/MayBeLinux
    Author: LumiArt-Studio
================================================================================
]]--

--------------------------------------------------------------------------------
-- Configuration & Constants
--------------------------------------------------------------------------------

local Config = {
    -- PDF Settings
    PDF_VERSION = "%PDF-1.4\n",
    PAGE_WIDTH = 612,
    PAGE_HEIGHT = 792,
    MARGIN = 50,
    
    -- Table Layout
    MAX_ROWS_PER_PAGE = 17,
    ROW_HEIGHT = 35,
    HEADER_Y_FIRST_PAGE = 650,
    HEADER_Y_OTHER_PAGES = 760,
    START_X = 50,
    COLUMN_OFFSETS = {-30, 25, 100, 150, 310, 480},
    
    -- Column Headers
    TABLE_HEADERS = {"FID", "IDType", "CID", "Name", "Fixture Type / Mode", "U.Addrs"},
    
    -- Default Values
    DEFAULT_FILE_NAME = "MA3_Export",
    DEFAULT_USER_NAME = "User 1",
    OUTPUT_DIRECTORY = "/MA3_EXPORT_PDF/",
    
    -- Author Info
    GITHUB_URL = "https://github.com/MayBeLinux",
    STUDIO_NAME = "LumiArt-Studio",

    -- UI Theme
    UI_THEME = {
        backColor = "Global.Default",
        icon = "logo_small",
        titleTextColor = "Global.AlertText",
        messageTextColor = "Global.Text",
        align_h = "Left",
        align_v = "Top",
    },
}

local ErrorMessages = {
    USB_NOT_FOUND = "Error 1: USB Stick Not Found",
    PDF_CORRUPT = "Error 2: PDF Creation Failed",
    EMPTY_TABLES = "Error 3: Tables are empty",
    STATS_PDF_FAILED = "Error 2: Unable to create statistics PDF",
}

-- MA3 Parameter Reference Table
local MA3ParameterTable = {
    -- Left column devices
    {name = "grandMA3 full-size and grandMA3 full-size CRV", params = "12 288 parameters.", col = "left"},
    {name = "grandMA3 light and grandMA3 light CRV", params = "8 192 parameters.", col = "left"},
    {name = "grandMA3 extension", params = "0 parameters.", col = "left"},
    {name = "grandMA3 replay unit", params = "4 096 parameters.", col = "left"},
    {name = "grandMA3 compact XL", params = "4 096 parameters.", col = "left"},
    {name = "grandMA3 compact", params = "4 096 parameters.", col = "left"},
    {name = "grandMA3 processing unit XL", params = "16 384 parameters.", col = "left"},
    {name = "grandMA3 processing unit L", params = "8 192 parameters.", col = "left"},
    {name = "grandMA3 processing unit M", params = "4 096 parameters.", col = "left"},
    {name = "grandMA3 8Port Node", params = "0 parameters.", col = "left"},
    {name = "grandMA3 4Port Node", params = "0 parameters.", col = "left"},
    -- Right column devices
    {name = "grandMA3 2Port Node", params = "0 parameters.", col = "right"},
    {name = "grandMA3 8Port Node DIN-Rail", params = "0 parameters.", col = "right"},
    {name = "grandMA3 4Port Node DIN-Rail", params = "0 parameters.", col = "right"},
    {name = "grandMA3 2Port Node DIN-Rail", params = "0 parameters.", col = "right"},
    {name = "grandMA3 onPC command wing XT", params = "4 096 parameters.", col = "right"},
    {name = "grandMA3 onPC command wing", params = "2 048 parameters.", col = "right"},
    {name = "grandMA3 onPC 8Port Node 4k", params = "4 096 parameters (when connected to grandMA2 2 048 parameters).", col = "right"},
    {name = "grandMA3 onPC 4Port Node 4k", params = "4 096 parameters (when connected to grandMA2 2 048 parameters).", col = "right"},
    {name = "grandMA3 onPC 2Port Node 2k", params = "4 096 parameters (when connected to grandMA2 2 048 parameters).", col = "right"},
    {name = "grandMA3 onPC Software", params = "0 parameters.", col = "right"},
}

--------------------------------------------------------------------------------
-- System Overrides
--------------------------------------------------------------------------------

local print = Printf
local error = ErrPrintf

--------------------------------------------------------------------------------
-- State Management
--------------------------------------------------------------------------------

local State = {
    fixtureCount = 0,
    groupingCount = 0,
    stagesCount = 0,
}

local function resetCounters()
    State.fixtureCount = 0
    State.groupingCount = 0
    State.stagesCount = 0
end

--------------------------------------------------------------------------------
-- Utility Functions
--------------------------------------------------------------------------------

local Utils = {}

function Utils.getSystemInfo()
    return {
        machineName = os.getenv("COMPUTERNAME") or os.getenv("HOSTNAME") or "Unknown",
        timestamp = os.date("%Y-%m-%d %H:%M:%S"),
        showName = nil,
    }
end

function Utils.ensureDirectory(path)
    local mkdirCommand = 'mkdir "' .. path .. '"'
    os.execute(mkdirCommand)
end

function Utils.safeValue(value, default)
    if value and value ~= "" then
        return value
    end
    return default or "None"
end

function Utils.truncate(text, maxLen)
    if #text > maxLen then
        return text:sub(1, maxLen) .. "..."
    end
    return text
end

--------------------------------------------------------------------------------
-- PDF Content Builders
--------------------------------------------------------------------------------

local ContentBuilder = {}

function ContentBuilder.text(text, x, y, fontSize, r, g, b)
    r, g, b = r or 0, g or 0, b or 0
    return string.format(
        "%.2f %.2f %.2f rg\nBT\n/F1 %d Tf\n%d %d Td\n(%s) Tj\nET\n",
        r, g, b, fontSize, x, y, text
    )
end

function ContentBuilder.textBold(text, x, y, fontSize)
    return string.format(
        "BT\n/F2 %d Tf\n%d %d Td\n(%s) Tj\nET\n",
        fontSize, x, y, text
    )
end

function ContentBuilder.line(x1, y1, x2, y2)
    return string.format(
        "0 0 0 RG\n%d %d m\n%d %d l\nS\n",
        x1, y1, x2, y2
    )
end

function ContentBuilder.colorBlock(r, g, b)
    return string.format("%.2f %.2f %.2f rg\n", r, g, b)
end

--------------------------------------------------------------------------------
-- PDF Writer Class
--------------------------------------------------------------------------------

local PDFWriter = {}

function PDFWriter.new(filepath)
    local self = {
        file = nil,
        xrefTable = {},
        xrefOffset = 0,
        pageObjects = {},
        currentObjectId = 3,
    }
    
    self.file = io.open(filepath, "wb")
    if not self.file then
        return nil
    end
    
    self.file:write(Config.PDF_VERSION)
    
    setmetatable(self, {__index = PDFWriter})
    return self
end

function PDFWriter:writeObject(objectContent)
    self.xrefTable[#self.xrefTable + 1] = string.format("%010d 00000 n ", self.xrefOffset)
    local data = objectContent .. "\n"
    self.xrefOffset = self.xrefOffset + #data
    self.file:write(data)
end

function PDFWriter:addPage(content)
    local pageId = self.currentObjectId
    self.pageObjects[#self.pageObjects + 1] = pageId
    
    local pageObj = string.format(
        "%d 0 obj\n<< /Type /Page /Parent 2 0 R /MediaBox [0 0 %d %d] /Contents %d 0 R " ..
        "/Resources << /Font << " ..
        "/F1 << /Type /Font /Subtype /Type1 /BaseFont /Helvetica >> " ..
        "/F2 << /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold >> " ..
        ">> >> >>\nendobj",
        pageId, Config.PAGE_WIDTH, Config.PAGE_HEIGHT, pageId + 1
    )
    self:writeObject(pageObj)
    
    local contentObj = string.format(
        "%d 0 obj\n<< /Length %d >>\nstream\n%sendstream\nendobj",
        pageId + 1, #content, content
    )
    self:writeObject(contentObj)
    
    self.currentObjectId = self.currentObjectId + 2
end

function PDFWriter:finalize()
    local kids = table.concat(self.pageObjects, " 0 R ") .. " 0 R"
    local pagesObj = string.format(
        "2 0 obj\n<< /Type /Pages /Count %d /Kids [%s] >>\nendobj",
        #self.pageObjects, kids
    )
    self:writeObject(pagesObj)
    
    self:writeObject("1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj")
    
    self.file:write("xref\n0 " .. (#self.xrefTable + 1) .. "\n")
    self.file:write("0000000000 65535 f \n")
    for _, xref in ipairs(self.xrefTable) do
        self.file:write(xref .. "\n")
    end
    
    self.file:write(string.format(
        "trailer\n<< /Size %d /Root 1 0 R >>\nstartxref\n%d\n%%%%EOF",
        #self.xrefTable + 1, self.xrefOffset
    ))
    
    self.file:close()
end

--------------------------------------------------------------------------------
-- Fixture Data Collection
--------------------------------------------------------------------------------

local FixtureCollector = {}

function FixtureCollector.createFixtureRecord(fixture, indent)
    indent = indent or ""
    return {
        FID = Utils.safeValue(fixture.fid),
        IDType = Utils.safeValue(fixture.idtype),
        CID = Utils.safeValue(fixture.cid),
        Name = indent .. Utils.safeValue(fixture.name),
        FixtureTypes = (fixture.fixturetype and fixture.fixturetype.name) or "None",
        Mode = Utils.safeValue(fixture.mode, "No Mode"),
        UAddrs = (fixture.patch and fixture.patch ~= "") and fixture.patch or "Unpatched",
    }
end

function FixtureCollector.createGroupingRecord(name, indent)
    indent = indent or ""
    local separator = "------"
    return {
        FID = separator,
        IDType = separator,
        CID = separator,
        Name = indent .. "GROUPING: " .. Utils.safeValue(name, "Unnamed Group"),
        FixtureTypes = separator,
        Mode = separator,
        UAddrs = separator,
    }
end

function FixtureCollector.extractFromGrouping(grouping, allPatch, indent)
    indent = indent or ""
    local children = grouping:Children()
    
    for _, child in ipairs(children) do
        if child.fixturetype and child.fixturetype.name == "Grouping" then
            State.groupingCount = State.groupingCount + 1
            table.insert(allPatch, FixtureCollector.createGroupingRecord(child.name, indent))
            FixtureCollector.extractFromGrouping(child, allPatch, indent .. "  ")
        else
            State.fixtureCount = State.fixtureCount + 1
            table.insert(allPatch, FixtureCollector.createFixtureRecord(child, indent))
        end
    end
end

function FixtureCollector.scanGroupings()
    local stagesData = {}

    for stageIndex, stage in ipairs(Patch().Stages) do
        local stageName = stage.name or ("Stage " .. stageIndex)
        local stageEntry = {
            stageName = stageName,
            groupings = {},
            hasUngrouped = false,
        }

        for _, fixture in ipairs(stage.fixtures) do
            if fixture.fixturetype and fixture.fixturetype.name == "Grouping" then
                table.insert(stageEntry.groupings, fixture.name or "Unnamed Group")
            else
                stageEntry.hasUngrouped = true
            end
        end

        table.insert(stagesData, stageEntry)
    end

    return stagesData
end

function FixtureCollector.collectAll(filter)
    resetCounters()
    local allPatch = {}

    for stageIndex, stage in ipairs(Patch().Stages) do
        State.stagesCount = State.stagesCount + 1
        local stageName = stage.name or ("Stage " .. stageIndex)
        local stageFilter = filter and filter.stages[stageName] or nil

        for _, fixture in ipairs(stage.fixtures) do
            if fixture.fixturetype and fixture.fixturetype.name == "Grouping" then
                local groupName = fixture.name or "Unnamed Group"
                if not stageFilter or not stageFilter.excludedGroupings[groupName] then
                    State.groupingCount = State.groupingCount + 1
                    table.insert(allPatch, FixtureCollector.createGroupingRecord(fixture.name))
                    FixtureCollector.extractFromGrouping(fixture, allPatch, "  ")
                end
            else
                if not stageFilter or stageFilter.includeUngrouped then
                    State.fixtureCount = State.fixtureCount + 1
                    table.insert(allPatch, FixtureCollector.createFixtureRecord(fixture))
                end
            end
        end
    end

    return allPatch
end

--------------------------------------------------------------------------------
-- Main PDF Export
--------------------------------------------------------------------------------

local function generateMainPDF(outputPath, fixtures, documentName, userName)
    local sysInfo = Utils.getSystemInfo()
    local directory = outputPath .. Config.OUTPUT_DIRECTORY
    local fullPath = directory .. documentName .. ".pdf"
    
    Utils.ensureDirectory(directory)
    
    local pdf = PDFWriter.new(fullPath)
    if not pdf then
        error(ErrorMessages.PDF_CORRUPT)
        return
    end
    
    local function buildFirstPageHeader()
        return table.concat({
            ContentBuilder.text("||  MA3 Data Extractor  ||", 200, 775, 18),
            ContentBuilder.text(Config.STUDIO_NAME .. " / Github: " .. Config.GITHUB_URL, 30, 750, 14),
            ContentBuilder.text("User name: " .. userName, 30, 735, 12),
            ContentBuilder.text("Date: " .. sysInfo.timestamp, 30, 720, 12),
            ContentBuilder.text("LocalHost: " .. sysInfo.machineName, 30, 705, 12),
            ContentBuilder.text("Show Names: " .. Utils.safeValue(sysInfo.showName, "N/A"), 30, 690, 12),
        })
    end
    
    local function buildRowContent(row, y)
        local content = ""
        
        local displayName = Utils.truncate(tostring(row.Name), 25)

        if row.FID == "------" then
            content = content .. ContentBuilder.colorBlock(1, 0, 0)
            content = content .. ContentBuilder.textBold(displayName, Config.START_X, y, 13)
            content = content .. ContentBuilder.colorBlock(0, 0, 0)
            return content, Config.ROW_HEIGHT - 2
        else
            local lineY = y - 20
            content = content .. ContentBuilder.line(
                Config.START_X - 31, lineY,
                Config.PAGE_WIDTH - Config.MARGIN + 40, lineY
            )

            local values = {row.FID, row.IDType, row.CID, displayName, row.FixtureTypes, row.UAddrs}
            for i, value in ipairs(values) do
                content = content .. ContentBuilder.text(
                    tostring(value),
                    Config.START_X + Config.COLUMN_OFFSETS[i], y, 12
                )
            end
            
            content = content .. ContentBuilder.text(
                tostring(row.Mode),
                Config.START_X + Config.COLUMN_OFFSETS[5], y - 10, 10
            )
            
            return content, Config.ROW_HEIGHT
        end
    end
    
    local function buildPageContent(pageFixtures, isFirstPage)
        local content = ""
        local headerY = isFirstPage and Config.HEADER_Y_FIRST_PAGE or Config.HEADER_Y_OTHER_PAGES
        
        if isFirstPage then
            content = buildFirstPageHeader()
        end
        
        for i, header in ipairs(Config.TABLE_HEADERS) do
            content = content .. ContentBuilder.text(
                header,
                Config.START_X + Config.COLUMN_OFFSETS[i], headerY, 12
            )
        end
        
        local y = headerY - 20
        for _, row in ipairs(pageFixtures) do
            local rowContent, rowHeight = buildRowContent(row, y)
            content = content .. rowContent
            y = y - rowHeight
        end
        
        return content
    end
    
    local isFirstPage = true
    for i = 1, #fixtures, Config.MAX_ROWS_PER_PAGE do
        local pageFixtures = {}
        for j = i, math.min(i + Config.MAX_ROWS_PER_PAGE - 1, #fixtures) do
            pageFixtures[#pageFixtures + 1] = fixtures[j]
        end
        
        local pageContent = buildPageContent(pageFixtures, isFirstPage)
        pdf:addPage(pageContent)
        isFirstPage = false
    end
    
    pdf:finalize()
    print("PDF generated: %s", documentName)
end

--------------------------------------------------------------------------------
-- Statistics PDF Export
--------------------------------------------------------------------------------

local function generateStatisticsPDF(outputPath)
    local sysInfo = Utils.getSystemInfo()
    local directory = outputPath .. Config.OUTPUT_DIRECTORY
    local fullPath = directory .. "Statistics_Report.pdf"
    
    local file = io.open(fullPath, "wb")
    if not file then
        error(ErrorMessages.STATS_PDF_FAILED)
        return
    end
    
    file:write(Config.PDF_VERSION)
    
    FixtureCollector.collectAll()
    local parameters = GetUIChannelCount()
    
    local startY = 750
    local content = {}
    
    -- Header section
    table.insert(content, ContentBuilder.text("|| MA3 STATISTICS REPORT ||", 180, startY + 20, 18))
    table.insert(content, ContentBuilder.text(Config.STUDIO_NAME .. " / Github: " .. Config.GITHUB_URL, 50, startY - 10, 12))
    table.insert(content, ContentBuilder.text("Date: " .. sysInfo.timestamp, 50, startY - 22, 12))
    
    -- Statistics section
    table.insert(content, ContentBuilder.text("Numbers of fixtures: " .. State.fixtureCount, 50, startY - 50, 14))
    table.insert(content, ContentBuilder.text("Numbers of grouping: " .. State.groupingCount, 50, startY - 70, 14))
    table.insert(content, ContentBuilder.text("Numbers of stages: " .. State.stagesCount, 50, startY - 90, 14))
    table.insert(content, ContentBuilder.text("Numbers of parameters: " .. parameters, 50, startY - 110, 14))
    
    -- Parameter table header
    table.insert(content, ContentBuilder.text("Parameters table:", 10, startY - 138, 15))
    
    -- Parameter reference list
    local leftColY = startY - 160
    local rightColY = startY - 160
    
    for _, device in ipairs(MA3ParameterTable) do
        local x, y
        if device.col == "left" then
            x, y = 20, leftColY
            leftColY = leftColY - 35
        else
            x, y = 300, rightColY
            rightColY = rightColY - 35
        end
        
        table.insert(content, ContentBuilder.text(device.name .. ":", x, y, 12))
        table.insert(content, ContentBuilder.text(device.params, x, y - 15, 10, 1, 0, 0))
    end
    
    -- Footer / Copyright
    table.insert(content, ContentBuilder.text(
        "This software plugin is proprietary and protected under copyright law. " ..
        "Unauthorized reproduction, distribution, modification, or resale is strictly prohibited.",
        3, startY - 740, 7
    ))
    table.insert(content, ContentBuilder.text(Config.STUDIO_NAME, 3, startY - 747, 7))
    
    local pdfContent = table.concat(content)

    -- Write PDF structure with tracked byte offsets
    local offset = #Config.PDF_VERSION
    local xrefs = {}

    local obj1 = "1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n"
    xrefs[1] = offset
    file:write(obj1)
    offset = offset + #obj1

    local obj2 = "2 0 obj\n<< /Type /Pages /Count 1 /Kids [3 0 R] >>\nendobj\n"
    xrefs[2] = offset
    file:write(obj2)
    offset = offset + #obj2

    local obj3 = string.format(
        "3 0 obj\n<< /Type /Page /Parent 2 0 R /MediaBox [0 0 %d %d] /Contents 4 0 R " ..
        "/Resources << /Font << " ..
        "/F1 << /Type /Font /Subtype /Type1 /BaseFont /Helvetica >> " ..
        "/F2 << /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold >> " ..
        ">> >> >>\nendobj\n",
        Config.PAGE_WIDTH, Config.PAGE_HEIGHT
    )
    xrefs[3] = offset
    file:write(obj3)
    offset = offset + #obj3

    local obj4 = string.format(
        "4 0 obj\n<< /Length %d >>\nstream\n%sendstream\nendobj\n",
        #pdfContent, pdfContent
    )
    xrefs[4] = offset
    file:write(obj4)
    offset = offset + #obj4

    file:write("xref\n0 5\n0000000000 65535 f \n")
    for i = 1, 4 do
        file:write(string.format("%010d 00000 n \n", xrefs[i]))
    end
    file:write(string.format(
        "trailer\n<< /Size 5 /Root 1 0 R >>\nstartxref\n%d\n%%%%EOF",
        offset
    ))
    
    file:close()
    print("Statistics PDF generated")
end

--------------------------------------------------------------------------------
-- USB Drive Detection
--------------------------------------------------------------------------------

local USBManager = {
    drives = {},
    paths = {},
    idCounter = 1,
}

function USBManager.reset()
    USBManager.drives = {}
    USBManager.paths = {}
    USBManager.idCounter = 1
end

function USBManager.isValidUSB(drive)
    return drive.name:match("^[A-Za-z0-9]")
        and drive.drivetype == "Removeable"
        and drive.drivetype ~= "Internal"
        and drive.drivetype ~= "OldVersion"
        and drive.drivetype ~= "gma3_2.1.1"
end

function USBManager.detectDrives(driveList)
    USBManager.reset()
    local foundUSB = false
    
    for _, drive in ipairs(driveList) do
        if USBManager.isValidUSB(drive) then
            foundUSB = true
            USBManager.idCounter = USBManager.idCounter + 1
            USBManager.drives[drive.name] = USBManager.idCounter
            USBManager.paths[USBManager.idCounter] = drive.path
        end
    end
    
    return foundUSB
end

--------------------------------------------------------------------------------
-- User Interface
--------------------------------------------------------------------------------

local UI = {}

function UI.dialog(options)
    local theme = Config.UI_THEME
    local params = {
        title = options.title or "MA3 PDF Exporter",
        message = options.message or "",
        message_align_h = Enums.AlignmentH[theme.align_h],
        message_align_v = Enums.AlignmentV[theme.align_v],
        commands = options.commands or {{value = 1, name = "Ok"}, {value = 0, name = "Cancel"}},
        backColor = theme.backColor,
        icon = theme.icon,
        titleTextColor = theme.titleTextColor,
        messageTextColor = theme.messageTextColor,
    }

    if options.inputs then params.inputs = options.inputs end
    if options.selectors then params.selectors = options.selectors end
    if options.timeout then params.timeout = options.timeout end

    return MessageBox(params)
end

function UI.showError(title, message)
    UI.dialog({
        title = title,
        message = message,
        commands = {{value = 1, name = "OK"}},
        timeout = 5000,
    })
end

function UI.showGroupingDialog(stagesData)
    local selectors = {}
    local stageCount = #stagesData

    for _, stageEntry in ipairs(stagesData) do
        local prefix = stageCount > 1 and (stageEntry.stageName .. " | ") or ""

        for _, groupName in ipairs(stageEntry.groupings) do
            table.insert(selectors, {
                name = prefix .. groupName,
                selectedValue = 1,
                values = {["Include"] = 1, ["Exclude"] = 2},
                type = 1
            })
        end

        if stageEntry.hasUngrouped then
            table.insert(selectors, {
                name = prefix .. "Ungrouped Fixtures",
                selectedValue = 1,
                values = {["Include"] = 1, ["Exclude"] = 2},
                type = 1
            })
        end
    end

    return UI.dialog({
        title = "PDF Export - Select Groupings",
        message = "Choose which groupings to include in the export.\n" ..
                  "Each item can be set to Include or Exclude.",
        selectors = selectors,
    })
end

function UI.buildFilterFromSelections(settings, stagesData)
    local filter = { stages = {} }
    local stageCount = #stagesData

    for _, stageEntry in ipairs(stagesData) do
        local prefix = stageCount > 1 and (stageEntry.stageName .. " | ") or ""
        local stageFilter = {
            excludedGroupings = {},
            includeUngrouped = true,
        }

        for _, groupName in ipairs(stageEntry.groupings) do
            if settings.selectors[prefix .. groupName] == 2 then
                stageFilter.excludedGroupings[groupName] = true
            end
        end

        if stageEntry.hasUngrouped and settings.selectors[prefix .. "Ungrouped Fixtures"] == 2 then
            stageFilter.includeUngrouped = false
        end

        filter.stages[stageEntry.stageName] = stageFilter
    end

    return filter
end

function UI.showExportDialog()
    return UI.dialog({
        title = "PDF Export - Settings",
        message = "Configure your export settings below.\n" ..
                  "Ensure a USB drive is connected.",
        inputs = {
            {name = "Document Name", values = Config.DEFAULT_FILE_NAME},
            {name = "Programmer", values = Config.DEFAULT_USER_NAME},
        },
        selectors = {
            {
                name = "USB Drive",
                values = USBManager.drives,
                path = USBManager.paths,
                selectedValue = USBManager.idCounter,
                type = 1
            },
            {
                name = "Statistics Page",
                selectedValue = 2,
                values = {["Include"] = 1, ["Exclude"] = 2},
                type = 1
            },
        },
    })
end

function UI.processExportRequest(drives)
    -- Step 1: Scan for groupings across all stages
    local stagesData = FixtureCollector.scanGroupings()

    -- Step 2: Show grouping selection dialog (only if there are groupings or fixtures)
    local filter = nil
    local hasContent = false
    for _, stageEntry in ipairs(stagesData) do
        if #stageEntry.groupings > 0 or stageEntry.hasUngrouped then
            hasContent = true
            break
        end
    end

    if hasContent then
        local groupingSettings = UI.showGroupingDialog(stagesData)

        if groupingSettings.result ~= 1 then
            return
        end

        filter = UI.buildFilterFromSelections(groupingSettings, stagesData)
    end

    -- Step 3: Show export dialog
    local settings = UI.showExportDialog()

    if settings.result ~= 1 then
        UI.showError("Error E3", "No values entry")
        return
    end

    -- Get selected drive path
    local selectedDriveId = settings.selectors["USB Drive"]
    local drivePath = USBManager.paths[selectedDriveId]

    -- Generate statistics PDF if requested
    if settings.selectors["Statistics Page"] == 1 then
        generateStatisticsPDF(drivePath)
    end

    -- Get document name
    local fileName = settings.inputs["Document Name"]
    if not fileName or fileName == "" then
        fileName = Config.DEFAULT_FILE_NAME
    end

    -- Get programmer name
    local userName = settings.inputs["Programmer"]
    if not userName or userName == "" then
        userName = Config.DEFAULT_USER_NAME
    end

    -- Collect filtered fixture data and generate PDF
    local fixturesData = FixtureCollector.collectAll(filter)

    if #fixturesData == 0 then
        UI.showError("Empty Export", "All groupings were excluded. No data to export.")
        return
    end

    generateMainPDF(drivePath, fixturesData, fileName, userName)
end

--------------------------------------------------------------------------------
-- Main Entry Point
--------------------------------------------------------------------------------

local function main()
    local drives = Root().Temp.DriveCollect
    
    if USBManager.detectDrives(drives) then
        UI.processExportRequest(drives)
    else
        UI.showError(
            ErrorMessages.USB_NOT_FOUND,
            "Please insert a USB stick or check your USB port!"
        )
    end
end

return main