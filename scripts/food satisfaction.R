#load the relevant packages
library(tidyverse)
#import SPSS data
library(haven)
#skewness
library(moments)
#trees
library(tree)
library(rpart)
library(rpart.plot)
#conditional inference tree
library(partykit)
#factor analysis of mixed data
library(factoextra)
library(FactoMineR)

#import data
food_satisfaction_raw <- read_sav("data/RememberedMealSatisfaction.sav")

#data exploration and cleansing ---------------------------

#look at data structure
#146 rows and 46 columns
#some variables have a label with extra info(lbl)
#data is either a double or a character
#some character columns seem to be split, data limit in SPSS?
#some data has been reverse coded 
#need to understand what cognitive restraint/uncontrolled/emotional eating mean
glimpse(food_satisfaction_raw)

#looks like ID column is NA only, investigate nulls
#ID is null, drop
#minor nulls in age/gender/BMI/Height/Weight that don't really impact study
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

# Visualizations -------------------------

# add age category 
food_satisfaction_amended$AgeGroup <-
  case_when(food_satisfaction_amended$Age <= 24 ~ "18-24",
            food_satisfaction_amended$Age <= 34 ~ "25-34",
            food_satisfaction_amended$Age <= 44 ~ "35-44",
            .default = "45-60")
str(food_satisfaction_amended$AgeGroup)
food_satisfaction_amended$AgeGroup <- factor(food_satisfaction_amended$AgeGroup)

# plot bar chart of age categories
# as expected more younger participants
ggplot(food_satisfaction_amended, aes(x = AgeGroup)) +
  geom_bar() +
  theme_bw() +
  labs(y = "Count of participants")

#boxplot of BMI
boxplot(food_satisfaction_amended$BMI, 
        horizontal = TRUE,
        xlab = "BMI")

#distribution of pre/post lunch hunger
ggplot(food_satisfaction_amended) +
  geom_density(aes(Hunger_pre_lunch), colour = "red", linewidth = 1) +
  geom_density(aes(Hunger_post_lunch), colour = "blue", linewidth = 1) +
  theme_bw() +
  labs(x = "Pre / post lunch hunger (red = pre)")

#distribution of pre/post taste test hunger
#hunger is generally lower to start but doesn't decrease as much 
ggplot(food_satisfaction_amended) +
  geom_density(aes(Hunger_pre_taste_test), colour = "red", linewidth = 1) +
  geom_density(aes(Hunger_post_taste_test), colour = "blue", linewidth = 1) +
  theme_bw() +
  labs(x = "Pre / post taste test hunger (red = pre)")

#boxplot of biscuit kcal consumed
#no outliers, amount was controlled, slight positive skew
boxplot(food_satisfaction_amended$Snack_kcal, 
        horizontal = TRUE,
        xlab = "Biscuits consumed (kcal)")
mean(food_satisfaction_amended$Snack_kcal)
median(food_satisfaction_amended$Snack_kcal)

#distribution of general satisfaction / satiety (memory)
#generally participants remembered being full but range of satisfaction
ggplot(food_satisfaction_amended) +
  geom_density(aes(General_satisfaction), colour = "red", linewidth = 1) +
  geom_density(aes(Satisfaction_satiety), colour = "blue", linewidth = 1) +
  theme_bw() +
  labs(x = "Memory of lunch (red = general satisfaction, blue = satiety)")

#change variables to factors
food_satisfaction_amended$Condition <- 
  factor(food_satisfaction_amended$Condition)

food_satisfaction_amended$Rehearsal_exclu_exploratory <- 
  factor(food_satisfaction_amended$Rehearsal_exclu_exploratory)

food_satisfaction_amended$Sens_exclu_aims <- 
  factor(food_satisfaction_amended$Sens_exclu_aims)

food_satisfaction_amended$Gender <- 
  factor(food_satisfaction_amended$Gender)

