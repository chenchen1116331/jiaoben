local KEY_SYSTEM  = false
local KEY_REMEMBER = false
local MASTER_KEY  = "chenchen1116"
local VALID_KEYS  = {
	["chenchen1116"] = true,
}
print("[HON SPEED HUB] 载入中 · v5.20 · 若只看到这一行说明文件在中途中断")
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
ToggleRegistry = {}
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
	Dance = false, Halo = false, Follow = false, Face = false, FovValue = 0, WatchTarget = nil,
	Freeze = false, HidePlayers = false, HideUI = false, AutoJump = false, CoordHud = false,
	TPLoop = false, TPInterval = 0, TPOffsetY = 3,
	MoveGameUI = false, UILayoutLocked = false,
	Stealth = false, StealthHideGame = true,
	BlackHole = false, BlackHoleForce = 60, HeroFly = false, Car = false,
	EngineOutline = true, Trail = false, CloneArmy = false, OrbitFx = false, HideBlock = false,
	HeadRide = false, Shake = false, SpinCam = false, Magnet = false,
	ThirdPerson = false, NoFall = false, ShowHP = false, ShowFunList = false,
	AntiKB = false, AntiStun = false, Freecam = false,
	SafePos = nil,
}
function bindClick(btn, tag, fn)
	if not btn then return end
	local last = 0
	local function fire()
		local now = tick()
		if now - last < 0.28 then return end
		last = now
		local ok, err = pcall(fn)
		if not ok then warn("[HON] 点击[" .. tostring(tag) .. "]出错: " .. tostring(err)) end
	end
	pcall(function() btn.MouseButton1Click:Connect(fire) end)
	pcall(function() btn.Activated:Connect(fire) end)
	pcall(function() btn.TouchTap:Connect(fire) end)
	pcall(function()
		btn.InputBegan:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then fire() end
		end)
	end)
end

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
	ZIndexBehavior = Enum.ZIndexBehavior.Global, DisplayOrder = 2147483647, Parent = PG,
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
label({ Text = "Universal Hub  ·  W / V / CF  ·  v5.20", Font = Enum.Font.Gotham, TextSize = 11,
	TextColor3 = Color3.fromRGB(140, 149, 172),
	Position = UDim2.new(0, 36, 0, 42), Size = UDim2.new(0, 240, 0, 16),
	TextXAlignment = Enum.TextXAlignment.Left }, Header)
InfoLabel = label({ Text = "", Font = Enum.Font.Gotham, TextSize = 9,
	TextColor3 = Color3.fromRGB(105, 113, 134), Position = UDim2.new(0, 20, 0, 54),
	Size = UDim2.new(1, -120, 0, 14), TextXAlignment = Enum.TextXAlignment.Left,
	TextTruncate = Enum.TextTruncate.AtEnd, BackgroundTransparency = 1 }, Header)
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
iconBtn("!", -136, Mode().Accent, function() showNotice() end)
iconBtn("–", -68, Color3.fromRGB(190, 198, 220), function() playCloseAnim(function() Mini.Visible = true end) end)
iconBtn("×", -34, Color3.fromRGB(255, 108, 118), function() playCloseAnim() end)
-- ---------- 更新公告 ----------
CHANGELOG = {
	{ v = "v5.20", t = {
		"改 · 移动 UI：屏幕上点哪个就能拖哪个（数字键/方向键各自独立拖动）",
		"新增 · 自由视角开关：角色定在原地，镜头到处飞",
		"改 · 环绕 TA：开启后弹面板选人（取消会自动关掉开关）",
		"改 · 少侠飞行 / FE 变车：点击后先弹确认框，确认才生效",
		"改 · 分身军团：独立面板（环绕跟随 / 脚下放置 / 删除分身）",
		"改 · 已开启功能显示：挪到屏幕上方横排 1 2 3",
		"改 · 全部关闭：先弹确认框并说明会关掉哪些东西",
		"新增 · 传送页：查看玩家（选中即可看他）+ 恢复自己视角",
		"改 · 存档点：保存成功/失败都有明确提示",
	}},	{ v = "v5.20", t = {
		"新增 · 装扮页：6 种大翅膀（天使/堕天/恶魔/光/火/机械）+ 5 种头顶光环",
		"新增 · 蔚蓝档案式光环（悬浮旋转，可调大小与角度）",
		"新增 · 隐藏身上方块：一键清除配件/框选/名牌等附加物",
		"改 · 隐身录屏：开启时暂停除加速外所有功能，退出后原样恢复",
		"修复 · 黑洞与 FPS 加速控件重叠（点不到黑洞）",
		"修复 · 拖尾/少侠/第三人称等角色重生后失效（改为每帧维持）",
		"修复 · 血量显示与功能列表被 HUD 覆盖不显示",
		"新增 · 空壳检查器：自动揪出「开关没用」的字段",
	}},
	{ v = "v5.20", t = {
		"新增 · 公告界面（本页）· 设置页入口",
		"新增 · 头顶光环（蔚蓝档案式）· 分身独立面板",
		"修复 · 飞行 / FOV / 连跳 / 拖尾 / 跳舞 / 骑头 失效",
		"修复 · 黑洞与倒立控件重叠 · 存档点提示",
		"重构 · 混淆版：字符串全加密 + 诱饵逻辑，抗反混淆",
	}},
	{ v = "v5.20", t = {
		"修复 · 特效永远不停（时长单位错误）",
		"修复 · 放出动画不显示漩涡",
		"回退 · 漩涡恢复平面版（更好看的那版）",
		"调整 · 动画时长延长到 3 秒",
	}},
	{ v = "v5.15", t = {
		"新增 · 面板撕裂：切成 18 块被卷进奇点",
		"新增 · 碎片沿螺旋轨迹卷入（龙卷风感）",
		"优化 · 减少线条数量，降低卡顿",
	}},
	{ v = "v5.14", t = {
		"新增 · 面板撕裂（3×6 碎片 + 发光断面）",
		"新增 · 传送独立页面 · 引擎描边开关",
		"新增 · 黑洞 / 甩飞 / 闪电冲刺 / 少侠飞行 / 变车",
	}},
}

NoticeFrame, NoticeList, NoticeAuto = nil, nil, true
function fillNotice()
	if not NoticeList then return end
	for _, c in ipairs(NoticeList:GetChildren()) do
		if c:IsA("Frame") then pcall(function() c:Destroy() end) end
	end
	local y = 6
	local acc = Mode().Accent
	for _, item in ipairs(CHANGELOG) do
		local h = 30 + #item.t * 19
		local row = new("Frame", { Size = UDim2.new(1, -12, 0, h), Position = UDim2.new(0, 6, 0, y),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.955,
			BorderSizePixel = 0, Parent = NoticeList })
		corner(row, 10)
		new("TextLabel", { Text = item.v, Font = Enum.Font.GothamBold, TextSize = 13,
			TextColor3 = acc, BackgroundTransparency = 1, Size = UDim2.new(1, -20, 0, 18),
			Position = UDim2.new(0, 12, 0, 6), TextXAlignment = Enum.TextXAlignment.Left, Parent = row })
		for i, line in ipairs(item.t) do
			new("TextLabel", { Text = "· " .. line, Font = Enum.Font.Gotham, TextSize = 11,
				TextColor3 = Color3.fromRGB(176, 184, 203), BackgroundTransparency = 1,
				Size = UDim2.new(1, -24, 0, 18), Position = UDim2.new(0, 14, 0, 25 + (i - 1) * 19),
				TextXAlignment = Enum.TextXAlignment.Left, Parent = row })
		end
		y = y + h + 8
	end
	NoticeList.CanvasSize = UDim2.new(0, 0, 0, y + 10)
end

function buildNotice()
	if NoticeFrame then return end
	NoticeFrame = new("Frame", { Name = "HonNotice", Size = UDim2.new(0, 470, 0, 420),
		Position = UDim2.new(0.5, -235, 0.5, -210), BackgroundColor3 = Color3.fromRGB(14, 16, 24),
		BackgroundTransparency = 0.02, BorderSizePixel = 0, Visible = false, Parent = Gui })
	corner(NoticeFrame, 16)
	new("UIStroke", { Color = Color3.fromRGB(255, 255, 255), Transparency = 0.92, Thickness = 1, Parent = NoticeFrame })
	new("TextLabel", { Text = "更 新 公 告", Font = Enum.Font.GothamBold, TextSize = 15,
		TextColor3 = Color3.fromRGB(232, 237, 248), BackgroundTransparency = 1,
		Size = UDim2.new(1, -60, 0, 24), Position = UDim2.new(0, 18, 0, 12),
		TextXAlignment = Enum.TextXAlignment.Left, Parent = NoticeFrame })
	new("TextLabel", { Text = "每次更新了什么 / 修了什么，都写在这里", Font = Enum.Font.Gotham, TextSize = 10,
		TextColor3 = Color3.fromRGB(120, 129, 152), BackgroundTransparency = 1,
		Size = UDim2.new(1, -60, 0, 16), Position = UDim2.new(0, 18, 0, 34),
		TextXAlignment = Enum.TextXAlignment.Left, Parent = NoticeFrame })
	local closeB = new("TextButton", { Text = "×", Font = Enum.Font.GothamBold, TextSize = 16,
		TextColor3 = Color3.fromRGB(255, 108, 118), BackgroundTransparency = 1,
		Size = UDim2.new(0, 28, 0, 28), Position = UDim2.new(1, -36, 0, 10), Parent = NoticeFrame })
	closeB.MouseButton1Click:Connect(function() NoticeFrame.Visible = false end)
	NoticeList = new("ScrollingFrame", { Size = UDim2.new(1, -16, 0, 322), Position = UDim2.new(0, 8, 0, 56),
		BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4,
		ScrollBarImageTransparency = 0.6, ScrollBarImageColor3 = Mode().Accent,
		CanvasSize = UDim2.new(0, 0, 0, 600), Parent = NoticeFrame })
	local autoB = new("TextButton", { Text = "启动时自动弹出：开", Font = Enum.Font.GothamBold, TextSize = 11,
		TextColor3 = Mode().Accent, BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.9, BorderSizePixel = 0,
		Size = UDim2.new(1, -16, 0, 30), Position = UDim2.new(0, 8, 0, 384), Parent = NoticeFrame })
	corner(autoB, 8)
	autoB.MouseButton1Click:Connect(function()
		NoticeAuto = not NoticeAuto
		autoB.Text = "启动时自动弹出：" .. (NoticeAuto and "开" or "关")
	end)
	fillNotice()
end

function showNotice()
	buildNotice()
	fillNotice()
	NoticeFrame.Visible = true
end

Mini.MouseButton1Click:Connect(function() Mini.Visible = false; playOpenAnim() end)
local TabBar = new("ScrollingFrame", { Name = "Sidebar", Size = UDim2.new(0, 168, 0, 348), Position = UDim2.new(0, 0, 0, 66),
	BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3,
	ScrollBarImageTransparency = 0.7, ScrollBarImageColor3 = Modes[1].Accent,
	CanvasSize = UDim2.new(0, 0, 0, 372), AutomaticCanvasSize = Enum.AutomaticSize.Y,
	ScrollingDirection = Enum.ScrollingDirection.Y, Parent = Main })
local SideLine = new("Frame", { Size = UDim2.new(0, 1, 1, 0), Position = UDim2.new(0, 167, 0, 0),
	BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.93, BorderSizePixel = 0, Parent = Main })
local TabBtns = {}
local CurTab = 1
do
	local names = { "引擎", "辅助", "视觉", "触屏", "工具", "娱乐", "更多", "实用", "传送", "装扮" }
	for i, n in ipairs(names) do
		local b = new("TextButton", { Text = n, Font = Enum.Font.GothamBold, TextSize = 13,
			TextColor3 = Color3.fromRGB(140, 149, 172), BackgroundTransparency = 1,
			BorderSizePixel = 0, AutoButtonColor = false,
			Size = UDim2.new(1, -16, 0, 40), Position = UDim2.new(0, 8, 0, 10 + (i - 1) * 44), Parent = TabBar })
		local ul = new("Frame", { Size = UDim2.new(0, 4, 0, 26), Position = UDim2.new(0, 0, 0.5, -13),
			BackgroundColor3 = Modes[1].Accent, BackgroundTransparency = 1, BorderSizePixel = 0, Parent = b })
		corner(ul, 1)
		TabBtns[i] = { Btn = b, Underline = ul }
		b.MouseEnter:Connect(function()
			TweenService:Create(b, TWEEN_FAST, { BackgroundTransparency = 0.88 }):Play()
		end)
		b.MouseLeave:Connect(function()
			if i ~= CurTab then
				TweenService:Create(b, TWEEN_FAST, { BackgroundTransparency = 1 }):Play()
			end
		end)
		b.InputEnded:Connect(function()
			if i ~= CurTab then
				TweenService:Create(b, TWEEN_FAST, { BackgroundTransparency = 1 }):Play()
			end
		end)
		bindClick(b, "标签" .. n, function() SetTab(i) end)
	end
end
local PageHost = new("Frame", { Name = "Content", Size = UDim2.new(0, 464, 0, 336), Position = UDim2.new(0, 180, 0, 84),
	BackgroundTransparency = 1, BorderSizePixel = 0, ClipsDescendants = true, Parent = Main })
local PAGE_H = { 520, 380, 620, 680, 910, 1300, 530, 720, 960, 720 }
PageList = {}
local function mkPage(i, visible)
	return new("ScrollingFrame", { Name = "Page" .. tostring(i),
		Size = UDim2.new(1, 0, 1, 0), Position = UDim2.new(0, 0, 0, 0),
		BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4,
		ScrollBarImageTransparency = 0.55, ScrollBarImageColor3 = Modes[1].Accent,
		CanvasSize = UDim2.new(0, 0, 0, PAGE_H[i]),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ElasticBehavior = Enum.ElasticBehavior.WhenScrollable,
		Visible = visible, Parent = PageHost })
