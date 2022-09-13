sdxRoot = createElement( "sdxRoot" )

STATE_UNDEFINED, STATE_DEFAULT, STATE_HOVERED, STATE_PRESSED, STATE_SELECTED = 0, 1, 2, 3, 4

screenW, screenH = guiGetScreenSize()
fullHDResolutionX, fullHDResolutionY = 1920, 1080

ratio_mul = ( screenW / screenH ) / ( fullHDResolutionX / fullHDResolutionY )
font_mul = screenW / fullHDResolutionX

local elementsWithText = { "sdxButton", "sdxLabel", "sdxEditBox", "sdxList" }
local elementsEditable = { "sdxEditBox" }
local elementsSpaces = { "sdxSpace", "sdxList" }
local sdxElements = { "sdxRectangle", "sdxLabel", "sdxImage", "sdxRoundBar", "sdxProgressBar", "sdxButton", "sdxEditBox", "sdxSpace", "sdxScroll", "sdxSlider", "sdxList" }

sharedFiles = {
    close = ":sharedFunctions/assets/close.dds",
    logo = ":sharedFunctions/assets/logo.dds",
    accept = ":sharedFunctions/assets/accept.dds",
    arrow = ":sharedFunctions/assets/arrow.dds",
}

tFonts = {
    GothamPro = "fonts/gothampro.ttf",
    GothamPro_Bold = "fonts/gothampro_bold.ttf",
    SFPro_Medium = "fonts/sfpro_medium.ttf",
    SFPro_Light = "fonts/sfpro_light.ttf",
    SFPro_Bold = "fonts/sfpro_bold.ttf",
    SFPro_Regular = "fonts/sfpro_regular.ttf",
    Qanelas_Medium = "fonts/qanelas_medium.ttf",
    Qanelas_Regular = "fonts/qanelas_regular.ttf",
    Qanelas_Bold = "fonts/qanelas_bold.ttf",
    Gilroy_Bold = "fonts/gilroy_bold.ttf",
    Gilroy_Semibold = "fonts/gilroy_semibold.ttf",
    Gilroy_Medium = "fonts/gilroy_medium.ttf",
    Gilroy_Regular = "fonts/gilroy_regular.ttf",
    Roboto_Regular = "fonts/roboto_regular.ttf",
    Roboto_Medium = "fonts/roboto_medium.ttf",
    Roboto_Bold = "fonts/roboto_bold.ttf",
}

function isSDXRunning()
    local sdxResource = getResourceFromName( "sdxLib" )
	if not sdxResource or getResourceState( sdxResource ) ~= "running" then return false end
	return true
end

function setSDXData( element, key, data, notUpdate )
    assert( isSDXRunning(), "SDX не работает! - 'setSDXData'" )
    exports.sdxLib:setSDXData( element, key, data, notUpdate )
    return true
end

function getSDXData( element, key )
    assert( isSDXRunning(), "SDX не работает! - 'setSDXData'" )
    return exports.sdxLib:getSDXData( element, key )
end

function sdxGetFontByName( font, size )
    assert( isSDXRunning(), "SDX не работает! - 'sdxGetFontByName'" )
    if not tFonts[tostring( font )] then return font end
    return exports.sdxLib:getSDXFont( tFonts[tostring( font )], (size or 1) * 0.71875 * font_mul ) or "default"
end

function xFHD( x )
	return x * 1920 / screenW
end

function yFHD( y )
	return isUltraWideRatio() and y or y * 1080 / ( screenH * ratio_mul )
end

function _x( x )
	if not x then return false end
	if isFullHDHeight() or isUltraWideRatio() and x < fullHDResolutionX then
		return x
	end
	return ( x / fullHDResolutionX ) * screenW
end

function _y( y )
	if not y then return false end
	if isFullHDHeight() or isUltraWideRatio() then
		return y
	elseif y == fullHDResolutionY then
		return screenH
	end
	return ( y / fullHDResolutionY ) * screenH * ratio_mul
end

function isFullHDHeight()
	return screenH == 1080
end

function isLowVideoMemory()
	return dxGetStatus().VideoMemoryFreeForMTA < 2
end

function isUltraWideRatio()
	return ratio_mul >= 1.3
end

function table.find( table, search_element )
	if type( table ) ~= "table" then return false end
	if not search_element then return false end
	for k, element in pairs( table ) do
		if element == search_element then return k end
	end
end

function isEvent( sEventName, pElementAttachedTo, func )
	if type( sEventName ) == 'string' and isElement( pElementAttachedTo ) and type( func ) == 'function' then
		local aAttachedFunctions = getEventHandlers( sEventName, pElementAttachedTo )
		if type( aAttachedFunctions ) == 'table' and #aAttachedFunctions > 0 then
			for i, v in ipairs( aAttachedFunctions ) do
				if v == func then return true end
			end
		end
	end
	return false
end

function convertHEXtoRGB( color, maxColor )
    if not tonumber( color ) then return end
    maxColor = tonumber( maxColor ) or 255
    local b = color%256
    local color = (color-b)/256
    local g = color%256
    local color = (color-g)/256
    local r = color%256
    local color = (color-r)/256
    local a = color%256

    local koeff = maxColor/255
    return koeff*r, koeff*g, koeff*b, koeff*a
end

local function getVarType( var )
    if isElement( var ) then return getElementType( var ) else return type( var ) end
end

local function sdxGetType( element )
    if not isElement( element ) then return end
    local elemType = getElementType( element )
    if table.find( sdxElements, elemType ) then return elemType end
end

-- Utilite functions

function wordwrapText( text, font, scale, maxStringWidth )
	scale = scale or 1
	font = font or "arial"
	local testWidth = 150
	maxStringWidth = _x( maxStringWidth ) or _x( testWidth )
	--	 local stringText = text or [[И бог заплачет над моею оченьдлинноесловодляпроверкиработывордврапаещенемногобуквдлянагрузки книжкой!
	-- Не слова - судороги, слипшиеся комом
	-- и побежит по небу с моими стихами под мышкой
	-- и будет, задыхаясь, читать их своим знакомым.]]
	local stringText = text or "Вот\n\n\nтак"

	local spaceCharWidth = dxGetTextWidth( " ", scale, font )
	local textHeight = dxGetFontHeight( scale, font )

	local wordCharPosStart = 1
	local wordCharPosEnd, word
	local stringWidth = 0
	local stringCount = 1

	local resultString = ""

	local tStrings = split( stringText, "\n" )

	--check every string
	for i = 1, #tStrings do
		local string = tStrings[i]

		repeat
			wordCharPosStart, wordCharPosEnd, word = utf8.find( string, "(%S+)", wordCharPosStart )

			if wordCharPosStart then
				wordCharPosStart = wordCharPosEnd + 1

				local wordWidth = dxGetTextWidth( word, scale, font )
				local additionalWidth = 0

				if stringWidth ~= 0 then
					additionalWidth = spaceCharWidth
				end

				if stringWidth + additionalWidth + wordWidth > maxStringWidth then
					local wordPart = word
					local wordPartWidth --= wordWidth

					--слово длиннее лимита
					repeat
						for i = 1, utf8.len( wordPart ) do
							local shortPart = utf8.sub( wordPart, 1, i )
							local tempWordPartWidth = dxGetTextWidth( shortPart, scale, font )

							if tempWordPartWidth > maxStringWidth then
								if stringWidth ~= 0 then
									resultString = resultString .. "\n" .. utf8.sub( wordPart, 1, i - 1 )
									stringCount = stringCount + 1
								else
									resultString = resultString .. utf8.sub( wordPart, 1, i - 1 )
								end

								--оставшаяся часть длинного слова
								wordPart = utf8.sub( wordPart, i )
								break
							end
						end

						wordPartWidth = dxGetTextWidth( wordPart, scale, font )
					until wordPartWidth <= maxStringWidth

					resultString = resultString .. "\n" .. wordPart
					stringWidth = wordPartWidth
					stringCount = stringCount + 1
				else
					if stringWidth ~= 0 then
						resultString = resultString .. " " .. word
						stringWidth = stringWidth + spaceCharWidth + wordWidth
					else
						resultString = resultString .. word
						stringWidth = stringWidth + wordWidth
					end
				end
			end
		until not wordCharPosStart

		if i < #tStrings then
			resultString = resultString .. "\n"
			stringCount = stringCount + 1
			stringWidth = 0
		end
	end

	return resultString, textHeight * stringCount, textHeight, stringCount
end

function createColorTable( shared, default, hovered, pressed, selected )
    assert( type( shared ) == "number", "Некорректный shared цвет ("..getVarType( shared )..") - 'createColorTable'" )

    return {
        [STATE_UNDEFINED] = shared,
        [STATE_DEFAULT] = default,
        [STATE_HOVERED] = hovered,
        [STATE_PRESSED] = pressed,
        [STATE_SELECTED] = selected,
    }
end

-- SHARED

