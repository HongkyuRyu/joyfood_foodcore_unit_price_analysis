
-- 1. �� ��ǰ�ڵ忡 �ش�Ǵ� �͵� ��, ���� �ֱ� ������ 1�Ǹ��� ��������
-- 2. �� ��, ��������

-- NO_PRCS: �ֹ���ȣ
-- UP_PRICE: ���ܸ��Աݾ�

-- 1.���� �ֱ� ������ 1�ǿ� ����, �� ������ ������ ��������
--�ش� ��Ʈ��ȣ�� �ش��ϴ� ���� 


WITH RankedData AS (
	SELECT 
		NO_PRCS AS '�ֹ���ȣ',
		VL_THICK AS '���ܵβ�',
		VL_WIDTH AS '������',
		VL_LENGTH AS '���ܱ���',
		UP_PRICE AS '���ܸ��Աݾ�',
		SUBSTRING(NO_PRCS, CHARINDEX('-', NO_PRCS) + 1, LEN(NO_PRCS)) AS '��ǰ�ڵ�',
		ROW_NUMBER() OVER(
			PARTITION BY SUBSTRING(NO_PRCS, CHARINDEX('-', NO_PRCS) + 1, LEN(NO_PRCS))
			ORDER BY NO_PRCS DESC, UP_PRICE DESC
			) AS r_num
	FROM PMPC_CF_D
), CalculateOriginalPrice AS (
	SELECT
		*
	FROM RankedData
	WHERE �ֹ���ȣ IS NOT NULL
	AND �ֹ���ȣ <> ''
	AND r_num = 1
), GongJeongOrdering AS (
SELECT
	SOP.NO_SMOR AS '�ֹ���ȣ',
	SOP.NO_SEQUENCE AS '��������',
	SOP.CD_PROCESS AS '����Ÿ��',
	SOP.CD_CUST AS '����ó��',
	COP.���ܱ���,
	COP.���ܵβ�,
	COP.������,
	COP.���ܸ��Աݾ�
FROM CalculateOriginalPrice AS COP
	RIGHT JOIN SMOR_ORDER_PRO AS SOP
		ON COP.�ֹ���ȣ = SOP.NO_SMOR
), SpecificGongJung AS (
SELECT
	GJO.*,
	SOH.CD_PRINTTYPE AS '�μ�����',
	SOH.CD_PRINTDEGREE AS '�μ⵵��',
	SOH.CD_HAPJIPROCESS AS '��������',
	SOH.VL_HJFBTHICK AS '�����β�',
	SOH.CD_JAEDAETYPE AS '��������'
FROM GongJeongOrdering AS GJO
	LEFT JOIN SMOR_ORDER_H AS SOH
		ON GJO.�ֹ���ȣ = SOH.NO_SMOR
WHERE GJO.�ֹ���ȣ = '20221229-1000156847'
)
SELECT
*
FROM SpecificGongJung
/*
SELECT *,
		NO_PRCS AS '�ֹ���ȣ',
		VL_THICK AS '���ܵβ�',
		VL_WIDTH AS '������',
		VL_LENGTH AS '���ܱ���',
		UP_PRICE AS '���ܸ��Աݾ�',
		SUBSTRING(NO_PRCS, CHARINDEX('-', NO_PRCS) + 1, LEN(NO_PRCS)) AS '��ǰ�ڵ�'
FROM PMPC_CF_D
WHERE SUBSTRING(NO_PRCS, CHARINDEX('-', NO_PRCS) + 1, LEN(NO_PRCS)) = '3000159871'
ORDER BY �ֹ���ȣ DESC, ���ܸ��Աݾ� DESC
*/