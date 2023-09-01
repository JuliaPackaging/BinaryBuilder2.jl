module BinaryBuilderSourcesExt

# Define adapters to convert from `AbstractSource` objects to `JLLSource` objects:
using BinaryBuilderSources, JLLGenerator
JLLGenerator.JLLSourceRecord(as::AbstractSource) = JLLSourceRecord(source(as), content_hash(fas))

end # module
