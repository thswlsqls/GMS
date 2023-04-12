-- 본사인트라넷SQL스터디_2023-04-11
-- 1. FRONT > 회사관리 > 영업관리				  

SELECT DISTINCT TSE.SALES_SEQ -- 순번
		, TSE.SALES_COMPANY -- 고객사명
		, TSE.SALES_PSRN_NM -- 담당자명
		, TSE.SALES_TITLE -- 제목
		, (SELECT USER_NAME FROM TBINSA WHERE 1=1 AND INSA_NO = TO_NUMBER(REG_USER_NM)) REG_USER_NM -- 영업진행자
		, CASE T.SALES_PROC_CD WHEN 'AA' THEN '진행중' WHEN 'BB' THEN '완료' END SALES_PROC
		, TO_CHAR(TO_DATE(DECODE(TSE.UPDT_DT, NULL, TSE.REG_DT, TSE.UPDT_DT),'YYYYMMDD'),'YYYY-MM-DD') AS UPDT_DT -- 최종수정일 -- 참조
FROM TB_SALES_EVENT TSE
INNER JOIN (SELECT A.SALES_SEQ 
					, B.LAST_PROC_SEQ
					, A.SALES_PROC_CD
			FROM TB_SALES_EVENT_PROC A
			INNER JOIN (SELECT SALES_SEQ 
							  , MAX(SALES_PROC_SEQ) LAST_PROC_SEQ
						FROM TB_SALES_EVENT_PROC 
						WHERE 1=1
						GROUP BY SALES_SEQ) B
			ON A.SALES_SEQ = B.SALES_SEQ
			AND A.SALES_PROC_SEQ = B.LAST_PROC_SEQ) T
ON TSE.SALES_SEQ = T.SALES_SEQ
WHERE 1=1
AND (T.SALES_PROC_CD = 'AA')    
ORDER BY UPDT_DT DESC, SALES_SEQ DESC
; -- 197 rows : 화면과 로우 수, 데이터, 정렬 순서 일치

-- 2. FRONT > 회사관리 > 이슈등록관리

SELECT *
FROM (
		SELECT ISSUE_SEQ 
				, ISSUE_TITLE 
				, CASE ISSUE_RLT_CD WHEN 'A' THEN '요청' WHEN 'B' THEN '완료' END ISSUE_RLT_CD
				, TO_CHAR(ISSUE_START_DT, 'YYYY-MM-DD') || '~' || TO_CHAR(ISSUE_END_DT, 'YYYY-MM-DD') ISSUE_PERIOD
				, (SELECT USER_NAME FROM TBINSA WHERE INSA_NO = ISSUE_RLT_INSA_NO) ISSUE_RLT_USER_NAME
				, TO_CHAR(ISSUE_RLT_DT, 'YYYY-MM-DD') ISSUE_RLT_DT -- 처리일
				, REG_USER_NM -- 등록자
				, TO_CHAR(REG_DT, 'YYYY-MM-DD') REG_DT -- 등록일
		FROM TB_ISSUE_REG
		WHERE 1=1
--		AND ISSUE_RLT_CD = 'A'	
	 )
WHERE ISSUE_RLT_USER_NAME IS NOT NULL
ORDER BY 1 DESC
; -- 89 ROWS : 화면과 로우 수, 데이터, 정렬 순서 일치
       
        
-- 3. FRONT > 회사관리 > 회의록

SELECT MEETING_NUM -- 회
		, TITLE -- 제목
		, (SELECT NVL(COUNT(*), 0 ) FROM MEETING_REPLY A WHERE A.MEETING_NUM = MT.MEETING_NUM) RE_CNT -- 댓글개수 참조
		, TO_CHAR(WRITE_DATE, 'YYYY/MM/DD') WRITE_DATE -- 등록일
		,  CASE WHEN (PROGRESS_CNT + COMPLETED_CNT) <> 0 THEN 
	               CASE WHEN COMPLETED_CNT = (PROGRESS_CNT + COMPLETED_CNT) THEN 'Y' ELSE 'N' END
	                 ELSE 'N'
	                   END STATUS -- 상태 -- 참조
	    , (COMPLETED_CNT || '/' || (PROGRESS_CNT + COMPLETED_CNT)) STATUS_CNT
		, USER_NAME -- 작성자
		, DECODE ( MEETING_FLAG,'0','전체','1','사업부','2','팀','3','팀장','4','주간') MEETING_FLAG -- 회의분류 -- 참조
		, CNT -- 조회
FROM MEETING MT
WHERE 1=1
ORDER BY MEETING_NUM DESC -- 참조
; -- 213 rows : 화면과 로우 수, 데이터, 정렬 순서 일치


-- 4. FRONT > 회사관리 > 자산리스트

