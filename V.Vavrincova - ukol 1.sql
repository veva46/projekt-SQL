-- projekt DA SQL Engeto
-- Věra Vavrincová
-- úkol 1
-- Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají?

         
--analýza z tabulek Engeta:

SELECT 
  cp.industry_branch_code, 
  cpib.name, 
  cp.payroll_year, 
  ROUND(
    AVG(cp.value), 
    0
  ) AS prumerna_mzda_za_odvetvi 
FROM 
  czechia_payroll cp 
  JOIN czechia_payroll_industry_branch cpib -- spojí druhou tabulku s názvy odvětví
  ON cp.industry_branch_code = cpib.code 
WHERE 
  cp.value_type_code = 5958 -- kód 5958 udává průměrnou hrubou mzdu na zaměstnance
  AND cp.industry_branch_code IS NOT NULL --odstranění řádků bez udání odvětví
GROUP BY 
  cp.industry_branch_code, 
  cp.payroll_year, 
  cpib.name 
ORDER BY 
  cp.payroll_year ASC, 
  prumerna_mzda_za_odvetvi ASC;


SELECT 
  cp.industry_branch_code 
FROM 
  czechia_payroll cp 
WHERE 
  cp.value_type_code = 5958 
  AND cp.value IS NULL;
-- kontrola, že u mezd (tj.cp.value_type_code = '5958')je vždy uvedena hodnota mzdy
-- správně je, že nevrátí žádný záznam, tj. není nulová hodnota    



WITH trendy_mzda AS (
  -- tento select ukáže trend růstu nebo poklesu mezd dle odvětví a roků 
  SELECT 
    cp2.industry_branch_code AS kod_odvetvi, 
    cpib.name AS odvetvi, 
    cp2.payroll_year AS rok, 
    ROUND(
      AVG(cp2.value), 
      0
    ) AS prumerna_mzda_za_odvetvi, 
    -- průměrná mzda podle odvětví
    LAG(
      ROUND(
        AVG(cp2.value), 
        0
      )
    ) OVER (
      PARTITION BY cp2.industry_branch_code 
      ORDER BY 
        cp2.payroll_year
    ) AS predchozi_mzda, 
    ROUND(
      AVG(cp2.value), 
      0
    ) - LAG(
      ROUND(
        AVG(cp2.value), 
        0
      )
    ) OVER (
      PARTITION BY cp2.industry_branch_code 
      ORDER BY 
        cp2.payroll_year
    ) AS rozdil_mzdy, 
    --vypočítá rozdíl dvou po sobě jdoucích řádků
    CASE WHEN ROUND(
      AVG(cp2.value), 
      0
    ) > LAG(
      ROUND(
        AVG(cp2.value), 
        0
      )
    ) OVER (
      PARTITION BY cp2.industry_branch_code 
      ORDER BY 
        cp2.payroll_year
    ) THEN 'Růst' WHEN ROUND(
      AVG(cp2.value), 
      0
    ) < LAG(
      ROUND(
        AVG(cp2.value), 
        0
      )
    ) OVER (
      PARTITION BY cp2.industry_branch_code 
      ORDER BY 
        cp2.payroll_year
    ) THEN 'Pokles' ELSE 'Beze změny' END AS trend 
  FROM 
    czechia_payroll cp2 
    JOIN czechia_payroll_industry_branch cpib ON cp2.industry_branch_code = cpib.code 
  WHERE 
    cp2.value_type_code = 5958 -- kód 5958 udává průměrnou hrubou mzdu na zaměstnance
  GROUP BY 
    cp2.industry_branch_code, 
    cpib.name, 
    cp2.payroll_year
) 
SELECT 
  * 
FROM 
  trendy_mzda 
WHERE 
  trendy_mzda.kod_odvetvi IS NOT NULL --odstranění řádků bez udání odvětví
  AND trendy_mzda.predchozi_mzda IS NOT NULL --řádky r.2000, kdy neexistuje předchozí rok
ORDER BY 
  trendy_mzda.trend DESC, 
  trendy_mzda.rozdil_mzdy DESC, 
  trendy_mzda.kod_odvetvi ASC, 
  trendy_mzda.rok;

 
--analýza z primární tabulky:

WITH trendy_mzda AS (
  -- tento select ukáže trend růstu nebo poklesu mezd dle odvětví a roků 
  SELECT 
    tpr.industry_branch_code AS kod_odvetvi, 
    tpr.odvetvi, 
    tpr.rok_m, 
    ROUND(
      AVG(tpr.prumer_mzda), 
      0
    ) AS prumerna_mzda_za_odvetvi, 
    LAG(
      ROUND(
        AVG(tpr.prumer_mzda), 
        0
      )
    ) OVER (
      PARTITION BY tpr.industry_branch_code 
      ORDER BY 
        tpr.rok_m
    ) AS predchozi_mzda, 
    ROUND(
      AVG(tpr.prumer_mzda), 
      0
    ) - LAG(
      ROUND(
        AVG(tpr.prumer_mzda), 
        0
      )
    ) OVER (
      PARTITION BY tpr.industry_branch_code 
      ORDER BY 
        tpr.rok_m
    ) AS rozdil_mzdy, 
    --vypočítá rozdíl dvou po sobě jdoucích řádků
    CASE WHEN ROUND(
      AVG(tpr.prumer_mzda), 
      0
    ) > LAG(
      ROUND(
        AVG(tpr.prumer_mzda), 
        0
      )
    ) OVER (
      PARTITION BY tpr.industry_branch_code 
      ORDER BY 
        tpr.rok_m
    ) THEN 'Růst' WHEN ROUND(
      AVG(tpr.prumer_mzda), 
      0
    ) < LAG(
      ROUND(
        AVG(tpr.prumer_mzda), 
        0
      )
    ) OVER (
      PARTITION BY tpr.industry_branch_code 
      ORDER BY 
        tpr.rok_m
    ) THEN 'Pokles' ELSE 'Beze změny' END AS trend 
  FROM 
    t_vera_vavrincova_project_SQL_primary_final tpr 
  WHERE 
    tpr.kod_mzdy = 5958 -- kód 5958 udává průměrnou hrubou mzdu na zaměstnance
  GROUP BY 
    tpr.industry_branch_code, 
    tpr.odvetvi, 
    tpr.rok_m
) 
SELECT 
  * 
FROM 
  trendy_mzda 
WHERE 
  trendy_mzda.kod_odvetvi IS NOT NULL --odstranění řádků bez udání odvětví
  AND trendy_mzda.predchozi_mzda IS NOT NULL --řádky r.2006, kdy neexistuje předchozí rok
ORDER BY 
  trendy_mzda.trend DESC, 
  trendy_mzda.rozdil_mzdy DESC, 
  trendy_mzda.rok_m, 
  trendy_mzda.kod_odvetvi;
         
	-- s každým dalším rokem je ve většině odvětví vždy vzestup průměrné mzdy 
    -- pokles je pouze u 20-ti případů - nejvíc u odvětví B-tj. Těžba a dobývání
    -- pokud se vyfiltruje podle roku a odvětví, pak je dobře vidět, které odvětví, který rok stagnovalo
    
         