# MultiHashParsing.jl

This package provides utilities for parsing/serializing strings that contain hashes as well as an identifying tag that declares what kind of hash it is.
Examples are strings such as `sha1:f10e2821bbbea527ea02200352313bc059445190` or `sha256:688787d8ff144c502c7f5cffaafe2cc588d86079f9de88304c26b0cb99ce91c6`.
This is useful for packages such as `BinaryBuilder2` where users can embed hashes for archives that may report different kinds of hashes.
While this package can attempt to guess what hash algorithm is being used based on length, as more hash types are added, this quickly becomes impossible and such usage should be discouraged.

## Currently implemented hash types

- `SHA1HAsh`
- `SHA256Hash`
