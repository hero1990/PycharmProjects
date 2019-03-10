

  
/*    
INSERT INTO SLI_AIM_Version_Track    
VALUES('SLI_EXPORT_940B','CR2008-0014','10Apr_01',GETDATE(),USER_NAME())    
    
    
 Project: Cisco Global Hub                        
    
 Revision History:                                                                
    
 Version  Author  Date                   
 Base Version  Robert Wu 20090223    
 CR2009-0016  Becky Fu 20090224    
 AIM_20090716  Robert Wu 2009/07/16    
CR2009-0025  Pih lLing 2009/09/24    
CR2009-M011  Pih Ling  2009/10/26    
CR2008-0014  Becky  2010/01/10  
SQL2008			YP 2011/07/18   
RIM2011-0022 Pih Ling 2011/10/05    
RIM2011-0018 Tom Song 2011/10/25    
RIM2011-0025  YP  2011-10-31    
RIM2011-0018b Tom Song 2011-12-09    
RIM2011-0018c YP   2011-12-14    
RIM2012-0002 Tom Song 2012-02-27  
RIM2012-0003 Tom Song 2012-02-27 
PVMI#2012-1005 Tom Song	
PVMI-SMN 2015/09/07 
PVMI - Extern PO Number and EMS Pull PO Tom Song
PVMI-SMN Zhang Yin 2015/11/10-12
PVMI-SMN Zhang Yin 2015/12/03

 Short Description:    
 CR2009-0016 Change field mapping     
 col011= ISNULL(OD1.FLAG1,''),col005=(OD1.BaxOriginalQty)    
CR2009-0025 Standardize filename format for 4 messages (940a, 940b, 856o, 945)     
CR2009-M011 CPA SKU truncated    
CR2008-0014 Partner Guideline Standardization  
SQL2008		single quote and set identifier on  
RIM2011-0022 Filename Changed    
RIM2011-0018 940a, 940b, 856 and 945 (CPO), get from discrepancy flag from flag2     
RIM2011-0025 SLI_AIM_IN_WMS.MPACODE = Select nsqldefault from nsqlconfig where configkey = 'Custcd'    
RIM2011-0018 940a, 940b, 856 and 945 (CPO), get from discrepancy flag from flag2     
RIM2011-0018b No 940b send out for ROI and HHT    
RIM2011-0018c DET 9- return ems code if allocation qty = 0 , else return vendor ID     
RIM2012-0002 Schenker SO# in HDR10   
RIM2012-0003 DET22- RETURN the country of origion    
PVMI#2012-1005 940b (Pull commit - discrepancy flag) - conflicting rules for base
 leon wang add qtypicked   for abb   2015-07-16  
PVMI-SMN 2015/09/07 
PVMI - Extern PO Number and EMS Pull PO 2015-10-08
PVMI-SMN Change email subject
PVMI-SMN RTV should not send eamil notification
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/    
    
Alter PROCEDURE [dbo].[SLI_EXPORT_940B]
AS 
    BEGIN    
     
    
    
        DECLARE @sysdate DATETIME    
    
        DECLARE @mpa_code VARCHAR(15)    
    
        DECLARE @storerkey VARCHAR(15)    
    
        DECLARE @keyname VARCHAR(30)    
    
        DECLARE @key VARCHAR(9)    
    
        DECLARE @dunsno VARCHAR(9)    
    
    
    
        DECLARE @hiRunId VARCHAR(10) ,
            @startdate DATETIME ,
            @enddate DATETIME ,
            @recordsProcessed VARCHAR(200) ,
            @sql VARCHAR(500) ,
            @spresult INT ,
            @Custcode VARCHAR(10) -- RIM2011-0022     
            ,
            @EMS_CODE CHAR(3) ,
            @MODEL_CODE CHAR(3) ,
            @hubcode VARCHAR(10) -- RIM2011-0025    
            ,
            @c_discrepancyflag_DET12 VARCHAR(30) ,
            @c_discrepancyflag_DET9 VARCHAR(30)
  
        DECLARE @SLI_940bEMAIL_FULL_ALLOC_flag VARCHAR(1) ,
            @SLI_940bEMAIL_OVER_ALLOC_flag VARCHAR(1) ,
            @SLI_940bEMAIL_PARTIAL_ALLOC_flag VARCHAR(1) ,
            @SLI_940bEMAIL_ZERO_ALLOC_flag VARCHAR(1),
            @SLI_940b_flag VARCHAR(1)
       
        --SMN-Remove by zhangyin 2015/09/08,begin     
        --SELECT  @SLI_940bEMAIL_flag = NSQLValue
        --FROM    NSQLCONFIG
        --WHERE   ConfigKey = 'SLI_940bEMAIL' ;	       
        --SELECT  @SLI_OVER_ALLOC_940bEMAIL_flag = NSQLValue
        --FROM    NSQLCONFIG
        --WHERE   ConfigKey = 'SLI_OVER_ALLOC_940bEMAIL' ;
        --SELECT  @SLI_PARTIAL_ALLOC_940bEMAIL_flag = NSQLValue
        --FROM    NSQLCONFIG
        --WHERE   ConfigKey = 'SLI_PARTIAL_ALLOC_940bEMAIL' ;   
        --SELECT  @SLI_Trigger_940b_flag = NSQLValue
        --FROM    NSQLCONFIG
        --WHERE   ConfigKey = 'SLI_Trigger_940b' ;          
		--SMN-Remove by zhangyin 2015/09/08,end
   
        SELECT  @Custcode = NSQLValue ,
                @hubcode = LTRIM(RTRIM(NSQLDefault))
        FROM    NSQLCONFIG -- RIM2011-0025    
        WHERE   ConfigKey = 'Custcd'     
    
        DECLARE @logfile VARCHAR(100)    
    
        DECLARE @MsgEnv VARCHAR(10)    
    
        DECLARE @b_success INT ,
            @n_err INT ,
            @c_errmsg VARCHAR(250)      
    
        SET @sysdate = GETDATE()    
  
 --- leon add  sort rule for temp table for abb for sweden   
        CREATE TABLE #TEMPTABLE1
            (
              WaveKey CHAR(10) COLLATE DATABASE_DEFAULT ,
              OrderKey CHAR(10) COLLATE DATABASE_DEFAULT ,
              storerkey CHAR(15) COLLATE DATABASE_DEFAULT ,
              export_flag CHAR(1) COLLATE DATABASE_DEFAULT
            )    
    
        CREATE TABLE #TEMPTABLE2
            (
              RecType CHAR(3) COLLATE DATABASE_DEFAULT ,
              col001 VARCHAR(240) COLLATE DATABASE_DEFAULT
                                  NULL ,
              col002 VARCHAR(240) COLLATE DATABASE_DEFAULT
                                  NULL ,
              col003 VARCHAR(240) COLLATE DATABASE_DEFAULT
                                  NULL ,
              col004 VARCHAR(240) COLLATE DATABASE_DEFAULT
                                  NULL ,
              col005 VARCHAR(240) COLLATE DATABASE_DEFAULT
                                  NULL ,
              col006 VARCHAR(240) COLLATE DATABASE_DEFAULT
                                  NULL ,
              col007 VARCHAR(240) COLLATE DATABASE_DEFAULT
                                  NULL ,
              col008 VARCHAR(240) COLLATE DATABASE_DEFAULT
                                  NULL ,
              col009 VARCHAR(240) COLLATE DATABASE_DEFAULT
                                  NULL ,
              col010 VARCHAR(240) COLLATE DATABASE_DEFAULT
                                  NULL ,
              col011 VARCHAR(240) COLLATE DATABASE_DEFAULT
                                  NULL ,
              col012 VARCHAR(240) COLLATE DATABASE_DEFAULT
                                  NULL ,
              col013 VARCHAR(240) COLLATE DATABASE_DEFAULT
                                  NULL ,
              col014 VARCHAR(240) COLLATE DATABASE_DEFAULT
                                  NULL ,
              col015 VARCHAR(240) COLLATE DATABASE_DEFAULT
                                  NULL ,
              col016 VARCHAR(240) COLLATE DATABASE_DEFAULT
                                  NULL ,
              col017 VARCHAR(240) COLLATE DATABASE_DEFAULT
                                  NULL ,
              col018 VARCHAR(240) COLLATE DATABASE_DEFAULT
                                  NULL ,
              col019 VARCHAR(240) COLLATE DATABASE_DEFAULT
                                  NULL ,
              col020 VARCHAR(240) COLLATE DATABASE_DEFAULT
                                  NULL ,
              col021 VARCHAR(240) COLLATE DATABASE_DEFAULT
                                  NULL ,
              col022 VARCHAR(240) COLLATE DATABASE_DEFAULT
                                  NULL ,
              col023 VARCHAR(240) COLLATE DATABASE_DEFAULT
                                  NULL ,
              col024 VARCHAR(240) COLLATE DATABASE_DEFAULT
                                  NULL ,
              col025 VARCHAR(240) COLLATE DATABASE_DEFAULT
                                  NULL ,
              MpaCode VARCHAR(20) COLLATE DATABASE_DEFAULT ,
              SO VARCHAR(20) COLLATE DATABASE_DEFAULT ,
              pid VARCHAR(50) COLLATE DATABASE_DEFAULT
            )    
 
        INSERT  INTO #TEMPTABLE1        
-- 27 Feb 2008 use Orders.SO to link with the Parent SO    
                SELECT DISTINCT
                        O.SO ,
                        o.OrderKey ,
                        o.storerkey ,    
    
--CASE WHEN O.STORERKEY LIKE 'C%' OR o.PH='OST' THEN 'Y' ELSE 'N' END    
                        CASE WHEN O.STORERKEY LIKE 'M%'
								  --PVMI-SMN Change by zhangyin 2015/12/03,begin
                                  --OR o.PH = 'HHT' 
                                  OR o.PH IN ('HHT','RTV') 
                                  --PVMI-SMN Change by zhangyin 2015/12/03,end
                             THEN 'N'
                                  
                             ELSE 'Y'
                        END  --No 940b send out for ROI and HHT    
                FROM    TransmitLog t ( NOLOCK ) ,
                        WaveDetail wd ( NOLOCK ) ,
                        Orders o ( NOLOCK ) ,
                        SLI_Partner_Messages PMsg ( NOLOCK )
                WHERE   t.TableName = '940B'
                        AND t.TransmitFlag = '0'
                        AND t.Key1 = O.SO
                        AND wd.OrderKey = o.OrderKey
                        AND PMsg.MessageType = '940B'    
--RIM2011-0018 940a, 940b, 856 and 945 (CPO)    
                        AND PMsg.PartnerCode = CASE WHEN ( o.Storerkey LIKE 'ANY%' )
                                                    THEN SUBSTRING(O.STORERKEY,
                                                              4, 20)
                                                    ELSE SUBSTRING(O.STORERKEY,
                                                              2,
                                                              CHARINDEX('-',
                                                              O.STORERKEY, 1)
                                                              - 2)
                                               END
                ORDER BY O.SO ,
                        o.OrderKey ,
                        o.storerkey    
   
-- 2011-11-07 set the export flag for parent orders.    
        UPDATE  #TEMPTABLE1
        SET     export_flag = 'Y'
        WHERE   storerkey LIKE 'ANY%'
                AND WaveKey IN ( SELECT WaveKey
                                 FROM   #TEMPTABLE1
                                 WHERE  export_flag = 'Y'
                                        AND storerkey LIKE 'C%' )    
    
    
--select * from #TEMPTABLE1     --for test zhangyin 2015/09/15
    
        IF NOT EXISTS ( SELECT  COUNT(1)
                        FROM    #TEMPTABLE1 ) 
            BEGIN    
    
                DROP TABLE #TEMPTABLE1    
    
                DROP TABLE #TEMPTABLE2    
    
                RETURN    
    
            END     
    
        SELECT  @StartDate = GETDATE()    
    
    
    
    
    
-- ===== Envelope ==========================================    
    
        SELECT TOP 1
                @dunsno = ISNULL(RTRIM(code), '')
        FROM    CODELKUP(NOLOCK)
        WHERE   listname = 'SCHDUNS'     
    
        SELECT  @MsgEnv = Code
        FROM    Codelkup
        WHERE   listname = 'MsgEnv'    
    
        DECLARE ordercur CURSOR
        FOR
            SELECT DISTINCT
                    UPPER(storerkey)
            FROM    #TEMPTABLE1
            WHERE   storerkey LIKE 'ANY%'
            ORDER BY UPPER(storerkey) ;
     
        OPEN ordercur    
    
        FETCH NEXT FROM ordercur INTO @storerkey    
    
        WHILE @@fetch_status = 0 
            BEGIN    
    
                SET @mpa_code = SUBSTRING(@storerkey, 4, 20)   
                SELECT  @EMS_CODE = CASE WHEN LEFT(@storerkey, 3) = 'ANY'
                                         THEN SUBSTRING(@storerkey, 4, 3)
                                         ELSE SUBSTRING(@storerkey, 2, 3)
                                    END   
                EXEC SLI_GetModel_Code @EMS_CODE, @MODEL_CODE OUTPUT,
                    @b_success OUTPUT, @n_err OUTPUT, @c_errmsg OUTPUT    
                IF @n_err > 0 
                    CONTINUE    
				
                SET @keyname = '940b_' + @mpa_code    
    
                SELECT  @c_discrepancyflag_DET12 = 'STD2'
                SELECT  @c_discrepancyflag_DET12 = configvalue
                FROM    SLI_CONFIG
                WHERE   Configkey = '940b_discrepancyflag_DET12'
                        AND ConfigID = @EMS_CODE
                SELECT  @c_discrepancyflag_DET9 = 'STD2'
                SELECT  @c_discrepancyflag_DET9 = configvalue
                FROM    SLI_CONFIG
                WHERE   Configkey = '940b_discrepancyflag_DET9'
                        AND ConfigID = @EMS_CODE
				--SMN-Add by zhangyin 2015/09/08,begin         
				SELECT  @SLI_940bEMAIL_FULL_ALLOC_flag = ConfigValue
				FROM    SLI_Config 
				WHERE   ConfigKey = 'SLI_940bEMAIL_FULL_ALLOC' AND ConfigID=@EMS_CODE ;
		        	       
				SELECT  @SLI_940bEMAIL_OVER_ALLOC_flag = ConfigValue
				FROM    SLI_Config
				WHERE   ConfigKey = 'SLI_940bEMAIL_OVER_ALLOC' AND ConfigID=@EMS_CODE ;
		        
				SELECT  @SLI_940bEMAIL_PARTIAL_ALLOC_flag = ConfigValue
				FROM    SLI_Config
				WHERE   ConfigKey = 'SLI_940bEMAIL_PARTIAL_ALLOC' AND ConfigID=@EMS_CODE ; 
		        
				SELECT  @SLI_940bEMAIL_ZERO_ALLOC_flag = ConfigValue
				FROM    SLI_Config 
				WHERE   ConfigKey = 'SLI_940bEMAIL_ZERO_ALLOC' AND ConfigID=@EMS_CODE;	
		          
				SELECT  @SLI_940b_flag = ConfigValue
				FROM    SLI_Config
				WHERE   ConfigKey = 'SLI_940b' AND ConfigID=@EMS_CODE;          
				--SMN-Add by zhangyin 2015/09/08,end  
    
                EXEC nspg_getkey @keyname, 9, @key OUTPUT, NULL, NULL, NULL    
    
                IF LEFT(@key, 6) <> RIGHT(CONVERT(CHAR(8), @sysdate, 112), 6) 
                    BEGIN    
    
                        SET @key = RIGHT(CONVERT(CHAR(8), @sysdate, 112), 6)
                            + '001'    
    
                        UPDATE  ncounter
                        SET     keycount = @key
                        WHERE   keyname = @keyname    
    
                    END    
    
    
    
                EXEC nspg_getkey 'HIRUN', 10, @hirunid OUTPUT, NULL, NULL,
                    NULL    
    
    
    
                INSERT  hierror
                        ( hierrorgroup ,
                          errortext ,
                          errortype ,
                          sourcekey 
                        )
                        SELECT  @hiRunId ,
                                'Initiallizing....   hierror: ' + @hiRunId ,
                                'GENERAL' ,
                                '940b'    
    
                INSERT  INTO hiError
                        ( HiErrorGroup ,
                          ErrorText ,
                          ErrorType ,
                          SourceKey ,
                          AddDate ,
                          AddWho ,
                          EditDate ,
                          EditWho
                        )
                VALUES  ( @hiRunId ,
                          '940b Export started at '
                          + CONVERT(VARCHAR, @StartDate) ,
                          'GENERAL' ,
                          '940b' ,
                          GETDATE() ,
                          LEFT(SUSER_SNAME(), 18) ,
                          GETDATE() ,
                          LEFT(SUSER_SNAME(), 18)
                        )    
    
    
    
                INSERT  INTO hiError
                        ( HiErrorGroup ,
                          ErrorText ,
                          ErrorType ,
                          SourceKey ,
                          AddDate ,
                          AddWho ,
                          EditDate ,
                          EditWho
                        )
                VALUES  ( @hiRunId ,
                          'Export file - ' + RTRIM(@keyname) + '_'
                          + CONVERT(VARCHAR(8), @StartDate, 112) + '_'
                          + RIGHT(@key, 3) ,
                          'GENERAL' ,
                          '940b' ,
                          GETDATE() ,
                          LEFT(SUSER_SNAME(), 18) ,
                          GETDATE() ,
                          LEFT(SUSER_SNAME(), 18)
                        ) ;  
       
  -- ===== Header ============================================     
    
  -- Insert into #TEMPTABLE2 (RecType, col001,col002, col003, col004, col005, col006, col007, col008, col009, col010, col011)    
 
                IF ( @SLI_940bEMAIL_FULL_ALLOC_flag = '1'
                     OR @SLI_940bEMAIL_OVER_ALLOC_flag = '1'
                     OR @SLI_940bEMAIL_PARTIAL_ALLOC_flag = '1'
                     OR @SLI_940bEMAIL_ZERO_ALLOC_flag = '1'
                   ) 
                   
                    BEGIN 

                        INSERT  INTO #TEMPTABLE2
                                SELECT  RecType = CASE  WHEN ISNULL(b.qtyallocated,0) = 0 THEN '130' --zero alloc
														WHEN a.BaxOriginalQty > ISNULL(b.qtyallocated,
                                                              0) AND ISNULL(b.qtyallocated,0) <> 0 THEN '100' --partial alloc
                                                       WHEN a.BaxOriginalQty < ISNULL(b.qtyallocated,
                                                              0) THEN '110' --over alloc
                                                       ELSE '120' --full alloc
                                                  END ,
                                        col001 = a.ExternOrderKey ,
                                        col002 = a.ExternLineNo ,
                                        --col003 = a.BINLocation ,
                                        col003 = CASE WHEN ISNULL(b.BinLocation, '') = ''
												  THEN ( CASE WHEN @c_discrepancyflag_DET9 = 'STD1'
																  AND ISNULL(b.QTYALLOCATED,
																  0) = 0 THEN ''
															  ELSE a.S_Company
														 END )
												  ELSE LEFT(ISNULL(b.BinLocation,
																  ''), 15)
                                         END , 
                                        col004 = a.sku ,
                                        col005 = CONVERT(VARCHAR(20), a.BaxOriginalQty) ,
                                        col006 = ISNULL(CONVERT(VARCHAR(20), b.qtyallocated),
                                                        0) ,
                                        col007 = '' ,
                                        col008 = '' ,
                                        col009 = '' ,
                                        col010 = '' ,
                                        col011 = '' ,
                                        col012 = '' ,
                                        col013 = '' ,
                                        col014 = '' ,
                                        col015 = '' ,
                                        col016 = '' ,
                                        col017 = '' ,
                                        col018 = '' ,
                                        col019 = '' ,
                                        col020 = '' ,
                                        col021 = '' ,
                                        --SMN-Add by zhangyin 2015/11/10,begin
                                        --col022 = '' ,
                                        col022 = ISNULL(a.Notes1,''),
                                        --SMN-Add by zhangyin 2015/11/10,end
                                        col023 = '' ,
                                        col024 = '' ,
                                        col025 = 'email' ,
                                        @mpa_code ,
                                        '' ,
                                        @hirunid
                                FROM    ( SELECT    OD.ExternOrderKey ,
                                                    OD.ExternLineNo ,
                                                    OD.BaxOriginalQty ,
                                                    OD.BINLocation ,
                                                    OD.Sku,
                                                    O.S_Company --SMN-ADD by zhangyin 2015/09/11
                                                    ,OrdersExt.Notes1 --SMN-Add by zhangyin 2015/11/10
                                          FROM      ORDERS (NOLOCK) O ,
                                                    ORDERDETAIL (NOLOCK) OD
                                                    ,OrdersExt(NOLOCK) --SMN-Add by zhangyin 2015/11/10
                                          WHERE     O.OrderKey = OD.OrderKey
													AND O.OrderKey=OrdersExt.OrderKey --SMN-Add by zhangyin 2015/11/10
                                                    AND O.OrderKey IN (
                                                    SELECT  OrderKey
                                                    FROM    #TEMPTABLE1
                                                    WHERE   STORERKEY = @storerkey
                                                            AND export_flag = 'Y'
                                                            AND StorerKey LIKE 'any%' )
                                        ) a
                                        LEFT JOIN ( SELECT  OD.ExternOrderKey ,
                                                            OD.ExternLineNo ,
                                                            SUBSTRING(OD.StorerKey,
                                                              6, 10) AS suppliercode ,
                                                            OD.Sku ,
                                                            SUM(OD.QtyAllocated
                                                              + OD.shippedqty
                                                              + OD.QtyPicked) qtyallocated	  -- leon wang update	    add qtyshipped  and qtypicked	   2015-07-16
															,OD.BINLocation  --SMN-Add by zhangyin 2015/09/11
                                                    FROM    ORDERS (NOLOCK) O ,
                                                            ORDERDETAIL (NOLOCK) OD
                                                    WHERE   O.OrderKey = OD.OrderKey
                                                            AND O.SO IN (
                                                            SELECT
                                                              OrderKey
                                                            FROM
                                                              #TEMPTABLE1
                                                            WHERE
                                                              STORERKEY = @storerkey
                                                              AND export_flag = 'Y'
                                                              AND storerkey LIKE 'any%' )
                                                            AND O.SO <> O.OrderKey
                                                    GROUP BY OD.ExternOrderKey ,
                                                            OD.ExternLineNo ,
                                                            OD.storerkey ,
                                                            OD.sku,
                                                            OD.BINLocation	--SMN-Add by zhangyin 2015/09/11
                                                  ) b ON a.externorderkey = b.externorderkey
                                                         AND a.externlineno = b.externlineno		

	  --- leon wang add for abb 
						--PRINT 'test1'
						--SELECT * FROM #TEMPTABLE1
						--SELECT * FROM #TEMPTABLE2
                        IF @SLI_940bEMAIL_OVER_ALLOC_flag = '0' 
                            BEGIN
                                DELETE  #TEMPTABLE2
                                WHERE   RecType = '110'
                            END 
	   
                        IF  @SLI_940bEMAIL_PARTIAL_ALLOC_flag = '0' 
                            BEGIN
                                DELETE  #TEMPTABLE2
                                WHERE   RecType = '100'
                            END 
                            
                        IF  @SLI_940bEMAIL_ZERO_ALLOC_flag = '0' 
                            BEGIN
                                DELETE  #TEMPTABLE2
                                WHERE   RecType = '130'
                            END 
	   
                        IF @SLI_940bEMAIL_FULL_ALLOC_flag = '0' 
                            BEGIN
                                DELETE  #TEMPTABLE2
                                WHERE   RecType = '120'
                            END 
	    
                        INSERT  INTO #TEMPTABLE2
                                SELECT	DISTINCT
                                        RecType = '000' ,
                                        col001 = @dunsno + @mpa_code ,
                                        col002 = CONVERT(CHAR(8), @sysdate, 112)
                                        + SUBSTRING(CONVERT(CHAR, @sysdate, 114),
                                                    1, 2)
                                        + SUBSTRING(CONVERT(CHAR, @sysdate, 114),
                                                    4, 2)
                                        + SUBSTRING(CONVERT(CHAR, @sysdate, 114),
                                                    7, 2) ,     
	    
	   -- RIM2011-0022  col003 = rtrim(@keyname) + '_' + convert(char(8), @sysdate, 112) + Substring(CONVERT(CHAR, @sysdate,114),1,2) + Substring(CONVERT(CHAR, @sysdate,114),4,2) + Substring(CONVERT(CHAR, @sysdate,114),7,2) + Substring(CONVERT(CHAR, @sysdate,114),10,3) + '_' +  RIGHT(@key, 3),    
                                        col003 =
                                         --RTRIM(LTRIM(LEFT(ISNULL(SUBSTRING(a.Notes1,
                                         --                     1,
                                         --                     ( CASE CHARINDEX('-',
                                         --                     a.Notes1)
                                         --                     WHEN 0 THEN 1
                                         --                     ELSE CHARINDEX('-',
                                         --                     a.Notes1)
                                         --                     END ) - 1), ''),
                                         --                     20))) + '_'
                                         --SMN-Remove by zhangyin 2015/09/11
                                        + RTRIM(LTRIM(ExternOrderKey)) + '_'                                        
                                        --+ '940b2b_' + RTRIM(@custcode) + '_'
                                        + '940bEmail_' + RTRIM(@custcode) + '_'	--SMN-Change by zhangyin 2015/09/11
                                        + RTRIM(@mpa_code) + '_'
                                        + CONVERT(CHAR(8), @sysdate, 112)
                                        + SUBSTRING(CONVERT(CHAR, @sysdate, 114),
                                                    1, 2)
                                        + SUBSTRING(CONVERT(CHAR, @sysdate, 114),
                                                    4, 2)
                                        + SUBSTRING(CONVERT(CHAR, @sysdate, 114),
                                                    7, 2)
                                        + SUBSTRING(CONVERT(CHAR, @sysdate, 114),
                                                    10, 3) + '_' + RIGHT(@key,
                                                              3) ,
                                        col004 = @MsgEnv ,
                                        col005 = '' ,
                                        col006 = '' ,
                                        col007 = a.ExternOrderKey ,
                --                        col008 = LEFT(ISNULL(SUBSTRING(a.Notes1,
																--1,
                --                                              ( CASE CHARINDEX('-',
                --                                              a.Notes1)
                --                                              WHEN 0 THEN 1
                --                                              ELSE CHARINDEX('-',
                --                                              a.Notes1)
                --                                              END ) - 1), ''),
                --                                      20) ,
										col008 = CASE CHARINDEX('-',a.Notes1) 
							WHEN 0 THEN ISNULL(LTRIM(RTRIM((a.Notes1))),'')
							ELSE  ISNULL(LTRIM(RTRIM(SUBSTRING(a.Notes1,CHARINDEX('-',a.Notes1)+1,LEN(a.Notes1)-CHARINDEX('-',a.Notes1)))),'')
							END, 
                                                       --SMN-Change by zhangyin 2015/09/15,get buyer name
                                        --col009 = '' ,
                                        col009 = a.InternalNote01,--SMN-Change by zhangyin 2015/09/11
                                        col010 = '' ,
                                        col011 = '' ,
                                        col012 = '' ,
                                        col013 = '' ,
                                        col014 = '' ,
                                        col015 = '' ,
                                        col016 = '' ,
                                        col017 = '' ,
                                        col018 = '' ,
                                        col019 = '' ,
                                        col020 = '' ,
                                        --SMN-Change by zhangyin 2015/11/10,begin
                                        --col021 = '' ,
                                        --col022 = '' ,
                                        col021 = a.POLineNumber ,
                                        col022 = #TEMPTABLE2.col022,
                                        --SMN-Change by zhangyin 2015/11/10,end
                                        col023 = a.ExternOrderKey ,
                                        col024 = '' ,
                                        col025 = 'email' ,
                                        @mpa_code ,
                                        '' ,
                                        @hirunid
                                FROM    #TEMPTABLE2 ,
										
             --                           ( SELECT     
													--externorderkey ,
             --                                       Notes1,
             --                                       InternalNote01 --SMN-Change by zhangyin 2015/09/11
             --                             FROM      ORDERDETAIL
                                          --WHERE     OrderKey IN (
                                          --          SELECT  OrderKey
                                          --          FROM    #TEMPTABLE1
                                          --          WHERE   STORERKEY = @storerkey
                                          --                  AND export_flag = 'Y'
                                          --                  AND StorerKey LIKE 'any%' )		                                         
                                        --) a
                                        
                                        --------
                                        (SELECT OD1.externorderkey,
												OD1.Notes1,
												OD1.InternalNote01,
												--SMN-Add by zhangyin 2015/11/10,begin
												OD1.POLineNumber
												--SMN-Add by zhangyin 2015/11/10,end
										FROM
											(SELECT externorderkey, 
													externlineno,
													Notes1,
													InternalNote01,
													--SMN-Add by zhangyin 2015/11/10,begin
													POLineNumber
													--SMN-Add by zhangyin 2015/11/10,end
											FROM ORDERDETAIL
												
											WHERE OrderKey IN (
                                                    SELECT  OrderKey
                                                    FROM    #TEMPTABLE1
                                                    WHERE   STORERKEY = @storerkey
                                                            AND export_flag = 'Y'
                                                            AND StorerKey LIKE 'any%' )) OD1,

											(SELECT externorderkey,max(externlineno) AS MaxLine
																	FROM      ORDERDETAIL
																	WHERE     OrderKey IN (
																					SELECT  OrderKey
																					FROM    #TEMPTABLE1
																					WHERE   STORERKEY = @storerkey
																							AND export_flag = 'Y'
																							AND StorerKey LIKE 'any%' )
																	GROUP BY externorderkey ) OD2
										WHERE OD1.externorderkey=OD2.externorderkey
											  AND OD1.externlineno=OD2.MaxLine) a
                                        --------
                                WHERE   RecType IN ( '100', '110', '120','130' )
                                        AND mpacode = @mpa_code
                                        AND #TEMPTABLE2.col001 = a.ExternOrderKey 
                                       

                        --UPDATE  #TEMPTABLE2
                        --SET     col005 = CAST(a.recttype AS VARCHAR) ,
                        --        col006 = a.mrectype
                        --FROM    ( SELECT    COUNT(DISTINCT RecType) recttype ,
                        --                    MAX(rectype) mrectype ,
                        --                    col001
                        --          FROM      #TEMPTABLE2
                        --          WHERE     RecType IN ( '100', '110', '120','130' )
                        --                    AND mpacode = @mpa_code
                        --          GROUP BY  col001
                        --        ) a
                        --WHERE   #TEMPTABLE2.RecType = '000'
                        --        AND #TEMPTABLE2.col001 = @dunsno + @mpa_code
                        --        AND #TEMPTABLE2.col007 = a.col001   
                                
                        --SMN-Add by zhangyin 2015/09/09,begin
                         DECLARE @c_orderno VARCHAR(20)
                         DECLARE @c_RecType VARCHAR(250)
						 DECLARE @c_RecTypes VARCHAR(250)
						 DECLARE C2 CURSOR
								FOR
									SELECT DISTINCT col001
									FROM    #TEMPTABLE2
									WHERE RecType IN ( '100', '110', '120','130' )
										AND mpacode = @mpa_code
										
								OPEN C2    
								FETCH NEXT FROM C2 INTO @c_orderno    
								
								WHILE @@fetch_status = 0 
									BEGIN    
										SELECT @c_RecTypes='',@c_RecType=''
										DECLARE C1 CURSOR
												FOR
													SELECT DISTINCT RecType
													FROM    #TEMPTABLE2
													WHERE RecType IN ( '100', '110', '120','130' )
														AND mpacode = @mpa_code
														AND col001 = @c_orderno
												OPEN C1    
												FETCH NEXT FROM C1 INTO @c_RecType    
												WHILE @@fetch_status = 0 
													BEGIN    
														SELECT @c_RecTypes = @c_RecTypes + '-' + @c_RecType
														FETCH NEXT FROM C1 INTO @c_RecType
													END
										 CLOSE C1     
										 DEALLOCATE C1 
										 
										  UPDATE  #TEMPTABLE2
											SET    col006 = @c_RecTypes
											
											WHERE   #TEMPTABLE2.RecType = '000'
													AND #TEMPTABLE2.col007 = @c_orderno
													  
                                 
										FETCH NEXT FROM C2 INTO @c_orderno
									END
						 CLOSE C2     
						 DEALLOCATE C2 	 
						 --SMN-Add by zhangyin 2015/09/09,end
	
                    END  
	        
                INSERT  INTO #TEMPTABLE2
                        SELECT		DISTINCT
                                RecType = 'ENV' ,
                                col001 = @dunsno + @mpa_code ,
                                col002 = CONVERT(CHAR(8), @sysdate, 112)
                                + SUBSTRING(CONVERT(CHAR, @sysdate, 114), 1, 2)
                                + SUBSTRING(CONVERT(CHAR, @sysdate, 114), 4, 2)
                                + SUBSTRING(CONVERT(CHAR, @sysdate, 114), 7, 2) ,     
		    
		   -- RIM2011-0022  col003 = rtrim(@keyname) + '_' + convert(char(8), @sysdate, 112) + Substring(CONVERT(CHAR, @sysdate,114),1,2) + Substring(CONVERT(CHAR, @sysdate,114),4,2) + Substring(CONVERT(CHAR, @sysdate,114),7,2) + Substring(CONVERT(CHAR, @sysdate,114),10,3) + '_' +  RIGHT(@key, 3),    
                                col003 = '940b_' + RTRIM(@custcode) + '_'
                                + RTRIM(@mpa_code) + '_'
                                + CONVERT(CHAR(8), @sysdate, 112)
                                + SUBSTRING(CONVERT(CHAR, @sysdate, 114), 1, 2)
                                + SUBSTRING(CONVERT(CHAR, @sysdate, 114), 4, 2)
                                + SUBSTRING(CONVERT(CHAR, @sysdate, 114), 7, 2)
                                + SUBSTRING(CONVERT(CHAR, @sysdate, 114), 10,
                                            3) + '_' + RIGHT(@key, 3) ,
                                col004 = @MsgEnv ,
                                col005 = '' ,
                                col006 = '' ,
                                col007 = '' ,
                                col008 = '' ,
                                col009 = '' ,
                                col010 = '' ,
                                col011 = '' ,
                                col012 = '' ,
                                col013 = '' ,
                                col014 = '' ,
                                col015 = '' ,
                                col016 = '' ,
                                col017 = '' ,
                                col018 = '' ,
                                col019 = '' ,
                                col020 = '' ,
                                col021 = '' ,
                                col022 = '' ,
                                col023 = '' ,
                                col024 = '' ,
                                col025 = '' ,
                                @mpa_code ,
                                '' ,
                                @hirunid	

    
                INSERT  INTO #TEMPTABLE2
                        SELECT  RecType = '0' ,
                                col001 = 0 ,
                                col002 = LEFT(ISNULL(Orders.s_company, ''), 15) ,    
 /* Updated By Becky Fu, 10 Oct 08, extend Pull request# from 15 to 20 */
                                col003 = LEFT(ISNULL(Orders.ExternOrderKey, ''),
                                              20) ,
                                col004 = CONVERT(CHAR(8), orders.orderdate, 112)
                                + SUBSTRING(CONVERT(CHAR, Orders.orderdate, 114),
                                            1, 2)
                                + SUBSTRING(CONVERT(CHAR, Orders.orderdate, 114),
                                            4, 2) ,
                                col005 = ISNULL(Orders.s_company1, '') ,
                                col006 = ISNULL(Ordersext.Notes1, '')
                                + ISNULL(Ordersext.Notes2, '')
                                + ISNULL(Ordersext.Notes3, '') ,
                                col007 = CONVERT(CHAR(8), orders.DeliveryDate, 112)
                                + SUBSTRING(CONVERT(CHAR, Orders.DeliveryDate, 114),
                                            1, 2)
                                + SUBSTRING(CONVERT(CHAR, Orders.DeliveryDate, 114),
                                            4, 2) ,
                                col008 = LEFT(ISNULL(Orders.PH, ''), 20) ,    
      
  -- RIM2012-0002 col009=LEFT(ISNULL(Orders.PE, ''), 20),  
                                col009 = LEFT(ISNULL(Orders.SO, ''), 20) ,
                                col010 = LEFT(ISNULL(Orders.KK, ''), 20) ,
                                col011 = LEFT(ISNULL(( SELECT TOP 1
                                                              CODELKUP.description
                                                       FROM   CODELKUP(NOLOCK)
                                                       WHERE  CODELKUP.listname = 'ORDRPRIOR'
                                                              AND Orders.Priority = CODELKUP.code
                                                     ), ''), 15) ,
                                col012 = '' ,
                                col013 = '' ,
                                col014 = '' ,
                                col015 = '' ,
                                col016 = '' ,
                                col017 = '' ,
                                col018 = '' ,
                                col019 = '' ,
                                col020 = '' ,
                                col021 = '' ,
                                col022 = '' ,
                                col023 = '' ,
                                col024 = '' ,
                                col025 = '' ,  --col025 = export_flag,    
                                @mpa_code ,    
 /* Updated By Becky Fu, 10 Oct 08, extend Pull request# from 15 to 20 */
                                LEFT(ISNULL(Orders.SO, ''), 20) ,
                                @hirunid
                        FROM    Orders(NOLOCK) ,
                                OrdersExt(NOLOCK)    
 -- ,       (Select DISTINCT OrderKey,export_flag from  #TEMPTABLE1 WHERE STORERKEY LIKE 'ANY%') tmpord -- 2011-11-07     
                        WHERE   Orders.OrderKey IN (
                                SELECT  OrderKey
                                FROM    #TEMPTABLE1
                                WHERE   STORERKEY LIKE 'ANY%'
                                        AND export_flag = 'Y' )
                                AND  -- 2011-11-07     
                                Orders.OrderKey = OrdersExt.OrderKey
                                AND Orders.Storerkey = @storerkey -- AND -- 2011-11-07    
 -- tmpord.orderkey=Orders.OrderKey -- 2011-11-07    
                        ORDER BY ExternOrderKey    
    
    
 -- -- ===== Detail ============================================     
    

                PRINT 'aaaa==>storerkey=' + @storerkey + ' @mpa_code='
                    + @mpa_code + ' @MODEL_CODE=' + @MODEL_CODE
                    + ' @c_discrepancyflag_DET12=' + @c_discrepancyflag_DET12
                    + ' @c_discrepancyflag_DET9' + @c_discrepancyflag_DET9
                INSERT  INTO #TEMPTABLE2
                        SELECT  RecType = '1' ,    
 /* Updated By Becky Fu, 10 Oct 08, extend Pull request# from 15 to 20 */
                                col001 = LEFT(ISNULL(OD1.ExternOrderkey, ''),
                                              20) ,
                                col002 = LEFT(ISNULL(OD1.ExternLineNo, ''), 5) ,
                                col003 = UPPER(OD1.SKU) ,     
    
--    
                                col004 = ISNULL(OD1.RetailSKU, '') ,
                                col005 = ISNULL(OD1.BaxOriginalQty, 0) ,    /*col005=(OD1.OPENQTY)  CR2009-0016 */
                                col006 = 'EA' ,
                                col007 = ISNULL(SUBSTRING(OD1.Instruction,
                                                          CHARINDEX('-',
                                                              OD1.Instruction)
                                                          + 1, 20), '') ,     
    
  --col008=CASE WHEN ISNULL(OD2.BinLocation, '')='' THEN SUBSTRING(STORER.STORERKEY,4,10) ELSE LEFT(ISNULL(OD2.BinLocation, ''), 15) END,     
  --PVMI#2012-1005 col008=CASE WHEN ISNULL(OD2.BinLocation, '')='' THEN OD1.S_Company ELSE LEFT(ISNULL(OD2.BinLocation, ''), 15) END, -- RIM2011-0018c    
                                col008 = CASE WHEN ISNULL(OD2.BinLocation, '') = ''
                                              THEN ( CASE WHEN @c_discrepancyflag_DET9 = 'STD1'
                                                              AND ISNULL(OD2.QTYALLOCATED,
                                                              0) = 0 THEN ''
                                                          ELSE OD1.S_Company
                                                     END )
                                              ELSE LEFT(ISNULL(OD2.BinLocation,
                                                              ''), 15)
                                         END , 
   /*    
    col008=ISNULL(CASE WHEN OD2.QtyAllocated>0 THEN OD1.S_Company WHEN @MODEL_CODE='VMI' THEN ISNULL(OD2.BinLocation, SUBSTRING(STORER.STORERKEY,4,10))     
                WHEN @MODEL_CODE = 'CPO' AND LEFT(STORER.STORERKEY,1)='M' AND ISNULL(OD2.QtyAllocated,0)=0  THEN OD1.S_Company     
                WHEN @MODEL_CODE = 'CPO' AND LEFT(STORER.STORERKEY,1)='C' AND ISNULL(OD2.QtyAllocated,0)=0 THEN OD2.BinLocation     
                WHEN @MODEL_CODE = 'CPO' AND LEFT(STORER.STORERKEY,1)='C' AND ISNULL(OD2.QtyAllocated,0)=0 AND (OD1.ph='OST') THEN OD2.BinLocation     
                ELSE OD2.BinLocation END,'') , */
                                col009 = ISNULL(OD1.DeliveryReference, '') ,
                                col010 = ISNULL(CONVERT(VARCHAR, OD2.QtyAllocated),
                                                '0') ,    
    
  --PVMI#2012-1005	col011= ISNULL(OD1.FLAG2,''), --ISNULL(OD1.FLAG1,''),  -- RIM2011-0008/* col011= OD1.FLAG1   CR2009-0016 */    
                                col011 = CASE @c_discrepancyflag_DET12
                                           WHEN 'STD1'
                                           THEN ISNULL(OD1.FLAG1, '')
                                           ELSE ISNULL(OD1.FLAG2, '')
                                         END , --ISNULL(OD1.FLAG1,''),  -- RIM2011-0008/* col011= OD1.FLAG1   CR2009-0016 */    
 /*Narrative5.0 change back DET13 and DET14, change back to retrieve receiving PO.    
  /*For CPO, leave blank*/    
  col012=CASE  WHEN STORER.INSTRUCTIONS1='1' OR @MODEL_CODE='CPO' THEN '' WHEN STORER.INSTRUCTIONS1='2' THEN ISNULL(OD2.RPO,'') WHEN STORER.INSTRUCTIONS1='3' THEN ISNULL(OD1.PolineitemID, '') END,    
  /*For CPO, leave blank*/    
  col013=CASE  WHEN STORER.INSTRUCTIONS1='1' OR @MODEL_CODE='CPO' THEN '' WHEN STORER.INSTRUCTIONS1='2' THEN ISNULL(OD2.RPOLN,'') WHEN STORER.INSTRUCTIONS1='3' THEN ISNULL(OD1.POLineNumber, '') END,  --PO Line#*/    
                                col012 = ISNULL(CASE WHEN STORER.INSTRUCTIONS1 = '1'
                                                          OR @MODEL_CODE = 'CPO'
                                                     THEN ISNULL(OD2.CPO, '')
                                                     WHEN STORER.INSTRUCTIONS1 = '2'
                                                     THEN ISNULL(OD2.RPO, '')
                                                     WHEN STORER.INSTRUCTIONS1 = '3'
--PVMI - Extern PO Number and EMS Pull PO			 THEN ISNULL(OD1.PolineitemID,
													 THEN ISNULL(OD1.POLineNumber,
                                                              '')
                                                END, '') ,
                                col013 = ISNULL(CASE WHEN STORER.INSTRUCTIONS1 = '1'
                                                          OR @MODEL_CODE = 'CPO'
                                                     THEN ISNULL(OD2.CPOLN, '')
                                                     WHEN STORER.INSTRUCTIONS1 = '2'
                                                     THEN ISNULL(OD2.RPOLN, '')
                                                     WHEN STORER.INSTRUCTIONS1 = '3'
--PVMI - Extern PO Number and EMS Pull PO			 THEN ISNULL(OD1.POLineNumber,	
                                                     THEN ISNULL(OD1.PolineitemID,
                                                              '')
                                                END, '') ,  --PO Line#    
                                col014 = LEFT(ISNULL(SKU.ManufacturerSKU, ''), 50) ,
                                --col014 = LEFT(ISNULL(SKU.ManufacturerSKU, '')
                                        --      + ISNULL(SKU.Altsku, ''), 40) ,
                                col015 = ISNULL(CASE WHEN @model_code = 'CPO'
                                                     THEN ''
                                                     ELSE LEFT(ISNULL(SUBSTRING(OD1.Notes1,
                                                              1,
                                                              ( CASE CHARINDEX('-',
                                                              OD1.Notes1)
                                                              WHEN 0 THEN 1
                                                              ELSE CHARINDEX('-',
                                                              OD1.Notes1)
                                                              END ) - 1), ''),
                                                              20)
                                                END, '') ,
                                col016 = ISNULL(CASE WHEN @model_code = 'CPO'
                                                     THEN ''
                                                     ELSE ISNULL(SUBSTRING(OD1.Notes1,
                                                              CHARINDEX('-',
                                                              OD1.Notes1) + 1,
                                                              20), '')
                                                END, '') ,     
    
  --PVMI#2012-1005 col017=LEFT(ISNULL(Substring(OD1.Instruction, 1, CHARINDEX('-', OD1.Instruction) - 1), ''), 20),      
                                col017 = LEFT(ISNULL(SUBSTRING(OD1.Instruction,
                                                              1,
                                                              CASE
                                                              WHEN CHARINDEX('-',
                                                              OD1.Instruction) > 0
                                                              THEN CHARINDEX('-',
                                                              OD1.Instruction)
                                                              ELSE LEN(OD1.Instruction)
                                                              + 1
                                                              END - 1), ''),
                                              20) ,
                                col018 = LEFT(ISNULL(OD1.Notes4, ''), 15) ,
                                col019 = LEFT(ISNULL(OD1.Lottable01, ''), 18) ,
                                col020 = LEFT(ISNULL(OD1.InternalNote01, ''),
                                              18) ,     
  
  --  col021 = LEFT(ISNULL(OD2.countryofOrigin, ''),18),  
                                col021 = LEFT(ISNULL(OD1.InternalNote02, ''),
                                              18) ,   --- leon change for abb   
                                col022 = LEFT(ISNULL(OD1.CustShipInst01, '')
                                              + ISNULL(OD1.CustShipInst02, '')
                                              + ISNULL(OD1.CustShipInst03, ''),
                                              240) ,    
    
  --col023 = '', col024 = '', col025 = '',    
  --RIM2012-0003 col023 = '', col024 = '', -- col025 = #TEMPTABLE1.export_flag, -- 2011-11-07    
  --col023 = LEFT(ISNULL(OD2.countryofOrigin, ''),18), col024 = '', -- col025 = #TEMPTABLE1.export_flag, -- 2011-11-07    
                                col023 = '' ,
                                col024 = '' ,
                                col025 = '' , -- 2011-11-07    
                                @mpa_code ,    
 /* Updated By Becky Fu, 10 Oct 08, extend Pull request# from 15 to 20 */
                                LEFT(ISNULL(OD1.WaveKey, ''), 20) ,
                                @hirunid
                        FROM    STORER
                                JOIN ( SELECT   ORDERDETAIL.* ,
                                                #TEMPTABLE1.WaveKey ,
                                                ORDERS.S_Company ,
                                                ORDERS.PH
                                       FROM     ORDERDETAIL(NOLOCK) ,
                                                #TEMPTABLE1 ,
                                                ORDERS (NOLOCK)
                                       WHERE    ORDERDETAIL.ORDERKEY = #TEMPTABLE1.ORDERKEY
                                                AND ORDERDETAIL.STORERKEY LIKE 'ANY%'    
    
 -- AND ORDERS.ORDERKEY=ORDERDETAIL.ORDERKEY AND ORDERDETAIL.STORERKEY=@storerkey  ) OD1 ON STORER.STORERKEY = OD1.STORERKEY --2011-11-07    
                                                AND ORDERS.ORDERKEY = ORDERDETAIL.ORDERKEY
                                                AND ORDERDETAIL.STORERKEY = @storerkey
                                                AND #TEMPTABLE1.export_flag = 'Y'
                                     ) OD1 ON STORER.STORERKEY = OD1.STORERKEY --2011-11-07    
                                LEFT JOIN ( SELECT  ORDERDETAIL.BinLocation ,
                                                    ORDERDETAIL.ExternOrderKey ,
                                                    ORDERDETAIL.ExternLineNo ,
                                                    ORDERDETAIL.SKU ,
                                                    #TEMPTABLE1.WaveKey ,
                                                    ORDERDETAIL.STORERKEY ,
                                                    ORDERDETAIL.ORDERKEY ,
                                                    QTYALLOCATED = SUM(PICKDETAIL.QTY) ,    
    
   --remarked by RIM2011-0018 CPO=ISNULL(ORDERDETAIL.ExternalNote02,''),CPOLN=ISNULL(ORDERDETAIL.ExternalNote03,''),    
                                                    CPO = ISNULL(PICKDETAIL.SerialNo,
                                                              '') ,
                                                    CPOLN = ISNULL(PICKDETAIL.BoxNumber,
                                                              '') ,
                                                    RPO = CASE STORER.INSTRUCTIONS1
                                                            WHEN '1' THEN ''
                                                            WHEN '2'
                                                            THEN ISNULL(PICKDETAIL.SerialNo,
                                                              '')
                                                            WHEN '3'
                                                            THEN ISNULL(ORDERDETAIL.PolineitemID,
                                                              '')
                                                          END ,
                                                    RPOLN = CASE STORER.INSTRUCTIONS1
                                                              WHEN '1' THEN ''
                                                              WHEN '2'
                                                              THEN ISNULL(PICKDETAIL.BoxNumber,
                                                              '')
                                                              WHEN '3'
                                                              THEN ISNULL(ORDERDETAIL.PolineitemID,
                                                              '')
                                                            END ,    
--RIM2012-0003    
                                                    countryofOrigin = ISNULL(RECEIPTDETAIL.CountryofOrigin,
                                                              '')    
    
--RIM2012-0003    
   --FROM ORDERDETAIL(NOLOCK), #TEMPTABLE1,PICKDETAIL(NOLOCK),STORER(NOLOCK),ORDERS(NOLOCK)    
                                            FROM    ORDERDETAIL(NOLOCK) ,
                                                    #TEMPTABLE1 ,
                                                    PICKDETAIL(NOLOCK) ,
                                                    STORER(NOLOCK) ,
                                                    ORDERS(NOLOCK) ,
                                                    LOTATTRIBUTE (NOLOCK) ,
                                                    RECEIPTDETAIL (NOLOCK)    
    
   --RIM2012-0003   
                                            WHERE   LOTATTRIBUTE.lot = pickdetail.lot
                                                    AND LOTATTRIBUTE.lottable03 = RECEIPTDETAIL.Lottable03
                                                    AND ORDERDETAIL.ORDERKEY = #TEMPTABLE1.ORDERKEY
                                                    AND ORDERDETAIL.STORERKEY NOT LIKE 'ANY%'
                                                    AND ORDERDETAIL.ORDERKEY = PICKDETAIL.ORDERKEY
                                                    AND ORDERDETAIL.ORDERLINENUMBER = PICKDETAIL.ORDERLINENUMBER
                                                    AND ORDERS.OrderKey = ORDERDETAIL.OrderKey
                                                    AND STORER.STORERKEY LIKE 'ANY%'
                                                    AND SUBSTRING(STORER.STORERKEY,
                                                              4, 10) = SUBSTRING(ORDERDETAIL.STORERKEY,
                                                              2,
                                                              CHARINDEX('-',
                                                              ORDERDETAIL.STORERKEY)
                                                              - 2)
                                            GROUP BY #TEMPTABLE1.WaveKey ,
                                                    ORDERDETAIL.ExternOrderKey ,
                                                    ORDERDETAIL.ExternLineNo ,
                                                    ORDERDETAIL.BinLocation ,
                                                    ORDERDETAIL.SKU ,
                                                    ORDERDETAIL.STORERKEY ,
                                                    ORDERDETAIL.ORDERKEY ,
                                                    ISNULL(ORDERDETAIL.ExternalNote02,
                                                           '') ,
                                                    ISNULL(ORDERDETAIL.ExternalNote03,
                                                           '') ,
                                                    CASE STORER.INSTRUCTIONS1
                                                      WHEN '1' THEN ''
                                                      WHEN '2'
                                                      THEN ISNULL(PICKDETAIL.SerialNo,
                                                              '')
                                                      WHEN '3'
                                                      THEN ISNULL(ORDERDETAIL.PolineitemID,
                                                              '')
                                                    END ,
                                                    CASE STORER.INSTRUCTIONS1
                                                      WHEN '1' THEN ''
                                                      WHEN '2'
                                                      THEN ISNULL(PICKDETAIL.BoxNumber,
                                                              '')
                                                      WHEN '3'
                                                      THEN ISNULL(ORDERDETAIL.PolineitemID,
                                                              '')
                                                    END ,
                                                    ISNULL(PICKDETAIL.SerialNo,
                                                           '') ,
                                                    ISNULL(PICKDETAIL.BoxNumber,
                                                           '') ,    
 --RIM2012-0003   
                                                    ISNULL(RECEIPTDETAIL.CountryofOrigin,
                                                           '')
                                          ) OD2 ON OD1.WAVEKEY = OD2.WAVEKEY
                                                   AND OD1.ExternLineNo = OD2.ExternLineNo
                                                   AND OD1.ExternOrderKey = OD2.ExternOrderKey
                                LEFT JOIN SKU(NOLOCK) ON OD2.STORERKEY = SKU.STORERKEY
                                                         AND OD2.SKU = SKU.SKU    
    
  --Order By OrderDetail.ExternOrderKey, OrderDetail.ExternLineNo, OrderDetail.SKU    
    
--/* Begin of PG Standardisation **************************************** */    
                IF EXISTS ( SELECT  1
                            FROM    SLI_PartnerGuideline_Ctrl
                            WHERE   REFERENCE1 = 'Y'
                                    AND Messageid = '940b'
                                    AND HUB = @mpa_code ) 
                    BEGIN    
  ----if config table turn on then perform below checking--    
  -- Validation    
                        CREATE TABLE #RESULT
                            (
                              LineNumber INT ,
                              RecordType VARCHAR(5) ,
                              ElementID INT ,
                              ColumnName VARCHAR(50) ,
                              Value VARCHAR(250)
                            )    
       
                        SELECT  LineNumber = IDENTITY( INT, 1, 1 ),
                                *
                        INTO    #TmpTbl
                        FROM    #TEMPTABLE2    
    
                        DECLARE @i INT ,
                            @mi INT ,
                            @n_col INT ,
                            @j INT ,
                            @col_name VARCHAR(50) ,
                            @s_col INT    
                        DECLARE @c_SQLString NVARCHAR(4000) ,
                            @c_SQLString1 NVARCHAR(4000) ,
                            @c_SQLString2 NVARCHAR(4000) ,
                            @c_SQLString3 NVARCHAR(4000)     
       
                        SELECT  @i = 1 ,
                                @j = 1    
                        SELECT  @s_col = 2    
                        SELECT  @mi = COUNT(1)
                        FROM    #TmpTbl    
                       /*--MIG_DB2016_PB2017 SELECT  @n_col = info
                        FROM    tempdb.dbo.sysobjects
                        WHERE   id = OBJECT_ID(N'tempdb..#TmpTbl')  */   
						SELECT  @n_col = max(column_id)
                        FROM    tempdb.sys.columns
                        WHERE   OBJECT_ID = OBJECT_ID(N'tempdb..#TmpTbl') 
    
                        DELETE  FROM #RESULT    
    
   -- Start from column3    
                        SELECT  @j = @s_col    
                        WHILE @j <= @n_col 
                            BEGIN    
                               /*--MIG_DB2016_PB2017 SELECT  @col_name = name
                                FROM    tempdb.dbo.syscolumns
                                WHERE   id = OBJECT_ID(N'tempdb..#TmpTbl')
                                        AND colorder = @j    */
								SELECT  @col_name = name
                                FROM    tempdb.sys.columns
                                WHERE   OBJECT_ID = OBJECT_ID(N'tempdb..#TmpTbl')
                                        AND column_id = @j
    
                                SELECT  @c_SQLString = ' select LineNumber, RecType, '
                                        + CAST(@j - ( @s_col - 1 ) AS VARCHAR)
                                        + ',''' + @col_name + ''','
                                        + @col_name + ' from #TmpTbl '      
                                INSERT  INTO #RESULT
                                        EXECUTE sp_executesql @c_SQLString    
                                SELECT  @j = @j + 1    
                            END    
        
                        INSERT  INTO SLI_TMP_Validation
                                SELECT  @hirunid ,
                                        GETDATE() ,
                                        LineNumber ,
                                        messageid ,
                                        #RESULT.recordtype ,
                                        SLI_PartnerGuideline_Ctrl.ElementID ,
                                        SLI_PartnerGuideline_Ctrl.ElementName ,
                                        ColumnName ,
                                        Value ,
                                        Type ,
                                        FieldLength ,
                                        TruncateYN ,
                                        Is_Nullable = CASE WHEN Mandatory = 'Y'
                                                              AND RTRIM(LTRIM(ISNULL(CAST(Value AS VARCHAR),
                                                              ''))) = ''
                                                           THEN '0'
                                                           ELSE '1'
                                                      END ,
                                        Is_Numeric = CASE WHEN Type IN ( 'int',
                                                              'float' )
                                                              AND ISNUMERIC(Value) <> 1
                                                          THEN '0'
                                                          ELSE '1'
                                                     END ,
                                        Is_Length = CASE WHEN Type IN ( 'char',
                                                              'datetime' )
                                                              AND TruncateYN = 'N'
                                                              AND LEN(Value) > FieldLength
                                                         THEN '0'
                                                         ELSE '1'
                                                    END ,
                                        Is_Truncated = CASE WHEN Type IN (
                                                              'char',
                                                              'datetime' )
                                                              AND TruncateYN = 'Y'
                                                              AND LEN(Value) > FieldLength
                                                            THEN 'Y'
                                                            ELSE 'N'
                                                       END ,
                                        ValueT = CASE WHEN Type IN ( 'char',
                                                              'datetime' )
                                                           AND TruncateYN = 'Y'
                                                      THEN LEFT(LTRIM(CAST(Value AS VARCHAR)),
                                                              FieldLength)
                                                      ELSE Value
                                                 END ,
                                        '' ,
                                        '' ,
                                        '' ,
                                        ''
                                FROM    SLI_PartnerGuideline_Ctrl ,
                                        #RESULT
                                WHERE   messageid = '940b'
                                        AND CASE SLI_PartnerGuideline_Ctrl.recordtype
                                              WHEN 'HDR' THEN '0'
                                              WHEN 'DET' THEN '1'
                                              ELSE SLI_PartnerGuideline_Ctrl.recordtype
                                            END = #RESULT.recordtype
                                        AND SLI_PartnerGuideline_Ctrl.ElementID = #RESULT.ElementID
                                        AND ( CASE WHEN Mandatory = 'Y'
                                                        AND ISNULL(Value, '') = ''
                                                   THEN '0'
                                                   ELSE '1'
                                              END = '0'
                                              OR CASE WHEN Type IN ( 'int',
                                                              'float' )
                                                           AND ISNUMERIC(Value) <> 1
                                                      THEN '0'
                                                      ELSE '1'
                                                 END = '0'
                                              OR CASE WHEN Type IN ( 'char',
                                                              'datetime' )
                                                           AND TruncateYN = 'N'
                                                           AND LEN(Value) > FieldLength
                                                      THEN '0'
                                                      ELSE '1'
                                                 END = '0'
                                              OR CASE WHEN Type IN ( 'char',
                                                              'datetime' )
                                                           AND TruncateYN = 'Y'
                                                           AND LEN(Value) > FieldLength
                                                      THEN 'Y'
                                                      ELSE 'N'
                                                 END = 'Y'
                                            )    
    
    
                        UPDATE  SLI_TMP_Validation
                        SET     Is_Truncated = 'N'
                        WHERE   messageid = '940b'
                                AND HiError = @hirunid
                                AND LineNumber IN (
                                SELECT DISTINCT
                                        LineNumber
                                FROM    SLI_TMP_Validation
                                WHERE   messageid = '940b'
                                        AND HiError = @hirunid
                                        AND ( Is_Nullable = '0'
                                              OR Is_Numeric = '0'
                                              OR Is_Length = '0'
                                            ) )    
    
                        DELETE  FROM SLI_TMP_Validation
                        WHERE   messageid = '940b'
                                AND HiError = @hirunid
                                AND ( Is_Nullable = '1'
                                      AND Is_Numeric = '1'
                                      AND Is_Length = '1'
                                    )
                                AND Is_Truncated = 'N'    
    
                        DROP TABLE #RESULT    
    
                        SELECT  LN = IDENTITY( INT ,1,1 ),
                                SQLString1 = 'Update #TmpTbl Set '
                                + ColumnName + '=''' + Valuet + ''' WHERE '
                                + 'LineNumber = '
                                + CAST(LineNumber AS VARCHAR)
                        INTO    #tmp
                        FROM    SLI_TMP_Validation
                        WHERE   Is_Truncated = 'Y'
                                AND messageid = '940b'
                                AND HiError = @hirunid    
    
   /************update truncated values**/    
                        SELECT  @i = 1 ,
                                @j = MAX(ln)
                        FROM    #tmp    
                        WHILE @i <= @j 
                            BEGIN    
                                SELECT  @c_SQLString1 = SqlString1
                                FROM    #tmp
                                WHERE   ln = @i    
                                EXECUTE sp_executesql @c_SQLString1    
                                SET @i = @i + 1    
                            END    
    
                        DROP TABLE #tmp    
    
                        SELECT  LN = IDENTITY( INT ,1,1 ),
                                SQLString2 = 'DELETE FROM #TEMPTABLE2 WHERE SO = (SELECT SO FROM #TmpTbl WHERE LineNumber = '
                                + CAST(LineNumber AS VARCHAR) + ')' ,
                                SQLString3 = 'DELETE FROM #TEMPTABLE1 WHERE WaveKey = (SELECT SO FROM #TmpTbl WHERE LineNumber = '
                                + CAST(LineNumber AS VARCHAR) + ')'
                        INTO    #tmperr
                        FROM    SLI_TMP_Validation
                        WHERE   ( Is_Nullable = '0'
                                  OR Is_Numeric = '0'
                                  OR Is_Length = '0'
                                )
                                AND messageid = '940b'
                                AND HiError = @hirunid
                        GROUP BY LineNumber    
   /************delete error**/    
                        SELECT  @i = 1 ,
                                @j = MAX(ln)
                        FROM    #tmperr    
                        WHILE @i <= @j 
                            BEGIN    
                                SELECT  @c_SQLString2 = SqlString2 ,
                                        @c_SQLString3 = SqlString3
                                FROM    #tmperr
                                WHERE   ln = @i    
                                EXECUTE sp_executesql @c_SQLString2    
                                EXECUTE sp_executesql @c_SQLString3    
                                SET @i = @i + 1    
                            END    
    
                        DROP TABLE #tmperr    
                    END    
/* End of PG Standardisation ******************************************** */    
    
                SELECT  @recordsProcessed = CONVERT(VARCHAR, COUNT(1))
                FROM    #TEMPTABLE2    
    
                INSERT  INTO hiError
                        ( HiErrorGroup ,
                          ErrorText ,
                          ErrorType ,
                          SourceKey ,
                          AddDate ,
                          AddWho ,
                          EditDate ,
                          EditWho
                        )
                VALUES  ( @hiRunId ,
                          'Records Exported = ' + @recordsProcessed ,
                          'GENERAL' ,
                          '940b' ,
                          GETDATE() ,
                          LEFT(SUSER_SNAME(), 18) ,
                          GETDATE() ,
                          LEFT(SUSER_SNAME(), 18)
                        )    
    
    
    
                SELECT  @EndDate = GETDATE()    
    
    
    
                INSERT  INTO hiError
                        ( HiErrorGroup ,
                          ErrorText ,
                          ErrorType ,
                          SourceKey ,
                          AddDate ,
                          AddWho ,
                          EditDate ,
                          EditWho
                        )
                VALUES  ( @hiRunId ,
                          '940b Export end at ' + CONVERT(VARCHAR, @EndDate) ,
                          'GENERAL' ,
                          '940b' ,
                          GETDATE() ,
                          LEFT(SUSER_SNAME(), 18) ,
                          GETDATE() ,
                          LEFT(SUSER_SNAME(), 18)
                        )    
    
    
    
                INSERT  hierror
                        ( hierrorgroup ,
                          errortext ,
                          errortype ,
                          sourcekey 
                        )
                        SELECT  @hiRunId ,
                                'Ending....   hierror: ' + @hiRunId ,
                                'GENERAL' ,
                                '940b'    
    
    
    
    
    
                SELECT  @logfile = 'LOG_940b_'
                        + REPLACE(CONVERT(VARCHAR(10), GETDATE(), 120), '-',
                                  '') + '_' + @hiRunId    
    
    
    
                INSERT  INTO HIERRORSUMMARY
                        ( hirunid ,
                          edi ,
                          editype ,
                          status ,
                          start ,
                          finish ,
                          rtp ,
                          rp ,
                          logname
                        )
                VALUES  ( @hiRunId ,
                          '940b' ,
                          'EXPORT' ,
                          'OK' ,
                          CONVERT(CHAR(20), @StartDate, 120) ,
                          CONVERT(CHAR(20), @endDate, 120) ,
                          @recordsProcessed ,
                          @recordsProcessed ,
                          @logfile
                        )    
    
    
-- AIM CR# AIM_20090716    
                IF ISNULL(@mpa_code, '') <> ''
                    AND ISNULL(@keyname, '') <> '' 
                    BEGIN     
    
                        INSERT  INTO SLI_AIM_OUT_WMS    
/**CR2009-0025**/    
--        select   rtrim(@keyname) + '_' + convert(char(8), @sysdate, 112) + '_' + RIGHT(@key, 3)+'.txt',     
    --  RIM2011-0022   select    rtrim(@keyname) + '_' + convert(char(8), @sysdate, 112) + Substring(CONVERT(CHAR, @sysdate,114),1,2) + Substring(CONVERT(CHAR, @sysdate,114),4,2) + Substring(CONVERT(CHAR, @sysdate,114),7,2) + Substring(CONVERT(CHAR, @sysdate,114),10,3) + '_' +  RIGHT(@key, 3)+'.txt',     
                                SELECT  '940b_' + RTRIM(@custcode) + '_'
                                        + RTRIM(@mpa_code) + '_'
                                        + CONVERT(CHAR(8), @sysdate, 112)
                                        + SUBSTRING(CONVERT(CHAR, @sysdate, 114),
                                                    1, 2)
                                        + SUBSTRING(CONVERT(CHAR, @sysdate, 114),
                                                    4, 2)
                                        + SUBSTRING(CONVERT(CHAR, @sysdate, 114),
                                                    7, 2)
                                        + SUBSTRING(CONVERT(CHAR, @sysdate, 114),
                                                    10, 3) + '_' + RIGHT(@key,
                                                              3) + '.txt' ,
                                        CONVERT(CHAR(8), GETDATE(), 112)
                                        + SUBSTRING(CONVERT(CHAR, GETDATE(), 114),
                                                    1, 2)
                                        + SUBSTRING(CONVERT(CHAR, GETDATE(), 114),
                                                    4, 2)
                                        + SUBSTRING(CONVERT(CHAR, GETDATE(), 114),
                                                    7, 2) ,
                                        'ENTRY' ,
                                        'GMT+0800' ,
                                        CONVERT(CHAR(8), GETDATE(), 112)
                                        + SUBSTRING(CONVERT(CHAR, GETDATE(), 114),
                                                    1, 2)
                                        + SUBSTRING(CONVERT(CHAR, GETDATE(), 114),
                                                    4, 2)
                                        + SUBSTRING(CONVERT(CHAR, GETDATE(), 114),
                                                    7, 2) ,     
       --  Upper(@mpa_code),'940B','',''  -- RIM2011-0025     
                                        UPPER(@hubcode) ,
                                        '940B' ,
                                        '' ,
                                        ''  -- RIM2011-0025           
    
                        INSERT  INTO dbo.SLI_AIM_PULL
                                SELECT  '940B' ,
                                        UPPER(@hubcode) , --Upper(@mpa_code), --rtrim(@keyname) + '_' + convert(char(8), @sysdate, 112) + '_' + RIGHT(@key, 3)+'.txt',/**CR2009-0025**/    
 -- RIM2011-0022 rtrim(@keyname) + '_' + convert(char(8), @sysdate, 112) + Substring(CONVERT(CHAR, @sysdate,114),1,2) + Substring(CONVERT(CHAR, @sysdate,114),4,2) + Substring(CONVERT(CHAR, @sysdate,114),7,2) + Substring(CONVERT(CHAR, @sysdate,114),10,3) +'_' +  RIGHT(@key, 3)+'.txt',     
                                        '940b_' + RTRIM(@custcode) + '_'
                                        + RTRIM(@mpa_code) + '_'
                                        + CONVERT(CHAR(8), @sysdate, 112)
                                        + SUBSTRING(CONVERT(CHAR, @sysdate, 114),
                                                    1, 2)
                                        + SUBSTRING(CONVERT(CHAR, @sysdate, 114),
                                                    4, 2)
                                        + SUBSTRING(CONVERT(CHAR, @sysdate, 114),
                                                    7, 2)
                                        + SUBSTRING(CONVERT(CHAR, @sysdate, 114),
                                                    10, 3) + '_' + RIGHT(@key,
                                                              3) + '.txt' ,
                                        LTRIM(RTRIM(col003)) ,
                                        CONVERT(CHAR(8), GETDATE(), 112)
                                        + SUBSTRING(CONVERT(CHAR, GETDATE(), 114),
                                                    1, 2)
                                        + SUBSTRING(CONVERT(CHAR, GETDATE(), 114),
                                                    4, 2)
                                        + SUBSTRING(CONVERT(CHAR, GETDATE(), 114),
                                                    7, 2) ,
                                        CONVERT(CHAR(8), GETDATE(), 112)
                                        + SUBSTRING(CONVERT(CHAR, GETDATE(), 114),
                                                    1, 2)
                                        + SUBSTRING(CONVERT(CHAR, GETDATE(), 114),
                                                    4, 2)
                                        + SUBSTRING(CONVERT(CHAR, GETDATE(), 114),
                                                    7, 2)
                                FROM    #TEMPTABLE2
                                WHERE   rectype = '0'
                                        AND COL002 = @mpa_code    
    
    
    
                    END     
-- AIM    
    
		
    
                FETCH NEXT FROM ordercur INTO @storerkey    
    
            END    
    
        CLOSE ordercur    
    
        DEALLOCATE ordercur    
    
    
    
-- 2008/03/03: Set hotpart flag    
    
        UPDATE  SKU
        SET     BUSR4 = 'Y'
        FROM    SKU ,
                ORDERS ,
                ORDERDETAIL ,
                ( SELECT    SO = WAVEKEY
                  FROM      #TEMPTABLE1
                  WHERE     STORERKEY LIKE 'ANY%'
                ) O
        WHERE   ORDERS.ORDERKEY = O.SO
                AND ORDERS.ORDERKEY = ORDERDETAIL.ORDERKEY
                AND SKU.SKU = ORDERDETAIL.SKU
                AND 'C' + RTRIM(ORDERS.S_Company) + '-'
                + RTRIM(ORDERDETAIL.BINLOCATION) = SKU.STORERKEY
                AND ORDERDETAIL.FLAG1 = 'Y'    
    
    
    
        UPDATE  SKU
        SET     BUSR4 = 'Y'
        FROM    SKU ,
                ORDERS ,
                ORDERDETAIL ,
                ( SELECT    SO = WAVEKEY
                  FROM      #TEMPTABLE1
                  WHERE     STORERKEY LIKE 'ANY%'
                ) O
        WHERE   ORDERS.ORDERKEY = O.SO
                AND ORDERS.ORDERKEY = ORDERDETAIL.ORDERKEY
                AND SKU.SKU = ORDERDETAIL.SKU
                AND SKU.STORERKEY LIKE 'M' + RTRIM(ORDERS.S_Company) + '-%'
                AND ORDERDETAIL.BINLOCATION = ORDERS.S_Company
                AND ORDERDETAIL.FLAG1 = 'Y'    
    
    
    
        UPDATE  SKU
        SET     BUSR4 = 'YA'
        FROM    SKU ,
                ORDERS ,
                ORDERDETAIL ,
                ( SELECT    SO = WAVEKEY
                  FROM      #TEMPTABLE1
                  WHERE     STORERKEY LIKE 'ANY%'
                ) O
        WHERE   ORDERS.ORDERKEY = O.SO
                AND ORDERS.ORDERKEY = ORDERDETAIL.ORDERKEY
                AND SKU.SKU = ORDERDETAIL.SKU
                AND SKU.STORERKEY LIKE '%' + RTRIM(ORDERS.S_Company) + '-%'
                AND ISNULL(ORDERDETAIL.BINLOCATION, '') = ''
                AND ORDERDETAIL.FLAG1 = 'Y'     
    
    
  
    
    
    
        UPDATE  TransmitLog
        SET     TransmitFlag = '9'
        FROM    TransmitLog(ROWLOCK)
        WHERE   TableName = '940B'
                AND Key1 IN ( SELECT    WaveKey
                              FROM      #TEMPTABLE1 ) ;    
    
    
    
    
    
    
    
        UPDATE  #TEMPTABLE2
        SET     Col001 = CONVERT(VARCHAR, RecCnt)
        FROM    ( SELECT    RecCnt = COUNT(1) ,
                            MpaCode ,
                            SO
                  FROM      #TEMPTABLE2
                  WHERE     RecType = '1'
                  GROUP BY  MpaCode ,
                            SO
                ) TMP
        WHERE   #TEMPTABLE2.MpaCode = TMP.MPaCode
                AND RecType = '0'
                AND #TEMPTABLE2.SO = TMP.SO     
    
   
        UPDATE  #TEMPTABLE2
        SET     col023 = col001 ,
                col024 = col002
        WHERE   RecType IN ( '100', '110', '120','130' )   
    
 
        SELECT  *
        FROM    #TEMPTABLE2
        ORDER BY col025 ,
                mpacode ,
                col023 ,
                col024 ,
                SO ,
                rectype

    
    
        DROP TABLE #TEMPTABLE1    
    
        DROP TABLE #TEMPTABLE2    
    
    
    
    END    
    
    