function sdxIsElementVisible( element )
    assert( sdxGetType( element ), "Некорректный SDX Element ("..getVarType( element )..") - 'sdxIsElementVisible'" )
    return getSDXData( element, "visible" )
end

function sdxSetElementVisible( element, visible )
    assert( sdxGetType( element ), "Некорректный SDX Element ("..getVarType( element )..") - 'sdxSetElementVisible'" )
    assert( type( visible ) == "boolean" or type( visible ) == "nil", "Некорректно указано состояние ("..getVarType( visible )..") - 'sdxSetElementVisible'" )
    setSDXData( element, "visible", visible )
    return true
end

function sdxIsElementEnabled( element )
    assert( sdxGetType( element ), "Некорректный SDX Element ("..getVarType( element )..") - 'sdxIsElementEnabled'" )
    return getSDXData( element, "enable" )
end

function sdxSetElementEnabled( element, enable )
    assert( sdxGetType( element ), "Некорректный SDX Element ("..getVarType( element )..") - 'sdxSetElementEnabled'" )
    assert( type( enable ) == "boolean" or type( enable ) == "nil", "Некорректно указано состояние ("..getVarType( enable )..") - 'sdxSetElementEnabled'" )
    setSDXData( element, "enable", enable )
    return true
end

function sdxGetElementPosition( element )
    assert( sdxGetType( element ), "Некорректный SDX Element ("..getVarType( element )..") - 'sdxGetElementPosition'" )
    local pos = getSDXData( element, "position" ) or { x=0, y=0 }
    return pos.x, pos.y
end

function sdxSetElementPosition( element, x, y )
    assert( sdxGetType( element ), "Некорректный SDX Element ("..getVarType( element )..") - 'sdxSetElementPosition'" )
    assert( type( x ) == "number", "Некорректно указан x ("..getVarType( x )..") - 'sdxSetElementPosition'" )
    assert( type( y ) == "number", "Некорректно указан y ("..getVarType( y )..") - 'sdxSetElementPosition'" )
    local pos = getSDXData( element, "position" ) or { rot = 0 }
    setSDXData( element, "position", { x = x, y = y, rot = pos.rot or 0 } )
    return true
end

function sdxGetElementSize( element )
    assert( sdxGetType( element ), "Некорректный SDX Element ("..getVarType( element )..") - 'sdxGetElementSize'" )
    local size = getSDXData( element, "size" ) or { w=1, h=1 }
    return size.w, size.h
end

function sdxSetElementSize( element, w, h )
    assert( sdxGetType( element ), "Некорректный SDX Element ("..getVarType( element )..") - 'sdxSetElementSize'" )
    assert( type( w ) == "number", "Некорректно указан w ("..getVarType( w )..") - 'sdxSetElementSize'" )
    assert( type( h ) == "number", "Некорректно указан h ("..getVarType( h )..") - 'sdxSetElementSize'" )
    setSDXData( element, "size", { w = w, h = h } )
    return true
end

function sdxSetElementRotation( element, rotation )
    assert( sdxGetType( element ), "Некорректный SDX Element ("..getVarType( element )..") - 'sdxSetElementRotation'" )
    assert( type( rotation ) == "number", "Некорректно указан rotation ("..getVarType( rotation )..") - 'sdxSetElementRotation'" )
    local pos = getSDXData( element, "position" ) or { x=0, y=0 }
    setSDXData( element, "position", { x=pos.x, y=pos.y, rot = rotation } )
    return true
end

function sdxGetElementRotation( element )
    assert( sdxGetType( element ), "Некорректный SDX Element ("..getVarType( element )..") - 'sdxGetElementRotation'" )
    return (getSDXData( element, "position" ) or { rot=0 }).rot
end

function sdxSetRelativePosition( element, target, alignX, alignY, offsetX, offsetY )
    assert( sdxGetType( element ), "Некорректный SDX Element ("..getVarType( element )..") - 'sdxSetRelativePosition'" )
    target = sdxGetType( target ) and target or nil
    alignX = alignX or "center"
    alignY = alignY or "center"
    offsetX = _x( tonumber( offsetX ) or 0 )
    offsetY = _y( tonumber( offsetY ) or 0 )

    local x, y = 0, 0

    local size = getSDXData( element, "size" ) or { w=1, h=1 }
    local pos = getSDXData( element, "position" ) or { rot = 0 }

    local target_pos = { x=0, y=0 }
    local target_size = { w=screenW, h=screenH }
    if sdxGetType( target ) then
        target_size = getSDXData( target, "size" ) or { w=1, h=1 }
        target_pos = getSDXData( target, "position" ) or { x=0, y=0 }
    end

    if alignX == "left" then x = target_pos.x + offsetX
    elseif alignX == "o_left" then x = target_pos.x - offsetX - size.w
    elseif alignX == "right" then x = target_pos.x + target_size.w - offsetX - size.w
    elseif alignX == "o_right" then x = target_pos.x + target_size.w + offsetX
    elseif alignX == "center" then x = ( target_size.w - size.w ) / 2 + target_pos.x
    end

    if alignY == "top" then y = target_pos.y + offsetY
    elseif alignY == "above" then y = target_pos.y - offsetY - size.h
    elseif alignY == "bottom" then y = target_pos.y + target_size.h - offsetY - size.h
    elseif alignY == "under" then y = target_pos.y + target_size.h + offsetY
    elseif alignY == "center" then y = ( target_size.h - size.h ) / 2 + target_pos.y
    end

    setSDXData( element, "position", { x=x, y=y, rot=pos.rot or 0 } )
    return true
end

function sdxSetElementRounded( element, left_up, right_up, right_down, left_down )
    assert( sdxGetType( element ), "Некорректный SDX Element ("..getVarType( element )..") - 'sdxSetElementRounded'" )
    assert( type( left_up ) == "number", "Отсутствует радиус ("..getVarType( left_up )..") - 'sdxSetElementRounded'" )

    setSDXData( element, "roundedCorners", {
        _x( left_up or 0 ),
        _x( right_up or left_up or 0 ),
        _x( right_down or left_up or 0 ),
        _x( left_down or left_up or 0 ),
    } )
    return true
end

function sdxSetElementTabs( element, left, top, right, bottom )
    assert( sdxGetType( element ), "Некорректный SDX Element ("..getVarType( element )..") - 'sdxSetElementTabs'" )
    assert( type( left ) == "number", "Некорректный отступ ("..getVarType( left )..") - 'sdxSetElementTabs'" )
    setSDXData( element, "tabs", {
        _x ( left or 0 ),
        _y( top or 0 ),
        _x ( right or left or 0 ),
        _y ( bottom or top or 0 ),
    } )
    return true
end

function sdxSetElementGradient( element, colorTo, rotation )
    assert( sdxGetType( element ), "Некорректный SDX Element ("..getVarType( element )..") - 'sdxSetElementGradient'" )
    assert( type( colorTo ) == "number", "Некорректный цвет до ("..getVarType( colorTo )..") - 'sdxSetElementGradient'" )

    setSDXData( element, "gradient", { color = colorTo, rot = type( rotation ) == "number" and rotation } )
    return true
end

function sdxSetElementBorder( element, size, color, isTransparent )
    assert( sdxGetType( element ), "Некорректный SDX Element ("..getVarType( element )..") - 'sdxSetElementBorder'" )
    assert( type( size ) == "number", "Некорректный размер ("..getVarType( colorTo )..") - 'sdxSetElementBorder'" )
    setSDXData( element, "border", {
        size = _x( size ),
        color = color,
        transparent = isTransparent,
    } )
    return true
end

function sdxSetElementDragable( element, dragable )
    assert( sdxGetType( element ), "Некорректный SDX Element ("..getVarType( element )..") - 'sdxSetElementDragable'" )
    setSDXData( element, "dragable", dragable )
    return true
end

function sdxPinElementInRenderOrder( element, isPinned )
    assert( sdxGetType( element ), "Некорректный SDX Element ("..getVarType( element )..") - 'sdxPinElementInRenderOrder'" )
    setSDXData( element, "renderInTop", isPinned )
    return true
end

---------

-- COLOR

function sdxGetElementColor( element, color_type )
    assert( sdxGetType( element ), "Некорректный SDX Element ("..getVarType( element )..") - 'sdxGetElementColor'" )
    local color = getSDXData( element, "color" )
    if tonumber( color_type ) then return color[color_type]
    else return color[STATE_UNDEFINED] end
end

function sdxSetElementColor( element, color, color_type )
    assert( sdxGetType( element ), "Некорректный SDX Element ("..getVarType( element )..") - 'sdxSetElementColor'" )
    assert( type( color ) == "number", "Некорректный цвет ("..getVarType( color )..") - 'sdxSetElementColor'" )

    local colorT = getSDXData( element, "color" )
    if tonumber( color_type ) then colorT[color_type] = color
    else colorT = { [STATE_UNDEFINED] = color } end
    setSDXData( element, "color", colorT )
    return true
end

