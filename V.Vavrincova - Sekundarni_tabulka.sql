-- projekt DA SQL Engeto
-- Věra Vavrincová

--Sekundární tabulka

CREATE TABLE t_vera_vavrincova_project_SQL_secondary_final AS 
SELECT 
  country, 
  year, 
  population, 
  gini, 
  gdp, 
  tpr.rok_m, 
  tpr.kvartal_m, 
  tpr.prumer_mzda, 
  tpr.odvetvi, 
  tpr.rok_p, 
  tpr.kvartal_p, 
  tpr.prumer_cena_potr, 
  tpr.category_code, 
  tpr.potravina, 
  tpr.jednotka 
FROM 
  economies e 
  JOIN t_vera_vavrincova_project_sql_primary_final tpr ON e.year = tpr.rok_m 
WHERE 
  tpr.kvartal_m = tpr.kvartal_p 
  AND tpr.rok_m = tpr.rok_p 
  AND e.country LIKE '%Czech%' --pro Českou republiku
ORDER BY 
  tpr.rok_m, 
  tpr.kvartal_m, 
  country, 
  odvetvi, 
  potravina, 
  tpr.prumer_cena_potr;


SELECT * FROM t_vera_vavrincova_project_SQL_secondary_final;