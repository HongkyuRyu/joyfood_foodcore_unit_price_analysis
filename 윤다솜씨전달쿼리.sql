-- 1089개 (공정순서에 대해서)
WITH 기성공정순서 AS (SELECT
                        A.NO_SMOR AS 주문번호,
                        A.NO_SEQ AS 주문세부번호,
                        A.공정타입,
                        BC.NM_CUST AS 외주처명
                FROM (SELECT NO_SMOR, NO_SEQ, CD_CUST,
                            CASE
                                WHEN CD_PROCESS = '02' THEN '인쇄'
                                WHEN CD_PROCESS = '03' THEN '합지'
                                WHEN CD_PROCESS = '04' AND CD_CUST = '029994' THEN '분단'
                                WHEN CD_PROCESS = '05' THEN '제대'
                                ELSE NULL
                            END AS 공정타입
                      FROM SMOR_ORDER_PRO
                      WHERE SUBSTRING(NO_SMOR, 1, 8) BETWEEN '20240101' AND '20241231'
                        AND SUBSTRING(NO_SMOR, CHARINDEX('-', NO_SMOR) + 1, LEN(NO_SMOR)) LIKE '9%'
                        AND CD_PROCESS IN ('02', '03', '04', '05')) A
                LEFT JOIN BSCT_CUST AS BC
                    ON A.CD_CUST = BC.CD_CUST
                WHERE 공정타입 IN ('인쇄', '합지', '분단', '제대')

                )
, 인쇄 AS (SELECT *
         FROM 기성공정순서
         WHERE 공정타입 = '인쇄')
, 합지 AS (
SELECT
    주문번호, 주문세부번호, 공정타입,
    CASE
        WHEN 외주처명 IS NULL THEN '외주처명미기입'
        WHEN 외주처명 = '<사용금지>진산' THEN '진산'
        WHEN 외주처명 = '해한산업(주)' THEN '해한산업'
        ELSE 외주처명
    END AS 외주처명
FROM 기성공정순서
WHERE 공정타입 = '합지'
AND 외주처명 <> '박도영 테스트'
)
,제대 AS (SELECT 주문번호,
              주문세부번호,
              공정타입,
              CASE
                  WHEN 외주처명 IS NULL THEN '외주처명미기입'
                  WHEN 외주처명 = '다산팩(합지소)' THEN '다산팩(가공소)'
                  ELSE 외주처명
                  END AS 외주처명
       FROM 기성공정순서
       WHERE 공정타입 = '제대')
-- 9개

/*
 인쇄단가 계산
 - 다산팩인쇄소
    - 단가: 19
    - 계산공식: 원단폭 * 원단길이 * 0.001 * 청구도수
 */
, 인쇄공식 AS (SELECT B.주문번호,
                  B.주문세부번호,
                  B.공정타입,
                  B.외주처명,
                  B.원단폭,
                  B.원단길이,
                  SUM(B.도수 + B.추가도수) AS 청구도수
           FROM (SELECT 인쇄.*,
                        SOH.VL_FBWIDTH                       AS 원단폭,
                        SOH.QT_MAKE                          AS 원단길이,
                        CONVERT(INTEGER, SOH.CD_PRINTDEGREE) AS 도수,
                        CONVERT(INTEGER, SOH.CD_ADDDEGREE)   AS 추가도수
                 FROM 인쇄
                          JOIN SMOR_ORDER_H SOH
                               ON 인쇄.주문번호 = SOH.NO_SMOR
                                   AND 인쇄.주문세부번호 = SOH.NO_SEQ) B
           GROUP BY B.주문번호, B.주문세부번호, B.공정타입, B.외주처명, B.원단폭, B.원단길이)
, 인쇄종료 AS (SELECT 인쇄단가계산.*,
                  CONVERT(INTEGER, 인쇄단가 * 원단폭 * 원단길이 * 청구도수 * 0.001) AS 공급가액
           FROM (SELECT *,
                        19 AS 인쇄단가
                 FROM 인쇄공식) 인쇄단가계산)
/*
 합지단가계산

중량단가
    - 에스아이팩
    - 진산
    - 보성산업

면적단가
    - 가인
    - 한솔
    - 다산팩(합지소)
    - 제국포장
    - 해한산업(주)

 */
, 합지유니크넘버 AS (SELECT DISTINCT K.주문번호,
                              K.주문세부번호,
                              K.공정타입,
                              K.외주처명,
                              K.계산방법
              FROM (SELECT *,
                           CASE
                               WHEN 외주처명 IN ('에스아이팩', '진산', '보성산업') THEN '중량단가'
                               ELSE '면적단가'
                               END AS 계산방법
                    FROM 합지) K)

-- 합지유니크넘버를 주문원장과 결합해서, 원단폭, 원단길이를 가져온다.
, 합지유니크넘버_주문정보 AS (SELECT 합지유니크넘버.*,
                          SOH.VL_FBWIDTH AS 원단폭,
                          SOH.QT_MAKE    AS 원단길이
                   FROM 합지유니크넘버
                            LEFT JOIN SMOR_ORDER_H AS SOH
                                      ON 합지유니크넘버.주문번호 = SOH.NO_SMOR
                                          AND 합지유니크넘버.주문세부번호 = SOH.NO_SEQ)


