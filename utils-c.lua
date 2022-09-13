screenW, screenH = guiGetScreenSize()
tDrawElements = {}

STATE_UNDEFINED, STATE_DEFAULT, STATE_HOVERED, STATE_PRESSED, STATE_SELECTED = 0, 1, 2, 3, 4
selectEdit, tSelectedKey, writePosition, lastTickRectEdit = nil, nil, 0, 0

sdxElements = { "sdxRectangle", "sdxLabel", "sdxImage", "sdxRoundBar", "sdxProgressBar", "sdxButton", "sdxEditBox", "sdxSpace", "sdxScroll", "sdxSlider", "sdxList" }
rectangledElements = { "sdxRectangle", "sdxImage", "sdxRoundBar" }

tSymbols = {
    ["space"] = { " " },
    ["0-9"] = { "0", "1", "2", "3", "4", "5", "6", "7", "8", "9" },
    ["a-Z"] = { "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z" },
    ["а-Я"] = { "а", "б", "в", "г", "д", "е", "ё", "ж", "з", "и", "й", "к", "л", "м", "н", "о", "п", "р", "с", "т", "у", "ф", "х", "ц", "ч", "ш", "щ", "ъ", "ы", "ь", "э", "ю", "я", "А", "Б", "В", "Г", "Д", "Е", "Ё", "Ж", "З", "И", "Й", "К", "Л", "М", "Н", "О", "П", "Р", "С", "Т", "У", "Ф", "Х", "Ц", "Ч", "Ш", "Щ", "Ъ", "Ы", "Ь", "Э", "Ю", "Я" },
    ["pass#"] = { "!", "@", "#", "$", "%" },
    ["#"] = { "<", ">", "`", "~", ",", ".", "!", "@", "#", '"', "№", "$", ";", "%", "^", ":", "&", "?", "*", "(", ")", "-", "_", "=", "+", "[", "{", "]", "}", "/", "\\", "|" },
}

