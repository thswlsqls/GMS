-- 본사인트라넷SQL스터디_2023-04-10

-- 1. FRONT > 회사관리 > 근태관리
SELECT TI.ATTEN_START_DT 
		, TI.ATTEN_END_DT 
		, CC1.KEY01 START_DT015
		, CC1.KEY02 END_DT015
		, CC2.KEY01 START_DT016
		, CC2.KEY02 END_DT016
		, TE_E.REQ_START_TIME EXT_START_DT
		, TE_E.REQ_END_TIME EXT_END_DT
		, (SELECT A.APLY_NO
		   FROM TB_EXTENDEDWORK A
		   WHERE A.SEQ_NO = 1
           AND A.INSA_NO = TI.INSA_NO
           AND TO_CHAR(A.REQ_DATE , 'YYYY-MM-DD') = TO_CHAR(SYSDATE, 'YYYY-MM-DD')
           AND TI.ATTEN_END_DT <= TO_CHAR(SYSDATE, 'HH24MI')
           AND A.APLY_NO like 'E%'
           AND ROWNUM =1) APLY_NO
		, TE_H.REQ_START_TIME HOLY_START_DT
		, TE_H.REQ_END_TIME HOLY_END_DT
		, (SELECT A.APLY_NO 
		   FROM TB_EXTENDEDWORK A
           WHERE A.SEQ_NO = 1
           AND A.INSA_NO = TI.INSA_NO
           AND TO_CHAR(A.REQ_DATE , 'YYYY-MM-DD') = TO_CHAR(SYSDATE, 'YYYY-MM-DD')
           AND TI.ATTEN_END_DT <= TO_CHAR(SYSDATE, 'HH24MI')
           AND A.APLY_NO like 'H%'
           AND ROWNUM =1) HOLY_APLY_NO      
        , (SELECT A.APLY_NO 
           FROM TB_EXTENDEDWORK A
           WHERE A.SEQ_NO = 2
           AND A.INSA_NO = TI.INSA_NO
           AND TO_CHAR(A.REQ_DATE , 'YYYY-MM-DD') = TO_CHAR(SYSDATE, 'YYYY-MM-DD')
           AND TI.ATTEN_END_DT >= TO_CHAR(SYSDATE, 'HH24MI')
           AND ROWNUM =1) BEFORE_APLY_NO
FROM TBINSA TI
INNER JOIN (SELECT KEY01, KEY02 FROM COMMON_CODE WHERE MAJOR_CODE = 'HVTM' AND MINOR_CODE = 'H1') CC1
ON TI.INSA_NO = (SELECT INSA_NO FROM TBINSA WHERE USER_ID = 'helpfile')
INNER JOIN (SELECT KEY01, KEY02 FROM COMMON_CODE WHERE MAJOR_CODE = 'HVTM' AND MINOR_CODE = 'H2') CC2
ON TI.INSA_NO = (SELECT INSA_NO FROM TBINSA WHERE USER_ID = 'helpfile')
LEFT OUTER JOIN (SELECT INSA_NO, REQ_START_TIME, REQ_END_TIME 
				 FROM TB_EXTENDEDWORK 
				 WHERE 1=1
				 AND TO_CHAR(REQ_DATE, 'YYYY-MM-DD') = TO_CHAR(SYSDATE, 'YYYY-MM-DD')
				 AND APLY_NO LIKE 'E%' 
				 AND ROWNUM = 1) TE_E
ON TI.INSA_NO = TE_E.INSA_NO
LEFT OUTER JOIN (SELECT INSA_NO, REQ_START_TIME, REQ_END_TIME
				 FROM TB_EXTENDEDWORK 
				 WHERE 1=1
				 AND TO_CHAR(REQ_DATE, 'YYYY-MM-DD') = TO_CHAR(SYSDATE, 'YYYY-MM-DD')
				 AND APLY_NO LIKE 'H%' 
				 AND ROWNUM = 1) TE_H
ON TI.INSA_NO = TE_H.INSA_NO
; -- 1 ROW : 데이터 일치


-- 2. FRONT > 회사관리 > 근태조정
-- model.addAttribute("attendanceStatusApproveList" , attendanceStatusApproveList);
SELECT TO_CHAR(A.IN_TIME, 'YYYY-MM-DD') IN_TIME
		, TI.USER_NAME 
        , DECODE(A.FLAG,'06',FNC_GET_VACATION_NM(A.VACATION),'09','결근','출근') AS FLAG_NM /* 근태명 */ -- 참조
        , A.MEMO /* 상세내역(사유) */ -- 참조
