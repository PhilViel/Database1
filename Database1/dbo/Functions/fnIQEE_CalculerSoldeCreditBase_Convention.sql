/****************************************************************************************************
Code de service    :   fnIQEE_CalculerSoldeCreditBase_Convention
Nom du service  :   CalculerSoldeIQEE_Convention
But             :   Calculer le solde de l'IQÉÉ de base d'une convention
Facette         :   IQÉÉ
Reférence       :    Système de gestion de la relation client

Parametres d'entrée :    
    Parametres                Description
    ----------                ----------------
    iID_Convention            ID de la convention concernée par l'appel
    dtDate_Fin                Date de fin de la période considérée par l'appel

Exemple d'appel:
    declare @ID int = (select conventionID from dbo.un_convention where ConventionNo = 'E-19991006001')
    SELECT dbo.fnIQEE_CalculerSoldeCreditBase_Convention (@ID, '2017-12-31')

Parametres de sortie :    Le solde de l'IQEE

Historique des modifications :
            
    Date        Programmeur                 Description
    ----------  ------------------------    --------------------------------------------------------
    2012-08-06  Stéphane Barbeau            Création de la fonction
    2012-08-14    Stéphane Barbeau            Ajout clause OR (O.OperTypeID = 'IQE' AND CO.ConventionOperAmount < 0.00)
    2012-12-13  Stéphane Barbeau            Inclure dans le calcul les montants subséquents liés à des demandes T02 antérieures.
    2013-02-25  Stéphane Barbeau            Ajout des réencaissements issus des T06 en erreur dans le calcul.
    2013-02-26  Stéphane Barbeau            Ajout des montants issus des réponses aux T06s dans le calcul.
    2013-12-13  Stéphane Barbeau            Requête @mMontant_IQEE_Base: Ajustement condition (O.OperTypeID <> 'IQE'  AND O.OperDate <= @dtDate_Fin)
    2018-02-08  Steeve Picard               Déplacement de «siAnnee_Fiscale» de la table «tblIQEE_Fichiers» vers les tables d'évèments
****************************************************************************************************/
CREATE FUNCTION dbo.fnIQEE_CalculerSoldeCreditBase_Convention
(
    @iID_Convention    INT,
    @dtDate_Fin     DATETIME
)
RETURNS MONEY
AS
BEGIN

    DECLARE @mMontant_IQEE_Base MONEY
    DECLARE @mMontant_Subsequent_ReponsesT02 MONEY
    DECLARE @mMontant_Subsequent_T06_Reponses MONEY
    DECLARE @mMontant_Subsequent_T06_Erreur MONEY
    DECLARE @mTotal_IQEE_Base MONEY

    SELECT 
        @mMontant_IQEE_Base = ISNULL(cbq.cbq, 0)
    FROM 
        dbo.Un_Convention C
        LEFT JOIN (
            SELECT 
                cbq = ISNULL(SUM(ISNULL(CO.ConventionOperAmount, 0)), 0),
                CO.ConventionID
            FROM
                dbo.Un_ConventionOper CO
                JOIN dbo.Un_Oper O ON O.OperID = CO.OperID
                                   AND (
                                        (O.OperTypeID <> 'IQE' AND O.OperDate <= @dtDate_Fin)
                                        OR (O.OperTypeID = 'IQE' AND CO.ConventionOperAmount < 0.00)
                                        OR (O.OperTypeID = 'IQE' AND O.OperDate <= @dtDate_Fin)
                                   )
            WHERE 
                CO.ConventionOperTypeID = 'CBQ'
            GROUP BY 
                CO.ConventionID
        ) cbq
            ON cbq.ConventionID = C.ConventionID
    WHERE 
        C.ConventionID = @iID_Convention

    -- Montants subséquents

    -- CBQ

    -- Réponses CBQ  T02
    SELECT 
        @mMontant_Subsequent_ReponsesT02 = ISNULL(SUM(C.ConventionOperAmount), 0)
    FROM 
        dbo.Un_ConventionOper C
    WHERE 
        C.ConventionOperID IN (
            SELECT 
                RD.iID_Transaction_Convention
            FROM 
                dbo.tblIQEE_Demandes D
                JOIN dbo.tblIQEE_ReponsesDemande RD ON RD.iID_Demande_IQEE = D.iID_Demande_IQEE
                JOIN dbo.Un_ConventionOper UCO ON UCO.ConventionOperID = RD.iID_Transaction_Convention
                JOIN dbo.Un_Oper UOP ON UOP.OperID = RD.iID_Operation
            WHERE 
                D.iID_Convention = @iID_Convention
                AND D.cStatut_Reponse IN ( 'R', 'T' )
                AND D.tiCode_Version IN ( 0, 2 )
                AND D.siAnnee_Fiscale <= YEAR(@dtDate_Fin)
                AND RD.iID_Operation IS NOT NULL
                AND RD.tiID_Type_Reponse IN ( 4, 22 )
                AND UCO.ConventionOperTypeID = 'CBQ'
                AND UOP.OperDate > @dtDate_Fin
        )

    -- Erreurs CBQ T06
    SELECT 
        @mMontant_Subsequent_T06_Erreur = ISNULL(SUM(C.ConventionOperAmount), 0)
    FROM
        dbo.Un_ConventionOper C
    WHERE 
        C.ConventionOperID IN (
            SELECT 
                DIS.iID_Transaction_Convention_CBQ_Renversee
            FROM 
                dbo.tblIQEE_ImpotsSpeciaux DIS
                JOIN dbo.Un_ConventionOper UCO ON UCO.ConventionOperID = DIS.iID_Transaction_Convention_CBQ_Renversee
                JOIN dbo.Un_Oper UOP ON UOP.OperID = UCO.OperID
            WHERE 
                DIS.iID_Convention = @iID_Convention
                AND DIS.cStatut_Reponse IN ( 'E' )
                AND DIS.tiCode_Version IN ( 0, 2 )
                AND DIS.iID_Transaction_Convention_CBQ_Renversee IS NOT NULL
                AND DIS.siAnnee_Fiscale <= YEAR(@dtDate_Fin)
                AND UCO.ConventionOperTypeID = 'CBQ'
                AND UOP.OperDate > @dtDate_Fin
        )

    -- Réponses CBQ T06
    SELECT 
        @mMontant_Subsequent_T06_Reponses = ISNULL(SUM(C.ConventionOperAmount), 0)
    FROM 
        dbo.Un_ConventionOper C
    WHERE 
        C.ConventionOperID IN (
            SELECT 
                RIS.iID_Paiement_Impot_CBQ
            FROM 
                dbo.tblIQEE_ImpotsSpeciaux DIS
                JOIN dbo.tblIQEE_ReponsesImpotsSpeciaux RIS ON DIS.iID_Impot_Special = RIS.iID_Impot_Special_IQEE
                JOIN dbo.Un_ConventionOper UCO ON UCO.ConventionOperID = RIS.iID_Paiement_Impot_CBQ
                JOIN dbo.Un_Oper UOP ON UOP.OperID = UCO.OperID
            WHERE 
                DIS.iID_Convention = @iID_Convention
                AND DIS.cStatut_Reponse IN ( 'R' )
                AND DIS.tiCode_Version IN ( 0, 2 )
                AND DIS.siAnnee_Fiscale <= YEAR(@dtDate_Fin)
                AND RIS.iID_Paiement_Impot_CBQ IS NOT NULL
                AND UCO.ConventionOperTypeID = 'CBQ'
                AND UOP.OperDate > @dtDate_Fin
        )

    SET @mTotal_IQEE_Base = @mMontant_IQEE_Base + @mMontant_Subsequent_ReponsesT02 + @mMontant_Subsequent_T06_Erreur + @mMontant_Subsequent_T06_Reponses

    RETURN @mTotal_IQEE_Base
END
