-- projekt DA SQL Engeto
-- Věra Vavrincová
-- Dodatečná tabulka pro ostatní evropské státy

--Jako dodatečný materiál připravte i tabulku s HDP, GINI koeficientem 
--a populací dalších evropských států ve stejném období, jako primární přehled pro ČR.

--analýza z tabulek Engeta:

-- přehled HDP, Gini, populace pro evropské státy
WITH predch_HDP AS (   
     SELECT              -- HDP a populace pro předchozí rok
         country,
         year,
         population,
         gini,
         gdp,
         LAG (gdp) OVER (PARTITION BY country ORDER BY year) AS predchozi_rok_gdp,
         LAG (population) OVER (PARTITION BY country ORDER BY year) AS predchozi_rok_population
     FROM economies e 
 )
SELECT 
   predch_HDP.year,
   predch_HDP.country,
   predch_HDP.gdp,
   predch_HDP.predchozi_rok_gdp,
   CASE 
	 WHEN (predch_HDP.predchozi_rok_gdp < predch_HDP.gdp) THEN 'HDP zvýšeno'
	 WHEN (predch_HDP.predchozi_rok_gdp > predch_HDP.gdp) THEN 'HDP sníženo'
     ELSE 'HDP stejné'
   END AS zmena_HDP,
   predch_HDP.gini,
   predch_HDP.population,
   predch_HDP.predchozi_rok_population,
   CASE 
	 WHEN (predch_HDP.predchozi_rok_population < predch_HDP.population) THEN 'populace zvýšena'
	 WHEN (predch_HDP.predchozi_rok_population > predch_HDP.population) THEN 'populace snížena'
     ELSE 'populace stejná'
   END AS zmena_population
FROM predch_HDP  
  WHERE predch_HDP.country IN ('France','Italy','Germany','Czech Republic','Slovakia','European Union')      -- uvažuji jen státy Evropy EU
     AND predch_HDP.predchozi_rok_gdp IS NOT NULL   -- první rok nemá předchozí rok
     AND predch_HDP.YEAR BETWEEN 2006 AND 2018  -- období pro porovnání cen potravin a mezd - viz.úkoly 1-4
     ORDER BY predch_HDP.YEAR ASC, predch_HDP.gdp, predch_HDP.country DESC
;

--analýza ze sekukundární tabulky:
WITH 
prumerceny_P_rok AS (
     SELECT  
         ROUND(AVG(TS.prumer_cena_potr)) AS prumer_cenyPOTR, --průměr ceny potravin za rok
         TS.category_code,
         TS.rokp,
         TS.kvartalP
     FROM t_vera_vavrincova_project_SQL_secondary_final TS 
        GROUP BY TS.rokp, TS.kvartalP, TS.category_code
   ),
predch_HDP AS (   
     SELECT              -- HDP a populace pro předchozí rok
         TS.country,
         TS.year,
         TS.population,
         TS.gini,
         TS.gdp,
         LAG (TS.gdp) OVER (PARTITION BY TS.country ORDER BY TS.year) AS predchozi_rok_gdp,
         LAG (TS.population) OVER (PARTITION BY TS.country ORDER BY TS.year) AS predchozi_rok_population,
         TS.category_code AS kod_potr
     FROM t_vera_vavrincova_project_SQL_secondary_final TS 
   )
SELECT                
   predch_HDP.year,
   predch_HDP.country,
   predch_HDP.gdp,
   predch_HDP.predchozi_rok_gdp,
      CASE 
	 WHEN (predch_HDP.predchozi_rok_gdp < predch_HDP.gdp) THEN 'HDP zvýšeno'
	 WHEN (predch_HDP.predchozi_rok_gdp > predch_HDP.gdp) THEN 'HDP sníženo'
     ELSE 'HDP stejné'
   END AS zmena_HDP,
   predch_HDP.gini,
   predch_HDP.kod_potr,
   prumerceny_P_rok.prumer_cenyPOTR,
   predch_HDP.population,
   predch_HDP.predchozi_rok_population,
   CASE 
	 WHEN (predch_HDP.predchozi_rok_population < predch_HDP.population) THEN 'populace zvýšena'
	 WHEN (predch_HDP.predchozi_rok_population > predch_HDP.population) THEN 'populace snížena'
     ELSE 'populace stejná'
   END AS zmena_population
FROM predch_HDP 
  LEFT JOIN prumerceny_P_rok
     ON predch_HDP.YEAR = prumerceny_P_rok.rokp
  WHERE predch_HDP.country IN ('France','Italy','Czech Republic')--,'Slovakia','Germany')      
      AND predch_HDP.predchozi_rok_gdp I(S NOT NULL   -- první rok nemá předchozí rok
     AND predch_HDP.YEAR BETWEEN 2006 AND 2018  -- období pro porovnání cen potravin a mezd - viz.úkoly 1-4
  ORDER BY predch_HDP.YEAR ASC, predch_HDP.gdp, predch_HDP.country DESC
; 
  --v sekundární tabulce jsou řádky pro všechny potraviny a všechna měřená období
  --můj ntb zvládne vyčíslit pouze 3 státy, pak se předpokládám přeplní RAM,
  --takže uvažuji jen 3 státy Evropy 'France','Italy','Czech Republic'