-- 2023-04-07
-- 1. 열람실 > 공지사항
SELECT * FROM MEMBERS_ROOM;
SELECT * FROM CM_MS_DEPT;

SELECT ARTICLEID 
		, TYPE 
		, TYPE_1
		, GUBUN 
		, TITLE
		, WRITE_DATE 
		, USER_NAME 
		, HITS
		, TOP_YN
FROM MEMBERS_ROOM
WHERE 1=1
AND CODE = 'notice_jika'
AND TEAM IS NULL OR TEAM IN ( -- 참조
	SELECT NVL(DEPT_TYPE, DEPT_BIZ_CD) DEPT_TYPE
	FROM CM_MS_DEPT
	WHERE 1=1
	AND USE_YN = 'Y'
	AND DEPT_BIZ_CD <> 'ETC'
	START WITH DEPT_ID = '0'
	CONNECT BY DEPT_ID = UP_DEPT_ID
	UNION
	SELECT  NVL(DEPT_TYPE, DEPT_BIZ_CD) DEPT_TYPE
	FROM CM_MS_DEPT 
	WHERE 1=1
	AND USE_YN = 'Y'
	AND DEPT_BIZ_CD <> 'ETC'
	START WITH DEPT_ID = '0'
	CONNECT BY PRIOR DEPT_ID =  UP_DEPT_ID
)
-- 참조
AND (SYSDATE-1 BETWEEN START_DATE AND END_DATE
OR SYSDATE + 32 BETWEEN START_DATE AND END_DATE
OR START_DATE BETWEEN SYSDATE-1 AND SYSDATE + 32
OR END_DATE BETWEEN SYSDATE-1 AND SYSDATE + 32
OR START_DATE IS NULL OR END_DATE IS NULL)
-- 참조
ORDER BY WRITE_DATE DESC
; -- 614 rows


-- 2. 열람실 > 자유게시판
SELECT * FROM MEMBERS_ROOM;

SELECT ARTICLEID 
		, TITLE 
		, WRITE_DATE 
		, USER_NAME 
		, HITS
FROM MEMBERS_ROOM
WHERE 1=1
AND CODE = 'bbs_jika' -- 참조
-- 참조 
AND (SYSDATE-1 BETWEEN START_DATE AND END_DATE
OR SYSDATE + 32 BETWEEN START_DATE AND END_DATE
OR START_DATE BETWEEN SYSDATE-1 AND SYSDATE + 32
OR END_DATE BETWEEN SYSDATE-1 AND SYSDATE + 32
OR START_DATE IS NULL OR END_DATE IS NULL)
AND READ = 'all'
-- 참조
; -- 5511 rows


-- 3. 열람실 > 도서게시판
SELECT * FROM BOOK_LENT;
SELECT * FROM COMMON_CODE WHERE MAJOR_CODE = 'B02';
SELECT * FROM BOOK_MASTER;
SELECT * FROM ARRIVE_ALARM;

SELECT ROWNUM, T.* -- 찬조
FROM (SELECT BK.BOOK_SEQNO 
				, BK.BOOK_TITLE 
				, BCNT.CNT
				, (SELECT NAME1 FROM COMMON_CODE WHERE MAJOR_CODE = 'B02' AND MINOR_CODE = BK.BOOK_STATUS) STATUS
	  FROM BOOK_MASTER BK 
	  INNER JOIN (SELECT BOOK_SEQNO 
						 , COUNT(LENT_DATE) CNT
				  FROM BOOK_LENT 
				  WHERE 1=1
				  GROUP BY BOOK_SEQNO
				  ORDER BY 2 DESC) BCNT
	  ON BK.BOOK_SEQNO = BCNT.BOOK_SEQNO
	  WHERE 1=1
	  AND BK.FLAG = 'Y' -- 참조
	  ORDER BY CNT DESC) T
WHERE ROWNUM <= 5	   
; -- 3.1. 베스트셀러 : 화면과 데이터, 로우 수, 정렬 순서 일치
       
SELECT * FROM COMMON_CODE WHERE MAJOR_CODE = 'B06' AND MINOR_CODE = '01';
SELECT * FROM COMMON_CODE WHERE MAJOR_CODE = 'B02';
SELECT * FROM BOOK_MASTER;            
        
