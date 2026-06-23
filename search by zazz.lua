local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")

local Request = (syn and syn.request) or (http and http.request) or http_request or request
if not Request then return warn("Executor lu ga support HTTP") end

if CoreGui:FindFirstChild("ScriptbloxUI") then CoreGui.ScriptbloxUI:Destroy() end

-- Save system
local function SaveFile(name, data)
    if writefile then writefile("Scriptblox_"..name..".json", HttpService:JSONEncode(data)) end
end

local function LoadFile(name)
    if isfile and isfile("Scriptblox_"..name..".json") then
        return HttpService:JSONDecode(readfile("Scriptblox_"..name..".json"))
    end
    return {}
end

local Favorites = LoadFile("Favorites")
local History = LoadFile("History")

local function IsFavorited(scriptId)
    for _, v in ipairs(Favorites) do
        if v._id == scriptId then return true end
    end
    return false
end

-- Deteksi keamanan
local function ScanSecurity(scriptText)
    local flags = {}
    local lower = string.lower(scriptText or "")
    if string.find(lower, "getgenv%(") or string.find(lower, "_g%[") then table.insert(flags, "⚠️ Akses _G/getgenv") end
    if string.find(lower, "httpget") and string.find(lower, "loadstring") then table.insert(flags, "🚨 HttpGet + Loadstring") end
    if string.find(lower, "require%(") then table.insert(flags, "⚠️ Require module") end
    if string.find(lower, "writefile") or string.find(lower, "delfile") then table.insert(flags, "📁 Akses file") end
    if string.find(lower, "webhook") or string.find(lower, "discord.com/api") then table.insert(flags, "🔗 Discord Webhook") end
    if string.find(lower, "game:shutdown") then table.insert(flags, "💀 Force shutdown") end
    return #flags > 0 and flags or {"✅ Aman"}
end

-- Image cache
local ImageCache = {}
local function GetImageAsset(url)
    if not url or url == "" then return "rbxasset://textures/ui/GuiImagePlaceholder.png" end
    if ImageCache[url] then return ImageCache[url] end

    local success, result = pcall(function()
        if getcustomasset then
            local fileName = "zazz_thumb_".. HttpService:GenerateGUID(false).. ".png"
            local imageData = game:HttpGet(url)
            writefile(fileName, imageData)
            return getcustomasset(fileName)
        else
            return url
        end
    end)

    if success then
        ImageCache[url] = result
        return result
    else
        return "rbxasset://textures/ui/GuiImagePlaceholder.png"
    end
end

-- UI
local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "ScriptbloxUI"
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.new(0, 700, 0, 480)
Main.Position = UDim2.new(0.5, -350, 0.5, -240)
Main.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 8)

-- Topbar
local Topbar = Instance.new("Frame", Main)
Topbar.Size = UDim2.new(1, 0, 0, 35)
Topbar.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
Topbar.BorderSizePixel = 0

local Title = Instance.new("TextLabel", Topbar)
Title.Text = " Search for script by zazz 2.1" -- UDAH GANTI INI 🗿
Title.Size = UDim2.new(1, -70, 1, 0)
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14

local MinBtn = Instance.new("TextButton", Topbar)
MinBtn.Text = "–"
MinBtn.Size = UDim2.new(0, 35, 1, 0)
MinBtn.Position = UDim2.new(1, -70, 0, 0)
MinBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
MinBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
MinBtn.BorderSizePixel = 0
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 20

local CloseBtn = Instance.new("TextButton", Topbar)
CloseBtn.Text = "×"
CloseBtn.Size = UDim2.new(0, 35, 1, 0)
CloseBtn.Position = UDim2.new(1, -35, 0, 0)
CloseBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
CloseBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
CloseBtn.BorderSizePixel = 0
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 20

-- Mini ball
local MiniBall = Instance.new("TextButton", ScreenGui)
MiniBall.Size = UDim2.new(0, 50, 0, 50)
MiniBall.Position = UDim2.new(0, 20, 0.5, -25)
MiniBall.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
MiniBall.Text = "zazz"
MiniBall.TextColor3 = Color3.fromRGB(255, 255, 255)
MiniBall.Font = Enum.Font.GothamBold
MiniBall.TextSize = 12
MiniBall.Visible = false
MiniBall.Active = true
MiniBall.Draggable = true
Instance.new("UICorner", MiniBall).CornerRadius = UDim.new(1, 0)

