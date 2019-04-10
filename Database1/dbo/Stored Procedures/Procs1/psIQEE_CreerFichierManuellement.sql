/****************************************************************************************************
Copyright (c) 2014 Gestion Universitas inc.

Code du service		: psIQEE_CreerFichierManuellement
Nom du service		: Créer un fichiers de transactions manuellement
But 				: Créer un ou fichier pour l’IQÉÉ dont les transactions existent déjà dans la BD.
Facette				: IQÉÉ

Paramètres d’entrée	:	Paramètre					Description
						--------------------------	-----------------------------------------------------------------
						@iID_Fichier_IQEE			Identifiant du fichier logique source des données
						@bDenominalisation			Booléen identifiant s'il y a dénominalisation des données
						@vcChemin_Fichier			Répertoire où le fichier physique devra être créé.
						
						
Exemple d’appel		:	EXECUTE [dbo].[psIQEE_CreerFichierManuellement] 5206,0,
															 '\\gestas2\departements\IQEE\Fichiers\Transmis\'

Paramètres de sortie:	Table						Champ							Description
		  				-------------------------	--------------------------- 	---------------------------------
						S/O							iResultat						>= 0 = Traitement terminé normalement,
																						   nombre de fichiers crées.
																					-1 = Erreur dans les paramètres
 
Historique des modifications:
    Date        Programmeur             Description								
    ----------  --------------------    -----------------------------------------
    2014-03-06  Stéphane Barbeau        Création du service							
    2017-06-08  Steeve Picard           Changement au niveau d'un des paramètres de « psIQEE_CreerLignesFichier » pour utiliser le ID du fichier
    2017-09-14  Steeve Picard           Modification des paramètres de «fnIQEE_FormaterChamp»
    2018-05-02  Steeve Picard           L'identifiant du fiduciaire (NEQ) est maintenant traité comme un numérique par RQ
****************************************************************************************************/
CREATE PROCEDURE [dbo].[psIQEE_CreerFichierManuellement]
(
	@iID_Fichier_IQEE INTEGER,
	@bDenominalisation BIT = 0,
	@vcChemin_Fichier VARCHAR(150)
)
AS
BEGIN
	DECLARE 
        @vcNom_Fichier VARCHAR(50) = 'P',
		@vcNEQ_GUI VARCHAR(10) = (SELECT TOP 1 D.vcNEQ_GUI FROM Un_Def D),
		@iID_Session  integer,
		@iResultat INTEGER

        SELECT @vcNom_Fichier = @vcNom_Fichier + @vcNEQ_GUI 
                                               + dbo.fnIQEE_FormaterChamp(F.dtDate_Creation,'D',14,NULL)
		  FROM dbo.tblIQEE_Fichiers F
		 WHERE F.iID_Fichier_IQEE = @iID_Fichier_IQEE
				
        PRINT 'Génère le nom du fichier : ' + @vcNom_Fichier
      PRINT '      dans le répertoire : ' + @vcChemin_Fichier

		UPDATE tblIQEE_Fichiers
		   SET vcNom_Fichier = @vcNom_Fichier
		  FROM dbo.tblIQEE_Fichiers F
		 WHERE F.iID_Fichier_IQEE = @iID_Fichier_IQEE
		  
        PRINT 'Crée les lignes du fichier'
        DECLARE @iNEQ_GUI INT = CAST(@vcNEQ_GUI AS INTEGER)
		EXECUTE dbo.psIQEE_CreerLignesFichier @iID_Fichier_IQEE, @bDenominalisation, @iNEQ_GUI
		
        IF EXISTS(SELECT * FROM dbo.tblIQEE_LignesFichier WHERE iID_Fichier_IQEE = @iID_Fichier_IQEE AND NOT LEFT(cLigne, 2) IN ('01', '99')) --> 2
        BEGIN
            PRINT 'Écrit les lignes dans le fichier'
            EXECUTE @iResultat = dbo.psIQEE_CreerPhysiquementFichier @iID_Fichier_IQEE, @vcChemin_Fichier
        END
        ELSE
            PRINT 'Pas de lignes de données dans le fichier'
		
		RETURN @iResultat 
END