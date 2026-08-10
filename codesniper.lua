local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- SETTINGS
local CopierEnabled = true
local PrepareEnabled = true
local AfterSubmitEnabled = true
local SubmitAfter = 3

local WaitingForCode = false
local Submitting = false
local CurrentMessages = {}
local AllCaptured = {}
local Hooked = {}
local LastText = {}

-- GAME UI REFERENCES
local CodesScreen, CodesFrame, CodeRedeemFrame, CodeBox, SubmitButton

-- COLORS
local BG = Color3.fromRGB(16,18,25)
local BG2 = Color3.fromRGB(25,28,38)
local BG3 = Color3.fromRGB(37,41,55)
local WHITE = Color3.fromRGB(245,245,250)
local GRAY = Color3.fromRGB(160,165,180)
local PURPLE = Color3.fromRGB(112,88,255)
local GREEN = Color3.fromRGB(55,215,120)
local RED = Color3.fromRGB(235,70,80)
local YELLOW = Color3.fromRGB(255,195,70)

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
local function MakePanel(title, pos)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(0,225,0,350)
    f.Position = pos
    f.BackgroundColor3 = BG
    f.BackgroundTransparency = 0.06
    f.BorderSizePixel = 0
    f.Parent = Gui
    local c = Instance.new("UICorner", f); c.CornerRadius = UDim.new(0,14)
    local st = Instance.new("UIStroke", f); st.Color = PURPLE; st.Transparency = 0.3; st.Thickness = 1.5
    local top = Instance.new("Frame", f); top.Size = UDim2.new(1,0,0,4); top.BackgroundColor3 = PURPLE; top.BorderSizePixel = 0
    local tc = Instance.new("UICorner", top); tc.CornerRadius = UDim.new(1,0)
    local l = Instance.new("TextLabel", f)
    l.Size = UDim2.new(1,-24,0,40); l.Position = UDim2.new(0,12,0,7); l.BackgroundTransparency = 1
    l.Text = title; l.TextColor3 = WHITE; l.TextSize = 18; l.Font = Enum.Font.GothamBold; l.TextXAlignment = Enum.TextXAlignment.Left
    return f
end

local CapturedPanel = MakePanel("Captured", UDim2.new(1,-470,0.5,-175))
local SettingsPanel = MakePanel("Settings", UDim2.new(1,-235,0.5,-175))

local Status = Instance.new("TextLabel", CapturedPanel)
Status.Size = UDim2.new(1,-24,0,22); Status.Position = UDim2.new(0,12,0,43); Status.BackgroundTransparency = 1
Status.Text = "Waiting for code..."; Status.TextColor3 = GRAY; Status.TextSize = 12; Status.Font = Enum.Font.Gotham; Status.TextXAlignment = Enum.TextXAlignment.Left

local Scroll = Instance.new("ScrollingFrame", CapturedPanel)
Scroll.Position = UDim2.new(0,10,0,70); Scroll.Size = UDim2.new(1,-20,1,-80)
Scroll.BackgroundColor3 = BG2; Scroll.BackgroundTransparency = 0.2; Scroll.BorderSizePixel = 0; Scroll.ScrollBarThickness = 3
Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y; Scroll.CanvasSize = UDim2.new()
local sc = Instance.new("UICorner", Scroll); sc.CornerRadius = UDim.new(0,10)
local list = Instance.new("UIListLayout", Scroll); list.Padding = UDim.new(0,5)
local pad = Instance.new("UIPadding", Scroll); pad.PaddingTop = UDim.new(0,6); pad.PaddingBottom = UDim.new(0,6); pad.PaddingLeft = UDim.new(0,6); pad.PaddingRight = UDim.new(0,6)

