USE eContracts;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
Select ROW_NUMBER() OVER(PARTITION BY c.contract_id ORDER BY ci.contract_item_id DESC) AS Contract_Item_Count
	,ds.state_name
	,cf.farm_nbr
	,c.contract_id
	,ci.contract_item_id
	--,ci.practice_id
	,c.latitude
	,c.longitude
	,c.ranking_score AS Contract_Ranking_Score
	,c.total_treated_acres
	--,ci.treated_acres
	--,LEFT(CONVERT(NVARCHAR, ci.date_certified, 20), 10) AS Date_Certified
	,LEFT(CONVERT(NVARCHAR, ci.date_certified, 20), 4) AS Year_Certified
	,pin.payment_amount
	,cic.component_name
FROM dbo.contract AS c
LEFT JOIN dbo.contract_item AS ci ON ci.contract_id = c.contract_id
LEFT JOIN dbo.payment_instructions AS pin ON pin.contract_item_id = ci.contract_item_id
LEFT JOIN dbo.contract_item_component AS cic ON cic.contract_item_id = ci.contract_item_id
LEFT JOIN dbo.contract_farm AS cf ON cf.contract_id = c.contract_id
LEFT JOIN dbo.d_state AS ds ON ds.state_code = c.state_code
-- no links for NPAD.dbo.practice_schedule to ci.practice_id
-- INNER JOIN NPAD.dbo.practice_schedule as Nps ON Nps.alt_scheduled_practice_id = ci.practice_id
WHERE ci.date_certified IS NOT Null
	AND component_name LIKE '%cover crop%'
	AND c.state_code = '34'
	--AND ci.treated_acres <> '0'
	AND LEFT(CONVERT(NVARCHAR, ci.date_certified, 20), 4) IN (2015, 2016,2017, 2019, 2019)
ORDER BY c.contract_id
	,Contract_Item_Count ASC
	,cf.farm_nbr
	,c.latitude
	,c.longitude
	,Year_Certified