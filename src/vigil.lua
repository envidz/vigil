--[[
	Vigil
	ESP menu. Toggle with Right Shift (rebindable under Settings).
	Re-executing replaces the running copy.
]]

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

--------------------------------------------------------------------------------
-- Design tokens (the only place colours, sizes and motion are defined)
--------------------------------------------------------------------------------

local Tokens = {
	space = { xs = 4, sm = 8, md = 12, lg = 16 },
	radius = { sm = 7, md = 9, card = 14, lg = 18 },
	text = { body = 14, small = 12, title = 42 },
	size = { side = 204, header = 122, row = 50, control = 30, window = Vector2.new(920, 600), minWindow = Vector2.new(640, 440) },
	stroke = 1,
	motion = 0.16,
	tooltipDelay = 0.4,
	fontRegular = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Regular),
	font = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Medium),
	fontStrong = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.SemiBold),
	mono = Font.new("rbxasset://fonts/families/RobotoMono.json", Enum.FontWeight.Regular),
}

local Themes = {
	Dark = {
		bg = Color3.fromRGB(12, 12, 11),
		surface = Color3.fromRGB(24, 24, 22),
		card = Color3.fromRGB(24, 24, 22),
		raised = Color3.fromRGB(42, 42, 38),
		hover = Color3.fromRGB(58, 58, 54),
		border = Color3.fromRGB(38, 38, 35),
		divider = Color3.fromRGB(38, 38, 35),
		text = Color3.fromRGB(244, 244, 240),
		muted = Color3.fromRGB(154, 154, 147),
		faint = Color3.fromRGB(104, 104, 98),
		nav = Color3.fromRGB(176, 176, 170),
		knob = Color3.fromRGB(244, 244, 240),
		danger = Color3.fromRGB(255, 122, 110),
		gradTop = Color3.fromRGB(58, 58, 56),
		gradBottom = Color3.fromRGB(22, 22, 21),
	},
	Light = {
		bg = Color3.fromRGB(246, 246, 243),
		surface = Color3.fromRGB(255, 255, 255),
		card = Color3.fromRGB(255, 255, 255),
		raised = Color3.fromRGB(228, 228, 223),
		hover = Color3.fromRGB(214, 214, 209),
		border = Color3.fromRGB(224, 224, 219),
		divider = Color3.fromRGB(232, 232, 227),
		text = Color3.fromRGB(22, 22, 20),
		muted = Color3.fromRGB(100, 100, 94),
		faint = Color3.fromRGB(140, 140, 134),
		nav = Color3.fromRGB(84, 84, 78),
		knob = Color3.fromRGB(255, 255, 255),
		danger = Color3.fromRGB(204, 54, 54),
		gradTop = Color3.fromRGB(222, 222, 218),
		gradBottom = Color3.fromRGB(246, 246, 243),
	},
}

-- Mono has no colour of its own: controls take the theme's text colour
local Accents = {
	{ "Mono" },
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

--------------------------------------------------------------------------------
-- Settings (persisted when the executor supports file access)
--------------------------------------------------------------------------------

local SAVE_FILE = "Vigil.json"
local GAME_FILE = "Vigil-" .. tostring(game.GameId ~= 0 and game.GameId or game.PlaceId) .. ".json" -- used when "per game" is on

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
	npcEsp = false,
	friendsAsTeam = false,
	allyKey = "Z",
	triggerEnabled = false,
	triggerMode = "Always",
	triggerFire = "Hold",
	triggerDelay = 40,
	triggerRate = 10,
	radarEnabled = false,
	radarRange = 200,
	radarTeam = true,
	panicKey = "End",
	perGame = false,
	showLoader = true,
	antiAfk = false,
	freecamKey = "P",
	freecamSpeed = 60,
	spin = false,
	spinSpeed = 8,
	hitmarker = false,
	hitSound = true,
	bodySource = "Auto",
	aimEnabled = false,
	aimKey = "MouseButton2",
	aimMode = "Hold",
	aimPart = "Head",
	aimPriority = "Crosshair",
	aimTeamCheck = true,
	aimTargets = "Players",
	visibleOnly = false,
	stickyTarget = true,
	aimMaxDistance = 1000,
	fov = 120,
	showFov = true,
	smoothing = 4,
	prediction = 0,
	aimMethod = "Auto",
	silentEnabled = false,
	silentPart = "Head",
	hitChance = 100,
	silentTeamCheck = true,
	silentTargets = "Players",
	silentVisibleOnly = false,
	silentMaxDistance = 1000,
	silentFov = 150,
	showSilentFov = true,
	showSilentTarget = true,
	silentRaycast = true,
	silentMouse = true,
	silentCameraRays = false,
	silentRemotes = true,
	silentWalls = false,
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
	accentColour = 1,
	menuKey = "RightShift",
	menuW = 0, -- 0 means the default window size
	menuH = 0,
}

local canSave = typeof(writefile) == "function" and typeof(readfile) == "function" and typeof(isfile) == "function"

if canSave then
	pcall(function()
		local function apply(path, keepPerGame)
			if not isfile(path) then return end
			local data = HttpService:JSONDecode(readfile(path))
			for k, v in pairs(data) do
				if Settings[k] ~= nil and typeof(v) == typeof(Settings[k]) and not (keepPerGame and k == "perGame") then
					Settings[k] = v
				end
			end
		end
		apply(SAVE_FILE)
		if Settings.perGame then apply(GAME_FILE, true) end
	end)
	if not pcall(function() return Enum.KeyCode[Settings.menuKey] end) then
		Settings.menuKey = "RightShift"
	end
	if not Themes[Settings.theme] then Settings.theme = "Dark" end
	if not Accents[Settings.accentColour] then Settings.accentColour = 1 end
	if not EspColours[Settings.espColour] then Settings.espColour = 1 end
end

local saveQueued = false
local function save()
	if not canSave or saveQueued then return end
	saveQueued = true
	task.delay(0.5, function()
		saveQueued = false
		if Settings.perGame then
			pcall(writefile, GAME_FILE, HttpService:JSONEncode(Settings))
			-- the shared file only learns that this game keeps its own settings
			pcall(function()
				local shared = isfile(SAVE_FILE) and HttpService:JSONDecode(readfile(SAVE_FILE)) or {}
				if shared.perGame ~= true then
					shared.perGame = true
					writefile(SAVE_FILE, HttpService:JSONEncode(shared))
				end
			end)
		else
			pcall(writefile, SAVE_FILE, HttpService:JSONEncode(Settings))
		end
	end)
end

--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------

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

-- Like tween, but with a chosen curve: Quint for things arriving, Back for a little spring
local function tweenStyle(inst, props, duration, style, direction)
	if reducedMotion then
		for k, v in pairs(props) do inst[k] = v end
		return
	end
	TweenService:Create(inst, TweenInfo.new(duration, style or Enum.EasingStyle.Quint, direction or Enum.EasingDirection.Out), props):Play()
end

local function prettyKey(name)
	return (name:gsub("(%l)(%u)", "%1 %2"):gsub("(%a)(%d)", "%1 %2"))
end

-- Binds are stored as a KeyCode name or a mouse button UserInputType name
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

--------------------------------------------------------------------------------
-- Theming
--------------------------------------------------------------------------------

local P -- active palette
local themed, refreshers = {}, {}

local function buildPalette()
	local p = table.clone(Themes[Settings.theme])
	local colour = Accents[Settings.accentColour][2]
	p.accent = colour or p.text
	p.onAccent = colour and Color3.new(1, 1, 1) or p.bg
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

--------------------------------------------------------------------------------
-- Root containers
--------------------------------------------------------------------------------

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

--------------------------------------------------------------------------------
-- Icons (Lucide images, white on transparent so they can be tinted)
--------------------------------------------------------------------------------
local ICONS = {
	aim = "rbxassetid://10709818534",
	silent = "rbxassetid://10734977012",
	trigger = "rbxassetid://10734898355",
	esp = "rbxassetid://10734942198",
	visuals = "rbxassetid://10709811939",
	movement = "rbxassetid://10734900011",
	players = "rbxassetid://10747373426",
	settings = "rbxassetid://10734950309",
	search = "rbxassetid://10734943674",
	close = "rbxassetid://10747384394",
	eye = "rbxassetid://10723346959",
	games = "rbxassetid://10723395215",
	discord = "rbxthumb://type=Asset&id=132364423955781&w=150&h=150",
}

-- returns the image and a function that tints it
local function iconImage(id, size, parent)
	local image = new("ImageLabel", {
		Size = UDim2.fromOffset(size, size), BackgroundTransparency = 1, Image = ICONS[id], ZIndex = 2, Parent = parent,
	})
	return image, function(c) image.ImageColor3 = c end
end

--------------------------------------------------------------------------------
-- Window
--------------------------------------------------------------------------------

-- Holder carries position, scale and visibility
local UI = { cards = {}, index = {} } -- shared menu parts, kept in one table to spare the main chunk's registers
local Holder = new("Frame", {
	Name = "Holder", Size = UDim2.fromOffset(Tokens.size.window.X, Tokens.size.window.Y),
	AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
	BackgroundTransparency = 1, Parent = menuGui,
})
local windowScale = new("UIScale", { Parent = Holder })

local Window = new("Frame", {
	Name = "Window", Size = UDim2.fromScale(1, 1), BorderSizePixel = 0, Active = true, ZIndex = 1, Parent = Holder,
}, { round(Tokens.radius.lg) })
bind(Window, "BackgroundColor3", "bg")
bind(new("UIStroke", { Thickness = Tokens.stroke, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = Window }), "Color", "border")

do
	-- a soft grey fall-off from the top of the window, the same on every page
	local gradient = new("UIGradient", {
		Rotation = 90,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.42, 0.28), NumberSequenceKeypoint.new(1, 1),
		}),
	})
	new("Frame", {
		Size = UDim2.new(1, 0, 0, 330), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = Window,
	}, { round(Tokens.radius.lg), gradient })
	onTheme(function() gradient.Color = ColorSequence.new(P.gradTop, P.gradBottom) end)

	UI.side = new("Frame", {
		Name = "Side", Size = UDim2.new(0, Tokens.size.side, 1, 0), BackgroundTransparency = 1, Parent = Window,
	})
	bind(new("Frame", {
		Size = UDim2.new(0, 1, 1, 0), Position = UDim2.new(1, -1, 0, 0), BorderSizePixel = 0, Parent = UI.side,
	}), "BackgroundColor3", "border")
	bind(new("TextLabel", {
		Text = "Vigil", FontFace = Tokens.fontStrong, TextSize = 21, BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(22, 20), Size = UDim2.fromOffset(120, 28), Parent = UI.side,
	}), "TextColor3", "text")

	UI.main = new("Frame", {
		Name = "Content", Size = UDim2.new(1, -Tokens.size.side, 1, 0), Position = UDim2.fromOffset(Tokens.size.side, 0),
		BackgroundTransparency = 1, Parent = Window,
	})
	UI.title = bind(new("TextLabel", {
		FontFace = Tokens.fontStrong, TextSize = Tokens.text.title, BackgroundTransparency = 1, Text = "",
		TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(32, 30), Size = UDim2.new(1, -170, 0, 50), Parent = UI.main,
	}), "TextColor3", "text")
	UI.sub = bind(new("TextLabel", {
		FontFace = Tokens.fontRegular, TextSize = Tokens.text.body, BackgroundTransparency = 1, Text = "", TextTruncate = Enum.TextTruncate.AtEnd,
		TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(32, 84), Size = UDim2.new(1, -64, 0, 20), Parent = UI.main,
	}), "TextColor3", "muted")
end

--------------------------------------------------------------------------------
-- Tooltip and toast (floating, so they live outside the window)
--------------------------------------------------------------------------------
local hideTip, tooltip, toast
do

local tip = new("TextLabel", {
	AutomaticSize = Enum.AutomaticSize.XY, Size = UDim2.fromOffset(0, 0), Visible = false, ZIndex = 50,
	FontFace = Tokens.font, TextSize = Tokens.text.small, AnchorPoint = Vector2.new(0, 0.5), Parent = menuGui,
}, { round(Tokens.radius.sm), padding(5, 9) })
bind(tip, "BackgroundColor3", "raised")
bind(tip, "TextColor3", "text")
local tipStroke = bind(new("UIStroke", { Thickness = Tokens.stroke, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = tip }), "Color", "border")

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
			tip.BackgroundTransparency, tip.TextTransparency, tipStroke.Transparency = 1, 1, 1
			tip.Visible = true
			tweenStyle(tip, { BackgroundTransparency = 0, TextTransparency = 0 }, 0.14, Enum.EasingStyle.Quad)
			tweenStyle(tipStroke, { Transparency = 0 }, 0.14, Enum.EasingStyle.Quad)
		end)
	end)
	connect(target.MouseLeave, hideTip)
end

local toastFrame = new("Frame", {
	AutomaticSize = Enum.AutomaticSize.XY, Size = UDim2.fromOffset(0, 0), Visible = false, ZIndex = 60,
	AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -24),
	BorderSizePixel = 0, Parent = menuGui,
}, {
	round("full"), padding(4, 6, 4, 18),
	new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, Tokens.space.md),
		VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder,
	}),
})
bind(toastFrame, "BackgroundColor3", "card")
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
}, { round("full"), padding(0, 12) })
bind(toastAction, "BackgroundColor3", "raised")
bind(toastAction, "TextColor3", "accent")

local toastToken = 0
local toastCallback
local toastScale = new("UIScale", { Parent = toastFrame })
local TOAST_POS = toastFrame.Position
local TOAST_LOW = TOAST_POS + UDim2.fromOffset(0, 14)

local function hideToast(mine)
	tweenStyle(toastFrame, { Position = TOAST_LOW }, 0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	tweenStyle(toastScale, { Scale = 0.96 }, 0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	task.delay(reducedMotion and 0 or 0.16, function()
		if mine == toastToken then toastFrame.Visible = false end
	end)
end

function toast(text, actionText, action)
	toastToken += 1
	local mine = toastToken
	toastLabel.Text = text
	toastAction.Visible = actionText ~= nil
	toastAction.Text = actionText or ""
	toastCallback = action
	if toastFrame.Visible then
		-- already up: a small pulse says the message changed
		toastScale.Scale = 0.98
	else
		toastFrame.Position = TOAST_LOW
		toastScale.Scale = 0.96
		toastFrame.Visible = true
	end
	tweenStyle(toastFrame, { Position = TOAST_POS }, 0.3)
	tweenStyle(toastScale, { Scale = 1 }, 0.3)
	task.delay(actionText and 5 or 2.5, function()
		if mine == toastToken then
			toastCallback = nil
			hideToast(mine)
		end
	end)
end
table.insert(connections, toastAction.Activated:Connect(function()
	local fn = toastCallback
	toastToken += 1
	toastCallback = nil
	hideToast(toastToken)
	if fn then fn() end
end))
end

--------------------------------------------------------------------------------
-- Controls
--------------------------------------------------------------------------------
local section, row, switchRenders, switch, note, slider, segmented, swatches, keyCapture, consumedInput, aimToggled, keybind, actionButton, buttonRow, nextOrder, pressable, cardOf, hairline
do

-- Buttons dip slightly while pressed, so a click feels physical
function pressable(btn)
	local scale = new("UIScale", { Parent = btn })
	connect(btn.MouseButton1Down, function() tweenStyle(scale, { Scale = 0.95 }, 0.08, Enum.EasingStyle.Quad) end)
	local function up() tweenStyle(scale, { Scale = 1 }, 0.25, Enum.EasingStyle.Back) end
	connect(btn.MouseButton1Up, up)
	connect(btn.MouseLeave, up)
	return btn
end

local order = 0
function nextOrder()
	order += 1
	return order
end

function hairline(parent)
	return bind(new("Frame", {
		Size = UDim2.new(1, -16, 0, 1), Position = UDim2.fromOffset(16, 0), BorderSizePixel = 0, Name = "Keep", Parent = parent,
	}), "BackgroundColor3", "divider")
end

-- Each section is a rounded card; everything added to a page goes in its newest card
local function makeCard(page, heading)
	local card = new("Frame", {
		Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 0.12,
		BorderSizePixel = 0, LayoutOrder = nextOrder(), Parent = page,
	}, { round(Tokens.radius.card), new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }) })
	bind(card, "BackgroundColor3", "card")
	bind(new("UIStroke", { Thickness = Tokens.stroke, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = card }), "Color", "border")
	local state = { frame = card, count = 0, title = heading or "" }
	UI.cards[page] = state
	return state
end

function cardOf(page)
	return UI.cards[page] or makeCard(page)
end

function section(page, text)
	local holder = new("Frame", {
		Size = UDim2.new(1, 0, 0, UI.cards[page] and 40 or 26), BackgroundTransparency = 1, LayoutOrder = nextOrder(), Parent = page,
	})
	bind(new("TextLabel", {
		Size = UDim2.new(1, 0, 0, 14), AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 2, 1, -8),
		BackgroundTransparency = 1, FontFace = Tokens.mono, TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left, Text = string.upper(text), Parent = holder,
	}), "TextColor3", "muted")
	makeCard(page, text)
end

function row(page, label)
	local card = cardOf(page)
	local r = new("Frame", {
		Size = UDim2.new(1, 0, 0, Tokens.size.row), BackgroundTransparency = 1,
		LayoutOrder = nextOrder(), Parent = card.frame,
	})
	if card.count > 0 then hairline(r) end
	card.count += 1
	local text = bind(new("TextLabel", {
		Size = UDim2.new(0.5, -8, 1, 0), Position = UDim2.fromOffset(16, 0), BackgroundTransparency = 1, FontFace = Tokens.font,
		TextSize = Tokens.text.body, TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd, Text = label, Parent = r,
	}), "TextColor3", "text")
	table.insert(UI.index, { label = label, page = page.Name, group = card.title, frame = r, scroller = page })
	return r, text
end

local function rightAligned(props, inset)
	props.AnchorPoint = Vector2.new(1, 0.5)
	props.Position = UDim2.new(1, -(inset or 14), 0.5, 0)
	return props
