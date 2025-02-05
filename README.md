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
- Step 3: Plot multivariate graphs to look for relationships
- Step 4: Fit tree models to understand what factors contribute to biscuit consumption

## Findings
- Participants in the dissatisfying rehearsal group tend to be hungrier after lunch (see scatter chart below).

![image](https://github.com/user-attachments/assets/30dbcf9f-e7ca-4c5a-a0b0-83f0bed1f98a)

However, the relationship isn't clear cut and there's a lot of overlap between groups (see boxplots below).

![image](https://github.com/user-attachments/assets/11fd9d91-cea8-44ff-a0e8-7e5d7acfb707)

When we also consider participants who described the opposite of what they were asked the trend becomes less clear cut and in fact shows the opposite of what we'd expect. 

- There is little difference between hunger pre/post taste test by group (see scatter chart below).

![image](https://github.com/user-attachments/assets/1345524f-22dc-4dfb-a604-73912b00e97f)

- Biscuit consumption wasn't significantly higher in the dissatisfying rehearsal group (see boxplot below). Because boxplots can lose too much information the jitter plot shows the individual points. Excluding people who described the opposite of intended didn't change the visualizations much. 

![image](https://github.com/user-attachments/assets/312f535e-ceb8-403d-8773-4a95c133c659)

![image](https://github.com/user-attachments/assets/f75cc1ed-306e-46a7-8ade-98c791d994b3)

- Remembered lunchtime satisfaction was lower in the dissatisfying rehearsal group but not significantly so (see boxplots below).

![image](https://github.com/user-attachments/assets/e0f8c167-a5fa-43f5-8cc9-d695651723e1)

When we only considered participants who described what they were supposed to the trend became clearer (see box plots and density plots below).

![image](https://github.com/user-attachments/assets/6edefbda-6d4f-4c92-8ff6-98726f96033f)

![image](https://github.com/user-attachments/assets/06d66676-71b8-41bb-a535-82eed250fec1)

As expected, there wasn't much difference in remembered lunch satiety between groups. 

- There were only three participants who guessed the actual intention of the study. Therefore, excluding these people is unlikely to change the results.

- Age does seem to have an impact on pre/post hunger levels (for example, in the charts below we can see that 18-24 year olds are hungrier after lunch even in the neutral group). However, because there were a lot more younger participants in the study it may be difficult to test this statistically.
  
![image](https://github.com/user-attachments/assets/504eb9ff-b99d-4487-b4b3-b302f19d8c71)

- BMI doesn't seem to be an important measure. Although participants with a higher BMI were more likely to be in the satisfying rehearsal group removing BMI's over 30 didn't significantly change any of the relationships.

- There does seem to be a slight relationship between the TFEQ measures and participant behaviour. For example, participants that had a higher cognitive restraint score ate less biscuits in all groups (see chart below). However, this is only likely to be weak correlation. 

![TFEQ cognitive restraint vs biscuit consumption](https://github.com/user-attachments/assets/5f352347-9718-42f1-882d-5a1c52df1ffa)

- ANOVA or Kruskal Wallis tests (depending on the assumptions) were performed to test whether the outcomes differed by condition. The only significant result was the Kruskal Wallis test on remembered lunch satisfaction only for participants who described what they were asked to (see screenshot below). This confirms what the visualizations showed us intuitively. 

![kruskal wallis general satisfaction by condition](https://github.com/user-attachments/assets/00b79af7-7f83-4bea-92b7-bb093c1b8338)

- A recursive partitioning tree was fitted to predict biscuit consumption. After pruning only two variables remained: hunger pre taste test and cognitive restraint (see tree below). However, these variables only explained around 28% of the variation in biscuit consumption. Interestingly, condition wasn't chosen as a factor that influences biscuit consumption even in the larger tree. Also, the surrogate splits identified correlated variables that could be used instead of the chosen variables. For example, remembered lunchtime satiety was linked to the chosen variable "hunger pre taste test". 

![image](https://github.com/user-attachments/assets/50fb436c-e23e-4712-ada8-a00e11c7cfbf)

- A recursive partitioning tree was then fitted to predict biscuit consumption only in the satisfying and dissatisfying rehearsal groups. In this case hunger pre taste test was still the most important variable. The second variable was remembered lunchtime satisfaction instead of cognitive restraint. This variable was significantly different by category (only for participants who described what they were asked to). However, even in this case the improvement of remembered lunchtime satisfaction over cognitive restraint was minimal and only a small proportion of the difference in biscuit consumption was described by the model. 

- CART trees can be biased towards variables who have more cutpoints. Therefore, a conditional inference tree was also plotted. In this case only variables which have a statistically significant relationship with the response variable are included in the tree. Only pre taste test hunger was included in this tree (see plot below). This didn't change significantly after trying different model parameters and condition was not included in any of the trees.
  
![image](https://github.com/user-attachments/assets/eb2bbd0f-0330-4dbf-9efc-d45b3db3172c)
