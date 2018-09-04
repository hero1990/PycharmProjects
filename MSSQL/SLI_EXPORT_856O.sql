
/*SQL2008	YP Single quote 2011/07/18 */
/*PVMI-CR2011-0001 	Tom Song		2011/08/12*/
/*RIM2011-0022  Pih Ling		2011/11/10 */
/*RIM2011-0025	SLI_AIM_IN_WMS.MPACODE = Select nsqldefault from nsqlconfig where configkey = 'Custcd' */
/*RIM2012-0003  DET30- RETURN the country of origion*/
/*PVMI - Extern PO Number and EMS Pull PO  20151009 Tom SOng*/

Alter   PROCEDURE [dbo].[SLI_EXPORT_856O]
AS
BEGIN

DECLARE @sysdate datetime
DECLARE @mpa_code varchar(15)
-- DECLARE @storerkey varchar(15)
DECLARE @keyname varchar(30)
DECLARE @key varchar(9)
DECLARE @dunsno varchar(9)
DECLARE @c_instruction1 varchar(10)

DECLARE	@hiRunId varchar(10),
		@startdate DATETIME,
		@enddate DATETIME,
		@recordsProcessed VARCHAR(200)
		,@sql varchar(500)
		,@spresult int
DECLARE @logfile varchar(100)
DECLARE @MsgEnv varchar(10)
DECLARE	@c_orderkey varchar(10), @c_orderlinenumber varchar(5)
DECLARE @n_pdqty int, @n_856qty int
,         @b_resultset   int 
,         @n_batch       int
,@c_cnt INT

DECLARE @c_transmitlogkey  varchar(10), @d_transmitlogkey int
DECLARE @o_success int,
	@n_err int,
	@c_errmsg char(255),
	@b_success int
	, @Custcode varchar(10) -- RIM2011-0022 
	,@wms_model CHAR(3)
	,@hubcode varchar(10) -- RIM2011-0025
	
SELECT @Custcode= NSQLValue, @hubcode = LTRIM(rtrim(nsqldefault)) FROM NSQLCONFIG -- RIM2011-0025
WHERE ConfigKey = 'Custcd' -- RIM2011-0025

set @sysdate = GetDate()


CREATE TABLE #TEMPTABLE1
(
--WaveKey char(10),OrderKey char(10), plantnumber char(20)
	SO char(10),OrderKey char(10)  , StorerKey char(20), PH VARCHAR(30), S_COMPANY VARCHAR(45), EXPORT_FLAG CHAR(1)
)

CREATE TABLE #TEMPTABLE2
(
SO	varchar(30),
RecType	char(3),
col001 varchar(240) NULL, col002 varchar(240) NULL, col003 varchar(240) NULL, col004 varchar(240) NULL, col005 varchar(240) NULL,
col006 varchar(240) NULL, col007 varchar(240) NULL, col008 varchar(240) NULL, col009 varchar(240) NULL, col010 varchar(240) NULL,
col011 varchar(240) NULL, col012 varchar(240) NULL, col013 varchar(240) NULL, col014 varchar(240) NULL, col015 varchar(240) NULL,
col016 varchar(240) NULL, col017 varchar(240) NULL, col018 varchar(240) NULL, col019 varchar(240) NULL, col020 varchar(240) NULL,
col021 varchar(240) NULL, col022 varchar(240) NULL, col023 varchar(240) NULL, col024 varchar(240) NULL, col025 varchar(240) NULL,
col026 varchar(240) NULL, col027 varchar(240) NULL, col028 varchar(240) NULL, col029 varchar(240) NULL, col030 varchar(240) NULL,
--col031 varchar(240) NULL ,
pid varchar(50)
)

--CR2009-M027
/*
CREATE TABLE #TEMPTABLE3
(
RecType	char(3),
col001 varchar(240) NULL, col002 varchar(240) NULL, col003 varchar(240) NULL, col004 varchar(240) NULL, col005 varchar(240) NULL,
col006 varchar(240) NULL, col007 varchar(240) NULL, col008 varchar(240) NULL, col009 varchar(240) NULL, col010 varchar(240) NULL,
col011 varchar(240) NULL, col012 varchar(240) NULL, col013 varchar(240) NULL, col014 varchar(240) NULL, col015 varchar(240) NULL,
col016 varchar(240) NULL, col017 varchar(240) NULL, col018 varchar(240) NULL, col019 varchar(240) NULL, col020 varchar(240) NULL,
col021 varchar(240) NULL, col022 varchar(240) NULL, col023 varchar(240) NULL, col024 varchar(240) NULL, col025 varchar(240) NULL,
col026 varchar(240) NULL, col027 varchar(240) NULL, col028 varchar(240) NULL, col029 varchar(240) NULL, col030 varchar(240) NULL
,pid varchar(50)
)

*/

IF EXISTS(SELECT 1 FROM STORER WHERE STORERKEY = 'ANYFHK') -- SPECIFIC FOR FHK CHECKING AGAINST 940B SENDING STATUS

BEGIN
Insert into #TEMPTABLE1
SELECT orders.SO, orders.OrderKey , orders.storerkey,MAX(ORDERS.PH) ph,MAX(S_Company) S_Company,
MAX(CASE WHEN orders.STORERKEY LIKE 'C%' OR orders.PH='OST' THEN 'Y' WHEN orders.STORERKEY LIKE 'M%' THEN 'Y' ELSE 'N' END)
FROM transmitlog(nolock), transmitlog tlog(NOLOCK), orders(NOLOCK), SLI_Partner_Messages PMsg(NOLOCK)
where transmitlog.tablename = '856MPa'
and transmitlog.transmitflag = '0'
and transmitlog.key1 = orders.SO
 /* Added By Becky Fu, 10 Oct 08 */
and tlog.key1 = orders.SO
and tlog.tablename = '940b'
and tlog.transmitflag = '9' 
/* end */
AND PMsg.MessageType='856o'
-- CR2010-M027 AND PMsg.PartnerCode = CASE WHEN (orders.Storerkey like 'ANY%') THEN SUBSTRING(orders.STORERKEY,4,20) 
AND PMsg.PartnerCode = CASE WHEN (left(orders.Storerkey,3) = 'ANY') THEN SUBSTRING(orders.STORERKEY,4,20) 
				ELSE SUBSTRING(orders.STORERKEY,2, CHARINDEX('-', orders.STORERKEY,1) -2 ) END
group by orders.SO, orders.Orderkey, orders.storerkey
END

ELSE
BEGIN
Insert into #TEMPTABLE1
SELECT orders.SO, orders.OrderKey , orders.storerkey,MAX(ISNULL(ORDERS.PH,'')) ph,MAX(S_Company) S_Company,
--MAX(CASE WHEN orders.STORERKEY LIKE 'C%' AND  orders.PH<>'OST' THEN 'Y' ELSE 'N' END)
MAX(CASE WHEN LEFT(orders.STORERKEY,3)<> 'ANY' AND  (orders.PH like '%NML%' OR orders.PH='HHT' OR ISNULL(orders.PH,'')='')  THEN 'Y' ELSE 'N' END)
FROM transmitloG(nolock) , orders(NOLOCK), SLI_Partner_Messages PMsg(NOLOCK)
where transmitlog.tablename = '856MPa'
and transmitlog.transmitflag = '0'
and transmitlog.key1 = orders.SO
AND PMsg.MessageType='856o'
--CR2010-M027AND PMsg.PartnerCode = CASE WHEN (orders.Storerkey like 'ANY%') THEN SUBSTRING(orders.STORERKEY,4,20) 
AND PMsg.PartnerCode = CASE WHEN (LEFT(orders.Storerkey,3) = 'ANY') THEN SUBSTRING(orders.STORERKEY,4,20) 
				ELSE SUBSTRING(orders.STORERKEY,2, CHARINDEX('-', orders.STORERKEY,1) -2 ) END
