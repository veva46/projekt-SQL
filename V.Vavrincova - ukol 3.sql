-- projekt DA SQL Engeto
-- Věra Vavrincová
-- úkol 3
-- Která kategorie potravin zdražuje nejpomaleji (je u ní nejnižší percentuální meziroční nárůst)? 

--Meziroční nárůst = 100x((hodnota v roce N - hodnota v roce N-1)/(hodnota v roce N-1))
--srovnáváme každé dva roky za sebou
	--funkce LAG() umožňuje "vidět předchozí hodnotu" pro každý řádek v časové řadě

--analýza z tabulek Engeta:

SELECT 
  -- průměrné ceny potravin v letech
  EXTRACT(
    YEAR 
    FROM 
      cp.date_from :: DATE
  ) AS rok, 
  cp.category_code, 
  cpc.name, 
  ROUND(
    AVG(cp.value)
  ) AS prumerna_cena 
FROM 
  czechia_price cp 
  JOIN czechia_price_category cpc ON cp.category_code = cpc.code 
GROUP BY 
  cp.category_code, 
  cpc.name, 
  rok 
ORDER BY 
  name ASC;



WITH -- průměrné ceny potravin v letech
prumery AS (
  SELECT 
    EXTRACT(
      YEAR 
      FROM 
        cp.date_from :: DATE
    ) AS rok, 
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
    rok 
  ORDER BY 
    name ASC
), 
srovnani AS (
  SELECT 
    prumery.rok, 
    prumery.kategorie, 
    prumery.nazev, 
    prumery.prumerna_cena, 
    LAG (prumerna_cena) OVER (
      PARTITION BY kategorie 
      ORDER BY 
        rok
    ) AS predchozi_cena 
  FROM 
    prumery
), 
mezirust AS (
  SELECT 
    srovnani.rok, 
    srovnani.kategorie, 
    --rok 2006 má mezinárust NULL - neexistuje předchozí rok
    srovnani.nazev, 
    -- jakostní bílé víno je udáváno až od roku 2015
    srovnani.prumerna_cena, 
    srovnani.predchozi_cena, 
    CASE WHEN (prumerna_cena - predchozi_cena) < 0 THEN 'zlevněno' WHEN (prumerna_cena - predchozi_cena) > 0 THEN 'zdraženo' WHEN (prumerna_cena - predchozi_cena) = 0 THEN 'stejná cena' ELSE 'nesrovnatelné s předchozím rokem' END AS zmena_ceny 
  FROM 
    srovnani
), 
procenta AS (
  SELECT 
    mezirust.rok, 
    mezirust.kategorie, 
    mezirust.nazev, 
    mezirust.prumerna_cena, 
    mezirust.predchozi_cena, 
    mezirust.zmena_ceny, 
    ROUND(
      100 *(
        (prumerna_cena - predchozi_cena)/ predchozi_cena
      )
    ) AS narust_ceny_procenta 
  FROM 
    mezirust
) 
SELECT 
  procenta.rok, 
  procenta.kategorie, 
  procenta.nazev, 
  procenta.prumerna_cena, 
  procenta.predchozi_cena, 
  procenta.zmena_ceny, 
  procenta.narust_ceny_procenta 
FROM 
  procenta 
WHERE 
  predchozi_cena IS NOT NULL --AND zmena_ceny = 'zdraženo'          
ORDER BY 
  rok, 
  kategorie, 
  narust_ceny_procenta ASC;  
-- je sledováno 26 potravin (+1 od r.2015)
-- je sledováno po dobu 12ti let (2006-2018)
-- meziroční růst cen potravin je větší než 10% u 68 položek (potravina/rok)
-- u 95 položek (potravina/rok) došlo ke snížení ceny (1-31% poklesu oproti předchozímu roku)
-- u 60 položek (potravina/rok) se cena nezměnila oproti předchozímu roku
    

WITH --procentuální růst cen potravin
prumery AS (
  SELECT 
    -- průměrné ceny potravin v letech
    EXTRACT(
      YEAR 
      FROM 
        cp.date_from :: DATE
    ) AS rok, 
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
    rok 
  ORDER BY 
    name ASC
), 
srovnani AS (
  SELECT 
    prumery.rok, 
    prumery.kategorie, 
    prumery.nazev, 
    prumery.prumerna_cena, 
    LAG (prumerna_cena) OVER (
      PARTITION BY kategorie 
      ORDER BY 
        rok
    ) AS predchozi_cena 
  FROM 
    prumery
), 
mezirust AS (
  SELECT 
    srovnani.rok, 
    srovnani.kategorie, 
    srovnani.nazev, 
    srovnani.prumerna_cena, 
    srovnani.predchozi_cena, 
    CASE WHEN (prumerna_cena - predchozi_cena) < 0 THEN 'zlevněno' WHEN (prumerna_cena - predchozi_cena) > 0 THEN 'zdraženo' -- oproti předchozímu roku
    WHEN (prumerna_cena - predchozi_cena) = 0 THEN 'stejná cena' ELSE 'nesrovnatelné s předchozím rokem' END AS zmena_ceny 
  FROM 
    srovnani
), 
procenta AS (
  SELECT 
    mezirust.rok, 
    mezirust.kategorie, 
    mezirust.nazev, 
    mezirust.prumerna_cena, 
    mezirust.predchozi_cena, 
    mezirust.zmena_ceny, 
    ROUND(
      100 *(
        (prumerna_cena - predchozi_cena)/ predchozi_cena
      )
    ) AS narust_ceny_procenta 
  FROM 
    mezirust
), 
prumer_rustu_cen AS (
  SELECT 
    procenta.rok, 
    procenta.kategorie, 
    procenta.nazev, 
    procenta.prumerna_cena, 
    procenta.predchozi_cena, 
    procenta.zmena_ceny, 
    AVG(procenta.narust_ceny_procenta) AS prumer_rustu 
  FROM 
    procenta 
  GROUP BY 
    kategorie, 
    nazev, 
    rok, 
    prumerna_cena, 
    predchozi_cena, 
    zmena_ceny 
  ORDER BY 
    rok, 
    kategorie
) 
SELECT 
  prumer_rustu_cen.rok, 
  --prumer_rustu_cen.kategorie,
  prumer_rustu_cen.nazev, 
  prumer_rustu_cen.prumerna_cena, 
  prumer_rustu_cen.predchozi_cena, 
  prumer_rustu_cen.zmena_ceny, 
  prumer_rustu_cen.prumer_rustu 
