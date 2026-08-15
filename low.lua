-- BUILD: v40.1\\\ Routine Automation FIX
--[[
	Grow A Chicken Fighter
	Graphite IDE UI - Single File Library

	Features
	- Reusable internal UI library
	- Window / Tabs / Sections
	- Toggle component
	- Dropdown component
	- Status component
	- Smooth draggable window
	- Compact minimize
	- Close button
	- Auto Open Egg
	- Auto Collect Egg
	- Auto Pet Chicken with CPS slider
	- Auto Rebirth
	- Auto Tower
	- Automation cycle with dynamic Rebirth floor detection
	- Utilities: flat single-action controls
	- ALL / Selected mode
	- feed / barn / storm / crown

	Place as ONE LocalScript:
	StarterPlayer > StarterPlayerScripts > MainUI
]]

--========================================================
-- SERVICES
--========================================================

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

--========================================================
-- REMOTE / GAME CONFIG
--========================================================

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local HatchEgg = Remotes:WaitForChild("HatchEgg")
local PetChicken = Remotes:WaitForChild("PetChicken")
local Rebirth = Remotes:WaitForChild("Rebirth")
local BuyGenerator = Remotes:WaitForChild("BuyGenerator")
local UpgradeGenerator = Remotes:WaitForChild("UpgradeGenerator")
local ExpandCoop = Remotes:FindFirstChild("ExpandCoop")
	or game:FindFirstChild("ExpandCoop", true)

local TowerStart = Remotes:WaitForChild("TowerStart")
local TowerElevator = Remotes:WaitForChild("TowerElevator")
local TowerSurrender = Remotes:WaitForChild("TowerSurrender")
local TowerContinueDecline = Remotes:WaitForChild("TowerContinueDecline")

local EGG_TYPES = {
	"feed",
	"barn",
	"storm",
	"crown",
}

local AUTO_EGG_DELAY = 0.225
local APP_VERSION = "v2.3.6"

local THEME_NAMES = {
	"Monochrome",
	"Graphite",
	"Midnight",
	"Forest",
	"Rose",
}

--========================================================
-- AUTO SAVE CONFIG
--========================================================

local CONFIG_FILE = "GrowAChickenFighter_Config.json"

local Config = {
	AutoOpenEnabled = false,
	AutoOpenMode = "ALL",
	SelectedEgg = "feed",
	AutoCollectEnabled = false,
	AutoPetEnabled = false,
	AutoPetCPS = 2,
	AutoRebirthEnabled = false,
	AutoBuyFeederEnabled = false,
	AutoUpgradeFeederCPS = 5,
	AutoBuyFeederLevel = 1,

	-- Separate keys: existing AutoBuyFeederEnabled belongs to
	-- the Auto Upgrade Feeder feature for config compatibility.
	AutoPurchaseFeederEnabled = false,
	AutoPurchaseFeederTarget = 1, -- legacy / unused
	AutoExpandCoopEnabled = false,

	AutoTowerEnabled = false,
	AutoTowerStartChoice = "Priority FRONTIER",
	AutoTowerSurrenderEnabled = false,
	AutoTowerSurrenderFloor = 60,
	AutoTowerNoThanksEnabled = false,

	AutomationEnabled = false,
	AutomationTowerDelay = 5,

	GodMode = false,
	NoClip = false,
	AntiAFK = false,

	WalkSpeed = 16,
	WalkSpeedOverride = false,

	Theme = "Monochrome",
}

local configRevision = 0

local function canUseFileSystem()
	return typeof(isfile) == "function"
		and typeof(readfile) == "function"
		and typeof(writefile) == "function"
end

local function sanitizeConfig(data)
	if type(data) ~= "table" then
		return
	end

	if type(data.AutoOpenEnabled) == "boolean" then
		Config.AutoOpenEnabled = data.AutoOpenEnabled
	end

	if data.AutoOpenMode == "ALL"
		or data.AutoOpenMode == "Selected" then

		Config.AutoOpenMode = data.AutoOpenMode
	end

	if type(data.SelectedEgg) == "string"
		and table.find(EGG_TYPES, data.SelectedEgg) then

		Config.SelectedEgg = data.SelectedEgg
	end

	if type(data.AutoCollectEnabled) == "boolean" then
		Config.AutoCollectEnabled = data.AutoCollectEnabled
	end

	if type(data.AutoPetEnabled) == "boolean" then
		Config.AutoPetEnabled = data.AutoPetEnabled
	end

	if type(data.AutoPetCPS) == "number" then
		Config.AutoPetCPS = math.clamp(
			math.floor(data.AutoPetCPS + 0.5),
			1,
			100
		)
	end

	if type(data.AutoRebirthEnabled) == "boolean" then
		Config.AutoRebirthEnabled = data.AutoRebirthEnabled
	end

	if type(data.AutoBuyFeederEnabled) == "boolean" then
		Config.AutoBuyFeederEnabled = data.AutoBuyFeederEnabled
	end

	if type(data.AutoUpgradeFeederCPS) == "number" then
		Config.AutoUpgradeFeederCPS = math.clamp(
			math.floor(data.AutoUpgradeFeederCPS + 0.5),
			1,
			50
		)
	end

	if type(data.AutoBuyFeederLevel) == "number" then
		Config.AutoBuyFeederLevel = math.clamp(
			math.floor(data.AutoBuyFeederLevel + 0.5),
			1,
			10
		)
	end

	if type(data.AutoPurchaseFeederEnabled) == "boolean" then
		Config.AutoPurchaseFeederEnabled = data.AutoPurchaseFeederEnabled
	end

	if type(data.AutoPurchaseFeederTarget) == "number" then
		Config.AutoPurchaseFeederTarget = math.clamp(
			math.floor(data.AutoPurchaseFeederTarget + 0.5),
			1,
			10
		)
	end

	if type(data.AutoExpandCoopEnabled) == "boolean" then
		Config.AutoExpandCoopEnabled = data.AutoExpandCoopEnabled
	end

	if type(data.AutoTowerEnabled) == "boolean" then
		Config.AutoTowerEnabled = data.AutoTowerEnabled
	end

	if data.AutoTowerStartChoice == "Priority FRONTIER"
		or data.AutoTowerStartChoice == "Priority STRAIGHT"
		or data.AutoTowerStartChoice == "Only BOTTOM" then

		Config.AutoTowerStartChoice = data.AutoTowerStartChoice
	end

	if type(data.AutoTowerSurrenderEnabled) == "boolean" then
		Config.AutoTowerSurrenderEnabled = data.AutoTowerSurrenderEnabled
	end

	if type(data.AutoTowerSurrenderFloor) == "number" then
		Config.AutoTowerSurrenderFloor = math.clamp(
			math.floor(data.AutoTowerSurrenderFloor + 0.5),
			1,
			9999
		)
	end

	if type(data.AutoTowerNoThanksEnabled) == "boolean" then
		Config.AutoTowerNoThanksEnabled = data.AutoTowerNoThanksEnabled
	end

	if type(data.AutomationEnabled) == "boolean" then
		Config.AutomationEnabled = data.AutomationEnabled
	end

	if type(data.AutomationTowerDelay) == "number" then
		Config.AutomationTowerDelay = math.clamp(
			math.floor(data.AutomationTowerDelay + 0.5),
			1,
			200
		)
	end

	if type(data.GodMode) == "boolean" then
		Config.GodMode = data.GodMode
	end

	if type(data.NoClip) == "boolean" then
		Config.NoClip = data.NoClip
	end

	if type(data.AntiAFK) == "boolean" then
		Config.AntiAFK = data.AntiAFK
	end

	if type(data.WalkSpeed) == "number" then
		Config.WalkSpeed = math.clamp(
			math.floor(data.WalkSpeed + 0.5),
			1,
			100
		)
	end

	if type(data.WalkSpeedOverride) == "boolean" then
		Config.WalkSpeedOverride = data.WalkSpeedOverride
	end

	if type(data.Theme) == "string"
		and table.find(THEME_NAMES, data.Theme) then

		Config.Theme = data.Theme
	end
end

local function loadConfig()
	if not canUseFileSystem() then
		return false
	end

	local exists = false

	local existsOk, existsResult = pcall(function()
		return isfile(CONFIG_FILE)
	end)

	if existsOk then
		exists = existsResult == true
	end

	if not exists then
		return false
	end

	local ok, decoded = pcall(function()
		local raw = readfile(CONFIG_FILE)
		return HttpService:JSONDecode(raw)
	end)

	if not ok then
		return false
	end

	sanitizeConfig(decoded)
	return true
end

local function writeConfig()
	if not canUseFileSystem() then
		return false
	end

	local ok = pcall(function()
		local encoded = HttpService:JSONEncode(Config)
		writefile(CONFIG_FILE, encoded)
	end)

	return ok
end

local function queueSaveConfig()
	if not canUseFileSystem() then
		return
	end

	configRevision += 1
	local revision = configRevision

	-- Debounce disk writes, especially while dragging Walk Speed.
	task.delay(0.25, function()
		if revision ~= configRevision then
			return
		end

		writeConfig()
	end)
end

loadConfig()

--========================================================
-- CLEAN OLD GUI
--========================================================

local oldGui = playerGui:FindFirstChild("GACF_Library")
if oldGui then
	oldGui:Destroy()
end

--========================================================
-- THEME
--========================================================

local Themes = {
	Monochrome = {
		Window = Color3.fromRGB(9, 9, 10),
		WindowGlow = Color3.fromRGB(15, 15, 17),
		Header = Color3.fromRGB(13, 13, 15),
		Sidebar = Color3.fromRGB(11, 11, 13),
		Content = Color3.fromRGB(16, 16, 18),

		Surface = Color3.fromRGB(23, 23, 26),
		ParentSurface = Color3.fromRGB(28, 28, 32),
		SurfaceHover = Color3.fromRGB(34, 34, 39),
		SurfaceActive = Color3.fromRGB(38, 38, 43),
		Control = Color3.fromRGB(19, 19, 22),
		Field = Color3.fromRGB(34, 34, 39),
		Track = Color3.fromRGB(43, 43, 48),
		ValueBadge = Color3.fromRGB(37, 37, 42),

		Accent = Color3.fromRGB(238, 238, 242),
		AccentHover = Color3.fromRGB(255, 255, 255),
		AccentSoft = Color3.fromRGB(48, 48, 53),
		AccentText = Color3.fromRGB(18, 18, 20),

		Text = Color3.fromRGB(241, 241, 244),
		TextMuted = Color3.fromRGB(172, 172, 181),
		TextDim = Color3.fromRGB(108, 108, 119),

		Success = Color3.fromRGB(200, 200, 205),
		SuccessSoft = Color3.fromRGB(40, 40, 44),
		Danger = Color3.fromRGB(219, 88, 96),
		DangerHover = Color3.fromRGB(237, 105, 113),

		ToggleOff = Color3.fromRGB(53, 53, 60),
		ToggleKnobOn = Color3.fromRGB(24, 24, 27),
		ToggleKnobOff = Color3.fromRGB(236, 236, 240),
		SliderKnob = Color3.fromRGB(241, 241, 244),
		Scrollbar = Color3.fromRGB(100, 100, 111),
	},

	Graphite = {
		Window = Color3.fromRGB(12, 12, 14),
		WindowGlow = Color3.fromRGB(18, 18, 22),
		Header = Color3.fromRGB(16, 16, 19),
		Sidebar = Color3.fromRGB(14, 14, 17),
		Content = Color3.fromRGB(17, 17, 20),

		Surface = Color3.fromRGB(23, 23, 28),
		ParentSurface = Color3.fromRGB(29, 29, 35),
		SurfaceHover = Color3.fromRGB(35, 35, 42),
		SurfaceActive = Color3.fromRGB(34, 34, 41),
		Control = Color3.fromRGB(19, 19, 23),
		Field = Color3.fromRGB(35, 35, 42),
		Track = Color3.fromRGB(42, 42, 50),
		ValueBadge = Color3.fromRGB(38, 38, 46),

		Accent = Color3.fromRGB(93, 133, 255),
		AccentHover = Color3.fromRGB(114, 151, 255),
		AccentSoft = Color3.fromRGB(28, 35, 58),
		AccentText = Color3.fromRGB(226, 233, 255),

		Text = Color3.fromRGB(236, 236, 241),
		TextMuted = Color3.fromRGB(165, 165, 177),
		TextDim = Color3.fromRGB(105, 105, 118),

		Success = Color3.fromRGB(95, 202, 138),
		SuccessSoft = Color3.fromRGB(24, 46, 34),
		Danger = Color3.fromRGB(224, 91, 100),
		DangerHover = Color3.fromRGB(239, 109, 118),

		ToggleOff = Color3.fromRGB(53, 53, 62),
		ToggleKnobOn = Color3.fromRGB(245, 247, 255),
		ToggleKnobOff = Color3.fromRGB(236, 236, 241),
		SliderKnob = Color3.fromRGB(241, 241, 244),
		Scrollbar = Color3.fromRGB(92, 92, 102),
	},

	Midnight = {
		Window = Color3.fromRGB(8, 11, 20),
		WindowGlow = Color3.fromRGB(12, 17, 31),
		Header = Color3.fromRGB(11, 15, 27),
		Sidebar = Color3.fromRGB(9, 13, 24),
		Content = Color3.fromRGB(12, 17, 30),

		Surface = Color3.fromRGB(18, 25, 43),
		ParentSurface = Color3.fromRGB(23, 32, 52),
		SurfaceHover = Color3.fromRGB(29, 39, 63),
		SurfaceActive = Color3.fromRGB(31, 42, 69),
		Control = Color3.fromRGB(15, 21, 36),
		Field = Color3.fromRGB(28, 38, 63),
		Track = Color3.fromRGB(35, 46, 72),
		ValueBadge = Color3.fromRGB(27, 37, 61),

		Accent = Color3.fromRGB(112, 139, 255),
		AccentHover = Color3.fromRGB(135, 158, 255),
		AccentSoft = Color3.fromRGB(31, 40, 78),
		AccentText = Color3.fromRGB(235, 239, 255),

		Text = Color3.fromRGB(235, 239, 249),
		TextMuted = Color3.fromRGB(157, 166, 190),
		TextDim = Color3.fromRGB(98, 108, 135),

		Success = Color3.fromRGB(83, 207, 157),
		SuccessSoft = Color3.fromRGB(20, 53, 45),
		Danger = Color3.fromRGB(229, 91, 111),
		DangerHover = Color3.fromRGB(244, 110, 129),

		ToggleOff = Color3.fromRGB(48, 58, 80),
		ToggleKnobOn = Color3.fromRGB(246, 248, 255),
		ToggleKnobOff = Color3.fromRGB(231, 236, 248),
		SliderKnob = Color3.fromRGB(240, 244, 255),
		Scrollbar = Color3.fromRGB(77, 89, 121),
	},

	Forest = {
		Window = Color3.fromRGB(8, 14, 12),
		WindowGlow = Color3.fromRGB(12, 22, 18),
		Header = Color3.fromRGB(11, 19, 16),
		Sidebar = Color3.fromRGB(9, 17, 14),
		Content = Color3.fromRGB(12, 21, 17),

		Surface = Color3.fromRGB(18, 29, 24),
		ParentSurface = Color3.fromRGB(23, 36, 30),
		SurfaceHover = Color3.fromRGB(29, 45, 37),
		SurfaceActive = Color3.fromRGB(30, 49, 40),
		Control = Color3.fromRGB(15, 25, 21),
		Field = Color3.fromRGB(27, 43, 36),
		Track = Color3.fromRGB(35, 52, 45),
		ValueBadge = Color3.fromRGB(26, 41, 34),

		Accent = Color3.fromRGB(100, 222, 165),
		AccentHover = Color3.fromRGB(126, 235, 184),
		AccentSoft = Color3.fromRGB(26, 59, 46),
		AccentText = Color3.fromRGB(10, 27, 20),

		Text = Color3.fromRGB(232, 243, 237),
		TextMuted = Color3.fromRGB(156, 180, 168),
		TextDim = Color3.fromRGB(94, 121, 108),

		Success = Color3.fromRGB(100, 222, 165),
		SuccessSoft = Color3.fromRGB(25, 59, 45),
		Danger = Color3.fromRGB(224, 96, 105),
		DangerHover = Color3.fromRGB(240, 114, 123),

		ToggleOff = Color3.fromRGB(46, 66, 57),
		ToggleKnobOn = Color3.fromRGB(245, 255, 250),
		ToggleKnobOff = Color3.fromRGB(231, 241, 235),
		SliderKnob = Color3.fromRGB(239, 250, 244),
		Scrollbar = Color3.fromRGB(74, 101, 88),
	},

	Rose = {
		Window = Color3.fromRGB(16, 9, 12),
		WindowGlow = Color3.fromRGB(25, 13, 18),
		Header = Color3.fromRGB(21, 11, 16),
		Sidebar = Color3.fromRGB(18, 10, 14),
		Content = Color3.fromRGB(22, 12, 17),

		Surface = Color3.fromRGB(31, 18, 24),
		ParentSurface = Color3.fromRGB(39, 22, 30),
		SurfaceHover = Color3.fromRGB(49, 28, 38),
		SurfaceActive = Color3.fromRGB(54, 29, 40),
		Control = Color3.fromRGB(27, 15, 21),
		Field = Color3.fromRGB(47, 26, 36),
		Track = Color3.fromRGB(57, 32, 43),
		ValueBadge = Color3.fromRGB(45, 25, 35),

		Accent = Color3.fromRGB(244, 121, 164),
		AccentHover = Color3.fromRGB(255, 144, 182),
		AccentSoft = Color3.fromRGB(72, 30, 48),
		AccentText = Color3.fromRGB(255, 238, 245),

		Text = Color3.fromRGB(246, 235, 239),
		TextMuted = Color3.fromRGB(188, 157, 168),
		TextDim = Color3.fromRGB(128, 92, 105),

		Success = Color3.fromRGB(100, 211, 151),
		SuccessSoft = Color3.fromRGB(29, 55, 42),
		Danger = Color3.fromRGB(235, 89, 104),
		DangerHover = Color3.fromRGB(248, 109, 123),

		ToggleOff = Color3.fromRGB(72, 45, 55),
		ToggleKnobOn = Color3.fromRGB(255, 244, 248),
		ToggleKnobOff = Color3.fromRGB(240, 226, 231),
		SliderKnob = Color3.fromRGB(252, 239, 244),
		Scrollbar = Color3.fromRGB(112, 76, 89),
	},
}

local ThemeName = Themes[Config.Theme] and Config.Theme or "Monochrome"
local Theme = Themes[ThemeName]

local THEME_COLOR_KEYS = {
	"Window",
	"WindowGlow",
	"Header",
	"Sidebar",
	"Content",
	"Surface",
	"ParentSurface",
	"SurfaceHover",
	"SurfaceActive",
	"Control",
	"Field",
	"Track",
	"ValueBadge",
	"Accent",
	"AccentHover",
	"AccentSoft",
	"AccentText",
	"Text",
	"TextMuted",
	"TextDim",
	"Success",
	"SuccessSoft",
	"Danger",
	"DangerHover",
	"ToggleOff",
	"ToggleKnobOn",
	"ToggleKnobOff",
	"SliderKnob",
	"Scrollbar",
}

local function findThemeColorKey(themeTable, color)
	for _, key in ipairs(THEME_COLOR_KEYS) do
		if themeTable[key] == color then
			return key
		end
	end

	return nil
end

local function applyThemeToGui(root, newThemeName)
	local newTheme = Themes[newThemeName]
	if not newTheme then
		return false
	end

	local oldTheme = Theme

	for _, object in ipairs(root:GetDescendants()) do
		if object:GetAttribute("ThemeStatic") ~= true then
			for _, property in ipairs({
				"BackgroundColor3",
				"TextColor3",
				"ImageColor3",
				"ScrollBarImageColor3",
			}) do
				local ok, currentColor = pcall(function()
					return object[property]
				end)

				if ok and typeof(currentColor) == "Color3" then
					local key = findThemeColorKey(oldTheme, currentColor)

					if key then
						pcall(function()
							object[property] = newTheme[key]
						end)
					end
				end
			end
		end
	end

	ThemeName = newThemeName
	Theme = newTheme
	return true
