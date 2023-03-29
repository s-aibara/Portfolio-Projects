#==============================================================================
# Simulate data to estimate a treatment effect in an RCT
#==============================================================================

#==========
#Set Up
#==========

# Clear the working space
  rm(list = ls())
  
  library(tidyverse) # data wrangling and aggregations
  library(sandwich)
  library(stargazer)
  library(dplyr)
  library(scales)
  library(fmsb)
  library(ggradar)

# turn off scientific notation except for big numbers
options(scipen = 9)
# function to calculate corrected SEs for regression 
cse <- function(reg) {
  rob = sqrt(diag(vcovHC(reg, type = "HC1")))
  return(rob)
}

#===========

# Simulate data
  set.seed(1234)
  N =1000

# Create a variable "comply" for whether a person is "complier" (in treatment group they
# will comply with treatment, in control group interpreted as spillover from treatment.
# Here set 10% of all people to be non-compliers.
  
# Add variables for child's age, gender, diarrhea occurrence, village id, mom's height, dad's height, pre-existing medical conditions, and wealth index 
# Variable description/units: age of child (measured in years), gender of child (male or female, binomial), number of diarrhea episodes per year (measured on scale from 1-5 (more than 2 is unhealthy)), village_id (which village each child is from), educ_mom (years, how many years of education the mom has from 1-7), med_cond (yes or no, binomial), height (inches),
#wealth_index (scale from 1-5)
 
  df <- data.frame(comply=sample(c(0, 1), N,replace=TRUE, prob=c(.1, .9)),
                  male= rbinom(N,1,.45),
                  age=sample(1:5, N, replace = TRUE), 
                  diarrhea=sample(1:5, N, replace = TRUE),
                  village_id=sample(1:20, N, replace=TRUE), 
                  educ_mom=sample(1:7, N, replace=TRUE),
                  med_cond=rbinom(N,1,.45),
                  wealth_index=sample(1:5, N, replace=TRUE, prob=c(.3,.3,.2,.1,.1)),
                  mom_height=sample(61:66, N, replace=TRUE),
                  dad_height=sample(66:72, N, replace=TRUE),
                  post=0)  
  
 # Create a variable "treat" that  will be indicator for treatment and control groups.
  df<-df %>% mutate(treat=
    ifelse(10 >= village_id, 1, 
    ifelse(11<= village_id & village_id <= 20, 0, NA)))
  
# Add a variable "id" to identify each participant. 
  df <- df %>% mutate(id=row_number())
 
#Define a variable "height" (height-for-age) measured in inches. 
  df<-df %>%mutate(height=
    ifelse(age==1, sample(25:30, n(), replace=TRUE),
    ifelse(age==2, sample(31:34, n(), replace=TRUE),
    ifelse(age==3, sample(35:39, n(), replace=TRUE),
    ifelse(age==4, sample(37:40, n(), replace=TRUE),
    ifelse(age==5, sample(39:43, n(), replace=TRUE), NA))))))
  
#Define a variable "weight" (weight-for-age) measured in pounds. 
  
  df<-df %>% mutate(weight=
    ifelse(age==1, sample(15:20, n(), replace=TRUE),
    ifelse(age==2, sample(19:26, n(), replace=TRUE),
    ifelse(age==3, sample(24:30, n(), replace=TRUE),
    ifelse(age==4, sample(28:35, n(), replace=TRUE),
    ifelse(age==5, sample(31:40, n(), replace=TRUE), NA))))))
  
#Define a variable "upper_arm" for upper-arm circumference, measured in inches (indicator for malnutrition). 
  
  df<-df %>% mutate(upper_arm=
    ifelse(age==1, sample(4.7:5.5, n(), replace=TRUE),
    ifelse(age==2, sample(5:6, n(), replace=TRUE),
    ifelse(age==3, sample(5.2:6.1, n(), replace=TRUE),
    ifelse(age==4, sample(5.3:6.5, n(), replace=TRUE),
    ifelse(age==5, sample(5.5:6.6, n(), replace=TRUE), NA))))))
  
  
# Now copy the data set and change the variable post=1 (observe after treatment).
  df2 <- df %>% mutate(post=1)
# Then append the two data frames so now have a "long" dataset (each id observed twice)
  df <- rbind(df, df2)
  rm(df2)
  
              
