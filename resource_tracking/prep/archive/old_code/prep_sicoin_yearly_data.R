# ----------------------------------------------
# Irena Chen
#
# 11/2/2017
# Template for prepping SICOIN cost category data 
# Inputs:
# inFile - name of the file to be prepped
# year - which year the dataset corresponds to
#
# Outputs:
# budget_dataset - prepped data.table object

# ----------------------------------------------
# Set up R

library(data.table)
library(reshape2)
library(stringr)
library(readxl)
library(rlang)
library(zoo)

# start function
prep_detailed_sicoin = function(inFile, start_date, disease, period, source) {
  # --------------------
  # Test the inputs
  if (class(inFile)!='character') stop('Error: inFile argument must be a string!')
  if (class(year)=='character') stop('Error: year argument must be a number!')
  # ----------------------------------------------
  # Files and directories
  
  # Load/prep data
  gf_data <- data.table(read_excel(inFile))
  ## remove empty columns 
  gf_data<- Filter(function(x)!all(is.na(x)), gf_data)
  # ----------------------------------------------
  if(source=="ghe"&year(start_date)==2014&disease=="hiv"&period==365){
    gf_data <- gf_data[c(grep("INGRESOS CORRIENTES", gf_data$X__10):grep("DONACIONES", gf_data$X__10)),]
    # remove rows where cost_categories are missing values
    gf_data <- na.omit(gf_data, cols="X__10")
    budget_dataset <- gf_data[, c("X__3","X__10","X__19", "X__26"), with=FALSE]
    budget_dataset <- budget_dataset[-1,]
    budget_dataset <- budget_dataset[-nrow(budget_dataset),]
    names(budget_dataset) <- c("loc_id", "loc_name", "budget", "disbursement")
    toMatch <- c("government", "recursos", "resources", "multire", "donacions")
    budget_dataset <- budget_dataset[ !grepl(paste(toMatch, collapse="|"), tolower(budget_dataset$loc_name)),]
    budget_dataset$sda_orig <- "All"

  } else if(source=="ghe"){
      if(length(grep("DONACIONES", gf_data$X__12))==0){
        gf_data <- gf_data[c(grep("INGRESOS CORRIENTES", gf_data$X__12):.N),]
      } else if(length(grep("INGRESOS CORRIENTES", gf_data$X__12) !=0)){
        gf_data <- gf_data[c(grep("INGRESOS CORRIENTES", gf_data$X__12):grep("DONACIONES", gf_data$X__12)),]
      } else {
        gf_data <- gf_data[c(grep("RECURSOS DEL TESORO", gf_data$X__12):grep("DONACIONES", gf_data$X__12)),]
      }
    
      ## grab loc_id: 
      gf_data$X__4 <- na.locf(gf_data$X__4, na.rm=FALSE)
      gf_data$X__14 <- na.locf(gf_data$X__14, na.rm=FALSE)
      # remove rows where cost_categories are missing values
      gf_data <- na.omit(gf_data, cols="X__15")
      # ----------------------------------------------
      ## Code to aggregate into a dataset 
      ## now get region + budgeted expenses 
      budget_dataset <- gf_data[, c("X__4","X__14","X__15", "X__22", "X__29"), with=FALSE]
      names(budget_dataset) <- c("loc_id", "loc_name", "sda_orig", "budget", "disbursement")
     
      ##enforce variable classes 
      if (!is.numeric(budget_dataset$budget)) budget_dataset[,budget:=as.numeric(budget)]
      if (!is.numeric(budget_dataset$disbursement)) budget_dataset[,disbursement:=as.numeric(disbursement)]
      # government resources are split by income (taxes) and "treasury" 
      #we don't care, so sum by just the municipality and SDA: 
      
      budget_dataset <- budget_dataset[, list(budget=sum(na.omit(budget)), disbursement=sum(na.omit(disbursement))),
                                     by=c("loc_id", "loc_name", "sda_orig")]
  } else if (source=="gf") {
    colnames(gf_data)[3] <- "loc_id"
    gf_data$X__11 <- na.locf(gf_data$X__11, na.rm=FALSE)
    gf_data$loc_id <- na.locf(gf_data$loc_id, na.rm=FALSE)
    gf_data <- na.omit(gf_data, cols="X__10")
    budget_dataset <- gf_data[, c("loc_id", "X__10", "X__11", "X__19", "X__26"), with=FALSE]
    # remove rows where cost_categories are missing values
    names(budget_dataset) <- c("loc_id", "sda_orig", "loc_name", "budget", "disbursement")
    budget_dataset <- na.omit(budget_dataset, cols="loc_name")
    loc_names <- unique(budget_dataset$loc_name)
    budget_dataset <- budget_dataset[!budget_dataset$sda_orig%in%loc_names]
  }
  toMatch <- c("government", "recursos", "resources", "multire", "total")
  budget_dataset <- budget_dataset[ !grepl(paste(toMatch, collapse="|"), tolower(budget_dataset$loc_name)),]
# ----------------------------------------------

  ## Create other variables 
  budget_dataset$source <- source
  budget_dataset$start_date <- start_date
  budget_dataset$period <- period
  budget_dataset$expenditure <- 0 ## change this once we figure out where exp data is
  budget_dataset$disease <- disease
  # ----------------------------------------------
  
  # Enforce variable classes again 
  if (!is.numeric(budget_dataset$budget)) budget_dataset[,budget:=as.numeric(budget)]
  if (!is.numeric(budget_dataset$disbursement)) budget_dataset[,disbursement:=as.numeric(disbursement)]
  if (!is.numeric(budget_dataset$expenditure)) budget_dataset[,expenditure:=as.numeric(expenditure)]

  # ----------------------------------------------
  
  # return prepped data
  return(budget_dataset)
  
}

