local ROBLOX_ENUMS = Enum:GetEnums()
local LuauTypes = require(script.Parent.Parent.LuauTypes)
local ROBLOX_CLASSES = require(script.Parent.Parent.RobloxClassNames)
local ROBLOX_INSTANCES = require(script.Parent.Parent.RobloxInstanceNames)
local ROBLOX_DATA_TYPES = require(script.Parent.Parent.RobloxDataTypeNames)

export type TypeId = "DataType" | "Class" | "Instance" | "Enum"

export type Type = {
	Is: (...any) -> boolean,
	IsTypeOf: (Type) -> boolean,
	IsSubtype: (Type) -> boolean,
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

function DataType:IsSubtype(other: Type): boolean
	if other.Type == "DataType" then
		return self.Name == other.Name
	end
	return false
end

function DataType:IsTypeOf(other: Type): boolean
	return other:IsSubtype(self)
end

function DataType:__eq(other: any): boolean
	if type(other) ~= "table" or getmetatable(other) ~= DataType then
		return false
	end
	return self.Name == other.Name
end

function DataType:__tostring(): string
	return self.Name
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

function InstanceType:IsSubtype(other: Type): boolean
	if other.Type == "Instance" then
		if self.ClassName == other.ClassName then
			return true
		end
	end
	if other.Type ~= "Class" and other.Type ~= "Instance" then
		return false
	end
	local instance: Instance?
	pcall(function()
		instance = Instance.new(other.ClassName)
	end)
	if instance then
		return instance:IsA(self.ClassName)
	end
	return false
end

function InstanceType:IsTypeOf(other: Type): boolean
	return other:IsSubtype(self)
end

function InstanceType:__eq(other: any): boolean
	if type(other) ~= "table" or getmetatable(other) ~= InstanceType then
		return false
	end
	return self.ClassName == other.ClassName
end

function InstanceType:__tostring(): string
	return self.ClassName
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

function ClassType:IsSubtype(other: Type): boolean
	if other.Type == "Class" then
		if self.ClassName == other.ClassName then
			return true
		end
	end
	if other.Type == "Instance" then
		local instance: Instance?
		pcall(function()
			instance = Instance.new(other.ClassName)
		end)
		if instance then
			return instance:IsA(self.ClassName)
		end
	end
	return false
end

function ClassType:IsTypeOf(other: Type): boolean
	return other:IsSubtype(self)
end

function ClassType:__eq(other: any): boolean
	if type(other) ~= "table" or getmetatable(other) ~= ClassType then
		return false
	end
	return self.ClassName == other.ClassName
end

function ClassType:__tostring(): string
	return self.ClassName
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
	for _, enumItem in self.Enum:GetEnumItems() do
		if value == enumItem then
			return true
		end
	end
	return false
end

function EnumType:IsSubtype(other: Type): boolean
	if other.Type == "Literal" then
		return self:Is(other.Value)
	end
	return other.Type == "Enum" and self.Enum == other.Enum
end

function EnumType:IsTypeOf(other: Type): boolean
	return other:IsSubtype(self)
end

function EnumType:__eq(other: any): boolean
	if type(other) ~= "table" or getmetatable(other) ~= EnumType then
		return false
	end
	return self.Enum == other.Enum
end

function EnumType:__tostring(): string
	return tostring(self.Enum)
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

	for _, enum in ROBLOX_ENUMS do
		if "Enum." .. tostring(enum) == literal then
			return EnumType.new(enum)
		end
	end

	if string.sub(literal, 1, 5) == "Enum." then
		local enumName = string.sub(literal, 6)
		enumName = string.sub(enumName, 1, string.find(enumName, ".", 1, true) - 1)
		local enumItemName = string.sub(literal, string.find(literal, ".", 6, true) + 1)
		local enum = Enum[enumName]
		if not enum then
			return nil
		end
		local enumValue = Enum[enumName][enumItemName]
		if not enumValue then
			return nil
		end
		return LuauTypes.Literal.new(enumValue)
	end
end

return RobloxTypes
