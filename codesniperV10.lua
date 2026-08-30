-- CodeSniper V6 - Manual Whitelist
-- Upload whitelist.json to GitHub and put its RAW URL below.
local WHITELIST_URL = "https://raw.githubusercontent.com/SigMaUgI/codesniper/refs/heads/main/whitelist.json"

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

local function Normalize(value)
    return string.lower(tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

local function FetchWhitelist(noCache)
    local url = WHITELIST_URL
    if noCache then
        local separator = string.find(url, "?", 1, true) and "&" or "?"
        url = url .. separator .. "v=" .. tostring(math.floor(tick() * 1000))
    end

    local ok, body = pcall(function()
        -- Use the SAME HttpGet method that loads this script.
        return game:HttpGet(url)
    end)

    if not ok or type(body) ~= "string" or body == "" then
        return nil, "FETCH_FAILED"
    end

    local decodedOk, data = pcall(function()
        return HttpService:JSONDecode(body)
    end)

    if not decodedOk or type(data) ~= "table" then
        return nil, "BAD_JSON"
    end

    return data, nil
end

local function CheckWhitelist(noCache)
    local data, err = FetchWhitelist(noCache)
    if not data then
        return nil, err
    end

    local myId = tostring(LocalPlayer.UserId)
    local myName = Normalize(LocalPlayer.Name)

    -- V10 uses ONE record per allowed person.
    -- Removing the record removes BOTH username and UserId access.
    if type(data.allowed_users) == "table" then
        for _, user in pairs(data.allowed_users) do
            if type(user) == "table" then
                local savedId = tostring(user.user_id or ""):gsub("%s+", "")
                local savedName = Normalize(user.username)

                if savedId ~= "" and savedId == myId then
                    return true, "USER_ID"
                end

                if savedName ~= "" and savedName == myName then
                    return true, "USERNAME"
                end
            end
        end
    end

    return false, "NOT_LISTED"
end

local function WaitForInitialAccess()
    for attempt = 1, 4 do
        local allowed, reason = CheckWhitelist(attempt > 1)

        if allowed == true then
            print("CodeSniper whitelist AUTHORIZED via " .. tostring(reason))
            return true
        end

        if allowed == false then
            warn("CodeSniper whitelist DENIED for " .. LocalPlayer.Name .. " / " .. tostring(LocalPlayer.UserId))
            return false
        end

        warn("CodeSniper whitelist fetch problem: " .. tostring(reason))
        task.wait(0.5)
    end

    return nil
end

-- NOTHING from CodeSniper runs unless access is confirmed.
local initialAccess = WaitForInitialAccess()

if initialAccess == false then
    LocalPlayer:Kick("You don't have access")
    return
elseif initialAccess == nil then
    LocalPlayer:Kick("Whitelist check failed. Try again.")
    return
end

local function StartCodeSniper()
    local Players = game:GetService("Players")
    local UserInputService = game:GetService("UserInputService")
    local VirtualInputManager = game:GetService("VirtualInputManager")
    local Player = Players.LocalPlayer

    -- Discord spawn notifier.
    local DISCORD_WEBHOOK = "https://discord.com/api/webhooks/1543471879170564147/6GB3mUHORNr5lVJGcCkPJJ5KaQs4OpqNpUq-gDD_KjkMT-dUShgwB6ilMdn3vhZ2LVoP"
    local CODE_SNIPER_AVATAR = "https://placehold.co/256x256/111111/ff9b19.png?text=FTX%0ASniper"
    local WEBHOOK_USERNAME = "FTX Sniper"

    -- Exact fallback image supplied by the user. This is uploaded directly to
    -- Discord whenever a brainrot image cannot be found/downloaded.
    local IMAGE_NOT_FOUND_B64 = [[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]]

    local function Base64Decode(data)
        local alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
        data = tostring(data or ""):gsub("[^" .. alphabet .. "=]", "")

        return (data:gsub(".", function(x)
            if x == "=" then return "" end
            local r, f = "", (alphabet:find(x, 1, true) or 1) - 1
            for i = 6, 1, -1 do
                r = r .. ((f % 2 ^ i - f % 2 ^ (i - 1) > 0) and "1" or "0")
            end
            return r
        end):gsub("%d%d%d?%d?%d?%d?%d?%d?", function(x)
            if #x ~= 8 then return "" end
            local c = 0
            for i = 1, 8 do
                if x:sub(i, i) == "1" then
                    c = c + 2 ^ (8 - i)
                end
            end
            return string.char(c)
        end))
    end

    local IMAGE_NOT_FOUND_BYTES = Base64Decode(IMAGE_NOT_FOUND_B64)

    local SpawnWebhookState = {
        name = nil,
        user = nil,
        count = 0,
        message_id = nil
    }

    local PlayerGui = Player:WaitForChild("PlayerGui")

    -- SETTINGS
    local CopierEnabled = true
    local RiddleSolverEnabled = false -- removed from UI
    local PrepareEnabled = true
    local AfterSubmitEnabled = true
    local SmartRedeemerEnabled = false
    local SubmitAfter = 3

    -- V18 contains no Radar / Player Highlight implementation.
    -- Keep those features explicitly disabled.
    local RadarEnabled = false
    local PlayerHighlightEnabled = false

    -- Persistent UI/settings preferences (executor file APIs when supported).
    local PREF_FILE = "codesniper_preferences.json"

    local function LoadPreferences()
        if not isfile or not readfile or not isfile(PREF_FILE) then
            return
        end

        local ok, data = pcall(function()
            return HttpService:JSONDecode(readfile(PREF_FILE))
        end)

        if not ok or type(data) ~= "table" then
            return
        end

        if type(data.CopierEnabled) == "boolean" then CopierEnabled = data.CopierEnabled end
        if type(data.PrepareEnabled) == "boolean" then PrepareEnabled = data.PrepareEnabled end
        if type(data.AfterSubmitEnabled) == "boolean" then AfterSubmitEnabled = data.AfterSubmitEnabled end
        if type(data.SmartRedeemerEnabled) == "boolean" then SmartRedeemerEnabled = data.SmartRedeemerEnabled end
        if type(data.SubmitAfter) == "number" then
            SubmitAfter = math.clamp(math.floor(data.SubmitAfter), 1, 5)
        end
    end

    local function SavePreferences()
        if not writefile then
            return
        end

        local data = {
            CopierEnabled = CopierEnabled,
            PrepareEnabled = PrepareEnabled,
            AfterSubmitEnabled = AfterSubmitEnabled,
            SmartRedeemerEnabled = SmartRedeemerEnabled,
            SubmitAfter = SubmitAfter
        }

        pcall(function()
            writefile(PREF_FILE, HttpService:JSONEncode(data))
        end)
    end

    LoadPreferences()

    local WaitingForCode = false
    local Submitting = false
    local CurrentMessages = {}
    local AllCaptured = {}
    local Hooked = {}
    local LastText = {}

local SmartAwaitingResult = false
local SmartNeedsNextMessage = false
local SmartRetrying = false
local SmartAttemptId = 0

    -- Riddle Solver state
    local RiddleActive = false
    local RiddleAnswers = {}
    local RiddleFacts = {
        name = nil,
        weight = nil,
        age = nil,
        color = nil,
        number = nil,
        birthday = nil
    }
    local RiddleLastText = {}

    -- GAME UI REFERENCES
    local CodesScreen, CodesFrame, CodeRedeemFrame, CodeBox, SubmitButton

    -- COLORS
    local BG = Color3.fromRGB(7,7,7)
    local BG2 = Color3.fromRGB(13,13,13)
    local BG3 = Color3.fromRGB(24,18,8)
    local WHITE = Color3.fromRGB(255,248,225)
    local GRAY = Color3.fromRGB(190,175,145)
    local PURPLE = Color3.fromRGB(255,135,20) -- kept variable name so existing UI code stays intact
    local GREEN = Color3.fromRGB(255,155,25)
    local RED = Color3.fromRGB(210,65,35)
    local YELLOW = Color3.fromRGB(255,220,45)
    local ORANGE = Color3.fromRGB(255,125,15)
    local GOLD = Color3.fromRGB(255,185,25)
    local DEEP_ORANGE = Color3.fromRGB(255,92,8)

    local function AddAnimatedGradient(guiObject, speed)
        local gradient = Instance.new("UIGradient")
        gradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0.00, DEEP_ORANGE),
            ColorSequenceKeypoint.new(0.28, ORANGE),
            ColorSequenceKeypoint.new(0.55, GOLD),
            ColorSequenceKeypoint.new(0.78, YELLOW),
            ColorSequenceKeypoint.new(1.00, ORANGE)
        })
        gradient.Rotation = 0
        gradient.Parent = guiObject

        task.spawn(function()
            local offset = -1
            while gradient.Parent do
                offset += speed or 0.01
                if offset > 1 then offset = -1 end
                gradient.Offset = Vector2.new(offset, 0)
                task.wait(0.03)
            end
        end)

        return gradient
    end

    local function CleanText(text)
        if not text then return "" end
        text = tostring(text):gsub("<.->", "")
        text = text:gsub("^%s+", ""):gsub("%s+$", "")
        return string.upper(text)
    end

    local function IsVisible(obj)
        if obj:IsA("GuiObject") and not obj.Visible then return false end
        local p = obj.Parent
        while p and p ~= PlayerGui do
            if p:IsA("GuiObject") and not p.Visible then return false end
            if p:IsA("ScreenGui") and not p.Enabled then return false end
            p = p.Parent
        end
        return true
    end

    local old = PlayerGui:FindFirstChild("CodeSniper")
    if old then old:Destroy() end

    local Gui = Instance.new("ScreenGui")
    Gui.Name = "CodeSniper"
    Gui.IgnoreGuiInset = true
    Gui.ResetOnSpawn = false
    Gui.Parent = PlayerGui

    -- Loading screen
    local Loading = Instance.new("Frame")
    Loading.Name = "FTXLoading"
    Loading.Size = UDim2.fromScale(1,1)
    Loading.Position = UDim2.fromScale(0,0)
    Loading.BackgroundColor3 = Color3.fromRGB(4,4,4)
    Loading.BorderSizePixel = 0
    Loading.ZIndex = 1000
    Loading.Parent = Gui

    local LoadingCard = Instance.new("Frame")
    LoadingCard.Size = UDim2.new(0,330,0,150)
    LoadingCard.AnchorPoint = Vector2.new(0.5,0.5)
    LoadingCard.Position = UDim2.fromScale(0.5,0.5)
    LoadingCard.BackgroundColor3 = Color3.fromRGB(9,9,9)
    LoadingCard.BorderSizePixel = 0
    LoadingCard.ZIndex = 1001
    LoadingCard.Parent = Loading
    local loadingCorner = Instance.new("UICorner", LoadingCard)
    loadingCorner.CornerRadius = UDim.new(0,18)
    local loadingStroke = Instance.new("UIStroke", LoadingCard)
    loadingStroke.Color = ORANGE
    loadingStroke.Thickness = 1.5
    loadingStroke.Transparency = 0.15

    local LoadingTitle = Instance.new("TextLabel")
    LoadingTitle.Size = UDim2.new(1,-28,0,52)
    LoadingTitle.Position = UDim2.new(0,14,0,24)
    LoadingTitle.BackgroundTransparency = 1
    LoadingTitle.Text = "CodeSniper"
    LoadingTitle.TextColor3 = WHITE
    LoadingTitle.TextSize = 28
    LoadingTitle.Font = Enum.Font.GothamBlack
    LoadingTitle.TextWrapped = true
    LoadingTitle.ZIndex = 1002
    LoadingTitle.Parent = LoadingCard

    local LoadingBy = Instance.new("TextLabel")
    LoadingBy.Size = UDim2.new(1,-28,0,28)
    LoadingBy.Position = UDim2.new(0,14,0,76)
    LoadingBy.BackgroundTransparency = 1
    LoadingBy.Text = "made by FTX"
    LoadingBy.TextColor3 = YELLOW
    LoadingBy.TextSize = 15
    LoadingBy.Font = Enum.Font.GothamBold
    LoadingBy.TextWrapped = true
    LoadingBy.ZIndex = 1002
    LoadingBy.Parent = LoadingCard

    local LoadingBarBG = Instance.new("Frame")
    LoadingBarBG.Size = UDim2.new(1,-50,0,8)
    LoadingBarBG.Position = UDim2.new(0,25,1,-28)
    LoadingBarBG.BackgroundColor3 = Color3.fromRGB(24,24,24)
    LoadingBarBG.BorderSizePixel = 0
    LoadingBarBG.ZIndex = 1002
    LoadingBarBG.Parent = LoadingCard
    local lbgc = Instance.new("UICorner", LoadingBarBG)
    lbgc.CornerRadius = UDim.new(1,0)

    local LoadingBar = Instance.new("Frame")
    LoadingBar.Size = UDim2.new(0,0,1,0)
    LoadingBar.BackgroundColor3 = ORANGE
    LoadingBar.BorderSizePixel = 0
    LoadingBar.ZIndex = 1003
    LoadingBar.Parent = LoadingBarBG
    local lbc = Instance.new("UICorner", LoadingBar)
    lbc.CornerRadius = UDim.new(1,0)
    AddAnimatedGradient(LoadingBar, 0.025)

    local function IsScreenUI(obj)
        if not obj or not obj:IsA("GuiObject") then
            return false
        end

        -- Never capture 3D/world-space GUI text.
        if obj:FindFirstAncestorWhichIsA("BillboardGui") then
            return false
        end

        if obj:FindFirstAncestorWhichIsA("SurfaceGui") then
            return false
        end

        if obj:FindFirstAncestorWhichIsA("ViewportFrame") then
            return false
        end

        -- Never capture CodeSniper's own UI.
        if Gui and obj:IsDescendantOf(Gui) then
            return false
        end

        -- Accept normal 2D Roblox UI even if the game uses an unusual hierarchy.
        -- If it has an AbsolutePosition/AbsoluteSize and is not world-space,
        -- IsTopArea() will decide whether it is actually on-screen.
        return true
    end

    local function IsTopArea(obj)
        if not obj or not (obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox")) then
            return false
        end

        if not IsScreenUI(obj) or not IsVisible(obj) then
            return false
        end

        local cam = workspace.CurrentCamera
        if not cam then
            return false
        end

        local vp = cam.ViewportSize
        local p = obj.AbsolutePosition
        local s = obj.AbsoluteSize

        if s.X <= 0 or s.Y <= 0 then
            return false
        end

        local left = p.X
        local right = p.X + s.X
        local top = p.Y
        local bottom = p.Y + s.Y

        -- Must actually intersect the visible viewport.
        if right <= 0 or left >= vp.X or bottom <= 0 or top >= vp.Y then
            return false
        end

        local cx = p.X + s.X / 2
        local cy = p.Y + s.Y / 2

        -- Allow a larger HUD region so game popups aren't accidentally rejected.
        return cx >= 0
            and cx <= vp.X
            and cy >= 0
            and cy <= vp.Y * 0.60
    end

    -- Codes > Codes > CodeRedeem (Frame) > real TextBox
    local function FindCodeRedeemFrame()
        CodesScreen = PlayerGui:FindFirstChild("Codes")
        if not CodesScreen then return nil end
        CodesFrame = CodesScreen:FindFirstChild("Codes")
        if not CodesFrame then return nil end
        CodeRedeemFrame = CodesFrame:FindFirstChild("CodeRedeem", true)
        return CodeRedeemFrame
    end

    local function FindCodeBox()
        local frame = FindCodeRedeemFrame()
        if not frame then CodeBox = nil return nil end
        for _, obj in ipairs(frame:GetDescendants()) do
            if obj:IsA("TextBox") then
                CodeBox = obj
                return obj
            end
        end
        CodeBox = nil
        return nil
    end

    local function FindSubmit()
        FindCodeRedeemFrame()
        if not CodesFrame then
            SubmitButton = nil
            return nil
        end

        -- IMPORTANT: do NOT require Visible=true.
        -- The Codes tab may be closed while CodeSniper is working.
        for _, obj in ipairs(CodesFrame:GetDescendants()) do
            if obj:IsA("TextButton") or obj:IsA("ImageButton") then
                local t = ""
                pcall(function()
                    t = CleanText(obj.Text)
                end)

                local n = string.upper(tostring(obj.Name or ""))

                if t == "SUBMIT"
                or t == "REDEEM"
                or t:find("SUBMIT",1,true)
                or t:find("REDEEM",1,true)
                or n:find("SUBMIT",1,true)
                or n:find("REDEEM",1,true) then
                    SubmitButton = obj
                    return obj
                end
            end
        end

        -- Some games use a TextLabel inside an ImageButton/TextButton.
        for _, obj in ipairs(CodesFrame:GetDescendants()) do
            if obj:IsA("TextLabel") then
                local t = CleanText(obj.Text)

                if t == "SUBMIT"
                or t == "REDEEM"
                or t:find("SUBMIT",1,true)
                or t:find("REDEEM",1,true) then
                    local p = obj.Parent

                    while p and p ~= CodesFrame do
                        if p:IsA("TextButton") or p:IsA("ImageButton") then
                            SubmitButton = p
                            return p
                        end
                        p = p.Parent
                    end
                end
            end
        end

        SubmitButton = nil
        return nil
    end

    -- UI helpers
    local TweenService = game:GetService("TweenService")
    local RunService = game:GetService("RunService")

    local function Tween(obj, duration, props, style, direction)
        local info = TweenInfo.new(duration or 0.25, style or Enum.EasingStyle.Quint, direction or Enum.EasingDirection.Out)
        local tw = TweenService:Create(obj, info, props)
        tw:Play()
        return tw
    end

    local ActiveDraggedPanel = nil

    local function MakePanel(title, pos, fullHeight)
        local f = Instance.new("Frame")
        f.Name = title .. "Panel"
        f.Size = UDim2.new(0,235,0,fullHeight)
        f.Position = pos
        f.BackgroundColor3 = Color3.fromRGB(6,7,10)
        f.BackgroundTransparency = 0.04
        f.BorderSizePixel = 0
        f.Active = true
        f.ClipsDescendants = true
        f.Parent = Gui
        f:SetAttribute("Collapsed", false)

        local c = Instance.new("UICorner", f); c.CornerRadius = UDim.new(0,16)
        local st = Instance.new("UIStroke", f); st.Color = ORANGE; st.Transparency = 0.28; st.Thickness = 1.4

        local top = Instance.new("Frame", f)
        top.Name = "DragBar"
        top.Size = UDim2.new(1,0,0,48)
        top.BackgroundColor3 = ORANGE
        top.BorderSizePixel = 0
        top.Active = true
        top.ZIndex = 5
        local tc = Instance.new("UICorner", top); tc.CornerRadius = UDim.new(0,16)
        AddAnimatedGradient(top,0.008)

        local fade = Instance.new("Frame", f)
        fade.Size = UDim2.new(1,0,0,34)
        fade.Position = UDim2.new(0,0,0,28)
        fade.BackgroundColor3 = ORANGE
        fade.BorderSizePixel = 0
        fade.ZIndex = 4
        local fg = Instance.new("UIGradient", fade)
        fg.Rotation = 90
        fg.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0,ORANGE),
            ColorSequenceKeypoint.new(0.5,GOLD),
            ColorSequenceKeypoint.new(1,Color3.fromRGB(6,7,10))
        })
        fg.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0,0.05),
            NumberSequenceKeypoint.new(0.55,0.4),
            NumberSequenceKeypoint.new(1,1)
        })

        local body = Instance.new("Frame", f)
        body.Name = "PanelBody"
        body.Size = UDim2.new(1,0,1,-48)
        body.Position = UDim2.new(0,0,0,48)
        body.BackgroundTransparency = 1
        body.BorderSizePixel = 0
        body.ClipsDescendants = true
        body.ZIndex = 2

        local l = Instance.new("TextLabel", top)
        l.Size = UDim2.new(1,-72,1,0)
        l.Position = UDim2.new(0,14,0,0)
        l.BackgroundTransparency = 1
        l.Text = string.upper(title)
        l.TextColor3 = Color3.fromRGB(28,14,0)
        l.TextSize = 17
        l.Font = Enum.Font.GothamBlack
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.ZIndex = 6

        local collapse = Instance.new("TextButton", top)
        collapse.Size = UDim2.new(0,28,0,28)
        collapse.Position = UDim2.new(1,-34,0,10)
        collapse.BackgroundColor3 = Color3.fromRGB(255,145,0)
        collapse.BackgroundTransparency = 0
        collapse.BorderSizePixel = 0
        collapse.Text = "−"
        collapse.TextColor3 = Color3.fromRGB(40,18,0)
        collapse.TextSize = 18
        collapse.Font = Enum.Font.GothamBold
        collapse.ZIndex = 7
        local cc = Instance.new("UICorner",collapse); cc.CornerRadius = UDim.new(1,0)
        local collapseGrad = Instance.new("UIGradient", collapse)
        collapseGrad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255,225,35)),
            ColorSequenceKeypoint.new(0.55, Color3.fromRGB(255,145,0)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255,95,0))
        })

        local collapsed = false
        collapse.MouseButton1Click:Connect(function()
            collapsed = not collapsed
            f:SetAttribute("Collapsed", collapsed)
            collapse.Text = collapsed and "+" or "−"

            if collapsed then
                body.Visible = false
                fade.Visible = false
                f.BackgroundTransparency = 1
                st.Transparency = 0.18

                if f.Name == "ConfigPanel" and ConfigLightning then
                    ConfigLightning.Visible = false
                end

                Tween(f,0.26,{Size = UDim2.new(0,235,0,48)},Enum.EasingStyle.Quint)
            else
                f.BackgroundTransparency = 0.04
                st.Transparency = 0.28
                fade.Visible = true
                Tween(f,0.34,{Size = UDim2.new(0,235,0,fullHeight)},Enum.EasingStyle.Back)
                task.delay(0.08,function()
                    if not collapsed then
                        body.Visible = true
                    end
                end)
            end
        end)

        local dragging=false
        local dragStart,startPos,dragInput

        top.InputBegan:Connect(function(input)
            if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
                if ActiveDraggedPanel and ActiveDraggedPanel ~= f then
                    return
                end

                ActiveDraggedPanel = f
                dragging = true
                dragStart = input.Position
                startPos = f.Position

                input.Changed:Connect(function()
                    if input.UserInputState==Enum.UserInputState.End then
                        dragging = false
                        if ActiveDraggedPanel == f then
                            ActiveDraggedPanel = nil
                        end
                    end
                end)
            end
        end)

        top.InputChanged:Connect(function(input)
            if input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch then
                dragInput=input
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if dragging and ActiveDraggedPanel == f and input==dragInput then
                local d=input.Position-dragStart
                f.Position=UDim2.new(
                    startPos.X.Scale,startPos.X.Offset+d.X,
                    startPos.Y.Scale,startPos.Y.Offset+d.Y
                )
            end
        end)

        return f, body
    end

    local GlobalScale=Instance.new("UIScale",Gui)
    GlobalScale.Scale=1

    local function UpdateDeviceScale()
        local cam=workspace.CurrentCamera
        if not cam then return end
        local w=cam.ViewportSize.X

        if w < 800 then
            GlobalScale.Scale = 0.5
        else
            GlobalScale.Scale = 1
        end
    end
    UpdateDeviceScale()
    if workspace.CurrentCamera then
        workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(UpdateDeviceScale)
    end

    local CapturedPanel, CapturedBody = MakePanel("Logs", UDim2.new(1,-486,0.5,-190), 380)
    local SettingsPanel, SettingsBody = MakePanel("Config", UDim2.new(1,-243,0.5,-210), 420)

    local function AddAtmosphere(panel)
        local fx=Instance.new("Frame",panel)
        fx.Size=UDim2.fromScale(1,1)
        fx.BackgroundTransparency=1
        fx.ClipsDescendants=true
        fx.ZIndex=1

        for i=1,9 do
            local streak=Instance.new("Frame",fx)
            streak.Size=UDim2.new(0,math.random(35,85),0,math.random(1,3))
            streak.Position=UDim2.new(0,math.random(-100,200),0,math.random(58,340))
            streak.BackgroundColor3=(i%2==0) and Color3.fromRGB(255,160,20) or Color3.fromRGB(255,225,75)
            streak.BackgroundTransparency=math.random(76,91)/100
            streak.BorderSizePixel=0
            streak.Rotation=math.random(-7,7)
            local sc=Instance.new("UICorner",streak); sc.CornerRadius=UDim.new(1,0)

            task.spawn(function()
                while streak.Parent do
                    streak.Position=UDim2.new(0,-100,0,math.random(58,math.max(70,panel.AbsoluteSize.Y-24)))
                    streak.BackgroundTransparency=math.random(76,92)/100
                    local yy=streak.Position.Y.Offset+math.random(-10,10)
                    local tw=Tween(streak,math.random(22,42)/10,{
                        Position=UDim2.new(1,85,0,yy),
                        BackgroundTransparency=0.98
                    },Enum.EasingStyle.Linear)
                    tw.Completed:Wait()
                    task.wait(math.random(2,8)/10)
                end
            end)
        end
        return fx
    end

    local LogsFX=AddAtmosphere(CapturedPanel)
    local ConfigFX=AddAtmosphere(SettingsPanel)

    local function MakeLightning(parent)
        local holder=Instance.new("Frame",parent)
        holder.Name="ConfigLightning"
        holder.Size=UDim2.fromScale(1,1)
        holder.Position=UDim2.fromScale(0,0)
        holder.BackgroundTransparency=1
        holder.Visible=false
        holder.ClipsDescendants=true
        holder.ZIndex=1 -- behind every Config control

        local segments = {}

        for i=1,6 do
            local seg=Instance.new("Frame",holder)
            seg.AnchorPoint=Vector2.new(0.5,0)
            seg.BackgroundColor3=Color3.fromRGB(255,235,0)
            seg.BorderSizePixel=0
            seg.ZIndex=1

            local sc=Instance.new("UICorner",seg)
            sc.CornerRadius=UDim.new(1,0)

            local glow=Instance.new("UIStroke",seg)
            glow.Color=Color3.fromRGB(255,185,0)
            glow.Thickness=2.2
            glow.Transparency=0.18

            table.insert(segments,seg)
        end

        local function RandomizeBolt()
            -- Smaller bolt and randomized placement inside Config only.
            local baseX = math.random(35,75) / 100
            local startY = math.random(8,30) / 100

            local y = startY
            local x = baseX

            for i,seg in ipairs(segments) do
                local h = math.random(34,48)
                local w = math.random(3,4)
                local rot = math.random(-18,18)

                seg.Size = UDim2.new(0,w,0,h)
                seg.Position = UDim2.new(x,0,y,0)
                seg.Rotation = rot

                -- Zig-zag horizontally while descending.
                x = math.clamp(x + math.random(-9,9)/100, 0.18, 0.82)
                y = y + math.random(9,13)/100
            end
        end

        holder:SetAttribute("RandomizeBolt", true)
        return holder, RandomizeBolt
    end

    local ConfigLightning, RandomizeConfigLightning = MakeLightning(SettingsPanel)

    local function FlashConfigLightning()
        -- Do nothing if Config is collapsed/closed.
        if not SettingsPanel.Parent then return end
        if SettingsPanel:GetAttribute("Collapsed") == true or SettingsPanel.Size.Y.Offset <= 60 then
            ConfigLightning.Visible = false
            return
        end

        RandomizeConfigLightning()

        if SettingsPanel:GetAttribute("Collapsed") == true then
            ConfigLightning.Visible = false
            return
        end

        ConfigLightning.Visible = true

        -- Soft flash behind all Config controls only.
        local flash=Instance.new("Frame",SettingsPanel)
        flash.Size=UDim2.fromScale(1,1)
        flash.BackgroundColor3=Color3.fromRGB(255,238,140)
        flash.BackgroundTransparency=0.90
        flash.BorderSizePixel=0
        flash.ZIndex=2
        flash.ClipsDescendants=true

        local fc=Instance.new("UICorner",flash)
        fc.CornerRadius=UDim.new(0,16)

        task.wait(0.08)

        if SettingsPanel:GetAttribute("Collapsed") == true then
            ConfigLightning.Visible = false
            if flash and flash.Parent then flash:Destroy() end
            return
        end

        ConfigLightning.Visible=false
        Tween(flash,0.10,{BackgroundTransparency=1},Enum.EasingStyle.Quad)
        task.wait(0.10)

        if flash and flash.Parent then
            flash:Destroy()
        end
    end

    task.spawn(function()
        while Gui.Parent do
            task.wait(math.random(0,30))
            if SettingsPanel:GetAttribute("Collapsed") ~= true and SettingsPanel.Size.Y.Offset > 60 then
                task.spawn(FlashConfigLightning)
            else
                ConfigLightning.Visible = false
            end
        end
    end)


    local Status = Instance.new("TextLabel", CapturedBody)
    Status.Size = UDim2.new(1,-24,0,22); Status.Position = UDim2.new(0,12,0,8); Status.BackgroundTransparency = 1
    Status.Text = "Logs ready"; Status.TextColor3 = GRAY; Status.TextSize = 12; Status.Font = Enum.Font.Gotham; Status.TextXAlignment = Enum.TextXAlignment.Left; Status.ZIndex = 4

    local Scroll = Instance.new("ScrollingFrame", CapturedBody)
    Scroll.Position = UDim2.new(0,10,0,36); Scroll.Size = UDim2.new(1,-20,1,-46)
    Scroll.ZIndex = 4; Scroll.BackgroundColor3 = BG2; Scroll.BackgroundTransparency = 0.2; Scroll.BorderSizePixel = 0; Scroll.ScrollBarThickness = 3
    Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y; Scroll.CanvasSize = UDim2.new()
    local sc = Instance.new("UICorner", Scroll); sc.CornerRadius = UDim.new(0,10)
    local list = Instance.new("UIListLayout", Scroll); list.Padding = UDim.new(0,5)
    local pad = Instance.new("UIPadding", Scroll); pad.PaddingTop = UDim.new(0,6); pad.PaddingBottom = UDim.new(0,6); pad.PaddingLeft = UDim.new(0,6); pad.PaddingRight = UDim.new(0,6)

    local LogRows = {}
    local LastLogText = nil
    local LastLogAt = 0
    local MAX_LOG_ROWS = 45

    local function AddLog(text)
        text = tostring(text or "")
        if text == "" then return end

        -- Keep the Logs panel useful instead of filling it with internal noise.
        local lower = string.lower(text)
        if lower:find("discord image added", 1, true)
        or lower:find("brainrot image added", 1, true)
        or lower:find("fallback image added", 1, true)
        or lower:find("webhook queue", 1, true)
        or lower:find("smart write retry", 1, true) then
            return
        end

        -- Suppress rapid duplicates caused by multiple Roblox UI signals.
        local now = os.clock()
        if LastLogText == text and (now - LastLogAt) < 2.5 then
            return
        end
        LastLogText = text
        LastLogAt = now

        table.insert(AllCaptured, text)

        local l = Instance.new("TextLabel", Scroll)
        l.Size = UDim2.new(1,-2,0,32)
        l.BackgroundColor3 = BG3
        l.BackgroundTransparency = 0.15
        l.BorderSizePixel = 0
        l.Text = "•  " .. text
        l.TextColor3 = WHITE
        l.TextSize = 13
        l.Font = Enum.Font.GothamMedium
        l.ZIndex = 5
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.TextTruncate = Enum.TextTruncate.AtEnd
        l.ClipsDescendants = true

        local c = Instance.new("UICorner", l)
        c.CornerRadius = UDim.new(0,8)

        local p = Instance.new("UIPadding", l)
        p.PaddingLeft = UDim.new(0,8)

        table.insert(LogRows, l)

        -- Keep only the newest useful entries.
        while #LogRows > MAX_LOG_ROWS do
            local old = table.remove(LogRows, 1)
            if old and old.Parent then
                old:Destroy()
            end
        end

        task.defer(function()
            Scroll.CanvasPosition = Vector2.new(
                0,
                math.max(0, Scroll.AbsoluteCanvasSize.Y - Scroll.AbsoluteWindowSize.Y)
            )
        end)
    end

    local function LogState(name, enabled)
        AddLog(name .. " " .. (enabled and "enabled" or "disabled"))
    end

    local function MakeSwitch(name, y)
        local l = Instance.new("TextLabel", SettingsBody)
        l.Size = UDim2.new(0,110,0,32); l.Position = UDim2.new(0,14,0,y); l.BackgroundTransparency = 1
        l.Text = name; l.TextColor3 = WHITE; l.TextSize = 14; l.Font = Enum.Font.GothamMedium; l.TextXAlignment = Enum.TextXAlignment.Left
        local b = Instance.new("TextButton", SettingsBody)
        b.Size = UDim2.new(0,78,0,32); b.Position = UDim2.new(1,-92,0,y); b.BorderSizePixel = 0; b.AutoButtonColor = false
        b.TextColor3 = WHITE; b.TextSize = 12; b.Font = Enum.Font.GothamBold
        local c = Instance.new("UICorner", b); c.CornerRadius = UDim.new(1,0)
        return b, l
    end

    local CopierToggle, CopierLabel = MakeSwitch("Copier", 12)
    local PrepareToggle = MakeSwitch("Prepare", 52)
    local AfterSubmitToggle, AfterSubmitLabel = MakeSwitch("After Submit", 92)
