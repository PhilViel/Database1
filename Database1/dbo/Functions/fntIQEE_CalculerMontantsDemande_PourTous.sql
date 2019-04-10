/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service : fntIQEE_CalculerMontantsDemande_PourTous
Nom du service  : Calculer les montants d’une demande de l’IQÉÉ pour toutes les conventions
But             : Calculer les montants d’une demande de l’IQÉÉ qui correspondent aux champs « Montant des
                  cotisations annuelles versées dans le régime », « Montant des cotisations annuelles issues d’un
                  transfert », « Montant total des cotisations annuelles » et « Montant total des cotisations
                  versées au régime » du type d’enregistrement 02.  Les montants négatifs sont utilisé pour les
                  transactions de type 06-impôt spécial et de sous-type 22-retrait prématuré de cotisations
Facette         : IQÉÉ

Paramètres d’entrée :
    Paramètre                   Description
    ------------------------    -----------------------------------------------------------------
    iID_Convention              Identifiant unique de la convention pour laquelle le calcul est demandé.
    dtDate_Debut_Application    Date de début d’application des cotisations.  La date effective de la transaction 
                                de cotisation est utilisée pour la sélection.
    dtDate_Fin_Application      Date de fin d’application des cotisations.  La date effective de la transaction de 
                                cotisation est utilisée pour la sélection.
    @bForceRIN                  

Exemple d’appel : Cette procédure doit être appelée uniquement par les procédures "psIQEE_CreerTransactions02" et
                  declare @id int = (select conventionid from dbo.un_convention where ConventionNo = 'I-20161219008')
                  select * from dbo.fntIQEE_CalculerMontantsDemande_PourTous(@id, '2017-01-01', '2017-12-31', 0)

Paramètres de sortie :
    Champ                       Description
    ------------------------    ---------------------------------
    iID_Convention              ID de la convention
    mCotisations                Montant des cotisations annuellessubventionnables versées dans la convention.
    mTransfert_IN               Montant des cotisations annuelles subventionnables versées dans la convention 
                                cédante qui sont transmis à GUI qui est le cessionnaire.
    mTotal_Subventionnables
                                Somme des 2 montants précédents.
    mTotal_Cotisations          Solde des cotisations et frais au 31 décembre de l’année fiscale du fichier en création.
    bTransactions_Deja_Subventionnee
                                Indicateur s’il y a des transactions de l’année fiscale qui n’entre pas dans le 
                                calcul du montant subventionnable parce qu’elles ont déjà été utilisé dans une 
                                autre demande de l’IQÉÉ.
    mTotal_RIN_SansPreuve       Montant des cotisations retirées avec preuve d'étude

Historique des modifications:
    Date        Programmeur     Description
    ----------  -------------   -----------------------------------------------------
    2016-06-09  Steeve Picard   Création du service
    2017-03-24  Steeve Picard   Split de la fonction avec fntIQEE_CalculerMontantsDemande_Details
    2017-09-15  Steeve Picard   Correction du montant de cotisation subventionnable «mCotisations» pour y soustraire les RIN avec preuve
    2017-12-19  Steeve Picard   Ajout pour retourner aussi le «mTotal_RIN_SansPreuve»
                                Inclus les frais «FRS» dans le cas de convention temporaire «T-%»
    2018-11-23  Steeve Picard   Correction du montant de cotisation subventionnable «mCotisations» pour considérer les TFR que les cas des individuels
    2019-01-10  Steeve Picard   Exclure les frais «FRS» dans le cas de convention temporaire «T-%»
