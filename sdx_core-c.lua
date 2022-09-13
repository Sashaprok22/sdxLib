for _, sdxRoot in pairs( getElementsByType( "sdxRoot" ) ) do
    for _, sdxChild in pairs( getElementChildren( sdxRoot ) ) do destroyElement( sdxChild ) end
end

local clickedScroll = {}
local tRenderOrder = {}
local elementsUpdatesAfterMinimize = {}
local tRenderInTop = {}
local tElementsToRemove = {}

local function updateElement( element, ... )
    if not isElement( element ) then return end
    if isMTAMinimized() then elementsUpdatesAfterMinimize[element] = arg return end
    local elementType = getElementType( element )
    if table.find( rectangledElements, elementType ) then updateRectangle( element )
    elseif elementType == "sdxProgressBar" then updateProgressBar( element )
    elseif elementType == "sdxButton" then updateButton( element )
    elseif elementType == "sdxEditBox" then updateEditBox( element, unpack( arg ) )
    elseif elementType == "sdxSpace" then updateSpace( element )
    elseif elementType == "sdxScroll" then updateScroll( element )
    elseif elementType == "sdxSlider" then updateSlider( element )
    elseif elementType == "sdxList" then updateList( element )
    end
end

local function drawElement( element, pOffsetX, pOffsetY, render )
    if not getSDXData( element, "visible" ) then return end

    local offsetX, offsetY = pOffsetX or 0, pOffsetY or 0
    local scrollOffsetX, scrollOffsetY = offsetX, offsetY

    local elementType = getElementType( element )
    if table.find( rectangledElements, elementType ) then drawRectangle( element, offsetX, offsetY, render )
    elseif elementType == "sdxLabel" then drawLabel( element, offsetX, offsetY, render )
    elseif elementType == "sdxProgressBar" then drawProgressBar( element, offsetX, offsetY, render )
    elseif elementType == "sdxButton" then drawButton( element, offsetX, offsetY, render )
    elseif elementType == "sdxEditBox" then drawEditBox( element, offsetX, offsetY, render )
    elseif elementType == "sdxScroll" then drawScroll( element, offsetX, offsetY, render )
    elseif elementType == "sdxSlider" then drawSlider( element, offsetX, offsetY, render )
    elseif elementType == "sdxList" then drawList( element, offsetX, offsetY, render )
    elseif elementType == "sdxSpace" then
        drawSpace( element, offsetX, offsetY, render )
        dxSetRenderTarget( getSDXData( element, "texture" ), true )
        dxSetBlendMode( "modulate_add" )
        local content = getSDXData( element, "content" ) or {x=0,y=0}
        render = element
        offsetX, offsetY = offsetX - content.x, offsetY - content.y

    end

    for _, child_element in ipairs( tRenderOrder[element] or {} ) do
        if isElement( child_element ) then
            if not tRenderInTop[child_element] then
                if getElementType( child_element ) == "sdxScroll" then drawElement( child_element, scrollOffsetX, scrollOffsetY )
                else drawElement( child_element, offsetX, offsetY, render ) end
            end
        else
            table.insert( tElementsToRemove, { i, element } )
            tRenderOrder[child_element] = nil
        end

    end

    if elementType == "sdxSpace" then
        dxSetBlendMode( "blend" )
        dxSetRenderTarget()
    end
end

function sdxElementUpInRenderOrder( element )
    local parent = getElementParent( element )
    local isMain = getElementType( parent ) == "sdxRoot"

    if not isMain and not tRenderOrder[parent] then tRenderOrder[parent] = {} end

    local isFinded = table.find( isMain and tRenderOrder or tRenderOrder[parent], element )
    if isFinded then
        table.remove( isMain and tRenderOrder or tRenderOrder[parent], isFinded )
    end
    table.insert( isMain and tRenderOrder or tRenderOrder[parent], element )
end

function sdxGetElementOrderPosition( element )
    local parent = getElementParent( element )
    local isMain = getElementType( parent ) == "sdxRoot"

    if not isMain and not tRenderOrder[parent] then return false end
    return table.find( isMain and tRenderOrder or tRenderOrder[parent], element )
end

function setSDXData( element, key, data, notUpdate )
    if not key then return end
    if not isElement( element ) or not table.find( sdxElements, getElementType( element ) ) then return end
    if not tDrawElements[element] then tDrawElements[element] = {} end
    if not triggerEvent( "onSDXDataChange", element, key, tDrawElements[element][key], data ) then return end
    local old = tDrawElements[element][key]
    tDrawElements[element][key] = data

    if not notUpdate and key == "position" and old and data then
        local moveX, moveY = data.x - old.x, data.y - old.y
        for _, child in pairs( getElementChildren( element ) ) do
            local child_pos = getSDXData( child, "position" )
            local x, y = child_pos.x + moveX, child_pos.y + moveY
            setSDXData( child, "position", { x = x, y = y } )
        end
    end

    if key == "renderInTop" then
        tRenderInTop[element] = data and true or nil
    end

    if key == "visible" and data and ( getElementType( getElementParent( element ) ) == "sdxRoot" or not sdxGetElementOrderPosition( element ) ) then
        sdxElementUpInRenderOrder( element )
    end

    if not notUpdate then updateElement( element ) end
end

function getSDXData( element, key )
    if not key then return end
    if not tDrawElements[element] then return end
    if tDrawElements[element][key] == false then return false end
    if tDrawElements[element][key] == nil then return end
    return table.copy({ tDrawElements[element][key] }, true)[1]
end

