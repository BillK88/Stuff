--FV = PV(1 + i)^n
--FV = Future value
--PV = Present Value (PurchasePrice or CommissioningCost)
--i = Interest Rate
--n = number of Years
Begin
 Declare @iRate decimal(5,2) = 0.03

select GIS_Object, EntityUID, PurchasePrice, InstallDate, LifeExpectancy, ReplacementCost, TimeToReplace
,Case When TimeToReplace > -1 Then PurchasePrice * Power(1 + @iRate,TimeToReplace) Else PurchasePrice End FV
,Case When TimeToReplace > -1 Then PurchasePrice * Power(1 + @iRate,TimeToReplace) Else PurchasePrice End - ReplacementCost ExcessCost
from (
select GIS_Object, EntityUID, PurchasePrice, InstallDate, EndOfLifeDate, LifeExpectancy, ReplacementCost
,IsNull(DatePart(year,IsNull(EndOfLifeDate,dateAdd(year,LifeExpectancy,case when Cast(InstallDate as date) < '01/01/9999' Then InstallDate End)) ) - DatePart(year,GetDate() ), 999999 )TimeToReplace
from pgis.pgis.EAMGlobalAttributes
where PurchasePrice > 0
and InstallDate is not null
and LifeExpectancy > 0
) X
End
--==============================================================================================
--==============================================================================================
--Next 10 Years of Replacement Costs
select GIS_Object, OwnedBy, MaintainedBy, Sum(CntAssets) TotalAsets
,Sum(TotalCond) / Sum(CntCCR) AvgCond
,Sum(TotalBRE) / Sum(CntBRE) AvgBRE
, Format(Sum(TotalReplaceCost),'C0') TotalReplaceCost
,Format(Sum(Case When TimeToReplace < 0 Then TotalReplaceCost End ),'C0') ReplAssetsOverdue, Sum(Case When TimeToReplace < 0 Then CntAssets End ) ReplAssetsOverdue
,Format(Sum(Case TimeToReplace When 0 Then TotalReplaceCost End ),'C0') ReplCostYearNow, Sum(Case TimeToReplace When 0 Then CntAssets End )ReplAssetsYearNow
,Format(Sum(Case TimeToReplace When 1 Then TotalReplaceCost End ),'C0') ReplCostYear1, Sum(Case TimeToReplace When 1 Then CntAssets End )ReplAssetsYear1
,Format(Sum(Case TimeToReplace When 2 Then TotalReplaceCost End),'C0') ReplCostYear2, Sum(Case TimeToReplace When 2 Then CntAssets End) ReplAssetsYear2
,Format(Sum(Case TimeToReplace When 3 Then TotalReplaceCost End),'C0') ReplCostYear3, Sum(Case TimeToReplace When 3 Then CntAssets End) ReplAssetsYear3
,Format(Sum(Case TimeToReplace When 4 Then TotalReplaceCost End),'C0') ReplCostYear4, Sum(Case TimeToReplace When 4 Then CntAssets End) ReplAssetsYear4
,Format(Sum(Case TimeToReplace When 5 Then TotalReplaceCost End),'C0') ReplCostYear5, Sum(Case TimeToReplace When 5 Then CntAssets End) ReplAssetsYear5
,Format(Sum(Case TimeToReplace When 6 Then TotalReplaceCost End),'C0') ReplCostYear6, Sum(Case TimeToReplace When 6 Then CntAssets End) ReplAssetsYear6
,Format(Sum(Case TimeToReplace When 7 Then TotalReplaceCost End),'C0') ReplCostYear7, Sum(Case TimeToReplace When 7 Then CntAssets End) ReplAssetsYear7
,Format(Sum(Case TimeToReplace When 8 Then TotalReplaceCost End),'C0') ReplCostYear8, Sum(Case TimeToReplace When 8 Then CntAssets End) ReplAssetsYear8
,Format(Sum(Case TimeToReplace When 9 Then TotalReplaceCost End),'C0') ReplCostYear9, Sum(Case TimeToReplace When 9 Then CntAssets End) ReplAssetsYear9
,Format(Sum(Case TimeToReplace When 10 Then TotalReplaceCost End),'C0') ReplCostYear10, Sum(Case TimeToReplace When 10 Then CntAssets End) ReplAssetsYear10
,Format(Sum(Case When TimeToReplace > 10 Then TotalReplaceCost End),'C0') ReplCostYear10Plus, Sum(Case When TimeToReplace > 10 Then CntAssets End) ReplAssetsYear10Plus
from (
select GIS_Object, OwnedBy, MaintainedBy, count(EntityUID) CntAssets, count(CurrentConditionRating) CntCCR, count(Criticality) CntBRE
,Sum(Convert(numeric(3,2), CurrentConditionRating)) TotalCond, 
Sum(Criticality) TotalBRE
--need to do the case on InstallDate or get an Adding a value to a 'datetime2' column caused an overflow.
,IsNull(DatePart(year,IsNull(EndOfLifeDate,dateAdd(year,LifeExpectancy,case when Cast(InstallDate as date) < '01/01/9999' Then InstallDate End)) ) - DatePart(year,GetDate() ), 999999 )TimeToReplace
,DatePart(year,IsNull(EndOfLifeDate,dateAdd(year,LifeExpectancy,case when Cast(InstallDate as date) < '01/01/9999' Then InstallDate End)) ) ReplYear
,Sum(ReplacementCost) TotalReplaceCost
from pgis.pgis.EAMGlobalAttributes
where 1 = 1
and GIS_Object like '%'
and LifeCycleStatus = 'In Service'
and EAM_Priority = 'Strategic'
group by GIS_Object, OwnedBy, MaintainedBy
--,IsNull(DatePart(year,IsNull(EndOfLifeDate,dateAdd(year,LifeExpectancy,case when Cast(InstallDate as date) < '01/01/9999' Then InstallDate End)) ) - DatePart(year,GetDate() ), 999999 )
,DatePart(year,IsNull(EndOfLifeDate,dateAdd(year,LifeExpectancy,case when Cast(InstallDate as date) < '01/01/9999' Then InstallDate End)) )
--order by 1,2,3
) X
group by GIS_Object, OwnedBy, MaintainedBy
order by 1,2,3

