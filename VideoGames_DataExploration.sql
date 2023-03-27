-- Video Games Data Exploration Project (Prompt Reference: DataCamp)
-- Skills Used: Joins, Set Theory, Aggregate Functions, Subqueries, CTEs

--1. What are the 10 best selling video games? 

SELECT * 
FROM game_sales 
ORDER BY total_shipped DESC 
LIMIT 10; 

--2. What are the 10 worst selling video games?
SELECT * 
FROM game_sales 
ORDER BY total_shipped
LIMIT 10; 

--3. How many games in the game_sales table are missing both a user_score and a critic_score? 

SELECT COUNT(g.name)
FROM game_sales as g
FULL JOIN game_reviews as r
ON g.name = r.name
WHERE critic_score IS NULL 
	AND user_score IS NULL; 
	
--4. Looking at the years with the highest average critic_score.

SELECT year, ROUND(AVG(critic_score),2) as avg_critic_score
FROM game_sales as g
INNER JOIN game_reviews as r 
ON g.name = r.name 
GROUP BY year
ORDER BY avg_critic_score DESC 
LIMIT 10; 

--5. Find game critics' ten favorite years, where a year must have more than 4 games released
--in order to be considered. 

SELECT year, ROUND(AVG(critic_score),2) as avg_critic_score, COUNT(g.name) as num_games
FROM game_sales as g
INNER JOIN game_reviews as r 
ON g.name = r.name 
GROUP BY year
HAVING COUNT(g.name) > 4
ORDER BY avg_critic_score DESC 
LIMIT 10; 

--6. Looking at the years that dropped off the critics' favorite list. (They were on the
--first critics' favorite list but not the second). 

WITH top_critic_years AS(
	SELECT year, ROUND(AVG(critic_score),2) as avg_critic_score
	FROM game_sales as g
	INNER JOIN game_reviews as r 
	ON g.name = r.name 
	GROUP BY year
	ORDER BY avg_critic_score DESC 
	LIMIT 10),

	top_critic_years_5_games AS (
	SELECT year, ROUND(AVG(critic_score),2) as avg_critic_score, COUNT(g.name) as num_games
	FROM game_sales as g
	INNER JOIN game_reviews as r 
	ON g.name = r.name 
	GROUP BY year
	HAVING COUNT(g.name) > 4
	ORDER BY avg_critic_score DESC 
	LIMIT 10) 

SELECT year, avg_critic_score
FROM top_critic_years 

EXCEPT 

SELECT year, avg_critic_score 
FROM top_critic_years_5_games

ORDER BY avg_critic_score DESC

--7. Looking at the years that are present on both critics' lists. 

WITH top_critic_years AS(
	SELECT year, ROUND(AVG(critic_score),2) as avg_critic_score
	FROM game_sales as g
	INNER JOIN game_reviews as r 
	ON g.name = r.name 
	GROUP BY year
	ORDER BY avg_critic_score DESC 
	LIMIT 10),

	top_critic_years_5_games AS (
	SELECT year, ROUND(AVG(critic_score),2) as avg_critic_score, COUNT(g.name) as num_games
	FROM game_sales as g
	INNER JOIN game_reviews as r 
	ON g.name = r.name 
	GROUP BY year
	HAVING COUNT(g.name) > 4
	ORDER BY avg_critic_score DESC 
	LIMIT 10) 

SELECT year
FROM top_critic_years 

INTERSECT 

SELECT year
FROM top_critic_years_5_games

--8. Looking at the 10 highest average_user_score values. 

SELECT year, ROUND(AVG(user_score),2) as avg_user_score, COUNT(g.name) as num_games
FROM game_sales as g
INNER JOIN game_reviews as r 
ON g.name = r.name 
GROUP BY year
HAVING COUNT(g.name) > 4
ORDER BY avg_user_score DESC 
LIMIT 10;

--9. Looking at years that appeared on both the critics' favorites list and users' favorites list
--where there need to be more than 4 games released per year. 

WITH top_critic_years_5_games AS (
	SELECT year, ROUND(AVG(critic_score),2) as avg_critic_score, COUNT(g.name) as num_games
	FROM game_sales as g
	INNER JOIN game_reviews as r 
	ON g.name = r.name 
	GROUP BY year
	HAVING COUNT(g.name) > 4
	ORDER BY avg_critic_score DESC 
	LIMIT 10), 
	
	top_user_years_5_games AS(
	SELECT year, ROUND(AVG(user_score),2) as avg_user_score, COUNT(g.name) as num_games
	FROM game_sales as g
	INNER JOIN game_reviews as r 
	ON g.name = r.name 
	GROUP BY year
	HAVING COUNT(g.name) > 4
	ORDER BY avg_user_score DESC 
	LIMIT 10)

SELECT year
FROM top_critic_years_5_games

INTERSECT 

SELECT year 
FROM top_user_years_5_games

--10. Looking at sales in the best video game years.

WITH top_critic_years_5_games AS (
	SELECT year, ROUND(AVG(critic_score),2) as avg_critic_score, COUNT(g.name) as num_games
	FROM game_sales as g
	INNER JOIN game_reviews as r 
	ON g.name = r.name 
	GROUP BY year
	HAVING COUNT(g.name) > 4
	ORDER BY avg_critic_score DESC 
	LIMIT 10), 
	
	top_user_years_5_games AS(
	SELECT year, ROUND(AVG(user_score),2) as avg_user_score, COUNT(g.name) as num_games
	FROM game_sales as g
	INNER JOIN game_reviews as r 
	ON g.name = r.name 
	GROUP BY year
	HAVING COUNT(g.name) > 4
	ORDER BY avg_user_score DESC 
	LIMIT 10)

SELECT year, SUM(total_shipped) as total_games_sold
FROM game_sales
WHERE year IN(
    SELECT year
    FROM top_critic_years_5_games
    
    INTERSECT 
    
    SELECT year
    FROM top_user_years_5_games)
GROUP BY year
ORDER BY total_games_sold DESC; 

--11. Best selling games (total)

SELECT g.name, g.platform, g.publisher, r.critic_score, r.user_score, g.total_shipped
FROM game_sales as g
RIGHT JOIN game_reviews as r
ON g.name = r.name 
ORDER BY total_shipped DESC NULLS LAST

	