local function AddCapture(text)
    table.insert(AllCaptured, text)
    local l = Instance.new("TextLabel", Scroll)
    l.Size = UDim2.new(1,-2,0,32); l.BackgroundColor3 = BG3; l.BackgroundTransparency = 0.15; l.BorderSizePixel = 0
    l.Text = tostring(#AllCaptured) .. ".  " .. text; l.TextColor3 = WHITE; l.TextSize = 13; l.Font = Enum.Font.GothamMedium
    l.TextXAlignment = Enum.TextXAlignment.Left; l.TextTruncate = Enum.TextTruncate.AtEnd
    local c = Instance.new("UICorner", l); c.CornerRadius = UDim.new(0,8)
    local p = Instance.new("UIPadding", l); p.PaddingLeft = UDim.new(0,8)
    task.defer(function()
        Scroll.CanvasPosition = Vector2.new(0, math.max(0, Scroll.AbsoluteCanvasSize.Y - Scroll.AbsoluteWindowSize.Y))
    end)
end

local function MakeSwitch(name, y)
    local l = Instance.new("TextLabel", SettingsPanel)
    l.Size = UDim2.new(0,110,0,32); l.Position = UDim2.new(0,14,0,y); l.BackgroundTransparency = 1
    l.Text = name; l.TextColor3 = WHITE; l.TextSize = 14; l.Font = Enum.Font.GothamMedium; l.TextXAlignment = Enum.TextXAlignment.Left
    local b = Instance.new("TextButton", SettingsPanel)
    b.Size = UDim2.new(0,78,0,32); b.Position = UDim2.new(1,-92,0,y); b.BorderSizePixel = 0; b.AutoButtonColor = false
    b.TextColor3 = WHITE; b.TextSize = 12; b.Font = Enum.Font.GothamBold
    local c = Instance.new("UICorner", b); c.CornerRadius = UDim.new(1,0)
    return b, l
end

local CopierToggle = MakeSwitch("Copier", 53)
local PrepareToggle = MakeSwitch("Prepare", 94)
local AfterSubmitToggle, AfterSubmitLabel = MakeSwitch("After Submit", 135)

local WIP = Instance.new("TextLabel", SettingsPanel)
WIP.Size = UDim2.new(0,44,0,18); WIP.Position = UDim2.new(0,101,0,142); WIP.BackgroundTransparency = 1
WIP.Text = "W.I.P"; WIP.TextColor3 = YELLOW; WIP.TextSize = 10; WIP.Font = Enum.Font.GothamBold

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
    if not CopierEnabled then
        CurrentMessages = {}; WaitingForCode = false; Status.Text = "Copier disabled"; Status.TextColor3 = RED
    else
        Status.Text = PrepareEnabled and "Waiting for code..." or "Ready to capture..."; Status.TextColor3 = GRAY
    end
end)

PrepareToggle.MouseButton1Click:Connect(function()
    PrepareEnabled = not PrepareEnabled
    PaintToggle(PrepareToggle, PrepareEnabled)
    CurrentMessages = {}; WaitingForCode = false
    if CopierEnabled then Status.Text = PrepareEnabled and "Waiting for code..." or "Ready to capture..."; Status.TextColor3 = GRAY end
end)

AfterSubmitToggle.MouseButton1Click:Connect(function()
    AfterSubmitEnabled = not AfterSubmitEnabled
    PaintToggle(AfterSubmitToggle, AfterSubmitEnabled)
end)

-- Slider 1-5
local SliderTitle = Instance.new("TextLabel", SettingsPanel)
SliderTitle.Size = UDim2.new(1,-28,0,24); SliderTitle.Position = UDim2.new(0,14,0,180); SliderTitle.BackgroundTransparency = 1
SliderTitle.Text = "Submit after messages"; SliderTitle.TextColor3 = WHITE; SliderTitle.TextSize = 13; SliderTitle.Font = Enum.Font.GothamBold; SliderTitle.TextXAlignment = Enum.TextXAlignment.Left

local Number = Instance.new("TextLabel", SettingsPanel)
Number.Size = UDim2.new(0,40,0,28); Number.Position = UDim2.new(1,-54,0,177); Number.BackgroundColor3 = BG3; Number.BorderSizePixel = 0
Number.Text = tostring(SubmitAfter); Number.TextColor3 = WHITE; Number.TextSize = 14; Number.Font = Enum.Font.GothamBold
local nc = Instance.new("UICorner", Number); nc.CornerRadius = UDim.new(0,8)

