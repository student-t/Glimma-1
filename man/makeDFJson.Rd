% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/utilities.R
\name{makeDFJson}
\alias{makeDFJson}
\title{JSON converter for data frames}
\usage{
makeDFJson(df)
}
\arguments{
\item{df}{the data.frame to be converted into JSON}
}
\value{
a stringified JSON, the data.frame is encoded as a vector of objects, 
with each column being one object with keys corresponding to column names.
}
\description{
Function to create a JSON from a data.frame
}

