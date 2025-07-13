-- projekt DA SQL Engeto
-- Věra Vavrincová
-- úkol 4

--Existuje rok, ve kterém byl meziroční nárůst cen potravin výrazně vyšší 
      --než růst mezd (větší než 10 %)?

--použiji skript z úkolu č.3 a dopracuji ho pro tento 4.úkol


--analýza z tabulek Engeta:

WITH    -- meziroční nárust cen potravin
prumery_potr AS (
  SELECT   -- průměrné ceny potravin v letech
     EXTRACT(YEAR FROM cp.date_from::DATE) AS rok,
     cp.category_code AS kategorie,
     cpc.name AS nazev,
     ROUND(AVG(cp.value)) AS prumerna_cena    
  FROM czechia_price cp
    JOIN czechia_price_category cpc
       ON cp.category_code = cpc.code
    GROUP BY cp.category_code, cpc.name, rok
    ORDER BY name ASC
  ),
srovnani_potr AS (
  SELECT 
    prumery_potr.rok,
    prumery_potr.kategorie,
    prumery_potr.nazev,
    prumery_potr.prumerna_cena,
    LAG (prumerna_cena) OVER (PARTITION BY kategorie 
      ORDER BY rok) AS predchozi_cena
  FROM prumery_potr   
  ),
mezirust_potr AS (
  SELECT 
    srovnani_potr.rok,
    srovnani_potr.kategorie,
    srovnani_potr.nazev,
    srovnani_potr.prumerna_cena,
    srovnani_potr.predchozi_cena, 
    CASE 
   	  WHEN (prumerna_cena - predchozi_cena) < 0 THEN 'zlevněno'
   	  WHEN (prumerna_cena - predchozi_cena) > 0 THEN 'zdraženo'
      WHEN (prumerna_cena - predchozi_cena) = 0 THEN 'stejná cena'        
      ELSE 'nesrovnatelné s předchozím rokem'
    END AS zmena_ceny
   FROM srovnani_potr
),
procenta_potr AS (
    SELECT 
      mezirust_potr.rok,
      mezirust_potr.kategorie,
      mezirust_potr.nazev,
      mezirust_potr.prumerna_cena,
      mezirust_potr.predchozi_cena,
      mezirust_potr.zmena_ceny,
	  ROUND(100*((prumerna_cena - predchozi_cena)/predchozi_cena)) AS narust_ceny_procenta
   FROM mezirust_potr
),
prumer_rustu_cen_potr AS (
     SELECT   
       procenta_potr.rok,
       procenta_potr.kategorie,
       procenta_potr.nazev,
       procenta_potr.prumerna_cena,
       procenta_potr.predchozi_cena,
       procenta_potr.zmena_ceny, 
       AVG(procenta_potr.narust_ceny_procenta) AS prumer_rustu
     FROM procenta_potr 
        GROUP BY kategorie, nazev, rok, prumerna_cena, predchozi_cena, zmena_ceny 
        ORDER BY rok, kategorie
  )      
SELECT   
   prumer_rustu_cen_potr.rok,
   prumer_rustu_cen_potr.nazev,
   prumer_rustu_cen_potr.prumerna_cena,
   prumer_rustu_cen_potr.predchozi_cena,
   prumer_rustu_cen_potr.zmena_ceny, 
   prumer_rustu_cen_potr.prumer_rustu
FROM prumer_rustu_cen_potr 
  WHERE predchozi_cena IS NOT NULL   
    AND zmena_ceny = 'zdraženo'    -- uvažuji jen zdražení potravin      
  ORDER BY prumer_rustu DESC;              
-- meziroční růst cen potravin 			



WITH     -- meziroční nárůst průmerné mzdy
prumery_mzdy AS (
  SELECT   -- průměrné mzdy v letech
     payroll_year AS rok,
     ROUND(AVG(cp2.value)) AS prumerna_mzda    
  FROM czechia_payroll cp2
    JOIN czechia_payroll_value_type cpvt
       ON cp2.value_type_code = cpvt.code
    GROUP BY rok
    ORDER BY rok ASC
 ),
srovnani_mzdy AS (
  SELECT 
    prumery_mzdy.rok,
    prumery_mzdy.prumerna_mzda,
    LAG(prumerna_mzda) OVER (ORDER BY rok) AS predchozi_mzda
  FROM prumery_mzdy   
 ),
