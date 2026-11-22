local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ContextActionService = game:GetService("ContextActionService")
local HttpService = game:GetService("HttpService")

local Library = {}
Library.__index = Library
Library.Options = {}
Library.Windows = {}
Library.ConfigStorage = {}
Library.ThemeCallbacks = {}
Library.Unloaded = false

local Player = Players.LocalPlayer
local Themes = {
    GTA = {
        Background = Color3.fromRGB(15, 17, 19),
        Panel = Color3.fromRGB(23, 26, 29),
        PanelLight = Color3.fromRGB(31, 35, 39),
        Row = Color3.fromRGB(27, 30, 33),
        RowSelected = Color3.fromRGB(45, 94, 190),
        Border = Color3.fromRGB(57, 63, 67),
        Text = Color3.fromRGB(239, 241, 239),
        Muted = Color3.fromRGB(151, 159, 161),
        Accent = Color3.fromRGB(48, 105, 218),
        AccentDark = Color3.fromRGB(27, 69, 157),
        Danger = Color3.fromRGB(211, 83, 76)
    },
    Midnight = {
        Background = Color3.fromRGB(13, 16, 24),
        Panel = Color3.fromRGB(20, 25, 37),
        PanelLight = Color3.fromRGB(29, 36, 52),
        Row = Color3.fromRGB(24, 30, 44),
        RowSelected = Color3.fromRGB(41, 53, 76),
        Border = Color3.fromRGB(57, 70, 96),
        Text = Color3.fromRGB(236, 241, 250),
        Muted = Color3.fromRGB(144, 157, 180),
        Accent = Color3.fromRGB(91, 161, 255),
        AccentDark = Color3.fromRGB(54, 112, 193),
        Danger = Color3.fromRGB(220, 83, 92)
    },
    Crimson = {
        Background = Color3.fromRGB(18, 14, 16),
        Panel = Color3.fromRGB(29, 21, 24),
        PanelLight = Color3.fromRGB(40, 29, 33),
        Row = Color3.fromRGB(33, 24, 28),
        RowSelected = Color3.fromRGB(57, 37, 43),
        Border = Color3.fromRGB(80, 53, 61),
        Text = Color3.fromRGB(247, 239, 241),
        Muted = Color3.fromRGB(169, 145, 151),
        Accent = Color3.fromRGB(226, 83, 100),
        AccentDark = Color3.fromRGB(154, 48, 63),
        Danger = Color3.fromRGB(255, 105, 105)
    }
}

Library.Theme = Themes.GTA
Library.ThemeName = "GTA"

local function create(className, properties, parent)
    local object = Instance.new(className)
    for property, value in pairs(properties or {}) do
        object[property] = value
    end
    object.Parent = parent
    return object
end

local function addCorner(object, radius)
    create("UICorner", { CornerRadius = UDim.new(0, radius or 4) }, object)
end

local function addStroke(object, color, transparency)
    return create("UIStroke", {
        Color = color or Library.Theme.Border,
        Transparency = transparency or 0,
        Thickness = 1
    }, object)
end

local function tween(object, properties, duration)
    local animation = TweenService:Create(object, TweenInfo.new(duration or 0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), properties)
    animation:Play()
    return animation
end

local function copyTable(value)
    if type(value) ~= "table" then
        return value
    end
    local result = {}
    for key, item in pairs(value) do
        result[key] = copyTable(item)
    end
    return result
end

local function makeFlag(text)
    local flag = tostring(text or "Option"):lower():gsub("[^%w]+", "_"):gsub("^_+", ""):gsub("_+$", "")
    if flag == "" then
        flag = "option"
    end
    return flag
end

local function getEnvironment()
    if type(getgenv) == "function" then
        local success, environment = pcall(getgenv)
        if success and type(environment) == "table" then
            return environment
        end
    end
    return _G
end

local function getGlobalFunction(name)
    local environment = getEnvironment()
    local candidate = environment and environment[name]
    if type(candidate) == "function" then
        return candidate
    end
    local fallback = _G and _G[name]
    if type(fallback) == "function" then
        return fallback
    end
    return nil
end