end
local PageEng = mkPage(1, true)
local PageAssist = mkPage(2, false)
local PageEsp = mkPage(3, false)
local PageTouch = mkPage(4, false)
local PageTool = mkPage(5, false)
local PageFun = mkPage(6, false)
local PageMore = mkPage(7, false)
local PageUtil = mkPage(8, false)
local PageTp = mkPage(9, false)
local PageDeco = mkPage(10, false)
PageList = { PageEng, PageAssist, PageEsp, PageTouch, PageTool, PageFun, PageMore, PageUtil, PageTp, PageDeco }
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
local function makeToggle(parent, y, title, sub, initial, onChange, keep)
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
		Set = function(v, silent) on = v; api._last = v; paint(on); if not silent then onChange(on) end end,
		Refresh = function() if on then paint(true) end end,
		Dim = function(dim)
			TweenService:Create(row, TWEEN_SOFT, { BackgroundTransparency = dim and 0.75 or 0.35 }):Play()
			TweenService:Create(t1, TWEEN_SOFT, { TextColor3 = dim and Color3.fromRGB(120, 128, 148) or Color3.fromRGB(224, 231, 246) }):Play()
			TweenService:Create(t2, TWEEN_SOFT, { TextColor3 = dim and Color3.fromRGB(92, 99, 118) or Color3.fromRGB(132, 141, 163) }):Play()
			TweenService:Create(stroke, TWEEN_SOFT, { Transparency = dim and 0.95 or 0.85 }):Play()
		end,
	}
	api._last = initial
	api._keep = keep
	api._title = title
	table.insert(ToggleRegistry, api)
	themed(api)
	return api
end
local SearchBox = new("TextBox", { PlaceholderText = "搜索功能…", Text = "", Font = Enum.Font.Gotham, TextSize = 11,
	TextColor3 = Color3.fromRGB(226, 233, 248), PlaceholderColor3 = Color3.fromRGB(105, 113, 134),
	BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.92, BorderSizePixel = 0,
	ClearTextOnFocus = false, Position = UDim2.new(0, 8, 0, 420), Size = UDim2.new(0, 152, 0, 28), Parent = Main })
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
	bindClick(card, "引擎" .. m.Id, function() SetMode(i) end)
end
local SpeedSlider  = makeSlider(PageEng, "速度 SPEED", 206, Modes[1].Min, Modes[1].Max, State.Speed, " sp",
	function(v) State.Speed = v end, true, function(v) State.SpeedLocked = v end, true)
local SmoothSlider = makeSlider(PageEng, "顺滑 SMOOTH", 258, 1, 20, State.Smooth, "",
	function(v) State.Smooth = v end, false)
local PowerToggle   = makeToggle(PageEng, 312, "启用引擎", "F2 快捷键 · 隐身时仍保持", true, function(v) State.Enabled = v end, true)
local InertiaToggle = makeToggle(PageEng, 360, "惯性滑行", "仅 V 引擎生效", true, function(v) State.Inertia = v end)
local SlideToggle   = makeToggle(PageEng, 408, "防穿墙 / 沿墙滑动", "仅 CF 引擎生效", true, function(v) State.WallSlide = v end)
local TeleportToggle = makeToggle(PageEng, 456, "瞬移闪现 TP", "仅 CF · 蓄力后整段位移", false, function(v)
	State.CFTeleport = v
local OutlineTgl = makeToggle(PageEng, 504, "引擎描边 OUTLINE", "角色轮廓跟着引擎颜色", true, function(v)
	State.EngineOutline = v
	if Highlight and Highlight.Parent then
		Highlight.Enabled = v
		if v then Highlight.OutlineColor = Mode().Accent end
	end
end)
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
local FreecamTgl = makeToggle(PageEsp, 470, "自由视角 FREE CAM", "角色定在原地 · 镜头随便飞", false, function(v)
	if type(setFreecam) == "function" then setFreecam(v) end
end)
local BlockTgl = makeToggle(PageEsp, 380, "隐藏身上方块 NO BLOCK", "配件 / 框选 / 名牌等附加物一起藏", false, function(v)
	State.HideBlock = v
	if v then hideBodyBlocks(true) end
end)
local BlockBtn = new("TextButton", { Text = "立即清除身上方块", Font = Enum.Font.GothamBold, TextSize = 11,
	TextColor3 = Mode().Accent, BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.9,
	BorderSizePixel = 0, AutoButtonColor = false,
	Size = UDim2.new(1, 0, 0, 34), Position = UDim2.new(0, 0, 0, 424), Parent = PageEsp })
corner(BlockBtn, 10)
table.insert(FunBtns, BlockBtn)
bindClick(BlockBtn, "清除方块", function()
	local n = hideBodyBlocks(true)
	if notify then notify("已清除 " .. n .. " 个附加物") end
end)
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
	Position = UDim2.new(0, 2, 0, 0), TextXAlignment = Enum.TextXAlignment.Left }, PageTp)
label({ Text = "传 送 TELEPORT", Font = Enum.Font.GothamBold, TextSize = 11,
	TextColor3 = Color3.fromRGB(120, 129, 152), Size = UDim2.new(1, 0, 0, 18),
	Position = UDim2.new(0, 2, 0, 0), TextXAlignment = Enum.TextXAlignment.Left }, PageTp)
local ViewBtn = new("TextButton", { Text = "查看玩家 VIEW PLAYER", Font = Enum.Font.GothamBold, TextSize = 11,
	TextColor3 = Mode().Accent, BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.9,
	BorderSizePixel = 0, AutoButtonColor = false,
	Size = UDim2.new(1, 0, 0, 34), Position = UDim2.new(0, 0, 0, 560), Parent = PageTp })
corner(ViewBtn, 10)
table.insert(FunBtns, ViewBtn)
bindClick(ViewBtn, "查看玩家", function()
	openPlayerPicker(function(pl)
		local ch = pl.Character
		local hum = ch and ch:FindFirstChildOfClass("Humanoid")
		if hum then
			Cam.CameraSubject = hum
			if notify then notify("正在查看：" .. pl.Name) end
		elseif notify then
			notify("该玩家角色还没加载")
		end
	end, nil, "选择要查看的玩家")
end)
local CamBackBtn = new("TextButton", { Text = "恢复自己的视角", Font = Enum.Font.GothamBold, TextSize = 11,
	TextColor3 = Color3.fromRGB(190, 198, 220), BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	BackgroundTransparency = 0.9, BorderSizePixel = 0, AutoButtonColor = false,
	Size = UDim2.new(1, 0, 0, 34), Position = UDim2.new(0, 0, 0, 600), Parent = PageTp })
corner(CamBackBtn, 10)
table.insert(FunBtns, CamBackBtn)
bindClick(CamBackBtn, "恢复视角", function()
	if Humanoid and Humanoid.Parent then Cam.CameraSubject = Humanoid end
	if notify then notify("视角已恢复") end
end)
local TPTarget = nil
local TargetBtn = new("TextButton", { Text = "选择目标 ▾  （玩家 / NPC）", Font = Enum.Font.GothamBold, TextSize = 11,
	TextColor3 = Mode().Accent, BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.9,
	BorderSizePixel = 0, AutoButtonColor = false,
	Size = UDim2.new(1, 0, 0, 36), Position = UDim2.new(0, 0, 0, 152), Parent = PageTp })
