/********************************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service        : psIQEE_CompleterTransactionsAnnulation
Nom du service        : Compléter les transactions d'annulation
Buts                 : Créer les transactions de demande d'IQÉÉ de type "reprise à 0" pour les transactions modifiant
                      une information pas amendable.
                      
                      Créer les transactions d'annulation.  
                      
                      Confirmer l'annulation des transactions suite aux demandes d'annulation.  
                      
                      Supprimer les demandes d'annulations manuelles qui ont été réalisées.
                      
Facette                : IQÉÉ

Paramètres d’entrée    :    Paramètre                    Description
                        --------------------------    -----------------------------------------------------------------
                        bFichier_Test                Indicateur si le fichier est crée pour fins d’essais ou si c’est
                                                    un fichier réel.  0=Fichier réel, 1=Fichier test.
                        iID_Session                    Identifiant de session identifiant de façon unique la création des
                                                    fichiers de transactions
                        dtDate_Creation_Fichiers    Date et heure de la création des fichiers identifiant de façon unique avec
                                                    identifiant de session, la création des    fichiers de transactions.
                                                    
Exemple d’appel        :    Cette procédure doit être appelée uniquement par "psIQEE_CreerFichiers".

Paramètres de sortie:    Table                        Champ                            Description
                          -------------------------    ---------------------------     ---------------------------------
                        S/O

Historique des modifications:
        Date            Programmeur                            Description                                
        ------------    ----------------------------------    -----------------------------------------
        2009-10-20        Éric Deshaies                        Création du service                            
        2012-11-27        Stéphane Barbeau                    Ajustement des requêtes SELECT dans les INSERT tblIQEE_Demandes pour aller chercher les valeurs actuelles
                                                            du NAS, nom, prénom et date de naissance du bénéficiaire.  (Section 4 NIDs RQ).
        2012-12-20        Stéphane Barbeau                    Désactivation champs facultatifs.
        2013-08-19        Stéphane Barbeau                    Requêtes SELECT dans les INSERT tblIQEE_Demandes: Corrections jointure JOIN Un_Beneficiary B ON B.BeneficiaryID = D.iID_Beneficiaire_31Decembre
        2013-09-11        Stéphane Barbeau                    Désactivation code pour les reprises à 0$.
        2016-06-17        Steeve Picard                        Remplacement des traces de SELECT par des PRINT
        2018-02-08      Steeve Picard                       Déplacement de «siAnnee_Fiscale» de la table «tblIQEE_Fichiers» vers les tables d'évèments
*********************************************************************************************************************/
CREATE PROCEDURE dbo.psIQEE_CompleterTransactionsAnnulation 
(
    @bFichier_Test BIT,
    @iID_Session INT,
    @dtDate_Creation_Fichiers DATETIME
)
AS
BEGIN
    DECLARE @tiID_Type_Enregistrement TINYINT,
            @iID_Type_Annulation INT,
            @iID_Raison_Annulation_Annulation INT,
            @iID_Statut_Annulation INT,
            @vcNAS_Beneficiaire VARCHAR(9),
            @vcNom_Beneficiaire VARCHAR(20),
            @vcPrenom_Beneficiaire VARCHAR(20),
            @dtDate_Naissance_Beneficiaire DATETIME
            
--    -------------------------------------------------------------------------------------------------------------------------------
--    -- Créer les transactions de demande d'IQÉÉ de type "reprise à 0" pour les transactions modifiant une information pas amendable
--    -------------------------------------------------------------------------------------------------------------------------------
--    INSERT INTO ##tblIQEE_RapportCreation (cSection,iSequence,vcMessage)
--    VALUES ('3',10,'       '+CONVERT(VARCHAR(25),GETDATE(),121)+' - psIQEE_CompleterTransactionsAnnulation - Créer les transactions'+
--            ' de demande d''IQÉÉ de type "reprise à 0"')

--    -- Déterminer le type d'enregistrement 02
    SELECT @tiID_Type_Enregistrement = TE.tiID_Type_Enregistrement
    FROM tblIQEE_TypesEnregistrement TE
    WHERE TE.cCode_Type_Enregistrement = '02'

--    -- Créer une table temporaire associant les nouvelles transactions d'origine et la transaction original encore en vigueur
--    CREATE TABLE #tblIQEE_TransactionsA0
--       (iID_Convention INT NOT NULL,
--        iID_Demande_IQEE_Nouvelle INT NOT NULL,
--        iID_Demande_IQEE_Origine INT NULL,
--        siAnnee_Fiscale_Nouvelle SMALLINT NOT NULL)

--    -- Insérer les nouvelles transactions d'origine
--    INSERT INTO #tblIQEE_TransactionsA0
--       (iID_Convention,
--        iID_Demande_IQEE_Nouvelle,
--        siAnnee_Fiscale_Nouvelle)
--    SELECT D.iID_Convention,D.iID_Demande_IQEE,A.siAnnee_Fiscale
--    FROM tblIQEE_Demandes D
--         JOIN #tblIQEE_AnneesFiscales A ON A.iID_Fichier_IQEE = D.iID_Fichier_IQEE
--    WHERE D.tiCode_Version = 0

