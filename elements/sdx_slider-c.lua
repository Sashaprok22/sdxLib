local tHovered = {}

function drawSlider( element, offsetX, offsetY, render )
    if not isElement( element ) then return end
    local texture = getSDXData( element, "roundedShader" ) or getSDXData( element, "texture" )
    local pos, size = getSDXData( element, "position" ) or {x=0,y=0,rot=0}, getSDXData( element, "size" ) or {w=0,h=0}
    local colorStates = getSDXData( element, "color" ) or { [STATE_UNDEFINED] = 0xFFFFFFFF }
    local enable = getSDXData( element, "enable" )
    
    local slider = getSDXData( element, "slider" )
    local scroll = getSDXData( element, "scroll" ) or {}
    local progressColor = getSDXData( element, "progress_color" ) or 0xFF000000
    local progress = getSDXData( element, "progress" ) or 0

    local rPos = {x=0,y=0,rot=0}
    local rSize = {w=99999,h=99999}
    if isElement( render ) then
        rPos = getSDXData( render, "position" ) or rPos
        rSize = getSDXData( render, "size" ) or rSize
    end
    pos.x, pos.y = pos.x + offsetX - rPos.x, pos.y + offsetY - rPos.y

    local sizeSlider = math.min( size.w, size.h )
    local sX, sY, sW, sH = pos.x, pos.y, sizeSlider*2, sizeSlider*2
    if scroll.vector == "horizontal" then
        sX = (sX + size.w/100*progress) - sizeSlider
        sY = sY - sizeSlider + size.h/2
    else
        sY = (sY + size.h - size.h/100*progress) - sizeSlider
        sX = sX - sizeSlider + size.w/2
    end

    local color = colorStates[STATE_DEFAULT] or colorStates[STATE_UNDEFINED]
    if isCursorOnElement( rPos.x, rPos.y, rSize.w, rSize.h, rPos.rot or 0 ) and isCursorOnElement( sX + rPos.x, sY + rPos.y, sW, sH, pos.rot or 0 ) then
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
        dxDrawImage( pos.x, pos.y, size.w, size.h, texture, 0,0,0, scroll.bg or 0xFFFFFFFF )

        if progress > 0 then
            local tabs = getSDXData( element, "tabs" ) or { 0, 0, 0, 0 }
            local roundedCorners = getSDXData( element, "roundedCorners" ) or { 0, 0, 0, 0 }
            local x, y, w, h = pos.x, pos.y, size.w, size.h
            if scroll.vector == "horizontal" then
                x = x + tabs[1]
                y = y + tabs[2]
                w = w - tabs[1] - tabs[3]
                h = h - tabs[2] - tabs[4]

                w = w/100*progress
                if w < math.max( unpack( roundedCorners ) )*2 then w = math.max( unpack( roundedCorners ) )*2 end

            else
                x = x + tabs[1]
                y = y + tabs[2]
                w = w - tabs[1] - tabs[3]
                h = h - tabs[2] - tabs[4]

                y = y + h
                h = h/100*progress
                if h < math.max( unpack( roundedCorners ) )*2 then h = math.max( unpack( roundedCorners ) )*2 end

                y = y - h
            end
            dxDrawImage( x, y, w, h, texture, 0,0,0, progressColor )
        end
    end
    dxSetBlendMode( old_blend )

    if isElement( slider ) then dxDrawImage( sX, sY, sW, sH, slider, 0,0,0, color ) end
end

function updateSlider( element )
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

    local slider = getSDXData( element, "slider" )
    if not isElement( slider ) then
        slider = dxCreateShader( shaderRounded )
        setSDXData( element, "slider", slider )
    end
    dxSetShaderValue( slider, "sourceTexture", texture )
    local size = getSDXData( element, "size" ) or { w = 1, h = 1 }
    size = math.min( size.w, size.h )
    dxSetShaderValue( slider, "radius", { size, size, size, size } )
end