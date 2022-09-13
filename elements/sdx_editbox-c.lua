local tHovered = {}
function drawEditBox( element, offsetX, offsetY, render )
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

    local textTexture = getSDXData( element, "text_texture" )
    local tabs = getSDXData( element, "tabs" ) or {0,0,0,0}

    offsetX = pos.x + size.w/2
    offsetY = pos.y + size.h/2
    pos.x = pos.x + tabs[1]
    pos.y = pos.y + tabs[2]
    size.w = size.w - tabs[1] - tabs[3]
    size.h = size.h - tabs[2] - tabs[4]
    offsetX = offsetX - pos.x + size.w/2
    offsetY = offsetY - pos.y + size.h/2

    dxSetBlendMode("add")
    if textTexture then dxDrawImage( pos.x, pos.y, size.w, size.h, textTexture, pos.rot, offsetX, offsetY, colorText ) end
    dxSetBlendMode("blend")

    -- ПАЛОЧКА
    if selectEdit == element and lastTickRectEdit + 700 <= getTickCount() then
        local textSettings = getSDXData( element, "textSettings" ) or { scale = 1, font = "default" }
        local editSettings = getSDXData( element, "editSettings" ) or {}
        local text = getSDXData( element, "text" ) or ""
        local font = textSettings.font or "default"
        local scale = isElement( textSettings.font ) and 1 or textSettings.scale

        local writeText = text
        if editSettings.masked then writeText = string.rep( "*", utf8.len( writeText ) ) end

        local rectLength, textHeight = dxGetTextSize ( "|", 0, scale, font )
        local textLenght = dxGetTextWidth( writeText, scale, font )

        local ax = 0
        if textLenght >= size.w then
            local addLenght = dxGetTextWidth( utf8.sub( writeText, utf8.len( writeText ) - writePosition + 1 ), scale, font )
            if addLenght > size.w then
                local visText = utf8.sub( settings.text, utf8.len( writeText ) - writePosition + 1 )
                local addLenght = dxGetTextWidth( utf8.sub( visText, 1, settings.tabEdit ), scale, font )
                ax = ax - ( textLenght - size.w ) + addLenght
            else
                ax = ax - ( textLenght - size.w )
            end
                
        end

        local textLenghtRectRight = writePosition > 0 and dxGetTextWidth( utf8.sub( writeText, -writePosition ), scale, font ) or 0
        if textSettings.alignX == "left" then 
            local textLenghtRect = dxGetTextWidth( utf8.sub( writeText, 1, -1 - writePosition ), scale, font )
            pos.x = pos.x + ax + textLenghtRect
            
        elseif textSettings.alignX == "right" then
            pos.x = pos.x + size.w - textLenghtRectRight

        elseif textSettings.alignX == "center" then
            local new_w = ( size.w/2 + textLenght/2 ) - textLenghtRectRight
            if new_w > size.w then new_w = size.w end
            pos.x = pos.x + new_w
        end

        if textSettings.alignY == "bottom" then pos.y = pos.y + size.h - textHeight
        elseif textSettings.alignY == "center" then pos.y = pos.y + size.h / 2 - textHeight / 2 end

        dxDrawRectangle( pos.x, pos.y, 2, textHeight, colorText or 0xFFFFFFFF )
        if lastTickRectEdit + 1400 <= getTickCount() then lastTickRectEdit = getTickCount() end
    end
end

function updateEditBox( element, clickArrow )
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

    local size = getSDXData( element, "size" ) or {w=1, h=1}
    local tabs = getSDXData( element, "tabs" ) or {0,0,0,0}
    size.w = size.w - tabs[1] - tabs[3]
    size.h = size.h - tabs[2] - tabs[4]

    local textTexture = getSDXData( element, "text_texture" )
    local textSettings = getSDXData( element, "textSettings" ) or { scale = 1, font = "default" }
    local editSettings = getSDXData( element, "editSettings" ) or {}
    local tabEdit = getSDXData( element, "tabEdit" ) or 0
    local text = getSDXData( element, "text" ) or ""

    if isElement( textTexture ) then
        local rw, rh = dxGetMaterialSize( textTexture )
        if rw ~= math.floor( size.w ) or rh ~= math.floor( size.h ) then destroyElement( textTexture ) end
    end

    if not isElement( textTexture ) then
        textTexture = dxCreateRenderTarget( math.floor( size.w ), math.floor( size.h ), true )
        setSDXData( element, "text_texture", textTexture )
    end
    
    dxSetRenderTarget( textTexture, true )
    dxSetBlendMode( "modulate_add" )
        local font = textSettings.font or "default"
        local scale = isElement( textSettings.font ) and 1 or textSettings.scale

        local onElement = selectEdit == element or utf8.len( text ) > 0
        if onElement then
            if editSettings.masked then text = string.rep( "*", utf8.len( text ) ) end
            local textLenght = dxGetTextWidth( text, scale, font )

            local x = 0
            if textLenght >= size.w then
                local writePos = selectEdit == element and writePosition or 0
                local addLenght = dxGetTextWidth( utf8.sub( text, utf8.len( text ) - writePos + 1 ), scale, font )
                if addLenght > size.w then
                    if clickArrow == "l" then
                        setSDXData( element, "tabEdit", tabEdit+1 )
                        tabEdit = tabEdit + 1
                    else
                        if tabEdit > 0 then
                            setSDXData( element, "tabEdit", tabEdit-1 )
                            tabEdit = tabEdit - 1
                        end
                    end

                    local visText = utf8.sub( text, utf8.len( text ) - writePos + 1 )
                    local addLenght = dxGetTextWidth( utf8.sub( visText, 1, tabEdit ), scale, font )
                    x = x - ( textLenght - size.w ) + addLenght

                else
                    if tabEdit and tabEdit ~= 0 then setSDXData( element, "tabEdit", nil ) end
                    x = x - ( textLenght - size.w )
                end

            end
            dxDrawText( text or "", x, 0, size.w, size.h, 0xFFFFFFFF, scale, font, textSettings.alignX, textSettings.alignY )
        else
            dxDrawText( editSettings.placeholder or "", 0, 0, size.w, size.h, 0xFFFFFFFF, scale, font, textSettings.alignX, textSettings.alignY )
        end

    dxSetBlendMode( "blend" )
    dxSetRenderTarget()

end