FROM 
  prumer_rustu_cen 
WHERE 
  predchozi_cena IS NOT NULL 
  AND zmena_ceny = 'zdraženo' --- uvažuji jen zdražované položky
ORDER BY 
  prumer_rustu, 
  rok, 
  nazev ASC;
      
--nejnižší percentuální meziroční nárust ceny potraviny 
   -- byl zaznamenaný v letech 2007,2008, 2012, 2015, 2016, 2018 u potravin:
   -- Rostlinný roztíratelný tuk, Kapr živý, Hovězí maso zadní bez kosti,
   -- Šunkový salám, Kuřata kuchaná celá  
   -- šlo o 1% nárustu ceny.
--tedy nejpomaleji zdražili v těchto letech tyto výše vyjmenované potraviny.
--Ale některé tyto potraviny v jiném roce zdražily více:
   --např. Rostlinný roztíratelný tuk roce 2008 až o 20% oproti předchozímu roku
   --např. Kapr živý v roce 2007 až o 14%					         
   --např. Hovězí maso zadní bez kosti v roce 2012 až o 11%
   --např. Kuřata kuchaná celá v roce 2007 až o 15%


--analýza z primární tabulky:

WITH --procentuální růst cen potravin
prumery AS (
  SELECT 
    -- průměrné ceny potravin v letech
    tpr.rok_p, 
    tpr.category_code AS kategorie, 
    tpr.potravina AS nazev, 
    tpr.prumer_cena_potr 
  FROM 
    t_vera_vavrincova_project_SQL_primary_final tpr 
  ORDER BY 
    nazev ASC
), 
srovnani AS (
  SELECT 
    prumery.rok_p, 
    prumery.kategorie, 
    prumery.nazev, 
    prumery.prumer_cena_potr, 
    LAG (prumery.prumer_cena_potr) OVER (
      PARTITION BY kategorie 
      ORDER BY 
        rok_p
    ) AS predchozi_cena 
  FROM 
    prumery
), 
mezirust AS (
  SELECT 
    srovnani.rok_p, 
    srovnani.kategorie, 
    srovnani.nazev, 
    srovnani.prumer_cena_potr, 
    srovnani.predchozi_cena, 
    CASE WHEN (
      prumer_cena_potr - predchozi_cena
    ) < 0 THEN 'zlevněno' WHEN (
      prumer_cena_potr - predchozi_cena
    ) > 0 THEN 'zdraženo' -- oproti předchozímu roku
    WHEN (
      prumer_cena_potr - predchozi_cena
    ) = 0 THEN 'stejná cena' ELSE 'nesrovnatelné s předchozím rokem' END AS zmena_ceny 
  FROM 
    srovnani
), 
procenta AS (
  SELECT 
    mezirust.rok_p, 
    mezirust.kategorie, 
    mezirust.nazev, 
    mezirust.prumer_cena_potr, 
    mezirust.predchozi_cena, 
    mezirust.zmena_ceny, 
    ROUND(
      100 *(
        (
          prumer_cena_potr - predchozi_cena
        )/ predchozi_cena
      )
    ) AS narust_ceny_procenta 
  FROM 
    mezirust
), 
prumer_rustu_cen AS (
  SELECT 
    procenta.rok_p, 
    procenta.kategorie, 
    procenta.nazev, 
    procenta.prumer_cena_potr, 
    procenta.predchozi_cena, 
    procenta.zmena_ceny, 
    AVG(procenta.narust_ceny_procenta) AS prumer_rustu 
  FROM 
    procenta 
  GROUP BY 
    kategorie, 
    nazev, 
    rok_p, 
    prumer_cena_potr, 
    predchozi_cena, 
    zmena_ceny 
  ORDER BY 
    rok_p, 
    kategorie
) 
SELECT 
  prumer_rustu_cen.rok_p, 
  prumer_rustu_cen.nazev, 
  prumer_rustu_cen.prumer_cena_potr, 
  prumer_rustu_cen.predchozi_cena, 
  prumer_rustu_cen.zmena_ceny, 
  prumer_rustu_cen.prumer_rustu 
FROM 
  prumer_rustu_cen 
WHERE 
  predchozi_cena IS NOT NULL 
  AND zmena_ceny = 'zdraženo' --- uvažuji jen zdražované položky
ORDER BY 
  prumer_rustu, 
  rok_p, 
  nazev ASC;