#plot pre/post lunch hunger against category
#as we'd expect negative descriptions(2) are more hungry after lunch
ggplot(food_satisfaction_amended, aes(x = Hunger_pre_lunch, 
                                      y = Hunger_post_lunch,
                                      color = Condition))+
  geom_point() +
  geom_smooth(method = "lm", se = F) +
  facet_wrap(~Condition) +
  theme_bw() +
  labs(x = "Pre lunch hunger", y = "Post lunch hunger", colour = "Condition")


#plot difference between pre/post lunch as boxplots
#lots of overlap, negative looks negative skewed, neutral positive skew
#positive looks symmetrical
boxplot((Hunger_post_lunch - Hunger_pre_lunch) ~ Condition, 
        data = food_satisfaction_amended, xlab = "Condition", 
        ylab = "Difference in pre/post lunch hunger") 

#plot distributions
ggplot(food_satisfaction_amended, 
       aes(x = (Hunger_post_lunch - Hunger_pre_lunch),
                                      after_stat(density),
                                      colour = Condition)) +
  geom_density() +
  theme_bw() +
  labs(x = "Difference in pre/post lunch hunger", 
       colour = "Condition")

#skewness, negative is roughly symmetric, neutral is moderate positive skew
negative <- food_satisfaction_amended %>% filter(Condition == 2)
neutral <- food_satisfaction_amended %>% filter(Condition == 0)
skewness(negative$Hunger_post_lunch - negative$Hunger_pre_lunch)
skewness(neutral$Hunger_post_lunch - neutral$Hunger_pre_lunch)

#are the results clearer if we look at people who described the opposite?
#no, they're more confused, we'd expect negative condition who describe
# positive to be less hungry after lunch, but they're more hungry
ggplot(food_satisfaction_amended, aes(x = Hunger_pre_lunch, 
                                      y = Hunger_post_lunch,
                                      color = Rehearsal_exclu_exploratory))+
  geom_point() +
  geom_smooth(method = "lm", se = F) +
  facet_wrap(~Condition) +
  theme_bw() +
  labs(x = "Pre lunch hunger", y = "Post lunch hunger", 
       colour = "Explained opposite")

#same plot for but pre/post taste test hunger
#no difference at all between groups
ggplot(food_satisfaction_amended, aes(x = Hunger_pre_taste_test, 
                                      y = Hunger_post_taste_test,
                                      color = Condition))+
  geom_point() +
  geom_smooth(method = "lm", se = F) +
  facet_wrap(~Condition) +
  theme_bw() +
  labs(x = "Pre taste test hunger", y = "Post taste test hunger", 
       colour = "Condition")

ggplot(food_satisfaction_amended, 
       aes(x = (Hunger_post_taste_test - Hunger_pre_taste_test),
           after_stat(density),
           colour = Condition)) +
  geom_density() +
  theme_bw() +
  labs(x = "Difference in pre/post taste test hunger", 
       colour = "Condition")


#plot biscuit consumption by condition
#lots of overlap, all slightly positive skew
boxplot(Snack_kcal ~ Condition, 
        data = food_satisfaction_amended, xlab = "Condition", 
        ylab = "Biscuits consumed (kcal)") 

#boxplot losing too much information, try jitter, no difference
ggplot(food_satisfaction_amended, aes(x = Condition,
                                      y = Snack_kcal
                                      )) +
  geom_jitter() +
  theme_bw()

#plot biscuit consumption distributions
ggplot(food_satisfaction_amended, 
       aes(x = Snack_kcal,
           after_stat(density),
           colour = Condition)) +
  geom_density() +
  theme_bw() +
  labs(x = "Biscuits consumed (kcal)", 
       colour = "Condition")

#any difference removing people who described opposite? No
boxplot(Snack_kcal ~ Condition, 
        data = food_satisfaction_amended %>% 
          filter(Rehearsal_exclu_exploratory == 0), 
        xlab = "Condition", 
        ylab = "Biscuits consumed (kcal)") 

