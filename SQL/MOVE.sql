-- INIT database
CREATE TABLE DM_WIP_BT (
  LOT_ID VARCHAR2(100),
  LOT_STATUS VARCHAR2(100),
  TECH_ID VARCHAR2(100),
  STAGE_NAME VARCHAR2(100),
  WFR_QTY NUMBER,
  OPNO VARCHAR2(100),
  IS_DUMMY NUMBER
);

INSERT INTO DM_WIP_BT(LOT_ID,LOT_STATUS,TECH_ID, STAGE_NAME,OPNO,WFR_QTY,IS_DUMMY) VALUES ('B3100200.00','H','XinMEMS-RP','BO1','M1000-100',10,0);
INSERT INTO DM_WIP_BT(LOT_ID,LOT_STATUS,TECH_ID, STAGE_NAME,OPNO,WFR_QTY,IS_DUMMY) VALUES ('B3100200.01','R','XinMEMS-RP','BO1','M1000-100',10,0);
INSERT INTO DM_WIP_BT(LOT_ID,LOT_STATUS,TECH_ID, STAGE_NAME,OPNO,WFR_QTY,IS_DUMMY) VALUES ('B3100222.00','Q','XinMEMS-RP','GS','M1100-100',10,0);
INSERT INTO DM_WIP_BT(LOT_ID,LOT_STATUS,TECH_ID, STAGE_NAME,OPNO,WFR_QTY,IS_DUMMY) VALUES ('B3100222.00','Q','XinMEMS-RP','LE_CO','M1100-100',10,0);
CREATE TABLE DM_MOVE_BT (
  LOT_ID VARCHAR2(100),
  STAGE_NAME VARCHAR2(100),
  MOVE_FLAG VARCHAR2(100),
  TRACK_IN_DT DATE,
  WFR_QTY NUMBER,
  TECH_ID VARCHAR2(100)
);

INSERT INTO DM_MOVE_BT(LOT_ID,STAGE_NAME, MOVE_FLAG,TRACK_IN_DT,WFR_QTY,TECH_ID) VALUES ('B3100222.00','BO1','Y',TO_DATE('2024-07-06 13:54:00', 'YYYY-MM-DD HH24:MI:SS') ,10,'XinMEMS-RP');
INSERT INTO DM_MOVE_BT(LOT_ID,STAGE_NAME, MOVE_FLAG,TRACK_IN_DT,WFR_QTY,TECH_ID) VALUES ('B3100222.00','GS','Y',TO_DATE('2024-07-06 09:30:00', 'YYYY-MM-DD HH24:MI:SS'),10,'XinMEMS-RP');


-- QUERY database
with First_Left_Table as ( SELECT STAGE_NAME,SUM(WFR_QTY) AS WIP FROM DM_WIP_BT WHERE TECH_ID LIKE 'XinMEMS%' AND (LOT_STATUS='H' OR LOT_STATUS='Q' OR LOT_STATUS='R' OR LOT_STATUS='WWIQC') AND STAGE_NAME ^='FAILIN' AND STAGE_NAME ^= 'INV' AND IS_DUMMY=0  GROUP BY STAGE_NAME 
),
 Second_Left_Table AS ( 
SELECT t.OPNO,t.STAGE_NAME,a.WIP,  ROW_NUMBER() OVER ( PARTITION BY t.STAGE_NAME ORDER BY t.OPNO) as rn  FROM DM_WIP_BT t  JOIN First_Left_Table a ON t.STAGE_NAME= a.STAGE_NAME  AND t.TECH_ID LIKE 'XinMEMS%'  AND t.OPNO ^= '-' AND length(t.OPNO)<=9 AND (t.LOT_STATUS='H' OR t.LOT_STATUS='Q' OR t.LOT_STATUS='R' OR t.LOT_STATUS='WWIQC') AND t.STAGE_NAME ^='FAILINV' AND t.STAGE_NAME ^= 'INV' AND t.IS_DUMMY=0 
),
Left_Table as ( 
 SELECT CASE WHEN STAGE_NAME ='PACK' THEN '9999-9999' ELSE OPNO END AS OPNO , STAGE_NAME FROM Second_Left_Table WHERE rn=1 ORDER BY OPNO 
),
Right_Table  AS ( 
SELECT STAGE_NAME,SUM(WFR_QTY) AS MOVE FROM  DM_MOVE_BT WHERE  TECH_ID LIKE 'XinMEMS%'  AND TRACK_IN_DT BETWEEN to_date('2024-07-06 07:30:00', 'yyyy-mm-dd hh24:mi:ss') AND to_date('2024-07-07 07:30:00', 'yyyy-mm-dd hh24:mi:ss') AND MOVE_FLAG='Y' GROUP BY STAGE_NAME ),
RESULT10 AS ( 
SELECT t.STAGE_NAME,a.MOVE from Left_Table t LEFT JOIN Right_Table a ON t.STAGE_NAME=a.STAGE_NAME
)
SELECT STAGE_NAME,CASE WHEN MOVE IS NOT NULL THEN MOVE ELSE 0 END AS MOVE FROM RESULT10