local LucideIconData = {
    ["user-round"] = "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAYAAACqaXHeAAAABmJLR0QA/wD/AP+gvaeTAAAEj0lEQVR4nO2aTWwVVRiG3wOWgn9BUqoFioQo2hB/MBGISGKIaUxYmbgDf+LfhsREN26JIerW+LNRg0bjxphoXBhtY1AsYty4MLEQI4VeKNaFYhtKgfZxMdNQp9/cO3PPOXObcJ+ki37teb/3O3Nm5pw5R2rTpk2bqxhXdUJgmaSNkrol9abhUUnjkv5wzl2s2lN0gBuAx4FPgQnymUj/Zy9wfat9ewN0AM8DY3WKzuMv4GWgs9V1NAVwD3C8icKzHAPubnU9pQB2A+cCFD/HBPBoDK/BH4LAE5I+qKN9QdK3kn6TdDqNrZPUJ2mXpLwhPyvpSefcx8HMhgZ4ALiQcxVHgWep83AjeVg+B9RyNKaA7VXWVBigGzibY/xNYEUJrRXA2zlaY0BXzFqaIi0yyyywz0NzX6qR5Y2Q3r0BNgLThtEDAbRfM3QvAreF8B4E4B3D5A/AkgDaS4AfDf23Qnj3BnDYD60dAXPsNPRrQOVTecvcNsPcTxHy/Gzkud9X13uISnrQiH0RQLeIppW7FCE6oMeIHQmgm2XIiK3xFQ3RAWuN2Gkj5ssZI7YoOsCa2U0E0M1yzojd6CsaogPGjVh3AN0s1q121lc0RAeMGbFbA+gW0bRylyJEB5wwYo8E0C2iORIhTzmAdSycr9eAjoA5lgFnMjlmAesBXD05k5SmF0GG/guG/tFQ+t4ALxkG/wRuDqDdA4wb+i+G8B4EkvX7KcPkETw+agLLsRdCNeDakDV4AzxjGAX4BripCb1VwGCO5lMRSvADWAp8nWP4OPBwCa1+4Pccra8IsMyOArASGM4xDjAA7LFGRHrF99a56qTaK1tRW2GATcDJOkUAzADngX/Sn/NprB4ngdtbXV8hgC7gUIOCyjAE3BLDa6x7aZukpQH1LkvaElAvDsAW4HDAK5/le+DeVte5AJKp6qvA5YjFz3EJOECgqbb3R0VgjaTPJDXasRmRNCDpqKRhSTVJ0+nfOpWcFbgz1emXtL6B3pCkx5xz3kvipgH6sGeAc0wB7wJbm9DeDrxH/lYbwAiwKUZtRQz2kb8VNgO8T4DVGslq8yD2DhEkq8RqOwFYW+fKjwA7I+R8qE7OE0R6TVpGOrAXKJDM4lZFzN0FfJeT+zBwTazc8028nmPgc5IDULHzdwJf5nh4JXby+7BfdYNVFD/Px/KckXCJmMdpsCc5I0Qc9nW8rMZ+JhyKlXC3kWwG8N6e8vC0C/vt0B8jmTXkDgZPVN7Xh4avwdBJNhtJplgEX2WB9Sw8nDEL3FGkfdHV4B4j9pFzLsYeYCmcc6ckfZINy/bcHMCvxgjw3psPBcnptCy/hBLvMcSt3aCWQXJKZdS4DRqeJityC1gLmYHyNuPhnEMLPTnZ3v9HkQ7YbMQWz67MFSxPdzVqVKQDNhixYwXaVc2wEdvQqFGRDrD2+msF2lWN5Wl1o0ZFOsA64jpZoF3VWKdSrmvUqEgH/J35fVqLswP+1ZVPbHNYx2rKAWwFJue9XvZ7i0YC2D/P5yRNfIrLE+4Fnibg6c9YADtSr72N/7tNmzZtrnL+AyxKHnB6Id+xAAAAAElFTkSuQmCC",
    ["sliders-horizontal"] = "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAYAAACqaXHeAAAABmJLR0QA/wD/AP+gvaeTAAADRUlEQVR4nO2bTahWRRiAn8nf/CERxH4QCQyEFpKoSFi5KheFC8PCCDEIFKJUWiZeQQmJ2kW71m5ciG4M+rkZbsSUKBFFEjUjWoRcI7sXe1ycL7zod78z59w5zvd5z7M898zM8773MGdmzvtBS0tLyxQmpOpIDcCzwHJgPvAncCqE8EeqMfoSdbr6vnrZ+/lP/Vp9IbdnI6gL1RNdAr+X2+pQbt+kqDPUkxHBj2d3bu9kqLsqBq96S12W23080ZOgOg+YMa7dT8BTNcb8HNhTo10VxkIIN2NuLE2A+hhwCHgl5v4+QeA48GYI4UavGx+J6OwjYAODEzwUrhso3HsSk4BnJq2Tj1L3mAQcSSCSi1L3qMdafQfYBMzsXJoFrIttfw9/AadrtKvCKHA4hPBlYyMYtwDqxnuNST1I1OctlrpVuKTOzu2eDHVvheD/Vtfmdk6OxUbon5LgL6ircrs2hrpEPaj+rI51gh5Rv1HfVWfldnygqHNzO7S0xNF36/vOfPEa8BKwpHP5CjAMHA0hjOZyaxx1i/pbj7fJNfWN3J6NoH5cYU2xP7dvUtStFYL/n7dyeydBnav+XiMB19U5kx1/eqTkk8DL3N0NpmQl8HiNdk8An6pnuvxtFPgqhHC9rJOYI7GVwHcUHzsGiRFgfQjhx143xRyI7GbwgofCufQYPiYBDzUxCfiM4nEaNEYo3HsSeyTW5CT4HLC9ZtsvgLNdrkdPgtlR5+R8DfYF6ts1ErAlt3dS1P0Vgt+X27cR1M0WG56JuKK+nnLMftwOzwRepdgOL+1cvkyxHT4WQhjLpNbSMhnU+RaFVFMD9VF1hzrs3e8Gt9Vf1E/UpeW9DCjqWvXXklfZLXVnbtfkqGssPorEMpTbORmdx75bvWAZL+Z2T4L6QY3gVb/P5Vy3QGIiVgELangI/AD8W6NtN9IVSKjbav5X+4FtZfHFHIhsnHQW81HqHpOAiwlEclHqPuULJeuWyk7EAWBHbJ/juAqsqNFuIqJLZZOiPm15uUw3Ho7KMQD1w4rBD6tRX6gGBnXIYuNTxrdqnXVD/6Ous/i5TLdawksWO8VpuT0bn9XVRcBqYDFwAzgfQjjX9LgtLS0tLRHcAcWILwYefOnWAAAAAElFTkSuQmCC",
    ["crosshair"] = "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",
    ["eye"] = "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAYAAACqaXHeAAAABmJLR0QA/wD/AP+gvaeTAAAFT0lEQVR4nO2aXWwVRRTHz7QNbSnUtrdRoKh8StRoBDWi0Qoa47OmLX7EiBjSSIxRo4KJJhrxHROi1PgAkjRVn9QEImJbH5AqQsWANvogH6ZIvyiglKS1Px9mLr25ndk7e+9urw/7Tza52bvnf/5ndvbsnLMjkiBBggQJEiRIkCDBjAOoBCqLqUHF7QAoE5HVInKHiKwSkdtEpF5EakWkwlx2WUTOiciQiPwkIofN0aOUmohbY+QASoCHgY+AIfLHIPAh8BBQUuy4cgIoB54F+goI2oVfgQ3ArGLHOQ2AAh4DTscQeDZOAeui0l5wDgBuFJEdItLoaTIpImdEP/Oj5lytiNSIyIIQmrpF5DmlVJ+32KgBtAKXctyxSeA74DXgfqA6gK8aWANsBg4a2yD8A2ycyZjTQquAz3KIGwLeAhYW4Oda4G1yJ9JPgNlRxhgkqgE4HCDmPPAKUBWhzyrgVeBCgN9DwIKofLqELEcnIRd2A/Ni9D8faA/wfxJYFpfzFcCfAXf9yVgc27U0ASMOLWeAm6N22ID7FfcLsDQkXz3QCDxhjkYgFZJjGe71xmmgIVyUbkdzgV6Ho/1AjSdPeq3QDUxYuCbMfy2A16sQqAU6Hdp6gbmFBl8KfOFwsAeoyM1y5W4dcvDY0AMs8eQuBz4P0FhWyAC87yD+Cs8lKXAv+dUDg8A9IQZhn4Nne77BP+ogPIb/tF9sAskXw3hmdfSjetTBE27pDCw0zrPRD1znyaGAHxyCRoGdwEvm2GXO2XAQ/5zgStbnfHWnS9kuC8klYKUXieZZ5wioHaizXJ8COhw2zSH83g6MWTg6vQYSXXLasMlXhOH51hG8UwR61tgGoSuk7xccMazPZViNnubZ2OM1elM89Ux/1Y1iufMW2xR6YZWJcR/bDA4FfGmJ4yxB+QvYZjEaBq72dW541lh4doaw32Wx9y230xzXYM9j2zKvK8kwKBORVgvXG0qpgTDORdf12Tgawv5nT04nlFJnReRNy1+tZKwN4uqzYTkXxldUzdqcPFdEme5rm+WarWEfAdEdn2zcEsL+Vsu5/jAC0FXpO5a/2pydZtxJcC/hkmAKexLMWfCgE2hxkqAxfsZiCPC8rwDD023h6AgaSCPc1mnqDOn7RUcM632MFfYKawxYFUJEi0NEB5aZgL7zrjZbUwi/dwKXLRzfBA1+NkkD9gKmH7jek0OhqzobzgMfAy+bYzfTp30aB3yFG922ps0IvkvhDLJHHIKO418MLQIGHDw+GMK/LK7GXQy1hAo+g3S7g3AfUO7JcTf5VYSDwGpPH+XA1w6e9/IK3hCX4m427MXzyy6wBF3V+eIAsMiTuxLdn7ChsIaIcRDUEusCaj15FNBsbMYtXOPo5NuE/zNfh73oAjgCzCko+AxHQU3RPmB5SL4UcB+6Ifq4+e39njccNwC/OTSdIupvBMahaxAuAE9F6jBYSzO6yWFDP3BTXI6XAiccjkG/42P7OoOeiZ8G+P8Dz7dGISLm4251pWfDZqJ6/rTPOcAW4GKA3x5i/CqVLWg27vZVGsPAVjwXTg4/i4F3cX8FSqOdYuw1AjYCf+cQN2nuzhZgLXBVAF8N8ADwOsGzLI2LwIZCYohig8QKEflARNb6mojIX6I3SIyYc3WiN0nMC6Fpv4hsUkr97q82RqCLn5Med61QnCBEcTSjAGahy+njMQR+DHia/+MmqWygV30PAm0UVgwNADvQeSGWPY0zsVGyVETukqmNkitlaqNkOnOPydRGyV4ROSIiP4rI90qpf+PWWDQAFXh+YU6QIEGCBAkSJEiQIFr8B/g1cMgRf/K4AAAAAElFTkSuQmCC",
    ["move"] = "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAYAAACqaXHeAAAABmJLR0QA/wD/AP+gvaeTAAADR0lEQVR4nO2bv28TMRzFn1FVfqjsqGvVf6GdwhC69g9AQoKpGxJlbKVuFZWQ2gkJtiIhwd6xlIU/goH/gqihLUiPoV8X6/I9+5yz75K7fqQM8Z2f/d75fE7iALfc0hokl0gutd2PViB5yv+ctt2fRiH5kZN8brtfjUDyUDFvOWy7f1kh+cZj3nLUdj+zUNF8N0MIDPtu3w6RV75bI8Fj/lIpu+hUCB7z59RvibckR50IIWD+Cckt5dgWycHchxAyL+eoAcix+Q2B5J7H/NA5rzQAOT6UOhp77bgLQHKB5DhkXs71BiDnlIUwJrmQqt93UgmVMAawaYz5FltR6myKRjaSBWCM+Qtg3ykaYUrzjqYNYeQU70tb7UNykeRioWyN5AuSy556wVugcP6yaK6F2m8MXk945/LaiawbFUCJxo7TfrMTI/WFzHpE/VoBkFxX6k/12SF6DpCGtpVDq9N0YEq0tranDaEyJVeeJH/57nlFp+4IWJY2NfKE4DE/8ZyvoJViDvAtltKGwArL20i92gGITv5lc2rzopkkANHKF0IO86KbLADRSx9CLvOinTQA0UwXQk7zop88ANGNDmHiUxXJYwDPlXOvAHwAsEJypWZfB1oZyZqyAID3AF4CuFsof0XykTHmqVto3DckvwKofYVnnDNjzIZ9cxMAyXsAfrfSpea5b4y5APJ/HzDz3AQgiZy12JemOLNXHyjMAYB3EvwD4B2AHwk6MQDwrFD2CcD3BNqr0CdBAPhSnARVPI/BMcmNoEBYP9dj8HHsY9Anli2EHAEkNe+IZgkhdQBZzDviyUNIGUBW804jSUNIFUAj5p3G+vuFiNNo574Si1oJGmNeA9CG1kMAUaOgJkNps8iR9LEy0UthTwg/Y7VqoLUVbb4W7PMPI04n+vvTmAbJ3cLEqM4LMQHwerZ3J7zdvC6mhPr+APURWTUA6o+6udof8ADASdlI8CF1TkQjG6n3Bxwoh6JDCJg/mJn9ARqssGz23QJscnmbi1AIZQF0wrwlEMKRUt6djZIWTwhXSlm3tspaPCFUYb7NW9jn7fKWyJHQjStfpGII3TRvCdwO3Rr2ZZA8Vsz3429zFvb5j5MW9vmvs7fMCP8AsSrbgv5ZO6cAAAAASUVORK5CYII=",
    ["grid-2x2"] = "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAYAAACqaXHeAAAABmJLR0QA/wD/AP+gvaeTAAADjklEQVR4nO2bzWsVVxjGnzcJmOBHMVgQF0Yo0driB1JD0XZhQV1KSrvwH/A/EER3haxEBCkU3QZLV+50YQUxmEKjFpFGSupGqUWhSL4gQZP8ujgJ3Ixn5s4cZziLex7IYt5z3vs888zMuTnvO1dKSEhI6GBYuwlAt6RPJR2UtDGA44Wk38xstkoSsEPSIUk7AjjnVjmfB+SuEzEEPOXDsQRcBfpKcPYD12vgBHgE7PmQk39Xk5A1jAM9BZy9wGTNnHPAZ1VPvpt6rrwPZwt4Rxri/B3wPu5dOVr2rv41gdMFY8MNcQ5J+sQ3kHc77vfEfpF0N4D8vKSBluN9QK+ZLbZOwq0PuzO5U5IuBXCelPRtJnZY0rPsxDwDNnlid83sWlUlwHdab0CPpD5Ji5mpvZK6M7HngZzS+wZs9s3NewQ6BsmA2AJiIxkQW0BsJANiC4iNZEBsAbGRDIgtIDY63oC8zdA/nth54PsAjqHM8bwkX3lsVq6U1bpp+Rr4NYBzlyf2b+lsYBuw3FBxYqyA905DnADbfZzeR8DM/pP0U2nHquFiwdiIJBrgHDWzV5UygE3AvZqvwuUSvBeo9+57AmwNsg3oAc7hamqhBdI5nJGnKvCeAG4C04GcS6sn/gOwoYirbV+gRVSvXCWnKmbNbDkgT0CXpI8CUheyJbeEhIQEH6osgn1ypeuqmDGzlYC8tcbsloDUehZBXK9uBNevWwr8SpoGbgEnKvAO4/qI84Gc74AJ3Fd4bi+ynYh+6m1ULgMXSvBeqZETYAzwNXraCvm5ZiEAK8CxAs7hBjgBfszj9K4BuJcTXlZ2rRzumNnxHN77ko42wLki6WMze5MdyHs+Dnlif0sKeePiK61fPIeA7ux/h7gF72Amd0bSgwDOQa3vR3ZJ+lLSrVLZwBnPbXQmQIiA257Pem9zAmz1zLsdyFlaf8dXhJIBsQXERjIgtoDYSAbEFhAbyYDYAmIjGRBbQGx0vAF5u8E5T+wkBHWtdmWOlyUteOYtSFrKaNoduAn7xhOb903MqwcMyr2n2wT+NLN9ObyPJR1oiHevmf2VDeY9As8kTTQk5EbB2PWGOCdV9YICn+P6enXiCQW9OlwvcrxmzrfAF0G2AXtwPzupA6OU6NICfbif14RWoVsxSZuTL9UXAAYkHVHOK+dt8FLSQzN7XSUJ2LLKuTOAc17SH5KmQnsSCQkJCR2B/wGDr01DxKl0zQAAAABJRU5ErkJggg==",
    ["house"] = "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAYAAACqaXHeAAAABmJLR0QA/wD/AP+gvaeTAAAC00lEQVR4nO2bv2sUQRTH3/gjohIwEIka2wQUBAvRoNhYCtr5L6SzFmJj4VlrqYV2/gkWJxoEKysxRQobi6T1dyI5TT4WNzFyN7s7ezOz746bDxzc7s68+b63M+/t3HIimUwmM8YYrYGBQyJy3R6+MMZsaWlpHGAeWGGPFWBeW1cjADeBL/TzHbilrS8ZwH7gHrDjcH6XHeARcFBbb1SAGWC5xPFeloEZbd1RAC4An2o4v8s6cEVbfxDAbaBT4GDHXq9so+1HbYDDwLOSu7sGXP6vfdUseQ4c1fTJG2AO+FDizBvghKPfNPCypN8qcFbDJ2+AG7hLHHhkePYqxXaBjeEslbGFhwayUYDjKaYufkvpZAqf6ohMmrzoJtOnJfb1SiWwCGwVCPsN3BnFsXzE1CpxEcfVL5UMWOIijq9XKhmSzEzTpbLxAf11pb8hHlPuW7Ip56dvriQIELIkgQW6Ca2MV5F9GkTn6wqNa8BCUf99BUZPiUhbRGYrxt8O0B6LKg2zItK2PvXhDICIXBORyRBVQ8akdH3qoygAHx3n3kaTkx6XVpdPxQBLwIb93Kf7zN9LO47ewcGdpKet5l39S4ManwAm7PepEQrAMXvtn/4iDpRdNMZ0YoptGh/9RTlgbMgB0BagTWkOCMUmoNAt6kbFWsZxzvulb7IA2NJzV0SOBJraBFrGmAcRZPWRZAkAl0SkJeHOi7XRsjajkyoHnBsRm8kCkMJukU3XenflBSdJk2APqyKy7tl2VkTOeLYdziTo4KEx5olPQ2BRRB572g2aAWP/HJADoC1AmxwAbQHa5ABoC9AmB0BbgDY5ANoCtBn7AIRuhk7bjUsvV13nwHuPUqd/1fvLUry3jcCUiHwOGaxBpowxX30ajv0SqBOAHyLyK5WQiGyKyE/fxt4BMMb8ke4PncNOy2r1ovafpoCLInK+br+GeG+MeactIpPJZEaGv8iSv7zRTJwzAAAAAElFTkSuQmCC",
    ["settings"] = "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAYAAACqaXHeAAAABmJLR0QA/wD/AP+gvaeTAAAEJ0lEQVR4nO2bz4scRRTHv28Tgpf4axaEoJCsIYj4axc0GoIIAY96SdRTjrkGPGbPkZz8G8wlLHgx10ASxXWz/jjsGgUvrh7EX7sRs0GQZN2Ph6pJemeqZ7p6urZmd+YDc5jqfvW+73VPdderGmnMmGwA+4B9uXVkATgH/OM/53Lr2VaAo3RzNIeWiRxOJT1fsS05uRIQ8ptFS64EDA3jBOQWkJvoBAAHgeeAPSkE1QHY4zUdjLWNSgDwgaQVSTclzQOtWIdN4zXMy2la8RqTODoEbHY8u5fqJAE4E3gPOFOjn5bXUGQTOFS1j5g74FFJ1tH2oqSrNZLwb8W2UrzPq15DEZPT2izABLAQuHLRdwJwAFgv2K8DByLsQ1e+zQKQZnDv4zg2CTPAJf+ZyaGhFsBjwNc9BEwm9v1NDt+dQnpdhc+BzrGiCZ/m+85z5QOCeiXhSAJ/R4Ym+IKoUBLuprgVgUnf93AEXxDWAua9oHvA2YS+znofeJ8DB9/YbxV4RtKama1VOHdS0rOSnvRNv0j63sxuVbSdNLMfBtG77fhB7D3gU2Aj8Fve8MfeIcEgmhXgMOWPzhCLwFRu3Y0AHAfWIoJvswocy61/IHATqNUawbe5BRxOqTHZbw33O/5S0suBw7clfSJp2X9/SdLbkh4JnLso6ZiZkUJnMoB3S67qJeDxwPktYK7E5lSOGAYC+Kwk+NK7DvekCCXheiqdXWKAV+RuyV7clXTFzH4NHcQ9q3+XVCyb3ZY0ZWZ/9eoY93KzIunhQvOGpCfKbHFT6Tcl9VtmWzKzr3o5n604OIGbwwenscAbgfM/6iOuaH8xYP96ybkzbK0t9GO2aD9R6GivpNkuD+Xsl/R+ybFQcWM50FbGtxX7lNewP6LvWR+rpHRl8dCIHeNr294E74sysw1J5yNs70j6sOTYb4G2mLW/FwJtwfHGa7gT0fd5H6ukdINgS9If6h4En+434cENoD8qxyDYJLiJTSdz9H8Mfhywu7YtopsEN6sLMUdgHo8reISCBziZSmfqV+EbkkIbH9YlXZa05L9PS3pLW2/7NguSju+4V2Hp/jrin5WezmHW2OnTYuA16s0IV4FXc+tvBGAKuBER/BfUWOkdanAj/CngOg8Km0XuAdeAk2xjSSxXUbQlVxR9Su6tsV0U7TlR8rbDVRRlh5fFBxU0ugsjJcG32d1LY32C392Lo2Rcoibj0nxbwOhukGDUt8gA001lHTgd6Od0ZB+9kjBdtZ+YTP2t7lLXsqQTVVZ1O3ioYlsp3ucJddcakdNaicoJMLOfJF3QgyQsql7wjVFIwqJvQtIFrzUNNLBVloY2Shb6q71Vdm//U7ZiZj/H2qTGzP6T9F0d2/Fu8dwCcjNOQCa/mxXbkpMrATcrtu1eGOU/TrZhlP86O2ZI+B9tBYYwdYCIPAAAAABJRU5ErkJggg==",
    ["shield"] = "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAYAAACqaXHeAAAABmJLR0QA/wD/AP+gvaeTAAAElklEQVR4nO3bTagVZRgH8PeYei0IvYqlRFKLMLtGkdmqTViEXKQMdFO0cCFaixYVboMgw2tGYItWgUmFRIu84ldBWETesFpYi6CsRQaGX5FadvXXYubW8fjOOTPnzJy50f3DLM6ceZ7//3nej5n3K4QpTKE2YCZm1q2jr8B0DGMXzqXXrvTe9Lr1VQYswQv4STZ+wWu4u269pQBz8TTG2gSdhbHUdm7dcRQCpuFB7Eird6/4A7uxBjPqji8TGMIIjhcI7q/0yovjKcdQ3fGGEELAHKzHpwWCgG8l/cEiLMAz+Kqgj2+wCfP7HXS3Vfw03sD9bXwP4WWcKOC3P00Et+vci7fiEg7iSVxXgGsAqySvx4sF+Mp/i2A29hcQAUfxHBaWwL8w9XW0oIb9mF1GAkZyEp7EdizvmTRby/KU42ROTSNlkO5rQzCOUUn7GyghxryaBlLO0VRDFvaVQXYg4ri0Kl6CvnZN5EAZBLEEDJagvVRgsJsETOuHuMmMqQTULaBuTCWgbgF1YyoBdQuoG1MJqFtAFrAM76TXsqp4JuUsLFaEEHaHEK5Nbw1jSaPR+LlsrklXAyLBhxDC9SGEB6rgm1QJyAh+At9VwTlpEtAh+C2NRmOsCt48fcB4N3aSJa/h9OeeRqNxsc2z7YLf1mg0NuXQGdMU014MeDsyzLytg80ADjc9fwTzMp5dgfMRDnilgM7FEfudnezyNIFTkXudVmtWhhDua/p9Twjho9Yk5Cj5Z3Poa6cppv0KdJuABTnsWnFXaEpCycFnaTrdyShPAo5F7t3bwWZvCOFI5P5EEtaGcoMPIYTYx9IPXfi5ElgaaVv7c9gN4ouMtp2FbT3oPBjxt6Rbf82Or8FvLY7PyDELjHn4OmfwuTu8CM8snG3xdxblvObxYUTwIzlt89SErks+5Xgs4rP3GeEmgqciBO8WsG9XE7ou+Sb/70X8ru/VbzPBfFcvY19QYF0goyb0VPKp35skC6TNuCjju6MXor29lp5kOX0Ee7CuJF2vRnSNluG7lWhlhOh33Fg6WX5NC8SX6B+uijDWme2ohCyfnp0RPV+iURVhrLe9jErG6h20rIhogUerJG3gUIT0e8ypjPhqHYM4FtHxcWWl30Q+JL5r44PKycM/hfB+hP9P3FE1/4SIlzKq3/N94N6Uwf1i1dzNImbgs4iIy3i8Qt61kn1HrRjT7z3HuFWy86sVFyRD3bL5HnL1Bw+cwi1l8+UVtUp8i8q5MpMg2ZYXmzUax3BnDxVCsp83hvNYXYL/1RnBw8YyYugZ2JIh8BLyTGhm+d0k3uZhc5kx9AxszhBKMrE6q4CvmXizjb+eB1GVAFvbiD6Em3P4WIRP2vjZ2o9YuoZk83TWDvAzeKKN7RrZmyDH9dCc+grJyLF1iqoZb2k6CCE5WBEb2EzgLFbWGVNh4E782CaoE1iXXr+2ee4YltYdT1fADZLtrN1iVL/PA5QNyeBlo2JnC85hgz4MrvoGydrd5zmCP4zFdeutBJLTJhsk3++tOJn+N2mW7CuDZJZ5u38PTr7+n2/r3cD/8ejsFCYZ/gZad+T8MDx6bAAAAABJRU5ErkJggg==",
    ["compass"] = "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAYAAACqaXHeAAAABmJLR0QA/wD/AP+gvaeTAAAGX0lEQVR4nO2baYhWVRjH/1edptwSI9QWiCKXycpMU3NQCAkUC4TKFARhQKgIsfwgBW7RAmWuBH3LTApcpj6ZWR+CQENB3DItCXJCUSg3XJjl14f7Tl7P+9x7z13eeYX8w3x475zn+f+fc859znqlW7iFugHoD/Srp4ag1gTAYElTJU2UNFzSSElDJQ1yip6TdFrSUUnHJe2R9GMQBP/UWmPpAIYBi4F9QCf50QnsBd4AhtU7rlQAE4GvgY4CQcehA2gFJtQ7zioAY4DvaxB0HHYBj5ehvVAOAAZKekfSa5J6e5p1SDop6W9JFyvPBki6S9J9kvpk8LNB0tIgCC6mFS4dwHjghEdrnQI2AvOBJuC2BJ+3AaMqZTcCpz38/w6M7cnYBbwKXEsQ1QlsAaYDvj3D4ukDzAC2kpxMrwILyowxTlAAvJsS+GfA8BpwjwA2AV0J/CvL5o0KCIBPEsj3AxNrJuC6jsnAgQQd62tF/F4C6ackvNs10NIAfJDQG1aUTfhKDNFV4KVSybLpmkN8LionJwDjYkguAM+UQlJM3zTgYkzjFBsdgIHYQ93VmyH4blQqwWqk34ABRRyvM5x21bPbxwGYG/MqrMrr8DGg3XC4umTtpQHYYOhtJ8+0GfjBcLafHsz2ES1NwFvAx8ATCeUagYOG7m+zEk4wnHQCkwpH469hFLAUOOzouJpSCZOxh8fxWci/MRxsLCWyZN7uoA8Z/FF8lOLnC8Nmu6+Ie6hez3cAI0qJsprPN+golqT4HEn12qEdGOojaLFBuLW0iEOOB4GFwE8Zgo5ilAfHdsNukY+4fYbh9BKCztPSFg558s00bPekGQ2muuucAnw3KSyfI4DdOQI9WflzsdSTtwE449h2ADdsxvZy7KYaz3YGQdCRtwIkbVa4I+yDNklrJTVLeiCmzBYfR0EQtEv6znncW9KUWCPCFZaL+T6EMf6aPFt6DeHw1StiO9ko69X9Iz5aDB/vR8u4XdvK9D9nIXXwYszzNknbFLbm7iAIujxtvVo/Akt7/GgGHHVqq50CMz+qJzEAs6MtHWPXC/v9T83+jp9Gqof0I0kG553CJ7IQOr5GGgGcBFJ3ooFmw/ZgTh1/OH5uOGmKvnOBpP6OfZFjqZeNZ1uCIMDDtozu341zzu8blsfRrthX1SPApZykUs4gKg0xy/hX3snYBed3b6Bv94/EdzEvgJGSmpzHbQoPPNMwWdL9zrNDQRAcLUObi2gFXJbkZmP3lfDFzdL9JWmg87szCILLZsmykiBwxEhiqUtpwuzfZthmyv6Oz8Qk6Ba2hsHGjITW5Cc1+xOeO8w2bDNNfhyf1jB4OFrGzQG/Or/7SHooI6/Vhbda3b8S9NOE22x/SvrKsC3S/R9W9aHtsegPdyZ4TNWYIOmXDKSJ73ClJ0yqlHtB4YlwEopUgHWXwIoxBDDL6ILeO0EJ3b93d0tjz/DisDdP1BE9mw2fzycZWMvh03guh4FlMRWQJehu7KbALhTxy+E70wz3GmJmeJJac/8sOExYie4cIk8FPGdVqo/hm4Zh6iwMeCRn0EeA5WUE7ehpNbgW+hgOofpApDNNILAkQ9CltXSMllHYm6JDfB1YtbcpxWZVPYN2tHxp8G/L4uApw0EXMDXBZizhoUVdgo7oaKbowUjF0S7DyQESZoaVSlgNvN2TQUf4b8dOxDvyOHsU+3B0bQ20lwLsKzz5DkcrDtcYDgHmlKy9MIB5MVo/LOJ0IOE9PBfXgGkl6i8E4FnsCxLHgLxL+v+cP0l1coPwWkrdK6ES/CVD3xVgTFkkC2K61zVgbikk+XTNi2l5gJayyVbGEAF8DtxRKmGylkZgbYKeZbUiXp9AehBorgnxjRqmkLzmWFdrASsSyLsIl6C5t7ASeJsIZ3hJV2Vr0/KGmAXYibEbnYTn8zOBhgI8DYSrulaSL0tfoex33kPcWMJ7eGk4Q3hlpQUYTfJMsrFSpoWwJ5318H+MAtm+6AcTAyStkPS6/D906JT0l6Szun7w0l/S3ZLulf+HF+2S1klaHgRBkQOc4iC8U7jTo7XKwg5gdF2DtkC4imzFXkMURTuwDRhX7zhTAQwFFgF7KPYFWQfh3uBCfDczMqInPpwcpOoPJ4cp/HCymx+Fp7inFJ5NHJe0W+GHk+drrbFuAPpR509nb+H/jn8BpClS1ESUACYAAAAASUVORK5CYII=",
    ["map-pin"] = "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",
    ["gamepad-2"] = "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAYAAACqaXHeAAAABmJLR0QA/wD/AP+gvaeTAAAFSUlEQVR4nO2aW4hVVRjH/9+go+PkjTTTyG5jgqGFhKJhalRm0KAVlOFD0L2op0jQIB8Kgl7y2Yd6iCgDB4JM8yHMzCy8EGKUlY2ZqaNT2NjopP562Pvgcp21z1l7n6MW7R+ch7P2d/l/66y19trrbKmkpKSkpKSkpKSkpOR/iBV1BCZKmiJpvKTBTVOUjwFJhyTtMbP9RQLk6gBgiqQnJN0vaWKRhBeQbklrJa02s2+bGhm4FvgAOMO/nzPAeyQjtCnFLwX+vLQ1FeI4sKTR4lde6iqawMu1asxcA4Blkl6v4btb0iZJ30s6WaiHG2eopBslzVeyIGfxkpm9ER0VWED2fF8H3Nqg8KYDzADWZ2g+A9wZG2g4cCAQ5BTw2AWuo2GAJ4GBgP5uoD0mwCsB59PAfZECZgCPAhMarqYgwKJUs8+Keo5DgaMBx5oLieO/wvE5DkxvSkUFyPghDwNDajk9EHD6Dqi70wMGAX95vu80taocAK3Aj4F6Frl2LZ7fvYFYb5rZ3xE5h0tq89quyKH5PIDpwLskm5oZef3NbEDSqsClhbWS7vZ66ywwLlLw6EBvf5JXeBprQjqFKvQB1xSM47PTtWlxjE3SDV6Mn83scI0ErWnhoyWNCpgMrlxPP7HPHncoGVEV2iXF3cYczOygpANec4f7xZ0CbUo2Fi6/ZgUHlkv6XVJv+vkpYDbPud4raR9wW4T2vZFtMfg1XAa0VlkBwwLDZXMoIjAzYBtLd4xqYDlwgmRhXZm77HNxvgxoCC/qVK/i+zLsljbQAWcBf6Rl6Wkl47aVXltMcufKjAfs9/Ifr5Xwm4DgqkWQ6kUqDx/HFF8LYAiwzYm5HfDvQALGBfLvcm0GeT7bJE312mZL6nIbzOwgME/Si5LGps2DJc31fHsl7XC+75L0WkSN9Vgoyb01TpfUKel9zy603nzlfvE7YIukxwNBurw2mdkOSY9UvpPcCXo9s+1mdndAxMUi1AFbMq2BSYEhszUmE03cB0Tkip0CoQWwIxTTdfrNcxgAhkWIGhlItr6BOuvlq7kIAm0kT7AumXsa17ErUMjtkaK6Pb/4Q4gmA8wN1LHWt/OfBaTwHInZvEjJmtAtCUnrJb0arbj5RM1/fxEMGmUEq8LMtgDXSWo3s75KO3C1pLsy8oU4LWmjmf0SaR9idqDti7peJAtMvzd0jhG/j/fjzSF5mMlLHzCnYE5LNbv0U+sswAuwOSCo1qFjVpwpQG+B4iv8AUwrkPemQKzPQrahNUBqbB2oiJggaZ2k0Xn8PEZKWkf+Pzmi7/8XpAOAUZI2SMr9DB/gKkkfpTFjiZ7/wXkNXC6px7v+g5lNqpc5nWcbVL0tlpIdZb29wT2SFgfaN0laYGanIjTs1fnP/Ugaa2bH6vm6QfYE5lHN0yGgBViTMZ83EnoOr47RmtqGWANkjdqK/5UBvz3RhTuBVgcCPVPHZ1WG8J3AiBy5R6Q+IULnfK7v8wGf1bG53UAPBQL1ANdn2C/LELwPGF8g//jUN8SyDJ8Owsf6D+bNXzkh6gkEO0Ly78sYkiE/DXg7Q+hRYHLu5Oc0TM4oCOAtYGqqYQzwVIbeQ0QewIQEPJeRPIYTwKyixTsaZqWxivJ0I8lbgA8LJD0NdDZavKOjk/BfXfXoouAO1k3elrMT+oGHm1S7q2MJcDJn8VVnBEWTtwAvkD0fK2wC/CO1pgHcDHxeR0MP8CyRv3zel6TalbwgNV/JiwlDJR1RctbXZWZf56ypEMBMSYsk3aLkTLJfyYsan6Y6TlwMHSUlJSUlJSUlJSUl/13+AVpPhjBo3dukAAAAAElFTkSuQmCC",
    ["zap"] = "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAYAAACqaXHeAAAABmJLR0QA/wD/AP+gvaeTAAAC+klEQVR4nO2aP2gUQRTG30gwCQRjYuGf1k4QbGKTxtrUsbWzUPBioY1aWihCFLS3NbVyra1WErAS8RTvYmHEzoRIfhZ7wmV9M7t7NztzN9kfpMnu7Pve7sd8c7Mr0tAwFgBzgImtIzjAPNAG9oEOsBxbU1CAdQ7SBWZj6woCMA1s8z+t2NqCAKwqzQP0DoULgNeWG5C+C4CTwJ7jBmyFcMGRugs4uCoiU47jp0TkWiAt4QE2HU8/qAuCAyxZJr7eoZgLgOdKow+BteRdABwFfiiNngdmgG9JuwC4ojT4duB42i5Az/7rA8fTdQF69u8CJ3LnpekC4I7S2EvlvDRdgJ79ly3npuUC4KLS0HdAXQ0m5wIs2V8wJg0X4Mj+gnFpuICC7C8YO/kuoCD7C8bW6oJKu7DAcRG5KyIXKta5JAd/+u6KyBljzM+SdVsi8iT37y0ROWuM+V1Ry/CQ7d76YKNi3Vli/1LsW3Hf0w1YGaJ+S7lO2B1k4IuH5r9iyf6C2mPhAm1GrsJHRnjxYakfzgWOp3APWCj4O1Zj/Zs++isrImouA7eU+uHeIxB5ddav321c0LhgPF3g5SlQPKEuAPeV+l1gxkd/ZUR6z2VgGfisXLMKk+kCYIpskTQqnRpatYr25gJgxUPzkC3Xp+vo1ybciwuADU83oF2l7sgfJfUb/SQip3OH1owxT0teY1FEeiIy+OT+iMibinLei8gDY8yviuNGw+KC0usC4IYy/lXdur3BiOsC4J0ydrVu3V4Z1gXAOWXcNiEnMh8M6wLgkTLmWSjdXqnqArLs12J0KbR2L1R1AXr2fwit2ytVXICe/bdj6PZGWRcAi8BO7pw9IL+emDzKuIBJz34XZVxACtnvwuUCUsl+Fy4XkFL2u7C4wPZB5GRmvwuHC/JEy/5aP5Y2xuyIyOMSp76oU0dUSrggjex3YZkL/pFG9rvAvncIKWW/C4sL0sp+F30X5N/mrMfWFRSyFx8dsq3rNjAfW1NwAAPMxdbR0JDxFxR/dON0qJeRAAAAAElFTkSuQmCC",
    ["terminal"] = "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAYAAACqaXHeAAAABmJLR0QA/wD/AP+gvaeTAAABX0lEQVR4nO3aMUpDQRjE8VkLEVSiJDYewwsoau8Z4hmsPICNeAVvINhILmGR3kZrO1ELhfe3UAvx5T3E7H6QnV8dNjPDS0hgJTMzMzOzTsAakKJzFAcMgAnQAPfAXnSmooBzfnoFDqJzFQNc81s9IwDjlgGqG+HCI8BZxwiH0fmK8AjyCJI8giSPIMkjSPIIkjyCJI8gySNI8giSev877EbnK6JjhIfobEUAI+CxZYAGWInOlxUwBKYznoBJdL6sespPgWF0xmyATeC2o/woOmM2Lu/yLu/yLu/yLu/yC6n28gNq/W0vtd4PqKe8NPN+QB3lpdb7AfWU/wYcAzdfH4eN6DzzFHbrC9iRdCJpK8Pxb5KuUkqXGc7+P2AbeJrx5TpP474sSyUKt9iXtF7gfY76XhA1wN2Cvc/fAafAS6ZHv+HzcuegL0fo1VdgWdJqhqPfU0rPGc41MzMzs4XxAWrHPS7JYjxaAAAAAElFTkSuQmCC",
}