-- 중량단가(접착제정보두께 및 접착제 종류를 알아야함)
, 중량단가업체 AS (SELECT *
             FROM 합지유니크넘버_주문정보
             WHERE 계산방법 = '중량단가')
, 면적단가업체 AS (SELECT *
             FROM 합지유니크넘버_주문정보
             WHERE 계산방법 = '면적단가')
, 접착제두께정보 AS (SELECT M.*,
                     BI.NM_ITEM AS 접착제명,
                     SUM(접착제두께) OVER (
                            PARTITION BY
                                    주문번호, 주문세부번호
                         )
                    AS 총접착제두께
              FROM (SELECT 중량단가업체.*,
                           SOM.CD_SYSITEM AS 접착제코드,
                           SOM.VL_THICK   AS 접착제두께
                    FROM SMOR_ORDER_MATERIAL SOM
                             RIGHT JOIN 중량단가업체
                                        ON SOM.NO_SMOR = 중량단가업체.주문번호
                                            AND SOM.NO_SEQ = 중량단가업체.주문세부번호
                    WHERE CD_ITEMGUBUN = '003') M
                       JOIN BSIT_ITEM AS BI
                            ON M.접착제코드 = BI.CD_SYSITEM
              wHERE 접착제두께 <> 1)

, 중량단가공식 AS (SELECT *,
                    CASE
                        WHEN 외주처명 = '에스아이팩' AND 접착제명 = 'TD1' THEN 4000
                        WHEN 외주처명 = '에스아이팩' AND 접착제명 = 'TD2' THEN 4600
                        WHEN 외주처명 = '보성산업' AND 접착제명 = 'TD1' THEN 4000
                        WHEN 외주처명 = '진산' AND 접착제명 IN ('TD1', 'TD1(PE)') THEN 3900
                        WHEN 외주처명 = '진산' AND 접착제명 = 'TD2' THEN 5000
                        ELSE NULL
                        END  AS 단가,
                    0.000001 AS 단위환산
             FROM (SELECT 주문번호,
                          주문세부번호,
                          공정타입,
                          외주처명,
                          원단폭,
                          원단길이,
                          계산방법,
                          접착제명,
                          총접착제두께 AS 두께
                   FROM 접착제두께정보) C)
, 중량단가종료 AS (SELECT *,
                    원단폭 * 원단길이 * 두께 * 0.92 * 단위환산 * 단가 AS 공급가액
             FROM 중량단가공식)

/*
 면적단가를 계산한다. (면적단가는 DY1도 포함한다. 두께가 있는게 필요한게 아니니)
 */
, 면적단가공식 AS (
SELECT
    KK.*,
    BI.NM_ITEM AS 접착제명
FROM (SELECT 면적단가업체.*,
             SOM.CD_SYSITEM AS 접착제코드
      FROM SMOR_ORDER_MATERIAL AS SOM
               RIGHT JOIN 면적단가업체
                          ON SOM.NO_SMOR = 면적단가업체.주문번호
                              AND SOM.NO_SEQ = 면적단가업체.주문세부번호
                WHERE CD_ITEMGUBUN = '003') KK
    JOIN BSIT_ITEM AS BI
        ON KK.접착제코드 = BI.CD_SYSITEM)
, 면적단가계산 AS (SELECT BB.*,
                    0.001 AS 단위환산
             FROM (SELECT *,
                          CASE
                              WHEN 외주처명 = '가인' AND 접착제명 = 'DY1' THEN 40
                              WHEN 외주처명 = '가인' AND 접착제명 = 'DY2' THEN 50
                              WHEN 외주처명 = '가인' AND 접착제명 = 'DY2(무용제)' THEN 50
                              WHEN 외주처명 = '가인' AND 접착제명 = 'TD1' THEN 35
                              WHEN 외주처명 = '다산팩(합지소)' AND 접착제명 = 'DY1' THEN 50
                              WHEN 외주처명 = '다산팩(합지소)' AND 접착제명 IN ('DY2', 'DY2(무용제)') THEN 50
                              WHEN 외주처명 = '제국포장' AND 접착제명 = 'DY1' THEN 35
                              WHEN 외주처명 = '제국포장' AND 접착제명 IN ('DY2', 'DY2(무용제)') THEN 50
                              WHEN 외주처명 = '한솔' AND 접착제명 IN ('DY2', 'DY2(무용제)') THEN 50
                              WHEN 외주처명 = '해한산업' THEN 70
                              ELSE NULL
                              END AS 단가
                   FROM 면적단가공식) BB
             wHERE BB.단가 IS NOT NULL)
, 면적단가종료 AS (SELECT *,
                    원단폭 * 원단길이 * 단위환산 * 단가 AS 공급가액
             FROM 면적단가계산)

/*

 면적단가종료, 중량단가종료가 최종 합지 공급가액 계산
 */