FROM ATTENDANCE A
INNER JOIN TBINSA TI 
ON A.INSA_NO = TI.INSA_NO 
WHERE 1=1
AND A.FLAG = '09' -- 참조
AND TI.INSA_GB != 'F' -- 참조
AND TO_CHAR(A.IN_TIME,'YYYYMMDD') >= TO_CHAR(TRUNC(SYSDATE, 'MM'), 'YYYYMMDD')
AND TO_CHAR(A.IN_TIME,'YYYYMMDD') <= TO_CHAR(LAST_DAY(SYSDATE), 'YYYYMMDD')
AND A.MEMO IS NOT NULL -- 팜조
AND TI.TEAM_CD IN (SELECT A.DEPT_TYPE
				  FROM CM_MS_DEPT A
				  WHERE  A.DEPT_TYPE IS NOT NULL
				  AND A.DEPT_TYPE NOT IN ( 'SB', 'FF' )
				  START WITH A.DEPT_ID = '0' 
				  CONNECT BY PRIOR A.DEPT_ID = A.UP_DEPT_ID) -- 참조
ORDER BY A.UPDATE_DATE DESC, A.IN_TIME DESC, TI.USER_NAME -- 참조
; -- 0 ROW

-- model.addAttribute("deptAuthList"                , deptAuthList );
SELECT A.DEPT_ID
		, A.UP_DEPT_ID 
		, CASE WHEN DEPT_LVL > 3 THEN CONCAT('-',  A.DEPT_NM) ELSE A.DEPT_NM END DEPT_NM  
		, A.DEPT_LVL 
		, A.DEPT_BIZ_CD 
		, A.DEPT_TYPE 
		, SUBSTR(SYS_CONNECT_BY_PATH(A.DEPT_NM, '>'), 2) DEPT_PATH 
FROM CM_MS_DEPT A
WHERE 1=1
AND A.USE_YN = 'Y'
AND A.DEPT_BIZ_CD <> 'ETC'
AND A.DEPT_TYPE IS NOT NULL
START WITH A.DEPT_ID= 0
CONNECT BY PRIOR A.DEPT_ID = A.UP_DEPT_ID 
; -- 10 ROWS : 화면과 로우 수, 데이터, 정렬순서 일치
	
-- 3. FRONT > 회사관리 > 결재신청
SELECT APLY_NO -- 신청번호 
		, (SELECT NAME1 FROM COMMON_CODE WHERE MAJOR_CODE = 'CTYPE' AND MINOR_CODE = A.APP_CODE) CTYPE -- 결재방법
		, (SELECT NAME1 FROM COMMON_CODE WHERE MAJOR_CODE = 'APP' AND MINOR_CODE = A.APLY_CODE) APP -- 신청사유
		, APLY_REASON -- 상세내역
		,CASE WHEN A.APLY_CODE = 'EAT' THEN (SELECT COUNT(E.APLY_NO) FROM TBAPLY_ADD_EMP E WHERE E.APLY_NO = A.APLY_NO) +1
         ELSE (SELECT COUNT(E.APLY_NO) FROM TBAPLY_ADD_EMP E WHERE E.APLY_NO = A.APLY_NO)
         END AS CNT -- 인원 -- 참조
		, APLY_AMT -- 신청금액
		, TO_CHAR(TO_DATE(HAPPEN_DATE), 'YYYY/MM/DD') HAPPEN_DATE -- 사유 발생일
		, TO_CHAR(APLY_DATE, 'YYYY/MM/DD') APLY_DATE -- 결재 신청일
		, (SELECT NAME1 FROM COMMON_CODE WHERE MAJOR_CODE = 'APST' AND MINOR_CODE = A.STATUS) APST -- 진행상태
FROM TBAPLY A
WHERE 1=1
AND A.INSA_NO = (SELECT INSA_NO FROM TBINSA WHERE USER_ID = 'helpfile')
ORDER BY A.APLY_NO DESC 
; -- 242 ROWS : 화면과 로우 수, 정렬순서 일치

