//
//  CZKBaito8080.swift
//  CZKBaito8080 Machine
//
//  Created by Cecilio C. Tamarit on 22/01/2018.
//  Copyright © 2018 cecetaca. All rights reserved.
//

import Cocoa

extension String {

	var formatByteZeroes: String {
		var newStr = self
		if count == 1 {
			newStr = "0"+self
		}
		return newStr
	}

	var formatPC: String {
		var newStr = ""
		if (count < 2) {
			newStr += "000\(self)    "
		} else if (count < 3) {
			newStr += "00\(self)    "
		} else if (count < 4) {
			newStr += "0\(self)    "
		} else {
			newStr += "\(self)    "
		}
		return newStr
	}
}


class CZKBaito8080: NSObject {

	//Registers
	var pc = 0
	var SP = 0x23DE
	var A: UInt8 = 0
	var B: UInt8 = 0
	var C: UInt8 = 0
	var D: UInt8 = 0
	var E: UInt8 = 0
	var H: UInt8 = 0
	var L: UInt8 = 0

	//Flags
	var IE = 0
	var Z = 0
	var S = 0
	var P = 0
	var CY = 0
	var AC = 0


	var array = [UInt8]()
	var output = ""
	var cycles = 0
	var instCount = 0
	var running = false
	var interruptToHandle = 0


	init(filePath: String) {
		let location = NSString(string:filePath).expandingTildeInPath
		print(location)
		let fileData = NSData(contentsOfFile: location)!
		//Bytes contained in the file (length/bytesize)
		let count = fileData.length / MemoryLayout<UInt8>.size

		array = [UInt8](repeating: 0, count: count+0x6000) //ROM+RAM+Mirror (Taito machine hardware)
		fileData.getBytes(&array, length:count * MemoryLayout<UInt8>.size)
	}