local tFontCache = {}
function getSDXFont( font, size, notCreate )
    if not fileExists( font ) then return font or "default" end
    if notCreate then
        if not tFontCache[font] then return false end
        return tFontCache[font][size]
    end

    if not tFontCache[font] then tFontCache[font] = {} end
    tFontCache[font][size] = tFontCache[font][size] or dxCreateFont( font, size )
    return tFontCache[font][size] or "default"
end

local function isElementActive( element )
    local active = getSDXData( element, "visible" ) or getSDXData( element, "enable" )
    if not active then return end

    local parent = getElementParent( element )
    local visible = true

    while visible and parent do
        if getElementType( parent ) == "sdxRoot" then return true end
        visible = getSDXData( element, "visible" ) or getSDXData( element, "enable" )
        if not visible then return end
        parent = getElementParent( parent )
    end
    return visible
end

addEventHandler( "onClientRender", root, function ()

    if clickedScroll and isElement( clickedScroll.scroll ) then
        if not getKeyState( "mouse1" ) then clickedScroll = {} else

            if getElementType( clickedScroll.scroll ) == "sdxScroll" then
                local pos, size = getSDXData( clickedScroll.scroll, "position" ) or {x=0,y=0,rot=0}, getSDXData( clickedScroll.scroll, "size" ) or {w=0,h=0}
                local x, y, w, h, visible, vector = getInsideScroll( clickedScroll.scroll, pos.x, pos.y, size.w, size.h )
                if not visible then clickedScroll = {} else

                    local cx, cy = getCursorPosition()
                    cx, cy = cx*screenW, cy*screenH

                    local parent = getElementParent( clickedScroll.scroll )
                    local content = getSDXData( parent, "content" ) or {x=0,y=0,w=0,h=0}
                    local size = getSDXData( parent, "size" ) or {w=0,h=0}

                    if vector == "horizontal" then
                        if not clickedScroll.diff then
                            clickedScroll.diff = cx - x
                        end

                        local newSliderX = cx - clickedScroll.diff
                        if newSliderX > pos.x + size.w - w then newSliderX = pos.x + size.w - w end
                        if newSliderX < pos.x then newSliderX = pos.x end
                        local newX = newSliderX - pos.x
                        local rel = size.w/newX

                        local newX = content.w/rel
                        if newX > content.w-size.w then newX = content.w-size.w end
                        if newX < 0 then newX = 0 end
                        if content.x ~= newX then
                            content.x = newX
                            setSDXData( parent, "content", content )
                        end

                    else

                        if not clickedScroll.diff then
                            clickedScroll.diff = cy - y
                        end

                        local newSliderY = cy - clickedScroll.diff
                        if newSliderY > pos.y + size.h - h then newSliderY = pos.y + size.h - h end
                        if newSliderY < pos.y then newSliderY = pos.y end
                        local newY = newSliderY - pos.y
                        local rel = size.h/newY

                        local newY = content.h/rel
                        if newY > content.h-size.h then newY = content.h-size.h end
                        if newY < 0 then newY = 0 end
                        if content.y ~= newY then
                            content.y = newY
                            setSDXData( parent, "content", content )
                        end

                    end
                end

            elseif getElementType( clickedScroll.scroll ) == "sdxSlider" then
                local pos, size = getSDXData( clickedScroll.scroll, "position" ) or {x=0,y=0,rot=0}, getSDXData( clickedScroll.scroll, "size" ) or {w=0,h=0}

                local scroll = getSDXData( clickedScroll.scroll, "scroll" ) or {}
                local progress = getSDXData( clickedScroll.scroll, "progress" ) or 0

                local w = math.min( size.w, size.h )*2
                local vector = scroll.vector
                
                local x, y = pos.x, pos.y
                if vector == "horizontal" then
                    x = (x + size.w/100*progress) - w/2
                    y = y - w/2 + size.h/2
                else
                    y = (y + size.h - size.h/100*progress) - w/2
                    x = x - w/2 + size.w/2
                end

                local cx, cy = getCursorPosition()
                cx, cy = cx*screenW, cy*screenH

                if vector == "horizontal" then
                    if not clickedScroll.diff then clickedScroll.diff = cx - x - w/2 end

                    local newSliderX = cx - clickedScroll.diff
                    local newX = newSliderX - pos.x
                    if newX <= -w/2 then newX = -w/2 end
                    if newX >= size.w then newX = size.w end

                    local newProgress = newX / (size.w / 100)

                    if progress ~= newProgress and newProgress >= 0 and newProgress <= 100 then
                        setSDXData( clickedScroll.scroll, "progress", newProgress )
                        triggerEvent( "onSDXSliderMoved", clickedScroll.scroll, newProgress )
                    end

                else

                    if not clickedScroll.diff then clickedScroll.diff = cy - y - w/2 end

                    local newSliderY = cy - clickedScroll.diff
                    local newY = newSliderY - pos.y
                    if newY <= -w/2 then newY = -w/2 end
                    if newY >= size.h then newY = size.h end

                    local newProgress = newY / (size.h / 100)

                    if progress ~= newProgress and newProgress >= 0 and newProgress <= 100 then
                        newProgress = 100 - newProgress
                        setSDXData( clickedScroll.scroll, "progress", newProgress )
                        triggerEvent( "onSDXSliderMoved", clickedScroll.scroll, newProgress )
                    end

                end

            else
                local pos = getSDXData( clickedScroll.scroll, "position" ) or {x=0,y=0,rot=0}

                if not clickedScroll.diff then clickedScroll.diff = { clickedScroll.x - pos.x, clickedScroll.y - pos.y } end
                local diffX, diffY = unpack( clickedScroll.diff )

                local cx, cy = getCursorPosition()
                cx, cy = cx*screenW, cy*screenH

                pos.x = cx - diffX
                pos.y = cy - diffY

                setSDXData( clickedScroll.scroll, "position", pos )

            end
        end

    end

    if isElement( selectEdit ) and not isElementActive( selectEdit ) then resetActiveEditBox() end

    if tSelectedKey and isElement( selectEdit ) and getSDXData( selectEdit, "enable" ) then
        local text = getSDXData( selectEdit, "text" ) or ""
        local editSettings = getSDXData( selectEdit, "editSettings" ) or {}

        if tSelectedKey.tick + 500 <= getTickCount() and not tSelectedKey.second and getKeyState( tSelectedKey.key ) then
            if  tSelectedKey.key == "Backspace" then 
                if writePosition < utf8.len( text ) then text = remove_char( text, utf8.len( text ) - writePosition ) end
            elseif tSelectedKey.key == "arrow_l" then
                if writePosition < utf8.len( text ) then
                    writePosition = writePosition + 1
                    updateElement( selectEdit, "l" )
                end
            elseif tSelectedKey.key == "arrow_r" then
                if writePosition > 0 then
                    writePosition = writePosition - 1
                    updateElement( selectEdit, "r" )
                end
            else
                if utf8.len( text ) < (editSettings.maxLength or 1000) then text = add_char( text, utf8.len( text ) - writePosition, tSelectedKey.symbol ) end
            end
            if tSelectedKey.key ~= "arrow_l" and tSelectedKey.key ~= "arrow_r" then
                local eventResult = triggerEvent( "onSdxEditBoxEdited", selectEdit, text )
                if eventResult then
                    setSDXData( selectEdit, "text", text )
                    updateElement( selectEdit )
                end
            end
            tSelectedKey.second = true
            tSelectedKey.tick = getTickCount()

            lastTickRectEdit = getTickCount() - 700

        elseif tSelectedKey.tick + 100 <= getTickCount() and tSelectedKey.second and getKeyState( tSelectedKey.key ) then
            if  tSelectedKey.key == "Backspace" then 
                if writePosition < utf8.len( text ) then text = remove_char( text, utf8.len( text ) - writePosition ) end
            elseif tSelectedKey.key == "arrow_l" then
                if writePosition < utf8.len( text ) then
                    writePosition = writePosition + 1
                    updateElement( selectEdit, "l" )
                end
            elseif tSelectedKey.key == "arrow_r" then
                if writePosition > 0 then
                    writePosition = writePosition - 1
                    updateElement( selectEdit, "r" )
                end
            else 
                if utf8.len( text ) < (editSettings.maxLength or 1000) then text = add_char( text, utf8.len( text ) - writePosition, tSelectedKey.symbol ) end
            end 
            if tSelectedKey.key ~= "arrow_l" and tSelectedKey.key ~= "arrow_r" then
                local eventResult = triggerEvent( "onSdxEditBoxEdited", selectEdit, text )
                if eventResult then
                    setSDXData( selectEdit, "text", text )
                    updateElement( selectEdit )
                end
            end
            tSelectedKey.tick = getTickCount()

            lastTickRectEdit = getTickCount() - 700

        elseif not getKeyState( tSelectedKey.key ) then tSelectedKey = false end
    end

    tElementsToRemove = {}
    for i, element in ipairs( tRenderOrder ) do
        if isElement( element ) then
            if not tRenderInTop[element] then drawElement( element ) end
        else
            table.insert( tElementsToRemove, { i } )
            tRenderOrder[element] = nil
        end

    end

    for element, _ in ipairs( tRenderInTop ) do
        if isElement( element ) then drawElement( element ) else tRenderInTop[element] = nil end
    end

    for _, element in pairs( tElementsToRemove ) do
        if element[2] and tRenderOrder[element[2]] then table.remove( tRenderOrder[element[2]], element[1] )
        elseif not element[2] then table.remove( tRenderOrder, element[1] ) end
    end
    tElementsToRemove = {}
    
end, true, "low" )

