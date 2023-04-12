-- 본사인트라넷SQL스터디_2023-04-12
-- 1. FRONT > 기술정보 > 기술현황조회
SELECT CODE 
		, CODE_NAME 
		, (SELECT CEIL(COUNT(*)/5)
		   FROM SKILL_CODE_SUB T
		   WHERE T.CODE = SC.CODE) LINE_CNT
FROM SKILL_CODE SC
WHERE USE_FLAG = 'Y'
ORDER BY CODE 
; -- 7 rows : 화면과 로우 수 , 데이터, 정렬 순서 일치
SELECT SEQ
		, CODE
		, SUB_CODE
		, CODE_NAME
		, USE_FLAG 
		, FREE_FLAG 
FROM SKILL_CODE_SUB
WHERE USE_FLAG = 'Y'
; -- 73 rows : 화면과 데이터 일치


-- 2. FRONT > 직원현황 > 비가동현황
SELECT ROW_NUMBER() OVER (PARTITION BY T.TEAM_CD ORDER BY T.TEAM_CD, T.JIKGUB_NO, T.INSA_NO, T.REAL_END_DATE) AS RN
		, T.USER_NAME
		, T.NEXT_GRADE
		, T.END_FG_NM
		, T.MAN_GRADE
		, T.TEAM_NM
		, T.CAPTAIN_NM
		, T.ADDRESS
		, T.M_MESSAGE
		, T.LAST_UPDATE_NAME
		, T.LAST_UPDATE_DT
