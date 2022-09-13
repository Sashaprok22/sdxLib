local tHovered = {}
function drawProgressBar( element, offsetX, offsetY, render )
    if not isElement( element ) then return end
    local texture = getSDXData( element, "roundedShader" ) or getSDXData( element, "texture" )
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
    local old_blend = dxGetBlendMode()
    dxSetBlendMode( "blend" )
    if isElement( texture ) then
        dxDrawImage( pos.x, pos.y, size.w, size.h, texture, pos.rot, 0,0, color )

        local progress = getSDXData( element, "progress" ) or 0
        if progress > 0 then
            local progressColor = getSDXData( element, "progress_color" ) or 0xFF000000
            local progressVector = getSDXData( element, "progress_vector" ) or "horizontal"
            local tabs = getSDXData( element, "tabs" ) or { 0, 0, 0, 0 }
            local roundedCorners = getSDXData( element, "roundedCorners" ) or { 0, 0, 0, 0 }
            local offsetX, offsetY = 0, 0
            if progressVector == "horizontal" then
                offsetX = pos.x + size.w/2
                offsetY = pos.y + size.h/2
                pos.x = pos.x + tabs[1]
                pos.y = pos.y + tabs[2]
                size.w = size.w - tabs[1] - tabs[3]
                size.h = size.h - tabs[2] - tabs[4]

                size.w = size.w/100*progress
                if size.w < math.max( unpack( roundedCorners ) )*2 then size.w = math.max( unpack( roundedCorners ) )*2 end
                offsetX = offsetX - pos.x + size.w/2
                offsetY = offsetY - pos.y + size.h/2

            else
                offsetX = pos.x + size.w/2
                offsetY = pos.y + size.h/2
                pos.x = pos.x + tabs[1]
                pos.y = pos.y + tabs[2]
                size.w = size.w - tabs[1] - tabs[3]
                size.h = size.h - tabs[2] - tabs[4]

                pos.y = pos.y + size.h
                size.h = size.h/100*progress
                if size.h < math.max( unpack( roundedCorners ) )*2 then size.h = math.max( unpack( roundedCorners ) )*2 end

                pos.y = pos.y - size.h
                offsetX = offsetX - (pos.x + size.w/2)
                offsetY = offsetY - (pos.y + size.h/2)
            end
            dxDrawImage( pos.x, pos.y, size.w, size.h, texture, pos.rot, offsetX, offsetY, progressColor )
        end
    end
    dxSetBlendMode( old_blend )
    
end

function updateProgressBar( element )
    if not isElement( element ) then return end
    local texture = getSDXData( element, "texture" )
    if not isElement( texture ) then
        texture = createWhiteTexture()
        setSDXData( element, "texture", texture )
    end

    local roundedShader = getSDXData( element, "roundedShader" )
    local roundedCorners = getSDXData( element, "roundedCorners" )
    if roundedCorners then
        if not isElement( roundedShader ) then
            roundedShader = dxCreateShader( shaderRounded )
            setSDXData( element, "roundedShader", roundedShader )
        end
        dxSetShaderValue( roundedShader, "sourceTexture", texture )
        dxSetShaderValue( roundedShader, "radius", roundedCorners )

        local border = getSDXData( element, "border" ) or {}
        if border then
            dxSetShaderValue( roundedShader, "borderWidth", border.size or 0 )
            dxSetShaderValue( roundedShader, "borderColor", { convertColor( border.color or 0xFFFFFFFF ) } )
            dxSetShaderValue( roundedShader, "isTransparent", border.transparent and true or false )
        end

    elseif isElement( roundedShader ) then
        destroyElement( roundedShader )
        setSDXData( element, "roundedShader", nil )
    end
end