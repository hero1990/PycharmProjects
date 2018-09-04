
ALTER  PROC    [dbo].[nspOrderProcessing]
               @c_orderkey     char(10)   
,              @c_oskey        char(10)
,              @c_docarton     char(1)
,              @c_doroute      char(1)
,              @c_tblprefix    char(3)
,              @b_Success      int        OUTPUT
,              @n_err          int        OUTPUT
,              @c_errmsg       char(250)  OUTPUT
AS
BEGIN

DECLARE        @n_continue int        ,  /* continuation flag 
       		1=Continue
       		2=failed but continue processsing 
       		3=failed do not continue processing 
       		4=successful but skip furthur processing */                                               
@n_starttcnt   int      , -- Holds the current transaction count                                                                                           
@n_cnt         int      , -- Holds @@ROWCOUNT after certain operations
@c_preprocess char(250) , -- preprocess
@c_pstprocess char(250) , -- post process
@n_err2 int             , -- For Additional Error Detection
@b_debug int            ,  -- Debug 0 - OFF, 1 - Show ALL, 2 - Map
@c_checkstrategykey    char(10),  -- For Strategy Code Detection
@c_sqlstring	varchar(3000)


/* Set default values for variables */
SELECT @n_starttcnt=@@TRANCOUNT , @n_continue=1, @b_success=0,@n_err=0,@n_cnt = 0,@c_errmsg='',@n_err2=0
SELECT @b_debug = 0
--SELECT @c_docarton= 'Y'
IF @c_tblprefix = 'DS1' or @c_tblprefix = 'DS2'
BEGIN
SELECT @b_debug = Convert(Int, Right(@c_tblprefix, 1))
END
DECLARE @n_cnt_sql     int  -- Additional holds for @@ROWCOUNT to try catch a wrong processing
/* Execute Preprocess */
/* #INCLUDE <SPOP1.SQL> */     
/* End Execute Preprocess */
/* Start Main Processing */
IF @n_continue=1 or @n_continue=2
BEGIN
/* Both Orderkey and @c_tblprefix+'orders' is blank, return error */
/*Added by SMO-OngPW OR added for 80 compatibiilty */
set @c_orderkey = isnull(@c_orderkey,'')
set @c_oskey= isnull(@c_oskey,'')
IF (isnull(LTRIM(RTRIM(@c_orderkey)),'') = '' OR LTRIM(RTRIM(@c_orderkey)) = '') AND isnull(OBJECT_ID(@c_tblprefix+'orders'),'') = '' AND (isnull(LTRIM(RTRIM(@c_oskey)),'') = '' OR LTRIM(RTRIM(@c_oskey)) = '')
BEGIN
SELECT @n_continue = 3 
SELECT @n_err = 63500
SELECT @c_errmsg='NSQL'+CONVERT(char(5),@n_err)+': Invalid Parameters Passed (nspOrderProcessing)'
END 
END -- @n_continue =1 or @n_continue = 2
/* Create the TEMP Table To Hold The Orders */
/* DS: Commented out because not in use now */
/*  IF @n_continue = 1 or @n_continue =2 
BEGIN
SELECT OrderKey,Storerkey,ConsigneeKey,Type,Status,Priority,DeliveryDate,OrderDate,Intermodalvehicle,OrderGroup 
INTO #OPORDERS FROM ORDERS WHERE orderkey = '!XYZ!' 
SELECT @n_err = @@ERROR, @n_cnt = @@ROWCOUNT                
IF @n_err <> 0
BEGIN
SELECT @n_continue = 3 
SELECT @c_errmsg = CONVERT(char(250),@n_err), @n_err = 63501   -- Should Be Set To The SQL Errmessage but I don't know how to do so.                              
SELECT @c_errmsg='NSQL'+CONVERT(char(5),@n_err)+': Creation Of Temp Table Failed (nspOrderProcessing)' + ' ( ' + ' SQLSvr MESSAGE=' + LTRIM(RTRIM(@c_errmsg)) + ' ) '
END 
ELSE IF @n_cnt <> 0
BEGIN
SELECT @n_continue = 3 
SELECT @n_err = 63502
SELECT @c_errmsg='NSQL'+CONVERT(char(5),@n_err)+': Temp table unexpectedly created with rows. (nspOrderProcessing)'
END          

END
*/
/* End Create The TEMP Table To Hold The Orders */
/* Get a unique number to identity this run */
IF @n_continue = 1 or @n_continue = 2
BEGIN
DECLARE @c_oprun char(9)
SELECT @b_success = 0     
EXECUTE nspg_getkey 'OPRUN', 9, @c_oprun OUTPUT, @b_success OUTPUT, @n_err OUTPUT, @c_errmsg OUTPUT
END
/* End get a unique number to identify this run */
/* Execute preallocate routine */
IF @n_continue = 1 or @n_continue = 2
BEGIN
SELECT @b_success = 0     
EXECUTE nspPreAllocateOrderProcessing @c_orderkey, @c_oskey, @c_oprun, @c_doroute, @b_success OUTPUT, @n_err OUTPUT, @c_errmsg OUTPUT

END     
/* End execute preallocation routine */
/* Extract Line Items Into TempTable #OPORDERLINES */
IF @n_continue = 1 or @n_continue = 2
BEGIN
SELECT *, CARTONGROUP = SPACE(10), STRATEGYKEY = SPACE(10) INTO #OPORDERLINES FROM PREALLOCATEPICKDETAIL WHERE 1=2
SELECT @n_err = @@ERROR, @n_cnt = @@ROWCOUNT
IF @n_err <> 0
BEGIN
SELECT @n_continue = 3 
/* Trap SQL Server Error */
SELECT @c_errmsg = CONVERT(char(250),@n_err), @n_err = 63529   -- Should Be Set To The SQL Errmessage but I don't know how to do so.                              
SELECT @c_errmsg='NSQL'+CONVERT(char(5),@n_err)+': Creation of Temp Table #op_cartonlines Failed.(nspOrderProcessing)' + ' ( ' + ' SQLSvr MESSAGE=' + LTRIM(RTRIM(@c_errmsg)) + ' ) '
/* End Trap SQL Server Error */
END
END
IF @n_continue = 1 or @n_continue = 2
BEGIN
/*Added by SMO-OngPW AND added for 80 compatibiilty */
IF isnull(LTRIM(RTRIM(@c_orderkey)),'') <> '' AND LTRIM(RTRIM(@c_orderkey)) <> '' 
BEGIN
INSERT #OPORDERLINES 
SELECT * , CARTONGROUP = SPACE(10), STRATEGYKEY = SPACE(10) FROM PREALLOCATEPICKDETAIL WHERE ORDERKEY = @c_orderkey AND QTY > 0
END
ELSE
BEGIN   
/**** Commented by UK  not used for Apple 
DECLARE @d_orderdatestart datetime,@d_orderdateend datetime,@d_deliverydatestart datetime,@d_deliverydateend datetime,
@c_ordertypestart char(10),@c_ordertypeend char(10),@c_orderprioritystart char(10),@c_orderpriorityend char(10),
@c_storerkeystart char(15),@c_storerkeyend char(15),@c_consigneekeystart char(15),@c_consigneekeyend char(15),
@c_carrierkeystart char(15),@c_carrierkeyend char(15),@c_orderkeystart char(10),@c_orderkeyend char(10),
@c_externorderkeystart char(30),@c_externorderkeyend char(30),@c_ordergroupstart char(20),@c_ordergroupend char(20),@n_maxorders int 
SELECT @d_orderdatestart = orderdatestart,@d_orderdateend = orderdateend,@d_deliverydatestart = deliverydatestart,
@d_deliverydateend = deliverydateend,@c_ordertypestart = ordertypestart,@c_ordertypeend = ordertypeend,
@c_orderprioritystart = orderprioritystart,@c_orderpriorityend = orderpriorityend,@c_storerkeystart = storerkeystart,
@c_storerkeyend = storerkeyend,@c_consigneekeystart = consigneekeystart,@c_consigneekeyend = consigneekeyend,
@c_carrierkeystart = carrierkeystart,@c_carrierkeyend = carrierkeyend,@c_orderkeystart = orderkeystart,
@c_orderkeyend = orderkeyend,@c_externorderkeystart = externorderkeystart,@c_externorderkeyend = externorderkeyend,
@c_ordergroupstart = ordergroupstart,@c_ordergroupend = ordergroupend,@n_maxorders = maxorders
FROM OrderSelection WHERE OrderSelectionKey = @c_oskey
SELECT @n_cnt = @@ROWCOUNT                     
IF @n_cnt = 0
BEGIN
SELECT @n_continue = 3 
SELECT @n_err = 63505
SELECT @c_errmsg='NSQL'+CONVERT(char(5),@n_err)+': No Orders To Process. (nspOrderProcessing)'
END 
***/
                   
