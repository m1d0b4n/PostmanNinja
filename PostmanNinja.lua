-- PostmanNinja 
-- Addon pour poster automatiquement plusieurs messages à chaque connexion

local addonName = "PostmanNinja"
local frame = CreateFrame("Frame", "PostmanNinjaFrame", UIParent)
local mainFrame = nil
local currentJobIndex = 1

-- Base de données par défaut
local defaults = {
    jobs = {
        {
            name = "Job 1",
            enabled = false,
            messages = {"POST TEXT!"},
            channel = "GUILD",
            whisperTarget = "",
        }
    },
    popupX = nil,
    popupY = nil,
}

-- Initialisation de la DB
local function InitDB()
    -- Migration depuis ChatAutoPosterDB
    if ChatAutoPosterDB and not PostmanNinjaDB then
        PostmanNinjaDB = ChatAutoPosterDB
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[PostmanNinja]|r Migration depuis ChatAutoPoster réussie !", 0, 255, 0)
    end
    
    if not PostmanNinjaDB then
        PostmanNinjaDB = {}
    end
    
    -- Migration de l'ancien format vers le système de jobs
    if PostmanNinjaDB.enabled ~= nil or PostmanNinjaDB.messages then
        PostmanNinjaDB.jobs = {
            {
                name = "Job 1",
                enabled = PostmanNinjaDB.enabled or false,
                messages = PostmanNinjaDB.messages or {"POST TEXT!"},
                channel = PostmanNinjaDB.channel or "GUILD",
                whisperTarget = "",
            }
        }
        PostmanNinjaDB.enabled = nil
        PostmanNinjaDB.messages = nil
        PostmanNinjaDB.message = nil
        PostmanNinjaDB.channel = nil
    end
    
    for k, v in pairs(defaults) do
        if PostmanNinjaDB[k] == nil then
            PostmanNinjaDB[k] = v
        end
    end
    
    -- S'assurer qu'on a au moins un job
    if not PostmanNinjaDB.jobs or #PostmanNinjaDB.jobs == 0 then
        PostmanNinjaDB.jobs = defaults.jobs
    end
    
    -- S'assurer que chaque job a au moins un message
    for _, job in ipairs(PostmanNinjaDB.jobs) do
        if not job.messages or #job.messages == 0 then
            job.messages = {"POST TEXT!"}
        end
        if not job.whisperTarget then
            job.whisperTarget = ""
        end
    end
end

