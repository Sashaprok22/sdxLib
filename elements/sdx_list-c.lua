
function drawList( element, offsetX, offsetY, render )
    if not isElement( element ) then return end
    local texture = getSDXData( element, "texture" )
    local addTexture = getSDXData( element, "addTexture" )
    local shader = getSDXData( element, "roundedShader" )
    local pos, size = getSDXData( element, "position" ) or {x=0,y=0,rot=0}, getSDXData( element, "size" ) or {w=0,h=0}
    local colorStates = getSDXData( element, "color" ) or { [STATE_UNDEFINED] = 0xFFFFFFFF }
    local enable = getSDXData( element, "enable" )
    local tabs = getSDXData( element, "tabs" ) or {0,0,0,0}

    local columns = getSDXData( element, "columns" ) or {}
    local rows = getSDXData( element, "rows" ) or {}
    local listSets = getSDXData( element, "list" ) or {}
    local headSets = getSDXData( element, "header" ) or { height = 0 }
    local selectedItem = getSDXData( element, "selectedItem" ) or {}
    local textSettings = getSDXData( element, "textSettings" ) or { scale = 1, font = "default" }

    local content = getSDXData( element, "content" ) or {x=0,y=0,w=0,h=0}

    local rPos = {x=0,y=0,rot=0}
    local rSize = {w=99999,h=99999}
    if isElement( render ) then
        rPos = getSDXData( render, "position" ) or rPos
        rSize = getSDXData( render, "size" ) or rSize
    end
    pos.x, pos.y = pos.x + offsetX - rPos.x, pos.y + offsetY - rPos.y

    local tX = pos.x + tabs[1]
    local tY = pos.y + headSets.height + tabs[2]
    local tW = size.w - tabs[1] - tabs[3]
    local tH = size.h - headSets.height - tabs[2] - tabs[4]

    local mouseActive = getKeyState( "mouse1" ) or getKeyState( "mouse2" )

    local color = colorStates[STATE_DEFAULT] or colorStates[STATE_UNDEFINED]
    local isBgHovered = false
    if isCursorOnElement( rPos.x, rPos.y, rSize.w, rSize.h, rPos.rot or 0 ) and isCursorOnElement( pos.x + rPos.x, pos.y + rPos.y, size.w, size.h, pos.rot or 0 ) then
        if enable then
            if mouseActive then
                color = colorStates[STATE_PRESSED] or colorStates[STATE_UNDEFINED]
            else
                color = colorStates[STATE_HOVERED] or colorStates[STATE_UNDEFINED]
            end

            if not tHoveredSpaces[element] then
                triggerEvent( "onSdxElementHovered", element, true )
                tHoveredSpaces[element] = true
            end
            if isCursorOnElement( tX, tY, tW, tH, pos.rot or 0 ) then
                isBgHovered = true
            end
        end

    elseif tHoveredSpaces[element] then
        triggerEvent( "onSdxElementHovered", element )
        tHoveredSpaces[element] = nil
    end

    local shaderExists = isElement( shader )
    if shaderExists then
        dxSetShaderValue( shader, "textureLoad", false )
        dxSetShaderValue( shader, "radius", listSets.rounded or {0,0,0,0} )
    end

    -- ROWS
    dxSetRenderTarget( texture, true )

    local defaultRowColors = listSets.rowColor or { [STATE_UNDEFINED] = 0xFFFFFFFF, [STATE_SELECTED] = { [STATE_UNDEFINED] = 0xFFFFFFFF } }
    local offsetRow = -content.y

    for rowI, row in ipairs( rows ) do
        local rowColors = row.color or defaultRowColors

        local rowWidth = 0
        for i, col in ipairs( columns ) do
            if not listSets.solid then
                local itemColors = row.items[i].color or rowColors
                itemColors = (selectedItem.row == rowI and selectedItem.item == i) and itemColors[STATE_SELECTED] or itemColors
                local itemColor = itemColors[STATE_DEFAULT] or itemColors[STATE_UNDEFINED]
                if isBgHovered and isCursorOnElement( -content.x + tX + rowWidth + (i-1) * (listSets.colTab or 0), tY + offsetRow, col.width, listSets.rowHeight, 0 ) then
                    if mouseActive then
                        itemColor = itemColors[STATE_PRESSED] or itemColors[STATE_UNDEFINED]
                    else
                        itemColor = itemColors[STATE_HOVERED] or itemColors[STATE_UNDEFINED]
                    end
                end
                dxDrawImage( -content.x + rowWidth + (i-1) * (listSets.colTab or 0), offsetRow, col.width, listSets.rowHeight, shaderExists and shader or whiteTexture, 0, 0, 0, itemColor ) -- TODO: Подмутить цвет selected
            end

            rowWidth = rowWidth + (col.width or 0)
        end

        if listSets.solid then
            rowColors = selectedItem.row == rowI and rowColors[STATE_SELECTED] or rowColors
            local rowColor = rowColors[STATE_DEFAULT] or rowColors[STATE_UNDEFINED]
            if isCursorOnElement( -content.x + tX, tY + offsetRow, rowWidth, listSets.rowHeight, 0 ) then
                if mouseActive then
                    rowColor = rowColors[STATE_PRESSED] or rowColors[STATE_UNDEFINED]
                else
                    rowColor = rowColors[STATE_HOVERED] or rowColors[STATE_UNDEFINED]
                end
            end

            dxDrawImage( -content.x, offsetRow, rowWidth, listSets.rowHeight, shaderExists and shader or whiteTexture, 0, 0, 0, rowColor ) -- TODO: Подмутить цвет row
        end

        rowWidth = 0
        for i, col in ipairs( columns ) do

            if row.items[i] then
                local itemSets = row.items[i]
                local itemTabs = itemSets.tabs or listSets.rowTextTabs or {0,0}
                local aligns = itemSets.aligns or listSets.rowTextAligns or { "left", "center" }

                local lX = -content.x + rowWidth + (i-1) * (listSets.colTab or 0) + (itemTabs[1] or 0)
                local tY = offsetRow + (itemTabs[2] or 0)
                local rX = -content.x + rowWidth + (i-1) * (listSets.colTab or 0) + col.width - (itemTabs[1] or 0)
                local bY = offsetRow + listSets.rowHeight - (itemTabs[2] or 0)

                dxDrawText( itemSets.text, lX, tY, rX, bY, 0xFFFFFFFF, isElement( textSettings.font ) and 1 or textSettings.scale, textSettings.font, aligns[1] or "left", aligns[2] or "center", true, false, false, false )
            end

            rowWidth = rowWidth + (col.width or 0)
        end

        

        offsetRow = offsetRow + listSets.rowHeight + (listSets.rowTab or 0)
    end

    -- COLS
    dxSetRenderTarget( addTexture, true )

    local columns = getSDXData( element, "columns" ) or {}
    local headText = headSets.text or { scale = 1, font = "default" }

    local offsetHead = -content.x
    for i, cols in ipairs( columns ) do
        local color = cols.headColor or headSets.color or 0xFFFFFFFF
        local headTabs = cols.headTabs or headSets.tabs or {0,0}
        local aligns = cols.headAligns or headSets.aligns or { "left", "top" }

        local lX = offsetHead + (headTabs[1] or 0) + (i-1) * ( listSets.colTab or 0 )
        local tY = headTabs[2] or 0
        local rX = offsetHead + (cols.width or 0) - (headTabs[1] or 0) + (i-1) * ( listSets.colTab or 0 )
        local bY = (headSets.height or 0) - (headTabs[2] or 0)

        dxDrawText( cols.header or "", lX, tY, rX, bY, color, isElement( headText.font ) and 1 or headText.scale, headText.font, aligns[1] or "left", aligns[2] or "top", false, false, false, true )
        offsetHead = offsetHead + (cols.width or 0)
    end

    dxSetRenderTarget( render )
    -------

    if shaderExists then
        dxSetShaderValue( shader, "radius", getSDXData( element, "roundedCorners" ) or {0,0,0,0} )
        dxDrawImage( pos.x, pos.y, size.w, size.h, shader, pos.rot, 0,0, color )
        dxSetShaderValue( shader, "textureLoad", true )
    else
        dxDrawImage( pos.x, pos.y, size.w, size.h, whiteTexture, pos.rot, 0,0, color )
    end

    dxSetBlendMode( "add" )
    if isElement( addTexture ) then
        if shaderExists then dxSetShaderValue( shader, "sourceTexture", addTexture ) end
        dxDrawImage( pos.x + tabs[1], pos.y + tabs[2], size.w - tabs[1] - tabs[3], headSets.height, shaderExists and shader or addTexture, pos.rot, 0,0, 0xFFFFFFFF )
    end

    if isElement( texture ) then
        if shaderExists then dxSetShaderValue( shader, "sourceTexture", texture ) end
        dxDrawImage( tX, tY, tW, tH, shaderExists and shader or texture, pos.rot, 0,0, 0xFFFFFFFF )
    end

    dxSetBlendMode( "blend" )