end

switchRenders = {} -- key -> re-render, so other controls (hotkeys, preview chips) stay in sync

function switch(page, label, key, onChange)
	local r, text = row(page, label)
	text.Size = UDim2.new(1, -80, 1, 0)
	local track = new("Frame", rightAligned({ Size = UDim2.fromOffset(42, 25), BorderSizePixel = 0, Parent = r }), { round("full") })
	local knob = new("Frame", {
		Size = UDim2.fromOffset(21, 21), AnchorPoint = Vector2.new(0, 0.5), BorderSizePixel = 0, Parent = track,
	}, { round("full") })
	local hit = new("TextButton", {
		Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", ZIndex = 2, Parent = r,
	})

	local function render(animate)
		local on = Settings[key]
		local trackProps = { BackgroundColor3 = on and P.accent or P.raised }
		local knobProps = { Position = on and UDim2.new(1, -23, 0.5, 0) or UDim2.new(0, 2, 0.5, 0), BackgroundColor3 = on and P.onAccent or P.knob }
		if animate then
			tween(track, trackProps, 0.2)
			tweenStyle(knob, knobProps, 0.28)
		else
			track.BackgroundColor3 = trackProps.BackgroundColor3
			knob.Position, knob.BackgroundColor3 = knobProps.Position, knobProps.BackgroundColor3
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
	local card = cardOf(page)
	local holder = new("Frame", {
		Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
		LayoutOrder = nextOrder(), Parent = card.frame,
	})
	if card.count > 0 then hairline(holder) end
	card.count += 1
	bind(new("TextLabel", {
		Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
		FontFace = Tokens.fontRegular, TextSize = Tokens.text.small + 1, TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left, Text = text, Parent = holder,
	}, { padding(12, 16, 12, 16) }), "TextColor3", "muted")
end

function slider(page, label, key, min, max, step, format)
	local r = row(page, label)
	local value = new("TextLabel", rightAligned({
		Size = UDim2.fromOffset(84, 18), BackgroundTransparency = 1, FontFace = Tokens.mono,
		TextSize = Tokens.text.small, TextXAlignment = Enum.TextXAlignment.Right, Parent = r,
	}, 16))
	bind(value, "TextColor3", "muted")
	local hit = new("TextButton", {
		Size = UDim2.new(0.5, -112, 0, 28), AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -108, 0.5, 0), BackgroundTransparency = 1, Text = "", Parent = r,
	}, { new("UISizeConstraint", { MaxSize = Vector2.new(190, 28) }) })
	local track = new("Frame", {
		Size = UDim2.new(1, 0, 0, 3), AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromScale(0, 0.5), BorderSizePixel = 0, Parent = hit,
	}, { round("full") })
	bind(track, "BackgroundColor3", "raised")
	local fill = new("Frame", { Size = UDim2.fromScale(0, 1), BorderSizePixel = 0, Parent = track }, { round("full") })
	local knob = new("Frame", {
		Size = UDim2.fromOffset(16, 16), AnchorPoint = Vector2.new(0.5, 0.5), BorderSizePixel = 0, Parent = track,
	}, { round("full") })
	bind(new("UIStroke", { Thickness = 2, Parent = knob }), "Color", "bg")

	local function render()
		local a = (Settings[key] - min) / (max - min)
		fill.Size = UDim2.fromScale(a, 1)
		knob.Position = UDim2.fromScale(a, 0.5)
		fill.BackgroundColor3 = P.accent
		knob.BackgroundColor3 = P.accent
		value.Text = format(Settings[key])
	end

	local dragging, hovering = false, false
	local function knobSize()
		local px = dragging and 20 or (hovering and 18 or 16)
		tweenStyle(knob, { Size = UDim2.fromOffset(px, px) }, 0.18, Enum.EasingStyle.Back)
	end
	connect(hit.MouseEnter, function() hovering = true; knobSize() end)
	connect(hit.MouseLeave, function() hovering = false; knobSize() end)
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
			knobSize()
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
			knobSize()
			save()
		end
	end)
	onTheme(render)
end

function segmented(page, label, key, options, onChange)
	local r = row(page, label)
	local holder = new("Frame", rightAligned({
		AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, Tokens.size.control),
		BackgroundTransparency = 0.45, BorderSizePixel = 0, Parent = r,
	}), {
		round(Tokens.radius.md), padding(2),
		new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	bind(holder, "BackgroundColor3", "raised")

	local buttons = {}
	for i, option in ipairs(options) do
		buttons[option] = new("TextButton", {
			AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.new(0, 0, 1, 0), Text = option,
			FontFace = Tokens.font, TextSize = Tokens.text.small, AutoButtonColor = false,
			BorderSizePixel = 0, LayoutOrder = i, Parent = holder,
		}, { round(Tokens.radius.sm), padding(0, 12) })
		pressable(buttons[option])
	end

	local function render()
		for option, btn in pairs(buttons) do
			local selected = Settings[key] == option
			btn.BackgroundColor3 = P.text
			tween(btn, { BackgroundTransparency = selected and 0 or 1, TextColor3 = selected and P.bg or P.muted }, 0.16)
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

	local rings, dots = {}, {}
	for i, entry in ipairs(colours) do
		local btn = new("TextButton", {
			Size = UDim2.fromOffset(24, 24), BackgroundTransparency = 1, Text = "",
			LayoutOrder = i, Parent = holder,
		})
		dots[i] = new("Frame", {
			Size = UDim2.fromOffset(16, 16), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
			BorderSizePixel = 0, Parent = btn,
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
			dots[i].BackgroundColor3 = colours[i][2] or P.text
		end
	end)
end

aimToggled = false

function keybind(page, label, key, allowMouse)
	local r = row(page, label)
	local btn = new("TextButton", rightAligned({
		AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 28),
		FontFace = Tokens.mono, TextSize = Tokens.text.small, AutoButtonColor = false,
		BorderSizePixel = 0, Parent = r,
	}), { round(8), padding(0, 11) })
	pressable(btn)

	local listening = false
	local function render()
		btn.Text = listening and (allowMouse and "Press a key or button" or "Press a key") or bindName(Settings[key])
		btn.BackgroundColor3 = listening and P.hover or P.raised
		btn.TextColor3 = listening and P.muted or P.text
	end
	connect(btn.Activated, function()
		if keyCapture then return end
		listening = true
		render()
		keyCapture = function(name)
			if MouseBinds[name] and not allowMouse then return end
			listening = false
			keyCapture = nil
			if name ~= "Escape" then
				Settings[key] = name
				save()
				toast(label .. " set to " .. bindName(name))
				if UI.refreshHint then UI.refreshHint() end
			end
			render()
		end
	end)
	onTheme(render)
end

local function pill(parent, text, order2)
	local btn = new("TextButton", {
		AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.new(0, 0, 0, Tokens.size.control),
		Text = text, FontFace = Tokens.font, TextSize = Tokens.text.small + 1, AutoButtonColor = false,
		BorderSizePixel = 0, LayoutOrder = order2 or 0, Parent = parent,
	}, { round("full"), padding(0, 14) })
	pressable(btn)
	return btn
end

function actionButton(page, label, text, onClick)
	local r = row(page, label)
	local btn = pill(r, text)
	btn.AnchorPoint = Vector2.new(1, 0.5)
	btn.Position = UDim2.new(1, -14, 0.5, 0)
	local hovered = false
	local function render()
		tween(btn, { BackgroundColor3 = hovered and P.danger or P.raised, TextColor3 = hovered and P.bg or P.danger }, 0.12)
	end
	connect(btn.MouseEnter, function() hovered = true; render() end)
	connect(btn.MouseLeave, function() hovered = false; render() end)
	connect(btn.Activated, onClick)
	onTheme(render)
end

function buttonRow(page, label, buttons)
	local r, text = row(page, label)
	local holder
	if #buttons > 3 then
		-- too many to share a line with the label: the label sits on top of a grid
		local lines = math.ceil(#buttons / 3)
		r.Size = UDim2.new(1, 0, 0, 46 + lines * 30 + (lines - 1) * 6 + 14)
		text.Size = UDim2.new(1, -32, 0, 20)
		text.Position = UDim2.fromOffset(16, 14)
		holder = new("Frame", {
			Size = UDim2.new(1, -30, 0, lines * 30 + (lines - 1) * 6), Position = UDim2.fromOffset(16, 46),
			BackgroundTransparency = 1, Parent = r,
		}, { new("UIGridLayout", {
			CellSize = UDim2.new(1 / 3, -4, 0, 30), CellPadding = UDim2.fromOffset(6, 6), SortOrder = Enum.SortOrder.LayoutOrder,
		}) })
	else
		holder = new("Frame", rightAligned({
			AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, Tokens.size.control),
			BackgroundTransparency = 1, Parent = r,
		}), { new("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder,
		}) })
	end
	for i, entry in ipairs(buttons) do
		local btn = pill(holder, entry[1], i)
		local hovered = false
		local function render()
			tween(btn, { BackgroundColor3 = hovered and P.hover or P.raised }, 0.12)
			btn.TextColor3 = P.text
		end
		connect(btn.MouseEnter, function() hovered = true; render() end)
		connect(btn.MouseLeave, function() hovered = false; render() end)
		connect(btn.Activated, entry[2])
		onTheme(render)
	end
end
end

--------------------------------------------------------------------------------
-- Presets (only touch combat settings; applying one can be undone from the toast)
--------------------------------------------------------------------------------
-- A field of view at this value covers the whole screen and also takes targets behind the camera
local FOV_FULL = 1500

local Presets, applyPreset
do

