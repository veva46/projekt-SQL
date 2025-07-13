-- projekt DA SQL Engeto
-- Věra Vavrincová
-- úkol 5

--Má výška HDP vliv na změny ve mzdách a cenách potravin? 
--Neboli, pokud HDP vzroste výrazněji v jednom roce, projeví se to na cenách 
--potravin či mzdách ve stejném nebo následujícím roce výraznějším růstem?


--Sekundární tabulka

--CREATE TABLE t_vera_vavrincova_project_SQL_secondary_final AS  --(takto byla vytvořena sekundární tabulka)
/*SELECT 
    country,
    year,
    population,
    gini,
    gdp,
    TvvPr.rokm,
    TvvPr.kvartalm,
    TvvPr.prumer_mzda,
    TvvPr.odvetvi,
    TvvPr.rokp,
    TvvPr.kvartalp,
    TvvPr.prumer_cena_potr,
    TvvPr.category_code,
    TvvPr.potravina,
    TvvPr.jednotka
FROM economies e 
   JOIN t_vera_vavrincova_project_sql_primary_final TvvPr
      ON e.year = TvvPr.rokm
      WHERE TvvPr.kvartalM = TvvPr.kvartalP 
      AND TvvPr.rokM = TvvPr.rokP
      AND e.country LIKE '%Czech%'   --pro Českou republiku
   ORDER BY TvvPr.rokm, TvvPr.kvartalm, country, odvetvi, potravina, TvvPr.prumer_cena_potr   
;      
*/

 

WITH               -- porovnání meziročních nárustů cen jednotlivých potravin, mezd a HDP
prumeryPOTR AS ( 
  SELECT   -- meziroční růst cen potravin
     EXTRACT(YEAR FROM cp.date_from::DATE) AS rokP,
     cp.category_code AS kategorie,
     cpc.name AS nazev,
     ROUND(AVG(cp.value)) AS prumerna_cena    
  FROM czechia_price cp
    JOIN czechia_price_category cpc
       ON cp.category_code = cpc.code
    GROUP BY cp.category_code, cpc.name, rokP
    ORDER BY name ASC
  ),
srovnaniPOTR AS (
  SELECT 
    prumeryPOTR.rokP,
    prumeryPOTR.kategorie,
    prumeryPOTR.nazev,
    prumeryPOTR.prumerna_cena,
    LAG (prumerna_cena) OVER (PARTITION BY kategorie 
      ORDER BY rokP) AS predchozi_cena
  FROM prumeryPOTR   
  ),
mezirustPOTR AS (
  SELECT 
    srovnaniPOTR.rokP,
    srovnaniPOTR.kategorie,
    srovnaniPOTR.nazev,
    srovnaniPOTR.prumerna_cena,
    srovnaniPOTR.predchozi_cena, 
    CASE 
   	  WHEN (prumerna_cena - predchozi_cena) < 0 THEN 'zlevněno'
   	  WHEN (prumerna_cena - predchozi_cena) > 0 THEN 'zdraženo'
      WHEN (prumerna_cena - predchozi_cena) = 0 THEN 'stejná cena'        
      ELSE 'nesrovnatelné s předchozím rokem'
    END AS zmena_ceny
   FROM srovnaniPOTR
),
procentaPOTR AS (
    SELECT 
      mezirustPOTR.rokP,
      mezirustPOTR.kategorie,
      mezirustPOTR.nazev,
      mezirustPOTR.prumerna_cena,
      mezirustPOTR.predchozi_cena,
      mezirustPOTR.zmena_ceny,
	  ROUND(100*((prumerna_cena - predchozi_cena)/predchozi_cena)) AS narust_ceny_procenta
   FROM mezirustPOTR
),
prumerPOTR AS (
     SELECT   
       procentaPOTR.rokP,
       procentaPOTR.kategorie,
       procentaPOTR.nazev,
       procentaPOTR.prumerna_cena,
       procentaPOTR.predchozi_cena,
       procentaPOTR.zmena_ceny, 
       AVG(procentaPOTR.narust_ceny_procenta) AS prumer_rustu
     FROM procentaPOTR 
        GROUP BY kategorie, nazev, rokP, prumerna_cena, predchozi_cena, zmena_ceny 
        ORDER BY rokP, kategorie
  ),