local LucideIconCache = {}
local LucideIconNames = {}
for iconName in pairs(LucideIconData) do
    LucideIconNames[#LucideIconNames + 1] = iconName
end
table.sort(LucideIconNames)

local Base64Alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local Base64Lookup = {}
for index = 1, #Base64Alphabet do
    Base64Lookup[Base64Alphabet:sub(index, index)] = index - 1
end

local function decodeBase64(data)
    local output = {}
    local buffer = 0
    local bitCount = 0
    for index = 1, #data do
        local character = data:sub(index, index)
        if character == "=" then
            break
        end
        local value = Base64Lookup[character]
        if value then
            buffer = buffer * 64 + value
            bitCount = bitCount + 6
            if bitCount >= 8 then
                bitCount = bitCount - 8
                local byte = math.floor(buffer / (2 ^ bitCount)) % 256
                output[#output + 1] = string.char(byte)
                buffer = buffer % (2 ^ bitCount)
            end
        end
    end
    return table.concat(output)
end

local function getLucideAsset(iconName)
    if LucideIconCache[iconName] then
        return LucideIconCache[iconName]
    end
    local assetFunction = getGlobalFunction("getcustomasset") or getGlobalFunction("getsynasset")
    local writeFileFunction = getGlobalFunction("writefile")
    if not assetFunction or not writeFileFunction then
        return nil
    end
    local path = "UnnamedHook/Icons/" .. iconName .. ".png"
    local isFileFunction = getGlobalFunction("isfile")
    local makeFolderFunction = getGlobalFunction("makefolder")
    if makeFolderFunction then
        pcall(makeFolderFunction, "UnnamedHook")
        pcall(makeFolderFunction, "UnnamedHook/Icons")
    end
    local exists = false
    if isFileFunction then
        local success, result = pcall(isFileFunction, path)
        exists = success and result == true
    end
    if not exists then
        local encoded = LucideIconData[iconName]
        if not encoded then
            return nil
        end
        local success, bytes = pcall(decodeBase64, encoded)
        if not success or type(bytes) ~= "string" or #bytes == 0 then
            return nil
        end
        local written = pcall(writeFileFunction, path, bytes)
        if not written then
            return nil
        end
    end
    local success, asset = pcall(assetFunction, path)
    if success and type(asset) == "string" then
        LucideIconCache[iconName] = asset
        return asset
    end
    return nil
end

local TabIconDefaults = {
    player = "user-round",
    players = "user-round",
    interface = "sliders-horizontal",
    settings = "settings",
    combat = "crosshair",
    aim = "crosshair",
    visual = "eye",
    visuals = "eye",
    movement = "move",
    misc = "grid-2x2",
    main = "house",
    home = "house",
    protection = "shield",
    security = "shield",
    world = "compass",
    teleport = "map-pin",
    teleports = "map-pin",
    game = "gamepad-2",
    gameplay = "gamepad-2",
    exploits = "zap",
    developer = "terminal",
    debug = "terminal"
}

local function resolveLucideIcon(tabName, requestedIcon)
    local requested = tostring(requestedIcon or ""):lower():gsub("^lucide:", "")
    if LucideIconData[requested] then
        return requested
    end
    local normalizedName = tostring(tabName or ""):lower():gsub("[^%w]+", "")
    return TabIconDefaults[normalizedName] or "grid-2x2"
end

local function getGuiParent()
    local getHuiFunction = getGlobalFunction("gethui")
    if getHuiFunction then
        local success, parent = pcall(getHuiFunction)
        if success and parent then
            return parent
        end
    end
    local success, coreGui = pcall(function()
        return game:GetService("CoreGui")
    end)
    if success and coreGui then
        local probe = Instance.new("Folder")
        local canParent = pcall(function()
            probe.Parent = coreGui
        end)
        probe:Destroy()
        if canParent then
            return coreGui
        end
    end
    if not Player then
        error("Unnamed Hook must be run on the client")
    end
    return Player:WaitForChild("PlayerGui")
end

function Library:BindTheme(callback)
    table.insert(self.ThemeCallbacks, callback)
    callback(self.Theme)
end

function Library:SetTheme(theme)
    local selected = type(theme) == "string" and Themes[theme] or theme
    if type(selected) ~= "table" then
        return false
    end
    self.Theme = selected
    self.ThemeName = type(theme) == "string" and theme or "Custom"
    for _, callback in ipairs(self.ThemeCallbacks) do
        pcall(callback, selected)
    end
    return true
end

Library.ThemeManager = {}
function Library.ThemeManager:SetTheme(theme)
    return Library:SetTheme(theme)
end
function Library.ThemeManager:GetThemes()
    local names = {}
    for name in pairs(Themes) do
        table.insert(names, name)
    end
    table.sort(names)
    return names
end
function Library.ThemeManager:GetTheme()
    return Library.ThemeName, Library.Theme
end
function Library.ThemeManager:AddTheme(name, theme)
    if type(name) ~= "string" or type(theme) ~= "table" then
        return false
    end
    Themes[name] = copyTable(theme)
    return true
end

local function encodeValue(value)
    if typeof(value) == "Color3" then
        return { __type = "Color3", r = value.R, g = value.G, b = value.B }
    end
    if typeof(value) == "EnumItem" then
        return { __type = "EnumItem", enum = tostring(value.EnumType), name = value.Name }
    end
    if type(value) == "table" then
        local result = {}
        for key, item in pairs(value) do
            result[key] = encodeValue(item)
        end
        return result
    end
    return value
end

local function decodeValue(value)
    if type(value) ~= "table" then
        return value
    end
    if value.__type == "Color3" then
        return Color3.new(value.r or 1, value.g or 1, value.b or 1)
    end
    if value.__type == "EnumItem" then
        local enumName = tostring(value.enum or "Enum.KeyCode"):match("Enum%.(%w+)") or "KeyCode"
        local enumType = Enum[enumName]
        if enumType and value.name and enumType[value.name] then
            return enumType[value.name]
        end
        return Enum.KeyCode.Unknown
    end
    local result = {}
    for key, item in pairs(value) do
        result[key] = decodeValue(item)
    end
    return result
end

local function safeFileName(name)
    return tostring(name or "default"):gsub("[^%w_%-]", "_")
end

Library.ConfigManager = {}
Library.ConfigManager.Folder = "UnnamedHook"
Library.ConfigManager.ConfigFolder = "UnnamedHook/Configs"

function Library.ConfigManager:Save(name)
    name = safeFileName(name)
    local data = {
        Theme = Library.ThemeName,
        SelectionMode = Library.SelectionMode or "Normal",
        Values = {}
    }
    for flag, option in pairs(Library.Options) do
        if option and option.GetConfigValue then
            local success, value = pcall(option.GetConfigValue, option)
            if success then
                data.Values[flag] = encodeValue(value)
            end
        end
    end
    local encoded = HttpService:JSONEncode(data)
    Library.ConfigStorage[name] = encoded
    local makefolderFunction = getGlobalFunction("makefolder")
    local isfolderFunction = getGlobalFunction("isfolder")
    local writefileFunction = getGlobalFunction("writefile")
    if writefileFunction then
        pcall(function()
            if makefolderFunction and (not isfolderFunction or not isfolderFunction(self.Folder)) then
                makefolderFunction(self.Folder)
            end
            if makefolderFunction and (not isfolderFunction or not isfolderFunction(self.ConfigFolder)) then
                makefolderFunction(self.ConfigFolder)
            end
            writefileFunction(self.ConfigFolder .. "/" .. name .. ".json", encoded)
        end)
    end
    return true, encoded
end

function Library.ConfigManager:Load(name)
    name = safeFileName(name)
    local encoded = Library.ConfigStorage[name]
    local readfileFunction = getGlobalFunction("readfile")
    local isfileFunction = getGlobalFunction("isfile")
    local path = self.ConfigFolder .. "/" .. name .. ".json"
    if readfileFunction then
        local success, result = pcall(function()
            if isfileFunction and not isfileFunction(path) then
                return nil
            end
            return readfileFunction(path)
        end)
        if success and type(result) == "string" then
            encoded = result
        end
    end
    if type(encoded) ~= "string" then
        return false, "Config not found"
    end
    local success, data = pcall(function()
        return HttpService:JSONDecode(encoded)
    end)
    if not success or type(data) ~= "table" then
        return false, "Config could not be decoded"
    end
    if data.Theme then
        Library:SetTheme(data.Theme)
    end
    if data.SelectionMode then
        for _, window in ipairs(Library.Windows) do
            window:SetSelectionMode(data.SelectionMode)
        end
    end
    for flag, value in pairs(data.Values or {}) do
        local option = Library.Options[flag]
        if option and option.SetValue then
            pcall(option.SetValue, option, decodeValue(value), true)
        end
    end
    return true, "Config loaded"
end

function Library.ConfigManager:List()
    local results = {}
    for name in pairs(Library.ConfigStorage) do
        results[name] = true
    end
    local listfilesFunction = getGlobalFunction("listfiles")
    if listfilesFunction then
        local success, files = pcall(listfilesFunction, self.ConfigFolder)
        if success and type(files) == "table" then
            for _, path in ipairs(files) do
                local fileName = tostring(path):match("([^/\\]+)%.json$")
                if fileName then
                    results[fileName] = true
                end
            end
        end
    end
    local names = {}
    for name in pairs(results) do
        table.insert(names, name)
    end
    table.sort(names)
    return names
end

function Library.ConfigManager:Delete(name)
    name = safeFileName(name)
    Library.ConfigStorage[name] = nil
    local deleteFunction = getGlobalFunction("delfile")
    local isfileFunction = getGlobalFunction("isfile")
    local path = self.ConfigFolder .. "/" .. name .. ".json"
    if deleteFunction then
        pcall(function()
            if not isfileFunction or isfileFunction(path) then
                deleteFunction(path)
            end
        end)
    end
    return true
end

local function addRow(section, labelText, selectable)
    local window = section.Window
    local theme = Library.Theme
    local row = create("Frame", {
        Name = "OptionRow",
        BackgroundColor3 = theme.Row,
        BorderSizePixel = 0,
        Size = UDim2.new(1, -4, 0, 34)
    }, section.Container)
    addCorner(row, 3)
    local accent = create("Frame", {
        Name = "SelectionBar",
        BackgroundColor3 = theme.Accent,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 3, 1, -8),
        Position = UDim2.new(0, 0, 0, 4),
        Visible = false
    }, row)
    addCorner(accent, 2)
    local hitbox = create("TextButton", {
        Name = "Hitbox",
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
        Size = UDim2.fromScale(1, 1),
        ZIndex = 2
    }, row)
    local label = create("TextLabel", {
        Name = "Label",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(12, 0),
        Size = UDim2.new(0.58, -12, 1, 0),
        Font = Enum.Font.Gotham,
        Text = tostring(labelText),
        TextColor3 = theme.Text,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 3
    }, row)
    local control = {
        Window = window,
        Section = section,
        Row = row,
        Hitbox = hitbox,
        Label = label,
        Accent = accent,
        Selectable = selectable ~= false,
        Focused = false
    }
    function control:SetFocused(state)
        self.Focused = state
        self.Accent.Visible = state and self.Window.SelectionMode == "Normal"
        tween(self.Row, {
            BackgroundColor3 = state and Library.Theme.RowSelected or Library.Theme.Row
        }, 0.1)
    end
    function control:SetLabel(value)
        self.Label.Text = tostring(value)
    end
    function control:GetConfigValue()
        return self.Value
    end
    function control:SetValue(value)
        self.Value = value
    end
    function control:Activate() end
    function control:Adjust() end
    if selectable then
        table.insert(section.Tab.Controls, control)
        if section.Window.CurrentTab == section.Tab and not section.Window.FocusedControl then
            section.Tab:FocusControl(1)
        end
    end
    hitbox.Activated:Connect(function()
        if selectable then
            section.Tab:FocusControl(control)
        end
        if control.Activate then
            control:Activate()
        end
    end)
    hitbox.MouseEnter:Connect(function()
        if window.SelectionMode == "Mouse" then
            control:SetFocused(true)
        end
    end)
    hitbox.MouseLeave:Connect(function()
        if window.SelectionMode == "Mouse" and window.FocusedControl ~= control then
            control:SetFocused(false)
        end
    end)
    Library:BindTheme(function(newTheme)
        row.BackgroundColor3 = newTheme.Row
        label.TextColor3 = newTheme.Text
        accent.BackgroundColor3 = newTheme.Accent
        if control.Focused then
            row.BackgroundColor3 = newTheme.RowSelected
        end
    end)
    return control
end

local Section = {}
Section.__index = Section

function Section:AddLabel(text)
    local control = addRow(self, text, false)
    control.Row.BackgroundTransparency = 1
    control.Label.Position = UDim2.fromOffset(8, 0)
    control.Label.Size = UDim2.new(1, -16, 1, 0)
    control.Label.TextColor3 = Library.Theme.Muted
    control.Hitbox.Visible = false
    Library:BindTheme(function(theme)
        control.Label.TextColor3 = theme.Muted
    end)
    return control
end

function Section:AddButton(label, callback)
    local control = addRow(self, label, true)
    control.ValueLabel = create("TextLabel", {
        Name = "ActionHint",
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -12, 0.5, 0),
        Size = UDim2.fromOffset(24, 20),
        Font = Enum.Font.GothamBold,
        Text = ">",
        TextColor3 = Library.Theme.Muted,
        TextSize = 15,
        ZIndex = 3
    }, control.Row)
    function control:Activate()
        if callback then
            task.spawn(callback)
        end
    end
    Library:BindTheme(function(theme)
        control.ValueLabel.TextColor3 = theme.Muted
    end)
    return control