--    -- Trouver la transaction originale encore en vigueur des nouvelles transactions d'origine
--    UPDATE #tblIQEE_TransactionsA0
--    SET iID_Demande_IQEE_Origine = (SELECT TOP 1 D.iID_Demande_IQEE
--                                    FROM tblIQEE_Annulations A
--                                         -- Annulation sur les demandes d'IQÉÉ
--                                         JOIN tblIQEE_TypesEnregistrement TE ON TE.tiID_Type_Enregistrement = A.tiID_Type_Enregistrement
--                                                                            AND TE.cCode_Type_Enregistrement = '02'
--                                         -- Rechercher la transaction originale
--                                         JOIN tblIQEE_Demandes D ON D.iID_Demande_IQEE = A.iID_Enregistrement_Demande_Annulation
--                                                                AND D.iID_Convention=#tblIQEE_TransactionsA0.iID_Convention
--                                                                AND D.siAnnee_Fiscale = #tblIQEE_TransactionsA0.siAnnee_Fiscale_Nouvelle
--                                         -- Rechercher le fichier de la transaction originale
--                                         JOIN tblIQEE_Fichiers F ON F.iID_Fichier_IQEE = D.iID_Fichier_IQEE
--                                    -- Demande d'annulations des fichiers en cours de création
--                                    WHERE A.iID_Session = @iID_Session
--                                      AND A.dtDate_Creation_Fichiers = @dtDate_Creation_Fichiers
--                                    ORDER BY F.bFichier_Test, F.bInd_Simulation, F.dtDate_Creation DESC)
---- TODO: Pourquoi j'utilise cette méthode au lieu d'utiliser la table des demandes d'annulation?
----(SELECT TOP 1 D.iID_Demande_IQEE
----                                    FROM tblIQEE_Demandes D
----                                         -- Transactions d'origine de l'année fiscale en cours de création qui ont été fait
----                                         -- antérieurement et qui font partie des fichiers de l'IQÉÉ admissibles
----                                         JOIN tblIQEE_Fichiers F ON F.iID_Fichier_IQEE = D.iID_Fichier_IQEE
----                                                                AND F.dtDate_Creation < @dtDate_Creation
----                                                                AND (@bFichiers_Test_Comme_Production = 1
----                                                                     OR F.bFichier_Test = 0) -- Tenir compte ou non des fichiers test
----                                                                AND F.bInd_Simulation = 0 -- Ne jamais tenir compte des fichiers de
----                                                                                          -- simulation
----                                     -- La transaction d'origine doit être valide
----                                    WHERE D.iID_Convention = #tblIQEE_TransactionsA0.iID_Convention
----                                      AND D.tiCode_Version = 0
----                                      AND D.cStatut_Reponse IN ('A','R')
----                                      AND D.siAnnee_Fiscale = #tblIQEE_TransactionsA0.siAnnee_Fiscale
----                                      -- La transaction ne doit pas avoir été annulée par un fichier admissible
----                                      AND NOT EXISTS (SELECT *
----                                                      FROM tblIQEE_Annulations A
----                                                           -- Transaction annulée
----                                                           JOIN tblIQEE_Demandes D2 ON D2.iID_Demande_IQEE =
----                                                                                                    A.iID_Enregistrement_Annulation
----                                                           -- Par un fichier de l'IQÉÉ admissible
----                                                           JOIN tblIQEE_Fichiers F2 ON F2.iID_Fichier_IQEE = D2.iID_Fichier_IQEE
----                                                                                   AND (@bFichiers_Test_Comme_Production = 1
----                                                                                        OR F2.bFichier_Test = 0)
----                                                                                   AND F2.bInd_Simulation = 0
----                                                      WHERE A.tiID_Type_Enregistrement = @tiID_Type_Enregistrement
----                                                        AND A.iID_Enregistrement_Demande_Annulation = D.iID_Demande_IQEE
----                                                        AND A.vcCode_Simulation IS NULL)
----                                    ORDER BY F.bFichier_Test, F.bInd_Simulation, F.dtDate_Creation DESC)

