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
        if obj:FindFirstAncestorWhichIsA("BillboardGui") then return false end
        if obj:FindFirstAncestorWhichIsA("SurfaceGui") then return false end
        local sg = obj:FindFirstAncestorWhichIsA("ScreenGui")
        return sg ~= nil and sg ~= Gui
    end

    local function IsTopArea(obj)
        if not obj:IsA("TextLabel") or not IsScreenUI(obj) or not IsVisible(obj) then return false end
        local cam = workspace.CurrentCamera
        if not cam then return false end
        local vp = cam.ViewportSize
        local p, s = obj.AbsolutePosition, obj.AbsoluteSize
        local cx, cy = p.X + s.X/2, p.Y + s.Y/2
        return cx >= 0 and cx <= vp.X and cy >= 0 and cy <= vp.Y * 0.42
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
        if not CodesFrame then SubmitButton = nil return nil end

        for _, obj in ipairs(CodesFrame:GetDescendants()) do
            if obj:IsA("TextButton") and IsVisible(obj) then
                local t = CleanText(obj.Text)
                if t == "SUBMIT" or t == "REDEEM" or t:find("SUBMIT",1,true) or t:find("REDEEM",1,true) then
                    SubmitButton = obj
                    return obj
                end
            end
        end

        for _, obj in ipairs(CodesFrame:GetDescendants()) do
            if obj:IsA("TextLabel") and IsVisible(obj) then
                local t = CleanText(obj.Text)
                if t == "SUBMIT" or t == "REDEEM" then
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

    local function AddLog(text)
        table.insert(AllCaptured, text)
        local l = Instance.new("TextLabel", Scroll)
        l.Size = UDim2.new(1,-2,0,32); l.BackgroundColor3 = BG3; l.BackgroundTransparency = 0.15; l.BorderSizePixel = 0
        l.Text = "•  " .. text; l.TextColor3 = WHITE; l.TextSize = 13; l.Font = Enum.Font.GothamMedium
        l.ZIndex = 5; l.TextXAlignment = Enum.TextXAlignment.Left; l.TextTruncate = Enum.TextTruncate.AtEnd; l.ClipsDescendants = true
        local c = Instance.new("UICorner", l); c.CornerRadius = UDim.new(0,8)
        local p = Instance.new("UIPadding", l); p.PaddingLeft = UDim.new(0,8)
        task.defer(function()
            Scroll.CanvasPosition = Vector2.new(0, math.max(0, Scroll.AbsoluteCanvasSize.Y - Scroll.AbsoluteWindowSize.Y))
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
    Fill.Size = UDim2.new((SubmitAfter-1)/4,0,1,0); Fill.BackgroundColor3 = PURPLE; Fill.BorderSizePixel = 0
    local fc = Instance.new("UICorner", Fill); fc.CornerRadius = UDim.new(1,0)
    AddAnimatedGradient(Fill, 0.012)
    local Knob = Instance.new("TextButton", Slider)
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

    SmartRedeemerToggle.MouseButton1Click:Connect(function()
        SmartRedeemerEnabled = not SmartRedeemerEnabled

        if SmartRedeemerEnabled then
            -- Smart Redeemer owns submission while enabled.
            AfterSubmitEnabled = false
            PaintToggle(AfterSubmitToggle, false)
        end

        PaintToggle(SmartRedeemerToggle, SmartRedeemerEnabled)

        SmartAwaitingResult = false
        SmartNeedsNextMessage = false
        SmartRetrying = false
        SmartAttemptId += 1
        CurrentMessages = {}
        WaitingForCode = false

        if SmartRedeemerEnabled then
            Status.Text = "Smart Redeemer ON - waiting for 3 messages"
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
        local pct = math.clamp((x-Slider.AbsolutePosition.X)/Slider.AbsoluteSize.X,0,1)
        local value = math.clamp(math.floor(pct*4+1.5),1,5)
        SubmitAfter = value
        local snap = (value-1)/4
        Fill.Size = UDim2.new(snap,0,1,0); Knob.Position = UDim2.new(snap,0,0.5,0); Number.Text = tostring(value)
        SavePreferences()
    end
    Slider.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=true; SetSlider(i.Position.X) end end)
    Knob.MouseButton1Down:Connect(function() dragging=true end)
    UserInputService.InputChanged:Connect(function(i) if dragging and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then SetSlider(i.Position.X) end end)
    UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=false end end)

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
        CurrentMessages = {}
        WaitingForCode = false
        Submitting = false
        SmartAwaitingResult = false
        SmartNeedsNextMessage = false
        SmartRetrying = false
        SmartAttemptId += 1

        AllCaptured = {}
        for _, child in ipairs(Scroll:GetChildren()) do
            if child:IsA("TextLabel") then
                child:Destroy()
            end
        end

        local box = FindCodeBox()
        if box then
            pcall(function()
                box.Text = ""
            end)
        end

        Status.Text = "Logs reset"
        Status.TextColor3 = GRAY
        AddLog("Logs reset")
    end)

    -- EXACT Steal a Brainrot logo image supplied by the user.
    -- Put steal_a_brainrot.png beside this script OR upload it to this repo:
    -- https://raw.githubusercontent.com/SigMaUgI/codesniper/refs/heads/main/steal_a_brainrot.png
    local BRAINROT_IMAGE_URL = "https://raw.githubusercontent.com/SigMaUgI/codesniper/refs/heads/main/steal_a_brainrot.png"
    local BRAINROT_LOCAL_FILE = "steal_a_brainrot.png"
    local BRAINROT_IMAGE = ""

    pcall(function()
        if getcustomasset then
            if isfile and isfile(BRAINROT_LOCAL_FILE) then
                BRAINROT_IMAGE = getcustomasset(BRAINROT_LOCAL_FILE)
            elseif writefile then
                local raw = game:HttpGet(BRAINROT_IMAGE_URL)
                if raw and #raw > 100 then
                    writefile(BRAINROT_LOCAL_FILE, raw)
                    BRAINROT_IMAGE = getcustomasset(BRAINROT_LOCAL_FILE)
                end
            end
        end
    end)

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
        local usable = BRAINROT_IMAGE ~= ""

        if collapsed or SettingsPanel.Size.Y.Offset <= 60 or not usable then
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

        -- Center sits exactly on the Config bottom edge:
        -- half the image is inside the menu and half is outside.
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
        "THE CODE:",
        "USE CODE",
        "USE THE CODE",
        "USE THIS CODE",
        "OK HERE'S THE CODE",
        "OK HERES THE CODE",
        "OK, HERE'S THE CODE",
        "OK, HERES THE CODE",
        "HERE'S THE CODE",
        "HERES THE CODE",
        "YOUR CODE IS",
        "YOUR CODE:",
        "CODE IS",
        "CODE:",
        "REDEEM CODE",
        "REDEEM THIS CODE",
        "ENTER CODE",
        "ENTER THIS CODE",
        "TYPE THIS CODE",
        "TRY THIS CODE",
        "PUT IN CODE",
        "PUT THIS CODE IN",
        "USE THIS",
        "THE REDEEM CODE IS",
        "REDEEM WITH",
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

    -- Type into real TextBox inside CodeRedeem
    local function TypeIntoCodeBox()
        local box = FindCodeBox()
        if not box then Status.Text="No TextBox inside CodeRedeem"; Status.TextColor3=RED; return false end

        local finalText = table.concat(CurrentMessages, "")
        if finalText == "" then
            Status.Text = "No code data to redeem"
            Status.TextColor3 = RED
            return false
        end

        -- Focus the REAL redeem TextBox first, then inject the captured code.
        local pos,size = box.AbsolutePosition,box.AbsoluteSize
        local x,y = math.floor(pos.X+size.X/2), math.floor(pos.Y+size.Y/2)

        pcall(function()
            VirtualInputManager:SendMouseButtonEvent(x,y,0,true,game,0)
            
            VirtualInputManager:SendMouseButtonEvent(x,y,0,false,game,0)
        end)

        pcall(function()
            box:CaptureFocus()
        end)
        

        -- Set the value while focused so the game's textbox listeners see the code.
        pcall(function()
            box.Text = finalText
            box.CursorPosition = #finalText + 1
            box.SelectionStart = -1
        end)

        -- Fire the Text property signal when supported by the executor.
        if firesignal then
            pcall(function()
                firesignal(box:GetPropertyChangedSignal("Text"))
            end)
        end

        

        -- Keep focus until ClickSubmit runs. Releasing focus before redeeming can
        -- cause some UIs to clear/ignore their internal code value.
        print("TYPED CODE DATA:", finalText)
        -- The game may update its TextBox state a frame later.
        -- We already forced the text into the real box, so don't block instant redeem
        -- on an immediate equality check.
        pcall(function()
            box.Text = finalText
            box.CursorPosition = #finalText + 1
        end)
        return true
    end

    local function ClickSubmit()
        local button = FindSubmit()
        if not button then Status.Text="Submit not found"; Status.TextColor3=RED; return false end
        local pos,size = button.AbsolutePosition,button.AbsoluteSize
        local x,y = math.floor(pos.X+size.X/2), math.floor(pos.Y+size.Y/2)
        pcall(function()
            VirtualInputManager:SendMouseMoveEvent(x,y,game)
            VirtualInputManager:SendMouseButtonEvent(x,y,0,true,game,0)
            
            VirtualInputManager:SendMouseButtonEvent(x,y,0,false,game,0)
        end)
        pcall(function() button:Activate() end)
        if firesignal then
            pcall(function() firesignal(button.Activated) end)
            if button:IsA("TextButton") then pcall(function() firesignal(button.MouseButton1Click) end) end
        end
        if getconnections then
            pcall(function() for _,c in ipairs(getconnections(button.Activated)) do c:Fire() end end)
        end
        return true
    end

    local function SpamSubmit()
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
        AddLog("Captured: " .. text)

        if #CurrentMessages < 3 then
            Status.Text = "Smart captured " .. #CurrentMessages .. "/3"
            Status.TextColor3 = GREEN
            TypeIntoCodeBox()
            return
        end

        if #CurrentMessages <= 5 then
            Status.Text = "SMART REDEEMING " .. #CurrentMessages .. "/5..."
            Status.TextColor3 = (#CurrentMessages == 3) and GREEN or YELLOW

            -- Force the complete accumulated code into the real TextBox.
            local finalText = table.concat(CurrentMessages, "")
            local box = FindCodeBox()

            if not box then
                Status.Text = "No TextBox inside CodeRedeem"
                Status.TextColor3 = RED
                return
            end

            pcall(function()
                box:CaptureFocus()
                box.Text = finalText
                box.CursorPosition = #finalText + 1
                box.SelectionStart = -1
            end)

            -- Set it again immediately so no intermediate UI update can leave it blank.
            pcall(function()
                box.Text = finalText
            end)

            -- ZERO intentional delay: redeem immediately after writing.
            ClickSubmit()

            if #CurrentMessages == 5 then
                -- Only reset after the 5th captured message.
                CurrentMessages = {}
                WaitingForCode = false
                SmartAwaitingResult = false
                SmartNeedsNextMessage = false
                SmartRetrying = false
                SmartAttemptId += 1

                pcall(function()
                    box.Text = ""
                end)

                Status.Text = "Smart reset - waiting for new code..."
                Status.TextColor3 = GRAY
            else
                Status.Text = "SMART ACTIVE - waiting for next message..."
                Status.TextColor3 = YELLOW
            end

            return
        end

        -- Safety fallback. Smart mode never keeps more than 5 pieces.
        CurrentMessages = {}
        WaitingForCode = false
        Status.Text = "Smart reset - waiting for new code..."
        Status.TextColor3 = GRAY
        return
    end

    if #CurrentMessages >= SubmitAfter then
        CurrentMessages = {}
    end

    table.insert(CurrentMessages,text)
    AddLog("Captured: " .. text)
    Status.Text = "Captured " .. #CurrentMessages .. "/" .. SubmitAfter .. " message(s)"
    Status.TextColor3 = GREEN
    TypeIntoCodeBox()

    if AfterSubmitEnabled and #CurrentMessages == SubmitAfter then
        Submitting = true
        Status.Text = "SUBMITTING x10..."
        Status.TextColor3 = GREEN

        local typed = TypeIntoCodeBox()
        local liveBox = FindCodeBox()

        if typed and liveBox and CleanText(liveBox.Text) ~= "" then
            SpamSubmit()
        else
            Status.Text = "Code was not inside redeem box"
            Status.TextColor3 = RED
        end

        CurrentMessages = {}
        WaitingForCode = false

        task.delay(0.1,function()
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
        if IsBadText(text) or LastText[obj] == text then return end
        LastText[obj] = text

        if not PrepareEnabled then AddCode(text); return end

        if not WaitingForCode then
            local phrase,_,b = FindTrigger(text)
            if not phrase then return end

            WaitingForCode = true
            Status.Text = "Code detected..."
            Status.TextColor3 = GREEN

            -- If the trigger and the first code piece are in the same message,
            -- immediately capture everything after the trigger phrase.
            local remaining = text:sub(b+1):gsub("^[%s:%-%.]+","")

            if remaining ~= "" and remaining ~= "..." and remaining ~= "…" then
                AddCode(remaining)
            elseif SmartRedeemerEnabled then
                Status.Text = "Smart Redeemer waiting for code messages..."
                Status.TextColor3 = YELLOW
            end

            return
        end

        if FindTrigger(text) then return end
        AddCode(text)
    end

    local function HandleSmartInvalid(obj)
        -- Smart Redeemer V18 does not reset from bottom-screen result text.
        -- Code data resets only after the 5th captured message.
    end

    local function Hook(obj)
        if not obj:IsA("TextLabel") or Hooked[obj] or not IsScreenUI(obj) then return end
        Hooked[obj] = true
        LastText[obj] = CleanText(obj.Text)
        obj:GetPropertyChangedSignal("Text"):Connect(function() task.defer(function() HandlePopup(obj); HandleSmartInvalid(obj) end) end)
        obj:GetPropertyChangedSignal("Visible"):Connect(function() if obj.Visible then task.defer(function() HandlePopup(obj); HandleSmartInvalid(obj) end) end end)
    end

    for _,obj in ipairs(PlayerGui:GetDescendants()) do if obj:IsA("TextLabel") then Hook(obj) end end

    PlayerGui.DescendantAdded:Connect(function(obj)
        task.defer(function() task.wait(); UpdateDetected() end)
        if not obj:IsA("TextLabel") then return end
        task.defer(function()
            task.wait()
            if not IsScreenUI(obj) then return end
            Hooked[obj] = true
            LastText[obj] = ""
            obj:GetPropertyChangedSignal("Text"):Connect(function() task.defer(function() HandlePopup(obj); HandleSmartInvalid(obj) end) end)
            obj:GetPropertyChangedSignal("Visible"):Connect(function() if obj.Visible then task.defer(function() HandlePopup(obj); HandleSmartInvalid(obj) end) end end)
            HandlePopup(obj)
        end)
    end)

    task.spawn(function()
        while Gui.Parent do
            UpdateDetected()
            task.wait(0.25)
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

    print("CodeSniper loaded - made by FTX")

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
