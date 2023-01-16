# Roblox-Runtime-Type
Runtime type parser and checker for roblox types that allows you to define types in the luau type format. You can check whether certain values match a given type, or perform other type-related operations.

Supported types:
  - All luau value types
  - All roblox types (classes, instances, enums) 
    - (Depends on updated dependencies: RobloxDataTypeNames, RobloxInstanceNames, RobloxClassNames)
  - Unions `(type | type) | type`
  - Optionals `type?`
  - Tuples `type, type, type`
  - Primitive literals `"Square" | "Circle" | true`

Differences from luau type definitions:
  - No intersection types
  - No generic types
  - No specific function types (only `function`)
  - Tuples can be treated as a value where appropriate
    - `(number, Vector2) | (Vector2, Vector3)`

# Usage

Add **Type** to your Wally dependencies:
```toml
Type = "meta-maxim/type@^1"
```

Use it to check types and perform other type manipulations. Usage examples:
```lua
local Type = require(script.Parent.Type)

-- Defines a custom tuple type
local myType = Type("Enum.NormalId, { x: number, y: number }?")

-- Check types
print(myType:Is(Enum.NormalId.Front, nil)) --> true
print(myType:Is(Enum.NormalId.Front, { x = 1 })) --> false

-- Compare types
print(myType == Type("Enum.NormalId", "{ x: number, y: number }?")) --> true

local myItemTemplate = {
  Id = 1;
  RefId = 1;
}

local myItemType = Type [[{
  Id: number;
  RefId: number;
}]]

-- Get type of value
print(Type.of(myItemTemplate) == myItemType) --> true

-- Custom type class construction
print(Type.Union.new(Type.Number, Type.String) == Type("number | string")) --> true
```

Remote value type checking example:
```lua
local Type = require(script.Parent.Type)

local myItemType = Type [[{
  Id: number;
  RefId: number;
  Metadata: {}?;
}]]

local function processItemRequest(itemId: number, item: {}?) end

local itemRequestType = Type("number", Type.Optional(myItemType))
myItemRemote.OnServerEvent:Connect(function (...)
  if not itemRequestType:Is(...) then
    warn("Invalid input from client")
    return
  end
  processItemRequest(...)
end)
```

# API
**Type construction**
  - `Type.new(...(string | Type))`
    - `Type(...(string | Type))` *(equivalent)*

**Type object API:**
  - `Type:Is(...any)` -- returns true if the given values match this type
  - `Type:IsTypeOf(otherType)` -- returns true if this type is a subtype of otherType
  - `Type:IsSubtype(otherType)` -- returns true if otherType is a subtype of this type
  - `Type == otherType` -- returns true if the two types have identical definitions

**Types:**
  - `Type.Nil`
  - `Type.Boolean`
  - `Type.Number`
  - `Type.String`
  - `Type.Thread`
  - `Type.Function`
  - `Type.Table.new(maps: {Map}, fields: {Field})`
  - `Type.Field.new(key: Type, valueType: Type)`
  - `Type.Map.new(keyType: Type, valueType: Type)`
  - `Type.Union.new(...Type)`
  - `Type.Optional.new(value: Type)`
  - `Type.DataType.new(valueType: string)`
  - `Type.Enum.new(enum: Enum)`
  - `Type.Instance.new(className: string)`
  - `Type.Class.new(className: string)`