Presets = {
	{ "Legit", {
		aimEnabled = true, aimMode = "Hold", aimPart = "Torso", aimPriority = "Crosshair", aimMethod = "Auto",
		fov = 80, showFov = false, smoothing = 8, prediction = 0, visibleOnly = true,
		aimTeamCheck = true, stickyTarget = true, aimMaxDistance = 800, silentEnabled = false, aimTargets = "Players",
	} },
	{ "Silent", {
		aimEnabled = false, silentEnabled = true, silentPart = "Closest", hitChance = 75,
		silentFov = 100, showSilentFov = false, showSilentTarget = false, silentVisibleOnly = true,
		silentTeamCheck = true, silentMaxDistance = 1000, silentTargets = "Players", silentWalls = false,
	} },
	{ "Rage", {
		aimEnabled = true, aimMode = "Always", aimPart = "Head", aimPriority = "Crosshair", aimMethod = "Auto",
		fov = 500, showFov = true, smoothing = 1, visibleOnly = false, stickyTarget = false,
		aimMaxDistance = 3000, silentEnabled = true, silentPart = "Head", hitChance = 100,
		silentFov = 600, silentVisibleOnly = false, showSilentTarget = true, silentMaxDistance = 3000,
		aimTargets = "Players", silentTargets = "Players", silentWalls = false,
	} },
	{ "Ultra rage", { -- full screen, through walls, snaps and stays on the target
		aimEnabled = true, aimMode = "Always", aimPart = "Head", aimPriority = "Distance", aimMethod = "Auto",
		fov = FOV_FULL, showFov = false, smoothing = 1, prediction = 0, visibleOnly = false,
		stickyTarget = true, aimMaxDistance = 3000, silentEnabled = true, silentPart = "Head",
		hitChance = 100, silentFov = FOV_FULL, showSilentFov = false, silentVisibleOnly = false,
		showSilentTarget = true, silentMaxDistance = 3000, silentRaycast = true, silentMouse = true,
		silentCameraRays = true, silentWalls = true, aimTargets = "Players", silentTargets = "Players",
	} },
	{ "NPC ultra rage", { -- the same, but only on NPCs (bots, mobs, dummies)
		aimEnabled = true, aimMode = "Always", aimPart = "Head", aimPriority = "Distance", aimMethod = "Auto",
		fov = FOV_FULL, showFov = false, smoothing = 1, prediction = 0, visibleOnly = false,
		stickyTarget = true, aimMaxDistance = 3000, silentEnabled = true, silentPart = "Head",
		hitChance = 100, silentFov = FOV_FULL, showSilentFov = false, silentVisibleOnly = false,
		showSilentTarget = true, silentMaxDistance = 3000, silentRaycast = true, silentMouse = true,
		silentCameraRays = true, silentWalls = true, aimTargets = "NPCs", silentTargets = "NPCs",
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

--------------------------------------------------------------------------------
-- Pages
--------------------------------------------------------------------------------

local canMoveMouse = typeof(mousemoverel) == "function"
local canHook = typeof(hookmetamethod) == "function" and typeof(getnamecallmethod) == "function"
	and typeof(checkcaller) == "function"

local pages, page, selectTab = {}
do
local PAGE_HOME = UDim2.fromOffset(0, Tokens.size.header)
local PAGE_SIZE = UDim2.new(1, -8, 1, -132)

local function scroller(id)
	local p = new("ScrollingFrame", {
		Name = id, Size = PAGE_SIZE, Position = PAGE_HOME,
		BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4, ScrollBarImageTransparency = 0.72,
		ScrollingDirection = Enum.ScrollingDirection.Y, AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(), Visible = false, Parent = UI.main,
	}, {
		padding(0, 24, 18, 32),
		new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	bind(p, "ScrollBarImageColor3", "text")
	-- the bar brightens while scrolling, then settles back
	local movedAt = 0
	connect(p:GetPropertyChangedSignal("CanvasPosition"), function()
		p.ScrollBarImageTransparency = 0.4
		movedAt = os.clock()
		local mine = movedAt
		task.delay(0.7, function()
			if mine == movedAt then tweenStyle(p, { ScrollBarImageTransparency = 0.72 }, 0.4, Enum.EasingStyle.Sine) end
		end)
	end)
	pages[id] = p
	return p
end

function page(id)
	return scroller(id)
end

local canClickMouse = typeof(mouse1click) == "function" or (typeof(mouse1press) == "function" and typeof(mouse1release) == "function")
local tabs = {
	{ id = "aim", title = "Aimbot", sub = "Turns your camera onto the closest target in your field of view.", master = "aimEnabled" },
	{ id = "silent", title = "Silent aim", sub = "Bends your shots toward a target while your camera stays still.", master = canHook and "silentEnabled" or nil },
	{ id = "trigger", title = "Triggerbot", sub = "Fires for you while your crosshair is on an enemy.", master = canClickMouse and "triggerEnabled" or nil },
	{ id = "esp", title = "ESP", sub = "Draws players and NPCs through walls.", master = "enabled" },
	{ id = "visuals", title = "Visuals", sub = "Changes how the world looks on your screen." },
	{ id = "movement", title = "Movement", sub = "Changes how your character gets around." },
	{ id = "players", title = "Players", sub = "Everyone in this server." },
	{ id = "games", title = "Games", sub = "Scripts made for specific games." },
	{ id = "settings", title = "Settings", sub = "Presets, appearance, keys and configs." },
}
local tabById = {}
for _, tab in ipairs(tabs) do tabById[tab.id] = tab end
local GROUPS = {
	{ "Combat", { "aim", "silent", "trigger" } },
	{ "Sight", { "esp", "visuals" } },
	{ "World", { "movement", "players", "games" } },
}

-- the big switch beside the page title, shared by every page that has one
local masterHost = new("Frame", {
	Size = UDim2.fromOffset(120, 34), AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -32, 0, 40),
	BackgroundTransparency = 1, Visible = false, Parent = UI.main,
})
local masterStatus = bind(new("TextLabel", {
	FontFace = Tokens.mono, TextSize = Tokens.text.small, BackgroundTransparency = 1, Text = "",
	TextXAlignment = Enum.TextXAlignment.Right, Size = UDim2.new(1, -62, 1, 0), Parent = masterHost,
}), "TextColor3", "text")
local masterTrack = new("Frame", {
	Size = UDim2.fromOffset(52, 31), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), BorderSizePixel = 0, Parent = masterHost,
}, { round("full") })
local masterKnob = new("Frame", {
	Size = UDim2.fromOffset(27, 27), AnchorPoint = Vector2.new(0, 0.5), BorderSizePixel = 0, Parent = masterTrack,
}, { round("full") })
local masterHit = new("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", ZIndex = 3, Parent = masterTrack })

local nav = {}
local lastTab
local function currentMaster()
	local tab = tabById[UI.currentTab]
	return tab and tab.master
end
local function renderMaster(animate)
	for id, item in pairs(nav) do
		if item.state then item.state.Text = Settings[tabById[id].master] and "ON" or "" end
	end
	local key = currentMaster()
	masterHost.Visible = key ~= nil
	if not key then return end
	local on = Settings[key]
	masterStatus.Text = on and "On" or "Off"
	local trackProps = { BackgroundColor3 = on and P.accent or P.raised }
	local knobProps = { Position = on and UDim2.new(1, -29, 0.5, 0) or UDim2.new(0, 2, 0.5, 0), BackgroundColor3 = on and P.onAccent or P.knob }
	if animate then
		tween(masterTrack, trackProps, 0.2)
		tweenStyle(masterKnob, knobProps, 0.28)
	else
		masterTrack.BackgroundColor3 = trackProps.BackgroundColor3
		masterKnob.Position, masterKnob.BackgroundColor3 = knobProps.Position, knobProps.BackgroundColor3
	end
end
connect(masterHit.Activated, function()
	local key = currentMaster()
	if not key then return end
	Settings[key] = not Settings[key]
	save()
	renderMaster(true)
end)
for _, tab in ipairs(tabs) do
	if tab.master then switchRenders[tab.master] = function() renderMaster(true) end end
end
onTheme(function() renderMaster(false) end)

-- navigation: one highlight that slides between items
local navScroll = new("ScrollingFrame", {
	Position = UDim2.fromOffset(0, 100), Size = UDim2.new(1, -1, 1, -168), BackgroundTransparency = 1, BorderSizePixel = 0,
	ScrollBarThickness = 0, ScrollingDirection = Enum.ScrollingDirection.Y, CanvasSize = UDim2.new(), Parent = UI.side,
})
local navPill = new("Frame", {
	Size = UDim2.new(1, -20, 0, 34), BackgroundTransparency = 0.88, BorderSizePixel = 0, Parent = navScroll,
}, { round(10) })
bind(navPill, "BackgroundColor3", "text")
local searchBox

local function paintNav()
	for id, item in pairs(nav) do
		local colour = id == UI.currentTab and P.text or P.nav
		tween(item.label, { TextColor3 = colour }, 0.18)
		item.paint(colour)
	end
end
onTheme(paintNav)

local function navItem(id, y)
	local b = new("TextButton", {
		Size = UDim2.new(1, -20, 0, 34), Position = UDim2.fromOffset(10, y), BackgroundTransparency = 1, Text = "", ZIndex = 2, Parent = navScroll,
	})
	local label = new("TextLabel", {
		Text = tabById[id].title, FontFace = Tokens.font, TextSize = Tokens.text.body, BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(40, 0), Size = UDim2.new(1, -40, 1, 0), ZIndex = 2, Parent = b,
	})
	local image, paint = iconImage(id, 18, b)
	image.Position = UDim2.fromOffset(12, 8)
	local item = { label = label, y = y, btn = b, paint = paint }
	if tabById[id].master then
		item.state = bind(new("TextLabel", {
			Text = "", FontFace = Tokens.mono, TextSize = 10, BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Right,
			AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(30, 14), ZIndex = 2, Parent = b,
		}), "TextColor3", "muted")
	end
	nav[id] = item
	connect(b.Activated, function() selectTab(id) end)
end

local navY = 0
for _, group in ipairs(GROUPS) do
	bind(new("TextLabel", {
		Text = string.upper(group[1]), FontFace = Tokens.mono, TextSize = 10, BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(22, navY), Size = UDim2.fromOffset(160, 20), Parent = navScroll,
	}), "TextColor3", "muted")
	navY += 22
	for _, id in ipairs(group[2]) do
		navItem(id, navY)
		navY += 35
	end
	navY += 12
end
navItem("settings", 0)

-- Discord: Roblox can't open links, so the button copies the invite
local discordBtn = new("TextButton", {
	Size = UDim2.new(1, -20, 0, 34), BackgroundTransparency = 1, BorderSizePixel = 0, Text = "", AutoButtonColor = false, ZIndex = 2, Parent = navScroll,
}, { round(10) })
bind(discordBtn, "BackgroundColor3", "text")
do
	local INVITE = "https://discord.gg/wFde66zTR5"
	local label = new("TextLabel", {
		Text = "Discord", FontFace = Tokens.font, TextSize = Tokens.text.body, BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(40, 0), Size = UDim2.new(1, -40, 1, 0), ZIndex = 2, Parent = discordBtn,
	})
	local image, paint = iconImage("discord", 18, discordBtn)
	image.Position = UDim2.fromOffset(12, 8)
	local function idle()
		label.Text, label.TextSize, label.TextColor3 = "Discord", Tokens.text.body, P.nav
		paint(P.nav)
	end
	onTheme(idle)
	connect(discordBtn.MouseEnter, function() tween(discordBtn, { BackgroundTransparency = 0.94 }, 0.14) end)
	connect(discordBtn.MouseLeave, function() tween(discordBtn, { BackgroundTransparency = 1 }, 0.14) end)
	local token = 0
	connect(discordBtn.Activated, function()
		token += 1
		local mine = token
		local copy = (typeof(setclipboard) == "function" and setclipboard) or (typeof(toclipboard) == "function" and toclipboard)
		if copy and pcall(copy, INVITE) then
			label.Text = "Invite copied"
			toast("Discord invite copied")
		else
			label.Text, label.TextSize = "discord.gg/wFde66zTR5", 11
		end
		label.TextColor3 = P.text
		task.delay(2.2, function()
			if mine == token then idle() end
		end)
	end)
end

function UI.layoutNav()
	local view = Holder.Size.Y.Offset - 168
	local top = math.max(navY, view - 72)
	discordBtn.Position = UDim2.fromOffset(10, top)
	nav.settings.y = top + 35
	nav.settings.btn.Position = UDim2.fromOffset(10, top + 35)
	navScroll.CanvasSize = UDim2.fromOffset(0, math.max(view, top + 72))
	if UI.currentTab == "settings" then navPill.Position = UDim2.fromOffset(10, nav.settings.y) end
end

function selectTab(id)
	local first = UI.currentTab == nil
	if UI.currentTab == id then return end
	UI.currentTab = id
	navPill.Visible = true
	if searchBox and searchBox.Text ~= "" then searchBox.Text = "" end
	local tab = tabById[id]
	for k, p in pairs(pages) do p.Visible = k == id end
	UI.title.Text, UI.sub.Text = tab.title, tab.sub
	paintNav()
	renderMaster(false)
	local target = UDim2.fromOffset(10, nav[id].y)
	if first then
		navPill.Position = target
	else
		tweenStyle(navPill, { Position = target }, 0.34)
		pages[id].Position = PAGE_HOME + UDim2.fromOffset(0, 8)
		tweenStyle(pages[id], { Position = PAGE_HOME }, 0.34)
	end
	if UI.fitPreview then UI.fitPreview() end
	hideTip()
end

-- Search: every setting in one list; choosing one opens its page and points at it
do
	local field = new("Frame", {
		Size = UDim2.new(1, -20, 0, 34), Position = UDim2.fromOffset(10, 58), BackgroundTransparency = 0.45, BorderSizePixel = 0, Parent = UI.side,
	}, { round(10) })
	bind(field, "BackgroundColor3", "raised")
	local image, paint = iconImage("search", 18, field)
	image.Position = UDim2.fromOffset(8, 8)
	onTheme(function() paint(P.muted) end)
	searchBox = new("TextBox", {
		Size = UDim2.new(1, -40, 1, 0), Position = UDim2.fromOffset(34, 0), BackgroundTransparency = 1, Text = "",
		PlaceholderText = "Search settings", FontFace = Tokens.fontRegular, TextSize = Tokens.text.small + 1,
		TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, ClearTextOnFocus = false, Parent = field,
	})
	bind(searchBox, "TextColor3", "text")
	bind(searchBox, "PlaceholderColor3", "muted")

	local results = scroller("search")
	local resultCard

	local function jump(entry)
		selectTab(entry.page)
		task.wait()
		local p = entry.scroller
		p.CanvasPosition = Vector2.new(0, math.max(0, entry.frame.AbsolutePosition.Y - p.AbsolutePosition.Y + p.CanvasPosition.Y - 40))
		entry.frame.BackgroundColor3 = P.text
		entry.frame.BackgroundTransparency = 0.86
		tweenStyle(entry.frame, { BackgroundTransparency = 1 }, 1.1, Enum.EasingStyle.Sine)
	end

	local function runSearch()
		local q = string.lower((searchBox.Text:gsub("^%s+", ""):gsub("%s+$", "")))
		if q == "fov" then q = "field of view" end
		if q == "" then
			if UI.currentTab == "search" then
				UI.currentTab = nil
				selectTab(lastTab or "aim")
			end
			return
		end
		if UI.currentTab ~= "search" then lastTab, UI.currentTab = UI.currentTab, "search" end
		navPill.Visible = false
		for k, p in pairs(pages) do p.Visible = k == "search" end
		paintNav()
		masterHost.Visible = false
		if UI.fitPreview then UI.fitPreview() end
		if resultCard then resultCard:Destroy(); resultCard = nil end
		local found = {}
		for _, e in ipairs(UI.index) do
			if e.frame.Parent and (string.find(string.lower(e.label), q, 1, true) or string.find(string.lower(tabById[e.page].title), q, 1, true)
				or string.find(string.lower(e.group), q, 1, true)) then
				table.insert(found, e)
			end
		end
		table.sort(found, function(x, y) return x.label < y.label end)
		UI.title.Text = "Search"
		if #found == 0 then
			UI.sub.Text = 'Nothing matches "' .. searchBox.Text .. '". Try a shorter word.'
			return
		end
		UI.sub.Text = #found == 1 and "1 setting" or (#found .. " settings")
		resultCard = new("Frame", {
			Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = P.card, BackgroundTransparency = 0.12,
			BorderSizePixel = 0, Parent = results,
		}, {
			round(Tokens.radius.card), new("UIStroke", { Color = P.border, Thickness = Tokens.stroke, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
			new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }),
		})
		for i, e in ipairs(found) do
			local b = new("TextButton", {
				Size = UDim2.new(1, 0, 0, Tokens.size.row), BackgroundColor3 = P.text, BackgroundTransparency = 1, BorderSizePixel = 0,
				Text = "", AutoButtonColor = false, LayoutOrder = i, Parent = resultCard,
			})
			if i > 1 then new("Frame", { Size = UDim2.new(1, -16, 0, 1), Position = UDim2.fromOffset(16, 0), BackgroundColor3 = P.divider, BorderSizePixel = 0, Parent = b }) end
			new("TextLabel", {
				Text = e.label, FontFace = Tokens.font, TextSize = Tokens.text.body, TextColor3 = P.text, BackgroundTransparency = 1,
				TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
				Position = UDim2.fromOffset(16, 0), Size = UDim2.new(0.55, -16, 1, 0), Parent = b,
			})
			new("TextLabel", {
				Text = tabById[e.page].title .. (e.group ~= "" and ("  /  " .. e.group) or ""), FontFace = Tokens.mono, TextSize = 11,
				TextColor3 = P.muted, BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Right, TextTruncate = Enum.TextTruncate.AtEnd,
				AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -16, 0.5, 0), Size = UDim2.new(0.42, 0, 0, 16), Parent = b,
			})
			connect(b.MouseEnter, function() tween(b, { BackgroundTransparency = 0.95 }, 0.12) end)
			connect(b.MouseLeave, function() tween(b, { BackgroundTransparency = 1 }, 0.12) end)
			connect(b.Activated, function() task.spawn(jump, e) end)
		end
	end
	connect(searchBox:GetPropertyChangedSignal("Text"), runSearch)
end

-- account row
do
	local side = UI.side
	bind(new("Frame", {
		Size = UDim2.new(1, -20, 0, 1), Position = UDim2.new(0, 10, 1, -62), BorderSizePixel = 0, Parent = side,
	}), "BackgroundColor3", "border")
	bind(new("ImageLabel", {
		Size = UDim2.fromOffset(32, 32), Position = UDim2.new(0, 18, 1, -48), BorderSizePixel = 0,
		Image = "rbxthumb://type=AvatarHeadShot&id=" .. LocalPlayer.UserId .. "&w=60&h=60", Parent = side,
	}, { round("full") }), "BackgroundColor3", "raised")
	bind(new("TextLabel", {
		Text = LocalPlayer.DisplayName, FontFace = Tokens.font, TextSize = Tokens.text.small + 1, BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Position = UDim2.new(0, 60, 1, -49), Size = UDim2.fromOffset(130, 17), Parent = side,
	}), "TextColor3", "text")
	local hint = bind(new("TextLabel", {
		Text = "", FontFace = Tokens.fontRegular, TextSize = 11, BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Position = UDim2.new(0, 60, 1, -31), Size = UDim2.fromOffset(130, 15), Parent = side,
	}), "TextColor3", "faint")
	function UI.refreshHint()
		hint.Text = bindName(Settings.menuKey) .. " hides"
	end
	onTheme(UI.refreshHint)
end
end

-- ESP page: settings list on the left, live preview on the right
local PANEL_W, PREVIEW_H = 240, 200
local PREVIEW_W = PANEL_W - 24

local espPage = page("esp")

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
switch(espPage, "Show NPCs", "npcEsp")
switch(espPage, "Friends are teammates", "friendsAsTeam")
keybind(espPage, "Mark teammate", "allyKey")
note(espPage, "Point at a player or NPC and press the key to cycle it: teammate, enemy, then automatic. Teammates are hidden and ignored by the aimbot and silent aim.")
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
		Position = UDim2.new(1, -24, 0, Tokens.size.header),
		Size = UDim2.new(0, PANEL_W, 1, -(Tokens.size.header + 18)),
		BackgroundTransparency = 0.12, BorderSizePixel = 0, Visible = false, Parent = UI.main,
	}, { round(Tokens.radius.card), padding(Tokens.space.md) })
	bind(panel, "BackgroundColor3", "card")
	bind(new("UIStroke", { Thickness = Tokens.stroke, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = panel }), "Color", "border")

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
		TextXAlignment = Enum.TextXAlignment.Left, Text = "Drag onto the player, or off it", Parent = panel,
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
		local label = new("TextLabel", {
			Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
			FontFace = Tokens.font, TextSize = Tokens.text.small,
			TextTruncate = Enum.TextTruncate.AtEnd, Text = def[2], Parent = btn,
		})
		chips[i] = { key = def[1], btn = btn, label = label }
	end

	-- on: filled chip; off: plain chip
	function previewUI.renderChips()
		for _, c in ipairs(chips) do
			local on = Settings[c.key]
			c.btn.BackgroundColor3 = on and P.accent or P.raised
			c.label.TextColor3 = on and P.onAccent or P.muted
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

	-- a press without movement toggles; a drag adds on the player or removes elsewhere
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
end

-- the preview only stays while the window has room for both it and the settings
function UI.fitPreview()
	local fits = Holder.Size.X.Offset - Tokens.size.side >= 620 and Holder.Size.Y.Offset >= 540
	espPage.Size = fits and UDim2.new(1, -(PANEL_W + 32), 1, -132) or UDim2.new(1, -8, 1, -132)
	previewUI.panel.Visible = fits and UI.currentTab == "esp"
end

-- Aimbot page
do -- repair saved values that no longer fit this executor or the option lists
	local choices = {
		silentPart = { Head = true, Torso = true, Closest = true },
		boxStyle = { Corners = true, Full = true },
		bodySource = { Auto = true, Visible = true, Character = true },
		aimMode = { Hold = true, Toggle = true, Always = true },
		aimPart = { Head = true, Torso = true },
		aimPriority = { Crosshair = true, Distance = true },
		aimTargets = { Players = true, NPCs = true, Both = true },
		silentTargets = { Players = true, NPCs = true, Both = true },
		triggerMode = { Always = true, ["Aim key"] = true },
		triggerFire = { Hold = true, Tap = true },
		aimMethod = { Auto = true, Camera = true, Mouse = canMoveMouse },
		tracerOrigin = { Bottom = true, Centre = true, Mouse = true },
	}
	local defaults = { bodySource = "Auto", boxStyle = "Corners", silentPart = "Head", aimMode = "Hold", aimPart = "Head", aimPriority = "Crosshair", aimMethod = "Auto", tracerOrigin = "Bottom", aimTargets = "Players", silentTargets = "Players", triggerMode = "Always", triggerFire = "Hold" }
	for key, allowed in pairs(choices) do
		if not allowed[Settings[key]] then Settings[key] = defaults[key] end
	end
	if not bindValid(Settings.aimKey, true) then Settings.aimKey = "MouseButton2" end
	if not bindValid(Settings.flyKey, false) then Settings.flyKey = "F" end
	if not bindValid(Settings.allyKey, false) then Settings.allyKey = "Z" end
	if not bindValid(Settings.panicKey, false) then Settings.panicKey = "End" end
	if not bindValid(Settings.freecamKey, false) then Settings.freecamKey = "P" end
end

local aimPage = page("aim")
section(aimPage, "Activation")
keybind(aimPage, "Aim key", "aimKey", true)
segmented(aimPage, "Activation", "aimMode", { "Hold", "Toggle", "Always" })

section(aimPage, "Target")
segmented(aimPage, "Targets", "aimTargets", { "Players", "NPCs", "Both" })
segmented(aimPage, "Aim at", "aimPart", { "Head", "Torso" })
segmented(aimPage, "Prefer", "aimPriority", { "Crosshair", "Distance" })
switch(aimPage, "Ignore teammates", "aimTeamCheck")
switch(aimPage, "Visible only", "visibleOnly")
switch(aimPage, "Stay on target", "stickyTarget")
slider(aimPage, "Max distance", "aimMaxDistance", 50, 3000, 50, function(v) return string.format("%d studs", v) end)

section(aimPage, "Feel")
slider(aimPage, "Field of view", "fov", 30, FOV_FULL, 10, function(v) return v >= FOV_FULL and "Full screen" or string.format("%d px", v) end)
switch(aimPage, "Show field of view", "showFov")
slider(aimPage, "Smoothing", "smoothing", 1, 20, 1, function(v) return v == 1 and "Off" or string.format("%d", v) end)
slider(aimPage, "Prediction", "prediction", 0, 250, 10, function(v) return v == 0 and "Off" or string.format("%d ms", v) end)
if canMoveMouse then
	segmented(aimPage, "Method", "aimMethod", { "Auto", "Camera", "Mouse" })
end

-- Triggerbot page
local triggerPage = page("trigger")
if typeof(mouse1click) == "function" or (typeof(mouse1press) == "function" and typeof(mouse1release) == "function") then
	section(triggerPage, "Firing")
	segmented(triggerPage, "Active", "triggerMode", { "Always", "Aim key" })
	segmented(triggerPage, "Fire", "triggerFire", { "Hold", "Tap" })
	slider(triggerPage, "Reaction delay", "triggerDelay", 0, 300, 10, function(v) return v == 0 and "Instant" or string.format("%d ms", v) end)
	slider(triggerPage, "Tap rate", "triggerRate", 2, 20, 1, function(v) return string.format("%d / s", v) end)
	note(triggerPage, "It uses the aimbot's target and teammate settings. Hold suits automatic weapons, Tap suits semi-automatic ones.")
else
	note(triggerPage, "The triggerbot isn't available because this executor can't click the mouse.")
end

