-- PZFB Input System v2.0
-- Comprehensive input capture for framebuffer applications.
-- Derives from ISPanelJoypad for full keyboard, mouse, and gamepad support.
--
-- Usage:
--   local panel = PZFBInputPanel:new(x, y, w, h, { mode = PZFBInput.MODE_EXCLUSIVE })
--   panel:initialise()
--   panel:addToUIManager()
--   panel:grabInput()
--
--   function panel:onPZFBKeyDown(key) ... end
--   function panel:onPZFBKeyUp(key) ... end
--   function panel:onPZFBKeyRepeat(key) ... end
--   function panel:onPZFBMouseDown(x, y, btn) ... end
--   function panel:onPZFBMouseUp(x, y, btn) ... end
--   function panel:onPZFBMouseMove(x, y, dx, dy) ... end
--   function panel:onPZFBMouseWheel(delta) ... end
--   function panel:onPZFBGamepadDown(slot, button) ... end
--   function panel:onPZFBGamepadUp(slot, button) ... end
--   function panel:onPZFBCaptureToggle(active) ... end

require "ISUI/ISPanelJoypad"
require "ISUI/ISPanel"

-- ============================================================================
-- Module Constants
-- ============================================================================

PZFBInput = PZFBInput or {}

PZFBInput.MODE_EXCLUSIVE = 1   -- Consume ALL keys, block game entirely
PZFBInput.MODE_SELECTIVE = 2   -- Consume only registered keys
PZFBInput.MODE_PASSIVE   = 3   -- Read everything, consume nothing
PZFBInput.MODE_FOCUS     = 4   -- Exclusive when mouse over panel, passive otherwise

-- ============================================================================
-- PZFBInputPanel Class
-- ============================================================================

PZFBInputPanel = ISPanelJoypad:derive("PZFBInputPanel")

-- ============================================================================
-- Constructor
-- ============================================================================