ggplot(food_satisfaction_amended %>% 
         filter(Rehearsal_exclu_exploratory == 0), 
       aes(x = Snack_kcal,
           after_stat(density),
           colour = Condition)) +
  geom_density() +
  theme_bw() +
  labs(x = "Biscuits consumed (kcal)", 
       colour = "Condition")

#plot remembered satisfaction by category
boxplot(General_satisfaction ~ Condition, 
        data = food_satisfaction_amended, 
        xlab = "Condition", 
        ylab = "Remembered lunch satisfaction") 

ggplot(food_satisfaction_amended, 
       aes(x = General_satisfaction,
           after_stat(density),
           colour = Condition)) +
  geom_density() +
  theme_bw() +
  labs(x = "General satisfaction", 
       colour = "Condition")

#remembered satisfaction by category and accurate reflection
boxplot(General_satisfaction ~ Condition, 
        data = food_satisfaction_amended %>% 
          filter(Rehearsal_exclu_exploratory == 0), 
        xlab = "Condition", 
        ylab = "Remembered lunch satisfaction") 

ggplot(food_satisfaction_amended %>% 
         filter(Rehearsal_exclu_exploratory == 0), 
       aes(x = General_satisfaction,
           after_stat(density),
           colour = Condition)) +
  geom_density() +
  theme_bw() +
  labs(x = "General satisfaction", 
       colour = "Condition")

#remembered satiety by category 
#(not much difference when excluding those that described opposite)
boxplot(Satisfaction_satiety ~ Condition, 
        data = food_satisfaction_amended, 
        xlab = "Condition", 
        ylab = "Remembered lunch satiety") 

ggplot(food_satisfaction_amended, 
       aes(x = Satisfaction_satiety,
           after_stat(density),
           colour = Condition)) +
  geom_density() +
  theme_bw() +
  labs(x = "Remembered lunch satiety", 
       colour = "Condition")

#how much do these results change if we exclude people who guessed 
# the study intentions?
#There are only three people who met this criteria so the results are
#unlikely to substantially change

#at the moment seems only significant difference would be general satisfaction
# of people who described what they were supposed to and 
# even that may not be statistically significant
# (also: whether people liked/didn't like the food was more important
# than being told to reflect one way or the other)

#do demographics / food personalities play any part in results?

#age and pre/post lunch hunger
ggplot(food_satisfaction_amended, aes(x = Hunger_pre_lunch, 
                                      y = Hunger_post_lunch,
                                      color = AgeGroup,
                                      shape = Condition))+
  geom_point() +
  geom_smooth(method = "lm", se = F) +
  facet_grid(rows = vars(Condition),
             cols = vars(AgeGroup)) +
  theme_bw() +
  labs(x = "Pre lunch hunger", y = "Post lunch hunger", colour = "Age Group")


boxplot(Hunger_pre_lunch - Hunger_post_lunch ~ AgeGroup, 
        data = food_satisfaction_amended, 
        xlab = "Age Group", 
        ylab = "Difference between pre and post lunch hunger") 

#age and biscuit consumption
boxplot(Snack_kcal ~ AgeGroup, 
        data = food_satisfaction_amended, 
        xlab = "Age Group", 
        ylab = "Biscuits consumed (kcal)") 

#age and general satisfaction
boxplot(General_satisfaction ~ AgeGroup, 
        data = food_satisfaction_amended, 
        xlab = "Age Group", 
        ylab = "Remembered lunch satisfaction") 

#bmi and biscuit consumption
#NHS say above 30 BMI is obese, these people are mainly in positive group
ggplot(food_satisfaction_amended, aes(x = BMI, 
                                      y = Snack_kcal,
                                      color = Condition))+
  geom_point() +
  geom_smooth(method = "lm", se = F) +
  facet_wrap(~Condition) +
  theme_bw() +
  labs(x = "BMI", y = "Biscuit Consumption (kcal)")

