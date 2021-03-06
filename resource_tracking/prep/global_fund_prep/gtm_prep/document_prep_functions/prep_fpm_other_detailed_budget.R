# ----------------------------------------------
# Irena Chen
#
# 11/7/2017
# Template for prepping the GUA-610-G04-T grant 
# Inputs:
# inFile - name of the file to be prepped
# Outputs:
# budget_dataset - prepped data.table object
# ----------------------------------------------


# ----------------------------------------------
##Function to prepare the budgets: 
# ----------------------------------------------
prep_other_detailed_budget = function(dir, inFile, sheet_name, start_date, qtr_num, disease, period, lang, grant){
  
  # dir = file_dir
  # inFile = "GUA-610-G04-T_SB_Year_6_7_ENG.XLS"
  # sheet_name = "Detailed budget"
  # start_date = "2012-08-01"
  # qtr_num = 8
  # disease = "tb"
  # period = 90
  # lang = "esp" 
  # grant = "GTM-610-G04-T"

  
  qtr_names <- c("Area de prestacion de servicios","Actividad", "Receptor Principal", seq(21, 29, by=1))
  
  create_qtr_names = function(qtr_names){
    for(i in 1:length(qtr_names)){
      if(i <4) {
        i=i+1
      } else { 
        qtr_names[i] <- paste0("Q", qtr_names[i])
        i=i+1
      }
    }
    return(qtr_names)
  }
  qtr_names <- create_qtr_names(qtr_names)
  
  if(!is.na(sheet_name)){
    gf_data <- data.table(read_excel(paste0(dir, inFile), sheet=as.character(sheet_name)))
  } else {
    gf_data <- data.table(read_excel(paste0(dir, inFile)))
  }
  
  setnames(gf_data, fix_diacritics(names(gf_data)))
  ##only get the columns that we want
  gf_data <- gf_data[,names(gf_data)%in%qtr_names, with=FALSE]
  
  ##only keep data that has a value in the "category" column 
  gf_data <- na.omit(gf_data, cols=1, invert=FALSE)
  
  colnames(gf_data)[1] <- "module"
  colnames(gf_data)[2] <- "sda_activity"
  colnames(gf_data)[3] <- "recipient" 

  ## invert the dataset so that budget expenses and quarters are grouped by category
  ##library(reshape)
  setDT(gf_data)
  gf_data1<- melt(gf_data,id=c("module", "sda_activity", "recipient"), 
                  variable.name = "qtr", value.name="budget")
  
  
  dates <- rep(start_date, qtr_num) # 
  for (i in 1:length(dates)){
    if (i==1){
      dates[i] <- start_date
    } else {
      dates[i] <- dates[i-1]%m+% months(3)
    }
  }
  
  if(length(dates) != length(unique(gf_data1$qtr))){
    stop('quarters were dropped!')
  }
  ##turn the list of dates into a dictionary (but only for quarters!) : 
  dates <- setNames(dates,unique(gf_data1$qtr))
  
  
  ## now match quarters with start dates 
  kDT = data.table(qtr = names(dates), value = TRUE, start_date = unname(dates))
  budget_dataset <-gf_data1[kDT, on=.(qtr), start_date := i.start_date ]
  budget_dataset$qtr <- NULL
  budget_dataset$period <- period
  #budget_dataset$grant_name <- grant
  budget_dataset$disease <- disease
  budget_dataset$intervention <- budget_dataset$sda_activity
  budget_dataset$expenditure <- 0 
  budget_dataset$lang <- lang
  budget_dataset$cost_category <- "all"
  budget_dataset$grant_number <- grant
  return(budget_dataset)  
}

