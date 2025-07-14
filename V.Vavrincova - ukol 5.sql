-- projekt DA SQL Engeto
-- Věra Vavrincová
-- úkol 5

--Má výška HDP vliv na změny ve mzdách a cenách potravin? 
--Neboli, pokud HDP vzroste výrazněji v jednom roce, projeví se to na cenách 
--potravin či mzdách ve stejném nebo následujícím roce výraznějším růstem?


--porovnání meziročních nárustů cen jednotlivých potravin, mezd a HDP v ČR v letech 2006-2018
WITH 
prumery_potr AS (
  SELECT 
    -- meziroční růst cen potravin
    EXTRACT(
      YEAR 
      FROM 
        cp.date_from :: DATE
    ) AS rok_p, 
    cp.category_code AS kategorie, 
    cpc.name AS nazev, 
    ROUND(
      AVG(cp.value)
    ) AS prumerna_cena 
  FROM 
    czechia_price cp 
    JOIN czechia_price_category cpc ON cp.category_code = cpc.code 
  GROUP BY 
    cp.category_code, 
    cpc.name, 
    rok_p 
  ORDER BY 
    name ASC
), 
srovnani_potr AS (
  SELECT 
    prumery_potr.rok_p, 
    prumery_potr.kategorie, 
    prumery_potr.nazev, 
    prumery_potr.prumerna_cena, 
    LAG (prumerna_cena) OVER (
      PARTITION BY kategorie 
      ORDER BY 
        rok_p
    ) AS predchozi_cena 
  FROM 
    prumery_potr
), 
mezirust_potr AS (
  SELECT 
    srovnani_potr.rok_p, 
    srovnani_potr.kategorie, 
    srovnani_potr.nazev, 
    srovnani_potr.prumerna_cena, 
    srovnani_potr.predchozi_cena, 
    CASE WHEN (prumerna_cena - predchozi_cena) < 0 THEN 'zlevněno' WHEN (prumerna_cena - predchozi_cena) > 0 THEN 'zdraženo' WHEN (prumerna_cena - predchozi_cena) = 0 THEN 'stejná cena' ELSE 'nesrovnatelné s předchozím rokem' END AS zmena_ceny 
  FROM 
    srovnani_potr
), 
procenta_potr AS (
  SELECT 
    mezirust_potr.rok_p, 
    mezirust_potr.kategorie, 
    mezirust_potr.nazev, 
    mezirust_potr.prumerna_cena, 
    mezirust_potr.predchozi_cena, 
    mezirust_potr.zmena_ceny, 
    ROUND(
      100 *(
        (prumerna_cena - predchozi_cena)/ predchozi_cena
      )
    ) AS narust_ceny_procenta 
  FROM 
    mezirust_potr
), 
prumer_potr AS (
  SELECT 
    procenta_potr.rok_p, 
    procenta_potr.kategorie, 
    procenta_potr.nazev, 
    procenta_potr.prumerna_cena, 
    procenta_potr.predchozi_cena, 
    procenta_potr.zmena_ceny, 
    AVG(
      procenta_potr.narust_ceny_procenta
    ) AS prumer_rustu 
  FROM 
    procenta_potr 
  GROUP BY 
    kategorie, 
    nazev, 
    rok_p, 
    prumerna_cena, 
    predchozi_cena, 
    zmena_ceny 
  ORDER BY 
    rok_p, 
    kategorie
), 
prumery_mzdy AS (
  -- meziroční růst průmerné mzdy
  SELECT 
    payroll_year AS rok_m, 
    ROUND(
      AVG(cp2.value)
    ) AS prumerna_mzda 
  FROM 
    czechia_payroll cp2 
    JOIN czechia_payroll_value_type cpvt ON cp2.value_type_code = cpvt.code 
  GROUP BY 
    rok_m 
  ORDER BY 
    rok_m ASC
), 
srovnani_mzdy AS (
  SELECT 
    prumery_mzdy.rok_m, 
    prumery_mzdy.prumerna_mzda, 
    LAG(prumerna_mzda) OVER (
      ORDER BY 
        rok_m
    ) AS predchozi_mzda 
  FROM 
    prumery_mzdy
), 
mezirust_mzdy AS (
  SELECT 
    srovnani_mzdy.rok_m, 
    srovnani_mzdy.prumerna_mzda, 
    srovnani_mzdy.predchozi_mzda, 
    CASE WHEN (prumerna_mzda - predchozi_mzda) < 0 THEN 'snížena' WHEN (prumerna_mzda - predchozi_mzda) > 0 THEN 'zvýšena' WHEN (prumerna_mzda - predchozi_mzda) = 0 THEN 'stejná' ELSE 'nesrovnatelné s předchozím rokem' END AS zmena_mzdy 
  FROM 
    srovnani_mzdy
), 
procenta_mzdy AS (
  SELECT 
    mezirust_mzdy.rok_m AS rok_m, 
    mezirust_mzdy.prumerna_mzda, 
    mezirust_mzdy.predchozi_mzda, 
    mezirust_mzdy.zmena_mzdy, 
    ROUND(
      100 *(
        (prumerna_mzda - predchozi_mzda)/ predchozi_mzda
      )
    ) AS narust_mzdy_proc 
  FROM 
    mezirust_mzdy
), 
hdp AS (
  -- meziroční porovnání HDP
  SELECT 
    country, 
    year, 
    population, 
    gdp, 
    LAG (gdp) OVER (
      PARTITION BY country 
      ORDER BY 
        year
    ) AS predchozi_rok_gdp 
  FROM 
    economies e
) 
SELECT 
  hdp.country, 
  hdp.year, 
  ROUND(
    100 *(
      (hdp.gdp - hdp.predchozi_rok_gdp)/ hdp.predchozi_rok_gdp
    )
  ) AS narust_hdp_proc, 
  procenta_mzdy.narust_mzdy_proc, 
  prumer_potr.prumer_rustu AS rust_cen_potr_proc, 
  prumer_potr.rok_p, 
  prumer_potr.nazev AS nazev_potraviny, 
  (
    prumer_potr.prumer_rustu - procenta_mzdy.narust_mzdy_proc
  ) AS rozdil_cena_mzda_proc, 
  prumer_potr.zmena_ceny, 
  hdp.gdp, 
  hdp.predchozi_rok_gdp, 
  CASE WHEN (predchozi_rok_gdp < gdp) THEN 'HDP zvýšeno' WHEN (predchozi_rok_gdp > gdp) THEN 'HDP sníženo' ELSE 'HDP stejné' END AS zmena_HDP, 
  procenta_mzdy.rok_m AS rok_m, 
  procenta_mzdy.prumerna_mzda, 
  procenta_mzdy.predchozi_mzda, 
  procenta_mzdy.zmena_mzdy, 
  hdp.population 
