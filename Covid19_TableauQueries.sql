--Queries used for Tableau Project using Covid 19 data from Data Exploration project.
--(Reference: Alex the Analyst)


---------------

--Visualizing Global Numbers (Cases, Deaths, Death Percentage)

--1. 

SELECT SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths, SUM(new_deaths)/SUM(new_cases)*100 as death_percentage
FROM covid_deaths
--WHERE location = 'United States'
WHERE continent IS NOT NULL
--GROUP BY date
ORDER BY 1,2

---------------

--Visualizing Total Death Count Per Continent

--2. 

SELECT location, SUM(new_deaths) as total_death_count
From covid_deaths
WHERE continent IS NULL 
AND location NOT IN ('World', 'European Union', 'International')
GROUP BY location
ORDER BY total_death_count DESC


---------------

--Visualizing Infection Rate Per Country

--3.

SELECT location, population, MAX(total_cases) as highest_infection_count,  MAX((total_cases/population))*100 as percent_pop_infected
FROM covid_deaths
GROUP BY location, population
ORDER BY percent_pop_infected DESC NULLS LAST

--4. 

SELECT location, population, date, MAX(total_cases) as highest_infection_count,  Max((total_cases/population))*100 as percent_pop_infected
FROM covid_deaths
GROUP BY location, population, date
ORDER BY percent_pop_infected DESC NULLS LAST

--5. 

--Visualizing Total Vaccinations per Continent/Country 

SELECT * 
FROM public.percent_population_vaxed 
ORDER BY rolling_people_vacc DESC NULLS LAST
