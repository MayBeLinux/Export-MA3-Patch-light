
  local ERR1 = "Erreur 1 : USB Stick Not Found"
  local ERR2 = "Erreur 2 : PDF Corrupt"
  local ERR3 = "Erreur 3 : Tables Stick empty now !"
  local print = Printf
  local error = ErrPrintf
  local Machines, Time, ProgrammeursNames, ShowsNow, UserName = os.getenv("COMPUTERNAME") or os.getenv("HOSTNAME"), os.date("%Y-%m-%d %H:%M:%S"), "https://github.com/MayBeLinux", Root().manetsocket.showfile , UsersName

  local function generatePDF(path , fixtures , documentsnames , Users)
      local file = io.open(path, "wb")
      if not file then error(ERR2) return end 

      
      file:write("%PDF-1.4\n")

      
      local maxRowsPerPage = 17 
      local pageWidth = 612 
      local pageHeight = 792 
      local margin = 50
      local rowHeight = 35 
      local headerYFirstPage = 650  
      local headerYOtherPages = 760 
      local startX = 50          
      local columnOffsets = {-30, 25, 100, 150, 310, 480}  

      local xrefTable = {}
      local xrefOffset = 0
      local pageObjects = {}

      
      local function writeObject(object)
          xrefTable[#xrefTable + 1] = string.format("%010d 00000 n ", xrefOffset)
          local data = object .. "\n"
          xrefOffset = xrefOffset + #data
          file:write(data)
      end

      
      local function generateFirstPageHeader()
          return table.concat({
              string.format("BT\n/F1 18 Tf\n200 775 Td\n(||  MA3 Data Extractor  ||  ) Tj\nET\n"),
              string.format("BT\n/F1 14 Tf\n30 750 Td\n(LumiArt- Studio / Github :  %s) Tj\nET\n", ProgrammeursNames),
              string.format("BT\n/F1 12 Tf\n30 735 Td\n(User name : %s) Tj\nET\n", Users),
              string.format("BT\n/F1 12 Tf\n30 720 Td\n(Date : %s) Tj\nET\n", Time),
              string.format("BT\n/F1 12 Tf\n30 705 Td\n(LocalHosts : %s) Tj\nET\n", Machines),
              string.format("BT\n/F1 12 Tf\n30 690 Td\n(Show Names : %s) Tj\nET\n", ShowsNow)  
          })
      end

      
      local function generateRow(row)
          return {
              string.format("%s", row.FID),
              string.format("%s", row.IDType),
              string.format("%s", row.CID),
              string.format("%s", row.Name),
              string.format("%s", row.FixtureTypes),
              string.format("%s", row.UAddrs)
          }, row.Mode 
      end

      
      local function generatePageContent(pageFixtures, isFirstPage)
          local content = ""
          local headerY = isFirstPage and headerYFirstPage or headerYOtherPages

          
          if isFirstPage then
              content = generateFirstPageHeader()
          end

          
          local headers = {"FID", "IDType", "CID", "Name", "Fixture Type / Mode", "U.Addrs"}
          for i, header in ipairs(headers) do
              content = content .. string.format(
                  "BT\n/F1 12 Tf\n%d %d Td\n(%s) Tj\nET\n",
                  startX + columnOffsets[i], headerY, header
              )
          end

          
          local y = headerY - 20
          for _, row in ipairs(pageFixtures) do
              if row.FID == "------" then
                  content = content .. "1 0 0 rg\n" .. string.format(
                      "BT\n/F2 13 Tf\n%d %d Td\n(%s) Tj\nET\n",
                      startX, y, row.Name
                  ) .. "0 0 0 rg\n"
                  y = y - (rowHeight - 2)
              else
                  
                  local ligneNoireY = y - 20  

                  
                  content = content .. string.format(
                      "0 0 0 RG\n%d %d m\n%d %d l\nS\n",
                      startX - 31, ligneNoireY, pageWidth - margin + 40, ligneNoireY
                  )

                  
                  local rowData, mode = generateRow(row)
                  for i, value in ipairs(rowData) do
                      content = content .. string.format(
                          "BT\n/F1 12 Tf\n%d %d Td\n(%s) Tj\nET\n",
                          startX + columnOffsets[i], y, value
                      )
                  end

                  
                  content = content .. string.format(
                      "BT\n/F1 10 Tf\n%d %d Td\n(%s) Tj\nET\n",
                      startX + columnOffsets[5], y - 10, mode  
                  )

                  
                  y = y - rowHeight
              end
          end

          return content
      end

      
      local currentPage = 3
      local isFirstPage = true
      for i = 1, #fixtures, maxRowsPerPage do
          local pageFixtures = {}
          for j = i, math.min(i + maxRowsPerPage - 1, #fixtures) do
              pageFixtures[#pageFixtures + 1] = fixtures[j]
          end

          
          local pageContent = generatePageContent(pageFixtures, isFirstPage)
          pageObjects[#pageObjects + 1] = currentPage
          writeObject(currentPage .. " 0 obj\n<< /Type /Page /Parent 2 0 R /MediaBox [0 0 " .. pageWidth .. " " .. pageHeight .. "] /Contents " .. (currentPage + 1) .. " 0 R >>\nendobj")
          writeObject((currentPage + 1) .. " 0 obj\n<< /Length " .. #pageContent .. " >>\nstream\n" .. pageContent .. "endstream\nendobj")
          currentPage = currentPage + 2
          isFirstPage = false
      end

      
      local kids = table.concat(pageObjects, " 0 R ") .. " 0 R"
      writeObject("2 0 obj\n<< /Type /Pages /Count " .. #pageObjects .. " /Kids [" .. kids .. "] >>\nendobj")

      
      writeObject("1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj")

      
      file:write("xref\n0 " .. (#xrefTable + 1) .. "\n")
      file:write("0000000000 65535 f \n")
      for _, xref in ipairs(xrefTable) do
          file:write(xref .. "\n")
      end

      
      file:write("trailer\n<< /Size " .. (#xrefTable + 1) .. " /Root 1 0 R >>\nstartxref\n" .. xrefOffset .. "\n%%EOF")

      file:close()
      print("PDF : %s" , documentsnames , "Thanks : %s", Users)
  end
  
  local inputs = {
          {name = "Documents Name :",values = defaultFileName},
          { name = "Users" , values = usersName, }}

  local selectors = {
          { name="USB DRIVES", values={}, type=1},
          { name = "Statistic Tables", selectedValues = 2, values ={["Include"]=1 , ["Exclude"]=2} , type=1}
          }

        local idCounter = 1 

  local drive = Root().Temp.DriveCollect 
  function usbStickConnected()  
  local connectedUSB = false     
  selectors[1].values = {}
  local usbDrive = ""
    for _, usbStick in ipairs(drive) do
          if usbStick.name:match("^[A-Za-z0-9]") and
          usbStick.drivetype == "Removeable" and
            usbStick.drivetype ~= "Internal" and
            usbStick.drivetype ~= "OldVersion" and            
            usbStick.drivetype ~= "gma3_2.1.1" then
              connectedUSB = true 
              idCounter = idCounter + 1
              selectors[1].values[usbStick.name] = idCounter
              selectors[1].selectedValues = idCounter
      end
    end

    if connectedUSB == true then
    userRequest()
  else

  MessageBox({   
        title = ERR1,
        message = "Please insert a usb stick or check your usb port !",
        commands = {{value = 1, name = "OK"}},
        timeout = 5000
      })
    end 
  end

  function userRequest(arguments) 
    
    
    idCounter = 1 
    local settings = MessageBox({
        title = "Export PDF",
        message = "Enter a name for you documents and programmer name. If you want a statistic page specifie this with the selectors buttons and the page was export to a PDF. (LumiArt-Studio)",
        message_align_h = Enums.AlignmentH.Left,
        message_align_v = Enums.AlignmentV.Top,
        commands = {{value = 1, name = "Ok"}, {value = 0, name = "Cancel"}},
        inputs = inputs,
        selectors = selectors,
        backColor = "Global.Default",
        icon = "logo_small",
        titleTextColor = "Global.AlertText",
        messageTextColor = "Global.Text",
        autoCloseOnInput = true
      }
    )
    
  for k , v in pairs(settings.selectors) do
    if k == 'USB DRIVES' then  
      drivePath = drive[v].path
    end
  end
if settings.result == 1 then 
      for k , v in pairs(settings.selectors) do
    if k == 'USB DRIVES' then
        drivePath = drive[v].path
      
    elseif k == nil then 
      print(ERR3)
    end
  end
    local fileName = settings.inputs["Documents Name :"] 
    local UsersName = settings.inputs["Users"]     
    local summaryTable = settings.selectors["Statistic PDF"] 
    local FixturesData = collectFixtureData()
    generatePDF(drivePath .. "/" .. fileName .. ".pdf", FixturesData, fileName, UsersName)
    
    elseif settings.result == 0 then
    MessageBox({
        title = "PDF EXPORTER ABORT",
        message = "Export abort, please restart the plugin",
        commands = {{value = 1, name = "OK"}},
        timeout = 5000 
      })
    end
  end




  function extractFixturesFromGrouping(grouping, AllPatch, indent)
      indent = indent or "" 

      
      local children = grouping:Children()
      for _, child in ipairs(children) do
         
          if child.fixturetype and child.fixturetype.name == "Grouping" then
              table.insert(AllPatch, {
                  FID = "------",
                  IDType = "------",
                  CID = "------",
                  Name = indent .. "GROUPING: " .. (child.name or "Unnamed Group"),
                  FixtureTypes = "------",
                  Mode = "------",
                  UAddrs = "------"
              })
              
              extractFixturesFromGrouping(child, AllPatch, indent .. "  ")  
          else
             
              table.insert(AllPatch, {
                  FID = child.fid or "None",
                  IDType = child.idtype or "None",
                  CID = child.cid or "None",
                  Name = indent .. (child.name or "None"),
                  FixtureTypes = (child.fixturetype and child.fixturetype.name) or "None",
                  Mode = child.mode or "No Mode",
                  UAddrs = (child.patch and child.patch ~= "") and child.patch or "Unpatched",
              })
          end
      end
  end

  function collectFixtureData()
      local AllPatch = {} 

      for _, stages in ipairs(Patch().Stages) do 
          for _, fixture in ipairs(stages.fixtures) do
              
              if fixture.fixturetype and fixture.fixturetype.name == "Grouping" then
                  table.insert(AllPatch, {
                      FID = "------",
                      IDType = "------",
                      CID = "------",
                      Name = "GROUPING: " .. (fixture.name or "Unnamed Group"),
                      FixtureTypes = "------",
                      Mode = "------",
                      UAddrs = "------"
                  })

                  
                  extractFixturesFromGrouping(fixture, AllPatch, "  ")
              else
                   table.insert(AllPatch, {
                      FID = fixture.fid or "None",
                      IDType = fixture.idtype or "None",
                      CID = fixture.cid or "None",
                      Name = fixture.name or "None",
                      FixtureTypes = (fixture.fixturetype and fixture.fixturetype.name) or "None",
                      Mode = fixture.mode or "No Mode",
                      UAddrs = (fixture.patch and fixture.patch ~= "") and fixture.patch or "Unpatched",
                  })
              end
          end
      end
      return AllPatch
  end
local function Main(displayHandle, argument)  
  if argument then usbStickConnected()
  else usbStickConnected() end
  end

  return Main