# Define a variable treat_effect that will be the simple treatment effect
df <- df %>% mutate(treat_effect_h=
    ifelse(treat==1 & comply==1, 2,
    ifelse(treat==1 & comply==0, 1,
    ifelse(treat==0 & comply==1, .5,
    ifelse(treat==0 & comply==0, .5, NA)))))

df <- df %>% mutate(treat_effect_w=
    ifelse(treat==1 & comply==1, 4,
    ifelse(treat==1 & comply==0, 2,
    ifelse(treat==0 & comply==1, 1,
    ifelse(treat==0 & comply==0, 1, NA)))))

df <- df %>% mutate(treat_effect_d=
  ifelse(treat==1 & comply==1, -1,
  ifelse(treat==1 & comply==0, 2,
  ifelse(treat==0 & comply==1, 3,
  ifelse(treat==0 & comply==0, 3, NA)))))

# Create pre and post outcomes. Here the primary outcome is height-for-age, measured after one year.

df <- df %>% mutate(height=
  ifelse(post==0, 0.15*male+0.25*age+0.38*upper_arm+0.25*educ_mom+0.15*mom_height+0.15*dad_height+rnorm(n()),
  ifelse(post==1, treat_effect_h+height+rnorm(n(),3,.5), height)))

df$height <-rescale(df$height, to = c(26,44))

# Secondary outcome: Weight (measured in pounds) after one year 
# Do not include variables for mom's height and dad's height --> not good explanatory variables for weight. 

df<-df %>% mutate(weight=
  ifelse(post==0, 0.2*male+0.3*age+0.42*upper_arm+0.22*educ_mom+rnorm(n()),
  ifelse(post==1, treat_effect_w+weight+rnorm(n(),.3, .5), weight)))

df$weight <-rescale(df$weight, to = c(15,40))

# Secondary outcome: Diarrhea occurrence (number of diarrhea episodes) after one year.
# Do not include variables for mom's height and dad's height --> not good explanatory variables for diarrhea.

df<-df %>% mutate(diarrhea=
  ifelse(post==0, 0.15*male-0.17*age-0.54*upper_arm-0.32*educ_mom+rnorm(n()),
  ifelse(post==1, treat_effect_d+diarrhea+rnorm(n(),.3, .5), diarrhea)))

df$diarrhea <-rescale(df$diarrhea, to = c(0,5))

#age variable after 1 year 
df<-df %>% mutate(age_2=
  ifelse(age==1 & post==1, 2,
  ifelse(age==2 & post==1, 3,
  ifelse(age==3 & post==1, 4,
  ifelse(age==4 & post==1, 5,
  ifelse(age==5 & post==1, 6,age))))))

#==============
#Balance Table
#==============
#install.packages("kableExtra")
library(kableExtra)
library(pacman)

#balance table function
{
  # here is the function
  balance_table_frame <- function(vars, treat_var, data_set) {
    # load packages using pacman (installs package if necessary)
    if (!require(pacman)) install.packages('pacman', repos = 'https://cran.rstudio.com')
    pacman::p_load(broom, haven, knitr, sandwich, data.table, tidyverse) 
    
    # turn off scientific notation except for big numbers
    options(scipen = 9) 
    options(digits=3)
    # function to calculate corrected SEs for OLS regression 
    cse = function(reg) {
      rob = sqrt(diag(vcovHC(reg, type = "HC1")))
      return(rob)
    } 
    n_vars <- length(vars) 
    treat <- rep(treat_var, t=n_vars)
    data <- rep(data_set, t=n_vars) 
    
    coeff <- function(y, x, d) { 
      df <- get(d) 
      reg <- lm(as.formula(paste0(y," ~ ", x)), data=df) 
      n_obs <- summary(reg)$df[2] + 2        # grab the regression sample size
      coef <- tidy(reg) %>% 
        select(term, estimate, std.error)  
      rob_se <- as.data.frame(cse(reg)) %>%           # robust SEs
        rownames_to_column(var = "term") %>% 
        rename(se_robust = `cse(reg)`) 
      treat_est <- coef %>% 
        left_join(rob_se) %>% 
        mutate(treat_var = x,
               variable = y,
               n_obs = n_obs, 
               p_value = 2*pnorm(-abs(estimate/se_robust),0,1)) 
      treat_est <- as.data.frame(treat_est)
      return(treat_est)
    }
    
    # use mapply to get the coefficients and p values 
    qq <- mapply(coeff, vars, treat, data, SIMPLIFY = FALSE) 
    
    # get the data set for table
    qqq <- do.call("rbind",qq)  
    control <- qqq %>% 
      filter(term=="(Intercept)") %>% 
      select(control=estimate, variable)
    balance_table <- qqq %>% 
      filter(term!="(Intercept)")  %>% 
      select(diff=estimate, variable, p_value, n_obs) %>% 
      left_join(control) %>% 
      mutate(treated = control+diff) %>% 
      select(variable, control, treated, diff, p_value, n_obs)
  }
  # end of function (remember to copy the close brace } above)
}

