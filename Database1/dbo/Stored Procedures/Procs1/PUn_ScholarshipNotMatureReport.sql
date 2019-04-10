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
CREATE PROCEDURE [dbo].[PUn_ScholarshipNotMatureReport] (
@ConnectID MoID)
AS
BEGIN

    SELECT 1/0
    /*
  SELECT 
    C.ConventionNo AS ConventionNo,
    P.PlanDesc AS PlanDesc,
    C.ScholarshipYear AS ScholarshipYear, 
    RTRIM(BH.LastName) + ', ' + RTRIM(BH.FirstName) AS BeneficiaryName
  FROM dbo.Mo_Human BH
  JOIN dbo.Un_Convention C ON (C.BeneficiaryID = BH.HumanID)
  JOIN dbo.Un_Unit U ON (U.ConventionID = C.ConventionID)
  JOIN Un_Plan P ON (P.PlanID = C.PlanID)
  WHERE (U.IntReimbDate IS NULL)
  AND (C.ScholarshipYear > 0)
  ORDER BY 
    P.PlanDesc,
    C.ConventionNo
*/
END;