/****************************************************************************************************
Copyrights (c) 2008 Gestion Universitas inc.

Code du service        : psIQEE_TraiterExceptionsManuellesDonneesTransactions
Nom du service        : Traiter les exceptions manuelles dans les données des transactions
But                 : - Il est prévu que par programmation, nous puissions modifier manuellement des informations dans
                        les transactions.  Ces informations modifiées font parties intégrante des transactions.
                      - Cela permettant de traiter manuellement d’une façon temporaire ou permanente, des exceptions
                        à l’écart du code principale pour ne pas polluer ce code.
                      - Cela permet de compenser pour les faiblesses des systèmes UniAccès et les traitements de RQ
                        en attendant des développements.
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
        2012-01-30        Éric Deshaies                        Création du service                            
        2018-02-08      Steeve Picard                       Déplacement de «siAnnee_Fiscale» de la table «tblIQEE_Fichiers» vers les tables d'évèments
****************************************************************************************************/
CREATE PROCEDURE dbo.psIQEE_TraiterExceptionsManuellesDonneesTransactions 
(
    @bFichier_Test BIT,
    @iID_Session INT,
    @dtDate_Creation_Fichiers DATETIME
)
AS
BEGIN
    --------------------------------------------------
    -- Modifier des informations dans les transactions
    --------------------------------------------------
    INSERT INTO ##tblIQEE_RapportCreation (cSection,iSequence,vcMessage)
    VALUES ('3',10,'       '+CONVERT(VARCHAR(25),GETDATE(),121)+' - psIQEE_TraiterExceptionsManuellesDonneesTransactions - Modifier des informations dans les transactions')

    -- Convention U-20081218044
    ---------------------------
    UPDATE D
    -- Définir la date de naissance
    SET dtDate_Naissance_Beneficiaire = '2003-01-30'
    FROM tblIQEE_Demandes D
         -- Pour l'année fiscale 2008
         JOIN tblIQEE_Fichiers F ON F.iID_Fichier_IQEE = D.iID_Fichier_IQEE
         -- Pour la création de fichier en cours seulement
         JOIN #tblIQEE_AnneesFiscales A ON A.iID_Fichier_IQEE = D.iID_Fichier_IQEE
    -- Pour la transaction d'annulation de la convention
    WHERE D.vcNo_Convention = 'U-20081218044'
      AND D.siAnnee_Fiscale = 2008
      AND D.tiCode_Version = 1
      AND D.cStatut_Reponse = 'A'
      -- Si l'annulation porte sur la transaction originale de 2008
      AND EXISTS(SELECT *
                 FROM tblIQEE_Annulations A
                 WHERE A.iID_Enregistrement_Annulation = D.iID_Demande_IQEE
                   AND A.iID_Enregistrement_Demande_Annulation = 338238)
END