IF @n_continue = 1 or @n_continue = 2
BEGIN
INSERT #OPORDERLINES
SELECT PREALLOCATEPICKDETAIL.*, CARTONGROUP = SPACE(10), STRATEGYKEY = SPACE(10) 
FROM ORDERS,PREALLOCATEPICKDETAIL , WAVEDETAIL WHERE PREALLOCATEPICKDETAIL.Orderkey = Orders.Orderkey
AND NOT ORDERS.Status = '9' AND PREALLOCATEPICKDETAIL.QTY > 0 AND ORDERS.Orderkey = WAVEDETAIL.OrderKey AND WAVEDETAIL.WaveKey = @c_oskey 
  
/****** Commented by UK Not required for Apple 
AND ORDERS.Storerkey >=@c_storerkeystart AND ORDERS.Storerkey <= @c_storerkeyend
AND NOT ORDERS.Status = '9' AND ORDERS.ConsigneeKey >= @c_consigneekeystart
AND ORDERS.ConsigneeKey <=  @c_consigneekeyend AND ORDERS.Type >=  @c_ordertypestart
AND ORDERS.Type <=  @c_OrderTypeEnd AND ORDERS.OrderDate >= @d_orderdatestart
AND ORDERS.OrderDate <= @d_orderdateend AND ORDERS.DeliveryDate >= @d_deliveryDateStart
AND ORDERS.DeliveryDate <= @d_deliveryDateEnd AND ORDERS.Priority >= @c_orderpriorityStart
AND ORDERS.Priority <= @c_orderpriorityEnd AND ORDERS.Intermodalvehicle >= @c_carrierkeystart
AND ORDERS.Intermodalvehicle <= @c_carrierkeyend AND ORDERS.Orderkey >= @c_OrderkeyStart
AND ORDERS.Orderkey <= @c_OrderkeyEnd AND ORDERS.ExternOrderkey >= @c_ExternOrderkeyStart
AND ORDERS.ExternOrderkey <= @c_ExternOrderkeyEnd AND ORDERS.OrderGroup >= @c_ordergroupstart
AND PREALLOCATEPICKDETAIL.QTY > 0
***/
END                                   
END             
SELECT @n_err = @@ERROR, @n_cnt = @@ROWCOUNT
IF @n_err <> 0
BEGIN
SELECT @n_continue = 3 
/* Trap SQL Server Error */
SELECT @c_errmsg = CONVERT(char(250),@n_err), @n_err = 63510   -- Should Be Set To The SQL Errmessage but I don't know how to do so.                              
SELECT @c_errmsg='NSQL'+CONVERT(char(5),@n_err)+': Creation Of OPORDERLINES Temp Table Failed (nspOrderProcessing)' + ' ( ' + ' SQLSvr MESSAGE=' + LTRIM(RTRIM(@c_errmsg)) + ' ) '
/* End Trap SQL Server Error */
END                         
IF @n_continue = 1 or @n_continue = 2
BEGIN
SELECT @n_cnt = COUNT(*) FROM #OPORDERLINES
IF @n_cnt = 0               
BEGIN
SELECT @n_continue = 4
SELECT @n_err = 63511
SELECT @c_errmsg='NSQL'+CONVERT(char(5),@n_err)+': No Order Lines To Process. (nspOrderProcessing)'
execute nsp_logerror @n_err, @c_errmsg, 'nspOrderProcessing'               
END
ELSE IF (@b_debug = 1 or @b_debug = 2)
BEGIN
SELECT 'Number lines in #OPORDERLINES' = @n_cnt
IF @b_debug = 1
BEGIN
SELECT * FROM #OPORDERLINES ORDER BY PreallocatePickDetailKey
END
END
END                                             
END
/* End Extract Line Items Into TempTable #OPORDERLINES */
/* Read The Order Selection Table To Pick Up Other Order Processing Parameters */
IF @n_continue = 1 or @n_continue = 2
BEGIN
DECLARE @c_cartonizationgroup char(10) , @c_routingkey char(10) , @c_pickcode char(10) , @c_dorouting char(1) , @c_docartonization char(1),
@c_preallocationgrouping char(10) , @c_preallocationsort char(10) , @c_waveoption char(10) , @n_batchpickmaxcube int ,
@n_batchpickmaxcount int , @c_workoskey char(10) 
SELECT @c_dorouting = @c_doroute , @c_docartonization = @c_docarton
/**** Commented by UK not required for Apple 
IF isnull(LTRIM(RTRIM(@c_oskey)),'') <> ''
BEGIN
SELECT  @c_cartonizationgroup = cartonizationgroup , @c_routingkey = routingkey , @c_pickcode = pickcode ,
@c_dorouting = dorouting , @c_docartonization = docartonization , @n_maxorders = maxorders , @c_preallocationgrouping = preallocationgrouping ,
@c_preallocationsort = preallocationsort , @c_waveoption = waveoption , @n_batchpickmaxcube = batchpickmaxcube ,
@n_batchpickmaxcount = batchpickmaxcount FROM orderselection WHERE OrderSelectionKey = @c_oskey 
SELECT @c_workoskey = @c_oskey        
END
ELSE
BEGIN
SELECT  @c_cartonizationgroup = cartonizationgroup , @c_routingkey = routingkey , @c_pickcode = pickcode ,
@c_preallocationgrouping = preallocationgrouping , @c_preallocationsort = preallocationsort , @c_waveoption = waveoption ,
@n_batchpickmaxcube = batchpickmaxcube , @n_batchpickmaxcount = batchpickmaxcount , @c_workoskey = orderselectionkey
FROM ORDERSELECTION WHERE DefaultFlag = '1'                       
END
******/
-- Added by uk  for apple bax  only 
SELECT  @c_cartonizationgroup = cartonizationgroup , @c_routingkey = routingkey , @c_pickcode = pickcode ,
@c_preallocationgrouping = preallocationgrouping , @c_preallocationsort = preallocationsort , @c_waveoption = waveoption ,
@n_batchpickmaxcube = batchpickmaxcube , @n_batchpickmaxcount = batchpickmaxcount , @c_workoskey = orderselectionkey
FROM ORDERSELECTION WHERE DefaultFlag = '1'     
SELECT @n_cnt = @@ROWCOUNT                     
IF @n_cnt = 0
BEGIN
SELECT @n_continue = 3 
SELECT @n_err = 63512
SELECT @c_errmsg='NSQL'+CONVERT(char(5),@n_err)+': Incomplete Orderselection Parameters! (nspOrderProcessing)'
END                    
END     
/* End Read The Order Selection Table To Pick Up Other Order Processing Parameters */
/* Update the line items with pickcodes, cartonization codes etc */
IF @n_continue = 1 or @n_continue = 2
BEGIN
/* Update The Cartonization Code By Reading The SKU Table */
UPDATE #OPORDERLINES SET CARTONGROUP = SKU.CartonGroup FROM #OPORDERLINES,SKU
WHERE #OPORDERLINES.Storerkey = SKU.Storerkey AND #OPORDERLINES.Sku = SKU.Sku AND #OPORDERLINES.CartonGroup = SPACE(10) AND isnull(SKU.CartonGroup,'') <> ''
/* Update the Cartonization code by reading the Storer Table */
UPDATE #OPORDERLINES SET CARTONGROUP = Storer.CartonGroup FROM #OPORDERLINES,Storer
WHERE #OPORDERLINES.Storerkey = Storer.Storerkey AND #OPORDERLINES.CartonGroup = SPACE(10) AND isnull(Storer.CartonGroup,'') <> '' 
/* Update Packkey By Reading SKU Table */
UPDATE #OPORDERLINES SET PACKKEY = SKU.PackKey FROM #OPORDERLINES,SKU
WHERE #OPORDERLINES.Storerkey = SKU.Storerkey AND #OPORDERLINES.Sku = SKU.Sku AND #OPORDERLINES.PackKey = SPACE(10) AND isnull(SKU.PackKey,'') <> ''
UPDATE #OPORDERLINES SET STRATEGYKEY = STRATEGY.AllocateStrategyKey FROM #OPORDERLINES,SKU,STRATEGY 
WHERE #OPORDERLINES.Storerkey = SKU.Storerkey AND #OPORDERLINES.Sku = SKU.Sku AND SKU.Strategykey = Strategy.Strategykey
/* Set the Cartongroup for those that are still blank */
UPDATE #OPORDERLINES SET CARTONGROUP = @c_cartonizationgroup WHERE CartonGroup = space(10)
END
/* End Update the line items with pickcodes/cartonization codes etc */
/* Create a temp table that will hold the pickdetails */
IF @n_continue = 1 or @n_continue = 2
BEGIN
CREATE TABLE #OPPICKDETAIL (PickDetailKey    char(10) , PickHeaderKey    char(10) , OrderKey         char(10) ,
OrderLineNumber  char(10) , Storerkey        char(15) , Sku              char(20) , Loc              char(10) ,
Lot              char(10) , Id               char(18) , Caseid           char(10) , UOM              char(10) ,
UOMQty           int , Qty              Int , PackKey          char(10) , CartonGroup      char(10) ,
DoReplenish      char(1)  NULL, ReplenishZone    char(10) NULL, DoCartonize      char(1), PickMethod       char(1),
PalletId         char(10), DNnumber         char(10) NULL)
SELECT @n_err = @@ERROR, @n_cnt = @@ROWCOUNT
IF @n_err <> 0
BEGIN
SELECT @n_continue = 3 
/* Trap SQL Server Error */
SELECT @c_errmsg = CONVERT(char(250),@n_err), @n_err = 63513   -- Should Be Set To The SQL Errmessage but I don't know how to do so.                              
SELECT @c_errmsg='NSQL'+CONVERT(char(5),@n_err)+': Creation Of Temp Table Failed (nspOrderProcessing)' + ' ( ' + ' SQLSvr MESSAGE=' + LTRIM(RTRIM(@c_errmsg)) + ' ) '
/* End Trap SQL Server Error */
END 
END
/* End Create a temp table that will hold the pickdetails */
IF @n_continue = 1 or @n_continue = 2
BEGIN
/* Check overallocations flag */
DECLARE @c_allowoverallocations char(1) -- Flag to see if overallocations are allowed.
SELECT @c_allowoverallocations = NSQLValue FROM NSQLCONFIG (NOLOCK) WHERE CONFIGKEY = 'ALLOWOVERALLOCATIONS'
IF isnull(@c_allowoverallocations,'') = ''
BEGIN
SELECT @c_allowoverallocations = '0'
END
IF @b_debug = 1
BEGIN
SELECT 'ALLOWOVERALLOCATIONS' = @c_allowoverallocations
END
/* End Check overallocations flag */          
END
/* Create temp tables for use when overallocation is ON */
IF @c_allowoverallocations = '1'
BEGIN
/* To hold list of locations with LocationTypeOverride */
IF ( @n_continue = 1 or @n_continue = 2 )
BEGIN
CREATE TABLE #OP_PICKLOCTYPE (loc  char(10) )
SELECT @n_err = @@ERROR, @n_cnt = @@ROWCOUNT
IF @n_err <> 0
BEGIN
SELECT @n_continue = 3 
/* Trap SQL Server Error */
SELECT @c_errmsg = CONVERT(char(250),@n_err), @n_err = 63528   -- Should Be Set To The SQL Errmessage but I don't know how to do so.                              
SELECT @c_errmsg='NSQL'+CONVERT(char(5),@n_err)+': Creation Of #OP_PICKLOCTYPE Temp Table Failed (nspOrderProcessing)' + ' ( ' + ' SQLSvr MESSAGE=' + LTRIM(RTRIM(@c_errmsg)) + ' ) '
/* End Trap SQL Server Error */
END 
END
/* End To hold list of locations with LocationTypeOverride */
/* Create a temp table to hold a list of LOTxLOCxID rows */
IF ( @n_continue = 1 or @n_continue = 2 )
BEGIN
CREATE TABLE #OP_OVERPICKLOCS (rownum      int IDENTITY,
     loc          char(10) ,      id           char(18) ,      QtyAvailable int)