-- Fonction pour envoyer le message d'un job
local function SendJobMessage(job, forceTest)
    if not job.enabled and not forceTest then
        return
    end
    
    local channel = job.channel
    
    -- Filtrer les messages vides
    local validMessages = {}
    for _, message in ipairs(job.messages) do
        local trimmed = strtrim(message)
        if trimmed ~= "" then
            table.insert(validMessages, trimmed)
        end
    end
    
    if #validMessages == 0 then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[" .. job.name .. "]|r Aucun message configuré !", 255, 0, 0)
        return
    end
    
    -- Choisir un message aléatoire
    local msg = validMessages[math.random(1, #validMessages)]
    
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00[" .. job.name .. "]|r Envoi: \"" .. msg .. "\" dans " .. channel, 255, 255, 0)
    
    local success, err = pcall(function()
        if channel == "GUILD" then
            SendChatMessage(msg, "GUILD")
        elseif channel == "SAY" then
            SendChatMessage(msg, "SAY")
        elseif channel == "YELL" then
            SendChatMessage(msg, "YELL")
        elseif channel == "PARTY" then
            SendChatMessage(msg, "PARTY")
        elseif channel == "RAID" then
            SendChatMessage(msg, "RAID")
        elseif channel == "WHISPER" then
            if not job.whisperTarget or job.whisperTarget == "" then
                error("Aucune cible de chuchotement définie")
            end
            -- Vérifier si le joueur est en ligne
            local isOnline = false
            local numFriends = C_FriendList.GetNumFriends()
            for i = 1, numFriends do
                local friendInfo = C_FriendList.GetFriendInfoByIndex(i)
                if friendInfo and friendInfo.name == job.whisperTarget and friendInfo.connected then
                    isOnline = true
                    break
                end
            end
            
            if isOnline then
                SendChatMessage(msg, "WHISPER", nil, job.whisperTarget)
            else
                error(job.whisperTarget .. " n'est pas en ligne")
            end
        end
    end)
    
    if not success then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[" .. job.name .. "]|r Erreur: " .. tostring(err), 255, 0, 0)
    end
end

-- Fonction pour envoyer tous les jobs actifs
local function SendAllActiveJobs()
    for _, job in ipairs(PostmanNinjaDB.jobs) do
        if job.enabled then
            SendJobMessage(job, false)
        end
    end
end

-- Création de l'interface
local function CreateUI()
    if mainFrame then return end
    
    -- Frame principale
    mainFrame = CreateFrame("Frame", "PostmanNinjaMainFrame", UIParent, "BackdropTemplate")
    mainFrame:SetSize(520, 420)
    mainFrame:SetPoint("CENTER")
    mainFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    mainFrame:SetBackdropColor(0, 0, 0, 1)
    mainFrame:EnableMouse(true)
    mainFrame:SetMovable(true)
    mainFrame:RegisterForDrag("LeftButton")
    mainFrame:SetScript("OnDragStart", mainFrame.StartMoving)
    mainFrame:SetScript("OnDragStop", mainFrame.StopMovingOrSizing)
    mainFrame:SetScript("OnMouseDown", function(self)
        -- Permet de quitter l'édition en cliquant ailleurs
        if GetCurrentKeyBoardFocus() then
            GetCurrentKeyBoardFocus():ClearFocus()
        end
    end)
    mainFrame:Hide()
    
    -- Bouton fermer
    local closeButton = CreateFrame("Button", nil, mainFrame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", -5, -5)
    
    -- Titre
    local title = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -20)
    title:SetText("PostmanNinja")
    
    -- Zone des onglets avec scroll horizontal
    local tabScrollFrame = CreateFrame("ScrollFrame", nil, mainFrame)
    tabScrollFrame:SetPoint("TOPLEFT", 20, -50)
    tabScrollFrame:SetSize(410, 30)
    tabScrollFrame:EnableMouseWheel(true)
    tabScrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local current = self:GetHorizontalScroll()
        local maxScroll = self:GetHorizontalScrollRange()
        local newScroll = math.max(0, math.min(maxScroll, current - (delta * 40)))
        self:SetHorizontalScroll(newScroll)
    end)
    
    local tabContainer = CreateFrame("Frame", nil, tabScrollFrame)
    tabContainer:SetSize(410, 30)
    tabScrollFrame:SetScrollChild(tabContainer)
    
    mainFrame.tabs = {}
    mainFrame.tabContainer = tabContainer
    mainFrame.tabScrollFrame = tabScrollFrame
    
    -- Fonction pour créer un onglet
    local function CreateTab(index)
        local tab = CreateFrame("Button", nil, tabContainer)
        tab:SetSize(75, 24)
        tab:SetNormalFontObject("GameFontNormalSmall")
        tab:SetHighlightFontObject("GameFontHighlightSmall")
        
        -- Background de l'onglet
        local bg = tab:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(0.2, 0.2, 0.2, 0.8)
        tab.bg = bg
        
        local label = tab:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        label:SetPoint("CENTER")
        label:SetText(PostmanNinjaDB.jobs[index].name)
        tab.label = label
        
        tab:SetScript("OnClick", function()            if GetCurrentKeyBoardFocus() then
                GetCurrentKeyBoardFocus():ClearFocus()
            end            currentJobIndex = index
            mainFrame.RefreshUI()
        end)
        
        return tab
    end
    
    -- Bouton + pour ajouter un job (fixe à droite)
    local addJobButton = CreateFrame("Button", nil, mainFrame, "UIPanelButtonTemplate")
    addJobButton:SetSize(24, 24)
    addJobButton:SetPoint("TOPLEFT", 435, -50)
    addJobButton:SetText("+")
    addJobButton:SetScript("OnClick", function()
        if GetCurrentKeyBoardFocus() then
            GetCurrentKeyBoardFocus():ClearFocus()
        end
        table.insert(PostmanNinjaDB.jobs, {
            name = "Job " .. (#PostmanNinjaDB.jobs + 1),
            enabled = false,
            messages = {"Nouveau message"},
            channel = "GUILD",
            whisperTarget = "",
        })
        currentJobIndex = #PostmanNinjaDB.jobs
        mainFrame.RefreshUI()
    end)
    mainFrame.addJobButton = addJobButton
    
    -- Bouton supprimer job (fixe à droite)
    local deleteJobButton = CreateFrame("Button", nil, mainFrame, "UIPanelButtonTemplate")
    deleteJobButton:SetSize(24, 24)
    deleteJobButton:SetPoint("TOPLEFT", 464, -50)
    deleteJobButton:SetText("X")
    deleteJobButton:SetScript("OnClick", function()
        if GetCurrentKeyBoardFocus() then
            GetCurrentKeyBoardFocus():ClearFocus()
        end
        if #PostmanNinjaDB.jobs > 1 then
            table.remove(PostmanNinjaDB.jobs, currentJobIndex)
            currentJobIndex = math.min(currentJobIndex, #PostmanNinjaDB.jobs)
            mainFrame.RefreshUI()
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[PostmanNinja]|r Il doit y avoir au moins un job !", 255, 0, 0)
        end
    end)
    mainFrame.deleteJobButton = deleteJobButton
    
    -- Zone de contenu du job actuel
    local contentFrame = CreateFrame("Frame", nil, mainFrame, "BackdropTemplate")
    contentFrame:SetPoint("TOPLEFT", 20, -100)
    contentFrame:SetSize(480, 265)
    contentFrame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    contentFrame:SetBackdropColor(0, 0, 0, 0.5)
    contentFrame:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
    contentFrame:SetScript("OnMouseDown", function()
        if GetCurrentKeyBoardFocus() then
            GetCurrentKeyBoardFocus():ClearFocus()
        end
    end)
    
    mainFrame.contentFrame = contentFrame
    mainFrame.contentElements = {}
    
    -- Boutons du bas
    local testButton = CreateFrame("Button", nil, mainFrame, "UIPanelButtonTemplate")
    testButton:SetSize(100, 28)
    testButton:SetPoint("BOTTOMLEFT", 30, 15)
    testButton:SetText("Test Job")
    testButton:SetScript("OnClick", function()
        if GetCurrentKeyBoardFocus() then
            GetCurrentKeyBoardFocus():ClearFocus()
        end
        SendJobMessage(PostmanNinjaDB.jobs[currentJobIndex], true)
    end)
    
    local testAllButton = CreateFrame("Button", nil, mainFrame, "UIPanelButtonTemplate")
    testAllButton:SetSize(120, 28)
    testAllButton:SetPoint("BOTTOM", 0, 15)
    testAllButton:SetText("Test Tous")
    testAllButton:SetScript("OnClick", function()
        if GetCurrentKeyBoardFocus() then
            GetCurrentKeyBoardFocus():ClearFocus()
        end
        SendAllActiveJobs()
    end)
    
    local reloadButton = CreateFrame("Button", nil, mainFrame, "UIPanelButtonTemplate")
    reloadButton:SetSize(100, 28)
    reloadButton:SetPoint("BOTTOMRIGHT", -30, 15)
    reloadButton:SetText("Recharger")
    reloadButton:SetScript("OnClick", function()
        if GetCurrentKeyBoardFocus() then
            GetCurrentKeyBoardFocus():ClearFocus()
        end
        ReloadUI()
    end)
    
    -- Fonction pour rafraîchir tout le contenu
    function mainFrame.RefreshUI()
        -- Nettoyer les anciens onglets
        for _, tab in ipairs(mainFrame.tabs) do
            tab:Hide()
            tab:SetParent(nil)
        end
        mainFrame.tabs = {}
        
        local totalWidth = 0
        for i, job in ipairs(PostmanNinjaDB.jobs) do
            local tab = CreateTab(i)
            mainFrame.tabs[i] = tab
            tab:SetPoint("LEFT", (i-1) * 78, 0)
            tab.label:SetText(job.name)
            
            -- Highlight de l'onglet actif
            if i == currentJobIndex then
                tab.bg:SetColorTexture(0.4, 0.4, 0.1, 1)
            else
                tab.bg:SetColorTexture(0.2, 0.2, 0.2, 0.8)
            end
            tab:Show()
            totalWidth = i * 78
        end
        
        -- Ajuster la largeur du container pour activer le scroll si nécessaire
        mainFrame.tabContainer:SetWidth(math.max(410, totalWidth))
        
        -- Nettoyer le contenu
        for _, element in ipairs(mainFrame.contentElements) do
            element:Hide()
            element:SetParent(nil)
        end
        mainFrame.contentElements = {}
        
        -- Recréer le contenu pour le job actif
        local job = PostmanNinjaDB.jobs[currentJobIndex]
        local yOffset = -10
        
        -- Champ nom du job
        local nameLabel = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        nameLabel:SetPoint("TOPLEFT", 10, yOffset)
        nameLabel:SetText("Nom:")
        table.insert(mainFrame.contentElements, nameLabel)
        
        local nameBox = CreateFrame("EditBox", nil, contentFrame, "BackdropTemplate")
        nameBox:SetSize(200, 20)
        nameBox:SetPoint("LEFT", nameLabel, "RIGHT", 10, 0)
        nameBox:SetAutoFocus(false)
        nameBox:SetFontObject(GameFontHighlight)
        nameBox:SetMaxLetters(13)
        nameBox:SetText(job.name)
        nameBox:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 8, edgeSize = 8,
            insets = { left = 2, right = 2, top = 2, bottom = 2 }
        })
        nameBox:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
        nameBox:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
        nameBox:SetScript("OnEscapePressed", function(self) 
            self:SetText(job.name)
            self:ClearFocus() 
        end)
        nameBox:SetScript("OnEnterPressed", function(self) 
            local newName = strtrim(self:GetText())
            if newName == "" then
                self:SetText(job.name)
            else
                job.name = newName
            end
            self:ClearFocus()
            mainFrame.RefreshUI()
        end)
        nameBox:SetScript("OnEditFocusLost", function(self)
            local newName = strtrim(self:GetText())
            if newName == "" then
                self:SetText(job.name)
            else
                job.name = newName
            end
            mainFrame.RefreshUI()
        end)
        table.insert(mainFrame.contentElements, nameBox)
        
        -- Checkbox Activé
        local enabledCheck = CreateFrame("CheckButton", nil, contentFrame, "UICheckButtonTemplate")
        enabledCheck:SetPoint("LEFT", nameBox, "RIGHT", 20, 0)
        enabledCheck:SetSize(24, 24)
        enabledCheck:SetChecked(job.enabled)
        enabledCheck:SetScript("OnClick", function(self)
            job.enabled = self:GetChecked()
        end)
        table.insert(mainFrame.contentElements, enabledCheck)
        
        local enabledLabel = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        enabledLabel:SetPoint("LEFT", enabledCheck, "RIGHT", 5, 0)
        enabledLabel:SetText("Activé")
        table.insert(mainFrame.contentElements, enabledLabel)
        
        yOffset = yOffset - 35
        
        -- Messages avec ScrollFrame
        local msgLabel = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        msgLabel:SetPoint("TOPLEFT", 10, yOffset)
        msgLabel:SetText("Messages (variantes):")
        table.insert(mainFrame.contentElements, msgLabel)
        
        yOffset = yOffset - 20
        
        -- ScrollFrame pour les messages
        local scrollFrame = CreateFrame("ScrollFrame", nil, contentFrame, "UIPanelScrollFrameTemplate")
        scrollFrame:SetPoint("TOPLEFT", 10, yOffset)
        scrollFrame:SetSize(435, 150)
        table.insert(mainFrame.contentElements, scrollFrame)
        
        local scrollChild = CreateFrame("Frame", nil, scrollFrame)
        scrollChild:SetWidth(400)
        scrollFrame:SetScrollChild(scrollChild)
        
        local scrollBg = CreateFrame("Frame", nil, contentFrame, "BackdropTemplate")
        scrollBg:SetPoint("TOPLEFT", 8, yOffset + 2)
        scrollBg:SetSize(440, 154)
        scrollBg:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 8, edgeSize = 8,
            insets = { left = 2, right = 2, top = 2, bottom = 2 }
        })
        scrollBg:SetBackdropColor(0.05, 0.05, 0.05, 0.9)
        scrollBg:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
        table.insert(mainFrame.contentElements, scrollBg)
        
        local msgYOffset = -5
        
        -- Liste des messages
        for i, message in ipairs(job.messages) do
            local msgBox = CreateFrame("EditBox", nil, scrollChild, "BackdropTemplate")
            msgBox:SetSize(355, 20)
            msgBox:SetPoint("TOPLEFT", 5, msgYOffset)
            msgBox:SetAutoFocus(false)
            msgBox:SetFontObject(GameFontNormalSmall)
            msgBox:SetMaxLetters(255)
            msgBox:SetText(message)
            msgBox:SetBackdrop({
                bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                tile = true, tileSize = 8, edgeSize = 8,
                insets = { left = 2, right = 2, top = 2, bottom = 2 }
            })
            msgBox:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
            msgBox:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
            msgBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
            msgBox:SetScript("OnTextChanged", function(self)
                job.messages[i] = self:GetText()
            end)
            msgBox:SetScript("OnEditFocusLost", function(self)
                -- Supprimer les messages vides (sauf s'il n'en reste qu'un)
                if #job.messages > 1 then
                    local cleaned = {}
                    for _, msg in ipairs(job.messages) do
                        if strtrim(msg) ~= "" then
                            table.insert(cleaned, msg)
                        end
                    end
                    if #cleaned > 0 and #cleaned ~= #job.messages then
                        job.messages = cleaned
                        mainFrame.RefreshUI()
                    end
                end
            end)
            
            -- Auto-focus sur le dernier message si demandé
            if i == #job.messages and mainFrame.focusLastMessage then
                C_Timer.After(0.1, function()
                    msgBox:SetFocus()
                end)
                mainFrame.focusLastMessage = false
            end
            
            -- Bouton supprimer message
            local delBtn = CreateFrame("Button", nil, scrollChild, "UIPanelButtonTemplate")
            delBtn:SetSize(40, 20)
            delBtn:SetPoint("LEFT", msgBox, "RIGHT", 5, 0)
            delBtn:SetText("-")
            delBtn:SetScript("OnClick", function()
                if #job.messages > 1 then
                    table.remove(job.messages, i)
                    mainFrame.RefreshUI()
                else
                    DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[PostmanNinja]|r Au moins 1 message requis!", 255, 0, 0)
                end
            end)
            
            msgYOffset = msgYOffset - 25
        end
        
        -- Bouton ajouter message
        local addMsgBtn = CreateFrame("Button", nil, scrollChild, "UIPanelButtonTemplate")
        addMsgBtn:SetSize(150, 22)
        addMsgBtn:SetPoint("TOPLEFT", 5, msgYOffset)
        addMsgBtn:SetText("+ Ajouter variante")
        addMsgBtn:SetScript("OnClick", function()
            -- Forcer la perte de focus pour nettoyer les champs vides avant d'ajouter
            if GetCurrentKeyBoardFocus() then
                GetCurrentKeyBoardFocus():ClearFocus()
                -- Attendre que le nettoyage soit fait avant d'ajouter
                C_Timer.After(0.05, function()
                    table.insert(job.messages, "")
                    mainFrame.focusLastMessage = true
                    mainFrame.RefreshUI()
                end)
            else
                table.insert(job.messages, "")
                mainFrame.focusLastMessage = true
                mainFrame.RefreshUI()
            end
        end)
        
        scrollChild:SetHeight(math.abs(msgYOffset) + 30)
        
        yOffset = yOffset - 166
        
        -- Canal
        local chanLabel = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        chanLabel:SetPoint("TOPLEFT", 10, yOffset)
        chanLabel:SetText("Canal:")
        table.insert(mainFrame.contentElements, chanLabel)
        
        local chanDropdown = CreateFrame("Frame", "PostmanNinjaChanDrop"..currentJobIndex, contentFrame, "UIDropDownMenuTemplate")
        chanDropdown:SetPoint("LEFT", chanLabel, "RIGHT", 0, -3)
        
        local channels = {
            {text = "Guilde", value = "GUILD"},
            {text = "Dire", value = "SAY"},
            {text = "Crier", value = "YELL"},
            {text = "Groupe", value = "PARTY"},
            {text = "Raid", value = "RAID"},
            {text = "Chuchoter", value = "WHISPER"},
        }
        
        UIDropDownMenu_Initialize(chanDropdown, function()
            for _, channel in ipairs(channels) do
                local info = UIDropDownMenu_CreateInfo()
                info.text = channel.text
                info.value = channel.value
                info.func = function()
                    job.channel = channel.value
                    UIDropDownMenu_SetSelectedValue(chanDropdown, channel.value)
                    mainFrame.RefreshUI()
                end
                UIDropDownMenu_AddButton(info)
            end
        end)
        
        UIDropDownMenu_SetWidth(chanDropdown, 120)
        UIDropDownMenu_SetSelectedValue(chanDropdown, job.channel)
        table.insert(mainFrame.contentElements, chanDropdown)
        
        -- Champ cible de chuchotement (si WHISPER)
        if job.channel == "WHISPER" then
            local targetLabel = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            targetLabel:SetPoint("LEFT", chanDropdown, "RIGHT", 30, 3)
            targetLabel:SetText("Cible:")
            table.insert(mainFrame.contentElements, targetLabel)
            
            local targetEditBox = CreateFrame("EditBox", nil, contentFrame, "InputBoxTemplate")
            targetEditBox:SetSize(120, 20)
            targetEditBox:SetPoint("LEFT", targetLabel, "RIGHT", 10, 0)
            targetEditBox:SetAutoFocus(false)
            targetEditBox:SetText(job.whisperTarget or "")
            targetEditBox:SetScript("OnTextChanged", function(self)
                job.whisperTarget = self:GetText()
            end)
            targetEditBox:SetScript("OnEnterPressed", function(self)
                self:ClearFocus()
            end)
            targetEditBox:SetScript("OnEscapePressed", function(self)
                self:ClearFocus()
            end)
            table.insert(mainFrame.contentElements, targetEditBox)
        end
    end
    
    -- Initialiser l'UI
    mainFrame.RefreshUI()
end

-- Toggle UI
local function ToggleUI()
    if not mainFrame then
        CreateUI()
    end
    
    if mainFrame:IsShown() then
        mainFrame:Hide()
    else
        mainFrame:Show()
        if mainFrame.RefreshUI then
            mainFrame.RefreshUI()
        end
    end
end

-- Création du popup d'envoi automatique
local function ShowAutoSendPopup()
    -- Compter les jobs actifs
    local activeJobs = {}
    for _, job in ipairs(PostmanNinjaDB.jobs) do
        if job.enabled then
            table.insert(activeJobs, job)
        end
    end
    
    if #activeJobs == 0 then
        return
    end
    
    -- Créer un popup frame
    local popup = CreateFrame("Frame", "PostmanNinjaPopup", UIParent, "BackdropTemplate")
    popup:SetWidth(350)
    popup:SetHeight(120)
    popup:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    popup:SetBackdropColor(0, 0, 0, 0.95)
    popup:SetFrameStrata("DIALOG")
    popup:EnableMouse(true)
    popup:SetMovable(true)
    popup:RegisterForDrag("LeftButton")
    popup:SetClampedToScreen(true)
    
    -- Restaurer la position
    if PostmanNinjaDB.popupX and PostmanNinjaDB.popupY then
        popup:ClearAllPoints()
        popup:SetPoint("CENTER", UIParent, "CENTER", PostmanNinjaDB.popupX, PostmanNinjaDB.popupY)
    else
        popup:SetPoint("CENTER", 0, 200)
    end
    
    popup:SetScript("OnDragStart", function(self) self:StartMoving() end)
    popup:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local x, y = self:GetCenter()
        local screenWidth = UIParent:GetWidth()
        local screenHeight = UIParent:GetHeight()
        PostmanNinjaDB.popupX = x - (screenWidth / 2)
        PostmanNinjaDB.popupY = y - (screenHeight / 2)
    end)
    
    -- Titre
    local title = popup:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -15)
    title:SetText("PostmanNinja ")
    title:SetTextColor(1, 0.8, 0)
    
    -- Message
    local text = popup:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("TOP", 0, -40)
    text:SetWidth(320)
    text:SetText("Envoyer " .. #activeJobs .. " job(s) actif(s) ?")
    
    -- Bouton Envoyer
    local sendBtn = CreateFrame("Button", nil, popup, "UIPanelButtonTemplate")
    sendBtn:SetWidth(120)
    sendBtn:SetHeight(30)
    sendBtn:SetPoint("BOTTOM", -65, 15)
    sendBtn:SetText("Envoyer")
    sendBtn:SetScript("OnClick", function()
        SendAllActiveJobs()
        popup:Hide()
    end)
    
    -- Bouton Ignorer
    local ignoreBtn = CreateFrame("Button", nil, popup, "UIPanelButtonTemplate")
    ignoreBtn:SetWidth(120)
    ignoreBtn:SetHeight(30)
    ignoreBtn:SetPoint("BOTTOM", 65, 15)
    ignoreBtn:SetText("Ignorer")
    ignoreBtn:SetScript("OnClick", function()
        popup:Hide()
    end)
    
    popup:Show()
end

-- Event handler
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        InitDB()
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00PostmanNinja |r chargé. /pmn pour ouvrir", 0, 255, 0)
    elseif event == "PLAYER_LOGIN" then
        local loginTimer = 0
        local timerFrame = CreateFrame("Frame")
        timerFrame:SetScript("OnUpdate", function(self, elapsed)
            loginTimer = loginTimer + elapsed
            if loginTimer >= 3 then
                ShowAutoSendPopup()
                self:SetScript("OnUpdate", nil)
            end
        end)
    end
end)

-- Slash commands
SLASH_POSTMANNINJA1 = "/pmn"
SLASH_POSTMANNINJA2 = "/postmanninja"
SlashCmdList["POSTMANNINJA"] = function(msg)
    if not msg then msg = "" end
    msg = string.lower(string.gsub(msg, "^%s*(.-)%s*$", "%1"))
    
    if msg == "reload" or msg == "rl" then
        ReloadUI()
    else
        ToggleUI()
    end
end