end

--========================================================
-- UI HELPERS
--========================================================

local function create(className, properties)
	local object = Instance.new(className)

	for property, value in pairs(properties or {}) do
		if property ~= "Parent" then
			object[property] = value
		end
	end

	if properties and properties.Parent then
		object.Parent = properties.Parent
	end

	return object
end

local function corner(parent, radius)
	return create("UICorner", {
		CornerRadius = UDim.new(0, radius),
		Parent = parent,
	})
end

local function stroke(parent, color, transparency, thickness)
	return create("UIStroke", {
		Color = color or Theme.Stroke,
		Transparency = transparency or 0,
		Thickness = thickness or 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = parent,
	})
end

local function gradient(parent, colorA, colorB, rotation)
	return create("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, colorA),
			ColorSequenceKeypoint.new(1, colorB),
		}),
		Rotation = rotation or 0,
		Parent = parent,
	})
end

local function padding(parent, left, right, top, bottom)
	return create("UIPadding", {
		PaddingLeft = UDim.new(0, left or 0),
		PaddingRight = UDim.new(0, right or 0),
		PaddingTop = UDim.new(0, top or 0),
		PaddingBottom = UDim.new(0, bottom or 0),
		Parent = parent,
	})
end

local function tween(object, duration, properties)
	local animation = TweenService:Create(
		object,
		TweenInfo.new(
			duration,
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.Out
		),
		properties
	)

	animation:Play()
	return animation
end

local function makeText(parent, properties)
	local defaults = {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		TextColor3 = Theme.Text,
		Font = Enum.Font.Gotham,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
	}

	for key, value in pairs(properties or {}) do
		defaults[key] = value
	end

	defaults.Parent = parent

	return create("TextLabel", defaults)
end

local function makeButton(parent, properties)
	local defaults = {
		BackgroundColor3 = Theme.Surface,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		TextColor3 = Theme.Text,
		Font = Enum.Font.GothamMedium,
		TextSize = 13,
	}

	for key, value in pairs(properties or {}) do
		defaults[key] = value
	end

	defaults.Parent = parent

	return create("TextButton", defaults)
end

local function ensureHoverScale(guiObject)
	local existing = guiObject:FindFirstChild("HoverScale")
	if existing and existing:IsA("UIScale") then
		return existing
	end

	return create("UIScale", {
		Name = "HoverScale",
		Scale = 1,
		Parent = guiObject,
	})
end

local function bindHoverMotion(guiObject, options)
	options = options or {}

	local scaleObject = ensureHoverScale(guiObject)
	local hoverScale = tonumber(options.HoverScale) or 1.018
	local pressScale = tonumber(options.PressScale) or 0.985
	local enterDuration = tonumber(options.EnterDuration) or 0.14
	local leaveDuration = tonumber(options.LeaveDuration) or 0.18

	local hovering = false
	local pressing = false

	guiObject.MouseEnter:Connect(function()
		hovering = true

		tween(scaleObject, enterDuration, {
			Scale = hoverScale,
		})
	end)

	guiObject.MouseLeave:Connect(function()
		hovering = false
		pressing = false

		tween(scaleObject, leaveDuration, {
			Scale = 1,
		})
	end)

	if guiObject:IsA("GuiButton") then
		guiObject.MouseButton1Down:Connect(function()
			pressing = true

			tween(scaleObject, 0.07, {
				Scale = pressScale,
			})
		end)

		guiObject.MouseButton1Up:Connect(function()
			pressing = false

			tween(scaleObject, 0.10, {
				Scale = hovering and hoverScale or 1,
			})
		end)
	end
end

local function bindSimpleHover(button, normalColor, hoverColor)
	local normalKey = findThemeColorKey(Theme, normalColor)
	local hoverKey = findThemeColorKey(Theme, hoverColor)

	bindHoverMotion(button, {
		HoverScale = 1.015,
		PressScale = 0.985,
		EnterDuration = 0.13,
		LeaveDuration = 0.17,
	})

	button.MouseEnter:Connect(function()
		tween(button, 0.13, {
			BackgroundColor3 = hoverKey and Theme[hoverKey] or hoverColor,
		})
	end)

	button.MouseLeave:Connect(function()
		tween(button, 0.17, {
			BackgroundColor3 = normalKey and Theme[normalKey] or normalColor,
		})
	end)
end

--========================================================
-- LIBRARY CORE
--========================================================

local Library = {}
Library.__index = Library

local Window = {}
Window.__index = Window

local Tab = {}
Tab.__index = Tab

local Section = {}
Section.__index = Section

--========================================================
-- CREATE WINDOW
--========================================================

function Library:CreateWindow(options)
	options = options or {}

	local screenGui = create("ScreenGui", {
		Name = options.Name or "GACF_Library",
		ResetOnSpawn = false,
		IgnoreGuiInset = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 50,
		Parent = playerGui,
	})

	local holder = create("Frame", {
		Name = "Window",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = options.Size or UDim2.fromOffset(800, 500),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Parent = screenGui,
	})

	-- Each edge frame owns the corner that is visible to the user.
	-- This avoids child frames visually squaring off a rounded root.
	local cornerRadius = 28
	local headerHeight = 58
	local sidebarWidth = 164

	local header = create("Frame", {
		Name = "Header",
		Size = UDim2.new(1, 0, 0, headerHeight),
		BackgroundColor3 = Theme.Header,
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		Active = true,
		ZIndex = 20,
		Parent = holder,
	})
	corner(header, cornerRadius)

	-- Soft glass layer: increases header contrast without a border.
	local headerGlass = create("Frame", {
		Name = "HeaderGlass",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Theme.Surface,
		BackgroundTransparency = 0.72,
		BorderSizePixel = 0,
		ZIndex = 21,
		Parent = header,
	})
	corner(headerGlass, cornerRadius)

	-- Square only the lower corners. Top-left and top-right stay rounded.
	local headerBottomFill = create("Frame", {
		Name = "HeaderBottomFill",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, 0),
		Size = UDim2.new(1, 0, 0, cornerRadius),
		BackgroundColor3 = Theme.Header,
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		ZIndex = 20,
		Parent = header,
	})

	local headerBottomGlass = create("Frame", {
		Name = "HeaderBottomGlass",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, 0),
		Size = UDim2.new(1, 0, 0, cornerRadius),
		BackgroundColor3 = Theme.Surface,
		BackgroundTransparency = 0.76,
		BorderSizePixel = 0,
		ZIndex = 21,
		Parent = header,
	})

	-- Soft depth under the title bar. No border line is used.
	local headerShadow = create("Frame", {
		Name = "HeaderShadow",
		Position = UDim2.new(0, 0, 1, -1),
		Size = UDim2.new(1, 0, 0, 14),
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 0.48,
		BorderSizePixel = 0,
		ZIndex = 19,
		Parent = header,
	})
	headerShadow:SetAttribute("ThemeStatic", true)

	local headerShadowGradient = create("UIGradient", {
		Rotation = 90,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.28),
			NumberSequenceKeypoint.new(0.35, 0.58),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Parent = headerShadow,
	})
	headerShadowGradient:SetAttribute("ThemeStatic", true)

	-- Launcher-style traffic lights inspired by desktop app title bars.
	local trafficHolder = create("Frame", {
		Name = "TrafficLights",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 18, 0.5, 0),
		Size = UDim2.fromOffset(66, 20),
		BackgroundTransparency = 1,
		ZIndex = 23,
		Parent = header,
	})

	create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Left,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = trafficHolder,
	})

	local trafficColors = {
		Color3.fromRGB(255, 95, 87),
		Color3.fromRGB(255, 189, 46),
		Color3.fromRGB(40, 201, 64),
	}

	for index, color in ipairs(trafficColors) do
		local dot = create("Frame", {
			Name = "TrafficDot" .. tostring(index),
			LayoutOrder = index,
			Size = UDim2.fromOffset(14, 14),
			BackgroundColor3 = color,
			BorderSizePixel = 0,
			ZIndex = 24,
			Parent = trafficHolder,
		})
		dot:SetAttribute("ThemeStatic", true)
		corner(dot, 7)
	end


	-- The application identity stays geometrically centered in the title bar.
	local titleLabel = makeText(header, {
		Name = "CenteredTitle",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(260, 32),
		Text = options.Title or "Grow A Chicken Fighter",
		Font = Enum.Font.GothamMedium,
		TextSize = 17,
		TextColor3 = Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 23,
	})

	-- Compact version badge.
	local versionBadge = makeButton(header, {
		Name = "VersionBadge",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -140, 0.5, 0),
		Size = UDim2.fromOffset(104, 34),
		BackgroundColor3 = Theme.Surface,
		BackgroundTransparency = 0.12,
		Text = "",
		ZIndex = 23,
	})
	corner(versionBadge, 17)

	local versionIcon = create("Frame", {
		Name = "VersionIcon",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 9, 0.5, 0),
		Size = UDim2.fromOffset(20, 20),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 24,
		Parent = versionBadge,
	})

	-- GitHub-style Octocat mark built from GUI primitives so it does
	-- not depend on an external Roblox image asset.
	local githubHead = create("Frame", {
		Name = "GitHubHead",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.54),
		Size = UDim2.fromOffset(14, 13),
		BackgroundColor3 = Theme.TextMuted,
		BorderSizePixel = 0,
		ZIndex = 25,
		Parent = versionIcon,
	})
	corner(githubHead, 7)

	local leftEar = create("Frame", {
		Name = "GitHubLeftEar",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.30, 0.20),
		Size = UDim2.fromOffset(6, 6),
		BackgroundColor3 = Theme.TextMuted,
		BorderSizePixel = 0,
		Rotation = 45,
		ZIndex = 25,
		Parent = versionIcon,
	})
	corner(leftEar, 2)

	local rightEar = create("Frame", {
		Name = "GitHubRightEar",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.70, 0.20),
		Size = UDim2.fromOffset(6, 6),
		BackgroundColor3 = Theme.TextMuted,
		BorderSizePixel = 0,
		Rotation = 45,
		ZIndex = 25,
		Parent = versionIcon,
	})
	corner(rightEar, 2)

	local leftEye = create("Frame", {
		Name = "GitHubLeftEye",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.40, 0.55),
		Size = UDim2.fromOffset(2, 2),
		BackgroundColor3 = Theme.Surface,
		BorderSizePixel = 0,
		ZIndex = 26,
		Parent = versionIcon,
	})
	corner(leftEye, 2)

	local rightEye = create("Frame", {
		Name = "GitHubRightEye",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.60, 0.55),
		Size = UDim2.fromOffset(2, 2),
		BackgroundColor3 = Theme.Surface,
		BorderSizePixel = 0,
		ZIndex = 26,
		Parent = versionIcon,
	})
	corner(rightEye, 2)

	local githubTail = create("Frame", {
		Name = "GitHubTail",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.19, 0.72),
		Size = UDim2.fromOffset(7, 3),
		BackgroundColor3 = Theme.TextMuted,
		BorderSizePixel = 0,
		Rotation = -28,
		ZIndex = 25,
		Parent = versionIcon,
	})
	corner(githubTail, 2)

	local versionText = makeText(versionBadge, {
		Position = UDim2.fromOffset(36, 0),
		Size = UDim2.new(1, -44, 1, 0),
		Text = APP_VERSION,
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		TextColor3 = Theme.TextMuted,
		ZIndex = 24,
	})

	-- Balanced action area on the right.
	local actionArea = create("Frame", {
		Name = "HeaderActions",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.5, 0),
		Size = UDim2.fromOffset(112, 34),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 23,
		Parent = header,
	})

	local settingsButton = makeButton(actionArea, {
		Name = "Settings",
		Position = UDim2.fromOffset(0, 1),
		Size = UDim2.fromOffset(32, 32),
		BackgroundColor3 = Theme.Header,
		Text = "⚙",
		TextColor3 = Theme.TextMuted,
		Font = Enum.Font.GothamMedium,
		TextSize = 17,
		ZIndex = 24,
	})
	corner(settingsButton, 10)

	local minimizeButton = makeButton(actionArea, {
		Name = "Minimize",
		Position = UDim2.fromOffset(40, 1),
		Size = UDim2.fromOffset(32, 32),
		BackgroundColor3 = Theme.Header,
		Text = "−",
		TextColor3 = Theme.TextMuted,
		Font = Enum.Font.GothamMedium,
		TextSize = 18,
		ZIndex = 24,
	})
	corner(minimizeButton, 10)

	local closeButton = makeButton(actionArea, {
		Name = "Close",
		Position = UDim2.fromOffset(80, 1),
		Size = UDim2.fromOffset(32, 32),
		BackgroundColor3 = Theme.Header,
		Text = "×",
		TextColor3 = Theme.TextMuted,
		Font = Enum.Font.GothamMedium,
		TextSize = 18,
		ZIndex = 24,
	})
	corner(closeButton, 10)

	local settingsPanel = create("Frame", {
		Name = "SettingsPanel",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -14, 0, headerHeight + 8),
		Size = UDim2.fromOffset(250, 286),
		BackgroundColor3 = Theme.Surface,
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = 70,
		Parent = holder,
	})
	corner(settingsPanel, 16)
	padding(settingsPanel, 12, 12, 12, 12)

	makeText(settingsPanel, {
		LayoutOrder = 1,
		Size = UDim2.new(1, 0, 0, 24),
		Text = "Settings",
		Font = Enum.Font.GothamBold,
		TextSize = 16,
		TextColor3 = Theme.Text,
		ZIndex = 71,
	})

	makeText(settingsPanel, {
		LayoutOrder = 2,
		Size = UDim2.new(1, 0, 0, 20),
		Text = "Theme",
		Font = Enum.Font.GothamMedium,
		TextSize = 12,
		TextColor3 = Theme.TextMuted,
		ZIndex = 71,
	})

	local themeList = create("Frame", {
		LayoutOrder = 3,
		Size = UDim2.new(1, 0, 0, 210),
		BackgroundTransparency = 1,
		ZIndex = 71,
		Parent = settingsPanel,
	})

	create("UIListLayout", {
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = themeList,
	})

	create("UIListLayout", {
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = settingsPanel,
	})

	local themeButtons = {}
	local settingsOpen = false

	local function refreshThemeButtons()
		for name, item in pairs(themeButtons) do
			local selected = name == ThemeName
			item.Button.BackgroundColor3 = selected and Theme.SurfaceActive or Theme.Control
			item.Label.TextColor3 = selected and Theme.Text or Theme.TextMuted
			item.Check.Text = selected and "✓" or ""
			item.Check.TextColor3 = Theme.Accent
		end
	end

	local function setThemeFromSettings(name)
		if not Themes[name] then
			return
		end

		applyThemeToGui(screenGui, name)
		Config.Theme = name
		queueSaveConfig()
		refreshThemeButtons()
	end

	for index, name in ipairs(THEME_NAMES) do
		local previewTheme = Themes[name]

		local themeButton = makeButton(themeList, {
			LayoutOrder = index,
			Size = UDim2.new(1, 0, 0, 36),
			BackgroundColor3 = Theme.Control,
			Text = "",
			ZIndex = 72,
		})
		corner(themeButton, 10)

		local swatch = create("Frame", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 9, 0.5, 0),
			Size = UDim2.fromOffset(16, 16),
			BackgroundColor3 = previewTheme.Accent,
			BorderSizePixel = 0,
			ZIndex = 73,
			Parent = themeButton,
		})
		swatch:SetAttribute("ThemeStatic", true)
		corner(swatch, 5)

		local optionLabel = makeText(themeButton, {
			Position = UDim2.fromOffset(34, 0),
			Size = UDim2.new(1, -66, 1, 0),
			Text = name,
			Font = Enum.Font.GothamMedium,
			TextSize = 12,
			TextColor3 = Theme.TextMuted,
			ZIndex = 73,
		})

		local checkLabel = makeText(themeButton, {
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -10, 0, 0),
			Size = UDim2.fromOffset(22, 36),
			Text = "",
			Font = Enum.Font.GothamBold,
			TextSize = 14,
			TextColor3 = Theme.Accent,
			TextXAlignment = Enum.TextXAlignment.Center,
			ZIndex = 73,
		})

		themeButtons[name] = {
			Button = themeButton,
			Label = optionLabel,
			Check = checkLabel,
		}

		bindHoverMotion(themeButton, {
			HoverScale = 1.018,
			PressScale = 0.985,
			EnterDuration = 0.13,
			LeaveDuration = 0.17,
		})

		themeButton.MouseEnter:Connect(function()
			if name ~= ThemeName then
				tween(themeButton, 0.13, {
					BackgroundColor3 = Theme.SurfaceHover,
				})
			end
		end)

		themeButton.MouseLeave:Connect(function()
			refreshThemeButtons()
		end)

		themeButton.MouseButton1Click:Connect(function()
			setThemeFromSettings(name)
		end)
	end

	refreshThemeButtons()

	local settingsScale = ensureHoverScale(settingsPanel)
	settingsScale.Scale = 0.96
	settingsPanel.BackgroundTransparency = 1

	local function setSettingsOpen(open)
		settingsOpen = open == true

		if settingsOpen then
			settingsPanel.Visible = true

			tween(settingsScale, 0.16, {
				Scale = 1,
			})

			tween(settingsPanel, 0.16, {
				BackgroundTransparency = 0,
			})
		else
			tween(settingsScale, 0.13, {
				Scale = 0.96,
			})

			tween(settingsPanel, 0.13, {
				BackgroundTransparency = 1,
			})

			task.delay(0.13, function()
				if not settingsOpen then
					settingsPanel.Visible = false
				end
			end)
		end

		settingsButton.TextColor3 = settingsOpen and Theme.Text or Theme.TextMuted
		settingsButton.BackgroundColor3 = settingsOpen and Theme.SurfaceActive or Theme.Header
	end

	settingsButton.MouseButton1Click:Connect(function()
		setSettingsOpen(not settingsOpen)
	end)

	local body = create("Frame", {
		Name = "Body",
		Position = UDim2.fromOffset(0, headerHeight),
		Size = UDim2.new(1, 0, 1, -headerHeight),
		BackgroundTransparency = 1,
		Parent = holder,
	})

	local sidebar = create("Frame", {
		Name = "Sidebar",
		Size = UDim2.new(0, sidebarWidth, 1, 0),
		BackgroundColor3 = Theme.Sidebar,
		BorderSizePixel = 0,
		Parent = body,
	})
	corner(sidebar, cornerRadius)

	local sidebarTopFill = create("Frame", {
		Name = "SidebarTopFill",
		Size = UDim2.new(1, 0, 0, cornerRadius),
		BackgroundColor3 = Theme.Sidebar,
		BorderSizePixel = 0,
		Parent = sidebar,
	})

	local sidebarRightFill = create("Frame", {
		Name = "SidebarRightFill",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 0),
		Size = UDim2.new(0, cornerRadius, 1, 0),
		BackgroundColor3 = Theme.Sidebar,
		BorderSizePixel = 0,
		Parent = sidebar,
	})

	makeText(sidebar, {
		Position = UDim2.fromOffset(14, 12),
		Size = UDim2.new(1, -28, 0, 20),
		Text = "PROJECT",
		TextColor3 = Theme.TextMuted,
		Font = Enum.Font.GothamBold,
		TextSize = 12,
	})

	local navHolder = create("Frame", {
		Name = "Tabs",
		Position = UDim2.fromOffset(8, 40),
		Size = UDim2.new(1, -16, 1, -49),
		BackgroundTransparency = 1,
		Parent = sidebar,
	})

	create("UIListLayout", {
		Padding = UDim.new(0, 3),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = navHolder,
	})

	local content = create("Frame", {
		Name = "Content",
		Position = UDim2.fromOffset(sidebarWidth, 0),
		Size = UDim2.new(1, -sidebarWidth, 1, 0),
		BackgroundColor3 = Theme.Content,
		BorderSizePixel = 0,
		Parent = body,
	})
	corner(content, cornerRadius)

	local contentTopFill = create("Frame", {
		Name = "ContentTopFill",
		Size = UDim2.new(1, 0, 0, cornerRadius),
		BackgroundColor3 = Theme.Content,
		BorderSizePixel = 0,
		Parent = content,
	})

	local contentLeftFill = create("Frame", {
		Name = "ContentLeftFill",
		Size = UDim2.new(0, cornerRadius, 1, 0),
		BackgroundColor3 = Theme.Content,
		BorderSizePixel = 0,
		Parent = content,
	})

	local pageHeader = create("Frame", {
		Name = "PageHeader",
		Position = UDim2.fromOffset(20, 14),
		Size = UDim2.new(1, -40, 0, 52),
		BackgroundTransparency = 1,
		Parent = content,
	})

	local breadcrumb = makeText(pageHeader, {
		Position = UDim2.fromOffset(0, 0),
		Size = UDim2.new(1, 0, 0, 16),
		Text = "project / routine",
		TextColor3 = Theme.TextMuted,
		Font = Enum.Font.Gotham,
		TextSize = 12,
	})

	local pageTitle = makeText(pageHeader, {
		Position = UDim2.fromOffset(0, 17),
		Size = UDim2.new(1, 0, 0, 31),
		Text = "",
		Font = Enum.Font.GothamMedium,
		TextSize = 22,
		TextColor3 = Theme.Text,
	})

	local pageContainer = create("Frame", {
		Name = "PageContainer",
		Position = UDim2.fromOffset(20, 72),
		Size = UDim2.new(1, -40, 1, -84),
		BackgroundTransparency = 1,
		Parent = content,
	})

	local self = setmetatable({
		ScreenGui = screenGui,
		Holder = holder,
		Header = header,
		HeaderGlass = headerGlass,
		HeaderShadow = headerShadow,
		HeaderBottomFill = headerBottomFill,
		HeaderBottomGlass = headerBottomGlass,
		TitleLabel = titleLabel,
		Body = body,
		NavHolder = navHolder,
		PageContainer = pageContainer,
		PageTitle = pageTitle,
		Breadcrumb = breadcrumb,
		TrafficLights = trafficHolder,
		VersionBadge = versionBadge,
		SettingsButton = settingsButton,
		SettingsPanel = settingsPanel,
		MinimizeButton = minimizeButton,
		CloseButton = closeButton,
		Tabs = {},
		ActiveTab = nil,
		NormalSize = options.Size or UDim2.fromOffset(800, 500),
		MinimizedSize = options.MinimizedSize or UDim2.fromOffset(410, 58),
		Minimized = false,
		Closed = false,
	}, Window)

	bindHoverMotion(versionBadge, {
		HoverScale = 1.035,
		PressScale = 0.985,
		EnterDuration = 0.13,
		LeaveDuration = 0.17,
	})

	versionBadge.MouseEnter:Connect(function()
		tween(versionBadge, 0.13, {
			BackgroundColor3 = Theme.SurfaceHover,
		})

		tween(versionText, 0.13, {
			TextColor3 = Theme.Text,
		})

		tween(githubHead, 0.13, {
			BackgroundColor3 = Theme.Text,
		})
		tween(leftEar, 0.13, {
			BackgroundColor3 = Theme.Text,
		})
		tween(rightEar, 0.13, {
			BackgroundColor3 = Theme.Text,
		})
		tween(githubTail, 0.13, {
			BackgroundColor3 = Theme.Text,
		})
	end)

	versionBadge.MouseLeave:Connect(function()
		tween(versionBadge, 0.17, {
			BackgroundColor3 = Theme.Surface,
		})

		tween(versionText, 0.17, {
			TextColor3 = Theme.TextMuted,
		})

		tween(githubHead, 0.17, {
			BackgroundColor3 = Theme.TextMuted,
		})
		tween(leftEar, 0.17, {
			BackgroundColor3 = Theme.TextMuted,
		})
		tween(rightEar, 0.17, {
			BackgroundColor3 = Theme.TextMuted,
		})
		tween(githubTail, 0.17, {
			BackgroundColor3 = Theme.TextMuted,
		})
	end)

	bindSimpleHover(settingsButton, Theme.Header, Theme.SurfaceHover)
	bindSimpleHover(minimizeButton, Theme.Header, Theme.SurfaceHover)

	bindHoverMotion(closeButton, {
		HoverScale = 1.06,
		PressScale = 0.92,
		EnterDuration = 0.12,
		LeaveDuration = 0.16,
	})

	closeButton.MouseEnter:Connect(function()
		tween(closeButton, 0.12, {
			BackgroundColor3 = Theme.Danger,
			TextColor3 = Color3.fromRGB(255, 255, 255),
		})
	end)

	closeButton.MouseLeave:Connect(function()
		tween(closeButton, 0.1, {
			BackgroundColor3 = Theme.Header,
			TextColor3 = Theme.TextMuted,
		})
	end)

	local function toggleMinimize()
		setSettingsOpen(false)
		self.Minimized = not self.Minimized
		if self.Minimized then
			self.Body.Visible = false
			self.HeaderBottomFill.Visible = false
			self.HeaderBottomGlass.Visible = false
			self.HeaderShadow.Visible = false
			self.MinimizeButton.Text = "+"
			tween(self.Holder, 0.18, {Size = self.MinimizedSize})
		else
			self.HeaderBottomFill.Visible = true
			self.HeaderBottomGlass.Visible = true
			self.HeaderShadow.Visible = true
			self.MinimizeButton.Text = "−"
			tween(self.Holder, 0.18, {Size = self.NormalSize})
			task.delay(0.18, function()
				if not self.Closed and not self.Minimized then
					self.Body.Visible = true
				end
			end)
		end
	end

	self.ToggleMinimize = function()
		toggleMinimize()
	end
	minimizeButton.MouseButton1Click:Connect(toggleMinimize)

	local function closeWindow()
		if self.Closed then return end
		self.Closed = true
		setSettingsOpen(false)
		tween(self.Holder, 0.14, {
			Size = UDim2.fromOffset(360, 0),
		})
		task.delay(0.14, function()
			if self.ScreenGui then self.ScreenGui:Destroy() end
		end)
	end

	self.Close = function()
		closeWindow()
	end
	closeButton.MouseButton1Click:Connect(closeWindow)

	local dragging = false
	local dragInput
	local dragStart
	local startPosition

	local function inside(guiObject, position)
		local p = guiObject.AbsolutePosition
		local s = guiObject.AbsoluteSize
		return position.X >= p.X and position.X <= p.X + s.X
			and position.Y >= p.Y and position.Y <= p.Y + s.Y
	end

	header.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch then return end
		if inside(versionBadge, input.Position)
			or inside(settingsButton, input.Position)
			or inside(minimizeButton, input.Position)
			or inside(closeButton, input.Position) then return end
		dragging = true
		dragStart = input.Position
		startPosition = holder.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then dragging = false end
		end)
	end)

	header.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if not dragging or input ~= dragInput then return end
		local delta = input.Position - dragStart
		holder.Position = UDim2.new(
			startPosition.X.Scale,
			startPosition.X.Offset + delta.X,
			startPosition.Y.Scale,
			startPosition.Y.Offset + delta.Y
		)
	end)

	return self