-- Silent aim page
local silentPage = page("silent")
if canHook then
	section(silentPage, "Target")
	segmented(silentPage, "Targets", "silentTargets", { "Players", "NPCs", "Both" })
	segmented(silentPage, "Aim at", "silentPart", { "Head", "Torso", "Closest" })
	slider(silentPage, "Hit chance", "hitChance", 0, 100, 1, function(v) return string.format("%d%%", v) end)
	switch(silentPage, "Ignore teammates", "silentTeamCheck")
	switch(silentPage, "Visible only", "silentVisibleOnly")
	slider(silentPage, "Max distance", "silentMaxDistance", 50, 3000, 50, function(v) return string.format("%d studs", v) end)

	section(silentPage, "Field of view")
	slider(silentPage, "Radius", "silentFov", 30, FOV_FULL, 10, function(v) return v >= FOV_FULL and "Full screen" or string.format("%d px", v) end)
	switch(silentPage, "Show circle", "showSilentFov")
	switch(silentPage, "Mark target", "showSilentTarget")

	section(silentPage, "Redirect")
	note(silentPage, "Games aim shots in different ways, so leave these on unless one causes trouble. Only shots you are firing are changed.")
	switch(silentPage, "Raycasts", "silentRaycast")
	switch(silentPage, "Mouse position", "silentMouse")
	switch(silentPage, "Screen rays", "silentCameraRays")
	switch(silentPage, "Shots sent to the server", "silentRemotes")
	switch(silentPage, "Shoot through walls", "silentWalls")
else
	note(silentPage, "Silent aim isn't available because this executor can't hook game functions.")
end

-- Visuals page
local visualsPage = page("visuals")
section(visualsPage, "World")
switch(visualsPage, "Fullbright", "fullbright")
switch(visualsPage, "Remove fog", "noFog")
switch(visualsPage, "Lock time of day", "lockTime")
slider(visualsPage, "Time", "timeOfDay", 0, 24, 0.5, function(v)
	return string.format("%02d:%02d", math.floor(v) % 24, math.floor((v % 1) * 60 + 0.5))
end)

section(visualsPage, "Radar")
switch(visualsPage, "Show radar", "radarEnabled")
slider(visualsPage, "Range", "radarRange", 50, 1000, 25, function(v) return string.format("%d studs", v) end)
switch(visualsPage, "Show teammates", "radarTeam")
note(visualsPage, "Enemies use the ESP colour, teammates are blue, and NPCs are orange when NPC ESP is on. Dots on the edge are out of range.")

section(visualsPage, "Camera")
switch(visualsPage, "Custom field of view", "camFovEnabled")
slider(visualsPage, "Field of view", "camFov", 50, 120, 1, function(v) return string.format("%d°", v) end)

section(visualsPage, "Crosshair")
switch(visualsPage, "Show crosshair", "crosshair")
slider(visualsPage, "Size", "crosshairSize", 4, 20, 1, function(v) return string.format("%d px", v) end)
slider(visualsPage, "Gap", "crosshairGap", 0, 12, 1, function(v) return string.format("%d px", v) end)

-- Movement page
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

-- Games page
bind(new("TextLabel", {
	Size = UDim2.new(1, 0, 0, 280), BackgroundTransparency = 1, FontFace = Tokens.font, TextSize = 18,
	Text = "Coming soon, join discord for news", TextWrapped = true, Parent = page("games"),
}), "TextColor3", "muted")

-- Settings page
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
switch(settingsPage, "Loading screen", "showLoader")
segmented(settingsPage, "Theme", "theme", { "Dark", "Light" }, function() applyTheme() end)
swatches(settingsPage, "Accent", "accentColour", Accents)

section(settingsPage, "Controls")
keybind(settingsPage, "Show or hide menu", "menuKey")
keybind(settingsPage, "Panic", "panicKey")
note(settingsPage, "Panic hides the menu and turns every feature off. Press it again to turn them back on.")

section(settingsPage, "Configs")
switch(settingsPage, "Separate settings per game", "perGame", function() save() end)
note(settingsPage, "When on, this game keeps its own settings and other games keep theirs.")

section(settingsPage, "Script")
local unload -- defined below
actionButton(settingsPage, "Remove ESP and menu", "Unload", function() unload() end)

-- Close button, top right
local closeBtn = new("TextButton", {
	Size = UDim2.fromOffset(26, 26), AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 10),
	BackgroundTransparency = 1, BorderSizePixel = 0, Text = "", AutoButtonColor = false, ZIndex = 5, Parent = UI.main,
}, { round("full") })
bind(closeBtn, "BackgroundColor3", "text")
do
	local image, paint = iconImage("close", 14, closeBtn)
	image.AnchorPoint = Vector2.new(0.5, 0.5)
	image.Position = UDim2.fromScale(0.5, 0.5)
	local hovered = false
	local function render()
		paint(hovered and P.text or P.muted)
		tween(closeBtn, { BackgroundTransparency = hovered and 0.9 or 1 }, 0.12)
	end
	connect(closeBtn.MouseEnter, function() hovered = true; render() end)
	connect(closeBtn.MouseLeave, function() hovered = false; render() end)
	onTheme(render)
	tooltip(closeBtn, "Hide menu")
end

--------------------------------------------------------------------------------
-- Window behaviour: drag, resize, scale, show/hide
--------------------------------------------------------------------------------

local baseScale = 1
do
	local MIN_W, MIN_H = Tokens.size.minWindow.X, Tokens.size.minWindow.Y
	local DEF_W, DEF_H = Tokens.size.window.X, Tokens.size.window.Y
	local wantW = Settings.menuW > 0 and Settings.menuW or DEF_W
	local wantH = Settings.menuH > 0 and Settings.menuH or DEF_H

	local function screen()
		local s = menuGui.AbsoluteSize
		if s.X > 0 then return s.X, s.Y end
		local cam = workspace.CurrentCamera
		if cam then return cam.ViewportSize.X, cam.ViewportSize.Y end
		return DEF_W + 24, DEF_H + 24
	end

	-- only screens smaller than the smallest window shrink the menu; returns the largest size that fits
	local function limits()
		local sx, sy = screen()
		local scale = math.clamp(math.min((sx - 16) / MIN_W, (sy - 16) / MIN_H), 0.55, 1)
		return math.max(MIN_W, (sx - 24) / scale), math.max(MIN_H, (sy - 24) / scale), scale
	end

	local function applySize(w, h)
		Holder.Size = UDim2.fromOffset(math.floor(w + 0.5), math.floor(h + 0.5))
		UI.layoutNav()
		UI.fitPreview()
	end

	local function fit()
		local maxW, maxH, scale = limits()
		baseScale = scale
		windowScale.Scale = scale
		applySize(math.min(wantW, maxW), math.min(wantH, maxH))
	end
	fit()
	connect(menuGui:GetPropertyChangedSignal("AbsoluteSize"), fit)

	local function isMove(input)
		return input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch
	end

	-- resize from the right edge, bottom edge or corner; the top-left stays put
	local mouse = LocalPlayer:GetMouse()
	local savedIcon, sizing
	local function setCursor(name)
		if savedIcon == nil then savedIcon = mouse.Icon end
		mouse.Icon = "rbxasset://SystemCursors/" .. name
	end
	local function clearCursor()
		if savedIcon ~= nil then
			mouse.Icon = savedIcon
			savedIcon = nil
		end
	end

	local lastCornerClick = 0
	local function handle(cursor, props, xOn, yOn)
		props.BackgroundTransparency, props.Text, props.ZIndex, props.AutoButtonColor, props.Parent = 1, "", 50, false, Window
		local b = new("TextButton", props)
		connect(b.MouseEnter, function() if not sizing then setCursor(cursor) end end)
		connect(b.MouseLeave, function() if not sizing then clearCursor() end end)
		connect(b.InputBegan, function(input)
			if not isPointer(input) then return end
			if xOn and yOn then
				if os.clock() - lastCornerClick < 0.4 then
					lastCornerClick = 0
					local w0, h0 = Holder.Size.X.Offset, Holder.Size.Y.Offset
					wantW, wantH = DEF_W, DEF_H
					Settings.menuW, Settings.menuH = 0, 0
					save()
					fit()
					local dw, dh = Holder.Size.X.Offset - w0, Holder.Size.Y.Offset - h0
					Holder.Position += UDim2.fromOffset(dw * baseScale / 2, dh * baseScale / 2)
					toast("Window size reset")
					return
				end
				lastCornerClick = os.clock()
			end
			sizing = { from = input.Position, w = Holder.Size.X.Offset, h = Holder.Size.Y.Offset, pos = Holder.Position, x = xOn, y = yOn }
		end)
		return b
	end
	local grip = handle("SizeNWSE", { Size = UDim2.fromOffset(24, 24), AnchorPoint = Vector2.new(1, 1), Position = UDim2.fromScale(1, 1) }, true, true)
	handle("SizeEW", { Size = UDim2.new(0, 6, 1, -44), Position = UDim2.new(1, -6, 0, 20) }, true, false)
	handle("SizeNS", { Size = UDim2.new(1, -44, 0, 6), Position = UDim2.new(0, 20, 1, -6) }, false, true)
	for _, g in ipairs({ { 11, 10 }, { 6, 5 } }) do
		bind(new("Frame", {
			Size = UDim2.fromOffset(g[1], 1.5), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -g[2] - 1, 1, -g[2] - 1),
			Rotation = -45, BackgroundTransparency = 0.55, BorderSizePixel = 0, ZIndex = 49, Parent = grip,
		}, { round("full") }), "BackgroundColor3", "text")
	end

	-- drag from the title area
	local dragStart, startPos
	connect(Window.InputBegan, function(input)
		if isPointer(input) and (input.Position.Y - Window.AbsolutePosition.Y) / baseScale < 120 then
			dragStart, startPos = input.Position, Holder.Position
		end
	end)

	connect(UserInputService.InputChanged, function(input)
		if not isMove(input) then return end
		if sizing then
			local d = input.Position - sizing.from
			local maxW, maxH = limits()
			local w = sizing.x and math.clamp(sizing.w + d.X / baseScale, MIN_W, maxW) or sizing.w
			local h = sizing.y and math.clamp(sizing.h + d.Y / baseScale, MIN_H, maxH) or sizing.h
			-- the window is centre-anchored, so half the change moves its centre
			Holder.Position = sizing.pos + UDim2.fromOffset((w - sizing.w) * baseScale / 2, (h - sizing.h) * baseScale / 2)
			wantW, wantH = w, h
			applySize(w, h)
		elseif dragStart then
			local d = input.Position - dragStart
			Holder.Position = startPos + UDim2.fromOffset(d.X, d.Y)
		end
	end)
	connect(UserInputService.InputEnded, function(input)
		if not isPointer(input) then return end
		dragStart = nil
		if sizing then
			sizing = nil
			clearCursor()
			Settings.menuW, Settings.menuH = math.floor(wantW + 0.5), math.floor(wantH + 0.5)
			save()
		end
	end)
end

-- A veil in the window colour covers the content while it opens and closes, which reads
-- as a fade without rendering the whole window through a CanvasGroup
local veil = new("Frame", {
	Size = UDim2.fromScale(1, 1), BorderSizePixel = 0, BackgroundTransparency = 1, Visible = false, ZIndex = 40, Parent = Window,
}, { round(Tokens.radius.lg) })
bind(veil, "BackgroundColor3", "bg")