baltable<-balance_table_frame(c("male","age","diarrhea","educ_mom","height","weight","upper_arm","med_cond","wealth_index","mom_height","dad_height"),c("treat"),c("df"))

baltable %>% 
  kbl()%>%
  kable_paper("hover", full_width=F)


#=========
#Graphs
#=========

#Graphs for HEIGHT. 

#1. Boxplot of height-for-age before and after the intervention.

pre_treat<-subset(df, post=="0" & comply=="1")
pre_treat$treat_f <- as.factor(pre_treat$treat)

ggplot(data=pre_treat, aes(x=treat_f, y=height,fill=treat_f)) +
  geom_boxplot() + 
  labs(title="Figure 1: Height (in inches) Pre-Intervention") + 
  labs(x="Treatment Group", y="Height (in inches) Before Intervention")+
  labs(fill="Treatment Group")+
  scale_fill_discrete(labels=c("0:Control Group (no probiotic)", "1: Treated Group (received probiotic)"))

post_treat<-subset(df, post=="1" & comply=="1")
post_treat$treat_f <- as.factor(post_treat$treat)

ggplot(data=post_treat, aes(x=treat_f, y=height, fill=treat_f)) +
  geom_boxplot() + 
  labs(title="Figure 2: Height (in Inches) After Intervention") + 
  labs(x="Treatment Group", y="Height (in inches)")+
  labs(fill="Treatment Group")+
  scale_fill_discrete(labels=c("0: Control Group (no probiotic)", "1: Treatment Group (received probiotic)"))

#2. Linear graph of height (in inches) and age (in years), grouped by treatment.

df$treat_f<- as.factor(df$treat)

ggplot(data=post_treat, aes(x=age_2, y=height, group=treat_f, fill=treat_f))+
  geom_smooth(method=loess, color="black", size=1)+
  labs(title="Figure 3: Height-For-Age Post-Intervention", 
       x="Age (in years)" , y="Height (in inches)")+
  scale_fill_discrete(name="Treatment Group", labels=c("0: Control Group (no probiotic)", "1: Treatement Group (received probiotic)"))

#Graphs for WEIGHT

#3. Boxplot of weight-for-age before and after the intervention. 

ggplot(data=pre_treat, aes(x=treat_f, y=weight,fill=treat_f)) +
  geom_boxplot() + 
  labs(title="Figure 4: Weight (in pounds) Pre-Intervention") + 
  labs(x="Treatment Group", y="Weight (in pounds) Before Intervention")+
  labs(fill="Treatment Group")+
  scale_fill_discrete(labels=c("0: Control Group (no probiotic)", "1: Treatment Group (received probiotic)"))

ggplot(data=post_treat, aes(x=treat_f, y=weight,fill=treat_f)) +
  geom_boxplot() + 
  labs(title="Figure 5: Weight (in pounds) After Intervention") + 
  labs(x="Treatment Group", y="Weight (in pounds)")+
  labs(fill="Treatment Group")+
  scale_fill_discrete(labels=c("0: Control Group (no probiotic)", "1: Treatment Group (received probiotic)"))

#4. Linear graph of weight(in pounds) and age (in years)

ggplot(data=post_treat, aes(x=age_2, y=weight, group=treat_f, fill=treat_f))+
  geom_smooth(method=loess, color="black", size=1)+
  labs(title="Figure 6: Weight-For-Age Post-Intervention", 
       x="Age (in years)" , y="Weight (in pounds)")+
  scale_fill_discrete(name="Treatment Group", labels=c("0: Control Group (no probiotic)", "1: Treatement Group (received probiotic)"))