end

function Section:AddToggle(label, settings)
    if type(settings) == "function" then
        settings = { Callback = settings }
    elseif type(settings) == "boolean" then
        settings = { Default = settings }
    end
    settings = settings or {}
    local control = addRow(self, label, true)
    local flag = settings.Flag or makeFlag(label)
    local state = settings.Default == true
    local indicator = create("Frame", {
        Name = "ToggleIndicator",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -12, 0.5, 0),
        Size = UDim2.fromOffset(34, 17),
        BackgroundColor3 = Library.Theme.PanelLight,
        BorderSizePixel = 0,
        Active = true,
        ZIndex = 3
    }, control.Row)
    addCorner(indicator, 9)
    local dot = create("Frame", {
        Name = "ToggleDot",
        Position = UDim2.fromOffset(2, 2),
        Size = UDim2.fromOffset(13, 13),
        BackgroundColor3 = Library.Theme.Muted,
        BorderSizePixel = 0,
        ZIndex = 4
    }, indicator)
    addCorner(dot, 8)
    function control:SetValue(value, silent)
        state = value == true
        self.Value = state
        tween(indicator, { BackgroundColor3 = state and Library.Theme.AccentDark or Library.Theme.PanelLight }, 0.12)
        tween(dot, { Position = state and UDim2.fromOffset(19, 2) or UDim2.fromOffset(2, 2), BackgroundColor3 = state and Color3.new(1, 1, 1) or Library.Theme.Muted }, 0.12)
        if not silent and settings.Callback then
            task.spawn(settings.Callback, state)
        end
    end
    function control:Activate()
        self:SetValue(not state)
    end
    function control:Adjust(direction)
        if direction ~= 0 then
            self:SetValue(not state)
        end
    end
    control:SetValue(state, true)
    Library.Options[flag] = control
    Library:BindTheme(function(theme)
        if not state then
            indicator.BackgroundColor3 = theme.PanelLight
            dot.BackgroundColor3 = theme.Muted
        else
            indicator.BackgroundColor3 = theme.AccentDark
            dot.BackgroundColor3 = Color3.new(1, 1, 1)
        end
    end)
    return control
