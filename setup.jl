using Pkg

#activate environment in working directory
Pkg.activate(@__DIR__)

#instantiate environment
Pkg.instantiate()

download("www.kaggle.com/jekyllstein/ib-short-avail", joinpath(@__DIR__, "short_avail.zip"))

println("Please extract the zip file short_avail.zip in the directory $@__DIR__")