SELECT @n_err = @@ERROR, @n_cnt = @@ROWCOUNT
IF @n_err <> 0
BEGIN
SELECT @n_continue = 3 
/* Trap SQL Server Error */
SELECT @c_errmsg = CONVERT(char(250),@n_err), @n_err = 63528   -- Should Be Set To The SQL Errmessage but I don't know how to do so.                              
SELECT @c_errmsg='NSQL'+CONVERT(char(5),@n_err)+': Creation Of #OP_OVERPICKLOCS Temp Table Failed (nspOrderProcessing)' + ' ( ' + ' SQLSvr MESSAGE=' + LTRIM(RTRIM(@c_errmsg)) + ' ) '
/* End Trap SQL Server Error */
END 
END
/* End Create a temp table to hold a list of LOTxLOCxID rows */
/* Create a temp table to hold casepick/piecepick locations already used */
/* when striping picks across these locations      */
IF ( @n_continue = 1 or @n_continue = 2 )
BEGIN
CREATE TABLE #OP_PICKLOCS (StorerKey    char(15) ,
  Sku          char(20) ,  Loc          char(10) ,   LocationType char(10) )
SELECT @n_err = @@ERROR, @n_cnt = @@ROWCOUNT
IF @n_err <> 0
BEGIN
SELECT @n_continue = 3 
/* Trap SQL Server Error */
SELECT @c_errmsg = CONVERT(char(250),@n_err), @n_err = 63528   -- Should Be Set To The SQL Errmessage but I don't know how to do so.                              
SELECT @c_errmsg='NSQL'+CONVERT(char(5),@n_err)+': Creation Of #OP_PICKLOCS Temp Table Failed (nspOrderProcessing)' + ' ( ' + ' SQLSvr MESSAGE=' + LTRIM(RTRIM(@c_errmsg)) + ' ) '
/* End Trap SQL Server Error */
END 
END
/* End Create a temp table to hold casepick/piecepick locations already used */
END 
/* End Create temp tables for use when overallocation is ON */
/* Here comes the fun part */
/* For each group - generate the candidate set and allocate inventory */
IF @n_continue = 1 or @n_continue = 2
BEGIN
/* Variables Used To Mangage Looping Through Line Items */
DECLARE @c_Astorerkey char(15), @c_Asku char(20), @c_Aorderkey char(10), 
@c_Aorderlinenumber char(5), @c_Auom char(5), @n_Auomqty int ,
@n_Aqtylefttofulfill int, @c_Apackkey char(10), @c_Adocartonize char(1) ,
@c_Alot char(10), @c_Ashipfrom varchar(20), @c_Apreallocatepickdetailkey char(10) ,
@c_AStrategykey char(10), @c_Acartongroup char(10), @c_ApickMethod char(1)
/* Variables Used To Manage/Loop Candidate Cursor */
DECLARE @c_cloc char(10) ,@c_cid char(18) , @n_cqtyavailable int, @c_endstring char(30) ,
@n_cursorcandidates_open int,
@b_candidateexhausted int, @n_candidateline int
SELECT @b_candidateexhausted=0, @n_candidateline = 0           
/* Variables used to calculate qty to take from the candidates */
DECLARE @n_available int, @n_qtytotake int, @n_uomqty int ,  @n_cpackqty int,@n_jumpsource int
SELECT @n_available = 0, @n_qtytotake = 0, @n_uomqty = 0, @n_cpackqty = 0
/* Variables used while looping through the strategy table */
DECLARE @c_scurrentlinenumber char(5), @c_sallocatepickcode char(10) ,
@c_slocationtypeoverride char(10), @c_slocationtypeoverridestripe char(10)
/* Variables used when overallocations is turned on and that section */
/* of the code is triggered */
DECLARE @c_pickloc char(10), @b_overcontinue int, @c_pickId char(18), @n_pickQty int,
@n_rownum int, @n_qtytoovertake int
/* Variables to be used while creating the pickdetail records */
DECLARE @c_pickdetailkey char(10), @c_pickheaderkey char(5), @n_pickrecscreated int ,
@b_pickupdatesuccess int, @n_qtytoinsert int, @n_uomqtytoinsert int
/* Variables used for calculating pickmethods */
DECLARE @c_uom1pickmethod char(1) ,
@c_uom2pickmethod char(1) ,                  
@c_uom3pickmethod char(1) ,                  
@c_uom4pickmethod char(1) ,                  
@c_uom5pickmethod char(1) ,                  
@c_uom6pickmethod char(1) ,
@c_uom7pickmethod char(1) 
/* This variable will be used to control how the program acts when */
/* the preallocation qty cannot be fulfilled.                      */
/* When this variable is set to 1 we will loop around if there are */                  
/* quantity left over.                                             */
/* The additional variables support this process.                  */
DECLARE @b_tryifqtyremain int, @n_numberofretries int
SELECT @b_tryifqtyremain = 1, @n_numberofretries = 0          
DECLARE @n_caseqty int, @n_palletqty int, @n_innerpackqty int, 
@n_otherunit1 int , @n_otherunit2 int,
@c_cartonizeCase char(1), @c_cartonizePallet char(1), @c_cartonizeInner char(1), 
@c_cartonizeOther1 char(1), @c_cartonizeOther2 char(1), @c_cartonizeEA char(1)
SELECT @n_caseqty = 0, @n_palletqty=0, @n_innerpackqty = 0, @n_otherunit1=0, @n_otherunit2=0
/* Loop through line items */
SELECT @c_Apreallocatepickdetailkey = SPACE(10)

