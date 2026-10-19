local KEY_SYSTEM  = false
local KEY_REMEMBER = false
local MASTER_KEY  = "chenchen1116"
local VALID_KEYS  = {
	["chenchen1116"] = true,
}
print("[HON SPEED HUB] 载入中 · v5.4 · 若只看到这一行说明文件在中途中断")
local twait  = (type(task) == "table" and task.wait)  or wait  or function() end
local tspawn = (type(task) == "table" and task.spawn) or spawn or function(f, ...) return f(...) end
if type(twait) ~= "function" then twait = function() end end
if type(tspawn) ~= "function" then tspawn = function(f, ...) return f(...) end end
local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local Workspace        = game:GetService("Workspace")
local VirtualUser      = game:GetService("VirtualUser")
local VirtualInput     = game:GetService("VirtualInputManager")
local Lighting         = game:GetService("Lighting")
local StarterGui       = game:GetService("StarterGui")
local TeleportService  = game:GetService("TeleportService")
local sWait = (type(task) == "table" and task.wait) or wait or function() end
local LP, Cam, PG = Players.LocalPlayer, Workspace.CurrentCamera, nil
local readyStart = tick()
while (not LP or not Cam) and (tick() - readyStart) < 20 do
	if not LP  then LP  = Players.LocalPlayer end
	if not Cam then Cam = Workspace.CurrentCamera end
	if LP and Cam then break end
	sWait(0.2)
end
if LP then
	PG = LP:FindFirstChild("PlayerGui")
	if not PG then
		pcall(function() PG = LP:WaitForChild("PlayerGui", 8) end)
	end
end
if not Cam then
	pcall(function() Cam = Workspace:FindFirstChildOfClass("Camera") or Workspace.CurrentCamera end)
end
if not PG then
	warn("[HON SPEED HUB] 获取 PlayerGui 失败：请等游戏完全加载进服务器后再注入一次")
	return
end
if not Cam then
	warn("[HON SPEED HUB] 获取 Camera 失败：请重新注入")
	return
end
for _, g in ipairs(PG:GetChildren()) do
	if g:IsA("ScreenGui") and g.Name == "HonSpeedHub" then g:Destroy() end
end
local DEFAULT_WALK = 16
local DEFAULT_JUMP = 50
local BASE_FOV     = 70
local TWEEN_FAST = TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local TWEEN_SOFT = TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local Modes = {
	{
		Id = "W",  Name = "W 引擎",  Tag = "WALKSPEED",
		Desc = "WalkSpeed · 稳定兼容 · 不穿模",
		Accent = Color3.fromRGB(72, 170, 255),
		Speed = 50,  Smooth = 7, Min = 0, Max = 200, FovBoost = 8,
	},
	{
		Id = "V",  Name = "V 引擎",  Tag = "VELOCITY",
		Desc = "Assembly 速度 · 惯性滑行 · 冲得快",
		Accent = Color3.fromRGB(255, 96, 118),
		Speed = 95, Smooth = 9, Min = 0, Max = 300, FovBoost = 16,
	},
	{
		Id = "CF", Name = "CF 引擎", Tag = "CFRAME",
		Desc = "CFrame 位移 · 普通滑行 / 瞬移闪现",
		Accent = Color3.fromRGB(126, 255, 178),
		Speed = 130, Smooth = 12, Min = 0, Max = 400, FovBoost = 28,
	},
}
local TOUCH_KEYS = {
	Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three,
	Enum.KeyCode.Four, Enum.KeyCode.Five,
}
local State = {
	Enabled = true, ModeIndex = 1,
	Speed = Modes[1].Speed, Smooth = Modes[1].Smooth,
	Inertia = true,
	WallSlide = true,
	CFTeleport = false,
	SpeedLocked = false,
	PanelLocked = false,
	JumpPower = DEFAULT_JUMP, JumpEnabled = false, JumpLocked = false,
	InfJump = false, Noclip = false, AntiAFK = false, HUD = false,
	Fly = false, FlySpeed = 60,
	TouchKeys = false, TouchLocked = false,
	PadKeys = false, PadSize = 100,
	EspPlayer = false, EspNPC = false, EspInteract = false,
	InstantInteract = false, EspDepth = true,
	ClickTP = false, AntiVoid = false, FakeChar = false, BodyTransp = 0, Fullbright = false,
	Spin = false, Rainbow = false, Bounce = false, Orbit = false, LowFx = false,
	Dance = false, Halo = false, Follow = false, Face = false, FovValue = 0,
	Freeze = false, HidePlayers = false, HideUI = false, AutoJump = false, CoordHud = false,
	TPLoop = false, TPInterval = 0, TPOffsetY = 3,
	MoveGameUI = false, UILayoutLocked = false,
	Stealth = false, StealthHideGame = true,
	AntiKB = false, AntiStun = false, Freecam = false,
	SafePos = nil,
}
local function Mode() return Modes[State.ModeIndex] end
local cur = 0
local fps, fpsAcc, fpsFrames = 0, 0, 0
local Authed = (not KEY_SYSTEM)
if KEY_SYSTEM and KEY_REMEMBER then
	local remembered = false
	pcall(function()
		remembered = (TeleportService:GetTeleportSetting("HON_KEY_OK") == true)
	end)
	if remembered then Authed = true end
end
local rainbowTimer, wasAirborne, FxBackup = 0, false, nil
local HaloPart = nil
local hideTimer = 0
local tpTimer = 0
local HiddenParts = {}
local CFAccum = 0
local Character, Humanoid, HRP, Highlight, Emitter
local HudFrame, HudText, HudSub
local PadFrame, PadScale
local refsValid
local function new(class, props, kids)
	local o = Instance.new(class)
	for k, v in pairs(props or {}) do
		if k ~= "Parent" then o[k] = v end
	end
	for _, c in ipairs(kids or {}) do c.Parent = o end
	if props and props.Parent then o.Parent = props.Parent end
	return o
end
local function corner(p, r)
	return new("UICorner", { CornerRadius = UDim.new(0, r), Parent = p })
end
local function label(props, parent)
	props.BackgroundTransparency = 1
	props.BorderSizePixel = 0
	props.Parent = parent
	return new("TextLabel", props)
end
local function lockIcon(parent, pos, color)
	local holder = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(0, 16, 0, 16), Position = pos, Parent = parent })
	local shackle = new("Frame", { Size = UDim2.new(0, 8, 0, 5), Position = UDim2.new(0, 4, 0, 1),
		BackgroundColor3 = color, BorderSizePixel = 0, Parent = holder })
	corner(shackle, 3)
	local body = new("Frame", { Size = UDim2.new(0, 12, 0, 8), Position = UDim2.new(0, 2, 0, 5),
		BackgroundColor3 = color, BorderSizePixel = 0, Parent = holder })
	corner(body, 2)
	return { Holder = holder, Shackle = shackle, Body = body }
end
local AllToggles, AllSliders = {}, {}
local function themed(o) table.insert(AllToggles, o) end
local Gui = new("ScreenGui", {
	Name = "HonSpeedHub", ResetOnSpawn = false, IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Global, DisplayOrder = 999, Parent = PG,
})
local PANEL_W, PANEL_H = 660, 470
new("UIScale", { Scale = math.min(1, (Cam.ViewportSize.Y - 30) / PANEL_H, (Cam.ViewportSize.X - 20) / PANEL_W), Parent = Gui })
local Main = new("Frame", {
	Name = "Main", Size = UDim2.new(0, PANEL_W, 0, PANEL_H),
	Position = UDim2.new(0.5, -PANEL_W / 2, 0.5, -PANEL_H / 2),
	BackgroundColor3 = Color3.fromRGB(13, 15, 23), BackgroundTransparency = 0.05,
	BorderSizePixel = 0, ClipsDescendants = true, Active = true, Parent = Gui,
})
corner(Main, 18)
local MainStroke = new("UIStroke", { Color = Color3.fromRGB(255, 255, 255), Transparency = 0.92, Thickness = 1, Parent = Main })
local Glow = new("Frame", { Size = UDim2.new(1, 0, 0, 150), BackgroundColor3 = Modes[1].Accent,
	BackgroundTransparency = 0.78, BorderSizePixel = 0, Parent = Main })
new("UIGradient", {
	Rotation = 90,
	Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.05),
		NumberSequenceKeypoint.new(0.55, 0.55),
		NumberSequenceKeypoint.new(1, 1),
	}), Parent = Glow,
})
local Header = new("Frame", { Size = UDim2.new(1, 0, 0, 74), BackgroundTransparency = 1, Parent = Main })
local Dot = new("Frame", { Size = UDim2.new(0, 8, 0, 8), Position = UDim2.new(0, 20, 0, 24),
	BackgroundColor3 = Modes[1].Accent, BorderSizePixel = 0, Parent = Header })
corner(Dot, 4)
label({ Text = "HON SPEED HUB", Font = Enum.Font.GothamBold, TextSize = 21,
	TextColor3 = Color3.fromRGB(238, 243, 255),
	Position = UDim2.new(0, 36, 0, 16), Size = UDim2.new(0, 200, 0, 24),
	TextXAlignment = Enum.TextXAlignment.Left }, Header)
label({ Text = "Universal Hub  ·  W / V / CF  ·  v5.4", Font = Enum.Font.Gotham, TextSize = 11,
	TextColor3 = Color3.fromRGB(140, 149, 172),
	Position = UDim2.new(0, 36, 0, 42), Size = UDim2.new(0, 240, 0, 16),
	TextXAlignment = Enum.TextXAlignment.Left }, Header)
local Mini = new("TextButton", {
	Text = "HON", Font = Enum.Font.GothamBold, TextSize = 14,
	TextColor3 = Color3.fromRGB(230, 236, 250),
	BackgroundColor3 = Color3.fromRGB(16, 18, 27), BackgroundTransparency = 0.08,
	BorderSizePixel = 0, AutoButtonColor = false,
	Size = UDim2.new(0, 74, 0, 40), Position = UDim2.new(0.5, -37, 0.06, 0), Visible = false, Parent = Gui,
})
corner(Mini, 20)
local MiniStroke = new("UIStroke", { Color = Modes[1].Accent, Transparency = 0.55, Thickness = 1, Parent = Mini })
local function iconBtn(txt, xOff, color, onClick)
	local b = new("TextButton", { Text = txt, Font = Enum.Font.GothamBold, TextSize = 15, TextColor3 = color,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.94,
		BorderSizePixel = 0, AutoButtonColor = false,
		Position = UDim2.new(1, xOff, 0, 20), Size = UDim2.new(0, 28, 0, 28), Parent = Header })
	corner(b, 8)
	b.MouseButton1Click:Connect(onClick)
	return b
end
local LockBtn = new("TextButton", { Text = "", AutoButtonColor = false, BackgroundTransparency = 0.94,
	BackgroundColor3 = Color3.fromRGB(255, 255, 255), BorderSizePixel = 0,
	Position = UDim2.new(1, -102, 0, 20), Size = UDim2.new(0, 28, 0, 28), Parent = Header })
corner(LockBtn, 8)
local LockIcon = lockIcon(LockBtn, UDim2.new(0.5, -8, 0.5, -8), Color3.fromRGB(150, 158, 180))
iconBtn("–", -68, Color3.fromRGB(190, 198, 220), function() Main.Visible, Mini.Visible = false, true end)
iconBtn("×", -34, Color3.fromRGB(255, 108, 118), function() Main.Visible, Mini.Visible = false, false end)
Mini.MouseButton1Click:Connect(function() Mini.Visible, Main.Visible = false, true end)
local TabBar = new("Frame", { Name = "Sidebar", Size = UDim2.new(0, 168, 1, -74), Position = UDim2.new(0, 0, 0, 74),
	BackgroundTransparency = 1, BorderSizePixel = 0, Parent = Main })
local SideLine = new("Frame", { Size = UDim2.new(0, 1, 1, 0), Position = UDim2.new(1, -1, 0, 0),
	BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.93, BorderSizePixel = 0, Parent = TabBar })
local TabBtns = {}
local CurTab = 1
do
	local names = { "引擎", "辅助", "视觉", "触屏", "工具", "娱乐", "更多", "实用" }
	for i, n in ipairs(names) do
		local b = new("TextButton", { Text = n, Font = Enum.Font.GothamBold, TextSize = 13,
			TextColor3 = Color3.fromRGB(140, 149, 172), BackgroundTransparency = 1,
			BorderSizePixel = 0, AutoButtonColor = false,
			Size = UDim2.new(1, -24, 0, 34), Position = UDim2.new(0, 12, 0, 12 + (i - 1) * 38), Parent = TabBar })
		local ul = new("Frame", { Size = UDim2.new(0, 3, 0, 20), Position = UDim2.new(0, 0, 0.5, -10),
			BackgroundColor3 = Modes[1].Accent, BackgroundTransparency = 1, BorderSizePixel = 0, Parent = b })
		corner(ul, 1)
		TabBtns[i] = { Btn = b, Underline = ul }
		b.MouseEnter:Connect(function()
			TweenService:Create(b, TWEEN_FAST, { BackgroundTransparency = 0.88 }):Play()
		end)
		b.MouseLeave:Connect(function()
			if i ~= CurTab then
				TweenService:Create(b, TWEEN_FAST, { BackgroundTransparency = 0.94 }):Play()
			end
		end)
		b.MouseButton1Click:Connect(function() SetTab(i) end)
	end
end
local Pages = new("ScrollingFrame", { Name = "Content", Size = UDim2.new(0, 464, 0, 336), Position = UDim2.new(0, 180, 0, 84),
	BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4,
	ScrollBarImageTransparency = 0.6, ScrollBarImageColor3 = Modes[1].Accent,
	CanvasSize = UDim2.new(0, 0, 0, 520), AutomaticCanvasSize = Enum.AutomaticSize.None, Parent = Main })
local PAGE_H = { 520, 380, 400, 680, 910, 410, 530, 720 }
local PageEng = new("Frame", { Size = UDim2.new(1, 0, 0, PAGE_H[1]), BackgroundTransparency = 1, Parent = Pages })
local PageAssist = new("Frame", { Size = UDim2.new(1, 0, 0, PAGE_H[2]), BackgroundTransparency = 1, Parent = Pages })
local PageEsp = new("Frame", { Size = UDim2.new(1, 0, 0, PAGE_H[3]), BackgroundTransparency = 1, Parent = Pages })
local PageTouch = new("Frame", { Size = UDim2.new(1, 0, 0, PAGE_H[4]), BackgroundTransparency = 1, Parent = Pages })
local PageTool = new("Frame", { Size = UDim2.new(1, 0, 0, PAGE_H[5]), BackgroundTransparency = 1, Parent = Pages })
local PageFun = new("Frame", { Size = UDim2.new(1, 0, 0, PAGE_H[6]), BackgroundTransparency = 1, Parent = Pages })
local PageMore = new("Frame", { Size = UDim2.new(1, 0, 0, PAGE_H[7]), BackgroundTransparency = 1, Parent = Pages })
local PageUtil = new("Frame", { Size = UDim2.new(1, 0, 0, PAGE_H[8]), BackgroundTransparency = 1, Parent = Pages })
local function makeSlider(parent, title, y, min, max, default, suffix, onChange, lockable, onLockChange, editable)
	local wrap = new("Frame", { Size = UDim2.new(1, 0, 0, 46), Position = UDim2.new(0, 0, 0, y), BackgroundTransparency = 1, Parent = parent })
	label({ Text = title, Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = Color3.fromRGB(196, 204, 224),
		Size = UDim2.new(0, 140, 0, 16), Position = UDim2.new(0, 2, 0, 0), TextXAlignment = Enum.TextXAlignment.Left }, wrap)
	local val
	if editable then
		val = new("TextBox", {
			Text = tostring(default) .. suffix, Font = Enum.Font.GothamBold, TextSize = 12,
			TextColor3 = Modes[1].Accent, Size = UDim2.new(0, 110, 0, 20),
			Position = UDim2.new(1, (lockable and -158 or -112), 0, -2),
			TextXAlignment = Enum.TextXAlignment.Right,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.92,
			BorderSizePixel = 0, ClearTextOnFocus = false, TextEditable = true, Parent = wrap,
		})
		corner(val, 6)
	else
		val = label({ Text = tostring(default) .. suffix, Font = Enum.Font.GothamBold, TextSize = 12,
			TextColor3 = Modes[1].Accent, Size = UDim2.new(0, 110, 0, 16),
			Position = UDim2.new(1, (lockable and -158 or -112), 0, 0), TextXAlignment = Enum.TextXAlignment.Right }, wrap)
	end
	local track = new("TextButton", { Text = "", AutoButtonColor = false,
		Size = UDim2.new(1, (lockable and -40 or 0), 0, 14), Position = UDim2.new(0, 0, 0, 22),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.92,
		BorderSizePixel = 0, Parent = wrap })
	corner(track, 7)
	local fill = new("Frame", { Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = Modes[1].Accent, BorderSizePixel = 0, Parent = track })
	corner(fill, 7)
	local knob = new("Frame", { Size = UDim2.new(0, 18, 0, 18), Position = UDim2.new(0, -9, 0.5, -9),
		BackgroundColor3 = Color3.fromRGB(240, 245, 255), BorderSizePixel = 0, Parent = track })
	corner(knob, 9)
	local dragging, value, lo, hi, locked = false, default, min, max, false
	local lockBtn, li
	local function paint(v)
		local r = (v - lo) / math.max(hi - lo, 1)
		TweenService:Create(fill, TWEEN_FAST, { Size = UDim2.new(r, 0, 1, 0) }):Play()
		TweenService:Create(knob, TWEEN_FAST, { Position = UDim2.new(r, -9, 0.5, -9) }):Play()
	end
	local function apply(v, silent)
		v = math.clamp(math.floor(v + 0.5), lo, hi)
		value = v; paint(v); val.Text = tostring(v) .. suffix
		if not silent then onChange(v) end
	end
	local function fromX(x)
		if locked then return end
		local r = math.clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
		apply(lo + (hi - lo) * r)
	end
	if editable then
		val.Focused:Connect(function() val.Text = tostring(value) end)
		val.FocusLost:Connect(function()
			local n = tonumber(val.Text:gsub("%D+", ""))
			if n then apply(n) else apply(value, true) end
		end)
	end
	track.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true; fromX(input.Position.X)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			fromX(input.Position.X)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
	end)
	local api = {
		Fill = fill, Value = val, Track = track, Row = wrap, TitleText = title,
		Set = function(v) apply(v, true) end,
		SetRange = function(a, b) local nv = math.clamp(value, a, b); lo, hi = a, b; apply(nv, true) end,
		GetValue = function() return value end,
		IsLocked = function() return locked end,
		Refresh = function()
			TweenService:Create(fill, TWEEN_SOFT, { BackgroundColor3 = Mode().Accent }):Play()
			if not locked then TweenService:Create(val, TWEEN_SOFT, { TextColor3 = Mode().Accent }):Play() end
		end,
	}
	table.insert(AllSliders, api)
	if lockable then
		lockBtn = new("TextButton", { Text = "", AutoButtonColor = false, BackgroundTransparency = 0.9,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255), BorderSizePixel = 0,
			Size = UDim2.new(0, 28, 0, 28), Position = UDim2.new(1, -30, 0, 4), Parent = wrap })
		corner(lockBtn, 8)
		li = lockIcon(lockBtn, UDim2.new(0.5, -8, 0.5, -8), Color3.fromRGB(150, 158, 180))
		api.SetLocked = function(v)
			locked = v
			local c = v and Mode().Accent or Color3.fromRGB(150, 158, 180)
			TweenService:Create(li.Shackle, TWEEN_FAST, { BackgroundColor3 = c }):Play()
			TweenService:Create(li.Body, TWEEN_FAST, { BackgroundColor3 = c }):Play()
			TweenService:Create(track, TWEEN_SOFT, { BackgroundTransparency = v and 0.97 or 0.92 }):Play()
			TweenService:Create(fill, TWEEN_SOFT, { BackgroundTransparency = v and 0.35 or 0 }):Play()
			TweenService:Create(knob, TWEEN_SOFT, { BackgroundTransparency = v and 0.55 or 0 }):Play()
			TweenService:Create(val, TWEEN_SOFT, { TextColor3 = v and Color3.fromRGB(120, 128, 148) or Mode().Accent }):Play()
		end
		lockBtn.MouseButton1Click:Connect(function()
			api.SetLocked(not locked)
			if onLockChange then onLockChange(locked) end
		end)
	end
	apply(default, true)
	return api