end

function Section:AddSlider(label, settings)
    settings = settings or {}
    local minimum = tonumber(settings.Min) or 0
    local maximum = tonumber(settings.Max) or 100
    local step = math.abs(tonumber(settings.Step) or 1)
    if maximum < minimum then
        minimum, maximum = maximum, minimum
    end
    if step == 0 then
        step = 1
    end
    local decimals = tonumber(settings.Decimals)
    if decimals == nil then
        decimals = step < 1 and 2 or 0
    end
    local control = addRow(self, label, true)
    local valueLabel = create("TextLabel", {
        Name = "Value",
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -12, 0, 2),
        Size = UDim2.fromOffset(82, 15),
        Font = Enum.Font.GothamSemibold,
        TextColor3 = Library.Theme.Text,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Right,
        ZIndex = 3
    }, control.Row)
    local track = create("Frame", {
        Name = "Track",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -12, 0.5, 8),
        Size = UDim2.fromOffset(122, 4),
        BackgroundColor3 = Library.Theme.PanelLight,
        BorderSizePixel = 0,
        Active = true,
        ZIndex = 3
    }, control.Row)
    addCorner(track, 3)
    local fill = create("Frame", {
        Name = "Fill",
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = Library.Theme.Accent,
        BorderSizePixel = 0,
        ZIndex = 4
    }, track)
    addCorner(fill, 3)
    local dragging = false
    local function formatValue(value)
        local formatted = string.format("%." .. tostring(decimals) .. "f", value)
        if decimals == 0 then
            formatted = tostring(math.floor(value + 0.5))
        end
        return formatted .. tostring(settings.Suffix or "")
    end
    local function setFromX(x)
        local ratio = math.clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
        local raw = minimum + (maximum - minimum) * ratio
        local snapped = minimum + math.floor(((raw - minimum) / step) + 0.5) * step
        control:SetValue(math.clamp(snapped, minimum, maximum))
    end
    function control:SetValue(value, silent)
        value = math.clamp(tonumber(value) or minimum, minimum, maximum)
        value = minimum + math.floor(((value - minimum) / step) + 0.5) * step
        value = math.clamp(value, minimum, maximum)
        self.Value = value
        local ratio = maximum == minimum and 0 or (value - minimum) / (maximum - minimum)
        fill.Size = UDim2.new(ratio, 0, 1, 0)
        valueLabel.Text = formatValue(value)
        if not silent and settings.Callback then
            task.spawn(settings.Callback, value)
        end
    end
    function control:Adjust(direction)
        self:SetValue((self.Value or minimum) + direction * step)
    end
    function control:Activate()
        local x = UserInputService:GetMouseLocation().X
        if x >= track.AbsolutePosition.X and x <= track.AbsolutePosition.X + track.AbsoluteSize.X then
            setFromX(x)
        end
    end
    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            setFromX(input.Position.X)
        end
    end)
    table.insert(control.Window.Connections, UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            setFromX(input.Position.X)
        end
    end))
    table.insert(control.Window.Connections, UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end))
    control:SetValue(settings.Default ~= nil and settings.Default or minimum, true)
    Library.Options[settings.Flag or makeFlag(label)] = control
    Library:BindTheme(function(theme)
        track.BackgroundColor3 = theme.PanelLight
        fill.BackgroundColor3 = theme.Accent
        valueLabel.TextColor3 = theme.Text
    end)
    return control
end

function Section:AddInput(label, settings)
    if type(settings) == "function" then
        settings = { Callback = settings }
    end
    settings = settings or {}
    local control = addRow(self, label, true)
    local inputBox = create("TextBox", {
        Name = "Input",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0.5, 0),
        Size = UDim2.fromOffset(160, 24),
        BackgroundColor3 = Library.Theme.PanelLight,
        BorderSizePixel = 0,
        ClearTextOnFocus = false,
        Font = Enum.Font.Gotham,
        PlaceholderText = tostring(settings.Placeholder or "Enter value"),
        PlaceholderColor3 = Library.Theme.Muted,
        Text = tostring(settings.Default or ""),
        TextColor3 = Library.Theme.Text,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 4
    }, control.Row)
    addCorner(inputBox, 3)
    create("UIPadding", { PaddingLeft = UDim.new(0, 7), PaddingRight = UDim.new(0, 7) }, inputBox)
    function control:SetValue(value, silent)
        self.Value = tostring(value or "")
        inputBox.Text = self.Value
        if not silent and settings.Callback then
            task.spawn(settings.Callback, self.Value)
        end
    end
    function control:Activate()
        inputBox:CaptureFocus()
    end
    inputBox.FocusLost:Connect(function(enterPressed)
        control.Value = inputBox.Text
        if enterPressed and settings.Callback then
            task.spawn(settings.Callback, control.Value)
        elseif settings.Callback and settings.FireOnFocusLost then
            task.spawn(settings.Callback, control.Value)
        end
    end)
    function control:GetConfigValue()
        return inputBox.Text
    end
    control:SetValue(settings.Default or "", true)
    Library.Options[settings.Flag or makeFlag(label)] = control
    Library:BindTheme(function(theme)
        inputBox.BackgroundColor3 = theme.PanelLight
        inputBox.TextColor3 = theme.Text
        inputBox.PlaceholderColor3 = theme.Muted
    end)
    return control
end

function Section:AddKeyPicker(label, settings)
    settings = settings or {}
    local control = addRow(self, label, true)
    local keyButton = create("TextButton", {
        Name = "KeyButton",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -12, 0.5, 0),
        Size = UDim2.fromOffset(92, 23),
        BackgroundColor3 = Library.Theme.PanelLight,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Font = Enum.Font.GothamSemibold,
        TextColor3 = Library.Theme.Text,
        TextSize = 11,
        Text = "None",
        ZIndex = 4
    }, control.Row)
    addCorner(keyButton, 3)
    function control:SetValue(value, silent)
        if type(value) == "string" then
            value = Enum.KeyCode[value] or Enum.KeyCode.Unknown
        end
        local nextValue = value or Enum.KeyCode.Unknown
        local changed = self.Value ~= nextValue
        self.Value = nextValue
        keyButton.Text = self.Value == Enum.KeyCode.Unknown and "None" or self.Value.Name
        if not silent and changed then
            if settings.Callback then
                task.spawn(settings.Callback, self.Value)
            end
            if settings.ChangedCallback then
                task.spawn(settings.ChangedCallback, self.Value)
            end
        end
    end
    function control:Activate()
        self.Window.CapturingKey = self
        keyButton.Text = "Press key..."
    end
    function control:GetConfigValue()
        return self.Value
    end
    function control:SetCapturedKey(value)
        self:SetValue(value)
    end
    keyButton.Activated:Connect(function()
        control:Activate()
    end)
    control:SetValue(settings.Default or Enum.KeyCode.Unknown, true)
    Library.Options[settings.Flag or makeFlag(label)] = control
    control.KeyCallback = settings.OnKey
    Library:BindTheme(function(theme)
        keyButton.BackgroundColor3 = theme.PanelLight
        keyButton.TextColor3 = theme.Text
    end)
    return control