FROM (
		SELECT A.INSA_NO
			   , MAX(B.USER_NAME) USER_NAME
			   , MAX(C.NEXT_GRADE) NEXT_GRADE
			   , MAX(B.END_FG_NM) END_FG_NM
			   , MAX(B.MAN_GRADE) MAN_GRADE
			   , MAX(B.TEAM_NM) TEAM_NM
			   , MAX(B.CAPTAIN_NM) CAPTAIN_NM
			   , MAX(B.ADDRESS) ADDRESS
			   , MAX(B.M_MESSAGE) M_MESSAGE
			   , MAX(B.LAST_UPDATE_NAME) LAST_UPDATE_NAME
			   , MAX(B.LAST_UPDATE_DT) LAST_UPDATE_DT
			   , MAX(B.TEAM_CD) TEAM_CD
			   , MAX(B.JIKGUB_NO) JIKGUB_NO
			   , MAX(B.REAL_END_DATE) REAL_END_DATE
		FROM (SELECT T.INSA_NO
			  FROM (SELECT A.INSA_NO
					  FROM TBINSA A
					  WHERE A.TEAM_CD NOT IN ('ZZ', 'ZA', 'SB', 'RE', 'ZS', 'S1', 'FF') /* 관리, 퇴사, 센스바이, 휴직, 경지, 프리 */
					  AND A.INSA_GB != 'F' /* 계약직 제외 */
					  MINUS
					  SELECT NVL(B.RPLC_INSA_NO, B.INSA_NO) INSA_NO
					  FROM TBPROJECT A
					      ,TBMP110   B
					      ,TBINSA    C
					  WHERE A.PROJECT_CD = B.PROJECT_CD
					  AND TO_CHAR(SYSDATE, 'YYYYMMDD') BETWEEN B.REAL_STARAT_DATE AND B.REAL_END_DATE           
					  AND B.END_FG NOT IN ( 'N', 'Y')
					  AND A.USE_YN = 'Y' /* 평가프로젝트(USE:N 제외 BY ESJUNG 20160308) */
					  AND NVL(B.RPLC_INSA_NO, B.INSA_NO) = C.INSA_NO /* 대리계약 */) T) A
		      INNER JOIN (SELECT ROW_NUMBER() OVER (PARTITION BY TI.INSA_NO ORDER BY T.REAL_END_DATE DESC) RN
		      							, T.PROJECT_CD 
										, T.PROJECT_SEQ 
										, TI.INSA_NO 
										, TI.TEAM_CD 
										, TI.JIKGUB_NO 
										, TI.USER_NAME -- 이름
										, T.REAL_END_DATE
										, CASE WHEN T.END_FG = 'N' THEN '무상'
								               WHEN T.END_FG = 'Y' THEN '종료'
								               ELSE 'N/A'
								          END AS END_FG_NM
										, (SELECT USER_NAME FROM TBINSA WHERE USER_ID = T.LAST_UPDATE_ID) LAST_UPDATE_USER_NAME -- 수정자 
										, F_GET_GRADE_NEW('GD', T.INSA_NO) AS MAN_GRADE -- 등급
										, TT.TEAM_NM -- 조직
										, TT.CAPTAIN_NM -- 팀장
										, REGEXP_SUBSTR(TI.ADDRESS, '[^ ]* [^ ]*') ADDRESS -- 거주지
										, CASE WHEN T.PROJECT_CD IS NULL THEN '프로젝트 미등록' ELSE  T.MESSAGE END M_MESSAGE -- 비고
										,(SELECT TI2.USER_NAME FROM TBINSA TI2 WHERE TI2.USER_ID = T.LAST_UPDATE_ID AND TI2.BUSINESS_FG = 'Y' AND T.END_FG  IN ( 'N', 'Y')) LAST_UPDATE_NAME -- 수정자
									    ,TO_CHAR(T.LAST_UPDATE_DT,'YYYYMMDD') AS LAST_UPDATE_DT -- 수정일자
								FROM TBTEAM TT
								FULL OUTER JOIN TBINSA TI 
								ON TI.TEAM_CD = TT.TEAM_CD 
								FULL OUTER JOIN TBMP110 T
								ON T.INSA_NO = TI.INSA_NO 
								) B
		ON A.INSA_NO = B.INSA_NO
		INNER JOIN (
					SELECT T.USER_NAME
				   			   ,T.INSA_NO
				   			   ,CASE WHEN TC.NEXT_GRADE_CD <> '34' THEN 
							   '(' || (SELECT NAME1
								  		 FROM COMMON_CODE
								 		WHERE MAJOR_CODE = '010'
								   		  AND MINOR_CODE = TC.NEXT_GRADE_CD
							       	  ) 
							    || ' : '||
							    TO_CHAR(ADD_MONTHS(TO_DATE(TC.START_DT, 'YYYYMM'), (SELECT (T.FROM_YEAR -1) *12
														    						FROM TBGRADE T 
														   							WHERE T.GRADE_CD = TC.NEXT_GRADE_CD 
														     						AND T.SCHOOL_CD = DECODE(TC.CON_SCHOOL,'1','2','3','4',TC.CON_SCHOOL))), 'YYYY.MM')
							 	||')'
							 	ELSE NULL
						     	END  AS NEXT_GRADE
		       		   FROM TBINSA T, TBJIKGUB TB,
						   ( SELECT A.TEAM_CD
							  	  , A.TEAM_NM
								  , B.BUSINESS_CD
								  , B.BUSINESS_NM
						       FROM TBTEAM A, BUSINESS_DEPT B
						      WHERE A.BUSINESS_CD = B.BUSINESS_CD(+)
						        AND A.TEAM_CD NOT IN ( 'SB', 'ZA', 'ZZ' )) B,
						   ( SELECT TC.START_DT
								  , TC.CON_SCHOOL
								  , TC.INSA_NO
								  , S.S_NM CON_S_NM
								  , S2.S_NM SIL_S_NM
								  , CASE WHEN T.GRADE_CD IS NULL THEN NULL
									 WHEN T.GRADE_CD = '34' THEN '34'
									 WHEN T.GRADE_CD = '23' THEN '31'
									 WHEN T.GRADE_CD = '13' THEN '21'
									 ELSE TO_CHAR(T.GRADE_CD + 1)
								     END NEXT_GRADE_CD                
						       FROM TBINSA_CON TC
								  , SCHOOL S
								  , SCHOOL S2
								  , TBGRADE T
						      WHERE TC.CON_SCHOOL = S.S_CD
						        AND TC.SIL_SCHOOL = S2.S_CD(+)
						        AND F_GET_ANNUAL(SUBSTR( TC.START_DT, 1, 6 ), 'A' ) BETWEEN T.FROM_YEAR AND T.TO_YEAR 
						        AND T.SCHOOL_CD = DECODE(TC.CON_SCHOOL,'1','2','3','4',TC.CON_SCHOOL)
						     ) TC
				      WHERE T.TEAM_CD NOT IN ( 'SB' )
						AND T.INSA_NO NOT IN ( '88888888', '99999999' )
						AND B.TEAM_CD(+) = T.TEAM_CD
						AND T.JIKGUB_NO = TB.JIKGUB_NO
						AND T.INSA_NO = TC.INSA_NO(+)
						) C -- 참조
		ON A.INSA_NO = C.INSA_NO
		GROUP BY A.INSA_NO
		) T
