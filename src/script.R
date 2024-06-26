library(tidyverse)
library(ggplot2)
library(forcats)
library(dplyr)
library(broom)
library(MVN)
library(agricolae)
library(ggcorrplot)
library(pwr)
library(BSDA)
library(gridExtra)
require(moonBook)
require(webr)
library(nortest)
library(pwr)
library(MKpower)
library(gridExtra)
library(ggdist)
library(pwrss)
library(TOSTER)
library(plotly)
library(gghighlight)
library(hrbrthemes)
library(viridis)


#reading datasets
df_general_num <- read.csv(file.path(getwd(), "data", "survey_num_27_10.csv"), header = TRUE, sep = ",")
df_general_text <- read.csv(file.path(getwd(), "data", "survey_text_27_10.csv"), header = TRUE, sep = ",")
df_num <- read.csv(file.path(getwd(), "data", "survey_num_27_10.csv"), header = TRUE, sep = ",")

#labeling missing values as NA
df_main[df_main == ""] <- NA

# these are used when visualizing barchart
x_order <- c("Strongly agree", "Somewhat agree", "Neither agree nor disagree", "Somewhat disagree", "Strongly disagree")
x_order1 <- c("Extremely good", "Somewhat good", "Neither good nor bad", "Somewhat bad", "Extremely bad")
mapping <- c("Tourism" = "#A8BAC4", "Leisure & Events" = "#A8BAC4", "Media" = "#A8BAC4",
             "Hotel" = "#A8BAC4", "Games" = "#A8BAC4", "Logistics" = "#A8BAC4",
             "Built Environment" = "#A8BAC4", "Facility" = "#076fa2", "Applied Data Science & AI" = "#A8BAC4", "Other" = "#A8BAC4")

# Filtering df text for Facility domain
df_facility_text <- df_general_text %>%
  slice(-1:-2) %>%
  select(12:36) %>%
  filter(demo_domain == "Facility", demo_age != "") %>%
  na.omit()

# Filtering df num for Facility domain
df_facility_num <- df_general_num %>%
  slice(-1:-2) %>%
  select(c(12:15, 17:36)) %>%
  filter(demo_domain == '8') %>%
  mutate_at(vars(-c("demo_gender", "demo_domain", "demo_experience")), as.integer) %>%
  na.omit()

# Adding noise to df facility num for linear regression
df_facility_noise <- df_facility_num %>%
  mutate(demo_ai_know = jitter(demo_ai_know, amount = 0.2),
         ml_dl_famil = jitter(ml_dl_famil, amount = 0.4),
         acc_2 = jitter(acc_2, amount = 0.5))

# Aggregating df num across all domains
df_domains_num <- df_general_num %>%
  slice(-1, -2) %>%
  select(c(12:15, 17:36)) %>%
  mutate_at(vars(-c("demo_domain")), as.numeric) %>%
  filter(demo_domain != '11') %>%
  mutate(demo_domain = case_when(
    demo_domain == '1' ~ 'Tourism',
    demo_domain == '2' ~ 'Leisure & Events',
    demo_domain == '3' ~ 'Media',
    demo_domain == '4' ~ 'Hotel',
    demo_domain == '5' ~ 'Games',
    demo_domain == '6' ~ 'Logistics',
    demo_domain == '7' ~ 'Built Environment',
    demo_domain == '8' ~ 'Facility',
    demo_domain == '9' ~ 'Applied Data Science & AI',
    demo_domain == '10' ~ 'Other',
    TRUE ~ demo_domain),
#adding noise to the variables
    demo_ai_know = jitter(demo_ai_know, amount = 0.2),
    ml_dl_famil = jitter(ml_dl_famil, amount = 0.4),
    aware_dom = jitter(aware_dom, amount = 0.5),
    ai_courses = jitter(ai_courses, amount = 0.5),
    aware_everyday = jitter(aware_everyday, amount = 0.5),
    used_ai = jitter(used_ai, amount = 0.5),
    demo_ai_know = jitter(demo_ai_know, amount = 0.1),
    demo_experience = jitter(demo_experience, amount = 0.2),
    att_pos_1 = jitter(att_pos_1, amount = 0.5),
    att_pos_2 = jitter(att_pos_2, amount = 0.5),
    att_pos_3 = jitter(att_pos_3, amount = 0.5),
    att_pos_4 = jitter(att_pos_4, amount = 0.5),
    att_neg_1 = jitter(att_neg_1, amount = 0.5),
    att_neg_2 = jitter(att_neg_2, amount = 0.5),
    att_neg_3 = jitter(att_neg_3, amount = 0.5),
    acc_1 = jitter(acc_1, amount = 0.5),
    acc_2 = jitter(acc_2, amount = 0.5),
    acc_3 = jitter(acc_3, amount = 0.5),
    acc_4 = jitter(acc_4, amount = 0.5),
    acc_5 = jitter(acc_5, amount = 0.5),
    acc_6 = jitter(acc_6, amount = 0.5)) %>%
  na.omit()

