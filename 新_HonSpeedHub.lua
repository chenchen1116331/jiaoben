local _pr = (type(print) == "function") and print or (type(warn) == "function" and warn) or function() end
_pr("[HON SPEED HUB] 载入中 · v5.58 · 若只看到这一行说明文件在中途中断")
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
local ContentProvider = game:GetService("ContentProvider")
local HttpService     = game:GetService("HttpService")
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
	_pr("[HON SPEED HUB] 获取 PlayerGui 失败：请等游戏完全加载进服务器后再注入一次")
	return
end
if not Cam then
	_pr("[HON SPEED HUB] 获取 Camera 失败：请重新注入")
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
	InstantInteract = false, EspDepth = true, InputAnim = true, EspHpBarBg = true,
	ClickTP = false, SparkTP = false, AntiVoid = false, FakeChar = false, BodyTransp = 0, Fullbright = false, LowGravity = false, GravityValue = 40,
	Spin = false, Rainbow = false, Bounce = false, Orbit = false, LowFx = false,
	PlayDead = false, NeonGlow = false, EjectCd = 0,
	Dance = false, Follow = false, Face = false, FovValue = 0, WatchTarget = nil, Radar = false, GfxShadow = false, GfxFog = false, GfxParticle = false, GfxDecal = false, GfxNight = false, GfxSuperNight = false, GfxNoFog = false, DashRun = false, WPLoop = false, WPLoopInt = 5,
	Freeze = false, HidePlayers = false, AutoJump = false, CoordHud = false,
	TPLoop = false, TPInterval = 0, TPOffsetY = 3,
	MoveGameUI = false, UILayoutLocked = false,
	Stealth = false, StealthHideGame = false,
	CamNoclip = false,
	BlackHole = false, BlackHoleForce = 60, HeroFly = false, Car = false,
	EngineOutline = true, Trail = false, CloneArmy = false, OrbitFx = false,
	HeadRide = false, Shake = false, SpinCam = false, Magnet = false,
	ThirdPerson = false, NoFall = false, ShowHP = false, ShowFunList = false,
	AntiKB = false, AntiStun = false, Countdown = false,
	SafePos = nil,
	CuteFxExtra = true,        -- 可爱风额外特效（爱心 + 泡泡）随樱花一起飘
	StyleFxPanelOnly = false,  -- 屏幕特效仅面板开启时显示（false = 全程显示）
}
function bindClick(btn, tag, fn)
	if not btn then return end
	local last = 0
	-- 绑定时锁死原始尺寸作为回弹基准：点击动画只在其上做临时缩放，永远回到它，
	-- 避免「每次按压都从当前尺寸取基准 + 多次事件叠加」导致越点越小的 bug
	local baseSz = btn and btn.Size or nil
	local popping = false
	local function fire()
		local now = tick()
		if now - last < 0.28 then return end
		last = now
		local ok, err = pcall(fn)
		if not ok then _pr("[HON] 点击[" .. tostring(tag) .. "]出错: " .. tostring(err)) end
	end
	local function pressPop()
		if not (State and State.InputAnim and btn and btn.IsA and btn:IsA("GuiObject")) then return end
		if not baseSz then return end
		pcall(function()
			if popping then return end  -- 动画进行中不叠加，防止重复缩小
			popping = true
			local small = UDim2.new(baseSz.X.Scale, baseSz.X.Offset - 2, baseSz.Y.Scale, baseSz.Y.Offset - 2)
			local tw = TweenService:Create(btn, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = small })
			tw:Play()
			spawn(function()
				wait(0.1)
				pcall(function() if btn and btn.Parent then btn.Size = baseSz end end)  -- 永远回到原始大小
				popping = false
			end)
		end)
	end
	-- 只用 Activated（已统一鼠标点击 / 触屏点击 / 手柄），避免 MouseButton1Click + TouchTap + InputBegan
	-- 重复触发导致一次点击执行多次 pressPop 而叠加缩小
	pcall(function() btn.Activated:Connect(function() pressPop(); fire() end) end)
end

local function Mode() return Modes[State.ModeIndex] end
local cur = 0
local fps, fpsAcc, fpsFrames = 0, 0, 0
local rainbowTimer, wasAirborne, FxBackup = 0, false, nil
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
-- v5.47： OrigMainSize 补上赋值——此前全文件 6 处 if OrigMainSize then Main.Size = OrigMainSize
-- 全是空跑（变量从来没赋过值），关闭动画把面板宽×1.16 高×0.8 污染掉之后再也还原不回来，
-- 就是「每动一下 UI 缩短变宽 / 重复收缩打开也出问题」的根因
OrigMainSize = Main.Size
-- 面板缩放：此前全脚本只有 10 处 if MainScale then 空跑（对象从未创建，「面板收缩没有用」的实锤）
MainScale = new("UIScale", { Scale = 1, Parent = Main })
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
label({ Text = "Universal Hub  ·  W / V / CF  ·  v5.58", Font = Enum.Font.Gotham, TextSize = 11,
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
iconBtn("×", -34, Color3.fromRGB(255, 108, 118), function()
	askConfirm("彻底关闭脚本？", "会关掉所有功能、清掉翅膀/分身/黑洞等生成物、销毁界面并停止全部循环。\n（只想收起的话请点左边的 –）", "确认关闭", function()
		unloadScript()
	end)
end)
-- ---------- 更新公告 ----------
CHANGELOG = {
	{ v = "v5.58", t = {
		"新增 · 辅助页「相机穿墙 CAMERA NOCLIP」：开启后镜头不被墙 / 地形遮挡，可看穿墙体（每帧在相机模块摆好镜头之后，把相机沿当前朝向推回当前缩放距离，但不做任何遮挡射线检测，鼠标转向照常、只是不再被拉近；关闭即解绑，不改动相机类型 / 状态）",
		"改动 · 隐身录屏改为开启即在右上角弹出固定小窗「隐身 STEALTH」（与飞行小窗同款样式、固定在右上角、不可最小化），点 × 或「开关隐身」即关闭、窗随隐身一起收起；关闭隐身时小窗同步收起。内部「开关隐身」开关建好后立即移出 ToggleRegistry，避免被「隐身冻结 / 全部关闭」误伤",
	}},
	{ v = "v5.57", t = {
		"重要修复 · 飞行「只能上下、不能前后左右」：根因是飞行水平移动的方向取自 keyDir()，而 keyDir 只靠 UserInputService:IsKeyDown 判断 WASD 是否按下——飞行 / PlatformStand 状态下个别执行器 IsKeyDown 不可靠地返回 false，WASD 判定全失败、水平方向恒为 0，于是只剩右上角 UP/DOWN 按钮能驱动的上下移动。v5.57 用 InputBegan / InputEnded 维护一份可靠的「按下按键集合」，与 IsKeyDown 取并集，所有依赖该判定的移动（飞行水平、普通行走方向）都一并变稳；并防卡键（松开时清状态）",
	}},
	{ v = "v5.56", t = {
		"重要修复 · 小窗上面的按钮「点一下就缩小、越点越小直到点不到」：根因有两点——① bindClick 一个点击同时挂了 MouseButton1Click + Activated + TouchTap + InputBegan 四个事件，一次点击会触发 2~3 次 pressPop 叠加；② pressPop 每次从「当前尺寸」取基准，多次叠加后把已经缩小的尺寸当成原尺寸存回，于是越点越小。v5.56 改成只保留统一的 Activated 事件（本就涵盖鼠标/触屏/手柄），并在绑定时锁死「原始尺寸」作回弹基准、回弹永远回到它，外加 popping 防重入——现在点击是「往里弹一下再弹回原大小」的反馈，不再永久性缩小",
	}},
	{ v = "v5.55", t = {
		"功能删除 · 彻底移除「面板背景图」整套功能（设置页开关 / 启动时自动加载 / 11 张预设 / 图片 ID 输入框 / 透明度滑条 / WindUI 窗口背景同步 / 本地+跨服务器双存档）：它是满屏 ImageLabel 用远程 https 图，每帧都在合成、加载与解码会周期性卡顿——正好是你说的「启动之后变卡顿」的元凶；删掉后界面直接走 UI 样式纯色背景，更轻更流畅，设置页相关控件相应上移补位、页高同步收紧",
	}},
	{ v = "v5.54", t = {
		"重要修复 · 所有小窗都启动不了、倒计时长按缩小后原地又冒出一个重复小窗（一直有两个）：根因是 v5.53 把小窗位置记到了 Roblox 实例的自定义属性上（如 X.SavedPos），执行器里纯 Lua 表不校验、测试通过，但真机对实例挂自定义属性会抛「not a valid member」导致整个窗口创建流程中断、连锁报错；v5.54 改用普通 Lua 表（WinPos）记忆四个小窗（加速 / 倒计时 / 标点 / 飞行）的位置，关掉再开、最小化 / 展开切换都能恢复到关闭前的位置，且不再产生重复窗",
		"布局修复 · 传送页小窗开关（WPWinTgl）和「查看玩家 ViewBtn」「恢复视角 CamBackBtn」重叠挤到一起：把两个按钮整体下移 36px 让出开关所在那一行约 48px 高的空间，三控件不再碰撞",
		"布局修复 · 右边页面标签栏切换数字乱摆不整齐：TabBar 原本手动按 44px 间距定位 11 个分页按钮，部分执行器下 AutomaticCanvasSize 失效导致散开；改成在 TabBar 里加 UIListLayout + UIPadding 兜底，纵向自动对齐、整齐排布",
		"功能新增 · 可爱风屏幕特效在樱花之外再加爱心 ♥ + 泡泡：设置页新增「可爱风额外特效 CUTE EXTRA」开关（默认开），开启后樱花飘落的同时粉色爱心与半透明泡泡一起飘（爱心下落、泡泡上浮）；外加「特效仅面板开启 FX PANEL-ONLY」开关，开 = 只有面板打开时才显示屏幕特效，关 = 全程一直显示",
	}},
	{ v = "v5.53", t = {
		"重要修复 · 特殊小窗（加速小窗 / 倒计时 / 标点小窗 / 飞行窗口）的数字不再能被拖走：此前数字 / 时间 / 坐标这些文字标签被错当成拖动手柄，按住数字拖动会把它从窗内拽飞、而窗口框本身没动，看起来就像「窗口回到初始位置、数字乱跑」；现在只保留窗体 / 标题条作为把手，数字固定在窗内不漂移（点数字拖动会整体移动窗口，数字相对窗口位置不变）",
		"重要修复 · 小窗关闭后再开启回到初始位置：此前窗口位置没有记忆，关掉再打开就弹回默认坐标；现在拖动时实时记下位置，关闭后再开启（含最小化 / 展开切换）都恢复到关闭前的位置——加速 / 倒计时 / 标点 / 飞行四个窗统一处理",
	}},
	{ v = "v5.52", t = {
		"功能新增 · 设置页新增「输入动画 INPUT ANIM」开关（按钮按下时的缩放回弹反馈，关闭则无动画），并保留「启动动画」开关；一键触碰所有可触碰物体从视觉页移到工具页（WindUI 侧移至辅助页）；透视修复部分玩家不高亮（高亮此前挂在角色模型上，会随重生 / 流式加载 / 角色重建而丢失，改为挂到持久容器 EspFolder，Adornee 仍指向角色，每次扫描稳定渲染）；透视血条新增样式切换「血条背景 HP BAR BG」（开=有背景实时血量，关=纯血量数字）；反重力去重——删除辅助页的反重力与重力值滑条，只保留工具页的反重力（两个反重力同指一个开关，留一个即可）",
		"实测 · 全量回归 20 个测试文件全绿（含新增 test_v552 专项：输入动画开关 / 一键触碰位移 / 高亮挂持久容器 / 血条样式切换 / 反重力去重）：82 开关 + 168 按钮触发 0 报错",
	}},
	{ v = "v5.51", t = {
		"功能调整 · 删除独立的「隐藏脚本界面」开关（用户：「把那个隐藏脚本 UI 界面的功能给删掉，不需要，我只需要一个隐藏录屏功能就行了」）：移除 setHideUI 函数、HideUiTgl 开关与 State.HideUI 字段，实用工具页其余开关相应上移补位；现在只有「隐身录屏 STEALTH」这一种隐藏方式——它本来就只藏本脚本面板（系统 UI / 服务器自带 UI 一律不动），删掉冗余开关后录屏逻辑更干净：录屏时只隐去本脚本，游戏原本的界面照常显示",
	}},
	{ v = "v5.50", t = {
		"重要改进 · 隐身录屏改为「开启后冻结除加速外的全部功能，关闭后原样恢复」（用户：「隐身完之后把所有功能全部关掉，就是开启隐身之后关掉所有功能，除了那个加速，然后其他功能全部关掉，当我关闭隐身，当我关闭录屏时恢复所有功能」）：此前 stealthFreeze 用 _keep 标志判断保留项，导致防布娃娃 / 启动动画 / 面板边框 / 背景图 / 霓虹发光 / 装死倒地等一堆非加速开关在隐身时也没被关；现在 stealthFreeze 改用一份独立的「加速白名单」（启用引擎 + 加速小窗 SPEED WIN + 隐身录屏开关本身），其余所有处于开启状态的开关一律 Set(false) 冻结，关隐身时逐个 Set(true) 还原到隐身前的状态——既满足「只留加速」，又不破坏 _keep 同时管辖的「全部关闭」按钮逻辑（设置类开关仍不被全部关闭排除）",
		"说明同步 · 隐身录屏小窗副标题与提示文案更正为「隐藏界面 + 暂停其他功能（加速保留）」「隐藏期间仅加速保持运行，其余功能全部暂停（关闭隐身即恢复）」，删掉旧版「隐藏期间加速 / 飞行 / ESP 全部继续生效」的错误描述",
	}},
	{ v = "v5.49", t = {
		"重要修复 · 防录屏不再误藏系统 UI 与服务器自带 UI（用户：「防录屏不只隐藏脚本，不隐藏原系统 UI 和服务器自带的 UI」）：此前「隐藏全部 UI」开关与「隐身录屏 STEALTH」都会遍历 PlayerGui，把 Gui 以外的所有 ScreenGui（即游戏服务器自带的界面）一并 Enabled=false——录屏 / 截图时把人家游戏界面也收了；现在只藏脚本自己的 Gui 这一个 ScreenGui，原系统 UI（CoreGui：聊天 / 排行榜 / 菜单 / 顶栏）与服务器自带 UI 原样保留，录屏只隐去本脚本面板",
		"重要改进 · 隐身录屏默认不再藏游戏界面：State.StealthHideGame 默认 true → false，开启后只调用 stealthHideOwn() 收本脚本面板（REC 悬浮钮照常显示），彻底停掉 stealthHideGame() 对 PlayerGui 下服务器 UI 的收拢；「隐藏全部 UI」开关改名为「隐藏脚本界面」，语义与行为一致",
		"实测 · mock 全量回归 17 个测试文件全绿：新增 test_v549 专项（隐藏脚本界面只禁 Gui.Enabled、PlayerGui 下服务器 ScreenGui 保持 Enabled 不变、关开关还原；State.StealthHideGame 默认 false、隐身录屏开后仅 HideOwn 生效、服务器 ScreenGui 与 REC 球均不受影响）；82 开关 + 168 按钮触发 0 报错",
	}},
	{ v = "v5.48", t = {
		"重大修复 · 切 WindUI 框架后倒计时小窗不显示、飞行用不了的根因（用户：「倒计时的那个倒计时有问题，它不显示在那个小窗上面」「飞行用不了」）：setUiFramework(2) 此前执行 Gui.Enabled=false 想藏掉自制 UI——可倒计时 / 加速 / 标点 / 飞行四个小窗和右上角 UP / DOWN 键全部挂在 Gui 下，禁 Gui 等于把它们连窝端，症状正是「倒计时不显示」「飞行用不了」；现在切框架只藏 Main 主面板和 Mini 迷你条（GuiPanelBak 记住原显隐、切回时原样恢复，缩成迷你条也不怕），Gui 全程不禁，小窗与升降键在哪个框架下都活",
		"重大新增 · 四个小窗全部加最小化键（用户：「给所有小窗全部增加个缩小，就是最小键也是缩量的」）：加速 / 标点 / 飞行三个小窗标题条新增「–」钮——点一下整窗缩成 30px 标题条（子元素逐个记原显隐后全藏、标题字与 × 留着），再点还原；通用能力 winMinSetup(win, minBtn, keep) 一次接线全窗生效；飞行小窗最小化只缩窗体，右上角 UP / DOWN 升降键不受影响",
		"重大改进 · 倒计时最小化改「屏幕中心上方小 pill」（用户：「倒计时的 UI 缩小之后，倒计时会出现在屏幕中心上方」）：倒计时小窗的「–」收起完整窗体后，屏幕顶部中间（0.5, -75, 0, 8）浮出 150×40 小 pill——大字时间 + 「展开」钮；缩起期间表照常走、最后 10 秒同步染红；点 pill 时间字或展开钮随时还原完整小窗；关开关 = 全收 + 停表 + 最小化态重置，下次开从完整小窗开始",
		"重大改进 · 飞行重写为悬浮模式（用户：「修改一下飞行，飞行用不了，我要的是开机之后控制，就是把角色控制在原地，就固定在原地，只能前后移动，前后左右移动准确来说就是，上下只能靠屏幕右上角的那两个按钮键来进行动」）：旧飞行动力整个是死的——渲染步读 Humanoid.MoveDirection 取水平方向（PlatformStand 下该值失效，脚本自己的注释都承认），主循环里算完的速度又从不写出去（死代码），唯一活着的只有 E / Q / Space / LeftCtrl 键盘升降；现在单一动力源：① 水平走原始输入（WASD / 虚拟方向键）按飞行速度直写；② 上下只认右上角 UP / DOWN 两个按钮键，键盘升降全部拆除；③ 不按升降 = 弹簧锁在当前高度（按过再松手就锁定新高度），角色固定在原地不坠不飘；④ 每帧直接写 HRP.AssemblyLinearVelocity，不再依赖 LinearVelocity 约束（新 API 个别执行器建了不工作，飞行会直接瘫）；AlignOrientation 保持 upright + 朝向只跟随镜头水平朝向（不含俯仰），pcall 包着，老执行器自动退化照样飞",
		"重要修复 · 三个新测试才抓到的笔误 / 断链（test_v548 暴露）：① winMinSetup 的 shrunk and false or e[2] 是坏三元——A=false 时 Lua 穿透到 or 分支，最小化根本没藏住子元素（缩成标题条但内容全露着）；② CdMiniL 把单个实例误当 kids 表传给 new() 第三参——mock 的 ipairs 静默零迭代，真机上 ipairs(userdata) 直接报错，整个 cdBuild 会中断（倒计时开关点了白点）；③ 飞行中重生三断链——FlyHoldY 留着旧高度把新角色往旧高度拽、旧 FlyAtt 还挂在已换掉的角色上（buildFlyParts 早退跳过）、新角色 PlatformStand 没重断言，现在重生一律销毁旧附件 → 重建 → 按新位置锁高度 → 重钉 PlatformStand",
		"重要改进 · 加速小窗 ± 改为一点一点加（用户：「引擎的那个小窗上面的加速要一点一点的增加，而不是一下就加 10」）：± 按钮步进 10 → 1，与主速度滑条整数粒度一致；顶 / 底格 clamp 照旧，要大改直接拖主滑条",
		"实测 · mock 全量回归 17 个测试文件全绿：新增 test_v548 五段专项（框架切换小窗全活——Gui 不禁 / Main·Mini 藏 / 四个小窗 + UP·DOWN 键在 WindUI 下仍可见可点 / GuiPanelBak 原显隐恢复 / 关着面板切框架不强行弹回；四窗最小化-恢复——30px 标题条 + 子元素藏 / 还原 + 标题条元素不藏 + 飞行小窗缩窗不缩升降键；倒计时 pill——顶部中间位置 + 缩起照常走 + 最后 10 秒染红 + 两种展开路径 + 关开关重置；飞行悬浮——PlatformStand + 弹簧锁高度 + WASD 水平 + E / Q 键盘升降失效 + UP / DOWN 按钮升降与锁定高度随动 + 速度滑条联动 + 关闭全复位 + 重生三连重置；加速 ±1 + 连点累积 + 顶 / 底 clamp + 源码级防回归）；mock 基建修正——GuiObject.Visible 默认 true 对齐真机；82 开关 + 168 按钮触发 0 报错",
	}},
	{ v = "v5.47", t = {
		"重大改进 · ESP 字体放大 + 启动记忆（用户：「增加一个透视字体放大，因为字体太小了。就是我设置到那个字体，下次启动脚本的时候还是在那个字体的位置，就那个大小」）：视觉页新增「ESP 字体」滑条（60%~200%，默认 100%）——竖排三件套（盒子 / 名字 / 血条 / 距离 / 间距）整套按 EspFontScale 等比缩放，不是只放大字号；选定的倍数写存档（ef 字段，clamp 0.6~2），重启 / 换服自动恢复；WindUI 视觉页同步上架",
		"重要修复 · ESP 厚墙远距透视不到（用户：「可能是墙壁特别厚，然后又特别远的地方它透视不到……我需要它不管在哪里，不管有什么阻挡都能透视到」）：名字 / 血条 / 距离文字牌此前 AlwaysOnTop 跟着「穿墙显示」开关走、MaxDistance 又是默认小值——墙一挡或稍远就整组消失；现在文字牌无条件最顶渲染（AlwaysOnTop=true），MaxDistance 拉到 100000，厚墙远距都不丢标签；角色高亮仍归「穿墙显示」开关管，行为不变",
		"重大改进 · 关闭动画改成与开启完全对称的碎片扭曲（用户：「它是直接把面板就哐的一下横过来，然后消失了，我需要的是让它和开启一样变成碎片扭曲空间，然后再收回去」）：旧版关闭动画是 Rotation=10 + 宽×1.16 高×0.8 的横倒 tween，和开场的神威漩涡展开完全不搭；现在面板碎成 24 片、被黑洞吸回去再消失，开 / 关两端完全对称。顺手修掉「每动一下 UI 缩短变宽 / 重复收缩打开也出问题」的根因：OrigMainSize 从来没被赋值，全文件 6 处 if OrigMainSize then Main.Size = OrigMainSize 全是空跑——关闭动画把面板尺寸污染掉之后再也还原不回来，已补上 Main.Size 快照",
		"重大新增 · 三主题屏幕特效（用户：「可爱风加点樱花特效，魔眼加点那种地狱的那种翅膀什么的呀，或者眼睛的那种，然后酷炫的也是加点科技风的」）：特效挂在 ScreenGui 全屏层，随「UI 样式」切换增删，render step「HonStyleFx」驱动——酷风 COOL = 科技扫描线 + 四角 HUD 支架；可爱风 CUTE = 18 片樱花飘落（摇摆 + 旋转 + 循环）；魔眼 3D = 地狱翅膀（3 层翼指绕肩扇动）+ 一双巨眼（瞳孔游移 + 定时眨眼）；切样式 / 卸载即时清理，不留野循环",
		"重大改进 · 虚拟方向键整块拖动（用户：「我要的是拖动它，然后就中间那个我碰到哪里就轻轻碰向哪里……而不是把所有按键全部分散拖动」）：此前 8 个方向格各自独立拖动，轻轻一碰就拽得满屏飞；现在按住格子照常走路，手指挪出 12px 容忍区才停脚、改为拖动整个方向键（PadFrame 整体位移）；中心格小摇杆手感不变（轻碰定向 / 长按拖整块 / 正中心死区三者互不冲突）",
		"重要改进 · 右上角提示全面收权（用户：「哪些功能开启后会在屏幕右上角给提示……把那个给关掉，都说了只有我开启。有娱乐功能的那里的那个功能列表显示，它才会显示在右上角」）：notify() 顶部加无色闸门——日常确认（不带色）一律不弹，右上角从此只归「功能列表显示」开关管；7 个警告 / 错误提示点补上统一的警示橙（角色还没加载 / 角色还没就绪 ×2 / 当前角色不支持缩放 / 保存失败：角色还没加载 / 没识别到有效图片 ID / 坐标格式不对），该响的警报一个不少；7 处唯一定过色的日常确认（引擎切换 / 帧率优化 / 咻起飞 / 霓虹发光 / 已固定 / 已恢复布局 / 已关闭全部）剥成无色不再刷屏；全文件剩余 23 处带色提示全是警告 / 错误 / 引导类",
		"重大新增 · 加速小窗 SPEED WIN（用户：「再给弄个加速，做个小窗，可以在小窗上面切换速度和模式」）：引擎页新增「加速小窗」开关——屏幕左上角弹出 176×148 可拖动小窗：标题 + × 收起、W / V / CF 三模式按钮（当前模式高亮 + 主题色）、34px 速度大字、± 按钮（每次 ±10，顶到当前模式上限即停）；小窗调速度与主速度滑条双向实时同步，切引擎时模式高亮 / 速度范围 / 主题色全部跟着刷；× 收起时静默同步开关状态；WindUI 引擎页镜像上架",
		"重大新增 · 标点传送小窗 WP WIN（用户：「然后那个标点传送也是」——加速小窗同款待遇）：传送页新增「标点小窗」开关——176×228 可拖动小窗：实时坐标条、「存此处」一键保存（自动命名「标点 N」）、标点列表（名字 + ☆ 选中 + 「去」传送，空列表有提示）、计数标签；小窗与主页面共享同一份标点数据，保存 / 选中 / 删除三个方向实时同步，☆ 选中后「去」直接传送；× 收起静默同步开关；WindUI 传送页镜像上架",
		"重大新增 · 一键触碰所有可触碰物体（用户：「再增加个新功能，就是一键触碰所有可触碰的物体，就是整个服务器一键触碰所有可触碰的物体」）：视觉页新增「一键触碰所有可触碰物体」按钮——遍历 Workspace 全图，ProximityPrompt（fireproximityprompt）/ ClickDetector（fireclickdetector）/ Tool（Activate）三类全部触发，逐个 pcall 隔离，单个失败不拖垮整体；汇总成功计数并橙提示「已触发 N 个可触碰物体」；执行器没有扩展函数时自动降级不崩；WindUI 视觉页镜像上架",
		"重要修复 · 引擎描边开关「点了不存在」（预存嵌套 bug）：OutlineTgl 的创建语句此前被意外包在「瞬移闪现 TP」开关的回调体内（缩进为 0 但 Lua 不管缩进）——加载时描边开关根本没被创建，用户点不到，只有手动开 / 关一次 TP 开关才会顺带创建出来；已改正回调结构，描边开关加载即存在。实测 toggle 注册表不再出现重复项（修复前 TP 每触发一次回调就多注册一个描边开关）",
		"实测 · mock 全量回归 16 个测试文件全绿：新增 test_v547 十段专项（ESP 字体滑条缩放与存档记忆往返 / ESP 文字牌无条件最顶 + MaxDistance / 关闭动画碎片扭曲 + OrigMainSize 还原 / 三主题特效增删与渲染步绑定 / 方向键 12px 容忍整块拖（单格零位移·中心格不回退）/ 提示收权闸门 + 7 警告点带橙 + 日常确认不弹 / 加速小窗三模式·±·双向同步·clamp·收起同步·拖动 / 标点小窗存·选·删·去四向同步·拖动 / 一键触碰三类对象全触发·总数·降级不崩）；mock 基建修正——GetChildren 返回快照副本对齐真机语义（修掉遍历中 Destroy 隔项漏删），新增 fireproximityprompt / fireclickdetector / Tool:Activate 执行器扩展与 MockTouchFired 计数器；82 开关 + 168 按钮触发 0 报错",
	}},
	{ v = "v5.46", t = {
		"重大改进 · WindUI 框架下背景图终于生效（学习夜脚本的窗口背景方案并借鉴）：此前切到 WindUI 后 11 张预设 / 透明度 / 开关全部失效——CreateWindow 从来没接过 Background，背景图只挂在自制 UI 的 ImageLabel 上，切框架等于背景全丢；现在 CreateWindow 直接吃 Background + BackgroundImageTransparency（没开就不传，走库默认），建完再补一层保险强制重写（防 UI 初始化不同步），新增 windSyncBg() 把开关 / 预设切换 / 图片 ID / 透明度滑条 / 框架切换五路全部实时同步到 WindUI 窗口，关背景时 BackgroundImage 清空；自制 UI 侧行为不变，两边互不干扰",
		"改进 · WindUI 加载加重试（借鉴夜脚本 tryLoadWindUI）：HttpGet 偶发失败（网络抖动 / 限流）就整体回退自制 UI 太脆——改成最多 3 次尝试，任一成功即用，全失败才回退并明示",
		"实测 · mock 全量回归 15 个测试文件全绿：扩展 test_ui_framework（CreateWindow 收到 Background / BackgroundImageTransparency / windSyncBg 开关·预设·ID·透明度四路同步 / 关背景清空 Image / 切框架自动应用 / 卸载体后不同步不崩）；79 开关 + 164 按钮 0 报错",
	}},
	{ v = "v5.45", t = {
		"重大新增 · 工具页「倒计时器 COUNTDOWN」（用户：「在防坠落上面增加一个计时，开启之后屏幕生成一个小 UI，输入要计多少分钟，点确认之后就开始倒数，倒数到 0 的时候就在屏幕上提示时间到了，或者自己暂停和重置」）：开关一开屏幕顶部弹出可拖动小 UI——mm:ss 30px 大字（最后 10 秒染红）、分钟输入框、确认 / 暂停 / 重置三兄弟；输入 1 或 1.5 都认，空 / 0 / 非数字橙色提示不崩，上限 24 小时；倒数到 0 大字归零并弹「时间到了」；暂停冻结表针，重置回总时长；关开关收界面并停表。render step 里 tick，WindUI 传送页同步上架；工具页防坠落以下 9 个控件整体下移 48px，PAGE_H[5] 600 → 660 对齐无死空",
		"重大改进 · 身上方块改内置自动清除（用户：「隐藏身上的方块没有用……开启隐身之后自动清除，因为它只有开启隐身才能让它显现，然后开启脚本如果出现方块自动清除而不是手动，所以把清除方块功能就可以去掉了，就在脚本内置一个自动开启的」）：视觉页删掉「隐藏身上方块 NO BLOCK」开关和「立即清除身上方块」按钮（含 WindUI 镜像），改为无感内置——启动 / 重生绑定角色自动清、开隐身录屏自动清、Stepped 维持循环每 30 帧持续压回游戏后加上来的附加物（配件 / 框选 / 名牌 / 高亮 / SurfaceGui 全覆盖），UNLOAD 时统一还原不留残",
		"重要修复 · 「隐藏身上方块没有用」根因清除：Stepped 维持循环里写的是 hideBodyBlocks(false)——false 是还原分支，等于每 30 帧把刚藏起来的方块全部放出来，开开关也肉眼看不出来；已改为常开 hideBodyBlocks(true) 真压回（v5.43 加开关时引入的笔误，实测三处入口全部生效）",
		"实测 · mock 全量回归 15 个测试文件全绿：新增 test_v545（倒计时开关显隐 / 确认起跑与非法输入拦截 / 倒数递减与 mm:ss 格式 / 最后 10 秒染红 / 暂停冻结 / 重置回总时长 / 到点「时间到了」通知 / 关开关停表 / 按钮接线；身上方块启动自动清 + 维持循环真压回 + 开隐身自动清 + 卸载体还原 + 手动开关已拆干净）；79 开关 + 164 按钮触发 0 报错",
	}},
	{ v = "v5.44", t = {
		"重大改进 · 启动动画开关化（用户：「可开可关的按钮……不要动画切换了，就要那个」）：设置页删掉「启动动画样式 / 删除动画样式」两个 ▾ 循环按钮（4 样式互斥逻辑整层拆除），换成两个独立开关——开着才播神威漩涡展开动画，关掉面板直接显形不播；存档格式从样式序号 o/c 升级为布尔 on/co，旧档里的 4（不要动画）自动兼容为关",
		"改进 · 字体默认拉到最大（用户：「给它那个字体默认拉到最大」）：无存档时启动即应用 160%（FontScaleV=1.6），字体滑条默认值与 WindUI 侧同步改为 160，有存档仍按存档恢复",
		"重要改进 · 右上角提示窗收权（用户：「有的功能打开会自动生成一个提示窗，我不要让它生成，当我开启功能显示那个时候它才会生成」）：已开启功能清单从此只归「功能列表显示」开关管——不开功能列表显示，哪怕开着飞行穿墙夜视也天塌下来不弹",
		"重大改进 · 透视 ESP 竖排重做（用户：「字体有点太小了……竖着摆，名字摆最上面，血条摆中间，距离摆最下面」）：Billboard 从 13px 单行「名字 距离 HP」挤一行改为 200×80 竖排三件套——名字 16px 最上、血条（深色底槽 + 按血量比例填充 + 数字压条）中间、距离 14px 最下；交互物没有血量，血条整组隐藏、距离上移到名字下方不留空档",
		"重大改进 · 技能定身不暴露（用户：哥斯拉 VS 王者基多拉类技能必须把角色定在原地才能放，开着加速角色会动很容易暴露）：新增 skillRooted() 检测（PlatformStand / 锚定 / 本帧 WalkSpeed 被游戏写 0），三大引擎定身期间全部停手——W 引擎不把 WalkSpeed 抢回来、V/CF 引擎不做 CFrame 位移并清零蓄力速度，定身结束下一帧自动继续加速，不窜出不暴露",
		"重大改进 · 虚拟方向键中心键小摇杆（用户：「中间那个键轻轻往右上角一摁就往右上角走……轻微触碰某个方向就往某个方向动，要不然中间不能按走路一卡一卡的」）：中心格触点相对格子中心的偏移量化成 8 向（阈值 ±30%），斜向（右上/左上/右下/左下）也能走；正中心死区留给长按拖动整块，走路与拖动互不冲突",
		"重大改进 · 雷达朝向朝上 heading-up（用户：「让雷达上面人物跟着我的，让人物转，而不是让我转……在我中心前面放一个小三角形，那就是我看向哪里，让敌人 NPC 建筑开始旋转」）：自己永远是雷达中心一个点 + 正上方静态小三角（三角指的就是当前朝向），敌人 / NPC / 建筑按自己水平朝向反向旋转、绕着自己转；正上 / 正下看时水平分量为 0，保持上帧朝向不跳变",
		"重大新增 · 画质页「一键提升帧率 · 降低卡顿」（用户：「这两个做成一个功能，降低贴图什么的，反正能提升帧率就行」）：阴影 / 粒子 / 贴图全关 + 地形装饰（草花灌木，大地图掉帧大头）+ 渲染质量压到 Level01，全部走已有画质通道——自动记原值、同步开关 UI、写存档，「恢复默认画质」一键还原；WindUI 画质页同步上架，另补「恢复默认画质」按钮",
		"重要修复 · 「恢复默认画质」只调 setGfxX 却不同步 State：恢复后画面回来了，存档里却还是开着状态，下次启动又给关回去——State 四项（阴影/雾气/粒子/贴花）在 gfxReset 里显式归 false，实测存档往返与还原全链",
		"实测 · mock 全量回归 14 个测试文件全绿：重写 test_anim（开关默认开 / 点击闸门生效 / on/co 存档往返 / 旧档 o=4 兼容为关）、test_bg 收权断言（未开功能列表时开着功能也不弹提示窗）、test_radar_new 改 heading-up 断言（正前方 NPC 恒在屏幕正上方、世界 +X 直墙旋转到屏幕左侧）、新增 test_v544（ESP 竖排三段结构 + 交互物隐藏血条 / 字体默认 1.6 与滑条 160 / 技能定身 W·V 双引擎不抢不动 / 中心键 8 向含斜向与死区 / 帧率优化与 gfxReset 还原全链含地形装饰与渲染质量）；79 开关 + 165 按钮触发 0 报错",
	}},
	{ v = "v5.43", t = {
		"重大修复 · 「背景图怎么没用」根因清除（三项全修）：① https 直链加载失败静默无痕——Roblox 的 ImageLabel 对执行器不支持的 https 图片不报错也不留痕，用户对着空面板猜；现在建图后 2.5 秒检测 IsLoaded，还没加载就明说「https 直链不被支持，请用图片 ID 框」，指明确实兜底路径；② 开关与画面不同步——「启动时自动加载背景」开了、背景也显示了，设置页开关却还是关的（按默认 false 建的），用户手一滑又给关掉；启动恢复后同步 BgTgl 视觉；③ 顺手修一个藏了很久的 off-by-one：「rbxassetid:」是 11 个字符，守卫写成 sub(img,1,12) 永远匹配不上，图片 ID 一直被当 https 送进预下载/失败检测——ID 图加载稍慢就误报「https 不被支持」，指错路。另：背景预设提示在开着时直接标注「没显示就用下方图片 ID 框」，setBg 增加 quiet 参数，启动恢复不再弹通知刷屏",
		"重大新增 · 面板边框（照参考源码模式）：设置页新增「面板边框」开关 + 「边框样式」循环（彩虹 / 红色 / 蓝色 / 主题色）。彩虹模式挂 RunService:BindToRenderStep(「HonBorder」) 走 HSV 色环（复用 hsv2rgb，不依赖 Color3.fromHSV），关闭或切静态色立即解绑不留野循环；「主题色」跟随引擎主题色，换引擎 / 换 UI 风格都同步；开关与样式自动存档（HonSpeedHub_Pref.json + HON_PREF 双保险）",
		"重大新增 · 界面框架切换（设置页「界面框架 UI FRAMEWORK」，注意不是上面的「UI 风格」换肤）：自制 UI / WindUI 整套界面库二选一。WindUI 加载走 _G.WindUI 优先、其次 loadstring + HttpGet 拉 dist/main.lua，构建时每个组件单独 pcall 隔离（单个组件炸不拖垮整个界面），加载或构建任何一步失败自动回退自制 UI 并明示原因，绝不留白屏；WindUI 侧完整镜像 7 个标签（引擎 / 辅助 / 视觉 / 传送 / 娱乐 / 画质 / 设置）80+ 组件——三大引擎、速度顺滑、全部常用开关、坐标传送输入框、弹射升空、8 款翅膀、玩具全量、画质 7 项、背景预设/图片 ID、UNLOAD，以及「切回自制 UI」入口；框架选择自动存档，换服自动恢复；UNLOAD 时 WindUI 窗口一并收掉",
		"重要修复 · makeToggle 的 _last 从「创建时快照」改为实时同步：此前用户在自制 UI 里点过关的开关，切到 WindUI 后那边显示的还是创建默认值，和实际功能状态对不上；现在点击 / Set 都同步 _last，WindUI 构建时读到的是当前真实状态",
		"改进 · 设置页布局重排（新增框架 + 边框两组）：启动动画以下全部下移 162px，逐项核对无死空；PAGE_H[10] 900 → 1200 与内容实际高度对齐；底部说明补上「界面框架 / 边框已自动存档」",
		"实测 · mock 全量回归 13 个测试文件全绿：新增 test_ui_framework（60+ 断言：框架回退 / 假库完整构建 / 开关滑条接线 / 边框开关样式彩虹循环 / 背景失败检测与 rbxassetid 不误报 / PREF fw/bo/bm 存档往返与越界 clamp）；76 开关 + 164 按钮触发 0 报错",
	}},
	{ v = "v5.42", t = {
		"重要修复 · 设置页三项自动保存全部落地：字体大小 / 面板收缩 / 面板透明度改完即存（本地 HonSpeedHub_Pref.json + 跨服务器 HON_PREF 双保险），重启 / 换服自动恢复；顺差修掉两个真 bug——①「面板收缩没有用」的实锤：MainScale 从来没被创建，全脚本 10 处 if MainScale then 全是空跑，已补 new UIScale；② 透明度关闭态下拖滑条不生效，已闭环（关着时提示先开「面板背景图」开关，开启后实时刷新 ImageTransparency）",
		"改进 · 启动 / 关闭动画样式互斥：播放神威漩涡时再点别的样式，旧协程立即停账清碎片，不再出现两个动画叠加或旧碎片残留；动画样式选择本身也已自动存档",
		"重要修复 · 录屏 / 截图（隐藏全部 UI / 隐身录屏）不再隐藏 Roblox 系统 UI：旧版动过 StarterGui:SetCoreGuiEnabled(All) 和 SetCore('TopbarEnabled')，把聊天 / 排行榜 / 菜单一并弄没导致部分设备UI错乱——现在只收自己 PlayerGui 下的 ScreenGui，系统 UI 原样保留；UNLOAD 时按记录精确还原",
		"重大改进 · 雷达重做（五项全修）：① 扫描线「木棍乱晃」——旧实现用 Frame.Rotation 转一根 1×78 的贴边线，端点绕偏心几何中心公转，已改为 2×156 直径线 + UIGradient 渐隐绕中心旋转，纹丝不动；② 中心「小绿方块乱飘」——4×9 无圆角方块朝向标同样踩偏心公转，已改为位置计算的 3×13 圆角短线，贴着中心点；③ 墙壁改成折线——大块建筑取俯视长边中轴线（Size.X vs Size.Z 取大）缓存屏幕方向，Frame 贴中点旋转绘制，L 形墙多段自然接成折线，想要的一条竖线 / 拐弯跟拐弯都有了；④ 雷达框开 ClipsDescendants，扫描线不再溢出边框；⑤ 双模式按钮文字统一为「全显 + 墙壁 ▾ / 仅人物 / NPC ▾」，切换不再乱",
		"清理 · 按用户要求彻底删除装扮页：商城 63 件商品数据（246 行）+ 装扮函数（55 行）+ 装扮页 UI（143 行）整体拆除，标签栏 12 → 11 页；原装扮里的「玩具」8 件和「翅膀」8 款已搬到娱乐页，即开即关不丢功能",
		"重大新增 · 娱乐页三个新趣味功能：🚀 弹射升空 EJECT（垂直 190 速度弹射，2.5 秒冷却防连点）· 装死倒地 PLAY DEAD（PlatformStand 当场躺平，再点站起来）· 霓虹发光 NEON GLOW（全身色相循环流光，记录原始颜色，关闭 / 重生自动还原）",
		"重要修复 · 「画质为什么每次启动都必须开，不开就出 bug」根因清除：① 画质各项此前往死里写固定值（雾 FogEnd=500 / 阴影 true / 粒子 Enabled=true），游戏原本不是这个值就被改坏，且 ColorCorrectionEffect 挂在 Lighting 里不随脚本卸载销毁——下次启动画面残留黑白 / 异常，用户只能开画质盖住；现已改为「第一次开启时记录游戏原始值，关闭时原样还原」+「亮度 / 饱和度 100% 时直接销毁特效而不是留个 0 值的效果」+ UNLOAD 连 Lighting 里的残留一起清；② 画质 7 开关 + 亮度 / 饱和度现在也自动存档（HonSpeedHub_Gfx.json + HON_GFX），不用每次重启再开；设置页新增「恢复默认画质」一键同步全部 UI 与存档",
		"改进 · 大招照搬参考源码回归纯点击传送：去掉自研的 800 米限距 / 1 秒冷却 / 双端粒子特效（射线 2000 内点哪传哪，和「点击传送」共用一套输入回调，关闭即停），行为与参考脚本完全一致",
		"性能 · 启动卡顿治理：神威漩涡启动动画 252 段碎片 → 112 段 + 颜色缓存（Color3 常量预计算），低端机首帧掉帧明显缓解",
		"改进 · 全页空隙排查（11 页逐页核对元素坐标）：修掉 6 处死空——视觉页 44px（透明度滑块贴住雷达组）、工具页 56px + 106px（大招 / 反重力两组悬空）、娱乐页 34px + 一处真重叠（「收起翅膀」整宽按钮压住第 4 行两只翅膀）、更多页 52px、实用页 60px、传送页 114px（目标列表面板收起后大片空白）；另删掉一条贴错页面、压住雷达开关的说明 label（内容已并入工具页「分身隐身」描述），清理删装扮页残留在 PAGE_H 里的第 12 项高度，修正设置 / 画质两页 mkPage 索引错位（11/12 → 10/11）",
		"实测 · mock 全量回归全绿：11 个测试文件（含本轮新增 / 重写的画质还原与存档、设置三项、雷达新实现、隐身录屏系统 UI 零调用监控、新趣味功能、玩具边界）全部通过；76 开关 + 160 按钮触发 0 报错",
	}},
	{ v = "v5.41", t = {
		"清理 · 按用户要求彻底移除密钥系统：删除 KEY_SYSTEM / KEY_REMEMBER / MASTER_KEY / VALID_KEYS 全部配置、Authed 鉴权变量与两处权限门、整块卡密输入 UI（71 行）及 HON_KEY_OK 本机记录读写——全文件零残留，脚本打开即用，无任何验证环节",
		"实测 · 移除后 mock 全量回归通过：76 开关 + 172 按钮 0 报错，背景 / 大招 / 存档三件套专项回归全过；主文件 6547 → 6461 行",
	}},
	{ v = "v5.40", t = {
		"重大新增 · 工具箱新增「闪电尖兵大招 SPARK ULT」：开启后点击屏幕任意位置即可闪电突进过去——射线找落点、限距 800 米、冷却 1 秒（冷却中再点会提示）、起点终点各一发蓝白雷暴粒子特效；右上角功能列表实时显示「瞬移」；和「点击传送」互不冲突（大招优先），UNLOAD 自动关闭",
		"重大新增 · 设置页背景区搬入 WindUI 参考脚本的 11 张背景预设（蓝色系少女 / 粉色系少女 / 蓝色系猫娘 / 彩蛋 / 紫色系御姐 / 蓝色系少女2 / 你懂的 / 你懂的2 / 你懂的3 / 罪恶王冠楪祈 / 罪恶王冠楪祈2）：3 列 chips 横排点击即切换，切换结果自动存档（本地文件 + 跨服务器双保险），重启/换服不丢",
		"改进 · https 背景图改走 ContentProvider:PreloadAsync 协程预下载（不卡界面），提高执行器里 GitHub 直链图片的加载成功率；「图片 ID」输入框保留作兜底——预设链接显示不了时，去 create.roblox.com 上传图片拿 rbxassetid 数字 ID 填框即可",
		"重要修复 · 三套本地存档（标点 WP / 动画样式 ANIM / 背景图 BG）此前全部静默失效——脚本引用了从未定义的全局 HttpService（Roblox 不会提供全局服务对象），JSONEncode 每次都在 pcall 里报错被吞，「换服不丢」从来就没生效过；已补 game:GetService('HttpService')，三套存档实测写入/读档/跨服务器兜底全部恢复",
		"改进 · 背景图存档格式升级（id → src）：预设链接 / 自定义 ID / 默认图统一记「图片来源」一个字段，读档向后兼容旧存档",
		"实测 · 新增背景与大招专项 mock 回归全通过：11 预设结构 / 预设切换换图与存档 / ID 提取与前缀补全 / 无效输入不崩 / 本地读档与跨服务器双保险 / BgIdBox 失焦链路 / 存档三件套（标点+动画+背景）写入读档恢复 / 闪电突进命中·冷却拦截·超距拦截·无落点·触屏·关闭即停·特效自清理；全量回归 76 开关 + 172 按钮 0 报错",
	}},
	{ v = "v5.39", t = {
		"重大新增 · 商城新增「玩具 TOYS」分类：8 种真实可玩的本地趣味特效，灵感与实现参考 GitHub 外国开源 Admin 脚本（EdgeIY/infiniteyield 与 fatesc/fates-admin 的经典 FE 命令），全部点卡片即开即关、只有自己看得见",
		"玩具清单 · 🎆 烟花（ Neon 球爆裂连发，每 1.2s 一发、Debris 2.2s 定时清理）· ✨ 火花（原生 Sparkles 挂满全身）· 🔥 火焰（原生 Fire）· 💨 烟雾（原生 Smoke）· 🪄 魔毯（红地毯+金边每帧跟随脚下，配 Infinite Yield carpet 命令同款坐姿动画 rbxassetid://282574440，开着飞行就是飞行魔毯）· 💃 跳舞（Infinite Yield dance 命令同款真实动画 ID 清单，R15/R6 各一套共 18 个）· 🎈 气球（3 只大气球头上浮动跟随）· ☄️ 环绕（Infinite Yield orbit 命令同款 CFrame 公转数学，绕自己身边半径 4 旋转）",
		"机制 · 玩具与装扮互不干扰（可同时穿衣服放烟花）；「卸下全部」会一并关掉所有玩具；重生后自动重挂（火花/火焰/烟雾挂在角色部件上，换角色自动重新挂）；UNLOAD 彻底清理",
		"修复 · 测试基建三连：mock 角色此前没挂进 Workspace 导致 bindCharacter 直接 return、HRP 全程为 nil（所有帧驱动路径实测不到）——已修；mock 的 Vector3.Magnitude / .Unit 原本是方法（真 Roblox 是属性），脚本里距离比较一直在静默报错——已改为计算属性；mock 的 Position/CFrame 写入不同步（实例写 CFrame 后读 Position 拿到过期值）——已改为统一以 CFrame 为准",
		"改进 · 魔毯 / 气球创建瞬间即贴到角色脚下 / 头上（此前第一帧前停在世界原点会闪一下）；新增玩具边界回归（角色缺失时开全部玩具 / 8 玩具全开叠加 / 环绕中重生中心重置 / 角色部件销毁后停止跟随 / UNLOAD 彻底清理）全通过",
		"实测 · 新增玩具专项 mock 回归（test_toys.lua）全通过：8 玩具结构校验 / 卡片点击启停 / 火花挂载与清除 / 烟花连发节奏与 Debris 到期清理 / 跳舞动画 ID 在 Infinite Yield 清单内 / 魔毯跟随与坐姿动画 / 气球浮动 / 环绕公转半径 / 一键全关 / 重生重挂不翻倍；全量回归 76 开关 + 160 按钮 0 报错",
	}},
	{ v = "v5.38", t = {
		"重大新增 · 装扮页升级为完整 Roblox 商城 AVATAR SHOP：头饰 / 头发 / 眼睛 / 上衣 / 经典上衣 / 连衣裙 / 裙子 / 经典裤子 / 丝袜 / 鞋子 共 10 大分类 63 件商品，商城式分类标签（chips）+ 商品卡片网格（emoji 图标 + 名称 + R$ 价格 + 已装备高亮描边）+ 搜索 + 卸下全部",
		"新增 · 眼睛类 6 款（星瞳 / 心形 / 赛博竖瞳 / 血瞳 / 闪光 / 闪电瞳）Part 拼眼睛贴在头前；高跟鞋 / 厚底运动鞋 / 长筒靴 Part 拼鞋；连衣裙 = 躯干换色 + Part 拼裙摆（女仆装 / 婚纱 / JK / 礼服等）",
		"机制 · 全部商品本地装扮只有你自己看得见，换角色 / 重生后自动重扮；点击已装备卡片即卸下；衣服 / 裤子 / 丝袜 / 鞋子类是直接给身体部件换色（存原色、卸下自动还原）",
		"修复 · 测试基建：mock 的 CFrame 实例元表此前漏挂 __mul / __add / __sub（只挂在了 CFrame 表上），CFrame × CFrame 组合在实测环境直接崩「attempt to perform arithmetic on a table value」——已修，63 件商品的 build 全量穿脱实测 0 错；mock 角色补全 R15 十五个身体部件，换色类商品可真实验证",
		"实测 · 新版商城 mock 回归全通过：63 商品结构校验 / 11 个分类 chips 切换 / 穿戴与卸下 / 换色与还原 / 搜索过滤（名称+分类双匹配）/ 63 件全量穿脱；全量回归 78 开关 + 159 按钮点击 0 报错",
	}},
	{ v = "v5.37", t = {
		"重要修复 · 雷达重做：从屏幕左下角搬到右上角（自动避开右上角已开启功能列表，不挡视线）；军事雷达样式——世界坐标固定（上=北、右=东）、旋转扫描线、半程刻度圈、自己居中并带朝向小三角",
		"2D 模式按最初规格补全四要素：人（红点）+ NPC（黄点）+ 建筑（灰点，任一边 ≥12 studs 的大块 BasePart）+ 可互动物（蓝点，带 ProximityPrompt / ClickDetector）；模式2 仅人物 / NPC；范围 220 studs，半程刻度圈 110",
		"重要修复 · 「闪电冲刺·持续加速」开关此前根本没接上线（setDashRun 是死函数，DashOn 永远为 false）——已在趣味页补上开关，开启后越跑越快（上限 260），随时可关；右上角功能列表实时显示「冲刺」",
		"实测 · 用自建 Roblox API mock + Lua 5.4 全量回归：78 个开关逐个开/关、153 个按钮逐个点击，0 报错；88 个 State 键全部确认有真实消费点（不再有「State 置位但没人读」的死开关）",
		"稳健 · 顶层局部变量 187 → 141（39 个只用一次的开关句柄转为全局），消除贴近 Lua 200 局部上限的加载中断风险",
	}},
	{ v = "v5.36", t = {
		"重要新增 · 夜脚本源码的画质系统完整搬入画质页（新增「夜视与环境 NIGHT VISION」分区）：普通夜视（Brightness=10，夜里全亮+阴影全关+色偏清零）/ 超级夜视（Brightness=70，正午光感+远距视野）/ 彻底去雾（Legacy Fog 与 Atmosphere 雾霾 Density/Offset/Glare/Haze 双清，关闭时逐项还原原值）/ 关闭所有夜视/去雾",
		"机制 · 首次开启任一夜视功能即存档原始 Lighting 13 项参数（Ambient/OutdoorAmbient/Fog/ClockTime/GlobalShadows/EnvironmentScale/ColorShift/Exposure 等），关闭自动还原，绝不留下改过的环境",
		"改进 · 彻底去雾补上了原「关闭雾气」开关的短板——原来只改 FogEnd 不去 Atmosphere，游戏里有雾霾时等于没关；现在两套雾一起清",
		"联动 · 三项夜视状态重生后自动重放；右上角已开启功能列表实时显示「夜视/超级夜视/去雾」；彻底关闭脚本（UNLOAD）与「恢复默认画质」均会一并关掉并还原",
	}},
	{ v = "v5.35", t = {
		"阳光派对 · 新增三套竞技活动皮肤（设置页 UI 样式，共 7 套可选）：酷风 COOL（冰蓝钛灰描边+冰蓝光带）/ 可爱风 CUTE（莓粉描边+粉光带）/ 魔眼 3D（暗红底+血红粗描边+血红光带）",
		"改进 · 面板主题机制扩展：每套皮肤可带描边颜色、描边粗细、顶部光带颜色（老主题无这些字段自动跳过，行为不变）",
	}},

	{ v = "v5.34", t = {
		"重要修复 · 全面复查发现 7 个娱乐功能的设置函数此前被整组误删（UI/开关/每帧驱动/重生恢复都在，就是创建函数没了），点开关直接崩「尝试调用 nil 值」—— 已按驱动代码的字段契约全部重建：彩虹拖尾 / 粒子环绕 / 分身军团（5 分身环绕+贴地）/ FE 变车（6 件套车模）/ 无敌少侠飞行 / 强制第三人称 / 隐藏身上方块",
		"修复 · 分身军团的 Clones 表没有初始定义，点「在脚下放置分身」会 table.insert(nil) 崩溃 —— 已补全局初始化",
		"修复 · 「隐藏身上方块」开关原来只能开不能关（关掉不还原附加物）—— 现在关闭即全部还原",
		"加固 · 检查工具新增「被调用但未定义的函数」扫描（本轮 7 个误删函数就是靠它抓出来的），防止再整组丢失",
	}},

	{ v = "v5.33", t = {
		"新增 · 「删除动画样式」独立选择：收起面板（–）的动画不再跟启动动画绑死，两种动画各自可选，共 4 种（神威漩涡/淡入淡出/缩放弹出/不要动画）",
		"新增 · 启动/删除动画选择自动存档：本地文件 + 跨服务器 TeleportSetting 双保险（和标点同一套机制），换服/重进不恢复默认，按钮文字读档后正确显示当前选择",
		"修复 · 设置页「彻底关闭脚本 UNLOAD」按钮与下方说明文字原本重叠在同一位置（都压在 y=622），已重排整页；新增动画行后设置页整体下移，页高 720 → 740",
	}},

	{ v = "v5.32", t = {
		"重要修复 · 神威（Kamui）开屏/关屏动画的「撕裂碎片」系统此前被误删（shatterPanel / hideShards 两个函数 + KamuiShards 表整个不见了），一点开或关面板就崩「尝试调用 nil 值」—— 已按渲染字段完整重建，碎片被黑洞吸入/喷出的动画恢复",
		"重要修复 · 4 处裸 print 全部换成 _pr 防御（切换页面 / 切换引擎 / 关闭脚本 / 载入提示），个别禁用 print 的执行器下这些操作不再崩",
		"修复 · 装饰商城每输入一次搜索、每穿脱一件装饰都往 FunBtns 按钮表重复插入（旧按钮已销毁但仍留在表里，内存只涨不减）—— 改用独立 DecoBtns 表，每次刷新即清空，主题变色 / 搜索索引同步覆盖",
		"重要修复 · 顶层局部变量一度到 206 个，超过 Luau 单函数 200 上限（超限是编译期错误，整个脚本一行都不会执行）—— 精简死变量 + 内部函数转全局，现为 186 个，留足余量",
		"优化 · 辅助页与设置页的「防布娃娃」两个开关现在联动，一边开另一边同步显示",
		"加固 · 循环传送 / 标点循环的回调自引用加 nil 保护，与全局卸载逻辑统一",
	}},

	{ v = "v5.31", t = {
		"重要修复 · 之前误删翅膀系统导致脚本在装扮页中断，装扮 / 设置 / 画质三页全空 —— 已重建，三页恢复正常",
		"新增 · 装扮页改成「装饰商城」：背饰/尾部/颈部/腰部/头发/上衣/裤子/裙子/袜子/鞋子 共 30 项 + 搜索 + 卸下全部（客户端本地装扮，只有自己看得见，重生自动重扮）",
		"新增 · 传送页「坐标传送」：实时显示当前坐标，可手动输入 XYZ 传送，一键填入当前坐标",
		"新增 · 传送页「标点系统」：保存当前位置为标点（无上限），点击/★选中/删除，自动存档，写文件 + 跨服务器 TeleportSetting 双保险，换服不丢",
		"新增 · 标点循环传送：每隔 N 秒自动传送到 ★ 选中标点（间隔可调）",
		"删除 · 光环相关残留代码已清干净",
		"加固 · 布局检查器升级：横排控件不再误报重叠",
		"重要修复 · 网络版/极致压缩版/混淆版此前会把文件前 3969 行整个丢掉（压缩脚本的分隔线定位 bug），导致一执行就「尝试调用 nil 值」—— 已改成全文压缩，三个版本恢复完整（字符串 1408/1408 一致性自检通过）",
		"加固 · 载入提示加 print/warn 双防御，个别禁用 print 的执行器也不会在第 7 行崩",
	}},

	{ v = "v5.30", t = {
		"改 · × = 彻底关闭脚本（弹确认后关全部功能并卸载）；– = 收起面板（功能继续跑）",
	}},
	{ v = "v5.29", t = {
		"重要 · 收起面板（– / ×）不再关闭功能，功能继续在后台跑",
		"新增 · 设置页「彻底关闭脚本 UNLOAD」：关全部功能 + 清翅膀/分身/黑洞等生成物 + 停所有循环 + 销毁界面（带二次确认）",
		"修复 · closeAllFeatures 函数定义此前被误删导致调用无效，已补回",
		"加固 · 14 条循环全部加关停检查，卸载后彻底停止",
	}},
	{ v = "v5.28", t = {
		"改 · 关闭脚本时自动关闭全部功能（不只是隐藏面板）",
		"改 · 启动/删除动画 4 种样式真正生效（神威漩涡 / 淡入淡出 / 缩放弹出 / 不要动画），之前选了没反应",
		"改 · 已开启功能显示：挪到屏幕右上角，竖排编号 1. 2. 3.",
		"改 · 黑洞不再吸自己，只吸 NPC / 物品",
		"改 · 装死躺平改成切换：点一下装死，再点一下起身",
		"删 · 头顶光环、隐藏游戏 UI（按你说的删掉）",
		"新增 · 画质修改独立页（关阴影/关雾/关粒子/隐藏贴花/亮度/饱和度/一键恢复）",
		"新增 · 雷达（屏幕左下角）：2D 全显 与 仅人物NPC 两种模式",
		"新增 · 闪电冲刺持续加速版：越跑越快，可随时关",
		"改 · 分身现在能上楼梯（贴地射线跟随）",
		"改 · 侧栏滑动时不切换页面（滑动只滚动，点击才切）",
		"改 · 跳舞包含 NPC；工具页也加了重力与防布娃娃",
	}},
	{ v = "v5.27", t = {
		"新增 · 设置页（第 11 页）：4 种 UI 样式 · 面板缩放 · 启动/删除动画样式 · 字体大小 · 背景图与透明度",
		"新增 · 面板背景图：用你给的那张 IMG_3683 当面板背景，可开关 + 启动时自动加载",
		"新增 · 恢复角色外观按钮（修被画质/材质改动染色的角色）",
		"新增 · 重置身体比例按钮（放大身体后一键回 100%）",
		"新增 · 防布娃娃（夜脚本同款）：不会被打倒/摔倒",
		"新增 · 换个服务器（随机重进）",
	}},
	{ v = "v5.26", t = {
		"重做 · 神威动画严格对齐预览：14 条螺旋卷入线 + 16 个沿螺旋内流的碎屑粒子 + 7 圈空间环 + 黑洞奇点，时长 3 秒，参数逐项一致",
		"修复 · 移动键拖动：之前挂错了不存在的变量（NumBtns→TouchBtns），现在数字键/方向键都能在屏幕上直接拖",
	}},
	{ v = "v5.25", t = {
		"重做 · 翅膀：每侧 3 层 × 9 片共 54 片羽翼，按翼形轮廓排布（中间长两端短）+ 波浪式扇动，新增「EVA 暴走翼」",
		"修复 · 头顶光环默认改成水平（Torus 默认竖直），并加降级方案：不支持就用 24 段拼环，保证一定出现",
		"修复 · 误删的彩虹拖尾 / 分身军团 / 粒子环绕 / 全员跳舞 四个函数已补回",
		"新增 · 反重力开关 + 重力值滑条（辅助页）",
		"修复 · 顶部横排总是显示「1 加速」：引擎默认开着不算已开功能",
		"修复 · 功能列表显示被 HUD 覆盖的判定问题",
	}},
	{ v = "v5.24", t = {
		"修复 · 头顶光环是竖着的：Roblox 的 Torus 默认竖直，默认角度改为 90°（水平悬浮），并做得更细",
		"修复 · 视野 FOV：拖动滑条立即生效，不用等平滑过渡",
	}},
	{ v = "v5.23", t = {
		"修复 · 黑洞吸力滑条与「倒立 FLIP」重叠（都在 y=352），倒立已下移到独立位置",
		"新增 · 布局检查器构建闸门：自动扫描所有页面控件 y 区间，重叠直接拦下",
	}},
	{ v = "v5.22", t = {
		"紧急修复 · 白屏崩溃：FunBtns 表在第 679 行被使用却在第 1159 行才定义，导致 table.insert(nil) 报错、初始化中断",
		"修复 · 表定义顺序全部前移，新增「表检查器」构建闸门（table.insert 目标必须先定义）",
		"修复 · 收起面板后状态还原，关闭/重开不再残留",
	}},
	{ v = "v5.21", t = {
		"紧急修复 · makeToggle 内部自引用导致每次 Set() 抛错（连锁引发页面/小窗打不开）",
		"修复 · 关不掉：关闭流程改为无论如何都会收起面板并还原状态",
		"修复 · 启动动画：移除与神威冲突的旧弹出动画，改为神威之后衔接弹出",
		"修复 · 侧栏只认前 8 页：改为动态全部页 + 画布放大，10 个标签都能点",
		"新增 · 看门狗：5 秒后若界面意外消失会自动恢复，防止整个 UI 不见",
	}},	{ v = "v5.20", t = {
		"改 · 移动 UI：屏幕上点哪个就能拖哪个（数字键/方向键各自独立拖动）",
		"新增 · 自由视角开关：角色定在原地，镜头到处飞",
		"改 · 环绕 TA：开启后弹面板选人（取消会自动关掉开关）",
		"改 · 少侠飞行 / FE 变车：点击后先弹确认框，确认才生效",
		"改 · 分身军团：独立面板（环绕跟随 / 脚下放置 / 删除分身）",
		"改 · 已开启功能显示：挪到屏幕上方横排 1 2 3",
		"改 · 全部关闭：先弹确认框并说明会关掉哪些东西",
		"新增 · 传送页：查看玩家（选中即可看他）+ 恢复自己视角",
		"改 · 存档点：保存成功/失败都有明确提示",
	}},	{ v = "v5.19", t = {
		"新增 · 装扮页：6 种大翅膀（天使/堕天/恶魔/光/火/机械）+ 5 种头顶光环",
		"新增 · 蔚蓝档案式光环（悬浮旋转，可调大小与角度）",
		"新增 · 隐藏身上方块：一键清除配件/框选/名牌等附加物",
		"改 · 隐身录屏：开启时暂停除加速外所有功能，退出后原样恢复",
		"修复 · 黑洞与 FPS 加速控件重叠（点不到黑洞）",
		"修复 · 拖尾/少侠/第三人称等角色重生后失效（改为每帧维持）",
		"修复 · 血量显示与功能列表被 HUD 覆盖不显示",
		"新增 · 空壳检查器：自动揪出「开关没用」的字段",
	}},
	{ v = "v5.18", t = {
		"新增 · 公告界面（本页）· 设置页入口",
		"新增 · 头顶光环（蔚蓝档案式）· 分身独立面板",
		"修复 · 飞行 / FOV / 连跳 / 拖尾 / 跳舞 / 骑头 失效",
		"修复 · 黑洞与倒立控件重叠 · 存档点提示",
		"重构 · 混淆版：字符串全加密 + 诱饵逻辑，抗反混淆",
	}},
	{ v = "v5.17", t = {
		"修复 · 特效永远不停（时长单位错误）",
		"修复 · 放出动画不显示漩涡",
		"回退 · 漩涡恢复平面版（更好看的那版）",
		"调整 · 动画时长延长到 3 秒",
	}},
	{ v = "v5.16", t = {
		"新增 · 面板撕裂：切成 18 块被卷进奇点",
		"新增 · 碎片沿螺旋轨迹卷入（龙卷风感）",
		"优化 · 减少线条数量，降低卡顿",
	}},
	{ v = "v5.15", t = {
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
local TabBar = new("ScrollingFrame", { Name = "Sidebar", Size = UDim2.new(0, 168, 0, 356), Position = UDim2.new(0, 0, 0, 66),
	BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3,
	ScrollBarImageTransparency = 0.7, ScrollBarImageColor3 = Modes[1].Accent,
	CanvasSize = UDim2.new(0, 0, 0, 470), AutomaticCanvasSize = Enum.AutomaticSize.Y,
	ScrollingDirection = Enum.ScrollingDirection.Y, Parent = Main })
-- v5.54：用 UIListLayout 兜底排布，避免部分执行器下 AutomaticCanvasSize 失效导致标签栏散开
new("UIListLayout", { Padding = UDim.new(0, 4), FillDirection = Enum.FillDirection.Vertical,
	HorizontalAlignment = Enum.HorizontalAlignment.Left, VerticalAlignment = Enum.VerticalAlignment.Top,
	SortOrder = Enum.SortOrder.LayoutOrder, Parent = TabBar })
new("UIPadding", { PaddingTop = UDim.new(0, 10), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), Parent = TabBar })
SideLine = new("Frame", { Size = UDim2.new(0, 1, 1, 0), Position = UDim2.new(0, 167, 0, 0),
	BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.93, BorderSizePixel = 0, Parent = Main })
local TabBtns = {}
local FunBtns = {}
local CurTab = 1
do
	local names = { "引擎", "辅助", "视觉", "触屏", "工具", "娱乐", "更多", "实用", "传送", "设置", "画质" }
	for i, n in ipairs(names) do
		local b = new("TextButton", { Text = n, Font = Enum.Font.GothamBold, TextSize = 13,
			TextColor3 = Color3.fromRGB(140, 149, 172), BackgroundTransparency = 1,
			BorderSizePixel = 0, AutoButtonColor = false,
			Size = UDim2.new(1, -16, 0, 40), Position = UDim2.new(0, 0, 0, 0), Parent = TabBar })
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
local PAGE_H = { 620, 440, 500, 680, 660, 2040, 560, 660, 1260, 1000, 1080 }
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
local PageSet = mkPage(10, false)
local PageGfx = mkPage(11, false)
PageList = { PageEng, PageAssist, PageEsp, PageTouch, PageTool, PageFun, PageMore, PageUtil, PageTp, PageSet, PageGfx }
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
		Apply = function(v) apply(v, false) end,
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
	local lastVal = initial
	local api   -- 前向声明：点击/Set 里要顺手同步 _last（WindUI 构建时读当前值用）
	local function paint(v)
		TweenService:Create(sw, TWEEN_FAST, { BackgroundColor3 = v and Mode().Accent or Color3.fromRGB(70, 74, 90) }):Play()
		TweenService:Create(kb, TWEEN_FAST, { Position = v and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9) }):Play()
	end
	-- _last 必须是实时值：用户在自制 UI 里点过关的开关，切到 WindUI 时那边要显示当前状态，
	-- 不能还是创建时的快照（此前切框架后 WindUI 开关全是默认值，和实际功能状态对不上）
	sw.MouseButton1Click:Connect(function() on = not on; lastVal = on; api._last = on; paint(on); onChange(on) end)
	api = {
		Row = row, Stroke = stroke, Title = t1, Sub = t2, Switch = sw,
		Set = function(v, silent) on = v; lastVal = v; api._last = v; paint(on); if not silent then onChange(on) end end,
		Refresh = function() if on then paint(true) end end,
		Dim = function(dim)
			TweenService:Create(row, TWEEN_SOFT, { BackgroundTransparency = dim and 0.75 or 0.35 }):Play()
			TweenService:Create(t1, TWEEN_SOFT, { TextColor3 = dim and Color3.fromRGB(120, 128, 148) or Color3.fromRGB(224, 231, 246) }):Play()
			TweenService:Create(t2, TWEEN_SOFT, { TextColor3 = dim and Color3.fromRGB(92, 99, 118) or Color3.fromRGB(132, 141, 163) }):Play()
			TweenService:Create(stroke, TWEEN_SOFT, { Transparency = dim and 0.95 or 0.85 }):Play()
		end,
	}
	api._last = lastVal
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
	function(v) State.Speed = v; if speedWinRefresh then speedWinRefresh() end end, true, function(v) State.SpeedLocked = v end, true)
local SmoothSlider = makeSlider(PageEng, "顺滑 SMOOTH", 258, 1, 20, State.Smooth, "",
	function(v) State.Smooth = v end, false)
local PowerToggle   = makeToggle(PageEng, 312, "启用引擎", "F2 快捷键 · 隐身时仍保持", true, function(v) State.Enabled = v end, true)
local InertiaToggle = makeToggle(PageEng, 360, "惯性滑行", "仅 V 引擎生效", true, function(v) State.Inertia = v end)
local SlideToggle   = makeToggle(PageEng, 408, "防穿墙 / 沿墙滑动", "CF / V 引擎生效", true, function(v) State.WallSlide = v end)
local TeleportToggle = makeToggle(PageEng, 456, "瞬移闪现 TP", "仅 CF · 蓄力后整段位移", false, function(v)
	State.CFTeleport = v
	CFAccum = 0
end)
OutlineTgl = makeToggle(PageEng, 504, "引擎描边 OUTLINE", "角色轮廓跟着引擎颜色", true, function(v)
	State.EngineOutline = v
	if Highlight and Highlight.Parent then
		Highlight.Enabled = v
		if v then Highlight.OutlineColor = Mode().Accent end
	end
end)
SpeedWinTgl = makeToggle(PageEng, 552, "加速小窗 SPEED WIN", "屏幕小窗 · 切模式 / 调速度，把手可拖动", false, function(v)
	speedWinBuild()
	if SpeedWin then
		if v and WinPos.SpeedWin then SpeedWin.Position = WinPos.SpeedWin end
		SpeedWin.Visible = v
	end
	if v then speedWinRefresh() end
end)
label({ Text = "辅 助 功 能", Font = Enum.Font.GothamBold, TextSize = 11,
	TextColor3 = Color3.fromRGB(120, 129, 152), Size = UDim2.new(1, 0, 0, 18),
	Position = UDim2.new(0, 2, 0, 0), TextXAlignment = Enum.TextXAlignment.Left }, PageAssist)
local JumpSlider = makeSlider(PageAssist, "跳跃力 JUMP", 24, 16, 200, DEFAULT_JUMP, " jp",
	function(v) State.JumpPower = v end, true, function(v) State.JumpLocked = v end)
JumpToggle = makeToggle(PageAssist, 78, "启用跳跃增强", "逐帧回写防被重置", false, function(v) State.JumpEnabled = v end)
InfJumpTgl = makeToggle(PageAssist, 126, "无限跳", "空中可反复起跳", false, function(v) State.InfJump = v end)
NoclipTgl  = makeToggle(PageAssist, 174, "穿墙 NOCLIP", "关闭时还原碰撞体", false, function(v)
	State.Noclip = v
	setNoclip(v)
end)
AntiAFKTgl = makeToggle(PageAssist, 222, "反挂机 ANTI-AFK", "防止长时间无操作掉线", false, function(v) State.AntiAFK = v end)
local HudTgl     = makeToggle(PageAssist, 270, "速度 HUD", "屏幕底部实时显示速度", false, function(v)
	State.HUD = v; HudFrame.Visible = v
end)
local FlyTgl     = makeToggle(PageAssist, 318, "飞行窗口 FLY", "打开小窗 + 右上角上下键", false, function(v)
	setFlyWindow(v)
end)
CamNoclipTgl = makeToggle(PageAssist, 366, "相机穿墙 CAMERA NOCLIP", "镜头不被墙/地形遮挡，可看穿墙体", false, function(v)
	State.CamNoclip = v
	setCamNoclip(v)
end)
label({ Text = "视 觉 增 强", Font = Enum.Font.GothamBold, TextSize = 11,
	TextColor3 = Color3.fromRGB(120, 129, 152), Size = UDim2.new(1, 0, 0, 18),
	Position = UDim2.new(0, 2, 0, 0), TextXAlignment = Enum.TextXAlignment.Left }, PageEsp)
EspPlayerTgl = makeToggle(PageEsp, 24,  "玩家透视", "高亮 + 名称 / 距离 / 血量", false, function(v)
	State.EspPlayer = v; if not v then clearEsp("Player") end
end)
EspNpcTgl    = makeToggle(PageEsp, 72,  "NPC 透视", "高亮所有非玩家人形", false, function(v)
	State.EspNPC = v; if not v then clearEsp("NPC") end
end)
EspItTgl     = makeToggle(PageEsp, 120, "交互物透视", "ProximityPrompt / ClickDetector", false, function(v)
	State.EspInteract = v; if not v then clearEsp("Interact") end
end)
InstantTgl   = makeToggle(PageEsp, 168, "秒交互", "HoldDuration=0 · 距离 30", false, function(v)
	State.InstantInteract = v; applyInstantInteract(v)
end)
RadarTgl = makeToggle(PageEsp, 318, "雷达 RADAR", "右上角 · 人/NPC/互动物/墙壁折线", false, function(v)
	State.Radar = v
	if not v and RadarFrame then RadarFrame.Visible = false end
end)
local RadarModeBtn = new("TextButton", { Text = "雷达模式：全显 + 墙壁 ▾", Font = Enum.Font.GothamBold, TextSize = 11,
	TextColor3 = Mode().Accent, BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.9,
	BorderSizePixel = 0, AutoButtonColor = false,
	Size = UDim2.new(1, 0, 0, 32), Position = UDim2.new(0, 0, 0, 366), Parent = PageEsp })
corner(RadarModeBtn, 8)
table.insert(FunBtns, RadarModeBtn)
bindClick(RadarModeBtn, "雷达模式", function()
	RadarMode = (RadarMode % 2) + 1
	RadarModeBtn.Text = (RadarMode == 1) and "雷达模式：全显 + 墙壁 ▾" or "雷达模式：仅人物 / NPC ▾"
	if notify then notify((RadarMode == 1) and "雷达：全显（人 + NPC + 互动物 + 墙壁折线）" or "雷达：仅人物 / NPC（干净模式）") end
end)
EspDepthTgl  = makeToggle(PageEsp, 216, "穿墙显示", "角色高亮穿墙，名字/血条/距离永远可见", true, function(v)
	State.EspDepth = v; refreshEspDepth()
end)
TranspSlider = makeSlider(PageEsp, "身体透明度", 264, 0, 100, 0, " %", function(v)
	State.BodyTransp = v / 100
end, false)
-- v5.45：「隐藏身上方块」从手动开关/按钮改为脚本内置自动功能（用户：「开启脚本如果出现
-- 方块自动清除而不是手动……把清除方块功能就可以去掉了，就在脚本内置一个自动开启的」）——
-- 启动 / 重生 / 开隐身都会自动清，Stepped 维持循环持续压回游戏后加上来的附加物
label({ Text = "触 屏 控 制", Font = Enum.Font.GothamBold, TextSize = 11,
	TextColor3 = Color3.fromRGB(120, 129, 152), Size = UDim2.new(1, 0, 0, 18),
	Position = UDim2.new(0, 2, 0, 0), TextXAlignment = Enum.TextXAlignment.Left }, PageTouch)
TouchTgl = makeToggle(PageTouch, 24, "触屏数字键", "屏幕生成 1~5 键 · 可拖动", false, function(v)
	State.TouchKeys = v
	updateTouchVisibility()
end)
PadTgl = makeToggle(PageTouch, 72, "虚拟方向键", "8 向 WASD · 长按中心拖动整块", false, function(v)
	State.PadKeys = v
	updateTouchVisibility()
end)
ToolGravTgl = makeToggle(PageTool, 554, "反重力 LOW GRAVITY", "和辅助页那个是同一个开关", false, function(v)
	State.LowGravity = v
	pcall(function() Workspace.Gravity = v and (State.GravityValue or 40) or 196.2 end)
	if notify then notify(v and "重力已降低" or "重力已恢复") end
end)
function syncRagTgls(v)
	State.AntiRagdoll = v
	for _, t in ipairs(ToggleRegistry) do
		if t._title == "防布娃娃 ANTI RAGDOLL" and t.Set then t.Set(v, true) end
	end
end
ToolRagTgl = makeToggle(PageTool, 606, "防布娃娃 ANTI RAGDOLL", "不会被打倒 / 摔倒", false, function(v)
	syncRagTgls(v)
end)
PadSizeSlider = makeSlider(PageTouch, "方向键大小", 120, 50, 200, 100, " %", function(v)
	State.PadSize = v
	if PadScale then PadScale.Scale = v / 100 end
end, false)
TouchLockTgl = makeToggle(PageTouch, 174, "锁定位置", "数字键 + 方向键一起锁死", false, function(v)
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
UiListLayout = new("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder, Parent = UiList })
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
ClickTpTgl = makeToggle(PageTool, 24, "点击传送", "开启后点地面即可瞬移过去", false, function(v)
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
function toolBtn(text, x, onClick)
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
-- ===== v5.48：小窗最小化（用户：「给所有小窗全部增加个缩小，就是最小键也是缩小的」）=====
-- 「–」把窗缩成只剩标题条（winMinSetup：子元素逐个记 Visible，缩时全藏、展时全还），
-- 再点一下（钮变 □）展开。keep 里的对象（标题字 / 关闭钮）收缩时保持可见
function winMinSetup(win, minBtn, keep)
	if not (win and minBtn) then return end
	local full = win.Size
	local shrunk = false
	local bodies = {}
	for _, c in ipairs(win:GetChildren()) do
		if c ~= minBtn and c:IsA("GuiObject") then
			local k = false
			for _, o in ipairs(keep or {}) do if c == o then k = true break end end
			if not k then table.insert(bodies, { c, c.Visible }) end
		end
	end
	local function apply()
		-- 注意：不能写 `e[1].Visible = shrunk and false or e[2]`——Lua 的 and/or 三元
		-- 在 A=false 时会穿透到 or 分支（true and false or x == x），最小化根本没藏住
		for _, e in ipairs(bodies) do
			if shrunk then e[1].Visible = false else e[1].Visible = e[2] end
		end
		win.Size = shrunk and UDim2.new(full.X.Scale, full.X.Offset, 0, 30) or full
		minBtn.Text = shrunk and "□" or "–"
	end
	bindClick(minBtn, "小窗最小化", function()
		shrunk = not shrunk
		apply()
	end)
end
-- ===== 倒计时器 COUNTDOWN（用户：「在防坠落上面增加一个计时，开启之后屏幕生成一个小 UI，
-- 输入要计多少分钟，点确认开始倒数，到 0 提示时间到了，可暂停 / 重置」）=====
-- 说明：纯界面小部件，不碰角色；Stepped 维持循环在 render step 里 tick
CdTotal, CdRemain, CdRunning, CdPaused = 0, 0, false, false
CdShownSec = -1
-- v5.48：最小化态——缩起来时完整小窗收起、屏幕顶部中间出一个小 pill 继续显示时间
-- （用户：「倒计时的 UI 缩小之后，倒计时会出现在屏幕中心上方」）
CdMinimized = false
function cdFmt(s)
	s = math.max(0, math.floor(s + 0.5))
	return string.format("%02d:%02d", math.floor(s / 60), s % 60)
end
-- v5.54：小窗位置记忆改用普通 Lua 表（Roblox 实例不能随便挂自定义属性，
-- 之前用 instance.SavedPos 赋值会在真机每帧拖动时抛 not a valid member，导致小窗行为异常）
WinPos = {}
function cdBuild()
	if CdFrame then return end
	CdFrame = new("Frame", { Name = "HonCountdown",
		Size = UDim2.new(0, 176, 0, 126), Position = UDim2.new(0.5, -88, 0, 96),
		BackgroundColor3 = Color3.fromRGB(16, 19, 28), BackgroundTransparency = 0.08,
		BorderSizePixel = 0, Visible = false, Parent = Gui })
	corner(CdFrame, 12)
	new("UIStroke", { Color = Mode().Accent, Transparency = 0.5, Thickness = 1, Parent = CdFrame })
	CdTitleL = label({ Text = "倒计时 COUNTDOWN", Font = Enum.Font.GothamBold, TextSize = 10,
		TextColor3 = Color3.fromRGB(140, 148, 168), Position = UDim2.new(0, 12, 0, 8),
		Size = UDim2.new(1, -24, 0, 14), TextXAlignment = Enum.TextXAlignment.Left }, CdFrame)
	CdTimeL = label({ Text = "00:00", Font = Enum.Font.GothamBold, TextSize = 30,
		TextColor3 = Color3.fromRGB(238, 243, 255), Position = UDim2.new(0, 4, 0, 24),
		Size = UDim2.new(1, -8, 0, 36), TextXAlignment = Enum.TextXAlignment.Center }, CdFrame)
	CdInput = new("TextBox", { Name = "CdMin", PlaceholderText = "分钟", Text = "",
		Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Color3.fromRGB(226, 233, 248),
		PlaceholderColor3 = Color3.fromRGB(105, 113, 134),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.92,
		BorderSizePixel = 0, ClearTextOnFocus = false,
		Size = UDim2.new(0, 152, 0, 24), Position = UDim2.new(0, 12, 0, 66), Parent = CdFrame })
	corner(CdInput, 8)
	CdOkBtn = new("TextButton", { Text = "确认", Font = Enum.Font.GothamBold, TextSize = 11,
		TextColor3 = Mode().Accent, BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.88, BorderSizePixel = 0, AutoButtonColor = false,
		Size = UDim2.new(0, 46, 0, 24), Position = UDim2.new(0, 12, 0, 96), Parent = CdFrame })
	corner(CdOkBtn, 8)
	CdPauseBtn = new("TextButton", { Text = "暂停", Font = Enum.Font.GothamBold, TextSize = 11,
		TextColor3 = Mode().Accent, BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.88, BorderSizePixel = 0, AutoButtonColor = false,
		Size = UDim2.new(0, 46, 0, 24), Position = UDim2.new(0, 65, 0, 96), Parent = CdFrame })
	corner(CdPauseBtn, 8)
	CdResetBtn = new("TextButton", { Text = "重置", Font = Enum.Font.GothamBold, TextSize = 11,
		TextColor3 = Mode().Accent, BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.88, BorderSizePixel = 0, AutoButtonColor = false,
		Size = UDim2.new(0, 46, 0, 24), Position = UDim2.new(0, 118, 0, 96), Parent = CdFrame })
	corner(CdResetBtn, 8)
	bindClick(CdOkBtn, "倒计时确认", function() cdConfirm() end)
	bindClick(CdPauseBtn, "倒计时暂停", function() cdPause() end)
	bindClick(CdResetBtn, "倒计时重置", function() cdReset() end)
	-- v5.48：最小化——「–」收小窗，倒计时改到屏幕顶部中间的小 pill 上继续跑
	CdMinBtn = new("TextButton", { Text = "–", Font = Enum.Font.GothamBold, TextSize = 14,
		TextColor3 = Color3.fromRGB(150, 158, 180), BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.9, BorderSizePixel = 0, AutoButtonColor = false,
		Size = UDim2.new(0, 22, 0, 22), Position = UDim2.new(1, -30, 0, 6), Parent = CdFrame })
	corner(CdMinBtn, 6)
	bindClick(CdMinBtn, "倒计时最小化", function() cdSetMini(true) end)
	CdMini = new("Frame", { Name = "HonCdMini",
		Size = UDim2.new(0, 150, 0, 40), Position = UDim2.new(0.5, -75, 0, 8),
		BackgroundColor3 = Color3.fromRGB(16, 19, 28), BackgroundTransparency = 0.08,
		BorderSizePixel = 0, Visible = false, Parent = Gui })
	corner(CdMini, 10)
	new("UIStroke", { Color = Mode().Accent, Transparency = 0.5, Thickness = 1, Parent = CdMini })
	CdMiniL = new("TextButton", { Text = "00:00", Font = Enum.Font.GothamBold, TextSize = 22,
		TextColor3 = Color3.fromRGB(238, 243, 255), BackgroundTransparency = 1,
		BorderSizePixel = 0, AutoButtonColor = false,
		Position = UDim2.new(0, 12, 0, 9), Size = UDim2.new(0, 78, 0, 22),
		TextXAlignment = Enum.TextXAlignment.Left, Parent = CdMini })
	bindClick(CdMiniL, "倒计时展开", function() cdSetMini(false) end)
	CdMiniOpen = new("TextButton", { Text = "展开", Font = Enum.Font.GothamBold, TextSize = 10,
		TextColor3 = Mode().Accent, BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.88, BorderSizePixel = 0, AutoButtonColor = false,
		Size = UDim2.new(0, 46, 0, 24), Position = UDim2.new(1, -58, 0, 8), Parent = CdMini })
	corner(CdMiniOpen, 8)
	bindClick(CdMiniOpen, "倒计时展开", function() cdSetMini(false) end)
	-- 小 UI 随时可挪：窗体 / 标题条当把手，时间大字不再可拖动（固定在窗内）
	local function cdDragHook(o, onMove)
		if not o then return end
		local dragging, startMouse, basePos, moved = false, nil, nil, 0
		o.InputBegan:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
				dragging, startMouse, basePos, moved = true, i.Position, o.Position, 0
			end
		end)
		UserInputService.InputChanged:Connect(function(i)
			if dragging and (i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseMovement) then
				local d = i.Position - startMouse
				moved = math.max(moved, math.abs(d.X) + math.abs(d.Y))
				o.Position = UDim2.new(basePos.X.Scale, basePos.X.Offset + d.X,
					basePos.Y.Scale, basePos.Y.Offset + d.Y)
				if onMove then onMove(o.Position) end
			end
		end)
		UserInputService.InputEnded:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
				dragging = false
			end
		end)
	end
	cdDragHook(CdFrame, function(p) WinPos.CdFrame = p end)
	cdDragHook(CdTitleL, function(p) WinPos.CdFrame = p end)
	cdDragHook(CdMini, function(p) WinPos.CdMini = p end)   -- 最小化 pill 也能随手挪
end
function cdSetMini(on)
	CdMinimized = on and true or false
	if CdFrame then CdFrame.Visible = not on; if (not on) and WinPos.CdFrame then CdFrame.Position = WinPos.CdFrame end end
	if CdMini then CdMini.Visible = on; if on and WinPos.CdMini then CdMini.Position = WinPos.CdMini end end
	cdPaint()
end
function cdPaint()
	if not (CdFrame and CdFrame.Parent) then return end
	local sec = math.max(0, math.ceil(CdRemain - 0.0001))
	if sec ~= CdShownSec then
		CdShownSec = sec
		CdTimeL.Text = cdFmt(sec)
		-- 最后 10 秒染红，肉眼就知道要到了
		CdTimeL.TextColor3 = (CdRunning and not CdPaused and sec <= 10)
			and Color3.fromRGB(255, 96, 96) or Color3.fromRGB(238, 243, 255)
	end
	if CdPauseBtn then CdPauseBtn.Text = CdPaused and "继续" or "暂停" end
	-- v5.48：最小化 pill 同步时间与最后 10 秒染红（时间照常走，缩不缩都在跑）
	if CdMiniL and CdMiniL.Parent then
		CdMiniL.Text = cdFmt(sec)
		CdMiniL.TextColor3 = (CdRunning and not CdPaused and sec <= 10)
			and Color3.fromRGB(255, 96, 96) or Color3.fromRGB(238, 243, 255)
	end
end
function cdConfirm()
	local txt = CdInput and tostring(CdInput.Text or "") or ""
	local m = tonumber(txt)
	if not m or m <= 0 then
		if notify then notify("请输入大于 0 的分钟数（如 1 或 1.5）", Color3.fromRGB(255, 176, 32)) end
		return
	end
	if m > 1440 then m = 1440 end
	CdTotal = m * 60
	CdRemain = CdTotal
	CdRunning, CdPaused = true, false
	CdShownSec = -1
	cdPaint()
	if notify then notify("倒计时开始 · " .. cdFmt(CdTotal)) end
end
function cdPause()
	if not CdRunning then
		if notify then notify("倒计时还没开始：先输分钟数点确认", Color3.fromRGB(255, 176, 32)) end
		return
	end
	CdPaused = not CdPaused
	cdPaint()
	if notify then notify(CdPaused and "倒计时已暂停" or "倒计时继续") end
end
function cdReset()
	CdRunning, CdPaused = false, false
	CdRemain = CdTotal or 0
	CdShownSec = -1
	cdPaint()
	if notify then notify("倒计时已重置 · " .. cdFmt(CdRemain)) end
end
function cdFinish()
	CdRunning, CdPaused = false, false
	CdRemain = 0
	CdShownSec = -1
	cdPaint()
	if notify then notify("时间到了！倒计时结束", Color3.fromRGB(255, 176, 32)) end
end
function cdTick(dt)
	if not (CdRunning and not CdPaused) or CdRemain <= 0 then return end
	CdRemain = CdRemain - (dt or 0)
	if CdRemain <= 0 then
		CdRemain = 0
		cdFinish()
	else
		cdPaint()
	end
end
-- ===== 加速小窗 SPEED WIN（用户：「再给弄个加速，做个小窗，可以在小窗上面切换速度和模式」）=====
-- 引擎页开关唤出；W / V / CF 三模式按钮直切 SetMode；速度 ± 步进 1（v5.48 起一点一点加），
-- 与主 UI 速度滑条双向同步（走 SpeedSlider.Apply）；标题条 + 数字区当把手整块拖；
-- × 收起、– 最小化缩成标题条（v5.48）
SpeedWinBtns = {}
function speedWinBuild()
	if SpeedWin then return end
	SpeedWin = new("Frame", { Name = "HonSpeedWin",
		Size = UDim2.new(0, 176, 0, 148), Position = UDim2.new(0, 14, 0, 96),
		BackgroundColor3 = Color3.fromRGB(16, 19, 28), BackgroundTransparency = 0.08,
		BorderSizePixel = 0, Visible = false, Parent = Gui })
	corner(SpeedWin, 12)
	SpeedWinStroke = new("UIStroke", { Color = Mode().Accent, Transparency = 0.5, Thickness = 1, Parent = SpeedWin })
	SpeedWinTitleL = label({ Text = "加速 SPEED", Font = Enum.Font.GothamBold, TextSize = 10,
		TextColor3 = Color3.fromRGB(140, 148, 168), Position = UDim2.new(0, 12, 0, 8),
		Size = UDim2.new(1, -80, 0, 14), TextXAlignment = Enum.TextXAlignment.Left }, SpeedWin)
	SpeedWinCloseBtn = new("TextButton", { Text = "×", Font = Enum.Font.GothamBold, TextSize = 14,
		TextColor3 = Color3.fromRGB(150, 158, 180), BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.9, BorderSizePixel = 0, AutoButtonColor = false,
		Size = UDim2.new(0, 22, 0, 22), Position = UDim2.new(1, -30, 0, 6), Parent = SpeedWin })
	corner(SpeedWinCloseBtn, 6)
	-- v5.48：最小化（缩成标题条，再点展开）
	SpeedWinMinBtn = new("TextButton", { Text = "–", Font = Enum.Font.GothamBold, TextSize = 14,
		TextColor3 = Color3.fromRGB(150, 158, 180), BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.9, BorderSizePixel = 0, AutoButtonColor = false,
		Size = UDim2.new(0, 22, 0, 22), Position = UDim2.new(1, -56, 0, 6), Parent = SpeedWin })
	corner(SpeedWinMinBtn, 6)
	-- 三模式按钮：W / V / CF 直切（高亮当前模式）
	for i, m in ipairs(Modes) do
		local b = new("TextButton", { Text = m.Id, Font = Enum.Font.GothamBold, TextSize = 12,
			TextColor3 = Color3.fromRGB(224, 231, 246), BackgroundColor3 = Color3.fromRGB(38, 42, 58),
			BorderSizePixel = 0, AutoButtonColor = false,
			Size = UDim2.new(0, 50, 0, 26), Position = UDim2.new(0, 12 + (i - 1) * 56, 0, 30), Parent = SpeedWin })
		corner(b, 8)
		SpeedWinBtns[i] = b
		bindClick(b, "小窗模式" .. m.Id, function() SetMode(i) end)
	end
	-- 当前速度大字 + 单位
	SpeedWinNumL = label({ Text = "0", Font = Enum.Font.GothamBold, TextSize = 34,
		TextColor3 = Color3.fromRGB(238, 243, 255), Position = UDim2.new(0, 4, 0, 62),
		Size = UDim2.new(1, -8, 0, 42), TextXAlignment = Enum.TextXAlignment.Center }, SpeedWin)
	label({ Text = "sp", Font = Enum.Font.GothamBold, TextSize = 10,
		TextColor3 = Color3.fromRGB(140, 148, 168), Position = UDim2.new(0, 0, 0, 104),
		Size = UDim2.new(1, 0, 0, 12), TextXAlignment = Enum.TextXAlignment.Center }, SpeedWin)
	-- 速度 ±（步进 10）
	SpeedWinMinusBtn = new("TextButton", { Text = "−", Font = Enum.Font.GothamBold, TextSize = 18,
		TextColor3 = Mode().Accent, BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.88, BorderSizePixel = 0, AutoButtonColor = false,
		Size = UDim2.new(0, 74, 0, 28), Position = UDim2.new(0, 12, 0, 112), Parent = SpeedWin })
	corner(SpeedWinMinusBtn, 8)
	SpeedWinPlusBtn = new("TextButton", { Text = "+", Font = Enum.Font.GothamBold, TextSize = 18,
		TextColor3 = Mode().Accent, BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.88, BorderSizePixel = 0, AutoButtonColor = false,
		Size = UDim2.new(0, 74, 0, 28), Position = UDim2.new(1, -86, 0, 112), Parent = SpeedWin })
	corner(SpeedWinPlusBtn, 8)
	bindClick(SpeedWinCloseBtn, "加速小窗关闭", function()
		SpeedWin.Visible = false
		if SpeedWinTgl then SpeedWinTgl.Set(false, true) end
	end)
	-- v5.48：± 一点一点加（用户：「要一点一点的增加，而不是一下就加 10」）——与主滑条
	-- 整数粒度一致，长按习惯靠主滑条 / 大改直接拖滑条
	bindClick(SpeedWinMinusBtn, "加速小窗减速", function() speedWinStep(-1) end)
	bindClick(SpeedWinPlusBtn, "加速小窗加速", function() speedWinStep(1) end)
	-- 小窗随时可挪：只有窗体 / 标题条当把手，数字区不再可拖动（数字固定在窗内不漂移）
	local function swDragHook(o, onMove)
		if not o then return end
		local dragging, startMouse, basePos = false, nil, nil
		o.InputBegan:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
				dragging, startMouse, basePos = true, i.Position, o.Position
			end
		end)
		UserInputService.InputChanged:Connect(function(i)
			if dragging and (i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseMovement) then
				local d = i.Position - startMouse
				o.Position = UDim2.new(basePos.X.Scale, basePos.X.Offset + d.X,
					basePos.Y.Scale, basePos.Y.Offset + d.Y)
				if onMove then onMove(o.Position) end
			end
		end)
		UserInputService.InputEnded:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
				dragging = false
			end
		end)
	end
	swDragHook(SpeedWin, function(p) WinPos.SpeedWin = p end)
	winMinSetup(SpeedWin, SpeedWinMinBtn, { SpeedWinTitleL, SpeedWinCloseBtn })
end
function speedWinStep(d)
	local m = Mode()
	local v = math.clamp(math.floor((State.Speed or 0) + d + 0.5), m.Min, m.Max)
	SpeedSlider.Apply(v)   -- 触发 onChange → 写 State.Speed + 刷主 UI 滑条
	speedWinRefresh()
end
function speedWinRefresh()
	if not (SpeedWin and SpeedWin.Parent) then return end
	local m = Mode()
	if SpeedWinStroke then SpeedWinStroke.Color = m.Accent end
	for i, b in ipairs(SpeedWinBtns) do
		local act = (i == State.ModeIndex)
		b.BackgroundColor3 = act and m.Accent or Color3.fromRGB(38, 42, 58)
		b.TextColor3 = act and Color3.fromRGB(16, 19, 28) or Color3.fromRGB(150, 158, 180)
	end
	if SpeedWinNumL then
		SpeedWinNumL.Text = tostring(math.floor((State.Speed or 0) + 0.5))
		SpeedWinNumL.TextColor3 = m.Accent
	end
	for _, b in ipairs({ SpeedWinMinusBtn, SpeedWinPlusBtn }) do
		if b then b.TextColor3 = m.Accent end
	end
end
CdTgl = makeToggle(PageTool, 152, "倒计时器 COUNTDOWN", "屏幕小 UI · 输入分钟数倒数，到点提醒", false, function(v)
	State.Countdown = v
	cdBuild()
	if v then
		-- 最小化过就回顶部中间的小 pill，否则给完整小窗（都恢复到关闭前位置）
		if CdMinimized then
			if CdMini then CdMini.Visible = true; if WinPos.CdMini then CdMini.Position = WinPos.CdMini end end
		elseif CdFrame then
			CdFrame.Visible = true; if WinPos.CdFrame then CdFrame.Position = WinPos.CdFrame end
		end
		cdPaint()
	else
		-- 关开关 = 收界面并停表（下次开从完整小窗开始，不清空已输入的总时长）
		if CdFrame then CdFrame.Visible = false end
		if CdMini then CdMini.Visible = false end
		CdMinimized = false
		CdRunning, CdPaused = false, false
	end
end, true)
AntiVoidTgl = makeToggle(PageTool, 200, "防坠落 ANTI-VOID", "掉出地图自动拉回安全点", false, function(v)
	State.AntiVoid = v
end)
   local FakeTgl = makeToggle(PageTool, 248, "分身隐身 FAKE CHAR", "改的是本体（有网络所有权，会同步）", false, function(v)
	setFakeChar(v)
end)
BrightTgl = makeToggle(PageTool, 296, "夜视 FULLBRIGHT", "去雾 + 全亮，关闭时还原", false, function(v)
	setFullbright(v)
end)
AntiKbTgl = makeToggle(PageTool, 344, "防击退 ANTI-KB", "限制异常击飞速度", false, function(v)
	State.AntiKB = v
end)
AntiStunTgl = makeToggle(PageTool, 392, "防失控 ANTI-STUN", "自动解除被眩晕 / 被坐下", false, function(v)
	State.AntiStun = v
end)
GravitySlider = makeSlider(PageTool, "重力 GRAVITY", 450, -200, 300, math.floor(Workspace.Gravity + 0.5), " g",
	function(v) Workspace.Gravity = v end, false)
SparkTgl = makeToggle(PageTool, 502, "闪电尖兵大招 SPARK ULT", "点击画面任意位置直接传送过去（照搬参考源码）", false, function(v)
	State.SparkTP = v
end)
label({ Text = "传 送 TELEPORT", Font = Enum.Font.GothamBold, TextSize = 11,
	TextColor3 = Color3.fromRGB(120, 129, 152), Size = UDim2.new(1, 0, 0, 18),
	Position = UDim2.new(0, 2, 0, 0), TextXAlignment = Enum.TextXAlignment.Left }, PageTp)
label({ Text = "传 送 玩 家 PLAYER TP", Font = Enum.Font.GothamBold, TextSize = 11,
	TextColor3 = Color3.fromRGB(196, 204, 224), Size = UDim2.new(1, 0, 0, 16),
	Position = UDim2.new(0, 2, 0, 24), TextXAlignment = Enum.TextXAlignment.Left }, PageTp)
local ViewBtn = new("TextButton", { Text = "查看玩家 VIEW PLAYER", Font = Enum.Font.GothamBold, TextSize = 11,
	TextColor3 = Mode().Accent, BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.9,
	BorderSizePixel = 0, AutoButtonColor = false,
	Size = UDim2.new(1, 0, 0, 34), Position = UDim2.new(0, 0, 0, 1098), Parent = PageTp })
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
			notify("该玩家角色还没加载", Color3.fromRGB(255, 176, 32))
		end
	end, nil, "选择要查看的玩家")
end)
local CamBackBtn = new("TextButton", { Text = "恢复自己的视角", Font = Enum.Font.GothamBold, TextSize = 11,
	TextColor3 = Color3.fromRGB(190, 198, 220), BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	BackgroundTransparency = 0.9, BorderSizePixel = 0, AutoButtonColor = false,
	Size = UDim2.new(1, 0, 0, 34), Position = UDim2.new(0, 0, 0, 1138), Parent = PageTp })
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
	Size = UDim2.new(1, 0, 0, 36), Position = UDim2.new(0, 0, 0, 44), Parent = PageTp })
corner(TargetBtn, 10)
table.insert(ToolBtns, TargetBtn)
local TPListWrap = new("Frame", { Size = UDim2.new(1, 0, 0, 150), Position = UDim2.new(0, 0, 0, 86),
	BackgroundColor3 = Color3.fromRGB(20, 23, 33), BackgroundTransparency = 0.25,
	BorderSizePixel = 0, Visible = false, ClipsDescendants = true, Parent = PageTp })
corner(TPListWrap, 10)
new("UIStroke", { Color = Modes[1].Accent, Transparency = 0.75, Thickness = 1, Parent = TPListWrap })
local TPList = new("ScrollingFrame", { Size = UDim2.new(1, -8, 1, -8), Position = UDim2.new(0, 4, 0, 4),
	BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4,
	ScrollBarImageTransparency = 0.5, CanvasSize = UDim2.new(0, 0, 0, 0), Parent = TPListWrap })
TPListLayout = new("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder, Parent = TPList })
function pickTarget(kind, ref, name)
	TPTarget = { Kind = kind, Ref = ref, Name = name }
	TargetBtn.Text = "目标：" .. name
	TPListWrap.Visible = false
	if notify then notify("已选择目标：" .. name) end
end
function refreshTargetList()
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
function tpTargetCF()
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
	Size = UDim2.new(1, 0, 0, 36), Position = UDim2.new(0, 0, 0, 244), Parent = PageTp })
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
local TPLoopTgl = makeToggle(PageTp, 288, "循环传送 LOOP TP", "持续锁定目标（离开即停）", false, function(v)
	State.TPLoop = v
	if v and not TPTarget and notify then
		notify("请先选择目标", Color3.fromRGB(255, 108, 118))
		State.TPLoop = false
		if TPLoopTgl then TPLoopTgl.Set(false, true) end
	end
end)
TPSpeedSlider = makeSlider(PageTp, "循环间隔 (0=每帧)", 336, 0, 20, 0, " 秒", function(v)
	State.TPInterval = v / 10
end, false)
TPOffSlider = makeSlider(PageTp, "高度偏移", 390, 0, 30, 3, " m", function(v)
	State.TPOffsetY = v
end, false)
-- ---------- 坐标 / 标点传送 ----------
Waypoints = {}
WP_FILE = "HonSpeedHub_Waypoints.json"
WPSelIdx = 0
function wpSave()
	local slim = {}
	for i, w in ipairs(Waypoints) do
		slim[i] = { n = string.sub(tostring(w.n or ("点" .. i)), 1, 14),
			x = math.floor(w.x or 0), y = math.floor(w.y or 0), z = math.floor(w.z or 0) }
	end
	local ok, json = pcall(function() return HttpService:JSONEncode(slim) end)
	if not ok or not json then return end
	pcall(function() if writefile then writefile(WP_FILE, json) end end)
	pcall(function() TeleportService:SetTeleportSetting("HON_WP", json) end)
end
function wpLoad()
	local data = nil
	pcall(function()
		if isfile and readfile and isfile(WP_FILE) then
			local ok, d = pcall(function() return HttpService:JSONDecode(readfile(WP_FILE)) end)
			if ok and type(d) == "table" then data = d end
		end
	end)
	if not data then
		pcall(function()
			local raw = TeleportService:GetTeleportSetting("HON_WP")
			if raw and raw ~= "" then
				local ok, d = pcall(function() return HttpService:JSONDecode(raw) end)
				if ok and type(d) == "table" then data = d end
			end
		end)
	end
	if data then
		Waypoints = {}
		for _, w in ipairs(data) do
			if type(w) == "table" and w.x then
				table.insert(Waypoints, { n = tostring(w.n or "点"), x = w.x or 0, y = w.y or 0, z = w.z or 0 })
			end
		end
	end
end
wpLoad()
function tpToPos(x, y, z)
	if not (HRP and HRP.Parent) then
		if notify then notify("角色还没加载", Color3.fromRGB(255, 108, 118)) end
		return
	end
	pcall(function() HRP.CFrame = CFrame.new(x, y, z) end)
end

label({ Text = "坐 标 传 送 COORD TP", Font = Enum.Font.GothamBold, TextSize = 11,
	TextColor3 = Color3.fromRGB(120, 129, 152), Size = UDim2.new(1, 0, 0, 16),
	Position = UDim2.new(0, 2, 0, 442), TextXAlignment = Enum.TextXAlignment.Left }, PageTp)
local CoordLbl = label({ Text = "当前坐标：读取中…", Font = Enum.Font.GothamBold, TextSize = 12,
	TextColor3 = Color3.fromRGB(150, 220, 255), Size = UDim2.new(1, 0, 0, 18),
	Position = UDim2.new(0, 2, 0, 464), TextXAlignment = Enum.TextXAlignment.Left }, PageTp)
function mkNumBox(x, ph)
	return new("TextBox", { PlaceholderText = ph, Text = "", Font = Enum.Font.GothamBold, TextSize = 12,
		TextColor3 = Color3.fromRGB(238, 243, 255), PlaceholderColor3 = Color3.fromRGB(110, 118, 140),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.92,
		BorderSizePixel = 0, ClearTextOnFocus = false,
		Size = UDim2.new(0.32, -4, 0, 32), Position = UDim2.new(x, 0, 0, 488), Parent = PageTp })
end
corner(mkNumBox(0, "X"), 8); corner(mkNumBox(0.34, "Y"), 8); corner(mkNumBox(0.67, "Z"), 8)
local CxBox, CyBox, CzBox = nil, nil, nil
do
	local boxes = {}
	for _, c in ipairs(PageTp:GetChildren()) do
		if c:IsA("TextBox") then table.insert(boxes, c) end
	end
	table.sort(boxes, function(a, b) return a.Position.X.Offset < b.Position.X.Offset end)
	CxBox, CyBox, CzBox = boxes[#boxes - 2], boxes[#boxes - 1], boxes[#boxes]
end
local CoordTpBtn = new("TextButton", { Text = "传送到坐标 GO", Font = Enum.Font.GothamBold, TextSize = 11,
	TextColor3 = Color3.fromRGB(150, 220, 255), BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	BackgroundTransparency = 0.9, BorderSizePixel = 0, AutoButtonColor = false,
	Size = UDim2.new(0.62, -4, 0, 32), Position = UDim2.new(0, 0, 0, 528), Parent = PageTp })
corner(CoordTpBtn, 8)
table.insert(ToolBtns, CoordTpBtn)
bindClick(CoordTpBtn, "坐标传送", function()
	local x = tonumber(CxBox and CxBox.Text) or 0
	local y = tonumber(CyBox and CyBox.Text) or 0
	local z = tonumber(CzBox and CzBox.Text) or 0
	tpToPos(x, y, z)
	if notify then notify(string.format("已传送到 X %d · Y %d · Z %d", x, y, z)) end
end)
local CurPosBtn = new("TextButton", { Text = "填入当前", Font = Enum.Font.GothamBold, TextSize = 11,
	TextColor3 = Color3.fromRGB(190, 198, 220), BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	BackgroundTransparency = 0.9, BorderSizePixel = 0, AutoButtonColor = false,
	Size = UDim2.new(0.38, 0, 0, 32), Position = UDim2.new(0.62, 4, 0, 528), Parent = PageTp })
corner(CurPosBtn, 8)
table.insert(ToolBtns, CurPosBtn)
bindClick(CurPosBtn, "填入当前坐标", function()
	if not (HRP and HRP.Parent) then return end
	local q = HRP.Position
	CxBox.Text = tostring(math.floor(q.X))
	CyBox.Text = tostring(math.floor(q.Y))
	CzBox.Text = tostring(math.floor(q.Z))
end)
label({ Text = "标 点 WAYPOINTS · 自动存档 · 换服不丢", Font = Enum.Font.GothamBold, TextSize = 11,
	TextColor3 = Color3.fromRGB(120, 129, 152), Size = UDim2.new(1, 0, 0, 16),
	Position = UDim2.new(0, 2, 0, 570), TextXAlignment = Enum.TextXAlignment.Left }, PageTp)
local WpNameBox = new("TextBox", { PlaceholderText = "标点名称（如：家 / 刷怪点）", Text = "",
	Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = Color3.fromRGB(238, 243, 255),
	PlaceholderColor3 = Color3.fromRGB(110, 118, 140), BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	BackgroundTransparency = 0.92, BorderSizePixel = 0, ClearTextOnFocus = false,
	Size = UDim2.new(0.58, -4, 0, 30), Position = UDim2.new(0, 0, 0, 594), Parent = PageTp })
corner(WpNameBox, 8)
local WpSaveBtn = new("TextButton", { Text = "保存当前位置", Font = Enum.Font.GothamBold, TextSize = 11,
	TextColor3 = Mode().Accent, BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	BackgroundTransparency = 0.9, BorderSizePixel = 0, AutoButtonColor = false,
	Size = UDim2.new(0.42, 0, 0, 30), Position = UDim2.new(0.58, 4, 0, 594), Parent = PageTp })
corner(WpSaveBtn, 8)
table.insert(ToolBtns, WpSaveBtn)
local WPListWrap = new("Frame", { Size = UDim2.new(1, 0, 0, 300), Position = UDim2.new(0, 0, 0, 632),
	BackgroundColor3 = Color3.fromRGB(20, 23, 33), BackgroundTransparency = 0.25,
	BorderSizePixel = 0, ClipsDescendants = true, Parent = PageTp })
corner(WPListWrap, 10)
new("UIStroke", { Color = Modes[1].Accent, Transparency = 0.75, Thickness = 1, Parent = WPListWrap })
local WPList = new("ScrollingFrame", { Size = UDim2.new(1, -8, 1, -8), Position = UDim2.new(0, 4, 0, 4),
	BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4,
	ScrollBarImageTransparency = 0.5, CanvasSize = UDim2.new(0, 0, 0, 0), Parent = WPListWrap })
function wpRefresh()
	for _, c in ipairs(WPList:GetChildren()) do
		if c:IsA("Frame") or c:IsA("TextButton") then c:Destroy() end
	end
	for i, w in ipairs(Waypoints) do
		local row = new("Frame", { Size = UDim2.new(1, -4, 0, 28), Position = UDim2.new(0, 2, 0, (i - 1) * 31),
			BackgroundTransparency = 1, Parent = WPList })
		local nm = new("TextButton", { Text = string.format("%d. %s  (%d, %d, %d)", i, tostring(w.n), w.x, w.y, w.z),
			Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = Color3.fromRGB(226, 233, 248),
			BackgroundTransparency = 1, BorderSizePixel = 0, AutoButtonColor = false,
			Size = UDim2.new(0.66, 0, 1, 0), TextXAlignment = Enum.TextXAlignment.Left, Parent = row })
		local sel = new("TextButton", { Text = WPSelIdx == i and "★" or "☆", Font = Enum.Font.Gotham, TextSize = 12,
			TextColor3 = WPSelIdx == i and Color3.fromRGB(255, 210, 90) or Color3.fromRGB(140, 149, 172),
			BackgroundTransparency = 1, BorderSizePixel = 0, AutoButtonColor = false,
			Size = UDim2.new(0.10, 0, 1, 0), Parent = row })
		local go = new("TextButton", { Text = "去", Font = Enum.Font.GothamBold, TextSize = 11,
			TextColor3 = Color3.fromRGB(150, 220, 255), BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 0.9, BorderSizePixel = 0, AutoButtonColor = false,
			Size = UDim2.new(0.11, 0, 0, 22), Position = UDim2.new(0.75, 0, 0, 3), Parent = row })
		corner(go, 6)
		local del = new("TextButton", { Text = "删", Font = Enum.Font.GothamBold, TextSize = 11,
			TextColor3 = Color3.fromRGB(255, 108, 118), BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 0.9, BorderSizePixel = 0, AutoButtonColor = false,
			Size = UDim2.new(0.11, 0, 0, 22), Position = UDim2.new(0.88, 0, 0, 3), Parent = row })
		corner(del, 6)
		nm.MouseButton1Click:Connect(function() tpToPos(w.x, w.y, w.z); if notify then notify("已传送到：" .. tostring(w.n)) end end)
		sel.MouseButton1Click:Connect(function()
			WPSelIdx = (WPSelIdx == i) and 0 or i
			wpRefresh()
			if notify then notify(WPSelIdx == i and ("已选中：" .. tostring(w.n)) or "已取消选中") end
		end)
		go.MouseButton1Click:Connect(function() tpToPos(w.x, w.y, w.z); if notify then notify("已传送到：" .. tostring(w.n)) end end)
		del.MouseButton1Click:Connect(function()
			table.remove(Waypoints, i)
			if WPSelIdx == i then WPSelIdx = 0 elseif WPSelIdx > i then WPSelIdx = WPSelIdx - 1 end
			wpSave(); wpRefresh()
			if notify then notify("已删除标点：" .. tostring(w.n)) end
		end)
	end
	WPList.CanvasSize = UDim2.new(0, 0, 0, math.max(#Waypoints * 31 + 6, 1))
	if wpWinRefresh then wpWinRefresh() end   -- 标点小窗开着的话跟着一起刷
end
bindClick(WpSaveBtn, "保存标点", function()
	if not (HRP and HRP.Parent) then
		if notify then notify("角色还没加载", Color3.fromRGB(255, 108, 118)) end
		return
	end
	local q = HRP.Position
	local nm = WpNameBox.Text
	if nm == "" then nm = "标点 " .. tostring(#Waypoints + 1) end
	table.insert(Waypoints, { n = nm, x = math.floor(q.X), y = math.floor(q.Y), z = math.floor(q.Z) })
	WpNameBox.Text = ""
	wpSave(); wpRefresh()
	if notify then notify("已保存标点：" .. nm .. "（共 " .. #Waypoints .. " 个）") end
end)
wpRefresh()
local WPLoopTgl = makeToggle(PageTp, 948, "标点循环 LOOP", "每隔一段时间传送一次到 ★ 选中标点", false, function(v)
	State.WPLoop = v
	if v and WPSelIdx == 0 and notify then
		notify("请先在标点列表里点 ☆ 选一个", Color3.fromRGB(255, 108, 118))
		State.WPLoop = false
		if WPLoopTgl then WPLoopTgl.Set(false, true) end
	end
end)
makeSlider(PageTp, "循环间隔", 996, 1, 60, 5, " 秒", function(v) State.WPLoopInt = v end, false)
RunService:BindToRenderStep("HonCoord", 9993, function(dt)
	if HON_SHUTDOWN then return end
	WPCoordTimer = (WPCoordTimer or 0) + dt
	if WPCoordTimer < 0.25 then return end
	WPCoordTimer = 0
	if not (CoordLbl and CoordLbl.Parent) then return end
	if HRP and HRP.Parent then
		local q = HRP.Position
		CoordLbl.Text = string.format("当前坐标：X %d   Y %d   Z %d", q.X, q.Y, q.Z)
	end
	-- 标点小窗的坐标条也在这里顺手刷（省一个渲染步）
	if WPWinCoordLbl and WPWinCoordLbl.Parent and HRP and HRP.Parent then
		local q2 = HRP.Position
		WPWinCoordLbl.Text = string.format("X %d   Y %d   Z %d", q2.X, q2.Y, q2.Z)
	end
end)

-- ===== 标点传送小窗 WP WIN（用户：「然后那个标点传送也是」——加速小窗同款待遇）=====
-- 传送页开关唤出；当前坐标 + 「存此处」+ 标点列表（☆ 选中 / 去传送）；
-- wpWinRefresh() 独立渲染进小窗列表，不碰页面 wpRefresh（两边数据同一份 Waypoints）
function honDragHook(o, onMove)
	if not o then return end
	local dragging, startMouse, basePos = false, nil, nil
	o.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging, startMouse, basePos = true, i.Position, o.Position
		end
	end)
	UserInputService.InputChanged:Connect(function(i)
		if dragging and (i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseMovement) then
			local d = i.Position - startMouse
			o.Position = UDim2.new(basePos.X.Scale, basePos.X.Offset + d.X,
				basePos.Y.Scale, basePos.Y.Offset + d.Y)
			if onMove then onMove(o.Position) end
		end
	end)
	UserInputService.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)
end
function wpWinBuild()
	if WPWin then return end
	WPWin = new("Frame", { Name = "HonWPWin",
		Size = UDim2.new(0, 176, 0, 228), Position = UDim2.new(0, 14, 0, 256),
		BackgroundColor3 = Color3.fromRGB(16, 19, 28), BackgroundTransparency = 0.08,
		BorderSizePixel = 0, Visible = false, Parent = Gui })
	corner(WPWin, 12)
	WPWinStroke = new("UIStroke", { Color = Color3.fromRGB(150, 220, 255), Transparency = 0.5, Thickness = 1, Parent = WPWin })
	WPWinTitleL = label({ Text = "标点 WP", Font = Enum.Font.GothamBold, TextSize = 10,
		TextColor3 = Color3.fromRGB(140, 148, 168), Position = UDim2.new(0, 12, 0, 8),
		Size = UDim2.new(1, -80, 0, 14), TextXAlignment = Enum.TextXAlignment.Left }, WPWin)
	WPWinCloseBtn = new("TextButton", { Text = "×", Font = Enum.Font.GothamBold, TextSize = 14,
		TextColor3 = Color3.fromRGB(150, 158, 180), BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.9, BorderSizePixel = 0, AutoButtonColor = false,
		Size = UDim2.new(0, 22, 0, 22), Position = UDim2.new(1, -30, 0, 6), Parent = WPWin })
	corner(WPWinCloseBtn, 6)
	-- v5.48：最小化（缩成标题条，再点展开）
	WPWinMinBtn = new("TextButton", { Text = "–", Font = Enum.Font.GothamBold, TextSize = 14,
		TextColor3 = Color3.fromRGB(150, 158, 180), BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.9, BorderSizePixel = 0, AutoButtonColor = false,
		Size = UDim2.new(0, 22, 0, 22), Position = UDim2.new(1, -56, 0, 6), Parent = WPWin })
	corner(WPWinMinBtn, 6)
	-- 当前坐标（HonCoord 渲染步顺手刷）
	WPWinCoordLbl = label({ Text = "X 0   Y 0   Z 0", Font = Enum.Font.GothamBold, TextSize = 12,
		TextColor3 = Color3.fromRGB(150, 220, 255), Position = UDim2.new(0, 12, 0, 28),
		Size = UDim2.new(1, -24, 0, 16), TextXAlignment = Enum.TextXAlignment.Center }, WPWin)
	-- 存此处：一键存当前位置（自动命名）
	WPWinSaveBtn = new("TextButton", { Text = "存此处", Font = Enum.Font.GothamBold, TextSize = 11,
		TextColor3 = Color3.fromRGB(150, 220, 255), BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.88, BorderSizePixel = 0, AutoButtonColor = false,
		Size = UDim2.new(1, -24, 0, 26), Position = UDim2.new(0, 12, 0, 48), Parent = WPWin })
	corner(WPWinSaveBtn, 8)
	-- 标点列表（☆ 选中 / 去传送；删除留在主页面，防误触）
	WPWinListWrap = new("Frame", { Size = UDim2.new(1, -16, 0, 120), Position = UDim2.new(0, 8, 0, 80),
		BackgroundColor3 = Color3.fromRGB(20, 23, 33), BackgroundTransparency = 0.25,
		BorderSizePixel = 0, ClipsDescendants = true, Parent = WPWin })
	corner(WPWinListWrap, 8)
	WPWinList = new("ScrollingFrame", { Size = UDim2.new(1, -8, 1, -8), Position = UDim2.new(0, 4, 0, 4),
		BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3,
		ScrollBarImageTransparency = 0.5, CanvasSize = UDim2.new(0, 0, 0, 0), Parent = WPWinListWrap })
	WPWinCountL = label({ Text = "共 0 个", Font = Enum.Font.Gotham, TextSize = 9,
		TextColor3 = Color3.fromRGB(120, 128, 148), Position = UDim2.new(0, 12, 0, 204),
		Size = UDim2.new(1, -24, 0, 12), TextXAlignment = Enum.TextXAlignment.Left }, WPWin)
	bindClick(WPWinCloseBtn, "标点小窗关闭", function()
		WPWin.Visible = false
		if WPWinTgl then WPWinTgl.Set(false, true) end
	end)
	bindClick(WPWinSaveBtn, "小窗存标点", function()
		if not (HRP and HRP.Parent) then
			if notify then notify("保存失败：角色还没加载", Color3.fromRGB(255, 176, 32)) end
			return
		end
		local q = HRP.Position
		local nm = "标点 " .. tostring(#Waypoints + 1)
		table.insert(Waypoints, { n = nm, x = math.floor(q.X), y = math.floor(q.Y), z = math.floor(q.Z) })
		wpSave(); wpRefresh()   -- wpRefresh 尾部会顺带刷小窗
		if notify then notify("已保存标点：" .. nm .. "（共 " .. #Waypoints .. " 个）") end
	end)
	honDragHook(WPWin, function(p) WinPos.WPWin = p end)
	winMinSetup(WPWin, WPWinMinBtn, { WPWinTitleL, WPWinCloseBtn })
end
function wpWinRefresh()
	if not (WPWin and WPWin.Parent and WPWinList) then return end
	for _, c in ipairs(WPWinList:GetChildren()) do
		if c:IsA("Frame") or c:IsA("TextButton") or c:IsA("TextLabel") then c:Destroy() end
	end
	if #Waypoints == 0 then
		label({ Text = "还没有标点\n点上方「存此处」记一个", Font = Enum.Font.Gotham, TextSize = 10,
			TextColor3 = Color3.fromRGB(105, 113, 134), Position = UDim2.new(0, 8, 0, 34),
			Size = UDim2.new(1, -16, 0, 40), TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Top }, WPWinList)
	end
	for i, w in ipairs(Waypoints) do
		local row = new("Frame", { Size = UDim2.new(1, -4, 0, 26), Position = UDim2.new(0, 2, 0, (i - 1) * 30),
			BackgroundTransparency = 1, Parent = WPWinList })
		local nm = new("TextButton", { Text = string.format("%d.%s", i, tostring(w.n)),
			Font = Enum.Font.Gotham, TextSize = 10,
			TextColor3 = WPSelIdx == i and Color3.fromRGB(255, 210, 90) or Color3.fromRGB(226, 233, 248),
			BackgroundTransparency = 1, BorderSizePixel = 0, AutoButtonColor = false,
			Size = UDim2.new(0.62, 0, 1, 0), TextXAlignment = Enum.TextXAlignment.Left, Parent = row })
		local sel = new("TextButton", { Text = WPSelIdx == i and "★" or "☆", Font = Enum.Font.Gotham, TextSize = 11,
			TextColor3 = WPSelIdx == i and Color3.fromRGB(255, 210, 90) or Color3.fromRGB(140, 149, 172),
			BackgroundTransparency = 1, BorderSizePixel = 0, AutoButtonColor = false,
			Size = UDim2.new(0.14, 0, 1, 0), Parent = row })
		local go = new("TextButton", { Text = "去", Font = Enum.Font.GothamBold, TextSize = 10,
			TextColor3 = Color3.fromRGB(150, 220, 255), BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 0.9, BorderSizePixel = 0, AutoButtonColor = false,
			Size = UDim2.new(0.16, 0, 0, 20), Position = UDim2.new(0.78, 0, 0, 3), Parent = row })
		corner(go, 6)
		nm.MouseButton1Click:Connect(function() tpToPos(w.x, w.y, w.z); wpWinRefresh() end)
		sel.MouseButton1Click:Connect(function()
			WPSelIdx = (WPSelIdx == i) and 0 or i
			wpWinRefresh()
			if notify then notify(WPSelIdx == i and ("已选中：" .. tostring(w.n)) or "已取消选中") end
		end)
		go.MouseButton1Click:Connect(function() tpToPos(w.x, w.y, w.z); wpWinRefresh() end)
	end
	WPWinList.CanvasSize = UDim2.new(0, 0, 0, math.max(#Waypoints * 30 + 6, 1))
	if WPWinCountL then WPWinCountL.Text = "共 " .. #Waypoints .. " 个 · ☆ 选中可循环" end
end
WPWinTgl = makeToggle(PageTp, 1044, "标点小窗 WP WIN", "屏幕小窗 · 看坐标 / 存标点 / ★ 选中传送", false, function(v)
	wpWinBuild()
	if WPWin then
		if v and WinPos.WPWin then WPWin.Position = WinPos.WPWin end
		WPWin.Visible = v
	end
	if v then wpWinRefresh() end
end)

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
lastTransp = -1
RunService.Stepped:Connect(function()
	if HON_SHUTDOWN then return end
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
	-- 内置自动清除身上方块（v5.45，用户：「开启脚本如果出现方块自动清除而不是手动」）：
	-- 旧版这里是有开关才维持、而且维持调用写的是 hideBodyBlocks(false)——false 是还原分支，
	-- 等于每 30 帧把藏起来的方块全部放出来，「隐藏身上方块没有用」的根因就在这一行；
	-- 现在改成无开关常驻：持续把游戏后加上来的附加物压回去，UNLOAD 时才统一还原
	BlockTimer = BlockTimer + 1
	if BlockTimer >= 30 then
		BlockTimer = 0
		pcall(hideBodyBlocks, true)
	end
end)
FAKE_Y = 100000
FakeClone, FakePlatform, FakeBase, FakeAnchor = nil, nil, nil, nil
function cleanupFake()
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
	if HON_SHUTDOWN then return end
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
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if not State.ClickTP and not State.SparkTP then return end
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
label({ Text = "娱 乐 功 能", Font = Enum.Font.GothamBold, TextSize = 11,
	TextColor3 = Color3.fromRGB(120, 129, 152), Size = UDim2.new(1, 0, 0, 18),
	Position = UDim2.new(0, 2, 0, 0), TextXAlignment = Enum.TextXAlignment.Left }, PageFun)
SpinTgl    = makeToggle(PageFun, 24,  "自转 SPIN", "角色原地高速旋转", false, function(v) State.Spin = v end)
RainbowTgl = makeToggle(PageFun, 72,  "彩虹角色 RAINBOW", "本体变色，别人也看得见", false, function(v)
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
BounceTgl = makeToggle(PageFun, 164, "超级弹跳 BOUNCE", "落地自动弹起来", false, function(v) State.Bounce = v end)
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
-- ---------- 娱乐功能生成物（重建：此前整组函数被误删，UI/驱动/恢复逻辑都在，这里按驱动字段契约补回） ----------
Clones, TrailObj, OrbitPart, CarModel, HeroFlyOn = {}, nil, nil, nil, false
CarBackup, TP_Backup, BlockHidden = nil, nil, {}
BlockTimer = 0

-- 彩虹拖尾：两个 Attachment 之间拉彩色光带（Trail 自动渲染，重生后由恢复逻辑重建）
function setTrail(on)
	State.Trail = on
	if not on then
		if TrailObj and TrailObj.Parent then pcall(function() TrailObj:Destroy() end) end
		TrailObj = nil
		return
	end
	if not (HRP and HRP.Parent) then return end
	if TrailObj and TrailObj.Parent then return end
	local a0 = Instance.new("Attachment"); a0.Name = "HonTrailA0"; a0.Position = Vector3.new(0, 1.0, 0); a0.Parent = HRP
	local a1 = Instance.new("Attachment"); a1.Name = "HonTrailA1"; a1.Position = Vector3.new(0, -1.0, 0); a1.Parent = HRP
	local tr = Instance.new("Trail")
	tr.Name = "HonRainbowTrail"
	tr.Attachment0 = a0
	tr.Attachment1 = a1
	tr.Lifetime = 0.55
	tr.MinLength = 0.05
	tr.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 80, 90)),
		ColorSequenceKeypoint.new(0.20, Color3.fromRGB(255, 200, 70)),
		ColorSequenceKeypoint.new(0.40, Color3.fromRGB(120, 240, 120)),
		ColorSequenceKeypoint.new(0.60, Color3.fromRGB(90, 200, 255)),
		ColorSequenceKeypoint.new(0.80, Color3.fromRGB(150, 110, 255)),
		ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 90, 170)),
	})
	tr.Transparency = ColorSequence.new({
		ColorSequenceKeypoint.new(0, 0.15),
		ColorSequenceKeypoint.new(1, 1),
	})
	tr.LightEmission = 0.6
	tr.Parent = HRP
	TrailObj = tr
end

-- 粒子环绕：一个 Neon 小球绕角色公转，身上挂全向粒子发射器
function setOrbitFx(on)
	State.OrbitFx = on
	if not on then
		if OrbitPart and OrbitPart.Parent then pcall(function() OrbitPart:Destroy() end) end
		OrbitPart = nil
		return
	end
	if OrbitPart and OrbitPart.Parent then return end
	local p = Instance.new("Part")
	p.Name = "HonOrbitFx"
	p.Size = Vector3.new(0.6, 0.6, 0.6)
	p.Shape = Enum.PartType.Ball
	p.Anchored = true
	p.CanCollide = false
	p.CastShadow = false
	p.Material = Enum.Material.Neon
	p.Color = Mode().Accent
	p.Parent = Workspace
	local pe = Instance.new("ParticleEmitter")
	pe.Name = "HonOrbitEmitter"
	pe.Rate = 90
	pe.Lifetime = NumberRange.new(0.5, 0.9)
	pe.Speed = NumberRange.new(1.5, 3)
	pe.SpreadAngle = Vector2.new(180, 180)
	pe.Size = NumberSequence.new(0.35)
	pe.Color = ColorSequence.new(Mode().Accent)
	pe.LightEmission = 0.8
	pe.Parent = p
	OrbitPart = p
end

-- 分身军团：5 个半透明分身环绕跟随（贴地射线已由每帧驱动处理，能上楼梯）
function setCloneArmy(on)
	State.CloneArmy = on
	Clones = Clones or {}
	if not on then
		for _, c in ipairs(Clones) do pcall(function() c:Destroy() end) end
		Clones = {}
		return
	end
	if #Clones > 0 then return end
	local c = LP.Character
	if not (c and HRP and HRP.Parent) then return end
	for i = 1, 5 do
		local cl = c:Clone()
		cl.Name = "HonClone" .. i
		cl.Parent = Workspace
		for _, d in ipairs(cl:GetDescendants()) do
			if d:IsA("Script") or d:IsA("LocalScript") then d:Destroy() end
			if d:IsA("BasePart") then d.Transparency = 0.5; d.CanCollide = false; d.CastShadow = false end
		end
		local cr = cl:FindFirstChild("HumanoidRootPart")
		if cr then cr.Anchored = true end
		local hum = cl:FindFirstChildOfClass("Humanoid")
		if hum then hum.Health = math.huge; hum.WalkSpeed = 0; hum.JumpPower = 0 end
		table.insert(Clones, cl)
	end
end

-- FE 变车：隐藏角色 + 6 件套车模（车身/车顶/四轮，驱动按 GetChildren 顺序摆放）
function setCar(on)
	State.Car = on
	CarBackup = CarBackup or {}
	if not on then
		if CarModel and CarModel.Parent then pcall(function() CarModel:Destroy() end) end
		CarModel = nil
		if Character then
			for _, d in ipairs(Character:GetDescendants()) do
				if d:IsA("BasePart") and CarBackup[d] then
					pcall(function() d.Transparency = CarBackup[d] end)
					CarBackup[d] = nil
				end
			end
		end
		return
	end
	if CarModel and CarModel.Parent then return end
	if not (HRP and HRP.Parent) then return end
	if Character then
		for _, d in ipairs(Character:GetDescendants()) do
			if d:IsA("BasePart") and d.Transparency < 1 then
				CarBackup[d] = d.Transparency
				d.Transparency = 1
			end
		end
	end
	local m = Instance.new("Model")
	m.Name = "HonCarModel"
	m.Parent = Workspace
	local body = Instance.new("Part")
	body.Name = "HonCarBody"
	body.Size = Vector3.new(4.4, 1.1, 7.6)
	body.Anchored = true
	body.CanCollide = false
	body.CastShadow = false
	body.Color = Color3.fromRGB(200, 60, 60)
	body.Material = Enum.Material.SmoothPlastic
	body.Parent = m
	local roof = Instance.new("Part")
	roof.Name = "HonCarRoof"
	roof.Size = Vector3.new(3.0, 0.9, 3.4)
	roof.Anchored = true
	roof.CanCollide = false
	roof.CastShadow = false
	roof.Color = Color3.fromRGB(160, 50, 50)
	roof.Material = Enum.Material.SmoothPlastic
	roof.Parent = m
	for i = 1, 4 do
		local w = Instance.new("Part")
		w.Name = "HonCarWheel" .. i
		w.Size = Vector3.new(0.7, 1.3, 1.3)
		w.Shape = Enum.PartType.Cylinder
		w.Anchored = true
		w.CanCollide = false
		w.CastShadow = false
		w.Color = Color3.fromRGB(30, 30, 34)
		w.Material = Enum.Material.Metal
		w.Parent = m
	end
	CarModel = m
end

-- 无敌少侠飞行：复用普通飞行（setFly）+ 悬浮姿态
function setHeroFly(on)
	State.HeroFly = on
	HeroFlyOn = on
	if on then
		if not State.Fly then pcall(setFly, true) end
		if Humanoid and Humanoid.Parent then Humanoid.PlatformStand = true end
	else
		if State.Fly then pcall(setFly, false) end
	end
end

-- 强制第三人称：锁死相机缩放距离（拉不进第一人称），关闭时还原备份
function setThirdPerson(on)
	State.ThirdPerson = on
	pcall(function()
		if on then
			if not TP_Backup then TP_Backup = { Min = LP.CameraMinZoomDistance, Max = LP.CameraMaxZoomDistance } end
			LP.CameraMode = Enum.CameraMode.Classic
			LP.CameraMinZoomDistance = 12
			LP.CameraMaxZoomDistance = 25
			if Humanoid and Humanoid.Parent then Humanoid.CameraOffset = Vector3.new(0, 1.5, 0) end
		else
			local mn, mx = 0.5, 20
			if TP_Backup then mn, mx = TP_Backup.Min, TP_Backup.Max end
			LP.CameraMode = Enum.CameraMode.Classic
			LP.CameraMinZoomDistance = mn
			LP.CameraMaxZoomDistance = mx
			if Humanoid and Humanoid.Parent then Humanoid.CameraOffset = Vector3.zero end
		end
	end)
end

-- 隐藏身上附加物（配件/名牌/框选/高亮等），返回清除数量；关闭时全部还原
function hideBodyBlocks(on)
	BlockHidden = BlockHidden or {}
	if not on then
		for _, q in ipairs(BlockHidden) do
			if q and q.Parent then pcall(function() q.Visible = true end) end
		end
		BlockHidden = {}
		return 0
	end
	if not Character then return 0 end
	for _, v in ipairs(Character:GetDescendants()) do
		if v:IsA("Accoutrement") or v:IsA("BillboardGui") or v:IsA("SelectionBox")
			or v:IsA("Highlight") or v:IsA("SurfaceGui") or v:IsA("Sparkles") then
			if v.Visible then
				pcall(function() v.Visible = false end)
				table.insert(BlockHidden, v)
			end
		end
	end
	return #BlockHidden
end

BlackHoleTgl = makeToggle(PageFun, 304, "黑洞 BLACK HOLE", "在前方生成黑洞，吸住周围一切", false, function(v)
	setBlackHole(v)
end)
BlackHoleSlider = makeSlider(PageFun, "黑洞吸力", 352, 10, 200, 60, " ", function(v)
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
DashRunTgl = makeToggle(PageFun, 1212, "闪电冲刺·持续加速 DASH RUN", "开启后越跑越快，随时可关", false, function(v)
	setDashRun(v)
end)
FlipBtn = new("TextButton", { Text = "倒立 FLIP", Font = Enum.Font.GothamBold, TextSize = 11,
	TextColor3 = Mode().Accent, BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.9,
	BorderSizePixel = 0, AutoButtonColor = false,
	Size = UDim2.new(1, 0, 0, 36), Position = UDim2.new(0, 0, 0, 1164), Parent = PageFun })
corner(FlipBtn, 10)
table.insert(FunBtns, FlipBtn)
FlipBtn.MouseButton1Click:Connect(function()
	if HRP and HRP.Parent then
		HRP.CFrame = HRP.CFrame * CFrame.Angles(0, 0, math.rad(180))
	end
end)

-- ===== 三个新趣味功能（删掉装扮商城后补上的）=====
-- 手写 HSV→RGB：不依赖 Color3.fromHSV，执行器/mock 都稳
function hsv2rgb(h, s, v)
	h = (h % 1) * 6
	local i = math.floor(h)
	local f = h - i
	local p, q, t = v * (1 - s), v * (1 - s * f), v * (1 - s * (1 - f))
	i = i % 6
	if i == 0 then return Color3.new(v, t, p) end
	if i == 1 then return Color3.new(q, v, p) end
	if i == 2 then return Color3.new(p, v, t) end
	if i == 3 then return Color3.new(p, q, v) end
	if i == 4 then return Color3.new(t, p, v) end
	return Color3.new(v, p, q)
end
-- 1) 弹射升空：一键把自己炸上天（2.5s 冷却防连点）
EjectCd = 0
function ejectUp()
	if not (HRP and HRP.Parent) then
		if notify then notify("角色还没就绪", Color3.fromRGB(255, 176, 32)) end
		return
	end
	if tick() < (EjectCd or 0) then
		if notify then notify("弹射冷却中，稍等一下", Color3.fromRGB(255, 205, 110)) end
		return
	end
	EjectCd = tick() + 2.5
	HRP.AssemblyLinearVelocity = Vector3.new(0, 190, 0)
	-- 脚下补一圈烟花，起飞更有仪式感
	pcall(toyFirework)
	if notify then notify("咻——起飞！") end
end
-- 2) 装死倒地：PlatformStand 让角色当场躺平（再点站起来；起身走两步自动退出）
function setPlayDead(on)
	State.PlayDead = on
	if Humanoid and Humanoid.Parent then
		Humanoid.PlatformStand = on and true or false
		if not on then
			pcall(function() Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp) end)
		end
	end
	if notify then notify(on and "已躺平·装死中（再点站起来）" or "已起身") end
end
-- 3) 霓虹发光：全身 Neon + 色相循环（只有自己看得见的本地特效；记录原材质/颜色，关闭还原）
NeonBackup, NeonHue = nil, 0
function setNeonGlow(on)
	State.NeonGlow = on
	local ch = LP and LP.Character
	if on then
		if not ch then
			if notify then notify("角色还没就绪", Color3.fromRGB(255, 176, 32)) end
			return
		end
		if NeonBackup then return end
		NeonBackup = {}
		for _, p in ipairs(ch:GetChildren()) do
			if p:IsA("BasePart") then
				NeonBackup[p] = { M = p.Material, C = p.Color }
			end
		end
		-- 开启瞬间就应用一次，不用等下一帧
		for p, _ in pairs(NeonBackup) do
			if p and p.Parent then p.Material = Enum.Material.Neon end
		end
		if notify then notify("霓虹发光开启 · 关掉自动还原") end
	else
		if NeonBackup then
			for p, v in pairs(NeonBackup) do
				if p and p.Parent then p.Material = v.M; p.Color = v.C end
			end
			NeonBackup = nil
		end
		if notify then notify("已还原材质") end
	end
end
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
FollowTgl = makeToggle(PageMore, 182, "自动跟随 FOLLOW", "开启后弹出面板选要跟的人", false, function(v)
	State.Follow = v
	if v then openPlayerPicker("选择要跟随的玩家", function(pl)
		State.WatchTarget = pl
		if notify then notify("已锁定：" .. (pl.DisplayName or pl.Name)) end
	end) end
end)
FaceTgl   = makeToggle(PageMore, 230, "始终注视 FACING", "开启后弹出面板选要看的人", false, function(v)
	State.Face = v
	if v then openPlayerPicker("选择要注视的玩家", function(pl)
		State.WatchTarget = pl
		if notify then notify("已锁定：" .. (pl.DisplayName or pl.Name)) end
	end) end
end)
FeignBtn = new("TextButton", { Text = "装死躺平 FEIGN", Font = Enum.Font.GothamBold, TextSize = 11,
	TextColor3 = Mode().Accent, BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.9,
	BorderSizePixel = 0, AutoButtonColor = false,
	Size = UDim2.new(1, 0, 0, 36), Position = UDim2.new(0, 0, 0, 278), Parent = PageMore })
corner(FeignBtn, 10)
table.insert(MoreBtns, FeignBtn)
FeignBtn.MouseButton1Click:Connect(function()
	if HRP and HRP.Parent then
		HRP.CFrame = HRP.CFrame * CFrame.Angles(math.rad(90), 0, 0)
		if Humanoid then Humanoid.PlatformStand = true end
	end
end)
ClockSlider = makeSlider(PageMore, "昼夜 CLOCK", 322, 0, 24, math.floor(Lighting.ClockTime), " h", function(v)
	Lighting.ClockTime = v
end, false)
FovSlider = makeSlider(PageMore, "视野 FOV", 376, 30, 120, 70, " °", function(v)
	State.FovValue = v
	pcall(function() if v > 0 then Cam.FieldOfView = v end end)
	if v > 0 then Cam.FieldOfView = v end
end, false)
FX_LIST = { "OFF", "BLOOM", "CYBER", "NOIR" }
fxIndex = 1
FxBtn = new("TextButton", { Text = "画面特效：OFF", Font = Enum.Font.GothamBold, TextSize = 11,
	TextColor3 = Mode().Accent, BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.9,
	BorderSizePixel = 0, AutoButtonColor = false,
	Size = UDim2.new(1, 0, 0, 36), Position = UDim2.new(0, 0, 0, 430), Parent = PageMore })
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
			notify("当前角色不支持缩放（需 R15）", Color3.fromRGB(255, 176, 32))
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
	if HON_SHUTDOWN then return end
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

label({ Text = "开启后右上角弹出「隐身 STEALTH」小窗：点 × 或「开关隐身」即可关闭，窗随隐身一起收起。\n隐藏期间仅「加速」保持运行（启用引擎 + 加速小窗），其余功能全部暂停，关闭隐身即原样恢复。\n注：注入器若是独立原生窗口，脚本无法控制它，请用它自己的快捷键。",
	Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = Color3.fromRGB(132, 141, 163),
	Position = UDim2.new(0, 2, 0, 564), Size = UDim2.new(1, -4, 0, 56),
	TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top }, PageUtil)
WaypointLabel = label({ Text = "存档点：未设置", Font = Enum.Font.Gotham, TextSize = 10,
	TextColor3 = Color3.fromRGB(132, 141, 163), Size = UDim2.new(1, -4, 0, 20),
	Position = UDim2.new(0, 2, 0, 628), TextXAlignment = Enum.TextXAlignment.Left }, PageUtil)
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
		notify("保存失败：角色还没加载", Color3.fromRGB(255, 176, 32))
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
AutoJumpTgl = makeToggle(PageUtil, 252, "自动连跳 AUTO JUMP", "一直保持弹跳前进", false, function(v) State.AutoJump = v end)
CoordTgl = makeToggle(PageUtil, 300, "坐标显示 COORD", "自动开启 HUD 并在上面显示 XYZ", false, function(v)
	State.CoordHud = v
	if v then
		State.HUD = true
		if HudFrame then HudFrame.Visible = true end
		if HudTgl then HudTgl.Set(true, true) end
		if notify then notify("坐标显示已开启（已自动打开速度 HUD）") end
	end
end)
ZoomSlider = makeSlider(PageUtil, "镜头距离 ZOOM", 348, 1, 120, 20, " m", function(v)
	LP.CameraMaxZoomDistance = v
	LP.CameraMinZoomDistance = v
end, false)
utilBtn("全部关闭 RESET ALL", 402, function()
	askConfirm("关闭全部功能？", "会把当前开着的所有开关全部关掉：飞行 / 穿墙 / 无限跳 / 透视 / 黑洞 / 分身 / 拖尾 / 特效 等等。\n滑条数值保留，存档点不会被删除。", "确认全部关闭", function()
		for _, t in ipairs(ToggleRegistry) do pcall(function() t.Set(false, false) end) end
		if notify then notify("已关闭全部功能") end
	end)
end)
HiddenParts = {}
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
label({ Text = "M 切引擎 · F2 开关 · L 锁面板 · 飞行升降看右上角 UP/DOWN · , . 切页 · RightCtrl 显隐",
	Font = Enum.Font.Gotham, TextSize = 9, TextColor3 = Color3.fromRGB(105, 113, 134),
	Position = UDim2.new(0, 0, 1, -13), Size = UDim2.new(1, 0, 0, 12),
	TextXAlignment = Enum.TextXAlignment.Center,
	TextXAlignment = Enum.TextXAlignment.Center, TextWrapped = true }, Main)
HudFrame = new("Frame", { Size = UDim2.new(0, 172, 0, 40), Position = UDim2.new(0.5, -110, 0, 8),
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
-- v5.48：最小化——缩成只剩 FLY 标题条（UP/DOWN 按钮在右上角，不受影响），再点展开
FlyMinBtn = new("TextButton", { Text = "–", Font = Enum.Font.GothamBold, TextSize = 14,
	TextColor3 = Color3.fromRGB(150, 158, 180), BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	BackgroundTransparency = 0.9, BorderSizePixel = 0, AutoButtonColor = false,
	Position = UDim2.new(1, -68, 0, 7), Size = UDim2.new(0, 26, 0, 26), Parent = FlyBar })
corner(FlyMinBtn, 8)
FlyToggle = makeToggle(FlyWin, 44, "开关飞行", "WASD 前后左右 · 升降看右上角 UP/DOWN", false, function(v) setFly(v) end)
FlySlider = makeSlider(FlyWin, "飞行速度", 96, 10, 250, 60, " sp", function(v) State.FlySpeed = v end, false)
label({ Text = "UP / DOWN 键在右上角 · 主 UI 可关窗",
	Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = Color3.fromRGB(132, 141, 163),
	Position = UDim2.new(0, 16, 0, 150), Size = UDim2.new(1, -32, 0, 28),
	TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top }, FlyWin)
-- v5.48：最小化接线放在最后（子元素齐了才算「窗体」）——缩成标题条，UP/DOWN 照常在右上角
winMinSetup(FlyWin, FlyMinBtn, { FlyBar })
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
		-- v5.47：方向格整块拖（用户：「我要的是拖动它，然后就中间那个我碰到哪里就轻轻碰
		-- 向哪里……而不是把所有按键全部分散拖动」）——按住格子照常走；手指挪出 12px 容忍区
		-- 就停脚、改为拖动整个方向键（PadFrame 整体位移），单格再也别想被拽得满屏飞
		local cellDrag, cellStart, cellMouse = false, nil, nil
		b.InputBegan:Connect(function(i)
			if i.UserInputType ~= Enum.UserInputType.Touch and i.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
			if State.TouchLocked then return end
			cellDrag, cellStart, cellMouse = false, PadFrame.Position, i.Position
			press(true)
		end)
		UserInputService.InputChanged:Connect(function(i)
			if not cellMouse then return end
			if i.UserInputType ~= Enum.UserInputType.MouseMovement and i.UserInputType ~= Enum.UserInputType.Touch then return end
			local mx, my = i.Position.X - cellMouse.X, i.Position.Y - cellMouse.Y
			if not cellDrag and (math.abs(mx) > 12 or math.abs(my) > 12) then
				cellDrag = true
				press(false)   -- 转入拖动：先停脚，别一边走一边拖
			end
			if cellDrag then
				PadFrame.Position = UDim2.new(cellStart.X.Scale, cellStart.X.Offset + mx,
					cellStart.Y.Scale, cellStart.Y.Offset + my)
			end
		end)
		b.InputEnded:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
				cellMouse, cellDrag = nil, false
			end
		end)
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
	local centerWalk, centerUsed, centerKeys = false, false, nil
	-- 中心格当小摇杆（用户：「只要轻轻往右上角一摁就往右上角走……只需要轻微触碰某个方向
	-- 就往某个方向动，要不然中间不能按这样走路一卡一卡的」）：
	-- 触点相对格子中心的偏移量化成 8 向——偏移任一侧超过 30% 就算这个方向，
	-- 两个轴都过线就是斜向（右上 / 左上 / 右下 / 左下），斜向也能走
	local function padAxis(v)
		if v > 0.3 then return 1 elseif v < -0.3 then return -1 end
		return 0
	end
	local function centerDirAt(pos)
		-- 触点是屏幕绝对坐标；格子几何 = 56×56（Offset）× PadScale，位置取绝对坐标
		local ap, asz = padCenter.AbsolutePosition, padCenter.AbsoluteSize
		if not ap or not asz or asz.X < 1 or asz.Y < 1 then return 0, 0 end
		local dx = (pos.X - (ap.X + asz.X / 2)) / (asz.X / 2)
		local dy = -(pos.Y - (ap.Y + asz.Y / 2)) / (asz.Y / 2)  -- 屏幕 Y 向下，方向键 Y 向上
		return padAxis(dx), padAxis(dy)
	end
	local function centerSendKeys(on, dx, dy)
		if not PAD_USE_KEYS then return end
		-- PAD_USE_KEYS 模式下中心格也同步发真实按键（和方向键同一套键位表）
		if centerKeys then
			for _, k in ipairs(centerKeys) do pcall(function() VirtualInput:SendKeyEvent(false, k, false, game) end) end
			centerKeys = nil
		end
		if on then
			for _, c in ipairs(PAD_CELLS) do
				if c[4] and c[5] == dx and c[6] == dy then centerKeys = c[4]; break end
			end
			if centerKeys then
				for _, k in ipairs(centerKeys) do pcall(function() VirtualInput:SendKeyEvent(true, k, false, game) end) end
			end
		end
	end
	local function centerSetDir(pos)
		local dx, dy = centerDirAt(pos)
		if dx == 0 and dy == 0 then
			-- 正中心（死区）：不当方向键用，留给「长按 0.3 秒拖动整块」
			if centerWalk then
				centerWalk = false
				PadActive = false
				PadDir.x, PadDir.y = 0, 0
				TweenService:Create(padCenter, TWEEN_FAST, { BackgroundTransparency = 0.18 }):Play()
				centerSendKeys(false, 0, 0)
			end
			return
		end
		if not centerWalk or PadDir.x ~= dx or PadDir.y ~= dy then
			centerWalk = true
			centerUsed = true
			PadDir.x, PadDir.y = dx, dy
			PadActive = true
			TweenService:Create(padCenter, TWEEN_FAST, { BackgroundTransparency = 0.02 }):Play()
			centerSendKeys(true, dx, dy)
		end
	end
	local function centerStop()
		if centerWalk then
			centerWalk = false
			PadActive = false
			PadDir.x, PadDir.y = 0, 0
			TweenService:Create(padCenter, TWEEN_FAST, { BackgroundTransparency = 0.18 }):Play()
		end
		centerSendKeys(false, 0, 0)
		centerUsed = false
	end
	padCenter.MouseButton1Down:Connect(function()
		centerUsed = false
		if State.TouchLocked then return end
		holdStart = tick()
	end)
	padCenter.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
			centerUsed = false
			if not State.TouchLocked then holdStart = tick() end
			-- 落指即定向：轻碰中心格边缘就往那个方向走（走动和长按拖动互不冲突——
			-- 这次按聘用过走路就永远不再触发拖动）
			centerSetDir(i.Position)
		end
	end)
	UserInputService.InputChanged:Connect(function(i)
		if i.UserInputType ~= Enum.UserInputType.MouseMovement and i.UserInputType ~= Enum.UserInputType.Touch then return end
		if centerWalk then
			-- 手指在中心格里划：实时改方向（小摇杆手感），且不启动拖动
			centerSetDir(i.Position)
			return
		end
		if holdStart and not centerUsed and (tick() - holdStart > 0.3) then
			if not padDrag then padDrag, padStart, padMouse = true, PadFrame.Position, i.Position end
			local d = i.Position - padMouse
			PadFrame.Position = UDim2.new(padStart.X.Scale, padStart.X.Offset + d.X,
				padStart.Y.Scale, padStart.Y.Offset + d.Y)
		end
	end)
	UserInputService.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
			holdStart, padDrag = nil, false
			centerStop()
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
	if HON_SHUTDOWN then return end
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
		if notify then notify("已固定：" .. t.Name .. "（本服务器自动生效）") end
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
			if notify then notify("已恢复本服务器的 UI 布局（" .. hit .. " 项）") end
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
	_pr("[HON] 切换到第 " .. tostring(i) .. " 页")
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
	_pr("[HON] 切换到引擎 " .. tostring(i) .. " " .. tostring(Modes[i] and Modes[i].Name))
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
	-- 边框是「主题色」时跟着引擎主题色走（彩虹/红/蓝是固定色，不跟）
	if BorderOn and BorderMode == 4 and MainStroke then MainStroke.Color = m.Accent end
	for _, b in ipairs(MoreBtns) do TweenService:Create(b, TWEEN_SOFT, { TextColor3 = m.Accent }):Play() end
	for _, b in ipairs(UtilBtns) do TweenService:Create(b, TWEEN_SOFT, { TextColor3 = m.Accent }):Play() end
	for _, b in ipairs(UiBtns) do TweenService:Create(b, TWEEN_SOFT, { TextColor3 = m.Accent }):Play() end
	InertiaToggle.Dim(m.Id ~= "V")
	SlideToggle.Dim(m.Id ~= "CF")
	if notify then notify("引擎已切换：" .. m.Name) end
	TeleportToggle.Dim(m.Id ~= "CF")
	cur, CFAccum = 0, 0
	VVEL = Vector3.zero
	speedWinRefresh()   -- 加速小窗跟着切：模式高亮 + 速度范围 + 主题色
end
-- ---------- 神威 · 空间扭曲 ----------
-- 还原「空间被拧成漩涡」：把一整片空间网格（同心环 + 径向线）按等角(对数)螺旋
-- r = a·e^(b·theta) 扭曲 —— 径向线弯成螺旋、同心环按「内快外慢」差异旋转产生剪切，
-- 越靠中心卷得越紧，最后被中心的黑洞奇点吞噬。
-- 螺旋段不是散点：每条臂由一串首尾相接的短线段沿切线方向拼成，因此是连续曲线。
KAMUI_A, KAMUI_B = 5, 0.30
KamuiRoot, KamuiCore, KamuiGlow, KamuiDisc = nil, nil, nil, nil
KamuiSegs, KamuiRings = {}, {}
KamuiOn, KamuiT, KamuiDur, KamuiDir = false, 0, 3.0, 1
-- v5.47：面板动画世代锁——开关动画/tspawn 协程各持一个 gen，过期协程直接退出，
-- 快速反复开关时两个协程不会再交错写 Main 的 Size/Rotation/Visible（UI 收缩变宽根因之二）
PanelAnimGen = 0

KAMUI_RMAX, KAMUI_RMIN, KAMUI_BASE = 215, 17, 6
KAMUI_ARMS, KAMUI_SEGN = 14, 8
KamuiDots = {}
-- 神威「撕裂碎片」：开/关面板时把面板切成网格碎片，被黑洞奇点吸入/喷出
KamuiShards, KamuiShatter = {}, false
function hideShards()
	for _, d in ipairs(KamuiShards) do
		if d.F then d.F.Visible = false end
	end
end
function shatterPanel()
	if not Main or not Main.Parent then return end
	hideShards()
	local ax, ay = Main.AbsolutePosition.X, Main.AbsolutePosition.Y
	local aw, ah = Main.AbsoluteSize.X, Main.AbsoluteSize.Y
	if aw < 8 or ah < 8 then return end
	local gx, gy = Gui.AbsoluteSize.X * 0.5, Gui.AbsoluteSize.Y * 0.5
	local cols, rows = 6, 4
	local bw, bh = aw / cols, ah / rows
	local bg = Main.BackgroundColor3
	local i = 0
	for r = 0, rows - 1 do
		for c = 0, cols - 1 do
			i = i + 1
			local d = KamuiShards[i]
			if not d or not d.F or not d.F.Parent then
				local f = new("Frame", { Name = "HonShard" .. i, BackgroundColor3 = bg,
					BackgroundTransparency = 0.06, BorderSizePixel = 0, Visible = false, Parent = Gui })
				local s = new("UIStroke", { Color = Color3.fromRGB(255, 255, 255), Transparency = 0.15,
					Thickness = 1, Parent = f })
				d = { F = f, S = s }
				KamuiShards[i] = d
			end
			d.F.BackgroundColor3 = bg
			d.OW, d.OH = bw, bh
			d.OX, d.OY = ax + (c + 0.5) * bw, ay + (r + 0.5) * bh
			d.CX, d.CY = gx, gy
			d.R0 = (math.random() - 0.5) * 50
			d.F.Size = UDim2.new(0, bw, 0, bh)
			d.F.Position = UDim2.new(0, d.OX - bw * 0.5, 0, d.OY - bh * 0.5)
			d.F.Rotation = 0
			d.F.Visible = true
		end
	end
	for k = i + 1, #KamuiShards do
		local d = KamuiShards[k]
		if d and d.F then d.F.Visible = false end
	end
end
function buildKamui()
	if KamuiRoot then return end
	KamuiRoot = new("Frame", { Name = "HonKamui", Size = UDim2.new(0, 480, 0, 480),
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0),
		BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false, Parent = Gui })
	-- 奇点辉光
	KamuiGlow = new("Frame", { Size = UDim2.new(0, 150, 0, 150), AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0), BackgroundColor3 = Color3.fromRGB(150, 200, 255),
		BackgroundTransparency = 0.8, BorderSizePixel = 0, Parent = KamuiRoot })
	corner(KamuiGlow, 75)
	-- 吸积盘（白亮细环）
	KamuiDisc = new("Frame", { Size = UDim2.new(0, 78, 0, 78), AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0), BackgroundTransparency = 1,
		BorderSizePixel = 0, Parent = KamuiRoot })
	corner(KamuiDisc, 39)
	new("UIStroke", { Color = Color3.fromRGB(238, 246, 255), Thickness = 2.5, Transparency = 0.1, Parent = KamuiDisc })
	-- 黑洞奇点
	KamuiCore = new("Frame", { Size = UDim2.new(0, 34, 0, 34), AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0), BackgroundColor3 = Color3.fromRGB(1, 1, 4),
		BackgroundTransparency = 0, BorderSizePixel = 0, Parent = KamuiRoot })
	corner(KamuiCore, 17)
	-- 7 圈空间环（对应预览 i=5..11）
	for i = 5, 11 do
		local d = (i / 11) * KAMUI_RMAX * 2
		local r = new("Frame", { Size = UDim2.new(0, d, 0, d), AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0), BackgroundTransparency = 1,
			BorderSizePixel = 0, Parent = KamuiRoot })
		corner(r, d / 2)
		local st = new("UIStroke", { Color = Color3.fromRGB(165, 205, 255), Thickness = 1.3, Transparency = 1, Parent = r })
		table.insert(KamuiRings, { Ring = r, Stroke = st, Idx = i, Base = d })
	end
	-- 14 条螺旋线，每条 12 段（段首尾相接连成连续曲线）
	for a = 1, KAMUI_ARMS do
		for j = 0, KAMUI_SEGN - 1 do
			local seg = new("Frame", { Size = UDim2.new(0, 8, 0, 1.8),
				AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Color3.fromRGB(210, 230, 255),
				BackgroundTransparency = 1, BorderSizePixel = 0, Parent = KamuiRoot })
			corner(seg, 1)
			table.insert(KamuiSegs, { Seg = seg, Arm = a, Idx = j })
		end
	end
	-- 16 个被卷入的碎屑粒子
	for k = 0, 15 do
		local dt2 = new("Frame", { Size = UDim2.new(0, 6, 0, 6), AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0), BackgroundColor3 = Color3.fromRGB(240, 248, 255),
			BackgroundTransparency = 1, BorderSizePixel = 0, Parent = KamuiRoot })
		corner(dt2, 3)
		table.insert(KamuiDots, { Dot = dt2, Seed = k / 16 })
	end
end

-- 立即结束正在播放的神威动画：切换动画样式时调用，否则旧协程 1.6s 后还会
-- hideShards + Main.Visible = true 把新样式的结果搅乱（「动画样式不能关闭」的残余路径）
function stopKamui()
	KamuiOn = false
	KamuiShatter = false
	if KamuiRoot then KamuiRoot.Visible = false end
	pcall(hideShards)
end

function playKamui(mode, dur)
	buildKamui()
	KamuiDir = (mode == "out") and -1 or 1
	KamuiDur = dur or 3.0
	KamuiT = 0
	KamuiOn = true
	KamuiRoot.Visible = true
end

pcall(function() RunService:UnbindFromRenderStep("HonKamui") end)
RunService:BindToRenderStep("HonKamui", 9999, function(dt)
	if HON_SHUTDOWN then return end
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
	-- ===== 神威：参数与预览逐项对齐 =====
	local t = raw
	local sc = out and (1 - math.pow(1 - t, 3)) or math.pow(1 - t, 2.2)
	local wind = 3.6 + t * 4.0
	local ph = KamuiT * 1.6
	local al = out and ((t < 0.08) and (t / 0.08) or ((t > 0.90) and (1 - (t - 0.90) / 0.10) or 1)) or (1 - t * 0.5)
	local R0, R1, BS = KAMUI_RMIN, KAMUI_RMAX, KAMUI_BASE
	local ARMS, SEGN = KAMUI_ARMS, KAMUI_SEGN

	-- 14 条螺旋卷入线：按 r 采样，段首尾相接成连续曲线
	-- 颜色只在引擎主题变化时整表刷新（此前每帧每段都写色，1300 次属性写入/帧，手机必卡）
	if acc ~= KamuiLastAcc then
		KamuiLastAcc = acc
		for _, sd in ipairs(KamuiSegs) do sd.Seg.BackgroundColor3 = acc end
	end
	for a = 1, ARMS do
		local a0 = (a - 1) * (math.pi * 2 / ARMS) + ph
		local px, py = 0, 0
		for j = 0, SEGN do
			local f = j / SEGN
			local r = R0 + (R1 - R0) * f
			local th = a0 + wind * math.log(r / BS)
			local x = math.cos(th) * r * sc
			local y = math.sin(th) * r * sc
			if j > 0 then
				local sd = KamuiSegs[(a - 1) * SEGN + j]
				if sd then
					local mx, my = (px + x) / 2, (py + y) / 2
					local dx, dy = x - px, y - py
					local len = math.sqrt(dx * dx + dy * dy) * 1.35 + 1
					sd.Seg.Position = UDim2.new(0.5, mx, 0.5, my)
					sd.Seg.Size = UDim2.new(0, len, 0, 1.9)
					sd.Seg.Rotation = math.deg(math.atan2(dy, dx))
					sd.Seg.BackgroundTransparency = 1 - al * 0.62
					sd.Seg.BackgroundColor3 = acc
				end
			end
			px, py = x, y
		end
	end

	-- 16 个被卷入的碎屑：沿螺旋向内流动（预览里这一层最关键）
	for _, d in ipairs(KamuiDots) do
		local f2 = (d.Seed + KamuiT * 0.35) % 1
		local r2 = R1 - (R1 - 15) * f2
		local th2 = d.Seed * math.pi * 2 + ph + wind * math.log(r2 / BS)
		local x = math.cos(th2) * r2 * sc
		local y = math.sin(th2) * r2 * sc
		local sz = (1.6 + 3.4 * (1 - f2)) * sc
		d.Dot.Position = UDim2.new(0.5, x, 0.5, y)
		d.Dot.Size = UDim2.new(0, sz, 0, sz)
		d.Dot.BackgroundTransparency = 1 - al * (1 - f2 * 0.6) * 0.9
	end

	-- 7 圈空间环（对应预览 i=5..11，差异旋转）
	for _, q in ipairs(KamuiRings) do
		local rr = (q.Idx / 11) * R1 * sc
		local dd = rr * 2
		q.Ring.Size = UDim2.new(0, dd, 0, dd)
		q.Ring.Rotation = math.deg(wind * math.log(math.max(rr / BS, 1.2)) + ph * (1 - q.Idx / 12 * 0.6))
		q.Stroke.Transparency = 1 - al * 0.34 * (1 - q.Idx / 14)
		q.Stroke.Color = acc
	end

	-- 黑洞奇点：放出时由大收缩为点，吸入时膨胀吞噬
	local coreR = (out and (58 - 42 * t) or (20 + 120 * t)) * 0.5
	KamuiCore.Size = UDim2.new(0, coreR * 2, 0, coreR * 2)
	KamuiCore.BackgroundTransparency = 1 - al
	KamuiDisc.Size = UDim2.new(0, coreR * 2.44, 0, coreR * 2.44)
	KamuiGlow.Size = UDim2.new(0, coreR * 3, 0, coreR * 3)
	KamuiGlow.BackgroundTransparency = 1 - al * 0.22
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
	-- v5.47：世代锁——本次开场动画持 gen，后续任何开关动画都会 +1 把过期协程作废
	PanelAnimGen = PanelAnimGen + 1
	local myGen = PanelAnimGen
	-- 用户关了启动动画：面板直接归位出现，不播神威漩涡（旧版只有样式切换、没有总开关，
	-- 「不要动画」藏在第 4 个样式里，用户找不到就是「启动动画没法关」）
	if not AnimOn then
		Main.Visible = true
		pcall(function()
			if MainScale then MainScale.Scale = PrefPanelScale or 1 end
			Main.Rotation = 0
			Main.Size = UDim2.new(0, PANEL_W, 0, PANEL_H)
			Main.BackgroundTransparency = 0.05
		end)
		return
	end
	local st = AnimStyleIdx or 1
	if st ~= 1 then stopKamui() end
	if st == 4 then
		Main.Visible = true
		pcall(function()
			if MainScale then MainScale.Scale = PrefPanelScale or 1 end
			Main.Size = UDim2.new(0, PANEL_W, 0, PANEL_H)
			Main.BackgroundTransparency = 0.05
		end)
		return
	end
	if st == 2 then
		Main.Visible = true
		pcall(function()
			Main.BackgroundTransparency = 1
			if MainScale then MainScale.Scale = PrefPanelScale or 1 end
			TweenService:Create(Main, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ BackgroundTransparency = 0.05 }):Play()
		end)
		return
	end
	if st == 3 then
		Main.Visible = true
		pcall(function()
			if MainScale then MainScale.Scale = 0.4 end
			TweenService:Create(MainScale, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
				{ Scale = PrefPanelScale or 1 }):Play()
		end)
		return
	end
	Main.Visible = false
	pcall(playKamui, "in")
	pcall(shatterPanel)
	KamuiShatter = true
	tspawn(function()
		twait(1.6)
		if myGen ~= PanelAnimGen then return end   -- 期间又开关过：本次结果已作废
		KamuiShatter = false
		pcall(hideShards)
		Main.Visible = true
		pcall(function()
			if MainScale then MainScale.Scale = PrefPanelScale or 1 end
			Main.Rotation = 0
			Main.Size = UDim2.new(0, PANEL_W, 0, PANEL_H)
			Main.BackgroundTransparency = 1
			TweenService:Create(Main, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
				{ Size = UDim2.new(0, PANEL_W, 0, PANEL_H), BackgroundTransparency = 0.05 }):Play()
		end)
	end)
end

function closeAllFeatures()
	for _, t in ipairs(ToggleRegistry) do
		if t._last and not t._keep then pcall(function() t.Set(false, false) end) end
	end
	if notify then notify("已关闭全部功能") end
end

HON_SHUTDOWN = false
function unloadScript()
	if HON_SHUTDOWN then return end
	HON_SHUTDOWN = true
	pcall(closeAllFeatures)
	pcall(function() if type(clearWings) == "function" then clearWings() end end)
	pcall(function() if type(toyStopAll) == "function" then toyStopAll() end end)
	pcall(function() if type(setCloneArmy) == "function" then setCloneArmy(false) end end)
	pcall(function() if type(setBlackHole) == "function" then setBlackHole(false) end end)
	pcall(function() if type(setTrail) == "function" then setTrail(false) end end)
	pcall(function() if type(setOrbitFx) == "function" then setOrbitFx(false) end end)
	pcall(function() if type(clearStyleFx) == "function" then clearStyleFx() end end)
	pcall(function() if type(setCar) == "function" then setCar(false) end end)
	pcall(function() if type(setHeroFly) == "function" then setHeroFly(false) end end)
	pcall(function() if KamuiRoot then KamuiRoot.Visible = false end end)
	pcall(function() Workspace.Gravity = 196.2 end)
	-- 画质特效残留清理：ColorCorrectionEffect 挂在 Lighting 里，不销毁会赖到下一个脚本
	-- （下次启动画面黑白/过亮，用户只能开画质覆盖——「不开画质就出 bug」的根因之一）
	pcall(function()
		if GfxFx then GfxFx:Destroy(); GfxFx = nil end
		setGfxParticles(false); setGfxDecal(false)
		setGfxShadows(false); setGfxFog(false)
	end)
	-- 身上方块还原：脚本内置自动清过角色附加物，卸载时原样还回去不留残
	pcall(function() if type(hideBodyBlocks) == "function" then hideBodyBlocks(false) end end)
	for _, nm in ipairs({ "HonFunLoop", "HonFlyJump", "HonFov", "HonKamui",
		"HonUILayout", "HonPadMove", "HonFakeSync", "HonDance", "HonBorder", "HonStyleFx" }) do
		pcall(function() RunService:UnbindFromRenderStep(nm) end)
	end
	-- WindUI 界面也要收：用户可能在 WindUI 框架里点的关闭
	pcall(function() if windDestroy then windDestroy() end end)
	pcall(function() if Gui then Gui.Enabled = false end end)
	pcall(function() if Gui then Gui:Destroy() end end)
	_pr("[HON SPEED HUB] 已彻底关闭")
end

function playCloseAnim(after)
	-- v5.47：世代锁——同 playOpenAnim，过期协程作废，快速反复开关不再交错写面板状态
	PanelAnimGen = PanelAnimGen + 1
	local myGen = PanelAnimGen
	-- 同启动动画：关了就秒收，不播收回动画
	if not CloseAnimOn then
		Main.Visible = false
		if after then pcall(after) end
		return
	end
	local st = CloseAnimIdx or 1
	if st ~= 1 then stopKamui() end
	if st == 4 then
		Main.Visible = false
		if after then pcall(after) end
		return
	end
	if st == 2 then
		pcall(function()
			TweenService:Create(Main, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{ BackgroundTransparency = 1 }):Play()
		end)
		tspawn(function()
			twait(0.32)
			Main.Visible = false
			Main.BackgroundTransparency = 0.05
			if after then pcall(after) end
		end)
		return
	end
	if st == 3 then
		pcall(function()
			if MainScale then
				TweenService:Create(MainScale, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
					{ Scale = 0.4 }):Play()
			end
		end)
		tspawn(function()
			twait(0.32)
			Main.Visible = false
			if MainScale then MainScale.Scale = PrefPanelScale or 1 end
			if after then pcall(after) end
		end)
		return
	end
	-- v5.47：删除动画改成与开启完全对称的碎片扭曲——面板碎成 24 片，被黑洞吸回去再消失
	-- （用户：「它是直接把面板就哐的一下横过来，然后消失了，我需要的是让它和开启一样
	-- 变成碎片扭曲空间，然后再收回去」）——旧版那套 Rotation=10 + 宽×1.16 高×0.8 的
	-- 横倒 tween 整个删掉：它既是「哐的一下横过来」的观感来源，又把 Main.Size 永久污染
	-- （当时 OrigMainSize 没赋值，还原全是空跑），无动画开启时污染直接暴露成 UI 缩短变宽
	pcall(playKamui, "out", 2.2)
	pcall(shatterPanel)
	KamuiShatter = true
	Main.Visible = false
	if after then pcall(after) end
	tspawn(function()
		twait(2.0)
		if myGen ~= PanelAnimGen then return end   -- 期间又打开过：本次收尾作废
		KamuiShatter = false
		pcall(hideShards)
		-- 硬复位：尺寸/旋转/透明度全部归位，绝不留污染值
		pcall(function()
			Main.Rotation = 0
			Main.Size = UDim2.new(0, PANEL_W, 0, PANEL_H)
			Main.BackgroundTransparency = 0.05
			if MainScale then MainScale.Scale = PrefPanelScale or 1 end
		end)
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
			WinPos.FlyWin = FlyWin.Position
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

-- v5.57：键盘按键状态集（兜底 IsKeyDown）——飞行水平移动此前「只能上下、不能前后」，
-- 根因是 anyDown 只靠 UserInputService:IsKeyDown，飞行/PlatformStand 等状态下个别执行器
-- IsKeyDown 不可靠地返回 false，导致 WASD 判定全失败、水平方向恒为 0；改成用 InputBegan/
-- InputEnded 维护一份可靠的「按下集合」，与 IsKeyDown 取并集，所有依赖 anyDown 的移动都变稳
local KeysDown = {}
pcall(function()
	UserInputService.InputBegan:Connect(function(i, processed)
		if i and i.UserInputType == Enum.UserInputType.Keyboard then KeysDown[i.KeyCode] = true end
	end)
	UserInputService.InputEnded:Connect(function(i, processed)
		if i and i.UserInputType == Enum.UserInputType.Keyboard then KeysDown[i.KeyCode] = nil end
	end)
end)
function anyDown(list)
	for _, k in ipairs(list) do if KeysDown[k] or UserInputService:IsKeyDown(k) then return true end end
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
	if HON_SHUTDOWN then return end
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
-- v5.58：相机穿墙（CAMERA NOCLIP）——镜头不被墙/地形遮挡，可看穿墙体。
-- 做法：每帧在相机模块把镜头摆好之后（RenderPriority.Camera 之后跑），把相机沿其当前
-- 朝向推回「当前缩放距离」，但全程不做任何遮挡射线检测，于是相机停在墙体外侧、能看穿墙；
-- 鼠标转向由相机模块照常处理，本步只改「距离」不改「朝向」，所以转向照常、只是不再被拉近。
-- 关闭时解绑即可，不改动相机类型/状态，下一帧由相机模块正常接管。
local CamNoclipConn = nil
function setCamNoclip(on)
	State.CamNoclip = on
	if CamNoclipConn then pcall(function() CamNoclipConn:Disconnect() end) end
	CamNoclipConn = nil
	if not on then return end
	CamNoclipConn = RunService:BindToRenderStep("HonCamClip",
		(Enum.RenderPriority.Camera.Value or 200) + 1, function()
		if HON_SHUTDOWN or not Cam then return end
		if not (HRP and HRP.Parent) then return end
		if not (LP and LP.Parent) then return end
		local head = HRP.Position
		local cur = Cam.CFrame.Position - head
		local dist = cur.Magnitude
		if dist < 0.1 then return end
		local look = Cam.CFrame.LookVector
		Cam.CFrame = CFrame.new(head - look * dist, head)
	end)
end
pcall(function() RunService:UnbindFromRenderStep("HonPadMove") end)
RunService:BindToRenderStep("HonPadMove", 10000, function()
	if HON_SHUTDOWN then return end
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
	-- v5.48：位移不走 LinearVelocity 约束，改成每帧直接写 HRP.AssemblyLinearVelocity
	-- 约束类是新 API，个别执行器建了不工作，飞行会直接瘫（用户：「飞行用不了」）
	-- 只留 AlignOrientation 保持悬浮时 upright + 朝向跟随镜头水平朝向（pcall 包着，
	-- 老执行器没有这个类型就退化：照样飞，只是不强制朝向）
	FlyOrient = nil
	pcall(function()
		local o = Instance.new("AlignOrientation")
		o.Attachment0 = FlyAtt
		o.Mode = Enum.OrientationAlignmentMode.OneAttachment
		o.RigidityEnabled = true
		o.Parent = HRP
		FlyOrient = o
	end)
	if not (FlyOrient and FlyOrient.Parent) then FlyOrient = nil end
end
function destroyFlyParts()
	if FlyAtt then pcall(function() FlyAtt:Destroy() end) end
	if FlyOrient then pcall(function() FlyOrient:Destroy() end) end
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
	if on and WinPos.FlyWin then FlyWin.Position = WinPos.FlyWin end
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
		-- v5.47：文字牌无条件最顶渲染——厚墙 / 远距都不许挡
		-- （用户：「我需要它不管在哪里，不管有什么阻挡都能透视到」）
		if e.BB and e.BB.Parent then e.BB.AlwaysOnTop = true end
	end
end

function refreshEspHpStyle()
	for _, e in pairs(EspItems) do
		if e and (e.Cat == "Player" or e.Cat == "NPC") then
			local show = State.EspHpBarBg
			if e.BarBg then e.BarBg.Visible = show end
			if e.BarFill then e.BarFill.Visible = show end
		end
	end
end
-- v5.47：ESP 字体放大 + 启动记忆（用户：「增加一个透视字体放大，因为字体太小了。
-- 就是我设置到那个字体，下次启动脚本的时候还是在那个字体的位置，就那个大小」）——
-- 竖排三件套按 EspFontScale 整体等比缩放（盒子 / 字 / 血条 / 间距全按比例走）
EspFontScale = 1.0
function espApplyFont()
	for _, e in pairs(EspItems) do
		if e and e.BB and e.BB.Parent then
			local s = EspFontScale
			e.BB.Size = UDim2.new(0, math.floor(200 * s + 0.5), 0, math.floor(80 * s + 0.5))
			e.BB.StudsOffset = Vector3.new(0, 4 * s, 0)
			if e.NameLbl then
				e.NameLbl.Size = UDim2.new(1, 0, 0, math.floor(22 * s + 0.5))
				e.NameLbl.Position = UDim2.new(0, 0, 0, math.floor(2 * s + 0.5))
				e.NameLbl.TextSize = math.max(6, math.floor(16 * s + 0.5))
			end
			local bw = math.floor(150 * s + 0.5)
			if e.BarBg then
				e.BarBg.Size = UDim2.new(0, bw, 0, math.floor(12 * s + 0.5))
				e.BarBg.Position = UDim2.new(0.5, -bw / 2, 0, math.floor(30 * s + 0.5))
			end
			if e.HpTxt then
				e.HpTxt.Size = UDim2.new(0, bw, 0, math.floor(14 * s + 0.5))
				e.HpTxt.Position = UDim2.new(0.5, -bw / 2, 0, math.floor(29 * s + 0.5))
				e.HpTxt.TextSize = math.max(6, math.floor(10 * s + 0.5))
			end
			if e.DistLbl then
				e.DistLbl.Size = UDim2.new(1, 0, 0, math.floor(20 * s + 0.5))
				e.DistLbl.Position = UDim2.new(0, 0, 0, math.floor((e.Cat == "Interact" and 32 or 54) * s + 0.5))
				e.DistLbl.TextSize = math.max(6, math.floor(14 * s + 0.5))
			end
		end
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
	hl.Parent = EspFolder
	local bb = Instance.new("BillboardGui")
	bb.Name = "HonEspTag"
	bb.Adornee = adornee
	-- v5.44：竖排三件套（用户：「名字摆最上面，血条摆中间，距离摆最下面，字体太小了」）——
	-- 旧版是 13px 单行「名字 距离 HP」挤一行，远处根本看不清
	-- v5.47：整套按 EspFontScale 等比缩放（用户：「增加一个透视字体放大」）
	local s = EspFontScale
	bb.Size = UDim2.new(0, math.floor(200 * s + 0.5), 0, math.floor(80 * s + 0.5))
	bb.StudsOffset = Vector3.new(0, 4 * s, 0)
	-- v5.47：无条件最顶 + MaxDistance 拉到 100000——厚墙远距都不许丢标签
	-- （用户：「可能是墙壁特别厚，然后又特别远的地方它透视不到……不管有什么阻挡都能透视到」）
	bb.AlwaysOnTop = true
	bb.MaxDistance = 100000
	bb.Parent = EspFolder
	-- ① 名字（最上面，16px）
	local nm = Instance.new("TextLabel")
	nm.Name = "HonEspName"
	nm.Size = UDim2.new(1, 0, 0, math.floor(22 * s + 0.5))
	nm.Position = UDim2.new(0, 0, 0, math.floor(2 * s + 0.5))
	nm.BackgroundTransparency = 1
	nm.Font = Enum.Font.GothamBold
	nm.TextSize = math.max(6, math.floor(16 * s + 0.5))
	nm.TextColor3 = ESP_NAME_COLOR
	nm.TextStrokeTransparency = 0.4
	nm.Text = esc(name or cat)
	nm.Parent = bb
	-- ② 血条（中间）：深色底槽 + 按血量比例的填充 + 数字压在条上
	local barW = math.floor(150 * s + 0.5)
	local barBg = Instance.new("Frame")
	barBg.Name = "HonEspBarBg"
	barBg.Size = UDim2.new(0, barW, 0, math.floor(12 * s + 0.5))
	barBg.Position = UDim2.new(0.5, -barW / 2, 0, math.floor(30 * s + 0.5))
	barBg.BackgroundColor3 = Color3.fromRGB(10, 12, 18)
	barBg.BackgroundTransparency = 0.2
	barBg.BorderSizePixel = 0
	barBg.Parent = bb
	corner(barBg, 6)
	local barFill = Instance.new("Frame")
	barFill.Name = "HonEspBarFill"
	barFill.Size = UDim2.new(1, 0, 1, 0)
	barFill.BackgroundColor3 = ESP_HP_FULL
	barFill.BorderSizePixel = 0
	barFill.Parent = barBg
	corner(barFill, 6)

	-- v5.52：血条样式切换——关掉背景时只留纯血量数字（不画底槽/填充）
	if not State.EspHpBarBg then
		barBg.Visible = false
		barFill.Visible = false
	end
	local hpTxt = Instance.new("TextLabel")
	hpTxt.Name = "HonEspHp"
	hpTxt.Size = UDim2.new(0, barW, 0, math.floor(14 * s + 0.5))
	hpTxt.Position = UDim2.new(0.5, -barW / 2, 0, math.floor(29 * s + 0.5))
	hpTxt.BackgroundTransparency = 1
	hpTxt.Font = Enum.Font.GothamBold
	hpTxt.TextSize = math.max(6, math.floor(10 * s + 0.5))
	hpTxt.TextColor3 = Color3.fromRGB(240, 244, 252)
	hpTxt.TextStrokeTransparency = 0.3
	hpTxt.Text = ""
	hpTxt.Parent = bb
	-- ③ 距离（最下面，14px）
	local ds = Instance.new("TextLabel")
	ds.Name = "HonEspDist"
	ds.Size = UDim2.new(1, 0, 0, math.floor(20 * s + 0.5))
	ds.Position = UDim2.new(0, 0, 0, math.floor(54 * s + 0.5))
	ds.BackgroundTransparency = 1
	ds.Font = Enum.Font.GothamBold
	ds.TextSize = math.max(6, math.floor(14 * s + 0.5))
	ds.TextColor3 = ESP_DIST_COLOR
	ds.TextStrokeTransparency = 0.4
	ds.Text = ""
	ds.Parent = bb
	-- 交互物没有血量：血条整组藏起来，距离上移到名字下方，不留空档
	if cat == "Interact" then
		barBg.Visible = false
		barFill.Visible = false
		hpTxt.Visible = false
		ds.Position = UDim2.new(0, 0, 0, math.floor(32 * s + 0.5))
	end
	EspItems[target] = { Cat = cat, HL = hl, BB = bb, NameLbl = nm, BarBg = barBg,
		BarFill = barFill, HpTxt = hpTxt, DistLbl = ds, BarW = barW, Name = esc(name or cat) }
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
				-- 距离（最下面一栏）
				if e.DistLbl then e.DistLbl.Text = tostring(dist) .. " m" end
				local hum = anchor:FindFirstChildOfClass("Humanoid")
				if (e.Cat == "Player" or e.Cat == "NPC") and hum then
					local maxHp = hum.MaxHealth > 0 and hum.MaxHealth or 100
					local ratio = math.clamp(hum.Health / maxHp, 0, 1)
					local hc = hpColor(ratio)
					-- 血条：填充按比例收，数字跟着血量变色
					if e.BarFill then e.BarFill.Size = UDim2.new(ratio, 0, 1, 0); e.BarFill.BackgroundColor3 = hc end
					if e.HpTxt then
						e.HpTxt.Text = math.floor(hum.Health) .. " / " .. math.floor(maxHp)
						e.HpTxt.TextColor3 = hc
					end
					if e.HL and e.HL.Parent then
						e.HL.OutlineColor = hc
						e.HL.FillColor = hc
					end
				elseif e.BarBg then
					-- 理论上交互物在建图时就没血条；这是防御分支（角色掉了 Humanoid 之类）
					e.BarBg.Visible = false
					if e.BarFill then e.BarFill.Visible = false end
					if e.HpTxt then e.HpTxt.Visible = false end
				end
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
	-- 身上方块内置自动清除（v5.45）：启动 / 重生绑定角色就清一遍；
	-- 配件是异步加载的，CharacterAppearanceLoaded 也会再走 bindCharacter，
	-- 加上 Stepped 维持循环持续压回，三重保证不露方块
	pcall(hideBodyBlocks, true)
	cur, CFAccum = 0, 0
	-- v5.48：重生后锁定高度重置到新角色的当前 Y——不然 FlyHoldY 还留着旧高度，
	-- 弹簧速度会把新角色往重生点上方/下方的旧高度拽
	if State.Fly then
		-- 先销毁旧角色身上的附件：buildFlyParts 有「附件还活着就跳过」的早退，
		-- 不先销毁的话新角色拿不到 FlyAtt/FlyOrient（旧的还挂在已换掉的角色上）
		destroyFlyParts()
		buildFlyParts()
		-- 新角色的人形默认 PlatformStand=false，不重断言的话重生后角色会站起来 /
		-- 受重力，飞行态等于断了一拍（velocity 照写，但人形状态不对）
		if Humanoid and Humanoid.Parent then Humanoid.PlatformStand = true end
		FlyHoldY = (HRP and HRP.Parent) and HRP.Position.Y or nil
	end
	-- 画质/夜视类状态重生后自动重放（Lighting 是全局的不受影响，粒子/贴图类要重扫一遍）
	pcall(function()
		if State.GfxShadow then setGfxShadows(true) end
		if State.GfxFog then setGfxFog(true) end
		if State.GfxParticle then setGfxParticles(true) end
		if State.GfxDecal then setGfxDecal(true) end
		if State.GfxNight then setGfxNight(true) end
		if State.GfxSuperNight then setGfxSuperNight(true) end
		if State.GfxNoFog then setGfxNoFog(true) end
	end)
	-- 玩具重生后自动重挂（火花/火焰/烟雾挂在角色部件上，换角色后要重新挂）
	pcall(function() if type(toyReapplyAll) == "function" then toyReapplyAll() end end)
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
-- ===== 游戏内「放技能必须定身」检测（用户：哥斯拉 VS 王者基多拉类技能，放着技能角色被游戏钉住，=====
-- 但加速还推着角色走，一放着技能就乱窜，一眼脚本）=====
-- 游戏定身三件套：PlatformStand / HumanoidRootPart 锚定 /（W 引擎独有）WalkSpeed 被写 0。
-- 检测到就全部熄火钉在原地，角色绝不在技能期间移动。
-- 注意 V/CF 引擎自己就把 WalkSpeed 写 0，所以 WalkSpeed=0 只对 W 引擎当定身信号；
-- 飞行时 PlatformStand 是脚本自己开的，但飞行分支在上面提前 return，走不到这里。
function skillRooted()
	if not Humanoid or not Humanoid.Parent then return false end
	if Humanoid.PlatformStand then return true end
	if HRP and HRP.Anchored then return true end
	return false end
RunService.Heartbeat:Connect(function(dt)
	if HON_SHUTDOWN then return end
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
if State.WPLoop then
		local w = Waypoints[WPSelIdx]
		if not w then
			State.WPLoop = false
			if WPLoopTgl then WPLoopTgl.Set(false, true) end
			if notify then notify("标点已失效，循环已停止", Color3.fromRGB(255, 108, 118)) end
		else
			wpTimer = (wpTimer or 0) + dt
			if wpTimer >= (State.WPLoopInt or 5) then
				wpTimer = 0
				tpToPos(w.x, w.y, w.z)
			end
		end
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
		-- v5.48：位移动力全挪到 HonFlyJump（悬浮模式：水平 WASD/方向键 + 右上角 UP/DOWN
		-- 升降 + 不按时锁高度）。这里只负责外观和状态灯——旧代码在这算的 v 从来没写出去，
		-- 纯死代码，已拆
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
		if skillRooted() or Humanoid.WalkSpeed == 0 then
			-- 游戏定身中（放技能类：WalkSpeed 被写 0 / PlatformStand / 锚定）：
			-- 这一帧不把 WalkSpeed 抢回来，角色就钉住了；游戏恢复后下一帧自动继续加速
			statNote = "技能定身"
		else
			Humanoid.WalkSpeed = cur
			statNote = dir and "行进中" or "待机"
		end
	elseif m.Id == "V" then
		-- V 引擎：自维护虚拟速度 VVEL + CFrame 位移。
		-- 旧版直接写 AssemblyLinearVelocity，但 WalkSpeed=0 时 Humanoid 控制器会在物理步里把水平速度清零，
		-- 角色完全不动——这就是「V 引擎不能用」。CFrame 位移不经过 Humanoid，任何游戏都能正常跑。
		Humanoid.WalkSpeed = 0
		VVEL = VVEL or Vector3.zero
		if skillRooted() then
			-- 游戏定身（PlatformStand / 锚定）：连 CFrame 位移一起停，VVEL 清零，
			-- 不然定身一结束角色会带着残留速度窜出去
			VVEL = Vector3.zero
			statNote = "技能定身"
		elseif not HRP.Anchored then
			local goal = dir and (dir * cur) or Vector3.zero
			local k = 1 - math.exp(-dt * math.max(State.Smooth, 1))
			VVEL = VVEL + (goal - VVEL) * k
			if not dir and not State.Inertia then VVEL = Vector3.zero end
			local hv = Vector3.new(VVEL.X, 0, VVEL.Z)
			if hv.Magnitude > 0.05 then
				local step = hv * dt
				if State.WallSlide then
					local hit = Workspace:Raycast(HRP.Position, step, RayParams)
					if hit then
						local n = hit.Normal
						local slide = step - n * step:Dot(n)
						step = (slide.Magnitude > 0.08) and slide or Vector3.zero
					end
				end
				if step.Magnitude > 0 then
					HRP.CFrame = (HRP.CFrame - HRP.CFrame.Position) + (HRP.Position + step)
				end
				statNote = dir and "惯性冲刺" or "滑行中"
			else
				statNote = State.Inertia and "滑行中" or "已刹停"
			end
		else
			VVEL = Vector3.zero
			statNote = "锚定中"
		end
	elseif m.Id == "CF" then
		Humanoid.WalkSpeed = 0
		if skillRooted() then
			-- 同 V 引擎：游戏定身期间不做 CFrame 位移，蓄力清零，结束不窜
			CFAccum = 0
			statNote = "技能定身"
		elseif not HRP.Anchored and dir then
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
			if extra ~= "" then
				local cur = HudSub.Text
				local cut = cur:find("  ·")
				if cut then cur = cur:sub(1, cut - 1) end
				HudSub.Text = cur .. extra
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
	if processed then return end
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
	if HON_SHUTDOWN then return end
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

-- 闪电冲刺（持续加速版）：开启后越跑越快，关闭立即停
DashOn, DashSpeed, DashTimer = false, 0, 0
function setDashRun(on)
	DashOn = on
	if not on then
		DashSpeed = 0
		State.DashRun = false
		if notify then notify("闪电冲刺已关闭") end
		return
	end
	State.DashRun = true
	if notify then notify("闪电冲刺：开始加速（越跑越快）") end
end

function danceAll()
	local n, idx = 0, 0
	local targets = {}
	for _, pl in ipairs(Players:GetPlayers()) do table.insert(targets, pl.Character) end
	pcall(function()
		for _, o in ipairs(Workspace:GetDescendants()) do
			if o:IsA("Model") and o:FindFirstChildOfClass("Humanoid") and not Players:GetPlayerFromCharacter(o) then
				table.insert(targets, o)
			end
		end
	end)
	for _, ch in ipairs(targets) do
		local hum = ch and ch:FindFirstChildOfClass("Humanoid")
		if hum then
			idx = idx + 1
			pcall(function()
				local anim = Instance.new("Animation")
				anim.AnimationId = DANCE_IDS[(idx % #DANCE_IDS) + 1]
				local track = hum:LoadAnimation(anim)
				track.Looped = true
				track:Play()
			end)
			n = n + 1
		end
	end
	if notify then notify("已让 " .. n .. " 人开始跳舞") end
end

-- ---------- 翅膀系统（重建）----------
WING_STYLES = {
	{ name = "天使之翼", c = Color3.fromRGB(245, 248, 255), layers = 3, mat = Enum.Material.SmoothPlastic },
	{ name = "恶魔之翼", c = Color3.fromRGB(196, 48, 54), layers = 3, mat = Enum.Material.SmoothPlastic },
	{ name = "暗影之翼", c = Color3.fromRGB(62, 44, 96), layers = 4, mat = Enum.Material.SmoothPlastic },
	{ name = "龙翼",     c = Color3.fromRGB(54, 100, 78), layers = 2, mat = Enum.Material.Fabric },
	{ name = "蝴蝶之翼", c = Color3.fromRGB(255, 160, 220), layers = 4, mat = Enum.Material.Neon },
	{ name = "光翼",     c = Color3.fromRGB(140, 210, 255), layers = 5, mat = Enum.Material.Neon },
	{ name = "火焰之翼", c = Color3.fromRGB(255, 142, 46), layers = 3, mat = Enum.Material.Neon },
	{ name = "机械翼",   c = Color3.fromRGB(158, 168, 184), layers = 2, mat = Enum.Material.DiamondPlate },
}
WingIdx, WingParts, WingSizeV = 0, {}, 1
function clearWings()
	for _, w in ipairs(WingParts) do
		pcall(function() if w.P then w.P:Destroy() end end)
	end
	WingParts = {}
	WingIdx = 0
end
function setWing(i)
	clearWings()
	local st = WING_STYLES[i]
	if not st then return end
	WingIdx = i
	for side = -1, 1, 2 do
		for layer = 1, st.layers do
			local f = (st.layers == 1) and 0 or (layer - 1) / (st.layers - 1)
			local pt = Instance.new("Part")
			pt.Name = "HonWing"
			pt.Anchored = true
			pt.CanCollide = false
			pt.CastShadow = false
			pt.Material = st.mat
			pt.Color = st.c
			pt.TopSurface = Enum.SurfaceType.Smooth
			pt.BottomSurface = Enum.SurfaceType.Smooth
			pt.Parent = Workspace
			local len = 2.8 - f * 1.5
			local wid = 1.15 - f * 0.55
			table.insert(WingParts, {
				P = pt, F = f, Layer = layer, Side = side,
				Off = CFrame.new(side * (1.15 + f * 2.3), 0.25 + f * 0.95, 0.15 + f * 1.5)
					* CFrame.Angles(0, side * (0.25 + f * 0.55), side * 0.3),
				W = wid, L = len,
			})
		end
	end
	if notify then notify("已装备：" .. st.name) end
end


-- ---------- 玩具系统（参考 GitHub 外国开源 Admin：Fate's Admin / Infinite Yield 的经典 FE 命令）----------
-- 玩具也是商城商品：cat = "玩具"，点击卡片即启停；全部本地实现，只有自己看得见
ToyOn, ToyParts, ToyTimers = {}, {}, {}
ToyTrack, ToyAnimId = nil, nil
ToyOrbitCenter, ToyOrbitRot = nil, 0
local Debris = game:GetService("Debris")
-- Infinite Yield dance 命令同款动画 ID（R15 / R6 两套，来源：EdgeIY/infiniteyield source）
TOY_DANCE_R15 = { "3333432454", "4555808220", "4049037604", "4555782893", "10214311282",
	"10714010337", "10713981723", "10714372526", "10714076981", "10714392151", "11444443576" }
TOY_DANCE_R6 = { "27789359", "30196114", "248263260", "45834924", "33796059", "28488254", "52155728" }
TOY_CARPET_ANIM = "282574440"   -- Infinite Yield carpet 命令同款坐姿动画
-- 角色身上可挂粒子实例的部件（R15 名 + R6 名都列上，找不到就跳过）
TOY_ATTACH_PARTS = { "Head", "UpperTorso", "LowerTorso", "Torso",
	"LeftUpperArm", "RightUpperArm", "LeftArm", "RightArm",
	"LeftUpperLeg", "RightUpperLeg", "LeftLeg", "RightLeg" }

function toyClearParts(tag)
	for i = #ToyParts, 1, -1 do
		if ToyParts[i].Tag == tag then
			pcall(function() ToyParts[i].P:Destroy() end)
			table.remove(ToyParts, i)
		end
	end
end
-- 给角色部件挂原生粒子实例（Sparkles / Fire / Smoke，Roblox 原生类，真实生效）
function toyAttach(cls, props)
	local ch = LP and LP.Character
	if not ch then return {} end
	local made = {}
	for _, n in ipairs(TOY_ATTACH_PARTS) do
		local p = ch:FindFirstChild(n)
		if p and p:IsA("BasePart") and not p:FindFirstChild("Hon" .. cls) then
			local o = Instance.new(cls)
			o.Name = "Hon" .. cls
			for k, v in pairs(props) do o[k] = v end
			o.Parent = p
			table.insert(made, o)
		end
	end
	return made
end
function toyPlayAnim(id)
	local ch = LP and LP.Character
	local hum = ch and ch:FindFirstChildOfClass("Humanoid")
	if not hum then return end
	toyStopAnim()
	local anim = Instance.new("Animation")
	anim.AnimationId = "rbxassetid://" .. tostring(id)
	ToyAnimId = anim.AnimationId
	local track = hum:LoadAnimation(anim)
	track.Looped = true
	track:Play()
	ToyTrack = track
end
function toyStopAnim()
	if ToyTrack then pcall(function() ToyTrack:Stop() end) end
	ToyTrack = nil
	ToyAnimId = nil
end
function toyToggle(it)
	if not it then return end
	local on = not ToyOn[it.name]
	ToyOn[it.name] = on or nil
	if it.on then pcall(it.on, on) end
	if notify then notify((on and "已开启：" or "已关闭：") .. it.name) end
end
function toyStopAll()
	for _, it in ipairs(TOY_DEFS) do
		if it.toy and ToyOn[it.name] and it.on then pcall(it.on, false) end
	end
	ToyOn = {}
	if notify then notify("玩具已全部关闭") end
end
-- 重生后重挂（火花/火焰/烟雾挂在角色部件上，换角色要重新挂；on(true) 自带清理，可重复调用）
function toyReapplyAll()
	if not (ToyOn and next(ToyOn) and TOY_DEFS) then return end
	for _, it in ipairs(TOY_DEFS) do
		if it.toy and ToyOn[it.name] and it.on then pcall(it.on, true) end
	end
end
-- 烟花：脚下爆一圈霓虹球（Fate's Admin 经典 firework：Neon 球 + 随机速度 + Debris 定时清理）
function toyFirework()
	if not (HRP and HRP.Parent) then return end
	local cols = { Color3.fromRGB(255, 90, 90), Color3.fromRGB(255, 200, 70), Color3.fromRGB(120, 240, 120),
		Color3.fromRGB(90, 200, 255), Color3.fromRGB(190, 120, 255), Color3.fromRGB(255, 120, 200) }
	local n, base = 14, HRP.Position
	for i = 1, n do
		local p = Instance.new("Part")
		p.Name = "HonFirework"
		p.Shape = Enum.PartType.Ball
		p.Size = Vector3.new(0.45, 0.45, 0.45)
		p.Material = Enum.Material.Neon
		p.Color = cols[(i % #cols) + 1]
		p.CanCollide = false
		p.CastShadow = false
		p.Position = base + Vector3.new(0, 0.3, 0)
		local ang = (i / n) * math.pi * 2
		local sp = 8 + math.random() * 5
		p.Velocity = Vector3.new(math.cos(ang) * sp, 13 + math.random() * 8, math.sin(ang) * sp)
		p.Parent = Workspace
		Debris:AddItem(p, 2.2)
	end
end
-- 每帧驱动（烟花连发计时 / 魔毯跟随 / 气球浮动 / 环绕公转）
function toyFrame(dt)
	if ToyOn["烟花"] then
		ToyTimers["烟花"] = (ToyTimers["烟花"] or 0) + dt
		if ToyTimers["烟花"] >= 0.9 then
			ToyTimers["烟花"] = 0
			toyFirework()
		end
	end
	if not (HRP and HRP.Parent) then return end
	if ToyOn["魔毯"] then
		for _, d in ipairs(ToyParts) do
			if d.P and d.P.Parent then
				if d.Tag == "carpet" then
					d.P.CFrame = HRP.CFrame * CFrame.new(0, -2.42, 0)
				elseif d.Tag == "carpetTrim" then
					-- 金边镶在地毯前缘
					d.P.CFrame = HRP.CFrame * CFrame.new(0, -2.28, 0) * CFrame.new(0, 0, -1.75)
				end
			end
		end
	end
	if ToyOn["气球"] then
		local t = tick()
		for _, d in ipairs(ToyParts) do
			if d.Tag == "balloon" and d.P and d.P.Parent then
				local bob = math.sin(t * 1.6 + d.Ph) * 0.22
				d.P.CFrame = HRP.CFrame * d.Off * CFrame.new(0, bob, 0)
			end
		end
	end
	if ToyOn["环绕"] and ToyOrbitCenter then
		-- ToyOrbitRot 直接按弧度累加（不要再 math.rad，否则等于二次换算、转速慢 57 倍）
		ToyOrbitRot = ToyOrbitRot + 2.4 * dt
		local c = ToyOrbitCenter
		local pos = (CFrame.new(c) * CFrame.Angles(0, ToyOrbitRot, 0) * CFrame.new(4, 0, 0)).Position
		HRP.AssemblyLinearVelocity = Vector3.zero
		HRP.CFrame = CFrame.lookAt(pos, Vector3.new(c.X, pos.Y, c.Z))
	end
end

-- 玩具商品（接入商城网格，点击即启停）
TOY_DEFS = {
	{ cat = "玩具", name = "烟花", icon = "🎆", price = 0, toy = true, on = function(active)
		if active then ToyTimers["烟花"] = 0 else ToyTimers["烟花"] = nil end
	end },
	{ cat = "玩具", name = "火花", icon = "✨", price = 0, toy = true, on = function(active)
		toyClearParts("sparkles")
		if active then
			for _, o in ipairs(toyAttach("Sparkles", { Color = Color3.fromRGB(255, 230, 120), Enabled = true })) do
				table.insert(ToyParts, { P = o, Tag = "sparkles" })
			end
		end
	end },
	{ cat = "玩具", name = "火焰", icon = "🔥", price = 0, toy = true, on = function(active)
		toyClearParts("fire")
		if active then
			for _, o in ipairs(toyAttach("Fire", { Size = 9, Heat = 12,
				Color = Color3.fromRGB(255, 150, 40), SecondaryColor = Color3.fromRGB(255, 60, 20) })) do
				table.insert(ToyParts, { P = o, Tag = "fire" })
			end
		end
	end },
	{ cat = "玩具", name = "烟雾", icon = "💨", price = 0, toy = true, on = function(active)
		toyClearParts("smoke")
		if active then
			for _, o in ipairs(toyAttach("Smoke", { Size = 6, RiseVelocity = 2.5, Opacity = 0.45,
				Color = Color3.fromRGB(180, 180, 190) })) do
				table.insert(ToyParts, { P = o, Tag = "smoke" })
			end
		end
	end },
	{ cat = "玩具", name = "魔毯", icon = "🪄", price = 0, toy = true, on = function(active)
		toyClearParts("carpet")
		toyClearParts("carpetTrim")
		if active then
			-- 创建瞬间就贴到脚下（否则第一帧前停在世界原点，会闪一下）
			local baseCF = HRP and HRP.CFrame or CFrame.new()
			local p = Instance.new("Part")
			p.Name = "HonCarpet"
			p.Size = Vector3.new(4, 0.25, 4)
			p.Color = Color3.fromRGB(150, 40, 60)
			p.Material = Enum.Material.Fabric
			p.Anchored = true; p.CanCollide = false; p.CastShadow = false
			p.CFrame = baseCF * CFrame.new(0, -2.42, 0)
			p.Parent = Workspace
			table.insert(ToyParts, { P = p, Tag = "carpet" })
			local trim = Instance.new("Part")
			trim.Name = "HonCarpetTrim"
			trim.Size = Vector3.new(4.2, 0.1, 0.5)
			trim.Color = Color3.fromRGB(230, 200, 110)
			trim.Material = Enum.Material.SmoothPlastic
			trim.Anchored = true; trim.CanCollide = false; trim.CastShadow = false
			trim.CFrame = baseCF * CFrame.new(0, -2.28, 0) * CFrame.new(0, 0, -1.75)
			trim.Parent = Workspace
			table.insert(ToyParts, { P = trim, Tag = "carpetTrim" })
			toyPlayAnim(TOY_CARPET_ANIM)
		else
			toyStopAnim()
		end
	end },
	{ cat = "玩具", name = "跳舞", icon = "💃", price = 0, toy = true, on = function(active)
		if active then
			local ch = LP and LP.Character
			local ids = (ch and ch:FindFirstChild("UpperTorso")) and TOY_DANCE_R15 or TOY_DANCE_R6
			toyPlayAnim(ids[math.random(1, #ids)])
		else
			toyStopAnim()
		end
	end },
	{ cat = "玩具", name = "气球", icon = "🎈", price = 0, toy = true, on = function(active)
		toyClearParts("balloon")
		if active then
			local cols = { Color3.fromRGB(255, 80, 90), Color3.fromRGB(90, 160, 255), Color3.fromRGB(255, 200, 70) }
			local offs = { CFrame.new(-0.75, 2.7, 0), CFrame.new(0.75, 2.9, 0), CFrame.new(0, 3.2, 0.25) }
			-- 创建瞬间就定位到头上（避免第一帧前停在世界原点闪一下）
			local baseCF = HRP and HRP.CFrame or CFrame.new()
			for i = 1, 3 do
				local p = Instance.new("Part")
				p.Name = "HonBalloon"
				p.Shape = Enum.PartType.Ball
				p.Size = Vector3.new(1.1, 1.3, 1.1)
				p.Color = cols[i]
				p.Material = Enum.Material.SmoothPlastic
				p.Anchored = true; p.CanCollide = false; p.CastShadow = false
				p.CFrame = baseCF * offs[i]
				p.Parent = Workspace
				table.insert(ToyParts, { P = p, Tag = "balloon", Off = offs[i], Ph = i * 1.3 })
			end
		end
	end },
	{ cat = "玩具", name = "环绕", icon = "☄️", price = 0, toy = true, on = function(active)
		if active then
			ToyOrbitCenter = HRP and HRP.Position
			ToyOrbitRot = 0
		else
			ToyOrbitCenter = nil
		end
	end },
}




-- ===== 娱乐页追加：三个新趣味功能 + 翅膀 + 玩具（原装扮页拆除后搬来）=====
label({ Text = "新 玩 法 NEW FUN", Font = Enum.Font.GothamBold, TextSize = 11,
	TextColor3 = Color3.fromRGB(120, 129, 152), Size = UDim2.new(1, 0, 0, 18),
	Position = UDim2.new(0, 2, 0, 1252), TextXAlignment = Enum.TextXAlignment.Left }, PageFun)
EjectBtn = new("TextButton", { Text = "🚀 弹射升空 EJECT", Font = Enum.Font.GothamBold, TextSize = 11,
	TextColor3 = Mode().Accent, BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.9,
	BorderSizePixel = 0, AutoButtonColor = false,
	Size = UDim2.new(1, 0, 0, 36), Position = UDim2.new(0, 0, 0, 1276), Parent = PageFun })
corner(EjectBtn, 10)
table.insert(FunBtns, EjectBtn)
bindClick(EjectBtn, "弹射升空", ejectUp)
PlayDeadTgl = makeToggle(PageFun, 1320, "装死倒地 PLAY DEAD", "当场躺平装死，再点站起来", false, function(v)
	setPlayDead(v)
end, true)
NeonGlowTgl = makeToggle(PageFun, 1368, "霓虹发光 NEON GLOW", "全身变色流光，关掉自动还原", false, function(v)
	setNeonGlow(v)
end, true)

-- 翅膀（原装扮页搬来）
label({ Text = "翅 膀 WINGS", Font = Enum.Font.GothamBold, TextSize = 11,
	TextColor3 = Color3.fromRGB(120, 129, 152), Size = UDim2.new(1, 0, 0, 18),
	Position = UDim2.new(0, 2, 0, 1416), TextXAlignment = Enum.TextXAlignment.Left }, PageFun)
for i, st in ipairs(WING_STYLES) do
	local col = (i - 1) % 2
	local row = math.floor((i - 1) / 2)
	local b = new("TextButton", { Text = st.name, Font = Enum.Font.GothamBold, TextSize = 11,
		TextColor3 = Mode().Accent, BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.9, BorderSizePixel = 0, AutoButtonColor = false,
		Size = UDim2.new(0.5, -4, 0, 34),
		Position = UDim2.new(col == 0 and 0 or 0.5, col == 0 and 0 or 4, 0, 1440 + row * 40), Parent = PageFun })
	corner(b, 8)
	table.insert(FunBtns, b)
	bindClick(b, st.name, function() setWing(i) end)
end
local NoWingBtn = new("TextButton", { Text = "收起翅膀", Font = Enum.Font.GothamBold, TextSize = 11,
	TextColor3 = Color3.fromRGB(255, 108, 118), BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	BackgroundTransparency = 0.9, BorderSizePixel = 0, AutoButtonColor = false,
	Size = UDim2.new(1, 0, 0, 32), Position = UDim2.new(0, 0, 0, 1600), Parent = PageFun })
corner(NoWingBtn, 8)
table.insert(FunBtns, NoWingBtn)
bindClick(NoWingBtn, "收起翅膀", function() clearWings() end)
makeSlider(PageFun, "翅膀大小", 1640, 40, 220, 100, " %", function(v) WingSizeV = v / 100 end, false)

-- 玩具（原装扮页「玩具」分类搬来：点卡片即开即关，纯本地特效）
label({ Text = "玩 具 TOYS · 点卡片即开即关", Font = Enum.Font.GothamBold, TextSize = 11,
	TextColor3 = Color3.fromRGB(120, 129, 152), Size = UDim2.new(1, 0, 0, 18),
	Position = UDim2.new(0, 2, 0, 1692), TextXAlignment = Enum.TextXAlignment.Left }, PageFun)
ToyBtns = {}
local function toyRefresh()
	for _, b in ipairs(ToyBtns) do
		if b and b.Parent then b:Destroy() end
	end
	ToyBtns = {}
	local shown = 0
	for _, it in ipairs(TOY_DEFS) do
		shown = shown + 1
		local col = (shown - 1) % 2
		local row = math.floor((shown - 1) / 2)
		local on = ToyOn[it.name]
		local card = new("TextButton", { Text = "", Font = Enum.Font.Gotham, TextSize = 11,
			TextColor3 = Color3.fromRGB(226, 233, 248),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = on and 0.86 or 0.93, BorderSizePixel = 0, AutoButtonColor = false,
			Size = UDim2.new(0.5, -4, 0, 54), Position = UDim2.new(col == 0 and 0 or 0.5, col == 0 and 0 or 4, 0, 1716 + row * 60), Parent = PageFun })
		corner(card, 8)
		if on then new("UIStroke", { Color = Mode().Accent, Transparency = 0.4, Thickness = 1.5, Parent = card }) end
		table.insert(ToyBtns, card)
		local ib = new("Frame", { Size = UDim2.new(0, 38, 0, 38), Position = UDim2.new(0, 8, 0, 8),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.88,
			BorderSizePixel = 0, Parent = card })
		corner(ib, 8)
		label({ Text = it.icon or "🎁", Font = Enum.Font.GothamBold, TextSize = 18,
			Size = UDim2.new(1, 0, 1, 0), TextColor3 = Color3.fromRGB(238, 243, 255) }, ib)
		label({ Text = (on and "✓ " or "") .. it.name, Font = Enum.Font.GothamBold, TextSize = 11,
			TextColor3 = on and Mode().Accent or Color3.fromRGB(226, 233, 248),
			Size = UDim2.new(1, -56, 0, 16), Position = UDim2.new(0, 54, 0, 7),
			TextXAlignment = Enum.TextXAlignment.Left }, card)
		label({ Text = on and "✨ 开启中 · 点击关闭" or "玩具 · 点击开启", Font = Enum.Font.Gotham, TextSize = 9,
			TextColor3 = on and Mode().Accent or Color3.fromRGB(140, 200, 255),
			Size = UDim2.new(1, -56, 0, 14), Position = UDim2.new(0, 54, 0, 28),
			TextXAlignment = Enum.TextXAlignment.Left }, card)
		bindClick(card, it.name, function()
			toyToggle(it)
			toyRefresh()
		end)
	end
end
ToyAllOffBtn = new("TextButton", { Text = "全部关闭 TOYS OFF", Font = Enum.Font.GothamBold, TextSize = 11,
	TextColor3 = Color3.fromRGB(255, 108, 118), BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	BackgroundTransparency = 0.9, BorderSizePixel = 0, AutoButtonColor = false,
	Size = UDim2.new(1, 0, 0, 32), Position = UDim2.new(0, 0, 0, 1962), Parent = PageFun })
corner(ToyAllOffBtn, 8)
table.insert(FunBtns, ToyAllOffBtn)
bindClick(ToyAllOffBtn, "玩具全部关闭", function() toyStopAll(); toyRefresh() end)
toyRefresh()
label({ Text = "玩具全部是本地特效，只有自己看得见；重生后自动重挂；UNLOAD 会一并清掉。", Font = Enum.Font.Gotham, TextSize = 10,
	TextColor3 = Color3.fromRGB(120, 129, 152), Position = UDim2.new(0, 2, 0, 2002),
	Size = UDim2.new(1, -4, 0, 26), TextWrapped = true,
	TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top }, PageFun)

-- ---------- 独立飞行 / 自动连跳 ----------
-- 之前这两项写在引擎主循环里，一旦「启用引擎」关闭就整段不执行 → 表现为「开了没用」。
-- 现在独立成一条渲染循环，不受引擎开关影响。
RunService:BindToRenderStep("HonFlyJump", 9994, function(dt)
	if HON_SHUTDOWN then return end
	if not (HRP and HRP.Parent) then return end
	if State.Fly then
		-- v5.48 悬浮模式重写（用户：「把角色控制在原地，就固定在原地，只能前后移动，
		-- 前后左右移动准确来说就是，上下只能靠屏幕右上角的那两个按钮键来进行动」）：
		-- ① 水平走原始输入（WASD / 虚拟方向键）——PlatformStand 下 MoveDirection 是失效的，
		-- 旧代码读它等于水平移动整个是死的；② 上下只认右上角 UP/DOWN 两个按钮键，E/Q 键盘升降去掉；
		-- ③ 不按升降 = 弹簧锁在当前高度（按过再松手就锁定新高度，角色固定在原地不坠不飘）；
		-- ④ 每帧直接写 HRP.AssemblyLinearVelocity，不依赖 LinearVelocity 约束（老执行器也认）
		if not (FlyAtt and FlyAtt.Parent) then pcall(buildFlyParts) end
		local spd = State.FlySpeed or 60
		local dir = flyDir()
		local vx, vz = 0, 0
		if dir then vx, vz = dir.X * spd, dir.Z * spd end
		local vy
		if FlyUp or FlyDown then
			local vert = (FlyUp and 1 or 0) - (FlyDown and 1 or 0)
			vy = vert * spd
			FlyHoldY = (FlyHoldY or HRP.Position.Y) + vert * spd * dt
		else
			if not FlyHoldY then FlyHoldY = HRP.Position.Y end
			vy = math.clamp((FlyHoldY - HRP.Position.Y) * 8, -spd, spd)
		end
		pcall(function() HRP.AssemblyLinearVelocity = Vector3.new(vx, vy, vz) end)
		-- 朝向跟随镜头水平朝向（不含俯仰——不能一边飞一边抬头望天）
		if FlyOrient then
			local look = horiz(Cam.CFrame.LookVector)
			if look and look.Magnitude > 0.01 then
				pcall(function() FlyOrient.CFrame = CFrame.lookAt(HRP.Position, HRP.Position + look) end)
			end
		end
	end
	if State.AutoJump and Humanoid and Humanoid.Parent then
		if Humanoid.FloorMaterial ~= Enum.Material.Air and not State.Fly then
			Humanoid.Jump = true
		end
	end
	if DashOn and HRP and HRP.Parent then
		DashSpeed = math.min(DashSpeed + dt * 55, 260)
		local md = (Humanoid and Humanoid.Parent) and Humanoid.MoveDirection or Vector3.zero
		local dir = md.Magnitude > 0.05 and Vector3.new(md.X, 0, md.Z).Unit or horiz(Cam.CFrame.LookVector)
		pcall(function() HRP.AssemblyLinearVelocity = dir * DashSpeed + Vector3.new(0, HRP.AssemblyLinearVelocity.Y, 0) end)
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
	-- 触屏数字键：每个控件单独可拖，屏幕上点哪个就能挪哪个
	pcall(function() for _, o in ipairs(TouchBtns) do makeDraggable(o.Btn or o) end end)
	-- v5.47：虚拟方向键不再按格分散拖（用户：「而不是把所有按键全部分散拖动」）——
	-- 整块拖走：按住方向格挪动过 12px 容忍区即拖动整个 PadFrame，中心格仍是
	-- 轻碰=走、长按 0.3s=拖整块；这里只保留框体本身的拖拽（格子间 3px 缝隙）
	pcall(function() if PadFrame then makeDraggable(PadFrame) end end)
	pcall(function()
		if TouchBtns and #TouchBtns > 0 and notify then
			notify("触屏控件已可拖动：方向键按住格子里挪动=整块拖，数字键各自拖")
		end
	end)
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
	-- 用户：「有的功能打开会自动在屏幕右上角生成一个提示窗，我不要让它生成，
	-- 当我开启功能显示那个时候它才会生成」——这个清单从此只归「功能列表显示」管，
	-- 不开功能列表显示时天塌下来也不弹
	if not State.ShowFunList then
		if TopBarFrame then TopBarFrame.Visible = false end
		return
	end
	if not TopBarFrame then
		TopBarFrame = new("Frame", { Name = "HonTopBar", Size = UDim2.new(0, 172, 0, 120),
			Position = UDim2.new(1, -184, 0, 8), BackgroundColor3 = Color3.fromRGB(13, 15, 23),
			BackgroundTransparency = 0.3, BorderSizePixel = 0, Visible = false, Parent = Gui })
		corner(TopBarFrame, 10)
		new("UIStroke", { Color = Mode().Accent, Transparency = 0.7, Thickness = 1, Parent = TopBarFrame })
		TopBarLabel = label({ Text = "", Font = Enum.Font.GothamBold, TextSize = 11,
			TextColor3 = Mode().Accent, BackgroundTransparency = 1, Size = UDim2.new(1, -14, 0, 110),
			Position = UDim2.new(0, 8, 0, 5), TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top }, TopBarFrame)
	end
	local list = {}
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
	if State.LowGravity then table.insert(list, "反重力") end
	if State.AntiRagdoll then table.insert(list, "防布娃娃") end
	if State.GfxNight then table.insert(list, "夜视") end
	if State.GfxSuperNight then table.insert(list, "超级夜视") end
	if State.GfxNoFog then table.insert(list, "去雾") end
	if State.DashRun then table.insert(list, "冲刺") end
	if State.SparkTP then table.insert(list, "瞬移") end
	if #list > 0 then
		local parts = {}
		for i, nm in ipairs(list) do parts[i] = tostring(i) .. ". " .. nm end
		TopBarLabel.Text = table.concat(parts, "\n")
		TopBarFrame.Size = UDim2.new(0, 172, 0, math.min(18 * #list + 12, 300))
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

-- ---------- 设置页 ----------
UI_STYLES = {
	{ name = "默认暗色", bg = Color3.fromRGB(13, 15, 23), alpha = 0.05, stroke = 0.92 },
	{ name = "液态玻璃", bg = Color3.fromRGB(22, 30, 46), alpha = 0.32, stroke = 0.5 },
	{ name = "霓虹黑",   bg = Color3.fromRGB(8, 10, 18),  alpha = 0.12, stroke = 0.3 },
	{ name = "纯黑极简", bg = Color3.fromRGB(0, 0, 0),    alpha = 0.22, stroke = 0.85 },
	-- 阳光派对 · 竞技活动三套皮肤
	{ name = "酷风 COOL",   bg = Color3.fromRGB(14, 24, 34), alpha = 0.16, stroke = 0.30,
		strokeColor = Color3.fromRGB(90, 220, 255), strokeThick = 1.5, glowColor = Color3.fromRGB(40, 160, 230),
		Fx = "tech" },
	{ name = "可爱风 CUTE", bg = Color3.fromRGB(52, 28, 42), alpha = 0.20, stroke = 0.45,
		strokeColor = Color3.fromRGB(255, 160, 200), strokeThick = 2, glowColor = Color3.fromRGB(230, 110, 160),
		Fx = "sakura" },
	{ name = "魔眼 3D",     bg = Color3.fromRGB(16, 4, 6),   alpha = 0.06, stroke = 0.15,
		strokeColor = Color3.fromRGB(235, 45, 55), strokeThick = 2.5, glowColor = Color3.fromRGB(190, 25, 35),
		Fx = "demon" },
}
ANIM_STYLES = { "神威漩涡（推荐）", "淡入淡出", "缩放弹出", "不要动画" }
-- 启动/删除动画开关（v5.44：按用户要求去掉样式切换，只留「放不放这一套动画」）——
-- 开着就播默认的神威漩涡（启动）/ 收回（删除），关了面板直接出现/消失，不再有 ▾ 循环按钮
AnimOn, CloseAnimOn = true, true
-- 字体默认直接最大（用户要求「默认拉到最大」）：无存档时 160%，有存档按存档来
FontScaleV, UiStyleIdx, AnimStyleIdx, CloseAnimIdx = 1.6, 1, 1, 1
FontBase = {}

function applyUiStyle(i)
	local st = UI_STYLES[i] or UI_STYLES[1]
	pcall(function()
		Main.BackgroundColor3 = st.bg
		Main.BackgroundTransparency = st.alpha
		if MainStroke then
			MainStroke.Transparency = st.stroke
			MainStroke.Color = st.strokeColor or Color3.fromRGB(255, 255, 255)
			MainStroke.Thickness = st.strokeThick or 1
		end
		if Glow and st.glowColor then Glow.BackgroundColor3 = st.glowColor end
	end)
	-- 边框开着且是「主题色」时边框色优先：不然换个皮肤，描边色就被样式覆盖回白色
	if BorderOn and BorderMode == 4 and MainStroke then MainStroke.Color = Mode().Accent end
	-- v5.47：主题特效（樱花 / 科技扫描线 / 地狱翅膀+巨眼）跟着样式走
	pcall(buildStyleFx, i)
	if notify then notify("UI 样式：" .. st.name) end
end

-- ===== v5.47：三主题屏幕特效（用户：「可爱风加点樱花特效，魔眼加点那种地狱的那种翅膀
-- 什么的呀，或者眼睛的那种，然后酷炫的也是加点科技风的」）=====
-- 特效挂在 Gui（ScreenGui）下的全屏层，随「UI 样式」切换增删，render step「HonStyleFx」驱动：
-- 酷风 = 科技扫描线 + 四角 HUD 支架；可爱风 = 18 片樱花飘落（摇摆+旋转+循环）；
-- 魔眼 = 地狱翅膀（3 层翼指绕肩扇动）+ 一双巨眼（瞳孔游移 + 定时眨眼）
StyleFxRoot, StyleFxKind, StyleFxT = nil, nil, 0
StyleFxParts = {}
function clearStyleFx()
	StyleFxKind = nil
	StyleFxParts = {}
	if StyleFxRoot and StyleFxRoot.Parent then StyleFxRoot:Destroy() end
	StyleFxRoot = nil
	pcall(function() RunService:UnbindFromRenderStep("HonStyleFx") end)
end
-- 爱心：粉色 ♥ 飘落（摇摆 + 旋转 + 循环）；泡泡：半透明圆形上浮（可爱风额外特效）
-- 放在 fxSakura 之前定义，避免 Lua 局部函数前向引用在真机结算为全局 nil
local function fxHeart()
	local W = Cam.ViewportSize.X
	for k = 1, 10 do
		local sz = 14 + (k % 4) * 5
		local f = new("TextLabel", { Size = UDim2.new(0, sz, 0, sz),
			BackgroundTransparency = 1, BorderSizePixel = 0,
			Text = "♥", TextColor3 = Color3.fromRGB(255, 96, 144), TextSize = sz,
			TextTransparency = 0.15 + (k % 3) * 0.12,
			Font = Enum.Font.SourceSansBold, Parent = StyleFxRoot })
		table.insert(StyleFxParts, { K = "heart", F = f,
			X = 20 + math.random() * (W - 40), Y = math.random() * 760,
			V = 22 + math.random() * 30, SW = 14 + math.random() * 30,
			Fq = 0.4 + math.random() * 0.8, Ph = math.random() * 6.283,
			R = (math.random() - 0.5) * 70 })
	end
end
local function fxBubble()
	local W, H = Cam.ViewportSize.X, Cam.ViewportSize.Y
	for k = 1, 12 do
		local sz = 8 + (k % 6) * 4
		local f = new("Frame", { Size = UDim2.new(0, sz, 0, sz),
			BackgroundColor3 = Color3.fromRGB(255, 210, 235), BackgroundTransparency = 0.55,
			BorderSizePixel = 0, Parent = StyleFxRoot })
		corner(f, sz / 2)
		pcall(function() new("UIStroke", { Color = Color3.fromRGB(255, 255, 255),
			Transparency = 0.55, Thickness = 1, Parent = f }) end)
		table.insert(StyleFxParts, { K = "bubble", F = f,
			X = 20 + math.random() * (W - 40), Y = H + math.random() * 200,
			V = 18 + math.random() * 28, SW = 10 + math.random() * 24,
			Fq = 0.3 + math.random() * 0.6, Ph = math.random() * 6.283 })
	end
end
-- 樱花花瓣
local function fxSakura()
	local pal = { Color3.fromRGB(255, 183, 206), Color3.fromRGB(255, 205, 226),
		Color3.fromRGB(255, 222, 236), Color3.fromRGB(248, 165, 190) }
	local W = Cam.ViewportSize.X
	for k = 1, 18 do
		local sz = 7 + (k % 5) * 2.4
		local f = new("Frame", { Size = UDim2.new(0, sz, 0, sz * 0.8), Rotation = 0,
			BackgroundColor3 = pal[(k % 4) + 1], BackgroundTransparency = 0.1 + (k % 4) * 0.07,
			BorderSizePixel = 0, Parent = StyleFxRoot })
		corner(f, sz / 2)
		table.insert(StyleFxParts, { K = "petal", F = f,
			X = 30 + math.random() * (W - 60), Y = math.random() * 760,
			V = 26 + math.random() * 46, SW = 18 + math.random() * 42,
			Fq = 0.5 + math.random() * 0.9, Ph = math.random() * 6.283,
			R = (math.random() - 0.5) * 150 })
	end
	-- 可爱风额外特效：樱花之外再飘粉色爱心 + 上浮泡泡（用户：「不能只有樱花落下」）
	if State and State.CuteFxExtra then
		fxHeart()
		fxBubble()
	end
end
-- 科技风：扫描线 + 四角 HUD 支架
local function fxTech(st)
	local W, H = Cam.ViewportSize.X, Cam.ViewportSize.Y
	local cy = st.glowColor or Color3.fromRGB(40, 160, 230)
	-- 一条 2px 亮线 + 外面罩 26px 渐变光带，从上往下循环扫
	local band = new("Frame", { Size = UDim2.new(1, 0, 0, 26), Position = UDim2.new(0, 0, 0, -40),
		BackgroundColor3 = cy, BackgroundTransparency = 0.86, BorderSizePixel = 0, Parent = StyleFxRoot })
	new("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.5),
		NumberSequenceKeypoint.new(1, 1) }), Parent = band })
	local line = new("Frame", { Size = UDim2.new(1, 0, 0, 2), Position = UDim2.new(0, 0, 0, -40),
		BackgroundColor3 = cy, BackgroundTransparency = 0.2, BorderSizePixel = 0, Parent = StyleFxRoot })
	table.insert(StyleFxParts, { K = "scan", Band = band, Line = line, V = 130 })
	-- 四角支架：每角一横一竖两条 2px 臂，呼吸式明暗
	local arm, inset = 30, 16
	for ci = 1, 4 do
		local ox = (ci == 1 or ci == 3) and inset or (W - inset)
		local oy = (ci <= 2) and inset or (H - inset)
		local dx = (ci == 1 or ci == 3) and 1 or -1
		local dy = (ci <= 2) and 1 or -1
		local b1 = new("Frame", { Size = UDim2.new(0, arm, 0, 2),
			Position = UDim2.new(0, dx > 0 and ox or (ox - arm), 0, oy),
			BackgroundColor3 = cy, BackgroundTransparency = 0.35, BorderSizePixel = 0, Parent = StyleFxRoot })
		local b2 = new("Frame", { Size = UDim2.new(0, 2, 0, arm),
			Position = UDim2.new(0, ox, 0, dy > 0 and oy or (oy - arm)),
			BackgroundColor3 = cy, BackgroundTransparency = 0.35, BorderSizePixel = 0, Parent = StyleFxRoot })
		table.insert(StyleFxParts, { K = "bracket", Bars = { b1, b2 } })
	end
end
-- 魔眼：地狱翅膀 + 一双巨眼
local function fxDemon(st)
	local W, H = Cam.ViewportSize.X, Cam.ViewportSize.Y
	local red = st.strokeColor or Color3.fromRGB(235, 45, 55)
	local cx, cy = W * 0.5, H * 0.58
	-- 翅膀：每侧 3 层 × 4 根翼指，绕肩点扇动（层越靠外越暗越大）
	for side = -1, 1, 2 do
		for layer = 1, 3 do
			local col = (layer == 1) and Color3.fromRGB(96, 10, 16)
				or (layer == 2 and Color3.fromRGB(150, 20, 28) or red)
			local tr = 0.16 + (layer - 1) * 0.1
			for bi = 1, 4 do
				local len = 110 + bi * 32 + layer * 14
				local w = 13 - bi * 1.6 + layer
				local b = new("Frame", { Size = UDim2.new(0, len, 0, w),
					AnchorPoint = Vector2.new(side > 0 and 0 or 1, 0.5),
					Position = UDim2.new(0, cx + side * 30, 0, cy),
					Rotation = (-52 + (bi - 1) * 24) * side,
					BackgroundColor3 = col, BackgroundTransparency = tr,
					BorderSizePixel = 0, Parent = StyleFxRoot })
				corner(b, w / 2)
				table.insert(StyleFxParts, { K = "bone", F = b,
					A0 = (-52 + (bi - 1) * 24) * side, Ph = bi * 0.55 + layer * 0.3 })
			end
		end
	end
	-- 巨眼一双：黑眶 + 大红虹膜 + 竖瞳 + 高光；定时眨眼，瞳孔缓慢游移
	for e = -1, 1, 2 do
		local ew, eh = 92, 116
		local box = new("Frame", { Size = UDim2.new(0, ew, 0, eh),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0, W * 0.5 + e * 108, 0, H * 0.17),
			BackgroundTransparency = 1, Parent = StyleFxRoot })
		local scl = new("Frame", { Size = UDim2.new(1, 0, 1, 0),
			BackgroundColor3 = Color3.fromRGB(12, 2, 4), BackgroundTransparency = 0.04,
			BorderSizePixel = 0, Parent = box })
		corner(scl, 40)
		new("UIStroke", { Color = red, Transparency = 0.55, Thickness = 1.5, Parent = scl })
		local iris = new("Frame", { Size = UDim2.new(0, 66, 0, 66), AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0), BackgroundColor3 = red,
			BackgroundTransparency = 0.05, BorderSizePixel = 0, Parent = box })
		corner(iris, 33)
		local pup = new("Frame", { Size = UDim2.new(0, 13, 0, 52), AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0), BackgroundColor3 = Color3.fromRGB(6, 0, 2),
			BorderSizePixel = 0, Parent = box })
		corner(pup, 6)
		local shine = new("Frame", { Size = UDim2.new(0, 12, 0, 12), AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, -14, 0.5, -16), BackgroundColor3 = Color3.fromRGB(255, 240, 240),
			BackgroundTransparency = 0.25, BorderSizePixel = 0, Parent = box })
		corner(shine, 6)
		table.insert(StyleFxParts, { K = "eye", Box = box, Iris = iris, Pup = pup,
			EW = ew, EH = eh, BlinkT = 2.4 + e * 0.9, BlinkPh = 0 })
	end
end
function buildStyleFx(i)
	clearStyleFx()
	local st = UI_STYLES[i] or UI_STYLES[1]
	if not st.Fx then return end
	StyleFxRoot = new("Frame", { Name = "HonStyleFx", Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1, BorderSizePixel = 0, Parent = Gui })
	StyleFxKind = st.Fx
	if st.Fx == "sakura" then fxSakura()
	elseif st.Fx == "tech" then fxTech(st)
	elseif st.Fx == "demon" then fxDemon(st) end
	if #StyleFxParts > 0 then
		RunService:BindToRenderStep("HonStyleFx", 2002, function(dt)
			if HON_SHUTDOWN or not StyleFxRoot or not StyleFxRoot.Parent then return end
			-- 特效仅面板开启时显示：面板全关则隐藏整层并跳过，不烧帧
			if State and State.StyleFxPanelOnly
				and not (Main and (Main.Visible or (Mini and Mini.Visible))) then
				if StyleFxRoot.Visible then StyleFxRoot.Visible = false end
				return
			end
			if not StyleFxRoot.Visible then StyleFxRoot.Visible = true end
			-- 整帧包一层：个别元素出问题只跳这一帧，不连带其他特效
			pcall(function()
			StyleFxT = StyleFxT + dt
			local t = StyleFxT
			local H = Cam.ViewportSize.Y
			local W = Cam.ViewportSize.X
			for _, d in ipairs(StyleFxParts) do
				if d.K == "petal" then
					d.Y = d.Y + d.V * dt
					if d.Y > H + 16 then d.Y = -16; d.X = 30 + math.random() * (W - 60) end
					d.F.Position = UDim2.new(0, d.X + math.sin(t * d.Fq + d.Ph) * d.SW, 0, d.Y)
					d.F.Rotation = (d.F.Rotation + d.R * dt) % 360
				elseif d.K == "heart" then
					d.Y = d.Y + d.V * dt
					if d.Y > H + 20 then d.Y = -20; d.X = 20 + math.random() * (W - 40) end
					d.F.Position = UDim2.new(0, d.X + math.sin(t * d.Fq + d.Ph) * d.SW, 0, d.Y)
					d.F.Rotation = (d.F.Rotation + d.R * dt) % 360
				elseif d.K == "bubble" then
					d.Y = d.Y - d.V * dt
					if d.Y < -20 then d.Y = H + math.random() * 120; d.X = 20 + math.random() * (W - 40) end
					d.F.Position = UDim2.new(0, d.X + math.sin(t * d.Fq + d.Ph) * d.SW, 0, d.Y)
				elseif d.K == "scan" then
					local y = (t * d.V) % (H + 60) - 40
					d.Band.Position = UDim2.new(0, 0, 0, y - 13)
					d.Line.Position = UDim2.new(0, 0, 0, y)
				elseif d.K == "bracket" then
					local tr = 0.35 + 0.2 * (0.5 + 0.5 * math.sin(t * 3))
					for _, b in ipairs(d.Bars) do b.BackgroundTransparency = tr end
				elseif d.K == "bone" then
					d.F.Rotation = d.A0 + math.sin(t * 2.2 + d.Ph) * 11
					d.F.BackgroundTransparency = 0.16 + 0.08 * (0.5 + 0.5 * math.sin(t * 2.2 + d.Ph))
				elseif d.K == "eye" then
					-- 瞳孔游移：双螺线慢转，幅度限制在眼眶内
					local dx = math.sin(t * 0.6) * 13 + math.sin(t * 0.23) * 5
					local dy = math.cos(t * 0.44) * 11
					d.Iris.Position = UDim2.new(0.5, dx, 0.5, dy)
					d.Pup.Position = UDim2.new(0.5, dx, 0.5, dy)
					-- 眨眼：倒计时到点进入 0.16s 闭-开窗口
					d.BlinkT = d.BlinkT - dt
					if d.BlinkT <= 0 then d.BlinkPh = 0.16; d.BlinkT = 2.6 + math.random() * 2.4 end
					local open = 1
					if d.BlinkPh > 0 then
						d.BlinkPh = d.BlinkPh - dt
						local u = 1 - math.max(d.BlinkPh, 0) / 0.16
						open = 1 - math.sin(u * math.pi)
					end
					d.Box.Size = UDim2.new(0, d.EW, 0, math.max(2, d.EH * open))
				end
			end
			end)
		end)
	end
end

function applyFontScale(sc)
	FontScaleV = sc
	pcall(function()
		for _, d in ipairs(Gui:GetDescendants()) do
			if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then
				if not FontBase[d] then FontBase[d] = d.TextSize end
				d.TextSize = math.max(6, math.floor(FontBase[d] * sc + 0.5))
			end
		end
	end)
end

-- ===== 面板边框（照参考源码的模式：开关 + 样式循环，彩虹模式挂渲染循环）=====
-- 描边本体就是 Main 自带的 MainStroke；开关只切它的 Enabled，样式决定颜色。
-- 透明度/粗细继续归 UI 样式管（applyUiStyle），两边不打架
BORDER_STYLES = { "彩虹", "红色", "蓝色", "主题色" }
BorderOn, BorderMode = true, 4
function setBorder(on, quiet)
	BorderOn = on and true or false
	pcall(function() if MainStroke then MainStroke.Enabled = BorderOn end end)
	if BorderOn then
		setBorderMode(BorderMode, true)
	else
		-- 关边框必须解绑彩虹循环，不然颜色还在变，只是被 Enabled 藏住——白烧帧
		pcall(function() RunService:UnbindFromRenderStep("HonBorder") end)
	end
	if notify and not quiet then notify(BorderOn and ("面板边框已开启 · " .. BORDER_STYLES[BorderMode]) or "面板边框已关闭") end
end
function setBorderMode(m, quiet)
	BorderMode = math.clamp(math.floor(m or 1), 1, #BORDER_STYLES)
	if not BorderOn then
		if notify and not quiet then notify("边框样式：" .. BORDER_STYLES[BorderMode] .. " · 打开边框开关后生效") end
		return
	end
	if BorderMode == 1 then
		-- 彩虹：渲染循环里走 HSV 色环（复用 hsv2rgb，不依赖 Color3.fromHSV，执行器/mock 都稳）
		pcall(function() RunService:UnbindFromRenderStep("HonBorder") end)
		pcall(function()
			RunService:BindToRenderStep("HonBorder", 2001, function()
				if not (BorderOn and MainStroke and MainStroke.Parent) then
					-- 边框被关/面板被销毁时自己解绑，不留野循环
					pcall(function() RunService:UnbindFromRenderStep("HonBorder") end)
					return
				end
				MainStroke.Color = hsv2rgb((tick() * 0.15) % 1, 0.85, 1)
			end)
		end)
	else
		pcall(function() RunService:UnbindFromRenderStep("HonBorder") end)
		local c = Mode().Accent
		if BorderMode == 2 then c = Color3.fromRGB(255, 70, 82) end
		if BorderMode == 3 then c = Color3.fromRGB(80, 160, 255) end
		pcall(function() if MainStroke then MainStroke.Color = c end end)
	end
	if notify and not quiet then notify("边框样式：" .. BORDER_STYLES[BorderMode]) end
end


-- ===== 界面框架切换：自制 UI / WindUI（搬参考脚本的 WindUI 库）=====
-- 用户原话：「在设置里加一个 UI 样式，注意不是 UI 风格，就是加一个 WindUI，
-- 可以在自制和 windui 进行切换」。UI 风格 = 上面那 7 套皮肤（applyUiStyle）；
-- 界面框架 = 整套界面库，这里是二选一切换， WindUI 加载/构建任何一步失败都
-- 自动回退自制 UI，绝不给用户留白屏
FW_NAMES = { "自制 UI", "WindUI" }
UiFrameworkIdx, WindWin = 1, nil
PrefFramework = nil
-- v5.48：切 WindUI 前记住自制面板的显隐，切回时原样恢复（缩成迷你条也不怕）
GuiPanelBak = nil
-- 每个 WindUI 组件调用都过 windSafe：库里单个组件签名不符/字段缺失只废那一个，
-- 不炸整个界面（更不会让用户回不去自制 UI）
function windSafe(name, fn)
	local ok, err = pcall(fn)
	if not ok then _pr("[HON] WindUI 组件出错 " .. tostring(name) .. ": " .. tostring(err)) end
	return ok
end
function windFetch()
	-- 优先白嫖别人已经加载好的 _G.WindUI，没有就自己 loadstring 拉 dist/main.lua
	local ok, lib = pcall(function() return _G.WindUI end)
	if ok and lib then return lib end
	if type(loadstring) ~= "function" then return nil end
	-- v5.46 借鉴夜脚本 tryLoadWindUI 的重试：HttpGet 偶发失败（网络抖动 / 限流）
	-- 就整体回退自制 UI 太脆——最多试 3 次，任一成功即用，全失败才回退
	for _ = 1, 3 do
		local okSrc, src = pcall(function()
			return game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua")
		end)
		if okSrc and type(src) == "string" and src ~= "" then
			local okLib, lib2 = pcall(function() return loadstring(src)() end)
			if okLib and lib2 then return lib2 end
		end
	end
	return nil
end
function windDestroy()
	pcall(function()
		if WindWin then
			if WindWin.Close then WindWin:Close() end
			if WindWin.Destroy then WindWin:Destroy() end
		end
	end)
	WindWin = nil
	-- 自制 UI 还活着（只是被隐藏），直接放出来（按切换前的显隐恢复，别把用户缩起的面板强行展开）
	pcall(function()
		if Gui then Gui.Enabled = true end
		if GuiPanelBak then
			if Main then Main.Visible = GuiPanelBak.main end
			if Mini then Mini.Visible = GuiPanelBak.mini end
			GuiPanelBak = nil
		end
	end)
end
-- 自制开关 → WindUI 开关：直接驱动原 toggle 的 Set(v)（非 silent），
-- 完整复刻点击行为（onChange + 存档）。同名开关（如两个「反重力」）一起同步。
-- 初值读实时 _last（makeToggle 里已做成实时同步），不另存镜像——用户在自制 UI
-- 里点过关再切框架，WindUI 那边必须显示当前状态，不能是创建时的快照
function windTglByTitle(tab, title, sub)
	local list = {}
	for _, t in ipairs(ToggleRegistry) do
		if t._title == title and t.Set then table.insert(list, t) end
	end
	if #list == 0 then return end
	windSafe("tgl:" .. title, function()
		tab:Toggle({
			Title = title, Desc = sub or "", Value = list[1]._last and true or false,
			Callback = function(v)
				for i, t in ipairs(list) do t.Set(v, i > 1) end
			end,
		})
	end)
end
-- 自制滑条 → WindUI 滑条：走 Apply（非 silent，触发 onChange 的存档/生效逻辑），
-- 初值取滑条当前值（GetValue），保证切框架前后显示一致
function windSld(tab, api, title, mn, mx, def, step)
	if not (api and api.Apply) then return end
	local init = def
	if api.GetValue then
		local ok, v = pcall(api.GetValue)
		if ok and type(v) == "number" then init = v end
	end
	windSafe("sld:" .. title, function()
		tab:Slider({
			Title = title, Step = step or 1,
			Value = { Min = mn, Max = mx, Default = math.clamp(init, mn, mx) },
			Callback = function(v) api.Apply(v) end,
		})
	end)
end
function windBtn(tab, title, sub, fn)
	windSafe("btn:" .. title, function()
		tab:Button({ Title = title, Desc = sub or "", Callback = function() pcall(fn) end })
	end)
end
-- 照自制 UI 的页面结构搭一套 WindUI：引擎/辅助/视觉/传送/娱乐/画质/设置
function windBuild(lib)
	if not lib or not lib.CreateWindow then return false end
	local W = nil
	windSafe("CreateWindow", function()
		W = lib:CreateWindow({
			Title = "HonSpeedHub · WindUI",
			Author = "极速驱动",
			Icon = "solar:wind-bold",
			Theme = "Dark",
			ToggleKey = Enum.KeyCode.F,
		})
	end)
	if not W then return false end
	WindWin = W
	-- 再补一层保险（夜脚本同款）：CreateWindow 可能被库吞掉背景参数，建完强制再写一次
	windSafe("Tag", function() W:Tag({ Title = "v5.58", Color = "ElementBackground" }) end)
	-- 引擎页
	local tEng = nil
	windSafe("Tab:引擎", function() tEng = W:Tab({ Title = "引擎", Icon = "gauge" }) end)
	if tEng then
		for i, m in ipairs(Modes) do
			windBtn(tEng, m.Name, m.Desc, function() SetMode(i) end)
		end
		windSld(tEng, SpeedSlider, "速度 SPEED", Modes[1].Min, Modes[1].Max, State.Speed, 1)
		windSld(tEng, SmoothSlider, "顺滑 SMOOTH", 1, 20, State.Smooth, 1)
		windTglByTitle(tEng, "启用引擎", "F2 快捷键 · 隐身时仍保持")
		windTglByTitle(tEng, "惯性滑行", "仅 V 引擎生效")
		windTglByTitle(tEng, "防穿墙 / 沿墙滑动", "CF / V 引擎生效")
		windTglByTitle(tEng, "瞬移闪现 TP", "仅 CF · 蓄力后整段位移")
		windTglByTitle(tEng, "引擎描边 OUTLINE", "角色轮廓跟着引擎颜色")
		windTglByTitle(tEng, "加速小窗 SPEED WIN", "屏幕小窗 · 切模式 / 调速度，把手可拖动")
	end
	-- 辅助页
	local tAss = nil
	windSafe("Tab:辅助", function() tAss = W:Tab({ Title = "辅助", Icon = "life-buoy" }) end)
	if tAss then
		windSld(tAss, JumpSlider, "跳跃力 JUMP", 16, 200, DEFAULT_JUMP, 1)
		windTglByTitle(tAss, "启用跳跃增强", "逐帧回写防被重置")
		windTglByTitle(tAss, "无限跳", "空中可反复起跳")
		windTglByTitle(tAss, "穿墙 NOCLIP", "关闭时还原碰撞体")
		windTglByTitle(tAss, "反挂机 ANTI-AFK", "防止长时间无操作掉线")
		windTglByTitle(tAss, "速度 HUD", "屏幕底部实时显示速度")
		windTglByTitle(tAss, "飞行窗口 FLY", "打开小窗 + 右上角上下键")
		windTglByTitle(tAss, "相机穿墙 CAMERA NOCLIP", "镜头不被墙/地形遮挡，可看穿墙体")
	end
	-- 视觉页
	local tEsp = nil
	windSafe("Tab:视觉", function() tEsp = W:Tab({ Title = "视觉", Icon = "eye" }) end)
	if tEsp then
		windSld(tEsp, TranspSlider, "身体透明度", 0, 100, State.BodyTransp, 1)
		windTglByTitle(tEsp, "玩家透视", "高亮 + 名称 / 距离 / 血量")
		windTglByTitle(tEsp, "NPC 透视", "高亮所有非玩家人形")
		windTglByTitle(tEsp, "交互物透视", "ProximityPrompt / ClickDetector")
		windTglByTitle(tEsp, "秒交互", "HoldDuration=0 · 距离 30")
		windTglByTitle(tEsp, "雷达 RADAR", "右上角 · 人/NPC/互动物/墙壁折线")
		windTglByTitle(tEsp, "穿墙显示", "角色高亮穿墙，名字/血条/距离永远可见")
		windTglByTitle(tEsp, "血条背景 HP BAR BG", "开=有背景实时血量 · 关=纯血量数字")
		windSld(tEsp, EspFontSlider, "ESP 字体", 60, 200, 100, 1)
		windBtn(tAss, "一键触碰所有可触碰物体", "整个服务器：Prompt / ClickDetector / Tool", function()
			touchAllInteractables()
		end)
	end
	-- 传送页
	local tTp = nil
	windSafe("Tab:传送", function() tTp = W:Tab({ Title = "传送", Icon = "locate-fixed" }) end)
	if tTp then
		windSafe("Input:坐标", function()
			tTp:Input({
				Title = "传送到坐标", Desc = "填 X,Y,Z（可用逗号或空格分隔）",
				Placeholder = "例如 100, 200, 300", Value = "",
				Callback = function(text)
					local x, y, z = string.match(tostring(text or ""), "(-?%d+%.?%d*)[,%s]+(-?%d+%.?%d*)[,%s]+(-?%d+%.?%d*)")
					if not x then
						if notify then notify("坐标格式不对：要三个数字，如 100, 200, 300", Color3.fromRGB(255, 176, 32)) end
						return
					end
					tpToPos(tonumber(x), tonumber(y), tonumber(z))
				end,
			})
		end)
		windTglByTitle(tTp, "点击传送", "开启后点地面即可瞬移过去")
		windTglByTitle(tTp, "防坠落 ANTI-VOID", "掉出地图自动拉回安全点")
		windTglByTitle(tTp, "倒计时器 COUNTDOWN", "屏幕小 UI · 输入分钟数倒数，到点提醒")
		windTglByTitle(tTp, "标点小窗 WP WIN", "屏幕小窗 · 看坐标 / 存标点 / ★ 选中传送")
		windTglByTitle(tTp, "闪电尖兵大招 SPARK ULT", "点击画面任意位置直接传送过去（照搬参考源码）")
	end
	-- 娱乐页
	local tFun = nil
	windSafe("Tab:娱乐", function() tFun = W:Tab({ Title = "娱乐", Icon = "gamepad-2" }) end)
	if tFun then
		windBtn(tFun, "弹射升空", "一键把自己炸上天（2.5s 冷却）", function() ejectUp() end)
		for i, st in ipairs(WING_STYLES) do
			windBtn(tFun, "翅膀 · " .. st.name, "点击穿戴 / 再点切换", function() setWing(i) end)
		end
		windBtn(tFun, "收起翅膀", "卸掉全部翅膀", function() clearWings() end)
		for _, it in ipairs(TOY_DEFS) do
			windSafe("toy:" .. it.name, function()
				tFun:Toggle({
					Title = (it.icon or "") .. " " .. it.name,
					Value = ToyOn[it.name] and true or false,
					Callback = function() toyToggle(it) end,
				})
			end)
		end
	end
	-- 画质页
	local tGfx = nil
	windSafe("Tab:画质", function() tGfx = W:Tab({ Title = "画质", Icon = "sparkles" }) end)
	if tGfx then
		windSld(tGfx, GfxBrightSlider, "亮度", 0, 200, 100, 1)
		windSld(tGfx, GfxSatSlider, "饱和度", 0, 200, 100, 1)
		windTglByTitle(tGfx, "关闭阴影", "关掉全局阴影，帧数明显提升")
		windTglByTitle(tGfx, "关闭雾气", "视野更清楚")
		windTglByTitle(tGfx, "关闭粒子特效", "烟/火/拖尾/光束全关")
		windTglByTitle(tGfx, "隐藏贴花/纹理", "墙面图案去掉，更干净")
		windTglByTitle(tGfx, "普通夜视", "夜里全亮 · 阴影全关")
		windTglByTitle(tGfx, "超级夜视", "超高亮度 · 正午光感")
		windTglByTitle(tGfx, "彻底去雾", "连 Atmosphere 雾霾一起清")
		windBtn(tGfx, "一键提升帧率 · 降低卡顿", "阴影/粒子/贴图/地形装饰/渲染质量全压掉，可一键还原", function() fpsBoost() end)
		windBtn(tGfx, "恢复默认画质", "所有画质项恢复原状（含帧率优化动过的项）", function() gfxReset() end)
	end
	-- 设置页（含切回自制 UI 的入口——用户在 WindUI 里也能回自制）
	local tSet = nil
	windSafe("Tab:设置", function() tSet = W:Tab({ Title = "设置", Icon = "settings" }) end)
	if tSet then
		windBtn(tSet, "切回自制 UI", "关闭 WindUI，恢复原来的界面", function() setUiFramework(1) end)
		if BorderTgl and BorderTgl.Set then
			windSafe("tgl:面板边框", function()
				tSet:Toggle({
					Title = "面板边框", Desc = "WindUI 自身界面边框由库里管，这里管自制 UI 的",
					Value = BorderOn,
					Callback = function(v) BorderOn = v; setBorder(v); prefSave() end,
				})
			end)
		end
		windSld(tSet, FontSlider, "字体大小", 70, 160, PrefFontScale and math.floor(PrefFontScale * 100 + 0.5) or 160, 1)
		windSld(tSet, PanelScaleSlider, "面板缩放", 60, 140, PrefPanelScale and math.floor(PrefPanelScale * 100 + 0.5) or 100, 1)
		windTglByTitle(tSet, "启动动画", "开机播放神威漩涡展开动画")
		windTglByTitle(tSet, "删除动画", "关闭面板时播放碎裂消失动画")
		if RagTgl and RagTgl.Set then
			windSafe("tgl:防布娃娃", function()
				tSet:Toggle({
					Title = "防布娃娃 ANTI RAGDOLL", Desc = "不会被打倒/摔倒（夜脚本同款）",
					Value = RagTgl._last and true or false,
					Callback = function(v) RagTgl.Set(v) end,
				})
			end)
		end
		windBtn(tSet, "换个服务器（随机重进）", "会重新加载脚本", function()
			pcall(function()
				if notify then notify("正在换服务器…") end
				TeleportService:Teleport(game.PlaceId, LP)
			end)
		end)
		windBtn(tSet, "彻底关闭脚本 UNLOAD", "关掉所有功能并销毁界面", function() unloadScript() end)
	end
	return true
end
function setUiFramework(i)
	i = math.clamp(math.floor(i or 1), 1, #FW_NAMES)
	if i == 2 then
		local lib = windFetch()
		if not lib then
			UiFrameworkIdx = 1
			if notify then notify("WindUI 加载失败（执行器不支持 loadstring/HttpGet），已回退自制 UI", Color3.fromRGB(255, 205, 110)) end
			return false
		end
		if not windBuild(lib) then
			UiFrameworkIdx = 1
			if notify then notify("WindUI 界面构建失败，已回退自制 UI", Color3.fromRGB(255, 205, 110)) end
			return false
		end
		UiFrameworkIdx = 2
		-- v5.48：只藏自制主面板，绝不禁整个 Gui——倒计时 / 加速 / 标点 / 飞行这些小窗
		-- 和右上角 UP/DOWN 键全挂在 Gui 下，禁 Gui 等于把它们连窝端
		-- （用户：「倒计时不显示在那个小窗上面」「飞行用不了」根因就在这）
		GuiPanelBak = { main = Main and Main.Visible, mini = Mini and Mini.Visible }
		if Main then Main.Visible = false end
		if Mini then Mini.Visible = false end
		-- 背景图应用到 WindUI 窗口（CreateWindow 已接参数，这里再保险一次）
		if notify then notify("已切换到 WindUI（按 F 开关界面）") end
	else
		windDestroy()
		UiFrameworkIdx = 1
		if notify then notify("已切回自制 UI") end
	end
	PrefFramework = UiFrameworkIdx
	pcall(prefSave)
	return true
end
-- 「当前框架」用按钮背景深浅标，不用文字色——SetMode 会把所有 FunBtns 的
-- 文字染成主题色，用文字色标「当前」会被引擎切换冲掉
function paintFwBtns()
	for i, b in ipairs(FwBtns or {}) do
		pcall(function()
			b.Text = FW_NAMES[i] .. (i == UiFrameworkIdx and " · 当前" or "")
			b.BackgroundTransparency = (i == UiFrameworkIdx) and 0.78 or 0.93
		end)
	end
end

label({ Text = "设 置 SETTINGS", Font = Enum.Font.GothamBold, TextSize = 11,
	TextColor3 = Color3.fromRGB(120, 129, 152), Size = UDim2.new(1, 0, 0, 18),
	Position = UDim2.new(0, 2, 0, 0), TextXAlignment = Enum.TextXAlignment.Left }, PageSet)

-- UI 样式：7 个按钮
for i, st in ipairs(UI_STYLES) do
	local b = new("TextButton", { Text = st.name, Font = Enum.Font.GothamBold, TextSize = 11,
		TextColor3 = Mode().Accent, BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.9, BorderSizePixel = 0, AutoButtonColor = false,
		Size = UDim2.new(0.5, -4, 0, 32),
		Position = UDim2.new(((i - 1) % 2 == 0) and 0 or 0.5, ((i - 1) % 2 == 0) and 0 or 4, 0, 24 + math.floor((i - 1) / 2) * 38),
		Parent = PageSet })
	corner(b, 8)
	table.insert(FunBtns, b)
	bindClick(b, st.name, function() UiStyleIdx = i; applyUiStyle(i) end)
end

-- UI 样式（框架）：整套界面库二选一——自制 UI / WindUI。注意跟上面的「UI 风格」
-- 不是一回事：上面那排是换皮肤（applyUiStyle），这里换的是整套界面库
label({ Text = "界面框架 UI FRAMEWORK · 切换整套界面", Font = Enum.Font.GothamBold, TextSize = 11,
	TextColor3 = Color3.fromRGB(120, 129, 152), Size = UDim2.new(1, 0, 0, 18),
	Position = UDim2.new(0, 2, 0, 178), TextXAlignment = Enum.TextXAlignment.Left }, PageSet)
FwBtns = {}
for i, nm in ipairs(FW_NAMES) do
	local b = new("TextButton", { Text = nm, Font = Enum.Font.GothamBold, TextSize = 11,
		TextColor3 = Mode().Accent, BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.9, BorderSizePixel = 0, AutoButtonColor = false,
		Size = UDim2.new(0.5, -4, 0, 32),
		Position = UDim2.new(i == 1 and 0 or 0.5, i == 1 and 0 or 4, 0, 196),
		Parent = PageSet })
	corner(b, 8)
	table.insert(FunBtns, b)
	table.insert(FwBtns, b)
	bindClick(b, "界面框架" .. nm, function() setUiFramework(i) end)
end
paintFwBtns()

-- 面板边框：开关 + 样式循环（彩虹/红/蓝/主题色，照参考源码那套模式）
label({ Text = "面板边框 BORDER", Font = Enum.Font.GothamBold, TextSize = 11,
	TextColor3 = Color3.fromRGB(120, 129, 152), Size = UDim2.new(1, 0, 0, 18),
	Position = UDim2.new(0, 2, 0, 238), TextXAlignment = Enum.TextXAlignment.Left }, PageSet)
BorderTgl = makeToggle(PageSet, 256, "面板边框", "面板外圈描边 · 样式在下面换", BorderOn, function(v)
	setBorder(v)
	prefSave()
end, true)
local BorderModeBtn = new("TextButton", { Text = "边框样式：" .. BORDER_STYLES[BorderMode] .. "  ▾", Font = Enum.Font.GothamBold, TextSize = 11,
	TextColor3 = Mode().Accent, BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	BackgroundTransparency = 0.9, BorderSizePixel = 0, AutoButtonColor = false,
	Size = UDim2.new(1, 0, 0, 32), Position = UDim2.new(0, 0, 0, 304), Parent = PageSet })
corner(BorderModeBtn, 8)
table.insert(FunBtns, BorderModeBtn)
bindClick(BorderModeBtn, "边框样式", function()
	setBorderMode((BorderMode % #BORDER_STYLES) + 1)
	BorderModeBtn.Text = "边框样式：" .. BORDER_STYLES[BorderMode] .. "  ▾"
	prefSave()
end)

-- 启动 / 删除动画开关：用户要求「可开可关，不要动画切换」——样式循环整层删掉，只留默认的神威漩涡
AnimTgl = makeToggle(PageSet, 346, "启动动画", "开机播放神威漩涡展开动画", AnimOn, function(v)
	AnimOn = v
	animSave()
	if notify then notify(v and "启动动画已开启" or "启动动画已关闭") end
end, true)
CloseAnimTgl = makeToggle(PageSet, 394, "删除动画", "关闭面板时播放碎裂消失动画", CloseAnimOn, function(v)
	CloseAnimOn = v
	animSave()
	if notify then notify(v and "删除动画已开启" or "删除动画已关闭") end
end, true)
InputAnimTgl = makeToggle(PageSet, 442, "输入动画 INPUT ANIM", "按钮按下时的缩放回弹反馈（关闭则无动画）", true, function(v)
	State.InputAnim = v
	if notify then notify(v and "输入动画已开启" or "输入动画已关闭") end
end, true)
-- v5.54：可爱风额外特效（爱心 + 泡泡）随樱花一起飘；以及屏幕特效的显示时机（仅面板开启 / 全程）
CuteFxExtraTgl = makeToggle(PageSet, 490, "可爱风额外特效 CUTE EXTRA", "可爱风在樱花外再加爱心 + 泡泡飘落", true, function(v)
	State.CuteFxExtra = v
	pcall(buildStyleFx, UiStyleIdx or 1)
end, true)
StyleFxPanelOnlyTgl = makeToggle(PageSet, 538, "特效仅面板开启 FX PANEL-ONLY", "开=只有面板打开时才显示特效；关=全程一直显示", false, function(v)
	State.StyleFxPanelOnly = v
	if StyleFxRoot then StyleFxRoot.Visible = (not v) or (Main and (Main.Visible or (Mini and Mini.Visible))) end
end, true)
-- 动画开关存档（本地文件 + 跨服务器双保险，和标点同一套机制）
ANIM_FILE = "HonSpeedHub_Anim.json"
function animSave()
	local d = { on = AnimOn and true or false, co = CloseAnimOn and true or false }
	local ok, json = pcall(function() return HttpService:JSONEncode(d) end)
	if not ok or not json then return end
	pcall(function() if writefile then writefile(ANIM_FILE, json) end end)
	pcall(function() TeleportService:SetTeleportSetting("HON_ANIM", json) end)
end
function animLoad()
	local d = nil
	pcall(function()
		if isfile and readfile and isfile(ANIM_FILE) then
			local ok, x = pcall(function() return HttpService:JSONDecode(readfile(ANIM_FILE)) end)
			if ok and type(x) == "table" then d = x end
		end
	end)
	if not d then
		pcall(function()
			local raw = TeleportService:GetTeleportSetting("HON_ANIM")
			if raw and raw ~= "" then
				local ok, x = pcall(function() return HttpService:JSONDecode(raw) end)
				if ok and type(x) == "table" then d = x end
			end
		end)
	end
	if d then
		-- 新档 on/co 是布尔；旧档 o/c 是样式序号（4 = 不要动画 → 对应开关关上）
		if type(d.on) == "boolean" then AnimOn = d.on end
		if type(d.co) == "boolean" then CloseAnimOn = d.co end
		if type(d.o) == "number" and d.o == 4 then AnimOn = false end
		if type(d.c) == "number" and d.c == 4 then CloseAnimOn = false end
	end
end
animLoad()

-- UI 偏好存档：字体大小 / 面板缩放 / 背景图透明（本地文件 + 跨服务器双保险，和动画样式同一套机制）
-- 用户要求「脚本设置里面增加个自动保存」——这三项改完即存，换服/重进不恢复默认
PREF_FILE = "HonSpeedHub_Pref.json"
PrefFontScale, PrefPanelScale, PrefFramework = nil, nil, nil
function prefSave()
	-- fw = 界面框架（1 自制 / 2 WindUI），bo/bm = 面板边框开关与样式，
	-- ef = ESP 字体缩放——和背景图一样本地文件 + 跨服务器双保险，重启/换服不恢复默认
	local d = { fs = PrefFontScale, ps = PrefPanelScale,
		fw = UiFrameworkIdx or 1, bo = BorderOn and true or false, bm = BorderMode or 1,
		ef = EspFontScale }
	local ok, json = pcall(function() return HttpService:JSONEncode(d) end)
	if not ok or not json then return end
	pcall(function() if writefile then writefile(PREF_FILE, json) end end)
	pcall(function() TeleportService:SetTeleportSetting("HON_PREF", json) end)
end
function prefLoad()
	local d = nil
	pcall(function()
		if isfile and readfile and isfile(PREF_FILE) then
			local ok, x = pcall(function() return HttpService:JSONDecode(readfile(PREF_FILE)) end)
			if ok and type(x) == "table" then d = x end
		end
	end)
	if not d then
		pcall(function()
			local raw = TeleportService:GetTeleportSetting("HON_PREF")
			if raw and raw ~= "" then
				local ok, x = pcall(function() return HttpService:JSONDecode(raw) end)
				if ok and type(x) == "table" then d = x end
			end
		end)
	end
	if not d then return end
	if type(d.fs) == "number" then PrefFontScale = math.clamp(d.fs, 0.7, 1.6) end
	if type(d.ps) == "number" then PrefPanelScale = math.clamp(d.ps, 0.6, 1.4) end
	if type(d.fw) == "number" and (d.fw == 1 or d.fw == 2) then PrefFramework = d.fw end
	if type(d.bo) == "boolean" then BorderOn = d.bo end
	if type(d.bm) == "number" then BorderMode = math.clamp(math.floor(d.bm), 1, #BORDER_STYLES) end
	-- ef = ESP 字体缩放（v5.47）：0.6 ~ 2.0，重启/换服照原样恢复
	if type(d.ef) == "number" then EspFontScale = math.clamp(d.ef, 0.6, 2) end
end
prefLoad()
local psDef = PrefPanelScale and math.floor(PrefPanelScale * 100 + 0.5) or 100
local fsDef = PrefFontScale and math.floor(PrefFontScale * 100 + 0.5) or 160
PanelScaleSlider = makeSlider(PageSet, "面板缩放", 596, 60, 140, math.clamp(psDef, 60, 140), " %", function(v)
	PrefPanelScale = v / 100
	pcall(function() if MainScale then MainScale.Scale = PrefPanelScale end end)
	prefSave()
end, false)
FontSlider = makeSlider(PageSet, "字体大小", 652, 70, 160, math.clamp(fsDef, 70, 160), " %", function(v)
	PrefFontScale = v / 100
	applyFontScale(v / 100)
	prefSave()
end, false)

-- v5.47：ESP 字体放大滑条（视觉页，用户：「增加一个透视字体放大，因为字体太小了。
-- 就是我设置到那个字体，下次启动脚本的时候还是在那个字体的位置，就那个大小」）——
-- 60% ~ 200% 整体等比缩放竖排三件套，改动即存 ef 档，重启/换服照原样恢复
local efDef = math.floor(EspFontScale * 100 + 0.5)
EspFontSlider = makeSlider(PageEsp, "ESP 字体", 406, 60, 200, math.clamp(efDef, 60, 200), " %", function(v)
	EspFontScale = v / 100
	espApplyFont()
	prefSave()
end, false)
pcall(espApplyFont)
EspHpBarBgTgl = makeToggle(PageEsp, 454, "血条背景 HP BAR BG", "开=有背景实时血量 · 关=纯血量数字", true, function(v)
	State.EspHpBarBg = v
	refreshEspHpStyle()
end, true)
-- ===== 一键触碰所有可触碰物体（用户：「一键触碰所有可触碰的物体，整个服务器」）=====
-- 遍历 Workspace:GetDescendants()：ProximityPrompt → fireproximityprompt（执行器扩展），
-- ClickDetector → 试 fireclickdetector，Tool → Activate()；逐个 pcall，橙提示汇总成功数
function touchAllInteractables()
	local n = 0
	for _, d in ipairs(Workspace:GetDescendants()) do
		if d and d.Parent then
			local cn = d.ClassName
			if cn == "ProximityPrompt" then
				if pcall(function() fireproximityprompt(d) end) then n = n + 1 end
			elseif cn == "ClickDetector" then
				if pcall(function() fireclickdetector(d) end) then n = n + 1 end
			elseif cn == "Tool" then
				if pcall(function() d:Activate() end) then n = n + 1 end
			end
		end
	end
	if notify then notify("已触发 " .. n .. " 个可触碰物体", Color3.fromRGB(255, 176, 32)) end
	return n
end
local TouchAllBtn = new("TextButton", { Text = "一键触碰所有可触碰物体", Font = Enum.Font.GothamBold, TextSize = 11,
	TextColor3 = Mode().Accent, BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.9,
	BorderSizePixel = 0, AutoButtonColor = false,
	Size = UDim2.new(1, 0, 0, 36), Position = UDim2.new(0, 0, 0, 654), Parent = PageTool })
corner(TouchAllBtn, 10)
table.insert(FunBtns, TouchAllBtn)
bindClick(TouchAllBtn, "一键触碰", function() touchAllInteractables() end)

local FixBtn = new("TextButton", { Text = "恢复角色外观（修染色）", Font = Enum.Font.GothamBold, TextSize = 11,
	TextColor3 = Color3.fromRGB(150, 220, 255), BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	BackgroundTransparency = 0.9, BorderSizePixel = 0, AutoButtonColor = false,
	Size = UDim2.new(1, 0, 0, 34), Position = UDim2.new(0, 0, 0, 764), Parent = PageSet })
corner(FixBtn, 8)
table.insert(FunBtns, FixBtn)
bindClick(FixBtn, "恢复外观", function() fixCharacterLook() end)

local ResetScaleBtn = new("TextButton", { Text = "重置身体比例", Font = Enum.Font.GothamBold, TextSize = 11,
	TextColor3 = Color3.fromRGB(255, 200, 120), BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	BackgroundTransparency = 0.9, BorderSizePixel = 0, AutoButtonColor = false,
	Size = UDim2.new(1, 0, 0, 34), Position = UDim2.new(0, 0, 0, 804), Parent = PageSet })
corner(ResetScaleBtn, 8)
table.insert(FunBtns, ResetScaleBtn)
bindClick(ResetScaleBtn, "重置比例", function()
	setBodyScale(1, 1, 1)
	if notify then notify("身体比例已重置为 100%") end
end)

RagTgl = makeToggle(PageSet, 848, "防布娃娃 ANTI RAGDOLL", "不会被打倒/摔倒（夜脚本同款）", false, function(v)
	syncRagTgls(v)
end, true)

local KillBtn = new("TextButton", { Text = "彻底关闭脚本 UNLOAD", Font = Enum.Font.GothamBold, TextSize = 12,
	TextColor3 = Color3.fromRGB(255, 108, 118), BackgroundColor3 = Color3.fromRGB(255, 80, 90),
	BackgroundTransparency = 0.82, BorderSizePixel = 0, AutoButtonColor = false,
	Size = UDim2.new(1, 0, 0, 38), Position = UDim2.new(0, 0, 0, 934), Parent = PageSet })
corner(KillBtn, 8)
table.insert(FunBtns, KillBtn)
bindClick(KillBtn, "关闭脚本", function()
	askConfirm("彻底关闭脚本？", "会关掉所有功能、清掉翅膀/分身/黑洞等生成物、销毁界面并停止全部循环。\n（只是收起面板请点右上角 – 或 ×，功能会继续跑）", "确认关闭", function()
		unloadScript()
	end)
end)
local SvBtn = new("TextButton", { Text = "换个服务器（随机重进）", Font = Enum.Font.GothamBold, TextSize = 11,
	TextColor3 = Mode().Accent, BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	BackgroundTransparency = 0.9, BorderSizePixel = 0, AutoButtonColor = false,
	Size = UDim2.new(1, 0, 0, 34), Position = UDim2.new(0, 0, 0, 894), Parent = PageSet })
corner(SvBtn, 8)
table.insert(FunBtns, SvBtn)
bindClick(SvBtn, "换服务器", function()
	pcall(function()
		if notify then notify("正在换服务器…") end
		TeleportService:Teleport(game.PlaceId, LP)
	end)
end)
label({ Text = "换服务器会重新加载脚本；动画样式 / 标点 / 界面框架 / 边框已自动存档，换服不丢；其他设置仅本次有效",
	Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = Color3.fromRGB(132, 141, 163),
	BackgroundTransparency = 1, Position = UDim2.new(0, 2, 0, 884),
	Size = UDim2.new(1, -4, 0, 40), TextWrapped = true,
	TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top }, PageSet)

-- 恢复角色外观（修染色 + 材质）
function fixCharacterLook()
	local c = LP.Character
	if not c then return end
	pcall(function()
		for _, d in ipairs(c:GetDescendants()) do
			if d:IsA("BasePart") then
				d.Material = Enum.Material.Plastic
				d.Transparency = 0
			end
		end
		local bc = c:FindFirstChild("Body Colors") or c:FindFirstChildOfClass("BodyColors")
		if bc then
			-- 触发肤色重新应用
			bc.Parent = nil
			bc.Parent = c
		end
	end)
	if notify then notify("角色外观已恢复（材质/颜色重置）") end
end

-- ---------- 画质修改（独立页，原「材质修改」关掉搬到这里）----------
GfxFx = nil
-- 画质还原机制：每个「关闭类」功能第一次开启时记录游戏原始值，关闭时原样还原。
-- 旧版直接写死值（雾 FogEnd=500 / 阴影 true / 粒子 Enabled=true），游戏原本不是这个值就被改坏，
-- 且 ColorCorrectionEffect 挂在 Lighting 里退出脚本也不清——下次启动画面残留，用户只能开画质覆盖，
-- 这就是「画质必须每次启动都开启，不开就出 bug」的根因
GfxOrigShadow, GfxOrigFog = nil, nil
GfxOrigParts, GfxOrigDecals = {}, {}
-- 一键提升帧率用到的两个额外原值：地形装饰 Terrain.Decoration、引擎渲染质量 QualityLevel
GfxOrigTerrainDeco, GfxOrigQuality = nil, nil
function gfxLight()
	if not Lighting then Lighting = game:GetService("Lighting") end
	return Lighting
end
function setGfxShadows(on)
	local L = gfxLight()
	if on then
		if GfxOrigShadow == nil then GfxOrigShadow = L.GlobalShadows end
		pcall(function() L.GlobalShadows = false end)
	else
		-- 注意：不能用 (GfxOrigShadow ~= nil) and GfxOrigShadow or true——
		-- GfxOrigShadow = false 时该链会错误求值为 true，把游戏原本的关阴影强制打开
		if GfxOrigShadow ~= nil then
			pcall(function() L.GlobalShadows = GfxOrigShadow end)
		else
			pcall(function() L.GlobalShadows = true end)
		end
		GfxOrigShadow = nil
	end
end
function setGfxFog(on)
	local L = gfxLight()
	if on then
		if GfxOrigFog == nil then GfxOrigFog = { S = L.FogStart, E = L.FogEnd } end
		pcall(function() L.FogEnd = 100000; L.FogStart = 0 end)
	else
		if GfxOrigFog then
			pcall(function() L.FogStart = GfxOrigFog.S; L.FogEnd = GfxOrigFog.E end)
			GfxOrigFog = nil
		end
	end
end
function setGfxParticles(on)
	pcall(function()
		if on then
			for _, o in ipairs(Workspace:GetDescendants()) do
				if (o:IsA("ParticleEmitter") or o:IsA("Trail") or o:IsA("Beam")
					or o:IsA("Smoke") or o:IsA("Fire") or o:IsA("Sparkles"))
					and GfxOrigParts[o] == nil then
					GfxOrigParts[o] = o.Enabled
					o.Enabled = false
				end
			end
		else
			for o, e in pairs(GfxOrigParts) do
				if o and o.Parent then pcall(function() o.Enabled = e end) end
			end
			GfxOrigParts = {}
		end
	end)
end
function setGfxDecal(on)
	pcall(function()
		if on then
			for _, o in ipairs(Workspace:GetDescendants()) do
				if (o:IsA("Decal") or o:IsA("Texture")) and GfxOrigDecals[o] == nil then
					GfxOrigDecals[o] = o.Transparency
					o.Transparency = 1
				end
			end
		else
			for o, t in pairs(GfxOrigDecals) do
				if o and o.Parent then pcall(function() o.Transparency = t end) end
			end
			GfxOrigDecals = {}
		end
	end)
end
function setGfxBright(v)
	pcall(function()
		-- 100% = 无效果：直接销毁效果而不是留一个 Brightness=0 的 ColorCorrection 赖在 Lighting 里
		if v == 100 then
			if GfxFx then GfxFx:Destroy(); GfxFx = nil end
			return
		end
		if not GfxFx then
			GfxFx = Instance.new("ColorCorrectionEffect")
			GfxFx.Parent = gfxLight()
		end
		GfxFx.Brightness = (v - 100) / 200
	end)
end
function setGfxSat(v)
	pcall(function()
		if v == 100 then
			if GfxFx then GfxFx:Destroy(); GfxFx = nil end
			return
		end
		if not GfxFx then
			GfxFx = Instance.new("ColorCorrectionEffect")
			GfxFx.Parent = gfxLight()
		end
		GfxFx.Saturation = (v - 100) / 100
	end)
end

-- ---------- 一键提升帧率 · 降低卡顿（用户：「这两个做成一个功能，降低贴图什么的，反正能提升帧率就行」）----------
-- 全部走已有的 setGfxX 通道：自动记原值、同步开关 UI、写存档，「恢复默认画质」一键还原，
-- 绝不留下关不回去的效果。再加两个画质页没有的独立项：地形装饰（草/花，大地图掉帧大头）
-- 和渲染质量等级（客户端允许才生效，不允许就跳过，不报错）
function fpsBoost()
	local done = {}
	-- ① 阴影 / 粒子 / 贴花：复用已有通道
	setGfxShadows(true);   State.GfxShadow = true
	setGfxParticles(true); State.GfxParticle = true
	setGfxDecal(true);     State.GfxDecal = true
	table.insert(done, "阴影")
	table.insert(done, "粒子")
	table.insert(done, "贴图")
	-- ② 地形装饰（草 / 花 / 灌木）：中大型地图掉帧大头，且不挡战斗视线
	local terrain = Workspace:FindFirstChildOfClass("Terrain")
	if terrain then
		pcall(function()
			if GfxOrigTerrainDeco == nil then GfxOrigTerrainDeco = terrain.Decoration end
			terrain.Decoration = false
			table.insert(done, "地形装饰")
		end)
	end
	-- ③ 渲染质量等级：能设就设，设不了（执行器/客户端不允许）就跳过，不卡加载不报错
	pcall(function()
		local setfn = Settings or settings
		if type(setfn) == "function" then
			local st = setfn()
			if st and st.Rendering and Enum.QualityLevel and Enum.QualityLevel.Level01 then
				if GfxOrigQuality == nil then GfxOrigQuality = st.Rendering.QualityLevel end
				st.Rendering.QualityLevel = Enum.QualityLevel.Level01
				table.insert(done, "渲染质量")
			end
		end
	end)
	-- 同步 3 个画质开关的 UI（silent：不触发 onChange，状态已在上面直接置好）
	for _, t in ipairs(ToggleRegistry) do
		local ti = t._title
		if ti == "关闭阴影" or ti == "关闭粒子特效" or ti == "隐藏贴花/纹理" then
			pcall(function() t.Set(true, true) end)
		end
	end
	gfxSave()
	if notify then
		notify("帧率优化已应用：" .. table.concat(done, " · ") .. "（恢复默认画质可还原）")
	end
end

-- ---------- 夜视 / 环境（夜脚本源码完整搬入：普通夜视 / 超级夜视 / 彻底去雾）----------
GfxOrigLight, GfxOrigAtm = nil, {}
function gfxSet(k, v)
	pcall(function() gfxLight()[k] = v end)
end
function gfxSaveLight()
	if GfxOrigLight then return end
	local L = gfxLight()
	GfxOrigLight = {
		Brightness = L.Brightness, Ambient = L.Ambient, OutdoorAmbient = L.OutdoorAmbient,
		FogStart = L.FogStart, FogEnd = L.FogEnd, FogColor = L.FogColor,
		ClockTime = L.ClockTime, GlobalShadows = L.GlobalShadows,
		EnvironmentDiffuseScale = L.EnvironmentDiffuseScale or 1,
		EnvironmentSpecularScale = L.EnvironmentSpecularScale or 0,
		ColorShift_Top = L.ColorShift_Top, ColorShift_Bottom = L.ColorShift_Bottom,
		ExposureCompensation = L.ExposureCompensation,
	}
end
function gfxRestoreLight()
	if not GfxOrigLight then return end
	for k, v in pairs(GfxOrigLight) do gfxSet(k, v) end
end
-- 普通夜视（Brightness=10）
function setGfxNight(on)
	if on then
		gfxSaveLight()
		gfxSet("Brightness", 10)
		gfxSet("Ambient", Color3.fromRGB(220, 220, 220))
		gfxSet("OutdoorAmbient", Color3.fromRGB(220, 220, 220))
		gfxSet("EnvironmentDiffuseScale", 1)
		gfxSet("EnvironmentSpecularScale", 1)
		gfxSet("GlobalShadows", false)
		gfxSet("ClockTime", 8)
		gfxSet("ColorShift_Top", Color3.new(0, 0, 0))
		gfxSet("ColorShift_Bottom", Color3.new(0, 0, 0))
	else
		gfxRestoreLight()
	end
end
-- 超级夜视（Brightness=70，正午光感）
function setGfxSuperNight(on)
	if on then
		gfxSaveLight()
		gfxSet("Brightness", 70)
		gfxSet("Ambient", Color3.fromRGB(255, 255, 255))
		gfxSet("OutdoorAmbient", Color3.fromRGB(255, 255, 255))
		gfxSet("GlobalShadows", false)
		gfxSet("ClockTime", 12)
		gfxSet("FogEnd", 100000)
		gfxSet("EnvironmentDiffuseScale", 1)
	else
		gfxRestoreLight()
	end
end
-- 彻底去雾（Legacy Fog + Atmosphere 雾霾双清，关闭时双双还原）
function setGfxNoFog(on)
	local L = gfxLight()
	if on then
		gfxSaveLight()
		gfxSet("FogStart", 0)
		gfxSet("FogEnd", math.huge)
		gfxSet("FogColor", Color3.fromRGB(200, 200, 220))
		for _, obj in ipairs(L:GetChildren()) do
			if obj:IsA("Atmosphere") then
				if not GfxOrigAtm[obj] then
					GfxOrigAtm[obj] = { Density = obj.Density, Offset = obj.Offset, Glare = obj.Glare, Haze = obj.Haze }
				end
				pcall(function() obj.Density = 0; obj.Offset = 0; obj.Glare = 0; obj.Haze = 0 end)
			end
		end
	else
		local o = GfxOrigLight
		gfxSet("FogStart", o and o.FogStart or 0)
		gfxSet("FogEnd", o and o.FogEnd or 500)
		gfxSet("FogColor", o and o.FogColor or Color3.fromRGB(200, 200, 220))
		for obj, p in pairs(GfxOrigAtm) do
			if obj and obj.Parent then
				pcall(function()
					obj.Density = p.Density; obj.Offset = p.Offset; obj.Glare = p.Glare; obj.Haze = p.Haze
				end)
			end
		end
		GfxOrigAtm = {}
	end
end
-- 一键关闭所有夜视/去雾（同步三个开关的 UI 状态）
function gfxAllNightOff()
	State.GfxNight = false; State.GfxSuperNight = false; State.GfxNoFog = false
	setGfxNight(false); setGfxSuperNight(false); setGfxNoFog(false)
	for _, t in ipairs(ToggleRegistry) do
		if t._title == "普通夜视" or t._title == "超级夜视" or t._title == "彻底去雾" then
			pcall(function() t.Set(false, true) end)
		end
	end
end

-- 画质存档（本地文件 + 跨服务器双保险）：4 个关闭类开关 + 亮度/饱和度 + 3 个夜视类开关。
-- 修「画质必须每次启动都开启，不开就出 bug」：设置现在自动记忆，且退出脚本时彻底清理特效残留
GFX_FILE = "HonSpeedHub_Gfx.json"
function gfxSave()
	local d = {
		sh = State.GfxShadow, fo = State.GfxFog, pa = State.GfxParticle, de = State.GfxDecal,
		br = GfxBrightSlider and GfxBrightSlider.GetValue() or 100,
		sa = GfxSatSlider and GfxSatSlider.GetValue() or 100,
		ni = State.GfxNight, sn = State.GfxSuperNight, nf = State.GfxNoFog,
	}
	local ok, json = pcall(function() return HttpService:JSONEncode(d) end)
	if not ok or not json then return end
	pcall(function() if writefile then writefile(GFX_FILE, json) end end)
	pcall(function() TeleportService:SetTeleportSetting("HON_GFX", json) end)
end
function gfxLoad()
	local d = nil
	pcall(function()
		if isfile and readfile and isfile(GFX_FILE) then
			local ok, x = pcall(function() return HttpService:JSONDecode(readfile(GFX_FILE)) end)
			if ok and type(x) == "table" then d = x end
		end
	end)
	if not d then
		pcall(function()
			local raw = TeleportService:GetTeleportSetting("HON_GFX")
			if raw and raw ~= "" then
				local ok, x = pcall(function() return HttpService:JSONDecode(raw) end)
				if ok and type(x) == "table" then d = x end
			end
		end)
	end
	if not d then return end
	local function bool(v) return v == true end
	State.GfxShadow, State.GfxFog = bool(d.sh), bool(d.fo)
	State.GfxParticle, State.GfxDecal = bool(d.pa), bool(d.de)
	State.GfxNight, State.GfxSuperNight, State.GfxNoFog = bool(d.ni), bool(d.sn), bool(d.nf)
	local br, sa = 100, 100
	if type(d.br) == "number" then br = math.clamp(math.floor(d.br), 0, 200) end
	if type(d.sa) == "number" then sa = math.clamp(math.floor(d.sa), 0, 200) end
	-- 同步开关 UI（silent，不重复触发 onChange）
	for _, t in ipairs(ToggleRegistry) do
		local ti = t._title
		if ti == "关闭阴影" then pcall(function() t.Set(State.GfxShadow, true) end)
		elseif ti == "关闭雾气" then pcall(function() t.Set(State.GfxFog, true) end)
		elseif ti == "关闭粒子特效" then pcall(function() t.Set(State.GfxParticle, true) end)
		elseif ti == "隐藏贴花/纹理" then pcall(function() t.Set(State.GfxDecal, true) end)
		elseif ti == "普通夜视" then pcall(function() t.Set(State.GfxNight, true) end)
		elseif ti == "超级夜视" then pcall(function() t.Set(State.GfxSuperNight, true) end)
		elseif ti == "彻底去雾" then pcall(function() t.Set(State.GfxNoFog, true) end)
		end
	end
	if GfxBrightSlider then pcall(function() GfxBrightSlider.Set(br) end) end
	if GfxSatSlider then pcall(function() GfxSatSlider.Set(sa) end) end
	-- 应用到游戏（夜视三个互斥显示上按存档原样套，冲突时以最后一个为准）
	pcall(setGfxShadows, State.GfxShadow)
	pcall(setGfxFog, State.GfxFog)
	pcall(setGfxParticles, State.GfxParticle)
	pcall(setGfxDecal, State.GfxDecal)
	pcall(setGfxBright, br)
	pcall(setGfxSat, sa)
	if State.GfxNight then pcall(setGfxNight, true) end
	if State.GfxSuperNight then pcall(setGfxSuperNight, true) end
	if State.GfxNoFog then pcall(setGfxNoFog, true) end
end

label({ Text = "画 质 修 改 GRAPHICS", Font = Enum.Font.GothamBold, TextSize = 11,
	TextColor3 = Color3.fromRGB(120, 129, 152), Size = UDim2.new(1, 0, 0, 18),
	Position = UDim2.new(0, 2, 0, 0), TextXAlignment = Enum.TextXAlignment.Left }, PageGfx)
makeToggle(PageGfx, 24,  "关闭阴影", "关掉全局阴影，帧数明显提升", false, function(v) State.GfxShadow = v; setGfxShadows(v); gfxSave() end)
makeToggle(PageGfx, 72,  "关闭雾气", "视野更清楚", false, function(v) State.GfxFog = v; setGfxFog(v); gfxSave() end)
makeToggle(PageGfx, 120, "关闭粒子特效", "烟/火/拖尾/光束全关", false, function(v) State.GfxParticle = v; setGfxParticles(v); gfxSave() end)
makeToggle(PageGfx, 168, "隐藏贴花/纹理", "墙面图案去掉，更干净", false, function(v) State.GfxDecal = v; setGfxDecal(v); gfxSave() end)
GfxBrightSlider = makeSlider(PageGfx, "亮度", 226, 0, 200, 100, " %", function(v) setGfxBright(v); gfxSave() end, false)
GfxSatSlider = makeSlider(PageGfx, "饱和度", 282, 0, 200, 100, " %", function(v) setGfxSat(v); gfxSave() end, false)
label({ Text = "夜 视 与 环 境 NIGHT VISION", Font = Enum.Font.GothamBold, TextSize = 11,
	TextColor3 = Color3.fromRGB(120, 129, 152), Size = UDim2.new(1, 0, 0, 18),
	Position = UDim2.new(0, 2, 0, 330), TextXAlignment = Enum.TextXAlignment.Left }, PageGfx)
makeToggle(PageGfx, 354, "普通夜视", "夜里全亮 · 阴影全关", false, function(v) State.GfxNight = v; setGfxNight(v); gfxSave() end)
makeToggle(PageGfx, 402, "超级夜视", "超高亮度 · 正午光感", false, function(v) State.GfxSuperNight = v; setGfxSuperNight(v); gfxSave() end)
makeToggle(PageGfx, 450, "彻底去雾", "连 Atmosphere 雾霾一起清", false, function(v) State.GfxNoFog = v; setGfxNoFog(v); gfxSave() end)
local GfxNightOffBtn = new("TextButton", { Text = "关闭所有夜视/去雾", Font = Enum.Font.GothamBold, TextSize = 11,
	TextColor3 = Color3.fromRGB(255, 190, 120), BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	BackgroundTransparency = 0.9, BorderSizePixel = 0, AutoButtonColor = false,
	Size = UDim2.new(1, 0, 0, 34), Position = UDim2.new(0, 0, 0, 498), Parent = PageGfx })
corner(GfxNightOffBtn, 8)
table.insert(FunBtns, GfxNightOffBtn)
bindClick(GfxNightOffBtn, "关闭夜视", function()
	gfxAllNightOff()
	if notify then notify("夜视/去雾已全部关闭") end
end)
local GfxResetBtn = new("TextButton", { Text = "恢复默认画质", Font = Enum.Font.GothamBold, TextSize = 11,
	TextColor3 = Color3.fromRGB(150, 220, 255), BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	BackgroundTransparency = 0.9, BorderSizePixel = 0, AutoButtonColor = false,
	Size = UDim2.new(1, 0, 0, 34), Position = UDim2.new(0, 0, 0, 546), Parent = PageGfx })
corner(GfxResetBtn, 8)
table.insert(FunBtns, GfxResetBtn)
-- 恢复默认画质：自制 UI 按钮与 WindUI 按钮共用（含一键提升帧率动过的地形装饰 / 渲染质量）
function gfxReset()
	-- State 必须显式归 false：setGfxX 只动游戏画面，不碰 State——
	-- 少了这四行，恢复默认后存的档还是「开着」的状态，下次启动又给关回去了
	State.GfxShadow, State.GfxFog, State.GfxParticle, State.GfxDecal = false, false, false, false
	setGfxShadows(false); setGfxFog(false); setGfxParticles(false); setGfxDecal(false)
	setGfxBright(100); setGfxSat(100)
	gfxAllNightOff()
	-- 一键提升帧率动过的两项也还原：地形装饰 + 渲染质量
	if GfxOrigTerrainDeco ~= nil then
		pcall(function()
			local terrain = Workspace:FindFirstChildOfClass("Terrain")
			if terrain then terrain.Decoration = GfxOrigTerrainDeco end
		end)
	end
	if GfxOrigQuality ~= nil then
		pcall(function()
			local setfn = Settings or settings
			if type(setfn) == "function" then
				local st = setfn()
				if st and st.Rendering then st.Rendering.QualityLevel = GfxOrigQuality end
			end
		end)
	end
	-- 同步 4 个画质开关 + 2 个滑条的 UI（silent）
	for _, t in ipairs(ToggleRegistry) do
		local ti = t._title
		if ti == "关闭阴影" or ti == "关闭雾气" or ti == "关闭粒子特效" or ti == "隐藏贴花/纹理" then
			pcall(function() t.Set(false, true) end)
		end
	end
	if GfxBrightSlider then pcall(function() GfxBrightSlider.Set(100) end) end
	if GfxSatSlider then pcall(function() GfxSatSlider.Set(100) end) end
	gfxSave()
	if notify then notify("画质已恢复默认（已存档）") end
end
bindClick(GfxResetBtn, "恢复画质", function() gfxReset() end)
-- 一键提升帧率 · 降低卡顿：用户要求「这两个做成一个功能，反正能提升帧率就行」——
-- 阴影 / 粒子 / 贴图全关 + 地形装饰关 + 渲染质量压到最低，全部可被「恢复默认画质」还原
local GfxBoostBtn = new("TextButton", { Text = "一键提升帧率 · 降低卡顿", Font = Enum.Font.GothamBold, TextSize = 11,
	TextColor3 = Color3.fromRGB(140, 255, 170), BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	BackgroundTransparency = 0.9, BorderSizePixel = 0, AutoButtonColor = false,
	Size = UDim2.new(1, 0, 0, 34), Position = UDim2.new(0, 0, 0, 594), Parent = PageGfx })
corner(GfxBoostBtn, 8)
table.insert(FunBtns, GfxBoostBtn)
bindClick(GfxBoostBtn, "提升帧率", function() fpsBoost() end)

-- ---------- 雷达 ----------
-- 模式1 = 2D 全显（人 + NPC + 建筑 + 可互动物 + 自己）；模式2 = 仅人物 / NPC
-- v5.44 起改成「朝向朝上 heading-up」：自己永远是中心一个点 + 前方小三角（三角指的就是当前朝向），
-- 敌人 / NPC / 建筑按自己朝向反向旋转绕着自己转（用户：「让人物跟着我转，而不是让我转」）。
-- 屏幕右上角创建，动态避开右上角功能列表 TopBarFrame
RadarFrame, RadarSelf, RadarSelfTri, RadarSweep, RadarSweepAng = nil, nil, nil, nil, 0
-- 朝向朝上（heading-up）用的自己水平朝向：cosH = -Look.Z, sinH = Look.X（归一化）。
-- 世界偏移按它反向旋转后映射到屏幕——自己永远是中心一个点 + 前方小三角，
-- 敌人 / NPC / 建筑绕着自己转（用户：「让人物转，而不是让我转」）
RadarCosH, RadarSinH = 1, 0
RadarDots, RadarWalls, RadarMode, RadarTimer, RadarNpcCache = {}, {}, 1, 0, {}
function buildRadar()
	if RadarFrame then return end
	-- 初始位置在右上角，精确避让 TopBar 在 updateRadar 里每帧计算
	RadarFrame = new("Frame", { Name = "HonRadar", Size = UDim2.new(0, 168, 0, 168),
		Position = UDim2.new(1, -184, 0, 8), BackgroundColor3 = Color3.fromRGB(10, 14, 20),
		BackgroundTransparency = 0.35, BorderSizePixel = 0, Visible = false,
		ClipsDescendants = true, Parent = Gui })
	corner(RadarFrame, 84)
	new("UIStroke", { Color = Mode().Accent, Transparency = 0.6, Thickness = 1.5, Parent = RadarFrame })
	-- 十字线
	new("Frame", { Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 0.5, 0),
		BackgroundColor3 = Mode().Accent, BackgroundTransparency = 0.75, BorderSizePixel = 0, Parent = RadarFrame })
	new("Frame", { Size = UDim2.new(0, 1, 1, 0), Position = UDim2.new(0.5, 0, 0, 0),
		BackgroundColor3 = Mode().Accent, BackgroundTransparency = 0.75, BorderSizePixel = 0, Parent = RadarFrame })
	-- 半程刻度圈（110 studs = 半径一半）
	local ring = new("Frame", { Size = UDim2.new(0, 78, 0, 78), AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0), BackgroundTransparency = 1, BorderSizePixel = 0, Parent = RadarFrame })
	corner(ring, 39)
	new("UIStroke", { Color = Mode().Accent, Transparency = 0.85, Thickness = 1, Parent = ring })
	-- 旋转扫描线：直径线 + 两端渐隐。
	-- 旧版是 1×78 底边贴中心的「木棍」——Frame.Rotation 绕自身几何中心旋转，
	-- 底端点会绕偏心点公转，看起来就是一根棍子在乱晃。直径线绕真正的中心转，稳定
	RadarSweep = new("Frame", { Size = UDim2.new(0, 2, 0, 156), AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0), BackgroundColor3 = Mode().Accent,
		BackgroundTransparency = 0.35, BorderSizePixel = 0, Parent = RadarFrame })
	new("UIGradient", {
		Rotation = 90,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.92),
			NumberSequenceKeypoint.new(0.5, 0.3),
			NumberSequenceKeypoint.new(1, 0.92),
		}),
		Parent = RadarSweep })
	-- 自己：中心圆点（固定不动，天旋地转它也在正中心）
	RadarSelf = new("Frame", { Size = UDim2.new(0, 8, 0, 8), AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0), BackgroundColor3 = Color3.fromRGB(120, 255, 160),
		BorderSizePixel = 0, Parent = RadarFrame })
	corner(RadarSelf, 4)
	-- 自己前方小三角：标记「我脸朝向哪边」。朝向朝上模式下世界绕自己转，
	-- 正上方就是当前朝向，所以三角是静态的（不用每帧算位置/ Rotation）
	RadarSelfTri = new("TextLabel", { Text = "▲", Font = Enum.Font.GothamBold, TextSize = 10,
		TextColor3 = Color3.fromRGB(120, 255, 160), BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 0.5, -5),
		Size = UDim2.new(0, 14, 0, 13), TextYAlignment = Enum.TextYAlignment.Bottom,
		Parent = RadarFrame })
end
function updateRadar(dt)
	if not State.Radar then if RadarFrame then RadarFrame.Visible = false end return end
	buildRadar()
	RadarFrame.Visible = true
	-- 右上角定位：避开功能列表 TopBarFrame（它此时若可见就占 8 + 高度）
	local tbH = 0
	if TopBarFrame and TopBarFrame.Visible then tbH = TopBarFrame.Size.Y.Offset end
	RadarFrame.Position = UDim2.new(1, -184, 0, 8 + tbH + 6)
	-- 扫描线旋转
	RadarSweepAng = (RadarSweepAng or 0) + (dt or 0) * 110
	if RadarSweepAng > 360 then RadarSweepAng = RadarSweepAng - 360 end
	if RadarSweep then RadarSweep.Rotation = RadarSweepAng end
	if not (HRP and HRP.Parent) then return end
	RadarTimer = (RadarTimer or 0) + (dt or 0)
	if RadarTimer > 0.9 then
		RadarTimer = 0
		RadarNpcCache = {}
		pcall(function()
			local n, seen = 0, {}
			for _, o in ipairs(Workspace:GetDescendants()) do
				if n >= 60 then break end
				-- NPC：带 Humanoid 的 Model 且不是玩家角色
				if o:IsA("Model") and o:FindFirstChildOfClass("Humanoid")
					and not Players:GetPlayerFromCharacter(o) then
					local hr = o:FindFirstChild("HumanoidRootPart") or o:FindFirstChildWhichIsA("BasePart")
					if hr and not seen[o] then
						seen[o] = true
						table.insert(RadarNpcCache, { P = hr, C = Color3.fromRGB(255, 200, 90) })
						n = n + 1
					end
				end
			if RadarMode == 1 then
				-- 可互动物：带 ProximityPrompt / ClickDetector 的 BasePart
				local hasPrompt = o:FindFirstChildOfClass("ProximityPrompt") or o:FindFirstChildOfClass("ClickDetector")
				local part = o:IsA("BasePart") and o or nil
				if hasPrompt and part and not seen[o] then
					seen[o] = true
					table.insert(RadarNpcCache, { P = part, C = Color3.fromRGB(120, 200, 255) })
					n = n + 1
				end
				-- 墙壁：大块 BasePart（任一边 ≥ 12 studs）画成「长边中轴线」线段——
				-- 墙延伸到哪里线画到哪里，墙由多个 Part 拼成（L 形 / 拐弯）时线段自然接成折线
				if o:IsA("BasePart") and not seen[o] then
					local s = o.Size
					if s and (s.X >= 12 or s.Y >= 12 or s.Z >= 12) then
						seen[o] = true
						local cf = o.CFrame
						local wv, ln
						if s.X >= s.Z then wv, ln = cf.RightVector, s.X else wv, ln = -cf.LookVector, s.Z end
						-- 世界水平方向 → 雷达屏幕方向（屏幕 X = 世界 X，屏幕 Y = -世界 Z）
						local dx, dy = wv.X, -wv.Z
						local m = math.sqrt(dx * dx + dy * dy)
						if m > 0.001 then
							table.insert(RadarNpcCache, {
								P = o, C = Color3.fromRGB(150, 168, 196), W = true,
								DX = dx / m, DY = dy / m, Len = math.min(ln, 130),
							})
							n = n + 1
						end
					end
				end
			end
			end
		end)
	end
	local pts = {}
	for _, pl in ipairs(Players:GetPlayers()) do
		if pl ~= LP and pl.Character then
			local hr = pl.Character:FindFirstChild("HumanoidRootPart")
			if hr then table.insert(pts, { P = hr, C = Color3.fromRGB(255, 110, 110) }) end
		end
	end
	for _, q in ipairs(RadarNpcCache) do table.insert(pts, q) end
	local RANGE, RR = 220, 78
	local myPos = HRP.Position
	local myLook = HRP.CFrame.LookVector
	-- 朝向朝上：先拿到自己水平朝向（cosH = -Z, sinH = X）。正上/正下看时水平分量为 0，
	-- 保持上一帧的朝向不跳变；从来没拿到过就默认世界 -Z 朝上（和老版世界固定一致）
	local lx, lz = myLook.X, myLook.Z
	local lm = math.sqrt(lx * lx + lz * lz)
	if lm > 0.001 then RadarCosH, RadarSinH = -lz / lm, lx / lm end
	local cosH, sinH = RadarCosH, RadarSinH
	local nDot, nWall = 0, 0
	for i, it in ipairs(pts) do
		local d = it.P.Position - myPos
		local dist = math.sqrt(d.X * d.X + d.Z * d.Z)
		-- 世界偏移按自己朝向反向旋转：正前方的目标永远出现在屏幕正上方，
		-- 右边的目标出现在屏幕右方——敌人 / NPC / 建筑绕着自己转，自己不动
		local rx = d.X * cosH + d.Z * sinH
		local ry = -d.X * sinH + d.Z * cosH
		local k = math.min(dist / RANGE, 1) * RR
		local px = (dist > 0.001) and (rx / dist * k) or 0
		local py = (dist > 0.001) and (ry / dist * k) or 0
		if it.W then
			-- 墙壁线段：方向同样按朝向旋转，AnchorPoint 贴中点，粗细 2px
			nWall = nWall + 1
			local seg = RadarWalls[nWall]
			if not seg then
				seg = new("Frame", { Size = UDim2.new(0, 10, 0, 2), AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundColor3 = it.C, BackgroundTransparency = 0.15,
					BorderSizePixel = 0, Parent = RadarFrame })
				RadarWalls[nWall] = seg
			end
			seg.Visible = true
			seg.BackgroundColor3 = it.C
			seg.Size = UDim2.new(0, it.Len, 0, 2)
			seg.Position = UDim2.new(0.5, px, 0.5, py)
			local wdx = it.DX * cosH + it.DY * sinH
			local wdy = -it.DX * sinH + it.DY * cosH
			seg.Rotation = math.deg(math.atan2(wdy, wdx))
		else
			nDot = nDot + 1
			local dot = RadarDots[nDot]
			if not dot then
				dot = new("Frame", { Size = UDim2.new(0, 5, 0, 5), AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundColor3 = it.C, BorderSizePixel = 0, Parent = RadarFrame })
				corner(dot, 2.5)
				RadarDots[nDot] = dot
			end
			dot.Visible = true
			dot.BackgroundColor3 = it.C
			dot.Position = UDim2.new(0.5, px, 0.5, py)
		end
	end
	for i = nDot + 1, #RadarDots do RadarDots[i].Visible = false end
	for i = nWall + 1, #RadarWalls do RadarWalls[i].Visible = false end
end

function notify(msg, col)
	if not msg then return end
	-- v5.47 提示收权：右上角只留给「功能列表显示」，日常确认（无色）一律不弹；
	-- 警告/错误必须显式带色才会显示（统一橙 Color3.fromRGB(255,176,32)）
	if not col then return end
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
	for _, list in ipairs({ ToolBtns, FunBtns, MoreBtns, UtilBtns, UiBtns, ToyBtns }) do
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
StealthWin, StealthRecText = nil, nil
StealthOwn, StealthHiddenGui = {}, {}
stealthTime, stealthAcc = 0, 0
-- v5.58：隐身小窗（右上角）——开启隐身即在右上角弹出，固定不最小化；关闭隐身即收起。
-- 命名 HonStealth：stealthHideOwn 只藏 Gui 下非 HonStealth 的子级，本窗作为「录制指示器」
-- 在隐身期间保持可见（与旧版 REC 悬浮钮同一个豁免名，行为一致）。
function buildStealthWin()
	if StealthWin then return end
	local w = new("Frame", { Name = "HonStealth", Size = UDim2.new(0, 224, 0, 132),
		Position = UDim2.new(1, -244, 0, 320),
		BackgroundColor3 = Color3.fromRGB(13, 15, 23), BackgroundTransparency = 0.06,
		BorderSizePixel = 0, Visible = false, Active = true, Parent = Gui })
	corner(w, 16)
	new("UIStroke", { Color = Color3.fromRGB(255, 86, 96), Transparency = 0.5, Thickness = 1, Parent = w })
	local bar = new("Frame", { Size = UDim2.new(1, 0, 0, 38), BackgroundTransparency = 1, Parent = w })
	label({ Text = "STEALTH", Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = Color3.fromRGB(238, 243, 255),
		Position = UDim2.new(0, 16, 0, 9), Size = UDim2.new(0, 130, 0, 20), TextXAlignment = Enum.TextXAlignment.Left }, bar)
	local dot = new("Frame", { Size = UDim2.new(0, 10, 0, 10), Position = UDim2.new(1, -66, 0.5, -5),
		BackgroundColor3 = Color3.fromRGB(255, 86, 96), BorderSizePixel = 0, Parent = bar })
	corner(dot, 5)
	local close = new("TextButton", { Text = "×", Font = Enum.Font.GothamBold, TextSize = 16,
		TextColor3 = Color3.fromRGB(255, 108, 118), BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.94, BorderSizePixel = 0, AutoButtonColor = false,
		Position = UDim2.new(1, -36, 0, 7), Size = UDim2.new(0, 26, 0, 26), Parent = bar })
	corner(close, 8)
	-- ×：关掉隐身，窗随隐身一起收起
	close.MouseButton1Click:Connect(function() setStealth(false) end)
	-- 内部「开关隐身」：注册进 ToggleRegistry 后立刻移出，避免被「隐身冻结 / 全部关闭」误伤
	local StToggle = makeToggle(w, 48, "开关隐身", "关闭即收起本窗", false, function(v) setStealth(v) end)
	for i = #ToggleRegistry, 1, -1 do
		if ToggleRegistry[i] == StToggle then table.remove(ToggleRegistry, i) break end
	end
	StealthRecText = label({ Text = "REC 00:00", Font = Enum.Font.GothamBold, TextSize = 13,
		TextColor3 = Color3.fromRGB(255, 120, 130), Position = UDim2.new(0, 16, 0, 90),
		Size = UDim2.new(1, -32, 0, 22), TextXAlignment = Enum.TextXAlignment.Left }, w)
	label({ Text = "隐藏界面 · 暂停其他功能（加速保留）", Font = Enum.Font.Gotham, TextSize = 10,
		TextColor3 = Color3.fromRGB(132, 141, 163), Position = UDim2.new(0, 16, 0, 112),
		Size = UDim2.new(1, -32, 0, 18), TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top }, w)
	StealthWin = w
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
-- ---------- 隐身录屏：开启后冻结除「加速」外的全部功能，关闭后原样恢复 ----------
-- 加速 = 启用引擎（让角色真正跑快）+ 加速小窗 SPEED WIN（调速面板）；隐身录屏开关本身
-- 也必须在白名单里，否则隐身开着时关不掉它。其余（ESP / 飞行 / 穿墙 / 防布娃娃 /
-- 启动动画 / 背景图 …）一律冻结，关闭隐身后逐个原样恢复。注意这里不走 _keep 标志——
-- _keep 同时还管着「全部关闭」按钮，不能为了隐身把设置类开关（边框 / 背景图等）从
-- 全部关闭里排除掉，所以隐身冻结单独用一份白名单。
StealthFrozen = nil
local STEALTH_KEEP = {
	["启用引擎"] = true,
	["加速小窗 SPEED WIN"] = true,
	["隐身录屏 STEALTH"] = true,
}
function stealthFreeze()
	if StealthFrozen then return end
	StealthFrozen = {}
	for _, t in ipairs(ToggleRegistry) do
		if t._last and not STEALTH_KEEP[t._title] then
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
	buildStealthWin()
	if on then
		local n = stealthFreeze()
		stealthHideOwn()
		-- 开隐身自动清身上方块（v5.45，用户：「开启隐身之后自动清除」）——
		-- 录屏的时候角色光溜的，不戴帽子不挂配件
		pcall(hideBodyBlocks, true)
		if StealthWin then StealthWin.Visible = true end
		stealthTime, stealthAcc = 0, 0
		if notify then notify("隐身录屏开启 · 已暂停 " .. n .. " 个功能（仅加速保持运行）") end
	else
		local n = stealthRestore()
		stealthShowOwn()
		if StealthWin then StealthWin.Visible = false end
		if notify then notify("已恢复界面 · 并恢复 " .. n .. " 个功能") end
	end
	if StealthTgl then StealthTgl.Set(on, true) end
end
RunService.Heartbeat:Connect(function(dt)
	if HON_SHUTDOWN then return end
	if not State.Stealth then stealthAcc = 0; return end
	stealthTime = stealthTime + dt
	stealthAcc = stealthAcc + dt
	if stealthAcc >= 0.5 then
		stealthAcc = 0
		if StealthRecText then
			StealthRecText.Text = string.format("REC %02d:%02d",
				math.floor(stealthTime / 60), math.floor(stealthTime % 60))
		end
	end
end)
-- ---------- 新功能的每帧驱动（黑洞 / 变车 / 防摔落 / HUD 附加信息）----------
pcall(function() RunService:UnbindFromRenderStep("HonFunLoop") end)
RunService:BindToRenderStep("HonFunLoop", 9995, function(dt)
	if HON_SHUTDOWN then return end
	if State.BlackHole and HoleCore and HoleCore.Parent then
		local c = HoleCore.Position
		local f = State.BlackHoleForce or 60
		for _, pl in ipairs(Players:GetPlayers()) do
			if pl ~= LP then
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
			local base = HRP.CFrame * CFrame.new(0, 0, 0.3)
			local tm = tick()
			for _, w in ipairs(WingParts) do
				-- 波浪式扇动：内侧先动、外侧跟上，层间再错开一点相位
				local ph = w.F * 1.15 + w.Layer * 0.22
				local flap = math.sin(tm * 1.7 - ph) * 0.2 * (0.35 + w.F)
				local lift = math.sin(tm * 1.7 - ph) * 0.12 * (1 - w.F * 0.5)
				local cf = base * w.Off
					* CFrame.Angles(0, 0, w.Side * flap)
					* CFrame.new(0, lift, 0)
				w.P.CFrame = cf
				local k = WingSizeV or 1
				w.P.Size = Vector3.new(w.W * 0.2 * k, w.L * k, w.W * k)
			end
		end)
	end
	-- 三个新趣味功能的每帧驱动
	if State.PlayDead and Humanoid and Humanoid.Parent then
		Humanoid.PlatformStand = true
	end
	if State.NeonGlow then
		-- 重生重挂：旧备份里的部件已销毁（换角色）就重建备份
		if NeonBackup then
			local alive = false
			for p, _ in pairs(NeonBackup) do
				if p and p.Parent then alive = true break end
			end
			if not alive then NeonBackup = nil; pcall(setNeonGlow, true) end
		end
		if NeonBackup then
			NeonHue = ((NeonHue or 0) + dt * 0.15) % 1
			local col = hsv2rgb(NeonHue, 0.85, 1)
			for p, _ in pairs(NeonBackup) do
				if p and p.Parent then p.Material = Enum.Material.Neon; p.Color = col end
			end
		end
	end
	pcall(toyFrame, dt)
	pcall(cdTick, dt)
	pcall(updateRadar, dt)
	TopBarTimer = (TopBarTimer or 0) + dt
	if TopBarTimer > 0.35 then
		TopBarTimer = 0
		pcall(updateTopBar)
	end
	opBarDone = true
	if State.AntiRagdoll and Humanoid and Humanoid.Parent then
		pcall(function()
			if Humanoid:GetState() == Enum.HumanoidStateType.Ragdoll
				or Humanoid:GetState() == Enum.HumanoidStateType.FallingDown then
				Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
			end
			Humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
			Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
		end)
	end
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
					local tx = HRP.Position + Vector3.new(math.cos(a) * 6.5, 0, math.sin(a) * 6.5)
					-- 贴地：向下打一条射线找到地面高度，这样分身能跟着上楼梯/坡道
					local gy = tx.Y
					pcall(function()
						local rp = RaycastParams.new()
						rp.FilterDescendantsInstances = { cl }
						rp.FilterType = Enum.RaycastFilterType.Blacklist
						local hit = Workspace:Raycast(Vector3.new(tx.X, tx.Y + 12, tx.Z), Vector3.new(0, -40, 0), rp)
						if hit then gy = hit.Position.Y end
					end)
					cr.CFrame = CFrame.new(tx.X, gy + 2.6, tx.Z) * CFrame.Angles(0, -a, 0)
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
	if not ok then _pr("[HON] 初始化步骤失败: " .. name .. " -> " .. tostring(err)) end
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
-- 恢复 UI 偏好（字体/面板缩放）：playOpenAnim 之前应用缩放，
-- 保证「缩放弹出」动画的起点就是恢复后的比例
pcall(function()
	-- 字体默认最大：用户要求「默认拉到最大」，无存档时也应用 1.6，有存档按存档
	applyFontScale(PrefFontScale or 1.6)
	if PrefPanelScale and MainScale then MainScale.Scale = PrefPanelScale end
end)
-- 恢复画质设置（关阴影/雾气/粒子/贴花 + 亮度/饱和度 + 夜视类）：改一次就记住，不用每次启动重开
if type(gfxLoad) == "function" then pcall(gfxLoad) end
-- 边框初始应用（静默）：开关/样式来自 prefLoad 读到的存档，主题色边框立即生效
if BorderTgl and BorderTgl.Set then BorderTgl.Set(BorderOn, true) end
if BorderModeBtn then BorderModeBtn.Text = "边框样式：" .. BORDER_STYLES[BorderMode] .. "  ▾" end
pcall(setBorder, BorderOn, true)
if paintFwBtns then paintFwBtns() end
-- 界面框架恢复：上次用的 WindUI 就自动切回去。加载/构建任何一步失败都会在
-- setUiFramework 里自动回退自制 UI，不会给用户留白屏
if PrefFramework == 2 then
	task.defer(function() pcall(setUiFramework, 2) end)
end
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
do
	local downY, downX = nil, nil
	TabBar.InputBegan:Connect(function(i)
		if i.UserInputType ~= Enum.UserInputType.Touch and i.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
		downY, downX = i.Position.Y, i.Position.X
	end)
	TabBar.InputEnded:Connect(function(i)
		if i.UserInputType ~= Enum.UserInputType.Touch and i.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
		if not downY then return end
		local moved = math.abs(i.Position.Y - downY) + math.abs(i.Position.X - (downX or 0))
		downY = nil
		if moved > 12 then return end   -- 滑动了就不切页，只滚动
		local rel = i.Position - TabBar.AbsolutePosition + TabBar.CanvasPosition
		if rel.X < 0 or rel.X > TabBar.AbsoluteSize.X then return end
		local idx = math.floor((rel.Y - 10) / 44) + 1
		if idx >= 1 and idx <= #TabBtns then pcall(SetTab, idx) end
	end)
end
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
if OrigMainSize then Main.Size = OrigMainSize end
Main.BackgroundTransparency = 0.05
-- 看门狗：万一开场/关闭动画出错导致界面消失，这里兜底把它找回来
tspawn(function()
	twait(5)
	if Main and not Main.Visible and Mini and not Mini.Visible then
		pcall(function()
			Main.Visible = true
			Main.Rotation = 0
			if OrigMainSize then Main.Size = OrigMainSize end
			Main.BackgroundTransparency = 0.05
			if MainScale then MainScale.Scale = PrefPanelScale or 1 end
		end)
	end
end)
_pr("[HON SPEED HUB] v5.58 已加载 · 完整文件约 7933 行 · 若你的脚本远大于此行数说明粘贴重复了")


