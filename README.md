# Food Satisfaction Study
This project uses R to explore an open dataset retrieved from the UK Data Service. 
The data relates to a study investigating the link between [remembered meal satisfaction and later snack intake](https://reshare.ukdataservice.ac.uk/853370/).

## Study Summary
A study was conducted to test the effect of meal satisfaction on subsequent food intake. Participants were randomly allocated to one of three groups (with gender stratification so both genders were represented in each group):
- Satisfying rehearsal: Where participants are asked to reflect on the positive aspects of a meal
- Dissatisfying rehearsal: Where participants are asked to reflect on the negative aspects of a meal
- Neutral rehearsal: Where participants are asked to reflect on a question unrelated to the meal

In a lunchtime session all participants ate the same pasta and in a second session they ate biscuits. They were told the sessions were investigating the link between
personality and evaluation of savoury/sweet foods. The outcome variable was the total biscuit intake in kcals. Before and after each session the participants were asked to rate their hunger. At the end of the second session questions were asked about how the lunch had been remembered in terms of satisfaction and satiety. Other questions relating to eating habits and demographics were also asked. 

Full details of the study can be found in the Data folder. 

## Steps Taken
- Step 1: Explore and cleanse data. This included:
  -   Counting and dropping nulls
  -   Merging character columns
  -   Removing participants who didn't fulfill all the study requirements
  -   Understanding the correlation/link between the lunch memory questions and removing values calculated from each other
- Step 2: Visualize single variables to understand distributions. Findings:
  - 18-24 year olds account for more than half of the participants
  - Three BMI's are outliers
  - The biscuits consumed distribution is slightly positively skewed
  - Participants were generally hungrier before lunch than the taste test and were less hungry after lunch than the taste test (not surprising given amount of food and time of day)
  - Participants generally remembered being full after lunch but there was a wider range of satisfaction levels (again, not surprising, you can be full without particularly enjoying a meal)

## Findings