*********************************************************************************************************************/
CREATE FUNCTION dbo.fntIQEE_CalculerMontantsDemande_PourTous
(
    @iID_Convention INT = NULL,
    @dtDate_Debut_Application DATETIME,
    @dtDate_Fin_Application DATETIME,
    @bForceRIN BIT = 0
)
RETURNS @tblIQEE_Montants TABLE
(
    iID_Convention INT NOT NULL,
    mCotisations MONEY NOT NULL,
    mTransfert_IN MONEY NOT NULL,
    mTotal_Cotisations MONEY NOT NULL,
    mTotal_Subventionnables MONEY NOT NULL DEFAULT(0),
    bTransactions_Deja_Subventionnee BIT DEFAULT(0),
    --dtRetrait_RIN DATE,
    --iID_College_RIN INT,
    mTotal_RIN_AvecPreuve money DEFAULT(0),
    mTotal_RIN_SansPreuve money DEFAULT(0)
)
AS
BEGIN
    -- Initialisations
    DECLARE 
        --@vcID_Transactions VARCHAR(8000) = '',
       --@ID_Convention int,
       @vcIQEE_DEMANDE_COTISATION VARCHAR(200),
       @vcIQEE_CALCUL_MONTANTS_DEMANDE_TRANSFERT_IN VARCHAR(200),
       @vcIQEE_CALCUL_MONTANTS_DEMANDE_TRANSFERT_OUT VARCHAR(200),
       @vcIQEE_CALCUL_MONTANTS_DEMANDE_MONTANTS_NEGATIF VARCHAR(200),
       @vcIQEE_CALCUL_MONTANTS_DEMANDE_MONTANTS_POSITIF VARCHAR(200),
       @bCotisation_Deja_Subventionnee BIT,
       @bTransactions_Deja_Subventionnee BIT = 0,
       @dtDate_Effective_Operation_Transfert datetime,
       @CollegeID int

    -- Confirmer la valeur des paramètres absents
     IF @bForceRIN IS NULL
        SET @bForceRIN = 0
     IF @dtDate_Debut_Application >= '2012-01-01'
        SET @bForceRIN = 1

    -- Trouver les codes des catégories utilisés
    SET @vcIQEE_DEMANDE_COTISATION = dbo.fnOPER_ObtenirTypesOperationCategorie('IQEE-DEMANDE-COTISATION')
    SET @vcIQEE_CALCUL_MONTANTS_DEMANDE_TRANSFERT_IN = dbo.fnOPER_ObtenirTypesOperationCategorie
                                                        ('IQEE_CALCUL_MONTANTS_DEMANDE_TRANSFERT_IN')
--TODO: Considérer les RIM, RIO et TRI comme des transferts lors la phase 18 de l'IQÉÉ?  Oui pour le calcul du champ "@mTransfert_IN".  Quand les données seront enregistrées dans Un_TIN.  Quoi faire avec les anciennes transactions?
    SET @vcIQEE_CALCUL_MONTANTS_DEMANDE_TRANSFERT_OUT = dbo.fnOPER_ObtenirTypesOperationCategorie
                                                        ('IQEE_CALCUL_MONTANTS_DEMANDE_TRANSFERT_OUT')