function sdxGetElementTextColor( element, color_type )
    assert( sdxGetType( element ), "Некорректный SDX Element ("..getVarType( element )..") - 'sdxGetElementTextColor'" )
    assert( table.find( elementsWithText, sdxGetType( element ) ), "Не допустимый тип элемента ("..getVarType( element )..") - 'sdxGetElementTextColor'" )

    local color = getSDXData( element, "text_color" )
    if tonumber( color_type ) then return color[color_type]
    else return color[STATE_UNDEFINED] end
end

function sdxSetElementTextColor( element, color, color_type )
    assert( sdxGetType( element ), "Некорректный SDX Element ("..getVarType( element )..") - 'sdxGetElementTextColor'" )
    assert( table.find( elementsWithText, sdxGetType( element ) ), "Не допустимый тип элемента ("..getVarType( element )..") - 'sdxGetElementTextColor'" )
    assert( type( color ) == "number", "Некорректный цвет ("..getVarType( color )..") - 'sdxGetElementTextColor'" )

    local colorT = getSDXData( element, "text_color" ) or {}
    if tonumber( color_type ) then colorT[color_type] = color
    else colorT = { [STATE_UNDEFINED] = color } end
    setSDXData( element, "text_color", colorT )
    return true
end

--------

-- TEXT

function sdxGetElementText( element )
    assert( sdxGetType( element ), "Некорректный SDX Element ("..getVarType( element )..") - 'sdxGetElementText'" )
    assert( table.find( elementsWithText, sdxGetType( element ) ), "Не допустимый тип элемента ("..getVarType( element )..") - 'sdxGetElementText'" )
    return getSDXData( element, "text" )
end

function sdxSetElementText( element, text, wordBreak )
    assert( sdxGetType( element ), "Некорректный SDX Element ("..getVarType( element )..") - 'sdxSetElementText'" )
    assert( table.find( elementsWithText, sdxGetType( element ) ), "Не допустимый тип элемента ("..getVarType( element )..") - 'sdxSetElementText'" )
    assert( type( text ) == "string" or type( text ) =="number", "Некорректный текст ("..getVarType( text )..") - 'sdxSetElementText'" )

    if wordBreak then
        local textSettings = getSDXData( element, "textSettings" ) or { scale = 1, font = "default" }
        local size = getSDXData( element, "size" ) or { w = 1 }
        text = wordwrapText( text, textSettings.font, isElement( textSettings.font ) and 1 or textSettings.scale, size.w )
    end

    setSDXData( element, "text", text )
    return true
end

function sdxSetLabelMarked( element, marked )
    assert( sdxGetType( element ), "Некорректный SDX Element ("..getVarType( element )..") - 'sdxSetLabelMarked'" )
    assert( table.find( elementsWithText, sdxGetType( element ) ), "Не допустимый тип элемента ("..getVarType( element )..") - 'sdxSetLabelMarked'" )
    local textSettings = getSDXData( element, "textSettings" ) or {}
    textSettings.marked = marked
    setSDXData( element, "textSettings", textSettings )
    return true
end

function sdxSetElementFont( element, font, size )
    assert( sdxGetType( element ), "Некорректный SDX Element ("..getVarType( element )..") - 'sdxSetElementFont'" )
    assert( table.find( elementsWithText, sdxGetType( element ) ), "Не допустимый тип элемента ("..getVarType( element )..") - 'sdxSetElementFont'" )
    assert( font or tFonts[tostring( font )] , "Некорректный шрифт  ("..tostring( font )..") - 'sdxSetElementFont'" )

    local createFont = sdxGetFontByName( font, size ) or "default"
    local textSettings = getSDXData( element, "textSettings" )

    textSettings.font = createFont
    textSettings.scale = (size or 1) * 0.71875 * font_mul
    setSDXData( element, "textSettings", textSettings )
    return true
end

function sdxSetElementTextAlign( element, alignX, alignY )
    assert( sdxGetType( element ), "Некорректный SDX Element ("..getVarType( element )..") - 'sdxSetElementTextAlign'" )
    assert( table.find( elementsWithText, sdxGetType( element ) ), "Не допустимый тип элемента ("..getVarType( element )..") - 'sdxSetElementTextAlign'" )

    local textSettings = getSDXData( element, "textSettings" )
    textSettings.alignX = alignX or "left"
    textSettings.alignY = alignY or "top"
    setSDXData( element, "textSettings", textSettings )
    return true
end

-------

--EDIT BOX

function sdxSetEditBoxPlaceholder( element, placeholder )
    assert( sdxGetType( element ), "Некорректный SDX Element ("..getVarType( element )..") - 'sdxSetEditBoxPlaceholder'" )
    assert( table.find( elementsEditable, sdxGetType( element ) ), "Не допустимый тип элемента ("..getVarType( element )..") - 'sdxSetEditBoxPlaceholder'" )
    assert( type( placeholder ) == "string" or type( placeholder ) == "number", "Не допустимое значение placeholder ("..getVarType( placeholder )..") - 'sdxSetEditBoxPlaceholder'" )

    local editSettings = getSDXData( element, "editSettings" ) or {}
    editSettings.placeholder = placeholder
    setSDXData( element, "editSettings", editSettings )

    return true
end

function sdxSetEditBoxMasked( element, state )
    assert( sdxGetType( element ), "Некорректный SDX Element ("..getVarType( element )..") - 'sdxSetEditBoxMasked'" )
    assert( table.find( elementsEditable, sdxGetType( element ) ), "Не допустимый тип элемента ("..getVarType( element )..") - 'sdxSetEditBoxMasked'" )
    assert( type( state ) == "boolean" or type( state ) == "nil", "Некоректное состояние ("..getVarType( state )..") - 'sdxSetEditBoxMasked'" )

    local editSettings = getSDXData( element, "editSettings" ) or {}
    editSettings.masked = state
    setSDXData( element, "editSettings", editSettings )

    return true
end

function sdxSetEditBoxMaxLength( element, maxLength )
    assert( sdxGetType( element ), "Некорректный SDX Element ("..getVarType( element )..") - 'sdxSetEditBoxMaxLength'" )
    assert( table.find( elementsEditable, sdxGetType( element ) ), "Не допустимый тип элемента ("..getVarType( element )..") - 'sdxSetEditBoxMaxLength'" )
    assert( type( maxLength ) == "number", "Не допустимое значение maxLength ("..getVarType( maxLength )..") - 'sdxSetEditBoxMaxLength'" )

    local editSettings = getSDXData( element, "editSettings" ) or {}
    editSettings.maxLength = maxLength
    setSDXData( element, "editSettings", editSettings )

    return true
end

function sdxSetEditBoxAllowedSymbols( element, symbols )
    assert( sdxGetType( element ), "Некорректный SDX Element ("..getVarType( element )..") - 'sdxSetEditBoxAllowedSymbols'" )
    assert( table.find( elementsEditable, sdxGetType( element ) ), "Не допустимый тип элемента ("..getVarType( element )..") - 'sdxSetEditBoxAllowedSymbols'" )
    assert( type( symbols ) == "string", "Не допустимое значение symbols ("..getVarType( symbols )..") - 'sdxSetEditBoxAllowedSymbols'" )

    local editSettings = getSDXData( element, "editSettings" ) or {}
    editSettings.symbols = symbols
    setSDXData( element, "editSettings", editSettings )

    return true
end

function sdxSetEditBoxActive( element )
    assert( sdxGetType( element ), "Некорректный SDX Element ("..getVarType( element )..") - 'sdxSetEditBoxActive'" )
    assert( table.find( elementsEditable, sdxGetType( element ) ), "Не допустимый тип элемента ("..getVarType( element )..") - 'sdxSetEditBoxActive'" )

    exports.sdxLib:setActiveEditBox( element )
    return true
end

function sdxIsEditBoxActive( element )
    local active = exports.sdxLib:getActiveEditBox()
    return (element == active), active
end

function sdxUnselectEditBox()
    exports.sdxLib:resetActiveEditBox()
    return true
end

----------

-- SPACE

function sdxSetContentWidth( element, w )
    assert( sdxGetType( element ), "Некорректный SDX Element ("..getVarType( element )..") - 'sdxSetContentWidth'" )
    assert( table.find( elementsSpaces, sdxGetType( element ) ), "Не допустимый тип элемента ("..getVarType( element )..") - 'sdxSetContentWidth'" )
    assert( type( w ) == "number", "Не допустимое значение w ("..getVarType( w )..") - 'sdxSetContentWidth'" )

    local content = getSDXData( element, "content" ) or {}
    content = {
        w = _x(w),
        h = content.h or 0,
        x = content.x or 0,
        y = content.y or 0
    }
    setSDXData( element, "content", content )

    return true
end

