WITH 원자재정보 AS (
    SELECT
        a.NO_SMOR,
        SUBSTRING(a.NO_SMOR, CHARINDEX('-', a.NO_SMOR)+1, LEN(a.NO_SMOR)-CHARINDEX('-', a.NO_SMOR)) AS '품목코드',
        c.CD_SYSITEM AS '원자재시스템품목코드',
        c.NO_SMORSUB AS '순서',
        b.NM_PRODUCTNAME AS '품명',
        b.NM_PRODUCTPRINT AS '인쇄명',
        b.TX_MATERIAL1 AS '원자재1',
        CASE
            WHEN c.CD_ITEMGUBUN = '001' THEN '무지'
            WHEN c.CD_ITEMGUBUN = '002' THEN '인쇄'
            WHEN c.CD_ITEMGUBUN = '003' THEN '접착'
        END AS '종류',
        c.VL_THICK AS '원자재두께',
        c.VL_WIDTH AS '원자재폭',
        c.VL_LENGTH AS '원자재길이',
        c.VL_ROLL AS '원자재롤수'
    FROM SMOR_ORDER_H AS a
        LEFT JOIN BSIT_SPEC_H AS b
            ON a.CD_SYSITEM = b.CD_SYSITEM
        LEFT JOIN SMOR_ORDER_MAT1 AS c
            ON a.NO_SMOR = c.NO_SMOR
	WHERE c.CD_ITEMGUBUN <> '003'
),
매입데이터 AS (
    SELECT
        p.CD_SYSITEM,
        p.VL_THICK,
        p.VL_WIDTH,
        p.VL_LENGTH,
        p.QT_CONFIRM AS '매입수량',
        p.NO_PMPC AS '매입번호',
        p.NO_PRCS AS '처리번호',
        p.AM_PRICE AS '합계'
    FROM PMPC_CF_D AS p
),
매입조건별데이터 AS (
    SELECT
        w.*,
        m.매입수량,
        m.합계,
        m.매입번호,
        m.처리번호,
        1 AS 조건순위
    FROM 원자재정보 w
    INNER JOIN 매입데이터 m
        ON w.NO_SMOR = m.처리번호
        AND w.원자재두께 = m.VL_THICK
        AND w.원자재폭 = m.VL_WIDTH
        AND w.원자재길이 = m.VL_LENGTH
        AND w.원자재롤수 = m.매입수량

    UNION ALL

    SELECT
        w.*,
        m.매입수량,
        m.합계,
        m.매입번호,
        m.처리번호,
        2 AS 조건순위
    FROM 원자재정보 w
    INNER JOIN 매입데이터 m
        ON w.원자재두께 = m.VL_THICK
        AND w.원자재폭 = m.VL_WIDTH
        AND w.원자재길이 = m.VL_LENGTH
        AND w.원자재롤수 = m.매입수량

    UNION ALL

    SELECT
        w.*,
        m.매입수량,
        m.합계,
        m.매입번호,
        m.처리번호,
        3 AS 조건순위
    FROM 원자재정보 w
    INNER JOIN 매입데이터 m
        ON w.원자재두께 = m.VL_THICK
        AND w.원자재폭 = m.VL_WIDTH
        AND w.원자재길이 = m.VL_LENGTH
),
조건순위별데이터 AS (
    SELECT
        *,
        CASE
            WHEN 조건순위 = 3 THEN (합계 / NULLIF(매입수량, 0)) * 원자재롤수
            ELSE 합계
        END AS 계산된합계
    FROM 매입조건별데이터
    WHERE 조건순위 IS NOT NULL
),
-- 조건 순위가 가장 높은 데이터 선택
종류별_최종데이터 AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY NO_SMOR, 종류
            ORDER BY 조건순위 ASC, 계산된합계 DESC
        ) AS row_num
    FROM 조건순위별데이터
)
SELECT
    t.*
FROM 종류별_최종데이터 t
WHERE t.row_num = 1  AND NO_SMOR = '20240906-1418P0070' 
ORDER BY t.NO_SMOR DESC, t.종류;
