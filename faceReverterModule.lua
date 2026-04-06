--!strict
--[[
___________                  __________                           __                
\_   _____/____    ____  ____\______   \ _______  __ ____________/  |_  ___________ 
|    __) \__  \ _/ ___\/ __ \|       _// __ \  \/ // __ \_  __ \   __\/ __ \_  __ \
|     \   / __ \\  \__\  ___/|    |   \  ___/\   /\  ___/|  | \/|  | \  ___/|  | \/
\___  /  (____  /\___  >___  >____|_  /\___  >\_/  \___  >__|   |__|  \___  >__|   
	By @rcsnnn - r_csn
	- Just a tool that converts dynamic heads to their classic counterparts
]]--

local FaceReverterModule = {}

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

-- config

-- remote event name in ReplicatedStorage. must match on both sides.
local remoteName = "faceReverterEvent"

-- url for the face name to decal id json. set to "" to use fallbackFaceIds only.
local facesJsonUrl = "https://raw.githubusercontent.com/rcsnnn/FaceReverter/refs/heads/main/faces.json"

-- seconds to wait after CharacterAppearanceLoaded before applying faces.
local respawnDelay = 1

-- convert npc models that have FaceControls.
local convertDynamicNpcs = true

-- convert every rig with a Humanoid and Head, not just dynamic ones.
local convertAllRigs = true

-- re-apply faces when a player's rig changes mid-session.
local convertRigChanges = true

-- match a player's dynamic face to its classic 2d equivalent.
local matchDynamicFace = true

-- scan all of Workspace for npc rigs on startup.
local scanWorkspace = true

-- poll the player's equipped face and re-apply when it changes.
local pollFaceChanges = true

-- how often (seconds) to poll for face changes.
local pollInterval = 5

-- when true, only convert dynamic heads made by roblox. ugc heads are left alone. players only.
local robloxHeadsOnly = false

-- when true, keep the dynamic head instead of falling back to defaultFaceId if no match is found.
-- retries on every respawn.
local dynamicFaceRollback = false

-- extra roots to always scan for npc rigs.
local acceptModelPaths: {Instance} = {
}

-- models that are descendants of these are skipped entirely.
local excludeModelPaths: {Instance} = {
}

-- fallback face while async resolution is in progress, and for unmatched faces.
-- unused when dynamicFaceRollback is true and no match is found.
local defaultFaceId = "rbxassetid://144080495"

-- vertical offset applied to the face part weld to align it with the classic head.
local faceYOffset = -0.0319