end

--========================================================
-- ADD TAB
--========================================================

function Window:AddTab(name, description)
	local order = #self.Tabs + 1
	local button = makeButton(self.NavHolder, {
		Name = name .. "TabButton", LayoutOrder = order,
		Size = UDim2.new(1, 0, 0, 38), BackgroundColor3 = Theme.Sidebar, Text = "",
	})
	corner(button, 11)
	local indicator = create("Frame", {
		Name = "Indicator", AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.fromOffset(4, 18),
		BackgroundColor3 = Theme.Accent, BackgroundTransparency = 1,
		BorderSizePixel = 0, Parent = button,
	})
	corner(indicator, 4)
	local label = makeText(button, {
		Position = UDim2.fromOffset(11, 0), Size = UDim2.new(1, -17, 1, 0),
		Text = name, TextColor3 = Theme.TextMuted, Font = Enum.Font.GothamMedium, TextSize = 14,
	})
	local page = create("ScrollingFrame", {
		Name = name .. "Page", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
		BorderSizePixel = 0, ScrollBarThickness = 2, ScrollBarImageColor3 = Theme.Scrollbar,
		ScrollingDirection = Enum.ScrollingDirection.Y, AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(), Visible = false, Parent = self.PageContainer,
	})
	padding(page, 0, 3, 0, 5)
	create("UIListLayout", {Padding = UDim.new(0, 7), SortOrder = Enum.SortOrder.LayoutOrder, Parent = page})
	local tab = setmetatable({Window = self, Name = name, Description = description or "", Button = button,
		Label = label, Indicator = indicator, Page = page, Sections = {}, Order = order}, Tab)
	table.insert(self.Tabs, tab)
	function tab:SetActive(active)
		if active then
			tween(self.Button, 0.1, {BackgroundColor3 = Theme.SurfaceActive})
			tween(self.Indicator, 0.1, {BackgroundTransparency = 0})
			self.Label.TextColor3 = Theme.Text
			self.Page.Visible = true
		else
			tween(self.Button, 0.1, {BackgroundColor3 = Theme.Sidebar})
			tween(self.Indicator, 0.1, {BackgroundTransparency = 1})
			self.Label.TextColor3 = Theme.TextMuted
			self.Page.Visible = false
		end
	end
	bindHoverMotion(button, {
		HoverScale = 1.018,
		PressScale = 0.985,
		EnterDuration = 0.13,
		LeaveDuration = 0.18,
	})

	button.MouseEnter:Connect(function()
		if self.ActiveTab ~= tab then
			tween(button, 0.13, {
				BackgroundColor3 = Theme.SurfaceHover,
			})
		end
	end)

	button.MouseLeave:Connect(function()
		if self.ActiveTab ~= tab then
			tween(button, 0.18, {
				BackgroundColor3 = Theme.Sidebar,
			})
		end
	end)
	button.MouseButton1Click:Connect(function() self:SelectTab(tab) end)
	if #self.Tabs == 1 then self:SelectTab(tab) end
	return tab
end

--========================================================
-- SELECT TAB
--========================================================

function Window:SelectTab(tab)
	for _, item in ipairs(self.Tabs) do
		item:SetActive(item == tab)
	end

	self.ActiveTab = tab
	self.PageTitle.Text = tab.Name
	self.Breadcrumb.Text = "project / " .. string.lower(tab.Name)
end

local function usesStrongParentSurface(tab)
	return tab
		and (
			tab.Name == "Routine"
			or tab.Name == "Auto"
			or tab.Name == "Utilities"
		)
end

local function topLevelSurface(tab)
	if usesStrongParentSurface(tab) then
		return Theme.ParentSurface
	end

	return Theme.Surface
end

--========================================================
-- ADD SECTION
--========================================================

function Tab:AddSection(titleText, descriptionText)
	local sectionFrame = create("Frame", {
		Name = titleText .. "Section", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = topLevelSurface(self), BorderSizePixel = 0, Parent = self.Page,
	})
	corner(sectionFrame, 16)
	padding(sectionFrame, 10, 10, 9, 9)
	makeText(sectionFrame, {LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 24), Text = titleText,
		Font = Enum.Font.GothamMedium, TextSize = 14, TextColor3 = Theme.Text})
	local controls = create("Frame", {Name = "Controls", LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = sectionFrame})
	create("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = controls})
	create("UIListLayout", {Padding = UDim.new(0, 7), SortOrder = Enum.SortOrder.LayoutOrder, Parent = sectionFrame})
	local section = setmetatable({Tab = self, Frame = sectionFrame, Controls = controls, ControlCount = 0}, Section)
	table.insert(self.Sections, section)
	return section
end

--========================================================
-- ADD DIRECT CONTROL GROUP
-- Used when controls should live directly on the tab page
-- without an extra titled/card wrapper.
--========================================================

function Tab:AddDirectGroup()
	local controls = create("Frame", {
		Name = "DirectControls",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Parent = self.Page,
	})

	create("UIListLayout", {
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = controls,
	})

	local group = setmetatable({
		Tab = self,
		Frame = controls,
		Controls = controls,
		ControlCount = 0,
		IsDirectGroup = true,
	}, Section)

	table.insert(self.Sections, group)
	return group
end

--========================================================
-- ADD COLLAPSIBLE DROPDOWN SECTION
--========================================================

function Tab:AddDropdownSection(titleText, defaultOpen)
	local breakdownInsetX = 4
	local breakdownInsetY = 4

	-- Chevron-only style. Background button is intentionally hidden.
	local arrowIconColor = Color3.fromRGB(190, 191, 198)

	local sectionFrame = create("Frame", {
		Name = titleText .. "DropdownSection", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = topLevelSurface(self), BorderSizePixel = 0, Parent = self.Page,
	})
	corner(sectionFrame, 16)
	padding(sectionFrame, breakdownInsetX, breakdownInsetX, breakdownInsetY, breakdownInsetY)
	create("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = sectionFrame})

	local headerButton = makeButton(sectionFrame, {
		Name = "DropdownHeader",
		LayoutOrder = 1,
		Size = UDim2.new(1, 0, 0, 42),
		BackgroundColor3 = topLevelSurface(self),
		Text = "",
	})
	corner(headerButton, 12)

	local arrowChip = create("Frame", {
		Name = "DropdownArrowChip",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(38, 36),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 3,
		Parent = headerButton,
	})

	local arrow = makeText(arrowChip, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(18, 18),
		Text = ">",
		TextColor3 = arrowIconColor,
		Font = Enum.Font.Code,
		TextSize = 17,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
		ZIndex = 4,
	})

	makeText(headerButton, {
		Position = UDim2.fromOffset(14, 0),
		Size = UDim2.new(1, -66, 1, 0),
		Text = titleText,
		Font = Enum.Font.GothamMedium,
		TextSize = 14,
		TextColor3 = Theme.Text,
	})

	local controls = create("Frame", {
		Name = "Controls",
		LayoutOrder = 2,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Visible = defaultOpen == true,
		Parent = sectionFrame,
	})

	create("UIListLayout", {
		Padding = UDim.new(0, 5),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = controls,
	})

	local section = setmetatable({
		Tab = self,
		Frame = sectionFrame,
		Controls = controls,
		ControlCount = 0,
		HeaderButton = headerButton,
		Arrow = arrow,
		ArrowChip = arrowChip,
		IsOpen = defaultOpen == true,
	}, Section)

	local function renderOpenState(animate)
		local open = section.IsOpen
		controls.Visible = open

		local headerColor = open and Theme.SurfaceActive or topLevelSurface(self)
		local arrowColor = open and Theme.Accent or arrowIconColor

		if animate then
			tween(arrow, 0.12, {
				Rotation = open and 90 or 0,
				TextColor3 = arrowColor,
			})

			tween(headerButton, 0.12, {
				BackgroundColor3 = headerColor,
			})
		else
			arrow.Rotation = open and 90 or 0
			arrow.TextColor3 = arrowColor
			headerButton.BackgroundColor3 = headerColor
		end
	end

	function section:SetOpen(open, animate)
		self.IsOpen = open == true
		renderOpenState(animate ~= false)
	end

	function section:Toggle()
		self:SetOpen(not self.IsOpen, true)
	end

	bindHoverMotion(headerButton, {
		HoverScale = 1.008,
		PressScale = 0.992,
		EnterDuration = 0.14,
		LeaveDuration = 0.18,
	})

	headerButton.MouseEnter:Connect(function()
		if not section.IsOpen then
			tween(headerButton, 0.14, {
				BackgroundColor3 = Theme.SurfaceHover,
			})

			tween(arrow, 0.14, {
				TextColor3 = Theme.Text,
			})
		end
	end)

	headerButton.MouseLeave:Connect(function()
		if not section.IsOpen then
			tween(headerButton, 0.18, {
				BackgroundColor3 = topLevelSurface(self),
			})

			tween(arrow, 0.18, {
				TextColor3 = arrowIconColor,
			})
		end
	end)

	headerButton.MouseButton1Click:Connect(function()
		section:Toggle()
	end)

	renderOpenState(false)
	table.insert(self.Sections, section)
	return section
end


local function controlSurface(section)
	if section.IsDirectGroup then
		return topLevelSurface(section.Tab)
	end

	return Theme.Control
end

local function controlLeftInset(section)
	-- Accordion title = 7px outer padding + 14px title inset.
	-- Direct rows have no outer wrapper, so use the combined 21px.
	return section.IsDirectGroup and 21 or 14
end

local function controlRightInset(section)
	return section.IsDirectGroup and 21 or 14
end

local function applyDirectRowHover(section, frame)
	if not section.IsDirectGroup then
		return
	end

	bindHoverMotion(frame, {
		HoverScale = 1.006,
		PressScale = 0.997,
		EnterDuration = 0.14,
		LeaveDuration = 0.18,
	})

	frame.MouseEnter:Connect(function()
		tween(frame, 0.14, {
			BackgroundColor3 = Theme.SurfaceHover,
		})
	end)

	frame.MouseLeave:Connect(function()
		tween(frame, 0.18, {
			BackgroundColor3 = topLevelSurface(section.Tab),
		})
	end)
end

--========================================================
-- SECTION: PARAGRAPH
--========================================================

function Section:AddParagraph(titleText, bodyText)
	self.ControlCount += 1
	local leftInset = controlLeftInset(self)
	local rightInset = controlRightInset(self)
	local frame = create("Frame", {LayoutOrder = self.ControlCount, Size = UDim2.new(1, 0, 0, 62),
		BackgroundColor3 = controlSurface(self), BorderSizePixel = 0, Parent = self.Controls})
	corner(frame, 13)

	makeText(frame, {
		Position = UDim2.fromOffset(leftInset, 8),
		Size = UDim2.new(1, -(leftInset + rightInset), 0, 22),
		Text = titleText,
		Font = Enum.Font.GothamMedium,
		TextSize = 14,
		TextColor3 = Theme.Text,
	})

	makeText(frame, {
		Position = UDim2.fromOffset(leftInset, 31),
		Size = UDim2.new(1, -(leftInset + rightInset), 0, 22),
		Text = bodyText,
		Font = Enum.Font.Gotham,
		TextColor3 = Theme.TextMuted,
		TextSize = 13,
	})

	applyDirectRowHover(self, frame)

	return frame
end

--========================================================
-- SECTION: STATUS
--========================================================

function Section:AddStatus(labelText, initialValue)
	self.ControlCount += 1
	local leftInset = controlLeftInset(self)
	local rightInset = controlRightInset(self)
	local frame = create("Frame", {LayoutOrder = self.ControlCount, Size = UDim2.new(1, 0, 0, 44),
		BackgroundColor3 = controlSurface(self), BorderSizePixel = 0, Parent = self.Controls})
	corner(frame, 13)

	makeText(frame, {
		Position = UDim2.fromOffset(leftInset, 0),
		Size = UDim2.new(0.5, -(leftInset / 2), 1, 0),
		Text = labelText,
		TextColor3 = Theme.Text,
		Font = Enum.Font.GothamMedium,
		TextSize = 14,
	})

	local valueLabel = makeText(frame, {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -rightInset, 0, 0),
		Size = UDim2.new(0.5, -(rightInset / 2), 1, 0),
		Text = initialValue or "",
		TextColor3 = Theme.Text,
		Font = Enum.Font.GothamMedium,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Right,
	})
	local api = {}
	applyDirectRowHover(self, frame)

	function api:Set(value, useAccent) valueLabel.Text = tostring(value) valueLabel.TextColor3 = useAccent and Theme.Accent or Theme.Text end
	return api
end

--========================================================
-- SECTION: TOGGLE
--========================================================

