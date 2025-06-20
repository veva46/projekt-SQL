-- projekt DA SQL Engeto
-- Věra Vavrincová
-- úkol 2
-- Kolik je možné si koupit litrů mléka a kilogramů chleba za první a poslední srovnatelné období 
-- v dostupných datech cen a mezd?

--analýza z tabulek Engeta:

WITH obdobi AS (  -- a vybere první a poslední srovnatelné období (tj.1týden - 7dní)
 SELECT                 --Dotaz vybere řádky jen pro Mléko a Chléb, jejich cenu 
   DATE(cp.date_from::DATE)AS datum_OD,  
   DATE(cp.date_to::DATE) AS datum_DO    
 FROM czechia_price cp
)
SELECT 
   cpc.name,  
   cp.value,
   DATE(cp.date_from::DATE)AS datum_OD,  --DATE změní datum jen na YYYY-MM-DD tj.bez hodin -- ::DATE přeformátuje datum na typ DATE
   DATE(cp.date_to::DATE) AS datum_DO,
   EXTRACT(QUARTER FROM date_from) AS kvartal,   -- převede datum do kvartálu v roce
   EXTRACT(YEAR FROM cp.date_from) AS rok_kvartal,
   cpc.price_value,
   cpc.price_unit
FROM czechia_price cp
JOIN czechia_price_category cpc   --připojí tabulku cpc
   ON cp.category_code = cpc.code 
WHERE (cpc.name IN ('Chléb konzumní kmínový','Mléko polotučné pasterované'))
   AND (DATE(cp.date_from::DATE) IN (    -- vybere jen první a poslední období
     (SELECT MIN(datum_OD) FROM obdobi), 
     (SELECT MAX(datum_OD) FROM obdobi)  
    ));                                                              
-- první srovnatelné období je od 2.1.2006 do 8.1.2006 - tj.7dní - tj. 1.Q roku 2006 
-- poslední srovnatelné období je od 10.12.2018 do 16.12.2018 - tj.7dní - tj. 4.Q roku 2018    



SELECT   --průměrná MZDA
	ROUND(AVG(cp2.value),0) AS Prumerna_mzda,  -- průměrná hrubá mzda zaměstanců v období (formát numeric) (pokud je value_type_code = '5958')
    CASE 
		WHEN cp2.payroll_quarter = 1 AND cp2.payroll_year = 2006 THEN '1Q/2006'
		WHEN cp2.payroll_quarter = 4 AND cp2.payroll_year = 2018 THEN '4Q/2018'
		  ELSE 'nesrovnávané období'
	END AS kvartal_rok
FROM czechia_payroll cp2
  WHERE cp2.value_type_code = '5958'
    AND (cp2.payroll_quarter = '1' AND cp2.payroll_year = '2006')  -- pro 1. srovnatelné období
    OR (cp2.payroll_quarter = '4' AND cp2.payroll_year = '2018')   -- pro poslední srovnatelné období
GROUP BY kvartal_rok;  


SELECT   -- kvartální cena potravin(mléka a chleba)
	CASE 
		WHEN (EXTRACT(QUARTER FROM date_from) = 1) AND (EXTRACT(YEAR FROM cp.date_from) = 2006) THEN '1Q/2006'
		WHEN (EXTRACT(QUARTER FROM date_from) = 4) AND (EXTRACT(YEAR FROM cp.date_from) = 2018) THEN '4Q/2018'
		  --ELSE 'nesrovnávané období'
	END AS kvartal_rok,
	cpc.name,
	ROUND(AVG(cp.value)) AS Prumerna_cena_potraviny   -- formát integer
FROM czechia_price cp
JOIN czechia_price_category cpc
    ON cp.category_code = cpc.code
WHERE ((EXTRACT(QUARTER FROM date_from) = 1 AND EXTRACT(YEAR FROM cp.date_from) = 2006)        -- pro první srovnatelné období
        OR (EXTRACT(QUARTER FROM date_from) = 4 AND EXTRACT(YEAR FROM cp.date_from) = 2018) )  -- pro poslední srovnatelné období
	  AND (cp.category_code = '111301' OR cp.category_code = '114201') -- mléko a chleba;
GROUP BY cp.category_code, kvartal_rok, cpc.name
ORDER BY kvartal_rok, category_code;