--    -- Créer les transactions de demande d'IQÉÉ de type "reprise à 0" pour les transactions modifiant une information pas amendable
--    -- Note: Des caractères hors du jeu de caractères permit ont été acceptés par RQ mais ne passent pas les validations de RQ sur les transactions
--    --         d'annulation ou de reprise à 0.  Voilà pourquoi il y a modification potentiel des noms et prénoms.
--    INSERT INTO [dbo].[tblIQEE_Demandes]
--           ([iID_Fichier_IQEE]
--           ,[cStatut_Reponse]
--           ,[iID_Convention]
--           ,[vcNo_Convention]
--           ,[tiCode_Version]
--           ,[dtDate_Debut_Convention]
--           ,[tiNB_Annee_Quebec]
--           ,[mCotisations]
--           ,[mTransfert_IN]
--           ,[mTotal_Cotisations_Subventionnables]
--           ,[mTotal_Cotisations]
--           ,[iID_Beneficiaire_31Decembre]
--           ,[vcNAS_Beneficiaire]
--           ,[vcNom_Beneficiaire]
--           ,[vcPrenom_Beneficiaire]
--           ,[dtDate_Naissance_Beneficiaire]
--           ,[tiSexe_Beneficiaire]
--           ,[iID_Adresse_31Decembre_Beneficiaire]
--           ,[vcAppartement_Beneficiaire]
--           ,[vcNo_Civique_Beneficiaire]
--           ,[vcRue_Beneficiaire]
--           ,[vcLigneAdresse2_Beneficiaire]
--           ,[vcLigneAdresse3_Beneficiaire]
--           ,[vcVille_Beneficiaire]
--           ,[vcProvince_Beneficiaire]
--           ,[vcPays_Beneficiaire]
--           ,[vcCodePostal_Beneficiaire]
--           ,[bResidence_Quebec]
--           ,[iID_Souscripteur]
--           ,[tiType_Souscripteur]
--           ,[vcNAS_Souscripteur]
--           ,[vcNEQ_Souscripteur]
--           ,[vcNom_Souscripteur]
--           ,[vcPrenom_Souscripteur]
--           ,[tiID_Lien_Souscripteur]
--           ,[iID_Adresse_Souscripteur]
--           ,[vcAppartement_Souscripteur]
--           ,[vcNo_Civique_Souscripteur]
--           ,[vcRue_Souscripteur]
--           ,[vcLigneAdresse2_Souscripteur]
--           ,[vcLigneAdresse3_Souscripteur]
--           ,[vcVille_Souscripteur]
--           ,[vcCodePostal_Souscripteur]
--           ,[vcProvince_Souscripteur]
--           ,[vcPays_Souscripteur]
--           ,[vcTelephone_Souscripteur]
--           ,[iID_Cosouscripteur]
--           ,[vcNAS_Cosouscripteur]
--           ,[vcNom_Cosouscripteur]
--           ,[vcPrenom_Cosouscripteur]
--           ,[tiID_Lien_Cosouscripteur]
--           ,[vcTelephone_Cosouscripteur]
--           ,[tiType_Responsable]
--           ,[vcNAS_Responsable]
--           ,[vcNEQ_Responsable]
--           ,[vcNom_Responsable]
--           ,[vcPrenom_Responsable]
--           ,[tiID_Lien_Responsable]
--           ,[vcAppartement_Responsable]
--           ,[vcNo_Civique_Responsable]
--           ,[vcRue_Responsable]
--           ,[vcLigneAdresse2_Responsable]
--           ,[vcLigneAdresse3_Responsable]
--           ,[vcVille_Responsable]
--           ,[vcCodePostal_Responsable]
--           ,[vcProvince_Responsable]
--           ,[vcPays_Responsable]
--           ,[vcTelephone_Responsable]
--           ,[bInd_Cession_IQEE])
--    SELECT A.iID_Fichier_IQEE
--           ,'D'
--           ,D.iID_Convention
--           ,D.vcNo_Convention
--           ,2
--           ,D.dtDate_Debut_Convention
--           ,0 --D.tiNB_Annee_Quebec  -- Champ facultatif
--           ,0
--           ,0
--           ,0
--           ,0  --D.mTotal_Cotisations  -- Champ facultatif
--           ,D.iID_Beneficiaire_31Decembre
--           ,H.SocialNumber 
--           ,(SELECT vcNom FROM [dbo].[fntIQEE_ModifierNom](H.LastName)) 
--           ,(SELECT vcNom FROM [dbo].[fntIQEE_ModifierNom](H.FirstName))
--           ,H.BirthDate 
--           ,D.tiSexe_Beneficiaire
--           ,D.iID_Adresse_31Decembre_Beneficiaire
--           ,NULL  --D.vcAppartement_Beneficiaire  -- Champ facultatif
--           ,D.vcNo_Civique_Beneficiaire
--           ,D.vcRue_Beneficiaire
--           ,NULL -- D.vcLigneAdresse2_Beneficiaire  -- Champ facultatif
--           ,D.vcLigneAdresse3_Beneficiaire
--           ,D.vcVille_Beneficiaire
--           ,D.vcProvince_Beneficiaire
--           ,D.vcPays_Beneficiaire
--           ,D.vcCodePostal_Beneficiaire
--           ,D.bResidence_Quebec
--           ,D.iID_Souscripteur
--           ,D.tiType_Souscripteur
--           ,D.vcNAS_Souscripteur
--           ,D.vcNEQ_Souscripteur
--           ,(SELECT vcNom FROM [dbo].[fntIQEE_ModifierNom](D.vcNom_Souscripteur))
--           ,(SELECT vcNom FROM [dbo].[fntIQEE_ModifierNom](D.vcPrenom_Souscripteur))
--           ,D.tiID_Lien_Souscripteur
--           ,D.iID_Adresse_Souscripteur
--           ,NULL  -- D.vcAppartement_Souscripteur  -- Champ facultatif
--           ,D.vcNo_Civique_Souscripteur
--           ,D.vcRue_Souscripteur
--           ,D.vcLigneAdresse2_Souscripteur
--           ,D.vcLigneAdresse3_Souscripteur
--           ,D.vcVille_Souscripteur
--           ,D.vcCodePostal_Souscripteur
--           ,D.vcProvince_Souscripteur
--           ,D.vcPays_Souscripteur
--           ,D.vcTelephone_Souscripteur
--           ,D.iID_Cosouscripteur
--           ,D.vcNAS_Cosouscripteur
--           ,(SELECT vcNom FROM [dbo].[fntIQEE_ModifierNom](D.vcNom_Cosouscripteur))
--           ,(SELECT vcNom FROM [dbo].[fntIQEE_ModifierNom](D.vcPrenom_Cosouscripteur))
--           ,D.tiID_Lien_Cosouscripteur
--           ,D.vcTelephone_Cosouscripteur
--           ,D.tiType_Responsable
--           ,D.vcNAS_Responsable
--           ,D.vcNEQ_Responsable
--           ,(SELECT vcNom FROM [dbo].[fntIQEE_ModifierNom](D.vcNom_Responsable))
--           ,(SELECT vcNom FROM [dbo].[fntIQEE_ModifierNom](D.vcPrenom_Responsable))
--           ,0  -- D.tiID_Lien_Responsable -- Champ facultatif
--           ,NULL  -- D.vcAppartement_Responsable -- Champ facultatif
--           ,NULL  -- D.vcNo_Civique_Responsable -- Champ facultatif
--           ,NULL  -- D.vcRue_Responsable -- Champ facultatif
--           ,NULL  -- D.vcLigneAdresse2_Responsable -- Champ facultatif
--           ,NULL -- D.vcLigneAdresse3_Responsable -- Champ facultatif
--           ,NULL  --D.vcVille_Responsable -- Champ facultatif
--           ,NULL  --D.vcCodePostal_Responsable -- Champ facultatif
--           ,NULL -- D.vcProvince_Responsable  -- Champ facultatif
--           ,NULL --D.vcPays_Responsable  -- Champ facultatif
--           ,NULL --D.vcTelephone_Responsable  -- Champ facultatif
--           ,0 --D.bInd_Cession_IQEE  -- Champ facultatif
--    FROM #tblIQEE_TransactionsA0 TA0
--         JOIN tblIQEE_Demandes D ON D.iID_Demande_IQEE = TA0.iID_Demande_IQEE_Origine
--         JOIN #tblIQEE_AnneesFiscales A ON A.siAnnee_Fiscale = TA0.siAnnee_Fiscale_Nouvelle
--         JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = D.iID_Beneficiaire_31Decembre --  Trouver le bénéficiaire au 31 décembre de l'année fiscale
--         JOIN dbo.Mo_Human H ON B.BeneficiaryID = H.HumanID
         
--    WHERE TA0.iID_Demande_IQEE_Origine IS NOT NULL

    --------------------------------------
    -- Créer les transactions d'annulation
    --------------------------------------

    INSERT INTO ##tblIQEE_RapportCreation (cSection,iSequence,vcMessage)
    VALUES ('3',10,'       '+CONVERT(VARCHAR(25),GETDATE(),121)+' - psIQEE_CompleterTransactionsAnnulation - Créer les transactions'+
            ' d''annulation')

    PRINT 'psIQEE_CompleterTransactionsAnnulation - Créer les transactions d''annulation'