local menuOpen, menuToken = true, 0
local function setMenuVisible(visible)
	if visible == menuOpen and visible == Holder.Visible then return end
	menuOpen = visible
	menuToken += 1
	local mine = menuToken
	hideTip()
	if visible then
		Holder.Visible = true
		veil.Visible = true
		veil.BackgroundTransparency = 0
		windowScale.Scale = baseScale * 0.96
		tweenStyle(windowScale, { Scale = baseScale }, 0.4)
		tweenStyle(veil, { BackgroundTransparency = 1 }, 0.26, Enum.EasingStyle.Quad)
		task.delay(0.3, function()
			if mine == menuToken then veil.Visible = false end
		end)
	else
		veil.Visible = true
		tweenStyle(windowScale, { Scale = baseScale * 0.96 }, 0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		tweenStyle(veil, { BackgroundTransparency = 0 }, 0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		task.delay(reducedMotion and 0 or 0.16, function()
			if mine ~= menuToken then return end
			Holder.Visible = false
			veil.Visible = false
			windowScale.Scale = baseScale
		end)
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
		setMenuVisible(not (menuOpen and Holder.Visible))
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
	local icon, paint = iconImage("eye", 20, fab)
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.Position = UDim2.fromScale(0.5, 0.5)
	onTheme(function() paint(P.text) end)
	connect(fab.Activated, function() setMenuVisible(not (menuOpen and Holder.Visible)) end)
end

--------------------------------------------------------------------------------
-- ESP
-- One renderer draws both the live overlay and the menu preview, so the
-- preview always matches what you see in game.
--------------------------------------------------------------------------------

-- Teams ------------------------------------------------------------------------
-- A player or NPC counts as a teammate from, in order: a manual mark (ally key),
-- Roblox friends (optional), a team tag the game stores in attributes or value
-- objects, then Roblox Teams / TeamColor. Lobby and free-for-all teams never
-- count, and one team that holds everyone never counts either.

-- Team names that mean "not fighting" or "everyone for themselves"
local function teamName(player)
	return player.Team and string.lower(player.Team.Name) or ""
end
local function idleTeam(name)
	return name:find("lobby") or name:find("spectat") or name:find("menu") or name:find("waiting")
		or name:find("afk") or name:find("queue") or name:find("intermission")
end
local function ffaTeam(name)
	return name:find("ffa") or name:find("free") or name:find("solo") or name:find("deathmatch")
		or name:find("everyone") or name:find("neutral")
end

local isTeammate, isAllyNpc, allyMarks
do
allyMarks = setmetatable({}, { __mode = "k" }) -- player or NPC model -> true (teammate) / false (enemy)

-- attribute / value names games use for a team
local TEAM_KEYS = {
	team = true, teamname = true, teamid = true, teamindex = true, teamnumber = true, teamcolor = true,
	teamcolour = true, side = true, squad = true, faction = true, alliance = true, allegiance = true,
	clan = true, party = true, crew = true, army = true, nation = true,
}
local NO_TEAM = { [""] = true, none = true, ["nil"] = true, null = true, neutral = true, unassigned = true, nobody = true }

-- Turns any team value into one comparable string, or nil when it means "no team"
local function teamValue(v)
	local t = typeof(v)
	if t == "Instance" then
		if not v:IsA("Team") then return "i:" .. v:GetFullName() end
		v, t = v.Name, "string"
	elseif t == "BrickColor" then
		return "c:" .. v.Name
	elseif t == "Color3" then
		return "c:" .. v:ToHex()
	elseif t == "EnumItem" then
		return "e:" .. tostring(v)
	elseif t == "number" then
		return "s:" .. tostring(v)
	end
	if t ~= "string" then return end
	local s = string.lower(v):gsub("%s+", "")
	if NO_TEAM[s] then return end
	return "s:" .. s
end

local function readTag(inst)
	if not inst then return end
	for key, v in pairs(inst:GetAttributes()) do
		if TEAM_KEYS[string.lower(key)] then
			local tag = teamValue(v)
			if tag then return tag end
		end
	end
	for _, child in ipairs(inst:GetChildren()) do
		if child:IsA("ValueBase") and TEAM_KEYS[string.lower(child.Name)] then
			local ok, v = pcall(function() return child.Value end)
			local tag = ok and teamValue(v)
			if tag then return tag end
		end
	end
end

-- Cached for a moment: these are read for every target every frame
local tagCache = setmetatable({}, { __mode = "k" })
local function tagOf(player)
	local now = os.clock()
	local c = tagCache[player]
	if c and now - c.at < 1 then return c.tag end
	local char = player.Character
	local tag = readTag(player) or readTag(char) or readTag(char and char:FindFirstChildOfClass("Humanoid"))
		or readTag(player:FindFirstChild("leaderstats")) or readTag(player:FindFirstChild("Data"))
		or readTag(player:FindFirstChild("Stats"))
	tagCache[player] = { at = now, tag = tag or false }
	return tag or false
end

-- Roblox teams as one key: the Team, or the TeamColor when the game uses colours only
local function robloxTeam(p)
	if p.Team then return p.Team end
	if not p.Neutral then return p.TeamColor end
end

-- Whether the players who are actually fighting are split over more than one team
local teamCache = { at = -1, split = false, tagSplit = false }
local function refreshSplit()
	local now = os.clock()
	if now - teamCache.at < 0.5 then return end
	teamCache.at = now
	teamCache.split, teamCache.tagSplit = false, false
	local myTeam, myTag = robloxTeam(LocalPlayer), tagOf(LocalPlayer)
	for _, other in ipairs(Players:GetPlayers()) do
		if other ~= LocalPlayer and not idleTeam(teamName(other)) then
			if robloxTeam(other) ~= myTeam then teamCache.split = true end
			local tag = tagOf(other)
			if tag and tag ~= myTag then teamCache.tagSplit = true end
		end
	end
end

-- Friend lookups are web requests, so they only run while the option is on,
-- one player at a time, and never more than once per player
local friends = setmetatable({}, { __mode = "k" })
local friendQueue, friendBusy = {}, false
local function isFriend(p)
	local known = friends[p]
	if known ~= nil then return known end
	friends[p] = false
	table.insert(friendQueue, p)
	if not friendBusy then
		friendBusy = true
		task.defer(function()
			while #friendQueue > 0 do
				local q = table.remove(friendQueue, 1)
				if q.Parent then
					local ok, yes = pcall(LocalPlayer.IsFriendsWith, LocalPlayer, q.UserId)
					friends[q] = ok and yes == true
				end
				task.wait(0.2)
			end
			friendBusy = false
		end)
	end
	return false
end

function isTeammate(player)
	if player == LocalPlayer then return true end
	local mark = allyMarks[player]
	if mark ~= nil then return mark end
	if Settings.friendsAsTeam and isFriend(player) then return true end

	-- a team the game stores itself is the most reliable signal
	local mine, theirs = tagOf(LocalPlayer), tagOf(player)
	if mine and theirs then
		if mine ~= theirs then return false end
		refreshSplit()
		-- everyone carrying the same tag means it is not really a team
		return teamCache.tagSplit or teamCache.split
	end

	local myTeam, theirTeam = robloxTeam(LocalPlayer), robloxTeam(player)
	if myTeam == nil or theirTeam ~= myTeam then return false end
	if ffaTeam(teamName(player)) or idleTeam(teamName(player)) then return false end
	refreshSplit()
	return teamCache.split
end

-- NPCs ------------------------------------------------------------------------
local OWNER_KEYS = {
	owner = true, ownerid = true, ownername = true, creator = true, creatorid = true, summoner = true,
	master = true, leader = true, player = true, playerid = true, userid = true, controller = true, spawner = true,
}
local FRIENDLY_WORDS = { "friendly", "friend", "ally", "allies", "allied", "pet", "follower", "companion", "minion", "summon" }
local HOSTILE_WORDS = { "enem", "hostile", "mob", "monster", "zombie", "bandit", "boss" }

local function playerFrom(v)
	if typeof(v) == "Instance" then
		if v:IsA("Player") then return v end
		return Players:GetPlayerFromCharacter(v)
	elseif type(v) == "number" then
		return Players:GetPlayerByUserId(v)
	elseif type(v) == "string" and v ~= "" then
		local p = Players:FindFirstChild(v)
		if p and p:IsA("Player") then return p end
		local id = tonumber(v)
		return id and Players:GetPlayerByUserId(id)
	end
end

local function ownerOf(model)
	for key, v in pairs(model:GetAttributes()) do
		if OWNER_KEYS[string.lower(key)] then
			local p = playerFrom(v)
			if p then return p end
		end
	end
	for _, child in ipairs(model:GetChildren()) do
		if child:IsA("ValueBase") and OWNER_KEYS[string.lower(child.Name)] then
			local ok, v = pcall(function() return child.Value end)
			local p = ok and playerFrom(v)
			if p then return p end
		end
	end
end

local function hasWord(name, words)
	for _, w in ipairs(words) do
		if name:find(w, 1, true) then return true end
	end
	return false
end

local function npcAlly(model)
	-- pets, summons and turrets belong to someone
	local owner = ownerOf(model)
	if owner then return isTeammate(owner) end

	-- a team tag on the NPC, compared with every way our own team is written
	local theirs = readTag(model) or readTag(model:FindFirstChildOfClass("Humanoid"))
	if theirs then
		local mine = tagOf(LocalPlayer)
		if mine and theirs == mine then return true end
		if LocalPlayer.Team then
			return theirs == teamValue(LocalPlayer.Team) or theirs == "c:" .. LocalPlayer.TeamColor.Name
				or theirs == "i:" .. LocalPlayer.Team:GetFullName()
		end
		return false
	end

	-- the name, or the folders it lives in: workspace.Red.NPCs, workspace.Allies, workspace.Enemies ...
	local name = string.lower(model.Name)
	if hasWord(name, HOSTILE_WORDS) then return false end
	if hasWord(name, FRIENDLY_WORDS) then return true end
	local myTeamName = LocalPlayer.Team and string.lower(LocalPlayer.Team.Name):gsub("%s+", "")
	local node = model.Parent
	while node and node ~= workspace and node ~= game do
		local n = string.lower(node.Name):gsub("%s+", "")
		if myTeamName and #myTeamName >= 3 and n:find(myTeamName, 1, true) then return true end
		if hasWord(n, HOSTILE_WORDS) then return false end
		if hasWord(n, FRIENDLY_WORDS) then return true end
		node = node.Parent
	end
	return false
end

local npcCache = setmetatable({}, { __mode = "k" })
function isAllyNpc(model)
	local mark = allyMarks[model]
	if mark ~= nil then return mark end
	local now = os.clock()
	local c = npcCache[model]
	if c and now - c.at < 1 then return c.ally end
	local ok, ally = pcall(npcAlly, model)
	ally = ok and ally == true
	npcCache[model] = { at = now, ally = ally }
	return ally
end
end

-- Players in a lobby or spectating while we fight, or still spawn-protected, can't be hit
local function isCombatant(player)
	local theirs = teamName(player)
	if idleTeam(theirs) and theirs ~= teamName(LocalPlayer) then return false end
	local char = player.Character
	if char and char:FindFirstChildOfClass("ForceField") then return false end
	return true
end

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

-- `extra` is the player's real character when they are drawn as a separate model
local function isVisible(camera, part, char, extra)
	rayParams.FilterDescendantsInstances = { camera, LocalPlayer.Character, char, extra }
	local origin = camera.CFrame.Position
	return workspace:Raycast(origin, part.Position - origin, rayParams) == nil
end

--------------------------------------------------------------------------------
-- Visible bodies
-- Some games keep a player's real Character as an invisible, server-delayed
local bodyOf, outline, Esp, removeEsp, espStep, npcModels
do
-- decoy and show a separate model instead. Every character-like model is
-- tracked, matched to its player a few times a second, and the match is what
-- ESP, aimbot and silent aim follow. Per frame this is a single table lookup.
--------------------------------------------------------------------------------

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
	-- names like "Name_Combat" or "Body_Name"
	if #player.Name >= 4 and string.find(name, player.Name, 1, true) then return true end
	-- attributes are not checked: games store things like "last hit by" there, which named the wrong body
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
			-- skip our own visible body and first-person arms
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

	-- Some games park every real Character at one spot and fight with copies
	-- elsewhere; characters stacked inside each other are parked decoys.
	local roots = {}
	for _, p in ipairs(Players:GetPlayers()) do
		local r = p.Character and bodyRoot(p.Character)
		if r then roots[p] = r.Position end
	end
	local function parked(p)
		local pos = roots[p]
		if not pos then return false end
		for other, q in pairs(roots) do
			if other ~= p and (q - pos).Magnitude < 2 then return true end
		end
		return false
	end

	local waiting = {}
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer then
			local isParked = parked(p)
			-- a parked decoy is only swapped for a model that names its owner; guessing by distance would pick NPCs
			local needs = not isParked and (mode == "Visible" or not p.Character or looksHidden(p.Character))
			-- a model that names its owner wins, but only when the real character can't be used
			for _, body in ipairs((needs or isParked) and free or {}) do
				if not body.taken and ownedBy(body.model, p) then
					bodyChoice[p] = body.model
					body.taken = true
					break
				end
			end
			if not bodyChoice[p] and needs then
				-- keep an earlier match so the box never jumps between models
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

	-- whoever is left: pair with the nearest unclaimed model
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

-- NPCs: living Humanoid models that are not a player, a player's visible body, or ours
npcModels = {}
local function refreshNpcs()
	table.clear(npcModels)
	if Settings.aimTargets == "Players" and Settings.silentTargets == "Players" and not Settings.npcEsp then return end
	local owned = {}
	for _, p in ipairs(Players:GetPlayers()) do
		if p.Character then owned[p.Character] = true end
		if bodyChoice[p] then owned[bodyChoice[p]] = true end
	end
	local myChar = LocalPlayer.Character
	local camera = workspace.CurrentCamera
	for model in pairs(bodyModels) do
		if model.Parent and not owned[model] and model:IsDescendantOf(workspace)
			and not (myChar and model:IsDescendantOf(myChar)) then
			local outer = model:FindFirstAncestorWhichIsA("Model")
			local hum = model:FindFirstChildOfClass("Humanoid")
			local root = bodyRoot(model)
			if hum and hum.Health > 0 and root and root:IsA("BasePart") and not (outer and owned[outer])
				and not (camera and (root.Position - camera.CFrame.Position).Magnitude < 4) then
				table.insert(npcModels, model)
			end
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
			refreshNpcs()
		end
	end)
end

-- The model to draw and aim at, plus the Humanoid that holds health
function bodyOf(player)
	local char = player.Character
	local body = bodyChoice[player]
	if not (body and body.Parent) then body = char end
	local hum = (char and char:FindFirstChildOfClass("Humanoid")) or (body and body:FindFirstChildOfClass("Humanoid"))
	return body, hum
end

-- Diagnostics: a snapshot of how this game builds player models, written to the
-- executor's workspace folder (Vigil-debug.txt) every 5 s for the first 3 minutes.
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

	-- folders that often hold the models players actually fight with
	for _, folderName in ipairs({ "CombatPlayers", "Solo", "GameBC", "Debris" }) do
		local folder = workspace:FindFirstChild(folderName)
		if folder then
			add("-- %s", folder:GetFullName())
			for i, k in ipairs(folder:GetDescendants()) do
				if i > 80 then break end
				local extra = k:IsA("BasePart") and (" " .. vec(k.Position)) or ""
				add("  %s:%s%s", k:GetFullName(), k.ClassName, extra)
			end
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
	while os.clock() - started < 900 and ENV.Vigil ~= nil do
		task.wait(8)
		pcall(writeDump)
	end
end)

-- Body height above/below its root, refreshed twice a second instead of every frame
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
	-- chevron pointing right; the container rotates toward the player
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

-- t = { char, root, colour, hidden, name, distance, item, health (0-1), healthValue }
-- project(worldPos) -> screenPos, depth; view = { size, tracerFrom, preview }
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

-- Live overlay ---------------------------------------------------------------

Esp = {} -- Player or NPC model -> its visual
local npcShown = {}
local NPC_COLOUR = Color3.fromRGB(255, 170, 60) -- NPCs always read apart from players

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

	-- NPC visuals follow the NPC list: added when one appears, dropped when it dies or leaves
	table.clear(npcShown)
	if Settings.enabled and Settings.npcEsp then
		for _, model in ipairs(npcModels) do
			npcShown[model] = true
			createEsp(model)
		end
	end
	for target in pairs(Esp) do
		if not target:IsA("Player") and not npcShown[target] then removeEsp(target) end
	end

	for player, o in pairs(Esp) do
		local isNpc = not player:IsA("Player")
		local char, hum
		if isNpc then
			char, hum = player, player:FindFirstChildOfClass("Humanoid")
		else
			char, hum = bodyOf(player)
		end
		local root = char and bodyRoot(char)
		local alive = root ~= nil and (hum == nil or hum.Health > 0)

		if not (Settings.enabled and alive) or (Settings.teamCheck and (if isNpc then isAllyNpc(player) else isTeammate(player))) then
			hideVisual(o)
			continue
		end
		local distance = (camPos - root.Position).Magnitude
		if distance > Settings.maxDistance then
			hideVisual(o)
			continue
		end

		local colour, hidden, tool
		if isNpc then
			colour = NPC_COLOUR
			hidden = Settings.visCheck and not isVisible(camera, root, char)
			tool = char:FindFirstChildOfClass("Tool")
		else
			colour = (Settings.teamColour and player.Team) and player.TeamColor.Color or baseColour
			hidden = Settings.visCheck and not isVisible(camera, root, char, player.Character)
			tool = char:FindFirstChildOfClass("Tool") or (player.Character and player.Character:FindFirstChildOfClass("Tool"))
		end

		-- only touch the Highlight when something changed; rewriting it every frame is costly
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
			name = isNpc and player.Name or player.DisplayName, distance = distance, item = tool and tool.Name,
			health = hum and math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1),
			healthValue = hum and math.floor(hum.Health + 0.5),
		}, project, view)
	end
end

for _, player in ipairs(Players:GetPlayers()) do createEsp(player) end
connect(Players.PlayerAdded, createEsp)
connect(Players.PlayerRemoving, removeEsp)
-- espStep runs from the render step after the camera updates (see the per-frame driver)

-- Menu preview -----------------------------------------------------------------

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

--------------------------------------------------------------------------------
-- Targeting (shared by aimbot and silent aim)
--------------------------------------------------------------------------------
local RENDER_STEP, findTarget, circle, placeCircle, focus
do
focus = {} -- focus.target: a player picked in the player list, preferred whenever valid

RENDER_STEP = "VigilRender"

local function candidateParts(char, mode)
	local head = char:FindFirstChild("Head")
	local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") or char:FindFirstChild("HumanoidRootPart")
	head = (head and head:IsA("BasePart")) and head or nil
	torso = (torso and torso:IsA("BasePart")) and torso or nil
	head, torso = head or torso, torso or head -- NPCs are often missing one of them
	if mode == "Head" then return { head } end
	if mode == "Torso" then return { torso } end
	return { head, torso } -- "Closest": whichever sits nearer the cursor
end

-- cfg = { part, team, visible, maxDistance, fov, priority, targets }
-- A target is a Player or an NPC model. Returns its best part plus screen and world distance, or nil
local function evaluate(target, camera, mouse, cfg)
	local who = cfg.targets or "Players"
	local char, hum, extra
	if target:IsA("Player") then
		if who == "NPCs" then return end
		char, hum = bodyOf(target)
		if not char or (hum and hum.Health <= 0) then return end
		if cfg.team and isTeammate(target) then return end
		if not isCombatant(target) then return end
		extra = target.Character
	else
		if who == "Players" or not target:IsDescendantOf(workspace) then return end
		char, hum = target, target:FindFirstChildOfClass("Humanoid")
		if not hum or hum.Health <= 0 then return end
		if cfg.team and isAllyNpc(target) then return end
	end
	local camPos = camera.CFrame.Position
	local full = cfg.fov >= FOV_FULL
	local best, bestScreen, bestWorld, bestSeen
	for _, part in pairs(candidateParts(char, cfg.part)) do
		if not part.Parent then continue end
		local worldDist = (camPos - part.Position).Magnitude
		if worldDist <= cfg.maxDistance then
			local screen, onScreen = camera:WorldToViewportPoint(part.Position)
			if onScreen or full then
				-- off-screen targets rank after every on-screen one
				local screenDist = onScreen and (Vector2.new(screen.X, screen.Y) - mouse).Magnitude or 1e5 + worldDist
				if (full or screenDist <= cfg.fov) and (not bestScreen or screenDist < bestScreen) then
					local seen = isVisible(camera, part, char, extra)
					if seen or not cfg.visible then
						best, bestScreen, bestWorld, bestSeen = part, screenDist, worldDist, seen
					end
				end
			end
		end
	end
	if cfg.anyPart and not bestSeen then
		for _, part in pairs(candidateParts(char, "Closest")) do
			if part ~= best and part.Parent then
				local worldDist = (camPos - part.Position).Magnitude
				local screen, onScreen = camera:WorldToViewportPoint(part.Position)
				local screenDist = onScreen and (Vector2.new(screen.X, screen.Y) - mouse).Magnitude or 1e5 + worldDist
				if worldDist <= cfg.maxDistance and (onScreen or full) and (full or screenDist <= cfg.fov)
					and isVisible(camera, part, char, extra) then
					return part, screenDist, worldDist, true
				end
			end
		end
	end
	return best, bestScreen, bestWorld, bestSeen
end

-- Keeps `current` while it stays valid, otherwise picks the best player in the field of view
local hiddenSince = setmetatable({}, { __mode = "k" }) -- player -> when they went behind cover

function findTarget(camera, mouse, cfg, current)
	local function scoreOf(screenDist, worldDist, seen)
		-- targets that can be hit always rank ahead of ones behind walls
		return (cfg.priority == "Distance" and worldDist or screenDist) + (seen and 0 or 1e7)
	end

	-- a focused player wins whenever they can be targeted at all
	local f = focus.target
	if f and f.Parent and (cfg.targets or "Players") ~= "NPCs" then
		local part = evaluate(f, camera, mouse, cfg)
		if part then return f, part end
	end

	-- the current target is kept unless it is gone, or has been behind cover for a moment
	local now = os.clock()
	local keepPart, keepScore
	if current and current.Parent then
		local part, screenDist, worldDist, seen = evaluate(current, camera, mouse, cfg)
		if part then
			if seen then
				hiddenSince[current] = nil
			elseif not hiddenSince[current] then
				hiddenSince[current] = now
			end
			local hiddenFor = seen and 0 or now - hiddenSince[current]
			if hiddenFor < 0.5 then
				keepPart, keepScore = part, scoreOf(screenDist, worldDist, true)
				if cfg.sticky then return current, part end
			end
		end
	end

	local bestPlayer, bestPart, bestScore
	local function consider(target)
		if target == current then return end
		local part, screenDist, worldDist, seen = evaluate(target, camera, mouse, cfg)
		if part then
			local score = scoreOf(screenDist, worldDist, seen)
			if not bestScore or score < bestScore then
				bestPlayer, bestPart, bestScore = target, part, score
			end
		end
	end
	local who = cfg.targets or "Players"
	if who ~= "NPCs" then
		for _, player in ipairs(Players:GetPlayers()) do
			if player ~= LocalPlayer then consider(player) end
		end
	end
	if who ~= "Players" then
		for _, model in ipairs(npcModels) do consider(model) end
	end
	-- only leave the current target for one that is clearly better, so the aim never flicks between two
	if keepPart and (not bestScore or bestScore > keepScore * 0.6 - 25) then
		return current, keepPart
	end
	if current then hiddenSince[current] = nil end
	return bestPlayer, bestPart
end

-- Mark teammate key: teammate -> enemy -> automatic, for whoever is nearest the cursor
connect(UserInputService.InputBegan, function(input)
	if keyCapture or input == consumedInput or UserInputService:GetFocusedTextBox() then return end
	if inputName(input) ~= Settings.allyKey then return end
	local camera = workspace.CurrentCamera
	if not camera then return end
	local mouse = UserInputService:GetMouseLocation()
	local best, bestDist, bestName = nil, 200, nil
	local function try(target, model, label)
		local root = model and (model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart or model:FindFirstChild("Head"))
		if root and not root:IsA("BasePart") then return end
		if not root then return end
		local head = model:FindFirstChild("Head")
		local pos = (head and head:IsA("BasePart")) and head.Position or root.Position
		local screen, onScreen = camera:WorldToViewportPoint(pos)
		if not onScreen then return end
		local d = (Vector2.new(screen.X, screen.Y) - mouse).Magnitude
		if d < bestDist then best, bestDist, bestName = target, d, label end
	end
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer then try(p, (bodyOf(p)), p.DisplayName) end
	end
	for _, model in ipairs(npcModels) do try(model, model, model.Name) end
	if not best then
		toast("Point at a player or NPC first")
		return
	end
	local mark = allyMarks[best]
	if mark == nil then
		allyMarks[best] = true
		toast(bestName .. " marked as teammate")
	elseif mark == true then
		allyMarks[best] = false
		toast(bestName .. " marked as enemy")
	else
		allyMarks[best] = nil
		toast(bestName .. " back to automatic")
	end
end)

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
	-- thickness changes too, so a lock reads without relying on colour
	stroke.Thickness = locked and 2 or 1
	stroke.Color = locked and P.accent or World.label
	stroke.Transparency = locked and 0 or 0.25