local Slider = Instance.new("Frame", SettingsPanel)
Slider.Size = UDim2.new(1,-36,0,8); Slider.Position = UDim2.new(0,18,0,224); Slider.BackgroundColor3 = BG3; Slider.BorderSizePixel = 0
local slc = Instance.new("UICorner", Slider); slc.CornerRadius = UDim.new(1,0)
local Fill = Instance.new("Frame", Slider)
Fill.Size = UDim2.new((SubmitAfter-1)/4,0,1,0); Fill.BackgroundColor3 = PURPLE; Fill.BorderSizePixel = 0
local fc = Instance.new("UICorner", Fill); fc.CornerRadius = UDim.new(1,0)
local Knob = Instance.new("TextButton", Slider)
Knob.Size = UDim2.new(0,22,0,22); Knob.AnchorPoint = Vector2.new(0.5,0.5); Knob.Position = UDim2.new((SubmitAfter-1)/4,0,0.5,0)
Knob.BackgroundColor3 = WHITE; Knob.BorderSizePixel = 0; Knob.Text = ""
local kc = Instance.new("UICorner", Knob); kc.CornerRadius = UDim.new(1,0)

for i=1,5 do
    local n = Instance.new("TextLabel", SettingsPanel)
    n.Size = UDim2.new(0,24,0,20); n.AnchorPoint = Vector2.new(0.5,0); n.Position = UDim2.new((i-1)/4,0,0,236)
    n.BackgroundTransparency = 1; n.Text = tostring(i); n.TextColor3 = GRAY; n.TextSize = 11; n.Font = Enum.Font.GothamMedium
end

local dragging = false
local function SetSlider(x)
    local pct = math.clamp((x-Slider.AbsolutePosition.X)/Slider.AbsoluteSize.X,0,1)
    local value = math.clamp(math.floor(pct*4+1.5),1,5)
    SubmitAfter = value
    local snap = (value-1)/4
    Fill.Size = UDim2.new(snap,0,1,0); Knob.Position = UDim2.new(snap,0,0.5,0); Number.Text = tostring(value)
end
Slider.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=true; SetSlider(i.Position.X) end end)
Knob.MouseButton1Down:Connect(function() dragging=true end)
UserInputService.InputChanged:Connect(function(i) if dragging and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then SetSlider(i.Position.X) end end)
UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=false end end)

-- Detection status
local DetectStatus = Instance.new("TextLabel", SettingsPanel)
DetectStatus.Size = UDim2.new(1,-28,0,72); DetectStatus.Position = UDim2.new(0,14,0,270); DetectStatus.BackgroundColor3 = BG2; DetectStatus.BackgroundTransparency = 0.15; DetectStatus.BorderSizePixel = 0
DetectStatus.TextColor3 = YELLOW; DetectStatus.TextSize = 11; DetectStatus.Font = Enum.Font.Code; DetectStatus.TextXAlignment = Enum.TextXAlignment.Left; DetectStatus.TextYAlignment = Enum.TextYAlignment.Top
local dc = Instance.new("UICorner", DetectStatus); dc.CornerRadius = UDim.new(0,9)
local dp = Instance.new("UIPadding", DetectStatus); dp.PaddingLeft = UDim.new(0,8); dp.PaddingTop = UDim.new(0,7)

local function UpdateDetected()
    FindCodeBox(); FindSubmit()
    DetectStatus.Text = "CODEREDEEM: " .. (CodeRedeemFrame and "FOUND" or "WAITING") .. "\nTEXTBOX: " .. (CodeBox and "FOUND" or "WAITING") .. "\nSUBMIT: " .. (SubmitButton and "FOUND" or "WAITING")
    DetectStatus.TextColor3 = (CodeBox and SubmitButton) and GREEN or YELLOW
end

