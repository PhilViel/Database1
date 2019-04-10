/****************************************************************************************************
Code de service        :        fnCONV_ValiderChangementBeneficiaire
Nom du service        :        1.4.1 Valider le changement de bénéficiaire
But                    :        Effectuer plusieurs validations sur le changement de bénéficiaire
Description            :        Ce service est utilisé lors du changement de bénéficiaire. Plusieurs validations
                            entre le bénéficiaire actuel et le nouveau bénéficiaire sont effectuées. Certaines
                            validations seront propres au régime.
                            
Facette                :        CONV
Reférence            :        Document P171U - Services du noyau de la facette CONV - Conventions (section 1.4)


Parametres d'entrée :    Parametres                                        Description                                    Obligatoire
                        ----------                                        ----------------                            --------------                       
                        iID_Convention                                    Identifiant unique de la convention                        
                        iID_Nouveau_Beneficiaire                        Identifiant unique du nouveau bénéficiaire
                        vcCode_Raison                                    Raison du changement de bénéficiaire
                        bLien_Frere_Soeur_Avec_Ancien_Beneficiaire        Indicateur oui/non du lien frère-soeur entre 
                                                                        le nouveau et le bénéficiaire actuel
                        bLien_Sang_Avec_Souscripteur_Initial            Indicateur oui/non du lien de sang entre le
                                                                        nouveau bénéficiaire et le souscripteur 
                                                                        initial

Exemples d'appel:
                    SELECT dbo.[fnCONV_ValiderChangementBeneficiaire](339878,251051,'DEC',1,1)

Parametres de sortie :  Table                        Champs                                        Description
                        -----------------            ---------------------------                    --------------------------
                        S/O                            vcCode_Message                                Liste des numéros de message à afficher à l'utilisateur                

Historique des modifications :

        Date        Programmeur                 Description                            Référence
        ----------  ------------------------    ----------------------------        ---------------
        2009-10-19  Jean-François Gauthier      Création de la fonction
        2009-10-21  Jean-François Gauthier      Modification pour le calcul des montants totaux de subventions et de cotisations
        2009-11-03  Jean-François Gauthier      Ajout du paramètre de début à l'appel de la fonction fntIQEE_ObtenirIQEE
        2009-12-15  Jean-François Gauthier      Mise en commentaire de l'appel à fntIQEE_ObtenirIQEE
        2010-02-08  Jean-François Gauthier      Remplacement de fntIQEE_ObtenirIQEE par fntOPER_ObtenirMntIQEERelDep au cas où il faudrait réactiver le tout
        2010-02-11  Pierre Paquet               Ajustement sur la validation de la vérification de l'âge.
        2010-02-17  Pierre Paquet               Ajustement sur la validation #7 afin d'éviter 2 messages concernant l'âge.
        2010-02-22  Pierre Paquet               Validation 004 - Remplacer le NULL par zéro.
                                                Ajustement de la validation de .fnIQEE_RemplacementBeneficiaireReconnu
        2010-02-22  Jean-François Gauthier      Modification afin de faire la somme des montants souscrits pour l'ensemble de conventions du bénéficiaire
                                                Modification afin d'ajouter au montant total déposé, les montants provenant de la "nouvelle" convention du bénéficiaire
        2010-03-01  Pierre Paquet               Utilisation de fnIQEE_RemplaceerBeneficiaireReconnu avec 7 paramètres.
        2010-04-27  Pierre Paquet               Ajout de la vérification de  AND @vcCode_Raison <> 'INV'
        2010-04-28  Pierre Paquet               Correction: Le calcul de @mMntTotalSubvention n'était pas correct.
        2010-05-14  Pierre Paquet               Correction: Affichage des messages d'avertissement.
                                                            Calcul du montant dépot, il faut ajouter les frais.
                                                            Ajustement de @mMntTotalSubvention
        2016-11-25  Steeve Picard               Changement d'orientation de la valeur de retour de «fnIQEE_RemplacementBeneficiaireReconnu»
 ****************************************************************************************************/
