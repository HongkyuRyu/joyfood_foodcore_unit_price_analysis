-- 1089�� (���������� ���ؼ�)
WITH �⼺�������� AS (SELECT
                        A.NO_SMOR AS �ֹ���ȣ,
                        A.NO_SEQ AS �ֹ����ι�ȣ,
                        A.����Ÿ��,
                        BC.NM_CUST AS ����ó��
                FROM (SELECT NO_SMOR, NO_SEQ, CD_CUST,
                            CASE
                                WHEN CD_PROCESS = '02' THEN '�μ�'
                                WHEN CD_PROCESS = '03' THEN '����'
                                WHEN CD_PROCESS = '04' AND CD_CUST = '029994' THEN '�д�'
                                WHEN CD_PROCESS = '05' THEN '����'
                                ELSE NULL
                            END AS ����Ÿ��
                      FROM SMOR_ORDER_PRO
                      WHERE SUBSTRING(NO_SMOR, 1, 8) BETWEEN '20240101' AND '20241231'
                        AND SUBSTRING(NO_SMOR, CHARINDEX('-', NO_SMOR) + 1, LEN(NO_SMOR)) LIKE '9%'
                        AND CD_PROCESS IN ('02', '03', '04', '05')) A
                LEFT JOIN BSCT_CUST AS BC
                    ON A.CD_CUST = BC.CD_CUST
                WHERE ����Ÿ�� IN ('�μ�', '����', '�д�', '����')

                )
, �μ� AS (SELECT *
         FROM �⼺��������
         WHERE ����Ÿ�� = '�μ�')
, ���� AS (
SELECT
    �ֹ���ȣ, �ֹ����ι�ȣ, ����Ÿ��,
    CASE
        WHEN ����ó�� IS NULL THEN '����ó��̱���'
        WHEN ����ó�� = '<������>����' THEN '����'
        WHEN ����ó�� = '���ѻ��(��)' THEN '���ѻ��'
        ELSE ����ó��
    END AS ����ó��
FROM �⼺��������
WHERE ����Ÿ�� = '����'
AND ����ó�� <> '�ڵ��� �׽�Ʈ'
)
,���� AS (SELECT �ֹ���ȣ,
              �ֹ����ι�ȣ,
              ����Ÿ��,
              CASE
                  WHEN ����ó�� IS NULL THEN '����ó��̱���'
                  WHEN ����ó�� = '�ٻ���(������)' THEN '�ٻ���(������)'
                  ELSE ����ó��
                  END AS ����ó��
       FROM �⼺��������
       WHERE ����Ÿ�� = '����')
-- 9��

/*
 �μ�ܰ� ���
 - �ٻ����μ��
    - �ܰ�: 19
    - ������: ������ * ���ܱ��� * 0.001 * û������
 */
, �μ���� AS (SELECT B.�ֹ���ȣ,
                  B.�ֹ����ι�ȣ,
                  B.����Ÿ��,
                  B.����ó��,
                  B.������,
                  B.���ܱ���,
                  SUM(B.���� + B.�߰�����) AS û������
           FROM (SELECT �μ�.*,
                        SOH.VL_FBWIDTH                       AS ������,
                        SOH.QT_MAKE                          AS ���ܱ���,
                        CONVERT(INTEGER, SOH.CD_PRINTDEGREE) AS ����,
                        CONVERT(INTEGER, SOH.CD_ADDDEGREE)   AS �߰�����
                 FROM �μ�
                          JOIN SMOR_ORDER_H SOH
                               ON �μ�.�ֹ���ȣ = SOH.NO_SMOR
                                   AND �μ�.�ֹ����ι�ȣ = SOH.NO_SEQ) B
           GROUP BY B.�ֹ���ȣ, B.�ֹ����ι�ȣ, B.����Ÿ��, B.����ó��, B.������, B.���ܱ���)
, �μ����� AS (SELECT �μ�ܰ����.*,
                  CONVERT(INTEGER, �μ�ܰ� * ������ * ���ܱ��� * û������ * 0.001) AS ���ް���
           FROM (SELECT *,
                        19 AS �μ�ܰ�
                 FROM �μ����) �μ�ܰ����)
/*
 �����ܰ����

�߷��ܰ�
    - ����������
    - ����
    - �������

�����ܰ�
    - ����
    - �Ѽ�
    - �ٻ���(������)
    - ��������
    - ���ѻ��(��)

 */
, ��������ũ�ѹ� AS (SELECT DISTINCT K.�ֹ���ȣ,
                              K.�ֹ����ι�ȣ,
                              K.����Ÿ��,
                              K.����ó��,
                              K.�����
              FROM (SELECT *,
                           CASE
                               WHEN ����ó�� IN ('����������', '����', '�������') THEN '�߷��ܰ�'
                               ELSE '�����ܰ�'
                               END AS �����
                    FROM ����) K)

-- ��������ũ�ѹ��� �ֹ������ �����ؼ�, ������, ���ܱ��̸� �����´�.
, ��������ũ�ѹ�_�ֹ����� AS (SELECT ��������ũ�ѹ�.*,
                          SOH.VL_FBWIDTH AS ������,
                          SOH.QT_MAKE    AS ���ܱ���
                   FROM ��������ũ�ѹ�
                            LEFT JOIN SMOR_ORDER_H AS SOH
                                      ON ��������ũ�ѹ�.�ֹ���ȣ = SOH.NO_SMOR
                                          AND ��������ũ�ѹ�.�ֹ����ι�ȣ = SOH.NO_SEQ)