mezirust_mzdy AS (
  SELECT 
    srovnani_mzdy.rok,
    srovnani_mzdy.prumerna_mzda,
    srovnani_mzdy.predchozi_mzda, 
    CASE 
   	  WHEN (prumerna_mzda - predchozi_mzda) < 0 THEN 'snížena'
   	  WHEN (prumerna_mzda - predchozi_mzda) > 0 THEN 'zvýšena'
      WHEN (prumerna_mzda - predchozi_mzda) = 0 THEN 'stejná'        
      ELSE 'nesrovnatelné s předchozím rokem'
    END AS zmena_mzdy
   FROM srovnani_mzdy
),
procenta_mzdy AS (
    SELECT 
      mezirust_mzdy.rok,
      mezirust_mzdy.prumerna_mzda,
      mezirust_mzdy.predchozi_mzda,
      mezirust_mzdy.zmena_mzdy,
	  ROUND(100*((prumerna_mzda - predchozi_mzda)/predchozi_mzda)) AS narust_mzdy_procenta
   FROM mezirust_mzdy
)
SELECT   
   procenta_mzdy.rok,
   procenta_mzdy.prumerna_mzda,
   procenta_mzdy.predchozi_mzda,
   procenta_mzdy.zmena_mzdy, 
   procenta_mzdy.narust_mzdy_procenta
FROM procenta_mzdy
  WHERE predchozi_mzda IS NOT NULL   
    AND zmena_mzdy = 'zvýšena'        -- uvažuji jen zvýšení mzdy   
  ORDER BY narust_mzdy_procenta DESC;              
-- meziroční nárůst průmerné mzdy



WITH    -- porovnání meziročních nárustů cen potravin a mezd
prumery_potr AS ( 
  SELECT   -- meziroční růst cen potravin
     EXTRACT(YEAR FROM cp.date_from::DATE) AS rok,
     cp.category_code AS kategorie,
     cpc.name AS nazev,
     ROUND(AVG(cp.value)) AS prumerna_cena    
  FROM czechia_price cp
    JOIN czechia_price_category cpc
       ON cp.category_code = cpc.code
    GROUP BY cp.category_code, cpc.name, rok
    ORDER BY name ASC
  ),
srovnani_potr AS (
  SELECT 
    prumery_potr.rok,
    prumery_potr.kategorie,
    prumery_potr.nazev,
    prumery_potr.prumerna_cena,
    LAG (prumerna_cena) OVER (PARTITION BY kategorie 
      ORDER BY rok) AS predchozi_cena
  FROM prumery_potr   
  ),
mezirust_potr AS (
  SELECT 
    srovnani_potr.rok,
    srovnani_potr.kategorie,
    srovnani_potr.nazev,
    srovnani_potr.prumerna_cena,
    srovnani_potr.predchozi_cena, 
    CASE 
   	  WHEN (prumerna_cena - predchozi_cena) < 0 THEN 'zlevněno'
   	  WHEN (prumerna_cena - predchozi_cena) > 0 THEN 'zdraženo'
      WHEN (prumerna_cena - predchozi_cena) = 0 THEN 'stejná cena'        
      ELSE 'nesrovnatelné s předchozím rokem'
    END AS zmena_ceny
   FROM srovnani_potr
),
procenta_potr AS (
    SELECT 
      mezirust_potr.rok,
      mezirust_potr.kategorie,
      mezirust_potr.nazev,
      mezirust_potr.prumerna_cena,
      mezirust_potr.predchozi_cena,
      mezirust_potr.zmena_ceny,
	  ROUND(100*((prumerna_cena - predchozi_cena)/predchozi_cena)) AS narust_ceny_procenta
   FROM mezirust_potr
),
prumer_rustu_cen_potr AS (
     SELECT   
       procenta_potr.rok,
       procenta_potr.kategorie,
       procenta_potr.nazev,
       procenta_potr.prumerna_cena,
       procenta_potr.predchozi_cena,
       procenta_potr.zmena_ceny, 
       AVG(procenta_potr.narust_ceny_procenta) AS prumer_rustu
     FROM procenta_potr 
        GROUP BY kategorie, nazev, rok, prumerna_cena, predchozi_cena, zmena_ceny 
        ORDER BY rok, kategorie
  ),