group by orders.SO, orders.Orderkey, orders.storerkey
END

-- 2011-11-07 set the export flag for parent orders.
update #TEMPTABLE1 
set export_flag = 'Y'
where storerkey like 'ANY%' and SO in (select so from #TEMPTABLE1 where export_flag = 'Y' )
--and storerkey like 'C%'


UPDATE TransmitLog SET TransmitFlag = '5'
FROM #TEMPTABLE1
WHERE TransmitLog.Key1 = #TEMPTABLE1.SO and TransmitLog.TableName = '856MPa'
--CR2010-M027
IF @@ROWCOUNT = 0  or @@ERROR  <>0
BEGIN

	IF OBJECT_ID('TempDB..#TEMPTABLE1') IS NOT NULL DELETE #TEMPTABLE1 
	SELECT * FROM #TEMPTABLE1
	RETURN
END


IF NOT EXISTS (SELECT COUNT(1) FROM #TEMPTABLE1)
BEGIN
	DROP TABLE #TEMPTABLE1
	DROP TABLE #TEMPTABLE2
--CR2009-M027
--	DROP TABLE #TEMPTABLE3
	RETURN
END 


-- CR#2009-0044
--CR2010-M027 IF EXISTS(SELECT 1 FROM PICKDETAIL(NOLOCK) WHERE ORDERKEY IN (SELECT OrderKey FROM #TEMPTABLE1 WHERE  storerkey not like 'ANY%') AND 
IF EXISTS(SELECT 1 FROM PICKDETAIL(NOLOCK) WHERE ORDERKEY IN (SELECT OrderKey FROM #TEMPTABLE1 WHERE  LEFT(storerkey,3) <> 'ANY') AND 
(ISNULL(Notes,'') = '' OR ISNULL(Serialno,'') = '' OR ISNULL(BoxNumber,'')= ''))

BEGIN
	
	UPDATE PICKDETAIL
	SET 	Notes=RECEIPTDETAIL.ExternReceiptKey, 
		Serialno=RECEIPTDETAIL.PoNumber, 
		BoxNumber=RECEIPTDETAIL.POLineNumber, 
		TrafficCop = Null 
	FROM LOTATTRIBUTE (NOLOCK), RECEIPTDETAIL (NOLOCK), #TEMPTABLE1
	WHERE LOTATTRIBUTE.LOTTABLE03 = RTRIM(RECEIPTDETAIL.RECEIPTKEY) + RTRIM(RECEIPTDETAIL.ReceiptLineNumber)
--CR2010-M027	AND PICKDETAIL.ORDERKEY =#TEMPTABLE1.ORDERKEY AND #TEMPTABLE1.storerkey not like 'ANY%'
	AND PICKDETAIL.ORDERKEY =#TEMPTABLE1.ORDERKEY AND LEFT(#TEMPTABLE1.storerkey,3) <> 'ANY'
	AND LOTATTRIBUTE.LOT = PICKDETAIL.LOT
	AND (ISNULL(Notes,'') = '' OR ISNULL(Serialno,'') = '' OR ISNULL(BoxNumber,'')= '')
	IF @@ERROR <> 0
	BEGIN 
			
		EXEC nspg_getkey 'HIRUN', 10, @hirunid OUTPUT, null, null, null
		
			
		INSERT INTO hiError
			(HiErrorGroup, ErrorText, ErrorType, SourceKey, AddDate, AddWho, EditDate, EditWho)
		VALUES 
			(@hiRunId, '856o Export started at ' + CONVERT(VARCHAR, @StartDate), 
			'UPDATE', '856o', GETDATE(), LEFT(SUSER_SNAME(),18), GETDATE(), LEFT(SUSER_SNAME(),18))
		RETURN
	END
	
END


SELECT @StartDate = GetDate()

SELECT top 1 @dunsno = IsNull(rtrim(code), '') from CODELKUP(NOLOCK) WHERE listname = 'SCHDUNS' 
SELECT @MsgEnv = Code FROM Codelkup WHERE listname='MsgEnv'

DECLARE ordercur CURSOR FOR
--	SELECT Distinct orders.storerkey  FROM Orders(NOLOCK) 
	SELECT Distinct substring(UPPER(orders.storerkey) , 2, charindex('-', orders.storerkey, 1)-2)  FROM Orders(NOLOCK) 
--CR2010-M027	WHERE orders.orderkey IN (Select OrderKey from  #TEMPTABLE1 where storerkey not like 'ANY%')

	WHERE orders.orderkey IN (Select OrderKey from  #TEMPTABLE1 where LEFT(storerkey,3) <> 'ANY')
	Order By  substring(UPPER(orders.storerkey) , 2, charindex('-', orders.storerkey, 1)-2) -- orders.storerkey 

	OPEN ordercur
--	FETCH NEXT FROM ordercur into @storerkey
	FETCH NEXT FROM ordercur into @mpa_code
	WHILE @@fetch_status = 0
	BEGIN
  		   Exec SLI_GetModel_Code @mpa_code, @wms_model OUTPUT,@b_success  OUTPUT,@n_err  OUTPUT,@c_errmsg  OUTPUT
		  IF @n_err>0  
		  BEGIN
		    UPDATE #TEMPTABLE1
		    SET EXPORT_FLAG='N'
		    WHERE  LEFT(storerkey,3) <> 'ANY' AND SUBSTRING(storerkey,2,3)=@mpa_code OR LEFT(storerkey,3) = 'ANY' AND SUBSTRING(storerkey,2,3)=@mpa_code
		    FETCH NEXT FROM ordercur into @mpa_code
			CONTINUE
		  END
 
--		set @mpa_code = substring(@storerkey , 2, charindex('-', @storerkey, 1)-2)
		set @keyname = '856o_' + rtrim(@mpa_code)

		select @c_instruction1 = INSTRUCTIONS1 from STORER WHERE STORERKEY = 'ANY' + rtrim(@mpa_code)

		exec nspg_getkey @keyname, 9, @key OUTPUT, null, null, null

		IF left(@key, 6) <> right(convert(char(8), @sysdate, 112), 6) 
		BEGIN
			set @key = right(convert(char(8), @sysdate, 112), 6) + '001'
			UPDATE ncounter SET keycount= @key WHERE keyname = @keyname
		END 

		EXEC nspg_getkey 'HIRUN', 10, @hirunid OUTPUT, null, null, null

		Insert hierror ( hierrorgroup , errortext , errortype , sourcekey )
		Select @hiRunId ,'Initiallizing....   hierror: '+@hiRunId , 'GENERAL' , '856o'

		INSERT INTO hiError
			(HiErrorGroup, ErrorText, ErrorType, SourceKey, AddDate, AddWho, EditDate, EditWho)
		VALUES 
			(@hiRunId, '856o Export started at ' + CONVERT(VARCHAR, @StartDate), 
			'GENERAL', '856o', GETDATE(), LEFT(SUSER_SNAME(),18), GETDATE(), LEFT(SUSER_SNAME(),18))


		INSERT INTO hiError
		(HiErrorGroup, ErrorText, ErrorType, SourceKey, AddDate, AddWho, EditDate, EditWho)
		VALUES 
		(@hiRunId, 'Export file - ' + rtrim(@keyname) + '_' + CONVERT(VARCHAR(8), @StartDate,112)+ '_' + RIGHT(@key, 3), 
		'GENERAL', '856o', GETDATE(), LEFT(SUSER_SNAME(),18), GETDATE(), LEFT(SUSER_SNAME(),18))

		-- ===== Envelope ==========================================
		Insert into #TEMPTABLE2 
		SELECT
			SO = '',
			RecType='ENV', col001 = @dunsno + @mpa_code, 
			col002 = convert(char(8), @sysdate, 112) + Substring(CONVERT(CHAR, @sysdate,114),1,2) + Substring(CONVERT(CHAR, @sysdate,114),4,2) + Substring(CONVERT(CHAR, @sysdate,114),7,2), 
			-- RIM2011-0022 col003 = rtrim(@keyname) + '_' + convert(char(8), @sysdate, 112) + Substring(CONVERT(CHAR, @sysdate,114),1,2) + Substring(CONVERT(CHAR, @sysdate,114),4,2) + Substring(CONVERT(CHAR, @sysdate,114),7,2) + Substring(CONVERT(CHAR, @sysdate,114),10,3) + '_' + RIGHT(@key, 3),
			col003 ='856o_' +rtrim(@custcode)+'_'+ rtrim(@mpa_code) + '_' + convert(char(8), @sysdate, 112) + Substring(CONVERT(CHAR, @sysdate,114),1,2) + Substring(CONVERT(CHAR, @sysdate,114),4,2) + Substring(CONVERT(CHAR, @sysdate,114),7,2) + Substring(CONVERT(CHAR, @sysdate,114),10,3) + '_' + RIGHT(@key, 3),
			col004 = @MsgEnv , col005 = '', 
			col006 = '', col007 = '', col008 = '', col009 = '', col010 = '', col011 = '', col012 = '', col013 = '', col014 = '', col015 = '', 
			col016 = '', col017 = '', col018 = '', col019 = '', col020 = '', col021 = '', col022 = '', col023 = '', col024 = '', col025 = '',
--RIM2012-0003			col026 = '', col027 = '', col028 = '', col029 = '', col030 = '',@hirunid
			col026 = '', col027 = '', col028 = '', col029 = '', col030 = '', --col031 = '',
			@hirunid


		-- ===== Header ============================================ 
		Insert into #TEMPTABLE2 
		SELECT		ORDERS.SO,
		RecType='0',
		col001= (SELECT COUNT(DISTINCT ORDERDETAIL.OrderKey+ORDERDETAIL.PlantNumber+ 
			CASE WHEN @c_instruction1='2' THEN ISNULL(PickDetail.SerialNo,'') ELSE '' END +
			CASE WHEN @c_instruction1='2' THEN ISNULL(PickDetail.BoxNumber,'') ELSE '' END +
			CASE WHEN @c_instruction1='2' THEN ISNULL(PickDetail.Notes,'') ELSE '' END)
				FROM ORDERS O(NOLOCK), ORDERDETAIL(NOLOCK), PICKDETAIL(NOLOCK) 
				WHERE ORDERDETAIL.OrderKey = PICKDETAIL.OrderKey 
					AND O.Orderkey = ORDERDETAIL.Orderkey
					AND ORDERDETAIL.OrderLineNumber = PICKDETAIL.OrderLineNumber 
					AND Orders.SO = O.SO) , 
		col002=ISNULL(Orders.s_company, ''),
		/*remarked by 
		col003=#TEMPTABLE1.SO,
		col004=ISNULL(Orders.ExternOrderKey, ''),
		col005=convert(char(8), orders.editdate, 112) + Substring(CONVERT(CHAR,Orders.editdate,114),1,2) + Substring(CONVERT(CHAR,Orders.editdate,114),4,2), 
		col006=ISNULL(Orders.s_company1, ''),
		col007=convert(char(8), orders.DeliveryDate, 112) + Substring(CONVERT(CHAR,Orders.DeliveryDate,114),1,2) + Substring(CONVERT(CHAR,Orders.DeliveryDate,114),4,2), 
		col008=convert(char(8), orders.orderdate, 112) + Substring(CONVERT(CHAR,Orders.orderdate,114),1,2) + Substring(CONVERT(CHAR,Orders.orderdate,114),4,2), 
		col009=ISNULL(Ordersext.Notes1, '') + ISNULL(Ordersext.Notes2, '') + ISNULL(Ordersext.Notes3, ''),
		col010=LEFT(ISNULL(Orders.PH, ''), 20),
		col011=LEFT(ISNULL(Orders.PE, ''), 20),
		col012=LEFT(ISNULL(Orders.KK, ''), 20),
		col013=LEFT(ISNULL( (SELECT top 1 CODELKUP.description FROM CODELKUP(NOLOCK) WHERE CODELKUP.listname = 'ORDRPRIOR' AND Orders.Priority = CODELKUP.code), ''), 15), 
		col014 = '', col015 = '', col016 = '', col017 = '', col018 = '', col019 = '', col020 = '', col021 = '', col022 = '', col023 = '', col024 = '', col025 = '',
		col026 = '', col027 = '', col028 = '', col029 = '', col030 = '',@hirunid
		*/
		--col003=ISNULL(Orders.ExternOrderKey, ''),
		--col004=convert(char(8), orders.editdate, 112) + Substring(CONVERT(CHAR,Orders.editdate,114),1,2) + Substring(CONVERT(CHAR,Orders.editdate,114),4,2), 
		--col005=ISNULL(Orders.s_company1, ''),
		--col006=ISNULL(Ordersext.Notes1, '') + ISNULL(Ordersext.Notes2, '') + ISNULL(Ordersext.Notes3, ''),
		--col007=convert(char(8), orders.DeliveryDate, 112) + Substring(CONVERT(CHAR,Orders.DeliveryDate,114),1,2) + Substring(CONVERT(CHAR,Orders.DeliveryDate,114),4,2), 
		--col008=LEFT(ISNULL(Orders.PH, ''), 20),
		--col009=LEFT(ISNULL(Orders.PE, ''), 20),
		--col010=LEFT(ISNULL(Orders.KK, ''), 20),
		--col011=LEFT(ISNULL( (SELECT top 1 CODELKUP.description FROM CODELKUP(NOLOCK) WHERE CODELKUP.listname = 'ORDRPRIOR' AND Orders.Priority = CODELKUP.code), ''), 15), 
		--col012 = '', col013 = '', col014 = '', col015 = '', col016 = '', col017 = '', col018 = '', col019 = '', col020 = '', col021 = '', col022 = '', col023 = '',
		--col024 = '', col025 = '', col026 = '', col027 = '', col028 = '', col029 = '', col030 = '',@hirunid
		
		col003=ISNULL(Orders.orderkey, ''), 
		col004=ISNULL(Orders.ExternOrderKey, ''),
		col005=convert(char(8), orders.editdate, 112) + Substring(CONVERT(CHAR,Orders.editdate,114),1,2) + Substring(CONVERT(CHAR,Orders.editdate,114),4,2), 
		col006=ISNULL(Orders.s_company1, ''),
		col007=convert(char(8), orders.DeliveryDate, 112) + Substring(CONVERT(CHAR,Orders.DeliveryDate,114),1,2) + Substring(CONVERT(CHAR,Orders.DeliveryDate,114),4,2), 
		col008=convert(char(8), orders.OrderDate, 112) + Substring(CONVERT(CHAR,Orders.OrderDate,114),1,2) + Substring(CONVERT(CHAR,Orders.OrderDate,114),4,2), 
		col009=ISNULL(Ordersext.Notes1, '') + ISNULL(Ordersext.Notes2, '') + ISNULL(Ordersext.Notes3, ''),
		col010=LEFT(ISNULL(Orders.PH, ''), 20),
		col011=LEFT(ISNULL(Orders.PE, ''), 20),
		col012=LEFT(ISNULL(Orders.KK, ''), 20),
		col013=LEFT(ISNULL( (SELECT top 1 CODELKUP.description FROM CODELKUP(NOLOCK) WHERE CODELKUP.listname = 'ORDRPRIOR' AND Orders.Priority = CODELKUP.code), ''), 15), 
		--col012 = '', col013 = '', 
		col014 = '', col015 = '', col016 = '', col017 = '', col018 = '', col019 = '', col020 = '', col021 = '', col022 = '', col023 = '',
		col024 = '', col025 = '', col026 = '', col027 = '', col028 = '', col029 = '', col030 = '', --col031 = '',
		@hirunid

		FROM Orders(NOLOCK), OrdersExt(NOLOCK), #TEMPTABLE1
		WHERE -- Orders.Storerkey = @storerkey AND	 
			Orders.OrderKey = #TEMPTABLE1.OrderKey
			AND	Orders.OrderKey = OrdersExt.OrderKey
--CR2010-M027			AND #TEMPTABLE1.storerkey  like 'ANY%'
--PVMI-CR2011-0001 		AND LEFT(#TEMPTABLE1.storerkey,3) = 'ANY'
		AND #TEMPTABLE1.storerkey = 'ANY'+@MPA_CODE AND EXPORT_FLAG='Y'
		Order By ExternOrderKey

		-- ===== Detail ============================================ 
		Insert into #TEMPTABLE2
		SELECT
		SO = #TEMPTABLE1.SO, 
		RecType='1',
		col001=#TEMPTABLE1.SO,

		col002=LEFT(ISNULL(OrderDetail.PlantNumber, ''), 10),
		/* Updated By Becky Fu, 10 Oct 08, extend Pull request# from 15 to 20 */
		col003=LEFT(ISNULL(OrderDetail.ExternOrderkey,''), 20),

		col004=LEFT(ISNULL(OrderDetail.ExternLineNo, ''), 5),
		col005=UPPER(OrderDetail.SKU) , -- By Becky to upper sku 
		col006=ISNULL(OrderDetail.RetailSKU, ''),
		col007=ISNULL(SKU.descr, ''),
		col008=ISNULL(SUM(PICKDETAIL.QTY),0),
		col009=ISNULL(OrderDetail.UOM,''),
		col010=ISNULL(Substring(OrderDetail.Instruction, CHARINDEX('-', OrderDetail.Instruction) +1, 20), ''), 
		col011=CASE WHEN ISNULL(SUM(PICKDETAIL.Qty),0)=0 THEN #TEMPTABLE1.s_company
					WHEN ISNULL(SUM(PICKDETAIL.Qty),0)<>0 AND @wms_model='VMI' AND RTRIM(ISNULL(OrderDetail.BinLocation,''))='' THEN SUBSTRING(#TEMPTABLE1.STORERKEY,4,10) 
					WHEN ISNULL(SUM(PICKDETAIL.Qty),0)<>0 AND @wms_model='VMI' AND RTRIM(ISNULL(OrderDetail.BinLocation,''))='' THEN ISNULL(OrderDetail.BinLocation,'')
					WHEN ISNULL(SUM(PICKDETAIL.Qty),0)<>0 AND @wms_model='CPO' AND RTRIM(ISNULL(OrderDetail.BinLocation,''))='' THEN ISNULL(OrderDetail.BinLocation,'')
					WHEN ISNULL(SUM(PICKDETAIL.Qty),0)<>0 AND @wms_model='CPO' AND #TEMPTABLE1.ph='NML' AND RTRIM(ISNULL(OrderDetail.BinLocation,''))='' THEN #TEMPTABLE1.s_company
					WHEN ISNULL(SUM(PICKDETAIL.Qty),0)<>0 AND @wms_model='CPO' AND #TEMPTABLE1.ph='NML' AND RTRIM(ISNULL(OrderDetail.BinLocation,''))<>'' THEN OrderDetail.BinLocation
					WHEN ISNULL(SUM(PICKDETAIL.Qty),0)<>0 AND @wms_model='CPO' AND #TEMPTABLE1.ph='HHT' AND RTRIM(ISNULL(OrderDetail.BinLocation,''))='' THEN #TEMPTABLE1.s_company
					WHEN ISNULL(SUM(PICKDETAIL.Qty),0)<>0 AND @wms_model='CPO' AND #TEMPTABLE1.ph='PO' AND RTRIM(ISNULL(OrderDetail.BinLocation,''))<>'' THEN SUBSTRING(#TEMPTABLE1.STORERKEY,4,10)
					ELSE ISNULL(OrderDetail.BinLocation,'')
					END, 
		col012=ISNULL(OrderDetail.DeliveryReference, ''), 
		col013=ISNULL(CASE WHEN @wms_model='VMI'  THEN OrderDetail.ExternalNote02 
					WHEN @wms_model='CPO' AND LEFT(#TEMPTABLE1.StorerKey,1)='M' THEN OrderDetail.EXTERNORDERKEY  
					WHEN @wms_model='CPO' AND #TEMPTABLE1.ph<>'OST' AND LEFT(#TEMPTABLE1.StorerKey,1)='C'  THEN OrderDetail.ExternalNote02 
					WHEN @wms_model='CPO' AND #TEMPTABLE1.ph='OST'  THEN OrderDetail.EXTERNORDERKEY 
					ELSE ''
					END,''),
		col014=ISNULL(CASE WHEN @wms_model='VMI'  THEN OrderDetail.ExternalNote03 
					WHEN @wms_model='CPO' AND LEFT(#TEMPTABLE1.StorerKey,1)='M' THEN OrderDetail.EXTERNLINENO  
					WHEN @wms_model='CPO' AND #TEMPTABLE1.ph<>'OST' AND LEFT(#TEMPTABLE1.StorerKey,1)='C'  THEN OrderDetail.ExternalNote03 
					WHEN @wms_model='CPO' AND #TEMPTABLE1.ph='OST'  THEN OrderDetail.EXTERNLINENO
					ELSE ''
					END,''), 
		col015=CASE WHEN @wms_model='VMI'  THEN Orderdetail.POLineNumber  --20151009 Orderdetail.PolineitemID
					WHEN @wms_model='CPO' AND LEFT(#TEMPTABLE1.Storerkey,1)<>'C' THEN ''
					WHEN @wms_model='CPO' AND LEFT(#TEMPTABLE1.Storerkey,1)='C' AND #TEMPTABLE1.ph<>'OST'  THEN orderdetail.POLineNumber
					ELSE ''
					END,
		col016=CASE WHEN @wms_model='VMI'  THEN Orderdetail.PolineitemID  --20151009 Orderdetail.POLineNumber
					WHEN @wms_model='CPO' AND LEFT(#TEMPTABLE1.Storerkey,1)<>'C' THEN ''
					WHEN @wms_model='CPO' AND LEFT(#TEMPTABLE1.Storerkey,1)='C' AND #TEMPTABLE1.ph<>'OST' THEN orderdetail.PolineitemID
					ELSE ''
					END,		--PO Line#
		col017=CASE WHEN @c_instruction1='2' THEN LEFT(ISNULL(PickDetail.Notes,''),10) ELSE '' END,
		col018=CASE WHEN @c_instruction1='2' THEN LEFT(ISNULL(PickDetail.SerialNo,''),20) ELSE '' END,   --20151009 LEFT(ISNULL(PickDetail.SerialNo,''),10) ELSE '' END
		col019=CASE WHEN @c_instruction1='2' THEN LEFT(ISNULL(PickDetail.BoxNumber,''),10) ELSE '' END,	 --20151009 LEFT(ISNULL(PickDetail.BoxNumber,''),5) ELSE '' END
		--CR2009-M011
--		col020=LEFT(ISNULL(SKU.ManufacturerSKU, '') + ISNULL(SKU.Altsku, ''), 20),
		col020=LEFT(LTRIM(RTRIM(isnull(SKU.ManufacturerSKU,''))) +  LTRIM(RTRIM(isnull(SKU.AltSKU,''))),40),
		col021=ISNULL(OrderDetail.BaxOriginalQty,0),
		col022=(SELECT ISNULL(SUM(PD.Qty),0) from PICKDETAIL PD(NOLOCK),Orders O(NOLOCK)
				WHERE pd.orderkey = o.orderkey and
					O.SO = #TEMPTABLE1.SO and PD.Sku = OrderDetail.SKU ),
		col023= LEFT(ISNULL(Substring(Orderdetail.Notes1, 1, case when CHARINDEX('-', Orderdetail.Notes1)<1 then len(Orderdetail.Notes1) else CHARINDEX('-', Orderdetail.Notes1) - 1 end  ), ''), 15), 
		col024=ISNULL(Substring(OrderDetail.Notes1, case when CHARINDEX('-', Orderdetail.Notes1)<1 then len(Orderdetail.Notes1) else CHARINDEX('-', Orderdetail.Notes1) +1 end  , 20), ''), 
		col025=LEFT(ISNULL(Substring(OrderDetail.Instruction, 1, case when CHARINDEX('-', Orderdetail.Instruction)<1 then len(Orderdetail.Instruction) else CHARINDEX('-', Orderdetail.Instruction)-1 end), ''), 20),  
		col026=LEFT(ISNULL(OrderDetail.Notes4, ''), 20), 
		col027=LEFT(ISNULL(OrderDetail.Lottable01, ''), 18), 
		col028=LEFT(ISNULL(OrderDetail.InternalNote01, ''), 18), 
		--RIM2012-0003 col029=LEFT(ISNULL(OrderDetail.InternalNote02, ''), 18), 
		col029=LEFT(ISNULL(RECEIPTDETAIL.CountryofOrigin,''), 240),
		col030=LEFT(ISNULL(OrderDetail.CustShipInst01, '') + ISNULL(OrderDetail.CustShipInst02, '') + ISNULL(OrderDetail.CustShipInst03, ''), 240),
		--RIM2012-0003
		--col031=LEFT(ISNULL(RECEIPTDETAIL.CountryofOrigin,''), 240)
		@hirunid
		FROM ORDERDETAIL (NOLOCK), 	
			PICKDETAIL (NOLOCK), 
			SKU (NOLOCK), 
			#TEMPTABLE1,
		--RIM2012-0003
			LOTATTRIBUTE (NOLOCK),
			RECEIPTDETAIL (NOLOCK)
			
		WHERE		--RIM2012-0003
			LOTATTRIBUTE.LOT=PICKDETAIL.LOT AND
			RECEIPTDETAIL.Lottable03=LOTATTRIBUTE.Lottable03 AND
		
		    ( ORDERDETAIL.OrderKey = PICKDETAIL.OrderKey ) AND
			( ORDERDETAIL.OrderLineNumber = PICKDETAIL.OrderLineNumber ) AND
			( ORDERDETAIL.Sku = SKU.Sku ) AND
			( ORDERDETAIL.Storerkey = SKU.Storerkey ) AND
			( #TEMPTABLE1.orderkey = ORDERDETAIL.Orderkey ) AND
--CR2010-M027			( #TEMPTABLE1.storerkey NOT LIKE 'ANY%' )
--PVMI-CR2011-0001 			(left( #TEMPTABLE1.storerkey,3) <> 'ANY' )
			( substring(#TEMPTABLE1.storerkey,2,3) = @MPA_CODE ) AND
			#TEMPTABLE1.EXPORT_FLAG='Y'
			
		group by #TEMPTABLE1.SO, orderdetail.orderkey, OrderDetail.PlantNumber, orderdetail.externOrderkey, 
			orderdetail.externlineno, orderdetail.Lottable01, OrderDetail.Sku, OrderDetail.RetailSku, Sku.Descr, OrderDetail.UOM, OrderDetail.Instruction,
			OrderDetail.BinLocation, OrderDetail.DeliveryReference, OrderDetail.ExternalNote02, OrderDetail.ExternalNote03, OrderDetail.POLineItemId,
			OrderDetail.POLineNumber, orderdetail.orderlinenumber,
			--Pickdetail.Notes, WO#33854 
			OrderDetail.BaxOriginalQty,
--WO#33854 
		CASE WHEN @c_instruction1='2' THEN LEFT(ISNULL(PickDetail.Notes,''),10) ELSE '' END,
		CASE WHEN @c_instruction1='2' THEN LEFT(ISNULL(PickDetail.SerialNo,''),20) ELSE '' END,
		CASE WHEN @c_instruction1='2' THEN LEFT(ISNULL(PickDetail.BoxNumber,''),10) ELSE '' END,

			--Pickdetail.Serialno, Pickdetail.BoxNumber, WO#33854 
			 Sku.Manufacturersku, sku.Altsku,
			OrderDetail.Notes1, OrderDetail.Notes4, OrderDetail.InternalNote01, OrderDetail.InternalNote01, OrderDetail.InternalNote02, 
			OrderDetail.CustShipInst01, OrderDetail.CustShipInst02, OrderDetail.CustShipInst03,#TEMPTABLE1.StorerKey,#TEMPTABLE1.S_COMPANY,#TEMPTABLE1.PH,
			LEFT(ISNULL(RECEIPTDETAIL.CountryofOrigin,''), 240)
		
/* Begin of PG Standardisation **************************************** */
		IF EXISTS (select 1 from SLI_PartnerGuideline_Ctrl WHERE REFERENCE1 = 'Y'  AND Messageid ='856o' AND HUB =@mpa_code)
		BEGIN
		----if config table turn on then perform below checking--
		-- Validation
			CREATE TABLE #RESULT
			( 
				LineNumber int, RecordType varchar(5), ElementID int, ColumnName varchar(50), Value varchar(250)
			)
			
			SELECT LineNumber = Identity(Int, 1, 1),*
			INTO #TmpTbl
			FROM #TEMPTABLE2

			declare @i int, @mi int, @n_col int, @j int, @col_name varchar(50), @s_col int
			declare @c_SQLString NVARCHAR(4000), @c_SQLString1 NVARCHAR(4000), @c_SQLString2 NVARCHAR(4000), @c_SQLString3 NVARCHAR(4000) 
			
			select @i=1, @j=1
			select @s_col = 3
			select @mi=count(1) from #TmpTbl
			select @n_col = info from tempdb.dbo.sysobjects where id = object_id(N'tempdb..#TmpTbl') 

			delete  from #RESULT

			-- Start from column3
			select @j=@s_col
			while @j <= @n_col
			begin
				select @col_name=name 
				from tempdb.dbo.syscolumns 
				where id = object_id(N'tempdb..#TmpTbl') and colorder = @j

				select @c_SQLString = ' select LineNumber, RecType, ' + 
				cast(@j-(@s_col-1) as varchar) + ',''' + @col_name + ''',' + @col_name +  ' from #TmpTbl '  
				insert into #RESULT
				EXECUTE sp_executesql @c_SQLString
				select @j = @j + 1
			end
			
			INSERT INTO SLI_TMP_Validation
			select @hirunid, GETDATE(),LineNumber, messageid, #RESULT.recordtype,SLI_PartnerGuideline_Ctrl.ElementID,SLI_PartnerGuideline_Ctrl.ElementName, ColumnName, Value, Type, FieldLength, TruncateYN,
			Is_Nullable = Case When Mandatory = 'Y' And Isnull(Value,'')='' Then '0' Else '1' End,
			Is_Numeric = Case When Type in ('int', 'float') and Isnumeric(Value)<>1 Then '0' Else '1' End,
			Is_Length = Case When Type in ('char','datetime') and TruncateYN='N' and Len(Value)>FieldLength Then '0' Else '1' End,
			Is_Truncated = Case When Type in ('char','datetime') and TruncateYN='Y' and Len(Value)>FieldLength Then 'Y' Else 'N' End,
			ValueT = Case When Type in ('char','datetime') and TruncateYN='Y' Then Left(Ltrim(Cast(Value as Varchar)),FieldLength) Else Value End,
			'','','',''
			from SLI_PartnerGuideline_Ctrl, #RESULT
			where messageid='856o'
			and  Case SLI_PartnerGuideline_Ctrl.recordtype When 'HDR'
			 Then  '0' When 'DET' Then '1' Else  SLI_PartnerGuideline_Ctrl.recordtype End =  #RESULT.recordtype
			and SLI_PartnerGuideline_Ctrl.ElementID = #RESULT.ElementID
			 and (Case When Mandatory = 'Y' And Isnull(Value,'')='' Then '0' Else '1' End = '0'
			or Case When Type in ('int', 'float') and Isnumeric(Value)<>1 Then '0' Else '1' End ='0'
			or Case When Type in ('char','datetime') and TruncateYN='N' and Len(Value)>FieldLength Then '0' Else '1' End ='0'
			or Case When Type in ('char','datetime') and TruncateYN='Y' and Len(Value)>FieldLength Then 'Y' Else 'N' End ='Y')
			
			UPDATE SLI_TMP_Validation Set Is_Truncated = 'N'
			WHERE messageid='856o' and HiError=@hirunid 
				And LineNumber In (SELECT DISTINCT LineNumber FROM SLI_TMP_Validation 
					WHERE messageid='856o' and HiError=@hirunid
					And (Is_Nullable = '0' Or Is_Numeric = '0' Or Is_Length = '0'))

			DELETE FROM SLI_TMP_Validation
			WHERE messageid='856o' and HiError=@hirunid 
				AND(Is_Nullable = '1' AND Is_Numeric = '1' AND Is_Length = '1')
				AND Is_Truncated = 'N'

			DROP TABLE #RESULT

			select  LN=Identity(int ,1,1), 
				SQLString1 = 'Update #TmpTbl Set ' +ColumnName+'='''+Valuet+ ''' WHERE '+
				'LineNumber = '+Cast(LineNumber as varchar)
			into #tmp
			from SLI_TMP_Validation
			where Is_Truncated = 'Y' and messageid='856o' and HiError=@hirunid

			/************update truncated values**/
			select @i=1, @j=max(ln) from #tmp
			while @i<=@j
			begin
				select @c_SQLString1 = SqlString1
				from #tmp where ln=@i
				EXECUTE sp_executesql @c_SQLString1
				set @i=@i+1
			end
			DROP TABLE #tmp

			select  LN=Identity(int ,1,1), 
				SQLString2 = 'DELETE FROM #TEMPTABLE2 WHERE SO = (SELECT SO FROM #TmpTbl WHERE LineNumber = '+Cast(LineNumber as varchar) + ')',
				SQLString3 = 'DELETE FROM #TEMPTABLE1 WHERE SO = (SELECT SO FROM #TmpTbl WHERE LineNumber = '+Cast(LineNumber as varchar) + ')'
			into #tmperr
			from SLI_TMP_Validation
			where (Is_Nullable = '0' Or Is_Numeric = '0' Or Is_Length = '0')
				and messageid='856o' and HiError=@hirunid
			GROUP BY LineNumber
			/************delete error**/
			select @i=1, @j=max(ln) from #tmperr
			while @i<=@j
			begin
				select @c_SQLString2 = SqlString2, @c_SQLString3 = SqlString3 
				from #tmperr where ln=@i
				EXECUTE sp_executesql @c_SQLString2
				EXECUTE sp_executesql @c_SQLString3
				set @i=@i+1
			end

			DROP TABLE #tmperr
		END
/* End of PG Standardisation ******************************************** */

		SELECT @recordsProcessed=CONVERT(VARCHAR, COUNT(1)) FROM #TEMPTABLE2
		INSERT INTO hiError
		(HiErrorGroup, ErrorText, ErrorType, SourceKey, AddDate, AddWho, EditDate, EditWho)
		VALUES 
		(@hiRunId, 'Records Exported = ' + @recordsProcessed,
		'GENERAL', '856o', GETDATE(), LEFT(SUSER_SNAME(),18), GETDATE(), LEFT(SUSER_SNAME(),18))

		SELECT @EndDate = GetDate()
		INSERT INTO hiError
			(HiErrorGroup, ErrorText, ErrorType, SourceKey, AddDate, AddWho, EditDate, EditWho)
			VALUES 
			(@hiRunId, '856o Export end at ' + CONVERT(VARCHAR, @EndDate), 
			'GENERAL', '856o', GETDATE(), LEFT(SUSER_SNAME(),18), GETDATE(), LEFT(SUSER_SNAME(),18))

		Insert hierror ( hierrorgroup , errortext , errortype , sourcekey )
		Select @hiRunId ,'Ending....   hierror: '+@hiRunId , 'GENERAL' , '856o'
		

		SELECT @logfile = 'LOG_856o_'  + REPLACE(CONVERT(VARCHAR(10),GETDATE(),120),'-','') + '_' + @hiRunId

		INSERT INTO HIERRORSUMMARY
		(hirunid,edi,editype,status,start,finish,rtp,rp,logname)
		Values(@hiRunId,'856o','EXPORT','OK',CONVERT(char(20), @StartDate, 120),CONVERT(char(20), @endDate, 120),@recordsProcessed,@recordsProcessed,@logfile)

/*CR2010-M026 Remove from 856o insert into GR table
		-- 2008/03/03: Insert GR Table
		--INSERT SLI_MPA_GR
		DELETE FROM SLI_MPA_GR 
		FROM #TEMPTABLE1, Storer
		WHERE SLI_MPA_GR.ORDERKEY = #TEMPTABLE1.SO
			AND #TEMPTABLE1.StorerKey = Storer.StorerKey 
--CR2010-M027			AND #TEMPTABLE1.StorerKey LIKE 'ANY%'
			AND left(#TEMPTABLE1.StorerKey,3) = 'ANY'
			AND Storer.Instructions3 = '7'

		DECLARE ORDCUR CURSOR FOR
			SELECT ORDERDETAIL.ORDERKEY, ORDERLINENUMBER 
			FROM ORDERDETAIL(NOLOCK), #TEMPTABLE1, #TEMPTABLE1 ANYSTORER, STORER
			WHERE ORDERDETAIL.ORDERKEY = #TEMPTABLE1.ORDERKEY
--CR2010-M027				AND #TEMPTABLE1.STORERKEY NOT LIKE 'ANY%'
				AND left(#TEMPTABLE1.STORERKEY,3) <> 'ANY'
				AND #TEMPTABLE1.SO = ANYSTORER.SO
--CR2010-M027				AND ANYSTORER.Storerkey like 'ANY%'
				AND left(ANYSTORER.Storerkey,3) = 'ANY'
				AND ANYSTORER.Storerkey = Storer.Storerkey
				AND Storer.Instructions3 = '7'

		OPEN 	ORDCUR
		FETCH NEXT FROM ORDCUR into @c_orderkey, @c_orderlinenumber

		WHILE @@fetch_status = 0
		BEGIN
			SELECT 
			MPAID = O.S_Company, 
			SKU = OD.Sku, 
			ORDERKEY = O.SO, 
			OrderLineNumber = OD.PlantNumber, 
			CPAID = OD.Binlocation, 
			PONO = CASE Storer.Instructions1 WHEN  '1' THEN OD.ExternalNote02 
					WHEN '2' THEN PD.SerialNo
					WHEN '3' THEN OD.POlineitemID	END,
			POLINENO = CASE Storer.Instructions1 WHEN  '1'  THEN OD.ExternalNote03 
					WHEN '2' THEN PD.BoxNumber
					WHEN '3' THEN OD.POlineNumber	END ,
			GRNO = ANYSTORER.Orderkey,
			OD.PlantNumber,
			GRLINENO = Identity(Int,1,1),
			QTYRECEIVED = SUM(PD.QTY), 
			RECEIPTDATE = REPLACE(CONVERT(VARCHAR(10),OD.Editdate,120),'-','')+REPLACE(CONVERT(VARCHAR(5),OD.Editdate,114),':',''),
			SOKEY = OD.Orderkey
			INTO #TMPGR
			FROM ORDERS O(NOLOCK), ORDERDETAIL OD(NOLOCK), 	
				PICKDETAIL PD(NOLOCK)  , 
				#TEMPTABLE1 , #TEMPTABLE1 ANYSTORER, STORER(NOLOCK)
			WHERE  ( O.Orderkey = OD.Orderkey ) AND
				( OD.OrderKey = PD.OrderKey ) AND
				( OD.OrderLineNumber = PD.OrderLineNumber )  AND
				( #TEMPTABLE1.orderkey = OD.Orderkey ) AND
----CR2010-M027					( #TEMPTABLE1.storerkey not  like 'ANY%' ) AND
				(left( #TEMPTABLE1.storerkey,3) <> 'ANY' ) AND
				( #TEMPTABLE1.SO = ANYSTORER.SO )  AND
				( OD.ORDERKEY = @c_orderkey AND OD.ORDERLINENUMBER = @c_orderlinenumber) AND
----CR2010-M027		( ANYSTORER.Storerkey like 'ANY%' )  AND
				( left(ANYSTORER.Storerkey,3) = 'ANY' )  AND
				( ANYSTORER.Storerkey = Storer.Storerkey) AND
				( Storer.Instructions3 = '7' ) 		
			GROUP BY
				O.S_Company, OD.Sku, O.SO, 
				OD.OrderLineNumber, OD.Binlocation, 
				CASE Storer.Instructions1 WHEN  '1' THEN OD.ExternalNote02 
				WHEN '2' THEN PD.SerialNo
				WHEN '3' THEN OD.POlineitemID	END,
				CASE Storer.Instructions1 WHEN  '1'  THEN OD.ExternalNote03 
				WHEN '2' THEN PD.BoxNumber
				WHEN '3' THEN OD.POlineNumber	END ,
				ANYSTORER.Orderkey,
				OD.PlantNumber,
				REPLACE(CONVERT(VARCHAR(10),OD.Editdate,120),'-','')+REPLACE(CONVERT(VARCHAR(5),OD.Editdate,114),':',''),
				OD.Orderkey

			INSERT SLI_MPA_GR
			SELECT NULL,NULL,MPAID,SKU,ORDERKEY,ORDERLINENUMBER,CPAID,PONO,POLINENO,GRNO,
				LEFT(PlantNumber,3)+RIGHT(CAST(100+GRLINENO-1 AS VARCHAR),2),QTYRECEIVED,
				RECEIPTDATE,NULL,SOKey,USER_NAME(),GETDATE(),USER_NAME(),GETDATE()
			FROM #TMPGR

			DROP TABLE #TMPGR

			FETCH NEXT FROM ORDCUR into @c_orderkey, @c_orderlinenumber
		END
		CLOSE ORDCUR
		DEALLOCATE ORDCUR
CR2010-M026 End */
		SELECT SO, SeqNo = Identity(int, 1, 1)
		INTO #TMPSO
		FROM #TEMPTABLE1,STORER
----CR2010-M027		WHERE #TEMPTABLE1.STORERKEY LIKE 'ANY%'
		WHERE left(#TEMPTABLE1.STORERKEY,3) = 'ANY'
			AND #TEMPTABLE1.STORERKEY = STORER.STORERKEY
			AND Storer.Instructions3 = '7'
		GROUP BY SO
	
		IF EXISTS (SELECT 1 FROM #TMPSO)
		BEGIN
			SELECT @b_resultset = 0
			SELECT @n_batch = MAX(SeqNo) FROM #TMPSO
			
			EXECUTE nspg_getkey 'TransmitLog', 10, @c_transmitlogkey OUTPUT, @b_success OUTPUT, @n_err OUTPUT, @c_errmsg OUTPUT, @b_resultset, @n_batch	
			

--			SELECT @d_transmitLogkey = CAST(@c_transmitlogkey AS INT ) - @n_batch 
	--		select @d_transmitlogkey = keycount from ncounter where keyname='TransmitLog'
			UPDATE NCOUNTER SET KEYCOUNT=(SELECT ISNULL(MAX(SeqNo),0)+@c_transmitlogkey FROM #TMPSO)
			WHERE KEYNAME = 'TransmitLog'

			INSERT INTO TRANSMITLOG (transmitlogkey, tablename,key1, transmitflag)
			SELECT RIGHT(CAST(SeqNo+@c_transmitlogkey+10000000000 AS VARCHAR),10), '945INVIEWGR',SO,'0'
			FROM #TMPSO
			DROP TABLE #TMPSO
			--EXECUTE nspg_getkey 'TransmitLog', 10, @c_transmitlogkey OUTPUT, @o_success OUTPUT, @n_err OUTPUT, @c_errmsg OUTPUT

			--INSERT INTO TRANSMITLOG (transmitlogkey, tablename,key1, transmitflag)
			--VALUES (@c_transmitlogkey, '945INVIEWGR', @c_orderkey ,'0')
		END
		
		-- AIM CR# AIM_20090716
		If ISNULL(@mpa_code,'')<>'' and ISNULL(@keyname,'')<>'' 
		Begin 

			insert into SLI_AIM_OUT_WMS
	--		select       rtrim(@keyname) + '_' + convert(char(8), @sysdate, 112) + '_' + RIGHT(@key, 3)+'.txt',  /**CR2009-0025**/

			--RIM2011-0022 select rtrim(@keyname) + '_' + convert(char(8), @sysdate, 112) + Substring(CONVERT(CHAR, @sysdate,114),1,2) + Substring(CONVERT(CHAR, @sysdate,114),4,2) + Substring(CONVERT(CHAR, @sysdate,114),7,2) + Substring(CONVERT(CHAR, @sysdate,114),10,3) + '_' + RIGHT(@key, 3)+'.txt',
			 select '856o_' +rtrim(@custcode)+'_'+ rtrim(@mpa_code) + '_' + convert(char(8), @sysdate, 112) + Substring(CONVERT(CHAR, @sysdate,114),1,2) + Substring(CONVERT(CHAR, @sysdate,114),4,2) + Substring(CONVERT(CHAR, @sysdate,114),7,2) + Substring(CONVERT(CHAR, @sysdate,114),10,3) + '_' + RIGHT(@key, 3)+'.txt',
			convert(char(8), getdate(), 112) + Substring(CONVERT(CHAR, getdate(),114),1,2)+ Substring(CONVERT(CHAR, getdate(),114),4,2) + Substring(CONVERT(CHAR, getdate(),114),7,2) , 
			'ENTRY','GMT+0800', 
			convert(char(8), getdate(), 112) + Substring(CONVERT(CHAR, getdate(),114),1,2)+ Substring(CONVERT(CHAR, getdate(),114),4,2) + Substring(CONVERT(CHAR, getdate(),114),7,2) , 
			--Upper(@mpa_code),'856O','',''     
			Upper(@hubcode),'856O','','' --RIM2011-0025
			
			insert into dbo.SLI_AIM_PULL
	--		select  '856O',Upper(@mpa_code),rtrim(@keyname) + '_' + convert(char(8), @sysdate, 112) + '_' + RIGHT(@key, 3)+'.txt', /**CR2009-0025**/
			--RIM2011-0022 SELECT  '856O',Upper(@mpa_code),rtrim(@keyname) + '_' + convert(char(8), @sysdate, 112) + Substring(CONVERT(CHAR, @sysdate,114),1,2) + Substring(CONVERT(CHAR, @sysdate,114),4,2) + Substring(CONVERT(CHAR, @sysdate,114),7,2) + Substring(CONVERT(CHAR, @sysdate,114),10,3) + '_' + RIGHT(@key, 3)+'.txt',
			----RIM2011-0025
			--SELECT  '856O',Upper(@mpa_code),'856o_' +rtrim(@custcode)+'_'+ rtrim(@mpa_code)  + '_' + convert(char(8), @sysdate, 112) + Substring(CONVERT(CHAR, @sysdate,114),1,2) + Substring(CONVERT(CHAR, @sysdate,114),4,2) + Substring(CONVERT(CHAR, @sysdate,114),7,2) + Substring(CONVERT(CHAR, @sysdate,114),10,3) + '_' + RIGHT(@key, 3)+'.txt',
			SELECT  '856O',Upper(@hubcode),'856o_' +rtrim(@custcode)+'_'+ rtrim(@mpa_code)  + '_' + convert(char(8), @sysdate, 112) + Substring(CONVERT(CHAR, @sysdate,114),1,2) + Substring(CONVERT(CHAR, @sysdate,114),4,2) + Substring(CONVERT(CHAR, @sysdate,114),7,2) + Substring(CONVERT(CHAR, @sysdate,114),10,3) + '_' + RIGHT(@key, 3)+'.txt',
			ltrim(rtrim(col004)),
			convert(char(8), getdate(), 112) + Substring(CONVERT(CHAR, getdate(),114),1,2)+ Substring(CONVERT(CHAR, getdate(),114),4,2) + Substring(CONVERT(CHAR, getdate(),114),7,2) ,
			convert(char(8), getdate(), 112) + Substring(CONVERT(CHAR, getdate(),114),1,2)+ Substring(CONVERT(CHAR, getdate(),114),4,2) + Substring(CONVERT(CHAR, getdate(),114),7,2) 

			from #TEMPTABLE2 where rectype = '0' AND col002 = @mpa_code

		End 
	-- AIM
		FETCH NEXT FROM ordercur into @mpa_code --  @storerkey
	END
CLOSE ordercur
DEALLOCATE ordercur

      
SELECT @n_pdqty = SUM(PICKDETAIL.QTY),@c_cnt=COUNT(1) FROM PICKDETAIL(NOLOCK), #TEMPTABLE1
WHERE PICKDETAIL.Orderkey = #TEMPTABLE1.Orderkey AND
      #TEMPTABLE1.EXPORT_FLAG='Y'

SELECT @n_856qty = SUM(CAST(Col008 AS INT)) FROM #TEMPTABLE2 WHERE RECType='1'
IF @n_pdqty=@n_856qty 
BEGIN
	--SELECT @n_pdqty, @n_856qty --Becky remarked on 28th Jan
--CR2009-M027
--	Insert into #TEMPTABLE3
	SELECT
			RecType, col001, col002, col003,col004, col005, 
			col006, col007, col008, col009, col010, col011, col012, col013, col014, col015, 
			col016, col017, col018, col019, col020, col021, col022, col023, col024, col025,
			--RIM2012-0003	col026, col027, col028, col029, col030,pid
			col026, col027, col028, col029, col030, --col031,
			pid
/** to solve invalid sequent No**/
			,IDENTITY(INT, 1 ,1) AS id_num
	INTO #TEMPTABLE3
	FROM #TEMPTABLE2
	ORDER BY SO, Rectype

	UPDATE TransmitLog SET TransmitFlag = '9' WHERE TableName = '856MPa' and Key1 in (SELECT SO FROM #TEMPTABLE1 WHERE export_flag='Y')
	--CR2010-M027
	IF @@ROWCOUNT = 0 
	BEGIN
	
		IF OBJECT_ID('TempDB..#TEMPTABLE1') IS NOT NULL DELETE #TEMPTABLE1 
		SELECT * FROM #TEMPTABLE1
		RETURN
	END


		
END

--CR2009-M027
IF EXISTS(SELECT COUNT(1) FROM #TEMPTABLE1 HAVING COUNT(1)>1) AND
    OBJECT_ID('TempDB..#TEMPTABLE1') IS NOT NULL AND
    OBJECT_ID('TempDB..#TEMPTABLE3') IS NOT NULL 
    
BEGIN
	SELECT *
	FROM  #TEMPTABLE3
	--ORDER BY ID_Num
	ORDER BY pid, ID_Num -- RIM2011-0022a
END
ELSE
BEGIN
SELECT * FROM #TEMPTABLE1
END

END
