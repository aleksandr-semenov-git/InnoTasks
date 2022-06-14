-- 1
SELECT COUNT(film_id) AS film_count, category_id
FROM film_category
GROUP BY category_id
ORDER BY category_id DESC;
-- 2
SELECT film_actor.actor_id, actor.first_name, actor.last_name, SUM(rental_duration) as rental_dur
FROM film_actor, film, actor
WHERE film_actor.film_id = film.film_id
AND film_actor.actor_id = actor.actor_id
GROUP BY film_actor.actor_id, actor.first_name, actor.last_name
ORDER BY rental_dur DESC
LIMIT 10;
-- 3
SELECT c.name, SUM(p.amount) as summ
FROM rental r, payment p, film_category fc, inventory i, category c
WHERE r.rental_id = p.rental_id
AND i.inventory_id = r.inventory_id
AND i.film_id = fc.film_id
AND fc.category_id = c.category_id
GROUP BY fc.category_id, c.name
ORDER BY summ DESC
LIMIT 1;
-- 4
SELECT f.title
FROM film as f
LEFT JOIN inventory as i
USING (film_id)
EXCEPT
SELECT f.title
FROM film as f
INNER JOIN inventory as i
USING (film_id);
-- 5
CREATE VIEW child_act AS
SELECT fa.actor_id, COUNT(*) cnt
FROM film f, film_category fc, category c, film_actor fa
WHERE fc.category_id = c.category_id
AND fc.film_id = f.film_id
AND fa.film_id = f.film_id
AND c.name = 'Children';

CREATE VIEW child_act_dns AS
SELECT actor_id, cnt, DENSE_RANK() OVER(ORDER BY cnt DESC) dns
FROM child_act;

SELECT a.actor_id, a.first_name, a.last_name, cnt FROM child_act_dns
INNER JOIN actor as a USING (actor_id)
WHERE dns < 4
ORDER BY cnt DESC;
-- 6
SELECT cit.city, cus.active, COUNT(*) cnt
FROM (SELECT *
FROM city c
INNER JOIN address ad
USING (city_id)) AS cit
INNER JOIN customer cus
USING (address_id)
GROUP BY cit.city, cus.active
ORDER BY cus.active ASC, cnt DESC;
-- 7

CREATE VIEW a_cities AS
SELECT * FROM city WHERE city.city LIKE 'A%';

CREATE VIEW hyphen_cities AS
SELECT * FROM city WHERE city.city LIKE '%\-%';

CREATE VIEW rent_time_a AS
SELECT r.rental_id, r.inventory_id, a_cities.city,
EXTRACT(EPOCH FROM(r.return_date - r.rental_date)) as renttime
FROM a_cities, address ad, customer cus, rental r
WHERE a_cities.city_id = ad.city_id
AND ad.address_id = cus.address_id
AND cus.customer_id = r.customer_id;

CREATE VIEW rent_time_h AS
SELECT r.rental_id, r.inventory_id, hyphen_cities.city,
EXTRACT(EPOCH FROM(r.return_date - r.rental_date)) as renttime
FROM hyphen_cities, address ad, customer cus, rental r
WHERE hyphen_cities.city_id = ad.city_id
AND ad.address_id = cus.address_id
AND cus.customer_id = r.customer_id;
-- Category with max hours among A-cities
SELECT c.name, (ROUND(SUM(rt.renttime) / 3600), 0) hours
FROM rent_time_a rt, inventory inv, film_category fc, category c
WHERE rt.inventory_id = inv.inventory_id
AND inv.film_id = fc.film_id
AND fc.category_id = c.category_id
GROUP BY c.name
ORDER BY hours DESC
LIMIT 1;
-- Category with max hourse among cities with hyphen 
SELECT c.name, (ROUND(SUM(rt.renttime) / 3600), 0) hours
FROM rent_time_h rt, inventory inv, film_category fc, category c
WHERE rt.inventory_id = inv.inventory_id
AND inv.film_id = fc.film_id
AND fc.category_id = c.category_id
GROUP BY c.name
ORDER BY hours DESC
LIMIT 1;