WITH mzda AS (  --- výpočet, kolik si lze koupit mléka a chleba za průměrnou mzdu ve srovnávaném období
  SELECT 
	ROUND(AVG(cp2.value),0) AS Prumerna_mzda,  -- průměrná hrubá mzda zaměstanců v období (formát numeric) (pokud je value_type_code = '5958')
    CASE 
	   WHEN cp2.payroll_quarter = 1 AND cp2.payroll_year = 2006 THEN '1Q/2006'
	   WHEN cp2.payroll_quarter = 4 AND cp2.payroll_year = 2018 THEN '4Q/2018'
		  --ELSE 'nesrovnávané období'
	END AS kvartal_rok
  FROM czechia_payroll cp2
   WHERE cp2.value_type_code = '5958'
     AND (cp2.payroll_quarter = '1' AND cp2.payroll_year = '2006')  -- pro 1. srovnatelné období
     OR (cp2.payroll_quarter = '4' AND cp2.payroll_year = '2018')   -- pro poslední srovnatelné období
   GROUP BY kvartal_rok
), 
cena AS (
   SELECT   -- kvartální cena potravin(mléka a chleba)
	 CASE 
		WHEN (EXTRACT(QUARTER FROM date_from) = 1) AND (EXTRACT(YEAR FROM cp.date_from) = 2006) THEN '1Q/2006'
		WHEN (EXTRACT(QUARTER FROM date_from) = 4) AND (EXTRACT(YEAR FROM cp.date_from) = 2018) THEN '4Q/2018'
		  --ELSE 'nesrovnávané období'
	 END AS kvartal_rok,
	 cp.category_code,
	 cpc.name AS potravina,
	 ROUND(AVG(cp.value)) AS Prumerna_cena_potraviny   -- formát integer
   FROM czechia_price cp
    JOIN czechia_price_category cpc
      ON cp.category_code = cpc.code
    WHERE ((EXTRACT(QUARTER FROM date_from) = 1 AND EXTRACT(YEAR FROM cp.date_from) = 2006)   -- pro 1. srovnatelné období
        OR (EXTRACT(QUARTER FROM date_from) = 4 AND EXTRACT(YEAR FROM cp.date_from) = 2018) ) -- pro poslední srovnatelné období
	   AND (cp.category_code = '111301' OR cp.category_code = '114201') -- mléko a chleba;
    GROUP BY cp.category_code, kvartal_rok, cpc.name
    ORDER BY kvartal_rok, category_code
)
SELECT 
    cena.kvartal_rok,
    mzda.Prumerna_mzda,
    cena.potravina,
    cena.Prumerna_cena_potraviny,
    ROUND(mzda.Prumerna_mzda / cena.Prumerna_cena_potraviny) AS pocet_jednotek_potraviny_za_mzdu  --počet jednotek potraviny možné koupit za průměrnou mzdu
FROM mzda
 JOIN cena  --spojení tabulky cena a mzda, pro vypsání kvartálů
   ON mzda.kvartal_rok = cena.kvartal_rok
 ORDER BY cena.kvartal_rok, cena.potravina;

-- od 2.1.2006 do 8.1.2006 (tj. 1 kvartál roku 2006) - první srovnatelné období 
     --je možné koupit za průměrnou mzdu 1303 kg chleba a 1396 l mléka
-- od 10.12.2018 do 16.12.2018 (tj. 4 kvartál roku 2018) - poslední srovnatelné období 
     --je možné koupit za průměrnou mzdu 1367 kg chleba a 1727 l mléka



--analýza z prim.tabulky:

WITH mzda AS (  --- výpočet, kolik si lze koupit mléka a chleba za průměrnou mzdu ve srovnávaném období
  SELECT 
	TP.prumer_mzda,   -- průměrná hrubá mzda zaměstanců v období (pokud je value_type_code = '5958')
	CASE 
	   WHEN TP.kvartalM = 1 AND TP.rokM = 2006 THEN '1Q/2006'
	   WHEN TP.kvartalM = 4 AND TP.rokM = 2018 THEN '4Q/2018'
		  --ELSE 'nesrovnávané období'
	END AS kvartal_rokM
  FROM t_vera_vavrincova_project_SQL_primary_final TP
   WHERE TP.kod_mzdy = '5958'
     AND (TP.kvartalM = '1' AND TP.rokM = '2006')  -- pro 1. srovnatelné období 2.1.2006 do 8.1.2006 
     OR (TP.kvartalM = '4' AND TP.rokM = '2018')   -- pro poslední srovn.období 10.12.2018 do 16.12.2018
  ), 
cena AS (
   SELECT   -- kvartální cena potravin(mléka a chleba)
	 TP.category_code,
	 TP.potravina,
	 TP.prumer_cena_potr,  --průměrná cena potraviny
	 CASE 
		WHEN (TP.kvartalP = 1) AND (TP.rokP = 2006) THEN '1Q/2006'
		WHEN (TP.kvartalP = 4) AND (TP.rokP = 2018) THEN '4Q/2018'
		  --ELSE 'nesrovnávané období'
	 END AS kvartal_rokP
   FROM t_vera_vavrincova_project_SQL_primary_final TP
    --JOIN czechia_price_category cpc   --spojení tabulek již v prim.tabulce
      --ON cp.category_code = cpc.code
    WHERE ((TP.kvartalp = 1 AND TP.rokP = 2006)   -- pro 1. srovnatelné období
        OR (TP.kvartalp = 4 AND TP.rokP = 2018)) -- pro poslední srovnatelné období
	   AND (TP.category_code = '111301' OR TP.category_code = '114201') -- mléko a chleba;
    ORDER BY kvartal_rokP, TP.category_code
)
SELECT 
    mzda.kvartal_rokM,
    mzda.prumer_mzda,
    cena.potravina,
    cena.prumer_cena_potr,
    ROUND(mzda.prumer_mzda / cena.prumer_cena_potr) AS pocet_jednotek_potraviny_za_mzdu  --počet jednotek potraviny možné koupit za průměrnou mzdu
FROM mzda
 JOIN cena  --spojení tabulky cena a mzda, pro vypsání kvartálů
   ON mzda.kvartal_rokM = cena.kvartal_rokP
 ORDER BY mzda.kvartal_rokM, cena.potravina;
