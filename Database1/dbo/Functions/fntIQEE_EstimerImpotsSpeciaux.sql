/****************************************************************************************************
Code de service : fntIQEE_EstimerImpotsSpeciaux
Nom du service  : EstimerImpotsSpeciaux
But             : Calculer l'estimation de la majoration pour une convention donnée.  
                  Stratégie: Trouver la demande d'IQEE la plus récente ayant reçu de la majoration et déduire à partir 
                             de ces informations le montant anticipé.
Facette         : IQÉÉ
Reférence       : Guide du fiduciaire Revenu Québec sur l'IQEE et Rapport mensuel de l'estimation de l'IQEE à recevoir.

Parametres d'entrée :    
    Parametres                      Description
    ----------------------------    ------------------------------------------------------------------
    cCode_ImpotSpecial              Code du sous-type d'impôt spécial
    iID_Convention                  ID de la convention concernée par l'appel
    dtDate_Fin                      Date de fin de la période considérée par l'appel
    iID_Fichier_IQEE                ID du fichier IQÉÉ

Paramètres de sortie:    
    Champ                       Description
    ------------------------    ---------------------------------
    dtDate_Evenement            Date de fin concernée
    mIQEE_Crédit_de_base        Montant du crédit base estimée par les calculs.
    mIQEE_Majoration            Montant de la majoration estimée par les calculs.
    mIQEE_Impot_Total           Montant total estimée par les calculs.

Exemple d'appel:
    SELECT * FROM DBO.[fntIQEE_EstimerImpotsSpeciaux] (987654, 1234, 250.25,'2011-12-19')

Historique des modifications :
            
    Date        Programmeur                Description                        Référence
    ----------    --------------------    ---------------------------        ---------------
    2014-02-11    Stéphane Barbeau        Création de la fonction
    2016-03-01    Steeve Picard           Déduire le montant de RIN avec preuve du total de cotisation subventionnable à partir de 2016
    2016-06-09    Steeve Picard           Modification au niveau des paramètres de la fonction «dbo.fntIQEE_CalculerMontantsDemande»
    2017-04-07    Pierre-Luc Simard        Remplacer la variable @mCotisations_Donne_Droit_IQEE (Toujours NULL) par @mIQEE_Crédit_de_base * 10
****************************************************************************************************/
CREATE FUNCTION [dbo].[fntIQEE_EstimerImpotsSpeciaux] ( 
    @cCode_ImpotSpecial Char(2), 
    @iID_Convention INT , 
    @dtDate_Fin DATETIME, 
    @iID_Fichier_IQEE INT
)    
RETURNS @tblIQEE_ImpotsSpeciaux TABLE
(
    dtDate_Evenement  DATETIME NOT NULL, 
    mIQEE_Crédit_de_base MONEY NOT NULL,
    mIQEE_Majoration  MONEY NOT NULL,
    mIQEE_Impot_Total MONEY NOT NULL
)
AS
BEGIN

    DECLARE @mSolde_IQEE MONEY
    DECLARE @mIQEE_ImpotSpecial MONEY
    DECLARE @mIQEE_Crédit_de_base MONEY
    DECLARE @mIQEE_Majoration MONEY
    DECLARE @mSolde_IQEE_Base MONEY
    DECLARE @mSolde_IQEE_Majore MONEY
    Declare @siAnnee_Fiscale smallint
    Declare @mCotisations_Retirees Money
    Declare @mTotal_Cotisations_Subventionnables Money,
            @mTotal_RIN_AvecPreuve MONEY
    Declare @mCotisations_Donne_Droit_IQEE Money
    Declare @dtDate_Evenement datetime

    set @siAnnee_Fiscale = year(@dtDate_Fin) 


    IF @cCode_ImpotSpecial = '91' OR @cCode_ImpotSpecial = '01'
        BEGIN 

            -- Impôts Spéciaux 91
            SET @mSolde_IQEE = [dbo].[fnIQEE_CalculerSoldeIQEE_Convention](@iID_Convention,@dtDate_Fin)
            SET @mIQEE_ImpotSpecial = @mSolde_IQEE

            -- Division de l'impôt spécial
            If @mIQEE_ImpotSpecial > 0
                BEGIN
                    -- Compte tenu qu'il s'agit d'une convention fermée, il faut tenir compte de la date du jour et non pas de @dtDate_Fin_Cotisation            
                    SET @mIQEE_Crédit_de_base = dbo.fnIQEE_CalculerSoldeCreditBase_Convention(@iID_Convention ,@dtDate_Fin)
                    
                    -- Compte tenu qu'il s'agit d'une convention fermée, il faut tenir compte de la date du jour et non pas de @dtDate_Fin_Cotisation            
                    SET @mIQEE_Majoration = dbo.fnIQEE_CalculerSoldeMajoration_Convention(@iID_Convention ,@dtDate_Fin)

                    IF (@mIQEE_Crédit_de_base + @mIQEE_Majoration) > 0
                        
                        SET @mSolde_IQEE_Base = @mIQEE_Crédit_de_base
                        
                        -- Formule de répartition si l'impôt spécial dépend soit du solde ou de la JVM
                        -- Multiplier avant de diviser: ça fait moins de divergence sur les décimales 
                        --et cela garantie que l'opération IQE de décaissement donnera une valeur de 0 au solde.
                        --SET @mSolde_IQEE_Base = @mIQEE_Crédit_de_base * @mIQEE_ImpotSpecial / (@mIQEE_Crédit_de_base + @mIQEE_Majoration) 
                    ELSE
                        SET @mSolde_IQEE_Base = 0
                                
                    SET @mSolde_IQEE_Majore = @mIQEE_ImpotSpecial - @mSolde_IQEE_Base
                END
            ELSE
                BEGIN
                            SET @mSolde_IQEE_Base  = 0
                            SET @mSolde_IQEE_Majore = 0
                            SET @mIQEE_ImpotSpecial = 0
                END
            
            SET @dtDate_Evenement= @dtDate_Fin  

        END 

    IF @cCode_ImpotSpecial = '22'
                            
        BEGIN 
        
            SELECT @mTotal_Cotisations_Subventionnables = mTotal_Cotisations_Subventionnables,
                   @mTotal_RIN_AvecPreuve = mTotal_RIN_AvecPreuve
            FROM [dbo].[fntIQEE_CalculerMontantsDemande](@iID_Convention,
                                             CAST(CAST(@siAnnee_Fiscale AS VARCHAR(4))+'-01-01' AS DATETIME),
                                             CAST(CAST(@siAnnee_Fiscale AS VARCHAR(4))+'-12-31' AS DATETIME),
                                             DEFAULT)

            -- Déduire le montant de RIN avec preuve du total de cotisation subventionnable à partir de l'année 2016
            IF @siAnnee_Fiscale > 2015
                SET @mTotal_Cotisations_Subventionnables = @mTotal_Cotisations_Subventionnables + @mTotal_RIN_AvecPreuve

            IF @mTotal_Cotisations_Subventionnables < 0.00
                BEGIN
                    ----------------------------------------------------------------------------------------
                    -- Rechercher ou calculer les informations requises pour produire une transaction valide
                    ----------------------------------------------------------------------------------------

                    set   @mCotisations_Retirees = @mTotal_Cotisations_Subventionnables*-1
                    

                    -- S'il y a eu un transfert OUT total et que la convention est fermée, prendre la date du transfert comme
                    -- date d'événement au lieu du 31 décembre de l'année fiscale
                    SELECT @dtDate_Evenement = ISNULL(MAX(T.dtDate_Transfert),@dtDate_Fin)
                    FROM tblIQEE_Transferts T
                         JOIN tblIQEE_SousTypeEnregistrement ST ON ST.iID_Sous_Type = T.iID_Sous_Type
                                                               AND ST.cCode_Sous_Type = '01'
                         JOIN tblIQEE_Fichiers F ON F.iID_Fichier_IQEE = T.iID_Fichier_IQEE 
                                                AND F.iID_Fichier_IQEE = @iID_Fichier_IQEE
                                                
                         JOIN tblIQEE_ImpotsSpeciaux TIS ON TIS.iID_Convention = T.iID_Convention
                         JOIN tblIQEE_SousTypeEnregistrement ST2 ON ST2.iID_Sous_Type = TIS.iID_Sous_Type
                                                                AND ST2.cCode_Sous_Type IN ('91','51')
                         JOIN tblIQEE_Fichiers F2 ON F2.iID_Fichier_IQEE = TIS.iID_Fichier_IQEE 
                                                AND F2.iID_Fichier_IQEE = @iID_Fichier_IQEE

                    WHERE T.iID_Convention = @iID_Convention
                      AND T.cStatut_Reponse IN ('A','R')

                    
                    SET @mIQEE_Crédit_de_base = dbo.fnIQEE_CalculerSoldeCreditBase_Convention(@iID_Convention,@dtDate_Evenement)
                    
                    SET @mIQEE_Majoration = dbo.fnIQEE_CalculerSoldeMajoration_Convention(@iID_Convention,@dtDate_Evenement)

                         IF @mIQEE_Crédit_de_base > 0
                            SET @mCotisations_Donne_Droit_IQEE = @mIQEE_Crédit_de_base * 10
                         ELSE
                            SET @mCotisations_Donne_Droit_IQEE = 0
        
                            -- Calcul de l'impôt spécial
                            -- Égal au mimimum entre
                            --        1- Solde du compte de l'IQÉÉ immédiatement avant la fin de l'année
                            --          2- Montant de la formule (A x C) / B
                            -- Formule de Revenu Québec (A x C) / B
                            -- A: Solde du compte de l'IQEE immédiatement avant la fin de l'année(@mIQEE_Majoration + @mIQEE_Crédit_de_base).
                            -- B: Total des cotisations versées au régime immédiatement avant la fin de l'année ayant donné droit à l'IQEE.
                            -- C: Montant de la cotisation  retirée du régime à l'égard de laquelle un IQÉÉ a été reçu immédiatement avant la fin de l'année.
                    
                            SET @mSolde_IQEE = @mIQEE_Crédit_de_base + @mIQEE_Majoration
                            
                            IF @mSolde_IQEE < 0 
                                SET @mSolde_IQEE = 0
                                
                                
                            SET @mCotisations_Retirees = abs(@mCotisations_Retirees)
                                   IF @mCotisations_Donne_Droit_IQEE > 0
                               SET @mIQEE_ImpotSpecial = round((@mSolde_IQEE * @mCotisations_Retirees) / @mCotisations_Donne_Droit_IQEE, 2)
                                   ELSE
                                      SET @mIQEE_ImpotSpecial = 0
                        
                            -- Déduction du plus petit montant de l'impôt spécial
                            If @mIQEE_ImpotSpecial > @mSolde_IQEE
                                BEGIN
                                    SET @mIQEE_ImpotSpecial= @mSolde_IQEE
                                END
                                                    
                            -- Division de l'impôt spécial
                            IF (@mIQEE_Crédit_de_base + @mIQEE_Majoration) > 0
                                -- Multiplier avant de diviser: ça fait moins de divergence sur les décimales 
                                -- et cela garantie que l'opération IQE de décaissement donnera une valeur de 0 au solde.
                                SET @mSolde_IQEE_Base = round(@mIQEE_Crédit_de_base * @mIQEE_ImpotSpecial / (@mIQEE_Crédit_de_base + @mIQEE_Majoration),2) 
                            ELSE
                                SET @mSolde_IQEE_Base = 0
                                
                            SET @mSolde_IQEE_Majore = @mIQEE_ImpotSpecial - @mSolde_IQEE_Base        
        
        
            END            
        
        END

            INSERT @tblIQEE_ImpotsSpeciaux (dtDate_Evenement, mIQEE_Crédit_de_base , mIQEE_Majoration, mIQEE_Impot_Total )
            VALUES                       (@dtDate_Evenement, @mSolde_IQEE_Base,@mSolde_IQEE_Majore ,@mIQEE_ImpotSpecial)

    RETURN     

END