--TODO: Considérer les RIM, RIO et TRI comme des transferts lors la phase 18 de l'IQÉÉ?  Oui pour le calcul du champ "@mCotisations" afin d'exclure les cotisations de l'année du transfert du calcul.  Quand les données seront enregistrées dans Un_OUT.  Quoi faire avec les anciennes transactions?
    SET @vcIQEE_CALCUL_MONTANTS_DEMANDE_MONTANTS_NEGATIF = dbo.fnOPER_ObtenirTypesOperationCategorie
                                                        ('IQEE_CALCUL_MONTANTS_DEMANDE_MONTANTS_NEGATIF')
    SET @vcIQEE_CALCUL_MONTANTS_DEMANDE_MONTANTS_POSITIF = dbo.fnOPER_ObtenirTypesOperationCategorie
                                                        ('IQEE_CALCUL_MONTANTS_DEMANDE_MONTANTS_POSITIF')

    DECLARE @TB_CalculerMontantsDemande TABLE (
                ID_Convention int,
                ID_Operation int,
                Code_Type_Operation varchar(3),
                ID_Operation_Annulation    int,
                Date_Cotisation date,
                ID_Cotisation int,
                Cotisations_Transaction money,
                Frais money,
                Cotisation_Annee_Transfert_IN money,
                Cotisation_Annee_Transfert_OUT money,
                Cotisations_Sans_SCEE_Avant_1998 money,
                Cotisations_Sans_SCEE_APartirDe_1998 money,
                Cotisations_Avec_SCEE money,
                CollegeID int
            )

    -- Rechercher toutes les transactions de cotisation applicables depuis le début jusqu'à la date de fin d'application
    INSERT INTO @TB_CalculerMontantsDemande (
            ID_Convention, ID_Operation, Code_Type_Operation, ID_Operation_Annulation, Date_Cotisation, CollegeID,
            ID_Cotisation, Cotisations_Transaction, Frais, Cotisation_Annee_Transfert_IN, Cotisation_Annee_Transfert_OUT, 
            Cotisations_Sans_SCEE_Avant_1998, Cotisations_Sans_SCEE_APartirDe_1998, Cotisations_Avec_SCEE
        )
    SELECT
        ID_Convention, ID_Operation, Code_Type_Operation, ID_Operation_Annulation, Date_Cotisation, CollegeID,
        ID_Cotisation, Cotisations_Transaction, Frais, Cotisation_Annee_Transfert_IN, Cotisation_Annee_Transfert_OUT, 
        Cotisations_Sans_SCEE_Avant_1998, Cotisations_Sans_SCEE_APartirDe_1998, Cotisations_Avec_SCEE
    FROM 
        dbo.fntIQEE_CalculerMontantsDemande_Details(@iID_Convention, @dtDate_Debut_Application, @dtDate_Fin_Application)
    WHERE 
        YEAR(Date_Cotisation) < 2012
        OR (
            Code_Type_Operation <> 'RIN'
            OR (
                Code_Type_Operation = 'RIN' 
                AND ( IsNull(CollegeID, 0) = 0 OR CollegeID = 4941 OR Year(Date_Cotisation) >= 2012)
            )
        )        

    DECLARE @tblIQEE_Montants_Detail TABLE (
                iID_Convention INT NOT NULL,
                iID_Cotisation INT NOT NULL,
                mCotisations MONEY NOT NULL DEFAULT(0),
                mTransfert_IN MONEY NOT NULL DEFAULT(0),
                mTotal_Cotisations MONEY NOT NULL DEFAULT(0),
                --dtCotisation DATE,
                --iID_College INT,
                mTotal_RIN_AvecPreuve money NOT NULL DEFAULT(0),
                mTotal_RIN_SansPreuve money NOT NULL DEFAULT(0)
            )

    -- Est un transfert IN
    INSERT @tblIQEE_Montants_Detail (iID_Convention, iID_Cotisation, mTransfert_IN)
    SELECT
        ID_Convention, ID_Cotisation, ISNULL(Cotisation_Annee_Transfert_IN,0)
    FROM
        @TB_CalculerMontantsDemande
    WHERE
        Date_Cotisation BETWEEN @dtDate_Debut_Application AND @dtDate_Fin_Application 
        AND CHARINDEX(Code_Type_Operation, @vcIQEE_CALCUL_MONTANTS_DEMANDE_TRANSFERT_IN) > 0

    -- N'est pas un transfert IN
    INSERT @tblIQEE_Montants_Detail (iID_Convention, iID_Cotisation, mCotisations)
    SELECT
        ID_Convention, ID_Cotisation,
        CASE Code_Type_Operation WHEN @vcIQEE_CALCUL_MONTANTS_DEMANDE_TRANSFERT_OUT 
                                 THEN -1 * IsNull(Cotisation_Annee_Transfert_OUT, 0)
                                 ELSE IsNull(Cotisations_Transaction, 0) + IsNull(Frais, 0)
        END
    FROM
        @TB_CalculerMontantsDemande
    WHERE
        Date_Cotisation BETWEEN @dtDate_Debut_Application AND @dtDate_Fin_Application 
        AND CHARINDEX(Code_Type_Operation, @vcIQEE_CALCUL_MONTANTS_DEMANDE_TRANSFERT_IN) = 0
        --AND NOT(Date_Cotisation >= '2012-11-01' and Code_Type_Operation = 'TFR')
            -- Cotisation admissible à l'IQÉÉ
        AND CHARINDEX(','+Code_Type_Operation+',', @vcIQEE_DEMANDE_COTISATION) = 0 
                   
    INSERT @tblIQEE_Montants_Detail (iID_Convention, iID_Cotisation, mTotal_Cotisations)
    SELECT
        ID_Convention, ID_Cotisation, IsNull(Cotisations_Transaction, 0) + IsNull(Frais, 0)
    FROM
        @TB_CalculerMontantsDemande
    WHERE
        ID_Operation_Annulation IS NULL
        AND (
            (Date_Cotisation >= '2012-11-01' AND Code_Type_Operation <> 'TFR')
            OR Date_Cotisation < '2012-11-01'
        )
        AND (
            (
                Cotisations_Transaction + Frais < 0
                AND CHARINDEX(Code_Type_Operation, @vcIQEE_CALCUL_MONTANTS_DEMANDE_MONTANTS_NEGATIF) > 0
            )
            OR (
                Cotisations_Transaction + Frais >= 0
                AND CHARINDEX(','+Code_Type_Operation+',',@vcIQEE_CALCUL_MONTANTS_DEMANDE_MONTANTS_POSITIF) > 0
            )
        )

    -- Depuis 2012/01/01 On inclus les RINs sans ID                               
    IF @bForceRIN <> 0
        INSERT @tblIQEE_Montants_Detail (iID_Convention, iID_Cotisation, mTotal_RIN_AvecPreuve, mTotal_RIN_SansPreuve)
        SELECT
            ID_Convention, ID_Cotisation, 
            CASE WHEN ISNULL(CollegeID, 0) IN (0, 4941) THEN 0 ELSE ISNULL(Cotisations_Transaction, 0) + IsNull(Frais, 0) END,
            CASE WHEN ISNULL(CollegeID, 0) IN (0, 4941) THEN ISNULL(Cotisations_Transaction, 0) + IsNull(Frais, 0) ELSE 0 END
        FROM
            @TB_CalculerMontantsDemande D
        WHERE
            Code_Type_Operation = 'RIN'
            AND ( CollegeID IS NOT NULL OR YEAR(Date_Cotisation) >= 2012)

    ---- Considérer les TFR des conventions d'un plan individuel
    --INSERT @tblIQEE_Montants_Detail (iID_Convention, iID_Cotisation, mTotal_RIN_AvecPreuve, mTotal_RIN_SansPreuve)
    --SELECT
    --    ID_Convention, ID_Cotisation, 0, ISNULL(Cotisations_Transaction, 0) + IsNull(Frais, 0)
    --FROM
    --    @TB_CalculerMontantsDemande TB
    --    JOIN dbo.Un_Convention C ON C.ConventionID = TB.ID_Convention
    --    JOIN dbo.Un_Plan P ON P.PlanID = C.PlanID
    --WHERE
    --    Code_Type_Operation = 'TFR'
    --    AND YEAR(Date_Cotisation) >= 2012
    --    AND P.PlanTypeID = 'IND'

    -- Considérer les FRS des conventions «T-***********»
    INSERT @tblIQEE_Montants_Detail (iID_Convention, iID_Cotisation, mTotal_RIN_AvecPreuve, mTotal_RIN_SansPreuve)
    SELECT
        ID_Convention, ID_Cotisation, ISNULL(Cotisations_Transaction, 0) + IsNull(Frais, 0), 0
    FROM
        @TB_CalculerMontantsDemande TB
        JOIN dbo.Un_Convention C ON C.ConventionID = TB.ID_Convention
    WHERE
        YEAR(Date_Cotisation) >= 2012
        AND Code_Type_Operation = 'FRS'
        AND NOT C.ConventionNo LIKE 'T-%'
                 
    -- Est un transfert IN
    INSERT @tblIQEE_Montants_Detail (iID_Convention, iID_Cotisation, mTotal_Cotisations)
    SELECT
        ID_Convention, ID_Cotisation, IsNull(Cotisations_Sans_SCEE_Avant_1998, 0) + IsNull(Cotisations_Sans_SCEE_APartirDe_1998, 0) + IsNull( + Cotisations_Avec_SCEE, 0)
    FROM
        @TB_CalculerMontantsDemande
    WHERE
        CHARINDEX(Code_Type_Operation, @vcIQEE_CALCUL_MONTANTS_DEMANDE_TRANSFERT_IN) > 0

    INSERT @tblIQEE_Montants (iID_Convention, mCotisations, mTransfert_IN, mTotal_Subventionnables, mTotal_Cotisations, 
                              --dtRetrait_RIN, iID_College_RIN, 
                              mTotal_RIN_AvecPreuve, mTotal_RIN_SansPreuve)
    SELECT
        iID_Convention, Sum(mCotisations), Sum(mTransfert_IN), Sum(mCotisations + mTransfert_IN + mTotal_RIN_AvecPreuve + mTotal_RIN_SansPreuve), sum(mTotal_Cotisations), 
        --MAX(dtCotisation), MAX(iID_College), 
        -SUM(mTotal_RIN_AvecPreuve), -SUM(mTotal_RIN_SansPreuve)
    FROM
        @tblIQEE_Montants_Detail
    GROUP BY
        iID_Convention

    --;WITH CTE_Detail (iID_Convention, vcTrans, Row_Num) as (
    --    SELECT iID_Convention, Cast(LTrim(Str(iID_Cotisation, 10)) as varchar(max)),
    --           ROW_NUMBER() OVER(Partition By iID_Convention Order By iID_Cotisation)
    --      FROM @tblIQEE_Montants_Detail
    --),
    --CTE_Recursive (iID_Convention, Row_Num, vcTransaction) AS (
    --    SELECT iID_Convention, Row_Num, vcTrans
    --      FROM CTE_Detail
    --     WHERE Row_Num = 1
       --UNION ALL 
    --    SELECT C.iID_Convention, C.Row_Num, R.vcTransaction + ',' + C.vcTrans
    --      FROM CTE_Detail AS C INNER JOIN CTE_Recursive AS R ON C.iID_Convention = R.iID_Convention
    --     WHERE C.Row_Num = R.Row_Num + 1
       -- ) 
    --UPDATE T
    --   SET vcID_Transactions = vcTransaction
    --  FROM @tblIQEE_Montants T JOIN CTE_Recursive R ON R.iID_Convention = T.iID_Convention
    -- WHERE Row_Num = (SELECT MAX(Row_Num) FROM CTE_Recursive WHERE iID_Convention = T.iID_Convention)

    UPDATE @tblIQEE_Montants
       SET mCotisations = CASE WHEN mCotisations + mTransfert_IN > 0 THEN 0 ELSE mCotisations + mTransfert_IN END,
           mTransfert_IN = CASE WHEN mCotisations + mTransfert_IN > 0 THEN mCotisations + mTransfert_IN ELSE 0 END
     WHERE mCotisations < 0

    UPDATE @tblIQEE_Montants
       SET mCotisations = CASE WHEN mCotisations + mTransfert_IN > 0 THEN mCotisations + mTransfert_IN ELSE 0 END,
           mTransfert_IN = CASE WHEN mCotisations + mTransfert_IN > 0 THEN 0 ELSE mCotisations + mTransfert_IN END
     WHERE mTransfert_IN < 0

    UPDATE @tblIQEE_Montants
       SET mTotal_Subventionnables = 0
     WHERE mTotal_Subventionnables < 0

    /*
    UPDATE @tblIQEE_Montants
       SET mTransfert_IN = mCotisations + mTransfert_IN,
           mCotisations = 0
     WHERE mCotisations < 0
    */

    RETURN
END