#what would happen if we looked at BMI below 30
#positive group has greater decrease in hunger but still
# doesn't look statistically significant
boxplot((Hunger_post_lunch - Hunger_pre_lunch) ~ Condition, 
        data = food_satisfaction_amended %>% filter(BMI < 30), 
        xlab = "Condition", 
        ylab = "Difference in pre/post lunch hunger") 

#no change
boxplot(Snack_kcal ~ Condition, 
        data = food_satisfaction_amended %>% filter(BMI < 30), 
        xlab = "Condition", 
        ylab = "Biscuits consumed (kcal)") 

#little change
boxplot(General_satisfaction ~ Condition, 
        data = food_satisfaction_amended %>% filter(BMI < 30), 
        xlab = "Condition", 
        ylab = "Remembered lunch satisfacion") 


#look at TFEQ measures, cognitive restraint
# most useful in looking at biscuit consumption
# slight downward trend in all groups
ggplot(food_satisfaction_amended, aes(x = Cognitive_restraint, 
                                      y = Snack_kcal,
                                      color = Condition))+
  geom_point() +
  geom_smooth(method = "lm", se = F) +
  facet_wrap(~Condition) +
  theme_bw() +
  labs(x = "TFEQ cognitive restraint", y = "Biscuits consumed (kcal)")

#TFEQ uncontrolled eating, higher upward trend in negative group
ggplot(food_satisfaction_amended, aes(x = Uncontrolled_eating, 
                                      y = Snack_kcal,
                                      color = Condition))+
  geom_point() +
  geom_smooth(method = "lm", se = F) +
  facet_wrap(~Condition) +
  theme_bw() +
  labs(x = "TFEQ uncontrolled eating", y = "Biscuits consumed (kcal)")

#TFEQ uncontrolled eating
ggplot(food_satisfaction_amended, aes(x = Emotional_eating, 
                                      y = Snack_kcal,
                                      color = Condition))+
  geom_point() +
  geom_smooth(method = "lm", se = F) +
  facet_wrap(~Condition) +
  theme_bw() +
  labs(x = "TFEQ emotional eating", y = "Biscuits consumed (kcal)")

#most promising measures for statistical analysis:
#  remembered lunch satisfaction by condition and accurate description

#difference in pre/post lunch hunger by category wasn't significant but 
# interesting to see ANOVA results

#Statistics --------------------------------
#ANOVA assumptions
#Samples follow normal distribution (or n > 30)
#Samples have equal variance
#Samples are independent

#Test pre/post lunch hunger by category
#We've already seen neutral moderately skewed, positive/negative symmetric
#Test variance, same
bartlett.test(Hunger_pre_lunch - Hunger_post_lunch ~ Condition, 
              data = food_satisfaction_amended)

#ANOVA, no difference for all participants, as expected
aov_lunch_hunger_diff <- aov(Hunger_pre_lunch - Hunger_post_lunch ~ Condition, 
                             data = food_satisfaction_amended)
summary(aov_lunch_hunger_diff)

#test general satisfaction
#distributions are skewed in this case, try Kruskal Wallis 

#same variances
bartlett.test(General_satisfaction ~ Condition, 
              data = food_satisfaction_amended)

#not quite significant
kruskal.test(General_satisfaction ~ Condition, 
             data = food_satisfaction_amended)

#only participants who described what they were asked
#variances are the same
bartlett.test(General_satisfaction ~ Condition, 
              data = food_satisfaction_amended %>% 
                filter(Rehearsal_exclu_exploratory == 0))

#yes, significant now
kruskal.test(General_satisfaction ~ Condition, 
             data = food_satisfaction_amended %>% 
                               filter(Rehearsal_exclu_exploratory == 0))

#check two remaining outcomes for completeness although visuals
# show there wouldn't be a relationship