function sdxSetContentHeight( element, h )
    assert( sdxGetType( element ), "Некорректный SDX Element ("..getVarType( element )..") - 'sdxSetContentHeight'" )
    assert( table.find( elementsSpaces, sdxGetType( element ) ), "Не допустимый тип элемента ("..getVarType( element )..") - 'sdxSetContentHeight'" )
    assert( type( h ) == "number", "Не допустимое значение h ("..getVarType( h )..") - 'sdxSetContentHeight'" )

    local content = getSDXData( element, "content" ) or {}
    content = {
        w = content.w or 0,
        h = _y(h),
        x = content.x or 0,
        y = content.y or 0
    }
    setSDXData( element, "content", content )

    return true
end

function sdxResetContentPosition( element )
    assert( sdxGetType( element ), "Некорректный SDX Element ("..getVarType( element )..") - 'sdxResetContentPosition'" )
    assert( table.find( elementsSpaces, sdxGetType( element ) ), "Не допустимый тип элемента ("..getVarType( element )..") - 'sdxResetContentPosition'" )

    local content = getSDXData( element, "content" ) or {}
    content = {
        w = content.w or 0,
        h = content.h or 0,
        x = 0,
        y = 0
    }
    setSDXData( element, "content", content )

    return true
end

function sdxScrollAutoPosition( element )
    assert( sdxGetType( element ), "Некорректный SDX Element ("..getVarType( element )..") - 'sdxScrollAutoPosition'" )
    assert( table.find( elementsSpaces, sdxGetType( element ) ), "Не допустимый тип элемента ("..getVarType( element )..") - 'sdxScrollAutoPosition'" )

    local scrolls = getSDXData( element, "scrollingElements" ) or {}

    if isElement( scrolls.v ) then sdxSetRelativePosition( scrolls.v, element, "o_right", "top", 10, 0 ) end
    if isElement( scrolls.h ) then sdxSetRelativePosition( scrolls.h, element, "left", "under", 0, 10 ) end

    return true
end

function sdxScrollAutoSize( element )
    assert( sdxGetType( element ), "Некорректный SDX Element ("..getVarType( element )..") - 'sdxScrollAutoSize'" )
    assert( table.find( elementsSpaces, sdxGetType( element ) ), "Не допустимый тип элемента ("..getVarType( element )..") - 'sdxScrollAutoSize'" )

    local scrolls = getSDXData( element, "scrollingElements" ) or {}
    local size = getSDXData( element, "size" ) or {w=0,h=0}

    if isElement( scrolls.v ) then setSDXData( scrolls.v, "size", { w=_x(10), h=size.h } ) end
    if isElement( scrolls.h ) then setSDXData( scrolls.h, "size", { w=size.w, h=_y(10) } ) end

    return true
end

function sdxSetScrollBackground( element, state )
    assert( sdxGetType( element ), "Некорректный SDX Element ("..getVarType( element )..") - 'sdxSetScrollBackground'" )
    assert( table.find( elementsSpaces, sdxGetType( element ) ), "Не допустимый тип элемента ("..getVarType( element )..") - 'sdxSetScrollBackground'" )
    assert( type( state ) == "number" or state == false or state == nil, "Не допустимое значение state ("..getVarType( state )..") - 'sdxSetScrollBackground'" )

    local scrolls = getSDXData( element, "scrollingElements" ) or {}

    if isElement( scrolls.v ) then
        local scroll = getSDXData( scrolls.v, "scroll" ) or {}
        scroll.bg = state
        setSDXData( scrolls.v, "scroll", scroll )
    end
    if isElement( scrolls.h ) then
        local scroll = getSDXData( scrolls.h, "scroll" ) or {}
        scroll.bg = state
        setSDXData( scrolls.h, "scroll", scroll )
    end

    return true
end

function sdxSetScrollAlwaysVisible( element, state )
    assert( sdxGetType( element ), "Некорректный SDX Element ("..getVarType( element )..") - 'sdxSetScrollAlwaysVisible'" )
    assert( table.find( elementsSpaces, sdxGetType( element ) ), "Не допустимый тип элемента ("..getVarType( element )..") - 'sdxSetScrollAlwaysVisible'" )
    assert( type( state ) == "boolean" or state == nil, "Не допустимое значение state ("..getVarType( state )..") - 'sdxSetScrollAlwaysVisible'" )

    local scrolls = getSDXData( element, "scrollingElements" ) or {}

    if isElement( scrolls.v ) then
        local scroll = getSDXData( scrolls.v, "scroll" ) or {}
        scroll.always = state
        setSDXData( scrolls.v, "scroll", scroll )
    end
    if isElement( scrolls.h ) then
        local scroll = getSDXData( scrolls.h, "scroll" ) or {}
        scroll.always = state
        setSDXData( scrolls.h, "scroll", scroll )
    end

    return true
end

function sdxGetElementScrolls( element )
    assert( sdxGetType( element ), "Некорректный SDX Element ("..getVarType( element )..") - 'sdxGetElementScrolls'" )
    assert( table.find( elementsSpaces, sdxGetType( element ) ), "Не допустимый тип элемента ("..getVarType( element )..") - 'sdxGetElementScrolls'" )

    local scrolls = getSDXData( element, "scrollingElements" ) or {}
    return scrolls.v, scrolls.h
end

function sdxSetScrollStep( element, step )
    assert( sdxGetType( element ), "Некорректный SDX Element ("..getVarType( element )..") - 'sdxSetScrollStep'" )
    assert( table.find( elementsSpaces, sdxGetType( element ) ), "Не допустимый тип элемента ("..getVarType( element )..") - 'sdxSetScrollStep'" )
    assert( type( step ) == "number", "Не допустимое значение step ("..getVarType( step )..") - 'sdxSetScrollStep'" )

    setSDXData( element, "scroll_step", step )
    return true
end

function sdxSetScrollTab( element, tab )
    assert( sdxGetType( element ), "Некорректный SDX Element ("..getVarType( element )..") - 'sdxSetScrollTab'" )
    assert( table.find( elementsSpaces, sdxGetType( element ) ), "Не допустимый тип элемента ("..getVarType( element )..") - 'sdxSetScrollTab'" )
    assert( type( tab ) == "number", "Не допустимое значение tab ("..getVarType( tab )..") - 'sdxSetScrollTab'" )

    local scrolls = getSDXData( element, "scrollingElements" ) or {}

    if isElement( scrolls.v ) then sdxSetRelativePosition( scrolls.v, element, "o_right", "top", tab, 0 ) end
    if isElement( scrolls.h ) then sdxSetRelativePosition( scrolls.h, element, "left", "under", 0, tab ) end

    return true
end

function sdxSetScrollWidth( element, w )
    assert( sdxGetType( element ), "Некорректный SDX Element ("..getVarType( element )..") - 'sdxSetScrollWidth'" )
    assert( table.find( elementsSpaces, sdxGetType( element ) ), "Не допустимый тип элемента ("..getVarType( element )..") - 'sdxSetScrollWidth'" )
    assert( type( w ) == "number", "Не допустимое значение w ("..getVarType( w )..") - 'sdxSetScrollWidth'" )

    local scrolls = getSDXData( element, "scrollingElements" ) or {}
    local size = getSDXData( element, "size" ) or {w=0,h=0}

    if isElement( scrolls.v ) then setSDXData( scrolls.v, "size", { w=_x(w), h=size.h } ) end
    if isElement( scrolls.h ) then setSDXData( scrolls.h, "size", { w=size.w, h=_y(w) } ) end

    return true
end

--------

-- OTHER

function sdxSetElementImage( element, image )
    assert( sdxGetType( element ), "Некорректный SDX Element ("..getVarType( element )..") - 'sdxSetElementImage'" )
    assert( getVarType( image ) == "texture" or fileExists( tostring( image ) ), "Отсутствует изображение ("..getVarType( image )..") - 'sdxSetElementImage'" )
    if getVarType( image ) ~= "texture" then
        image = dxCreateTexture( image, "dxt5", false, "clamp" )
    end

    local old_texture = getSDXData( element, "texture" )
    if isElement( old_texture ) then destroyElement( old_texture ) end

   setSDXData( element, "texture", image )
    return true
end

function sdxGetProgressBarValue( element )
    assert( sdxGetType( element ), "Некорректный SDX Element ("..getVarType( element )..") - 'sdxGetProgressBarValue'" )
    return getSDXData( element, "progress" ) or 0
end

function sdxSetProgressBarValue( element, progress )
    assert( sdxGetType( element ), "Некорректный SDX Element ("..getVarType( element )..") - 'sdxSetProgressBarValue'" )
    assert( type( progress ) == "number" and progress >= 0 and progress <= 100, "Некорректный прогресс ("..getVarType( progress )..") - 'sdxSetProgressBarValue'" )
    setSDXData( element, "progress", progress )
    return true
end

--------

-- LIST

local function resizeListContent( element )
    if not sdxGetType( element ) then return end
    if sdxGetType( element ) ~= "sdxList" then return end

    local cols = getSDXData( element, "columns" ) or {}
    local rows = getSDXData( element, "rows" ) or {}
    local listSets = getSDXData( element, "list" ) or {}

    local contentHeight = (listSets.rowHeight + listSets.rowTab) * #rows - listSets.rowTab
    local contentWidth = 0
    for _, col in pairs( cols ) do contentWidth = contentWidth + col.width + listSets.colTab end
    contentWidth = contentWidth - listSets.colTab

    local content = getSDXData( element, "content" ) or {}
    setSDXData( element, "content", {
        w = contentWidth,
        h = contentHeight,
        x = content.x or 0,
        y = content.y or 0
    } )

    return true
