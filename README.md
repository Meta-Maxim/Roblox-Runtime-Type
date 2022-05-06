# Roblox-Runtime-Type
Runtime type parser and checker for roblox types.

⚠️ Early version - May crash or error with invalid type definitions

Supported types:
  - All luau types
  - All roblox types (classes, instances, enums) (until updates)
  - Unions `(type | type) | type`
  - Optionals `type?`
  - Tuples `type, type, type`

# Usage

Add **Type** your Wally dependencies:
```toml
Type = "meta-maxim/type@^1"
```

Use **Type** to check to check types and perform other type manipulations. Usage examples:
```lua
local Type = require(script.Parent.Type)

-- Create a tuple type (using parser)
local typeDefinition = "string, number, { x: number, y: number }?"
local myType = Type.new(typeDefinition)

-- Compare types
print(myType == Type(typeDefinition)) --> true

-- Check types
print(myType:Is("mystring", 123, nil) --> true

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

Remote value type checking example (without global networking middleware):
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
