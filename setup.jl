using Pkg

#activate environment in working directory
Pkg.activate(@__DIR__)

#instantiate environment
Pkg.instantiate()

download("https://www.dropbox.com/s/gwgxvno5ukwgohp/short_avail.zip?dl=0", joinpath(@__DIR__, "short_avail.zip"))

println("Please extract the zip file short_avail.zip in the directory $@__DIR__")