	//MARK: REPL
	func disassemble() {
		let hexPC = String(pc, radix:16)
		var str = hexPC.formatPC

		let byte2 = String(array[pc+1],radix:16).formatByteZeroes
		let byte3 = String(array[pc+2],radix:16).formatByteZeroes

		handleInterrupts()

		switch (array[pc]) {

			case 0: str += "NOP"
				cycles += 1
				pc += 1
			// ALU
			case 0x03: str += "INX B"
				incrementRegisterPair(reg: &B)
				cycles += 1
				pc += 1
			case 0x05: str += "DCR B" //Decrement register B
				decrementRegister(reg: &B)
				cycles += 1
				pc += 1
			case 0x09: str += "DAD B" //Add B & C to H & L
				addRegisterPairToHL(reg: &B)
				cycles += 3
				pc += 1
			case 0x0D: str += "DCR C" //Decrement register C
				decrementRegister(reg: &C)
				cycles += 1
				pc += 1
			case 0x0F: str += "RRC" //Rotate right
				rotateRight()
				cycles += 1
				pc += 1
				break
			case 0x13: str += "INX D" //Increment D & E register pair
				incrementRegisterPair(reg: &D)
				cycles += 1
				pc += 1
			case 0x19: str += "DAD D" //Add D & E to H & L
				addRegisterPairToHL(reg: &D)
				cycles += 3
				pc += 1
			case 0x24: str += "INR H" //Increment register
				incrementRegister(reg: &H)
				cycles += 1
				pc += 1
			case 0x23: str += "INX H" //Increment H & L register pair
				incrementRegisterPair(reg: &H)
				cycles += 1
				pc += 1
			case 0x27: str += "DAA" //Decimal Adjust Accumulator
				decimalAdjust(reg: &A)
				cycles += 1
				pc += 1
			case 0x29: str += "DAD H" //Add H & L to H & L
				addRegisterPairToHL(reg: &H)
				cycles += 3
				pc += 1
			case 0x35: str += "DCR M"
				decrementMemory()
				cycles += 3
				pc += 1
			case 0x37: str += "STC"
				CY = 1
				cycles += 1
				pc += 1
			case 0x3D: str += "DCR A"
				decrementRegister(reg: &A)
				cycles += 1
				pc += 1
			case 0x80: str += "ADD B"
				addRegister(reg: &B)
				cycles += 1
				pc += 1
			case 0xA7: str += "ANA A"
				andRegister(reg: &A)
				cycles += 1
				pc += 1
			case 0xAF: str += "XRA A" //XOR A with A
				exclusiveOr(reg: &A)
				cycles += 1
				pc += 1
			case 0xB0: str += "ORA B" //OR B with A
				orRegister(reg: &B)
				cycles += 1
				pc += 1
			case 0xC6: str += "ADI #$\(byte2)"
				addInmediate(inm: UInt8(byte2, radix:16)!)
				cycles += 2
				pc += 2
			case 0xE6: str += "ANI #$\(byte2)"
				andInmediate(inm: UInt8(byte2,radix:16)!)
				cycles += 2
				pc += 2
			case 0xFE: str += "CPI #$\(byte2)" // Compare inmediate to (A)ccumulator
				compareInmediate(inm: UInt8(byte2,radix:16)!)
				cycles += 2
				pc += 2


			// BRANCH
			case 195: str += "JMP $\(String(array[pc+2],radix:16))\(String(array[pc+1],radix:16))"
				jumpInmediate(inm: Int(byte3+byte2,radix:16)!)
				cycles += 3
			case 0xC0: str += "RNZ"
				retNoZero()
			case 0xC2: str += "JNZ $\(byte3)\(byte2)"
				jumpNotZero(inm: Int(byte3+byte2,radix:16)!)
				cycles += 3
			case 0xC8: str += "RZ"
				retOnZero()
			case 0xC9: str += "RET"
				returnFromException()
				cycles += 3
			case 0xCA: str += "JZ $\(byte3)\(byte2)"
				jumpOnZero(inm: Int(byte3+byte2,radix:16)!)
				cycles += 3
			case 0xCD: str += "CALL $\(byte3)\(byte2)" //Call unconditional addr
				callException(inm: Int(byte3+byte2,radix:16)!)
				cycles += 5
			case 0xD2: str += "JNC $\(byte3)\(byte2)"
				jumpNoCarry(inm: Int(byte3+byte2,radix:16)!)
				cycles += 3
			case 0xD8: str += "RC"
				retOnCarry()
			case 0xDA: str += "JC $\(byte3)\(byte2)"
				jumpOnCarry(inm: Int(byte3+byte2,radix:16)!)
				cycles += 3
			case 0xE9: str += "PCHL" //HL to PC
				jumpInmediate(inm: Int(H+L+1))
				cycles += 1
			// DATA TRANSFER
			case 0x01: str += "LXI B, #$\(byte3)\(byte2)" //Load inmediate register pair B & C
				loadInmediateRegisterPair(reg: &B, byte3: UInt8(byte3,radix:16)!, byte2: UInt8(byte2,radix:16)!)
				cycles += 3
				pc += 3
			case 0x06: str += "MVI B, #$\(byte2)" //Move inmediate
				moveInmediate(reg: &B, inm: UInt8(byte2,radix:16)!)
				cycles += 2
				pc += 2
			case 0x0A: str += "LDAX B" //Load (A)ccumulator indirect
				loadAccumulatorIndirect(reg: &B)
				cycles += 2
				pc += 1
			case 0x0E: str += "MVI C, #$\(byte2)" //Move inmediate
				moveInmediate(reg: &C, inm: UInt8(byte2,radix:16)!)
				cycles += 2
				pc += 2
			case 0x11: str += "LXI D, #$\(byte3)\(byte2)" //Load inmediate register pair D & E
				loadInmediateRegisterPair(reg: &D, byte3: UInt8(byte3,radix:16)!, byte2: UInt8(byte2,radix:16)!)
				cycles += 3
				pc += 3
			case 0x1A: str += "LDAX D" //Load (A)ccumulator indirect
				loadAccumulatorIndirect(reg: &D)
				cycles += 2
				pc += 1
			case 0x21: str += "LXI H, #$\(byte3)\(byte2)" //Load inmediate register pair H & L
				loadInmediateRegisterPair(reg: &H, byte3: UInt8(byte3,radix:16)!, byte2: UInt8(byte2,radix:16)!)
				cycles += 3
				pc += 3
			case 0x26: str += "MVI H, #$\(byte2)" //Move inmediate
				moveInmediate(reg: &H, inm: UInt8(byte2,radix:16)!)
				cycles += 2
				pc += 2
			case 0x31: str += "LXI SP, #$\(byte3)\(byte2)" //Load inmediate stack pointer
				SP = Int("\(byte3)\(byte2)",radix:16)!
				cycles += 3
				pc += 3
		case 0x32: str += "STA #$\(byte3)\(byte2)" //Store A(ccumulator) direct
				storeAccumulatorDirect(addr: Int("\(byte3)\(byte2)", radix:16)!)
				cycles += 4
				pc += 3
			case 0x36: str += "MVI M, #$\(byte2)" //Move to memory inmediate
				moveToMemory(inm: UInt8(byte2,radix:16)!)
				cycles += 3
				pc += 2
			case 0x3A: str += "LDA $\(byte3)\(byte2)" //Load (A)ccumulator direct
				loadAccumulatorDirect(addr: Int("\(byte3)\(byte2)", radix:16)!)
				cycles += 4
				pc += 3
			case 0x3E: str += "MVI A, #$\(byte2)" //Move inmediate to A
				moveInmediate(reg: &A, inm: UInt8(byte2, radix:16)!)
				cycles += 2
				pc += 2
			case 0x46: str += "MOV B, M" //Move from memory
				moveFromMemory(reg: &B)
				cycles += 2
				pc += 1
			case 0x4F: str += "MOV C, A"
				moveRegister(reg: &A, toRegister: &C)
				cycles += 1
				pc += 1
			case 0x56: str += "MOV D, M" //Move from memory
				moveFromMemory(reg: &D)
				cycles += 2
				pc += 1
			case 0x57: str += "MOV D, A"
				moveRegister(reg: &A, toRegister: &D)
				cycles += 1
				pc += 1
			case 0x5E: str += "MOV E, M" //Move from memory
				moveFromMemory(reg: &E)
				cycles += 2
				pc += 1
			case 0x5F: str += "MOV E, A"
				moveRegister(reg: &A, toRegister: &E)
				cycles += 1
				pc += 1
			case 0x66: str += "MOV H, M" //Move from memory
				moveFromMemory(reg: &H)
				cycles += 2
				pc += 1
			case 0x67: str += "MOV H, A"
				moveRegister(reg: &A, toRegister: &H)
				cycles += 1
				pc += 1
			case 0x6F: str += "MOV L, A" //Move register to register (r1) <- (r2)
				moveRegister(reg: &A, toRegister: &L)
				cycles += 1
				pc += 1
			case 0x77: str += "MOV M, A" //Move register to memory
				moveToMemory(reg: &A)
				cycles += 2
				pc += 1
			case 0x79: str += "MOV A, D" //Move register to register (r1) <- (r2)
				moveRegister(reg: &C, toRegister: &A)
				cycles += 1
				pc += 1
			case 0x7A: str += "MOV A, D" //Move register to register (r1) <- (r2)
				moveRegister(reg: &D, toRegister: &A)
				cycles += 1
				pc += 1
			case 0x7B: str += "MOV A, E"
				moveRegister(reg: &E, toRegister: &A)
				cycles += 1
				pc += 1
			case 0x7C: str += "MOV A, H" //Move register to register (r1) <- (r2)
				moveRegister(reg: &H, toRegister: &A)
				cycles += 1
				pc += 1
			case 0x7E: str += "MOV A, M" //Move from memory
				moveFromMemory(reg: &A)
				cycles += 2
				pc += 1
			case 0xEB: str += "XCHG" //Exchange H & L with D & E
				exchangeDEHL()
				cycles += 1
				pc += 1
			// STACK, I/O, MACHINE CONTROL
			case 0xC1: str += "POP B"
				popOffStack(reg: &B)
				cycles += 3
				pc += 1
			case 0xC5: str += "PUSH B"
				pushOnStack(reg: &B)
				cycles += 3
				pc += 1
			case 0xD1: str += "POP D"
				popOffStack(reg: &D)
				cycles += 3
				pc += 1
			case 0xD3: str += "OUT #$\(byte2)" //Output
				outputTo(port: Int(byte2, radix:16)!)
				cycles += 3
				pc += 2
			case 0xD5: str += "PUSH D" //Push register pair D & E on stack
				pushOnStack(reg: &D)
				cycles += 3
				pc += 1
			case 0xDB: str += "IN #$\(byte2)" //Input
				inputIn(port: Int(byte2, radix:16)!)
				cycles += 3
				pc += 2
			case 0xE1: str += "POP H"
				popOffStack(reg: &H)
				cycles += 3
				pc += 1
			case 0xE3: str += "XTHL" //Exchange top of stack
				exchangeStackTop()
				cycles += 5
				pc += 1
			case 0xE5: str += "PUSH H"
				pushOnStack(reg: &H)
				cycles += 3
				pc += 1
			case 0xF1: str += "POP PSW"
				popProcessorStatusWord()
				cycles += 3
				pc += 1
			case 0xf5: str += "PUSH PSW"
				pushProcessorStatusWord()
				cycles += 3
				pc += 1
			case 0xFB: str += "EI" //Enable interrupts
				enableInterrupts()
				cycles += 1
				pc += 1
			default: str += "\(String(array[pc],radix:16)) ***No implementada***"
				pc += 1
		}
		addOutput(res: str)
		instCount += 1

	}

