-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE FUNCTION [dbo].[fntIQEE_ExtraireNoCiviqueUserTable](@pTableAdresse dbo.UDT_tblAdresse READONLY)
RETURNS TABLE
AS RETURN
(
    WITH CTE_Fix as (
        SELECT
            iiD_Source, iID_Adresse, vcNoCivique,
            vcNomRue = Replace(
                            Replace(
                                Replace(
                                    Replace(
                                        Replace(
                                            Replace(
                                                Replace(
                                                    Replace(
                                                        Replace(
                                                            Replace(
                                                                Replace(Replace(Replace(vcNomRue, '  ', ' '), ' - ', '-'), 'Boite Postal', 'CP'),
                                                                'Boite', 'CP'),
                                                            'Case PO Box', 'CP'),
                                                        'Casier PO Box', 'CP'),
                                                    'PO Box', 'CP'),
                                                'Box', 'CP'),
                                            'BP', 'CP'),
                                        'Case Postale', 'CP'),
                                    'Casier Postal', 'CP'),
                                'Poste restante', 'CP'),
                            'C.P.', 'CP'),
            vcAppartement = LTrim(vcAppartement), 
            iID_TypeBoite, 
            vcBoite = LTrim(vcBoite)
        FROM
            @pTableAdresse
    ),
    CTE_blank as (
        SELECT
            iiD_Source, iID_Adresse, 
            vcNoCivique = CASE WHEN LTrim(Replace(vcNomRue, '.', '')) like 'CP [0-9]% SUCC%' OR LTrim(Replace(vcNomRue, '.', '')) like 'CP [0-9]% CSP %' OR LTrim(Replace(vcNomRue, '.', '')) like 'CP [0-9]% RPO %'
                                    THEN IsNull(vcNoCivique, '-') 
                               WHEN LTrim(REPLACE(vcNomRue, '-', '')) like 'Casier Postal [0-9]% SUCC%' OR LTrim(vcNomRue) like 'Casier Postal [0-9]% CSP %'  OR LTrim(vcNomRue) like 'Casier Postal [0-9]% RPO %'
                                    THEN IsNull(vcNoCivique, '-') 
                               WHEN LTrim(Replace(vcNomRue, '.', '')) like 'CP [0-9]%' AND NOT LTrim(Replace(vcNomRue, '.', '')) like 'CP [0-9]% %'
                                    THEN IsNull(vcNoCivique, '-') 
                               WHEN LTrim(Replace(vcNomRue, '.', '')) like 'CP[0-9]%' AND NOT LTrim(Replace(vcNomRue, '.', '')) like 'CP[0-9]% %'
                                    THEN IsNull(vcNoCivique, '-') 
                               WHEN LTrim(Replace(vcNomRue, '.', '')) like 'RR [0-9]%' AND NOT LTrim(Replace(vcNomRue, '.', '')) like 'RR [0-9]% %' 
                                    THEN IsNull(vcNoCivique, '-') 
                               WHEN LTrim(Replace(vcNomRue, '.', '')) like 'BP [0-9]%' AND NOT LTrim(Replace(vcNomRue, '.', '')) like 'BP [0-9]% %' 
                                    THEN IsNull(vcNoCivique, '-') 
                               WHEN LTrim(Replace(vcNomRue, '.', '')) like 'PO Box [0-9]%' AND NOT LTrim(Replace(vcNomRue, '.', '')) like 'PO Box [0-9]% %' 
                                    THEN IsNull(vcNoCivique, '-') 
                               WHEN LTrim(Replace(vcNomRue, '.', '')) like 'Case PO Box [0-9]%' AND NOT LTrim(Replace(vcNomRue, '.', '')) like 'Case PO Box [0-9]% %' 
                                    THEN IsNull(vcNoCivique, '-') 
                               WHEN LTrim(Replace(vcNomRue, '.', '')) like 'Casier PO Box [0-9]%' AND NOT LTrim(Replace(vcNomRue, '.', '')) like 'Casier PO Box [0-9]% %' 
                                    THEN IsNull(vcNoCivique, '-') 
                               WHEN LTrim(vcNomRue) like 'Case Postale [0-9]%' AND NOT LTrim(vcNomRue) like 'Case Postale [0-9]% %' 
                                    THEN IsNull(vcNoCivique, '-') 
                               WHEN LTrim(vcNomRue) like 'Casier Postal [0-9]%' AND NOT LTrim(vcNomRue) like 'Casier Postal [0-9]% %' 
                                    THEN IsNull(vcNoCivique, '-') 
                               WHEN LTrim(vcNomRue) like 'Boite [0-9]%' AND NOT LTrim(vcNomRue) like 'Boite [0-9]% %' 
                                    THEN IsNull(vcNoCivique, '-') 
                               WHEN LTrim(vcNomRue) like 'Boite Poste [0-9]%' AND NOT LTrim(vcNomRue) like 'Boite Poste [0-9]% %' 
                                    THEN IsNull(vcNoCivique, '-') 
                               WHEN LTrim(vcNomRue) like 'Box [0-9]%' AND NOT LTrim(vcNomRue) like 'Box [0-9]% %' 
                                    THEN IsNull(vcNoCivique, '-') 
                               WHEN LTrim(vcNomRue) = 'Poste restante' THEN IsNull(vcNoCivique, '-') 
                               WHEN iID_TypeBoite <> 0 AND LTrim(IsNull(vcBoite, '')) <> ''
                                    THEN IsNull(vcNoCivique, '-') 
                               WHEN Left(vcNomRue, CharIndex(' ', vcNomRue, 1)) LIKE '%[0-9]%' THEN IsNull(vcNoCivique, '-') 
                               ELSE LTrim(IsNull(vcNoCivique, '-') ) END,
            vcAppartement = LTrim(vcAppartement), 
            vcNomRue = LTrim(CASE WHEN LEFT(vcNomRue, 1) = '-' THEN SUBSTRING(vcNomRue, 2, LEN(vcNomRue) - 1) 
                                  WHEN Len(vcNoCivique) > 0 AND vcNomRue Like vcNoCivique + ' %' 
                                       THEN Substring(vcNomRue, Len(vcNoCivique) + 2, LEN(vcNomRue) - Len(vcNoCivique) - 1) 
                                  ELSE Replace(vcNomRue, ' - ', '-')
                             END),
            iID_TypeBoite, 
            vcBoite = LTrim(vcBoite),
            iBlank_1 = CharIndex(' ', vcNomRue, 1),
            iBlank_2 = CharIndex(' ', Replace(vcNomRue, '  ', ' '), CharIndex(' ', Replace(vcNomRue, '  ', ' '), 1) + 1),
            iBlank_3 = CharIndex(' ', Replace(vcNomRue, '  ', ' '), CharIndex(' ', Replace(vcNomRue, '  ', ' '), CharIndex(' ', Replace(vcNomRue, '  ', ' '), 1) + 1) + 1)
        FROM
            CTE_Fix
    ),
    CTE_Civique as (
        SELECT
            iiD_Source, iID_Adresse, 
            NoCivique = LTRIM(REPLACE(CASE WHEN IsNull(vcNoCivique, '-') <> '-' OR iBlank_1 = 0 THEN vcNoCivique
                                           WHEN LTrim(Replace(vcNomRue, '.', '')) like 'CP [0-9]% SUCC%' OR LTrim(Replace(vcNomRue, '.', '')) like 'CP [0-9]% CSP %' OR LTrim(Replace(vcNomRue, '.', '')) like 'CP [0-9]% RPO %' THEN vcNoCivique
                                           WHEN LTrim(vcNomRue) like 'Casier Postal [0-9]% SUCC%'  OR LTrim(vcNomRue) like 'Casier Postal [0-9]% CSP %' OR LTrim(vcNomRue) like 'Casier Postal [0-9]% RPO %' THEN vcNoCivique
                                           WHEN LTrim(Replace(vcNomRue, '.', '')) like 'CP [0-9]%-[0-9]% [a-z]%' and iBlank_2 > 0 THEN Left(vcNomRue, iBlank_2 - 1)
                                           WHEN vcNomRue Like '%[0-9,A-Z]-[0-9]%' and iBlank_1 > 0 THEN Left(vcNomRue, iBlank_1 - 1)
                                           WHEN vcNomRue Like '%[0-9]-[0-9,A-Z]%' and iBlank_1 > 0 THEN Left(vcNomRue, iBlank_1 - 1)
                                           WHEN vcNomRue Like '%[0-9,A-Z]- [0-9,A-Z]%' and iBlank_2 > 0 THEN Replace(Left(vcNomRue, iBlank_2 - 1), ' ', '')
                                           WHEN vcNomRue Like '[A-Z][0-9]%' and iBlank_1 > 0 THEN Left(vcNomRue, iBlank_1 - 1)
                                           WHEN vcNomRue Like '%[0-9][A-Z]%' and iBlank_1 > 0 THEN Left(vcNomRue, iBlank_1 - 1)
                                           WHEN Replace(vcNomRue, '.', '') Like 'CP [0-9]% [0-9]%' and iBlank_3 > 0 THEN Replace(Left(Replace(vcNomRue, '  ', ' '), iBlank_3 - 1), ' ', '-')
                                           WHEN Replace(vcNomRue, '.', '') Like 'PO [0-9]% [0-9]%' and iBlank_3 > 0 THEN Replace(Left(Replace(vcNomRue, '  ', ' '), iBlank_3 - 1), ' ', '-')
                                           WHEN Replace(vcNomRue, '.', '') Like 'BOX [0-9]% [0-9]%' and iBlank_3 > 0 THEN Replace(Left(Replace(vcNomRue, '  ', ' '), iBlank_3 - 1), ' ', '-')
                                           WHEN IsNumeric(Replace(Left(vcNomRue, iBlank_1 - 1), ',', '')) = 0 THEN vcNoCivique
                                           ELSE Left(vcNomRue, iBlank_1 - 1)
                                      END, ',', '')),
            Appartement = CASE WHEN (vcAppartement LIKE 'APP.%' OR vcAppartement LIKE 'APP-%' OR vcAppartement LIKE 'APP #%' OR vcAppartement LIKE 'APP %') 
                                    THEN LTrim(Replace(Replace(Replace(Replace(vcAppartement, '.', ''), '-', ''), '#', ''), 'APP', ''))
                               WHEN (vcAppartement LIKE 'APPT.%' OR vcAppartement LIKE 'APPT-%' OR vcAppartement LIKE 'APPT #%' OR vcAppartement LIKE 'APPT %') 
                                    THEN LTrim(Replace(Replace(Replace(Replace(vcAppartement, '.', ''), '-', ''), '#', ''), 'APPT', ''))
                               WHEN Replace(vcAppartement, '.', '') LIKE 'CP[0-9]%' OR Replace(vcAppartement, '.', '') LIKE 'CP [0-9]%' THEN NULL 
                               WHEN Replace(vcAppartement, '.', '') LIKE 'RR[0-9]%' OR Replace(vcAppartement, '.', '') LIKE 'RR [0-9]%' THEN NULL 
                               WHEN (vcAppartement LIKE '[0-9] étage' OR vcAppartement LIKE '[0-9]e étage') THEN Replace(Replace(Replace(vcAppartement, 'étage', 'e'), ' ', ''), 'ee', 'e')
                               ELSE Replace(Replace(Replace(Replace(Replace(Replace(vcAppartement, 'é', 'e'), 'Condo ', ''), 'Unite ', ''), 'Suite ', ''), 'Lot ', ''), 'etage', 'ét.')
                          END,
            NomRue = CASE WHEN IsNull(vcNoCivique, '-') <> '-' OR iBlank_1 = 0  THEN vcNomRue
                          WHEN Replace(vcNomRue, '.', '') Like 'CP [0-9]% [0-9]%' THEN LTrim(SubString(vcNomRue, iBlank_3 + 1, Len(vcNomRue) - iBlank_3))
                          WHEN Replace(vcNomRue, '.', '') Like 'CP [0-9]% SUCC%' THEN LTrim(SubString(vcNomRue, iBlank_2 + 1, Len(vcNomRue) - iBlank_2))
                          WHEN Replace(vcNomRue, '.', '') Like 'CP [0-9]% CSP %' THEN LTrim(SubString(vcNomRue, iBlank_2 + 1, Len(vcNomRue) - iBlank_2))
                          WHEN vcNomRue like 'Casier Postal [0-9]% SUCC%' OR vcNomRue like 'Casier Postal [0-9]% CSP %' THEN LTrim(SubString(vcNomRue, iBlank_3 + 1, Len(vcNomRue) - iBlank_3))
                          WHEN LTrim(Replace(vcNomRue, '.', '')) like 'CP [0-9]%-[0-9]% [a-z]%'THEN SubString(vcNomRue, iBlank_2 + 1, Len(vcNomRue) - iBlank_2)
                          WHEN vcNomRue Like '%[0-9,A-Z]-[0-9]%' THEN LTrim(SubString(vcNomRue, iBlank_1 + 1, Len(vcNomRue) - iBlank_1))
                          WHEN vcNomRue Like '%[0-9]-[0-9,A-Z]%' THEN LTrim(SubString(vcNomRue, iBlank_1 + 1, Len(vcNomRue) - iBlank_1))
                          WHEN vcNomRue Like '%[0-9,A-Z]- [0-9]%' THEN LTrim(SubString(vcNomRue, iBlank_2 + 1, Len(vcNomRue) - iBlank_2))
                          WHEN vcNomRue Like '%[0-9]- [0-9,A-Z]%' THEN LTrim(SubString(vcNomRue, iBlank_2 + 1, Len(vcNomRue) - iBlank_2))
                          WHEN vcNomRue Like '[A-Z][0-9]%' THEN LTrim(SubString(vcNomRue, iBlank_1 + 1, Len(vcNomRue) - iBlank_1))
                          WHEN vcNomRue Like '%[0-9][A-Z]%' THEN LTrim(SubString(vcNomRue, iBlank_1 + 1, Len(vcNomRue) - iBlank_1))
                          WHEN IsNumeric(Replace(Left(vcNomRue, iBlank_1 - 1), ',', '')) = 0 THEN vcNomRue
                          ELSE LTrim(SubString(vcNomRue, iBlank_1 + 1, Len(vcNomRue) - iBlank_1))
                     END,
            ID_TypeBoite = CASE WHEN Replace(vcAppartement, '.', '') LIKE 'CP[0-9]%' THEN 1 
                                WHEN Replace(vcAppartement, '.', '') LIKE 'CP [0-9]%' THEN 1 
                                WHEN LTrim(Replace(vcNomRue, '.', '')) like 'CP [0-9]% SUCC%'  OR LTrim(Replace(vcNomRue, '.', '')) like 'CP [0-9]% CSP %' THEN 1
                                WHEN vcNomRue like 'Casier Postal [0-9]% SUCC%' OR vcNomRue like 'Casier Postal [0-9]% CSP %' THEN 1
                                WHEN Replace(vcAppartement, '.', '') LIKE 'RR%'THEN 2
                                ELSE iID_TypeBoite 
                           END,
            Boite = CASE WHEN Replace(vcAppartement, '.', '') LIKE 'CP[0-9]%'
                              THEN LTrim(Replace(Replace(Replace(vcAppartement, '.', ''), ':', ''), 'CP', '')) 
                         WHEN Replace(vcAppartement, '.', '') LIKE 'CP [0-9]%'
                              THEN LTrim(Replace(Replace(Replace(vcAppartement, '.', ''), ':', ''), 'CP', '')) 
                         WHEN LTrim(Replace(vcNomRue, '.', '')) like 'CP [0-9]% SUCC%'  OR LTrim(Replace(vcNomRue, '.', '')) like 'CP [0-9]% CSP %'
                              THEN LTrim(Replace(Replace(Replace(LEFT(vcNomRue, CTE_blank.iBlank_2 - 1), '.', ''), ':', ''), 'CP', '')) 
                         WHEN vcNomRue like 'Casier Postal [0-9]% SUCC%' OR vcNomRue like 'Casier Postal [0-9]% CSP %' 
                              THEN LTrim(SubString(vcNomRue, iBlank_2 + 1, iBlank_3 - iBlank_2))
                         WHEN Replace(vcAppartement, '.', '') LIKE 'RR %'
                              THEN LTrim(Replace(Replace(vcAppartement, '.', ''), 'RR', '')) 
                         WHEN Len(RTrim(vcBoite)) = 0 THEN NULL
                         ELSE vcBoite
                     END
        FROM
            CTE_Blank
    )
    SELECT
        TB.iiD_Source, 
        TB.iID_Adresse, 
        NoCivique = Left(RTrim(Replace(A.NoCivique, '.', ' ')), 20),
        Appartement = Left(A.Appartement, 10),
        NomRue = Left(RTrim(Replace(A.NomRue, ',', ' ')), 175),
        ID_TypeBoite = A.ID_TypeBoite,
        Boite = Left(A.Boite, 50)
    FROM
        @pTableAdresse TB 
        JOIN CTE_Civique A ON A.iid_Source = TB.iID_Source And  A.iID_Adresse = TB.iID_Adresse
    --WHERE
    --    IsNull(TB.vcNoCivique, '') <> IsNull(A.NoCivique, '')
    --    OR IsNull(TB.vcAppartement, '') <> IsNull(A.Appartement, '')
    --    OR IsNull(TB.vcNomRue, '') <> IsNull(A.NomRue, '')
    --    OR IsNull(TB.iID_TypeBoite, 0) <> IsNull(A.ID_TypeBoite, 0)
    --    OR IsNull(TB.vcBoite, '') <> IsNull(A.Boite, '')
)