SELECT ROWNUM, T.* 
FROM (SELECT BOOK_SEQNO 
			, BOOK_TITLE 
			, (SELECT NAME1 FROM COMMON_CODE WHERE MAJOR_CODE = 'B02' AND MINOR_CODE = BK.BOOK_STATUS) STATUS
			, BOOK_STOCK_DATE
			, FLAG
	  FROM BOOK_MASTER BK
	  WHERE 1=1
	  AND BK.FLAG = 'Y'
	  AND BK.BOOK_STATUS <> '06'
	  ORDER BY BOOK_STOCK_DATE DESC) T
WHERE ROWNUM <= 5
; -- 3.2. 신규도서 : 화면과 데이터, 로우 수, 정렬 순서 일치

SELECT * FROM BOOK_RECOMMEND;
SELECT * FROM BOOK_MASTER;
SELECT * FROM TBINSA;

SELECT ROWNUM, T.* -- 참조
FROM (
		SELECT BM.BOOK_SEQNO
				, BM.BOOK_TITLE 
				, (SELECT USER_NAME FROM TBINSA WHERE INSA_NO = BM.INSA_NO) REGISTER_NAME
				, TI.USER_NAME RECOMMENDER_NAME
		FROM BOOK_MASTER BM
		INNER JOIN BOOK_RECOMMEND BR 
		ON BM.BOOK_SEQNO = BR.BOOK_SEQNO 
		INNER JOIN TBINSA TI 
		ON BR.INSA_NO = TI.INSA_NO
		WHERE 1=1
		AND BM.FLAG = 'Y'
		AND BM.BOOK_PATTERN = '01' AND BM.BOOK_STATUS IS NULL -- 참조
		ORDER BY BM.BOOK_SEQNO DESC 
	) T
WHERE ROWNUM <= 5
; -- 3.3. 추천도서 : 화면과 데이터, 로우 수, 정렬 순서 일치

SELECT * FROM BOOK_MASTER;
SELECT * FROM COMMON_CODE WHERE MAJOR_CODE = 'B02';
SELECT * FROM COMMON_CODE WHERE MAJOR_CODE = 'B01';

SELECT ROWNUM, T.* -- 참조
FROM (
		SELECT BM.BOOK_SEQNO 
			, BM.BOOK_TITLE
			, (SELECT NAME1 FROM COMMON_CODE WHERE MAJOR_CODE = 'B01' AND MINOR_CODE = BM.BOOK_PATTERN) PATTERN -- 참조
			, (SELECT NAME1 FROM COMMON_CODE WHERE MAJOR_CODE = 'B02' AND MINOR_CODE = BM.BOOK_STATUS) STATUS
			, BR.CNT
		FROM BOOK_MASTER BM
		LEFT OUTER JOIN (SELECT BOOK_SEQNO 
							, COUNT(INSA_NO) CNT
					FROM BOOK_RECOMMEND
					GROUP BY BOOK_SEQNO) BR
		ON BM.BOOK_SEQNO = BR.BOOK_SEQNO
		WHERE 1=1
		AND BM.FLAG = 'Y'
		AND BM.INSA_NO = (SELECT INSA_NO FROM TBINSA WHERE USER_ID = 'helpfile')
		AND BM.BOOK_PATTERN IN ('01', '02') -- 참조
		ORDER BY BM.BOOK_SEQNO DESC
	) T
WHERE ROWNUM <= 5
; -- 3.4. 나의 희망/기탁도서 : 화면과 데이터, 로우 수, 정렬 순서 일치

SELECT * FROM BOOK_LENT;
SELECT * FROM BOOK_MASTER;
SELECT * FROM ARRIVE_ALARM;
SELECT * FROM COMMON_CODE WHERE MAJOR_CODE = 'B02';

