-- 
-- Top Combined Estimated Organic Carbon
-- uses the highest numbered layer_sequence - this may not be what is needed
-- 2021-02-12
--

USE sdmONLINE2019; 
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED; 
IF OBJECT_ID('tempdb..#Temp') IS NOT NULL DROP TABLE #Temp
GO
Select ROW_NUMBER() OVER(PARTITION BY lcnn.pedlabsampnum ORDER BY layer_sequence DESC) AS RowNumber
	  ,lcnn.pedlabsampnum
	  ,lcp.labsampnum
	  ,la.area_name AS StateP
	  ,la_ct.county_name AS County
	  ,ll.layer_sequence
	  ,CASE WHEN lcp.estimated_organic_carbon IS NOT NULL THEN lcp.estimated_organic_carbon
	        WHEN lcp.estimated_organic_carbon IS NULL AND lcp.caco3_lt_2_mm IS NOT NULL THEN (lcp.total_carbon_ncs - (lcp.caco3_lt_2_mm * 0.12))
			WHEN lcp.estimated_organic_carbon IS NULL AND lcp.caco3_lt_2_mm IS NULL AND lcp.total_carbon_ncs IS NOT NULL THEN lcp.total_carbon_ncs
		    WHEN lcp.organic_carbon_walkley_black IS NOT NULL THEN 0.25 + lcp.organic_carbon_walkley_black  * 0.86
	   END AS Combined_Est_Org_Carbon
	  ,CASE WHEN lcnn.corr_name IS NULL THEN lcnn.samp_name 
		  ELSE upper(substring(lcnn.corr_name,1,1))+ lower(substring(lcnn.corr_name,2,120)) 
	   END AS Soil_Name
	  ,CASE WHEN lcnn.corr_class_type IS NULL THEN lcnn.samp_class_type
		  ELSE lcnn.corr_class_type 
	   END AS Class_Type
	  ,CASE WHEN lcnn.corr_classification_name IS NULL THEN lcnn.samp_classification_name
		  ELSE lcnn.corr_classification_name  
	   END AS Sample_Classification_Name
	  ,lcnn.latitude_decimal_degrees
	  ,lcnn.longitude_decimal_degrees
INTO #Temp
FROM dbo.lab_combine_nasis_ncss AS lcnn
INNER JOIN dbo.lab_pedon AS lp ON lp.pedon_key = lcnn.pedon_key 
INNER JOIN dbo.lab_layer AS ll ON ll.pedon_key = lcnn.pedon_key
INNER JOIN dbo.lab_chemical_properties AS lcp ON lcp.labsampnum = ll.labsampnum
INNER JOIN dbo.lab_area AS la ON la.area_key = lcnn.state_key -- State
INNER JOIN (SELECT area_name AS county_name, area_key         -- County
			FROM lab_area
		    ) AS la_ct ON la_ct.area_key = lcnn.county_key
WHERE la.area_name = 'Kansas'
ORDER BY pedlabsampnum, labsampnum, layer_sequence

SELECT pedlabsampnum
	  ,latitude_decimal_degrees
	  ,longitude_decimal_degrees
	  ,Soil_Name
	  ,Sample_Classification_Name
	  ,Combined_Est_Org_Carbon AS SOC
FROM #Temp
WHERE RowNumber = 1
	AND Combined_Est_Org_Carbon IS NOT NULL
	AND Combined_Est_Org_Carbon <> '0'
	AND	latitude_decimal_degrees IS NOT NULL
	AND longitude_decimal_degrees IS NOT NULL