end

function Section:AddDropdown(label, settings)
    if type(settings) == "table" and settings[1] ~= nil then
        settings = { Options = settings }
    end
    settings = settings or {}
    local options = settings.Options or {}
    local multi = settings.Multi == true
    local control = addRow(self, label, true)
    local valueButton = create("TextButton", {
        Name = "DropdownValue",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -12, 0.5, 0),
        Size = UDim2.fromOffset(152, 23),
        BackgroundColor3 = Library.Theme.PanelLight,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Font = Enum.Font.Gotham,
        TextColor3 = Library.Theme.Text,
        TextSize = 11,
        Text = "Select",
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 4
    }, control.Row)
    addCorner(valueButton, 3)
    local popup
    local popupItems = {}
    local selectedIndex = 1
    local function hasValue(list, value)
        for _, entry in ipairs(list) do
            if entry == value then
                return true
            end
        end
        return false
    end
    local function renderValue()
        if multi then
            valueButton.Text = #control.Value == 0 and "Select" or table.concat(control.Value, ", ")
        else
            valueButton.Text = control.Value == nil and "Select" or tostring(control.Value)
        end
    end
    local function closePopup()
        if popup then
            popup:Destroy()
            popup = nil
        end
        control.Window.CurrentDropdown = nil
    end
    local function choose(value)
        if multi then
            local result = copyTable(control.Value or {})
            local found = false
            for index, entry in ipairs(result) do
                if entry == value then
                    table.remove(result, index)
                    found = true
                    break
                end
            end
            if not found then
                table.insert(result, value)
            end
            control:SetValue(result)
        else
            control:SetValue(value)
            closePopup()
        end
    end
    local function rebuildPopup()
        if popup then
            popup:Destroy()
        end
        if multi then
            selectedIndex = math.clamp(selectedIndex, 1, math.max(#options, 1))
        else
            selectedIndex = table.find(options, control.Value) or 1
        end
        popupItems = {}
        local height = math.min(#options, 7) * 27 + 8
        local absolute = control.Row.AbsolutePosition
        popup = create("Frame", {
            Name = "DropdownPopup",
            Position = UDim2.fromOffset(absolute.X + control.Row.AbsoluteSize.X - 180, absolute.Y + control.Row.AbsoluteSize.Y + 3),
            Size = UDim2.fromOffset(174, math.max(height, 36)),
            BackgroundColor3 = Library.Theme.Panel,
            BorderSizePixel = 0,
            ZIndex = 50
        }, control.Window.Gui)
        addCorner(popup, 4)
        addStroke(popup)
        local list = create("ScrollingFrame", {
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Position = UDim2.fromOffset(4, 4),
            Size = UDim2.new(1, -8, 1, -8),
            CanvasSize = UDim2.new(0, 0, 0, #options * 27),
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = Library.Theme.Accent,
            ZIndex = 51
        }, popup)
        create("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, list)
        for index, option in ipairs(options) do
            local selected = multi and hasValue(control.Value or {}, option) or (not multi and control.Value == option)
            local item = create("TextButton", {
                Name = "Choice",
                LayoutOrder = index,
                Size = UDim2.new(1, -2, 0, 25),
                BackgroundColor3 = selected and Library.Theme.RowSelected or Library.Theme.Row,
                BorderSizePixel = 0,
                AutoButtonColor = false,
                Font = Enum.Font.Gotham,
                Text = tostring(option),
                TextColor3 = selected and Library.Theme.Accent or Library.Theme.Text,
                TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 52
            }, list)
            addCorner(item, 2)
            create("UIPadding", { PaddingLeft = UDim.new(0, 8) }, item)
            item.Activated:Connect(function()
                choose(option)
            end)
            popupItems[index] = item
        end
        control.Window.CurrentDropdown = control
    end
    function control:SetValue(value, silent)
        if multi then
            if type(value) ~= "table" then
                value = value == nil and {} or { value }
            end
            self.Value = copyTable(value)
        else
            self.Value = value
        end
        renderValue()
        if not silent and settings.Callback then
            task.spawn(settings.Callback, self.Value)
        end
        if popup then
            rebuildPopup()
        end
    end
    function control:Activate()
        if popup then
            closePopup()
        else
            rebuildPopup()
        end
    end
    function control:Adjust(direction)
        if #options == 0 or direction == 0 then
            return
        end
        if multi then
            selectedIndex = math.clamp(selectedIndex + direction, 1, #options)
            choose(options[selectedIndex])
        else
            local index = table.find(options, self.Value) or 0
            index = ((index - 1 + direction) % #options) + 1
            self:SetValue(options[index])
        end
    end
    function control:HandlePopupKey(keyCode)
        if not popup then
            return false
        end
        if keyCode == Enum.KeyCode.Escape then
            closePopup()
        elseif keyCode == Enum.KeyCode.Up then
            selectedIndex = math.max(1, selectedIndex - 1)
        elseif keyCode == Enum.KeyCode.Down then
            selectedIndex = math.min(#options, selectedIndex + 1)
        elseif keyCode == Enum.KeyCode.Return or keyCode == Enum.KeyCode.KeypadEnter then
            if options[selectedIndex] ~= nil then
                choose(options[selectedIndex])
            end
        end
        for index, item in ipairs(popupItems) do
            local selected = index == selectedIndex
            item.BackgroundColor3 = selected and Library.Theme.RowSelected or Library.Theme.Row
            item.TextColor3 = selected and Library.Theme.Accent or Library.Theme.Text
        end
        return true
    end
    control.ClosePopup = closePopup
    valueButton.Activated:Connect(function()
        control:Activate()
    end)
    local default = settings.Default
    if multi then
        default = type(default) == "table" and default or {}
    elseif default == nil and settings.AllowNull == true then
        default = nil
    elseif default == nil then
        default = options[1]
    end
    control:SetValue(default, true)
    if settings.Default ~= nil and not multi then
        selectedIndex = table.find(options, settings.Default) or 1
    end
    Library.Options[settings.Flag or makeFlag(label)] = control
    Library:BindTheme(function(theme)
        valueButton.BackgroundColor3 = theme.PanelLight
        valueButton.TextColor3 = theme.Text
        if popup then
            popup.BackgroundColor3 = theme.Panel
        end
    end)
    return control
end

function Section:AddColorPicker(label, settings)
    settings = settings or {}
    local control = addRow(self, label, true)
    local swatch = create("TextButton", {
        Name = "ColorSwatch",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -12, 0.5, 0),
        Size = UDim2.fromOffset(42, 20),
        BackgroundColor3 = Library.Theme.Accent,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        ZIndex = 4
    }, control.Row)
    addCorner(swatch, 3)
    local popup
    local hue = 0.32
    local saturation = 0.45
    local brightness = 0.9
    local function updateColor(silent)
        local color = Color3.fromHSV(hue, saturation, brightness)
        control:SetValue(color, silent)
    end
    local function setSV(position)
        if not popup then
            return
        end
        local area = popup:FindFirstChild("SVArea")
        if not area then
            return
        end
        saturation = math.clamp((position.X - area.AbsolutePosition.X) / math.max(area.AbsoluteSize.X, 1), 0, 1)
        brightness = 1 - math.clamp((position.Y - area.AbsolutePosition.Y) / math.max(area.AbsoluteSize.Y, 1), 0, 1)
        updateColor()
    end
    local function setHue(position)
        if not popup then
            return
        end
        local bar = popup:FindFirstChild("HueBar")
        if not bar then
            return
        end
        hue = math.clamp((position.X - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
        local color = Color3.fromHSV(hue, saturation, brightness)
        local area = popup:FindFirstChild("SVArea")
        if area then
            area.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
        end
        control:SetValue(color)
    end
    local function closePopup()
        if control.PopupConnection then
            control.PopupConnection:Disconnect()
            control.PopupConnection = nil
        end
        if popup then
            popup:Destroy()
            popup = nil
        end
        control.Window.ColorPickerOpen = nil
    end
    local function openPopup()
        closePopup()
        local absolute = control.Row.AbsolutePosition
        popup = create("Frame", {
            Name = "ColorPickerPopup",
            Position = UDim2.fromOffset(absolute.X + control.Row.AbsoluteSize.X - 206, absolute.Y + control.Row.AbsoluteSize.Y + 4),
            Size = UDim2.fromOffset(196, 190),
            BackgroundColor3 = Library.Theme.Panel,
            BorderSizePixel = 0,
            ZIndex = 60
        }, control.Window.Gui)
        addCorner(popup, 4)
        addStroke(popup)
        local sv = create("Frame", {
            Name = "SVArea",
            Position = UDim2.fromOffset(9, 9),
            Size = UDim2.fromOffset(178, 112),
            BackgroundColor3 = Color3.fromHSV(hue, 1, 1),
            BorderSizePixel = 0,
            Active = true,
            ZIndex = 61
        }, popup)
        addCorner(sv, 3)
        local white = create("Frame", {
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderSizePixel = 0,
            Size = UDim2.fromScale(1, 1),
            ZIndex = 62
        }, sv)
        local whiteGradient = create("UIGradient", {
            Rotation = 0,
            Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 0.95) })
        }, white)
        local black = create("Frame", {
            BackgroundColor3 = Color3.new(0, 0, 0),
            BorderSizePixel = 0,
            Size = UDim2.fromScale(1, 1),
            ZIndex = 63
        }, sv)
        create("UIGradient", {
            Rotation = 90,
            Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) })
        }, black)
        local marker = create("Frame", {
            Name = "Marker",
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(saturation, 1 - brightness),
            Size = UDim2.fromOffset(9, 9),
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderSizePixel = 0,
            ZIndex = 65
        }, sv)
        addCorner(marker, 8)
        addStroke(marker, Color3.new(0, 0, 0), 0.1)
        local hueBar = create("Frame", {
            Name = "HueBar",
            Position = UDim2.fromOffset(9, 129),
            Size = UDim2.fromOffset(178, 13),
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderSizePixel = 0,
            Active = true,
            ZIndex = 61
        }, popup)
        addCorner(hueBar, 3)
        create("UIGradient", {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
                ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
                ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
                ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
                ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
            })
        }, hueBar)
        local hexBox = create("TextBox", {
            Name = "HexInput",
            Position = UDim2.fromOffset(9, 151),
            Size = UDim2.fromOffset(178, 27),
            BackgroundColor3 = Library.Theme.PanelLight,
            BorderSizePixel = 0,
            ClearTextOnFocus = false,
            Font = Enum.Font.Gotham,
            TextColor3 = Library.Theme.Text,
            TextSize = 11,
            Text = "#" .. control.Value:ToHex(),
            ZIndex = 62
        }, popup)
        addCorner(hexBox, 3)
        sv.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                setSV(input.Position)
            end
        end)
        hueBar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                setHue(input.Position)
            end
        end)
        local moveConnection
        moveConnection = UserInputService.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
                    local mouse = UserInputService:GetMouseLocation()
                    if sv and mouse.X >= sv.AbsolutePosition.X and mouse.X <= sv.AbsolutePosition.X + sv.AbsoluteSize.X and mouse.Y >= sv.AbsolutePosition.Y and mouse.Y <= sv.AbsolutePosition.Y + sv.AbsoluteSize.Y then
                        setSV(mouse)
                        marker.Position = UDim2.fromScale(saturation, 1 - brightness)
                    elseif hueBar and mouse.X >= hueBar.AbsolutePosition.X and mouse.X <= hueBar.AbsolutePosition.X + hueBar.AbsoluteSize.X and mouse.Y >= hueBar.AbsolutePosition.Y - 5 and mouse.Y <= hueBar.AbsolutePosition.Y + hueBar.AbsoluteSize.Y + 5 then
                        setHue(mouse)
                    end
                end
            end
        end)
        control.PopupConnection = moveConnection
        table.insert(control.Window.Connections, moveConnection)
        hexBox.FocusLost:Connect(function()
            local hex = hexBox.Text:gsub("#", "")
            if #hex == 6 then
                local success, color = pcall(Color3.fromHex, hex)
                if success then
                    control:SetValue(color)
                end
            end
            hexBox.Text = "#" .. control.Value:ToHex()
        end)
        control.PopupRefresh = function()
            if popup and sv and marker and hexBox then
                sv.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
                marker.Position = UDim2.fromScale(saturation, 1 - brightness)
                hexBox.Text = "#" .. control.Value:ToHex()
            end
        end
        control.Window.ColorPickerOpen = control
    end
    function control:SetValue(value, silent)
        if typeof(value) ~= "Color3" then
            value = Library.Theme.Accent
        end
        self.Value = value
        hue, saturation, brightness = value:ToHSV()
        swatch.BackgroundColor3 = value
        if not silent and settings.Callback then
            task.spawn(settings.Callback, value)
        end
        if self.PopupRefresh then
            self.PopupRefresh()
        end
    end
    function control:Activate()
        if popup then
            closePopup()
        else
            openPopup()
        end
    end
    function control:GetConfigValue()
        return self.Value
    end
    control.ClosePopup = closePopup
    swatch.Activated:Connect(function()
        control:Activate()
    end)
    control:SetValue(settings.Default or Library.Theme.Accent, true)
    Library.Options[settings.Flag or makeFlag(label)] = control
    Library:BindTheme(function(theme)
        if popup then
            popup.BackgroundColor3 = theme.Panel
        end
    end)
    return control
