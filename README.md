# Julia Notebook Requirements:
- julia 1.1 or later, download binaries from https://julialang.org/downloads/ or build from source https://github.com/JuliaLang/julia/tree/v1.1.0.  Below it is assumed that this version of julia can be run in the terminal with the command {julia}
- jupyter installed through miniconda3.  Use the appropriate 64 bit installer for Python 3.7 from https://docs.conda.io/en/latest/miniconda.html.  Make sure conda is added to system path and once it is install jupyter with `conda install jupyter`.  jupyter should be in the system path as well which can be confirmed with `which jupyter` in the terminal.
- to set up proper environment for notebook, clone the repository to your computer and run `{julia} setup.jl` within that directory.  Doing so will install all the package dependencies and download a zip file short_avail.zip
- Unzip the file locally for all functions to work.

# Notebook run instructions:
- Clone the repository to a local directory and run the setup.jl script as explained above
- Navigate to directory in terminal and execute `jupyter notebook`.  A web browser should open displaying the JuliaDB_Intro directory.  Click on the notebook `File Blob Out of Core DB Tutorial.ipynb`

# Other notes:
The notebook with outputs generated on a 2015 MacBook Pro with a 2.8 GHz Intel Core i7 CPU has been saved as an html and markdown version with the same name as the original notebook.  Outputs can been observed most clearly in the html version while code examples and document structure can be seen most clearly in the markdown version.