; -- 127 ROWS


-- 3. FRONT > 직원현황 > 면담관리
SELECT A.ITV_SEQ -- 등록번호
		, CASE WHEN LENGTH(A.ITV_TITLE) > 19 THEN SUBSTR(A.ITV_TITLE, 1, 16)||'...'
                    ELSE A.ITV_TITLE
                END ITV_TITLE -- 제목 -- 참조
		, (SELECT NAME1 FROM COMMON_CODE WHERE MAJOR_CODE = 'IV1' AND MINOR_CODE = A.ITV_GUBUN_CD) ITV_GUBUN_CD -- 면담구분
		, (SELECT NAME1 FROM COMMON_CODE WHERE MAJOR_CODE = 'IV2' AND MINOR_CODE = A.ITV_GUBUN_CD_DETAIL AND KEY01 = ITV_GUBUN_CD) ITV_GUBUN_DETAIL_NM -- 면담구분
		, (SELECT NAME1 FROM COMMON_CODE WHERE MAJOR_CODE = 'I01' AND MINOR_CODE = A.ITV_RESULT_CD) ITV_RESULT_NM -- 면담결과상태
		, (SELECT USER_NAME FROM TBINSA T WHERE T.INSA_NO = A.ITVEE_INSA_NO) ITVEE_USER_NAME -- 면담대상자
		, A.REG_USER_NM -- 등록자
		, TO_CHAR(A.REG_DT, 'YYYY-MM-DD') REG_DT -- 등록일
FROM TB_INTERVIEW A
LEFT OUTER JOIN TB_SECOND_INTERVIEW B 
ON A.ITV_SEQ = B.ITV_SEQ 
AND (B.ITV_TYPE = 'TP' OR B.ITV_TYPE IS NULL)
INNER JOIN (SELECT A.INSA_NO 
			FROM TBINSA A
			LEFT OUTER JOIN (
							SELECT A.BUSINESS_CD
							     , B.BUSINESS_NM
							     , A.TEAM_CD
							     , A.TEAM_NM
							FROM TBTEAM          A
							     , BUSINESS_DEPT   B
							WHERE A.BUSINESS_CD = B.BUSINESS_CD
							) B	
			ON A.TEAM_CD = B.TEAM_CD) C
ON A.ITVEE_INSA_NO = C.INSA_NO
ORDER BY A.ITV_SEQ DESC
; -- 134 rows


-- 4. HOME > 회사소개 > 주요사업실적
SELECT CASE RN WHEN 1 THEN YYYY ELSE NULL END YEARS
		, A.RN
		, A.YYYY
		, A.MM
		, A.PROJECT_NM
		, A.ORDER_COMP
		, A.DEV_BUSI