# Defining a function for grouping by a certain column
groupby_n <- function(df, colx, coly) {
  colx <- enquo(colx)
  coly <- enquo(coly)
  agg <- df %>% 
    group_by(!!colx, !!coly) %>%
    summarise(n = length(!!coly))
  return(agg)
}

# Defining a function for visualizing bar charts
bar <- function(df, colx, coly, title) {
  colx <- enquo(colx)
  coly <- enquo(coly)
  agg <- groupby_n(df, !!colx, !!coly)
  gg <- ggplot(agg, aes(x = !!colx, y = n, fill = !!coly)) + 
    geom_bar(stat = "identity", position = position_stack()) +
    scale_x_discrete(limits = x_order) + 
    labs(title = title, 
         x = '',
         y = "Count") +
    guides(fill = guide_legend(title = "Groups"),
           alpha = guide_legend(title = "Groups")) +
    theme_minimal() +
    theme(
      plot.title = element_text(size = 8),
      axis.title.x = element_text(size = 6),
      axis.title.y = element_text(size = 7),
      axis.text.x = element_text(size = 7, angle = 15, hjust = 1),
      axis.text.y = element_text(size = 6),
      legend.title = element_text(size = 7),
      legend.text = element_text(size = 7)
    ) +
    scale_fill_brewer(palette = "BuPu")
}

# 1. EDAs

# Visualizing participants from all domains
df_domain_par <- df_general_text %>%
  slice(-1:-2) %>%
  select(demo_domain) %>%
  filter(demo_domain != "Click to write Choice 10") %>%
  na.omit() %>%
  group_by(demo_domain) %>%
  summarise(n = length(demo_domain)) %>%
  arrange(desc(n)) %>%
  ggplot() +
  geom_col(aes(n, reorder(demo_domain, n)), fill = "#076fa2", width = 0.6) +
  gghighlight(demo_domain == "Facility") +
  scale_x_continuous(
    limits = c(0, 105),
    breaks = seq(0, 105, by = 10), 
    expand = c(0, 0), 
    position = "top") +
  scale_y_discrete(expand = expansion(add = c(0, .5))) +
  theme(
    panel.background = element_rect(fill = "white"),
    panel.grid.major.x = element_line(color = "#A8BAC4", size = 0.3),
    axis.ticks.length = unit(0, "mm"),
    axis.title = element_blank(),
    axis.line.y.left = element_line(color = "black"))

# Visualizing demographic groups from the Facility domain
role <- bar(df_facility_text, acc_3, demo_role, "Role")
gender <- bar(df_facility_text, acc_3, demo_gender, "Gender")
age <- bar(df_facility_text, acc_3, demo_age, "Age")
year_study <- bar(df_facility_text, acc_3, demo_year_study, "Year of study")
expr <- bar(df_facility_text, acc_3, demo_experience, "Experience in the domain")

# Arranging the plots
grid.arrange(role, gender, age, expr, ncol = 2, nrow = 2)

# 2. DESCRIPTIVE ANALYSIS

# 2 Sample T-test
t_test <- t.test(df_facility_num$used_ai, df_facility_num$acc_5)
df <- t_test$parameter #degree freedom is 36.968
t_value <- t_test$statistic #t-value is -41.03689 
p_value <- t_test$p.value # p-value is 1.94423e-32
conf_interval <- t_test$conf.int # CI is (-14.90114 -13.49886)


x <- seq(-41, 40, length = 1000)
pdf_values <- dt(seq(-41, 40, length = 1000), df)


# Plotting normal T distribution plot
density_plot <- data.frame(x, pdf_values) %>%
  ggplot(aes(x)) +
  geom_line(aes(y = pdf_values), color = "black") +
  geom_vline(xintercept = t_value, linetype = "dashed", color = "red", size = 0.5) +
  geom_ribbon(aes(x = x, ymin = ifelse(x < t_test$conf.int[1] | x > t_test$conf.int[2], dt(x, df), 0), ymax = 0), fill = "#076fa2", alpha = 0.2) +
  geom_text(aes(x = t_test$statistic, y = 0.3, label = paste("t-score =", round(t_test$statistic, 2)), angle = 90, vjust = 1.5), color = "black") +
  geom_text(aes(x = -20, y = 0.2, label = paste("95% CI \n [", round(t_test$conf.int[1], 2), ", ", round(t_test$conf.int[2], 2), "]")), vjust = -1, color = "red") +
  labs(title = "Two-Sample t test",
       x = "t statistic",
       y = "Probability Density"
  ) +
  xlim(c(-42, 5))

# Power analysis

# calculating the required sample for 80% power and the required power for the given sample
alpha <- 0.05
effect_size <- 0.5
desired_power <- 0.80
sample_size <- nrow(df_facility_num)
achieved_power <- 0
while (achieved_power < desired_power) {
  t_test_pwr <- pwr.t.test(
    d = effect_size,
    n = sample_size,
    sig.level = alpha,
    power = NULL,
    type = "two.sample"
  )
  achieved_power <- t_test_pwr$power  # Correct the variable name
  sample_size <- sample_size + 1
}
print(paste("Sample size needed to achieve 80% power:", sample_size - 1, "\n"))



