-- projekt DA SQL Engeto
-- Věra Vavrincová
-- úkol 1
-- Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají?

SELECT  
   cp.industry_branch_code,
   cpib.name,
   cp.payroll_year,
   ROUND(AVG(cp.value),0) AS prumerna_mzda_za_odvetvi
FROM czechia_payroll cp
  JOIN czechia_payroll_industry_branch cpib -- spojí druhou tabulku s názvy odvětví
    ON cp.industry_branch_code = cpib.code
  WHERE cp.value_type_code = '5958' -- kód 5958 udává průměrnou hrubou mzdu na zaměstnance
    AND cp.industry_branch_code IS NOT NULL --odstranění řádků bez udání odvětví
  GROUP BY cp.industry_branch_code, cp.payroll_year, cpib.name 
  ORDER BY cp.payroll_year ASC, 
		 prumerna_mzda_za_odvetvi ASC;
-- tento select vypíše kód odvětví, rok, průměrnou mzdu 
-- seskepeno/sgrupováno podle odvětví a roku
-- seřazeno podle roku, a vzestupně podle průměrné mzdy


SELECT  
   cp.industry_branch_code
FROM czechia_payroll cp
  WHERE cp.value_type_code = '5958' 
    AND cp.value IS NULL;
-- kontrola, že u mezd (tj.cp.value_type_code = '5958')je vždy uvedena hodnota mzdy
-- správně je, že nevrátí žádný záznam, tj. není nulová hodnota    


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
  -- seřazeno podle odvětví, vzestupně podle roku a vzestupně podle prům.mzdy

SELECT  
-- tento select ukáže podle řazení sl.trend růst nebo pokles mezd dle odvětví a roků
   cp.industry_branch_code,
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
  WHERE cp.value_type_code = '5958' -- kód 5958 udává průměrnou hrubou mzdu na zaměstnance
    AND cp.industry_branch_code IS NOT NULL   --odstranění řádků bez udání odvětví
  GROUP BY cp.industry_branch_code, cp.payroll_year
  ORDER BY trend DESC,
         cp.industry_branch_code ASC;
         -- seřazeno podle trendu a odvětví
		 -- s každým dalším rokem je ve většině odvětví vždy vzestup průměrné mzdy 
         -- od řádku 370 je vidět pokles mzdy oproti předchozímu roku
         -- pokles je pouze u 10-ti případů - nejvíc u odvětví B-tj. Těžba a dobývání
         -- od řádku 400 je uveden první zkoumaný rok tj. r.2000, 
            -- proto je zde trend "Beze změny" neboť se s předchozím rokem nesrovnával