end
end

--------------------------------------------------------------------------------
-- Aimbot
--------------------------------------------------------------------------------
local motion, aimStep, mouseAim
do

local fovCircle, fovStroke = circle(false)
local currentTarget

-- Velocity measured from on-screen movement. Visible models are often anchored
-- and moved by the game, so their physics velocity reads zero.
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

-- Mouse aiming works in angles: each game turns the camera by its own number of
-- degrees per mouse pixel, so that ratio is measured from how far each move turned it.
local mouseCal = { degPerPixel = 0.25, sentX = 0, sentY = 0 }
local function cameraAngles(cf)
	local look = cf.LookVector
	return math.deg(math.atan2(-look.X, -look.Z)), math.deg(math.asin(math.clamp(look.Y, -1, 1)))
end
local function wrapAngle(a)
	return (a + 180) % 360 - 180
end
function mouseAim(camera, aimPos, gain)
	local cf = camera.CFrame
	local yaw, pitch = cameraAngles(cf)
	-- learn degrees per pixel from the last move
	local cal = mouseCal
	if cal.yaw and math.abs(cal.sentX) >= 4 then
		local turned = math.abs(wrapAngle(yaw - cal.yaw))
		local sample = turned / math.abs(cal.sentX)
		if sample > 0.005 and sample < 3 then
			cal.degPerPixel = cal.degPerPixel * 0.85 + sample * 0.15
		end
	end
	local d = cf:VectorToObjectSpace(aimPos - cf.Position)
	local yawErr = math.deg(math.atan2(d.X, -d.Z)) -- positive: target is to the right
	local pitchErr = math.deg(math.atan2(d.Y, math.sqrt(d.X * d.X + d.Z * d.Z))) -- positive: above
	local k = cal.degPerPixel
	local dx = math.clamp(yawErr / k * gain, -2000, 2000)
	local dy = math.clamp(-pitchErr / k * gain, -2000, 2000)
	cal.yaw, cal.sentX, cal.sentY = yaw, dx, dy
	if math.abs(dx) >= 0.5 or math.abs(dy) >= 0.5 then
		mousemoverel(math.round(dx), math.round(dy))
	end
end

function aimStep(camera, mouse, dt)
	if Settings.aimMode ~= "Toggle" or not Settings.aimEnabled then aimToggled = false end
	local active = false
	if Settings.aimEnabled and not keyCapture and not Holder.Visible and not UserInputService:GetFocusedTextBox() then
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
			sticky = Settings.stickyTarget, targets = Settings.aimTargets,
		}, currentTarget)
	else
		currentTarget = nil
	end

	placeCircle(fovCircle, fovStroke, Settings.aimEnabled and Settings.showFov and Settings.fov < FOV_FULL, mouse, Settings.fov, part ~= nil)
	if not part then return end

	local aimPos = part.Position
	if Settings.prediction > 0 then
		aimPos += measuredVelocity(part) * (Settings.prediction / 1000)
	end
	-- frame-rate independent easing; smoothing 1 snaps
	local alpha = Settings.smoothing <= 1 and 1 or 1 - (1 - 1 / Settings.smoothing) ^ (dt * 60)

	local method = Settings.aimMethod
	if method == "Auto" then
		-- a Scriptable camera is driven by the game every frame and would undo a camera turn
		method = (canMoveMouse and camera.CameraType == Enum.CameraType.Scriptable) and "Mouse" or "Camera"
	end

	if method == "Mouse" and canMoveMouse then
		-- with a free cursor (a game menu, say) only a held key may move it
		if Settings.aimMode ~= "Hold" and UserInputService.MouseBehavior == Enum.MouseBehavior.Default then return end
		mouseAim(camera, aimPos, Settings.smoothing <= 1 and 0.6 or alpha * 0.6)
	else
		local cf = camera.CFrame
		camera.CFrame = cf:Lerp(CFrame.lookAt(cf.Position, aimPos), alpha)
	end
end
end

--------------------------------------------------------------------------------
-- Silent aim
-- Each frame the target is resolved on our own thread; the hooks only read the
local hookState, silent, silentStep
do
-- cached result, and checkcaller() keeps our own raycasts untouched.
--------------------------------------------------------------------------------

hookState = { alive = true }
silent = { active = false, mouse = Vector2.zero, inset = Vector2.zero, roll = true, rolledAt = 0, guiPress = false, releasedAt = 0 }

-- True only while the player is shooting. Without this the hooks would feed the target
-- to everything in the game that reads the mouse: custom cursors, menus, head tracking.
-- A direct call, because the hooks run inside the game's own metamethods.
local isPressed = UserInputService.IsMouseButtonPressed
local LEFT_MOUSE = Enum.UserInputType.MouseButton1
local function shooting()
	if touchOnly then return true end
	if isPressed(UserInputService, LEFT_MOUSE) then return not silent.guiPress end
	return os.clock() - silent.releasedAt < 0.12 -- some games fire a moment after the release
end

-- A press that lands on a button or menu is not a shot, and stays that way until released
connect(UserInputService.InputBegan, function(input, gameProcessed)
	if input.UserInputType == LEFT_MOUSE then silent.guiPress = gameProcessed end
end)
connect(UserInputService.InputEnded, function(input)
	if input.UserInputType ~= LEFT_MOUSE then return end
	if not silent.guiPress then silent.releasedAt = os.clock() end
	silent.guiPress = false
end)

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
		-- passing the last target keeps a burst on one enemy instead of flipping between two
		silent.target, part = findTarget(camera, mouse, {
			part = Settings.silentPart, team = Settings.silentTeamCheck, visible = Settings.silentVisibleOnly,
			maxDistance = Settings.silentMaxDistance, fov = Settings.silentFov, priority = "Crosshair",
			targets = Settings.silentTargets, anyPart = true,
		}, silent.target)
	else
		silent.target = nil
	end

	placeCircle(silentCircle, silentStroke, enabled and Settings.showSilentFov and Settings.silentFov < FOV_FULL, mouse, Settings.silentFov, part ~= nil)
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
	silent.camPos, silent.aimDir, silent.dirTo = camPos, mouseRay.Direction, unit
	local mine = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	silent.myPos = mine and mine.Position or camPos
	local target = silent.target
	if Settings.silentVisibleOnly then
		silent.seen = true
	elseif target:IsA("Player") then
		silent.seen = isVisible(camera, part, (bodyOf(target)), target.Character)
	else
		silent.seen = isVisible(camera, part, target)
	end
	-- the roll is held for a moment, so hit chance decides per shot and never flickers per frame
	local now = os.clock()
	if now - silent.rolledAt > 0.15 then
		silent.rolledAt = now
		silent.roll = math.random(1, 100) <= Settings.hitChance
	end
	silent.active = silent.roll

	marker.Visible = Settings.showSilentTarget
	marker.Position = UDim2.fromOffset(screen.X, screen.Y)
	markerStroke.Color = P.accent
end

-- Bends a shot toward the target, but only shots fired roughly where the player is aiming.
-- Returns the new direction and where the shot should start.
local function redirect(origin, direction)
	local length = direction.Magnitude
	if length < 1e-3 then return end
	local toAim = silent.aimPoint - origin
	if toAim.Magnitude < 1e-3 or direction.Unit:Dot(toAim.Unit) < 0.6 then return end
	local target = silent.position
	if Settings.silentWalls and not silent.seen then
		-- start right in front of the target, so nothing in between can stop the shot
		origin = target - silent.dirTo * 3
	end
	local toTarget = target - origin
	return toTarget.Unit * math.max(length, toTarget.Magnitude * 1.05), origin
end

-- Games that send the shot to the server pass the aim along as a direction, a point or a
-- CFrame. Only values that clearly match where the player is aiming are replaced.
local function bendArg(v, depth)
	local kind = typeof(v)
	if kind == "Vector3" then
		local m = v.Magnitude
		if m > 0.9 and m < 1.1 then
			if v:Dot(silent.aimDir) > 0.97 then return silent.dirTo end
		elseif m > 0 then
			local fromCam = v - silent.camPos
			if fromCam.Magnitude > 12 and (v - silent.myPos).Magnitude > 8 and fromCam.Unit:Dot(silent.aimDir) > 0.995 then
				return silent.position
			end
		end
	elseif kind == "CFrame" then
		if (v.Position - silent.camPos).Magnitude < 40 and v.LookVector:Dot(silent.aimDir) > 0.97 then
			return CFrame.lookAt(v.Position, silent.position)
		end
	elseif kind == "table" and depth < 2 and getmetatable(v) == nil then
		local copy
		for key, item in pairs(v) do
			local bent = bendArg(item, depth + 1)
			if not rawequal(bent, item) then
				copy = copy or table.clone(v)
				copy[key] = bent
			end
		end
		return copy or v
	end
	return v
end

local RayMethods = { FindPartOnRay = true, FindPartOnRayWithIgnoreList = true, FindPartOnRayWithWhitelist = true }
local Shapecasts = { Spherecast = true, Blockcast = true }
local Remotes = { FireServer = true, InvokeServer = true }
local MouseSpoof = { Hit = true, Target = true, UnitRay = true }
local Redirected = {
	Raycast = true, FindPartOnRay = true, FindPartOnRayWithIgnoreList = true, FindPartOnRayWithWhitelist = true,
	ViewportPointToRay = true, ScreenPointToRay = true, Spherecast = true, Blockcast = true, FireServer = true, InvokeServer = true,
}

if canHook then
	local wrap = typeof(newcclosure) == "function" and newcclosure or function(f) return f end

	local oldNamecall
	oldNamecall = hookmetamethod(game, "__namecall", wrap(function(self, ...)
		if hookState.alive and silent.active and not checkcaller() then
			local method = getnamecallmethod()
			if not Redirected[method] or not shooting() then
				return oldNamecall(self, ...)
			end
			if method == "Raycast" and Settings.silentRaycast then
				local origin, direction = ...
				if typeof(origin) == "Vector3" and typeof(direction) == "Vector3" then
					local bent, start = redirect(origin, direction)
					if bent then
						local args = table.pack(...)
						args[1], args[2] = start, bent
						return oldNamecall(self, table.unpack(args, 1, args.n))
					end
				end
			elseif RayMethods[method] and Settings.silentRaycast then
				local ray = ...
				if typeof(ray) == "Ray" then
					local bent, start = redirect(ray.Origin, ray.Direction)
					if bent then
						local args = table.pack(...)
						args[1] = Ray.new(start, bent)
						return oldNamecall(self, table.unpack(args, 1, args.n))
					end
				end
			elseif Shapecasts[method] and Settings.silentRaycast then
				local args = table.pack(...)
				local from, direction = args[1], args[3]
				local isCFrame = typeof(from) == "CFrame"
				local pos = isCFrame and from.Position or from
				if typeof(pos) == "Vector3" and typeof(direction) == "Vector3" then
					local bent, start = redirect(pos, direction)
					if bent then
						args[1] = isCFrame and (from - pos + start) or start
						args[3] = bent
						return oldNamecall(self, table.unpack(args, 1, args.n))
					end
				end
			elseif Remotes[method] and Settings.silentRemotes then
				local args = table.pack(...)
				local changed = false
				for i = 1, args.n do
					local bent = bendArg(args[i], 0)
					if not rawequal(bent, args[i]) then
						args[i] = bent
						changed = true
					end
				end
				if changed then return oldNamecall(self, table.unpack(args, 1, args.n)) end
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
	local isA = game.IsA
	local oldIndex
	oldIndex = hookmetamethod(game, "__index", wrap(function(self, key)
		-- X and Y stay real: games draw their cursors and menus from them
		if hookState.alive and silent.active and MouseSpoof[key] and Settings.silentMouse and not checkcaller()
			and (rawequal(self, mouseObject) or (typeof(self) == "Instance" and isA(self, "Mouse"))) and shooting() then
			if key == "Hit" then
				return silent.hitCFrame
			elseif key == "Target" then
				return silent.part
			end
			return silent.unitRay
		end
		return oldIndex(self, key)
	end))
end
end

--------------------------------------------------------------------------------
-- Visuals
-- enforce() remembers a property's original value the first time it is
local enforce, release, releaseAll, visualsStep
do
-- overridden; release() puts it back.
--------------------------------------------------------------------------------

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
	-- looking for Atmosphere objects once a second is plenty
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

--------------------------------------------------------------------------------
-- Movement
--------------------------------------------------------------------------------
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

--------------------------------------------------------------------------------
-- Triggerbot, radar and panic key
--------------------------------------------------------------------------------
local triggerStep, radarStep, releaseTrigger
do

-- Triggerbot -------------------------------------------------------------------
-- Fires while the crosshair sits on an enemy: holds the button for automatic
-- weapons, or taps it for semi-automatic ones.
local canPress = typeof(mouse1press) == "function" and typeof(mouse1release) == "function"
local canClick = typeof(mouse1click) == "function" or canPress
local triggerParams = RaycastParams.new()
triggerParams.FilterType = Enum.RaycastFilterType.Exclude
local trig = { held = false, seenAt = nil, lastTap = 0 }

local function click()
	if typeof(mouse1click) == "function" then
		mouse1click()
	elseif canPress then
		mouse1press()
		task.delay(0.03, mouse1release)
	end
end

function releaseTrigger()
	if trig.held and canPress then pcall(mouse1release) end
	trig.held, trig.seenAt = false, nil
end

-- The player or NPC that owns a hit part, if it is a live enemy the settings allow
local function enemyFromPart(part)
	local who = Settings.aimTargets
	local node = part
	while node and node ~= workspace do
		if node.ClassName == "Model" then
			local hum = node:FindFirstChildOfClass("Humanoid")
			local player = Players:GetPlayerFromCharacter(node)
			if not player then
				for _, p in ipairs(Players:GetPlayers()) do
					if p ~= LocalPlayer and bodyOf(p) == node then player = p break end
				end
			end
			if player then
				if player == LocalPlayer or who == "NPCs" then return end
				local _, h = bodyOf(player)
				hum = h or hum
				if hum and hum.Health <= 0 then return end
				if Settings.aimTeamCheck and isTeammate(player) then return end
				if not isCombatant(player) then return end
				return player
			end
			if hum then
				if who == "Players" or hum.Health <= 0 then return end
				if Settings.aimTeamCheck and isAllyNpc(node) then return end
				return node
			end
		end
		node = node.Parent
	end
end

function triggerStep(camera, mouse)
	local active = Settings.triggerEnabled and canClick and not Holder.Visible
		and not keyCapture and not UserInputService:GetFocusedTextBox()
		and (Settings.triggerMode == "Always" or isBindDown(Settings.aimKey))
	local target
	if active then
		local ray = camera:ViewportPointToRay(mouse.X, mouse.Y)
		triggerParams.FilterDescendantsInstances = { camera, LocalPlayer.Character }
		local hit = workspace:Raycast(ray.Origin, ray.Direction * 3000, triggerParams)
		target = hit and enemyFromPart(hit.Instance)
	end
	if not target then
		if trig.held then releaseTrigger() end
		trig.seenAt = nil
		return
	end
	local now = os.clock()
	trig.seenAt = trig.seenAt or now
	if now - trig.seenAt < Settings.triggerDelay / 1000 then return end
	if Settings.triggerFire == "Hold" and canPress then
		if not trig.held then
			trig.held = true
			mouse1press()
		end
	elseif now - trig.lastTap >= 1 / math.max(Settings.triggerRate, 1) then
		trig.lastTap = now
		click()
	end
end

-- Radar ------------------------------------------------------------------------
local RADAR_SIZE = 168
local radar = new("Frame", {
	Name = "Radar", Size = UDim2.fromOffset(RADAR_SIZE, RADAR_SIZE), BorderSizePixel = 0,
	Position = UDim2.fromOffset(Tokens.space.lg, Tokens.space.lg + 36), BackgroundTransparency = 0.15,
	Visible = false, Parent = espGui,
}, { round("full") })
local radarStroke = new("UIStroke", { Thickness = 1, Transparency = 0.2, Parent = radar })
local function radarLine(horizontal)
	return new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), BorderSizePixel = 0,
		BackgroundTransparency = 0.6, Size = horizontal and UDim2.new(1, -16, 0, 1) or UDim2.new(0, 1, 1, -16),
		Parent = radar,
	})
end
local radarLines = { radarLine(true), radarLine(false) }
local ring = new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.5, 0.5),
	BackgroundTransparency = 1, Parent = radar,
}, { round("full") })
local ringStroke = new("UIStroke", { Thickness = 1, Transparency = 0.7, Parent = ring })
-- you: a small arrow pointing where the camera looks (always up)
local me = new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(6, 6),
	BorderSizePixel = 0, Parent = radar,
}, { round("full") })

local dots = {}
local function dot(i)
	local d = dots[i]
	if not d then
		d = new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(7, 7), BorderSizePixel = 0,
			ZIndex = 2, Parent = radar,
		}, { round("full") })
		new("UIStroke", { Thickness = 1, Color = Color3.new(0, 0, 0), Transparency = 0.4, Parent = d })
		dots[i] = d
	end
	return d
end

local TEAMMATE_DOT = Color3.fromRGB(120, 200, 255)
local NPC_DOT = Color3.fromRGB(255, 170, 60)

