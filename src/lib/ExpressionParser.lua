
local ExpressionParser = {}

-- Operator, Precedence, associativity, func
local operators = {
	["^"] = {4, 1, function(a, b) return a ^ b end},
	["*"] = {3, -1, function(a, b) return a * b end},
	["/"] = {3, -1, function(a, b) return a / b end},
	["%"] = {3, -1, function(a, b) return a % b end},
	["+"] = {1, -1, function(a, b) return a + b end},
	["-"] = {1, -1, function(a, b) return a - b end},
}

-- the funcionality of negates may be slow and dirty, but it works and the expressions are not going to be massive.
local function negate(a)
	return -a
end

local funcs = {
    abs 	= math.abs,
    acos 	= math.acos,
    asin 	= math.asin,
    atan 	= math.atan,
    ceil 	= math.ceil,
    cos 	= math.cos,
    cosh 	= math.cosh,
    deg 	= math.deg,
    floor 	= math.floor,
    log10 	= math.log10,
    rad 	= math.rad,
    random 	= math.random,
	rand 	= math.random,
	rnd 	= math.random,
    round 	= math.round,
    sign 	= math.sign,
    sin 	= math.sin,
    sinh 	= math.sinh,
    sqrt 	= math.sqrt,
    tan 	= math.tan,
    tanh 	= math.tanh,
	pi      = function() return math.pi end,
	
	u 		= negate,
}

local longestFirst = {}
local oneLetterFuncs = {}
local funcsOneLetter = {}

local available = {}
for i = 97, 122 do
	local char = string.char(i)
	if not funcs[char] then
		table.insert(available, char)
	end
	char = string.upper(string.char(i))
	if not funcs[char] then
		table.insert(available, char)
	end
end

for i,v in pairs(funcs) do
	table.insert(longestFirst, i)
	
	if funcsOneLetter[v] then-- if this function is already mapped to one letter then continue
		continue
	end
	
	local letter = table.remove(available, #available)
	oneLetterFuncs[letter] = v
	funcsOneLetter[v] = letter
end

table.sort(longestFirst, function(a,b)
	return #a > #b
end)

local function getNegateNumEnd(exp, startNum)
	local begin = string.sub(exp, startNum, startNum)
	if begin == "(" then
		local toclose = 1
		while true do
			startNum += 1
			local check = string.sub(exp, startNum, startNum)
			if check == "(" then
				toclose += 1
			elseif check == ")" then
				toclose -= 1
				if toclose == 0 then
					return startNum
				end
			end
			
			if startNum > #exp then
				return nil
			end
		end
	else
		local canAffordAnotherDot = not (begin == ".")
		while true do
			startNum += 1
			local check = string.sub(exp, startNum, startNum)
			if tonumber(check) or (canAffordAnotherDot and check == ".") then
				if check == "." then
					canAffordAnotherDot = false
				end
			else
				startNum -= 1
				return startNum
			end
		end
	end
end

function ExpressionParser.ToRPN(exp: String): String
	exp = string.gsub(exp, "[,%s]", "")
	
	for i = 1, #longestFirst do
		local funcName = longestFirst[i]
		exp = string.gsub(exp, funcName .. "%(", funcsOneLetter[funcs[funcName]] .. "(")
	end
	
	local outputQueue = {}
	local operatorStack = {}
	
	local token = ""
	local pos = 0
	
	while pos < #exp do
		pos += 1
		token = string.sub(exp, pos, pos)
		if tonumber(token) or token == "." then
			local canAffordAnotherDot = not (token == ".")
			
			while true do
				pos += 1
				local check = string.sub(exp, pos, pos)
				if tonumber(check) or (canAffordAnotherDot and check == ".") then
					if check == "." then
						canAffordAnotherDot = false
					end
					token ..= check
				else
					pos -= 1
					break
				end
			end
			
			table.insert(outputQueue, token)
		elseif oneLetterFuncs[token] then
			table.insert(operatorStack, token)
		elseif operators[token] then
			--[[ while ((there is an operator at the top of the operator stack)
			and ((the operator at the top of the operator stack has greater precedence)
			or (the operator at the top of the operator stack has equal precedence and the token is left associative))
			and (the operator at the top of the operator stack is not a left parenthesis)):
			pop operators from the operator stack onto the output queue. ]]
			
			
			if token == "-" then
				-- a minus is always unary if it immediately follows another operator or a left parenthesis, or if it occurs at the very beginning of the input
				local left = string.sub(exp, pos-1, pos-1)
				if pos == 1 or operators[left] or left == "(" then
					
					local endNum = getNegateNumEnd(exp, pos + 1)
					exp = string.sub(exp, 1, pos - 1) .. funcsOneLetter[negate] .. "(" .. string.sub(exp, pos + 1, endNum) .. ")" .. string.sub(exp, endNum + 1, -1)
					table.insert(operatorStack, funcsOneLetter[negate])
					
					continue
				end
			end
			
			local top = operatorStack[#operatorStack]
			while true do
				if not top then
					break
				end
				if top == "(" then
					break
				end
				
				local tkop = operators[token]
				local tkoppre = tkop and tkop[1] or 10-- if its a function then it is not in the operators stack.
				local toppre = operators[top] and operators[top][1] or 10
				
				if not(toppre > tkoppre or (toppre == tkoppre and (tkop and tkop[2] or 1) == -1)) then
					break
				end
			
				table.insert(outputQueue, table.remove(operatorStack, #operatorStack))
				top = operatorStack[#operatorStack]
			end
			table.insert(operatorStack, token)
		elseif token == "(" then
			table.insert(operatorStack, token)
		elseif token == ")" then
			local top = operatorStack[#operatorStack]
			while top ~= "(" do
				table.insert(outputQueue, table.remove(operatorStack, #operatorStack))
				top = operatorStack[#operatorStack]
				if #operatorStack == 0 then
					return nil
				end
			end
			-- If the stack runs out without finding a left parenthesis, then there are mismatched parentheses. */
			if top == "(" then
				table.remove(operatorStack, #operatorStack)
			end
			if oneLetterFuncs[top] then
				table.insert(outputQueue, table.remove(operatorStack, #operatorStack))
			end
		end
	end
	for i = #operatorStack, 1, -1 do
		table.insert(outputQueue, table.remove(operatorStack, i))
	end
	
	return outputQueue
end

function ExpressionParser.EvaluateRPN(RPN): number
	local stack = {}
	
	for i = 1, #RPN do
		local toAdd = RPN[i]
		local num = tonumber(toAdd)
		if not num then
			local num1 = table.remove(stack, #stack)
			
			local opp = operators[toAdd]
			if opp then
				local num2 = table.remove(stack, #stack)
				
				table.insert(stack, opp[3](num2, num1))-- very important that num2 comes before num1 here
			else
				local func = oneLetterFuncs[toAdd]
				if func then
					if num1 then
						table.insert(stack, func(num1))
					else
						table.insert(stack, func())
					end
				else
					error("Something got by you or me!")
				end
			end
		else
			table.insert(stack, num)
		end
	end
	
	return stack[1]
end

function ExpressionParser.Evaluate(exp: string): number
	local suc, ret = pcall(function()
		return ExpressionParser.EvaluateRPN(ExpressionParser.ToRPN(exp))
	end)
	
	return suc and ret or nil
end

ExpressionParser.Funcs = funcs

return ExpressionParser