	func handleInterrupts() {
		if (IE == 1) {
			IE = 0
			//Handle
			if (interruptToHandle != 0) {
				//print("Handling interrupt \(interruptToHandle)")
				callInterrupt(inm: 8*interruptToHandle)
				//interruptToHandle = 0
			}
		}
	}

	//MARK: Flags
	func setUpdatingFlags(value: Int, clearCarry:Bool) -> UInt8 {
		var value8: UInt8?
		// Carry
		if (value > 0xFF) {
			value8 = UInt8(value - 0xFF - 1)
			CY = 1
		} else if (value < 0) {
			value8 = UInt8(0xFF - value*(-1) + 1)
			CY = 1
		} else {
			value8 = UInt8(value)
		}
		if (clearCarry) {
			CY = 0
			AC = 0
		}

		// Zero
		if (value == 0) {
			Z = 1
		} else {
			Z = 0
		}
		// Sign
		if (value8! & 0x80 == 0x80) {
			S = 1
		} else {
			S = 0
		}
		// Parity
		if (value8! % 2 == 0) {
			P = 1
		} else {
			P = 0
		}

		return value8!

	}

	//MARK: - ALU functions
	func decrementRegister(reg:UnsafeMutablePointer<UInt8>) {
		let res = Int(reg.pointee) - 1
		reg.pointee = setUpdatingFlags(value: res, clearCarry: false)
	}

