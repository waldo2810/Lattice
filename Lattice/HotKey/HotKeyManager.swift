import Carbon.HIToolbox

final class HotKeyManager {
    private var currentId: UInt32 = 1
    private var registrations: [UInt32: (ref: EventHotKeyRef, hotKey: HotKey)] = [:]
    private var actions: [UInt32: () -> Void] = [:]
    private var eventHandlerRef: EventHandlerRef!
    
    func register(hotKey: HotKey, action: @escaping () -> Void) {
        let modifiers = hotKey.carbonModifiers.reduce(0) { $0 | $1.value }
        var hotKeyRef: EventHotKeyRef?
        let id = getHotKeyId()
        
        let result = RegisterEventHotKey(
            UInt32(hotKey.carbonKey.value),
            UInt32(modifiers),
            EventHotKeyID(signature: getSignature(), id: id),
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
        
        guard result == noErr, let ref = hotKeyRef else {
            Log.error("Failed to register hotkey: \(result)")
            return
        }
        
        registrations[id] = (ref, hotKey)
        actions[id] = action        
    }
    
    /// Listens for hot key presses. Extracts the HotKeyID from it and calls the action it was registered with
    func listen() {
        guard eventHandlerRef == nil else {
            return
        }
        
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let unsafeSelfPointer = Unmanaged.passUnretained(self).toOpaque()
        
        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, eventRef, unsafeMutableRawPointer in
                guard let eventRef, let unsafeMutableRawPointer else {
                    return noErr
                }
                                
                let unmanagedHotKeyManager = Unmanaged<HotKeyManager>.fromOpaque(unsafeMutableRawPointer)
                let hotKeyManager = unmanagedHotKeyManager.takeUnretainedValue()
                
                var hotKeyId = EventHotKeyID()
                
                let result = GetEventParameter(
                    eventRef,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyId
                )
                
                guard result == noErr else {
                    Log.error("Failed to get hotKey id parameter from event: \(eventRef.debugDescription)")
                    return noErr
                }
                                
                guard let action = hotKeyManager.actions[hotKeyId.id] else {
                    Log.error("Failed to set event handler for hotKey id: \(hotKeyId.id)")
                    return noErr
                }
                
                action()
                
                return noErr
            },
            1,
            &eventType,
            unsafeSelfPointer,
            &eventHandlerRef
        )
    }
    
    private func getSignature() -> OSType {
        return OSType(4321)
    }
    
    private func getHotKeyId() -> UInt32 {
        currentId += 1
        return currentId
    }
}
