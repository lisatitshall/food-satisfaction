#load the relevant packages
library(tidyverse)
#import SPSS data
library(haven)

#import data
food_satisfaction_raw <- read_sav("data/RememberedMealSatisfaction.sav")

#data exploration and cleansing ---------------------------

#look at data structure
#146 rows and 46 columns
#some variables have a label with extra info(lbl)
#data is either a double or a character
#some character columns seem to be split, data limit in SPSS?
#some data has been reverse coded 
#need to understand what cognitive restraint, uncontrolled/emotional eating mean
glimpse(food_satisfaction_raw)

#looks like ID column is NA only, investigate nulls
#ID is null, drop
#minor nulls in age/gender/BMI/Height/Weight that don't impact study
#minor nulls in more important columns
View(food_satisfaction_raw %>% 
       summarize(across(everything(), ~sum(is.na(.x))))) 

#drop null id column
food_satisfaction_amended <- food_satisfaction_raw %>% select(!ID)

#most of the nulls are from one row, remove this row
food_satisfaction_amended <- food_satisfaction_amended[2:146,]

#only 2 null values in % ate pasta remain
View(food_satisfaction_amended %>% 
       summarize(across(everything(), ~sum(is.na(.x))))) 

#can we combine character columns without losing information?
View(food_satisfaction_amended)

#try concatenating the satisfying columns (these are the longest)
test <- food_satisfaction_amended %>% 
  unite("Satisfying_rehearsal_all",
        Satisfying_rehearsal:
          Satisfying_rehearsal_cont_2, 
        sep = "", 
        remove = FALSE) %>%
  select(Satisfying_rehearsal:
           Satisfying_rehearsal_cont_2,
         `Satisfying_rehearsal_all`)

View(test)

#visual inspection looks OK, filtering doesn't return any rows, all OK
View(test %>% 
       filter(nchar(Satisfying_rehearsal_all) !=
                nchar(Satisfying_rehearsal) +
                nchar(Satisfying_rehearsal_cont) +
                nchar(Satisfying_rehearsal_cont_1) +
                nchar(Satisfying_rehearsal_cont_2)
                ))            

#combine character columns but this time remove originals
#do for all columns as longest was OK
food_satisfaction_amended <- food_satisfaction_amended %>% 
  unite("Satisfying_rehearsal_all",
        Satisfying_rehearsal:
          Satisfying_rehearsal_cont_2, 
        sep = "") %>% 
  unite("Dissatisfying_rehearsal_all",
        Dissastisfying_rehearsal:Dissastisfying_rehearsal_cont_1, 
        sep = "") %>%
  unite("Awareness_probe_1_all",
        Awareness_probe_1:
          Awareness_probe_1_cont,
        sep = "") %>%
  unite("Awareness_probe_2_all",
        Awareness_probe_2:
          Awareness_probe_2_cont,
        sep = "")