-- Tabs
local TabFrame = Instance.new("Frame", Main)
TabFrame.Size = UDim2.new(1, -20, 0, 30)
TabFrame.Position = UDim2.new(0, 10, 0, 45)
TabFrame.BackgroundTransparency = 1

local function CreateTab(name, pos)
    local btn = Instance.new("TextButton", TabFrame)
    btn.Text = name
    btn.Size = UDim2.new(0, 100, 1, 0)
    btn.Position = UDim2.new(0, pos, 0, 0)
    btn.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    btn.TextColor3 = Color3.fromRGB(180, 180, 180)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 13
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    return btn
end

local SearchTab = CreateTab("Search", 0)
local FavTab = CreateTab("Favorit", 105)
local HistoryTab = CreateTab("History", 210)

local activeTab = SearchTab
local function SetActiveTab(tab)
    for _, btn in ipairs(TabFrame:GetChildren()) do
        if btn:IsA("TextButton") then
            btn.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
            btn.TextColor3 = Color3.fromRGB(180, 180, 180)
        end
    end
    tab.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
    tab.TextColor3 = Color3.fromRGB(255, 255, 255)
    activeTab = tab
end
SetActiveTab(SearchTab)

-- Search + Filter
local SearchBox = Instance.new("TextBox", Main)
SearchBox.PlaceholderText = "Cari script... misal: Blox Fruits, Doors"
SearchBox.Size = UDim2.new(1, -230, 0, 30)
SearchBox.Position = UDim2.new(0, 10, 0, 85)
SearchBox.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
SearchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
SearchBox.Font = Enum.Font.Gotham
SearchBox.TextSize = 13
SearchBox.ClearTextOnFocus = false
Instance.new("UICorner", SearchBox).CornerRadius = UDim.new(0, 6)

local FilterDropdown = Instance.new("TextButton", Main)
FilterDropdown.Text = "All ▼"
FilterDropdown.Size = UDim2.new(0, 100, 0, 30)
FilterDropdown.Position = UDim2.new(1, -210, 0, 85)
FilterDropdown.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
FilterDropdown.TextColor3 = Color3.fromRGB(255, 255, 255)
FilterDropdown.Font = Enum.Font.Gotham
FilterDropdown.TextSize = 13
Instance.new("UICorner", FilterDropdown).CornerRadius = UDim.new(0, 6)

local currentFilter = "All"

local SearchBtn = Instance.new("TextButton", Main)
SearchBtn.Text = "Cari"
SearchBtn.Size = UDim2.new(0, 90, 0, 30)
SearchBtn.Position = UDim2.new(1, -100, 0, 85)
SearchBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
SearchBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SearchBtn.Font = Enum.Font.GothamBold
SearchBtn.TextSize = 13
Instance.new("UICorner", SearchBtn).CornerRadius = UDim.new(0, 6)

-- Results
local ScrollFrame = Instance.new("ScrollingFrame", Main)
ScrollFrame.Size = UDim2.new(1, -20, 1, -135)
ScrollFrame.Position = UDim2.new(0, 10, 0, 125)
ScrollFrame.BackgroundTransparency = 1
ScrollFrame.BorderSizePixel = 0
ScrollFrame.ScrollBarThickness = 4
ScrollFrame.ScrollBarImageColor3 = Color3.fromRGB(88, 101, 242)
ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)

local UIListLayout = Instance.new("UIListLayout", ScrollFrame)
UIListLayout.Padding = UDim.new(0, 8)
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder

local currentResults = {}
local CommentFrame = nil

