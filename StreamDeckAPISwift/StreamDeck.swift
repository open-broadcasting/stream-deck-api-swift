import Foundation
import IOKit.hid

class StreamDeck : NSObject {
	let vendorId = 0x0fd9
	let productId = 0x0060
	let reportSize = 64
	var keyStates = Array(repeating: false, count: 15)
	static let singleton = StreamDeck()
	var device : IOHIDDevice? = nil

	func input(_ inResult: IOReturn, inSender: UnsafeMutableRawPointer, type: IOHIDReportType, reportId: UInt32, report: UnsafeMutablePointer<UInt8>, reportLength: CFIndex) {
		let message = Data(bytes: UnsafePointer<UInt8>(report), count: reportLength)
		if message[0] == 0x01 {
			print("Received button state report")
			for buttonId in 0..<keyStates.count {
				keyStates[buttonId] = (message[buttonId + 1] != 0)
			}
			print("\(keyStates[4].icon) \(keyStates[3].icon) \(keyStates[2].icon) \(keyStates[1].icon) \(keyStates[0].icon)")
			print("\(keyStates[9].icon) \(keyStates[8].icon) \(keyStates[7].icon) \(keyStates[6].icon) \(keyStates[5].icon)")
			print("\(keyStates[14].icon) \(keyStates[13].icon) \(keyStates[12].icon) \(keyStates[11].icon) \(keyStates[10].icon)")
		} else {
			print("Received unknown report: \(message.hexEncodedString())")
		}
	}

	func connected(_ inResult: IOReturn, inSender: UnsafeMutableRawPointer, inIOHIDDeviceRef: IOHIDDevice!) {
		print("StreamDeck connected")
		// It would be better to look up the report size and create a chunk of memory of that size
		let report = UnsafeMutablePointer<UInt8>.allocate(capacity: reportSize)
		device = inIOHIDDeviceRef

		let inputCallback : IOHIDReportCallback = { inContext, inResult, inSender, type, reportId, report, reportLength in
			let this : StreamDeck = unsafeBitCast(inContext, to: StreamDeck.self)
			this.input(inResult, inSender: inSender!, type: type, reportId: reportId, report: report, reportLength: reportLength)
		}
		IOHIDDeviceRegisterInputReportCallback(device!, report, reportSize, inputCallback, unsafeBitCast(self, to: UnsafeMutableRawPointer.self));
	}

	func removed(_ inResult: IOReturn, inSender: UnsafeMutableRawPointer, inIOHIDDeviceRef: IOHIDDevice!) {
		print("StreamDeck removed")
		NotificationCenter.default.post(name: Notification.Name(rawValue: "deviceDisconnected"), object: nil, userInfo: ["class": NSStringFromClass(type(of: self))])
	}


	func initUsb() {
		let deviceMatch = [kIOHIDProductIDKey: productId, kIOHIDVendorIDKey: vendorId]
		let managerRef = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))

		IOHIDManagerSetDeviceMatching(managerRef, deviceMatch as CFDictionary?)
		IOHIDManagerScheduleWithRunLoop(managerRef, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue);
		IOHIDManagerOpen(managerRef, 0);

		let matchingCallback : IOHIDDeviceCallback = { inContext, inResult, inSender, inIOHIDDeviceRef in
			let this : StreamDeck = unsafeBitCast(inContext, to: StreamDeck.self)
			this.connected(inResult, inSender: inSender!, inIOHIDDeviceRef: inIOHIDDeviceRef)
		}

		let removalCallback : IOHIDDeviceCallback = { inContext, inResult, inSender, inIOHIDDeviceRef in
			let this : StreamDeck = unsafeBitCast(inContext, to: StreamDeck.self)
			this.removed(inResult, inSender: inSender!, inIOHIDDeviceRef: inIOHIDDeviceRef)
		}

		IOHIDManagerRegisterDeviceMatchingCallback(managerRef, matchingCallback, unsafeBitCast(self, to: UnsafeMutableRawPointer.self))
		IOHIDManagerRegisterDeviceRemovalCallback(managerRef, removalCallback, unsafeBitCast(self, to: UnsafeMutableRawPointer.self))

		RunLoop.current.run();
	}

}
