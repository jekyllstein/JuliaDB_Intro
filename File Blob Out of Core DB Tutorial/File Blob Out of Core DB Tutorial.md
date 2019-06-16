
# Set Up Environment


```julia
#Base Tools
using Distributed
addprocs(8) #add workers for multithreaded testing
```




    8-element Array{Int64,1}:
     2
     3
     4
     5
     6
     7
     8
     9




```julia
#Activate Environment For Directory on each worker
@everywhere using Pkg
@everywhere Pkg.activate(".")
Pkg.status()
```

    [32m[1m    Status[22m[39m `~/Dropbox (Blackbody Group)/Julia Programming Projects/JuliaDB_Intro/Project.toml`
     [90m [6e4b80f9][39m[37m BenchmarkTools v0.4.2[39m
     [90m [336ed68f][39m[37m CSV v0.5.5[39m
     [90m [7073ff75][39m[37m IJulia v1.18.1[39m
     [90m [6deec6e2][39m[37m IndexedTables v0.12.0[39m
     [90m [a93385a2][39m[37m JuliaDB v0.12.0[39m
     [90m [a15396b6][39m[37m OnlineStats v0.23.0[39m
     [90m [91a5bcdd][39m[37m Plots v0.25.1[39m
     [90m [2913bbd2][39m[37m StatsBase v0.30.0[39m
     [90m [f3b207a7][39m[37m StatsPlots v0.11.0[39m
     [90m [8ba89e20][39m[37m Distributed [39m
     [90m [10745b16][39m[37m Statistics [39m



```julia
#Import Database Tools For Workers
using OnlineStats
using BenchmarkTools
using JuliaDB
@everywhere using DelimitedFiles
using CSV
@everywhere using Dates
using StatsPlots
using Plots
```

    ┌ Info: Recompiling stale cache file /Users/jekyllstein/.julia/compiled/v1.1/StatsPlots/SiylL.ji for StatsPlots [f3b207a7-027a-5e70-b257-86293d7955fd]
    └ @ Base loading.jl:1184


# Load Files Into Indexed Tables

## File Examination


```julia
#Check all text files in directory.  The ones we care about start with the prefix "IB_usa_short_avail"
fnames = glob("short_avail/IB_usa_short_avail_*.txt")

```




    24875-element Array{String,1}:
     "short_avail/IB_usa_short_avail_2017-09-27_06-40-00.txt"
     "short_avail/IB_usa_short_avail_2017-09-27_06-45-00.txt"
     "short_avail/IB_usa_short_avail_2017-09-27_06-50-00.txt"
     "short_avail/IB_usa_short_avail_2017-09-27_06-55-00.txt"
     "short_avail/IB_usa_short_avail_2017-09-27_07-00-00.txt"
     "short_avail/IB_usa_short_avail_2017-09-27_07-05-00.txt"
     "short_avail/IB_usa_short_avail_2017-09-27_07-10-00.txt"
     "short_avail/IB_usa_short_avail_2017-09-27_07-15-00.txt"
     "short_avail/IB_usa_short_avail_2017-09-27_07-20-00.txt"
     "short_avail/IB_usa_short_avail_2017-09-27_07-25-00.txt"
     "short_avail/IB_usa_short_avail_2017-09-27_07-30-00.txt"
     "short_avail/IB_usa_short_avail_2017-09-27_07-35-00.txt"
     "short_avail/IB_usa_short_avail_2017-09-27_07-40-00.txt"
     ⋮                                                       
     "short_avail/IB_usa_short_avail_2018-04-25_10-05-00.txt"
     "short_avail/IB_usa_short_avail_2018-04-25_10-10-00.txt"
     "short_avail/IB_usa_short_avail_2018-04-25_10-15-00.txt"
     "short_avail/IB_usa_short_avail_2018-04-25_10-20-00.txt"
     "short_avail/IB_usa_short_avail_2018-04-25_10-25-00.txt"
     "short_avail/IB_usa_short_avail_2018-04-25_10-30-00.txt"
     "short_avail/IB_usa_short_avail_2018-04-25_10-35-00.txt"
     "short_avail/IB_usa_short_avail_2018-04-25_10-40-00.txt"
     "short_avail/IB_usa_short_avail_2018-04-25_10-45-00.txt"
     "short_avail/IB_usa_short_avail_2018-04-25_10-50-00.txt"
     "short_avail/IB_usa_short_avail_2018-04-25_10-55-00.txt"
     "short_avail/IB_usa_short_avail_2018-04-25_11-00-00.txt"




```julia
#Example file shows #BOF/#EOF lines, | delimeter, and '>' char in last column.  All these factors make parsing and type
#inference difficult
exFile = fnames[1]
readlines(exFile)
```




    13428-element Array{String,1}:
     "#BOF|2017.09.27|06:30:03"                                                            
     "#SYM|CUR|NAME|CON|ISIN|REBATERATE|FEERATE|AVAILABLE|"                                
     "A|USD|AGILENT TECHNOLOGIES INC|1715006|XXXXXXXU1016|0.0623|1.0977|>10000000|"        
     "AA|USD|ALCOA CORP|251962528|XXXXXXX21065|0.3373|0.8227|>10000000|"                   
     "AAAP|USD|ADVANCED ACCELERATOR APP-ADR|212212690|XXXXXXXT1007|-6.4292|7.5892|350000|" 
     "AABA|USD|ALTABA INC|278946664|XXXXXXX61017|0.8167|0.3433|>10000000|"                 
     "AABB|USD|ASIA BROADBAND INC|75216559|XXXXXXXL1008|0.9100|0.2500|1600000|"            
     "AABVF|USD|ABERDEEN INTERNATIONAL INC.|60152167|CA0030691012|0.9100|0.2500|10000|"    
     "AAC|USD|AAC HOLDINGS INC|169041192|XXXXXXX71083|-0.1012|1.2612|300000|"              
     "AACS|USD|AMERICAN COMMERCE SOLUTIONS|30207299|XXXXXXX91008|0.9100|0.2500|1900000|"   
     "AACTF|USD|AURORA SOLAR TECHNOLOGIES IN|195675323|CA05207J1084|-3.1229|4.2829|4000|"  
     "AAEH|USD|ALL AMERICAN ENERGY HOLDING|143664841|XXXXXXXW2098|0.9100|0.2500|50000|"    
     "AAGC|USD|ALL AMERICAN GOLD CORP|88362966|XXXXXXXV1026|0.8600|0.3000|9100000|"        
     ⋮                                                                                     
     "ZUMZ|USD|ZUMIEZ INC|34466024|XXXXXXX71015|-0.1635|1.3235|2400000|"                   
     "ZURVY|USD|ZURICH INSURANCE GROUP-ADR|105653547|XXXXXXX51049|-9.3903|10.5503|55000|"  
     "ZVTK|USD|ZEVOTEK INC|96765892|XXXXXXXB3042|0.9100|0.2500|6000|"                      
     "ZWBC|USD|GOLDKEY CORP|178731140|XXXXXXXN1046|NA|NA|60000|"                           
     "ZX|USD|CHINA ZENIX AUTO INTERNA-ADR|87836947|XXXXXXXE1047|-0.5574|1.7174|500000|"    
     "ZYME|USD|ZYMEWORKS INC|274189981|CA98985W1023|-14.3798|15.5398|2000|"                
     "ZYNE|USD|ZYNERBA PHARMACEUTICALS INC|202225021|XXXXXXXX1090|-15.4990|16.6590|200000|"
     "ZYTO|USD|ZYTO CORP|41119964|XXXXXXX21066|0.9100|0.2500|350000|"                      
     "ZYXI|USD|ZYNEX INC|52413740|XXXXXXXM1036|-11.6679|12.8279|200000|"                   
     "ZZLL|USD|ZZLL INFORMATION TECHNOLOGY|235604017|XXXXXXXP1030|0.9100|0.2500|150000|"   
     "ZZZOF|USD|ZINC ONE RESOURCES INC|274242368|CA98959W1041|-1.8239|2.9839|55000|"       
     "#EOF|13425"                                                                          



## Single File Loading Attempts


```julia
#DelimitedFiles parser can read into Array{Any} and make use of the comments keyword to ignore BOF/EOF
@btime readdlm(exFile, '|', comments = true)
testArray = readdlm(exFile, '|', comments = true)
```

      26.559 ms (478115 allocations: 15.80 MiB)





    13425×9 Array{Any,2}:
     "A"      "USD"  …   1.0977         ">10000000"  ""
     "AA"     "USD"      0.8227         ">10000000"  ""
     "AAAP"   "USD"      7.5892   350000             ""
     "AABA"   "USD"      0.3433         ">10000000"  ""
     "AABB"   "USD"      0.25    1600000             ""
     "AABVF"  "USD"  …   0.25      10000             ""
     "AAC"    "USD"      1.2612   300000             ""
     "AACS"   "USD"      0.25    1900000             ""
     "AACTF"  "USD"      4.2829     4000             ""
     "AAEH"   "USD"      0.25      50000             ""
     "AAGC"   "USD"  …   0.3     9100000             ""
     "AAGH"   "USD"      0.25     550000             ""
     "AAGIY"  "USD"      5.9899    90000             ""
     ⋮               ⋱                                 
     "ZTS"    "USD"      0.25           ">10000000"  ""
     "ZUMZ"   "USD"      1.3235  2400000             ""
     "ZURVY"  "USD"  …  10.5503    55000             ""
     "ZVTK"   "USD"      0.25       6000             ""
     "ZWBC"   "USD"       "NA"     60000             ""
     "ZX"     "USD"      1.7174   500000             ""
     "ZYME"   "USD"     15.5398     2000             ""
     "ZYNE"   "USD"  …  16.659    200000             ""
     "ZYTO"   "USD"      0.25     350000             ""
     "ZYXI"   "USD"     12.8279   200000             ""
     "ZZLL"   "USD"      0.25     150000             ""
     "ZZZOF"  "USD"      2.9839    55000             ""




```julia
#CSV read into in memory dataframe with original file
#keywords that allow this are footerskip and header. parser handles all other exceptions
@btime CSV.read(exFile, delim = '|', missingstring = "NA", header = 2, footerskip = 1)
dfEx = CSV.read(exFile, delim = '|', missingstring = "NA", footerskip=1, header=2)
```

    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`
      15.845 ms (25678 allocations: 2.18 MiB)
    warning: only found 2 / 9 columns on data row: 13426. Filling remaining columns with `missing`





<table class="data-frame"><thead><tr><th></th><th>#SYM</th><th>CUR</th><th>NAME</th><th>CON</th><th>ISIN</th><th>REBATERATE</th></tr><tr><th></th><th>String</th><th>String</th><th>String⍰</th><th>Int64⍰</th><th>String⍰</th><th>Float64⍰</th></tr></thead><tbody><p>13,425 rows × 9 columns (omitted printing of 3 columns)</p><tr><th>1</th><td>A</td><td>USD</td><td>AGILENT TECHNOLOGIES INC</td><td>1715006</td><td>XXXXXXXU1016</td><td>0.0623</td></tr><tr><th>2</th><td>AA</td><td>USD</td><td>ALCOA CORP</td><td>251962528</td><td>XXXXXXX21065</td><td>0.3373</td></tr><tr><th>3</th><td>AAAP</td><td>USD</td><td>ADVANCED ACCELERATOR APP-ADR</td><td>212212690</td><td>XXXXXXXT1007</td><td>-6.4292</td></tr><tr><th>4</th><td>AABA</td><td>USD</td><td>ALTABA INC</td><td>278946664</td><td>XXXXXXX61017</td><td>0.8167</td></tr><tr><th>5</th><td>AABB</td><td>USD</td><td>ASIA BROADBAND INC</td><td>75216559</td><td>XXXXXXXL1008</td><td>0.91</td></tr><tr><th>6</th><td>AABVF</td><td>USD</td><td>ABERDEEN INTERNATIONAL INC.</td><td>60152167</td><td>CA0030691012</td><td>0.91</td></tr><tr><th>7</th><td>AAC</td><td>USD</td><td>AAC HOLDINGS INC</td><td>169041192</td><td>XXXXXXX71083</td><td>-0.1012</td></tr><tr><th>8</th><td>AACS</td><td>USD</td><td>AMERICAN COMMERCE SOLUTIONS</td><td>30207299</td><td>XXXXXXX91008</td><td>0.91</td></tr><tr><th>9</th><td>AACTF</td><td>USD</td><td>AURORA SOLAR TECHNOLOGIES IN</td><td>195675323</td><td>CA05207J1084</td><td>-3.1229</td></tr><tr><th>10</th><td>AAEH</td><td>USD</td><td>ALL AMERICAN ENERGY HOLDING</td><td>143664841</td><td>XXXXXXXW2098</td><td>0.91</td></tr><tr><th>11</th><td>AAGC</td><td>USD</td><td>ALL AMERICAN GOLD CORP</td><td>88362966</td><td>XXXXXXXV1026</td><td>0.86</td></tr><tr><th>12</th><td>AAGH</td><td>USD</td><td>AMERICA GREAT HEALTH</td><td>280898497</td><td>XXXXXXXT1016</td><td>0.91</td></tr><tr><th>13</th><td>AAGIY</td><td>USD</td><td>AIA GROUP LTD-SP ADR</td><td>90162715</td><td>XXXXXXX72053</td><td>-4.8299</td></tr><tr><th>14</th><td>AAIIQ</td><td>USD</td><td>ALABAMA AIRCRAFT INDUSTRIES</td><td>48014358</td><td>XXXXXXXE1001</td><td>0.91</td></tr><tr><th>15</th><td>AAIR</td><td>USD</td><td>AVANTAIR INC</td><td>44026574</td><td>XXXXXXXT1016</td><td>0.91</td></tr><tr><th>16</th><td>AAL</td><td>USD</td><td>AMERICAN AIRLINES GROUP INC</td><td>139673266</td><td>XXXXXXXR1023</td><td>0.91</td></tr><tr><th>17</th><td>AAMC</td><td>USD</td><td>ALTISOURCE ASSET MANAGEMENT</td><td>118834665</td><td>VI02153X1080</td><td>-7.1874</td></tr><tr><th>18</th><td>AAME</td><td>USD</td><td>ATLANTIC AMERICAN CORP</td><td>265585</td><td>XXXXXXX91008</td><td>-2.4881</td></tr><tr><th>19</th><td>AAMTF</td><td>USD</td><td>ARMADA MERCANTILE LTD</td><td>75218554</td><td>CA0419041037</td><td>0.91</td></tr><tr><th>20</th><td>AAN</td><td>USD</td><td>AARON'S INC</td><td>3630029</td><td>XXXXXXX53006</td><td>0.91</td></tr><tr><th>21</th><td>AAOI</td><td>USD</td><td>APPLIED OPTOELECTRONICS INC</td><td>135423662</td><td>XXXXXXXU1025</td><td>-81.2981</td></tr><tr><th>22</th><td>AAON</td><td>USD</td><td>AAON INC</td><td>265595</td><td>XXXXXXX02069</td><td>0.7228</td></tr><tr><th>23</th><td>AAP</td><td>USD</td><td>ADVANCE AUTO PARTS INC</td><td>4027</td><td>XXXXXXXY1064</td><td>0.8818</td></tr><tr><th>24</th><td>AAPC</td><td>USD</td><td>ATLANTIC ALLIANCE PARTNERSHI</td><td>192379292</td><td>VGG048971078</td><td>-1.3158</td></tr><tr><th>25</th><td>AAPH</td><td>USD</td><td>AMERICAN PETRO-HUNTER INC</td><td>30207586</td><td>XXXXXXX71005</td><td>0.86</td></tr><tr><th>26</th><td>AAPJ</td><td>USD</td><td>AAP INC</td><td>95309032</td><td>XXXXXXXT1034</td><td>0.91</td></tr><tr><th>27</th><td>AAPL</td><td>USD</td><td>APPLE INC</td><td>265598</td><td>XXXXXXX31005</td><td>0.91</td></tr><tr><th>28</th><td>AAPT</td><td>USD</td><td>ALL AMERICAN PET CO INC</td><td>44001811</td><td>XXXXXXXF1066</td><td>0.86</td></tr><tr><th>29</th><td>AASP</td><td>USD</td><td>ALL-AMERICAN SPORTPARK INC</td><td>30207319</td><td>XXXXXXXP1057</td><td>0.86</td></tr><tr><th>30</th><td>AAST</td><td>USD</td><td>ALLIED AMERICAN STEEL CORP</td><td>88121627</td><td>XXXXXXX71033</td><td>0.86</td></tr><tr><th>&vellip;</th><td>&vellip;</td><td>&vellip;</td><td>&vellip;</td><td>&vellip;</td><td>&vellip;</td><td>&vellip;</td></tr></tbody></table>




```julia
#Fee Rate = Interest rate charged on borrowed shares
#Rebate rate = Fed funds rate minus interest rate charged on borrowed shares
#Available = number of shares available to borrow
names(dfEx)
```




    9-element Array{Symbol,1}:
     Symbol("#SYM")
     :CUR          
     :NAME         
     :CON          
     :ISIN         
     :REBATERATE   
     :FEERATE      
     :AVAILABLE    
     Symbol("")    




```julia
#Columns are accessed with dot syntax and contain missing values
#Note that there is a blank 9th column and a warning about one of the rows
dfEx.FEERATE
```




    13425-element CSV.Column{Union{Missing, Float64},Union{Missing, Float64}}:
      1.0977  
      0.8227  
      7.5892  
      0.3433  
      0.25    
      0.25    
      1.2612  
      0.25    
      4.2829  
      0.25    
      0.3     
      0.25    
      5.9899  
      ⋮       
      0.25    
      1.3235  
     10.5503  
      0.25    
       missing
      1.7174  
     15.5398  
     16.659   
      0.25    
     12.8279  
      0.25    
      2.9839  



### JuliaDB File Loading
loadtable() is a function that can read text files into an indexed table.  By default only a single argument is needed which is the path to the file.  Many keyword options exist but not as extensive as those for CSV.read().  By default it assumes the following:  
- ',' delimited (change with delim = '')
- use first line as header to name columns (change with header_exists = false)
- use the first 20 lines to infer column types
- Assume TextParse.NA_STRINGS contains any string examples that should be considered missing/NA values
- Reads file from first line (change with skiplines_begin = 1 to skip first line)
- If nprocs() > 1 will read as a distributed table in chunks (1 per worker).  Otherwise reads as a plain in memory indexed table.  Use `distributed=false` to load normally even with multiple workers


```julia
#Default NA strings
show(JuliaDB.TextParse.NA_STRINGS)
```

    ["#N/A", "#N/A N/A", "#NA", "#n/a", "#n/a n/a", "#na", "-1.#IND", "-1.#QNAN", "-1.#ind", "-1.#qnan", "-NaN", "-nan", "-nan", "-nan", "1.#IND", "1.#QNAN", "1.#ind", "1.#qnan", "N/A", "N/A", "NA", "NA", "NULL", "NaN", "n/a", "n/a", "na", "na", "nan", "nan", "nan", "null"]


```julia
#JuliaDB read into in memory dataframe with original file, fails due to parsing errors
loadtable(exFile, delim = '|', skiplines_begin = 1, distributed = false)
```

          From worker 2:	Error parsing short_avail/IB_usa_short_avail_2017-09-27_06-40-00.txt



    On worker 2:
    MethodError: no method matching iterate(::Nothing)
    Closest candidates are:
      iterate(!Matched::Core.SimpleVector) at essentials.jl:568
      iterate(!Matched::Core.SimpleVector, !Matched::Any) at essentials.jl:568
      iterate(!Matched::ExponentialBackOff) at error.jl:199
      ...
    indexed_iterate at ./tuple.jl:66
    getlineat at /Users/jekyllstein/.julia/packages/TextParse/tFXtC/src/util.jl:353
    Type at /Users/jekyllstein/.julia/packages/TextParse/tFXtC/src/csv.jl:629 [inlined]
    parsefill! at /Users/jekyllstein/.julia/packages/TextParse/tFXtC/src/csv.jl:560
    #_csvread_internal#26 at /Users/jekyllstein/.julia/packages/TextParse/tFXtC/src/csv.jl:328
    #_csvread_internal at ./none:0
    #22 at /Users/jekyllstein/.julia/packages/TextParse/tFXtC/src/csv.jl:110
    #open#310 at ./iostream.jl:369
    open at ./iostream.jl:367 [inlined]
    #_csvread_f#20 at /Users/jekyllstein/.julia/packages/TextParse/tFXtC/src/csv.jl:107 [inlined]
    #_csvread_f at ./none:0 [inlined]
    #csvread#25 at /Users/jekyllstein/.julia/packages/TextParse/tFXtC/src/csv.jl:125
    #csvread at ./none:0
    #_loadtable_serial#3 at /Users/jekyllstein/.julia/packages/JuliaDB/jDAlJ/src/util.jl:83
    #190 at ./none:0
    do_task at /Users/jekyllstein/.julia/packages/Dagger/sdZXi/src/scheduler.jl:259
    #112 at /Users/osx/buildbot/slave/package_osx64/build/usr/share/julia/stdlib/v1.1/Distributed/src/process_messages.jl:269
    run_work_thunk at /Users/osx/buildbot/slave/package_osx64/build/usr/share/julia/stdlib/v1.1/Distributed/src/process_messages.jl:56
    macro expansion at /Users/osx/buildbot/slave/package_osx64/build/usr/share/julia/stdlib/v1.1/Distributed/src/process_messages.jl:269 [inlined]
    #111 at ./task.jl:259

    

    Stacktrace:

     [1] compute_dag(::Dagger.Context, ::Dagger.Thunk) at /Users/jekyllstein/.julia/packages/Dagger/sdZXi/src/scheduler.jl:62

     [2] compute(::Dagger.Context, ::Dagger.Thunk) at /Users/jekyllstein/.julia/packages/Dagger/sdZXi/src/compute.jl:25

     [3] #fromchunks#47(::Nothing, ::Int64, ::Base.Iterators.Pairs{Union{},Union{},Tuple{},NamedTuple{(),Tuple{}}}, ::Function, ::Array{Dagger.Thunk,1}) at /Users/jekyllstein/.julia/packages/JuliaDB/jDAlJ/src/table.jl:148

     [4] (::getfield(JuliaDB, Symbol("#kw##fromchunks")))(::NamedTuple{(:output, :fnoffset),Tuple{Nothing,Int64}}, ::typeof(JuliaDB.fromchunks), ::Array{Dagger.Thunk,1}) at ./none:0

     [5] #_loadtable#188(::Nothing, ::Nothing, ::Bool, ::Array{Any,1}, ::Bool, ::Bool, ::Base.Iterators.Pairs{Symbol,Any,Tuple{Symbol,Symbol},NamedTuple{(:delim, :skiplines_begin),Tuple{Char,Int64}}}, ::Function, ::Type, ::String) at /Users/jekyllstein/.julia/packages/JuliaDB/jDAlJ/src/io.jl:140

     [6] #_loadtable at ./none:0 [inlined]

     [7] #loadtable#186 at /Users/jekyllstein/.julia/packages/JuliaDB/jDAlJ/src/io.jl:63 [inlined]

     [8] (::getfield(JuliaDB, Symbol("#kw##loadtable")))(::NamedTuple{(:delim, :skiplines_begin, :distributed),Tuple{Char,Int64,Bool}}, ::typeof(loadtable), ::String) at ./none:0

     [9] top-level scope at In[13]:1



```julia
#Created a test file to see what could be causing the failure by removing first and last line.
testName = "short_avail/short_test.txt"
flines = readlines(testName)
```




    13426-element Array{String,1}:
     "#SYM|CUR|NAME|CON|ISIN|REBATERATE|FEERATE|AVAILABLE|"                                
     "A|USD|AGILENT TECHNOLOGIES INC|1715006|XXXXXXXU1016|0.0623|1.0977|>10000000|"        
     "AA|USD|ALCOA CORP|251962528|XXXXXXX21065|0.3373|0.8227|>10000000|"                   
     "AAAP|USD|ADVANCED ACCELERATOR APP-ADR|212212690|XXXXXXXT1007|-6.4292|7.5892|350000|" 
     "AABA|USD|ALTABA INC|278946664|XXXXXXX61017|0.8167|0.3433|>10000000|"                 
     "AABB|USD|ASIA BROADBAND INC|75216559|XXXXXXXL1008|0.9100|0.2500|1600000|"            
     "AABVF|USD|ABERDEEN INTERNATIONAL INC.|60152167|CA0030691012|0.9100|0.2500|10000|"    
     "AAC|USD|AAC HOLDINGS INC|169041192|XXXXXXX71083|-0.1012|1.2612|300000|"              
     "AACS|USD|AMERICAN COMMERCE SOLUTIONS|30207299|XXXXXXX91008|0.9100|0.2500|1900000|"   
     "AACTF|USD|AURORA SOLAR TECHNOLOGIES IN|195675323|CA05207J1084|-3.1229|4.2829|4000|"  
     "AAEH|USD|ALL AMERICAN ENERGY HOLDING|143664841|XXXXXXXW2098|0.9100|0.2500|50000|"    
     "AAGC|USD|ALL AMERICAN GOLD CORP|88362966|XXXXXXXV1026|0.8600|0.3000|9100000|"        
     "AAGH|USD|AMERICA GREAT HEALTH|280898497|XXXXXXXT1016|0.9100|0.2500|550000|"          
     ⋮                                                                                     
     "ZTS|USD|ZOETIS INC|121665622|XXXXXXXV1035|0.9100|0.2500|>10000000|"                  
     "ZUMZ|USD|ZUMIEZ INC|34466024|XXXXXXX71015|-0.1635|1.3235|2400000|"                   
     "ZURVY|USD|ZURICH INSURANCE GROUP-ADR|105653547|XXXXXXX51049|-9.3903|10.5503|55000|"  
     "ZVTK|USD|ZEVOTEK INC|96765892|XXXXXXXB3042|0.9100|0.2500|6000|"                      
     "ZWBC|USD|GOLDKEY CORP|178731140|XXXXXXXN1046|NA|NA|60000|"                           
     "ZX|USD|CHINA ZENIX AUTO INTERNA-ADR|87836947|XXXXXXXE1047|-0.5574|1.7174|500000|"    
     "ZYME|USD|ZYMEWORKS INC|274189981|CA98985W1023|-14.3798|15.5398|2000|"                
     "ZYNE|USD|ZYNERBA PHARMACEUTICALS INC|202225021|XXXXXXXX1090|-15.4990|16.6590|200000|"
     "ZYTO|USD|ZYTO CORP|41119964|XXXXXXX21066|0.9100|0.2500|350000|"                      
     "ZYXI|USD|ZYNEX INC|52413740|XXXXXXXM1036|-11.6679|12.8279|200000|"                   
     "ZZLL|USD|ZZLL INFORMATION TECHNOLOGY|235604017|XXXXXXXP1030|0.9100|0.2500|150000|"   
     "ZZZOF|USD|ZINC ONE RESOURCES INC|274242368|CA98959W1041|-1.8239|2.9839|55000|"       




```julia
#Parsing this file works but we still have the annoying 9th missing column and the hashtag symbol for the first name
@btime loadtable("short_avail/short_test.txt", delim = '|', distributed = false)
tblTest = loadtable("short_avail/short_test.txt", delim = '|', distributed = false)
```

    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372
    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372


      22.347 ms (80477 allocations: 3.03 MiB)


    ┌ Warning: In short_avail/short_test.txt line 13429 has 0 fields but 9 fields are expected. Skipping row.
    └ @ TextParse ~/.julia/packages/TextParse/tFXtC/src/csv.jl:372





    Table with 13425 rows, 9 columns:
    Columns:
    [1m#  [22m[1mcolname     [22m[1mtype[22m
    ──────────────────────────────────────
    1  #SYM        String
    2  CUR         String
    3  NAME        String
    4  CON         Int64
    5  ISIN        String
    6  REBATERATE  Union{Missing, Float64}
    7  FEERATE     Union{Missing, Float64}
    8  AVAILABLE   String
    9              Missing




```julia
#in JuliaDB columns are accessed with the columns function and either the column number or the name as a symbol
#the columns are stored as native Arrays with type unions for missing values
[columns(tblTest, 7) columns(tblTest, :FEERATE)]

```




    13425×2 Array{Union{Missing, Float64},2}:
      1.0977     1.0977  
      0.8227     0.8227  
      7.5892     7.5892  
      0.3433     0.3433  
      0.25       0.25    
      0.25       0.25    
      1.2612     1.2612  
      0.25       0.25    
      4.2829     4.2829  
      0.25       0.25    
      0.3        0.3     
      0.25       0.25    
      5.9899     5.9899  
      ⋮                  
      0.25       0.25    
      1.3235     1.3235  
     10.5503    10.5503  
      0.25       0.25    
       missing    missing
      1.7174     1.7174  
     15.5398    15.5398  
     16.659     16.659   
      0.25       0.25    
     12.8279    12.8279  
      0.25       0.25    
      2.9839     2.9839  



# Parse and Load Group of Files

## File Modification for Parsing
Due to the peculiar formatting of these files both JuliaDB and CSV do not parse perfectly and JuliaDB fails completely without some additional help.  In order to compare the functionality of both packages on a large data set we can use other functions to perform an initial parsing step on the files and save them to disk in a modified fashion.  The function below achieves this with the following steps:

1. Filter out files that are non-empty and start with the prefix "IB_usa_short_avail"
2. Extract the date and time from line 1 ignoring files which have an improper date/time format
3. Form a new file name based on the stamp e.g. 2017-09-27T06.30.03.csv
4. Check in the desired output directory if the file already exists
    1. If file already exists skip it
    2. If file does not exist then attempt to parse it as follows
        1. remove the first and last line
        2. remove the starting '#' character from the 2nd header line
        3. remove '>' characters from the available shares column
        4. remove the last '|' charater from each data line
        5. Check line by line for the correct number of columns and save as array of substrings
        6. If all lines are parsed correctly then save with modified name
        
Because of the new naming scheme, this function will also reduce the number of files by saving only those that have a unique timestamp.


```julia
#modify and rename short files for easy juliaDB parsing, also eliminates duplicate files b/c of new naming convention
@everywhere function lineParse(l::AbstractString)
    n = 0
    newStr = Vector{Char}()
    if length(l) < 2
        return (0, "")
    end
    
    for c in l[1:end-1]
        if c == '|'
            n += 1
        end
        
        if (c != '#') && (c != '>')
            push!(newStr, c)
        end
    end
    (n, String(newStr))
end 

@everywhere function shortFileParse(f; outputdir = "short_avail_parsed", duplicate = false)
	#only parse files with this prefix
    if !occursin("IB_usa_short_avail", f)
		return
	end	
    
    #ignore empty files
	lines = readlines(f)
	if isempty(lines)
		return
	end
    
    #extract date and time from line 1, ignore if not formed properly
	row1 = split(lines[1], '|')
	if length(row1) != 3
		return
	end
	if (length(row1[2]) != 10) || (length(row1[3]) != 8)
		return
	end
	date = row1[2]
	time = row1[3]
    
    #form new file name from date time stamp
	name = string(replace(date, "." => "-"), "T", replace(time, ":" => "."), ".txt")
	
    #don't duplicate work if file already exists
    if !duplicate && isfile("$outputdir/$name")
		return
	end
    
    #save modified file removing > signs, first line, last line, and terminal | char
    #checks line by line if it has the correct number of cols as split by |
    
    outputLines = Vector{AbstractString}()
    for line in lines[2:end-1]
        (n, newLine) = lineParse(line)
        (n == 7) ? push!(outputLines, newLine) : return
    end
    
    #quotes = false keyword is necessary to handle line where quote appears inside the string
    #without this the resulting line in the written file is enclosed in quotes as additional chars
    #saving as CSV
    if length(outputLines) == (length(lines) - 2)
        writedlm("$outputdir/$name", outputLines, quotes=false)
    end
end
```


```julia
#parse exFile to see what result looks like and how long it takes (note we must create the desired output directory first)
@btime shortFileParse(exFile, outputdir = "parse_test", duplicate = true)
@btime shortFileParse(exFile, outputdir = "parse_test")
```

      14.998 ms (160109 allocations: 20.78 MiB)
      691.804 μs (26921 allocations: 1.74 MiB)



```julia
#Original file header, new file name, and new file line formats
println(readlines(exFile)[1])
println(glob("parse_test/*.txt")[1])
readlines(glob("parse_test/*.txt")[1])[1:3]
```

    #BOF|2017.09.27|06:30:03
    parse_test/2017-09-27T06.30.03.txt





    3-element Array{String,1}:
     "SYM|CUR|NAME|CON|ISIN|REBATERATE|FEERATE|AVAILABLE"                        
     "A|USD|AGILENT TECHNOLOGIES INC|1715006|XXXXXXXU1016|0.0623|1.0977|10000000"
     "AA|USD|ALCOA CORP|251962528|XXXXXXX21065|0.3373|0.8227|10000000"           




```julia
#Now when we try to parse this with JuliaDB it should be very easy
@btime loadtable(glob("parse_test/*.txt")[1], delim = '|', distributed = false)
loadtable(glob("parse_test/*.txt")[1], delim = '|', distributed = false)
```

      15.578 ms (80472 allocations: 2.91 MiB)





    Table with 13425 rows, 8 columns:
    Columns:
    [1m#  [22m[1mcolname     [22m[1mtype[22m
    ──────────────────────────────────────
    1  SYM         String
    2  CUR         String
    3  NAME        String
    4  CON         Int64
    5  ISIN        String
    6  REBATERATE  Union{Missing, Float64}
    7  FEERATE     Union{Missing, Float64}
    8  AVAILABLE   Int64




```julia
#parse files with serial broadcast
isdir("serial_parse") ? nothing : mkdir("serial_parse")
println("Parsing $(length(fnames)) files with maximum expected time of $(length(fnames)*15/1000) seconds")
@time shortFileParse.(fnames, outputdir = "serial_parse");
```

    Parsing 24875 files with maximum expected time of 373.125 seconds
    280.610388 seconds (1.68 G allocations: 185.774 GiB, 15.99% gc time)



```julia
#parse files with parallel execution instead, note that using @distributed is ideal when there
#are many parallel calls that each take a very short time.  Using @sync ensures our timer will
#wait until the task is completed.
isdir("parallel_parse") ? nothing : mkdir("parallel_parse")
println("Parsing $(length(fnames)) files with $(nworkers()) cores and idealized time of $(280/nworkers()) seconds")
@time @sync @distributed for f in fnames
    shortFileParse(f, outputdir = "parallel_parse")
end
```

    Parsing 24875 files with 8 cores and idealized time of 35.0 seconds
    144.342788 seconds (189.99 k allocations: 20.897 MiB, 0.00% gc time)





    Task (done) @0x000000010681ef50




```julia
#Verify that both methods yield the same number of files
println("Original number of files to parse = $(length(fnames))")
println("Number of new files parsed with parallel method = $(length(readdir("parallel_parse")))")
println("Number of new files parsed with parallel method = $(length(readdir("serial_parse")))")
println("Redundancy = $(length(fnames)/length(readdir("parallel_parse")))x")
```

    Original number of files to parse = 24875
    Number of new files parsed with parallel method = 8247
    Number of new files parsed with parallel method = 8247
    Redundancy = 3.016248332727052x


## Loading file glob into in memory table
The loadtable() function used earlier can take a list of files as input in which case it will create a merged table of all the subtables for each file.  We also have the added benefit of making use of the filenamecol keyword argument which can create a new column of a constant value based on the file name for the data source.

The filenamecol argument is pased with either a symbol or a pair.  The symbol is the name of the column associated with the filename and the data entries will be the filename with suffix removed by default.  It can be paired with an anonymous function that acts on the full name.  For example, the keyword argument could look like this:
```julia
filenamecol = :name => f -> count(isnumeric, f)/length(f)
```
This would create a column called name measuring the fraction of characters in the source filename are numeric.  In our case we will use this feature to label data with the timestamp of its source file with the DateTime() function.  Since our files are named according to the convention `2017-09-27T06.30.03.txt` we can parse them as DateTime types with ```DateTime({fname}[1:end-4], "yyyy-mm-ddTHH.MM.SS")```

Since we have multiple workers available, we must use ```distributed = false``` keyword to avoid loading a distributed table in parallel.  Our load time will occur serially and will not benefit from parallel processing. 


```julia
pflist = glob("parallel_parse/*.txt")
println("Loading in memory table of $(length(pflist)) files with an idealized time of $(15.456*length(pflist)/1000) seconds")
@time tblM = loadtable(pflist, distributed = false, delim = '|', filenamecol = :DATETIME => f -> DateTime(split(f, '/')[2][1:end-4], "yyyy-mm-ddTHH.MM.SS"))

```

    Loading in memory table of 8247 files with an idealized time of 127.465632 seconds
    317.181824 seconds (632.18 M allocations: 22.797 GiB, 3.99% gc time)





    Table with 105132209 rows, 9 columns:
    Columns:
    [1m#  [22m[1mcolname     [22m[1mtype[22m
    ──────────────────────────────────────
    1  DATETIME    DateTime
    2  SYM         String
    3  CUR         String
    4  NAME        String
    5  CON         Int64
    6  ISIN        String
    7  REBATERATE  Union{Missing, Float64}
    8  FEERATE     Union{Missing, Float64}
    9  AVAILABLE   Int64




```julia
#Once we have the table in memory we can save it to disk for fast loading
@time save(tblM, "short_avail.db")
println("Database file is $(filesize("short_avail.db")/1e9) gigabytes")
```

    122.636429 seconds (628.29 M allocations: 12.125 GiB, 9.92% gc time)
    Database file is 13.764525304 gigabytes



```julia
#Can see that in memory the table takes up 12.8 GB and 13.76 GB on disk
varinfo()
```




| name           |        size | summary                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
|:-------------- | -----------:|:--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Base           |             | Module                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          |
| Core           |             | Module                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          |
| Main           |             | Module                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          |
| dfEx           |   7.041 MiB | 13425×9 DataFrames.DataFrame                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| exFile         |    62 bytes | String                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          |
| f              |    62 bytes | String                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          |
| flines         |   1.169 MiB | 13426-element Array{String,1}                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   |
| fnames         |   1.661 MiB | 24875-element Array{String,1}                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   |
| l              |   976 bytes | 8-element Array{SubString{String},1}                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| line           |   1.170 MiB | 13428-element Array{String,1}                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   |
| lineParse      |     0 bytes | typeof(lineParse)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               |
| lines          |   1.170 MiB | 13428-element Array{String,1}                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   |
| outputLines    |  12.423 MiB | 13426-element Array{Array{SubString{String},1},1}                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               |
| pflist         | 434.939 KiB | 8247-element Array{String,1}                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| shortFileParse |     0 bytes | typeof(shortFileParse)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          |
| subTbl         |   4.567 MiB | IndexedTable{StructArrays.StructArray{NamedTuple{(:DATETIME, :SYM, :FEERATE, :AVAILABLE),Tuple{DateTime,String,Union{Missing, Float64},Int64}},1,NamedTuple{(:DATETIME, :SYM, :FEERATE, :AVAILABLE),Tuple{Array{DateTime,1},WeakRefStrings.StringArray{String,1},Array{Union{Missing, Float64},1},Array{Int64,1}}}}}                                                                                                                                                                                                                                                                                                                                            |
| subTbl2        |   4.567 MiB | IndexedTable{StructArrays.StructArray{NamedTuple{(:SYM, :DATETIME, :FEERATE, :AVAILABLE),Tuple{String,DateTime,Union{Missing, Float64},Int64}},1,NamedTuple{(:SYM, :DATETIME, :FEERATE, :AVAILABLE),Tuple{WeakRefStrings.StringArray{String,1},Array{DateTime,1},Array{Union{Missing, Float64},1},Array{Int64,1}}}}}                                                                                                                                                                                                                                                                                                                                            |
| tblM           |  12.802 GiB | IndexedTable{StructArrays.StructArray{NamedTuple{(:DATETIME, :SYM, :CUR, :NAME, :CON, :ISIN, :REBATERATE, :FEERATE, :AVAILABLE),Tuple{DateTime,String,String,String,Int64,String,Union{Missing, Float64},Union{Missing, Float64},Int64}},1,NamedTuple{(:DATETIME, :SYM, :CUR, :NAME, :CON, :ISIN, :REBATERATE, :FEERATE, :AVAILABLE),Tuple{Array{DateTime,1},WeakRefStrings.StringArray{String,1},WeakRefStrings.StringArray{String,1},WeakRefStrings.StringArray{String,1},Array{Int64,1},WeakRefStrings.StringArray{String,1},Array{Union{Missing, Float64},1},Array{Union{Missing, Float64},1},Array{Int64,1}}}}}                                            |
| tblTest        |   1.876 MiB | IndexedTable{StructArrays.StructArray{NamedTuple{(Symbol("#SYM"), :CUR, :NAME, :CON, :ISIN, :REBATERATE, :FEERATE, :AVAILABLE, Symbol("")),Tuple{String,String,String,Int64,String,Union{Missing, Float64},Union{Missing, Float64},String,Missing}},1,NamedTuple{(Symbol("#SYM"), :CUR, :NAME, :CON, :ISIN, :REBATERATE, :FEERATE, :AVAILABLE, Symbol("")),Tuple{WeakRefStrings.StringArray{String,1},WeakRefStrings.StringArray{String,1},WeakRefStrings.StringArray{String,1},Array{Int64,1},WeakRefStrings.StringArray{String,1},Array{Union{Missing, Float64},1},Array{Union{Missing, Float64},1},WeakRefStrings.StringArray{String,1},Array{Missing,1}}}}} |
| testName       |    34 bytes | String                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          |





```julia
#Once the file is saved can be loaded much faster 15 seconds vs 317 seconds
@btime tblM = load("short_avail.db")
tblM = load("short_avail.db")
```

      12.795 s (418022372 allocations: 8.49 GiB)





    Table with 105132209 rows, 9 columns:
    Columns:
    [1m#  [22m[1mcolname     [22m[1mtype[22m
    ──────────────────────────────────────
    1  DATETIME    DateTime
    2  SYM         String
    3  CUR         String
    4  NAME        String
    5  CON         Int64
    6  ISIN        String
    7  REBATERATE  Union{Missing, Float64}
    8  FEERATE     Union{Missing, Float64}
    9  AVAILABLE   Int64



## Loading file glob into distributed table
loadtable() functions the same way for distributed tables with a few keyword argument changes.  If we have multiple workers then omitting the `distributed` keyword will default to loading a distributed table in chunks with each one chunk per worker.  We need to have enough memory to load nworkers() x chunksize at once.  So if our database file is on par with the amount of memory it might be better to use more chunks than the number of workers.  The number of chunks is specified with the `chunks` keyword.  Below I've selected 32 chunks so at most we'd use less than 1/4 of system memory considering we still have the pervious database loaded in memory.

`output` is another keyword that can be used to save the distributed database to a directory.  This enables fast loading of the distributed database just like the single file.

Note that loading the file glob itself will now occur in parallel since the resulting table is split among workers and on disk.


```julia
#This will create a directory named according to "output" which contains one file for each 
#chunk and an index file.  It takes up the same 13.76GB as the single file.
@time tblD = loadtable(pflist, output = "short_avail_bin", chunks = 32, delim = '|', filenamecol = :DATETIME => f -> DateTime(split(f, '/')[2][1:end-4], "yyyy-mm-ddTHH.MM.SS"))

```

    127.905685 seconds (3.36 M allocations: 172.690 MiB, 1.71% gc time)





    Distributed Table with 105132209 rows in 32 chunks:
    Columns:
    [1m#  [22m[1mcolname     [22m[1mtype[22m
    ──────────────────────────────────────
    1  DATETIME    DateTime
    2  SYM         String
    3  CUR         String
    4  NAME        String
    5  CON         Int64
    6  ISIN        String
    7  REBATERATE  Union{Missing, Float64}
    8  FEERATE     Union{Missing, Float64}
    9  AVAILABLE   Int64




```julia
#We can load the distributed table from file similar to the in memory database, but in this
#case it occurs nearly instantly.
@btime tblD = load("short_avail_bin")
tblD = load("short_avail_bin")
```

      492.703 μs (2181 allocations: 71.69 KiB)





    Distributed Table with 105132209 rows in 32 chunks:
    Columns:
    [1m#  [22m[1mcolname     [22m[1mtype[22m
    ──────────────────────────────────────
    1  DATETIME    DateTime
    2  SYM         String
    3  CUR         String
    4  NAME        String
    5  CON         Int64
    6  ISIN        String
    7  REBATERATE  Union{Missing, Float64}
    8  FEERATE     Union{Missing, Float64}
    9  AVAILABLE   Int64



# Table Operations

## Selecting subtables
We can index table rows just like arrays and use the select() function to limit the number of columns.  Columns are selected with a tuple of column names or numbers.


```julia
subTblM = select(tblM[1:100000], (:DATETIME, :SYM, :FEERATE, :AVAILABLE))
```




    Table with 100000 rows, 4 columns:
    DATETIME             SYM      FEERATE  AVAILABLE
    ────────────────────────────────────────────────
    2017-09-27T06:30:03  "A"      1.0977   10000000
    2017-09-27T06:30:03  "AA"     0.8227   10000000
    2017-09-27T06:30:03  "AAAP"   7.5892   350000
    2017-09-27T06:30:03  "AABA"   0.3433   10000000
    2017-09-27T06:30:03  "AABB"   0.25     1600000
    2017-09-27T06:30:03  "AABVF"  0.25     10000
    2017-09-27T06:30:03  "AAC"    1.2612   300000
    2017-09-27T06:30:03  "AACS"   0.25     1900000
    2017-09-27T06:30:03  "AACTF"  4.2829   4000
    2017-09-27T06:30:03  "AAEH"   0.25     50000
    2017-09-27T06:30:03  "AAGC"   0.3      9100000
    2017-09-27T06:30:03  "AAGH"   0.25     550000
    ⋮
    2017-09-27T08:15:04  "UGL"    4.722    25000
    2017-09-27T08:15:04  "UGLD"   5.2459   150000
    2017-09-27T08:15:04  "UGNEQ"  0.3      350000
    2017-09-27T08:15:04  "UGP"    0.691    450000
    2017-09-27T08:15:04  "UHAL"   0.2869   500000
    2017-09-27T08:15:04  "UHID"   0.25     400
    2017-09-27T08:15:04  "UHLN"   0.3      9200000
    2017-09-27T08:15:04  "UHN"    8.4296   5000
    2017-09-27T08:15:04  "UHS"    0.2609   4100000
    2017-09-27T08:15:04  "UHT"    0.25     1700000
    2017-09-27T08:15:04  "UIFC"   0.25     300




```julia
#Distributed tables can be selected but not indexed unless we collect them first
#The number of chunks in the selection matches the original table
subTblD = select(tblD, (:DATETIME, :SYM, :FEERATE, :AVAILABLE))
```




    Distributed Table with 105132209 rows in 32 chunks:
    DATETIME             SYM      FEERATE  AVAILABLE
    ────────────────────────────────────────────────
    2017-09-27T06:30:03  "A"      1.0977   10000000
    2017-09-27T06:30:03  "AA"     0.8227   10000000
    2017-09-27T06:30:03  "AAAP"   7.5892   350000
    2017-09-27T06:30:03  "AABA"   0.3433   10000000
    2017-09-27T06:30:03  "AABB"   0.25     1600000
    2017-09-27T06:30:03  "AABVF"  0.25     10000
    2017-09-27T06:30:03  "AAC"    1.2612   300000
    2017-09-27T06:30:03  "AACS"   0.25     1900000
    2017-09-27T06:30:03  "AACTF"  4.2829   4000
    2017-09-27T06:30:03  "AAEH"   0.25     50000
    2017-09-27T06:30:03  "AAGC"   0.3      9100000
    2017-09-27T06:30:03  "AAGH"   0.25     550000
    2017-09-27T06:30:03  "AAGIY"  5.9899   90000
    2017-09-27T06:30:03  "AAIIQ"  0.25     100000
    2017-09-27T06:30:03  "AAIR"   0.25     3600000
    2017-09-27T06:30:03  "AAL"    0.25     10000000
    2017-09-27T06:30:03  "AAMC"   8.3474   30000
    2017-09-27T06:30:03  "AAME"   3.6481   300000
    2017-09-27T06:30:03  "AAMTF"  0.25     2000
    2017-09-27T06:30:03  "AAN"    0.25     8500000
    2017-09-27T06:30:03  "AAOI"   82.4581  40000
    2017-09-27T06:30:03  "AAON"   0.4372   2000000
    2017-09-27T06:30:03  "AAP"    0.2782   900000
    2017-09-27T06:30:03  "AAPC"   2.4758   7000
    ⋮



## Re-indexing table and filtering
Notice that the tables are indexed by DateTime with Sym in alphabetical order following.  If we want to filter the tables by symbols, we should re-index by that column so functions operate faster.  We can always re-index again by DateTime again should we filter or group by that variable instead.

reindex(t::IndexedTable, by) will reindex table t using the second argument which can be a symbol/number or tuple of sybols/numbers representing the new columns.  A third optional argument can pass a tuple of symbols/numbers for a column selection just like the select function.

filter() works normally with a function that iterates over each row.  An optional keyword argument can also be used to make a selection.


```julia
#Both tables are already sorted by DateTime followed by Symbol but we can ensure that by
#using the reindex function.  At the same time we can redefine the original table to only
#have two data columns to focus our analysis
@time tblM = reindex(tblM, (:DATETIME, :SYM), (:FEERATE, :AVAILABLE))
```

     42.652941 seconds (114.29 M allocations: 8.495 GiB, 4.02% gc time)





    Table with 105132209 rows, 4 columns:
    [1mDATETIME             [22m[1mSYM      [22mFEERATE  AVAILABLE
    ────────────────────────────────────────────────
    2017-09-27T06:30:03  "A"      1.0977   10000000
    2017-09-27T06:30:03  "AA"     0.8227   10000000
    2017-09-27T06:30:03  "AAAP"   7.5892   350000
    2017-09-27T06:30:03  "AABA"   0.3433   10000000
    2017-09-27T06:30:03  "AABB"   0.25     1600000
    2017-09-27T06:30:03  "AABVF"  0.25     10000
    2017-09-27T06:30:03  "AAC"    1.2612   300000
    2017-09-27T06:30:03  "AACS"   0.25     1900000
    2017-09-27T06:30:03  "AACTF"  4.2829   4000
    2017-09-27T06:30:03  "AAEH"   0.25     50000
    2017-09-27T06:30:03  "AAGC"   0.3      9100000
    2017-09-27T06:30:03  "AAGH"   0.25     550000
    ⋮
    2018-04-25T11:00:03  "ZUMZ"   0.4746   1500000
    2018-04-25T11:00:03  "ZUO"    5.8911   200000
    2018-04-25T11:00:03  "ZURVY"  13.7653  70000
    2018-04-25T11:00:03  "ZWBC"   missing  60000
    2018-04-25T11:00:03  "ZX"     2.7694   300000
    2018-04-25T11:00:03  "ZYME"   12.2239  15000
    2018-04-25T11:00:03  "ZYNE"   24.0515  50000
    2018-04-25T11:00:03  "ZYTO"   0.25     90000
    2018-04-25T11:00:03  "ZYXI"   2.3604   55000
    2018-04-25T11:00:03  "ZZLL"   0.25     2000
    2018-04-25T11:00:03  "ZZZOF"  2.172    100000




```julia
#We can do the same with the distributed table.
@time tblD = reindex(tblD, (:DATETIME, :SYM), (:FEERATE, :AVAILABLE))
```

     63.806646 seconds (8.23 M allocations: 418.168 MiB, 1.00% gc time)





    Distributed Table with 105132209 rows in 32 chunks:
    [1mDATETIME             [22m[1mSYM      [22mFEERATE  AVAILABLE
    ────────────────────────────────────────────────
    2017-09-27T06:30:03  "A"      1.0977   10000000
    2017-09-27T06:30:03  "AA"     0.8227   10000000
    2017-09-27T06:30:03  "AAAP"   7.5892   350000
    2017-09-27T06:30:03  "AABA"   0.3433   10000000
    2017-09-27T06:30:03  "AABB"   0.25     1600000
    2017-09-27T06:30:03  "AABVF"  0.25     10000
    2017-09-27T06:30:03  "AAC"    1.2612   300000
    2017-09-27T06:30:03  "AACS"   0.25     1900000
    2017-09-27T06:30:03  "AACTF"  4.2829   4000
    2017-09-27T06:30:03  "AAEH"   0.25     50000
    2017-09-27T06:30:03  "AAGC"   0.3      9100000
    2017-09-27T06:30:03  "AAGH"   0.25     550000
    2017-09-27T06:30:03  "AAGIY"  5.9899   90000
    2017-09-27T06:30:03  "AAIIQ"  0.25     100000
    2017-09-27T06:30:03  "AAIR"   0.25     3600000
    2017-09-27T06:30:03  "AAL"    0.25     10000000
    2017-09-27T06:30:03  "AAMC"   8.3474   30000
    2017-09-27T06:30:03  "AAME"   3.6481   300000
    2017-09-27T06:30:03  "AAMTF"  0.25     2000
    2017-09-27T06:30:03  "AAN"    0.25     8500000
    2017-09-27T06:30:03  "AAOI"   82.4581  40000
    2017-09-27T06:30:03  "AAON"   0.4372   2000000
    2017-09-27T06:30:03  "AAP"    0.2782   900000
    2017-09-27T06:30:03  "AAPC"   2.4758   7000
    ⋮




```julia
#Now it should be relatively fast to filter results by date.  Let's try to extract a subtable
#for just the first day "2017-09-27"
@time filter(r -> Date(r.DATETIME) == Date("2017-09-27"), tblM)
```

     23.222548 seconds (421.33 M allocations: 14.159 GiB, 14.20% gc time)





    Table with 720235 rows, 4 columns:
    [1mDATETIME             [22m[1mSYM      [22mFEERATE  AVAILABLE
    ────────────────────────────────────────────────
    2017-09-27T06:30:03  "A"      1.0977   10000000
    2017-09-27T06:30:03  "AA"     0.8227   10000000
    2017-09-27T06:30:03  "AAAP"   7.5892   350000
    2017-09-27T06:30:03  "AABA"   0.3433   10000000
    2017-09-27T06:30:03  "AABB"   0.25     1600000
    2017-09-27T06:30:03  "AABVF"  0.25     10000
    2017-09-27T06:30:03  "AAC"    1.2612   300000
    2017-09-27T06:30:03  "AACS"   0.25     1900000
    2017-09-27T06:30:03  "AACTF"  4.2829   4000
    2017-09-27T06:30:03  "AAEH"   0.25     50000
    2017-09-27T06:30:03  "AAGC"   0.3      9100000
    2017-09-27T06:30:03  "AAGH"   0.25     550000
    ⋮
    2017-09-27T19:45:09  "ZUMZ"   1.3235   2500000
    2017-09-27T19:45:09  "ZURVY"  10.5968  55000
    2017-09-27T19:45:09  "ZVTK"   0.25     6000
    2017-09-27T19:45:09  "ZWBC"   missing  60000
    2017-09-27T19:45:09  "ZX"     1.6931   500000
    2017-09-27T19:45:09  "ZYME"   15.5398  3000
    2017-09-27T19:45:09  "ZYNE"   17.0519  90000
    2017-09-27T19:45:09  "ZYTO"   0.25     350000
    2017-09-27T19:45:09  "ZYXI"   12.9131  200000
    2017-09-27T19:45:09  "ZZLL"   0.25     150000
    2017-09-27T19:45:09  "ZZZOF"  2.9709   55000




```julia
#And do the same filtering for the distributed table
@time filter(r -> Date(r.DATETIME) == Date("2017-09-27"), tblD)
```

      8.687150 seconds (290.73 k allocations: 15.022 MiB, 0.12% gc time)





    Distributed Table with 720235 rows in 1 chunks:
    [1mDATETIME             [22m[1mSYM      [22mFEERATE  AVAILABLE
    ────────────────────────────────────────────────
    2017-09-27T06:30:03  "A"      1.0977   10000000
    2017-09-27T06:30:03  "AA"     0.8227   10000000
    2017-09-27T06:30:03  "AAAP"   7.5892   350000
    2017-09-27T06:30:03  "AABA"   0.3433   10000000
    2017-09-27T06:30:03  "AABB"   0.25     1600000
    2017-09-27T06:30:03  "AABVF"  0.25     10000
    2017-09-27T06:30:03  "AAC"    1.2612   300000
    2017-09-27T06:30:03  "AACS"   0.25     1900000
    2017-09-27T06:30:03  "AACTF"  4.2829   4000
    2017-09-27T06:30:03  "AAEH"   0.25     50000
    2017-09-27T06:30:03  "AAGC"   0.3      9100000
    2017-09-27T06:30:03  "AAGH"   0.25     550000
    2017-09-27T06:30:03  "AAGIY"  5.9899   90000
    2017-09-27T06:30:03  "AAIIQ"  0.25     100000
    2017-09-27T06:30:03  "AAIR"   0.25     3600000
    2017-09-27T06:30:03  "AAL"    0.25     10000000
    2017-09-27T06:30:03  "AAMC"   8.3474   30000
    2017-09-27T06:30:03  "AAME"   3.6481   300000
    2017-09-27T06:30:03  "AAMTF"  0.25     2000
    2017-09-27T06:30:03  "AAN"    0.25     8500000
    2017-09-27T06:30:03  "AAOI"   82.4581  40000
    2017-09-27T06:30:03  "AAON"   0.4372   2000000
    2017-09-27T06:30:03  "AAP"    0.2782   900000
    2017-09-27T06:30:03  "AAPC"   2.4758   7000
    ⋮



# Summary Statistics
The method for calculating statistics like means varies depending on whether the table is in memory or distributed.  The OnlineStats package can be used to calculate these quantities out of core with parallel threads and update as new data is introduced.

## OnlineStats basics
OnlineStats are based on a new type which stores both the statistics in question and the number of observations.  For example, to calculate the mean, we can instantiate a stat as follows.


```julia
m = Mean()
```




    Mean: n=0 | value=0.0




```julia
dump(m)
```

    Mean{Float64,EqualWeight}
      μ: Float64 0.0
      weight: EqualWeight EqualWeight
      n: Int64 0



```julia
#each field can be accessed with dot syntax.  The value can also be accessed with value(m)
println(m.μ)
println(value(m))
println(m.n)
```

    0.0
    0.0
    0


To update this statistic m, we can use the `fit!()` function to which we pass the statistic and a vector of numbers.


```julia
#After using fit!, m is updated with the correct mean based on 10 numbers
v = rand(10)
println("The mean of v is $(mean(v))")
fit!(m, v)
```

    The mean of v is 0.5148007814644744





    Mean: n=10 | value=0.514801



`fit!()` can be called repeatedly on the same statistic to update it.  As shown below I can use the same vector and n will increase but the mean will stay unchanged as expected


```julia
fit!(m, v)
```




    Mean: n=20 | value=0.514801



## Comparing methods to calculate statistics on dbs
Let's take the example of calculating the average fee rate across the entire dataset.  There are a few methods depending on which type of database we are working with and there are performance considerations for each.  Also each method will need to handle missing data appropriately.

### In memory database methods


```julia
select(tblD, (:FEERATE, :AVAILABLE))
```




    Distributed Table with 105132209 rows in 32 chunks:
    FEERATE  AVAILABLE
    ──────────────────
    1.0977   10000000
    0.8227   10000000
    7.5892   350000
    0.3433   10000000
    0.25     1600000
    0.25     10000
    1.2612   300000
    0.25     1900000
    4.2829   4000
    0.25     50000
    0.3      9100000
    0.25     550000
    5.9899   90000
    0.25     100000
    0.25     3600000
    0.25     10000000
    8.3474   30000
    3.6481   300000
    0.25     2000
    0.25     8500000
    82.4581  40000
    0.4372   2000000
    0.2782   900000
    2.4758   7000
    ⋮




```julia
#Most basic method using mean().  First we extract the column, create an iterator that will
#ignore missing values, then take the mean of that at once.  Calculations are sequential.
@btime mean(skipmissing(columns(tblM, :FEERATE)))

```

      129.559 ms (3 allocations: 80 bytes)





    5.037132331674106




```julia
#OnlineStats method using fit! on the same iterator
@btime fit!(Mean(), skipmissing(columns(tblM, :FEERATE)))
```

      370.923 ms (3 allocations: 96 bytes)





    Mean: n=103879172 | value=5.03713




```julia
#OnlineStats method using reduce function with a selection and dropmissing()
@btime reduce(Mean(), dropmissing(tblM, :FEERATE), select = :FEERATE)

```

      33.931 s (1038742723 allocations: 26.93 GiB)





    Mean: n=103879172 | value=5.03713



### Distributed database methods


```julia
#Most basic method using mean() just as above.  The columns() command will return a distributed
#vector and skipmissing() can generate an iterator based on that.  However, the mean() function
#must accumulate it on one worker's memory before completing its calculation.  Moreover, we
#need to collect the vector immediately because it crashes if run after the skipmissing
#iterator
@btime mean(skipmissing(collect(columns(tblD, :FEERATE))))  

```

      22.761 s (314160063 allocations: 10.47 GiB)





    5.037132331674106



The act of collecting the vector from the distributed workers adds over 22 seconds to a process that was only 130ms.  If we try to use the fit! method we'll incur the same overhead on top of the even slower baseline calculation method on a normal vector.


```julia
#We can try to use the fit!() method above as well on the same iterator we had before.  We have
#the same problem though since fit!() requires a normal iterable collection for the second argument
@btime fit!(Mean(), skipmissing(collect(columns(tblD, :FEERATE))))
```

      21.024 s (314159810 allocations: 10.47 GiB)





    Mean: n=103879172 | value=5.03713




```julia
#The only remaining method is the one required for OnlineStats calculations with a distributed
#table and is the intended method to apply OnlineStats to a database.  It is also the slowest
#method for a table that isn't distributed.  Although the calculation occurs in parallel in 
#this case it is still about the same speed as the above methods likely due to the need to make
#an entirely new distributed table with the dropmissing command.  This is necessary because
#the Mean() function cannot handle missing values.
@btime reduce(Mean(), dropmissing(tblD, :FEERATE), select = :FEERATE)

```

      22.058 s (63410 allocations: 2.71 MiB)





    Mean: n=103879172 | value=5.03713




```julia
#Now the subtable is indexed by Sym first followed by DateTime
subTblM = reindex(subTblM, (:SYM, :DATETIME))
```




    Table with 100000 rows, 4 columns:
    [1mSYM      [22m[1mDATETIME             [22mFEERATE  AVAILABLE
    ────────────────────────────────────────────────
    "A"      2017-09-27T06:30:03  1.0977   10000000
    "A"      2017-09-27T06:45:03  1.0977   10000000
    "A"      2017-09-27T07:00:03  1.0977   10000000
    "A"      2017-09-27T07:15:03  1.0977   10000000
    "A"      2017-09-27T07:30:04  1.0977   10000000
    "A"      2017-09-27T07:45:03  1.0977   10000000
    "A"      2017-09-27T08:00:04  1.0977   10000000
    "A"      2017-09-27T08:15:04  1.0977   10000000
    "AA"     2017-09-27T06:30:03  0.8227   10000000
    "AA"     2017-09-27T06:45:03  0.8227   10000000
    "AA"     2017-09-27T07:00:03  0.8227   10000000
    "AA"     2017-09-27T07:15:03  0.8227   10000000
    ⋮
    "ZZLL"   2017-09-27T07:15:03  0.25     25000
    "ZZLL"   2017-09-27T07:30:04  0.25     25000
    "ZZLL"   2017-09-27T07:45:03  0.25     25000
    "ZZLL"   2017-09-27T08:00:04  0.25     150000
    "ZZZOF"  2017-09-27T06:30:03  2.9839   55000
    "ZZZOF"  2017-09-27T06:45:03  2.9839   55000
    "ZZZOF"  2017-09-27T07:00:03  2.9839   55000
    "ZZZOF"  2017-09-27T07:15:03  2.9839   50000
    "ZZZOF"  2017-09-27T07:30:04  2.9839   50000
    "ZZZOF"  2017-09-27T07:45:03  2.9839   55000
    "ZZZOF"  2017-09-27T08:00:04  2.9839   55000



## Groupreduce operations
With `groupreduce()` and `groupby()` we can get statistics for specific selections in one pass.  `groupby()` will calculate functions on entire columns while `groupreduce()` can take OnlineStats function arguments and work in parallel on distributed tables.

```julia
groupreduce(f, t, by = pkeynames(t); select)
```
f is a function, t is a table or distributed table, by controls how statistics are grouped and can be a tuple of symbols or just one.  Select controls which output variables the reduce operation is carried out upon.

`groupby()` takes the same arguments but includes a flatten keyword option.


```julia
@time symFees = groupby(mean ∘ skipmissing, tblM, :SYM, select = :FEERATE)
```

     12.263079 seconds (256.79 k allocations: 2.068 GiB, 4.07% gc time)





    Table with 16134 rows, 2 columns:
    [1mSYM         [22m#56
    ────────────────────
    "1608083D"  0.25
    "A"         0.329612
    "AA"        0.448209
    "AAAP"      6.74084
    "AABA"      0.286169
    "AABB"      0.25
    "AABVF"     15.0136
    "AAC"       1.17528
    "AACAY"     28.334
    "AACS"      0.25
    "AACTF"     4.13199
    "AADR"      15.0999
    ⋮
    "ZVTK"      0.25
    "ZWBC"      NaN
    "ZX"        2.4116
    "ZYME"      14.6038
    "ZYNE"      16.1114
    "ZYTO"      0.25
    "ZYXI"      10.4664
    "ZZLL"      0.25
    "ZZLL.OLD"  0.25
    "ZZLLD"     0.25
    "ZZZOF"     6.61522




```julia
@time symAvail = groupby(mean ∘ skipmissing, tblM, :SYM, select = :AVAILABLE)
```

     13.717304 seconds (833.47 k allocations: 2.096 GiB, 3.43% gc time)





    Table with 16134 rows, 2 columns:
    [1mSYM         [22m#56
    ─────────────────────
    "1608083D"  150000.0
    "A"         9.60141e6
    "AA"        6.37221e6
    "AAAP"      1.67359e5
    "AABA"      9.99818e6
    "AABB"      1.63223e6
    "AABVF"     16096.5
    "AAC"       5.29082e5
    "AACAY"     2045.27
    "AACS"      2.02142e6
    "AACTF"     4256.13
    "AADR"      4146.27
    ⋮
    "ZVTK"      1492.76
    "ZWBC"      60795.8
    "ZX"        3.85164e5
    "ZYME"      7013.3
    "ZYNE"      80346.3
    "ZYTO"      73913.6
    "ZYXI"      1.65099e5
    "ZZLL"      9793.7
    "ZZLL.OLD"  2.03857e5
    "ZZLLD"     541.727
    "ZZZOF"     66239.6




```julia
symFees = renamecol(symFees, 2, :AvgFee)
symAvail = renamecol(symAvail, 2, :AvgAvail)
```




    Table with 16134 rows, 2 columns:
    [1mSYM         [22mAvgAvail
    ─────────────────────
    "1608083D"  150000.0
    "A"         9.60141e6
    "AA"        6.37221e6
    "AAAP"      1.67359e5
    "AABA"      9.99818e6
    "AABB"      1.63223e6
    "AABVF"     16096.5
    "AAC"       5.29082e5
    "AACAY"     2045.27
    "AACS"      2.02142e6
    "AACTF"     4256.13
    "AADR"      4146.27
    ⋮
    "ZVTK"      1492.76
    "ZWBC"      60795.8
    "ZX"        3.85164e5
    "ZYME"      7013.3
    "ZYNE"      80346.3
    "ZYTO"      73913.6
    "ZYXI"      1.65099e5
    "ZZLL"      9793.7
    "ZZLL.OLD"  2.03857e5
    "ZZLLD"     541.727
    "ZZZOF"     66239.6




```julia
#Combine avg values into one table.  Need to have different column names ahead of time
symStats = filter(r -> !isnan(r.AvgFee), join(symFees, symAvail))
```




    Table with 15792 rows, 3 columns:
    [1mSYM         [22mAvgFee    AvgAvail
    ───────────────────────────────
    "1608083D"  0.25      150000.0
    "A"         0.329612  9.60141e6
    "AA"        0.448209  6.37221e6
    "AAAP"      6.74084   1.67359e5
    "AABA"      0.286169  9.99818e6
    "AABB"      0.25      1.63223e6
    "AABVF"     15.0136   16096.5
    "AAC"       1.17528   5.29082e5
    "AACAY"     28.334    2045.27
    "AACS"      0.25      2.02142e6
    "AACTF"     4.13199   4256.13
    "AADR"      15.0999   4146.27
    ⋮
    "ZURVY"     10.7328   56695.5
    "ZVTK"      0.25      1492.76
    "ZX"        2.4116    3.85164e5
    "ZYME"      14.6038   7013.3
    "ZYNE"      16.1114   80346.3
    "ZYTO"      0.25      73913.6
    "ZYXI"      10.4664   1.65099e5
    "ZZLL"      0.25      9793.7
    "ZZLL.OLD"  0.25      2.03857e5
    "ZZLLD"     0.25      541.727
    "ZZZOF"     6.61522   66239.6




```julia
@df symStats scatter(:AvgFee, :AvgAvail, legend = false, xaxis = ("Avg Fee Rate", (0, 100)), yaxis = ("Avg Available Shares", (0, 1e6)), markersize = 0.2)
```




![svg](output_72_0.svg)




```julia
cor(columns(symStats, :AvgFee), columns(symStats, :AvgAvail))
```




    -0.13148232315765312




```julia
#note groupreduce is a reduce operation vs groupby in which the function applies to the whole
#columns.  Here the function needs to be a reduce function so mean() wouldn't work.
@time symFees2 = groupreduce(Mean(), dropmissing(tblD, :FEERATE), :SYM, select = :FEERATE)
```

     54.049496 seconds (4.56 M allocations: 235.253 MiB, 0.99% gc time)





    Distributed Table with 15792 rows in 1 chunks:
    [1mSYM         [22mMean
    ─────────────────────────────────────────
    "1608083D"  Mean: n=23 | value=0.25
    "A"         Mean: n=8247 | value=0.329612
    "AA"        Mean: n=8247 | value=0.448209
    "AAAP"      Mean: n=5114 | value=6.74084
    "AABA"      Mean: n=8247 | value=0.286169
    "AABB"      Mean: n=2674 | value=0.25
    "AABVF"     Mean: n=8246 | value=15.0136
    "AAC"       Mean: n=8240 | value=1.17528
    "AACAY"     Mean: n=5536 | value=28.334
    "AACS"      Mean: n=8019 | value=0.25
    "AACTF"     Mean: n=7664 | value=4.13199
    "AADR"      Mean: n=5470 | value=15.0999
    "AAEH"      Mean: n=4725 | value=0.25
    "AAEH.OLD"  Mean: n=77 | value=0.25
    "AAGC"      Mean: n=7731 | value=0.3
    "AAGH"      Mean: n=6775 | value=0.643128
    "AAGIY"     Mean: n=8247 | value=5.48791
    "AAGRY"     Mean: n=59 | value=0.25
    "AAIIQ"     Mean: n=8094 | value=0.25
    "AAIR"      Mean: n=7924 | value=0.25
    "AAL"       Mean: n=8247 | value=0.254682
    "AAMC"      Mean: n=7878 | value=8.49992
    "AAME"      Mean: n=8237 | value=1.31718
    "AAMTF"     Mean: n=6439 | value=0.25
    ⋮




```julia
symFees2 = renamecol(symFees2, 2, :MeanFee)
```




    Distributed Table with 15792 rows in 1 chunks:
    [1mSYM         [22mMeanFee
    ─────────────────────────────────────────
    "1608083D"  Mean: n=23 | value=0.25
    "A"         Mean: n=8247 | value=0.329612
    "AA"        Mean: n=8247 | value=0.448209
    "AAAP"      Mean: n=5114 | value=6.74084
    "AABA"      Mean: n=8247 | value=0.286169
    "AABB"      Mean: n=2674 | value=0.25
    "AABVF"     Mean: n=8246 | value=15.0136
    "AAC"       Mean: n=8240 | value=1.17528
    "AACAY"     Mean: n=5536 | value=28.334
    "AACS"      Mean: n=8019 | value=0.25
    "AACTF"     Mean: n=7664 | value=4.13199
    "AADR"      Mean: n=5470 | value=15.0999
    "AAEH"      Mean: n=4725 | value=0.25
    "AAEH.OLD"  Mean: n=77 | value=0.25
    "AAGC"      Mean: n=7731 | value=0.3
    "AAGH"      Mean: n=6775 | value=0.643128
    "AAGIY"     Mean: n=8247 | value=5.48791
    "AAGRY"     Mean: n=59 | value=0.25
    "AAIIQ"     Mean: n=8094 | value=0.25
    "AAIR"      Mean: n=7924 | value=0.25
    "AAL"       Mean: n=8247 | value=0.254682
    "AAMC"      Mean: n=7878 | value=8.49992
    "AAME"      Mean: n=8237 | value=1.31718
    "AAMTF"     Mean: n=6439 | value=0.25
    ⋮




```julia
#try value(r) and r.n to show ways to access OnlineStats objects
[value(r) for r in collect(columns(symFees2, :MeanFee))]
```




    15792-element Array{Float64,1}:
      0.25               
      0.3296119922396023 
      0.44820858493997817
      6.7408358623386775 
      0.2861686795198254 
      0.25               
     15.013575260732477  
      1.1752785072815535 
     28.334018569364154  
      0.25               
      4.131986951983299  
     15.09991003656307   
      0.25               
      ⋮                  
     13.205927586206892  
     10.732801890013413  
      0.25               
      2.4116045956105254 
     14.603774475566874  
     16.111388624535316  
      0.25               
     10.466355256456893  
      0.25               
      0.25               
      0.25               
      6.615215060021827  




```julia
symFees2 = groupby(mean ∘ skipmissing, tblD, :SYM, select = :FEERATE)
```




    Distributed Table with 16134 rows in 8 chunks:
    [1mSYM         [22m#56
    ────────────────────
    "1608083D"  0.25
    "A"         0.329612
    "AA"        0.448209
    "AAAP"      6.74084
    "AABA"      0.286169
    "AABB"      0.25
    "AABVF"     15.0136
    "AAC"       1.17528
    "AACAY"     28.334
    "AACS"      0.25
    "AACTF"     4.13199
    "AADR"      15.0999
    "AAEH"      0.25
    "AAEH.OLD"  0.25
    "AAGC"      0.3
    "AAGH"      0.643128
    "AAGIY"     5.48791
    "AAGRY"     0.25
    "AAIIQ"     0.25
    "AAIR"      0.25
    "AAL"       0.254682
    "AAMC"      8.49992
    "AAME"      1.31718
    "AAMTF"     0.25
    ⋮




```julia
subTblD = reindex(tblD, (:SYM, :DATETIME), (:SYM, :DATETIME, :FEERATE, :AVAILABLE))
```




    Distributed Table with 105132209 rows in 32 chunks:
    [1mSYM  [22m[1mDATETIME             [22mFEERATE  AVAILABLE
    ────────────────────────────────────────────
    "A"  2017-09-27T06:30:03  1.0977   10000000
    "A"  2017-09-27T06:45:03  1.0977   10000000
    "A"  2017-09-27T07:00:03  1.0977   10000000
    "A"  2017-09-27T07:15:03  1.0977   10000000
    "A"  2017-09-27T07:30:04  1.0977   10000000
    "A"  2017-09-27T07:45:03  1.0977   10000000
    "A"  2017-09-27T08:00:04  1.0977   10000000
    "A"  2017-09-27T08:15:04  1.0977   10000000
    "A"  2017-09-27T08:30:03  1.0977   10000000
    "A"  2017-09-27T08:45:03  1.0977   10000000
    "A"  2017-09-27T09:00:03  1.0977   10000000
    "A"  2017-09-27T09:15:03  1.0977   10000000
    "A"  2017-09-27T09:30:03  1.0977   10000000
    "A"  2017-09-27T09:45:03  1.0977   10000000
    "A"  2017-09-27T10:00:06  1.0977   10000000
    "A"  2017-09-27T10:15:04  1.1077   10000000
    "A"  2017-09-27T10:30:04  1.1077   10000000
    "A"  2017-09-27T10:45:04  1.1077   10000000
    "A"  2017-09-27T11:00:04  1.1077   10000000
    "A"  2017-09-27T11:15:03  1.1077   10000000
    "A"  2017-09-27T11:30:03  1.1077   10000000
    "A"  2017-09-27T11:45:05  1.1077   10000000
    "A"  2017-09-27T12:00:03  1.1077   10000000
    "A"  2017-09-27T12:15:03  1.0533   10000000
    ⋮


