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
CREATE PROCEDURE [dbo].[PUn_ScholarshipManualImportReport] (
@ConnectID MoID)
AS
BEGIN
    
    SELECT 1/0
    /*
  SELECT
    CASE C.ScholarshipEntryID
      WHEN 'G' THEN RTRIM(P.PlanDesc) + ', Importation de génie - Bourse ' + CAST(S.ScholarshipNo AS VARCHAR)
      WHEN 'R' THEN RTRIM(P.PlanDesc) + ', Remise en vigueur - Bourse ' + CAST(S.ScholarshipNo AS VARCHAR)
      ELSE 'Type d''entrée inconnue'
    END AS ScholarshipEntryDesc,
    C.ConventionNo AS ConventionNo,
    RTRIM(SH.LastName) + ', ' + RTRIM(SH.FirstName) AS SubscriberName,
    RTRIM(BH.LastName) + ', ' + RTRIM(BH.FirstName) AS BeneficiaryName,
    U.UnitQty
  FROM dbo.Mo_Human BH
  JOIN dbo.Un_Convention C ON (C.BeneficiaryID = BH.HumanID)
  JOIN Un_Scholarship S ON (S.ConventionID = C.ConventionID) AND (S.ScholarshipStatusID IN ('RES','ADM','WAI','TPA'))
  JOIN Un_Plan P ON (P.PlanID = C.PlanID)
  JOIN VUn_UnitByConvention U ON (U.ConventionID = C.ConventionID)
  JOIN dbo.Mo_Human SH ON (SH.HumanID = C.SubscriberID)
  WHERE C.ScholarshipYear = (SELECT ScholarshipYear FROM Un_Def)
  AND C.ScholarshipEntryID IN ('R','G')
  ORDER BY
    P.PlanDesc,
    C.ScholarshipEntryID,
    S.ScholarshipNo,
    C.ConventionNo
    */
END;