--==============================================================================================
--==============================================================================================
--Next 10 Years of Replacement Costs from PurchasePrice Future Value
Begin
Declare @iRate decimal(5,2) = 0.03

select GIS_Object, OwnedBy, MaintainedBy, Sum(CntAssets) TotalAsets
,Sum(TotalCond) / Sum(CntCCR) AvgCond
,Sum(TotalBRE) / Sum(CntBRE) AvgBRE
, Format(Sum(TotalPurchasePrice),'C0') TotalPurchasePricePV
--, Format(Sum(FV),'C0') TotalPurchasePriceFV
--,Format(Sum(Case When TimeToReplace < 0 Then FV End ),'C0') ReplAssetsOverdue, Sum(Case When TimeToReplace < 0 Then CntAssets End ) ReplAssetsOverdue
--,Format(Sum(Case TimeToReplace When 0 Then FV End ),'C0') ReplCostYearNow, Sum(Case TimeToReplace When 0 Then CntAssets End )ReplAssetsYearNow
--,Format(Sum(Case TimeToReplace When 1 Then FV End ),'C0') ReplCostYear1, Sum(Case TimeToReplace When 1 Then CntAssets End )ReplAssetsYear1
--,Format(Sum(Case TimeToReplace When 2 Then FV End),'C0') ReplCostYear2, Sum(Case TimeToReplace When 2 Then CntAssets End) ReplAssetsYear2
--,Format(Sum(Case TimeToReplace When 3 Then FV End),'C0') ReplCostYear3, Sum(Case TimeToReplace When 3 Then CntAssets End) ReplAssetsYear3
--,Format(Sum(Case TimeToReplace When 4 Then FV End),'C0') ReplCostYear4, Sum(Case TimeToReplace When 4 Then CntAssets End) ReplAssetsYear4
--,Format(Sum(Case TimeToReplace When 5 Then FV End),'C0') ReplCostYear5, Sum(Case TimeToReplace When 5 Then CntAssets End) ReplAssetsYear5
--,Format(Sum(Case TimeToReplace When 6 Then FV End),'C0') ReplCostYear6, Sum(Case TimeToReplace When 6 Then CntAssets End) ReplAssetsYear6
--,Format(Sum(Case TimeToReplace When 7 Then FV End),'C0') ReplCostYear7, Sum(Case TimeToReplace When 7 Then CntAssets End) ReplAssetsYear7
--,Format(Sum(Case TimeToReplace When 8 Then FV End),'C0') ReplCostYear8, Sum(Case TimeToReplace When 8 Then CntAssets End) ReplAssetsYear8
--,Format(Sum(Case TimeToReplace When 9 Then FV End),'C0') ReplCostYear9, Sum(Case TimeToReplace When 9 Then CntAssets End) ReplAssetsYear9
--,Format(Sum(Case TimeToReplace When 10 Then FV End),'C0') ReplCostYear10, Sum(Case TimeToReplace When 10 Then CntAssets End) ReplAssetsYear10
--,Format(Sum(Case When TimeToReplace > 10 Then FV End),'C0') ReplCostYear10Plus, Sum(Case When TimeToReplace > 10 Then CntAssets End) ReplAssetsYear10Plus
from (
select GIS_Object, OwnedBy, MaintainedBy, CntAssets, CntCCR, CntBRE, TotalCond, TotalBRE, TimeToReplace, ReplYear, TotalPurchasePrice
,Case When TimeToReplace > -1 Then TotalPurchasePrice * Power(1 + 0.03,TimeToReplace) Else TotalPurchasePrice End FV
from (
select GIS_Object, OwnedBy, MaintainedBy, count(EntityUID) CntAssets, count(CurrentConditionRating) CntCCR, count(Criticality) CntBRE
,Sum(Convert(numeric(3,2), CurrentConditionRating)) TotalCond, 
Sum(Criticality) TotalBRE
--need to do the case on InstallDate or get an Adding a value to a 'datetime2' column caused an overflow.
,IsNull(DatePart(year,IsNull(EndOfLifeDate,dateAdd(year,LifeExpectancy,case when Cast(InstallDate as date) < '01/01/9999' Then InstallDate End)) ) - DatePart(year,GetDate() ), 999999 )TimeToReplace
,DatePart(year,IsNull(EndOfLifeDate,dateAdd(year,LifeExpectancy,case when Cast(InstallDate as date) < '01/01/9999' Then InstallDate End)) ) ReplYear
,Sum(PurchasePrice) TotalPurchasePrice
from pgis.pgis.EAMGlobalAttributes
where 1 = 1
and GIS_Object like '%'
and LifeCycleStatus = 'In Service'
and EAM_Priority = 'Strategic'
group by GIS_Object, OwnedBy, MaintainedBy
--,IsNull(DatePart(year,IsNull(EndOfLifeDate,dateAdd(year,LifeExpectancy,case when Cast(InstallDate as date) < '01/01/9999' Then InstallDate End)) ) - DatePart(year,GetDate() ), 999999 )
,DatePart(year,IsNull(EndOfLifeDate,dateAdd(year,LifeExpectancy,case when Cast(InstallDate as date) < '01/01/9999' Then InstallDate End)) )
--order by 1,2,3
) X
) Y
group by GIS_Object, OwnedBy, MaintainedBy
order by 1,2,3