function radarStep(camera)
	local on = Settings.radarEnabled
	radar.Visible = on
	if not on then return end
	radar.BackgroundColor3 = P.bg
	radarStroke.Color = P.border
	ringStroke.Color = P.border
	for _, l in ipairs(radarLines) do l.BackgroundColor3 = P.border end
	me.BackgroundColor3 = P.accent

	local cf = camera.CFrame
	local look = Vector3.new(cf.LookVector.X, 0, cf.LookVector.Z)
	if look.Magnitude < 1e-3 then look = Vector3.new(0, 0, -1) end
	look = look.Unit
	local right = Vector3.new(-look.Z, 0, look.X)
	local myChar = LocalPlayer.Character
	local myRoot = myChar and (myChar:FindFirstChild("HumanoidRootPart") or myChar.PrimaryPart)
	local centre = myRoot and myRoot.Position or cf.Position
	local half = RADAR_SIZE / 2 - 6
	local scale = half / Settings.radarRange
	local enemyColour = EspColours[Settings.espColour][2]
	local used = 0

	local function place(model, colour)
		local root = model and (model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart or model:FindFirstChild("Head"))
		if not (root and root:IsA("BasePart")) then return end
		local rel = root.Position - centre
		local x, y = rel:Dot(right) * scale, -rel:Dot(look) * scale
		local len = math.sqrt(x * x + y * y)
		local edge = len > half
		if edge then x, y = x / len * half, y / len * half end
		used += 1
		local d = dot(used)
		d.Position = UDim2.new(0.5, x, 0.5, y)
		d.BackgroundColor3 = colour
		d.BackgroundTransparency = edge and 0.55 or 0
		d.Visible = true
	end

	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer then
			local char, hum = bodyOf(p)
			if char and not (hum and hum.Health <= 0) then
				local mate = isTeammate(p)
				if not (mate and Settings.radarTeam == false) then
					local colour = mate and TEAMMATE_DOT
						or ((Settings.teamColour and p.Team) and p.TeamColor.Color or enemyColour)
					place(char, colour)
				end
			end
		end
	end
	if Settings.npcEsp then
		for _, model in ipairs(npcModels) do
			if not (Settings.radarTeam == false and isAllyNpc(model)) then
				place(model, isAllyNpc(model) and TEAMMATE_DOT or NPC_DOT)
			end
		end
	end
	for i = used + 1, #dots do dots[i].Visible = false end
end

-- Panic key ----------------------------------------------------------------------
-- One press hides the menu and turns every feature off; the next press puts them back.
local PANIC_KEYS = {
	"enabled", "aimEnabled", "silentEnabled", "triggerEnabled", "radarEnabled", "fullbright", "noFog",
	"lockTime", "camFovEnabled", "crosshair", "speedEnabled", "jumpEnabled", "infiniteJump", "fly",
	"noclip", "clickTp", "showModules", "spin", "hitmarker",
}
local panicSaved

connect(UserInputService.InputBegan, function(input)
	if keyCapture or input == consumedInput or UserInputService:GetFocusedTextBox() then return end
	if inputName(input) ~= Settings.panicKey then return end
	if panicSaved then
		for k, v in pairs(panicSaved) do Settings[k] = v end
		panicSaved = nil
	else
		panicSaved = {}
		for _, k in ipairs(PANIC_KEYS) do
			panicSaved[k] = Settings[k]
			Settings[k] = false
		end
		setMenuVisible(false)
		releaseTrigger()
	end
	save()
	applyTheme() -- re-renders every switch from Settings
end)
end

--------------------------------------------------------------------------------
-- Player list, server tools, configs, waypoints, hitmarker, freecam and spin
--------------------------------------------------------------------------------
local features, freecamStep
do
features = { kills = 0, freecam = false, spectate = nil }

local TeleportService = game:GetService("TeleportService")
local SoundService = game:GetService("SoundService")

local function rootOf(model)
	local r = model and (model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart or model:FindFirstChild("Head"))
	return (r and r:IsA("BasePart")) and r or nil
end

local function myRoot()
	return rootOf(LocalPlayer.Character)
end

local function readJson(path)
	if not canSave then return nil end
	local ok, data = pcall(function()
		return isfile(path) and HttpService:JSONDecode(readfile(path)) or nil
	end)
	return ok and type(data) == "table" and data or nil
end

local function writeJson(path, data)
	if canSave then pcall(writefile, path, HttpService:JSONEncode(data)) end
end

local clipboard = (typeof(setclipboard) == "function" and setclipboard)
	or (typeof(toclipboard) == "function" and toclipboard) or nil

-- Shared building blocks ------------------------------------------------------

-- A text field on the right of a row
local function inputRow(page, label, placeholder)
	local r = row(page, label)
	local box = new("TextBox", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, 0), Size = UDim2.new(0.5, -30, 0, Tokens.size.control),
		Text = "", PlaceholderText = placeholder, ClearTextOnFocus = false, FontFace = Tokens.fontRegular,
		TextSize = Tokens.text.small + 1, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
		BorderSizePixel = 0, Parent = r,
	}, { round(Tokens.radius.md), padding(0, 10), new("UISizeConstraint", { MaxSize = Vector2.new(240, Tokens.size.control) }) })
	bind(box, "BackgroundColor3", "raised")
	bind(box, "TextColor3", "text")
	bind(box, "PlaceholderColor3", "muted")
	return box
end

-- A list that is rebuilt from data: each entry is a title, a detail line and buttons
local function listBox(page)
	local card = cardOf(page)
	local box = new("Frame", {
		Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
		LayoutOrder = nextOrder(), Parent = card.frame,
	}, { new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }) })
	card.count += 1
	return box
end

local function clearList(box)
	for _, child in ipairs(box:GetChildren()) do
		if not child:IsA("UIListLayout") then child:Destroy() end
	end
end

local function emptyLine(box, text)
	local holder = new("Frame", { Size = UDim2.new(1, 0, 0, 44), BackgroundTransparency = 1, Parent = box })
	new("TextLabel", {
		Size = UDim2.new(1, -32, 1, 0), Position = UDim2.fromOffset(16, 0), BackgroundTransparency = 1,
		FontFace = Tokens.fontRegular, TextSize = Tokens.text.small + 1,
		TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = P.muted, Text = text, Parent = holder,
	})
end

-- buttons = { { text, onClick, danger?, active? }, ... }; returns the detail label
local function listRow(box, order, titleText, detailText, buttons, userId)
	local r = new("Frame", {
		Size = UDim2.new(1, 0, 0, 58), BackgroundTransparency = 1, LayoutOrder = order, Parent = box,
	})
	if order > 1 then
		new("Frame", { Size = UDim2.new(1, -16, 0, 1), Position = UDim2.fromOffset(16, 0), BackgroundColor3 = P.divider, BorderSizePixel = 0, Parent = r })
	end
	local x = 16
	if userId then
		new("ImageLabel", {
			Size = UDim2.fromOffset(32, 32), Position = UDim2.new(0, 16, 0.5, -16), BackgroundColor3 = P.raised, BorderSizePixel = 0,
			Image = "rbxthumb://type=AvatarHeadShot&id=" .. userId .. "&w=60&h=60", Parent = r,
		}, { round("full") })
		x = 60
	end
	-- the text gets whatever the buttons leave over
	local reserve = x + 14
	for _, b in ipairs(buttons) do reserve += #b[1] * 6.2 + 22 end
	new("TextLabel", {
		Size = UDim2.new(1, -reserve, 0, 18), Position = UDim2.fromOffset(x, 11), BackgroundTransparency = 1,
		FontFace = Tokens.font, TextSize = Tokens.text.body, TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd, TextColor3 = P.text, Text = titleText, Parent = r,
	})
	local detail = new("TextLabel", {
		Size = UDim2.new(1, -reserve, 0, 15), Position = UDim2.fromOffset(x, 31), BackgroundTransparency = 1,
		FontFace = Tokens.mono, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd, TextColor3 = P.muted, Text = detailText or "", Parent = r,
	})
	local holder = new("Frame", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, 0), AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, 28), BackgroundTransparency = 1, Parent = r,
	}, { new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder,
	}) })
	for i, b in ipairs(buttons) do
		local btn = new("TextButton", {
			AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.new(0, 0, 1, 0), Text = b[1], FontFace = Tokens.font,
			TextSize = Tokens.text.small, AutoButtonColor = false, BorderSizePixel = 0, LayoutOrder = i,
			BackgroundColor3 = b[4] and P.accent or P.raised, TextColor3 = b[3] and P.danger or (b[4] and P.onAccent or P.text), Parent = holder,
		}, { round("full"), padding(0, 9) })
		pressable(btn)
		if not b[4] then
			connect(btn.MouseEnter, function() tween(btn, { BackgroundColor3 = P.hover }, 0.12) end)
			connect(btn.MouseLeave, function() tween(btn, { BackgroundColor3 = P.raised }, 0.12) end)
		end
		connect(btn.Activated, b[2])
	end
	return detail
end

-- Freecam and spectate ----------------------------------------------------------
local fc = { pos = Vector3.zero, yaw = 0, pitch = 0, anchored = nil, mouseLocked = false }

local function cameraSubjectHome()
	local camera = workspace.CurrentCamera
	if not camera then return end
	local target = features.spectate
	local _, hum = target and bodyOf(target)
	if not hum then
		local char = LocalPlayer.Character
		hum = char and char:FindFirstChildOfClass("Humanoid")
	end
	if hum then camera.CameraSubject = hum end
end

local function setFreecam(on)
	if on == features.freecam then return end
	local camera = workspace.CurrentCamera
	if not camera then return end
	features.freecam = on
	local root = myRoot()
	if on then
		local cf = camera.CFrame
		fc.pos = cf.Position
		local x, y = cf:ToOrientation()
		fc.pitch, fc.yaw = x, y
		if root then
			fc.anchored = root.Anchored
			root.Anchored = true
		end
		camera.CameraType = Enum.CameraType.Scriptable
		toast("Freecam on. Hold right mouse to look, WASD, E and Q to move, Shift for speed.")
	else
		if root and fc.anchored ~= nil then root.Anchored = fc.anchored end
		fc.anchored = nil
		if fc.mouseLocked then
			UserInputService.MouseBehavior = Enum.MouseBehavior.Default
			fc.mouseLocked = false
		end
		camera.CameraType = Enum.CameraType.Custom
		cameraSubjectHome()
	end
end

function freecamStep(camera, dt)
	if not features.freecam then return end
	if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
		fc.mouseLocked = true
		local d = UserInputService:GetMouseDelta()
		fc.yaw -= d.X * 0.004
		fc.pitch = math.clamp(fc.pitch - d.Y * 0.004, -1.5, 1.5)
	elseif fc.mouseLocked then
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		fc.mouseLocked = false
	end
	local rot = CFrame.fromOrientation(fc.pitch, fc.yaw, 0)
	if not UserInputService:GetFocusedTextBox() then
		local k = function(code) return UserInputService:IsKeyDown(code) and 1 or 0 end
		local move = Vector3.new(
			k(Enum.KeyCode.D) - k(Enum.KeyCode.A),
			k(Enum.KeyCode.E) - k(Enum.KeyCode.Q),
			k(Enum.KeyCode.S) - k(Enum.KeyCode.W)
		)
		if move.Magnitude > 0 then
			local speed = Settings.freecamSpeed * (UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) and 3 or 1)
			fc.pos += rot:VectorToWorldSpace(move.Unit) * speed * dt
		end
	end
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = CFrame.new(fc.pos) * rot
end

local renderPlayers -- set below

local function setSpectate(player)
	features.spectate = player
	if not features.freecam then cameraSubjectHome() end
	if player then toast("Spectating " .. player.DisplayName) end
	if renderPlayers then renderPlayers() end
end

connect(RunService.Heartbeat, function()
	local target = features.spectate
	if not target then return end
	if target.Parent ~= Players then
		setSpectate(nil)
		return
	end
	-- follow respawns
	local camera = workspace.CurrentCamera
	local _, hum = bodyOf(target)
	if camera and hum and camera.CameraSubject ~= hum and not features.freecam then camera.CameraSubject = hum end
end)

connect(UserInputService.InputBegan, function(input)
	if keyCapture or input == consumedInput or UserInputService:GetFocusedTextBox() then return end
	if inputName(input) == Settings.freecamKey then setFreecam(not features.freecam) end
end)

-- Players page ---------------------------------------------------------------------
local playersPage = page("players")

section(playersPage, "Server")
switch(playersPage, "Anti-AFK", "antiAfk")

local function rejoin()
	toast("Rejoining...")
	pcall(function()
		if #Players:GetPlayers() <= 1 then
			TeleportService:Teleport(game.PlaceId, LocalPlayer)
		else
			TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
		end
	end)
end

