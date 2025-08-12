// a CHIP-8 emulator for Mini Micro

import "qa"
import "disassem"
import "chars"
mnemonic = @disassem.mnemonic
clear

// Load the CHIP-8 program data
oldDir = file.curdir
file.setdir "/usr/samples"
dataPath = findFile("Select .ch8 file to load")
if not dataPath then exit
data = file.loadRaw(dataPath)
file.setdir oldDir

text.color = color.gray
text.row = 2
print "RETURN: run/pause"
print "Space or s: step"
text.color = color.silver

// Machine description
memory = [0]*4096
PC = 512
I = 0
V = [0]*16
returnStack = []
timerStartVal = 0
timerStartTime = 0

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
	text.column = 10; print "Return"
	text.column = 10; print "Stack:"
	for s in returnStack
		text.column = 10; print hex4(s)
	end for
	text.column = 10; print "    "  // (clears last entry after a return)
	text.row = 10
	text.column = 24; print "  ADDR  CODE  Meaning"
	text.column = 24; print "  ----  ----  -------", ""
	for addr in range(PC-8, PC+8, 2)
		if addr == PC then line = chars.right + " " else line = "  "
		if addr >= 0 then
			line += hex4(addr) + "  "
			op0 = memory[addr]
			op1 = memory[addr+1]
			line = line + hex4(op0*256+op1) + "  " + mnemonic(op0, op1)
			line = line + " " * (43 - line.len) // (clears to end of line)
			text.row -= 1
			text.column = 24; print line, ""
		end if
	end for
	text.row = 25; text.column = 0
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
	td.setCell range(63), range(31), 0
	td.setCellTint range(63), range(31), color.blue
end function
clearDisplay

drawSprite = function(x, y, address, height)
	//print "drawingSprite " + x + "," +y + ", " + address + ", " + height
	flippedOff = false
	for i in range(0, height-1)
		data = memory[address + i]
		for j in range(7,0)
			bit = data % 2
			data = floor(data / 2)
			if not bit then continue
			cellx = (x + j) % 64
			celly = (31 - y - i) % 32
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
		
		hiNibble = floor(opHi / 16)
		if hiNibble < 8 then
			if hiNibble < 4 then
				if hiNibble < 2 then
					if hiNibble == 1 then  // Go To
						globals.PC = (opHi % 16) * 256 + opLo
						//print "Set PC to " + PC
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
						if V[opHi % 16] == opLo then globals.PC += 2
					end if
				end if
			else  // 4-7
				if hiNibble < 6 then
					if hiNibble == 4 then // if (Vx != NN)
						if V[opHi % 16] != opLo then globals.PC += 2
					else  // if (Vx == Vy)
						if V[opHi % 16] == V[floor(opLo/16)] then globals.PC += 2
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
						if V[opHi % 16] != V[floor(opLo/16)] then globals.PC += 2
					end if
				else // 10-11
					if hiNibble == 10 then // 10: I = NNN
						globals.I = (opHi % 16) * 256 + opLo
						//print "Set I to " + globals.I
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
						keyNum = -1
						if V[0] >= 0 and V[0] < 16 then keyNum = V[0]
						keyChar = "0123qweasdzc4rfv~"[keyNum]
						isPressed = key.pressed(keyChar)
						if opLo == 158 then  // skip if key V0 pressed
							if isPressed then globals.PC += 2
						else if opLo == 161 then  // skip if key V0 not pressed
							if not isPressed then globals.PC += 2
						end if
					else // 15 (various)
						if opLo == 7 then  // Vx = timer
							elapsed = time - timerStartTime
							newVal = timerStartVal - elapsed*60
							if newVal < 0 then newVal = 0
							V[opHi % 16] = newVal
						else if opLo == 10 then // Vx = get_key()
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
						else if opLo == 21 then // timer = Vx
							globals.timerStartVal = V[opHi % 16]
							globals.timerStartTime = time
						end if						
					end if						
				end if
			end if
			
		end if
		globals.PC += 2
	end while
end function

runMachine = function
	// Run machine continuously until Return or Esc is pressed.
	text.row=25; text.column = 0; print " RUNNING "
	text.row = 4
	while key.pressed("return") or key.pressed("space"); end while
	while true
		if key.pressed("return") or key.pressed("space") then break
		simulate 1  // use a higher number here for faster simulation
		drawMachineState
	end while
	key.clear
	drawMachineState
end function

stepMachine = function
	text.row=25; text.column = 0; print " STEPPING "
	text.row = 4
	simulate 1
	key.clear
	drawMachineState
end function

while true
	text.row=25; text.column = 0; print " Ready!   "
	k = key.get
	if k == "s" or k == " " then
		stepMachine
	else if k.code == 10 then
		runMachine
	end if
end while