End
--==============================================================================================

select EntityUID, CurrentConditionRating
from pgis.pgis.EAMGlobalAttributes
where GIS_Object = 'Actuator'

select EntityUID, criticality
from pgis.pgis.EAMGlobalAttributes
where GIS_Object = 'Actuator'

select count(ReplacementCost), count(*)
from pgis.pgis.EAMGlobalAttributes

select count(EndOfLifeDate), count(*)
from pgis.pgis.EAMGlobalAttributes

select count(InstallDate), count(LifeExpectancy), count(*)
from pgis.pgis.EAMGlobalAttributes

select GIS_Object, EntityUID, MaintainedBy, LifeCycleStatus, CurrentConditionRating, Criticality
, InstallDate, EndOfLifeDate, LifeExpectancy, ReplacementCost, RemainingUseFulLife, PctRemainingUseFulLife
from pgis.pgis.EAMGlobalAttributes
where GIS_Object like 'SWGravityMain'

select GIS_Object, EntityUID, OwnedBy, MaintainedBy, LifeCycleStatus, CurrentConditionRating, Criticality
, InstallDate
, EndOfLifeDate
,dateAdd(year,LifeExpectancy,InstallDate) CalcEOL
,IsNull(EndOfLifeDate,dateAdd(year,LifeExpectancy,InstallDate)) EOLDate
,DatePart(month,IsNull(EndOfLifeDate,dateAdd(year,LifeExpectancy,InstallDate)) ) EOLMonth
,DatePart(year,IsNull(EndOfLifeDate,dateAdd(year,LifeExpectancy,InstallDate)) ) EOLYear
, LifeExpectancy, ReplacementCost, RemainingUseFulLife, PctRemainingUseFulLife
from pgis.pgis.EAMGlobalAttributes
where GIS_Object like 'SWGravityMain'
and LifeCycleStatus = 'In Service'