--select 'Preuve d''existence de reprise'
--SELECT *
--                  FROM tblIQEE_Demandes D2
--                  WHERE D2.iID_Convention = D.iID_Convention
--                    AND D2.iID_Fichier_IQEE = AF.iID_Fichier_IQEE
--                    AND D2.tiCode_Version = 2

    -- Créer les transactions d'annulation pour les demandes de l'IQÉÉ (type 02)
    -- Note: Des caractères hors du jeu de caractères permit ont été acceptés par RQ mais ne passent pas les validations de RQ sur les transactions
    --         d'annulation ou de reprise à 0.  Voilà pourquoi il y a modification potentiel des noms et prénoms.
    INSERT INTO dbo.tblIQEE_Demandes
           (iID_Fichier_IQEE
           ,cStatut_Reponse
           ,iID_Convention
           ,vcNo_Convention
           ,tiCode_Version
           ,dtDate_Debut_Convention
           ,tiNB_Annee_Quebec
           ,mCotisations
           ,mTransfert_IN
           ,mTotal_Cotisations_Subventionnables
           ,mTotal_Cotisations
           ,iID_Beneficiaire_31Decembre
           ,vcNAS_Beneficiaire
           ,vcNom_Beneficiaire
           ,vcPrenom_Beneficiaire
           ,dtDate_Naissance_Beneficiaire
           ,tiSexe_Beneficiaire
           ,iID_Adresse_31Decembre_Beneficiaire
           ,vcAppartement_Beneficiaire
           ,vcNo_Civique_Beneficiaire
           ,vcRue_Beneficiaire
           ,vcLigneAdresse2_Beneficiaire
           ,vcLigneAdresse3_Beneficiaire
           ,vcVille_Beneficiaire
           ,vcProvince_Beneficiaire
           ,vcPays_Beneficiaire
           ,vcCodePostal_Beneficiaire
           ,bResidence_Quebec
           ,iID_Souscripteur
           ,tiType_Souscripteur
           ,vcNAS_Souscripteur
           ,vcNEQ_Souscripteur
           ,vcNom_Souscripteur
           ,vcPrenom_Souscripteur
           ,tiID_Lien_Souscripteur
           ,iID_Adresse_Souscripteur
           ,vcAppartement_Souscripteur
           ,vcNo_Civique_Souscripteur
           ,vcRue_Souscripteur
           ,vcLigneAdresse2_Souscripteur
           ,vcLigneAdresse3_Souscripteur
           ,vcVille_Souscripteur
           ,vcCodePostal_Souscripteur
           ,vcProvince_Souscripteur
           ,vcPays_Souscripteur
           ,vcTelephone_Souscripteur
           ,iID_Cosouscripteur
           ,vcNAS_Cosouscripteur
           ,vcNom_Cosouscripteur
           ,vcPrenom_Cosouscripteur
           ,tiID_Lien_Cosouscripteur
           ,vcTelephone_Cosouscripteur
           ,tiType_Responsable
           ,vcNAS_Responsable
           ,vcNEQ_Responsable
           ,vcNom_Responsable
           ,vcPrenom_Responsable
           ,tiID_Lien_Responsable
           ,vcAppartement_Responsable
           ,vcNo_Civique_Responsable
           ,vcRue_Responsable
           ,vcLigneAdresse2_Responsable
           ,vcLigneAdresse3_Responsable
           ,vcVille_Responsable
           ,vcCodePostal_Responsable
           ,vcProvince_Responsable
           ,vcPays_Responsable
           ,vcTelephone_Responsable
           ,bInd_Cession_IQEE)
    SELECT DISTINCT AF.iID_Fichier_IQEE
           ,'A'
           ,D.iID_Convention
           ,D.vcNo_Convention
           ,1
           ,D.dtDate_Debut_Convention
           ,0 --D.tiNB_Annee_Quebec  -- Champ facultatif
           ,D.mCotisations
           ,D.mTransfert_IN
           ,D.mTotal_Cotisations_Subventionnables
           ,0 --D.mTotal_Cotisations  -- Champ facultatif
           ,D.iID_Beneficiaire_31Decembre
           ,H.SocialNumber 
           ,(SELECT vcNom FROM dbo.fntIQEE_ModifierNom(H.LastName)) 
           ,(SELECT vcNom FROM dbo.fntIQEE_ModifierNom(H.FirstName))
           ,H.BirthDate 
           ,D.tiSexe_Beneficiaire
           ,D.iID_Adresse_31Decembre_Beneficiaire
           ,NULL  --D.vcAppartement_Beneficiaire  -- Champ facultatif
           ,D.vcNo_Civique_Beneficiaire
           ,D.vcRue_Beneficiaire
           ,NULL  --D.vcLigneAdresse2_Beneficiaire  -- Champ facultatif
           ,D.vcLigneAdresse3_Beneficiaire
           ,D.vcVille_Beneficiaire
           ,D.vcProvince_Beneficiaire
           ,D.vcPays_Beneficiaire
           ,D.vcCodePostal_Beneficiaire
           ,D.bResidence_Quebec
           ,D.iID_Souscripteur
           ,D.tiType_Souscripteur
           ,D.vcNAS_Souscripteur
           ,D.vcNEQ_Souscripteur
           ,(SELECT vcNom FROM dbo.fntIQEE_ModifierNom(D.vcNom_Souscripteur))
           ,(SELECT vcNom FROM dbo.fntIQEE_ModifierNom(D.vcPrenom_Souscripteur))
           ,D.tiID_Lien_Souscripteur
           ,D.iID_Adresse_Souscripteur
           ,NULL  -- D.vcAppartement_Souscripteur  -- Champ facultatif
           ,D.vcNo_Civique_Souscripteur
           ,D.vcRue_Souscripteur
           ,D.vcLigneAdresse2_Souscripteur
           ,D.vcLigneAdresse3_Souscripteur
           ,D.vcVille_Souscripteur
           ,D.vcCodePostal_Souscripteur
           ,D.vcProvince_Souscripteur
           ,D.vcPays_Souscripteur
           ,D.vcTelephone_Souscripteur
           ,D.iID_Cosouscripteur
           ,D.vcNAS_Cosouscripteur
           ,(SELECT vcNom FROM dbo.fntIQEE_ModifierNom(D.vcNom_Cosouscripteur))
           ,(SELECT vcNom FROM dbo.fntIQEE_ModifierNom(D.vcPrenom_Cosouscripteur))
           ,D.tiID_Lien_Cosouscripteur
           ,D.vcTelephone_Cosouscripteur
           ,D.tiType_Responsable
           ,D.vcNAS_Responsable
           ,D.vcNEQ_Responsable
           ,(SELECT vcNom FROM dbo.fntIQEE_ModifierNom(D.vcNom_Responsable))
           ,(SELECT vcNom FROM dbo.fntIQEE_ModifierNom(D.vcPrenom_Responsable))
           ,0 --D.tiID_Lien_Responsable  -- Champ facultatif
           ,NULL --D.vcAppartement_Responsable  -- Champ facultatif
           ,NULL --D.vcNo_Civique_Responsable  -- Champ facultatif
           ,NULL --D.vcRue_Responsable  -- Champ facultatif
           ,NULL --D.vcLigneAdresse2_Responsable  -- Champ facultatif
           ,NULL --D.vcLigneAdresse3_Responsable  -- Champ facultatif
           ,NULL --D.vcVille_Responsable  -- Champ facultatif
           ,NULL --D.vcCodePostal_Responsable  -- Champ facultatif
           ,NULL --D.vcProvince_Responsable  -- Champ facultatif
           ,NULL --D.vcPays_Responsable  -- Champ facultatif
           ,NULL --D.vcTelephone_Responsable  -- Champ facultatif
           ,0 -- D.bInd_Cession_IQEE  -- Champ facultatif
    FROM tblIQEE_Annulations A
         -- Uniquement les transactions d'origine en vigueur
         JOIN tblIQEE_Demandes D ON D.iID_Demande_IQEE = A.iID_Enregistrement_Demande_Annulation
