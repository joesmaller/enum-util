--!strict
--[=[
	@class Enum-Util
]=]

local TOSTRING_ENUM = "Enum.%s"
local TOSTRING_ENUMITEM = "Enum.%s.%s"
local ERROR_INVALID_TYPE = "invalid argument #%s to '%s' (%s expected, got %s)"
local ERROR_INVALD_INDEX = "%q is a restricted CustomEnumItem index"

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

	if dataTable then
		for index in dataTable do
			assert(index ~= "Name", ERROR_INVALD_INDEX:format(index))
			assert(index ~= "EnumType", ERROR_INVALD_INDEX:format(index))
		end
	end

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
	@param enumName string
	@param enumItems {CustomEnumItem}
	@return CustomEnum

	Creates a new CustomEnum from an array of CustomEnumItems
]=]
function EnumUtil.createEnum(enumName: string, enumItems: {CustomEnumItem}): CustomEnum
	assertFunctionType("createEnum", 1, "string", enumName)
	assertFunctionType("createEnum", 2, "table", enumItems)

	local newEnum = {}

	newEnum.Name = enumName

	-- add the enum items to the enum
	for _,enumItem in enumItems do
		if enumItem.EnumType ~= enumName then
			error(ERROR_INVALID_TYPE:format(enumName, enumItem.Name, enumItem.EnumType))
		end
		newEnum[enumItem.Name] = enumItem
	end

	function newEnum:GetEnumItems()
		return table.clone(enumItems)
	end

	return table.freeze(setmetatable(newEnum, {
		__EnumProxy = newproxy();
		__eq = function(self, other)
			if type(other) ~= "table" then return false end
			local selfMetatable = getmetatable(self)
			local otherMetatable = getmetatable(other)
			if otherMetatable and (selfMetatable.__EnumProxy == otherMetatable.__EnumProxy) then return true end
			return false
		end;
		__tostring = function()
			return TOSTRING_ENUM:format(enumName)
		end;
	}))
end


--[=[
	@interface CustomEnumItem
	.Name string
	.EnumType string
]=]
type CustomEnumItem = typeof(EnumUtil.createEnumItem("", ""))

--[=[
	@interface CustomEnum
	.Name string
	.GetEnumItems () -> ({CustomEnumItem})
	[string] CustomEnumItem
]=]
type CustomEnum = typeof(EnumUtil.createEnum("", {}))


return table.freeze(EnumUtil)