prumery_mzdy AS (   -- meziroční nárůst průmerné mzdy
  SELECT   
     payroll_year AS rok,
     ROUND(AVG(cp2.value)) AS prumerna_mzda    
  FROM czechia_payroll cp2
    JOIN czechia_payroll_value_type cpvt
       ON cp2.value_type_code = cpvt.code
    GROUP BY rok
    ORDER BY rok ASC
 ),
srovnani_mzdy AS (
  SELECT 
    prumery_mzdy.rok,
    prumery_mzdy.prumerna_mzda,
    LAG(prumerna_mzda) OVER (ORDER BY rok) AS predchozi_mzda
  FROM prumery_mzdy   
 ),
mezirust_mzdy AS (
  SELECT 
    srovnani_mzdy.rok,
    srovnani_mzdy.prumerna_mzda,
    srovnani_mzdy.predchozi_mzda, 
    CASE 
   	  WHEN (prumerna_mzda - predchozi_mzda) < 0 THEN 'snížena'
   	  WHEN (prumerna_mzda - predchozi_mzda) > 0 THEN 'zvýšena'
      WHEN (prumerna_mzda - predchozi_mzda) = 0 THEN 'stejná'        
      ELSE 'nesrovnatelné s předchozím rokem'
    END AS zmena_mzdy
   FROM srovnani_mzdy
),
procenta_mzdy AS (
    SELECT 
      mezirust_mzdy.rok,
      mezirust_mzdy.prumerna_mzda,
      mezirust_mzdy.predchozi_mzda,
      mezirust_mzdy.zmena_mzdy,
	  ROUND(100*((prumerna_mzda - predchozi_mzda)/predchozi_mzda)) AS narust_mzdy_proc
   FROM mezirust_mzdy
)
SELECT   
   prumer_rustu_cen_potr.rok,
   prumer_rustu_cen_potr.nazev AS nazev_potraviny,
   (prumer_rustu_cen_potr.prumer_rustu - procenta_mzdy.narust_mzdy_proc) AS rozdil_cena_mzda_proc,
   prumer_rustu_cen_potr.prumer_rustu AS rust_cen_potr_proc,
   procenta_mzdy.narust_mzdy_proc,
   prumer_rustu_cen_potr.zmena_ceny,
   procenta_mzdy.zmena_mzdy
FROM procenta_mzdy
  JOIN prumer_rustu_cen_potr
     ON procenta_mzdy.rok = prumer_rustu_cen_potr.rok 
  WHERE prumer_rustu_cen_potr.predchozi_cena IS NOT NULL   --u r. 2006 neexistuje předchozí rok 
    AND procenta_mzdy.predchozi_mzda IS NOT NULL
    --AND zmena_ceny = 'zdraženo'    -- uvažuji jen zdražení potravin      
  	AND (prumer_rustu_cen_potr.prumer_rustu - procenta_mzdy.narust_mzdy_proc) > 10
  ORDER BY rozdil_cena_mzda_proc DESC, rok ASC
  ;              
-- meziroční nárůst cen potravin byl výrazně vyšší než růst mezd (více než 10%) 
   -- v roce 2007 u potraviny Papriky až 97% oproti zvýšení mezd o 7% - tj. rozdíl 90%	
   -- v roce 2013 u Konzumních brambor byl nárůst ceny oproti mzdám o 61%.  
   -- v roce 2012 u Vajec byl nárůst ceny oproti mzdám o 53%.  
   -- víc než 60 položek (potravina/rok) bylo zvýšeno o víc než 10% oproti mzdám 



--analýza z primární tabulky:

WITH    -- porovnání meziročních nárustů cen potravin a mezd
prumery_potr AS ( 
  SELECT   -- meziroční růst cen potravin
     tpr.rok_p,
     tpr.category_code AS kategorie,
     tpr.potravina AS nazev,
     tpr.prumer_cena_potr     
  FROM t_vera_vavrincova_project_SQL_primary_final tpr
 ),
srovnani_potr AS (
  SELECT 
    prumery_potr.rok_p,
    prumery_potr.kategorie,
    prumery_potr.nazev,
    prumery_potr.prumer_cena_potr,
    LAG (prumer_cena_potr) OVER (PARTITION BY kategorie 
      ORDER BY rok_p) AS predchozi_cena
  FROM prumery_potr   
  ),