CREATE FUNCTION [dbo].[fnCONV_ValiderChangementBeneficiaire]
(
    @iID_Convention                                    INT
    ,@iID_Nouveau_Beneficiaire                        INT
    ,@vcCode_Raison                                    VARCHAR(6)    
    ,@bLien_Frere_Soeur_Avec_Ancien_Beneficiaire    BIT    
    ,@bLien_Sang_Avec_Souscripteur_Initial            BIT    
)
RETURNS VARCHAR(4000)
AS
    BEGIN
        DECLARE @vcCode_Message                    VARCHAR(4000)
                ,@iID_Plan                        INT
                ,@vcPlanDesc                    VARCHAR(75)
                ,@dAgeBeneficiaire                DECIMAL(6,0)
                ,@dAgeValidationBeneficiaire    DECIMAL(6,0)
                ,@dAgeNouveauBeneficiaire        DECIMAL(6,0)
                ,@mMntSCEESup                    MONEY
                ,@mMntSCEE                        MONEY
                ,@mMntPlafondAVie                MONEY
                ,@mMntMaxAVie                    MONEY
                ,@mMntTotalDepose                MONEY
                ,@mMntTotalSubvention            MONEY
                ,@mMntIQEE                        MONEY
                ,@iID_Ancien_Beneficiaire       INT

        -- Initialisation 
        SET @vcCode_Message        = ''
        SELECT 
                @mMntSCEE        = SUM(f.fCESG + f.fCESGINT)
                ,@mMntSCEESup    = SUM(f.fACESG + f.fACESGINT) 
        FROM 
            fntPCEE_ObtenirSubventionBons(@iID_Convention,NULL,GETDATE()) f 

        SELECT
                @mMntSCEE        = ISNULL(@mMntSCEE,0)
                ,@mMntSCEESup    = ISNULL(@mMntSCEESup,0)
        
        SET @mMntPlafondAVie    = (SELECT cfg.LifeCeiling FROM dbo.Un_BeneficiaryCeilingCfg cfg)
        SET @mMntMaxAVie        = (SELECT d.MaxLifeGovernmentGrant FROM dbo.Un_Def d)
        
        -- 2010-02-22 : JFG : AJOUT DU MONTANT DÉPOSÉ DE LA NOUVELLE CONVENTION
        SET @mMntTotalDepose    =    ((SELECT 
                                        ISNULL(SUM(ct.Cotisation),0) + ISNULL(SUM(ct.fee),0)
                                    FROM
                                        dbo.Un_Unit u
                                        INNER JOIN dbo.Un_Cotisation ct
                                            ON u.UnitID = ct.UnitId
                                        INNER JOIN dbo.Un_Convention c
                                            ON c.ConventionID = u.ConventionID
                                    WHERE
                                        c.BeneficiaryID = @iID_Nouveau_Beneficiaire)
                                    +
                                    (SELECT 
                                        ISNULL(SUM(ct.Cotisation),0) + ISNULL(SUM(ct.fee),0)
                                    FROM
                                        dbo.Un_Unit u
                                        INNER JOIN dbo.Un_Cotisation ct
                                            ON u.UnitID = ct.UnitId
                                        INNER JOIN dbo.Un_Convention c
                                            ON c.ConventionID = u.ConventionID
                                    WHERE
                                        c.ConventionID = @iID_Convention))

        -- Correction 2010-04-28
        SET @mMntTotalSubvention =  (SELECT 
                                        SUM(ce.fCESG +        -- SCEE 
                                            ce.fACESG)        -- SCEE+ 
                                    --        ce.fCLB   +        -- BEC 
                                    --        ce.fPG)            -- Subvention provinciale 
                                        FROM    
                                            dbo.Un_Convention c
                                            INNER JOIN dbo.Un_CESP ce
                                                ON c.ConventionID = ce.ConventionID
                                        WHERE 
                                            c.BeneficiaryID = @iID_Nouveau_Beneficiaire) 

        -- Récupérer la somme de SCEE de la convention actuel avant le changement de bénéficiaire.
        -- On ajoute 
        SET @mMntTotalSubvention =  @mMntTotalSubvention + (SELECT SUM(ce.fCESG + ce.fACESG) -- SCEE et SCEE+
                                        FROM    
                                            dbo.Un_CESP ce
                                        WHERE 
                                            ce.conventionID  = @iID_Convention) 
        


        -- 2009-12-15 : Mise en commentaire
        -- SET @mMntIQEE             =    ISNULL((SELECT f.mMntIQEE FROM dbo.fntOPER_ObtenirMntIQEERelDep(@iID_Convention, NULL, GETDATE()) f),0)
                
        -- 1. Récupérer le régime (PlanID) de la convention reçue en paramètre
        SELECT    
            @iID_Plan        =    c.PlanID
            ,@vcPlanDesc    =    p.PlanDesc
            ,@iID_Ancien_Beneficiaire = c.beneficiaryID
        FROM
            dbo.Un_Convention c
            INNER JOIN dbo.Un_Plan p
                ON p.PlanID = c.PlanID
        WHERE
            c.ConventionID = @iID_Convention


        -- 2. Récupérer l'âge de la validation d'un changement de bénéficiaire selon le régime
        SELECT
            @dAgeValidationBeneficiaire = dbo.fnGENE_ObtenirParametre('CONV_AGE_CHANG_BENEF', NULL, @iID_Plan, NULL, NULL, NULL, NULL)

        -- 3. Récupérer l'âge du bénéficiaire actuel et du nouveau bénéficiaire
        SELECT
            @dAgeBeneficiaire = dbo.fn_Mo_Age(h.BirthDate, GETDATE())
        FROM
            dbo.Un_Convention c
            INNER JOIN dbo.Mo_Human h
                ON c.BeneficiaryID = h.HumanID
        WHERE
            c.ConventionID = @iID_Convention    

        SELECT
            @dAgeNouveauBeneficiaire = dbo.fn_Mo_Age(h.BirthDate, GETDATE())
        FROM
            dbo.Mo_Human h
        WHERE
            h.HumanID = @iID_Nouveau_Beneficiaire

        -- 4. Vérification du régime Universitas
        IF @vcPlanDesc = 'Universitas' AND @dAgeBeneficiaire >= @dAgeValidationBeneficiaire AND @vcCode_Raison <> 'DEC' AND @vcCode_Raison <> 'INV'
            BEGIN
                SET @vcCode_Message = '001'        
            END

        -- 5. Vérification du régime REEEFlex
        IF @vcPlanDesc = 'Reeeflex' AND @dAgeBeneficiaire >= @dAgeValidationBeneficiaire AND @vcCode_Raison <> 'DEC'  AND @vcCode_Raison <> 'INV'
            BEGIN
                SET @vcCode_Message = '002'        
            END



        -- 6. Vérification du lien entre bénéficiare et du montant SCEE+
    --    IF (@bLien_Frere_Soeur_Avec_Ancien_Beneficiaire = 0) AND (@mMntSCEESup IS NULL)
        IF (@bLien_Frere_Soeur_Avec_Ancien_Beneficiaire = 0) AND (@mMntSCEESup > 0 )
            BEGIN
                SET @vcCode_Message = @vcCode_Message + ',004'
            END

        -- 7. Vérification du lien entre bénéficiaire et souscripteur initial ainsi que du montant SCEE+
        IF (@bLien_Frere_Soeur_Avec_Ancien_Beneficiaire = 0) AND (@bLien_Sang_Avec_Souscripteur_Initial = 0) AND  (@mMntSCEE > 0) AND (@mMntSCEESup = 0)
            BEGIN
                SET @vcCode_Message = @vcCode_Message + ',005'
            END    
            ELSE
            -- Vérification de l'âge du nouveau bénéficiaire est plus grande que 21 ans.
            IF  (@dAgeNouveauBeneficiaire > 21) OR (@bLien_Frere_Soeur_Avec_Ancien_Beneficiaire = 0 AND @dAgeBeneficiaire > 21 AND @dAgeNouveauBeneficiaire < @dAgeValidationBeneficiaire)
            BEGIN
                SET @vcCode_Message = @vcCode_Message + ',005'
            END
    
        -- 8. Vérification du régime versus l'âge du nouveau bénéficiaire
        IF (@vcPlanDesc IN ('Universitas', 'Reeeflex')) AND (@dAgeNouveauBeneficiaire > @dAgeBeneficiaire) AND (@dAgeNouveauBeneficiaire < @dAgeValidationBeneficiaire)
            BEGIN
                SET @vcCode_Message = @vcCode_Message + ',006'
            END
        --    ELSE IF @dAgeBeneficiaire < @dAgeNouveauBeneficiaire -- Gérer les cas sans âge de validation.
        --    BEGIN
        --        SET @vcCode_Message = @vcCode_Message + ',003'
        --    END
            



        -- 10. Vérification des montants souscrits et du montant de plafond à vie
        -- 2010-02-22 : JFG :    Il faut faire la somme des montants souscrits pour toutes les conventions
        --                        du bénéficiaire        
        IF (
            dbo.fnCONV_ObtenirMontantSouscritConvention(@iID_Convention,NULL,GETDATE()) 
            +
            (SELECT
                SUM(dbo.fnCONV_ObtenirMontantSouscritConvention(c.ConventionID,NULL,GETDATE()))
            FROM
                dbo.Un_Convention c
            WHERE
                c.BeneficiaryID = @iID_Nouveau_Beneficiaire    
                AND
                c.ConventionID <> @iID_Convention)
            ) > @mMntPlafondAVie
            BEGIN
                SET @vcCode_Message = @vcCode_Message + ',007'
            END

        -- 11. Vérification du montant total déposé dans toutes les conventions du nouveau bénéficiaire et montant de plafond à vie
        IF @mMntTotalDepose > @mMntPlafondAVie
            BEGIN
                SET @vcCode_Message = @vcCode_Message + ',008'
            END

        -- 12. Vérification du montant total des subventions reçu par le nouveau bénéficiaire et du montant maximum à vie toléré par le gouvernement
        IF @mMntTotalSubvention > @mMntMaxAVie
            BEGIN
                SET @vcCode_Message = @vcCode_Message + ',009'
            END
        
    /*    2009-12-15 : Mise en commentaire
        -- 13. Validation du montant IQEE
        IF (@mMntIQEE > 0) AND 
                                NOT ((@dAgeNouveauBeneficiaire < 21) AND (@bLien_Frere_Soeur_Avec_Ancien_Beneficiaire = 1))
                            AND 
                                NOT ((@dAgeBeneficiaire < 21) AND (@dAgeNouveauBeneficiaire < 21) AND (@bLien_Sang_Avec_Souscripteur_Initial = 1))
            BEGIN
                SET @vcCode_Message = @vcCode_Message + ',010'
            END*/

        -- 13. Valider si le changement de bénéficiaire est valide pour l'IQEE
        --IF dbo.fnIQEE_RemplacementBeneficiaireReconnu(@iID_Nouveau_Beneficiaire) > 0
        IF dbo.fnIQEE_RemplacementBeneficiaireReconnu(NULL, @iID_Convention, @iID_Ancien_Beneficiaire, @iID_Nouveau_Beneficiaire, GETDATE(), @bLien_Frere_Soeur_Avec_Ancien_Beneficiaire, @bLien_Sang_Avec_Souscripteur_Initial) = 0
            BEGIN
                SET @vcCode_Message = @vcCode_Message + ',010'
            END

        IF LEFT(@vcCode_Message,1) = ','
            BEGIN
                SET @vcCode_Message = RIGHT(@vcCode_Message, LEN(@vcCode_Message) -1)
            END

        RETURN @vcCode_Message
    END