-- 4. FRONT > 회사관리 > 결재승인/내역보기
WITH    W_EXTENDEDWORK  AS ( -- WITH절 모두 참조
    SELECT	C.INSA_NO AS INSA_NO
        ,   C.REQ_DATE AS REQ_DATE
        ,   C.REQ_CODE AS REQ_CODE
        ,   C.APPRV_CODE AS APPRV_CODE
        ,   MAX(C.REQ_START_TIME) AS REQ_START_TIME
        /* 업무재개일자가 요청일자기준으로 들어가는것으로 파악되어 요청시작시간이 0시인 경우 업무재개일자의 시작일시, 종료일시에 1일을 더해준다. */
        ,   MIN(CASE WHEN REQ_START_TIME = '0000' THEN RESTART_START_TIME + 1 ELSE RESTART_START_TIME END) AS RESTART_START_TIME
        ,   MAX(CASE WHEN REQ_START_TIME = '0000' THEN RESTART_END_TIME + 1   ELSE RESTART_END_TIME   END) AS RESTART_END_TIME
    FROM	TBAPLY_SNCT		A
    	,	TBAPLY			B
    	,	TB_EXTENDEDWORK C
    WHERE	1 = 1
    AND		A.INSA_NO = (SELECT INSA_NO FROM TBINSA WHERE USER_ID = 'helpfile')
    AND		A.APLY_NO = B.APLY_NO
    AND		B.INSA_NO = C.INSA_NO
    AND		B.HAPPEN_DATE = TO_CHAR(C.REQ_DATE, 'YYYYMMDD')
    AND     NVL(C.DELETE_FLAG, 'N') = 'N'
    GROUP BY
            C.INSA_NO
        ,   C.REQ_DATE
        ,   C.REQ_CODE
        ,   C.APPRV_CODE
) 
SELECT TA.APLY_NO -- 신청번호 
		, NVL(HMAL.APPRV_LN_NM, '해당없음!') APPRV_LN_NM -- 결재선
		, TI.USER_NAME -- 신청자
		, (SELECT NAME1 FROM COMMON_CODE WHERE MAJOR_CODE = 'CTYPE' AND MINOR_CODE = TA.APP_CODE) CTYPE -- 결재방법
		, (SELECT NAME1 FROM COMMON_CODE WHERE MAJOR_CODE = 'APP' AND MINOR_CODE = TA.APLY_CODE) APP -- 신청사유
		, TA.APLY_REASON -- 상세내역
		, CASE WHEN TA.APLY_CODE = 'EAT' THEN (SELECT COUNT(E.APLY_NO) FROM TBAPLY_ADD_EMP E WHERE E.APLY_NO = TA.APLY_NO) +1
	      ELSE (SELECT COUNT(E.APLY_NO) FROM TBAPLY_ADD_EMP E WHERE E.APLY_NO = TA.APLY_NO)
	      END AS CNT -- 인원 -- 참조
		, TA.APLY_AMT -- 신청금액
		, TO_CHAR(TO_DATE(TA.HAPPEN_DATE), 'YYYY/MM/DD') HAPPEN_DATE -- 사유 발생일
		, TO_CHAR(TA.APLY_DATE, 'YYYY/MM/DD') APLY_DATE -- 결재신청일
		, (SELECT NAME1 FROM COMMON_CODE WHERE MAJOR_CODE = 'APST' AND MINOR_CODE = TA.STATUS) APST 
		, (SELECT CASE WHEN h.req_code='E01' AND h.apprv_code='03' THEN TO_CHAR(ATT.in_time,'hh24:mi') || '~' || TO_CHAR(ATT.out_time,'hh24:mi')
                       WHEN h.req_code='E02' THEN
                       CASE WHEN h.restart_start_time IS NULL THEN ''
                             WHEN  ( h.req_start_time >  to_char(h.restart_start_time, 'hh24mi'))  THEN
                                                  h.req_start_time  || ' ~ ' || to_char(h.restart_end_time , 'hh24:mi')  
                             ELSE   to_char(h.restart_start_time, 'hh24:mi') || ' ~ ' || to_char(h.restart_end_time , 'hh24:mi')  
                             END
                       ELSE ''
                       END 
           FROM  W_EXTENDEDWORK H
           WHERE h.insa_no =     TA.insa_no 
           AND nvl(h.apprv_code, '99') = '03' AND h.req_code IN ('E01', 'E02' )
           AND To_char(h.req_date,'YYYYMMDD') = TA.happen_date
          ) AS WORKTIME -- 참조