corner(TargetBtn, 10)
table.insert(ToolBtns, TargetBtn)
local TPListWrap = new("Frame", { Size = UDim2.new(1, 0, 0, 150), Position = UDim2.new(0, 0, 0, 194),
	BackgroundColor3 = Color3.fromRGB(20, 23, 33), BackgroundTransparency = 0.25,
	BorderSizePixel = 0, Visible = false, ClipsDescendants = true, Parent = PageTp })
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
	Size = UDim2.new(1, 0, 0, 36), Position = UDim2.new(0, 0, 0, 350), Parent = PageTp })
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
local TPLoopTgl = makeToggle(PageTp, 392, "循环传送 LOOP TP", "持续锁定目标（离开即停）", false, function(v)
	State.TPLoop = v
	if v and not TPTarget and notify then
		notify("请先选择目标", Color3.fromRGB(255, 108, 118))
		State.TPLoop = false
		TPLoopTgl.Set(false, true)
	end
end)
local TPSpeedSlider = makeSlider(PageTp, "循环间隔 (0=每帧)", 440, 0, 20, 0, " 秒", function(v)
	State.TPInterval = v / 10
end, false)
local TPOffSlider = makeSlider(PageTp, "高度偏移", 492, 0, 30, 3, " m", function(v)
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
	if t ~= lastTransp then
		lastTransp = t
		for _, p in ipairs(c:GetDescendants()) do
			if p:IsA("BasePart") then p.Transparency = t end
		end
	end
	-- 持续维持：把露出来的附加方块压回去
	if State.HideBlock then
		BlockTimer = BlockTimer + 1
		if BlockTimer >= 30 then
			BlockTimer = 0
			pcall(hideBodyBlocks, false)
		end
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
	{ Enum.Material.Foil, "GOLD" }, { Enum.Material.Neon, "NEON" },
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
local OrbitTgl = makeToggle(PageFun, 256, "绕 TA 转圈 ORBIT", "开启后弹面板选要绕的人", false, function(v)
	if v then
		openPlayerPicker(function(pl)
			State.WatchTarget = pl
			State.Orbit = true
			if TPInput and TPInput.NAME then TPInput.NAME.Text = pl.Name end
			if notify then notify("开始环绕：" .. pl.Name) end
		end, function()
			State.Orbit = false
			pcall(function() OrbitTgl.Set(false, true) end)
		end, "选择要环绕的玩家")
	else
		State.Orbit = false
	end
end)
local BlackHoleTgl = makeToggle(PageFun, 304, "黑洞 BLACK HOLE", "在前方生成黑洞，吸住周围一切", false, function(v)
	setBlackHole(v)
end)
local BlackHoleSlider = makeSlider(PageFun, "黑洞吸力", 352, 10, 200, 60, " ", function(v)
	State.BlackHoleForce = v
end, false)
FlingBtn = new("TextButton", { Text = "甩飞所有人 LAUNCH ALL", Font = Enum.Font.GothamBold, TextSize = 11,
	TextColor3 = Mode().Accent, BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.9,
	BorderSizePixel = 0, AutoButtonColor = false,
	Size = UDim2.new(0.5, -4, 0, 36), Position = UDim2.new(0, 0, 0, 404), Parent = PageFun })
corner(FlingBtn, 10)
table.insert(FunBtns, FlingBtn)
bindClick(FlingBtn, "甩飞", function() flingAll() end)
DashBtn = new("TextButton", { Text = "闪电冲刺 LIGHTNING", Font = Enum.Font.GothamBold, TextSize = 11,
	TextColor3 = Mode().Accent, BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.9,
	BorderSizePixel = 0, AutoButtonColor = false,
	Size = UDim2.new(0.5, -4, 0, 36), Position = UDim2.new(0.5, 4, 0, 404), Parent = PageFun })
corner(DashBtn, 10)
table.insert(FunBtns, DashBtn)
bindClick(DashBtn, "闪电冲刺", function() lightningDash() end)
HeroFlyTgl = makeToggle(PageFun, 448, "无敌少侠飞行 HERO FLY", "超人姿势 · 高速（需确认）", false, function(v)
	if v then
		pcall(function() HeroFlyTgl.Set(false, true) end)
		askConfirm("开启无敌少侠飞行？", "会以超人姿势高速飞行，角色进入悬浮状态。\n点「确认开启」后才会真正生效。", "确认开启", function()
			setHeroFly(true)
			pcall(function() HeroFlyTgl.Set(true, true) end)
		end)
	else
		setHeroFly(false)
	end
end)
CarTgl = makeToggle(PageFun, 496, "FE 变车 BECOME CAR", "角色变成车（需确认）", false, function(v)
	if v then
		pcall(function() CarTgl.Set(false, true) end)
		askConfirm("变成车？", "会把你的角色隐藏并生成一辆车跟着你走，别人也能看见。\n点「确认开启」后才会真正生效。", "确认开启", function()
			setCar(true)
			pcall(function() CarTgl.Set(true, true) end)
		end)
	else
		setCar(false)
	end
end)
ThirdTgl = makeToggle(PageFun, 544, "强制第三人称", "锁定第三人称视角", false, function(v)
	setThirdPerson(v)
end)
NoFallTgl = makeToggle(PageFun, 592, "防摔落伤害", "落地不扣血", false, function(v)
	State.NoFall = v
end)
HpTgl = makeToggle(PageFun, 640, "自身血量显示", "HUD 上显示当前血量", false, function(v)
	State.ShowHP = v
end)
FunListTgl = makeToggle(PageFun, 688, "功能列表显示", "HUD 列出当前开启的功能", false, function(v)
	State.ShowFunList = v
end)
TrailTgl = makeToggle(PageFun, 736, "彩虹拖尾 TRAIL", "角色身后拉出彩色光带", false, function(v)
	State.Trail = v
	setTrail(v)
end)
CloneTgl = makeToggle(PageFun, 784, "分身军团 CLONE ARMY", "打开独立面板：环绕/放置/删除", false, function(v)
	buildClonePanel()
	ClonePanel.Visible = v
end)
OrbitFxTgl = makeToggle(PageFun, 832, "粒子环绕 ORBIT FX", "角色周围粒子球旋转", false, function(v)
	State.OrbitFx = v
	setOrbitFx(v)
end)
RideTgl = makeToggle(PageFun, 880, "骑到头上 HEAD RIDE", "坐到最近玩家头顶", false, function(v)
	State.HeadRide = v
end)
ShakeTgl = makeToggle(PageFun, 928, "屏幕震动 SHAKE", "镜头持续抖动（恶搞）", false, function(v)
	State.Shake = v
end)
SpinCamTgl = makeToggle(PageFun, 976, "视角自转 SPIN CAM", "镜头绕着自己旋转", false, function(v)
	State.SpinCam = v
end)
MagnetTgl = makeToggle(PageFun, 1024, "物品吸附 MAGNET", "把附近可拾取物吸过来", false, function(v)
	State.Magnet = v
end)
DanceAllBtn = new("TextButton", { Text = "让所有人跳舞 DANCE PARTY", Font = Enum.Font.GothamBold, TextSize = 11,
	TextColor3 = Mode().Accent, BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.9,
	BorderSizePixel = 0, AutoButtonColor = false,
	Size = UDim2.new(1, 0, 0, 36), Position = UDim2.new(0, 0, 0, 1072), Parent = PageFun })
corner(DanceAllBtn, 10)
table.insert(FunBtns, DanceAllBtn)
bindClick(DanceAllBtn, "全员跳舞", function() danceAll() end)
LowFxTgl = makeToggle(PageFun, 1120, "FPS 加速 LOW FX", "关阴影/粒子/降画质", false, function(v) setLowFx(v) end)
FlipBtn = new("TextButton", { Text = "倒立 FLIP", Font = Enum.Font.GothamBold, TextSize = 11,
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
MoreBtns = {}
label({ Text = "更 多 玩 法", Font = Enum.Font.GothamBold, TextSize = 11,
	TextColor3 = Color3.fromRGB(120, 129, 152), Size = UDim2.new(1, 0, 0, 18),
	Position = UDim2.new(0, 2, 0, 0), TextXAlignment = Enum.TextXAlignment.Left }, PageMore)
DanceTgl = makeToggle(PageMore, 24, "自创跳舞 DANCE", "骨骼正弦摆动，不依赖动画 ID", false, function(v)
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
HeightSlider = makeSlider(PageMore, "身高 HEIGHT", 72, 0.3, 5, 1, " x", function(v)
	setBodyScale(v, nil, nil)
end, false)
HeadSlider = makeSlider(PageMore, "头比例 HEAD", 124, 0.3, 5, 1, " x", function(v)
	setBodyScale(nil, nil, v)
end, false)
HaloTgl = makeToggle(PageMore, 178, "头顶光环 HALO", "跟着头转的霓虹光环", false, function(v)
	State.Halo = v
	if not v then HaloPart = nil end
end)
FollowTgl = makeToggle(PageMore, 226, "自动跟随 FOLLOW", "开启后弹出面板选要跟的人", false, function(v)
	State.Follow = v
	if v then openPlayerPicker("选择要跟随的玩家", function(pl)
		State.WatchTarget = pl
		if notify then notify("已锁定：" .. (pl.DisplayName or pl.Name)) end
	end) end
end)
FaceTgl   = makeToggle(PageMore, 274, "始终注视 FACING", "开启后弹出面板选要看的人", false, function(v)
	State.Face = v
	if v then openPlayerPicker("选择要注视的玩家", function(pl)
		State.WatchTarget = pl
		if notify then notify("已锁定：" .. (pl.DisplayName or pl.Name)) end
	end) end
end)
FeignBtn = new("TextButton", { Text = "装死躺平 FEIGN", Font = Enum.Font.GothamBold, TextSize = 11,
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
ClockSlider = makeSlider(PageMore, "昼夜 CLOCK", 366, 0, 24, math.floor(Lighting.ClockTime), " h", function(v)
	Lighting.ClockTime = v
end, false)
FovSlider = makeSlider(PageMore, "视野 FOV", 420, 30, 120, 70, " °", function(v)
	State.FovValue = v
	if v > 0 then Cam.FieldOfView = v end
end, false)
FX_LIST = { "OFF", "BLOOM", "CYBER", "NOIR" }
fxIndex = 1
FxBtn = new("TextButton", { Text = "画面特效：OFF", Font = Enum.Font.GothamBold, TextSize = 11,
	TextColor3 = Mode().Accent, BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.9,
	BorderSizePixel = 0, AutoButtonColor = false,
	Size = UDim2.new(1, 0, 0, 36), Position = UDim2.new(0, 0, 0, 474), Parent = PageMore })
corner(FxBtn, 10)
table.insert(MoreBtns, FxBtn)
FxBtn.MouseButton1Click:Connect(function() applyScreenFx() end)
function setBodyScale(h, w, head)
	local c = LP.Character
	if not c then return end
	local found = 0
	for _, v in ipairs(c:GetDescendants()) do
		if v:IsA("NumberValue") then
			if h and v.Name == "BodyHeightScale" then v.Value = h end
			if w and (v.Name == "BodyWidthScale" or v.Name == "BodyDepthScale") then v.Value = w end
			if head and v.Name == "HeadScale" then v.Value = head end
			found = found + 1
		end
	end
	if found == 0 then
		local hum = c:FindFirstChildOfClass("Humanoid")
		if hum then
			pcall(function()
				local function ensure(nm, val)
					local o = hum:FindFirstChild(nm)
					if not o then o = Instance.new("NumberValue"); o.Name = nm; o.Parent = hum end
					o.Value = val
				end
				if h then ensure("BodyHeightScale", h) end
				if w then ensure("BodyWidthScale", w); ensure("BodyDepthScale", w) end
				if head then ensure("HeadScale", head) end
			end)
		elseif notify then
			notify("当前角色不支持缩放（需 R15）")
		end
	end
end
FxInstances = {}
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
				HaloPart.Size = Vector3.new(3.0, 0.16, 3.0)
				HaloPart.Shape = Enum.PartType.Cylinder
				HaloPart.Material = Enum.Material.Neon
				HaloPart.BrickColor = BrickColor.new("Bright yellow")
				HaloPart.CanCollide = false
				HaloPart.Anchored = true
				HaloPart.Parent = Workspace
			end
			local a = tick() * 2
			HaloPart.CFrame = CFrame.new(head.Position + Vector3.new(0, 2.6, 0)) * CFrame.Angles(0, a, 0)
		end
	elseif HaloPart then
		if HaloPart.Parent then HaloPart:Destroy() end
		HaloPart = nil
	end
end)
UtilBtns = {}
label({ Text = "实 用 工 具", Font = Enum.Font.GothamBold, TextSize = 11,
	TextColor3 = Color3.fromRGB(120, 129, 152), Size = UDim2.new(1, 0, 0, 18),
	Position = UDim2.new(0, 2, 0, 0), TextXAlignment = Enum.TextXAlignment.Left }, PageUtil)
label({ Text = "隐 身 录 屏", Font = Enum.Font.GothamBold, TextSize = 11,
	TextColor3 = Color3.fromRGB(120, 129, 152), Size = UDim2.new(1, 0, 0, 16),
	Position = UDim2.new(0, 2, 0, 494), TextXAlignment = Enum.TextXAlignment.Left }, PageUtil)
StealthTgl = makeToggle(PageUtil, 516, "隐身录屏 STEALTH", "隐藏界面 + 暂停其他功能（加速保留）", false, function(v)
	setStealth(v)
end, true)
StealthGameTgl = makeToggle(PageUtil, 564, "连游戏 UI 一起藏", "含 Roblox 核心 UI · 顶栏 · 内置界面", true, function(v)
	State.StealthHideGame = v
	if State.Stealth then
		if v then stealthHideGame() else stealthShowGame() end
	end
end)
label({ Text = "开启后右上角出现一个 REC 悬浮窗：点一下恢复全部界面，再点一下重新隐藏。\n隐藏期间加速 / 飞行 / ESP 全部继续生效。\n注：注入器若是独立原生窗口，脚本无法控制它，请用它自己的快捷键。",
	Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = Color3.fromRGB(132, 141, 163),
	Position = UDim2.new(0, 2, 0, 616), Size = UDim2.new(1, -4, 0, 56),
	TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top }, PageUtil)
WaypointLabel = label({ Text = "存档点：未设置", Font = Enum.Font.Gotham, TextSize = 10,
	TextColor3 = Color3.fromRGB(132, 141, 163), Size = UDim2.new(1, -4, 0, 20),
	Position = UDim2.new(0, 2, 0, 680), TextXAlignment = Enum.TextXAlignment.Left }, PageUtil)
function utilBtn(text, y, onClick)
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
FreezeTgl = makeToggle(PageUtil, 112, "冻结自己 FREEZE", "锚定本体，推不动也掉不下去", false, function(v)
	State.Freeze = v
	if HRP and HRP.Parent and not v then HRP.Anchored = false end
end)
SaveBtn = utilBtn("保存存档点 SAVE", 160, function()
	if HRP and HRP.Parent then
		State.Waypoint = HRP.Position
		WaypointLabel.Text = string.format("存档点：%d, %d, %d",
			math.floor(State.Waypoint.X), math.floor(State.Waypoint.Y), math.floor(State.Waypoint.Z))
		if notify then notify("存档点已保存 " .. WaypointLabel.Text:gsub("存档点：", "")) end
	elseif notify then
		notify("保存失败：角色还没加载")
	end
end)
GoBtn = utilBtn("回到存档点 GO", 160, function()
	if State.Waypoint and HRP and HRP.Parent then
		HRP.CFrame = CFrame.new(State.Waypoint + Vector3.new(0, 3, 0))
	end
end)
SaveBtn.Size = UDim2.new(0.5, -4, 0, 36)
GoBtn.Size = UDim2.new(0.5, -4, 0, 36)
GoBtn.Position = UDim2.new(0.5, 4, 0, 160)
HidePlrTgl = makeToggle(PageUtil, 204, "隐藏其他玩家", "别人变透明，不再挡视线", false, function(v)
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
CoordTgl = makeToggle(PageUtil, 348, "坐标显示 COORD", "自动开启 HUD 并在上面显示 XYZ", false, function(v)
	State.CoordHud = v
	if v then
		State.HUD = true
		if HudFrame then HudFrame.Visible = true end
		if HudTgl then HudTgl.Set(true, true) end
		if notify then notify("坐标显示已开启（已自动打开速度 HUD）") end
	end
end)
ZoomSlider = makeSlider(PageUtil, "镜头距离 ZOOM", 396, 1, 120, 20, " m", function(v)
	LP.CameraMaxZoomDistance = v
	LP.CameraMinZoomDistance = v
end, false)
utilBtn("全部关闭 RESET ALL", 450, function()
	askConfirm("关闭全部功能？", "会把当前开着的所有开关全部关掉：飞行 / 穿墙 / 无限跳 / 透视 / 黑洞 / 分身 / 拖尾 / 特效 等等。\n滑条数值保留，存档点不会被删除。", "确认全部关闭", function()
		for _, t in ipairs(ToggleRegistry) do pcall(function() t.Set(false, false) end) end
		if notify then notify("已关闭全部功能", Color3.fromRGB(255, 108, 118)) end
	end)
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
		pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, not on) end)
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
label({ Text = "M 切引擎 · F2 开关 · L 锁面板 · E/Q 飞行 · , . 切页 · RightCtrl 显隐",
	Font = Enum.Font.Gotham, TextSize = 9, TextColor3 = Color3.fromRGB(105, 113, 134),
	Position = UDim2.new(0, 0, 1, -13), Size = UDim2.new(1, 0, 0, 12),
	TextXAlignment = Enum.TextXAlignment.Center,
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
	print("[HON] 切换到第 " .. tostring(i) .. " 页")
	if notify then pcall(function() notify("第 " .. tostring(i) .. " 页") end) end
	if Status then pcall(function() Status.Text = "当前第 " .. tostring(i) .. " 页 · 点左侧栏切页" end) end
	-- 先切页面（这一步绝不能失败，否则所有页面会同时显示、叠在一起）
	for j, pg in ipairs(PageList) do
		if pg then pg.Visible = (j == i) end
	end
	pcall(function()
		local pg = PageList[i]
		if pg then pg.CanvasPosition = Vector2.new(0, 0) end
	end)
	pcall(function()
		for _, pg in ipairs(PageList) do pg.ScrollBarImageColor3 = Mode().Accent end
	end)
	-- 再刷新侧栏高亮（这里出错也不影响切页）
	pcall(function()
		for j, t in ipairs(TabBtns) do
			if t and t.Btn then
				local on = (j == i)
				TweenService:Create(t.Btn, TWEEN_FAST, {
					TextColor3 = on and Color3.fromRGB(238, 243, 255) or Color3.fromRGB(140, 149, 172),
					BackgroundTransparency = on and 0.86 or 1 }):Play()
				if t.Underline then
					TweenService:Create(t.Underline, TWEEN_FAST, { BackgroundTransparency = on and 0 or 1 }):Play()
				end
			end
		end
	end)
end
function SetMode(i)
	State.ModeIndex = i
	print("[HON] 切换到引擎 " .. tostring(i) .. " " .. tostring(Modes[i] and Modes[i].Name))
	if notify then pcall(function() notify("引擎：" .. tostring(Modes[i] and Modes[i].Name)) end) end
	if Status then pcall(function() Status.Text = "当前引擎：" .. tostring(Modes[i] and Modes[i].Name) end) end
	local m = Modes[i]
	if State.SpeedLocked then
		SpeedSlider.SetRange(m.Min, math.max(m.Max, State.Speed))
		SpeedSlider.Set(State.Speed)
	else
		State.Speed = m.Speed
		SpeedSlider.SetRange(m.Min, m.Max)
		SpeedSlider.Set(m.Speed)
	end
	if not State.JumpLocked then
		State.JumpPower = DEFAULT_JUMP
		JumpSlider.Set(State.JumpPower)
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
-- ---------- 神威 · 空间扭曲 ----------
-- 还原「空间被拧成漩涡」：把一整片空间网格（同心环 + 径向线）按等角(对数)螺旋
-- r = a·e^(b·theta) 扭曲 —— 径向线弯成螺旋、同心环按「内快外慢」差异旋转产生剪切，
-- 越靠中心卷得越紧，最后被中心的黑洞奇点吞噬。
-- 螺旋段不是散点：每条臂由一串首尾相接的短线段沿切线方向拼成，因此是连续曲线。
KAMUI_A, KAMUI_B = 5, 0.30
KamuiRoot, KamuiCore, KamuiGlow, KamuiDisc = nil, nil, nil, nil
KamuiSegs, KamuiRings = {}, {}
KamuiOn, KamuiT, KamuiDur, KamuiDir = false, 0, 2.8, 1

function buildKamui()
	if KamuiRoot then return end
	KamuiRoot = new("Frame", { Name = "HonKamui", Size = UDim2.new(0, 360, 0, 360),
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0),
		BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false, Parent = Gui })
	-- 奇点辉光
	KamuiGlow = new("Frame", { Size = UDim2.new(0, 130, 0, 130), AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0), BackgroundColor3 = Color3.fromRGB(130, 165, 255),
		BackgroundTransparency = 0.8, BorderSizePixel = 0, Parent = KamuiRoot })
	corner(KamuiGlow, 65)
	-- 吸积盘
	KamuiDisc = new("Frame", { Size = UDim2.new(0, 78, 0, 78), AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0), BackgroundTransparency = 1,
		BorderSizePixel = 0, Parent = KamuiRoot })
	corner(KamuiDisc, 39)
	new("UIStroke", { Color = Color3.fromRGB(230, 242, 255), Thickness = 3, Transparency = 0.08, Parent = KamuiDisc })
	-- 黑洞奇点
	KamuiCore = new("Frame", { Size = UDim2.new(0, 34, 0, 34), AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0), BackgroundColor3 = Color3.fromRGB(1, 1, 4),
		BackgroundTransparency = 0, BorderSizePixel = 0, Parent = KamuiRoot })
	corner(KamuiCore, 17)
	-- 同心空间环：内快外慢 → 差异旋转 = 剪切扭曲
	for i = 1, 4 do
		local d = 104 + i * 46
		local r = new("Frame", { Size = UDim2.new(0, d, 0, d), AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0), BackgroundTransparency = 1,
			BorderSizePixel = 0, Parent = KamuiRoot })
		corner(r, d / 2)
		local st = new("UIStroke", { Color = Color3.fromRGB(165, 190, 240), Thickness = 2, Transparency = 0.62, Parent = r })
		table.insert(KamuiRings, { Ring = r, Stroke = st, D = d, Spd = 4.4 - i * 0.64 })
	end
	-- 等角螺旋：7 条臂 × 24 段，段沿切线方向首尾相接 → 连续螺旋曲线
	local psi = math.deg(math.atan(1 / KAMUI_B))
	local th0 = math.log(9 / KAMUI_A) / KAMUI_B
	local th1 = math.log(140 / KAMUI_A) / KAMUI_B
	local dth = (th1 - th0) / 13
	for i = 1, 5 do
		local base = (i - 1) * (360 / 5)
		for j = 0, 12 do
			local th = th0 + j * dth
			local r = KAMUI_A * math.exp(KAMUI_B * th)
			local len = r * dth * math.sqrt(1 + KAMUI_B * KAMUI_B) * 1.5
			local w = 2 + (r / 140) * 3
			local seg = new("Frame", { Size = UDim2.new(0, len, 0, w),
				AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Color3.fromRGB(180, 205, 248),
				BackgroundTransparency = 0.28, BorderSizePixel = 0, Parent = KamuiRoot })
			corner(seg, w / 2)
			table.insert(KamuiSegs, { Seg = seg, R = r, A0 = base + math.deg(th),
				Rot = psi, Spd = 3.9 - (r / 140) * 2.5 })
		end
	end
end

-- ---------- 面板撕裂：把面板切成 3×6 共 18 块，每块被空间扭曲扯向奇点 ----------
KamuiShards, KamuiShatter = {}, false
OrigMainSize = nil
function buildShards()
	if #KamuiShards > 0 then return end
	for i = 1, 18 do
		local f = new("Frame", { Name = "HonShard", Size = UDim2.new(0, 0, 0, 0),
			Position = UDim2.new(0, 0, 0, 0), BackgroundColor3 = Color3.fromRGB(16, 19, 28),
			BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false, Parent = Gui })
		corner(f, 5)
		local st = new("UIStroke", { Color = Color3.fromRGB(120, 160, 255), Thickness = 1.5, Transparency = 1, Parent = f })
		table.insert(KamuiShards, { F = f, S = st, OX = 0, OY = 0, OW = 0, OH = 0, CX = 0, CY = 0, R0 = 0 })
	end
end

function shatterPanel()
	buildShards()
	if not OrigMainSize then OrigMainSize = Main.Size end
	local mp, ms = Main.AbsolutePosition, Main.AbsoluteSize
	if ms.X < 10 or ms.Y < 10 then return false end
	local cxp, cyp = 0, 0
	if KamuiRoot then
		cxp = KamuiRoot.AbsolutePosition.X + KamuiRoot.AbsoluteSize.X / 2
		cyp = KamuiRoot.AbsolutePosition.Y + KamuiRoot.AbsoluteSize.Y / 2
	else
		cxp = mp.X + ms.X / 2
		cyp = mp.Y + ms.Y / 2
	end
	local cols, rows = 3, 6
	local cw, ch = ms.X / cols, ms.Y / rows
	local acc = Mode().Accent
	local base = Main.BackgroundColor3
	for i, d in ipairs(KamuiShards) do
		local c = (i - 1) % cols
		local r = math.floor((i - 1) / cols)
		d.OX = mp.X + c * cw
		d.OY = mp.Y + r * ch
		d.OW = cw
		d.OH = ch
		d.CX = cxp
		d.CY = cyp
		d.R0 = ((i % 2 == 0) and 1 or -1) * (140 + (i * 37) % 220)
		d.F.BackgroundColor3 = ((i % 4) == 0) and acc or base
		d.F.BackgroundTransparency = 0.06
		d.S.Color = acc
		d.S.Transparency = 0.15
	end
	return true
end

function hideShards()
	for _, d in ipairs(KamuiShards) do d.F.Visible = false end
end

function playKamui(mode)
	buildKamui()
	KamuiDir = (mode == "out") and -1 or 1
	KamuiT = 0
	KamuiOn = true
	KamuiRoot.Visible = true
end

pcall(function() RunService:UnbindFromRenderStep("HonKamui") end)
RunService:BindToRenderStep("HonKamui", 9999, function(dt)
	if not KamuiOn or not KamuiRoot then return end
	KamuiT = KamuiT + dt
	local raw = KamuiT / KamuiDur
	if raw >= 1 then
		KamuiOn = false
		KamuiRoot.Visible = false
		KamuiShatter = false
		hideShards()
		return
	end
	local k = raw < 0.5 and (2 * raw * raw) or (1 - math.pow(-2 * raw + 2, 2) / 2)
	local out = KamuiDir > 0
	local sc = out and (0.06 + 0.94 * k) or (1 - 0.94 * k)
	local vis = out and (raw < 0.18 and (raw / 0.18) or (raw > 0.78 and (1 - (raw - 0.78) / 0.22) or 1))
		or (1 - raw * 0.9)
	local acc = Mode().Accent
	local phase = KamuiT * 2.6
	local wind = k * 2.2
	-- 螺旋段：差异旋转 + 持续卷紧
	for _, g in ipairs(KamuiSegs) do
		local ang = g.A0 + (phase + wind * 3.4) * g.Spd * KamuiDir
		local rr = g.R * sc
		local rd = math.rad(ang)
		g.Seg.Position = UDim2.new(0.5, math.cos(rd) * rr, 0.5, math.sin(rd) * rr)
		g.Seg.Rotation = ang + g.Rot
		g.Seg.BackgroundTransparency = 1 - vis * 0.72
		g.Seg.BackgroundColor3 = acc
	end
	-- 同心环：内快外慢
	for _, q in ipairs(KamuiRings) do
		local d = q.D * sc
		q.Ring.Size = UDim2.new(0, d, 0, d)
		q.Ring.Rotation = (phase + wind * 2) * q.Spd * KamuiDir
		q.Stroke.Transparency = 1 - vis * 0.45
		q.Stroke.Color = acc
	end
	-- 奇点：放出时由大收缩为点，吸入时膨胀吞噬
	local cs = out and (150 - 116 * k) or (34 + 150 * k)
	KamuiCore.Size = UDim2.new(0, cs, 0, cs)
	pcall(function() corner(KamuiCore, cs / 2) end)
	KamuiCore.BackgroundTransparency = 1 - vis
	local ds = 78 * (out and (0.4 + 0.6 * k) or (1 + 0.9 * k))
	KamuiDisc.Size = UDim2.new(0, ds, 0, ds)
	KamuiDisc.BackgroundTransparency = 1
	local gs = 130 * (out and (0.2 + 0.8 * k) or (1 + 0.5 * k))
	KamuiGlow.Size = UDim2.new(0, gs, 0, gs)
	KamuiGlow.BackgroundTransparency = 1 - vis * 0.22
	KamuiGlow.BackgroundColor3 = acc
	-- 撕裂碎片：1 = 完整拼在面板原位，0 = 被扯进奇点
	if KamuiShatter and #KamuiShards > 0 then
		local u
		if out then
			u = math.min(1, math.max(0, (raw - 0.10) / 0.78))
		else
			u = 1 - math.min(1, math.max(0, (raw - 0.06) / 0.80))
		end
		local q = u * u * (3 - 2 * u)
		local fcy = 20
		for _, d in ipairs(KamuiShards) do
			local vx, vy = d.OX - d.CX, d.OY - (d.CY + fcy)
			local rad = math.sqrt(vx * vx + vy * vy)
			local ang = math.atan2(vy, vx)
			local spin = (1 - q) * 2.6 * (1 + (1 - q) * 1.6) * KamuiDir
			local rr = rad * math.pow(q, 1.25)
			local nx = d.CX + math.cos(ang + spin) * rr
			local ny = d.CY + fcy + math.sin(ang + spin) * rr * 0.92
			local w = d.OW * (0.03 + 0.97 * q)
			local h = d.OH * (0.03 + 0.97 * q)
			d.F.Visible = true
			d.F.Position = UDim2.new(0, nx, 0, ny)
			d.F.Size = UDim2.new(0, w, 0, h)
			d.F.Rotation = d.R0 * (1 - q) * (out and -1 or 1)
			d.F.BackgroundTransparency = 0.06 + (1 - q) * 0.82
			d.S.Transparency = 0.15 + (1 - q) * 0.82
		end
	end
end)

function playOpenAnim()
	Main.Visible = false
	playKamui("in")
	if not pcall(shatterPanel) then Main.Visible = true; return end
	KamuiShatter = true
	tspawn(function()
		twait(2.35)
		KamuiShatter = false
		hideShards()
		Main.Visible = true
		if MainScale then MainScale.Scale = 1 end
		Main.Rotation = 0
		if OrigMainSize then Main.Size = OrigMainSize end
	end)
end

function playCloseAnim(after)
	playKamui("out")
	local ok = pcall(shatterPanel)
	if not ok then
		if after then after() end
		return
	end
	KamuiShatter = true
	-- 先被空间横向拉扯扭曲一下，再交给碎片撕裂
	pcall(function()
		local ti0 = TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
		TweenService:Create(Main, ti0, { Rotation = 10 }):Play()
		TweenService:Create(Main, ti0, { Size = UDim2.new(0, Main.AbsoluteSize.X * 1.16, 0, Main.AbsoluteSize.Y * 0.8) }):Play()
	end)
	tspawn(function()
		twait(0.15)
		Main.Visible = false
		Main.Rotation = 0
		if OrigMainSize then Main.Size = OrigMainSize end
		if after then after() end
	end)
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
function flyDir()
	-- 飞行时 PlatformStand=true，Humanoid.MoveDirection 失效，
	-- 而虚拟方向键的 Humanoid:Move 在飞行时也被跳过，所以这里直接读 PadDir
	if PadActive and (PadDir.x ~= 0 or PadDir.y ~= 0) then
		return padWorld()
	end
	return keyDir()
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
		local p = State.WatchTarget
		if not (p and p.Parent) then p = getTargetPlayer(TPInput and TPInput.NAME and TPInput.NAME.Text or "") end
		local thrp = p and p.Character and p.Character:FindFirstChild("HumanoidRootPart")
		if thrp then
			local a = tick() * 1.3
			HRP.CFrame = CFrame.new(thrp.Position + Vector3.new(math.cos(a) * 9, 0, math.sin(a) * 9))
		end
	end
	if State.Follow or State.Face then
		local p = State.WatchTarget
		if not (p and p.Parent) then p = getTargetPlayer(TPInput and TPInput.NAME and TPInput.NAME.Text or "") end
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
		local dir = flyDir()
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
		if Highlight and Highlight.Parent then
			Highlight.Enabled = State.EngineOutline
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
		Highlight.Enabled = State.EngineOutline
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
		if HudSub and HudSub.Parent then
			local extra = ""
			if State.ShowHP and Humanoid and Humanoid.Parent then
				extra = extra .. " · HP" .. math.floor(Humanoid.Health)
			end
			if State.ShowFunList then
				local onList = {}
				if State.Enabled then table.insert(onList, "SPD") end
				if State.Fly then table.insert(onList, "FLY") end
				if State.Noclip then table.insert(onList, "CLIP") end
				if State.InfJump then table.insert(onList, "JUMP") end
				if State.EspPlayer then table.insert(onList, "ESP") end
				if State.Spin then table.insert(onList, "SPIN") end
				if State.Rainbow then table.insert(onList, "RGB") end
				if State.BlackHole then table.insert(onList, "HOLE") end
				if State.Car then table.insert(onList, "CAR") end
				if State.Trail then table.insert(onList, "TRAIL") end
				if #onList > 0 then extra = extra .. " · " .. table.concat(onList, "/") end
			end
			if extra ~= "" and HudSub.Text:find("HP") == nil then
				HudSub.Text = HudSub.Text .. extra
			end
		end
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
	elseif k == Enum.KeyCode.Comma then
		SetTab((CurTab - 2) % 8 + 1)
	elseif k == Enum.KeyCode.Period then
		SetTab((CurTab % 8) + 1)
	elseif k == Enum.KeyCode.M then
		SetMode((State.ModeIndex % #Modes) + 1)
	end
end)
NotifyHost = new("Frame", { Name = "HonNotify", Size = UDim2.new(0, 250, 0, 400),
	Position = UDim2.new(1, -266, 0, 60), BackgroundTransparency = 1, Parent = Gui })
NotifyLayout = new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = NotifyHost })
-- ---------- 执行器 / 时间 / 首次使用 ----------
function detectExecutor()
	local ok, name = pcall(function()
		if type(rawget(_G, "identifyexecutor")) == "function" then return identifyexecutor() end
		if type(rawget(_G, "getexecutorname")) == "function" then return getexecutorname() end
		if type(rawget(_G, "syn")) == "table" then return "Synapse X" end
		if rawget(_G, "KRNL_LOADED") ~= nil then return "KRNL" end
		if type(rawget(_G, "Delta")) == "table" then return "Delta" end
		if type(rawget(_G, "Xeno")) == "table" then return "Xeno" end
		return nil
	end)
	if ok and type(name) == "string" and #name > 0 then return name end
	return "未识别（执行器未暴露信息）"
end
ExecutorName = detectExecutor()
pcall(function() FirstUse = TeleportService:GetTeleportSetting("HON_FIRST_USE") end)
if not FirstUse or FirstUse == "" then
	FirstUse = os.date("%Y-%m-%d %H:%M")
	pcall(function() TeleportService:SetTeleportSetting("HON_FIRST_USE", FirstUse) end)
end
function clockInfo()
	local h = tonumber(os.date("%H")) or 12
	local period = (h >= 6 and h < 18) and "白天" or "晚上"
	return os.date("%H:%M") .. " · " .. period
end

-- 视野 FOV：独立维持（用户设定优先于引擎自动拉伸，不受主循环任何分支影响）
pcall(function() RunService:UnbindFromRenderStep("HonFov") end)
RunService:BindToRenderStep("HonFov", 9996, function()
	if State.FovValue and State.FovValue > 0 then
		if math.abs((Cam.FieldOfView or 70) - State.FovValue) > 0.5 then
			Cam.FieldOfView = State.FovValue
		end
	end
end)

-- ---------- 屏幕选人面板（自动跟随 / 始终注视 / 环绕 用）----------
PickerFrame, PickerList, PickerTitle = nil, nil, nil
function openPlayerPicker(title, onPick)
	if not PickerFrame then
		PickerFrame = new("Frame", { Name = "HonPicker", Size = UDim2.new(0, 286, 0, 320),
			Position = UDim2.new(0.5, -143, 0.5, -160),
			BackgroundColor3 = Color3.fromRGB(14, 16, 24), BackgroundTransparency = 0.04,
			BorderSizePixel = 0, Visible = false, Parent = Gui })
		corner(PickerFrame, 16)
		new("UIStroke", { Color = Modes[1].Accent, Transparency = 0.4, Thickness = 1, Parent = PickerFrame })
		PickerTitle = label({ Text = "选择玩家", Font = Enum.Font.GothamBold, TextSize = 13,
			TextColor3 = Color3.fromRGB(238, 243, 255), Position = UDim2.new(0, 14, 0, 12),
			Size = UDim2.new(1, -60, 0, 20), TextXAlignment = Enum.TextXAlignment.Left }, PickerFrame)
		local close = new("TextButton", { Text = "×", Font = Enum.Font.GothamBold, TextSize = 16,
			TextColor3 = Color3.fromRGB(255, 108, 118), BackgroundTransparency = 1, BorderSizePixel = 0,
			AutoButtonColor = false, Position = UDim2.new(1, -38, 0, 8), Size = UDim2.new(0, 28, 0, 28), Parent = PickerFrame })
		bindClick(close, "关闭选人", function() PickerFrame.Visible = false end)
		PickerList = new("ScrollingFrame", { Size = UDim2.new(1, -20, 1, -52), Position = UDim2.new(0, 10, 0, 42),
			BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4,
			ScrollBarImageTransparency = 0.5, CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = PickerFrame })
		new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = PickerList })
	end
	if PickerTitle then PickerTitle.Text = tostring(title or "选择玩家") end
	for _, c in ipairs(PickerList:GetChildren()) do
		if c:IsA("TextButton") then c:Destroy() end
	end
	local n = 0
	for _, pl in ipairs(Players:GetPlayers()) do
		if pl ~= LP then
			n = n + 1
			local b = new("TextButton", { Text = (pl.DisplayName or pl.Name) .. "  (@" .. pl.Name .. ")",
				Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Color3.fromRGB(226, 233, 248),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.93,
				BorderSizePixel = 0, AutoButtonColor = false,
				Size = UDim2.new(1, -8, 0, 34), Parent = PickerList })
			corner(b, 8)
			bindClick(b, "选人" .. pl.Name, function()
				PickerFrame.Visible = false
				if onPick then onPick(pl) end
			end)
		end
	end
	if n == 0 then
		label({ Text = "当前没有别的玩家", Font = Enum.Font.Gotham, TextSize = 12,
			TextColor3 = Color3.fromRGB(140, 149, 172), Size = UDim2.new(1, -8, 0, 30),
			BackgroundTransparency = 1 }, PickerList)
	end
	PickerFrame.Visible = true
