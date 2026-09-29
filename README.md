# airbnb-property-analysis
An analysis of public Airbnb data across 10 cities.

[Graphs can be seen here](https://public.tableau.com/views/AnanalysisofpublicAirbnbdataacross10cities_/Dashboard1?:language=en-GB&:sid=&:redirect=auth&:display_count=n&:origin=viz_share_link)

# Evaluating Airbnb Property Opportunities Using Publicly Available Listings Data


## Introduction

The objective of this analysis is to make practical use of a dataset containing publicly available information on Airbnb listings in 10 cities around the world, in order to potentially help a prospective host decide on a property to acquire. A major limitation of the data is in the lack of information on various crucial aspects that would normally be considered when making such a decision, such as occupancy rate, maintenance costs, property actual size etc.


## Questions for Answering

In this project, the available data will be examined with the purpose of addressing 3 main questions a host may have when deciding on a property to invest in. The 3 questions are: 
- What is a potentially suitable location for the property? 
- What type of room and property size may be suitable?
- What amenities may be important for competing in the market?


## Key Findings

The analysis identified Rome as the city with the highest number of reviews per listing, so the analysis was narrowed down to Rome. Three neighbourhoods were then selected based on guest activity, ratings, and the concentration of experienced hosts.
The property type analysis showed that entire places, particularly those with a relatively small number of bedrooms, were common within the selected neighbourhoods.
The amenities analysis highlighted which amenities are most common in the market and compared their differences in average property prices and ratings.


## Tools Used

The main tool used in this project was **SQL** for data cleaning and querying to obtain the required results.
**Tableau** was then used to create the final visualizations of the findings.
**Excel** was also used to assist with importing the data into SQL and handling a specific cleaning process.
**ChatGPT** was used for support with some parts of the code, data cleaning, table creation, and organization.


## Process

Exploration, Cleaning and Filtering:
After some initial exploration of the dataset, the data was cleaned, mostly by retrieving missing values where possible and otherwise setting inconsistent or illogical values to NULL. Some new tables were also created for better organization, while NULL values were reviewed to decide which rows needed to be dropped.


## Analysis Process:

The analysis was divided into three main stages, progressively narrowing down the type of opportunity being investigated.

1. **Location**

   This stage was done by mainly comparing the following key values in each different city or neighbourhood:

   * The average rating for each group and its deviation from the overall average rating, since this could imply lower (or higher) satisfaction in specific areas, especially neighbourhoods, potentially indicating markets to compete in.
   * The reviews per listing of each group, as it can work as a (not definite, but still indicative) measure of guest activity relative to the available listings, helping identify where people utilize Airbnb more compared to the available supply. The reviews were limited to more recent years to get a more accurate image of the recent situation.
   * Experienced host concentration in each group to identify areas with a higher concentration of established hosts and potentially more established competition.

   For cities, COVID's influence was also accounted for by checking the drop in reviews between 2019 and 2020.

   The growth of review count was also checked per year to account for a potentially growing market.

2. **Property Type**

   From the second stage onward, the scope of the study was limited to Rome and the 3 neighbourhoods that we narrowed down as potentially more appealing based on guest activity, ratings, and experienced host concentration (in spite of the lack of definite information). The following were then examined using similar metrics to the previous stage:

   * Room type: To identify which room type was more appealing.
   * Bedroom count: To identify what size had more apparent demand, utilizing bedroom count due to the lack of any metric for property size.

3. **Property Characteristics**

   In the final stage, while further limiting the analysis to the selected property types, the amenities were examined to identify differences in price and ratings between listings with and without each amenity. Minimum and maximum nights were also briefly reviewed as additional considerations. The amenity analysis was conducted by calculating:

   * Each amenity's frequency in Rome (how many % of listings contain it).
   * The average price difference for listings with and without that amenity.
   * Similarly, the difference in ratings for listings with and without that amenity.



## Insights

Through the data, we can see tendencies that correspond to what we know from real life, such as the popularity of some cities as historical landmarks and the effect of **COVID**, however, the data lacks the necessary parameters to confidently assess **profitability** or make a strong investment decision.

Even so, the following insights can be drawn from the analysis:

* **Rome** showed an almost double **reviews per listing ratio** compared to the second highest, without significant issues in the other parameters examined, leading to a more detailed analysis of the city.
* Several **neighbourhoods** stood out as potentially interesting areas, due to their high **reviews per listing ratio** and:

  * **I Centro Storico:** Highest ratio and relatively lower ratings.
  * **VII San Giovanni/Cinecitta:** relatively lower experienced hosts % with relatively better location score.
  * **II Paroli/Nomentano:** Lower rating compared to average while having a relatively high ratio.
* **Entire apartments** were the most common room type and showed considerable guest activity, making them a reasonable starting point when considering the type of property.
* Bedrooms with more bedrooms showed a **decreasing guest activity**, which is to be expected as bigger groups are rarer.
* Some **amenities showed noticeable differences in average ratings** when they were absent, providing an indication of which amenities may be worth considering in a potential listing.
* Some amenities also showed **noticeable differences in average price**, providing insight into which features are associated with higher or lower listing prices, although this alone does not indicate whether they are more profitable.

Graphs indicating the above findings in more detail were done in **Tableau** and can be found in the repository, along with the **analytical code**.



## Reflections and Limitations

While the dataset provides useful insights into Airbnb activity, it lacks enough information to confidently assess profitability. Reviews per listing can indicate demand vs supply, but they cannot be used as a direct measure of occupancy. Similarly, differences in price or ratings cannot directly establish that a specific property characteristic caused those differences.
With additional data, the analysis could be expanded by including occupancy rates, operating expenses, property size and building age, as well as more recent market data. This would allow for a more complete comparison of properties and a more realistic assessment of profitability.


## What I learned

While in the end the project did not provide any definite answers, it was still a valuable experience. It familiarized me with many SQL concepts that I did not have enough experience with and gave me a better understanding of how to choose a suitable dataset with more relevant information, even if it is smaller in scale. This knowledge will be utilized in the next project, in hopes of leading to a more practical result.
