local textureMarked = createWhiteTexture()

local tHovered = {}
function drawLabel( element, offsetX, offsetY, render )
    if not isElement( element ) then return end
    local pos, size = getSDXData( element, "position" ) or {x=0,y=0,rot=0}, getSDXData( element, "size" ) or {w=0,h=0}
    local colorStates = getSDXData( element, "color" ) or { [STATE_UNDEFINED] = 0xFFFFFFFF }
    local enable = getSDXData( element, "enable" )

    local rPos = {x=0,y=0,rot=0}
    local rSize = {w=99999,h=99999}
    if isElement( render ) then
        rPos = getSDXData( render, "position" ) or rPos
        rSize = getSDXData( render, "size" ) or rSize
    end
    pos.x, pos.y = pos.x + offsetX - rPos.x, pos.y + offsetY - rPos.y

    local color = colorStates[STATE_DEFAULT] or colorStates[STATE_UNDEFINED]
    if isCursorOnElement( rPos.x, rPos.y, rSize.w, rSize.h, rPos.rot or 0 ) and isCursorOnElement( pos.x + rPos.x, pos.y + rPos.y, size.w, size.h, pos.rot or 0 ) then
        if enable then
            if getKeyState( "mouse1" ) or getKeyState( "mouse2" ) then
                color = colorStates[STATE_PRESSED] or colorStates[STATE_UNDEFINED]
            else
                color = colorStates[STATE_HOVERED] or colorStates[STATE_UNDEFINED]
            end

            if not tHovered[element] then
                triggerEvent( "onSdxElementHovered", element, true )
                tHovered[element] = true
            end
        end

    elseif tHovered[element] then
        triggerEvent( "onSdxElementHovered", element )
        tHovered[element] = nil
    end

    local textSettings = getSDXData( element, "textSettings" ) or { scale = 1, font = "default" }
    local text = getSDXData( element, "text" ) or ""
    if textSettings.marked then dxDrawImage( pos.x, pos.y, size.w, size.h, textureMarked, pos.rot, 0,0, textSettings.marked ) end
    dxDrawText( text, pos.x, pos.y, size.w + pos.x, size.h + pos.y, color, isElement( textSettings.font ) and 1 or textSettings.scale, textSettings.font or "default", textSettings.alignX, textSettings.alignY, false, false, false, true, false, pos.rot or 0 )
end