shaderRounded = [[
    #define PI 3.1415926535898

    texture sourceTexture;

    float4 radius = 0;

    float borderWidth = 0;
    float4 borderColor = 0;
    float isTransparent = false;

    bool gradientState = false;
    float gradientRotation = 0;
    float4 gradientTo = 0;

    SamplerState tSampler{
        Texture = sourceTexture;
        MinFilter = Linear;
        MagFilter = Linear;
        MipFilter = Linear;
    };

    float4 roundRect(float2 tex: TEXCOORD0, float4 color : COLOR0):COLOR0{
        float4 result = tex2D(tSampler,tex)*color;
        float2 dx = ddx(tex);
        float2 dy = ddy(tex);
        float2 dd = float2(length(float2(dx.x,dy.x)),length(float2(dx.y,dy.y)));
        float a = dd.x/dd.y;

        bool isBorderActive = borderWidth != 0;

        float2 center = 0.5*float2(1/(a<=1?a:1),a<=1?1:a);

        float4 nRadius;
        float nBorder;
        float soft = 1.5;

        if(a<=1){
            tex.x /= a;
            soft *= dd.y;
            nRadius = float4( radius.x*dd.y, radius.y*dd.y, radius.z*dd.y, radius.w*dd.y );
            nBorder = borderWidth*dd.y;
        }else{
            tex.y *= a;
            soft *= dd.x;
            nRadius = float4( radius.x*dd.x, radius.y*dd.x, radius.z*dd.x, radius.w*dd.x );
            nBorder = borderWidth*dd.x;
        }

        float2 roundCenter;
        float cRadius = 0;
        bool isCanRound = false;

        float height = a <= 1 ? 1.0 : a;
        float width = a <= 1 ? 1.0/a : 1.0;

        if ( tex.x <= center.x && tex.y <= center.y ){
            cRadius = min( min( nRadius.x, height/2.0 ), width/2.0 );
            roundCenter = float2( cRadius, cRadius );
            isCanRound = (tex.x < cRadius && tex.y < cRadius);

        } else if ( tex.x <= center.x && tex.y >= center.y ){
            cRadius = min( min( nRadius.w, height/2.0 ), width/2.0 );
            roundCenter = float2( cRadius, height - cRadius );
            isCanRound = (tex.x < cRadius && tex.y > roundCenter.y);

        } else if ( tex.x >= center.x && tex.y <= center.y ){
            cRadius = min( min( nRadius.y, height/2.0 ), width/2.0 );
            roundCenter = float2( width - cRadius, cRadius );
            isCanRound = (tex.x > roundCenter.x && tex.y < cRadius);
        
        } else if ( tex.x >= center.x && tex.y >= center.y ){
            cRadius = min( min( nRadius.z, height/2.0 ), width/2.0 );
            roundCenter = float2( width - cRadius, height - cRadius );
            isCanRound = (tex.x > roundCenter.x && tex.y > roundCenter.y);
        }

        float dis = distance( roundCenter,  tex );
        bool isBorder = false;

        if ( isCanRound ){

            if ( dis > cRadius ){
                result.a = 0;
            } else if ( isBorderActive && result.a != 0 ){
                if ( dis + nBorder > cRadius ){
                    result = borderColor;
                    isBorder = true;
                } else if ( isTransparent ) {
                    result.a = 0;
                } else if ( dis + nBorder + soft > cRadius ){
                    //result.a = saturate( smoothstep( cRadius, cRadius-soft, dis+nBorder ) - (1 - result.a) ); // Будующее сглаживание для внутреней части обводки
                }
            }

            if ( dis + soft > cRadius && result.a != 0 ){
                result.a = saturate( smoothstep( cRadius, cRadius-soft, dis ) - (1 - result.a) );
            }

        } else if (result.a != 0) {
            if (isBorderActive){
                if (tex.x < nBorder || tex.x > width - nBorder || tex.y < nBorder || tex.y > height - nBorder ){
                    result = borderColor;
                    isBorder = true;
                } else if (isTransparent) {
                    result.a = 0;
                }
            }

            if (result.a != 0){
                if ( tex.x < soft || tex.y < soft ){
                    result.a = saturate( smoothstep( 0, soft, tex.x < soft ? tex.x : tex.y ) - (1 - result.a) );

                } else if ( tex.x > width-soft ){
                    result.a = saturate( smoothstep( width, width-soft, tex.x ) - (1 - result.a) );

                } else if ( tex.y > height-soft ){
                    result.a = saturate( smoothstep( height, height-soft, tex.y ) - (1 - result.a) );
                }
            }

        }

        if ( result.a != 0 && gradientState && ((isTransparent && isBorder) || (!isTransparent && !isBorder))){

            float4 useColor = isTransparent ? borderColor : result;

            if(a<=1) tex.x *= a;
            else tex.y /= a;

            float rad = gradientRotation/180*PI;
            float rotSin = sin(rad);
            float rotCos = cos(rad);
            tex -= 0.5;
            float2 kValue = float2(tex.x*rotCos-tex.y*rotSin,tex.x*rotSin+tex.y*rotCos)+0.5;
            float4 colorCalculated = useColor+(gradientTo-useColor)*(kValue.x);
            result.rgb = colorCalculated.rgb;
            result.a *= colorCalculated.a;
            
        }
        
        return result;
    }

    technique roundRectTech{
        pass P0{
            PixelShader = compile ps_2_a roundRect();
        }
    }
]]

