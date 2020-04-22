
# Use ACS occupation data from table S2401 to approximate essential workers by census tract. 
# Compare to race, poverty, income.
# CMAP | Matt Stern | 4/15/2020

# packages
library(tidyverse)
library(tidycensus)


# variables
year <- 2018

# FIPS codes for 7 counties in CMAP region
counties <- c("031", "043", "089", "093", "097", "111", "197")

# essential worker assignments, identified by variable ID.
#  no  = not essential
#  na  = a subtotal in the table. Disregard.
#  conman = Construction, Manufacturing, Maintenance
occ_class <- tribble(~variable, ~essential,
                     "S2401_C01_001", "total",
                     "S2401_C01_002", "na",
                     "S2401_C01_003", "na",
                     "S2401_C01_004", "no",
                     "S2401_C01_005", "no",
                     "S2401_C01_006", "na",
                     "S2401_C01_007", "no",
                     "S2401_C01_008", "no",
                     "S2401_C01_009", "no",
                     "S2401_C01_010", "na",
                     "S2401_C01_011", "socialservices",
                     "S2401_C01_012", "no",
                     "S2401_C01_013", "no",
                     "S2401_C01_014", "no",
                     "S2401_C01_015", "na",
                     "S2401_C01_016", "health",
                     "S2401_C01_017", "health",
                     "S2401_C01_018", "na",
                     "S2401_C01_019", "health",
                     "S2401_C01_020", "na",
                     "S2401_C01_021", "protection",
                     "S2401_C01_022", "protection",
                     "S2401_C01_023", "food",
                     "S2401_C01_024", "conman",
                     "S2401_C01_025", "no",
                     "S2401_C01_026", "na",
                     "S2401_C01_027", "no",
                     "S2401_C01_028", "no",
                     "S2401_C01_029", "na",
                     "S2401_C01_030", "food",
                     "S2401_C01_031", "conman",
                     "S2401_C01_032", "conman",
                     "S2401_C01_033", "na",
                     "S2401_C01_034", "conman",
                     "S2401_C01_035", "transport",
                     "S2401_C01_036", "transport"
)

# build vector of occupation categories
occ_class_list <- filter(occ_class, essential != "total" & essential != "na") %>% 
  .[["essential"]] %>% 
  unique()


# load full ACS variables list, if needed
#load_variables(year, "acs5/subject", cache = TRUE) %>% 
#  View()


# get descriptive variable names for table S2401
varnames <- load_variables(year, "acs5/subject", cache = TRUE) %>% 
  # get only records from this table
  filter(str_sub(name, 1, 5) == "S2401") %>%
  # remove unnecessary label text
  mutate(label = sub('^Estimate!!', '', label)) %>% 
  # drop unnecessary columns and rename
  select(variable = name, label)


# get occupation data
S2401 <- get_acs(geography = "tract", table = "S2401", cache_table = TRUE, 
                 year = year, state = "17", county = counties, survey = "acs5")

# clean up occupation data
S2401_clean <- S2401 %>%
  # add descriptive variable names
  left_join(varnames, by = "variable") %>% 
  # drop gender and gender percent data, keeping only total
  filter(str_sub(label, 1, 5) == "Total") %>% 
  # add occupation classes
  left_join(occ_class, by = "variable") %>% 
  # clean labels by separating into separate columns. At the moment, keep only the last (most detailed) descriptor
  separate(label, into = c(NA, NA, NA, NA, "label"), sep = "!!", fill = "left") %>%
  # drop all subtotal records
  filter(essential != "na")

# check that all workers are still in the data
S2401_clean %>% 
  # turn essential into just a total vs subcategory column
  mutate(essential = if_else(essential == "total", "total", "sub")) %>% 
  # summarize employment by total and subtotal per tract
  group_by(NAME, essential) %>% 
  summarize(estimate = sum(estimate)) %>% 
  pivot_wider(id_cols = NAME, names_from = essential, values_from = estimate) %>% 
  # generate a check column, and see if it equals 0
  mutate(check = (total - sub) == 0) %>%
  .[["check"]] %>% 
  # return TRUE if every check is TRUE
  all()


# get demographic data from various tables
# B01001_001 == total population
# B19013_001 == Median HH income
# S1701_C03_001 == Percent below poverty level
# DP05_0077PE == Percent white not hispanic
demogs <- get_acs(geography = "tract", variables = c("B01001_001", "B19013_001", "S1701_C03_001", "DP05_0077PE"), 
                  cache_table = TRUE, year = year, state = "17", county = counties, survey = "acs5", output = "wide")

# clean demographic data
demogs_clean <- demogs %>% 
  # generate percent nonwhite
  mutate(nonwhite_pct = 100 - DP05_0077PE) %>% 
  # select and rename other variables
  select(GEOID, total_pop = B01001_001E, nonwhite_pct, pov_pct = S1701_C03_001E, hh_inc_med = B19013_001E) %>% 
  # convert percentages to decimals
  mutate(nonwhite_pct = nonwhite_pct / 100,
         pov_pct = pov_pct / 100)


# stitch together final analysis
final <- S2401_clean %>% 
  # summarize employment categories per tract
  group_by(GEOID, essential) %>% 
  summarize(NAME = first(NAME),
            estimate = sum(estimate)) %>% 
  # widen the table so there is 1 row per census tract
  pivot_wider(id_cols = c(GEOID, NAME), names_from = essential, values_from = estimate) %>% 
  # calculate percentages of various essential worker categories
  mutate_at(occ_class_list, ~ . / total) %>% 
  mutate(essential = 1 - no) %>% 
  # clean up column names
  select(GEOID, NAME, total_workers = total, essential, nonessential = no, everything()) %>% 
  # add demographic info
  full_join(demogs_clean, by = "GEOID") %>% 
  # clean up tract name
  separate(NAME, into = c("tract", "county", NA), sep = ", ", remove = FALSE) %>% 
  mutate(county = sub(' County', '', county),
         tract = gsub("[^0-9.-]", "", tract)) %>% 
  # drop tracts with fewer than 100 workers, for SOME degree of MOE accuracy
  filter(total_workers > 99)
  

# check that all counties have all/most tracts
final  %>%
  group_by(county) %>% 
  summarize(records = n()) %>%
  # These are the actual number of 2010 census tracts in each county
  left_join(tribble(~county, ~tracts,
                    "Cook", 1319,
                    "DuPage", 216,
                    "Kane", 82,
                    "Kendall", 10,
                    "Lake", 154,
                    "McHenry", 52,
                    "Will", 152),
            by = "county") %>% 
  mutate(percent = records / tracts)


# Graphical comparisons
ggplot(final, aes(essential, hh_inc_med)) + geom_point() + geom_smooth(color = "red")
ggplot(final, aes(essential, hh_inc_med)) + geom_point() + geom_smooth(color = "red") + 
  coord_trans(y = "log2") + scale_y_continuous(labels = scales::comma_format(), breaks = c(50000,100000,150000,200000))
ggplot(final, aes(essential, nonwhite_pct)) + geom_point() + geom_smooth(color = "red") + scale_y_continuous(limits = c(0,1))
ggplot(final, aes(essential, pov_pct)) + geom_point() + geom_smooth(color = "red") + scale_y_continuous()


# export
write.csv(final, "essential occupations data.csv")