local SmartRedeemerToggle, SmartRedeemerLabel

    local function PaintToggle(button, enabled)
        button.Text = enabled and "ON" or "OFF"
        button.BackgroundColor3 = enabled and GREEN or RED
    end

    PaintToggle(CopierToggle, CopierEnabled)
    PaintToggle(PrepareToggle, PrepareEnabled)
    PaintToggle(AfterSubmitToggle, AfterSubmitEnabled)



    CopierToggle.MouseButton1Click:Connect(function()
        CopierEnabled = not CopierEnabled
        PaintToggle(CopierToggle, CopierEnabled)
        SavePreferences()
        LogState("Copier", CopierEnabled)

        if not CopierEnabled then
            CurrentMessages = {}
            WaitingForCode = false
            Status.Text = "Copier disabled"
            Status.TextColor3 = RED
        else
            Status.Text = PrepareEnabled and "Waiting for code..." or "Ready to capture..."
            Status.TextColor3 = GRAY
        end
    end)



    PrepareToggle.MouseButton1Click:Connect(function()
        PrepareEnabled = not PrepareEnabled
        PaintToggle(PrepareToggle, PrepareEnabled)
        SavePreferences()
        LogState("Prepare", PrepareEnabled)
        CurrentMessages = {}; WaitingForCode = false
        if CopierEnabled then Status.Text = PrepareEnabled and "Waiting for code..." or "Ready to capture..."; Status.TextColor3 = GRAY end
    end)

    AfterSubmitToggle.MouseButton1Click:Connect(function()
        AfterSubmitEnabled = not AfterSubmitEnabled

        if AfterSubmitEnabled and SmartRedeemerEnabled then
            SmartRedeemerEnabled = false
            if SmartRedeemerToggle then
                PaintToggle(SmartRedeemerToggle, false)
            end
            SmartAwaitingResult = false
            SmartNeedsNextMessage = false
            SmartRetrying = false
            SmartAttemptId += 1
            CurrentMessages = {}
            WaitingForCode = false
        end

        PaintToggle(AfterSubmitToggle, AfterSubmitEnabled)
        SavePreferences()
        LogState("After Submit", AfterSubmitEnabled)
    end)

    -- Slider 1-5
    local SliderTitle = Instance.new("TextLabel", SettingsBody)
    SliderTitle.ZIndex = 5
    SliderTitle.Size = UDim2.new(1,-28,0,24); SliderTitle.Position = UDim2.new(0,14,0,132); SliderTitle.BackgroundTransparency = 1
    SliderTitle.Text = "Submit after messages"; SliderTitle.TextColor3 = WHITE; SliderTitle.TextSize = 13; SliderTitle.Font = Enum.Font.GothamBold; SliderTitle.TextXAlignment = Enum.TextXAlignment.Left

    local Number = Instance.new("TextLabel", SettingsBody)
    Number.ZIndex = 5
    Number.Size = UDim2.new(0,40,0,28); Number.Position = UDim2.new(1,-54,0,129); Number.BackgroundColor3 = BG3; Number.BorderSizePixel = 0
    Number.Text = tostring(SubmitAfter); Number.TextColor3 = WHITE; Number.TextSize = 14; Number.Font = Enum.Font.GothamBold
    local nc = Instance.new("UICorner", Number); nc.CornerRadius = UDim.new(0,8)

    local Slider = Instance.new("Frame", SettingsBody)
    Slider.ZIndex = 5
    Slider.Size = UDim2.new(1,-36,0,8); Slider.Position = UDim2.new(0,18,0,169); Slider.BackgroundColor3 = BG3; Slider.BorderSizePixel = 0
    local slc = Instance.new("UICorner", Slider); slc.CornerRadius = UDim.new(1,0)
    local Fill = Instance.new("Frame", Slider)
    Fill.ZIndex = 6
    Fill.Size = UDim2.new((SubmitAfter-1)/4,0,1,0); Fill.BackgroundColor3 = PURPLE; Fill.BorderSizePixel = 0
    local fc = Instance.new("UICorner", Fill); fc.CornerRadius = UDim.new(1,0)
    AddAnimatedGradient(Fill, 0.012)
    local Knob = Instance.new("TextButton", Slider)
    Knob.ZIndex = 8
    Knob.Size = UDim2.new(0,22,0,22); Knob.AnchorPoint = Vector2.new(0.5,0.5); Knob.Position = UDim2.new((SubmitAfter-1)/4,0,0.5,0)
    Knob.BackgroundColor3 = WHITE; Knob.BorderSizePixel = 0; Knob.Text = ""
    local kc = Instance.new("UICorner", Knob); kc.CornerRadius = UDim.new(1,0)

    for i=1,5 do
        local n = Instance.new("TextLabel", SettingsBody)
        n.Size = UDim2.new(0,24,0,20); n.AnchorPoint = Vector2.new(0.5,0); n.Position = UDim2.new((i-1)/4,0,0,180)
        n.ZIndex = 5; n.BackgroundTransparency = 1; n.Text = tostring(i); n.TextColor3 = GRAY; n.TextSize = 11; n.Font = Enum.Font.GothamMedium
    end

    -- Smart Redeemer sits directly below the Submit After slider.
    SmartRedeemerToggle, SmartRedeemerLabel = MakeSwitch("Smart Redeemer", 207)

    PaintToggle(SmartRedeemerToggle, SmartRedeemerEnabled)

    local function UpdateSliderLock()
        local locked = SmartRedeemerEnabled == true
        Slider.Active = not locked
        Knob.Active = not locked
        Knob.AutoButtonColor = not locked
        SliderTitle.TextColor3 = locked and GRAY or WHITE
        Number.TextColor3 = locked and GRAY or WHITE
        Knob.BackgroundColor3 = locked and GRAY or WHITE
        Slider.BackgroundTransparency = locked and 0.35 or 0
    end

    UpdateSliderLock()

    SmartRedeemerToggle.MouseButton1Click:Connect(function()
        SmartRedeemerEnabled = not SmartRedeemerEnabled

        if SmartRedeemerEnabled then
            -- Smart Redeemer owns submission while enabled.
            AfterSubmitEnabled = false
            PaintToggle(AfterSubmitToggle, false)
        end

        PaintToggle(SmartRedeemerToggle, SmartRedeemerEnabled)
        UpdateSliderLock()

        SmartAwaitingResult = false
        SmartNeedsNextMessage = false
        SmartRetrying = false
        SmartAttemptId += 1
        CurrentMessages = {}
        WaitingForCode = false

        if SmartRedeemerEnabled then
            Status.Text = PrepareEnabled and "Smart ON - waiting for prepare..." or "Smart ON - waiting for message 1/5..."
            Status.TextColor3 = YELLOW
        else
            Status.Text = PrepareEnabled and "Waiting for code..." or "Ready to capture..."
            Status.TextColor3 = GRAY
        end

        SavePreferences()
        LogState("Smart Redeemer", SmartRedeemerEnabled)
    end)

    local dragging = false

    local function SetSlider(x)
        if SmartRedeemerEnabled then
            dragging = false
            return
        end

        local pct = math.clamp((x-Slider.AbsolutePosition.X)/Slider.AbsoluteSize.X,0,1)
        local value = math.clamp(math.floor(pct*4+1.5),1,5)
        SubmitAfter = value

        AfterSubmitEnabled = true
        PaintToggle(AfterSubmitToggle, true)

        local snap = (value-1)/4
        Fill.Size = UDim2.new(snap,0,1,0)
        Knob.Position = UDim2.new(snap,0,0.5,0)
        Number.Text = tostring(value)

        SavePreferences()
        AddLog("Submit After set to " .. tostring(value))
    end

    Slider.InputBegan:Connect(function(i)
        if SmartRedeemerEnabled then return end
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            dragging=true
            SetSlider(i.Position.X)
        end
    end)

    Knob.MouseButton1Down:Connect(function()
        if SmartRedeemerEnabled then return end
        dragging=true
    end)

    UserInputService.InputChanged:Connect(function(i)
        if SmartRedeemerEnabled then
            dragging=false
            return
        end
        if dragging and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
            SetSlider(i.Position.X)
        end
    end)

    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            dragging=false
        end
    end)

    -- Detection status
    local DetectStatus = Instance.new("TextLabel", SettingsBody)
    DetectStatus.ZIndex = 5
    DetectStatus.AnchorPoint = Vector2.new(0,0)
    DetectStatus.Size = UDim2.new(1,-28,0,44)
    DetectStatus.Position = UDim2.new(0,14,0,249); DetectStatus.BackgroundColor3 = BG2; DetectStatus.BackgroundTransparency = 0.15; DetectStatus.BorderSizePixel = 0
    DetectStatus.TextColor3 = YELLOW; DetectStatus.TextSize = 11; DetectStatus.Font = Enum.Font.Code; DetectStatus.TextXAlignment = Enum.TextXAlignment.Left; DetectStatus.TextYAlignment = Enum.TextYAlignment.Top; DetectStatus.TextWrapped = true; DetectStatus.ClipsDescendants = true
    local dc = Instance.new("UICorner", DetectStatus); dc.CornerRadius = UDim.new(0,9)
    local dp = Instance.new("UIPadding", DetectStatus); dp.PaddingLeft = UDim.new(0,8); dp.PaddingTop = UDim.new(0,7)

    -- Reset all captured code data
    local ResetButton = Instance.new("TextButton", SettingsBody)
    ResetButton.ZIndex = 5
    ResetButton.Name = "ResetData"
    ResetButton.Size = UDim2.new(1,-28,0,34)
    ResetButton.AnchorPoint = Vector2.new(0,0)
    ResetButton.Position = UDim2.new(0,14,0,301)
    ResetButton.BackgroundColor3 = ORANGE
    ResetButton.BorderSizePixel = 0
    ResetButton.Text = "RESET LOGS"
    ResetButton.TextColor3 = Color3.fromRGB(20,12,0)
    ResetButton.TextSize = 12
    ResetButton.Font = Enum.Font.GothamBold
    ResetButton.AutoButtonColor = true
    local resetCorner = Instance.new("UICorner", ResetButton)
    resetCorner.CornerRadius = UDim.new(0,9)
    AddAnimatedGradient(ResetButton, 0.012)

    ResetButton.MouseButton1Click:Connect(function()
        -- Fresh capture session. Keep all user settings/toggles exactly as they are.
        CurrentMessages = {}
        WaitingForCode = false
        Submitting = false
        SmartAwaitingResult = false
        SmartNeedsNextMessage = false
        SmartRetrying = false
        SmartAttemptId += 1

        -- Start fresh WITHOUT immediately re-capturing old messages that are
        -- still visible on screen at the moment Reset is pressed.
        LastText = {}
        SpawnSeenText = {}
        SpawnSeenVisible = {}

        for _, obj in ipairs(PlayerGui:GetDescendants()) do
            if obj:IsA("TextLabel") and IsScreenUI(obj) then
                LastText[obj] = CleanText(obj.Text)
            end
        end

        AllCaptured = {}
        LogRows = {}
        LastLogText = nil
        LastLogAt = 0
        for _, child in ipairs(Scroll:GetChildren()) do
            if child:IsA("TextLabel") then
                child:Destroy()
            end
        end

        local box = FindCodeBox()
        if box then
            pcall(function()
                box.Text = ""
                box.CursorPosition = 1
                box.SelectionStart = -1
            end)
        end

        if SmartRedeemerEnabled then
            Status.Text = PrepareEnabled
                and "Smart reset - waiting for trigger..."
                or "Smart reset - waiting for message 1/5..."
            Status.TextColor3 = YELLOW
        else
            Status.Text = PrepareEnabled and "Waiting for code..." or "Ready to capture..."
            Status.TextColor3 = GRAY
        end
    end)

    -- Steal a Brainrot logo.
    -- Mobile-safe loading: try executor custom asset APIs first, then Roblox asset fallback.
    local BRAINROT_IMAGE_URL = "https://raw.githubusercontent.com/SigMaUgI/codesniper/refs/heads/main/steal_a_brainrot.png"
    local BRAINROT_LOCAL_FILE = "steal_a_brainrot.png"

    -- IMPORTANT:
    -- For the most reliable mobile support, upload steal_a_brainrot.png to Roblox
    -- and replace 0 below with the Roblox image/decal asset ID.
    local BRAINROT_ROBLOX_ASSET_ID = 0

    local function LoadBrainrotImage()
        local customAsset = getcustomasset or getsynasset
        local image = ""

        if customAsset then
            -- Existing local copy first.
            pcall(function()
                if isfile and isfile(BRAINROT_LOCAL_FILE) then
                    image = customAsset(BRAINROT_LOCAL_FILE)
                end
            end)

            -- Download from GitHub if the local file is missing.
            if image == "" then
                pcall(function()
                    if writefile then
                        local raw = game:HttpGet(BRAINROT_IMAGE_URL)
                        if raw and #raw > 100 then
                            writefile(BRAINROT_LOCAL_FILE, raw)
                            image = customAsset(BRAINROT_LOCAL_FILE)
                        end
                    end
                end)
            end
        end

        -- Roblox-hosted fallback works much more consistently on mobile.
        if image == "" and BRAINROT_ROBLOX_ASSET_ID ~= 0 then
            image = "rbxassetid://" .. tostring(BRAINROT_ROBLOX_ASSET_ID)
        end

        return image
    end

    local BRAINROT_IMAGE = LoadBrainrotImage()

    local BrainrotLogo = Instance.new("ImageLabel", Gui)
    BrainrotLogo.Name = "BrainrotLogo"
    BrainrotLogo.Size = UDim2.new(0,178,0,100)
    BrainrotLogo.AnchorPoint = Vector2.new(0.5,0.5)
    BrainrotLogo.BackgroundTransparency = 1
    BrainrotLogo.Image = BRAINROT_IMAGE
    BrainrotLogo.ScaleType = Enum.ScaleType.Fit
    BrainrotLogo.ZIndex = 40

    local logoPulse = 0
    RunService.RenderStepped:Connect(function(dt)
        if not SettingsPanel.Parent then return end

        local collapsed = SettingsPanel:GetAttribute("Collapsed") == true
        if collapsed or SettingsPanel.Size.Y.Offset <= 60 or BRAINROT_IMAGE == "" then
            BrainrotLogo.Visible = false
            return
        end

        BrainrotLogo.Visible = true
        logoPulse += dt * 2.2

        local pulse = (math.sin(logoPulse) + 1) * 0.5
        local grow = math.floor(pulse * 8)
        local rise = math.floor(pulse * 5)

        local panelPos = SettingsPanel.Position
        local panelHeight = SettingsPanel.Size.Y.Offset

        -- BrainrotLogo is a Gui sibling of Config, so it can hang outside the panel
        -- without being clipped. GlobalScale automatically makes it 50% size on phone.
        BrainrotLogo.Size = UDim2.new(0,178 + grow,0,100 + math.floor(grow * 0.56))
        BrainrotLogo.Position = UDim2.new(
            panelPos.X.Scale,
            panelPos.X.Offset + 117,
            panelPos.Y.Scale,
            panelPos.Y.Offset + panelHeight - rise
        )
    end)

    local function UpdateDetected()
        FindCodeBox()
        FindSubmit()

        if CodeRedeemFrame and CodeBox and SubmitButton then
            DetectStatus.Text = "READY TO GO\nOpen the Codes menu to start CodeSniper."
            DetectStatus.TextColor3 = GREEN
        else
            local missing = {}
            if not CodeRedeemFrame then table.insert(missing, "CodeRedeem") end
            if not CodeBox then table.insert(missing, "TextBox") end
            if not SubmitButton then table.insert(missing, "Redeem button") end
            DetectStatus.Text = "WAITING FOR: " .. table.concat(missing, ", ")
            DetectStatus.TextColor3 = YELLOW
        end
    end

    -- Prepare phrases
    local TriggerPhrases = {
        "THE CODE IS",
        "THE CODE'S",
        "THE CODE:",
        "CODE IS",
        "CODE'S",
        "CODE =",
        "CODE:",
        "USE CODE",
        "USE THE CODE",
        "USE THIS CODE",
        "USE THIS",
        "USE:",
        "HERE'S THE CODE",
        "HERES THE CODE",
        "HERE IS THE CODE",
        "YOUR CODE IS",
        "YOUR CODE:",
        "OK HERE'S THE CODE",
        "OK HERES THE CODE",
        "OKAY HERE'S THE CODE",
        "OKAY HERES THE CODE",
        "OK, HERE'S THE CODE",
        "OK, HERES THE CODE",
        "THE REDEEM CODE IS",
        "REDEEM CODE",
        "REDEEM THIS CODE",
        "REDEEM WITH",
        "ENTER CODE",
        "ENTER THE CODE",
        "ENTER THIS CODE",
        "TYPE CODE",
        "TYPE THE CODE",
        "TYPE THIS CODE",
        "TRY THIS CODE",
        "PUT IN CODE",
        "PUT THE CODE IN",
        "PUT THIS CODE IN",
        "CLAIM WITH CODE",
        "CLAIM THIS CODE"
    }

    local function FindTrigger(text)
        for _, phrase in ipairs(TriggerPhrases) do
            local a,b = text:find(phrase,1,true)
            if a then return phrase,a,b end
        end
        return nil
    end

    local function IsBadText(text)
        local blocked = { [""]=true,["SUBMIT"]=true,["REDEEM"]=true,["CODES"]=true,["CODE HERE..."]=true,["CODE HERE…"]=true,["CAPTURED"]=true,["SETTINGS"]=true }
        return blocked[text] == true
    end

    local function GetRequestFunction()
        local candidates = {
            request,
            http_request,
            httprequest,
            syn and syn.request,
            http and http.request,
            fluxus and fluxus.request
        }

        for _, fn in ipairs(candidates) do
            if type(fn) == "function" then
                return fn
            end
        end

        return nil
    end

    local DownloadImageBytes

    local function GetSpawnImageUrl(spawnName)
        local requester = GetRequestFunction()
        if not requester or not spawnName or spawnName == "" then
            return nil
        end

        local query = tostring(spawnName) .. " Steal a Brainrot"
        local googleUrl =
            "https://www.google.com/search?tbm=isch&safe=active&q=" ..
            HttpService:UrlEncode(query)

        local ok, response = pcall(function()
            return requester({
                Url = googleUrl,
                Method = "GET",
                Headers = {
                    ["User-Agent"] = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/128 Safari/537.36",
                    ["Accept"] = "text/html,application/xhtml+xml"
                }
            })
        end)

        if not ok or not response then
            return nil
        end

        local status = tonumber(response.StatusCode or response.Status or response.status_code or 0)
        if status ~= 0 and (status < 200 or status >= 300) then
            return nil
        end

        local html = response.Body or response.body
        if type(html) ~= "string" or html == "" then
            return nil
        end

        html = html
            :gsub("\\u003d", "=")
            :gsub("\\u0026", "&")
            :gsub("\\u002f", "/")
            :gsub("\\/", "/")
            :gsub("&amp;", "&")

        -- Prefer Google's own image thumbnails because they are directly
        -- fetchable and already correspond to the image-search results.
        local firstThumb = html:match("(https://encrypted%-tbn[^\"'%s<>]+)")
        if firstThumb then
            firstThumb = firstThumb
                :gsub("\\u0026", "&")
                :gsub("\\/", "/")
                :gsub("&amp;", "&")

            return firstThumb
        end

        -- Fallback: first ordinary image URL in the Google result HTML.
        for raw in html:gmatch("(https?://[^\"'%s<>]+)") do
            local lower = string.lower(raw)

            if lower:find(".png", 1, true)
            or lower:find(".jpg", 1, true)
            or lower:find(".jpeg", 1, true)
            or lower:find(".webp", 1, true) then

                if not lower:find("google.com/logos", 1, true)
                and not lower:find("/favicon", 1, true)
                and not lower:find("/avatar", 1, true)
                and not lower:find("sprite", 1, true) then
                    return raw
                end
            end
        end

        return nil
    end


    local function MakeWebhookPayload(spawnName, playerName, count, imageUrl, redeemedAt, attachmentId)
        local embed = {
            color = 16753920,
            fields = {
                {
                    name = "Spawn",
                    value = "**" .. tostring(spawnName) .. "**",
                    inline = true
                },
                {
                    name = "User",
                    value = "**" .. tostring(playerName) .. "**",
                    inline = true
                },
                {
                    name = "Redeemed At",
                    value = "<t:" .. tostring(redeemedAt or os.time()) .. ":T>",
                    inline = true
                }
            },
            footer = {
                text = "FTX Sniper"
            }
        }

        if imageUrl and imageUrl ~= "" then
            embed.image = {url = imageUrl}
        end

        local payload = {
            username = WEBHOOK_USERNAME,
            avatar_url = CODE_SNIPER_AVATAR,

            -- Exact top message format:
            -- @everyone
            -- # Brainrot Name
            content = "@everyone\n# " .. tostring(spawnName),

            allowed_mentions = {parse = {"everyone"}},
            embeds = {embed}
        }

        if attachmentId then
            payload.attachments = {
                {
                    id = tostring(attachmentId),
                    filename = "brainrot.png"
                }
            }
        end

        return payload
    end


    local SpawnWebhookMessages = {}
    local SpawnImageCache = {}
    local WebhookQueue = {}
    local WebhookQueueRunning = false

    local function WebhookKey(spawnName, playerName)
        return string.lower(tostring(spawnName)) .. "\31" .. string.lower(tostring(playerName))
    end

    local function CachedSpawnImage(spawnName)
        local key = string.lower(tostring(spawnName))

        if type(SpawnImageCache[key]) == "string" and SpawnImageCache[key] ~= "" then
            return SpawnImageCache[key]
        end

        local image = GetSpawnImageUrl(spawnName)

        -- Cache successes only. A temporary Google/Wiki failure should not
        -- permanently force IMAGE NOT FOUND for the rest of the session.
        if image then
            SpawnImageCache[key] = image
        end

        return image
    end

    local function DoWebhookRequest(requester, options)
        local ok, response = pcall(function()
            return requester(options)
        end)

        if not ok or not response then
            return false, nil, "REQUEST_FAILED"
        end

        local status = tonumber(response.StatusCode or response.Status or response.status_code or 0)
        if status ~= 0 and (status < 200 or status >= 300) then
            return false, response, "HTTP_" .. tostring(status)
        end

        return true, response, nil
    end

    DownloadImageBytes = function(url)
        local requester = GetRequestFunction()
        if not requester or not url or url == "" then
            return nil
        end

        local ok, response = pcall(function()
            return requester({
                Url = url,
                Method = "GET",
                Headers = {
                    ["User-Agent"] = "Mozilla/5.0",
                    ["Accept"] = "image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8",
                    ["Referer"] = "https://www.google.com/"
                }
            })
        end)

        if not ok or not response then
            return nil
        end

        local status = tonumber(response.StatusCode or response.Status or response.status_code or 0)
        if status ~= 0 and (status < 200 or status >= 300) then
            return nil
        end

        local body = response.Body or response.body
        if type(body) ~= "string" or #body < 200 then
            return nil
        end

        -- Basic signature check so HTML/error pages don't get uploaded as pictures.
        local isPng = body:sub(1, 8) == "\137PNG\r\n\26\n"
        local isJpg = body:sub(1, 2) == "\255\216"
        local isWebp = body:sub(1, 4) == "RIFF" and body:sub(9, 12) == "WEBP"
        local isGif = body:sub(1, 6) == "GIF87a" or body:sub(1, 6) == "GIF89a"

        if not (isPng or isJpg or isWebp or isGif) then
            return nil
        end

        local ext = "png"
        local mime = "image/png"
        if isJpg then ext, mime = "jpg", "image/jpeg"
        elseif isWebp then ext, mime = "webp", "image/webp"
        elseif isGif then ext, mime = "gif", "image/gif"
        end

        return body, ext, mime
    end

    local function GetBestSpawnImageBytes(spawnName)
        local imageUrl = CachedSpawnImage(spawnName)
        if imageUrl then
            local bytes, ext, mime = DownloadImageBytes(imageUrl)
            if bytes then
                return bytes, ext, mime, false
            end
        end

        -- Guaranteed fallback: exact IMAGE NOT FOUND picture embedded in V44.
        return IMAGE_NOT_FOUND_BYTES, "png", "image/png", true
    end

    local function BuildMultipartBody(payloadTable, imageBytes, filename, mime)
        local boundary = "----FTXSniper" .. tostring(math.floor(os.clock() * 1000000))
        local crlf = "\r\n"

        local payloadJson = HttpService:JSONEncode(payloadTable)

        local body =
            "--" .. boundary .. crlf ..
            'Content-Disposition: form-data; name="payload_json"' .. crlf ..
            "Content-Type: application/json" .. crlf .. crlf ..
            payloadJson .. crlf ..
            "--" .. boundary .. crlf ..
            'Content-Disposition: form-data; name="files[0]"; filename="' .. tostring(filename) .. '"' .. crlf ..
            "Content-Type: " .. tostring(mime) .. crlf .. crlf ..
            imageBytes .. crlf ..
            "--" .. boundary .. "--" .. crlf

        return body, "multipart/form-data; boundary=" .. boundary
    end

    local function PostWebhookWithImage(requester, payload, imageBytes, filename, mime)
        local body, contentType = BuildMultipartBody(payload, imageBytes, filename, mime)

        return DoWebhookRequest(requester, {
            Url = DISCORD_WEBHOOK .. "?wait=true",
            Method = "POST",
            Headers = {
                ["Content-Type"] = contentType
            },
            Body = body
        })
    end

    local function ProcessSpawnWebhook(spawnName, playerName)
        local requester = GetRequestFunction()
        if not requester then
            AddLog("Discord unavailable")
            return
        end

        spawnName = tostring(spawnName or ""):gsub("^%s+",""):gsub("%s+$","")
        playerName = tostring(playerName or Player.Name or "Unknown"):gsub("^%s+",""):gsub("%s+$","")

        if spawnName == "" then
            return
        end

        if playerName == "" then
            playerName = "Unknown"
        end

        local key = WebhookKey(spawnName, playerName)
        local state = SpawnWebhookMessages[key]

        if not state then
            state = {
                count = 0,
                message_id = nil,
                redeemed_at = os.time()
            }

            SpawnWebhookMessages[key] = state
        end

        state.count += 1
        state.redeemed_at = os.time()

        ------------------------------------------------------------
        -- EXISTING MESSAGE: update text immediately.
        ------------------------------------------------------------
        if state.message_id then
            local updatePayload = MakeWebhookPayload(
                spawnName,
                playerName,
                state.count,
                state.image_url,
                state.redeemed_at,
                nil
            )

            local updateOk = DoWebhookRequest(requester, {
                Url = DISCORD_WEBHOOK .. "/messages/" .. tostring(state.message_id),
                Method = "PATCH",
                Headers = {
                    ["Content-Type"] = "application/json"
                },
                Body = HttpService:JSONEncode(updatePayload)
            })

            if updateOk then
                AddLog("Updated: " .. spawnName)
                return
            end

            state.message_id = nil
        end

        ------------------------------------------------------------
        -- SEND TEXT FIRST. IMAGE SEARCH CANNOT BLOCK THIS.
        ------------------------------------------------------------
        local initialPayload = MakeWebhookPayload(
            spawnName,
            playerName,
            state.count,
            nil,
            state.redeemed_at,
            nil
        )

        local sendOk, sendResponse, sendErr = DoWebhookRequest(requester, {
            Url = DISCORD_WEBHOOK .. "?wait=true",
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = HttpService:JSONEncode(initialPayload)
        })

        if not sendOk then
            AddLog("Discord failed: " .. tostring(sendErr))
            state.count = math.max(0, state.count - 1)
            return
        end

        local sendBody = sendResponse and (sendResponse.Body or sendResponse.body) or ""

        if type(sendBody) == "string" and sendBody ~= "" then
            pcall(function()
                local decoded = HttpService:JSONDecode(sendBody)

                if decoded and decoded.id then
                    state.message_id = tostring(decoded.id)
                end
            end)
        end

        AddLog("Sent: " .. spawnName)

        ------------------------------------------------------------
        -- IMAGE: DIRECT URL + JSON PATCH ONLY.
        -- NO multipart, NO binary upload.
        ------------------------------------------------------------
        if not state.message_id then
            return
        end

        task.spawn(function()
            local imageUrl = nil

            local ok = pcall(function()
                imageUrl = GetSpawnImageUrl(spawnName)
            end)

            if not ok or not imageUrl or imageUrl == "" then
                -- Public fallback path. Put the exact IMAGE NOT FOUND PNG
                -- in the repo as image_not_found.png.
                imageUrl =
                    "https://raw.githubusercontent.com/SigMaUgI/codesniper/refs/heads/main/image_not_found.png"
            end

            state.image_url = imageUrl

            local imagePayload = MakeWebhookPayload(
                spawnName,
                playerName,
                state.count,
                imageUrl,
                state.redeemed_at,
                nil
            )

            local patchOk = DoWebhookRequest(requester, {
                Url = DISCORD_WEBHOOK .. "/messages/" .. tostring(state.message_id),
                Method = "PATCH",
                Headers = {
                    ["Content-Type"] = "application/json"
                },
                Body = HttpService:JSONEncode(imagePayload)
            })

            if not patchOk then
                AddLog("Image URL update failed")
            end
        end)
    end

    local function RunWebhookQueue()
        if WebhookQueueRunning then return end
        WebhookQueueRunning = true

        task.spawn(function()
            while true do
                local job = table.remove(WebhookQueue, 1)

                if not job then
                    WebhookQueueRunning = false

                    -- Cover the tiny race where a job arrived as we were stopping.
                    if #WebhookQueue > 0 then
                        RunWebhookQueue()
                    end
                    return
                end

                ProcessSpawnWebhook(job.spawnName, job.playerName)
                task.wait(0.20)
            end
        end)
    end

    local function SendOrUpdateSpawnWebhook(spawnName, playerName)
        table.insert(WebhookQueue, {
            spawnName = spawnName,
            playerName = playerName
        })
        RunWebhookQueue()
    end


    local function ExtractSpawnName(rawText)
        local t = tostring(rawText or ""):gsub("^%s+",""):gsub("%s+$","")

        local name =
            t:match("^%((.-)%)%s+[Ss][Pp][Aa][Ww][Nn][Ee][Dd]")
            or t:match("^(.-)%s+[Hh][Aa][Ss]%s+[Ss][Pp][Aa][Ww][Nn][Ee][Dd]")
            or t:match("^(.-)%s+[Ss][Pp][Aa][Ww][Nn][Ee][Dd]")

        if not name then return nil end

        name = tostring(name)
            :gsub("^%s+","")
            :gsub("%s+$","")
            :gsub("^%c","")
            :gsub("%c$","")

        -- Strip wrapping single/double quotes without fragile Lua patterns.
        local firstChar = string.sub(name, 1, 1)
        if firstChar == "\"" or firstChar == "'" then
            name = string.sub(name, 2)
        end

        local lastChar = string.sub(name, -1)
        if lastChar == "\"" or lastChar == "'" then
            name = string.sub(name, 1, -2)
        end


        return name ~= "" and name or nil
    end

    local function IsBottomGreenSpawnText(obj)
        if not obj:IsA("TextLabel") or not IsScreenUI(obj) or not IsVisible(obj) then
            return false
        end

        local cam = workspace.CurrentCamera
        if not cam then return false end

        local pos, size = obj.AbsolutePosition, obj.AbsoluteSize
        local centerY = pos.Y + size.Y / 2
        if centerY < cam.ViewportSize.Y * 0.55 then
            return false
        end

        local c = obj.TextColor3
        if not c then return false end

        return c.G > c.R + 0.08 and c.G > c.B + 0.05 and c.G >= 0.45
    end

    local SpawnSeenText = {}
    local SpawnSeenVisible = {}

    local function HandleSpawnResult(obj)
        if not (obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox")) then return end

        if not IsVisible(obj) then
            SpawnSeenVisible[obj] = false
            return
        end

        if not IsBottomGreenSpawnText(obj) then
            return
        end

        local raw = tostring(obj.Text or "")
        local spawnName = ExtractSpawnName(raw)
        if not spawnName then
            return
        end

        local normalized = string.lower(raw)

        -- Process once for this visible popup/text. It becomes eligible again
        -- after Visible=false or after its Text changes to something else.
        if SpawnSeenVisible[obj] and SpawnSeenText[obj] == normalized then
            return
        end

        SpawnSeenVisible[obj] = true
        SpawnSeenText[obj] = normalized

        local recipientName = Player.Name
        AddLog("Spawn: " .. spawnName .. " • " .. recipientName)
        SendOrUpdateSpawnWebhook(spawnName, recipientName)
    end


    -- Type into real TextBox inside CodeRedeem
    local function TypeIntoCodeBox()
        local box = FindCodeBox()

        if not box then
            Status.Text = "No TextBox inside CodeRedeem"
            Status.TextColor3 = RED
            return false
        end

        local finalText = table.concat(CurrentMessages, "")
        if finalText == "" then
            return false
        end

        -- IMPORTANT: never use keyboard simulation here.
        -- Directly changing the Roblox TextBox works even when Roblox is
        -- minimized, unfocused, or another Windows app is in front.
        local function DirectWrite()
            local ok = pcall(function()
                box.Text = finalText
                box.CursorPosition = #finalText + 1
                box.SelectionStart = -1
            end)
            return ok and tostring(box.Text) == finalText
        end

        local wrote = DirectWrite()

        -- Notify game-side listeners without requiring OS/Roblox focus.
        if firesignal then
            pcall(function()
                firesignal(box:GetPropertyChangedSignal("Text"))
            end)
            pcall(function()
                firesignal(box.FocusLost, false)
            end)
        end

        if getconnections then
            pcall(function()
                for _, connection in ipairs(getconnections(box:GetPropertyChangedSignal("Text"))) do
                    connection:Fire()
                end
            end)
            pcall(function()
                for _, connection in ipairs(getconnections(box.FocusLost)) do
                    connection:Fire(false)
                end
            end)
        end

        -- Keep enforcing the value briefly because some game UIs overwrite
        -- their textbox during tab/menu refreshes.
        for _ = 1, 5 do
            DirectWrite()
            task.wait(0.03)
        end

        return tostring(box.Text) == finalText
    end

    local function ClickSubmit()
        local button = FindSubmit()

        if not button then
            Status.Text = "Submit not found"
            Status.TextColor3 = RED
            return false
        end

        local fired = false

        -- These paths do not require Roblox to be the foreground window.
        if getconnections then
            pcall(function()
                for _, connection in ipairs(getconnections(button.Activated)) do
                    connection:Fire()
                    fired = true
                end
            end)

            pcall(function()
                if button:IsA("TextButton") then
                    for _, connection in ipairs(getconnections(button.MouseButton1Click)) do
                        connection:Fire()
                        fired = true
                    end
                end
            end)
        end

        if firesignal then
            pcall(function()
                firesignal(button.Activated)
                fired = true
            end)

            pcall(function()
                if button:IsA("TextButton") then
                    firesignal(button.MouseButton1Click)
                    fired = true
                end
            end)
        end

        pcall(function()
            button:Activate()
            fired = true
        end)

        -- Do NOT depend on VirtualInputManager/mouse coordinates here:
        -- Windows can send those to another application while Roblox is unfocused.
        return fired
    end

    local function SpamSubmit()
        -- Fire immediately; tiny task yields only let Roblox process callbacks.
        for _=1,10 do
            ClickSubmit()
            task.wait()
        end
    end

    local RiddleTriggerPhrases = {
        "OKAY ITS A RIDDLE",
        "OKAY IT'S A RIDDLE",
        "OK ITS A RIDDLE",
        "OK IT'S A RIDDLE",
        "HERE IS A RIDDLE",
        "HERE'S A RIDDLE",
        "RIDDLE TIME",
        "SOLVE THIS RIDDLE",
        "ANSWER THIS RIDDLE",
        "TIME FOR A RIDDLE",
        "LETS DO A RIDDLE",
        "LET'S DO A RIDDLE"
    }

    local function IsRiddleTrigger(t)
        local clean = CleanText(t)
        for _, phrase in ipairs(RiddleTriggerPhrases) do
            if clean:find(phrase, 1, true) then
                return true
            end
        end
        return false
    end

    local function RememberRiddleFacts(raw)
        local t = tostring(raw or "")
        local upper = string.upper(t)

        local name = t:match("[Mm][Yy]%s+[Nn][Aa][Mm][Ee]%s+[Ii][Ss]%s+([%w_%-]+)")
        if name then RiddleFacts.name = name end

        local weight = t:match("[Ii]%s+[Ww][Ee][Ii][Gg][Hh]%s*([%d%.]+)")
            or t:match("[Mm][Yy]%s+[Ww][Ee][Ii][Gg][Hh][Tt]%s+[Ii][Ss]%s*([%d%.]+)")
            or t:match("[Ww][Ee][Ii][Gg][Hh]%s*([%d%.]+)")
        if weight then RiddleFacts.weight = weight end

        local age = t:match("[Ii]%s+[Aa][Mm]%s+(%d+)%s+[Yy][Ee][Aa][Rr]")
            or t:match("[Ii]'[Mm]%s+(%d+)%s+[Yy][Ee][Aa][Rr]")
            or t:match("[Mm][Yy]%s+[Aa][Gg][Ee]%s+[Ii][Ss]%s+(%d+)")
        if age then RiddleFacts.age = age end

        local color = t:match("[Mm][Yy]%s+[Ff][Aa][Vv][Oo][Rr][Ii][Tt][Ee]%s+[Cc][Oo][Ll][Oo][Rr]%s+[Ii][Ss]%s+([%a]+)")
            or t:match("[Ff][Aa][Vv][Oo][Rr][Ii][Tt][Ee]%s+[Cc][Oo][Ll][Oo][Rr]%s+[Ii][Ss]%s+([%a]+)")
        if color then RiddleFacts.color = color end

        local number = t:match("[Mm][Yy]%s+[Nn][Uu][Mm][Bb][Ee][Rr]%s+[Ii][Ss]%s+(%d+)")
            or t:match("[Ff][Aa][Vv][Oo][Rr][Ii][Tt][Ee]%s+[Nn][Uu][Mm][Bb][Ee][Rr]%s+[Ii][Ss]%s+(%d+)")
        if number then RiddleFacts.number = number end

        local birthday = t:match("[Mm][Yy]%s+[Bb][Ii][Rr][Tt][Hh][Dd][Aa][Yy]%s+[Ii][Ss]%s+(.+)")
        if birthday and #birthday <= 30 then
            RiddleFacts.birthday = birthday:gsub("[%p]+$","")
        end
    end

    local function SolveSimpleMath(question)
        local q = question:gsub(",", "")
        local a, op, b = q:match("(-?%d+%.?%d*)%s*([%+%-%*/xX])%s*(-?%d+%.?%d*)")
        if not a then
            return nil
        end

        a, b = tonumber(a), tonumber(b)
        if not a or not b then return nil end

        local result
        if op == "+" then result = a + b
        elseif op == "-" then result = a - b
        elseif op == "*" or op == "x" or op == "X" then result = a * b
        elseif op == "/" and b ~= 0 then result = a / b
        end

        if result == nil then return nil end
        if math.floor(result) == result then
            return tostring(math.floor(result))
        end
        return tostring(result)
    end

    local function SolveRiddleQuestion(question)
        local q = CleanText(question)

        -- Memory questions.
        if q:find("WHAT",1,true) and q:find("NAME",1,true) and RiddleFacts.name then
            return tostring(RiddleFacts.name)
        end

        if (q:find("WEIGH",1,true) or q:find("WEIGHT",1,true)) and RiddleFacts.weight then
            return tostring(RiddleFacts.weight)
        end

        if q:find("HOW OLD",1,true) and RiddleFacts.age then
            return tostring(RiddleFacts.age)
        end

        if q:find("AGE",1,true) and RiddleFacts.age then
            return tostring(RiddleFacts.age)
        end

        if q:find("COLOR",1,true) and RiddleFacts.color then
            return tostring(RiddleFacts.color)
        end

        if q:find("NUMBER",1,true) and RiddleFacts.number then
            return tostring(RiddleFacts.number)
        end

        if q:find("BIRTHDAY",1,true) and RiddleFacts.birthday then
            return tostring(RiddleFacts.birthday)
        end

        -- Common small riddles.
        local common = {
            ["WHAT HAS KEYS BUT CANT OPEN LOCKS"] = "PIANO",
            ["WHAT HAS KEYS BUT CAN'T OPEN LOCKS"] = "PIANO",
            ["WHAT HAS HANDS BUT CANT CLAP"] = "CLOCK",
            ["WHAT HAS HANDS BUT CAN'T CLAP"] = "CLOCK",
            ["WHAT GETS WET WHILE DRYING"] = "TOWEL",
            ["WHAT HAS A FACE AND TWO HANDS BUT NO ARMS OR LEGS"] = "CLOCK",
            ["WHAT HAS ONE EYE BUT CANNOT SEE"] = "NEEDLE",
            ["WHAT HAS ONE EYE BUT CANT SEE"] = "NEEDLE",
            ["WHAT HAS A NECK BUT NO HEAD"] = "BOTTLE",
            ["WHAT HAS MANY TEETH BUT CANNOT BITE"] = "COMB",
            ["WHAT HAS MANY TEETH BUT CANT BITE"] = "COMB",
            ["WHAT GOES UP BUT NEVER COMES DOWN"] = "AGE"
        }

        for key, answer in pairs(common) do
            if q:find(key,1,true) then
                return answer
            end
        end

        local mathAnswer = SolveSimpleMath(question)
        if mathAnswer then
            return mathAnswer
        end

        -- Local fallback guess: use the most recent remembered fact that
        -- semantically resembles the question, otherwise no answer.
        if q:find("WHO",1,true) and RiddleFacts.name then
            return tostring(RiddleFacts.name)
        end

        return nil
    end

    local function RedeemRiddleAnswers()
        local count = #RiddleAnswers
        if count < 2 or count > 5 then return end

        CurrentMessages = {}
        for _, answer in ipairs(RiddleAnswers) do
            table.insert(CurrentMessages, CleanText(answer))
        end

        local finalText = table.concat(CurrentMessages, "")
        local box = FindCodeBox()

        if not box then
            Status.Text = "Riddle solved, but redeem box not found"
            Status.TextColor3 = RED
            return
        end

        pcall(function()
            box:CaptureFocus()
            box.Text = finalText
            box.CursorPosition = #finalText + 1
            box.SelectionStart = -1
        end)
        pcall(function() box.Text = finalText end)

        ClickSubmit()

        if count == 5 then
            RiddleAnswers = {}
            CurrentMessages = {}
            RiddleActive = false
            WaitingForCode = false
            pcall(function() box.Text = "" end)
            Status.Text = "Riddle data reset - waiting for next riddle..."
            Status.TextColor3 = GRAY
        else
            Status.Text = "Riddle redeemed " .. count .. "/5 - waiting for next question..."
            Status.TextColor3 = YELLOW
        end
    end

    local function HandleRiddleText(obj)
        if not RiddleSolverEnabled or Submitting or not IsTopArea(obj) then
            return false
        end

        local raw = tostring(obj.Text or "")
        local clean = CleanText(raw)
        if clean == "" then return false end

        if RiddleLastText[obj] == clean then
            return true
        end
        RiddleLastText[obj] = clean

        -- Always learn factual statements visible at the top.
        RememberRiddleFacts(raw)

        if not RiddleActive then
            if IsRiddleTrigger(clean) then
                RiddleActive = true
                RiddleAnswers = {}
                CurrentMessages = {}
                Status.Text = "Riddle detected - waiting for question..."
                Status.TextColor3 = GREEN
            end
            return true
        end

        if IsRiddleTrigger(clean) then
            return true
        end

        local answer = SolveRiddleQuestion(raw)
        if answer and answer ~= "" then
            table.insert(RiddleAnswers, answer)
            AddLog("Riddle solved: " .. clean .. " -> " .. CleanText(answer))
            Status.Text = "Solved: " .. CleanText(answer) .. " (" .. #RiddleAnswers .. "/5)"
            Status.TextColor3 = GREEN

            if #RiddleAnswers >= 2 then
                RedeemRiddleAnswers()
            end
        else
            Status.Text = "Riddle Solver couldn't solve that locally"
            Status.TextColor3 = RED
        end

        return true
    end

    local function AddCode(text)
        if not CopierEnabled or Submitting then return end

        text = CleanText(text)
        if IsBadText(text) then return end

        if SmartRedeemerEnabled then
            table.insert(CurrentMessages, text)
            AddLog("Smart captured " .. tostring(#CurrentMessages) .. "/5: " .. text)

            local count = #CurrentMessages
            if count > 5 then
                CurrentMessages = {}
                WaitingForCode = false
                Status.Text = "Smart reset - waiting for new code..."
                Status.TextColor3 = GRAY
                return
            end

            Status.Text = "SMART REDEEMING " .. tostring(count) .. "/5..."
            Status.TextColor3 = count == 5 and GREEN or YELLOW

            -- Smart Redeemer deliberately tries the accumulated code after
            -- EVERY piece: 1, 2, 3, 4, then 5.
            local typed = TypeIntoCodeBox()
            if typed then
                for _ = 1, 3 do
                    ClickSubmit()
                    task.wait()
                end
                AddLog("Smart redeem attempt " .. tostring(count) .. "/5")
            else
                AddLog("Smart write retry needed at " .. tostring(count) .. "/5")
            end

            if count >= 5 then
                local box = FindCodeBox()

                CurrentMessages = {}
                WaitingForCode = false
                SmartAwaitingResult = false
                SmartNeedsNextMessage = false
                SmartRetrying = false
                SmartAttemptId += 1

                if box then
                    pcall(function()
                        box.Text = ""
                    end)
                end

                Status.Text = PrepareEnabled
                    and "Smart reset - waiting for trigger..."
                    or "Smart reset - waiting for message 1/5..."
                Status.TextColor3 = GRAY
            else
                Status.Text = "Smart active - waiting for message " .. tostring(count + 1) .. "/5..."
                Status.TextColor3 = YELLOW
            end

            return
        end

    -- NORMAL REDEEMER
    table.insert(CurrentMessages, text)
    AddLog("Code part: " .. text)

    local count = #CurrentMessages
    Status.Text = "Captured " .. count .. "/" .. SubmitAfter .. " message(s)"
    Status.TextColor3 = GREEN

    -- Keep the textbox synchronized even before we hit the submit count.
    TypeIntoCodeBox()

    if AfterSubmitEnabled and count >= SubmitAfter then
        Submitting = true
        Status.Text = "AUTO REDEEMING..."
        Status.TextColor3 = GREEN
        AddLog("Redeeming " .. tostring(count) .. " part(s)")

        -- Re-write the full final code immediately before redeeming.
        local typed = TypeIntoCodeBox()

        if typed then
            SpamSubmit()
            AddLog("Redeem sent")
        else
            Status.Text = "Could not write redeem code"
            Status.TextColor3 = RED
            AddLog("Redeem failed: textbox unavailable")
        end

        CurrentMessages = {}
        WaitingForCode = false

        task.defer(function()
            Submitting = false
            Status.Text = PrepareEnabled and "Waiting for code..." or "Ready to capture..."
            Status.TextColor3 = GRAY
        end)
    end
end

local function HandlePopup(obj)
        if Submitting or not IsTopArea(obj) then return end

        if RiddleSolverEnabled then
            HandleRiddleText(obj)
            return
        end

        if not CopierEnabled then return end

        local text = CleanText(obj.Text)

        -- Always update the cache, including blank/placeholder states.
        -- This is important because the game reuses the SAME TextLabel.
        if LastText[obj] == text then
            return
        end
        LastText[obj] = text

        if IsBadText(text) then
            return
        end

        if not PrepareEnabled then
            AddCode(text)
            return
        end

        if not WaitingForCode then
            local phrase, _, b = FindTrigger(text)
            if not phrase then
                return
            end

            -- A new prepare trigger always starts a FRESH code.
            CurrentMessages = {}
            WaitingForCode = true

            local box = FindCodeBox()
            if box then
                pcall(function()
                    box.Text = ""
                    box.CursorPosition = 1
                    box.SelectionStart = -1
                end)
            end

            AddLog("Prepared: " .. phrase)
            Status.Text = SmartRedeemerEnabled
                and "Prepared - waiting for message 1/5..."
                or "Prepared - waiting for code..."
            Status.TextColor3 = GREEN

            -- Capture code text included in the same line after the trigger.
            local remaining = text:sub(b + 1):gsub("^[%s:%-=%.]+", "")
            if remaining ~= "" and remaining ~= "..." and remaining ~= "…" then
                AddCode(remaining)
            end

            return
        end

        -- If another prepare phrase appears while waiting, treat it as a NEW
        -- code announcement instead of accidentally concatenating two codes.
        local phrase, _, b = FindTrigger(text)
        if phrase then
            CurrentMessages = {}
            WaitingForCode = true

            local remaining = text:sub(b + 1):gsub("^[%s:%-=%.]+", "")
            AddLog("New code: " .. phrase)

            if remaining ~= "" and remaining ~= "..." and remaining ~= "…" then
                AddCode(remaining)
            else
                Status.Text = SmartRedeemerEnabled
                    and "Prepared - waiting for message 1/5..."
                    or "Prepared - waiting for code..."
                Status.TextColor3 = GREEN
            end
            return
        end

        AddCode(text)
    end

    local function HandleSmartInvalid(obj)
        -- Smart Redeemer V18 does not reset from bottom-screen result text.
        -- Code data resets only after the 5th captured message.
    end

    local SpawnVisibleState = {}

    local function Hook(obj)
        if not obj:IsA("TextLabel") or Hooked[obj] or not IsScreenUI(obj) then
            return
        end

        Hooked[obj] = true

        -- Do NOT swallow currently visible text when CodeSniper first attaches.
        -- Start empty, then process the label once.
        LastText[obj] = ""
        SpawnVisibleState[obj] = false

        obj:GetPropertyChangedSignal("Text"):Connect(function()
            task.defer(function()
                HandlePopup(obj)
                HandleSmartInvalid(obj)
                HandleSpawnResult(obj)
            end)
        end)

        obj:GetPropertyChangedSignal("Visible"):Connect(function()
            if obj.Visible then
                -- Same words can legitimately be used again in a later popup.
                LastText[obj] = ""
                SpawnVisibleState[obj] = false
                task.defer(function()
                    task.wait()
                    HandlePopup(obj)
                    HandleSmartInvalid(obj)
                    HandleSpawnResult(obj)
                end)
            else
                -- Reset both capture and spawn dedupe when the popup disappears.
                LastText[obj] = ""
                SpawnVisibleState[obj] = false
                SpawnSeenVisible[obj] = false
                SpawnSeenText[obj] = nil
            end
        end)

        -- Catch a trigger/code that was already on screen when script executed.
        if obj.Visible then
            task.defer(function()
                HandlePopup(obj)
                HandleSpawnResult(obj)
            end)
        end
    end

    for _, obj in ipairs(PlayerGui:GetDescendants()) do
        if obj:IsA("TextLabel") then
            Hook(obj)
        end
    end

    PlayerGui.DescendantAdded:Connect(function(obj)
        if not obj:IsA("TextLabel") then
            task.defer(UpdateDetected)
            return
        end

        task.defer(function()
            task.wait()
            Hook(obj)
            UpdateDetected()
        end)
    end)

    -- Fallback scanner: catches UI updates that fail to emit expected signals.
    -- It does NOT repeatedly log the same static popup.
    task.spawn(function()
        while Gui.Parent do
            UpdateDetected()

            for _, obj in ipairs(PlayerGui:GetDescendants()) do
                if obj:IsA("TextLabel") and IsScreenUI(obj) then
                    if not Hooked[obj] then
                        Hook(obj)
                    end

                    if IsTopArea(obj) then
                        local current = CleanText(obj.Text)
                        if LastText[obj] ~= current then
                            HandlePopup(obj)
                        end
                    end

                    if IsBottomGreenSpawnText(obj) then
                        HandleSpawnResult(obj)
                    else
                        -- A reused label changed away from the green spawn result.
                        if SpawnSeenVisible[obj] and tostring(obj.Text or "") ~= "" then
                            local currentSpawn = ExtractSpawnName(tostring(obj.Text or ""))
                            if not currentSpawn then
                                SpawnSeenVisible[obj] = false
                                SpawnSeenText[obj] = nil
                            end
                        end
                    end
                end
            end

            task.wait(0.15)
        end
    end)

    -- Preserve saved settings while clearing only runtime capture state.
    CurrentMessages = {}
    WaitingForCode = false
    Submitting = false

    Number.Text = tostring(SubmitAfter)
    local startupSnap = (SubmitAfter - 1) / 4
    Fill.Size = UDim2.new(startupSnap,0,1,0)
    Knob.Position = UDim2.new(startupSnap,0,0.5,0)
    PaintToggle(CopierToggle, CopierEnabled)
    if RiddleSolverEnabled then
        CopierEnabled = false
        PaintToggle(CopierToggle, false)
    else
        PaintToggle(CopierToggle, CopierEnabled)
    end
    PaintToggle(PrepareToggle, PrepareEnabled)
    PaintToggle(AfterSubmitToggle, AfterSubmitEnabled)
    PaintToggle(SmartRedeemerToggle, SmartRedeemerEnabled)
    UpdateSliderLock()

    UpdateDetected()
    SavePreferences()

    -- Fast loading animation, then reveal menu
    task.spawn(function()
        for i = 1, 12 do
            LoadingBar.Size = UDim2.new(i/12,0,1,0)
            LoadingCard.Rotation = math.sin(i/2) * 0.35
            task.wait()
        end
        LoadingCard.Rotation = 0
        Loading.Visible = false
    end)

    print("CodeSniper V54 loaded - direct image URL embeds")

end


StartCodeSniper()

-- Keep checking access while the script is running.
-- A temporary fetch failure does NOT revoke access; only a successful
-- whitelist fetch that confirms the user is absent does.
task.spawn(function()
    while true do
        task.wait(2)

        local allowed, reason = CheckWhitelist(true)

        if allowed == false then
            LocalPlayer:Kick("You don't have access")
            return
        elseif allowed == nil then
            warn("Live whitelist check skipped: " .. tostring(reason))
        end
    end
end)
