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

	var pc = 0
	var SP = 0
	var A: UInt8 = 0
	var B: UInt8 = 0
	var C: UInt8 = 0
	var D: UInt8 = 0
	var E: UInt8 = 0
	var H: UInt8 = 0
	var L: UInt8 = 0

	var IE = 0
	var Z = 0
	var S = 0
	var P = 0
	var CY = 0
	var AC = 0

	var array = [UInt8]()
	var output = ""
	var cycles = 0


	init(filePath: String) {
		let location = NSString(string:filePath).expandingTildeInPath
		print(location)
		let fileData = NSData(contentsOfFile: location)!
		//Bytes contained in the file (length/bytesize)
		let count = fileData.length / MemoryLayout<UInt8>.size

		array = [UInt8](repeating: 0, count: count+16000) //ROM+RAM
		fileData.getBytes(&array, length:count * MemoryLayout<UInt8>.size)
	}


	//MARK: REPL
	func disassemble() {
		let hexPC = String(pc, radix:16)
		var str = hexPC.formatPC

		let byte2 = String(array[pc+1],radix:16).formatByteZeroes
		let byte3 = String(array[pc+2],radix:16).formatByteZeroes

		switch (array[pc]) {

			case 0: str += "NOP"
				cycles += 1
				pc += 1
				break
			// ALU
			case 0x05: str += "DCR B" //Decrement register B
				decrementRegister(reg: &B)
				cycles += 1
				pc += 1
				break
			case 0x13: str += "INX D" //Increment D & E register pair
				incrementRegisterPair(reg: &D)
				cycles += 1
				pc += 1
				break
			case 0x24: str += "INR H" //Increment register
				incrementRegister(reg: &H)
				cycles += 1
				pc += 1
				break
			case 0x23: str += "INX H" //Increment H & L register pair
				incrementRegisterPair(reg: &H)
				cycles += 1
				pc += 1
				break
			case 0x29: str += "DAD H" //Add H & L to H & L
				addRegisterPairToHL(reg: &H)
				cycles += 3
				pc += 1
			case 0x80: str += "ADD B"
				addRegister(reg: &B)
				cycles += 1
				pc += 1
				break
			case 0xFE: str += "CPI, #$\(byte2)" // Compare inmediate to (A)ccumulator
				compareInmediate(inm: UInt8(byte2)!)
				cycles += 2
				pc += 2
				break
			case 0xE6: str += "ANI"
				andInmediate(inm: UInt8(byte2,radix:16)!)
				cycles += 2
				pc += 2

			// BRANCH
			case 195: str += "JMP $\(String(array[pc+2],radix:16))\(String(array[pc+1],radix:16))"
				jumpInmediate(inm: Int(byte3+byte2,radix:16)!)
				cycles += 3
				break
			case 0xC2: str += "JNZ $\(byte3)\(byte2)"
				jumpNotZero(inm: Int(byte3+byte2,radix:16)!)
				cycles += 3
				break
			case 0xC9: str += "RET"
				returnFromException()
				cycles += 3
				break
			case 0xCD: str += "CALL $\(byte3)\(byte2)" //Call unconditional addr
				callException(inm: Int(byte3+byte2,radix:16)!)
				cycles += 5
				break

			// DATA TRANSFER
			case 0x01: str += "LXI B, #$\(byte3)\(byte2)" //Load inmediate register pair B & C
				loadInmediateRegisterPair(reg: &B, byte3: UInt8(byte3,radix:16)!, byte2: UInt8(byte3,radix:16)!)
				cycles += 3
				pc += 3
				break
			case 0x06: str += "MVI B, #$\(byte2)" //Move inmediate
				moveInmediate(reg: &B, inm: UInt8(byte2,radix:16)!)
				cycles += 2
				pc += 2
				break
			case 0x0A: str += "LDAX B" //Load (A)ccumulator indirect
				loadAccumulatorIndirect(reg: &B)
				cycles += 2
				pc += 1
				break
			case 0x0E: str += "MVI C, #$\(byte2)" //Move inmediate
				moveInmediate(reg: &C, inm: UInt8(byte2,radix:16)!)
				cycles += 2
				pc += 2
				break
			case 0x11: str += "LXI D, #$\(byte3)\(byte2)" //Load inmediate register pair D & E
				loadInmediateRegisterPair(reg: &D, byte3: UInt8(byte3,radix:16)!, byte2: UInt8(byte2,radix:16)!)
				cycles += 3
				pc += 3
				break
			case 0x1A: str += "LDAX D" //Load (A)ccumulator indirect
				loadAccumulatorIndirect(reg: &D)
				cycles += 2
				pc += 1
				break
			case 0x21: str += "LXI H, #$\(byte3)\(byte2)" //Load inmediate register pair H & L
				loadInmediateRegisterPair(reg: &H, byte3: UInt8(byte3,radix:16)!, byte2: UInt8(byte2,radix:16)!)
				cycles += 3
				pc += 3
				break
			case 0x26: str += "MVI H, #$\(byte2)" //Move inmediate
				moveInmediate(reg: &H, inm: UInt8(byte2,radix:16)!)
				cycles += 2
				pc += 2
				break
			case 0x31: str += "LXI SP, #$\(byte3)\(byte2)" //Load inmediate stack pointer
				SP = Int("\(byte3)\(byte2)",radix:16)!
				cycles += 3
				pc += 3
				break
			case 0x36: str += "MVI M, #$\(byte2)" //Move to memory inmediate
				moveToMemoryInmediate(inm: UInt8(byte2,radix:16)!)
				cycles += 3
				pc += 2
				break
			case 0x32: str += "STA" //Store A(ccumulator) direct
				storeAccumulatorDirect(addr: Int("\(byte3)\(byte2)", radix:16)!)
				cycles += 4
				pc += 3
				break
			case 0x3A: str += "LDA $\(byte3)\(byte2)" //Load (A)ccumulator direct
				loadAccumulatorDirect(addr: Int("\(byte3)\(byte2)", radix:16)!)
				cycles += 4
				pc += 2
				break
			case 0x6F: str += "MOV A, L" //Move register to register (r1) <- (r2)
				moveRegister(reg: &L, toRegister: &A)
				cycles += 1
				pc += 1
				break
			case 0x77: str += "MOV M, A" //Move register to memory
				moveRegisterToMemory(reg: &A)
				cycles += 2
				pc += 1
				break
			case 0x7C: str += "MOV A, H" //Move register to register (r1) <- (r2)
				moveRegister(reg: &H, toRegister: &A)
				cycles += 1
				pc += 1
				break
			// STACK
			case 0xD5: str += "PUSH D" //Push register pair D & E on stack
				pushOnStack(reg: &D)
				cycles += 3
				pc += 1
				break
			case 0xE5: str += "PUSH H"
				pushOnStack(reg: &H)
				cycles += 3
				pc += 1
				break
			case 0xf5: str += "PUSH PSW ***No implementada***"
				cycles += 3
				pc += 1
				break
			default: str += "\(String(array[pc],radix:16)) ***No implementada***"
				pc += 1
		}
		addOutput(res: str)

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
		if (value8 == 0) {
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
			reg.pointee = setUpdatingFlags(value: newH+1, clearCarry: false)
		} else {
			newH = newH + Int(H)
			if (CY == 1) {
				newH = newH+1
			}
			H = setUpdatingFlags(value: newH+1, clearCarry: false)
		}
		CY = 0
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
		pc = Int("\(PCH)\(PCL)",radix:16)!
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

	//MARK: DATA TRANSFER functions
	func loadInmediateRegisterPair(reg: UnsafeMutablePointer<UInt8>, byte3: UInt8, byte2: UInt8) {
		reg.pointee = byte3
		reg.advanced(by: 1).pointee = byte2
	}

	func loadAccumulatorIndirect(reg: UnsafeMutablePointer<UInt8>) {
		let rp = Int("\(String(reg.pointee,radix:16))\(String(reg.advanced(by: 1).pointee,radix:16))",radix:16)
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

	func moveRegisterToMemory(reg: UnsafeMutablePointer<UInt8>) {
		array[Int("\(String(H,radix:16))\(String(L,radix:16))",radix:16)!] = reg.pointee
	}

	func moveToMemoryInmediate(inm: UInt8) {
		array[Int("\(String(H,radix:16))\(String(L,radix:16))",radix:16)!] = inm
	}

	func moveRegister(reg: UnsafePointer<UInt8>, toRegister: UnsafeMutablePointer<UInt8>) {
		toRegister.pointee = reg.pointee
	}

	//TODO: STACK functions
	func pushOnStack(reg: UnsafeMutablePointer<UInt8>) {
		array[SP-1] = reg.pointee
		array[SP-2] = reg.successor().pointee
		SP = SP-2
	}


	//MARK: - Interaction
	func step() {
		if (pc < array.count) {
			disassemble()
		}
	}

	func addOutput(res: String) {
		print(res)
		output += "\(res)\n"
	}

}