prumeryMZDY AS (   -- meziroční růst průmerné mzdy
  SELECT   
     payroll_year AS rokM,
     ROUND(AVG(cp2.value)) AS prumerna_mzda    
  FROM czechia_payroll cp2
    JOIN czechia_payroll_value_type cpvt
       ON cp2.value_type_code = cpvt.code
    GROUP BY rokM
    ORDER BY rokM ASC
 ),
srovnaniMZDY AS (
  SELECT 
    prumeryMZDY.rokM,
    prumeryMZDY.prumerna_mzda,
    LAG(prumerna_mzda) OVER (ORDER BY rokM) AS predchozi_mzda
  FROM prumeryMZDY   
 ),
mezirustMZDY AS (
  SELECT 
    srovnaniMZDY.rokM,
    srovnaniMZDY.prumerna_mzda,
    srovnaniMZDY.predchozi_mzda, 
    CASE 
   	  WHEN (prumerna_mzda - predchozi_mzda) < 0 THEN 'snížena'
   	  WHEN (prumerna_mzda - predchozi_mzda) > 0 THEN 'zvýšena'
      WHEN (prumerna_mzda - predchozi_mzda) = 0 THEN 'stejná'        
      ELSE 'nesrovnatelné s předchozím rokem'
      END AS zmena_mzdy
   FROM srovnaniMZDY
),
procentaMZDY AS (
    SELECT 
      mezirustMZDY.rokM AS rokM,
      mezirustMZDY.prumerna_mzda,
      mezirustMZDY.predchozi_mzda,
      mezirustMZDY.zmena_mzdy,
	  ROUND(100*((prumerna_mzda - predchozi_mzda)/predchozi_mzda)) AS narust_mzdy_proc
   FROM mezirustMZDY
),
HDP AS (     -- meziroční porovnání HDP
     SELECT 
         country,
         year,
         population,
         gdp,
         LAG (gdp) OVER (PARTITION BY country ORDER BY year) AS predchozi_rok_gdp
     FROM economies e 
 )
SELECT 
   HDP.country,
   HDP.year,
   ROUND(100*((HDP.gdp - HDP.predchozi_rok_gdp)/HDP.predchozi_rok_gdp)) AS narust_hdp_proc,
   procentaMZDY.narust_mzdy_proc,
   prumerPOTR.prumer_rustu AS rust_cen_POTR_proc,
   prumerPOTR.rokP,
   prumerPOTR.nazev AS nazev_potraviny,
   (prumerPOTR.prumer_rustu - procentaMZDY.narust_mzdy_proc) AS rozdil_cena_mzda_proc,
   prumerPOTR.zmena_ceny,
   HDP.gdp,
   HDP.predchozi_rok_gdp,
   CASE 
	 WHEN (predchozi_rok_gdp < gdp) THEN 'HDP zvýšeno'
	 WHEN (predchozi_rok_gdp > gdp) THEN 'HDP sníženo'
       ELSE 'HDP stejné'
   END AS zmena_HDP,
   procentaMZDY.rokM AS rokM,
   procentaMZDY.prumerna_mzda,
   procentaMZDY.predchozi_mzda,
   procentaMZDY.zmena_mzdy,
   HDP.population
FROM HDP
  JOIN prumerPOTR
     ON HDP.YEAR = prumerPOTR.rokP
  JOIN procentaMZDY 
     ON  HDP.YEAR = procentaMZDY.rokM
  WHERE HDP.country = 'Czech Republic'        -- uvažuji jen ČR
    AND HDP.YEAR BETWEEN 2006 AND 2018        -- období pro porovnání cen potravin a mezd - viz.úkoly 1-4
    AND procentaMZDY.predchozi_mzda IS NOT NULL
    AND prumerPOTR.predchozi_cena IS NOT NULL -- nesrovnávám první roky bez předchozího roku
  ORDER BY HDP.year ASC;                                      
 
                