end
local function makeToggle(parent, y, title, sub, initial, onChange)
	local row = new("Frame", { Size = UDim2.new(1, 0, 0, 40), Position = UDim2.new(0, 0, 0, y),
		BackgroundColor3 = Color3.fromRGB(24, 27, 38), BackgroundTransparency = 0.35,
		BorderSizePixel = 0, Parent = parent })
	corner(row, 12)
	local stroke = new("UIStroke", { Color = Modes[1].Accent, Transparency = 0.85, Thickness = 1, Parent = row })
	local t1 = label({ Text = title, Font = Enum.Font.GothamBold, TextSize = 12,
		TextColor3 = Color3.fromRGB(224, 231, 246), Position = UDim2.new(0, 14, 0, 5),
		Size = UDim2.new(0, 180, 0, 16), TextXAlignment = Enum.TextXAlignment.Left }, row)
	local t2 = label({ Text = sub, Font = Enum.Font.Gotham, TextSize = 10,
		TextColor3 = Color3.fromRGB(132, 141, 163), Position = UDim2.new(0, 14, 0, 22),
		Size = UDim2.new(0, 180, 0, 14), TextXAlignment = Enum.TextXAlignment.Left }, row)
	local sw = new("TextButton", { Text = "", AutoButtonColor = false,
		Size = UDim2.new(0, 46, 0, 24), Position = UDim2.new(1, -60, 0.5, -12),
		BackgroundColor3 = initial and Modes[1].Accent or Color3.fromRGB(70, 74, 90), BorderSizePixel = 0, Parent = row })
	corner(sw, 12)
	local kb = new("Frame", { Size = UDim2.new(0, 18, 0, 18),
		Position = initial and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9),
		BackgroundColor3 = Color3.fromRGB(250, 252, 255), BorderSizePixel = 0, Parent = sw })
	corner(kb, 9)
	local on = initial
	local function paint(v)
		TweenService:Create(sw, TWEEN_FAST, { BackgroundColor3 = v and Mode().Accent or Color3.fromRGB(70, 74, 90) }):Play()
		TweenService:Create(kb, TWEEN_FAST, { Position = v and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9) }):Play()
	end
	sw.MouseButton1Click:Connect(function() on = not on; paint(on); onChange(on) end)
	local api = {
		Row = row, Stroke = stroke, Title = t1, Sub = t2, Switch = sw,
		Set = function(v, silent) on = v; paint(on); if not silent then onChange(on) end end,
		Refresh = function() if on then paint(true) end end,
		Dim = function(dim)
			TweenService:Create(row, TWEEN_SOFT, { BackgroundTransparency = dim and 0.75 or 0.35 }):Play()
			TweenService:Create(t1, TWEEN_SOFT, { TextColor3 = dim and Color3.fromRGB(120, 128, 148) or Color3.fromRGB(224, 231, 246) }):Play()
			TweenService:Create(t2, TWEEN_SOFT, { TextColor3 = dim and Color3.fromRGB(92, 99, 118) or Color3.fromRGB(132, 141, 163) }):Play()
			TweenService:Create(stroke, TWEEN_SOFT, { Transparency = dim and 0.95 or 0.85 }):Play()
		end,
	}
	themed(api)
	return api
end
local SearchBox = new("TextBox", { PlaceholderText = "搜索功能…", Text = "", Font = Enum.Font.Gotham, TextSize = 11,
	TextColor3 = Color3.fromRGB(226, 233, 248), PlaceholderColor3 = Color3.fromRGB(105, 113, 134),
	BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.92, BorderSizePixel = 0,
	ClearTextOnFocus = false, Position = UDim2.new(0, 12, 0, 320), Size = UDim2.new(1, -24, 0, 30), Parent = TabBar })
corner(SearchBox, 8)
label({ Text = "驱 动 引 擎", Font = Enum.Font.GothamBold, TextSize = 11,
	TextColor3 = Color3.fromRGB(120, 129, 152), Size = UDim2.new(1, 0, 0, 18),
	Position = UDim2.new(0, 2, 0, 0), TextXAlignment = Enum.TextXAlignment.Left }, PageEng)
local Cards = {}
local CardHolder = new("Frame", { Size = UDim2.new(1, 0, 0, 174), Position = UDim2.new(0, 0, 0, 24),
	BackgroundTransparency = 1, Parent = PageEng })
for i, m in ipairs(Modes) do
	local card = new("TextButton", { Name = m.Id, Text = "", AutoButtonColor = false,
		Size = UDim2.new(1, 0, 0, 54), Position = UDim2.new(0, 0, 0, (i - 1) * 60),
		BackgroundColor3 = Color3.fromRGB(26, 29, 41), BackgroundTransparency = 0.3,
		BorderSizePixel = 0, Parent = CardHolder })
	corner(card, 12)
	local stroke = new("UIStroke", { Color = m.Accent, Transparency = 0.78, Thickness = 1, Parent = card })
	local bar = new("Frame", { Size = UDim2.new(0, 3, 0, 30), Position = UDim2.new(0, 11, 0.5, -15),
		BackgroundColor3 = m.Accent, BackgroundTransparency = 0.4, BorderSizePixel = 0, Parent = card })
	corner(bar, 2)
	label({ Text = m.Name, Font = Enum.Font.GothamBold, TextSize = 15, TextColor3 = Color3.fromRGB(234, 240, 255),
		Position = UDim2.new(0, 26, 0, 8), Size = UDim2.new(0, 150, 0, 18), TextXAlignment = Enum.TextXAlignment.Left }, card)
	label({ Text = m.Desc, Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = Color3.fromRGB(146, 155, 178),
		Position = UDim2.new(0, 26, 0, 30), Size = UDim2.new(1, -120, 0, 14), TextXAlignment = Enum.TextXAlignment.Left }, card)
	label({ Text = m.Tag, Font = Enum.Font.GothamBold, TextSize = 9, TextColor3 = m.Accent,
		Position = UDim2.new(1, -86, 0.5, -8), Size = UDim2.new(0, 74, 0, 16), TextXAlignment = Enum.TextXAlignment.Right }, card)
	Cards[i] = { Card = card, Stroke = stroke, Bar = bar }
	card.MouseButton1Click:Connect(function() SetMode(i) end)
end
local SpeedSlider  = makeSlider(PageEng, "速度 SPEED", 206, Modes[1].Min, Modes[1].Max, State.Speed, " sp",
	function(v) State.Speed = v end, true, function(v) State.SpeedLocked = v end, true)
local SmoothSlider = makeSlider(PageEng, "顺滑 SMOOTH", 258, 1, 20, State.Smooth, "",
	function(v) State.Smooth = v end, false)
local PowerToggle   = makeToggle(PageEng, 312, "启用引擎", "F2 快捷键", true, function(v) State.Enabled = v end)
local InertiaToggle = makeToggle(PageEng, 360, "惯性滑行", "仅 V 引擎生效", true, function(v) State.Inertia = v end)
local SlideToggle   = makeToggle(PageEng, 408, "防穿墙 / 沿墙滑动", "仅 CF 引擎生效", true, function(v) State.WallSlide = v end)
local TeleportToggle = makeToggle(PageEng, 456, "瞬移闪现 TP", "仅 CF · 蓄力后整段位移", false, function(v)
	State.CFTeleport = v
	CFAccum = 0
end)
label({ Text = "辅 助 功 能", Font = Enum.Font.GothamBold, TextSize = 11,
	TextColor3 = Color3.fromRGB(120, 129, 152), Size = UDim2.new(1, 0, 0, 18),
	Position = UDim2.new(0, 2, 0, 0), TextXAlignment = Enum.TextXAlignment.Left }, PageAssist)
local JumpSlider = makeSlider(PageAssist, "跳跃力 JUMP", 24, 16, 200, DEFAULT_JUMP, " jp",
	function(v) State.JumpPower = v end, true, function(v) State.JumpLocked = v end)
local JumpToggle = makeToggle(PageAssist, 78, "启用跳跃增强", "逐帧回写防被重置", false, function(v) State.JumpEnabled = v end)
local InfJumpTgl = makeToggle(PageAssist, 126, "无限跳", "空中可反复起跳", false, function(v) State.InfJump = v end)
local NoclipTgl  = makeToggle(PageAssist, 174, "穿墙 NOCLIP", "关闭时还原碰撞体", false, function(v)
	State.Noclip = v
	setNoclip(v)
end)
local AntiAFKTgl = makeToggle(PageAssist, 222, "反挂机 ANTI-AFK", "防止长时间无操作掉线", false, function(v) State.AntiAFK = v end)
local HudTgl     = makeToggle(PageAssist, 270, "速度 HUD", "屏幕底部实时显示速度", false, function(v)
	State.HUD = v; HudFrame.Visible = v
end)
local FlyTgl     = makeToggle(PageAssist, 318, "飞行窗口 FLY", "打开小窗 + 右上角上下键", false, function(v)
	setFlyWindow(v)
end)
label({ Text = "视 觉 增 强", Font = Enum.Font.GothamBold, TextSize = 11,
	TextColor3 = Color3.fromRGB(120, 129, 152), Size = UDim2.new(1, 0, 0, 18),
	Position = UDim2.new(0, 2, 0, 0), TextXAlignment = Enum.TextXAlignment.Left }, PageEsp)
local EspPlayerTgl = makeToggle(PageEsp, 24,  "玩家透视", "高亮 + 名称 / 距离 / 血量", false, function(v)
	State.EspPlayer = v; if not v then clearEsp("Player") end
end)
local EspNpcTgl    = makeToggle(PageEsp, 72,  "NPC 透视", "高亮所有非玩家人形", false, function(v)
	State.EspNPC = v; if not v then clearEsp("NPC") end
end)
local EspItTgl     = makeToggle(PageEsp, 120, "交互物透视", "ProximityPrompt / ClickDetector", false, function(v)
	State.EspInteract = v; if not v then clearEsp("Interact") end
end)
local InstantTgl   = makeToggle(PageEsp, 168, "秒交互", "HoldDuration=0 · 距离 30", false, function(v)
	State.InstantInteract = v; applyInstantInteract(v)
end)
local EspDepthTgl  = makeToggle(PageEsp, 216, "穿墙显示", "ESP 无视遮挡", true, function(v)
	State.EspDepth = v; refreshEspDepth()
end)
local TranspSlider = makeSlider(PageEsp, "身体透明度", 300, 0, 100, 0, " %", function(v)
	State.BodyTransp = v / 100
end, false)
label({ Text = "改的是本体（有网络所有权，会同步），关闭分身隐身后别人能看见半透明的你",
	Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = Color3.fromRGB(120, 129, 152),
	Position = UDim2.new(0, 2, 0, 352), Size = UDim2.new(1, -4, 0, 26),
	TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top }, PageEsp)
label({ Text = "触 屏 控 制", Font = Enum.Font.GothamBold, TextSize = 11,
	TextColor3 = Color3.fromRGB(120, 129, 152), Size = UDim2.new(1, 0, 0, 18),
	Position = UDim2.new(0, 2, 0, 0), TextXAlignment = Enum.TextXAlignment.Left }, PageTouch)
local TouchTgl = makeToggle(PageTouch, 24, "触屏数字键", "屏幕生成 1~5 键 · 可拖动", false, function(v)
	State.TouchKeys = v
	updateTouchVisibility()
end)
local PadTgl = makeToggle(PageTouch, 72, "虚拟方向键", "8 向 WASD · 长按中心拖动整块", false, function(v)
	State.PadKeys = v
	updateTouchVisibility()
end)
local PadSizeSlider = makeSlider(PageTouch, "方向键大小", 120, 50, 200, 100, " %", function(v)
	State.PadSize = v
	if PadScale then PadScale.Scale = v / 100 end
end, false)
local TouchLockTgl = makeToggle(PageTouch, 174, "锁定位置", "数字键 + 方向键一起锁死", false, function(v)
	State.TouchLocked = v
	updateTouchLock()
end)
label({ Text = "方向键中心格长按 0.3 秒后可整块拖动；大小滑条实时缩放",
	Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = Color3.fromRGB(132, 141, 163),
	Position = UDim2.new(0, 2, 0, 224), Size = UDim2.new(1, -4, 0, 28),
	TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top }, PageTouch)
local UiBtns = {}
label({ Text = "移 动 游 戏 UI", Font = Enum.Font.GothamBold, TextSize = 11,
	TextColor3 = Color3.fromRGB(120, 129, 152), Size = UDim2.new(1, 0, 0, 18),
	Position = UDim2.new(0, 2, 0, 262), TextXAlignment = Enum.TextXAlignment.Left }, PageTouch)
local MoveUiTgl = makeToggle(PageTouch, 284, "移动游戏 UI", "选目标后整块拖到想要的位置", false, function(v)
	State.MoveGameUI = v
	setUIEdit(v)
end)
local UiPickBtn = new("TextButton", { Text = "选择要移动的 UI  ▾", Font = Enum.Font.GothamBold, TextSize = 11,
	TextColor3 = Mode().Accent, BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.9,
	BorderSizePixel = 0, AutoButtonColor = false,
	Size = UDim2.new(1, 0, 0, 36), Position = UDim2.new(0, 0, 0, 330), Parent = PageTouch })
corner(UiPickBtn, 10)
table.insert(UiBtns, UiPickBtn)
local UiListWrap = new("Frame", { Size = UDim2.new(1, 0, 0, 160), Position = UDim2.new(0, 0, 0, 372),
	BackgroundColor3 = Color3.fromRGB(20, 23, 33), BackgroundTransparency = 0.25,
	BorderSizePixel = 0, Visible = false, ClipsDescendants = true, Parent = PageTouch })
corner(UiListWrap, 10)
new("UIStroke", { Color = Modes[1].Accent, Transparency = 0.75, Thickness = 1, Parent = UiListWrap })
local UiList = new("ScrollingFrame", { Size = UDim2.new(1, -8, 1, -8), Position = UDim2.new(0, 4, 0, 4),
	BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4,
	ScrollBarImageTransparency = 0.5, CanvasSize = UDim2.new(0, 0, 0, 0), Parent = UiListWrap })