end

-- ---------- 黑洞：在前方生成一个吸引周围一切的球体 ----------
HolePart, HoleCore = nil, nil
function setBlackHole(on)
	State.BlackHole = on
	if not on then
		if HolePart then pcall(function() HolePart:Destroy() end) end
		if HoleCore then pcall(function() HoleCore:Destroy() end) end
		HolePart, HoleCore = nil, nil
		return
	end
	if not (HRP and HRP.Parent) then State.BlackHole = false; return end
	local pos = HRP.Position + horiz(Cam.CFrame.LookVector) * 18 + Vector3.new(0, 3, 0)
	HolePart = Instance.new("Part")
	HolePart.Name = "HonBlackHole"
	HolePart.Shape = Enum.PartType.Ball
	HolePart.Size = Vector3.new(10, 10, 10)
	HolePart.Material = Enum.Material.Neon
	HolePart.BrickColor = BrickColor.new("Really black")
	HolePart.Anchored = true
	HolePart.CanCollide = false
	HolePart.CFrame = CFrame.new(pos)
	HolePart.Parent = Workspace
	HoleCore = Instance.new("Part")
	HoleCore.Shape = Enum.PartType.Ball
	HoleCore.Size = Vector3.new(3, 3, 3)
	HoleCore.Material = Enum.Material.Neon
	HoleCore.BrickColor = BrickColor.new("Bright violet")
	HoleCore.Anchored = true
	HoleCore.CanCollide = false
	HoleCore.CFrame = CFrame.new(pos)
	HoleCore.Parent = Workspace
	if notify then notify("黑洞已生成，周围的东西会被吸过去") end