-- used when facesJsonUrl is empty or the fetch fails.
local fallbackFaceIds: {[string]: string} = {
	["O.o"]               = "rbxassetid://7046277",
	["Classic Goof"]      = "rbxassetid://7046286",
	["Glee"]              = "rbxassetid://7074712",
	["Chill"]             = "rbxassetid://7074749",
	["Check It"]          = "rbxassetid://7074780",
	["Existential Angst"] = "rbxassetid://417334857",
	["Classic Vampire"]   = "rbxassetid://7074827",
	["Winky"]             = "rbxassetid://7074856",
	["Drool"]             = "rbxassetid://7074882",
	["Uh Oh"]             = "rbxassetid://7074932",
	["Fearless"]          = "rbxassetid://7074972",
	["Whatchoo Talkin Bout"] = "rbxassetid://7075077",
	["Fang"]              = "rbxassetid://7075130",
	["Toothy Grin"]       = "rbxassetid://7075412",
	[":-/"]               = "rbxassetid://7075459",
	["Lazy Eye"]          = "rbxassetid://7075492",
	["Hmmm..."]           = "rbxassetid://7076053",
	["Chubs"]             = "rbxassetid://7076096",
	["Shhh..."]           = "rbxassetid://629925953",
	["RAWR!"]             = "rbxassetid://7076211",
	["Sad Zombie"]        = "rbxassetid://7131308",
	["Alright"]           = "rbxassetid://7131482",
	["I Am Not Amused"]   = "rbxassetid://7131857",
	["Mysterious"]        = "rbxassetid://7132019",
	["Slickfang"]         = "rbxassetid://7317591",
	["Chippy McTooth"]    = "rbxassetid://7317697",
	[":-o"]               = "rbxassetid://7317691",
	["Good Intentioned"]  = "rbxassetid://7317606",
	["Blinky"]            = "rbxassetid://7506008",
	["Emotionally Distressed Zombie"] = "rbxassetid://629906620",
	["It's Go Time!"]     = "rbxassetid://7506025",
	["I Lack Personal Confidence"] = "rbxassetid://7505989",
	["Silly Fun"]         = "rbxassetid://7699086",
	["Sad"]               = "rbxassetid://7699115",
	["Poor Man"]          = "rbxassetid://478719512",
	["Frightful"]         = "rbxassetid://7699096",
	["Stitchface"]        = "rbxassetid://8329438",
	["ZOMG"]              = "rbxassetid://8329421",
	["Sinister"]          = "rbxassetid://8329434",
	["Daring"]            = "rbxassetid://8329410",
	["Stare"]             = "rbxassetid://8560915",
	["Anguished"]         = "rbxassetid://8560912",
	["Toothy Drool"]      = "rbxassetid://8560901",
	["Frightening Unibrow"] = "rbxassetid://417335778",
	["Aghast"]            = "rbxassetid://629923753",
	["Meanie"]            = "rbxassetid://508490451",
	["Mischievous"]       = "rbxassetid://9250081",
	["Concerned"]         = "rbxassetid://9250431",
	["Commando"]          = "rbxassetid://10526794",
	["Sly Cat"]           = "rbxassetid://10678193",
	["Serious Cat"]       = "rbxassetid://10678215",
	["Serious Dog"]       = "rbxassetid://10678225",
	["Bad Dog"]           = "rbxassetid://10678229",
	["RAWR Bear"]         = "rbxassetid://10678240",
	["Skeletar"]          = "rbxassetid://10747452",
	["Retro Smiley"]      = "rbxassetid://10747911",
	["Hypnoface"]         = "rbxassetid://10747392",
	["Sir Rich McMoneyston, III"] = "rbxassetid://629914851",
	["Shy Lady"]          = "rbxassetid://10749431",
	["eXtreme"]           = "rbxassetid://10747652",
	["$.$"]               = "rbxassetid://10747371",
	["The Big Dog"]       = "rbxassetid://10749405",
	["Pumpkin Face"]      = "rbxassetid://10747387",
	["Silence"]           = "rbxassetid://10749546",
	["Meow?"]             = "rbxassetid://10749222",
	["Yuck!"]             = "rbxassetid://629907657",
	["Quijibo"]           = "rbxassetid://508485561",
	["Redonkulous"]       = "rbxassetid://10747492",
	["Slobbery Villain"]  = "rbxassetid://508484319",
	["Mr. Chuckles"]      = "rbxassetid://10747810",
	["I wuv u"]           = "rbxassetid://10749449",
	["Crazy Abstract Artist"] = "rbxassetid://620866423",
	["Bird of Prey"]      = "rbxassetid://629949468",
	["Finn McCool"]       = "rbxassetid://10749456",
	["Dizzy Face"]        = "rbxassetid://10749463",
	["Owl"]               = "rbxassetid://620869273",
	["Mr. Oinkers"]       = "rbxassetid://629919997",
	["Adorable Puppy"]    = "rbxassetid://5492600700",
	["Cute Kitty"]        = "rbxassetid://10747401",
	["Ninja"]             = "rbxassetid://10749503",
	["Love"]              = "rbxassetid://10749488",
	["Quackface McGraw"]  = "rbxassetid://478719853",
	["Muttdawg"]          = "rbxassetid://478731659",
	["Distaught Alien Invader"] = "rbxassetid://11913422",
	["Alien Ambassador"]  = "rbxassetid://11913449",
	["Nibbles, Devourer of Worlds"] = "rbxassetid://629912441",
	["Lion"]              = "rbxassetid://11956455",
	["Oh Deer"]           = "rbxassetid://12145229",
	["Freckles"]          = "rbxassetid://12145059",
	["Demented Mouse"]    = "rbxassetid://12188129",
	["Koala"]             = "rbxassetid://629901607",
	["Ghostface"]         = "rbxassetid://12466911",
	["And then we'll take over the world!"] = "rbxassetid://12732236",
	["Blerg!"]            = "rbxassetid://12777582",
	["Dragonface"]        = "rbxassetid://629903805",
	["¬_¬"]               = "rbxassetid://13038247",
	["Oh Noes Another Dog"] = "rbxassetid://13038224",
	["Old Man Jenkins"]   = "rbxassetid://629927480",
	["Walk the Plank You Scurvy Dogs!"] = "rbxassetid://13478066",
	["Pony Face"]         = "rbxassetid://13655958",
	["I Hate Noobs"]      = "rbxassetid://14030506",
	["Visual Studio Seized Up For 45 Seconds"] = "rbxassetid://14083319",
	["Two Guys on a Boat"] = "rbxassetid://14123364",
	["WHAAAaaa!"]         = "rbxassetid://14123340",
	["No Z"]              = "rbxassetid://14405631",
	["Sniffles"]          = "rbxassetid://14516479",
	["Scarecrow Face"]    = "rbxassetid://14721752",
	["D:"]                = "rbxassetid://14812835",
	["=)"]                = "rbxassetid://14817231",
	[":P"]                = "rbxassetid://14861556",
	[":-O"]               = "rbxassetid://15013091",
	["XD"]                = "rbxassetid://15054328",
	[":'("]               = "rbxassetid://15133335",
	[">:3"]               = "rbxassetid://15177471",
	[">_<"]               = "rbxassetid://15324447",
	["^_^"]               = "rbxassetid://15365479",
	["x_x"]               = "rbxassetid://15395252",
	[":3"]                = "rbxassetid://15431991",
	[":-["]               = "rbxassetid://15471076",
	["Hut Hut Hike!"]     = "rbxassetid://15470573",
	["ILOVEFOOTBOLL!"]    = "rbxassetid://629948559",
	[":/"]                = "rbxassetid://15470952",
	["-_-"]               = "rbxassetid://15637705",
	[":-?"]               = "rbxassetid://15858100",
	["Cutiemouse"]        = "rbxassetid://15885042",
	["Tango"]             = "rbxassetid://16101613",
	[":D"]                = "rbxassetid://16132434",
	["Semi Colon Open Paren"] = "rbxassetid://16179600",
	["NetHack Addict"]    = "rbxassetid://16357318",
	[">_>"]               = "rbxassetid://16387598",
	["zOMG Hat Selling!"] = "rbxassetid://16413448",
	["Red Tango"]         = "rbxassetid://629930519",
	["Jungle Commando"]   = "rbxassetid://16678109",
	["Red Fang"]          = "rbxassetid://16722374",
	["Sapphire Drool"]    = "rbxassetid://16723441",
	["Ochre Ogre"]        = "rbxassetid://16723395",
	["D="]                = "rbxassetid://17137977",
	["Eyes of Azurewrath"] = "rbxassetid://629947734",
	[":]"]                = "rbxassetid://18151722",
	["Bubble Trouble"]    = "rbxassetid://19264782",
	["Friendly Pirate"]   = "rbxassetid://19366214",
	["Pieface Jellyfreckles"] = "rbxassetid://19382647",
	["Jack Frost Face"]   = "rbxassetid://19396122",
	["Snowman Face"]      = "rbxassetid://19396549",
	["Rudolph"]           = "rbxassetid://19397593",
	["Grr!"]              = "rbxassetid://19398553",
	["Toothless"]         = "rbxassetid://19627641",
	["Starry Eyed"]       = "rbxassetid://19958885",
	["Yawn"]              = "rbxassetid://20010294",
	["Puck"]              = "rbxassetid://20298933",
	["Disbelief"]         = "rbxassetid://20337265",
	["Err..."]            = "rbxassetid://20418518",
	["Bandage"]           = "rbxassetid://20418584",
	["Secret Service"]    = "rbxassetid://20612916",
	["Xtreme Happy"]      = "rbxassetid://20643951",
	["Shiny Teeth"]       = "rbxassetid://20722053",
	["Sweat It Out"]      = "rbxassetid://20909031",
	["Optimist"]          = "rbxassetid://21024598",
	["Embarrassed"]       = "rbxassetid://21272940",
	["Sigmund"]           = "rbxassetid://21311520",
	["Downcast"]          = "rbxassetid://21351916",
	["Clown School Dropout"] = "rbxassetid://21392803",
	["Toughguy"]          = "rbxassetid://21439548",
	["Heeeeeey..."]       = "rbxassetid://21635489",
	["You ated my caik!"] = "rbxassetid://21638407",
	["Woebegone"]         = "rbxassetid://21754586",
	["Glory on the Gridiron"] = "rbxassetid://21796275",
	["Timmy McPwnage"]    = "rbxassetid://22023001",
	["The First Time I Ever Played ROBLOX..."] = "rbxassetid://22070531",
	["Square Eyes"]       = "rbxassetid://22118943",
	["Masque"]            = "rbxassetid://629920835",
	["The Friendly Eviscerator"] = "rbxassetid://22500052",
	["Winter"]            = "rbxassetid://22587827",
	["Fast Car"]          = "rbxassetid://22587893",
	["Speaker of Lightning"] = "rbxassetid://149486853",
	["Lightning Speaker"] = "rbxassetid://22588800",
	["Wink-Blink"]        = "rbxassetid://22828283",
	["Whistle"]           = "rbxassetid://22877631",
	["Troublemaker"]      = "rbxassetid://22920500",
	["Eyes of Everfrost"] = "rbxassetid://22972635",
	["Nervous"]           = "rbxassetid://23219775",
	["Surprise!"]         = "rbxassetid://23261768",
	["Mick McCann"]       = "rbxassetid://23999943",
	["Paintball Enthusiast"] = "rbxassetid://23310996",
	["Look At My Nose"]   = "rbxassetid://23311760",
	["Clown Face"]        = "rbxassetid://23644832",
	["Awkward...."]       = "rbxassetid://23931977",
	["Drooling Noob"]     = "rbxassetid://24067663",
	["Zip It!"]           = "rbxassetid://24125997",
	["Camoface"]          = "rbxassetid://24441824",
	["Butterfly"]         = "rbxassetid://24727888",
	["Where are the eggs?"] = "rbxassetid://24975243",
	["Squiggle Mouth"]    = "rbxassetid://25165947",
	["Emperor"]           = "rbxassetid://629917700",
	["Friendly Grin"]     = "rbxassetid://25321744",
	["Freckled Cheeks"]   = "rbxassetid://25555431",
	["Sophisticated Spectacles"] = "rbxassetid://25930455",
	["Bling"]             = "rbxassetid://25975157",
	["Yum!"]              = "rbxassetid://26018945",
	["Scarecrow"]         = "rbxassetid://26260786",
	["Tattletale"]        = "rbxassetid://26343132",
	["Know-It-All Grin"]  = "rbxassetid://26424652",
	["Sick Day"]          = "rbxassetid://26619042",
	["It's so beautiful!"] = "rbxassetid://26674356",
	["Old Timer"]         = "rbxassetid://27003564",
	["Raccoon"]           = "rbxassetid://27052496",
	["Goofball"]          = "rbxassetid://27134272",
	["Smith McCool"]      = "rbxassetid://27412750",
	["Seeing Stars"]      = "rbxassetid://27599799",
	["Friendly Puppy"]    = "rbxassetid://27725380",
	["Hilarious"]         = "rbxassetid://27861351",
	["Not Again!"]        = "rbxassetid://28118994",
	["Pwnda Face"]        = "rbxassetid://28281785",
	["Adoration"]         = "rbxassetid://28878210",
	["Joyous Surprise"]   = "rbxassetid://28999175",
	["Trance"]            = "rbxassetid://29109680",
	["Daydreaming"]       = "rbxassetid://29296097",
	["Lady Lashes"]       = "rbxassetid://29347988",
	["Vampire"]           = "rbxassetid://29532362",
	["Thinking"]          = "rbxassetid://29716203",
	["Robot Smile"]       = "rbxassetid://30265036",
	["Imagine"]           = "rbxassetid://30394315",
	["Friendly Cyclops"]  = "rbxassetid://30394437",
	["Braces"]            = "rbxassetid://30394483",
	["Facepalm"]          = "rbxassetid://30394593",
	["Awesome Face"]      = "rbxassetid://30394849",
	["=("]                = "rbxassetid://30395096",
	["Skeptic"]           = "rbxassetid://31117192",
	["Alien"]             = "rbxassetid://31317607",
	["Mr. Bubbles"]       = "rbxassetid://31615924",
	["So Funny"]          = "rbxassetid://32058103",
	["I <3 New Site Theme"] = "rbxassetid://32723156",
	["Starface"]          = "rbxassetid://32873288",
	["Cheerful Grin"]     = "rbxassetid://33321688",
	["Disbelief Face"]    = "rbxassetid://34186612",
	["Shutter Shades: The Face"] = "rbxassetid://34673639",
	["The Dog Whisperer"] = "rbxassetid://34764373",
	["Magical Dragon"]    = "rbxassetid://34871107",
	["Exclamation Face"]  = "rbxassetid://35168482",
	["Gigglypuff"]        = "rbxassetid://35397044",
	["Epic Face"]         = "rbxassetid://42070872",
	["Angelic"]           = "rbxassetid://45083898",
	["Crimson Laser Vision"] = "rbxassetid://45514494",
	["Crazy Happy"]       = "rbxassetid://45515545",
	["Monster Face"]      = "rbxassetid://49045252",
	["Eyes of Crimsonwrath"] = "rbxassetid://49493144",
	["Sunny Fun"]         = "rbxassetid://51241170",
	["Grandma's Lipstick"] = "rbxassetid://51241479",
	["Country Morning"]   = "rbxassetid://51241521",
	["Obvious Wink"]      = "rbxassetid://51241536",
	["NOWAI!"]            = "rbxassetid://51241861",
	["Golden Shiny Teeth"] = "rbxassetid://66319713",
	["Emerald Ambassador"] = "rbxassetid://66329462",
	["Bored"]             = "rbxassetid://66329524",
	["Derp Face"]         = "rbxassetid://508486545",
	["Green-eyed Awesome Face"] = "rbxassetid://66329597",
	["Emerald Laser Vision"] = "rbxassetid://66329642",
	["Not So Friendly Eviscerator"] = "rbxassetid://66329683",
	["Golden Lightning Speaker"] = "rbxassetid://66329737",
	["O_o"]               = "rbxassetid://66329844",
	["Red RAWR"]          = "rbxassetid://66329788",
	["Singing"]           = "rbxassetid://66329905",
	["Buddy Face"]        = "rbxassetid://83025169",
	["Disapproving Unibrow"] = "rbxassetid://66329994",
	["Dr. Smyth Face"]    = "rbxassetid://83016614",
	["Manlier Face"]      = "rbxassetid://83017053",
	["Kate Face"]         = "rbxassetid://83021209",
	["Honey Face"]        = "rbxassetid://83022608",
	["Max Face"]          = "rbxassetid://83015508",
	["Missy Face"]        = "rbxassetid://83321898",
	["Pal Face"]          = "rbxassetid://83025982",
	["Sarge Face"]        = "rbxassetid://82837707",
	["Sarge Extreme Face"] = "rbxassetid://81615913",
	["Sarge Sad Face"]    = "rbxassetid://82824027",
	["Man Face"]          = "rbxassetid://83017053",
	["Woman Face"]        = "rbxassetid://83022608",
	["iFace"]             = "rbxassetid://97717261",
	["Spring Bunny"]      = "rbxassetid://108209955",
	["Egg on your Face"]  = "rbxassetid://108213708",
	["Daring Beard"]      = "rbxassetid://110287880",
	["Evil Skeptic Face"] = "rbxassetid://110287983",
	["Evil Skeptic"]      = "rbxassetid://110287983",
	["I Didn't Eat That Cookie"] = "rbxassetid://115978221",
	["Rosey Smile"]       = "rbxassetid://658751484",
	["Sadfaic"]           = "rbxassetid://629925029",
	["Punk Face"]         = "rbxassetid://119768621",
	["Blue Starface"]     = "rbxassetid://119772974",
	["Green Starface"]    = "rbxassetid://119773049",
	["Purple Starface"]   = "rbxassetid://119773113",
	["Bombo Face"]        = "rbxassetid://121946959",
	["Beast Mode"]        = "rbxassetid://127959433",
	["ROBLOX Madness Face"] = "rbxassetid://129900258",
	["Zombie Face"]       = "rbxassetid://133360891",
	["Fawkes Face"]       = "rbxassetid://133867453",
	["Tired Face"]        = "rbxassetid://141728515",
	["Drill Sergeant"]    = "rbxassetid://657217430",
	["Hockey Face"]       = "rbxassetid://142888113",
	["Smile"]             = "rbxassetid://144080495",
	["Shocked"]           = "rbxassetid://147144198",
	["Bluffing"]          = "rbxassetid://147144273",
	["Awkward Eyeroll"]   = "rbxassetid://150070631",
	["Huh?"]              = "rbxassetid://150070505",
	["Awkward Grin"]      = "rbxassetid://150070305",
	["Classic Alien Face"] = "rbxassetid://158017769",
	["YAAAWWN."]          = "rbxassetid://161124757",
	["Crimson Starface"]  = "rbxassetid://162185411",
	["Orange Starface"]   = "rbxassetid://162185335",
	["Yellow Starface"]   = "rbxassetid://162185210",
	["Angry Zombie"]      = "rbxassetid://168332015",
	["Not sure if..."]    = "rbxassetid://168332209",
	["Grumpy Blox"]       = "rbxassetid://478720454",
	["Red Glowing Eyes"]  = "rbxassetid://179693472",
	["Epic Vampire Face"] = "rbxassetid://181661839",
	["Sapphire Laser Vision"] = "rbxassetid://508487599",
	["Sharpnine's Face of Disappointment"] = "rbxassetid://209712916",
	["Eyes of Emeraldwrath"] = "rbxassetid://508398801",
	["Raig Face"]         = "rbxassetid://209714802",
	["Smiling Girl"]      = "rbxassetid://209713952",
	["Suspicious"]        = "rbxassetid://209715003",
	["Blizzard Beast Mode"] = "rbxassetid://209712379",
	["Joyful Smile"]      = "rbxassetid://209713384",
	["Laughing Fun"]      = "rbxassetid://226216895",
	["Egg Crazed"]        = "rbxassetid://233240646",
	["Happy Wink"]        = "rbxassetid://236455674",
	["Purple Butterfly Smile"] = "rbxassetid://240961696",
	["Sly Guy Face"]      = "rbxassetid://238984437",
	["Just Trouble"]      = "rbxassetid://243755928",
	["Blue Trance"]       = "rbxassetid://260296642",
	["Sad Clown"]         = "rbxassetid://629934434",
	["Serious Scar Face"] = "rbxassetid://255828374",
	["Tiger Chase Fear Face"] = "rbxassetid://258192246",
	["Green Trance"]      = "rbxassetid://260296789",
	["Orange Trance"]     = "rbxassetid://260296899",
	["Purple Trance"]     = "rbxassetid://629935400",
	["Bad News Face"]     = "rbxassetid://629929484",
	["Whuut?"]            = "rbxassetid://273874617",
	["Furious George"]    = "rbxassetid://277939506",
	["Mildly Irritated Face"] = "rbxassetid://280987977",
	["Super Happy Joy"]   = "rbxassetid://280987381",
	["Happy Girl Face"]   = "rbxassetid://287062870",
	["RBX-90 Face"]       = "rbxassetid://293229488",
	["Amelia Face"]       = "rbxassetid://292668540",
	["Ezebel Face"]       = "rbxassetid://286947469",
	["Krezak"]            = "rbxassetid://286951068",
	["Furious Finn Face"] = "rbxassetid://295491745",
	["Too Much Candy"]    = "rbxassetid://295421997",
	["Lin's Face"]        = "rbxassetid://292668540",
	["Serena's Face"]     = "rbxassetid://287062870",
	["Claire's Face"]     = "rbxassetid://287062870",
	["Casey's Face"]      = "rbxassetid://286951068",
	["John's Face"]       = "rbxassetid://321741599",
	["Oakley's Face"]     = "rbxassetid://286951068",
	["Daring Blonde Beard Face"] = "rbxassetid://324190505",
	["Green Super Happy Joy"] = "rbxassetid://324189860",
	["Desert Commando"]   = "rbxassetid://323188972",
	["Green Whatchoo Talkin' Bout"] = "rbxassetid://629936597",
	["Blue Eyeroll"]      = "rbxassetid://324191500",
	["Pink Shades McCool"] = "rbxassetid://324191930",
	["Purple Alien"]      = "rbxassetid://324192486",
	["Blue Bubble Trouble"] = "rbxassetid://330393309",
	["Miss Scarlet"]      = "rbxassetid://334655813",
	["Sneaky Green-Eyed Snake"] = "rbxassetid://334655587",
	["Teal Rock Star Smile"] = "rbxassetid://334655293",
	["Don't Wake Me Up"]  = "rbxassetid://343187883",
	["True Love Smile"]   = "rbxassetid://362047893",
	["Cheerful Hello"]    = "rbxassetid://362050947",
	["Eyes of Everflame"] = "rbxassetid://362046854",
	["Violet Fang"]       = "rbxassetid://362047042",
	["Purple Bubble Trouble"] = "rbxassetid://362047189",
	["Red Rock Star Smile"] = "rbxassetid://508489686",
	["Really Embarrassed"] = "rbxassetid://376785624",
	["Purple Super Happy Joy"] = "rbxassetid://376786318",
	["Chill McCool"]      = "rbxassetid://376788359",
	["Green Bubble Trouble"] = "rbxassetid://380753459",
	["Monarch Butterfly Smile"] = "rbxassetid://383607989",
	["Tix Vision"]        = "rbxassetid://620870415",
	["Blue-eyed Awesome Face"] = "rbxassetid://386188071",
	["Silver Punk Face"]  = "rbxassetid://387256104",
	["Ogre Face"]         = "rbxassetid://629922352",
	["Super Crazy Face"]  = "rbxassetid://508488410",
	["Big Sad Eyes"]      = "rbxassetid://629933140",
	["Nouveau George"]    = "rbxassetid://398670843",
	["Monster Smile"]     = "rbxassetid://398671601",
	["Green Glowing Eyes"] = "rbxassetid://398676207",
	["4/15 - New Cool"]   = "rbxassetid://399017769",
	["4/15 - New Smile"]  = "rbxassetid://399018593",
	["4/15 - New Smirk"]  = "rbxassetid://399019194",
	["Bacon Face"]        = "rbxassetid://645438093",
	["Friendly Trusting Smile"] = "rbxassetid://402301113",
	["Red Serious Scar Face"] = "rbxassetid://405704912",
	["Gritty Bombo"]      = "rbxassetid://405704563",
	["Happy :D"]          = "rbxassetid://406035320",
	["¬_¬ 2.0"]           = "rbxassetid://405705854",
	["XD 2.0"]            = "rbxassetid://405706156",
	["ROAR!!!"]           = "rbxassetid://405704879",
	["Smug"]              = "rbxassetid://405706038",
	["Green Drool Angry Zombie"] = "rbxassetid://629946036",
	["Sharpnine's Face of Joy"] = "rbxassetid://405706600",
	["Yellow Glowing Eyes"] = "rbxassetid://416830979",
	["Stink Eye"]         = "rbxassetid://416829404",
	["Anime Surprise"]    = "rbxassetid://416829065",
	["Unbelievable"]      = "rbxassetid://419749791",
	["6/17 - Fierce Ninja Face"] = "rbxassetid://435625893",
	["Pink Galaxy Gaze"]  = "rbxassetid://440737960",
	["Purple Galaxy Gaze"] = "rbxassetid://440738083",
	["Blue Galaxy Gaze"]  = "rbxassetid://440737549",
	["Green Galaxy Gaze"] = "rbxassetid://440737812",
	["Red White and Starface"] = "rbxassetid://445110839",
	["Super Super Happy Face"] = "rbxassetid://494290547",
	["Serious Red Eye Scar"] = "rbxassetid://494290010",
	["Crazybot 10000"]    = "rbxassetid://554651972",
	["Madbot 10000"]      = "rbxassetid://554654683",
	["Cuckookrazybot 10000"] = "rbxassetid://554655304",
	["Manicbot 10000"]    = "rbxassetid://554654979",
	["Blue Wistful Wink"] = "rbxassetid://583712942",
	["Pink Wistful Wink"] = "rbxassetid://583713318",
	["Purple Wistful Wink"] = "rbxassetid://583713594",
	["Green Wistful Wink"] = "rbxassetid://583713423",
	["Jacob: The Storm Breaker Face"] = "rbxassetid://599921920",
	["The Winning Smile"]  = "rbxassetid://616395480",
	["Friendly Smile"]    = "rbxassetid://616394568",
	["DDotty Smile"]      = "rbxassetid://667683410",
	["BiteyMcFace"]       = "rbxassetid://904124085",
	["Dex's Face"]        = "rbxassetid://286951068",
	["Zoey Face"]         = "rbxassetid://287062870",
	["Sneaky Steve"]      = "rbxassetid://823018334",
	["Green Amazeface"]   = "rbxassetid://835059826",
	["Blue Amazeface"]    = "rbxassetid://835057164",
	["Lavender Amazeface"] = "rbxassetid://835060246",
	["Rose Amazeface"]    = "rbxassetid://835060009",
	["Pink Moonstruck"]   = "rbxassetid://878945106",
	["Blue Moonstruck"]   = "rbxassetid://878947374",
	["Purple Moonstruck"] = "rbxassetid://878944494",
	["Winning Smile"]     = "rbxassetid://1315936169",
	["Death's Grin"]      = "rbxassetid://1315935475",
	["Sapphire Gaze"]     = "rbxassetid://1315942144",
	["Squinty Assassin Face"] = "rbxassetid://1315942662",
	["Crimson Evil Eye"]  = "rbxassetid://1016178220",
	["Sapphire Evil Eye"] = "rbxassetid://1016178981",
	["Emerald Evil Eye"]  = "rbxassetid://1016179764",
	["Golden Evil Eye"]   = "rbxassetid://1016180707",
	["Up To Something"]   = "rbxassetid://1016181246",
	["Red Goof"]          = "rbxassetid://1191121968",
	["Golden Bling Braces"] = "rbxassetid://1191124133",
	["Blue Goof"]         = "rbxassetid://1191123763",
	["Green Goof"]        = "rbxassetid://1191123237",
	["Catching Snowflakes"] = "rbxassetid://1213444061",
	["Tohru: The Phantom Claw's Face"] = "rbxassetid://1384268303",
	["Blue Rock Star Smile"] = "rbxassetid://1428314296",
	["Overjoyed Smile"]   = "rbxassetid://1428312511",
	["Teal Mermaid Queen"] = "rbxassetid://1428397734",
	["Pink Mermaid Princess"] = "rbxassetid://1428315155",
	["Purple Mermaid Princess"] = "rbxassetid://1428396343",
	["Rogueish Good Looks"] = "rbxassetid://1868539477",
	["Rainbow Barf Face"] = "rbxassetid://1868469550",
	["Otakufaic"]         = "rbxassetid://2176326858",
	["Blue Ultimate Dragon Face"] = "rbxassetid://1772533846",
	["Red Ultimate Dragon Face"] = "rbxassetid://1772543614",
	["Green Ultimate Dragon Face"] = "rbxassetid://1772542456",
	["Upside Down Face"]  = "rbxassetid://1772583132",
	["Hold It In"]        = "rbxassetid://2222767231",
	["Green Starry Sight"] = "rbxassetid://2222769550",
	["Blue Starry Sight"] = "rbxassetid://2222768690",
	["Violet Starry Sight"] = "rbxassetid://2222770385",
	["Radioactive Beast Mode"] = "rbxassetid://2225757922",
	["Pop Queen Smilestar Spectacusmile"] = "rbxassetid://2565825723",
	["Fashion Face"]      = "rbxassetid://2565818601",
	["Playful Vampire"]   = "rbxassetid://2409281591",
	["City Life Man"]     = "rbxassetid://2490055992",
	["City Life Woman"]   = "rbxassetid://2492475038",
	["Knights of Redcliff: Paladin"] = "rbxassetid://2492950480",
	["The High Seas: Beatrix The Pirate Queen"] = "rbxassetid://2493660907",
	["Squad Ghouls: Drop Dead Tedd - Zombie Face"] = "rbxassetid://2499282434",
	["Rogue Era Magus"]   = "rbxassetid://2499475232",
	["Sunstar"]           = "rbxassetid://2502420356",
	["Wanted Desperado"]  = "rbxassetid://2502512164",
	["Barb the Barbarian"] = "rbxassetid://2502295804",
	["Knight of Splintered Skies Ascendant"] = "rbxassetid://2506453417",
	["Police Officer Nash"] = "rbxassetid://2506729946",
	["Dark Age Apprentice"] = "rbxassetid://2506788845",
	["Dr. Lauren, Artifact Excavator"] = "rbxassetid://2506968954",
	["Knight of Chivalry"] = "rbxassetid://2507424923",
	["Elf Guardian of the Northern Border"] = "rbxassetid://2507497762",
	["Squad Ghouls: Zoe Saberhagen"] = "rbxassetid://2514352026",
	["Rock Star Singer"]  = "rbxassetid://2342052677",
	["Wyldfire Fairy"]    = "rbxassetid://2514414752",
	["Fearless Ocean Diver"] = "rbxassetid://2515271103",
	["Baroness Callidora"] = "rbxassetid://2514388837",
	["DIY Cardboard Knight"] = "rbxassetid://2514392290",
	["Arachnid Queen"]    = "rbxassetid://2565828727",
	["C.Y.N.D.I"]         = "rbxassetid://2514403812",
	["Knights of Redcliff: General"] = "rbxassetid://2313826098",
	["Samantha"]          = "rbxassetid://2514418247",
	["Knight of Courage"] = "rbxassetid://2530798909",
	["The Harbinger"]     = "rbxassetid://2514587317",
	["Beekeeper"]         = "rbxassetid://2551694054",
	["Alexandra Ninniflip"] = "rbxassetid://2551758057",
	["8-Bit Heart Face"]  = "rbxassetid://2568569786",
	["So Super Excited - Pink"] = "rbxassetid://2568608091",
	["So Super Excited - Purple"] = "rbxassetid://2568605832",
	["So Super Excited - Blue"] = "rbxassetid://2568609094",
	["Snow Queen Smile"]  = "rbxassetid://2568579815",
	["Satyr Face"]        = "rbxassetid://2571723000",
	["Ballerina Face"]    = "rbxassetid://2571725090",
	["Billionaire Heiress' Face"] = "rbxassetid://2571727019",
	["Gamin the Scaled Sorcerer"] = "rbxassetid://2573833907",
	["Terrain Assault Specialist"] = "rbxassetid://2573923862",
	["Icicle Fairy_Face"] = "rbxassetid://2514416175",
	["InsectZoids: Dr. Mantis_Face"] = "rbxassetid://2583147905",
	["Poisonous Beast Mode"] = "rbxassetid://2606174048",
	["Specter Informant"] = "rbxassetid://2514568836",
	["Rach"]              = "rbxassetid://2514445602",
	["Minerva Bright"]    = "rbxassetid://2341561567",
	["Lynn"]              = "rbxassetid://2610489111",
	["Rock Star Guitarist"] = "rbxassetid://2514396066",
	["Absolutely Shocked"] = "rbxassetid://2620488318",
	["Crybaby"]           = "rbxassetid://2620487058",
	["Sparkle Time Sparkle Eyes"] = "rbxassetid://2620489144",
	["Astral Isle Clan: Windsor the Blue"] = "rbxassetid://2623056236",
	["High Seas: Pirate King Xerxes"] = "rbxassetid://2623052853",
	["The Phantom Phalanx: Cygnus-34"] = "rbxassetid://2514345793",
	["Genni the Snail Knight-Errant"] = "rbxassetid://2623058805",
	["Yeti Hunter Face"]  = "rbxassetid://2646087114",
	["Chester Finkleton"] = "rbxassetid://2639364063",
	["Pepper Krinklesnaps"] = "rbxassetid://2639366656",
	["Supreme Claus"]     = "rbxassetid://2625379390",
	["Knights of Redcliff: Elite Dragoon"] = "rbxassetid://2658471215",
	["Skater Gurl"]       = "rbxassetid://2739777922",
	["Skater Boi"]        = "rbxassetid://2739778788",
	["Sheriff Buffington"] = "rbxassetid://2756332108",
	["Overseer: Assassin"] = "rbxassetid://2756347310",
	["Knights of Redcliff: Warrior"] = "rbxassetid://2756343123",
	["Football Player"]   = "rbxassetid://2772513986",
	["Aztec Warrior Face"] = "rbxassetid://2803576899",
	["Royal Eye of Horus Face"] = "rbxassetid://2803654708",
	["Lady Darkshade"]    = "rbxassetid://2794747554",
	["Dr. Bunton Madmind"] = "rbxassetid://2797313154",
	["Torque the Red Orc"] = "rbxassetid://2830472766",
	["Torque the Blue Orc"] = "rbxassetid://2830474424",
	["Torque the Green Orc"] = "rbxassetid://2830473786",
	["Emerald Archfey Visage"] = "rbxassetid://2830481956",
	["Sapphire Archfey Visage"] = "rbxassetid://2830481528",
	["Ruby Archfey Visage"] = "rbxassetid://2830482465",
	["Slithering Smile"]  = "rbxassetid://2830640563",
	["Conner"]            = "rbxassetid://2827303145",
	["Pizza Face"]        = "rbxassetid://3065052750",
	["Cyanskeleface"]     = "rbxassetid://3065051594",
	["THE SOUP IS DRY"]   = "rbxassetid://3065049688",
	["Star-Mist Fairy"]   = "rbxassetid://2849462122",
	["Rosewood"]          = "rbxassetid://2849500812",
	["The Birdcaller"]    = "rbxassetid://2874300109",
	["Valkyrie of the Splintered Skies"] = "rbxassetid://2903490495",
	["Fanciful Leprechaun Face"] = "rbxassetid://2907636680",
	["Tenko the Nine-Tailed Fox"] = "rbxassetid://2900211650",
	["Witter"]            = "rbxassetid://2874324913",
	["Digital Artist"]    = "rbxassetid://2924060633",
	["Jester Equinox"]    = "rbxassetid://2953700072",
	["Oli Zigzag"]        = "rbxassetid://2957259729",
	["Kroma Blitz"]       = "rbxassetid://2959503199",
	["Aurora Spark"]      = "rbxassetid://2956959047",
	["Octavia, The Ivory Spider Girl"] = "rbxassetid://2975222716",
	["Futureglam Bounty Hunter Face"] = "rbxassetid://3008636268",
	["WWE - Seth Rollins Face"] = "rbxassetid://3016152826",
	["WWE - Xavier Woods Face"] = "rbxassetid://3016289446",
	["WWE - Becky Lynch Face"] = "rbxassetid://3016321351",
	["WWE - Roman Reigns Face"] = "rbxassetid://3016622929",
	["Ellie Face"]        = "rbxassetid://3027117721",
	["Chivalrous Knight of the Silver Kingdom Face"] = "rbxassetid://2976066765",
	["Overseer: Prophet Face"] = "rbxassetid://3030235136",
	["DJ Databaze"]       = "rbxassetid://3076877056",
	["DJ E-Mosion"]       = "rbxassetid://3076875377",
	["Battle Ready Kenji Face"] = "rbxassetid://3116344124",
	["Druid of the Stag Face"] = "rbxassetid://3115551219",
	["Erisyphia"]         = "rbxassetid://3134826009",
	["Eita the Envious Youkai Face"] = "rbxassetid://3210093672",
	["Chichiri the Wise Youkai Face"] = "rbxassetid://3210092741",
	["Noriko the Gentle Youkai Face"] = "rbxassetid://3210091014",
	["Tycoon Summoner Face"] = "rbxassetid://3210504690",
	["Lobster Warrior Grimace"] = "rbxassetid://3237756144",
	["Atlantean Warrior Face"] = "rbxassetid://3237758757",
	["Fairly Faerie"]     = "rbxassetid://3064754707",
	["Red Sparkle Time Lobster Person"] = "rbxassetid://4018465122",
	["Sharkbait"]         = "rbxassetid://3064754707",
	["Valorous Knight"]   = "rbxassetid://3254218159",
	["Prideful Smile"]    = "rbxassetid://3267472315",
	["Beaming with Pride"] = "rbxassetid://3267470325",
	["Champion Of The Tide Face"] = "rbxassetid://3234016124",
	["Dr. Fia Tyfoid"]    = "rbxassetid://3493258178",
	["Sorority Star Face"] = "rbxassetid://4019292650",
	["Wicked Webbed Berserker Face"] = "rbxassetid://3808073644",
	["Classic Male"]      = "rbxassetid://3994344171",
	["Classic Female"]    = "rbxassetid://3994345447",
	["Digital Shock Artist"] = "rbxassetid://2924060633",
	["Mr. Toilet"]        = "rbxassetid://4086501806",
	["Snow Samurai"]      = "rbxassetid://4417209075",
	["NeoClassic Female v2"] = "rbxassetid://4588499007",
	["Classic Male v2"]   = "rbxassetid://4637450017",
	["Classic Female v2"] = "rbxassetid://4586610741",
	["Neoclassic Male v2"] = "rbxassetid://4588498182",
	["Renegade Bounty Hunter Face"] = "rbxassetid://4426576622",
	["Tsundere Expression"] = "rbxassetid://4895360333",
	["Mixologist's Smile"] = "rbxassetid://4895362922",
	["Cheerful Barista Face"] = "rbxassetid://4584117070",
	["Paramedic's Face"]  = "rbxassetid://4584973204",
	["Elegant Evening Dress"] = "rbxassetid://4582519378",
	["Biohazard First Responder"] = "rbxassetid://4508029059",
	["Pirate Prince Cryon"] = "rbxassetid://2623052853",
	["Gold Mermaid Visage"] = "rbxassetid://5849008243",
	["Tears of Sorrow"]   = "rbxassetid://6028824880",
	["Performing Mime"]   = "rbxassetid://5848997920",
	["Zed Face"]          = "rbxassetid://5849006088",
	["Glided Diver"]      = "rbxassetid://2515271103",
	["Irian the Legendary Sorcerer"] = "rbxassetid://5579496275",
	["Bubbly Reviewer"]   = "rbxassetid://6873584508",
	["Cat Mascot"]        = "rbxassetid://5754100966",
	["Steampunk Inventor"] = "rbxassetid://5759199436",
	["Lumber Joe"]        = "rbxassetid://2827303145",
	["Lumber Jessie"]     = "rbxassetid://2849500812",
	["Crank and Zap Mech"] = "rbxassetid://5885708899",
	["Vans Checkerboard Brown Eyes"] = "rbxassetid://8246559242",
	["Rodeo Vampire - Lil Nas X (LNX)"] = "rbxassetid://5924592609",
	["Smil Nas X - Lil Nas X (LNX)"] = "rbxassetid://5924588534",
	["Holiday Cheer Toshi"] = "rbxassetid://5964850347",
	["Festive Beekeeper"] = "rbxassetid://5965061327",
	["Wonder Woman's Golden Armor"] = "rbxassetid://6029531141",
	["Curator"]           = "rbxassetid://6100612503",
	["Award-Winning Smile"] = "rbxassetid://6531805594",
	["Sparkling's Friendly Wink"] = "rbxassetid://6714123250",
	["Super Pink Heart Makeup"] = "rbxassetid://6714740652",
	["Princess Alexis"]   = "rbxassetid://6714756103",
	["Merciless Ninja"]   = "rbxassetid://6652963861",
	["Domino Deckard"]    = "rbxassetid://6653115585",
	["The Engineer"]      = "rbxassetid://6710820473",
	["Gucci Aviator Sunglasses with GG Lens"] = "rbxassetid://6831468736",
	["Bakonette"]         = "rbxassetid://7369467011",
	["Persephone's Girl Glam"] = "rbxassetid://6792755141",
	["Starry Eyes Sparkling"] = "rbxassetid://7370410419",
	["Monster Grumpy Face"] = "rbxassetid://7737933327",
	["Mon Cheri Face"]    = "rbxassetid://7737952495",
	["Isabella"]          = "rbxassetid://7737963900",
	["Sai-eye Tyler Joseph - Twenty One Pilots"] = "rbxassetid://7389895884",
	["Warpaint Josh Dun - Twenty One Pilots"] = "rbxassetid://7389918425",
	["Diamond Grill - Lil Nas X (LNX)"] = "rbxassetid://7657592485",
	["Butterfly Wink - Lil Nas X (LNX)"] = "rbxassetid://7657640018",
	["Devil Nas X - Lil Nas X (LNX)"] = "rbxassetid://7657648582",
	["Cat Eye - Zara Larsson"] = "rbxassetid://7893435035",
	["Glittering Eye - Zara Larsson"] = "rbxassetid://7893438453",
	["Heart Gaze - Zara Larsson"] = "rbxassetid://7893441222",
	["Big Grin - Tai Verdes"] = "rbxassetid://7987146198",
	["Sunrise Eyes - Tai Verdes"] = "rbxassetid://7987150722",
	["Vans Checkerboard Blue Eyes"] = "rbxassetid://8246562466",
	["Mermaid Mystique"]  = "rbxassetid://8664088085",
	["Rainbow Spirit Face"] = "rbxassetid://8666737055",
	["Kandi's Sprinkle Face"] = "rbxassetid://8666858645",
	["McLaren Smile"]     = "rbxassetid://9062608001",
	["McLaren Big Grin"]  = "rbxassetid://9062612645",
	["24kGoldn Face"]     = "rbxassetid://9156233764",
	["Devilish Smile - 24kGoldn"] = "rbxassetid://9156244686",
	["Golden Eyes - 24kGoldn"] = "rbxassetid://9156248239",
	["Red Lip - Tate McRae"] = "rbxassetid://9650705589",
	["Pink Cat Eye Sunglasses"] = "rbxassetid://16008780614",
	["Snowflake Eyes"]    = "rbxassetid://84263778542721",
	["Blanc Knowledge Visor"] = "rbxassetid://75539787580658",
	["Dylan Default"]     = "rbxassetid://144080495",
	["Stevie Standard"]   = "rbxassetid://144080495",
	["Face"] = "rbxassetid://144080495",
}