-- �߷��ܰ�(�����������β� �� ������ ������ �˾ƾ���)
, �߷��ܰ���ü AS (SELECT *
             FROM ��������ũ�ѹ�_�ֹ�����
             WHERE ����� = '�߷��ܰ�')
, �����ܰ���ü AS (SELECT *
             FROM ��������ũ�ѹ�_�ֹ�����
             WHERE ����� = '�����ܰ�')
, �������β����� AS (SELECT M.*,
                     BI.NM_ITEM AS ��������,
                     SUM(�������β�) OVER (
                            PARTITION BY
                                    �ֹ���ȣ, �ֹ����ι�ȣ
                         )
                    AS ���������β�
              FROM (SELECT �߷��ܰ���ü.*,
                           SOM.CD_SYSITEM AS �������ڵ�,
                           SOM.VL_THICK   AS �������β�
                    FROM SMOR_ORDER_MATERIAL SOM
                             RIGHT JOIN �߷��ܰ���ü
                                        ON SOM.NO_SMOR = �߷��ܰ���ü.�ֹ���ȣ
                                            AND SOM.NO_SEQ = �߷��ܰ���ü.�ֹ����ι�ȣ
                    WHERE CD_ITEMGUBUN = '003') M
                       JOIN BSIT_ITEM AS BI
                            ON M.�������ڵ� = BI.CD_SYSITEM
              wHERE �������β� <> 1)

, �߷��ܰ����� AS (SELECT *,
                    CASE
                        WHEN ����ó�� = '����������' AND �������� = 'TD1' THEN 4000
                        WHEN ����ó�� = '����������' AND �������� = 'TD2' THEN 4600
                        WHEN ����ó�� = '�������' AND �������� = 'TD1' THEN 4000
                        WHEN ����ó�� = '����' AND �������� IN ('TD1', 'TD1(PE)') THEN 3900
                        WHEN ����ó�� = '����' AND �������� = 'TD2' THEN 5000
                        ELSE NULL
                        END  AS �ܰ�,
                    0.000001 AS ����ȯ��
             FROM (SELECT �ֹ���ȣ,
                          �ֹ����ι�ȣ,
                          ����Ÿ��,
                          ����ó��,
                          ������,
                          ���ܱ���,
                          �����,
                          ��������,
                          ���������β� AS �β�
                   FROM �������β�����) C)
, �߷��ܰ����� AS (SELECT *,
                    ������ * ���ܱ��� * �β� * 0.92 * ����ȯ�� * �ܰ� AS ���ް���
             FROM �߷��ܰ�����)

/*
 �����ܰ��� ����Ѵ�. (�����ܰ��� DY1�� �����Ѵ�. �β��� �ִ°� �ʿ��Ѱ� �ƴϴ�)
 */
, �����ܰ����� AS (
SELECT
    KK.*,
    BI.NM_ITEM AS ��������
FROM (SELECT �����ܰ���ü.*,
             SOM.CD_SYSITEM AS �������ڵ�
      FROM SMOR_ORDER_MATERIAL AS SOM
               RIGHT JOIN �����ܰ���ü
                          ON SOM.NO_SMOR = �����ܰ���ü.�ֹ���ȣ
                              AND SOM.NO_SEQ = �����ܰ���ü.�ֹ����ι�ȣ
                WHERE CD_ITEMGUBUN = '003') KK
    JOIN BSIT_ITEM AS BI
        ON KK.�������ڵ� = BI.CD_SYSITEM)
, �����ܰ���� AS (SELECT BB.*,
                    0.001 AS ����ȯ��
             FROM (SELECT *,
                          CASE
                              WHEN ����ó�� = '����' AND �������� = 'DY1' THEN 40
                              WHEN ����ó�� = '����' AND �������� = 'DY2' THEN 50
                              WHEN ����ó�� = '����' AND �������� = 'DY2(������)' THEN 50
                              WHEN ����ó�� = '����' AND �������� = 'TD1' THEN 35
                              WHEN ����ó�� = '�ٻ���(������)' AND �������� = 'DY1' THEN 50
                              WHEN ����ó�� = '�ٻ���(������)' AND �������� IN ('DY2', 'DY2(������)') THEN 50
                              WHEN ����ó�� = '��������' AND �������� = 'DY1' THEN 35
                              WHEN ����ó�� = '��������' AND �������� IN ('DY2', 'DY2(������)') THEN 50
                              WHEN ����ó�� = '�Ѽ�' AND �������� IN ('DY2', 'DY2(������)') THEN 50
                              WHEN ����ó�� = '���ѻ��' THEN 70
                              ELSE NULL
                              END AS �ܰ�
                   FROM �����ܰ�����) BB
             wHERE BB.�ܰ� IS NOT NULL)
, �����ܰ����� AS (SELECT *,
                    ������ * ���ܱ��� * ����ȯ�� * �ܰ� AS ���ް���
             FROM �����ܰ����)

/*

 �����ܰ�����, �߷��ܰ����ᰡ ���� ���� ���ް��� ���
 */