end

function sdxSetListContent( element, content )
    assert( sdxGetType( element ), "Некорректный SDX Element ("..getVarType( element )..") - 'sdxSetListContent'" )
    assert( sdxGetType( element ) == "sdxList", "Не допустимый тип элемента ("..getVarType( element )..") - 'sdxSetListContent'" )
    assert( type( content ) == "table", "Не допустимое значение content ("..getVarType( content )..") - 'sdxSetListContent'" )
    setSDXData( element, "rows", content )
    resizeListContent( element )
    return true
end

function sdxSetListColumns( element, cols )
    assert( sdxGetType( element ), "Некорректный SDX Element ("..getVarType( element )..") - 'sdxSetListColumns'" )
    assert( sdxGetType( element ) == "sdxList", "Не допустимый тип элемента ("..getVarType( element )..") - 'sdxSetListColumns'" )
    assert( type( cols ) == "table", "Не допустимое значение content ("..getVarType( content )..") - 'sdxSetListColumns'" )
    for i, col in ipairs( cols ) do cols[i].width = _x(col.width or 10) end
    setSDXData( element, "columns", cols )
    resizeListContent( element )
    return true
end

function sdxAddListColumn( element, colName, width )
    assert( sdxGetType( element ), "Некорректный SDX Element ("..getVarType( element )..") - 'sdxAddColumn'" )
    assert( sdxGetType( element ) == "sdxList", "Не допустимый тип элемента ("..getVarType( element )..") - 'sdxAddColumn'" )
    assert( type( colName ) == "string", "Не допустимое значение name ("..getVarType( colName )..") - 'sdxAddColumn'" )
    assert( type( width ) == "number", "Не допустимое значение width ("..getVarType( width )..") - 'sdxAddColumn'" )

    local cols = getSDXData( element, "columns" ) or {}
    table.insert( cols, { width = _x(width), header = colName } )
    setSDXData( element, "columns", cols )
    resizeListContent( element )
    return #cols
end

function sdxAddListRow( element, ... )
    assert( sdxGetType( element ), "Некорректный SDX Element ("..getVarType( element )..") - 'sdxAddRow'" )
    assert( sdxGetType( element ) == "sdxList", "Не допустимый тип элемента ("..getVarType( element )..") - 'sdxAddRow'" )

    local rows = getSDXData( element, "rows" ) or {}

    local items = {}
    for _, item in ipairs( arg ) do table.insert( items, { text = item } ) end

    table.insert( rows, { items = items } )
    setSDXData( element, "rows", rows )
    resizeListContent( element )
    return #rows
end

function sdxSetListItemText( element, row, column, text )
    assert( sdxGetType( element ), "Некорректный SDX Element ("..getVarType( element )..") - 'sdxSetItemText'" )
    assert( sdxGetType( element ) == "sdxList", "Не допустимый тип элемента ("..getVarType( element )..") - 'sdxSetItemText'" )
    assert( type( row ) == "number", "Не допустимое значение row ("..getVarType( row )..") - 'sdxSetItemText'" )
    assert( type( column ) == "number", "Не допустимое значение column ("..getVarType( column )..") - 'sdxSetItemText'" )
    assert( type( text ) == "string", "Не допустимое значение text ("..getVarType( text )..") - 'sdxSetItemText'" )

    local rows = getSDXData( element, "rows" ) or {}

    assert( rows[row] and rows[row].items and rows[row].items[column], "Item с таким row и column не существует - 'sdxSetItemText'" )

    rows[row].items[column].text = text
    setSDXData( element, "rows", rows )
    return true
end

function sdxSetListRowHeigth( element, height )
    assert( sdxGetType( element ), "Некорректный SDX Element ("..getVarType( element )..") - 'sdxSetListRowHeigth'" )
    assert( sdxGetType( element ) == "sdxList", "Не допустимый тип элемента ("..getVarType( element )..") - 'sdxSetListRowHeigth'" )
    assert( type( height ) == "number", "Не допустимое значение height ("..getVarType( height )..") - 'sdxSetListRowHeigth'" )

    local listSets = getSDXData( element, "list" ) or {}
    listSets.rowHeight = _y( height or 10 )
    setSDXData( element, "list", listSets )
    resizeListContent( element )
    return true
end

function sdxSetListRowKey( element, row, key )
    assert( sdxGetType( element ), "Некорректный SDX Element ("..getVarType( element )..") - 'sdxSetListRowKey'" )
    assert( sdxGetType( element ) == "sdxList", "Не допустимый тип элемента ("..getVarType( element )..") - 'sdxSetListRowKey'" )
    assert( type( row ) == "number", "Не допустимое значение row ("..getVarType( row )..") - 'sdxSetListRowKey'" )
    assert( type( key ) == "number" or type( key ) == "string", "Не допустимое значение key ("..getVarType( key )..") - 'sdxSetListRowKey'" )

    local rows = getSDXData( element, "rows" ) or {}
    assert( rows[row], "Строки не существует - 'sdxSetListRowKey'" )

    rows[row].key = key
    setSDXData( element, "rows", rows )
    return true
end

function sdxSetListRowColor( element, row, colorTable )
    assert( sdxGetType( element ), "Некорректный SDX Element ("..getVarType( element )..") - 'sdxSetListRowColor'" )
    assert( sdxGetType( element ) == "sdxList", "Не допустимый тип элемента ("..getVarType( element )..") - 'sdxSetListRowColor'" )

    if type( colorTable ) == "nil" then
        colorTable = row
        row = nil
    end

    assert( type( colorTable ) == "table", "Не допустимое значение colorTable ("..getVarType( colorTable )..") - 'sdxSetListRowColor'" )

    if type( row ) ~= "nil" then
        assert( type( row ) == "number", "Не допустимое значение row ("..getVarType( row )..") - 'sdxSetListRowColor'" )

        local rows = getSDXData( element, "rows" ) or {}
        assert( rows[row], "Строки не существует - 'sdxSetListRowColor'" )

        rows[row].color = colorTable
        setSDXData( element, "rows", rows )

    else
        local listSets = getSDXData( element, "list" ) or {}
        listSets.rowColor = colorTable
        setSDXData( element, "list", listSets )
    end
    return true
end

function sdxSetListItemColor( element, row, column, colorTable )
    assert( sdxGetType( element ), "Некорректный SDX Element ("..getVarType( element )..") - 'sdxSetListItemColor'" )
    assert( sdxGetType( element ) == "sdxList", "Не допустимый тип элемента ("..getVarType( element )..") - 'sdxSetListItemColor'" )
    assert( type( row ) == "number", "Не допустимое значение row ("..getVarType( row )..") - 'sdxSetListItemColor'" )
    assert( type( column ) == "number", "Не допустимое значение column ("..getVarType( column )..") - 'sdxSetListItemColor'" )
    assert( type( colorTable ) == "table", "Не допустимое значение colorTable ("..getVarType( colorTable )..") - 'sdxSetListItemColor'" )

    local rows = getSDXData( element, "rows" ) or {}

    assert( rows[row] and rows[row].items and rows[row].items[column], "Item с таким row и column не существует - 'sdxSetListItemColor'" )

    rows[row].items[column].color = colorTable
    setSDXData( element, "rows", rows )
    return true
end

function sdxSetListColumnWidth( element, column, width )
    assert( sdxGetType( element ), "Некорректный SDX Element ("..getVarType( element )..") - 'sdxSetListColumnWidth'" )
    assert( sdxGetType( element ) == "sdxList", "Не допустимый тип элемента ("..getVarType( element )..") - 'sdxSetListColumnWidth'" )
    assert( type( column ) == "number", "Не допустимое значение column ("..getVarType( column )..") - 'sdxSetListColumnWidth'" )
    assert( type( width ) == "number", "Не допустимое значение width ("..getVarType( width )..") - 'sdxSetListColumnWidth'" )

    local cols = getSDXData( element, "columns" ) or {}
    assert( cols[column], "Столбца не существует - 'sdxSetListColumnWidth'" )
    cols[column].width = _x( width )

    setSDXData( element, "columns", cols )
    resizeListContent( element )
    return true
end