-- state


local faceIds: {[string]: string} = {}
local playerFaceCache: {[number]: string} = {}        -- userid to face decal id
local playerDynamicFaceCache: {[number]: string} = {} -- userid to dynamic-equiv decal id

-- nil = unknown, true = roblox-made, false = ugc
local playerRobloxCreator: {[number]: boolean?} = {}

local rigCurrentFaceId: {[Model]: string}  = {} -- intended texture per rig
local rigLockConnected: {[Model]: boolean} = {}  -- prevents duplicate lock connections


-- face id loading

local faceIdsLoaded = false

local function ensureFaceIdsLoaded()
	if faceIdsLoaded then return end
	faceIdsLoaded = true

	if facesJsonUrl == "" then
		faceIds = fallbackFaceIds
		print("faceReverter - no json url set, using fallback table.")
		return
	end

	local ok, result = pcall(HttpService.GetAsync, HttpService, facesJsonUrl, true)
	if not ok then
		warn("faceReverter - json fetch failed:", result, "- using fallback table.")
		faceIds = fallbackFaceIds
		return
	end

	local decodeOk, parsed = pcall(HttpService.JSONDecode, HttpService, result)
	if not decodeOk or type(parsed) ~= "table" then
		warn("faceReverter - json parse failed, using fallback table.")
		faceIds = fallbackFaceIds
		return
	end

	local count = 0
	for name, id in pairs(parsed :: {[string]: string}) do
		faceIds[name] = id
		count += 1
	end
	print(string.format("faceReverter - loaded %d face ids from json.", count))
