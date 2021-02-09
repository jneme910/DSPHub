 USE sdmONLINE
 
 DROP TABLE IF EXISTS #AoiTablePoint
 DROP TABLE IF EXISTS #AoiMUIn
 DROP TABLE IF EXISTS #TempTex1
 DROP TABLE IF EXISTS #TempTex2
 DROP TABLE IF EXISTS #TempTex3
 DROP TABLE IF EXISTS #tex
 DROP TABLE IF EXISTS #Firstoftex
 DROP TABLE IF EXISTS #NoDuffTemp1
 DROP TABLE IF EXISTS #NoDuffTemp2
 DROP TABLE IF EXISTS #NoDuffTemp3
 DROP TABLE IF EXISTS #NoDufftex
 DROP TABLE IF EXISTS #FirstofNoDufftex
 DROP TABLE IF EXISTS #muagTemp
 DROP TABLE IF EXISTS #muagTemp
 DROP TABLE IF EXISTS #dspssurgo
 DECLARE @aoiGeom Geometry;
 DECLARE @aoiGeomFixed Geometry;

-- Create AOI table with polygon geometry. Coordinate system must be WGS1984 (EPSG 4326)
CREATE TABLE #AoiTablePoint
    ( aoiid INT IDENTITY (1,1),
    pedlabsampnum CHAR(20),
    aoigeom GEOMETRY )

SELECT @aoiGeom = geometry::STGeomFromText('POINT (-91.5366669 45.3494453)', 4326);  
SELECT @aoiGeomFixed = @aoiGeom.MakeValid().STUnion(@aoiGeom.STStartPoint()); 
INSERT INTO #AoiTablePoint ( pedlabsampnum, aoigeom ) 
VALUES ('92P0439', @aoiGeomFixed);

SELECT @aoiGeom = geometry::STGeomFromText('POINT (-92.0802765 45.6877785)', 4326);  
SELECT @aoiGeomFixed = @aoiGeom.MakeValid().STUnion(@aoiGeom.STStartPoint()); 
INSERT INTO #AoiTablePoint ( pedlabsampnum, aoigeom ) 
VALUES ('90P0546', @aoiGeomFixed);


CREATE TABLE #AoiMUIn
    ( aoiid INT ,
    pedlabsampnum CHAR(20),
	 mukey  INT,
    aoigeom GEOMETRY )


-- Populate #AoiMUIn  table with intersected soil polygon geometry
INSERT INTO #AoiMUIn (aoiid,  pedlabsampnum , mukey, aoigeom)
    SELECT A.aoiid, A.pedlabsampnum, M.mukey, M.mupolygongeo.STIntersection(A.aoigeom ) AS aoigeom
    FROM mupolygon M, #AoiTablePoint A
    WHERE mupolygongeo.STIntersects(A.aoigeom ) = 1

--Surface with Duff
/*Surface Texture Groups:
	• Class T1 sand, loamy sand, sandy loam (with <8% clay)
	• Class T2 sandy loam (with clay >8%), sandy clay loam, loam
	• Class T3 silt loam, silt
	• Class T4 sandy clay, clay loam, silty clay loam, silty clay, clay (<60%)
	• Class T5 clay (>60%)
*/
SELECT mapunit.mukey, Sum(component.comppct_r) AS SumOfcomppct_r, chorizon.hzdept_r, CASE WHEN claytotal_r < 8 AND chtexturegrp.texture = 'SL' THEN 'sandy loam (with <8% clay)'
WHEN claytotal_r >= 8 AND chtexturegrp.texture = 'SL' THEN 'sandy loam (with clay >8%)'
WHEN claytotal_r < 60 AND chtexturegrp.texture = 'C' THEN 'clay (<60%)'
WHEN claytotal_r >= 60 AND chtexturegrp.texture = 'C' THEN 'clay (>60%)'ELSE chtexturegrp.texture END AS texture , 

chtexturegrp.rvindicator
INTO #TempTex1
FROM mapunit
INNER JOIN #AoiMUIn ON #AoiMUIn.mukey=mapunit.mukey
INNER JOIN (component INNER JOIN (chorizon INNER JOIN chtexturegrp ON chorizon.chkey = chtexturegrp.chkey) ON component.cokey = chorizon.cokey) ON #AoiMUIn.mukey = component.mukey
GROUP BY mapunit.musym, mapunit.muname, mapunit.mukey, chorizon.hzdept_r, texture, claytotal_r, chtexturegrp.rvindicator
HAVING (((chorizon.hzdept_r)=0) AND ((chtexturegrp.rvindicator)='yes'))

