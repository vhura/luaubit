--!strict
--[[
https://github.com/vhura/luaubit
]]

export type ByteArray = {[number]: number}
export type Bits = {[number]: number} -- pedantic
export type FromNumberMode = "u32" | "u64"

local byte_random = Random.new()

local luaubit = {}

--[[
clears and freezes the given ByteArray or Bits byte_array_or_bits
]]
function luaubit.destroy(byte_array_or_bits: ByteArray | Bits): nil
	assert(byte_array_or_bits, "byte_array_or_bits must be provided!")

	table.clear(byte_array_or_bits)
	table.freeze(byte_array_or_bits)

	return nil
end

-- OPERATIONS

function luaubit.reverse(bits: Bits): nil
	assert(bits, "bits must be provided!")
	
	for i = 1, #bits//2 do
		--[[
		bits[i] = bits[#bits-i+1]
		bits[#bits-i+1] = bits[i]
		]]
		bits[i], bits[#bits-i+1] = bits[#bits-i+1], bits[i]
	end
	
	return nil
end

--[[
pads the given Bits bits with padding 0s
]]
function luaubit.pad(bits: Bits, padding: number): nil
	assert(bits, "bits must be provided!")
	assert(padding, "padding must be provided!")
	assert(type(padding) == "number", "padding must be of type number!")
	
	for i = #bits + 1, #bits + padding do
		bits[i] = 0
	end
	return nil
end

--[[
pads the given Bits bits until its length is equal to goal
]]
function luaubit.pad_until(bits: Bits, goal: number): nil
	assert(bits, "bits must be provided!")
	assert(goal, "goal must be provided!")
	assert(type(goal) == "number", "goal must be of type number!")
	
	local padding = goal - #bits
	luaubit.pad(bits, padding)
	
	return nil
end

--[[
pads either bits_a or bits_b until they share the same length, prioritizing the length of the larger Bits
]]
function luaubit.equalize(bits_a: Bits, bits_b: Bits): nil
	assert(bits_a, "bits_a must be provided!")
	assert(bits_b, "bits_b must be provided!")
	
	local len_a, len_b = #bits_a, #bits_b
	local larger = len_a > len_b and bits_a or bits_b
	local smaller = len_a < len_b and bits_a or bits_b
	
	luaubit.pad_until(smaller, #larger)
	
	return nil
end

--[[
creates a table containing the bits in the given ByteArray byte_array
]]
function luaubit.to_bits(byte_array: ByteArray): Bits
	assert(byte_array, "byte_array must be provided!")
	
	local bits = table.create(#byte_array * 8, nil) :: Bits
	local index: number = 1
	
	for i, byte in byte_array do
		local copy = byte
		
		for i = 8, 1, -1 do
			local remainder: number = copy % 2
			
			local bit: number = remainder == 1 and 1 or 0
			bits[index] = bit
			
			copy //= 2
			index += 1
		end
	end
	
	return bits
end

--[[
writes the bits of Bits bits to ByteArray byte_array as bytes
as Bits and ByteArray both have fixed lengths, bits must be of length #byte_array * 8
]]
function luaubit.to_bytes_direct(bits: Bits, byte_array: ByteArray): nil
	assert(bits, "bits must be provided!")
	assert(byte_array, "byte_array must be provided!")
	assert(#bits == #byte_array*8, "length of bits must be exactly 8 times the length of byte_array")
	
	for i = 1, #byte_array do
		local byte = 0
		for ii = 1, 8 do
			if bits[((i-1) * 8) + ii] == 1 then
				byte += 2^(7-(ii-1)) -- 1 based indexing :(
			end
		end
		
		byte_array[i] = byte
	end
	
	return nil
end

--[[
applies the bitwise NOT operation on ByteArray byte_array
]]
function luaubit.b_not(byte_array: ByteArray): nil
	assert(byte_array, "byte_array must be provided!")
	
	local bits: Bits = luaubit.to_bits(byte_array)
	for i, bit in bits do
		bits[i] = bit == 1 and 0 or 1
	end
	
	luaubit.to_bytes_direct(bits, byte_array)
	luaubit.destroy(bits)
	return nil
end

--[[
applies the bitwise OR opreation on ByteArrays byte_array and comparison
]]
function luaubit.b_or(byte_array: ByteArray, comparison: ByteArray): nil
	assert(byte_array, "byte_array must be provided!")
	assert(comparison, "comparison must be provided!")
	
	local bits_a = luaubit.to_bits(byte_array)
	local bits_b = luaubit.to_bits(comparison)
	luaubit.equalize(bits_a, bits_b)
	
	local result_bits = {} :: Bits
	for i = 1, #bits_a do
		result_bits[i] = (bits_a[i] == 0 and bits_b[i] == 0) and 0 or 1
	end
	
	luaubit.to_bytes_direct(result_bits, byte_array)
	luaubit.destroy(bits_a)
	luaubit.destroy(bits_b)
	luaubit.destroy(result_bits)
	return nil
end

--[[
applies the bitwise AND operation to ByteArrays byte_array and comparison
]]
function luaubit.b_and(byte_array: ByteArray, comparison: ByteArray): nil
	assert(byte_array, "byte_array must be provided!")
	assert(comparison, "comparison must be provided!")
	
	local bits_a = luaubit.to_bits(byte_array)
	local bits_b = luaubit.to_bits(comparison)
	luaubit.equalize(bits_a, bits_b)

	local result_bits = {} :: Bits
	for i = 1, #bits_a do
		result_bits[i] = (bits_a[i] == 0 or bits_b[i] == 0) and 0 or 1
	end

	luaubit.to_bytes_direct(result_bits, byte_array)
	luaubit.destroy(bits_a)
	luaubit.destroy(bits_b)
	luaubit.destroy(result_bits)
	return nil
end

--[[
applies the bitwise XOR operation to ByteArrays byte_array and comparison
]]
function luaubit.b_xor(byte_array: ByteArray, comparison: ByteArray): nil
	assert(byte_array, "byte_array must be provided!")
	assert(comparison, "comparison must be provided!")
	
	local bits_a = luaubit.to_bits(byte_array)
	local bits_b = luaubit.to_bits(comparison)
	luaubit.equalize(bits_a, bits_b)

	local result_bits = {} :: Bits
	for i = 1, #bits_a do
		result_bits[i] = (bits_a[i] ~= bits_b[i]) and 1 or 0
	end

	luaubit.to_bytes_direct(result_bits, byte_array)
	luaubit.destroy(bits_a)
	luaubit.destroy(bits_b)
	luaubit.destroy(result_bits)
	return nil
end

--[[
applies the bitwise logical rshift operation to ByteArray byte_array with displacement of number displacement
]]
function luaubit.r_shift(byte_array: ByteArray, displacement: number): nil
	assert(byte_array, "byte_array must be provided")
	assert(displacement, "displacement must be provided!")
	assert(type(displacement) == "number", "displacement must be of type number!")
	assert(byte_array, "byte_array must be provided!")
	assert(#byte_array*8 == 64 or #byte_array*8 == 32, "byte_array must be a 32 bit or 64 bit integer!")
	
	local length = #byte_array
	local mode = length == 32 and "u32" or "u64"
	
	local number = luaubit.to_number(byte_array)
	for i = 1, displacement do
		number//=2
	end
	
	local result_bytes = luaubit.from_number(number, mode :: FromNumberMode)
	for i, byte in result_bytes do
		byte_array[i] = byte
	end
	
	luaubit.destroy(result_bytes)
	return nil
end

--[[
applies the bitwise logical lshift operation to ByteArray byte_array with displacement of number displacement
]]
function luaubit.l_shift(byte_array: ByteArray, displacement: number): nil
	assert(byte_array, "byte_array must be provided")
	assert(displacement, "displacement must be provided!")
	assert(type(displacement) == "number", "displacement must be of type number!")
	assert(byte_array, "byte_array must be provided!")
	assert(#byte_array*8 == 64 or #byte_array*8 == 32, "byte_array must be a 32 bit or 64 bit integer!")

	local length = #byte_array
	local mode = length == 32 and "u32" or "u64"

	local number = luaubit.to_number(byte_array)
	for i = 1, displacement do
		number *= 2
	end

	local result_bytes = luaubit.from_number(number, mode :: FromNumberMode)
	for i, byte in result_bytes do
		byte_array[i] = byte
	end

	luaubit.destroy(result_bytes)
	return nil
end

-- BYTEARRAY

--[[
determines if the given number byte is a valid byte, second return value is a description of why the byte is invalid
]]
function luaubit.verify_byte(byte: number): (boolean, string?)
	assert(byte, "byte  must be provided!")
	
	if type(byte) ~= "number" then
		return false, "byte must be of type number"
	elseif byte < 0 then
		return false, "byte must be positive"
	elseif byte > 255 then
		return false, "byte must be less than 255"
	elseif byte % 1 ~= 0 then
		return false, "byte must be an integer"
	end
	
	return true
end

--[[
creates a ByteArray with the given length len. returned array is filled with 0x0
]]
function luaubit.new(len: number): ByteArray
	assert(len, "length must be provided!")
	assert(type(len) == "number", "len must be of type number!")
	
	local byte_array = table.create(len, 0x0)
	return byte_array
end

--[[
creates a ByteArray with the given length len. returned array is f illed with random bytes
]]
function luaubit.random_bytes(len: number): ByteArray
	assert(len, "length must be provided!")
	assert(type(len) == "number", "len must be of type number!")
	
	local byte_array = table.create(len, nil)
	for i = 1, len do
		byte_array[i] = byte_random:NextInteger(0, 255)
	end
	
	return byte_array
end

--[[
creates a ByteArray with the given numbers ...
]]
function luaubit.from_bytes(...: number): ByteArray
	assert(..., "at least one number must be provided!")
	
	local bytes = {...}
	local byte_array = table.create(#bytes, nil) :: ByteArray
	
	for i, byte in bytes do
		local valid, response = luaubit.verify_byte(byte)
		if not valid then
			luaubit.destroy(byte_array)
			luaubit.destroy(bytes)
			error(response, 2)
		end
		byte_array[#byte_array + 1] = byte
	end
	
	return byte_array
end

--[[
creates a ByteArray with the given string str
]]
function luaubit.from_string(str: string): ByteArray
	assert(str, "str must be provided!")
	assert(type(str), "str must be of type string!")
	
	local characters = str:split("")
	local byte_array = table.create(#characters, nil) :: ByteArray
	
	for i, character in characters do
		byte_array[i] = string.byte(character)
	end
	
	return byte_array
end

--[[
creates a ByteArray with the given unsigned integer of the given length (u32 or u64)
]]
function luaubit.from_number(number: number, mode: FromNumberMode): ByteArray
	assert(number, "number must be provided!")
	assert(type(number) == "number", "number must be of type number!")
	assert(number > 0, "number must be positive!")
	assert(number % 1 == 0, "number must be integer!")
	assert(mode, "mode must be provided!")
	assert((mode == "u32") or (mode == "u64"), "mode must be either 'u32' or 'u64'")
	
	local bits = {} :: Bits
	local i = number
	while i > 0 do
		local remainder: number = i % 2
		bits[#bits + 1] = remainder
		
		i//=2
	end
	
	luaubit.pad_until(bits, mode == "u32" and 32 or 64)
	luaubit.reverse(bits)
	
	local byte_array = table.create(#bits/8, 0x0) :: ByteArray
	luaubit.to_bytes_direct(bits, byte_array)
	
	luaubit.destroy(bits)
	return byte_array
end

--[[
creates a string with the given ByteArray byte_array
will destroy byte_array if boolean trash is true
]]
function luaubit.to_string(byte_array: ByteArray, trash: boolean?): string
	assert(byte_array, "byte_array must be provided!")
	if trash then
		assert(type(trash) == "boolean", "trash must be of type boolean!")
	end
	
	local str: string = ""
	for i, byte in byte_array do
		str ..= string.char(byte)
	end
	
	if trash then
		luaubit.destroy(byte_array)
	end
	
	return str
end

--[[
packs ByteArray byte_array as the u32 or u64 integer it represents
will destroy byte_array if boolean trash is true
]]
function luaubit.to_number(byte_array: ByteArray, trash: boolean?): number
	assert(byte_array, "byte_array must be provided!")
	assert(#byte_array*8 == 64 or #byte_array*8 == 32, "byte_array must be a 32 bit or 64 bit integer!")
	if trash then
		assert(type(trash) == "boolean", "trash must be of type boolean!")
	end
	
	local bits = luaubit.to_bits(byte_array)

	local length = #bits
	local mode = length == 32 and "u32" or "u64"

	local number = 0
	for i = 0, length do
		local index = length - i
		local bit = bits[i]

		if bit == 1 then
			number += 2^index
		end
	end
	
	if trash then
		luaubit.destroy(byte_array)
	end
	
	luaubit.destroy(bits)
	return number
end

return luaubit