end


-- utilities


local function isExcluded(model: Model): boolean
	for _, excluded in ipairs(excludeModelPaths) do
		if model == excluded or model:IsDescendantOf(excluded) then return true end
	end
	return false
end

local function shiftWeldC1Y(weld: Weld, yDelta: number)
	local x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 = weld.C1:components()
	weld.C1 = CFrame.new(x, y + yDelta, z, r00, r01, r02, r10, r11, r12, r20, r21, r22)
end

-- moves accessory welds to stay aligned after the y-offset is applied.
local function adjustAccessoriesForOffset(char: Model, head: BasePart, yOffset: number)
	for _, child in ipairs(char:GetChildren()) do
		if child:IsA("Accessory") then
			local handle = child:FindFirstChild("Handle") :: BasePart?
			if handle then
				for _, item in ipairs(handle:GetChildren()) do
					if item:IsA("Weld") then
						local weld = item :: Weld
						if weld.Part1 == head then
							shiftWeldC1Y(weld, yOffset)
						elseif weld.Part0 == head then
							local x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 = weld.C0:components()
							weld.C0 = CFrame.new(x, y + yOffset, z, r00, r01, r02, r10, r11, r12, r20, r21, r22)
						end
					end
				end
			end
		end
	end
end

-- locks a Part head's SpecialMesh to the classic shape. no-ops on MeshPart heads.
local function lockHeadMesh(head: BasePart)
	if head:IsA("MeshPart") then return end
	local mesh = head:FindFirstChildOfClass("SpecialMesh") :: SpecialMesh?
	if not mesh then
		mesh        = Instance.new("SpecialMesh")
		mesh.Name   = "Mesh"
		mesh.Parent = head
	end
	local m     = mesh :: SpecialMesh
	local scale = Vector3.new(1.25, 1.25, 1.25)
	local function enforce() -- messy
		if not m.Parent then return end
		if m.MeshType ~= Enum.MeshType.Head then m.MeshType = Enum.MeshType.Head end
		if m.MeshId   ~= ""                 then m.MeshId   = ""                 end
		if m.Scale    ~= scale               then m.Scale    = scale               end
	end
	enforce()
	task.delay(0.05, enforce)
	task.delay(0.5,  enforce)
	m:GetPropertyChangedSignal("MeshType"):Connect(enforce)
	m:GetPropertyChangedSignal("MeshId"):Connect(enforce)
	m:GetPropertyChangedSignal("Scale"):Connect(enforce)
