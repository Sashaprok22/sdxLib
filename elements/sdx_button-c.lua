local tHovered = {}
function drawButton( element, offsetX, offsetY, render )
    if not isElement( element ) then return end
    local texture = getSDXData( element, "roundedShader" ) or getSDXData( element, "texture" )
    local pos, size = getSDXData( element, "position" ) or {x=0,y=0,rot=0}, getSDXData( element, "size" ) or {w=0,h=0}
    local enable = getSDXData( element, "enable" )

    local rPos = {x=0,y=0,rot=0}
    local rSize = {w=99999,h=99999}
    if isElement( render ) then
        rPos = getSDXData( render, "position" ) or rPos
        rSize = getSDXData( render, "size" ) or rSize
    end
    pos.x, pos.y = pos.x + offsetX - rPos.x, pos.y + offsetY - rPos.y

    local colorStates = getSDXData( element, "color" ) or { [STATE_UNDEFINED] = 0xFFFFFFFF }
    local colorStatesText = getSDXData( element, "text_color" ) or { [STATE_UNDEFINED] = 0xFF000000 }

    local color = colorStates[STATE_DEFAULT] or colorStates[STATE_UNDEFINED]
    local colorText = colorStatesText[STATE_DEFAULT] or colorStatesText[STATE_UNDEFINED]
    if isCursorOnElement( rPos.x, rPos.y, rSize.w, rSize.h, rPos.rot or 0 ) and isCursorOnElement( pos.x + rPos.x, pos.y + rPos.y, size.w, size.h, pos.rot or 0 ) then
        if enable then
            if getKeyState( "mouse1" ) or getKeyState( "mouse2" ) then
                color = colorStates[STATE_PRESSED] or colorStates[STATE_UNDEFINED]
                colorText = colorStatesText[STATE_PRESSED] or colorStatesText[STATE_UNDEFINED]
            else
                color = colorStates[STATE_HOVERED] or colorStates[STATE_UNDEFINED]
                colorText = colorStatesText[STATE_HOVERED] or colorStatesText[STATE_UNDEFINED]
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
    if isElement( texture ) then dxDrawImage( pos.x, pos.y, size.w, size.h, texture, pos.rot, 0,0, color ) end
    dxSetBlendMode( old_blend )

    local textSettings = getSDXData( element, "textSettings" ) or { scale = 1, font = "default" }
    local text = getSDXData( element, "text" ) or ""
    local tabs = getSDXData( element, "tabs" ) or {0,0,0,0}

    dxDrawText( text, pos.x + tabs[1], pos.y + tabs[2], size.w - tabs[1] - tabs[3] + pos.x, size.h - tabs[2] - tabs[4] + pos.y, colorText, isElement( textSettings.font ) and 1 or textSettings.scale, textSettings.font or "default", textSettings.alignX, textSettings.alignY, true, false, false, true, false, pos.rot or 0, pos.x + size.w/2, pos.y + size.h/2 )
end

function updateButton( element )
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

        local gradient = getSDXData( element, "gradient" )
        dxSetShaderValue( roundedShader, "gradientState", gradient and true or false )
        if gradient then
            dxSetShaderValue( roundedShader, "gradientTo", { convertColor( gradient.color or 0xFF000000 ) } )
            dxSetShaderValue( roundedShader, "gradientRotation", tonumber( gradient.rot ) or 0 )
        end

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