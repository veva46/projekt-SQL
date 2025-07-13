-- projekt DA SQL Engeto
-- Věra Vavrincová
-- 
--Sekundární tabulka

--CREATE TABLE t_vera_vavrincova_project_SQL_secondary_final AS  
SELECT 
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
      AND e.country LIKE '%Czech%'   
   ORDER BY TvvPr.rokm, TvvPr.kvartalm, country, odvetvi, potravina, TvvPr.prumer_cena_potr   
;      

SELECT * FROM t_vera_vavrincova_project_SQL_secondary_final;