FROM (SELECT ROW_NUMBER() OVER(PARTITION BY T.YYYY ORDER BY T.YYYY DESC, T.MM DESC) RN
			, T.*
	  FROM (SELECT SUBSTR(START_DT, 1, 4) YYYY
				, SUBSTR(START_DT, 5, 2) MM
				, PROJECT_NM 
				, ORDER_COMP 
				, DEV_BUSI
		  FROM TBPROJECT
		  WHERE 1=1
		  AND USE_YN = 'Y'
		  AND OPEN_YN = 'Y'
		  ORDER BY START_DT DESC) T
	  ORDER BY YYYY DESC, MM DESC) A
; -- 772 rows : 화면과 로우 수, 데이터, 정렬순서 일치 


-- 5. HOME > 좋은사람들 > 행사
SELECT ROWNUM T_RN
		, T.*
FROM (
	SELECT ARTICLEID 
			, TITLE 
			, TO_CHAR(WRITE_DATE, 'YYYY/MM/DD') WRITE_DATE
			, USER_NAME 
			, HITS
			, ROWNUM
	FROM MEMBERS_EVENT
	WHERE CODE = 'eventa'
	AND DELETE_YN = 'N'
	AND MAIN_IMAGE_YN = 'N'
	ORDER BY 1 DESC
) T
; -- 7 rows : 화면과 로우 수, 데이터, 정렬순서 일치


-- 6. HOME > 좋은사람들 > 동호회
SELECT CLUB_NO
		, CLUB_NAME
		, CLUB_INTRO
		, CLUB_OPENDATE
		, CLUB_ENDDATE
FROM CLUB
WHERE CLUB_ENDDATE IS NULL
ORDER BY 1 DESC
; -- 20 rows -- 참조


-- 7. HOME > 좋은사람들 > 새소식
SELECT ROWNUM RNUM,
         A.TITLE,
         A.USER_NAME,
         A.HITS,
         A.WRITE_DATE,
         A.GUBUN_NM
    FROM (
          SELECT *
            FROM (SELECT ARTICLEID, --
                          NVL(TITLE, ' ') TITLE, --
                          NVL(USER_NAME, ' ') USER_NAME, --
                          HITS, --
                          TO_CHAR(WRITE_DATE, 'YYYY/MM/DD') WRITE_DATE, --
                          F_CODE_NAME('R050', GUBUN) GUBUN_NM --
                     FROM MEMBERS_ROOM MR1
                    WHERE CODE = 'notice_jika'
                      AND OPEN_YN != '1'
                      AND TO_DATE(SYSDATE, 'YYYY/MM/DD') BETWEEN
                          TO_DATE(START_DATE, 'YYYY/MM/DD') AND
                          TO_DATE(END_DATE, 'YYYY/MM/DD')
                    ORDER BY WRITE_DATE ASC)
          UNION ALL
          SELECT A.ANN_ID ARTICLEID,
                 A.USER_NAME || '님의 ' ||
                 DECODE(A.ANN_CODE,
                        'M0',
                        '생일',
                        'M4',
                        '생일',
                        F_CODE_NAME('A030', A.ANN_CODE)) || '을 축하합니다!' TITLE,
                 '관리자' USER_NAME,
                 0 HITS,
                 TO_CHAR(TO_DATE(A.ANN_YYMMDD, 'YYYYMMDD') - 7, 'YYYY/MM/DD') WRITE_DATE,
                 '축하' GUBUN_NM
            FROM (SELECT A.ANN_ID ANN_ID,
                         B.USER_NAME USER_NAME,
                         F_GET_SOLAR2(A.ANN_YYMMDD, A.MS_GUBUN, '0') ANN_YYMMDD,
                         A.ANN_CODE ANN_CODE
                    FROM (SELECT A.*,
                                 TO_CHAR(SYSDATE, 'YYYY') || A.ANN_MONTH ||
                                 A.ANN_DATE ANN_YYMMDD
                            FROM ANNIVERSARY A
                           WHERE A.ANN_CODE IN ('M0', 'M4')
                             AND NOT EXISTS
                           (SELECT '1'
                                    FROM ANNIVERSARY
                                   WHERE ANN_CODE = 'M0'
                                     AND ANN_ID = A.ANN_ID)
                          UNION ALL
                          SELECT A.*,
                                 TO_CHAR(SYSDATE, 'YYYY') || A.ANN_MONTH ||
                                 A.ANN_DATE ANN_YYMMDD
                            FROM ANNIVERSARY A
                           WHERE A.ANN_CODE != 'M4') A
                   INNER JOIN TBINSA B
                   ON A.ANN_ID = B.INSA_NO
                   LEFT OUTER JOIN  
                         (SELECT COUNT(*) CNT, ANN_ID, ANN_SEQ, YEAR
                            FROM ANNIVERSARY_CELEB_MSG 
                            WHERE DELETE_FLAG(+) = 'N'
							AND YEAR(+) = TO_CHAR(SYSDATE, 'YYYY') 
                           GROUP BY ANN_ID, ANN_SEQ, YEAR) C
                   ON A.ANN_ID = C.ANN_ID
                   AND A.ANN_SEQ = C.ANN_SEQ
                   WHERE B.TEAM_CD NOT IN ('ZA', 'SB', 'RE', 'FF')
                   ORDER BY ANN_YYMMDD, ANN_ID) A
           WHERE ANN_YYMMDD BETWEEN TO_CHAR(SYSDATE - 7, 'YYYYMMDD')
           AND TO_CHAR(SYSDATE + 10, 'YYYYMMDD')
          ) A
   WHERE 1 = 1
   ORDER BY RNUM DESC
   ; -- 모두참조, 화면과 로우 수, 데이터, 정렬순서 일치  
  
   
