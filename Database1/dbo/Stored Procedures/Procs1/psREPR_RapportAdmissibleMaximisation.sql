/********************************************************************************************************************
Copyrights (c) 2009 Gestion Universitas inc
Nom                 :	psREPR_RapportAdmissibleMaximisation
Description         :	Procédure stockée du rapport : Liste des bénéficiaire de 12 ans et plus
Valeurs de retours  :	Dataset

exec psREPR_RapportAdmissibleMaximisation 690691, NULL
exec psREPR_RapportAdmissibleMaximisation 690691, '2020-04-20'
    
Historique des modifications:
        Date			Programmeur			Description
        ----------	------------------	-----------------------------------------	
        2016-09-06	Maxime Martel		Création du service	
        2016-09-15	Steve Bélanger		Ajout du calcul our trouver le montant de cotisation additionnelle pour maximiser:
								        Boucler sur toutes les conventions d'un bénéficiaire de 12 ans et plus,
								        demandé via un souscripteur
								            (A) Trouver l'âge du bénéficiaire au 31 décembre de l'année courante.
								            (B) Calculer le maximum de cotisation possible : multiplier (A) par 2500
								            (C) Additionner les montants de cotisation et de frais à la date du jour
								            (D) Calculer les montants de cotisation à venir, de la date du jour au 31 décembre de l'année courante
								            (E) Choisir le plus petit montant entre 36 000 et (B)
								        Montant de cotisation additionnelle pour maximiser = (E) - (C) - (D)
        2016-09-16  Steeve Picard       Optimisation et correction du montant en (C)
        2016-10-12  Steeve Picard       Doit tenir compte de la date du dernier dépôt pour chaque groupe d'unité
        2016-11-04  Pierre-Luc Simard   Retirer les adresses post-datées et filtrer pour conserver uniquement les provinces QC et NB
        2016-11-24  Steeve Picard       Correction du calcul de «EstimatedCotisationAndFee»
        2016-03-06  Maxime Martel       TI-5769 : Indiquer "Invalide" pour le courriel, code postal et ville
        2017-03-15  Steeve Picard       Utilisation des fonctions
        2017-03-22  Pierre-Luc Simard   Ajout du champ qui indique que le souscripteur a au moins une convention ayant un prêt
        2017-04-18  Pierre-Luc Simard   Utilisation des valeurs persistées dans la convention et le bénéficiaire si demandé en date du jour
                                        Utlisation de la procédure psCONV_IdentifierConventionMaximisable si demandé à une autre date
        2018-09-26  Pierre-Luc Simard   Ajout de l'audit dans la table tblGENE_AuditHumain
*********************************************************************************************************************/
CREATE PROCEDURE [dbo].[psREPR_RapportAdmissibleMaximisation] (
    @RepID INT = NULL,
    @EnDateDu DATE = NULL,
    @BeneficiaryID INT = NULL) -- Pas utilisé
