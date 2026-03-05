SELECT
--     COUNT(*)
    dealID, Status, StageName,DealHealthStatus, CreatedDateKey, LastActivityDateKey,
    DaysInPipeline, DaysSinceLastActivity, TotalActivities,
    Emails, Calls, Meetings, Demos, Workshops, TotalDuration
FROM v_DealsEnriched
WHERE Status = 'Open'
      AND DealHealthStatus <> 'Ghost'
      AND DaysInPipeline >= 80
      AND TotalActivities <= 5
      AND StageOrder <=3;

DELETE FROM FactDeals
WHERE DealID IN (SELECT DealID
                 FROM v_DealsEnriched
                 WHERE Status='Open'
                 AND DealHealthStatus <> 'Ghost'
                 AND DaysInPipeline >= 80
                 AND TotalActivities <= 5
                 AND StageOrder <=3);

DELETE FROM FactActivities
WHERE DealID IN (SELECT DealID
                 FROM v_DealsEnriched
                 WHERE Status='Open'
                 AND DealHealthStatus <> 'Ghost'
                 AND DaysInPipeline >= 80
                 AND TotalActivities <= 5
                 AND StageOrder <=3);



SELECT DealID
FROM v_DealsEnriched
JOIN DimSalesRep ON v_DealsEnriched.RepID = DimSalesRep.RepID
WHERE LeaveYear IS NOT NULL AND Status = 'Open';

DELETE FROM FactDeals
WHERE DealID IN (SELECT DealID
                 FROM v_DealsEnriched
                 JOIN DimSalesRep ON v_DealsEnriched.RepID = DimSalesRep.RepID
                 WHERE LeaveYear IS NOT NULL AND Status = 'Open');

DELETE FROM FactActivities
WHERE DealID IN (SELECT DealID
                 FROM v_DealsEnriched
                 JOIN DimSalesRep ON v_DealsEnriched.RepID = DimSalesRep.RepID
                 WHERE LeaveYear IS NOT NULL AND Status = 'Open');


SELECT count(*)
FROM v_DealsEnriched
WHERE Status = 'Won'
    and Demos > 0
    AND StageOrder >= 4
