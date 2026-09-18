# perf_exercise.jl
#
# ECON 5010 — Performance Optimization Exercise
# ------------------------------------------------
# Every function below computes something simple and correct, but each
# one is written in a way that makes Julia run much slower than it
# needs to.
#
# YOUR TASK:
#   1. Run `main()` once and note the @time output (baseline).
#   2. Profile the code — use @time / @btime (BenchmarkTools.jl),
#      @code_warntype, and/or @allocated / --track-allocation — to find
#      the bottlenecks in each function.
#   3. Rewrite each function so it runs faster and allocates less
#      memory, WITHOUT changing what it computes. (Your output values
#      should match the originals.)
#   4. Be ready to explain, for each fix: what was slow, why, and how
#      you fixed it.
#
# Hints on what to look for (this is most of what you'll need to know
# about Julia performance):
#   - Non-constant global variables
#   - Containers that don't have a concrete element type
#   - Allocating memory inside a loop when you don't need to
#   - Copying data (e.g. via slicing) when a view would do
#   - Growing a plain array one element at a time
#   - Type instability (a variable that can hold more than one type)
#
# You will not need every hint for every function.

using Random
using Statistics

# --- Global state used directly inside the functions below ---
N = 2_000_000
data = rand(N)

# 1. Summary statistics
#I made two changes: Declaring a type of the array in advance
#and I initialized the size of the array at the beginning instead of letting
#it grow one step a time
#Runtime went from ~0.69 to ~0.31, and 
function compute_stats()
    results = Array{Float64}(undef, 5)
    results[1] = sum(data)
    results[2] = mean(data)
    results[3] = minimum(data)
    results[4] = maximum(data)
    results[5] = std(data)
    return results
end

function compute_stats_orig()
    results = []
    push!(results,sum(data))
    push!(results,mean(data))
    push!(results,minimum(data))
    push!(results,maximum(data))
    push!(results, std(data))
    return results
end





# 2. Monte Carlo estimate of pi
#Estimating pi..
#I achieved this decrease in runtime by decreasing the number of allocations from 1.02 Million to 16.59K.
#Prior: 0.154582 seconds (1.02 M allocations: 46.639 MiB, 63.22% gc time, 25.75% compilation time)
#Current: 0.044874 seconds (16.59 k allocations: 883.844 KiB, 91.21% compilation time)

function monte_carlo_pi(n)
    count = 0
    for i in 1:n
        #point = [rand(), rand()] #It seems like we do not need to allocate space for the points because we do not use them later on.
	#if point[1]^2 + point[2]^2 <= 1
	if rand()^2 + rand()^2 <= 1.0
            count += 1
        end
    end
    return 4 * count / n
end

function monte_carlo_pi_orig(n)
    count = 0
    for i in 1:n
        point = [rand(), rand()] #It seems like we do not need to allocate space for the points because we do not use them later on.
	if point[1]^2 + point[2]^2 <= 1
	#if rand()^2 + rand()^2 <= 1.0
            count += 1
        end
    end
    return 4 * count / n
end





# 3. Row sums of a matrix
## I changed the sum list from normal slicing to view. This helped me get rid of a lot of allocations to 3. It also decreased runtime
#though runtime decrease is really visible when we have a small matrix
##Computing row sums...
# New time (for 50k by 20k): 20.935563 seconds (3 allocations: 315.992 KiB)
# Old Time: 23.713520 seconds (160.02 k allocations: 5.965 GiB, 1.10% gc time)

#New time(for 2k by 2k):  0.017349 seconds (3 allocations: 15.695 KiB)

#Old Time(for 2k by 2k): 0.034827 seconds (8.01 k allocations: 30.725 MiB)


function row_sums(A)
    n = size(A, 1)
    sums = Array{Float64}(undef,n)
    for i in 1:n
	row = @view A[i,:]
    	sums[i] = sum(row)
    end
    return sums
end

function row_sums_orig(A)
    n = size(A, 1)
    sums = []
    for i in 1:n
	row = A[i,:]
	push!(sums,sum(row))
    end
    return sums
end




# 4. Build a text report
# I have been able to decrease the number of allocations by using the join function. I found it
# in julia documentation. It allows us to decrease the allocations when strings are being joined.
# I believe it can be sped up further by making all the lists for all the rows join together at once. 
#   0.000003 seconds (20 allocations: 2.594 KiB)
#  0.000003 seconds (42 allocations: 4.094 KiB)

function build_report(labels, values)
    report = ""
    for i in 1:length(labels)
    	report = join([report,labels[i],": ",string(values[i]),"\n "])
    end
    return report
end

function build_report_orig(labels, values)
    report = ""
    for i in 1:length(labels)
        report = report * labels[i] * ": " * string(values[i]) * "\n"
    end
    return report
end




# 5. Conditional accumulator
#Original Runtime (with increased N): 174.081998 seconds (6.84 k allocations: 331.914 KiB, 0.03% compilation time)
#7.499887559875121e8
#New Runtime: 139.057526 seconds (5.71 k allocations: 282.711 KiB, 0.09% compilation time)
#7.499887559875121e8
# I got rid of the extra else condition which allowed me to decrease the runtime, as well as allocations because 0 was never allocated. 



function unstable_sum(xs)
    #total = sum(filter(y->y>0.5,xs))
    
    total = 0
    for x in xs
        if x > 0.5
	    
	    total += x
        
	 #else #### I Dont think we need to check for anything else 
         #   total += 0
        end
    end
    return total
end
function unstable_sum_orig(xs)
    
    total = 0
    for x in xs
        if x > 0.5
	    
	    total += x
        
	 else 
            total += 0
        end
    end
    return total
end




function main()
    println("Computing stats...")
    @time stats_orig = compute_stats_orig()
    println("Original Stats $stats_orig \n")
    @time stats = compute_stats()
    println("Optimized States: $stats\n\n\n")


    println("Estimating pi...")
    @time pi_est = monte_carlo_pi_orig(1_000_000)
    println("Original Pi: $pi_est\n")

    println("Estimating pi...")
    @time pi_est = monte_carlo_pi(1_000_000)
    println("Optimized Pi: $pi_est\n\n\n")

    println("Computing row sums...")
    A = rand(2000, 2000)
    @time sums_orig = row_sums_orig(A)[1:5]
    println("Original $sums_orig\n")
    @time sums = row_sums(A)[1:5]
    println("Optimized $sums\n\n\n")

    #println("Building report...")
    labels = ["sum", "mean", "max", "min", "std"]
    @time report_orig = build_report_orig(labels,stats)
    println("Original report $report_orig\n")

    @time report = build_report(labels,stats)
    println("Optimized report $report\n\n\n")



    println("Summing with condition...")
    @time sum = unstable_sum_orig(data)
    println("Original sum: $sum\n")
    
    @time sum = unstable_sum(data)
    println("Optimized sum: $sum\n\n\n")


end

main()
