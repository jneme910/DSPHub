USE NPAD
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED; 
IF OBJECT_ID('tempdb..#Points_Practice') IS NOT NULL DROP TABLE #Points_Practice
GO
SELECT LU.land_unit_id
	,RAAP.survey_id
	,RAAP.result_area_answer_points_id
	,RAAP.last_change_date AS 'RAAP.last_change_date'
	,PLU.scheduled_practice_id
	,PSched.last_change_date
	,A.assessment_id
	,LU.land_unit_state_county_code
	,RAAP.points
	,PSched.practice_id AS 'Practice_Id - 20 Cover Crop'
	,RPA.ranking_pool_assessment_id
	,RPA.last_change_date AS 'RPA.last_change_date'
	,PSys.planned_system_id
INTO #Points_Practice
FROM dbo.ranking_pool_assessment_survey				AS RPAS
LEFT JOIN cart.display_group_survey					AS CDGS		ON CDGS.display_group_survey_id = RPAS.display_group_survey_id
LEFT JOIN cart.result_area_answer_points			AS RAAP		ON RAAP.survey_id = CDGS.display_group_survey_id
LEFT JOIN dbo.ranking_pool_assessment_display_group AS RPADG	ON RPADG.ranking_pool_assessment_display_group_id = RPAS.ranking_pool_assessment_display_group_id
LEFT JOIN dbo.ranking_pool_assessment				AS RPA		ON RPA.ranking_pool_assessment_id = RPADG.ranking_pool_assessment_id
LEFT JOIN dbo.assessment							AS A		ON A.assessment_id = RPA.assessment_id
LEFT JOIN dbo.planned_system						AS PSys		ON PSys.planned_system_id = A.planned_system_id
LEFT JOIN dbo.practice_schedule						AS PSched	ON PSched.planned_system_id = PSys.planned_system_id
LEFT JOIN dbo.practice_land_unit					AS PLU		ON PLU.scheduled_practice_id = PSched.scheduled_practice_id
LEFT JOIN dbo.land_unit								AS LU		
ON LU.land_unit_id = PLU.land_unit_id
WHERE RAAP.points IS NOT NULL
	AND RAAP.points <> '0'
	AND PSched.practice_id = '20' -- NRT.dbo.d_practice.practice_ID = '20' is NRT.dbo.d_practice.practice_code = '340' which is cover crop
	--AND LEFT(LU.land_unit_state_county_code, 2) = '34' -- New Jersey
ORDER BY LU.land_unit_id
	,RAAP.survey_id
	,RAAP.result_area_answer_points_id
	,RAAP.last_change_date
	,PLU.scheduled_practice_id

-- Second Segment

IF OBJECT_ID('tempdb..#Points_Second') IS NOT NULL DROP TABLE #Points_Second
GO
Select ROW_NUMBER() OVER(PARTITION BY survey_id ORDER BY scheduled_practice_id DESC) AS RowNumber
	,survey_id
	--,MAX(survey_id) OVER (PARTITION BY land_unit_id) AS 'MAX(survey_id)'
	,scheduled_practice_id
	,#Points_Practice.last_change_date
	,land_unit_id
	,points
INTO #Points_Second
FROM #Points_Practice
GROUP BY land_unit_id
	,survey_id
	,scheduled_practice_id
	,#Points_Practice.last_change_date
	,points
ORDER BY land_unit_id

-- Third Segment

SELECT * FROM #Points_Second
WHERE RowNumber = 1