end

function updateList( element )
    if not isElement( element ) then return end
    local texture = getSDXData( element, "texture" )
    local size = getSDXData( element, "size" ) or { w = 1, h = 1 }
    local tabs = getSDXData( element, "tabs" ) or {0,0,0,0}
    local headSets = getSDXData( element, "header" ) or { height = 0 }
    local listSets = getSDXData( element, "list" ) or { colTab = 0 }

    if isElement( texture ) then
        local rw, rh = dxGetMaterialSize( texture )
        if rw ~= math.floor( size.w - tabs[1] - tabs[3] ) or rh ~= math.floor( size.h - tabs[2] - tabs[4] - (headSets.height or 0) ) then destroyElement( texture ) end
    end
    if not isElement( texture ) then
        texture = dxCreateRenderTarget( math.floor( size.w - tabs[1] - tabs[3] ), math.floor( size.h - tabs[2] - tabs[4] - (headSets.height or 0) ), true )
        setSDXData( element, "texture", texture, true )
    end

    -- HEADERS

    local addTexture = getSDXData( element, "addTexture" )
    local aW, aH = size.w - tabs[1] - tabs[3], headSets.height or 0
    if isElement( addTexture ) then
        local rw, rh = dxGetMaterialSize( addTexture )
        if rw ~= math.floor( aW ) or rh ~= math.floor( aH ) then destroyElement( addTexture ) end
    end
    if not isElement( addTexture ) then
        addTexture = dxCreateRenderTarget( math.floor( aW ), math.floor( aH ), true )
        setSDXData( element, "addTexture", addTexture, true )
    end

    dxSetRenderTarget( addTexture, true )

    local columns = getSDXData( element, "columns" ) or {}
    local headText = headSets.text or { scale = 1, font = "default" }

    local offsetHead = 0
    for i, cols in ipairs( columns ) do
        local color = cols.headColor or headSets.color or 0xFFFFFFFF
        local headTabs = cols.headTabs or headSets.tabs or {0,0}
        local aligns = cols.headAligns or headSets.aligns or { "left", "top" }

        local lX = offsetHead + (headTabs[1] or 0) + (i-1) * ( listSets.colTab or 0 )
        local tY = headTabs[2] or 0
        local rX = offsetHead + (cols.width or 0) - (headTabs[1] or 0) + (i-1) * ( listSets.colTab or 0 )
        local bY = (headSets.height or 0) - (headTabs[2] or 0)

        dxDrawText( cols.header or "", lX, tY, rX, bY, color, headText.scale, headText.font, aligns[1] or "left", aligns[2] or "top", false, false, false, true )
        offsetHead = offsetHead + (cols.width or 0)
    end

    dxSetRenderTarget()

    ----------

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

--[[
    columns:
    {
        {
            width = w,
            headColor = color,
            headTabs = { x, y },
            headAligns = { x, y },
            header = textHeader,
        }
    }

    header:
    {
        text = { scale = int, font = font },
        color = color,
        tabs = { x, y },
        aligns = { x, y },
        height = int,
    }

    list:
    {
        colTab = int,
        rowTab = int,
        solid = bool,
        rowHeight = int,
        rowColor = colorTable,
    }
    selectedItem = mixed
]]