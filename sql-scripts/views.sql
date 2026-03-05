CREATE OR ALTER VIEW v_DealsEnriched AS
WITH ActivityStats AS (
    SELECT
        DealID,
        COUNT(CASE WHEN ActivityType = 'Call' THEN 1 END) AS CallsCount,
        COUNT(CASE WHEN ActivityType = 'Demo' THEN 1 END) AS DemosCount,
        COUNT(CASE WHEN ActivityType = 'Email' THEN 1 END) AS EmailsCount,
        COUNT(CASE WHEN ActivityType = 'Meeting' THEN 1 END) AS MeetingsCount,
        COUNT(CASE WHEN ActivityType = 'Workshop' THEN 1 END) AS WorkshopsCount,
        SUM(DurationMinutes) AS TotalDurationMinutes
    FROM FactActivities a
    GROUP BY DealID
)
SELECT
    f.DealID, f.CompanyID, f.RepID,
    f.CreatedDateKey, f.LastActivityDateKey,
    CASE
        WHEN f.Status = 'Open' THEN DATEDIFF(day, d_start.Date, '2026-02-28')
        ELSE DATEDIFF(day, d_start.Date, d_last.Date) + 1
    END AS DaysInPipeline,
    f.StageName, f.StageOrder, f.Status,
    DATEDIFF(day, d_last.Date, '2026-02-28') AS DaysSinceLastActivity,
    CASE
        WHEN Status != 'Open' THEN 'Closed'
        WHEN DATEDIFF(day, d_last.Date, '2026-02-28') <= 30 THEN 'Active'
        WHEN DATEDIFF(day, d_last.Date, '2026-02-28') <= 60 THEN 'At Risk'
        WHEN DATEDIFF(day, d_last.Date, '2026-02-28') > 60 THEN 'Ghost'
    END AS DealHealthStatus,
    CAST(ROUND(f.BaseWinProbability, 2) AS DECIMAL(3,2)) AS BaseWinProbability,
    CAST(ROUND(f.AdjustedWinProbability, 2) AS DECIMAL(3,2)) AS AdjustedWinProbability,
    CASE
        WHEN f.BaseWinProbability <= 0.2 THEN 'Low'
        WHEN f.BaseWinProbability <= 0.3 THEN 'Medium'
        ELSE 'High'
    END AS BaseProbabilityCategory,
    CASE
        WHEN f.AdjustedWinProbability <= 0.3 THEN 'Low'
        WHEN f.AdjustedWinProbability <= 0.55 THEN 'Medium'
        ELSE 'High'
    END AS AdjustedProbabilityCategory,
    f.DealValueEUR,
    CAST(f.DealValueEUR * f.AdjustedWinProbability AS DECIMAL(12,2)) AS WeightedDealValue,
    CASE
        WHEN DealValueEUR < 15000 THEN 'Small'
        WHEN DealValueEUR BETWEEN 15000 AND 75000 THEN 'Medium'
        ELSE 'Large'
    END AS DealValueCategory,
    f.ProductCategory,
    COALESCE(a.CallsCount + a.DemosCount + a.EmailsCount +
         a.MeetingsCount + a.WorkshopsCount, 0) AS TotalActivities,
    COALESCE(a.EmailsCount, 0) as Emails,
    COALESCE(a.CallsCount, 0) as Calls,
    COALESCE(a.MeetingsCount, 0) as Meetings,
    COALESCE(a.DemosCount, 0) as Demos,
    COALESCE(a.WorkshopsCount, 0) as Workshops,
    COALESCE(a.TotalDurationMinutes, 0) as TotalDuration
FROM FactDeals f
JOIN DimDate d_start      ON f.CreatedDateKey = d_start.DateKey
JOIN DimDate d_last       ON f.LastActivityDateKey = d_last.DateKey
LEFT JOIN ActivityStats a ON f.DealID = a.DealID;
GO


CREATE OR AlTER VIEW v_OBT AS
SELECT
    -- Deal identifiers
    f.DealID, f.Status, f.StageName, f.StageOrder, f.DealHealthStatus,
    -- Dates
    d_start.Date AS CreatedDate,
    d_last.Date AS LastActivityDate,
    -- Deal metrics
    f.DealValueEUR, f.WeightedDealValue,
    f.BaseWinProbability, f.AdjustedWinProbability,
    f.DaysInPipeline, f.DaysSinceLastActivity,
    -- Company
    c.CompanyName, c.CompanySize, c.Industry, c.Region AS CompanyRegion,
    c.Country AS CompanyCountry, c.EmployeeCount, c.AnnualRevenueEUR,
    -- Rep
    r.RepName, r.Role, r.Seniority, r.Region as RepRegion,
    r.JoinYear, r.LeaveYear,
    COALESCE(r.LeaveYear, 2026) - r.JoinYear AS TenureYears,
    -- Product
    f.ProductCategory,
    -- Activity
    f.TotalActivities, f.TotalDuration,
    f.Emails, f.Calls, f.Meetings, f.Demos, f.Workshops
FROM v_DealsEnriched f
LEFT JOIN DimSalesRep r ON f.RepID = r.RepID
LEFT JOIN DimCompany c ON f.CompanyID = c.CompanyID
LEFT JOIN DimDate d_start ON f.CreatedDateKey = d_start.DateKey
LEFT JOIN DimDate d_last ON f.LastActivityDateKey = d_last.DateKey;
GO