end

local Tab = {}
Tab.__index = Tab
function Tab:AddSection(name)
    local sectionFrame = create("Frame", {
        Name = "Section",
        BackgroundColor3 = Library.Theme.Panel,
        BorderSizePixel = 0,
        Size = UDim2.new(1, -8, 0, 36)
    }, self.Content)
    addCorner(sectionFrame, 4)
    addStroke(sectionFrame)
    local heading = create("TextLabel", {
        Name = "Heading",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(10, 0),
        Size = UDim2.new(1, -20, 0, 28),
        Font = Enum.Font.GothamBold,
        Text = tostring(name),
        TextColor3 = Library.Theme.Accent,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left
    }, sectionFrame)
    local container = create("Frame", {
        Name = "Options",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(5, 30),
        Size = UDim2.new(1, -10, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y
    }, sectionFrame)
    local layout = create("UIListLayout", {
        Padding = UDim.new(0, 4),
        SortOrder = Enum.SortOrder.LayoutOrder
    }, container)
    local section = setmetatable({ Window = self.Window, Tab = self, Frame = sectionFrame, Container = container, Layout = layout }, Section)
    local function updateSize()
        sectionFrame.Size = UDim2.new(1, -8, 0, 36 + container.AbsoluteSize.Y)
    end
    container.ChildAdded:Connect(updateSize)
    container.ChildRemoved:Connect(updateSize)
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateSize)
    Library:BindTheme(function(theme)
        sectionFrame.BackgroundColor3 = theme.Panel
        heading.TextColor3 = theme.Accent
        local stroke = sectionFrame:FindFirstChildOfClass("UIStroke")
        if stroke then
            stroke.Color = theme.Border
        end
    end)
    return section
end

