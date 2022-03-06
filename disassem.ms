// Module to "disassemble" a 2-byte CHIP-8 instruction,
// i.e., return a mnemonic that will help us understand
// what that instruction does.

// The main entry point is mnemonic(byte0, byte1), with
//   input: 2 bytes in numeric form.
//   output: mnemonic string.

// Mnemonic map: defines a mnemonic string or function
// for each of the 16 possible hex values of the first nibble.
// If it's a function, it takes X, Y, and Z (the remaining
// nibbles) and returns a string.  The string returned in
// either case can include X, Y, and Z, which will be 
// replaced with the actual nibbles of the instruction.
mnMap = {}
mnMap["0"] = function(X, Y, Z)
	xyz = X + Y + Z
	if xyz == "0E0" then return "clear display"
	if xyz == "0EE" then return "return"
	return "Firmware XYZ"
end function
mnMap["1"] = "goto XYZ"
mnMap["2"] = "call XYZ"
mnMap["3"] = "skip if VX == YZ"
mnMap["4"] = "skip if VX != YZ"
mnMap["5"] = "skip if VX == VY"
mnMap["6"] = "VX = YZ"
mnMap["7"] = "VX += YZ"
mnMap["8"] = function(X, Y, Z)
	if Z == "0" then return "VX = VY"
	if Z == "1" then return "VX |= VY"
	if Z == "2" then return "VX &= VY"
	if Z == "3" then return "VX ^= VY"
	if Z == "4" then return "VX += VY"
	if Z == "5" then return "VX -= VY"
	if Z == "6" then return "VX >>= 1"
	if Z == "7" then return "VX = VY - VX"
	if Z == "E" then return "VX <<= 1"	
end function
mnMap["9"] = "skip if VX != VY"
mnMap["A"] = "I = XYZ"
mnMap["B"] = "goto XYZ + V0"
mnMap["C"] = "VX = rnd & YZ"
mnMap["D"] = "draw Z bytes at VX, VY"
mnMap["E"] = function(X, Y, Z)
	yz = Y + Z
	if yz == "9E" then return "skip if key VX pressed"
	if yz == "A1" then return "skip if key VX not pressed"
end function
mnMap["F"] = function(X, Y, Z)
	yz = Y + Z
	if yz == "07" then return "VX = timer"
	if yz == "0A" then return "VX = get_key()"
	if yz == "15" then return "timer = VX"
	if yz == "18" then return "sound = VX"
	if yz == "1E" then return "I += VX"
	if yz == "29" then return "I = sprite_addr[VX]"
	if yz == "33" then return "store BCD(VX) at I"
	if yz == "55" then return "reg_save V0-VX at I"
	if yz == "65" then return "reg_load V0-VX from I"	
end function

mnemonic = function(byte0, byte1)
	ax = hex2(byte0)
	yz = hex2(byte1)
	a = ax[0]; x = ax[1]
	y = yz[0]; z = yz[1]
	result = "?!?"
	if mnMap.hasIndex(a) then
		result = mnMap[a]
		if @result isa funcRef then result = result(x, y, z)		
	end if
	result = result.replace("X", x).replace("Y", y).replace("Z", z)
	return result
end function

// Helper function to get a 0-255 value from a 2-digit hex number.
hexVal = function(hex2)
	result = 0
	for i in [0,1]
		c = hex2[i].code
		if c >= 97 then  // lowercase letter
			result = result * 16 + c - 87
		else if c >= 65 then // uppercase letter
			result = result * 16 + c - 55
		else  // number
			result = result * 16 + c - 48
		end if
	end for
	return result
end function

if locals == globals then
	// Run unit tests, with a check function that takes
	// an instruction in 4-character hex form, and the
	// expected mnemonic.
	errCount = 0
	check = function(hex4, expected)
		byte0 = hexVal(hex4[:2])
		byte1 = hexVal(hex4[2:])
		m = mnemonic(byte0, byte1)
		if m == expected then return
		print "Unit test failure: expected " + expected + ", but got " + m
		outer.errCount = errCount + 1
	end function
	
	check "00E0", "clear display"
	check "00EE", "return"
	check "1ABC", "goto ABC"
	check "2123", "call 123"
	check "3812", "skip if V8 == 12"
	check "4812", "skip if V8 != 12"
	check "5ABC", "skip if VA == VB"
	check "6123", "V1 = 23"
	check "7123", "V1 += 23"
	check "8424", "V4 += V2"
	check "9ABC", "skip if VA != VB"
	check "A123", "I = 123"
	check "B123", "goto 123 + V0"
	check "C50F", "V5 = rnd & 0F"
	check "D015", "draw 5 bytes at V0, V1"
	check "E49E", "skip if key V4 pressed"
	check "FA15", "timer = VA"
	
	if errCount == 0 then
		print "All unit tests passed.  :)"
	else
		print errCount + " errors found."
	end if
end if
