
  local ERR1 = "Erreur 1 : USB Stick Not Found"
  local ERR2 = "Erreur 2 : PDF Corrupt"
  local ERR3 = "Erreur 3 : Tables Stick empty now !"
  local print = Printf
  local error = ErrPrintf

  local Machines, Time, ProgrammeursNames, ShowsNow, UserName = os.getenv("COMPUTERNAME") or os.getenv("HOSTNAME"), os.date("%Y-%m-%d %H:%M:%S"), "https://github.com/MayBeLinux", Root().manetsocket.showfile , UsersName

  local function generatePDF(path , fixtures , documentsnames , Users)

    local directory = path.. "/MA3_EXPORT_PDF/"  
    local fullpath = directory .. documentsnames .. ".pdf"
    
    local mkdir_command = "mkdir \"" .. directory .. "\""
    os.execute(mkdir_command)
    
      local file = io.open(fullpath, "wb")
      if not file then error(ERR2) return end 

      
      file:write("%PDF-1.4\n")

      -- Constantes
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
      print("PDF généré : %s", documentsnames)
  end
  
local function StatisticgenPdf(path)
    local directory = path .. "/MA3_EXPORT_PDF/"

    local fullpath = directory .. "Statistics_Report.pdf"
    local file = io.open(fullpath, "wb")

    if not file then
        error("Erreur 2 : Impossible to create a statistics PDF")
        return
    end

    -- 1. Version du PDF
    file:write("%PDF-1.4\n")

    -- Constantes
    local pageWidth = 612   
    local pageHeight = 792  
    local startX = 50
    local startY = 750


    fixtureCount = 0 
    groupingCount = 0 
    stagesCount = 0 
    collectFixtureData()
    local parameters = GetUIChannelCount()
    
    for _,stages in ipairs(Patch().Stages) do    
      stagesCount = stagesCount + 1
      end
        -- Écriture du contenu du PDF
      local function writePDFText(r , g , b , text, x, y, size)
        return string.format("%.2f %.2f %.2f rg\nBT\n/F1 %d Tf\n%d %d Td\n(%s) Tj\nET\n", r, g, b, size , x , y + 20 , text)
        end
      

      local pdfContent = table.concat({
          writePDFText(0 , 0 , 0 ,"|| MA3 STATISTICS REPORT ||",  180, startY, 18),
          writePDFText(0 , 0 , 0 ,"LumiArt - Studio / Github : https://github.com/MayBeLinux",  50, startY - 30, 12),
          writePDFText(0 , 0 , 0 ,"Date : " .. os.date("%Y-%m-%d %H:%M:%S"),  50, startY - 42, 12),
          writePDFText(0 , 0 , 0 ,"Numbers of fixtures : " .. fixtureCount, 50,  startY - 70, 14),
          writePDFText(0 , 0 , 0 ,"Numbers of grouping : " .. groupingCount,  50, startY - 90, 14),
          writePDFText(0 , 0 , 0 ,"Numbers of stages :" ..stagesCount,  50, startY - 110, 14),
          writePDFText(0 , 0 , 0 ,"Numbers of parameters : " .. parameters, 50, startY - 130, 14),
          writePDFText(0 , 0 , 0 ,"This software plugin is proprietary and protected under copyright law. Unauthorized reproduction, distribution, modification, or resale of this software, in whole or in part, is strictly prohibited.", 3, startY - 760, 7),
          writePDFText(0, 0 , 0 ,"LumiArt - Studio", 3, startY - 767, 7),
          
          writePDFText(0, 0 , 0 , "Parameters table : ",10, startY - 158, 15),
          
          writePDFText(0, 0 , 0 , "grandMA3 full-size and grandMA3 full-size CRV:",20, startY - 180, 12),
          
          writePDFText(1 , 0 , 0  ,"12 288 parameters.",20, startY - 195, 10),
          
          
          writePDFText(0, 0, 0, "grandMA3 light and grandMA3 light CRV:",20, startY -  215, 12),
          
          writePDFText(1 , 0 , 0 ,  "8 192 parameters.",20, startY - 230, 10),
          
          
          writePDFText(0 , 0 , 0 ,"grandMA3 extension:",20, startY - 250, 12),
          
          writePDFText(1 , 0 , 0  ,"0 parameters.",20, startY - 265, 10),
          
          
          writePDFText(0 , 0 , 0 ,"grandMA3 replay unit:",20, startY - 285, 12),
          
          writePDFText(1 , 0 , 0  ,"4 096 parameters.",  20, startY - 300, 10),
          
          
          writePDFText(0 , 0 , 0 ,"grandMA3 compact XL:", 20, startY - 320, 12),
          
          writePDFText(1 , 0 , 0  ,"4 096 parameters.",20, startY - 335, 10),
          
          
          writePDFText(0 , 0 , 0 ,"grandMA3 compact:",20, startY - 355, 12),
          
          writePDFText(1, 0 , 0  ,"4 096 parameters.",20, startY - 370, 10),
          
          
          writePDFText(0 , 0 , 0 ,"grandMA3 processing unit XL:",20, startY - 390, 12),
          
          writePDFText(1 , 0 , 0 ,"16 384 parameters." ,  20, startY - 405, 10),
          
          
          writePDFText(0 , 0 , 0 ,"grandMA3 processing unit L:",20, startY - 425, 12),
          
          writePDFText(1 , 0 , 0    ,"8 192 parameters.",20, startY - 440, 10),
          
          
          writePDFText(0 , 0 , 0 ,"grandMA3 processing unit M:",20, startY - 460, 12),
          
          writePDFText(1 , 0 , 0  ,"4 096 parameters.",20, startY - 475, 10),
          
          
          writePDFText(0 , 0 , 0 ,"grandMA3 8Port Node:",20, startY - 495, 12),
          
          writePDFText(1 , 0 , 0  , "0 parameters:",20, startY - 510, 10),
          
          
          writePDFText(0 , 0 , 0 ,"grandMA3 4Port Node:",20, startY - 530, 12),
          
          writePDFText(1 , 0 , 0 , "0 parameters.",20, startY - 545, 10),
          
          
          writePDFText(0 , 0 , 0 ,"grandMA3 2Port Node:",300, startY - 180, 12),
          writePDFText(1 , 0 , 0  ,"0 parameters.",300, startY - 195, 10),
          
          
          
          writePDFText(0 , 0 , 0 ,"grandMA3 8Port Node DIN-Rail:",300, startY - 215, 12),
          writePDFText(1 , 0 , 0 , "0 parameters.",300, startY - 230, 10),
          
          
          writePDFText(0 , 0 , 0 ,"grandMA3 4Port Node DIN-Rail:",300, startY - 250, 12),
          writePDFText(1 , 0 , 0 ,"0 parameters.",300, startY - 265, 10),
          
          
          
          writePDFText(0 , 0 , 0 ,"grandMA3 2Port Node DIN-Rail:",300, startY - 285, 12),
          writePDFText(1 , 0 , 0  , "0 parameters.",300, startY - 300 , 10),
          
          
          
          writePDFText(0 , 0 , 0 ,"grandMA3 onPC command wing XT:",300, startY - 320, 12),
          writePDFText(1 , 0 , 0  ,"4 096 parameters.", 300, startY - 335, 10),
          
          
          
          writePDFText(0 , 0 , 0 ,"grandMA3 onPC command wing:",300, startY - 355, 12),
          writePDFText(1 , 0 , 0 ,"2 048 parameters.",300, startY - 380, 10),
          
          
          
          writePDFText(0 , 0 , 0 ,"grandMA3 onPC 8Port Node 4k:",  300, startY - 395, 12),
          writePDFText(1 , 0 , 0 ,"4 096 parameters (when connected to grandMA2 2 048 parameters).", 300, startY - 415, 10),
          
          
          
          writePDFText(0 , 0 , 0 ,"grandMA3 onPC 4Port Node 4k:",  300, startY - 440, 12),
          writePDFText(1 , 0 , 0 ,"4 096 parameters (when connected to grandMA2 2 048 parameters).", 300, startY - 455, 10),
          
          
          writePDFText(0 , 0 , 0 ,"grandMA3 onPC 2Port Node 2k:",  300, startY - 475, 12),
          writePDFText(1 , 0 , 0 ,"4 096 parameters (when connected to grandMA2 2 048 parameters).", 300, startY - 490, 10),
          
          
          
          writePDFText(0 , 0 , 0 ,"grandMA3 onPC Software:",  300, startY -  510, 12),
          writePDFText(1 , 0 , 0 ,"0 parameters.",  300, startY - 525, 10),
          
          
            })

      -- Écriture dans le fichier PDF
      file:write("1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n")
      file:write("2 0 obj\n<< /Type /Pages /Count 1 /Kids [3 0 R] >>\nendobj\n")
      file:write("3 0 obj\n<< /Type /Page /Parent 2 0 R /MediaBox [0 0 " .. pageWidth .. " " .. pageHeight .. "] /Contents 4 0 R >>\nendobj\n")
      file:write("4 0 obj\n<< /Length " .. #pdfContent .. " >>\nstream\n" .. pdfContent .. "endstream\nendobj\n")
      file:write("xref\n0 5\n0000000000 65535 f\n0000000010 00000 n\n0000000050 00000 n\n0000000100 00000 n\n0000000200 00000 n\n")
      file:write("trailer\n<< /Size 5 /Root 1 0 R >>\nstartxref\n200\n%%EOF")

      file:close()
  end

  
  
  
  local inputs = {
          {name = "Documents Name :",values = defaultFileName},-- MODIFIE LE NOM PAR DEFAULT DU DOCUMENTS PDF !
          { name = "Users" , values = usersName, }}-- MODIFIE LE NOM DE L'AUTEUR PAR DEFAULT PAR CELUI VOULUES

  local selectors = {
          { name="USB DRIVES", values={}, selectedValue =2,  type=1},
          { name = "Statistic Tables", selectedValue=2, values ={["Include"]=1 , ["Exclude"]=2} , type=1}
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
        message = "Enter a name for your document and specify the programmer's name. If you want to include a statistics page, select 'Include' from the options. Then, click 'OK' to generate the PDF. Make sure a USB stick is connected for saving.",
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
    
  if settings.result == 1 then 
      for k , v in pairs(settings.selectors) do
    if k == 'USB DRIVES' then 
     
      drivePath = drive[v].path
    end
  end
  
     if settings.selectors["Statistic Tables"] == 1 then
       StatisticgenPdf(drivePath) 
       end
    
    if settings.inputs["Documents Name :"] == nil then
     fileName ="Documents"
     else
   fileName = settings.inputs["Documents Name :"]
 end
 
   if settings.inputs["Users"] == nil then 
     local UsersName = "User 1" 
     else
    local UsersName = settings.inputs["Users"]  
  end
  
    
    local FixturesData = collectFixtureData()
    generatePDF(drivePath, FixturesData, fileName, UsersName)

elseif settings.result == 0 then 

MessageBox({ 
    title = "Error E3",
    message = "No values entry",
    messageTextColor = "Global.Text",
    icon = "logo_small",
    commands = {{value = 1, name = "Ok"}, {value = 0, name = "Cancel"}},
    })
end
end 

fixtureCount = -1   
groupingCount = 0 

  function extractFixturesFromGrouping(grouping, AllPatch, indent)
      indent = indent or "" 

      -- Vérifier si le grouping a des enfants
      local children = grouping:Children()
      for _, child in ipairs(children) do
          
          if child.fixturetype and child.fixturetype.name == "Grouping" then
                groupingCount = groupingCount + 1  
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
              fixtureCount = fixtureCount + 1
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
      AllPatch = {}

      for _, stages in ipairs(Patch().Stages) do 
          for _, fixture in ipairs(stages.fixtures) do
             if fixture.fixturetype and fixture.fixturetype.name == "Grouping" then
                  groupingCount = groupingCount + 1
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
                  fixtureCount = fixtureCount + 1  
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
      tostring(displayHandle) 

      if argument then
        usbStickConnected()

      else
          usbStickConnected()
      end
  end

  return Main
