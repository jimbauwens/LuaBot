ircs	= {}

irc	= class()

userCommandHandler = {}

userCommandHandler[":!lua"]	= function (self, nick, username, hostname, channel,other)
	if hostname ~= "bwns.be" then self:print(channel, "you got no permission to do this") return end
 	print("D", "calling lua code")
	local fnc, err = loadstring(table.concat(other or "", " "))
	if not fnc then
		self:print(channel, "ERROR:", err)
		print("E", err)
	end
	self:print(channel,unpack(table.part({pcall(fnc)},2)))
end

commandHandler	= {}

commandHandler["376"]	= function (self)
	self:joinChannels()
end

commandHandler["353"]	= function (self, line)
end

commandHandler["PRIVMSG"] = function (self, nick, username, hostname, other)
	if userCommandHandler[other[2]] then
		userCommandHandler[other[2]](self, nick, username, hostname, other[1], table.part(other, 3))
	else
		print(other[1])
	end
end

function irc:init(settings)
	self.settings	= settings
	self.server	= settings.server
	self.port	= settings.port or 6667

	self.id	= 1337
end

function irc:register()
	print("# Registering with IRCS table")
	table.insert(ircs, self)
	self.id	= #ircs
	print("# IRCS ID is " .. self.id)
end

function irc:start()
	local err
	self.socket, err	= socket.connect(self.server, self.port)
	
	if not self.socket then
		print("# Error while try to connect to " .. self.server .. ":" .. self. port .. " !")
		print("# " .. err)
		self:abort()
		return nil, "socket"
	end
	
	self:registerIRC()
end

function irc:abort()
	print("# Aborting")
	self.socket:shutdown()
	ircs[self.id]	= "aborted"
end

function irc:send(...)
	local out	= ""
	for _, s in ipairs{...} do
		out = out .. s .. " "
	end 
	out	= out:sub(1,-2)
	print("<<", out)
	local ok, err	= self.socket:send(out .. "\r\n")
	
	if not ok then
		print("# Error while sending data!")
		self:errorHandler(err)
	end
end

function irc:print(channel, ...)
	local out = ""
	for k,v in ipairs{...} do
		out = out .. tostring(v) .. "    "
	end
	self:send("PRIVMSG", channel, ":" .. out)
end

function ircprint(chan, ...)
	ircs[1]:print(chan, ...)
end


function irc:registerIRC()
	self:send("NICK", self.settings.nick)
	self:send("USER", self.settings.user, self.settings.user, self.server, ":" .. self.settings.fulln)
end

function irc:handleRequests()
	local line, err	= self.socket:receive("*l")
	local spline	= line:split()
	local r, err = true, ""
	if not line then
		self:errorHandler(err)
		return
	end

	if spline[2] ~= "372" then
		print(">>", line)
	end
	
	if spline[1] == "PING" then
		self:send("PONG", spline[2])
	elseif spline[1] == ":" .. self.server or (not spline[1]:find("!")) then
		r, err = pcall(self.handleServerMessage, self, spline)
	elseif spline[1]:sub(1,1) == ":" then
		r, err = pcall(self.handleUserMessage, self, spline)
	end
	
	if not r then 
		print("")
		print("------------------------")
		print("Error when parsing message!")
		print("spline: ", line)
		print("error :", err)
		print("------------------------")
		print("")
	end
end

function irc:handleServerMessage(line)
	if commandHandler[line[2]] then
		commandHandler[line[2]](self, table.part(line, 3))
	end	
end

function irc:handleUserMessage(line)
	local user	= line[1]:sub(2, -1):split("!")
	local nick	= user[1]
	local user	= user[2]:split("@")
	local username	= user[1]
	local hostname	= user[2]
	
	local argstring	= ""
	local argtable	= {}
	
	if commandHandler[line[2]] then
		commandHandler[line[2]](self, nick, username, hostname, table.part(line, 3))
	end
end

function irc:joinChannels()
	for channelname, chan in pairs(self.settings.channels) do
		self:send("JOIN", channelname)
	end
end

function irc:errorHandler(err)
	if err == "closed" then
		print("# Connection closed! Trying to reconnect")
		self.socket:shutdown()
		self:start()
	end
end


function startIRC()
	local s
	for n, session in ipairs(sessions) do
		s	= irc(session)
		s:register()
		s:start()	
	end	
end

function ircStep()
	local cn	= 0
	for n, session in ipairs(ircs) do
		if session ~= "aborted" then
			cn = cn + 1
			session:handleRequests()
		end
		
	end	
	
	if cn == 0 then
		return false
	end
	
	return true
end