-- POPUP KOMENTAR 🗿
local function OpenCommentPopup(scriptId, scriptTitle, totalComments)
    if CommentFrame then CommentFrame:Destroy() end

    CommentFrame = Instance.new("Frame", ScreenGui)
    CommentFrame.Size = UDim2.new(0, 500, 0, 450)
    CommentFrame.Position = UDim2.new(0.5, -250, 0.5, -225)
    CommentFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    CommentFrame.BorderSizePixel = 0
    CommentFrame.Active = true
    CommentFrame.Draggable = true
    Instance.new("UICorner", CommentFrame).CornerRadius = UDim.new(0, 12)

    local Header = Instance.new("Frame", CommentFrame)
    Header.Size = UDim2.new(1, 0, 0, 40)
    Header.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 12)

    local Title = Instance.new("TextLabel", Header)
    Title.Text = "💬 Komentar [".. totalComments.. "] - ".. scriptTitle:sub(1, 25).. "..."
    Title.Size = UDim2.new(1, -50, 1, 0)
    Title.Position = UDim2.new(0, 10, 0, 0)
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.BackgroundTransparency = 1
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 13
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.TextTruncate = Enum.TextTruncate.AtEnd

    local CloseBtn = Instance.new("TextButton", Header)
    CloseBtn.Text = "×"
    CloseBtn.Size = UDim2.new(0, 30, 0, 30)
    CloseBtn.Position = UDim2.new(1, -35, 0, 5)
    CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.TextSize = 18
    Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 8)
    CloseBtn.MouseButton1Click:Connect(function() CommentFrame:Destroy() end)

    local Scroll = Instance.new("ScrollingFrame", CommentFrame)
    Scroll.Size = UDim2.new(1, -20, 1, -50)
    Scroll.Position = UDim2.new(0, 10, 0, 45)
    Scroll.BackgroundTransparency = 1
    Scroll.BorderSizePixel = 0
    Scroll.ScrollBarThickness = 5
    Scroll.ScrollBarImageColor3 = Color3.fromRGB(88, 101, 242)
    local UIList = Instance.new("UIListLayout", Scroll)
    UIList.Padding = UDim.new(0, 8)

    local Loading = Instance.new("TextLabel", Scroll)
    Loading.Text = "Loading komentar dari Scriptblox..."
    Loading.Size = UDim2.new(1, 0, 0, 40)
    Loading.TextColor3 = Color3.fromRGB(200, 200, 200)
    Loading.BackgroundTransparency = 1
    Loading.Font = Enum.Font.Gotham
    Loading.TextSize = 12

    task.spawn(function()
        local url = "https://scriptblox.com/api/comment/".. scriptId.. "?page=1&max=20"
        local success, res = pcall(function()
            return Request({Url = url, Method = "GET"})
        end)

        Loading:Destroy()

        if success and res.StatusCode == 200 then
            local data = HttpService:JSONDecode(res.Body)
            local comments = data.result.comments or {}

            if #comments == 0 then
                local NoComment = Instance.new("TextLabel", Scroll)
                NoComment.Text = "Belum ada komentar buat script ini 🗿\nJadi yang pertama komen di Scriptblox!"
                NoComment.Size = UDim2.new(1, 0, 0, 50)
                NoComment.TextColor3 = Color3.fromRGB(150, 150, 150)
                NoComment.BackgroundTransparency = 1
                NoComment.Font = Enum.Font.Gotham
                NoComment.TextSize = 12
                NoComment.TextWrapped = true
            else
                for i, c in ipairs(comments) do
                    local CFrame = Instance.new("Frame", Scroll)
                    CFrame.Size = UDim2.new(1, -12, 0, 0)
                    CFrame.AutomaticSize = Enum.AutomaticSize.Y
                    CFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
                    Instance.new("UICorner", CFrame).CornerRadius = UDim.new(0, 8)
                    Instance.new("UIPadding", CFrame).PaddingLeft = UDim.new(0, 8)
                    Instance.new("UIPadding", CFrame).PaddingRight = UDim.new(0, 8)
                    Instance.new("UIPadding", CFrame).PaddingTop = UDim.new(0, 6)
                    Instance.new("UIPadding", CFrame).PaddingBottom = UDim.new(0, 6)

                    local UserFrame = Instance.new("Frame", CFrame)
                    UserFrame.Size = UDim2.new(1, 0, 0, 20)
                    UserFrame.BackgroundTransparency = 1

                    local User = Instance.new("TextLabel", UserFrame)
                    User.Text = "@".. (c.commentBy.username or "anonymous")
                    User.Size = UDim2.new(0.6, 0, 1, 0)
                    User.TextColor3 = Color3.fromRGB(88, 166, 255)
                    User.Font = Enum.Font.GothamBold
                    User.TextSize = 12
                    User.TextXAlignment = Enum.TextXAlignment.Left
                    User.BackgroundTransparency = 1

                    local Date = Instance.new("TextLabel", UserFrame)
                    local timeAgo = c.createdAt and c.createdAt:sub(1, 10) or "???"
                    Date.Text = timeAgo
                    Date.Size = UDim2.new(0.4, 0, 1, 0)
                    Date.Position = UDim2.new(0.6, 0, 0, 0)
                    Date.TextColor3 = Color3.fromRGB(120, 120, 120)
                    Date.Font = Enum.Font.Gotham
                    Date.TextSize = 10
                    Date.TextXAlignment = Enum.TextXAlignment.Right
                    Date.BackgroundTransparency = 1

                    local Text = Instance.new("TextLabel", CFrame)
                    Text.Text = c.text or ""
                    Text.Size = UDim2.new(1, 0, 0, 0)
                    Text.AutomaticSize = Enum.AutomaticSize.Y
                    Text.Position = UDim2.new(0, 0, 0, 22)
                    Text.TextColor3 = Color3.fromRGB(220, 220, 220)
                    Text.Font = Enum.Font.Gotham
                    Text.TextSize = 11
                    Text.TextWrapped = true
                    Text.TextXAlignment = Enum.TextXAlignment.Left
                    Text.BackgroundTransparency = 1
                end
            end
            Scroll.CanvasSize = UDim2.new(0, 0, 0, UIList.AbsoluteContentSize.Y + 10)
        else
            local Error = Instance.new("TextLabel", Scroll)
            Error.Text = "❌ Gagal load komentar\nError: ".. (res and res.StatusCode or "No response")
            Error.Size = UDim2.new(1, 0, 0, 60)
            Error.TextColor3 = Color3.fromRGB(255, 100, 100)
            Error.BackgroundTransparency = 1
            Error.Font = Enum.Font.Gotham
            Error.TextSize = 12
            Error.TextWrapped = true
        end
    end)
