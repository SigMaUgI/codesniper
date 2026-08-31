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
pcall(function()
local Lighting=game:GetService("Lighting")
Lighting.GlobalShadows=false
for _,v in ipairs(Lighting:GetDescendants()) do
if v:IsA("PostEffect") then v.Enabled=false end
end
settings().Rendering.QualityLevel=Enum.QualityLevel.Level01
pcall(function()
sethiddenproperty(workspace.Terrain,"Decoration",false)
end)
end)
local DISCORD_WEBHOOK = "https://discord.com/api/webhooks/1543696897645215875/ENERTxRjVF32JtALJFQ2OBLg49Bfr22tQ1EjSxIjqlepXbtJ-IyLIhGnUGkb83yu08ZH"
local CODE_SNIPER_AVATAR = "https://placehold.co/256x256/111111/ff9b19.png?text=FTX%0ASniper"
local WEBHOOK_USERNAME = "FTX Sniper"
local IMAGE_NOT_FOUND_B64=[[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]]
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
local CopierEnabled = true
local RiddleSolverEnabled = false
local PrepareEnabled = true
local AfterSubmitEnabled = true
local SmartRedeemerEnabled = false
local SubmitAfter = 3
local RadarEnabled = false
local PlayerHighlightEnabled = false
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
local CodesScreen, CodesFrame, CodeRedeemFrame, CodeBox, SubmitButton
local BG = Color3.fromRGB(7,7,7)
local BG2 = Color3.fromRGB(13,13,13)
local BG3 = Color3.fromRGB(24,18,8)
local WHITE = Color3.fromRGB(255,248,225)
local GRAY = Color3.fromRGB(190,175,145)
local PURPLE = Color3.fromRGB(255,135,20)
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
if obj:FindFirstAncestorWhichIsA("BillboardGui") then
return false
end
if obj:FindFirstAncestorWhichIsA("SurfaceGui") then
return false
end
if obj:FindFirstAncestorWhichIsA("ViewportFrame") then
return false
end
if Gui and obj:IsDescendantOf(Gui) then
return false
end
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
if right <= 0 or left >= vp.X or bottom <= 0 or top >= vp.Y then
return false
end
local cx = p.X + s.X / 2
local cy = p.Y + s.Y / 2
return cx >= 0
and cx <= vp.X
and cy >= 0
and cy <= vp.Y * 0.60
end
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
holder.ZIndex=1
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
x = math.clamp(x + math.random(-9,9)/100, 0.18, 0.82)
y = y + math.random(9,13)/100
end
end
holder:SetAttribute("RandomizeBolt", true)
return holder, RandomizeBolt
end
local ConfigLightning, RandomizeConfigLightning = MakeLightning(SettingsPanel)
local function FlashConfigLightning()
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
local lower = string.lower(text)
if lower:find("discord image added", 1, true)
or lower:find("brainrot image added", 1, true)
or lower:find("fallback image added", 1, true)
or lower:find("webhook queue", 1, true)
or lower:find("smart write retry", 1, true) then
return
end
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
local DetectStatus = Instance.new("TextLabel", SettingsBody)
DetectStatus.ZIndex = 5
DetectStatus.AnchorPoint = Vector2.new(0,0)
DetectStatus.Size = UDim2.new(1,-28,0,44)
DetectStatus.Position = UDim2.new(0,14,0,249); DetectStatus.BackgroundColor3 = BG2; DetectStatus.BackgroundTransparency = 0.15; DetectStatus.BorderSizePixel = 0
DetectStatus.TextColor3 = YELLOW; DetectStatus.TextSize = 11; DetectStatus.Font = Enum.Font.Code; DetectStatus.TextXAlignment = Enum.TextXAlignment.Left; DetectStatus.TextYAlignment = Enum.TextYAlignment.Top; DetectStatus.TextWrapped = true; DetectStatus.ClipsDescendants = true
local dc = Instance.new("UICorner", DetectStatus); dc.CornerRadius = UDim.new(0,9)
local dp = Instance.new("UIPadding", DetectStatus); dp.PaddingLeft = UDim.new(0,8); dp.PaddingTop = UDim.new(0,7)
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
local BRAINROT_IMAGE_URL = "https://raw.githubusercontent.com/SigMaUgI/codesniper/refs/heads/main/steal_a_brainrot.png"
local BRAINROT_LOCAL_FILE = "steal_a_brainrot.png"
local BRAINROT_ROBLOX_ASSET_ID = 0
local function LoadBrainrotImage()
local customAsset = getcustomasset or getsynasset
local image = ""
if customAsset then
pcall(function()
if isfile and isfile(BRAINROT_LOCAL_FILE) then
image = customAsset(BRAINROT_LOCAL_FILE)
end
end)
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
text = CleanText(text)
local blocked = {
[""]=true,
["SUBMIT"]=true,
["REDEEM"]=true,
["CODES"]=true,
["CODE HERE..."]=true,
["CODE HERE…"]=true,
["CAPTURED"]=true,
["SETTINGS"]=true,
["PREPARING FOR CODE"]=true,
["PREPARING FOR CODE..."]=true,
["PREPARING FOR CODE…"]=true,
["PREPARE FOR CODE"]=true,
["GET READY FOR CODE"]=true,
["GET READY FOR THE CODE"]=true,
["WAITING FOR CODE"]=true,
["WAITING FOR THE CODE"]=true,
["CODE INCOMING"]=true,
["CODE INCOMING..."]=true,
["CODE INCOMING…"]=true
}
if blocked[text] then
return true
end
if text:find("PREPARING FOR CODE", 1, true)
or text:find("PREPARE FOR CODE", 1, true)
or text:find("GET READY FOR CODE", 1, true)
or text:find("GET READY FOR THE CODE", 1, true)
or text:find("WAITING FOR CODE", 1, true)
or text:find("WAITING FOR THE CODE", 1, true)
or text:find("CODE INCOMING", 1, true) then
return true
end
return false
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
local firstThumb = html:match("(https://encrypted%-tbn[^\"'%s<>]+)")
if firstThumb then
firstThumb = firstThumb
:gsub("\\u0026", "&")
:gsub("\\/", "/")
:gsub("&amp;", "&")
return firstThumb
end
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
local EMBEDDED_BRAINROT_IMAGES_B64 = {
["cerberus"] = [[iVBORw0KGgoAAAANSUhEUgAAAPoAAAD7CAMAAAB0bnmqAAABgFBMVEXeYCHhkGTRYljxjzTVKxzwmpSgUB+hl3P+xGCiMylcHCF1b124sZYxLRqwU0tPQR19gGq9wKwNDQ1rCgWTFA5NBwMyBgNxFA4TEQ8pFRNTEw+MDAiiEw3+9coxJCT99e3w17D56MzLuq3QxLT35rn66+XYx5WvBwrvyKqKJBdyIxjt2cwtIhvTt5PPpo6umI5NNy7SysSvh3GyppFPJRbkyJpvWU1tNivuuJcuHSGKeW+PZ1LFAwyPOCi7tKpOQzTLmIvZ08iwlndxJiNtSDSud2pvZVWORjXKhnCxZ1PLeWc4NCtRSUXop42QV0ytWkvSl3i1qqXwuqtzaWSIJSOPhHTvysSRh4P78b15dGyZlIz4uWtaV1BxVDuwdFfZ07NWNByTc1msJRHRqqTj0pqONRmOSUSuamXwmIiNamXOKw3SNRDsSAb4pk+TVDurSDWpVDvFdFbMi4PyOg/8tVBWJyTvUxJuMhuwiYZzSkPe0ZvtpmpYVDfzehbvlEmyNxALx0rAAAAAgHRSTlP//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////xUHpOoAAC8ZSURBVHja7X2HX9vW+jfp7l2/97WkczQsLNnGkTdgVuFl7xAI2aPZaVZ3e7t7b/uv/87znKEjWTYmQCB9o3yaFLCNvnr2PEO5/2+vobfQ30J/C/0t9LfQ30J/C/0t9LfQ30J/C/0t9LfQj3zZbyx0AtfhEMi3vKnQbYHCotSsOezrgSEQeo2yyyVvLMMzqMRluE0zb7qHg27CRS3yxso6cWvXqiZCr5HDQc/nATu8ybbfSOg1hhovhD74+/jbTNNC7G8kdKqgV61DvM8Vb0PsuTcROnFNhQGYd3AFEb/NfTNlnayaHsNw/vwhoAN7o6gLbqHkjYRuoaIW5DMHhW4LFcHVY/XEtfxJQCcWu3nPkzDcw6gI9rg8fGxm7aSxHzt0RjwHiG4YSDyATg7BLQyzYRn4TvqmQWfqCpQcQEfgh4FgIbkty0Lo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]],
["dragon cannelloni"] = [[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]],
["arcadragon"] = [[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]],
["celestial pegasus"] = [[iVBORw0KGgoAAAANSUhEUgAAAUAAAAExCAMAAAA6MIv8AAABgFBMVEVxJJzq3fGfYrSiqs/UmOGiMNKOK55dEmyx0uJsHJzeZOKbJaOkXqrMOtWdZMV3S6GSLqZ0ma//AP+SL6hwG5AgBXKMn7laGG9wHJF3d3jlc+bFS7rloeWgT7AAAP+mp7KfWK769/vGNLinp9JmWqNaDnXLc8yjrMvemt4sBjaj0dbbmNsuAjukqMlmqKyryNhdEniqZtHNcst/f/+eJNSmNce1cMX/AACtyNd9APuwacKgNcSWnbgA//+dmLrXb7N7CRB6tcmkH3d///81CkZ2S5V2nax3nK8fdHR6SJQA/wCqVVX/f3/dpbjDjL05AKx//3//AH/JTrPAxNQAfwBvQHx/v8+DK3jMUrj//wAAAACKG652GpiRJrCsNct2GKuzd9GSVrOuZ8fQZ9HOd9WPSauoN7fseOXOWMzMhdSqV7mWNbHwhuz4mPb6p/quRceqx9m1WcStR7STuMyqLNGpJ7N8AHx1JJXkatjPRsnkdduEGpr4tveYxdW4g9DRldUSDg4KAAAAgHRSTlP3/vn6/P3zD/wS/BQP/vv+X/wBnl4E+/igAgr9GqIBDFsE/hgJXZ5hnv8WXAWXB6KkFl8CCKGmAVoCZl1iAaYTAv4HAv+gbKMDbAEDAhH/BAICp6QC/xD/WgEA/v7+/v7+/v7+/v79/v7+/vz+/v7+/v79/v7+Av3+/v7+/v79/nXJq3YAADUPSURBVHja7Z2JQxrZlv+LAgpZVMKiuGtMTF72pJd09/T2tnnzZt6b9bdeKISqooAqFkEBBYV/fc45t6ooUBM1GtNM3e4YO+lsn5zle849916BeeuTluAh8AB6AD2AHkBveQA9gB5AD6C3PIAeQA/grK1QNOQB/BR++CHa9QDecG2yeDIe8izwpivB4npbF5PxsAfwJviiLG7qerMpy0LIA3jt1eX88nk5J+ces5AH8Hrrq1A3buY5v7aZYWkP4PXsL7wD/PJN5Kc3TSH23gN4rfgXhvyRz5P94YdcyIuB15IvXRbPW/x05JdLsa4H8Fr6T7f9V0d+vczFWcQDeNGCfIH5A/gNZBAxOQS47Fng1fMHC2H+yCO/PPHrAcAQe+EBvNIKP4olMX8EiZ9J9tfrZV6seBZ4pfUoHLb4Yf4w93NEEEoRz4WvtFbCoSREv7xp6xebnyekrxb/QqEkxj/wXDnI8wc4sBBmng68Gr/vGfED6SKbzY/anwfw/Epi+wD5BYMufpd2VD2AU/qP8oeedfIv+C9UcZe3VD2ArvU9S3P/tfntE7/Hl/qvB3Bifc0gf2D7Cvjpec4vl/tA/PMATrRfvmZR4mfa/MiBL+2kegCn0m8U+OmW/eFHND5MIBcWcB7A6RWKsbjUzDeb5iCX1Tk/tL9cphv2AF6BH2NxHfnJA9B/yI9XcNgG9CzwKu0XKH+bTexcDcb1G2QRIRf6yA/1AEL6eM/iIuLLU/lh1x/7+/vCfubFzQF2v+r+z+i+sG7cRH5Y/jbd/K5ggJcDDNMPTcw+vyi5L3Xvc8DRHPvvviCk2OYNAYLxhaNR9tEf/5uPfqj+MHtA9ZsNNkn+yY4HC2HWvakFRuOSJCW73882wXAY1QvkDz2L7mvK+2P7g5UJf9QHLwb4KwtLIMl1M/nrTMfBMKkXCn8Dnj2yWXnMDwHeLAbiprKum7JuxmddvbQBX5uyL+5eZvdd+Pb3Ux/14EsAhhhVhXldl8MfLKV/y2szzKKkXqD4kN3ZwwEIKjr9aQCBYBLS1EyKP7CteHvCfR18HKCQu7yR/3GAcQ4QAuHHE9Fv0XlXGPYOePGRNZumlHOtfTmLADOhK/xMl2XhsKnr5MTmDJpg9y2qDHLfJu69Wb1n2/4AoCxjAPzqEwDi1gASNE0zvHnbBBMr3dV7lX4sHE8SPj3nzG7QGmQRXVbuZPeFcLd7c4Bdms1EEzQhEYdu+Y8QgwB0bzXO148A37dNu/Z1md8+ogPvzWY78DHD/o19igVGJeIHAKWr/VVc3f6g/FyPrezcj/KLQe7YaFvem3ObHyYOQEcU5X0htZn+FICJlbgNUL6xCa5c/I3hDXFD3Gaxe8D3PUvHN5otwjfAyVM9OyFdstms9VEIX81HLq+Fo6beQYKdfDLdTdzM0i70XxYTxWIhsM62PrtuBuuD2NeCf8Bvs4BPzk5JP1iUgvczV9S/l1ogiPQ8meARliPhm/yGd2OxCy0wtiGWxGok9lltMAE8QtsbzROSfllb+w3O8csGg+DBuas6nXB5l4yP+CNBKXoDgoCp4N9l50JdIsQ2jJKoFfbWQ58PXwwz70aTp94B4TMH50oPboAYAzPsUwFCnSNxKQ2GmIxe14nT7K/Fkhh4+vaRbXhbz3hIhIy00TKMqlbdi7G/fR58EM+iNj6IfVS55c7jk2WBAGYFEIGhTwSYCLNk3iH4w3XVdJc9KpWKheEP5KdbW1tI79nW7qvNlfS2oRhGvappP3weJw6HMXXwzKtnBcRHY89W40AYe68cDAYBY/byg0lXB4gdGTPvrOtm4gSkimKxUBius9gWZouVZ8928TveQxIuGS21AQT3VlY+Az/4q49a1oddZ5k3n+1FytkGSF/AgYVU99MB/seOnUZwBePXLYlDG0ZRVBQRjWz3u+9ez829fPbsuyeP2B82DENVa42atrfDVj8DP96zgtTL8enyRNlL/GRbxEAAFDKp1NWtRfjQr2xJQe7G11aDG4YoKu32t7s7r+cO5ubmzs7gyxJYI4RAVauVa3Xt3S+Ju65IwlQSoPPKg4Fsjq2vh/2q3D4JPwFcV85yfrJwrYT5oV05kIJ51/oH9vZ6AItggc2S6PfNzRE/AHj4YCvBtouGUqural1T3t5xqwd7VmYT7EDnurl5vulnxcCsvYQUBM3ubQBk4W7SDTB4ra5Cl22XikarXRr6yP4OznD9/sFujG2LADBSOYmU1Xd3a37fY1OkjQOTlnKRaFzjnHSxAEL0y2Zz4c307Vggb+y7CMYS1wD4iMUgDbdM0Yf4LH5nDx48e7v7o2i0aurJSaVW27vLLJLoUs8P/gw4MH5RzxldF5zXtj+508EmQveWXBi3DCZ8+IfryOkuZJFSyRD95L82wN8fvn792i8WW7XISaVSq0fusJzDeRcJ8OF5I+Bn544eb/ld4L7AD8q41O0BTKwylw8f5b9ZvY4JhliqBFIa2OHCEHh2eHiGMAGgESmfIMFq7A75hfG4Pj+vpTfN3pgfAhQEwRLPWfiMEwQDzArhzc3bAoidfbcL5795G01c5w8giqIf4J0hQQsgfO73D4uGBgBbrVr1zmRMGAcOaMlW4dEbey/Ck4Nke5h8HROUc73UNavWjwAc5+GjYPAIEvE14us/rfxZXPRbvmvxO5g78D/wg7xRy5VKpRWpvVu9kyjYDaF6yYP9mVmr6efws3VLkEPLyk4CllPh1HWL/g9PZyVCksuFIRFHrxEgQuyvi4t+mx4aIQI8XAJ+RUWrqwBQCzy9m+z7FYuXePibbJrmeLnBM4edOuwm4L5wg+6G8JFMMCFkjvLJa/wFPWLbAPCQrwML4NmhH0OgUq8BwIoa0bbZyh24L0uWqPKlgSH82OtZ+LLTuUM+6iA7QRaEVCgU7t4ywMkgiGr6qn9Lr35lfx4DpDgIHIEfAmzVtAoCrNWg1OveOr8oFG/8uBGoPzM7Dn6yW/ZZmQMBQiLJZDLhG7TePzZg2ZUnAQa/vuKf9xX743d+AOgyQfgUDdDvL4KMwRhYqZTrWuyWt027j+xGHKhn67ivFfyy3FnHupm0yxE1sITQzoub/HIfnVBNTpngN+GvE1fit/va54Mi5MEDP0HE7Isgl8gEWxEOEITMLW+ORHFDEc2P5iVd47pWvMtBAOQAOblxAXezERbhY3I4bk4CzCffX2G75RV79pqXwIdLD/xLS0uHZICHZIAFqETUGgeo1TZuFWCYxeLtpk63RbjUs2V/KJSd+HeEAG1vFsI3HIUUPtZYnixGgpBJ4uzrj/2sK+zZnI8DBN38ANaSH0Mg4htVCwoCpCSi1uobt7m5FMLw1242IfwJEP6cPbd9bmwdeezCMgfIv0PI3HSG6qMuHE666uGjYAQ+fHSH5I9bz+ZsgFAJLyFBgof8RpqmKQoCVFVVqze+vUULhOJXarYp/QpZfbzrYWk92eHnJBHaBKZNzM27AZjoTjQUjngieRT7iAG+RnI2wQMywUPw5MBoCACrBLAG/NRyHZTg1u3ZX4qmxWlgzZU+nEg32XwBoryRDwLm/U0ncYWP/52a+oQUPIKimIbDLl3P2Hdzh8iM92Eg+lkmCKWdGKhq1aoogu8iwX59dHv7w1HgZ5rU9JsYWLuAn9N9FiAmCsKNI+AVLHC8OWcjPLJ2SDYv6Zu9+un/+P0PIGscLh1ygkATMPoColgY1au0tGq9rvVr9QYAXL0tfnHTlGX4khvorn2P/Yv4WQBJQIdCn7C/+tEYmLauQJp0Y3urffNCB/5HsLdDTLwonYHg4YNDjIk+X4DsbwSrCgDrjdPGrQHkd/2BBYJSyeZx73fa/rLWtpGTRfBbMtevfq8JMDbZ2D864tk4ilMS0QvHNx6xv4B2eYBVB/YOIP360Zl9tJDcaBQIjBqEDz6/HYDdGJ8nw2GNiYE/Fz8hK7sAyqRpPnlvX/h4Yvs6mT9P8Juv48F8MN69oIrYZf94aMU/FNAonZf8NkBANwqcnvp8p4CvAaYYuJWdudCv1kwtHRZ07bvJsssAudFZALF7ijeKhbp3C5CHlrH7RoAgoMt/E+SlcfdCFz60NOAcpI5DP+A8OHAIBgL8M0R4Ggis73x6Egm9t9QWpl/dKX7B/rBHOnbgrBsg0MyEu3dugbQv2HES8dF8BEwwGESGlxB8BRZ4cIYRkFIIViIP/JzgARI89flsgvBfo+efrgO7wA/vmtSxepvgR60W2QY3YYHwOThw+O4Bpr8Ku334KBIENz6yAQZj3ycuUjHUvKcGIKQQ/wHVIkjR516IcuRfj30iQWw+B3EAheLfmN8+7xfsT0+uEb79VCqTuoVG0BWOu349tTl3FJwHNZiXOcFvppspKz/tvsT2s5+6f9SGmfMRQUBITuwADFBWebm680lRMERn9XUe//LmtHzZv2Dh9AZjL25jzvgKAKNTUhDi4DzYYCQSvLBD+Ir9CEXvA1pLZ1zIwFpaXAKCgcCUBZ6OAtUf2KfM+0Zp9AC3znOT9rd/Kb9cKkXHCG+jESlc6bc43dMCLw62LICgCd02+NMr9vPhA2stot1xgHNL4hAE9MhNEFLIqFqoVp+wR5/Ij3dfTOJnNZ+tvaKLAGboip3bOYl6NYDgw/K0lkEXDloEw+4cvPUXqtwwBCLDQyqJIfj5C8jv1A0QdEzVKAQKb2+aSDaBn+zYH28+93r2tu8lAD9yE8ztA0zEmDQJMM8zMWSSIO4XR109VgBIvntGjRjwYEvPHJCIHjV80wBFsap9u3Uzd+qGWFzOI0A8b2RVbz178CBnt1+sETYhg81AIZe6zXMbwtXCdFyX9Skfhg+gCOfn5yedeGcHLBBkzJnVSFiyCGItPKqO3AbYaICqriqlglZ98v9vEgXDIav80F38XOf1QaoI2K6ig0d4dDAlwMpE093PDJB1u5I52VgNcj0dJILfRLs7Y4C7L2kb3QL4AAke0HiCLzCsukLgKZQhAFArGZHqwk3EdDg65rdv8euNHRhy7ZG8P+4DCiHQO6lc73bPnwpXjNQpc6KrBeSOyIOBIEVB51jZH9mz1zTHwflBJUd1CBfSAbcPB0ZiFby6aqAJ7l5/dzNKV13RuWY8Lyhb9HJ88EDYJ8uzRw4odYTTIZz3vdWRxKtee7KZNOXprgzI6SNMJ0d5fezCW+wZ8Tuz7M7PGwsWQf/YhyEFc4Ci2apWX147CIZYLMnTR9Z1V6J1W4l7ZEhGfpIgJxkEzGTils8/X/nemDA4xBhehBIxSOr5I0rFUnQsA5+cnbkt0O+nnHxADZnAWAgGRr7Rv9arVU2USlq1sHVtftFknkYns3TXkDv6ATB7YAMn1jKCEE7KQTmehIQtRW93H/rqF+8kj1wmiOCwIpmPcJQm/LY2LQt8AhUcVCIHvBkNAJfEB1DNYW8LCZ46bZl/FavYXi2UJKMKSmblevzCUpN+K1ksfx1+gjVqJTsja1C0CUIc76OUTcCZv+Xju1cF2AW9JXdcFTEUI2h/8xGaUQzGQ4wfJfkKAR6eHS4t0S4wlsALC+IS7g5TKRxwDHBJFEUEqBmSVBheTwhCFSG12yhf8K61MT85mJ1cCBCgyggQzRE8PnUPSYTvEAfdURAt72gegqClB7+J4gWu3ALPEJxdjCyKhUJhKIq4JefuJfyrDbAqlgzx23++pgDMmLLe1umuK/18996OftRzoVFAyiNyviNnM7d6fPfKABOJqNTpTOYQzCLBLFkgFsVd1NMraIEPcBOEj3T4CWChIIrDITYTHAtEflXs7YOQKYrXmzEKswzuftDgfV7PTvLDTqk9d5XMYEJGgLQDghOAQjh9LxaIalqeUNNH2NnCkz0R+hoIpmMJtEAqhakNc4YAF4ulUqmgiGIBCFIWwTAYEAkgVsMgZMT16/WvUlweC7mL+HWcqTXpnxkQlAV+igZnAQUhdLvnx68OMBGNJmXZXc3NzyM5OViu5PPcBiE+/wt7xRsxh9wG/UuL4MVFsEBNAzscjUanp5hIRggQ/gvTiSZeCyDxMy1+cnay++LqQUPMS8YF10kkQUiFb5nfda6/i06bYCQyDwAXeFkHAOcX3sLv7qfNV39BA5xzTcMM0YU1VVWUqqbhRkjgdMQtcEQtQXF4DSEdRUmFKyfIjnzZ389OL9o3guwhW2NteAaJsdu+v+AaANPhNKlpyGWkCOeBoCWkESAWxd/gPh3UIn5rpBJ1DC0AqCFADT5Wq2h2JKHFKgHUCtWXsatns7CE+HB2Vz6/eT7OIJB7IQXz5EGDbHImbF1Kdz8A8dyIjJoVfl/cAuetTJznRXGECLJXK7t+PlLJpTSZoKhYAMEIq1UshFEBUn/wdKRVqyBjHl0xFEMBR0Ua6Gf5wuxLxoe6z27G8M6+nLuLK3CE6wXvpGytcTUXtGtjbFRDVfx+96snh0uc35xthEMRIGktRSsYSqBawKrYWiOwRTDK4cur7e+kLX5Y/8rOXWvyND8uYXgXxpqk3L/dNtbNACbC8gRBkjIEEByYPkmy2DP2xGHnWGBBA8FsqGCBxWEVkodYHS8NuA79u1f6LcRC1t8hNftcs1e0/2a7b9Dq5sv8EBJ8JQt4BDNxzwAtEzQdgtyBIZMcgQPP08TCLot9h6NtOJjv840BioaqGi0gCIIQ0weC0zQCqFgAN68SAG1+rgBIADtHYwvMy+M2gjVE1Auzu1nXvIQ2bAUgh2B+npvgEeZk3KPDbhY/mkkbwbYLDwtgf4oBQbBQhJzMLU8tcAMErFjLda8WhS1+FwVAp4HlDCSQWcqZFLhv90sAyHgKNF1xkC+a+ISvN57YR1up8iUj5GlYwWPWbUNRilCXaDSgpYhogxpaYKGw/fHNzTE/4UJ+vHcP+tmtBbPovoyFvgwLZN8DQXMyk/AkAjV7Fr4u+eeoGUMna3w+qN2IX6AgEsF2CQHawY8yclVpFRDgxydVo1SAdMwJAeMSgOOpFwIoO26cCYfv7FjytS3QlmETBIN4ZbUQ5Px+j/bn4yfkkCEl4WLRASgWaMIN0YHrQm5RNKUaKAyffIRgiEVlS8BkTXny3CofdLY+7XQku5ajZCzc5SWS17+IGwj2bIAdByDYBFYl/rnD33OAc2c8+mHPAIthA6phAGgCwCGWwLSfBDkZlaGmNBqFKlQjsQ/6r2X7WUzAru0j69YNOr1AosVuJljnt/ZT7A4vqLnBTeZQikrTBCOtYDOfX6CqAweyoJA7O3j98sn2oiiWisUifFEUBQG2ACAVcL4GWiAKbKWAWWU4/OD+etSxfLyiTp4+uC/sY1nu7uPjMCVujFzlLuPPC5CK+SwWmU5N0oygnl6ILODixdvrJ8/w/wXfLaIBIkDRaIEFQjTk4wmNAOiYEphgQSkUsSx++QEL7LLueQHDD65C0ZG15J5rGhBVYBDrDznD0ukvC6BN0GWDMm5z5oOthSAxLP4AGXV7ezvK4iXiVyqWDAIoGeTCHCAoQUPEBIIGGPD9HNu6bHe4+z22gkyegOWJBv6+o1rk/alxaBnJChkWZl8YQPCnjHwuDrpEzUKUPcK7bhbiYdGywBKYoA1wODwlFwaABfh+EWXNcOTz/3jZwP77bjqpk3zaFyb81zls7t4GyWb3Xedpcqk7vRnkhq85hNNjgrr7HFOQFyjJOM0UNvPROAVAYEgADQRYKIiQRMgAwQSlosF14Wj0c+yScd+0VYCYsjBw+A1kalY5kvlospsPtoe9mFzmbm9WuSHATRZOThMMWvMy+aPgkd0vzP9DqGQUuRsjwJYJSpr3VUcIUFWhPDG04RCssTAsXJKHu7ivzzsIORe/juwqOdyNVDwIhxPkAnZQ7/ga7Ju+JxK6QA7ySQU+v0oNQwTI4kaJLxugoRUMjawP+VVabfgvas5ohUtuI0uzDJ0AmayAJ4nJkx2ZPD/DmmJ3vW78IEsaCGatTOKMUB/xPc6joGWF8/lgOFwqcoAi2BoAFIuFYdEQsTWDh70qlbaiVX2nQ0BaffnokhZWrmdCDASrG5+ezl62Okf5ow7urWfxFsDQ5hcKEP1KdnLxkXtqBhEeBSPzNLn1DUu2OUCIfmtQDIvLqKyxs9UvH5ePK8cVQxNPT9EEQQru7lyU9N9Q82Df3UHYP2d8UpYKkA7+slYNkgqHv1gLxKvoU44TOwQtCwSC8xECmA/HAaBhFItQstWgbhN/97s/Cdx/y7V6OXJcWVMNKo9Ho6XABW3BLgst9yj4yePnKs7vgdiiACIIVcJ53IP7gl3YvbvoIuhEQbS/efi8Gd1WUUcXDZB8AZUA/m5ZpPAXqddrkUilokIeAfs79QX8FwD8N/aYT+0iv33nuYXxdS/W3RG8uQv4OnYTAQF2v2CAabcclPPuOJgPkgGivP5mQVMVbPlBjNNaLU38ExEEfifler0eQYItzCOorv0vz/8qmyGhZ5062ndf+Wyr5ay0f8GWEp7uz3yGS1o/6VWvbjScgd+pOYHQdmIgSGOYuupq3rdahcJwGQD+X+BXQYBlMsG2Bg4cAAt8ekEKeZwbX9tkJxB7o3d//wh8VZrKwbiFDuaXZi++bIDYmXHZoDXDCvVTkO9zBml+0A3QaCnVQHF5eVkCgJGIAxD8ezQCIxw9vWAXTshN8rOvXuNDL1l5sga24yGYX6L7hVsgBfiM7LSozTwdOAgiwDwOzuDoW7PMd99G1WpNbStKYCgWjJKqngDAGgXB44qqKQUfJOKCKK5OHT8IgQFOLWHMz5ployJE6jjKEIBC+kh/jnc8PvVhvk2L4JSkPhqvZqQP/PCMYSBSabeUQAH7MpoasQCiCUKErPp8GhJc/2ll+uef5sfJYbR1m16nczQGCAXw5ud5BuWTXzYkG6QWiZsguu7R/DwBbLZcCwo5pSouL7fJhTnAsoopBg9jQ023ztijrQm1mbsYIP4luQFKkmQdauXXeDL22wAIv9MXmdy+fG7HHYeP5smHx/iaCjVPAeByhbtwo14ul48R4BBrEdH/hO2+/s6dQ970pEmA03c3Te6p0/ekWGLzNwOQhbtgg46QJYIQjawdd7RAa7Va7aZaCADD5WVRsgDWEWBZpS1i3Nz0+V7Pzb1mO05BEspN8+O1jnwBPavjKsXZ5md7ruQ2HicNd1+kqMx3CFramkYwbQOE8NeGcq4qQjG3vAY5xAJYswAWChpFwrmDudc7Ky6AvfMGOCFY3PzgP+OpEAt/vucEb+V1126IpYRxJtF1+zMcW5BbilmkSk5RsKVQKBR/t6ycA1ig9kxh5AeAL9n/cgB2M+cAXmR3dAGqzLPvZ4t/twYQr3xw2yCffuQEg0HTascUcU8Y1vLy75bVtgsgZhFFjeDuHMhsIPhyd3xw50VG6l3MT+64bJBDlOUU+6RLTO4LIHUWxgSxahWg/qLUEjSXl4vWEsF7sY4zWh193koiZIEqmqeiGcoQAPoPXqbZT04W7vU+aICQkR2kg9Rnf8Pt1h5oxopLsgaXoWiAr3v80i852PvTsgB5Fz7872Wsg4tGW3cBhGoY+6pKW9UMozr0+/1n/q0VxwRTkjQF0Nn4dV8mYV3BFmK/VYBUMtCTHFbdJfesuhU8uocNBFp/EsCZc8sDSX94UuEuDKWIqoJCLBlayyiIQPDwwNkiToMFTgJ07hDL4T0w9P4Mb7/IN3o35ssBiJJayI39rSfYn++DPwvLgrC4uCgAP/hmEL162wZ4DPzUFnb8cexjuOQ/9B84XS3cOhhMuzDed8V3zZ25fDrbkLqHRxhv84317rjuH1f/9C2CWcLqYbkHH0y0QdNsVdRIuQarjNfgqTQ1oxiiz4e3e8A/T+yfM4NP0Jx/vWe8oUTihT79rQPEzYupwhWsDZhJpgVQWBT4lELJVFQo3iKRQEDlAJW2gfcJnp4ORwG/P3AAYfC9tW8gTwC0nqC5QEen0vfw2t+tAgSC6TcTZSv8i70roAYOjAAXSzQng3t0SiSgAcFWK4I5uGXQhYzUeBW1aiCA71mlec97cIEFntOCkEHes986QAhZ6ccuN6bkCwDNYgkD4DJ8IDWjlIoFpRAIaFpEM1rYsYZKBQBiONT6qgElSWCdxcD+BlwXDQYTMXBiE45OxMlSmH2f+O0DxCA0JijYAHslDhDcGAkuKGSIBSo/QP4BvlK7jXeqAkGtX6kc97Xqc/aCxQeWsBxI7gcwJyo47GHRO2bhe3kO/rYBss3QOBBC1pAwFUsS8gOCi2SCCwqVJAZ2Zvh4YKtlttECVbDAYwLY19R3q1F7736QkwYTpXDn6GjShTP39Q63cPs/ZYi9eGMDbDfb7bYulThA24GpqWUtTTMoiVAu6fePj48jlUq5XK/3j8vtjg1wMJh4gtDdQsAs3MuE2OwAZGnehkcHxkPROgDEatjit7AwAbBQMFoE8BjMrl8uA8GTyjEvUdZ03iGQB7JTjlAOHu9l0u6RUHh+b89w3wVAtgl13XIOgl+O+OmmBZDqYUWZAqi0yHmPOUGwwGO83bcBBCsAsEMGiF48GQQdhjmz4A88jc2SBXJF+AY8eAzQWQvnALYIILdA9OFyo96vAb96vfwQAXZk5Dc41w6ks5hyr+gH3ejbnTGA4FHpN5B+uQe7AU7jAwMEgMeWBZYh8tVOGzUEWC6XT2wDtGPgwLVxDt8mSUKBBoqheF6ZLYBggy8eL0trHCChIxfm/Aihn/PjAI/7ZIIArdYAgHXcLIlEwIehbHYZoGw3//ZzAp7SwWsECODLmQPIQgkWIoDSoGQgQGFRLIoFBKiU8B6KAPErtQwE2O/jF/BfAthoNPiG8QkABAPMIsAeHQumg9O9XnFI96cElpb8eD3IwctZc2HaKomKALAt5ah8KwrFBVEhgAsTANtQxB3j1hxYYYUAnhLA44ha0QfATxrXcjRc1FvkFznCF3woggD6Q7MHMMSiIsZAqUcGiAAXOEB89tUCuFDiRRwEP7RCVIANMsA6EK24APZ6PevWjUW/c6my7wD4PVg6A4BbswcwyuIkAwc9kU6LCKCgC0MOcFiASphuQynyNgK4bx/dmAOsY5uLACI/CXU0XiwmQNKlN3Kc22zRAh/AN/gPdmcXoNQrQvATwQLB8oaYQ0pogYEhAiwiQKxBKIVYAGmfBMriSktHfkQQAPZMQaDDZGcOwCfA78ESAly/pyxyhwD/wOJrSFCSUP6JxUXsY1HmpZDIRQwCbLfX1riMroCIqXMFgztNlVZbkqw0DKGPzkDNnf2eXriiw05Pd39GF0aAz9nWjAFMRNnGGlbCeokKOBFrOFv7OWIQvpEAoogpowuDAmzgTmeZZljbaptMEGRfrkjn8PB6ef8Bv8DH95z9SFkElPR/zRzAbuLXjRPyYQAo4gGwKQXNV4kKEZLRZHcYAkHBlGmIutIut7AOxh2jnuKnu6P81vVH+GV9ZwtkDO2i/Fdi1mJgDJLwGvmwQfyUC/kVioYNkOto8mCQgJrvVFNblg8DP6ndwtmGwrAwHI7onE7A9/TvLIYnaimt7LA/zhbAKNsG19TbettY4OsifrySc1oJVggEgFWfT1ErRluXOT9DbQHCtkEjcqpqGKNT8OB19jOdsAWA392PD98lwLgFsKUsnG8hOAANdy/GySGqhhOrmlpptnU8pNSoQaxstZr0FBh1D7XRCBPHjxygf/YAxth2BQDqUpvgoYi+0ADbtgcfTwBUAzhxWcYnTCEMtBsQEdsteopOVXGUQdX61afwi2z5rYf/Xs8YwC6L/icAbOuDtjauPvhVghDGeB1itRKgiLMsENswABAktVrFiVVwZmRYqRh0KqxiG2CkjP9vfZ2xrSUOcO71ymwBhByytoYAJaPAxTNWH7z8xUzAPy1ygNhHxUKkZvURcOg3ENDUcjkC0po/4QdeewyfRODfCOpFtNWnW2zrZ3wB6+xwbm6X/ftsWWC8gjJQkpQCem9JsTtY4hjgQgkBYi8BLVBdq/mgCKZKDvgRwDIv6o5Va8cJG/60adKH/+8UTDD28+ESAryvLHJXABPskdhuE0DgVLA6WH5eh4ALV6mSEznACu8GqmvlerVP8zK1gAWQWtN8/gh71eUyGKB6UrF8vfGcYRZBgIcA8NlMdaS3iyWpJ0mlEvVPRQTI+wfFIoZA/mkJgiA+cAhVcB/Y9MnGysivDgD7BBAtsg+6ukY7TeDetgPXA7Wnq5hFHvAgyLZ2ZsiF/2WjBQQFIEjZd4Ha0VYl7LQScMKj3W5Z2XUNAeJnEZyZcQCCRda1xin6bB2rFDBYDhawRtYxiywRwLln9+HDd5dE8IRraVEQBEv/KYrIP6HWDE/IeJFCu23itBssGk44qeBpHEMJBCIqL0zA6Go1n0/DNj8OBKPLcwOsj9b+zv795SEBPACAr2YG4Cr7QcE2aglHAoXFUsm1JedWgQoIQUPq9QihqWPQpBkjzUrCZT4D3K+dnmo0CwfBsHIcIcPs930NjYLgkh/v/j67lyB4VxYYWzBEaysJCPZw2rLX42eMTNO0blEoKhgDDfj+5cFA0uEbDENBfNyDjx2AWrkewGRtaUECWOsHTkcAcAWC4NKsAYwm3imiZXVohMDONAVn9ZwlmCWjKAjUMcDNTzwKRieLXUkYezTY7XcWWWC9X+5rVW0PHyPHfaUHZ3MvWWxWAMbYtwVxsbhQXFhAIxR66MWLzhqjLIE1IkByXmvTkwBWxwCh5sDeFuUZboARNEwNDFOrLq2zt4mXdN/y3OufVlZmA2AXPBglCtS/CBBJWcZYKo1BlqzIqJR6EvIr8bEjzbZAlSdbiHx022Wl0lQbIAFtgGCAWvV0+IS9ZU8gi7x+Ofd69x6yyJ0AjLJ3oFZErEAQIMQ+12jC1MJGTYkkt2EnmEDA9mCehBuno1FDa1WarToBhCSMkbHW0Kq+4Y9s99XOX/yHT569fPnsHlqCdwEw8dV79GDeshfFRcggzkGbCXgib1S3Su21SsVQ+MBCsYBPLyHACM8hNeo+F1onJyd4vomrGIiMdV+g2qj+zFZ22Y8PDp8wtnUPKuZOAMbYO7pUDBswyoIokBYEWLi1NLmoz6oYbQP7LYWhDbDg5BAEWAeADZ9iALy1E26BOD6oNUDFVLUhSOl/egUAN/9pZlr6Mban2UIPAOHhEBArorK4SJ1BUIMLi6KCm+zgvgtFAIiliMKLk4Wi3z90AayRBVbrUKfwNNKunEAMhOqu7hvh8cR1FnvF/nHpCZsZgDG2uqA5UhnzCEoUyBj0MEaxxMc8lAW+OQe5xqDxaI0DFIsBvjQnh0AM1FS1xhcAXDsBH671qWFYwPu23rNXSz/eRxlyNwBX2bbVOeUbmAtFU+jl8Ba80qJ1UgTSMc5qIcuSYBjY0QKABbu/gAP8BJByCHKKqNQbRE9Hf8csgioQ5I6It/+usJ9/nJ2N9SiLiQXNVa4VS1JuWeGKEIxwgU/KLBJSWi2sPhT+QxQUMxgEsZWAAHGDEwAaBrUX2wZWzBgE8duVel1ZiCVW2E9bszQbE1rfKFG1RoesAUnJ7PVQ0IiLAu1wWqNG4oICqQa+uwhgkN8QF3yFt3xUnUq4T1vEbWsZhkEAG6Su61VVWacCZHOGAD5i37ZKJV66UbFWKoGQWRCLC3jQAasTmpTBfU7cbEdD7OUkvDEB6Q2tO3qsJIz1Bs0otHUbIWhqRNun71AL9Mb4T2x2AHbDUMhhrm0ZPMzhDYzIi9cli0WUNCKeGSniZEehuAhpJldCD0YLrF4IsNW2LtEDEwSAfazltEYVfL96LyXw3WbhtwvUwld4v6qIF3Fj3QswufCjXU5+YoTPFxWF3kIAXDdAN/RUeSUc4U0XBKiobbNNpV+pZKAJopTWaqeAuer7eWVrZaYAvmU/FIY4AqhYugSiXEkat2BkmTe0itR8ITUI5TI//mAvalJHjglgHyjVIahKBLBoGG2VZ5F+HavmxlLsPk3wTixwL1AoIT2/NcCGhmPyLpaczQ4G/OARdlGt3uACCp0e9VXtpVtdK7LAQAM8uAf/q1EsEUAUMrXjPjUeAuuzBXCVxfYC6MH2xpFi8Ft88RqKnjy+a9K1zJKZExaADQ6+WDZoNZ4JoKYBQEGQBJy2NujaqDLl58ZIqwZ2Lrk8+TcKMAQy0CjimcJCYDgMKMWCdQ0yGGGvB7Y3ec8QHgSR0PqUAHUTigqN/0Yi6nGEC+l6DXMIZRCTchIK70gZ8otW9+GJ2XW2PksAuyvRjRKdD17EPyydrjYoE5dMCb1YGjPkNyXSzca9CK9EFhdAzOBYjNWMASur43n2kr0NUCQlGCElSAC11dmyQKyFcRh/AXffDLyFuwReTHGwZJqSICRTAtrhxOVXAJAcflhYLNgAeS+hrAXAAvfEMUAuZI45QOwnvJu5JLJtjM8UUrugZSgGL9tMetwy9PhNbjBx4DdXClQRIA7O4Lb7eEckgjpwddvGxy1QpXI4wF+22psxgCG20TKo3Wf3TaGiM4pW3btoPa4QeiygGdp2OGjVSf7RGRzXllKDRt0iCLAIapyEDN5CrZLE6dOdb3v3cF3MXQL8im2LijNLDhxLJaVgFSUAEN9HTtO5olBGcMxw0AqMB/iLuDFijSXgpqa2F4tRHgeILWpBAMAyB9jQtKczZoGJKJRyBdcOOt7RYRgghCEiiqkXVt0fxSPS4YxkMZRLtoubUD6X2mrZ2RVWIcqxjSJu31laumRVcwCwrlXXZyyJsEexb6fHeFstAAjBy4i53odK/wFcL5TKJMGVJZMrwBbfcMdtzONyn3RgGfPsyiOrIDSpuHZ8uK9qT3dWE7MF8C2bBqigBUJKNjY2J56nSHfRl0OpVFJSQPo5TUQN7+M5PuZnHsrlyCpEudg4DxfxiTqV9jY1tfb8PmXgHe2JbEPksyqKMUAJ/tzY/Jzu3ZArx0HzYPcG+1t0m0eLb/+eopR+ur7yaCW84UrEOBOHp5pw7uh5YnXGAGItguaGyy7NUBBKxsaF74N28XX7bdHZ+cQErhgVqkROT08bdez4rYT+yh+3ojRDN33wGImj5rPVjUET3FAsgIpd3RqYQS578odFE9uTXq+pNJhABAPr7O848vpnysO0DJFmzbGphUnklxkDGEUfttpSY4Ab25e/P4obUVNx0yIICJ9SkEt02V8XcVfF9uKKWtZqkEYCsyZjsKcPso2eDLFv34a1Efuwdjx3AMdYq9Bc79N1HuS6GBq4C6NttytAsK71A/Wn99mOuasBS1GC8kPTEB+mTGAYW/kAwRX2Q4Fa+uMLjeAHiSDznj6PORuWYXDjPy/iezgQXIFvRatVA3V08fUZA5hgGyU80oa3YrXabbwecPuD9dYKRM3JGKjRbYKNp4z984rLtNmjlZhYauPfC27Hg4lSjPxlxgCGdrbFlgoA8W7UFj4/ZXw4TOFQP755YydvAw8UKlXfSNxedf/IR6EwiCSpVUN1iO9oAECfb+YAJhIrG1IbDwTilWKVlqYZrYXYh0cHYg47iyDYIBS6YmRnUvikw4mY0KbLQ2v4K9QgyazH/jZTACFffgs5oIKNTxwqRUOEiguS8wdNcJIgH7TUWuq7cxkilJHaOKYFfzUttV+rrs9aFsbpLAhOEU1VxzfbadovoLC7oUvK1h08F2E5L69gqvUAIXx6DuBqdBun+dfWKq0SGOrzWdsXXmXrEfyT0wl+7mpqpF+uPV9d5XXKxWnnaxLfbalNtBWlehqAT+r1p+dSLNTFbYOOQ6iKsveO3WMdcncAI2W++mWtr6nU26ttbMTj0RBejXphHt4mA5RMAx89FJVqHfJIrdG4QCb/y7Z1nETFcyL3u+4GIJpevVYn88OWch+LsjJeoCAlo+zCemQ1EdtAgLoJEgX0jwoaUsV7oMACE5O2Gt0QASAe0a4Y2+uzCtC+wYkDpOb8yYmu67KQCSfSF1lgFLNIq22ia1YpctLG8DkXDiXbuv4QX4Oo6GZpY5slZgxgjK0Hyv36KS7ekz/G5mfjGAHyB8vC52xwp7u+Rw2IdrsFVQY9HEl23Jhq98VYGPA9fIgPJ57optmUYvcaBO8oBtY0DvCUH3Wj7nHlZD7PL51MXfRg3nO8VpoSN4JU19S+xW91qlER10/o3cmTebRoU1xNRGcL4Mr6zl5ZtQCe0q5Qv4z8bICyEDofBt/uVTUraePRGkDJDwVPA0yw+DxfYNAyENy4zz25u9GBq2yv7waI7lhXwQDn+a28Uu4xOxcFV0E79rU+/gsLjLFGN3g0AtMemk4+dACa4MMbLDprAFcS63tjgOWapuJdlCd54Kd3+CRH6Jwc3Nnr962s3e8f0+vD2E1t1PYmTDABOeQEXTiCACXZ3LjX4bY7qoVX2TuNZ2E6bIkZlW7z7XSs56p6QvqckH7Hj/HX6e5ANETaEan31V/cJgYiRtLnMQWfoAsDwFCXzSDAX/YCgTpeH0H7umrlIT66iQgtgLk33WkV85z370/5RpzWPyaAfbWy7TaxLgv36Hg7CJlmR+7oZpR1Zw4geuT66h5Fsz7ePnTysNMhgNY8YK/Xezz550aAtcY4c3OAjRr82I1fXEZGTwQ14WdqnjSb+Lq7GZu9JII8ol32TrVvGlp7OI8WKLtGK3vLk22FHbYaqTdciQciYa1Rj0DsFGMuH0aAOchDmH/xr0M337LvZ9ECV1ZX/19l7aRyAvUbGOD8fEfWx+9H4ks3oQkxmGDrezU3wL56XAN+lZOm/oPLh9GFe/hMlTQAeLJpSquMzSJACPb/iYcr8fanNcyag5ysZwfOy3O55TeTUuannWmAahkTRVNvb8QSsfHPGxZ6+H4m/CRN0IGmtNOdVYDADmIfMKDCAZiZsvN0H1jg48lyJAppmANsnPLjSSpJ73yzqcfd8TKU6ck9/ognqMD7loF3CPAPUqfz8OFJJHISgcpVR4DZMcDlx+eaCe/o1qfxTUUovSFyNqFaezt+KhKCoNTLWQDBheNsNi0QhHK805E6D+cBIgLsQNAaD+gL59qqf2Pv8EYiXszR+TgwQFDeYIBme3tMKYRvRdKtqgQwGb63U3J3DLD7azTZQYS4oIjTZdfjpZnQdDvhPYsmweUrlWN62EFVI/gIe1zWm3nw0+Sj8c/bpReHBHz81NTbb+/ZAO/wBsv/gJoBnRjfBHk430GAJn/LXkqlz/2xqcLQH+on/GqYkwqI75O9lKQ3df7o41j0xGKhJB0tARFTinUTswoQL+Lu2OvhALwOTAkfmuulWOhcO6vLQmSsAPBkTV9r6zokn72MrNNjz1LYJg6gk8kkSOlmpW3CZ2HGZhbgZvcPcfzDAhZdSj1OpZLJTObNcibMp3un12PQOPB/njgLarUcxjkZI13aAR3XeT8aFObGD9ux2OwC5OoEVzzOpUY6HcLnk8MXet1jOjvS0cFcIXVHIvMPTzoDboBJF6UXSUhK8yfYzTqB4tBMxmYZ4JhUN5ROO3n0wqyd6eUGg4FsufxDRAT1Xwf8N/6VK2R2JaufGgGRgx3pbRaaZQtkiUSi23W57GWiI7TMH9OVdY5QAjft6HnIFHEWDo1VYFi226kn/MGrGWyo3kw3LvMHdQdO4pk/GQhcKSfchmpatU0EDRQASjEPINmW/Sys5GRurJ+FFEu7jTacM+0kk+9ghwcAdrseQEwiFkB6wgZvz+8k37yBlB2acPpQj3J1HtIIr2vM5Ez2A2/iw2+Wl60HsWHFIXdHsVyZohPGI9vyQMjyRyNntqF6I4Kh0OMQYAR81lujUbYy7Z1hasRkBauq1nVp9V7eZf4SAVo6jziybrT7hy5Lp6frFQ5QNmUbYHJG21k3SSOhbsje/bhE2gHAqcsWzO379eAvzwLZ5ge6AwDQPAcw5AG8upHaLjy+7mPWa+HbXt1MridjM9Ck5hjUIR7Aa/Fz5CI+cyj3zO3Zbajepd7mZTN81YuxhAfwmnobBXeGF369N2nPhW8muHnpnIkxD+BNMYbDKRDcmx7A6wvFzfQX9Lv5zVogrF+7HsDf/vIAegA9gB5AD6C3PIAeQA+gB9BbHkAPoAfQA+gtD6AH0APoAfSWB9AD6AH0AHrLA+gB9AB6AL3lAfQAegA9gN7yAHoAPYAeQG95AD2AHkAPoLc8gB5AD6AH0FseQA+gB9AD6AH0lgfQA+gB9AB6ywPoAfQA/g9c/w3k0RoUDWgL/gAAAABJRU5ErkJggg==]],
["capitano moby"] = [[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]],
["la breakfast combinasion"] = [[iVBORw0KGgoAAAANSUhEUgAAAPAAAAFACAMAAAC1NgFhAAABgFBMVEWhaVojKhzcll/XaVqhl2Pdm5xiXlAlWhI1nQ3n2GGYWTFfNS1r0I6rzWHOYzeY0KpGzwxbWi6fmtiqlZ5cZJe1y93p69hxlFaQaZdTpx1IPFGhmzPYt+U7Ql4yM1XNnjg9zV3v4Kg8yAuENzTNe4ZgzHQ4mEunyDxynZCHPULSxjtxfsO1p9D46PD89vjp1/LTx+uGebN3dbDHttbx19CwprSpmslsZ5Q5ylTJuueNh7X35NiOicZXWIhuaHbny+3QxdX0uG6Wlcq3tuvb0uy7s9L7xXRybKenmbLpysl5dI2OhpNkXYqEeo+tquaZlLPOqLPyxrMDAwT3x4vTtrXErdDpqI/xtpPsuK7rqmh6grlLR1VXVG5IzGhkW2/61ZBPSWf217DSlnLpp1jVpo91cnrnucTTmYoJFgd7hcPV1dfPiHH75rNP0XGumJNBzFxwRDNS+AvQd2/pmo04OFDUpW+PfMTVw7nTl1GXk5j1tlvTd063tblN5wy0xcv65JOX85z+AAAAgHRSTlP//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////xUHpOoAAGo+SURBVHjavb2LQxpJtvjfEMDE7ExiyHt2Znb37vfevfc2AjaPpTHYIkQeIUAEQWF8EIyJZt2M0RgTZ+Zf/51HVXU14COZub+aiSL44NPn1HnVqWojFlvKZGKFSGT2jxmRSCRKYwEHfYrFYviIRyxmwSiaMOD5Ag14D8/zOO6YSzToBXgZ3hm+Bt9Lj9yRyWSsthVb4D+EfyC2sCD+ojbomZj7s/BjhkVfFqLwRiN/CG7E89cY2X0bC/p7jjEyXIQl8w7xMjAIgC7NkinGkhdX/Dj8gmg0EhUXdWECMQPLPwUvxaIG40YJ+Hcza7gusPoypr8Z933AZyB7/twEST5fWioiMEs4kykWl4r45FIsNgk5FqMLw1rEQ+MWuO4r+HeNmEcHfh+zkO/C2MWWf9r7LEtJDNZlfuwioUYvLZlFIWj8BhcYninK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]],
["burguro and fryuro"] = [[iVBORw0KGgoAAAANSUhEUgAAANAAAADzCAMAAADAQmjeAAABgFBMVEWaVyCmolre2qHgZlqaIBqnmDPSXSXirJzfMkVZIhbVDCHfnCAuJCNyUyev1ZKRYktjVEx50Emh2XPRx2rb5NX60TVryzdsrzivp5N1qFWKyTncimblusM+O0JAMkOyP0z+/v3ytm7nljXqplH0ulX4wlrRJizpqWbZm1X6xWntpDnWiC/omkz1x4z616zZlTTao1T71ZbYpmjOHCjzxjb659DLeSkMBAXkjDLuuofxyq366+j12crvuDbSNDH95LC0ZhXMikn89dZ4RS2xGBarWQ/Sm2Wu14d4x0bjKDK2JRW2dS6ESTC5JSfRSStuOSfIJRpQKBOyaSqJyUrviUyXyXLZs3Lsm2e2GyTIGhrHdhovGAxYNSdxxTnZozb503QUExFvOBWzh0nXt4t3ukjENxjOaC6RVS6zNRaMuE1tuja4dBj1vLGm1nmweUYwJBFUNBPlMzjWVzGmynfPhhnVtFLteUr700xRLCW2NSjzyciZeVCRZzLPqouD00srCQI7H/nlAAAAgHRSTlP//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////xUHpOoAAEAeSURBVHja7b2LWxPJEvAdQEDF27p7dvdc3vej05PMTOaaiQm5kZsQIVxFBEEFAQUvq6uul9Wj67/+VlX3TGaSQILnPMc95/lmXSDJZKZ/XdXV1dXVPbHJ/7Ej9v8D/eeObHW4+r8E1EjrTLezjf8VoMauojBF0dPVxv8GUFWZTjAlAUc6i/oHx383UFpREkxP6Mq0bpcmJxnTdSudTvdTwT8tUMPiKB7QusQuMiTkYduN/yagbGDWqhaIBJrQrn7NIgXEAwmV3eHsfwtQNq3r/t/DYOL0hKLrbDo9OVmyfCB4K13+7wCq7gKAYstXu2QQsBkpILUS84HgHGYHNfCnAmpko9JJTCgAZMkmogt5IAK8kw0BJZj/xWq6+icCaqTTIaIs1DzUPVOYAMoqPpCSFiYvANJ95qwO6tdp9b4ZkJ1OBOo1iTpF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]],
["pizza and ranch"] = [[iVBORw0KGgoAAAANSUhEUgAAAOEAAADhCAMAAAAJbSJIAAABgFBMVEVkYFGcLBippJdoWh8oJhacl1/d18rioamYUCCdcGjlY06biTdfimYtTCtTIRrS16Hejjo8ZEOyyaTcajNiO0PpiWTk0mjwrcSwdIbXeJa6wXmDPkO60cLGLS7JPUb+/fr854z559fzp2jsmFP42HX42Yr57OTv2cvzyG/zo1r4tnDRh0/65HpwNDP+8pPLeUzNSDXUlm356KpMd1P59dnNdzX2yIu1dk/tyK/KZzOyZy/KVzTvuI5RNi/likuyVyxPKCfpmmjXVkj21rTXlVPmV1DSqI00VTnXSkPOuKvVxrbMime0SCpySEjThDr+9KftuFeuakfSZ0hTRS9rLC7OuG3UxXKHSEjOplDSpnJvSDFpiGy0h2tNNhKrmE5KaU2LVk3UtZHStlZ0VjAxGBBah2O3dDI2JRLLOTSPd07uxFqUaEyKdzHV1cquplTUx4noqodIJxPoZlHzl7WpWRm1p26zKSfMmoevl488WEGQWDKul2yqRxmwhVWKZjG0Nydnsx/QAAAAgHRSTlP//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////xUHpOoAAEX7SURBVHja7Z2JXxrJtvgRREUTNclkZu5bfkBD0w2tQhNodhBBRgVxC0QMElFHY9xzNTpu+dd/55yqhsaoMblz35vM51US45rw7XPqbFV1ymT/uw/T/xH+RYbn/2T4dyLs2d/v8fwtCXuem81P3prevTOZ4M0701uzef/vQ9izb7a+ffWOhsn0FgZhvjX3/D0In5uB5hVyvWJv6SOQp+ntk+f7fwPC/bcgNdO733579+63p/Dnt6fd3d2/PXv3CkhN774mRtOPoKAgtndA9fQ3gPuND/bOU/j0254fmxAE+McfIMCnMH5rjT/+YH8Q0fRjE+6bQHaA9tRkIiLgYn9z0D/A4vzYhGbQzXd//IZQDLCTEhGf/dCEHvNTgII/73Q40lWUHAgVPwF//eAyREJ91vG5iIJDRvgUfubZ/o9NaHrG9NHE0NCG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]],
["la fuse machine"] = [[iVBORw0KGgoAAAANSUhEUgAAAUAAAAE6CAMAAABQ93s/AAABgFBMVEUhX50iHSUeNVtWXGYsWHBdmZ84kKyOqdJKXYk7rc+RzelBKzGPs7pLiuLZ1+IPPIlCa8RDQD1c0d3+/v5Sl9dKiM44ecdVpddbpOKq/f1lqeZqtujWxstv1+tNRUxXm+Hz5+wtKS5qx+owaLH02+OX9vmmmqtpptNMeLE2drdUttiQh5E1MzeK6PBShrNomc88g8lZt+Ovpa1Ge8fSvMPs1ttot9TS5/J14+5ZxuSWlqlSl65xZ25piLFIPERLWGoxV47Jtrttl7Xiy9FUVFjW1NgyR2pQZXBsx9ZKaJEwOEuJe4YqW6mHdHo2RVROdpDN2uppprXU9vqRtdEYFRdHNzuLqMmxxtY5hbiolZo4VXBYxNpGa6pnVVqXk5mw5+msus+3tLlShpVa1OcVRpM1ZZWwyeS31ulXpLFzd4mI2+owa8JqXGM7lsd0dXrDq7JjnOKOpbNli8mjjJOT1tmCbHNotLpy1NuTxtNyhI4nS4slK0QPCQyv1tqTjaNjfKpzu51UAAAAgHRSTlP//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////xUHpOoAAFyMSURBVHja7Z2LQxLZ2/i9dHHby/f7/pxhWEBAMWcAHRAUEkERlcQbKAXeMm1Ts8xbu621W/3rv+dyzsygVla279rbyQuCgfPhOee5nOc8T1P79/FFo+k7gu8AvwP8DvA7wO/jO8DvAL8D/A7wf2mkKzvb9Q0a2zh2KjjSjvEd4HvZTdY3qrWaHivEeOjwUWscR0dH6e8A3zPeHCE5XdeZ3ntGpvId4HtG/SimezyegHJ4GDv0iIH3eLweIOfxEMCF7xL4XoAZED7dI+ZvTPOcM4Dg/2mAwfYgfohxBiASjNEMVmAwMkXRYHi83v/bAIM+30Ai0ZPpWV/vge/ik8bmxubm5saGz5fIFGARLBQKuRwvhhoD9LhhED53wPN/EeDkJuCK7kdp7O5Gz4yZ7B7eu555m8PxKkcEURgRoGpP4IDi0TPnAyR5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]],
["cash or card"] = [[iVBORw0KGgoAAAANSUhEUgAAAOEAAADhCAMAAAAJbSJIAAABgFBMVEUuVxJNYidda1Kcp5GnqCBykWEbNQ/O1Tqmq1+ezzDOsFnHtZzb88i62KWEfoHZ6GDu652cxV5diCi+vcP+/v4XFhYKCQmNuCuXxTC12EimyTWr0zgnJSXw+9PF5E8gGxzt5uipyUmHqiyKtRx3phc3NTXNx8d4qCnq2NKVt0pJRkdqZ2fY19O74kqxyG/t5tJumRPY57CLh4hxmC6GqxnD20yqpabn97SMqUzlyU18sypYVlaZlZZ4dXS3tbTS2K8jHSDx2LOnulCzyYu51W3TxTaZxUbH15DR5pKquTCpuWzm6LTHuLfE2W1oii7my9Dx1pbv2uiZtm5COzmCe3nSuFMcGSK51Ip4lUrXxU/Jx44jIhvOuy/Nx7bb9LJ7sxoTJwZJZjTnyIuimpmuuopShwyQp2zq00+3yKhiW1nkxWVUdy7RvcSIm1DRxHDa6MiOwhzY9ZdalAnG5WxFPkBpZllphU6Ig3SGmW6ppZm54Tzoy7I3VipoiRl7okSImi8/XvJYAAAAgHRSTlP//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////xUHpOoAACLWSURBVHja7Z2JX9rK9sBdur7e9f1gEkIiJCSEJKwBA5XNohVXequ2tVqtVru97rf7vV3+9d85MwmLoqDXfn7t+zGtEJKo+eacOdvMxCHff3sbGhAOCAeEA8IB4YBwQDggHBAOCAeEA8IB4YBwQDggHBAOCAeEA8IB4YBwQDggHBAOCAeEA8IB4YBwQDggHBAOCAeEA8L/ZkIJ2kIGmrSQgq0UbmZSdM+hLZWCE/JwjvT9E0qZKbfV61NJ+JpOTk9PJ5NJ+oJNhpZsNTkQkN132Kjnpe+bUMrXk4ZRk5FqaUmu1YAmgJc+NyfQd2hzgiDgbnzHFgwKwhzHcbDJcfLsd00oSfnZpWlAGocWWBpndONj4xQtEGCMyIdbgrsvGAxScngXlEL9eyZEAcqB1+NjrKHQ8J2CAeQYUNPNcXYGIw4k/vqLbeAu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]],
["cangurato gelato"] = [[iVBORw0KGgoAAAANSUhEUgAAAOEAAADhCAMAAAAJbSJIAAABgFBMVEXsnaffX5vq2mpY2dnckl5ZVm0f3uDg3efkps+h3qO0UR7hmjIlJivaV2OooKZg3qrXYyfpMZye4Nvc4p/v4SEntc6srMnQK3ChaZupXVlll6Qjoq2tKGJXs82lmWdjY48yNEys3m4uUWHtZ9anNRkr0LJNN1ZTMSVgVTArd4suSSK5M5VyjmG6jinOOCxc3H0DhH881XpkoTm+bsfsOcj+/v7zl0zyWLQy1+j6pVLSZy/siEn7Zsb4x5P62KvXdjPphjftSKnmeTb75bQy5OvnOJfKWSn0qGwtyNX0ZLj5tm726fHteYb7udHxuYnWN48v1tjoRZjoekn61Zbodnb55jKMiKj76MspKC12d5L25kz52DPZZ27XRZPzhI1I2OvXd0jxlTn4xdH22Mwxy+b3Wce4VylJ5u72yaz6dc30d60JBgn55o/QV1OWlbD410zlaHKLhpfXKomtp7T3yE/zyDH79tFuaYkUFRTNxtHUZk3UWWnymWn3tVOGepXJVhq+KQGfAAAAgHRSTlP//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////xUHpOoAAED+SURBVHja7b2HXyJbtuhfkSJIEBAB29TpnDPpvl+ggCqhAJUi2EQRBREQAwZUjK2i/utvrV2F3dMzc2e6z0DPu5+32wCmri8r77CKCvy+cRsY38jiB0F//5cHFfifPv6PI9QEKfxPJewIRiNFUePS0mpn3IC7FAIeT1upcRDeRsLqmBGzO2vHxmN6ulhcGz1hJxqOJWKZ6nh1dL1ktU5PTx8f059GTRjNcG1RbMdErjtOr5h8cZinp6308feY4o8Q3nI+AAyLMRjy7wmIt//0lwWX06n/bPbTw8tLS3oPhBR9/GmUhFVVBvmFw2IbGEVqVA6nGqi6bK45k0sV1WiU4lrm1oPjJfl+ukivgT8dJWE3FguHw5awKIpyTGyJXGcYpn40vP29r7cOSlbpRZa5dqwdk6SYI+FISAkp6XtvPQYZHo9WhmCD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]],
["yetimatic"] = [[iVBORw0KGgoAAAANSUhEUgAAAOEAAADhCAMAAAAJbSJIAAABgFBMVEUnViUyYpmp2udYaGJpm9UaKWNnm2MsYGBlmqDb8s1SZpnK5rWq3p4WGB8fN5pvydqkrZiNmNeSUGWDfIpVx2xty5dPdMmFk3Mya8RGZTOPxXrLR2hPMzBjNEolPclShT09h6TbPF/BveE8icWsPWc+t1j9/f3v6O0pKDTS1+wzNUfNyNHl3OPY1NkXGSbk2NuxuNAvMzoUFRnW5Pa2x+nGyukvLUK1xdZHRlYJCRIZJC+Pl7Gvuuarp7GUps2nq8siHCrEvMhTVme1tLm21fBzh62OmcmQprWVt9E3RFFQdYxpZ29QaIyLiJNNTGPW9PtveIyq1pZ2lrCPlZaVuIyXx4lSVFmy2KkXNUyKtnemyZRCPE3FuLuRxdQySWtthpSStLV2pmu45auauOhIdjZQhY9MZ3VzprHG6LFWh0mNqYl2l86jnKkVKE4YNjBse6qHi7Bpl1aHp3Xq4t1yuM02VHIiFxetxqqWx+XL6MstRcp2mWpzdHaTqOgtRrE4WocNM3vzAAAAgHRSTlP//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////xUHpOoAADZKSURBVHja7X2Jf9NI8q8Th5ycw87Mzu7s9Xu/J7ndki1bcmRblu8rF3FucpMQQhICJGEYYLj+9VdV3ZJlE27CevfzmuA7Tn9V1XV1VXVI+W8foe/1h9TA+O9E2A33vwzhOYi+Gy1D/38dXhRV/+sRCkb9r0D43WXnv1NbfHfy/X9JczFKv2shqv/ZCNVu1lQD/InwvscavXCEbUNNVTV4EBegCJ6ua/+ZCNUAwjhCIojwWOecx+OqfEdTOQ8ivCB6hi50sSHZ9LgE2DUEwvcv0v8UhMCKmoew8wMagOdqF0f/pyD0HwJHqlzHBYdr0CergKzr8tHFSpzQBQoXQBjXFECklSolt6QLFNx13RLXNIKnMbXjl3ofoZwozl8QkdNzROWtOWa4boUTQMakYFUl4IuAeKEI4bnOUXYC0ri/DHUYxJoal2RV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]],
}
local function NormalizeBrainrotName(name)
return string.lower(tostring(name or ""))
:gsub("<[^>]->", "")
:gsub("&lt;", "<"):gsub("&gt;", ">"):gsub("&amp;", "&")
:gsub("[^%w%s]", " ")
:gsub("%s+", " ")
:gsub("^%s+", "")
:gsub("%s+$", "")
end
local function GetEmbeddedBrainrotImageBytes(spawnName)
local key = NormalizeBrainrotName(spawnName)
local encoded = EMBEDDED_BRAINROT_IMAGES_B64[key]
if encoded then
return Base64Decode(encoded), "png", "image/png", false
end
return IMAGE_NOT_FOUND_BYTES, "png", "image/png", true
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
return GetEmbeddedBrainrotImageBytes(spawnName)
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
if spawnName == "" then return end
if playerName == "" then playerName = "Unknown" end
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
local textPayload = MakeWebhookPayload(
spawnName,
playerName,
state.count,
nil,
state.redeemed_at,
nil
)
if state.message_id then
local updateOk = DoWebhookRequest(requester, {
Url = DISCORD_WEBHOOK .. "/messages/" .. tostring(state.message_id),
Method = "PATCH",
Headers = { ["Content-Type"] = "application/json" },
Body = HttpService:JSONEncode(textPayload)
})
if updateOk then
AddLog("Updated: " .. spawnName)
return
end
state.message_id = nil
end
local sendOk, sendResponse, sendErr = DoWebhookRequest(requester, {
Url = DISCORD_WEBHOOK .. "?wait=true",
Method = "POST",
Headers = { ["Content-Type"] = "application/json" },
Body = HttpService:JSONEncode(textPayload)
})
if not sendOk then
AddLog("Discord failed: " .. tostring(sendErr))
state.count = math.max(0, state.count - 1)
return
end
local responseBody = sendResponse and (sendResponse.Body or sendResponse.body) or ""
if type(responseBody) == "string" and responseBody ~= "" then
pcall(function()
local decoded = HttpService:JSONDecode(responseBody)
if decoded and decoded.id then
state.message_id = tostring(decoded.id)
end
end)
end
AddLog("Sent: " .. spawnName)
task.spawn(function()
local imageBytes, ext, mime = GetBestSpawnImageBytes(spawnName)
ext = tostring(ext or "png")
mime = tostring(mime or "image/png")
local filename = "brainrot." .. ext
local attachmentPayload = {
username = WEBHOOK_USERNAME,
avatar_url = CODE_SNIPER_AVATAR,
embeds = {
{
image = { url = "attachment://" .. filename },
footer = { text = "FTX Sniper" }
}
},
attachments = {
{
id = 0,
filename = filename
}
}
}
local multipartBody, contentType = BuildMultipartBody(
attachmentPayload,
imageBytes,
filename,
mime
)
local uploadOk = select(1, DoWebhookRequest(requester, {
Url = DISCORD_WEBHOOK .. "?wait=true",
Method = "POST",
Headers = { ["Content-Type"] = contentType },
Body = multipartBody
}))
if not uploadOk then
local ok, response = pcall(function()
return requester({
url = DISCORD_WEBHOOK .. "?wait=true",
method = "POST",
headers = { ["Content-Type"] = contentType },
body = multipartBody
})
end)
if ok and response then
local status = tonumber(response.StatusCode or response.Status or response.status_code or response.status or 0)
uploadOk = status == 0 or (status >= 200 and status < 300)
end
end
if not uploadOk then
local displayUrl = curatedUrl
if not displayUrl then
pcall(function()
displayUrl = GetSpawnImageUrl(spawnName)
end)
end
if not displayUrl or displayUrl == "" then
displayUrl = IMAGE_NOT_FOUND_URL
end
local fallbackPayload = {
username = WEBHOOK_USERNAME,
avatar_url = CODE_SNIPER_AVATAR,
embeds = {
{
image = { url = displayUrl },
footer = { text = "FTX Sniper" }
}
}
}
local fallbackOk = select(1, DoWebhookRequest(requester, {
Url = DISCORD_WEBHOOK,
Method = "POST",
Headers = { ["Content-Type"] = "application/json" },
Body = HttpService:JSONEncode(fallbackPayload)
}))
if not fallbackOk then
AddLog("Image send failed")
end
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
local t = tostring(rawText or "")
t = t:gsub("<[^>]->", "")
t = t:gsub("&lt;", "<"):gsub("&gt;", ">"):gsub("&amp;", "&")
t = t:gsub("^%s+",""):gsub("%s+$","")
local name =
t:match("^%((.-)%)%s+[Ss][Pp][Aa][Ww][Nn][Ee][Dd]")
or t:match("^(.-)%s+[Hh][Aa][Ss]%s+[Ss][Pp][Aa][Ww][Nn][Ee][Dd]")
or t:match("^(.-)%s+[Ss][Pp][Aa][Ww][Nn][Ee][Dd]")
if not name then return nil end
name = tostring(name)
:gsub("<[^>]->", "")
:gsub("^%s+","")
:gsub("%s+$","")
:gsub("^%c","")
:gsub("%c$","")
local firstChar = string.sub(name, 1, 1)
if firstChar == "\"" or firstChar == "'" then
name = string.sub(name, 2)
end
local lastChar = string.sub(name, -1)
if lastChar == "\"" or lastChar == "'" then
name = string.sub(name, 1, -2)
end
name = name:gsub("^%s+",""):gsub("%s+$","")
return name ~= "" and name or nil
end
local function IsBottomGreenSpawnText(obj)
if not obj or not (
obj:IsA("TextLabel")
or obj:IsA("TextButton")
or obj:IsA("TextBox")
) then
return false
end
if obj:FindFirstAncestorWhichIsA("BillboardGui")
or obj:FindFirstAncestorWhichIsA("SurfaceGui")
or obj:FindFirstAncestorWhichIsA("ViewportFrame") then
return false
end
if Gui and obj:IsDescendantOf(Gui) then
return false
end
if not IsVisible(obj) then
return false
end
local cam = workspace.CurrentCamera
if not cam then
return false
end
local pos = obj.AbsolutePosition
local size = obj.AbsoluteSize
local vp = cam.ViewportSize
if size.X <= 0 or size.Y <= 0 then
return false
end
local left = pos.X
local right = pos.X + size.X
local top = pos.Y
local bottom = pos.Y + size.Y
if right <= 0 or left >= vp.X or bottom <= 0 or top >= vp.Y then
return false
end
local centerY = pos.Y + size.Y / 2
if centerY < vp.Y * 0.40 then
return false
end
return ExtractSpawnName(tostring(obj.Text or "")) ~= nil
end
local SpawnSeenText = {}
local SpawnSeenVisible = {}
local function HandleSpawnResult(obj)
if not (obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox")) then return end
if not IsVisible(obj) then
SpawnSeenVisible[obj] = false
SpawnSeenText[obj] = nil
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
if SpawnSeenVisible[obj] and SpawnSeenText[obj] == normalized then
return
end
SpawnSeenVisible[obj] = true
SpawnSeenText[obj] = normalized
local recipientName = Player.Name
AddLog("Spawn: " .. spawnName .. " • " .. recipientName)
SendOrUpdateSpawnWebhook(spawnName, recipientName)
end
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
local function DirectWrite()
local ok = pcall(function()
box.Text = finalText
box.CursorPosition = #finalText + 1
box.SelectionStart = -1
end)
return ok and tostring(box.Text) == finalText
end
local wrote = DirectWrite()
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
DirectWrite()
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
return fired
end
local function SpamSubmit()
for _ = 1, 10 do
ClickSubmit()
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
local triggerPhrase, triggerA, triggerB = FindTrigger(text)
if triggerPhrase then
local remainder = text:sub(triggerB + 1):gsub("^[%s:%-=%.]+", "")
if remainder == "" or remainder == "..." or remainder == "…" then
return
end
text = remainder
if IsBadText(text) then return end
end
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
local typed = TypeIntoCodeBox()
if typed then
for _ = 1, 3 do
ClickSubmit()
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
table.insert(CurrentMessages, text)
AddLog("Code part: " .. text)
local count = #CurrentMessages
Status.Text = "Captured " .. count .. "/" .. SubmitAfter .. " message(s)"
Status.TextColor3 = GREEN
TypeIntoCodeBox()
if AfterSubmitEnabled and count >= SubmitAfter then
Submitting = true
Status.Text = "AUTO REDEEMING..."
Status.TextColor3 = GREEN
AddLog("Redeeming " .. tostring(count) .. " part(s)")
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
local remaining = text:sub(b + 1):gsub("^[%s:%-=%.]+", "")
if remaining ~= "" and remaining ~= "..." and remaining ~= "…" then
AddCode(remaining)
end
return
end
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
end
local SpawnVisibleState = {}
local function Hook(obj)
if not obj:IsA("TextLabel") or Hooked[obj] or not IsScreenUI(obj) then
return
end
Hooked[obj] = true
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
LastText[obj] = ""
SpawnVisibleState[obj] = false
task.defer(function()
HandlePopup(obj)
HandleSmartInvalid(obj)
HandleSpawnResult(obj)
end)
else
LastText[obj] = ""
SpawnVisibleState[obj] = false
SpawnSeenVisible[obj] = false
SpawnSeenText[obj] = nil
end
end)
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
Hook(obj)
UpdateDetected()
end)
end)
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
task.wait(0.03)
end
end)
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
task.spawn(function()
for i = 1, 12 do
LoadingBar.Size = UDim2.new(i/12,0,1,0)
LoadingCard.Rotation = math.sin(i/2) * 0.35
task.wait()
end
LoadingCard.Rotation = 0
Loading.Visible = false
end)
print("CodeSniper V62 loaded - compact instant FPS build")
end
StartCodeSniper()
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