local clickedElement
local clickedDoubleElement

local function searchHoveredElement( element, event, offsetX, offsetY, render )
    if not getSDXData( element, "visible" ) then return end
    local elementType = getElementType( element )

    local pos, size = getSDXData( element, "position" ) or {x=0,y=0,rot=0}, getSDXData( element, "size" ) or {w=0,h=0}

    local rPos = {x=0,y=0,rot=0}
    local rSize = {w=99999,h=99999}
    if isElement( render ) then
        rPos = getSDXData( render, "position" ) or rPos
        rSize = getSDXData( render, "size" ) or rSize
    end
    pos.x, pos.y = pos.x + offsetX, pos.y + offsetY

    local x, y, w, h, visible = pos.x, pos.y, size.w, size.h, true
    if elementType == "sdxScroll" then x, y, w, h, visible = getInsideScroll( element, x, y, w, h )
    elseif elementType == "sdxSlider" then
        local progress = getSDXData( element, "progress" ) or 0
        local scroll = getSDXData( element, "scroll" ) or {}
        local sizeSlider = math.min( size.w, size.h )
        if scroll.vector == "horizontal" then
            x = (x + size.w/100*progress) - sizeSlider
            y = y - sizeSlider + size.h/2
        else
            y = (y + size.h - size.h/100*progress) - sizeSlider
            x = x - sizeSlider + size.w/2
        end
        w, h = sizeSlider*2, sizeSlider*2
    end
    if not visible then return end

    if isCursorOnElement( rPos.x, rPos.y, rSize.w, rSize.h, rPos.rot or 0 ) and isCursorOnElement( x, y, w, h, pos.rot or 0 ) and getSDXData( element, "enable" ) then
        if event == 1 then clickedElement = element
        else clickedDoubleElement = element end
    end

    local content = getSDXData( element, "content" ) or { x=0,y=0 }
    for _, child_element in ipairs( tRenderOrder[element] or {} ) do
        local nOffsetX, nOffsetY = offsetX, offsetY
        local render
        if getElementType( child_element ) ~= "sdxScroll" then
            nOffsetX, nOffsetY = offsetX-content.x, offsetY-content.y
            render = elementType == "sdxSpace" and element
        end

        if not tRenderInTop[child_element] then
            searchHoveredElement( child_element, event, nOffsetX, nOffsetY, render )
        end

    end