end

-- ---------- 甩飞所有玩家 ----------
function flingAll()
	local n = 0
	for _, pl in ipairs(Players:GetPlayers()) do
		if pl ~= LP and pl.Character then
			local hrp = pl.Character:FindFirstChild("HumanoidRootPart")
			if hrp then
				pcall(function()
					hrp.AssemblyLinearVelocity = Vector3.new(
						math.random(-1, 1) * 220, 320, math.random(-1, 1) * 220)
				end)
				n = n + 1
			end
		end
	end
	if notify then notify("已甩飞 " .. n .. " 名玩家") end
end

-- ---------- 闪电冲刺：瞬间向前冲一段并带雷电特效 ----------
function lightningDash()
	if not (HRP and HRP.Parent) then return end
	pcall(function()
		local dir = horiz(Cam.CFrame.LookVector)
		if HRP then HRP.CFrame = HRP.CFrame + dir * 60 end
		local att = Instance.new("Part")
		att.Size = Vector3.new(1, 1, 1)
		att.Anchored = true
		att.CanCollide = false
		att.Transparency = 1
		att.CFrame = HRP.CFrame
		att.Parent = Workspace
		local pe = Instance.new("ParticleEmitter")
		pe.Color = ColorSequence.new(Color3.fromRGB(120, 200, 255))
		pe.LightEmission = 1
		pe.Rate = 0
		pe.Lifetime = NumberRange.new(0.4)
		pe.Speed = NumberRange.new(40)
		pe.Parent = att
		pe:Emit(60)
		tspawn(function()
			twait(1.2)
			if att and att.Parent then att:Destroy() end
		end)
	end)
	if notify then notify("闪电冲刺！") end
end

-- ---------- 无敌少侠飞行：超人姿势飞行 ----------
function setHeroFly(on)
	State.HeroFly = on
	if on then
		setFly(true)
		pcall(function()
			if Humanoid then Humanoid.PlatformStand = true end
			if FlyOrient then
				FlyOrient.CFrame = Cam.CFrame * CFrame.Angles(math.rad(-70), 0, 0)
			end
		end)
	else
		setFly(false)
	end
end

-- ---------- FE 变车：角色变成车（客户端可见，本体同步）----------
CarModel = nil
function setCar(on)
	State.Car = on
	if not on then
		if CarModel then pcall(function() CarModel:Destroy() end) end
		CarModel = nil
		local c = LP.Character
		if c then
			for _, q in ipairs(c:GetDescendants()) do
				if q:IsA("BasePart") then pcall(function() q.Transparency = 0 end) end
			end
		end
		return
	end
	if not (HRP and HRP.Parent) then State.Car = false; return end
	pcall(function()
		local c = LP.Character
		for _, q in ipairs(c:GetDescendants()) do
			if q:IsA("BasePart") and q.Name ~= "HumanoidRootPart" then
				q.Transparency = 1
			end
		end
		CarModel = Instance.new("Model")
		CarModel.Name = "HonCar"
		local body = Instance.new("Part")
		body.Size = Vector3.new(4, 2, 8)
		body.Material = Enum.Material.SmoothPlastic
		body.BrickColor = BrickColor.new("Bright red")
		body.Anchored = true
		body.CanCollide = false
		body.Parent = CarModel
		local roof = Instance.new("Part")
		roof.Size = Vector3.new(3.4, 1.6, 4)
		roof.Material = Enum.Material.SmoothPlastic
		roof.BrickColor = BrickColor.new("Bright blue")
		roof.Anchored = true
		roof.CanCollide = false
		roof.Parent = CarModel
		for i = 0, 1 do
			for j = 0, 1 do
				local w = Instance.new("Part")
				w.Shape = Enum.PartType.Cylinder
				w.Size = Vector3.new(1.6, 1, 1.6)
				w.Material = Enum.Material.SmoothPlastic
				w.BrickColor = BrickColor.new("Really black")
				w.Anchored = true
				w.CanCollide = false
				w.Parent = CarModel
			end
		end
		CarModel.Parent = Workspace
	end)
end

-- ---------- 强制第三人称 ----------
function setThirdPerson(on)
	State.ThirdPerson = on
	pcall(function()
		if on then
			if Humanoid then Humanoid.CameraOffset = Vector3.new(0, 1.5, 0) end
			LP.CameraMode = Enum.CameraMode.Classic
			LP.CameraMaxZoomDistance = 25
			LP.CameraMinZoomDistance = 12
		else
			if Humanoid then Humanoid.CameraOffset = Vector3.new(0, 0, 0) end
			LP.CameraMinZoomDistance = 0.5
			LP.CameraMaxZoomDistance = 400
		end
	end)
end

-- ---------- 隐藏身上的小方块 / 附加装饰 ----------
-- 身体变透明后，配件 Handle、ESP 的 Adornment 框、贴花、名牌等附加物会露出来变成小方块。
-- 这里扫描角色，把所有「非原生身体部件」一次性隐藏，并可每 0.5 秒持续维持。
BODY_NATIVE = {
	Head = true, Torso = true, UpperTorso = true, LowerTorso = true, HumanoidRootPart = true,
	LeftArm = true, RightArm = true, LeftLeg = true, RightLeg = true,
	LeftUpperArm = true, RightUpperArm = true, LeftLowerArm = true, RightLowerArm = true,
	LeftUpperLeg = true, RightUpperLeg = true, LeftLowerLeg = true, RightLowerLeg = true,
	LeftHand = true, RightHand = true, LeftFoot = true, RightFoot = true,
}
BlockTimer = 0
function hideBodyBlocks(deep)
	local c = LP.Character
	if not c then return 0 end
	local n = 0
	for _, d in ipairs(c:GetDescendants()) do
		if d:IsA("BasePart") then
			if not BODY_NATIVE[d.Name] and d.Transparency < 1 then
				d.Transparency = 1; n = n + 1
			end
		elseif d:IsA("SelectionBox") or d:IsA("BoxHandleAdornment") or d:IsA("CylinderHandleAdornment")
			or d:IsA("ConeHandleAdornment") or d:IsA("SphereHandleAdornment") or d:IsA("LineHandleAdornment") then
			if d.Visible ~= false then d.Visible = false; n = n + 1 end
		elseif d:IsA("BillboardGui") or d:IsA("SurfaceGui") then
			if d.Enabled ~= false then d.Enabled = false; n = n + 1 end
		elseif d:IsA("Decal") or d:IsA("Texture") then
			if d.Transparency < 1 then d.Transparency = 1; n = n + 1 end
		end
	end
	if deep then
		local ok = pcall(function()
			for _, d in ipairs(Workspace:GetDescendants()) do
				if d:IsA("SelectionBox") or d:IsA("BoxHandleAdornment") or d:IsA("CylinderHandleAdornment")
					or d:IsA("SphereHandleAdornment") or d:IsA("ConeHandleAdornment") or d:IsA("LineHandleAdornment") then
					local ad = d.Adornee
					if ad and ad:IsDescendantOf(c) and d.Visible ~= false then
						d.Visible = false; n = n + 1
					end
				end
			end
		end)
	end
	return n
end

