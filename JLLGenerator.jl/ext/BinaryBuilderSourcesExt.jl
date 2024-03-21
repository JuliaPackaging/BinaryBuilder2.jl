module BinaryBuilderSourcesExt

# Define adapters to convert from `AbstractSource` objects to `JLLSourceRecord` objects:
using BinaryBuilderSources, JLLGenerator
JLLGenerator.JLLSourceRecord(as::AbstractSource) = JLLSourceRecord(source(as), content_hash(as))

end # module
