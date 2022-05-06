local ROBLOX_ENUMS = Enum:GetEnums()
local ROBLOX_CLASSES = require(script.Parent.Parent.RobloxClassNames)
local ROBLOX_INSTANCES = require(script.Parent.Parent.RobloxInstanceNames)
local ROBLOX_DATA_TYPES = require(script.Parent.Parent.RobloxDataTypeNames)

export type TypeId = "DataType" | "Class" | "Instance" | "Enum"

export type Type = {
	Is: (...any) -> boolean,
	Type: TypeId,
}

export type DataType = Type & {
	Name: string,
}

export type InstanceType = Type & {
	ClassName: string,
}

export type ClassType = Type & {
	ClassName: string,
}

export type EnumType = Type & {
	Enum: Enum,
}

local RobloxTypes = {}

local DataType = {}
DataType.__index = DataType

function DataType.new(name: string): DataType
	return setmetatable({
		Type = "DataType",
		Name = name,
	}, DataType) :: DataType
end

function DataType:Is(value: any): boolean
	return typeof(value) == self.Name
end

function DataType:__eq(other: any): boolean
	if getmetatable(other) ~= DataType then
		return false
	end
	return self.Name == other.Name
end

RobloxTypes.DataType = DataType

local InstanceType = {}
InstanceType.__index = InstanceType

function InstanceType.new(name: string): InstanceType
	return setmetatable({
		Type = "Instance",
		ClassName = name,
	}, InstanceType) :: InstanceType
end

function InstanceType:Is(value: any): boolean
	return typeof(value) == "Instance" and value.ClassName == self.ClassName
end

function InstanceType:__eq(other: any): boolean
	if getmetatable(other) ~= InstanceType then
		return false
	end
	return self.ClassName == other.ClassName
end

RobloxTypes.Instance = InstanceType

local ClassType = {}
ClassType.__index = ClassType

function ClassType.new(name: string): ClassType
	return setmetatable({
		Type = "Class",
		ClassName = name,
	}, ClassType) :: ClassType
end

function ClassType:Is(value: any): boolean
	local valueType = typeof(value)
	return valueType == self.ClassName or (valueType == "Instance" and value:IsA(self.ClassName))
end

function ClassType:__eq(other: any): boolean
	if getmetatable(other) ~= ClassType then
		return false
	end
	return self.ClassName == other.ClassName
end

RobloxTypes.Class = ClassType

local EnumType = {}
EnumType.__index = EnumType

function EnumType.new(enum: Enum): EnumType
	return setmetatable({
		Type = "Enum",
		Enum = enum,
	}, EnumType) :: EnumType
end

function EnumType:Is(value: any): boolean
	return value == self.Enum
end

function EnumType:__eq(other: any): boolean
	if getmetatable(other) ~= EnumType then
		return false
	end
	return self.Enum == other.Enum
end

RobloxTypes.Enum = EnumType

function RobloxTypes.ParseString(literal: string)
	if table.find(ROBLOX_DATA_TYPES, literal) then
		return DataType.new(literal)
	end

	if table.find(ROBLOX_INSTANCES, literal) then
		return InstanceType.new(literal)
	end

	if table.find(ROBLOX_CLASSES, literal) then
		return ClassType.new(literal)
	end

	for _, enumName in ipairs(ROBLOX_ENUMS) do
		if enumName == literal then
			return EnumType.new(enum)
		end
	end
end

return RobloxTypes