end

local function ClearResults()
    for _, v in pairs(ScrollFrame:GetChildren()) do
        if v:IsA("Frame") then v:Destroy() end
    end
    task.wait()
    ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y)
end

local function AddResultCard(data)
    local isGameScript = data.game and data.game.name and data.game.name ~= ""
    if currentFilter == "Game" and not isGameScript then return end
    if currentFilter == "Universal" and isGameScript then return end

    local Card = Instance.new("Frame", ScrollFrame)
    Card.Size = UDim2.new(1, -10, 0, 130)
    Card.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    Instance.new("UICorner", Card).CornerRadius = UDim.new(0, 6)

    local Thumbnail = Instance.new("ImageLabel", Card)
    Thumbnail.Size = UDim2.new(0, 100, 0, 100)
    Thumbnail.Position = UDim2.new(0, 10, 0, 10)
    Thumbnail.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    Thumbnail.Image = GetImageAsset(data.game and data.game.imageUrl or data.image)
    Thumbnail.ScaleType = Enum.ScaleType.Crop
    Instance.new("UICorner", Thumbnail).CornerRadius = UDim.new(0, 6)

    local GameBadge = Instance.new("TextLabel", Thumbnail)
    GameBadge.Size = UDim2.new(0, 70, 0, 18)
    GameBadge.Position = UDim2.new(1, -75, 1, -23)
    GameBadge.BackgroundColor3 = isGameScript and Color3.fromRGB(88, 101, 242) or Color3.fromRGB(80, 80, 80)
    GameBadge.Text = isGameScript and "GAME" or "UNIVERSAL"
    GameBadge.TextColor3 = Color3.fromRGB(255, 255, 255)
    GameBadge.Font = Enum.Font.GothamBold
    GameBadge.TextSize = 9
    GameBadge.BackgroundTransparency = 0.1
    Instance.new("UICorner", GameBadge).CornerRadius = UDim.new(0, 4)

    local Title = Instance.new("TextLabel", Card)
    Title.Text = data.title
    Title.Size = UDim2.new(1, -130, 0, 25)
    Title.Position = UDim2.new(0, 120, 0, 8)
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.BackgroundTransparency = 1
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 14
    Title.TextTruncate = Enum.TextTruncate.AtEnd

    local gameName = isGameScript and data.game.name or "Universal"
    local gameColor = isGameScript and Color3.fromRGB(100, 200, 255) or Color3.fromRGB(150, 150, 150)

    local Game = Instance.new("TextLabel", Card)
    Game.Text = "Game: ".. gameName
    Game.Size = UDim2.new(1, -130, 0, 18)
    Game.Position = UDim2.new(0, 120, 0, 31)
    Game.TextColor3 = gameColor
    Game.TextXAlignment = Enum.TextXAlignment.Left
    Game.BackgroundTransparency = 1
    Game.Font = Enum.Font.GothamBold
    Game.TextSize = 12
    Game.TextTruncate = Enum.TextTruncate.AtEnd

    local Security = Instance.new("TextLabel", Card)
    local scanResult = ScanSecurity(data.script or "")
    Security.Text = scanResult[1]
    Security.Size = UDim2.new(1, -130, 0, 18)
    Security.Position = UDim2.new(0, 120, 0, 49)
    Security.TextColor3 = string.find(scanResult[1], "✅") and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 150, 80)
    Security.TextXAlignment = Enum.TextXAlignment.Left
    Security.BackgroundTransparency = 1
    Security.Font = Enum.Font.Gotham
    Security.TextSize = 11

    -- Stats Bar Like/Dislike/Views
    local StatsBar = Instance.new("Frame", Card)
    StatsBar.Size = UDim2.new(1, -130, 0, 18)
    StatsBar.Position = UDim2.new(0, 120, 0, 67)
    StatsBar.BackgroundTransparency = 1

    local Likes = Instance.new("TextLabel", StatsBar)
    Likes.Text = "👍 ".. (data.likeCount or 0)
    Likes.Size = UDim2.new(0, 60, 1, 0)
    Likes.Position = UDim2.new(0, 0, 0, 0)
    Likes.TextColor3 = Color3.fromRGB(100, 255, 100)
    Likes.Font = Enum.Font.Gotham
    Likes.TextSize = 11
    Likes.TextXAlignment = Enum.TextXAlignment.Left
    Likes.BackgroundTransparency = 1

    local Dislikes = Instance.new("TextLabel", StatsBar)
    Dislikes.Text = "👎 ".. (data.dislikeCount or 0)
    Dislikes.Size = UDim2.new(0, 60, 1, 0)
    Dislikes.Position = UDim2.new(0, 65, 0, 0)
    Dislikes.TextColor3 = Color3.fromRGB(255, 100, 100)
    Dislikes.Font = Enum.Font.Gotham
    Dislikes.TextSize = 11
    Dislikes.TextXAlignment = Enum.TextXAlignment.Left
    Dislikes.BackgroundTransparency = 1

    local Views = Instance.new("TextLabel", StatsBar)
    Views.Text = "👁️ ".. (data.views or 0).. " | ".. (data.verified and "✓" or "✗")
    Views.Size = UDim2.new(0, 100, 1, 0)
    Views.Position = UDim2.new(0, 130, 0, 0)
    Views.TextColor3 = data.verified and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(180, 180, 180)
    Views.Font = Enum.Font.Gotham
    Views.TextSize = 11
    Views.TextXAlignment = Enum.TextXAlignment.Left
    Views.BackgroundTransparency = 1

    -- Tombol Run
    local RunBtn = Instance.new("TextButton", Card)
    RunBtn.Text = "Run"
    RunBtn.Size = UDim2.new(0, 65, 0, 26)
    RunBtn.Position = UDim2.new(0, 120, 1, -32)
    RunBtn.BackgroundColor3 = Color3.fromRGB(60, 200, 80)
    RunBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    RunBtn.Font = Enum.Font.GothamBold
    RunBtn.TextSize = 12
    Instance.new("UICorner", RunBtn).CornerRadius = UDim.new(0, 4)

    -- Tombol Copy
    local CopyBtn = Instance.new("TextButton", Card)
    CopyBtn.Text = "Copy"
    CopyBtn.Size = UDim2.new(0, 65, 0, 26)
    CopyBtn.Position = UDim2.new(0, 190, 1, -32)
    CopyBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
    CopyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    CopyBtn.Font = Enum.Font.GothamBold
    CopyBtn.TextSize = 12
    Instance.new("UICorner", CopyBtn).CornerRadius = UDim.new(0, 4)

    -- Tombol Favorit
    local FavBtn = Instance.new("TextButton", Card)
    FavBtn.Text = IsFavorited(data._id) and "★" or "☆"
    FavBtn.Size = UDim2.new(0, 32, 0, 26)
    FavBtn.Position = UDim2.new(0, 260, 1, -32)
    FavBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
    FavBtn.TextColor3 = IsFavorited(data._id) and Color3.fromRGB(255, 200, 0) or Color3.fromRGB(150, 150, 150)
    FavBtn.Font = Enum.Font.GothamBold
    FavBtn.TextSize = 16
    Instance.new("UICorner", FavBtn).CornerRadius = UDim.new(0, 4)

    -- Tombol Komen 🗿
    local CommentBtn = Instance.new("TextButton", Card)
    CommentBtn.Text = "💬"
    CommentBtn.Size = UDim2.new(0, 32, 0, 26)
    CommentBtn.Position = UDim2.new(0, 297, 1, -32)
    CommentBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 255)
    CommentBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    CommentBtn.Font = Enum.Font.GothamBold
    CommentBtn.TextSize = 14
    Instance.new("UICorner", CommentBtn).CornerRadius = UDim.new(0, 4)

    -- Fungsi tombol
    RunBtn.MouseButton1Click:Connect(function()
        RunBtn.Text = "..."
        local func, err = loadstring(data.script)
        if func then
            local success, runErr = pcall(func)
            RunBtn.Text = success and "Done!" or "Error"
            if not success then warn("Run error:", runErr) end
        else
            RunBtn.Text = "Err"
            warn("Loadstring error:", err)
        end
        task.wait(1)
        RunBtn.Text = "Run"

        table.insert(History, 1, data)
        if #History > 50 then table.remove(History) end
        SaveFile("History", History)
    end)

    CopyBtn.MouseButton1Click:Connect(function()
        setclipboard(data.script)
        CopyBtn.Text = "Copied!"
        task.wait(1)
        CopyBtn.Text = "Copy"

        table.insert(History, 1, data)
        if #History > 50 then table.remove(History) end
        SaveFile("History", History)
    end)

    FavBtn.MouseButton1Click:Connect(function()
        if IsFavorited(data._id) then
            for i, v in ipairs(Favorites) do
                if v._id == data._id then table.remove(Favorites, i) break end
            end
            FavBtn.Text = "☆"
            FavBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
        else
            table.insert(Favorites, data)
            FavBtn.Text = "★"
            FavBtn.TextColor3 = Color3.fromRGB(255, 200, 0)
        end
        SaveFile("Favorites", Favorites)
    end)

    CommentBtn.MouseButton1Click:Connect(function()
        OpenCommentPopup(data._id, data.title, data.commentCount or 0)
    end)

    ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y)
