--[[Scroll
bg = int,
vector = str,
]]

local tHovered = {}

function getInsideScroll( element, x, y, w, h )
    if not isElement( element ) then return end
    local parent = getElementParent( element )
    if not isElement( parent ) then return x, y, w, h, false end

    local sizep = getSDXData( parent, "size" ) or {w=0,h=0}
    local content = getSDXData( parent, "content" ) or {w=0,h=0,x=0,y=0}
    local scroll = getSDXData( element, "scroll" ) or {}
    local visible = true

    if scroll.vector == "horizontal" then
        local relSize = (content.w < sizep.w and sizep.w or content.w)/w
        x = x + content.x/relSize

        local relSize = content.w/sizep.w
        relSize = relSize < 1 and 1 or relSize
        w = w/relSize

        visible = scroll.always and true or relSize ~= 1

    else
        local relSize =  (content.h < sizep.h and sizep.h or content.h)/h
        y = y + content.y/relSize

        local relSize = content.h/sizep.h
        relSize = relSize < 1 and 1 or relSize
        h = h/relSize

        visible = scroll.always and true or relSize ~= 1
    end
    return x, y, w, h, visible, scroll.vector
end

function drawScroll( element, offsetX, offsetY, render )
    if not isElement( element ) then return end
    local texture = getSDXData( element, "roundedShader" ) or getSDXData( element, "texture" )
    local pos, size = getSDXData( element, "position" ) or {x=0,y=0,rot=0}, getSDXData( element, "size" ) or {w=0,h=0}
    local colorStates = getSDXData( element, "color" ) or { [STATE_UNDEFINED] = 0xFFFFFFFF }
    local enable = getSDXData( element, "enable" )
    local scroll = getSDXData( element, "scroll" ) or {}

    local rPos = {x=0,y=0,rot=0}
    local rSize = {w=99999,h=99999}
    if isElement( render ) then
        rPos = getSDXData( render, "position" ) or rPos
        rSize = getSDXData( render, "size" ) or rSize
    end
    pos.x, pos.y = pos.x + offsetX - rPos.x, pos.y + offsetY - rPos.y

    local x, y, w, h, visible = getInsideScroll( element, pos.x, pos.y, size.w, size.h )

    local color = colorStates[STATE_DEFAULT] or colorStates[STATE_UNDEFINED]
    if isCursorOnElement( rPos.x, rPos.y, rSize.w, rSize.h, rPos.rot or 0 ) and isCursorOnElement( x + rPos.x, y + rPos.y, w, h, pos.rot or 0 ) then
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
    if isElement( texture ) and visible then
        dxSetRenderTarget()

        if tonumber( scroll.bg ) then dxDrawImage( pos.x, pos.y, size.w, size.h, texture, 0,0,0, scroll.bg ) end
        dxDrawImage( x, y, w, h, texture, 0,0,0, color )

        local parent = getElementParent( element )
        if isElement( parent ) then dxSetRenderTarget( getSDXData( parent, "texture" ) ) end
    end
    dxSetBlendMode( old_blend )
end

function updateScroll( element )
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