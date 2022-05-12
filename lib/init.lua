local ROBLOX_CLASSES = require(script.Parent.RobloxClassNames)
local ROBLOX_DATA_TYPES = require(script.Parent.RobloxDataTypeNames)
local LuauTypeParser = require(script.Parent.LuauTypeParser)
local LuauTypes = require(script.Parent.LuauTypes)
local RobloxTypes = require(script.RobloxTypes)

local Type = {}

function Type:__index(key): LuauTypes.Type
	local typeKey = rawget(Type, key)
	if typeKey then
		return typeKey
	end
	local robloxType = RobloxTypes[key]
	if robloxType then
		return robloxType
	end
	return LuauTypes[key]
end

function Type:__call(...): LuauTypes.Type
	return Type.new(...)
end

function Type.new(...): LuauTypes.Type
	local parser
	local function getLuauParser()
		if parser then
			return parser
		end
		parser = LuauTypeParser.new({
			CustomTypeParsers = { RobloxTypes.ParseString },
		})
		return parser
	end

	local input = { ... }
	if #input == 1 then
		local arg = input[1]
		if type(arg) == "string" then
			return getLuauParser():Parse(arg)
		else
			return arg
		end
	end

	local tuple = LuauTypes.Tuple.new()
	for _, arg in ipairs(input) do
		tuple:AddValueType(LuauTypes.new(if type(arg) == "string" then getLuauParser():Parse(arg) else arg))
	end

	return tuple
end

local function typeOfRecursive(value: any): LuauTypes.Type
	local valueType = typeof(value)
	if valueType == "table" then
		local tableType = LuauTypes.Table.new()
		for key, val in pairs(value) do
			tableType:AddFieldType(LuauTypes.Field.new(key, typeOfRecursive(val)))
		end
		return tableType
	elseif LuauTypes.Globals[valueType] then
		return LuauTypes.Globals[valueType]
	elseif valueType == "Instance" then
		return RobloxTypes.Instance.new(value.ClassName)
	elseif valueType == "EnumItem" then
		return RobloxTypes.Enum.new(value.EnumType)
	elseif table.find(ROBLOX_DATA_TYPES, valueType) then
		return RobloxTypes.DataType.new(valueType)
	elseif table.find(ROBLOX_CLASSES, valueType) then
		return RobloxTypes.Class.new(valueType)
	end
end

function Type.of(...): LuauTypes.Type
	local input = { ... }
	if #input == 1 then
		return typeOfRecursive(input[1])
	end

	local tuple = LuauTypes.Tuple.new()
	for _, arg in ipairs(input) do
		tuple:AddValueType(typeOfRecursive(arg))
	end

	return tuple
end

return setmetatable(Type, Type)
