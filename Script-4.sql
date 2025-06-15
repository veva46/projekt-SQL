-- projekt DA SQL Engeto
-- Věra Vavrincová
-- úkol 4

--Existuje rok, ve kterém byl meziroční nárůst cen potravin výrazně vyšší 
      --než růst mezd (větší než 10 %)?

--použiji skript z úkolu č.3 a dopracuji ho pro tento 4.úkol

WITH    -- meziroční nárust cen potravin
prumeryPOTR AS (
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
srovnaniPOTR AS (
  SELECT 
    prumeryPOTR.rok,
    prumeryPOTR.kategorie,
    prumeryPOTR.nazev,
    prumeryPOTR.prumerna_cena,
    LAG (prumerna_cena) OVER (PARTITION BY kategorie 
      ORDER BY rok) AS predchozi_cena
  FROM prumeryPOTR   
  ),
mezirustPOTR AS (
  SELECT 
    srovnaniPOTR.rok,
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
      mezirustPOTR.rok,
      mezirustPOTR.kategorie,
      mezirustPOTR.nazev,
      mezirustPOTR.prumerna_cena,
      mezirustPOTR.predchozi_cena,
      mezirustPOTR.zmena_ceny,
	  ROUND(100*((prumerna_cena - predchozi_cena)/predchozi_cena)) AS narust_ceny_procenta
   FROM mezirustPOTR
),
prumer_rustu_cenPOTR AS (
     SELECT   
       procentaPOTR.rok,
       procentaPOTR.kategorie,
       procentaPOTR.nazev,
       procentaPOTR.prumerna_cena,
       procentaPOTR.predchozi_cena,
       procentaPOTR.zmena_ceny, 
       AVG(procentaPOTR.narust_ceny_procenta) AS prumer_rustu
     FROM procentaPOTR 
        GROUP BY kategorie, nazev, rok, prumerna_cena, predchozi_cena, zmena_ceny 
        ORDER BY rok, kategorie
  )      
SELECT   
   prumer_rustu_cenPOTR.rok,
   prumer_rustu_cenPOTR.nazev,
   prumer_rustu_cenPOTR.prumerna_cena,
   prumer_rustu_cenPOTR.predchozi_cena,
   prumer_rustu_cenPOTR.zmena_ceny, 
   prumer_rustu_cenPOTR.prumer_rustu
FROM prumer_rustu_cenPOTR 
  WHERE predchozi_cena IS NOT NULL   
    AND zmena_ceny = 'zdraženo'    -- uvažuji jen zdražení potravin      
  ORDER BY prumer_rustu DESC;              
-- meziroční růst cen potravin 			



WITH     -- meziroční nárůst průmerné mzdy
prumeryMZDY AS (
  SELECT   -- průměrné mzdy v letech
     payroll_year AS rok,
     ROUND(AVG(cp2.value)) AS prumerna_mzda    
  FROM czechia_payroll cp2
    JOIN czechia_payroll_value_type cpvt
       ON cp2.value_type_code = cpvt.code
    GROUP BY rok
    ORDER BY rok ASC
 ),
srovnaniMZDY AS (
  SELECT 
    prumeryMZDY.rok,
    prumeryMZDY.prumerna_mzda,
    LAG(prumerna_mzda) OVER (ORDER BY rok) AS predchozi_mzda
  FROM prumeryMZDY   
 ),
mezirustMZDY AS (
  SELECT 
    srovnaniMZDY.rok,
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
      mezirustMZDY.rok,
      mezirustMZDY.prumerna_mzda,
      mezirustMZDY.predchozi_mzda,
      mezirustMZDY.zmena_mzdy,
	  ROUND(100*((prumerna_mzda - predchozi_mzda)/predchozi_mzda)) AS narust_mzdy_procenta
   FROM mezirustMZDY
)
SELECT   
   procentaMZDY.rok,
   procentaMZDY.prumerna_mzda,
   procentaMZDY.predchozi_mzda,
   procentaMZDY.zmena_mzdy, 
   procentaMZDY.narust_mzdy_procenta
FROM procentaMZDY
  WHERE predchozi_mzda IS NOT NULL   
    AND zmena_mzdy = 'zvýšena'        -- uvažuji jen zvýšení mzdy   
  ORDER BY narust_mzdy_procenta DESC;              
-- meziroční nárůst průmerné mzdy


WITH    -- porovnání meziročních nárustů cen potravin a mezd
prumeryPOTR AS ( 
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
srovnaniPOTR AS (
  SELECT 
    prumeryPOTR.rok,
    prumeryPOTR.kategorie,
    prumeryPOTR.nazev,
    prumeryPOTR.prumerna_cena,
    LAG (prumerna_cena) OVER (PARTITION BY kategorie 
      ORDER BY rok) AS predchozi_cena
  FROM prumeryPOTR   
  ),
mezirustPOTR AS (
  SELECT 
    srovnaniPOTR.rok,
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
      mezirustPOTR.rok,
      mezirustPOTR.kategorie,
      mezirustPOTR.nazev,
      mezirustPOTR.prumerna_cena,
      mezirustPOTR.predchozi_cena,
      mezirustPOTR.zmena_ceny,
	  ROUND(100*((prumerna_cena - predchozi_cena)/predchozi_cena)) AS narust_ceny_procenta
   FROM mezirustPOTR
),
prumer_rustu_cenPOTR AS (
     SELECT   
       procentaPOTR.rok,
       procentaPOTR.kategorie,
       procentaPOTR.nazev,
       procentaPOTR.prumerna_cena,
       procentaPOTR.predchozi_cena,
       procentaPOTR.zmena_ceny, 
       AVG(procentaPOTR.narust_ceny_procenta) AS prumer_rustu
     FROM procentaPOTR 
        GROUP BY kategorie, nazev, rok, prumerna_cena, predchozi_cena, zmena_ceny 
        ORDER BY rok, kategorie
  ),
prumeryMZDY AS (   -- meziroční nárůst průmerné mzdy
  SELECT   
     payroll_year AS rok,
     ROUND(AVG(cp2.value)) AS prumerna_mzda    
  FROM czechia_payroll cp2
    JOIN czechia_payroll_value_type cpvt
       ON cp2.value_type_code = cpvt.code
    GROUP BY rok
    ORDER BY rok ASC
 ),
srovnaniMZDY AS (
  SELECT 
    prumeryMZDY.rok,
    prumeryMZDY.prumerna_mzda,
    LAG(prumerna_mzda) OVER (ORDER BY rok) AS predchozi_mzda
  FROM prumeryMZDY   
 ),
mezirustMZDY AS (
  SELECT 
    srovnaniMZDY.rok,
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
      mezirustMZDY.rok,
      mezirustMZDY.prumerna_mzda,
      mezirustMZDY.predchozi_mzda,
      mezirustMZDY.zmena_mzdy,
	  ROUND(100*((prumerna_mzda - predchozi_mzda)/predchozi_mzda)) AS narust_mzdy_procenta
   FROM mezirustMZDY
)
SELECT   
   prumer_rustu_cenPOTR.rok,
   prumer_rustu_cenPOTR.nazev,
   (prumer_rustu_cenPOTR.prumer_rustu - procentaMZDY.narust_mzdy_procenta) AS procent_rozdil_cena_mzda,
   prumer_rustu_cenPOTR.prumer_rustu AS rust_cen_POTR_proc,
   procentaMZDY.narust_mzdy_procenta,
   prumer_rustu_cenPOTR.zmena_ceny,
   procentaMZDY.zmena_mzdy
FROM procentaMZDY
  JOIN prumer_rustu_cenPOTR
     ON procentaMZDY.rok = prumer_rustu_cenPOTR.rok 
  WHERE prumer_rustu_cenPOTR.predchozi_cena IS NOT NULL   --u r. 2006 neexistuje předchozí rok 
    AND procentaMZDY.predchozi_mzda IS NOT NULL
    --AND zmena_ceny = 'zdraženo'    -- uvažuji jen zdražení potravin      
  	AND (prumer_rustu_cenPOTR.prumer_rustu - procentaMZDY.narust_mzdy_procenta) > 10
  ORDER BY procent_rozdil_cena_mzda DESC, rok ASC
  ;              
-- meziroční nárust cen potravin byl výrazně vyšší než růst mezd (více než 10%) 
   -- v roce 2007 u potraviny Papriky až 97% oproti zvýšení mezd o 7% - tj. rozdíl 90%	
           --pak v roce 2013 u Konzumní brambory a v roce 2012 u Vajec	
-- víc než 60 položek (potravina/rok) bylo zvýšeno o víc než 10% oproti mzdám 

