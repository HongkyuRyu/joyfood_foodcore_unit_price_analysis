
-- 1. 각 제품코드에 해당되는 것들 중, 가장 최근 데이터 1건만을 가져오기
-- 2. 그 후, 공정순서

-- NO_PRCS: 주문번호
-- UP_PRICE: 원단매입금액

-- 1.가장 최근 데이터 1건에 대해, 각 공정별 순서를 가져오기
--해당 로트번호에 해당하는 공정 


WITH RankedData AS (
	SELECT 
		NO_PRCS AS '주문번호',
		VL_THICK AS '원단두께',
		VL_WIDTH AS '원단폭',
		VL_LENGTH AS '원단길이',
		UP_PRICE AS '원단매입금액',
		SUBSTRING(NO_PRCS, CHARINDEX('-', NO_PRCS) + 1, LEN(NO_PRCS)) AS '제품코드',
		ROW_NUMBER() OVER(
			PARTITION BY SUBSTRING(NO_PRCS, CHARINDEX('-', NO_PRCS) + 1, LEN(NO_PRCS))
			ORDER BY NO_PRCS DESC, UP_PRICE DESC
			) AS r_num
	FROM PMPC_CF_D
), CalculateOriginalPrice AS (
	SELECT
		*
	FROM RankedData
	WHERE 주문번호 IS NOT NULL
	AND 주문번호 <> ''
	AND r_num = 1
), GongJeongOrdering AS (
SELECT
	SOP.NO_SMOR AS '주문번호',
	SOP.NO_SEQUENCE AS '공정순서',
	SOP.CD_PROCESS AS '제대타입',
	SOP.CD_CUST AS '외주처명',
	COP.원단길이,
	COP.원단두께,
	COP.원단폭,
	COP.원단매입금액
FROM CalculateOriginalPrice AS COP
	RIGHT JOIN SMOR_ORDER_PRO AS SOP
		ON COP.주문번호 = SOP.NO_SMOR
), SpecificGongJung AS (
SELECT
	GJO.*,
	SOH.CD_PRINTTYPE AS '인쇄종류',
	SOH.CD_PRINTDEGREE AS '인쇄도수',
	SOH.CD_HAPJIPROCESS AS '합지공정',
	SOH.VL_HJFBTHICK AS '합지두께',
	SOH.CD_JAEDAETYPE AS '제대종류'
FROM GongJeongOrdering AS GJO
	LEFT JOIN SMOR_ORDER_H AS SOH
		ON GJO.주문번호 = SOH.NO_SMOR
WHERE GJO.주문번호 = '20221229-1000156847'
)
SELECT
*
FROM SpecificGongJung
/*
SELECT *,
		NO_PRCS AS '주문번호',
		VL_THICK AS '원단두께',
		VL_WIDTH AS '원단폭',
		VL_LENGTH AS '원단길이',
		UP_PRICE AS '원단매입금액',
		SUBSTRING(NO_PRCS, CHARINDEX('-', NO_PRCS) + 1, LEN(NO_PRCS)) AS '제품코드'
FROM PMPC_CF_D
WHERE SUBSTRING(NO_PRCS, CHARINDEX('-', NO_PRCS) + 1, LEN(NO_PRCS)) = '3000159871'
ORDER BY 주문번호 DESC, 원단매입금액 DESC
*/