#pre/post taste test hunger by condition
#plots look approx normal
#Test variance, same
bartlett.test(Hunger_pre_taste_test - Hunger_post_taste_test ~ Condition, 
              data = food_satisfaction_amended)

#ANOVA, no difference for all participants, as expected
aov_taste_test_hunger_diff <- aov(
  Hunger_pre_taste_test - Hunger_post_taste_test ~ Condition, 
                             data = food_satisfaction_amended)
summary(aov_taste_test_hunger_diff)


#biscuit consumption by condition
#plots look approx normal

#Test variance, same
bartlett.test(Snack_kcal ~ Condition, 
              data = food_satisfaction_amended)

#ANOVA, no difference for all participants, as expected
aov_snack_kcal_diff <- aov(
  Snack_kcal ~ Condition, 
  data = food_satisfaction_amended)
summary(aov_snack_kcal_diff)

#Ideas: look at tree / factor analysis of mixed data to see which measures  
#are most important in determining biscuit consumption / changes in hunger/
#general satisfaction
#this would include looking at raw hunger levels rather than differences


#reduce dataset to only include important/numerical variables
food_satisfaction_amended_reduced <- food_satisfaction_amended %>%
  select(Sens_exclu_aims:Condition, Gender:BMI, 
         Hunger_pre_lunch:Hunger_post_taste_test, Pasta_ate_percentage:AgeGroup)

#build tree to see what's important for biscuit consumption
rpart_biscuit_consumption = rpart(Snack_kcal ~ ., 
                                  data = food_satisfaction_amended_reduced, 
                                  method = "anova")

#interestingly condition isn't here at all
prp(rpart_biscuit_consumption)

#plot error curve
plotcp(rpart_biscuit_consumption)

#complexity relates to improvement in R2 for ANOVA
View(rpart_biscuit_consumption$frame)

#this matrix gives information on optimal prunings
#rel error is 1 - R2
#xerr shows which steps reduce/increase error
#xstd is cross validated error
View(rpart_biscuit_consumption$cptable)

#find CP for min error
#alternative is to find smallest tree within 1 S.E of tree with smallest error
min_cp = rpart_biscuit_consumption$cptable[
  which.min(rpart_biscuit_consumption$cptable[,"xerror"]),"CP"]

#prune tree
rpart_biscuit_consumption_prune = prune(rpart_biscuit_consumption, 
                                        cp = min_cp)

#only two variables remain: hunger pre taste test and cognitive restraint
prp(rpart_biscuit_consumption_prune)

#this shows primary splits and surrogate splits
#primary splits are the alternatives not chosen at each node
#surrogate splits show which variables are closely related 
# e.g. hunger pre taste test is related to remembered lunchtime satiety
summary(rpart_biscuit_consumption_prune)

#alternative way of plotting which shows how much data in each leaf
rpart.plot(rpart_biscuit_consumption_prune)

#try subset to only include those who described what they were supposed to
rpart_biscuit_consumption_correct_desc = rpart(Snack_kcal ~ ., 
                                  data = food_satisfaction_amended_reduced, 
                                  method = "anova",
                                  subset = (Rehearsal_exclu_exploratory==0)
                                  )

#condition not here
prp(rpart_biscuit_consumption_correct_desc)

#plot error curve
plotcp(rpart_biscuit_consumption_correct_desc)

#complexity relates to improvement in R2 for ANOVA
View(rpart_biscuit_consumption_correct_desc$frame)

#optimal prunings
View(rpart_biscuit_consumption_correct_desc$cptable)

#find CP for min error
min_cp_2 = rpart_biscuit_consumption_correct_desc$cptable[
  which.min(rpart_biscuit_consumption_correct_desc$cptable[,"xerror"]),"CP"]

#prune tree
rpart_biscuit_consumption_correct_desc_prune = 
  prune(rpart_biscuit_consumption_correct_desc, cp = min_cp_2)