#Graphs for DIARRHEA 

#5. Diarrhea occurrence before and after the intervention. 

ggplot(data=pre_treat, aes(x=treat_f, y=diarrhea,fill=treat_f)) +
  geom_boxplot() + 
  labs(title="Figure 7: Number of Diarrhea Episodes Pre-Intervention") + 
  labs(x="Treatment Group", y="Number of Diarrhea Episodes")+
  labs(fill="Treatment Group")+
  scale_fill_discrete(labels=c("0: Control Group (no probiotic)", "1: Treatment Group (received probiotic)"))

ggplot(data=post_treat, aes(x=treat_f, y=diarrhea,fill=treat_f)) +
  geom_boxplot() + 
  labs(title="Figure 8: Number of Diarrhea Episodes After Intervention") + 
  labs(x="Treatment Group", y="Number of Diarrhea Episodes")+
  labs(fill="Treatment Group")+
  scale_fill_discrete(labels=c("0: Control Group (no probiotic)", "1: Treatment Group (received probiotic)"))

#6. Linear graph of diarrhea occurrence and age.

ggplot(data=post_treat, aes(x=age_2, y=diarrhea, group=treat_f, fill=treat_f))+
  geom_smooth(method=loess, color="black", size=1)+
  labs(title="Figure 9: Diarrhea Occurrence Post-Intervention", 
       x="Age (in years)" , y="Diarrhea Occurrence (Number of Episode)")+
  scale_fill_discrete(name="Treatment Group", labels=c("0: Control Group (no probiotic)", "1: Treatement Group (received probiotic)"))

#7. Radar Graph for Diarrhea

#install.packages("fmsb")
devtools::install_github("ricardo-bion/ggradar", dependencies = TRUE)
#library(fmsb)
library(ggradar)
library(scales)

# Radar graph using ggradar
xx <- df %>% filter(post==1) %>% select(-id,-post, -comply, -treat_effect_h,-treat_effect_w,-treat_effect_d,-village_id,-comply,-weight,-height,-treat_f,-med_cond,-wealth_index,-mom_height,-dad_height) %>% 
  rename(group=treat) %>% mutate(group=as.character(group)) %>% 
  mutate_each(funs(scales::rescale),-group) %>% 
  group_by(group) %>% 
  summarise(across(male:upper_arm, base::mean))
ggradar(xx,label.gridline.min = F, label.gridline.mid = F, label.gridline.max = F)+
  labs(title="Figure 10: Radar graph of diarrhea frequency and control variables") + 
  theme(plot.title = element_text(size=5)+
          theme(plot.title.position = "plot"))

#============
#Regressions
#============

reg1<-lm(height~post+treat+post*treat, data=df)
reg2<-lm(height~post+treat+post*treat+male, data=df)
reg3<-lm(height~post+treat+post*treat+male+age, data=df)
reg4<-lm(height~post+treat+post*treat+male+age+upper_arm, data=df)
reg5<-lm(height~post+treat+post*treat+male+age+upper_arm+educ_mom, data=df)
reg6<-lm(height~post+treat+post*treat+male+age+upper_arm+educ_mom+mom_height, data=df)
reg7<-lm(height~post+treat+post*treat+male+age+upper_arm+educ_mom+mom_height+dad_height, data=df)

stargazer(reg1, reg2, reg3, reg4,reg5, reg6, reg7,
          se=list(cse(reg1),cse(reg2),cse(reg3),cse(reg4), cse(reg5), cse(reg6), cse(reg7)), 
          title="Table 2: Effect of Control Variables on Height (After 1 Year)", type="text", 
          df=FALSE, digits=3)

reg8<-lm(weight~post+treat+post*treat, data=df)
reg9<-lm(weight~post+treat+post*treat+male, data=df)
reg10<-lm(weight~post+treat+post*treat+male+age, data=df)
reg11<-lm(weight~post+treat+post*treat+male+age+upper_arm, data=df)
reg12<-lm(weight~post+treat+post*treat+male+age+upper_arm+educ_mom, data=df)