end

local function canDragElement( element )
    if getSDXData( element, "dragable" ) then return true end
    return getElementType( element ) == "sdxScroll" or getElementType( element ) == "sdxSlider"
end

addEventHandler( "onClientClick", root, function ( btn, state )
    for _, element in ipairs( tRenderOrder ) do
        if not tRenderInTop[child_element] then searchHoveredElement( element, 1,0,0) end
    end

    for element, _ in ipairs( tRenderInTop ) do
        if isElement( element ) then searchHoveredElement( element, 1,0,0) end
    end

    if isElement( clickedElement ) then
        if state == "down" then playSound( "click.mp3" ) end

        local clickedItem = {}
        local isUnselectItem
        if btn == "left" and state == "up" and getElementType( clickedElement ) == "sdxList" then
            local pos, size = getSDXData( clickedElement, "position" ) or {x=0,y=0,rot=0}, getSDXData( clickedElement, "size" ) or {w=0,h=0}
            local tabs = getSDXData( clickedElement, "tabs" ) or {0,0,0,0}

            local columns = getSDXData( clickedElement, "columns" ) or {}
            local rows = getSDXData( clickedElement, "rows" ) or {}
            local listSets = getSDXData( clickedElement, "list" ) or {}
            local headSets = getSDXData( clickedElement, "header" ) or { height = 0 }

            local tX = pos.x + tabs[1]
            local tY = pos.y + headSets.height + tabs[2]
            local tW = size.w - tabs[1] - tabs[3]
            local tH = size.h - headSets.height - tabs[2] - tabs[4]

            local content = getSDXData( clickedElement, "content" ) or {x=0,y=0,w=0,h=0}
            local selectedItem = getSDXData( element, "selectedItem" ) or {}

            if ( listSets.canSelect or listSets.canUnselect ) and isCursorOnElement( tX, tY, tW, tH, pos.rot or 0 ) then
                local offsetRow = -content.y

                for rowI, row in ipairs( rows ) do
                    local rowWidth = 0
                    for i, col in ipairs( columns ) do
                        if not listSets.solid and isCursorOnElement( -content.x + tX + rowWidth + (i-1) * (listSets.colTab or 0), tY + offsetRow, col.width, listSets.rowHeight, 0 ) then
                            if selectedItem.row == rowI and selectedItem.item == i then
                                isUnselectItem = listSets.canUnselect
                            elseif listSets.canSelect then
                                clickedItem = { rowI, i, row.key }
                            end
                        end
                        rowWidth = rowWidth + (col.width or 0)
                    end

                    if listSets.solid and isCursorOnElement( -content.x + tX, tY + offsetRow, rowWidth, listSets.rowHeight, 0 ) then
                        if selectedItem.row == rowI then
                            isUnselectItem = listSets.canUnselect
                        elseif listSets.canSelect then
                            clickedItem = { rowI, false, row.key }
                        end
                    end

                    offsetRow = offsetRow + listSets.rowHeight + (listSets.rowTab or 0)
                end
            end
        end

        local isTriggered = triggerEvent( "onSdxElementPressed", clickedElement, btn, state, unpack( clickedItem ) )
        if not isTriggered then return end

        if isUnselectItem then
            setSDXData( clickedElement, "selectedItem", nil )
        elseif #clickedItem > 0 then
            setSDXData( clickedElement, "selectedItem", { row = clickedItem[1], item = clickedItem[2] or nil, rowKey = clickedItem[3] } )
        end

        if btn == "left" and state == "down" then
            if getElementType( clickedElement ) == "sdxEditBox" then setActiveEditBox( clickedElement )
            elseif selectEdit ~= clickedElement then resetActiveEditBox() end

            if canDragElement( clickedElement ) then
                local cx, cy = getCursorPosition()
                clickedScroll = {
                    scroll = clickedElement,
                    x = cx*screenW,
                    y = cy*screenH,
                }
            end
        end

    elseif btn == "left" and state == "down" and isElement( selectEdit ) then resetActiveEditBox() end
    clickedElement = nil
end )

addEventHandler( "onClientDoubleClick", root, function ( btn )
    for _, element in ipairs( tRenderOrder ) do
        if not tRenderInTop[child_element] then searchHoveredElement( element, 2,0,0 ) end
    end

    for element, _ in ipairs( tRenderInTop ) do
        if isElement( element ) then searchHoveredElement( element, 2,0,0 ) end
    end

    if isElement( clickedDoubleElement ) then triggerEvent( "onSdxElementDoubleClick", clickedDoubleElement, btn ) end
    clickedDoubleElement = nil
end )

