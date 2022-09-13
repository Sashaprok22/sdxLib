tHoveredSpaces = {}
function drawSpace( element, offsetX, offsetY, render )
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

            if not tHoveredSpaces[element] then
                triggerEvent( "onSdxElementHovered", element, true )
                tHoveredSpaces[element] = true
            end
        end

    elseif tHoveredSpaces[element] then
        triggerEvent( "onSdxElementHovered", element )
        tHoveredSpaces[element] = nil
    end

    dxSetBlendMode( "add" )
    if isElement( texture ) then dxDrawImage( pos.x, pos.y, size.w, size.h, texture, pos.rot, 0,0, color ) end
    dxSetBlendMode( "blend" )
end

function updateSpace( element )
    if not isElement( element ) then return end
    local texture = getSDXData( element, "texture" )
    local size = getSDXData( element, "size" ) or { w = 1, h = 1 }

    if isElement( texture ) then
        local rw, rh = dxGetMaterialSize( texture )
        if rw ~= math.floor( size.w ) or rh ~= math.floor( size.h ) then destroyElement( texture ) end
    end
    if not isElement( texture ) then
        texture = dxCreateRenderTarget( math.floor( size.w ), math.floor( size.h ), true )
        setSDXData( element, "texture", texture, true )
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