AS
BEGIN
    
    CREATE TABLE #tSouscBenef (
        SubscriberID INTEGER NOT NULL,
        BeneficiaryID INTEGER NOT NULL,
        RepID INTEGER NOT NULL,
        bEstEligiblePret BIT NULL,
        SMaximisationREEE BIT NULL,
        BMaximisationREEE BIT NULL,
        mMaximisation_MontantDisponible MONEY NULL)
        --CONSTRAINT #PK_tSouscBenef_SubscriberIDBeneficiaryID PRIMARY KEY (SubscriberID, BeneficiaryID))

    IF CAST(ISNULL(@EnDateDu, GETDATE()) AS DATE) = CAST(GETDATE() AS DATE) -- En date du jour, on utilise les valeurs persistées
    BEGIN   
        -- Liste des souscripteurs et des bénéficiaires ayant au moins une convention maximisable
        INSERT INTO #tSouscBenef(
            SubscriberID,
            BeneficiaryID,
            RepID,
            bEstEligiblePret,
            SMaximisationREEE,
            BMaximisationREEE,
            mMaximisation_MontantDisponible)
        SELECT 
            C.SubscriberID, 
            C.BeneficiaryID, 
            S.RepID,
            bEstEligiblePret = MAX(CASE WHEN ISNULL(C.bEstEligiblePret, 0) = 1 THEN 1 ELSE 0 END),
            SMaximisationREEE = CASE WHEN SM.SubscriberID IS NOT NULL THEN 1 ELSE 0 END, 
            BMaximisationREEE = MAX(ISNULL(C.tiMaximisationREEE, 0)), 
            B.mMaximisation_MontantDisponible 
        FROM dbo.Un_Convention C
        JOIN dbo.Un_Subscriber S ON S.SubscriberID = C.SubscriberID
        JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = C.BeneficiaryID
        LEFT JOIN (-- Liste des souscripteurs ayant une prêt
            SELECT DISTINCT
                C.SubscriberID
            FROM dbo.Un_Convention C
            JOIN Un_Subscriber S ON S.SubscriberID = C.SubscriberID
            WHERE S.RepID = ISNUll(@RepID, S.RepID)
                AND ISNULL(C.tiMaximisationREEE, 0) = 2
            ) SM ON SM.SubscriberID = S.SubscriberID
        WHERE S.RepID = ISNUll(@RepID, S.RepID)
            AND ISNULL(C.bEstMaximisable, 0) = 1 
        GROUP BY 
            C.SubscriberID, 
            C.BeneficiaryID,
            S.RepID,
            SM.SubscriberID,
            B.mMaximisation_MontantDisponible
    END 
    ELSE -- Pour une autre date, on utilise la procédure pour récupérer les valeurs à la date demandée
    BEGIN   
        CREATE TABLE #tConventionMaximisable (
            ConventionID INTEGER NOT NULL,
            SubscriberID INTEGER NOT NULL,
            BeneficiaryID INTEGER NOT NULL,
            RepID INTEGER NOT NULL,
            Age_Benef_31Dec INT NULL,
            mMaximisation_MontantDisponible MONEY NULL,
            tiMaximisationREEE TINYINT NULL,
            ConventionEligiblePret BIT NULL)
            --CONSTRAINT #PK_ConventionMaximisable_ConventionID PRIMARY KEY (ConventionID))
	    INSERT INTO #tConventionMaximisable 
		EXEC psCONV_IdentifierConventionMaximisable @RepID, NULL, NULL, @EnDateDu, NULL
        
        --SELECT * FROM #tConventionMaximisable CM

        -- Liste des souscripteurs et des bénéficiaires ayant au moins une convention maximisable
        INSERT INTO #tSouscBenef(
            SubscriberID,
            BeneficiaryID,
            RepID,
            bEstEligiblePret,
            SMaximisationREEE,
            BMaximisationREEE,
            mMaximisation_MontantDisponible)
        SELECT 
            C.SubscriberID, 
            C.BeneficiaryID, 
            C.RepID,
            bEstEligiblePret = MAX(CASE WHEN ISNULL(C.ConventionEligiblePret, 0) = 1 THEN 1 ELSE 0 END),
            SMaximisationREEE = CASE WHEN SM.SubscriberID IS NOT NULL THEN 1 ELSE 0 END, 
            BMaximisationREEE = MAX(ISNULL(C.tiMaximisationREEE, 0)), 
            C.mMaximisation_MontantDisponible
        FROM #tConventionMaximisable C
        LEFT JOIN (-- Liste des souscripteurs ayant une prêt
            SELECT DISTINCT
                C.SubscriberID
            FROM #tConventionMaximisable C
            WHERE ISNULL(C.tiMaximisationREEE, 0) = 2
            ) SM ON SM.SubscriberID = C.SubscriberID
        GROUP BY 
            C.SubscriberID, 
            C.BeneficiaryID,
            C.RepID,
            SM.SubscriberID,
            C.mMaximisation_MontantDisponible
    END

    IF OBJECT_ID('TEMPDB..#tSouscBenef') IS NOT NULL 
        SELECT
            SHumainID = S.SubscriberID,
            SLastName = HS.LastName,
            SFirstName = HS.FirstName,
            SSexID = HS.SexID,
            SLangName = CASE LS.LangName WHEN 'English' THEN 'Anglais' ELSE ISNULL(LS.LangName, 'Inconnu') END,
            STelephone = TEL.vcTelephone,
            SCellulaire = CEL.vcTelephone,
            SCourriel = CASE WHEN EM.bInvalide = 1 THEN '*** Invalide *** ' ELSE EM.vcCourriel END,
            SVille = CASE WHEN A.bInvalide = 1 THEN '*** Invalide *** ' ELSE A.vcVille END,
            SCodePostal = CASE WHEN A.bInvalide = 1 THEN '*** Invalide *** ' ELSE A.vcCodePostal END,
            BHumainID = SB.BeneficiaryID,
            BLastName = HB.LastName,
            BFirstName = HB.FirstName,
            BSexID = HB.SexID,
            BBirthDate = HB.BirthDate,
            BAge = YEAR(ISNULL(@EnDateDu, GETDATE())) - YEAR(HB.BirthDate),
            BLangName = CASE LB.LangName WHEN 'English' THEN 'Anglais' ELSE ISNULL(LB.LangName, 'Inconnu') END,                     
            MontantMaximisation = SB.mMaximisation_MontantDisponible,
            BenefSouscMaximise = CASE WHEN SB.BMaximisationREEE IN (1, 2) THEN 'OUI' ELSE 'NON' END,
            SouscEligiblePret = CASE WHEN SB.SMaximisationREEE = 1 THEN 'Prêt existant' 
                            ELSE CASE WHEN SB.bEstEligiblePret = 1 THEN 'Pré-qualifié' ELSE 'Non admissible' END 
                            END,  
            RName = LTRIM(HR.FirstName + ' ' + HR.LastName),
            RCode = R.RepCode,
            RStatut = CASE WHEN R.BusinessStart <= GETDATE() AND ISNULL(R.BusinessEnd, '9999-12-31') > GETDATE() THEN 'Actif' ELSE 'Inactif' END,
            EnDateDu = ISNULL(@EnDateDu, GETDATE())
        INTO #tpsREPR_RapportAdmissibleMaximisation
        FROM #tSouscBenef SB
        JOIN dbo.Un_Subscriber S ON S.SubscriberID = SB.SubscriberID
        JOIN dbo.Mo_Human HS ON HS.HumanID = SB.SubscriberID
        JOIN dbo.Mo_Human HB ON HB.HumanID = SB.BeneficiaryID
        JOIN dbo.Mo_Lang LS ON LS.[LangID] = HS.[LangID]
        JOIN dbo.Mo_Lang LB ON LB.[LangID] = HB.[LangID]
        JOIN fntGENE_ObtenirAdresseEnDate_PourTous(NULL, NULL, NULL, NULL) A ON A.iID_Source = SB.SubscriberID AND A.cType_Source = 'H'
        JOIN fntGENE_ObtenirAdresseEnDate_PourTous(NULL, NULL, NULL, NULL) AB ON AB.iID_Source = SB.BeneficiaryID AND AB.cType_Source = 'H'
        LEFT JOIN dbo.fntGENE_TelephoneEnDate_PourTous(GETDATE(), DEFAULT, 1, 1, 1) TEL ON TEL.iID_Source = SB.SubscriberID
        LEFT JOIN dbo.fntGENE_TelephoneEnDate_PourTous(GETDATE(), DEFAULT, 2, 1, 1) CEL ON CEL.iID_Source = SB.SubscriberID
        LEFT JOIN dbo.fntGENE_CourrielEnDate_PourTous(GETDATE(), DEFAULT, 1, 1) EM ON EM.iID_Source = SB.SubscriberID
        JOIN dbo.Un_Rep R ON R.RepID = SB.RepID
        JOIN dbo.Mo_Human HR ON HR.HumanID = R.RepID

    SELECT * FROM #tpsREPR_RapportAdmissibleMaximisation

    ----------------
    -- AUDIT - DÉBUT
    ----------------
    BEGIN 
        DECLARE 
            @vcAudit_Utilisateur VARCHAR(75) = dbo.GetUserContext(),
            @vcAudit_Contexte VARCHAR(75) = OBJECT_NAME(@@PROCID)
    
        -- Ajout de l'audit dans la table tblGENE_AuditHumain
        EXEC psGENE_AuditAcces 
            @vcNom_Table = '#tpsREPR_RapportAdmissibleMaximisation', 
            @vcNom_ChampIdentifiant = 'SHumainID', 
            @vcUtilisateur = @vcAudit_Utilisateur, 
            @vcContexte = @vcAudit_Contexte, 
            @bAcces_Courriel = 1, 
            @bAcces_Telephone = 1, 
            @bAcces_Adresse = 1
    --------------
    -- AUDIT - FIN
    --------------
    END 
    
END