local UiListLayout = new("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder, Parent = UiList })
local UiLockTgl = makeToggle(PageTouch, 538, "固定位置", "锁定并记住（仅本服务器生效）", false, function(v)
	State.UILayoutLocked = v
	setUILock(v)
end)
local UiResetBtn = new("TextButton", { Text = "重置本服务器布局记录", Font = Enum.Font.GothamBold, TextSize = 11,
	TextColor3 = Mode().Accent, BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.9,
	BorderSizePixel = 0, AutoButtonColor = false,
	Size = UDim2.new(1, 0, 0, 36), Position = UDim2.new(0, 0, 0, 586), Parent = PageTouch })
corner(UiResetBtn, 10)
table.insert(UiBtns, UiResetBtn)
label({ Text = "开「移动游戏 UI」→ 选目标 → 拖屏幕上的把手 → 开「固定位置」保存。\n位置按服务器分别记忆，下次进同一个服务器自动恢复。",
	Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = Color3.fromRGB(132, 141, 163),
	Position = UDim2.new(0, 2, 0, 628), Size = UDim2.new(1, -4, 0, 44),
	TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top }, PageTouch)
local ToolBtns = {}
label({ Text = "工 具 箱", Font = Enum.Font.GothamBold, TextSize = 11,
	TextColor3 = Color3.fromRGB(120, 129, 152), Size = UDim2.new(1, 0, 0, 18),
	Position = UDim2.new(0, 2, 0, 0), TextXAlignment = Enum.TextXAlignment.Left }, PageTool)
local ClickTpTgl = makeToggle(PageTool, 24, "点击传送", "开启后点地面即可瞬移过去", false, function(v)
	State.ClickTP = v
end)
local TPInput = {}
do
	local defs = { { "X", 0, 68 }, { "Y", 74, 68 }, { "Z", 148, 68 }, { "NAME", 222, 90 } }
	for _, d in ipairs(defs) do
		local b = new("TextBox", {
			Name = d[1], PlaceholderText = d[1], Text = "",
			Font = Enum.Font.Gotham, TextSize = 11,
			TextColor3 = Color3.fromRGB(226, 233, 248),
			PlaceholderColor3 = Color3.fromRGB(105, 113, 134),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.92,
			BorderSizePixel = 0, ClearTextOnFocus = false,
			Size = UDim2.new(0, d[3], 0, 32), Position = UDim2.new(0, d[2], 0, 72), Parent = PageTool,
		})
		corner(b, 8)
		TPInput[d[1]] = b
	end
end
local function toolBtn(text, x, onClick)
	local b = new("TextButton", {
		Text = text, Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = Mode().Accent,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.9,
		BorderSizePixel = 0, AutoButtonColor = false,
		Size = UDim2.new(0, 58, 0, 32), Position = UDim2.new(0, x, 0, 110), Parent = PageTool,
	})
	corner(b, 8)
	b.MouseButton1Click:Connect(onClick)
	table.insert(ToolBtns, b)
	return b
end
toolBtn("取坐标", 0,   function() fillCoords() end)
toolBtn("传送", 62,    function() teleportTyped() end)
toolBtn("传 TA", 124,  function() teleportToPlayer() end)
toolBtn("观察", 186,   function() spectateTyped() end)
toolBtn("重进", 248,   function() rejoinServer() end)
local AntiVoidTgl = makeToggle(PageTool, 152, "防坠落 ANTI-VOID", "掉出地图自动拉回安全点", false, function(v)
	State.AntiVoid = v
end)
   local FakeTgl = makeToggle(PageTool, 200, "分身隐身 FAKE CHAR", "本体升空 · 留半透明分身 · 镜头跟分身", false, function(v)
	setFakeChar(v)
end)
local BrightTgl = makeToggle(PageTool, 248, "夜视 FULLBRIGHT", "去雾 + 全亮，关闭时还原", false, function(v)
	setFullbright(v)
end)
local AntiKbTgl = makeToggle(PageTool, 296, "防击退 ANTI-KB", "限制异常击飞速度", false, function(v)
	State.AntiKB = v
end)
local AntiStunTgl = makeToggle(PageTool, 344, "防失控 ANTI-STUN", "自动解除被眩晕 / 被坐下", false, function(v)
	State.AntiStun = v
end)
local GravitySlider = makeSlider(PageTool, "重力 GRAVITY", 392, -200, 300, math.floor(Workspace.Gravity + 0.5), " g",
	function(v) Workspace.Gravity = v end, false)
local FreecamTgl = makeToggle(PageTool, 446, "自由视角 FREECAM", "WASD 飞镜头 · Shift 加速", false, function(v)
	setFreecam(v)
end)
label({ Text = "传 送 TELEPORT", Font = Enum.Font.GothamBold, TextSize = 11,
	TextColor3 = Color3.fromRGB(120, 129, 152), Size = UDim2.new(1, 0, 0, 16),
	Position = UDim2.new(0, 2, 0, 494), TextXAlignment = Enum.TextXAlignment.Left }, PageTool)
local TPTarget = nil
local TargetBtn = new("TextButton", { Text = "选择目标 ▾  （玩家 / NPC）", Font = Enum.Font.GothamBold, TextSize = 11,
	TextColor3 = Mode().Accent, BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.9,
	BorderSizePixel = 0, AutoButtonColor = false,
	Size = UDim2.new(1, 0, 0, 36), Position = UDim2.new(0, 0, 0, 516), Parent = PageTool })
corner(TargetBtn, 10)
table.insert(ToolBtns, TargetBtn)
local TPListWrap = new("Frame", { Size = UDim2.new(1, 0, 0, 150), Position = UDim2.new(0, 0, 0, 558),
	BackgroundColor3 = Color3.fromRGB(20, 23, 33), BackgroundTransparency = 0.25,
	BorderSizePixel = 0, Visible = false, ClipsDescendants = true, Parent = PageTool })
corner(TPListWrap, 10)
new("UIStroke", { Color = Modes[1].Accent, Transparency = 0.75, Thickness = 1, Parent = TPListWrap })
local TPList = new("ScrollingFrame", { Size = UDim2.new(1, -8, 1, -8), Position = UDim2.new(0, 4, 0, 4),
	BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4,
	ScrollBarImageTransparency = 0.5, CanvasSize = UDim2.new(0, 0, 0, 0), Parent = TPListWrap })
local TPListLayout = new("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder, Parent = TPList })
local function pickTarget(kind, ref, name)
	TPTarget = { Kind = kind, Ref = ref, Name = name }
	TargetBtn.Text = "目标：" .. name
	TPListWrap.Visible = false
	if notify then notify("已选择目标：" .. name) end
end
local function refreshTargetList()
	for _, c in ipairs(TPList:GetChildren()) do
		if c:IsA("TextButton") then c:Destroy() end
	end
	for _, pl in ipairs(Players:GetPlayers()) do
		if pl ~= LP then
			local b = new("TextButton", { Text = "[玩家] " .. (pl.DisplayName or pl.Name),
				Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = Color3.fromRGB(226, 233, 248),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.94,
				BorderSizePixel = 0, AutoButtonColor = false,
				Size = UDim2.new(1, -4, 0, 26), Parent = TPList })
			corner(b, 6)
			b.MouseButton1Click:Connect(function() pickTarget("Player", pl, pl.DisplayName or pl.Name) end)
		end
	end
	local cnt = 0
	for _, m in ipairs(Workspace:GetDescendants()) do
		if cnt >= 30 then break end
		if m:IsA("Model") and m ~= LP.Character and m:FindFirstChildOfClass("Humanoid")
			and not Players:GetPlayerFromCharacter(m) then
			cnt = cnt + 1
			local b = new("TextButton", { Text = "[NPC] " .. m.Name,
				Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = Color3.fromRGB(200, 210, 230),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.94,
				BorderSizePixel = 0, AutoButtonColor = false,
				Size = UDim2.new(1, -4, 0, 26), Parent = TPList })
			corner(b, 6)
			b.MouseButton1Click:Connect(function() pickTarget("NPC", m, m.Name) end)
		end
	end
	TPList.CanvasSize = UDim2.new(0, 0, 0, (#TPList:GetChildren() - 1) * 29)
end
TargetBtn.MouseButton1Click:Connect(function()
	TPListWrap.Visible = not TPListWrap.Visible
	if TPListWrap.Visible then refreshTargetList() end
end)
local function tpTargetCF()
	if not TPTarget then return nil end
	if TPTarget.Kind == "Player" then
		local c = TPTarget.Ref and TPTarget.Ref.Character
		local hrp = c and c:FindFirstChild("HumanoidRootPart")
		return hrp and hrp.CFrame or nil
	else
		local m = TPTarget.Ref
		if not (m and m.Parent) then return nil end
		local pp = m.PrimaryPart
		if not pp then
			for _, d in ipairs(m:GetDescendants()) do
				if d:IsA("BasePart") then pp = d; break end
			end
		end
		return pp and pp.CFrame or nil
	end
end
local TPOnceBtn = new("TextButton", { Text = "传送到目标 TP ONCE", Font = Enum.Font.GothamBold, TextSize = 11,
	TextColor3 = Mode().Accent, BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.9,
	BorderSizePixel = 0, AutoButtonColor = false,
	Size = UDim2.new(1, 0, 0, 36), Position = UDim2.new(0, 0, 0, 714), Parent = PageTool })
corner(TPOnceBtn, 10)
table.insert(ToolBtns, TPOnceBtn)
TPOnceBtn.MouseButton1Click:Connect(function()
	local cf = tpTargetCF()
	if cf and HRP and HRP.Parent then
		HRP.CFrame = cf + Vector3.new(0, State.TPOffsetY, 0)
		if notify then notify("已传送到 " .. (TPTarget and TPTarget.Name or "目标")) end
	elseif notify then
		notify("未选择目标或目标已失效", Color3.fromRGB(255, 108, 118))
	end
end)
local TPLoopTgl = makeToggle(PageTool, 756, "循环传送 LOOP TP", "持续锁定目标（离开即停）", false, function(v)
	State.TPLoop = v
	if v and not TPTarget and notify then
		notify("请先选择目标", Color3.fromRGB(255, 108, 118))
		State.TPLoop = false
		TPLoopTgl.Set(false, true)
	end
end)
local TPSpeedSlider = makeSlider(PageTool, "循环间隔 (0=每帧)", 804, 0, 20, 0, " 秒", function(v)
	State.TPInterval = v / 10
end, false)
local TPOffSlider = makeSlider(PageTool, "高度偏移", 856, 0, 30, 3, " m", function(v)
	State.TPOffsetY = v
end, false)
function getTargetPlayer(name)
	name = tostring(name or ""):lower()
	if name == "" then return nil end
	local fuzzy
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LP then
			local n = p.Name:lower()
			local d = (p.DisplayName or p.Name):lower()
			if n == name or d == name then return p end
			if not fuzzy and (n:sub(1, #name) == name or d:sub(1, #name) == name) then fuzzy = p end
		end
	end
	return fuzzy
end
function fillCoords()
	if not HRP or not HRP.Parent then return end
	TPInput.X.Text   = tostring(math.floor(HRP.Position.X))
	TPInput.Y.Text   = tostring(math.floor(HRP.Position.Y))
	TPInput.Z.Text   = tostring(math.floor(HRP.Position.Z))
end
function teleportTyped()
	if not HRP or not HRP.Parent then return end
	local x = tonumber(TPInput.X.Text)
	local y = tonumber(TPInput.Y.Text)
	local z = tonumber(TPInput.Z.Text)
	if x and y and z then
		HRP.CFrame = CFrame.new(x, y + 3, z)
	end
end
function teleportToPlayer()
	local p = getTargetPlayer(TPInput.NAME.Text)
	if p and p.Character then
		local hrp = p.Character:FindFirstChild("HumanoidRootPart")
		if hrp and HRP then HRP.CFrame = hrp.CFrame + Vector3.new(0, 3, 0) end
	end
end
function spectateTyped()
	local name = TPInput.NAME.Text
	if name == "" then
		Cam.CameraSubject = (Humanoid and Humanoid.Parent) and Humanoid or Cam.CameraSubject
		return
	end
	local p = getTargetPlayer(name)
	if p and p.Character then
		local h = p.Character:FindFirstChildOfClass("Humanoid")
		if h then Cam.CameraSubject = h end
	end
end
function rejoinServer()
	pcall(function()
		TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP)
	end)
end
local lastTransp = -1
RunService.Stepped:Connect(function()
	local c = LP.Character
	if not c then return end
	local t = 0
	if State.FakeChar then
		t = 1
	elseif State.BodyTransp > 0 then
		t = State.BodyTransp
	end
	if t == lastTransp then return end
	lastTransp = t
	for _, p in ipairs(c:GetDescendants()) do
		if p:IsA("BasePart") then p.Transparency = t end
	end
end)
local FAKE_Y = 100000
local FakeClone, FakePlatform, FakeBase, FakeAnchor = nil, nil, nil, nil
local function cleanupFake()
	if FakeClone then pcall(function() FakeClone:Destroy() end) end
	if FakePlatform then pcall(function() FakePlatform:Destroy() end) end
	FakeClone, FakePlatform, FakeBase, FakeAnchor = nil, nil, nil, nil
end
function setFakeChar(on)
	State.FakeChar = on
	if not on then
		if FakeClone and FakeClone.Parent and HRP and HRP.Parent then
			HRP.CFrame = FakeClone:GetPivot()
		end
		cleanupFake()
		lastTransp = -1
		if Humanoid and Humanoid.Parent then Cam.CameraSubject = Humanoid end
		return
	end
	if not (HRP and HRP.Parent) or not Humanoid then State.FakeChar = false; return end
	local hip = (Humanoid.HipHeight > 0) and Humanoid.HipHeight or 2.5
	FakeAnchor = Vector3.new(HRP.Position.X, FAKE_Y, HRP.Position.Z)
	FakeBase   = HRP.Position - Vector3.new(0, hip, 0)
	FakePlatform = Instance.new("Part")
	FakePlatform.Name = "HonFakePlatform"
	FakePlatform.Size = Vector3.new(400, 10, 400)
	FakePlatform.Anchored = true
	FakePlatform.CanCollide = true
	FakePlatform.Transparency = 1
	FakePlatform.CFrame = CFrame.new(FakeAnchor - Vector3.new(0, 5, 0))
	FakePlatform.Parent = Workspace
	FakeClone = HRP.Parent:Clone()
	FakeClone.Name = "HonFakeClone"
	FakeClone.Parent = Workspace
	for _, d in ipairs(FakeClone:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Transparency = 0.45
			d.CanCollide = false
			d.CastShadow = false
		elseif d:IsA("Script") or d:IsA("LocalScript") then
			d:Destroy()
		end
	end
	local fhrp = FakeClone:FindFirstChild("HumanoidRootPart")
	if fhrp then fhrp.Anchored = true end
	local fh = FakeClone:FindFirstChildOfClass("Humanoid")
	if fh then Cam.CameraSubject = fh end
	HRP.CFrame = CFrame.new(FakeAnchor + Vector3.new(0, hip + 1, 0))
	lastTransp = -1
end
pcall(function() RunService:UnbindFromRenderStep("HonFakeSync") end)
RunService:BindToRenderStep("HonFakeSync", 1999, function()
	if not State.FakeChar then return end
	if not (FakeClone and FakeClone.Parent) or not (HRP and HRP.Parent) then return end
	local fhrp = FakeClone:FindFirstChild("HumanoidRootPart")
	if not fhrp then return end
	if HRP.Position.Y < FAKE_Y - 300 then
		HRP.CFrame = CFrame.new(FakeAnchor + Vector3.new(0, 3, 0))
	end
	local rel = HRP.Position - FakeAnchor
	fhrp.CFrame = CFrame.new(FakeBase + rel) * (HRP.CFrame - HRP.Position)
end)
local LightBackup = nil
function setFullbright(on)
	State.Fullbright = on
	if on then
		if not LightBackup then
			LightBackup = {
				Ambient = Lighting.Ambient, OutdoorAmbient = Lighting.OutdoorAmbient,
				Brightness = Lighting.Brightness, FogEnd = Lighting.FogEnd,
				GlobalShadows = Lighting.GlobalShadows,
			}
		end
		Lighting.Ambient = Color3.new(1, 1, 1)
		Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
		Lighting.Brightness = 2
		Lighting.FogEnd = 1e9
		Lighting.GlobalShadows = false
	elseif LightBackup then
		Lighting.Ambient = LightBackup.Ambient
		Lighting.OutdoorAmbient = LightBackup.OutdoorAmbient
		Lighting.Brightness = LightBackup.Brightness
		Lighting.FogEnd = LightBackup.FogEnd
		Lighting.GlobalShadows = LightBackup.GlobalShadows
	end
end
local FreecamPrev = nil
local fcYaw, fcPitch = 0, 0
function setFreecam(on)
	State.Freecam = on
	if on then
		FreecamPrev = Cam.CameraType
		local px, py = Cam.CFrame:ToEulerAnglesYXZ()
		fcPitch, fcYaw = px, py
		Cam.CameraType = Enum.CameraType.Scriptable
		if HRP and HRP.Parent then HRP.AssemblyLinearVelocity = Vector3.zero end
	else
		Cam.CameraType = Enum.CameraType.Custom
		if Humanoid and Humanoid.Parent then Cam.CameraSubject = Humanoid end
	end
end
pcall(function() RunService:UnbindFromRenderStep("HonFreecam") end)
RunService:BindToRenderStep("HonFreecam", 10000, function(dt)
	if not State.Freecam then return end
	if Cam.CameraType ~= Enum.CameraType.Scriptable then Cam.CameraType = Enum.CameraType.Scriptable end
	local rot = CFrame.fromEulerAnglesYXZ(fcPitch, fcYaw, 0)
	local pos = Cam.CFrame.Position
	local d = keyDir()
	if d then
		local sp = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) and 180 or 60
		pos = pos + d * sp * dt
	end
	Cam.CFrame = CFrame.new(pos) * rot
end)
UserInputService.InputChanged:Connect(function(i)
	if State.Freecam and i.UserInputType == Enum.UserInputType.MouseMovement then
		fcYaw = fcYaw - i.Delta.X * 0.0035
		fcPitch = math.clamp(fcPitch - i.Delta.Y * 0.0035, -math.rad(85), math.rad(85))
	end
end)
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if not State.ClickTP then return end
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
	if not HRP or not HRP.Parent then return end
	local pos = (input.UserInputType == Enum.UserInputType.Touch) and input.Position or UserInputService:GetMouseLocation()
	local ray = Cam:ViewportPointToRay(pos.X, pos.Y)
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = { LP.Character }
	local res = Workspace:Raycast(ray.Origin, ray.Direction * 2000, params)
	if res then
		HRP.CFrame = CFrame.new(res.Position + Vector3.new(0, 3, 0))
	end
end)
local FunBtns = {}
label({ Text = "娱 乐 功 能", Font = Enum.Font.GothamBold, TextSize = 11,
	TextColor3 = Color3.fromRGB(120, 129, 152), Size = UDim2.new(1, 0, 0, 18),
	Position = UDim2.new(0, 2, 0, 0), TextXAlignment = Enum.TextXAlignment.Left }, PageFun)
local SpinTgl    = makeToggle(PageFun, 24,  "自转 SPIN", "角色原地高速旋转", false, function(v) State.Spin = v end)
local RainbowTgl = makeToggle(PageFun, 72,  "彩虹角色 RAINBOW", "本体变色，别人也看得见", false, function(v)
	State.Rainbow = v
	if not v and LP.Character then
		for _, q in ipairs(LP.Character:GetDescendants()) do
			if q:IsA("BasePart") then q.Color = Color3.fromRGB(163, 162, 165) end
		end
	end
end)
local MAT_LIST = {
	{ Enum.Material.Gold, "GOLD" }, { Enum.Material.Neon, "NEON" },
	{ Enum.Material.Glass, "GLASS" }, { Enum.Material.Ice, "ICE" },
	{ Enum.Material.SmoothPlastic, "NORMAL" },
}
local matIndex = 1
local MatBtn = new("TextButton", { Text = "材质：NORMAL", Font = Enum.Font.GothamBold, TextSize = 11,
	TextColor3 = Mode().Accent, BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.9,
	BorderSizePixel = 0, AutoButtonColor = false,
	Size = UDim2.new(1, 0, 0, 36), Position = UDim2.new(0, 0, 0, 120), Parent = PageFun })
corner(MatBtn, 10)
table.insert(FunBtns, MatBtn)
MatBtn.MouseButton1Click:Connect(function()
	matIndex = (matIndex % #MAT_LIST) + 1
	MatBtn.Text = "材质：" .. MAT_LIST[matIndex][2]
	local c = LP.Character
	if c then
		for _, q in ipairs(c:GetDescendants()) do
			if q:IsA("BasePart") then q.Material = MAT_LIST[matIndex][1] end
		end
	end
end)
local BounceTgl = makeToggle(PageFun, 164, "超级弹跳 BOUNCE", "落地自动弹起来", false, function(v) State.Bounce = v end)
local LaunchBtn = new("TextButton", { Text = "火箭升空 LAUNCH", Font = Enum.Font.GothamBold, TextSize = 11,
	TextColor3 = Mode().Accent, BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.9,
	BorderSizePixel = 0, AutoButtonColor = false,
	Size = UDim2.new(1, 0, 0, 36), Position = UDim2.new(0, 0, 0, 212), Parent = PageFun })
corner(LaunchBtn, 10)
table.insert(FunBtns, LaunchBtn)
LaunchBtn.MouseButton1Click:Connect(function()
	if HRP and HRP.Parent then
		HRP.AssemblyLinearVelocity = Vector3.new(HRP.AssemblyLinearVelocity.X, 260, HRP.AssemblyLinearVelocity.Z)
	end
end)
local OrbitTgl = makeToggle(PageFun, 256, "绕 TA 转圈 ORBIT", "围绕 NAME 里的玩家公转", false, function(v) State.Orbit = v end)
local LowFxTgl = makeToggle(PageFun, 304, "FPS 加速 LOW FX", "关阴影/粒子/降画质", false, function(v) setLowFx(v) end)
local FlipBtn = new("TextButton", { Text = "倒立 FLIP", Font = Enum.Font.GothamBold, TextSize = 11,
	TextColor3 = Mode().Accent, BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.9,
	BorderSizePixel = 0, AutoButtonColor = false,
	Size = UDim2.new(1, 0, 0, 36), Position = UDim2.new(0, 0, 0, 352), Parent = PageFun })
corner(FlipBtn, 10)
table.insert(FunBtns, FlipBtn)
FlipBtn.MouseButton1Click:Connect(function()
	if HRP and HRP.Parent then
		HRP.CFrame = HRP.CFrame * CFrame.Angles(0, 0, math.rad(180))
	end
end)
FxBackup = nil
function setLowFx(on)
	State.LowFx = on
	if on then
		if FxBackup then return end
		FxBackup = { Quality = nil, Shadows = Lighting.GlobalShadows, Parts = {} }
		pcall(function() FxBackup.Quality = settings().Rendering.QualityLevel end)
		Lighting.GlobalShadows = false
		pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
		for _, v in ipairs(Workspace:GetDescendants()) do
			if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Beam") then
				if v.Enabled then
					table.insert(FxBackup.Parts, v)
					v.Enabled = false
				end
			end
		end
	elseif FxBackup then
		Lighting.GlobalShadows = FxBackup.Shadows
		if FxBackup.Quality ~= nil then
			pcall(function() settings().Rendering.QualityLevel = FxBackup.Quality end)
		end
		for _, v in ipairs(FxBackup.Parts) do
			if v and v.Parent then v.Enabled = true end
		end
		FxBackup = nil
	end
end
local MoreBtns = {}
label({ Text = "更 多 玩 法", Font = Enum.Font.GothamBold, TextSize = 11,
	TextColor3 = Color3.fromRGB(120, 129, 152), Size = UDim2.new(1, 0, 0, 18),
	Position = UDim2.new(0, 2, 0, 0), TextXAlignment = Enum.TextXAlignment.Left }, PageMore)
local DanceTgl = makeToggle(PageMore, 24, "自创跳舞 DANCE", "骨骼正弦摆动，不依赖动画 ID", false, function(v)
	State.Dance = v
	local c = LP.Character
	local an = c and c:FindFirstChild("Animate")
	if an then an.Disabled = v end
	if not v and c then
		for _, m in ipairs(c:GetDescendants()) do
			if m:IsA("Motor6D") then m.Transform = CFrame.new() end
		end
	end
end)
local HeightSlider = makeSlider(PageMore, "身高 HEIGHT", 72, 0.3, 5, 1, " x", function(v)
	setBodyScale(v, nil, nil)
end, false)
local HeadSlider = makeSlider(PageMore, "头比例 HEAD", 124, 0.3, 5, 1, " x", function(v)
	setBodyScale(nil, nil, v)
end, false)
local HaloTgl = makeToggle(PageMore, 178, "头顶光环 HALO", "跟着头转的霓虹光环", false, function(v)
	State.Halo = v
	if not v then HaloPart = nil end
end)
local FollowTgl = makeToggle(PageMore, 226, "自动跟随 FOLLOW", "自动走向 NAME 里的玩家", false, function(v) State.Follow = v end)
local FaceTgl   = makeToggle(PageMore, 274, "始终注视 FACING", "角色一直面朝 NAME 玩家", false, function(v) State.Face = v end)
local FeignBtn = new("TextButton", { Text = "装死躺平 FEIGN", Font = Enum.Font.GothamBold, TextSize = 11,
	TextColor3 = Mode().Accent, BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.9,
	BorderSizePixel = 0, AutoButtonColor = false,
	Size = UDim2.new(1, 0, 0, 36), Position = UDim2.new(0, 0, 0, 322), Parent = PageMore })
corner(FeignBtn, 10)
table.insert(MoreBtns, FeignBtn)
FeignBtn.MouseButton1Click:Connect(function()
	if HRP and HRP.Parent then
		HRP.CFrame = HRP.CFrame * CFrame.Angles(math.rad(90), 0, 0)
		if Humanoid then Humanoid.PlatformStand = true end
	end
end)
local ClockSlider = makeSlider(PageMore, "昼夜 CLOCK", 366, 0, 24, math.floor(Lighting.ClockTime), " h", function(v)
	Lighting.ClockTime = v
end, false)
local FovSlider = makeSlider(PageMore, "视野 FOV", 420, 30, 120, 70, " °", function(v)
	State.FovValue = v
	if not State.Enabled then Cam.FieldOfView = v end
end, false)
local FX_LIST = { "OFF", "BLOOM", "CYBER", "NOIR" }
local fxIndex = 1
local FxBtn = new("TextButton", { Text = "画面特效：OFF", Font = Enum.Font.GothamBold, TextSize = 11,
	TextColor3 = Mode().Accent, BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.9,
	BorderSizePixel = 0, AutoButtonColor = false,
	Size = UDim2.new(1, 0, 0, 36), Position = UDim2.new(0, 0, 0, 474), Parent = PageMore })
corner(FxBtn, 10)
table.insert(MoreBtns, FxBtn)
FxBtn.MouseButton1Click:Connect(function() applyScreenFx() end)
function setBodyScale(h, w, head)
	local c = LP.Character
	if not c then return end
	for _, v in ipairs(c:GetDescendants()) do
		if v:IsA("NumberValue") then
			if h and v.Name == "BodyHeightScale" then v.Value = h end
			if w and (v.Name == "BodyWidthScale" or v.Name == "BodyDepthScale") then v.Value = w end
			if head and v.Name == "HeadScale" then v.Value = head end
		end
	end
end
local FxInstances = {}
function applyScreenFx()
	fxIndex = (fxIndex % #FX_LIST) + 1
	for _, v in ipairs(FxInstances) do
		if v and v.Parent then v:Destroy() end
	end
	FxInstances = {}
	local mode = FX_LIST[fxIndex]
	if mode == "BLOOM" or mode == "CYBER" then
		local b = Instance.new("BloomEffect")
		b.Intensity = (mode == "CYBER") and 1.6 or 1.1
		b.Parent = Lighting
		table.insert(FxInstances, b)
	end
	if mode == "CYBER" then
		local cc = Instance.new("ColorCorrectionEffect")
		cc.TintColor = Color3.fromRGB(190, 130, 255)
		cc.Saturation = 0.25
		cc.Parent = Lighting
		table.insert(FxInstances, cc)
	elseif mode == "NOIR" then
		local cc = Instance.new("ColorCorrectionEffect")
		cc.Saturation = -1
		cc.Contrast = 0.3
		cc.Parent = Lighting
		table.insert(FxInstances, cc)
		local bl = Instance.new("BlurEffect")
		bl.Size = 2
		bl.Parent = Lighting
		table.insert(FxInstances, bl)
	end
	FxBtn.Text = "画面特效：" .. mode
end
pcall(function() RunService:UnbindFromRenderStep("HonDance") end)
RunService:BindToRenderStep("HonDance", 9999, function()
	if not State.Dance then return end
	local c = LP.Character
	if not c then return end
	local t = tick() * 5
	for _, m in ipairs(c:GetDescendants()) do
		if m:IsA("Motor6D") then
			local n = m.Name
			local amp = 0
			if n:find("Shoulder") or n:find("Elbow") then amp = 0.9
			elseif n:find("Hip") or n:find("Knee") then amp = 0.5
			elseif n:find("Neck") or n:find("Waist") then amp = 0.35 end
			if amp > 0 then
				m.Transform = CFrame.Angles(math.sin(t) * amp, 0, math.cos(t * 0.8) * amp * 0.6)
			end
		end
	end
end)
RunService.Heartbeat:Connect(function()
	if State.Halo then
		local c = LP.Character
		local head = c and c:FindFirstChild("Head")
		if head then
			if not (HaloPart and HaloPart.Parent) then
				HaloPart = Instance.new("Part")
				HaloPart.Name = "HonHalo"
				HaloPart.Size = Vector3.new(3.2, 0.25, 3.2)
				HaloPart.Shape = Enum.PartType.Cylinder
				HaloPart.Material = Enum.Material.Neon
				HaloPart.BrickColor = BrickColor.new("Bright yellow")
				HaloPart.CanCollide = false
				HaloPart.Anchored = true
				HaloPart.Parent = Workspace
			end
			local a = tick() * 2
			HaloPart.CFrame = CFrame.new(head.Position + Vector3.new(0, 2.6, 0)) * CFrame.Angles(0, a, math.rad(75))
		end
	elseif HaloPart then
		if HaloPart.Parent then HaloPart:Destroy() end
		HaloPart = nil
	end
end)
local UtilBtns = {}
label({ Text = "实 用 工 具", Font = Enum.Font.GothamBold, TextSize = 11,
	TextColor3 = Color3.fromRGB(120, 129, 152), Size = UDim2.new(1, 0, 0, 18),
	Position = UDim2.new(0, 2, 0, 0), TextXAlignment = Enum.TextXAlignment.Left }, PageUtil)
label({ Text = "隐 身 录 屏", Font = Enum.Font.GothamBold, TextSize = 11,
	TextColor3 = Color3.fromRGB(120, 129, 152), Size = UDim2.new(1, 0, 0, 16),
	Position = UDim2.new(0, 2, 0, 494), TextXAlignment = Enum.TextXAlignment.Left }, PageUtil)
local StealthTgl = makeToggle(PageUtil, 516, "隐身录屏 STEALTH", "隐藏全部界面 · 功能后台照常跑", false, function(v)
	setStealth(v)
end)
local StealthGameTgl = makeToggle(PageUtil, 564, "连游戏 UI 一起藏", "含 Roblox 核心 UI · 顶栏 · 内置界面", true, function(v)
	State.StealthHideGame = v
	if State.Stealth then
		if v then stealthHideGame() else stealthShowGame() end
	end
end)
label({ Text = "开启后右上角出现一个 REC 悬浮窗：点一下恢复全部界面，再点一下重新隐藏。\n隐藏期间加速 / 飞行 / ESP 全部继续生效。\n注：注入器若是独立原生窗口，脚本无法控制它，请用它自己的快捷键。",
	Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = Color3.fromRGB(132, 141, 163),
	Position = UDim2.new(0, 2, 0, 616), Size = UDim2.new(1, -4, 0, 56),
	TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top }, PageUtil)
local WaypointLabel = label({ Text = "存档点：未设置", Font = Enum.Font.Gotham, TextSize = 10,
	TextColor3 = Color3.fromRGB(132, 141, 163), Size = UDim2.new(1, -4, 0, 20),
	Position = UDim2.new(0, 2, 0, 680), TextXAlignment = Enum.TextXAlignment.Left }, PageUtil)
local function utilBtn(text, y, onClick)
	local b = new("TextButton", { Text = text, Font = Enum.Font.GothamBold, TextSize = 11,
		TextColor3 = Mode().Accent, BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.9,
		BorderSizePixel = 0, AutoButtonColor = false,
		Size = UDim2.new(1, 0, 0, 36), Position = UDim2.new(0, 0, 0, y), Parent = PageUtil })
	corner(b, 10)
	table.insert(UtilBtns, b)
	b.MouseButton1Click:Connect(onClick)
	return b
end
utilBtn("解除卡死 UNSTUCK", 24, function()
	if HRP and HRP.Parent then
		HRP.CFrame = HRP.CFrame + Vector3.new(0, 8, 0)
		HRP.AssemblyLinearVelocity = Vector3.zero
	end
end)
utilBtn("立即重生 RESPAWN", 68, function()
	if Humanoid and Humanoid.Parent then Humanoid.Health = 0 end
end)
local FreezeTgl = makeToggle(PageUtil, 112, "冻结自己 FREEZE", "锚定本体，推不动也掉不下去", false, function(v)
	State.Freeze = v
	if HRP and HRP.Parent and not v then HRP.Anchored = false end
end)
local SaveBtn = utilBtn("保存存档点 SAVE", 160, function()
	if HRP and HRP.Parent then
		State.Waypoint = HRP.Position
		WaypointLabel.Text = string.format("存档点：%d, %d, %d",
			math.floor(State.Waypoint.X), math.floor(State.Waypoint.Y), math.floor(State.Waypoint.Z))
	end
end)
local GoBtn = utilBtn("回到存档点 GO", 160, function()
	if State.Waypoint and HRP and HRP.Parent then
		HRP.CFrame = CFrame.new(State.Waypoint + Vector3.new(0, 3, 0))
	end
end)
SaveBtn.Size = UDim2.new(0.5, -4, 0, 36)
GoBtn.Size = UDim2.new(0.5, -4, 0, 36)
GoBtn.Position = UDim2.new(0.5, 4, 0, 160)
local HidePlrTgl = makeToggle(PageUtil, 204, "隐藏其他玩家", "别人变透明，不再挡视线", false, function(v)
	State.HidePlayers = v
	if not v then
		for _, q in ipairs(HiddenParts) do
			if q and q.Parent then q.Transparency = 0 end
		end
		HiddenParts = {}
	end
end)
HideUiTgl = makeToggle(PageUtil, 252, "隐藏全部 UI", "录屏 / 截图用", false, function(v) setHideUI(v) end)
AutoJumpTgl = makeToggle(PageUtil, 300, "自动连跳 AUTO JUMP", "一直保持弹跳前进", false, function(v) State.AutoJump = v end)
CoordTgl = makeToggle(PageUtil, 348, "坐标显示 COORD", "HUD 上实时显示 XYZ", false, function(v) State.CoordHud = v end)
ZoomSlider = makeSlider(PageUtil, "镜头距离 ZOOM", 396, 1, 120, 20, " m", function(v)
	LP.CameraMaxZoomDistance = v
	LP.CameraMinZoomDistance = v
end, false)
utilBtn("全部关闭 RESET ALL", 450, function()
	for _, t in ipairs(AllToggles) do t.Set(false) end
	if notify then notify("已关闭全部功能", Color3.fromRGB(255, 108, 118)) end
end)
HiddenParts = {}
function setHideUI(on)
	State.HideUI = on
	for _, g in ipairs(PG:GetChildren()) do
		if g:IsA("ScreenGui") and g ~= Gui then
			g.Enabled = not on
		end
	end
	pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, not on)
	end)
end
LockShield = new("TextButton", { Text = "", AutoButtonColor = false,
	BackgroundColor3 = Color3.fromRGB(8, 10, 16), BackgroundTransparency = 0.55, BorderSizePixel = 0,
	Visible = false, Size = UDim2.new(1, 0, 0, PANEL_H - 74), Position = UDim2.new(0, 0, 0, 74), Parent = Main })
LockBadge = new("Frame", { Size = UDim2.new(0, 132, 0, 30), Position = UDim2.new(0.5, -66, 0, 92),
	BackgroundColor3 = Color3.fromRGB(20, 23, 33), BackgroundTransparency = 0.15, BorderSizePixel = 0, Parent = LockShield })
corner(LockBadge, 15)
LockBadgeStroke = new("UIStroke", { Color = Modes[1].Accent, Transparency = 0.35, Thickness = 1, Parent = LockBadge })
LockBadgeIcon = lockIcon(LockBadge, UDim2.new(0, 12, 0.5, -8), Mode().Accent)
label({ Text = "LOCKED", Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = Color3.fromRGB(226, 233, 248),
	Position = UDim2.new(0, 34, 0, 0), Size = UDim2.new(1, -44, 0, 30), TextXAlignment = Enum.TextXAlignment.Left }, LockBadge)
StatusFrame = new("Frame", { Size = UDim2.new(0, 464, 0, 32), Position = UDim2.new(0, 180, 0, PANEL_H - 42),
	BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.95, BorderSizePixel = 0, Parent = Main })
corner(StatusFrame, 12)
Status = label({ Text = "就绪", Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = Color3.fromRGB(150, 159, 182),
	Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(1, -24, 1, 0),
	TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center, RichText = true }, StatusFrame)
label({ Text = "M 切引擎 · F2 开关\nL 锁面板 · E/Q 飞行\nRightCtrl 显隐",
	Font = Enum.Font.Gotham, TextSize = 9, TextColor3 = Color3.fromRGB(105, 113, 134),
	Position = UDim2.new(0, 0, 1, -46), Size = UDim2.new(0, 168, 0, 40),
	TextXAlignment = Enum.TextXAlignment.Center, TextWrapped = true }, Main)
HudFrame = new("Frame", { Size = UDim2.new(0, 172, 0, 40), Position = UDim2.new(0.5, -86, 1, -104),
	BackgroundColor3 = Color3.fromRGB(13, 15, 23), BackgroundTransparency = 0.25,
	BorderSizePixel = 0, Visible = false, Parent = Gui })
corner(HudFrame, 12)
new("UIStroke", { Color = Modes[1].Accent, Transparency = 0.45, Thickness = 1, Parent = HudFrame })
HudText = label({ Text = "0 stud/s", Font = Enum.Font.GothamBold, TextSize = 17, TextColor3 = Color3.fromRGB(238, 243, 255),
	Position = UDim2.new(0, 0, 0, 4), Size = UDim2.new(1, 0, 0, 22), TextXAlignment = Enum.TextXAlignment.Center }, HudFrame)
HudSub = label({ Text = "WALKSPEED", Font = Enum.Font.GothamBold, TextSize = 9, TextColor3 = Modes[1].Accent,
	Position = UDim2.new(0, 0, 0, 24), Size = UDim2.new(1, 0, 0, 12), TextXAlignment = Enum.TextXAlignment.Center }, HudFrame)
FlyWin = new("Frame", { Size = UDim2.new(0, 224, 0, 214), Position = UDim2.new(1, -244, 0, 96),
	BackgroundColor3 = Color3.fromRGB(13, 15, 23), BackgroundTransparency = 0.06,
	BorderSizePixel = 0, Visible = false, Active = true, Parent = Gui })
corner(FlyWin, 16)
FlyWinStroke = new("UIStroke", { Color = Modes[1].Accent, Transparency = 0.5, Thickness = 1, Parent = FlyWin })
FlyBar = new("Frame", { Size = UDim2.new(1, 0, 0, 38), BackgroundTransparency = 1, Parent = FlyWin })
label({ Text = "FLY", Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = Color3.fromRGB(238, 243, 255),
	Position = UDim2.new(0, 16, 0, 9), Size = UDim2.new(0, 120, 0, 20), TextXAlignment = Enum.TextXAlignment.Left }, FlyBar)
FlyClose = new("TextButton", { Text = "×", Font = Enum.Font.GothamBold, TextSize = 16,
	TextColor3 = Color3.fromRGB(255, 108, 118), BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	BackgroundTransparency = 0.94, BorderSizePixel = 0, AutoButtonColor = false,
	Position = UDim2.new(1, -36, 0, 7), Size = UDim2.new(0, 26, 0, 26), Parent = FlyBar })
corner(FlyClose, 8)
FlyClose.MouseButton1Click:Connect(function() FlyTgl.Set(false) end)
FlyToggle = makeToggle(FlyWin, 44, "开关飞行", "WASD 移动 · E/Q 升降", false, function(v) setFly(v) end)
FlySlider = makeSlider(FlyWin, "飞行速度", 96, 10, 250, 60, " sp", function(v) State.FlySpeed = v end, false)
label({ Text = "UP / DOWN 键在右上角 · 主 UI 可关窗",
	Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = Color3.fromRGB(132, 141, 163),
	Position = UDim2.new(0, 16, 0, 150), Size = UDim2.new(1, -32, 0, 28),
	TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top }, FlyWin)
function makeFlyBtn(txt, y)
	local b = new("TextButton", { Text = txt, Font = Enum.Font.GothamBold, TextSize = 12,
		TextColor3 = Color3.fromRGB(238, 243, 255), BackgroundColor3 = Color3.fromRGB(16, 19, 28),
		BackgroundTransparency = 0.12, BorderSizePixel = 0, AutoButtonColor = false,
		Size = UDim2.new(0, 60, 0, 60), Position = UDim2.new(1, -76, 0, y), Visible = false, Parent = Gui })
	corner(b, 30)
	local s = new("UIStroke", { Color = Modes[1].Accent, Transparency = 0.4, Thickness = 2, Parent = b })
	return b, s
end
UpBtn, UpStroke = makeFlyBtn("UP", 96)
DownBtn, DownStroke = makeFlyBtn("DOWN", 166)
FlyUp, FlyDown = false, false
FlyHoldY = nil
function bindHold(btn, setTrue)
	btn.MouseButton1Down:Connect(function() setTrue(true) end)
	btn.MouseButton1Up:Connect(function() setTrue(false) end)
	btn.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.Touch then setTrue(true) end
	end)
	btn.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.Touch then setTrue(false) end
	end)
	btn.MouseLeave:Connect(function() setTrue(false) end)
end
bindHold(UpBtn, function(v) FlyUp = v end)
bindHold(DownBtn, function(v) FlyDown = v end)
UserInputService.InputEnded:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
		FlyUp, FlyDown = false, false
	end
end)
TouchBtns = {}
function makeTouchBtn(index, key)
	local b = new("TextButton", {
		Text = tostring(index), Font = Enum.Font.GothamBold, TextSize = 20,
		TextColor3 = Color3.fromRGB(240, 245, 255),
		BackgroundColor3 = Color3.fromRGB(16, 19, 28), BackgroundTransparency = 0.18,
		BorderSizePixel = 0, AutoButtonColor = false, Active = true,
		Size = UDim2.new(0, 58, 0, 58),
		Position = UDim2.new(0, 24, 0, 150 + (index - 1) * 70),
		Visible = false, Parent = Gui,
	})
	corner(b, 29)
	local s = new("UIStroke", { Color = Modes[1].Accent, Transparency = 0.45, Thickness = 2, Parent = b })
	local obj = { Btn = b, Stroke = s, Key = key }
	local function send(down)
		pcall(function() VirtualInput:SendKeyEvent(down, key, false, game) end)
	end
	b.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
			send(true)
		end
	end)
	b.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
			send(false)
		end
	end)
	b.MouseLeave:Connect(function() send(false) end)
	local dragging, startPos, startMouse = false, nil, nil
	b.InputBegan:Connect(function(i)
		if State.TouchLocked then return end
		if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging, startPos, startMouse = true, b.Position, i.Position
		end
	end)
	UserInputService.InputChanged:Connect(function(i)
		if dragging and (i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseMovement) then
			local d = i.Position - startMouse
			b.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end
	end)
	UserInputService.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
	end)
	TouchBtns[index] = obj
	return obj
