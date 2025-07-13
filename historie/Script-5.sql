-- projekt DA SQL Engeto
-- Věra Vavrincová
-- úkol 5

--Má výška HDP vliv na změny ve mzdách a cenách potravin? 
--Neboli, pokud HDP vzroste výrazněji v jednom roce, projeví se to na cenách 
--potravin či mzdách ve stejném nebo následujícím roce výraznějším růstem?

--HDP (Hrubý domácí produkt (GDP)) je celková peněžní hodnota všech statků a služeb, které se 
      --za určité období (většinou rok) vyprodukují v dané zemi.
      --vyšší HDP → často vyšší mzdy i mírný růst cen.
--GINI Giniho koeficient (index) 
      --číslo, které ukazuje nerovnost v příjmech nebo majetku v určité společnosti nebo zemi.
      --pohybuje se mezi 0 a 1 : 0-všichni mají stejně, 1-jeden má všechno, ostatní nic (udává se v %)
--population v tab. economies - je počet lidí v dané zemi



WITH predch_HDP AS (
     SELECT 
         country,
         year,
         gdp,
         LAG (gdp) OVER (PARTITION BY country ORDER BY year) AS predchozi_rok
     FROM economies e 
        WHERE country = 'Central Europe and the Baltics'  -- uvažuji jen Střední Evropu
 )
SELECT 
   predch_HDP.country,
   predch_HDP.year,
   predch_HDP.gdp,
   predch_HDP.predchozi_rok,
   CASE 
	 WHEN (predchozi_rok < gdp) THEN 'HDP zvýšeno'
	 WHEN (predchozi_rok > gdp) THEN 'HDP sníženo'
       ELSE 'HDP stejné'
   END AS zmena_HDP  
FROM predch_HDP
WHERE predch_HDP.country = 'Central Europe and the Baltics'
  AND predch_HDP.gdp IS NOT NULL
  AND predch_HDP.YEAR BETWEEN 2005 AND 2018
ORDER BY predch_HDP.YEAR
;