function Section:AddToggle(options)
	options = options or {}
	self.ControlCount += 1
	local frame = create("Frame", {LayoutOrder = self.ControlCount, Size = UDim2.new(1, 0, 0, self.IsDirectGroup and 64 or 50),
		BackgroundColor3 = controlSurface(self), BorderSizePixel = 0, Parent = self.Controls})
	corner(frame, 13)

	local leftInset = controlLeftInset(self)
	local rightInset = controlRightInset(self)

	makeText(frame, {
		Position = UDim2.fromOffset(leftInset, 0),
		Size = UDim2.new(1, -(leftInset + 62 + rightInset), 1, 0),
		Text = options.Title or "Toggle",
		Font = Enum.Font.GothamMedium,
		TextSize = 14,
		TextColor3 = Theme.Text,
	})
	local state = options.Default == true

	local button = makeButton(frame, {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -rightInset, 0.5, 0),
		Size = UDim2.fromOffset(44, 24), BackgroundColor3 = state and Theme.Accent or Theme.ToggleOff, Text = ""})
	corner(button, 14)
	local knob = create("Frame", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 3, 0.5, 0),
		Size = UDim2.fromOffset(16, 16), BackgroundColor3 = state and Theme.ToggleKnobOn or Theme.ToggleKnobOff,
		BorderSizePixel = 0, Parent = button})
	corner(knob, 8)
	local callback = options.Callback or function() end
	local api = {}
	local function render(animate)
		local targetBackground = state and Theme.Accent or Theme.ToggleOff
		local targetKnobColor = state and Theme.ToggleKnobOn or Theme.ToggleKnobOff
		local targetPosition = state and UDim2.new(1, -19, 0.5, 0) or UDim2.new(0, 4, 0.5, 0)
		if animate then
			tween(button, 0.12, {BackgroundColor3 = targetBackground})
			tween(knob, 0.12, {
				Position = targetPosition,
				BackgroundColor3 = targetKnobColor,
			})
		else
			button.BackgroundColor3 = targetBackground
			knob.Position = targetPosition
			knob.BackgroundColor3 = targetKnobColor
		end
	end
	function api:Set(value, fireCallback)
		state = value == true
		render(true)
		if fireCallback ~= false then task.spawn(callback, state) end
	end
	function api:Get() return state end
	function api:SetVisible(visible) frame.Visible = visible end
	bindHoverMotion(button, {
		HoverScale = 1.08,
		PressScale = 0.92,
		EnterDuration = 0.12,
		LeaveDuration = 0.16,
	})

	button.MouseEnter:Connect(function()
		tween(knob, 0.13, {
			Size = UDim2.fromOffset(18, 18),
		})
	end)

	button.MouseLeave:Connect(function()
		tween(knob, 0.16, {
			Size = UDim2.fromOffset(16, 16),
		})
	end)

	button.MouseButton1Click:Connect(function()
		api:Set(not state, true)
	end)

	applyDirectRowHover(self, frame)

	render(false)
	return api
end

--========================================================
-- SECTION: NUMBER INPUT
--========================================================

function Section:AddNumberInput(options)
	options = options or {}
	self.ControlCount += 1

	local minimum = tonumber(options.Min) or 1
	local maximum = tonumber(options.Max) or 10
	local callback = options.Callback or function() end

	if maximum < minimum then
		maximum = minimum
	end

	local value = tonumber(options.Default) or minimum
	value = math.clamp(
		math.floor(value + 0.5),
		minimum,
		maximum
	)

	local leftInset = controlLeftInset(self)
	local rightInset = controlRightInset(self)

	local frame = create("Frame", {
		LayoutOrder = self.ControlCount,
		Size = UDim2.new(
			1,
			0,
			0,
			self.IsDirectGroup and 64 or 52
		),
		BackgroundColor3 = controlSurface(self),
		BorderSizePixel = 0,
		Parent = self.Controls,
	})
	corner(frame, 13)

	makeText(frame, {
		Position = UDim2.fromOffset(leftInset, 0),
		Size = UDim2.new(
			1,
			-(leftInset + rightInset + 92),
			1,
			0
		),
		Text = options.Title or "Value",
		Font = Enum.Font.GothamMedium,
		TextSize = 14,
		TextColor3 = Theme.Text,
	})

	local input = create("TextBox", {
		Name = "NumberInput",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(
			1,
			-rightInset,
			0.5,
			0
		),
		Size = UDim2.fromOffset(72, 36),
		BackgroundColor3 = Theme.Field,
		BorderSizePixel = 0,
		ClearTextOnFocus = false,
		Font = Enum.Font.GothamMedium,
		Text = tostring(value),
		TextColor3 = Theme.Text,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = frame,
	})
	corner(input, 10)

	local api = {}
	local editingText = false

	local function sanitize(raw)
		local numeric = tonumber(raw)

		if numeric == nil then
			return value
		end

		return math.clamp(
			math.floor(numeric + 0.5),
			minimum,
			maximum
		)
	end

	local function render()
		editingText = true
		input.Text = tostring(value)
		editingText = false
	end

	local function commit(raw, fireCallback)
		local newValue = sanitize(raw)
		local changed = newValue ~= value

		value = newValue
		render()

		if fireCallback ~= false and changed then
			task.spawn(callback, value)
		end
	end

	function api:Set(newValue, fireCallback)
		commit(newValue, fireCallback)
	end

	function api:Get()
		return value
	end

	function api:SetVisible(visible)
		frame.Visible = visible
	end

	input:GetPropertyChangedSignal("Text"):Connect(function()
		if editingText then
			return
		end

		local cleaned = input.Text:gsub("[^0-9]", "")

		if cleaned ~= input.Text then
			editingText = true
			input.Text = cleaned
			editingText = false
		end
	end)

	input.Focused:Connect(function()
		tween(input, 0.12, {
			BackgroundColor3 = Theme.SurfaceActive,
		})
	end)

	input.FocusLost:Connect(function()
		commit(input.Text, true)

		tween(input, 0.16, {
			BackgroundColor3 = Theme.Field,
		})
	end)

	input.MouseEnter:Connect(function()
		if not input:IsFocused() then
			tween(input, 0.12, {
				BackgroundColor3 = Theme.SurfaceHover,
			})
		end
	end)

	input.MouseLeave:Connect(function()
		if not input:IsFocused() then
			tween(input, 0.16, {
				BackgroundColor3 = Theme.Field,
			})
		end
	end)

	applyDirectRowHover(self, frame)
	render()

	return api
end

--========================================================
-- SECTION: SLIDER
--========================================================