-- ---------- 装扮：翅膀 + 头顶光环（客户端可见，只有你自己看得见）----------
WING_STYLES = {
	{ name = "天使白翼", c1 = Color3.fromRGB(250, 252, 255), c2 = Color3.fromRGB(205, 222, 255), neon = false },
	{ name = "堕天黑翼", c1 = Color3.fromRGB(26, 26, 34),    c2 = Color3.fromRGB(130, 24, 34),   neon = false },
	{ name = "恶魔蝠翼", c1 = Color3.fromRGB(38, 18, 48),    c2 = Color3.fromRGB(160, 30, 60),   neon = false },
	{ name = "光之翼",   c1 = Color3.fromRGB(255, 242, 190), c2 = Color3.fromRGB(255, 205, 100), neon = true },
	{ name = "凤凰火翼", c1 = Color3.fromRGB(255, 130, 40),  c2 = Color3.fromRGB(255, 60, 20),   neon = true },
	{ name = "机械光翼", c1 = Color3.fromRGB(160, 190, 220), c2 = Color3.fromRGB(90, 205, 255),  neon = true },
}
HALO_STYLES = {
	{ name = "蓝白光环", c = Color3.fromRGB(150, 212, 255) },
	{ name = "金光环",   c = Color3.fromRGB(255, 216, 120) },
	{ name = "粉光环",   c = Color3.fromRGB(255, 165, 205) },
	{ name = "紫光环",   c = Color3.fromRGB(195, 145, 255) },
	{ name = "彩虹光环", c = nil },
}
WingParts, HaloPart = {}, nil
WingIdx, HaloIdx = 0, 0
WingSizeV, HaloSizeV, HaloTiltV = 1, 1, 0

function clearWings()
	for _, d in ipairs(WingParts) do pcall(function() d.P:Destroy() end) end
	WingParts = {}
	WingIdx = 0
end

function setWing(idx)
	clearWings()
	if not idx or idx <= 0 then return end
	local st = WING_STYLES[idx]
	if not st then return end
	if not (HRP and HRP.Parent) then return end
	WingIdx = idx
	local mat = st.neon and Enum.Material.Neon or Enum.Material.SmoothPlastic
	for side = -1, 1, 2 do
		for i = 0, 6 do
			local f = i / 6
			local len = 3.2 - f * 1.6
			local p = Instance.new("Part")
			p.Name = "HonWing"
			p.Size = Vector3.new(0.14, len, 1.0 - f * 0.45)
			p.Material = mat
			p.Color = (i % 2 == 0) and st.c1 or st.c2
			p.Anchored = true
			p.CanCollide = false
			p.CastShadow = false
			p.Transparency = st.neon and 0.15 or 0
			p.Parent = Workspace
			local ang = math.rad(-16 + f * 78)
			local off = CFrame.new(side * (0.55 + f * 1.15), 0.85 - f * 0.75, -0.15 - f * 0.25)
				* CFrame.Angles(0, 0, side * -ang) * CFrame.Angles(math.rad(-8), 0, 0)
			table.insert(WingParts, { P = p, Off = off, Side = side, F = f })
		end
	end
	if notify then notify("已装备：" .. st.name) end
end

function setHalo(idx)
	if HaloPart then pcall(function() HaloPart:Destroy() end); HaloPart = nil end
	HaloIdx = idx or 0
	if HaloIdx <= 0 then return end
	local st = HALO_STYLES[HaloIdx]
	if not st then return end
	HaloPart = Instance.new("Part")
	HaloPart.Name = "HonHalo"
	HaloPart.Shape = Enum.PartType.Torus
	HaloPart.Size = Vector3.new(3.2, 0.32, 3.2)
	HaloPart.Material = Enum.Material.Neon
	HaloPart.Color = st.c or Color3.fromRGB(255, 255, 255)
	HaloPart.Anchored = true
	HaloPart.CanCollide = false
	HaloPart.CastShadow = false
	HaloPart.Parent = Workspace
	if notify then notify("已装备：" .. st.name) end
end

-- ---------- 彩虹拖尾：角色上下两个挂点拉出彩色光带 ----------
TrailObj, TrailA0, TrailA1 = nil, nil, nil
function setTrail(on)
	if not on then
		if TrailObj then pcall(function() TrailObj:Destroy() end) end
		if TrailA0 then pcall(function() TrailA0:Destroy() end) end
		if TrailA1 then pcall(function() TrailA1:Destroy() end) end
		TrailObj, TrailA0, TrailA1 = nil, nil, nil
		return
	end
	if not (HRP and HRP.Parent) then State.Trail = false; return end
	pcall(function()
		TrailA0 = Instance.new("Attachment")
		TrailA0.Position = Vector3.new(0, -2.2, 0)
		TrailA0.Parent = HRP
		TrailA1 = Instance.new("Attachment")
		TrailA1.Position = Vector3.new(0, 2.2, 0)
		TrailA1.Parent = HRP
		TrailObj = Instance.new("Trail")
		TrailObj.Attachment0 = TrailA0
		TrailObj.Attachment1 = TrailA1
		TrailObj.Color = ColorSequence.new(Color3.fromRGB(255, 60, 60), Color3.fromRGB(80, 220, 255))
		TrailObj.Lifetime = 0.7
		TrailObj.MinLength = 0.1
		TrailObj.LightEmission = 1
		TrailObj.WidthScale = NumberSequence.new(1.4)
		TrailObj.Parent = HRP
	end)
end

-- ---------- 分身军团：克隆自己，围成一圈跟随 ----------
Clones = {}
function setCloneArmy(on)
	if not on then
		for _, c in ipairs(Clones) do pcall(function() c:Destroy() end) end
		Clones = {}
		return
	end
	local c = LP.Character
	if not (c and HRP and HRP.Parent) then State.CloneArmy = false; return end
	for i = 1, 5 do
		pcall(function()
			local cl = c:Clone()
			cl.Name = "HonClone" .. tostring(i)
			cl.Parent = Workspace
			for _, d in ipairs(cl:GetDescendants()) do
				if d:IsA("Script") or d:IsA("LocalScript") then d:Destroy() end
				if d:IsA("BasePart") then d.Transparency = 0.5; d.CanCollide = false; d.CastShadow = false end
			end
			local chr = cl:FindFirstChild("HumanoidRootPart")
			if chr then chr.Anchored = true end
			local hum = cl:FindFirstChildOfClass("Humanoid")
			if hum then hum.Health = math.huge; hum.WalkSpeed = 0; hum.JumpPower = 0 end
			table.insert(Clones, cl)
		end)
	end
	if notify then notify("分身军团：已生成 " .. #Clones .. " 个分身") end
end

-- ---------- 粒子环绕：角色身边一颗旋转的发光粒子球 ----------
OrbitPart = nil
function setOrbitFx(on)
	if not on then
		if OrbitPart then pcall(function() OrbitPart:Destroy() end) end
		OrbitPart = nil
		return
	end
	pcall(function()
		OrbitPart = Instance.new("Part")
		OrbitPart.Name = "HonOrbitFx"
		OrbitPart.Size = Vector3.new(0.6, 0.6, 0.6)
		OrbitPart.Anchored = true
		OrbitPart.CanCollide = false
		OrbitPart.Transparency = 1
		OrbitPart.Parent = Workspace
		local pe = Instance.new("ParticleEmitter")
		pe.Color = ColorSequence.new(Mode().Accent)
		pe.LightEmission = 1
		pe.LightInfluence = 0
		pe.Rate = 220
		pe.Lifetime = NumberRange.new(0.7)
		pe.Speed = NumberRange.new(7)
		pe.Size = NumberSequence.new(0.5)
		pe.Parent = OrbitPart
	end)
end

-- ---------- 让所有人跳舞 ----------
DANCE_IDS = { "rbxassetid://507776043", "rbxassetid://507771019", "rbxassetid://507770453", "rbxassetid://507770239" }
function danceAll()
	local n = 0
	for _, pl in ipairs(Players:GetPlayers()) do
		local ch = pl.Character
		local hum = ch and ch:FindFirstChildOfClass("Humanoid")
		if hum then
			pcall(function()
				local anim = Instance.new("Animation")
				anim.AnimationId = DANCE_IDS[(i % #DANCE_IDS) + 1]
				local track = hum:LoadAnimation(anim)
				track.Looped = true
				track:Play()
			end)
			n = n + 1
		end
	end
	if notify then notify("已让 " .. n .. " 人开始跳舞") end
end

-- ---------- 装扮页 UI ----------
label({ Text = "翅 膀 WINGS", Font = Enum.Font.GothamBold, TextSize = 11,
	TextColor3 = Color3.fromRGB(120, 129, 152), Size = UDim2.new(1, 0, 0, 18),
	Position = UDim2.new(0, 2, 0, 0), TextXAlignment = Enum.TextXAlignment.Left }, PageDeco)
for i, st in ipairs(WING_STYLES) do
	local col = (i - 1) % 2
	local row = math.floor((i - 1) / 2)
	local b = new("TextButton", { Text = st.name, Font = Enum.Font.GothamBold, TextSize = 11,
		TextColor3 = Mode().Accent, BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.9, BorderSizePixel = 0, AutoButtonColor = false,
		Size = UDim2.new(0.5, -4, 0, 34),
		Position = UDim2.new(col == 0 and 0 or 0.5, col == 0 and 0 or 4, 0, 24 + row * 40),
		Parent = PageDeco })
	corner(b, 8)
	table.insert(FunBtns, b)
	bindClick(b, st.name, function() setWing(i) end)
end
local NoWingBtn = new("TextButton", { Text = "收起翅膀", Font = Enum.Font.GothamBold, TextSize = 11,
	TextColor3 = Color3.fromRGB(255, 108, 118), BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	BackgroundTransparency = 0.9, BorderSizePixel = 0, AutoButtonColor = false,
	Size = UDim2.new(1, 0, 0, 32), Position = UDim2.new(0, 0, 0, 144), Parent = PageDeco })
corner(NoWingBtn, 8)
table.insert(FunBtns, NoWingBtn)
bindClick(NoWingBtn, "收起翅膀", function() clearWings() end)

label({ Text = "头 顶 光 环 HALO（蔚蓝档案式）", Font = Enum.Font.GothamBold, TextSize = 11,
	TextColor3 = Color3.fromRGB(120, 129, 152), Size = UDim2.new(1, 0, 0, 18),
	Position = UDim2.new(0, 2, 0, 190), TextXAlignment = Enum.TextXAlignment.Left }, PageDeco)
for i, st in ipairs(HALO_STYLES) do
	local col = (i - 1) % 2
	local row = math.floor((i - 1) / 2)
	local b = new("TextButton", { Text = st.name, Font = Enum.Font.GothamBold, TextSize = 11,
		TextColor3 = st.c or Color3.fromRGB(255, 255, 255), BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.9, BorderSizePixel = 0, AutoButtonColor = false,
		Size = UDim2.new(0.5, -4, 0, 34),
		Position = UDim2.new(col == 0 and 0 or 0.5, col == 0 and 0 or 4, 0, 214 + row * 40),
		Parent = PageDeco })
	corner(b, 8)
	table.insert(FunBtns, b)
	bindClick(b, st.name, function() setHalo(i) end)
end
local NoHaloBtn = new("TextButton", { Text = "收起光环", Font = Enum.Font.GothamBold, TextSize = 11,
	TextColor3 = Color3.fromRGB(255, 108, 118), BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	BackgroundTransparency = 0.9, BorderSizePixel = 0, AutoButtonColor = false,
	Size = UDim2.new(1, 0, 0, 32), Position = UDim2.new(0, 0, 0, 334), Parent = PageDeco })
corner(NoHaloBtn, 8)
table.insert(FunBtns, NoHaloBtn)
bindClick(NoHaloBtn, "收起光环", function() setHalo(0) end)

makeSlider(PageDeco, "翅膀大小", 380, 40, 220, 100, " %", function(v) WingSizeV = v / 100 end, false)
makeSlider(PageDeco, "光环大小", 436, 40, 220, 100, " %", function(v) HaloSizeV = v / 100 end, false)
makeSlider(PageDeco, "光环角度", 492, 0, 90, 0, " °", function(v) HaloTiltV = v end, false)
label({ Text = "光环角度用来调平躺 / 竖立，戴歪了就调它", Font = Enum.Font.Gotham, TextSize = 10,
	TextColor3 = Color3.fromRGB(120, 129, 152), Position = UDim2.new(0, 2, 0, 548),
	Size = UDim2.new(1, -4, 0, 26), TextWrapped = true,
	TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top }, PageDeco)

-- ---------- 独立飞行 / 自动连跳 ----------
-- 之前这两项写在引擎主循环里，一旦「启用引擎」关闭就整段不执行 → 表现为「开了没用」。
-- 现在独立成一条渲染循环，不受引擎开关影响。
RunService:BindToRenderStep("HonFlyJump", 9994, function(dt)
	if not (HRP and HRP.Parent) then return end
	if State.Fly then
		if not (FlyVel and FlyVel.Parent) then pcall(buildFlyParts) end
		local spd = State.FlySpeed or 60
		local v = Vector3.zero
		local md = (Humanoid and Humanoid.Parent) and Humanoid.MoveDirection or Vector3.zero
		if md.Magnitude > 0.05 then
			v = v + Vector3.new(md.X, 0, md.Z).Unit * spd
		end
		local up, down = false, false
		pcall(function()
			if UserInputService:IsKeyDown(Enum.KeyCode.E) or UserInputService:IsKeyDown(Enum.KeyCode.Space) then up = true end
			if UserInputService:IsKeyDown(Enum.KeyCode.Q) or UserInputService:IsKeyDown(Enum.KeyCode.LeftCtrl) then down = true end
		end)
		if FlyUp then up = true end
		if FlyDown then down = true end
		if up then v = v + Vector3.new(0, spd, 0) end
		if down then v = v - Vector3.new(0, spd, 0) end
		if v.Magnitude < 0.1 then
			if not FlyHoldY then FlyHoldY = HRP.Position.Y end
			v = Vector3.new(0, math.clamp((FlyHoldY - HRP.Position.Y) * 8, -spd, spd), 0)
		else
			FlyHoldY = HRP.Position.Y
		end
		if FlyVel then FlyVel.VectorVelocity = v end
		if FlyOrient then FlyOrient.CFrame = Cam.CFrame end
	end
	if State.AutoJump and Humanoid and Humanoid.Parent then
		if Humanoid.FloorMaterial ~= Enum.Material.Air and not State.Fly then
			Humanoid.Jump = true
		end
	end
end)

-- ---------- 通用：让任意触屏控件「点哪个就能拖哪个」 ----------
DraggableMap = {}
function makeDraggable(obj)
	if not obj or DraggableMap[obj] then return end
	DraggableMap[obj] = true
	local dragging, startPos, startMouse = false, nil, nil
	obj.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			if State.TouchLocked then return end
			dragging, startPos, startMouse = true, obj.Position, i.Position
		end
	end)
	obj.InputChanged:Connect(function(i)
		if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
			local d = i.Position - startMouse
			obj.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
				startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end
	end)
	obj.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
end
function applyTouchDrag()
	pcall(function() for _, o in ipairs(NumBtns) do makeDraggable(o.Btn or o) end end)
	pcall(function() for _, o in ipairs(PadBtns) do makeDraggable(o.Btn or o) end end)
	pcall(function() if PadFrame then makeDraggable(PadFrame) end end)
end

-- ---------- 通用确认弹窗 ----------
ConfirmFrame, ConfirmTitleL, ConfirmDescL, ConfirmYesCb = nil, nil, nil, nil
function askConfirm(title, desc, yesText, onYes)
	if not ConfirmFrame then
		ConfirmFrame = new("Frame", { Name = "HonConfirm", Size = UDim2.new(0, 396, 0, 200),
			Position = UDim2.new(0.5, -198, 0.5, -100), BackgroundColor3 = Color3.fromRGB(16, 18, 27),
			BackgroundTransparency = 0.02, BorderSizePixel = 0, Visible = false, Parent = Gui })
		corner(ConfirmFrame, 14)
		new("UIStroke", { Color = Color3.fromRGB(255, 255, 255), Transparency = 0.9, Thickness = 1, Parent = ConfirmFrame })
		ConfirmTitleL = label({ Text = "", Font = Enum.Font.GothamBold, TextSize = 14,
			TextColor3 = Color3.fromRGB(232, 237, 248), BackgroundTransparency = 1,
			Size = UDim2.new(1, -32, 0, 22), Position = UDim2.new(0, 16, 0, 12),
			TextXAlignment = Enum.TextXAlignment.Left }, ConfirmFrame)
		ConfirmDescL = label({ Text = "", Font = Enum.Font.Gotham, TextSize = 11,
			TextColor3 = Color3.fromRGB(168, 176, 196), BackgroundTransparency = 1,
			Size = UDim2.new(1, -32, 0, 74), Position = UDim2.new(0, 16, 0, 38),
			TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top }, ConfirmFrame)
		ConfirmYesBtn = new("TextButton", { Text = "确认", Font = Enum.Font.GothamBold, TextSize = 12,
			TextColor3 = Color3.fromRGB(255, 255, 255), BackgroundColor3 = Mode().Accent,
			BackgroundTransparency = 0.1, BorderSizePixel = 0, AutoButtonColor = false,
			Size = UDim2.new(0.5, -20, 0, 34), Position = UDim2.new(0, 16, 0, 140), Parent = ConfirmFrame })
		corner(ConfirmYesBtn, 8)
		ConfirmNoBtn = new("TextButton", { Text = "取消", Font = Enum.Font.GothamBold, TextSize = 12,
			TextColor3 = Color3.fromRGB(190, 198, 220), BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 0.9, BorderSizePixel = 0, AutoButtonColor = false,
			Size = UDim2.new(0.5, -20, 0, 34), Position = UDim2.new(0.5, 4, 0, 140), Parent = ConfirmFrame })
		corner(ConfirmNoBtn, 8)
		ConfirmNoBtn.MouseButton1Click:Connect(function()
			ConfirmFrame.Visible = false; ConfirmYesCb = nil
		end)
		ConfirmYesBtn.MouseButton1Click:Connect(function()
			ConfirmFrame.Visible = false
			if ConfirmYesCb then pcall(ConfirmYesCb) end
			ConfirmYesCb = nil
		end)
	end
	ConfirmTitleL.Text = title or "确认"
	ConfirmDescL.Text = desc or ""
	ConfirmYesBtn.Text = yesText or "确认"
	ConfirmYesCb = onYes
	ConfirmFrame.Visible = true
end

-- ---------- 通用玩家选择面板 ----------
PickerFrame, PickerList, PickCb, PickCancel = nil, nil, nil, nil
function openPlayerPicker(cb, onCancel, titleTxt)
	if not PickerFrame then
		PickerFrame = new("Frame", { Name = "HonPicker", Size = UDim2.new(0, 320, 0, 360),
			Position = UDim2.new(0.5, -160, 0.5, -180), BackgroundColor3 = Color3.fromRGB(15, 17, 26),
			BackgroundTransparency = 0.02, BorderSizePixel = 0, Visible = false, Parent = Gui })
		corner(PickerFrame, 14)
		new("UIStroke", { Color = Mode().Accent, Transparency = 0.7, Thickness = 1, Parent = PickerFrame })
		PickerTitleL = label({ Text = "选择玩家", Font = Enum.Font.GothamBold, TextSize = 13,
			TextColor3 = Color3.fromRGB(232, 237, 248), BackgroundTransparency = 1,
			Size = UDim2.new(1, -60, 0, 22), Position = UDim2.new(0, 16, 0, 12),
			TextXAlignment = Enum.TextXAlignment.Left }, PickerFrame)
		local pclose = new("TextButton", { Text = "×", Font = Enum.Font.GothamBold, TextSize = 16,
			TextColor3 = Color3.fromRGB(255, 108, 118), BackgroundTransparency = 1,
			Size = UDim2.new(0, 28, 0, 28), Position = UDim2.new(1, -36, 0, 8), Parent = PickerFrame })
		pclose.MouseButton1Click:Connect(function()
			PickerFrame.Visible = false
			if PickCancel then pcall(PickCancel) end
			PickCancel = nil
		end)
		PickerList = new("ScrollingFrame", { Size = UDim2.new(1, -16, 0, 300), Position = UDim2.new(0, 8, 0, 44),
			BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4,
			ScrollBarImageTransparency = 0.5, CanvasSize = UDim2.new(0, 0, 0, 0), Parent = PickerFrame })
		new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = PickerList })
	end
	PickerTitleL.Text = titleTxt or "选择玩家"
	PickCancel = onCancel
	for _, c in ipairs(PickerList:GetChildren()) do
		if c:IsA("TextButton") then pcall(function() c:Destroy() end) end
	end
	local n = 0
	for _, pl in ipairs(Players:GetPlayers()) do
		local b = new("TextButton", { Text = (pl == LP) and ("我自己 · " .. pl.Name) or (pl.DisplayName .. "  @" .. pl.Name),
			Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = Color3.fromRGB(220, 228, 245),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.92,
			BorderSizePixel = 0, AutoButtonColor = false,
			Size = UDim2.new(1, -8, 0, 34), Parent = PickerList })
		corner(b, 8)
		b.MouseButton1Click:Connect(function()
			PickerFrame.Visible = false
			if cb then pcall(cb, pl) end
		end)
		n = n + 1
	end
	PickerList.CanvasSize = UDim2.new(0, 0, 0, n * 40 + 8)
	PickerFrame.Visible = true