/*Added by wbtan on microsoft recommendation*/
create clustered index #OPORDERLINES_PDKEY on #OPORDERLINES (PreAllocatePickDetailKey)

WHILE (1 = 1) and (@n_continue = 1 or @n_continue = 2)
BEGIN
SET ROWCOUNT 1
SELECT @c_Apreallocatepickdetailkey = PreAllocatePickDetailKey ,
@c_Astorerkey = storerkey ,
@c_Asku = sku ,
@c_Aorderkey = orderkey,
@c_AOrderlinenumber = Orderlinenumber ,
@c_Auom = uom ,
@n_Auomqty = uomqty ,
@n_Aqtylefttofulfill = qty ,
@c_Apackkey = packkey ,
@c_Acartongroup = cartongroup ,
@c_Adocartonize = docartonize,
@c_Alot = lot ,
@c_Ashipfrom = ShipFrom ,
@c_APickMethod = PickMethod ,
@c_AStrategykey = Strategykey
FROM #OPORDERLINES
WHERE PreAllocatePickDetailKey > @c_Apreallocatepickdetailkey
ORDER BY PreAllocatePickDetailKey
IF @@ROWCOUNT = 0
BEGIN
SET ROWCOUNT 0
BREAK
END
ELSE IF ( @b_debug = 1 or @b_debug = 2 )
BEGIN
PRINT ' '
PRINT ' * Loop PreAllocatePickDetai Lines'
SELECT 'PreAllocatePickDetailKey'=@c_Apreallocatepickdetailkey,
'StorerKey'=@c_Astorerkey, 'Sku'=@c_Asku,
'OrderKey'=@c_Aorderkey, 'Orderlinenumber'=@c_AOrderlinenumber,
'Lot'=@c_Alot, 'UOM'=@c_Auom, 'UOMQty'=@n_Auomqty, 'Qty'=@n_Aqtylefttofulfill, 'PackKey'=@c_Apackkey
END
SET ROWCOUNT 0
/* Reverse engineer the packqty */
SELECT @n_cpackqty = @n_Aqtylefttofulfill/@n_Auomqty
/* Get some flags from the strategy header */
SELECT @b_tryifqtyremain = retryifqtyremain
FROM ALLOCATESTRATEGY
WHERE ALLOCATESTRATEGYKEY = @c_AStrategykey
/* Loop through the pick strategy table for this uom */
SELECT @c_scurrentlinenumber = SPACE(5)               
SELECT @n_numberofretries = 0               
LOOPPICKSTRATEGY:
WHILE (@n_continue = 1 or @n_continue = 2) and @n_numberofretries <= 7
BEGIN
SET ROWCOUNT 1
SELECT @c_scurrentlinenumber = AllocateStrategyLineNumber ,
@c_sallocatepickcode = Pickcode ,
@c_slocationtypeoverride = LocationTypeOverride,
@c_slocationtypeoverridestripe = LocationTypeOverrideStripe
FROM ALLOCATESTRATEGYDETAIL
WHERE AllocateStrategyLineNumber > @c_scurrentlinenumber
AND UOM = @c_Auom
AND ALLOCATESTRATEGYKEY = @c_AStrategykey
ORDER BY AllocateStrategyLineNumber
IF @@ROWCOUNT = 0
BEGIN SET ROWCOUNT 0
BREAK
END
SET ROWCOUNT 0
IF ( @b_debug = 1 or @b_debug = 2 )
BEGIN
Print ' ** LOOP AllocateStrategyDetail '
SELECT 'AllocateStrategyLineNumber' = @c_scurrentlinenumber, 
'@n_Aqtylefttofulfill'=@n_Aqtylefttofulfill, '@n_Auomqty'=@n_Auomqty,
'UOM' = @c_Auom, 'Pickcode' = @c_sallocatepickcode,
'LocationTypeOverride' = @c_slocationtypeoverride, 'LocationTypeOverrideStripe' = @c_slocationtypeoverridestripe 
END
/*Added by SMO-OngPW OR added for 80 compatibiilty */
IF ( isnull(LTRIM(RTRIM(@c_slocationtypeoverride)),'') = '' OR LTRIM(RTRIM(@c_slocationtypeoverride)) = '' ) or (@c_allowoverallocations = '0')
BEGIN
DECLARECURSOR_CANDIDATES:               
SELECT @n_cursorcandidates_open = 0                              
-- JN: Added ShipFrom to list of parameters to be considered when selecting candidates
SELECT @c_endstring = ltrim(convert(char(10),@n_cpackqty)) + ',' + isnull(ltrim(convert(char(10), @n_Aqtylefttofulfill)),'') + ',''' + isnull(ltrim(@c_Ashipfrom),'') + ''''
set @c_sqlstring = @c_sallocatepickcode + ' ' + '''' + isnull(@c_Alot,'') +'''' +',' + '''' + isnull(@c_Auom,'') +''''+ ',' + isnull(@c_endstring,'')
EXEC(@c_sqlstring)
/* Evaluate Errors From Declaring Cursor */

SELECT @n_err = @@ERROR, @n_cnt = @@ROWCOUNT
IF @n_err = 16915 /* Cursor Already Exists So Close, Deallocate And Try Again! */
BEGIN
CLOSE CURSOR_CANDIDATES
DEALLOCATE CURSOR_CANDIDATES
GOTO DECLARECURSOR_CANDIDATES
END
/* END Evaluate Errors From Declaring Cursor */          
OPEN CURSOR_CANDIDATES                    
/* Evaluate Errors From Opening Cursor */
SELECT @n_err = @@ERROR, @n_cnt = @@ROWCOUNT
IF @n_err = 16905 /* Cursor Already Opened! */
BEGIN
CLOSE CURSOR_CANDIDATES
DEALLOCATE CURSOR_CANDIDATES
GOTO DECLARECURSOR_CANDIDATES               
END
/* End Evaluate Errors From Opening Cursor */          
IF @n_err <> 0
BEGIN
SELECT @n_continue = 3 

/* Trap SQL Server Error */
SELECT @c_errmsg = CONVERT(char(250),@n_err), @n_err = 63515   -- Should Be Set To The SQL Errmessage but I don't know how to do so.                              
SELECT @c_errmsg='NSQL'+CONVERT(char(5),@n_err)+': Creation/Opening of Candidate Cursor Failed! (nspOrderProcessing)' + ' ( ' + ' SQLSvr MESSAGE=' + LTRIM(RTRIM(@c_errmsg)) + ' ) '
/* End Trap SQL Server Error */
END                                        
ELSE
BEGIN
SELECT @n_cursorcandidates_open = 1                            
END               
/* End Get The Candidate Set */
IF (@n_continue = 1 or @n_continue = 2) AND @n_cursorcandidates_open = 1
BEGIN
SELECT @n_candidateline = 0
WHILE @n_Aqtylefttofulfill > 0
BEGIN
SELECT @n_candidateline = @n_candidateline + 1
IF @n_candidateline = 1
BEGIN
FETCH       FROM CURSOR_CANDIDATES INTO @c_cloc, @c_cid, @n_cqtyavailable
END
ELSE
BEGIN
FETCH NEXT FROM CURSOR_CANDIDATES INTO @c_cloc, @c_cid, @n_cqtyavailable
END
IF @@FETCH_STATUS < 0
BEGIN
BREAK
END
IF @@FETCH_STATUS = 0
BEGIN
/* How much of the current uom can this line provide us with? */
SELECT @n_available = Floor(@n_cqtyavailable/@n_cpackqty) * @n_cpackqty                              
/* How much should we take from this line? */
IF @n_available >= @n_Aqtylefttofulfill
BEGIN
     SELECT @n_qtytotake = @n_Aqtylefttofulfill
END
ELSE
BEGIN
     SELECT @n_qtytotake = @n_available
END
/* Convert the amount needed to UOM Qty */
SELECT @n_uomqty = floor(@n_qtytotake / @n_cpackqty)
IF @b_debug = 1 or @b_debug = 2
BEGIN
     Print 'Fetched next Cursor_Candidate'
     SELECT '@c_cloc'=@c_cloc, '@c_cid'=@c_cid, '@n_cqtyavailable'=@n_cqtyavailable
     SELECT '@n_Aqtylefttofulfill'=@n_Aqtylefttofulfill, '@n_qtytotake'=@n_qtytotake, '@n_uomqty'=@n_uomqty
END
IF @n_qtytotake > 0
BEGIN
     /* Override Include Statements Here */
     /* #INCLUDE <SPOP4.SQL> */
     /* End Override Include Statements Here */                                        
     SELECT @n_jumpsource = 1
     GOTO UPDATEINV
     RETURNFROMUPDATEINV_01:
END
END
END -- WHILE @n_Aqtylefttofulfill > 0
END -- (@n_continue = 1 or @n_continue = 2) AND @n_cursorcandidates_open = 1
IF @n_cursorcandidates_open = 1
BEGIN
/* Close Cursor - Ignore Error Messages If Any */
CLOSE CURSOR_CANDIDATES      
/* Deallocate Cursor - Ignore Error Messages If Any */
DEALLOCATE CURSOR_CANDIDATES
END
END
ELSE
BEGIN
/* OVERALLOCATION */
/* Assign all these picks to the locationtype specified */
/* in the locationtypeoverride field                    */
/* There are two algorithms available:                  */
/*     1. If the locationtypeoverridestripe field is    */
/*        not set, simply assign all qty to the first   */
/*        location of the specified type                */
/*     2. If the locationtypeoverridestrip field is     */
/*        is a '1' then we must assign every line       */
/*        to a different location until we run out      */
/*        and then start over again.                    */
SELECT @b_overcontinue = 1
/* First, verify that there is a location of this type */
/* for this SKU in the SKUxLOC table.                  */
/* If there isn't, Error Out!.                         */
IF @b_overcontinue = 1
BEGIN

DELETE #OP_OVERPICKLOCS
DELETE #OP_PICKLOCTYPE
INSERT #OP_PICKLOCTYPE
SELECT LOC 
FROM SKUxLOC (nolock)
WHERE SKUxLOC.STORERKEY = @c_Astorerkey
AND SKUxLOC.SKU = @c_Asku
AND SKUxLOC.LOCATIONTYPE = @c_slocationtypeoverride
SELECT @n_cnt = @@ROWCOUNT, @n_err = @@ERROR
IF @n_cnt = 0 or @n_err <> 0
BEGIN
SELECT @b_overcontinue = 0
END
ELSE
BEGIN
/* Make sure we have at least one row per loc */
INSERT LOTxLOCxID (StorerKey, Sku, Lot, Loc, Id, Qty)
SELECT @c_AStorerKey, @c_ASku, @c_ALot, Loc, Space(10), 0
FROM #OP_PickLocType
WHERE not exists ( SELECT * FROM LOTxLOCxID
                WHERE StorerKey = @c_AStorerKey
                  AND SKU = @c_ASku
                  AND Lot = @c_ALot
                  AND Loc = #OP_PickLocType.Loc ) 
IF @@ERROR <> 0
BEGIN
SELECT @b_overcontinue = 0
END
END
IF @b_debug = 1 or @b_debug = 2
BEGIN
Print ' Candidate locations #OP_PickLocType'
SELECT * FROM #OP_PickLocType
END     
/* Figure out what row we'll use for overallocate */
IF @b_overcontinue = 1
BEGIN

SELECT @c_pickLoc = ''
                         
IF @c_slocationtypeoverridestripe = '1'
BEGIN
/* This is algorithm #2 */
/* step 1 - get a location of this type from skuxloc */
/* that has not been used yet.                       */
/* step 2 - if none exists, then delete from         */
/* #OP_PICKLOCS.                                     */
/* Either which way, place the one that was used     */
/* into the #OP_PICKLOCS table                       */
SET ROWCOUNT 1
SELECT @c_pickloc = LOC

 FROM #OP_PickLocType
 WHERE LOC NOT IN (SELECT LOC FROM #OP_PICKLOCS
                     WHERE STORERKEY = @c_Astorerkey
                       AND SKU = @c_Asku
                       AND LocationType = @c_slocationtypeoverride
                   )
 ORDER BY Loc
SET ROWCOUNT 0
/*Added by SMO-OngPW OR  added for 80 compatibiilty */                                                                    
IF isnull(Ltrim(@c_pickLoc),'') = '' OR Ltrim(@c_pickLoc) = ''
BEGIN
     DELETE FROM #OP_PICKLOCS
       WHERE STORERKEY = @c_Astorerkey
          AND SKU = @c_Asku
          AND LocationType = @c_slocationtypeoverride
     SET ROWCOUNT 1
     SELECT @c_pickloc = LOC
      FROM #OP_PickLocType
      ORDER BY LOC
     SET ROWCOUNT 0
END
INSERT #OP_PICKLOCS (StorerKey, Sku, Loc, LocationType)
VALUES ( @c_Astorerkey, @c_Asku, @c_pickloc, @c_slocationtypeoverride )
END
ELSE
BEGIN         
/* This is algorithm #1 */
SET ROWCOUNT 1
SELECT @c_pickloc = LOC
 FROM #OP_PickLocType
 ORDER BY LOC
SET ROWCOUNT 0
END                                   
END
IF @b_debug = 1 or @b_debug = 2
BEGIN
SELECT '@c_pickloc to Overallocate' = @c_pickloc
END     
/* Get a list of candidate lines */     
INSERT #OP_OVERPICKLOCS (Loc, Id, QtyAvailable)
SELECT LOTXLOCXID.LOC, LOTXLOCXID.ID, 
Floor((LOTXLOCXID.Qty - LOTXLOCXID.QtyAllocated - LOTXLOCXID.QtyPicked)/@n_cpackqty)*@n_cpackqty
FROM LOTXLOCXID, #OP_PickLocType
WHERE LOTXLOCXID.STORERKEY = @c_Astorerkey
AND LOTXLOCXID.Sku = @c_Asku
AND LOTXLOCXID.Lot = @c_ALot
AND LOTXLOCXID.Loc = #OP_PickLocType.Loc
AND ( Floor((LOTXLOCXID.Qty - LOTXLOCXID.QtyAllocated - LOTXLOCXID.QtyPicked)/@n_cpackqty) > 0
OR LOTXLOCXID.Loc = @c_pickloc )
ORDER BY CASE when #OP_PickLocType.Loc = @c_pickloc 
     then 1 else 2 end, 1, 2
IF @@ROWCOUNT = 0
BEGIN
SELECT @b_overcontinue = 0          
END
ELSE IF @b_debug = 1 or @b_debug = 2
BEGIN
Print ' Candidate lines #OP_OVERPICKLOCS'
Select * from #OP_OVERPICKLOCS
Order by RowNum
END
/* Let's do a job */
IF @b_overcontinue = 1
BEGIN
/* Calculate expected qty for overallocated loc */
SELECT @n_qtytoovertake = Sum(CASE when QtyAvailable > 0 
                              then QtyAvailable else 0 end )
FROM #OP_OVERPICKLOCS
IF @n_Aqtylefttofulfill <= @n_qtytoovertake
BEGIN
SELECT @n_qtytoovertake = 0
END
ELSE 
BEGIN
SELECT @n_qtytoovertake = @n_Aqtylefttofulfill - @n_qtytoovertake
END
IF @b_debug = 1

BEGIN
SELECT '@n_qtytoovertake'=@n_qtytoovertake, '@n_Aqtylefttofulfill'=@n_Aqtylefttofulfill
END
SELECT @n_rownum = 0
WHILE @n_Aqtylefttofulfill > 0
BEGIN
SET ROWCOUNT 1
SELECT @n_rownum = RowNum, @c_cloc = LOC, @c_cid = Id, 
     @n_qtytotake = CASE when QtyAvailable > 0 
                         then QtyAvailable else 0 end
 FROM #OP_OVERPICKLOCS
 WHERE Rownum >  @n_rownum
 ORDER BY Rownum
 
IF @@ROWCOUNT = 0
BEGIN

     SET ROWCOUNT 0
     BREAK
END
SET ROWCOUNT 0
IF @c_cloc = @c_pickloc
BEGIN
     SELECT @n_qtytotake = @n_qtytotake + @n_qtytoovertake
     SELECT @n_qtytoovertake = 0
END
IF @n_Aqtylefttofulfill < @n_qtytotake
BEGIN
     SELECT @n_qtytotake = @n_Aqtylefttofulfill
END
SELECT @n_uomqty = @n_qtytotake / @n_cpackqty
IF @b_debug = 1 or @b_debug = 2
BEGIN
     Print 'Ready to take'
     Select '@c_cloc'=@c_cloc, '@c_cid'=@c_cid, '@n_qtytotake'=@n_qtytotake,
            '@n_uomqty'=@n_uomqty, '@n_Aqtylefttofulfill'=@n_Aqtylefttofulfill
END
     
IF @n_qtytotake > 0
BEGIN
     SELECT @n_jumpsource = 2
     GOTO UPDATEINV
     RETURNFROMUPDATEINV_02:
END
END
/* Override Include Statements Here */
/* #INCLUDE <SPOP5.SQL> */
/* End Override Include Statements Here */                                        
END -- End of doing a job
END  -- End of OVERALLOCATION                            
END -- IF isnull(LTRIM(RTRIM(@c_slocationtypeoverride)),'') = ''
END -- LOOP ALLOCATE STRATEGY DETAIL Lines
SET ROWCOUNT 0
/* This set of code loops the program around to try to fulfill */
/* any remaining quantities.                                   */
TRYIFQTYREMAIN:               
IF @b_tryifqtyremain = 1 and @n_Aqtylefttofulfill > 0 and @n_numberofretries < 7
BEGIN               
/* DS: We need refresh pack information just one time for particular orderdetail row */
IF @n_numberofretries  = 0
BEGIN
SELECT @n_palletqty = Pallet, @c_cartonizePallet = CartonizeUOM4,
@n_caseqty = CaseCnt, @c_cartonizeCase = CartonizeUOM1, 
@n_innerpackQty = innerpack, @c_cartonizeInner = CartonizeUOM2,
@n_otherunit1 = CONVERT(int,OtherUnit1), @c_cartonizeOther1 = CartonizeUOM8,
@n_otherUnit2 = CONVERT(int,Otherunit2), @c_cartonizeOther2 = CartonizeUOM9,
@c_cartonizeEA = CartonizeUOM3
FROM PACK (nolock)
WHERE PACKKEY = @c_Apackkey
END
SELECT @n_numberofretries = @n_numberofretries + 1               
SELECT @c_Auom = Ltrim(Rtrim(Convert(char(5), (Convert(int,@c_Auom) + 1))))
SELECT @n_cpackqty =                     
CASE @c_Auom
WHEN '1' THEN @n_palletqty
WHEN '2' THEN @n_caseqty
WHEN '3' THEN @n_innerpackqty 
WHEN '4' THEN @n_otherunit1
WHEN '5' THEN @n_otherunit2
WHEN '6' THEN 1
WHEN '7' THEN 1
ELSE 0
END    
SELECT @c_Adocartonize =                     
CASE @c_Auom
WHEN '1' THEN @c_cartonizePallet
WHEN '2' THEN @c_cartonizeCase
WHEN '3' THEN @c_cartonizeInner
WHEN '4' THEN @c_cartonizeOther1
WHEN '5' THEN @c_cartonizeOther2
WHEN '6' THEN @c_cartonizeEA
WHEN '7' THEN @c_cartonizeEA
ELSE 'N'
END    
IF @n_cpackqty > 0
BEGIN
GOTO LOOPPICKSTRATEGY
END
ELSE
BEGIN
GOTO TRYIFQTYREMAIN
END                         
END
/* End loop around to fulfill remaining quantities if necessary */
/* End Loop through the pick strategy table for this uom */               
END -- WHILE (1 = 1)
SET ROWCOUNT 0
/* End Loop through line items */
END -- of fun part
/* Cartonize Partials */
DECLARE @c_cartonbatch char(10)
IF @n_continue = 1 or @n_continue = 2
BEGIN
SELECT @b_success = 0     
/********************************/
SET ROWCOUNT 1
SELECT 	@c_checkstrategykey = SKU.STRATEGYKEY 
FROM 	SKU,#OPORDERLINES
WHERE 	#OPORDERLINES.Storerkey = SKU.Storerkey AND    
	#OPORDERLINES.Sku = SKU.Sku
SET ROWCOUNT 0 
SELECT @n_err = @@ERROR, @n_cnt = @@ROWCOUNT
IF @n_err <> 0
BEGIN
SELECT @n_continue = 3 
SELECT @c_errmsg = CONVERT(char(250),@n_err), @n_err = 63527   
SELECT @c_errmsg='NSQL'+CONVERT(char(5),@n_err)+':   SELECTION OF DISTINCT STRATEGY KEY FAILED -nsporderprocessing' + ' ( ' + ' SQLSvr MESSAGE=' + LTRIM(RTRIM(@c_errmsg)) + ' ) '
END 
/* DS: we'll use existing OPRun number instead of call to generate new  */
SELECT @c_cartonbatch = @c_oprun
INSERT OP_CARTONLINES 
	(Cartonbatch, pickheaderkey,pickdetailkey,orderkey,orderlinenumber,storerkey,sku,
	loc,lot,id,caseid,uom,uomqty,qty,packkey,cartongroup,DoReplenish, replenishzone, docartonize,PickMethod,PalletId,DNnumber )
	(SELECT @c_cartonbatch,pickheaderkey,pickdetailkey,orderkey,orderlinenumber,storerkey,sku,
		loc,lot,id,caseid,uom,uomqty,qty,packkey,cartongroup,DoReplenish, replenishzone, docartonize,PickMethod,PalletId,DNnumber 
		FROM #OPPICKDETAIL )                    

/* Execute The Cartonization Procedure */
IF @c_docartonization = 'Y'
BEGIN
	SELECT @b_success = 0  
	BEGIN 
		EXECUTE nspCartonization @c_cartonbatch, @b_success OUTPUT, @n_err OUTPUT, @c_errmsg OUTPUT
	END 
	IF @b_success <> 1
	BEGIN
		SELECT @n_continue = 3
	END
END          
/* Back from the Cartonization Procedure */                    

/* Break pickdetail into qty=1 for serialized product */
IF EXISTS (SELECT 1 FROM NSQLCONFIG WHERE CONFIGKEY = 'BAX_SerializePickDetail' AND NSQLVALUE = '1')
BEGIN
	EXECUTE nspSerializePickDetail @c_cartonbatch, @b_success OUTPUT, @n_err OUTPUT, @c_errmsg OUTPUT
	IF @b_success <> 1
	BEGIN
		SELECT @n_continue = 3
	END
END
/* Break pickdetail into qty=1 for serialized product */

END
/* End Cartonize Partials */
/* Group Into Pick Tickets */
IF (@n_continue = 1 or @n_continue = 2) AND @c_waveoption <> 'NONE'
BEGIN
SELECT @b_success = 0          
EXECUTE nspOrderProcessingWave
@c_cartonbatch, @c_workoskey, @b_success OUTPUT, @n_err OUTPUT, @c_errmsg OUTPUT
IF @b_success <> 1
BEGIN
SELECT @n_continue = 3
END
END
/* End Group Into Pick Tickets */
/* Insert Into Live Pick Files - Final Post One Order At A Time!*/
IF ( @n_continue =1 OR @n_continue =2 )
BEGIN
DECLARE @c_currentorder char(10)
WHILE (@n_continue = 1 or @n_continue = 2)
BEGIN
/* Get the next order to post */
SET ROWCOUNT 1
SELECT @c_currentorder = Orderkey 
FROM OP_CARTONLINES WHERE Cartonbatch = @c_cartonbatch               
IF @@ROWCOUNT = 0
BEGIN
SET ROWCOUNT 0               
BREAK
END
SET ROWCOUNT 0 
/* End get the next order to post */
-- DS: Here was a nested loop by OrderLineNumber which was deleted to spead up the process
BEGIN TRANSACTION 
IF (1=1)
BEGIN
UPDATE PICKDETAIL SET TrafficCop = Null, ArchiveCop = '9'
WHERE PickHeaderKey = 'N'+@c_oprun
AND ORDERKEY = @c_currentorder
SELECT @n_err = @@ERROR, @n_cnt = @@ROWCOUNT
IF @n_err <> 0
BEGIN
SELECT @n_continue = 3 
/* Trap SQL Server Error */
SELECT @c_errmsg = CONVERT(char(250),@n_err), @n_err = 63527   -- Should Be Set To The SQL Errmessage but I don't know how to do so.                              
SELECT @c_errmsg='NSQL'+CONVERT(char(5),@n_err)+': Update to pickdetail table failed.  Preallocated QTY Needs to be Manually Adjusted! (nspOrderProcessing)' + ' ( ' + ' SQLSvr MESSAGE=' + LTRIM(RTRIM(@c_errmsg)) + ' ) '
/* End Trap SQL Server Error */
END                
IF @n_continue = 1 or @n_continue = 2
BEGIN     
DELETE FROM PICKDETAIL WHERE PickHeaderKey = 'N'+@c_oprun
               AND ORDERKEY = @c_currentorder
SELECT @n_err = @@ERROR, @n_cnt = @@ROWCOUNT
IF @n_err <> 0
BEGIN
SELECT @n_continue = 3 
/* Trap SQL Server Error */
SELECT @c_errmsg = CONVERT(char(250),@n_err), @n_err = 63523   -- Should Be Set To The SQL Errmessage but I don't know how to do so.                              
SELECT @c_errmsg='NSQL'+CONVERT(char(5),@n_err)+': Delete From live pickdetail table failed.  Preallocated QTY Needs to be Manually Adjusted! (nspOrderProcessing)' + ' ( ' + ' SQLSvr MESSAGE=' + LTRIM(RTRIM(@c_errmsg)) + ' ) '
/* End Trap SQL Server Error */
END                
END                         
END
IF @n_continue = 1 or @n_continue = 2
BEGIN
IF (1=1)
BEGIN          
INSERT PICKDETAIL (PickDetailKey,Caseid,PickHeaderkey,OrderKey,OrderLineNumber,Lot,Storerkey,
          Sku,PackKey,UOM,UOMQty,Qty,Loc,ID,Cartongroup,Cartontype,DoReplenish, replenishzone, docartonize,Trafficcop,OptimizeCop,PickMethod,PalletId,DNnumber)
         (SELECT PickDetailKey,Caseid,PickHeaderkey,OrderKey,OrderLineNumber,Lot,Storerkey,
         Sku,PackKey,UOM,UOMQty,Qty,Loc,ID,CartonGroup,Cartontype,DoReplenish, replenishzone, docartonize,'U', '9',PickMethod,PalletId,DNnumber
          FROM OP_CARTONLINES 
          WHERE Cartonbatch = @c_cartonbatch
            AND ORDERKEY = @c_currentorder
          )    

/* Assign boxount */
IF EXISTS (SELECT * FROM NSQLCONFIG WHERE CONFIGKEY = 'BAX_AssignBoxCount' AND NSQLVALUE = '1')
BEGIN
	EXECUTE nspAssignBoxCount @c_currentorder, @b_success OUTPUT, @n_err OUTPUT, @c_errmsg OUTPUT
	IF @b_success <> 1
	BEGIN
		SELECT @n_continue = 3
	END
END
/* Assign Boxcount */
                          
END
SELECT @n_err = @@ERROR, @n_cnt = @@ROWCOUNT
IF @n_err <> 0
BEGIN
SELECT @n_continue = 3 
/* Trap SQL Server Error */
SELECT @c_errmsg = CONVERT(char(250),@n_err), @n_err = 63524   -- Should Be Set To The SQL Errmessage but I don't know how to do so.                              
SELECT @c_errmsg='NSQL'+CONVERT(char(5),@n_err)+': Insert into live pickdetail table failed.  Preallocated QTY Needs to be Manually Adjusted! (nspOrderProcessing)' + ' ( ' + ' SQLSvr MESSAGE=' + LTRIM(RTRIM(@c_errmsg)) + ' ) '
/* End Trap SQL Server Error */
END                
END
/* Added by Gregory Lee */
IF @n_continue = 1 or @n_continue = 2
BEGIN
	DECLARE @n_nopicks int
	DECLARE @c_transmitlogkey char(10)
	DECLARE @c_pickkey char(10)
	SELECT 	@c_pickkey = ''
	SELECT  @n_nopicks = count(*) FROM OP_CARTONLINES (NOLOCK), ORDERDETAIL (NOLOCK)
	WHERE	OP_CARTONLINES.CartonBatch = @c_cartonbatch AND 
		OP_CARTONLINES.Orderkey = @c_currentorder AND
		OP_CARTONLINES.Orderkey = ORDERDETAIL.Orderkey AND
		OP_CARTONLINES.OrderLinenumber = ORDERDETAIL.OrderLinenumber AND
		ORDERDETAIL.Flag1 = 'Y'
	EXECUTE nspg_getkey
		'TransmitLog', 10, @c_TransmitLogKey OUTPUT, @b_success OUTPUT, @n_err OUTPUT, @c_errmsg OUTPUT, 0, @n_nopicks
	WHILE (1=1)
	BEGIN
		SET ROWCOUNT 1
		SELECT 	@c_pickkey = OP_CARTONLINES.PickDetailKey 
		FROM	OP_CARTONLINES (NOLOCK), ORDERDETAIL (NOLOCK)
		WHERE	OP_CARTONLINES.CartonBatch = @c_cartonbatch AND 
			OP_CARTONLINES.Orderkey = @c_currentorder AND
			OP_CARTONLINES.Pickdetailkey > @c_pickkey AND
			OP_CARTONLINES.Orderkey = ORDERDETAIL.Orderkey AND
			OP_CARTONLINES.OrderLinenumber = ORDERDETAIL.OrderLinenumber AND
			ORDERDETAIL.Flag1 = 'Y'
		ORDER BY OP_CARTONLINES.PickDetailkey
		IF @@ROWCOUNT = 0 BREAK
		SET ROWCOUNT 0
		INSERT TRANSMITLOG (TransmitlogKey, Tablename, Key1, TransmitFlag)
			VALUES (@c_transmitlogkey, 'ASNF', @c_pickkey, '0')
		SELECT 	@c_transmitlogkey = Right('0000000000' + Convert(char(10), Convert(int, @c_transmitlogkey) + 1), 10)
	END
	SET ROWCOUNT 0
END
/* Delete the order just processed from the OP_CARTONLINES table */
IF @n_continue = 1 or @n_continue = 2
BEGIN
DELETE FROM OP_CARTONLINES WHERE Cartonbatch = @c_cartonbatch AND ORDERKEY = @c_currentorder
SELECT @n_err = @@ERROR, @n_cnt = @@ROWCOUNT
IF @n_err <> 0
BEGIN
SELECT @n_continue = 3 
/* Trap SQL Server Error */
SELECT @c_errmsg = CONVERT(char(250),@n_err), @n_err = 63525   -- Should Be Set To The SQL Errmessage but I don't know how to do so.                              
SELECT @c_errmsg='NSQL'+CONVERT(char(5),@n_err)+': Delete From live op_cartonlines failed.  Preallocated QTY Needs to be Manually Adjusted! (nspOrderProcessing)' + ' ( ' + ' SQLSvr MESSAGE=' + LTRIM(RTRIM(@c_errmsg)) + ' ) '
/* End Trap SQL Server Error */
END                               
END
/* End Delete the order just processed from the OP_CARTONLINES table */     
IF @n_continue = 1 or @n_continue = 2
BEGIN
COMMIT TRAN 
END 
ELSE
BEGIN
ROLLBACK TRAN 
END         
END 
/* While 1=1 by OrderKey*/               
SET ROWCOUNT 0
END
/* End Insert Into Live Pick Files - Final Post One Order At A Time*/
/* End Main Processing */
/* Post Process Starts */
/* #INCLUDE <SPOP2.SQL> */
/* Post Process Ends */
/* Return Statement */
IF @n_continue=3  -- Error Occured - Process And Return
BEGIN
SELECT @b_success = 0
IF @@TRANCOUNT = 1 and @@TRANCOUNT > @n_starttcnt 
BEGIN
ROLLBACK TRAN
END     
ELSE

BEGIN
WHILE @@TRANCOUNT > @n_starttcnt BEGIN
COMMIT TRAN
END          
END          
execute nsp_logerror @n_err, @c_errmsg, 'nspOrderProcessing'
RAISERROR @n_err @c_errmsg
RETURN
END
ELSE
BEGIN
/* Error Did Not Occur , Return Normally */
SELECT @b_success = 1
WHILE @@TRANCOUNT > @n_starttcnt 
BEGIN

COMMIT TRAN
END
RETURN
END
/* End Return Statement */          
/*************************************************/   
/* Subprocedure for updating inventory           */
/*************************************************/
UPDATEINV:     
/* DS: Transaction handling moved closer to the insert */
SELECT @b_pickupdatesuccess = 1                    
IF @b_pickupdatesuccess = 1
BEGIN
/* Figure out what the pickmethod is based on the location */
SELECT  @c_uom1pickmethod = uom1pickmethod, -- case
@c_uom2pickmethod = uom2pickmethod, -- innerpack
@c_uom3pickmethod = uom3pickmethod, -- piece
@c_uom4pickmethod = uom4pickmethod, -- pallet
@c_uom5pickmethod = uom5pickmethod, -- other 1
@c_uom6pickmethod = uom6pickmethod ,-- other 2
@c_uom7pickmethod = uom3pickmethod -- Yes,this statement is correct, UOM7 is a special case
FROM LOC (nolock), PUTAWAYZONE (nolock)
WHERE LOC.Putawayzone = PUtawayzone.Putawayzone
AND LOC.LOC = @c_cloc
SELECT @c_Apickmethod = 
CASE @c_Auom
WHEN '1' THEN @c_uom4pickmethod -- Full Pallets
WHEN '2' THEN @c_uom1pickmethod -- Full Case
WHEN '3' THEN @c_uom2pickmethod -- Inner
WHEN '4' THEN @c_uom5pickmethod -- Other 1
WHEN '5' THEN @c_uom6pickmethod -- Other 2 (uses the same pickmethod as other1)
WHEN '6' THEN @c_uom3pickmethod -- Piece
WHEN '7' THEN @c_uom3pickmethod -- Piece
ELSE '0'
END
/* End Figure out what the pickmethod is based on the location */
/* If the pulltype is not a 6 and the pulltype is not a 7 *//* Then create @n_uomqty records in the pickdetail table */
IF (@c_Auom = '6' or @c_Auom = '7')
BEGIN
/* Piece picks only */
SELECT @n_qtytoinsert = @n_qtytotake
SELECT @n_uomqtytoinsert = @n_uomqty
END
ELSE
BEGIN
/* Bulk Picks Only */
SELECT @n_qtytoinsert = @n_qtytotake/@n_uomqty
SELECT @n_uomqtytoinsert = 1
END     
SELECT @n_pickrecscreated = 0
WHILE @n_pickrecscreated < @n_uomqty and @b_pickupdatesuccess = 1
BEGIN
/*   Get the pickdetail key    */
IF @b_pickupdatesuccess = 1
BEGIN SELECT @b_success = 0               
EXECUTE   nspg_getkey 
'PickDetailKey', 10, @c_PickDetailKey OUTPUT, @b_success OUTPUT, @n_err OUTPUT, @c_errmsg OUTPUT
END                    
/* End Get The PickDetail Key  */
/* Create A PICKDETAIL Records In The PICKDETAIL Table */
IF @b_success = 1
BEGIN               
BEGIN TRANSACTION TROUTERLOOP
INSERT #OPPICKDETAIL (PickDetailKey,PickHeaderKey,OrderKey,OrderLineNumber,
     Lot,Storerkey,Sku,Qty,Loc,Id,UOMQty, 
     UOM, CaseID, PackKey, CartonGroup, docartonize,doreplenish,replenishzone,PickMethod,PalletID,DNnumber)
VALUES 
  (@c_PickDetailKey,'',@c_Aorderkey,@c_Aorderlinenumber,
     @c_Alot,@c_Astorerkey,@c_Asku,@n_qtytoinsert,@c_cloc,@c_cid,@n_uomqtytoinsert,
     @c_Auom,'', @c_Apackkey,@c_ACartonGroup, @c_Adocartonize,'N','',@c_Apickmethod,'','')
SELECT @n_err = @@ERROR, @n_cnt = @@ROWCOUNT
IF not (@n_err = 0 AND @n_cnt = 1)
BEGIN
SELECT @b_pickupdatesuccess = 0
END
/* Update the pickdetail table */
/* DS: Modified insert to use the values instead of selecting from #OPPICKDETAIL */
/*      because that record is just inserted using the same values*/
IF @b_pickupdatesuccess = 1
BEGIN
INSERT PICKDETAIL (PickDetailKey,PickHeaderKey,OrderKey,OrderLineNumber,
Lot,Storerkey,Sku,Qty,Loc,Id,UOMQty, 
UOM, CaseID, PackKey, CartonGroup, DoReplenish, replenishzone, 
docartonize,Trafficcop,PickMethod,PalletId,DNnumber,wavekey)
VALUES ( @c_PickDetailKey,'N'+@c_oprun,@c_Aorderkey,@c_Aorderlinenumber,
@c_Alot,@c_Astorerkey,@c_Asku,@n_qtytoinsert,@c_cloc,@c_cid,@n_uomqtytoinsert,
@c_Auom,'C'+@c_oprun, @c_Apackkey,@c_ACartonGroup, 'N', '', 
@c_Adocartonize, 'U', @c_Apickmethod,'','',@c_oskey)
SELECT @n_err = @@ERROR, @n_cnt_sql = @@ROWCOUNT
/* Check to make sure row got placed into table.  Cannot use  */
/* @@ROWCOUNT because it seems to be unreliable in 6.5        */
SELECT @n_cnt = COUNT(*) FROM PICKDETAIL WHERE PICKDETAILKEY = @c_pickdetailkey 
if (@b_debug = 1 or @b_debug = 2) and (@n_cnt_sql <> @n_cnt)
begin
print 'INSERT PickDetail @@ROWCOUNT gets wrong'
select '@@ROWCOUNT' = @n_cnt_sql, 'COUNT(*)' = @n_cnt
end                                                 
IF not (@n_err = 0 AND @n_cnt = 1)
BEGIN                              
SELECT @b_pickupdatesuccess = 0
END
IF @b_pickupdatesuccess = 1
BEGIN
/* Everyting OK - Commit */
SELECT @n_Aqtylefttofulfill = @n_Aqtylefttofulfill - @n_qtytoinsert
COMMIT TRAN TROUTERLOOP
IF (@b_debug = 1 or @b_debug = 2)
BEGIN
SELECT 'Inserted PickDetailKey'=@c_PickDetailKey, 
'@n_qtytoinsert'=@n_qtytoinsert, '@n_Aqtylefttofulfill'=@n_Aqtylefttofulfill
END
END
ELSE
BEGIN
ROLLBACK TRAN TROUTERLOOP                                   
--SELECT @n_err = 0
IF (@b_debug = 1 or @b_debug = 2)
BEGIN
PRINT 'TRAN TROUTERLOOP ROLLBACKed'
END
BREAK
END
END
/* End update the pickdetail table now */                         
END
ELSE
BEGIN
SELECT @b_pickupdatesuccess = 0                    
END  -- IF @b_sucess = 1
SELECT @n_pickrecscreated = @n_pickrecscreated + 1
/* Must only do this loop once if piecepicks */
/* Otherwise we'll get one record in the pickdetail */
/* table for each piece and thats a no-no */
IF @c_Auom = '6' or @c_Auom = '7'
BEGIN
BREAK
END
END -- While @n_pickrecscreated < @n_uomqty 
/* Override Include Statements Here */
/* #INCLUDE <SPOP6.SQL> */
/* End Override Include Statements Here */                                        
END 
IF @n_jumpsource = 1

BEGIN
GOTO RETURNFROMUPDATEINV_01     
END
IF @n_jumpsource = 2
BEGIN
GOTO RETURNFROMUPDATEINV_02
END
/*
IF @n_jumpsource = 3
BEGIN
GOTO RETURNFROMUPDATEINV_03
END
*/
/***************END OF UPDATEINV******************/
END