FROM TBAPLY TA
INNER JOIN TBAPLY_SNCT TS 
ON TA.APLY_NO = TS.APLY_NO 
INNER JOIN TBINSA TI 
ON TA.INSA_NO = TI.INSA_NO 
LEFT OUTER JOIN HR_MS_APPRV_LN HMAL
ON TA.APPRV_LN_ID  = HMAL.APPRV_LN_ID
LEFT OUTER JOIN ATTENDANCE ATT
ON TA.INSA_NO = ATT.INSA_NO
AND TA.HAPPEN_DATE    = TO_CHAR(ATT.IN_TIME, 'yyyymmdd')
WHERE 1=1
AND TS.INSA_NO = (SELECT INSA_NO FROM TBINSA WHERE USER_ID = 'helpfile')
AND TS.SNCT_DATE IS NOT NULL
AND TS.SNCT_STATUS IS NULL
ORDER BY TA.APLY_NO DESC -- 참조
; -- 7 ROWS : 화면과 로우 수, 정렬 순서 일치


-- 5. FRONT > 회사관리 > 조직도
-- model.addAttribute("deptList",     deptList);
SELECT * FROM CM_MS_DEPT;
SELECT * FROM CM_TR_DEPT_INSA A;
SELECT * FROM TBINSA B;
SELECT * FROM TBJIKGUB J;
SELECT * FROM CM_MS_DEPT C;
SELECT MAJOR_CODE, MINOR_CODE, NAME1 FROM COMMON_CODE WHERE MAJOR_CODE = 'BJOB' AND USE_FG = 'Y'

SELECT T.DEPT_ID 
		, T.UP_DEPT_ID
		, T.DEPT_NM
		, T.DEPT_LVL
		, T.DEPT_BIZ_CD
		, T.DEPT_TYPE
		, T.DISP_ORD
		, T.USE_YN
FROM (
		SELECT DEPT_ID 
				, UP_DEPT_ID 
				, DEPT_NM 
				, DEPT_LVL
				, DEPT_BIZ_CD 
				, DEPT_TYPE 
				, DISP_ORD 
				, USE_YN
		FROM CM_MS_DEPT 
		WHERE 1=1
		AND NVL(DEPT_TYPE, 'X') NOT IN ( 'ZA', 'SB', 'FF') -- 참조
		AND USE_YN = 'Y'
		UNION ALL 
		SELECT TO_CHAR(A.DEPT_ID ||'0' + A.DISP_ORD) DEPT_ID -- 참조
			 , A.DEPT_ID UP_DEPT_ID
			 , B.USER_NAME || ' ' || C.JIKGUB_NM || CASE WHEN E.NAME1 IS NOT NULL THEN '/' || E.NAME1 ELSE '' END DEPT_NM -- 참조
			 , CASE WHEN A.DEPT_ID = 20109000 THEN 3 
		                              WHEN SUBSTR(A.DEPT_ID, 7,1) > 0 THEN 5 
		                              WHEN SUBSTR(A.DEPT_ID, 5,1) > 0 THEN 4 
		                              WHEN SUBSTR(A.DEPT_ID, 3,1) > 0 THEN 3 
		                          END DEPT_LVL -- 참조 
		     , D.DEPT_BIZ_CD
		     , TO_CHAR(A.INSA_NO) AS DEPT_TYPE -- 참조
		     ,ROW_NUMBER() OVER (PARTITION BY A.DEPT_ID ORDER BY B.JIKGUB_NO, B.BIZ_JOB ASC, B.INSA_NO ) AS DISP_ORD -- 참조
		     ,'Y' AS USE_YN -- 참조
		FROM CM_TR_DEPT_INSA A
		RIGHT OUTER JOIN TBINSA B
		ON A.INSA_NO = B.INSA_NO
		INNER JOIN TBJIKGUB C 
		ON B.JIKGUB_NO = C.JIKGUB_NO 
		INNER JOIN CM_MS_DEPT D
		ON B.TEAM_CD = D.DEPT_TYPE 
		LEFT OUTER JOIN (SELECT MAJOR_CODE, MINOR_CODE, NAME1
		                 FROM COMMON_CODE
		                 WHERE MAJOR_CODE = 'BJOB'
		                 AND USE_FG = 'Y') E
		ON B.BIZ_JOB = E.MINOR_CODE
		WHERE 1=1
		AND B.INSA_NO NOT IN ('99999999', '88888888')
		AND A.TEAM_CD NOT IN ( 'ZA', 'SB', 'FF') -- 조건 모두 참조
	  ) T
WHERE 1=1
AND T.DEPT_ID > '0'
START WITH T.DEPT_ID = '0'
CONNECT BY PRIOR T.DEPT_ID = T.UP_DEPT_ID
ORDER SIBLINGS BY T.DEPT_LVL, T.DISP_ORD -- 정렬순서 참조
; -- 156 ROWS : 화면과 로우 수, 데이터, 정렬 순서 일치