function sdxSetListItemsTabs( element, tabX, tabY, row, column )
    assert( sdxGetType( element ), "Некорректный SDX Element ("..getVarType( element )..") - 'sdxSetListItemsTabs'" )
    assert( sdxGetType( element ) == "sdxList", "Не допустимый тип элемента ("..getVarType( element )..") - 'sdxSetListItemsTabs'" )
    assert( type( tabX ) == "number", "Не допустимое значение tabX ("..getVarType( tabX )..") - 'sdxSetListItemsTabs'" )
    assert( type( tabY ) == "number", "Не допустимое значение tabY ("..getVarType( tabY )..") - 'sdxSetListItemsTabs'" )

    if type( row ) ~= "nil" or type( column ) ~= "nil" then
        assert( type( row ) == "number", "Не допустимое значение row ("..getVarType( row )..") - 'sdxSetListItemsTabs'" )
        assert( type( column ) == "number", "Не допустимое значение column ("..getVarType( column )..") - 'sdxSetListItemsTabs'" )

        local rows = getSDXData( element, "rows" ) or {}

        assert( rows[row] and rows[row].items and rows[row].items[column], "Item с таким row и column не существует - 'sdxSetListItemsTabs'" )

        rows[row].items[column].tabs = { _x( tabX ), _y( tabY ) }
        setSDXData( element, "rows", rows )

    else
        local listSets = getSDXData( element, "list" ) or {}
        listSets.rowTextTabs = { _x( tabX ), _y( tabY ) }
        setSDXData( element, "list", listSets )
    end

    return true
end

function sdxSetListItemsTextAligns( element, alignX, alignY, row, column )
    assert( sdxGetType( element ), "Некорректный SDX Element ("..getVarType( element )..") - 'sdxSetListItemsTextAligns'" )
    assert( sdxGetType( element ) == "sdxList", "Не допустимый тип элемента ("..getVarType( element )..") - 'sdxSetListItemsTextAligns'" )

    if type( row ) ~= "nil" or type( column ) ~= "nil" then
        assert( type( row ) == "number", "Не допустимое значение row ("..getVarType( row )..") - 'sdxSetListItemsTextAligns'" )
        assert( type( column ) == "number", "Не допустимое значение column ("..getVarType( column )..") - 'sdxSetListItemsTextAligns'" )

        local rows = getSDXData( element, "rows" ) or {}

        assert( rows[row] and rows[row].items and rows[row].items[column], "Item с таким row и column не существует - 'sdxSetListItemsTextAligns'" )

        rows[row].items[column].aligns = { alignX or "left", alignY or "center" }
        setSDXData( element, "rows", rows )

    else
        local listSets = getSDXData( element, "list" ) or {}
        listSets.rowTextAligns = { alignX or "left", alignY or "center" }
        setSDXData( element, "list", listSets )
    end

    return true
end

function sdxSetListHeaderFont( element, font, size )
    assert( sdxGetType( element ), "Некорректный SDX Element ("..getVarType( element )..") - 'sdxSetListHeaderFont'" )
    assert( sdxGetType( element ) == "sdxList", "Не допустимый тип элемента ("..getVarType( element )..") - 'sdxSetListHeaderFont'" )
    assert( font or tFonts[tostring( font )] , "Некорректный шрифт  ("..tostring( font )..") - 'sdxSetListHeaderFont'" )

    local headerSets = getSDXData( element, "header" ) or {}
    local createFont = sdxGetFontByName( font, size ) or "default"

    headerSets.text = { font = createFont, scale = (size or 1) * 0.71875 * font_mul }

    setSDXData( element, "header", headerSets )
    return true
end

function sdxSetListHeaderColor( element, color )
    assert( sdxGetType( element ), "Некорректный SDX Element ("..getVarType( element )..") - 'sdxSetListHeaderColor'" )
    assert( sdxGetType( element ) == "sdxList", "Не допустимый тип элемента ("..getVarType( element )..") - 'sdxSetListHeaderColor'" )
    assert( type( color ) == "number", "Некорректный цвет ("..getVarType( color )..") - 'sdxSetListHeaderColor'" )

    local headerSets = getSDXData( element, "header" ) or {}
    headerSets.color = color

    setSDXData( element, "header", headerSets )
    return true
end

function sdxSetListHeaderTabs( element, tabX, tabY )
    assert( sdxGetType( element ), "Некорректный SDX Element ("..getVarType( element )..") - 'sdxSetListHeaderTabs'" )
    assert( sdxGetType( element ) == "sdxList", "Не допустимый тип элемента ("..getVarType( element )..") - 'sdxSetListHeaderTabs'" )
    assert( type( tabX ) == "number", "Не допустимое значение tabX ("..getVarType( tabX )..") - 'sdxSetListHeaderTabs'" )
    assert( type( tabY ) == "number", "Не допустимое значение tabY ("..getVarType( tabY )..") - 'sdxSetListHeaderTabs'" )

    local headerSets = getSDXData( element, "header" ) or {}
    headerSets.tabs = { _x( tabX ), _y( tabY ) }

    setSDXData( element, "header", headerSets )
    return true
end

function sdxSetListHeaderAligns( element, alignX, alignY )
    assert( sdxGetType( element ), "Некорректный SDX Element ("..getVarType( element )..") - 'sdxSetListHeaderAligns'" )
    assert( sdxGetType( element ) == "sdxList", "Не допустимый тип элемента ("..getVarType( element )..") - 'sdxSetListHeaderAligns'" )

    local headerSets = getSDXData( element, "header" ) or {}
    headerSets.aligns = { alignX or "left", alignY or "center" }

    setSDXData( element, "header", headerSets )
    return true
end

function sdxSetListHeaderHeight( element, height )
    assert( sdxGetType( element ), "Некорректный SDX Element ("..getVarType( element )..") - 'sdxSetListHeaderHeight'" )
    assert( sdxGetType( element ) == "sdxList", "Не допустимый тип элемента ("..getVarType( element )..") - 'sdxSetListHeaderHeight'" )
    assert( type( height ) == "number", "Не допустимое значение height ("..getVarType( height )..") - 'sdxSetListHeaderHeight'" )

    local headerSets = getSDXData( element, "header" ) or {}
    headerSets.height = height

    setSDXData( element, "header", headerSets )
    return true
end

function sdxSetListItemsRounded( element, left_up, right_up, right_down, left_down )
    assert( sdxGetType( element ), "Некорректный SDX Element ("..getVarType( element )..") - 'sdxSetListItemsRounded'" )
    assert( sdxGetType( element ) == "sdxList", "Не допустимый тип элемента ("..getVarType( element )..") - 'sdxSetListItemsRounded'" )
    assert( type( left_up ) == "number", "Отсутствует радиус ("..getVarType( left_up )..") - 'sdxSetListItemsRounded'" )

    local listSets = getSDXData( element, "list" ) or {}
    listSets.rounded = {
        _x( left_up or 0 ),
        _x( right_up or left_up or 0 ),
        _x( right_down or left_up or 0 ),
        _x( left_down or left_up or 0 ),
    }
    setSDXData( element, "list", listSets )
    return true
end

function sdxSetListRowsTab( element, tab )
    assert( sdxGetType( element ), "Некорректный SDX Element ("..getVarType( element )..") - 'sdxSetListRowsTab'" )
    assert( sdxGetType( element ) == "sdxList", "Не допустимый тип элемента ("..getVarType( element )..") - 'sdxSetListRowsTab'" )
    assert( type( tab ) == "number", "Отсутствует отступ ("..getVarType( left_up )..") - 'sdxSetListRowsTab'" )

    local listSets = getSDXData( element, "list" ) or {}
    listSets.rowTab = _y( tab )
    setSDXData( element, "list", listSets )
    resizeListContent( element )
    return true
end

function sdxSetListColumnsTab( element, tab )
    assert( sdxGetType( element ), "Некорректный SDX Element ("..getVarType( element )..") - 'sdxSetListColumnsTab'" )
    assert( sdxGetType( element ) == "sdxList", "Не допустимый тип элемента ("..getVarType( element )..") - 'sdxSetListColumnsTab'" )
    assert( type( tab ) == "number", "Отсутствует отступ ("..getVarType( left_up )..") - 'sdxSetListColumnsTab'" )

    local listSets = getSDXData( element, "list" ) or {}
    listSets.colTab = _x( tab )
    setSDXData( element, "list", listSets )
    resizeListContent( element )
    return true
end

function sdxSetListSolidMode( element, state )
    assert( sdxGetType( element ), "Некорректный SDX Element ("..getVarType( element )..") - 'sdxSetListSolidMode'" )
    assert( sdxGetType( element ) == "sdxList", "Не допустимый тип элемента ("..getVarType( element )..") - 'sdxSetListSolidMode'" )
    assert( type( state ) == "boolean", "Отсутствует состояние ("..getVarType( state )..") - 'sdxSetListSolidMode'" )

    local listSets = getSDXData( element, "list" ) or {}
    listSets.solid = state
    setSDXData( element, "list", listSets )
    return true
end

function sdxGetListSelectedItem( element )
    assert( sdxGetType( element ), "Некорректный SDX Element ("..getVarType( element )..") - 'sdxGetListSelectedItem'" )
    assert( sdxGetType( element ) == "sdxList", "Не допустимый тип элемента ("..getVarType( element )..") - 'sdxGetListSelectedItem'" )

    local itemData = getSDXData( element, "selectedItem" ) or {}
    return itemData.row, itemData.item, itemData.rowKey