SELECT BM.BOOK_SEQNO 
		, BM.BOOK_TITLE 
		, BM.BOOK_AUTHOR
		, BM.BOOK_PUBLISHER
		, CASE WHEN (SELECT NAME1 FROM COMMON_CODE WHERE MAJOR_CODE = 'B02' AND MINOR_CODE = BM.BOOK_STATUS) = '대여가능' THEN '반납완료'
		       ELSE (SELECT NAME1 FROM COMMON_CODE WHERE MAJOR_CODE = 'B02' AND MINOR_CODE = BM.BOOK_STATUS) END STATUS
		, BL.LENT_DATE || '~' || RETURN_DUEDATE PERIOD
		, BL.RETURN_DATE
        , (CASE WHEN (BL.RETURN_DATE IS NULL) AND (TRUNC(SYSDATE-TO_DATE(BL.RETURN_DUEDATE,'YYYY-MM-DD'))>0)                   THEN TRUNC(SYSDATE-TO_DATE(BL.RETURN_DUEDATE,'YYYY-MM-DD'))
                WHEN (BL.RETURN_DATE IS NULL) AND (TRUNC(SYSDATE-TO_DATE(BL.RETURN_DUEDATE,'YYYY-MM-DD'))<=0)                  THEN 0
                WHEN (BL.RETURN_DATE IS NOT NULL) AND (TRUNC(TO_DATE(BL.RETURN_DATE,'YYYY-MM-DD')-TO_DATE(BL.RETURN_DUEDATE,'YYYY-MM-DD'))>0)  THEN TRUNC(TO_DATE(BL.RETURN_DATE,'YYYY-MM-DD')-TO_DATE(BL.RETURN_DUEDATE,'YYYY-MM-DD'))
                WHEN (BL.RETURN_DATE IS NOT NULL) AND (TRUNC(TO_DATE(BL.RETURN_DATE,'YYYY-MM-DD')-TO_DATE(BL.RETURN_DUEDATE,'YYYY-MM-DD'))<=0) THEN 0 END) OVER -- 참조 
        , (CASE WHEN (BL.RETURN_DATE IS NULL) AND (TRUNC(SYSDATE-TO_DATE(BL.RETURN_DUEDATE,'YYYY-MM-DD'))>0)                   THEN TRUNC(SYSDATE-TO_DATE(BL.RETURN_DUEDATE,'YYYY-MM-DD')) 
                WHEN (BL.RETURN_DATE IS NULL) AND (TRUNC(SYSDATE-TO_DATE(BL.RETURN_DUEDATE,'YYYY-MM-DD'))<=0)                  THEN 0
                WHEN (BL.RETURN_DATE IS NOT NULL) AND (TRUNC(TO_DATE(BL.RETURN_DATE,'YYYY-MM-DD')-TO_DATE(BL.RETURN_DUEDATE,'YYYY-MM-DD'))>0)  THEN TRUNC(TO_DATE(BL.RETURN_DATE,'YYYY-MM-DD')-TO_DATE(BL.RETURN_DUEDATE,'YYYY-MM-DD'))  
                WHEN (BL.RETURN_DATE IS NOT NULL) AND (TRUNC(TO_DATE(BL.RETURN_DATE,'YYYY-MM-DD')-TO_DATE(BL.RETURN_DUEDATE,'YYYY-MM-DD'))<=0) THEN 0 END)*(SELECT KEY01 FROM COMMON_CODE WHERE MAJOR_CODE='B04'AND MINOR_CODE='01') KEY1 -- 참조 
FROM BOOK_LENT BL
INNER JOIN BOOK_MASTER BM 
ON BL.BOOK_SEQNO = BM.BOOK_SEQNO 
WHERE 1=1
AND BL.INSA_NO = (SELECT INSA_NO FROM TBINSA WHERE USER_ID = 'helpfile')
AND BM.FLAG = 'Y'
ORDER BY BOOK_SEQNO DESC
; -- 3.5. 나의도서현황 : 화면과 로우 수, 데이터, 정렬순서 일치


-- 4. 열람실 > 좋은벼룩
SELECT * FROM MEMBERS_ROOM WHERE CODE = 'byoruk_jika';

SELECT ARTICLEID 
		, TITLE 
		, TO_CHAR(WRITE_DATE, 'YYYY/MM/DD HH24:MI') 
		, USER_NAME 
		, HITS
FROM MEMBERS_ROOM MB
WHERE 1=1
AND CODE = 'byoruk_jika'
ORDER BY ARTICLEID DESC 
; -- 23 rows : 화면과 로우 수, 정렬순서 일치


-- 5. 열람실 > 포토제닉
SELECT * FROM MEMBERS_ROOM WHERE CODE = 'photo_jika';
SELECT * FROM MASTER_PHOTO;

SELECT ARTICLEID 
		, PHOTOSEQ
		, TITLE 
		, TO_CHAR(WRITE_DATE, 'YYYY/MM/DD HH24:MI') WRITE_DATE 
		, USER_NAME 
		, HITS
		, DECODE( PHOTOSEQ, '', '', RANK() OVER ( PARTITION BY PHOTOSEQ ORDER BY NVL( MARK, 0 ) DESC )) RANK, ROWNUM RNUM -- 참조
	    , (SELECT NVL( COUNT( * ), 0 ) FROM TBMB110 TB WHERE TB.ARTICLEID=ARTICLEID AND CODE = 'photo_jika') RERANK -- 참조