	func decrementMemory() {
		let res = array[Int("\(String(H,radix:16))\(String(L,radix:16))",radix:16)!]
		array[Int("\(String(H,radix:16).formatByteZeroes)\(String(L,radix:16).formatByteZeroes)",radix:16)!] = setUpdatingFlags(value: Int(res) - 1, clearCarry: false)
	}

	func incrementRegisterPair(reg:UnsafeMutablePointer<UInt8>) {
		incrementRegister(reg:reg.advanced(by: 1))
		if (reg.advanced(by: 1).pointee == 0) {
			incrementRegister(reg: reg)
		}
	}

	func incrementRegister(reg: UnsafeMutablePointer<UInt8>) {
		let res = Int(reg.pointee) + 1
		reg.pointee = setUpdatingFlags(value: res, clearCarry: false)
	}

	func addRegister(reg: UnsafePointer<UInt8>) {
		let res = Int(A) + Int(reg.pointee)
		A = setUpdatingFlags(value: res, clearCarry: false)
	}

	func andInmediate(inm: UInt8) {
		let res = Int(A & inm)
		A = setUpdatingFlags(value: res, clearCarry: true)
	}

	func compareInmediate(inm: UInt8) {
		let res = Int(A) - Int(inm)
		_ = setUpdatingFlags(value: res, clearCarry: false)
	}