end

-- removes any existing "face" decals from head and blocks future ones.
local function suppressHeadFaceDecal(head: BasePart)
	for _, child in ipairs(head:GetChildren()) do
		if child:IsA("Decal") and child.Name == "face" then child:Destroy() end
	end
	head.ChildAdded:Connect(function(child)
		if child:IsA("Decal") and child.Name == "face" then child:Destroy() end
	end)
end

-- reads Head.face texture and returns defaultFaceId for MeshPart heads.
local function getHeadFaceId(char: Model): string
	local head = char:FindFirstChild("Head")
	if head and head:IsA("BasePart") and not head:IsA("MeshPart") then
		local decal = head:FindFirstChild("face")
		if decal and decal:IsA("Decal") then
			local tex = (decal :: Decal).Texture
			if tex and tex ~= "" then return tex end
		end
	end
	return defaultFaceId
end

-- finds a face decal on any Part named "Head".
local function getFaceIdRecursive(instance: Instance): string
	if instance.Name == "Head" and instance:IsA("BasePart") and not instance:IsA("MeshPart") then
		local decal = instance:FindFirstChild("face")
		if decal and decal:IsA("Decal") then
			local tex = (decal :: Decal).Texture
			if tex and tex ~= "" then return tex end
		end
	end
	for _, child in ipairs(instance:GetChildren()) do
		local r = getFaceIdRecursive(child)
		if r ~= defaultFaceId then return r end
	end
	return defaultFaceId
