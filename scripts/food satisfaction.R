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

#some people were excluded from the study because they didn't 
# fulfill all the criteria, how many?
#11 + 4 + 2 + 1 = 18
sum(food_satisfaction_amended$Lunch_exclusion)
sum(food_satisfaction_amended$Ate_between_exclusion)
sum(food_satisfaction_amended$Rehearsal_exclu)
sum(food_satisfaction_amended$Use_of_phone_exclu)

#remove these values and columns because this data shouldn't be analysed
food_satisfaction_amended <- food_satisfaction_amended %>% 
  filter(Lunch_exclusion == 0 &
           Ate_between_exclusion == 0 &
           Rehearsal_exclu == 0 &
           Use_of_phone_exclu == 0) %>% 
  select(Sens_exclu_aims:Satisfaction_satiety)

#look at correlation between satisfaction metrics
#reverse coded -1 as expected
#looks like satisfaction / taste / like combined to get general satisfaction
#filling used for satisfaction satiety
View(cor(food_satisfaction_amended %>% 
      select(Lunch_memory_satisfying:Lunch_memory_liked,
             General_satisfaction:Satisfaction_satiety)))

#look at easier case first
View(food_satisfaction_amended %>% select(Lunch_memory_satisfied_filling,
                                          Lunch_memory_dissatisfied_filling_R,
                                          Satisfaction_satiety))

#average of satisfied filling / dissatisfied filling reverse coded is
# satisfaction satiety, yes
View(food_satisfaction_amended %>% 
       select(Lunch_memory_satisfied_filling,
              Lunch_memory_dissatisfied_filling_R,
              Satisfaction_satiety) %>%
  filter(Satisfaction_satiety !=
           (Lunch_memory_satisfied_filling 
            + Lunch_memory_dissatisfied_filling_R) / 2))

#guess that general satisfaction is average of 
# memory satisfaction, dissatisfaction reverse, taste satisfaction, 
# dissatisfaction reverse and liked
#check, yeah
View(food_satisfaction_amended %>% 
       select(Lunch_memory_satisfying,
              Lunch_memory_dissastisfying_R,
              Lunch_memory_satisfied_taste,
              Lunch_memory_dissatisfied_taste_R,
              Lunch_memory_liked,
              General_satisfaction) %>%
       filter(General_satisfaction !=
                (Lunch_memory_satisfying +
                   Lunch_memory_dissastisfying_R +
                   Lunch_memory_satisfied_taste +
                   Lunch_memory_dissatisfied_taste_R +
                   Lunch_memory_liked) / 5))


#remove columns which are calculated from each other
food_satisfaction_amended <- food_satisfaction_amended %>%
  select(!starts_with("Lunch_memory"))

#look at correlation of TFEQ variables, not enough to exclude any
View(cor(food_satisfaction_amended %>% select(Cognitive_restraint,
                                              Uncontrolled_eating,
                                              Emotional_eating)))

#order of actions:
# answer pre-lunch hunger question
# eat lunch
# complete satisfying / dissatisfying description
# answer post-lunch hunger question
# BREAK
# answer pre-taste test hunger question
# complete taste test
# answer post-taste test hunger question
# answer lunchtime memory satisfaction questions
# answer TFEQ, demographic, study intention questions, measure BMI


#visualization ideas:
#univariate first to understand values:
# age groupings to see if good range (bar by category)
# BMI to see if any outliers (box plot)
# distribution of pre/post lunch and taste test hunger (freqpoly)
# snack kcal to see if any outliers (box plot)
# distribution of general satisfaction and satiety 
#multivariate:
# plot pre/post lunch hunger by condition (scatter)
#    also include whether people described the opposite 
# same as above but for pre/post taste test hunger (scatter)
# plot biscuit consumption by condition (boxplots)
#    also include whether people described the opposite 
# plot general satisfaction by condition (boxplots)
#    also include whether people described the opposite
# same as above but for satisfaction satiety
# repeat visuals for people who guessed study intention, diff results??
# look into demographics:
  # plot age against difference in pre/post lunch hunger (scatter)
  # plot age against biscuit consumption (scatter)
  # plot age against general satisfaction / satiety (scatter)
  # same as above for BMI
# look into TFEQ measures:
  # same plots as age