-- zprůměrování cen všech potravin za rok - jako zdroj použita sekundární tabulka
-- a porovnání meziročních nárustů cen potravin a mezd a HDP
WITH               
prumerPOTR AS (               
  SELECT   -- meziroční růst cen potravin
     EXTRACT(YEAR FROM cp.date_from::DATE) AS rokP,
     ROUND(AVG(cp.value)) AS prumerna_cena    
  FROM czechia_price cp
    GROUP BY rokP
    ORDER BY rokP ASC
  ),
srovnaniPOTR AS (
  SELECT 
    prumerPOTR.rokP,
    prumerPOTR.prumerna_cena,
    LAG (prumerna_cena) OVER (ORDER BY rokP) AS predchozi_cena
  FROM prumerPOTR   
  ),
mezirustPOTR AS (
  SELECT 
    srovnaniPOTR.rokP,
    srovnaniPOTR.prumerna_cena,
    srovnaniPOTR.predchozi_cena, 
    CASE 
   	  WHEN (prumerna_cena - predchozi_cena) < 0 THEN 'zlevněno'
   	  WHEN (prumerna_cena - predchozi_cena) > 0 THEN 'zdraženo'
      WHEN (prumerna_cena - predchozi_cena) = 0 THEN 'stejná cena'        
      ELSE 'nesrovnatelné s předchozím rokem'
    END AS zmena_ceny
   FROM srovnaniPOTR
),
procentaPOTR AS (
    SELECT 
      mezirustPOTR.rokP,
      mezirustPOTR.prumerna_cena,
      mezirustPOTR.predchozi_cena,
      mezirustPOTR.zmena_ceny,
	  ROUND(100*((prumerna_cena - predchozi_cena)/predchozi_cena)) AS narust_ceny_procenta
   FROM mezirustPOTR
),
prumPOTR AS (
     SELECT   
       procentaPOTR.rokP,
       procentaPOTR.prumerna_cena,
       procentaPOTR.predchozi_cena,
       procentaPOTR.zmena_ceny, 
       AVG(procentaPOTR.narust_ceny_procenta) AS prumer_rustu
     FROM procentaPOTR 
        GROUP BY rokP, prumerna_cena, predchozi_cena, zmena_ceny 
        ORDER BY rokP
),
prumeryMZDY AS (   -- meziroční nárůst průmerné mzdy
  SELECT   
     payroll_year AS rokM,
     ROUND(AVG(cp2.value)) AS prumerna_mzda    
  FROM czechia_payroll cp2
    JOIN czechia_payroll_value_type cpvt
       ON cp2.value_type_code = cpvt.code
    GROUP BY rokM
    ORDER BY rokM ASC
 ),
srovnaniMZDY AS (
  SELECT 
    prumeryMZDY.rokM,
    prumeryMZDY.prumerna_mzda,
    LAG(prumerna_mzda) OVER (ORDER BY rokM) AS predchozi_mzda
  FROM prumeryMZDY   
 ),
mezirustMZDY AS (
  SELECT 
    srovnaniMZDY.rokM,
    srovnaniMZDY.prumerna_mzda,
    srovnaniMZDY.predchozi_mzda, 
    CASE 
   	  WHEN (prumerna_mzda - predchozi_mzda) < 0 THEN 'snížena'
   	  WHEN (prumerna_mzda - predchozi_mzda) > 0 THEN 'zvýšena'
      WHEN (prumerna_mzda - predchozi_mzda) = 0 THEN 'stejná'        
      ELSE 'nesrovnatelné s předchozím rokem'
      END AS zmena_mzdy
   FROM srovnaniMZDY
),
procentaMZDY AS (
    SELECT 
      mezirustMZDY.rokM AS rokM,
      mezirustMZDY.prumerna_mzda,
      mezirustMZDY.predchozi_mzda,
      mezirustMZDY.zmena_mzdy,
	  ROUND(100*((prumerna_mzda - predchozi_mzda)/predchozi_mzda)) AS narust_mzdy_proc
   FROM mezirustMZDY
),
HDP AS (     -- meziroční porovnání HDP
     SELECT 
         country,
         year,
         population,
         gdp,
         LAG (gdp) OVER (PARTITION BY country ORDER BY year) AS predchozi_rok_gdp
     FROM economies e 
 )