end

local function hasDynamicFace(instance: Instance): boolean
	if instance:IsA("FaceControls") then return true end
	for _, child in ipairs(instance:GetChildren()) do
		if hasDynamicFace(child) then return true end 
	end
	return false
end

local function headHasNonClassicMesh(char: Model): boolean
	local head = char:FindFirstChild("Head")
	if not head or not head:IsA("BasePart") then return false end
	if head:IsA("MeshPart") then return true end
	local mesh = (head :: BasePart):FindFirstChildOfClass("SpecialMesh")
	if not mesh then return false end
	return mesh.MeshId ~= "" or mesh.MeshType ~= Enum.MeshType.Head
end

local function isPlayerCharacter(char: Model): boolean
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr.Character == char then return true end
	end
	return false
end

local function ensureFaceDecalLock(char: Model, decal: Decal)
	if rigLockConnected[char] then return end
	rigLockConnected[char] = true
	decal:GetPropertyChangedSignal("Texture"):Connect(function()
		local intended = rigCurrentFaceId[char]
		if intended and decal.Texture ~= intended then
			decal.Texture = intended
		end
	end)
end


-- builds a new classic-head Part and welds it over a MeshPart head.
local function facePartBuilder(char: Model, head: BasePart): Part
	head.Transparency = 1
	suppressHeadFaceDecal(head)

	local fp       = Instance.new("Part")
	fp.Name        = "facePart"
	fp.Size        = Vector3.new(1.9, 0.95, 0.95)
	fp.Color       = head.Color
	fp.Material    = head.Material
	fp.Reflectance = head.Reflectance
	fp.Position    = head.Position
	fp.Orientation = head.Orientation
	fp.CanCollide  = false
	fp.CanQuery    = false
	fp.CanTouch    = false
	fp.Anchored    = false

	local mesh    = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Head
	mesh.Scale    = Vector3.new(1.25, 1.25, 1.25)
	mesh.Parent   = fp

	local decal  = Instance.new("Decal")
	decal.Name   = "face"
	decal.Face   = Enum.NormalId.Front
	decal.Parent = fp

	local weld  = Instance.new("Weld")
	weld.Name   = "faceWeld"
	weld.Part0  = fp
	weld.Part1  = head
	weld.C0     = CFrame.identity
	weld.C1     = CFrame.new(0, faceYOffset, 0)
	weld.Parent = fp

	fp.Parent = char
	adjustAccessoriesForOffset(char, head, faceYOffset)
	return fp
end


-- face applying


local function applyFaceR15(char: Model, faceId: string)
	local head = char:FindFirstChild("Head") :: BasePart?
	if not head then return end

	local fp = char:FindFirstChild("facePart") :: Part?
	if not fp then
		local ok, err = pcall(facePartBuilder, char, head)
		if not ok then warn("faceReverter - facePart failed:", err) return end
		fp = char:FindFirstChild("facePart") :: Part?
		if not fp then return end
	else
		head.Transparency = 1
		suppressHeadFaceDecal(head)
	end

	local decal = (fp :: Part):FindFirstChild("face") :: Decal?
	if not decal then return end

	rigCurrentFaceId[char] = faceId
	decal.Texture          = faceId
	ensureFaceDecalLock(char, decal)
end

local function applyFaceR6(char: Model, faceId: string)
	local head = char:FindFirstChild("Head") :: BasePart?
	if not head then return end

	lockHeadMesh(head)

	local decal = head:FindFirstChild("face") :: Decal?
	if not decal then
		local waited = head:WaitForChild("face", 2)
		if waited and waited:IsA("Decal") then decal = waited :: Decal end
	end
	if not decal then
		decal        = Instance.new("Decal")
		decal.Name   = "face"
		decal.Face   = Enum.NormalId.Front
		decal.Parent = head
	end

	local d = decal :: Decal
	rigCurrentFaceId[char] = faceId
	d.Texture              = faceId
	ensureFaceDecalLock(char, d)
end