shaderRoundbar = [[
    texture sourceTexture;

    float progress = 0;
    float roundWidth = 0;
    float4 progressColor = 0;
    bool isClockwise = true;

    SamplerState tSampler{
        Texture = sourceTexture;
        MinFilter = Linear;
        MagFilter = Linear;
        MipFilter = Linear;
    };

    float findRotation( float2 pos, float2 pos1 ){
        float t = -degrees( atan2( pos1.x - pos.x, pos1.y - pos.y ) );
        return t < 0 ? t + 360 : t;
    }

    float4 roundBar(float2 tex: TEXCOORD0, float4 color : COLOR0):COLOR0{
        float4 result = tex2D(tSampler,tex)*color;
        float2 dx = ddx(tex);
        float2 dy = ddy(tex);
        float2 dd = float2(length(float2(dx.x,dy.x)),length(float2(dx.y,dy.y)));
        float a = dd.x/dd.y;

        float cProgress = min( progress, 100 );
        float maxAngle = 3.6 * cProgress;

        float2 center = 0.5*float2(1/(a<=1?a:1),a<=1?1:a);

        float nWidth;
        float soft = 1.5;

        if(a<=1){
            tex.x /= a;
            soft *= dd.y;
            nWidth = roundWidth*dd.y;
        }else{
            tex.y *= a;
            soft *= dd.x;
            nWidth = roundWidth*dd.x;
        }

        float radius = min( 1.0, 1/a )/2.0;
        float dis = distance( center, tex );

        if ( dis > radius ){
            result.a = 0;
        } else if ( dis + nWidth > radius ){
            float rot = findRotation( center, tex );
            if ( (isClockwise && rot <= maxAngle) || (!isClockwise && rot > 360-maxAngle ) ) result = progressColor;

        } else if ( dis + nWidth + soft > radius ){
            float rot = findRotation( center, tex );
            if ( (isClockwise && rot <= maxAngle) || (!isClockwise && rot > 360-maxAngle ) ) result = progressColor;
            result.a = saturate( smoothstep( radius-soft, radius, dis+nWidth ) - (1 - result.a) );

        } else {
            result.a = 0;
        }

        if ( dis + soft > radius && result.a != 0 ){
            result.a = saturate( smoothstep( radius, radius-soft, dis ) - (1 - result.a) );
        }
        
        return result;
    }

    technique roundBarTech{
        pass P0{
            PixelShader = compile ps_2_a roundBar();
        }
    }
]]

getElementType_old = getElementType
function getElementType( element )
    if isElement( element ) then return getElementType_old( element ) end
    return false
end

function math.round(number)
    local _, decimals = math.modf(number)
    if decimals < 0.5 then return math.floor(number) end
    return math.ceil(number)
end

function table.find( table, search_element )
	if type( table ) ~= "table" then return end
	if not search_element then return end
	for k, element in pairs( table ) do
		if element == search_element then return k end
	end
end

function table.copy(tab, recursive)
    local ret = {}
    for key, value in pairs(tab) do
        if (type(value) == "table") and recursive then ret[key] = table.copy(value)
        else ret[key] = value end
    end
    return ret
end

function createWhiteTexture()
    local texture = dxCreateTexture( 1, 1 )
    local pixel = dxGetTexturePixels ( texture )
    dxSetPixelColor ( pixel, 0, 0, 255,255,255 )
    dxSetTexturePixels( texture, pixel )
    return texture
end
whiteTexture = createWhiteTexture()

function isSymbolAllowed( symbol, allowed )
    if not symbol then return false end
    if not allowed then return false end
    for _, lang in ipairs( split( allowed, "," ) ) do
        if table.find( tSymbols[lang] or {}, symbol ) or lang == symbol then return true end
    end
    return false
end
function remove_char(str, pos)
    return utf8.sub( str, 1, pos - 1 )..""..utf8.sub( str, pos + 1 )
end
function add_char( str, pos, char )
    return utf8.sub( str, 1, pos )..char..utf8.sub( str, pos + 1 )
end

function convertColor( color )
    if not tonumber( color ) then return end
    local b = color%256
    local color = (color-b)/256
    local g = color%256
    local color = (color-g)/256
    local r = color%256
    local color = (color-r)/256
    local a = color%256

    local koeff = 1/255
    return koeff*r, koeff*g, koeff*b, koeff*a
end

function isCursorOnElement( x, y, w, h, angle )
    if not isCursorShowing() then return end

    local centerX, centerY = x + w / 2, y + h / 2
    local halfWidth, halfHeight = w / 2, h / 2

    local pointX, pointY = getCursorPosition()
    local pointX, pointY = pointX * screenW, pointY * screenH

    local dX, dY = centerX - pointX, centerY - pointY

    angle = math.rad ( angle )

    local c, s = math.cos ( angle ), math.sin ( angle )
    local x, y = c * dX + s * dY, s * dX - c * dY

    return not ( x * x > halfWidth * halfWidth or y * y > halfHeight * halfHeight )
end

-- Events

addEvent( "onSdxElementDoubleClick", true )
addEvent( "onSdxElementPressed", true )
addEvent( "onSdxElementHovered", true )
addEvent( "onSdxEditBoxEdited", true )
addEvent( "onSDXDataChange", true )
addEvent( "onSDXSliderMoved", true )

---------