SELECT 
   HDP.year,
   ROUND(100*((HDP.gdp - HDP.predchozi_rok_gdp)/HDP.predchozi_rok_gdp)) AS narust_hdp_proc,
   procentaMZDY.narust_mzdy_proc,
   prumPOTR.prumer_rustu AS rust_cen_POTR_proc,
   prumPOTR.prumerna_cena,
   prumPOTR.predchozi_cena,
   prumPOTR.zmena_ceny,
   HDP.gdp,
   HDP.predchozi_rok_gdp,
   CASE 
	 WHEN (predchozi_rok_gdp < gdp) THEN 'HDP zvýšeno'
	 WHEN (predchozi_rok_gdp > gdp) THEN 'HDP sníženo'
       ELSE 'HDP stejné'
   END AS zmena_HDP,
   procentaMZDY.prumerna_mzda,
   procentaMZDY.predchozi_mzda,
   procentaMZDY.zmena_mzdy,
   (prumPOTR.prumer_rustu - procentaMZDY.narust_mzdy_proc) AS rozdil_cena_mzda_proc,
   HDP.country
FROM HDP
  JOIN prumPOTR
     ON HDP.YEAR = prumPOTR.rokP
  JOIN procentaMZDY 
     ON HDP.YEAR = procentaMZDY.rokM
  WHERE HDP.country = 'Czech Republic'             --ČR
    AND HDP.YEAR BETWEEN 2006 AND 2018  -- období pro porovnání cen potravin a mezd - viz.úkoly 1-4
    AND (prumPOTR.prumer_rustu - procentaMZDY.narust_mzdy_proc) IS NOT NULL 
    AND prumPOTR.predchozi_cena IS NOT NULL      -- první měřený rok nemá předchozí rok
    AND procentaMZDY.predchozi_mzda IS NOT NULL  -- první měřený rok nemá předchozí rok
  ORDER BY HDP.year ASC;                          -- HDP je měřeno již dříve               

  
--Výška HDP má jistý vliv na ceny potravin a mzdy. 
--Při zvyšování HDP se většinou v dalším roce zvýšila průměrná mzda (např.r.2015, 2017). 
--Ceny potravin se zvedly v závislosti na zvýšení HDP již v tom stejném roce (např.2017). 
 
  
WITH predch_HDP AS (
     SELECT                  --HDP v ČR
         country,
         year,
         population,
         gdp,
         LAG (gdp) OVER (PARTITION BY country ORDER BY year) AS predchozi_rok_gdp
     FROM economies e 
 )
SELECT 
   predch_HDP.country,
   predch_HDP.year,
   predch_HDP.gdp,
   predch_HDP.population,
   predch_HDP.predchozi_rok_gdp,
   CASE 
	 WHEN (predchozi_rok_gdp < gdp) THEN 'HDP zvýšeno'
	 WHEN (predchozi_rok_gdp > gdp) THEN 'HDP sníženo'
       ELSE 'HDP stejné'
   END AS zmena_HDP  
FROM predch_HDP
  WHERE predch_HDP.country = 'Czech Republic'  -- uvažuji jen ČR
  AND predch_HDP.predchozi_rok_gdp IS NOT NULL -- první rok nemá předchozí rok
  ORDER BY zmena_hdp, predch_HDP.year
;
-- HDP bylo sníženo v letech 1991,1992,1997,1998,2009,2012,2013,2020, 
--     jinak vždy bylo HDP zvýšeno oproti předchozímu roku. 
--  Podklady/zdrojová data/ jsou z období 1990-2020.


