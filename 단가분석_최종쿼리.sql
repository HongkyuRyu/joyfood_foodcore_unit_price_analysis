WITH ���������� AS (
    SELECT
        a.NO_SMOR,
        SUBSTRING(a.NO_SMOR, CHARINDEX('-', a.NO_SMOR)+1, LEN(a.NO_SMOR)-CHARINDEX('-', a.NO_SMOR)) AS 'ǰ���ڵ�',
        c.CD_SYSITEM AS '������ý���ǰ���ڵ�',
        c.NO_SMORSUB AS '����',
        b.NM_PRODUCTNAME AS 'ǰ��',
        b.NM_PRODUCTPRINT AS '�μ��',
        b.TX_MATERIAL1 AS '������1',
        CASE
            WHEN c.CD_ITEMGUBUN = '001' THEN '����'
            WHEN c.CD_ITEMGUBUN = '002' THEN '�μ�'
            WHEN c.CD_ITEMGUBUN = '003' THEN '����'
        END AS '����',
        c.VL_THICK AS '������β�',
        c.VL_WIDTH AS '��������',
        c.VL_LENGTH AS '���������',
        c.VL_ROLL AS '������Ѽ�',
        ROW_NUMBER() OVER (PARTITION BY a.NO_SMOR, c.cd_sysitem ORDER BY a.NO_SMOR DESC) AS rn
    FROM SMOR_ORDER_H AS a
        LEFT JOIN BSIT_SPEC_H AS b
            ON a.CD_SYSITEM = b.CD_SYSITEM
        LEFT JOIN SMOR_ORDER_MAT1 AS c
            ON a.NO_SMOR = c.NO_SMOR
),
���Ե����� AS (
    SELECT
        p.CD_SYSITEM,
        p.VL_THICK,
        p.VL_WIDTH,
        p.VL_LENGTH,
        p.QT_CONFIRM AS '���Լ���',
        p.NO_PMPC AS '���Թ�ȣ',
        p.NO_PRCS AS 'ó����ȣ',
        p.AM_PRICE AS '�հ�',
        ROW_NUMBER() OVER (PARTITION BY p.CD_SYSITEM, p.VL_THICK, p.VL_WIDTH, p.VL_LENGTH, p.QT_CONFIRM
                           ORDER BY p.NO_PMPC DESC, CASE WHEN p.AM_TOT > 0 THEN 1 ELSE 2 END) AS rn
    FROM PMPC_CF_D AS p
),
�������Ǻ������� AS (
    SELECT
        w.*,
        m.���Լ���,
        m.�հ�,
        m.���Թ�ȣ,
        m.ó����ȣ,
        CASE
            WHEN w.NO_SMOR = m.ó����ȣ
                 AND w.������β� = m.VL_THICK
                 AND w.�������� = m.VL_WIDTH
                 AND w.��������� = m.VL_LENGTH
                 AND w.������Ѽ� = m.���Լ��� THEN 1
            WHEN w.������β� = m.VL_THICK
                 AND w.�������� = m.VL_WIDTH
                 AND w.��������� = m.VL_LENGTH
                 AND w.������Ѽ� = m.���Լ��� THEN 2
            WHEN w.������β� = m.VL_THICK
                 AND w.�������� = m.VL_WIDTH
                 AND w.��������� = m.VL_LENGTH THEN 3
            ELSE NULL
        END AS ���Ǽ���
    FROM ���������� w
    LEFT JOIN ���Ե����� m
        ON w.������β� = m.VL_THICK
        AND w.�������� = m.VL_WIDTH
        AND w.��������� = m.VL_LENGTH
),
���Ǽ����������� AS (
    SELECT
        *,
        CASE
            WHEN ���Ǽ��� = 3 THEN (�հ� / NULLIF(���Լ���, 0)) * ������Ѽ�
            ELSE �հ�
        END AS �����հ�
    FROM �������Ǻ�������
    WHERE ���Ǽ��� IS NOT NULL
),
���������� AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY NO_SMOR, ǰ���ڵ�, ������ý���ǰ���ڵ�
            ORDER BY �����հ� DESC
        ) AS dr -- ���� ū �����հ踸 ����
    FROM ���Ǽ�����������
),
���̳ε����� AS (
    SELECT *
    FROM ����������
    --WHERE dr = 1 -- �ߺ� ����
)
SELECT
    t.*,
    SUM(t.�����հ�) OVER (PARTITION BY t.NO_SMOR) AS ���հ�
FROM ���̳ε����� t
WHERE NO_SMOR = '20240906-1418P0070' AND ó����ȣ = '20240906-1418P0070'
ORDER BY t.NO_SMOR DESC;