# arranging the plots
grid.arrange(density_plot,pwr_plt) 



# 3. INFERENTIAL ANALYSIS


#Multiple linear regression

#ml_dl_famil - How familiar are students and teaching staff with ML and DL concepts
#acc_2 - Their level of willingness to use AI
#demo_experience - They years, months of experience within the domain
model2 <- lm(data=df_domains_num, formula = acc_2 ~ demo_experience+ml_dl_famil)  # identifying significant predictors
residuals2 <- residuals(model2)  # get the distances between predicted and actual values
sqrt_abs_residuals <- sqrt(abs(residuals2))
fitted <- predict(model2)
qq_data <- data.frame(Theoretical = quantile(residuals, probs = seq(0, 1, by = 0.01)),
                      Sample = quantile(rnorm(length(residuals2), mean = 0, sd = sd(residuals2)), probs = seq(0, 1, by = 0.01)))


# Resduals vs Fitted
r_vs_f <- ggplot(data.frame(fitted = fitted, residual = residuals2), aes(x = fitted, y = residual)) +
  geom_point(size = 1, alpha = 0.7, color = "#076fa2") +
  geom_smooth(method = "lm", formula = y ~ x, se = FALSE, color = "red", linetype = "dotted") +
  labs(
    title = "Residuals vs. Fitted",
    x = "Fitted Values",
    y = "Residuals"
  ) +
  theme(
    plot.title = element_text(size = 12),
    axis.title.x = element_text(size = 9),
    axis.title.y = element_text(size = 9)
  ) +
  scale_fill_brewer(palette = "BuPu")

# Normal Q-Q Plot
qqplot <- ggplot(qq_data, aes(x = Theoretical, y = Sample)) +
  geom_point(size = 1, alpha = 0.7, color = "#076fa2") +
  geom_abline(intercept = 0, slope = 1, color = "red",size = 1) +
  labs(
    title = "Normal Q-Q Plot",
    x = "Theoretical Quantiles",
    y = "Sample Quantiles"
  ) +
  theme(
    plot.title = element_text(size = 12),
    axis.title.x = element_text(size = 9),
    axis.title.y = element_text(size = 9)
  ) +
  scale_fill_brewer(palette = "BuPu")

# Scale-Location Plot
scale_loc <- ggplot(data.frame(fitted = fitted, sqrt_abs_residuals = sqrt_abs_residuals), aes(x = fitted, y = sqrt_abs_residuals)) +
  geom_point(size = 1, alpha = 0.7, color = "#076fa2") +
  geom_smooth(method = "lm", formula = y ~ x, se = TRUE, color = "red", linetype = "solid") +
  labs(
    title = "Scale-Location Plot",
    x = "Fitted Values",
    y = "Sqrt(|Residuals|)"
  ) +
  scale_fill_brewer(palette = "BuPu") +
  
  theme(
    plot.title = element_text(size = 12),
    axis.title.x = element_text(size = 9),
    axis.title.y = element_text(size = 9)
  ) 

# arranging the disgnostic plots
grid.arrange(r_vs_f,qqplot, scale_loc,ncol = 2, nrow = 2,layout_matrix = rbind(c(1,1), c(2,3)))


# Linear regression
df_facility_noise <- df_facility_num %>%
  mutate(demo_ai_know = jitter(demo_ai_know, amount = 0.2),
         ml_dl_famil = jitter(ml_dl_famil, amount = 0.4),
         demo_ai_know = jitter(demo_ai_know, amount = 0.1),
         acc_2 = jitter(acc_2, amount = 0.5))


#ml_dl_famil - How familiar are students and teaching staff with ML and DL concepts
#acc_2 - Their level of willingness to use AI
model1 <- lm(acc_2 ~ ml_dl_famil, data = df_facility_noise)
predicted_values <- predict(model1, df_facility_noise) 
residuals1 <- resid(model1) # get the distances between predicted and actual values
custom_size1 <- 20 - abs(residuals1)  

linear_regg_plot <- df_facility_noise %>%
  mutate(predicted_values = jitter(predicted_values, amount = 0.15)) %>%
  ggplot(aes(x = ml_dl_famil, y = acc_2)) +
  geom_segment(aes(xend = ml_dl_famil, yend = acc_2 - residuals1), color = "red") +
  geom_point(size = 3,aes(color = demo_domain)) +
  scale_color_manual(values = mapping) +
  geom_smooth(method = "lm", formula = y ~ x, se = FALSE, color = "#076fa2", linetype = "solid",fullrange = TRUE) +
  labs(
    x = "Knowledge of AI",
    y = "Intention to use AI"
  ) +
  xlim(min(df_domains_num$ml_dl_famil),max(df_domains_num$ml_dl_famil)) +
  theme(
    plot.title = element_text(size = 15),
    axis.title.x = element_text(size = 12),
    axis.title.y = element_text(size = 12),
    legend.position = "none"
  ) +
  geom_point(data = df_domains_num, aes(x = ml_dl_famil, y = acc_2),alpha = 0.5, color = "#A8BAC4", size=2.5)

linear_regg_plot






