/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service : psIQEE_ModifierStatutErreurs
Nom du service  : Modifier le statut des erreurs
But             : Modifier le statut des erreurs suite à la création d'un nouveau fichier de transactions en
                  production pour que le statut des erreurs passe à "Terminée" lorsqu'une transaction corrigée
                  est retournée suite à une erreur de RQ.
Facette         : IQÉÉ

Paramètres d’entrée : Paramètre                    Description
                      ------------------------  -----------------------------------------------------------------
                      bFichier_Test             Indicateur si le fichier est crée pour fins d’essais ou si c’est
                                                un fichier réel.  0=Fichier réel, 1=Fichier test.
                      dtDate_Creation_Fichiers  Date et heure de la création des fichiers identifiant de façon unique
                                                avec l'identifiant de session, la création des fichiers de transactions.

Exemple d’appel : Ce service doit uniquement être appelé par la procédure "psIQEE_CreerFichiers".

Paramètres de sortie : Table                        Champ                            Description
                       -------------------------    ---------------------------     ---------------------------------
                       S/O

Historique des modifications:
    Date        Programmeur             Description                                
    ----------  --------------------    -----------------------------------------
    2009-09-10  Éric Deshaies           Création du service    
    2016-01-08  Steve Picard            Passer le statut d'erreur à «TER - Terminé» pour ceux «TAR - Traité & renvoyé»
                                        Empêcher de remettre le statut d'erreur à «ATR - À traiter»
    2018-02-08  Steeve Picard           Déplacement de «siAnnee_Fiscale» de la table «tblIQEE_Fichiers» vers les tables d'évèments
    2018-06-06  Steeve Picard           Modificiation de la gestion des retours d'erreur par RQ