select GIS_Object, OwnedBy, MaintainedBy, count(EntityUID) CntAssets, Avg(CurrentConditionRating) AvgCondition, Avg(Criticality) AvgBRE
,DatePart(month,IsNull(EndOfLifeDate,dateAdd(year,LifeExpectancy,InstallDate)) ) EOLMonth
,DatePart(year,IsNull(EndOfLifeDate,dateAdd(year,LifeExpectancy,InstallDate)) ) EOLYear
,Sum(ReplacementCost) TotalReplaceCost
from pgis.pgis.EAMGlobalAttributes
where GIS_Object like 'SWGravityMain'
and LifeCycleStatus = 'In Service'
group by GIS_Object, OwnedBy, MaintainedBy
,DatePart(month,IsNull(EndOfLifeDate,dateAdd(year,LifeExpectancy,InstallDate)) )
,DatePart(year,IsNull(EndOfLifeDate,dateAdd(year,LifeExpectancy,InstallDate)) )
order by 1,2,3

select GIS_Object, OwnedBy, MaintainedBy, count(EntityUID) CntAssets, Avg(Convert(numeric(3,2), CurrentConditionRating)) AvgCondition, Avg(Criticality) AvgBRE
,DatePart(year,IsNull(EndOfLifeDate,dateAdd(year,LifeExpectancy,InstallDate)) ) - DatePart(year,GetDate() ) TimeToReplace
,DatePart(year,IsNull(EndOfLifeDate,dateAdd(year,LifeExpectancy,InstallDate)) ) ReplYear
,Sum(ReplacementCost) TotalReplaceCost
from pgis.pgis.EAMGlobalAttributes
where GIS_Object like 'SW%'
and LifeCycleStatus = 'In Service'
--and EAM_Priority = 'Strategic'
group by GIS_Object, OwnedBy, MaintainedBy
,DatePart(year,IsNull(EndOfLifeDate,dateAdd(year,LifeExpectancy,InstallDate)) )
order by 1,2,3

select GIS_Object, OwnedBy, MaintainedBy, LifeExpectancy, InstallDate, EndOfLifeDate
,DatePart(year,IsNull(EndOfLifeDate,dateAdd(year,LifeExpectancy,case when Cast(InstallDate as date) < '01/01/9999' Then InstallDate End)) ) - DatePart(year,GetDate() ) TimeToReplace
--,DatePart(year, IsNull(EndOfLifeDate, dateAdd(year, LifeExpectancy, Cast(InstallDate as datetime2))) ) - DatePart(year,GetDate() ) TimeToReplace
--,DatePart(year,IsNull(EndOfLifeDate,dateAdd(year,LifeExpectancy,GetDate() )) ) ReplYear
,dateAdd(year,1, case when Cast(InstallDate as date) < '01/01/2023' Then InstallDate End) ReplYear
,DatePart(year,IsNull(EndOfLifeDate,dateAdd(year,LifeExpectancy, case when Cast(InstallDate as date) < '01/01/9999' Then InstallDate End)) ) ReplYear
from pgis.pgis.EAMGlobalAttributes
where GIS_Object like '%'
and EAM_Priority = 'Strategic'
and LifeCycleStatus = 'In Service'
and InstallDate is not null
and Cast(InstallDate as date) > '01/01/1975'
and Cast(InstallDate as date) < '01/01/2023'
and LifeExpectancy is not null
--group by GIS_Object, OwnedBy, MaintainedBy, LifeExpectancy, InstallDate, EndOfLifeDate
--,DatePart(year,IsNull(EndOfLifeDate,dateAdd(year, LifeExpectancy ,InstallDate)) )
order by 1,2,3

select count(*)
from pgis.pgis.EAMGlobalAttributes
where GIS_Object like 'SW%'
--and EAM_Priority = 'Strategic'

SELECT DATEADD(YY,-300,cast(getdate() as datetime2))

--==============================================================================================

--select GIS_Object, OwnedBy, MaintainedBy
--from pgis.pgis.EAMGlobalAttributes
--where 1 = 1
--and LifeCycleStatus = 'In Service'
--and EAM_Priority = 'Strategic'
--group by GIS_Object, OwnedBy, MaintainedBy

