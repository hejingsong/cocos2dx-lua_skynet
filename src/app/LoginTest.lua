local fd = assert(socket.connect("SERVER_HOST", LOGIN_SERVER_PORT))

local function writeline(fd, text)
	fd:send(text .. "\n")
end

local function unpack_line(text)
	local from = text:find("\n", 1, true)
	if from then
		return text:sub(1, from-1), text:sub(from+1)
	end
	return nil, text
end

local last = ""

local function unpack_f(f)
	local function try_recv(fd, last)
		local result
		result, last = f(last)
		if result then
			return result, last
		end
		local r = fd:receive(1)
		if not r then
			return nil, last
		end
		if r == "" then
			error "Server closed"
		end
		return f(last .. r)
	end

	return function()
		while true do
			local result
			result, last = try_recv(fd, last)
			if result then
				return result
			end
			-- socket.usleep(100)/
		end
	end
end

local readline = unpack_f(unpack_line)

local challenge = crypt.base64decode(readline())

local clientkey = crypt.randomkey()
writeline(fd, crypt.base64encode(crypt.dhexchange(clientkey)))
local secret = crypt.dhsecret(crypt.base64decode(readline()), clientkey)

print("sceret is ", crypt.hexencode(secret))

local hmac = crypt.hmac64(challenge, secret)
writeline(fd, crypt.base64encode(hmac))

local token = {
	server = "Game",
	user = "hello11",
	pass = "password",
}

local function encode_token(token)
	return string.format("%s@%s:%s",
		crypt.base64encode(token.user),
		crypt.base64encode(token.server),
		crypt.base64encode(token.pass))
end

local etoken = crypt.desencode(secret, encode_token(token))
local b = crypt.base64encode(etoken)
writeline(fd, crypt.base64encode(etoken))

local result = readline()
print(result)
local code = tonumber(string.sub(result, 1, 3))
assert(code == 200)
fd:close()

local subid = crypt.base64decode(string.sub(result, 5))

print("login ok, subid=", subid)

----- connect to game server

local function send_request(fd, v, session)
	local size = #v + 4
	local package = string.pack(">H", size)..v..string.pack(">I", session)
	fd:send(package)
	return v, session
end

local function recv_response(v)
	local size = #v - 5
	local s = ">A" .. tostring(size) .. 'bI4'
	local len, content, ok, session = string.unpack(v, s)
	return ok ~=0 , content, session
end

local function unpack_package(text)
	local size = #text
	if size < 2 then
		return nil, text
	end
	local s = text:byte(1) * 256 + text:byte(2)
	if size < s+2 then
		return nil, text
	end

	return text:sub(3,2+s), text:sub(3+s)
end

local readpackage = unpack_f(unpack_package)

local function send_package(fd, pack)
	local size = #pack
	local package = string.pack(">HA", size, pack)
	fd:send(package)
end

local text = "echo"
local index = 1

print("connect")
fd = assert(socket.connect("SERVER_HOST", SERVER_PORT))
last = ""

local handshake = string.format("%s@%s#%s:%d", crypt.base64encode(token.user), crypt.base64encode(token.server),crypt.base64encode(subid) , index)
local hmac = crypt.hmac64(crypt.hashkey(handshake), secret)


send_package(fd, handshake .. ":" .. crypt.base64encode(hmac))

print(readpackage())
print("===>",send_request(fd, text,0))
-- don't recv response
-- print("<===",recv_response(readpackage()))

print("disconnect")
fd:close(fd)

index = index + 1

print("connect again")
fd = assert(socket.connect("SERVER_HOST", SERVER_PORT))
last = ""

local handshake = string.format("%s@%s#%s:%d", crypt.base64encode(token.user), crypt.base64encode(token.server),crypt.base64encode(subid) , index)
local hmac = crypt.hmac64(crypt.hashkey(handshake), secret)

send_package(fd, handshake .. ":" .. crypt.base64encode(hmac))

print(readpackage())
print("===>",send_request(fd, "fake",0))	-- request again (use last session 0, so the request message is fake)
print("===>",send_request(fd, "again",1))	-- request again (use new session)
print("<===",recv_response(readpackage()))
print("<===",recv_response(readpackage()))


print("disconnect")
fd:close()