-- 8. HOME > 좋은사람들 > 게시판
  SELECT -- ARTICLEID,
       	  ROWNUM AS RNUM, -- NO 
	      CODE, -- 구분
	      TITLE, -- 글제목
	      RIPPLE, -- 댓글수
	      TO_CHAR(WRITE_DATE, 'YYYY-MM-DD') WRITE_DATE, -- 등록일
	      USER_NAME, -- 글쓴이
	      HITS -- 조회수
  FROM (SELECT MR.ARTICLEID ARTICLEID,
               NVL(MR.TITLE, ' ') TITLE,
               MR.RIPPLE,
               MR.USER_NAME USER_NAME,
               MR.WRITE_DATE WRITE_DATE,
               MR.CODE CODE,
               MR.HITS
          FROM (SELECT MR.ARTICLEID ARTICLEID,
                       MR.TITLE TITLE,
                       MR.USER_NAME USER_NAME,
                       MR.WRITE_DATE WRITE_DATE,
                       MR.CODE CODE,
                       COUNT(T.WRITE_DT) RIPPLE,
                       MR.HITS,
                       MR.OPEN_YN
                       , MR.TEAM
                       , MR.ID
                FROM MEMBERS_ROOM MR
                LEFT OUTER JOIN TBMB110 T
                ON MR.ARTICLEID = T.ARTICLEID(+)
                AND MR.CODE = T.CODE(+)
                WHERE MR.CODE IN ( 'bbs_jika', 'pds_jika' ) 
                GROUP BY MR.ARTICLEID,
                          MR.TITLE,
                          MR.ID,
                          MR.USER_NAME,
                          MR.WRITE_DATE,
                          MR.TEAM,
                          MR.CODE,
                          MR.OPEN_YN,
                          MR.HITS) MR
         WHERE MR.TEAM IS NULL
         GROUP BY MR.ARTICLEID,
                  MR.TITLE,
                  MR.ID,
                  MR.USER_NAME,
                  MR.WRITE_DATE,
                  MR.TEAM,
                  MR.CODE,
                  MR.RIPPLE,
                  MR.OPEN_YN,
                  MR.HITS
        HAVING MR.OPEN_YN = '3'
        ORDER BY WRITE_DATE ASC)
 WHERE 1=1 
 ORDER BY RNUM DESC
; -- 모두참조, 화면과 로우 수, 데이터, 정렬순서 일치
     







