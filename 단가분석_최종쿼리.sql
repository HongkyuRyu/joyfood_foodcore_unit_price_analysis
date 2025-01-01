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
        c.VL_ROLL AS '원자재롤수',
        ROW_NUMBER() OVER (PARTITION BY a.NO_SMOR, c.cd_sysitem ORDER BY a.NO_SMOR DESC) AS rn
    FROM SMOR_ORDER_H AS a
        LEFT JOIN BSIT_SPEC_H AS b
            ON a.CD_SYSITEM = b.CD_SYSITEM
        LEFT JOIN SMOR_ORDER_MAT1 AS c
            ON a.NO_SMOR = c.NO_SMOR
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
        p.AM_PRICE AS '합계',
        ROW_NUMBER() OVER (PARTITION BY p.CD_SYSITEM, p.VL_THICK, p.VL_WIDTH, p.VL_LENGTH, p.QT_CONFIRM
                           ORDER BY p.NO_PMPC DESC, CASE WHEN p.AM_TOT > 0 THEN 1 ELSE 2 END) AS rn
    FROM PMPC_CF_D AS p
),
매입조건별데이터 AS (
    SELECT
        w.*,
        m.매입수량,
        m.합계,
        m.매입번호,
        m.처리번호,
        CASE
            WHEN w.NO_SMOR = m.처리번호
                 AND w.원자재두께 = m.VL_THICK
                 AND w.원자재폭 = m.VL_WIDTH
                 AND w.원자재길이 = m.VL_LENGTH
                 AND w.원자재롤수 = m.매입수량 THEN 1
            WHEN w.원자재두께 = m.VL_THICK
                 AND w.원자재폭 = m.VL_WIDTH
                 AND w.원자재길이 = m.VL_LENGTH
                 AND w.원자재롤수 = m.매입수량 THEN 2
            WHEN w.원자재두께 = m.VL_THICK
                 AND w.원자재폭 = m.VL_WIDTH
                 AND w.원자재길이 = m.VL_LENGTH THEN 3
            ELSE NULL
        END AS 조건순위
    FROM 원자재정보 w
    LEFT JOIN 매입데이터 m
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
최종데이터 AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY NO_SMOR, 품목코드, 원자재시스템품목코드
            ORDER BY 계산된합계 DESC
        ) AS dr -- 가장 큰 계산된합계만 선택
    FROM 조건순위별데이터
),
파이널데이터 AS (
    SELECT *
    FROM 최종데이터
    --WHERE dr = 1 -- 중복 제거
)
SELECT
    t.*,
    SUM(t.계산된합계) OVER (PARTITION BY t.NO_SMOR) AS 총합계
FROM 파이널데이터 t
WHERE NO_SMOR = '20240906-1418P0070' AND 처리번호 = '20240906-1418P0070'
ORDER BY t.NO_SMOR DESC;
