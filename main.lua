_BotVersion	= "0.1"

print("Hello, World!")
print("This is LuaBot " .. _BotVersion .. " !\n")

print("Loading socket module...")
local socket	= require "socket"

print("Loading tools...")
dofile 'tools.lua'
print("Loading settings...")
dofile 'settings.lua'

--print("Loading rss module...")
--dofile 'rss.lua'

print("Loading main bot code")
dofile 'bot.lua'

print("\nStarting bot\n")

startIRC()
t=0

while true do
	good	= ircStep()
	if not good then 
		print("# Quiting, no connection left")
		break
	end
	
	-- local time	= os.time()
	-- if time>lastCheck+25 then
	-- 	checkPosts()
	-- end
end