FROM 
  hdp 
  JOIN prumer_potr ON hdp.YEAR = prumer_potr.rok_p 
  JOIN procenta_mzdy ON hdp.YEAR = procenta_mzdy.rok_m 
WHERE 
  hdp.country = 'Czech Republic' -- uvažuji jen ČR
  AND hdp.YEAR BETWEEN 2006 
  AND 2018 -- období pro porovnání cen potravin a mezd - viz.úkoly 1-4
  AND procenta_mzdy.predchozi_mzda IS NOT NULL 
  AND prumer_potr.predchozi_cena IS NOT NULL -- nesrovnávám první roky, které nemají předchozí rok
ORDER BY 
  hdp.year ASC;                                   
 
            


--porovnání meziročních nárustů průměrných cen potravin a mezd a HDP v ČR v letech 2006-2018
WITH prumer_potr AS (
  SELECT 
    -- meziroční růst cen potravin
    EXTRACT(
      YEAR 
      FROM 
        cp.date_from :: DATE
    ) AS rok_p, 
    ROUND(
      AVG(cp.value)
    ) AS prumerna_cena 
  FROM 
    czechia_price cp 
  GROUP BY 
    rok_p 
  ORDER BY 
    rok_p ASC
), 
srovnani_potr AS (
  SELECT 
    prumer_potr.rok_p, 
    prumer_potr.prumerna_cena, 
    LAG (prumerna_cena) OVER (
      ORDER BY 
        rok_p
    ) AS predchozi_cena 
  FROM 
    prumer_potr
), 
mezirust_potr AS (
  SELECT 
    srovnani_potr.rok_p, 
    srovnani_potr.prumerna_cena, 
    srovnani_potr.predchozi_cena, 
    CASE WHEN (prumerna_cena - predchozi_cena) < 0 THEN 'zlevněno' WHEN (prumerna_cena - predchozi_cena) > 0 THEN 'zdraženo' WHEN (prumerna_cena - predchozi_cena) = 0 THEN 'stejná cena' ELSE 'nesrovnatelné s předchozím rokem' END AS zmena_ceny 
  FROM 
    srovnani_potr
), 
procenta_potr AS (
  SELECT 
    mezirust_potr.rok_p, 
    mezirust_potr.prumerna_cena, 
    mezirust_potr.predchozi_cena, 
    mezirust_potr.zmena_ceny, 
    ROUND(
      100 *(
        (prumerna_cena - predchozi_cena)/ predchozi_cena
      )
    ) AS narust_ceny_procenta 
  FROM 
    mezirust_potr
), 
prum_potr AS (
  SELECT 
    procenta_potr.rok_p, 
    procenta_potr.prumerna_cena, 
    procenta_potr.predchozi_cena, 
    procenta_potr.zmena_ceny, 
    AVG(
      procenta_potr.narust_ceny_procenta
    ) AS prumer_rustu 
  FROM 
    procenta_potr 
  GROUP BY 
    rok_p, 
    prumerna_cena, 
    predchozi_cena, 
    zmena_ceny 
  ORDER BY 
    rok_p
), 
prumery_mzdy AS (
  -- meziroční nárůst průmerné mzdy
  SELECT 
    payroll_year AS rok_m, 
    ROUND(
      AVG(cp2.value)
    ) AS prumerna_mzda 
  FROM 
    czechia_payroll cp2 
    JOIN czechia_payroll_value_type cpvt ON cp2.value_type_code = cpvt.code 
  GROUP BY 
    rok_m 
  ORDER BY 
    rok_m ASC
), 
srovnani_mzdy AS (
  SELECT 
    prumery_mzdy.rok_m, 
    prumery_mzdy.prumerna_mzda, 
    LAG(prumerna_mzda) OVER (
      ORDER BY 
        rok_m
    ) AS predchozi_mzda 
  FROM 
    prumery_mzdy
), 
mezirust_mzdy AS (
  SELECT 
    srovnani_mzdy.rok_m, 
    srovnani_mzdy.prumerna_mzda, 
    srovnani_mzdy.predchozi_mzda, 
    CASE WHEN (prumerna_mzda - predchozi_mzda) < 0 THEN 'snížena' WHEN (prumerna_mzda - predchozi_mzda) > 0 THEN 'zvýšena' WHEN (prumerna_mzda - predchozi_mzda) = 0 THEN 'stejná' ELSE 'nesrovnatelné s předchozím rokem' END AS zmena_mzdy 
  FROM 
    srovnani_mzdy
), 
procenta_mzdy AS (
  SELECT 
    mezirust_mzdy.rok_m AS rok_m, 
    mezirust_mzdy.prumerna_mzda, 
    mezirust_mzdy.predchozi_mzda, 
    mezirust_mzdy.zmena_mzdy, 
    ROUND(
      100 *(
        (prumerna_mzda - predchozi_mzda)/ predchozi_mzda
      )
    ) AS narust_mzdy_proc 
  FROM 
    mezirust_mzdy
), 
hdp AS (
  -- meziroční porovnání HDP
  SELECT 
    country, 
    year, 
    population, 
    gdp, 
    LAG (gdp) OVER (
      PARTITION BY country 
      ORDER BY 
        year
    ) AS predchozi_rok_gdp 
  FROM 
    economies e
) 
SELECT 
  hdp.year, 
  ROUND(
    100 *(
      (hdp.gdp - hdp.predchozi_rok_gdp)/ hdp.predchozi_rok_gdp
    )
  ) AS narust_hdp_proc, 
  procenta_mzdy.narust_mzdy_proc, 
  prum_potr.prumer_rustu AS rust_cen_potr_proc, 
  prum_potr.prumerna_cena, 
  prum_potr.predchozi_cena, 
  prum_potr.zmena_ceny, 
  hdp.gdp, 
  hdp.predchozi_rok_gdp, 
  CASE WHEN (predchozi_rok_gdp < gdp) THEN 'HDP zvýšeno' WHEN (predchozi_rok_gdp > gdp) THEN 'HDP sníženo' ELSE 'HDP stejné' END AS zmena_HDP, 
  procenta_mzdy.prumerna_mzda, 
  procenta_mzdy.predchozi_mzda, 
  procenta_mzdy.zmena_mzdy, 
  (
    prum_potr.prumer_rustu - procenta_mzdy.narust_mzdy_proc
  ) AS rozdil_cena_mzda_proc, 
  hdp.country 