-- model.addAttribute("insacardList", insacardList);

SELECT T3.USER_NAME
		, T3.JIKGUB_NM
		, T3.HAND_PHONE
		, T3.EMAIL
		, ROW_NUMBER() OVER (PARTITION BY T3.DEPT_ID ORDER BY T3.JIKGUB_NO ASC, T3.INSA_NO) AS DISP_ORD
FROM (
		SELECT TI.USER_NAME 
				, T2.JIKGUB_NM
				, TI.HAND_PHONE1 || '-' || TI.HAND_PHONE2 || '-' || TI.HAND_PHONE3 HAND_PHONE
				, TI.EMAIL 
				, T2.DEPT_ID
				, TI.JIKGUB_NO
				, TI.INSA_NO
				-- , ROW_NUMBER() OVER (PARTITION BY T2.DEPT_ID ORDER BY TI.JIKGUB_NO ASC, TI.INSA_NO) AS DISP_ORD
		FROM(
				SELECT T.DEPT_ID 
						, T.UP_DEPT_ID
						, T.DEPT_NM
						, T.JIKGUB_NM
						, T.DEPT_LVL
						, T.DEPT_BIZ_CD
						, T.DEPT_TYPE
						, T.DISP_ORD
						, T.USE_YN
				FROM (
						SELECT DEPT_ID 
								, UP_DEPT_ID 
								, DEPT_NM 
								, '' JIKGUB_NM
								, DEPT_LVL
								, DEPT_BIZ_CD 
								, DEPT_TYPE 
								, DISP_ORD 
								, USE_YN
						FROM CM_MS_DEPT 
						WHERE 1=1
						AND NVL(DEPT_TYPE, 'X') NOT IN ( 'ZA', 'SB', 'FF') -- 참조
						AND USE_YN = 'Y'
						UNION ALL 
						SELECT TO_CHAR(A.DEPT_ID ||'0' + A.DISP_ORD) DEPT_ID -- 참조
							 , A.DEPT_ID UP_DEPT_ID
							 , B.USER_NAME || ' ' || C.JIKGUB_NM || CASE WHEN E.NAME1 IS NOT NULL THEN '/' || E.NAME1 ELSE '' END DEPT_NM -- 참조
							 , C.JIKGUB_NM || CASE WHEN E.NAME1 IS NOT NULL THEN '/' || E.NAME1 ELSE '' END JIKGUB_NM
							 , CASE WHEN A.DEPT_ID = 20109000 THEN 3 
						                              WHEN SUBSTR(A.DEPT_ID, 7,1) > 0 THEN 5 
						                              WHEN SUBSTR(A.DEPT_ID, 5,1) > 0 THEN 4 
						                              WHEN SUBSTR(A.DEPT_ID, 3,1) > 0 THEN 3 
						                          END DEPT_LVL -- 참조 
						     , D.DEPT_BIZ_CD
						     , TO_CHAR(A.INSA_NO) AS DEPT_TYPE -- 참조
						     ,ROW_NUMBER() OVER (PARTITION BY A.DEPT_ID ORDER BY B.JIKGUB_NO, B.BIZ_JOB ASC, B.INSA_NO ) AS DISP_ORD -- 참조
						     ,'Y' AS USE_YN -- 참조
						FROM CM_TR_DEPT_INSA A
						RIGHT OUTER JOIN TBINSA B
						ON A.INSA_NO = B.INSA_NO
						INNER JOIN TBJIKGUB C 
						ON B.JIKGUB_NO = C.JIKGUB_NO 
						INNER JOIN CM_MS_DEPT D
						ON B.TEAM_CD = D.DEPT_TYPE 
						LEFT OUTER JOIN (SELECT MAJOR_CODE, MINOR_CODE, NAME1
						                 FROM COMMON_CODE
						                 WHERE MAJOR_CODE = 'BJOB'
						                 AND USE_FG = 'Y') E
						ON B.BIZ_JOB = E.MINOR_CODE
						WHERE 1=1
						AND B.INSA_NO NOT IN ('99999999', '88888888')
						AND A.TEAM_CD NOT IN ( 'ZA', 'SB', 'FF') -- 조건 모두 참조
					  ) T
				WHERE 1=1
				AND LENGTH(T.DEPT_TYPE) > 3
				AND T.DEPT_ID > '0'
				START WITH T.DEPT_ID = '0'
				CONNECT BY PRIOR T.DEPT_ID = T.UP_DEPT_ID
				ORDER SIBLINGS BY T.DEPT_LVL, T.DISP_ORD -- 정렬순서 참조
				) T2 
		INNER JOIN TBINSA TI 
		ON T2.DEPT_TYPE = TO_CHAR(TI.INSA_NO)
		) T3
