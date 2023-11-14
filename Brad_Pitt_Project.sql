--Brad Pitt Data Exploration/Data Visualization Project 
--Sasha Aibara

SELECT * 
FROM brad_pitt; 

--GENERAL BACKGROUND ON FILMS 

--1. How many theatrical films has Brad Pitt appeared in? 

SELECT COUNT(movie_name)
FROM brad_pitt;

--2. How many different genres has he done roles for? What genre has he done
-- the most number of films for? 

SELECT COUNT(DISTINCT genre)
FROM brad_pitt; 

SELECT genre, COUNT(genre)
FROM brad_pitt
GROUP BY genre
ORDER BY COUNT(genre) DESC;

--3. What type of roles has Pitt appeared in? 

SELECT role, COUNT(role)
FROM brad_pitt
GROUP BY role 
ORDER BY COUNT(role) desc; 

--4. How many directors has he worked with? Has he worked with the same director 
-- more than once? 

SELECT director, COUNT(director)
FROM brad_pitt
GROUP BY director
ORDER BY COUNT(director) desc;

--5. What are the majority of his films rated? 

SELECT mpaa_rating, COUNT(mpaa_rating)
FROM brad_pitt
GROUP BY mpaa_rating
ORDER BY COUNT(mpaa_rating) DESC; 

--6. Which movies has he had a lead role in? 

SELECT movie_name
FROM brad_pitt 
WHERE role = 'lead'; 

--7. What are the critic and audience ratings for each film where he was a lead? Order 
--films from highest to lowest ratings. 

SELECT movie_name, meta_score
FROM brad_pitt 
WHERE role = 'lead' AND meta_score IS NOT NULL
ORDER BY meta_score DESC; 

SELECT movie_name, tomato_score
FROM brad_pitt 
WHERE role = 'lead' AND tomato_score IS NOT NULL 
ORDER BY tomato_score DESC; 

SELECT movie_name, audience_score
FROM brad_pitt 
WHERE role = 'lead' AND audience_score IS NOT NULL 
ORDER BY audience_score DESC; 

SELECT movie_name, genre, role, 
	meta_score, tomato_score, audience_score 
FROM brad_pitt;

--FILM BOX OFFICES

--8. Show each film and the total profit made, as well as the director, role, and genre of the film.
SELECT b1.movie_name, b2.release_year, b2.director, b2.role, b2.genre, 
	CASE 
		WHEN b1.wldwide_box IS NULL THEN b1.domestic_box
		ELSE b1.wldwide_box 
	END as total_profit
FROM bradpitt_boxoffice as b1
LEFT JOIN brad_pitt as b2
	ON b1.film_id = b2.film_id 
WHERE b1.domestic_box IS NOT NULL
ORDER BY total_profit DESC NULLS LAST; 

--9. Did films that did well domestically do well internationally? 

SELECT movie_name, domestic_box, intl_box
FROM bradpitt_boxoffice 
WHERE domestic_box IS NOT NULL 
	AND intl_box IS NOT NULL;
	
--10. Which genres had the highest domestic box office? (For Tableau)

SELECT b1.movie_name, b2.genre, b1.domestic_box
FROM bradpitt_boxoffice as b1 
INNER JOIN brad_pitt as b2 
	ON b1.film_id = b2.film_id 
WHERE b1.domestic_box IS NOT NULL; 

--11. Do critic ratings correlate with box office success? (For Tableau)

SELECT b1.movie_name, b2.meta_score, b2.tomato_score, b1.domestic_box
FROM bradpitt_boxoffice as b1 
INNER JOIN brad_pitt as b2 
	ON b1.film_id = b2.film_id 
WHERE b1.domestic_box IS NOT NULL; 

--12.Do audience ratings correlate with box office success? (For Tableau)

SELECT b1.movie_name, b2.audience_score, b1.domestic_box
FROM bradpitt_boxoffice as b1 
INNER JOIN brad_pitt as b2 
	ON b1.film_id = b2.film_id 
WHERE b1.domestic_box IS NOT NULL;

--13. Directors & Box Office Success (For Tableau)

SELECT b1.movie_name, b2.director, b1.domestic_box
FROM bradpitt_boxoffice as b1 
INNER JOIN brad_pitt as b2 
	ON b1.film_id = b2.film_id 
WHERE b1.domestic_box IS NOT NULL;

--FILM AWARDS AND RECOGNITION 

--14. How many total wins vs. nominations are there for his films? 

SELECT result, COUNT(result)
FROM bradpitt_awards
GROUP BY result; 

--15. Which of his films have won awards? 

SELECT movie_name, COUNT(film_id)
FROM bradpitt_awards
WHERE result = 'won'
GROUP BY movie_name 
ORDER BY COUNT(film_id) DESC; 

--16. Which awards did these 7 films receive? (For Tableau)

SELECT movie_name, award, category
FROM bradpitt_awards
WHERE result = 'won'
ORDER BY movie_name;

--17. Which awards did Brad Pitt receive (For Tableau)

SELECT movie_name, award, category 
FROM bradpitt_awards
WHERE category LIKE '%Actor%' 
	AND result = 'won'
ORDER BY movie_name; 

--18. Show the role, the director and the genre of these movies. 

WITH brad_awards as(
	SELECT film_id, movie_name, award, category 
	FROM bradpitt_awards
	WHERE category LIKE '%Actor%'
		AND result = 'won'
	ORDER BY movie_name)

SELECT b1.movie_name, b2.genre, b2.role, b2.director, 
	b1.award, b1.category
FROM brad_awards as b1 
INNER JOIN brad_pitt as b2 
	ON b1.film_id = b2.film_id;
	
--19. Audience Ratings & Box Office of these 7 films? 

SELECT movie_name, meta_score, tomato_score, audience_score
FROM brad_pitt
WHERE movie_name IN(
	SELECT DISTINCT movie_name
	FROM bradpitt_awards
	WHERE result = 'won' 
	ORDER BY movie_name);

SELECT movie_name, domestic_box
FROM bradpitt_boxoffice
WHERE movie_name IN(
	SELECT DISTINCT movie_name
	FROM bradpitt_awards
	WHERE result = 'won' 
	ORDER BY movie_name);


SELECT * 
FROM bradpitt_awards