*********************************************************************************************************************/
CREATE PROCEDURE dbo.psIQEE_ModifierStatutErreurs
(
    @bFichier_Test BIT,
    @dtDate_Creation_Fichiers DATETIME
)
AS
BEGIN
    DECLARE @tiID_Statuts_Erreur TINYINT,
            @tiID_Statuts_Erreur_ATR TINYINT

    -----------------------------------------------------------------------------------------------
    -- Modifier le statut des erreurs suite à la création d'un nouveau fichier de transactions en
    -- production pour que le statut des erreurs passe à "Terminée" lorsqu'une transaction corrigée
    -- est retournée suite à une erreur de RQ.
    -----------------------------------------------------------------------------------------------
    --IF @bFichier_Test = 0
    --    BEGIN
            DECLARE @DateDuJour DATETIME
            SET @DateDuJour = GETDATE()

            -- Trouver l'identifiant du statut d'erreur "Terminée" (TER)
            SELECT @tiID_Statuts_Erreur = SE.tiID_Statuts_Erreur
            FROM tblIQEE_StatutsErreur SE
            WHERE SE.vcCode_Statut = 'TER'

            -- Utiliser l'utilisateur système comme dernière modification aux erreurs
            DECLARE @iID_Utilisateur_Modification INT

            SELECT TOP 1 @iID_Utilisateur_Modification = D.iID_Utilisateur_Systeme
            FROM Un_Def D

            -- Modifier le statut des erreurs de l’IQÉÉ qui ont été traitées par GUI et donc la transaction en erreur
            -- a été remplacée par une nouvelle transaction à transmettre à RQ.
            UPDATE tblIQEE_Erreurs
            SET tiID_Statuts_Erreur = @tiID_Statuts_Erreur,
                iID_Utilisateur_Modification = @iID_Utilisateur_Modification,
                dtDate_Modification = @DateDuJour,
                -- Si le système a fait passer le statut de l'erreur de "À traiter" à "Traitée - A retourner", c'est alors le système qui a traitée
                -- l'erreur automatiquement.  Sinon, c'est l'utilisateur qui avait déjà traitée l'erreur avant le système.
                iID_Utilisateur_Traite = CASE WHEN E.dtDate_Modification = @dtDate_Creation_Fichiers THEN @iID_Utilisateur_Modification ELSE E.iID_Utilisateur_Traite END,
                dtDate_Traite = CASE WHEN E.dtDate_Modification = @dtDate_Creation_Fichiers THEN @dtDate_Creation_Fichiers ELSE E.dtDate_Traite END
            FROM tblIQEE_Erreurs E
                 -- Rechercher le type d'enregistrement en erreur
                 JOIN tblIQEE_TypesEnregistrement TE ON TE.tiID_Type_Enregistrement = E.tiID_Type_Enregistrement
                 -- Le statut de l'erreur permet de retourner une transaction
                 JOIN tblIQEE_StatutsErreur SE ON SE.tiID_Statuts_Erreur = E.tiID_Statuts_Erreur
                                              AND SE.bInd_Retourner_RQ = 1
                 -- Limiter la mise à jour des erreurs aux années fiscales de la création en cours
                 JOIN dbo.fntIQEE_RechercherFichiers(NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL) F ON F.iID_Fichier_IQEE = E.iID_Fichier_IQEE
                 JOIN #tblIQEE_AnneesFiscales A ON A.siAnnee_Fiscale = F.siAnnee_Fiscale
                 -- Rechercher la demande en erreur ainsi que la nouvelle transaction de remplacement
                 LEFT JOIN tblIQEE_Demandes D1 ON D1.iID_Demande_IQEE = E.iID_Enregistrement
                 --LEFT JOIN tblIQEE_Fichiers F2 ON F2.iID_Fichier_IQEE = D1.iID_Fichier_IQEE
                 LEFT JOIN #tblIQEE_AnneesFiscales A2 ON A2.siAnnee_Fiscale = D1.siAnnee_Fiscale
                 LEFT JOIN tblIQEE_Demandes D2 ON D2.iID_Fichier_IQEE = A2.iID_Fichier_IQEE
                                              AND D2.iID_Convention = D1.iID_Convention
                                              AND (D2.tiCode_Version = D1.tiCode_Version OR D2.tiCode_Version IN (0,2))
                 -- Rechercher le remplacement de bénéficiaire en erreur ainsi que la nouvelle transaction de remplacement
                 LEFT JOIN tblIQEE_RemplacementsBeneficiaire RB1 ON RB1.iID_Remplacement_Beneficiaire = E.iID_Enregistrement
                 --LEFT JOIN tblIQEE_Fichiers F3 ON F3.iID_Fichier_IQEE = RB1.iID_Fichier_IQEE
                 LEFT JOIN #tblIQEE_AnneesFiscales A3 ON A3.siAnnee_Fiscale = RB1.siAnnee_Fiscale
                 LEFT JOIN tblIQEE_RemplacementsBeneficiaire RB2 ON RB2.iID_Fichier_IQEE = A3.iID_Fichier_IQEE
                                                                AND RB2.iID_Convention = RB1.iID_Convention
                                                                AND RB2.iID_Changement_Beneficiaire = RB1.iID_Changement_Beneficiaire
                                                                AND (RB2.tiCode_Version = RB1.tiCode_Version OR RB2.tiCode_Version IN (0,2))
                 -- Rechercher le transfert en erreur ainsi que la nouvelle transaction de remplacement
                 LEFT JOIN tblIQEE_Transferts T1 ON T1.iID_Transfert = E.iID_Enregistrement
                 --LEFT JOIN tblIQEE_Fichiers F4 ON F4.iID_Fichier_IQEE = T1.iID_Fichier_IQEE
                 LEFT JOIN #tblIQEE_AnneesFiscales A4 ON A4.siAnnee_Fiscale = T1.siAnnee_Fiscale
                 LEFT JOIN tblIQEE_Transferts T2 ON T2.iID_Fichier_IQEE = A4.iID_Fichier_IQEE
                                                AND T2.iID_Convention = T1.iID_Convention
                                                AND T2.iID_Operation = T1.iID_Operation
                                                AND (T2.tiCode_Version = T1.tiCode_Version OR T2.tiCode_Version IN (0,2))
                 -- Rechercher le paiement au bénéficiaire en erreur ainsi que la nouvelle transaction de remplacement
                 LEFT JOIN tblIQEE_PaiementsBeneficiaires PB1 ON PB1.iID_Paiement_Beneficiaire = E.iID_Enregistrement
                 --LEFT JOIN tblIQEE_Fichiers F5 ON F5.iID_Fichier_IQEE = PB1.iID_Fichier_IQEE
                 LEFT JOIN #tblIQEE_AnneesFiscales A5 ON A5.siAnnee_Fiscale = PB1.siAnnee_Fiscale
                 LEFT JOIN tblIQEE_PaiementsBeneficiaires PB2 ON PB2.iID_Fichier_IQEE = A5.iID_Fichier_IQEE
                                                             AND PB2.iID_Convention = PB1.iID_Convention
                                                             AND PB2.iID_Operation = PB1.iID_Operation
                                                             AND (PB2.tiCode_Version = PB1.tiCode_Version OR PB2.tiCode_Version IN (0,2))
                 -- Rechercher l'impôt spécial en erreur ainsi que la nouvelle transaction de remplacement
                 LEFT JOIN tblIQEE_ImpotsSpeciaux IS1 ON IS1.iID_Impot_Special = E.iID_Enregistrement
                 --LEFT JOIN tblIQEE_Fichiers F6 ON F6.iID_Fichier_IQEE = IS1.iID_Fichier_IQEE
                 LEFT JOIN #tblIQEE_AnneesFiscales A6 ON A6.siAnnee_Fiscale = IS1.siAnnee_Fiscale
                 LEFT JOIN tblIQEE_ImpotsSpeciaux IS2 ON IS2.iID_Fichier_IQEE = A6.iID_Fichier_IQEE
                                                     AND IS2.iID_Convention = IS1.iID_Convention
                                                     AND ISNULL(IS2.iID_Remplacement_Beneficiaire,0) = ISNULL(IS1.iID_Remplacement_Beneficiaire,0)
                                                     AND ISNULL(IS2.iID_Transfert,0) = ISNULL(IS1.iID_Transfert,0)
                                                     AND ISNULL(IS2.iID_Operation,0) = ISNULL(IS1.iID_Operation,0)
                                                     AND ISNULL(IS2.iID_Statut_Convention,0) = ISNULL(IS1.iID_Statut_Convention,0)
                                                     AND (IS2.tiCode_Version = IS1.tiCode_Version OR IS2.tiCode_Version IN (0,2))
            WHERE CASE
                    WHEN TE.cCode_Type_Enregistrement = '02' THEN D2.iID_Demande_IQEE
                    WHEN TE.cCode_Type_Enregistrement = '03' THEN RB2.iID_Remplacement_Beneficiaire
                    WHEN TE.cCode_Type_Enregistrement = '04' THEN T2.iID_Transfert
                    WHEN TE.cCode_Type_Enregistrement = '05' THEN PB2.iID_Paiement_Beneficiaire
                    WHEN TE.cCode_Type_Enregistrement = '06' THEN IS2.iID_Impot_Special
                  END IS NOT NULL
               OR (TE.cCode_Type_Enregistrement = '02' AND EXISTS(SELECT *
                                                                  FROM tblIQEE_ReponsesDemande RD
                                                                  WHERE RD.iID_Demande_IQEE = E.iID_Enregistrement))
               OR (TE.cCode_Type_Enregistrement = '02' AND D1.tiCode_Version = 1 AND D1.cStatut_Reponse = 'R')
        --END