FROM MEMBERS_ROOM 
WHERE 1=1
AND CODE = 'photo_jika'
AND RESTEP = '0' 
ORDER BY ARTICLEID DESC -- 참조
; -- 472 rows : 화면과 로우 수, 정렬 순서 일치


-- 6. 열람실 > 팀게시판
SELECT * FROM MEMBERS_ROOM WHERE CODE = 'team_jika';


SELECT ARTICLEID 
		, TITLE 
		, TO_CHAR(WRITE_DATE, 'YYYY/MM/DD HH24:MI') WRITE_DATE
		, USER_NAME 
		, HITS
		, START_DATE 
		, END_DATE
FROM MEMBERS_ROOM
WHERE 1=1
AND CODE = 'team_jika'
AND TEAM IS NULL OR TEAM IN ( -- 참조
	SELECT NVL(DEPT_TYPE, DEPT_BIZ_CD) DEPT_TYPE
	FROM CM_MS_DEPT
	WHERE 1=1
	AND USE_YN = 'Y'
	AND DEPT_BIZ_CD <> 'ETC'
	START WITH DEPT_ID = '0'
	CONNECT BY DEPT_ID = UP_DEPT_ID
	UNION
	SELECT  NVL(DEPT_TYPE, DEPT_BIZ_CD) DEPT_TYPE
	FROM CM_MS_DEPT 
	WHERE 1=1
	AND USE_YN = 'Y'
	AND DEPT_BIZ_CD <> 'ETC'
	START WITH DEPT_ID = '0'
	CONNECT BY PRIOR DEPT_ID =  UP_DEPT_ID
)
-- 참조
AND (SYSDATE-1 BETWEEN START_DATE AND END_DATE
OR SYSDATE + 32 BETWEEN START_DATE AND END_DATE
OR START_DATE BETWEEN SYSDATE-1 AND SYSDATE + 32
OR END_DATE BETWEEN SYSDATE-1 AND SYSDATE + 32
OR START_DATE IS NULL OR END_DATE IS NULL)
-- 참조
ORDER BY WRITE_DATE DESC
; -- 36 rows


-- 7. 열람실 > 행사안내
SELECT * FROM MEMBERS_EVENT;

SELECT ROWNUM, T.*
FROM (SELECT ARTICLEID 
			, TITLE 
			, TO_CHAR(WRITE_DATE, 'YYYY/MM/DD') WRITE_DATE
			, USER_NAME 
			, HITS
	  FROM MEMBERS_EVENT 
	  WHERE 1=1
	  AND DELETE_YN = 'N'
	  ORDER BY ARTICLEID ASC) T
WHERE 1=1
ORDER BY ROWNUM DESC
; -- 53row : 화면과 로우수 확인 불가, 페이징 버튼 동작 안함, 정렬순서 첫페이지 일치함


-- 8. 열람실 > 복리후생 제도
SELECT * FROM COMMON_CODE WHERE MAJOR_CODE = 'W01';

SELECT MINOR_CODE 
		, NAME1
		, NAME2
FROM COMMON_CODE
WHERE MAJOR_CODE = 'W01' -- 참조
AND USE_FG = 'Y'
ORDER BY TO_NUMBER(SORT_NO) -- 참조
; -- 12 rows : 화면과 로우 수, 정렬 순서 일치

-- 9. 열람실 > 복리후생 제도 > My 4.4
SELECT * FROM COMMON_CODE WHERE MAJOR_CODE = 'G01';
SELECT * FROM GRADE_MASTER WHERE INSA_NO = (SELECT INSA_NO FROM TBINSA WHERE USER_ID = 'helpfile');
SELECT * FROM TBINSA;

SELECT TI.INSA_NO
		, (SELECT NAME1 FROM COMMON_CODE WHERE MAJOR_CODE = 'G01' AND MINOR_CODE = NVL(GM.GRADE_CODE, '001')) GRADE_NM
		, NVL(GM.TOTAL_SCORE, 0) TOTAL_SCORE
FROM GRADE_MASTER GM
RIGHT OUTER JOIN (SELECT INSA_NO , USER_NAME, USER_ID
				  FROM TBINSA
				  WHERE USER_ID = 'helpfile') TI 
ON TI.INSA_NO = GM.INSA_NO 
AND GM.GRADE_YEAR = TO_CHAR(SYSDATE, 'YYYY')
; -- 1 row : 화면과 데이터 일치