end

-- ---------- 屏幕上方：已开启功能横排 1 2 3 ----------
TopBarFrame, TopBarLabel, TopBarTimer = nil, nil, 0
function updateTopBar()
	if not TopBarFrame then
		TopBarFrame = new("Frame", { Name = "HonTopBar", Size = UDim2.new(0, 560, 0, 28),
			Position = UDim2.new(0.5, -280, 0, 6), BackgroundColor3 = Color3.fromRGB(13, 15, 23),
			BackgroundTransparency = 0.28, BorderSizePixel = 0, Visible = false, Parent = Gui })
		corner(TopBarFrame, 10)
		new("UIStroke", { Color = Mode().Accent, Transparency = 0.7, Thickness = 1, Parent = TopBarFrame })
		TopBarLabel = label({ Text = "", Font = Enum.Font.GothamBold, TextSize = 11,
			TextColor3 = Mode().Accent, BackgroundTransparency = 1, Size = UDim2.new(1, -16, 0, 24),
			Position = UDim2.new(0, 8, 0, 2), TextXAlignment = Enum.TextXAlignment.Left }, TopBarFrame)
	end
	local list = {}
	if State.Enabled then table.insert(list, "加速") end
	if State.Fly then table.insert(list, "飞行") end
	if State.Noclip then table.insert(list, "穿墙") end
	if State.InfJump then table.insert(list, "无限跳") end
	if State.AutoJump then table.insert(list, "连跳") end
	if State.Orbit then table.insert(list, "环绕") end
	if State.BlackHole then table.insert(list, "黑洞") end
	if State.Car then table.insert(list, "变车") end
	if State.HeroFly then table.insert(list, "少侠") end
	if State.Trail then table.insert(list, "拖尾") end
	if State.CloneArmy then table.insert(list, "分身") end
	if State.HeadRide then table.insert(list, "骑头") end
	if State.EspPlayer then table.insert(list, "透视") end
	if State.Rainbow then table.insert(list, "彩虹") end
	if State.Spin then table.insert(list, "自转") end
	if State.Freecam then table.insert(list, "自由视角") end
	if #list > 0 then
		local parts = {}
		for i, nm in ipairs(list) do parts[i] = tostring(i) .. " " .. nm end
		TopBarLabel.Text = table.concat(parts, "   ")
		TopBarFrame.Visible = true
	else
		TopBarFrame.Visible = false
	end
end

