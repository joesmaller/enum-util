--!strict
--[=[
	@class Enum-Util
]=]

local TOSTRING_ENUMITEM = "Enum.%s.%s"
local ERROR_INVALID_TYPE = "invalid argument #%s to '%s' (%s expected, got %s)"

local EnumUtil = {}

local function assertFunctionType(functionName: string, argument: number, desiredType: string, parameter: any)
	assert(typeof(parameter) == desiredType,
		ERROR_INVALID_TYPE:format(tostring(argument), functionName, desiredType, typeof(parameter))
	)
end

--[=[
	@param enumType string
	@param enumItemName string
	@param dataTable {[any]: any}?
	@return CustomEnumItem

	Creates a new custom EnumItem with optional table.
]=]
function EnumUtil.createEnumItem(enumType: string, enumItemName: string, dataTable: {[any]: any}?): CustomEnumItem
	assertFunctionType("createEnumItem", 1, "string", enumType)
	assertFunctionType("createEnumItem", 2, "string", enumItemName)
	assertFunctionType("createEnumItem", 3, "table", if type(dataTable) == "nil" then {} else dataTable)

	local newEnumItem: {[any]: any} = if dataTable then table.clone(dataTable) else {}

	newEnumItem.Name = enumItemName
	newEnumItem.EnumType = enumType

	return table.freeze(setmetatable(newEnumItem :: {Name: string, EnumType: string, [any]: any}, {
		__EnumItemProxy = newproxy();
		__eq = function(self, other)
			if type(other) ~= "table" then return false end
			local selfMetatable = getmetatable(self)
			local otherMetatable = getmetatable(other)
			if otherMetatable and (selfMetatable.__EnumItemProxy == otherMetatable.__EnumItemProxy) then return true end
			return false
		end;
		__tostring = function(self)
			return TOSTRING_ENUMITEM:format(self.EnumType, self.Name)
		end;
	}))
end


--[=[
	@interface CustomEnumItem
	.Name string
	.EnumType string
]=]
type CustomEnumItem = typeof(EnumUtil.createEnumItem("", ""))


return table.freeze(EnumUtil)