function PZFBInputPanel:new(x, y, width, height, options)
    local o = ISPanelJoypad:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self

    options = options or {}

    -- Configuration
    o._mode               = options.mode or PZFBInput.MODE_EXCLUSIVE
    o._captureToggleKey   = options.captureToggleKey or nil
    o._escapeCloses       = options.escapeCloses ~= false
    o._escapeReleasesCapture = options.escapeReleasesCapture ~= false
    o._playerNum          = options.playerNum or 0
    o._forceCursorVisible = options.forceCursorVisible ~= false
    o._autoGrab           = options.autoGrab or false

    -- Capture state
    o._capturing     = false
    o._captureActive = false   -- toggle key state
    o._focusMouseWasOver = false  -- edge detection for FOCUS mode binding suppression

    -- Keyboard state
    o._keysDown = {}

    -- Mouse state
    o._mouseButtons = {}

    -- Selective capture
    o._capturedKeys     = {}
    o._capturedBindings = {}
    o._savedBindings    = {}   -- saved game bindings for restore { name = {key,altCode,shift,ctrl,alt} }

    -- Action mapping
    o._actions = {}

    -- Input slots
    o._slots = {
        [1] = { device = "keyboard", controllerId = nil, axes = {}, triggers = {}, buttons = {}, dpad = {} },
    }
    o._autoAssignSlots = {}

    -- Key proxy (invisible top-level element for key forwarding when we're a child)
    o._keyProxy = nil

    -- Event listener references (for cleanup)
    o._onPlayerDeathFn  = nil
    o._onMainMenuEnterFn = nil

    return o
end

-- ============================================================================
-- Initialization
-- ============================================================================

function PZFBInputPanel:createChildren()
    ISPanelJoypad.createChildren(self)
    self:setWantKeyEvents(true)
    self:setWantExtraMouseEvents(true)

    -- Register safety event listeners
    self._onPlayerDeathFn = function(playerObj)
        if playerObj and playerObj:getPlayerNum() == self._playerNum then
            self:_safeRelease()
        end
    end
    self._onMainMenuEnterFn = function()
        self:_safeRelease()
    end
    Events.OnPlayerDeath.Add(self._onPlayerDeathFn)
    Events.OnMainMenuEnter.Add(self._onMainMenuEnterFn)

    if self._autoGrab then
        self:grabInput()
    end
end

-- ============================================================================
-- Capture Control (Public API)
-- ============================================================================

function PZFBInputPanel:grabInput()
    self._capturing = true
    if self._forceCursorVisible then
        self:setForceCursorVisible(true)
    end
    -- If we're a child element, UIManager won't dispatch key events to us.
    -- Create an invisible proxy in UIManager that forwards key events.
    if self.parent and not self._keyProxy then
        self:_createKeyProxy()
    end
    -- Suppress game bindings so isKeyDown(bindingName) returns false
    self:_suppressBindingsForMode()
end

function PZFBInputPanel:releaseInput()
    self:_safeRelease()
end

function PZFBInputPanel:isCapturing()
    return self._capturing
end

function PZFBInputPanel:setMode(mode)
    local oldMode = self._mode
    self._mode = mode
    if self._capturing and oldMode ~= mode then
        self:_restoreAllBindings()
        self:_suppressBindingsForMode()
    end
end

function PZFBInputPanel:getMode()
    return self._mode
end

-- ============================================================================
-- Safety Cleanup (Internal)
-- ============================================================================

function PZFBInputPanel:_safeRelease()
    -- Destroy key proxy FIRST (while _capturing is still true, so proxy's
    -- isKeyConsumed closure returns correct state during removal frame)
    self:_destroyKeyProxy()
    -- Restore all suppressed game bindings
    self:_restoreAllBindings()

    local wasActive = self._captureActive

    self._capturing = false
    self._captureActive = false
    self._focusMouseWasOver = false

    -- Clear key state to prevent phantom stuck keys
    self._keysDown = {}
    self._mouseButtons = {}

    -- Release mouse capture
    if self.javaObject then
        self:setCapture(false)
        self:setForceCursorVisible(false)
    end

    -- Release joypad focus only if we still own it
    local joypadData = JoypadState.players[self._playerNum + 1]
    if joypadData and joypadData.focus == self then
        setJoypadFocus(self._playerNum, nil)
    end

    -- Notify consumer if toggle was active
    if wasActive and self.onPZFBCaptureToggle then
        self:onPZFBCaptureToggle(false)
    end
end

function PZFBInputPanel:_removeEventListeners()
    self:_destroyKeyProxy()
    if self._onPlayerDeathFn then
        Events.OnPlayerDeath.Remove(self._onPlayerDeathFn)
        self._onPlayerDeathFn = nil
    end
    if self._onMainMenuEnterFn then
        Events.OnMainMenuEnter.Remove(self._onMainMenuEnterFn)
        self._onMainMenuEnterFn = nil
    end
end

-- ============================================================================
-- Key Proxy (for child elements that can't receive key events directly)
-- UIManager.onKeyPress only dispatches to top-level elements. When we're a
-- child of another window, this invisible 1x1 proxy sits in UIManager and
-- forwards key events to us via closures.
-- ============================================================================

function PZFBInputPanel:_createKeyProxy()
    local owner = self
    local proxy = ISPanel:new(0, 0, 1, 1)
    proxy.background = false
    proxy:initialise()
    proxy:instantiate()
    proxy:setVisible(true)
    proxy:setWantKeyEvents(true)

    -- Closures capture 'owner' (the real PZFBInputPanel instance).
    -- Java calls tryGetTableValue("onKeyPress") on proxy's table, finds these,
    -- invokes with (proxyTable, key). We ignore proxyTable and delegate to owner.
    proxy.onKeyPress = function(_, key) owner:onKeyPress(key) end
    proxy.onKeyRelease = function(_, key) owner:onKeyRelease(key) end
    proxy.onKeyRepeat = function(_, key) owner:onKeyRepeat(key) end
    proxy.isKeyConsumed = function(_, key) return owner:isKeyConsumed(key) end

    proxy:addToUIManager()
    self._keyProxy = proxy
end

function PZFBInputPanel:_destroyKeyProxy()
    if self._keyProxy then
        self._keyProxy:removeFromUIManager()
        self._keyProxy = nil
    end
end

-- ============================================================================
-- Binding Suppression (block game actions for captured keys)
-- Game systems poll GameKeyboard.isKeyDown(bindingName) which resolves to raw
-- key state. We temporarily rebind captured actions to KEY_NONE so the game
-- sees them as unbound. Saved bindings are restored on release.
-- ============================================================================

function PZFBInputPanel:_findBindingInMainOptions(bindingName)
    if MainOptions and MainOptions.keys then
        for _, bind in ipairs(MainOptions.keys) do
            if bind.value == bindingName then
                return bind
            end
        end
    end
    return nil
end

function PZFBInputPanel:_suppressBinding(bindingName)
    if self._savedBindings[bindingName] then return end

    local entry = self:_findBindingInMainOptions(bindingName)
    if entry then
        self._savedBindings[bindingName] = {
            key = entry.key or 0,
            altCode = entry.altCode or 0,
            shift = entry.shift or false,
            ctrl = entry.ctrl or false,
            alt = entry.alt or false,
        }
    else
        self._savedBindings[bindingName] = {
            key = getCore():getKey(bindingName),
            altCode = getCore():getAltKey(bindingName),
            shift = false, ctrl = false, alt = false,
        }
    end

    getCore():addKeyBinding(bindingName, 0, 0, false, false, false)
end

function PZFBInputPanel:_restoreAllBindings()
    for name, saved in pairs(self._savedBindings) do
        getCore():addKeyBinding(name, saved.key, saved.altCode, saved.shift, saved.ctrl, saved.alt)
    end
    self._savedBindings = {}
end

function PZFBInputPanel:_suppressBindingsForKey(keyCode)
    if MainOptions and MainOptions.keys then
        for _, bind in ipairs(MainOptions.keys) do
            if bind.value and not bind.value:match("^%[") then
                if bind.key == keyCode or bind.altCode == keyCode then
                    self:_suppressBinding(bind.value)
                end
            end
        end
    else
        for _, bind in ipairs(keyBinding) do
            if bind.value and not bind.value:match("^%[") then
                local k = getCore():getKey(bind.value)
                local a = getCore():getAltKey(bind.value)
                if k == keyCode or a == keyCode then
                    self:_suppressBinding(bind.value)
                end
            end
        end
    end
end

function PZFBInputPanel:_suppressAllBindings()
    if MainOptions and MainOptions.keys then
        for _, bind in ipairs(MainOptions.keys) do
            if bind.value and not bind.value:match("^%[") then
                self:_suppressBinding(bind.value)
            end
        end
    else
        for _, bind in ipairs(keyBinding) do
            if bind.value and not bind.value:match("^%[") then
                self:_suppressBinding(bind.value)
            end
        end
    end
end

function PZFBInputPanel:_suppressBindingsForMode()
    if self._mode == PZFBInput.MODE_EXCLUSIVE then
        self:_suppressAllBindings()
    elseif self._mode == PZFBInput.MODE_SELECTIVE then
        for keyCode, _ in pairs(self._capturedKeys) do
            self:_suppressBindingsForKey(keyCode)
        end
        for name, _ in pairs(self._capturedBindings) do
            self:_suppressBinding(name)
        end
    elseif self._mode == PZFBInput.MODE_FOCUS then
        -- FOCUS mode: suppress only when mouse is over the panel.
        -- Seed initial state here; prerender handles ongoing transitions.
        self._focusMouseWasOver = self:isMouseOver()
        if self._focusMouseWasOver then
            self:_suppressAllBindings()
        end
    end
end

-- ============================================================================
-- Lifecycle Overrides (guaranteed cleanup)
-- ============================================================================

function PZFBInputPanel:close()
    self:_safeRelease()
    self:_removeEventListeners()
    ISPanelJoypad.close(self)
end

function PZFBInputPanel:removeFromUIManager()
    self:_safeRelease()
    self:_removeEventListeners()
    ISPanelJoypad.removeFromUIManager(self)
end

function PZFBInputPanel:setVisible(visible)
    if not visible then
        self:_safeRelease()
    end
    ISPanelJoypad.setVisible(self, visible)
end

-- ============================================================================
-- Key Consumption Logic (core of the system)
-- ============================================================================

function PZFBInputPanel:_shouldConsume(key)
    if not self._capturing then return false end

    -- Toggle key is ALWAYS consumed when set
    if self._captureToggleKey and key == self._captureToggleKey then
        return true
    end

    -- If toggle capture is active, behave as exclusive
    if self._captureActive then
        return true
    end

    local mode = self._mode
    if mode == PZFBInput.MODE_EXCLUSIVE then
        return true
    elseif mode == PZFBInput.MODE_SELECTIVE then
        return self:_isKeyInCaptureList(key)
    elseif mode == PZFBInput.MODE_PASSIVE then
        return false
    elseif mode == PZFBInput.MODE_FOCUS then
        return self:isMouseOver()
    end
    return false
end

function PZFBInputPanel:_isKeyInCaptureList(key)
    if self._capturedKeys[key] then return true end
    for name, _ in pairs(self._capturedBindings) do
        if getCore():isKey(name, key) then return true end
    end
    return false
end

--- Called by PZ Java UI system. Return true to prevent game from processing the key.
function PZFBInputPanel:isKeyConsumed(key)
    return self:_shouldConsume(key)
end

-- ============================================================================
-- Keyboard Event Handlers
-- ============================================================================

--- Called by PZ on first frame of key press.
function PZFBInputPanel:onKeyPress(key)
    if not self._capturing then return end
    -- FOCUS mode: only process when mouse is over the panel (or toggle is active)
    if self._mode == PZFBInput.MODE_FOCUS and not self._captureActive and not self:isMouseOver() then return end

    -- Handle capture toggle key (intercept before anything else)
    if self._captureToggleKey and key == self._captureToggleKey then
        self:_toggleCapture()
        GameKeyboard.eatKeyPress(key)
        return
    end

    -- Handle escape
    if key == Keyboard.KEY_ESCAPE then
        -- If toggle capture is active, ESC releases it (safety valve)
        if self._captureActive and self._escapeReleasesCapture then
            self:_toggleCapture()
            GameKeyboard.eatKeyPress(key)
            return
        end
        -- If escapeCloses, close the panel
        if self._escapeCloses then
            GameKeyboard.eatKeyPress(key)
            self:close()
            return
        end
        -- Otherwise fall through — treat ESC as a regular key
    end

    -- Track key state
    self._keysDown[key] = true

    -- Fire consumer callback
    if self.onPZFBKeyDown then
        self:onPZFBKeyDown(key)
    end
end

--- Called by PZ every frame while a key is held.
function PZFBInputPanel:onKeyRepeat(key)
    if not self._capturing then return end
    if self._mode == PZFBInput.MODE_FOCUS and not self._captureActive and not self:isMouseOver() then return end

    -- Don't repeat the toggle key or escape
    if self._captureToggleKey and key == self._captureToggleKey then return end

    -- Ensure key is tracked (handles mouse entering panel while key is already held)
    if not self._keysDown[key] then
        self._keysDown[key] = true
        -- Fire the initial down callback since onKeyPress was blocked by FOCUS guard
        if self.onPZFBKeyDown then
            self:onPZFBKeyDown(key)
        end
    end

    if self.onPZFBKeyRepeat then
        self:onPZFBKeyRepeat(key)
    end
end

--- Called by PZ on key release.
function PZFBInputPanel:onKeyRelease(key)
    if not self._capturing then return end

    -- Toggle key release — ignore
    if self._captureToggleKey and key == self._captureToggleKey then return end

    -- Always clear tracked key state, even if FOCUS guard would skip processing.
    -- Prevents stuck keys when mouse leaves panel while a key is held.
    local wasTracked = self._keysDown[key]
    self._keysDown[key] = nil

    -- In FOCUS mode, only fire callbacks when mouse is over the panel
    if self._mode == PZFBInput.MODE_FOCUS and not self._captureActive and not self:isMouseOver() then return end

    -- Fire consumer callback only if we were tracking this key
    if wasTracked and self.onPZFBKeyUp then
        self:onPZFBKeyUp(key)
    end
end

-- ============================================================================
-- Capture Toggle
-- ============================================================================

function PZFBInputPanel:_toggleCapture()
    self._captureActive = not self._captureActive

    if self._captureActive then
        -- Entering exclusive capture
        if self.javaObject then
            self:setCapture(true)
            self:setForceCursorVisible(true)
        end
        -- Claim joypad focus if a controller is assigned to any slot
        for _, slot in pairs(self._slots) do
            if slot.device == "controller" and slot.controllerId then
                setJoypadFocus(self._playerNum, self)
                break
            end
        end
        -- Toggle override is always exclusive — suppress all bindings
        self:_restoreAllBindings()
        self:_suppressAllBindings()
    else
        -- Releasing toggle — revert to base mode suppression
        self._keysDown = {}
        self._mouseButtons = {}
        if self.javaObject then
            self:setCapture(false)
            if not self._forceCursorVisible then
                self:setForceCursorVisible(false)
            end
        end
        -- Release joypad focus only if we still own it
        local joypadData = JoypadState.players[self._playerNum + 1]
        if joypadData and joypadData.focus == self then
            setJoypadFocus(self._playerNum, nil)
        end
        -- Restore all then re-suppress per base mode
        self:_restoreAllBindings()
        self:_suppressBindingsForMode()
    end

    if self.onPZFBCaptureToggle then
        self:onPZFBCaptureToggle(self._captureActive)
    end
end

-- ============================================================================
-- Mouse Event Handlers
-- ============================================================================

function PZFBInputPanel:onMouseDown(x, y)
    if not self._capturing then
        return ISPanelJoypad.onMouseDown(self, x, y)
    end
    self._mouseButtons[0] = true
    if self.onPZFBMouseDown then
        self:onPZFBMouseDown(x, y, 0)
    end
    self:bringToTop()
    return true
end

function PZFBInputPanel:onMouseUp(x, y)
    if not self._capturing then
        return ISPanelJoypad.onMouseUp(self, x, y)
    end
    self._mouseButtons[0] = nil
    if self.onPZFBMouseUp then
        self:onPZFBMouseUp(x, y, 0)
    end
end

function PZFBInputPanel:onRightMouseDown(x, y)
    if not self._capturing then return end
    self._mouseButtons[1] = true
    if self.onPZFBMouseDown then
        self:onPZFBMouseDown(x, y, 1)
    end
    return true
end

function PZFBInputPanel:onRightMouseUp(x, y)
    if not self._capturing then return end
    self._mouseButtons[1] = nil
    if self.onPZFBMouseUp then
        self:onPZFBMouseUp(x, y, 1)
    end
end

function PZFBInputPanel:onRightMouseUpOutside(x, y)
    if not self._capturing then return end
    self._mouseButtons[1] = nil
    if self.onPZFBMouseUp then
        self:onPZFBMouseUp(x, y, 1)
    end
end

function PZFBInputPanel:onRightMouseDownOutside(x, y)
    -- When captured via toggle, don't let outside right-clicks escape
end

function PZFBInputPanel:onMouseDownOutside(x, y)
    if self._captureActive then
        -- While toggle-captured, outside clicks stay captured
        return
    end
    -- In FOCUS mode, outside click means we're not focused
end

function PZFBInputPanel:onMouseUpOutside(x, y)
    if not self._capturing then
        return ISPanelJoypad.onMouseUpOutside(self, x, y)
    end
    self._mouseButtons[0] = nil
    if self.onPZFBMouseUp then
        self:onPZFBMouseUp(x, y, 0)
    end
end

function PZFBInputPanel:onMouseMove(dx, dy)
    if not self._capturing then
        return ISPanelJoypad.onMouseMove(self, dx, dy)
    end
    if self.onPZFBMouseMove then
        self:onPZFBMouseMove(self:getMouseX(), self:getMouseY(), dx, dy)
    end
end

function PZFBInputPanel:onMouseMoveOutside(dx, dy)
    if not self._capturing then
        return ISPanelJoypad.onMouseMoveOutside(self, dx, dy)
    end
    -- When captured (via toggle or exclusive), still track mouse
    if self._captureActive or self._mode == PZFBInput.MODE_EXCLUSIVE then
        if self.onPZFBMouseMove then
            self:onPZFBMouseMove(self:getMouseX(), self:getMouseY(), dx, dy)
        end
    end
end

function PZFBInputPanel:onMouseWheel(del)
    if not self._capturing then return false end
    if self.onPZFBMouseWheel then
        self:onPZFBMouseWheel(del)
    end
    -- Wheel is a mouse event — consume based on mode, not key capture list
    if self._captureActive then return true end
    if self._mode == PZFBInput.MODE_EXCLUSIVE then return true end
    if self._mode == PZFBInput.MODE_PASSIVE then return false end
    -- SELECTIVE and FOCUS: consume when mouse is over panel
    return self:isMouseOver()
end

--- Extra mouse buttons (middle click, etc.) — requires setWantExtraMouseEvents(true).
function PZFBInputPanel:onMouseButtonDown(btn)
    if not self._capturing then return end
    self._mouseButtons[btn] = true
    if self.onPZFBMouseDown then
        self:onPZFBMouseDown(self:getMouseX(), self:getMouseY(), btn)
    end
end

--- Extra mouse button release (PZ only fires this when mouse is outside the panel).
function PZFBInputPanel:onMouseButtonUpOutside(btn)
    if not self._capturing then return end
    self._mouseButtons[btn] = nil
    if self.onPZFBMouseUp then
        self:onPZFBMouseUp(self:getMouseX(), self:getMouseY(), btn)
    end
end

-- ============================================================================
-- Gamepad Event Handlers (PZ-routed via joypad focus)
-- ============================================================================

-- PZ-routed joypad handlers: used ONLY for auto-assign detection.
-- All button/D-pad callbacks are fired from raw polling in _pollSingleGamepad
-- to avoid duplicate events when both paths are active.

function PZFBInputPanel:onJoypadDown(button, joypadData)
    if not self._capturing then return end

    -- Auto-assign: if any slot is waiting for a controller, assign this one
    for slotNum, _ in pairs(self._autoAssignSlots) do
        local slot = self._slots[slotNum]
        if slot and not slot.controllerId then
            slot.device = "controller"
            slot.controllerId = joypadData.id
            slot.axes = {}
            slot.triggers = {}
            slot.buttons = {}
            slot.dpad = {}
            self._autoAssignSlots[slotNum] = nil
            if self.onPZFBSlotAssigned then
                self:onPZFBSlotAssigned(slotNum, joypadData.id)
            end
        end
    end
end

function PZFBInputPanel:onJoypadDirUp(joypadData)
end

function PZFBInputPanel:onJoypadDirDown(joypadData)
end

function PZFBInputPanel:onJoypadDirLeft(joypadData)
end

function PZFBInputPanel:onJoypadDirRight(joypadData)
end

function PZFBInputPanel:onJoypadButtonReleased(button, joypadData)
end

function PZFBInputPanel:_slotForController(controllerId)
    for slotNum, slot in pairs(self._slots) do
        if slot.device == "controller" and slot.controllerId == controllerId then
            return slotNum
        end
    end
    return 1  -- fallback to slot 1
end

-- ============================================================================
-- Gamepad Raw Polling (in prerender, frame-accurate)
-- ============================================================================

function PZFBInputPanel:prerender()
    ISPanelJoypad.prerender(self)
    if self._capturing then
        -- Clean up sticky extra mouse buttons (PZ has no onMouseButtonUp for inside)
        -- Mouse.isButtonDown reads raw HW state — if button is physically released, clear it
        for btn, _ in pairs(self._mouseButtons) do
            if btn >= 2 and not Mouse.isButtonDown(btn) then
                self._mouseButtons[btn] = nil
            end
        end
        -- FOCUS mode: toggle binding suppression on mouse enter/leave
        if self._mode == PZFBInput.MODE_FOCUS and not self._captureActive then
            local mouseOver = self:isMouseOver()
            if mouseOver and not self._focusMouseWasOver then
                self:_suppressAllBindings()
            elseif not mouseOver and self._focusMouseWasOver then
                self:_restoreAllBindings()
            end
            self._focusMouseWasOver = mouseOver
        end
        self:_pollGamepads()
    end
end

function PZFBInputPanel:_pollGamepads()
    for slotNum, slot in pairs(self._slots) do
        if slot.device == "controller" and slot.controllerId then
            local cid = slot.controllerId
            if isJoypadConnected(cid) then
                self:_pollSingleGamepad(slotNum, slot, cid)
            end
        end
    end
end

function PZFBInputPanel:_pollSingleGamepad(slotNum, slot, cid)
    -- Analog sticks
    local prevAxes = slot.axes or {}
    slot.axes = {
        leftX  = getJoypadMovementAxisX(cid),
        leftY  = getJoypadMovementAxisY(cid),
        rightX = getJoypadAimingAxisX(cid),
        rightY = getJoypadAimingAxisY(cid),
    }

    -- Fire axis callbacks when value changes significantly
    if self.onPZFBGamepadAxis then
        for name, value in pairs(slot.axes) do
            local prev = prevAxes[name] or 0
            if math.abs(value - prev) > 0.05 then
                self:onPZFBGamepadAxis(slotNum, name, value)
            end
        end
    end

    -- Triggers
    local prevTriggers = slot.triggers or {}
    slot.triggers = {
        left  = isJoypadLTPressed(cid),
        right = isJoypadRTPressed(cid),
    }
    if self.onPZFBGamepadTrigger then
        if slot.triggers.left ~= prevTriggers.left then
            self:onPZFBGamepadTrigger(slotNum, "left", slot.triggers.left)
        end
        if slot.triggers.right ~= prevTriggers.right then
            self:onPZFBGamepadTrigger(slotNum, "right", slot.triggers.right)
        end
    end

    -- Button polling (sole source of button callbacks — PZ-routed handlers are no-ops)
    local prevButtons = slot.buttons or {}
    slot.buttons = {}
    local btnCount = getButtonCount(cid)
    for n = 0, btnCount - 1 do
        slot.buttons[n] = isJoypadPressed(cid, n)
        if slot.buttons[n] and not prevButtons[n] then
            local mapped = self:_translateButton(cid, n)
            if self.onPZFBGamepadDown then
                self:onPZFBGamepadDown(slotNum, mapped)
            end
        elseif not slot.buttons[n] and prevButtons[n] then
            local mapped = self:_translateButton(cid, n)
            if self.onPZFBGamepadUp then
                self:onPZFBGamepadUp(slotNum, mapped)
            end
        end
    end

    -- D-pad polling (isJoypadUp/Down/Left/Right are separate from button polling)
    local prevDpad = slot.dpad or {}
    slot.dpad = {
        up    = isJoypadUp(cid),
        down  = isJoypadDown(cid),
        left  = isJoypadLeft(cid),
        right = isJoypadRight(cid),
    }
    local dpadMap = {
        up    = Joypad.DPadUp,
        down  = Joypad.DPadDown,
        left  = Joypad.DPadLeft,
        right = Joypad.DPadRight,
    }
    for dir, pressed in pairs(slot.dpad) do
        if pressed and not prevDpad[dir] then
            if self.onPZFBGamepadDown then
                self:onPZFBGamepadDown(slotNum, dpadMap[dir])
            end
        elseif not pressed and prevDpad[dir] then
            if self.onPZFBGamepadUp then
                self:onPZFBGamepadUp(slotNum, dpadMap[dir])
            end
        end
    end
end

function PZFBInputPanel:_translateButton(controllerId, rawIndex)
    if rawIndex == getJoypadAButton(controllerId) then return Joypad.AButton end
    if rawIndex == getJoypadBButton(controllerId) then return Joypad.BButton end
    if rawIndex == getJoypadXButton(controllerId) then return Joypad.XButton end
    if rawIndex == getJoypadYButton(controllerId) then return Joypad.YButton end
    if rawIndex == getJoypadLBumper(controllerId) then return Joypad.LBumper end
    if rawIndex == getJoypadRBumper(controllerId) then return Joypad.RBumper end
    if rawIndex == getJoypadBackButton(controllerId) then return Joypad.Back end
    if rawIndex == getJoypadStartButton(controllerId) then return Joypad.Start end
    if rawIndex == getJoypadLeftStickButton(controllerId) then return Joypad.LStickButton end
    if rawIndex == getJoypadRightStickButton(controllerId) then return Joypad.RStickButton end
    return Joypad.Other
end

-- ============================================================================
-- Polling API (for consumers that prefer polling over callbacks)
-- ============================================================================

--- Check if a keyboard key is currently held.
--- @param key number Keyboard constant
--- @return boolean
function PZFBInputPanel:isKeyDown(key)
    return self._keysDown[key] == true
end

--- Check if a modifier key is held (checks both L and R variants).
--- @param name string "shift", "ctrl", or "alt"
--- @return boolean
function PZFBInputPanel:isModifierDown(name)
    if name == "shift" then
        return Keyboard.isKeyDown(Keyboard.KEY_LSHIFT) or Keyboard.isKeyDown(Keyboard.KEY_RSHIFT)
    elseif name == "ctrl" then
        return Keyboard.isKeyDown(Keyboard.KEY_LCONTROL) or Keyboard.isKeyDown(Keyboard.KEY_RCONTROL)
    elseif name == "alt" then
        return Keyboard.isKeyDown(Keyboard.KEY_LMENU) or Keyboard.isKeyDown(Keyboard.KEY_RMENU)
    end
    return false
end

--- Get mouse position relative to this panel.
--- @return number x, number y
function PZFBInputPanel:getMousePos()
    return self:getMouseX(), self:getMouseY()
end

--- Check if a mouse button is currently held.
--- @param btn number 0=left, 1=right, 2=middle, etc.
--- @return boolean
function PZFBInputPanel:isMouseButtonDown(btn)
    return self._mouseButtons[btn] == true
end

--- Get a gamepad analog axis value.
--- @param slot number input slot number
--- @param name string "leftX", "leftY", "rightX", "rightY"
--- @return number -1.0 to 1.0
function PZFBInputPanel:getGamepadAxis(slot, name)
    local s = self._slots[slot]
    if s and s.axes then
        return s.axes[name] or 0
    end
    return 0
end

--- Check if a gamepad button is currently held.
--- @param slot number input slot number
--- @param button number Joypad button constant
--- @return boolean
function PZFBInputPanel:isGamepadDown(slot, button)
    local s = self._slots[slot]
    if not s or not s.buttons then return false end
    -- Reverse lookup: find raw button index for this mapped button
    if s.controllerId then
        local cid = s.controllerId
        for n, pressed in pairs(s.buttons) do
            if pressed and self:_translateButton(cid, n) == button then
                return true
            end
        end
    end
    return false
end

--- Check if a gamepad trigger is pressed.
--- @param slot number input slot number
--- @param side string "left" or "right"
--- @return boolean
function PZFBInputPanel:isGamepadTriggerDown(slot, side)
    local s = self._slots[slot]
    if s and s.triggers then
        return s.triggers[side] == true
    end
    return false
end

-- ============================================================================
-- Input Slot Management
-- ============================================================================

--- Assign a device to an input slot.
--- @param slot number slot number (1 = keyboard, 2+ = controllers)
--- @param device string "keyboard" or "controller"
--- @param controllerId number|nil controller ID (0-15) for "controller" device
function PZFBInputPanel:setSlotDevice(slot, device, controllerId)
    self._slots[slot] = {
        device = device,
        controllerId = controllerId,
        axes = {},
        triggers = {},
        buttons = {},
        dpad = {},
    }
    self._autoAssignSlots[slot] = nil
end

--- Enable auto-assignment for a slot.
--- The next controller button press will assign that controller to this slot.
--- @param slot number slot number
--- @param enabled boolean
function PZFBInputPanel:setSlotAutoAssign(slot, enabled)
    if enabled then
        if not self._slots[slot] then
            self._slots[slot] = {
                device = "controller",
                controllerId = nil,
                axes = {},
                triggers = {},
                buttons = {},
                dpad = {},
            }
        end
        self._autoAssignSlots[slot] = true
    else
        self._autoAssignSlots[slot] = nil
    end
end

-- ============================================================================
-- Selective Capture API
-- ============================================================================

--- Capture a specific key code (for MODE_SELECTIVE).
--- @param keyCode number Keyboard constant
function PZFBInputPanel:captureKey(keyCode)
    self._capturedKeys[keyCode] = true
    if self._capturing and self._mode == PZFBInput.MODE_SELECTIVE then
        self:_suppressBindingsForKey(keyCode)
    end
end

--- Capture multiple key codes at once.
--- @param keys table array of Keyboard constants
function PZFBInputPanel:captureKeys(keys)
    for _, k in ipairs(keys) do
        self:captureKey(k)
    end
end

--- Capture whatever key is bound to a game action name.
--- Resolved dynamically — follows user rebinds.
--- @param bindingName string e.g. "Forward", "Backward", "Interact"
function PZFBInputPanel:captureBinding(bindingName)
    self._capturedBindings[bindingName] = true
    if self._capturing and self._mode == PZFBInput.MODE_SELECTIVE then
        self:_suppressBinding(bindingName)
    end
end

--- Stop capturing a specific key code.
--- @param keyCode number
function PZFBInputPanel:releaseKey(keyCode)
    self._capturedKeys[keyCode] = nil
    if self._capturing then
        -- Rebuild suppression: restore all, then re-suppress remaining
        self:_restoreAllBindings()
        self:_suppressBindingsForMode()
    end
end

--- Stop capturing a game binding.
--- @param bindingName string
function PZFBInputPanel:releaseBinding(bindingName)
    self._capturedBindings[bindingName] = nil
    if self._capturing then
        self:_restoreAllBindings()
        self:_suppressBindingsForMode()
    end
end

--- Clear all selective capture registrations.
function PZFBInputPanel:releaseAllCaptures()
    self._capturedKeys = {}
    self._capturedBindings = {}
    if self._capturing then
        self:_restoreAllBindings()
    end
end

-- ============================================================================
-- Action Mapping
-- ============================================================================

--- Map a named action to an input binding.
--- Multiple bindings per action are supported (call multiple times with same name).
--- @param name string action name (e.g. "jump", "moveX")
--- @param binding table one of:
---   { key = Keyboard.KEY_* }                          -- single key
---   { gamepad = Joypad.AButton }                      -- gamepad button
---   { axis = "leftX" }                                -- analog axis
---   { keyNeg = Keyboard.KEY_A, keyPos = Keyboard.KEY_D }  -- keyboard as axis
function PZFBInputPanel:mapAction(name, binding)
    if not self._actions[name] then
        self._actions[name] = {}
    end

    local entry = {}
    if binding.key then
        entry.type = "key"
        entry.key = binding.key
    elseif binding.gamepad then
        entry.type = "gamepad"
        entry.button = binding.gamepad
    elseif binding.axis then
        entry.type = "axis"
        entry.axis = binding.axis
        entry.slot = binding.slot or 2  -- default to slot 2 for gamepad axes
    elseif binding.keyNeg and binding.keyPos then
        entry.type = "keyAxis"
        entry.keyNeg = binding.keyNeg
        entry.keyPos = binding.keyPos
    end

    table.insert(self._actions[name], entry)
end

--- Remove all bindings for an action.
--- @param name string action name
function PZFBInputPanel:unmapAction(name)
    self._actions[name] = nil
end

--- Check if any binding for an action is currently active.
--- @param name string action name
--- @return boolean
function PZFBInputPanel:isActionDown(name)
    local bindings = self._actions[name]
    if not bindings then return false end

    for _, b in ipairs(bindings) do
        if b.type == "key" then
            if self._keysDown[b.key] then return true end
        elseif b.type == "gamepad" then
            -- Check all controller slots
            for slotNum, slot in pairs(self._slots) do
                if slot.device == "controller" and self:isGamepadDown(slotNum, b.button) then
                    return true
                end
            end
        elseif b.type == "axis" then
            local val = self:getGamepadAxis(b.slot, b.axis)
            if math.abs(val) > 0.5 then return true end
        elseif b.type == "keyAxis" then
            if self._keysDown[b.keyNeg] or self._keysDown[b.keyPos] then return true end
        end
    end
    return false
end

--- Get the analog value of an action.
--- For axes: -1.0 to 1.0. For buttons/keys: 0.0 or 1.0.
--- @param name string action name
--- @return number
function PZFBInputPanel:getActionValue(name)
    local bindings = self._actions[name]
    if not bindings then return 0 end

    local value = 0
    for _, b in ipairs(bindings) do
        if b.type == "key" then
            if self._keysDown[b.key] then return 1.0 end
        elseif b.type == "gamepad" then
            for slotNum, slot in pairs(self._slots) do
                if slot.device == "controller" and self:isGamepadDown(slotNum, b.button) then
                    return 1.0
                end
            end
        elseif b.type == "axis" then
            local val = self:getGamepadAxis(b.slot, b.axis)
            if math.abs(val) > math.abs(value) then
                value = val
            end
        elseif b.type == "keyAxis" then
            local v = 0
            if self._keysDown[b.keyNeg] then v = v - 1.0 end
            if self._keysDown[b.keyPos] then v = v + 1.0 end
            if math.abs(v) > math.abs(value) then
                value = v
            end
        end
    end
    return value
end

-- ============================================================================
-- Config Persistence
-- ============================================================================

--- Save input configuration to a file.
--- Writes to ~/Zomboid/Lua/PZFB_input_<name>.cfg
--- @param name string config name (e.g. "emulator", "videoplayer")
function PZFBInputPanel:saveInputConfig(name)
    local writer = getFileWriter("PZFB_input_" .. name .. ".cfg", true, false)
    if not writer then return end

    writer:writeln("[settings]")
    writer:writeln("mode=" .. tostring(self._mode))
    if self._captureToggleKey then
        writer:writeln("captureToggleKey=" .. tostring(self._captureToggleKey))
    end
    writer:writeln("escapeCloses=" .. tostring(self._escapeCloses))
    writer:writeln("escapeReleasesCapture=" .. tostring(self._escapeReleasesCapture))

    -- Save action mappings
    for actionName, bindings in pairs(self._actions) do
        for i, b in ipairs(bindings) do
            writer:writeln("[action." .. actionName .. "." .. tostring(i) .. "]")
            writer:writeln("type=" .. b.type)
            if b.key then writer:writeln("key=" .. tostring(b.key)) end
            if b.button then writer:writeln("button=" .. tostring(b.button)) end
            if b.axis then writer:writeln("axis=" .. b.axis) end
            if b.slot then writer:writeln("slot=" .. tostring(b.slot)) end
            if b.keyNeg then writer:writeln("keyNeg=" .. tostring(b.keyNeg)) end
            if b.keyPos then writer:writeln("keyPos=" .. tostring(b.keyPos)) end
        end
    end

    -- Save slot assignments
    for slotNum, slot in pairs(self._slots) do
        if slot.device == "controller" and slot.controllerId then
            writer:writeln("[slot." .. tostring(slotNum) .. "]")
            writer:writeln("device=controller")
            writer:writeln("controllerId=" .. tostring(slot.controllerId))
        end
    end

    writer:close()
end

--- Load input configuration from a file.
--- Reads from ~/Zomboid/Lua/PZFB_input_<name>.cfg
--- @param name string config name
--- @return boolean true if loaded successfully
function PZFBInputPanel:loadInputConfig(name)
    local reader = getFileReader("PZFB_input_" .. name .. ".cfg", false)
    if not reader then return false end

    -- Clear existing actions so load is a full replace, not append
    self._actions = {}

    local section = nil
    local actionName = nil
    local bindingIdx = nil
    local currentBinding = nil

    local line = reader:readLine()
    while line do
        line = line:trim()
        if line == "" or line:sub(1, 1) == "#" then
            -- skip empty lines and comments
        elseif line:sub(1, 1) == "[" then
            -- Commit any pending binding
            if currentBinding and actionName then
                if not self._actions[actionName] then
                    self._actions[actionName] = {}
                end
                table.insert(self._actions[actionName], currentBinding)
                currentBinding = nil
            end
            section = line:sub(2, -2)  -- strip brackets

            -- Parse section name
            local actionMatch, idxMatch = section:match("^action%.(.+)%.(%d+)$")
            if actionMatch then
                actionName = actionMatch
                bindingIdx = tonumber(idxMatch)
                currentBinding = {}
            else
                actionName = nil
                currentBinding = nil
            end
        else
            local key, val = line:match("^(%w+)=(.+)$")
            if key and val then
                if section == "settings" then
                    if key == "mode" then self._mode = tonumber(val) or self._mode end
                    if key == "captureToggleKey" then self._captureToggleKey = tonumber(val) end
                    if key == "escapeCloses" then self._escapeCloses = val == "true" end
                    if key == "escapeReleasesCapture" then self._escapeReleasesCapture = val == "true" end
                elseif currentBinding then
                    if key == "type" then currentBinding.type = val end
                    if key == "key" then currentBinding.key = tonumber(val) end
                    if key == "button" then currentBinding.button = tonumber(val) end
                    if key == "axis" then currentBinding.axis = val end
                    if key == "slot" then currentBinding.slot = tonumber(val) end
                    if key == "keyNeg" then currentBinding.keyNeg = tonumber(val) end
                    if key == "keyPos" then currentBinding.keyPos = tonumber(val) end
                elseif section and section:match("^slot%.") then
                    local slotNum = tonumber(section:match("^slot%.(%d+)$"))
                    if slotNum then
                        if key == "controllerId" then
                            self:setSlotDevice(slotNum, "controller", tonumber(val))
                        end
                    end
                end
            end
        end
        line = reader:readLine()
    end

    -- Commit last pending binding
    if currentBinding and actionName then
        if not self._actions[actionName] then
            self._actions[actionName] = {}
        end
        table.insert(self._actions[actionName], currentBinding)
    end

    reader:close()
    return true
end