end
for i, k in ipairs(TOUCH_KEYS) do makeTouchBtn(i, k) end
PAD_USE_KEYS = false
PadDir = { x = 0, y = 0 }
PadActive = false
PadBtns = {}
PadFrame = new("Frame", {
	Name = "HonPad", Size = UDim2.new(0, 174, 0, 174),
	Position = UDim2.new(1, -198, 0, 320),
	BackgroundTransparency = 1, Visible = false, Parent = Gui,
})
PadScale = new("UIScale", { Scale = 1, Parent = PadFrame })
PAD_CELLS = {
	{ 1, 1, "W A", { Enum.KeyCode.W, Enum.KeyCode.A }, -1,  1 },
	{ 1, 2, "W",   { Enum.KeyCode.W },                   0,  1 },
	{ 1, 3, "W D", { Enum.KeyCode.W, Enum.KeyCode.D },    1,  1 },
	{ 2, 1, "A",   { Enum.KeyCode.A },                  -1,  0 },
	{ 2, 2, "",    nil,                                   0,  0 },
	{ 2, 3, "D",   { Enum.KeyCode.D },                    1,  0 },
	{ 3, 1, "S A", { Enum.KeyCode.S, Enum.KeyCode.A },   -1, -1 },
	{ 3, 2, "S",   { Enum.KeyCode.S },                    0, -1 },
	{ 3, 3, "S D", { Enum.KeyCode.S, Enum.KeyCode.D },    1, -1 },
}
padCenter = nil
for _, c in ipairs(PAD_CELLS) do
	local row, col, txt, keys, dx, dy = c[1], c[2], c[3], c[4], c[5], c[6]
	local b = new("TextButton", {
		Text = txt, Font = Enum.Font.GothamBold, TextSize = 12,
		TextColor3 = Color3.fromRGB(238, 243, 255),
		BackgroundColor3 = Color3.fromRGB(16, 19, 28), BackgroundTransparency = 0.18,
		BorderSizePixel = 0, AutoButtonColor = false,
		Size = UDim2.new(0, 56, 0, 56),
		Position = UDim2.new(0, (col - 1) * 59, 0, (row - 1) * 59),
		Parent = PadFrame,
	})
	corner(b, 12)
	local s = new("UIStroke", { Color = Modes[1].Accent, Transparency = 0.45, Thickness = 2, Parent = b })
	table.insert(PadBtns, { Btn = b, Stroke = s })
	if not keys then
		padCenter = b
		for j = 0, 1 do
			new("Frame", { Size = UDim2.new(0, 22, 0, 3), Position = UDim2.new(0.5, -11, 0.5, -7 + j * 8),
				BackgroundColor3 = Color3.fromRGB(190, 198, 220), BackgroundTransparency = 0.25,
				BorderSizePixel = 0, Parent = b })
		end
	else
		local function press(on)
			if on then
				PadDir.x, PadDir.y = dx, dy
				PadActive = true
			else
				PadActive = false
				PadDir.x, PadDir.y = 0, 0
			end
			if PAD_USE_KEYS then
				for _, k in ipairs(keys) do
					pcall(function() VirtualInput:SendKeyEvent(on, k, false, game) end)
				end
			end
			TweenService:Create(b, TWEEN_FAST, { BackgroundTransparency = on and 0.02 or 0.18 }):Play()
		end
		b.MouseButton1Down:Connect(function() press(true) end)
		b.MouseButton1Up:Connect(function() press(false) end)
		b.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch then press(true) end end)
		b.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch then press(false) end end)
		b.MouseLeave:Connect(function() press(false) end)
	end
