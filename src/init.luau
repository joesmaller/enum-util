--!strict
--[=[
	@class Enum-Util
]=]

local TOSTRING_ENUM = "Enum.%s"
local TOSTRING_ENUMITEM = "Enum.%s.%s"
local ERROR_INCORRECT_ENUMTYPE = "Expected %q for CustomEnumItem %q.EnumType, got %q"
local ERROR_INVALID_TYPE = "invalid argument #%s to '%s' (%s expected, got %s)"
local ERROR_INVALD_INDEX = "%q is a restricted CustomEnumItem index"
local ERROR_INVALID_ENUMITEM_NAME = "%q is not a valid CustomEnumItem name for CustomEnum %q"
local ERROR_DUPLICATE_ENUMITEM = "%q is a duplicate CustomEnumItem within %q"
local ERROR_EXISTING_ENUM = "CustomEnum %q already exists, unable to create"

local EnumUtil = {}
local _enums: {[string]: CustomEnum} = {}

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
	assert(not _enums[enumName], ERROR_EXISTING_ENUM:format(enumName))

	local newEnum = {}

	newEnum.Name = enumName

	-- add the enum items to the enum
	for _,enumItem in enumItems do
		assert(not (enumItem.Name == "Name"), ERROR_INVALID_ENUMITEM_NAME:format(enumItem.Name, enumName))
		assert(not (enumItem.Name == "GetEnumItems"), ERROR_INVALID_ENUMITEM_NAME:format(enumItem.Name, enumName))
		assert(not newEnum[enumItem.Name], ERROR_DUPLICATE_ENUMITEM:format(enumItem.Name, enumName))
		assert(enumItem.EnumType == enumName, ERROR_INCORRECT_ENUMTYPE:format(enumName, enumItem.Name, enumItem.EnumType))
		newEnum[enumItem.Name] = enumItem
	end

	function newEnum:GetEnumItems()
		return table.clone(enumItems)
	end

	local result = table.freeze(setmetatable(newEnum, {
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

	_enums[enumName] = result

	return result
end

--[=[
	@param enumName string
	@param rawEnumItems {[string]: {[any]: any}}
	@return CustomEnum

	Returns a new CustomEnum from a dictionary of tables, where the index in
	the dictionary corresponds with the enum item name.
]=]
function EnumUtil.createEnumFromDictionary(enumName: string, rawEnumItems: {[string]: {[any]: any}}): CustomEnum
	assertFunctionType("createEnum", 1, "string", enumName)
	assertFunctionType("createEnum", 2, "table", rawEnumItems)

	local enumItems: {CustomEnumItem} = {}

	for enumItemName, dataTable in rawEnumItems do
		local newEnumItem = EnumUtil.createEnumItem(enumName, enumItemName, dataTable)
		table.insert(enumItems, newEnumItem)
	end

	return EnumUtil.createEnum(enumName, enumItems)
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