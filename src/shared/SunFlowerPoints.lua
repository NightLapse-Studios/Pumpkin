local SunFlower = {}

local function radius(k,n,b)
	if k > n - b then
		return 1 -- put on the boundary
	else
		return math.sqrt(k - 1 * 0.5) / math.sqrt(n - (b + 1) * 0.5) -- apply square root
	end
end

function SunFlower.getPoints(n: number, alpha: number, pointClassConstructor)
	pointClassConstructor = pointClassConstructor or Vector2.new
	alpha = alpha or 0 -- 0 is plain SunFlower

    local b = math.round(alpha * math.sqrt(n)) -- number of boundary points
	local phi = (math.sqrt(5) + 1) * 0.5 -- golden ratio
	phi *= phi
	phi = 1 / phi -- to multiply instead of divide

	local ret = {}

    for k = 1, n do
        local r = radius(k, n, b)
        local theta = 2 * math.pi * k * phi
		local x, y = r * math.cos(theta), r * math.sin(theta)
		ret[k] = pointClassConstructor(x, y)
	end

	return ret
end

local phi = math.pi * (3 - math.sqrt(5))
function SunFlower.getSpherePoints(samples, pointClassConstructor)
    local points = {}

    for i = 1, samples do
        local y = 1 - (i / (samples - 1)) * 2
        local r = math.sqrt(1 - y * y)

        local theta = phi * i

        local x = math.cos(theta) * r
        local z = math.sin(theta) * r

        points[#points + 1] = pointClassConstructor(x, y, z)
	end

    return points
end

return SunFlower