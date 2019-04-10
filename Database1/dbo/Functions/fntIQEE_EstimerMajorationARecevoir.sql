/****************************************************************************************************
Code de service :   fntIQEE_EstimerMajorationARecevoir
Nom du service  :   EstimerCreditBaseARecevoir
But             :   Calculer l'estimation de la majoration pour une convention donnée dans la tranche des premiers 500$ investis selon la date de fin donnée.  
                    Stratégie: Trouver la demande d'IQEE la plus récente ayant reçu de la majoration et déduire à partir de ces informations le montant anticipé.
                            
Facette         :   IQÉÉ
Reférence       :   Guide du fiduciaire Revenu Québec sur l'IQEE et Rapport mensuel de l'estimation de l'IQEE à recevoir.

Parametres d'entrée :    
    Parametres                          Description
    --------------------------------    ------------------------------------------------
    iID_Convention                      ID de la convention concernée par l'appel
    iID_Beneficiaire                    ID du bénéficiaire
    mTotal_Cotisations_Subventionnables Montant des cotisations subventionnables
    dtDate_Fin                          Date de fin de la période considérée par l'appel

Paramètres de sortie:    
    Champ                               Description
    ---------------------------         ----------------------------------------------------
    iID_Convention                      Numéro identifiant de la convention
    iID_Beneficiaire                    Numéro identifiant du bénéficiaire
    dtDate_Fin                          Date de fin concernée
    mMontantMajoration                  Montant de la majoration estimée par les calculs.
    fPourcentageMajoration              Pourcentage de majoration déduit à être versé.
    mTotal_Cotisations_Maximum500       Montant maximum de subvention pouvant être versé pour l'année.
                                                        
Exemple d'appel:
    SELECT * FROM dbo.fntIQEE_EstimerMajorationARecevoir (987654, 1234, 250.25,'2011-12-19')

Paramètres de sortie : La majoration (MMQ) de l'IQEE estimé

Historique des modifications :
    Date        Programmeur             Description
    ----------  --------------------    -----------------------------------------------------------
    2014-02-07  Stéphane Barbeau        Création de la fonction
    2015-11-23  Stéphane Barbeau        Ajout logique estimation 3% pour nouveaux contrats
    2016-02-19  Steeve Picard           Retrait des 2 derniers paramètres de « fnIQEE_ConventionConnueRQ »
    2017-11-09  Steeve Picard           Ajout du paramètre «siAnnee_Fiscale» à la fonction «fnIQEE_ConventionConnueRQ»
    2017-12-05  Steeve Picard           Élimination du paramètre «dtReference» dans l'appel à la fonction «fnIQEE_ConventionConnueRQ» qui retourne maintenant la date 
    2018-02-08  Steeve Picard           Déplacement de «siAnnee_Fiscale» de la table «tblIQEE_Fichiers» vers les tables d'évèments
****************************************************************************************************/
CREATE FUNCTION dbo.fntIQEE_EstimerMajorationARecevoir ( @iID_Convention INT , @iID_Beneficiaire INT,  @mTotal_Cotisations_Subventionnables MONEY,@dtDate_Fin DATETIME )    
RETURNS @tblIQEE_Majoration TABLE
(
    iID_Convention  INTEGER NOT NULL,
    iID_Beneficiaire INTEGER NOT NULL,
    dtDate_Fin DATETIME NOT NULL,
    mMontantMajoration MONEY NOT NULL,
    fPourcentageMajoration FLOAT NOT NULL,
    mTotal_Cotisations_Maximum500 MONEY NOT NULL    
)
AS
BEGIN
    DECLARE @fPourcentageMajoration  float
    DECLARE @mTotal_Cotisations_Maximum500 Money
    DECLARE @mMontantMajoration Money
    DECLARE @tiID_Justification_RQ tinyInt

    SELECT top 1 
        @tiID_Justification_RQ = isNULL(RD.tiID_Justification_RQ,0)
    FROM 
        dbo.tblIQEE_ReponsesDemande RD
        JOIN dbo.tblIQEE_Demandes D ON D.iID_Demande_IQEE = RD.iID_Demande_IQEE
        JOIN dbo.tblIQEE_TypesReponse TR ON TR.tiID_Type_Reponse = RD.tiID_Type_Reponse
                                        AND TR.vcCode IN ('EXM','NEM')
    WHERE 
        D.iID_Convention = @iID_Convention
        AND D.siAnnee_Fiscale <= YEAR(@dtDate_Fin)
    ORDER BY 
        RD.iID_Reponse_Demande DESC
    
    -- Déterminer le pourcentage de majoration à appliquer
    --  12    Le revenu familial est plus élevé que la limite du revenu moyen (0 % majoration)
    --  13    Le revenu familial est considéré comme moyen (5 % majoration)
    --  14    Le revenu familial est considéré comme faible (10 % majoration)
                
    IF @tiID_Justification_RQ = 14              -- Le revenu familial est considéré comme faible (10 % majoration)
        SET @fPourcentageMajoration  = 0.1
    
    ELSE IF @tiID_Justification_RQ  = 13        -- Le revenu familial est considéré comme moyen (5 % majoration)
        SET @fPourcentageMajoration = 0.05
    
    ELSE IF @tiID_Justification_RQ  = 12        -- Le revenu familial est considéré comme élevé (0 % majoration)
        SET @fPourcentageMajoration = 0.00
    
    ELSE IF dbo.fnIQEE_ConventionConnueRQ(@iID_Convention, YEAR(@dtDate_Fin)) IS NULL
        SET @fPourcentageMajoration  = 0.03     -- S'agit d'un nouveau contrat qui n'a jamais eu de T02 envoyé
    
    ELSE  
        SET @fPourcentageMajoration = 0.00

    -- Limiter à 500$ les cotisations subventionnables pour 1'année
    IF @mTotal_Cotisations_Subventionnables  > 500
        SET @mTotal_Cotisations_Maximum500 = 500
    ELSE
        SET @mTotal_Cotisations_Maximum500 = @mTotal_Cotisations_Subventionnables 
        
    SET @mMontantMajoration = isNULL(ROUND(@mTotal_Cotisations_Maximum500 * @fPourcentageMajoration,2),0)
        
    -- Retourner les valeurs
    INSERT @tblIQEE_Majoration (
        iID_Convention, iID_Beneficiaire, dtDate_Fin, mMontantMajoration, fPourcentageMajoration, mTotal_Cotisations_Maximum500
    )
    VALUES (
        @iID_Convention, @iID_Beneficiaire, @dtDate_Fin, @mMontantMajoration, @fPourcentageMajoration, @mTotal_Cotisations_Maximum500
    )
                
    RETURN     
END
