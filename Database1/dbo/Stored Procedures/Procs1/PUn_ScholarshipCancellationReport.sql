/*  *************************************************************
    *     _____                                _           _    *
    *    |  __ \                              | |         | |   *
    *    | |  | | ___ _ __  _ __ ___  ___ __ _| |_ ___  __| |   *
    *    | |  | |/ _ \ '_ \| '__/ _ \/ __/ _` | __/ _ \/ _` |   *
    *    | |__| |  __/ |_) | | |  __/ (_| (_| | ||  __/ (_| |   *
    *    |_____/ \___| .__/|_|  \___|\___\__,_|\__\___|\__,_|   *
    *                | |                                        *
    *                |_|                                        *
    ******************** D E P R E C A T E D ********************   */

/*
    2017-09-27  Pierre-Luc Simard   Deprecated - Cette procédure n'est plus utilisée

-- Optimisé version 26
*/
CREATE PROCEDURE [dbo].[PUn_ScholarshipCancellationReport] (
@ConnectID MoID)
AS
BEGIN

    SELECT 1/0
/*
  SELECT
    P.PlanDesc AS PlanDesc,
    S.ScholarshipNo,
    C.ConventionNo AS ConventionNo,
    RTRIM(SH.LastName) + ', ' + RTRIM(SH.FirstName) AS SubscriberName,
    RTRIM(BH.LastName) + ', ' + RTRIM(BH.FirstName) AS BeneficiaryName,
    CASE S.ScholarshipStatusID
      WHEN 'DEA' THEN 'Décès'
      WHEN 'REN' THEN 'Renonciation'
      WHEN '25Y' THEN '25 ans de régime'
      WHEN '24Y' THEN '24 ans d''age'
      END AS ScholarshipStatusDesc,
    U.UnitQty
  FROM dbo.Mo_Human BH
  JOIN dbo.Un_Convention C ON (C.BeneficiaryID = BH.HumanID)
  JOIN Un_Plan P ON (P.PlanID = C.PlanID)
  JOIN (

    SELECT
      MIN(C.ConventionID) AS ConventionID,
      SUM(U.UnitQty) AS UnitQty
    FROM dbo.Un_Convention C
    JOIN dbo.Un_Unit U ON (U.ConventionID = C.ConventionID)
    GROUP BY C.ConventionID

 ) U ON (U.ConventionID = C.ConventionID)

  JOIN dbo.Mo_Human SH ON (SH.HumanID = C.SubscriberID)
  JOIN Un_Scholarship S ON (S.ConventionID = C.ConventionID)
  WHERE S.ScholarshipStatusID IN ('REN','25Y','24Y','DEA')
  AND (S.YearDeleted = 0)
  ORDER BY
    P.PlanDesc,
    S.ScholarshipNo,
    SH.LastName,
    SH.FirstName,
    BH.LastName,
    BH.FirstName
*/
END;