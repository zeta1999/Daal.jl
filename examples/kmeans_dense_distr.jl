using Daal
using Daal.Algorithms
using Daal.Algorithms.Kmeans
using Daal.DataManagement

include("service.jl") # e.g. pritning of results

DAAL_PREFIX = joinpath(Daal.daalrootdir, "examples", "data")

# K-Means algorithm parameters
const nClusters   = 20
const nIterations = 5
const nBlocks     = 4
const nVectorsInBlock = 2500

const dataFileNames = [
    "distributed/kmeans_dense_1.csv", "distributed/kmeans_dense_2.csv",
    "distributed/kmeans_dense_3.csv", "distributed/kmeans_dense_4.csv"
]

function main(output = true)
    masterAlgorithm = Kmeans.Distributed(Daal.Step2Master, nClusters)

    data = Vector{Any}(nBlocks)

    assignments = Vector{Any}(nBlocks)
    goalFunction = nothing

    masterInit = Kmeans.Init.Distributed(Daal.Step2Master, Float64, Kmeans.Init.RandomDense, nClusters)
    for i in 1:nBlocks
        # Initialize FileDataSource<CSVFeatureManager> to retrieve the input data from a .csv file
        dataSource = DataManagement.FileDataSource(joinpath(DAAL_PREFIX, dataFileNames[i]), DataManagement.doAllocateNumericTable, DataManagement.doDictionaryFromContext)

        # Retrieve the data from the input file
        DataManagement.loadDataBlock(dataSource)
        data[i] = DataManagement.getNumericTable(dataSource)

        # Create an algorithm object for the K-Means algorithm
        localInit = Kmeans.Init.Distributed(Daal.Step1Local, Float64, Kmeans.Init.RandomDense, nClusters, nBlocks*nVectorsInBlock, (i - 1)*nVectorsInBlock)

        Algorithms.setInput(localInit, Kmeans.Init.Data, data[i])
        Algorithms.compute(localInit)
        Algorithms.addInput(masterInit, Kmeans.Init.PartialResults, Kmeans.Init.getPartialResult(localInit))
    end

    Algorithms.compute(masterInit)
    Kmeans.Init.finalizeCompute(masterInit)
    centroids = Kmeans.Init.get(Kmeans.Init.getResult(masterInit), Kmeans.Init.Centroids)

    # Calculate centroids
    for it in 1:nIterations
        for i in 1:nBlocks
            # Create an algorithm object for the K-Means algorithm
            localAlgorithm = Kmeans.Distributed(Daal.Step1Local, nClusters, false)

            # Set the input data to the algorithm
            Algorithms.setInput(localAlgorithm, Kmeans.Data, data[i])
            Algorithms.setInput(localAlgorithm, Kmeans.InputCentroids, centroids)

            Algorithms.compute(localAlgorithm)
            Algorithms.addInput(masterAlgorithm, Kmeans.PartialResults, Kmeans.getPartialResult(localAlgorithm))
        end

        Algorithms.compute(masterAlgorithm)
        Kmeans.finalizeCompute(masterAlgorithm)

        centroids = Kmeans.get(Kmeans.getResult(masterAlgorithm), Kmeans.Centroids)
        goalFunction = Kmeans.get(Kmeans.getResult(masterAlgorithm), Kmeans.GoalFunction)
    end

    # Calculate assignments
    for i = 1:nBlocks
        # Create an algorithm object for the K-Means algorithm
        localAlgorithm = Kmeans.Batch(nClusters, 0)

        # Set the input data to the algorithm
        Algorithms.setInput(localAlgorithm, Kmeans.Data, data[i])
        Algorithms.setInput(localAlgorithm, Kmeans.InputCentroids, centroids)

        Algorithms.compute(localAlgorithm)

        assignments[i] = Kmeans.get(Kmeans.getResult(localAlgorithm), Kmeans.Assignments)
    end

    # Print the clusterization results
    printNumericTable(assignments[1], "First 10 cluster assignments from 1st node:", 10)
    printNumericTable(centroids, "First 10 dimensions of centroids:", 20, 10)
    printNumericTable(goalFunction, "Goal function value:")

    return 0
end

main(false) # compile
@time main()
