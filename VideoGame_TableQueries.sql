-- Video Games Data Visualization Project 
-- Queries used for Tableau

--1. What were the top 10 best selling video games during The Golden Age? 

SELECT year, name, total_shipped as games_sold
FROM game_sales 
WHERE year = '1998'
	OR year = '2002'
	OR year = '2008'
ORDER BY total_shipped DESC 
LIMIT 10; 
	
--2. Looking at the most successful platforms during The Golden Age.

SELECT year, platform, SUM(total_shipped) as total_games_sold
FROM game_sales
WHERE year = '1998'
	OR year = '2002'
	OR year = '2008'
GROUP BY year, platform
ORDER BY total_games_sold DESC
LIMIT 10; 

--3. Looking at platforms users loved.

SELECT g.platform, ROUND(AVG(r.user_score),2) as avg_user_score
FROM game_sales as g
INNER JOIN game_reviews as r 
ON g.name = r.name
GROUP BY g.platform
ORDER BY avg_user_score DESC NULLS LAST
LIMIT 10; 

--4. Users' favorite games during 1998, 2002, 2008.

SELECT g.year, g.name, r.user_score, g.total_shipped as games_sold
FROM game_sales as g
INNER JOIN game_reviews as r
ON g.name = r.name 
WHERE year = '1998'
	OR year = '2002'
	OR year = '2008'
ORDER BY r.user_score DESC NULLS LAST
LIMIT 10; 

--5. Looking at sales during the years both critics and users loved.

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
	
--6. Platform Performance according to critics.
SELECT g.platform, SUM(g.total_shipped) as total_sales, ROUND(AVG(r.critic_score),2) as avg_critic_score
FROM game_sales as g
INNER JOIN game_reviews as r
ON g.name = r.name 
WHERE g.year IN ('1998', '2002', '2008')
GROUP BY platform
ORDER BY avg_critic_score DESC NULLS LAST

--7. Game Performance according to critics.
SELECT g.name, SUM(g.total_shipped) as total_sales, ROUND(AVG(r.critic_score),2) as avg_critic_score
FROM game_sales as g
INNER JOIN game_reviews as r
ON g.name = r.name 
WHERE g.year IN ('1998', '2002', '2008')
GROUP BY g.name
ORDER BY avg_critic_score DESC NULLS LAST
LIMIT 20;




