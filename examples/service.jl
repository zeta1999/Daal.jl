using Cxx
using Daal

### Include auxiliary C++ functions for printing the results
addHeaderDir(@__DIR__, kind=C_System)
addHeaderDir(joinpath(Daal.daalrootdir, "examples", "cpp", "source", "utils"), kind=C_System)
cxxinclude("service.h")

printNumericTable(dataTable, message::String, nPrintedRows::Integer = 0, nPrintedCols::Integer = 0, interval::Integer = 10) =
    icxx"printNumericTable($(dataTable), $message, $nPrintedRows, $nPrintedCols, $interval);"

printNumericTables(::Type{T1}, ::Type{T2}, dataTable1, dataTable2, title1 = "", title2 = "", message = "", nPrintedRows = 0, interval = 15) where {T1,T2} =
    icxx"printNumericTables<$T1,$T2>($(dataTable1), $(dataTable2), $title1, $title2, $message, $nPrintedRows, $interval);"

createSparseTable(::Type{T}, datasetFileName::String) where {T<:Union{Float32,Float64}} = icxx"daal::services::SharedPtr<CSRNumericTable>(createSparseTable<$T>($datasetFileName));"

readTensorFromCSV(datasetFileName::String) = icxx"readTensorFromCSV($datasetFileName);"

getDimensionSize(o, dim::Integer) = icxx"$o->getDimensionSize($dim);"

printTensors(::Type{T1}, ::Type{T2}, dataTable1, dataTable2, title1 = "", title2 = "", message = "", nPrintedRows = 0, interval = 15) where {T1,T2} =
    icxx"printTensors<$T1,$T2>($(dataTable1), $(dataTable2), $title1, $title2, $message, $nPrintedRows, $interval);"