end
UserInputService.InputEnded:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
		if PadActive then
			PadActive = false
			PadDir.x, PadDir.y = 0, 0
		end
		for _, o in ipairs(PadBtns) do
			TweenService:Create(o.Btn, TWEEN_FAST, { BackgroundTransparency = 0.18 }):Play()
		end
	end
end)
do
	local holdStart, padDrag, padStart, padMouse = nil, false, nil, nil
	padCenter.MouseButton1Down:Connect(function()
		if State.TouchLocked then return end
		holdStart = tick()
	end)
	padCenter.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.Touch and not State.TouchLocked then holdStart = tick() end
	end)
	UserInputService.InputChanged:Connect(function(i)
		if holdStart and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
			if tick() - holdStart > 0.3 then
				if not padDrag then padDrag, padStart, padMouse = true, PadFrame.Position, i.Position end
				local d = i.Position - padMouse
				PadFrame.Position = UDim2.new(padStart.X.Scale, padStart.X.Offset + d.X,
					padStart.Y.Scale, padStart.Y.Offset + d.Y)
			end
		end
	end)
	UserInputService.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
			holdStart, padDrag = nil, false
		end
	end)
end
function updateTouchVisibility()
	for _, o in ipairs(TouchBtns) do o.Btn.Visible = State.TouchKeys end
	PadFrame.Visible = State.PadKeys
	UpBtn.Visible, DownBtn.Visible = FlyWin.Visible, FlyWin.Visible
end
function updateTouchLock()
	for _, o in ipairs(TouchBtns) do
		TweenService:Create(o.Stroke, TWEEN_FAST, { Transparency = State.TouchLocked and 0.9 or 0.45 }):Play()
		TweenService:Create(o.Btn, TWEEN_FAST, { BackgroundTransparency = State.TouchLocked and 0.35 or 0.18 }):Play()
	end
	for _, o in ipairs(PadBtns) do
		TweenService:Create(o.Stroke, TWEEN_FAST, { Transparency = State.TouchLocked and 0.9 or 0.45 }):Play()
		TweenService:Create(o.Btn, TWEEN_FAST, { BackgroundTransparency = State.TouchLocked and 0.35 or 0.18 }):Play()
	end
end
UI_KW = { "touch", "thumbstick", "thumb", "stick", "jump", "button", "btn", "pad",
	"control", "mobile", "dpad", "joystick", "cross", "move" }
UI_SLOT = "HON_UI_" .. tostring(game.PlaceId) .. "_"
UiTargets    = {}
UiEditTarget = nil
UiHandle     = nil
function uiMatch(n)
	n = tostring(n or ""):lower()
	for _, k in ipairs(UI_KW) do
		if n:find(k, 1, true) then return true end
	end
	return false
end
function uiKeyOf(o)
	local par = o.Parent
	while par and not par:IsA("ScreenGui") do
		o = par
		par = par.Parent
	end
	local sg = (par and par.Name) or "?"
	return sg .. "/" .. o.Name
end
function uiScan()
	local out = {}
	for _, g in ipairs(PG:GetChildren()) do
		if g:IsA("ScreenGui") and g ~= Gui then
			local kids = {}
			for _, c in ipairs(g:GetChildren()) do
				if c:IsA("GuiObject") then table.insert(kids, c) end
			end
			if #kids > 0 then
				table.insert(out, { Label = "[整个界面] " .. g.Name, Items = kids, Key = uiKeyOf(g) })
			end
			local ok, desc = pcall(function() return g:GetDescendants() end)
			if ok and desc then
				for _, d in ipairs(desc) do
					if #out >= 40 then break end
					if d:IsA("GuiObject") and uiMatch(d.Name) then
						table.insert(out, { Label = "[控件] " .. d.Name, Items = { d }, Key = uiKeyOf(d) })
					end
				end
			end
		end
	end
	return out
end
function uiApply(t)
	if not t then return end
	for _, it in ipairs(t.Items) do
		if it.Obj and it.Obj.Parent then
			pcall(function()
				it.Obj.Position = UDim2.new(it.Base.X.Scale, it.Base.X.Offset + t.Off.x,
					it.Base.Y.Scale, it.Base.Y.Offset + t.Off.y)
			end)
		end
	end
end
function uiMakeTarget(cand)
	local items = {}
	for _, o in ipairs(cand.Items) do
		table.insert(items, { Obj = o, Base = o.Position })
	end
	return { Name = cand.Label, Key = cand.Key, Items = items, Off = { x = 0, y = 0 } }
end
function uiFindTarget(key)
	for _, t in ipairs(UiTargets) do
		if t.Key == key then return t end
	end
	return nil
end
function uiIdxGet()
	local v = nil
	pcall(function() v = TeleportService:GetTeleportSetting(UI_SLOT .. "KEYS") end)
	return tostring(v or "")
end
function uiIdxAdd(k)
	local cur = uiIdxGet()
	if cur == "" or not cur:find(k, 1, true) then
		pcall(function()
			TeleportService:SetTeleportSetting(UI_SLOT .. "KEYS", (cur == "") and k or (cur .. "," .. k))
		end)
	end
end
function uiIdxDel(k)
	local keep = {}
	for w in string.gmatch(uiIdxGet(), "[^,]+") do
		if w ~= k then table.insert(keep, w) end
	end
	pcall(function() TeleportService:SetTeleportSetting(UI_SLOT .. "KEYS", table.concat(keep, ",")) end)
end
function uiSave(t)
	pcall(function()
		TeleportService:SetTeleportSetting(UI_SLOT .. t.Key .. "_X", t.Off.x)
		TeleportService:SetTeleportSetting(UI_SLOT .. t.Key .. "_Y", t.Off.y)
	end)
	uiIdxAdd(t.Key)
end
function uiClear(t)
	pcall(function()
		TeleportService:SetTeleportSetting(UI_SLOT .. t.Key .. "_X", nil)
		TeleportService:SetTeleportSetting(UI_SLOT .. t.Key .. "_Y", nil)
	end)
	uiIdxDel(t.Key)
end
pcall(function() RunService:UnbindFromRenderStep("HonUILayout") end)
RunService:BindToRenderStep("HonUILayout", 9997, function()
	for _, t in ipairs(UiTargets) do
		if t.Off.x ~= 0 or t.Off.y ~= 0 then uiApply(t) end
	end
end)
function uiDestroyHandle()
	if UiHandle then
		if UiHandle.Parent then UiHandle:Destroy() end
		UiHandle = nil
	end
end
function uiBuildHandle()
	uiDestroyHandle()
	local t = UiEditTarget
	if not t then return end
	local first = t.Items[1] and t.Items[1].Obj
	if not (first and first.Parent) then return end
	local sz, ps = first.AbsoluteSize, first.AbsolutePosition
	local uiScaleObj = Gui:FindFirstChildOfClass("UIScale")
	local sc = (uiScaleObj and uiScaleObj.Scale) or 1
	if sc <= 0 then sc = 1 end
	local h = new("Frame", { Name = "HonUIHandle",
		Size = UDim2.new(0, (math.max(sz.X + 28, 90)) / sc, 0, (math.max(sz.Y + 28, 60)) / sc),
		Position = UDim2.new(0, ps.X / sc - 14 / sc, 0, ps.Y / sc - 14 / sc),
		BackgroundColor3 = Mode().Accent, BackgroundTransparency = 0.72,
		BorderSizePixel = 0, Active = true, Parent = Gui })
	corner(h, 12)
	new("UIStroke", { Color = Mode().Accent, Thickness = 2, Parent = h })
	label({ Text = "拖动我  ·  " .. t.Name, Font = Enum.Font.GothamBold, TextSize = 10,
		TextColor3 = Color3.fromRGB(240, 245, 255), Position = UDim2.new(0, 0, 0, -17),
		Size = UDim2.new(1, 0, 0, 15), TextXAlignment = Enum.TextXAlignment.Left,
		TextScaled = false, BackgroundTransparency = 1 }, h)
	UiHandle = h
	local dragging, startMouse, baseOffX, baseOffY, basePos = false, nil, 0, 0, nil
	h.InputBegan:Connect(function(i)
		if State.UILayoutLocked then return end
		if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			startMouse = i.Position
			baseOffX, baseOffY = t.Off.x, t.Off.y
			basePos = h.Position
		end
	end)
	UserInputService.InputChanged:Connect(function(i)
		if dragging and (i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseMovement) then
			local d = i.Position - startMouse
			t.Off.x = baseOffX + d.X
			t.Off.y = baseOffY + d.Y
			uiApply(t)
			h.Position = UDim2.new(basePos.X.Scale, basePos.X.Offset + d.X / sc, basePos.Y.Scale, basePos.Y.Offset + d.Y / sc)
		end
	end)
	UserInputService.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)