--                                AND D.siAnnee_Fiscale = @siAnnee_Fiscale
-- TODO: Pourquoi faire cette sélection?  Elle n'est pas déjà faite?
--                                AND D.cStatut_Reponse IN ('A','R')
-- TODO: Pourquoi ces sélections?
         -- La transaction d'origine est de la même année fiscale que le fichier en cours de création, a été faite antérieurement
         -- et fait partie des fichiers de l'IQÉÉ admissibles
         JOIN tblIQEE_Fichiers F ON F.iID_Fichier_IQEE = D.iID_Fichier_IQEE
--                                AND F.dtDate_Creation < @dtDate_Creation
--                                AND (@bFichiers_Test_Comme_Production = 1
--                                     OR F.bFichier_Test = 0) -- Tenir compte ou non des fichiers test
--                                AND F.bInd_Simulation = 0 -- Ne jamais tenir compte des fichiers de simulation
         JOIN #tblIQEE_AnneesFiscales AF ON AF.siAnnee_Fiscale = D.siAnnee_Fiscale
         JOIN dbo.Un_Beneficiary B ON B.BeneficiaryID = D.iID_Beneficiaire_31Decembre --  Trouver le bénéficiaire au 31 décembre de l'année fiscale
         JOIN dbo.Mo_Human H ON B.BeneficiaryID = H.HumanID
         
    -- Prendre les annulations de la création du fichier
    WHERE A.iID_Session = @iID_Session
      AND A.dtDate_Creation_Fichiers = @dtDate_Creation_Fichiers
      AND A.tiID_Type_Enregistrement = @tiID_Type_Enregistrement
      -- Uniquement ceux qui ont été actualisé par une transaction d'annulation
      AND A.iID_Raison_Annulation_Annulation IS NULL
      -- Il existe une transaction de reprise
      AND EXISTS (SELECT *
                  FROM tblIQEE_Demandes D2
                  WHERE D2.iID_Convention = D.iID_Convention
                    AND D2.iID_Fichier_IQEE = AF.iID_Fichier_IQEE
                    AND D2.tiCode_Version = 2)

    -- Créer les transactions d'annulation pour les remplacements de bénéficiaire (type 03)
-- TODO: Mettre statut 'R'
    -- Déterminer le type d'enregistrement 03?

    -- Créer les transactions d'annulation pour les transferts entre régimes (type 04)
-- TODO: Mettre statut 'R'
    -- Déterminer le type d'enregistrement 04?

    -- Créer les transactions d'annulation pour les paiements au bénéficiaire (type 05)
-- TODO: Mettre statut 'R'
    -- Déterminer le type d'enregistrement 05?

    -- Créer les transactions d'annulation pour les déclarations d'impôt spécial (type 06)
