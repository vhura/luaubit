# luaubit
bitwise manipulation on bytearrays rather than numbers being treated as unsigned 32 bit integers. made for practice, not to be "better" than bit32 or any other implenetations of bit manipulation.

# how to use
ByteArrays are statically sized arrays that should generally be modified using luaubit functions. all luaubit functions function as "applications" returning no value, therefore code using luaubit should look something like this
```lua
local myNumberBytes: luaubit.ByteArray = luaubit.from_number(300)
luaubit.shift_r(myNumberBytes, 2)
print(luaubit.to_number(myNumberBytes)) --> 75
```
other than that, just reference the docstrings.