addEventHandler( "onClientCharacter", root, function( symbol )
    if not isElement( selectEdit ) then return end
    local text = getSDXData( selectEdit, "text" ) or ""
    local editSettings = getSDXData( selectEdit, "editSettings" ) or {}
    if utf8.len( text ) >= (editSettings.maxLength or 1000) then return end
    if not isSymbolAllowed( symbol, editSettings.symbols or "" ) then return end
    text = add_char( text, utf8.len( text ) - writePosition, symbol )

    local eventResult = triggerEvent( "onSdxEditBoxEdited", selectEdit, text )
    if not eventResult then return end

    setSDXData( selectEdit, "text", text )
    updateElement( selectEdit )

    local key = utf8.lower( symbol )
    tSelectedKey = {
        symbol = symbol,
        key = key,
        tick = getTickCount()
    }
    lastTickRectEdit = getTickCount() - 700
end )

addEventHandler( "onClientKey", root, function( button, press )
    if button == "mouse_wheel_down" then
        for space, _ in pairs( tHoveredSpaces ) do
            if isElement( space ) then
                local size = getSDXData( space, "size" ) or {w=0,h=0}
                local content = getSDXData( space, "content" ) or {w=0,h=0,x=0,y=0}
                if content.h > size.h then
                    if content.y < content.h - size.h then
                        local step = content.h/100 * (getSDXData( space, "scroll_step" ) or 1)
                        step = content.y + step
                        if step > content.h - size.h then step = content.h - size.h end
                        content.y = step
                        setSDXData( space, "content", content )

                    end
                end

            end
        end

    elseif button == "mouse_wheel_up" then
        for space, _ in pairs( tHoveredSpaces ) do
            if isElement( space ) then
                local size = getSDXData( space, "size" ) or {w=0,h=0}
                local content = getSDXData( space, "content" ) or {w=0,h=0,x=0,y=0}
                if content.h > size.h then
                    if content.y > 0 then
                        local step = content.h/100 * (getSDXData( space, "scroll_step" ) or 1)
                        step = content.y - step
                        if step < 0 then step = 0 end
                        content.y = step
                        setSDXData( space, "content", content )

                    end
                end

            end
        end
    end

    if not press then return end
    if not isElement( selectEdit ) then return end
    local text = getSDXData( selectEdit, "text" ) or ""

    if button == "backspace" then
        if  writePosition >= utf8.len( text ) then return end
        text = remove_char( text, utf8.len( text ) - writePosition )

        local eventResult = triggerEvent( "onSdxEditBoxEdited", selectEdit, text )
        if not eventResult then return end

        setSDXData( selectEdit, "text", text )
        updateElement( selectEdit )

        tSelectedKey = {
            symbols = "Backspace",
            key = "Backspace",
            tick = getTickCount()
        }
        lastTickRectEdit = getTickCount() - 700

    elseif button == "arrow_l" then
        if writePosition >= utf8.len( text ) then return end
        writePosition = writePosition + 1
        updateElement( selectEdit, "l" )
        
        tSelectedKey = {
            symbols = "arrow_l",
            key = "arrow_l",
            tick = getTickCount()
        }
        lastTickRectEdit = getTickCount() - 700

    elseif button == "arrow_r" then
        if writePosition <= 0 then return end
        writePosition = writePosition - 1
        updateElement( selectEdit, "r" )
        
        tSelectedKey = {
            symbols = "arrow_r",
            key = "arrow_r",
            tick = getTickCount()
        }
        lastTickRectEdit = getTickCount() - 700
    end
end )

addEventHandler( "onClientPaste", root, function( paste )
    if not isElement( selectEdit ) then return end
    local text = getSDXData( selectEdit, "text" ) or ""
    local editSettings = getSDXData( selectEdit, "editSettings" ) or {}

    if utf8.len( text ) >= (editSettings.maxLength or 1000) then return end
    for s in utf8.gmatch( paste, "." ) do
        if not isSymbolAllowed( s, editSettings.symbols ) then return end
    end
    text = add_char( text, utf8.len( text ) - writePosition, paste )

    local eventResult = triggerEvent( "onSdxEditBoxEdited", selectEdit, text )
    if not eventResult then return end

    setSDXData( selectEdit, "text", text )
    updateElement( selectEdit )

    lastTickRectEdit = getTickCount() - 700
end )

addEventHandler( "onClientElementDestroy", root, function ()
    if tRenderOrder[source] then tRenderOrder[source] = nil end
    if table.find( tRenderOrder, source ) then table.remove( tRenderOrder, table.find( tRenderOrder, source ) ) end
    local parent = getElementParent( source )
    if tRenderOrder[parent] and table.find( tRenderOrder[parent], source ) then table.remove( tRenderOrder[parent], table.find( tRenderOrder[parent], source ) ) end

    local texture = getSDXData( source, "texture" )
    local addTexture = getSDXData( source, "addTexture" )
    local shaderRounded = getSDXData( source, "roundedShader" )
    local shaderRoundbar = getSDXData( source, "roundBarShader" )
    local textTexture = getSDXData( source, "text_texture" )
    local slider = getSDXData( source, "slider" )

    if isElement( texture ) then destroyElement( texture ) end
    if isElement( addTexture ) then destroyElement( addTexture ) end
    if isElement( textTexture ) then destroyElement( textTexture ) end
    if isElement( shaderRounded ) then destroyElement( shaderRounded ) end
    if isElement( shaderRoundbar ) then destroyElement( shaderRoundbar ) end
    if isElement( slider ) then destroyElement( slider ) end

    tDrawElements[source] = nil
end )

addEventHandler( "onClientRestore", root, function ()
    for element, info in pairs(elementsUpdatesAfterMinimize) do
        if isElement( element ) then updateElement( element, type( info ) == "table" and unpack( info ) ) end
    end
    elementsUpdatesAfterMinimize = {}
end )

