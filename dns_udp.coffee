udp = require "dgram"

parseUDP = (packet) ->


sendUDP = (socket, ip, port, data, cb) ->
	if not socket?
		done = false
		socket = udp.createSocket "udp4"
		timeoutSend = setTimeout () ->
			if not done
				clean()
				cb new Error "Time exceeded"
		, 600
		clean = () ->
			clearTimeout timeoutSend
			done = true
			socket.close()
		socket.on "error", (err) ->
			if not done
				clean()
				cb err
		socket.on "close", () ->
			if not done
				clean()
				cb new Error "socket closed"
		socket.on "message", (data, info) ->
			if not done
				clean()
				cb null, data, info
		socket.send data, 0, data.length, port, ip
	else
		socket.send data, 0, data.length, port, ip, cb

forwardGoogleUDP = (data, limiterUDP, cb) ->
	# start = Date.now()
	nbErrors = 0
	done = false
	timeoutDown = setTimeout () ->
		if not done
			clearTimeout timeoutAlt
			done = true
			cb new Error "Time exceeded ("+nbErrors+" errors)"
	, 800

	timeoutAlt = setTimeout () ->
		limiterUDP.submit sendUDP, null, "8.8.4.4", 53, data, (err, resData, resInfo) ->
			if err? then nbErrors++
			if not done and not err?
				clearTimeout timeoutDown
				done = true
				# console.log (Date.now()-start), "8.8.4.4"
				cb null, resData, resInfo
	, 80

	limiterUDP.submit sendUDP, null, "8.8.8.8", 53, data, (err, resData, resInfo) ->
		if err? then nbErrors++
		if not done and not err?
			clearTimeout timeoutAlt
			clearTimeout timeoutDown
			done = true
			# console.log (Date.now()-start), "8.8.8.8"
			cb null, resData, resInfo

module.exports = {sendUDP, forwardGoogleUDP}