end

function sdxSetListSelectedItem( element, row, column )
    assert( sdxGetType( element ), "Некорректный SDX Element ("..getVarType( element )..") - 'sdxSetListSelectedItem'" )
    assert( sdxGetType( element ) == "sdxList", "Не допустимый тип элемента ("..getVarType( element )..") - 'sdxSetListSelectedItem'" )
    assert( type( row ) == "number", "Отсутствует row ("..getVarType( row )..") - 'sdxSetListSelectedItem'" )

    setSDXData( element, "selectedItem", { row = row, item = column } )
    return true
end

function sdxSetListSelectionMode( element, canSelect, canUnselect )
    assert( sdxGetType( element ), "Некорректный SDX Element ("..getVarType( element )..") - 'sdxSetListSelectionMode'" )
    assert( sdxGetType( element ) == "sdxList", "Не допустимый тип элемента ("..getVarType( element )..") - 'sdxSetListSelectionMode'" )

    local listSets = getSDXData( element, "list" ) or {}
    listSets.canSelect = canSelect
    listSets.canUnselect = canUnselect
    setSDXData( element, "list", listSets )
    return true
end

-------

-- Create functions

local function createDefaultElement( elementType, x, y, w, h, color, parent )
    if not elementType or elementType == "sdxRoot" then return end
    local element = createElement( elementType )
    setElementParent( element, parent or sdxRoot )

    setSDXData( element, "position", { x = _x(x) or 0, y = _y(y) or 0, rot = 0 }, true )
    setSDXData( element, "size", { w = _x(w or 1), h = _y(h or 1) }, true )
    setSDXData( element, "color", { [STATE_UNDEFINED] = color }, true )
    setSDXData( element, "visible", true, true )
    setSDXData( element, "enable", true )
    return element
end

function sdxCreateRectangle( x, y, w, h, color, parent )
    assert( type( x ) == "number", "Отсутствует x ("..getVarType( x )..") - 'sdxCreateRectangle'" )
    assert( type( y ) == "number", "Отсутствует y ("..getVarType( y )..") - 'sdxCreateRectangle'" )
    assert( type( w ) == "number", "Отсутствует w ("..getVarType( w )..") - 'sdxCreateRectangle'" )
    assert( type( h ) == "number", "Отсутствует h ("..getVarType( h )..") - 'sdxCreateRectangle'" )

    return createDefaultElement( "sdxRectangle", x, y, w, h, color or 0xFFFFFFFF, parent )
end

function sdxCreateLabel( x, y, w, h, text, size, font, color, parent )
    assert( type( x ) == "number", "Отсутствует x ("..getVarType( x )..") - 'sdxCreateLabel'" )
    assert( type( y ) == "number", "Отсутствует y ("..getVarType( y )..") - 'sdxCreateLabel'" )
    assert( type( w ) == "number", "Отсутствует w ("..getVarType( w )..") - 'sdxCreateLabel'" )
    assert( type( h ) == "number", "Отсутствует h ("..getVarType( h )..") - 'sdxCreateLabel'" )
    assert( type( text ) == "string" or type( text ) == "number", "Отсутствует текст ("..getVarType( text )..") - 'sdxCreateLabel'" )
    assert( type( size ) == "number", "Отсутствует размер ("..getVarType( size )..") - 'sdxCreateLabel'" )

    local element = createDefaultElement( "sdxLabel", x, y, w, h, color or 0xFFFFFFFF, parent )
    local createFont = sdxGetFontByName( font, size ) or "default"

    setSDXData( element, "text", text, true )
    setSDXData( element, "textSettings", {
        font = createFont,
        scale = size * 0.71875 * font_mul,
        alignX = "left",
        alignY = "top",
    } )

    return element
end

function sdxCreateImage( x, y, w, h, image, color, parent )
    assert( type( x ) == "number", "Отсутствует x ("..getVarType( x )..") - 'sdxCreateImage'" )
    assert( type( y ) == "number", "Отсутствует y ("..getVarType( y )..") - 'sdxCreateImage'" )
    assert( type( w ) == "number", "Отсутствует w ("..getVarType( w )..") - 'sdxCreateImage'" )
    assert( type( h ) == "number", "Отсутствует h ("..getVarType( h )..") - 'sdxCreateImage'" )
    assert( getVarType( image ) == "texture" or fileExists( tostring( image ) ), "Отсутствует изображение ("..getVarType( image )..") - 'sdxCreateImage'" )

    local element = createDefaultElement( "sdxImage", x, y, w, h, color or 0xFFFFFFFF, parent )

    if getVarType( image ) == "string" then
        if utf8.find( image, "^(.+).svg$" ) then
            local rSize = getSDXData( element, "size" ) or {w=0,h=0}
            image = svgCreate ( rSize.w, rSize.h, image )
        else
            image = dxCreateTexture( image, "dxt5", false, "clamp" )
        end
    end
    setSDXData( element, "texture", image )

    return element
end

function sdxCreateProgressBar( x, y, w, h, color, progress_color, vector, parent )
    assert( type( x ) == "number", "Отсутствует x ("..getVarType( x )..") - 'sdxCreateProgressBar'" )
    assert( type( y ) == "number", "Отсутствует y ("..getVarType( y )..") - 'sdxCreateProgressBar'" )
    assert( type( w ) == "number", "Отсутствует w ("..getVarType( w )..") - 'sdxCreateProgressBar'" )
    assert( type( h ) == "number", "Отсутствует h ("..getVarType( h )..") - 'sdxCreateProgressBar'" )

    local element = createDefaultElement( "sdxProgressBar", x, y, w, h, color or 0xFFFFFFFF, parent )
    
    setSDXData( element, "progress", 0, true )
    setSDXData( element, "progress_color", progress_color or 0xFFFFFFFF, true )
    setSDXData( element, "progress_vector", vector or "horizontal" )

    return element
end

function sdxCreateRoundBar( x, y, w, h, thickness, color, progress_color, parent, isClockwise )
    assert( type( x ) == "number", "Отсутствует x ("..getVarType( x )..") - 'sdxCreateRoundBar'" )
    assert( type( y ) == "number", "Отсутствует y ("..getVarType( y )..") - 'sdxCreateRoundBar'" )
    assert( type( w ) == "number", "Отсутствует w ("..getVarType( w )..") - 'sdxCreateRoundBar'" )
    assert( type( h ) == "number", "Отсутствует h ("..getVarType( h )..") - 'sdxCreateRoundBar'" )

    local element = createDefaultElement( "sdxRoundBar", x, y, w, h, color or 0xFFFFFFFF, parent )
    setSDXData( element, "position", { x = x, y = y, rot = -90 }, true )
    setSDXData( element, "progress", 0, true )
    setSDXData( element, "progress_color", progress_color or 0xFF000000, true )
    setSDXData( element, "roundBarSettings", { thickness = _x( thickness ), isClockwise = isClockwise } )

    return element
end

function sdxCreateButton( x, y, w, h, text, color, parent )
    assert( type( x ) == "number", "Отсутствует x ("..getVarType( x )..") - 'sdxCreateButton'" )
    assert( type( y ) == "number", "Отсутствует y ("..getVarType( y )..") - 'sdxCreateButton'" )
    assert( type( w ) == "number", "Отсутствует w ("..getVarType( w )..") - 'sdxCreateButton'" )
    assert( type( h ) == "number", "Отсутствует h ("..getVarType( h )..") - 'sdxCreateButton'" )

    local element = createDefaultElement( "sdxButton", x, y, w, h, color or 0xFFFFFFFF, parent )

    setSDXData( element, "text", text or "", true )
    setSDXData( element, "textSettings", {
        font = "default",
        scale = 0.71875 * font_mul,
        alignX = "center",
        alignY = "center",
    }, true )
    setSDXData( element, "text_color", {
        [STATE_UNDEFINED] = 0xFF000000,
    } )

    return element
end

function sdxCreateEditBox( x, y, w, h, color, placeholder, masked, maxLength, font, size, textColor, parent )
    assert( type( x ) == "number", "Отсутствует x ("..getVarType( x )..") - 'sdxCreateEditBox'" )
    assert( type( y ) == "number", "Отсутствует y ("..getVarType( y )..") - 'sdxCreateEditBox'" )
    assert( type( w ) == "number", "Отсутствует w ("..getVarType( w )..") - 'sdxCreateEditBox'" )
    assert( type( h ) == "number", "Отсутствует h ("..getVarType( h )..") - 'sdxCreateEditBox'" )

    local element = createDefaultElement( "sdxEditBox", x, y, w, h, color, parent )
    local createFont = sdxGetFontByName( font, size ) or "default"

    setSDXData( element, "text", "", true )
    setSDXData( element, "textSettings", {
        font = createFont,
        scale = (size or 1) * 0.71875 * font_mul,
        alignX = "left",
        alignY = "center",
    }, true )
    setSDXData( element, "editSettings", {
        placeholder = placeholder or "",
        masked  = masked,
        maxLength = maxLength or 1000,
        symbols = "space,0-9,a-Z,а-Я,#",
    }, true )
    setSDXData( element, "text_color", {
        [STATE_UNDEFINED] = textColor or 0xFF000000,
    } )

    return element