end
function uiRefreshList()
	for _, c in ipairs(UiList:GetChildren()) do
		if c:IsA("TextButton") then c:Destroy() end
	end
	local cands = uiScan()
	if #cands == 0 then
		local none = new("TextButton", { Text = "没找到可移动的游戏 UI", Font = Enum.Font.Gotham, TextSize = 11,
			TextColor3 = Color3.fromRGB(140, 149, 172), BackgroundTransparency = 1,
			BorderSizePixel = 0, AutoButtonColor = false, Size = UDim2.new(1, -4, 0, 26), Parent = UiList })
		corner(none, 6)
	else
		for _, c in ipairs(cands) do
			local b = new("TextButton", { Text = c.Label, Font = Enum.Font.Gotham, TextSize = 11,
				TextColor3 = Color3.fromRGB(226, 233, 248),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.94,
				BorderSizePixel = 0, AutoButtonColor = false,
				Size = UDim2.new(1, -4, 0, 26), Parent = UiList })
			corner(b, 6)
			b.MouseButton1Click:Connect(function()
				local t = uiFindTarget(c.Key)
				if not t then
					t = uiMakeTarget(c)
					table.insert(UiTargets, t)
				end
				UiEditTarget = t
				UiPickBtn.Text = "目标：" .. c.Label
				UiListWrap.Visible = false
				if State.MoveGameUI then uiBuildHandle() end
				if notify then notify("已选中：" .. c.Label) end
			end)
		end
	end
	UiList.CanvasSize = UDim2.new(0, 0, 0, (#UiList:GetChildren() - 1) * 29)
end
function setUIEdit(on)
	if not on then
		uiDestroyHandle()
		return
	end
	if not UiEditTarget then
		if notify then notify("请先点「选择要移动的 UI」", Color3.fromRGB(255, 108, 118)) end
		if MoveUiTgl then MoveUiTgl.Set(false, true) end
		State.MoveGameUI = false
		return
	end
	uiBuildHandle()
	if notify then notify("拖动屏幕上的把手即可移动") end
end
function setUILock(on)
	local t = UiEditTarget
	if not t then
		if notify then notify("请先点「选择要移动的 UI」", Color3.fromRGB(255, 108, 118)) end
		if UiLockTgl then UiLockTgl.Set(false, true) end
		State.UILayoutLocked = false
		return
	end
	if on then
		uiSave(t)
		uiDestroyHandle()
		if notify then notify("已固定：" .. t.Name .. "（本服务器自动生效）", Color3.fromRGB(120, 230, 150)) end
	else
		uiClear(t)
		t.Off.x, t.Off.y = 0, 0
		uiApply(t)
		if notify then notify("已解除固定并还原原位") end
	end
end
function uiRestore()
	for attempt = 1, 8 do
		local cands = uiScan()
		local hit = 0
		for _, c in ipairs(cands) do
			local x = nil
			pcall(function() x = TeleportService:GetTeleportSetting(UI_SLOT .. c.Key .. "_X") end)
			if x ~= nil then
				local y = 0
				pcall(function() y = TeleportService:GetTeleportSetting(UI_SLOT .. c.Key .. "_Y") or 0 end)
				local t = uiFindTarget(c.Key)
				if not t then
					t = uiMakeTarget(c)
					table.insert(UiTargets, t)
				end
				t.Off.x = tonumber(x) or 0
				t.Off.y = tonumber(y) or 0
				UiEditTarget = t
				UiPickBtn.Text = "目标：" .. c.Label
				hit = hit + 1
			end
		end
		if hit > 0 then
			for _, t in ipairs(UiTargets) do uiApply(t) end
			State.UILayoutLocked = true
			if UiLockTgl then UiLockTgl.Set(true, true) end
			if notify then notify("已恢复本服务器的 UI 布局（" .. hit .. " 项）", Color3.fromRGB(120, 230, 150)) end
			return
		end
		twait(1.5)
	end
end
UiPickBtn.MouseButton1Click:Connect(function()
	UiListWrap.Visible = not UiListWrap.Visible
	if UiListWrap.Visible then uiRefreshList() end
end)
UiResetBtn.MouseButton1Click:Connect(function()
	for w in string.gmatch(uiIdxGet(), "[^,]+") do
		pcall(function()
			TeleportService:SetTeleportSetting(UI_SLOT .. w .. "_X", nil)
			TeleportService:SetTeleportSetting(UI_SLOT .. w .. "_Y", nil)
		end)
	end
	pcall(function() TeleportService:SetTeleportSetting(UI_SLOT .. "KEYS", nil) end)
	for _, t in ipairs(UiTargets) do
		t.Off.x, t.Off.y = 0, 0
		uiApply(t)
	end
	UiTargets = {}
	UiEditTarget = nil
	uiDestroyHandle()
	UiPickBtn.Text = "选择要移动的 UI  ▾"
	if notify then notify("已清除本服务器的全部布局记录") end
end)
function SetTab(i)
	CurTab = i
	PageEng.Visible, PageAssist.Visible, PageEsp.Visible, PageTouch.Visible, PageTool.Visible, PageFun.Visible, PageMore.Visible, PageUtil.Visible =
		(i == 1), (i == 2), (i == 3), (i == 4), (i == 5), (i == 6), (i == 7), (i == 8)
	Pages.CanvasSize = UDim2.new(0, 0, 0, PAGE_H[i] or 520)
	Pages.ScrollBarImageColor3 = Mode().Accent
	for j, t in ipairs(TabBtns) do
		local on = (j == i)
		TweenService:Create(t.Btn, TWEEN_FAST, { TextColor3 = on and Color3.fromRGB(238, 243, 255) or Color3.fromRGB(140, 149, 172) }):Play()
		TweenService:Create(t.Underline, TWEEN_FAST, { BackgroundTransparency = on and 0 or 1 }):Play()
	end
end
function SetMode(i)
	State.ModeIndex = i
	local m = Modes[i]
	if State.SpeedLocked then
		SpeedSlider.SetRange(m.Min, math.max(m.Max, State.Speed))
		SpeedSlider.Set(State.Speed)
	else
		State.Speed = m.Speed
		SpeedSlider.SetRange(m.Min, m.Max)
		SpeedSlider.Set(m.Speed)
	end
	State.Smooth = m.Smooth
	SmoothSlider.Set(m.Smooth)
	for j, c in ipairs(Cards) do
		local on = (j == i)
		TweenService:Create(c.Card, TWEEN_FAST, {
			BackgroundTransparency = on and 0.05 or 0.3,
			BackgroundColor3 = on and Color3.fromRGB(38, 43, 60) or Color3.fromRGB(26, 29, 41) }):Play()
		TweenService:Create(c.Stroke, TWEEN_FAST, { Transparency = on and 0 or 0.78 }):Play()
		TweenService:Create(c.Bar, TWEEN_FAST, {
			Size = UDim2.new(0, on and 4 or 3, 0, on and 34 or 30),
			BackgroundTransparency = on and 0 or 0.4 }):Play()
	end
	TweenService:Create(Glow, TWEEN_SOFT, { BackgroundColor3 = m.Accent }):Play()
	TweenService:Create(Dot, TWEEN_SOFT, { BackgroundColor3 = m.Accent }):Play()
	TweenService:Create(MiniStroke, TWEEN_SOFT, { Color = m.Accent }):Play()
	TweenService:Create(LockBadgeStroke, TWEEN_SOFT, { Color = m.Accent }):Play()
	TweenService:Create(LockBadgeIcon.Shackle, TWEEN_SOFT, { BackgroundColor3 = m.Accent }):Play()
	TweenService:Create(LockBadgeIcon.Body, TWEEN_SOFT, { BackgroundColor3 = m.Accent }):Play()
	TweenService:Create(FlyWinStroke, TWEEN_SOFT, { Color = m.Accent }):Play()
	TweenService:Create(UpStroke, TWEEN_SOFT, { Color = m.Accent }):Play()
	TweenService:Create(DownStroke, TWEEN_SOFT, { Color = m.Accent }):Play()
	TweenService:Create(HudSub, TWEEN_SOFT, { TextColor3 = m.Accent }):Play()
	for _, s in ipairs(AllSliders) do s.Refresh() end
	for _, t in ipairs(AllToggles) do t.Refresh() end
	for _, o in ipairs(TouchBtns) do TweenService:Create(o.Stroke, TWEEN_SOFT, { Color = m.Accent }):Play() end
	for _, o in ipairs(PadBtns) do TweenService:Create(o.Stroke, TWEEN_SOFT, { Color = m.Accent }):Play() end
	for _, b in ipairs(ToolBtns) do TweenService:Create(b, TWEEN_SOFT, { TextColor3 = m.Accent }):Play() end
	for _, b in ipairs(FunBtns) do TweenService:Create(b, TWEEN_SOFT, { TextColor3 = m.Accent }):Play() end
	for _, b in ipairs(MoreBtns) do TweenService:Create(b, TWEEN_SOFT, { TextColor3 = m.Accent }):Play() end
	for _, b in ipairs(UtilBtns) do TweenService:Create(b, TWEEN_SOFT, { TextColor3 = m.Accent }):Play() end
	for _, b in ipairs(UiBtns) do TweenService:Create(b, TWEEN_SOFT, { TextColor3 = m.Accent }):Play() end
	InertiaToggle.Dim(m.Id ~= "V")
	SlideToggle.Dim(m.Id ~= "CF")
	if notify then notify("引擎已切换：" .. m.Name, m.Accent) end
	TeleportToggle.Dim(m.Id ~= "CF")
	cur, CFAccum = 0, 0
end
function applyPanelLock(v)
	State.PanelLocked = v
	LockShield.Visible = v
	TweenService:Create(LockIcon.Shackle, TWEEN_FAST, { BackgroundColor3 = v and Mode().Accent or Color3.fromRGB(150, 158, 180) }):Play()
	TweenService:Create(LockIcon.Body, TWEEN_FAST, { BackgroundColor3 = v and Mode().Accent or Color3.fromRGB(150, 158, 180) }):Play()
end
LockBtn.MouseButton1Click:Connect(function() applyPanelLock(not State.PanelLocked) end)
do
	local dragging, startPos, startMouse = false, nil, nil
	Header.InputBegan:Connect(function(input)
		if State.PanelLocked then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging, startPos, startMouse = true, Main.Position, input.Position
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local d = input.Position - startMouse
			Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
	end)
	local fDrag, fPos, fMouse = false, nil, nil
	FlyBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			fDrag, fPos, fMouse = true, FlyWin.Position, input.Position
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if fDrag and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local d = input.Position - fMouse
			FlyWin.Position = UDim2.new(fPos.X.Scale, fPos.X.Offset + d.X, fPos.Y.Scale, fPos.Y.Offset + d.Y)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then fDrag = false end
	end)
end
KEY_FWD  = { Enum.KeyCode.W, Enum.KeyCode.Up }
KEY_BACK = { Enum.KeyCode.S, Enum.KeyCode.Down }
KEY_LEFT = { Enum.KeyCode.A, Enum.KeyCode.Left }
KEY_RIGHT = { Enum.KeyCode.D, Enum.KeyCode.Right }
function anyDown(list)
	for _, k in ipairs(list) do if UserInputService:IsKeyDown(k) then return true end end
	return false
end
function horiz(v)
	local x, z = v.X, v.Z
	local m = math.sqrt(x * x + z * z)
	if m < 0.0001 then return nil end
	return Vector3.new(x / m, 0, z / m)
end
function padWorld()
	if not PadActive then return nil end
	local look, right = horiz(Cam.CFrame.LookVector), horiz(Cam.CFrame.RightVector)
	if not look then return nil end
	local v = look * PadDir.y
	if right then v = v + right * PadDir.x end
	if v.Magnitude < 0.01 then return nil end
	return horiz(v)
end
function keyDir()
	local pd = padWorld()
	if pd then return pd end
	local look, right = horiz(Cam.CFrame.LookVector), horiz(Cam.CFrame.RightVector)
	if not look then return nil end
	local d = Vector3.zero
	if anyDown(KEY_FWD)  then d = d + look end
	if anyDown(KEY_BACK) then d = d - look end
	if right then
		if anyDown(KEY_RIGHT) then d = d + right end
		if anyDown(KEY_LEFT)  then d = d - right end
	end
	if d.Magnitude < 0.05 then return nil end
	return horiz(d)
end
function moveDir()
	local pd = padWorld()
	if pd then return pd end
	if Humanoid and Humanoid.Parent then
		local md = Humanoid.MoveDirection
		if md.Magnitude > 0.05 then return horiz(md) end
	end
	return keyDir()
end
NoclipCache = {}
function setNoclip(on)
	local c = LP.Character
	if not on then
		for part, orig in pairs(NoclipCache) do
			if part and part.Parent then
				pcall(function() part.CanCollide = orig end)
			end
		end
		NoclipCache = {}
		return
	end
	if not c then return end
	for _, part in ipairs(c:GetDescendants()) do
		if part:IsA("BasePart") then
			if NoclipCache[part] == nil then NoclipCache[part] = part.CanCollide end
			part.CanCollide = false
		end
	end
end
RunService.Stepped:Connect(function()
	if not State.Noclip then return end
	local c = LP.Character
	if not c then return end
	for _, part in ipairs(c:GetDescendants()) do
		if part:IsA("BasePart") and part.CanCollide then
			if NoclipCache[part] == nil then NoclipCache[part] = true end
			part.CanCollide = false
		end
	end
end)
pcall(function() RunService:UnbindFromRenderStep("HonPadMove") end)
RunService:BindToRenderStep("HonPadMove", 10000, function()
	if not PadActive then return end
	if State.Fly then return end
	if not (Humanoid and Humanoid.Parent and Humanoid.Health > 0) then return end
	local d = padWorld()
	if d then
		Humanoid:Move(d, false)
	end
end)
FlyAtt, FlyVel, FlyOrient = nil, nil, nil
function buildFlyParts()
	if not HRP or not HRP.Parent then return end
	if FlyAtt and FlyAtt.Parent then return end
	FlyAtt = Instance.new("Attachment")
	FlyAtt.Name = "HonFlyAtt"
	FlyAtt.Parent = HRP
	FlyVel = Instance.new("LinearVelocity")
	FlyVel.Attachment0 = FlyAtt
	FlyVel.MaxForce = 1e9
	FlyVel.RelativeTo = Enum.ActuatorRelativeTo.World
	FlyVel.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
	FlyVel.VectorVelocity = Vector3.zero
	FlyVel.Parent = HRP
	FlyOrient = Instance.new("AlignOrientation")
	FlyOrient.Attachment0 = FlyAtt
	FlyOrient.Mode = Enum.OrientationAlignmentMode.OneAttachment
	FlyOrient.RigidityEnabled = true
	FlyOrient.Parent = HRP
end
function destroyFlyParts()
	if FlyAtt then pcall(function() FlyAtt:Destroy() end) end
	FlyAtt, FlyVel, FlyOrient = nil, nil, nil
end
function setFly(on)
	State.Fly = on
	if not on then
		FlyHoldY = nil
		destroyFlyParts()
		if Humanoid and Humanoid.Parent then
			Humanoid.PlatformStand = false
		end
		if HRP and HRP.Parent then
			HRP.AssemblyLinearVelocity = Vector3.zero
		end
		FlyUp, FlyDown = false, false
		return
	end
	buildFlyParts()
	if Humanoid and Humanoid.Parent then Humanoid.PlatformStand = true end
	FlyHoldY = (HRP and HRP.Parent) and HRP.Position.Y or nil
end
function setFlyWindow(on)
	FlyWin.Visible = on
	UpBtn.Visible = on
	DownBtn.Visible = on
	if not on then FlyToggle.Set(false, true) end
end
EspFolder = new("Folder", { Name = "HonEsp", Parent = Gui })
EspItems = {}
ESP_COLOR = {
	Player   = Color3.fromRGB(255, 86, 96),
	NPC      = Color3.fromRGB(255, 186, 74),
	Interact = Color3.fromRGB(92, 226, 255),
}
ESP_NAME_COLOR = Color3.fromRGB(255, 70, 80)
ESP_DIST_COLOR = Color3.fromRGB(255, 214, 74)
ESP_HP_FULL    = Color3.fromRGB(96, 232, 128)
ESP_HP_HALF    = Color3.fromRGB(255, 168, 62)
ESP_HP_LOW     = Color3.fromRGB(255, 70, 70)
function hpColor(ratio)
	if ratio > 2 / 3 then return ESP_HP_FULL end
	if ratio > 1 / 3 then return ESP_HP_HALF end
	return ESP_HP_LOW
end
function rgbTag(c, s)
	return string.format('<font color="rgb(%d,%d,%d)">%s</font>',
		math.floor(c.R * 255), math.floor(c.G * 255), math.floor(c.B * 255), s)
end
function esc(s)
	s = tostring(s or "")
	s = s:gsub("&", "&amp;")
	s = s:gsub("<", "&lt;")
	s = s:gsub(">", "&gt;")
	return s
end
function removeEsp(target)
	local e = EspItems[target]
	if not e then return end
	if e.HL and e.HL.Parent then e.HL:Destroy() end
	if e.BB and e.BB.Parent then e.BB:Destroy() end
	EspItems[target] = nil
end
function clearEsp(cat)
	for target, e in pairs(EspItems) do
		if not cat or e.Cat == cat then removeEsp(target) end
	end
end
function refreshEspDepth()
	for _, e in pairs(EspItems) do
		if e.HL and e.HL.Parent then
			e.HL.DepthMode = State.EspDepth and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
		end
		if e.BB and e.BB.Parent then e.BB.AlwaysOnTop = State.EspDepth end
	end
end
function addEsp(target, cat, adornee, name)
	if EspItems[target] then return end
	if not target or not target.Parent then return end
	local col = ESP_COLOR[cat] or Color3.new(1, 1, 1)
	local hl = Instance.new("Highlight")
	hl.Name = "HonEspHL"
	hl.FillColor = col
	hl.FillTransparency = 0.75
	hl.OutlineColor = col
	hl.OutlineTransparency = 0
	hl.DepthMode = State.EspDepth and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
	hl.Adornee = adornee
	hl.Parent = adornee
	local bb = Instance.new("BillboardGui")
	bb.Name = "HonEspTag"
	bb.Adornee = adornee
	bb.Size = UDim2.new(0, 180, 0, 42)
	bb.StudsOffset = Vector3.new(0, 3, 0)
	bb.AlwaysOnTop = State.EspDepth
	bb.MaxDistance = 600
	bb.Parent = EspFolder
	local txt = Instance.new("TextLabel")
	txt.Size = UDim2.new(1, 0, 1, 0)
	txt.BackgroundTransparency = 1
	txt.Font = Enum.Font.GothamBold
	txt.TextSize = 13
	txt.TextColor3 = col
	txt.TextStrokeTransparency = 0.4
	txt.RichText = true
	txt.Text = esc(name or cat)
	txt.Parent = bb
	EspItems[target] = { Cat = cat, HL = hl, BB = bb, Label = txt, Name = esc(name or cat) }
end
espTimer, espScan = 0, 0
function isPlayerChar(model)
	return Players:GetPlayerFromCharacter(model) ~= nil
end
function updateEsp(dt)
	espTimer = espTimer + dt
	espScan = espScan + dt
	for target, e in pairs(EspItems) do
		if not target.Parent or (e.HL and not e.HL.Parent) then removeEsp(target) end
	end
	if espScan > 0.8 then
		espScan = 0
		if State.InstantInteract then applyInstantInteract(true) end
		if State.EspPlayer then
			for _, plr in ipairs(Players:GetPlayers()) do
				if plr ~= LP and plr.Character then
					addEsp(plr.Character, "Player", plr.Character, plr.DisplayName or plr.Name)
				end
			end
		end
		if State.EspNPC or State.EspInteract then
			for _, obj in ipairs(Workspace:GetDescendants()) do
				if State.EspNPC and obj:IsA("Model") and obj ~= LP.Character and not isPlayerChar(obj) then
					if obj:FindFirstChildOfClass("Humanoid") and obj:FindFirstChild("HumanoidRootPart") then
						addEsp(obj, "NPC", obj, obj.Name)
					end
				elseif State.EspInteract and (obj:IsA("ProximityPrompt") or obj:IsA("ClickDetector")) then
					local host = obj:FindFirstAncestorOfClass("Part") or obj:FindFirstAncestorOfClass("Model")
					if host then addEsp(obj, "Interact", host, obj.Name or "INTERACT") end
				end
			end
		end
	end
	if espTimer > 0.25 and HRP and HRP.Parent then
		espTimer = 0
		for target, e in pairs(EspItems) do
			local anchor = e.HL and e.HL.Adornee
			if anchor and anchor.Parent then
				local pos = anchor:IsA("Model") and anchor:GetPivot().Position or anchor.Position
				local dist = math.floor((pos - HRP.Position).Magnitude)
				local hpPart = ""
				if e.Cat == "Player" or e.Cat == "NPC" then
					local hum = anchor:FindFirstChildOfClass("Humanoid")
					if hum then
						local maxHp = hum.MaxHealth > 0 and hum.MaxHealth or 100
						local ratio = math.clamp(hum.Health / maxHp, 0, 1)
						local hc = hpColor(ratio)
						hpPart = "  " .. rgbTag(hc, string.format("HP %d", math.floor(hum.Health)))
						if e.HL and e.HL.Parent then
							e.HL.OutlineColor = hc
							e.HL.FillColor = hc
						end
					end
				end
				e.Label.Text = rgbTag(ESP_NAME_COLOR, e.Name) .. "  " ..
					rgbTag(ESP_DIST_COLOR, tostring(dist) .. " m") .. hpPart
			end
		end
	end
end
PromptCache = {}
function applyInstantInteract(on)
	if not on then
		for pr, orig in pairs(PromptCache) do
			if pr and pr.Parent then
				pcall(function()
					pr.HoldDuration = orig[1]
					pr.MaxActivationDistance = orig[2]
					pr.RequiresLineOfSight = orig[3]
				end)
			end
		end
		PromptCache = {}
		return
	end
	for _, pr in ipairs(Workspace:GetDescendants()) do
		if pr:IsA("ProximityPrompt") then
			if not PromptCache[pr] then
				PromptCache[pr] = { pr.HoldDuration, pr.MaxActivationDistance, pr.RequiresLineOfSight }
			end
			pr.HoldDuration = 0
			if pr.MaxActivationDistance < 30 then pr.MaxActivationDistance = 30 end
			pr.RequiresLineOfSight = false
		end
	end
end
statTimer, statTarget, statNote = 0, 0, "地面"
function clearFX()
	if Highlight and Highlight.Parent then Highlight:Destroy() end
	if Emitter and Emitter.Parent then Emitter:Destroy() end
	Highlight, Emitter = nil, nil
end
function buildFX(char, hrp)
	if not char or not hrp then return end
	Highlight = Instance.new("Highlight")
	Highlight.Name = "HonSpeedHL"
	Highlight.FillTransparency = 1
	Highlight.OutlineTransparency = 0.4
	Highlight.OutlineColor = Mode().Accent
	Highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	Highlight.Parent = char
	Emitter = Instance.new("ParticleEmitter")
	Emitter.Name = "HonSpeedFX"
	Emitter.Lifetime = NumberRange.new(0.32)
	Emitter.Rate = 0
	Emitter.Speed = NumberRange.new(0.4, 1.8)
	Emitter.VelocityInheritance = 0
	Emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0) })
	Emitter.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1) })
	Emitter.LightEmission = 1
	Emitter.LightInfluence = 0
	Emitter.Drag = 9
	Emitter.Rotation = NumberRange.new(0, 360)
	Emitter.Parent = hrp
