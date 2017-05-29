import Foundation
import AppKit

let streamDeck = StreamDeck.singleton
var daemon = Thread(target: streamDeck, selector:#selector(StreamDeck.initUsb), object: nil)

daemon.start()
RunLoop.current.run()