SELECT AM.ASSET_NO -- 자산번호 
		, AM.ASSET_NM -- 모델명
		, TI.USER_NAME -- 구매자
		, TO_CHAR(TO_DATE(MANUF_MON||'01'),'YYYY-MM') MANUF_MON -- 출시일
		, MANUF_COM -- 제조사
		, CC1.NAME1 ASSET_TYPE -- 자산구분
		, DECODE(AM.STATUS, 'SD', F_ASSET_NOW_KEEPER(AM.ASSET_NO),'RS', F_ASSET_NOW_KEEPER(AM.ASSET_NO), CC2.NAME1)  NOW_KEEPER -- 현보유자 -- 참조
FROM ASSET_MST AM
LEFT OUTER JOIN TBINSA TI
ON AM.BUYER = TI.INSA_NO 
INNER JOIN COMMON_CODE CC1 
ON AM.ASSET_TYPE = CC1.MINOR_CODE
AND CC1.MAJOR_CODE = 'CLS'
INNER JOIN COMMON_CODE CC2
ON AM.STATUS = CC2.MINOR_CODE
AND CC2.MAJOR_CODE = 'MST'
WHERE 1=1
ORDER BY AM.ASSET_NO DESC 
; -- 124 rows : 화면과 로우 수, 데이터, 정렬순서 일치

-- 자산구분
SELECT MINOR_CODE
		, NAME1 
FROM   COMMON_CODE 
WHERE  MAJOR_CODE = 'CLS' 
ORDER BY KEY01
; -- 3 rows --참조

-- SPEC
SELECT MINOR_CODE
		, NAME1 
FROM   COMMON_CODE 
WHERE  MAJOR_CODE = 'SPC' 
ORDER BY KEY01 
; -- 7 rows -- 참조

SELECT DISTINCT DECODE(A.MINOR_CODE, 'RR', 'ZZ', 'SR', 'ZZ', A.MINOR_CODE) AS MINOR_CODE 
      ,DECODE(A.MINOR_CODE, 'RR', '처리중', 'SR', '처리중', A.NAME1) AS NAME1   
      ,DECODE(A.MINOR_CODE, 'RR', '03', 'SR', '03', A.KEY01) AS KEY01        
FROM   COMMON_CODE A                                                        
WHERE  A.MAJOR_CODE = 'MST'                                                 
ORDER  BY KEY01
; -- 8 rows -- 참조


-- 5. FRONT > 회사관리 > PC사양조회

SELECT AK.ASSET_NO -- 자산번호
		, AM.ASSET_NM -- 모델명
		, DECODE(AK.STATUS, 'R', '인수중', 'S', '반납중', 'K', '보유중', 'C', '반납', '반납') STATUS -- 현상태 -- 유상태(직원)  R -인수중, S -반납중, K-보유중, C-반납완료
		, TO_CHAR(AK.KEEP_ST_DATE, 'YYYY-MM-DD') KEEP_ST_DATE -- 인수일자
		, TO_CHAR(AK.KEEP_ED_DATE, 'YYYY-MM-DD') KEEP_ED_DATE -- 반납일자
FROM ASSET_KEEP AK
INNER JOIN ASSET_MST AM 
ON AK.ASSET_NO = AM.ASSET_NO 
WHERE AK.KEEP_EMP = (SELECT INSA_NO FROM TBINSA WHERE USER_ID = 'helpfile')
ORDER BY 4 DESC -- 정렬순서 참조 
; -- 3 rows : 화면과 로우 수, 데이터, 정렬 순서 일치


-- 6. FRONT > 기술정보 > 자료실
SELECT ARTICLEID -- NO
		, NVL(TITLE, ' ') TITLE -- 제목
		, TO_CHAR(WRITE_DATE, 'YYYY/MM/DD HH24:MI') WRITE_DATE -- 등록일
		, NVL(USER_NAME, ' ') USER_NAME -- 글쓴이
		, HITS -- 조회수
		, (SELECT NVL(COUNT(*), 0 ) FROM TBMB110 RE WHERE RE.ARTICLEID=MR.ARTICLEID AND CODE='pds_jika') RE_CNT -- 댓글 수, 참조
FROM MEMBERS_ROOM MR
WHERE CODE = 'pds_jika' -- 참조
ORDER BY REF DESC, RELEVEL  ASC
; -- 144 ROWS : 화면과 로우 수, 데이터, 정렬 순서 일치


-- 7. FRONT > 기술정보 > 지식인
			        
SELECT TR.TR_NO NO -- 번호  
	    , F_CFM_YN(TR.TR_NO, 'Q')            F_CFM_YN    
		, F_CODE_NAME('R040', TR.TR_GUBUN)          F_GUBUN        
		, TR.TR_SUBJECT -- 글제목
		, TO_CHAR(TR.TR_CREATE_DATE, 'YYYY/MM/DD') TR_CREATE_DATE -- 등록일
	    , F_USER_NAME(TR.TR_CREATE_ID)              F_USER_NAME  
		, TR.TR_COUNT -- 조회
		, (SELECT NVL(COUNT(1),0) FROM TB_RESEARCH_REPLY C WHERE C.TRR_PARENT_TR_NO = TR_NO AND C.TRR_TIP_GUBUN = 'Q' ) AS REPLY_COUNT -- 댓글 수 -- 참조