FROM 
  hdp 
  JOIN prum_potr ON hdp.YEAR = prum_potr.rok_p 
  JOIN procenta_mzdy ON hdp.YEAR = procenta_mzdy.rok_m 
WHERE 
  hdp.country = 'Czech Republic' --ČR
  AND hdp.YEAR BETWEEN 2006 
  AND 2018 -- období pro porovnání cen potravin a mezd - viz.úkoly 1-4
  AND (
    prum_potr.prumer_rustu - procenta_mzdy.narust_mzdy_proc
  ) IS NOT NULL 
  AND prum_potr.predchozi_cena IS NOT NULL -- první měřený rok nemá předchozí rok
  AND procenta_mzdy.predchozi_mzda IS NOT NULL -- první měřený rok nemá předchozí rok
ORDER BY 
  hdp.year ASC;

--Výška HDP má jistý vliv na ceny potravin a mzdy. 
--Při zvyšování HDP se většinou v dalším roce zvýšila průměrná mzda (např.r.2015, 2017). 
--Ceny potravin se zvedly v závislosti na zvýšení HDP již v tom stejném roce (např.2017). 
 

--HDP v ČR v letech 1991 - 2020  
WITH predch_hdp AS (
  SELECT 
    country, 
    year, 
    population, 
    gdp, 
    LAG (gdp) OVER (
      PARTITION BY country 
      ORDER BY 
        year
    ) AS predchozi_rok_gdp 
  FROM 
    economies e
) 
SELECT 
  predch_hdp.country, 
  predch_hdp.year, 
  predch_hdp.gdp, 
  predch_hdp.population, 
  predch_hdp.predchozi_rok_gdp, 
  CASE WHEN (predchozi_rok_gdp < gdp) THEN 'HDP zvýšeno' WHEN (predchozi_rok_gdp > gdp) THEN 'HDP sníženo' ELSE 'HDP stejné' END AS zmena_HDP 
