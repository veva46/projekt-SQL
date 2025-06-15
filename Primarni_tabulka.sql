-- projekt DA SQL Engeto
-- Věra Vavrincová

--Primární tabulka

--CREATE TABLE t_vera_vavrincova_project_SQL_primary_final AS  -- takto se vytvořila primární tabulka 
WITH 
  potraviny AS (
 SELECT 
       DATE(cp.date_from::DATE) AS datum_OD,
       DATE(cp.date_to::DATE) AS datum_DO,
       EXTRACT(QUARTER FROM cp.date_from::DATE) AS kvartalP,   -- převede datum do kvartálu v roce
       EXTRACT(YEAR FROM cp.date_from::DATE) AS rokP,          -- převede datum do roku
       ROUND(AVG(cp.value)) AS prumer_cena_potr,   -- průměrná cena jednotlivé potraviny podle období, roku a kvartálu
       cp.category_code,
       cpc.name AS potravina,
       cpc.price_unit AS jednotka
 FROM czechia_price cp
     JOIN czechia_price_category cpc
       ON cp.category_code = cpc.code
     GROUP BY cp.category_code, cpc.name, datum_OD, datum_DO, rokP, kvartalP, jednotka
 ),
 mzdy AS (
 SELECT 
      cp2.payroll_quarter AS kvartalM,
      cp2.payroll_year AS rokM,
      AVG(cp2.value) AS prumer_mzda,   -- průměrná mzda podle odvětví, roku a kvartálu
      cpib.name AS odvetvi
 FROM czechia_payroll cp2
     JOIN czechia_payroll_industry_branch cpib 
       ON cp2.industry_branch_code = cpib.code
     JOIN czechia_payroll_value_type cpvt
       ON cp2.value_type_code = cpvt.code
     JOIN czechia_payroll_calculation cpc2 
       ON cp2.calculation_code = cpc2.code
     WHERE cp2.value IS NOT NULL          -- eliminace chyb v tabulce - absence mzdy
       AND cp2.value_type_code = '5958'   -- jen hrubá mzda
     GROUP BY cpib.name, cp2.payroll_year, cp2.payroll_quarter
 )
SELECT   
   *
FROM mzdy
  JOIN potraviny
     ON mzdy.kvartalM = potraviny.kvartalP AND mzdy.rokM = potraviny.rokP
  ORDER BY mzdy.rokm, mzdy.kvartalM, potraviny.datum_OD, mzdy.odvetvi;
    
       



SELECT  
   cp.industry_branch_code,
   cpib.name,
   cp.payroll_year,
   ROUND(AVG(cp.value), 0) AS prumerna_mzda_za_odvetvi,
   LAG(ROUND(AVG(cp.value), 0)) OVER (      --LAG vrátí hodnotu z předchozího řádku
       PARTITION BY cp.industry_branch_code --každé odvětví tvoří svou vlastní skupinu
       ORDER BY cp.payroll_year  --seřazení podle roku v dané skupině odvětví
   ) AS predchozi_mzda,
   ROUND(AVG(cp.value), 0) 
     - LAG(ROUND(AVG(cp.value), 0)) OVER (
         PARTITION BY cp.industry_branch_code 
         ORDER BY cp.payroll_year
     ) AS rozdil_mzdy,  --vypočítá rozdíl dvou po sobě jdoucích řádků
   CASE
     WHEN ROUND(AVG(cp.value), 0) > LAG(ROUND(AVG(cp.value), 0)) OVER (
            PARTITION BY cp.industry_branch_code 
            ORDER BY cp.payroll_year 
         ) THEN 'Růst'
     WHEN ROUND(AVG(cp.value), 0) < LAG(ROUND(AVG(cp.value), 0)) OVER (
            PARTITION BY cp.industry_branch_code 
            ORDER BY cp.payroll_year
         ) THEN 'Pokles'
     ELSE 'Beze změny'
   END AS trend
FROM czechia_payroll cp
 JOIN czechia_payroll_industry_branch cpib 
   ON cp.industry_branch_code = cpib.code
 WHERE cp.value_type_code = '5958' -- kód 5958 udává průměrnou hrubou mzdu na zaměstnance
  AND cp.industry_branch_code IS NOT NULL   --odstranění řádků bez udání odvětví
 GROUP BY cp.industry_branch_code, cp.payroll_year,cpib.name
 ORDER BY cp.industry_branch_code,
         cp.payroll_year ASC, 
         prumerna_mzda_za_odvetvi ASC;