-- R15 or R6 based on the Humanoid's RigType.
local function applyClassicFace(char: Model, faceId: string)
	local tung = char:FindFirstChildOfClass("Humanoid", true) :: Humanoid?
	if not tung then return end
	local rig = tung.Parent :: Model
	local ok, err = pcall(function()
		if tung.RigType == Enum.HumanoidRigType.R15 then
			applyFaceR15(rig, faceId)
		elseif tung.RigType == Enum.HumanoidRigType.R6 then
			applyFaceR6(rig, faceId)
		end
	end)
	if not ok then warn("faceReverter - applyClassicFace error:", err) end
end

-- used for dynamic/MeshPart heads searches the full hierarchy for Head and destroys FaceControls.
local function applyFaceCustomRig(char: Model, faceId: string)
	local head: BasePart? = char:FindFirstChild("Head") :: BasePart?
	if not head then
		for _, desc in ipairs(char:GetDescendants()) do
			if desc.Name == "Head" and desc:IsA("BasePart") then
				head = desc :: BasePart
				break
			end
		end
	end
	if not head then return end

	local h = head :: BasePart

	for _, desc in ipairs(char:GetDescendants()) do
		if desc:IsA("FaceControls") then desc:Destroy() end
	end

	local prev = char:FindFirstChild("facePart")
	if prev then prev:Destroy() end

	rigCurrentFaceId[char] = faceId

	local decalTarget: BasePart

	if h:IsA("MeshPart") then
		decalTarget = facePartBuilder(char, h)
	else
		h.Transparency = 0
		lockHeadMesh(h)
		local d = h:FindFirstChild("face") :: Decal?
		if not d then
			d        = Instance.new("Decal")
			d.Name   = "face"
			d.Face   = Enum.NormalId.Front
			d.Parent = h
		end
		decalTarget = h
	end

	local fd = decalTarget:FindFirstChild("face") :: Decal?
	if not fd then return end
	local faceDecal = fd :: Decal
	faceDecal.Texture = faceId
	ensureFaceDecalLock(char, faceDecal)

	-- destroy any FaceControls added after the fact and re-lock the texture.
	char.DescendantAdded:Connect(function(desc)
		if not desc:IsA("FaceControls") then return end
		desc:Destroy()
		task.defer(function()
			if not char.Parent then return end
			if h.Parent and h:IsA("MeshPart") then h.Transparency = 1 end
			if faceDecal.Parent then
				faceDecal.Texture = rigCurrentFaceId[char] or faceId
			end
		end)
	end)
end


-- npc monitoring


local function processNPCModel(model: Model)
	if isPlayerCharacter(model) then return end
	if isExcluded(model) then return end
	if not convertDynamicNpcs and not convertAllRigs then return end
	if not model:FindFirstChildOfClass("Humanoid", true) then return end
	if not model:FindFirstChild("Head", true) then return end
	if not convertAllRigs and not hasDynamicFace(model) then return end

	task.delay(respawnDelay, function()
		if not model.Parent then return end
		if isExcluded(model) then return end
		if not convertAllRigs and not hasDynamicFace(model) then return end
		local ok, err = pcall(function()
			local faceId = getFaceIdRecursive(model)
			applyClassicFace(model, faceId)
			print("faceReverter - converted npc:", model.Name, "to", faceId)
		end)
		if not ok then warn("faceReverter - npc error on", model.Name, ":", err) end
	end)
end

local function collectModels(root: Instance, out: {Model})
	if root:IsA("Model") then table.insert(out, root :: Model) end
	for _, desc in ipairs(root:GetDescendants()) do
		if desc:IsA("Model") then table.insert(out, desc :: Model) end
	end
end

local function startNPCMonitoring()
	local processed: {[Model]: boolean} = {}

	local function tryProcess(m: Model)
		if processed[m] then return end
		processed[m] = true
		task.spawn(processNPCModel, m)
	end

	local function watchRoot(root: Instance)
		local models: {Model} = {}
		collectModels(root, models)
		for _, m in ipairs(models) do tryProcess(m) end

		root.DescendantAdded:Connect(function(desc)
			if desc:IsA("Model") then
				tryProcess(desc :: Model)
			elseif desc:IsA("FaceControls") then
				local anc = desc.Parent
				while anc do
					if anc:IsA("Model") then
						processed[anc :: Model] = nil
						tryProcess(anc :: Model)
						break
					end
					anc = anc.Parent
				end
			end
		end)
	end

	for _, root in ipairs(acceptModelPaths) do
		local ok, err = pcall(watchRoot, root)
		if not ok then warn("faceReverter - acceptModelPaths error:", err) end
	end

	if scanWorkspace then watchRoot(workspace) end
end


-- player rig-change checks


local function convertPlayerRigFace(plr: Player, char: Model)
	if not char.Parent then return end
	if not hasDynamicFace(char) and not headHasNonClassicMesh(char) then return end
	if robloxHeadsOnly and playerRobloxCreator[plr.UserId] == false then return end

	local faceId = playerFaceCache[plr.UserId]
		or (matchDynamicFace and playerDynamicFaceCache[plr.UserId] or "")

	if faceId == "" then
		if dynamicFaceRollback then return end
		if robloxHeadsOnly and playerRobloxCreator[plr.UserId] ~= true then return end
		faceId = defaultFaceId
	end

	local ok, err = pcall(applyFaceCustomRig, char, faceId)
	if not ok then warn("faceReverter - convertPlayerRigFace error:", err) end
end

local function startPlayerCharacterMonitoring(plr: Player, char: Model)
	if not convertRigChanges then return end
	local function isActive(): boolean
		return plr.Character == char and char.Parent ~= nil
	end
	task.delay(respawnDelay + 0.15, function()
		if isActive() then convertPlayerRigFace(plr, char) end
	end)
	char.DescendantAdded:Connect(function(desc)
		if not desc:IsA("FaceControls") then return end
		if not isActive() then return end
		task.delay(respawnDelay, function()
			if isActive() then convertPlayerRigFace(plr, char) end
		end)
	end)
end


-- remote


local function getOrCreateRemote(): RemoteEvent
	local remote = ReplicatedStorage:FindFirstChild(remoteName) :: RemoteEvent?
	if not remote then
		if RunService:IsServer() then
			remote        = Instance.new("RemoteEvent")
			remote.Name   = remoteName
			remote.Parent = ReplicatedStorage
		else
			remote = ReplicatedStorage:WaitForChild(remoteName) :: RemoteEvent
		end
	end
	return remote :: RemoteEvent
end


-- startServer