FROM 
  predch_hdp 
WHERE 
  predch_hdp.country = 'Czech Republic' -- uvažuji jen ČR
  AND predch_hdp.predchozi_rok_gdp IS NOT NULL -- první rok nemá předchozí rok
ORDER BY 
  zmena_hdp, 
  predch_hdp.year;

-- HDP bylo sníženo v letech 1991,1992,1997,1998,2009,2012,2013,2020, 
-- jinak vždy bylo HDP zvýšeno oproti předchozímu roku. 
-- Podklady/zdrojová data/ jsou z období 1990-2020.



-- přehled HDP, Gini a populace pro ostatní státy světa
WITH predch_hdp AS (
  SELECT 
    -- HDP a populace pro předchozí rok
    country, 
    year, 
    population, 
    gini, 
    gdp, 
    LAG (gdp) OVER (
      PARTITION BY country 
      ORDER BY 
        year
    ) AS predchozi_rok_gdp, 
    LAG (population) OVER (
      PARTITION BY country 
      ORDER BY 
        year
    ) AS predchozi_rok_population 
  FROM 
    economies e
) 
SELECT 
  predch_hdp.year, 
  predch_hdp.country, 
  predch_hdp.gdp, 
  predch_hdp.predchozi_rok_gdp, 
  CASE WHEN (
    predch_hdp.predchozi_rok_gdp < predch_hdp.gdp
  ) THEN 'HDP zvýšeno' WHEN (
    predch_hdp.predchozi_rok_gdp > predch_hdp.gdp
  ) THEN 'HDP sníženo' ELSE 'HDP stejné' END AS zmena_hdp, 
  predch_hdp.gini, 
  predch_hdp.population, 
  predch_hdp.predchozi_rok_population, 
  CASE WHEN (
    predch_hdp.predchozi_rok_population < predch_hdp.population
  ) THEN 'populace zvýšena' WHEN (
    predch_hdp.predchozi_rok_population > predch_hdp.population
  ) THEN 'populace snížena' ELSE 'populace stejná' END AS zmena_population 
