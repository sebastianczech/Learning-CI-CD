print("Install R packages")

install.packages("jsonlite", repos = "https://cran.r-project.org")
install.packages("curl", repos = "https://cran.r-project.org")
install.packages("jsonlite", repos = "https://cran.r-project.org")
install.packages("openssl", repos = "https://cran.r-project.org")
install.packages("https://github.com/r-lib/httr/archive/refs/tags/v1.4.2.tar.gz", repos = NULL, type = 'file')
install.packages("oysteR", repos = "https://cran.r-project.org")
                   
installed.packages()