#only hunger pre taste test remains
prp(rpart_biscuit_consumption_correct_desc_prune)

#this shows primary splits and surrogate splits
summary(rpart_biscuit_consumption_correct_desc_prune)

#alternative way of plotting which shows how much data in each leaf
rpart.plot(rpart_biscuit_consumption_correct_desc_prune)

#try subset by condition 1/2 
rpart_biscuit_consumption_condition = rpart(Snack_kcal ~ ., 
                                               data = food_satisfaction_amended_reduced, 
                                               method = "anova",
                                               subset = (Condition %in% c(1,2))
)

#still hunger pre taste test but also general satisfaction
prp(rpart_biscuit_consumption_condition)

#general satisfaction is now slightly more important than cognitive restraint
summary(rpart_biscuit_consumption_condition)

#plot error curve
plotcp(rpart_biscuit_consumption_condition)

#complexity relates to improvement in R2 for ANOVA
View(rpart_biscuit_consumption_condition$frame)

#optimal prunings
View(rpart_biscuit_consumption_condition$cptable)

#find CP for min error
min_cp_3 = rpart_biscuit_consumption_condition$cptable[
  which.min(rpart_biscuit_consumption_condition$cptable[,"xerror"]),"CP"]

#prune tree
rpart_biscuit_consumption_condition_prune = 
  prune(rpart_biscuit_consumption_condition, cp = min_cp_3)

#nothing remains!
prp(rpart_biscuit_consumption_condition_prune)

#try conditional inference tree method (suggestion that CART chooses variables
#  with more splits - could be why we didn't get condition?)

ci_tree <- ctree(Snack_kcal ~ ., data = food_satisfaction_amended_reduced)

#only one variable is chosen, hunger pre taste test
print(ci_tree)

plot(ci_tree)

#the following control attributes didn't change the results significantly
# but sometimes included gender
# teststat, splitstat
# testtype "teststatistic" included more variables but only
#   hunger post lunch could be connected to the condition group


#this is what we'd expect given only stat. significant result we saw
ci_tree_general <- ctree(General_satisfaction ~ ., 
                         data = food_satisfaction_amended_reduced,
                         subset=(Rehearsal_exclu_exploratory == 0))

plot(ci_tree_general)

#no significant variables, no matter the subset
ci_tree_lunch_hunger <- ctree(Hunger_post_lunch - Hunger_pre_lunch ~ ., 
                         data = food_satisfaction_amended_reduced %>%
                           select(!Hunger_post_lunch, !Hunger_pre_lunch),
                         subset=(Condition %in% c(1,2))
                         )
plot(ci_tree_lunch_hunger)

#try factor analysis of mixed data
#impute 2 missing pasta % with mean
food_satisfaction_amended_reduced$Pasta_ate_percentage_no_nulls <- 
  replace(food_satisfaction_amended_reduced$Pasta_ate_percentage,
          is.na(food_satisfaction_amended_reduced$Pasta_ate_percentage),
          mean(food_satisfaction_amended_reduced$Pasta_ate_percentage, na.rm = TRUE))

food_satisfaction_amended_reduced <- food_satisfaction_amended_reduced %>%
  select(!Pasta_ate_percentage)
  
factor_analysis <- FAMD(food_satisfaction_amended_reduced %>% 
                          select(!Snack_kcal), graph = TRUE)

#the top 5 principal components only account for 49% of variance
#the top 2 account for 25% of variance
print(factor_analysis$eig)

#plot how much variance each component accounts for
fviz_screeplot(factor_analysis)

#get variable contributions
factor_analysis_var <- get_famd_var(factor_analysis)

#condition contributes most to 3rd dimension
factor_analysis_var$contrib

#show which variables contribute most to first 2 dimensions
fviz_famd_var(factor_analysis, repel = TRUE)


#understand how sample size was chosen
pwr.anova.test(k = 3, f = 0.3, sig.level = 0.05, power = 0.8)