FROM 
  predch_hdp 
WHERE 
  predch_hdp.predchozi_rok_gdp IS NOT NULL -- první rok nemá předchozí rok
  AND predch_hdp.YEAR BETWEEN 2006 
  AND 2018 -- období pro porovnání cen potravin a mezd - viz.úkoly 1-4
ORDER BY 
  predch_hdp.YEAR ASC, 
  predch_hdp.country, 
  predch_hdp.gdp DESC;



--analýza ze sekukundární tabulky:
WITH prumerceny_p_rok AS (
  SELECT 
    ROUND(
      AVG(ts.prumer_cena_potr)
    ) AS prumer_ceny_potr, 
    --průměr ceny potravin za rok
    ts.category_code, 
    ts.rok_p, 
    ts.kvartal_p 
  FROM 
    t_vera_vavrincova_project_SQL_secondary_final ts 
  GROUP BY 
    ts.rok_p, 
    ts.kvartal_p, 
    ts.category_code
), 
predch_hdp AS (
  SELECT 
    -- HDP a populace pro předchozí rok
    ts.country, 
    ts.year, 
    ts.population, 
    ts.gini, 
    ts.gdp, 
    LAG (ts.gdp) OVER (
      PARTITION BY ts.country 
      ORDER BY 
        ts.year
    ) AS predchozi_rok_gdp, 
    LAG (ts.population) OVER (
      PARTITION BY ts.country 
      ORDER BY 
        ts.year
    ) AS predchozi_rok_population, 
    ts.category_code AS kod_potr 
  FROM 
    t_vera_vavrincova_project_SQL_secondary_final ts
) 
SELECT 
  predch_hdp.year, 
  predch_hdp.country, 
  predch_hdp.gdp, 
  predch_hdp.predchozi_rok_gdp, 
  CASE WHEN (
    predch_hdp.predchozi_rok_gdp < predch_hdp.gdp
  ) THEN 'HDP zvýšeno' WHEN (
    predch_hdp.predchozi_rok_gdp > predch_hdp.gdp
  ) THEN 'HDP sníženo' ELSE 'HDP stejné' END AS zmena_hdp, 
  predch_hdp.gini, 
  predch_hdp.kod_potr, 
  prumerceny_p_rok.prumer_ceny_potr, 
  predch_hdp.population, 
  predch_hdp.predchozi_rok_population, 
  CASE WHEN (
    predch_hdp.predchozi_rok_population < predch_hdp.population
  ) THEN 'populace zvýšena' WHEN (
    predch_hdp.predchozi_rok_population > predch_hdp.population
  ) THEN 'populace snížena' ELSE 'populace stejná' END AS zmena_population 
FROM 
  predch_hdp 
  LEFT JOIN prumerceny_p_rok ON predch_hdp.YEAR = prumerceny_p_rok.rok_p 
WHERE 
  predch_hdp.country IN (
    'France', 'Italy', 'Czech Republic', 
    'Slovakia'
  ) 
  AND predch_hdp.predchozi_rok_gdp IS NOT NULL -- první rok nemá předchozí rok
  AND predch_hdp.YEAR BETWEEN 2006 
  AND 2018 -- období pro porovnání cen potravin a mezd - viz.úkoly 1-4
ORDER BY 
  predch_hdp.YEAR ASC, 
  predch_hdp.gdp, 
  predch_hdp.country DESC;
  --v sekundární tabulce jsou řádky pro všechny potraviny a všechna měřená období
  --můj ntb nezvládne vyčíslit všechny státy, předpokládám se pak přeplní RAM,
  --takže uvažuji jen 4 státy Evropy 'France','Italy','Czech Republic','Slovakia'.
         