-- TODO: Mettre statut 'A'
    -- Déterminer le type d'enregistrement 06?

    ----------------------------------------------------------------------------
    -- Confirmer l'annulation des transactions suite à aux demandes d'annulation
    ----------------------------------------------------------------------------

    INSERT INTO ##tblIQEE_RapportCreation (cSection,iSequence,vcMessage)
    VALUES ('3',10,'       '+CONVERT(VARCHAR(25),GETDATE(),121)+' - psIQEE_CompleterTransactionsAnnulation - Confirmer l''annulation'+
            ' des transactions suite à aux demandes d''annulation')

    -- Mettre à jour les identifiants des transactions d'annulation et de reprise des annulations pour les transactions
    -- de demande de l'IQÉÉ (type 02)
    UPDATE tblIQEE_Annulations
                                        -- Rechercher la transaction d'annulation
    SET iID_Enregistrement_Annulation = (SELECT D2.iID_Demande_IQEE
                                         FROM tblIQEE_Demandes D2
                                         WHERE D2.iID_Convention = D.iID_Convention
                                           AND D2.iID_Fichier_IQEE = AF.iID_Fichier_IQEE
                                           AND D2.tiCode_Version = 1),
                                      -- Rechercher la transaction de reprise
        iID_Enregistrement_Reprise = (SELECT D3.iID_Demande_IQEE
                                      FROM tblIQEE_Demandes D3
                                      WHERE D3.iID_Convention = D.iID_Convention
                                        AND D3.iID_Fichier_IQEE = AF.iID_Fichier_IQEE
                                        AND D3.tiCode_Version = 2),
                                               -- Rechercher la transaction de reprise originale (c'est elle la significative
                                               -- lorsqu'il y a modification d'informations pas amendable
        iID_Enregistrement_Reprise_Originale = (SELECT D4.iID_Demande_IQEE
                                                FROM tblIQEE_Demandes D4
                                                WHERE D4.iID_Convention = D.iID_Convention
                                                  AND D4.iID_Fichier_IQEE = AF.iID_Fichier_IQEE
                                                  AND D4.tiCode_Version = 0)
    FROM tblIQEE_Annulations A
         JOIN tblIQEE_TypesEnregistrement TE ON TE.tiID_Type_Enregistrement = A.tiID_Type_Enregistrement
                                            AND TE.cCode_Type_Enregistrement = '02'
         JOIN tblIQEE_Demandes D ON D.iID_Demande_IQEE = A.iID_Enregistrement_Demande_Annulation
         -- Uniquement les transactions du fichier en cours de création
         JOIN tblIQEE_Fichiers F ON F.iID_Fichier_IQEE = D.iID_Fichier_IQEE
         JOIN #tblIQEE_AnneesFiscales AF ON AF.siAnnee_Fiscale = D.siAnnee_Fiscale
    -- Prendre les annulations de la création du fichier
    WHERE A.iID_Session = @iID_Session
      AND A.dtDate_Creation_Fichiers = @dtDate_Creation_Fichiers
      AND A.tiID_Type_Enregistrement = @tiID_Type_Enregistrement
      -- Uniquement ceux qui ont été actualisé par une transaction d'annulation
      AND A.iID_Raison_Annulation_Annulation IS NULL

    -- Mettre à jour les identifiants des transactions d'annulation et de reprise des annulations pour les transactions
    -- de remplacement de bénéficiaire (type 03)
-- TODO: A faire

    -- Mettre à jour les identifiants des transactions d'annulation et de reprise des annulations pour les transactions
    -- de transfert entre régimes (type 04)
-- TODO: A faire

    -- Mettre à jour les identifiants des transactions d'annulation et de reprise des annulations pour les transactions
    -- de paiement au bénéficiaire (type 05)
-- TODO: A faire

    -- Mettre à jour les identifiants des transactions d'annulation et de reprise des annulations pour les transactions
    -- de déclaration d'impôt spécial (type 06) basés sur l'identifiant de remplacement de bénéficiaire
-- TODO: A faire

    -- Mettre à jour les identifiants des transactions d'annulation et de reprise des annulations pour les transactions
    -- de déclaration d'impôt spécial (type 06) basés sur l'identifiant de transfert
-- TODO: A faire

    -- Mettre à jour les identifiants des transactions d'annulation et de reprise des annulations pour les transactions
    -- de déclaration d'impôt spécial (type 06) basés sur l'identifiant de l'opération
-- TODO: A faire

    -- Mettre à jour les identifiants des transactions d'annulation et de reprise des annulations pour les transactions
    -- de déclaration d'impôt spécial (type 06) basés sur l'identifiant du changement de statut de convention
-- TODO: A faire

    -- Mettre à jour les identifiants des transactions d'annulation et de reprise des annulations pour les transactions
    -- de déclaration d'impôt spécial (type 06) basés sur l'année fiscale
-- TODO: A faire

    -----------------------------------------------------------------------------------------
    ---- Créer l'association des transactions de cotisations à la transaction de reprise à 0$
    -----------------------------------------------------------------------------------------
    --INSERT INTO ##tblIQEE_RapportCreation (cSection,iSequence,vcMessage)
    --VALUES ('3',10,'       '+CONVERT(VARCHAR(25),GETDATE(),121)+' - psIQEE_CompleterTransactionsAnnulation - Créer association des transactions de cotisations'+
    --        ' à la transaction de reprise à 0$')

    --INSERT INTO tblIQEE_TransactionsDemande
    --    (iID_Demande_IQEE,
    --     iID_Transaction)
    --SELECT DISTINCT DR.iID_Demande_IQEE,TD.iID_Transaction
    --FROM tblIQEE_Annulations A
    --     -- Associé à une reprise à 0$
    --     JOIN tblIQEE_Demandes DR ON DR.iID_Demande_IQEE = A.iID_Enregistrement_Reprise
    --                             AND DR.mTotal_Cotisations_Subventionnables = 0
    --                             -- Qui n'est pas associé à des transactions de cotisations
    --                             AND NOT EXISTS(SELECT *
    --                                            FROM tblIQEE_TransactionsDemande TD2
    --                                            WHERE TD2.iID_Demande_IQEE = DR.iID_Demande_IQEE)
    --     -- Retrouver la transaction annulée
    --     JOIN tblIQEE_Demandes D ON D.iID_Demande_IQEE = A.iID_Enregistrement_Demande_Annulation
    --     -- Uniquement les transactions du fichier en cours de création
    --     JOIN tblIQEE_Fichiers F ON F.iID_Fichier_IQEE = D.iID_Fichier_IQEE
    --     JOIN #tblIQEE_AnneesFiscales AF ON AF.siAnnee_Fiscale = D.siAnnee_Fiscale
    --     -- Retrouver les associations à des transactions de cotisations de la transaction annulée
    --     JOIN tblIQEE_TransactionsDemande TD ON TD.iID_Demande_IQEE = D.iID_Demande_IQEE
    ---- Prendre les annulations de la création du fichier
    --WHERE A.iID_Session = @iID_Session
    --  AND A.dtDate_Creation_Fichiers = @dtDate_Creation_Fichiers
    --  AND A.tiID_Type_Enregistrement = @tiID_Type_Enregistrement
    --  -- Uniquement ceux qui ont été actualisé par une transaction d'annulation
    --  AND A.iID_Raison_Annulation_Annulation IS NULL

    ----------------------------------------------------
    -- Mettre à jour le statut des demandes d'annulation
    ----------------------------------------------------

    INSERT INTO ##tblIQEE_RapportCreation (cSection,iSequence,vcMessage)
    VALUES ('3',10,'       '+CONVERT(VARCHAR(25),GETDATE(),121)+' - psIQEE_CompleterTransactionsAnnulation - Mettre à jour'+
            ' le statut des demandes d''annulation')

    -- Déterminer l'identifiant du statut d'annulation "Annulation créée - en attente de RQ"
    SELECT @iID_Statut_Annulation = SA.iID_Statut_Annulation
    FROM tblIQEE_StatutsAnnulation SA
    WHERE SA.vcCode_Statut = 'ACA'

    -- Mettre à jour le statut s'il y a juste une demande d'annulation
    UPDATE tblIQEE_Annulations
    SET iID_Statut_Annulation = @iID_Statut_Annulation
    FROM tblIQEE_Annulations A
         -- Prendre uniquement les demandes qui ont le statut transitoire pour la création des transactions
         JOIN tblIQEE_StatutsAnnulation SA ON SA.iID_Statut_Annulation = A.iID_Statut_Annulation
                                          AND SA.vcCode_Statut = 'ASS'
    -- Prendre les annulations de la création du fichier
    WHERE A.iID_Session = @iID_Session
      AND A.dtDate_Creation_Fichiers = @dtDate_Creation_Fichiers
      -- Il y a juste une demande d'annulation
      AND A.iID_Enregistrement_Annulation IS NOT NULL
      AND A.iID_Enregistrement_Reprise IS NULL
      AND A.iID_Enregistrement_Reprise_Originale IS NULL

    -- Déterminer l'identifiant du statut d'annulation "Annulation/reprise créées - en attente de RQ"
    SELECT @iID_Statut_Annulation = SA.iID_Statut_Annulation
    FROM tblIQEE_StatutsAnnulation SA
    WHERE SA.vcCode_Statut = 'ARA'

    -- Mettre à jour le statut s'il y a juste une demande d'annulation
    UPDATE tblIQEE_Annulations
    SET iID_Statut_Annulation = @iID_Statut_Annulation
    FROM tblIQEE_Annulations A
         -- Prendre uniquement les demandes qui ont le statut transitoire pour la création des transactions
         JOIN tblIQEE_StatutsAnnulation SA ON SA.iID_Statut_Annulation = A.iID_Statut_Annulation
                                          AND SA.vcCode_Statut = 'ASS'
    -- Prendre les annulations de la création du fichier
    WHERE A.iID_Session = @iID_Session
      AND A.dtDate_Creation_Fichiers = @dtDate_Creation_Fichiers
      -- Il y a juste une demande d'annulation
      AND A.iID_Enregistrement_Annulation IS NOT NULL
      AND A.iID_Enregistrement_Reprise IS NOT NULL
      AND A.iID_Enregistrement_Reprise_Originale IS NULL

    ---- Déterminer l'identifiant du statut d'annulation "Annulation/reprise à 0$/nouvelle transaction créées - en attente de RQ"
    --SELECT @iID_Statut_Annulation = SA.iID_Statut_Annulation
    --FROM tblIQEE_StatutsAnnulation SA
    --WHERE SA.vcCode_Statut = 'A0A'

    ---- Mettre à jour le statut s'il y a juste une demande d'annulation
    --UPDATE tblIQEE_Annulations
    --SET iID_Statut_Annulation = @iID_Statut_Annulation
    --FROM tblIQEE_Annulations A
    --     -- Prendre uniquement les demandes qui ont le statut transitoire pour la création des transactions
    --     JOIN tblIQEE_StatutsAnnulation SA ON SA.iID_Statut_Annulation = A.iID_Statut_Annulation
    --                                      AND SA.vcCode_Statut = 'ASS'
    ---- Prendre les annulations de la création du fichier
    --WHERE A.iID_Session = @iID_Session
    --  AND A.dtDate_Creation_Fichiers = @dtDate_Creation_Fichiers
    --  -- Il y a juste une demande d'annulation
    --  AND A.iID_Enregistrement_Annulation IS NOT NULL
    --  AND A.iID_Enregistrement_Reprise IS NOT NULL
    --  AND A.iID_Enregistrement_Reprise_Originale IS NOT NULL

    -- Déterminer l'identifiant du statut d'annulation "Annulation/nouvelle transaction créées - en attente de RQ"
    SELECT @iID_Statut_Annulation = SA.iID_Statut_Annulation
    FROM tblIQEE_StatutsAnnulation SA
    WHERE SA.vcCode_Statut = 'AOA'

    -- Mettre à jour le statut s'il y a juste une demande d'annulation
    UPDATE tblIQEE_Annulations
    SET iID_Statut_Annulation = @iID_Statut_Annulation
    FROM tblIQEE_Annulations A
         -- Prendre uniquement les demandes qui ont le statut transitoire pour la création des transactions
         JOIN tblIQEE_StatutsAnnulation SA ON SA.iID_Statut_Annulation = A.iID_Statut_Annulation
                                          AND SA.vcCode_Statut = 'ASS'
    -- Prendre les annulations de la création du fichier
    WHERE A.iID_Session = @iID_Session
      AND A.dtDate_Creation_Fichiers = @dtDate_Creation_Fichiers
      -- Il y a juste une demande d'annulation
      AND A.iID_Enregistrement_Annulation IS NOT NULL
      AND A.iID_Enregistrement_Reprise IS NULL
      AND A.iID_Enregistrement_Reprise_Originale IS NOT NULL

    ----------------------------------------------------
    -- Mettre à jour le statut des transactions annulées
    ----------------------------------------------------
    IF @bFichier_Test = 0
        BEGIN
            INSERT INTO ##tblIQEE_RapportCreation (cSection,iSequence,vcMessage)
            VALUES ('3',10,'       '+CONVERT(VARCHAR(25),GETDATE(),121)+' - psIQEE_CompleterTransactionsAnnulation - Mettre à jour'+
                    ' le statut des transactions annulées')

            UPDATE tblIQEE_Demandes
            SET cStatut_Reponse = 'D'
            FROM tblIQEE_Annulations A
                 JOIN tblIQEE_TypesEnregistrement TE ON TE.cCode_Type_Enregistrement = '02'
                 JOIN tblIQEE_Demandes D ON D.iID_Demande_IQEE = A.iID_Enregistrement_Demande_Annulation
-- TODO: Pourquoi ces sélections?
--                                        AND D.tiCode_Version IN (0,2)
--                                        AND D.cStatut_Reponse IN ('A','R')
            -- Prendre les annulations de la création du fichier
            WHERE A.tiID_Type_Enregistrement = TE.tiID_Type_Enregistrement
              AND A.iID_Session = @iID_Session
              AND A.dtDate_Creation_Fichiers = @dtDate_Creation_Fichiers
              -- Qui ont été annulée
              AND A.iID_Enregistrement_Annulation IS NOT NULL
              -- Uniquement ceux qui ont été actualisé par une transaction d'annulation
              AND A.iID_Raison_Annulation_Annulation IS NULL
--              -- Uniquement ceux qui font partie du fichier en cours de création
--              AND EXISTS(SELECT *
--                         FROM tblIQEE_Demandes D2
--                         WHERE D2.iID_Demande_IQEE = A.iID_Enregistrement_Annulation
--                           AND D2.iID_Fichier_IQEE = @iID_Fichier_IQEE)

            -- Mettre à jour le statut des transactions annulées des remplacements de bénéficiaire (type 03)
-- TODO: A faire: Statut 'T'

            -- Mettre à jour le statut des transactions annulées des transferts entre régimes (type 04)
-- TODO: A faire: Statut 'T'

            -- Mettre à jour le statut des transactions annulées des paiements au bénéficiaire (type 05)
-- TODO: A faire: Statut 'T'

            -- Mettre à jour le statut des transactions annulées des déclarations d'impôt spécial (type 06)
-- TODO: A faire: Statut 'D'

        END

    --------------------------------------------------------------------------------------------------------
    -- Supprimer les demandes d’annulations manuelles qui ont été actualisé par une transaction d’annulation
    -- pour ne pas quelles soient demandées à nouveau lors de la création d’un autre fichier
    --------------------------------------------------------------------------------------------------------
    IF @bFichier_Test = 0
        BEGIN
            INSERT INTO ##tblIQEE_RapportCreation (cSection,iSequence,vcMessage)
            VALUES ('3',10,'       '+CONVERT(VARCHAR(25),GETDATE(),121)+' - psIQEE_CompleterTransactionsAnnulation - Supprimer les'+
                    ' demandes d''annulations manuelles qui ont été réalisées')

            DELETE FROM tblIQEE_Annulations
            -- Supprimer les demandes annulations...
            FROM tblIQEE_Annulations A
                 -- de type manuelle...
                 JOIN tblIQEE_TypesAnnulation TA ON TA.iID_Type_Annulation = A.iID_Type_Annulation
                                                AND TA.vcCode_Type = 'MAN'
                 -- sur les enregistrements "demande d'IQÉÉ"...
                 JOIN tblIQEE_TypesEnregistrement TE ON TE.tiID_Type_Enregistrement = A.tiID_Type_Enregistrement
                                                    AND TE.cCode_Type_Enregistrement = '02'
            -- qui ne sont pas associé à la création d'un groupe de fichier de transactions...
            WHERE A.iID_Session IS NULL
              AND A.dtDate_Creation_Fichiers IS NULL
              AND A.vcCode_Simulation IS NULL
              -- pour lesquelles il existe une actualisation de la demande d'annulation dans les fichiers en cours de création
              AND EXISTS(SELECT *
                         FROM tblIQEE_Annulations A2
                         -- Rechercher les demandes d'annulation identiques à chaque demande d'annulation manuelle...
                         WHERE A2.tiID_Type_Enregistrement = A.tiID_Type_Enregistrement
                           AND A2.iID_Enregistrement_Demande_Annulation = A.iID_Enregistrement_Demande_Annulation
                           AND A2.dtDate_Demande_Annulation = A.dtDate_Demande_Annulation
                           AND A2.iID_Utilisateur_Demande = A.iID_Utilisateur_Demande
                           AND A2.iID_Type_Annulation = A.iID_Type_Annulation
                           AND A2.iID_Raison_Annulation = A.iID_Raison_Annulation
                           -- parmis les demandes d'annulation des fichiers en cours de création...
                           AND A2.iID_Session = @iID_Session
                           AND A2.dtDate_Creation_Fichiers = @dtDate_Creation_Fichiers
                           -- où la demande d'annulation a été actualisée
                           AND A2.iID_Raison_Annulation_Annulation IS NULL
                           AND A2.iID_Enregistrement_Annulation IS NOT NULL)
        END

    -------------------------------------------------------------------------------------------------------------------------
    -- Supprimer les demandes d'annulations manuelles qui n’ont pas été actualisé et qui ne doivent pas revenir parce que les
    -- transactions de reprise étaient identiques aux transactions originales (raison IDE)
    -------------------------------------------------------------------------------------------------------------------------
    IF @bFichier_Test = 0
        BEGIN
            INSERT INTO ##tblIQEE_RapportCreation (cSection,iSequence,vcMessage)
            VALUES ('3',10,'       '+CONVERT(VARCHAR(25),GETDATE(),121)+' - psIQEE_CompleterTransactionsAnnulation - Supprimer les'+
                    ' demandes d''annulations manuelles qui n’ont pas été actualisé parce que les transactions de reprise étaient'+
                    ' identiques aux transactions originales')

            DELETE FROM tblIQEE_Annulations
            -- Supprimer les demandes annulations...
            FROM tblIQEE_Annulations A
                 -- de type manuelle...
                 JOIN tblIQEE_TypesAnnulation TA ON TA.iID_Type_Annulation = A.iID_Type_Annulation
                                                AND TA.vcCode_Type = 'MAN'
                 -- sur les enregistrements "demande d'IQÉÉ"...
                 JOIN tblIQEE_TypesEnregistrement TE ON TE.tiID_Type_Enregistrement = A.tiID_Type_Enregistrement
                                                    AND TE.cCode_Type_Enregistrement = '02'
            -- qui ne sont pas associé à la création d'un groupe de fichier de transactions...
            WHERE A.iID_Session IS NULL
              AND A.dtDate_Creation_Fichiers IS NULL
              AND A.vcCode_Simulation IS NULL
              -- pour lesquelles il n'existe pas une actualisation de la demande d'annulation dans les fichiers en cours de création
              -- parce que les transactions de reprise étaient identiques aux transactions originales (raison IDE)
              AND EXISTS(SELECT *
                         FROM tblIQEE_Annulations A2
                              -- parce que les transactions étaient identiques
                              JOIN tblIQEE_RaisonsAnnulationAnnulation RAA ON RAA.iID_Raison_Annulation_Annulation =
                                                                                                A2.iID_Raison_Annulation_Annulation
                                                                          AND RAA.vcCode_Raison = 'IDE'
                         -- Rechercher les demandes d'annulation identiques à chaque demande d'annulation manuelle...
                         WHERE A2.tiID_Type_Enregistrement = A.tiID_Type_Enregistrement
                           AND A2.iID_Enregistrement_Demande_Annulation = A.iID_Enregistrement_Demande_Annulation
                           AND A2.dtDate_Demande_Annulation = A.dtDate_Demande_Annulation
                           AND A2.iID_Utilisateur_Demande = A.iID_Utilisateur_Demande
                           AND A2.iID_Type_Annulation = A.iID_Type_Annulation
                           AND A2.iID_Raison_Annulation = A.iID_Raison_Annulation
                           -- parmis les demandes d'annulation des fichiers en cours de création...
                           AND A2.iID_Session = @iID_Session
                           AND A2.dtDate_Creation_Fichiers = @dtDate_Creation_Fichiers
                           -- où la demande d'annulation n'a pas été actualisée...
                           AND A2.iID_Raison_Annulation_Annulation IS NOT NULL)
        END

    ---------------------------------------------------------------------------------------------------------------------------
    -- Compléter les demandes d’annulation manuelles qui ne faisait pas partie de la sélection pour la création des fichiers de
    -- transaction (qui ne faisait pas partie des années fiscales primaires « pas juste de conséquence d’annulation »)
    -- mais qui ont déjà étés traitées de facto par une autre demande annulation qui elle faisait partie de la sélection pour
    -- la création des fichiers.
    ---------------------------------------------------------------------------------------------------------------------------
    IF @bFichier_Test = 0
        BEGIN
            INSERT INTO ##tblIQEE_RapportCreation (cSection,iSequence,vcMessage)
            VALUES ('3',10,'       '+CONVERT(VARCHAR(25),GETDATE(),121)+' - psIQEE_CompleterTransactionsAnnulation - Compléter'+
                    ' demandes d''annulations manuelles actualisées par autres demandes annulation')

            UPDATE A
            SET iID_Session = @iID_Session,
                dtDate_Creation_Fichiers = @dtDate_Creation_Fichiers,
                iID_Enregistrement_Annulation = A2.iID_Enregistrement_Annulation,
                iID_Enregistrement_Reprise = A2.iID_Enregistrement_Reprise,
                iID_Enregistrement_Reprise_Originale = A2.iID_Enregistrement_Reprise_Originale
            -- Mettre à jour les demandes d'annulation manuelles...
            FROM tblIQEE_Annulations A
                 -- Qui faisait partie de la sélection pour la création des fichiers de transaction
                                            -- Même transaction...
                 JOIN tblIQEE_Annulations A2 ON A2.tiID_Type_Enregistrement = A.tiID_Type_Enregistrement
                                            AND A2.iID_Enregistrement_Demande_Annulation = A.iID_Enregistrement_Demande_Annulation
                                            -- Dans la sélection pour la création des fichiers en cours...
                                            AND A2.iID_Session = @iID_Session
                                            AND A2.dtDate_Creation_Fichiers = @dtDate_Creation_Fichiers
                                            -- Qui ont déjà été réalisées
                                            AND A2.iID_Raison_Annulation_Annulation IS NULL
                                            AND A2.iID_Enregistrement_Annulation IS NOT NULL
            -- Uniquement les demandes d'annulation manuelles   Note: comme les demandes manuelles réalisées ont été supprimées
            --                                                          dans les étapes précédentes, il ne reste que des demandes
            --                                                          d'annulation qui ne faisait pas partie de la sélection pour
            --                                                          la création des fichiers de transaction
            WHERE A.iID_Session IS NULL
              AND A.dtDate_Creation_Fichiers IS NULL
              AND A.vcCode_Simulation IS NULL
        END
END