-- ---------- 分身独立面板（屏幕左上角，可拖）----------
ClonePanel = nil
function buildClonePanel()
	if ClonePanel then return end
	ClonePanel = new("Frame", { Name = "HonClonePanel", Size = UDim2.new(0, 226, 0, 196),
		Position = UDim2.new(0, 16, 0.5, -98), BackgroundColor3 = Color3.fromRGB(15, 17, 26),
		BackgroundTransparency = 0.04, BorderSizePixel = 0, Visible = false, Parent = Gui })
	corner(ClonePanel, 12)
	new("UIStroke", { Color = Mode().Accent, Transparency = 0.7, Thickness = 1, Parent = ClonePanel })
	label({ Text = "分 身 军 团", Font = Enum.Font.GothamBold, TextSize = 12,
		TextColor3 = Color3.fromRGB(232, 237, 248), BackgroundTransparency = 1,
		Size = UDim2.new(1, -60, 0, 20), Position = UDim2.new(0, 12, 0, 8),
		TextXAlignment = Enum.TextXAlignment.Left }, ClonePanel)
	local cbtn = new("TextButton", { Text = "×", Font = Enum.Font.GothamBold, TextSize = 14,
		TextColor3 = Color3.fromRGB(255, 108, 118), BackgroundTransparency = 1,
		Size = UDim2.new(0, 24, 0, 24), Position = UDim2.new(1, -30, 0, 6), Parent = ClonePanel })
	cbtn.MouseButton1Click:Connect(function() ClonePanel.Visible = false end)
	makeDraggable(ClonePanel)
	local function mk(txt, y, col, cb)
		local b = new("TextButton", { Text = txt, Font = Enum.Font.GothamBold, TextSize = 11,
			TextColor3 = col, BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 0.9, BorderSizePixel = 0, AutoButtonColor = false,
			Size = UDim2.new(1, -24, 0, 32), Position = UDim2.new(0, 12, 0, y), Parent = ClonePanel })
		corner(b, 8)
		b.MouseButton1Click:Connect(cb)
		return b
	end
	mk("环绕跟随（开/关）", 34, Mode().Accent, function()
		State.CloneArmy = not State.CloneArmy
		setCloneArmy(State.CloneArmy)
		if notify then notify(State.CloneArmy and "分身：环绕跟随已开" or "分身：环绕已关") end
	end)
	mk("在脚下放置分身", 70, Color3.fromRGB(150, 220, 255), function()
		if not (HRP and HRP.Parent) then return end
		pcall(function()
			local c = LP.Character
			if not c then return end
			local cl = c:Clone()
			cl.Name = "HonCloneFoot"
			cl.Parent = Workspace
			for _, d in ipairs(cl:GetDescendants()) do
				if d:IsA("Script") or d:IsA("LocalScript") then d:Destroy() end
				if d:IsA("BasePart") then d.Transparency = 0.5; d.CanCollide = false; d.CastShadow = false end
			end
			local cr = cl:FindFirstChild("HumanoidRootPart")
			if cr then cr.Anchored = true; cr.CFrame = HRP.CFrame end
			local hum = cl:FindFirstChildOfClass("Humanoid")
			if hum then hum.Health = math.huge; hum.WalkSpeed = 0; hum.JumpPower = 0 end
			table.insert(Clones, cl)
		end)
		if notify then notify("已在脚下放置一个分身（共 " .. #Clones .. " 个）") end
	end)
	mk("删除所有分身", 106, Color3.fromRGB(255, 120, 130), function()
		for _, c in ipairs(Clones) do pcall(function() c:Destroy() end) end
		Clones = {}
		State.CloneArmy = false
		if CloneTgl then CloneTgl.Set(false, true) end
		if notify then notify("已删除所有分身") end
	end)
	label({ Text = "数量：" .. #Clones .. " · 分身只有你自己看得见",
		Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = Color3.fromRGB(130, 139, 160),
		BackgroundTransparency = 1, Size = UDim2.new(1, -24, 0, 30), Position = UDim2.new(0, 12, 0, 144),
		TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top }, ClonePanel)
end

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
		-- 除了我们自己的，全部收起来（包括注入器在 Roblox 内建的界面）
		if g:IsA("ScreenGui") and g ~= Gui and g.Enabled then
			g.Enabled = false
			table.insert(StealthHiddenGui, g)
		end
	end
	-- 有些注入器把图标做成 CoreGui 里的东西，这里也一并尝试隐藏
	pcall(function() StarterGui:SetCore("TopbarEnabled", false) end)
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
-- ---------- 隐身录屏：冻结除「加速」外的所有功能，退出后原样恢复 ----------
StealthFrozen = nil
function stealthFreeze()
	if StealthFrozen then return end
	StealthFrozen = {}
	for _, t in ipairs(ToggleRegistry) do
		if t._last and not t._keep then
			table.insert(StealthFrozen, t)
			pcall(function() t.Set(false, false) end)
		end
	end
	return #StealthFrozen
end
function stealthRestore()
	if not StealthFrozen then return end
	local n = #StealthFrozen
	for _, t in ipairs(StealthFrozen) do
		pcall(function() t.Set(true, false) end)
	end
	StealthFrozen = nil
	return n
end

function setStealth(on)
	State.Stealth = on
	buildStealthBall()
	if on then
		local n = stealthFreeze()
		stealthHideOwn()
		if State.StealthHideGame then stealthHideGame() end
		if StealthBall then StealthBall.Visible = true end
		stealthTime, stealthAcc = 0, 0
		if notify then notify("隐身录屏开启 · 已暂停 " .. n .. " 个功能（加速保持运行）") end
	else
		local n = stealthRestore()
		stealthShowOwn()
		if State.StealthHideGame then stealthShowGame() end
		if StealthBall then StealthBall.Visible = false end
		if notify then notify("已恢复界面 · 并恢复 " .. n .. " 个功能") end
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
-- ---------- 新功能的每帧驱动（黑洞 / 变车 / 防摔落 / HUD 附加信息）----------
pcall(function() RunService:UnbindFromRenderStep("HonFunLoop") end)
RunService:BindToRenderStep("HonFunLoop", 9995, function(dt)
	if State.BlackHole and HoleCore and HoleCore.Parent then
		local c = HoleCore.Position
		local f = State.BlackHoleForce or 60
		for _, pl in ipairs(Players:GetPlayers()) do
			local ch = pl.Character
			local h = ch and ch:FindFirstChild("HumanoidRootPart")
			if h then
				local d = c - h.Position
				local m = d.Magnitude
				if m > 3 and m < 90 then
					pcall(function() h.AssemblyLinearVelocity = d.Unit * (f * (1 - m / 90) + 12) end)
				end
			end
		end
		pcall(function()
			HoleCore.CFrame = HoleCore.CFrame * CFrame.Angles(0, dt * 3, 0)
			local sz = 3 + math.sin(tick() * 4) * 0.35
			HoleCore.Size = Vector3.new(sz, sz, sz)
		end)
	end
	if State.Car and CarModel and CarModel.Parent and HRP and HRP.Parent then
		pcall(function()
			local parts = CarModel:GetChildren()
			if #parts >= 6 then
				parts[1].CFrame = HRP.CFrame * CFrame.new(0, 0.2, 0)
				parts[2].CFrame = HRP.CFrame * CFrame.new(0, 1.7, -0.6)
				parts[3].CFrame = HRP.CFrame * CFrame.new(-1.9, -0.8, 2.6) * CFrame.Angles(0, 0, math.rad(90))
				parts[4].CFrame = HRP.CFrame * CFrame.new(1.9, -0.8, 2.6) * CFrame.Angles(0, 0, math.rad(90))
				parts[5].CFrame = HRP.CFrame * CFrame.new(-1.9, -0.8, -2.6) * CFrame.Angles(0, 0, math.rad(90))
				parts[6].CFrame = HRP.CFrame * CFrame.new(1.9, -0.8, -2.6) * CFrame.Angles(0, 0, math.rad(90))
			end
		end)
	end
	-- 维持：角色重生或游戏重置后自动把功能接回来
	if State.Trail and not (TrailObj and TrailObj.Parent) then pcall(setTrail, true) end
	if State.CloneArmy and #Clones == 0 then pcall(setCloneArmy, true) end
	if State.OrbitFx and not (OrbitPart and OrbitPart.Parent) then pcall(setOrbitFx, true) end
	if State.HeroFly then
		if not State.Fly then pcall(setFly, true) end
		if Humanoid and Humanoid.Parent and not Humanoid.PlatformStand then Humanoid.PlatformStand = true end
	end
	if State.ThirdPerson then
		pcall(function()
			LP.CameraMode = Enum.CameraMode.Classic
			LP.CameraMinZoomDistance = 12
			LP.CameraMaxZoomDistance = 25
			if Humanoid and Humanoid.Parent then Humanoid.CameraOffset = Vector3.new(0, 1.5, 0) end
		end)
	end
	if State.LowFx then
		pcall(function()
			local lg = Lighting or game:GetService("Lighting")
			if lg.GlobalShadows then lg.GlobalShadows = false end
		end)
	end
	if WingIdx > 0 and #WingParts > 0 and HRP and HRP.Parent then
		pcall(function()
			local base = HRP.CFrame * CFrame.new(0, 0.4, 0.35)
			local flap = math.sin(tick() * 2.2) * 0.16
			for _, w in ipairs(WingParts) do
				local o = w.Off
				local swing = CFrame.Angles(0, 0, w.Side * flap * (0.4 + w.F))
				w.P.CFrame = base * o * swing
				w.P.Size = Vector3.new(0.14, (3.2 - w.F * 1.6) * WingSizeV, (1.0 - w.F * 0.45) * WingSizeV)
			end
		end)
	end
	if HaloPart and HaloPart.Parent then
		local head = LP.Character and LP.Character:FindFirstChild("Head")
		if head then
			pcall(function()
				local t = tick()
				local st = HALO_STYLES[HaloIdx]
				if st and st.c == nil then
					HaloPart.Color = Color3.fromHSV((t * 0.12) % 1, 0.75, 1)
				end
				HaloPart.Size = Vector3.new(3.2 * HaloSizeV, 0.32 * HaloSizeV, 3.2 * HaloSizeV)
				HaloPart.CFrame = head.CFrame * CFrame.new(0, 2.1 + math.sin(t * 1.6) * 0.12, 0)
					* CFrame.Angles(math.rad(HaloTiltV), t * 1.1, 0)
			end)
		end
	end
	TopBarTimer = (TopBarTimer or 0) + dt
	if TopBarTimer > 0.35 then
		TopBarTimer = 0
		pcall(updateTopBar)
	end
	opBarDone = true
	if State.NoFall and HRP and HRP.Parent then
		pcall(function()
			local v = HRP.AssemblyLinearVelocity
			if v.Y < -90 then
				HRP.AssemblyLinearVelocity = Vector3.new(v.X, -30, v.Z)
			end
		end)
	end
	if State.CloneArmy and #Clones > 0 and HRP and HRP.Parent then
		pcall(function()
			for i, cl in ipairs(Clones) do
				local cr = cl:FindFirstChild("HumanoidRootPart")
				if cr then
					local a = tick() * 1.4 + (i / #Clones) * math.pi * 2
					cr.CFrame = CFrame.new(HRP.Position + Vector3.new(math.cos(a) * 6.5, 0, math.sin(a) * 6.5)) * CFrame.Angles(0, -a, 0)
				end
			end
		end)
	end
	if State.OrbitFx and OrbitPart and OrbitPart.Parent and HRP and HRP.Parent then
		pcall(function()
			local a = tick() * 3
			OrbitPart.CFrame = CFrame.new(HRP.Position + Vector3.new(math.cos(a) * 3.4, 1.2 + math.sin(a * 2) * 0.5, math.sin(a) * 3.4))
		end)
	end
	if State.HeadRide and HRP and HRP.Parent then
		pcall(function()
			local best, bd = nil, math.huge
			for _, pl in ipairs(Players:GetPlayers()) do
				if pl ~= LP and pl.Character then
					local hd = pl.Character:FindFirstChild("Head")
					if hd then
						local d = (hd.Position - HRP.Position).Magnitude
						if d < bd then bd = d; best = hd end
					end
				end
			end
			if best and bd < 60 then
				HRP.CFrame = best.CFrame * CFrame.new(0, 2.4, 0)
				HRP.AssemblyLinearVelocity = Vector3.zero
				if Humanoid then Humanoid.PlatformStand = false end
			end
		end)
	end
	if State.SpinCam and HRP and HRP.Parent then
		pcall(function()
			local a = tick() * 1.1
			local pos = HRP.Position
			Cam.CFrame = CFrame.new(pos + Vector3.new(math.cos(a) * 14, 7, math.sin(a) * 14), pos)
		end)
	elseif State.Shake then
		pcall(function()
			Cam.CFrame = Cam.CFrame * CFrame.new((math.random() - 0.5) * 0.9, (math.random() - 0.5) * 0.9, 0)
		end)
	end
	if State.Magnet and HRP and HRP.Parent then
		MagnetTimer = (MagnetTimer or 0) + dt
		if MagnetTimer > 0.5 then
			MagnetTimer = 0
			pcall(function()
				local cnt = 0
				for _, obj in ipairs(Workspace:GetDescendants()) do
					if cnt >= 25 then break end
					local isItem = obj:IsA("Tool") or obj:FindFirstChildOfClass("ClickDetector") or obj:FindFirstChildOfClass("ProximityPrompt")
					if isItem then
						local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
						if part then
							local d = (part.Position - HRP.Position).Magnitude
							if d > 4 and d < 45 then
								part.CFrame = CFrame.new(part.Position + (HRP.Position - part.Position).Unit * 5)
								cnt = cnt + 1
							end
						end
					end
				end
			end)
		end
	end
	if HudSub and HudSub.Parent and (State.ShowHP or State.ShowFunList) then
		local extra = ""
		if State.ShowHP and Humanoid and Humanoid.Parent then
			extra = extra .. "  HP" .. math.floor(Humanoid.Health)
		end
		if State.ShowFunList then
			local on = {}
			if State.Fly then table.insert(on, "FLY") end
			if State.Noclip then table.insert(on, "NCLIP") end
			if State.InfJump then table.insert(on, "JUMP") end
			if State.EspPlayer then table.insert(on, "ESP") end
			if State.Spin then table.insert(on, "SPIN") end
			if State.Rainbow then table.insert(on, "RGB") end
			if State.BlackHole then table.insert(on, "HOLE") end
			if State.Car then table.insert(on, "CAR") end
			if #on > 0 then extra = extra .. "  " .. table.concat(on, "/") end
		end
		if extra ~= "" then
			pcall(function()
				local base = HudSub.Text
				local cut = base:find("  HP")
				if cut then base = base:sub(1, cut - 1) end
				HudSub.Text = base .. extra
			end)
		end
	end
end)

function step(name, fn)
	local ok, err = pcall(fn)
	if not ok then warn("[HON] 初始化步骤失败: " .. name .. " -> " .. tostring(err)) end
end
step("搜索索引", buildSearchIndex)
step("恢复UI布局", function() tspawn(uiRestore) end)
step("速度锁", function() SpeedSlider.SetLocked(false) end)
step("跳跃锁", function() JumpSlider.SetLocked(false) end)
step("切换页面", function() SetTab(1) end)
step("切换引擎", function() SetMode(1) end)
step("面板锁", function() applyPanelLock(false) end)
step("触屏可见", updateTouchVisibility)
-- 最后再强制切一次，确保只有当前页可见
SetTab(1)
pcall(applyTouchDrag)
pcall(updateTopBar)
-- 开场：神威空间扭曲展开
pcall(function() playOpenAnim() end)
tspawn(function()
	twait(2.9)
	if NoticeAuto then pcall(showNotice) end
end)
if InfoLabel then
	InfoLabel.Text = clockInfo() .. "  ·  " .. tostring(ExecutorName) .. "  ·  首次 " .. tostring(FirstUse)
end
tspawn(function()
	while true do
		twait(1)
		if not (InfoLabel and InfoLabel.Parent) then break end
		InfoLabel.Text = clockInfo() .. "  ·  " .. tostring(ExecutorName) .. "  ·  首次 " .. tostring(FirstUse)
	end
end)
-- 手机端触摸兜底（放在这里是因为此刻所有界面对象都已创建完成）
pcall(function()
	TabBar.InputBegan:Connect(function(i)
		if i.UserInputType ~= Enum.UserInputType.Touch and i.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
		local rel = i.Position - TabBar.AbsolutePosition + TabBar.CanvasPosition
		if rel.X < 0 or rel.X > TabBar.AbsoluteSize.X then return end
		local idx = math.floor((rel.Y - 10) / 44) + 1
		if idx >= 1 and idx <= 8 then SetTab(idx) end
	end)
end)
pcall(function()
	CardHolder.InputBegan:Connect(function(i)
		if i.UserInputType ~= Enum.UserInputType.Touch and i.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
		local rel = i.Position - CardHolder.AbsolutePosition
		if rel.X < 0 or rel.X > CardHolder.AbsoluteSize.X then return end
		local idx = math.floor(rel.Y / 60) + 1
		if idx >= 1 and idx <= 3 then SetMode(idx) end
	end)
end)
FlyWin.Visible = false
UpBtn.Visible, DownBtn.Visible = false, false
Main.Size = UDim2.new(0, 300, 0, 560)
Main.BackgroundTransparency = 1
TweenService:Create(Main, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
	Size = UDim2.new(0, PANEL_W, 0, PANEL_H), BackgroundTransparency = 0.05 }):Play()
TweenService:Create(Main, TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
	Position = UDim2.new(0.5, -PANEL_W / 2, 0.5, -PANEL_H / 2) }):Play()
print("[HON SPEED HUB] v5.20 已加载 · 完整文件约 4615 行 · 若你的脚本远大于此行数说明粘贴重复了")