addEventHandler( "onClientResourceStop", resourceRoot, function ()
    guiSetInputEnabled( false )
end )

function setActiveEditBox( element )
    if getElementType( element ) ~= "sdxEditBox" then return end
    local oldSelect = selectEdit
    writePosition = 0
    lastTickRectEdit = getTickCount() - 700
    selectEdit = element
    guiSetInputEnabled( true )
    if oldSelect then updateElement( oldSelect ) end
    updateElement( element )
end

function getActiveEditBox()
    return selectEdit
end

function resetActiveEditBox()
    local oldSelect = selectEdit
    selectEdit = false
    writePosition = 0
    updateElement( oldSelect )
    guiSetInputEnabled( false )
end

TEST_MODE = false
CREATE_TEST_ELEMENT = false

if TEST_MODE then

    local function dxDrawBorderedText (outline, text, left, top, right, bottom, color, scale, font, alignX, alignY, clip, wordBreak, postGUI, colorCoded, subPixelPositioning, fRotation, fRotationCenterX, fRotationCenterY)
        local outline = (scale or 1) * (1.333333333333334 * (outline or 1))
        dxDrawText (text:gsub("#%x%x%x%x%x%x", ""), left - outline, top - outline, right - outline, bottom - outline, tocolor (0, 0, 0, 225), scale, font, alignX, alignY, clip, wordBreak, postGUI, false, subPixelPositioning, fRotation, fRotationCenterX, fRotationCenterY)
        dxDrawText (text:gsub("#%x%x%x%x%x%x", ""), left + outline, top - outline, right + outline, bottom - outline, tocolor (0, 0, 0, 225), scale, font, alignX, alignY, clip, wordBreak, postGUI, false, subPixelPositioning, fRotation, fRotationCenterX, fRotationCenterY)
        dxDrawText (text:gsub("#%x%x%x%x%x%x", ""), left - outline, top + outline, right - outline, bottom + outline, tocolor (0, 0, 0, 225), scale, font, alignX, alignY, clip, wordBreak, postGUI, false, subPixelPositioning, fRotation, fRotationCenterX, fRotationCenterY)
        dxDrawText (text:gsub("#%x%x%x%x%x%x", ""), left + outline, top + outline, right + outline, bottom + outline, tocolor (0, 0, 0, 225), scale, font, alignX, alignY, clip, wordBreak, postGUI, false, subPixelPositioning, fRotation, fRotationCenterX, fRotationCenterY)
        dxDrawText (text:gsub("#%x%x%x%x%x%x", ""), left - outline, top, right - outline, bottom, tocolor (0, 0, 0, 225), scale, font, alignX, alignY, clip, wordBreak, postGUI, false, subPixelPositioning, fRotation, fRotationCenterX, fRotationCenterY)
        dxDrawText (text:gsub("#%x%x%x%x%x%x", ""), left + outline, top, right + outline, bottom, tocolor (0, 0, 0, 225), scale, font, alignX, alignY, clip, wordBreak, postGUI, false, subPixelPositioning, fRotation, fRotationCenterX, fRotationCenterY)
        dxDrawText (text:gsub("#%x%x%x%x%x%x", ""), left, top - outline, right, bottom - outline, tocolor (0, 0, 0, 225), scale, font, alignX, alignY, clip, wordBreak, postGUI, false, subPixelPositioning, fRotation, fRotationCenterX, fRotationCenterY)
        dxDrawText (text:gsub("#%x%x%x%x%x%x", ""), left, top + outline, right, bottom + outline, tocolor (0, 0, 0, 225), scale, font, alignX, alignY, clip, wordBreak, postGUI, false, subPixelPositioning, fRotation, fRotationCenterX, fRotationCenterY)
        dxDrawText (text, left, top, right, bottom, color, scale, font, alignX, alignY, clip, wordBreak, postGUI, colorCoded, subPixelPositioning, fRotation, fRotationCenterX, fRotationCenterY)
    end

    local showCursorPos = false
    addCommandHandler( "showCursorPos", function ()
        showCursorPos = not showCursorPos
        showCursor( showCursorPos )
    end )

    local showSDXStat = true
    addCommandHandler( "showSDXStat", function ()
        showSDXStat = not showSDXStat
    end )

    local systemInfo = {
        VideoCardName = {"Видеокарта:", ""},
        VideoCardRAM = {"Видео память:", " MB"},
        VideoMemoryFreeForMTA = {"Свободной памяти для МТА:", " MB"},
        VideoMemoryUsedByFonts = {"Память для шрифтов:", " MB"},
        VideoMemoryUsedByTextures = {"Память для текстур:", " MB"},
        VideoMemoryUsedByRenderTargets = {"Память для рендеров:", " MB"},
    }

    local beginY = 520
    local columnX = screenW - 580
    local infoX =  screenW - 300

    addEventHandler( "onClientRender", root, function ()

        if showSDXStat then

            dxDrawRectangle( screenW - 600, 500, 600, screenH-500, 0x80000000 )

            local _, sdxCPU = getPerformanceStats( "Lua timing", "5", "sdxLib" )
            local _, sdxMEM = getPerformanceStats( "Lua memory", "", "sdxLib" )


            local cpu
            for _, res in pairs( sdxCPU ) do
                if res[1] == "sdxLib" then cpu = res[2] end
            end

            local mem
            local maxMem
            local elements = 0
            for _, res in pairs( sdxMEM ) do
                if res[1] == "sdxLib" then
                    mem = res[3]
                    maxMem = res[4]
                    elements = res[8]
                end
            end

            dxDrawText( "CPU:", columnX, beginY, screenW, screenH, 0xFFFFFFFF, 1.5, "arial", "left", "top" )
            dxDrawText( cpu or "N/A", infoX, beginY, screenW, screenH, 0xFFFFFFFF, 1.5, "arial", "left", "top" )

            dxDrawText( "ОЗУ:", columnX, beginY + 25, screenW, screenH, 0xFFFFFFFF, 1.5, "arial", "left", "top" )
            dxDrawText( mem or "N/A", infoX, beginY + 25, screenW, screenH, 0xFFFFFFFF, 1.5, "arial", "left", "top" )
            
            dxDrawText( "Макс. ОЗУ:", columnX, beginY + 50, screenW, screenH, 0xFFFFFFFF, 1.5, "arial", "left", "top" )
            dxDrawText( maxMem or "N/A", infoX, beginY + 50, screenW, screenH, 0xFFFFFFFF, 1.5, "arial", "left", "top" )

            local sdxVideo = dxGetStatus()

            local i = 0
            for key, name in pairs( systemInfo ) do
                dxDrawText( name[1], columnX, beginY + 100 + i*25, screenW, screenH, 0xFFFFFFFF, 1.5, "arial", "left", "top" )
                dxDrawText( (sdxVideo[key] or "N/A")..name[2], infoX, beginY + 100 + i*25, screenW, screenH, 0xFFFFFFFF, 1.5, "arial", "left", "top" )
                i = i + 1
            end

            dxDrawText( "SDX Roots:", columnX, beginY + 275, screenW, screenH, 0xFFFFFFFF, 1.5, "arial", "left", "top" )
            dxDrawText( #getElementsByType( "sdxRoot" ), infoX, beginY + 275, screenW, screenH, 0xFFFFFFFF, 1.5, "arial", "left", "top" )

            dxDrawText( "Шрифтов всего:", columnX, beginY + 300, screenW, screenH, 0xFFFFFFFF, 1.5, "arial", "left", "top" )
            dxDrawText( #getElementsByType( "dx-font" ), infoX, beginY + 300, screenW, screenH, 0xFFFFFFFF, 1.5, "arial", "left", "top" )

            dxDrawText( "Текстур всего:", columnX, beginY + 325, screenW, screenH, 0xFFFFFFFF, 1.5, "arial", "left", "top" )
            dxDrawText( #getElementsByType( "texture" ), infoX, beginY + 325, screenW, screenH, 0xFFFFFFFF, 1.5, "arial", "left", "top" )

            dxDrawText( "Элементов всего:", columnX, beginY + 350, screenW, screenH, 0xFFFFFFFF, 1.5, "arial", "left", "top" )
            dxDrawText( elements, infoX, beginY + 350, screenW, screenH, 0xFFFFFFFF, 1.5, "arial", "left", "top" )

        end

        if showCursorPos then
            local cx, cy = getCursorPosition()
            cx, cy = cx*screenW, cy*screenH
            dxDrawBorderedText( 1, "x: "..math.round(cx).." y:"..math.round(cy), cx+20, cy, screenW, screenH, 0xFFFFFFFF, 1.2, "default", "left", "top", false, false, true )
        end
    end )

end

if CREATE_TEST_ELEMENT then
    sdxRoot = createElement( "sdxRoot" )
    showCursor(true)

    local element = createElement( "sdxList" )
    setElementParent( element, sdxRoot )

    setSDXData( element, "visible", true )
    setSDXData( element, "enable", true )
    setSDXData( element, "position", { x = 200, y = 200, rot=0 } )
    setSDXData( element, "size", { w = 500, h = 300 } )
    setSDXData( element, "color", {
        [STATE_UNDEFINED] = 0xFFFFFFFF,
        --[STATE_DEFAULT] = 0xFFFFFFFF,
        --[STATE_HOVERED] = 0xD900FF00,
        --[STATE_PRESSED] = 0x800000FF,
    } )
    setSDXData( element, "roundedCorners", { 20, 20, 20, 20 } )
    setSDXData( element, "content", { x = 0, y = 0, w = 700, h = 700 } )
    --setSDXData( element, "progress",100 )
    --setSDXData( element, "progress_color", 0xFFFFFF00 )
    --setSDXData( element, "progress_vector", "vertical" )
    --setSDXData( element, "text", "" )
    --setSDXData( element, "textSettings", { font = "arial", scale="1.5", alignX = "left", alignY = "center" } )
    --setSDXData( element, "editSettings", { maxLength = 1000, placeholder="placeholder", masked = false, symbols = "space,0-9,a-Z,а-Я,#" } )
    setSDXData( element, "tabs", {10, 10, 10, 10} )
    setSDXData( element, "header", {
        text = { scale = 1, font = "arial" },
        color = 0xFFFF0000,
        tabs = { 0, 0 },
        aligns = { "center", "center" },
        height = 50,
    } )

    setSDXData( element, "columns", {
        {
            width = 100,
            header = "Column 1",
        },
        {
            width = 150,
            header = "Column 2",
        }
    } )

    setSDXData( element, "rows", {
        {
            items = {
                { text = "ITEM 1", tabs = { 10, 10 }, color = {
                    [STATE_UNDEFINED] = 0xFFF00FFF,
                    [STATE_DEFAULT] = 0xFFF00FFF,
                    [STATE_HOVERED] = 0xD900FF00,
                    [STATE_PRESSED] = 0x800000FF,
                    [STATE_SELECTED] = { [STATE_UNDEFINED] = 0xFFFF0000 },
                } },
                { text = "ITEM 2", tabs = { 10, 10 } },
            }
        },
        {
            items = {
                { text = "ITEM 3", tabs = { 10, 10 } },
                { text = "ITEM 4", tabs = { 10, 10 } },
            },
            color = {
                [STATE_UNDEFINED] = 0xFFFFF00F,
                [STATE_DEFAULT] = 0xFFF00FFF,
                [STATE_HOVERED] = 0xD900FF00,
                [STATE_PRESSED] = 0x800000FF,
                [STATE_SELECTED] = { [STATE_UNDEFINED] = 0xFFFF0000 },
            }
        },
        {
            items = {
                { text = "ITEM 5", tabs = { 10, 10 } },
                { text = "ITEM 6", tabs = { 10, 10 } },
            }
        },
        {
            items = {
                { text = "ITEM 7", tabs = { 10, 10 } },
                { text = "ITEM 8", tabs = { 10, 10 } },
            }
        },
        {
            items = {
                { text = "ITEM 9", tabs = { 10, 10 } },
                { text = "ITEM 10", tabs = { 10, 10 } },
            }
        },
        {
            items = {
                { text = "ITEM 11", tabs = { 10, 10 } },
                { text = "ITEM 12", tabs = { 10, 10 } },
            }
        },
        {
            items = {
                { text = "ITEM 13", tabs = { 10, 10 } },
                { text = "ITEM 14", tabs = { 10, 10 } },
            }
        }
    } )

    setSDXData( element, "list", {
        solid = true,
        colTab = 20,
        rowTab = 20,
        rounded = {10,10,10,10},
        rowHeight = 90,
        rowTextTabs = { 20, 20 },
        rowTextAligns = { "center", "center" },
        rowColor = {
            [STATE_UNDEFINED] = 0xFFFFF00F,
            [STATE_DEFAULT] = 0xFFF00FFF,
            [STATE_HOVERED] = 0xD900FF00,
            [STATE_PRESSED] = 0x800000FF,
            [STATE_SELECTED] = { [STATE_UNDEFINED] = 0xFFFF0000 },
        }
        
    } )


    local function createDefaultElement( elementType, x, y, w, h, color, parent )
        if not elementType or elementType == "sdxRoot" then return end
        local element = createElement( elementType )
        setElementParent( element, parent or sdxRoot )
    
        setSDXData( element, "position", { x = x, y = y, rot = 0 }, true )
        setSDXData( element, "size", { w = w, h = h }, true )
        setSDXData( element, "color", { [STATE_UNDEFINED] = color }, true )
        setSDXData( element, "visible", true, true )
        setSDXData( element, "enable", true )
        return element
    end

    local scroll_v = createDefaultElement( "sdxScroll", 200 + 500, 200, 10, 300, 0xFFFFFFFF, element )
    setSDXData( scroll_v, "scroll", { vector = "vertical" } )

    local scroll_h = createDefaultElement( "sdxScroll", 200, 200 + 300, 500, 10, 0xFFFFFFFF, element )
    setSDXData( scroll_h, "scroll", { vector = "horizontal" } )

    setSDXData( element, "scrollingElements", { v = scroll_v, h = scroll_h } )

    updateElement( element )
    updateElement(scroll_v)
    updateElement(scroll_h)

    --[[local element1 = createElement( "sdxScroll" )
    setElementParent( element1, element )

    setSDXData( element1, "visible", true )
    setSDXData( element1, "enable", true )
    setSDXData( element1, "position", { x = 320, y = 200, rot=0 } )
    setSDXData( element1, "size", { w = 20, h = 200 } )
    setSDXData( element1, "color", {
        [STATE_UNDEFINED] = 0xFF000000,
        [STATE_DEFAULT] = 0xFFFF0000,
        [STATE_HOVERED] = 0xD900FF00,
        [STATE_PRESSED] = 0x800000FF,
    } )
    setSDXData( element1, "roundedCorners", { 10, 10, 10, 10 } )
    setSDXData( element1, "scroll", { bg = 0x80000000 } )
    --setSDXData( element, "progress",100 )
    --setSDXData( element, "progress_color", 0xFFFFFF00 )
    --setSDXData( element, "progress_vector", "vertical" )
    --setSDXData( element, "text", "" )
    --setSDXData( element, "textSettings", { font = "arial", scale="1.5", alignX = "left", alignY = "center" } )
    --setSDXData( element, "editSettings", { maxLength = 1000, placeholder="placeholder", masked = false, symbols = "space,0-9,a-Z,а-Я,#" } )
    --setSDXData( element, "tabs", {40, 10, 10, 10} )
    updateElement( element1 )]]

end

--[[
    ElementDates:
    position - { x=px, y=px }
    size - { w=px, h=px }
    color - { undefined = int, default = int, hovered = int, pressed = int }
    roundedCorners - { px, px, px, px }
    roundBarSettings - { thickness = px, isClockwise = bool }
    progress - int
    progress_color - int
    progress_vector - string
    gradient - { color = int, rot = int }
    texture - Elem: texture
    roundBarShader - Elem: shader round bar
    roundedShader - Elem: shader rounded
    text_texture - Elem: text texture
    text - string
    textSettings - { font = dxFont(string), scale = int, alignX = string, alignY = string, marked=bool(int) }
    visible - bool
    enable - bool
    scroll - { bg = int, vector = string }
    content - { x = int, y = int, w = int, h = int }
    scroll_step - int
    scrollingElements - {v = scroll, h = scroll}
    slider - Elem: shader rounded
    addTexture - Elem: additionally texture
    border - { size = int, color = color, transparent = bool }
]]