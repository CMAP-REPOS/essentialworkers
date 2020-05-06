# Where "Essential Workers" likely live
This analysis underpins the 4/24/2020 CMAP Policy Update [Metropolitan Chicago’s essential workers disproportionately low-income, people of color](https://www.cmap.illinois.gov/updates/all/-/asset_publisher/UIMfSLnFfMB6/content/metropolitan-chicago-s-essential-workers-disproportionately-low-income-people-of-color).

In response to the COVID-19 crisis, Illinois Governor J.B. Pritzker passed [Executive Order 20-10](https://www2.illinois.gov/Pages/Executive-Orders/ExecutiveOrder2020-10.aspx), requiring non-essential workers to stay home. The order and additional state guidance define the universe of essential workers -- for the most part, the people who keep our transportation system running, produce the food and supplies we use daily, and provide social services and healthcare.

This script uses census tract-level occupational data from ACS table S2401 to approximately identify essential workers in the CMAP's 7 county Chicagoland region, along with parallel tract-level demographic information including income, poverty, and race & ethnicity data.

We marked the following occupations as essential:
1. Community and social services (21-0000) 
2. Health diagnosing and treating practitioners, Health technologists and technicians, and other technical occupations (29-0000) 
3. Healthcare support (31-0000) 
4. Protective service (33-0000) 
5. Food preparation and service (35-0000) 
6. Building and grounds cleaning and maintenance (37-0000) 
7. Personal care and service (39-0000) 
8. Farming, fishing, and forestry (45-0000) 
9. Construction and extraction (47-0000) 
10. Installation, maintenance, and repair (49-0000) 
11. Production (51-0000) 
12. Transportation and material moving (53-0000) 

Recent shutdowns and closures do not follow these rigid classifications and segmenting the workforce for research is imprecise. This initial analysis includes all regional workers in the occupations listed above, but does not include workers in other frontline industries that are outside of these categories. As a result, estimates exclude some workers in industries that are hard at work during this crisis, while also including some workers who are unable to work, even though they are in essential occupations. For example, grocery store clerks are working at the frontlines, even though they are classified in a non-essential occupation (retail sales workers). However, school bus drivers are unable to work in areas where schools are closed, even though they are in an essential occupation (passenger vehicle and public transit operators). Still, the vast majority of workers in the essential occupations are essential workers. 


## Files
- `essential occupations script.R` is a Tidyverse-based R script that utilizes the Tidycensus package to collect data directly from the US census API.
- `essential occupations data.csv` is the output file the script produces. This CSV includes tract-level employment and demographic statistics. 