FROM TB_RESEARCH TR
WHERE TR.TR_TIP_GUBUN = 'Q'
ORDER BY TR.TR_CREATE_DATE DESC
; -- 23 rows : 화면과 로우 수, 데이터, 정렬 순서 일치



-- 8. FRONT > 기술정보 > 프로젝트조회

SELECT DISTINCT TB.PROJECT_CD,
                    TB.PROJECT_REAL_CD,
                    PROJECT_NM,
                    ORDER_COMP,
                    CUSTOMER,
                    START_DT,
                    TB.END_DT,
                    DEV_ENV,
                    DEV_BUSI,
                    DEV_DESC,
                    DECODE(END_FG, 'N', '진행중', 'Y', '완료') AS END_FG,
                TO_CHAR(LAST_UPDATE_DT, 'YYYY-MM-DD HH24:MI:SS') AS LAST_UPDATE_DT,
                LAST_UPDATE_ID,
                TO_CHAR((TO_CHAR(START_DT) + 30)) AS START_TH,
                FNC_PROJECT_MEMBER_FRONT(TB.PROJECT_CD, 'N') AS USER_NAME,
                FNC_PROJECT_MEMBER_FRONT(TB.PROJECT_CD, 'A') AS USER_NAME_HTML,
                FNC_PROJECT_MEMBER_FRONT(TB.PROJECT_CD, 'E') AS PRO_DATE
 FROM TBPROJECT TB,
      (
        SELECT I.USER_NAME,
               TB.PROJECT_CD
          FROM TBMP110 P,
               TBINSA I,
               TBPROJECT TB
         WHERE P.INSA_NO = I.INSA_NO
          AND  P.PROJECT_CD = TB.PROJECT_CD
         UNION
        SELECT F.USER_NAME,
               TB.PROJECT_CD
          FROM TBMP110 P,
               TB_FREE F,
               TBPROJECT TB
         WHERE P.INSA_NO = F.INSA_NO
          AND  P.PROJECT_CD = TB.PROJECT_CD
      ) TI
WHERE TB.PROJECT_CD = TI.PROJECT_CD(+)
AND TB.USE_YN = 'Y' /* 평가프로젝트(USE:N 제외 BY ESJUNG 20160308) */
ORDER BY END_DT DESC, END_FG DESC, LAST_UPDATE_DT DESC, PROJECT_CD, PROJECT_NM
;


SELECT DISTINCT TP.PROJECT_CD -- 프로젝트 코드
		, TP.PROJECT_NM -- 프로젝트명
		, TP.ORDER_COMP -- 발주회사명
		, TP.CUSTOMER -- 고객사
--		, TO_CHAR(TO_DATE(TP.START_DT), 'YYYY-MM-DD') START_DT -- 시작일
--		, TO_CHAR(TO_DATE(TP.END_DT), 'YYYY-MM-DD') END_DT -- 종료일
		, START_DT 
		, END_DT
		, TP.DEV_ENV -- 개발환경
		, TP.DEV_DESC -- 개발내역
        , FNC_PROJECT_MEMBER_FRONT(TP.PROJECT_CD, 'N') USER_NAME -- 투입 인원
        , FNC_PROJECT_MEMBER_FRONT(TP.PROJECT_CD, 'A') USER_NAME_HTML
        , FNC_PROJECT_MEMBER_FRONT(TP.PROJECT_CD, 'E') PRO_DATE -- 투입 기간
		, DECODE(TP.END_FG, 'N', '진행중', 'Y', '완료') END_FG -- 종료유무
FROM TBPROJECT TP
LEFT OUTER JOIN (
			SELECT B.USER_NAME 
					, C.PROJECT_CD
			FROM TBMP110 A
			INNER JOIN TBINSA B 
			ON A.INSA_NO = B.INSA_NO 
			INNER JOIN TBPROJECT C 
			ON A.PROJECT_CD = C.PROJECT_CD 
			UNION
			SELECT B.USER_NAME 
					, C.PROJECT_CD 
			FROM TBMP110 A
			INNER JOIN TB_FREE B
			ON A.INSA_NO = B.INSA_NO
			INNER JOIN TBPROJECT C 
			ON A.PROJECT_CD = C.PROJECT_CD 
			) TI
ON TP.PROJECT_CD = TI.PROJECT_CD
AND TP.USE_YN = 'Y'


WHERE 1=1
ORDER BY TP.END_FG DESC, TP.END_DT DESC , TP.LAST_UPDATE_DT DESC, TP.PROJECT_CD, TP.PROJECT_NM
; -- 참조 
			
SELECT * 
FROM TBPROJECT
;



	   