end
bindToken, lastBound = 0, nil
function bindCharacter(char)
	if not char or not char.Parent then return end
	local pre = char:FindFirstChildOfClass("Humanoid")
	if pre and pre.Health <= 0 then return end
	if char == lastBound and refsValid() then return end
	lastBound = char
	bindToken = bindToken + 1
	if State.FakeChar then
		cleanupFake()
		State.FakeChar = false
		if FakeTgl then FakeTgl.Set(false, true) end
	end
	Character = char
	Humanoid = char:FindFirstChildOfClass("Humanoid")
	HRP = char:FindFirstChild("HumanoidRootPart")
	NoclipCache = {}
	lastTransp = -1
	clearFX()
	buildFX(char, HRP)
	cur, CFAccum = 0, 0
	if State.Fly then buildFlyParts() end
	if Humanoid then
		Humanoid.Died:Connect(function()
			cur, CFAccum = 0, 0
			clearFX()
			destroyFlyParts()
			Character, Humanoid, HRP = nil, nil, nil
		end)
	end
end
refsValid = function()
	return Character and Character.Parent
		and Humanoid and Humanoid.Parent and Humanoid.Health > 0
		and HRP and HRP.Parent
end
LP.CharacterAdded:Connect(function(c) bindCharacter(c) end)
LP.CharacterAppearanceLoaded:Connect(function(c) bindCharacter(c) end)
if LP.Character then bindCharacter(LP.Character) end
function selfHeal()
	local c = LP.Character
	if not c or not c.Parent then return false end
	local h = c:FindFirstChildOfClass("Humanoid")
	if not h or h.Health <= 0 then return false end
	if c ~= Character then
		bindCharacter(c)
		return refsValid()
	end
	if not Humanoid or not Humanoid.Parent then Humanoid = c:FindFirstChildOfClass("Humanoid") end
	if not HRP or not HRP.Parent then HRP = c:FindFirstChild("HumanoidRootPart") end
	if HRP and (not Emitter or not Emitter.Parent) then buildFX(c, HRP) end
	return refsValid()
end
RayParams = RaycastParams.new()
RunService.Heartbeat:Connect(function(dt)
	if not Authed then return end
	updateEsp(dt)
	if not refsValid() then
		if not selfHeal() then
			if Emitter and Emitter.Parent then Emitter.Rate = 0 end
			if Highlight and Highlight.Parent then Highlight.Enabled = false end
			return
		end
	end
	local m = Mode()
	if State.JumpEnabled then
		Humanoid.UseJumpPower = true
		if Humanoid.JumpPower ~= State.JumpPower then Humanoid.JumpPower = State.JumpPower end
	end
	fpsAcc = fpsAcc + dt
	fpsFrames = fpsFrames + 1
	if fpsAcc >= 0.5 then
		fps = math.floor(fpsFrames / fpsAcc + 0.5)
		fpsAcc, fpsFrames = 0, 0
	end
	if State.Fullbright then
		if Lighting.Brightness ~= 2 then Lighting.Brightness = 2 end
		if Lighting.FogEnd < 1e8 then Lighting.FogEnd = 1e9 end
	end
	if State.AntiStun and not State.Fly then
		if Humanoid.PlatformStand then Humanoid.PlatformStand = false end
		if Humanoid.Sit then Humanoid.Sit = false end
	end
	if Humanoid.FloorMaterial ~= Enum.Material.Air then
		State.SafePos = HRP.Position + Vector3.new(0, 3, 0)
	elseif State.AntiVoid and not State.FakeChar and HRP.Position.Y < (Workspace.FallenPartsDestroyHeight + 20) then
		if State.SafePos then HRP.CFrame = CFrame.new(State.SafePos) end
	end
	if State.Spin and not HRP.Anchored then
		HRP.CFrame = HRP.CFrame * CFrame.Angles(0, math.rad(760) * dt, 0)
	end
	if State.Rainbow then
		rainbowTimer = rainbowTimer + dt
		if rainbowTimer > 0.06 then
			rainbowTimer = 0
			local hue = (tick() * 0.35) % 1
			local c = LP.Character
			if c then
				local i2 = 0
				for _, q in ipairs(c:GetDescendants()) do
					if q:IsA("BasePart") then
						i2 = i2 + 1
						q.Color = Color3.fromHSV((hue + i2 * 0.03) % 1, 1, 1)
					end
				end
			end
		end
	end
	if State.Bounce then
		local grounded = (Humanoid.FloorMaterial ~= Enum.Material.Air)
		if grounded and wasAirborne then
			local v2 = HRP.AssemblyLinearVelocity
			HRP.AssemblyLinearVelocity = Vector3.new(v2.X, 85, v2.Z)
		end
		wasAirborne = not grounded
	else
		wasAirborne = (Humanoid.FloorMaterial == Enum.Material.Air)
	end
	if State.Orbit then
		local p = getTargetPlayer(TPInput and TPInput.NAME and TPInput.NAME.Text or "")
		local thrp = p and p.Character and p.Character:FindFirstChild("HumanoidRootPart")
		if thrp then
			local a = tick() * 1.3
			HRP.CFrame = CFrame.new(thrp.Position + Vector3.new(math.cos(a) * 9, 0, math.sin(a) * 9))
		end
	end
	if State.Follow or State.Face then
		local p = getTargetPlayer(TPInput and TPInput.NAME and TPInput.NAME.Text or "")
		local thrp = p and p.Character and p.Character:FindFirstChild("HumanoidRootPart")
		if thrp then
			if State.Follow and (thrp.Position - HRP.Position).Magnitude > 6 then
				Humanoid:MoveTo(thrp.Position)
			end
			if State.Face then
				HRP.CFrame = CFrame.new(HRP.Position,
					Vector3.new(thrp.Position.X, HRP.Position.Y, thrp.Position.Z))
			end
		end
	end
	if State.Freeze and not HRP.Anchored then
		HRP.Anchored = true
		HRP.AssemblyLinearVelocity = Vector3.zero
	end
	if State.AutoJump and Humanoid.FloorMaterial ~= Enum.Material.Air and not State.Fly then
		Humanoid.Jump = true
	end
	if State.HidePlayers then
		hideTimer = hideTimer + dt
		if hideTimer > 0.4 then
			hideTimer = 0
			for _, pl in ipairs(Players:GetPlayers()) do
				if pl ~= LP and pl.Character then
					for _, q in ipairs(pl.Character:GetDescendants()) do
						if q:IsA("BasePart") and q.Transparency ~= 1 then
							q.Transparency = 1
							table.insert(HiddenParts, q)
						end
					end
				end
			end
		end
	end
	if State.AntiKB then
		local v = HRP.AssemblyLinearVelocity
		local m = math.sqrt(v.X * v.X + v.Z * v.Z)
		local cap = math.max(State.Speed * 1.8, 110)
		if m > cap then
			local s = cap / m
			HRP.AssemblyLinearVelocity = Vector3.new(v.X * s, v.Y, v.Z * s)
		end
	end
	if State.Freecam then
		Humanoid.WalkSpeed = 0
		if HRP.AssemblyLinearVelocity.Magnitude > 0.05 then
			HRP.AssemblyLinearVelocity = Vector3.zero
		end
		statTimer = statTimer + dt
		if statTimer > 0.12 then
			statTimer = 0
			Status.Text = string.format(
				'<font color="rgb(%d,%d,%d)"><b>FREECAM</b></font>  镜头自由移动 · 本体静止\n镜头坐标 %d / %d / %d',
				math.floor(m.Accent.R * 255), math.floor(m.Accent.G * 255), math.floor(m.Accent.B * 255),
				math.floor(Cam.CFrame.Position.X), math.floor(Cam.CFrame.Position.Y), math.floor(Cam.CFrame.Position.Z))
			HudText.Text = "FREECAM"
			HudSub.Text = string.format("%s · %d FPS", m.Tag, fps)
		end
		return
	end
	if State.TPLoop then
		local cf = tpTargetCF()
		if not cf then
			State.TPLoop = false
			if TPLoopTgl then TPLoopTgl.Set(false, true) end
			if notify then notify("目标已失效，循环传送已停止", Color3.fromRGB(255, 108, 118)) end
		else
			tpTimer = tpTimer + dt
			if tpTimer >= State.TPInterval then
				tpTimer = 0
				HRP.CFrame = cf + Vector3.new(0, State.TPOffsetY, 0)
			end
			statTimer = statTimer + dt
			if statTimer > 0.12 then
				statTimer = 0
				Status.Text = string.format('<font color="rgb(%d,%d,%d)"><b>LOOP TP</b></font>  锁定：%s',
					math.floor(m.Accent.R * 255), math.floor(m.Accent.G * 255), math.floor(m.Accent.B * 255),
					tostring(TPTarget and TPTarget.Name or "?"))
			end
			return
		end
	end
	if State.Fly then
		if Humanoid.PlatformStand ~= true then Humanoid.PlatformStand = true end
		if not FlyAtt or not FlyAtt.Parent then buildFlyParts() end
		local dir = keyDir()
		local v = Vector3.zero
		if dir then v = dir * State.FlySpeed end
		local vert = 0
		if FlyUp then vert = vert + 1 end
		if FlyDown then vert = vert - 1 end
		if UserInputService:IsKeyDown(Enum.KeyCode.E) then vert = vert + 1 end
		if UserInputService:IsKeyDown(Enum.KeyCode.Q) then vert = vert - 1 end
		if vert ~= 0 then
			FlyHoldY = HRP.Position.Y
			v = v + Vector3.new(0, vert * State.FlySpeed, 0)
		else
			if not FlyHoldY then FlyHoldY = HRP.Position.Y end
			local dy = FlyHoldY - HRP.Position.Y
			v = v + Vector3.new(0, math.clamp(dy * 8, -State.FlySpeed, State.FlySpeed), 0)
		end
		if FlyVel then FlyVel.VectorVelocity = v end
		if FlyOrient then FlyOrient.CFrame = Cam.CFrame end
		if Highlight and Highlight.Parent then
			Highlight.Enabled = true
			Highlight.OutlineColor = m.Accent
			Highlight.OutlineTransparency = 0.35
		end
		if Emitter and Emitter.Parent then
			Emitter.Color = ColorSequence.new(m.Accent)
			Emitter.Rate = 90
		end
		statTarget, statNote = State.FlySpeed, "飞行中"
		statTimer = statTimer + dt
		if statTimer > 0.12 then
			statTimer = 0
			Status.Text = string.format('<font color="rgb(%d,%d,%d)"><b>FLY</b></font>  %s\n高度 %d  ·  FLY %d sp',
				math.floor(m.Accent.R * 255), math.floor(m.Accent.G * 255), math.floor(m.Accent.B * 255),
				"飞行中", math.floor(HRP.Position.Y), State.FlySpeed)
			HudText.Text = string.format("%d sp FLY", State.FlySpeed)
			HudSub.Text = "FLY"
		end
		return
	end
	if not State.Enabled or Humanoid.Sit then
		cur = DEFAULT_WALK + (cur - DEFAULT_WALK) * math.exp(-dt * 9)
		Humanoid.WalkSpeed = DEFAULT_WALK
		Cam.FieldOfView = Cam.FieldOfView + (BASE_FOV - Cam.FieldOfView) * (1 - math.exp(-dt * 5))
		if Emitter and Emitter.Parent then Emitter.Rate = 0 end
		if Highlight and Highlight.Parent then Highlight.Enabled = false end
		statTarget, statNote = DEFAULT_WALK, "已关闭"
		statTimer = statTimer + dt
		if statTimer > 0.12 then statTimer = 0; HudText.Text = "0 stud/s"; HudSub.Text = "OFF" end
		return
	end
	local dir = moveDir()
	RayParams.FilterDescendantsInstances = { Character }
	local target = State.Speed
	cur = target + (cur - target) * math.exp(-dt * State.Smooth)
	if math.abs(cur - target) < 0.4 then cur = target end
	statTarget = cur
	if m.Id == "W" then
		Humanoid.WalkSpeed = cur
		statNote = dir and "行进中" or "待机"
	elseif m.Id == "V" then
		Humanoid.WalkSpeed = 0
		if not HRP.Anchored then
			local v = HRP.AssemblyLinearVelocity
			if dir then
				HRP.AssemblyLinearVelocity = Vector3.new(dir.X * cur, v.Y, dir.Z * cur)
			else
				local decay = State.Inertia and math.exp(-dt * 1.6) or 0
				HRP.AssemblyLinearVelocity = Vector3.new(v.X * decay, v.Y, v.Z * decay)
			end
			statNote = dir and "惯性冲刺" or (State.Inertia and "滑行中" or "已刹停")
		else
			statNote = "锚定中"
		end
	elseif m.Id == "CF" then
		Humanoid.WalkSpeed = 0
		if not HRP.Anchored and dir then
			if State.CFTeleport then
				CFAccum = CFAccum + cur * dt
				local threshold = math.clamp(cur * 0.12, 4, 30)
				if CFAccum >= threshold then
					local dist = CFAccum
					CFAccum = 0
					local move = dir * dist
					if State.WallSlide then
						local hit = Workspace:Raycast(HRP.Position, dir * (dist + 2.4), RayParams)
						if hit then
							local n = hit.Normal
							local slide = dir - n * dir:Dot(n)
							if slide.Magnitude > 0.08 then
								local sd = horiz(slide)
								if sd and not Workspace:Raycast(HRP.Position, sd * (dist + 2.4), RayParams) then
									move = sd * dist
									statNote = "沿墙闪现"
								else
									move = nil; statNote = "受阻"
								end
							else
								move = nil; statNote = "受阻"
							end
						else
							statNote = "瞬移闪现"
						end
					else
						statNote = "瞬移闪现"
					end
					if move then
						HRP.CFrame = (HRP.CFrame - HRP.CFrame.Position) + (HRP.Position + move)
						if Emitter and Emitter.Parent then Emitter:Emit(16) end
					end
				else
					statNote = "蓄力中"
				end
			else
				local step = cur * dt
				local move = dir * step
				if State.WallSlide then
					local hit = Workspace:Raycast(HRP.Position, dir * (step + 2.4), RayParams)
					if hit then
						local n = hit.Normal
						local slide = dir - n * dir:Dot(n)
						if slide.Magnitude > 0.08 then
							local sd = horiz(slide)
							if sd and not Workspace:Raycast(HRP.Position, sd * (step + 2.4), RayParams) then
								move = sd * step
								statNote = "沿墙滑动"
							else
								move = nil; statNote = "受阻"
							end
						else
							move = nil; statNote = "受阻"
						end
					else
						statNote = "平滑推进"
					end
				else
					statNote = "自由位移"
				end
				if move then
					HRP.CFrame = (HRP.CFrame - HRP.CFrame.Position) + (HRP.Position + move)
				end
			end
		else
			statNote = dir and "锚定中" or "待机"
		end
	end
	local ratio = math.clamp((cur - DEFAULT_WALK) / math.max(State.Speed - DEFAULT_WALK, 1), 0, 1)
	local fovGoal = (State.FovValue > 0) and State.FovValue or (BASE_FOV + ratio * m.FovBoost)
	Cam.FieldOfView = Cam.FieldOfView + (fovGoal - Cam.FieldOfView) * (1 - math.exp(-dt * 5))
	if Highlight and Highlight.Parent then
		Highlight.Enabled = true
		Highlight.OutlineColor = m.Accent
		Highlight.OutlineTransparency = 0.5 - ratio * 0.22
	end
	if Emitter and Emitter.Parent then
		Emitter.Color = ColorSequence.new(m.Accent)
		Emitter.Rate = (m.Id == "CF" and ratio * 190) or (m.Id == "V" and ratio * 130) or (ratio * 45)
	end
	statTimer = statTimer + dt
	if statTimer > 0.12 then
		statTimer = 0
		local lockTag = State.SpeedLocked and "  ·  <b>LOCKED</b>" or ""
		local tpTag = (m.Id == "CF" and State.CFTeleport) and "  ·  TP" or ""
		Status.Text = string.format(
			'<font color="rgb(%d,%d,%d)"><b>%s</b></font>  %s%s%s\n目标 %d  ·  实际 %d stud/s  ·  FOV %d',
			math.floor(m.Accent.R * 255), math.floor(m.Accent.G * 255), math.floor(m.Accent.B * 255),
			m.Tag, statNote, lockTag, tpTag, math.floor(statTarget), math.floor(cur), math.floor(Cam.FieldOfView))
		HudText.Text = State.CoordHud and string.format("%d / %d / %d", math.floor(HRP.Position.X), math.floor(HRP.Position.Y), math.floor(HRP.Position.Z)) or string.format("%d stud/s", math.floor(cur))
		local pingMs = 0
		pcall(function()
			local p = LP:GetNetworkPing()
			pingMs = (p < 1) and math.floor(p * 1000) or math.floor(p)
		end)
		HudSub.Text = string.format("%s · %d FPS · %dms", m.Tag, fps, pingMs)
	end
end)
UserInputService.JumpRequest:Connect(function()
	if not State.InfJump then return end
	if Humanoid and Humanoid.Parent and Humanoid.Health > 0 then
		Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
	end
end)
LP.Idled:Connect(function()
	if not State.AntiAFK then return end
	pcall(function()
		VirtualUser:CaptureController()
		VirtualUser:ClickButton2(Vector2.new())
	end)
end)
UserInputService.InputBegan:Connect(function(input, processed)
	if processed or not Authed then return end
	local k = input.KeyCode
	if k == Enum.KeyCode.RightControl then
		if State.Stealth then setStealth(false); return end
		if Main.Visible or Mini.Visible then Main.Visible, Mini.Visible = false, false else Main.Visible = true end
	elseif k == Enum.KeyCode.F2 then
		PowerToggle.Set(not State.Enabled)
	elseif k == Enum.KeyCode.L then
		applyPanelLock(not State.PanelLocked)
	elseif k == Enum.KeyCode.M then
		SetMode((State.ModeIndex % #Modes) + 1)
	end
end)
NotifyHost = new("Frame", { Name = "HonNotify", Size = UDim2.new(0, 250, 0, 400),
	Position = UDim2.new(1, -266, 0, 60), BackgroundTransparency = 1, Parent = Gui })
NotifyLayout = new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = NotifyHost })
function notify(msg, col)
	if not msg then return end
	local t = new("Frame", { Size = UDim2.new(1, 0, 0, 42), LayoutOrder = tick(),
		BackgroundColor3 = Color3.fromRGB(16, 19, 28), BackgroundTransparency = 0.08,
		BorderSizePixel = 0, Parent = NotifyHost })
	corner(t, 10)
	new("UIStroke", { Color = col or Mode().Accent, Transparency = 0.45, Thickness = 1, Parent = t })
	new("Frame", { Size = UDim2.new(0, 3, 1, -16), Position = UDim2.new(0, 0, 0, 8),
		BackgroundColor3 = col or Mode().Accent, BorderSizePixel = 0, Parent = t })
	label({ Text = tostring(msg), Font = Enum.Font.GothamBold, TextSize = 11,
		TextColor3 = Color3.fromRGB(226, 233, 248), Position = UDim2.new(0, 14, 0, 0),
		Size = UDim2.new(1, -22, 1, 0), TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center, TextWrapped = true }, t)
	tspawn(function()
		twait(2.4)
		if t and t.Parent then
			TweenService:Create(t, TweenInfo.new(0.3), { BackgroundTransparency = 1 }):Play()
			twait(0.32)
			if t.Parent then t:Destroy() end
		end
	end)