end

local function RenderResults(results)
    ClearResults()
    for _, scriptData in ipairs(results) do
        AddResultCard(scriptData)
    end
end

local function DoSearch(query)
    SearchBtn.Text = "..."
    ClearResults()

    local url = "https://scriptblox.com/api/script/search?q=".. HttpService:UrlEncode(query).. "&page=1"
    local success, response = pcall(function()
        return Request({Url = url, Method = "GET"})
    end)

    if success and response.StatusCode == 200 then
        local data = HttpService:JSONDecode(response.Body)
        currentResults = data.result.scripts or {}
        RenderResults(currentResults)
    else
        warn("Gagal fetch:", response and response.StatusCode)
    end
    SearchBtn.Text = "Cari"
end

-- Filter dropdown logic
FilterDropdown.MouseButton1Click:Connect(function()
    if currentFilter == "All" then
        currentFilter = "Game"
        FilterDropdown.Text = "Game ▼"
    elseif currentFilter == "Game" then
        currentFilter = "Universal"
        FilterDropdown.Text = "Universal ▼"
    else
        currentFilter = "All"
        FilterDropdown.Text = "All ▼"
    end
    RenderResults(currentResults)
end)

-- Events
SearchBtn.MouseButton1Click:Connect(function()
    if SearchBox.Text ~= "" then DoSearch(SearchBox.Text) end
end)

FavTab.MouseButton1Click:Connect(function()
    SetActiveTab(FavTab)
    RenderResults(Favorites)
end)

HistoryTab.MouseButton1Click:Connect(function()
    SetActiveTab(HistoryTab)
    RenderResults(History)
end)

SearchTab.MouseButton1Click:Connect(function()
    SetActiveTab(SearchTab)
    RenderResults(currentResults)
end)

MinBtn.MouseButton1Click:Connect(function()
    Main.Visible = false
    MiniBall.Visible = true
end)

MiniBall.MouseButton1Click:Connect(function()
    Main.Visible = true
    MiniBall.Visible = false
end)

CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

SearchBox.FocusLost:Connect(function(enter)
    if enter and SearchBox.Text ~= "" then DoSearch(SearchBox.Text) end
end)