function Tab:FocusControl(controlOrIndex)
    local previous = self.FocusedControl
    if previous and previous.SetFocused then
        previous:SetFocused(false)
    end
    local index
    if type(controlOrIndex) == "number" then
        index = controlOrIndex
    else
        index = table.find(self.Controls, controlOrIndex)
    end
    if not index or #self.Controls == 0 then
        self.SelectedIndex = 0
        self.FocusedControl = nil
        self.Window.FocusedControl = nil
        return
    end
    index = math.clamp(index, 1, #self.Controls)
    self.SelectedIndex = index
    self.FocusedControl = self.Controls[index]
    self.Window.FocusedControl = self.FocusedControl
    self.FocusedControl:SetFocused(true)
    local row = self.FocusedControl.Row
    local page = self.Content
    local top = row.AbsolutePosition.Y - page.AbsolutePosition.Y + page.CanvasPosition.Y
    local bottom = top + row.AbsoluteSize.Y
    local current = page.CanvasPosition.Y
    if top < current then
        page.CanvasPosition = Vector2.new(0, top)
    elseif bottom > current + page.AbsoluteSize.Y then
        page.CanvasPosition = Vector2.new(0, bottom - page.AbsoluteSize.Y)
    end
end

function Tab:MoveSelection(direction)
    if #self.Controls == 0 then
        return
    end
    local nextIndex = (self.SelectedIndex or 1) + direction
    if nextIndex < 1 then
        nextIndex = #self.Controls
    elseif nextIndex > #self.Controls then
        nextIndex = 1
    end
    self:FocusControl(nextIndex)
end

local Window = {}
Window.__index = Window

function Library:CreateWindow(settings)
    settings = settings or {}
    local guiParent = getGuiParent()
    local gui = create("ScreenGui", {
        Name = "UnnamedHookUI",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 1000
    }, guiParent)
    local protectGuiFunction = getGlobalFunction("protectgui") or getGlobalFunction("protect_gui")
    if protectGuiFunction then
        pcall(protectGuiFunction, gui)
    end
    local window = setmetatable({
        Gui = gui,
        Tabs = {},
        Items = {},
        SelectionMode = "Normal",
        Open = true,
        ToggleKey = settings.ToggleKey or Enum.KeyCode.RightShift,
        FocusedControl = nil,
        CapturingKey = nil,
        CurrentDropdown = nil,
        ColorPickerOpen = nil,
        Connections = {},
        Title = settings.Title or "Unnamed Hook",
        SelectionMode = settings.SelectionMode == "Mouse" and "Mouse" or "Normal"
    }, Window)
    table.insert(Library.Windows, window)
    Library.SelectionMode = window.SelectionMode

    local main = create("Frame", {
        Name = "Main",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = settings.Size or UDim2.fromOffset(446, 554),
        BackgroundColor3 = Color3.fromRGB(5, 6, 8),
        BackgroundTransparency = 0.08,
        BorderSizePixel = 0
    }, gui)
    window.Main = main
    addCorner(main, 6)
    addStroke(main, Library.Theme.Border)

    local topbar = create("Frame", {
        Name = "Topbar",
        Size = UDim2.new(1, 0, 0, 70),
        BackgroundColor3 = Color3.fromRGB(5, 5, 5),
        BorderSizePixel = 0,
        Active = true
    }, main)
    addCorner(topbar, 6)
    local topbarCover = create("Frame", {
        BackgroundColor3 = Library.Theme.Panel,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 1, -8),
        Size = UDim2.new(1, 0, 0, 8)
    }, topbar)
    create("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(5, 5, 5)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(80, 0, 0)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(5, 5, 5))
        }),
        Rotation = 90
    }, topbar)
    local logo = create("TextLabel", {
        Name = "Logo",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(12, 0),
        Size = UDim2.fromOffset(0, 70),
        Font = Enum.Font.GothamBlack,
        Text = "",
        TextColor3 = Library.Theme.Accent,
        TextSize = 19,
        TextXAlignment = Enum.TextXAlignment.Left
    }, topbar)
    local title = create("TextLabel", {
        Name = "Title",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(10, 0),
        Size = UDim2.new(0.7, -10, 1, 0),
        Font = Enum.Font.GothamBold,
        Text = "UH.lua",
        TextColor3 = Library.Theme.Text,
        TextSize = 26,
        TextXAlignment = Enum.TextXAlignment.Left
    }, topbar)
    local topHint = create("TextLabel", {
        Name = "TopHint",
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -14, 0, 0),
        Size = UDim2.fromOffset(210, 48),
        Font = Enum.Font.Gotham,
        Text = "UNNAMED HOOK  /  CLIENT",
        TextColor3 = Library.Theme.Muted,
        TextSize = 9,
        TextXAlignment = Enum.TextXAlignment.Right
    }, topbar)

    local sidebar = create("Frame", {
        Name = "Sidebar",
        Position = UDim2.fromOffset(0, 70),
        Size = UDim2.new(0, 172, 1, -70),
        BackgroundColor3 = Color3.fromRGB(7, 8, 10),
        BackgroundTransparency = 0.05,
        BorderSizePixel = 0
    }, main)
    local sidebarLine = create("Frame", {
        Position = UDim2.new(1, -1, 0, 0),
        Size = UDim2.new(0, 1, 1, 0),
        BackgroundColor3 = Library.Theme.Border,
        BorderSizePixel = 0
    }, sidebar)
    local tabList = create("Frame", {
        Name = "TabList",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(8, 10),
        Size = UDim2.new(1, -16, 1, -20)
    }, sidebar)
    create("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, tabList)
    local sidebarFooter = create("TextLabel", {
        Name = "Footer",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 1, -32),
        Size = UDim2.new(1, -20, 0, 20),
        Font = Enum.Font.Gotham,
        Text = "UH  •  BUILD 01",
        TextColor3 = Library.Theme.Muted,
        TextSize = 9,
        TextXAlignment = Enum.TextXAlignment.Left
    }, sidebar)

    local pageHolder = create("Frame", {
        Name = "PageHolder",
        Position = UDim2.fromOffset(172, 70),
        Size = UDim2.new(1, -172, 1, -102),
        BackgroundTransparency = 1,
        ClipsDescendants = true
    }, main)
    local pageTitle = create("TextLabel", {
        Name = "PageTitle",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(12, 6),
        Size = UDim2.new(1, -24, 0, 28),
        Font = Enum.Font.GothamBold,
        Text = "PERSONAL MENU",
        TextColor3 = Library.Theme.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left
    }, pageHolder)
    local pageSubtitle = create("TextLabel", {
        Name = "PageSubtitle",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(12, 32),
        Size = UDim2.new(1, -24, 0, 18),
        Font = Enum.Font.Gotham,
        Text = "Select a category to view available options",
        TextColor3 = Library.Theme.Muted,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left
    }, pageHolder)
    local pages = create("Frame", {
        Name = "Pages",
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(8, 56),
        Size = UDim2.new(1, -16, 1, -63)
    }, pageHolder)
    local footer = create("Frame", {
        Name = "NavigationFooter",
        Position = UDim2.new(0, 172, 1, -32),
        Size = UDim2.new(1, -172, 0, 32),
        BackgroundColor3 = Library.Theme.Panel,
        BorderSizePixel = 0
    }, main)
    local footerText = create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(14, 0),
        Size = UDim2.new(1, -28, 1, 0),
        Font = Enum.Font.Gotham,
        Text = "↑  ↓  SELECT     ←  →  ADJUST     ENTER  CONFIRM     RIGHT SHIFT  HIDE",
        TextColor3 = Library.Theme.Muted,
        TextSize = 9,
        TextXAlignment = Enum.TextXAlignment.Left
    }, footer)

    window.PageTitle = pageTitle
    window.PageSubtitle = pageSubtitle
    window.FooterText = footerText
    window.TabList = tabList
    window.Pages = pages

    function window:AddTab(name, icon)
        local tabNameValue = tostring(name)
        local iconName = resolveLucideIcon(tabNameValue, icon)
        local tabButton = create("TextButton", {
            Name = "Tab_" .. tabNameValue,
            Size = UDim2.new(1, 0, 0, 34),
            BackgroundColor3 = Color3.fromRGB(0, 0, 0),
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Font = Enum.Font.GothamSemibold,
            Text = "",
            ZIndex = 2
        }, self.TabList)
        tabButton.BackgroundTransparency = 0.05
        local marker = create("TextLabel", {
            Name = "SelectionMarker",
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(5, 0),
            Size = UDim2.fromOffset(14, 34),
            Font = Enum.Font.GothamBold,
            Text = "",
            TextColor3 = Library.Theme.Accent,
            TextSize = 15,
            TextXAlignment = Enum.TextXAlignment.Center,
            Visible = false,
            ZIndex = 4
        }, tabButton)
        local tabName = create("TextLabel", {
            Name = "TabName",
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(15, 0),
            Size = UDim2.new(1, -43, 1, 0),
            Font = Enum.Font.GothamSemibold,
            Text = tabNameValue,
            TextColor3 = Library.Theme.Muted,
            TextSize = 15,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            ZIndex = 3
        }, tabButton)
        local tabIcon = create("ImageLabel", {
            Name = "LucideIcon",
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -8, 0.5, 0),
            Size = UDim2.fromOffset(17, 17),
            Image = "",
            ImageColor3 = Library.Theme.Muted,
            ScaleType = Enum.ScaleType.Fit,
            ZIndex = 4
        }, tabButton)
        local iconFallback = create("TextLabel", {
            Name = "LucideFallback",
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -8, 0.5, 0),
            Size = UDim2.fromOffset(17, 17),
            Font = Enum.Font.Gotham,
            Text = "◇",
            TextColor3 = Library.Theme.Muted,
            TextSize = 13,
            Visible = true,
            ZIndex = 4
        }, tabButton)
        task.spawn(function()
            local asset = getLucideAsset(iconName)
            if asset and tabIcon.Parent then
                tabIcon.Image = asset
                tabIcon.Visible = true
                iconFallback.Visible = false
            end
        end)
        local content = create("ScrollingFrame", {
            Name = "Content_" .. tostring(name),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.fromScale(1, 1),
            CanvasSize = UDim2.new(0, 0, 0, 0),
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = Library.Theme.Accent,
            Visible = false
        }, self.Pages)
        local layout = create("UIListLayout", {
            Padding = UDim.new(0, 9),
            SortOrder = Enum.SortOrder.LayoutOrder
        }, content)
        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            content.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 8)
        end)
        local tab = setmetatable({ Window = self, Name = tabNameValue, IconName = iconName, Button = tabButton, Marker = marker, TabName = tabName, Icon = tabIcon, IconFallback = iconFallback, Content = content, Controls = {}, SelectedIndex = 1 }, Tab)
        table.insert(self.Tabs, tab)
        tabButton.Activated:Connect(function()
            self:SelectTab(tab)
        end)
        Library:BindTheme(function(theme)
            tabButton.BackgroundColor3 = self.CurrentTab == tab and Color3.fromRGB(22, 34, 68) or Color3.fromRGB(0, 0, 0)
            tabName.Text = (self.CurrentTab == tab and "> " or "  ") .. tabNameValue
            tabName.Text = self.CurrentTab == tab and ("> " .. tabNameValue) or tabNameValue
            tabName.TextColor3 = self.CurrentTab == tab and theme.Text or theme.Muted
            marker.TextColor3 = theme.Accent
            tabIcon.ImageColor3 = self.CurrentTab == tab and theme.Accent or theme.Muted
            iconFallback.TextColor3 = self.CurrentTab == tab and theme.Accent or theme.Muted
            content.ScrollBarImageColor3 = theme.Accent
        end)
        if #self.Tabs == 1 then
            self:SelectTab(tab)
        end
        return tab
    end

    function window:SelectTab(tabOrName)
        local tab = tabOrName
        if type(tabOrName) == "string" then
            for _, item in ipairs(self.Tabs) do
                if item.Name == tabOrName then
                    tab = item
                    break
                end
            end
        end
        if type(tabOrName) == "number" then
            tab = self.Tabs[tabOrName]
        end
        if not tab then
            return false
        end
        if self.CurrentTab and self.CurrentTab.FocusedControl then
            self.CurrentTab.FocusedControl:SetFocused(false)
        end
        self.CurrentTab = tab
        for _, item in ipairs(self.Tabs) do
            local active = item == tab
            item.Content.Visible = active
            item.Marker.Visible = false
            item.Marker.Text = ""
            item.Button.BackgroundColor3 = active and Color3.fromRGB(22, 34, 68) or Color3.fromRGB(0, 0, 0)
            item.TabName.Text = active and ("> " .. item.Name) or item.Name
            item.TabName.TextColor3 = active and Library.Theme.Text or Library.Theme.Muted
            item.Icon.ImageColor3 = active and Library.Theme.Accent or Library.Theme.Muted
            item.IconFallback.TextColor3 = active and Library.Theme.Accent or Library.Theme.Muted
        end
        self.PageTitle.Text = tab.Name:upper()
        self.PageSubtitle.Text = "Use the arrow keys to navigate and enter to confirm"
        if #tab.Controls > 0 then
            tab:FocusControl(math.clamp(tab.SelectedIndex or 1, 1, #tab.Controls))
        else
            self.FocusedControl = nil
        end
        return true
    end

    local movementActionName = "UH_BlockPlayerMovement"
    local movementKeys = {
        Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D,
        Enum.KeyCode.Up, Enum.KeyCode.Down, Enum.KeyCode.Left, Enum.KeyCode.Right,
        Enum.KeyCode.Space, Enum.KeyCode.Thumbstick1, Enum.KeyCode.ButtonA,
        Enum.KeyCode.E, Enum.KeyCode.F, Enum.KeyCode.Q
    }
    local movementBlocked = false
    local playerControls
    local function setMovementBlocked(shouldBlock)
        shouldBlock = shouldBlock == true
        if movementBlocked == shouldBlock then
            return
        end
        movementBlocked = shouldBlock
        if shouldBlock then
            pcall(function()
                local playerScripts = Player:WaitForChild("PlayerScripts")
                local playerModule = require(playerScripts:WaitForChild("PlayerModule"))
                playerControls = playerModule:GetControls()
                playerControls:Disable()
            end)
            ContextActionService:BindActionAtPriority(movementActionName, function()
                return Enum.ContextActionResult.Sink
            end, false, Enum.ContextActionPriority.High.Value + 100, table.unpack(movementKeys))
        else
            ContextActionService:UnbindAction(movementActionName)
            if playerControls then
                pcall(function()
                    playerControls:Enable()
                end)
                playerControls = nil
            end
        end
    end

    function window:SetSelectionMode(mode)
        mode = tostring(mode or "Normal")
        if mode:lower() == "mouse" then
            self.SelectionMode = "Mouse"
        else
            self.SelectionMode = "Normal"
        end
        Library.SelectionMode = self.SelectionMode
        setMovementBlocked(self.Open and self.SelectionMode == "Normal")
        self.FooterText.Text = self.SelectionMode == "Normal" and "↑  ↓  SELECT     ←  →  ADJUST     ENTER  CONFIRM     RIGHT SHIFT  HIDE" or "MOUSE  SELECT     CLICK  OPTIONS     RIGHT SHIFT  HIDE"
        for _, tab in ipairs(self.Tabs) do
            for _, control in ipairs(tab.Controls) do
                control.Accent.Visible = control.Focused and self.SelectionMode == "Normal"
            end
        end
    end

    function window:SetOpen(state)
        self.Open = state == true
        main.Visible = self.Open
        setMovementBlocked(self.Open and self.SelectionMode == "Normal")
        if not self.Open then
            if self.CurrentDropdown and self.CurrentDropdown.ClosePopup then
                self.CurrentDropdown:ClosePopup()
            end
            if self.ColorPickerOpen and self.ColorPickerOpen.ClosePopup then
                self.ColorPickerOpen:ClosePopup()
            end
            self.CapturingKey = nil
        end
    end

    function window:Toggle()
        self:SetOpen(not self.Open)
    end

    function window:CreateWatermark(text)
        if self.Watermark then
            self.Watermark:Destroy()
        end
        local watermark = create("Frame", {
            Name = "UH_Watermark",
            Position = UDim2.fromOffset(14, 14),
            Size = UDim2.fromOffset(220, 28),
            BackgroundColor3 = Library.Theme.Panel,
            BorderSizePixel = 0
        }, self.Gui)
        addCorner(watermark, 4)
        addStroke(watermark)
        local accent = create("Frame", {
            Size = UDim2.new(0, 3, 1, -8),
            Position = UDim2.fromOffset(0, 4),
            BackgroundColor3 = Library.Theme.Accent,
            BorderSizePixel = 0
        }, watermark)
        addCorner(accent, 2)
        local watermarkText = create("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(11, 0),
            Size = UDim2.new(1, -18, 1, 0),
            Font = Enum.Font.GothamBold,
            Text = tostring(text or "UNNAMED HOOK"),
            TextColor3 = Library.Theme.Text,
            TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left
        }, watermark)
        self.Watermark = watermark
        watermark.Active = true
        local watermarkDragging = false
        local watermarkDragStart
        local watermarkStartPosition
        table.insert(self.Connections, watermark.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                watermarkDragging = true
                watermarkDragStart = input.Position
                watermarkStartPosition = watermark.Position
            end
        end))
        table.insert(self.Connections, UserInputService.InputChanged:Connect(function(input)
            if watermarkDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position - watermarkDragStart
                watermark.Position = UDim2.new(
                    watermarkStartPosition.X.Scale,
                    watermarkStartPosition.X.Offset + delta.X,
                    watermarkStartPosition.Y.Scale,
                    watermarkStartPosition.Y.Offset + delta.Y
                )
            end
        end))
        table.insert(self.Connections, UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                watermarkDragging = false
            end
        end))
        Library:BindTheme(function(theme)
            watermark.BackgroundColor3 = theme.Panel
            accent.BackgroundColor3 = theme.Accent
            watermarkText.TextColor3 = theme.Text
            local stroke = watermark:FindFirstChildOfClass("UIStroke")
            if stroke then
                stroke.Color = theme.Border
            end
        end)
        return watermark
    end

    function window:Notify(message, duration)
        local notification = create("Frame", {
            Name = "Notification",
            AnchorPoint = Vector2.new(1, 1),
            Position = UDim2.new(1, -18, 1, -18),
            Size = UDim2.fromOffset(260, 54),
            BackgroundColor3 = Library.Theme.Panel,
            BorderSizePixel = 0
        }, self.Gui)
        addCorner(notification, 4)
        addStroke(notification)
        local bar = create("Frame", {
            Size = UDim2.new(0, 3, 1, -10),
            Position = UDim2.fromOffset(0, 5),
            BackgroundColor3 = Library.Theme.Accent,
            BorderSizePixel = 0
        }, notification)
        addCorner(bar, 2)
        local textLabel = create("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(12, 0),
            Size = UDim2.new(1, -22, 1, 0),
            Font = Enum.Font.Gotham,
            Text = tostring(message),
            TextColor3 = Library.Theme.Text,
            TextSize = 11,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left
        }, notification)
        notification.Position = UDim2.new(1, 280, 1, -18)
        tween(notification, { Position = UDim2.new(1, -18, 1, -18) }, 0.2)
        task.delay(duration or 3, function()
            if notification.Parent then
                tween(notification, { Position = UDim2.new(1, 280, 1, -18), BackgroundTransparency = 1 }, 0.2)
                task.delay(0.22, function()
                    if notification then
                        notification:Destroy()
                    end
                end)
            end
        end)
    end

    local function onInputBegan(input, processed)
        if window.CapturingKey and input.KeyCode ~= Enum.KeyCode.Unknown then
            local capture = window.CapturingKey
            window.CapturingKey = nil
            local key = input.KeyCode
            if key == Enum.KeyCode.Escape then
                key = Enum.KeyCode.Unknown
            end
            capture:SetCapturedKey(key)
            return
        end
        if input.KeyCode == window.ToggleKey then
            window:Toggle()
            return
        end
        if not window.Open then
            return
        end
        if processed and not (window.SelectionMode == "Normal" and window.CurrentTab) then
            return
        end
        if UserInputService:GetFocusedTextBox() then
            return
        end
        if window.CurrentDropdown and window.CurrentDropdown.HandlePopupKey then
            local handled = window.CurrentDropdown:HandlePopupKey(input.KeyCode)
            if handled then
                return
            end
        end
        if window.ColorPickerOpen and (input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.Backspace) then
            window.ColorPickerOpen:ClosePopup()
            return
        end
        if window.SelectionMode == "Normal" and window.CurrentTab then
            local tab = window.CurrentTab
            local key = input.KeyCode
            if key == Enum.KeyCode.Up or key == Enum.KeyCode.W then
                tab:MoveSelection(-1)
            elseif key == Enum.KeyCode.Down or key == Enum.KeyCode.S then
                tab:MoveSelection(1)
            elseif key == Enum.KeyCode.Left or key == Enum.KeyCode.A then
                if window.FocusedControl and window.FocusedControl.Adjust then
                    window.FocusedControl:Adjust(-1)
                end
            elseif key == Enum.KeyCode.Right or key == Enum.KeyCode.D then
                if window.FocusedControl and window.FocusedControl.Adjust then
                    window.FocusedControl:Adjust(1)
                end
            elseif key == Enum.KeyCode.Return or key == Enum.KeyCode.KeypadEnter or key == Enum.KeyCode.Space then
                if window.FocusedControl and window.FocusedControl.Activate then
                    window.FocusedControl:Activate()
                end
            elseif key == Enum.KeyCode.Tab then
                local index = table.find(window.Tabs, window.CurrentTab) or 1
                index = index % #window.Tabs + 1
                window:SelectTab(index)
            end
        end
    end

    local dragging = false
    local dragStart
    local startPosition
    topbar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPosition = main.Position
        end
    end)
    table.insert(window.Connections, UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            main.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X, startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)
        end
    end))
    table.insert(window.Connections, UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end))

    table.insert(window.Connections, UserInputService.InputBegan:Connect(onInputBegan))
    table.insert(window.Connections, UserInputService.InputBegan:Connect(function(input, processed)
        if processed or not window.Open or window.CapturingKey then
            return
        end
        if UserInputService:GetFocusedTextBox() then
            return
        end
        for _, tab in ipairs(window.Tabs) do
            for _, control in ipairs(tab.Controls) do
                if control.Value and typeof(control.Value) == "EnumItem" and control.Value.EnumType == Enum.KeyCode and control.Value == input.KeyCode and control.KeyCallback then
                    task.spawn(control.KeyCallback, input.KeyCode)
                end
            end
        end
    end))

    table.insert(window.Connections, gui.AncestryChanged:Connect(function(_, parent)
        if not parent then
            for _, connection in ipairs(window.Connections) do
                pcall(function()
                    connection:Disconnect()
                end)
            end
        end
    end))

    Library:BindTheme(function(theme)
        main.BackgroundColor3 = theme.Background
        topbar.BackgroundColor3 = Color3.fromRGB(5, 5, 5)
        topbarCover.BackgroundColor3 = Color3.fromRGB(5, 5, 5)
        logo.TextColor3 = theme.Accent
        title.TextColor3 = theme.Text
        topHint.TextColor3 = theme.Muted
        sidebar.BackgroundColor3 = Color3.fromRGB(5, 5, 5)
        sidebarLine.BackgroundColor3 = theme.Border
        sidebarFooter.TextColor3 = theme.Muted
        pageTitle.TextColor3 = theme.Text
        pageSubtitle.TextColor3 = theme.Muted
        footer.BackgroundColor3 = theme.Panel
        footerText.TextColor3 = theme.Muted
        local stroke = main:FindFirstChildOfClass("UIStroke")
        if stroke then
            stroke.Color = theme.Border
        end
    end)

    window:SetSelectionMode(window.SelectionMode)
    if settings.Watermark ~= false then
        window:CreateWatermark(settings.WatermarkText or "UNNAMED HOOK  •  UH")
    end
    return window
end

function Library:SetWatermark(text)
    local window = self.Windows[#self.Windows]
    if window then
        return window:CreateWatermark(text)
    end
    return nil
end

function Library:Unload()
    self.Unloaded = true
    for _, window in ipairs(self.Windows) do
        for _, connection in ipairs(window.Connections) do
            pcall(function()
                connection:Disconnect()
            end)
        end
        if window.Gui then
            window:SetOpen(false)
            window.Gui:Destroy()
        end
    end
    self.Windows = {}
    self.Options = {}
    self.ThemeCallbacks = {}
end

Library.Themes = Themes
Library.LucideIcons = LucideIconNames
return Library