SELECT Max(#TempTex1.SumOfcomppct_r) AS MaxOfSumOfcomppct_r, #TempTex1.mukey
INTO #TempTex2
FROM #TempTex1 GROUP BY #TempTex1.mukey;

SELECT #TempTex1.texture, #TempTex1.mukey
INTO #TempTex3
FROM #TempTex1 INNER JOIN #TempTex2 ON (#TempTex1.mukey=#TempTex2.mukey) AND (#TempTex1.SumOfcomppct_r=#TempTex2.MaxOfSumOfcomppct_r);

SELECT mapunit.musym, #TempTex3.texture, mapunit.muname, mapunit.mukey
INTO #tex
FROM legend INNER JOIN (#TempTex3 RIGHT JOIN mapunit ON #TempTex3.mukey = mapunit.mukey) ON legend.lkey = mapunit.lkey
GROUP BY mapunit.musym, mapunit.muname, mapunit.mukey, legend.areasymbol, #TempTex3.texture;
WITH #Firstoftex1 AS (Select mukey, texture, rn = row_number() OVER (PARTITION BY mukey ORDER BY texture) From #tex)

Select texture, mukey
INTO #Firstoftex
From #Firstoftex1
Where rn=1

--Texture W\O Duff
--Forested Soils are often described with thin duff layers.  Often, the duff layer is destroyed; therefore knowing the first mineral layer is beneficial. This field provides the texture of the first mineral layer below the duff layer.
/*Surface Texture Groups:
	• Class T1 sand, loamy sand, sandy loam (with <8% clay)
	• Class T2 sandy loam (with clay >8%), sandy clay loam, loam
	• Class T3 silt loam, silt
	• Class T4 sandy clay, clay loam, silty clay loam, silty clay, clay (<60%)
	• Class T5 clay (>60%)
*/
SELECT mapunit.mukey, component.comppct_r, chorizon.hzdept_r, component.cokey, chorizon.chkey, 
CASE WHEN claytotal_r < 8 AND chtexturegrp.texture = 'SL' THEN 'sandy loam (with <8% clay)'
WHEN claytotal_r >= 8 AND chtexturegrp.texture = 'SL' THEN 'sandy loam (with clay >8%)'
WHEN claytotal_r < 60 AND chtexturegrp.texture = 'C' THEN 'clay (<60%)'
WHEN claytotal_r >= 60 AND chtexturegrp.texture = 'C' THEN 'clay (>60%)'ELSE chtexturegrp.texture END AS texture , 


chtexturegrp.rvindicator, component.majcompflag
INTO #NoDuffTemp1
FROM (legend INNER JOIN (mapunit LEFT JOIN component ON mapunit.mukey = component.mukey) ON legend.lkey = mapunit.lkey) LEFT JOIN (chorizon LEFT JOIN chtexturegrp ON chorizon.chkey = chtexturegrp.chkey) ON component.cokey = chorizon.cokey
INNER JOIN  #AoiMUIn ON #AoiMUIn.mukey=mapunit.mukey
WHERE (((chorizon.hzdept_r)=(SELECT Min(chorizon.hzdept_r) AS MinOfhzdept_r
FROM chorizon LEFT JOIN chtexturegrp ON chorizon.chkey = chtexturegrp.chkey
Where chtexturegrp.texture Not In ('SPM','HPM', 'MPM') AND chtexturegrp.rvindicator='Yes' AND component.cokey = chorizon.cokey )) AND ((chtexturegrp.rvindicator)='Yes')  AND ((component.majcompflag)='Yes'))
ORDER BY legend.areasymbol, mapunit.musym, chorizon.hzdept_r

SELECT #NoDuffTemp1.mukey, Sum(#NoDuffTemp1.comppct_r) AS SumOfcomppct_r, #NoDuffTemp1.texture
INTO #NoDuffTemp2
FROM #NoDuffTemp1
GROUP BY #NoDuffTemp1.mukey, #NoDuffTemp1.texture

SELECT #NoDuffTemp2.mukey, Max(#NoDuffTemp2.SumOfcomppct_r) AS MaxOfSumOfcomppct_r
INTO #NoDuffTemp3
FROM #NoDuffTemp2
GROUP BY #NoDuffTemp2.mukey

SELECT #NoDuffTemp3.mukey, #NoDuffTemp2.texture
INTO #NoDufftex
FROM #NoDuffTemp2 INNER JOIN #NoDuffTemp3 ON (#NoDuffTemp2.SumOfcomppct_r = #NoDuffTemp3.MaxOfSumOfcomppct_r) AND (#NoDuffTemp2.mukey = #NoDuffTemp3.mukey);
WITH #FirstofNoDufftex1 AS (Select mukey, texture, rn = row_number() OVER (PARTITION BY mukey ORDER BY texture) From #NoDufftex)

Select texture, mukey
INTO #FirstofNoDufftex
From #FirstofNoDufftex1
Where rn=1


/*
Soil suborder groups:
 
S1: Fribists, Folists, Hemists, Histels, Saprists, Wassists
 
S2: Aquands, Aquents, Aquepts, Aquods, Aquoxs, Cryods, Humods, Orthels, Peroxs,
Torrands, Tropepts, Turbels, Udands, Udoxs, Ustands
 
S3: Albolls, Andepts, Aquolls, Aquults, Cryands, Cryepts, Cryolls, Gelepts, Gelolls,
Humults, Rendolls, Umbrepts, Ustoxs, Vitrands, Wassents, Xerands
 
S4: Aqualfs, Aquerts, Boralfs, Borolls, Cryalfs, Ochrepts, Orthods, Orthoxs, Udalfs, Udepts,
Uderts, Udolls, Usterts, Ustolls, Xeralfs, Xerepts, Xerolls, Xerults
 
S5: Arents, Argids, Calcids, Cambids, Cryerts, Cryids, Durids, Fluvents, Gypsids, Orthents,
Orthids, Psamments, Salids, Torrerts, Torroxs, Udults, Ustalfs, Ustepts, Ustults, Xererts
 

*/

CREATE TABLE #dspssurgo
    ( aoiid INT ,
    pedlabsampnum CHAR(20),
	mukey INT, 
    aoigeom GEOMETRY, 
	NoDuffSufTex VARCHAR (250),
	SufTex VARCHAR (250), 
	dom_cond_suborder VARCHAR (250))

INSERT INTO #dspssurgo (aoiid,  pedlabsampnum , mukey, aoigeom, NoDuffSufTex, SufTex, dom_cond_suborder)

SELECT #AoiMUIn.aoiid, pedlabsampnum, #AoiMUIn.mukey, aoigeom,  #FirstofNoDufftex.texture as NoDuffSufTex, #Firstoftex.texture as SufTex, 
(SELECT TOP 1 taxsuborder
FROM mapunit 
INNER JOIN component ON component.mukey=mapunit.mukey
AND mapunit.mukey = #AoiMUIn.mukey 
GROUP BY taxsuborder, comppct_r ORDER BY SUM(comppct_r) over(partition by taxsuborder) DESC) AS dom_cond_suborder
FROM #AoiMUIn
LEFT JOIN #FirstofNoDufftex ON #AoiMUIn.mukey = #FirstofNoDufftex.mukey
LEFT JOIN #Firstoftex ON #AoiMUIn.mukey = #Firstoftex.mukey


SELECT aoiid,  pedlabsampnum , mukey, aoigeom, NoDuffSufTex, SufTex, dom_cond_suborder, 
CASE WHEN dom_cond_suborder IN ('Fribists', 'Folists', 'Hemists', 'Histels', 'Saprists', 'Wassists') THEN 'S1'
WHEN dom_cond_suborder IN  ('Aquands', 'Aquents', 'Aquepts', 'Aquods', 'Aquoxs', 'Cryods', 'Humods', 'Orthels', 'Peroxs', 'Torrands', 'Tropepts', 'Turbels', 'Udands', 'Udoxs', 'Ustands') THEN 'S2'
WHEN dom_cond_suborder IN ('Albolls', 'Andepts', 'Aquolls', 'Aquults', 'Cryands', 'Cryepts', 'Cryolls', 'Gelepts', 'Gelolls', 'Humults', 'Rendolls', 'Umbrepts', 'Ustoxs', 'Vitrands', 'Wassents', 'Xerands') THEN 'S3'
WHEN dom_cond_suborder IN  ('Aqualfs', 'Aquerts','Boralfs', 'Borolls', 'Cryalfs', 'Ochrepts', 'Orthods', 'Orthoxs', 'Udalfs', 'Udepts', 'Uderts', 'Udolls', 'Usterts', 'Ustolls', 'Xeralfs', 'Xerepts', 'Xerolls', 'Xerults') THEN 'S4'
WHEN dom_cond_suborder IN  ('Arents', 'Argids', 'Calcids', 'Cambids', 'Cryerts', 'Cryids', 'Durids', 'Fluvents', 'Gypsids', 'Orthents', 'Orthids', 'Psamments', 'Salids', 'Torrerts', 'Torroxs', 'Udults', 'Ustalfs', 'Ustepts', 'Ustults, Xererts' ) THEN 'S5' END AS 'suborder_groups' ,

CASE WHEN NoDuffSufTex IN ('S', 'LS', 'sandy loam (with <8% clay)') THEN 'T1'
WHEN NoDuffSufTex IN ('sandy loam (with clay >8%)', 'scl', 'l') THEN 'T2'
WHEN NoDuffSufTex IN ('SIL','SI') THEN 'T3'
WHEN NoDuffSufTex IN ('sc', 'cl', 'sicl', 'sic', 'clay (<60%)') THEN  'T4'
WHEN NoDuffSufTex IN ('clay (>60%)')THEN 'T5' END AS  'texture_groups'


FROM #dspssurgo