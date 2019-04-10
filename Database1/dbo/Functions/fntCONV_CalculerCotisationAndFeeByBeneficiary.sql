
CREATE FUNCTION [dbo].[fntCONV_CalculerCotisationAndFeeByBeneficiary] (
    @AsDate DATE = NULL,
    @BeneficiaryID INT = NULL
)
RETURNS TABLE
AS RETURN
(
    SELECT 
        C.BeneficiaryID, U.UnitID, 
        TotalCotisation = sum(ct.Cotisation), 
        TotalFee = sum(ct.Fee)
    FROM
        dbo.Un_Convention C
        JOIN dbo.Un_Unit U ON C.ConventionID= U.ConventionID
        JOIN dbo.Un_Cotisation CT ON U.UnitID = CT.UnitID
        JOIN dbo.Un_Oper O ON CT.OperID = O.OperID
        LEFT JOIN dbo.Un_OperCancelation OC ON OC.OperID = O.OperID
        LEFT JOIN dbo.Un_OperCancelation OCS ON OCS.OperSourceID = O.OperID
    WHERE
        C.BeneficiaryID = IsNull(@BeneficiaryID, C.BeneficiaryID)
        AND O.OperDate <= IsNull(@AsDate, GetDate())
        AND OC.OperID IS NULL
        AND OCS.OperID IS NULL
    GROUP by
        C.BeneficiaryID, U.UnitID
)