end

function sdxCreateSpace( x, y, w, h, parent )
    assert( type( x ) == "number", "Отсутствует x ("..getVarType( x )..") - 'sdxCreateSpace'" )
    assert( type( y ) == "number", "Отсутствует y ("..getVarType( y )..") - 'sdxCreateSpace'" )
    assert( type( w ) == "number", "Отсутствует w ("..getVarType( w )..") - 'sdxCreateSpace'" )
    assert( type( h ) == "number", "Отсутствует h ("..getVarType( h )..") - 'sdxCreateSpace'" )

    local element = createDefaultElement( "sdxSpace", x, y, w, h, 0xFFFFFFFF, parent )
    setSDXData( element, "content", { x=0,y=0,w=0,h=0 } )

    local scroll_v = createDefaultElement( "sdxScroll", x + w, y, 10, h, 0xFFFFFFFF, element )
    setSDXData( scroll_v, "scroll", { vector = "vertical" } )

    local scroll_h = createDefaultElement( "sdxScroll", x, y + h, w, 10, 0xFFFFFFFF, element )
    setSDXData( scroll_h, "scroll", { vector = "horizontal" } )

    setSDXData( element, "scrollingElements", { v = scroll_v, h = scroll_h } )

    return element, scroll_v, scroll_h
end

function sdxCreateSlider( x, y, w, h, color, color_bg, progress_color, vector, parent )
    assert( type( x ) == "number", "Отсутствует x ("..getVarType( x )..") - 'sdxCreateSlider'" )
    assert( type( y ) == "number", "Отсутствует y ("..getVarType( y )..") - 'sdxCreateSlider'" )
    assert( type( w ) == "number", "Отсутствует w ("..getVarType( w )..") - 'sdxCreateSlider'" )
    assert( type( h ) == "number", "Отсутствует h ("..getVarType( h )..") - 'sdxCreateSlider'" )

    local element = createDefaultElement( "sdxSlider", x, y, w, h, color or 0xFFFFFFFF, parent )
    setSDXData( element, "progress", 0, true )
    setSDXData( element, "scroll", { vector = vector or "horizontal", bg = color_bg or 0xFF000000 }, true )
    setSDXData( element, "progress_color", progress_color or 0xFF000000 )

    return element
end

function sdxCreateList( x, y, w, h, color, parent )
    assert( type( x ) == "number", "Отсутствует x ("..getVarType( x )..") - 'sdxCreateList'" )
    assert( type( y ) == "number", "Отсутствует y ("..getVarType( y )..") - 'sdxCreateList'" )
    assert( type( w ) == "number", "Отсутствует w ("..getVarType( w )..") - 'sdxCreateList'" )
    assert( type( h ) == "number", "Отсутствует h ("..getVarType( h )..") - 'sdxCreateList'" )

    local element = createDefaultElement( "sdxList", x, y, w, h, color, parent )
    setSDXData( element, "content", { x=0,y=0,w=0,h=0 }, true )
    setSDXData( element, "header", {
        text = { scale = 1, font = "default" },
        color = 0xFF000000,
        tabs = { 0, 0 },
        aligns = { "left", "center" },
        height = 50,
    }, true )

    setSDXData( element, "columns", {}, true )
    setSDXData( element, "rows", {}, true )

    setSDXData( element, "list", {
        rowHeight = 10,
        colTab = 20,
        rowTab = 20,
        rowColor = {
            [STATE_UNDEFINED] = 0xFF0000FF,
            [STATE_SELECTED] = { [STATE_UNDEFINED] = 0xFFFF0000 },
        }

    }, true )

    local scroll_v = createDefaultElement( "sdxScroll", x + w, y, 10, h, 0xFFFFFFFF, element )
    setSDXData( scroll_v, "scroll", { vector = "vertical" } )

    local scroll_h = createDefaultElement( "sdxScroll", x, y + h, w, 10, 0xFFFFFFFF, element )
    setSDXData( scroll_h, "scroll", { vector = "horizontal" } )

    setSDXData( element, "scrollingElements", { v = scroll_v, h = scroll_h } )

    return element, scroll_v, scroll_h
end

-- ANIMATIONS
local tAnims = {}

local function renderAnimations()
    for element, info in pairs( tAnims ) do
        local timeLost = getTickCount() - info.startTick
        if timeLost > info.time then timeLost = info.time end

        local def = info.reverse and info.result or info.default
        local res = info.reverse and info.default or info.result

        local nX = def.x + ( res.x - def.x ) / info.time * timeLost
        local nY = def.y + ( res.y - def.y ) / info.time * timeLost
        local nRot = def.rot + ( res.rot - def.rot ) / info.time * timeLost

        local nW = def.w + ( res.w - def.w ) / info.time * timeLost
        local nH = def.h + ( res.h - def.h ) / info.time * timeLost

        local cFR, cFG, cFB, cFA = convertHEXtoRGB( type( def.color ) == "table" and (def.color[STATE_DEFAULT] or def.color[STATE_UNDEFINED] or 0xFFFFFFFF) or def.color )
        local cTR, cTG, cTB, cTA = convertHEXtoRGB( type( res.color ) == "table" and (res.color[STATE_DEFAULT] or res.color[STATE_UNDEFINED] or 0xFFFFFFFF) or res.color )

        local nR = cFR + ( cTR - cFR ) / info.time * timeLost
        local nG = cFG + ( cTG - cFG ) / info.time * timeLost
        local nB = cFB + ( cTB - cFB ) / info.time * timeLost
        local nA = cFA + ( cTA - cFA ) / info.time * timeLost

        setSDXData( element, "position", { x = nX, y = nY, rot = nRot }, true )
        setSDXData( element, "size", { w = nW, h = nH }, true )
        setSDXData( element, "color", { [STATE_UNDEFINED] = tocolor( nR, nG, nB, nA ) }, true )

        if timeLost == info.time then
            if info.reverse and info.repeats > 0 then tAnims[element].repeats = info.repeats - 1 end
            tAnims[element].reverse = not info.reverse
            tAnims[element].startTick = getTickCount()
            if tAnims[element].repeats == 0 then sdxStopAnimation( element ) end
        end
    end
end

function sdxStopAnimation( element )
    assert( sdxGetType( element ), "Некорректный SDX Element ("..getVarType( element )..") - 'sdxStopAnimation'" )
    if not tAnims[element] then return end

    local def = tAnims[element].default
    setSDXData( element, "size", { w = def.w, h = def.h }, true )
    setSDXData( element, "enable", def.enable, true )
    setSDXData( element, "color", def.color, true )
    setSDXData( element, "position", { x = def.x, y = def.y, rot = def.rot } )

    tAnims[element] = nil
    if not next( tAnims ) then removeEventHandler( "onClientPreRender", root, renderAnimations ) end

    triggerEvent( "onSDXAnimationStop", element )
end

function sdxStartAnimation( element, time, x, y, w, h, rot, color, repeats )
    assert( sdxGetType( element ), "Некорректный SDX Element ("..getVarType( element )..") - 'sdxStartAnimation'" )
    assert( type( time ) == "number", "Некорректное время ("..getVarType( element )..") - 'sdxStartAnimation'" )

    sdxStopAnimation( element )

    local event = triggerEvent( "onSDXAnimationStart", element, time )
    if not event then return end

    local pos = getSDXData( element, "position" ) or { x=0, y=0, rot=0 }
    local size = getSDXData( element, "size" ) or { w=0, h=0 }
    local elemColor = getSDXData( element, "color" ) or { [STATE_UNDEFINED] = 0xFFFFFFFF }

    local tDefaultInfo = {
        x = pos.x or 0,
        y = pos.y or 0,
        rot = pos.rot or 0,
        w = size.w or 0,
        h = size.h or 0,
        color = elemColor,
        enable = getSDXData( element, "enable" )
    }

    local tResultInfo = {
        x = _x( x ) or tDefaultInfo.x,
        y = _y( y ) or tDefaultInfo.y,
        rot = rot or tDefaultInfo.rot,
        w = _x( w ) or tDefaultInfo.w,
        h = _y( h ) or tDefaultInfo.h,
        color = color or tDefaultInfo.color[STATE_UNDEFINED] or 0xFFFFFFFF,
    }

    tAnims[element] = {
        default = tDefaultInfo,
        result = tResultInfo,
        revers = false,
        startTick = getTickCount(),
        time = time * 1000,
        repeats = repeats,
    }

    if not isEvent( "onClientPreRender", root, renderAnimations ) then addEventHandler( "onClientPreRender", root, renderAnimations ) end
end

addEvent( "onSDXAnimationStart", true )
addEvent( "onSDXAnimationStop", true )