-----------
SELECT * FROM GRADE_BENEFIT;
SELECT * FROM COMMON_CODE WHERE MAJOR_CODE = 'G03';


        SELECT   CO.NAME1 AS NAME1
                ,CO.MINOR_CODE AS MINOR_CODE
                ,CO.KEY04 AS KEY04
                ,CO.KEY01 AS KEY01
                ,NVL(CO.KEY05,'') AS KEY05
                ,NVL(CO.KEY07,'') AS KEY07
                ,NVL(GB.SEQ_NO,'') AS SEQ_NO
                ,GB.GRADE_CODE AS GRADE_CODE  
                ,GB.BENEFIT_CODE AS BENEFIT_CODE
                ,NVL(GB.REQ_COMMENT,'') REQ_COMMENT
                ,NVL2(GB.REQ_COMMENT, SUBSTR(GB.REQ_COMMENT,1,10) || '...', '') STR_REQ
                ,NVL(GB.ADMIN_COMMENT,'') ADMIN_COMMENT
                ,NVL2(GB.ADMIN_COMMENT, SUBSTR(GB.ADMIN_COMMENT,1,10) || '...', '') STR_ADM 
                ,NVL(GB.CANCEL_COMMENT,'') CANCEL_COMMENT 
                ,NVL(GB.STATUS_CODE,'') STATUS_CODE 
                ,TO_CHAR(NVL(GB.CREATION_DATE,''),'YYYY-MM-DD') CREATION_DATE   
                ,CO.DESCR AS DESCR
        FROM (SELECT   NAME1 
                       , MINOR_CODE
                       , KEY01
                       , KEY04
                       , NVL(KEY05,'') KEY05
                       , NVL(KEY07,'') KEY07 
                       , NVL(DESCR,'') DESCR
                  FROM COMMON_CODE 
                 WHERE MAJOR_CODE='G03') CO 
                ,GRADE_BENEFIT GB
        WHERE  GB.BENEFIT_CODE = CO.MINOR_CODE 
          AND  GB.GRADE_YEAR = TO_CHAR(SYSDATE,'YYYY') 
          AND  INSA_NO = (SELECT INSA_NO FROM TBINSA WHERE USER_ID = 'helpfile')
        ORDER  BY MINOR_CODE ASC
	    ;

        SELECT COUNT(CC.KEY01) OVER (PARTITION BY CC.KEY01 ORDER BY CC.KEY01) RANK_SEQ
              ,CC.KEY01         DIS_SEQ
              ,CC.NAME1         MASTER_ITEM 
              ,CD.MINOR_CODE    ITEM_CODE  
              ,CASE WHEN GD.ITEM_CODE IS NULL THEN 
                         CD.NAME1 || ' : ' || NVL(GD.ITEM_COUNT,0) || ' * '  || CD.KEY01  
                    ELSE CD.NAME1 || ' : ' || GD.ITEM_COUNT || ' * '  || GD.MASTER_SCORE  
                     END ITEM_DETAIL
              ,NVL(GD.ITEM_SCORE,0) ITEM_SCORE 
          FROM COMMON_CODE CC, 
               COMMON_CODE CD, 
               ( SELECT * FROM GRADE_DETAIL  
                  WHERE INSA_NO=  (SELECT INSA_NO FROM TBINSA WHERE USER_ID = 'helpfile')
                    AND GRADE_YEAR = TO_CHAR(SYSDATE,'YYYY') 
                ) GD     
         WHERE CC.MAJOR_CODE = 'G06' 
           AND CD.MAJOR_CODE = 'G04' 
           AND CC.MINOR_CODE = CD.KEY03 
           AND CD.KEY03      = GD.MASTER_CODE(+) 
           AND CD.MINOR_CODE = GD.ITEM_CODE(+) 
           AND CC.USE_FG  = 'Y'
           AND CD.USE_FG  = 'Y'
         UNION ALL 
        SELECT 1, '99', 'TOTAL', NULL, 'X', 
               NVL(TOTAL_SCORE,0) TOTAL_SCORE  
          FROM GRADE_MASTER GM
          	   RIGHT OUTER JOIN
               (SELECT INSA_NO
                  FROM TBINSA
                 WHERE INSA_NO= (SELECT INSA_NO FROM TBINSA WHERE USER_ID = 'helpfile')
                ) TIS
            ON GM.INSA_NO = TIS.INSA_NO
           AND GM.GRADE_YEAR = TO_CHAR(SYSDATE,'YYYY')
         ORDER BY DIS_SEQ, ITEM_CODE
         ;''









        