--    -------------------------------------------------------------------------------------------------------------------------------------
--    -- Remettre les erreurs qui avait été considérées comme traitée au début du traitement comme à traiter.  Il le fera systhématiquement
--    -- si la création des fichiers est un test parce qu'il ne fera pas la section précédente du traitement.
--    -------------------------------------------------------------------------------------------------------------------------------------
---- TODO: En cas de fichier test, ne pas faire bouger les statuts.  Les remettres comme ils étaient au début du traitement.  Peut-être déjà comme ça.
--    -- Déterminer les codes de statut de l'erreur
--    SELECT @tiID_Statuts_Erreur = SE.tiID_Statuts_Erreur
--    FROM tblIQEE_StatutsErreur SE
--    WHERE SE.vcCode_Statut = 'TAR'

--    SELECT @tiID_Statuts_Erreur_ATR = SE.tiID_Statuts_Erreur
--    FROM tblIQEE_StatutsErreur SE
--    WHERE SE.vcCode_Statut = 'ATR'

--    UPDATE tblIQEE_Erreurs
--    SET tiID_Statuts_Erreur = @tiID_Statuts_Erreur_ATR,
--        iID_Utilisateur_Modification = iID_Utilisateur_Traite,
--        dtDate_Modification = dtDate_Traite,
--        iID_Utilisateur_Traite = NULL,
--        dtDate_Traite = NULL
--    FROM tblIQEE_Erreurs E
--    WHERE E.tiID_Statuts_Erreur = @tiID_Statuts_Erreur
--      AND E.dtDate_Modification = @dtDate_Creation_Fichiers


    ---------------------------------------------------------
    -- Mettre à jour le statut de tous les rapports d'erreurs
    ---------------------------------------------------------
    IF @bFichier_Test = 0
        EXECUTE dbo.psIQEE_MettreAJourStatutRapportsErreurs NULL
END