	func addRegisterPairToHL(reg: UnsafeMutablePointer<UInt8>) {
		let newL = Int(L) + Int(reg.successor().pointee)
		L = setUpdatingFlags(value: newL, clearCarry: false)
		var newH = Int(reg.pointee)
		if (&L-1 == reg) {			//Swift enforces exclusive access. This can be disabled or "dirty-fixed" this way.
			newH = newH + newH
			if (CY == 1) {
				newH = newH+1
			}
			reg.pointee = setUpdatingFlags(value: newH, clearCarry: false)
		} else {
			newH = newH + Int(H)
			if (CY == 1) {
				newH = newH+1
			}
			H = setUpdatingFlags(value: newH, clearCarry: false)
		}
		CY = 0
	}

	func rotateRight() {
		let res = A >> 1
		let shiftedOut = A & 1
		CY = Int(shiftedOut)
		A = res | (shiftedOut << 7)
	}

	func addInmediate(inm: UInt8) {
		A = setUpdatingFlags(value: Int(A)+Int(inm), clearCarry: false)
	}

	func exclusiveOr(reg: UnsafeMutablePointer<UInt8>) {
		if (reg.successor() == &B) { //Swift enforces exclusive access. This can be disabled or "dirty-fixed" this way.
			reg.pointee = setUpdatingFlags(value: Int(reg.pointee ^ reg.pointee), clearCarry: true)
		} else {
			A = setUpdatingFlags(value: Int(A ^ reg.pointee), clearCarry: true)
		}
	}

	func orRegister(reg: UnsafeMutablePointer<UInt8>) {
		A = setUpdatingFlags(value: Int(A | reg.pointee), clearCarry: true)
	}

	func andRegister(reg: UnsafeMutablePointer<UInt8>) {
		if (reg.successor() == &B) {
			reg.pointee = setUpdatingFlags(value: Int(reg.pointee & reg.pointee), clearCarry: true)
		} else {
			A = setUpdatingFlags(value: Int(A & reg.pointee), clearCarry: true)
		}
	}

	func decimalAdjust(reg: UnsafeMutablePointer<UInt8>) {
		if (AC == 1 || (reg.pointee & 0x0F) > 9) {
			reg.pointee += 6
		}
		var msb = reg.pointee & 0xF0
		msb = msb >> 4
		if (CY == 1 || msb > 9) {
			msb = msb + 6
		}
		reg.pointee = setUpdatingFlags(value: Int((msb << 4) & reg.pointee), clearCarry: false)
	}

	//MARK: BRANCH functions
	func jumpInmediate(inm: Int) {
		pc = inm
	}

	func jumpNotZero(inm: Int) {
		if (Z == 0) {
			jumpInmediate(inm: inm)
		} else {
			pc += 3
		}
	}

	func returnFromException() {
		let PCL = String(array[SP],radix:16)
		let PCH = String(array[SP+1],radix:16)
		SP += 2
		pc = Int("\(String(PCH).formatByteZeroes)\(String(PCL).formatByteZeroes)",radix:16)!
	}

	func retOnZero() {
		if (Z == 1) {
			returnFromException()
			cycles += 3
		} else {
			cycles += 1
			pc += 1
		}
	}

	func retNoZero() {
		if (Z == 0) {
			returnFromException()
			cycles += 3
		} else {
			cycles += 1
			pc += 1
		}
	}

	func retOnCarry() {
		if (C == 1) {
			returnFromException()
			cycles += 3
		} else {
			cycles += 1
			pc += 1
		}
	}

	func callException(inm: Int) {
		let pc16 = UInt16(pc+3)
		let PCH = UInt8((0xFF00 & pc16) >> 8)
		let PCL = UInt8(0x00FF & pc16)
		array[SP-1] = PCH
		array[SP-2] = PCL
		SP -= 2
		jumpInmediate(inm: inm)
	}

	func callInterrupt(inm: Int) {
		let pc16 = UInt16(pc)
		let PCH = UInt8((0xFF00 & pc16) >> 8)
		let PCL = UInt8(0x00FF & pc16)
		array[SP-1] = PCH
		array[SP-2] = PCL
		SP -= 2
		jumpInmediate(inm: inm)
	}

	func jumpOnZero(inm: Int) {
		if (Z == 1) {
			jumpInmediate(inm: inm)
		} else {
			pc += 3
		}
	}

	func jumpNoCarry(inm: Int) {
		if (CY == 0) {
			jumpInmediate(inm: inm)
		} else {
			pc += 3
		}
	}

