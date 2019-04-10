-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE FUNCTION [dbo].[fntIQEE_ExtraireNoUniteUserTable](@pTableAdresse dbo.UDT_tblAdresse READONLY)
RETURNS TABLE
AS RETURN
(
    WITH CTE_Dash as (
        SELECT
            iiD_Source, iID_Adresse, 
            NoCivique = CASE WHEN vcNoCivique Like 'CP-%-%' OR vcNoCivique Like 'CP.%-%' OR vcNoCivique Like 'CP:%-%' OR vcNoCivique Like 'CP %-%' 
                                  THEN Right(vcNoCivique, CharIndex('-', Reverse(vcNoCivique), 1) - 1)
                             WHEN vcNoCivique Like '%[0-9][A-Z]' AND Len(ISNULL(vcAppartement, '')) = 0
                                  THEN Left(vcNoCivique, Len(vcNoCivique) - 1)
                             WHEN vcNoCivique Like '[A-Z][0-9]%' AND Len(ISNULL(vcAppartement, '')) = 0 
                                  THEN SubString(vcNoCivique, 2, LEN(vcNoCivique) - 1)
                             ELSE vcNoCivique 
                        END,
            Appartement = CASE WHEN Len(ISNULL(vcAppartement, '')) <> 0 THEN vcAppartement
                               WHEN vcNoCivique Like '%[0-9][A-Z]' THEN UPPER(Right(vcNoCivique, 1))
                               WHEN vcNoCivique Like '[A-Z][0-9]%' THEN UPPER(Left(vcNoCivique, 1))
                               ELSE vcAppartement
                          END,
            NomRue = CASE WHEN (vcNomRue LIKE '% Case Postale %') 
                               THEN RTrim(Left(vcNomRue, CharIndex(' Case Postale ', vcNomRue, 1)))
                          WHEN (vcNomRue LIKE '% C. P.[0-9]%') OR (vcNomRue LIKE '% C. P. [0-9]%')
                               THEN RTrim(Left(vcNomRue, CharIndex(' C. P.', vcNomRue, 1)))
                          WHEN (vcNomRue LIKE '% C.P.[0-9]%') OR (vcNomRue LIKE '% C.P. [0-9]%')
                               THEN RTrim(Left(vcNomRue, CharIndex(' C.P.', vcNomRue, 1)))
                          WHEN (vcNomRue LIKE '% CP.[0-9]%') OR (vcNomRue LIKE '% CP. [0-9]%')
                               THEN RTrim(Left(vcNomRue, CharIndex(' CP.', vcNomRue, 1)))
                          WHEN (vcNomRue LIKE '% C.P[0-9]%') OR (vcNomRue LIKE '% C.P [0-9]%')
                               THEN RTrim(Left(vcNomRue, CharIndex(' C.P', vcNomRue, 1)))
                          WHEN (vcNomRue LIKE '% CP[0-9]%') OR (vcNomRue LIKE '% CP [0-9]%')
                               THEN RTrim(Left(vcNomRue, CharIndex(' CP', vcNomRue, 1)))
                          WHEN (Replace(vcNomRue, ' Box ', ' ') LIKE '% P.O.[0-9]%') OR (vcNomRue LIKE '% P.O. [0-9]%')
                               THEN RTrim(Left(vcNomRue, CharIndex(' P.O.', vcNomRue, 1)))
                          WHEN (Replace(vcNomRue, ' Box ', ' ') LIKE '% PO.[0-9]%') OR (vcNomRue LIKE '% PO. [0-9]%')
                               THEN RTrim(Left(vcNomRue, CharIndex(' PO.', vcNomRue, 1)))
                          WHEN (Replace(vcNomRue, ' Box ', ' ') LIKE '% P.O[0-9]%') OR (vcNomRue LIKE '% P.O [0-9]%')
                               THEN RTrim(Left(vcNomRue, CharIndex(' P.O', vcNomRue, 1)))
                          WHEN (Replace(vcNomRue, ' Box ', ' ') LIKE '% PO[0-9]%') OR (vcNomRue LIKE '% PO [0-9]%')
                               THEN RTrim(Left(vcNomRue, CharIndex(' PO', vcNomRue, 1)))
                          WHEN (vcNomRue LIKE '% Route Rurale %') 
                               THEN RTrim(Left(vcNomRue, CharIndex(' Route Rurale ', vcNomRue, 1)))
                          WHEN (vcNomRue LIKE '% R.R. %' OR vcNomRue LIKE '% R.R %' OR vcNomRue LIKE '% RR. %' OR vcNomRue LIKE '% RR %') 
                               THEN RTrim(Left(vcNomRue, CharIndex(' RR ', Replace(vcNomRue, '.', ''), 1)))
                          WHEN (vcNomRue LIKE '% R.R.[0-9]%') OR (vcNomRue LIKE '% R.R. [0-9]%')
                               THEN RTrim(Left(vcNomRue, CharIndex(' R.R.', vcNomRue, 1)))
                          WHEN (vcNomRue LIKE '% RR.[0-9]%') OR (vcNomRue LIKE '% RR. [0-9]%')
                               THEN RTrim(Left(vcNomRue, CharIndex(' RR.', vcNomRue, 1)))
                          WHEN (vcNomRue LIKE '% R.R[0-9]%') OR (vcNomRue LIKE '% R.R [0-9]%')
                               THEN RTrim(Left(vcNomRue, CharIndex(' R.R', vcNomRue, 1)))
                          WHEN (vcNomRue LIKE '% RR[0-9]%') OR (vcNomRue LIKE '% RR [0-9]%')
                               THEN RTrim(Left(vcNomRue, CharIndex(' RR', vcNomRue, 1)))
                          ELSE vcNomRue
                     END,
            ID_TypeBoite = CASE WHEN vcNoCivique Like 'CP-%-%' OR vcNoCivique Like 'CP.%-%' OR vcNoCivique Like 'CP:%-%' OR vcNoCivique Like 'CP %-%' OR vcNoCivique Like 'CP%-%' THEN 1
                                WHEN (vcNomRue LIKE '% Case Postale %') THEN 1
                                WHEN (vcNomRue LIKE '% C. P. [0-9]%' OR vcNomRue LIKE '% C.P. [0-9]%' OR vcNomRue LIKE '% C.P [0-9]%' OR vcNomRue LIKE '% CP. [0-9]%' OR vcNomRue LIKE '% CP [0-9]%') THEN 1
                                WHEN (vcNomRue LIKE '% C. P.[0-9]%' OR vcNomRue LIKE '% C.P.[0-9]%' OR vcNomRue LIKE '% CP.[0-9]%' OR vcNomRue LIKE '% C.P[0-9]%' OR vcNomRue LIKE '% CP[0-9]%') THEN 1
                                WHEN (Replace(vcNomRue, ' Box ', ' ') LIKE '% P. O. [0-9]%' OR Replace(vcNomRue, ' Box ', ' ') LIKE '% P.O. [0-9]%' OR Replace(vcNomRue, ' Box ', ' ') LIKE '% P.O [0-9]%' OR Replace(vcNomRue, ' Box ', ' ') LIKE '% PO. [0-9]%' OR Replace(vcNomRue, ' Box ', ' ') LIKE '% PO [0-9]%') THEN 1
                                WHEN (Replace(vcNomRue, ' Box ', ' ') LIKE '% P. O.[0-9]%' OR Replace(vcNomRue, ' Box ', ' ') LIKE '% P.O.[0-9]%' OR Replace(vcNomRue, ' Box ', ' ') LIKE '% PO.[0-9]%' OR Replace(vcNomRue, ' Box ', ' ') LIKE '% P.O[0-9]%' OR Replace(vcNomRue, ' Box ', ' ') LIKE '% PO[0-9]%') THEN 1
                                WHEN (vcNomRue LIKE '% Route Rurale %') THEN 2
                                WHEN (vcNomRue LIKE '% R.R. %' OR vcNomRue LIKE '% R.R %' OR vcNomRue LIKE '% RR. %' OR vcNomRue LIKE '% RR %') THEN 2
                                WHEN (vcNomRue LIKE '% R.R.[0-9]%' OR vcNomRue LIKE '% RR.[0-9]%' OR vcNomRue LIKE '% R.R[0-9]%') THEN 2
                                ELSE iID_TypeBoite 
                           END,
            Boite = CASE WHEN vcNoCivique Like 'CP-%-%' OR vcNoCivique Like 'CP.%-%' OR vcNoCivique Like 'CP:%-%' OR vcNoCivique Like 'CP %-%'
                              THEN SubString(vcNoCivique, 4, CharIndex('-', vcNoCivique, 4) - 4)
                         WHEN vcNoCivique Like 'CP%-%'
                              THEN SubString(vcNoCivique, 3, CharIndex('-', vcNoCivique, 3) - 3)
                         WHEN (vcNomRue LIKE '% Case Postale %') 
                              THEN LTrim(SubString(vcNomRue, CharIndex(' Case Postale', vcNomRue, 1)+13, Len(vcNomRue)))
                         WHEN (vcNomRue LIKE '% C. P.[0-9]%') OR (vcNomRue LIKE '% C. P. [0-9]%')
                              THEN LTrim(SubString(vcNomRue, CharIndex(' C. P.', vcNomRue, 1)+6, Len(vcNomRue)))
                         WHEN (vcNomRue LIKE '% C.P.[0-9]%') OR (vcNomRue LIKE '% C.P. [0-9]%')
                              THEN LTrim(SubString(vcNomRue, CharIndex(' C.P.', vcNomRue, 1)+5, Len(vcNomRue)))
                         WHEN (vcNomRue LIKE '% CP.[0-9]%') OR (vcNomRue LIKE '% CP. [0-9]%')
                              THEN LTrim(SubString(vcNomRue, CharIndex(' CP.', vcNomRue, 1)+4, Len(vcNomRue)))
                         WHEN (vcNomRue LIKE '% C.P[0-9]%') OR (vcNomRue LIKE '% C.P [0-9]%')
                              THEN LTrim(SubString(vcNomRue, CharIndex(' C.P', vcNomRue, 1)+4, Len(vcNomRue)))
                         WHEN (vcNomRue LIKE '% CP[0-9]%') OR (vcNomRue LIKE '% CP [0-9]%')
                              THEN LTrim(SubString(vcNomRue, CharIndex(' CP ', vcNomRue, 1)+3, Len(vcNomRue)))
                         WHEN (Replace(vcNomRue, ' Box ', ' ') LIKE '% P.O.[0-9]%') OR (Replace(vcNomRue, ' Box ', ' ') LIKE '% P.O. [0-9]%')
                              THEN LTrim(SubString(vcNomRue, CharIndex(' P.O.', vcNomRue, 1)+5, Len(vcNomRue)))
                         WHEN (Replace(vcNomRue, ' Box ', ' ') LIKE '% PO.[0-9]%') OR (Replace(vcNomRue, ' Box ', ' ') LIKE '% PO. [0-9]%')
                              THEN LTrim(SubString(vcNomRue, CharIndex(' PO.', vcNomRue, 1)+4, Len(vcNomRue)))
                         WHEN (Replace(vcNomRue, ' Box ', ' ') LIKE '% P.O[0-9]%') OR (Replace(vcNomRue, ' Box ', ' ') LIKE '% P.O [0-9]%')
                              THEN LTrim(SubString(vcNomRue, CharIndex(' P.O', vcNomRue, 1)+4, Len(vcNomRue)))
                         WHEN (Replace(vcNomRue, ' Box ', ' ') LIKE '% PO[0-9]%') OR (Replace(vcNomRue, ' Box ', ' ') LIKE '% PO [0-9]%')
                              THEN LTrim(SubString(vcNomRue, CharIndex(' PO ', vcNomRue, 1)+3, Len(vcNomRue)))
                         WHEN (vcNomRue LIKE '% Route Rurale %') 
                              THEN LTrim(SubString(vcNomRue, CharIndex(' Route Rurale', vcNomRue, 1)+13, Len(vcNomRue)))
                         WHEN (vcNomRue LIKE '% R.R.[0-9]%') OR (vcNomRue LIKE '% R.R. [0-9]%')
                              THEN LTrim(SubString(vcNomRue, CharIndex(' R.R.', vcNomRue, 1)+5, Len(vcNomRue)))
                         WHEN (vcNomRue LIKE '% RR.[0-9]%') OR (vcNomRue LIKE '% RR. [0-9]%')
                              THEN LTrim(SubString(vcNomRue, CharIndex(' RR.', vcNomRue, 1)+4, Len(vcNomRue)))
                         WHEN (vcNomRue LIKE '% R.R[0-9]%') OR (vcNomRue LIKE '% R.R [0-9]%')
                              THEN LTrim(SubString(vcNomRue, CharIndex(' R.R', vcNomRue, 1)+4, Len(vcNomRue)))
                         WHEN (vcNomRue LIKE '% RR[0-9]%') OR (vcNomRue LIKE '% RR [0-9]%')
                              THEN LTrim(SubString(vcNomRue, CharIndex(' RR', vcNomRue, 1)+2, Len(vcNomRue)))
                         WHEN (vcNomRue LIKE '% R.R. %' OR vcNomRue LIKE '% R.R %' OR vcNomRue LIKE '% RR. %' OR vcNomRue LIKE '% RR %') 
                              THEN LTrim(SubString(vcNomRue, CharIndex(' RR', Replace(vcNomRue, '.', ''), 1)+3, Len(vcNomRue)))
                         ELSE vcBoite
                     END,
            iDash_1 = CASE WHEN vcNoCivique Like 'CP-%-%' OR vcNoCivique Like 'CP.%-%' OR vcNoCivique Like 'CP:%-%' OR vcNoCivique Like 'CP %-%' THEN 0
                           WHEN vcNomRue Like '% APP %' OR vcNomRue Like '% APP.%' OR vcNomRue Like '% APP #%' OR vcNomRue Like '% APP-%' THEN 0
                           WHEN vcNoCivique = '-' THEN 0
                           ELSE IsNull(CharIndex('-', vcNoCivique, 1), 0)
                      END,
            iDash_2 = CASE WHEN vcNoCivique Like 'CP-%-%' OR vcNoCivique Like 'CP.%-%' OR vcNoCivique Like 'CP:%-%' OR vcNoCivique Like 'CP %-%' THEN 0
                           WHEN vcNomRue Like '% APP %' OR vcNomRue Like '% APP.%' OR vcNomRue Like '% APP #%' OR vcNomRue Like '% APP-%' THEN 0
                           WHEN vcNoCivique = '-' THEN 0
                           ELSE IsNull(CharIndex('-', vcNoCivique, CharIndex('-', vcNoCivique, 1) + 1), 0)
                      END
        FROM
            @pTableAdresse
    ),
    CTE_Appartement as (
        SELECT
            iiD_Source, iID_Adresse,
            NoCivique = CASE WHEN Len(IsNull(Appartement, '')) > 0 OR iDash_1 = 0 THEN NoCivique
                             WHEN iDash_2 > 0 THEN LTrim(SubString(NoCivique, iDash_2 + 1, Len(NoCivique) - iDash_2))
                             WHEN IsNumeric(LTrim(SubString(NoCivique, iDash_1 + 1, Len(NoCivique) - iDash_1))) = 0 THEN Left(NoCivique, iDash_1 - 1)
                             ELSE LTrim(SubString(NoCivique, iDash_1 + 1, Len(NoCivique) - iDash_1))
                        END,
            Appartement = CASE WHEN Len(IsNull(Appartement, '')) > 0 THEN Appartement
                               WHEN iDash_2 > 0 THEN  Left(NoCivique, iDash_2 - 1)
                               WHEN iDash_1 > 0 THEN 
                                    CASE WHEN IsNumeric(LTrim(SubString(NoCivique, iDash_1 + 1, Len(NoCivique) - iDash_1))) <> 0 
                                              THEN Left(NoCivique, iDash_1 - 1)
                                         ELSE LTrim(SubString(NoCivique, iDash_1 + 1, Len(NoCivique) - iDash_1))
                                    END
                               WHEN NomRue Like '% APP %' OR NomRue Like '% APP.%' OR NomRue Like '% APP #%' OR NomRue Like '% APP-%'
                                    THEN LTrim(Replace(SubString(NomRue, CharIndex(' APP', NomRue, 1)+4, Len(NomRue)), '.', ' '))
                               ELSE Appartement
                          END,
            NomRue = CASE WHEN Len(IsNull(Appartement, '')) > 0 OR iDash_1 > 0 THEN NomRue
                          WHEN NomRue Like '% APP %' OR NomRue Like '% APP.%' OR NomRue Like '% APP #%' OR NomRue Like '% APP-%'
                               THEN LTrim(Left(NomRue, CharIndex(' APP', NomRue, 1) - 1))
                          ELSE NomRue 
                     END,
            ID_TypeBoite, Boite
        FROM
            CTE_Dash
    )
    SELECT
        TB.iiD_Source, 
        TB.iID_Adresse, 
        NoCivique = Left(Replace(A.NoCivique, '.', ''), 10),
        Appartement = Left(A.Appartement, 10),
        NomRue = Left(RTrim(Replace(A.NomRue, ',', ' ')), 175),
        ID_TypeBoite = A.ID_TypeBoite,
        Boite = Left(A.Boite, 50)
    FROM
        @pTableAdresse TB 
        JOIN CTE_Appartement A ON A.iid_Source = TB.iID_Source And  A.iID_Adresse = TB.iID_Adresse
    --WHERE
    --    IsNull(TB.vcNoCivique, '') <> IsNull(A.NoCivique, '')
    --    OR IsNull(TB.vcAppartement, '') <> IsNull(A.Appartement, '')
    --    OR IsNull(TB.vcNomRue, '') <> IsNull(A.NomRue, '')
    --    OR IsNull(TB.iID_TypeBoite, 0) <> IsNull(A.ID_TypeBoite, 0)
    --    OR IsNull(TB.vcBoite, '') <> IsNull(A.Boite, '')
)
