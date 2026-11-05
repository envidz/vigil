-- Vigil (built from src/vigil.lua)
local ENV = (typeof(getgenv) == "function" and getgenv()) or _G
if ENV.Vigil and ENV.Vigil.Unload then
pcall(ENV.Vigil.Unload)
end
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local GuiService = game:GetService("GuiService")
local LocalPlayer = Players.LocalPlayer
local Tokens = {
space = { xs = 4, sm = 8, md = 12, lg = 16 },
radius = { sm = 5, md = 7, lg = 10 },
text = { body = 15, small = 13, title = 17 },
size = { rail = 56, header = 48, row = 40, control = 28, window = Vector2.new(780, 480) },
stroke = 1,
motion = 0.14,
tooltipDelay = 0.4,
font = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Medium),
fontStrong = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Bold),
mono = Font.new("rbxasset://fonts/families/RobotoMono.json", Enum.FontWeight.Regular),
}
local Themes = {
Dark = {
bg = Color3.fromRGB(22, 22, 25),
surface = Color3.fromRGB(29, 29, 33),
raised = Color3.fromRGB(42, 42, 47),
hover = Color3.fromRGB(52, 52, 58),
border = Color3.fromRGB(50, 50, 56),
text = Color3.fromRGB(236, 236, 240),
muted = Color3.fromRGB(158, 158, 168),
knob = Color3.fromRGB(200, 200, 208),
onAccent = Color3.fromRGB(255, 255, 255),
danger = Color3.fromRGB(238, 92, 92),
shadow = 0.55,
},
Light = {
bg = Color3.fromRGB(250, 250, 251),
surface = Color3.fromRGB(241, 241, 244),
raised = Color3.fromRGB(226, 226, 231),
hover = Color3.fromRGB(214, 214, 220),
border = Color3.fromRGB(218, 218, 224),
text = Color3.fromRGB(24, 24, 28),
muted = Color3.fromRGB(96, 96, 108),
knob = Color3.fromRGB(255, 255, 255),
onAccent = Color3.fromRGB(255, 255, 255),
danger = Color3.fromRGB(204, 54, 54),
shadow = 0.8,
},
}
local Accents = {
{ "Blue", Color3.fromRGB(77, 139, 255) },
{ "Violet", Color3.fromRGB(140, 110, 255) },
{ "Green", Color3.fromRGB(52, 178, 110) },
{ "Amber", Color3.fromRGB(226, 152, 40) },
{ "Rose", Color3.fromRGB(232, 80, 120) },
}
local EspColours = {
{ "White", Color3.fromRGB(240, 240, 240) },
{ "Red", Color3.fromRGB(255, 85, 85) },
{ "Amber", Color3.fromRGB(255, 190, 70) },
{ "Green", Color3.fromRGB(80, 220, 130) },
{ "Cyan", Color3.fromRGB(70, 200, 255) },
{ "Violet", Color3.fromRGB(170, 120, 255) },
}
local World = { -- colours drawn over the game world, theme-independent
outline = Color3.new(0, 0, 0),
label = Color3.fromRGB(245, 245, 245),
labelMuted = Color3.fromRGB(200, 200, 205),
healthLow = Color3.fromRGB(235, 70, 70),
healthHigh = Color3.fromRGB(80, 220, 120),
}
local SAVE_FILE = "Vigil.json"
local Settings = {
enabled = true,
boxes = true,
names = true,
distance = true,
health = true,
tracers = false,
highlight = false,
teamCheck = true,
teamColour = false,
maxDistance = 2000,
textSize = 14,
espColour = 1,
tracerOrigin = "Bottom",
boxStyle = "Corners",
boxFill = false,
skeleton = false,
item = true,
arrows = true,
visCheck = false,
bodySource = "Auto",
aimEnabled = false,
aimKey = "MouseButton2",
aimMode = "Hold",
aimPart = "Head",
aimPriority = "Crosshair",
aimTeamCheck = true,
visibleOnly = false,
stickyTarget = true,
aimMaxDistance = 1000,
fov = 120,
showFov = true,
smoothing = 4,
prediction = 0,
aimMethod = "Camera",
silentEnabled = false,
silentPart = "Head",
hitChance = 100,
silentTeamCheck = true,
silentVisibleOnly = false,
silentMaxDistance = 1000,
silentFov = 150,
showSilentFov = true,
showSilentTarget = true,
silentRaycast = true,
silentMouse = true,
silentCameraRays = false,
fullbright = false,
noFog = false,
lockTime = false,
timeOfDay = 14,
camFovEnabled = false,
camFov = 90,
crosshair = false,
crosshairSize = 8,
crosshairGap = 4,
speedEnabled = false,
walkSpeed = 32,
jumpEnabled = false,
jumpPower = 75,
infiniteJump = false,
fly = false,
flyKey = "F",
flySpeed = 60,
noclip = false,
clickTp = false,
showModules = true,
theme = "Dark",
accent = 1,
menuKey = "RightShift",
}
local canSave = typeof(writefile) == "function" and typeof(readfile) == "function" and typeof(isfile) == "function"
if canSave then
pcall(function()
if isfile(SAVE_FILE) then
local data = HttpService:JSONDecode(readfile(SAVE_FILE))
for k, v in pairs(data) do
if Settings[k] ~= nil and typeof(v) == typeof(Settings[k]) then
Settings[k] = v
end
end
end
end)
if not pcall(function() return Enum.KeyCode[Settings.menuKey] end) then
Settings.menuKey = "RightShift"
end
if not Themes[Settings.theme] then Settings.theme = "Dark" end
if not Accents[Settings.accent] then Settings.accent = 1 end
if not EspColours[Settings.espColour] then Settings.espColour = 1 end
end
local saveQueued = false
local function save()
if not canSave or saveQueued then return end
saveQueued = true
task.delay(0.5, function()
saveQueued = false
pcall(writefile, SAVE_FILE, HttpService:JSONEncode(Settings))
end)
end
local connections = {}
local function connect(signal, fn)
local c = signal:Connect(fn)
table.insert(connections, c)
return c
end
local function new(class, props, children)
local inst = Instance.new(class)
local parent
for k, v in pairs(props or {}) do
if k == "Parent" then parent = v else inst[k] = v end
end
for _, child in ipairs(children or {}) do
child.Parent = inst
end
if parent then inst.Parent = parent end
return inst
end
local function round(r)
return new("UICorner", { CornerRadius = r == "full" and UDim.new(1, 0) or UDim.new(0, r) })
end
local function padding(t, r, b, l)
return new("UIPadding", {
PaddingTop = UDim.new(0, t), PaddingRight = UDim.new(0, r or t),
PaddingBottom = UDim.new(0, b or t), PaddingLeft = UDim.new(0, l or r or t),
})
end
local reducedMotion = false
pcall(function() reducedMotion = GuiService.ReducedMotionEnabled end)
local function tween(inst, props, duration)
local d = reducedMotion and 0 or (duration or Tokens.motion)
if d == 0 then
for k, v in pairs(props) do inst[k] = v end
return
end
TweenService:Create(inst, TweenInfo.new(d, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
end
local function prettyKey(name)
return (name:gsub("(%l)(%u)", "%1 %2"):gsub("(%a)(%d)", "%1 %2"))
end
local MouseBinds = { MouseButton1 = "Left mouse", MouseButton2 = "Right mouse", MouseButton3 = "Middle mouse" }
local function bindName(name)
return MouseBinds[name] or prettyKey(name)
end
local function bindValid(name, allowMouse)
if MouseBinds[name] then return allowMouse == true end
return (pcall(function() return Enum.KeyCode[name] end))
end
local function isBindDown(name)
if MouseBinds[name] then
return UserInputService:IsMouseButtonPressed(Enum.UserInputType[name])
end
local ok, code = pcall(function() return Enum.KeyCode[name] end)
return ok and UserInputService:IsKeyDown(code)
end
local function inputName(input)
if input.UserInputType == Enum.UserInputType.Keyboard then return input.KeyCode.Name end
if MouseBinds[input.UserInputType.Name] then return input.UserInputType.Name end
end
local function isPointer(input)
return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
end
local P -- active palette
local themed, refreshers = {}, {}
local function buildPalette()
local p = table.clone(Themes[Settings.theme])
p.accent = Accents[Settings.accent][2]
return p
end
P = buildPalette()
local function bind(inst, prop, token)
table.insert(themed, { inst, prop, token })
inst[prop] = P[token]
return inst
end
local function onTheme(fn)
table.insert(refreshers, fn)
fn()
end
local function applyTheme()
P = buildPalette()
for _, b in ipairs(themed) do
b[1][b[2]] = P[b[3]]
end
for _, fn in ipairs(refreshers) do
fn()
end
end
local function guiParent()
if typeof(gethui) == "function" then
local ok, h = pcall(gethui)
if ok and h then return h end
end
local ok, core = pcall(function()
local cg = game:GetService("CoreGui")
local probe = Instance.new("Folder")
probe.Parent = cg
probe:Destroy()
return cg
end)
if ok and core then return core end
return LocalPlayer:WaitForChild("PlayerGui")
end
local ROOT = guiParent()
local espGui = new("ScreenGui", {
Name = "VigilESP", ResetOnSpawn = false, IgnoreGuiInset = true,
ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 9000, Parent = ROOT,
})
local highlightFolder = new("Folder", { Name = "VigilHighlights", Parent = ROOT })
local menuGui = new("ScreenGui", {
Name = "VigilMenu", ResetOnSpawn = false, IgnoreGuiInset = false,
ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 9001, Parent = ROOT,
})
local iconEye, iconSliders, iconCrosshair, iconTarget, iconSun, iconChevrons, iconClose
do
local ICON_STROKE = 1.6
function iconEye()
local root = new("Frame", { Size = UDim2.fromOffset(20, 20), BackgroundTransparency = 1 })
local lid = new("Frame", {
Size = UDim2.fromOffset(18, 11), AnchorPoint = Vector2.new(0.5, 0.5),
Position = UDim2.fromScale(0.5, 0.5), BackgroundTransparency = 1, Parent = root,
}, { round("full") })
local s = new("UIStroke", { Thickness = ICON_STROKE, Parent = lid })
local pupil = new("Frame", {
Size = UDim2.fromOffset(5, 5), AnchorPoint = Vector2.new(0.5, 0.5),
Position = UDim2.fromScale(0.5, 0.5), BorderSizePixel = 0, Parent = root,
}, { round("full") })
return root, function(c) s.Color = c; pupil.BackgroundColor3 = c end
end
function iconSliders()
local root = new("Frame", { Size = UDim2.fromOffset(20, 20), BackgroundTransparency = 1 })
local parts = {}
for i, knobX in ipairs({ 6, 13, 9 }) do
local y = 4 + (i - 1) * 6
table.insert(parts, new("Frame", {
Size = UDim2.fromOffset(16, ICON_STROKE), Position = UDim2.fromOffset(2, y),
AnchorPoint = Vector2.new(0, 0.5), BorderSizePixel = 0, Parent = root,
}))
table.insert(parts, new("Frame", {
Size = UDim2.fromOffset(5, 5), Position = UDim2.fromOffset(knobX, y),
AnchorPoint = Vector2.new(0.5, 0.5), BorderSizePixel = 0, Parent = root,
}, { round("full") }))
end
return root, function(c) for _, p in ipairs(parts) do p.BackgroundColor3 = c end end
end
function iconCrosshair()
local root = new("Frame", { Size = UDim2.fromOffset(20, 20), BackgroundTransparency = 1 })
local ring = new("Frame", {
Size = UDim2.fromOffset(13, 13), AnchorPoint = Vector2.new(0.5, 0.5),
Position = UDim2.fromScale(0.5, 0.5), BackgroundTransparency = 1, Parent = root,
}, { round("full") })
local s = new("UIStroke", { Thickness = ICON_STROKE, Parent = ring })
local fills = {
new("Frame", {
Size = UDim2.fromOffset(3, 3), AnchorPoint = Vector2.new(0.5, 0.5),
Position = UDim2.fromScale(0.5, 0.5), BorderSizePixel = 0, Parent = root,
}, { round("full") }),
}
for _, t in ipairs({
{ UDim2.fromOffset(10, 0), Vector2.new(ICON_STROKE, 5), Vector2.new(0.5, 0) },
{ UDim2.fromOffset(10, 20), Vector2.new(ICON_STROKE, 5), Vector2.new(0.5, 1) },
{ UDim2.fromOffset(0, 10), Vector2.new(5, ICON_STROKE), Vector2.new(0, 0.5) },
{ UDim2.fromOffset(20, 10), Vector2.new(5, ICON_STROKE), Vector2.new(1, 0.5) },
}) do
table.insert(fills, new("Frame", {
Position = t[1], Size = UDim2.fromOffset(t[2].X, t[2].Y), AnchorPoint = t[3],
BorderSizePixel = 0, Parent = root,
}))
end
return root, function(c)
s.Color = c
for _, f in ipairs(fills) do f.BackgroundColor3 = c end
end
end
function iconTarget()
local root = new("Frame", { Size = UDim2.fromOffset(20, 20), BackgroundTransparency = 1 })
local strokes = {}
for _, size in ipairs({ 17, 9 }) do
local ring = new("Frame", {
Size = UDim2.fromOffset(size, size), AnchorPoint = Vector2.new(0.5, 0.5),
Position = UDim2.fromScale(0.5, 0.5), BackgroundTransparency = 1, Parent = root,
}, { round("full") })
table.insert(strokes, new("UIStroke", { Thickness = ICON_STROKE, Parent = ring }))
end
local dot = new("Frame", {
Size = UDim2.fromOffset(3, 3), AnchorPoint = Vector2.new(0.5, 0.5),
Position = UDim2.fromScale(0.5, 0.5), BorderSizePixel = 0, Parent = root,
}, { round("full") })
return root, function(c)
for _, s in ipairs(strokes) do s.Color = c end
dot.BackgroundColor3 = c
end
end
function iconSun()
local root = new("Frame", { Size = UDim2.fromOffset(20, 20), BackgroundTransparency = 1 })
local core = new("Frame", {
Size = UDim2.fromOffset(8, 8), AnchorPoint = Vector2.new(0.5, 0.5),
Position = UDim2.fromScale(0.5, 0.5), BackgroundTransparency = 1, Parent = root,
}, { round("full") })
local s = new("UIStroke", { Thickness = ICON_STROKE, Parent = core })
local rays = {}
for i = 0, 7 do
local a = math.rad(i * 45)
table.insert(rays, new("Frame", {
Size = UDim2.fromOffset(ICON_STROKE, 3), AnchorPoint = Vector2.new(0.5, 0.5),
Position = UDim2.fromOffset(10 + math.sin(a) * 8, 10 - math.cos(a) * 8),
Rotation = i * 45, BorderSizePixel = 0, Parent = root,
}))
end
return root, function(c)
s.Color = c
for _, r in ipairs(rays) do r.BackgroundColor3 = c end
end
end
function iconChevrons()
local root = new("Frame", { Size = UDim2.fromOffset(20, 20), BackgroundTransparency = 1 })
local arms = {}
for _, y in ipairs({ 6, 12 }) do
for _, side in ipairs({ -1, 1 }) do
table.insert(arms, new("Frame", {
Size = UDim2.fromOffset(8, ICON_STROKE), AnchorPoint = Vector2.new(0.5, 0.5),
Position = UDim2.fromOffset(10 + side * 2.7, y), Rotation = side * 45,
BorderSizePixel = 0, Parent = root,
}))
end
end
return root, function(c) for _, a in ipairs(arms) do a.BackgroundColor3 = c end end
end
function iconClose()
local root = new("Frame", { Size = UDim2.fromOffset(16, 16), BackgroundTransparency = 1 })
local a = new("Frame", {
Size = UDim2.fromOffset(14, ICON_STROKE), AnchorPoint = Vector2.new(0.5, 0.5),
Position = UDim2.fromScale(0.5, 0.5), Rotation = 45, BorderSizePixel = 0, Parent = root,
})
local b = a:Clone()
b.Rotation = -45
b.Parent = root
return root, function(c) a.BackgroundColor3 = c; b.BackgroundColor3 = c end
end
end
local Holder = new("Frame", {
Name = "Holder", Size = UDim2.fromOffset(Tokens.size.window.X, Tokens.size.window.Y),
AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
BackgroundTransparency = 1, Parent = menuGui,
})
local windowScale = new("UIScale", { Parent = Holder })
local shadow = new("ImageLabel", {
Name = "Shadow", Image = "rbxassetid://6014261993", ScaleType = Enum.ScaleType.Slice,
SliceCenter = Rect.new(49, 49, 450, 450), ImageColor3 = Color3.new(0, 0, 0),
BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5),
Position = UDim2.new(0.5, 0, 0.5, 4), Size = UDim2.new(1, 44, 1, 44), ZIndex = 0, Parent = Holder,
})
local Window = new("Frame", {
Name = "Window", Size = UDim2.fromScale(1, 1), BorderSizePixel = 0, Active = true, ZIndex = 1, Parent = Holder,
}, { round(Tokens.radius.lg) })
bind(Window, "BackgroundColor3", "bg")
bind(new("UIStroke", { Thickness = Tokens.stroke, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = Window }), "Color", "border")
onTheme(function() shadow.ImageTransparency = P.shadow end)
local rail = new("Frame", {
Name = "Rail", Size = UDim2.new(0, Tokens.size.rail, 1, 0), BorderSizePixel = 0, Parent = Window,
}, { round(Tokens.radius.lg) })
bind(rail, "BackgroundColor3", "surface")
bind(new("Frame", { -- squares the rail's right edge
Size = UDim2.new(0, Tokens.radius.lg, 1, 0), Position = UDim2.new(1, -Tokens.radius.lg, 0, 0),
BorderSizePixel = 0, Parent = rail,
}), "BackgroundColor3", "surface")
bind(new("Frame", {
Size = UDim2.new(0, 1, 1, 0), Position = UDim2.new(1, 0, 0, 0), BorderSizePixel = 0, Parent = rail,
}), "BackgroundColor3", "border")
local railTop = new("Frame", {
Size = UDim2.new(1, 0, 1, -Tokens.space.md), BackgroundTransparency = 1, Parent = rail,
}, {
padding(Tokens.space.md, 0),
new("UIListLayout", {
Padding = UDim.new(0, Tokens.space.xs), HorizontalAlignment = Enum.HorizontalAlignment.Center,
SortOrder = Enum.SortOrder.LayoutOrder,
}),
})
local railBottom = new("Frame", {
Size = UDim2.new(1, 0, 0, 40), AnchorPoint = Vector2.new(0, 1),
Position = UDim2.new(0, 0, 1, -Tokens.space.md), BackgroundTransparency = 1, Parent = rail,
}, {
new("UIListLayout", { HorizontalAlignment = Enum.HorizontalAlignment.Center }),
})
local content = new("Frame", {
Name = "Content", Size = UDim2.new(1, -(Tokens.size.rail + 1), 1, 0),
Position = UDim2.fromOffset(Tokens.size.rail + 1, 0), BackgroundTransparency = 1, Parent = Window,
})
local header = new("Frame", {
Name = "Header", Size = UDim2.new(1, 0, 0, Tokens.size.header), BackgroundTransparency = 1, Parent = content,
})
local title = new("TextLabel", {
Size = UDim2.new(1, -60, 1, 0), Position = UDim2.fromOffset(Tokens.space.lg + 4, 0),
BackgroundTransparency = 1, FontFace = Tokens.fontStrong, TextSize = Tokens.text.title,
TextXAlignment = Enum.TextXAlignment.Left, Text = "", Parent = header,
})
bind(title, "TextColor3", "text")
local hideTip, tooltip, toast
do
local tip = new("TextLabel", {
AutomaticSize = Enum.AutomaticSize.XY, Size = UDim2.fromOffset(0, 0), Visible = false, ZIndex = 50,
FontFace = Tokens.font, TextSize = Tokens.text.small, AnchorPoint = Vector2.new(0, 0.5), Parent = menuGui,
}, { round(Tokens.radius.sm), padding(5, 9) })
bind(tip, "BackgroundColor3", "raised")
bind(tip, "TextColor3", "text")
bind(new("UIStroke", { Thickness = Tokens.stroke, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = tip }), "Color", "border")
local tipToken = 0
function hideTip()
tipToken += 1
tip.Visible = false
end
function tooltip(target, text)
connect(target.MouseEnter, function()
tipToken += 1
local mine = tipToken
task.delay(reducedMotion and 0.1 or Tokens.tooltipDelay, function()
if mine ~= tipToken or not Holder.Visible then return end
local pos, size = target.AbsolutePosition, target.AbsoluteSize
tip.Text = text
tip.Position = UDim2.fromOffset(pos.X + size.X + Tokens.space.sm, pos.Y + size.Y / 2)
tip.Visible = true
end)
end)
connect(target.MouseLeave, hideTip)
end
local toastFrame = new("Frame", {
AutomaticSize = Enum.AutomaticSize.XY, Size = UDim2.fromOffset(0, 0), Visible = false, ZIndex = 60,
AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -Tokens.space.lg, 1, -Tokens.space.lg),
BorderSizePixel = 0, Parent = menuGui,
}, {
round(Tokens.radius.md), padding(6, 6, 6, 14),
new("UIListLayout", {
FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, Tokens.space.md),
VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder,
}),
})
bind(toastFrame, "BackgroundColor3", "surface")
bind(new("UIStroke", { Thickness = Tokens.stroke, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = toastFrame }), "Color", "border")
local toastLabel = new("TextLabel", {
AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, Tokens.size.control),
BackgroundTransparency = 1, FontFace = Tokens.font, TextSize = Tokens.text.body, ZIndex = 61,
LayoutOrder = 1, Parent = toastFrame,
})
bind(toastLabel, "TextColor3", "text")
local toastAction = new("TextButton", {
AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, Tokens.size.control),
FontFace = Tokens.fontStrong, TextSize = Tokens.text.small + 1, AutoButtonColor = false,
BorderSizePixel = 0, ZIndex = 61, LayoutOrder = 2, Visible = false, Parent = toastFrame,
}, { round(Tokens.radius.sm), padding(0, 10) })
bind(toastAction, "BackgroundColor3", "raised")
bind(toastAction, "TextColor3", "accent")
local toastToken = 0
local toastCallback
function toast(text, actionText, action)
toastToken += 1
local mine = toastToken
toastLabel.Text = text
toastAction.Visible = actionText ~= nil
toastAction.Text = actionText or ""
toastCallback = action
toastFrame.Visible = true
task.delay(actionText and 5 or 2.5, function()
if mine == toastToken then
toastFrame.Visible = false
toastCallback = nil
end
end)
end
table.insert(connections, toastAction.Activated:Connect(function()
local fn = toastCallback
toastToken += 1
toastFrame.Visible = false
toastCallback = nil
if fn then fn() end
end))
end
local iconButton, section, row, switchRenders, switch, note, slider, segmented, swatches, keyCapture, consumedInput, aimToggled, keybind, actionButton, buttonRow
do
local order = 0
local function nextOrder()
order += 1
return order
end
function iconButton(parent, size, makeIcon, label, idleToken)
local btn = new("TextButton", {
Size = UDim2.fromOffset(size, size), Text = "", AutoButtonColor = false,
BackgroundTransparency = 1, BorderSizePixel = 0, LayoutOrder = nextOrder(), Parent = parent,
}, { round(Tokens.radius.md) })
bind(btn, "BackgroundColor3", "hover")
local icon, paint = makeIcon()
icon.AnchorPoint = Vector2.new(0.5, 0.5)
icon.Position = UDim2.fromScale(0.5, 0.5)
icon.Parent = btn
local state = { hovered = false, active = false }
local function render()
btn.BackgroundTransparency = (state.active and 0.35) or (state.hovered and 0.6) or 1
paint((state.active or state.hovered) and P.text or P[idleToken or "muted"])
end
connect(btn.MouseEnter, function() state.hovered = true; render() end)
connect(btn.MouseLeave, function() state.hovered = false; render() end)
onTheme(render)
tooltip(btn, label)
return btn, function(active) state.active = active; render() end
end
function section(page, text)
local holder = new("Frame", {
Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, LayoutOrder = nextOrder(), Parent = page,
})
bind(new("TextLabel", {
Size = UDim2.new(1, 0, 0, 18), AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1),
BackgroundTransparency = 1, FontFace = Tokens.font, TextSize = Tokens.text.small,
TextXAlignment = Enum.TextXAlignment.Left, Text = text, Parent = holder,
}), "TextColor3", "muted")
end
function row(page, label)
local r = new("Frame", {
Size = UDim2.new(1, 0, 0, Tokens.size.row), BackgroundTransparency = 1,
LayoutOrder = nextOrder(), Parent = page,
})
bind(new("TextLabel", {
Size = UDim2.new(0.5, 0, 1, 0), BackgroundTransparency = 1, FontFace = Tokens.font,
TextSize = Tokens.text.body, TextXAlignment = Enum.TextXAlignment.Left,
TextTruncate = Enum.TextTruncate.AtEnd, Text = label, Parent = r,
}), "TextColor3", "text")
return r
end
local function rightAligned(props)
props.AnchorPoint = Vector2.new(1, 0.5)
props.Position = UDim2.fromScale(1, 0.5)
return props
end
switchRenders = {} -- key -> re-render, so other controls (hotkeys, preview chips) stay in sync
function switch(page, label, key, onChange)
local r = row(page, label)
local track = new("Frame", rightAligned({ Size = UDim2.fromOffset(40, 22), BorderSizePixel = 0, Parent = r }), { round("full") })
local knob = new("Frame", {
Size = UDim2.fromOffset(16, 16), AnchorPoint = Vector2.new(0, 0.5), BorderSizePixel = 0, Parent = track,
}, { round("full") })
local hit = new("TextButton", {
Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", ZIndex = 2, Parent = r,
})
local function render(animate)
local on = Settings[key]
local trackProps = { BackgroundColor3 = on and P.accent or P.raised }
local knobProps = { Position = on and UDim2.new(1, -19, 0.5, 0) or UDim2.new(0, 3, 0.5, 0) }
knob.BackgroundColor3 = on and P.onAccent or P.knob
if animate then
tween(track, trackProps)
tween(knob, knobProps)
else
track.BackgroundColor3 = trackProps.BackgroundColor3
knob.Position = knobProps.Position
end
end
connect(hit.Activated, function()
Settings[key] = not Settings[key]
render(true)
save()
if onChange then onChange(Settings[key]) end
end)
onTheme(function() render(false) end)
local animated = function() render(true) end
switchRenders[key] = animated
return animated
end
function note(page, text)
local label = new("TextLabel", {
Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
FontFace = Tokens.font, TextSize = Tokens.text.small, TextWrapped = true,
TextXAlignment = Enum.TextXAlignment.Left, Text = text, LayoutOrder = nextOrder(), Parent = page,
}, { padding(2, 0, 8, 0) })
bind(label, "TextColor3", "muted")
end
function slider(page, label, key, min, max, step, format)
local r = row(page, label)
local value = new("TextLabel", rightAligned({
Size = UDim2.fromOffset(100, 20), BackgroundTransparency = 1, FontFace = Tokens.mono,
TextSize = Tokens.text.small, TextXAlignment = Enum.TextXAlignment.Right, Parent = r,
}))
bind(value, "TextColor3", "muted")
local hit = new("TextButton", {
Size = UDim2.fromOffset(140, 26), AnchorPoint = Vector2.new(1, 0.5),
Position = UDim2.new(1, -108, 0.5, 0), BackgroundTransparency = 1, Text = "", Parent = r,
})
local track = new("Frame", {
Size = UDim2.new(1, 0, 0, 4), AnchorPoint = Vector2.new(0, 0.5),
Position = UDim2.fromScale(0, 0.5), BorderSizePixel = 0, Parent = hit,
}, { round("full") })
bind(track, "BackgroundColor3", "raised")
local fill = new("Frame", { Size = UDim2.fromScale(0, 1), BorderSizePixel = 0, Parent = track }, { round("full") })
local knob = new("Frame", {
Size = UDim2.fromOffset(14, 14), AnchorPoint = Vector2.new(0.5, 0.5), BorderSizePixel = 0, Parent = track,
}, { round("full") })
local function render()
local a = (Settings[key] - min) / (max - min)
fill.Size = UDim2.fromScale(a, 1)
knob.Position = UDim2.fromScale(a, 0.5)
fill.BackgroundColor3 = P.accent
knob.BackgroundColor3 = P.accent
value.Text = format(Settings[key])
end
local dragging = false
local function setFromX(x)
local a = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
local v = math.floor((min + (max - min) * a) / step + 0.5) * step
if v ~= Settings[key] then
Settings[key] = v
render()
end
end
connect(hit.InputBegan, function(input)
if isPointer(input) then
dragging = true
setFromX(input.Position.X)
end
end)
connect(UserInputService.InputChanged, function(input)
if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
setFromX(input.Position.X)
end
end)
connect(UserInputService.InputEnded, function(input)
if dragging and isPointer(input) then
dragging = false
save()
end
end)
onTheme(render)
end
function segmented(page, label, key, options, onChange)
local r = row(page, label)
local holder = new("Frame", rightAligned({
AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, Tokens.size.control),
BorderSizePixel = 0, Parent = r,
}), {
round(Tokens.radius.md), padding(2),
new("UIListLayout", {
FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 2),
SortOrder = Enum.SortOrder.LayoutOrder,
}),
})
bind(holder, "BackgroundColor3", "raised")
local buttons = {}
for i, option in ipairs(options) do
buttons[option] = new("TextButton", {
AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.new(0, 0, 1, 0), Text = option,
FontFace = Tokens.font, TextSize = Tokens.text.small + 1, AutoButtonColor = false,
BorderSizePixel = 0, LayoutOrder = i, Parent = holder,
}, { round(Tokens.radius.sm), padding(0, 12) })
end
local function render()
for option, btn in pairs(buttons) do
local selected = Settings[key] == option
btn.BackgroundColor3 = P.bg
btn.BackgroundTransparency = selected and 0 or 1
btn.TextColor3 = selected and P.text or P.muted
end
end
for option, btn in pairs(buttons) do
connect(btn.Activated, function()
if Settings[key] == option then return end
Settings[key] = option
save()
if onChange then onChange(option) else render() end
end)
end
onTheme(render)
end
function swatches(page, label, key, colours, onChange)
local r = row(page, label)
local holder = new("Frame", rightAligned({
AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 24), BackgroundTransparency = 1, Parent = r,
}), {
new("UIListLayout", {
FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, Tokens.space.sm),
VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder,
}),
})
local rings = {}
for i, entry in ipairs(colours) do
local btn = new("TextButton", {
Size = UDim2.fromOffset(24, 24), BackgroundTransparency = 1, Text = "",
LayoutOrder = i, Parent = holder,
})
new("Frame", {
Size = UDim2.fromOffset(16, 16), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
BackgroundColor3 = entry[2], BorderSizePixel = 0, Parent = btn,
}, { round("full") })
local ringFrame = new("Frame", {
Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = btn,
}, { round("full") })
rings[i] = new("UIStroke", { Thickness = 2, Parent = ringFrame })
tooltip(btn, entry[1])
connect(btn.Activated, function()
if Settings[key] == i then return end
Settings[key] = i
save()
if onChange then onChange(i) else applyTheme() end
end)
end
onTheme(function()
for i, ring in ipairs(rings) do
ring.Enabled = Settings[key] == i
ring.Color = P.text
end
end)
end
aimToggled = false
function keybind(page, label, key, allowMouse)
local r = row(page, label)
local btn = new("TextButton", rightAligned({
AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, Tokens.size.control),
FontFace = Tokens.mono, TextSize = Tokens.text.small, AutoButtonColor = false,
BorderSizePixel = 0, Parent = r,
}), { round(Tokens.radius.md), padding(0, 12) })
local listening = false
local function render()
btn.Text = listening and (allowMouse and "Press a key or button" or "Press a key") or bindName(Settings[key])
btn.BackgroundColor3 = listening and P.hover or P.raised
btn.TextColor3 = listening and P.muted or P.text
end
connect(btn.Activated, function()
listening = true
render()
keyCapture = function(name)
if MouseBinds[name] and not allowMouse then return end
listening = false
keyCapture = nil
if name ~= "Escape" then
Settings[key] = name
save()
end
render()
end
end)
onTheme(render)
end
function actionButton(page, label, text, onClick)
local r = row(page, label)
local btn = new("TextButton", rightAligned({
AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, Tokens.size.control),
Text = text, FontFace = Tokens.font, TextSize = Tokens.text.small + 1, AutoButtonColor = false,
BorderSizePixel = 0, Parent = r,
}), { round(Tokens.radius.md), padding(0, 14) })
local hovered = false
local function render()
btn.BackgroundColor3 = hovered and P.danger or P.raised
btn.TextColor3 = hovered and P.onAccent or P.danger
end
connect(btn.MouseEnter, function() hovered = true; render() end)
connect(btn.MouseLeave, function() hovered = false; render() end)
connect(btn.Activated, onClick)
onTheme(render)
end
function buttonRow(page, label, buttons)
local r = row(page, label)
local holder = new("Frame", rightAligned({
AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, Tokens.size.control),
BackgroundTransparency = 1, Parent = r,
}), {
new("UIListLayout", {
FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, Tokens.space.sm),
SortOrder = Enum.SortOrder.LayoutOrder,
}),
})
for i, entry in ipairs(buttons) do
local btn = new("TextButton", {
AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.new(0, 0, 1, 0), Text = entry[1],
FontFace = Tokens.font, TextSize = Tokens.text.small + 1, AutoButtonColor = false,
BorderSizePixel = 0, LayoutOrder = i, Parent = holder,
}, { round(Tokens.radius.md), padding(0, 12) })
local hovered = false
local function render()
btn.BackgroundColor3 = hovered and P.hover or P.raised
btn.TextColor3 = P.text
end
connect(btn.MouseEnter, function() hovered = true; render() end)
connect(btn.MouseLeave, function() hovered = false; render() end)
connect(btn.Activated, entry[2])
onTheme(render)
end
end
end
local Presets, applyPreset
do
Presets = {
{ "Legit", {
aimEnabled = true, aimMode = "Hold", aimPart = "Torso", aimPriority = "Crosshair",
fov = 80, showFov = false, smoothing = 8, prediction = 0, visibleOnly = true,
aimTeamCheck = true, stickyTarget = true, aimMaxDistance = 800, silentEnabled = false,
} },
{ "Silent", {
aimEnabled = false, silentEnabled = true, silentPart = "Closest", hitChance = 75,
silentFov = 100, showSilentFov = false, showSilentTarget = false, silentVisibleOnly = true,
silentTeamCheck = true, silentMaxDistance = 1000,
} },
{ "Rage", {
aimEnabled = true, aimMode = "Always", aimPart = "Head", aimPriority = "Crosshair",
fov = 500, showFov = true, smoothing = 1, visibleOnly = false, stickyTarget = false,
aimMaxDistance = 3000, silentEnabled = true, silentPart = "Head", hitChance = 100,
silentFov = 600, silentVisibleOnly = false, showSilentTarget = true, silentMaxDistance = 3000,
} },
}
function applyPreset(name, values)
local before = table.clone(Settings)
for k, v in pairs(values) do Settings[k] = v end
save()
applyTheme() -- re-renders every control from Settings
toast(name .. " preset applied", "Undo", function()
for k, v in pairs(before) do Settings[k] = v end
save()
applyTheme()
end)
end
end
local pages, tabSetters = {}, {}
local tabExtras = {} -- tab id -> extra panel shown only on that tab
local function page(id)
local p = new("ScrollingFrame", {
Name = id, Size = UDim2.new(1, 0, 1, -Tokens.size.header), Position = UDim2.fromOffset(0, Tokens.size.header),
BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3,
ScrollingDirection = Enum.ScrollingDirection.Y, AutomaticCanvasSize = Enum.AutomaticSize.Y,
CanvasSize = UDim2.new(), Visible = false, Parent = content,
}, {
padding(0, Tokens.space.lg + 4, Tokens.space.lg, Tokens.space.lg + 4),
new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }),
})
bind(p, "ScrollBarImageColor3", "border")
pages[id] = p
return p
end
local tabs = {
{ id = "esp", title = "ESP", icon = iconEye },
{ id = "aim", title = "Aimbot", icon = iconCrosshair },
{ id = "silent", title = "Silent aim", icon = iconTarget },
{ id = "visuals", title = "Visuals", icon = iconSun },
{ id = "movement", title = "Movement", icon = iconChevrons },
{ id = "settings", title = "Settings", icon = iconSliders, bottom = true },
}
local function selectTab(id)
for _, tab in ipairs(tabs) do
pages[tab.id].Visible = tab.id == id
tabSetters[tab.id](tab.id == id)
if tab.id == id then title.Text = tab.title end
end
for tabId, panel in pairs(tabExtras) do
panel.Visible = tabId == id
end
hideTip()
end
for _, tab in ipairs(tabs) do
local btn, setActive = iconButton(tab.bottom and railBottom or railTop, 40, tab.icon, tab.title)
tabSetters[tab.id] = setActive
connect(btn.Activated, function() selectTab(tab.id) end)
end
local PANEL_W, PREVIEW_H = 268, 220
local PREVIEW_W = PANEL_W - 24
local espPage = page("esp")
espPage.Size = UDim2.new(1, -(PANEL_W + Tokens.space.lg), 1, -Tokens.size.header)
switch(espPage, "Enabled", "enabled")
section(espPage, "Show")
switch(espPage, "Box", "boxes")
segmented(espPage, "Box style", "boxStyle", { "Corners", "Full" })
switch(espPage, "Box fill", "boxFill")
switch(espPage, "Name", "names")
switch(espPage, "Distance", "distance")
switch(espPage, "Held item", "item")
switch(espPage, "Health bar", "health")
switch(espPage, "Skeleton", "skeleton")
switch(espPage, "Tracer", "tracers")
switch(espPage, "Off-screen arrows", "arrows")
switch(espPage, "Glow through walls", "highlight")
section(espPage, "Filter")
switch(espPage, "Hide teammates", "teamCheck")
switch(espPage, "Dim hidden players", "visCheck")
segmented(espPage, "Follow", "bodySource", { "Auto", "Visible", "Character" })
note(espPage, "Some games show a different model from a player's real character. Auto follows the visible one when the real one is hidden.")
slider(espPage, "Max distance", "maxDistance", 100, 5000, 50, function(v) return string.format("%d studs", v) end)
section(espPage, "Style")
swatches(espPage, "Colour", "espColour", EspColours, function() applyTheme() end)
switch(espPage, "Use team colours", "teamColour")
segmented(espPage, "Tracer origin", "tracerOrigin", { "Bottom", "Centre", "Mouse" })
slider(espPage, "Text size", "textSize", 11, 20, 1, function(v) return string.format("%d px", v) end)
local previewUI = { width = PREVIEW_W, height = PREVIEW_H }
do
local panel = new("Frame", {
Name = "Preview", AnchorPoint = Vector2.new(1, 0),
Position = UDim2.new(1, -Tokens.space.lg, 0, Tokens.size.header),
Size = UDim2.new(0, PANEL_W, 1, -(Tokens.size.header + Tokens.space.lg)),
BorderSizePixel = 0, Visible = false, Parent = content,
}, { round(Tokens.radius.md), padding(Tokens.space.md) })
bind(panel, "BackgroundColor3", "surface")
local stage = new("Frame", {
Name = "Stage", Size = UDim2.new(1, 0, 0, PREVIEW_H), BorderSizePixel = 0,
ClipsDescendants = true, Parent = panel,
}, { round(Tokens.radius.sm) })
bind(stage, "BackgroundColor3", "bg")
local dropStroke = new("UIStroke", {
Thickness = 2, Enabled = false, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = stage,
})
bind(dropStroke, "Color", "accent")
local viewport = new("ViewportFrame", {
Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
Ambient = Color3.fromRGB(130, 130, 140), LightColor = Color3.fromRGB(255, 255, 255),
LightDirection = Vector3.new(-1, -1, -1), Parent = stage,
})
local overlay = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 2, Parent = stage })
bind(new("TextLabel", {
Size = UDim2.new(1, 0, 0, 18), Position = UDim2.fromOffset(0, PREVIEW_H + 6),
BackgroundTransparency = 1, FontFace = Tokens.font, TextSize = Tokens.text.small,
TextXAlignment = Enum.TextXAlignment.Left, Text = "Drag onto the player to add, off to remove", Parent = panel,
}), "TextColor3", "muted")
local tray = new("Frame", {
Size = UDim2.new(1, 0, 1, -(PREVIEW_H + 32)), Position = UDim2.fromOffset(0, PREVIEW_H + 32),
BackgroundTransparency = 1, Parent = panel,
}, {
new("UIGridLayout", {
CellSize = UDim2.new(1 / 3, -4, 0, 28), CellPadding = UDim2.fromOffset(6, 6),
SortOrder = Enum.SortOrder.LayoutOrder,
}),
})
local CHIPS = {
{ "boxes", "Box" }, { "boxFill", "Fill" }, { "names", "Name" }, { "distance", "Distance" },
{ "item", "Item" }, { "health", "Health" }, { "skeleton", "Skeleton" }, { "tracers", "Tracer" },
{ "arrows", "Arrow" }, { "highlight", "Glow" },
}
local chips = {}
for i, def in ipairs(CHIPS) do
local btn = new("TextButton", {
Text = "", AutoButtonColor = false, BorderSizePixel = 0, LayoutOrder = i, Parent = tray,
}, { round(Tokens.radius.sm) })
local dot = new("Frame", {
Size = UDim2.fromOffset(8, 8), AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 9, 0.5, 0),
BorderSizePixel = 0, Parent = btn,
}, { round("full") })
local dotStroke = new("UIStroke", { Thickness = 1.5, Parent = dot })
local label = new("TextLabel", {
Size = UDim2.new(1, -26, 1, 0), Position = UDim2.fromOffset(23, 0), BackgroundTransparency = 1,
FontFace = Tokens.font, TextSize = Tokens.text.small, TextXAlignment = Enum.TextXAlignment.Left,
TextTruncate = Enum.TextTruncate.AtEnd, Text = def[2], Parent = btn,
})
chips[i] = { key = def[1], btn = btn, dot = dot, dotStroke = dotStroke, label = label }
end
function previewUI.renderChips()
for _, c in ipairs(chips) do
local on = Settings[c.key]
c.btn.BackgroundColor3 = on and P.accent or P.raised
c.btn.BackgroundTransparency = on and 0.8 or 0
c.label.TextColor3 = on and P.text or P.muted
c.dot.BackgroundColor3 = P.accent
c.dot.BackgroundTransparency = on and 0 or 1
c.dotStroke.Color = on and P.accent or P.muted
end
end
onTheme(previewUI.renderChips)
local function inside(gui, pos)
local p, s = gui.AbsolutePosition, gui.AbsoluteSize
return pos.X >= p.X and pos.X <= p.X + s.X and pos.Y >= p.Y and pos.Y <= p.Y + s.Y
end
local function setModule(key, value)
if Settings[key] == value then return end
Settings[key] = value
save()
if switchRenders[key] then switchRenders[key]() end
previewUI.renderChips()
end
local drag
for _, c in ipairs(chips) do
connect(c.btn.InputBegan, function(input)
if isPointer(input) then
drag = { chip = c, start = Vector2.new(input.Position.X, input.Position.Y) }
end
end)
end
connect(UserInputService.InputChanged, function(input)
if not drag then return end
if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
local pos = Vector2.new(input.Position.X, input.Position.Y)
if not drag.ghost then
if (pos - drag.start).Magnitude < 5 then return end
local ghost = drag.chip.btn:Clone()
ghost.Size = UDim2.fromOffset(drag.chip.btn.AbsoluteSize.X, drag.chip.btn.AbsoluteSize.Y)
ghost.AnchorPoint = Vector2.new(0.5, 0.5)
ghost.ZIndex = 80
ghost.Active = false
ghost.Parent = menuGui
drag.ghost = ghost
end
drag.ghost.Position = UDim2.fromOffset(pos.X, pos.Y)
dropStroke.Enabled = inside(stage, pos)
end)
connect(UserInputService.InputEnded, function(input)
if not drag or not isPointer(input) then return end
local d = drag
drag = nil
dropStroke.Enabled = false
local key = d.chip.key
if d.ghost then
d.ghost:Destroy()
if inside(stage, Vector2.new(input.Position.X, input.Position.Y)) then
setModule(key, true)
elseif Settings[key] then
setModule(key, false)
end
else
setModule(key, not Settings[key])
end
end)
previewUI.panel = panel
previewUI.viewport = viewport
previewUI.overlay = overlay
tabExtras.esp = panel
end
local canMoveMouse = typeof(mousemoverel) == "function"
local canHook = typeof(hookmetamethod) == "function" and typeof(getnamecallmethod) == "function"
and typeof(checkcaller) == "function"
do -- repair saved values that no longer fit this executor or the option lists
local choices = {
silentPart = { Head = true, Torso = true, Closest = true },
boxStyle = { Corners = true, Full = true },
bodySource = { Auto = true, Visible = true, Character = true },
aimMode = { Hold = true, Toggle = true, Always = true },
aimPart = { Head = true, Torso = true },
aimPriority = { Crosshair = true, Distance = true },
aimMethod = { Camera = true, Mouse = canMoveMouse },
tracerOrigin = { Bottom = true, Centre = true, Mouse = true },
}
local defaults = { bodySource = "Auto", boxStyle = "Corners", silentPart = "Head", aimMode = "Hold", aimPart = "Head", aimPriority = "Crosshair", aimMethod = "Camera", tracerOrigin = "Bottom" }
for key, allowed in pairs(choices) do
if not allowed[Settings[key]] then Settings[key] = defaults[key] end
end
if not bindValid(Settings.aimKey, true) then Settings.aimKey = "MouseButton2" end
if not bindValid(Settings.flyKey, false) then Settings.flyKey = "F" end
end
local aimPage = page("aim")
switch(aimPage, "Enabled", "aimEnabled")
keybind(aimPage, "Aim key", "aimKey", true)
segmented(aimPage, "Activation", "aimMode", { "Hold", "Toggle", "Always" })
section(aimPage, "Target")
segmented(aimPage, "Aim at", "aimPart", { "Head", "Torso" })
segmented(aimPage, "Prefer", "aimPriority", { "Crosshair", "Distance" })
switch(aimPage, "Ignore teammates", "aimTeamCheck")
switch(aimPage, "Visible only", "visibleOnly")
switch(aimPage, "Stay on target", "stickyTarget")
slider(aimPage, "Max distance", "aimMaxDistance", 50, 3000, 50, function(v) return string.format("%d studs", v) end)
section(aimPage, "Feel")
slider(aimPage, "Field of view", "fov", 30, 500, 5, function(v) return string.format("%d px", v) end)
switch(aimPage, "Show field of view", "showFov")
slider(aimPage, "Smoothing", "smoothing", 1, 20, 1, function(v) return v == 1 and "Off" or string.format("%d", v) end)
slider(aimPage, "Prediction", "prediction", 0, 250, 10, function(v) return v == 0 and "Off" or string.format("%d ms", v) end)
if canMoveMouse then
segmented(aimPage, "Method", "aimMethod", { "Camera", "Mouse" })
end
local silentPage = page("silent")
if canHook then
switch(silentPage, "Enabled", "silentEnabled")
section(silentPage, "Target")
segmented(silentPage, "Aim at", "silentPart", { "Head", "Torso", "Closest" })
slider(silentPage, "Hit chance", "hitChance", 0, 100, 1, function(v) return string.format("%d%%", v) end)
switch(silentPage, "Ignore teammates", "silentTeamCheck")
switch(silentPage, "Visible only", "silentVisibleOnly")
slider(silentPage, "Max distance", "silentMaxDistance", 50, 3000, 50, function(v) return string.format("%d studs", v) end)
section(silentPage, "Field of view")
slider(silentPage, "Radius", "silentFov", 30, 600, 5, function(v) return string.format("%d px", v) end)
switch(silentPage, "Show circle", "showSilentFov")
switch(silentPage, "Mark target", "showSilentTarget")
section(silentPage, "Redirect")
note(silentPage, "Games aim shots in different ways. Most use raycasts or the mouse position; try screen rays if neither works.")
switch(silentPage, "Raycasts", "silentRaycast")
switch(silentPage, "Mouse position", "silentMouse")
switch(silentPage, "Screen rays", "silentCameraRays")
else
note(silentPage, "Silent aim isn't available because this executor can't hook game functions.")
end
local visualsPage = page("visuals")
section(visualsPage, "World")
switch(visualsPage, "Fullbright", "fullbright")
switch(visualsPage, "Remove fog", "noFog")
switch(visualsPage, "Lock time of day", "lockTime")
slider(visualsPage, "Time", "timeOfDay", 0, 24, 0.5, function(v)
return string.format("%02d:%02d", math.floor(v) % 24, math.floor((v % 1) * 60 + 0.5))
end)
section(visualsPage, "Camera")
switch(visualsPage, "Custom field of view", "camFovEnabled")
slider(visualsPage, "Field of view", "camFov", 50, 120, 1, function(v) return string.format("%d°", v) end)
section(visualsPage, "Crosshair")
switch(visualsPage, "Show crosshair", "crosshair")
slider(visualsPage, "Size", "crosshairSize", 4, 20, 1, function(v) return string.format("%d px", v) end)
slider(visualsPage, "Gap", "crosshairGap", 0, 12, 1, function(v) return string.format("%d px", v) end)
local movementPage = page("movement")
section(movementPage, "Walking")
switch(movementPage, "Custom walk speed", "speedEnabled")
slider(movementPage, "Walk speed", "walkSpeed", 16, 200, 1, function(v) return string.format("%d studs/s", v) end)
switch(movementPage, "Custom jump power", "jumpEnabled")
slider(movementPage, "Jump power", "jumpPower", 50, 300, 5, function(v) return string.format("%d", v) end)
switch(movementPage, "Infinite jump", "infiniteJump")
section(movementPage, "Fly")
local renderFlySwitch = switch(movementPage, "Fly", "fly")
keybind(movementPage, "Fly key", "flyKey")
slider(movementPage, "Fly speed", "flySpeed", 10, 300, 5, function(v) return string.format("%d studs/s", v) end)
section(movementPage, "Other")
switch(movementPage, "Noclip", "noclip")
switch(movementPage, "Ctrl-click teleport", "clickTp")
local settingsPage = page("settings")
section(settingsPage, "Presets")
do
local buttons = {}
for _, preset in ipairs(Presets) do
table.insert(buttons, { preset[1], function() applyPreset(preset[1], preset[2]) end })
end
buttonRow(settingsPage, "Combat preset", buttons)
end
section(settingsPage, "Appearance")
switch(settingsPage, "Show active modules", "showModules")
segmented(settingsPage, "Theme", "theme", { "Dark", "Light" }, function() applyTheme() end)
swatches(settingsPage, "Accent", "accent", Accents)
section(settingsPage, "Controls")
keybind(settingsPage, "Show or hide menu", "menuKey")
section(settingsPage, "Script")
local unload -- defined below
actionButton(settingsPage, "Remove ESP and menu", "Unload", function() unload() end)
local closeBtn = iconButton(header, 32, iconClose, "Hide menu")
closeBtn.AnchorPoint = Vector2.new(1, 0.5)
closeBtn.Position = UDim2.new(1, -Tokens.space.md, 0.5, 0)
local baseScale = 1
local function rescale()
local camera = workspace.CurrentCamera
if not camera then return end
local vp = camera.ViewportSize
local size = Tokens.size.window
baseScale = math.clamp(math.min((vp.X - 32) / size.X, (vp.Y - 96) / size.Y), 0.55, 1)
windowScale.Scale = baseScale
end
rescale()
connect(workspace:GetPropertyChangedSignal("CurrentCamera"), rescale)
if workspace.CurrentCamera then
connect(workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"), rescale)
end
do
local dragStart, startPos
local function begin(input)
if isPointer(input) then
dragStart = input.Position
startPos = Holder.Position
end
end
connect(header.InputBegan, begin)
connect(rail.InputBegan, begin)
connect(UserInputService.InputChanged, function(input)
if dragStart and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
local d = input.Position - dragStart
Holder.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
end
end)
connect(UserInputService.InputEnded, function(input)
if isPointer(input) then dragStart = nil end
end)
end
local function setMenuVisible(visible)
if visible == Holder.Visible then return end
hideTip()
Holder.Visible = visible
if visible then
windowScale.Scale = baseScale * 0.97
tween(windowScale, { Scale = baseScale })
end
end
local touchOnly = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
connect(closeBtn.Activated, function()
setMenuVisible(false)
if not touchOnly then
toast("Menu hidden. " .. bindName(Settings.menuKey) .. " shows it again.")
end
end)
connect(UserInputService.InputBegan, function(input)
local name = inputName(input)
if not name then return end
if keyCapture then
consumedInput = input
keyCapture(name)
return
end
if UserInputService:GetFocusedTextBox() then return end
if name == Settings.menuKey then
setMenuVisible(not Holder.Visible)
end
if name == Settings.aimKey and Settings.aimMode == "Toggle" then
aimToggled = not aimToggled
end
end)
if touchOnly then -- no keyboard: a small floating button replaces the hotkey
local fab = new("TextButton", {
Size = UDim2.fromOffset(44, 44), Position = UDim2.new(0, Tokens.space.md, 0.35, 0),
Text = "", AutoButtonColor = false, BorderSizePixel = 0, Parent = menuGui,
}, { round("full") })
bind(fab, "BackgroundColor3", "surface")
bind(new("UIStroke", { Thickness = Tokens.stroke, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = fab }), "Color", "border")
local icon, paint = iconEye()
icon.AnchorPoint = Vector2.new(0.5, 0.5)
icon.Position = UDim2.fromScale(0.5, 0.5)
icon.Parent = fab
onTheme(function() paint(P.text) end)
connect(fab.Activated, function() setMenuVisible(not Holder.Visible) end)
end
local teamCache = { at = -1, split = false }
local function teamsSplit()
local now = os.clock()
if now - teamCache.at > 0.5 then
teamCache.at = now
teamCache.split = false
local myTeam = LocalPlayer.Team
for _, other in ipairs(Players:GetPlayers()) do
if other.Team ~= myTeam then
teamCache.split = true
break
end
end
end
return teamCache.split
end
local function isTeammate(player)
local myTeam = LocalPlayer.Team
return myTeam ~= nil and player.Team == myTeam and not player.Neutral and teamsSplit()
end
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
local function isVisible(camera, part, char, extra)
rayParams.FilterDescendantsInstances = { camera, LocalPlayer.Character, char, extra }
local origin = camera.CFrame.Position
return workspace:Raycast(origin, part.Position - origin, rayParams) == nil
end
local bodyOf, outline, Esp, removeEsp, espStep
do
local bodyModels = {} -- set of character-like models
local bodyChoice = {} -- player -> visible model used instead of the real Character
local BODY_CLASSES = { Humanoid = true, AnimationController = true }
local function considerBody(inst)
if BODY_CLASSES[inst.ClassName] or inst.Name == "Head" then
local model = inst.Parent
if model and model.ClassName == "Model" then bodyModels[model] = true end
end
end
for _, inst in ipairs(workspace:GetDescendants()) do considerBody(inst) end
connect(workspace.DescendantAdded, considerBody)
local function bodyRoot(model)
return model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart or model:FindFirstChild("UpperTorso")
or model:FindFirstChild("Torso") or model:FindFirstChild("Head")
end
local function partHidden(part)
return part.Transparency >= 0.95 or part.LocalTransparencyModifier >= 0.95
end
local function looksHidden(char)
if not char:IsDescendantOf(workspace) then return true end
local head = char:FindFirstChild("Head")
if head and head:IsA("BasePart") then return partHidden(head) end
for _, part in ipairs(char:GetChildren()) do
if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" and not partHidden(part) then
return false
end
end
return true
end
local function ownedBy(model, player)
local name = model.Name
if name == player.Name or name == player.DisplayName or name == tostring(player.UserId) then return true end
for _, value in pairs(model:GetAttributes()) do
if value == player.Name or value == player.UserId or value == player.DisplayName then return true end
end
for _, child in ipairs(model:GetChildren()) do
if child:IsA("ObjectValue") and child.Value == player then return true end
if (child:IsA("StringValue") and child.Value == player.Name)
or (child:IsA("IntValue") and child.Value == player.UserId) then
return true
end
end
return false
end
local function refreshBodies()
local mode = Settings.bodySource
if mode == "Character" then
table.clear(bodyChoice)
return
end
local camera = workspace.CurrentCamera
local myChar = LocalPlayer.Character
local myRoot = myChar and bodyRoot(myChar)
local realChars = {}
for _, p in ipairs(Players:GetPlayers()) do
if p.Character then realChars[p.Character] = true end
end
local free, freeByModel = {}, {}
for model in pairs(bodyModels) do
if not model.Parent then
bodyModels[model] = nil
elseif not realChars[model] and not (myChar and model:IsDescendantOf(myChar)) then
local root = bodyRoot(model)
local nearMe = root and ((myRoot and (root.Position - myRoot.Position).Magnitude < 4)
or (camera and (root.Position - camera.CFrame.Position).Magnitude < 4))
if root and not nearMe then
local body = { model = model, root = root }
table.insert(free, body)
freeByModel[model] = body
end
end
end
local previous = table.clone(bodyChoice)
table.clear(bodyChoice)
local waiting = {}
for _, p in ipairs(Players:GetPlayers()) do
if p ~= LocalPlayer then
local needs = mode == "Visible" or not p.Character or looksHidden(p.Character)
for _, body in ipairs(free) do
if not body.taken and ownedBy(body.model, p) then
bodyChoice[p] = body.model
body.taken = true
break
end
end
if not bodyChoice[p] and needs then
local kept = previous[p] and freeByModel[previous[p]]
if kept and not kept.taken then
bodyChoice[p] = kept.model
kept.taken = true
else
table.insert(waiting, p)
end
end
end
end
local candidates = {}
for _, p in ipairs(waiting) do
local root = p.Character and bodyRoot(p.Character)
for _, body in ipairs(free) do
if not body.taken then
local d = root and (root.Position - body.root.Position).Magnitude or 0
if d < 300 then table.insert(candidates, { p, body, d }) end
end
end
end
table.sort(candidates, function(a, b) return a[3] < b[3] end)
for _, entry in ipairs(candidates) do
local p, body = entry[1], entry[2]
if not bodyChoice[p] and not body.taken then
bodyChoice[p] = body.model
body.taken = true
end
end
end
do
local elapsed = 1
connect(RunService.Heartbeat, function(dt)
elapsed += dt
if elapsed >= 0.25 then
elapsed = 0
refreshBodies()
end
end)
end
function bodyOf(player)
local char = player.Character
local body = bodyChoice[player]
if not (body and body.Parent) then body = char end
local hum = (char and char:FindFirstChildOfClass("Humanoid")) or (body and body:FindFirstChildOfClass("Humanoid"))
return body, hum
end
local function writeDump()
if not canSave then return end
local lines = {}
local function add(fmt, ...) table.insert(lines, string.format(fmt, ...)) end
local function vec(v) return string.format("(%.1f, %.1f, %.1f)", v.X, v.Y, v.Z) end
local function pathOf(inst) return inst and inst:GetFullName() or "nil" end
local myChar = LocalPlayer.Character
local myRoot = myChar and bodyRoot(myChar)
add("place %d  time %.0f  players %d  follow=%s", game.PlaceId, os.clock(), #Players:GetPlayers(), Settings.bodySource)
add("me %s char=%s root=%s", LocalPlayer.Name, pathOf(myChar), myRoot and vec(myRoot.Position) or "nil")
for _, p in ipairs(Players:GetPlayers()) do
if p ~= LocalPlayer then
local c = p.Character
local r = c and bodyRoot(c)
local head = c and c:FindFirstChild("Head")
local isPart = head and head:IsA("BasePart")
add("player %s display=%s team=%s char=%s root=%s hidden=%s headT=%s headLTM=%s choice=%s",
p.Name, p.DisplayName, tostring(p.Team), pathOf(c), r and vec(r.Position) or "nil",
c and tostring(looksHidden(c)) or "-", isPart and tostring(head.Transparency) or "-",
isPart and tostring(head.LocalTransparencyModifier) or "-", pathOf(bodyChoice[p]))
if c then
local kids = {}
for _, k in ipairs(c:GetChildren()) do
local extra = k:IsA("BasePart") and string.format("[T%.2f %s]", k.Transparency, vec(k.Position)) or ""
table.insert(kids, k.Name .. ":" .. k.ClassName .. extra)
end
add("  char children: %s", table.concat(kids, ", "))
end
end
end
add("-- parts named Head")
local heads = 0
for _, d in ipairs(workspace:GetDescendants()) do
if d.Name == "Head" and d:IsA("BasePart") and heads < 60 then
heads += 1
add("%s pos=%s T=%.2f LTM=%.2f", d:GetFullName(), vec(d.Position), d.Transparency, d.LocalTransparencyModifier)
end
end
add("-- character-like models")
for model in pairs(bodyModels) do
if model.Parent then
local r = bodyRoot(model)
local attrs = {}
for k, v in pairs(model:GetAttributes()) do table.insert(attrs, k .. "=" .. tostring(v)) end
local kids = {}
for i, k in ipairs(model:GetChildren()) do
if i > 20 then break end
table.insert(kids, k.Name .. ":" .. k.ClassName)
end
add("%s root=%s attrs={%s}", model:GetFullName(), r and vec(r.Position) or "nil", table.concat(attrs, ", "))
add("  children: %s", table.concat(kids, ", "))
end
end
add("-- workspace children")
for _, k in ipairs(workspace:GetChildren()) do
add("%s:%s (%d)", k.Name, k.ClassName, #k:GetChildren())
end
local camera = workspace.CurrentCamera
if camera then
add("-- camera children")
for _, k in ipairs(camera:GetChildren()) do add("%s:%s", k.Name, k.ClassName) end
end
pcall(writefile, "Vigil-debug.txt", table.concat(lines, "\n"))
end
task.spawn(function()
local started = os.clock()
while os.clock() - started < 180 and ENV.Vigil ~= nil do
task.wait(5)
pcall(writeDump)
end
end)
local extentCache = setmetatable({}, { __mode = "k" })
local function bodyExtents(model, root)
local now = os.clock()
local c = extentCache[model]
if not c or now - c.at > 0.5 then
local ry = root.Position.Y
local up, down = 2.5, -3
local found = false
for _, part in ipairs(model:GetChildren()) do
if part:IsA("BasePart") then
local half, y = part.Size.Y / 2, part.Position.Y - ry
if not found then
up, down, found = y + half, y - half, true
else
if y + half > up then up = y + half end
if y - half < down then down = y - half end
end
end
end
c = { up = up, down = down, at = now }
extentCache[model] = c
end
return c.up, c.down
end
local ZERO = Vector3.zero
local SKELETON_R15 = {
{ "Head", ZERO, "UpperTorso", ZERO }, { "UpperTorso", ZERO, "LowerTorso", ZERO },
{ "UpperTorso", ZERO, "LeftUpperArm", ZERO }, { "LeftUpperArm", ZERO, "LeftLowerArm", ZERO },
{ "LeftLowerArm", ZERO, "LeftHand", ZERO }, { "UpperTorso", ZERO, "RightUpperArm", ZERO },
{ "RightUpperArm", ZERO, "RightLowerArm", ZERO }, { "RightLowerArm", ZERO, "RightHand", ZERO },
{ "LowerTorso", ZERO, "LeftUpperLeg", ZERO }, { "LeftUpperLeg", ZERO, "LeftLowerLeg", ZERO },
{ "LeftLowerLeg", ZERO, "LeftFoot", ZERO }, { "LowerTorso", ZERO, "RightUpperLeg", ZERO },
{ "RightUpperLeg", ZERO, "RightLowerLeg", ZERO }, { "RightLowerLeg", ZERO, "RightFoot", ZERO },
}
local NECK, HIP = Vector3.new(0, 1, 0), Vector3.new(0, -1, 0)
local LIMB_TOP, LIMB_END = Vector3.new(0, 0.9, 0), Vector3.new(0, -0.9, 0)
local SKELETON_R6 = {
{ "Head", ZERO, "Torso", NECK }, { "Torso", NECK, "Torso", HIP },
{ "Torso", NECK, "Left Arm", LIMB_TOP }, { "Left Arm", LIMB_TOP, "Left Arm", LIMB_END },
{ "Torso", NECK, "Right Arm", LIMB_TOP }, { "Right Arm", LIMB_TOP, "Right Arm", LIMB_END },
{ "Torso", HIP, "Left Leg", LIMB_TOP }, { "Left Leg", LIMB_TOP, "Left Leg", LIMB_END },
{ "Torso", HIP, "Right Leg", LIMB_TOP }, { "Right Leg", LIMB_TOP, "Right Leg", LIMB_END },
}
local MAX_BONES = 14
local HIDDEN_TINT = Color3.fromRGB(110, 110, 120)
local FILL_FADE = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.7), NumberSequenceKeypoint.new(1, 0.95) })
function outline(parent)
return new("UIStroke", { Thickness = 1, Color = World.outline, Transparency = 0.45, Parent = parent })
end
local function line(parent)
local f = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), BorderSizePixel = 0, Visible = false, Parent = parent })
outline(f)
return f
end
local function setLine(frame, a, b, thickness)
local d = b - a
frame.Size = UDim2.fromOffset(d.Magnitude, thickness)
frame.Position = UDim2.fromOffset((a.X + b.X) / 2, (a.Y + b.Y) / 2)
frame.Rotation = math.deg(math.atan2(d.Y, d.X))
end
local function createVisual(parent)
local o = { corners = {}, bones = {}, arrowParts = {} }
o.fill = new("Frame", { BorderSizePixel = 0, Visible = false, Parent = parent }, {
new("UIGradient", { Rotation = 90, Transparency = FILL_FADE }),
})
o.box = new("Frame", { BackgroundTransparency = 1, Visible = false, Parent = parent })
new("UIStroke", { Thickness = 3, Color = World.outline, Transparency = 0.5, Parent = o.box })
local inner = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Parent = o.box })
o.boxStroke = new("UIStroke", { Thickness = 1, Parent = inner })
for i = 1, 8 do
o.corners[i] = new("Frame", { BorderSizePixel = 0, Visible = false, Parent = parent })
outline(o.corners[i])
end
for i = 1, MAX_BONES do o.bones[i] = line(parent) end
o.tracer = line(parent)
o.name = new("TextLabel", {
AnchorPoint = Vector2.new(0.5, 1), Size = UDim2.fromOffset(260, 20), BackgroundTransparency = 1,
FontFace = Tokens.fontStrong, TextColor3 = World.label, TextStrokeTransparency = 0.45,
TextYAlignment = Enum.TextYAlignment.Bottom, Visible = false, Parent = parent,
})
o.info = new("TextLabel", {
AnchorPoint = Vector2.new(0.5, 0), Size = UDim2.fromOffset(260, 18), BackgroundTransparency = 1,
FontFace = Tokens.mono, TextColor3 = World.labelMuted, TextStrokeTransparency = 0.45,
TextYAlignment = Enum.TextYAlignment.Top, Visible = false, Parent = parent,
})
o.hpBg = new("Frame", {
BackgroundColor3 = World.outline, BackgroundTransparency = 0.35, BorderSizePixel = 0,
Visible = false, Parent = parent,
})
o.hp = new("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), BorderSizePixel = 0, Parent = o.hpBg })
o.hpText = new("TextLabel", {
AnchorPoint = Vector2.new(1, 0.5), Size = UDim2.fromOffset(40, 14), BackgroundTransparency = 1,
FontFace = Tokens.mono, TextColor3 = World.label, TextStrokeTransparency = 0.45,
TextXAlignment = Enum.TextXAlignment.Right, Visible = false, Parent = parent,
})
o.arrow = new("Frame", {
Size = UDim2.fromOffset(16, 16), AnchorPoint = Vector2.new(0.5, 0.5),
BackgroundTransparency = 1, Visible = false, Parent = parent,
})
for _, spec in ipairs({ { 5, 31 }, { 11, -31 } }) do
local f = new("Frame", {
Size = UDim2.fromOffset(11, 2.5), AnchorPoint = Vector2.new(0.5, 0.5),
Position = UDim2.fromOffset(8, spec[1]), Rotation = spec[2], BorderSizePixel = 0, Parent = o.arrow,
})
outline(f)
table.insert(o.arrowParts, f)
end
return o
end
local function hideBody(o)
o.fill.Visible = false
o.box.Visible = false
o.tracer.Visible = false
o.name.Visible = false
o.info.Visible = false
o.hpBg.Visible = false
o.hpText.Visible = false
for _, f in ipairs(o.corners) do f.Visible = false end
for _, f in ipairs(o.bones) do f.Visible = false end
end
local function hideVisual(o)
hideBody(o)
o.arrow.Visible = false
if o.highlight then o.highlight.Enabled = false end
end
local function destroyVisual(o)
for _, v in pairs(o) do
if typeof(v) == "Instance" then
v:Destroy()
elseif type(v) == "table" then
for _, x in ipairs(v) do
if typeof(x) == "Instance" then x:Destroy() end
end
end
end
end
local function renderVisual(o, t, project, view)
local char, root = t.char, t.root
local up, down = bodyExtents(char, root)
local rp = root.Position
local top, zTop = project(Vector3.new(rp.X, rp.Y + up + 0.15, rp.Z))
local bottom, zBottom = project(Vector3.new(rp.X, rp.Y + down - 0.1, rp.Z))
local size = view.size
local cx = (top.X + bottom.X) / 2
local offscreen = zTop <= 0 or zBottom <= 0 or cx < 0 or cx > size.X or bottom.Y < 0 or top.Y > size.Y
local colour = t.hidden and t.colour:Lerp(HIDDEN_TINT, 0.55) or t.colour
local showArrow = Settings.arrows and (offscreen or view.preview == true)
o.arrow.Visible = showArrow
if showArrow then
local pos, angle
if view.preview then
pos, angle = Vector2.new(size.X - 14, size.Y / 2), 0
else
local centre = size / 2
local dir = (top + bottom) / 2 - centre
if zTop <= 0 then dir = -dir end
if dir.Magnitude < 1 then dir = Vector2.new(0, 1) end
dir = dir.Unit
local radius = math.min(math.min(size.X, size.Y) / 2 - 48, 220)
pos, angle = centre + dir * radius, math.deg(math.atan2(dir.Y, dir.X))
end
o.arrow.Position = UDim2.fromOffset(pos.X, pos.Y)
o.arrow.Rotation = angle
for _, f in ipairs(o.arrowParts) do f.BackgroundColor3 = colour end
end
if offscreen then
hideBody(o)
return
end
local h = math.floor(math.max(bottom.Y - top.Y, 6))
local w = math.floor(math.max(h * 0.55, 4))
local left, y = math.floor(cx - w / 2), math.floor(top.Y)
local right, base = left + w, y + h
o.fill.Visible = Settings.boxFill
if Settings.boxFill then
o.fill.Position = UDim2.fromOffset(left, y)
o.fill.Size = UDim2.fromOffset(w, h)
o.fill.BackgroundColor3 = colour
end
local full = Settings.boxes and Settings.boxStyle == "Full"
o.box.Visible = full
if full then
o.box.Position = UDim2.fromOffset(left, y)
o.box.Size = UDim2.fromOffset(w, h)
o.boxStroke.Color = colour
end
if Settings.boxes and Settings.boxStyle == "Corners" then
local len, th = math.max(math.floor(math.min(w, h) * 0.28), 4), 2
local spec = {
{ left, y, len, th }, { left, y, th, len },
{ right - len, y, len, th }, { right - th, y, th, len },
{ left, base - th, len, th }, { left, base - len, th, len },
{ right - len, base - th, len, th }, { right - th, base - len, th, len },
}
for i, f in ipairs(o.corners) do
local s = spec[i]
f.Position = UDim2.fromOffset(s[1], s[2])
f.Size = UDim2.fromOffset(s[3], s[4])
f.BackgroundColor3 = colour
f.Visible = true
end
else
for _, f in ipairs(o.corners) do f.Visible = false end
end
o.name.Visible = Settings.names
if Settings.names then
o.name.Text = t.name
o.name.TextSize = Settings.textSize + 1
o.name.Position = UDim2.fromOffset(cx, y - 4)
end
local info = {}
if Settings.distance then table.insert(info, string.format("%d studs", math.floor(t.distance))) end
if Settings.item and t.item then table.insert(info, t.item) end
o.info.Visible = #info > 0
if #info > 0 then
o.info.Text = table.concat(info, "  ·  ")
o.info.TextSize = math.max(Settings.textSize - 1, 11)
o.info.Position = UDim2.fromOffset(cx, base + 4)
end
local showHealth = Settings.health and t.health ~= nil
o.hpBg.Visible = showHealth
o.hpText.Visible = showHealth and t.health < 0.995
if showHealth then
local ratio = t.health
o.hpBg.Position = UDim2.fromOffset(left - 7, y - 1)
o.hpBg.Size = UDim2.fromOffset(4, h + 2)
o.hp.Size = UDim2.fromScale(1, ratio)
o.hp.BackgroundColor3 = World.healthLow:Lerp(World.healthHigh, ratio)
if o.hpText.Visible then
o.hpText.Text = tostring(t.healthValue)
o.hpText.TextSize = math.max(Settings.textSize - 2, 11)
o.hpText.Position = UDim2.fromOffset(left - 11, y + h * (1 - ratio))
end
end
o.tracer.Visible = Settings.tracers
if Settings.tracers then
setLine(o.tracer, view.tracerFrom, Vector2.new(cx, base), 1.5)
o.tracer.BackgroundColor3 = colour
end
local used = 0
if Settings.skeleton then
local bones = char:FindFirstChild("UpperTorso") and SKELETON_R15 or SKELETON_R6
for _, b in ipairs(bones) do
local pa, pb = char:FindFirstChild(b[1]), char:FindFirstChild(b[3])
if pa and pb and pa:IsA("BasePart") and pb:IsA("BasePart") then
local a, za = project(pa.CFrame * b[2])
local c, zc = project(pb.CFrame * b[4])
if za > 0 and zc > 0 and used < MAX_BONES then
used += 1
local f = o.bones[used]
setLine(f, a, c, 1.5)
f.BackgroundColor3 = colour
f.Visible = true
end
end
end
end
for i = used + 1, MAX_BONES do o.bones[i].Visible = false end
end
Esp = {}
local function createEsp(player)
if player == LocalPlayer or Esp[player] then return end
local o = createVisual(espGui)
o.highlight = new("Highlight", {
FillTransparency = 0.75, OutlineTransparency = 0, DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
Enabled = false, Parent = highlightFolder,
})
Esp[player] = o
end
function removeEsp(player)
local o = Esp[player]
if not o then return end
destroyVisual(o)
Esp[player] = nil
end
function espStep()
local camera = workspace.CurrentCamera
if not camera then return end
local size = camera.ViewportSize
local camPos = camera.CFrame.Position
local function project(p)
local v = camera:WorldToViewportPoint(p)
return Vector2.new(v.X, v.Y), v.Z
end
local from
if Settings.tracerOrigin == "Centre" then
from = size / 2
elseif Settings.tracerOrigin == "Mouse" then
from = UserInputService:GetMouseLocation()
else
from = Vector2.new(size.X / 2, size.Y)
end
local view = { size = size, tracerFrom = from }
local baseColour = EspColours[Settings.espColour][2]
for player, o in pairs(Esp) do
local char, hum = bodyOf(player)
local root = char and bodyRoot(char)
local alive = root ~= nil and (hum == nil or hum.Health > 0)
if not (Settings.enabled and alive) or (Settings.teamCheck and isTeammate(player)) then
hideVisual(o)
continue
end
local distance = (camPos - root.Position).Magnitude
if distance > Settings.maxDistance then
hideVisual(o)
continue
end
local colour = (Settings.teamColour and player.Team) and player.TeamColor.Color or baseColour
local hidden = Settings.visCheck and not isVisible(camera, root, char, player.Character)
local tool = char:FindFirstChildOfClass("Tool") or (player.Character and player.Character:FindFirstChildOfClass("Tool"))
local hl = o.highlight
if Settings.highlight then
local glow = hidden and colour:Lerp(HIDDEN_TINT, 0.55) or colour
if hl.Adornee ~= char then hl.Adornee = char end
if o.glow ~= glow then
o.glow = glow
hl.FillColor = glow
hl.OutlineColor = glow
end
if not hl.Enabled then hl.Enabled = true end
elseif hl.Enabled then
hl.Enabled = false
end
renderVisual(o, {
char = char, root = root, colour = colour, hidden = hidden,
name = player.DisplayName, distance = distance, item = tool and tool.Name,
health = hum and math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1),
healthValue = hum and math.floor(hum.Health + 0.5),
}, project, view)
end
end
for _, player in ipairs(Players:GetPlayers()) do createEsp(player) end
connect(Players.PlayerAdded, createEsp)
connect(Players.PlayerRemoving, removeEsp)
do
local vf = previewUI.viewport
local W, H = previewUI.width, previewUI.height
local DUMMY = Color3.fromRGB(150, 150, 160)
local cam = new("Camera", { FieldOfView = 38, Parent = vf })
cam.CFrame = CFrame.lookAt(Vector3.new(0, 0.3, 13), Vector3.new(0, -0.5, 0))
vf.CurrentCamera = cam
local model = new("Model", { Name = "TestPlayer" })
local tinted = {}
local function part(name, size, pos)
local p = new("Part", {
Name = name, Size = size, CFrame = CFrame.new(pos), Anchored = true, CanCollide = false,
Material = Enum.Material.SmoothPlastic, Color = DUMMY, TopSurface = Enum.SurfaceType.Smooth,
BottomSurface = Enum.SurfaceType.Smooth, Parent = model,
})
table.insert(tinted, p)
return p
end
local root = part("HumanoidRootPart", Vector3.new(2, 2, 1), Vector3.zero)
root.Transparency = 1
table.remove(tinted)
part("Torso", Vector3.new(2, 2, 1), Vector3.zero)
local head = part("Head", Vector3.new(2, 1, 1), Vector3.new(0, 1.5, 0))
new("SpecialMesh", { MeshType = Enum.MeshType.Head, Scale = Vector3.new(1.25, 1.25, 1.25), Parent = head })
part("Left Arm", Vector3.new(1, 2, 1), Vector3.new(-1.5, 0, 0))
part("Right Arm", Vector3.new(1, 2, 1), Vector3.new(1.5, 0, 0))
part("Left Leg", Vector3.new(1, 2, 1), Vector3.new(-0.5, -2, 0))
part("Right Leg", Vector3.new(1, 2, 1), Vector3.new(0.5, -2, 0))
model.PrimaryPart = root
model.Parent = vf
local o = createVisual(previewUI.overlay)
local view = { size = Vector2.new(W, H), tracerFrom = Vector2.new(W / 2, H), preview = true }
local tanY = math.tan(math.rad(cam.FieldOfView) / 2)
local function project(p)
local rel = cam.CFrame:PointToObjectSpace(p)
local z = -rel.Z
if z <= 0.01 then return Vector2.zero, -1 end
local x = rel.X / z / (tanY * W / H)
local y = rel.Y / z / tanY
return Vector2.new((x + 1) / 2 * W, (1 - y) / 2 * H), z
end
local angle = 0.5
connect(RunService.RenderStepped, function(dt)
if not (Holder.Visible and previewUI.panel.Visible) then return end
previewUI.renderChips()
if not reducedMotion then angle = (angle + dt * 0.5) % (math.pi * 2) end
model:PivotTo(CFrame.Angles(0, angle, 0))
local colour = EspColours[Settings.espColour][2]
for _, p in ipairs(tinted) do
p.Color = Settings.highlight and DUMMY:Lerp(colour, 0.6) or DUMMY
end
renderVisual(o, {
char = model, root = root, colour = colour, hidden = false, name = "Test player",
distance = 48, item = "Pistol", health = 0.72, healthValue = 72,
}, project, view)
end)
end
end
local RENDER_STEP, findTarget, circle, placeCircle
do
RENDER_STEP = "VigilRender"
local function candidateParts(char, mode)
local head = char:FindFirstChild("Head")
local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") or char:FindFirstChild("HumanoidRootPart")
if mode == "Head" then return { head } end
if mode == "Torso" then return { torso } end
return { head, torso } -- "Closest": whichever sits nearer the cursor
end
local function evaluate(player, camera, mouse, cfg)
local char, hum = bodyOf(player)
if not char or (hum and hum.Health <= 0) then return end
if cfg.team and isTeammate(player) then return end
local camPos = camera.CFrame.Position
local best, bestScreen, bestWorld
for _, part in pairs(candidateParts(char, cfg.part)) do
local worldDist = (camPos - part.Position).Magnitude
if worldDist <= cfg.maxDistance then
local screen, onScreen = camera:WorldToViewportPoint(part.Position)
if onScreen then
local screenDist = (Vector2.new(screen.X, screen.Y) - mouse).Magnitude
if screenDist <= cfg.fov and (not bestScreen or screenDist < bestScreen)
and (not cfg.visible or isVisible(camera, part, char, player.Character)) then
best, bestScreen, bestWorld = part, screenDist, worldDist
end
end
end
end
return best, bestScreen, bestWorld
end
function findTarget(camera, mouse, cfg, current)
if current and current.Parent then
local part = evaluate(current, camera, mouse, cfg)
if part then return current, part end
end
local bestPlayer, bestPart, bestScore
for _, player in ipairs(Players:GetPlayers()) do
if player ~= LocalPlayer then
local part, screenDist, worldDist = evaluate(player, camera, mouse, cfg)
if part then
local score = cfg.priority == "Distance" and worldDist or screenDist
if not bestScore or score < bestScore then
bestPlayer, bestPart, bestScore = player, part, score
end
end
end
end
return bestPlayer, bestPart
end
function circle(filled)
local frame = new("Frame", {
AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = World.label,
BackgroundTransparency = filled and 0.94 or 1, BorderSizePixel = 0, Visible = false, Parent = espGui,
}, { round("full") })
local stroke = new("UIStroke", { Thickness = 1, Transparency = 0.25, Color = World.label, Parent = frame })
return frame, stroke
end
function placeCircle(frame, stroke, visible, centre, radius, locked)
frame.Visible = visible
if not visible then return end
frame.Position = UDim2.fromOffset(centre.X, centre.Y)
frame.Size = UDim2.fromOffset(radius * 2, radius * 2)
stroke.Thickness = locked and 2 or 1
stroke.Color = locked and P.accent or World.label
stroke.Transparency = locked and 0 or 0.25
end
end
local motion, aimStep
do
local fovCircle, fovStroke = circle(false)
local currentTarget
motion = setmetatable({}, { __mode = "k" })
local function measuredVelocity(part)
local now, pos = os.clock(), part.Position
local m = motion[part]
if not m then
motion[part] = { pos = pos, vel = Vector3.zero, at = now }
return Vector3.zero
end
local dt = now - m.at
if dt > 0.001 then
local v = dt < 0.25 and (pos - m.pos) / dt or Vector3.zero
m.vel = m.vel:Lerp(v, 0.35)
m.pos, m.at = pos, now
end
return m.vel
end
function aimStep(camera, mouse, dt)
if Settings.aimMode ~= "Toggle" or not Settings.aimEnabled then aimToggled = false end
local active = false
if Settings.aimEnabled and not keyCapture and not UserInputService:GetFocusedTextBox() then
if Settings.aimMode == "Always" then
active = true
elseif Settings.aimMode == "Toggle" then
active = aimToggled
else
active = isBindDown(Settings.aimKey)
end
end
local part
if active then
currentTarget, part = findTarget(camera, mouse, {
part = Settings.aimPart, team = Settings.aimTeamCheck, visible = Settings.visibleOnly,
maxDistance = Settings.aimMaxDistance, fov = Settings.fov, priority = Settings.aimPriority,
}, Settings.stickyTarget and currentTarget or nil)
else
currentTarget = nil
end
placeCircle(fovCircle, fovStroke, Settings.aimEnabled and Settings.showFov, mouse, Settings.fov, part ~= nil)
if not part then return end
local aimPos = part.Position
if Settings.prediction > 0 then
aimPos += measuredVelocity(part) * (Settings.prediction / 1000)
end
local alpha = Settings.smoothing <= 1 and 1 or 1 - (1 - 1 / Settings.smoothing) ^ (dt * 60)
if Settings.aimMethod == "Mouse" and canMoveMouse then
local screen = camera:WorldToViewportPoint(aimPos)
local delta = (Vector2.new(screen.X, screen.Y) - mouse) * alpha
mousemoverel(delta.X, delta.Y)
else
local cf = camera.CFrame
camera.CFrame = cf:Lerp(CFrame.lookAt(cf.Position, aimPos), alpha)
end
end
end
local hookState, silent, silentStep
do
hookState = { alive = true }
silent = { active = false, mouse = Vector2.zero, inset = Vector2.zero }
local silentCircle, silentStroke = circle(true)
local marker = new("Frame", {
Size = UDim2.fromOffset(14, 14), AnchorPoint = Vector2.new(0.5, 0.5),
BackgroundTransparency = 1, Visible = false, Parent = espGui,
}, { round("full") })
local markerStroke = new("UIStroke", { Thickness = 2, Parent = marker })
function silentStep(camera, mouse)
local inset = GuiService:GetGuiInset()
silent.mouse, silent.inset = mouse, inset
local enabled = canHook and Settings.silentEnabled
local part
if enabled then
local _
_, part = findTarget(camera, mouse, {
part = Settings.silentPart, team = Settings.silentTeamCheck, visible = Settings.silentVisibleOnly,
maxDistance = Settings.silentMaxDistance, fov = Settings.silentFov, priority = "Crosshair",
})
end
placeCircle(silentCircle, silentStroke, enabled and Settings.showSilentFov, mouse, Settings.silentFov, part ~= nil)
if not part then
silent.active = false
marker.Visible = false
return
end
local camPos = camera.CFrame.Position
local pos = part.Position
local unit = (pos - camPos).Unit
local screen = camera:WorldToViewportPoint(pos)
local mouseRay = camera:ViewportPointToRay(mouse.X, mouse.Y)
silent.part = part
silent.position = pos
silent.aimPoint = mouseRay.Origin + mouseRay.Direction * 1000
silent.hitCFrame = CFrame.lookAt(pos, pos + unit)
silent.unitRay = Ray.new(camPos, unit)
silent.screen = Vector2.new(screen.X, screen.Y) - inset
silent.active = math.random(1, 100) <= Settings.hitChance
marker.Visible = Settings.showSilentTarget
marker.Position = UDim2.fromOffset(screen.X, screen.Y)
markerStroke.Color = P.accent
end
local function redirect(origin, direction)
local length = direction.Magnitude
if length < 1e-3 then return end
local toAim = silent.aimPoint - origin
if toAim.Magnitude < 1e-3 or direction.Unit:Dot(toAim.Unit) < 0.85 then return end
local toTarget = silent.position - origin
return toTarget.Unit * math.max(length, toTarget.Magnitude * 1.05)
end
local RayMethods = { FindPartOnRay = true, FindPartOnRayWithIgnoreList = true, FindPartOnRayWithWhitelist = true }
if canHook then
local wrap = typeof(newcclosure) == "function" and newcclosure or function(f) return f end
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", wrap(function(self, ...)
if hookState.alive and silent.active and not checkcaller() then
local method = getnamecallmethod()
if method == "Raycast" and Settings.silentRaycast then
local origin, direction = ...
if typeof(origin) == "Vector3" and typeof(direction) == "Vector3" then
local bent = redirect(origin, direction)
if bent then
local args = table.pack(...)
args[2] = bent
return oldNamecall(self, table.unpack(args, 1, args.n))
end
end
elseif RayMethods[method] and Settings.silentRaycast then
local ray = ...
if typeof(ray) == "Ray" then
local bent = redirect(ray.Origin, ray.Direction)
if bent then
local args = table.pack(...)
args[1] = Ray.new(ray.Origin, bent)
return oldNamecall(self, table.unpack(args, 1, args.n))
end
end
elseif (method == "ViewportPointToRay" or method == "ScreenPointToRay") and Settings.silentCameraRays then
local x, y = ...
local ref = method == "ViewportPointToRay" and silent.mouse or (silent.mouse - silent.inset)
if typeof(x) == "number" and typeof(y) == "number" and (Vector2.new(x, y) - ref).Magnitude < 30 then
local ray = oldNamecall(self, ...)
return Ray.new(ray.Origin, (silent.position - ray.Origin).Unit)
end
end
end
return oldNamecall(self, ...)
end))
local mouseObject = LocalPlayer:GetMouse()
local oldIndex
oldIndex = hookmetamethod(game, "__index", wrap(function(self, key)
if hookState.alive and silent.active and rawequal(self, mouseObject) and Settings.silentMouse and not checkcaller() then
if key == "Hit" then
return silent.hitCFrame
elseif key == "Target" then
return silent.part
elseif key == "UnitRay" then
return silent.unitRay
elseif key == "X" then
return silent.screen.X
elseif key == "Y" then
return silent.screen.Y
end
end
return oldIndex(self, key)
end))
end
end
local enforce, release, releaseAll, visualsStep
do
local Lighting = game:GetService("Lighting")
local saved = setmetatable({}, { __mode = "k" })
function enforce(inst, prop, value)
local s = saved[inst]
if not s then
s = {}
saved[inst] = s
end
if s[prop] == nil then s[prop] = inst[prop] end
if inst[prop] ~= value then inst[prop] = value end
end
function release(inst, prop)
local s = saved[inst]
if s and s[prop] ~= nil then
pcall(function() inst[prop] = s[prop] end)
s[prop] = nil
end
end
function releaseAll()
for inst, props in pairs(saved) do
for prop, value in pairs(props) do
pcall(function() inst[prop] = value end)
end
end
table.clear(saved)
end
local function override(on, inst, props)
for prop, value in pairs(props) do
if on then enforce(inst, prop, value) else release(inst, prop) end
end
end
local FULLBRIGHT = {
Brightness = 2, GlobalShadows = false,
Ambient = Color3.fromRGB(178, 178, 178), OutdoorAmbient = Color3.fromRGB(178, 178, 178),
}
local NO_FOG = { FogEnd = 1e9 }
local NO_ATMOSPHERE = { Density = 0, Haze = 0 }
local crosshairArms = {}
for i = 1, 4 do
crosshairArms[i] = new("Frame", {
AnchorPoint = Vector2.new(0.5, 0.5), BorderSizePixel = 0, Visible = false, Parent = espGui,
}, { new("UIStroke", { Thickness = 1, Color = World.outline, Transparency = 0.5 }) })
end
local crosshairDot = new("Frame", {
Size = UDim2.fromOffset(2, 2), AnchorPoint = Vector2.new(0.5, 0.5), BorderSizePixel = 0,
Visible = false, Parent = espGui,
}, { new("UIStroke", { Thickness = 1, Color = World.outline, Transparency = 0.5 }) })
local ARM_DIRECTIONS = { Vector2.new(0, -1), Vector2.new(0, 1), Vector2.new(-1, 0), Vector2.new(1, 0) }
local atmosphereScan = 0
function visualsStep(camera, mouse)
override(Settings.fullbright, Lighting, FULLBRIGHT)
override(Settings.noFog, Lighting, NO_FOG)
local now = os.clock()
if now - atmosphereScan > 1 then
atmosphereScan = now
for _, child in ipairs(Lighting:GetChildren()) do
if child:IsA("Atmosphere") then override(Settings.noFog, child, NO_ATMOSPHERE) end
end
end
if Settings.lockTime then enforce(Lighting, "ClockTime", Settings.timeOfDay) else release(Lighting, "ClockTime") end
if Settings.camFovEnabled then enforce(camera, "FieldOfView", Settings.camFov) else release(camera, "FieldOfView") end
local on = Settings.crosshair
crosshairDot.Visible = on
for _, arm in ipairs(crosshairArms) do arm.Visible = on end
if on then
enforce(UserInputService, "MouseIconEnabled", false)
local size, offset = Settings.crosshairSize, Settings.crosshairGap + Settings.crosshairSize / 2
for i, arm in ipairs(crosshairArms) do
local d = ARM_DIRECTIONS[i]
arm.Position = UDim2.fromOffset(mouse.X + d.X * offset, mouse.Y + d.Y * offset)
arm.Size = d.X == 0 and UDim2.fromOffset(2, size) or UDim2.fromOffset(size, 2)
arm.BackgroundColor3 = P.accent
end
crosshairDot.Position = UDim2.fromOffset(mouse.X, mouse.Y)
crosshairDot.BackgroundColor3 = P.accent
else
release(UserInputService, "MouseIconEnabled")
end
end
end
local fly, noclipped, localCharacter, stopFly
do
fly = {}
noclipped = {}
function localCharacter()
local char = LocalPlayer.Character
local hum = char and char:FindFirstChildOfClass("Humanoid")
local root = char and char:FindFirstChild("HumanoidRootPart")
return char, hum, root
end
local function keyDown(code)
return UserInputService:IsKeyDown(code)
end
local function flyDirection(camera)
if UserInputService:GetFocusedTextBox() then return Vector3.zero end
local cf = camera.CFrame
local dir = Vector3.zero
if keyDown(Enum.KeyCode.W) then dir += cf.LookVector end
if keyDown(Enum.KeyCode.S) then dir -= cf.LookVector end
if keyDown(Enum.KeyCode.D) then dir += cf.RightVector end
if keyDown(Enum.KeyCode.A) then dir -= cf.RightVector end
if keyDown(Enum.KeyCode.Space) or keyDown(Enum.KeyCode.E) then dir += Vector3.yAxis end
if keyDown(Enum.KeyCode.LeftControl) or keyDown(Enum.KeyCode.Q) then dir -= Vector3.yAxis end
return dir.Magnitude > 0 and dir.Unit or dir
end
function stopFly(hum)
for _, inst in pairs(fly) do inst:Destroy() end
table.clear(fly)
if hum then release(hum, "PlatformStand") end
end
local function movementStep()
local camera = workspace.CurrentCamera
local _, hum, root = localCharacter()
if not (camera and hum and root) then return end
if Settings.speedEnabled then enforce(hum, "WalkSpeed", Settings.walkSpeed) else release(hum, "WalkSpeed") end
if Settings.jumpEnabled then
if hum.UseJumpPower then
enforce(hum, "JumpPower", Settings.jumpPower)
else
enforce(hum, "JumpHeight", Settings.jumpPower ^ 2 / (2 * workspace.Gravity))
end
else
release(hum, "JumpPower")
release(hum, "JumpHeight")
end
if Settings.fly then
if not (fly.attachment and fly.attachment.Parent == root) then
stopFly()
fly.attachment = new("Attachment", { Name = "VigilFly", Parent = root })
fly.velocity = new("LinearVelocity", {
Attachment0 = fly.attachment, VelocityConstraintMode = Enum.VelocityConstraintMode.Vector,
RelativeTo = Enum.ActuatorRelativeTo.World, MaxForce = math.huge, Parent = root,
})
fly.gyro = new("AlignOrientation", {
Attachment0 = fly.attachment, Mode = Enum.OrientationAlignmentMode.OneAttachment,
MaxTorque = math.huge, Responsiveness = 200, Parent = root,
})
end
enforce(hum, "PlatformStand", true)
fly.velocity.VectorVelocity = flyDirection(camera) * Settings.flySpeed
local look = camera.CFrame.LookVector
local flat = Vector3.new(look.X, 0, look.Z)
if flat.Magnitude > 0.01 then
fly.gyro.CFrame = CFrame.lookAt(Vector3.zero, flat)
end
elseif fly.attachment then
stopFly(hum)
end
end
local function noclipStep()
local char = LocalPlayer.Character
if Settings.noclip and char then
for _, part in ipairs(char:GetDescendants()) do
if part:IsA("BasePart") and part.CanCollide then
part.CanCollide = false
noclipped[part] = true
end
end
elseif next(noclipped) then
for part in pairs(noclipped) do
if part.Parent then part.CanCollide = true end
end
table.clear(noclipped)
end
end
local teleportParams = RaycastParams.new()
teleportParams.FilterType = Enum.RaycastFilterType.Exclude
local function clickTeleport()
local camera = workspace.CurrentCamera
local char, hum, root = localCharacter()
if not (camera and hum and root) then return end
local mouse = UserInputService:GetMouseLocation()
local ray = camera:ViewportPointToRay(mouse.X, mouse.Y)
teleportParams.FilterDescendantsInstances = { char, camera }
local hit = workspace:Raycast(ray.Origin, ray.Direction * 5000, teleportParams)
if hit then
root.CFrame = CFrame.new(hit.Position + Vector3.new(0, hum.HipHeight + root.Size.Y / 2 + 0.5, 0)) * root.CFrame.Rotation
end
end
connect(UserInputService.JumpRequest, function()
if not Settings.infiniteJump then return end
local _, hum = localCharacter()
if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
end)
connect(UserInputService.InputBegan, function(input, gameProcessed)
if keyCapture or input == consumedInput or UserInputService:GetFocusedTextBox() then return end
local name = inputName(input)
if name == Settings.flyKey then
Settings.fly = not Settings.fly
save()
renderFlySwitch()
elseif name == "MouseButton1" and Settings.clickTp and not gameProcessed and keyDown(Enum.KeyCode.LeftControl) then
clickTeleport()
end
end)
connect(RunService.Stepped, noclipStep)
connect(RunService.Heartbeat, movementStep)
end
RunService:BindToRenderStep(RENDER_STEP, Enum.RenderPriority.Camera.Value + 1, function(dt)
local camera = workspace.CurrentCamera
if not camera then return end
local mouse = UserInputService:GetMouseLocation()
visualsStep(camera, mouse)
silentStep(camera, mouse)
aimStep(camera, mouse, dt)
espStep() -- last, so boxes use this frame's final camera and never trail behind
end)
do
local modulesList = new("Frame", {
Name = "ActiveModules", AnchorPoint = Vector2.new(1, 0),
Position = UDim2.new(1, -Tokens.space.lg, 0, Tokens.space.lg),
AutomaticSize = Enum.AutomaticSize.XY, Size = UDim2.fromOffset(0, 0),
BackgroundTransparency = 1, Parent = menuGui,
}, {
new("UIListLayout", {
Padding = UDim.new(0, 2), HorizontalAlignment = Enum.HorizontalAlignment.Right,
SortOrder = Enum.SortOrder.LayoutOrder,
}),
})
local moduleRows = {}
local function moduleRow(i)
if moduleRows[i] then return moduleRows[i] end
local frame = new("Frame", {
AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 26), BorderSizePixel = 0,
BackgroundTransparency = 0.1, LayoutOrder = i, Parent = modulesList,
}, {
round(Tokens.radius.sm), padding(0, 6, 0, 10),
new("UIListLayout", {
FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, Tokens.space.sm),
VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder,
}),
})
bind(frame, "BackgroundColor3", "bg")
local label = new("TextLabel", {
AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 26), BackgroundTransparency = 1,
FontFace = Tokens.font, TextSize = Tokens.text.small + 1, RichText = true, LayoutOrder = 1, Parent = frame,
})
bind(label, "TextColor3", "text")
local bar = new("Frame", { Size = UDim2.fromOffset(2, 14), BorderSizePixel = 0, LayoutOrder = 2, Parent = frame }, { round("full") })
moduleRows[i] = { frame = frame, label = label, bar = bar }
return moduleRows[i]
end
local function activeModules()
local list = {}
local function add(on, name, detail)
if on then table.insert(list, { name, detail }) end
end
add(Settings.enabled, "ESP")
add(Settings.aimEnabled, "Aimbot", Settings.aimMode)
add(canHook and Settings.silentEnabled, "Silent aim", string.format("%d%%", Settings.hitChance))
add(Settings.fullbright, "Fullbright")
add(Settings.noFog, "No fog")
add(Settings.lockTime, "Lock time")
add(Settings.camFovEnabled, "Field of view", string.format("%d°", Settings.camFov))
add(Settings.crosshair, "Crosshair")
add(Settings.speedEnabled, "Speed", string.format("%d", Settings.walkSpeed))
add(Settings.jumpEnabled, "Jump power", string.format("%d", Settings.jumpPower))
add(Settings.infiniteJump, "Infinite jump")
add(Settings.fly, "Fly", string.format("%d", Settings.flySpeed))
add(Settings.noclip, "Noclip")
add(Settings.clickTp, "Click teleport")
table.sort(list, function(a, b)
local la, lb = #a[1] + #(a[2] or ""), #b[1] + #(b[2] or "")
if la ~= lb then return la > lb end
return a[1] < b[1]
end)
return list
end
local lastSignature
local modulesElapsed = 1
connect(RunService.Heartbeat, function(dt)
modulesElapsed += dt
if modulesElapsed < 0.2 then return end -- five updates a second is enough for a list
modulesElapsed = 0
modulesList.Visible = Settings.showModules
if not Settings.showModules then return end
local list = activeModules()
local parts = { Settings.theme, tostring(Settings.accent) }
for _, m in ipairs(list) do table.insert(parts, m[1] .. "|" .. (m[2] or "")) end
local signature = table.concat(parts, ";")
if signature == lastSignature then return end
lastSignature = signature
local mutedHex = P.muted:ToHex()
for i, m in ipairs(list) do
local r = moduleRow(i)
r.frame.Visible = true
r.label.Text = m[2] and string.format('%s <font color="#%s">%s</font>', m[1], mutedHex, m[2]) or m[1]
r.bar.BackgroundColor3 = P.accent
end
for i = #list + 1, #moduleRows do
moduleRows[i].frame.Visible = false
end
end)
end
unload = function()
pcall(function() RunService:UnbindFromRenderStep(RENDER_STEP) end)
hookState.alive = false
silent.active = false
stopFly(select(2, localCharacter()))
for part in pairs(noclipped) do
if part.Parent then part.CanCollide = true end
end
releaseAll()
for _, c in ipairs(connections) do c:Disconnect() end
table.clear(connections)
for player in pairs(Esp) do removeEsp(player) end
espGui:Destroy()
menuGui:Destroy()
highlightFolder:Destroy()
if ENV.Vigil and ENV.Vigil.Unload == unload then ENV.Vigil = nil end
end
ENV.Vigil = { Unload = unload, Settings = Settings }
selectTab("esp")
applyTheme()