mezirust_potr AS (
  SELECT 
    srovnani_potr.rok_p,
    srovnani_potr.kategorie,
    srovnani_potr.nazev,
    srovnani_potr.prumer_cena_potr,
    srovnani_potr.predchozi_cena, 
    CASE 
   	  WHEN (prumer_cena_potr - predchozi_cena) < 0 THEN 'zlevněno'
   	  WHEN (prumer_cena_potr - predchozi_cena) > 0 THEN 'zdraženo'
      WHEN (prumer_cena_potr - predchozi_cena) = 0 THEN 'stejná cena'        
      ELSE 'nesrovnatelné s předchozím rokem'
    END AS zmena_ceny
   FROM srovnani_potr
),
procenta_potr AS (
    SELECT 
      mezirust_potr.rok_p,
      mezirust_potr.kategorie,
      mezirust_potr.nazev,
      mezirust_potr.prumer_cena_potr,
      mezirust_potr.predchozi_cena,
      mezirust_potr.zmena_ceny,
	  ROUND(100*((prumer_cena_potr - predchozi_cena)/predchozi_cena)) AS narust_ceny_procenta
   FROM mezirust_potr
),
prumer_rustu_cen_potr AS (
     SELECT   
       procenta_potr.rok_p,
       procenta_potr.kategorie,
       procenta_potr.nazev,
       procenta_potr.prumer_cena_potr,
       procenta_potr.predchozi_cena,
       procenta_potr.zmena_ceny, 
       AVG(procenta_potr.narust_ceny_procenta) AS prumer_rustu
     FROM procenta_potr 
        GROUP BY kategorie, nazev, rok_p, prumer_cena_potr, predchozi_cena, zmena_ceny 
        ORDER BY rok_p, kategorie
  ),
prumery_mzdy AS (   -- meziroční nárůst průmerné mzdy
  SELECT   
     tpr.rok_m,
     tpr.prumer_mzda    
  FROM t_vera_vavrincova_project_SQL_primary_final tpr
  ),
srovnani_mzdy AS (
  SELECT 
    prumery_mzdy.rok_m,
    prumery_mzdy.prumer_mzda,
    LAG(prumer_mzda) OVER (ORDER BY rok_m) AS predchozi_mzda
  FROM prumery_mzdy   
 ),
mezirust_mzdy AS (
  SELECT 
    srovnani_mzdy.rok_m,
    srovnani_mzdy.prumer_mzda,
    srovnani_mzdy.predchozi_mzda, 
    CASE 
   	  WHEN (prumer_mzda - predchozi_mzda) < 0 THEN 'snížena'
   	  WHEN (prumer_mzda - predchozi_mzda) > 0 THEN 'zvýšena'
      WHEN (prumer_mzda - predchozi_mzda) = 0 THEN 'stejná'        
      ELSE 'nesrovnatelné s předchozím rokem'
    END AS zmena_mzdy
   FROM srovnani_mzdy
),
procenta_mzdy AS (
    SELECT 
      mezirust_mzdy.rok_m,
      mezirust_mzdy.prumer_mzda,
      mezirust_mzdy.predchozi_mzda,
      mezirust_mzdy.zmena_mzdy,
	  ROUND(100*((prumer_mzda - predchozi_mzda)/predchozi_mzda)) AS narust_mzdy_proc
   FROM mezirust_mzdy
)
SELECT   
   prumer_rustu_cen_potr.rok_p,
   prumer_rustu_cen_potr.nazev AS nazev_potraviny,
   (prumer_rustu_cen_potr.prumer_rustu - procenta_mzdy.narust_mzdy_proc) AS rozdil_cena_mzda_proc,
   prumer_rustu_cen_potr.prumer_rustu AS rust_cen_potr_proc,
   procenta_mzdy.narust_mzdy_proc,
   prumer_rustu_cen_potr.zmena_ceny,
   procenta_mzdy.zmena_mzdy,
   procenta_mzdy.rok_m
FROM procenta_mzdy
  JOIN prumer_rustu_cen_potr
     ON procenta_mzdy.rok_m = prumer_rustu_cen_potr.rok_p 
  WHERE prumer_rustu_cen_potr.predchozi_cena IS NOT NULL   --u r. 2006 neexistuje předchozí rok 
    AND procenta_mzdy.predchozi_mzda IS NOT NULL
    AND zmena_ceny = 'zdraženo'    -- uvažuji jen zdražení potravin      
  	AND (prumer_rustu_cen_potr.prumer_rustu - procenta_mzdy.narust_mzdy_proc) > 10
  ORDER BY rozdil_cena_mzda_proc DESC, procenta_mzdy.rok_m ASC
  ;
