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
        c.VL_ROLL AS '������Ѽ�'
    FROM SMOR_ORDER_H AS a
        LEFT JOIN BSIT_SPEC_H AS b
            ON a.CD_SYSITEM = b.CD_SYSITEM
        LEFT JOIN SMOR_ORDER_MAT1 AS c
            ON a.NO_SMOR = c.NO_SMOR
	WHERE c.CD_ITEMGUBUN <> '003'
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
        p.AM_PRICE AS '�հ�'
    FROM PMPC_CF_D AS p
),
�������Ǻ������� AS (
    SELECT
        w.*,
        m.���Լ���,
        m.�հ�,
        m.���Թ�ȣ,
        m.ó����ȣ,
        1 AS ���Ǽ���
    FROM ���������� w
    INNER JOIN ���Ե����� m
        ON w.NO_SMOR = m.ó����ȣ
        AND w.������β� = m.VL_THICK
        AND w.�������� = m.VL_WIDTH
        AND w.��������� = m.VL_LENGTH
        AND w.������Ѽ� = m.���Լ���

    UNION ALL

    SELECT
        w.*,
        m.���Լ���,
        m.�հ�,
        m.���Թ�ȣ,
        m.ó����ȣ,
        2 AS ���Ǽ���
    FROM ���������� w
    INNER JOIN ���Ե����� m
        ON w.������β� = m.VL_THICK
        AND w.�������� = m.VL_WIDTH
        AND w.��������� = m.VL_LENGTH
        AND w.������Ѽ� = m.���Լ���

    UNION ALL

    SELECT
        w.*,
        m.���Լ���,
        m.�հ�,
        m.���Թ�ȣ,
        m.ó����ȣ,
        3 AS ���Ǽ���
    FROM ���������� w
    INNER JOIN ���Ե����� m
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
-- ���� ������ ���� ���� ������ ����
������_���������� AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY NO_SMOR, ����
            ORDER BY ���Ǽ��� ASC, �����հ� DESC
        ) AS row_num
    FROM ���Ǽ�����������
)
SELECT
    t.*
FROM ������_���������� t
WHERE t.row_num = 1  AND NO_SMOR = '20240906-1418P0070' 
ORDER BY t.NO_SMOR DESC, t.����;