stargazer(reg8, reg9, reg10, reg11, reg12,
          se=list(cse(reg8),cse(reg9),cse(reg10),cse(reg11),cse(reg12)), 
          title="Table 3: Effect of Control Variables on Weight (After 1 Year)", type="text", 
          df=FALSE, digits=3)

reg13<-lm(diarrhea~post+treat+post*treat, data=df)
reg14<-lm(diarrhea~post+treat+post*treat+male, data=df)
reg15<-lm(diarrhea~post+treat+post*treat+male+age, data=df)
reg16<-lm(diarrhea~post+treat+post*treat+male+age+upper_arm, data=df)
reg17<-lm(diarrhea~post+treat+post*treat+male+age+upper_arm+educ_mom, data=df)

stargazer(reg13, reg14, reg15, reg16, reg17,
          se=list(cse(reg13), cse(reg14),cse(reg15),cse(reg16), cse(reg17)), 
          title="Table 4: Effect of Control Variables on Weight (After 1 Year)", type="text", 
          df=FALSE, digits=3)

#===========
#Robustness
#===========

#Change Model Specifications 

#1. Alternate Specification: control for existing medical conditions.  

df <- df %>% mutate(height2=
  ifelse(post==0, 0.15*male+0.25*age+0.38*upper_arm+0.25*educ_mom+0.15*mom_height+0.15*dad_height+0.12*med_cond+rnorm(n()),
  ifelse(post==1, treat_effect_h+height+rnorm(n(),3,.5), height)))

df$height2<-rescale(df$height, to = c(26,44))

reg18<-lm(height2~post+treat+post*treat, data=df)
reg19<-lm(height2~post+treat+post*treat+male, data=df)
reg20<-lm(height2~post+treat+post*treat+male+age, data=df)
reg21<-lm(height2~post+treat+post*treat+male+age+upper_arm, data=df)
reg22<-lm(height2~post+treat+post*treat+male+age+upper_arm+educ_mom, data=df)
reg23<-lm(height2~post+treat+post*treat+male+age+upper_arm+educ_mom+med_cond, data=df)
reg24<-lm(height2~post+treat+post*treat+male+age+upper_arm+educ_mom+med_cond+mom_height, data=df)
reg25<-lm(height2~post+treat+post*treat+male+age+upper_arm+educ_mom+med_cond+mom_height+dad_height, data=df)


stargazer(reg18, reg19, reg20, reg21, reg22, reg23, reg24, reg25,
          se=list(cse(reg18),cse(reg19),cse(reg20),cse(reg21),cse(reg22),cse(reg24),cse(reg25)), 
          title="Table 5: Effect of Control Variables on Height (After 1 Year)", type="text", 
          df=FALSE, digits=3)

#2. Include a control variable for wealth index.

df <- df %>% mutate(height3=
  ifelse(post==0, 0.15*male+0.25*age+0.38*upper_arm+0.25*educ_mom+0.15*mom_height+0.15*dad_height+0.12*med_cond+0.15*wealth_index+rnorm(n()),
  ifelse(post==1, treat_effect_h+height+rnorm(n(),3,.5), height)))

df$height3<-rescale(df$height3, to = c(26,44))

reg26<-lm(height3~post+treat+post*treat, data=df)
reg27<-lm(height3~post+treat+post*treat+age, data=df)
reg28<-lm(height3~post+treat+post*treat+age+upper_arm, data=df)
reg29<-lm(height3~post+treat+post*treat+age+upper_arm+educ_mom, data=df)
reg30<-lm(height3~post+treat+post*treat+age+upper_arm+educ_mom+mom_height, data=df)
reg31<-lm(height3~post+treat+post*treat+age+upper_arm+educ_mom+mom_height+dad_height, data=df)
reg32<-lm(height3~post+treat+post*treat+age+upper_arm+educ_mom+mom_height+dad_height+wealth_index, data=df)

stargazer(reg26, reg27, reg28, reg29, reg30, reg31, reg32,
          se=list(cse(reg26),cse(reg27),cse(reg28),cse(reg29), cse(reg30), cse(reg31), cse(reg32)), 
          title="Table 6: Effect of Control Variables on Height (After 1 Year)", type="text", 
          df=FALSE, digits=3)