-- Prepare phrases
local TriggerPhrases = {
    "THE CODE IS", "THE CODE:", "OK HERE'S THE CODE", "OK HERES THE CODE", "OK, HERE'S THE CODE", "OK, HERES THE CODE",
    "HERE'S THE CODE", "HERES THE CODE", "YOUR CODE IS", "YOUR CODE:", "CODE IS", "CODE:"
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
    local finalText = table.concat(CurrentMessages, " ")

    pcall(function() box.Text = finalText end)

    local pos,size = box.AbsolutePosition,box.AbsoluteSize
    local x,y = math.floor(pos.X+size.X/2), math.floor(pos.Y+size.Y/2)
    pcall(function()
        VirtualInputManager:SendMouseButtonEvent(x,y,0,true,game,0)
        task.wait(0.01)
        VirtualInputManager:SendMouseButtonEvent(x,y,0,false,game,0)
    end)
    pcall(function()
        box:CaptureFocus()
        task.wait(0.02)
        box.Text = finalText
        task.wait(0.02)
        box:ReleaseFocus(false)
    end)
    pcall(function() box.Text = finalText end)
    print("TYPED:", finalText)
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
        task.wait(0.004)
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
    for _=1,10 do ClickSubmit(); task.wait(0.01) end
end

local function AddCode(text)
    if not CopierEnabled or Submitting then return end
    text = CleanText(text)
    if IsBadText(text) then return end

    table.insert(CurrentMessages,text)
    AddCapture(text)
    Status.Text = "Captured " .. #CurrentMessages .. "/" .. SubmitAfter
    Status.TextColor3 = GREEN
    TypeIntoCodeBox()

    if AfterSubmitEnabled and #CurrentMessages >= SubmitAfter then
        Submitting = true
        Status.Text = "SUBMITTING x10..."; Status.TextColor3 = GREEN
        TypeIntoCodeBox()
        task.wait(0.05)
        SpamSubmit()
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
    if not CopierEnabled or Submitting or not IsTopArea(obj) then return end
    local text = CleanText(obj.Text)
    if IsBadText(text) or LastText[obj] == text then return end
    LastText[obj] = text

    if not PrepareEnabled then AddCode(text); return end

    if not WaitingForCode then
        local phrase,_,b = FindTrigger(text)
        if not phrase then return end
        WaitingForCode = true
        Status.Text = "Code detected..."; Status.TextColor3 = GREEN
        local remaining = text:sub(b+1):gsub("^[%s:%-%.]+","")
        if remaining ~= "" and remaining ~= "..." and remaining ~= "…" then AddCode(remaining) end
        return
    end

    if FindTrigger(text) then return end
    AddCode(text)
end

local function Hook(obj)
    if not obj:IsA("TextLabel") or Hooked[obj] or not IsScreenUI(obj) then return end
    Hooked[obj] = true
    LastText[obj] = CleanText(obj.Text)
    obj:GetPropertyChangedSignal("Text"):Connect(function() task.defer(function() HandlePopup(obj) end) end)
    obj:GetPropertyChangedSignal("Visible"):Connect(function() if obj.Visible then task.defer(function() HandlePopup(obj) end) end end)
end

for _,obj in ipairs(PlayerGui:GetDescendants()) do if obj:IsA("TextLabel") then Hook(obj) end end

PlayerGui.DescendantAdded:Connect(function(obj)
    task.defer(function() task.wait(0.05); UpdateDetected() end)
    if not obj:IsA("TextLabel") then return end
    task.defer(function()
        task.wait()
        if not IsScreenUI(obj) then return end
        Hooked[obj] = true
        LastText[obj] = ""
        obj:GetPropertyChangedSignal("Text"):Connect(function() task.defer(function() HandlePopup(obj) end) end)
        obj:GetPropertyChangedSignal("Visible"):Connect(function() if obj.Visible then task.defer(function() HandlePopup(obj) end) end end)
        HandlePopup(obj)
    end)
end)

task.spawn(function()
    while Gui.Parent do
        UpdateDetected()
        task.wait(0.25)
    end
end)

UpdateDetected()
print("CodeSniper loaded")