;

          SELECT INSA_CD
                 , USER_NAME
                 , USER_ID
                 , JIKGUB_NM
                 , TEAM_NM
                 , HP1
                 , HP2
                 , HP3
                 , EMAIL
                 , USER_NAME_ENG
                 , ROWNUM AS RNUM 
                 ,ROW_NUMBER() OVER (PARTITION BY DEPT_ID ORDER BY JIKGUB_NO ASC, INSA_CD ) AS DISP_ORD
              FROM ( SELECT I.INSA_NO INSA_CD,
                            I.USER_NAME USER_NAME, 
                            I.USER_ID USER_ID, 
                            J.JIKGUB_NM || CASE WHEN BJ.NAME1 IS NOT NULL THEN '/' || BJ.NAME1 ELSE '' END JIKGUB_NM, 
                            I.JIKGUB_NO,
                            I.BIZ_JOB,
                            T.TEAM_NM TEAM_NM,
                            I.HOME_TEL1 HT1,
                            I.HOME_TEL2 HT2,
                            I.HOME_TEL3 HT3,
                            I.HAND_PHONE1 HP1,
                            I.HAND_PHONE2 HP2,
                            I.HAND_PHONE3 HP3,
                            I.EMAIL EMAIL,
                            I.MSN_ID MSN_ID,
                            I.USER_NAME_ENG,
                            D.DEPT_LVL,
                            D.DEPT_ID
                       FROM TBINSA I 
                          , TBJIKGUB J
                          ,(SELECT MAJOR_CODE, MINOR_CODE, NAME1
                              FROM COMMON_CODE
                             WHERE MAJOR_CODE = 'BJOB'
                               AND USE_FG = 'Y') BJ
                          , TBTEAM T 
                          ,(SELECT A.DEPT_ID
                                  ,A.DEPT_ORD
                                  ,A.DEPT_TYPE INSA_NO
                                  ,A.DEPT_LVL
                              FROM (SELECT A.DEPT_ID
                                         , A.DEPT_ID AS DEPT_ORD
                                         , A.UP_DEPT_ID
                                         , A.DEPT_LVL
                                         , A.DEPT_TYPE
                                         , A.DISP_ORD
                                         , A.USE_YN
                                         , A.DEPT_BIZ_CD
                                    FROM CM_MS_DEPT A
                                   WHERE NVL(A.DEPT_TYPE, 'X') NOT IN ( 'ZA', 'SB', 'FF')
                                     AND A.USE_YN = 'Y'
                                   UNION ALL
                                  SELECT A.DEPT_ID
                                        ,TO_CHAR(A.DEPT_ID || '0' + A.DISP_ORD) DEPT_ORD
                                        ,A.DEPT_ID AS UP_DEPT_ID
                                        ,CASE WHEN SUBSTR(A.DEPT_ID, 7,1) > 0 THEN 5
                                              WHEN SUBSTR(A.DEPT_ID, 5,1) > 0 THEN 4 
                                              WHEN SUBSTR(A.DEPT_ID, 3,1) > 0 THEN 3 
                                          END AS DEPT_LVL
                                        ,TO_CHAR(A.INSA_NO) AS DEPT_TYPE
                                        ,A.DISP_ORD
                                        ,'Y' AS USE_YN
                                        ,C.DEPT_BIZ_CD
                                    FROM CM_TR_DEPT_INSA A
                                        ,CM_MS_DEPT C
                                   WHERE A.TEAM_CD   = C.DEPT_TYPE
                                     AND A.TEAM_CD NOT IN ( 'ZA', 'SB', 'FF')
                                ) A 
                      START WITH A.DEPT_ORD = '0'
                      CONNECT BY PRIOR A.DEPT_ORD = A.UP_DEPT_ID
                      ) D         
                      WHERE I.JIKGUB_NO = J.JIKGUB_NO 
                        AND I.INSA_NO  != 99999999 
                        AND I.TEAM_CD   = T.TEAM_CD
                        AND LENGTH(D.INSA_NO) >= 9
                        AND I.INSA_NO   = D.INSA_NO
                        AND I.BIZ_JOB   = BJ.MINOR_CODE(+)
        ) T                                          
        ; -- 142 rows : 화면과 로우수 일치
 


















