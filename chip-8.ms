// a CHIP-8 emulator for Mini Micro

import "qa"
clear

// Machine description
memory = [0]*4096
PC = 512
I = 0
V = [0]*16
returnStack = []

hex4 = function(value)
	return hex2(floor(value/256)) + hex2(value % 256)
end function

drawMachineState = function
	text.row = 23
	print "PC: " + hex4(PC)
	print "I:  " + hex4(I)
	for i in range(0, 15)
		print "V" + hex2(i)[-1] + ": " + hex2(V[i])
	end for
	text.row = 23
	text.column = 10; print "Return Stack:"
	for s in returnStack
		text.column = 10; print hex4(s)
	end for
	text.row = 4
end function

// prepare the tile display
display(4).mode = displayMode.tile
td = display(4)
td.extent = [64, 32]
td.tileSet = Image.create(8,8, color.white)
td.tileSetTileSize = 8
td.cellSize = 10
td.clear 0
td.scrollX = -300
td.scrollY = -300
clearDisplay = function
	for x in range(63)
		for y in range(31)
			td.setCellTint x, y, color.blue
		end for
	end for
end function
clearDisplay

drawSprite = function(x, y, address, height)
	print "drawingSprite " + x + "," +y + ", " + address + ", " + height
	flippedOff = false
	for i in range(0, height-1)
		data = memory[address + i]
		for j in range(7,0)
			bit = data % 2
			data = floor(data / 2)
			if not bit then continue
			cellx = x + j
			celly = (31 - y - i)
			if td.cellTint(cellx, celly)[:7] == color.white then
				td.setCellTint cellx, celly, color.blue
				flippedOff = true
			else
				td.setCellTint cellx, celly, color.white
			end if
		end for
	end for	
	return flippedOff
end function

// load the program
data = file.loadRaw("samples/tank.ch8")
for i in range(0, data.len-1)
	memory[i + 512] = data.byte(i)
end for

drawMachineState
//drawSprite 5, 3, 514, 8

// simulate!
simulate = function(stepLimit=null)
	while true
		if stepLimit != null then
			stepLimit = stepLimit - 1
			if stepLimit < 0 then return
		end if
		opHi = memory[PC]
		opLo = memory[PC+1]
		print "opHi:" + hex2(opHi) + "  opLo:" + hex2(opLo)
		hiNibble = floor(opHi / 16)
		if hiNibble < 8 then
			if hiNibble < 4 then
				if hiNibble < 2 then
					if hiNibble == 1 then  // Go To
						globals.PC = (opHi % 16) * 256 + opLo
						print "Set PC to " + PC
						continue
					end if
					if hiNibble == 0 then
						if opLo == 224 then  // Clear Screen
							clearDisplay
						else if opLo == 238 then  // return
							globals.PC = returnStack.pop							
						else
							qa.abort "opHi " + opHi + " + not supported"
						end if
					end if
				else  // 2-3
					if hiNibble == 2 then  // Gosub
						returnStack.push PC
						globals.PC = (opHi % 16) * 256 + opLo
						continue
					else  // if (Vx == NN)
						if V[opHi % 16] == opLo then PC = PC + 2
					end if
				end if
			else  // 4-7
				if hiNibble < 6 then
					if hiNibble == 4 then // if (Vx != NN)
						if V[opHi % 16] != opLo then PC = PC + 2
					else  // if (Vx == Vy)
						if V[opHi % 16] == V[floor(opLo/16)] then PC = PC + 2
					end if
				else  // 6-7
					if hiNibble == 6 then // Vx = N
						V[opHi % 16] = opLo
					else // Vx += N
						V[opHi % 16] = (V[opHi % 16] + opLo) % 256
					end if
				end if
			end if
		else  // >= 8...
			if hiNibble < 12 then
				if hiNibble < 10 then
					if hiNibble == 8 then  // 
						qa.abort hex2(opHi) + " not implemented yet"
					else // 9: if (Vx != Vy)
						if V[opHi % 16] != V[floor(opLo/16)] then PC = PC + 2
					end if
				else // 10-11
					if hiNibble == 10 then // 10: I = NNN
						globals.I = (opHi % 16) * 256 + opLo
						print "Set I to " + globals.I
					else // 11: PC = V0 + NNN
						globals.PC = V[0] + (opHi % 16) * 256 + opLo
					end if
				end if
			else  // 12-15
				if hiNibble < 14 then
					if hiNibble == 12 then // Rand
						V[opHi % 16] = bitAnd(floor(rnd*256), opLo)
					else // draw(Vx, Vy, N)
						flippedAny = drawSprite(V[opHi % 16],
						V[floor(opLo / 16)], I, opLo % 16)
						V[15] = flippedAny						
					end if
				else // 14-15
					if hiNibble == 14 then // 14 (some key check)
					else // 15 (various)
						if opLo == 10 then // Vx = get_key()
							k = key.get.code
							keyVal = 255
							if k == 17 then // left
								keyVal = 7
							else if k == 18 then // right
								keyVal = 9
							else if k == 19 then // up
								keyVal = 5
							else if k == 20 then // down
								keyVal = 8
							end if
							V[opHi % 16] = keyVal
						end if						
					end if						
				end if
			end if
			
		end if
		globals.PC = PC + 2
	end while
end function

while true
	simulate 1
	drawMachineState
	//key.get
end while