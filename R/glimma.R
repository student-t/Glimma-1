#' Glimma plot manager
#' 
#' Core glimma plot manager. Generates environment for glimma plots.
#' 
#' @param ... the jschart or jslink objects for processing.
#' @param layout the numeric vector representing the number of rows and columns in plot window.
#' @param path the path in which the folder will be created.
#' @param folder the name of the fold to save html file to.
#' @param html the name of the html file to save plots to.
#' @param overwrite the option to overwrite existing folder if it already exists.
#' @param launch TRUE to launch plot after call.
#' 
#' @return Generates interactive plots based on filling layout row by row from left to right.
#' 
#' @examples
#' data(iris)
#' \donttest{
#' plot1 <- glScatter(iris, xval="Sepal.Length", yval="Sepal.Width", colval="Species")
#' glimma(plot1, c(1,1))
#' }
#' 
#' @importFrom utils browseURL

glimma <- function(..., layout=c(1,1), path=getwd(), folder="glimma-plots", 
                html="index", overwrite=TRUE, launch=TRUE) {
    nplots <- 0

    ##
    # Input checking
    for (i in list(...)) {
        if (class(i) == "jschart") {
            nplots <- nplots + 1
        }
    }
    
    if (!is.numeric(layout) || !(length(layout) == 2)) {
        stop("layout must be numeric vector of length 2")
    }

    if (layout[2] < 1 || layout[2] > 6) {
        stop("number of columns must be between 1 and 6")
    }

    if (nplots > layout[1] * layout[2]) {
        stop("More plots than available layout cells")
    }

    if (overwrite == FALSE) {
        if (file.exists(file.path(path, folder))) {
            stop(paste(file.path(path, folder), "already exists"))
        }
    }

    if (!file.exists(path)) {
        stop(paste(path, "does not exist"))
    }
    #
    ##

    # Normalise input
    folder <- ifelse(char(folder, nchar(folder)) == "/" || 
                    char(folder, nchar(folder)) == "\\", 
                    substring(folder, 1, nchar(folder) - 1),
                    folder) # If folder ends with /
    layout <- round(layout)

    # Convert variable arguments into list
    args <- list(...)

    # Create folder
    if (!dir.exists(file.path(path, folder))) {
        dir.create(file.path(path, folder))
    }

    # Create file
    index.path <- system.file(package="Glimma", "index.html")
    js.path <- system.file(package="Glimma", "js")
    css.path <- system.file(package="Glimma", "css")
    
    file.copy(index.path, 
            file.path(path, folder, paste0(html, ".html")), 
            overwrite=overwrite)

    file.copy(js.path, 
            file.path(path, folder), 
            recursive=TRUE, 
            overwrite=overwrite)

    file.copy(css.path,
            file.path(path, folder),
            recursive=TRUE,
            overwrite=overwrite)

    data.path <- file.path(path, folder, "js", "data.js")
    cat("", file=data.path, sep="")
    write.data <- writeMaker(data.path)

    # Initialise data variables
    actions <- data.frame(from=0, 
                        to=0, 
                        src="none", 
                        dest="none", 
                        flag="none", 
                        info="none") # Dummy row

    inputs <- data.frame(target=0,
                        action="none", 
                        idval="none", 
                        flag="none") # Dummy row
    data.list <- list()

    # Process arguments
    for (i in 1:length(args)) {
        if (class(args[[i]]) == "jslink" || class(args[[i]]) == "jschart" || class(args[[i]]) == "jsinput") {
            if (args[[i]]$type == "link") {
                actions <- rbind(actions, args[[i]]$link)
            } else if (args[[i]]$type == "autocomplete") {
                inputs <- rbind(inputs, args[[i]]$input)
            } else {
                processPlot(write.data, args[[i]]$type, args[[i]], i)
            }
        }
    }

    # Write linkage
    if (nrow(actions) > 1) {
        actions.js <- makeDFJson(actions[-1, ])
        write.data(paste0("glimma.storage.linkage = ", actions.js, ";\n"))
    } else {
        write.data("glimma.storage.linkage = [];\n")
    }

    # Write input fields
    if (nrow(inputs) > 1) {
        inputs.js <- makeDFJson(inputs[-1, ])
        write.data(paste0("glimma.storage.input = ", inputs.js, ";\n"))
    } else {
        write.data("glimma.storage.input = [];\n")
    }

    # Generate layout
    layout <- paste0("glimma.layout.setupGrid(d3.select(\".container\"), \"md\", ", "[", layout[1], ",", layout[2], "]);\n")
    write.data(layout)

    # Launch page if required
    if (launch) {
        browseURL(file.path(path, folder, paste0(html, ".html")))
    }
}


# Helper function for parsing the information in a plot object
processPlot <- function(write.data, type, chart, index) {
    # Write json data
    write.data(paste0("glimma.storage.chartData.push(", chart$json, ");\n"))

    # Write plot information
    chart$json <- NULL
    chartInfo <- makeChartJson(chart) 
    write.data(paste0("glimma.storage.chartInfo.push(", chartInfo, ");\n"))

    # Write plot call
    if (type == "scatter") {
        constructScatterPlot(chart, index, write.data)
    } else if (type == "bar") {
        constructBarPlot(chart, index, write.data)  
    }
}
