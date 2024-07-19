local ROBLOX_CLASSES = require(script.Parent.RobloxClassNames)
local ROBLOX_DATA_TYPES = require(script.Parent.RobloxDataTypeNames)
local LuauTypeParser = require(script.Parent.LuauTypeParser)
local LuauTypes = require(script.Parent.LuauTypes)
local RobloxTypes = require(script.RobloxTypes)

local NIL = newproxy()

local Type = {}

export type ParserOptions = {
	CustomTypeParsers: { (string) -> LuauTypes.Type? }?,
}

local RobloxTypeParser = {}
RobloxTypeParser.__index = RobloxTypeParser

function RobloxTypeParser.new(parserOptions: ParserOptions?)
	local customTypeParsers = parserOptions and parserOptions.CustomTypeParsers or {}
	customTypeParsers[#customTypeParsers + 1] = RobloxTypes.ParseString
	return setmetatable({
		CustomTypeParsers = customTypeParsers,
	}, RobloxTypeParser)
end

function RobloxTypeParser:__call(...): LuauTypes.Type
	return self:parse(...)
end

function RobloxTypeParser:parse(...): LuauTypes.Type
	local parser
	local function getLuauParser()
		if parser then
			return parser
		end
		parser = LuauTypeParser.new({
			CustomTypeParsers = self.CustomTypeParsers,
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
		tuple:AddValueType(if type(arg) == "string" then getLuauParser():Parse(arg) else arg)
	end

	return tuple
end

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
	return RobloxTypeParser.new():parse(...)
end

function Type.custom(parserOptions: ParserOptions): LuauTypes.Type
	return RobloxTypeParser.new(parserOptions)
end

local function typeOfRecursive(value: any, customTypeParsers: { Type: string, Is: (any) -> boolean }?): LuauTypes.Type
	if customTypeParsers then
		for _, customTypeParser in ipairs(customTypeParsers) do
			if customTypeParser.Is(value) then
				return customTypeParser.Type
			end
		end
	end

	local valueType = typeof(value)
	if valueType == "table" then
		local tableType = LuauTypes.Table.new()
		local indices = {}
		for i = 1, #value do
			indices[i] = true
			tableType:AddFieldType(LuauTypes.Field.new(i, typeOfRecursive(value[i])))
		end
		for key, val in pairs(value) do
			if indices[key] then
				continue
			end
			if customTypeParsers then
				for _, customTypeParser in ipairs(customTypeParsers) do
					if customTypeParser.Is(key) then
						key = customTypeParser.Type
						break
					end
				end
			end
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
	for i = 1, #input do
		tuple:AddValueType(typeOfRecursive(input[i]))
	end

	return tuple
end

function Type.ofCustom(customTypeParsers: { Type: string, Is: (any) -> boolean }, ...): LuauTypes.Type
	local input = { ... }
	if #input == 1 then
		return typeOfRecursive(input[1], customTypeParsers)
	end

	local tuple = LuauTypes.Tuple.new()
	for i = 1, #input do
		tuple:AddValueType(typeOfRecursive(input[i], customTypeParsers))
	end

	return tuple
end

return setmetatable(Type, Type)
