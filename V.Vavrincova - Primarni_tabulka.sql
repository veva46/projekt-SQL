-- projekt DA SQL Engeto
-- Věra Vavrincová

--Primární tabulka


CREATE TABLE t_vera_vavrincova_project_SQL_primary_final AS 
WITH 
potraviny AS (
  SELECT 
    DATE(cp.date_from :: DATE) AS datum_od, 
    DATE(cp.date_to :: DATE) AS datum_do, 
    EXTRACT(
      QUARTER 
      FROM 
        cp.date_from :: DATE
    ) AS kvartal_p, 
    -- převede datum do kvartálu v roce
    EXTRACT(
      YEAR 
      FROM 
        cp.date_from :: DATE
    ) AS rok_p, 
    -- převede datum do roku
    ROUND(
      AVG(cp.value)
    ) AS prumer_cena_potr, 
    -- průměrná cena jednotlivé potraviny podle období
    cp.category_code, 
    cpc.name AS potravina, 
    cpc.price_unit AS jednotka 
  FROM 
    czechia_price cp 
    JOIN czechia_price_category cpc ON cp.category_code = cpc.code 
  GROUP BY 
    cp.category_code, 
    datum_od, 
    datum_do, 
    cpc.name, 
    rok_p, 
    kvartal_p, 
    jednotka
), 
mzdy AS (
  SELECT 
    cp2.payroll_quarter AS kvartal_m, 
    cp2.payroll_year AS rok_m, 
    AVG(cp2.value) AS prumer_mzda, 
    -- průměrná mzda podle odvětví, roku a kvartálu
    cpib.name AS odvetvi, 
    cpvt.code AS kod_mzdy, 
    --cpvt.code pokud je 5958, pak se jedná o hrubou mzdu zaměstnance
    cp2.industry_branch_code 
  FROM 
    czechia_payroll cp2 
    JOIN czechia_payroll_industry_branch cpib ON cp2.industry_branch_code = cpib.code 
    JOIN czechia_payroll_value_type cpvt ON cp2.value_type_code = cpvt.code 
    JOIN czechia_payroll_calculation cpc2 ON cp2.calculation_code = cpc2.code 
  WHERE 
    cp2.value IS NOT NULL -- eliminace chyb v tabulce - absence mzdy
    AND cp2.value_type_code = 5958 -- kód 5958 udává průměrnou hrubou mzdu na zaměstnance
  GROUP BY 
    cpib.name, 
    cp2.payroll_year, 
    cp2.payroll_quarter, 
    cpvt.code, 
    cp2.industry_branch_code
) 
SELECT 
  * 
FROM 
  mzdy 
  JOIN potraviny ON mzdy.kvartal_m = potraviny.kvartal_p 
  AND mzdy.rok_m = potraviny.rok_p 
ORDER BY 
  mzdy.rok_m, 
  mzdy.kvartal_m, 
  mzdy.odvetvi, 
  potraviny.datum_od, 
  potraviny.potravina;

    
   

SELECT * FROM t_vera_vavrincova_project_SQL_primary_final;