local hopping = false
local function serverHop()
	if hopping then return end
	hopping = true
	toast("Looking for another server...")
	task.spawn(function()
		local choices, cursor = {}, nil
		for _ = 1, 3 do
			local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Desc&limit=100"
				.. (cursor and ("&cursor=" .. cursor) or "")
			local ok, body = pcall(function() return game:HttpGet(url) end)
			if not ok then break end
			local okJson, data = pcall(function() return HttpService:JSONDecode(body) end)
			if not okJson or type(data) ~= "table" or type(data.data) ~= "table" then break end
			for _, s in ipairs(data.data) do
				if s.id ~= game.JobId and tonumber(s.playing) and tonumber(s.maxPlayers) and s.playing < s.maxPlayers then
					table.insert(choices, s.id)
				end
			end
			cursor = data.nextPageCursor
			if #choices >= 10 or not cursor then break end
		end
		hopping = false
		if #choices == 0 then
			toast("No other server with space was found")
			return
		end
		toast("Joining another server...")
		pcall(function()
			TeleportService:TeleportToPlaceInstance(game.PlaceId, choices[math.random(#choices)], LocalPlayer)
		end)
	end)
end

buttonRow(playersPage, "Server", { { "Rejoin", rejoin }, { "Server hop", serverHop } })
note(playersPage, "Anti-AFK stops the 20 minute idle kick. Server hop joins a random other server of this game that has space.")

connect(LocalPlayer.Idled, function()
	if not Settings.antiAfk then return end
	pcall(function()
		local vu = game:GetService("VirtualUser")
		vu:CaptureController()
		vu:ClickButton2(Vector2.new())
	end)
end)

section(playersPage, "Players")
local playerList = listBox(playersPage)
local detailLabels = {}

local function teamText(p)
	local mark = allyMarks[p]
	if mark == true then return "Teammate" end
	if mark == false then return "Enemy" end
	return isTeammate(p) and "Auto: team" or "Auto: enemy"
end

local function detailOf(p)
	local char, hum = bodyOf(p)
	local parts = {}
	if hum then table.insert(parts, string.format("%d hp", math.floor(hum.Health + 0.5))) end
	local a, b = rootOf(char), myRoot()
	if a and b then table.insert(parts, string.format("%d m", math.floor((a.Position - b.Position).Magnitude + 0.5))) end
	if p.Team then table.insert(parts, p.Team.Name) end
	if p.DisplayName ~= p.Name then table.insert(parts, "@" .. p.Name) end
	return #parts > 0 and table.concat(parts, "  ·  ") or "No character"
end

function renderPlayers()
	clearList(playerList)
	table.clear(detailLabels)
	local list = {}
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer then table.insert(list, p) end
	end
	table.sort(list, function(a, b) return a.DisplayName:lower() < b.DisplayName:lower() end)
	if #list == 0 then
		emptyLine(playerList, "No other players in this server.")
		return
	end
	for i, p in ipairs(list) do
		local spectating = features.spectate == p
		local focused = focus.target == p
		detailLabels[p] = listRow(playerList, i, p.DisplayName, detailOf(p), {
			{ spectating and "Stop" or "Spectate", function() setSpectate(not spectating and p or nil) end, false, spectating },
			{ "Go to", function()
				local a, b = rootOf((bodyOf(p))), myRoot()
				if a and b then
					b.CFrame = a.CFrame * CFrame.new(0, 0, 4)
				else
					toast(p.DisplayName .. " has no character right now")
				end
			end },
			{ teamText(p), function()
				local mark = allyMarks[p]
				if mark == nil then allyMarks[p] = true elseif mark == true then allyMarks[p] = false else allyMarks[p] = nil end
				renderPlayers()
			end },
			{ focused and "Unfocus" or "Focus", function()
				focus.target = (not focused) and p or nil
				if not focused then toast("Aimbot and silent aim prefer " .. p.DisplayName) end
				renderPlayers()
			end, false, focused },
		}, p.UserId)
	end
end
note(playersPage, "Focus makes the aimbot and silent aim pick that player first whenever they are a valid target. The team button cycles automatic, teammate and enemy.")

connect(Players.PlayerAdded, function() renderPlayers() end)
connect(Players.PlayerRemoving, function(p)
	if focus.target == p then focus.target = nil end
	task.defer(renderPlayers)
end)
onTheme(function() renderPlayers() end)

local detailElapsed = 0
connect(RunService.Heartbeat, function(dt)
	detailElapsed += dt
	if detailElapsed < 0.5 then return end
	detailElapsed = 0
	if not (Holder.Visible and pages.players.Visible) then return end
	for p, label in pairs(detailLabels) do
		if label.Parent then label.Text = detailOf(p) end
	end
end)

do -- own scope, so its locals don't count against the main chunk's register limit
-- Configs (Settings page) ------------------------------------------------------------
local CONFIG_FILE = "Vigil-configs.json"
local SKIP = { perGame = true, showLoader = true, menuW = true, menuH = true }
local configs = readJson(CONFIG_FILE) or {}

local function applyValues(values, label)
	local before = table.clone(Settings)
	local count = 0
	for k, v in pairs(values) do
		if Settings[k] ~= nil and not SKIP[k] and typeof(v) == typeof(Settings[k]) then
			Settings[k] = v
			count += 1
		end
	end
	if count == 0 then
		toast("That config has no settings Vigil knows")
		return
	end
	save()
	applyTheme()
	toast(label, "Undo", function()
		for k, v in pairs(before) do Settings[k] = v end
		save()
		applyTheme()
	end)
end

local function snapshot()
	local out = {}
	for k, v in pairs(Settings) do
		if not SKIP[k] then out[k] = v end
	end
	return out
end

section(settingsPage, "Saved configs")
local nameBox = inputRow(settingsPage, "Name", "Legit, Arsenal, ...")
local configList
local function renderConfigs()
	clearList(configList)
	local names = {}
	for name in pairs(configs) do table.insert(names, name) end
	table.sort(names, function(a, b) return a:lower() < b:lower() end)
	if #names == 0 then
		emptyLine(configList, "No saved configs yet.")
		return
	end
	for i, name in ipairs(names) do
		local count = 0
		for _ in pairs(configs[name]) do count += 1 end
		local buttons = { { "Load", function() applyValues(configs[name], "Loaded " .. name) end } }
		if clipboard then
			table.insert(buttons, { "Copy", function()
				pcall(clipboard, HttpService:JSONEncode(configs[name]))
				toast(name .. " copied to the clipboard")
			end })
		end
		table.insert(buttons, { "Delete", function()
			local removed = configs[name]
			configs[name] = nil
			writeJson(CONFIG_FILE, configs)
			renderConfigs()
			toast("Deleted " .. name, "Undo", function()
				configs[name] = removed
				writeJson(CONFIG_FILE, configs)
				renderConfigs()
			end)
		end, true })
		listRow(configList, i, name, string.format("%d settings", count), buttons)
	end
end
buttonRow(settingsPage, "Save current settings", { { "Save", function()
	local name = nameBox.Text:gsub("^%s+", ""):gsub("%s+$", "")
	if name == "" then
		toast("Type a name for the config first")
		return
	end
	name = name:sub(1, 32)
	local existed = configs[name] ~= nil
	configs[name] = snapshot()
	writeJson(CONFIG_FILE, configs)
	nameBox.Text = ""
	renderConfigs()
	toast((existed and "Updated " or "Saved ") .. name)
end } })
configList = listBox(settingsPage)

local importBox = inputRow(settingsPage, "Import", "Paste a config here")
local shareButtons = { { "Import", function()
	local ok, data = pcall(function() return HttpService:JSONDecode(importBox.Text) end)
	if not ok or type(data) ~= "table" then
		toast("That isn't a Vigil config")
		return
	end
	importBox.Text = ""
	applyValues(data, "Imported config applied")
end } }
if clipboard then
	table.insert(shareButtons, 1, { "Copy current", function()
		pcall(clipboard, HttpService:JSONEncode(snapshot()))
		toast("Current settings copied to the clipboard")
	end })
end
buttonRow(settingsPage, "Share", shareButtons)
note(settingsPage, canSave and "Saved configs are kept in Vigil-configs.json. Copy one to share it, and paste a friend's into Import."
	or "This executor can't write files, so saved configs only last until you leave.")
onTheme(function() renderConfigs() end)

end

do
-- Waypoints (Movement page) -------------------------------------------------------------
local WAYPOINT_FILE = "Vigil-waypoints.json"
local PLACE = tostring(game.PlaceId)
local waypointsAll = readJson(WAYPOINT_FILE) or {}
waypointsAll[PLACE] = type(waypointsAll[PLACE]) == "table" and waypointsAll[PLACE] or {}

section(movementPage, "Waypoints")
local wpBox = inputRow(movementPage, "Name", "Spawn, shop, ...")
local wpList
local function renderWaypoints()
	clearList(wpList)
	local list = waypointsAll[PLACE]
	if #list == 0 then
		emptyLine(wpList, "No waypoints in this game yet.")
		return
	end
	for i, wp in ipairs(list) do
		local b = myRoot()
		local dist = b and string.format("%d m away", math.floor((Vector3.new(wp.x, wp.y, wp.z) - b.Position).Magnitude + 0.5)) or ""
		listRow(wpList, i, wp.name, dist, {
			{ "Go", function()
				local root = myRoot()
				if not root then return end
				root.CFrame = CFrame.new(wp.x, wp.y, wp.z) * (root.CFrame - root.CFrame.Position)
				root.AssemblyLinearVelocity = Vector3.zero
				renderWaypoints()
			end },
			{ "Delete", function()
				table.remove(list, i)
				writeJson(WAYPOINT_FILE, waypointsAll)
				renderWaypoints()
			end, true },
		})
	end
end
buttonRow(movementPage, "Save where you stand", { { "Save", function()
	local root = myRoot()
	if not root then
		toast("You need a character to save a waypoint")
		return
	end
	local list = waypointsAll[PLACE]
	local name = wpBox.Text:gsub("^%s+", ""):gsub("%s+$", "")
	if name == "" then name = "Waypoint " .. (#list + 1) end
	local p = root.Position
	table.insert(list, { name = name:sub(1, 32), x = p.X, y = p.Y, z = p.Z })
	writeJson(WAYPOINT_FILE, waypointsAll)
	wpBox.Text = ""
	renderWaypoints()
end } })
wpList = listBox(movementPage)
note(movementPage, "Waypoints are kept per game.")
onTheme(function() renderWaypoints() end)

end

-- Freecam and spin (Movement page) ---------------------------------------------------------
section(movementPage, "Freecam")
keybind(movementPage, "Freecam key", "freecamKey")
slider(movementPage, "Freecam speed", "freecamSpeed", 10, 300, 5, function(v) return string.format("%d studs/s", v) end)
note(movementPage, "Your character stays frozen where it is. Hold right mouse to look around, WASD, E and Q to move, Shift to go faster.")

do
section(movementPage, "Spin")
switch(movementPage, "Spinbot", "spin")
slider(movementPage, "Spin speed", "spinSpeed", 1, 20, 1, function(v) return string.format("%d turns/s", v) end)

local spinning = false
connect(RunService.Heartbeat, function(dt)
	local char = LocalPlayer.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local root = rootOf(char)
	local want = Settings.spin and not features.freecam and hum and root and hum.Health > 0
	if want then
		hum.AutoRotate = false
		root.CFrame *= CFrame.Angles(0, math.rad(Settings.spinSpeed * 360 * dt), 0)
		spinning = true
	elseif spinning then
		spinning = false
		if hum then hum.AutoRotate = true end
	end
end)

features.stopSpin = function()
	if not spinning then return end
	spinning = false
	local char = LocalPlayer.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum then hum.AutoRotate = true end
end
end

do
-- Hitmarker and hit sound (Visuals page) -------------------------------------------------------
section(visualsPage, "Hitmarker")
switch(visualsPage, "Show hitmarker", "hitmarker")
switch(visualsPage, "Hit sound", "hitSound")
note(visualsPage, "Shows an X and plays a click when someone you are shooting at loses health, red for a kill. Kills are counted in the module list.")

local markLines = {}
for i = 1, 4 do
	markLines[i] = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(9, 2), BorderSizePixel = 0,
		BackgroundTransparency = 1, Rotation = (i % 2 == 0) and -45 or 45, ZIndex = 20, Parent = espGui,
	})
end
local hitSound = new("Sound", { SoundId = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.6, Parent = espGui })

local markToken = 0
local function showMark(kill)
	markToken += 1
	local mine = markToken
	local m = UserInputService:GetMouseLocation()
	local colour = kill and Color3.fromRGB(255, 70, 70) or Color3.new(1, 1, 1)
	local gap = kill and 9 or 7
	for i, l in ipairs(markLines) do
		local sx = (i == 1 or i == 4) and 1 or -1
		local sy = (i <= 2) and -1 or 1
		l.Position = UDim2.fromOffset(m.X + sx * gap, m.Y + sy * gap) -- espGui ignores the inset, so mouse coordinates line up
		l.BackgroundColor3 = colour
		l.Rotation = (sx * sy > 0) and 45 or -45
		l.Size = UDim2.fromOffset(kill and 12 or 9, 2)
		l.BackgroundTransparency = 0
		tween(l, { BackgroundTransparency = 1 }, 0.35)
	end
	task.delay(0.4, function()
		if mine ~= markToken then return end
		for _, l in ipairs(markLines) do l.BackgroundTransparency = 1 end
	end)
	if Settings.hitSound then
		hitSound.PlaybackSpeed = kill and 1.4 or 1
		if not pcall(function() SoundService:PlayLocalSound(hitSound) end) then pcall(function() hitSound:Play() end) end
	end
end

local lastHealth = setmetatable({}, { __mode = "k" })
local lastFire = 0
connect(RunService.Heartbeat, function()
	if not Settings.hitmarker then
		table.clear(lastHealth)
		return
	end
	local now = os.clock()
	if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then lastFire = now end
	local camera = workspace.CurrentCamera
	if not camera then return end
	local mouse = UserInputService:GetMouseLocation()
	local firing = now - lastFire < 0.6

	local function check(model, hum)
		if not hum then return end
		local h = hum.Health
		local prev = lastHealth[hum]
		lastHealth[hum] = h
		if not prev or h >= prev - 0.01 or not firing then return end
		-- only count damage to someone near where we are aiming
		local root = rootOf(model)
		if not root then return end
		local screen, onScreen = camera:WorldToViewportPoint(root.Position)
		if not onScreen or (Vector2.new(screen.X, screen.Y) - mouse).Magnitude > 260 then return end
		local kill = prev > 0 and h <= 0
		if kill then features.kills += 1 end
		showMark(kill)
	end

	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer then
			local char, hum = bodyOf(p)
			check(char, hum)
		end
	end
	for i, model in ipairs(npcModels) do
		if i > 150 then break end
		check(model, model:FindFirstChildOfClass("Humanoid"))
	end
end)

end

features.cleanup = function()
	setFreecam(false)
	features.spectate = nil
	cameraSubjectHome()
	if features.stopSpin then features.stopSpin() end
end
end

--------------------------------------------------------------------------------
-- Per-frame driver, bound after the camera updates
--------------------------------------------------------------------------------

RunService:BindToRenderStep(RENDER_STEP, Enum.RenderPriority.Camera.Value + 1, function(dt)
	local camera = workspace.CurrentCamera
	if not camera then return end
	local mouse = UserInputService:GetMouseLocation()
	visualsStep(camera, mouse)
	silentStep(camera, mouse)
	aimStep(camera, mouse, dt)
	triggerStep(camera, mouse)
	freecamStep(camera, dt)
	radarStep(camera)
	espStep() -- last, so boxes use this frame's final camera and never trail behind
end)

--------------------------------------------------------------------------------
-- Active modules (top right)
--------------------------------------------------------------------------------
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
	add(Settings.triggerEnabled, "Triggerbot", Settings.triggerFire)
	add(Settings.radarEnabled, "Radar", string.format("%d", Settings.radarRange))
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
	add(Settings.spin, "Spinbot", string.format("%d", Settings.spinSpeed))
	add(Settings.hitmarker, "Hitmarker", string.format("%d kills", features.kills))
	add(Settings.antiAfk, "Anti-AFK")
	add(features.freecam, "Freecam")
	add(features.spectate ~= nil, "Spectate", features.spectate and features.spectate.DisplayName)
	add(focus.target ~= nil, "Focus", focus.target and focus.target.DisplayName)
	-- longest first, the usual shape for a corner list
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
	local parts = { Settings.theme, tostring(Settings.accentColour) }
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

--------------------------------------------------------------------------------
-- Loading screen: a short card with a progress bar, then the menu opens
--------------------------------------------------------------------------------
local loaderGui, runLoader
do
function runLoader()
	loaderGui = new("ScreenGui", {
		Name = "VigilLoader", ResetOnSpawn = false, IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 9002, Parent = ROOT,
	})
	local backdrop = new("Frame", {
		Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 1, BorderSizePixel = 0, Parent = loaderGui,
	})
	local blur
	pcall(function()
		blur = new("BlurEffect", { Size = 0, Parent = workspace.CurrentCamera })
		loaderGui.Destroying:Connect(function() blur:Destroy() end)
	end)

	local card = new("CanvasGroup", {
		Size = UDim2.fromOffset(380, 172), AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 12), BackgroundColor3 = P.bg, BorderSizePixel = 0,
		GroupTransparency = 1, Parent = loaderGui,
	}, { round(Tokens.radius.lg) })
	new("UIStroke", { Color = P.border, Thickness = Tokens.stroke, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = card })
	local cardScale = new("UIScale", { Scale = 0.95, Parent = card })
	new("Frame", {
		Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = card,
	}, { new("UIGradient", {
		Rotation = 90, Color = ColorSequence.new(P.gradTop, P.gradBottom),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.42, 0.28), NumberSequenceKeypoint.new(1, 1),
		}),
	}) })

	-- each letter sits in its own clipped slot so it can rise into place
	local word = new("Frame", {
		Size = UDim2.new(1, -56, 0, 44), Position = UDim2.fromOffset(28, 22), BackgroundTransparency = 1, Parent = card,
	}, { new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, SortOrder = Enum.SortOrder.LayoutOrder }) })
	local letters = {}
	for i, ch in ipairs({ "V", "i", "g", "i", "l" }) do
		local slot = new("Frame", {
			Size = UDim2.fromOffset(0, 44), AutomaticSize = Enum.AutomaticSize.X, ClipsDescendants = true,
			BackgroundTransparency = 1, LayoutOrder = i, Parent = word,
		})
		letters[i] = new("TextLabel", {
			Text = ch, FontFace = Tokens.fontStrong, TextSize = 34, TextColor3 = P.text,
			AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 44), Position = UDim2.fromOffset(0, 40),
			TextTransparency = 1, BackgroundTransparency = 1, Parent = slot,
		})
	end
	local function label(props)
		props.BackgroundTransparency = 1
		props.TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left
		props.TextColor3 = props.TextColor3 or P.muted
		props.Parent = card
		return new("TextLabel", props)
	end
	local tagline = label({
		Text = "Advanced keyless universal script", FontFace = Tokens.fontRegular, TextSize = Tokens.text.body, TextTransparency = 1,
		Position = UDim2.fromOffset(28, 66), Size = UDim2.new(1, -56, 0, 20),
	})
	local status = label({
		Text = "Loading icons", FontFace = Tokens.font, TextSize = Tokens.text.small + 1,
		Position = UDim2.new(0, 28, 1, -56), Size = UDim2.new(1, -110, 0, 18),
	})
	local percent = label({
		Text = "0%", FontFace = Tokens.mono, TextSize = Tokens.text.small, TextXAlignment = Enum.TextXAlignment.Right,
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -28, 1, -56), Size = UDim2.fromOffset(60, 18),
	})
	local track = new("Frame", {
		Size = UDim2.new(1, -56, 0, 3), Position = UDim2.new(0, 28, 1, -30),
		BackgroundColor3 = P.raised, BorderSizePixel = 0, Parent = card,
	}, { round("full") })
	local fill = new("Frame", {
		Size = UDim2.fromScale(0, 1), BackgroundColor3 = P.accent, BorderSizePixel = 0, Parent = track,
	}, { round("full") })

	-- the bar is real: it follows the menu's images as they download
	local images, seen, total = {}, {}, 0
	for _, d in ipairs(Holder:GetDescendants()) do
		if d:IsA("ImageLabel") and d.Image ~= "" then
			table.insert(images, d)
			if not seen[d.Image] then
				seen[d.Image] = true
				total += 1
			end
		end
	end
	local done, finished = 0, false
	task.spawn(function()
		pcall(function()
			game:GetService("ContentProvider"):PreloadAsync(images, function() done += 1 end)
		end)
		finished = true
	end)

	local alive = function() return loaderGui and loaderGui.Parent ~= nil end
	local fast = reducedMotion

	task.spawn(function()
		tweenStyle(backdrop, { BackgroundTransparency = 0.55 }, 0.4, Enum.EasingStyle.Quad)
		if blur then tweenStyle(blur, { Size = 18 }, 0.5, Enum.EasingStyle.Quad) end
		tweenStyle(card, { GroupTransparency = 0, Position = UDim2.fromScale(0.5, 0.5) }, 0.45)
		tweenStyle(cardScale, { Scale = 1 }, 0.5)
		task.spawn(function()
			for _, l in ipairs(letters) do
				tweenStyle(l, { Position = UDim2.fromOffset(0, 0), TextTransparency = 0 }, 0.5)
				if not fast then task.wait(0.05) end
			end
			tweenStyle(tagline, { TextTransparency = 0 }, 0.4, Enum.EasingStyle.Quad)
		end)

		-- at least long enough to read; never longer than 6 seconds if an image is stuck
		local start, shown = os.clock(), 0
		local minimum = fast and 0 or 1.4
		while alive() do
			local dt = task.wait()
			local elapsed = os.clock() - start
			local target = (finished or elapsed > 6) and 1 or math.min(total > 0 and done / total or 0, 0.96)
			shown += (target - shown) * math.min(1, dt * 8)
			if target == 1 and shown > 0.995 then shown = 1 end
			fill.Size = UDim2.fromScale(shown, 1)
			percent.Text = string.format("%d%%", math.floor(shown * 100 + 0.5))
			if shown == 1 and elapsed >= minimum then break end
		end
		if not alive() then return end
		status.Text, status.TextColor3 = "Ready", P.text
		task.wait(fast and 0 or 0.28)
		if not alive() then return end

		-- the card lifts away while the menu rises in behind it
		tweenStyle(card, { GroupTransparency = 1, Position = UDim2.new(0.5, 0, 0.5, -10) }, 0.26, Enum.EasingStyle.Quad)
		tweenStyle(cardScale, { Scale = 0.97 }, 0.26, Enum.EasingStyle.Quad)
		tweenStyle(backdrop, { BackgroundTransparency = 1 }, 0.42, Enum.EasingStyle.Quad)
		if blur then tweenStyle(blur, { Size = 0 }, 0.42, Enum.EasingStyle.Quad) end
		task.wait(fast and 0 or 0.12)
		if not alive() then return end
		setMenuVisible(true)
		task.wait(fast and 0 or 0.5)
		if loaderGui then loaderGui:Destroy() end
		loaderGui = nil
	end)
end
end

--------------------------------------------------------------------------------
-- Lifecycle
--------------------------------------------------------------------------------

unload = function()
	pcall(function() RunService:UnbindFromRenderStep(RENDER_STEP) end)
	hookState.alive = false
	silent.active = false
	pcall(releaseTrigger)
	pcall(features.cleanup)
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
	if loaderGui then pcall(function() loaderGui:Destroy() end) end
	highlightFolder:Destroy()
	if ENV.Vigil and ENV.Vigil.Unload == unload then ENV.Vigil = nil end
end

ENV.Vigil = { Unload = unload, Settings = Settings }

selectTab("aim")
applyTheme()
if Settings.showLoader then
	Holder.Visible = false
	runLoader()
end