function Section:AddSlider(options)
	options = options or {}
	self.ControlCount += 1

	local minimum = tonumber(options.Min) or 0
	local maximum = tonumber(options.Max) or 100
	local step = tonumber(options.Step) or 1
	local callback = options.Callback or function() end
	local leftInset = controlLeftInset(self)
	local rightInset = controlRightInset(self)

	if maximum <= minimum then
		maximum = minimum + 1
	end

	if step <= 0 then
		step = 1
	end

	local value = tonumber(options.Default) or minimum
	value = math.clamp(value, minimum, maximum)

	local function snap(rawValue)
		local steps = math.floor(((rawValue - minimum) / step) + 0.5)
		return math.clamp(minimum + (steps * step), minimum, maximum)
	end

	value = snap(value)

	local frame = create("Frame", {
		LayoutOrder = self.ControlCount,
		Size = UDim2.new(1, 0, 0, self.IsDirectGroup and 78 or 72),
		BackgroundColor3 = controlSurface(self),
		BorderSizePixel = 0,
		Parent = self.Controls,
	})
	corner(frame, 13)

	makeText(frame, {
		Position = UDim2.fromOffset(leftInset, 6),
		Size = UDim2.new(1, -(leftInset + 74 + rightInset), 0, 26),
		Text = options.Title or "Slider",
		Font = Enum.Font.GothamMedium,
		TextSize = 14,
		TextColor3 = Theme.Text,
	})

	local valueBadge = create("Frame", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -rightInset, 0, 7),
		Size = UDim2.fromOffset(54, 25),
		BackgroundColor3 = Theme.ValueBadge,
		BorderSizePixel = 0,
		Parent = frame,
	})
	corner(valueBadge, 10)

	local valueLabel = makeText(valueBadge, {
		Size = UDim2.fromScale(1, 1),
		Text = tostring(value),
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		TextColor3 = Theme.Accent,
		TextXAlignment = Enum.TextXAlignment.Center,
	})

	local track = create("Frame", {
		Name = "Track",
		Position = UDim2.new(0, leftInset, 0, 53),
		Size = UDim2.new(1, -(leftInset + rightInset), 0, 5),
		BackgroundColor3 = Theme.Track,
		BorderSizePixel = 0,
		Active = true,
		Parent = frame,
	})
	corner(track, 5)

	local fill = create("Frame", {
		Name = "Fill",
		Size = UDim2.new(0, 0, 1, 0),
		BackgroundColor3 = Theme.Accent,
		BorderSizePixel = 0,
		Parent = track,
	})
	corner(fill, 5)
	
	local knob = create("Frame", {
		Name = "Knob",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.fromOffset(14, 14),
		BackgroundColor3 = Theme.SliderKnob,
		BorderSizePixel = 0,
		Active = true,
		Parent = track,
	})
	corner(knob, 8)

	local dragging = false
	local lastCallbackValue = value
	local api = {}

	local function ratioFor(currentValue)
		return math.clamp(
			(currentValue - minimum) / (maximum - minimum),
			0,
			1
		)
	end

	local function render(animate)
		local ratio = ratioFor(value)
		local fillTarget = UDim2.new(ratio, 0, 1, 0)
		local knobTarget = UDim2.new(ratio, 0, 0.5, 0)

		valueLabel.Text = tostring(value)

		if animate then
			tween(fill, 0.08, {
				Size = fillTarget,
			})

			tween(knob, 0.08, {
				Position = knobTarget,
			})
		else
			fill.Size = fillTarget
			knob.Position = knobTarget
		end
	end

	local function setValue(newValue, fireCallback, animate)
		newValue = snap(tonumber(newValue) or value)

		if newValue == value then
			render(animate == true)
			return
		end

		value = newValue
		render(animate == true)

		if fireCallback ~= false and value ~= lastCallbackValue then
			lastCallbackValue = value
			task.spawn(callback, value)
		end
	end

	local function valueFromScreenX(screenX)
		local width = track.AbsoluteSize.X
		if width <= 0 then
			return value
		end

		local relative = math.clamp(
			(screenX - track.AbsolutePosition.X) / width,
			0,
			1
		)

		return minimum + ((maximum - minimum) * relative)
	end

	local function beginDrag(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end

		dragging = true
		setValue(valueFromScreenX(input.Position.X), true, false)
	end

	track.InputBegan:Connect(beginDrag)
	knob.InputBegan:Connect(beginDrag)

	UserInputService.InputChanged:Connect(function(input)
		if not dragging then
			return
		end

		if input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch then

			setValue(valueFromScreenX(input.Position.X), true, false)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then

			dragging = false
		end
	end)

	track.MouseEnter:Connect(function()
		tween(track, 0.14, {
			BackgroundColor3 = Theme.SurfaceActive,
		})

		tween(knob, 0.14, {
			Size = UDim2.fromOffset(18, 18),
		})
	end)

	track.MouseLeave:Connect(function()
		if not dragging then
			tween(track, 0.18, {
				BackgroundColor3 = Theme.Track,
			})

			tween(knob, 0.18, {
				Size = UDim2.fromOffset(14, 14),
			})
		end
	end)

	function api:Set(newValue, fireCallback)
		setValue(newValue, fireCallback, true)
	end

	function api:Get()
		return value
	end

	function api:SetVisible(visible)
		frame.Visible = visible
	end

	applyDirectRowHover(self, frame)

	render(false)

	return api
end

--========================================================
-- SECTION: DROPDOWN
--========================================================

function Section:AddDropdown(options)
	options = options or {}
	self.ControlCount += 1

	local values = table.clone(options.Values or {})
	local selected = options.Default
	local callback = options.Callback or function() end
	local leftInset = controlLeftInset(self)
	local rightInset = controlRightInset(self)
	local opened = false
	local optionConnections = {}

	if selected == nil then
		selected = values[1] or ""
	end

	local frame = create("Frame", {
		LayoutOrder = self.ControlCount,
		Size = UDim2.new(1, 0, 0, self.IsDirectGroup and 64 or 52),
		BackgroundColor3 = controlSurface(self),
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Parent = self.Controls,
	})
	corner(frame, 13)

	makeText(frame, {
		Position = UDim2.fromOffset(leftInset, 0),
		Size = UDim2.new(0.5, -(leftInset / 2), 0, 52),
		Text = options.Title or "Dropdown",
		Font = Enum.Font.GothamMedium,
		TextSize = 14,
		TextColor3 = Theme.Text,
	})

	local selectButton = makeButton(frame, {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -rightInset, 0, 8),
		Size = UDim2.fromOffset(176, 36),
		BackgroundColor3 = Theme.Field,
		Text = "",
	})
	corner(selectButton, 11)

	local selectedLabel = makeText(selectButton, {
		Position = UDim2.fromOffset(8, 0),
		Size = UDim2.new(1, -28, 1, 0),
		Text = tostring(selected),
		TextColor3 = Theme.Text,
		Font = Enum.Font.GothamMedium,
		TextSize = 16,
	})

	local arrow = makeText(selectButton, {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -7, 0, 0),
		Size = UDim2.fromOffset(18, 36),
		Text = "v",
		TextColor3 = Theme.TextMuted,
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Center,
	})

	local optionsHolder = create("Frame", {
		Position = UDim2.new(0, 0, 0, 52),
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundTransparency = 1,
		Parent = frame,
	})

	padding(optionsHolder, 0, 0, 6, 0)

	create("UIListLayout", {
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = optionsHolder,
	})

	local api = {}
	local collapsedHeight = 52

	local function expandedHeight()
		return collapsedHeight + (#values * 40) + 6
	end

	local function disconnectOptions()
		for _, connection in ipairs(optionConnections) do
			connection:Disconnect()
		end
		table.clear(optionConnections)
	end

	local function setOpen(value)
		opened = value == true and #values > 0

		tween(frame, 0.18, {
			Size = UDim2.new(1, 0, 0, opened and expandedHeight() or collapsedHeight),
		})

		arrow.Text = opened and "^" or "v"
	end

	local function rebuildOptions()
		disconnectOptions()

		for _, child in ipairs(optionsHolder:GetChildren()) do
			if child:IsA("TextButton") then
				child:Destroy()
			end
		end

		optionsHolder.Size = UDim2.new(1, 0, 0, #values * 37 + 6)

		for index, value in ipairs(values) do
			local optionButton = makeButton(optionsHolder, {
				LayoutOrder = index,
				Size = UDim2.new(1, 0, 0, 37),
				BackgroundColor3 = Theme.Surface,
				Text = tostring(value),
				TextColor3 = Theme.TextMuted,
				Font = Enum.Font.GothamMedium,
				TextSize = 15,
				TextXAlignment = Enum.TextXAlignment.Left,
			})
			corner(optionButton, 11)
			padding(optionButton, 10, 10, 0, 0)

			bindHoverMotion(optionButton, {
				HoverScale = 1.008,
				PressScale = 0.99,
				EnterDuration = 0.12,
				LeaveDuration = 0.16,
			})

			table.insert(optionConnections, optionButton.MouseEnter:Connect(function()
				tween(optionButton, 0.12, {
					BackgroundColor3 = Theme.SurfaceHover,
					TextColor3 = Theme.Text,
				})
			end))

			table.insert(optionConnections, optionButton.MouseLeave:Connect(function()
				tween(optionButton, 0.16, {
					BackgroundColor3 = Theme.Surface,
					TextColor3 = Theme.TextMuted,
				})
			end))

			table.insert(optionConnections, optionButton.MouseButton1Click:Connect(function()
				api:Set(value, true)
			end))
		end

		if opened then
			frame.Size = UDim2.new(1, 0, 0, expandedHeight())
		end
	end

	function api:Set(value, fireCallback)
		if not table.find(values, value) then
			return false
		end

		selected = value
		selectedLabel.Text = tostring(value)
		setOpen(false)

		if fireCallback ~= false then
			task.spawn(callback, selected)
		end

		return true
	end

	function api:Get()
		return selected
	end

	function api:SetVisible(visible)
		frame.Visible = visible
		if not visible then
			setOpen(false)
		end
	end

	function api:SetValues(newValues, preferredValue, fireCallback)
		values = table.clone(newValues or {})

		local nextSelected = preferredValue
		if nextSelected == nil or not table.find(values, nextSelected) then
			if table.find(values, selected) then
				nextSelected = selected
			else
				nextSelected = values[1] or ""
			end
		end

		selected = nextSelected
		selectedLabel.Text = tostring(selected)
		setOpen(false)
		rebuildOptions()

		if fireCallback == true and selected ~= "" then
			task.spawn(callback, selected)
		end
	end

	function api:GetValues()
		return table.clone(values)
	end

	function api:Close()
		setOpen(false)
	end

	selectButton.MouseButton1Click:Connect(function()
		setOpen(not opened)
	end)

	bindSimpleHover(selectButton, Theme.Field, Theme.SurfaceHover)
	rebuildOptions()

	applyDirectRowHover(self, frame)

	return api
end

--========================================================
-- APP: WINDOW
--========================================================

local window = Library:CreateWindow({
	Name = "GACF_Library",
	Title = "Grow A Chicken Fighter",
	Size = UDim2.fromOffset(800, 500),
	MinimizedSize = UDim2.fromOffset(410, 58),
})

--========================================================
-- APP: TABS
--========================================================

local routineTab = window:AddTab(
	"Routine",
	""
)

local autoTab = window:AddTab(
	"Auto",
	""
)

local utilitiesTab = window:AddTab(
	"Utilities",
	""
)


--========================================================
-- ROUTINE TAB
-- Automation Cycle is mounted here later after all Auto
-- feature workers/functions have been defined.
--========================================================

--========================================================
-- AUTO PET CHICKEN
--========================================================

local autoPetEnabled = Config.AutoPetEnabled
local autoPetCPS = Config.AutoPetCPS
local autoPetWorkerToken = 0

local function getAutoPetDelay()
	return 0.5 / math.clamp(autoPetCPS, 1, 100)
end

local function invalidateAutoPetWorker()
	autoPetWorkerToken += 1
end

local function petChickenOnce()
	if not PetChicken
		or not PetChicken.Parent
		or not PetChicken:IsA("RemoteEvent") then

		return false, "PetChicken RemoteEvent unavailable"
	end

	local success, result = pcall(function()
		PetChicken:FireServer()
	end)

	if not success then
		return false, result
	end

	return true
end

local function startAutoPetWorker()
	invalidateAutoPetWorker()
	local token = autoPetWorkerToken

	if not autoPetEnabled then
		return
	end

	task.spawn(function()
		while autoPetEnabled
			and token == autoPetWorkerToken
			and window.ScreenGui.Parent do

			petChickenOnce()
			task.wait(getAutoPetDelay())
		end
	end)
end

local autoPetSection = autoTab:AddDropdownSection(
	"Auto Pet Chicken",
	false
)

local autoPetCpsSlider = autoPetSection:AddSlider({
	Title = "Pet CPS",
	Min = 1,
	Max = 100,
	Step = 1,
	Default = autoPetCPS,

	Callback = function(value)
		autoPetCPS = value
		Config.AutoPetCPS = value
		queueSaveConfig()
	end,
})

local autoPetToggle = autoPetSection:AddToggle({
	Title = "Auto Pet",
	Default = autoPetEnabled,

	Callback = function(enabled)
		autoPetEnabled = enabled
		Config.AutoPetEnabled = enabled
		queueSaveConfig()

		if enabled then
			startAutoPetWorker()
		else
			invalidateAutoPetWorker()
		end
	end,
})

--========================================================
-- AUTO REBIRTH
--========================================================

local autoRebirthEnabled = Config.AutoRebirthEnabled
local autoRebirthWorkerToken = 0
local AUTO_REBIRTH_DELAY = 0.5

local function invalidateAutoRebirthWorker()
	autoRebirthWorkerToken += 1
end

local function rebirthOnce()
	if not Rebirth
		or not Rebirth.Parent
		or not Rebirth:IsA("RemoteFunction") then

		return false, "Rebirth RemoteFunction unavailable"
	end

	local success, result = pcall(function()
		return Rebirth:InvokeServer()
	end)

	if not success or result == false then
		return false, result
	end

	return true, result
end

local function startAutoRebirthWorker()
	invalidateAutoRebirthWorker()
	local token = autoRebirthWorkerToken

	if not autoRebirthEnabled then
		return
	end

	task.spawn(function()
		while autoRebirthEnabled
			and token == autoRebirthWorkerToken
			and window.ScreenGui.Parent do

			rebirthOnce()
			task.wait(AUTO_REBIRTH_DELAY)
		end
	end)
end

local autoRebirthSection = autoTab:AddDirectGroup()

local autoRebirthToggle = autoRebirthSection:AddToggle({
	Title = "Auto Rebirth",
	Default = autoRebirthEnabled,

	Callback = function(enabled)
		autoRebirthEnabled = enabled
		Config.AutoRebirthEnabled = enabled
		queueSaveConfig()

		if enabled then
			startAutoRebirthWorker()
		else
			invalidateAutoRebirthWorker()
		end
	end,
})

--========================================================
-- AUTO UPGRADE FEEDER
--========================================================

local autoBuyFeederEnabled = Config.AutoBuyFeederEnabled
local autoUpgradeFeederCPS = Config.AutoUpgradeFeederCPS
local autoBuyFeederWorkerToken = 0

-- These values are feeder IDs inside the coop, not upgrade levels.
local AUTO_UPGRADE_FEEDER_MIN_ID = 1
local AUTO_UPGRADE_FEEDER_MAX_ID = 6

local function getAutoUpgradeFeederDelay()
	return 0.5 / math.clamp(autoUpgradeFeederCPS, 1, 50)
end

local function invalidateAutoBuyFeederWorker()
	autoBuyFeederWorkerToken += 1
end

local function upgradeFeederOnce(feederId)
	if not UpgradeGenerator
		or not UpgradeGenerator.Parent
		or not UpgradeGenerator:IsA("RemoteFunction") then

		return false, "UpgradeGenerator RemoteFunction unavailable"
	end

	local id = math.clamp(
		math.floor(
			tonumber(feederId)
				or AUTO_UPGRADE_FEEDER_MIN_ID
		),
		AUTO_UPGRADE_FEEDER_MIN_ID,
		AUTO_UPGRADE_FEEDER_MAX_ID
	)

	local success, result = pcall(function()
		return UpgradeGenerator:InvokeServer(id)
	end)

	if not success then
		return false, result
	end

	return true, result
end

local function startAutoBuyFeederWorker()
	invalidateAutoBuyFeederWorker()
	local token = autoBuyFeederWorkerToken

	if not autoBuyFeederEnabled then
		return
	end

	task.spawn(function()
		while autoBuyFeederEnabled
			and token == autoBuyFeederWorkerToken
			and window.ScreenGui.Parent do

			for feederId = AUTO_UPGRADE_FEEDER_MIN_ID, AUTO_UPGRADE_FEEDER_MAX_ID do
				if not autoBuyFeederEnabled
					or token ~= autoBuyFeederWorkerToken
					or not window.ScreenGui.Parent then

					break
				end

				upgradeFeederOnce(feederId)
				task.wait(getAutoUpgradeFeederDelay())
			end
		end
	end)
end

local autoBuyFeederSection = autoTab:AddDropdownSection(
	"Auto Upgrade Feeder",
	false
)

local autoUpgradeFeederCPSSlider = autoBuyFeederSection:AddSlider({
	Title = "Upgrade CPS",
	Min = 1,
	Max = 50,
	Step = 1,
	Default = autoUpgradeFeederCPS,

	Callback = function(value)
		autoUpgradeFeederCPS = value
		Config.AutoUpgradeFeederCPS = value
		queueSaveConfig()
	end,
})

local autoBuyFeederToggle = autoBuyFeederSection:AddToggle({
	Title = "Auto Upgrade",
	Default = autoBuyFeederEnabled,

	Callback = function(enabled)
		autoBuyFeederEnabled = enabled
		Config.AutoBuyFeederEnabled = enabled
		queueSaveConfig()

		if enabled then
			startAutoBuyFeederWorker()
		else
			invalidateAutoBuyFeederWorker()
		end
	end,
})

--========================================================
-- AUTO BUY FEEDER
--========================================================

local autoPurchaseFeederEnabled = Config.AutoPurchaseFeederEnabled
local autoPurchaseFeederWorkerToken = 0

-- Feeder IDs inside the Coop.
local AUTO_PURCHASE_FEEDER_MIN_ID = 1
local AUTO_PURCHASE_FEEDER_MAX_ID = 6
local AUTO_PURCHASE_FEEDER_STEP_DELAY = 0.075
local AUTO_PURCHASE_FEEDER_CYCLE_DELAY = 0.175

local function invalidateAutoPurchaseFeederWorker()
	autoPurchaseFeederWorkerToken += 1
end

local function purchaseFeederOnce(feederId)
	if not BuyGenerator
		or not BuyGenerator.Parent
		or not BuyGenerator:IsA("RemoteFunction") then

		return false, "BuyGenerator RemoteFunction unavailable"
	end

	local id = math.clamp(
		math.floor(
			tonumber(feederId)
				or AUTO_PURCHASE_FEEDER_MIN_ID
		),
		AUTO_PURCHASE_FEEDER_MIN_ID,
		AUTO_PURCHASE_FEEDER_MAX_ID
	)

	local success, result = pcall(function()
		return BuyGenerator:InvokeServer(id)
	end)

	if not success or result == false then
		return false, result
	end

	return true, result
end

local function startAutoPurchaseFeederWorker()
	invalidateAutoPurchaseFeederWorker()
	local token = autoPurchaseFeederWorkerToken

	if not autoPurchaseFeederEnabled then
		return
	end

	task.spawn(function()
		while autoPurchaseFeederEnabled
			and token == autoPurchaseFeederWorkerToken
			and window.ScreenGui.Parent do

			for feederId = AUTO_PURCHASE_FEEDER_MIN_ID, AUTO_PURCHASE_FEEDER_MAX_ID do
				if not autoPurchaseFeederEnabled
					or token ~= autoPurchaseFeederWorkerToken
					or not window.ScreenGui.Parent then

					break
				end

				purchaseFeederOnce(feederId)
				task.wait(AUTO_PURCHASE_FEEDER_STEP_DELAY)
			end

			if autoPurchaseFeederEnabled
				and token == autoPurchaseFeederWorkerToken
				and window.ScreenGui.Parent then

				task.wait(AUTO_PURCHASE_FEEDER_CYCLE_DELAY)
			end
		end
	end)
end

local autoPurchaseFeederSection = autoTab:AddDirectGroup()

local autoPurchaseFeederToggle = autoPurchaseFeederSection:AddToggle({
	Title = "Auto Buy Feeder",
	Default = autoPurchaseFeederEnabled,

	Callback = function(enabled)
		autoPurchaseFeederEnabled = enabled
		Config.AutoPurchaseFeederEnabled = enabled
		queueSaveConfig()

		if enabled then
			startAutoPurchaseFeederWorker()
		else
			invalidateAutoPurchaseFeederWorker()
		end
	end,
})

--========================================================
-- AUTO EXPAND COOP
--========================================================

local autoExpandCoopEnabled = Config.AutoExpandCoopEnabled
local autoExpandCoopWorkerToken = 0
local AUTO_EXPAND_COOP_DELAY = 0.5

local function invalidateAutoExpandCoopWorker()
	autoExpandCoopWorkerToken += 1
end

local function expandCoopOnce()
	if not ExpandCoop
		or not ExpandCoop.Parent
		or not ExpandCoop:IsA("RemoteFunction") then

		return false, "ExpandCoop RemoteFunction unavailable"
	end

	local success, result = pcall(function()
		return ExpandCoop:InvokeServer()
	end)

	if not success then
		return false, result
	end

	return true, result
end

local function startAutoExpandCoopWorker()
	invalidateAutoExpandCoopWorker()
	local token = autoExpandCoopWorkerToken

	if not autoExpandCoopEnabled then
		return
	end

	task.spawn(function()
		while autoExpandCoopEnabled
			and token == autoExpandCoopWorkerToken
			and window.ScreenGui.Parent do

			expandCoopOnce()
			task.wait(AUTO_EXPAND_COOP_DELAY)
		end
	end)
end

local autoExpandCoopSection = autoTab:AddDirectGroup()

local autoExpandCoopToggle = autoExpandCoopSection:AddToggle({
	Title = "Auto Expand Coop",
	Default = autoExpandCoopEnabled,

	Callback = function(enabled)
		autoExpandCoopEnabled = enabled
		Config.AutoExpandCoopEnabled = enabled
		queueSaveConfig()

		if enabled then
			startAutoExpandCoopWorker()
		else
			invalidateAutoExpandCoopWorker()
		end
	end,
})

local AutoTowerController = (function()
--========================================================
-- AUTO TOWER
--========================================================

local autoTowerEnabled = Config.AutoTowerEnabled
local autoTowerStartChoice = Config.AutoTowerStartChoice
local autoTowerSurrenderEnabled = Config.AutoTowerSurrenderEnabled
local autoTowerSurrenderFloor = Config.AutoTowerSurrenderFloor
local autoTowerNoThanksEnabled = Config.AutoTowerNoThanksEnabled

local autoTowerWorkerToken = 0
local autoTowerSurrenderWorkerToken = 0
local autoTowerNoThanksWorkerToken = 0
local autoTowerSurrenderTriggered = false

local AUTO_TOWER_START_RETRY_DELAY = 1.0
local AUTO_TOWER_SURRENDER_CHECK_DELAY = 0.10
local AUTO_TOWER_NO_THANKS_DELAY = 0.5

local TOWER_START_CHOICES = {
	"Priority FRONTIER",
	"Priority STRAIGHT",
	"Only BOTTOM",
}

local function invalidateAutoTowerWorker()
	autoTowerWorkerToken += 1
end

local function invalidateAutoTowerSurrenderWorker()
	autoTowerSurrenderWorkerToken += 1
end

local function invalidateAutoTowerNoThanksWorker()
	autoTowerNoThanksWorkerToken += 1
end

local function safeRequire(moduleScript)
	if not moduleScript or not moduleScript:IsA("ModuleScript") then
		return nil
	end

	local ok, result = pcall(require, moduleScript)
	if not ok then
		return nil
	end

	return result
end

local towerSupportCache = nil

local function getTowerSupport()
	if towerSupportCache ~= nil then
		return towerSupportCache
	end

	local playerScripts = player:FindFirstChild("PlayerScripts")
	if not playerScripts then
		return nil
	end

	local core = playerScripts:FindFirstChild("Core")
	local dataFolder = core and core:FindFirstChild("Data")
	local dataControllerModule = dataFolder
		and dataFolder:FindFirstChild("DataController")

	local uiFolder = playerScripts:FindFirstChild("UI")
	local twoD = uiFolder and uiFolder:FindFirstChild("2d")
	local shop = twoD and twoD:FindFirstChild("Shop")
	local shopWindow = shop and shop:FindFirstChild("ShopWindow")
	local catalogModule = shopWindow
		and shopWindow:FindFirstChild("catalog")

	local content = ReplicatedStorage:FindFirstChild("Content")
	local gameConfigModule = content
		and content:FindFirstChild("GameConfig")

	local coreStorage = ReplicatedStorage:FindFirstChild("Core")
	local numModule = coreStorage
		and coreStorage:FindFirstChild("Num")

	local dataController = safeRequire(dataControllerModule)
	local gameConfig = safeRequire(gameConfigModule)
	local num = safeRequire(numModule)
	local catalog = safeRequire(catalogModule)

	if not dataController
		or not gameConfig
		or not num
		or not catalog then

		return nil
	end

	towerSupportCache = {
		DataController = dataController,
		GameConfig = gameConfig,
		Num = num,
		Catalog = catalog,
	}

	return towerSupportCache
end

local function callDataGetter(fn)
	if type(fn) ~= "function" then
		return nil
	end

	local ok, result = pcall(fn)
	if not ok then
		return nil
	end

	return result
end

local function buildElevatorContext()
	local support = getTowerSupport()
	if not support then
		return nil
	end

	local dataController = support.DataController
	local gameConfig = support.GameConfig
	local num = support.Num
	local catalog = support.Catalog

	local premium = gameConfig.premium
	if type(premium) ~= "table"
		or type(premium.elevator) ~= "table" then

		return nil
	end

	if premium.elevator.enabled ~= true then
		return {
			applicable = false,
		}
	end

	local chicken = callDataGetter(dataController.chicken)
	local chickenLevel = 0

	if type(chicken) == "table" then
		chickenLevel = tonumber(chicken.level) or 0
	end

	local towerBest = tonumber(
		callDataGetter(dataController.towerBest)
			or 0
	) or 0

	local minFloor = tonumber(
		premium.elevator.minFloor
			or 1
	) or 1

	local applicable = chickenLevel >= 2
		and towerBest >= minFloor + 1

	if not applicable then
		return {
			applicable = false,
			towerBest = towerBest,
			minFloor = minFloor,
		}
	end

	local purchases = callDataGetter(dataController.purchases)
	local elevatorVip = false

	if type(purchases) == "table"
		and type(purchases.passes) == "table" then

		elevatorVip = purchases.passes.elevatorVip == true
	end

	local money = callDataGetter(dataController.money)

	local elevatorData = {
		restricted = true,
		prices = {},
		owned = {
			elevatorVip = elevatorVip,
		},
		towerBest = towerBest,
		rewardFloor = towerBest,
		boosts = {
			money = 0,
			corn = 0,
		},
	}

	local frontierFloor = towerBest + 1
	local warmUpFloor = math.max(
		minFloor,
		towerBest - 4
	)

	local function canAfford(floor)
		if money == nil
			or type(catalog.elevatorCost) ~= "function"
			or type(num.from) ~= "function"
			or type(num.ratio) ~= "function" then

			return false
		end

		local ok, affordable = pcall(function()
			local cost = catalog.elevatorCost(
				elevatorData,
				floor
			)

			local denominator = num.from(
				math.max(1, cost)
			)

			return num.ratio(
				money,
				denominator
			) >= 1
		end)

		return ok and affordable == true
	end

	return {
		applicable = true,
		towerBest = towerBest,
		minFloor = minFloor,
		frontierFloor = frontierFloor,
		warmUpFloor = warmUpFloor,
		frontierAffordable = canAfford(frontierFloor),
		warmUpAffordable = canAfford(warmUpFloor),
	}
end

local function invokeTowerElevator(floor)
	if not TowerElevator
		or not TowerElevator.Parent
		or not TowerElevator:IsA("RemoteFunction") then

		return false, nil
	end

	local ok, result = pcall(function()
		return TowerElevator:InvokeServer(floor)
	end)

	return ok, result
end

local function invokeTowerStart()
	if not TowerStart
		or not TowerStart.Parent
		or not TowerStart:IsA("RemoteFunction") then

		return false, nil
	end

	local ok, result = pcall(function()
		return TowerStart:InvokeServer()
	end)

	return ok, result
end

local function startTowerFromBottom()
	autoTowerSurrenderTriggered = false
	return invokeTowerStart()
end

local function startTowerPriorityFrontier()
	local context = buildElevatorContext()

	-- If elevator state cannot be resolved or elevator is not
	-- applicable, use the game's bottom-start path.
	if not context or context.applicable ~= true then
		return startTowerFromBottom()
	end

	local selectedFloor = nil

	if context.frontierAffordable then
		selectedFloor = context.frontierFloor
	elseif context.warmUpAffordable then
		selectedFloor = context.warmUpFloor
	end

	-- Neither paid elevator option is affordable.
	if selectedFloor == nil then
		return startTowerFromBottom()
	end

	local elevatorOk = invokeTowerElevator(selectedFloor)

	if not elevatorOk then
		-- Server rejected the preferred elevator choice.
		-- Try Warm Up if Frontier was attempted and Warm Up is
		-- independently affordable.
		if selectedFloor == context.frontierFloor
			and context.warmUpAffordable then

			local warmUpOk = invokeTowerElevator(
				context.warmUpFloor
			)

			if not warmUpOk then
				return startTowerFromBottom()
			end
		else
			return startTowerFromBottom()
		end
	end

	autoTowerSurrenderTriggered = false
	task.wait(0.10)
	return invokeTowerStart()
end

local function startTowerPriorityStraight()
	local context = buildElevatorContext()

	-- STRAIGHT means:
	-- try the direct FRONTIER floor (towerBest + 1) only.
	-- No Warm-up fallback. If the elevator path is unavailable
	-- or the server rejects it, fall back to Bottom.
	if not context or context.applicable ~= true then
		return startTowerFromBottom()
	end

	local directFloor = context.frontierFloor

	if not directFloor then
		return startTowerFromBottom()
	end

	local elevatorOk = invokeTowerElevator(directFloor)

	if not elevatorOk then
		return startTowerFromBottom()
	end

	autoTowerSurrenderTriggered = false
	task.wait(0.10)
	return invokeTowerStart()
end

local function startTowerOnce()
	if autoTowerStartChoice == "Only BOTTOM" then
		return startTowerFromBottom()
	end

	if autoTowerStartChoice == "Priority STRAIGHT" then
		return startTowerPriorityStraight()
	end

	return startTowerPriorityFrontier()
end

local function startAutoTowerWorker()
	invalidateAutoTowerWorker()
	local token = autoTowerWorkerToken

	if not autoTowerEnabled then
		return
	end

	task.spawn(function()
		while autoTowerEnabled
			and token == autoTowerWorkerToken
			and window.ScreenGui.Parent do

			startTowerOnce()
			task.wait(AUTO_TOWER_START_RETRY_DELAY)
		end
	end)
end

-- Current Tower floor discovery.
-- Strong sources are tried first. Values such as towerBest,
-- rewardFloor and elevator/start floors are deliberately rejected.
local CURRENT_FLOOR_KEYS = {
	floor = true,
	currentfloor = true,
	towerfloor = true,
	currenttowerfloor = true,
	towercurrentfloor = true,
	stage = true,
	currentstage = true,
	towerstage = true,
	currenttowerstage = true,
}

local CURRENT_FLOOR_REJECT_WORDS = {
	"best",
	"highest",
	"max",
	"reward",
	"elevator",
	"start",
	"frontier",
	"warmup",
	"record",
	"require",
	"needed",
	"target",
}

local towerDataClientCache = false

local function normalizeTowerKey(value)
	return string.lower(
		tostring(value or ""):gsub("[^%w]", "")
	)
end

local function rejectedCurrentFloorKey(normalized)
	for _, word in ipairs(CURRENT_FLOOR_REJECT_WORDS) do
		if string.find(normalized, word, 1, true) then
			return true
		end
	end
	return false
end

local function validTowerFloor(value)
	local floor = tonumber(value)
	if not floor then return nil end
	floor = math.floor(floor + 0.5)
	if floor < 1 or floor > 9999 then return nil end
	return floor
end

local function getTowerDataClient()
	if towerDataClientCache ~= false then
		return towerDataClientCache
	end
	local packages = ReplicatedStorage:FindFirstChild("Packages")
	local dataServiceModule = packages and packages:FindFirstChild("DataService")
	local dataService = safeRequire(dataServiceModule)
	local client = type(dataService) == "table" and dataService.client or nil
	towerDataClientCache = client
	return client
end

local function extractCurrentFloorFromTable(value, depth, visited)
	if type(value) ~= "table" then return nil end
	depth = depth or 0
	if depth > 5 then return nil end
	visited = visited or {}
	if visited[value] then return nil end
	visited[value] = true

	for key, child in pairs(value) do
		local normalized = normalizeTowerKey(key)
		if CURRENT_FLOOR_KEYS[normalized] and not rejectedCurrentFloorKey(normalized) then
			local floor = validTowerFloor(child)
			if floor then return floor end
		end
	end

	for key, child in pairs(value) do
		if type(child) == "table" then
			local normalized = normalizeTowerKey(key)
			local likelyCurrentState =
				string.find(normalized, "run", 1, true)
				or string.find(normalized, "battle", 1, true)
				or string.find(normalized, "state", 1, true)
				or string.find(normalized, "progress", 1, true)
				or (string.find(normalized, "tower", 1, true) and not rejectedCurrentFloorKey(normalized))
			if likelyCurrentState then
				local floor = extractCurrentFloorFromTable(child, depth + 1, visited)
				if floor then return floor end
			end
		end
	end
	return nil
end

local function floorFromTowerDataService()
	local client = getTowerDataClient()
	if type(client) ~= "table" or type(client.get) ~= "function" then return nil end
	local ok, towerState = pcall(function()
		return client:get({"tower"})
	end)
	if not ok then return nil end
	return extractCurrentFloorFromTable(towerState)
end

local function floorFromDataController()
	local support = getTowerSupport()
	local dataController = support and support.DataController
	if type(dataController) ~= "table" then return nil end
	for key, member in pairs(dataController) do
		local normalized = normalizeTowerKey(key)
		if type(member) == "function" and not rejectedCurrentFloorKey(normalized) then
			local looksLikeCurrentFloor = CURRENT_FLOOR_KEYS[normalized]
				or (string.find(normalized, "tower", 1, true) and string.find(normalized, "floor", 1, true))
				or (string.find(normalized, "tower", 1, true) and string.find(normalized, "stage", 1, true))
			if looksLikeCurrentFloor then
				local ok, result = pcall(member)
				if ok then
					local floor = validTowerFloor(result) or extractCurrentFloorFromTable(result)
					if floor then return floor end
				end
			end
		end
	end
	return nil
end

local function floorFromAttributes(instance)
	if not instance then return nil end
	for attributeName, attributeValue in pairs(instance:GetAttributes()) do
		local normalized = normalizeTowerKey(attributeName)
		if CURRENT_FLOOR_KEYS[normalized] and not rejectedCurrentFloorKey(normalized) then
			local floor = validTowerFloor(attributeValue)
			if floor then return floor end
		end
	end
	return nil
end

local function floorFromNamedValues(root)
	if not root then return nil end
	local rootFloor = floorFromAttributes(root)
	if rootFloor then return rootFloor end
	for _, object in ipairs(root:GetDescendants()) do
		local attrFloor = floorFromAttributes(object)
		if attrFloor then return attrFloor end
		if object:IsA("IntValue") or object:IsA("NumberValue") or object:IsA("StringValue") then
			local normalized = normalizeTowerKey(object.Name)
			if CURRENT_FLOOR_KEYS[normalized] and not rejectedCurrentFloorKey(normalized) then
				local floor = validTowerFloor(object.Value)
				if floor then return floor end
			end
		end
	end
	return nil
end

local function isTowerElevatorContext(instance)
	local current = instance
	for _ = 1, 8 do
		if not current then break end
		local normalized = normalizeTowerKey(current.Name)
		if string.find(normalized, "towerelevator", 1, true) or string.find(normalized, "elevator", 1, true) then
			return true
		end
		current = current.Parent
	end
	return false
end

local function hasActiveTowerContext(instance)
	local current = instance
	for _ = 1, 8 do
		if not current then break end
		local normalized = normalizeTowerKey(current.Name)
		if string.find(normalized, "tower", 1, true)
			and not string.find(normalized, "elevator", 1, true)
			and not string.find(normalized, "rebirth", 1, true) then
			return true
		end
		current = current.Parent
	end
	return false
end

local function floorFromTowerGui()
	for _, object in ipairs(playerGui:GetDescendants()) do
		if (object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox"))
			and not isTowerElevatorContext(object)
			and hasActiveTowerContext(object) then
			local content = tostring(object.Text or "")
			local floorText = content:match("[Ff][Ll][Oo][Oo][Rr]%s*[:#%-]?%s*(%d+)")
			if not floorText then
				floorText = content:match("[Ss][Tt][Aa][Gg][Ee]%s*[:#%-]?%s*(%d+)")
			end
			if floorText then
				local floor = validTowerFloor(floorText)
				if floor then return floor end
			end
			local normalizedName = normalizeTowerKey(object.Name)
			if CURRENT_FLOOR_KEYS[normalizedName] and not rejectedCurrentFloorKey(normalizedName) then
				local numericOnly = content:match("^%s*(%d+)%s*$")
				if numericOnly then
					local floor = validTowerFloor(numericOnly)
					if floor then return floor end
				end
			end
		end
	end
	return nil
end

local function getCurrentTowerFloor()
	local floor = floorFromTowerDataService()
	if floor then return floor end
	floor = floorFromDataController()
	if floor then return floor end
	floor = floorFromNamedValues(player)
	if floor then return floor end
	local character = player.Character
	if character then
		floor = floorFromNamedValues(character)
		if floor then return floor end
	end
	return floorFromTowerGui()
end

local function surrenderTowerOnce()
	if not TowerSurrender or not TowerSurrender.Parent or not TowerSurrender:IsA("RemoteFunction") then
		return false, nil
	end
	local ok, result = pcall(function()
		return TowerSurrender:InvokeServer()
	end)
	if not ok or result == false then return false, result end
	return true, result
end

local function startAutoTowerSurrenderWorker()
	invalidateAutoTowerSurrenderWorker()
	local token = autoTowerSurrenderWorkerToken
	if not autoTowerSurrenderEnabled then return end
	task.spawn(function()
		while autoTowerSurrenderEnabled and token == autoTowerSurrenderWorkerToken and window.ScreenGui.Parent do
			local targetFloor = math.clamp(math.floor(tonumber(autoTowerSurrenderFloor) or 60), 1, 9999)
			local currentFloor = getCurrentTowerFloor()
			if currentFloor then
				if currentFloor >= targetFloor then
					if not autoTowerSurrenderTriggered then
						local surrendered = surrenderTowerOnce()
						if surrendered then autoTowerSurrenderTriggered = true end
					end
				else
					autoTowerSurrenderTriggered = false
				end
			end
			task.wait(AUTO_TOWER_SURRENDER_CHECK_DELAY)
		end
	end)
end

local function declineTowerContinueOnce()
	if not TowerContinueDecline
		or not TowerContinueDecline.Parent
		or not TowerContinueDecline:IsA("RemoteEvent") then

		return false
	end

	local ok = pcall(function()
		TowerContinueDecline:FireServer()
	end)

	return ok
end

local function startAutoTowerNoThanksWorker()
	invalidateAutoTowerNoThanksWorker()
	local token = autoTowerNoThanksWorkerToken

	if not autoTowerNoThanksEnabled then
		return
	end

	task.spawn(function()
		while autoTowerNoThanksEnabled
			and token == autoTowerNoThanksWorkerToken
			and window.ScreenGui.Parent do

			declineTowerContinueOnce()
			task.wait(AUTO_TOWER_NO_THANKS_DELAY)
		end
	end)
end

local autoTowerSection = autoTab:AddDropdownSection(
	"Auto Tower",
	false
)

local autoTowerChoiceDropdown = autoTowerSection:AddDropdown({
	Title = "Start Choice",
	Values = TOWER_START_CHOICES,
	Default = autoTowerStartChoice,

	Callback = function(value)
		autoTowerStartChoice = value
		Config.AutoTowerStartChoice = value
		queueSaveConfig()
	end,
})

local autoTowerMainToggle = autoTowerSection:AddToggle({
	Title = "Auto Tower",
	Default = autoTowerEnabled,

	Callback = function(enabled)
		autoTowerEnabled = enabled
		Config.AutoTowerEnabled = enabled
		queueSaveConfig()

		if enabled then
			if Config.AutomationEnabled then
				invalidateAutoTowerWorker()
			else
				startAutoTowerWorker()
			end
		else
			invalidateAutoTowerWorker()
		end
	end,
})

local autoTowerSurrenderFloorInput = autoTowerSection:AddNumberInput({
	Title = "Surrender Floor",
	Min = 1,
	Max = 9999,
	Default = autoTowerSurrenderFloor,

	Callback = function(value)
		autoTowerSurrenderFloor = value
		autoTowerSurrenderTriggered = false
		Config.AutoTowerSurrenderFloor = value
		queueSaveConfig()
	end,
})

local autoTowerSurrenderToggle = autoTowerSection:AddToggle({
	Title = "Auto Surrender",
	Default = autoTowerSurrenderEnabled,

	Callback = function(enabled)
		autoTowerSurrenderEnabled = enabled
		Config.AutoTowerSurrenderEnabled = enabled
		autoTowerSurrenderTriggered = false
		queueSaveConfig()

		if enabled then
			if Config.AutomationEnabled then
				invalidateAutoTowerSurrenderWorker()
			else
				startAutoTowerSurrenderWorker()
			end
		else
			invalidateAutoTowerSurrenderWorker()
		end
	end,
})

local autoTowerNoThanksToggle = autoTowerSection:AddToggle({
	Title = "Auto No Thanks Tower",
	Default = autoTowerNoThanksEnabled,

	Callback = function(enabled)
		autoTowerNoThanksEnabled = enabled
		Config.AutoTowerNoThanksEnabled = enabled
		queueSaveConfig()

		if enabled then
			startAutoTowerNoThanksWorker()
		else
			invalidateAutoTowerNoThanksWorker()
		end
	end,
})


	return {
		StartFromConfig = function()
			if autoTowerEnabled
				and not Config.AutomationEnabled then

				startAutoTowerWorker()
			end

			-- Dynamic Automation surrender owns the threshold while
			-- Automation is ON; otherwise use the manual Surrender Floor.
			if autoTowerSurrenderEnabled
				and not Config.AutomationEnabled then

				startAutoTowerSurrenderWorker()
			end

			if autoTowerNoThanksEnabled then
				startAutoTowerNoThanksWorker()
			end
		end,

		PauseAutomationWorkers = function()
			invalidateAutoTowerWorker()
			invalidateAutoTowerSurrenderWorker()
			invalidateAutoTowerNoThanksWorker()
		end,

		ResumeConfiguredWorkers = function()
			if autoTowerEnabled
				and not Config.AutomationEnabled then

				startAutoTowerWorker()
			end

			if autoTowerSurrenderEnabled
				and not Config.AutomationEnabled then

				startAutoTowerSurrenderWorker()
			end

			if autoTowerNoThanksEnabled then
				startAutoTowerNoThanksWorker()
			end
		end,

		ForceAutomationOn = function()
			autoTowerEnabled = true
			autoTowerSurrenderEnabled = true
			autoTowerNoThanksEnabled = true
			autoTowerSurrenderTriggered = false

			Config.AutoTowerEnabled = true
			Config.AutoTowerSurrenderEnabled = true
			Config.AutoTowerNoThanksEnabled = true

			autoTowerMainToggle:Set(true, false)
			autoTowerSurrenderToggle:Set(true, false)
			autoTowerNoThanksToggle:Set(true, false)

			-- Routine is the ONLY owner of TowerStart timing.
			invalidateAutoTowerWorker()

			-- Dynamic Rebirth Runtime owns surrender threshold.
			invalidateAutoTowerSurrenderWorker()

			-- Auto No Thanks stays continuously active.
			startAutoTowerNoThanksWorker()
		end,

		ForceAutomationOff = function()
			autoTowerEnabled = false
			autoTowerSurrenderEnabled = false
			autoTowerNoThanksEnabled = false
			autoTowerSurrenderTriggered = false

			Config.AutoTowerEnabled = false
			Config.AutoTowerSurrenderEnabled = false
			Config.AutoTowerNoThanksEnabled = false

			autoTowerMainToggle:Set(false, false)
			autoTowerSurrenderToggle:Set(false, false)
			autoTowerNoThanksToggle:Set(false, false)

			invalidateAutoTowerWorker()
			invalidateAutoTowerSurrenderWorker()
			invalidateAutoTowerNoThanksWorker()
		end,

		StartOnce = function() return startTowerOnce() end,
		SurrenderOnce = function() return surrenderTowerOnce() end,
		DeclineOnce = function() return declineTowerContinueOnce() end,
		GetCurrentFloor = function() return getCurrentTowerFloor() end,

		Stop = function()
			autoTowerEnabled = false
			autoTowerSurrenderEnabled = false
			autoTowerNoThanksEnabled = false
			invalidateAutoTowerWorker()
			invalidateAutoTowerSurrenderWorker()
			invalidateAutoTowerNoThanksWorker()
		end,
	}
end)()

--========================================================
-- UTILITIES TAB
--========================================================

local godModeEnabled = Config.GodMode
local noClipEnabled = Config.NoClip
local antiAfkEnabled = Config.AntiAFK

local initialSpeedHumanoid = player.Character
	and player.Character:FindFirstChildOfClass("Humanoid")

local selectedWalkSpeed = Config.WalkSpeed

local currentDefaultWalkSpeed = initialSpeedHumanoid
	and initialSpeedHumanoid.WalkSpeed
	or nil

local walkSpeedOverrideEnabled = Config.WalkSpeedOverride
local godState = setmetatable({}, {__mode = "k"})
local collisionState = setmetatable({}, {__mode = "k"})
local utilityConnections = {}

local function currentCharacter()
	return player.Character
end

local function currentHumanoid()
	local character = currentCharacter()
	if not character then
		return nil
	end

	return character:FindFirstChildOfClass("Humanoid")
end

local function captureWalkSpeed(humanoid)
	if humanoid and currentDefaultWalkSpeed == nil then
		currentDefaultWalkSpeed = humanoid.WalkSpeed
	end
end

local function applyWalkSpeed()
	if not walkSpeedOverrideEnabled then
		return
	end

	local humanoid = currentHumanoid()
	if not humanoid then
		return
	end

	captureWalkSpeed(humanoid)

	humanoid.WalkSpeed = math.clamp(
		tonumber(selectedWalkSpeed) or humanoid.WalkSpeed,
		1,
		100
	)
end

local function restoreWalkSpeed()
	local humanoid = currentHumanoid()

	if humanoid and currentDefaultWalkSpeed ~= nil then
		humanoid.WalkSpeed = currentDefaultWalkSpeed
	end
end

local function rememberGodState(humanoid)
	if not humanoid or godState[humanoid] then
		return
	end

	local deadStateEnabled = true
	pcall(function()
		deadStateEnabled = humanoid:GetStateEnabled(Enum.HumanoidStateType.Dead)
	end)

	godState[humanoid] = {
		BreakJointsOnDeath = humanoid.BreakJointsOnDeath,
		DeadStateEnabled = deadStateEnabled,
	}
end

local function applyGodMode()
	if not godModeEnabled then
		return
	end

	local humanoid = currentHumanoid()
	if not humanoid then
		return
	end

	rememberGodState(humanoid)

	pcall(function()
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
	end)

	humanoid.BreakJointsOnDeath = false

	if humanoid.MaxHealth > 0 and humanoid.Health < humanoid.MaxHealth then
		humanoid.Health = humanoid.MaxHealth
	end
end

local function restoreGodMode()
	for humanoid, state in pairs(godState) do
		if humanoid and humanoid.Parent then
			pcall(function()
				humanoid:SetStateEnabled(
					Enum.HumanoidStateType.Dead,
					state.DeadStateEnabled
				)
			end)

			humanoid.BreakJointsOnDeath = state.BreakJointsOnDeath
		end
	end

	table.clear(godState)
end

local function applyNoClip()
	if not noClipEnabled then
		return
	end

	local character = currentCharacter()
	if not character then
		return
	end

	for _, descendant in ipairs(character:GetDescendants()) do
		if descendant:IsA("BasePart") then
			if collisionState[descendant] == nil then
				collisionState[descendant] = descendant.CanCollide
			end

			if descendant.CanCollide then
				descendant.CanCollide = false
			end
		end
	end
end

local function restoreNoClip()
	for part, originalCanCollide in pairs(collisionState) do
		if part and part.Parent then
			part.CanCollide = originalCanCollide
		end
	end

	table.clear(collisionState)
end

local function playerChoices()
	local values = {"Select Player"}
	local names = {}

	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		if otherPlayer ~= player then
			table.insert(names, otherPlayer.Name)
		end
	end

	table.sort(names, function(a, b)
		return string.lower(a) < string.lower(b)
	end)

	for _, name in ipairs(names) do
		table.insert(values, name)
	end

	return values
end

local function teleportToPlayer(playerName)
	if playerName == "Select Player" then
		return
	end

	local targetPlayer = Players:FindFirstChild(playerName)
	if not targetPlayer then
		return
	end

	local character = currentCharacter()
	local targetCharacter = targetPlayer.Character

	if not character or not targetCharacter then
		return
	end

	local targetRoot = targetCharacter:FindFirstChild("HumanoidRootPart")
	if not targetRoot then
		return
	end

	character:PivotTo(targetRoot.CFrame * CFrame.new(0, 0, 3))
end

local function performAntiAfkInput()
	if not antiAfkEnabled then
		return
	end

	pcall(function()
		VirtualUser:CaptureController()

		local camera = workspace.CurrentCamera
		local cameraCFrame = camera and camera.CFrame or CFrame.new()

		VirtualUser:Button2Down(
			Vector2.new(0, 0),
			cameraCFrame
		)

		task.wait(0.05)

		VirtualUser:Button2Up(
			Vector2.new(0, 0),
			cameraCFrame
		)
	end)
end

table.insert(
	utilityConnections,
	player.Idled:Connect(performAntiAfkInput)
)

--========================================================
-- UTILITIES UI
-- Single-action features stay flat.
-- Only the control itself is a dropdown when selection
-- is actually required.
--========================================================

local utilitiesSection = utilitiesTab:AddDirectGroup()

-- 1. Teleport to Player
local playerDropdown = utilitiesSection:AddDropdown({
	Title = "Teleport to Player",
	Values = playerChoices(),
	Default = "Select Player",
	Callback = function(value)
		teleportToPlayer(value)
	end,
})

local function refreshPlayerDropdown()
	local currentSelection = playerDropdown:Get()
	local values = playerChoices()

	if not table.find(values, currentSelection) then
		currentSelection = "Select Player"
	end

	playerDropdown:SetValues(values, currentSelection, false)
end

-- 2. God Mode
utilitiesSection:AddToggle({
	Title = "God Mode",
	Default = godModeEnabled,
	Callback = function(enabled)
		godModeEnabled = enabled
		Config.GodMode = enabled
		queueSaveConfig()

		if enabled then
			applyGodMode()
		else
			restoreGodMode()
		end
	end,
})

-- 3. No Clip
utilitiesSection:AddToggle({
	Title = "No Clip",
	Default = noClipEnabled,
	Callback = function(enabled)
		noClipEnabled = enabled
		Config.NoClip = enabled
		queueSaveConfig()

		if enabled then
			applyNoClip()
		else
			restoreNoClip()
		end
	end,
})

-- 4. Anti-AFK
utilitiesSection:AddToggle({
	Title = "Anti-AFK",
	Default = antiAfkEnabled,
	Callback = function(enabled)
		antiAfkEnabled = enabled
		Config.AntiAFK = enabled
		queueSaveConfig()
	end,
})

-- 5. Walk Speed
utilitiesSection:AddSlider({
	Title = "Walk Speed",
	Min = 1,
	Max = 100,
	Step = 1,
	Default = selectedWalkSpeed,

	Callback = function(value)
		selectedWalkSpeed = value
		walkSpeedOverrideEnabled = true

		Config.WalkSpeed = value
		Config.WalkSpeedOverride = true
		queueSaveConfig()

		applyWalkSpeed()
	end,
})

-- Runtime maintenance for character utilities.
table.insert(utilityConnections, RunService.Heartbeat:Connect(function()
	if godModeEnabled then
		applyGodMode()
	end
end))

table.insert(utilityConnections, RunService.Stepped:Connect(function()
	if noClipEnabled then
		applyNoClip()
	end
end))

table.insert(utilityConnections, player.CharacterAdded:Connect(function(character)
	currentDefaultWalkSpeed = nil
	table.clear(collisionState)

	task.spawn(function()
		local humanoid = character:WaitForChild("Humanoid", 10)
		if not humanoid then
			return
		end

		currentDefaultWalkSpeed = humanoid.WalkSpeed

		if walkSpeedOverrideEnabled then
			applyWalkSpeed()
		end

		if godModeEnabled then
			applyGodMode()
		end
	end)
end))

table.insert(utilityConnections, Players.PlayerAdded:Connect(function()
	task.delay(0.05, refreshPlayerDropdown)
end))

table.insert(utilityConnections, Players.PlayerRemoving:Connect(function()
	task.delay(0.05, refreshPlayerDropdown)
end))

local initialHumanoid = currentHumanoid()
if initialHumanoid then
	currentDefaultWalkSpeed = initialHumanoid.WalkSpeed
end

--========================================================
-- AUTO OPEN EGG LOGIC
--========================================================

local autoEggEnabled = Config.AutoOpenEnabled
local autoEggMode = Config.AutoOpenMode
local selectedEgg = Config.SelectedEgg
local workerToken = 0

local function hatchEgg(eggName)
	if not HatchEgg
		or not HatchEgg.Parent
		or not HatchEgg:IsA("RemoteFunction") then
		return false, "HatchEgg RemoteFunction unavailable"
	end

	local success, result = pcall(function()
		return HatchEgg:InvokeServer(eggName)
	end)

	if not success then
		return false, result
	end

	return true, result
end

local function invalidateWorker()
	workerToken += 1
end

--========================================================
-- AUTO TAB UI
--========================================================

local eggSection = autoTab:AddDropdownSection(
	"Auto Open Egg",
	false
)

local autoStatus = {
	Set = function() end,
}

local selectedEggDropdown

local function updateStatus()
	if not autoEggEnabled then
		autoStatus:Set("Stopped", false)
		return
	end

	if autoEggMode == "ALL" then
		autoStatus:Set("Running · ALL", true)
	else
		autoStatus:Set("Running · " .. selectedEgg, true)
	end
end

local function startWorker()
	invalidateWorker()
	local token = workerToken

	if not autoEggEnabled then
		updateStatus()
		return
	end

	task.spawn(function()
		while autoEggEnabled
			and token == workerToken
			and window.ScreenGui.Parent do

			if autoEggMode == "ALL" then
				for _, eggName in ipairs(EGG_TYPES) do
					if not autoEggEnabled
						or token ~= workerToken
						or not window.ScreenGui.Parent then
						break
					end

					autoStatus:Set("Opening · " .. eggName, true)
					hatchEgg(eggName)
					task.wait(AUTO_EGG_DELAY)
				end
			else
				autoStatus:Set("Opening · " .. selectedEgg, true)
				hatchEgg(selectedEgg)
				task.wait(AUTO_EGG_DELAY)
			end
		end

		if token == workerToken then
			updateStatus()
		end
	end)
end

local modeDropdown = eggSection:AddDropdown({
	Title = "Open Mode",
	Values = {
		"ALL",
		"Selected",
	},
	Default = autoEggMode,

	Callback = function(value)
		autoEggMode = value
		Config.AutoOpenMode = value
		queueSaveConfig()

		if selectedEggDropdown then
			selectedEggDropdown:SetVisible(value == "Selected")
		end

		updateStatus()

		if autoEggEnabled then
			startWorker()
		end
	end,
})

selectedEggDropdown = eggSection:AddDropdown({
	Title = "Selected Egg",
	Values = EGG_TYPES,
	Default = selectedEgg,

	Callback = function(value)
		selectedEgg = value
		Config.SelectedEgg = value
		queueSaveConfig()

		updateStatus()

		if autoEggEnabled and autoEggMode == "Selected" then
			startWorker()
		end
	end,
})

selectedEggDropdown:SetVisible(autoEggMode == "Selected")

local autoToggle = eggSection:AddToggle({
	Title = "Auto Open",
	Default = autoEggEnabled,

	Callback = function(enabled)
		autoEggEnabled = enabled
		Config.AutoOpenEnabled = enabled
		queueSaveConfig()

		if enabled then
			updateStatus()
			startWorker()
		else
			invalidateWorker()
			updateStatus()
		end
	end,
})

--========================================================
-- AUTO COLLECT EGG
-- NO TELEPORT / TOUCH TRIGGER
--========================================================

local autoCollectEnabled = Config.AutoCollectEnabled
local collectWorkerToken = 0

local COLLECT_SCAN_DELAY = 0.10
local COLLECT_TOUCH_DELAY = 0.025
local COLLECT_RETRY_DELAY = 0.10

local function invalidateCollectWorker()
	collectWorkerToken += 1
end

local function getCharacterRoot()
	local character = player.Character
	if not character then
		return nil
	end

	return character:FindFirstChild("HumanoidRootPart")
end

local function getOwnedNestEggs(rootPart)
	local eggs = {}

	for _, instance in ipairs(CollectionService:GetTagged("NestEgg")) do
		if instance:IsA("BasePart")
			and instance.Parent
			and instance:GetAttribute("owner") == player.UserId then

			table.insert(eggs, instance)
		end
	end

	-- Urutkan berdasarkan jarak hanya untuk prioritas.
	-- Tidak ada teleport / perpindahan karakter.
	if rootPart then
		table.sort(eggs, function(a, b)
			if not a.Parent then
				return false
			end

			if not b.Parent then
				return true
			end

			return (a.Position - rootPart.Position).Magnitude
				< (b.Position - rootPart.Position).Magnitude
		end)
	end

	return eggs
end

local function getFireTouchInterest()
	-- Executor biasanya menyediakan firetouchinterest sebagai global.
	local env = nil

	if typeof(getgenv) == "function" then
		local ok, result = pcall(getgenv)

		if ok and type(result) == "table" then
			env = result
		end
	end

	if env and typeof(env.firetouchinterest) == "function" then
		return env.firetouchinterest
	end

	if typeof(firetouchinterest) == "function" then
		return firetouchinterest
	end

	return nil
end

local function triggerNestEggTouch(rootPart, eggPart)
	if not rootPart
		or not rootPart.Parent
		or not eggPart
		or not eggPart.Parent then

		return false, "invalidPart"
	end

	local touchFunction = getFireTouchInterest()

	if not touchFunction then
		return false, "firetouchinterestUnavailable"
	end

	-- Trigger begin / end touch tanpa mengubah CFrame player.
	local beginSuccess = pcall(function()
		touchFunction(rootPart, eggPart, 0)
	end)

	task.wait(COLLECT_TOUCH_DELAY)

	local endSuccess = pcall(function()
		touchFunction(rootPart, eggPart, 1)
	end)

	return beginSuccess and endSuccess
end

local collectSection = autoTab:AddDirectGroup()

local collectStatus = {
	Set = function() end,
}

local collectCountStatus = {
	Set = function() end,
}

local collectMethodStatus = {
	Set = function() end,
}

local function updateCollectIdleStatus()
	if autoCollectEnabled then
		collectStatus:Set("Scanning", true)
	else
		collectStatus:Set("Stopped", false)
	end
end

local function startCollectWorker()
	invalidateCollectWorker()

	local token = collectWorkerToken

	if not autoCollectEnabled then
		updateCollectIdleStatus()
		return
	end

	task.spawn(function()
		while autoCollectEnabled
			and token == collectWorkerToken
			and window.ScreenGui.Parent do

			local rootPart = getCharacterRoot()

			if not rootPart then
				collectStatus:Set("Waiting for character", false)
				collectCountStatus:Set("0", false)

				task.wait(0.5)
				continue
			end

			local ownedEggs = getOwnedNestEggs(rootPart)

			collectCountStatus:Set(
				tostring(#ownedEggs),
				#ownedEggs > 0
			)

			if #ownedEggs == 0 then
				collectStatus:Set("Scanning", true)

				task.wait(COLLECT_SCAN_DELAY)
				continue
			end

			local touchAvailable = getFireTouchInterest() ~= nil

			if not touchAvailable then
				collectStatus:Set(
					"Touch trigger unavailable",
					false
				)

				task.wait(1)
				continue
			end

			for _, egg in ipairs(ownedEggs) do
				if not autoCollectEnabled
					or token ~= collectWorkerToken
					or not window.ScreenGui.Parent then

					break
				end

				if not egg
					or not egg.Parent
					or not CollectionService:HasTag(egg, "NestEgg")
					or egg:GetAttribute("owner") ~= player.UserId then

					continue
				end

				local tier = egg:GetAttribute("tier")

				collectStatus:Set(
					"Collecting · " .. tostring(tier or "egg"),
					true
				)

				local triggered = triggerNestEggTouch(
					rootPart,
					egg
				)

				if triggered then
					-- Beri server/client sedikit waktu untuk
					-- menghapus tag / instance setelah pickup.
					local started = os.clock()

					while egg.Parent
						and CollectionService:HasTag(egg, "NestEgg")
						and os.clock() - started < 0.65
						and autoCollectEnabled
						and token == collectWorkerToken do

						task.wait(0.04)
					end

					if not egg.Parent
						or not CollectionService:HasTag(egg, "NestEgg") then

						collectStatus:Set("Collected", true)
					else
						collectStatus:Set("Retrying", true)
					end
				else
					collectStatus:Set(
						"Touch failed",
						false
					)
				end

				task.wait(COLLECT_RETRY_DELAY)
			end

			task.wait(COLLECT_SCAN_DELAY)
		end

		if token == collectWorkerToken then
			updateCollectIdleStatus()
		end
	end)
end

local autoCollectToggle = collectSection:AddToggle({
	Title = "Auto Collect Egg",
	Default = autoCollectEnabled,

	Callback = function(enabled)
		autoCollectEnabled = enabled
		Config.AutoCollectEnabled = enabled
		queueSaveConfig()

		if enabled then
			updateCollectIdleStatus()
			startCollectWorker()
		else
			invalidateCollectWorker()

			collectStatus:Set(
				"Stopped",
				false
			)
		end
	end,
})

--========================================================
-- ROUTINE AUTOMATION
-- Uses the existing ON/OFF states and settings from Auto tab.
--========================================================

window.AutomationController = (function()
	local automationEnabled = Config.AutomationEnabled
	local towerLoopDelay = Config.AutomationTowerDelay
	local automationWorkerToken = 0
	local requiredRebirthFloorCache = nil
	local lastKnownRebirthCount = nil
	local waitingForRebirth = false
	local rebirthCountBeforeSurrender = nil
	local rebirthRequirementBeforeSurrender = nil
	local nextTowerStartAt = 0
	local towerWasActive = false
	local postRebirthHoldUntil = 0
	local lastRebirthAttemptAt = 0
	local lastCoopOrderAt = 0
	local coopStableSince = nil
	local surrenderRequestedAt = 0
	local rebirthAttemptedAfterReturn = false

	local AUTOMATION_POLL_DELAY = 0.10
	local AUTOMATION_REBIRTH_RETRY_DELAY = 0.5
	local AUTOMATION_NO_THANKS_DELAY = 0.5
	local AUTOMATION_POST_REBIRTH_HOLD = 1.0
	local AUTOMATION_COOP_ORDER_DELAY = 0.25
	local AUTOMATION_COOP_STABLE_DELAY = 0.50
	local AUTOMATION_SURRENDER_GRACE = 0.50

	local function getAutomationTowerLoopDelay()
		return math.clamp(
			tonumber(towerLoopDelay) or 5,
			1,
			200
		)
	end

	local function normalizeKey(value)
		return string.lower(tostring(value or ""):gsub("[^%w]", ""))
	end

	local function safeRequireAutomation(moduleScript)
		if not moduleScript or not moduleScript:IsA("ModuleScript") then return nil end
		local ok, result = pcall(require, moduleScript)
		if not ok then return nil end
		return result
	end

	local dataClientCache = false
	local function getDataClient()
		if dataClientCache ~= false then return dataClientCache end
		local packages = ReplicatedStorage:FindFirstChild("Packages")
		local dataServiceModule = packages and packages:FindFirstChild("DataService")
		local dataService = safeRequireAutomation(dataServiceModule)
		local client = type(dataService) == "table" and dataService.client or nil
		dataClientCache = client
		return client
	end

	local function getClientPath(path)
		local client = getDataClient()
		if type(client) ~= "table" or type(client.get) ~= "function" then return nil end
		local ok, result = pcall(function() return client:get(path) end)
		if not ok then return nil end
		return result
	end

	local function validFloor(value)
		local floor = tonumber(value)
		if not floor then return nil end
		floor = math.floor(floor + 0.5)
		if floor < 1 or floor > 9999 then return nil end
		return floor
	end

	local function getTowerBestFloor()
		local towerState = getClientPath({"tower"})
		if type(towerState) ~= "table" then return nil end
		return validFloor(
			towerState.best
				or towerState.bestFloor
				or towerState.highest
				or towerState.highestFloor
		)
	end

	local function rebirthCountFromGui()
		for _, object in ipairs(playerGui:GetDescendants()) do
			if object:IsA("TextLabel")
				or object:IsA("TextButton")
				or object:IsA("TextBox") then

				local content = tostring(object.Text or "")

				local countText = content:match(
					"[Rr][Ee][Bb][Ii][Rr][Tt][Hh]%s*#?%s*(%d+)"
				)

				if countText then
					local count = tonumber(countText)

					if count then
						return math.max(
							0,
							math.floor(count + 0.5)
						)
					end
				end
			end
		end

		return nil
	end

	local function getRebirthCount()
		local state = getClientPath({"rebirth"})

		if type(state) == "number" then
			return math.max(
				0,
				math.floor(state + 0.5)
			)
		end

		if type(state) == "table" then
			local count = tonumber(
				state.count
					or state.rebirthCount
					or state.rebirths
					or state.level
					or state.index
			)

			if count then
				return math.max(
					0,
					math.floor(count + 0.5)
				)
			end
		end

		return rebirthCountFromGui()
	end

	local REQUIREMENT_KEYS = {
		floorreq = true, floorrequired = true, requiredfloor = true,
		requiredtowerfloor = true, towerfloorreq = true,
		towerfloorrequired = true, towerrequiredfloor = true,
		neededfloor = true, needfloor = true, targetfloor = true,
		rebirthfloorreq = true, rebirthrequiredfloor = true,
	}
	local REQUIREMENT_WORDS = {"req", "require", "required", "need", "needed", "target", "gate"}
	local REQUIREMENT_REJECT_WORDS = {"current", "best", "highest", "progress", "reward", "elevator", "start"}

	local function isRequirementKey(normalized)
		if REQUIREMENT_KEYS[normalized] then return true end
		if not string.find(normalized, "floor", 1, true) then return false end
		for _, word in ipairs(REQUIREMENT_REJECT_WORDS) do
			if string.find(normalized, word, 1, true) then return false end
		end
		for _, word in ipairs(REQUIREMENT_WORDS) do
			if string.find(normalized, word, 1, true) then return true end
		end
		return false
	end

	local function extractRequirementFromTable(value, depth, visited)
		if type(value) ~= "table" then return nil end
		depth = depth or 0
		if depth > 6 then return nil end
		visited = visited or {}
		if visited[value] then return nil end
		visited[value] = true
		for key, child in pairs(value) do
			local normalized = normalizeKey(key)
			if isRequirementKey(normalized) then
				local floor = validFloor(child)
				if floor then return floor end
			end
		end
		for key, child in pairs(value) do
			if type(child) == "table" then
				local normalized = normalizeKey(key)
				local likely = string.find(normalized, "rebirth", 1, true)
					or string.find(normalized, "require", 1, true)
					or string.find(normalized, "gate", 1, true)
					or string.find(normalized, "progress", 1, true)
				if likely then
					local floor = extractRequirementFromTable(child, depth + 1, visited)
					if floor then return floor end
				end
			end
		end
		return nil
	end

	local function requirementFromData()
		local floor = extractRequirementFromTable(getClientPath({"rebirth"}))
		if floor then return floor end
		local root = getClientPath({})
		if type(root) == "table" then
			local branch = root.rebirth or root.Rebirth
			floor = extractRequirementFromTable(branch)
			if floor then return floor end
		end
		return nil
	end

	local function requirementFromAttributes()
		for _, instance in ipairs({player, player.Character}) do
			if instance then
				for name, value in pairs(instance:GetAttributes()) do
					if isRequirementKey(normalizeKey(name)) then
						local floor = validFloor(value)
						if floor then return floor end
					end
				end
			end
		end
		return nil
	end

	local function ancestorHasRebirthContext(instance)
		local current = instance
		for _ = 1, 8 do
			if not current then break end
			if string.find(normalizeKey(current.Name), "rebirth", 1, true) then return true end
			current = current.Parent
		end
		return false
	end

	local function nearbyHasRebirthTitle(instance)
		local current = instance
		for _ = 1, 5 do
			if not current then break end
			local checked = 0
			for _, descendant in ipairs(current:GetDescendants()) do
				checked += 1
				if checked > 80 then break end
				if descendant:IsA("TextLabel") or descendant:IsA("TextButton") then
					if string.find(string.upper(tostring(descendant.Text or "")), "REBIRTH", 1, true) then
						return true
					end
				end
			end
			current = current.Parent
		end
		return false
	end

	local function requirementFromRebirthGui()
		local fallback = nil
		for _, object in ipairs(playerGui:GetDescendants()) do
			if object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox") then
				local a, b = tostring(object.Text or ""):match("(%d+)%s*/%s*(%d+)")
				if a and b then
					local currentFloor, requiredFloor = validFloor(a), validFloor(b)
					if currentFloor and requiredFloor then
						if ancestorHasRebirthContext(object) then return requiredFloor end
						if nearbyHasRebirthTitle(object) then fallback = requiredFloor end
					end
				end
			end
		end
		return fallback
	end


	local function isGuiVisible(object)
		local current = object
		while current and current ~= playerGui do
			if current:IsA("GuiObject") and current.Visible == false then
				return false
			end
			if current:IsA("ScreenGui") and current.Enabled == false then
				return false
			end
			current = current.Parent
		end
		return true
	end

	local function hasClickableAncestor(object)
		local current = object

		for _ = 1, 6 do
			if not current then
				break
			end

			if current:IsA("TextButton")
				or current:IsA("ImageButton") then

				return true
			end

			current = current.Parent
		end

		return false
	end

	local function getRebirthUiState()
		local state = {
			panelVisible = false,
			needsRoosterHome = false,
			rebirthReady = false,
			progressFloor = nil,
			requiredFloor = nil,
		}

		for _, object in ipairs(playerGui:GetDescendants()) do
			if (object:IsA("TextLabel")
				or object:IsA("TextButton")
				or object:IsA("TextBox"))
				and isGuiVisible(object) then

				local content = tostring(object.Text or "")
				local upper = string.upper(content)

				if string.find(upper, "REBIRTH", 1, true) then
					state.panelVisible = true
				end

				if string.find(upper, "RESTING AT HOME", 1, true)
					or string.find(upper, "BACK TO YOUR COOP", 1, true) then
					state.panelVisible = true
					state.needsRoosterHome = true
				end

				local normalized = string.lower(
					content:gsub("[^%a]", "")
				)

				-- Rebirth button may be:
				-- TextButton("REBIRTH"), or
				-- ImageButton with a child TextLabel("REBIRTH").
				if normalized == "rebirth"
					and hasClickableAncestor(object) then

					state.panelVisible = true
					state.rebirthReady = true
				end

				local left, right =
					content:match("(%d+)%s*/%s*(%d+)")

				if left and right then
					local progressFloor = validFloor(left)
					local requiredFloor = validFloor(right)
					if progressFloor and requiredFloor
						and (
							ancestorHasRebirthContext(object)
							or nearbyHasRebirthTitle(object)
						) then
						state.panelVisible = true
						state.progressFloor = progressFloor
						state.requiredFloor = requiredFloor
					end
				end
			end
		end

		if state.needsRoosterHome then
			state.rebirthReady = false
		end

		return state
	end

	local function detectRequiredRebirthFloor()
		local floor = requirementFromData() or requirementFromAttributes() or requirementFromRebirthGui()
		if floor then requiredRebirthFloorCache = floor end
		return floor or requiredRebirthFloorCache
	end

	local setChickenOrderRemote =
		Remotes:WaitForChild("SetChickenOrder")

	local function callChickenToCoopOnce()
		if not setChickenOrderRemote
			or not setChickenOrderRemote.Parent
			or not setChickenOrderRemote:IsA("RemoteEvent") then

			return false
		end

		return pcall(function()
			setChickenOrderRemote:FireServer("coop")
		end)
	end

	local section = routineTab:AddDropdownSection("Automation Cycle", true)
	section:AddParagraph(
		"Uses Auto Tab Settings",
		"Routine controls only Buy Feeder, Upgrade Feeder, Tower, dynamic Surrender, No Thanks, and Rebirth. Pet/Open Egg/Collect/Expand stay OFF. Tower Loop Delay is the exact 1-200 second slider value between Tower attempts; the first Tower can start immediately. Rebirth retries continuously whenever eligible."
	)
	section:AddSlider({
		Title = "Tower Loop Delay", Min = 1, Max = 200, Step = 1, Default = towerLoopDelay,
		Callback = function(value)
			towerLoopDelay = value
			Config.AutomationTowerDelay = value
			queueSaveConfig()
		end,
	})
	local requiredFloorStatus = section:AddStatus("Required Rebirth Floor", "Detecting...")
	local currentFloorStatus = section:AddStatus("Current Tower Floor", "Waiting...")
	local towerBestStatus = section:AddStatus("Tower Best", "Detecting...")
	local cycleStatus = section:AddStatus("Cycle Status", "Stopped")

	local automationFeatureWorkerToken = 0
	local function invalidateAutomationWorker()
		automationWorkerToken += 1
	end

	local function invalidateAutomationFeatureWorkers()
		automationFeatureWorkerToken += 1
	end

	local function forceRoutineFeaturesOn()
		-- Not part of the requested Routine. Keep these OFF.
		autoPetEnabled = false
		Config.AutoPetEnabled = false
		autoPetToggle:Set(false, false)
		invalidateAutoPetWorker()

		autoEggEnabled = false
		Config.AutoOpenEnabled = false
		autoToggle:Set(false, false)
		invalidateWorker()
		updateStatus()

		autoCollectEnabled = false
		Config.AutoCollectEnabled = false
		autoCollectToggle:Set(false, false)
		invalidateCollectWorker()
		updateCollectIdleStatus()

		autoExpandCoopEnabled = false
		Config.AutoExpandCoopEnabled = false
		autoExpandCoopToggle:Set(false, false)
		invalidateAutoExpandCoopWorker()

		-- Routine core: Rebirth Runtime is always alive.
		autoRebirthEnabled = true
		Config.AutoRebirthEnabled = true
		autoRebirthToggle:Set(true, false)
		invalidateAutoRebirthWorker()

		-- Routine core: Buy Feeder 1..6 continuously.
		autoPurchaseFeederEnabled = true
		Config.AutoPurchaseFeederEnabled = true
		autoPurchaseFeederToggle:Set(true, false)
		startAutoPurchaseFeederWorker()

		-- Routine core: Upgrade Feeder 1..6 continuously.
		autoBuyFeederEnabled = true
		Config.AutoBuyFeederEnabled = true
		autoBuyFeederToggle:Set(true, false)
		startAutoBuyFeederWorker()

		-- Routine core: Tower + dynamic Surrender + No Thanks.
		AutoTowerController:ForceAutomationOn()

		queueSaveConfig()
	end

	local function forceRoutineFeaturesOff()
		autoRebirthEnabled = false
		Config.AutoRebirthEnabled = false
		autoRebirthToggle:Set(false, false)
		invalidateAutoRebirthWorker()

		autoPurchaseFeederEnabled = false
		Config.AutoPurchaseFeederEnabled = false
		autoPurchaseFeederToggle:Set(false, false)
		invalidateAutoPurchaseFeederWorker()

		autoBuyFeederEnabled = false
		Config.AutoBuyFeederEnabled = false
		autoBuyFeederToggle:Set(false, false)
		invalidateAutoBuyFeederWorker()

		AutoTowerController:ForceAutomationOff()

		queueSaveConfig()
	end

	-- Forward declarations are required because the dedicated
	-- Rebirth worker captures these functions before their bodies
	-- are assigned later in this controller scope.
	local updateFloorStatuses
	local markRebirthComplete

	local function startAutomationFeatureWorkers()
		invalidateAutomationFeatureWorkers()
		local token = automationFeatureWorkerToken

		-- All Auto features were already force-enabled by the
		-- Automation master switch before this runtime starts.

		-- Dedicated ALWAYS-ON Rebirth runtime.
		--
		-- Important:
		-- Rebirth does NOT require a previous surrender event.
		-- Every cycle this worker independently checks:
		--   1. required Rebirth floor
		--   2. current Tower floor
		--   3. Tower Best
		--   4. rooster home state
		--
		-- Examples:
		--   currentFloor 41 / required 40 -> surrender
		--   already at Coop, towerBest 52 / required 40
		--       -> immediately enter Rebirth flow
		task.spawn(function()
			local runtimeLastRebirthCount =
				getRebirthCount()

			local runtimeRequirementBefore =
				nil

			while automationEnabled
				and token == automationFeatureWorkerToken
				and window.ScreenGui.Parent do

				local now = os.clock()

				local rebirthCount =
					getRebirthCount()

				local requiredFloor =
					detectRequiredRebirthFloor()

				local currentFloor =
					AutoTowerController:GetCurrentFloor()

				local towerBest =
					getTowerBestFloor()

				local rebirthUi =
					getRebirthUiState()

				local rebirthRuntimeCoolingDown =
					now < postRebirthHoldUntil

				if not requiredFloor
					and rebirthUi.requiredFloor then

					requiredFloor =
						rebirthUi.requiredFloor

					requiredRebirthFloorCache =
						requiredFloor
				end

				if not towerBest
					and rebirthUi.progressFloor then

					towerBest =
						rebirthUi.progressFloor
				end

				updateFloorStatuses(
					requiredFloor,
					currentFloor,
					towerBest
				)

				-- PRIMARY SIGNAL:
				-- If the actual clickable REBIRTH button is visible,
				-- the game is explicitly telling us Rebirth is ready.
				-- Fire immediately; do not wait for surrender/home timers.
				if rebirthUi.rebirthReady
					and now - lastRebirthAttemptAt
						>= AUTOMATION_REBIRTH_RETRY_DELAY then

					local rebirthOk, rebirthResult =
						rebirthOnce()

					lastRebirthAttemptAt = now
					rebirthAttemptedAfterReturn = true

					if rebirthOk
						and rebirthResult ~= false then

						cycleStatus:Set(
							"REBIRTH button ready · invoking now",
							true
						)
					else
						cycleStatus:Set(
							"REBIRTH ready · retrying...",
							false
						)
					end
				end

				-- Strong success confirmation: Rebirth number changed.
				if runtimeLastRebirthCount ~= nil
					and rebirthCount ~= nil
					and rebirthCount
						> runtimeLastRebirthCount then

					runtimeLastRebirthCount =
						rebirthCount

					markRebirthComplete(now)

					runtimeRequirementBefore =
						nil

				elseif rebirthCount ~= nil then
					runtimeLastRebirthCount =
						rebirthCount
				end

				-- -------------------------------------------------
				-- IN TOWER:
				-- requirement 40 => 40 continues, 41+ surrenders.
				-- -------------------------------------------------
				if not rebirthRuntimeCoolingDown
					and requiredFloor
					and currentFloor
					and currentFloor > requiredFloor then

					if not waitingForRebirth then
						local surrendered =
							AutoTowerController:SurrenderOnce()

						if surrendered then
							waitingForRebirth = true

							rebirthCountBeforeSurrender =
								rebirthCount

							rebirthRequirementBeforeSurrender =
								requiredFloor

							runtimeRequirementBefore =
								requiredFloor

							lastRebirthAttemptAt = 0
							lastCoopOrderAt = 0
							coopStableSince = nil
							surrenderRequestedAt = now
							rebirthAttemptedAfterReturn = false

							AutoTowerController:DeclineOnce()
							callChickenToCoopOnce()

							cycleStatus:Set(
								"Floor "
									.. tostring(currentFloor)
									.. " > "
									.. tostring(requiredFloor)
									.. " · surrender → Rebirth runtime",
								true
							)
						end
					end

				-- -------------------------------------------------
				-- OUTSIDE TOWER:
				-- Rebirth eligibility is checked ALWAYS.
				-- This branch works even if no surrender happened.
				-- -------------------------------------------------
				elseif not rebirthRuntimeCoolingDown
					and not currentFloor
					and requiredFloor
					and towerBest
					and towerBest >= requiredFloor then

					if not waitingForRebirth then
						waitingForRebirth = true
						rebirthCountBeforeSurrender = rebirthCount
						rebirthRequirementBeforeSurrender = requiredFloor
						runtimeRequirementBefore = requiredFloor
						lastRebirthAttemptAt = 0
						lastCoopOrderAt = 0
						coopStableSince = nil
						surrenderRequestedAt = now - AUTOMATION_SURRENDER_GRACE
						rebirthAttemptedAfterReturn = false

						cycleStatus:Set(
							"Rebirth eligible "
								.. tostring(towerBest)
								.. " / "
								.. tostring(requiredFloor),
							true
						)
					end

					if now - lastCoopOrderAt >= AUTOMATION_COOP_ORDER_DELAY then
						callChickenToCoopOnce()
						lastCoopOrderAt = now
					end

					-- Always retry Rebirth while eligible. Server-side
					-- validation decides when rooster is actually home.
					if now - lastRebirthAttemptAt >= AUTOMATION_REBIRTH_RETRY_DELAY then
						local rebirthOk, rebirthResult = rebirthOnce()
						lastRebirthAttemptAt = now
						rebirthAttemptedAfterReturn = true

						if rebirthOk and rebirthResult ~= false then
							cycleStatus:Set("Rebirth invoked · confirming...", true)
						elseif rebirthUi.needsRoosterHome then
							cycleStatus:Set("Waiting rooster home · retry active", false)
						else
							cycleStatus:Set("Rebirth retry active", false)
						end
					end

					if rebirthCountBeforeSurrender ~= nil
						and rebirthCount ~= nil
						and rebirthCount > rebirthCountBeforeSurrender then

						markRebirthComplete(now)
						runtimeRequirementBefore = nil
					end

					if rebirthAttemptedAfterReturn
						and runtimeRequirementBefore
						and requiredFloor
						and requiredFloor ~= runtimeRequirementBefore then

						markRebirthComplete(now)
						runtimeRequirementBefore = nil
					end

				else
					-- Not currently eligible. Do not leave stale
					-- Rebirth state blocking the normal Tower cycle.
					if waitingForRebirth
						and (
							not requiredFloor
							or (
								towerBest
								and towerBest < requiredFloor
							)
						) then

						waitingForRebirth = false
						rebirthCountBeforeSurrender = nil
						rebirthRequirementBeforeSurrender = nil
						coopStableSince = nil
						rebirthAttemptedAfterReturn = false
						runtimeRequirementBefore = nil
					end
				end

				task.wait(AUTOMATION_POLL_DELAY)
			end
		end)
	end

	updateFloorStatuses = function(requiredFloor, currentFloor, towerBest)
		requiredFloorStatus:Set(
			requiredFloor and tostring(requiredFloor) or "Not detected",
			requiredFloor ~= nil
		)

		currentFloorStatus:Set(
			currentFloor and tostring(currentFloor) or "Not in Tower / unknown",
			currentFloor ~= nil
		)

		towerBestStatus:Set(
			towerBest and tostring(towerBest) or "Not detected",
			towerBest ~= nil
		)
	end

	markRebirthComplete = function(now)
		waitingForRebirth = false
		rebirthCountBeforeSurrender = nil
		rebirthRequirementBeforeSurrender = nil
		requiredRebirthFloorCache = nil
		postRebirthHoldUntil = now
		nextTowerStartAt =
			now + getAutomationTowerLoopDelay()
		towerWasActive = false
		lastRebirthAttemptAt = 0
		lastCoopOrderAt = 0
		coopStableSince = nil
		surrenderRequestedAt = 0
		rebirthAttemptedAfterReturn = false

		cycleStatus:Set(
			"Rebirth complete · Coop reset · rebuilding",
			true
		)
	end

	local function startAutomationWorker()
		invalidateAutomationWorker()
		local token = automationWorkerToken

		if not automationEnabled then
			return
		end

		-- MASTER SWITCH semantics:
		-- Automation ON means every Auto feature turns ON now.
		forceRoutineFeaturesOn()
		startAutomationFeatureWorkers()

		local now = os.clock()
		postRebirthHoldUntil = now
		nextTowerStartAt = now
		waitingForRebirth = false
		rebirthCountBeforeSurrender = nil
		rebirthRequirementBeforeSurrender = nil
		towerWasActive = false
		lastRebirthAttemptAt = 0
		lastCoopOrderAt = 0
		coopStableSince = nil
		surrenderRequestedAt = 0
		rebirthAttemptedAfterReturn = false

		cycleStatus:Set(
			"Routine ON · Buy + Upgrade + Tower + Rebirth active",
			true
		)

		task.spawn(function()
			while automationEnabled
				and token == automationWorkerToken
				and window.ScreenGui.Parent do

				local now = os.clock()

				local requiredFloor =
					detectRequiredRebirthFloor()

				local currentFloor =
					AutoTowerController:GetCurrentFloor()

				local towerBest =
					getTowerBestFloor()

				local rebirthUi =
					getRebirthUiState()

				if not requiredFloor
					and rebirthUi.requiredFloor then

					requiredFloor =
						rebirthUi.requiredFloor

					requiredRebirthFloorCache =
						requiredFloor
				end

				if not towerBest
					and rebirthUi.progressFloor then

					towerBest =
						rebirthUi.progressFloor
				end

				updateFloorStatuses(
					requiredFloor,
					currentFloor,
					towerBest
				)

				local inTower =
					currentFloor ~= nil

				-- Hard gate for the main routine:
				-- never start another Tower if Rebirth is already
				-- eligible outside Tower, even if the dedicated
				-- Rebirth worker has not flipped waitingForRebirth yet.
				local rebirthEligibleOutside =
					rebirthUi.rebirthReady
					or (
						not inTower
						and requiredFloor ~= nil
						and towerBest ~= nil
						and towerBest >= requiredFloor
					)

				-- Normal Tower K.O./end handling.
				-- No Thanks also has its own dedicated worker.
				if towerWasActive
					and not inTower then

					AutoTowerController:DeclineOnce()
					callChickenToCoopOnce()

					nextTowerStartAt =
						now + getAutomationTowerLoopDelay()

					cycleStatus:Set(
						"Tower ended/K.O. · returning Coop",
						true
					)
				end

				towerWasActive = inTower

				-- Rebirth Runtime owns surrender/Rebirth.
				-- Routine scheduler is the ONLY TowerStart owner.
				if not waitingForRebirth
					and not rebirthEligibleOutside
					and not inTower
					and now >= nextTowerStartAt then

					local latestRequired = detectRequiredRebirthFloor()
					local latestTowerBest = getTowerBestFloor()
					local becameRebirthEligible =
						latestRequired ~= nil
						and latestTowerBest ~= nil
						and latestTowerBest >= latestRequired

					if not waitingForRebirth and not becameRebirthEligible then
						local started = AutoTowerController:StartOnce()

						-- Always throttle future TowerStart attempts by the exact
						-- slider delay, even if current-floor detection is late.
						nextTowerStartAt = now + getAutomationTowerLoopDelay()

						if started then
							cycleStatus:Set(
								"Tower started · next attempt after "
									.. tostring(getAutomationTowerLoopDelay())
									.. "s",
								true
							)
						else
							cycleStatus:Set(
								"Tower start failed · retry in "
									.. tostring(getAutomationTowerLoopDelay())
									.. "s",
								false
							)
						end
					end
				end

				task.wait(AUTOMATION_POLL_DELAY)

		end)
	end

	local function stopAutomationWorker(shuttingDown)
		invalidateAutomationWorker()
		invalidateAutomationFeatureWorkers()
		waitingForRebirth = false
		rebirthCountBeforeSurrender = nil
		rebirthRequirementBeforeSurrender = nil
		coopStableSince = nil
		rebirthAttemptedAfterReturn = false
		window.AutomationRunning = false

		if not shuttingDown then
			forceRoutineFeaturesOff()
		end

		cycleStatus:Set(
			shuttingDown and "Closing" or "Stopped",
			false
		)
	end

	section:AddToggle({
		Title = "Automation",
		Default = automationEnabled,

		Callback = function(enabled)
			automationEnabled = enabled
			Config.AutomationEnabled = enabled
			window.AutomationRunning = enabled
			queueSaveConfig()

			if enabled then
				startAutomationWorker()
			else
				stopAutomationWorker(false)
			end
		end,
	})

	return {
		StartFromConfig = function()
			window.AutomationRunning = automationEnabled == true
			if automationEnabled then
				startAutomationWorker()
			else
				updateFloorStatuses(
					detectRequiredRebirthFloor(),
					AutoTowerController:GetCurrentFloor(),
					getTowerBestFloor()
				)
			end
		end,
		Stop = function(shuttingDown)
			automationEnabled = false
			stopAutomationWorker(shuttingDown == true)
		end,
	}
end)()

--========================================================
-- RESTORE SAVED STATE
--========================================================

if walkSpeedOverrideEnabled then
	applyWalkSpeed()
end

if godModeEnabled then
	applyGodMode()
end

if noClipEnabled then
	applyNoClip()
end

if autoEggEnabled then
	updateStatus()
	startWorker()
end

if autoCollectEnabled then
	updateCollectIdleStatus()
	startCollectWorker()
end

if autoPetEnabled then
	startAutoPetWorker()
end

if autoRebirthEnabled then
	startAutoRebirthWorker()
end

if autoBuyFeederEnabled then
	startAutoBuyFeederWorker()
end

if autoPurchaseFeederEnabled then
	startAutoPurchaseFeederWorker()
end

if autoExpandCoopEnabled then
	startAutoExpandCoopWorker()
end

AutoTowerController:StartFromConfig()
window.AutomationController:StartFromConfig()

-- Create the config file on first run when file APIs exist.
if canUseFileSystem() and typeof(isfile) == "function" then
	local hasFile = false

	local ok, result = pcall(function()
		return isfile(CONFIG_FILE)
	end)

	if ok then
		hasFile = result == true
	end

	if not hasFile then
		writeConfig()
	end
end

--========================================================
-- CLEANUP
--========================================================

window.ScreenGui.Destroying:Connect(function()
	-- Flush the latest user config before runtime cleanup.
	configRevision += 1
	writeConfig()

	if window.AutomationController then
		window.AutomationController:Stop(true)
	end

	autoEggEnabled = false
	autoCollectEnabled = false
	autoPetEnabled = false
	autoRebirthEnabled = false
	autoBuyFeederEnabled = false
	autoPurchaseFeederEnabled = false
	autoExpandCoopEnabled = false
	godModeEnabled = false
	noClipEnabled = false
	antiAfkEnabled = false

	invalidateWorker()
	invalidateCollectWorker()
	invalidateAutoPetWorker()
	invalidateAutoRebirthWorker()
	invalidateAutoBuyFeederWorker()
	invalidateAutoPurchaseFeederWorker()
	invalidateAutoExpandCoopWorker()
	AutoTowerController:Stop()

	restoreGodMode()
	restoreNoClip()
	restoreWalkSpeed()
	walkSpeedOverrideEnabled = false

	for _, connection in ipairs(utilityConnections) do
		connection:Disconnect()
	end
	table.clear(utilityConnections)
end)

print("[GACF] Borderless UI loaded · Themes + auto-save config enabled")