function FaceReverterModule.startServer()
	assert(RunService:IsServer(), "faceReverter - startServer() must be called from a server Script.")

	ensureFaceIdsLoaded()

	local remote             = getOrCreateRemote()
	local MarketplaceService = game:GetService("MarketplaceService")

	local function applyBestFace(plr: Player, char: Model)
		if not char.Parent then return end
		local faceId = playerFaceCache[plr.UserId]
			or (matchDynamicFace and playerDynamicFaceCache[plr.UserId] or "")
		if not faceId or faceId == "" then return end
		local ok, err = pcall(applyClassicFace, char, faceId)
		if not ok then warn("faceReverter - applyBestFace error:", err) end
	end

	local function resolveDynamicFaceAsync(plr: Player, char: Model)
		if not matchDynamicFace then return end

		if playerDynamicFaceCache[plr.UserId] then
			if robloxHeadsOnly and playerRobloxCreator[plr.UserId] == false then return end
			applyBestFace(plr, char)
			return
		end

		local descOk, desc = pcall(function()
			return Players:GetHumanoidDescriptionFromUserId(plr.UserId)
		end)
		if not descOk or not desc then return end

		local faceAssetId = desc.Face
		if not faceAssetId or faceAssetId == 0 then return end

		local infoOk, info = pcall(MarketplaceService.GetProductInfoAsync, MarketplaceService, faceAssetId)
		if not infoOk or not info then return end

		local creator  = info.Creator and info.Creator.Name
		local isRoblox = creator ~= nil and (creator :: string):lower() == "roblox"

		playerRobloxCreator[plr.UserId] = isRoblox

		if not isRoblox then
			if robloxHeadsOnly then return end
			if dynamicFaceRollback then return end
			playerDynamicFaceCache[plr.UserId] = defaultFaceId
			if not playerFaceCache[plr.UserId] then
				playerFaceCache[plr.UserId] = defaultFaceId
			end
			if plr.Character == char and char.Parent then applyBestFace(plr, char) end
			return
		end

		local name = (info.Name :: string)
			:gsub("%s%-%s*Dynamic%s*Face$", "")
			:gsub("%s%-%s*Face$", "")

		local resolvedId = faceIds[name]

		if resolvedId then
			playerDynamicFaceCache[plr.UserId] = resolvedId
			if not playerFaceCache[plr.UserId] or playerFaceCache[plr.UserId] == defaultFaceId then
				playerFaceCache[plr.UserId] = resolvedId
			end
			print(string.format("faceReverter - resolved dynamic face for %s: %q | %s", plr.Name, name, resolvedId))
		else
			warn(string.format(
				"faceReverter - no json match for dynamic face %q (%s)%s",
				name, plr.Name,
				dynamicFaceRollback and " - keeping dynamic face until respawn" or " - using default"
				))
			if not dynamicFaceRollback then
				-- cache the default so we don't re-hit marketplace on every respawn.
				playerDynamicFaceCache[plr.UserId] = defaultFaceId
				if not playerFaceCache[plr.UserId] then
					playerFaceCache[plr.UserId] = defaultFaceId
				end
			end
			-- dynamicFaceRollback = true: leave cache empty so the next respawn retries.
		end

		if plr.Character == char and char.Parent then
			if resolvedId or not dynamicFaceRollback then
				applyBestFace(plr, char)
			end
		end
	end

	local function handleCharacterLoaded(plr: Player, char: Model)
		task.delay(respawnDelay, function()
			if plr.Character ~= char or not char.Parent then return end

			local isDynamic = hasDynamicFace(char) or headHasNonClassicMesh(char)

			if isDynamic then
				local cached = playerFaceCache[plr.UserId]
					or (matchDynamicFace and playerDynamicFaceCache[plr.UserId] or "")

				local creatorIsRoblox = playerRobloxCreator[plr.UserId] == true
				local creatorIsUGC    = playerRobloxCreator[plr.UserId] == false

				if robloxHeadsOnly and creatorIsUGC then
					-- confirmed ugc - leave the head untouched.
				elseif cached ~= "" then
					applyClassicFace(char, cached)
				elseif dynamicFaceRollback then
					-- no cache yet; preserve the dynamic head until async resolution finishes.
				elseif robloxHeadsOnly and not creatorIsRoblox then
					-- creator unknown; wait for async resolution before applying anything.
				else
					applyClassicFace(char, defaultFaceId)
				end

				local skipResolve = robloxHeadsOnly and creatorIsUGC
				if not skipResolve
					and (not playerFaceCache[plr.UserId] or playerFaceCache[plr.UserId] == defaultFaceId)
				then
					task.spawn(resolveDynamicFaceAsync, plr, char)
				end
			else
				-- classic head: read the texture directly from Head.face.
				local faceId = playerFaceCache[plr.UserId]
				if not faceId or faceId == "" then
					faceId = getHeadFaceId(char)
					if faceId ~= defaultFaceId and faceId ~= "" then
						playerFaceCache[plr.UserId] = faceId
						print(string.format("faceReverter - captured classic face for %s: %s", plr.Name, faceId))
					end
				end
				applyClassicFace(char, faceId)
			end

			startPlayerCharacterMonitoring(plr, char)
		end)
	end

	local function setupPlayer(plr: Player)
		plr.CharacterRemoving:Connect(function(char: Model)
			rigCurrentFaceId[char] = nil
			rigLockConnected[char] = nil
		end)

		plr.CharacterAppearanceLoaded:Connect(function(char: Model)
			handleCharacterLoaded(plr, char)
			remote:FireClient(plr)
		end)

		if plr.Character then
			handleCharacterLoaded(plr, plr.Character :: Model)
		end
	end

	Players.PlayerAdded:Connect(setupPlayer)
	for _, plr in ipairs(Players:GetPlayers()) do task.spawn(setupPlayer, plr) end

	Players.PlayerRemoving:Connect(function(plr: Player)
		playerFaceCache[plr.UserId]        = nil
		playerDynamicFaceCache[plr.UserId] = nil
		playerRobloxCreator[plr.UserId]    = nil
	end)

	-- client sends back resolved face names; look them up and re-apply if anything changed.
	remote.OnServerEvent:Connect(function(plr: Player, headFaceName: string, dynamicFaceName: string?)
		local changed = false

		if headFaceName and headFaceName ~= "" then
			local faceId = faceIds[headFaceName]
			if faceId then
				playerRobloxCreator[plr.UserId] = true
				if faceId ~= playerFaceCache[plr.UserId] then
					playerFaceCache[plr.UserId] = faceId
					changed = true
					print(string.format("faceReverter - cached from client for %s: %q | %s", plr.Name, headFaceName, faceId))
				end
			else
				warn(string.format("faceReverter - no json match for %q (player: %s)", headFaceName, plr.Name))
			end
		end

		if dynamicFaceName and dynamicFaceName ~= "" then
			local dynId = faceIds[dynamicFaceName]
			if dynId then
				playerRobloxCreator[plr.UserId] = true
				if dynId ~= playerDynamicFaceCache[plr.UserId] then
					playerDynamicFaceCache[plr.UserId] = dynId
					if not playerFaceCache[plr.UserId] or playerFaceCache[plr.UserId] == defaultFaceId then
						playerFaceCache[plr.UserId] = dynId
					end
					changed = true
				end
			end
		end

		if not changed then return end

		local char = plr.Character
		if not char then return end

		local bestId = playerFaceCache[plr.UserId]
			or (matchDynamicFace and playerDynamicFaceCache[plr.UserId] or "")
		if bestId == "" then return end

		local ok, err = pcall(applyClassicFace, char, bestId)
		if not ok then warn("faceReverter - OnServerEvent apply error:", err) end
	end)

	if convertDynamicNpcs or convertAllRigs then
		startNPCMonitoring()
	end
end


-- startClient


function FaceReverterModule.startClient()
	assert(RunService:IsClient(), "faceReverter - startClient() must be called from a LocalScript.")

	local MarketplaceService = game:GetService("MarketplaceService")
	local player             = Players.LocalPlayer
	local remote             = getOrCreateRemote()

	-- only sends names for roblox-made assets, implicitly enforcing robloxHeadsOnly.
	local function resolveAndFire()
		local descOk, desc = pcall(function()
			return Players:GetHumanoidDescriptionFromUserIdAsync(player.UserId)
		end)
		if not descOk or not desc then return end

		local headFaceName = ""
		local headId       = desc.Head
		if headId and headId ~= 0 then
			local ok, info = pcall(MarketplaceService.GetProductInfoAsync, MarketplaceService, headId)
			if ok and info then
				local creator = info.Creator and info.Creator.Name
				if creator and creator:lower() == "roblox" then
					headFaceName = (info.Name :: string):gsub("%s%-%s*Head$", "")
					print("faceReverter - client resolved head face:", headFaceName)
				end
			end
		end

		local dynamicFaceName = ""
		if matchDynamicFace and convertRigChanges then
			local faceAssetId = desc.Face
			if faceAssetId and faceAssetId ~= 0 then
				local ok, info = pcall(MarketplaceService.GetProductInfoAsync, MarketplaceService, faceAssetId)
				if ok and info then
					local creator = info.Creator and info.Creator.Name
					if creator and creator:lower() == "roblox" then
						dynamicFaceName = (info.Name :: string)
							:gsub("%s%-%s*Dynamic%s*Face$", "")
							:gsub("%s%-%s*Face$", "")
						print("faceReverter - client resolved dynamic face:", dynamicFaceName)
					end
				end
			end
		end

		remote:FireServer(headFaceName, dynamicFaceName)
	end

	remote.OnClientEvent:Connect(resolveAndFire)

	-- polls for avatar changes; only calls marketplace when asset ids actually change.
	if pollFaceChanges then
		local lastHeadId      = 0
		local lastFaceId      = 0
		local lastHeadName    = ""
		local lastDynamicName = ""

		task.spawn(function()
			while player.Parent do
				task.wait(pollInterval)

				local descOk, desc = pcall(function()
					return Players:GetHumanoidDescriptionFromUserIdAsync(player.UserId)
				end)
				if not descOk or not desc then continue end

				local headAssetId = desc.Head or 0
				local faceAssetId = desc.Face or 0

				if headAssetId == lastHeadId and faceAssetId == lastFaceId then continue end

				local headName    = lastHeadName
				local dynamicName = lastDynamicName

				if headAssetId ~= lastHeadId then
					headName = ""
					if headAssetId ~= 0 then
						local ok, info = pcall(MarketplaceService.GetProductInfoAsync, MarketplaceService, headAssetId)
						if ok and info then
							local creator = info.Creator and info.Creator.Name
							if creator and creator:lower() == "roblox" then
								headName = (info.Name :: string):gsub("%s%-%s*Head$", "")
							end
						end
					end
				end

				if faceAssetId ~= lastFaceId and matchDynamicFace and convertRigChanges then
					dynamicName = ""
					if faceAssetId ~= 0 then
						local ok, info = pcall(MarketplaceService.GetProductInfoAsync, MarketplaceService, faceAssetId)
						if ok and info then
							local creator = info.Creator and info.Creator.Name
							if creator and creator:lower() == "roblox" then
								dynamicName = (info.Name :: string)
									:gsub("%s%-%s*Dynamic%s*Face$", "")
									:gsub("%s%-%s*Face$", "")
							end
						end
					end
				end

				lastHeadId = headAssetId
				lastFaceId = faceAssetId

				if headName ~= lastHeadName or dynamicName ~= lastDynamicName then
					lastHeadName    = headName
					lastDynamicName = dynamicName
					print(string.format("faceReverter - avatar changed: classic head - %q | dynamic head - %q", headName, dynamicName))
					remote:FireServer(headName, dynamicName)
				end
			end
		end)
	end
end


-- public api


-- manually convert a rig using the R6/R15 path. faceId defaults to the existing head decal.
function FaceReverterModule.convertRig(rig: Model, faceId: string?)
	applyClassicFace(rig, faceId or getFaceIdRecursive(rig))
end

-- like convertRig but forces the custom-rig path. use for dynamic/MeshPart heads.
function FaceReverterModule.convertCustomRig(rig: Model, faceId: string?)
	applyFaceCustomRig(rig, faceId or getFaceIdRecursive(rig))
end

-- returns the cached face decal id for a userId, or nil if not yet resolved.
function FaceReverterModule.getPlayerFaceId(userId: number): string?
	return playerFaceCache[userId]
end

-- returns the dynamic face creator status: true = roblox, false = ugc, nil = unknown/classic.
function FaceReverterModule.getPlayerCreatorStatus(userId: number): boolean?
	return playerRobloxCreator[userId]
end
return FaceReverterModule