end
SearchItems = {}
function buildSearchIndex()
	SearchItems = {}
	for _, t in ipairs(AllToggles) do
		if t.Row and t.Title then table.insert(SearchItems, { Obj = t.Row, Text = t.Title.Text }) end
	end
	for _, sl in ipairs(AllSliders) do
		if sl.Row then table.insert(SearchItems, { Obj = sl.Row, Text = sl.TitleText or "" }) end
	end
	for _, list in ipairs({ ToolBtns, FunBtns, MoreBtns, UtilBtns, UiBtns }) do
		for _, b in ipairs(list) do table.insert(SearchItems, { Obj = b, Text = b.Text }) end
	end
end
function applySearch(q)
	q = tostring(q or ""):lower()
	for _, it in ipairs(SearchItems) do
		if q == "" then
			it.Obj.Visible = true
		else
			it.Obj.Visible = (tostring(it.Text or ""):lower():find(q, 1, true) ~= nil)
		end
	end
end
if SearchBox then
	SearchBox:GetPropertyChangedSignal("Text"):Connect(function() applySearch(SearchBox.Text) end)
end
StealthBall, StealthBallText = nil, nil
StealthOwn, StealthHiddenGui = {}, {}
stealthTime, stealthAcc = 0, 0
function buildStealthBall()
	if StealthBall then return end
	local b = new("TextButton", { Name = "HonStealth", Text = "",
		Size = UDim2.new(0, 108, 0, 38), Position = UDim2.new(1, -124, 0, 14),
		BackgroundColor3 = Color3.fromRGB(12, 14, 20), BackgroundTransparency = 0.22,
		BorderSizePixel = 0, AutoButtonColor = false, Active = true, Visible = false, Parent = Gui })
	corner(b, 19)
	new("UIStroke", { Color = Color3.fromRGB(255, 86, 96), Transparency = 0.35, Thickness = 1, Parent = b })
	local dot = new("Frame", { Size = UDim2.new(0, 10, 0, 10), Position = UDim2.new(0, 13, 0.5, -5),
		BackgroundColor3 = Color3.fromRGB(255, 86, 96), BorderSizePixel = 0, Parent = b })
	corner(dot, 5)
	StealthBallText = label({ Text = "REC 00:00", Font = Enum.Font.GothamBold, TextSize = 11,
		TextColor3 = Color3.fromRGB(238, 243, 255), Position = UDim2.new(0, 30, 0, 0),
		Size = UDim2.new(1, -36, 1, 0), TextXAlignment = Enum.TextXAlignment.Left }, b)
	StealthBall = b
	local dragging, startMouse, basePos, moved = false, nil, nil, 0
	b.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging, startMouse, basePos, moved = true, i.Position, b.Position, 0
		end
	end)
	UserInputService.InputChanged:Connect(function(i)
		if dragging and (i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseMovement) then
			local d = i.Position - startMouse
			moved = math.max(moved, math.abs(d.X) + math.abs(d.Y))
			b.Position = UDim2.new(basePos.X.Scale, basePos.X.Offset + d.X, basePos.Y.Scale, basePos.Y.Offset + d.Y)
		end
	end)
	UserInputService.InputEnded:Connect(function(i)
		if dragging and (i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1) then
			dragging = false
			if moved < 6 then setStealth(not State.Stealth) end
		end
	end)
end
function stealthHideOwn()
	StealthOwn = {}
	for _, c in ipairs(Gui:GetChildren()) do
		if c:IsA("GuiObject") and c.Name ~= "HonStealth" then
			StealthOwn[c] = c.Visible
			c.Visible = false
		end
	end
end
function stealthShowOwn()
	for c, v in pairs(StealthOwn) do
		if c and c.Parent then c.Visible = v end
	end
	StealthOwn = {}
end
function stealthHideGame()
	StealthHiddenGui = {}
	for _, g in ipairs(PG:GetChildren()) do
		if g:IsA("ScreenGui") and g ~= Gui and g.Enabled then
			g.Enabled = false
			table.insert(StealthHiddenGui, g)
		end
	end
	pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false) end)
	pcall(function() StarterGui:SetCore("TopbarEnabled", false) end)
end
function stealthShowGame()
	for _, g in ipairs(StealthHiddenGui) do
		if g and g.Parent then g.Enabled = true end
	end
	StealthHiddenGui = {}
	pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true) end)
	pcall(function() StarterGui:SetCore("TopbarEnabled", true) end)
end
function setStealth(on)
	State.Stealth = on
	buildStealthBall()
	if on then
		stealthHideOwn()
		if State.StealthHideGame then stealthHideGame() end
		if StealthBall then StealthBall.Visible = true end
		stealthTime, stealthAcc = 0, 0
		if notify then notify("隐身录屏开启 · 后台功能照常运行") end
	else
		stealthShowOwn()
		if State.StealthHideGame then stealthShowGame() end
		if StealthBall then StealthBall.Visible = false end
		if notify then notify("已恢复全部界面") end
	end
	if StealthTgl then StealthTgl.Set(on, true) end
end
RunService.Heartbeat:Connect(function(dt)
	if not State.Stealth then stealthAcc = 0; return end
	stealthTime = stealthTime + dt
	stealthAcc = stealthAcc + dt
	if stealthAcc >= 0.5 then
		stealthAcc = 0
		if StealthBallText then
			StealthBallText.Text = string.format("REC %02d:%02d",
				math.floor(stealthTime / 60), math.floor(stealthTime % 60))
		end
	end
end)
if KEY_SYSTEM and not Authed then
	local KeyWin = new("Frame", {
		Name = "HonKeyWin", Size = UDim2.new(0, 300, 0, 236),
		Position = UDim2.new(0.5, -150, 0.5, -118),
		BackgroundColor3 = Color3.fromRGB(13, 15, 23), BackgroundTransparency = 0.04,
		BorderSizePixel = 0, Active = true, Parent = Gui,
	})
	corner(KeyWin, 18)
	local ks = new("UIStroke", { Color = Modes[1].Accent, Transparency = 0.45, Thickness = 1, Parent = KeyWin })
	new("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.05), NumberSequenceKeypoint.new(1, 1) }), Parent = KeyWin })
	label({ Text = "HON SPEED HUB", Font = Enum.Font.GothamBold, TextSize = 20,
		TextColor3 = Color3.fromRGB(238, 243, 255), Position = UDim2.new(0, 0, 0, 26),
		Size = UDim2.new(1, 0, 0, 24), TextXAlignment = Enum.TextXAlignment.Center }, KeyWin)
	label({ Text = "请输入卡密以启用", Font = Enum.Font.Gotham, TextSize = 11,
		TextColor3 = Color3.fromRGB(140, 149, 172), Position = UDim2.new(0, 0, 0, 54),
		Size = UDim2.new(1, 0, 0, 16), TextXAlignment = Enum.TextXAlignment.Center }, KeyWin)
	local KeyBox = new("TextBox", { PlaceholderText = "卡密", Text = "",
		Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = Color3.fromRGB(238, 243, 255),
		PlaceholderColor3 = Color3.fromRGB(105, 113, 134),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.92,
		BorderSizePixel = 0, ClearTextOnFocus = false,
		Position = UDim2.new(0, 30, 0, 84), Size = UDim2.new(1, -60, 0, 40), Parent = KeyWin })
	corner(KeyBox, 10)
	local OkBtn = new("TextButton", { Text = "验 证", Font = Enum.Font.GothamBold, TextSize = 13,
		TextColor3 = Color3.fromRGB(255, 255, 255), BackgroundColor3 = Modes[1].Accent,
		BorderSizePixel = 0, AutoButtonColor = false,
		Position = UDim2.new(0, 30, 0, 136), Size = UDim2.new(1, -60, 0, 40), Parent = KeyWin })
	corner(OkBtn, 10)
	local KeyTip = label({ Text = "", Font = Enum.Font.Gotham, TextSize = 10,
		TextColor3 = Color3.fromRGB(255, 108, 118), Position = UDim2.new(0, 0, 0, 186),
		Size = UDim2.new(1, 0, 0, 16), TextXAlignment = Enum.TextXAlignment.Center }, KeyWin)
	local function tryKey()
		local k = tostring(KeyBox.Text or ""):gsub("^%s+", ""):gsub("%s+$", "")
		if k == "" then KeyTip.Text = "请输入卡密"; return end
		if k == MASTER_KEY or VALID_KEYS[k] then
			Authed = true
			if KEY_REMEMBER then
				pcall(function() TeleportService:SetTeleportSetting("HON_KEY_OK", true) end)
			end
			KeyTip.TextColor3 = Color3.fromRGB(120, 230, 150)
			KeyTip.Text = "验证成功，正在载入…"
			if notify then notify("卡密验证通过，欢迎使用 HON SPEED HUB", Color3.fromRGB(120, 230, 150)) end
			twait(0.35)
			KeyWin:Destroy()
			Main.Visible = true
			TweenService:Create(Main, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				Size = UDim2.new(0, PANEL_W, 0, PANEL_H) }):Play()
		else
			KeyTip.Text = "卡密无效"
			TweenService:Create(KeyBox, TweenInfo.new(0.1), { Position = UDim2.new(0, 22, 0, 84) }):Play()
			twait(0.1)
			TweenService:Create(KeyBox, TweenInfo.new(0.1), { Position = UDim2.new(0, 38, 0, 84) }):Play()
			twait(0.1)
			TweenService:Create(KeyBox, TweenInfo.new(0.1), { Position = UDim2.new(0, 30, 0, 84) }):Play()
		end
	end
	OkBtn.MouseButton1Click:Connect(tryKey)
	KeyBox.FocusLost:Connect(function(enter) if enter then tryKey() end end)
	local ClearBtn = new("TextButton", { Text = "清除本机记录", Font = Enum.Font.Gotham, TextSize = 10,
		TextColor3 = Color3.fromRGB(120, 129, 152), BackgroundTransparency = 1,
		BorderSizePixel = 0, AutoButtonColor = false,
		Position = UDim2.new(0, 0, 0, 212), Size = UDim2.new(1, 0, 0, 18), Parent = KeyWin })
	ClearBtn.MouseButton1Click:Connect(function()
		pcall(function() TeleportService:SetTeleportSetting("HON_KEY_OK", false) end)
		KeyTip.TextColor3 = Color3.fromRGB(140, 149, 172)
		KeyTip.Text = "已清除，下次需要重新输入"
	end)
	Main.Visible = false
	Mini.Visible = false
end
buildSearchIndex()
tspawn(uiRestore)
SpeedSlider.SetLocked(false)
JumpSlider.SetLocked(false)
SetTab(1)
SetMode(1)
applyPanelLock(false)
updateTouchVisibility()
FlyWin.Visible = false
UpBtn.Visible, DownBtn.Visible = false, false
Main.Size = UDim2.new(0, 300, 0, 560)
Main.BackgroundTransparency = 1
TweenService:Create(Main, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
	Size = UDim2.new(0, PANEL_W, 0, PANEL_H), BackgroundTransparency = 0.05 }):Play()
TweenService:Create(Main, TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
	Position = UDim2.new(0.5, -PANEL_W / 2, 0.5, -PANEL_H / 2) }):Play()
print("[HON SPEED HUB] v5.4 已加载 · 完整文件约 2856 行 · 若你的脚本远大于此行数说明粘贴重复了")