	func jumpOnCarry(inm: Int) {
		if (CY == 1) {
			jumpInmediate(inm: inm)
		} else {
			pc += 3
		}
	}

	//MARK: DATA TRANSFER functions
	func loadInmediateRegisterPair(reg: UnsafeMutablePointer<UInt8>, byte3: UInt8, byte2: UInt8) {
		reg.pointee = byte3
		reg.advanced(by: 1).pointee = byte2
	}

	func loadAccumulatorIndirect(reg: UnsafeMutablePointer<UInt8>) {
		let rp = Int("\(String(reg.pointee,radix:16).formatByteZeroes)\(String(reg.advanced(by: 1).pointee,radix:16).formatByteZeroes)",radix:16)
		A = array[rp!]
	}

	func storeAccumulatorDirect(addr: Int) {
		array[addr] = A
	}

	func loadAccumulatorDirect(addr: Int) {
		A = array[addr]
	}

	func moveInmediate(reg:UnsafeMutablePointer<UInt8>, inm:UInt8) {
		reg.pointee = inm
	}

	func moveToMemory(reg: UnsafeMutablePointer<UInt8>) {
		array[Int("\(String(H,radix:16).formatByteZeroes)\(String(L,radix:16).formatByteZeroes)",radix:16)!] = reg.pointee
	}

	func moveToMemory(inm: UInt8) {
		array[Int("\(String(H,radix:16).formatByteZeroes)\(String(L,radix:16).formatByteZeroes)",radix:16)!] = inm
	}

	func moveRegister(reg: UnsafePointer<UInt8>, toRegister: UnsafeMutablePointer<UInt8>) {
		toRegister.pointee = reg.pointee
	}

	func exchangeDEHL() {
		let oldH = H
		let oldL = L
		H = D
		L = E
		D = oldH
		E = oldL
	}

	func moveFromMemory(reg: UnsafeMutablePointer<UInt8>) {
		if (reg.successor() == &L) {  //Again, Swift enforces exclusive access. This can be disabled or "dirty-fixed" this way.
			reg.pointee = array[Int("\(String(reg.pointee,radix:16).formatByteZeroes)\(String(L,radix:16).formatByteZeroes)",radix:16)!]
		} else {
			reg.pointee = array[Int("\(String(H,radix:16).formatByteZeroes)\(String(L,radix:16).formatByteZeroes)",radix:16)!]
		}
	}


	//MARK: STACK, I/O, MACHINE CONTROL functions
	func pushOnStack(reg: UnsafeMutablePointer<UInt8>) {
		array[SP-1] = reg.pointee
		array[SP-2] = reg.successor().pointee
		SP = SP-2
	}

	func popOffStack(reg: UnsafeMutablePointer<UInt8>) {
		reg.successor().pointee = array[SP]
		reg.pointee = array[SP+1]
		SP = SP+2
	}

	func pushProcessorStatusWord() {
		array[SP-1] = A
		let psw = Int("\(S)\(Z)0\(AC)0\(P)1\(CY)", radix:2)! //Flags
		let psw8 = UInt8(psw)
		array[SP-2] = psw8
		SP = SP-2
	}

	func popProcessorStatusWord() {
		let psw = array[SP]
		CY = Int(psw & 1)
		P = Int((psw & 4) >> 2)
		AC = Int((psw & 16) >> 4)
		Z = Int((psw & 64) >> 6)
		S = Int((psw & 128) >> 7)
		A = array[SP+1]
		SP += 2
	}

	func exchangeStackTop() {
		let Laux = L
		let Haux = H
		L = array[SP]
		H = array[SP+1]
		array[SP] = Laux
		array[SP+1] = Haux
	}

	func outputTo(port: Int) {
		//Implemented in specific machine.
	}

	func inputIn(port: Int) {
		//Implemented in specific machine.
	}

	func enableInterrupts() {
		IE = 1
	}


	//MARK: - Interaction
	func step() {
		if (pc < array.count) {
			disassemble()
		}
	}

	func run(specifiedCycles: Int) {
		if (!running) {
			running = true
			let wishedCycle = cycles + specifiedCycles
			while (cycles < wishedCycle) {
				step()
			}
			running = false
		}
	}

	func addOutput(res: String) {
		//print(res)
		output += "\(res)\n"
	}

}

